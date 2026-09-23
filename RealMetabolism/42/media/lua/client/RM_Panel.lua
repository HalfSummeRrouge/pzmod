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
RM.Panel = RM.UI.Panel or {}
RM.UI.Panel = RM.Panel
local clamp = RM.Util.clamp

RM.Panel._open = false
RM.Panel._lastRefreshMs = 0
RM.Panel._keycode = nil

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
end

function RM.Panel._onKey(key)
    local target = RM.Panel._resolveKeycode()
    if target and key == target then
        RM.Panel.toggle()
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
    local host = RM.UI.makePanel({ title = getText("RM_UI_Title"), theme = RM.Theme })
    if not host.ok then return end
    -- 组件装配（makeTabs/makeBar/makeLineChart）在 _impl 落地后补齐渲染（S7）
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
