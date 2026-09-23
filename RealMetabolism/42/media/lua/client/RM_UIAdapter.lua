-- ============================================================
-- 模块名   : RM_UIAdapter
-- 职责     : NeatUI 唯一接触点（§12.1）：依赖检测（§12.5）与组件接口
--            makePanel/makeTabs/makeBar/makeList/makeLineChart/
--            makeIconHost/drawText；NeatUI API 只允许出现在本文件
-- 所属里程碑: M1（接口与门控落地；具体组件映射待 S7 实测 NeatUI
--            API 后填充 _impl，业务代码零改动）
-- 对外接口 : RM.UI.checkDependency / RM.UI.makeXXX（同 §12.1 清单）
-- 依赖     : RM_Theme / shared 只读查询；禁止 server 反向依赖
-- ============================================================
RM = RM or {}
RM.UI = RM.UI or {}
RM.UI._panelImpl = nil     -- S7 填充：真实 NeatUI 组件实现
RM.UI._iconsImpl = nil

-- ---------------- 依赖检测（§12.5：缺失 → 明确提示，不加载业务逻辑） ----------------
-- TODO(S7): 按 NeatUI 实际暴露的全局名/版本接口复核检测写法与加载顺序
function RM.UI.checkDependency()
    if RM.State.neatUIChecked then return RM.State.neatUIOk end
    local ok, found = pcall(function()
        return (NeatUI ~= nil) or (NeatUIFramework ~= nil)
    end)
    RM.State.neatUIOk = (ok and found == true)
    RM.State.neatUIChecked = true
    if not RM.State.neatUIOk then
        RM.Log.warn("检测不到 NeatUI：Real Metabolism 需要前置 NeatUI（Workshop 3508537032）。"
            .. " MOD 业务逻辑不会加载（§12.5）")
    end
    return RM.State.neatUIOk
end

-- ---------------- 组件接口（业务只调这里；不可用时返回 nil，不抛错） ----------------
-- 每个函数返回 { ok=bool, widget=?, reason=string }
local function unavailable()
    return { ok = false, widget = nil, reason = "NeatUI unavailable or _impl pending S7" }
end

function RM.UI.makePanel(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makePanel then
        local ok, w = pcall(RM.UI._panelImpl.makePanel, opts)
        if ok then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeTabs(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeTabs then
        local ok, w = pcall(RM.UI._panelImpl.makeTabs, opts)
        if ok then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeBar(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeBar then
        local ok, w = pcall(RM.UI._panelImpl.makeBar, opts)
        if ok then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeList(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeList then
        local ok, w = pcall(RM.UI._panelImpl.makeList, opts)
        if ok then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeLineChart(opts)
    if RM.UI._panelImpl and RM.UI._panelImpl.makeLineChart then
        local ok, w = pcall(RM.UI._panelImpl.makeLineChart, opts)
        if ok then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.makeIconHost(opts)
    if RM.UI._iconsImpl and RM.UI._iconsImpl.makeIconHost then
        local ok, w = pcall(RM.UI._iconsImpl.makeIconHost, opts)
        if ok then return { ok = true, widget = w } end
    end
    return unavailable()
end

function RM.UI.drawText(widget, text, x, y, color)
    if RM.UI._panelImpl and RM.UI._panelImpl.drawText then
        return (pcall(RM.UI._panelImpl.drawText, widget, text, x, y, color))
    end
    return false
end

-- 启动阶段（client 文件加载时）即检测：NeatUI 经 mod.info require 先于本 MOD 加载，
-- 其全局此时已存在；结果写入 RM.State.neatUIOk，供 server attach 门控（§12.5）
pcall(RM.UI.checkDependency)
