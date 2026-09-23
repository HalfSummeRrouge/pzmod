# Real Metabolism — S1/S2 上机实测清单

- 日期：2026-09-23
- 目标版本：Project Zomboid Build 42.20.x（stable）
- 范围：M1 代码中全部 `TODO(S1)` / `TODO(S2)` 标记项（技术文档 §18）
- 性质：**离线单测无法覆盖，必须在真实游戏内验证**；结果回填本文档并同步修改 `RM_Config.lua`

---

## 0. 安装与环境准备（一次性）

### 0.1 安装 MOD 到游戏（开发目录方式，无需 Workshop 发布）

| 步 | 操作 |
|---|---|
| 1 | Win+R 输入 `%UserProfile%\Zomboid\mods` 回车；没有 `mods` 文件夹就新建 |
| 2 | 把仓库的 `RealMetabolism` 整个文件夹复制进去，最终结构：`Zomboid\mods\RealMetabolism\42\mod.info` |
| 3 | Steam 订阅 NeatUI（Workshop ID **3508537032**，硬前置） |
| 4 | Steam 库 → Project Zomboid 属性 → 启动选项填 `-debug` |
| 5 | 启动游戏 → 主菜单 MODS → 勾选 **Real Metabolism**（NeatUI 会自动带上） |
| 6 | 新建游戏（建议自定义沙盒：无僵尸/关闭疫情、9 月、时间流速默认） |

