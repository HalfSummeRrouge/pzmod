-- ============================================================
-- 模块名   : RM_History
-- 职责     : 7 天滚动历史与每日结算（EveryDays 0:00，幂等，含读档补算 §8.4）
-- 所属里程碑: M1（疾病评估/训练日结挂点留给 M2/M3 模块接入）
-- 对外接口 : RM.History.settle / rebuildCache / cache
-- 依赖     : RM_Config / RM_DataLayer / RM_Scoring（shared）
--            副作用（写 modData）集中在 settle（编排层调用）
-- ============================================================
RM = RM or {}
RM.History = {}
local clamp = RM.Util.clamp

-- 派生缓存（最近 N 天均值，运行时非持久化；读档/结算后重建）
RM.State.cache = {}

-- ---------------- 每日结算（幂等） ----------------
-- dayIndex: getGameTime():getDaysSinceStart()
-- 步骤（§8.4）：幂等 → 算 net/score → 入 7 天历史 → 重建派生缓存
--              → 疾病评估（M3 挂点）→ 训练日结（M2 挂点）→ 清零当日计数器
function RM.History.settle(player, dayIndex)
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    local day = dayIndex or 0

    -- 幂等：同一天重复触发不双计
    if md.lastSettleDay ~= nil and day <= md.lastSettleDay then return end
    local gap = 1
    if md.lastSettleDay ~= nil and md.lastSettleDay >= 0 then
        gap = day - md.lastSettleDay
        if gap > 1 then
            RM.Log.debug("跨日读档：间隔 " .. tostring(gap) .. " 天，只补算最近一天（§8.4）")
        end
    end

    -- 1) 净额与评分（§8.3）
    local net = RM.Scoring.microNet(md.micro, RM.Config.dailyFixedLoss,
                                    md.sweat, md.bloodLossIron)
    local r = RM.Scoring.microScore(net)

    -- 2) 能量分（读原生池）
    local avgI = 0
    if RM.State.fuel.seconds > 0 then
        avgI = RM.State.fuel.sumIntensity / RM.State.fuel.seconds
    end
    local macros = RM.Data.readNutrition(player)
    local score = {}
    for i, k in ipairs(RM.Config.microKeys) do score[k] = r[k] end
    score.energy = RM.Scoring.energyScore(macros.calories, RM.Scoring.tdeeOf(avgI))

    -- 3) 入 7 天历史（§6.2 条目字段：day/net/score/exercise/hydration/weightKg/sunMins）
    local entry = {
        day = day,
        net = net,
        score = score,
        exercise = clamp(avgI, 0, 1),
        hydration = clamp(RM.State.live.hydration or md.hydration, 0, 100),
        weightKg = macros.weightKg,
        sunMins = md.exposure.sun or 0,
    }
    table.insert(md.history, entry)
    while #md.history > RM.Config.historyDays do
        table.remove(md.history, 1)
    end

    -- 4) 重建派生缓存
    RM.History.rebuildCache(md)

    -- 5) 疾病评估（M3）与训练日结（M2）—— 挂点（§8.4，模块加载后生效）
    if RM.Diseases and RM.Diseases.evaluate then
        pcall(RM.Diseases.evaluate, player, md)
    end
    if RM.Training and RM.Training.onEveryDays then
        pcall(RM.Training.onEveryDays, player, md)
    end

    -- 6) 清零当日计数器
    for i, k in ipairs(RM.Config.microKeys) do md.micro[k] = 0 end
    md.sweat.sodium, md.sweat.potassium, md.sweat.waterMl = 0, 0, 0
    md.bloodLossIron = 0
    md.exposure.wet, md.exposure.sun, md.exposure.highTemp = 0, 0, 0

    -- 7) 燃料台账日清（均值已入历史）
    RM.State.fuel.seconds = 0
    RM.State.fuel.sumIntensity = 0

    md.lastSettleDay = day
    RM.Log.debug("每日结算完成 day=" .. tostring(day))
end

-- ---------------- 派生缓存重建（读档后也调用） ----------------
function RM.History.rebuildCache(md)
    if not md or not md.history then return end
    RM.State.cache = RM.Scoring.historyAvg(md.history)
end

-- UI 只读查询：最近 N 天均值（含 energy）
function RM.History.cache()
    return RM.State.cache
end
