-- ============================================================
-- 模块名   : RM_Core
-- 职责     : 编排核心：事件挂载（幂等）、统一累加器（世界时间差归一化）、
--            进食/饮水 TimedAction 包装（§8.1）、修饰器应用（§11）、
--            每日结算编排（§8.4）、NeatUI 依赖门控（§12.5）
-- 所属里程碑: M1
-- 对外接口 : RM.Core.isAuthority / attach / onEat / onDrink / tickSecond
-- 依赖     : shared 全部 + RM_Hydration / RM_Fuel（server）
--            依赖方向（§5.2）：子系统 → RM_Core；本文件不反向调用子系统内部
-- ============================================================
RM = RM or {}
RM.Core = {}
local clamp = RM.Util.clamp

-- ---------------- 权威开关（§7） ----------------
-- 单机恒 true；MP 第一版不启用（§14），预留服务端权威
function RM.Core.isAuthority(player)
    return true
end

-- ---------------- 世界时间工具 ----------------
-- 世界小时（schema 的 proteinWindowUntil 等同单位）
function RM.Core._worldAgeHours()
    local ok, h = pcall(function() return getGameTime():getWorldAgeHours() end)
    if ok and type(h) == "number" then return h end
    return nil
end

function RM.Core._dayIndex()
    local h = RM.Core._worldAgeHours()
    if h then return math.floor(h / 24.0) end
    return nil
end

-- ---------------- 进食结算（§8.2） ----------------
-- gramsEaten 由包装层按重量差累计；此处按设计公式换算百克数记账
function RM.Core.onEat(item, player, ratio, preWeightKg)
    if not item or not player then return end
    local gramsEaten = (preWeightKg or 0) * 1000.0 * (ratio or 0) / 100.0
    if gramsEaten <= 0 then return end
    local grams100 = gramsEaten / 100.0

    -- 食物先判 Food（§16.2）；非食物只走水合（汤类饮品）
    local isFood = false
    local okF, rF = pcall(function() return instanceof(item, "Food") end)
    if okF then isFood = (rF == true) end

    if isFood then
        local row = RM.Data.lookupMicro(item)                 -- 每 100g 微量行
        -- 降解保留率（M3 RM_Decay 接入点；M1 全 1.0）
        local ret = nil
        if RM.Decay and RM.Decay.retention then
            local okR, rr = pcall(RM.Decay.retention, item)
            if okR and type(rr) == "table" then ret = rr end
        end
        for k, v in pairs(row) do
            local keep = (ret and ret[k]) or 1.0
            RM.Data.addMicro(player, k, v * grams100 * keep)
        end
        -- 含水食物（汤/蔬果）补水
        RM.Hydration.onConsumeFood(item, player, ratio)
    end
    -- 饮品药效挂点（M2 RM_Beverages 接入；M1 不存在则跳过）
    if RM.Beverages and RM.Beverages.onConsume then
        pcall(RM.Beverages.onConsume, item, player, ratio, grams100)
    end
end

-- 饮水入口（由 ISDrinkFluidAction 包装调用）
function RM.Core.onDrink(player, ml, item)
    if not player or not ml or ml <= 0 then return end
    RM.Hydration.onDrink(player, ml, item)
end

