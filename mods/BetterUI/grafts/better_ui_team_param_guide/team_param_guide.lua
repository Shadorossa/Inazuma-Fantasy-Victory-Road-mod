-- ===== EVT better_ui team_param_guide BEGIN =====
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

-- Layer ids of soccer_formation_menu, soccer_team_dock_menu and team_dock_formation_menu.
local UI_TP_LAYER = 3159119257
local UI_TP_PILL = 3418019775
local UI_TP_BTN = 950238781
local UI_TP_TEXT = 378156699
local UI_TP_ICON = 260772049   -- the team build-type icon, kept hidden
local UI_TP_BTN_STYLE = 965926135
local UI_TP_TEXT_STYLE = 2403837512      -- fs_guide01 (-1891129784 as signed int32)
local UI_TP_DEFAULT_TEXT = 1938000735      -- "[CTEAMPARAM01]Bonific. de equipo[C]"
local CMND_SET_MESH_VISIBLE = 3405944500
local CMND_SET_LAYER_VISIBLE = 711242136
local CMND_SET_TEXT_FONTSTYLE = 2333948100
local CMND_SET_MENU_TEXT_STRING = 1083631230
local CMND_UPDATE_TEXT_PLATE = 1172899594
local CMND_TEXT_GET = 4074371074
local ui_tp_logged = false

local UiFixTeamParam

local function UiPlain(s)
  if type(s) ~= "string" then
    return s
  end
  return (string.gsub(s, "%[C[%w_]*%]", ""))
end

-- colour tags of any text the scripts put on this guide are dropped (the vroad variant sets its own string)
local function UiMenuFilter(orig, id, ...)
  if not UiOn("team_param_guide") then
    return nil
  end
  if id == CMND_SET_MESH_VISIBLE then
    -- retail UpdateTeamParameterButtonGuideByTeamDockNo shows the build icon again on every dock change
    local a = Pack(...)
    if a[1] == UI_TP_LAYER and (a[2] == UI_TP_ICON or a[2] == UI_TP_PILL) and a[3] == true then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
    return nil
  end
  if id == CMND_SET_LAYER_VISIBLE then
    -- team_dock_formation_menu shows the layer of its parent menu with CMND_SET_LAYER_VISIBLE(layer, 0, true).
    local a = Pack(...)
    if a[1] == UI_TP_LAYER and a[3] == true then
      local r = Pack(orig(id, table.unpack(a, 1, a.n)))
      local ok, err = pcall(UiFixTeamParam, a[1], a[2])
      if not ok then
        UiLog("error", "team_param_guide", err)
      end
      return r
    end
    return nil
  end
  if id ~= CMND_SET_MENU_TEXT_STRING then
    return nil
  end
  local a = Pack(...)
  if a[1] ~= UI_TP_LAYER or a[2] ~= UI_TP_TEXT or type(a[3]) ~= "string" then
    return nil
  end
  a[3] = UiPlain(a[3])
  return Pack(orig(id, table.unpack(a, 1, a.n)))
end
UiHookMenuCommand(UiMenuFilter)

UiFixTeamParam = function(a1, a2)
  if a1 ~= UI_TP_LAYER or not UiOn("team_param_guide") or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  local idx = a2 or 0
  funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, a1, UI_TP_PILL, false, idx)
  funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, a1, UI_TP_ICON, false, idx)
  funcLuaMenuCommand(CMND_SET_TEXT_FONTSTYLE, a1, idx, UI_TP_BTN, UI_TP_BTN_STYLE)
  funcLuaMenuCommand(CMND_SET_TEXT_FONTSTYLE, a1, idx, UI_TP_TEXT, UI_TP_TEXT_STYLE)
  if type(funcLuaCommand) == "function" and not funcLuaCommand(2149480449) then
    local s = funcLuaCommand(CMND_TEXT_GET, UI_TP_DEFAULT_TEXT)
    if type(s) == "string" then
      funcLuaMenuCommand(CMND_SET_MENU_TEXT_STRING, a1, UI_TP_TEXT, UiPlain(s), idx)
    end
  end
  funcLuaMenuCommand(CMND_UPDATE_TEXT_PLATE, a1, idx, UI_TP_TEXT)
  if not ui_tp_logged then
    ui_tp_logged = true
    UiLog("team_param_guide", a1, idx)
  end
end

UiWrapCallback("OnSetupLayer", UiFixTeamParam)
UiWrapCallback("OnOpenLayer", UiFixTeamParam)

end
better_ui_block()
end
-- ===== EVT better_ui team_param_guide END =====
