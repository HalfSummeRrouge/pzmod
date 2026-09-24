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
-- 污染水中毒交由 B42 原生流体系统处理（TaintedWater 的 Poison 块），mod 不重复实现
function RM.Core.onDrink(player, ml, item)
    if not player or not ml or ml <= 0 then return end
    RM.Hydration.onDrink(player, ml, item)
end

-- ---------------- TimedAction 包装（§8.1 / §20.5：包装+pcall+原链透传） ----------------
-- B42 注意：LuaTimedActionNew.complete 仅在 !GameClient.client 时调用（Java 侧判断），
-- 单人模式 client=true 导致 complete 不触发；perform 无此限制，客户端/服务端均调用，
-- 故进食结算挂 perform（完整吃完）+ eat（中断 serverStop 时的部分摄入）。
function RM.Core._hookEatActions()
    if ISEatFoodAction and ISEatFoodAction.__rmHooked then return end
    if not ISEatFoodAction then
        RM.Log.warn("_hookEatActions: ISEatFoodAction 不存在，进食 hook 未安装")
        return
    end

    -- eat：每次咬合立即记账（B42 取消进食走 forceCancel 不调用 stop，
    -- 故不能依赖 stop 刷累计值；改为每 bite 实时记账）
    local origEat = ISEatFoodAction.eat
    ISEatFoodAction.eat = function(self, ...)
        local item, player = self.item, self.character
        local preW = nil
        if item then
            local ok, w = pcall(function() return item:getActualWeight() end)
            if ok and type(w) == "number" and w == w then preW = w end  -- w==w 排除 NaN
        end
        local res = nil
        if origEat then
            local okE, r = pcall(origEat, self, ...)
            if okE then res = r else RM.Log.warn("ISEatFoodAction.eat 原版异常，已跳过") end
        end
        if preW and item then
            local ok2, postW = pcall(function() return item:getActualWeight() end)
            -- postW 可能为 NaN（物品被消耗），此时视为整口吃完，diff=preW
            local diff = 0
            if ok2 and type(postW) == "number" and postW == postW and postW < preW then
                diff = preW - postW
            elseif ok2 and type(postW) == "number" and (postW ~= postW or postW <= 0) then
                diff = preW  -- NaN 或 ≤0，物品已消耗
            end
            if diff > 0 then
                -- 立即记账（不累计，避免依赖 stop）
                local isFood = false
                local okF, rF = pcall(function() return instanceof(item, "Food") end)
                if okF then isFood = (rF == true) end
                local ratio = (diff / preW) * 100  -- 本口占原始重量的百分比
                local ok3 = pcall(RM.Core.onEat, item, player, ratio, preW)
                if not ok3 then RM.Log.warn("onEat(bite) 结算失败，已跳过") end
                -- 累计 bite 总量，供 perform 扣减（避免吃几口再吃完时重复记账）
                self.__rmBiteTotal = (self.__rmBiteTotal or 0) + diff
                if RM.Probe and RM.Probe.eatSettle then
                    pcall(RM.Probe.eatSettle, item, player, diff, isFood)
                end
            end
            -- S1-1/S2-4 探针：每口重量差 + 池瞬时值
            if RM.Probe and RM.Probe.bite then
                pcall(RM.Probe.bite, item, player, preW, postW)
            end
        end
        return res
    end

    -- start：记录初始重量 + 重置 bite 累计
    local origStart = ISEatFoodAction.start
    ISEatFoodAction.start = function(self, ...)
        local res = nil
        if origStart then res = origStart(self, ...) end
        if self and self.item then
            local ok, w = pcall(function() return self.item:getActualWeight() end)
            if ok and type(w) == "number" and w == w then self.__rmPreWeight = w end
            self.__rmBiteTotal = 0
            if RM.Probe and RM.Probe._write then
                pcall(RM.Probe._write, "dbg_start", {
                    "item", tostring(self.item and self.item:getFullType()),
                    "preW", ok and tostring(w) or "nil",
                })
            end
        end
        return res
    end

    -- perform：完整吃完结算，扣除已通过 bite 记账的部分
    local origPerform = ISEatFoodAction.perform
    ISEatFoodAction.perform = function(self, ...)
        local item, player = self.item, self.character
        local preW = self.__rmPreWeight
        local biteTotal = self.__rmBiteTotal or 0
        local itemFullType = nil
        local isFood = false
        if item then
            local okN, n = pcall(function() return item:getFullType() end)
            if okN and n then itemFullType = tostring(n) end
            local okF, rF = pcall(function() return instanceof(item, "Food") end)
            if okF then isFood = (rF == true) end
        end

        local pct = self.percentage
        if type(pct) ~= "number" or pct <= 0 then pct = 1.0 end
        -- B42 percentage 范围 0-1；若 >1 视为 0-100 百分比，归一化
        if pct > 1 then pct = pct / 100 end
        local totalEaten = 0
        if preW and preW > 0 then
            totalEaten = preW * pct
        end
        -- 扣除 bite 已记账部分，避免重复
        local remaining = totalEaten - biteTotal
        if remaining < 0 then remaining = 0 end

        if item and player and remaining > 0 then
            local remainingRatio = (remaining / preW) * 100  -- 剩余部分占原始重量的百分比
            local ok3 = pcall(RM.Core.onEat, item, player, remainingRatio, preW)
            if not ok3 then RM.Log.warn("onEat(perform) 结算失败，已跳过") end
            if RM.Probe and RM.Probe.eatSettle then
                pcall(RM.Probe.eatSettle, item, player, remaining, isFood)
            end
        end

        if RM.Probe and RM.Probe._write then
            pcall(RM.Probe._write, "dbg_perform", {
                "item", itemFullType,
                "preW", tostring(preW),
                "pct", tostring(pct),
                "biteTotal", tostring(biteTotal),
                "remainingKg", tostring(remaining),
            })
        end

        self.__rmPreWeight = nil
        self.__rmBiteTotal = nil

        local res = nil
        if origPerform then
            local okP, r = pcall(origPerform, self, ...)
            if okP then res = r else RM.Log.warn("ISEatFoodAction.perform 原版异常，已跳过") end
        end
        return res
    end

    ISEatFoodAction.__rmHooked = true
    RM.Log.debug("已包装 ISEatFoodAction.eat/start/perform")