-- ---------------- TimedAction 包装（§8.1 / §20.5：包装+pcall+原链透传） ----------------
function RM.Core._hookEatActions()
    if ISEatFoodAction and ISEatFoodAction.__rmHooked then return end

    -- eat：每次咬合按重量差累计
    local origEat = ISEatFoodAction.eat
    ISEatFoodAction.eat = function(self, ...)
        local item, player = self.item, self.character
        local preW = nil
        if item then
            local ok, w = pcall(function() return item:getActualWeight() end)
            if ok and type(w) == "number" then preW = w end
        end
        local res = nil
        if origEat then res = origEat(self, ...) end     -- 原链透传
        if preW and item then
            local ok2, postW = pcall(function() return item:getActualWeight() end)
            if ok2 and type(postW) == "number" and postW < preW then
                item.__rmEatenKg = (item.__rmEatenKg or 0) + (preW - postW)
            end
        end
        return res
    end

    -- complete：结算累计的摄入（分次口数语义 TODO(S1) 上机核实）
    local origComplete = ISEatFoodAction.complete
    ISEatFoodAction.complete = function(self, ...)
        local item, player = self.item, self.character
        local preW = nil
        if item then
            local ok, w = pcall(function() return item:getActualWeight() end)
            if ok and type(w) == "number" then preW = w end
        end
        local res = nil
        if origComplete then res = origComplete(self, ...) end   -- 原链透传
        if item and player then
            local ok2, postW = pcall(function() return item:getActualWeight() end)
            local eaten = item.__rmEatenKg or 0
            if ok2 and type(postW) == "number" and preW and postW < preW then
                eaten = eaten + (preW - postW)
            end
            if eaten > 0 then
                -- 传入 gramsEaten 作为 preWeightKg、ratio=100，保持 §8.2 公式成立
                local ok3 = pcall(RM.Core.onEat, item, player, 100, eaten / 1000.0)
                if not ok3 then RM.Log.warn("onEat 结算失败，已跳过") end
                item.__rmEatenKg = nil
            end
        end
        return res
    end
    ISEatFoodAction.__rmHooked = true
    RM.Log.debug("已包装 ISEatFoodAction.eat/complete")
end

function RM.Core._hookDrinkActions()
    if ISDrinkFluidAction and ISDrinkFluidAction.__rmHooked then return end

    -- updateEat：填充比差值 → 本次喝入 ml（§8.1）
    local orig = ISDrinkFluidAction.updateEat
    ISDrinkFluidAction.updateEat = function(self, ...)
        local item, player = self.item, self.character
        local fc, preRatio, capacity = nil, nil, nil
        if item then
            local ok, c = pcall(function() return item:getFluidContainer() end)
            if ok and c then
                fc = c
                local ok2, r = pcall(function() return fc:getFilledRatio() end)
                if ok2 and type(r) == "number" then preRatio = r end
                local ok3, cap = pcall(function() return fc:getCapacity() end)
                if ok3 and type(cap) == "number" then capacity = cap end
            end
        end
        local res = nil
        if orig then res = orig(self, ...) end    -- 原链透传
        if fc and preRatio and capacity then
            local ok2, postRatio = pcall(function() return fc:getFilledRatio() end)
            if ok2 and type(postRatio) == "number" and postRatio < preRatio then
                local ml = (preRatio - postRatio) * capacity
                local okD = pcall(RM.Core.onDrink, player, ml, item)
                if not okD then RM.Log.warn("onDrink 结算失败，已跳过") end
            end
        end
        return res
    end
    ISDrinkFluidAction.__rmHooked = true
    RM.Log.debug("已包装 ISDrinkFluidAction.updateEat")
end

-- ---------------- 统一累加器（§7：世界时间差归一化，不按帧数） ----------------
RM.Core._lastWorldHours = nil
RM.Core._maxCatchupSteps = 3600   -- 防螺旋：单帧最多补 1 游戏小时的秒结算

function RM.Core._onPlayerUpdate(player)
    local now = RM.Core._worldAgeHours()
    if not now then return end
    if RM.Core._lastWorldHours == nil then
        RM.Core._lastWorldHours = now
        return
    end
    local dtHours = now - RM.Core._lastWorldHours
    if dtHours <= 0 then return end
    RM.Core._lastWorldHours = now

    local dtSec = dtHours * 3600.0
    local steps = math.floor(dtSec)
    if steps > RM.Core._maxCatchupSteps then steps = RM.Core._maxCatchupSteps end
    local frac = dtSec - math.floor(dtSec)
    if steps <= 0 then
        -- 不足 1 游戏秒的余量累积到下一次（用部分步长保精度）
        RM.Core._fracAccum = (RM.Core._fracAccum or 0) + frac
        if RM.Core._fracAccum >= 1 then
            RM.Core._tickSecond(player, 1)
            RM.Core._fracAccum = RM.Core._fracAccum - 1
        end
        return
    end
    for i = 1, steps do
        RM.Core._tickSecond(player, 1)
    end
end

