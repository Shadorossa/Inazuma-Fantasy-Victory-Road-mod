--@section Head --- Advanced: Prematch table with logging and online checks.
--- Advanced: Namespace: prematch hooks, flags and helpers.
VRFW.prematch = VRFW.prematch or {}
--- Advanced: Flag, true by default; not read inside this file.
VRFW.prematch.lineups = true
--- Internal: Flag that turns prematch logging on; false by default.
VRFW.prematch.log_on = false
--- Advanced: Logs the arguments when prematch logging is on.
function VRFW.prematch.log(...)
  if VRFW.prematch.log_on then
    VRFW.host.command(@crc:CMND_VRFW_LOG@, ...)
  end
end
--- Advanced: True when the game is in online play.
function VRFW.prematch.online()                  -- network match / observer: never change anything
  return funcLuaCommand(3959907440) == true or funcLuaCommand(1191545622) == true
end
-- EVT prematch end ------------------------------------------------------------------------------