end

function RM.Core._hookDrinkActions()
    -- ===== ISDrinkFluidAction：右键菜单"喝"（子菜单全部/一半/四分之一）=====
    -- B42 单机 isClient()=true，update() 不调用 updateEat；实际饮水由 Java DrinkFluid
    -- 在 complete/animEvent 中完成，流体比例不会在 updateEat 内即时变化。
    -- 故改 hook start（记起始比例）+ perform（按差值算饮水量），不依赖 updateEat。
    if ISDrinkFluidAction and not ISDrinkFluidAction.__rmHooked then
        if not ISDrinkFluidAction then
            RM.Log.warn("_hookDrinkActions: ISDrinkFluidAction 不存在，饮水 hook 未安装")
        else
            -- start：记录起始比例 + 容量
            local origStart = ISDrinkFluidAction.start
            ISDrinkFluidAction.start = function(self, ...)
                self.__rmDrinkSettled = nil
                local res = nil
                if origStart then
                    local okS, r = pcall(origStart, self, ...)
                    if okS then res = r end
                end
                if self and self.fluidContainer then
                    local okR, sr = pcall(function() return self.fluidContainer:getFilledRatio() end)
                    local okC, cap = pcall(function() return self.fluidContainer:getCapacity() end)
                    if okR and type(sr) == "number" then self.__rmStartRatio = sr end
                    if okC and type(cap) == "number" then self.__rmCapacity = cap end
                    if RM.Probe and RM.Probe._write then
                        pcall(RM.Probe._write, "dbg_drink_start", {
                            "src", "FluidAction",
                            "startRatio", okR and tostring(sr) or "nil",
                            "cap", okC and tostring(cap) or "nil",
                        })
                    end
                end
                return res
            end

            -- perform：按起始比例与当前比例差值算饮水量
            local origPerform = ISDrinkFluidAction.perform
            ISDrinkFluidAction.perform = function(self, ...)
                RM.Core._settleFluidDrink(self)
                local res = nil
                if origPerform then
                    local okP, r = pcall(origPerform, self, ...)
                    if okP then res = r else RM.Log.warn("ISDrinkFluidAction.perform 原版异常，已跳过") end
                end
                return res
            end

            -- stop：中断饮水也结算（喝一半取消）
            local origStop = ISDrinkFluidAction.stop
            ISDrinkFluidAction.stop = function(self, ...)
                RM.Core._settleFluidDrink(self)
                local res = nil
                if origStop then
                    local okS, r = pcall(origStop, self, ...)
                    if okS then res = r else RM.Log.warn("ISDrinkFluidAction.stop 原版异常，已跳过") end
                end
                return res
            end

            ISDrinkFluidAction.__rmHooked = true
            RM.Log.debug("已包装 ISDrinkFluidAction.start/perform")
        end
    end

    -- ===== ISDrinkFromBottle：从水瓶手动喝水（右键喝水）=====
    -- B42 单机 complete() 会调用 drink()，但 drink() 里的 syncPlayerStats 在单机下
    -- 因 SyncPlayerStatsPacket 为 null 而崩溃。故覆盖 drink() 用 pcall 保护。
    -- 饮水量计算：start 记 preAmount，drink() 执行后用差值算 ml。
    if ISDrinkFromBottle and not ISDrinkFromBottle.__rmHooked then
        if not ISDrinkFromBottle then
            RM.Log.warn("_hookDrinkActions: ISDrinkFromBottle 不存在，水瓶饮水 hook 未安装")
        else
            -- start：记录初始水量
            local origStart = ISDrinkFromBottle.start
            ISDrinkFromBottle.start = function(self, ...)
                self.__rmDrinkSettled = nil
                local res = nil
                if origStart then
                    local okS, r = pcall(origStart, self, ...)
                    if okS then res = r end
                end
                if self and self.item then
                    local ok, fc = pcall(function() return self.item:getFluidContainer() end)
                    if ok and fc then
                        local okA, a = pcall(function() return fc:getAmount() end)
                        if okA and type(a) == "number" then self.__rmPreAmount = a end
                        -- 调试：记录 start 时的水量
                        if RM.Probe and RM.Probe._write then
                            pcall(RM.Probe._write, "dbg_drink_start", {
                                "preAmt", okA and tostring(a) or "nil",
                                "hasFC", ok and "1" or "0",
                            })
                        end
                    end
                end
                return res
            end

            -- 覆盖 drink()：原版逻辑 + pcall 保护 syncPlayerStats
            ISDrinkFromBottle.drink = function(self, food, percentage)
                if percentage > 0.95 then percentage = 1.0 end
                local uses = math.floor(self.uses * percentage + 0.001)
                local drankAny = false
                for i = 1, uses do
                    if not self.character:getInventory():contains(self.item) then break end
                    local isThirsty = false
                    local okT, t = pcall(function() return self.character:getStats():isAboveMinimum(CharacterStat.THIRST) end)
                    if okT then isThirsty = (t == true) end
                    if isThirsty then
                        pcall(function() self.character:getStats():remove(CharacterStat.THIRST, 0.1) end)
                        -- 单机下 SyncPlayerStatsPacket.Stat_Thirst 可能为 Java null，
                        -- 直接传给 syncPlayerStats 会触发 NPE（pcall 抓不住 Java 层异常）
                        local statThirst = nil
                        if SyncPlayerStatsPacket then
                            local okS, s = pcall(function() return SyncPlayerStatsPacket.Stat_Thirst end)
                            if okS and s ~= nil then statThirst = s end
                        end
                        if statThirst ~= nil and syncPlayerStats then
                            pcall(function() syncPlayerStats(self.character, statThirst) end)
                        end
                        local okFC, fc = pcall(function() return self.item:getFluidContainer() end)
                        if okFC and fc then
                            local okA, amt = pcall(function() return fc:getAmount() end)
                            if okA and type(amt) == "number" then
                                local amount = amt - 0.12
                                if amount < 0 then amount = 0 end
                                pcall(function() fc:adjustAmount(amount) end)
                                drankAny = true
                            end
                        end
                    end
                end
                -- 调试：记录 drink 执行情况
                if RM.Probe and RM.Probe._write then
                    pcall(RM.Probe._write, "dbg_drink", {
                        "uses", tostring(uses),
                        "drank", drankAny and "1" or "0",
                        "preAmt", tostring(self.__rmPreAmount),
                    })
                end
                -- drink 执行完后结算饮水量
                RM.Core._settleBottleDrink(self)
            end

            -- perform：兜底结算（complete 可能不触发时，perform 一定会执行）
            local origPerform = ISDrinkFromBottle.perform
            ISDrinkFromBottle.perform = function(self, ...)
                -- 先结算饮水量（在 origPerform 之前，因为 origPerform 可能清理 item）
                RM.Core._settleBottleDrink(self)
                local res = nil
                if origPerform then
                    local okP, r = pcall(origPerform, self, ...)
                    if okP then res = r else RM.Log.warn("ISDrinkFromBottle.perform 原版异常，已跳过") end
                end
                return res
            end

            ISDrinkFromBottle.__rmHooked = true
            RM.Log.debug("已包装 ISDrinkFromBottle.start/drink/perform")
        end
    end
