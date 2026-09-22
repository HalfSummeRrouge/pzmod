# 营养仿真 MOD 技术文档 — Zombie Atlas API 审查报告

- 审查日期：2026-09-22
- 审查工具：Zombie Atlas（基于本地 Project Zomboid B42 反编译源码）
- 反编译来源：`E:\Steam\steamapps\common\ProjectZomboid\projectzomboid.jar` → ZomboidDecompiler v0.3.2 (Vineflower)
- 源码规模：3,078 个 Java 文件 / 4,749 个类型 / 49,645 个方法
- 审查对象：`docs/superpowers/specs/2026-09-22-zomboid-nutrition-mod-technical.md`

---

## 一、审查结论摘要

技术文档对 B42 API 的核查整体质量较高，**25 项关键 API 声明中 20 项完全正确**，勘误部分（K1/K6 等）经核实准确。但发现 **1 项严重错误**（会导致核心进食钩子方案无法运行）和数项中/轻微偏差。

| 严重程度 | 数量 | 说明 |
|---|---|---|
| 🔴 严重 | 1 | `scripting.objects.Item` 无 `getOnEat/setOnEat`，§7.1 进食钩子方案需重写 |
| 🟡 中等 | 1 | `server/` 文件夹单机加载行为描述错误（不影响当前方案，但论证依据有误） |
| 🟢 轻微 | 3 | TimedAction 路径、AddXP 参数名、getNutrition 定义位置 |

---

## 二、验证通过的 API（20 项）

以下 API 经反编译源码核实，技术文档描述准确：

