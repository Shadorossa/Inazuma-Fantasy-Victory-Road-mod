-- level_trace (VRFW diagnostic): one log line per focused player and level in the item use menu when he is not an owned
-- card (handle pool above 0, the avatar is one) or the game says he cannot level up. Shows the values the gauge reads.
-- No engine call at load time.
if type(UpdateListItemGauge) == "function" then
  local retail_update_gauge = UpdateListItemGauge
  local logged = {}

  local function trace_level(handle)
    local level = funcLuaCommand(1131797651, handle, 0)
    local exp = funcLuaCommand(1131797651, handle, 5)
    local cap = funcLuaCommand(1131797651, handle, 29)
    local need = funcLuaMenuCommand(2018907327, handle, level)
    local pool = math.floor(handle / 0x1000) % 16
    if pool == 0 and level < cap and need > 0 then
      return
    end
    local line = string.format("VRFW item_use level trace: handle 0x%X pool %d level %d exp %d cap %d need %d",
      handle, pool, level, exp, cap, need)
    if not logged[line] then
      logged[line] = true
      funcLuaCommand(VRFW_Cmd.EVT_LOG, line)
    end
  end

  function UpdateListItemGauge(layer, index, handle, focused, can_use)
    retail_update_gauge(layer, index, handle, focused, can_use)
    if focused == true and type(handle) == "number" and handle ~= 0 then
      pcall(trace_level, handle)
    end
  end
end
