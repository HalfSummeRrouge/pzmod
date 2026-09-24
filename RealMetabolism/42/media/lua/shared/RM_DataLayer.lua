-- ============================================================
-- 模块名   : RM_DataLayer
-- 职责     : modData schema/迁移、微量表/饮品表/兜底查找、
--            原生宏量只读、每日累计器、运行时 State/Util/Log
-- 所属里程碑: M1（数据表 M4 调优；M2/M3 模块接入本层预留的挂点）
-- 对外接口 : RM.Util / RM.Log / RM.State
--            RM.Data.freshState / ensurePlayer / migrate
--            RM.Data.loadLive / commitLive
--            RM.Data.lookupMicro / resolveBeverage
--            RM.Data.addMicro / addSweat / addBloodLossIron
--            RM.Data.addWater / recordFuel / recordLoad
--            RM.Data.readNutrition
-- 依赖     : RM_Config（shared 前一加载）
-- ============================================================
RM = RM or {}

-- ---------------- Util / Log / State（全 MOD 公共） ----------------
RM.Util = {
    clamp = function(v, lo, hi)
        if v ~= v then return lo end          -- NaN 防御（§16.4）
        if v < lo then return lo elseif v > hi then return hi end
        return v
    end,
    safeDiv = function(a, b)                   -- 除零返回中性 0（§16.4）
        if b == 0 or b ~= b or a ~= a then return 0 end
        return a / b
    end,
}

RM.Log = {
    _fmt = function(tag, msg)
        return "[RealMetabolism][" .. tag .. "] " .. tostring(msg)
    end,
    info = function(msg) print(RM.Log._fmt("INFO", msg)) end,
    warn = function(msg) print(RM.Log._fmt("WARN", msg)) end,
    debug = function(msg)
        if RM.Config and RM.Config.debug then print(RM.Log._fmt("DEBUG", msg)) end
    end,
}

-- 运行时瞬时数据（非持久化，§5.1）
RM.State = {
    live = {},          -- 秒级消耗累计的活值（hydration 等），定期 commit 进 md
    fuel = {            -- 燃料台账（当日，仅 MOD 内部，§9.1；每日结算取均值后清零）
        seconds = 0, sumIntensity = 0,
        mix = { carbs = 0, fat = 0, protein = 0 },   -- 当前混合比例快照
        posture = "rest", durationSec = 0,          -- 当前姿态/同强度持续秒数
    },
    saveAccumSec = 0,   -- 落盘计时器（游戏秒）
    lastEndurance = nil,-- 修饰器应用：上一秒耐力（纯派生，不落盘）
}

RM.Data = RM.Data or {}

-- ---------------- schema 1（§6.2，键名冻结） ----------------
function RM.Data.freshState()
    return {
        schema = RM.Config.schemaVersion,
        micro = { sodium = 0, potassium = 0, calcium = 0, iron = 0,
                  vitA = 0, vitC = 0, vitD = 0, vitB1 = 0 },
        sweat = { sodium = 0, potassium = 0, waterMl = 0 },
        bloodLossIron = 0,
        hydration = 100.0,
        energyFeedback = 1.0,
        training = {
            dayLoad = 0, recoveryDebt = 0, overtrainDays = 0,
            lastSessionEndAge = -1, proteinWindowUntil = -1,
        },
        exposure = { wet = 0, sun = 0, highTemp = 0 },
        history = {},
        lastSettleDay = -1,
        disease = {},
        acute = {},
        effects = { caffeineUntil = -1, caffeineReboundUntil = -1 },
        prefs = { uiOpen = false },
    }
end

-- 叶子级默认合并（§6.4：只加不删、链式幂等；更高 schema 只告警）
function RM.Data._mergeTo(dst, proto)
    for k, v in pairs(proto) do
        local cur = dst[k]
        if cur == nil then
            if type(v) == "table" then
                local t = {}
                RM.Data._mergeTo(t, v)
                dst[k] = t
            else
                dst[k] = v
            end
        elseif type(v) == "table" and type(cur) == "table" then
            RM.Data._mergeTo(cur, v)
        end
    end
