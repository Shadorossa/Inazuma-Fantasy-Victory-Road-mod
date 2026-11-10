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

-- Layer and mesh ids of team_dock_common_top_menu.
local UI_ESC_LAYER = 2005383485
local UI_ESC_MESH = 1714756523
local CMND_SET_MESH_VISIBLE = 3405944500
local ui_esc_logged = false

local function UiFixEsc(a1, a2)
  if a1 ~= UI_ESC_LAYER or not UiOn("esc_guide") or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  local idx = a2 or 0
  funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, a1, UI_ESC_MESH, false, idx)
  if not ui_esc_logged then
    ui_esc_logged = true
    UiLog("esc_guide", a1, idx)
  end
end

UiWrapCallback("OnSetupLayer", UiFixEsc)
UiWrapCallback("OnOpenLayer", UiFixEsc)
