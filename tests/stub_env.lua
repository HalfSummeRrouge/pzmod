-- ============================================================
-- 模块名   : tests/stub_env.lua
-- 职责     : 离线单测的 PZ 环境桩（Events/getPlayer/instanceof 等）
-- 说明     : 仅测试用，不属于 MOD 发布物
-- ============================================================
Events = {}
local evnames = { "OnCreatePlayer", "OnGameStart", "OnPlayerUpdate", "EveryDays",
                  "OnKeyKeepPressed", "OnKeyPressed", "OnTick", "OnKeyPressed" }
for i = 1, #evnames do
    Events[evnames[i]] = { Add = function(fn) end }
end

function getPlayer()
    return _G.__testPlayer or nil
end

-- 桩：按 item.__rmClass 判类（onEat 用 pcall 包裹调用）
function instanceof(obj, cls)
    return (obj ~= nil) and (obj.__rmClass == cls) or false
end

Keyboard = { KEY_N = 46 }
function getTimestampMs() return 0 end
function getText(key) return key end

function getGameTime()
    local t = {}
    function t:getWorldAgeHours() return 24.0 * 10 end
    function t:getDaysSinceStart() return 10 end
    return t
end

CharacterStat = { ENDURANCE = "ENDURANCE" }
