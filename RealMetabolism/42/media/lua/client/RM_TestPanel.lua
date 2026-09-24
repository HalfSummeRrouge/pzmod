-- ============================================================
-- 模块名   : RM_TestPanel
-- 职责     : S1/S2 上机实测辅助面板（Ctrl+T 开关）
-- 对外接口 : RM.TestPanel.init / toggle / isOpen
-- 注意     : PZ 默认字体不支持中文，所有 UI 文本用英文
-- ============================================================
RM = RM or {}
RM.TestPanel = {}

RM.TestPanel._open = false
RM.TestPanel._panel = nil
RM.TestPanel._logLines = {}
RM.TestPanel._maxLogLines = 60

-- ---------------- 探针日志同步入口 ----------------
function RM.TestPanel.pushLog(line)
    table.insert(RM.TestPanel._logLines, line)
    while #RM.TestPanel._logLines > RM.TestPanel._maxLogLines do
        table.remove(RM.TestPanel._logLines, 1)
    end
    if RM.TestPanel._open and RM.TestPanel._panel then
        RM.TestPanel._refreshLogBox()
    end
end

function RM.TestPanel._player()
    local ok, p = pcall(getPlayer)
    if ok and p then return p end
    return nil
end

-- ---------------- 物品生成 ----------------
function RM.TestPanel.giveItem(type)
    local p = RM.TestPanel._player()
    if not p then return nil end
    local ok, item = pcall(function() return p:getInventory():AddItem(type) end)
    if ok and item then return item end
    return nil
end

function RM.TestPanel.giveItemMany(type, count)
    local p = RM.TestPanel._player()
    if not p then return 0 end
    local n = 0
    for i = 1, count do
        local ok, item = pcall(function() return p:getInventory():AddItem(type) end)
        if ok and item then n = n + 1 end
    end
    return n
end

-- ---------------- 动作 ----------------
function RM.TestPanel.eat(type)
    local p = RM.TestPanel._player()
    if not p then return end
    local item = RM.TestPanel.giveItem(type)
    if not item then return end
    pcall(function() ISTimedActionQueue.add(ISEatFoodAction:new(p, item, 1)) end)
end

function RM.TestPanel.drinkBottle()
    local p = RM.TestPanel._player()
    if not p then return end
    local wb = RM.TestPanel.giveItem("Base.WaterBottle")
    if not wb then return end
    local ok, fc = pcall(function() return wb:getFluidContainer() end)
    if ok and fc then
        pcall(function() fc:addFluid(FluidType.Water, fc:getCapacity()) end)
    end
    pcall(function() ISTimedActionQueue.add(ISDrinkFromBottle:new(p, wb, 1)) end)
end

-- 喝污染水：生成一瓶装满 TaintedWater 的水瓶并喝下
function RM.TestPanel.drinkTainted()
    local p = RM.TestPanel._player()
    if not p then return end
    local wb = RM.TestPanel.giveItem("Base.WaterBottle")
    if not wb then return end
    local ok, fc = pcall(function() return wb:getFluidContainer() end)
    if ok and fc then
        -- B42 FluidContainer 没有 setAmount，用 adjustAmount 设绝对值
        pcall(function() fc:adjustAmount(0) end)
        if FluidType and FluidType.TaintedWater then
            pcall(function() fc:addFluid(FluidType.TaintedWater, fc:getCapacity()) end)
        end
    end
    -- 先让玩家口渴，否则 drink() 里 isThirsty 判断会跳过
    pcall(function() p:getStats():set(CharacterStat.THIRST, 0.8) end)
    pcall(function() ISTimedActionQueue.add(ISDrinkFromBottle:new(p, wb, 1)) end)
end

