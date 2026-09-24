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

-- ---------------- ISXxx UI 桩（client 文件加载用） ----------------
local ISUIStub = {}
ISUIStub.__index = ISUIStub
function ISUIStub:new(x, y, w, h)
    local o = { x = x or 0, y = y or 0, width = w or 0, height = h or 0,
                visible = true, children = {} }
    setmetatable(o, self)
    return o
end
function ISUIStub:initialise() end
function ISUIStub:instantiate() end
function ISUIStub:addChild(c) table.insert(self.children, c) end
function ISUIStub:removeChild(c) end
function ISUIStub:setVisible(v) self.visible = v end
function ISUIStub:setAlwaysOnTop() end
function ISUIStub:addToUIManager() end
function ISUIStub:removeFromUIManager() end
function ISUIStub:setWidth(w) self.width = w end
function ISUIStub:getWidth() return self.width end
function ISUIStub:setHeight(h) self.height = h end
function ISUIStub:getHeight() return self.height end
function ISUIStub:setX(x) self.x = x end
function ISUIStub:getX() return self.x end
function ISUIStub:setY(y) self.y = y end
function ISUIStub:getY() return self.y end
function ISUIStub:setName(n) self.name = n end
function ISUIStub:drawRect() end
function ISUIStub:drawRectBorder() end
function ISUIStub:drawLine() end
function ISUIStub:drawText() end
function ISUIStub:drawTextureScaled() end
function ISUIStub:setColor() end
function ISUIStub:setTextColor() end

ISUIElement = ISUIStub
ISPanel = setmetatable({ __index = ISUIStub }, { __index = ISUIStub })
function ISPanel:new(x, y, w, h) return ISUIStub.new(self, x, y, w, h) end
ISLabel = setmetatable({ __index = ISUIStub }, { __index = ISUIStub })
function ISLabel:new(x, y, h, text, r, g, b, a, font, b2)
    local o = ISUIStub.new(self, x, y, 100, h)
    o.name = text; return o
end
ISButton = setmetatable({ __index = ISUIStub }, { __index = ISUIStub })
function ISButton:new(x, y, w, h, text, target, onclick)
    local o = ISUIStub.new(self, x, y, w, h)
    o.name = text; return o
end
NIScrollView = nil    -- 测试中不提供，适配器走 ISPanel 兜底
NeatTool = nil         -- 测试中不提供
UIFont = { Small = "Small", Medium = "Medium", Large = "Large" }
