-- ============================================================
-- 模块名   : tests/run_all.lua
-- 职责     : M1 离线单测驱动（lua5.1 可执行）
-- 用法     : lua5.1 tests/run_all.lua
--            （也可由外部驱动注入 BASEDIR/TESTDIR 全局后 dofile）
-- ============================================================

-- ---------------- 路径自举（未注入时按 arg[0] 推导） ----------------
if BASEDIR == nil then
    local here = (arg and arg[0]) or "."
    here = string.gsub(here, "\\", "/")
    local dir = string.match(here, "^(.*)/[^/]+$") or "."
    TESTDIR = dir
    BASEDIR = dir .. "/../RealMetabolism/42/media/lua/shared"
    CLIENTDIR = dir .. "/../RealMetabolism/42/media/lua/client"
    SERVERDIR = dir .. "/../RealMetabolism/42/media/lua/server"
end
local check = function(name, cond, extra)
    if cond then
        _G.__pass = _G.__pass + 1
        print("  PASS  " .. name)
    else
        _G.__fail = _G.__fail + 1
        print("  FAIL  " .. name .. (extra and ("  -- " .. tostring(extra)) or ""))
    end
end
_G.__pass, _G.__fail = 0, 0
_G.check = check

local function approx(a, b, eps)
    return math.abs((a or 0) - (b or 0)) <= (eps or 1e-9)
end
_G.approx = approx

print("== 加载测试桩（stub_env / helpers） ==")
dofile(TESTDIR .. "/stub_env.lua")
dofile(TESTDIR .. "/helpers.lua")

print("== 加载 shared（按依赖序） ==")
dofile(BASEDIR .. "/RM_Config.lua")
dofile(BASEDIR .. "/RM_DataLayer.lua")
dofile(BASEDIR .. "/RM_Scoring.lua")
dofile(BASEDIR .. "/RM_History.lua")

print("== 加载 client + server（桩环境） ==")
dofile(BASEDIR .. "/RM_Config.lua") -- 幂等重入确认
dofile(CLIENTDIR .. "/RM_Theme.lua")
dofile(CLIENTDIR .. "/RM_UIAdapter.lua")
dofile(CLIENTDIR .. "/RM_StatusIcons.lua")
dofile(CLIENTDIR .. "/RM_Panel.lua")
dofile(SERVERDIR .. "/RM_Commands.lua")
dofile(SERVERDIR .. "/RM_Hydration.lua")
dofile(SERVERDIR .. "/RM_Fuel.lua")
dofile(SERVERDIR .. "/RM_Core.lua")

print("== 执行用例 ==")
local tests = {
    "test_scoring.lua",
    "test_datalayer.lua",
    "test_history.lua",
    "test_persist.lua",
    "test_panel_icons.lua",
}
for i = 1, #tests do
    print("-- " .. tests[i])
    dofile(TESTDIR .. "/" .. tests[i])
end

print(string.format("\n== M1 单测结果: %d 通过 / %d 失败 ==", _G.__pass, _G.__fail))
if _G.__fail > 0 then error("M1 unit tests FAILED") end