-- 强制睡觉：把疲劳拉满，绕过"太舒服了"检查
-- 源码依据：ISSleepDialog.lua:16 直接用 CharacterStat.FATIGUE；
--           ISWorldObjectContextMenu.lua:1077 fatigue 决定睡眠时长
-- 注意：Kahlua pcall 抓不住 Java 异常，必须在 Lua 层先判空
function RM.TestPanel.forceSleepy()
    local p = RM.TestPanel._player()
    if not p then return end
    local stats = p:getStats()
    if not stats then return end

    -- 取 fatigue stat（先静态字段，再 getById 兜底）
    local fatigueStat = nil
    if CharacterStat then
        fatigueStat = CharacterStat.FATIGUE
        if not fatigueStat then
            fatigueStat = CharacterStat.getById("FATIGUE")
        end
    end

    local fatigueOk = false
    local fatigueReadback = -1
    if fatigueStat ~= nil then
        stats:set(fatigueStat, 1.0)
        fatigueOk = true
        local okR, rv = pcall(function() return stats:get(fatigueStat) end)
        if okR and type(rv) == "number" then fatigueReadback = rv end
    end

    -- 清压力/恐慌/疼痛（避免睡眠被 moodle 打断）
    if CharacterStat and CharacterStat.STRESS then stats:set(CharacterStat.STRESS, 0) end
    if CharacterStat and CharacterStat.PANIC then stats:set(CharacterStat.PANIC, 0) end
    if CharacterStat and CharacterStat.PAIN then stats:set(CharacterStat.PAIN, 0) end

    -- 直接入睡：照搬 ISSleepDialog.onClick YES 的 API（绕过 Java 层 canSleep 检查）
    local fellAsleep = false
    local sleepHours = 8
    pcall(function()
        local gt = GameTime.getInstance()
        local wakeTime = gt:getTimeOfDay() + sleepHours
        if wakeTime >= 24 then wakeTime = wakeTime - 24 end
        p:setForceWakeUpTime(wakeTime)
        p:setAsleepTime(0.0)
        p:setAsleep(true)
        if getSleepingEvent then
            getSleepingEvent():setPlayerFallAsleep(p, sleepHours)
        end
        fellAsleep = true
    end)

    if RM.Probe and RM.Probe._write then
        pcall(RM.Probe._write, "force_sleep", {
            "stat", fatigueStat ~= nil and 1 or 0,
            "set", fatigueOk and 1 or 0,
            "readback", fatigueReadback,
            "asleep", fellAsleep and 1 or 0,
        })
    end
end

-- ---------------- 状态重置 ----------------
-- B42 Stats 类没有 setHunger/setThirst，必须用 set(CharacterStat.XXX, value)
function RM.TestPanel.resetHunger()
    local p = RM.TestPanel._player()
    if not p then return end
    pcall(function() p:getStats():set(CharacterStat.HUNGER, 0.0) end)
end

function RM.TestPanel.resetThirst()
    local p = RM.TestPanel._player()
    if not p then return end
    pcall(function() p:getStats():set(CharacterStat.THIRST, 0.0) end)
end

function RM.TestPanel.resetVeryFull()
    local p = RM.TestPanel._player()
    if not p then return end
    pcall(function() p:getBodyDamage():setHealthFromFoodTimer(0) end)
end

function RM.TestPanel.resetHydration()
    if RM.State and RM.State.live then
        pcall(function() RM.State.live.hydration = 100 end)
    end
end

-- ---------------- 天气 ----------------
-- B42 直接控制降水：getClimateFloat(FLOAT_PRECIPITATION_INTENSITY) + setAdminValue
function RM.TestPanel.startRain()
    pcall(function()
        local cm = getClimateManager()
        if not cm then return end
        -- 策略1：直接设置降水强度（debug 菜单同款方式）
        local okCF, cf = pcall(function() return cm:getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY) end)
        if okCF and cf then
            pcall(function() cf:setEnableAdmin(true) end)
            pcall(function() cf:setAdminValue(1.0) end)
            return
        end
        -- 策略2：transmitServerStartRain（服务端天气包）
        local ok1 = pcall(function() cm:transmitServerStartRain(1.0) end)
        if not ok1 then
            pcall(function() cm:transmitServerTriggerStorm(2.0) end)
        end
    end)
end

function RM.TestPanel.stopRain()
    pcall(function()
        local cm = getClimateManager()
        if not cm then return end
        -- 策略1：降水强度归零
        local okCF, cf = pcall(function() return cm:getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY) end)
        if okCF and cf then
            pcall(function() cf:setAdminValue(0.0) end)
            return
        end
        -- 策略2
        local ok1 = pcall(function() cm:transmitServerStopRain() end)
        if not ok1 then
            pcall(function() cm:transmitServerStopWeather() end)
        end
    end)
