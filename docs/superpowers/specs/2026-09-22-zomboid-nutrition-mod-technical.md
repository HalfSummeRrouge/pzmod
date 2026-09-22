# 僵尸毁灭工程 营养仿真 MOD 技术文档

- 日期：2026-09-22
- 目标版本：Project Zomboid **Build 42.20.x（stable）**
- 关联文档：[2026-09-22-zomboid-nutrition-mod-design.md](./2026-09-22-zomboid-nutrition-mod-design.md)（设计文档）
- 依据来源：PZwiki《Modding》指南（[中文](https://pzwiki.net/wiki/Modding/zh-hans) / [英文](https://pzwiki.net/wiki/Modding)）、B42.20.2 反编译源码（`Ketum-Git/PZ-Javacode`）、Umbrella 事件定义库（`PZ-Umbrella/Umbrella`）、B42 实装 MOD 参考（`FrozenHeart247/Extensive-Health-Rework-B42`）
- 状态：技术评审稿（含待实测项，见 §15）

> **阅读对象**：负责本 MOD 编码与调试的 Lua 开发者。
> **本文性质**：技术实现方案。所有数值、平衡参数以设计文档 §3/§4/§7 为准，本文只规定"用什么 API、放在哪个文件、以什么时序执行"。

---

## 1. 文档目的与范围

把设计文档落成可编码的工程方案，重点解决四件事：

1. **MOD 怎么被游戏加载**：B42 版本化目录、`media/lua` 三类文件夹加载时机。
2. **每个设计功能挂在哪个真实 B42 API 上**：含对设计文档中 API 假设的勘误（见 §4）。
3. **模块怎么切、数据存哪、结算按什么时序跑**。
4. **怎么调试、怎么验证、哪些点必须上机实测**。

不包含：具体食物营养数值录入（数据工作，另行建表）、美术资产、Workshop 发布流程（后续）。

---

## 2. 技术栈与运行环境

| 项 | 说明 |
|---|---|
| 游戏版本 | Build 42.20.x stable；目录用版本化文件夹 `42/` |
| 脚本语言 | Lua **5.1 语法**。PZ 内嵌运行时为 **Kahlua**（Java 实现的 Lua VM），**不是 LuaJIT**；禁止依赖 LuaJIT 专有特性（`bit`、`jit` 库、goto 等）。设计文档 §6.1 的"luajit 同款"表述以此为准修正：本地纯函数测试用 Lua 5.1 或 LuaJIT 均可，仅保证 5.1 语法兼容 |
| Java 互操作 | 游戏本体类（`zombie.*`）以 Java 对象形式暴露给 Lua；静态方法用 `.`，实例方法用 `:`；类用 `ClassName.new(...)` 构造 |
| UI 框架 | 原版 ISUI Lua 体系（`ISPanel` / `ISButton` / `ISTabPanel` / `ISToolTip`），无第三方依赖 |
| 网络模式 | **单机优先**。逻辑写成 shared，预留多人权威接口（§11），第一版不联机验证 |
| 重要版本限制 | **B42.15.0 起 Release 模式禁止直接访问 Java 实例字段**，需要走 getter/setter 或百科给出的反射辅助函数；本 MOD 全程只用方法访问，不读字段 |

### 2.1 开发环境约定

- MOD 开发目录：`%UserProfile%\Zomboid\mods\NutritionMod\`（Windows）/ `~/Zomboid/mods/NutritionMod/`（Linux/Mac）。
- Steam 启动项加 `-debug` 打开调试模式；日志在 `Zomboid/console.txt`；F11 为 Lua 调试器（百科《Debug mode》）。
- 编辑器建议 VS Code + Lua 5.1 诊断 + EmmyLua 注解（参考 Umbrella 类型库可获得 B42 API 提示）。

---

## 3. MOD 包结构与加载机制（依据百科）

### 3.1 最终目录（对设计文档 §5.1 的修正版）

设计文档把 `Diseases/Exercise/Growth` 放在 `lua/server/`。**该方案在单机下不成立**：百科加载表明确指出，`server` 文件夹在单机模式**不加载**（仅多人服务器加载），而本 MOD 单机优先。因此**全部结算逻辑放 `shared`**，UI 放 `client`，`server` 目录第一版不使用（仅在需要联机权威时启用）。

```
NutritionMod/
└── 42/                                  -- B42 版本化文件夹
    ├── mod.info
    ├── poster.png                       -- 后续 Workshop 用
    └── media/
        └── lua/
            ├── shared/                  -- 单机/多人客户端/服务器都会加载
            │   └── Nutri/
            │       ├── Nutri_Config.lua       -- 全部可调参数（设计 §7 清单）
            │       ├── Nutri_DataLayer.lua    -- 食物营养表 + 分类兜底 + ModData 封装
            │       ├── Nutri_History.lua      -- 7 天滚动历史、每日净额
            │       ├── Nutri_Core.lua         -- 摄入/消耗结算、评分纯函数、症状应用
            │       ├── Nutri_Exercise.lua     -- 按秒消耗 + 瞬时动作挂接
            │       ├── Nutri_Diseases.lua     -- 7 疾病状态机
            │       ├── Nutri_Growth.lua       -- 短期耐力修正 + 长期成长 + 体重联动
            │       └── Nutri_EatHook.lua      -- 进食事件挂接（OnEat 脚本回调）
            └── client/                  -- 单机与多人客户端加载
                └── Nutri/
                    ├── Nutri_Keybind.lua      -- 快捷键注册/监听
                    ├── Nutri_UITheme.lua      -- 主题令牌（设计 §4.8）
                    ├── Nutri_UI_Main.lua      -- 面板容器 + 标签页
                    ├── Nutri_UI_Status.lua    -- 状态页
                    ├── Nutri_UI_Trend.lua     -- 趋势页（sparkline）
                    └── Nutri_UI_Health.lua    -- 健康页
```

补充约定：

- 所有 MOD 文件放在 `media/lua/.../Nutri/` 二级目录下，避免与原版或其他 MOD **同相对路径覆盖**（百科：同相对路径的 MOD 文件会覆盖原版文件）。
- `media/scripts/` 不使用：营养数据唯一来源是 `Nutri_DataLayer.lua`（与设计 §4.1 一致），不新增物品。
- 翻译走百科 Translation 约定：后续新增 `media/lua/shared/Translate/CN/UI_Nutri.txt`（第一版可先用中文字面量，但 UI 字符串集中到 `Nutri_Config.lua` 的 `L10N` 段以便迁移）。

### 3.2 `lua` 三类文件夹加载时机（百科原表）

| 文件夹 | 单人模式 | 多人客户端 | 多人服务器 |
|---|---|---|---|
| `client` | ✅ | ✅ | ❌ |
| `server` | ❌ | ❌ | ✅（仅读档时加载） |
| `shared` | ✅ | ✅ | ✅ |

加载顺序（客户端）：原版 shared → MOD shared → 原版 client → MOD client。
由此得出两个硬约束：

1. 所有结算/状态代码放 `shared`，否则单机跑不起来。
2. client 代码可以引用 shared 中定义的全局表（`Nutri`），反向禁止。

### 3.3 `mod.info`

与 `poster.png` 一起放在版本文件夹根目录。百科 `Mod_info` 页面目前为空，以下为社区通用字段（B41/B42 兼容）：

```ini
name=营养仿真（Nutrition Overhaul）
id=NutritionMod
description=多维度营养素仿真：宏量/微量营养素、运动消耗、体能成长与营养疾病。
author=用户 × Trae
version=0.1.0
url=
pack=
```

注意：`id` 为 MOD 唯一标识，代码中不依赖它做逻辑判断；MOD 内全局变量统一挂在 `Nutri` 表下，不散落全局。

---

## 4. B42 API 基线核查（含对设计文档的勘误）

> 本节所有结论均已对照 B42.20.2 反编译源码或 B42 实装 MOD，避免按 B41 旧印象编码。

### 4.1 勘误清单

| # | 设计文档假设 | B42.20 实际 | 本 MOD 对策 |
|---|---|---|---|
| K1 | §4.2 挂接 `Events.OnEatFood` | **B42 不存在 `OnEatFood` 事件**（Umbrella 事件库无此事件；`IsoGameCharacter.Eat()` 也不触发任何进食 Event） | 改用**食物脚本 `OnEat` 回调**批量挂接，见 §7.1。`Events.OnEat` 亦非原版事件（第三方 MOD 的防御性写法），不使用 |
| K2 | §5.1 结算逻辑放 `server/` | `server/` 单机不加载（§3.2） | 全部放 `shared/` |
| K3 | §6.1 用 luajit 做测试运行时 | PZ 内嵌 Kahlua（Lua 5.1 语法） | 只用 Lua 5.1 通用语法；本地解释器任选 |
| K4 | §4.6.3 直接 `stats:setEndurance()` | B42 `Stats` 改为枚举容器：`stats:get/set(CharacterStat.X, v)`，旧 `setEndurance/setFatigue` 已无 | 统一走 `CharacterStat`，见 §7.4 |
| K5 | §4.4.4 `AddXP(Perks.Fitness, delta)` | API 仍在，签名 `XP:AddXP(PerkFactory.Perk, float)`；但最简重载**只对本地玩家生效**，且负增量需实测 | 用静默重载、做 delta 钳制与实测，见 §7.5 |
| K6 | §4.3.1 `isCrouching()` | B42 角色类无 `isCrouching()`；蹲伏输入在 `CharacterInputComponent.isCrouchButtonDown()`，角色姿态仍可用 `isSneaking()` | 潜行/蹲姿档用 `isSneaking()`，输入侧 API 列为待实测（§14-R3） |
| K7 | §4.4.1 "基于游戏时钟 / OnGameDay 类事件" | 无 `OnGameDay`；周期事件为 `EveryDays`（**每天游戏内 0:00 触发**）、`EveryHours`、`EveryTenMinutes`、`EveryOneMinute` | 每日结算直接挂 `EveryDays`，与设计"凌晨 0 点"完全吻合 |

### 4.2 已核实的事件清单（Umbrella `library/events.lua`）

| 事件 | 回调签名 | 触发说明 | 本 MOD 用途 |
|---|---|---|---|
| `OnInitGlobalModData` | `fun(newGame:boolean)` | Sandbox 选项加载后最早事件 | 不使用（第一版只用玩家 modData）；多人版在此初始化全局表 |
| `OnCreatePlayer` | `fun(playerIndex:integer, player:IsoPlayer)`（客户端） | 本地玩家载入世界 | 初始化玩家 modData、批量挂接 OnEat 食物钩子（幂等） |
| `OnNewGame` | `fun(player:IsoPlayer, square:IsoGridSquare)`（客户端） | 角色首次创建 | 与 OnCreatePlayer 共用初始化函数 |
| `OnGameStart` / `OnLoad` | `fun()`（客户端） | 进入游戏完成 | 注册 UI、恢复疾病症状 hook |
| `OnTick` | `fun(tick:number)` | 每游戏帧 | **不挂重逻辑**（性能） |
| `OnTickEvenPaused` | `fun(tick:number)` | 含暂停时每帧 | 仅 UI 暂停态处理用 |
| `OnPlayerUpdate` | `fun(player:IsoPlayer)`（客户端） | 本地玩家每 tick 更新 | **每秒消耗结算的驱动**（内部累加器节流，§7.2） |
| `OnWeaponSwing` | `fun(attacker:IsoPlayer, weapon:HandWeapon)` | 开始挥击 | 战斗消耗（武器重量分档） |
| `OnWeaponSwingHitPoint` | `fun(attacker, weapon)` | 挥击命中点 | 不使用（命中与否不影响体力消耗口径） |
| `EveryDays` | `fun()` | 每游戏日 0:00 | 每日净额/历史/疾病/成长结算（§7.3） |
| `EveryHours` | `fun()` | 每游戏整点 | 短期耐力"近 2 天"窗口刷新、症状插值 |
| `EveryTenMinutes` / `EveryOneMinute` | `fun()` | 周期 | 调试造境命令、低频缓存刷新 |
| `OnKeyKeepPressed` | `fun(key:integer)`（客户端） | 按住键每帧触发 | 快捷键 fallback 方案（§7.8.4） |
| `OnPlayerDeath` / `OnCharacterDeath` | 后者：`fun(character:IsoGameCharacter)` | 死亡 | 清除瞬时修正标记，避免死后残留 |

挂接/移除写法（百科）：`Events.OnCreatePlayer.Add(Nutri.OnPlayerCreated)` / `Events....Remove(fn)`。**回调只传具名函数引用，便于 Remove**，不挂匿名函数。

### 4.3 已核实的核心 Java/Lua API

**进食与食物（`zombie.inventory.types.Food`，B42 包路径已从 B41 的 `zombie.items` 迁移）**

| API | 签名 | 备注 |
|---|---|---|
| `IsoGameCharacter:Eat` | `boolean Eat(InventoryItem info, float percentage, boolean useUtensil)` | 原版内部按 `food.getCalories() * percentage` 增加玩家 Nutrition；`percentage` 为本次吃掉的比例（0–1，1=整份） |
| 脚本 OnEat 回调 | `function(info: InventoryItem, player: IsoGameCharacter, percentage: number)` | Eat 流程内 `LuaManager` 以 `pcallvoid` 调用；钩子名来自食物脚本 `OnEat` 字符串字段 |
| 脚本枚举 | `ScriptManager.instance():getAllItems(): ArrayList<Item>` | B42 已核实；返回脚本对象（`zombie.scripting.objects.Item`，含 `onEat` 字段） |
| 脚本钩子 | `item:getOnEat()` / `item:setOnEat(string)` | 脚本 `Item` 与实例 `Food` 均有此方法；对脚本对象设置即全局生效 |
| 实例营养 | `food:getCalories() / getCarbohydrates() / getLipids() / getProteins() : float` | 均为**整份物品**基准（非每 100g） |
| 实例重量 | `food:getActualWeight(): float` | 已随使用比例（usedDelta）折算的当前重量；`getWeight()` 在有 ReplaceOnUse 时等同 actual |
| 其他 | `getFoodType():string`、`getHungerChange()`、`getThirstChange()`、`getFullType():string`（如 `"Base.CannedBolognese"`） | 类型识别/兜底用 |

**玩家与营养（`zombie.characters.IsoGameCharacter` / `IsoPlayer`）**

| API | 签名/语义 |
|---|---|
| `player:getNutrition()` | `zombie.characters.BodyDamage.Nutrition`，方法：`getCalories/setCalories(float)`、`getCarbohydrates/setCarbohydrates(float)`、`getProteins/setProteins(float)`、`getLipids/setLipids(float)`、`getWeight():double / setWeight(double)`、`isIncWeight()/setIncWeight(bool)`、`isDecWeight()/setDecWeight(bool)`、`canAddFitnessXp():boolean`、`update()` |
| `player:getXp()` | 内部类 `IsoGameCharacter.XP`，见 §7.5 |
| `player:getStats()` | B42 `zombie.characters.Stats`（枚举容器），见下 |
| `player:getBodyDamage()` | `BodyDamage`；身体部位 `BodyPart:ReduceHealth(float)`（B42 血量 0–100，内部已 clamp） |
| `player:getModData()` | KahluaTable，随玩家存档持久化（本 MOD 主存储） |
| `player:getInventoryWeight()` | `float`，当前负重（重量单位与物品 weight 一致，约 kg 语义） |
| `player:getPrimaryHandItem()` | `InventoryItem`（武器）；`item:getWeight()` |
| 姿态判定 | `isRunning():boolean`、`isSprinting():boolean`、`isSneaking():boolean`、`isMoving():boolean` |
| 动作 | `player:setBlockMovement(bool)`（用于"抽搐锁行动"，需实测联机/超时恢复，§14-R6）、TimedAction 中 `character:climbOverFence(dir)` 等 |

**B42 `Stats` + `CharacterStat`（`zombie.characters.Stats` / `CharacterStat`）**

读写统一为 `stats:get(stat) / set(stat, v) / add(stat, v) / remove(stat, v) / isAtMinimum/Maximum(stat)`。本 MOD 用到的枚举（含值域/默认值，源码常量）：

| CharacterStat | 值域 | 默认 | 用途 |
|---|---|---|---|
| `ENDURANCE` | 0–1 | 1 | 耐力上限/恢复修正、贫血、碳水冻结 |
| `FATIGUE` | 0–1 | 0 | 脚气病疲劳 |
| `HUNGER` / `THIRST` | 0–1 | 0 | 调试与观察，不直接改 |
| `PAIN` | 0–100 | 0 | 症状表现（必要时） |
| `TEMPERATURE` | 20–40 | 37 | 体温（只读观察为主） |

**经验（`IsoGameCharacter.XP`，源码核实）**

```java
public void AddXP(PerkFactory.Perk type, float amount)
// 内部转调 AddXP(type, amount, true, true, false)，且仅对 isLocalPlayer() 生效
public void AddXP(PerkFactory.Perk type, float amount, boolean noMultiplier, boolean haloText)
// 6 参重载：(type, amount, p3, useMultiplier, p5, haloText)
```

- Perk 访问：`PerkFactory.Perks.Fitness`、`PerkFactory.Perks.Strength`。
- 另有 `setXPToLevel(perk, level)`，必要时做硬钳制。
- 设计要求的"负增长"：传负 `amount` 是否被原版接受/是否触发反作弊（B42 有 `AntiCheatXP*`），列为待实测（§14-R4）；备选方案是降低当前 XP 总量（`getXP():addXP` 之外的只读字段配合 set 系列），实测后定型。

**全局 ModData（`zombie.world.moddata.ModData`，全局表 `ModData`）**

| 方法 | 用途 |
|---|---|
| `ModData.get(tag)` / `getOrCreate(tag)` | 取/建全局共享表（多人同步） |
| `ModData.create()` / `create(tag)` / `add(tag, table)` / `remove(tag)` | 表管理 |
| `ModData.transmit(tag)` / `request(tag)` | 服务器下发 / 客户端请求（多人） |
| `player:getModData()` | **玩家私有表，随存档保存；第一版唯一存储**，无需 transmit |

**环境（`zombie.iso.weather.ClimateManager`）**

- 获取：`getClimateManager()`（全局）或 `ClimateManager.getInstance()`。
- 气温：`:getTemperature()`（环境气温）；`:getAirTemperatureForCharacter(player, false): float`（角色体感温度，已含风寒/室内修正，Clock 与体温系统均用此方法）。**温度修正系数优先用体感温度**。

**UI（原版 Lua，`media/lua/client/ISUI/`，已核实构造签名）**

| 类 | 构造/关键方法 |
|---|---|
| `ISPanel` | `ISPanel:new(x, y, width, height)`；重写 `initialise()`、`prerender()`、`render()`；绘制方法（继承自 ISUIElement）：`self:drawRect(x,y,w,h,a,r,g,b)`、`drawRectBorder(...)`、`drawText(text,x,y,r,g,b,a,font)`、`drawTextureScaled(...)`；`panel:initialise()` + `panel:addToUIManager()` 挂载 |
| `ISButton` | `ISButton:new(x, y, w, h, title, clicktarget, onclick, onmousedown, allowMouseUpProcessing)` |
| `ISTabPanel` | `:new(x,y,w,h,...)`；`:addTab(name, view)`（view 为 ISPanel 派生实例）；属性 `tabHeight`、`tabTransparency` |
| `ISToolTip` | `:new()`、`:setName(s)`、`:setDescription(s)`、`:addToUIManager()` |

**快捷键（B42）**

- B42 引入 Mod 选项/按键体系，第三方 B42 MOD 的可用写法：`PZAPI.ModOptions:create(modId, modName)` 后 `options:addKeyBind(id, displayName, defaultKeyCode, tooltip)`，按键出现在"选项 → Mods"；运行时取键码，配合 `Events.OnKeyKeepPressed`。
- 该命名空间属 B42 新体系，实机存在性与确切方法名列为待实测（§14-R2）；**fallback**：`OnKeyKeepPressed(key)` 中直接比较默认键码常量（`Keyboard.KEY_N = 49`）。两套方案都封装在 `Nutri_Keybind.lua` 一个文件内，上层只调 `Nutri.Keybind:isTogglePressed(key)`。

---

## 5. 总体架构

### 5.1 全局命名空间

所有模块共享一个全局表：

```lua
Nutri = Nutri or {
    Config    = nil,  -- Nutri_Config.lua
    Data      = nil,  -- Nutri_DataLayer.lua
    History   = nil,  -- Nutri_History.lua
    Core      = nil,  -- Nutri_Core.lua
    Exercise  = nil,  -- Nutri_Exercise.lua
    Diseases  = nil,  -- Nutri_Diseases.lua
    Growth    = nil,  -- Nutri_Growth.lua
    UI        = nil,  -- client UI 聚合
    State     = nil,  -- 运行时瞬时状态（非持久化）
}
```

模块间只通过 `Nutri.*` 公开函数通信；文件内 local 函数不导出。禁止修改原版类方法以外的全局；对原版方法的包装（TimedAction/OnEat）集中在对应 hook 文件并保留原函数链。

### 5.2 模块职责与依赖方向

```
Nutri_Config ─────────────────────────────┐（无依赖，纯数据）
                                          │
Nutri_DataLayer ──┐                       │
                  ├─> Nutri_Core <────────┼─ 结算纯函数 + 症状应用
Nutri_EatHook ────┘        ▲              │
                           │              │
Nutri_Exercise ────────────┤              │
Nutri_History ─────────────┤              │
Nutri_Diseases ────────────┤              │
Nutri_Growth ──────────────┘              │
        ▲                                 │
        └── Events 驱动（OnCreatePlayer / OnPlayerUpdate /
                       OnWeaponSwing / EveryHours / EveryDays）
                                          │
client: Nutri_UI_* ──只读──> Nutri.Core/Data/History/Diseases 的查询函数
client: Nutri_Keybind ──开关──> UI
```

依赖只能向下（图中从左到右）。UI 不允许写任何结算数据。

### 5.3 文件加载与初始化顺序

利用"MOD shared 按路径字母序、文件内顺序执行"不可靠的特性，**不依赖文件名顺序**，改用两阶段引导：

1. **定义阶段**（各 shared 文件加载时）：只定义表与函数，最后一行不挂事件。
2. **启动阶段**（`Nutri_Core.lua` 末尾或独立 bootstrap 段挂 `Events.OnCreatePlayer`）：
   `OnCreatePlayer(playerIndex, player)` 时幂等执行：
   - `Nutri.Data.ensurePlayer(player)`：建/迁移 modData 结构（§6.3）；
   - `Nutri.EatHook.install()`：批量给脚本食物装 OnEat 钩子（全局只装一次）；
   - `Nutri.Exercise.attach(player)` / `Nutri.Diseases.attach(player)`：恢复症状修饰器；
   - client 侧 `Nutri.UI.init()`（UI 文件在 client 加载，后于 shared）。

`Events.OnGameStart` 再做一次"UI 与修饰器挂载"（处理读档场景），全部幂等。

---

## 6. 数据设计

### 6.1 持久化原则

- **只写玩家 modData**：`local md = player:getModData()`；键全部加前缀 `Nutri.`，单一根对象 `md["Nutri"]` 下集中管理，避免污染其他 MOD。
- 写入时机：进食（即时）、每秒消耗（内存累计，**每 10 个游戏分钟落盘一次**）、每日结算（即时）、症状阶段变化（即时）。
- KahluaTable 只存 Lua 基础类型（number/string/boolean/table），**不存 Java 对象引用**。

### 6.2 玩家存档结构（schema v1）

```lua
md["Nutri"] = {
    schema = 1,                    -- 存档版本，迁移用（§12.3）
    -- 当日累计（单位：宏量 g；矿物质 mg；维生素按表单位）
    intakeToday = { protein=0, carbs=0, fat=0, minerals=0,
                    vitA=0, vitC=0, vitD=0, vitB1=0,
                    sodium=0, potassium=0, calcium=0, iron=0, -- 预留细分
                    calories=0 },
    -- 当日消耗累计
    burnToday   = { carbs=0, minerals=0, sodium=0, potassium=0,
                    calories=0, protein=0, instant=0 },
    -- 每日净额历史（滚动队列，最多 7 条）
    history = {
        -- { day=游戏日序号, net={protein=..,carbs=..,...}, score={protein=..,..},
        --   exercise=0..1, weightKg=70.0 }
    },
    lastSettleDay = -1,            -- 已结算到的游戏日，防 EveryDays 重复/跨档
    -- 疾病状态（键 = 疾病 id）
    disease = {
        -- scurvy = { level=0..3, deficitDays=n, recoverDays=n,
        --           applied={...已应用的症状修饰, 用于摘除} }
    },
    -- 近两天净额快照（短期耐力用，由 History 派生缓存，结算时刷新）
    recent2 = { carbs=0, protein=0, ... },
    -- 成长
    growth = { lastXpDay=-1, dailyDeltaFitness=0, dailyDeltaStrength=0 },
    -- UI/杂项
    prefs = { uiOpen=false },
}
```

设计取舍说明：

- 第一版"每类只维护一个总量"（设计 §3.1 备注）：参与评分/结算的是 8 个大类键；食物表录入钠/钾/钙/铁细分，摄入时把 4 项求和写入 `minerals`，同时原值写入 4 个预留键，后续拆分记账不改存档结构。
- `burnToday` 把"按秒消耗"和"瞬时动作消耗"分列（`instant`），便于测试用例 2（§12.2）核对。

### 6.3 `ensurePlayer` 与存档迁移

```lua
function Nutri.Data.ensurePlayer(player)
    local md = player:getModData()
    if type(md["Nutri"]) ~= "table" then md["Nutri"] = Nutri.Data.freshState() end
    Nutri.Data.migrate(md["Nutri"])          -- 按 schema 补缺失键/默认值
end
```

迁移规则：只做"加键 + 补默认值"，不做删键；`schema` 升级在 `migrate` 内 `while schema < N` 链式升级。

### 6.4 配置数据（`Nutri_Config.lua` 内容骨架）

全部是纯 Lua 表，覆盖设计文档 §7 参数清单：

```lua
Nutri.Config = {
    DRI = { protein=75, carbs=250, fat=60, minerals=6015,   -- 钠2000+钾3000+钙1000+铁15
            vitA=900, vitC=100, vitD=15, vitB1=1.2, calories=2200 },
    ActionBurnPerSec = { idle={carbs=..}, crouch=.., walk=.., run=.., sprint=.. },
    InstantBurn = { vaultFence={carbs=30,minerals=8}, rope={45,10},
                    window={20,6}, stairs={12,3}, jump={8,2}, smash={20,5} },
    WeaponBurn = { {maxWeight=1.5, carbs=5, minerals=1}, ... },
    EnvModifier = { load={20,1.15,35,1.3,50,1.5},
                    hot={30, "minerals",1.5}, cold={5, "carbs",1.4} },
    ShortTerm = { surplus={cap=1.05,regen=1.1}, deficit={cap=0.9,regen=0.85},
                  carbFreezeScore=-0.6 },
    Growth = { xpGainK=.., xpLossK=.., dailyAbs=.. },
    Weight = { gain=0.1, lose=0.15, lowKg=55, highKg=95, stepK=.. },
    Disease = { scurvy={nutrient="vitC", threshold=.., needN=3, recoverM=2,
                        levels={...症状数值...}}, -- 7 种
    Ui = { theme={...}, width=420, height=560, keyDefault=Keyboard and Keyboard.KEY_N or 49 },
    FallbackCategory = { -- getFoodType() -> 营养模板
        Vegetables={...}, Meat={...}, Canned={...}, Grains={...}, ... },
    L10N = { ... },
}
```

### 6.5 食物营养表（`Nutri_DataLayer.lua`）

- 表结构与设计 §4.1.1 完全一致（每 100g，细项字段齐全）。
- 键统一用**物品全名**（`Food:getFullType()`，如 `Base.CannedBolognese`）。
- 查询三段式：

```lua
function Nutri.Data.lookupPer100(food)            -- food: Food 实例
    local full = food:getFullType()
    local row = FoodNutrition[full]
    if row then return row, "exact" end
    local cat = food:getFoodType()                -- 例: "Vegetables"/"Meat"/"Canned"
    return Nutri.Config.FallbackCategory[cat] or FallbackCategory.Default, "fallback"
end
```

---

## 7. 功能技术方案（逐模块）

### 7.1 进食摄入（`Nutri_EatHook.lua` + `Nutri_Core.lua`）

**问题**：B42 无进食事件（§4.1-K1）。原版 `IsoGameCharacter:Eat(info, percentage, useUtensil)` 在应用营养后，若食物脚本字段 `OnEat` 非空，则以 `(info, player, percentage)` 调用对应具名 Lua 函数。

**方案：启动期给所有食物脚本注入同一个 OnEat 钩子，并保留原链。**

```lua
-- 全局具名函数（OnEat 字段按名字查找，必须是全局可寻址）
function Nutri_OnFoodEaten(info, player, percentage)
    -- 1) 先执行原脚本链（若该食物原本有 OnEat）
    local chain = Nutri.EatHook.prev[info:getFullType()]
    if chain then pcall(_G[chain], info, player, percentage) end
    -- 2) 营养记账
    if instanceof(info, "Food") and percentage and percentage > 0 then
        Nutri.Core.onEat(info, player, percentage)
    end