**改代码后的更新循环**：退游戏 → 覆盖 `mods\RealMetabolism\` 下的文件 → 重进世界（Lua 不热载）。

### 0.2 环境项

| 项 | 操作 |
|---|---|
| 日志 | `Zomboid/console.txt`（每项验证后查看 WARN/INFO） |
| 调试器 | F11 打开 Lua 调试器，实时查看 `RM` 全局表 |
| MOD 调试日志 | `RM_Config.lua` 第 13 行 `debug = false` 改为 `true`，重进世界 |
| 前置 | NeatUI（Workshop 3508537032）必须订阅并启用 |
| 建议档 | 沙盒：无僵尸、时间流速默认、起始 9 月（避开环境干扰） |

### 0.3 进世界后的自检（30 秒）

1. `console.txt` 无 `[RealMetabolism][WARN]`（尤其"NeatUI 缺失"）
2. 按 N 无报错（面板渲染待 S7，无异常即正常）
3. 吃任意一口食物 → `Zomboid\RealMetabolismProbe.csv` 出现新行（见下节）

---

## 0.5 自动采集（RM_Probe）——只管做动作，数据自动落盘

MOD 内置实测探针（`RM_Config.lua` 的 `probe.enabled = true` 默认开启），把下表数据**自动追加**写入 `Zomboid\RealMetabolismProbe.csv`（console.txt 旁边；找不到就全盘搜这个文件名）。行格式 `世界小时,事件类型,键=值;...`。

| CSV 事件 | 覆盖清单项 | 你需要在游戏里做的 |
|---|---|---|
| `session` | — | 无（进世界/读档自动写） |
| `bite` | S1-1 重量线性 / S2-4 池增减时机 | 吃东西（任意食物） |
| `eat` | S1-2 重复计算 / S1-3 分次剩食 / S1-6 腐烂 / S1-7 判类 | 吃完食物；分次吃/吃一半丢；新鲜与腐烂各吃一次 |
| `drink` | S1-5 容量单位 | 喝水（水瓶/水壶） |
| `hydrate` | S1-4 ThirstChange 换算 | 吃含水食物（罐头汤/水果） |
| `sample` | S2-1/2/2-3 池范围 / S2-8 体温 | 无（每 60 游戏秒自动记一行；绝食几天即得池下限） |
| `clock` | S2-5 睡眠加速 | 睡一觉 |
| `everydays` | S2-6 结算触发 | 无（0:00 自动写；睡过 0:00 也写） |
| `key` | S2-7 键位 | 按 N（单按一次/长按一次各试） |

**退出后的分析流程**：把 `RealMetabolismProbe.csv` 内容发给我 → 我按清单逐项出结论 → 回填 Config → 出新版本再验证。

**关掉探针**：`probe.enabled = false`（M4 发布前会默认关闭）。

### 0.6 手动抽查命令（F11 控制台，交叉验证用）

```lua
-- 玩家台账全貌
local md = getPlayer():getModData()["RM"]
-- 原生池
getPlayer():getNutrition():getCalories()
getPlayer():getNutrition():getCarbohydrates()
-- MOD 活值
RM.State.live.hydration
RM.State.fuel
```

---

## 1. S1 — 进食/饮水语义（7 项）

> 影响：`RM_Core.lua` 吃喝 hook、`RM_Hydration.onConsumeFood`、`Config.hydration.thirstUnitMl`

### S1-1 吃前重量是否线性反映已吃部分

| 项 | 内容 |
|---|---|
| 问题 | `item:getActualWeight()` 在 `ISEatFoodAction.eat` 每次咬合后是否按比例下降？ |
| 步骤 | ① 拿 1 个苹果（0.3kg），F11 输入 `getPlayer():getInventory():getItems()` 找到物品记 weight；② 吃 1 口停下，再看 weight；③ 吃完看 weight |
| 通过标准 | 每口后 weight 单调下降，吃完归零或接近 0 |
| 失败后果 | 重量差累计公式失效，gramsEaten 记不准 |
| 现状代码 | `RM_Core.lua` `_hookEatActions`（`__rmEatenKg` 累计） |
| 验证结果 | 待填 |

### S1-2 complete 时的重复计算

| 项 | 内容 |
|---|---|
| 问题 | `complete` 钩子把最后一次咬合差也累入 `__rmEatenKg`，与 `eat` 钩子是否重复计同一口？ |
| 步骤 | ① debug=true 后吃一整件食物；② 查 console 中 onEat 结算的 gramsEaten（`RM.Log.debug` 打印）；③ 对比物品原始重量 |
| 通过标准 | 累计 gramsEaten ≈ 物品原始克重（误差 <5%） |
| 现状代码 | `RM_Core.lua` `complete` 包装：`postW < preW` 时补差值 |
| 验证结果 | 待填 |

### S1-3 分次进食与剩食

| 项 | 内容 |
|---|---|
| 问题 | 分多次吃完同一件食物（中断后再吃），`__rmEatenKg` 是否只累计本次会话？丢弃剩下一半是否只记吃掉部分？ |
| 步骤 | ① 吃一口丢弃 → 看 md.micro 增量；② 分 3 次吃完 → 看总增量是否 = 全量 |
| 通过标准 | 增量与实际入口克重一致；丢弃部分不记账 |
| 验证结果 | 待填 |

### S1-4 ThirstChange → ml 换算系数

| 项 | 内容 |
|---|---|
| 问题 | `thirstUnitMl = 10`（每 1 点解渴 ≈ 10ml）量级是否正确？ |
| 步骤 | ① 水合设为 40（F11：`RM.State.live.hydration = 40`）；② 吃 1 罐汤（ThirstChange=-20）；③ 观察水合变化 |
| 通过标准 | 变化 +20 点（=200ml×0.1）；若原版体感汤解渴远多于此，调 `thirstUnitMl` |
| 现状代码 | `RM_Hydration.onConsumeFood`；`Config.hydration.thirstUnitMl` |
| 验证结果 | 待填 |

### S1-5 喝流体的容量单位

| 项 | 内容 |
|---|---|
| 问题 | `FluidContainer:getCapacity()` 单位是 ml 吗？`(preRatio−postRatio)×capacity` 是否等于本次喝入 ml？ |
| 步骤 | ① 拿满水瓶（容量标签 ml 数已知）；② 一次喝完；③ console 查 onDrink 收到的 ml 值 |
| 通过标准 | ml ≈ 水瓶标签容量 |
| 现状代码 | `RM_Core.lua` `_hookDrinkActions` |
| 验证结果 | 待填 |

### S1-6 腐烂对重量的影响

| 项 | 内容 |
|---|---|
| 问题 | 食物腐烂后 `getActualWeight()` 是否变化？（影响 gramsEaten → 微量记账） |
| 步骤 | ① 对照新鲜苹果与腐烂苹果各吃一次；② 比较 onEat 结算的 gramsEaten |
| 通过标准 | 重量不变（当前假设）；若变化，需在 `onEat` 中补偿 |
| 备注 | 降解保留率本身是 M3（`RM_Decay`），此处只关心重量 |
| 验证结果 | 待填 |

### S1-7 instanceof 判类边界

| 项 | 内容 |
|---|---|
| 问题 | 汤类/含水食物是否被 `instanceof(item, "Food")` 正确判定？非 Food 的饮品走水合分支是否正常？ |
| 步骤 | ① 吃罐头汤 → console 应有微量记账 + 补水；② 喝纯水 → 只补水、无微量记账 |
| 通过标准 | 两类路径各自触发，无遗漏无越界 |
| 现状代码 | `RM_Core.onEat` `isFood` 分支 |
| 验证结果 | 待填 |

---

## 2. S2 — 原生池量纲与时间轴（8 项）

> 影响：`RM_Scoring.energyScore/energyFeedback`、`RM_Fuel.tick`、`Config.energy/fuel`、每日结算时机

### S2-1 原生碳水池范围（最高优先）

| 项 | 内容 |
|---|---|
| 问题 | `getNutrition():getCarbohydrates()` 实际范围是多少？（当前假设满值 ≈ 300） |
| 步骤 | ① 新角色看初始值；② 吃高碳水食物（面包/糖）至吃不下，看上限；③ 绝食 2–3 天看下限（是否负值、多负） |
| 通过标准 | 得到实测 [min, max]；`carbSaturation=300` 使 energyFeedback 在正常饮食下落在 0.6–1.0 区 |
| 回填 | `Config.energy.carbSaturation` |
| 验证结果 | 待填（实测 min=___，max=___） |

### S2-2 空腹阈值

| 项 | 内容 |
|---|---|
| 问题 | 碳水池低于多少算"空腹/碳水枯竭"？（当前假设 -200） |
| 步骤 | 绝食状态下每小时记录碳水池值；观察饥饿 debuff 出现时的池值 |
| 通过标准 | `fastedCarbsBelow` 应在"明显饿但未濒死"区间 |
| 回填 | `Config.fuel.fastedCarbsBelow` |
| 验证结果 | 待填 |

### S2-3 原生热量池量纲

| 项 | 内容 |
|---|---|
| 问题 | `getCalories()` 实际范围？（energyScore 用 `热量池 / (TDEE×0.5)` 归一化） |
| 步骤 | 同 S2-1：饱食/绝食两端采样 |
| 通过标准 | 正常饮食下 energyScore 大部分时间 ∈ (-0.3, 1) |
| 回填 | `RM_Scoring.energyScore` 的归一化系数（必要时） |
| 验证结果 | 待填 |

### S2-4 池增减时机

| 项 | 内容 |
|---|---|
| 问题 | 吃食物后热量/碳水池**何时**增加（每口 or 完成）？ |
| 步骤 | 吃食物过程中逐口查看 `getCalories()` |
| 通过标准 | 明确时机；MOD 侧读取（每日 0:00 结算 + 每秒 energyFeedback）不受影响 |
| 验证结果 | 待填 |

### S2-5 睡眠时间加速下的累加器

| 项 | 内容 |
|---|---|
| 问题 | 睡眠时世界时间大幅跳秒，`_onPlayerUpdate` 世界时间差归一化 + 防螺旋上限（3600 步/帧）是否正确处理？水合基础流失（5/小时）睡眠期扣减是否合理？ |
| 步骤 | ① 睡 8 小时前后记录 `RM.State.live.hydration` 与 console WARN；② 醒后看 hydration 是否 -40 左右、无异常刷屏 |
| 通过标准 | 无 "tickSecond 异常" WARN；流失量 = 期望值（睡眠代谢减半是否需要——M4 调优项，先记录数据） |
| 现状代码 | `RM_Core._onPlayerUpdate` / `_maxCatchupSteps` |
| 验证结果 | 待填 |

### S2-6 EveryDays 睡眠期触发

| 项 | 内容 |
|---|---|
| 问题 | 0:00 玩家在睡觉时 `EveryDays` 是否照常触发？结算（lastSettleDay 推进）是否正常？ |
| 步骤 | ① 睡过 0:00 醒来后查 `md.lastSettleDay` 与 `#md.history`；② 非睡眠跨天对照 |
| 通过标准 | 两种情形下都恰好 +1 条历史；同日重复触发无双计 |
| 验证结果 | 待填 |

