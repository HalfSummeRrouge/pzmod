-- 存档往返测试（§6.4 契约）：写 → 序列化(基础类型深拷贝) → 新档读回 → 迁移不漂移
local D = RM.Data

-- 1) 正常往返：业务操作 → 存档 → 读回 → 值一致
local p1 = mkPlayer()
local md1 = D.ensurePlayer(p1)
D.addMicro(p1, "sodium", 1234.5)
D.addMicro(p1, "vitC", 90)
D.addSweat(p1, "sodium", 100)
D.addBloodLossIron(p1, 2)
RM.State.live.hydration = 66.6
D.commitLive(p1, md1)
md1.prefs.uiOpen = true
md1.lastSettleDay = 42
table.insert(md1.history, { day = 42, net = { sodium = 500 },
                           score = { sodium = 0.25, energy = -0.3 },
                           exercise = 0.3, hydration = 70, weightKg = 71.5, sunMins = 30 })

-- 模拟引擎序列化/读档：plainCopy 只保留基础类型
local saved = plainCopy(md1)
local p2 = mkPlayer()
p2.md["RM"] = plainCopy(saved)   -- 第二次拷贝模拟"读档新对象"
local md2 = D.ensurePlayer(p2)   -- 含 migrate

check("往返: micro.sodium", approx(md2.micro.sodium, 1234.5))
check("往返: micro.vitC", approx(md2.micro.vitC, 90))
check("往返: sweat.sodium", approx(md2.sweat.sodium, 100))
check("往返: bloodLossIron", approx(md2.bloodLossIron, 2))
check("往返: hydration", approx(md2.hydration, 66.6))
check("往返: lastSettleDay", md2.lastSettleDay == 42)
check("往返: history 保留", #md2.history == 1 and md2.history[1].day == 42)
check("往返: history 只存数字（weightKg）", type(md2.history[1].weightKg) == "number")
check("往返: prefs.uiOpen", md2.prefs.uiOpen == true)
check("往返: 二次读档再迁移幂等", (function()
    D.migrate(md2)
    return approx(md2.micro.sodium, 1234.5) and #md2.history == 1
end)())

-- 2) 继续游戏：读档后业务可正常运作（loadLive → 喝水 → 结算）
D.loadLive(p2)
RM.State.live.hydration = 10
D.addWater(p2, 200, 1.0)
check("读档后续业务: 喝水 +20", approx(RM.State.live.hydration, 30))
RM.History.settle(p2, 43)
check("读档后续业务: 结算追加", #md2.history == 2 and md2.history[2].day == 43)

-- 3) 旧版本存档（缺 effects/prefs/acute）→ 叶子合并补齐，不碰既有值
local p3 = mkPlayer()
p3.md["RM"] = {
    schema = 1,
    micro = { sodium = 1, potassium = 2, calcium = 3, iron = 4, vitA = 5, vitC = 6, vitD = 7, vitB1 = 8 },
    hydration = 80,
    lastSettleDay = 5,
}
local md3 = D.ensurePlayer(p3)
check("旧档: micro 原值不动", md3.micro.sodium == 1 and md3.micro.vitB1 == 8)
check("旧档: effects 补默认", md3.effects.caffeineUntil == -1)
check("旧档: prefs 补默认", md3.prefs.uiOpen == false)
check("旧档: history 补空表", type(md3.history) == "table")
check("旧档: hydration 原值", approx(md3.hydration, 80))

-- 4) 部分损坏存档（history 混入非表项）→ 结算防御不崩
local p4 = mkPlayer()
local md4 = D.ensurePlayer(p4)
table.insert(md4.history, "corrupt-entry")
table.insert(md4.history, { day = 7, net = {}, score = { sodium = 0.5 }, hydration = 60, weightKg = 70 })
RM.History.settle(p4, 8)
check("损坏历史: 结算不崩且保留合法条目", #md4.history >= 1)
check("损坏历史: 新条目在尾部", md4.history[#md4.history].day == 8)

-- 5) NaN/负值防御
local p5 = mkPlayer()
D.addWater(p5, 0 / 0, 1.0)
D.addMicro(p5, "vitC", 0 / 0)
D.addSweat(p5, "sodium", 0 / 0)
check("NaN 防御: 全部忽略", D.ensurePlayer(p5).micro.vitC == 0 and D.ensurePlayer(p5).hydration == 100)
RM.State.live.hydration = 50
D.addWater(p5, 100, -0.4)    -- 烈酒：正体积 × 负补水效率 → 净脱水 4 点（§10.6）
check("负乘积正确脱水", approx(RM.State.live.hydration, 46))