end

-- 水瓶喝水结算：用 start 时记录的 preAmount 与当前 amount 差值算 ml
function RM.Core._settleBottleDrink(self)
    if not self or not self.item or not self.__rmPreAmount then return end
    if self.__rmDrinkSettled then
        self.__rmPreAmount = nil
        return
    end
    local item, player = self.item, self.character
    local preAmount = self.__rmPreAmount
    local fc = nil
    local ok, c = pcall(function() return item:getFluidContainer() end)
    if ok and c then fc = c end
    if not fc then self.__rmPreAmount = nil; return end

    local capacity = nil
    local okCap, cap = pcall(function() return fc:getCapacity() end)
    if okCap and type(cap) == "number" then capacity = cap end

    local okA, postAmount = pcall(function() return fc:getAmount() end)
    local settled = false
    local waterChanged = false
    if okA and type(postAmount) == "number" and postAmount < preAmount then
        waterChanged = true
        local ml = (preAmount - postAmount) * 1000  -- 升转 ml
        if ml > 1 then  -- 阈值过滤：1ml 以下视为误差
            self.__rmDrinkSettled = true
            settled = true
            local okD = pcall(RM.Core.onDrink, player, ml, item)
            if not okD then RM.Log.warn("onDrink(水瓶) 结算失败，已跳过") end
            if RM.Probe and RM.Probe.drink then
                local preRatio = capacity and capacity > 0 and preAmount / capacity or 0
                local postRatio = capacity and capacity > 0 and postAmount / capacity or 0
                pcall(RM.Probe.drink, player, ml, item, capacity, preRatio, postRatio)
            end
        end
    end
    -- 调试：记录 settle 结果
    if RM.Probe and RM.Probe._write then
        pcall(RM.Probe._write, "dbg_settle", {
            "preAmt", tostring(preAmount),
            "postAmt", okA and tostring(postAmount) or "nil",
            "settled", settled and "1" or "0",
        })
    end
    -- 关键：只有水量真的变了才清 preAmt。
    -- perform 可能在 drink 之前执行（B42 顺序），此时水还没扣，
    -- 如果清了 preAmt，drink 里的结算就拿不到初始值了。
    if waterChanged then
        self.__rmPreAmount = nil
    end
