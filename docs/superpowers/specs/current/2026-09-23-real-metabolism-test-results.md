# Real Metabolism — S1/S2 实测结果记录

- 日期：2026-09-23
- 游戏版本：Project Zomboid Build 42
- 测试方式：单机模式，测试面板（Ctrl+T）+ 探针自动采集
- 探针日志：`Zomboid\Lua\RealMetabolismProbe.log`

---

## 一、测试环境

| 项 | 值 |
|---|---|
| 角色初始体重 | 80.00 kg |
| 初始热量池 | ~1266 |
| 初始碳水池 | ~124 |
| 初始水合 | ~97 |
| 初始体温 | 37.00 |
| 姿态 | rest（静止） |

---

## 二、已验证通过项 ✅

### 1. 完整吃苹果（S1-2）

| 检查项 | 结果 |
|--------|------|
| 摄入量 | ✅ grams=200.00（preW=0.2kg × pct=1） |
| 食物判类 | ✅ isFood=1.00 |
| 补水计算 | ✅ thirstChange=-0.07 → ml=0.70 |
| 崩溃 | ✅ 无报错 |

### 2. 完整吃面包（S1-2）

| 检查项 | 结果 |
|--------|------|
| 摄入量 | ✅ grams=300.00 |
| 碳水冲高 | ✅ carbs 上升 |

### 3. 中断进食（S1-3）

面包 bite 测试：
```
bite preKg=0.30 postKg=0.18
eat grams=117.76
```
- ✅ bite 即时记账（每口吃的量正确记录）
- ✅ 不依赖 stop 回调（B42 forceCancel 空方法问题已绕过）

### 4. 分次进食（S1-3）

苹果分两次吃完：
```
eat grams=100.00 (pct=0.5)
eat grams=100.00 (pct=1)
```
- ✅ 两口各 100g，总 200g，无重复记账

### 5. 喝水（S1-5）

```
drink ml=120.00 capacity=1.00 preRatio=1.00 postRatio=0.88
```
- ✅ ml=120.00 正确（每口约 120ml）
- ✅ hyd 从 42.42 → 54.34（补水生效）
- ✅ 不崩溃（修复了 SyncPlayerStatsPacket NPE）

### 6. 汤（S1-4/S1-7）

- ✅ grams=800.00（修复了 percentage 归一化，之前是 80000）
- ✅ 补水链路正确

### 7. 腐烂苹果（S1-6）

- ✅ 腐烂标记生效（setRotten(true)）
- ✅ 重量不变（grams=200.00）

### 8. 按键 N（S2-7）

- ✅ 事件触发
- ✅ keycode 反向映射（49 → N）

### 9. 下雨/停雨

- ✅ 单机生效（ClimateFloat setAdminValue 方式）
- ✅ 不崩溃（修复了 Java null 问题）

### 10. 体温（淋雨）（S2-8）

- ✅ 淋雨后 temp 下降
- ✅ 探针正常记录

### 11. 池上下限（S2-1/S2-3）

源码确认（官方 bug 报告），无需实测：

| 营养池 | 上限 | 下限 |
|--------|------|------|
| calories | 3700 | — |
| carbohydrates | 1000 | -500 |
| lipids | 1000 | -500 |
| proteins | 1000 | -500 |

- ✅ 日志验证：cal 冲到 3700 不再涨，carbs 冲到 1000 不再涨
- ✅ 设计决策：保持原版下限 -500，不做 clamp

### 12. 睡眠时间消耗

5.5 小时睡眠数据：
| 指标 | 睡前 | 醒后 | 每小时消耗 |
|------|------|------|-----------|
| cal | 3018 | 2898 | -22 |
| carbs | 853 | 783 | -13 |
| lipids | 70 | 47 | -4 |
| hyd | 42.6 | 28.6 | -2.5 |
| weight | 81.6 | 82.1 | +0.1 |