end

function RM.Data.migrate(md)
    if md.schema == nil then md.schema = RM.Config.schemaVersion end
    if md.schema > RM.Config.schemaVersion then
        RM.Log.warn("存档来自更高 schema 版本(" .. tostring(md.schema) .. ")，按当前版本谨慎读取")
    end
    RM.Data._mergeTo(md, RM.Data.freshState())
    if type(md.history) ~= "table" then md.history = {} end
    -- history 只存数字（§6.4）：非表条目剔除；必须压紧数组，
    -- 原位置 nil 会留洞 → # 运算返回 0 → table.insert/滚动裁剪错位
    local clean, n = {}, 0
    for i = 1, #md.history do
        local e = md.history[i]
        if type(e) == "table" then
            n = n + 1
            clean[n] = e
        end
    end
    md.history = clean
    return md
end

function RM.Data.ensurePlayer(player)
    if not player then return nil end
    local ok, md = pcall(function() return player:getModData() end)
    if not ok or not md then return nil end
    if type(md["RM"]) ~= "table" then md["RM"] = RM.Data.freshState() end
    return RM.Data.migrate(md["RM"])
end

-- 秒级内存累计 ↔ 持久化（§6.1：消耗走内存，每 10 游戏分钟落盘；进食/饮水即时）
function RM.Data.loadLive(player)
    local md = RM.Data.ensurePlayer(player)
    if not md then return nil end
    RM.State.live.hydration = md.hydration
    RM.State.live.energyFeedback = md.energyFeedback
    return md
end

function RM.Data.commitLive(player, md)
    if not md then return end
    md.hydration = RM.Util.clamp(RM.State.live.hydration or md.hydration, 0, 100)
    md.energyFeedback = RM.Util.clamp(RM.State.live.energyFeedback or md.energyFeedback, 0, 1)
end

-- ---------------- 食物微量表（每 100g；钠/钾/钙/铁 mg，维A/维D µg，维C mg，B1 mg） ----------------
-- 数值为首版参考（USDA 量级），M4 按平衡规格调优；键为 B42 物品全名，未命中走关键词/兜底
local function M(sodium, potassium, calcium, iron, vitA, vitC, vitD, vitB1)
    return { sodium = sodium, potassium = potassium, calcium = calcium, iron = iron,
             vitA = vitA, vitC = vitC, vitD = vitD, vitB1 = vitB1 }
end

