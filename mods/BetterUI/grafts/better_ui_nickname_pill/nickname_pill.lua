-- ===== EVT better_ui nickname_pill BEGIN =====
do
local better_ui_block = function()
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

-- Layer ids of soccer_team_dock_menu and soccer_vs_cpu_list_menu.
local UI_NP_LAYER = 209828247
local UI_NP_FUNC = 3702644710
local CMND_OPEN_LAYER = 629267548
local CMND_OPEN_LAYER_ARRAY = 2152386330
local CMND_SET_LAYER_VISIBLE = 711242136
local CMND_IS_FULL_NAME = 1332416299
local CMND_TOGGLE_NAME = 376658171
local ui_np_forced = false

local function UiMenuFilter(orig, id, ...)
  if not UiOn("nickname_pill") then
    return nil
  end
  local a = Pack(...)
  if id == CMND_SET_LAYER_VISIBLE and a[1] == UI_NP_LAYER and a[3] == true then
    a[3] = false
    return Pack(orig(id, table.unpack(a, 1, a.n)))
  elseif (id == CMND_OPEN_LAYER or id == CMND_OPEN_LAYER_ARRAY) and a[1] == UI_NP_LAYER then
    local r = Pack(orig(id, ...))
    pcall(orig, CMND_SET_LAYER_VISIBLE, UI_NP_LAYER, 0, false)
    return r
  end
  return nil
end
UiHookMenuCommand(UiMenuFilter)

local function UiNpLayer(a1, a2)
  if a1 ~= UI_NP_LAYER or not UiOn("nickname_pill") or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, a1, a2 or 0, false)
  if not ui_np_forced and type(funcLuaCommand) == "function" then
    ui_np_forced = true
    if funcLuaCommand(CMND_IS_FULL_NAME) == false then
      funcLuaCommand(CMND_TOGGLE_NAME)
      UiLog("nickname_pill", "forced full names")
    else
      UiLog("nickname_pill", "hidden")
    end
  end
end
UiWrapCallback("OnSetupLayer", UiNpLayer)
UiWrapCallback("OnOpenLayer", UiNpLayer)

-- Handles the X key press.
local ui_np_orig_fn = rawget(_ENV, "OnFunction")
if type(ui_np_orig_fn) == "function" then
  rawset(_ENV, "OnFunction", function(a1, ...)
    if a1 == UI_NP_FUNC and UiOn("nickname_pill") then
      return
    end
    return ui_np_orig_fn(a1, ...)
  end)
end

end
better_ui_block()
end
-- ===== EVT better_ui nickname_pill END =====
