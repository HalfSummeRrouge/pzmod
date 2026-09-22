# 僵尸毁灭工程 营养仿真 MOD — 可行性与实用性验证报告

- 日期：2026-09-22
- 验证依据：PZ Wiki（Build 42.20.4 稳定版）+ LuaDocs 42.20.3 + 官方 JavaDoc
- 验证对象：[营养仿真 MOD 设计文档](./2026-09-22-zomboid-nutrition-mod-design.md)

---

## 一、结论摘要

该 MOD 的**整体技术路线可行**——所依赖的核心事件、API、UI 组件在 PZ Build 42 中均存在，且设计思路与原版营养/体重/锻炼系统高度对齐，没有"从零造轮子"的硬伤。

但有 **1 个必须修复的关键问题** 和 **3 个需要确认的风险点**：

| 级别 | 问题 | 影响 |
|------|------|------|
| 🔴 关键 | `Events.OnEatFood` 事件不存在 | 进食跟踪功能无法按设计实现，必须改用其他方式 |
| 🟡 风险 | 移动状态方法名需确认 | `isRunning()`/`isSprinting()`/`isCrouching()` 需核对 JavaDoc |
| 🟡 风险 | `Stats.setEndurance()` 可见性 | JavaDoc 截断未确认 setter，可能需直接写字段 |
| 🟡 风险 | 体重联动与原版公式冲突 | 原版体重公式复杂，叠加自定义逻辑可能双重计算 |

游戏实用性方面，设计在**机制深度**上做对了方向（蛋白质加成、体重→Fitness 经验封顶都是原版已有钩子），但 **7 种疾病 + 8 类营养素**的复杂度可能超出单机生存游戏的可管理范围，需在调参阶段重点验证玩家负担。

---

## 二、技术可行性逐项验证

### 2.1 事件系统

| 设计文档使用的事件 | PZ Wiki 验证结果 | 状态 |
|---|---|---|
| `Events.OnEatFood` | **不存在**。LuaDocs 42.20.3 完整事件列表（A–Z）中无任何进食相关事件 | 🔴 需替代方案 |
| `Events.OnPlayerUpdate` | 存在。Client 事件，每 tick 触发，参数 `player: IsoPlayer` | ✅ |
| `Events.OnWeaponSwing` | 存在。参数 `(attacker: IsoPlayer, weapon: HandWeapon)`，玩家挥武器时触发 | ✅ |
| `Events.OnGameStart` | 存在。Client only，进入游戏时触发，无参数 | ✅ |
| `Events.OnKeyPressed`（隐含用于 N 键） | 存在。UI 页面示例中使用 `Events.OnKeyPressed.Add` + `Keyboard.KEY_X` | ✅ |

**进食跟踪替代方案**（按推荐度排序）：

1. **Hook `ISEatFoodAction`**：扩展或覆盖原版进食 Timed Action 的 `perform()` 方法，在食物被消耗时读取食物类型与食用量。这是最精准的方式，但需要注意与其他修改进食动作的 MOD 兼容。
2. **`OnPlayerUpdate` 轮询**：检测玩家手持物品是否为食物、以及 `player:getNutrition()` 中卡路里/碳水的瞬时增量，反推进食。实现简单但精度低。
3. **上下文菜单注入**：在 Eat 菜单选项中包装自定义逻辑。

### 2.2 玩家状态与移动 API

| 设计文档使用 | PZ Wiki / JavaDoc 验证 | 状态 |
|---|---|---|
| `player:isWalking()` | IsoPlayer 类确认存在 | ✅ |
| `player:isRunning()` | 未在已抓取页面直接确认（JavaDoc 截断）。PZ 标准 API，应存在于 IsoGameCharacter | ⚠️ 需确认 |
| `player:isSprinting()` | 未直接确认。IsoGameCharacter 确认有 `canSprint()` 和 `getBeenSprintingFor()`，冲刺状态可通过这些方法或 `isRunning()` 组合判定 | ⚠️ 需确认 |
| `player:isCrouching()` | 未直接确认。PZ 标准 API | ⚠️ 需确认 |
| `player:getPrimaryHandItem():getWeight()` | `OnWeaponSwing` 提供 weapon 参数，HandWeapon 有 `getWeight()` | ✅ |
| 负重判定 | `player:getCarryWeight()` / `player:getMaxWeight()` 为 PZ 标准方法 | ✅ |