- ✅ 无异常刷屏
- ✅ 累加器正常处理时间跳变

---

## 三、待验证项（已完成 ✅）

### 睡眠探针（S2-5/S2-6）

- ✅ ISSleepAction → ISGetOnBedAction 已修正
- ✅ 面板新增 **Force Sleep** 按钮
- ✅ 实现方式：直接调用 `player:setAsleep(true)` + `setForceWakeUpTime()` + `getSleepingEvent():setPlayerFallAsleep()`，照搬 `ISSleepDialog.onClick` YES 分支，**绕过 Java 层 canSleep 检查**（"太舒服了"判断在 Java 层，Lua 改 fatigue 绕不过去）
- ✅ 探针验证：`force_sleep,stat=1.00;set=1.00;readback=1.00;asleep=1.00` —— fatigue 设到 1.0 且成功入睡

### 篝火体温回升（S2-8）

- ✅ 淋雨下降已验证
- ✅ 结论：**B42 原版热源对体温影响很弱**（点燃房子后体温上升不如跑步快）
- 📌 参考 mod：**Realistic Temperature Mod**（Workshop 3600401184，作者 RedChili）——无公开 GitHub 源码，mod 文件可从 modsfire 下载。该 mod **禁用原版 Thermoregulator**，自建体温模拟，篝火/壁炉/烤炉/烤箱/车载暖气均纳入热源，站在热源旁明显变暖。M2 环境系统可参考其热源建模思路。

### 污染水中毒

- ✅ 决策：**不重复实现**，交由 B42 原生流体系统处理
- 原因：`TaintedWater` 流体定义自带 `Poison { maxEffect=Medium, minAmount=1.0, diluteRatio=0.2 }` 块，Java 层自动计算中毒效果。mod 手动设值会与原生叠加或冲突。
- ✅ 面板保留 **Drink Tainted** 按钮（生成装满 TaintedWater 的水瓶并喝下），用于验证原生中毒机制

---

## 四、修复的 Bug 清单

