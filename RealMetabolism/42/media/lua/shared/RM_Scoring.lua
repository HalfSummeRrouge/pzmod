-- ============================================================
-- 模块名   : RM_Scoring
-- 职责     : 纯函数：微量评分/能量评分/燃料分配/水合档位/
--            修饰器归一化（§11）——全部无副作用，可离线单测
-- 所属里程碑: M1
-- 对外接口 : RM.Scoring.microNet / microScore / tierOf
--            RM.Scoring.energyScore / energyFeedback / tdeeOf
--            RM.Scoring.hydrationTier / postureIntensity / loadMult
--            RM.Scoring.fuelMix / modifiers / historyAvg
-- 依赖     : RM_Config / RM_DataLayer（shared）
-- ============================================================
RM = RM or {}
RM.Scoring = {}
local clamp = RM.Util.clamp
local safeDiv = RM.Util.safeDiv

-- ---------------- 微量净额与评分（§8.3） ----------------
-- 净摄入 = 摄入 − 日固定流失 − 出汗 − 出血（仅铁）
function RM.Scoring.microNet(intake, fixedLoss, sweat, bloodLossIron)
    local net = {}
    for i, k in ipairs(RM.Config.microKeys) do
        local v = (intake[k] or 0) - (fixedLoss[k] or 0)
        if sweat and sweat[k] then v = v - sweat[k] end
        if k == "iron" and bloodLossIron and bloodLossIron > 0 then v = v - bloodLossIron end
        net[k] = v
    end
    return net
end

-- r_i = 净摄入 / DRI
function RM.Scoring.microScore(net)
    local r = {}
    for i, k in ipairs(RM.Config.microKeys) do
        r[k] = safeDiv(net[k], RM.Config.DRI[k])
    end
    return r
end

-- UI 分档：<50% 危险 / 50–80% 注意 / 80–115% 达标 / >115% 过量（§8.3）
function RM.Scoring.tierOf(r)
    local t = RM.Config.scoreTiers
    if r < t.danger then return "danger"
    elseif r < t.attention then return "attention"
    elseif r <= t.ok then return "ok"
    else return "excess" end
end

-- ---------------- 能量（§9.2） ----------------
-- d = clamp(热量净额/TDEE 档, -1, 1)，热量净额读原生热量池（TODO(S2): 标定池量纲）
function RM.Scoring.energyScore(caloriesPool, tdee)
    return clamp(safeDiv(caloriesPool, (tdee or RM.Config.TDEE.moderate) * 0.5), -1, 1)
end

-- 小时级能量反馈 0–1：由原生碳水池派生
function RM.Scoring.energyFeedback(carbsPool)
    local ref = RM.Config.energy.carbSaturation
    return clamp(safeDiv(carbsPool, ref), 0, 1)
end

-- 当日平均强度 → TDEE 档（§4.1）
function RM.Scoring.tdeeOf(avgI)
    local tt = RM.Config.tdeeTier
    if avgI >= tt.highMinI then return RM.Config.TDEE.high end
    if avgI >= tt.moderateMinI then return RM.Config.TDEE.moderate end
    return RM.Config.TDEE.resting
end

-- ---------------- 燃料（§9.1） ----------------
-- 姿态相对倍率 → 归一化强度 I（0–1，以冲刺为 1）
function RM.Scoring.postureIntensity(postureRate)
    return clamp(safeDiv(postureRate, RM.Config.fuel.postureRate.sprint), 0, 1)
end

-- 负重比 → 强度修正系数（设计 §9.1）
function RM.Scoring.loadMult(weightRatio)
    local bands = RM.Config.fuel.loadCorrection
    local r = clamp(weightRatio or 0, 0, 99)
    for i = 1, #bands do
        if r <= bands[i].maxRatio then return bands[i].mult end
    end
    return bands[#bands].mult
end

-- 燃料混合比例查表：优先级 长期亏空 > 空腹/碳水枯竭 > 强度档（低强度随 T 漂移）
-- 返回 { carbs, fat, protein }（只用于 MOD 台账，§9.1）
function RM.Scoring.fuelMix(I, durationSec, fasted, deficitActive)
    local m = RM.Config.fuel.mix
    if deficitActive then
        return { carbs = m.deficit.carbs, fat = m.deficit.fat, protein = m.deficit.protein }
    end
    if fasted then
        return { carbs = m.fasted.carbs, fat = m.fasted.fat, protein = m.fasted.protein }
    end
    if I >= RM.Config.fuel.highIntensityMin then
        return { carbs = m.high.carbs, fat = m.high.fat, protein = m.high.protein }
    end
    if I <= RM.Config.fuel.lowIntensityMax then
        -- 低强度：随持续时间 carbs→fat 漂移
        local shift = clamp(durationSec / 60.0 * RM.Config.fuel.durationShiftPerMin, 0, 0.2)
        return { carbs = clamp(m.low.carbs - shift, 0.05, 1),
                 fat = clamp(m.low.fat + shift, 0, 0.95),
                 protein = m.low.protein }
    end
    return { carbs = m.mid.carbs, fat = m.mid.fat, protein = m.mid.protein }
end

-- ---------------- 水合档位（§10.4） ----------------
function RM.Scoring.hydrationTier(h)
    local tiers = RM.Config.hydration.tiers
    local v = clamp(h, 0, 100)
    for i = 1, #tiers do
        if v >= tiers[i].min then return tiers[i] end
    end
    return tiers[#tiers]
end

-- ---------------- 修饰器归一化（§11） ----------------
-- sources: { {recovery=, max=, add=}, ... }（nil 字段跳过）
-- 乘区相乘 clamp [0.5,1.5]；加区求和 clamp [-0.35,0.2]；上限 min 后 clamp [0.65,1.2]
function RM.Scoring.modifiers(sources)
    local mc = RM.Config.modifier
    local recovery, maxV, addV = 1.0, 1.0, 0.0
    for i = 1, #sources do
        local s = sources[i]
        if s then
            if s.recovery then recovery = recovery * s.recovery end
            if s.max then if s.max < maxV then maxV = s.max end end
            if s.add then addV = addV + s.add end
        end
    end
    return {
        recovery = clamp(recovery, mc.mul.min, mc.mul.max),
        max = clamp(maxV, mc.cap.min, mc.cap.max),
        add = clamp(addV, mc.add.min, mc.add.max),
    }
end

-- ---------------- 历史派生（§8.4 重建派生缓存） ----------------
-- 连续亏空天数（纯派生，从历史尾部数；d < deficitEnergyBelow 记亏空日）
function RM.Scoring.deficitDays(history)
    local n, cnt = #history, 0
    for i = n, 1, -1 do
        local e = history[i]
        if e and e.score and (e.score.energy or 0) < RM.Config.fuel.deficitEnergyBelow then
            cnt = cnt + 1
        else
            break
        end
    end
    return cnt
end

-- 对最近 historyDays 条的 r_i 取平均；含 energy
function RM.Scoring.historyAvg(history)
    local n = #history
    if n == 0 then return {} end
    local start = n - RM.Config.historyDays + 1
    if start < 1 then start = 1 end
    local sum, cnt = {}, 0
    for i = start, n do
        local e = history[i]
        if e and e.score then
            cnt = cnt + 1
            for k, v in pairs(e.score) do
                sum[k] = (sum[k] or 0) + v
            end
        end
    end
    local avg = {}
    for k, v in pairs(sum) do avg[k] = safeDiv(v, cnt) end
    return avg
end
