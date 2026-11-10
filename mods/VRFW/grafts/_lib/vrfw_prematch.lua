--@section Head
VRFW.prematch = VRFW.prematch or {}
VRFW.prematch.lineups = true
VRFW.prematch.log_on = false
--- Logs the arguments when prematch logging is on.
function VRFW.prematch.log(...)
  if VRFW.prematch.log_on then
    VRFW.host.command(@crc:CMND_VRFW_LOG@, ...)
  end
end
--- True when the game is in online play.
function VRFW.prematch.online()                  -- network match / observer: never change anything
  return funcLuaCommand(3959907440) == true or funcLuaCommand(1191545622) == true
end
-- EVT prematch end ------------------------------------------------------------------------------