local FOODS = {
    -- 水果
    ["Base.Apple"]      = M(1,107,6,0.1,3,4.6,0,0.017),
    ["Base.Orange"]     = M(1,181,40,0.1,11,53,0,0.087),
    ["Base.Banana"]     = M(1,358,5,0.3,3,8.7,0,0.031),
    ["Base.Strawberry"] = M(1,153,16,0.4,1,58.8,0,0.024),
    ["Base.Grapes"]     = M(2,191,10,0.4,3,3.2,0,0.069),
    ["Base.Watermelon"] = M(1,112,7,0.2,28,8.1,0,0.033),
    -- 蔬菜
    ["Base.Carrot"]     = M(69,320,33,0.3,835,5.9,0,0.066),
    ["Base.Potato"]     = M(6,421,12,0.8,0,19.7,0,0.098),
    ["Base.Broccoli"]   = M(33,316,47,0.7,31,89.2,0,0.071),
    ["Base.Cabbage"]    = M(18,170,40,0.8,61,36.6,0,0.061),
    ["Base.Tomato"]     = M(5,237,10,0.3,42,13.7,0,0.037),
    ["Base.Onion"]      = M(4,146,23,0.2,0,7.4,0,0.046),
    ["Base.RedRadish"]  = M(16,233,25,0.3,0,14.8,0,0.012),
    ["Base.ChiliPepper"]= M(9,340,18,1.2,59,242,0,0.07),
    ["Base.Mushroom"]   = M(5,318,18,0.5,0,2.1,0.2,0.081),
    ["Base.Corn"]       = M(15,270,2,0.5,9,6.8,0,0.155),
    ["Base.Avocado"]    = M(7,485,12,0.55,7,10,0,0.067),
    ["Base.Pumpkin"]    = M(1,340,21,0.8,426,9,0,0.05),
    ["Base.Eggplant"]   = M(2,229,9,0.2,1,2.2,0,0.039),
    -- 肉蛋
    ["Base.Chicken"]    = M(77,229,14,1,9,0,0.1,0.07),
    ["Base.Beef"]       = M(60,318,12,1.9,7,0,0.1,0.05),
    ["Base.Pork"]       = M(55,366,7,0.9,2,0,0.4,0.7),
    ["Base.Bacon"]      = M(1500,500,10,0.8,3,0,0.3,0.4),
    ["Base.Ham"]        = M(1300,300,8,1,5,0,0.3,0.6),
    ["Base.Mutton"]     = M(72,318,10,2.3,0,0,0.1,0.09),
    ["Base.Steak"]      = M(65,320,12,2,7,0,0.1,0.06),
    ["Base.Egg"]        = M(142,138,56,1.8,160,0,2,0.03),
    ["Base.Tofu"]       = M(7,121,350,5.4,0,0,0,0.08),
    -- 鱼类
    ["Base.Salmon"]     = M(59,363,9,0.3,58,0,11,0.23),
    ["Base.Sardines"]   = M(500,397,382,2.9,32,0,4.8,0.08),
    ["Base.Tuna"]       = M(320,237,11,1.6,17,0,1.7,0.03),
    -- 罐头（钠高、维 C 低 —— 罐头经济的坏血病压力）
    ["Base.CannedBeans"]       = M(400,300,60,2,0,0,0,0.1),
    ["Base.CannedSoup"]        = M(800,100,20,0.5,50,2,1,0.05),
    ["Base.CannedCorn"]        = M(400,130,10,0.8,3,2,0,0.03),
    ["Base.CannedPotato"]      = M(300,380,10,0.7,0,8,0,0.08),
    ["Base.CannedTomato"]      = M(300,290,30,1.5,21,10,0,0.06),
    ["Base.CannedPeas"]        = M(300,270,30,2.5,40,10,0,0.15),
    ["Base.CannedChili"]       = M(750,400,50,2,30,5,0,0.1),
    ["Base.CannedMushroomSoup"]= M(750,90,20,0.6,0,0,0.5,0.05),
    ["Base.Dogfood"]           = M(800,200,150,4,50,0,0.5,0.2),
    -- 主食/烘焙
    ["Base.Bread"]      = M(400,230,50,3,0,0,0,0.5),
    ["Base.BreadSlices"]= M(400,230,50,3,0,0,0,0.5),
    ["Base.Croissant"]  = M(450,130,30,2,100,0,0.2,0.4),
    ["Base.Cake"]       = M(300,130,40,1.5,80,0,0.1,0.1),
    ["Base.Cookie"]     = M(300,150,20,1,20,0,0.1,0.05),
    ["Base.Chocolate"]  = M(30,560,40,8,2,0,0,0.03),
    ["Base.Chips"]      = M(500,1264,24,1.6,0,5,0,0.17),
    ["Base.Pasta"]      = M(6,223,21,1.3,0,0,0,0.9),
    ["Base.Rice"]       = M(5,115,28,0.8,0,0,0,0.58),
    ["Base.Pancake"]    = M(430,130,80,2,50,0,0.2,0.2),
    ["Base.PeanutButter"]= M(430,649,43,1.9,0,0,0,0.14),
    ["Base.Cornbread"]  = M(550,280,130,2,50,0,0.1,0.3),
    ["Base.Pie"]        = M(300,120,20,1,15,2,0,0.1),
    ["Base.Honey"]      = M(4,52,6,0.4,0,0.5,0,0),
    ["Base.MapleSyrup"] = M(12,212,102,0.1,0,0,0,0.012),
    ["Base.Jam"]        = M(18,77,11,0.4,5,8,0,0),
    ["Base.Oatmeal"]    = M(2,61,54,4.7,0,0,0,0.46),
    ["Base.Cereal"]     = M(600,150,30,20,500,20,3,1.2),
    -- 乳制品
    ["Base.Butter"]         = M(11,24,24,0,684,0,1.5,0.005),
    ["Base.Cheese"]         = M(621,98,721,0.7,265,0,0.5,0.027),
    ["Base.Milk"]           = M(43,150,125,0.1,46,0,1.3,0.044),
    ["Base.EvaporatedMilk"] = M(127,303,261,0.2,74,1.9,0.5,0.16),
    ["Base.Yogurt"]         = M(46,141,121,0.1,27,0.5,0.1,0.029),
}

