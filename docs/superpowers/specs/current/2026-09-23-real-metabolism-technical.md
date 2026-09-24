# Real Metabolism（真实代谢）MOD 技术文档

- 日期：2026-09-23
- 目标版本：Project Zomboid **Build 42.20.x（stable）**
- 关联设计：[2026-09-22-real-metabolism-design.md](./2026-09-22-real-metabolism-design.md)（v3，三大子系统）
- 前序技术文档：[2026-09-22-zomboid-nutrition-mod-technical.md](../deprecated/2026-09-22-zomboid-nutrition-mod-technical.md)（v2 营养子系统，已弃用）
- API 审查依据：Zombie Atlas 对本地 B42.20.4 反编译源码（3,078 Java 文件）的逐项核实
- 状态：技术评审稿（含待实测项，见 §18）

> **阅读对象**：负责本 MOD 编码与调试的 Lua 开发者。
> **本文性质**：v3 设计的工程实现方案。数值/平衡以 v3 设计文档为准，本文规定"用什么 API、放在哪个文件、以什么时序执行"，并附编码约束（§20 开发规范）。

---

## 1. 文档目的与范围

把 v3《Real Metabolism》设计落成可编码方案，覆盖**营养 / 运动 / 环境**三大平级子系统，重点解决：

1. MOD 如何被加载：B42 版本化目录、NeatUI 前置依赖、`lua` 三类文件夹时机。
2. 每个设计功能挂在哪个真实 B42 API 上：继承 v2 勘误，新增体温/代谢/流体/锻炼/醉酒等 API 核实。
3. 模块划分、数据结构、结算时序、待实测项。

不包含：具体食物/饮品数值录入、美术资产、Workshop 发布流程。

---

## 2. 技术栈与运行环境

| 项 | 说明 |
|---|---|
| MOD 标识 | `RealMetabolism`（mod id），MOD 内全局表统一为 `RM` |
| 游戏版本 | Build 42.20.x；目录用版本化文件夹 `42/` |
| 脚本语言 | Lua **5.1 语法**，运行时 **Kahlua**（非 LuaJIT）；禁用 bit/jit/goto 等专有特性 |
| Java 互操作 | 静态方法 `.`、实例方法 `:`；全程不直接读实例字段（B42.15+ Release 限制），只用 getter/setter |
| UI 框架 | **NeatUI Framework [B42] 硬前置依赖**（Workshop ID 3508537032），经自有适配层 `RM_UIAdapter.lua` 隔离（见 §12） |
| 网络模式 | 单机优先；写入函数预留 `isAuthority` 开关，第一版不联机验证（§14） |

### 2.1 开发环境

- 开发目录：`%UserProfile%\Zomboid\mods\RealMetabolism\`。
- Steam 启动项加 `-debug`；日志 `Zomboid/console.txt`；F11 调试器。
- VS Code + Lua 5.1 诊断 + EmmyLua/Umbrella 类型库。

---

## 3. MOD 包结构与加载机制

### 3.1 最终目录（对齐 v3 设计 §9）

```
RealMetabolism/
└── 42/
    ├── mod.info                 -- 声明 NeatUI 前置与加载顺序
    └── media/lua/
        ├── shared/
        │   ├── RM_Config.lua           -- 全部参数（DRI/TDEE/燃料曲线/降解/饮品/疾病/环境/图标）
        │   ├── RM_DataLayer.lua        -- 微量表/饮品表/降解折算/原生宏量读取/兜底
        │   ├── RM_History.lua          -- 7 天历史与每日结算
        │   ├── RM_Scoring.lua          -- 纯函数：评分/归一化/燃料分配/恢复系数
        │   └── Translate/EN|CN/
        ├── client/
        │   ├── RM_UIAdapter.lua        -- 唯一接触 NeatUI 的适配层
        │   ├── RM_Panel.lua            -- 代谢面板/趋势/健康
        │   ├── RM_StatusIcons.lua      -- 角落状态图标层
        │   └── RM_Theme.lua            -- Vanilla-Native 主题令牌
        └── server/
            ├── RM_Commands.lua         -- 写操作封装（单机本地/预留 MP）
            ├── RM_Core.lua             -- 状态初始化/schema/结算编排/事件挂载
            ├── RM_Fuel.lua             -- 底物燃料切换、瞬时动作、能量反馈（M1）
            ├── RM_Hydration.lua        -- 水合池（M1）
            ├── RM_Environment.lua      -- 温湿度/湿身/日照、急性事件（M2）
            ├── RM_Beverages.lua        -- 饮品药效（酒精/咖啡因/糖）（M2）
            ├── RM_Training.lua         -- 负荷/恢复/蛋白窗口/过度训练（M2）
            ├── RM_Decay.lua            -- 食物分类降解（M3）
            └── RM_Diseases.lua         -- 7 营养缺乏病状态机（M3）
