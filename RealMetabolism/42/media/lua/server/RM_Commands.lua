-- ============================================================
-- 模块名   : RM_Commands
-- 职责     : 写操作封装（单机本地执行，MP 权威预留 §14）：
--            调试/外部触发的 modData 写入一律走此层，带 isAuthority
--            门控与 clamp，禁止散落直写
-- 所属里程碑: M1
-- 对外接口 : RM.Commands.isAuthority / setHydration / addMicro /
--            addWater / dump
-- 依赖     : shared 全部 + RM.Core.isAuthority（server）
-- ============================================================
RM = RM or {}
RM.Commands = {}
local clamp = RM.Util.clamp

-- 权威判定：单机恒 true（MP 改服务端权威，第一版不引网络代码 §14）
function RM.Commands.isAuthority(player)
    if RM.Core and RM.Core.isAuthority then return RM.Core.isAuthority(player) end
    return true
end

function RM.Commands.setHydration(player, v)
    if not RM.Commands.isAuthority(player) or type(v) ~= "number" then return false end
    local md = RM.Data.ensurePlayer(player)
    if not md then return false end
    RM.State.live.hydration = clamp(v, 0, 100)
    md.hydration = RM.State.live.hydration
    return true
end

function RM.Commands.addMicro(player, key, v)
    if not RM.Commands.isAuthority(player) or type(v) ~= "number" then return false end
    local known = false
    for i, k in ipairs(RM.Config.microKeys) do
        if k == key then known = true; break end
    end
    if not known then return false end
    RM.Data.addMicro(player, key, v)
    return true
end

function RM.Commands.addWater(player, ml)
    if not RM.Commands.isAuthority(player) or type(ml) ~= "number" then return false end
    RM.Data.addWater(player, ml, 1.0)
    return true
end

-- 调试 dump（-debug 用，§17）
function RM.Commands.dump(player)
    local md = RM.Data.ensurePlayer(player)
    if not md then return nil end
    local lines = {}
    table.insert(lines, "schema=" .. tostring(md.schema))
    table.insert(lines, "hydration=" .. tostring(md.hydration))
    table.insert(lines, "energyFeedback=" .. tostring(md.energyFeedback))
    local parts = {}
    for i, k in ipairs(RM.Config.microKeys) do
        parts[i] = k .. "=" .. string.format("%.1f", md.micro[k] or 0)
    end
    table.insert(lines, "micro=" .. table.concat(parts, ", "))
    table.insert(lines, "lastSettleDay=" .. tostring(md.lastSettleDay))
    local out = table.concat(lines, "\n")
    RM.Log.info("\n" .. out)
    return out
end