-- 关键词兜底行（按序匹配显示名小写）
local KEYWORD_ROWS = {
    { "sardine",  M(500,397,382,2.9,32,0,4.8,0.08) },
    { "tuna",     M(320,237,11,1.6,17,0,1.7,0.03) },
    { "salmon",   M(59,363,9,0.3,58,0,11,0.23) },
    { "fish",     M(60,350,20,0.8,30,0,5,0.15) },
    { "mushroom", M(5,318,18,0.5,0,2.1,0.2,0.081) },
    { "cereal",   M(600,150,30,20,500,20,3,1.2) },
    { "oat",      M(2,61,54,4.7,0,0,0,0.46) },
    { "yogurt",   M(46,141,121,0.1,27,0.5,0.1,0.029) },
    { "soup",     M(800,100,20,0.5,50,2,1,0.05) },
    { "dogfood",  M(800,200,150,4,50,0,0.5,0.2) },
}
-- 通用兜底（未收录食品的保守均值）
local FALLBACK_ROW = M(300,250,40,1,50,5,0.5,0.2)

function RM.Data.lookupMicro(item)
    local name = ""
    if item then
        -- B42: getFullName() 在 Food 上不存在且 Kahlua 无法 pcall 捕获，
        -- 改用肯定存在的 getFullType()（如 "Base.Apple"，与 FOODS 表键一致）
        local ok, ft = pcall(function() return item:getFullType() end)
        if ok and ft then name = tostring(ft) end
    end
    local row = FOODS[name]
    if row then return row end
    -- 关键词扫描（显示名小写）
    local dn = ""
    local ok2, d = pcall(function() return item and item:getDisplayName() end)
    if ok2 and d then dn = string.lower(tostring(d)) end
    if dn ~= "" then
        for i = 1, #KEYWORD_ROWS do
            if string.find(dn, KEYWORD_ROWS[i][1], 1, true) then return KEYWORD_ROWS[i][2] end
        end
    end
    return FALLBACK_ROW
end

-- ---------------- 饮品表（每 100ml；§10.6 字段） ----------------
-- B42 架构：酒精饮品为 base:normal + FluidContainer，酒精在 Fluid.Properties.alcohol
-- 原生 DrinkFluid 已自动触发 JustDrankBoozeFluid，MOD 不重复触发醉酒
-- MOD 表字段：hydrationEfficiency / diuretic / alcoholGrams(空热量7kcal/g) / caffeineMg / sugarGrams / category
local function B(efficiency, diuretic, alcohol, caffeine, sugar, category, microTopUp)
    return { hydrationEfficiency = efficiency, diuretic = diuretic,
             alcoholGrams = alcohol, caffeineMg = caffeine, sugarGrams = sugar,
             category = category, microTopUpPer100ml = microTopUp }
end