### S2-7 面板键位冲突

| 项 | 内容 |
|---|---|
| 问题 | N 键与原版功能（等）是否冲突？`OnKeyPressed` 触发是否单次？ |
| 步骤 | ① 进世界按 N → 面板开/关翻转一次；② 长按 N 不放 → 只翻转一次；③ 检查 N 是否被原版绑定占用 |
| 通过标准 | 单按翻转、长按不抖动、无原版冲突 |
| 现状代码 | `RM_Panel._onKey`（已用 OnKeyPressed，待实机确认）；ModOptions 改键为 M4 |
| 验证结果 | 待填 |

### S2-8 核心体温读数（顺带，M2 前置）

| 项 | 内容 |
|---|---|
| 问题 | `getCoreTemperature()` 正常/发热/受冻时的典型数值范围？ |
| 步骤 | 常态、淋雨、烤火旁各采样一次 |
| 通过标准 | 记录典型值，供 M2 环境阈值设定 |
| 验证结果 | 待填（常态___，受冻___，热___） |

---

## 3. 汇总回填表

| 编号 | 当前假设值 | 回填目标 | 结论（实测后填） |
|---|---|---|---|
| S1-4 | `thirstUnitMl = 10` | `Config.hydration.thirstUnitMl` | |
| S2-1 | `carbSaturation = 300` | `Config.energy.carbSaturation` | |
| S2-2 | `fastedCarbsBelow = -200` | `Config.fuel.fastedCarbsBelow` | |
| S2-3 | 归一化 = `TDEE×0.5` | `RM_Scoring.energyScore` | |
| S2-5 | 防螺旋 3600 步 | `RM_Core._maxCatchupSteps` | |
| S2-8 | — | M2 `Config.environment`（未建） | |