end

function Nutri.EatHook.install()
    if Nutri.EatHook.done then return end
    local items = ScriptManager.instance():getAllItems()
    for i = 0, items:size() - 1 do
        local scriptItem = items:get(i)
        -- 只处理食物脚本：B42 脚本对象类型判定（见下注）
        if Nutri.EatHook.isFoodScript(scriptItem) then
            local full = scriptItem:getModule() .. "." .. scriptItem:getName()
            Nutri.EatHook.prev[full] = scriptItem:getOnEat()
            scriptItem:setOnEat("Nutri_OnFoodEaten")
        end
    end
    Nutri.EatHook.done = true
end
```

注：

- `isFoodScript` 的实现二选一（编码时在游戏内确认，§14-R1）：脚本 `Item` 的类型枚举（`getType()` / `Type.Food`），或 `instanceof(ScriptManager.instance:findItem(...))` 试探；优先枚举法。
- **注入时机**：`OnCreatePlayer`（脚本已全部 merge）。`DrainableComboItem` 也有 `onEat` 字段（如喝品），一并纳入判定，覆盖 B42 流体容器。
- 设计 §4.1.2 的重量折算：

```lua
function Nutri.Core.onEat(food, player, percentage)
    local row = Nutri.Data.lookupPer100(food)          -- 每100g
    -- getActualWeight 是当前（吃之前）整份重量；本次吃入重量 ≈ 整份重 × percentage
    local grams100 = (food:getActualWeight() * 1000.0) * percentage / 100.0
    Nutri.Core.addIntake(player, row, grams100)        -- 各营养素 ×grams100 累加