end

-- ISDrinkFluidAction 饮水结算：用 start 时记录的起始比例与当前比例差值算 ml
function RM.Core._settleFluidDrink(self)
    if not self or not self.fluidContainer then return end
    if self.__rmDrinkSettled then return end
    local startRatio = self.__rmStartRatio
    local capacity = self.__rmCapacity
    if not startRatio or not capacity then return end
    local item, player = self.item, self.character

    local okP, curRatio = pcall(function() return self.fluidContainer:getFilledRatio() end)
    local settled = false
    if okP and type(curRatio) == "number" and curRatio < startRatio then
        local ml = (startRatio - curRatio) * capacity * 1000  -- 升转 ml
        if ml > 1 then
            self.__rmDrinkSettled = true
            settled = true
            local okD = pcall(RM.Core.onDrink, player, ml, item)
            if not okD then RM.Log.warn("onDrink(FluidAction) 结算失败，已跳过") end
            if RM.Probe and RM.Probe.drink then
                pcall(RM.Probe.drink, player, ml, item, capacity, startRatio, curRatio)
            end
        end
    end
    if RM.Probe and RM.Probe._write then
        pcall(RM.Probe._write, "dbg_settle", {
            "src", "FluidAction",
            "startRatio", tostring(startRatio),
            "curRatio", okP and tostring(curRatio) or "nil",
            "settled", settled and "1" or "0",
        })
    end
