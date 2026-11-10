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

-- Layers of soccer_menu to hide.
local UI_HIDE_LAYERS = {
  [2546223804] = 1,
  [1829362274] = 1,
  [1442388144] = 1,
  [2941575910] = 2,
}
local CMND_OPEN_LAYER = 629267548
local CMND_OPEN_LAYER_ARRAY = 2152386330
local CMND_SET_LAYER_VISIBLE = 711242136

local function UiHideLayer(orig, layer)
  for i = 0, UI_HIDE_LAYERS[layer] - 1 do
    pcall(orig, CMND_SET_LAYER_VISIBLE, layer, i, false)
  end
end

local function UiMenuFilter(orig, id, ...)
  if not UiOn("enemy_meters") then
    return nil
  end
  if id == CMND_SET_LAYER_VISIBLE then
    local a = Pack(...)
    if UI_HIDE_LAYERS[a[1]] and a[3] == true then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == CMND_OPEN_LAYER or id == CMND_OPEN_LAYER_ARRAY then
    local layer = ...
    if UI_HIDE_LAYERS[layer] then
      local r = Pack(orig(id, ...))
      UiHideLayer(orig, layer)
      UiLog("hide", layer)
      return r
    end
  end
  return nil
end

UiHookMenuCommand(UiMenuFilter)

-- Layers the engine opens by itself still pass through the menu callbacks.
local function UiAfterLayer(a1, a2)
  if UiOn("enemy_meters") and UI_HIDE_LAYERS[a1] and type(funcLuaMenuCommand) == "function" then
    funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, a1, a2 or 0, false)
  end
end
UiWrapCallback("OnSetupLayer", UiAfterLayer)
UiWrapCallback("OnOpenLayer", UiAfterLayer)

-- The engine opens these layers itself and shows them again after OnOpenLayer
local CMND_IS_OPEN_LAYER = 2640875187
local UI_STEP_LOGGED = {}
local function UiStepHide()
  if not UiOn("enemy_meters") or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  for layer, n in pairs(UI_HIDE_LAYERS) do
    local open = VRFW.host.menu_command(CMND_IS_OPEN_LAYER, layer)
    if open == true then
      for i = 0, n - 1 do
        VRFW.host.menu_command(CMND_SET_LAYER_VISIBLE, layer, i, false)
      end
      if not UI_STEP_LOGGED[layer] then
        UI_STEP_LOGGED[layer] = true
        UiLog("step_hide", layer)
      end
    end
  end
end
UiWrapCallback("PostStep", UiStepHide)