### 2.1 进食与食物
| 文档声明 | 源码核实 |
|---|---|
| `IsoGameCharacter:Eat(InventoryItem, float, boolean)` | ✅ [IsoGameCharacter.java:5712](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L5712) 签名一致 |
| `zombie.inventory.types.Food`（B42 从 `zombie.items` 迁移） | ✅ 位于 `zombie/inventory/types/Food.java` |
| `Food:getCalories/getCarbohydrates/getLipids/getProteins` | ✅ [Food.java:2123-2147](file:///d:/project/Zedema/zombie/inventory/types/Food.java#L2123-L2147) |
| `Food:getActualWeight()` | ✅ [Food.java:869](file:///d:/project/Zedema/zombie/inventory/types/Food.java#L869) |
| `Food:getFoodType()` | ✅ [Food.java:1970](file:///d:/project/Zedema/zombie/inventory/types/Food.java#L1970) |
| `Food:getFullType()` | ✅ 继承自 [InventoryItem.java:1658](file:///d:/project/Zedema/zombie/inventory/InventoryItem.java#L1658) |
| `ScriptManager.instance():getAllItems()` → `ArrayList<Item>` | ✅ [ScriptManager.java:568](file:///d:/project/Zedema/zombie/scripting/ScriptManager.java#L568) |

### 2.2 玩家与营养
| 文档声明 | 源码核实 |
|---|---|
| `player:getNutrition()` → Nutrition 类 | ✅ [IsoPlayer.java:6746](file:///d:/project/Zedema/zombie/characters/IsoPlayer.java#L6746) |
| `Nutrition` 全部方法（get/setCalories, Carbs, Proteins, Lipids, Weight, Inc/DecWeight, canAddFitnessXp, update） | ✅ [Nutrition.java](file:///d:/project/Zedema/zombie/characters/BodyDamage/Nutrition.java) 全部存在 |
| `player:getStats()` → Stats 枚举容器 | ✅ [Stats.java](file:///d:/project/Zedema/zombie/characters/Stats.java) |
| `Stats:get/set/add/remove/isAtMinimum/isAtMaximum(stat)` | ✅ [Stats.java:74-103](file:///d:/project/Zedema/zombie/characters/Stats.java#L74-L103) |
| `CharacterStat` 值域（ENDURANCE 0-1, FATIGUE 0-1, PAIN 0-100, TEMPERATURE 20-40） | ✅ [CharacterStat.java:15-30](file:///d:/project/Zedema/zombie/characters/CharacterStat.java#L15-L30) 完全一致 |
| `XP:AddXP(PerkFactory.Perk, float, ...)` 多重重载 | ✅ [IsoGameCharacter.java:17342+](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L17342) |
| `PerkFactory.Perks.Fitness / Strength` | ✅ [PerkFactory.java:332-336](file:///d:/project/Zedema/zombie/characters/skills/PerkFactory.java#L332-L336) |
| `player:getModData()` → KahluaTable | ✅ 继承自 [IsoObject.java:997](file:///d:/project/Zedema/zombie/iso/IsoObject.java#L997) |
| `player:getInventoryWeight()` | ✅ [IsoGameCharacter.java:11257](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L11257) |
| `player:getPrimaryHandItem()` | ✅ [IsoGameCharacter.java:3347](file:///d:/project/Zedema/zombie/characters/IsoGameCharacter.java#L3347) |
| 姿态方法 `isSprinting/isRunning/isSneaking/isMoving` | ✅ 全部存在于 IsoGameCharacter |
| `player:setBlockMovement(boolean)` | ✅ [IsoPlayer.java:6729](file:///d:/project/Zedema/zombie/characters/IsoPlayer.java#L6729) |
| `BodyPart:ReduceHealth(float)` | ✅ [BodyPart.java:517](file:///d:/project/Zedema/zombie/characters/BodyDamage/BodyPart.java#L517) |

### 2.3 环境与时间
| 文档声明 | 源码核实 |
|---|---|
| `getClimateManager()` → `ClimateManager.getInstance()` | ✅ Lua 全局函数已注册 |
| `ClimateManager:getTemperature()` | ✅ [ClimateManager.java:472](file:///d:/project/Zedema/zombie/iso/weather/ClimateManager.java#L472) |
| `getAirTemperatureForCharacter(player, boolean)` | ✅ [ClimateManager.java:693](file:///d:/project/Zedema/zombie/iso/weather/ClimateManager.java#L693) |
| `GameTime:getWorldAgeHours()` / `getNightsSurvived()` | ✅ [GameTime.java:893-914](file:///d:/project/Zedema/zombie/GameTime.java#L893-L914) |

### 2.4 事件与 ModData
| 文档声明 | 源码核实 |
|---|---|
| `Events.EveryDays / EveryHours / OnGameStart / OnCreatePlayer / OnKeyKeepPressed / OnPlayerUpdate / OnWeaponSwing` | ✅ 全部存在并被广泛使用 |
| `OnWeaponSwing(attacker, weapon)` 触发参数 | ✅ [SwipeStatePlayer.java:200](file:///d:/project/Zedema/zombie/ai/states/SwipeStatePlayer.java#L200) |
| `ModData.get/getOrCreate/create/add/remove/transmit/request` | ✅ [ModData.java](file:///d:/project/Zedema/zombie/world/moddata/ModData.java) 全部存在 |
| `PZAPI.ModOptions` 命名空间 | ✅ 位于 `media/lua/client/PZAPI/ModOptions.lua` |

### 2.5 勘误项核实
| 勘误 | 核实结果 |
|---|---|
| K1: B42 不存在 `OnEatFood` 事件 | ✅ 源码中无 `OnEatFood` 触发，进食走 `Food.onEat` 脚本字段 |
| K6: `isCrouching()` 不存在，用 `isSneaking()` | ✅ 无 `isCrouching`，`isSneaking` 存在 |

---

## 三、发现的问题

### 🔴 严重：`scripting.objects.Item` 无 `getOnEat()` / `setOnEat()` 方法

**文档位置**：§4.3（已核实的核心 Java/Lua API 表）、§7.1（进食摄入方案）

**文档声称**：
> `item:getOnEat()` / `item:setOnEat(string)` —— 脚本 `Item` 与实例 `Food` 均有此方法

**实际情况**：
- [Item.java:327](file:///d:/project/Zedema/zombie/scripting/objects/Item.java#L327)：`onEat` 是 **private 字段**，无公开 getter/setter
- 只有 [Food.java:2310+](file:///d:/project/Zedema/zombie/inventory/types/Food.java#L2310) 实例有 `getOnEat()` / `setOnEat(String)` 方法
- `Item.java` 中 `food.setOnEat(this.onEat)` 是内部把脚本字段同步到 Food 实例，并非公开 API

**影响**：
§7.1 的 `Nutri.EatHook.install()` 方案中：
```lua
scriptItem:getOnEat()       -- ❌ 不存在，会报错
scriptItem:setOnEat("...")  -- ❌ 不存在，会报错
```
这是 MOD 最核心的进食挂钩入口，**直接运行会失败**。

**修正建议**：
方案有两种，推荐方案 B（不依赖脚本对象方法）：

- **方案 A（脚本对象字段直写）**：`scriptItem.onEat` 字段虽为 private，但在 Lua 中可通过 `item:onEat` 直接读写 Kahlua 暴露的字段（B42.15+ Release 模式禁止直接访问 Java 实例字段，需确认脚本对象是否例外）。若可行：`scriptItem.onEat = "Nutri_OnFoodEaten"`。

- **方案 B（实例级挂钩，推荐）**：不修改脚本，改为在 `OnCreatePlayer` 时遍历玩家背包及世界已有 `Food` 实例，调用 `food:setOnEat("Nutri_OnFoodEaten")`；并监听容器变化对新生成的 Food 实例挂钩。R1 待实测项应优先验证此路径。

### 🟡 中等：`server/` 文件夹单机加载行为描述错误

**文档位置**：§3.1、§3.2、§4.1-K2

**文档声称**：
> `server` 文件夹在单机模式**不加载**（仅多人服务器加载）

**实际情况**：
- [Core.java:4764](file:///d:/project/Zedema/zombie/core/Core.java#L4764) 在启动时加载 `media/lua/server/Items/`
- [Core.java:4785](file:///d:/project/Zedema/zombie/core/Core.java#L4785) 加载 `media/lua/server/Vehicles/`
- 游戏 `media/lua/server/` 下的 `ISDynamicRadio.lua`、`STrapSystem.lua` 等在单机正常运行
- AGENTS.md 中的加载表（server/ 单机✅、MP client✅、MP server✅）与实际一致

**影响**：
不影响当前实现方案（已全部放 `shared/`），但 §3.1 "该方案在单机下不成立"的论证前提错误。若后续有人误信此表，可能错误地把服务端逻辑放 `client/`。

**修正建议**：
更正 §3.2 加载表为：

| 文件夹 | 单人模式 | 多人客户端 | 多人服务器 |
|---|---|---|---|
| `client` | ✅ | ✅ | ❌ |
| `server` | ✅ | ✅ | ✅（读档时加载） |
| `shared` | ✅ | ✅ | ✅ |

### 🟢 轻微 1：`ISSmashWindow` 实际位于 `shared/TimedActions`

**文档位置**：§7.2.3 暗示在 `media/lua/client/TimedActions/`

**实际**：`ISSmashWindow.lua` 位于 `media/lua/shared/TimedActions/`（其余 ISClimb* 在 `client/TimedActions/`）

**修正**：hook 时按实际路径引用即可，不影响功能。

### 🟢 轻微 2：`XP.AddXP` 6 参重载参数语义

**文档描述**：`AddXP(type, amount, p3, useMultiplier, p5, haloText)`

**实际签名**：`AddXP(PerkFactory.Perk type, float amount, boolean callLua, boolean doXPBoost, boolean remote, boolean haloText)`

**修正**：第 3 参是 `callLua`、第 4 参是 `doXPBoost`（非 `useMultiplier`）、第 5 参是 `remote`。技术文档 §7.5 调用 `AddXP(perk, delta, true--[[noMult]], false--[[halo]])` 用的是 4 参重载 `(type, amount, noMultiplier, haloText)`，该重载存在且签名正确，无需修改。仅 6 参描述需更正。

### 🟢 轻微 3：`getNutrition()` 定义位置

**文档**：归在 `IsoGameCharacter` 下
**实际**：定义在 [IsoPlayer.java:6746](file:///d:/project/Zedema/zombie/characters/IsoPlayer.java#L6746)（IsoGameCharacter 子类）

**修正**：因 `player` 即 `IsoPlayer`，调用不受影响，仅文档归属需更正。

---

## 四、待实测项（R1-R13）评估

技术文档 §14 列出的 13 项待实测，经源码审查补充以下判断：

| 编号 | 项 | 源码审查补充 |
|---|---|---|
| R1 | 脚本食物类型判定 + `setOnEat` | ⚠️ **核心风险**：`scripting.objects.Item.setOnEat` 不存在，需改为实例级挂钩（见严重问题） |
| R2 | `PZAPI.ModOptions` 签名 | ✅ 命名空间存在，具体方法签名需进游戏确认 |
| R3 | `isSneaking()` 等价蹲姿 | ✅ 方法存在，行为等价性需实测 |
| R4 | `AddXP` 负增量 | ✅ 方法接受 float，负值可行性需实测反作弊 |
| R5 | TimedAction 类名 | ✅ 四个类全部存在，方法名需进游戏确认 |
| R6 | `setBlockMovement` 副作用 | ✅ 方法存在，副作用需实测 |
| R12 | `DrinkFluid` 是否走 OnEat | 需确认 `DrainableComboItem` 的 `onEat` 字段是否被调用 |

---

## 五、总体评价

技术文档的 API 基线核查工作扎实，勘误部分（特别是 K1 进食事件、K6 蹲姿方法、K4 Stats 枚举化）经核实全部正确，体现了对 B42 变化的准确把握。**唯一的严重问题是 §7.1 进食钩子方案依赖了不存在的 `scripting.objects.Item.getOnEat/setOnEat` 方法**，这是 MOD 的入口功能，必须在编码前修正。

建议编码优先级：
1. **先解决进食钩子**（R1 + 严重问题修正）—— 这是整个 MOD 的数据入口
2. 其余按文档 §15 里程碑推进
