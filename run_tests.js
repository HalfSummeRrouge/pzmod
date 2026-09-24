// RealMetabolism 离线测试运行器（Fengari / Lua 5.1）
// 用法: node run_tests.js
const f = require('fengari');
const { lauxlib, lua, lualib } = f;
const fs = require('fs');
const path = require('path');
const to_luastring = f.to_luastring;
const to_js = f.to_jsstring;

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

// print → console.log
lua.lua_pushcfunction(L, function(L) {
  const n = lua.lua_gettop(L);
  const parts = [];
  for (let i = 1; i <= n; i++) {
    if (lua.lua_isstring(L, i)) parts.push(to_js(lua.lua_tostring(L, i)));
    else if (lua.lua_isnumber(L, i)) parts.push(String(lua.lua_tonumber(L, i)));
    else if (lua.lua_isboolean(L, i)) parts.push(lua.lua_toboolean(L, i) ? 'true' : 'false');
    else parts.push('?');
  }
  console.log(parts.join('\t'));
  return 0;
});
lua.lua_setglobal(L, to_luastring('print'));

// 测试断言框架
lua.lua_pushnumber(L, 0); lua.lua_setglobal(L, to_luastring('__pass'));
lua.lua_pushnumber(L, 0); lua.lua_setglobal(L, to_luastring('__fail'));

lua.lua_pushcfunction(L, function(L) {
  try {
    const name = to_js(lauxlib.luaL_checkstring(L, 1));
    const cond = lua.lua_toboolean(L, 2);
    lua.lua_getglobal(L, to_luastring('__pass'));
    const pass = lua.lua_tonumber(L, -1); lua.lua_pop(L, 1);
    lua.lua_getglobal(L, to_luastring('__fail'));
    const fail = lua.lua_tonumber(L, -1); lua.lua_pop(L, 1);
    if (cond) {
      lua.lua_pushnumber(L, pass + 1);
      lua.lua_setglobal(L, to_luastring('__pass'));
      console.log('  PASS  ' + name);
    } else {
      lua.lua_pushnumber(L, fail + 1);
      lua.lua_setglobal(L, to_luastring('__fail'));
      console.log('  FAIL  ' + name);
    }
  } catch (e) {
    console.error('CHECK JS ERROR:', e.message);
  }
  return 0;
});
lua.lua_setglobal(L, to_luastring('check'));

lua.lua_pushcfunction(L, function(L) {
  const a = lua.lua_tonumber(L, 1) || 0;
  const b = lua.lua_tonumber(L, 2) || 0;
  const eps = lua.lua_tonumber(L, 3) || 1e-9;
  lua.lua_pushboolean(L, Math.abs(a - b) <= eps);
  return 1;
});
lua.lua_setglobal(L, to_luastring('approx'));

function safeToJs(s) {
  if (!s) return 'null';
  try { return to_js(s); } catch (e) { return String(s); }
}

function runFile(p) {
  const code = fs.readFileSync(path.resolve(p), 'utf8');
  const s = lauxlib.luaL_dostring(L, to_luastring(code));
  if (s !== 0) {
    const t = lua.lua_type(L, -1);
    let errStr = 'null';
    if (lua.lua_isstring(L, -1)) errStr = safeToJs(lua.lua_tostring(L, -1));
    else if (lua.lua_isnumber(L, -1)) errStr = String(lua.lua_tonumber(L, -1));
    console.error('ERROR in ' + p + ' (type=' + t + '):', errStr);
    process.exit(1);
  }
}

const files = [
  'tests/stub_env.lua',
  'tests/helpers.lua',
  'RealMetabolism/42/media/lua/shared/RM_Config.lua',
  'RealMetabolism/42/media/lua/shared/RM_DataLayer.lua',
  'RealMetabolism/42/media/lua/shared/RM_Scoring.lua',
  'RealMetabolism/42/media/lua/shared/RM_History.lua',
  'RealMetabolism/42/media/lua/shared/RM_Probe.lua',
  'RealMetabolism/42/media/lua/client/RM_Theme.lua',
  'RealMetabolism/42/media/lua/client/RM_UIAdapter.lua',
  'RealMetabolism/42/media/lua/client/RM_StatusIcons.lua',
  'RealMetabolism/42/media/lua/client/RM_Panel.lua',
  'RealMetabolism/42/media/lua/server/RM_Commands.lua',
  'RealMetabolism/42/media/lua/server/RM_Hydration.lua',
  'RealMetabolism/42/media/lua/server/RM_Fuel.lua',
  'RealMetabolism/42/media/lua/server/RM_Core.lua',
];
for (const f of files) runFile(f);

const tests = [
  'tests/test_scoring.lua',
  'tests/test_datalayer.lua',
  'tests/test_history.lua',
  'tests/test_persist.lua',
  'tests/test_panel_icons.lua',
  'tests/test_probe.lua',
];
for (const t of tests) {
  console.log('-- ' + t);
  runFile(t);
}

lua.lua_getglobal(L, to_luastring('__pass'));
const pass = lua.lua_tonumber(L, -1);
lua.lua_getglobal(L, to_luastring('__fail'));
const fail = lua.lua_tonumber(L, -1);
console.log('\n== M1 单测结果: ' + pass + ' 通过 / ' + fail + ' 失败 ==');
process.exit(fail > 0 ? 1 : 0);