```

说明：

- 结算逻辑分两层：**纯数据/纯函数**（Config/DataLayer/History/Scoring）放 `shared`，保证启动阶段可用、三模式一致；**状态机/事件驱动逻辑**（Core/Fuel/Hydration/...）放 `server`，单机进入世界时加载（见 §3.2），事件实际在 `OnCreatePlayer`（晚于 server 加载）后挂载，时机安全。
- 所有文件置于二级目录避免同路径覆盖；不使用 `media/scripts/`（不新增物品）。

### 3.2 `lua` 三类文件夹加载时机（B42.20 源码核实）

| 文件夹 | 单人模式 | 多人客户端 | 多人服务器 |
|---|---|---|---|
| `client` | ✅（启动阶段） | ✅（启动阶段） | ❌ |
| `server` | ✅（进入世界时） | ✅（进入世界时） | ✅（读档时加载） |
| `shared` | ✅（启动阶段） | ✅（启动阶段） | ✅（读档时加载） |

调用链：启动阶段无参 `LuaManager.LoadDirBase()` 加载 shared → client；进入世界时 [GameLoadingState.java:149](file:///d:/project/Zedema/zombie/gameStates/GameLoadingState.java#L149) 补 `LoadDirBase("server")`；单机 `LoadingQueueState` 立即重定向到 GameLoadingState，因此单机同样加载 server。

硬约束：

1. client 可引用 shared 的 `RM` 表，反向禁止。
2. server 文件在单机可用但**不可在启动阶段被引用**；纯函数/常量必须放 shared。
3. NeatUI（shared/client 类）必须先于本 MOD 加载。

### 3.3 `mod.info`

```ini
name=Real Metabolism（真实代谢）
id=RealMetabolism
description=营养/运动/环境三子系统的真实生理仿真：微量营养、底物燃料、水合、环境急症、训练恢复。
author=用户 × Trae
version=0.1.0
require=NeatUI_Framework
workshop=3508537032
```

- `require` 填 NeatUI 的 mod id；`workshop` 填其 Workshop ID（加载顺序/字段写法列入 §18-S7 实测）。
- 若 NeatUI 缺失，启动时弹明确报错（§12.5）。

---

## 4. B42 API 基线核查

### 4.1 v2 勘误继承（仍然有效）

K1 无 `OnEatFood`/`OnEat` 事件；K2 server 时机（见 §3.2）；K3 Kahlua/Lua5.1；K4 `Stats` 枚举容器化；K5 `AddXP` 重载与本地玩家限制；K6 无 `isCrouching`，用 `isSneaking`；K7 无 `OnGameDay`，用 `EveryDays`（0:00）。详见 v2 技术文档 §4。

### 4.2 v3 新增已核实 API

**体温与代谢（`zombie.characters.BodyDamage.Thermoregulator`，实际生效类；`Thermoregulator_tryouts.java` 为实验副本不生效）**

| API | 说明 |
|---|---|
| `BodyDamage:getThermoregulator()` | 返回 Thermoregulator（[BodyDamage.java:152](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyDamage.java#L152)） |
| `:getCoreTemperature()` / `getCoreTemperatureUI()` | 核心体温（℃，约 37 基准） |
| `:getMetabolicRate()` / `getMetabolicRateReal()` / `getMetabolicTarget()` | 当前代谢率/MET 目标 |
| `:getMovementModifier()` / `getCombatModifier()` | 极端体温下的动作/战斗修正（只读） |
| `:getFluidsMultiplier()` / `getEnergyMultiplier()` / `getFatigueMultiplier()` | 体温应激派生倍率（只读，每帧由内部 `updateBodyMultipliers` 重算） |
| `:setMetabolicTarget(Metabolics)` / `setMetabolicTarget(float met)` | **可写但仅影响产热**：抬 Thermoregulator 的代谢目标地板（只升不降、帧末重置），不进入热量账（[IsoGameCharacter.java:13910-13918](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L13910-L13918)） |
| `Thermoregulator.setSimulationMultiplier(float)` | **静态可写但仅缩放体温/产热仿真**，不缩放热量消耗（[Thermoregulator.java:85](file:///d:/project/Zedema/zombie/characters/BodyDamage/Thermoregulator.java#L85)） |

**代谢档位枚举（`Metabolics`，@UsedFromLua）**：Sleeping .8 / SeatedResting 1.0 / StandingAtRest 1.1 / SedentaryActivity 1.2 / DrivingCar 1.4 / Default 1.5 / LightDomestic 1.6 / Walking2kmh 1.9 / HeavyDomestic 2.0 / Walking5kmh 3.1 / LightWork 3.2 / MediumWork 3.9 / UsingTools 2.5 / DefaultExercise 3.0 / HeavyWork 6.0 / DiggingSpade 5.5 / ForestryAxe 8.0 / Running10kmh 6.9 / Running15kmh 9.5 / Fitness 6.0 / FitnessHeavy 9.0 / JumpFence 4.0 / ClimbRope 8.0 / MAX 10.3。

**锻炼（`Fitness` + `FitnessExercise`）**

| API | 说明 |
|---|---|
| `IsoPlayer:getFitness()` | 返回 `Fitness`（定义于 [IsoPlayer.java:6750](file:///d:/project/Zedema/zombie/characters/IsoPlayer.java#L6750)，非 BodyDamage） |
| `:getRegularity(String type):float` / `getRegularityMap()` | 锻炼规律性（[Fitness.java:379](file:///d:/project/Zedema/zombie/characters/BodyDamage/Fitness.java#L379)） |
| `:setCurrentExercise(String)` / `getCurrentExe()` | 当前锻炼 |
| `:reduceEndurance()` | 按规律性/负重扣耐力（内部 `stats.remove(ENDURANCE)`，[Fitness.java:169](file:///d:/project/Zedema/zombie/characters/BodyDamage/Fitness.java#L169)） |
| 锻炼定义 | `Fitness.init()` 读全局 Lua 表 **`FitnessExercises.exercisesType`**，每项字段 `type / metabolics / stiffness / xpMod`（[Fitness.java:396-410](file:///d:/project/Zedema/zombie/characters/BodyDamage/Fitness.java#L396-L410)）。MOD 可在 init 前向该全局表追加锻炼类型 |
| `BodyPart:getStiffness()` / `setStiffness(v)` / stiffness 累加 | 僵硬 0–100（getStiffness [BodyPart.java:1921](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyPart.java#L1921)、setStiffness [:1925](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyPart.java#L1925)、累加 addStiffness [:1938](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyPart.java#L1938)） |

**流体（`zombie.entity.components.fluids`）**

| API | 说明 |
|---|---|
| `FluidContainer:getFilledRatio()` / `getCapacity()` / `getAmount()` | 填充比/容量/当前量（[FluidContainer.java:544](file:///d:/project/Zedema/zombie/entity/components/fluids/FluidContainer.java#L544)） |
| `FluidContainer:getProperties()` | 返回 **SealedFluidProperties**（[FluidContainer.java:522](file:///d:/project/Zedema/zombie/entity/components/fluids/FluidContainer.java#L522)） |
| `SealedFluidProperties` | `getAlcohol()`、`getCalories/Carbohydrates/Lipids/Proteins`、`getHungerChange/ThirstChange/FatigueChange/StressChange/UnhappyChange`、`getEnduranceChange`、`getPoison`、`getPainReduction`、`getFluReduction`、`getFoodSicknessChange`（**无 caffeine 字段**，咖啡因走 MOD 自配表） |

**天气与暴露（`ClimateManager`）**

| API | 说明 |
|---|---|
| `getHumidity()` | 相对湿度 0–1（Thermoregulator 以 >0.5 为高湿） |
| `getRainIntensity()` / `getPrecipitationIntensity()` | 降雨强度 |
| `getCloudIntensity()` | 云量（日照折减用，[ClimateManager.java:516](file:///d:/project/Zedema/zombie/iso/weather/ClimateManager.java#L516)） |
| `getSeason()` / `getSeasonId()` / `getWeatherPeriod()` | 季节/天气周期（含 isThunderStorm/hasHeavyRain 等判定） |
| `getTemperature()` / `getAirTemperatureForCharacter(p, false)` | 环境气温/体感温度 |
| `IsoGridSquare:isOutside()` | 户外判定 |
| `BodyPart:getWetness()` / `InventoryItem:getWetness()` | 身体/服装湿润度 0–100（Thermoregulator 以 ×0.01 折算） |

**酒精/醉酒（原生机制，MOD 复用）**

| API | 说明 |
|---|---|
| `CharacterStat.INTOXICATION` | 醉酒度 0–100（[CharacterStat.java:21](file:///d:/project/Zedema/zombie/characters/CharacterStat.java#L21)） |
| `BodyDamage:JustDrankBooze(Food, percentage)` | public：按食物酒精度加 INTOXICATION；名字含 beer 或有 LOW_ALCOHOL tag 时 ×0.25，空腹 ×1.1/1.25（[BodyDamage.java:466-488](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyDamage.java#L466-L488)） |
| `BodyDamage:JustDrankBoozeFluid(float alcohol)` | public：饮含酒流体时调用 |
| 原生触发点 | Eat 流程 [BodyDamage.java:616](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyDamage.java#L616)；DrinkFluid 流程 [IsoGameCharacter.java:5872](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L5872) |

**食物年龄与储存**

| API | 说明 |
|---|---|
| `InventoryItem:getAge()` / `setAge(float)` | 储存年龄（天，float；[InventoryItem.java:2634](file:///d:/project/Zedema/zombie/inventory/InventoryItem.java#L2634)） |
| `InventoryItem:getContainer()` → `ItemContainer` | 所在容器 |
| `ItemContainer:isFridge()` / `isFreezer()` / `isPowered()` | 冷藏/冷冻/通电（[ItemContainer.java:3760-3767](file:///d:/project/Zedema/zombie/inventory/ItemContainer.java#L3760-L3767)） |

### 4.3 对 v3 设计的一处 API 修正（重要）

v3 设计 §3.1/Spike S3 假设存在可写挂点 `Multiplier.MetabolicRateInc/Dec`，用于分别调制碳水/脂肪消耗速率。核实结果（经 Zombie Atlas 对生效类完整调用链复核）：

- 生效类 [Thermoregulator.java:1045](file:///d:/project/Zedema/zombie/characters/BodyDamage/Thermoregulator.java#L1045) **定义了 private enum Multiplier**（与实验副本 `Thermoregulator_tryouts` 同名同成员），并提供 public 只读访问器 `getMetabolicRateIncMultiplier()`（554）、`getMetabolicRateDecMultiplier()`（558）等。但它们的值是**固定常数**（MetabolicRateInc=0.001、MetabolicRateDec=4e-4）× 全局标量 simulationMultiplier，**无写入口**，不构成按池分别调制的挂点。
- 代谢侧的真实可写入口只有两个：**`setMetabolicTarget(Metabolics/float)`** 与 **静态 `setSimulationMultiplier(float)`**。但经调用链核实，二者**影响的是"产热"而非"热量/宏量消耗"**（语义见下，§9.1 已据此更正）。
- 引擎**不提供**"按比例分别驱动碳水池/脂肪池消耗"的外部接口；`fluidsMultiplier/energyMultiplier/fatigueMultiplier` 只读且内部重算。热量消耗在 [Nutrition.updateCalories:75-115](file:///d:/project/Zedema/zombie/characters/BodyDamage/Nutrition.java#L75-L115) 按真实姿态独立结算；三池按固定速率流失（[Nutrition.java:63-65](file:///d:/project/Zedema/zombie/characters/BodyDamage/Nutrition.java#L63-L65)）。

**实现口径（S3 核实后定稿）**：

1. MOD 自行维护"底物燃料分配"台账：由强度/时长/空腹查表得到碳水/脂肪/蛋白**应燃比例**，作为 MOD 状态记录与 UI 数据（§9.1）。
2. **不声称能重定向原生宏量消耗**：`setMetabolicTarget`/`setSimulationMultiplier` 只用于环境子系统的冷/热应激**产热**调制（§9.1、§10），不用于燃料切换；不分别改写四池。
3. 燃料切换的"可验证性"通过 MOD 台账 + 原生四池读数的相关性在长周期仿真中确认（§17），而非逐池强写。
4. 蛋白质"被动用"在 MOD 侧只记账与触发训练/疾病惩罚，不直接驱动原生蛋白池。
5. 若未来要影响热量消耗，唯一可研究入口是 TimedAction 链上的 `BaseCharacterAction.caloriesModifier`（Nutrition.updateCalories 第 77–78 行读取），列为 Spike 待实测，本期不做。

---

## 5. 总体架构

### 5.1 全局命名空间

```lua
RM = RM or {
    Config=nil, Data=nil, History=nil, Scoring=nil,   -- shared
    Core=nil, Commands=nil,                            -- server
    Fuel=nil, Hydration=nil, Environment=nil,
    Beverages=nil, Training=nil, Decay=nil, Diseases=nil,
    State=nil,                                         -- 运行时瞬时（非持久化）
    UI=nil,                                            -- client 聚合
}
```

模块间只通过 `RM.*` 公开函数通信；禁止散落全局（`FitnessExercises` 等引擎全局表除外）。

### 5.2 依赖方向

```
shared: RM_Config ─► RM_DataLayer ─► RM_Scoring ─► RM_History
server: RM_Commands ─► RM_Core（编排）
            RM_Fuel / RM_Hydration / RM_Environment /
            RM_Beverages / RM_Training / RM_Decay / RM_Diseases ─► RM_Core