end
```

- 健壮性：整段回调 pcall 包裹（原版用 pcallvoid 调用，抛错不影响进食，但会污染 console）。
- **风险**：B42 吃流体（`DrinkFluid`）走另一路径，若其不读 `onEat`，流体食物（汤等）在第一版走"识别为 Food 即记录"的统一兜底；实测后若漏记，改挂 `DrinkFluid` 的脚本钩子（API 上与 Eat 并列存在）。

### 7.2 运动消耗（`Nutri_Exercise.lua`）

#### 7.2.1 按秒结算（OnPlayerUpdate + 累加器）

`OnPlayerUpdate` 每 tick 触发（不同帧率次数不同），必须用游戏时间差做归一化，**不按帧数**：

```lua
local ACC_SEC = 1.0
function Nutri.Exercise.onPlayerUpdate(player)
    local st = Nutri.State.forPlayer(player)
    if not st then return end
    local now = getGameTime():getWorldAgeHours()          -- 游戏小时（含小数）
    local dt = now - (st.lastAge or now)
    st.lastAge = now
    st.acc = (st.acc or 0) + dt
    if st.acc < ACC_SEC then return end
    st.acc = 0.0
    Nutri.Exercise.settleSecond(player, ACC_SEC)
end
```

档位判定（每秒）：

| 设计档位 | 判定（短路优先级从上到下） |
|---|---|
| 冲刺 | `player:isSprinting()` |
| 跑步 | `player:isRunning()` |
| 蹲走/潜行 | `player:isSneaking()`（B42 蹲姿，待实测 R3） |
| 步行 | `player:isMoving()` 且上述皆否 |
| 休息/站立 | 其他（含静止） |

修正因子（乘在配置向量上，全部来自配置表）：

- 负重：`player:getInventoryWeight()` → 20/35/50 三档（设计 §4.3.4）。
- 温度：`getClimateManager():getAirTemperatureForCharacter(player, false)` → >30°C 矿物质 ×1.5；<5°C 碳水 ×1.4。
- 乘积只影响**消耗速率**，不影响动作判定。

结算结果写入 `burnToday`，并累计当日"运动量"（用于成长，见 §7.6）：运动量 = 各动作秒数加权和 / 当日活动时间，归一化到 0–1。

#### 7.2.2 战斗消耗（OnWeaponSwing）

```lua
function Nutri.Exercise.onWeaponSwing(attacker, weapon)
    if attacker ~= getPlayer() then return end           -- 单机本地玩家
    local w = weapon and weapon:getWeight() or 0
    local row = Nutri.Core.matchWeightTier(w, Nutri.Config.WeaponBurn)
    Nutri.Core.addInstantBurn(attacker, row.carbs, row.minerals)