| # | Bug | 原因 | 修复 | 状态 |
|---|-----|------|------|------|
| 1 | 吃完食物崩溃 | origPerform 消耗 item 后访问触发 Java 异常 | 所有 item 访问移到 origPerform 前 | ✅ |
| 2 | isFood=0.00 | eatSettle 漏传 isFood 参数 | 预先判类并传入 | ✅ |
| 3 | 中断进食漏记 | B42 forceCancel 空方法，不调 stop | eat hook 每 bite 即时记账 | ✅ |
| 4 | getFullName() 崩溃 | B42 Food 无此方法 | 改用 getFullType() | ✅ |
| 5 | isMoving() 崩溃 | B42 改名 | 改用 isPlayerMoving() | ✅ |
| 6 | postKg=nan | 物品消耗后 weight 返回 NaN | NaN 检测 | ✅ |
| 7 | 喝水 ml=0.00 | B42 drink() 不触发 | start 记 preAmt + amount 差值计算 | ✅ |
| 8 | 喝水疯狂刷日志 | 浮点精度误判 | ml>1 阈值 + __rmDrinkSettled 防重复 | ✅ |
| 9 | 喝水崩溃 | SyncPlayerStatsPacket.Stat_Thirst 为 Java null | 检查 ~= nil 后再调用 | ✅ |
| 10 | 喝水 perform 提前结算 | perform 在 drink 前执行 | 水量未变时不清 preAmt | ✅ |
| 11 | 汤 grams=80000 | percentage 传了 100 | 归一化 pct>1 时 /100 | ✅ |
| 12 | setAge(50) 崩溃 | Food 无 setAge 方法 | 改用 setRotten(true) | ✅ |
| 13 | /startrain 无效 | 多人命令，单机无效 | ClimateFloat setAdminValue | ✅ |
| 14 | Hunger=0 报错 | Stats 无 setHunger 方法 | 改用 set(CharacterStat.HUNGER, 0) | ✅ |
| 15 | 面板中文乱码 | UIFont 不支持中文 | 全部英文标签 | ✅ |
| 16 | ISLabel 宽度问题 | setTitle 后宽度不扩展 | 固定宽度 640px | ✅ |
| 17 | F7/F8 面板打不开 | 被 PZ 调试器占用 | 改用 Ctrl+T | ✅ |
| 18 | 按键显示 code=49 | 只记数字 keycode | Keyboard 表反向映射 | ✅ |
| 19 | 下雨 Java null | RainManager.getInstance() 返回 null | pcall 整链 + ClimateManager fallback | ✅ |
| 20 | Force Sleep `setFatigue` 报错 | B42 Stats 无 `setFatigue()` 快捷方法 | 改用 `stats:set(CharacterStat.FATIGUE, 1.0)` | ✅ |
| 21 | Force Sleep 疲劳设了还是睡不着 | "太舒服了"阻断在 Java 层 canSleep，Lua 改 fatigue 绕不过 | 直接调 `player:setAsleep(true)`（照搬 ISSleepDialog.onClick） | ✅ |
| 22 | Drink Tainted `setAmount` 报错 | B42 FluidContainer 无 `setAmount()` | 改用 `fc:adjustAmount(0)` | ✅ |
| 23 | `setPain`/`getPoisonLevel` 报错 | B42 把 PAIN/POISON/SICKNESS 从 BodyDamage 移到 Stats/CharacterStat | 用 `stats:set(CharacterStat.PAIN/POISON/SICKNESS, value)` | ✅ |
| 24 | 设了 POISON 没 Sick moodle | B42 食物中毒用 `CharacterStat.FOOD_SICKNESS`，不是 POISON | 删除 mod hook，交由 B42 原生 Poison 块处理 | ✅ |
| 25 | pcall 抓不住 Java 异常 | Kahlua 的 pcall 只捕获 Lua 错误，Java 层异常直接穿透 | 调用 Java 方法前必须在 Lua 层判空（`if x ~= nil then`） | ✅ |
| 26 | `setTextColor` 报错（按 N 崩溃） | B42 ISButton/ISLabel 无 `setTextColor` 方法 | 新增 `_setTextColor` 辅助：优先调方法，不存在则直接写 `textColor` 属性表 | ✅ |
| 27 | 折线图 `drawLine` 报 expected Texture | B42 `ISUIElement:drawLine` 需传 Texture 参数，传数字崩溃 | 网格线改用 1px `drawRect`；数据线改用 2×2 散点方块 | ✅ |
| 28 | 标题显示 `RM_UI_Title` 原文 | `getText` 无翻译时返回 key 字符串，正则 `%u+` 不匹配混合大小写 | 改用 `sub(1,6)=="RM_UI_"` 前缀判断回退为 "Metabolism" | ✅ |
| 29 | 开关键冲突 | N=God Mode，L=技能页，F7 不响应 | 查 `keysB42.ini` 确认 A-Z/F1-F6 全占用，改用 **F10** | ✅ |
| 30 | 切换页时三页内容穿透 | B42 `setVisible(false)` 不阻止子元素渲染 | 非激活页 `setY(-9999)` 移到屏外 + 不透明背景（a=1.0）双保险 | ✅ |
| 31 | 宏量文本跑到屏幕外 | ISLabel 在 B42 定位偏移，脱离父容器 | 改用自定义 `ISUIElement:render()` 内 `drawText`，定位由父容器控制 | ✅ |
| 32 | 面板不能拖动 | 标题栏无鼠标事件 | 标题栏加 `onMouseDown/Move/Up` 拖动逻辑，移动父面板 | ✅ |

---

## 五、测试这些有什么用？

### 直接回答：这些测试是为了确保 MOD 不会崩溃、数据准确、机制符合预期