client: RM_UIAdapter(NeatUI) ─► RM_Panel / RM_StatusIcons ─只读─► shared/server 查询函数
```

UI 不写任何结算数据；client/server 不反向依赖。

### 5.3 两阶段引导

1. **定义阶段**：各文件加载只定义表与函数，不挂事件。
2. **启动阶段**（`RM_Core.lua` 挂 `Events.OnCreatePlayer`，幂等）：
   - `RM.Data.ensurePlayer(player)`：建/迁移 modData（§6.3）；
   - `RM.Core.attach(player)`：挂接进食 TimedAction 包装（§8.1）、恢复疾病/急性事件修饰（§11）；
   - client 侧 `RM.UI.init()`。
   - `Events.OnGameStart` 再做一次修饰器挂载（处理读档），全部幂等。

---

## 6. 数据设计

### 6.1 持久化原则

- 只写玩家 modData 单一根对象 `md["RM"]`；KahluaTable 只存基础类型，不存 Java 对象/函数。
- 写入时机：进食/饮水（即时）、秒级消耗（内存累计，每 10 游戏分钟落盘）、每日结算（即时）、疾病/急性事件阶段变化（即时）。

### 6.2 玩家存档结构（schema 1）

```lua
md["RM"] = {
    schema = 1,
    -- 微量当日摄入（钠/钾 mg；钙 mg；铁 mg；维A µg；维C mg；维D µg；B1 mg）
    micro = { sodium=0, potassium=0, calcium=0, iron=0,
              vitA=0, vitC=0, vitD=0, vitB1=0 },
    -- 当日出汗流失（并入微量净额）
    sweat = { sodium=0, potassium=0, waterMl=0 },
    -- 当日出血流失（铁）
    bloodLossIron = 0,
    -- 水合连续池
    hydration = 100.0,
    -- 小时级能量反馈（0–1，派生自原生碳水/热量池）
    energyFeedback = 1.0,
    -- 训练
    training = {
        dayLoad = 0,                 -- 当日负荷（强度加权）
        recoveryDebt = 0,            -- 恢复债
        overtrainDays = 0,           -- 连续高负荷低恢复天数
        lastSessionEndAge = -1,      -- 上次训练结束的世界小时
        proteinWindowUntil = -1,     -- 蛋白合成窗口截止世界小时
    },
    -- 环境暴露当日累计（分钟）
    exposure = { wet=0, sun=0, highTemp=0 },
    -- 7 天滚动历史
    history = {
        -- { day, net={8项}, score={8项+energy}, exercise=0..1,
        --   hydration=0..100, weightKg, sunMins }
    },
    lastSettleDay = -1,
    -- 疾病（id → {level, deficitDays, recoverDays}）
    disease = {},
    -- 急性事件（id → { untilAge=世界小时, cooldownUntil=世界小时 }）
    acute = {},
    -- 饮品/咖啡因等短时药效（内部计时，见 §10.6）
    effects = { caffeineUntil=-1, caffeineReboundUntil=-1 },
    prefs = { uiOpen=false },
}
```

### 6.3 `ensurePlayer` 与迁移

```lua
function RM.Data.ensurePlayer(player)
    local md = player:getModData()
    if type(md["RM"]) ~= "table" then md["RM"] = RM.Data.freshState() end
    RM.Data.migrate(md["RM"])
