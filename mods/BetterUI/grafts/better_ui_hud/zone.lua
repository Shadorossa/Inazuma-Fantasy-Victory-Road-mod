BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

if BetterUI.preset == nil then
  BetterUI.preset = "limpio"
end
BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, corner_buttons = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

@UI_WRAP@

-- Layers of soccer_zone_menu to hide.
local UI_HIDE = {
  [3408112149] = "zone_hud",
  [2456741170] = "zone_exec",
}
local CMND_OPEN_LAYER = 629267548
local CMND_OPEN_LAYER_ARRAY = 2152386330
local CMND_SET_LAYER_VISIBLE = 711242136

local function UiHidden(layer)
  local f = UI_HIDE[layer]
  return f ~= nil and UiOn(f)
end

local function UiMenuFilter(orig, id, ...)
  if id == CMND_SET_LAYER_VISIBLE then
    local a = Pack(...)
    if a[3] == true and UiHidden(a[1]) then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == CMND_OPEN_LAYER or id == CMND_OPEN_LAYER_ARRAY then
    local layer = ...
    if UiHidden(layer) then
      local r = Pack(orig(id, ...))
      pcall(orig, CMND_SET_LAYER_VISIBLE, layer, 0, false)
      UiLog("hide", layer)
      return r
    end
  end
  return nil
end

UiHookMenuCommand(UiMenuFilter)

-- The zone timer is opened by the engine (no CMND_OPEN_LAYER in the scripts)
local function UiAfterLayer(a1, a2)
  if UiHidden(a1) and type(funcLuaMenuCommand) == "function" then
    funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, a1, a2 or 0, false)
    UiLog("hide_cb", a1)
  end
end
UiWrapCallback("OnSetupLayer", UiAfterLayer)
UiWrapCallback("OnOpenLayer", UiAfterLayer)
