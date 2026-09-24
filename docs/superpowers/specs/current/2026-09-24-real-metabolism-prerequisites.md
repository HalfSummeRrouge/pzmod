# Real Metabolism — 前置准备确认清单

- 日期：2026-09-24
- 目的：将设计文档（v3）和技术文档中标注"待确认/Spike 0"的项，凡可通过反编译源码 / 游戏脚本 / 官方 JavaDoc 确认的，全部查清楚，减少实机测试成本。
- 数据源：本地反编译 B42.20.4 源码（`Zedema\.api-cache\sources\42.20\out\source\`）+ 游戏脚本（`media\scripts\generated\`）。
- 状态：本文档覆盖 S2/S3/S4/S5/S6/S8/S9 的源码可确认部分；行为体感类仍需上机实测。

---

## 一、查证结论总览

| Spike 项 | 源码可确认部分 | 仍需上机 |
|---|---|---|
| S2 原生池时机/睡眠 | ✅ 已确认（见 §2.1） | 体温阈值体感标定 |
| S3 代谢调制路径 | ✅ 已关闭（见 §2.2） | — |
| S4 Fitness/锻炼 | ✅ 结构已确认（见 §2.3） | 负 AddXP 行为 |
| S5 瞬时动作 | ✅ 类名+hook 方法已确认（见 §2.4） | z-level/thump 具体行为 |
| S6 疾病表现 API | ✅ 输入锁定/伤口/夜盲方案已确认（见 §2.5） | — |
| S7 饮品 | ✅ 已完成（见测试结果文档 §七） | — |
| S8 环境数据 | ✅ API 已确认（见 §2.6） | 数值标定（出汗量、失温速率等） |
| S9 持久化/MP | ✅ 结构已确认 | 联机行为 |

---

## 二、逐项查证结果

### 2.1 S2 — 原生 Nutrition 池时机与 EveryDays 睡眠触发

**源码**：`zombie/characters/BodyDamage/Nutrition.java:58-115`

`Nutrition.update()` 关键逻辑：

```java
if (!GameClient.client) {                          // 单机客户端不执行此块
    setCarbohydrates(getCarbohydrates() - 0.0035f * dt);
    setLipids(getLipids() - 0.00113f * dt);
    setProteins(getProteins() - 8.6E-4f * dt);
}
updateCalories();   // 无论客户端/服务端都执行
```

**结论**：
- 单机模式 `GameClient.client = true`，碳水/脂肪/蛋白三池的**固定流失不在客户端执行**；热量消耗 `updateCalories()` 仍每帧执行。
- 热量消耗按姿态分支（`updateCalories:92-106`）：
  - Running + moving：`0.13 × 1.0 × (weight/80) × dt`
  - Sprinting + moving：`0.13 × 1.3 × (weight/80) × dt`
  - Moving（步行）：`0.13 × 0.6 × (weight/80) × dt`
  - Asleep：`0.003 × coldMulti × (weight/80) × dt`
  - Idle：`0.016 × coldMulti × (weight/80) × dt`
- `coldMulti = Thermoregulator.getEnergyMultiplier()` — 冷热应激对热量消耗的倍率。

**EveryDays 触发**：`zombie/GameTime.java:580-613`
- 两个触发分支：`serverNewDays > 0`（服务端跳天）和 `getTimeOfDay() >= 24.0`（自然过日）。
- 触发依赖**时间推进**，不依赖玩家是否睡眠。睡眠加速时间流逝 → 睡眠期间会触发 EveryDays。
- 设计文档中"EveryDays 睡眠期触发"已确认：睡眠时时间快进，EveryDays 仍会在跨日时触发。

**仍需上机**：核心体温阈值（多少度触发 HYPOTHERMIA/HYPERTHERMIA moodle）的体感标定；Thermoregulator 内部阈值为私有逻辑，MOD 侧建议直接读 `getCoreTemperature()` + moodle level 双重判定。

---

### 2.2 S3 — 代谢调制路径（已关闭）

**源码**：`zombie/characters/BodyDamage/Thermoregulator.java:1045` + `Nutrition.java:75-115`

已确认（技术文档 §4.3）：
- `Thermoregulator.Multiplier` 枚举为 private，值为固定常数，**无写入口**。
- `setMetabolicTarget(Metabolics/float)` 和静态 `setSimulationMultiplier(float)` **只调制产热**，不进热量账。
- 引擎不提供"按底物分别驱动碳水/脂肪池消耗"的外部接口。

**实现口径**（已定稿）：
- MOD 自行维护"底物燃料分配"台账（强度/时长/空腹查表），只用于 UI 与长周期仿真验证，不驱动原生消耗。
- `setMetabolicTarget` / `setSimulationMultiplier` 仅在环境子系统冷/热应激时用于产热调制。
- 唯一可研究的热量消耗入口：`BaseCharacterAction.caloriesModifier`（`Nutrition.updateCalories:77-78` 读取），本期不做。

---

### 2.3 S4 — Fitness / FitnessExercise

**源码**：`zombie/characters/BodyDamage/Fitness.java` + `BodyPart.java`

| API | 签名 | 说明 |
|---|---|---|
| `IsoPlayer:getFitness()` | 返回 `Fitness` | 定义于 IsoPlayer，非 BodyDamage |
| `Fitness:getRegularity(String type)` | float | 锻炼规律性 |
| `Fitness:setCurrentExercise(String)` | void | 设置当前锻炼 |
| `Fitness:reduceEndurance()` | void | 按规律性/负重扣耐力 |
| `BodyPart:getStiffness()` / `setStiffness(v)` | float / void | 僵硬 0–100 |
| `BodyPart:addStiffness(v)` | void | 僵硬累加 |

**FitnessExercise 追加写法**（`Fitness.init():396-410`）：
- 引擎读取全局 Lua 表 `FitnessExercises.exercisesType`。
- 每项字段：`type / metabolics / stiffness / xpMod`。
- MOD 可在 `Fitness.init()` 调用前向该全局表追加自定义锻炼类型。
- 追加时机需在 `Events.OnGameStart` 之前或 `Fitness.init` 之前。

**`canAddFitnessXp()`**：定义于 `Nutrition` 类，返回 boolean，成长发放前置检查。

**仍需上机**：`AddXP` 传负值的行为（是否被 clamp、是否影响降级）；负向降级本期只做"压制收益+疲劳惩罚"。

---

### 2.4 S5 — 瞬时动作 TimedAction

**源码**：游戏 Lua `media/lua/client/TimedActions/`

| 动作 | 类名 | hook 方法 | Metabolics 档位 | 备注 |
|---|---|---|---|---|
| 翻越栅栏 | `ISClimbOverFence` | start/update/stop/perform | `JumpFence` (4.0) | maxTime=0，瞬时 |
| 翻窗 | `ISClimbThroughWindow` | start/update/stop/perform | `JumpFence` (4.0) | maxTime=time（参数） |
| 爬绳 | `ISClimbSheetRopeAction` | start/update/stop/perform | 待确认 | — |
| 挖楼梯 | `ISDigStairsAction` | — | 待确认 | — |

**通用 hook 方法**：所有 `ISBaseTimedAction` 子类都有 `start()`、`update()`、`stop()`、`perform()`、`complete()` 方法，可包装 hook。

**移动状态判定**（`Nutrition.java:93-99`、`Thermoregulator.java:722`）：
- ✅ B42 用 **`isPlayerMoving()`**，不是 `isMoving()`。
- 配套姿态方法：`isSprinting()`、`IsRunning()`、`isSneaking()`、`isAsleep()`。

**负重比**（`Thermoregulator.java:741`）：
- 正确写法：`player:getInventory():getCapacityWeight() / player:getInventory():getMaxWeight()`
- 也可用 `player:getInventoryWeight()` / `player:getMaxWeight()`（`ILuaGameCharacter.java:121/269`，但需确认 `getInventoryWeight` 返回的是 capacity 还是 current）。
- 建议用 `getInventory():getCapacityWeight() / getInventory():getMaxWeight()` 更稳妥。

**仍需上机**：z-level 上下楼是否走 TimedAction；thump（砸窗/砸门）的具体 Action 类名。

---

### 2.5 S6 — 疾病表现 API

**输入锁定**（`IsoPlayer.java:6729`）：
- ✅ `player:setBlockMovement(boolean)` — 锁定移动。
- `BaseAction.setBlockMovementEtc(boolean)` — TimedAction 内使用。
- 急性事件硬控（热痉挛/中暑踉跄）可用 `setBlockMovement(true)`。

**伤口判定**（`BodyPart.java:1811`）：
- ✅ `bodyPart:isCut()` — 是否有割伤。
- `bodyPart:getStiffness()` / `setStiffness()` — 僵硬值。

**体温 moodle**（`Thermoregulator.java` + `BodyDamage.java`）：
- ✅ 原生通过 `player:getMoodles():getMoodleLevel(MoodleType.HYPOTHERMIA)` / `HYPERTHERMIA` 判定（0–4 级）。
- MOD 急性失温/中暑可参考 moodle level，也可直接读 `getCoreTemperature()` 自定义阈值。

**夜盲视野**：
- ❌ 不存在 `setNightVision` / `setSeeInDark` / `setNightStrength` 等直接 API，无法真正缩短视野半径。
- 相关 API：`isWearingNightVisionGoggles()`（夜视仪专用）、`getSquare():getLightLevel(playerNum)`（光照等级）、`getWornItemsVisionModifier()`（穿戴视野修正）。
- **确认方案：UI 暗角 overlay + 夜间惩罚**（非真正缩视野）：
  - 维 A 缺乏达到夜盲阶段时，在屏幕四周渲染半透明暗角（径向渐变遮罩），模拟夜间周边视力受损。
  - 叠加功能性惩罚：低光照环境下耐力恢复减慢、操作精度下降（`getLightLevel < 阈值` 时触发）。
  - 暗角强度随疾病等级递增（0–3 级），白天/充足光照下暗角不显示。
  - 暗角实现：`ISUIElement` 全屏透明层 + `drawRect` 径向渐变（或 NeatUI 渲染助手），置于 UI 最底层。

**HumanVisual**：
- `IsoPlayer:getHumanVisual()` 存在，但用于角色外观（服装/皮肤/毛发），**不适合做疾病视觉效果**。
- 疾病视觉效果应走 UI 层（暗角、色调 overlay），非 HumanVisual。

**仍需上机**：暗角渲染性能与渐变效果实机调优。

---

### 2.6 S8 — 环境数据源

**源码**：`zombie/iso/weather/ClimateManager.java` + `Thermoregulator.java`

| 数据 | API | 说明 |
|---|---|---|
| 相对湿度 | `ClimateManager.getInstance():getHumidity()` | 0–1，Thermoregulator 以 >0.5 为高湿 |
| 降雨强度 | `:getRainIntensity()` / `:getPrecipitationIntensity()` | — |
| 云量 | `:getCloudIntensity()` | 日照折减用 |
| 季节 | `:getSeason()` / `:getSeasonId()` / `:getWeatherPeriod()` | — |
| 环境气温 | `:getTemperature()` | 纯气温 |
| 体感温度 | `:getAirTemperatureForCharacter(player, false)` | 纯气温（第二参 false） |
| 风寒温度 | `:getAirTemperatureForCharacter(player, true)` | 气温+风寒（第二参 true） |
| 户外判定 | `square:isOutside()` | IsoGridSquare 方法 |
| 身体湿润度 | `bodyPart:getWetness()` | 0–100 |
| 服装湿润度 | `item:getWetness()` | 0–100 |
| 核心体温 | `thermoregulator:getCoreTemperature()` | ℃，基准 37 |

**CharacterStat.WETNESS**（`CharacterStat.java:33`）：
- 范围 0–100，默认 0。
- `player:getStats():get(CharacterStat.WETNESS)` 可读取整体湿身度，无需逐件读服装。

**仍需上机**：出汗量公式的系数标定、失温/中暑速率的体感调优（数值进 Config）。

---

### 2.7 S9 — ModData / 持久化

**源码**：技术文档 §6 已核实结构。
- 玩家 modData：`player:getModData()["RM"]`。
- 全局 ModData（MP 预留）：`ModData.getOrCreate(tag)` / `ModData.transmit(tag)`（Lua 侧 API）。
- schemaVersion 已有，迁移逻辑 `RM.Data.migrate()`。

**仍需上机**：联机同步行为（第一版不启用，预留）。

---

### 2.8 CharacterStat 枚举确认

**源码**：`zombie/characters/CharacterStat.java`

MOD 涉及的 CharacterStat：

| 枚举 | 范围 | 默认 | 用途 |
|---|---|---|---|
| `ENDURANCE` | 0–1 | 1.0 | 耐力 |
| `FATIGUE` | 0–1 | 0 | 疲劳 |
| `HUNGER` | 0–1 | 0 | 饥饿 |
| `THIRST` | 0–1 | 0 | 口渴 |
| `INTOXICATION` | 0–100 | 0 | 醉酒 |
| `PAIN` | 0–100 | 0 | 疼痛 |
| `POISON` | 0–100 | 0 | 中毒 |
| `SICKNESS` | 0–1 | 0 | 生病 |
| `FOOD_SICKNESS` | 0–100 | 0 | 食物中毒 |
| `WETNESS` | 0–100 | 0 | 湿身 |
| `TEMPERATURE` | 20–40 | 37 | 体温 |

**注意**：`CALORIES`/`CARBOHYDRATES`/`PROTEINS`/`LIPIDS` 不在 CharacterStat 中，这些在 `Nutrition` 类（`getCalories()`/`getCarbohydrates()` 等）。

---

### 2.9 烹饪产物年龄语义（设计 §4.3）

**源码**：`zombie/inventory/recipemanager/UsedItemProperties.java:64-107`

烹饪产物的 age **不重置为 0**，而是继承原料的腐烂状态：
- 原料 `getAge() > getOffAgeMax()` → 产物 `setAge(getOffAgeMax())`（直接腐烂）。
- 否则按原料 rottenness 计算产物 age：
  - `rottenness < 0.5`：`setAge(2.0 × rottenness × offAge)`
  - `rottenness >= 0.5`：`setAge(offAge + 2.0 × (rottenness - 0.5) × (offAgeMax - offAge))`

**设计影响**：降解系统中，烹饪产物的微量保留率应基于产物自身的 `getAge()`（已继承原料腐烂度），而非假设烹饪重置年龄。

---

## 三、技术文档勘误

| # | 技术文档原文 | 勘误 | 源码依据 |
|---|---|---|---|
| 1 | 附录 API 写 `isMoving()` | 应为 **`isPlayerMoving()`** | `Nutrition.java:93-99`、`Thermoregulator.java:722` |
| 2 | 负重比用 `inventoryWeight/maxWeight` | 建议用 `getInventory():getCapacityWeight() / getInventory():getMaxWeight()` | `Thermoregulator.java:741` |
| 3 | `getAirTemperatureForCharacter(p, false)` 未说明第二参 | `false`=纯气温，`true`=气温+风寒 | `Thermoregulator.java:579-583` |
| 4 | 夜盲光照"待实测" | 源码确认**无直接视野控制 API**，采用 UI 暗角 overlay + 夜间惩罚方案 | `IsoPlayer.java` 无 setSeeInDark/setNightVision |
| 5 | HumanVisual 用于疾病视觉 | HumanVisual 仅管角色外观，疾病视觉应走 UI overlay | `IsoPlayer.getHumanVisual()` 用途 |
| 6 | 烹饪产物年龄"Spike 0 验证" | 已确认继承原料腐烂度，非重置 | `UsedItemProperties.java:64-107` |

---

## 四、仍需上机实测的项（源码无法覆盖）

以下项涉及数值标定或行为体感，源码只能确认 API 存在性，具体数值/体感必须进游戏测：

1. **核心体温阈值**：中暑/失温的具体温度阈值（MOD 自定义 or 跟随原生 moodle）。
2. **出汗量系数**：强度×温度×湿度函数的系数标定。
3. **水合衰减速率**：各场景下降到 60/40 的时间。
4. **训练恢复系数**：睡眠质量、蛋白窗口的实际权重。
5. **负 AddXP 行为**：传负值是否被 clamp。
6. **疾病数值平衡**：7 种缺乏病的触发天数、恢复天数（M4 画像仿真）。

---

## 五、下一步建议

按优先级：

1. **S8 环境数据实机标定**：出汗量、失温速率 — M2 前置。
2. **M2 启动**：`RM_Environment` / `RM_Beverages` / `RM_Training` — API 已就绪。
3. **S4 负 AddXP 实测**：训练降级逻辑 — M2 训练模块。