end

-- ---------------- 面板构建 ----------------
function RM.TestPanel._build()
    local panel = ISPanel:new(20, 20, 660, 560)
    local ok, err = pcall(function()
        panel:initialise()
        panel:instantiate()
        panel:setAlwaysOnTop(true)
        panel.borderColor = {r=0.2, g=0.2, b=0.2, a=0.9}
        panel.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.9}

        local title = ISLabel:new(10, 8, 20, "RM Test Panel (Ctrl+T)", 1,1,1,1, UIFont.Medium, true)
        title:initialise()
        panel:addChild(title)

        local closeBtn = ISButton:new(620, 5, 30, 24, "X", panel, function() RM.TestPanel.toggle() end)
        closeBtn:initialise()
        panel:addChild(closeBtn)

        local BtnW = 100
        local BtnH = 26
        local Gap = 6

        -- ===== 行1：物品生成 =====
        local y = 40
        local itemLabel = ISLabel:new(10, y, 16, "Spawn Items:", 0.8,0.8,0.8,1, UIFont.Small, true)
        itemLabel:initialise()
        panel:addChild(itemLabel)

        local items = {
            {label="Apple",       type="Base.Apple"},
            {label="Bread",       type="Base.Bread"},
            {label="WaterFull",   type="Base.WaterBottle", fill=true},
            {label="Soup",        type="Base.TinnedSoupOpen"},
            {label="RottenApple", type="Base.Apple", rotten=true},
            {label="CampfireKit", type="Base.CampfireKit"},
        }
        local bx = 10
        for _, it in ipairs(items) do
            local btn = ISButton:new(bx, y+20, BtnW, BtnH, it.label, panel, function()
                local item = RM.TestPanel.giveItem(it.type)
                if not item then return end
                if it.fill then
                    local ok, fc = pcall(function() return item:getFluidContainer() end)
                    if ok and fc then pcall(function() fc:addFluid(FluidType.Water, fc:getCapacity()) end) end
                end
                if it.rotten then pcall(function() item:setRotten(true) end) end
            end)
            btn:initialise()
            panel:addChild(btn)
            bx = bx + BtnW + Gap
        end

        -- ===== 行2：测试动作 =====
        y = y + 56
        local actLabel = ISLabel:new(10, y, 16, "Test Actions:", 0.8,0.8,0.8,1, UIFont.Small, true)
        actLabel:initialise()
        panel:addChild(actLabel)

        local actions = {
            {label="Eat Apple",  fn=function() RM.TestPanel.eat("Base.Apple") end},
            {label="Eat Bread",  fn=function() RM.TestPanel.eat("Base.Bread") end},
            {label="Eat Soup",   fn=function() RM.TestPanel.eat("Base.TinnedSoupOpen") end},
            {label="Drink Water",fn=function() RM.TestPanel.drinkBottle() end},
            {label="Drink Tainted", fn=function() RM.TestPanel.drinkTainted() end},
        }
        bx = 10
        for _, act in ipairs(actions) do
            local btn = ISButton:new(bx, y+20, BtnW, BtnH, act.label, panel, act.fn)
            btn:initialise()
            panel:addChild(btn)
            bx = bx + BtnW + Gap
        end

        -- ===== 行3：批量/天气 =====
        y = y + 56
        local batchLabel = ISLabel:new(10, y, 16, "Batch / Weather:", 0.8,0.8,0.8,1, UIFont.Small, true)
        batchLabel:initialise()
        panel:addChild(batchLabel)

        local batchBtns = {
            {label="Bread x5",  fn=function() RM.TestPanel.giveItemMany("Base.Bread", 5) end},
            {label="Bread x10", fn=function() RM.TestPanel.giveItemMany("Base.Bread", 10) end},
            {label="Start Rain",fn=function() RM.TestPanel.startRain() end},
            {label="Stop Rain", fn=function() RM.TestPanel.stopRain() end},
            {label="Dump Bev",  fn=function()
                local p = getPlayer()
                if p and RM.Probe and RM.Probe.dumpBeverages then
                    pcall(RM.Probe.dumpBeverages, p)
                end
            end},
        }
        bx = 10
        for _, b in ipairs(batchBtns) do
            local btn = ISButton:new(bx, y+20, BtnW, BtnH, b.label, panel, b.fn)
            btn:initialise()
            panel:addChild(btn)
            bx = bx + BtnW + Gap
        end

        -- ===== 行4：状态重置 =====
        y = y + 56
        local resetLabel = ISLabel:new(10, y, 16, "Reset Stats:", 0.8,0.8,0.8,1, UIFont.Small, true)
        resetLabel:initialise()
        panel:addChild(resetLabel)

        local resetBtns = {
            {label="Hunger=0",  fn=function() RM.TestPanel.resetHunger() end},
            {label="Thirst=0",  fn=function() RM.TestPanel.resetThirst() end},
            {label="VeryFull=0",fn=function() RM.TestPanel.resetVeryFull() end},
            {label="Hyd=100",   fn=function() RM.TestPanel.resetHydration() end},
            {label="Force Sleep",fn=function() RM.TestPanel.forceSleepy() end},
        }
        bx = 10
        for _, b in ipairs(resetBtns) do
            local btn = ISButton:new(bx, y+20, BtnW, BtnH, b.label, panel, b.fn)
            btn:initialise()
            panel:addChild(btn)
            bx = bx + BtnW + Gap
        end

        -- ===== 池状态 =====
        y = y + 56
        panel._statusLabel = ISLabel:new(10, y, 16, "Pool: (loading...)", 0.9,0.9,0.9,1, UIFont.Small, false)
        panel._statusLabel:initialise()
        panel._statusLabel:setWidth(640)
        panel:addChild(panel._statusLabel)

        -- ===== 探针日志 =====
        y = y + 28
        local logLabel = ISLabel:new(10, y, 16,
            "Probe Log (last " .. RM.TestPanel._maxLogLines .. "):",
            0.8,0.8,0.8,1, UIFont.Small, true)
        logLabel:initialise()
        panel:addChild(logLabel)

        y = y + 20
        panel._logBox = ISRichTextPanel:new(10, y, 640, 180)
        panel._logBox:initialise()
        panel._logBox:setMargins(5, 5, 5, 5)
        panel._logBox.autosetheight = false
        panel._logBox.background = true
        panel._logBox.backgroundColor = {r=0, g=0, b=0, a=0.6}
        panel._logBox.borderColor = {r=0.3, g=0.3, b=0.3, a=0.5}
        panel:addChild(panel._logBox)

        local clearBtn = ISButton:new(570, y-24, 80, 22, "Clear", panel, function()
            RM.TestPanel._logLines = {}
            RM.TestPanel._refreshLogBox()
        end)
        clearBtn:initialise()
        panel:addChild(clearBtn)
    end)
    if not ok then
        RM.Log.warn("TestPanel._build error: " .. tostring(err))
    end
    return panel