end

-- ---------------- 睡眠探针 ----------------
function RM.Core._hookSleepActions()
    -- B42 睡觉走 ISGetOnBedAction（上床动作）
    if not ISGetOnBedAction then
        RM.Log.warn("_hookSleepActions: ISGetOnBedAction 不存在，睡眠 hook 未安装")
        return
    end
    -- start：记录入睡时间
    local origStart = ISGetOnBedAction.start
    ISGetOnBedAction.start = function(self, ...)
        self.__rmSleepStartHours = RM.Core._worldAgeHours()
        if RM.Probe and RM.Probe._write then
            pcall(RM.Probe._write, "sleep", {
                "phase", "start",
                "hours", tostring(self.__rmSleepStartHours),
            })
        end
        if origStart then return pcall(origStart, self, ...) end
    end
    -- stop：醒来时记录睡眠时长
    local origStop = ISGetOnBedAction.stop
    ISGetOnBedAction.stop = function(self, ...)
        local wakeHours = RM.Core._worldAgeHours()
        local startH = self.__rmSleepStartHours
        local duration = (startH and wakeHours) and (wakeHours - startH) or nil
        if RM.Probe and RM.Probe._write then
            pcall(RM.Probe._write, "wake", {
                "phase", "stop",
                "startHours", tostring(startH),
                "wakeHours", tostring(wakeHours),
                "durationHours", duration and string.format("%.2f", duration) or "?",
            })
        end
        if origStop then return pcall(origStop, self, ...) end
    end
    RM.Log.debug("_hookSleepActions: 睡眠探针已安装(ISGetOnBedAction)")
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
    -- S2-5 探针：时间加速/防螺旋触顶时记录（内部按 10 游戏分钟节流）
    if RM.Probe and RM.Probe.clock then
        pcall(RM.Probe.clock, dtHours, steps, math.floor(dtSec) > RM.Core._maxCatchupSteps)
    end
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
        -- S2-1/S2-2/S2-3/S2-8 探针：原生池/体温定时采样（内部节流）
        if RM.Probe and RM.Probe.sample then
            pcall(RM.Probe.sample, player, md, dtSec)
        end
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
        -- S2-6 探针：EveryDays 触发与结算推进（含睡眠期）
        if p and day and RM.Probe and RM.Probe.everydays then
            pcall(RM.Probe.everydays, p, day)
        end
    end)
end

function RM.Core.attach(player)
    if player == nil then return end
    local md = RM.Data.ensurePlayer(player)
    if not md then return end
    RM.Data.loadLive(player)
    RM.History.rebuildCache(md)

    -- NeatUI 仅为 UI 面板依赖（§12.5）：缺失时告警但不阻塞核心模拟逻辑，
    -- 以便 M1 S1/S2 实测（进食/饮水/池采样）正常进行；面板渲染由 RM.UI.makePanel
    -- 自行返回 ok=false 降级。MP 服务端无 client，neatUIOk 恒为 nil，天然放行。
    if RM.State.neatUIOk == false then
        RM.Log.warn("NeatUI 缺失：UI 面板不可用（订阅 Workshop 3508537032 后恢复），核心模拟逻辑照常运行")
    end

    -- Hook 只装一次（§16.3）
    RM.Core._hookEatActions()
    RM.Core._hookDrinkActions()
    RM.Core._hookSleepActions()
    -- 探针会话标记：每次 attach 写一行（含读档）
    if RM.Probe and RM.Probe.session then
        pcall(RM.Probe.session, "attach")
    end
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