-- 秒结算：只读派生 + 修饰器应用（每秒 ≤1 次 §15）；落盘每 10 游戏分钟
function RM.Core._tickSecond(player, dtSec)
    local ok, err = pcall(function()
        local md = RM.Data.ensurePlayer(player)
        if not md then return end
        RM.Hydration.tick(player, md, dtSec)
        RM.Fuel.tick(player, md, dtSec)
        RM.Core._applyModifiers(player)

        RM.State.saveAccumSec = RM.State.saveAccumSec + dtSec
        if RM.State.saveAccumSec >= RM.Config.saveEveryGameMin * 60 then
            RM.Data.commitLive(player, md)
            RM.State.saveAccumSec = 0
        end
    end)
    if not ok then RM.Log.warn("tickSecond 异常: " .. tostring(err)) end
end

-- 修饰器应用（§11：纯派生，不保存"已扣减"值；摘除来源即还原）
-- 通道：耐力恢复 ×乘区、耐力上限 cap（stats ENDURANCE 0–1）
function RM.Core._applyModifiers(player)
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    local stats
    local okS, s = pcall(function() return player:getStats() end)
    if not okS or not s then return end
    stats = s

    local statEnum
    local okE, e = pcall(function() return CharacterStat.ENDURANCE end)
    if not okE or not e then return end
    statEnum = e

    local cur
    local okG, v = pcall(function() return stats:get(statEnum) end)
    if not okG or type(v) ~= "number" then return end
    cur = v

    local sources = {}
    table.insert(sources, RM.Hydration.modifiers(md))
    local em = RM.Fuel.modifiers(md)
    if em then table.insert(sources, em) end
    if RM.Diseases and RM.Diseases.modifiers then
        local okD, dm = pcall(RM.Diseases.modifiers, md)
        if okD and dm then table.insert(sources, dm) end
    end
    if RM.Environment and RM.Environment.modifiers then
        local okV, vm = pcall(RM.Environment.modifiers, md)
        if okV and vm then table.insert(sources, vm) end
    end
    local mods = RM.Scoring.modifiers(sources)

    local last = RM.State.lastEndurance
    local newV = cur
    if last ~= nil then
        local delta = cur - last
        if delta > 0 then
            -- 恢复增益按乘区缩放
            newV = clamp(last + delta * mods.recovery, 0, mods.max)
        elseif cur > mods.max then
            newV = mods.max
        end
    end
    RM.State.lastEndurance = newV
    if newV ~= cur then
        pcall(function() stats:set(statEnum, newV) end)
    end
end

-- ---------------- 事件挂载（§5.3 两阶段；幂等 __rm 标记） ----------------
function RM.Core._onCreatePlayer(a, b)
    local player = b or a
    if player == nil then return end
    pcall(RM.Core.attach, player)
end

function RM.Core._onGameStart()
    pcall(function()
        local p = getPlayer()
        if p then RM.Core.attach(p) end
    end)
end

function RM.Core._onEveryDays()
    pcall(function()
        local p = getPlayer()
        local day = RM.Core._dayIndex()
        if p and day then RM.History.settle(p, day) end
    end)
end

function RM.Core.attach(player)
    if player == nil then return end
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    RM.Data.loadLive(player)
    RM.History.rebuildCache(md)

    -- 依赖门控（§12.5）：NeatUI 缺失 → 提示且不加载业务逻辑
    -- client 启动阶段把检测结果写入 RM.State.neatUIOk；server 独立进程（MP 服务器）无 client，
    -- 第一版单机优先（§14），MP 时改为服务端跳过该门控
    if RM.State.neatUIOk == false then
        RM.Log.warn("NeatUI 缺失：请订阅 Workshop 3508537032 后再启用 Real Metabolism（§12.5）")
        return
    end

    -- Hook 只装一次（§16.3）
    RM.Core._hookEatActions()
    RM.Core._hookDrinkActions()
    RM.Log.debug("attach 完成: hydration=" .. tostring(md.hydration))
end

-- 定义阶段注册引导事件（幂等）
if not RM.Core.__rmEventsBound then
    Events.OnCreatePlayer.Add(RM.Core._onCreatePlayer)
    Events.OnGameStart.Add(RM.Core._onGameStart)
    Events.OnPlayerUpdate.Add(RM.Core._onPlayerUpdate)
    Events.EveryDays.Add(RM.Core._onEveryDays)
    RM.Core.__rmEventsBound = true
end