-- 按 Fluid 类型查表（FluidContainer 饮品：啤酒/葡萄酒/烈酒/汽水/果汁/水/咖啡/茶）
-- 键名 = Fluid.getFluidTypeString() 返回值（fluids.txt / fluids_Beverages.txt / fluids_Alcoholic.txt 中的 fluid 名）
local FLUID_BEVERAGES = {
    -- 水
    ["Water"]            = B(1.0, 0.0, 0, 0, 0, "water", nil),
    ["CarbonatedWater"]  = B(1.0, 0.0, 0, 0, 0, "water", nil),
    -- 奶
    ["CowMilk"]          = B(0.85, 0.0, 0, 0, 5, "milk", { calcium = 125, vitD = 1.3, vitA = 46 }),
    ["AnimalMilk"]       = B(0.85, 0.0, 0, 0, 5, "milk", { calcium = 125, vitD = 1.3, vitA = 46 }),
    ["SheepMilk"]        = B(0.85, 0.0, 0, 0, 5, "milk", { calcium = 195, vitD = 1.3, vitA = 83 }),
    ["MilkChocolate"]    = B(0.85, 0.0, 0, 0, 11, "milk", { calcium = 125 }),
    -- 汽水
    ["Cola"]             = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["ColaDiet"]         = B(0.85, 0.1, 0, 8, 0, "soda", nil),
    ["GingerAle"]        = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaPop"]          = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaLime"]         = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaGrape"]        = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaBlueberry"]    = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaPineapple"]    = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaStrewberry"]   = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    ["SodaBubblegum"]    = B(0.85, 0.1, 0, 8, 10.4, "soda", nil),
    -- 咖啡/茶
    ["Coffee"]           = B(0.9, 0.15, 0, 95, 0, "coffee", nil),
    ["Tea"]              = B(0.92, 0.1, 0, 40, 0, "tea", nil),
    ["Honey"]            = B(0.8, 0.0, 0, 0, 0, "other", nil),
    -- 果汁
    ["JuiceApple"]       = B(0.85, 0.0, 0, 0, 12, "juice", { vitC = 42, potassium = 100 }),
    ["JuiceOrange"]      = B(0.85, 0.0, 0, 0, 12, "juice", { vitC = 40, potassium = 200, vitA = 8 }),
    ["JuiceGrape"]       = B(0.85, 0.0, 0, 0, 12, "juice", { vitC = 40 }),
    ["JuiceCranberry"]   = B(0.85, 0.0, 0, 0, 10, "juice", { vitC = 40 }),
    ["JuiceFruitpunch"]  = B(0.85, 0.0, 0, 0, 10, "juice", { vitC = 40 }),
    ["JuiceLemon"]       = B(0.85, 0.0, 0, 0, 12, "juice", { vitC = 40 }),
    ["JuiceTomato"]      = B(0.85, 0.0, 0, 0, 13, "juice", { vitC = 40, potassium = 200 }),
    ["SpiffoJuice"]      = B(0.85, 0.0, 0, 0, 16, "juice", { vitC = 40 }),
    ["SimpleSyrup"]      = B(0.8, 0.0, 0, 0, 0, "other", nil),
    -- 酒精流体（原生 DrankBoozeFluid 已自动醉酒，MOD 仅记空热量+训练恢复）
    ["Beer"]             = B(0.0, 1.2, 3.9, 0, 3.6, "beer", nil),
    ["Cider"]            = B(0.0, 1.0, 3.2, 0, 0.8, "beer", nil),
    ["Mead"]             = B(0.0, 1.0, 4.7, 0, 0, "beer", nil),
    ["Wine"]             = B(-0.2, 1.5, 9.5, 0, 0, "wine", nil),
    ["Champagne"]        = B(-0.2, 1.5, 9.5, 0, 2.5, "wine", nil),
    ["Sherry"]           = B(-0.2, 1.5, 11.8, 0, 6.9, "wine", nil),
    ["Vermouth"]         = B(-0.2, 1.5, 11.8, 0, 3.3, "wine", nil),
    ["Port"]             = B(-0.2, 1.5, 12.6, 0, 12.9, "wine", nil),
    ["CoffeeLiqueur"]    = B(-0.3, 1.6, 15.8, 30, 2.1, "spirits", nil),
    ["Curacao"]          = B(-0.4, 1.8, 31.6, 0, 23.6, "spirits", nil),
    ["Brandy"]           = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Gin"]              = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Rum"]              = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Scotch"]           = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Tequila"]          = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Vodka"]            = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Whiskey"]          = B(-0.4, 1.8, 31.6, 0, 0, "spirits", nil),
    ["Grenadine"]        = B(0.8, 0.0, 0, 0, 67, "other", nil),
}