end
```

### 6.4 存档兼容契约

继承 v2 技术文档 §6.5 全部条款（引擎序列化白名单、number 读回为 Double、整数 math.floor、链式幂等迁移只加不删、失败中止不 wipe、降级未知 schema 只告警、禁用-重启用空档不补算与修饰器重算、id 不改名、history 只存数字、叶子级默认合并、发布前升档/降档双向实测）。本文 schema 从 1 起。

---

## 7. 代谢核心（`RM_Core.lua`）

- 注册统一累加器：`OnPlayerUpdate` 驱动，按世界时间差归一化（不按帧数），每秒触发一次 `tickSecond(player, dt)`；各子系统注册自己的秒结算回调。
- 权威开关：`RM.Core.isAuthority(player)`（单机恒 true；MP 预留）。
- 编排每日结算（§8.4）与修饰器汇总（§11）。
- 所有 MOD 逻辑 pcall 包裹，错误只记日志，不阻断游戏。

---

## 8. 营养子系统

### 8.1 进食挂接（继承 v2 路径①）

包装 TimedAction（`__rmHooked` 幂等标记，先保存原链）：

- `ISEatFoodAction.complete/eat`：吃前取 `preWeight=item:getActualWeight()`，原版 Eat 后调 `RM.Core.onEat(item, player, ratio, preWeight)`。
- `ISDrinkFluidAction.start/perform/stop`：**单机 `isClient()=true` 导致 `update()` 内不调 `updateEat()`**，饮水由 Java `DrinkFluid` 异步完成。故在 `start` 记录 `__rmStartRatio` + `__rmCapacity`，在 `perform`/`stop` 按 `(startRatio − curRatio) × capacity × 1000` 计算饮水量 ml。
- `ISDrinkFromBottle.start/drink/perform`：测试面板"Drink Water"等自动饮水走此路径，`drink` 内 `getStats():Drink(uses)` 后按比例算 ml。

### 8.2 微量记账与降解折算

```lua
function RM.Core.onEat(item, player, ratio, preWeightKg)
    local grams100 = (preWeightKg * 1000.0) * ratio / 100.0
    local row = RM.Data.lookupMicro(item)               -- 每100g 微量行（精确/兜底）
    local ret = RM.Decay.retention(item)                -- 8 项各自保留率
    for k, v in pairs(row) do
        local gain = v * grams100 * (ret[k] or 1.0)
        RM.Data.addMicro(player, k, gain)
    end
    RM.Beverages.onConsume(item, player, ratio, grams100) -- 水合/药效
