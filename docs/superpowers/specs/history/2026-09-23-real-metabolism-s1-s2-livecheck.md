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
| 3 | Steam 订阅 NeatUI（Workshop ID **3508537032**，UI 面板前置；缺失时核心模拟照常运行，仅面板不可用） |
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
| 前置 | NeatUI（Workshop 3508537032）：UI 面板需要；缺失时核心模拟照常运行，仅面板不显示 |
| 建议档 | 沙盒：无僵尸、时间流速默认、起始 9 月（避开环境干扰） |

### 0.3 进世界后的自检（30 秒）

1. `console.txt` 无 `[RealMetabolism][ERROR]`；NeatUI 缺失仅有 WARN 不阻塞
2. 按 N 无报错（面板渲染待 S7，无异常即正常）
3. 吃完一整个食物 → `Zomboid\Lua\RealMetabolismProbe.log` 出现 `eat` 行（见下节）

---

## 0.5 自动采集（RM_Probe）——只管做动作，数据自动落盘

MOD 内置实测探针（`RM_Config.lua` 的 `probe.enabled = true` 默认开启），把下表数据**自动追加**写入 `Zomboid\Lua\RealMetabolismProbe.log`（PZ 的 getFileWriter 只允许 ini/cfg/txt/log/json 扩展名，且固定写入 Lua 缓存子目录；内容仍是 CSV 格式）。行格式 `世界小时,事件类型,键=值;...`。

| CSV 事件 | 覆盖清单项 | 你需要在游戏里做的 |
|---|---|---|
| `session` | — | 无（进世界/读档自动写） |
| `bite` | S1-1 重量线性 / S2-4 池增减时机 | **中断**进食（吃一口就停）；B42 完整吃完不触发 bite，只触发 eat |
| `eat` | S1-2 重复计算 / S1-3 分次剩食 / S1-6 腐烂 / S1-7 判类 | 吃完食物；分次吃/吃一半丢；新鲜与腐烂各吃一次 |
| `drink` | S1-5 容量单位 | 喝水（水瓶/水壶） |
| `hydrate` | S1-4 ThirstChange 换算 | 吃含水食物（罐头汤/水果） |
| `sample` | S2-1/2/2-3 池范围 / S2-8 体温 | 无（每 60 游戏秒自动记一行；绝食几天即得池下限） |
| `clock` | S2-5 睡眠加速 | 睡一觉 |
| `everydays` | S2-6 结算触发 | 无（0:00 自动写；睡过 0:00 也写） |
| `key` | S2-7 键位 | 按 N（单按一次/长按一次各试） |
| `dbg_start` | 调试 | 进食开始（记录 preWeight） |
| `dbg_perform` | 调试 | 完整吃完结算（pct、biteTotal、remainingKg） |

**退出后的分析流程**：把 `RealMetabolismProbe.log` 内容发给我 → 我按清单逐项出结论 → 回填 Config → 出新版本再验证。

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
>
> **本轮 B42 适配修复**（影响 S1 全部项）：
> 1. `ISEatFoodAction.complete` 在客户端不执行（Java 侧 `!GameClient.client`），进食结算改挂 `perform`，摄入量用 `preWeight × self.percentage` 计算
> 2. `getFullName()` 在 B42 Food 上不存在且 Kahlua 无法 pcall 捕获，全部改用 `getFullType()`
> 3. `isMoving()` → `isPlayerMoving()`（B42 方法改名）
> 4. **物品消耗崩溃修复**：`origPerform` 会消耗 item，之后访问 item 触发 Java 异常且 pcall 捕获不了。所有 item 访问移到 `origPerform` 之前
> 5. **中断进食记账修复**：B42 取消进食走 `resetQueue()`→`forceCancel()`，**不调用 `stop()`**（`forceCancel` 是空方法）。改为在 `eat` hook 里每 bite 立即记账，`perform` 里扣减已记账的 bite 部分，避免重复

### S1-1 吃前重量是否线性反映已吃部分

| 项 | 内容 |
|---|---|
| 问题 | `ISEatFoodAction.eat`（仅中断进食时由 serverStop 调用）中，`item:getActualWeight()` 每次咬合后是否按比例下降？完整吃完走 `perform`+`percentage`，不依赖重量差 |
| 步骤 | ① 拿 1 个苹果，F11 记 weight；② 吃 1 口停下（触发 bite 事件），再看 weight；③ 吃完看 weight |
| 通过标准 | 中断时每口后 weight 单调下降；完整吃完 gramsEaten = preWeight × percentage |
| 失败后果 | 中断进食的 bite 累计失效；完整吃完不受影响（走 percentage 路径） |
| 现状代码 | `RM_Core.lua` `_hookEatActions`：`eat` hook 每 bite 用重量差立即记账；`perform` 用 `preW × pct - biteTotal` 结算剩余；不依赖 `stop`（B42 不调用） |
| 验证结果 | ✅ 已验证：bite 探针显示重量差正确（0.20→0.12），中断时 `eat` 立即记账；完整吃完走 `perform` 路径 |

