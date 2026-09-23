-- ============================================================
-- 模块名   : RM_Probe
-- 职责     : S1/S2 上机实测自动采集器（技术文档 §18）：把进食/饮水/
--            原生池/时间加速/事件触发/按键数据追加写入 CSV 文件，
--            玩家退出游戏后离线分析（清单见 livecheck 文档）
-- 所属里程碑: M1（实测辅助工具；M4 发布前默认关闭或整文件移除）
-- 对外接口 : RM.Probe.session / bite / eatSettle / drink / hydrate /
--            sample / clock / everydays / key（全部安全空转）
-- 依赖     : RM_Config / RM_DataLayer（shared）；由 RM_Core /
--            RM_Hydration（server）与 RM_Panel（client）挂点调用
-- 输出     : Zomboid 用户目录 RealMetabolismProbe.csv（追加，勿手改）
-- 行格式   : worldHours,事件类型,键=值;键=值...
-- ============================================================
RM = RM or {}
RM.Probe = {}

local FILE = "RealMetabolismProbe.csv"

-- 运行时状态（非持久化）
RM.Probe._fileWarned = false    -- 文件 API 不可用只告警一次
RM.Probe._sampleAccum = 0       -- 池采样节流累计（游戏秒）
RM.Probe._clockAccum = 0        -- 时钟事件节流累计（游戏小时）

local function enabled()
    return (RM.Config.probe and RM.Config.probe.enabled) == true
end

local function num(v)
    if v == nil then return "na" end
    if type(v) == "number" then return string.format("%.2f", v) end
    return tostring(v)
end

-- 只读辅助（全部 pcall 防御，缺失记 na）
function RM.Probe._itemName(item)
    if not item then return "na" end
    local ok, n = pcall(function() return item:getFullName() end)
    if ok and n then return tostring(n) end
    return "na"
end

function RM.Probe._pools(player)
    if not player then return {} end
    local ok, r = pcall(RM.Data.readNutrition, player)
    if ok and type(r) == "table" then return r end
    return {}
end

function RM.Probe._coreTemp(player)
    if not player then return "na" end
    local ok, t = pcall(function() return player:getCoreTemperature() end)
    if ok and type(t) == "number" then return string.format("%.2f", t) end
    return "na"
end

-- 食物年龄（S1-6 腐烂判定输入；getter 缺失记 na）
function RM.Probe._foodAge(item)
    if not item then return "na" end
    local ok, a = pcall(function() return item:getAge() end)
    if ok and type(a) == "number" then return string.format("%.1f", a) end
    return "na"
end