| 测试项 | 不测的后果 |
|--------|-----------|
| 吃/喝记账 | 玩家吃了东西但营养没加上，或者加了两倍，导致平衡全乱 |
| 中断/分次进食 | 玩家咬一口取消，营养没记上；或者分次吃重复记账 |
| 喝水 ml | 喝水不补水，玩家会脱水死 |
| 腐烂食物 | 腐烂食物重量变了，导致摄入量算错 |
| 池上下限 | 不知道吃多少算"饱"，平衡参数全是猜的 |
| 睡眠消耗 | 睡一觉醒来直接饿死/渴死 |
| 体温 | 不知道淋雨/烤火的体温变化范围，环境阈值瞎设 |
| 按键 | 面板打不开，玩家无法操作 UI |

### 更深层的意义

1. **崩溃零容忍**：PZ 单机下 Java 异常 pcall 抓不住，一个未防御的调用就会让整个 MOD 失效。测试每一条吃喝路径都是为了找出这些隐藏的崩溃点。

2. **数据驱动平衡**：cal/carbs/lipids 的上下限、每小时消耗量、睡眠代谢率——这些是能量评分和燃料系统的输入。不实测就只能猜，猜出来的数值要么太容易要么太难。

3. **B42 适配验证**：B42 改了很多 API（getFullName→getFullType、isMoving→isPlayerMoving、complete 不执行、drink 不触发）。测试就是验证这些适配是否真的生效，而不是"代码看起来对"。

4. **发布前的安全网**：这个 MOD 改了吃喝核心逻辑，任何一个记账错误都会影响所有玩家。测试通过才能确保发布后不会因为"吃了不饱"或"喝水还渴"被差评。

### 当前状态

核心吃喝逻辑、记账、补水、天气、按键、睡眠、体温、污染水全部验证通过。**S7 NeatUI UI 框架实机验证通过**，M1 代谢核心 + UI 框架全部完成。

**M1 已完成模块**：
- 代谢核心：`RM_Core` / `RM_DataLayer` / `RM_Scoring` / `RM_History`
- 燃料系统：`RM_Fuel`（底物切换、瞬时动作、能量反馈）
- 水合池：`RM_Hydration`
- UI 框架：`RM_UIAdapter`（NeatUI 隔离层）/ `RM_Panel`（三页代谢面板）/ `RM_StatusIcons`（角落状态图标）/ `RM_Theme`（深色主题）
- 探针：`RM_Probe`

**B42 API 适配关键经验**：
1. `Stats` 类只有 `set(CharacterStat, value)` / `get(CharacterStat)`，无 `setHunger`/`setFatigue`/`setStress` 等快捷方法
2. `BodyDamage` 移除了 `setPain`/`getPain`/`getPoisonLevel`/`setPoisonLevel`，PAIN/POISON/SICKNESS/FOOD_SICKNESS 全在 `Stats`/`CharacterStat`
3. `FluidContainer` 无 `setAmount()`，用 `adjustAmount()`
4. Kahlua `pcall` 抓不住 Java 异常，调用 Java 方法前必须 Lua 层判空
5. 睡眠"太舒服了"检查在 Java 层，绕过需直接调 `player:setAsleep(true)`
6. `ISUIElement:drawLine` 需传 `Texture` 参数，不能传数字；画线用 1px `drawRect` 替代
7. `ISButton`/`ISLabel` 无 `setTextColor` 方法，直接写 `textColor` 属性表
8. `ISPanel:setVisible(false)` 不阻止子元素渲染，隐藏页需配合 `setY(-9999)` 屏外位移
9. `ISLabel` 在 B42 有定位偏移问题，长文本建议用自定义 `ISUIElement:render()` + `drawText`

---

## 六、S7 NeatUI 实机验证（2026-09-24）

### 验证项