end

-- ---------------- 日志格式化（原始 CSV → 易读对齐格式） ----------------
function RM.TestPanel._formatLine(line)
    if not line then return "" end
    local hour, evt, data = string.match(line, "^([^,]+),([^,]+),(.*)$")
    if not evt then return line end

    local kv = {}
    if data then
        for k, v in string.gmatch(data, "([^=;]+)=([^;]*)") do
            kv[k] = v
        end
    end

    local p = string.format("[%s] ", hour or "?")

    if evt == "sample" then
        return string.format("%sSAMPLE   cal=%s carbs=%s lipids=%s prot=%s hyd=%s wt=%s temp=%s",
            p, kv.cal or "?", kv.carbs or "?", kv.lipids or "?",
            kv.proteins or "?", kv.hyd or "?", kv.weightKg or "?", kv.temp or "?")
    elseif evt == "eat" then
        return string.format("%sEAT      %s grams=%s food=%s",
            p, kv.item or "", kv.grams or "?", kv.isFood or "?")
    elseif evt == "drink" then
        return string.format("%sDRINK    ml=%s cap=%s",
            p, kv.ml or "?", kv.capacity or "?")
    elseif evt == "bite" then
        return string.format("%sBITE     pre=%s post=%s",
            p, kv.preKg or "?", kv.postKg or "?")
    elseif evt == "hydrate" then
        return string.format("%sHYDRATE  %s", p, data or "")
    elseif evt == "key" then
        return string.format("%sKEY      key=%s", p, kv.key or "?")
    elseif evt == "session" then
        return string.format("%sSESSION  kind=%s", p, kv.kind or "")
    elseif evt == "clock" then
        return string.format("%sCLOCK    %s", p, data or "")
    elseif evt == "everydays" then
        return string.format("%sEVERYDAYS %s", p, data or "")
    elseif evt == "dbg_start" then
        return string.format("%sDBG_START %s", p, data or "")
    elseif evt == "dbg_perform" then
        return string.format("%sDBG_PERF %s", p, data or "")
    elseif evt == "poison" then
        return string.format("%sPOISON   %s ml=%s before=%s after=%s",
            p, kv.kind or "?", kv.ml or "?", kv.poisonBefore or "?", kv.poisonAfter or "?")
    elseif evt == "force_sleep" then
        return string.format("%sFORCE_SLEEP fatigue=%s", p, kv.fatigue or "?")
    elseif evt == "sleep" then
        return string.format("%sSLEEP    phase=%s hours=%s", p, kv.phase or "?", kv.hours or "?")
    elseif evt == "wake" then
        return string.format("%sWAKE     phase=%s duration=%sh", p, kv.phase or "?", kv.durationHours or "?")
    end
    return line
