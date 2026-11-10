-- EVT better_ui minimap
BetterUI = type(BetterUI) == "table" and BetterUI or {}
BetterUI.minimap_layer = 2557421440       -- soccer00_03_minimap
BetterUI.minimap_up = 190                 -- layout units up (0 = retail position)
BetterUI.minimap_right = 0                -- layout units right (negative = left)

local function place_minimap(layer, idx)
  if layer ~= BetterUI.minimap_layer or BetterUI.preset == "off" then
    return
  end
  if type(funcLuaMenuCommand) ~= "function" then
    return
  end
  pcall(funcLuaMenuCommand, 1389957207 --[[CMND_SET_LAYER_LOCAL_POS]], layer, BetterUI.minimap_right, BetterUI.minimap_up, 0, idx or 0)
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
