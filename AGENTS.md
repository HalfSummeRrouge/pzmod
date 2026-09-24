# pzmod — Project Zomboid B42 Mod 工作区

## 项目类型

Project Zomboid **Build 42** 单机 MOD 开发工作区，当前主项目为 **Real Metabolism（真实代谢）**。

## 主项目：Real Metabolism

一个 MOD，三个平级子系统——**营养 / 运动 / 环境**——共享一个"代谢核心"，把角色的身体做成一套真实的生理仿真。

- MOD ID：`RealMetabolism`
- 硬依赖：**NeatUI Framework [B42]**（Workshop ID 3508537032）
- 当前里程碑：M1 已完成，M2（运动与环境）待启动

## 目录结构

```
pzmod/
├── RealMetabolism/
│   └── 42/
│       ├── mod.info                    -- require NeatUI_Framework
│       └── media/lua/
│           ├── shared/                  -- 纯数据/纯函数（启动阶段加载）
│           │   ├── RM_Config.lua        -- 全部参数集中配置
│           │   ├── RM_DataLayer.lua     -- 微量表/饮品表/降解折算
│           │   ├── RM_History.lua       -- 7天历史与每日结算
│           │   ├── RM_Scoring.lua       -- 纯函数：评分/归一化/燃料分配
│           │   ├── RM_Probe.lua         -- 探针日志
│           │   └── Translate/{EN,CN}/    -- 翻译
│           ├── server/                  -- 状态机/事件驱动（进入世界时加载）
│           │   ├── RM_Core.lua          -- 编排/事件挂载
│           │   ├── RM_Fuel.lua          -- 底物燃料台账
│           │   ├── RM_Hydration.lua     -- 水合池
│           │   ├── RM_Environment.lua   -- 温湿度/湿身/日照（M2）
│           │   ├── RM_Beverages.lua     -- 饮品药效（M2）
│           │   ├── RM_Training.lua      -- 训练恢复（M2）
│           │   ├── RM_Decay.lua         -- 食物降解（M3）
│           │   └── RM_Diseases.lua      -- 7种缺乏病（M3）
│           └── client/                  -- UI（启动阶段加载）
│               ├── RM_UIAdapter.lua     -- NeatUI 隔离层（唯一接触 NeatUI）
│               ├── RM_Panel.lua         -- 代谢面板
│               ├── RM_StatusIcons.lua   -- 角落状态图标
│               ├── RM_Theme.lua         -- 主题令牌
│               └── RM_TestPanel.lua     -- 调试测试面板（Ctrl+T）
├── docs/superpowers/specs/current/      -- 设计/技术/测试文档
├── tests/                               -- 离线单元测试（Lua 5.1）
├── tools/                               -- 食物表提取脚本
└── run_tests.js                         -- Fengari 测试运行器
```

## 技术栈与运行环境

| 项 | 说明 |
|---|---|
| 脚本语言 | Lua **5.1 语法**，运行时 **Kahlua**（非 LuaJIT）；禁用 bit/jit/goto |
| Java 互操作 | 静态方法 `.`、实例方法 `:`；全程不直接读实例字段，只用 getter/setter |
| UI 框架 | NeatUI Framework [B42]，经 `RM_UIAdapter.lua` 隔离 |
| 网络模式 | 单机优先；写入函数预留 `isAuthority` 开关 |

## lua 三类文件夹加载时机（B42）

| 文件夹 | 单人 | 多人客户端 | 多人服务器 |
|---|---|---|---|
| `client` | ✅ 启动阶段 | ✅ 启动阶段 | ❌ |
| `server` | ✅ 进入世界时 | ✅ 进入世界时 | ✅ 读档时 |
| `shared` | ✅ 启动阶段 | ✅ 启动阶段 | ✅ 读档时 |

**硬约束**：
1. client 可引用 shared 的 `RM` 表，反向禁止。
2. server 文件在单机可用但**不可在启动阶段被引用**；纯函数/常量必须放 shared。
3. NeatUI 必须先于本 MOD 加载。

## 关键路径