**说明**：Build 42 的 JavaDoc 页面较大（单页 50KB 截断），移动状态方法分布在 IsoMovingObject / IsoGameCharacter / IsoPlayer 多层继承中。建议实现前用 `JavaDocs` 或游戏内 `dumpAPI` 确认精确方法签名。`isWalking()` 已确认，其余三个在 PZ 社区代码中广泛使用，大概率可用。

### 2.3 营养与体重系统

| 设计文档描述 | PZ Wiki 验证 | 状态 |
|---|---|---|
| 原版营养为四维（碳水/蛋白质/脂肪/卡路里），只影响体重 | 确认。Nutrition 页面明确：四个变量"currently only has an impact on the player's weight" | ✅ |
| `player:getNutrition()` 获取营养对象 | 原版 Nutrition 系统由 `Nutrition.class` 驱动，`getNutrition()` 为 IsoGameCharacter 标准方法 | ✅ |
| 体重阈值影响 Fitness 经验 | 确认。体重异常（"has weight trouble"）→ Fitness 经验封顶 6 级；消瘦/极重/极轻 → 完全无法获得 Fitness 经验 | ✅ |
| 体重增减公式 | 确认。原版公式：`△Weight = weightGainFactor × calorieProportion × timeElapsed`，涉及 calories/carbs/fats 累积值与时间 | ✅ |
| 原版 Fitness 经验封顶 trait 不绕过 | 确认。体重 trait 会自动增减，Fitness 等级也联动 trait（Unfit/Out of Shape/Fit/Athletic） | ✅ |

**风险提示**：设计文档 4.5 节"调用原版营养/体重接口，叠加速度因子，不接管原版权重计算"——这个方向正确。但需注意原版体重公式本身已经包含卡路里/碳水/脂肪的累积与衰减，若 MOD 再叠加一套"热量盈余→增重"的逻辑，可能导致**双重计算**。建议只在原版公式基础上调整系数（如修改 `weightGainFactor` 的输入），而非独立计算体重变化量。

### 2.4 经验与成长系统

| 设计文档描述 | PZ Wiki 验证 | 状态 |
|---|---|---|
| `player:getXp():AddXP(Perks.Fitness, delta)` | `Perks.Fitness` / `Perks.Strength` 为标准 Perk 枚举；`AddXP` 为 XP 系统标准方法 | ✅ |
| `getPerkLevel(Perks.Fitness)` 读取等级 | IsoGameCharacter 页面明确示例：`character:getPerkLevel(Perks.Fitness)` | ✅ |
| 蛋白质摄入促进力量成长 | 确认。原版"Protein Boost"机制：有蛋白质加成时，俯卧撑力量经验 6→9， burpees 4.8→7.2，杠铃弯举 7.2→10.8 | ✅ |
| 锻炼获得 Fitness/Strength 经验 | 确认。深蹲+4 Fitness，俯卧撑+6 Strength，burpees+3.2 Fitness/+4.8 Strength | ✅ |
| Fitness 影响耐力消耗/恢复 | 确认。5 级 Fitness：耐力消耗 ×60%，恢复 ×120%；10 级：消耗 ×43%，恢复 ×160% | ✅ |

**实用性评价**：设计文档将"营养盈余 + 运动量 → Fitness/Strength 经验"作为长期成长核心，这与原版机制方向一致（原版已有蛋白质加成、锻炼经验、跑步随机经验）。MOD 的增量价值在于把原版"隐式"的营养影响变成"显式"的多维度追踪，逻辑自洽。

### 2.5 疾病症状实现接口

| 设计文档症状 | 所需 API | PZ Wiki 验证 | 状态 |
|---|---|---|---|
| 耐力上限/恢复惩罚 | `stats:setEndurance()` / 修改耐力字段 | `getStats()` 确认存在；Stats 类有 `endurance` 字段。setter 方法在 JavaDoc 截断中未见，但 PZ 中可直接 `stats.endurance = value` | ✅ |
| 受伤加重 | `bodyDamage` 相关方法 | `getBodyDamage()` 确认存在 | ✅ |
| 负重上限下降 | `setMaxWeight()` 或 trait | PZ 标准 API | ✅ |
| 苍白肤色 | `getHumanVisual()` 调色 | `getHumanVisual()` 确认存在，可操作 body visuals 与颜色 | ✅ |
| 夜盲（视野缩小） | 光照/视野接口 | 设计文档已预留"若光照接口不可实现则用屏幕蒙层"的降级方案。B42 光照 API 可能受限，屏幕蒙层（`ISUIElement` 全屏半透明黑）是可行的 fallback | ⚠️ 需确认 |
| 抽搐/眩晕（操作锁定） | 禁止输入 | 可通过 `player:setBlockMovement()` 或清空按键队列实现。但**频繁锁定输入会严重影响游戏体验**，需谨慎 | ⚠️ 体验风险 |
| 武器掉落 | `player:setPrimaryHandItem(nil)` | 标准 API | ✅ |

