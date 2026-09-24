-- ============================================================
-- 模块名   : RM_Hydration
-- 职责     : 水合连续池 [0,100]（§10.4）：基础流失、饮水/食物补水、
--            档位耐力修饰器（统一归一化来源之一）
-- 所属里程碑: M1（出汗/利尿流失项 M2 的 Environment/Beverages 接入
--            md.sweat 与 addWater）
-- 对外接口 : RM.Hydration.tick / modifiers / onDrink / onConsumeFood / get
-- 依赖     : shared 全部 + RM_Core 编排调用（server）
-- ============================================================
RM = RM or {}
RM.Hydration = {}
local clamp = RM.Util.clamp

-- 秒结算：基础排尿/呼吸流失（出汗项 M2 接入）
function RM.Hydration.tick(player, md, dtSec)
    if not md then return end
    local drainPerSec = RM.Config.hydration.baseDrainPerHour / 3600.0
    local h = RM.State.live.hydration or md.hydration or 100
    RM.State.live.hydration = clamp(h - drainPerSec * dtSec, 0, 100)
end

-- 修饰器来源（§11 通道）：按当前档给耐力恢复/上限因子
function RM.Hydration.modifiers(md)
    local h = RM.State.live.hydration
    if h == nil and md then h = md.hydration end
    local tier = RM.Scoring.hydrationTier(h or 100)
    return { recovery = tier.recovery, max = tier.max }
end

-- 饮水/饮品：ml × 补水效率 × perMl（负效率 = 净脱水，设计 §10.6）
-- M1 只做水合与微量 topup；利尿/酒精/咖啡因由 M2 Beverages 扩展
function RM.Hydration.onDrink(player, ml, item)
    if not player or not ml or ml <= 0 then return end
    local row = RM.Data.resolveBeverage(item)
    if not row then return end   -- 未收录饮品已在 resolveBeverage 记录 WARN，此处跳过
    RM.Data.addWater(player, ml, row.hydrationEfficiency)
    -- 果汁/牛奶等微量 topup（每 100ml 行）
    if row.microTopUpPer100ml then
        for k, v in pairs(row.microTopUpPer100ml) do
            RM.Data.addMicro(player, k, v * ml / 100.0)
        end
    end
end

-- 含水食物：ThirstChange 解渴单位 → ml（TODO(S1): 语义上机标定）
function RM.Hydration.onConsumeFood(item, player, ratio)
    if not item or not player or not ratio or ratio <= 0 then return end
    local ok, tc = pcall(function() return item:getThirstChange() end)
    if not ok or type(tc) ~= "number" or tc >= 0 then return end
    local quench = -tc * (ratio / 100.0)
    local ml = quench * RM.Config.hydration.thirstUnitMl
    if ml > 0 then
        local hydBefore = RM.State.live.hydration
        RM.Data.addWater(player, ml, 1.0)
        -- S1-4 探针：ThirstChange → quenchU → ml → 水合前后
        if RM.Probe and RM.Probe.hydrate then
            pcall(RM.Probe.hydrate, item, player, tc, quench, ml, hydBefore)
        end
    end
end

-- UI 只读查询
function RM.Hydration.get(md)
    return clamp(RM.State.live.hydration or (md and md.hydration) or 100, 0, 100)
end
