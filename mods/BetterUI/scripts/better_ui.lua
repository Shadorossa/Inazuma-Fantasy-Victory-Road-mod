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
local PLATE_LAYOUT_KEYS = { "left_number_x", "right_number_x", "label_room", "bust_settle_frames", "tag_scale", "tag_anchor_x", "tag_digits_top",
  "tag_gap", "tag_height" }

function BetterUI.DuelPlateLayout()
  return NumberSection("duel_counter", PLATE_LAYOUT_KEYS)
end