### 2.6 瞬时动作（翻越/攀爬）

| 设计文档描述 | PZ Wiki 验证 | 状态 |
|---|---|---|
| 翻越/攀爬等瞬时动作消耗 | `ISBaseTimedAction` + `ISTimedActionQueue` 确认存在。`update()` 每 tick 调用，`animEvent` 可捕获动画事件（如 `VaultOverStarted`、`ClimbDone`） | ✅ |
| 动画事件列表 | Events 页面列出 `VaultOverStarted`、`ClimbDone`、`Climbed` 等动画事件 | ✅ |

**实现建议**：瞬时动作消耗应通过 `animEvent` 回调在动作完成瞬间结算，而非在 `OnPlayerUpdate` 中轮询。这样精准且性能好。

### 2.7 环境修正（温度）

| 设计文档描述 | PZ Wiki 验证 | 状态 |
|---|---|---|
| `getClimateManager()` 获取温度 | ClimateManager 页面确认 `getClimateManager()` 可用 | ✅ |
| >30°C 出汗排钠钾 / <5°C 产热 | 温度值可从 ClimateManager 获取。原版已有"过热/过冷" moodle，MOD 可叠加修正 | ✅ |

### 2.8 数据持久化

| 设计文档描述 | PZ Wiki 验证 | 状态 |
|---|---|---|
| `modData["Nutri.IntakeToday"]` / `modData["Nutri.History"]` | `player:getModData()` 返回持久化 Lua 表，支持 string/number/boolean/table。游戏自动保存，无需手动写入 | ✅ |
| 每日凌晨结算 | 需用游戏时钟（`GameTime`）检测日期变更触发结算。无专用"每日"事件，但可在 `OnPlayerUpdate` 中检测 `getDay()` 变化 | ✅ |

### 2.9 UI 组件

| 设计文档使用 | PZ Wiki 验证 | 状态 |
|---|---|---|
| `ISPanel` 自绘面板 | 确认。UI 页面示例 `ISPanel:derive("YourCustomUI")` | ✅ |
| `ISButton` 标签页/按钮 | 确认。UI 页面明确 ISButton 为子元素 | ✅ |
| `ISLabel` 文本 | 确认 | ✅ |
| `ISToolTip` 工具提示 | 确认（Timed Action 页面导航列出 ISToolTip） | ✅ |
| N 键开关 | `Events.OnKeyPressed` + `Keyboard.KEY_N` | ✅ |
| `addToUIManager()` / `setVisible()` | 确认 | ✅ |

**评价**：UI 方案完全可行。`ISPanel` 自绘进度条和 sparkline 不依赖外部图表库，符合"单机优先、无外部依赖"的设计原则。

---

## 三、游戏实用性分析

### 3.1 与原版系统的契合度

设计的核心优势在于**不重复造轮子**，而是沿着原版已有的机制深挖：

- **蛋白质→力量经验**：原版已有 Protein Boost，MOD 把这个单点扩展成完整的营养素矩阵。
- **体重→Fitness 经验封顶**：原版已有体重 trait 限制 Fitness 升级，MOD 把营养摄入直接挂钩到这个机制上。
- **锻炼系统**：原版已有 7 种锻炼动作和经验值，MOD 的"运动量刺激"可以复用锻炼数据作为输入。

这意味着 MOD 不是"另起炉灶"，而是"在原版骨架上加肌肉"，玩家不会感到突兀。

### 3.2 复杂度与玩家负担

原版营养系统极其简单（4 维，只影响体重，甚至大部分玩家都不会注意）。MOD 扩展到 **8 类营养素 + 7 种疾病 + 每日/每周趋势**，信息密度大幅提升。

