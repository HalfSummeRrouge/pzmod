# Real Metabolism v3 技术文档 — Zombie Atlas API 审查报告

- 审查日期：2026-09-23
- 审查工具：Zombie Atlas（http://127.0.0.1:5184/，本地 B42.20.4 反编译源码：3,078 Java 文件 / 4,749 类型）
- 审查对象：[2026-09-23-real-metabolism-technical.md](./2026-09-23-real-metabolism-technical.md)
- 核实方式：逐项对照反编译 Java 源码与游戏目录 Lua 源文件

---

## 一、结论摘要

v3 技术文档整体 API 把握准确，**约 45 项 API 声明中绝大多数（41 项）核实通过**。发现 2 项中等问题（均集中在 §4.3/§9.1 的代谢调制论证，系上一轮修正时的反向误判）与 2 项轻微问题。

| 严重程度 | 数量 | 说明 |
|---|---|---|
| 🔴 严重 | 0 | — |
| 🟡 中等 | 2 | §4.3 Multiplier 枚举归属事实错误；§9.1 代谢挂点语义错误（setMetabolicTarget 只影响产热不影响热量消耗） |
| 🟢 轻微 | 2 | `AddXpPacket` 名称错误（实为 PlayerXpPacket）；BodyPart stiffness 行号标注偏差 |

好消息：文档的**核心工程结论（燃料比例只做 MOD 台账、不分别强写四池）仍然成立**，需要修正的是支撑该结论的事实表述与挂点选择。

---

## 二、核实通过的 API（41 项）

### 2.1 体温与代谢（Thermoregulator / Metabolics）

