-- EVT better_ui minimap
BetterUI = type(BetterUI) == "table" and BetterUI or {}
BetterUI.minimap_layer = @crc:soccer00_03_minimap@       -- soccer00_03_minimap
BetterUI.minimap_up = 190                 -- layout units up (0 = retail position)
BetterUI.minimap_right = 0                -- layout units right (negative = left)

local function place_minimap(layer, idx)
  if layer ~= BetterUI.minimap_layer then
    return
  end
  if type(funcLuaMenuCommand) ~= "function" then
    return
  end
  -- The rival gauges option keeps the rival's meters on screen, so the minimap keeps its retail place.
  if type(VRFW) == "table" and type(VRFW.host) == "table"
      and VRFW.host.command(@crc:CMND_VRFW_OPTION_GET@, "BetterUI.rival_gauges") == 1 then
    return
  end
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_LOCAL_POS@, layer, BetterUI.minimap_right, BetterUI.minimap_up, 0, idx or 0)
end

local previous_on_setup_layer = OnSetupLayer
function OnSetupLayer(a1, a2)
  local r = previous_on_setup_layer(a1, a2)
  place_minimap(a1, a2)
  return r
end

local previous_on_open_layer = OnOpenLayer
function OnOpenLayer(a1, a2)
  local r = previous_on_open_layer(a1, a2)
  place_minimap(a1, a2)
  return r
end
