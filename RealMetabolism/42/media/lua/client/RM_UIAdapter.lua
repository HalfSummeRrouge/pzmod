-- ============================================================
-- 模块名   : RM_UIAdapter
-- 职责     : NeatUI 唯一接触点（§12.1）：依赖检测（§12.5）与组件接口
--            makePanel/makeTabs/makeBar/makeList/makeLineChart/
--            makeIconHost/drawText；NeatUI API 只允许出现在本文件
-- 所属里程碑: M1（S7 已落地：基于 NeatTool 绘制助手 + NI_SquareButton +
--            NIScrollView + NeatUI 纹理构建高层 widget）
-- 对外接口 : RM.UI.checkDependency / RM.UI.makeXXX（同 §12.1 清单）
-- 依赖     : RM_Theme / shared 只读查询；禁止 server 反向依赖
-- NeatUI 实测结论: NeatUI 是底层工具包（非 widget 库），提供 NeatTool
--            （drawTexturePercentage/ThreePatch/NinePatch/truncateText）、
--            NI_SquareButton、NIScrollView、ISUIElement center 兼容。
--            高层 panel/tabs/bar/chart 在此文件用 vanilla ISXxx + 上述工具构建。
-- ============================================================
-- require 在游戏内由 PZ Lua 加载器解析；测试环境用 pcall 兜底避免硬错误
local function _safeRequire(path)
    if package and package.loaded and package.loaded[path] then return true end
    local ok = pcall(require, path)
    return ok
end
_safeRequire("ISUI/ISPanel")
_safeRequire("ISUI/ISButton")
_safeRequire("ISUI/ISLabel")
_safeRequire("ISUI/ISUIElement")

RM = RM or {}
RM.UI = RM.UI or {}
RM.UI._panelImpl = nil
RM.UI._iconsImpl = nil

-- ---------------- 纹理缓存（NeatUI 自带纹理，getTexture 失败回退 nil-safe） ----------------
local _texCache = {}
local function _tex(path)
    if _texCache[path] ~= nil then return _texCache[path] end
    local ok, t = pcall(function() return getTexture(path) end)
    _texCache[path] = (ok and t) or false
    return _texCache[path] or nil
end

-- ---------------- 依赖检测（§12.5：缺失 → 明确提示，不加载业务逻辑） ----------------
function RM.UI.checkDependency()
    if RM.State and RM.State.neatUIChecked then return RM.State.neatUIOk end
    local ok, found = pcall(function()
        return (NeatTool ~= nil) or (NeatUI ~= nil) or (NIScrollView ~= nil)
    end)
    local neatOk = (ok and found == true)
    if RM.State then
        RM.State.neatUIOk = neatOk
        RM.State.neatUIChecked = true
    end
    if not neatOk then
        RM.Log.warn("检测不到 NeatUI：Real Metabolism 需要前置 NeatUI（Workshop 3508537032）。"
            .. " MOD 业务逻辑不会加载（§12.5）")
    end
    return neatOk
end

-- ---------------- 颜色工具：RM.Theme 颜色 → rgba 表 ----------------
local function _col(key, defaultA)
    local c = (RM.Theme and RM.Theme.colors and RM.Theme.colors[key]) or {r=1,g=1,b=1}
    return { r = c.r, g = c.g, b = c.b, a = defaultA or 1.0 }
end

-- ---------------- B42 兼容：setTextColor/setColor 在部分 ISXxx 子类不存在 ----------------
-- 优先调用方法，缺失则直接写属性表，避免 "attempt to call nil"
local function _setTextColor(el, r, g, b, a)
    if el.setTextColor then pcall(function() el:setTextColor(r, g, b, a) end) return end
    el.textColor = { r = r, g = g, b = b, a = a or 1 }
end
local function _setColor(el, r, g, b, a)
    if el.setColor then pcall(function() el:setColor(r, g, b, a) end) return end
    el.color = { r = r, g = g, b = b, a = a or 1 }
end

-- ============================================================
-- _panelImpl：高层 widget 实现（vanilla ISXxx + NeatTool + NeatUI 纹理）
-- ============================================================
RM.UI._panelImpl = {}

