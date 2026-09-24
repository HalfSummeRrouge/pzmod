-- ============================================================
-- 模块名   : RM_Panel
-- 职责     : 代谢面板（§12.2 三页：状态/趋势/健康）：N 键开关、
--            可见时节流刷新（≥250ms）、不可见停刷新；UI 零写入，
--            只读 shared/server 查询函数
-- 所属里程碑: M1（框架+数据装配；组件渲染经 RM_UIAdapter，S7 映射后可见）
-- 对外接口 : RM.Panel.init / isOpen / toggle / refresh / buildStatusRows
-- 依赖     : RM_UIAdapter / RM_Theme / shared 只读查询
-- ============================================================
RM = RM or {}
RM.UI = RM.UI or {}          -- 字母序下 RM_UIAdapter 可能晚于本文件加载，先建表
RM.Panel = RM.UI.Panel or {}
RM.UI.Panel = RM.Panel
local clamp = RM.Util.clamp

RM.Panel._open = false
RM.Panel._lastRefreshMs = 0
RM.Panel._keycode = nil
RM.Panel._widget = nil          -- 持久面板 widget（首次打开时创建）
RM.Panel._page = "status"       -- 当前页：status / trend / health
RM.Panel._statusBars = {}       -- 状态页条控件（按 key 索引，刷新时更新 value）
RM.Panel._trendChart = nil     -- 趋势页折线图控件

-- ---------------- 只读数据装配（纯函数，供单测与渲染共用） ----------------
-- 返回状态页行数据：8 微量（分档）+ 水合 + 能量 + 今日负荷 + 宏量（读原生）
function RM.Panel.buildStatusRows(md, live, fuel, macros)
    local rows = {}
    for i, k in ipairs(RM.Config.microKeys) do
        local intake = (md and md.micro and md.micro[k]) or 0
        local dri = RM.Config.DRI[k]
        local net = intake - (RM.Config.dailyFixedLoss[k] or 0)
        local r = RM.Util.safeDiv(net, dri)
        rows[#rows + 1] = {
            key = k, value = r, tier = RM.Scoring.tierOf(r),
            labelKey = "RM_Micro_" .. k, showDetail = true, -- Nutritionist trait 在 UI 层控制精度
        }
    end
    local hyd = clamp((live and live.hydration) or (md and md.hydration) or 100, 0, 100)
    local ef = clamp((live and live.energyFeedback) or 1.0, 0, 1)
    rows[#rows + 1] = {
        key = "hydration", value = hyd / 100.0, raw = hyd,
        tier = RM.Scoring.hydrationTier(hyd).id, labelKey = "RM_UI_Hydration",
    }
    rows[#rows + 1] = {
        key = "energy", value = ef, raw = ef,
        tier = (ef < RM.Config.energy.frozenBelow and "frozen")
            or (ef < RM.Config.energy.lowBelow and "low") or "normal",
        labelKey = "RM_UI_Energy",
    }
    local load = 0
    if fuel and fuel.seconds and fuel.seconds > 0 then
        load = clamp(fuel.sumIntensity / fuel.seconds, 0, 1)
    end
    rows[#rows + 1] = {
        key = "load", value = load, raw = load,
        tier = load >= RM.Config.tdeeTier.highMinI and "high"
            or (load >= RM.Config.tdeeTier.moderateMinI and "moderate" or "rest"),
        labelKey = "RM_UI_Load",
    }
    rows[#rows + 1] = {
        key = "macros", value = macros or {}, raw = macros or {},
        tier = "normal", labelKey = "RM_UI_Macros", -- 原生宏量只读展示
    }
    return rows
end

-- 趋势页：最近 N 天折线点（每微量一条线 + energy）
function RM.Panel.buildTrendPoints(md)
    local pts = {}
    local hist = (md and md.history) or {}
    for i = 1, #hist do
        local e = hist[i]
        if e and e.score then
            pts[#pts + 1] = {
                day = e.day, score = e.score, hydration = e.hydration,
                weightKg = e.weightKg, sunMins = e.sunMins, exercise = e.exercise,
            }
        end
    end
    return pts
end

-- ---------------- 面板生命周期 ----------------
function RM.Panel.isOpen()
    return RM.Panel._open
end