| # | 检查项 | 结果 |
|---|--------|------|
| 1 | NeatUI 依赖检测（`RM.UI.checkDependency`） | ✅ 检测通过，UI 适配器激活 |
| 2 | 面板打开（F10 键） | ✅ 面板弹出，无崩溃 |
| 3 | 面板关闭（X 按钮 / F10 再按） | ✅ 正常关闭 |
| 4 | 面板拖动 | ✅ 按住标题栏可移动 |
| 5 | 标签页切换（Status/Trend/Health） | ✅ 切换正常，无内容穿透 |
| 6 | Status 页 — 8 微量营养素进度条 | ✅ label \| bar \| value% 三栏布局，颜色分档 |
| 7 | Status 页 — 水合/能量/负荷条 | ✅ 正确显示百分比 |
| 8 | Status 页 — 宏量数值 | ✅ cal/carbs/lipids/protein/weight 正常显示 |
| 9 | Trend 页 — 折线图 | ✅ 散点趋势图渲染（drawLine 已规避） |
| 10 | Health 页 | ✅ 占位文案，无崩溃 |
| 11 | 角落状态图标 | ✅ 右下角 28×28 色块图标 |
| 12 | 面板拖动后数据刷新 | ✅ 250ms 节流刷新正常 |

### UI 设计定稿

- **主题**：深灰蓝底（`#171A1F`）+ 青蓝强调色，档位色 青绿/琥珀/红/紫
- **布局**：标签页（Status/Trend/Health）+ 分区标题 + 三栏进度条（名称\|条\|数值）
- **开关键**：**F10**（A-Z 全占用，F1-F6 绑定倍速/暂停，F7 不响应）
- **标题**："Metabolism"（getText 无翻译时自动回退）

### 已知遗留

- 折线图为散点样式（B42 drawLine 需 Texture），后续可用 NeatUI `NeatTool.drawLine` 升级为实线
- 微量营养素标签目前用英文 key（sodium/potassium 等），待翻译表补充后切换

---

## 七、S7 ② 饮品药效数据验证（2026-09-24）

> 数据源：本地反编译源码 `Zedema\.api-cache\sources\42.20\out\source\` + 游戏脚本 `media\scripts\generated\{items,fluids*.txt}` + 官方 JavaDoc `https://albion.codeberg.page/PZ-JavaDocs/`

### 7.1 B42 饮品架构（源码结论）

B42 把饮品分成两条完全独立的路径：

| 路径 | 物品类型 | 触发方法 | 醉酒入口 |
|------|---------|---------|---------|
| **Food 类** | `ItemType = base:food`（food.txt） | `BodyDamage.Eat` | `if food.isAlcoholic()` → `JustDrankBooze(food, pct)` |
| **FluidContainer 类** | `ItemType = base:normal` + `component FluidContainer`（normal.txt） | `IsoGameCharacter.DrinkFluid` | `if consume.getAlcohol() > 0` → `JustDrankBoozeFluid(alcohol)` |

酒精饮品（啤酒/葡萄酒/烈酒）全部是 **FluidContainer 类**，酒精含量定义在 **Fluid** 上，不在物品字段里。

### 7.2 原生字段盘点

| 字段 | 原生是否存在 | 位置 | 说明 |
|------|------------|------|------|
| **alcohol** | ✅ | Fluid 的 `Properties.alcohol`（0.0–1.0） | 酒精体积分数，`DrinkFluid` 自动读取并触发醉酒 |
| **Alcoholic**（布尔） | ✅ 仅绷带用 | 物品脚本 `Alcoholic = true` | 仅 `AlcoholBandage`/`AlcoholRippedSheets`，饮品**不用** |
| **alcoholPower** | ⚠️ 存在未使用 | 物品脚本 `AlcoholPower = x` | `getAlcoholPower()` 存在，醉酒逻辑**不调用** |
| **caffeine** | ❌ **不存在** | — | 咖啡/茶靠 `fatigueChange`（负值=减疲劳）实现提神 |
| **sugar** | ❌ **不存在** | — | 糖含量体现在 `Carbohydrates` 字段 |

