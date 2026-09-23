-- UI 层（§12）：图标装配纯函数 + 面板数据装配 + 生命周期/节流 + 适配层门控
-- 说明：渲染经 RM_UIAdapter，_impl 未落地（S7）→ 全部组件调用必须安全空操作
local Icons = RM.UI.Icons
local Panel = RM.Panel
local UI = RM.UI
local C = RM.Config

-- ---------------- A. buildIconStates（§12.3 隐藏原则：正常态零图标） ----------------
local st = Icons.buildIconStates({ hydration = 100, energyFeedback = 1.0 })
check("图标: 正常态不显示", #st == 0)

st = Icons.buildIconStates(nil)
check("图标: nil live 防御为正常态", #st == 0)

-- 水合 4 档（60/40/20 边界，min 含）
st = Icons.buildIconStates({ hydration = 60, energyFeedback = 1.0 })
check("图标: h=60 边界 normal", #st == 0)
st = Icons.buildIconStates({ hydration = 59.9, energyFeedback = 1.0 })
check("图标: h=59.9 → thirsty", #st == 1 and st[1].tier == "thirsty"
    and st[1].id == "hydration" and st[1].colorKey == "warn")
st = Icons.buildIconStates({ hydration = 35, energyFeedback = 1.0 })
check("图标: h=35 → low/bad", #st == 1 and st[1].tier == "low" and st[1].colorKey == "bad")
st = Icons.buildIconStates({ hydration = 10, energyFeedback = 1.0 })
check("图标: h=10 → critical/bad", #st == 1 and st[1].tier == "critical")
check("图标: 水合文本含整数值", st[1].text == "H 10")
st = Icons.buildIconStates({ hydration = 250, energyFeedback = 1.0 })
check("图标: 超界 clamp 100 → normal", #st == 0)
st = Icons.buildIconStates({ hydration = -5, energyFeedback = 1.0 })
check("图标: 负值 clamp 0 → critical", #st == 1 and st[1].tier == "critical")

-- 能量 3 档（0.30/0.05 边界，低于才触发）
st = Icons.buildIconStates({ hydration = 100, energyFeedback = 0.30 })
check("图标: ef=0.30 normal", #st == 0)
st = Icons.buildIconStates({ hydration = 100, energyFeedback = 0.299 })
check("图标: ef=0.299 → low/warn", #st == 1 and st[1].id == "energy"
    and st[1].tier == "low" and st[1].colorKey == "warn")
st = Icons.buildIconStates({ hydration = 100, energyFeedback = 0.05 })
check("图标: ef=0.05 仍 low（低于才 frozen）", #st == 1 and st[1].tier == "low")
st = Icons.buildIconStates({ hydration = 100, energyFeedback = 0.04 })
check("图标: ef=0.04 → frozen/bad", #st == 1 and st[1].tier == "frozen"
    and st[1].colorKey == "bad")

-- 双异常：水合在前、能量在后，均可见
st = Icons.buildIconStates({ hydration = 15, energyFeedback = 0.1 })
check("图标: 双异常共 2 枚", #st == 2 and st[1].id == "hydration" and st[2].id == "energy")
check("图标: visible 均为 true", st[1].visible == true and st[2].visible == true)

-- ---------------- B. buildStatusRows（§12.2 状态页装配） ----------------
local p = mkPlayer()
local md = RM.Data.ensurePlayer(p)
local rows = Panel.buildStatusRows(md, { hydration = 50, energyFeedback = 0.5 },
    { seconds = 100, sumIntensity = 20 }, { calories = 200 })
check("行数: 8微量+水合+能量+负荷+宏量", #rows == #C.microKeys + 4)

-- 微量行：0 摄入 → 净负 → danger；labelKey 命名规范
local r0 = rows[1]
check("微量行: 零摄入 danger", r0.tier == "danger" and r0.key == C.microKeys[1])
check("微量行: labelKey 规范", r0.labelKey == "RM_Micro_" .. C.microKeys[1])

-- 微量行满摄入 → ratio=1（扣固定损耗后仍 ≥0.8 → ok 档）
local pFull = mkPlayer()
local mdFull = RM.Data.ensurePlayer(pFull)
for _, k in ipairs(C.microKeys) do
    mdFull.micro[k] = C.DRI[k] + (C.dailyFixedLoss[k] or 0)
end
local rowsFull = Panel.buildStatusRows(mdFull, nil, nil, nil)
local allOk = true
for i = 1, #C.microKeys do
    if rowsFull[i].tier ~= "ok" then allOk = false end
end
check("微量行: DRI+损耗 全 ok 档", allOk)

-- 水合行 / 能量行
local byKey = {}
for i = 1, #rows do byKey[rows[i].key] = rows[i] end
check("水合行: value=hyd/100", approx(byKey.hydration.value, 0.5))
check("水合行: tier=thirsty", byKey.hydration.tier == "thirsty")
check("能量行: value=ef", approx(byKey.energy.value, 0.5) and byKey.energy.tier == "normal")
check("负荷行: 均值强度 0.2 → moderate", approx(byKey.load.value, 0.2)
    and byKey.load.tier == "moderate")
check("宏量行: 原生只读透传", byKey.macros.raw.calories == 200)

-- 负荷分档边界（0.15/0.45）与零秒防御
local function loadTier(sec, sum)
    return Panel.buildStatusRows(md, nil, { seconds = sec, sumIntensity = sum }, nil)[#C.microKeys + 3].tier
end
check("负荷: 0 → rest", loadTier(0, 0) == "rest")
check("负荷: 0.15 边界 moderate", loadTier(100, 15) == "moderate")
check("负荷: 0.45 边界 high", loadTier(100, 45) == "high")
check("负荷: seconds=0 除零安全", loadTier(0, 999) == "rest")

-- live 缺省回退：md.hydration / 1.0
local rowsDef = Panel.buildStatusRows(md, nil, nil, nil)
local byKey2 = {}
for i = 1, #rowsDef do byKey2[rowsDef[i].key] = rowsDef[i] end
check("缺省: live=nil 水合回退 md 值", approx(byKey2.hydration.value, md.hydration / 100))
check("缺省: live=nil 能量=1", approx(byKey2.energy.value, 1))

-- ---------------- C. buildTrendPoints（趋势页装配） ----------------
local mdT = RM.Data.ensurePlayer(mkPlayer())
mdT.history = {
    { day = 3, score = { sodium = 0.7 }, hydration = 50, weightKg = 70, sunMins = 10, exercise = 0.2 },
    { day = 4 },                                        -- 无 score → 跳过
    { day = 5, score = { sodium = 0.9 }, hydration = 60, weightKg = 71, sunMins = 0, exercise = 0 },
}
local pts = Panel.buildTrendPoints(mdT)
check("趋势: 有 score 才成点", #pts == 2 and pts[1].day == 3 and pts[2].day == 5)
check("趋势: 字段透传", pts[1].hydration == 50 and pts[1].weightKg == 70)
check("趋势: nil md → 空", #Panel.buildTrendPoints(nil) == 0)

-- ---------------- D. Panel 生命周期（开关键/开关态/节流） ----------------
_G.__testPlayer = mkPlayer()
local mdP = RM.Data.ensurePlayer(_G.__testPlayer)
check("初始: 面板关闭", Panel.isOpen() == false)

Panel.toggle()
check("toggle: 开 → prefs 持久化", Panel.isOpen() == true and mdP.prefs.uiOpen == true)
Panel.toggle()
check("toggle: 关 → prefs 同步 false", Panel.isOpen() == false and mdP.prefs.uiOpen == false)

-- 键位解析：Keyboard.KEY_N=46（桩）；命中才 toggle，未命中不动
Panel._keycode = nil
check("键位: 解析 KEY_N=46", Panel._resolveKeycode() == 46)
local openBefore = Panel.isOpen()
Panel._onKey(30)
check("按键: 非目标键不翻转", Panel.isOpen() == openBefore)
Panel._onKey(46)
check("按键: 目标键翻转", Panel.isOpen() ~= openBefore)
Panel._onKey(46)   -- 复位
check("按键: 再按复位", Panel.isOpen() == openBefore)

-- 键位缺失兜底：Keyboard 无该键 → 默认 46
Panel._keycode = nil
local kbBak, kbKey = Keyboard, Keyboard.KEY_N
Keyboard = {}
check("键位: 缺键兜底 46", Panel._resolveKeycode() == 46)
Keyboard, Keyboard.KEY_N = kbBak, kbKey

-- 节流刷新（§12.2：可见 ≥250ms；不可见停刷）
local refCount = 0
local refreshBak = Panel.refresh
Panel.refresh = function() refCount = refCount + 1 end
local nowBak = getTimestampMs
getTimestampMs = function() return 0 end
Panel._lastRefreshMs = 0

Panel._open = false
Panel._onTick()
check("节流: 关闭态零刷新", refCount == 0)

Panel._open = true
Panel._onTick()   -- 0-0=0 < 250 → 跳过
check("节流: 间隔内跳过", refCount == 0)
getTimestampMs = function() return 249 end
Panel._onTick()
check("节流: 249ms 仍跳过", refCount == 0)
getTimestampMs = function() return 250 end
Panel._onTick()
check("节流: 250ms 触发刷新", refCount == 1)
Panel._onTick()   -- 250-250=0 → 跳过
check("节流: 刷新后计时重置", refCount == 1)
getTimestampMs = function() return 600 end
Panel._onTick()
check("节流: 600ms 再刷一次", refCount == 2)

Panel.refresh, Panel._open = refreshBak, false
getTimestampMs = nowBak

-- ---------------- E. 适配层门控（§12.1/§12.5） ----------------
-- NeatUI 缺失（桩环境无全局）→ 检测失败并缓存
RM.State.neatUIChecked, RM.State.neatUIOk = false, nil
check("门控: 无 NeatUI 检测失败", UI.checkDependency() == false and RM.State.neatUIOk == false)
check("门控: 结果缓存（二次不再检测）", UI.checkDependency() == false and RM.State.neatUIChecked == true)

-- NeatUI 存在 → 检测通过（模拟前置已加载）
NeatUI = { version = "test" }
RM.State.neatUIChecked, RM.State.neatUIOk = false, nil
check("门控: NeatUI 在场通过", UI.checkDependency() == true)
NeatUI = nil

-- _impl 未落地（S7）→ 全组件安全空操作，不抛错
local w
local okAll = true
w = UI.makePanel({ title = "t" });     okAll = okAll and w.ok == false and w.widget == nil
w = UI.makeTabs({});                   okAll = okAll and w.ok == false
w = UI.makeBar({});                    okAll = okAll and w.ok == false
w = UI.makeList({});                   okAll = okAll and w.ok == false
w = UI.makeLineChart({});              okAll = okAll and w.ok == false
w = UI.makeIconHost({ anchor = "x" }); okAll = okAll and w.ok == false
check("适配: 未接 _impl 全部安全降级", okAll)
check("适配: drawText 返回 false", UI.drawText(nil, "x", 0, 0, nil) == false)

-- 端到端安全：Panel.refresh / Icons.update 在无渲染实现下不抛错
local okEnd, errEnd = pcall(function()
    RM.State.live.hydration = 20        -- critical，图标装配非空路径
    Panel.refresh()
    Icons.update(mdP)
    RM.State.live.hydration = 100
end)
check("端到端: 刷新+图标更新无渲染不抛错", okEnd and errEnd == nil)

-- ---------------- F. Theme 完整性（图标档位色引用闭合） ----------------
local colorOk = true
for tier, colorKey in pairs(RM.Theme.hydrationIcon) do
    if RM.Theme.colors[colorKey] == nil then colorOk = false end
end
for tier, colorKey in pairs(RM.Theme.energyIcon) do
    if RM.Theme.colors[colorKey] == nil then colorOk = false end
end
check("主题: 图标档位色全部闭合", colorOk)
check("主题: 水合 4 档齐全", (function()
    for _, t in ipairs(C.hydration.tiers) do
        if RM.Theme.hydrationIcon[t.id] == nil then return false end
    end
    return true
end)())
_G.__testPlayer = nil
