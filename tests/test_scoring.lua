-- Scoring 纯函数（§8.3 评分 / §9.1 燃料 / §10.4 档位 / §11 归一化）
local S = RM.Scoring

-- ---- tierOf 分档 ----
check("tierOf 0.4 → danger", S.tierOf(0.4) == "danger")
check("tierOf 0.5 → attention", S.tierOf(0.5) == "attention")
check("tierOf 0.79 → attention", S.tierOf(0.79) == "attention")
check("tierOf 0.8 → ok", S.tierOf(0.8) == "ok")
check("tierOf 1.15 → ok", S.tierOf(1.15) == "ok")
check("tierOf 1.151 → excess", S.tierOf(1.151) == "excess")

-- ---- microNet / microScore ----
local intake = { sodium = 2000, potassium = 3000, calcium = 1000, iron = 15,
                 vitA = 900, vitC = 100, vitD = 15, vitB1 = 1.2 }
local sweat = { sodium = 200, potassium = 100 }
local net = S.microNet(intake, RM.Config.dailyFixedLoss, sweat, 2)
check("net.sodium 含出汗", approx(net.sodium, 2000 - 500 - 200))
check("net.iron 含出血", approx(net.iron, 15 - 1 - 2))
check("net.vitC 无出汗项", approx(net.vitC, 100 - 30))
local r = S.microScore(net)
check("r.sodium = net/DRI", approx(r.sodium, net.sodium / 2000))

-- ---- energyScore / energyFeedback / tdeeOf ----
check("energyScore 满额 clamp 1", approx(S.energyScore(2700, 2700), 1))
check("energyScore 半亏 -0.5", approx(S.energyScore(-675, 2700), -0.5))
check("energyScore 空池下限", approx(S.energyScore(-99999, 2000), -1))
check("energyFeedback 满=1", approx(S.energyFeedback(1000), 1))
check("energyFeedback 半=0.5", approx(S.energyFeedback(500), 0.5))
check("energyFeedback 负=0", approx(S.energyFeedback(-500), 0))
check("tdeeOf 静息", S.tdeeOf(0.0) == RM.Config.TDEE.resting)
check("tdeeOf 中等", S.tdeeOf(0.2) == RM.Config.TDEE.moderate)
check("tdeeOf 高", S.tdeeOf(0.5) == RM.Config.TDEE.high)

-- ---- postureIntensity / loadMult ----
check("I(冲刺)=1", approx(S.postureIntensity(7.0), 1))
check("I(步行)=2/7", approx(S.postureIntensity(2.0), 2.0 / 7.0))
check("I(负 mod 超界) clamp", S.postureIntensity(99) <= 1)
check("loadMult 轻 1.0", S.loadMult(0.2) == 1.0)
check("loadMult 中 1.15", S.loadMult(0.3) == 1.15)
check("loadMult 偏重 1.3", S.loadMult(0.6) == 1.3)
check("loadMult 超重 1.5", S.loadMult(0.9) == 1.5)

-- ---- fuelMix 查表（§9.1 四场景） ----
local mHigh = S.fuelMix(1.0, 30, false, false)
check("fuelMix 高强度=高碳水", approx(mHigh.carbs, 0.75) and approx(mHigh.protein, 0))
local mLow = S.fuelMix(0.28, 1800, false, false)   -- 低强度 30 分钟
check("fuelMix 低强度随 T 漂移", approx(mLow.carbs, 0.30 - 30 * RM.Config.fuel.durationShiftPerMin)
      and approx(mLow.fat, 0.70 + 30 * RM.Config.fuel.durationShiftPerMin))
local mFasted = S.fuelMix(0.28, 60, true, false)
check("fuelMix 空腹=低碳水高脂肪", approx(mFasted.carbs, 0.2) and approx(mFasted.fat, 0.8))
local mDef = S.fuelMix(0.8, 60, true, true)
check("fuelMix 亏空优先级最高且记蛋白", approx(mDef.protein, 0.15) and approx(mDef.carbs, 0.15))
local mMid = S.fuelMix(0.4, 60, false, false)
check("fuelMix 中间档", approx(mMid.carbs, 0.5))

-- ---- hydrationTier ----
check("hydrationTier 100 normal", S.hydrationTier(100).id == "normal")
check("hydrationTier 60 normal(边界)", S.hydrationTier(60).id == "normal")
check("hydrationTier 59.9 thirsty", S.hydrationTier(59.9).id == "thirsty")
check("hydrationTier 25 low", S.hydrationTier(25).id == "low")
check("hydrationTier 5 critical", S.hydrationTier(5).id == "critical")
check("hydrationTier 负数防御 critical", S.hydrationTier(-3).id == "critical")

-- ---- modifiers 归一化（§11） ----
local mods = S.modifiers({
    { recovery = 0.60, max = 0.85 },      -- 水合 low
    { recovery = 0.85, max = 0.90 },      -- 能量 low
})
check("modifiers 乘区相乘 0.6×0.85=0.51（未触界）", approx(mods.recovery, 0.51))
check("modifiers 上限取 min", approx(mods.max, 0.85))
local modsFloor = S.modifiers({ { recovery = 0.4 }, { recovery = 0.9 } })
check("modifiers 乘区相乘后 clamp 下限", approx(modsFloor.recovery, 0.50))
local mods2 = S.modifiers({ { recovery = 1.5, max = 1.5 }, { recovery = 1.4 } })
check("modifiers 乘区 clamp 上限", approx(mods2.recovery, 1.5))
check("modifiers 空 sources 中性", (function()
    local m = S.modifiers({})
    return approx(m.recovery, 1) and approx(m.max, 1) and approx(m.add, 0)
end)())

-- ---- historyAvg / deficitDays ----
local hist = {
    { day = 1, score = { sodium = 0.5, energy = 0.0 } },
    { day = 2, score = { sodium = 1.0, energy = -0.8 } },
    { day = 3, score = { sodium = 1.5, energy = -0.9 } },
    { day = 4, score = { sodium = 0.6, energy = -0.7 } },
}
local avg = S.historyAvg(hist)
check("historyAvg sodium=(0.5+1+1.5+0.6)/4", approx(avg.sodium, 0.9))
check("deficitDays 尾部连续 3", S.deficitDays(hist) == 3)
local hist2 = {
    { day = 1, score = { energy = -0.9 } },
    { day = 2, score = { energy = 0.2 } },
    { day = 3, score = { energy = -0.9 } },
}
check("deficitDays 断链只计 1", S.deficitDays(hist2) == 1)
check("historyAvg 空历史=空表", next(S.historyAvg({})) == nil)