---

## 4. 实测操作剧本（探针版）

> 探针自动采集（§0.5）已覆盖被动观察项；你只需按下面顺序做动作，一个存档跑完 15 项。

**第一段：吃（覆盖 S1-1/2/3/4/6/7 + S2-4）**

1. 吃完一整个苹果（别打断）
2. 再拿一个苹果：吃一口 → 丢掉剩下的
3. 再拿一个苹果：吃两口 → 停 → 再吃完（分次）
4. 吃一罐汤（或任意含水食物）
5. 找一个腐烂食物吃一次（新鲜/腐烂对照）

**第二段：喝（S1-5）**

6. 用水瓶/水壶喝两三口水（中途停下），最后一口喝空

**第三段：按键（S2-7）**

7. 单按 N 一次；长按 N 一次

**第四段：睡（S2-5/S2-6）**

8. 睡到过 0:00，自然醒

**第五段：池标定（S2-1/2/2-3/8，最费时）**

9. 狂吃高碳水食物（面包/糖/麦片）到吃不下 → 记录时间点
10. 之后正常活动 2–3 天不进食（加速等待）→ 观察饥饿发展
11. 期间淋一次雨、在火堆旁站一会儿（S2-8 体温）

**退出后**：把 `Zomboid\RealMetabolismProbe.csv` 全文发我分析。

**注意事项**：
- 想要干净数据：开新档 + 删旧 `RealMetabolismProbe.csv`
- 每项数据探针自动落盘，本文档各"步骤"栏的手动 F11 操作仅作交叉验证，可跳过
- 发现失败项：**不要现场改代码绕过**——按约定先回报，确认方案再动（降级需先问）
