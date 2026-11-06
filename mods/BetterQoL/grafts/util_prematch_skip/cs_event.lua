-- BetterQoL in-match cut-in skip, event_menu side (docs/game/match/cutin-skip.md). event_menu is open while a technique
-- cut-in plays; its Step reads the fresh press of CMD_BETTERQOL_CUTIN_SKIP and asks CMND_BETTERQOL_CUTIN_SKIP, which
-- decides and ends the event (BetterQoL's scripts\prematch_skip.lua). Never in a network match or for an observer, never
-- while the game is paused, nor just after the pause closes (its confirm press). Wrapper only; no engine call at chunk load.
local util_cs = {
  INPUT = @crc:CMND_CHECK_INPUT_CMD@,
  KEY = @crc:CMD_BETTERQOL_CUTIN_SKIP@,
  CTRLS = {2917185202 --[[EVENT_CTRL_VISUAL]], 3237690481 --[[EVENT_CTRL_TALK]], 517748912 --[[EVENT_CTRL_RPG_FUNC]]},
  SKIP = @crc:CMND_BETTERQOL_CUTIN_SKIP@,
  PAUSED = 3618071757,                    -- CMND_IS_GAME_PAUSE
  NETWORK = 3959907440,                   -- network match (the pre-match skip's test)
  OBSERVER = 1191545622,                  -- observer (the pre-match skip's test)
  DT = 2839043456,                        -- frame seconds
  LOG = 3661580131,                       -- CMND_EVT_LOG
  AFTER_PAUSE_S = 0.25,
  quiet = 0,
  ask_again = false,
  prev_step = Step,
}

function util_cs.Pressed()
  for _, ctrl in ipairs(util_cs.CTRLS) do
    local ok, on = pcall(funcLuaCommand, util_cs.INPUT, ctrl, util_cs.KEY)
    if ok and on == true then
      return true
    end
  end
  return false
end

function util_cs.Step()
  if funcLuaCommand(util_cs.PAUSED) == true then
    util_cs.quiet = util_cs.AFTER_PAUSE_S
    return
  end
  if util_cs.quiet > 0 then
    util_cs.quiet = util_cs.quiet - (funcLuaCommand(util_cs.DT) or 0)
    return
  end
  if not util_cs.ask_again and not util_cs.Pressed() then
    return
  end
  if funcLuaCommand(util_cs.NETWORK) == true or funcLuaCommand(util_cs.OBSERVER) == true then
    util_cs.ask_again = false
    return
  end
  local ok, answer = pcall(funcLuaCommand, util_cs.SKIP)
  util_cs.ask_again = ok and answer == 2
end

function Step()
  local r = util_cs.prev_step()
  local ok, err = pcall(util_cs.Step)
  if not ok then
    pcall(funcLuaCommand, util_cs.LOG, "cut-in skip:", "step error", tostring(err))
  end
  return r
end