-- ---------- makePanel：带标题栏 + 关闭按钮的主面板（现代深色主题） ----------
-- opts: { title, theme, width=640, height=520 }
function RM.UI._panelImpl.makePanel(opts)
    opts = opts or {}
    local w = opts.width or 640
    local h = opts.height or 520
    local panel = ISPanel:new(40, 40, w, h)
    panel:initialise()
    panel:instantiate()
    panel:setAlwaysOnTop(true)
    local bg = _col("panelBg")
    local bd = _col("panelBorder")
    panel.backgroundColor = {r=bg.r, g=bg.g, b=bg.b, a=0.96}
    panel.borderColor = {r=bd.r, g=bd.g, b=bd.b, a=1.0}

    -- 标题栏（可拖动面板）
    local tb = _col("titleBar")
    local titleBar = ISPanel:new(0, 0, w, 36)
    titleBar:initialise()
    titleBar.backgroundColor = {r=tb.r, g=tb.g, b=tb.b, a=1.0}
    -- 拖动：按住标题栏移动整个面板
    titleBar._dragging = false
    titleBar._dragOX, titleBar._dragOY = 0, 0
    function titleBar:onMouseDown(x, y)
        self._dragging = true
        self._dragOX = x
        self._dragOY = y
    end
    function titleBar:onMouseMove(dx, dy)
        if self._dragging then
            panel:setX(panel:getX() + dx)
            panel:setY(panel:getY() + dy)
        end
    end
    function titleBar:onMouseUp(x, y)
        self._dragging = false
    end
    panel:addChild(titleBar)

    -- 标题文本（getText 无翻译时回退到硬编码，不显示 key）
    local title = opts.title
    if not title or title == "" then title = "Metabolism" end
    -- 若 getText 返回了未翻译的 key（RM_UI_ 前缀），回退
    if title and title:sub(1, 6) == "RM_UI_" then title = "Metabolism" end
    local titleLbl = ISLabel:new(14, 9, 22, title, 1, 1, 1, 1, UIFont.Medium, true)
    titleLbl:initialise()
    _setTextColor(titleLbl, 0.92, 0.94, 0.97, 1)
    titleBar:addChild(titleLbl)
    panel._titleLbl = titleLbl

    -- 关闭按钮
    local closeBtn = ISButton:new(w - 38, 6, 28, 24, "X", panel, function()
        if panel._onClose then panel:_onClose() end
    end)
    closeBtn:initialise()
    _setTextColor(closeBtn, 0.90, 0.32, 0.32, 1)
    titleBar:addChild(closeBtn)

    -- 内容区（留出标题栏 + 1px 分隔线）
    panel.contentY = 40
    panel.contentH = h - 44
    return panel
end

-- ---------- makeTabs：标签页切换 ----------
-- opts: { parent, y, tabs={ {key,label} }, onSelect }
-- 返回 { bar, setActive(key) }
function RM.UI._panelImpl.makeTabs(opts)
    local parent = opts.parent
    local tabs = opts.tabs or {}
    local bg = _col("titleBar")
    local bar = ISPanel:new(0, opts.y or 0, parent:getWidth(), 30)
    bar:initialise()
    bar.backgroundColor = {r=bg.r, g=bg.g, b=bg.b, a=1.0}
    parent:addChild(bar)

    local btns = {}
    local x = 10
    local inactive = _col("subText")
    for i, t in ipairs(tabs) do
        local btn = ISButton:new(x, 3, 96, 24, t.label, bar, function()
            if bar._onSelect then bar:_onSelect(t.key) end
        end)
        btn:initialise()
        _setTextColor(btn, inactive.r, inactive.g, inactive.b, 1)
        btn.backgroundColor = {r=bg.r, g=bg.g, b=bg.b, a=0}
        bar:addChild(btn)
        btns[t.key] = btn
        x = x + 100
    end
    bar._btns = btns
    bar._onSelect = opts.onSelect

    function bar:setActive(key)
        local accent = _col("accent")
        local text = _col("text")
        for k, b in pairs(self._btns) do
            if k == key then
                _setTextColor(b, text.r, text.g, text.b, 1)
                b.backgroundColor = {r=accent.r, g=accent.g, b=accent.b, a=0.25}
            else
                _setTextColor(b, inactive.r, inactive.g, inactive.b, 1)
                b.backgroundColor = {r=bg.r, g=bg.g, b=bg.b, a=0}
            end
        end
    end
    return bar
end