end
```

空挥与命中同口径（设计按"每击"）；`OnWeaponSwing` 在起手时触发，与设计一致。

#### 7.2.3 瞬时动作（TimedAction 包装）

B42 翻越/攀爬仍是 Lua TimedAction（原版类已核实存在；B42 具体类名以本机游戏文件为准，§14-R5）：

| 设计动作 | 原版类（`media/lua/client/TimedActions/`） | 挂接点 |
|---|---|---|
| 翻越栅栏/矮墙 | `ISClimbOverFence` | 包装 `perform`（原版 perform 内调 `character:climbOverFence(dir)`） |
| 翻窗进出 | `ISClimbThroughWindow` | 包装 `perform` |
| 攀爬绳索 | `ISClimbSheetRopeAction` | 包装 `perform` |
| 重拳/撞门 | `ISSmashWindow` 等破门动作 | 包装 `perform` |
| 上下楼梯/跳跃 | 无独立 TimedAction（移动系统内置） | 用 OnPlayerUpdate 姿态+位移启发式，或在实测中找对应动作类（R5） |

包装模式（保留原链，禁止覆盖式改写）：

```lua
function Nutri.Exercise.hookTimedAction(className, costKey)
    local cls = _G[className]
    if not cls or cls.__nutriHooked then return end
    local origPerform = cls.perform
    cls.perform = function(self, ...)
        Nutri.Core.addInstantBurn(self.character,
            Nutri.Config.InstantBurn[costKey].carbs,
            Nutri.Config.InstantBurn[costKey].minerals)
        return origPerform(self, ...)
    end
    cls.__nutriHooked = true
