-- ability_learning_board_menu
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

-- Header dock layers.
local HD_LAYERS = { @HD_LAYERS@ }
local HD_CHECK = { @HD_CHECK@ }
local CMND_SET_LAYER_LOCAL_POS = 1389957207
local CMND_SET_LAYER_LOCAL_SCALE = 3778714801
local CMND_IS_OPEN_MENU_OBJECT = 3693934564
local HEADER_LAYER = 575058101        -- mainmenu90_01_header
local hd_done = {}
local hd_check_raw = "-"

local function HdActive()
  if not UiOn("header_short") then
    return false
  end
  if type(funcLuaCommand) ~= "function" then
    return false
  end
  for _, m in ipairs(HD_CHECK) do
    local ok, r = pcall(funcLuaCommand, CMND_IS_OPEN_MENU_OBJECT, m, HEADER_LAYER)
    hd_check_raw = tostring(ok) .. ":" .. tostring(r)
    if ok and r ~= nil and r ~= false and r ~= 0 then
      return true
    end
  end
  return false
end

local function HdPlace(a1, a2)
  if type(a1) ~= "number" or HD_LAYERS[a1] == nil or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  local idx = type(a2) == "number" and a2 or 0
  local t = HD_LAYERS[a1]
  local active = HdActive()
  if active then                  -- inactive: no call at all, the layer keeps its retail state
    funcLuaMenuCommand(CMND_SET_LAYER_LOCAL_SCALE, a1, t[3], t[3], 1, idx)
    funcLuaMenuCommand(CMND_SET_LAYER_LOCAL_POS, a1, t[1], t[2], 0, idx)
  end
  if hd_done[a1] == nil then
    hd_done[a1] = true
    UiLog("header_dock", a1, idx, active and "in bar" or "retail (no compact header)", hd_check_raw)
  end
end

-- OnSetupLayer places the layer when it is created
for _, cb in ipairs({ "OnSetupLayer", "OnOpenLayer" }) do
  if not UiWrapCallback(cb, HdPlace) then
    UiLog("error", "no " .. cb .. " to wrap")
  end
end
