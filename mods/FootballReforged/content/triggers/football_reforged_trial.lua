local SET_BIT = 3258400760        -- CMND_SET_GLOBAL_BIT_FLAG
local SET_BYTE = 187123515        -- CMND_SET_GLOBAL_BYTE_FLAG
local LOG = 519897777               -- CMND_VRFW_LOG (loader; fails quietly without it)
local CLOCK = 2941906460            -- CMND_VRFW_CLOCK_MS (framework: monotonic real-time ms)
local F_DONE = {{v1}}           -- FOOTBALL_REFORGED_TRIAL_{{v2}} (bank-0 bit)
local B_RESULT = 4237444583     -- FOOTBALL_REFORGED_TRIAL_RESULT: 1 running, 2 passed, 3 failed
local B_SECS = 121581464         -- FOOTBALL_REFORGED_TRIAL_SECS: best seconds (hold) / goals / steals reached
local B_GAME = 2804103558
local TRIAL_INDEX = {{v3}}
local KEY_PLAYED = 2201308096  -- param FOOTBALL_REFORGED_TRIAL_PLAYED
local TXT_OK = {{v4}}         -- menu_text {{name}}_ok
local JUDGE = 439974078
local TEAM_USER, TEAM_RIVAL = 4108050209, 2212294583  -- trigger team keys "0" / "1"
local done, start_ms = false, 0
local function Log(...)
  pcall(funcLuaCommand, LOG, "{{name}}", ...)
end
local function Init()
  done, start_ms = false, funcLuaCommand(CLOCK)
  funcLuaCommand(SET_BYTE, B_RESULT, 1)
  funcLuaCommand(SET_BYTE, B_GAME, TRIAL_INDEX)
  Log("init")
end
local function Rules(no_shoot, hunt)
  if no_shoot then
    pcall(SetSoccerEnableNoShootExecTeam, TEAM_USER, true)
  end
  if hunt then
    pcall(SetRoughPlayTeamActRate, TEAM_RIVAL, 1, 1)
    pcall(SetSoccerAITeamSkillActRate, TEAM_RIVAL, 1)
  end
  Log("rules", "no_shoot", tostring(no_shoot), "hunt", tostring(hunt), type(SetSoccerEnableNoShootExecTeam))
end
local function FullTime(...)
  local okj, armed, _, _, _, result = pcall(funcLuaCommand, JUDGE, 2)
  if okj and armed == true and result == 2 then
    funcLuaCommand(SET_BIT, F_DONE, true)
    funcLuaCommand(SET_BYTE, B_RESULT, 2)
  end
  local ok, bit = pcall(funcLuaCommand, 941426960 --[[CMND_GET_GLOBAL_BIT_FLAG]], F_DONE)
  done = ok and bit == true
  if not done then
    funcLuaCommand(SET_BYTE, B_RESULT, 3)
  end
  Log("full time", done and "passed" or "failed", "ms", funcLuaCommand(CLOCK) - start_ms, ...)
end
function RunCmd_Soccer1()
  -- 249 match init
  Init()
  Rules({{t2}}, true)
end
function RunCmd_Soccer2()
  FullTime()
end
function RunCmd_Soccer3()
  Log("result 202: user won")
end
function RunCmd_Soccer4()
  Log("result 202: user lost")
end
function RunCmd_Soccer5()
  Log("result 202: draw")
end