**原生流体酒精值**（`fluids_Alcoholic.txt`）：

| Fluid | alcohol | Calories | Carbs |
|-------|---------|----------|-------|
| Beer | 0.05 | 500 | 36 |
| Cider | 0.04 | 190 | 8 |
| Mead | 0.06 | 1220 | 0 |
| Wine / Champagne | 0.12 | 481 / 581 | 0 / 25 |
| Sherry / Vermouth | 0.15 | 1520 / 1110 | 69 / 33 |
| Port | 0.16 | 1570 | 129 |
| CoffeeLiqueur | 0.20 | 3260 | 21 |
| Whiskey / Vodka / Rum / Gin / Tequila / Scotch / Brandy / Curacao | 0.40 | 2100–3260 | 0–236 |

**非酒精饮品流体**（`fluids_Beverages.txt`）：Water、Cola、SodaPop、SodaLime、JuiceOrange、JuiceApple、Coffee、Tea、CowMilk 等。Coffee `fatigueChange=-10`、Tea `fatigueChange=-5`、Cola `fatigueChange=-2`。

### 7.3 原生醉酒机制（BodyDamage.java）

**`JustDrankBoozeFluid(float alcohol)`**（流体路径，实际使用）：
```java
del = alcohol;
if (hunger > 0.8) del *= 1.1;        // 饿肚子醉酒更快
else if (hunger > 0.6) del *= 1.25;
stats.add(INTOXICATION, 400 * del);  // drunkIncreaseValue=400
// 附带：安眠药 0.02*alcohol、抗抑郁 0.4*alcohol、β阻滞剂 0.2*alcohol、止痛 0.2*alcohol
```

**`JustDrankBooze(Food, pct)`**（固体路径，基本不用）：仅当 `food.isAlcoholic()` 为 true 时触发（只有绷带满足，饮品不触发）；名字含 "beer" 或 `hasTag(LOW_ALCOHOL)` → `del *= 0.25`。

**衰减与效果**：每 tick `remove(INTOXICATION, 0.0042 * GameTime.multiplier)`；`drunkMod = 1 - 0.5 * (INTOXICATION/100)` 作用于不适度。

> **关键结论**：喝瓶装酒时 `DrinkFluid` **已自动调用 `JustDrankBoozeFluid`**，MOD 不需要也不应重复触发。MOD 的 `alcoholGrams` 仅用于**营养侧**（7 kcal/g 空热量 + 训练恢复打折 + MOD 侧醉酒图标判定）。

### 7.4 MOD 现有 BEVERAGES 表校验（RM_DataLayer.lua）

原表 14 条目中 **8 条物品 ID 在 B42 中不存在**：

| MOD 原 ID | 状态 | B42 实际 ID |
|----------|------|------------|
| `Base.WaterBottle` | ✅ | — |
| `Base.BeerBottle` | ✅ | — |
| `Base.BeerCan` | ✅ | — |
| `Base.Milk` | ✅ | normal.txt（利乐包/奶粉） |
| `Base.WineBottle` | ❌ | `Base.Wine` / `Base.Wine2` / `Base.WineOpen` |
| `Base.WhiskeyBottle` | ❌ | `Base.Whiskey` |
| `Base.VodkaBottle` | ❌ | `Base.Vodka` |
| `Base.RumBottle` | ❌ | `Base.Rum` |
| `Base.ColaBottle` | ❌ | 可乐是 **Fluid**（Cola），装在瓶/罐 |
| `Base.OrangeSoda` | ❌ | Fluid `SodaPop` |
| `Base.LemonSoda` | ❌ | Fluid `SodaLime` |
| `Base.OrangeJuice` | ❌ | Fluid `JuiceOrange` |
| `Base.AppleJuice` | ❌ | Fluid `JuiceApple` |
| `Base.EvaporatedMilk` | ❌ | 无对应物品 |

