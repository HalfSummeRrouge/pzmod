-- ============================================================
-- 模块名   : tests/helpers.lua
-- 职责     : 测试用玩家/物品桩 + 模拟引擎序列化的深拷贝
-- ============================================================

-- 玩家桩：getModData 持真表；getNutrition 返回固定宏量
function mkPlayer(calories, carbs)
    local p = {}
    p.md = {}
    local n = {
        getCalories = function() return calories or 200 end,
        getCarbohydrates = function() return carbs or 250 end,
        getLipids = function() return 50 end,
        getProteins = function() return 60 end,
        getWeight = function() return 75 end,
    }
    function p:getModData() return self.md end
    function p:getNutrition() return n end
    function p:isSprinting() return false end
    function p:isRunning() return false end
    function p:isSneaking() return false end
    function p:isMoving() return false end
    function p:getMaxWeight() return 50 end
    function p:getInventoryWeight() return 10 end
    return p
end

-- 物品桩
function mkItem(fullName, displayName, weightKg, thirstChange, cls)
    local it = {}
    it.__rmClass = cls or "Food"
    function it:getFullName() return fullName end
    function it:getFullType() return fullName end
    function it:getDisplayName() return displayName end
    function it:getActualWeight() return weightKg end
    function it:getThirstChange() return thirstChange or 0 end
    return it
end

-- 模拟 Kahlua 序列化：只保留基础类型（number/string/boolean/table）
function plainCopy(v)
    local t = type(v)
    if t ~= "table" then
        if t == "number" or t == "string" or t == "boolean" or t == "nil" then return v end
        return nil
    end
    local out = {}
    for k, x in pairs(v) do
        local c = plainCopy(x)
        if c ~= nil then out[k] = c end
    end
    return out
end