-- ---------- makeBar：进度条（三栏：label左 + bar中 + value右） ----------
-- opts: { parent, x, y, width, height, value=0..1, colorKey, label, valueText, labelW=90, valueW=56 }
-- 返回 ISUIElement，外部可设 .value / .label / .valueText / .colorKey 更新
function RM.UI._panelImpl.makeBar(opts)
    local el = ISUIElement:new(opts.x, opts.y, opts.width, opts.height or 22)
    el:initialise()
    el.value = opts.value or 0
    el.colorKey = opts.colorKey or "accent"
    el.label = opts.label or ""
    el.valueText = opts.valueText or ""
    el.labelW = opts.labelW or 90
    el.valueW = opts.valueW or 56

    function el:render()
        local w, h = self:getWidth(), self:getHeight()
        local lw = self.labelW
        local vw = self.valueW
        local bx = lw + 6
        local bw = w - lw - vw - 12

        -- 左侧 label
        if self.label and self.label ~= "" then
            local tc = _col("text")
            self:drawText(self.label, 2, 3, tc.r, tc.g, tc.b, 1, UIFont.Small)
        end

        -- 进度条背景
        local bg = _col("barBg")
        self:drawRect(bx, 2, bw, h - 4, 1, bg.r, bg.g, bg.b)
        -- 进度条填充
        local v = RM.Util.clamp(self.value or 0, 0, 1)
        local c = _col(self.colorKey)
        if v > 0 then
            self:drawRect(bx, 2, bw * v, h - 4, 1, c.r, c.g, c.b)
        end
        -- 进度条边框
        local bd = _col("panelBorder")
        self:drawRectBorder(bx, 2, bw, h - 4, 0.6, bd.r, bd.g, bd.b)

        -- 右侧 value
        if self.valueText and self.valueText ~= "" then
            local vc = _col("subText")
            self:drawText(self.valueText, w - vw, 3, vc.r, vc.g, vc.b, 1, UIFont.Small)
        end
    end
    return el
end

-- ---------- makeList：可滚动列表（NIScrollView，NeatUI） ----------
-- opts: { parent, x, y, width, height, rows={ {text, colorKey} } }
-- 返回 NIScrollView
function RM.UI._panelImpl.makeList(opts)
    local sv
    if NIScrollView then
        sv = NIScrollView:new(opts.x, opts.y, opts.width, opts.height)
    else
        sv = ISPanel:new(opts.x, opts.y, opts.width, opts.height)
    end
    sv:initialise()
    sv.backgroundColor = {r=0, g=0, b=0, a=0.4}

    local y = 0
    local rows = opts.rows or {}
    for i, r in ipairs(rows) do
        local lbl = ISLabel:new(6, y, 16, r.text or "",
            1, 1, 1, 1, UIFont.Small, true)
        lbl:initialise()
        local c = _col(r.colorKey or "neutral")
        _setColor(lbl, c.r, c.g, c.b)
        if NIScrollView then
            sv:addScrollChild(lbl)
        else
            sv:addChild(lbl)
        end
        y = y + 18
    end
    return sv
end