end
```

事实补充：`ISClimbOverFence:update()` 原版会调 `character:setMetabolicTarget(Metabolics.JumpFence)`，即 B42 自带代谢消耗体系。本 MOD **不重复驱动**原版代谢（独立记账，互不调用），只在体重联动处借道原版结果（§7.7）。

### 7.3 每日结算（`Nutri_History.lua`，EveryDays 0:00）

```lua
function Nutri.History.onEveryDays()
    local player = getPlayer()
    local st = Nutri.Data.state(player)
    local day = getGameTime():getNightsSurvived()        -- 游戏日序号（单调）
    if st.lastSettleDay == day then return end           -- 幂等
    st.lastSettleDay = day

    local net = Nutri.Core.computeNet(st.intakeToday, st.burnToday)   -- 各营养素净额
    local score = Nutri.Core.scoreDay(net)               -- d_i = clamp(net/DRI, -1, 1)
    local entry = { day=day, net=net, score=score,
                    exercise=st.exerciseToday, weightKg=player:getNutrition():getWeight() }
    Nutri.History.pushRolling(st.history, 7, entry)      -- 滚动 7 天
    Nutri.History.rebuildRecent2(st)                     -- 近 2 天净额缓存
    Nutri.Diseases.evaluate(player, st, score)           -- 疾病触发/恢复
    Nutri.Growth.dailySettle(player, st, entry)          -- 成长 + 体重
    Nutri.Data.resetDayCounters(st)                      -- intake/burn 清零
end
```

`EveryDays` 只在游戏运行到 0:00 时触发；玩家若长期 23:59 退出、0:01 读档，读档后需在 `OnGameStart` 用 `lastSettleDay` 与当前 `getNightsSurvived()` 补算（最多补 1 天；跨多天只补最近一天，中间运动量按 0 处理——保守，避免挂机穿越刷成长）。

### 7.4 短期耐力修正（`Nutri_Growth.lua`，每小时/每秒软修正）

B42 没有"耐力上限"setter。设计 §4.4.3 的两类效果用**软钳制 + 恢复速率**实现（全部可配置、可逆）：

- 上限修正：每秒检查，`cap = clamp(1 + 上限修正合计, 0.8, 1.2)`；若 `stats:get(CharacterStat.ENDURANCE) > cap` 则 `set(... cap)`。
- 恢复速率：玩家"非奔跑且耐力未满"时，每秒由本 MOD 补一口 `Δ = 基础恢复常量 × 恢复系数合计 × dt`，再 `set(clamp(e + Δ, 0, cap))`。基础恢复常量在调试期对照原版自然恢复标定（R7），保证系数 1.0 时与原版体感一致。
- 碳水冻结（当天 `score.carbs < -0.6`）：停止 MOD 补能且不阻止原版消耗（即"恢复冻结"）。
- 多病并发：所有修正先在 `Nutri.Core.composeModifiers(sourceList)` 内做归一化（设计 §4.4.4）：
  - 乘区相乘后 clamp 到 [0.5, 1.5]；
  - 加区求和后 clamp 到 [-0.35, +0.2]；
  - 最终上限 clamp [0.65, 1.2]。

修饰器全部是**每帧可重算的纯派生物**（来源：recent2 + 疾病 level），不保存"已扣减"值；摘除疾病后自然还原，避免存档漂移。

### 7.5 长期成长（Fitness/Strength XP）

每日结算后（与设计 §4.4.4 公式一致）：

```lua
local function xpDelta(stim, sat, cfg)            -- stim:0..1, sat:-1..1
    local raw = stim * sat * cfg.xpGainK
    if sat < 0 then raw = -(stim*cfg.xpLossKHigh + (1-stim)*cfg.xpLossKLow) * -sat end
    return Nutri.Core.clamp(raw, -cfg.dailyAbs, cfg.dailyAbs)  -- 单日绝对上限