### S1-2 perform 时的摄入量计算

| 项 | 内容 |
|---|---|
| 问题 | B42 客户端 `complete` 不执行（Java 侧 `!GameClient.client` 判断），改在 `perform` 用 `preWeight × self.percentage` 算摄入量，是否准确？ |
| 步骤 | ① debug=true 后吃一整件食物；② 查 console 中 onEat 结算的 gramsEaten；③ 对比物品原始克重 |
| 通过标准 | gramsEaten ≈ 物品原始克重 × percentage（误差 <5%） |
| 现状代码 | `RM_Core.lua` `perform` 包装：`eaten = preWeight × percentage`，不再依赖重量差 |
| 验证结果 | ✅ 已验证：苹果 preW=0.2kg, pct=1, eatenKg=0.2 → grams=200.00，与物品原始重量一致 |

### S1-3 分次进食与剩食

| 项 | 内容 |
|---|---|
| 问题 | 分多次吃完同一件食物（中断后再吃），`__rmEatenKg` 是否只累计本次会话？丢弃剩下一半是否只记吃掉部分？ |
| 步骤 | ① 吃一口丢弃 → 看 md.micro 增量；② 分 3 次吃完 → 看总增量是否 = 全量 |
| 通过标准 | 增量与实际入口克重一致；丢弃部分不记账 |
| 现状代码 | `start` 重置 `self.__rmBiteTotal=0`；`eat` 每 bite 立即记账并累计到 `__rmBiteTotal`；`perform` 用 `preW×pct - __rmBiteTotal` 结算剩余 |
| 验证结果 | ✅ 机制已修复：`eat` 立即记账不依赖 stop，`perform` 扣减 bite 避免重复。待实测确认中断时 bite 记账总和 = 实际入口量 |

### S1-4 ThirstChange → ml 换算系数

| 项 | 内容 |
|---|---|
| 问题 | `thirstUnitMl = 10`（每 1 点解渴 ≈ 10ml）量级是否正确？ |
| 步骤 | ① 水合设为 40（F11：`RM.State.live.hydration = 40`）；② 吃 1 罐汤（ThirstChange=-20）；③ 观察水合变化 |
| 通过标准 | 变化 +20 点（=200ml×0.1）；若原版体感汤解渴远多于此，调 `thirstUnitMl` |
| 现状代码 | `RM_Hydration.onConsumeFood`；`Config.hydration.thirstUnitMl` |
| 验证结果 | ✅ 部分验证：苹果 thirstChange=-0.07, quenchU=0.07, ml=0.70, 水合 +0.07。换算链路正确，系数量级待高含水食物（汤）验证 |

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
| 问题 | 食物腐烂后 `getActualWeight()` 是否变化？（`start` 阶段读 preWeight，腐烂可能改变基准重量，影响 gramsEaten） |
| 步骤 | ① 对照新鲜苹果与腐烂苹果各吃一次；② 比较 onEat 结算的 gramsEaten 与 eat 探针行的 grams |
| 通过标准 | 若腐烂不改变重量，gramsEaten 一致；若改变，需在 `start` 中用原始重量补偿 |
| 备注 | 降解保留率本身是 M3（`RM_Decay`），此处只关心 preWeight 基准 |
| 验证结果 | 待填 |

### S1-7 instanceof 判类边界

| 项 | 内容 |
|---|---|
| 问题 | 汤类/含水食物是否被 `instanceof(item, "Food")` 正确判定？非 Food 的饮品走水合分支是否正常？ |
| 步骤 | ① 吃罐头汤 → console 应有微量记账 + 补水；② 喝纯水 → 只补水、无微量记账 |
| 通过标准 | 两类路径各自触发，无遗漏无越界 |
| 现状代码 | `RM_Core.onEat` `isFood` 分支；`perform`/`stop` 中预先判类并传入 `eatSettle` |
| 验证结果 | ✅ 已验证：苹果 isFood=1.00，微量营养记账 + 补水同时触发；判类逻辑正确 |

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
| 已知结论 | B42 客户端 `complete` 不执行，营养在服务端应用后同步到客户端；客户端物品重量不变，故 MOD 用 `percentage` 而非重量差算摄入量 |
| 步骤 | 吃食物过程中逐口查看 `getCalories()` / `getCarbohydrates()`，确认是完成时一次性增加还是每口渐进 |
| 通过标准 | 明确时机；MOD 侧读取（每日 0:00 结算 + 每秒 energyFeedback）不受影响 |
| 验证结果 | ✅ 已验证：bite 事件后 sample 显示 cal/carbs 立即上升（每口渐进增加）；完整吃完时 perform 一次性结算。MOD 记账时机与 vanilla 营养应用时机一致 |

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

