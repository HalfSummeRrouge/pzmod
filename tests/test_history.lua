-- History：每日结算（幂等/历史裁剪/跨日补算/派生缓存）
local D, H = RM.Data, RM.History

local function freshDay(p, dayIdx)
    -- 模拟一天：摄入 2000mg 钠 + 燃料台账 1 游戏小时步行(I=2/7) + 水合 50
    D.addMicro(p, "sodium", 2000)
    D.addMicro(p, "vitC", 80)
    RM.State.fuel.seconds = 3600
    RM.State.fuel.sumIntensity = 3600 * (2.0 / 7.0)
    RM.State.live.hydration = 50
    H.settle(p, dayIdx)
end

local p = mkPlayer()
local md = D.ensurePlayer(p)
md.lastSettleDay = -1

-- 首日结算
freshDay(p, 10)
local md1 = D.ensurePlayer(p)
check("结算 day=10 入历史", #md1.history == 1 and md1.history[1].day == 10)
check("结算 net.sodium=2000-500", approx(md1.history[1].net.sodium, 1500))
check("结算 r.sodium=0.75", approx(md1.history[1].score.sodium, 0.75))
check("结算 exercise=2/7", approx(md1.history[1].exercise, 2.0 / 7.0, 1e-9))
check("结算 hydration 快照 50", approx(md1.history[1].hydration, 50))
check("结算 weightKg=75", approx(md1.history[1].weightKg, 75))
check("结算含 energy 分", type(md1.history[1].score.energy) == "number")
check("计数器清零", md1.micro.sodium == 0 and md1.micro.vitC == 0)
check("lastSettleDay=10", md1.lastSettleDay == 10)
check("燃料台账日清", RM.State.fuel.seconds == 0)
-- d = 200/(2700×0.5)（中等档 I=0.285→moderate）
check("结算 energy=200/1350", approx(md1.history[1].score.energy, 200 / 1350, 1e-6))

-- 幂等：同日再触发不双计
D.addMicro(p, "sodium", 999)
H.settle(p, 10)
check("同日重触发幂等", #md1.history == 1 and md1.micro.sodium == 999)
check("回退日不结算", (function() H.settle(p, 9) return #md1.history == 1 end)())

-- 次日结算
freshDay(p, 11)
check("次日入历史", #md1.history == 2 and md1.history[2].day == 11)

-- 跨日读档补算：跳 3 天（12,13,14），只在 14 结一次（§8.4 最多补 1 天）
freshDay(p, 14)
check("跨日跳档只补一天", #md1.history == 3 and md1.history[3].day == 14)

-- 7 天裁剪
for day = 15, 30 do freshDay(p, day) end
check("历史裁剪至 7 条", #md1.history == 7)
check("最新 day=30", md1.history[#md1.history].day == 30)
check("最旧 day=24（滚动窗）", md1.history[1].day == 24)

-- 派生缓存（7 天均值）
local cache = H.cache()
check("cache.sodium≈0.75", approx(cache.sodium, 0.75, 1e-6))
check("cache 含 energy", type(cache.energy) == "number")

-- settle 需要玩家 modData 异常防御：nil 玩家不崩
H.settle(nil, 99)
check("settle(nil) 不崩", true)
