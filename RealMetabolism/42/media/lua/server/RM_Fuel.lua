-- ============================================================
-- 模块名   : RM_Fuel
-- 职责     : 底物燃料模型（§9.1）：每秒产出强度 I 与持续时长 T，
--            查表得燃料比例 → 只写 MOD 台账（不驱动原生消耗）；
--            小时级能量反馈（§9.2）派生与修饰器来源
-- 所属里程碑: M1（瞬时动作折算 TODO(S5) 实测后接入；训练负荷 M2 扩展）
-- 对外接口 : RM.Fuel.tick / modifiers / intensity / energyFeedback / posture
-- 依赖     : shared 全部 + RM_Core 编排调用（server）
-- ============================================================
RM = RM or {}
RM.Fuel = {}
local clamp = RM.Util.clamp
local safeDiv = RM.Util.safeDiv

-- 当前姿态（优先级：冲刺 > 跑步 > 蹲走 > 步行 > 静息；K6: 无 isCrouching）
function RM.Fuel._posture(player)
    local ok, res = pcall(function()
        if player:isSprinting() then return "sprint" end
        if player:isRunning() then return "run" end
        if player:isSneaking() and player:isMoving() then return "sneak" end
        if player:isMoving() then return "walk" end
        return "rest"
    end)
    if ok then return res end
    return "rest"
end

-- 负重比（只读；早期时序判空 §16.1）
function RM.Fuel._loadRatio(player)
    local ok, ratio = pcall(function()
        local maxW = player:getMaxWeight()
        if not maxW or maxW <= 0 then return 0 end
        return player:getInventoryWeight() / maxW
    end)
    if ok and type(ratio) == "number" then return clamp(ratio, 0, 99) end
    return 0
end

-- 秒结算：姿态 → I/T → 燃料台账 + 训练负荷 + 能量反馈
function RM.Fuel.tick(player, md, dtSec)
    if not md then return end

    -- 1) 姿态与强度（负重修正 ×1.0/1.15/1.3/1.5，设计 §9.1）
    local posture = RM.Fuel._posture(player)
    local f = RM.State.fuel
    if posture ~= f.posture then
        f.posture = posture
        f.durationSec = 0
    end
    f.durationSec = f.durationSec + dtSec
    local rate = RM.Config.fuel.postureRate[posture] or RM.Config.fuel.postureRate.rest
    local I = RM.Scoring.postureIntensity(rate * RM.Scoring.loadMult(RM.Fuel._loadRatio(player)))
    I = clamp(I, 0, 1)

    -- 2) 空腹/碳水枯竭（读原生池，只读；TODO(S2): 阈值标定）
    local macros = RM.Data.readNutrition(player)
    local fasted = macros.carbohydrates < RM.Config.fuel.fastedCarbsBelow

    -- 3) 长期亏空 + 持续高负荷 → 蛋白记账（只记台账，§9.1）
    local deficitActive = (RM.Scoring.deficitDays(md.history or {}) >= RM.Config.fuel.deficitDaysForProtein)
                           and I >= RM.Config.fuel.highIntensityMin

    -- 4) 燃料比例查表 → 台账（仅 MOD 内部账，不写原生）
    local mix = RM.Scoring.fuelMix(I, f.durationSec, fasted, deficitActive)
    RM.Data.recordFuel(player, {
        intensity = I, duration = f.durationSec,
        carbsRatio = mix.carbs, fatRatio = mix.fat, proteinRatio = mix.protein,
    })
    RM.Data.recordLoad(player, I, dtSec)

    -- 5) 小时级能量反馈（0–1，派生自原生碳水池；供修饰器与 UI）
    RM.State.live.energyFeedback = RM.Scoring.energyFeedback(macros.carbohydrates)
end

-- 修饰器来源（§11 通道）：能量反馈偏低/枯竭（§9.2）
function RM.Fuel.modifiers(md)
    local ef = RM.State.live.energyFeedback or 1.0
    local e = RM.Config.energy
    if ef < e.frozenBelow then
        return { recovery = e.frozenRecovery, max = e.lowMax }
    elseif ef < e.lowBelow then
        return { recovery = e.lowRecovery, max = e.lowMax }
    end
    return nil
end

-- UI 只读查询
function RM.Fuel.intensity()
    local f = RM.State.fuel
    if f.seconds > 0 then return clamp(f.sumIntensity / f.seconds, 0, 1) end
    return 0
end

function RM.Fuel.energyFeedback()
    return clamp(RM.State.live.energyFeedback or 1.0, 0, 1)
end

function RM.Fuel.posture()
    return RM.State.fuel.posture
end
