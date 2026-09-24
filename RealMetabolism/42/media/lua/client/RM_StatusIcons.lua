-- ============================================================
-- 模块名   : RM_StatusIcons
-- 职责     : 角落状态图标层（§12.3）：M1 = 水合(4档)+能量反馈(3档)
--            基础图标；风格对齐原版 moodle；7 病图标 M3 接入
-- 所属里程碑: M1（图标位图 = 美术资产，另行处理；S7 前经适配层空渲染）
-- 对外接口 : RM.UI.Icons.update / buildIconStates
-- 依赖     : RM_UIAdapter / RM_Theme / shared 只读查询
-- ============================================================
RM = RM or {}
RM.UI = RM.UI or {}          -- 字母序下 RM_UIAdapter 可能晚于本文件加载，先建表
RM.UI.Icons = {}
local clamp = RM.Util.clamp

-- 图标状态装配（纯函数，可单测）：返回 { id, tierKey, themeColor, visible }
function RM.UI.Icons.buildIconStates(live)
    local hyd = clamp((live and live.hydration) or 100, 0, 100)
    local hydTier = RM.Scoring.hydrationTier(hyd)
    local ef = clamp((live and live.energyFeedback) or 1.0, 0, 1)
    local efTier = "normal"
    if ef < RM.Config.energy.frozenBelow then efTier = "frozen"
    elseif ef < RM.Config.energy.lowBelow then efTier = "low" end

    -- 隐藏原则：正常态不显示（对齐原版 moodle，只有异常才占角落）
    local states = {}
    if hydTier.id ~= "normal" then
        states[#states + 1] = {
            id = "hydration", tier = hydTier.id,
            colorKey = RM.Theme.hydrationIcon[hydTier.id] or "bad",
            visible = true, text = string.format("H %d", math.floor(hyd)),
        }
    end
    if efTier ~= "normal" then
        states[#states + 1] = {
            id = "energy", tier = efTier,
            colorKey = RM.Theme.energyIcon[efTier] or "warn",
            visible = true, text = "E",
        }
    end
    -- TODO(S7): 早期疾病模糊图标（M3）、低钠/醉酒/咖啡因/过度训练（M2）
    return states
end

-- 刷新（由 Panel.refresh / 秒级路径调用）：全部经适配层
function RM.UI.Icons.update(md)
    local states = RM.UI.Icons.buildIconStates(RM.State.live)
    -- 清理旧图标宿主
    if RM.UI.Icons._host then
        pcall(function() RM.UI.Icons._host:removeFromUIManager() end)
        RM.UI.Icons._host = nil
    end
    if #states == 0 then return end

    -- 转为 makeIconHost 的 icons 格式
    local icons = {}
    for i, s in ipairs(states) do
        icons[#icons + 1] = {
            id = s.id,
            text = s.text,
            colorKey = s.colorKey,
        }
    end

    local host = RM.UI.makeIconHost({ anchor = "bottomRight", icons = icons })
    if not host.ok or not host.widget then return end

    -- 定位到屏幕右下角
    local sw, sh = 1920, 1080
    pcall(function()
        sw = getCore():getScreenWidth()
        sh = getCore():getScreenHeight()
    end)
    host.widget:setAnchor(sw, sh)
    host.widget:setVisible(true)
    host.widget:addToUIManager()
    host.widget:setAlwaysOnTop(true)
    RM.UI.Icons._host = host.widget
end