| 文档声明 | 核实 |
|---|---|
| `BodyDamage:getThermoregulator()`（构造 BodyDamage.java:152） | ✅ 方法在 [BodyDamage.java:3064](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyDamage.java#L3064) |
| `getCoreTemperature()` / `getCoreTemperatureUI()` | ✅ [Thermoregulator.java:374](file:///d:/project/Zedema/zombie/characters/BodyDamage/Thermoregulator.java#L374) / 410 |
| `getMetabolicRate()` / `getMetabolicRateReal()` / `getMetabolicTarget()` | ✅ 382 / 390 / 386 |
| `getMovementModifier()` / `getCombatModifier()` | ✅ 324 / 349 |
| `getFluidsMultiplier()` / `getEnergyMultiplier()` / `getFatigueMultiplier()` | ✅ 312 / 316 / 320（只读，内部 updateBodyMultipliers 重算） |
| `IsoGameCharacter:setMetabolicTarget(Metabolics/float)`（13910–13918） | ✅ 行号准确 |
| 静态 `setSimulationMultiplier(float)`（line 85） | ✅ |
| Metabolics 全部 24 档位数值 | ✅ 与 [Metabolics.java](file:///d:/project/Zedema/zombie/characters/BodyDamage/Metabolics.java) 逐一相符 |

### 2.2 锻炼（Fitness / FitnessExercise）

| 文档声明 | 核实 |
|---|---|
| `IsoPlayer:getFitness()`（IsoPlayer.java:6750，非 BodyDamage） | ✅ |
| `getRegularity(type)` / `getRegularityMap()` | ✅ [Fitness.java:379](file:///d:/project/Zedema/zombie/characters/BodyDamage/Fitness.java#L379) |
| `reduceEndurance()`（内部 stats.remove(ENDURANCE)） | ✅ 169 |
| `Fitness.init()` 读全局 `FitnessExercises.exercisesType`（字段 type/metabolics/stiffness/xpMod） | ✅ 396–410；全局表在游戏 [FitnessExercises.lua:1-3](file:///e:/Steam/steamapps/common/ProjectZomboid/media/lua/shared/Definitions/FitnessExercises.lua#L1-L3) 确实存在 |
| `setCurrentExercise` / `getCurrentExe` | ✅ |
| 三个翻越 TimedAction（ISClimbOverFence / ISClimbThroughWindow / ISClimbSheetRopeAction）均有 perform | ✅ 位于 client/TimedActions |

### 2.3 流体（FluidContainer / SealedFluidProperties）

| 文档声明 | 核实 |
|---|---|
| `getProperties()` / `getCapacity()` / `getFilledRatio()` / `getAmount()` | ✅ 522 / 535 / 544 / 563（上轮已把臆造的 getTotalAmount 改正为 getAmount） |
| SealedFluidProperties 15 个方法（alcohol/calories/carbs/lipids/proteins/hunger/thirst/fatigue/stress/unhappy/endurance/poison/painReduction/fluReduction/foodSickness） | ✅ 全部存在 |
| 无 caffeine 字段 | ✅ 确认 |

### 2.4 天气与暴露（ClimateManager / WeatherPeriod）

| 文档声明 | 核实 |
|---|---|
| `getHumidity()` / `getRainIntensity()` / `getPrecipitationIntensity()` | ✅ 528 / 593 / 488 |
| `getCloudIntensity()`（516） | ✅ |
| `getSeason()`（633）/ `getWeatherPeriod()`（663）/ `getSeasonId()` | ✅ |
| `getTemperature()` / `getAirTemperatureForCharacter(p,false)` | ✅ 472 |
| WeatherPeriod：isThunderStorm / isTropicalStorm / isBlizzard / hasHeavyRain | ✅ 170 / 174 / 178 / 232 |
| `IsoGridSquare:isOutside()` | ✅ 9963 |
| `BodyPart:getWetness()` / `InventoryItem:getWetness()` | ✅ 1913 / 4989 |

### 2.5 酒精/醉酒与食物储存

| 文档声明 | 核实 |
|---|---|
| `CharacterStat.INTOXICATION`（0–100，line 21） | ✅ |
| `BodyDamage:JustDrankBooze(Food, percentage)` / `JustDrankBoozeFluid(float)` | ✅ 466 / 490（LOW_ALCOHOL tag/空腹倍率逻辑与文档描述一致） |
| 原生触发点：Eat 流程 BodyDamage:616；DrinkFluid 流程 IsoGameCharacter:5872 | ✅（前置条件 `newFood.isAlcoholic()` / `consume.getAlcohol()>0`；`isAlcoholic()` 定义在 [InventoryItem.java:3348](file:///d:/project/Zedema/zombie/inventory/InventoryItem.java#L3348)） |
| `InventoryItem:getAge()`（2634）/ `getContainer()`（3849） | ✅ |
| `ItemContainer:isFridge()`（3764）/ `isFreezer()`（3760）/ `isPowered()`（2316） | ✅ |
| `getMaxWeight()` | ✅ [IsoGameCharacter.java:3981](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L3981) |
| GameLoadingState.java:149 `LoadDirBase("server")` | ✅ 行号准确 |

### 2.6 Lua 进食挂接与 ModOptions

| 文档声明 | 核实 |
|---|---|
| ISEatFoodAction.complete（173）/ eat（193），吃前取 actualWeight | ✅ 文件在 **shared/TimedActions**，Eat 调用行 174 / 199，percentage 复合逻辑与文档一致 |
| ISDrinkFluidAction.updateEat（109），流体填充比差值 | ✅ 原版内部同样以 `startRatio - getFilledRatio()` 计算（line 112/119），文档算法等价 |
| `PZAPI.ModOptions:create(id,name)` / `options:addKeyBind(id,name,key,tooltip)` | ✅ 签名与 [ModOptions.lua:247](file:///e:/Steam/steamapps/common/ProjectZomboid/media/lua/client/PZAPI/ModOptions.lua#L247) / 182 **完全一致** |
| 关键事件（EveryDays/OnKeyKeepPressed/OnNewGame 等） | ✅ 游戏 Lua 中实际挂接使用 |

> 补充：文档 §18 把 ModOptions addKeyBind 列为待实测；现签名已逐字核实，可降级为"仅运行时行为待实测"。

---

## 三、发现的问题

### 🟡 问题 1：§4.3 Multiplier 枚举归属事实错误

**文档声称**：
> `Multiplier` 是 `Thermoregulator_tryouts`（实验副本）中的 private 枚举……生效类 `Thermoregulator` 无该枚举。

**实际**：生效的 [Thermoregulator.java:1045](file:///d:/project/Zedema/zombie/characters/BodyDamage/Thermoregulator.java#L1045) **同样定义了 private enum Multiplier**（11 个成员，与 tryouts 一致），且提供了 public 只读访问器 `getMetabolicRateIncMultiplier()`（554）、`getMetabolicRateDecMultiplier()`（558）、`getBodyHeatMultiplier()` 等；getSimulationMultiplier 在 606–620，固定常数 MetabolicRateInc=0.001、MetabolicRateDec=4e-4，唯一变量是全局 simulationMultiplier。

**结论的正确部分**（仍成立）：这些是**固定常数 × 全局标量**，不构成"按池分别调制"的可写挂点；引擎确实不暴露分别驱动碳水池/脂肪池的接口。

**修正建议**：把"生效类无该枚举"改为"生效类有同名 private 枚举（1045）与只读 getter，但值为固定常数、无写入口"。

### 🟡 问题 2：§9.1 代谢挂点语义错误——setMetabolicTarget 影响产热，不影响热量消耗

文档 §9.1 工程口径写道：

> 对原生只施加总速率：`setMetabolicTarget` 选档 + `setSimulationMultiplier` 做连续微调。

经完整调用链核实，这两个挂点**不驱动热量/宏量池消耗**：

1. `metabolicRateReal` 就是**产热**：`getHeatGeneration()` 直接返回 metabolicRateReal（[Thermoregulator.java:378-379](file:///d:/project/Zedema/zombie/characters/BodyDamage/Thermoregulator.java#L378-L379)），它进入体温调节的热生成，不进入热量账。
2. **热量消耗独立运行**于 [Nutrition.updateCalories()](file:///d:/project/Zedema/zombie/characters/BodyDamage/Nutrition.java#L75-L115)：由**真实移动状态** `IsRunning()/isSprinting()/isPlayerMoving()/isAsleep()` 直接分支（modifier 1.0/1.3/0.6 等），外部无倍率挂点；`getEnergyMultiplier()` 仅在睡眠/静息两支作为 coldMulti 生效。
3. `setMetabolicTarget` 是**每帧只升不降的地板**（Thermoregulator.java:527 拒绝更低值），而原生每帧已根据真实姿态（武器档/跑/走/锻炼，lines 695–736）自行设置，帧末重置为 -1（line 759）。MOD 每秒再调一次，绝大多数情况下被原生值覆盖或只抬地板，且抬的是**产热地板**而非消耗。
4. 三池（碳水/脂质/蛋白）按**固定速率**每秒流失（Nutrition.java:63-65：0.0035/0.00113/0.00086），与强度无关，再次证实引擎无底物切换。

**修正建议**：

- §9.1 明确"燃料底物分配是 **MOD 内部台账**，用于 UI、成长、疾病与长周期仿真验证；**不声称能重定向原生宏量消耗**——引擎按真实姿态独立结算，无外部入口"。
- 删除"setMetabolicTarget 选档调制消耗"的表述。`setMetabolicTarget` 的正当用途仅为环境子系统中**冷/热应激时调制产热**（例如湿身低温下模拟寒战产热），并须接受其地板语义；`setSimulationMultiplier` 同为体温仿真缩放，不影响热量。
- 若未来要影响热量消耗，唯一可研究入口是 TimedAction 链上的 `BaseCharacterAction.caloriesModifier`（Nutrition.updateCalories:77-78 读取），列为 Spike 待实测，本期不做。

### 🟢 问题 3：§14 网络包名称错误

文档：服务端 AddXP 需走 `AddXpPacket`。实际不存在该类；XP 同步包为 [PlayerXpPacket.java](file:///d:/project/Zedema/zombie/network/packets/PlayerXpPacket.java)（`getXp().save/load`，PacketSetting reliability=2）。改名为 PlayerXpPacket 即可。

### 🟢 问题 4：BodyPart stiffness 行号偏差

§4.2 标注"stiffness 0–100（BodyPart.java:1921-1938）"：getStiffness 在 1921 正确；**setStiffness 在 1925**，1938 是累加用的 addStiffness 方法。改为 1921–1925。

---

## 四、总体评价

v3 技术文档在继承 v2 勘误的基础上，对 B42 新引入的体温/锻炼/流体体系做了全面核实，41 项 API 引用准确，未发现会导致运行时失败的严重错误。两处中等问题属于上一轮"纠正 Multiplier 假设"时的过度修正：把枚举误判为实验副本独有，并据此选择了语义不符的代谢挂点。**修正后，文档对"引擎能做什么、MOD 边界在哪"的表述将完全与源码一致**，且 MOD 的核心玩法闭环（台账驱动成长/疾病/事件）不受影响。

建议按问题 1–4 修订 §4.2/§4.3、§9.1、§14 及 §18 相关表述。