- **开发目录**：`%UserProfile%\Zomboid\mods\RealMetabolism\`
- **游戏脚本/资源**：`Steam/steamapps/common/ProjectZomboid/media/`
- **反编译 Java 源码**：`d:\project\Zedema\.api-cache\sources\42.20\out\source\zombie\`
- **游戏脚本（物品/流体定义）**：`e:\Steam\steamapps\common\ProjectZomboid\media\scripts\generated\`
  - 物品：`items/food.txt`、`items/normal.txt`
  - 流体：`fluids.txt`、`fluids_Beverages.txt`、`fluids_Alcoholic.txt`
- **控制台日志**：`%UserProfile%\Zomboid\console.txt`
- **探针日志**：`%UserProfile%\Zomboid\Lua\RealMetabolismProbe.log`

## API 参考资源（信任顺序）

1. **本地反编译源码**（`Zedema\.api-cache\sources\42.20\`）— 最可靠，查内部行为
2. **官方 JavaDoc**：https://albion.codeberg.page/PZ-JavaDocs/（第三方镜像，按包导航）
3. **官方**：https://projectzomboid.com/modding/
4. **PZWiki**：https://pzwiki.net/wiki/Modding

> **前置优先查源码/文档**：任何机制、字段、API、物品ID、流体属性等前置准备，能通过查源码/脚本/JavaDoc 确认的，一律先查清楚再动手/测试，减少实机测试成本。

## 开发规范（摘自技术文档 §20）

### 总则

| 原则 | 含义 |
|---|---|
| **最小实现** | 只做当前里程碑定义的功能。不写前瞻代码、预留参数、死开关 |
| **复用优先** | 原生机制 > MOD 内已有模块 > 新代码 |
| **只读边界** | 不硬写原生池/倍率；燃料只记 MOD 台账；`setMetabolicTarget`/`setSimulationMultiplier` 仅环境子系统产热调制用 |
| **解耦** | 模块间只经 `RM.*` 公开函数通信；NeatUI 只出现在 `RM_UIAdapter.lua`；UI 零写入 |
| **因果可验证** | 每个效果都能回答"身体发生了什么"；所有平衡数值进 Config |

### 命名规范

| 对象 | 规则 | 示例 |
|---|---|---|
| 全局表 | `RM`（唯一） | `RM.Config` |
| 公开函数 | 驼峰、动词开头 | `RM.Data.addMicro` |
| 内部函数 | 下划线前缀 | `RM.Core._accumulate` |
| 幂等/去重标记 | `__rm` 前缀 | `item.__rmHooked` |
| 持久化键 | schema 字段名**冻结不改**，只加不删 | `micro` / `hydration` |

### Hook 规范

- **包装而非替换**：存原链 → 幂等标记 → pcall MOD 逻辑 → 原链透传
- 不独占挂点，天然成链兼容
- 与原生重复的效果（酒精 INTOXICATION 等）触发前判重
- Hook 点集中登记在 `RM_Core`，禁止各文件私自包装

### 性能红线

- `OnPlayerUpdate` 路径只读、不建闭包、不拼字符串；1s 节流
- 每秒级逻辑一律挂统一累加器 `tickSecond`
- 查表 O(1)；历史/折线定长；UI 不可见即停刷
- 目标：平均 <0.2ms/帧

### 错误处理

1. 原生调用一律判空（Java null ≠ Lua nil）
2. 食物先 `instanceof(item, "Food")`；字符串字段 tostring 兜底
3. hook 一律"包装+pcall+原链透传"，MOD 错误不阻断原版动作
4. Kahlua `pcall` 抓不住 Java 异常，调用 Java 方法前必须 Lua 层判空
5. 写入前 clamp，除零返回中性 0，NaN 防御（`w == w` 检测）

### 测试与提交

- 纯函数必须可离线单测（`node run_tests.js`）
- 涉及存档的改动必须过往返测试（操作→退主菜单→读档比对）
- **设计优先**：先按设计定稿实现主路径，禁止预先写降级/兜底分支
- **降级前置审批**：放弃主路径改用降级替代前，必须先询问用户确认
- 提交粒度：一个功能点一个 commit；schema 破坏性改动单独 commit

## 禁止清单

| # | 禁止项 |
|---|---|
| 1 | Lua 5.1 之外特性（bit/jit/goto）；直接读实例字段 |
| 2 | 双重计算：宏量/热量/醉酒重复记账 |
| 3 | 保存"已扣减"值到 modData（派生物必须可重算） |
| 4 | NeatUI API 出现在 `RM_UIAdapter.lua` 之外 |
| 5 | 数值硬编码在逻辑文件（一律进 RM_Config.lua） |
| 6 | 启动阶段引用 server 文件 |
| 7 | 跨子系统直接读写对方内部状态 |
| 8 | 超出当前里程碑范围的功能 |

## 关键 B42 API 勘误（高频踩坑）

| 错误写法 | 正确写法 | 说明 |
|---|---|---|
| `isMoving()` | `isPlayerMoving()` | B42 无 isMoving |
| `getFullName()` | `getFullType()` | Food 物品无 getFullName |
| `Stats.setHunger(v)` | `stats:set(CharacterStat.HUNGER, v)` | Stats 只有通用 set/get |
| `BodyDamage.setPain` | `stats:set(CharacterStat.PAIN, v)` | PAIN/POISON/SICKNESS 在 Stats |
| `FluidContainer.setAmount()` | `fc:adjustAmount(delta)` | 无 setAmount |
| `Food.setAge()` | `food:setRotten(true)` | Food 无 setAge |
| `ISLabel.setTextColor()` | 直接写 `textColor` 属性表 | 无 setTextColor 方法 |
| `drawLine(x1,y1,x2,y2)` | `drawRect` 1px 替代 | drawLine 需传 Texture |
| `setVisible(false)` 隐藏页 | `setY(-9999)` + 不透明背景 | setVisible 不阻止子元素渲染 |
| `ISLabel` 长文本 | 自定义 `ISUIElement:render()` + `drawText` | ISLabel 有定位偏移 |

## 饮品双路径架构（S7② 结论）

| 路径 | 物品类型 | 触发 | 醉酒 |
|---|---|---|---|
| Food 类 | `base:food` | `BodyDamage.Eat` | 仅绷带触发，饮品不触发 |
| FluidContainer 类 | `base:normal` + FluidContainer | `IsoGameCharacter.DrinkFluid` | `fluid.alcohol > 0` → 自动 `JustDrankBoozeFluid` |

- 酒精在 **Fluid 的 `Properties.alcohol`**（0.0–1.0），不在物品字段
- 原生**无 caffeine/sugar 字段**；糖在 `Carbohydrates`，咖啡/茶提神靠 `fatigueChange`
- MOD 不重复触发醉酒，`alcoholGrams` 仅用于空热量记账 + 训练恢复 + 图标判定
- 饮品表按 **Fluid 类型** 建模，查表优先级：Fluid 类型 → 物品 ID → 未命中告警（无关键词兜底）