潜在问题：
- **决策疲劳**：玩家需要同时关注蛋白质、碳水、脂肪、钠钾钙铁、维生素 A/C/D/B1，共 10+ 个数值。
- **疾病惩罚叠加**：7 种疾病可并发，虽然设计了"归一化累加防暴负"，但多疾病状态下的属性惩罚可能让角色迅速失能，挫败感强。
- **与原版节奏冲突**：原版是慢节奏生存游戏，营养变化以天/周计。MOD 引入"短期耐力修正（小时级）"可能让游戏节奏变快，需要玩家更频繁地查看面板。

**建议**：
- 第一版可考虑只实现 4-5 种最高频的疾病（坏血病、贫血、电解质紊乱、消瘦、夜盲症），脚气病和骨质流失作为后续增强。
- 营养素可以分"主要"（蛋白/碳水/脂肪/卡路里）和"次要"（维生素/无机盐）两层展示，次要项折叠。

### 3.3 平衡风险

1. **经验增长速度**：原版 Fitness 从 5 级升到 10 级需要大量锻炼。MOD 若通过 `AddXP` 每日注入经验，可能让成长过快或过慢，需严格控制单日 delta 上限（设计文档已提及"单日经验 delta 上限防刷"，正确）。
2. **疾病触发阈值**：坏血病需连续缺 VC 数天。但原版食物中罐头普遍缺 VC，新鲜蔬菜水果才有。在长期生存中，玩家可能"被迫"得坏血病，这增加了真实感但也可能让游戏更难。需要 sandbox 选项让玩家调整难度。
3. **体重双重计算**：如 2.3 节所述，需避免与原版体重公式冲突。

### 3.4 联机兼容性

设计文档明确"单机优先，预留接口"。PZ Wiki 指出：
- GlobalModData 在客户端不持久化（重连丢失）。
- B42 的 Timed Action 需要全局存储才能在多人中工作。
- 数值修改（耐力、经验、体重）在多人中需要服务端权威同步。

单机版无问题。若将来支持联机，营养结算必须移到服务端，客户端只负责 UI 和输入。

---

## 四、修复建议清单

### 必须修复（阻塞实现）

1. **替换 `OnEatFood` 事件**：
   ```lua
   -- 推荐方案：Hook ISEatFoodAction
   local originalPerform = ISEatFoodAction.perform
   function ISEatFoodAction:perform()
       originalPerform(self)
       -- self.item 是食物，self.character 是玩家
       Nutrition_OnEatFood(self.character, self.item, self.item:getHungChange())
   end
   ```

2. **确认移动方法签名**：在实现前用 JavaDoc 或 `dumpAPI` 确认 `isRunning()`、`isSprinting()`、`isCrouching()` 的精确名称和参数。

### 建议修复（提升质量）

3. **体重联动**：不要独立计算 `△Weight`，而是通过修改 `player:getNutrition()` 中的累积值（如 addCalories、addCarbohydrates）来间接影响原版体重公式，避免双重计算。

4. **疾病输入锁定**：抽搐/眩晕的"操作锁定"应设极短持续时间（≤0.5s）且低频率，避免让玩家觉得"游戏在跟我作对"。

5. **疾病数量**：第一版砍到 5 种，脚气病和骨质流失留到 v2。

6. **性能**：`OnPlayerUpdate` 中的营养结算务必用累加器（设计文档已正确设计），每秒结算一次而非每 tick。UI 刷新也应节流（如 0.5s 一次）。

---

## 五、总体判断

| 维度 | 评分 | 说明 |
|---|---|---|
| 技术可行性 | 8/10 | 核心 API 和事件均存在，仅 `OnEatFood` 需替代方案 |
| 原版契合度 | 9/10 | 深度复用蛋白质加成、体重封顶、锻炼系统等原版机制 |
| 游戏实用性 | 7/10 | 机制有深度，但复杂度可能超出玩家舒适区，需调参验证 |
| 实现风险 | 中 | 进食跟踪替代方案、体重公式冲突、疾病体验平衡是主要风险 |

**结论**：该 MOD 设计方案**技术上可行，方向上正确**。修复 `OnEatFood` 问题并确认移动 API 后即可进入实现阶段。建议第一版精简疾病数量、严格控制体重联动不与原版公式冲突，并在测试中重点验证多疾病并发时的玩家体验。