### 7.5 对设计的修订

1. **酒精不触发 MOD 醉酒** — 原生 `DrinkFluid` 已处理；MOD `alcoholGrams` 仅用于空热量记账 + 训练恢复 + 图标判定。
2. **咖啡因需 MOD 自建计时** — 原生无 caffeine 字段，靠 `fatigueChange` 提神；MOD 自建 `caffeineUntil`/`caffeineReboundUntil`。
3. **糖走原生 Carbohydrates** — Fluid 的 `Carbohydrates` 由 `DrinkFluid` 自动写入原生营养池，MOD 不重复记宏量。
4. **饮品表按 Fluid 类型建模** — B42 "喝什么"由 Fluid 决定，同一瓶可装不同流体。`resolveBeverage` 增加 `getFluidContainer():getPrimaryFluid():getFluidType()` 分支。

### 7.6 已实施修复

- **方案 A**：`BEVERAGES` 表物品 ID 全部修正为 B42 真实 ID，补全 Gin/Tequila/Champagne/Cider 等
- **方案 B**：`resolveBeverage` 重构为 Fluid 类型优先 → 物品 ID → 未命中告警（无关键词兜底）
- **方案 C**：`ISDrinkFluidAction` hook 从 `updateEat` 改为 `start`(记起始比例) + `perform`/`stop`(按差值算 ml)，解决单机 `updateEat` 不被调用的问题
- **方案 D**：未收录饮品告警同步写入探针日志（`bev_unknown` 事件），测试面板直接可见

### 7.7 实机验证结果（2026-09-24）

| 测试项 | 路径 | 结果 | 探针关键行 |
|--------|------|------|-----------|
| 右键喝啤酒（1000ml） | `ISDrinkFluidAction` | ✅ ml=1000，水合≈0 | `src=FluidAction;startRatio=1;curRatio=0` |
| 右键喝半瓶（500ml） | `ISDrinkFluidAction` | ✅ ml=500，postRatio=0.5 | `startRatio=1;curRatio=0.5` |
| 右键喝水（1000ml） | `ISDrinkFluidAction` | ✅ 水合 80.5→99.96（+100 clamp） | `postRatio=0` |
| 右键喝漂白剂（1000ml） | `ISDrinkFluidAction` | ✅ 未收录→`bev_unknown`，水合不增 | `bev_unknown,fullType=Base.Bleach;name=漂白剂` |
| 测试面板 Drink Water | `ISDrinkFromBottle` | ✅ ml=120，回归正常 | `dbg_drink_start`(无 src=FluidAction) |

**关键架构结论**：
- B42 单机 `isClient()=true`，`ISDrinkFluidAction.update()` 内 `if not isClient() then updateEat() end` 不执行，饮水由 Java `DrinkFluid` 异步完成。
- 必须在 `start` 记录 `__rmStartRatio`，在 `perform`/`stop` 按 `(startRatio - curRatio) × capacity × 1000` 计算饮水量。
- 未收录饮品（如 Bleach）`resolveBeverage` 返回 nil → `onDrink` 不补水合、不记营养，仅写 `bev_unknown` 探针告警。

---

### 剩余 Spike 0 项

| # | 项 | 状态 | 归属 |
|---|---|---|---|
| S7 ② | 饮品药效数据验证（酒精/糖/咖啡因字段盘点 + 原生醉酒机制） | ✅ 已验证 | M2 前置 |
| S8 | 环境数据源（天气湿度/温度/湿身/日照 API） | ❌ 未做 | M2 前置 |
| S9 | ModData schemaVersion / MP 同步预留 | ⚠️ 部分（schemaVersion 已有，MP 仅预留） | 发布前 |

### 下一步

S8 环境数据验证 → 启动 M2（`RM_Environment` / `RM_Beverages` / `RM_Training`）。
