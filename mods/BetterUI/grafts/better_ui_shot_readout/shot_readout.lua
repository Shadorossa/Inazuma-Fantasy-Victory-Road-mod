local function BetterUIShotReadout_Enabled()
  return VRFW.host.command(@crc:CMND_BETTERUI_DUEL_AND_SHOT_COUNTERS_ON@) == true
end

-- the «critical» tags of the readout on screen (BetterUI.power_counter); nil = none
local BetterUIShotReadout_tags = nil

-- per plate (1 = self, 2 = enemy): its player's move was a critical hit
local function BetterUIShotReadout_Critical(shooter, keeper, self_shoots)
  local counter = BetterUI.power_counter
  local shot, keeper_move = VRFW.host.command(@crc:CMND_BETTERUI_SHOT_MOVES@, shooter, keeper)
  local shooter_hit = counter.Critical(shooter, shot)
  local keeper_hit = counter.Critical(keeper, keeper_move)
  if self_shoots then
    return { shooter_hit, keeper_hit }
  end
  return { keeper_hit, shooter_hit }
end

local BetterUIShotReadout_previousOpen = OpenAtKpPowerInfoTelop
function OpenAtKpPowerInfoTelop(...)
  if not BetterUIShotReadout_Enabled() then
    return
  end
  local _, shooter, keeper, self_shoots = ...
  local critical = BetterUIShotReadout_Critical(shooter, keeper, self_shoots == true)
  if BetterUIShotReadout_tags ~= nil then
    BetterUI.power_counter.HideTags(BetterUIShotReadout_tags)
    BetterUIShotReadout_tags = nil
  end
  if critical[1] or critical[2] then
    local layout = VRFW.host.command(@crc:CMND_BETTERUI_DUEL_PLATE_LAYOUT@)
    BetterUIShotReadout_tags = BetterUI.power_counter.NewTags(critical, layout, VRFW.logger.new("BETTERUI_POWER_COUNTER"))
  end
  if type(BetterUIShotReadout_previousOpen) == "function" then
    return BetterUIShotReadout_previousOpen(...)
  end
end

local BetterUIShotReadout_previousStep = PostStep
function PostStep(...)
  if BetterUIShotReadout_tags ~= nil then
    BetterUI.power_counter.StepTags(BetterUIShotReadout_tags)
  end
  if type(BetterUIShotReadout_previousStep) == "function" then
    return BetterUIShotReadout_previousStep(...)
  end
end

local BetterUIShotReadout_previousOpenLayer = OnOpenLayer
function OnOpenLayer(layer, index, ...)
  if layer == @crc:betterui_power_counter_crit@ then
    VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, layer, index or 0, false)
  end
  if type(BetterUIShotReadout_previousOpenLayer) == "function" then
    return BetterUIShotReadout_previousOpenLayer(layer, index, ...)
  end
end

-- a plate closes (the readout's time is over): its tags go with it
local BetterUIShotReadout_previousCloseLayer = OnCloseLayer
function OnCloseLayer(layer, index, ...)
  if BetterUIShotReadout_tags ~= nil and (layer == @crc:soccer10_25_at_kp_power_info_telop_self@
      or layer == @crc:soccer10_25_at_kp_power_info_telop_enemy@) then
    BetterUI.power_counter.HideTags(BetterUIShotReadout_tags)
    BetterUIShotReadout_tags = nil
  end
  if type(BetterUIShotReadout_previousCloseLayer) == "function" then
    return BetterUIShotReadout_previousCloseLayer(layer, index, ...)
  end
end
