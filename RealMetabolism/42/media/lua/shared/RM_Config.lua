-- ============================================================
-- 模块名   : RM_Config
-- 职责     : 集中全部可调参数（DRI/TDEE/水合/燃料/评分/修饰器/UI）
-- 所属里程碑: M1（数值按设计文档定稿；M4 阶段按平衡规格调优，逻辑不感知）
-- 对外接口 : RM.Config（只读参数表）
-- 依赖     : 无（shared 中的首个加载文件）
-- 备注     : §20.4 禁止散落魔法数 —— 全部系数集中于此
-- ============================================================
RM = RM or {}
RM.Config = {
    modId = "RealMetabolism",
    schemaVersion = 1,      -- modData schema 版本（技术文档 §6.2）
    debug = false,          -- true 时输出调试日志
    saveEveryGameMin = 10,   -- 秒级内存累计落盘间隔（技术文档 §6.1/§13）

    -- ---------------- 微量营养素 ----------------
    DRI = {                 -- 每日参考需求（设计 §4.1）
        sodium = 2000,      -- mg
        potassium = 3000,   -- mg
        calcium = 1000,     -- mg
        iron = 15,          -- mg
        vitA = 900,         -- µg
        vitC = 100,         -- mg
        vitD = 15,          -- µg
        vitB1 = 1.2,        -- mg
    },
    microKeys = { "sodium", "potassium", "calcium", "iron", "vitA", "vitC", "vitD", "vitB1" },

    dailyFixedLoss = {      -- 日固定流失（M2 出汗 / M3 出血另行叠加）
        sodium = 500, potassium = 400, calcium = 100, iron = 1,
        vitA = 300, vitC = 30, vitD = 5, vitB1 = 0.3,
    },

    scoreTiers = { danger = 0.50, attention = 0.80, ok = 1.15 },  -- r_i 分档（设计 §8.3）

    -- ---------------- 热量 ----------------
    TDEE = { resting = 2000, moderate = 2700, high = 3400 },      -- kcal/日（设计 §4.1）
    tdeeTier = { moderateMinI = 0.15, highMinI = 0.45 },          -- 当日平均强度 → TDEE 档

    -- ---------------- 水合（设计 §6.2/§10.4）----------------
    hydration = {
        baseDrainPerHour = 5.0,   -- 基础流失 点/游戏小时（M4 目标体感：正常活动约 6–8 游戏小时降 40 点）
        perMl = 0.10,             -- 白水回补 点/ml
        thirstUnitMl = 10,        -- 物品 ThirstChange 每 1 点解渴 ≈ ml（TODO(S1): 上机标定语义）
        tiers = {                 -- 从高到低，min 含边界（h ≥ min 落入该档）
            { min = 60, recovery = 1.00, max = 1.00, id = "normal"   },
            { min = 40, recovery = 0.85, max = 1.00, id = "thirsty"  },
            { min = 20, recovery = 0.60, max = 0.85, id = "low"      },
            { min = 0,  recovery = 0.35, max = 0.70, id = "critical" },
        },
    },

    -- ---------------- 能量反馈（设计 §9.2）----------------
    energy = {
        carbSaturation = 300,     -- 原生碳水池视为"满"的参考值 TODO(S2): 实测池范围后标定
        lowBelow = 0.30,          -- 反馈低于此值 → 恢复×0.85 / 上限×0.90
        frozenBelow = 0.05,       -- 低于此值 → 恢复冻结
        lowRecovery = 0.85,
        lowMax = 0.90,
        frozenRecovery = 0.0,
    },

    -- ---------------- 燃料底物（设计 §9.1）----------------
    fuel = {
        postureRate = { rest = 1.0, sneak = 1.4, walk = 2.0, run = 4.0, sprint = 7.0 },
        loadCorrection = {       -- 负重比（inventoryWeight/maxWeight）→ 强度修正（设计 §9.1）
            { maxRatio = 0.25, mult = 1.00 },
            { maxRatio = 0.50, mult = 1.15 },
            { maxRatio = 0.75, mult = 1.30 },
            { maxRatio = 99.0, mult = 1.50 },
        },
        highIntensityMin = 0.55,     -- I ≥ 此值 → 高强度曲线（跑步及以上）
        lowIntensityMax = 0.30,       -- I ≤ 此值 → 低强度曲线（步行及以下）
        durationShiftPerMin = 0.002, -- 低强度随持续时间 carbs→fat 漂移
        fastedCarbsBelow = -200,     -- 原生碳水池低于此值 → 空腹 TODO(S2): 实测标定
        mix = {
            high    = { carbs = 0.75, fat = 0.25, protein = 0.00 },
            mid     = { carbs = 0.50, fat = 0.50, protein = 0.00 },
            low     = { carbs = 0.30, fat = 0.70, protein = 0.00 },
            fasted  = { carbs = 0.20, fat = 0.80, protein = 0.00 }, -- 空腹/碳水枯竭
            deficit = { carbs = 0.15, fat = 0.70, protein = 0.15 },  -- 长期亏空+持续高负荷（仅记台账）
        },
        deficitDaysForProtein = 3,   -- 连续热量亏空 ≥N 天才记录蛋白消耗
        deficitEnergyBelow = -0.5,   -- 单日能量分 d 低于此值计为"亏空日"
        -- 瞬时动作折算（翻越/爬绳/翻窗等）TODO(S5): TimedAction 方法名实测后接入（M2 训练阶段接线）
    },

    -- ---------------- 修饰器归一化（技术文档 §11）----------------
    modifier = {
        mul = { min = 0.50, max = 1.50 },   -- 乘区相乘后 clamp
        add = { min = -0.35, max = 0.20 }, -- 加区求和后 clamp
        cap = { min = 0.65, max = 1.20 },   -- 耐力上限因子 min 后 clamp
    },

    -- ---------------- 历史与节奏 ----------------
    historyDays = 7,   -- 历史保留条数（设计 §6.2）
    graceDays = 7,     -- 新档宽限天数（M3 疾病用；历史照记）

    -- ---------------- UI ----------------
    ui = {
        toggleKeyName = "KEY_N",   -- 面板开关键（OnKeyKeepPressed 解析；ModOptions 可改键 TODO(S2)）
        refreshMs = 250,            -- 面板可见时最小刷新间隔
    },
}
