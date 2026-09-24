-- Probe：CSV 行格式 / 事件覆盖 / 节流 / 文件 API 缺失降级 / 集成挂点
local P = RM.Probe

-- ---- 桩：getFileWriter 捕获写入行（三参数签名：path, createIfNull, append） ----
local lines = {}
local fileAPI = true
local function installFileStub()
    lines = {}
    getFileWriter = function(path, createIfNull, append)
        assert(path == "RealMetabolismProbe.log" and createIfNull == true and append == true, "路径/创建/追加模式")
        local w = {}
        function w:write(s) lines[#lines + 1] = string.gsub(s, "\n$", "") end
        function w:close() w.closed = true end
        return w
    end
end

local function countType(t)
    local n = 0
    for i = 1, #lines do
        if string.find(lines[i], "," .. t .. ",") or string.match(lines[i], "," .. t .. "$") then n = n + 1 end
    end
    return n
end

-- ---- 1) 事件写入与行格式 ----
installFileStub()
P.key(46, true)
check("probe: key 事件写入", #lines == 1)
check("probe: 行格式 worldH,type,kv", string.match(lines[1], "^[%d%.]+,key,key=N;code=46%.00;open=1%.00$") ~= nil)

P.session("attach")
check("probe: session 行含 kind", string.match(lines[2], "^[%d%.]+,session,kind=attach$") ~= nil)

-- ---- 2) bite/eat/drink/hydrate 内容（mkPlayer/mkItem 桩） ----
lines = {}
local pE = mkPlayer()
local apple = mkItem("Base.Apple", "Apple", 0.3, 0, "Food")
P.bite(apple, pE, 0.3, 0.28)
check("probe: bite 含 item/重量/池", string.find(lines[1], "item=Base%.Apple") ~= nil
    and string.find(lines[1], "preKg=0%.30") ~= nil
    and string.find(lines[1], "carbs=250%.00") ~= nil)
P.eatSettle(apple, pE, 0.15, true)
check("probe: eat 克重换算", string.find(lines[2], "grams=150%.00") ~= nil
    and string.find(lines[2], "isFood=1") ~= nil)
P.drink(pE, 250, mkItem("Base.WaterBottleFull", "Water", 1.0, -50), 250, 1.0, 0.0)
check("probe: drink 含容量与比例", string.find(lines[3], "ml=250%.00") ~= nil
    and string.find(lines[3], "capacity=250%.00") ~= nil)
RM.State.live.hydration = 40
P.hydrate(apple, pE, -20, 20, 200, 40)
check("probe: hydrate 前后水合", string.find(lines[4], "thirstChange=%-20%.00") ~= nil
    and string.find(lines[4], "hydBefore=40%.00") ~= nil)

-- ---- 3) sample 节流（60 游戏秒） ----
lines = {}
P._sampleAccum = 0
P.sample(pE, nil, 30)
P.sample(pE, nil, 30)          -- 60 累计 → 触发
P.sample(pE, nil, 59)          -- 未到 → 不触发
check("probe: sample 60s 节流", countType("sample") == 1)
check("probe: sample 行含池与体温 na", string.find(lines[1], "cal=200%.00") ~= nil
    and string.find(lines[1], "temp=na") ~= nil)

-- ---- 4) clock：大跳记录 + 10 游戏分钟节流；小跳忽略 ----
lines = {}
P._clockAccum = 0
P.clock(0.001, 1, false)       -- 常规帧 → 忽略
check("probe: 常规帧不记录", #lines == 0)
P.clock(0.10, 360, false)      -- 大跳 → 记录
P.clock(0.10, 360, false)      -- 大跳但节流窗内 → 不记
check("probe: 大跳记录且节流", countType("clock") == 1)
P.clock(0.001, 3600, true)    -- 触顶 → 恒记录（不受节流）
check("probe: 触顶恒记录", countType("clock") == 2
    and string.find(lines[2], "capped=1") ~= nil)

-- ---- 5) everydays ----
lines = {}
local pDay = mkPlayer()
local mdDay = RM.Data.ensurePlayer(pDay)
RM.History.settle(pDay, 12)
P.everydays(pDay, 12)
check("probe: everydays 含结算推进", string.find(lines[1], "day=12%.00") ~= nil
    and string.find(lines[1], "lastSettleDay=12") ~= nil
    and string.find(lines[1], "history=1") ~= nil)

-- ---- 6) 文件 API 缺失 → console 降级不炸、只告警一次 ----
lines = {}
getFileWriter = nil
P._fileWarned = false
P.key(46, false)
P.key(46, true)
check("probe: 文件缺失不抛错", true)   -- 走到此处即未抛
check("probe: 文件缺失零写入", #lines == 0)

-- ---- 7) enabled=false → 完全静默 ----
installFileStub()
RM.Config.probe.enabled = false
P.key(46, true)
P.bite(apple, pE, 0.3, 0.2)
P.clock(0.5, 1800, true)
check("probe: 关闭后零写入", #lines == 0)
RM.Config.probe.enabled = true

-- ---- 8) 集成：onEat → hydrate 挂点自动触发 ----
installFileStub()
local soup = mkItem("Base.CannedSoup", "Canned Soup", 0.15, -20, "Food")
RM.State.live.hydration = 40
RM.Core.onEat(soup, mkPlayer(), 100, 0.15)
check("probe: 集成 onEat 触发 hydrate 行", countType("hydrate") == 1
    and string.find(lines[1], "ml=200%.00") ~= nil
    and string.find(lines[1], "hydAfter=60%.00") ~= nil)

getFileWriter = nil