end
-- 调原版（静默、不弹 halo）：
player:getXp():AddXP(PerkFactory.Perks.Fitness, deltaF, true, false)
player:getXp():AddXP(PerkFactory.Perks.Strength, deltaS, true, false)
```

约束与复用：

- 前置门：`player:getNutrition():canAddFitnessXp()` 返回 false 时不加正增长（复用原版封顶/特质逻辑，设计 §4.5"不绕过"）。
- 最简 2 参重载只对本地玩家生效；这里显式传 `noMultiplier=true, haloText=false` 走 4 参重载，避免特质倍率二次叠加。
- 负 delta 的可用性以 R4 实测为准；若被拦截，降级为"暂停自然成长 + 用 `setXPToLevel` 不掉级但削当前级进度"，并在日志告警。
- 满足度取蛋白+碳水的 7 天均值（设计口径），与体重联动共享同一份评分。

### 7.6 体重联动（借道原版，不接管）

B42 `Nutrition` 的体重由原版 `update()` 根据热量与 `isIncWeight/isDecWeight` 标志自行演化。本 MOD **只做速度因子微调**：

- 每日结算根据设计 §4.5 四象限，决定一个 `weightBias ∈ [-1, +1]`（亏空高运动最强 -1，盈余低运动最强 +1）。
- 实现仅允许两种之一（R8 实测选）：
  1. 直接小幅 `nutrition:setWeight(getWeight() + 0.1 * biasSign)`（设计步长，按周期），随后让原版 update 继续；
  2. 不改重量，只在本 MOD 的"运动消耗"里反映体重（>95kg 跑步消耗系数、<55kg 力量流失），体重完全交给原版热量账。
- **禁止**直接灌 calories/lipids 去"催促"体重（会破坏原版饥饿/代谢平衡）。
- 阈值联动（55/95kg）只读 `getWeight()`，作为消耗/成长的乘数。
- 设计"负重上限增"不新增机制：B42 负重受特质/力量影响，随 Strength XP 自然变化，MOD 不另设接口。

### 7.7 疾病系统（`Nutri_Diseases.lua`）

表驱动状态机（配置见 `Nutri.Config.Disease`）：

```
每个疾病日评估（输入：7 天均值评分 history[k].score、连续计数）：
  score < threshold 且持续 needN 天 → stage 沿 0(潜伏)->1->2->3 演进
  score 连续 recoverM 天达标        → stage 逐级下降
  level 变化时：先摘除旧症状修饰，再应用新症状修饰（applied 列表）
```

数据存 `md.Nutri.disease[id] = { level, deficitDays, recoverDays }`；"潜伏"用 `level=0 + deficitDays>0` 表达，UI 只在 level≥1 显示病名。

症状落地映射（设计 §4.6.2 → 实现）：

| 疾病 | 实现落点 |
|---|---|
| 坏血病 | 疲劳恢复系数（§7.4 恢复乘区）；伤口愈合：B42 `BodyDamage/BodyPart` 愈合接口实测（R9），首版用"受伤时额外 `ReduceHealth(小幅)`"近似"愈合变慢"；失血倾向：低血量随机微伤 |
| 贫血 | 耐力上限/耗耐系数（进入 §7.4 修饰器）；重度偶发"眩晕"：`setBlockMovement(true)` 0.5s + 视觉抖动，定时器必须在玩家死亡/登出时清除（R6） |
| 电解质紊乱 | 耐力恢复乘区；"抽搐"：1s `setBlockMovement`；重度"控制倒置"首版降级为摇晃+锁移动（输入改写依赖 B42 input component，R3/R6 后增强） |
| 消瘦 | 受伤易伤：挂 `OnWeaponSwing` 无关，改在受击事件或 BodyDamage 减血路径做乘数（R10）；耐力恢复乘区；负重：修正仅反映在 MOD 自身消耗（无安全 setter 直接降原版容量） |
| 夜盲症 | 首版用**夜间屏幕蒙层**（client 全屏 ISPanel，按夜晚时段与等级加深径向遮罩），不碰光照；光照接口可行后再换真视野（设计已允许） |
| 脚气病 | 疲劳：`stats:set(CharacterStat.FATIGUE, clamp)` 的缓慢增量（奔跑触发额外 +）；日常疲劳乘区 |
| 骨质流失 | 武器掉落：`OnWeaponSwing` 后小概率调用原版"手部掉落"（`removeFromHands`/unEquip，实测 R11）；骨折愈合/摔落骨折率：BodyDamage 骨折接口（B42 骨骼系统）实测（R9） |

视觉层：苍白等外观通过角色外观/血色调色实现（仅在确认安全接口后做，首版可只做 UI 提示）；**不新增 Moodle 图标**（设计 §8）。
归一化：所有疾病修饰经 §7.4 `composeModifiers` 汇总后一次性作用，任何属性最终值先 clamp 再写，杜绝负数/NaN（对验收用例 6）。

### 7.8 UI（client）

#### 7.8.1 容器与标签页

- `Nutri_UI_Main`：`ISPanel:derive("NutriUIPanel")`，420×560（配置），`initialise` 内建顶部 `ISTabPanel`（三页：状态/趋势/健康），各页是独立 ISPanel 派生类并 `addTab(名称, view)`。
- `addToUIManager()` 显示；`setVisible(false)`/`removeFromUIManager()` 关闭。首版关闭即移除、打开重建（状态全从 shared 查询函数实时取，无本地缓存一致性问题）。
- 可拖拽（ISPanel/ISCollapsableWindow 原生能力，选用 ISCollapsableWindow 包标题栏时主题要自绘贴图，首版直接 ISPanel + 自绘标题栏）。

#### 7.8.2 刷新

- 打开时渲染一次；面板可见期间在 `OnPlayerUpdate` 内节流刷新（≥250ms 一次），关闭即解绑。
- 每页只调查询接口：`Nutri.Core.todayRatios(player)`、`Nutri.History.series7(player)`、`Nutri.Diseases.diagnostics(player)`。

#### 7.8.3 自绘内容

- 进度条：`drawRect` 两条（槽 + 填充），无圆角无渐变；状态色来自 `Nutri_UITheme`（设计 §4.8：绿/黄/红低饱和 + 深棕描边 + 米色底）。
- 状态文字：`drawText(text, x,y, r,g,b,a, UIFont.Small)`；三列固定宽度，满足中文不错位。
- sparkline（趋势页）：7 点折线，用像素绘制（无第三方库）：相邻点用 1px 高 `drawRect` 段近似连线，或自写 Bresenham；点数固定 7，坐标映射 `-1..1 → 高度`，0 轴画一条分隔线。
- tooltip：`ISToolTip:new()` + `setName/setDescription`，hover 进度条时挂 `:addToUIManager()`、移出 `:removeFromUIManager()`。
- 色盲友好：颜色 + 文字标签（达标/注意/危险/过量）双编码。

#### 7.8.4 快捷键

- 封装在 `Nutri_Keybind.lua`：启动尝试 `PZAPI.ModOptions:addKeyBind(...)`（默认 N，配置 `Ui.keyDefault`），失败降级为 `OnKeyKeepPressed` 比较默认键码；按键事件只在游戏世界中且输入框未聚焦时响应（避免聊天框打字触发）。
- 右上角按钮备用入口（设计 §4.7.1）：在原版 HUD 上叠加一个 `ISButton`（若挂接 HUD 成本高，首版降级为"仅快捷键"，并在选项提示）。

---

## 8. 关键时序

### 8.1 进食（即时）

```
玩家完成一口进食
 └─ 原版 IsoGameCharacter:Eat(food, percentage, useUtensil)
     ├─ 原版 Nutrition 四营养 + calories（原版账，不动）
     ├─ 脚本 OnEat → Nutri_OnFoodEaten(info, player, percentage)
     │    ├─ 原 OnEat 链（保留）
     │    └─ Nutri.Core.onEat
     │         ├─ lookupPer100（精确表/分类兜底）
     │         ├─ 重量折算 → 8 大类 + 4 预留细项
     │         └─ md.Nutri.intakeToday 累加（即时落盘）
     └─ 原版剩余流程（UseAndSync 等）