end

function RM.TestPanel._refreshLogBox()
    if not RM.TestPanel._panel or not RM.TestPanel._panel._logBox then return end
    local formatted = {}
    for _, line in ipairs(RM.TestPanel._logLines) do
        table.insert(formatted, RM.TestPanel._formatLine(line))
    end
    local text = table.concat(formatted, "\n")
    pcall(function()
        RM.TestPanel._panel._logBox.text = text
        RM.TestPanel._panel._logBox:paginate()
    end)
end

function RM.TestPanel._refreshStatus()
    if not RM.TestPanel._panel or not RM.TestPanel._panel._statusLabel then return end
    local p = RM.TestPanel._player()
    if not p then return end
    local live = RM.State and RM.State.live
    if not live then return end
    local ok, s = pcall(function()
        return string.format(
            "cal=%.0f carbs=%.0f lipids=%.1f proteins=%.1f hyd=%.1f weight=%.1f",
            live.calories or 0, live.carbohydrates or 0, live.lipids or 0,
            live.proteins or 0, live.hydration or 0, live.bodyWeight or 0)
    end)
    if ok then
        pcall(function() RM.TestPanel._panel._statusLabel:setName("Pool: " .. s) end)
    end
end

-- ---------------- 开关 ----------------
function RM.TestPanel.toggle()
    RM.TestPanel._open = not RM.TestPanel._open
    if RM.TestPanel._open then
        if not RM.TestPanel._panel then
            RM.TestPanel._panel = RM.TestPanel._build()
        end
        if RM.TestPanel._panel then
            RM.TestPanel._panel:setVisible(true)
            RM.TestPanel._panel:addToUIManager()
        end
        RM.TestPanel._refreshLogBox()
        RM.TestPanel._refreshStatus()
    else
        if RM.TestPanel._panel then
            RM.TestPanel._panel:removeFromUIManager()
            RM.TestPanel._panel:setVisible(false)
        end
    end
end

function RM.TestPanel.isOpen()
    return RM.TestPanel._open
end

-- ---------------- 启动 ----------------
function RM.TestPanel.init()
    if RM.TestPanel.__rmBound then return end
    RM.TestPanel.__rmBound = true

    Events.OnKeyPressed.Add(function(key)
        local okT, KEYT = pcall(function() return Keyboard.KEY_T end)
        if not okT or key ~= KEYT then return end
        local ctrlDown = false
        pcall(function() ctrlDown = isKeyDown(Keyboard.KEY_LCONTROL) end)
        if ctrlDown then RM.TestPanel.toggle() end
    end)

    Events.OnTick.Add(function()
        if RM.TestPanel._open then
            RM.TestPanel._refreshStatus()
        end
    end)
end

Events.OnGameStart.Add(function()
    pcall(function() RM.TestPanel.init() end)
end)
