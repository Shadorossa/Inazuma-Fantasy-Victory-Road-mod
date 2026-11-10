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

-- Layer and mesh ids of soccer_area_title_menu.
local UI_LAYER = 2169865486
local UI_MESH = 2623254857
local UI_ZONE_TYPE = 3
local CMND_SET_LAYER_VISIBLE = 711242136
local CMND_SET_MESH_VISIBLE = 3405944500
local ui_area_type = 0

local function UiHideNow()
  return UiOn("zone_hud") and ui_area_type == UI_ZONE_TYPE
end

local function UiApply()
  if type(funcLuaMenuCommand) ~= "function" then
    return
  end
  if UiHideNow() then
    funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, UI_LAYER, UI_MESH, false, 0)
    funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, UI_LAYER, 0, false)
  else
    funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, UI_LAYER, UI_MESH, true, 0)
  end
end

-- anything that tries to show the layer / the title mesh again while a zone title is up stays hidden
local function UiMenuFilter(orig, id, ...)
  if not UiHideNow() then
    return nil
  end
  local a = Pack(...)
  if id == CMND_SET_LAYER_VISIBLE and a[1] == UI_LAYER and a[3] == true then
    a[3] = false
    return Pack(orig(id, table.unpack(a, 1, a.n)))
  elseif id == CMND_SET_MESH_VISIBLE and a[1] == UI_LAYER and a[2] == UI_MESH and a[3] == true then
    a[3] = false
    return Pack(orig(id, table.unpack(a, 1, a.n)))
  end
  return nil
end
UiHookMenuCommand(UiMenuFilter)

local ui_orig_setup = rawget(_ENV, "SetupAreaTitle")
if type(ui_orig_setup) == "function" then
  rawset(_ENV, "SetupAreaTitle", function(a1, ...)
    ui_area_type = a1 or 0
    local r = Pack(ui_orig_setup(a1, ...))
    local ok, err = pcall(UiApply)
    UiLog("area_title", a1, ok and "ok" or err)
    return table.unpack(r, 1, r.n)
  end)
end

UiWrapCallback("OnSetupLayer", function(a1, a2)
  if a1 == UI_LAYER then
    UiApply()
  end
end)

-- Defines OnOpenLayer when the retail script has none.
if rawget(_ENV, "OnOpenLayer") == nil then
  rawset(_ENV, "OnOpenLayer", function(a1, a2)
    if a1 == UI_LAYER then
      pcall(UiApply)
    end
  end)
end