```

### 8.2 运动（每秒 + 瞬时）

```
OnPlayerUpdate(player) 每 tick
 └─ Exercise：世界时间差累加，满 1.0s
      ├─ 姿态档位判定（sprint>run>sneak>moving>idle）
      ├─ 负重档 × 温度档 → 修正系数
      ├─ burnToday += 档位向量 × 系数
      ├─ exerciseToday 加权
      └─ Growth：耐力软钳制/恢复（§7.4 修饰器汇总后一次写入）
OnWeaponSwing(player, weapon) → 武器重量档 → burnToday.instant
TimedAction.perform（翻越/翻窗/绳索/破门）→ 固定向量 → burnToday.instant
（每 10 游戏分钟：modData 落盘一次）
```

### 8.3 每日 0:00（EveryDays，含读档补算）

```
EveryDays（或 OnGameStart 检测跨日）
 └─ History.onEveryDays（按游戏日幂等）
      ├─ net = intakeToday − burnToday
      ├─ score = clamp(net / DRI, −1, 1)
      ├─ history 入队（截 7 条）→ recent2 重建
      ├─ Diseases.evaluate（7 病状态机；摘旧症状/挂新症状）
      ├─ Growth.dailySettle
      │    ├─ 短期：刷新 recent2 修正（实际每秒生效，此处刷缓存）
      │    ├─ 长期：XP AddXP（Fitness/Strength，canAddFitnessXp 门控）
      │    └─ 体重：bias 计算 → §7.6 两种实现（R8 选型）
      └─ 日计数器清零、即时落盘
