-- EVT better_ui kick-off button
BetterUI.kickoff_button = BetterUI.kickoff_button or {}
BetterUI = type(BetterUI) == "table" and BetterUI or {}
BetterUI.kickoff_button.SCALE = 0.72        -- size (retail 1.0)
BetterUI.kickoff_button.CENTRE_Y = 150      -- plate centre height in the layout (_pos_btn01 y), kept when scaling

local kickoff_button_layer = @crc:soccer00_27_restart_button@
local kickoff_button_add = {@crc:_restart_btn_base_add01@, @crc:_restart_btn_base_add02@}
local better_ui_ko_closing = false
local better_ui_ko_idx = nil

BetterUI.kickoff_button.FORMATION_GAP = 8              -- screen units between the two plates
BetterUI.kickoff_button.FORMATION_SCALE = 1.0
local kickoff_button_form = @crc:soccer01_33_formation_button_guide@
local kickoff_button_n_pos = @crc:_pos_btn01@
local kickoff_button_n_touch = @crc:_touch_btn01@ --[[_touch_btn01: the plate's top-left corner, (-220, +36) from _pos_btn01]]
local kickoff_button_touch_dx = -220
local kickoff_button_n_fbase = @crc:_pos_base01@ --[[_pos_base01 of soccer01_33: the plate's top-left corner]]
local kickoff_button_n_ftext = @crc:_text_guide01@ --[[_text_guide01 of soccer01_33: 56 units right of it]]
local kickoff_button_ftext_dx = 56
local kickoff_button_form_h = 52
local kickoff_button_rest_w = 388
local character_reforged_pp_idx = nil
local character_reforged_pp_s = 1
local character_reforged_pp_lx, character_reforged_pp_ly = 0, 0

local function kickoff_button_cmd(...)
  if type(funcLuaMenuCommand) == "function" then
    return pcall(funcLuaMenuCommand, ...)
  end
  return false
end

local function kickoff_button_look(idx)
  for i = 1, #kickoff_button_add do
    kickoff_button_cmd(@crc:CMND_SET_MESH_VISIBLE@, kickoff_button_layer, kickoff_button_add[i], false, idx)
  end
end

local function kickoff_button_gp(layer, idx, node)
  local ok, x, y = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_GLOBAL_POSITION@, layer, idx, node)
  if ok and type(x) == "number" and type(y) == "number" then
    return x, y
  end
  return nil
end

local function kickoff_button_place()
  if character_reforged_pp_idx == nil or better_ui_ko_idx == nil or better_ui_ko_closing then
    return
  end
  local okOpen, open = pcall(funcLuaMenuCommand, @crc:CMND_IS_OPEN_LAYER@, kickoff_button_form, character_reforged_pp_idx)
  if not okOpen or open ~= true then
    return
  end
  local px, py = kickoff_button_gp(kickoff_button_layer, better_ui_ko_idx, kickoff_button_n_pos)
  local tx, ty = kickoff_button_gp(kickoff_button_layer, better_ui_ko_idx, kickoff_button_n_touch)
  local fx0, fy0 = kickoff_button_gp(kickoff_button_form, character_reforged_pp_idx, kickoff_button_n_fbase)
  local fx1 = kickoff_button_gp(kickoff_button_form, character_reforged_pp_idx, kickoff_button_n_ftext)
  if px == nil or tx == nil or fx0 == nil or fx1 == nil then
    return
  end
  local kr = (tx - px) / kickoff_button_touch_dx
  local kf = (fx1 - fx0) / kickoff_button_ftext_dx
  if kr < 0.05 or kr > 5 or kf < 0.05 or kf > 5 then
    return
  end
  if math.abs(kf - BetterUI.kickoff_button.FORMATION_SCALE) > 0.03 then
    character_reforged_pp_s = character_reforged_pp_s * BetterUI.kickoff_button.FORMATION_SCALE / kf
    kickoff_button_cmd(@crc:CMND_SET_LAYER_LOCAL_SCALE@, kickoff_button_form, character_reforged_pp_s, character_reforged_pp_s, 1, character_reforged_pp_idx)
    return
  end
  local dir = (ty >= py) and 1 or -1 -- screen y direction of "up"
  -- Centres the button.
  local targetX = tx
  local okW, fw = pcall(funcLuaMenuCommand, 1775716383 --[[CMND_GET_LAYER_WIDTH]], kickoff_button_form, character_reforged_pp_idx, true, true)
  if okW and type(fw) == "number" and fw > 0 then
    targetX = tx + (kickoff_button_rest_w * kr - fw * kf) / 2
  end
  local ex = targetX - fx0
  local ey = ty + dir * (BetterUI.kickoff_button.FORMATION_GAP + kickoff_button_form_h * kf) - fy0
  if math.abs(ex) < 0.75 and math.abs(ey) < 0.75 then
    return
  end
  character_reforged_pp_lx = character_reforged_pp_lx + ex / kf
  character_reforged_pp_ly = character_reforged_pp_ly + ey * dir / kf
  kickoff_button_cmd(@crc:CMND_SET_LAYER_LOCAL_POS@, kickoff_button_form, character_reforged_pp_lx, character_reforged_pp_ly, 0, character_reforged_pp_idx)
end

local function kickoff_button_setup(idx)
  better_ui_ko_idx = idx
  better_ui_ko_closing = false
  local s = BetterUI.kickoff_button.SCALE
  kickoff_button_cmd(@crc:CMND_SET_LAYER_LOCAL_SCALE@, kickoff_button_layer, s, s, 1, idx)
  -- Scales the button around the layer origin (bottom centre).
  kickoff_button_cmd(@crc:CMND_SET_LAYER_LOCAL_POS@, kickoff_button_layer, 0, math.floor(BetterUI.kickoff_button.CENTRE_Y * (1 - s) + 0.5), 0, idx)
  kickoff_button_look(idx)
  pcall(funcLuaCommand, @crc:CMND_VRFW_LOG@, "BetterUI kickoff button", "scale " .. tostring(s))
end

local better_ui_ko_prevSetup = rawget(_ENV, "OnSetupLayer")
if type(better_ui_ko_prevSetup) == "function" then
  rawset(_ENV, "OnSetupLayer", function(a1, a2, ...)
    local r = better_ui_ko_prevSetup(a1, a2, ...)
    if a1 == kickoff_button_layer then
      kickoff_button_setup(a2 or 0)
    elseif a1 == kickoff_button_form then
      character_reforged_pp_idx = a2 or 0
      character_reforged_pp_s = 1
      character_reforged_pp_lx, character_reforged_pp_ly = 0, 0
    end
    return r
  end)
end

-- The retail blink animations bring the glow back
local better_ui_ko_prevStep = rawget(_ENV, "Step")
if type(better_ui_ko_prevStep) == "function" then
  rawset(_ENV, "Step", function(...)
    local r = better_ui_ko_prevStep(...)
    if better_ui_ko_idx ~= nil then
      kickoff_button_look(better_ui_ko_idx)
      kickoff_button_place()
    end
    return r
  end)
end

local better_ui_ko_prevDecide = rawget(_ENV, "DecideRestartButton")
if type(better_ui_ko_prevDecide) == "function" then
  rawset(_ENV, "DecideRestartButton", function(...)
    better_ui_ko_closing = true
    return better_ui_ko_prevDecide(...)
  end)
end
