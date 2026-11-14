BetterUI = type(BetterUI) == "table" and BetterUI or {}

function BetterUI.TacticSlices()
  return true
end

-- The card position types (ClassicCards.POSITION_LOOKS keys) by config.toml name.
local POSITION_NAMES = {[0] = "goalkeeper", "defender", "midfielder", "forward"}

function BetterUI.PositionLook(positionType)
  local name = POSITION_NAMES[positionType]
  if name == nil then
    return positionType
  end
  local want = VRFW.files.config("position_card_looks." .. name)
  for t, n in pairs(POSITION_NAMES) do
    if n == want then
      return t
    end
  end
  return positionType
end

-- The number keys of one config.toml section as a table, or nil when one is missing.
local function NumberSection(section, keys)
  local values = {}
  for _, key in ipairs(keys) do
    local value = VRFW.files.config(section .. "." .. key)
    if type(value) ~= "number" then
      return nil
    end
    values[key] = value
  end
  return values
end

local CARD_SPREAD_KEYS = { "card_width", "card_height", "gap", "smallest_scale", "scale_step",
                           "pitch_side", "pitch_top", "pitch_bottom" }

function BetterUI.FormationCardSpread()
  if VRFW.files.config("formation_card_spread.enabled") ~= true then
    return nil
  end
  return NumberSection("formation_card_spread", CARD_SPREAD_KEYS)
end

-- CMND_BETTERUI_DUEL_PLATE_LAYOUT() -> the tunables of config.toml [duel_counter], or nil when one is missing.
local PLATE_LAYOUT_KEYS = { "left_label_end_x", "right_label_end_x", "digits_gap", "left_plate_edge", "right_plate_edge", "plate_scale",
  "left_plate_outer_x", "right_plate_outer_x", "left_ribbon_inner_x", "right_ribbon_inner_x", "plate_gap",
  "half_distance", "right_label_inner_x", "digit_width",
  "bust_settle_frames", "tag_scale", "tag_width", "tag_centre_x", "tag_centre_y", "tag_gap", "digits_mid_y",
  "left_retail_number_x", "right_retail_number_x", "tag_default_digits", "layout_width", "layout_height" }

function BetterUI.DuelPlateLayout()
  return NumberSection("duel_counter", PLATE_LAYOUT_KEYS)
end

-- CMND_BETTERUI_SKILL_SCREEN_REDESIGN() -> true when config.toml [skill_screen] redesign is true.
function BetterUI.SkillScreenRedesign()
  return VRFW.files.config("skill_screen.redesign") == true
end