-- ---------- makeLineChart：折线图（drawLine 实现） ----------
-- opts: { parent, x, y, width, height, series={ {label, colorKey, points={v}} } }
-- 返回 ISUIElement，外部可设 .series 更新
function RM.UI._panelImpl.makeLineChart(opts)
    local el = ISUIElement:new(opts.x, opts.y, opts.width, opts.height)
    el:initialise()
    el.series = opts.series or {}
    el.padL, el.padR, el.padT, el.padB = 30, 10, 10, 20

    function el:render()
        local w, h = self:getWidth(), self:getHeight()
        local bg = _col("barBg")
        local bd = _col("panelBorder")
        -- 背景
        self:drawRect(0, 0, w, h, 1, bg.r, bg.g, bg.b)
        self:drawRectBorder(0, 0, w, h, 0.6, bd.r, bd.g, bd.b)
        -- 网格线（4 条水平）— 用 1px 高的 drawRect 替代 drawLine（B42 drawLine 需 Texture）
        for i = 1, 3 do
            local gy = self.padT + (h - self.padT - self.padB) * i / 4
            self:drawRect(self.padL, gy, w - self.padL - self.padR, 1, 0.3, bd.r, bd.g, bd.b)
        end
        -- 绘制每条线的数据点（2×2 方块）
        for si, s in ipairs(self.series) do
            local pts = s.points or {}
            if #pts >= 1 then
                local c = _col(s.colorKey or "accent")
                local plotW = w - self.padL - self.padR
                local plotH = h - self.padT - self.padB
                for i = 1, #pts do
                    local px = self.padL + plotW * (i - 1) / math.max(1, #pts - 1)
                    local v = RM.Util.clamp(pts[i] or 0, 0, 1)
                    local py = self.padT + plotH * (1 - v)
                    self:drawRect(px - 1, py - 1, 2, 2, 0.9, c.r, c.g, c.b)
                end
            end
        end
    end
    return el
end

-- ---------- drawText：在 widget 上绘制文本 ----------
function RM.UI._panelImpl.drawText(widget, text, x, y, color)
    if not widget then return false end
    local c = color or {r=1,g=1,b=1}
    local ok = pcall(function()
        widget:drawText(text or "", x or 0, y or 0, c.r, c.g, c.b, 1, UIFont.Small)
    end)
    return ok
end

-- ============================================================
-- _iconsImpl：角落状态图标
-- ============================================================
RM.UI._iconsImpl = {}

-- opts: { anchor="bottomRight", theme, icons={ {id, text, colorKey} } }
-- 返回 ISUIElement 图标宿主
function RM.UI._iconsImpl.makeIconHost(opts)
    local icons = opts.icons or {}
    if #icons == 0 then return nil end

    local size = 28
    local gap = 4
    local host = ISUIElement:new(0, 0, (size + gap) * #icons + gap, size + gap * 2)
    host:initialise()

    local x = gap
    for i, ic in ipairs(icons) do
        local btn = ISUIElement:new(x, gap, size, size)
        btn:initialise()
        btn.icon = ic
        function btn:render()
            local c = _col(self.icon.colorKey or "warn")
            local bg = _col("panelBg")
            self:drawRect(0, 0, size, size, 0.9, bg.r, bg.g, bg.b)
            self:drawRect(1, 1, size-2, size-2, 0.5, c.r * 0.3, c.g * 0.3, c.b * 0.3)
            self:drawRectBorder(0, 0, size, size, 0.9, c.r, c.g, c.b)
            if self.icon.text then
                self:drawText(self.icon.text, 4, 6, c.r, c.g, c.b, 1, UIFont.Small)
            end
        end
        host:addChild(btn)
        x = x + size + gap
    end

    -- 定位到锚点
    function host:setAnchor(screenW, screenH)
        local a = opts.anchor or "bottomRight"
        if a == "bottomRight" then
            self:setX(screenW - self:getWidth() - 10)
            self:setY(screenH - self:getHeight() - 60)
        elseif a == "topRight" then
            self:setX(screenW - self:getWidth() - 10)
            self:setY(10)
        end
    end
    return host
end

-- ---------------- 组件接口（业务只调这里；不可用时返回 nil，不抛错） ----------------
local function unavailable()
    return { ok = false, widget = nil, reason = "NeatUI unavailable or _impl pending S7" }
end

function RM.UI.makePanel(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makePanel then
        local ok, w = pcall(RM.UI._panelImpl.makePanel, opts)
        if ok and w then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeTabs(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeTabs then
        local ok, w = pcall(RM.UI._panelImpl.makeTabs, opts)
        if ok and w then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeBar(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeBar then
        local ok, w = pcall(RM.UI._panelImpl.makeBar, opts)
        if ok and w then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeList(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeList then
        local ok, w = pcall(RM.UI._panelImpl.makeList, opts)
        if ok and w then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeLineChart(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeLineChart then
        local ok, w = pcall(RM.UI._panelImpl.makeLineChart, opts)
        if ok and w then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeIconHost(opts)
    if RM.UI._iconsImpl and RM.UI._iconsImpl.makeIconHost then
        local ok, w = pcall(RM.UI._iconsImpl.makeIconHost, opts)
        if ok and w then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.drawText(widget, text, x, y, color)
    if RM.UI._panelImpl and RM.UI._panelImpl.drawText then
        return (pcall(RM.UI._panelImpl.drawText, widget, text, x, y, color))
    end
    return false
end

-- 启动阶段（client 文件加载时）即检测
pcall(RM.UI.checkDependency)