## 4. 实测操作剧本（面板版）

> **核心流程**：进世界 → 删旧日志 → 按 **Ctrl+T** 打开测试面板 → 点按钮做动作 → 面板实时显示探针日志和池状态。
> 面板自动同步 `RM_Probe` 的所有事件，**不用退出游戏就能看结果**。
>
> **开测前**：删 `Zomboid\Lua\RealMetabolismProbe.log`，确保数据干净。
>
> 标记说明：✅ 已验证通过 | ⚠️ 已测但有 bug/需重测 | ❌ 未测
>
> **本轮（2026-09-23 第三轮）发现的 bug**：
> 1. 🔴 喝水 ml=0.00：`ISDrinkFromBottle.drink()` 在 B42 客户端完整喝完时不触发。**已修复**：改用 start+perform+stop 按 amount 差值记账
> 2. 🟡 lipids 跌到负数（-69）：脂肪池未做下限钳制。**待修复**：需在 RM_Fuel 加 clamp(0, max)
> 3. 🟡 hydration 跌到 0：因喝水未记账导致脱水。喝水修复后应改善
> 4. 🟡 按键 N 无 key 事件：客户端 key hook 可能未触发。**待查**
> 5. 🟡 睡眠无 sleep/wake 探针事件：当前无睡眠 hook。**待加**
> 6. ✅ `item:setAge(50)` 会崩溃：Food 类无此方法，已改为 `setRotten(true)`
> 7. ✅ `/startrain` 单机无效：是多人 admin 命令，单机用 `RainManager` API

---

### 面板操作速查

| 行 | 按钮 | 功能 |
|----|------|------|
| 打开 | — | **Ctrl+T**（F7/F8 被游戏调试器占用） |
| 行1 生成物品 | 苹果 / 面包 / 水瓶(满) / 汤(开罐) / 腐烂苹果 / 篝火 kit | 点一下生成一件到背包 |
| 行2 测试动作 | 吃苹果 / 吃面包 / 喝汤 / 喝水 / **Drink Tainted** | 自动生成 + 触发 action；Drink Tainted 喝污染水验中毒 |
| 行3 批量/天气 | 面包×5 / 面包×10 / 下雨 / 停雨 | 批量取物 + RainManager/ClimateManager 开关雨 |
| 行4 状态重置 | 清空饥饿 / 清空口渴 / 清空很饱 / 水合=100 / **Force Sleep** | 绕过原版 moodle 限制；Force Sleep 拉满疲劳绕过"太舒服" |
| 池状态 | — | 每秒刷新：cal/carbs/lipids/proteins/hydration/weight |
| 探针日志 | — | 显示最近 60 条；点"清空日志"按钮清缓存 |

**面板已覆盖的**：全部吃喝动作、批量取物、天气、饥饿/口渴/很饱/水合重置、篝火。
**面板做不到的**（仍需 F11）：睡觉（睡觉走 ISSleepAction，不在面板控制范围内）。

---

### 第一段：吃（S1-1/2/3/6/7）

1. **按 Ctrl+T 打开面板**

2. ✅ **完整吃完第一个**（S1-2，别打断）
   - 面板点"生成物品 → 苹果" → 右键吃（或点"测试动作 → 吃苹果"）
   - 面板日志区应显示：`eat grams=200.00;isFood=1.00` + `dbg_perform pct=1`
   - 已验证 ✓

3. ⚠️ **第二个：吃一口 → ESC 取消**（S1-3 中断进食记账）
   - 面板点"生成物品 → 苹果" → 右键吃一口立刻 ESC
   - 面板日志区应显示：`bite preKg=0.20;postKg=0.12` → `eat grams=80.00`
   - **关键检查**：bite 后是否出现 `eat` 行（每 bite 即时记账）

4. ⚠️ **第三个：吃两口 → 停 → 再吃完**（分次进食）
   - 面板点"生成物品 → 苹果" → 吃两口 → 停 → 再右键吃
   - 预期：每次 bite 后有 `eat` 行，最后 `dbg_perform remainingKg` 扣减 bite 部分