EveryHours：症状插值/短期窗口缓存刷新（轻量）
```

---

## 9. 多人预留（第一版不启用）

- 结算全在 shared，未来多人时：进食/运动写入点改为**服务器权威**（OnEat 回调在服务端 Eat 流程同样会调；`OnPlayerUpdate` 仅客户端，需替换为服务端角色 update 事件或客户端上报+服务端校验）。
- 全局共享数据改走 `ModData.getOrCreate("Nutri.Global")` + `transmit/request`；玩家私有结果仍存 `player:getModData()` 但需自定义网络字段同步（B42 network fields）。
- B42 存在 XP 反作弊（`AntiCheatXP*`），服务器主动 AddXP 需走 packet（`AddXpPacket` 已在 B42 源码中）。
- 所有写入函数内部预留 `Nutri.Core.isAuthority(player)` 开关（单机恒 true），第一版不引网络代码。

---

## 10. 性能预算

| 项 | 措施 |
|---|---|
| OnPlayerUpdate | 不闭包分配、不查表遍历；档位判定固定顺序；1s 节流；修饰器汇总每秒最多一次 |
| OnEat | 仅进食瞬间执行，全表查找为哈希索引 O(1)；脚本枚举只在启动一次 |
| EveryDays | 单玩家 7 条历史 + 7 疾病，常量级 |
| UI | 不可见不解绑也要停刷新（关闭即移除监听）；sparkline 7 点定长；无逐帧字符串拼接（文本缓存，数值变化才重建） |
| 落盘 | 每秒数据只写内存表，10 分钟/关键事件写 modData |
| 验收（设计 §6.2-7） | 1 游戏小时 CPU 增量阈值在调试期用 `-debug` 性能视图测定，超阈值则把温度查询/负重查询做秒级缓存 |

---

## 11. 错误处理与兼容性约定

1. 所有原版 API 调用假设可能返回 nil（`getPrimaryHandItem()`、`getNutrition()` 早期时序）：先判空。
2. 食物相关先 `instanceof(item, "Food")`；全名/`getFoodType()` 用 `tostring()` 兜底。
3. hook 一律"包装 + pcall + 原链返回值透传"，任何 MOD 错误不得阻断原版进食/翻越。
4. 不读 Java 实例字段（B42.15+ Release 限制），只用方法；若某信息只有字段（§14-R3 等），用百科反射辅助函数并集中封装在 `Nutri_DataLayer.reflect`。
5. 所有写入原版状态的值先经 `Nutri.Core.clamp(v, lo, hi)`；NaN 防御：除法分母为 0 时返回中性值 0。
6. 与其他 MOD 的兼容：OnEat 钩子保存并调用原 `getOnEat()`；TimedAction 包装保存原 `perform`；不独占 `setOnEat`（多 MOD 同时包装时，后装者会看到我们的钩子名——文档化此顺序风险，必要时改为在钩子内动态查询）。
7. 日志统一 `Nutri.log(level, fmt, ...)`，开关在 Config；错误级别打 `print`（入 console.txt），调试级别默认关。

---

## 12. 调试与测试

### 12.1 工具链（百科《Debug mode》）

- `-debug` 启动；Debug 菜单可刷物品、刷时间、重置 Lua（Reset Lua 后需验证 hook 幂等重装）。
- F11 Lua 调试器断点；`Zomboid/console.txt` 查错误堆栈与本 MOD 日志。
- 调试造境命令做成 client 调试函数（仅 debug 模式注册）：
  `Nutri.Debug.give(fullType, count)`、`Nutri.Debug.skipDays(n)`、`Nutri.Debug.setBurn(carbs,min)`、`Nutri.Debug.forceDisease(id, level)`、`Nutri.Debug.dump(player)`（打印 modData 全量）。

### 12.2 分层测试（对应设计 §6）

| 层 | 做法 |
|---|---|
| 纯函数单测 | `computeNet / scoreDay / matchWeightTier / composeModifiers / xpDelta / 状态机 evaluate` 写成无副作用纯函数；用标准 Lua 5.1 跑独立断言脚本（不依赖 Kahlua/Java 对象，输入输出全用 table） |
| 集成 | 沙盒开局 + §12.1 造境函数人工/半自动验证 |
| 持久化 | 操作 → 退到主菜单 → 读档 → `Nutri.Debug.dump` 比对；跨 0:00 读档验证补算 |

设计 §6.2 的 7 个用例映射：

1. 摄入折算 → 100g 罐头：`lookupPer100` 精确命中 + `actualWeight × percentage` 折算断言。
2. 运动：冲刺 30s 比对 `burnToday.carbs/minerals`；翻越触发一次 instant=30/8。
3. 成长：造境连刷 7 天盈余+高刺激 → Fitness/Strength XP 上升；亏空 → 下降（依赖 R4）。
4. 疾病：VC 连续 3 天亏空 → 潜伏→轻度；补足 2 天 → 降阶；读档保持。
5. 体重：盈余少动增重；`canAddFitnessXp` 封顶仍生效（特质门控不被绕过）。
6. 并防：7 病满级 → 修饰器汇总后所有属性在界内、无 NaN。
7. 性能：1 游戏小时采样（§10）。

### 12.3 配置即调参

平衡只改 `Nutri_Config.lua`；配置加载时做一次 schema 自检（缺键/类型/范围），错误直接在 console 报出，防止改错配置静默失真。

---

## 13. 构建与安装

- 开发：直接把 `NutritionMod/` 放入 `Zomboid/mods/`，游戏内 MOD 列表勾选；改 Lua 后用 Debug 菜单 Reset Lua 或重进世界。
- 分发目录（预留 Workshop）：按百科 B42 布局，`Contents/mods/NutritionMod/42/...` + `workshop.txt` + `preview.png`（发布阶段再做）。
- 资产需求：首版零外部资产（全部 ISUI 自绘 + 原版字体/颜色）；`poster.png` 发布前补。

---

## 14. 待实测项与技术风险（编码前/中必须上机确认）

| 编号 | 项 | 验证方法 | 失败降级 |
|---|---|---|---|
| R1 | 脚本食物类型判定（`getType()==Food` 的确切枚举写法）、`setOnEat` 在脚本对象上启动期设置是否对后续生成实例生效 | 调试模式启动后枚举打印食物数量；吃一口未配置 MOD 表的食物看日志 | 改为在 `OnCreatePlayer` 后对背包/世界已有 Food 实例设置 + 监听容器事件（重） |
| R2 | `PZAPI.ModOptions` 及 `addKeyBind/getOptions` 在 B42.20 的确切存在与签名 | F11 里 `print(PZAPI, PZAPI and PZAPI.ModOptions)`；选项界面查看 | OnKeyKeepPressed + 默认键码 fallback |
| R3 | `isSneaking()` 是否等价 B42 蹲姿；`CharacterInputComponent` 是否可从 Lua 取（`player:getInputComponent()` 等） | 实测三姿态下各谓词返回 | 蹲走档并入步行档×1.4 配置常量，行为差异接受 |
| R4 | `XP:AddXP` 负增量是否生效、是否触发反作弊/halo | 造境亏空 7 天观察技能 XP 面板 | 只抑制增长 + 削当前级进度（不降级），日志告警 |
| R5 | B42 TimedAction 翻越/窗/绳/破门的确切类名与方法（B42 重写过移动动作） | 在本机 `media/lua/client/TimedActions/` 目录核对 | 用 OnPlayerUpdate 姿态+高度/位移启发式结算瞬时消耗 |
| R6 | `setBlockMovement` 锁定 0.5–1s 的副作用（联机/寻路/卡住）；死亡与登出清理 | 造境反复触发 + 读档 | 改为纯视觉+耐力惩罚，不锁输入 |
| R7 | 耐力自然恢复常量标定（保证恢复系数 1.0 等价原版） | 静止实测秒级耐力回升曲线 | 缩小 MOD 干预幅度，仅做乘区近似 |
| R8 | 体重联动实现选型（§7.6 方案 1/2）、`setWeight` 后原版 update 是否回弹 | 长周期造境称重 | 方案 2：只做消耗/成长侧体重系数，不写重量 |
| R9 | BodyPart/BodyDamage 伤口愈合速率、骨折相关 B42 接口 | 反编译本机类 + 受伤实测 | 用受伤加伤近似愈合变慢；骨质病症状缩减 |
| R10 | 受击/受伤事件名与参数（消瘦"受伤+"） | OnWeaponHitX/OnPlayerDamage 类事件实测 | 仅保留耐力侧症状 |
| R11 | 小概率"武器掉落"的安全原版调用（unEquip 路径） | 挥击实测 | 删掉该表现，保留数值惩罚 |
| R12 | `DrinkFluid`（B42 流体）是否经过 OnEat 钩子 | 喝汤/喝水造境 | 挂 DrinkFluid 并列钩子或其脚本字段 |
| R13 | Reset Lua 后全部 hook 的幂等重装（开发期高频操作） | Debug → Reset Lua 多次 | install 全部带 done 标记且可重入 |

无 R 标记的内容均为已核实事实。编码顺序建议先打通 R1（进食）→ R5/R3（消耗）→ R7/R4（成长）→ 疾病 → UI，优先消除最高不确定性。

---

## 15. 实施里程碑（文件级任务）

1. **M1 骨架**：`mod.info` + 目录 + `Nutri_Config`（含自检）+ `Nutri_DataLayer`（freshState/ensurePlayer/migrate + 60–80 食物表 + 兜底）+ Debug.dump。
2. **M2 进食闭环**：`Nutri_EatHook`（R1/R12）+ `Core.onEat/addIntake`；验收用例 1。
3. **M3 消耗**：`Nutri_Exercise` 每秒结算（R3/R7 不阻塞数值框架）+ 武器 + TimedAction（R5）；验收用例 2、7。
4. **M4 每日结算**：`Nutri_History` + EveryDays/读档补算 + 评分纯函数单测。
5. **M5 成长/体重**：`Nutri_Growth` 短期修正（composeModifiers）+ XP（R4）+ 体重（R8）；验收用例 3、5。
6. **M6 疾病**：`Nutri_Diseases` 7 病表 + 状态机 + 症状落点（R6/R9/R10/R11）；验收用例 4、6。
7. **M7 UI**：主题 + 三页 + sparkline + tooltip + 快捷键（R2）；验收（设计 §9-3）。
8. **M8 打磨**：性能阈值测定、console 清理、配置终调、读档矩阵。

---

## 16. 附录：API 速查

```lua
-- 事件
Events.OnCreatePlayer.Add(fn)          -- fn(playerIndex:number, player:IsoPlayer)
Events.OnGameStart.Add(fn)             -- fn()
Events.OnPlayerUpdate.Add(fn)          -- fn(player) 每 tick
Events.OnWeaponSwing.Add(fn)           -- fn(attacker, weapon)
Events.EveryDays.Add(fn)               -- fn() 每天 0:00
Events.EveryHours.Add(fn)
Events.OnKeyKeepPressed.Add(fn)        -- fn(key:number)
-- 玩家
local p = getPlayer()
p:getModData()                                                         -- 持久化 table
p:getNutrition():getCalories()/getWeight()/canAddFitnessXp()
p:getStats():get(CharacterStat.ENDURANCE) / :set(CharacterStat.ENDURANCE, v)
p:getXp():AddXP(PerkFactory.Perks.Fitness, delta, true--[[noMult]], false--[[halo]])
p:isSprinting()/isRunning()/isSneaking()/isMoving()/getInventoryWeight()
p:getPrimaryHandItem()
-- 食物（OnEat 回调内）
info:getFullType()/getFoodType()/getActualWeight()
info:getCalories()/getCarbohydrates()/getLipids()/getProteins()
-- 脚本枚举（启动期）
ScriptManager.instance():getAllItems()         -- ArrayList，:size()/:get(i)
scriptItem:getOnEat()/setOnEat("GlobalFnName")
-- 环境
getClimateManager():getAirTemperatureForCharacter(p, false)
getGameTime():getWorldAgeHours()/getNightsSurvived()
-- 全局 ModData（多人预留）
ModData.getOrCreate(tag)/transmit(tag)
-- UI
local panel = ISPanel:new(x,y,w,h); panel:initialise(); panel:addToUIManager()
self:drawRect(x,y,w,h,a,r,g,b); self:drawText(t,x,y,r,g,b,a,UIFont.Small)
ISButton:new(x,y,w,h,title,target,onClick)
tab:addTab(name, viewPanel); ISToolTip:new()/:setName(s)/:setDescription(s)
```

### 参考来源

- PZwiki：[Modding(zh-hans)](https://pzwiki.net/wiki/Modding/zh-hans)、[Mod structure](https://pzwiki.net/wiki/Mod_structure)、[Lua (API)](https://pzwiki.net/wiki/Lua_(API))、[Lua events 分类](https://pzwiki.net/wiki/Category:Current_Lua_events)、[Debug mode](https://pzwiki.net/wiki/Debug_mode)
- B42.20.2 反编译源码：`github.com/Ketum-Git/PZ-Javacode`（`IsoGameCharacter.java`、`BodyDamage/Nutrition.java`、`characters/Stats.java`、`CharacterStat.java`、`inventory/types/Food.java`、`world/moddata/ModData.java`、`scripting/ScriptManager.java` 等）
- 事件签名：`github.com/PZ-Umbrella/Umbrella` 的 `library/events.lua`
- B42 实装参考：`github.com/FrozenHeart247/Extensive-Health-Rework-B42`（OnEat 用法、ISPanel 自绘、ModOptions 按键）