function RM.Panel.toggle()
    RM.Panel._open = not RM.Panel._open
    local md = RM.Data.ensurePlayer(getPlayer())
    if md then md.prefs.uiOpen = RM.Panel._open end
    if RM.Panel._open then
        RM.Panel._ensureWidget()
        if RM.Panel._widget then
            RM.Panel._widget:setVisible(true)
            RM.Panel._widget:addToUIManager()
            pcall(RM.Panel.refresh)
        end
    else
        if RM.Panel._widget then
            RM.Panel._widget:removeFromUIManager()
            RM.Panel._widget:setVisible(false)
        end
    end
end

-- ---------------- 持久面板构建（首次打开时执行一次） ----------------
function RM.Panel._ensureWidget()
    if RM.Panel._widget then return end
    local host = RM.UI.makePanel({ title = getText("RM_UI_Title"), width = 660, height = 540 })
    if not host.ok then return end
    local panel = host.widget
    panel._onClose = function()
        RM.Panel._open = false
        panel:removeFromUIManager()
        panel:setVisible(false)
    end

    -- 标签栏
    local tabs = RM.UI.makeTabs({
        parent = panel,
        y = panel.contentY,
        tabs = {
            { key = "status", label = "Status" },
            { key = "trend",  label = "Trend" },
            { key = "health", label = "Health" },
        },
        onSelect = function(_, key)
            RM.Panel._switchPage(key)
        end,
    })
    if tabs.ok then
        panel._tabs = tabs.widget
        panel.contentY = panel.contentY + 30
    end

    -- 三页容器（只显示当前页）
    panel._pages = { status = nil, trend = nil, health = nil }
    RM.Panel._buildStatusPage(panel)
    RM.Panel._buildTrendPage(panel)
    RM.Panel._buildHealthPage(panel)
    RM.Panel._switchPage("status")

    RM.Panel._widget = panel
end

-- 分区标题：灰蓝色小标题 + 底部分隔线
local function _sectionLabel(parent, x, y, w, text)
    local lbl = ISLabel:new(x, y, 16, text, 0.55, 0.60, 0.68, 1, UIFont.Small, true)
    lbl:initialise()
    parent:addChild(lbl)
    -- 分隔线（1px 高 drawRect）
    local line = ISUIElement:new(x, y + 17, w, 1)
    line:initialise()
    function line:render()
        self:drawRect(0, 0, w, 1, 0.4, 0.22, 0.24, 0.28)
    end
    parent:addChild(line)
    return lbl
end

-- 状态页：分区标题 + 微量条（label|bar|value%）+ 状态条 + 宏量卡片
function RM.Panel._buildStatusPage(panel)
    local page = ISPanel:new(8, panel.contentY, panel:getWidth() - 16, panel.contentH - 30)
    page:initialise()
    page.backgroundColor = {r=0.090, g=0.100, b=0.120, a=1.0}
    panel:addChild(page)
    panel._pages.status = page

    local y = 4
    local barW = page:getWidth() - 16
    local barH = 24
    local rowH = barH + 4
    RM.Panel._statusBars = {}

    -- 简介
    local intro = ISUIElement:new(10, y, barW, 16)
    intro:initialise()
    intro.text = "Daily nutrient intake vs DRI. Green=adequate, Amber=low, Red=deficient."
    function intro:render()
        self:drawText(self.text, 0, 0, 0.55, 0.60, 0.68, 1, UIFont.Small)
    end
    page:addChild(intro)
    y = y + 22

    -- 微量营养素分区标题
    local sec = _sectionLabel(page, 4, y, barW, "MICRONUTRIENTS")
    y = y + 22

    -- 8 微量营养素（label | bar | DRI%）
    for i, k in ipairs(RM.Config.microKeys) do
        local bar = RM.UI.makeBar({
            x = 4, y = y, width = barW, height = barH,
            value = 0, colorKey = "neutral", label = k, valueText = "0%",
        })
        if bar.ok then
            page:addChild(bar.widget)
            RM.Panel._statusBars[k] = bar.widget
        end
        y = y + rowH
    end

    -- 状态分区标题
    y = y + 6
    _sectionLabel(page, 4, y, barW, "STATUS")
    y = y + 22

    -- 水合 + 能量 + 负荷
    for _, extra in ipairs({
        { key = "hydration", label = "Hydration" },
        { key = "energy",    label = "Energy" },
        { key = "load",      label = "Load" },
    }) do
        local bar = RM.UI.makeBar({
            x = 4, y = y, width = barW, height = barH,
            value = 0, colorKey = "accent", label = extra.label, valueText = "0",
        })
        if bar.ok then
            page:addChild(bar.widget)
            RM.Panel._statusBars[extra.key] = bar.widget
        end
        y = y + rowH
    end

    -- 宏量分区标题
    y = y + 6
    _sectionLabel(page, 4, y, barW, "MACRONUTRIENTS (vanilla)")
    y = y + 22
    -- 自定义渲染元素（避免 ISLabel 定位偏移跑到屏外）
    local macroBox = ISUIElement:new(8, y, barW, 18)
    macroBox:initialise()
    macroBox.text = ""
    function macroBox:render()
        if self.text and self.text ~= "" then
            self:drawText(self.text, 0, 0, 0.85, 0.88, 0.92, 1, UIFont.Small)
        end
    end
    page:addChild(macroBox)
    RM.Panel._macroLabel = macroBox