-- 按物品 ID 查表（Food 类饮品及无 Fluid 的容器，作为 Fluid 查表的补充）
local BEVERAGES = {
    -- 直接引用 FLUID_BEVERAGES，避免数据重复
    ["Base.WaterBottle"]             = FLUID_BEVERAGES["Water"],
    ["Base.BeerBottle"]              = FLUID_BEVERAGES["Beer"],
    ["Base.BeerCan"]                 = FLUID_BEVERAGES["Beer"],
    ["Base.BeerImported"]            = FLUID_BEVERAGES["Beer"],
    ["Base.Wine"]                    = FLUID_BEVERAGES["Wine"],
    ["Base.Wine2"]                   = FLUID_BEVERAGES["Wine"],
    ["Base.WineOpen"]                = FLUID_BEVERAGES["Wine"],
    ["Base.Wine2Open"]               = FLUID_BEVERAGES["Wine"],
    ["Base.WineAged"]                = FLUID_BEVERAGES["Wine"],
    ["Base.WineScrewtop"]            = FLUID_BEVERAGES["Wine"],
    ["Base.WineWhite_Boxed"]         = FLUID_BEVERAGES["Wine"],
    ["Base.WineRed_Boxed"]           = FLUID_BEVERAGES["Wine"],
    ["Base.Whiskey"]                 = FLUID_BEVERAGES["Whiskey"],
    ["Base.Vodka"]                   = FLUID_BEVERAGES["Vodka"],
    ["Base.Rum"]                     = FLUID_BEVERAGES["Rum"],
    ["Base.Gin"]                     = FLUID_BEVERAGES["Gin"],
    ["Base.Tequila"]                 = FLUID_BEVERAGES["Tequila"],
    ["Base.Champagne"]               = FLUID_BEVERAGES["Champagne"],
    ["Base.Cider"]                   = FLUID_BEVERAGES["Cider"],
    ["Base.CannedMilkOpen"]          = FLUID_BEVERAGES["CowMilk"],
    ["Base.CannedFruitBeverageOpen"] = FLUID_BEVERAGES["JuiceFruitpunch"],
    -- Food 类热饮（food.txt，无 FluidContainer，走 Eat 路径）
    ["Base.HotDrink"]                = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkTea"]             = B(0.92, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkTeaCeramic"]      = B(0.92, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkClay"]            = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkRed"]             = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkSpiffo"]          = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkWhite"]           = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkMetal"]           = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkCopper"]          = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkGold"]            = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkSilver"]          = B(0.9, 0.1, 0, 40, 0, "tea", nil),
    ["Base.HotDrinkTumbler"]         = B(0.9, 0.1, 0, 40, 0, "tea", nil),
}

