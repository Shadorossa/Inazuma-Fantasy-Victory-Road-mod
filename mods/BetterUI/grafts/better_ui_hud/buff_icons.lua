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

-- Layout of soccer_team_buff_icon_list_menu.
local UI_BUFF_S = 0.85
local UI_BUFF_DX = -5.4
local UI_BUFF_DY = -7.65
local UI_BUFF_LAYERS = {
  [1516973567] = true,
  [2849833820] = true,
  [2861847060] = true,
  [1535165083] = true,
}
local CMND_SET_LAYER_LOCAL_POS = 1389957207
local CMND_SET_LAYER_LOCAL_SCALE = 3778714801
local ui_buff_logged = false

local function UiMenuFilter(orig, id, ...)
  if id ~= CMND_SET_LAYER_LOCAL_POS or not UiOn("buff_icons") then
    return nil
  end
  local a = Pack(...)
  if not UI_BUFF_LAYERS[a[1]] or type(a[2]) ~= "number" then
    return nil
  end
  a[2] = a[2] * UI_BUFF_S + UI_BUFF_DX
  a[3] = (a[3] or 0) + UI_BUFF_DY
  local r = Pack(orig(id, table.unpack(a, 1, a.n)))
  pcall(orig, CMND_SET_LAYER_LOCAL_SCALE, a[1], UI_BUFF_S, UI_BUFF_S, 1, a[5] or 0)
  if not ui_buff_logged then
    ui_buff_logged = true
    UiLog("buff_scale", UI_BUFF_S, a[1], a[2], a[5])
  end
  return r
end

UiHookMenuCommand(UiMenuFilter)