end
```

宏量不记账（原生已入账）；只记微量、触发水合与药效。

### 8.3 每日净额与评分

- 净摄入 = 微量摄入 − 日固定流失 − 出汗（sweat）− 出血（bloodLossIron）。
- 评分 `r_i = 净摄入 / DRI`；能量 `d = clamp(热量净额/TDEE档, -1, 1)`（读原生池计算）。
- UI 分档：<50% 危险 / 50–80% 注意 / 80–115% 达标 / >115% 过量。

### 8.4 每日结算（EveryDays 0:00，含读档补算）

`RM.History.onEveryDays`：按 `lastSettleDay` 幂等 → 算 net/score → 入 7 天历史 → 重建派生缓存 → 疾病评估 → 训练日结 → 清零当日计数器。跨日读档最多补 1 天（沿用 v2）。

---

## 9. 运动子系统

### 9.1 底物燃料模型（`RM_Fuel.lua`）

每秒产出两信号：

- **强度 I**（0–1）：移动姿态映射（静息0 / 蹲走潜行 / 步行 / 跑步 / 冲刺），瞬时动作折算等效冲刺秒数。
- **持续时间 T**：同强度连续时长。

燃料比例查表（Config `fuelMix`：强度轴 × 空腹轴 → 碳水/脂肪/蛋白比例）：

| 场景 | 碳水 | 脂肪 | 蛋白 |
|---|---|---|---|
| 冲刺/战斗/攀爬（高强短时） | 高 | 低 | ≈0 |
| 步行/潜行/劳作（低强长时） | 中→随 T 降 | 中→随 T 升 | ≈0 |
| 空腹 + 碳水枯竭（读原生池） | 低 | 高 | 0 |
| 长期亏空 + 持续高负荷 | 低 | 高 | 记账拆蛋白 |

结果**只写入 MOD 内部台账**（供 UI、成长、疾病与长周期仿真验证）。引擎按真实姿态独立结算热量与三池、且三池为固定速率流失，**没有可从外部按底物重定向消耗的入口**，因此 `RM_Fuel.lua` 不调用任何代谢/热量写入：

```lua
-- 台账记录：仅保存"应燃比例"，不驱动原生消耗
RM.Data.recordFuel(player, {
    intensity = I, duration = T,
    carbsRatio   = mix.carbs,     -- Config fuelMix 查表
    fatRatio     = mix.fat,
    proteinRatio = mix.protein,   -- 长期亏空才 >0，只记账
})
```

`setMetabolicTarget` / `setSimulationMultiplier` **不在燃料模型中使用**——经调用链核实它们调制的是 Thermoregulator 的"产热"（getHeatGeneration 即 metabolicRateReal），不是热量账；热量消耗在 Nutrition.updateCalories 按真实姿态独立分支。这两个挂点仅在环境子系统冷/热应激时用于产热（§10），且 setMetabolicTarget 是"每帧只升不降"的地板、帧末重置，不能作为连续消耗控制。

- 动作强度相对倍率：静息1.0/蹲走1.4/步行2.0/跑步4.0/冲刺7.0。
- 瞬时动作等效冲刺秒：翻越2–4、爬绳4–6、翻窗2–3、上下楼1–2×负重比、重击1–3；**无跳跃动作**。
- 战斗不重复扣宏量（原生挥击已消耗），只计训练负荷与出汗流失。
- **负重修正**用负重比 `inventoryWeight/maxWeight`（×1.0/1.15/1.3/1.5）。

### 9.2 小时级能量反馈（`energyFeedback`）

由原生碳水/热量池水平派生 0–1；偏低：耐力恢复 ×0.85、上限 −10%；枯竭：恢复冻结。纳入统一归一化，总修正 clamp ±20%。

### 9.3 训练负荷、恢复与适应（`RM_Training.lua`）

挂原生 `Fitness`（规律性/僵硬/reduceEndurance），MOD 只增数据与调制：

- **负荷**：有效动作按 I×T 累积 `dayLoad`；高负荷映射原生僵硬（可向 `FitnessExercises.exercisesType` 追加 MOD 锻炼定义，字段 metabolics/stiffness/xpMod）。
- **恢复质量** = f(睡眠时长质量、蛋白满足度、总热量、水合、微损伤)。
- **蛋白窗口**：训练结束起 Config（默认 4 游戏小时）内 `proteinWindowUntil`，成长公式蛋白权重提高。
- **超量适应**：恢复完成后该类锻炼经验收益放大，与原生 regularity 正反馈叠加。
- **过度训练保护**：连续 N 天高负荷低恢复 → `overtrainDays++`，成长打折、疲劳加速、僵硬加重。
- **空腹/亏空训练**：负荷照计，恢复与收益显著降低。

### 9.4 长期成长（XP）

```lua
if player:getNutrition():canAddFitnessXp() then
    player:getXp():AddXP(PerkFactory.Perks.Fitness, deltaF, true, false)
    player:getXp():AddXP(PerkFactory.Perks.Strength, deltaS, true, false)