-- 两级查找：Fluid 类型 → 物品 ID；未命中返回 nil 并记录 WARN（不做关键词兜底，避免误判掩盖漏表）
function RM.Data.resolveBeverage(item)
    if not item then return nil end

    -- 1. FluidContainer 类饮品：按流体类型查表（B42 "喝什么"由 Fluid 决定）
    local okFc, fc = pcall(function() return item:getFluidContainer() end)
    if okFc and fc ~= nil then
        local okPf, pf = pcall(function() return fc:getPrimaryFluid() end)
        if okPf and pf ~= nil then
            local okName, fname = pcall(function() return pf:getFluidTypeString() end)
            if okName and fname then
                local row = FLUID_BEVERAGES[tostring(fname)]
                if row then return row end
            end
        end
    end

    -- 2. 按物品 ID 查表（Food 类饮品/无流体容器）
    local ok, ft = pcall(function() return item:getFullType() end)
    if ok and ft then
        local row = BEVERAGES[tostring(ft)]
        if row then return row end
    end

    -- 未命中：记录告警，返回 nil（调用方需防御）
    local dn = ""
    local ok2, d = pcall(function() return item:getDisplayName() end)
    if ok2 and d then dn = tostring(d) end
    local ftStr = ""
    if ok and ft then ftStr = tostring(ft) end
    RM.Log.warn("resolveBeverage: 未收录饮品 fullType=" .. ftStr .. " name=" .. dn .. "（请补 FLUID_BEVERAGES 或 BEVERAGES）")
    -- 同步写入探针日志，便于在测试面板直接观察
    if RM.Probe and RM.Probe._write then
        pcall(RM.Probe._write, "bev_unknown", {
            "fullType", ftStr,
            "name", dn,
        })
    end
    return nil
end

-- ---------------- 每日累计器（写 modData，进食/饮水即时） ----------------
function RM.Data.addMicro(player, key, gain)
    if gain ~= gain or gain == 0 then return end          -- NaN 防御
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    if md.micro[key] == nil then md.micro[key] = 0 end
    md.micro[key] = md.micro[key] + gain
end

function RM.Data.addSweat(player, key, amount)
    if amount ~= amount or amount == 0 then return end
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    if md.sweat[key] == nil then md.sweat[key] = 0 end
    md.sweat[key] = md.sweat[key] + amount
end

function RM.Data.addBloodLossIron(player, amount)
    if amount ~= amount or amount == 0 then return end
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    md.bloodLossIron = (md.bloodLossIron or 0) + amount
end

-- 水合即时写入（§6.1）；ml×效率×每 ml 回补，可为负（酒类净脱水）
function RM.Data.addWater(player, ml, efficiency)
    if ml ~= ml or ml == 0 then return end
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    local perMl = RM.Config.hydration.perMl
    local gain = ml * (efficiency or 1.0) * perMl
    RM.State.live.hydration = RM.Util.clamp((RM.State.live.hydration or md.hydration) + gain, 0, 100)
    md.hydration = RM.State.live.hydration
end

-- 燃料台账（§9.1：只记 MOD 内部账，不驱动原生消耗）
function RM.Data.recordFuel(player, entry)
    local f = RM.State.fuel
    f.mix.carbs = entry.carbsRatio or f.mix.carbs
    f.mix.fat = entry.fatRatio or f.mix.fat
    f.mix.protein = entry.proteinRatio or f.mix.protein
end

-- 今日训练负荷（强度加权；M1 只累计均值，M2 Training 扩展）
function RM.Data.recordLoad(player, intensity, durationSec)
    local f = RM.State.fuel
    f.seconds = f.seconds + durationSec
    f.sumIntensity = f.sumIntensity + intensity * durationSec
end

-- ---------------- 原生宏量只读（§16.1 判空 + pcall） ----------------
function RM.Data.readNutrition(player)
    local out = { calories = 0, carbohydrates = 0, lipids = 0, proteins = 0, weightKg = 70 }
    if not player then return out end
    local ok, n = pcall(function() return player:getNutrition() end)
    if not ok or not n then return out end
    local function grab(fn, dflt)
        local ok2, v = pcall(fn)
        if ok2 and type(v) == "number" then return v end
        return dflt
    end
    out.calories = grab(function() return n:getCalories() end, 0)
    out.carbohydrates = grab(function() return n:getCarbohydrates() end, 0)
    out.lipids = grab(function() return n:getLipids() end, 0)
    out.proteins = grab(function() return n:getProteins() end, 0)
    out.weightKg = grab(function() return n:getWeight() end, out.weightKg)
    return out
end