end

-- 趋势页：7 天折线图
function RM.Panel._buildTrendPage(panel)
    local page = ISPanel:new(8, -9999, panel:getWidth() - 16, panel.contentH - 30)
    page:initialise()
    page.backgroundColor = {r=0.090, g=0.100, b=0.120, a=1.0}
    panel:addChild(page)
    panel._pages.trend = page

    -- 简介
    local intro = ISUIElement:new(10, 8, page:getWidth() - 20, 16)
    intro:initialise()
    intro.text = "7-day trend of energy and hydration."
    function intro:render()
        self:drawText(self.text, 0, 0, 0.55, 0.60, 0.68, 1, UIFont.Small)
    end
    page:addChild(intro)

    local chart = RM.UI.makeLineChart({
        x = 4, y = 32, width = page:getWidth() - 8, height = 200,
        series = {},
    })
    if chart.ok then
        page:addChild(chart.widget)
        RM.Panel._trendChart = chart.widget
    end
end

-- 健康页：疾病/急性事件状态（M1 占位，M3 接入疾病状态机）
function RM.Panel._buildHealthPage(panel)
    local page = ISPanel:new(8, -9999, panel:getWidth() - 16, panel.contentH - 30)
    page:initialise()
    page.backgroundColor = {r=0.090, g=0.100, b=0.120, a=1.0}
    panel:addChild(page)
    panel._pages.health = page

    local intro = ISUIElement:new(10, 10, page:getWidth() - 20, 16)
    intro:initialise()
    intro.text = "Deficiency diseases and acute events. Coming in M3."
    function intro:render()
        self:drawText(self.text, 0, 0, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    page:addChild(intro)
end

-- 切换页（B42 setVisible 对子元素不可靠，用屏外位移隐藏）
function RM.Panel._switchPage(key)
    RM.Panel._page = key
    local panel = RM.Panel._widget
    if not panel or not panel._pages then return end
    local onY = panel.contentY
    for k, pg in pairs(panel._pages) do
        if pg then
            if k == key then
                pg:setY(onY)
                pg:setVisible(true)
            else
                pg:setY(-9999)
                pg:setVisible(false)
            end
        end
    end
    if panel._tabs then panel._tabs:setActive(key) end
end

-- tier → colorKey 映射
local function _tierColor(tier)
    if tier == "danger" or tier == "critical" or tier == "frozen" then return "bad"
    elseif tier == "attention" or tier == "thirsty" or tier == "low" then return "warn"
    elseif tier == "ok" or tier == "normal" then return "good"
    elseif tier == "excess" then return "excess"
    else return "accent" end
end

function RM.Panel._onKey(key)
    local target = RM.Panel._resolveKeycode()
    if target and key == target then
        RM.Panel.toggle()
        -- S2-7 探针：按键触发次数与开关态（验证单次翻转）
        if RM.Probe and RM.Probe.key then
            pcall(RM.Probe.key, key, RM.Panel._open)
        end
    end
end

function RM.Panel._resolveKeycode()
    if RM.Panel._keycode ~= nil then return RM.Panel._keycode end
    local ok, code = pcall(function()
        return Keyboard[RM.Config.ui.toggleKeyName]   -- TODO(S2): ModOptions 改键
    end)
    RM.Panel._keycode = (ok and type(code) == "number") and code or 46
    return RM.Panel._keycode
end

-- OnTick 节流刷新（可见时 ≥250ms，§12.2；不可见停刷 §15）
function RM.Panel._onTick()
    if not RM.Panel._open then return end
    local ok, nowMs = pcall(function() return getTimestampMs() end)
    if ok and nowMs and (nowMs - RM.Panel._lastRefreshMs) < RM.Config.ui.refreshMs then return end
    RM.Panel._lastRefreshMs = nowMs or 0
    pcall(RM.Panel.refresh)
end

-- 渲染入口：全部经适配层；适配不可用时为空操作（业务零改动，§12.1）
function RM.Panel.refresh()
    local p = getPlayer()
    if not p then return end
    local md = RM.Data.ensurePlayer(p)
    if not md then return end

    local rows = RM.Panel.buildStatusRows(md, RM.State.live, RM.State.fuel, RM.Data.readNutrition(p))

    -- 更新状态页各条（label 保留名称，valueText 显示右侧数值）
    for i, row in ipairs(rows) do
        local bar = RM.Panel._statusBars[row.key]
        if bar then
            bar.value = clamp(row.value or 0, 0, 1)
            bar.colorKey = _tierColor(row.tier)
            if row.key == "hydration" then
                bar.valueText = string.format("%.0f%%", (row.raw or 0))
            elseif row.key == "energy" then
                bar.valueText = string.format("%.0f%%", (row.raw or 0) * 100)
            elseif row.key == "load" then
                bar.valueText = string.format("%.0f%%", (row.raw or 0) * 100)
            else
                -- 微量：DRI 百分比（负值显示为 0%）
                local pct = math.max(0, math.floor((row.value or 0) * 100 + 0.5))
                bar.valueText = string.format("%d%%", pct)
            end
        end
    end

    -- 更新宏量文本
    if RM.Panel._macroLabel then
        local m = RM.Data.readNutrition(p) or {}
        local txt = string.format("cal %4.0f   carbs %4.0f   lipids %5.1f   protein %5.1f   weight %.1f kg",
            m.calories or 0, m.carbohydrates or 0, m.lipids or 0, m.proteins or 0, m.weight or 0)
        pcall(function() RM.Panel._macroLabel.text = txt end)
    end

    -- 更新趋势页折线图
    if RM.Panel._trendChart then
        local pts = RM.Panel.buildTrendPoints(md)
        local series = {}
        -- 能量曲线
        local energyPts = {}
        for i, e in ipairs(pts) do
            if e.score and e.score.energy ~= nil then
                energyPts[#energyPts + 1] = (e.score.energy + 1) / 2  -- -1..1 → 0..1
            end
        end
        if #energyPts >= 2 then
            series[#series + 1] = { label = "Energy", colorKey = "accent", points = energyPts }
        end
        -- 水合曲线
        local hydPts = {}
        for i, e in ipairs(pts) do
            if e.hydration ~= nil then
                hydPts[#hydPts + 1] = e.hydration / 100.0
            end
        end
        if #hydPts >= 2 then
            series[#series + 1] = { label = "Hydration", colorKey = "good", points = hydPts }
        end
        RM.Panel._trendChart.series = series
    end

    RM.UI.Icons.update(md)
end

-- ---------------- 启动（client 两阶段引导的 client 侧，§5.3） ----------------
function RM.Panel.init()
    RM.UI.checkDependency()   -- 写 RM.State.neatUIOk，server attach 读取做门控
    if not RM.Panel.__rmBound then
        -- 注：设计 §12.4 写 OnKeyKeepPressed 为 fallback；该事件按住持续触发，
        -- 用于"开关"语义会反复翻转，故取同族的 OnKeyPressed（单次按下触发）
        Events.OnKeyPressed.Add(RM.Panel._onKey)
        Events.OnTick.Add(RM.Panel._onTick)
        RM.Panel.__rmBound = true
    end
end

if not RM.UI.__rmPanelInitBound then
    RM.UI.__rmPanelInitBound = true
    RM.UI.init = function() RM.Panel.init() end
    -- client 侧两阶段引导（§5.3）：OnGameStart 幂等初始化（键位/节流/依赖检测结果）
    Events.OnGameStart.Add(function()
        pcall(function() RM.UI.init() end)
    end)
end