end
```

Fitness 偏碳水/有氧，Strength 偏蛋白/盈余；零训练零成长；负向降级在 R4 验证前只做压制收益+疲劳惩罚（沿用 v2）。

---

## 10. 环境子系统

### 10.1 环境采样（`RM_Environment.lua`）

每秒（节流后按分钟累计）读取：体感温度、湿度、雨强、云量、`square:isOutside()`、身体/服装 wetness。只取结果，不逐件建模服装。

### 10.2 出汗与流失模型

出汗量 = f(强度 I, 温度, 湿度)：高湿抑制蒸发 → 出汗更多（读 `getHumidity`）。产出：

- 水流失 `sweat.waterMl`、钠/钾流失（写入 `sweat.sodium/potassium`，每日并入微量评分）。
- 湿身时高温助蒸发（出汗略减），低温放大失温（§10.5）。

### 10.3 日照与维 D

`isOutside` 且白天，按 `(1−cloudIntensity)` 累计 `exposure.sun`；维 D 回补 = sunMins × Config 系数。暴晒轻微加速脱水。

### 10.4 水合池（`RM_Hydration.lua`）

`hydration ∈ [0,100]`：

- 补充：饮水/饮品（按补水效率）、含水食物（按含水量/汤走流体）。
- 流失：基础常数 + 出汗（§10.2）+ 酒精/咖啡因利尿项。

阈值效果（连续，进统一归一化）：

| 水平 | 效果 |
|---|---|
| 100–60 | 正常 |
| 60–40 | 耐力恢复下降、口渴提示 |
| 40–20 | 耐力上限/恢复明显下降、疲劳加快 |
| <20 | 强制踉跄、视野暗角，叠加高温快速导向中暑 |

脱水与低钠分开：纯水补大量出汗后可能 hydration 正常但血钠低 → 电解质事件（靠咸食/电解质）。

### 10.5 急性环境事件（连续池越阈，独立于 7 天病状态机）

| 事件 | 触发链 | 表现（有前兆、可逆） |
|---|---|---|
| 热痉挛/低钠抽搐 | 高温高湿大量出汗、钠钾严重流失 | 前兆提示 → 短暂硬控（删除"控制倒置"） |
| 中暑（热射病） | 核心体温持续超阈 + 脱水 | 强制踉跄、意识模糊视觉，须撤离热源+补水 |
| 失温 | 低温 + 湿身 + 持续暴露 | 动作变慢、剧烈颤抖、精度下降；火源/干衣恢复 |
| 脱水崩溃 | hydration<20 持续 | §10.4 重度表现 |

事件带 `untilAge`（持续期）与 `cooldownUntil`（冷却），解除条件明确；与疾病共用统一归一化器。核心体温阈值读 `getCoreTemperature()`（具体阈值进 Config，S8/S2 实测标定）。

### 10.6 饮品药效（`RM_DataLayer.lua` BEVERAGES / `RM_Beverages.lua`）

**B42 架构（S7② 验证）**：饮品分两类——Food 类（`base:food`，走 `BodyDamage.Eat`）与 FluidContainer 类（`base:normal`，走 `IsoGameCharacter.DrinkFluid`）。酒精含量在 **Fluid 的 `Properties.alcohol`**（0.0–1.0），不在物品字段；原生**无 caffeine/sugar 字段**（糖在 `Carbohydrates`，咖啡/茶提神靠 `fatigueChange`）。

饮品数据字段（每 100ml）：`hydrationEfficiency / diuretic / alcoholGrams / caffeineMg / sugarGrams / category`。

**查表优先级**（`RM.Data.resolveBeverage`）：
1. **Fluid 类型**：`item:getFluidContainer():getPrimaryFluid():getFluidTypeString()` → `FLUID_BEVERAGES`（覆盖所有瓶装/罐装饮品，同一瓶可装不同流体）
2. **物品 ID**：Food 类饮品（热饮等无 FluidContainer）→ `BEVERAGES`
3. **未命中**：`RM.Log.warn` 记录 `fullType`/`name`，同时写探针日志 `bev_unknown` 事件（测试面板可见），返回 `nil`，调用方（`onDrink`）`if not row then return end` 跳过。**不做关键词/分类兜底**，避免误判掩盖漏表。

- **水合**：净补水 = amount × hydrationEfficiency − 延迟利尿项（diuretic）。
- **酒精**：`DrinkFluid` 已自动调 `BodyDamage.JustDrankBoozeFluid(fluid.alcohol)` 触发 `INTOXICATION`，MOD **不重复触发**（无 `JustDrankBooze` 调用）。MOD 的 `alcoholGrams` 仅用于：空热量记账（7 kcal/g 写入原生热量池）、训练恢复打折、醉酒图标判定。
  醉酒联动：主观变暖而实际失温风险上升（低温湿身加重）、耐力/协调下降（原生 `INTOXICATION` 驱动）；长期频繁摄入降低训练恢复质量。
- **咖啡因**（原生无字段，MOD 自建计时）：`caffeineUntil` 内疲劳增长减半；`caffeineReboundUntil` 疲劳增长×1.5 反弹。通过统一归一化作用，不硬写原生。
- **糖**：Fluid 的 `Carbohydrates` 由 `DrinkFluid` 自动写入原生营养池，MOD 不重复记宏量。

> 注意：物品脚本 `Alcoholic = true` 仅用于绷带（消毒），饮品不用；`alcoholPower` 字段存在但醉酒逻辑不调用，勿依赖。

---

## 11. 统一惩罚归一化（`RM_Scoring.lua`）

所有耐力相关来源（能量反馈、水合、疾病、急性事件、咖啡因、过度训练）在同一通道汇总：

- 乘区相乘 clamp [0.5,1.5]；加区求和 clamp [−0.35,+0.2]；耐力上限 clamp [0.65,1.2]。
- 修饰器全部为**可重算纯派生物**，不保存"已扣减"值；摘除来源即还原，防存档漂移。
- 急性硬控（setBlockMovement）单独走事件计时，死亡/登出必清理（R6）。

---

## 12. UI 与 NeatUI 适配

### 12.1 适配层（`RM_UIAdapter.lua`，唯一接触 NeatUI）

业务代码只调适配层接口：`makePanel/makeTabs/makeBar/makeList/makeLineChart/makeIconHost/drawText` 等；NeatUI API 只出现在此文件。NeatUI 不兼容时重写适配层，业务零改动。

### 12.2 代谢面板（`RM_Panel.lua`）

三页：状态（8 微量 + 宏量读原生 + 水合 + 能量反馈 + 今日负荷）、7 天趋势（折线）、健康（疾病等级/急性事件/恢复与过度训练/改善建议）。可见时节流刷新 ≥250ms，关闭移除监听。

### 12.3 角落状态图标（`RM_StatusIcons.lua`）

7 营养病（四阶段）+ 脱水/中暑/失温/低钠/醉酒/咖啡因/过度训练；风格对齐原版 moodle（NeatUI 非 moodle 框架，自建+借渲染助手）。早期疾病模糊图标，病名在面板查看。

### 12.4 入口与文案

- N 键（可改，ModOptions S2 实测，fallback OnKeyKeepPressed）+ 原版健康面板整合区块。
- 文案 `getText()` + Translate/EN、CN，不硬编码。
- Nutritionist trait 控制毫克精度；无 trait 只看定性档。

### 12.5 依赖缺失处理

启动检测 NeatUI：缺失时弹明确提示（引导订阅 Workshop 3508537032），MOD 不加载业务逻辑，不抛堆栈。

---

## 13. 关键时序

**进食/饮水**：TimedAction → 取吃前重量 → 原版 Eat/DrinkFluid（原生宏量/INTOXICATION 在此）→ MOD 微量（×降解保留率）+ 水合 + 药效 → 即时落盘。

**每秒**：环境采样 → 出汗流失 → 燃料强度/台账（只记 MOD 账，不动原生消耗）→ 训练负荷 → 能量反馈 → 修饰器汇总写入（每 10 游戏分钟落盘）。原生热量/三池由引擎按真实姿态独立结算。

**每日 0:00**：净/评分 → 历史 → 疾病评估 → 训练日结（恢复/窗口/超量/过度训练）→ 成长 XP（canAddFitnessXp 门控）→ 计数清零。

**急性事件**：池越阈 → 前兆 → 硬控/表现（untilAge）→ 条件解除 → 冷却。

---

## 14. 多人预留（第一版不启用）

- 秒级驱动（OnPlayerUpdate）与 TimedAction 仅客户端 → MP 改服务端权威：客户端上报 + 服务端校验。
- 原生 JustDrankBooze 在服务端流程同样触发，可作服务端挂钩。
- 全局共享数据走 `ModData.getOrCreate("RM.Global")` + transmit/request；玩家私有结果仍存玩家 modData。
- XP 同步走 [PlayerXpPacket](file:///d:/project/Zedema/zombie/network/packets/PlayerXpPacket.java)（`getXp().save/load` 全量同步，requiredCapability=CanModifyPlayerStatsInThePlayerStatsUI，reliability=2）。
- `isAuthority` 开关预留，第一版不引网络代码。

---

## 15. 性能预算

| 项 | 措施 |
|---|---|
| OnPlayerUpdate | 只读、不闭包、固定顺序判定、1s 节流、修饰汇总每秒 ≤1 次 |
| 进食/饮水 | 瞬时执行，哈希查表 O(1)，包装只装一次 |
| 每日 | 7 历史 + 7 疾病，常量级 |
| UI | 不可见停刷新；折线 7 点定长；文本缓存 |
| 目标 | 平均 <0.2ms/帧；温度/负重查询必要时秒级缓存 |

---

## 16. 错误处理与兼容性

1. 原生调用一律判空（getPrimaryHandItem/getNutrition/getContainer 早期时序）。
2. 食物先 `instanceof(item,"Food")`；字符串字段 tostring 兜底。
3. hook 一律"包装+pcall+原链透传"，MOD 错误不阻断原版动作。
4. 只读字段不硬写；写入前 clamp，除零返回中性 0，NaN 防御。
5. 多 MOD 兼容：统一包装保存原链，不独占 setOnEat；先后包装自然成链。
6. 酒精触发去重，防原生+MOD 双计。

---

## 17. 调试与测试

- 纯函数单测（Lua 5.1，离线）：评分、燃料分配、降解保留率、饮品净补水、恢复系数、疾病状态机。
- "生理人"长周期仿真（M4）：罐头党/均衡/高运动战士/雨季湿身/酗酒流，30–60 天验证燃料切换、疾病节奏、水合急症、成长曲线。
- Debug 工具（仅 -debug）：喂食/给水/设天气与湿身/跳天含睡眠加速/强制疾病事件/打印燃料比例与流失明细/dump。
- 持久化：操作→退主菜单→读档比对；跨 0:00 补算；升档/降档双向（§6.4）。
- SandboxVars：疾病速率、消耗倍率、环境严酷度、降解速率、水合严格度、单病/单事件开关、日照产 D。

---

## 18. Spike 0 待实测项（S1–S9 现状）

反编译已回答"API 是否存在/签名"类问题；下列为**必须上机**确认行为的项：

| 编号 | 项 | 现状 |
|---|---|---|
| S1 | 吃前重量/腐烂/含水量语义、饮品与食物是否同事件、分次口数 | 签名已核实；行为待实测（v2 技术文档 R1/R12） |
| S2 | 原生池增减时机、睡眠加速、EveryDays 睡眠期触发、核心体温阈值标定 | 待实测 |
| S3 | 代谢调制路径：**已确认 setMetabolicTarget/setSimulationMultiplier 只调制产热、不进热量账**（§4.3、§9.1）；分别驱动四池不可行；待实测仅为环境产热调用的实际体感 | 路径已关闭，仅余行为实测 |
| S4 | FitnessExercise 追加写法、负 AddXP、regularity/stiffness 读写行为 | 结构已核实；负增量待实测 |
| S5 | 瞬时动作 TimedAction hook、z-level、thump、无跳跃 | 类已核实；方法名待实测 |
| S6 | 夜盲光照、HumanVisual、输入锁定、伤口判定 | 待实测 |
| S7 | NeatUI：require/加载顺序写法、组件清单、SP/MP、版本兼容；角落图标实现；饮品/酒原生字段盘点与醉酒联动 | 待实测（UI 与饮品定稿前最高优先） |
| S8 | 湿度/雨/云量 API、户外日照判定、湿身状态 | API 已核实；行为待实测 |
| S9 | modData schema、单机 command 行为、MP 同步预留 | 结构已核实；联机行为待实测 |

---

## 19. 实施里程碑（对齐 v3 M1–M4）

1. **M1 代谢核心**：mod.info（NeatUI 前置）+ Config/DataLayer/Scoring（freshState/ensure/migrate + 60–80 食物/饮品表 + 兜底）+ Core 编排 + Hydration + Fuel 内部台账（不挂原生消耗）+ UI 框架适配 + **存档往返测试**（§6.4）。
2. **M2 运动与环境**：Environment（湿/日照/暴露）+ 出汗模型 + 急性事件 + Beverages（酒精复用原生/咖啡因）+ Training（负荷/恢复/窗口/过度训练）。
3. **M3 降解与疾病**：Decay 分类降解 + 7 病状态机（不做骨折）。
4. **M4 平衡打磨**：长周期仿真、数值调优、沙盒选项、性能阈值、console 清理。

---

## 20. 开发规范

> 适用于本 MOD 全部 Lua 编码；与 §5（架构）、§16（错误处理）、§17（测试）配合使用，冲突时以本文为准并更新对方。

### 20.1 总则

| 原则 | 含义 |
|---|---|
| **最小实现** | 只做当前里程碑（§19）定义的功能。不写前瞻代码、预留参数、死开关、"以后可能用到"的抽象；需求出现时再改。三行重复好过过早抽象 |
| **复用优先** | 原生机制 > MOD 内已有模块 > 新代码。醉酒/宏量/热量/腐烂/经验门控一律走原生；同一段逻辑第二次出现必须抽公共函数 |
| **只读边界** | 严格按 §4.3 口径：不硬写原生池/倍率；燃料只记 MOD 台账；`setMetabolicTarget`/`setSimulationMultiplier` 仅环境子系统的产热调制 |
| **解耦** | 模块间只经 `RM.*` 公开函数通信，禁止散落全局；NeatUI 只出现在 `RM_UIAdapter.lua`；UI 零写入，只读查询 |
| **因果可验证** | 每个效果都能回答"身体发生了什么"；所有平衡数值进 Config，逻辑层不感知体感 |

### 20.2 结构规范

- 依赖方向固定（§5.2），禁止反向：client/shared 不依赖 server；server 不引用 client；UI 不写结算数据。
- 分层放置（§3.1）：纯数据/纯函数 → `shared`；状态机/事件驱动 → `server`；渲染 → `client`。新文件不动既有文件位置。
- 单文件单一职责；禁止一个文件跨层跨子系统。
- 文件头注释四项：模块名、职责、所属里程碑（M1–M4）、对外接口列表。

### 20.3 命名规范

| 对象 | 规则 | 示例 |
|---|---|---|
| 全局表 | `RM`（唯一） | `RM.Config` |
| 公开函数 | 驼峰、动词开头 | `RM.Data.addMicro` |
| 内部函数 | 下划线前缀 | `RM.Core._accumulate` |
| 常量/系数 | Config 内大写或点分层键 | `RM.Config.DRI.vitC` |
| 事件回调 | `onXxx` | `onEveryDays` / `onEat` |
| 幂等/去重标记 | `__rm` 前缀 | `item.__rmHooked` |
| 持久化键 | schema 字段名**冻结不改**（§6.4），只加不删 | `micro` / `sweat` / `hydration` |

### 20.4 函数与数据

- 结算逻辑一律写成**无副作用纯函数**（入 shared，可离线单测）；副作用（写 modData、调引擎 setter）只集中在编排层（`RM_Core` 与各子系统入口函数）。
- 修饰器/评分/恢复系数一律**每次重算的纯派生物**，不保存"已扣减"值；摘除来源即还原（§11）。
- **数值零魔法数**：新系数一律进 `RM_Config.lua`，带单位注释；沙盒倍率经 Config 汇总后统一读取。
- modData 只存基础类型；写前 clamp；除零返回中性 0；NaN 防御（§16.4）。
- **幂等**：事件挂载、每日结算、schema 迁移、UI 初始化全部幂等，重复触发不产生双计。

### 20.5 Hook 规范

- **包装而非替换**：存原链 → 幂等标记 → pcall MOD 逻辑 → 原链透传；MOD 错误只记日志，不阻断原版动作（§16.3）。
- 不独占挂点：不覆盖其他 MOD hook，天然成链兼容（§16.5）。
- 与原生重复的效果（酒精 INTOXICATION 等）触发前判重（§16.6）。
- Hook 点集中登记在 `RM_Core`；禁止各文件私自包装全局函数。

### 20.6 性能红线（§15）

- `OnPlayerUpdate` 路径只读、不建闭包、不拼字符串；1s 节流。
- 每秒级逻辑一律挂统一累加器 `tickSecond`，禁止独立 Event 驱动。
- 查表 O(1)；历史/折线定长；UI 不可见即停刷。

### 20.7 测试与提交

- 纯函数必须可离线单测（Lua 5.1）；涉及存档的改动必须过**往返测试**（§6.4：操作→退主菜单→读档比对；升/降档双向）。
- **设计优先**：一律先按设计文档定稿方案实现主路径，禁止在实测前预先写降级/兜底分支（防御式缩水）；仅当 Spike 上机实测**确认主路径不可行**后，才改写降级方案，并在代码标注 `TODO(Sx)` 注明降级原因与触发条件。
- **降级前置审批**：任何需要放弃设计主路径、改用降级替代的决策，实现前**必须先询问用户确认**（说明主路径卡点、降级方案、功能影响），禁止自行切换。未获确认时保持主路径实现并记录实测问题。
- 每个里程碑收尾跑 §17 对应调试清单。
- 提交粒度：一个功能点一个 commit；schema 破坏性改动单独 commit。

### 20.8 禁止清单

| # | 禁止项 | 依据 |
|---|---|---|
| 1 | Lua 5.1 之外特性（bit/jit/goto）；直接读实例字段 | §2 Kahlua/B42.15+ |
| 2 | 双重计算：宏量/热量/醉酒重复记账 | §1 设计目标 |
| 3 | 保存"已扣减"值到 modData（派生物必须可重算） | §11 |
| 4 | NeatUI API 出现在 `RM_UIAdapter.lua` 之外 | §12.1 |
| 5 | 数值硬编码在逻辑文件 | §1/§20.4 |
| 6 | 启动阶段引用 server 文件 | §3.2 |
| 7 | 跨子系统直接读写对方内部状态 | §5.1 |
| 8 | 超出当前里程碑范围的功能 | §19 |

---

## 21. 附录：API 速查

```lua
-- 事件
Events.OnCreatePlayer.Add(fn)          -- fn(idx, player)
Events.OnPlayerUpdate.Add(fn)          -- fn(player) 每 tick
Events.EveryDays.Add(fn)               -- fn() 0:00
Events.OnKeyKeepPressed.Add(fn)        -- fn(key)
-- 玩家/原生（只读+规定挂点）
local p = getPlayer()
p:getModData()                                                  -- 持久化
p:getNutrition():getCalories()/getWeight()/canAddFitnessXp()
p:getStats():get(CharacterStat.ENDURANCE)/:set(CharacterStat.ENDURANCE,v)
p:getXp():AddXP(PerkFactory.Perks.Fitness, delta, true--[[noMult]], false--[[halo]])
p:isSprinting()/isRunning()/isSneaking()/isMoving()/getInventoryWeight()
-- 体温/代谢（setXxx 仅调产热、不进热量账；仅环境冷热应激用）
local tr = p:getBodyDamage():getThermoregulator()
tr:getCoreTemperature()/getMetabolicTarget()/getMovementModifier()
p:setMetabolicTarget(Metabolics.Running10kmh)   -- 只抬产热地板，不用于燃料切换
Thermoregulator.setSimulationMultiplier(1.0)    -- 只缩放体温/产热
-- 燃料底物：只记 MOD 台账（RM.Data.recordFuel），引擎无重定向消耗的入口
-- 锻炼（Fitness 定义于 IsoPlayer）
local fit = p:getFitness()
fit:getRegularity(type)/setCurrentExercise(type)
-- 流体
fc:getFilledRatio()/getCapacity()/getProperties():getAlcohol()/getHungerChange()
-- 天气/暴露
cm:getHumidity()/getRainIntensity()/getCloudIntensity()/getSeason()
cm:getAirTemperatureForCharacter(p,false)
sq:isOutside(); bodyPart:getWetness(); item:getWetness()
-- 醉酒（原生复用，注意去重）
bd:JustDrankBooze(food, ratio); bd:JustDrankBoozeFluid(alcohol)
CharacterStat.INTOXICATION
-- 食物年龄/储存
item:getAge(); item:getContainer():isFridge()/isFreezer()/isPowered()
-- 全局 ModData（MP 预留）
ModData.getOrCreate(tag)/transmit(tag)
```

### 参考来源

- v3 设计：[2026-09-22-real-metabolism-design.md](./2026-09-22-real-metabolism-design.md)
- v2 技术文档与 API 审查：[technical](../deprecated/2026-09-22-zomboid-nutrition-mod-technical.md)、[api-review](../deprecated/2026-09-22-zomboid-nutrition-mod-api-review.md)
- B42.20.4 本地反编译（Zombie Atlas）：`Thermoregulator/Metabolics/Fitness/FitnessExercise/FluidContainer/SealedFluidProperties/ClimateManager/BodyDamage/CharacterStat/InventoryItem/ItemContainer`
- NeatUI Framework [B42]：Workshop 3508537032