-- ---------------- 行写入 ----------------
-- kv: 扁平数组 { key1, val1, key2, val2, ... }
function RM.Probe._write(evType, kv)
    if not enabled() then return end
    local ok, err = pcall(function()
        local h = "na"
        local okH, hh = pcall(function() return getGameTime():getWorldAgeHours() end)
        if okH and type(hh) == "number" then h = string.format("%.3f", hh) end
        local parts = {}
        for i = 1, #kv, 2 do
            parts[#parts + 1] = tostring(kv[i]) .. "=" .. num(kv[i + 1])
        end
        local line = h .. "," .. evType
        if #parts > 0 then line = line .. "," .. table.concat(parts, ";") end

        -- 文件追加：Kahlua 全局 getFileWriter；兼容两代参数签名
        local w
        local okW, ww = pcall(function() return getFileWriter(FILE, true) end)
        if okW and ww then
            w = ww
        else
            local okW2, ww2 = pcall(function() return getFileWriter(FILE, true, false) end)
            if okW2 and ww2 then w = ww2 end
        end
        if w then
            w:write(line .. "\n")
            w:close()
        else
            if not RM.Probe._fileWarned then
                RM.Probe._fileWarned = true
                RM.Log.warn("Probe: getFileWriter 不可用，采集数据回显 console.txt（降级，仅告警一次）")
            end
            RM.Log.info("[probe] " .. line)
        end
        if RM.Config.debug then RM.Log.debug("[probe] " .. line) end
    end)
    if not ok then RM.Log.warn("Probe 写入异常: " .. tostring(err)) end
end

-- ---------------- 事件入口（挂点全部 pcall 调用，本层再自防一层） ----------------

-- 会话标记：进世界/attach
function RM.Probe.session(kind)
    RM.Probe._write("session", { "kind", kind })
end

-- 每口咬合（S1-1 重量线性 / S2-4 池增减时机）
function RM.Probe.bite(item, player, preKg, postKg)
    local p = RM.Probe._pools(player)
    RM.Probe._write("bite", {
        "item", RM.Probe._itemName(item),
        "preKg", num(preKg), "postKg", num(postKg),
        "cal", num(p.calories), "carbs", num(p.carbohydrates),
    })
end

-- 完成进食结算（S1-2 重复计算 / S1-3 分次剩食 / S1-6 腐烂 / S1-7 判类）
function RM.Probe.eatSettle(item, player, eatenKg, isFood)
    local p = RM.Probe._pools(player)
    RM.Probe._write("eat", {
        "item", RM.Probe._itemName(item),
        "grams", num((eatenKg or 0) * 1000.0),
        "isFood", isFood and 1 or 0,
        "age", RM.Probe._foodAge(item),
        "cal", num(p.calories), "carbs", num(p.carbohydrates),
    })
end

-- 喝流体（S1-5 容量单位与填充比差值）
function RM.Probe.drink(player, ml, item, capacity, preRatio, postRatio)
    local p = RM.Probe._pools(player)
    RM.Probe._write("drink", {
        "ml", num(ml), "capacity", num(capacity),
        "preRatio", num(preRatio), "postRatio", num(postRatio),
        "item", RM.Probe._itemName(item),
        "cal", num(p.calories), "carbs", num(p.carbohydrates),
    })
end

-- 含水食物补水（S1-4 ThirstChange → ml 换算）
function RM.Probe.hydrate(item, player, thirstChange, quenchU, ml, hydBefore)
    local after = RM.State.live and RM.State.live.hydration
    RM.Probe._write("hydrate", {
        "item", RM.Probe._itemName(item),
        "thirstChange", num(thirstChange), "quenchU", num(quenchU), "ml", num(ml),
        "hydBefore", num(hydBefore), "hydAfter", num(after),
    })
end

-- 池定时采样（S2-1/2/2-3 池范围 / S2-8 体温；节流 sampleEveryGameSec）
function RM.Probe.sample(player, md, dtSec)
    local conf = RM.Config.probe or {}
    RM.Probe._sampleAccum = RM.Probe._sampleAccum + (dtSec or 0)
    local every = conf.sampleEveryGameSec or 60
    if RM.Probe._sampleAccum < every then return end
    RM.Probe._sampleAccum = 0
    local p = RM.Probe._pools(player)
    RM.Probe._write("sample", {
        "cal", num(p.calories), "carbs", num(p.carbohydrates),
        "lipids", num(p.lipids), "proteins", num(p.proteins),
        "weightKg", num(p.weightKg),
        "temp", RM.Probe._coreTemp(player),
        "hyd", num(RM.State.live and RM.State.live.hydration),
        "posture", RM.State.fuel and RM.State.fuel.posture or "na",
    })
end

-- 时间加速/防螺旋（S2-5）：单帧大跳或触顶才记录；同类按 10 游戏分钟节流
function RM.Probe.clock(dtHours, steps, capped)
    local big = (dtHours or 0) >= 0.05      -- 单帧 ≥3 游戏分钟 = 加速中
    if not big and not capped then return end
    if not capped then
        RM.Probe._clockAccum = RM.Probe._clockAccum + (dtHours or 0)
        if RM.Probe._clockAccum < 0.1667 then return end
    end
    RM.Probe._clockAccum = 0
    RM.Probe._write("clock", {
        "dtHours", num(dtHours), "steps", num(steps),
        "capped", capped and 1 or 0,
        "hyd", num(RM.State.live and RM.State.live.hydration),
    })
end

-- 每日结算触发（S2-6 睡眠期 EveryDays）
function RM.Probe.everydays(player, day)
    local md = RM.Data.ensurePlayer(player)
    RM.Probe._write("everydays", {
        "day", num(day),
        "lastSettleDay", md and num(md.lastSettleDay) or "na",
        "history", md and #(md.history or {}) or 0,
    })
end

-- 面板按键（S2-7 单次触发验证）
function RM.Probe.key(code, openAfter)
    RM.Probe._write("key", { "code", num(code), "open", openAfter and 1 or 0 })
end