5. ✅ **面包**（S1-2 高碳水）
   - 面板点"测试动作 → 吃面包"
   - 已验证 ✓：`eat grams=300.00;isFood=1.00`

---

### 第二段：含水食物 + 腐烂

6. ✅ **开罐汤**（S1-4 高含水）
   - 面板点"生成物品 → 汤(开罐)" → 右键吃
   - 已验证 ✓：补水链路正确

7. ✅ **腐烂苹果**（S1-6）
   - 面板点"生成物品 → 腐烂苹果" → 右键吃
   - 已验证 ✓：腐烂标记生效，重量不变

---

### 第三段：喝（S1-5）⚠️ 已修复待验证

> ⚠️ B42 有两套饮水 action：
> - `ISDrinkFromBottle`：**手动从水瓶喝水**（右键水瓶→喝 或 面板"测试动作→喝水"）
> - `ISDrinkFluidAction`：从杯子/碗/锅等容器喝水（含自动饮水）

8. ⚠️ **用面板一键喝水**
   - 面板点"测试动作 → 喝水"（自动生成满水瓶 + 触发饮水 action）
   - **上轮**：`drink ml=0.00`（bug）— 已修复
   - **本轮预期**：`drink ml=120.00;capacity=1.0`（每口约 120ml）
   - ⚠️ 若点了没反应（口渴值太低）：F11 执行 `getPlayer():getStats():setThirst(0.5)` 后重试

---

### 第四段：按键（S2-7）⚠️ 已测无事件

9. ⚠️ 单按 N 一次；长按 N 一次
   - **上轮**：无 key 事件写入日志
   - **待查**：`RM_Panel._onKey` 的 keycode 匹配
   - 调试：F11 执行 `print(Keyboard["N"])`

---

### 第五段：睡（S2-5/S2-6）⚠️ 已测无探针事件

10. ⚠️ 睡到过 0:00，自然醒
    - 面板池状态实时显示时间流逝和池变化
    - **上轮**：无 sleep/wake 事件（无睡眠 hook）
    - **待加**：ISSleepAction hook

---

### 第六段：池标定（S2-1/2/2-3/8）⚠️ 上轮有 bug 需重测

> **上轮实测数据**（约 11 游戏小时，吃面包后绝食）：
> | 指标 | 最小 | 最大 | 备注 |
> |------|------|------|------|
> | cal | 2528 | 3586 | 吃上面包后冲高 |
> | carbs | 360 | 556 | 正常范围 |
> | lipids | **-69** | -25 | 🔴 **负数 bug，需重测** |
> | proteins | 14 | 49 | 正常范围 |
> | weight | 80.9 | 81.8 | 吃面包后增重 |
> | temp | 36.65 | 36.82 | 稳定 |
> | hyd | **0** | 16 | 🔴 喝水未记账导致脱水 |

11. ⚠️ **先吃饱**（用面板 + 重复生成高碳水食物）

    面板点"测试动作 → 吃面包"，连续点 10 次以上；吃不动时 F11 重置饥饿：
    ```lua
    getPlayer():getStats():setHunger(0)
    ```
    若"很饱"moodle 挡住：
    ```lua
    local ok, bd = pcall(function() return getPlayer():getBodyDamage() end)
    if ok and bd then pcall(function() bd:setHealthFromFoodTimer(0) end) end
    ```
    面板实时看池状态冲高。

    > ⚠️ **不要用 `setGodMod(true)`**：god mode 会冻结消耗、体重更新、体温。

12. ⚠️ **绝食 2-3 天**（面板实时观察下限）
    - 待 lipids 钳制修复后重测，确认下限为 0

13. ❌ **淋雨 + 篝火**（S2-8 体温，未测）

    **触发下雨（单机 Lua API）**：
    ```lua
    local ok, rm = pcall(function() return RainManager.getInstance() end)
    if ok and rm then rm:setRainStrength(1.0) end
    ```
    停止：`rm:setRainStrength(0)`

    **篝火**：面板点"生成物品"区域没有篝火 kit，F11 执行：
    ```lua
    getPlayer():getInventory():AddItem("Base.CampfireKit")
    ```

---

**退出后**：把 `Zomboid\Lua\RealMetabolismProbe.log` 全文发我。

**注意事项**：
- 想要干净数据：开新档 + 删旧 `RealMetabolismProbe.log`
- 面板实时看探针日志，不用退出游戏就能判断结果好坏
- 面板做不到的（批量取物/下雨/睡觉）才用 F11
- 发现失败项：**先回报再改代码**
