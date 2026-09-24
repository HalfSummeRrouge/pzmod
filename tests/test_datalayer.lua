-- DataLayer：schema/迁移/微量/饮品/水合/原生读取
local D = RM.Data

-- ---- freshState / ensurePlayer / migrate ----
local p = mkPlayer()
local md = D.ensurePlayer(p)
check("ensurePlayer 建 schema1", md.schema == RM.Config.schemaVersion)
check("freshState hydration=100", approx(md.hydration, 100))
check("freshState micro 8 键全 0", (function()
    for i, k in ipairs(RM.Config.microKeys) do
        if md.micro[k] ~= 0 then return false end
    end
    return true
end)())
check("ensurePlayer 幂等（同对象）", D.ensurePlayer(p) == md)

-- 旧档缺键 → 叶子级默认合并（只加不删）
local oldSave = {
    schema = 1,
    micro = { sodium = 123 },
    hydration = 55,
    history = { { day = 3, net = {}, score = { sodium = 0.7 }, exercise = 0.2, hydration = 50, weightKg = 70, sunMins = 0 } },
}
local pOld = mkPlayer()
pOld.md["RM"] = oldSave
local mdOld = D.migrate(pOld.md["RM"])
check("迁移补 vitC 默认不碰 sodium", mdOld.micro.vitC == 0 and mdOld.micro.sodium == 123)
check("迁移补 effects 缺省", mdOld.effects.caffeineUntil == -1)
check("迁移保留 history", #mdOld.history == 1)

-- 高 schema 只告警不破坏
local pFut = mkPlayer()
pFut.md["RM"] = { schema = 99, hydration = 42 }
local mdFut = D.migrate(pFut.md["RM"])
check("高 schema 不清数据", mdFut.hydration == 42)
check("高 schema 仍可补缺键", mdFut.micro ~= nil)

-- 迁移幂等：二次迁移值不变
mdOld.micro.iron = 9
local before = mdOld.micro.sodium
D.migrate(mdOld)
check("迁移链式幂等", mdOld.micro.sodium == before and mdOld.micro.iron == 9)

-- ---- lookupMicro：精确 / 关键词 / 兜底 ----
local apple = mkItem("Base.Apple", "Apple", 0.3)
check("lookup 精确命中 Apple", D.lookupMicro(apple).vitC == 4.6)
local sardineCan = mkItem("Base.SardineTinUnknown", "Sardine Tin", 0.2)
check("lookup 关键词 sardine", D.lookupMicro(sardineCan).calcium == 382)
local mystery = mkItem("Base.Mystery", "Some Unknown Food", 1.0)
check("lookup 未收录走兜底行", D.lookupMicro(mystery).sodium == 300)
check("lookup nil item 防御", D.lookupMicro(nil).vitC == 5)

-- ---- addMicro / addWater / addSweat ----
local p2 = mkPlayer()
D.addMicro(p2, "vitC", 13.8)
D.addMicro(p2, "vitC", 1.2)
check("addMicro 累计", approx(D.ensurePlayer(p2).micro.vitC, 15))
D.addMicro(p2, "vitC", 0 / 0)   -- NaN 防御
check("addMicro NaN 忽略", approx(D.ensurePlayer(p2).micro.vitC, 15))
D.addWater(p2, 500, 1.0)
check("addWater 500ml→+50", approx(D.ensurePlayer(p2).hydration, 100))  -- 上限 clamp
local p3 = mkPlayer()
p3.md["RM"] = D.freshState()
p3.md["RM"].hydration = 10
RM.State.live.hydration = 10
D.addWater(p3, 500, 1.0)
check("addWater 从 10 补 50 clamp 60", approx(p3.md["RM"].hydration, 60))
D.addSweat(p2, "sodium", 3.2)
check("addSweat 记录", approx(D.ensurePlayer(p2).sweat.sodium, 3.2))
D.addBloodLossIron(p2, 1.5)
check("addBloodLossIron 记录", approx(D.ensurePlayer(p2).bloodLossIron, 1.5))

-- ---- commitLive / loadLive（秒级内存 ↔ 落盘） ----
RM.State.live.hydration = 33.3
RM.State.live.energyFeedback = 0.42
D.commitLive(p2, D.ensurePlayer(p2))
check("commitLive 落盘", approx(D.ensurePlayer(p2).hydration, 33.3)
      and approx(D.ensurePlayer(p2).energyFeedback, 0.42))

-- ---- resolveBeverage：精确 / 类别兜底 ----
local water = mkItem("Base.WaterBottle", "Water Bottle", 0.5, nil, nil)
check("beverage 精确水=1.0", D.resolveBeverage(water).hydrationEfficiency == 1.0)
local beer = mkItem("Base.BeerBottle", "Beer", 0.35, nil, nil)
check("beverage 啤酒净脱水 0", D.resolveBeverage(beer).hydrationEfficiency == 0.0)
local unknownCola = mkItem("Base.SomeBrandCola", "Cola Thing", 0.3, nil, nil)
check("beverage 未收录→nil（不做关键词兜底）", D.resolveBeverage(unknownCola) == nil)
local mysteryDrink = mkItem("Base.XYZ", "Weird Drink", 0.3, nil, nil)
check("beverage 未收录→nil", D.resolveBeverage(mysteryDrink) == nil)
local oj = mkItem("Base.CannedFruitBeverageOpen", "Fruit Beverage", 0.3, nil, nil)
check("beverage 果汁 vitC topup", D.resolveBeverage(oj).microTopUpPer100ml.vitC == 40)

-- ---- Hydration.onDrink / onConsumeFood ----
local p4 = mkPlayer()
RM.State.live.hydration = 50
RM.Hydration.onDrink(p4, 500, water)
check("onDrink 白水 +50", approx(RM.State.live.hydration, 100))
RM.State.live.hydration = 50
RM.Hydration.onDrink(p4, 300, oj)
check("onDrink 果汁 +25.5 且补 vitC", approx(RM.State.live.hydration, 75.5)
      and approx(D.ensurePlayer(p4).micro.vitC, 40 * 3))   -- 300ml × vitC40/100ml
RM.State.live.hydration = 50
RM.Hydration.onDrink(p4, 300, beer)
check("onDrink 啤酒净补水 0", approx(RM.State.live.hydration, 50))
local soup = mkItem("Base.CannedSoup", "Canned Soup", 0.4, -30, "Food")
RM.Hydration.onConsumeFood(soup, p4, 100)
check("onConsumeFood 汤解渴 -30 → +30 点", approx(RM.State.live.hydration, 80))

-- ---- Hydration.tick 基础流失 ----
RM.State.live.hydration = 100
RM.Hydration.tick(p4, D.ensurePlayer(p4), 3600)   -- 1 游戏小时
check("tick 基础流失 5/小时", approx(RM.State.live.hydration, 95))
check("Hydration.modifiers normal", RM.Hydration.modifiers(nil).recovery == 1.0)
RM.State.live.hydration = 10
local hmod = RM.Hydration.modifiers(nil)
check("Hydration.modifiers critical", hmod.recovery == 0.35 and hmod.max == 0.70)

-- ---- Core.onEat 记账公式（§8.2） ----
-- 300g 苹果整只吃掉：vitC 4.6mg/100g × 3 百克 = 13.8
local p5 = mkPlayer()
local appleBig = mkItem("Base.Apple", "Apple", 0.3, 0, "Food")
RM.Core.onEat(appleBig, p5, 100, 0.3)
check("onEat 300g 苹果 vitC=13.8", approx(D.ensurePlayer(p5).micro.vitC, 13.8))
check("onEat 300g 苹果 钠=3mg", approx(D.ensurePlayer(p5).micro.sodium, 3))
-- 150g 生菜汤类含水食物：微记 +30% 解渴
local soupItem = mkItem("Base.CannedSoup", "Canned Soup", 0.15, -20, "Food")
RM.State.live.hydration = 40
RM.Core.onEat(soupItem, p5, 100, 0.15)
check("onEat 汤补水 20 单位=200ml=+20", approx(RM.State.live.hydration, 60))
-- ratio 50% 半只苹果（此前汤已贡献 vitC，取增量断言）
local vitCBefore = D.ensurePlayer(p5).micro.vitC
RM.Core.onEat(appleBig, p5, 50, 0.3)
check("onEat 半只(50%×300g) vitC 增 6.9", approx(D.ensurePlayer(p5).micro.vitC - vitCBefore, 6.9))

-- ---- readNutrition 只读 ----
local nread = D.readNutrition(mkPlayer(321, 111))
check("readNutrition 原生池", nread.calories == 321 and nread.carbohydrates == 111 and nread.weightKg == 75)
check("readNutrition nil 玩家防御", D.readNutrition(nil).calories == 0)

-- ---- Commands 写操作封装（clamp/键校验） ----
local p6 = mkPlayer()
RM.Commands.setHydration(p6, 150)
check("Commands.setHydration clamp", approx(D.ensurePlayer(p6).hydration, 100))
check("Commands.addMicro 未知键拒绝", RM.Commands.addMicro(p6, "vitZ", 10) == false)
check("Commands.addMicro 合法键", RM.Commands.addMicro(p6, "iron", 5) == true)
check("Commands.addWater", RM.Commands.addWater(p6, 100) == true)
