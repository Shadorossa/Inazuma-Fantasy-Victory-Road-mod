-- The transformation cross of the match HUD: its places, from config.toml [transform_cross], for the graft hiper_btn.
CharacterReforged = CharacterReforged or {}
CharacterReforged.TransformCross = CharacterReforged.TransformCross or {}

local info, warn = VRFW.logger("transform_cross")

-- The numbers of the layout, in the order the command returns them.
local NUMBER_KEYS = {
  "centre_x", "centre_y", "ring_size", "dim_brightness", "side_gap", "plate_scale", "plate_height_scale", "vertical_gap", "text_scale",
  "name_scale", "name_room", "name_room_face", "name_offset_x", "pill_gap", "tactics_plate_scale",
}
-- The arrow of an entry as the command's direction code.
local DIRECTION_CODES = { up = 1, left = 2, right = 3, down = 4 }
local ENTRY_COUNT = 4

local layout = nil

-- Reads and checks the section once; a missing or wrong value is an error line and no layout.
local function read_layout()
  if layout ~= nil then return layout end
  layout = false
  local section = VRFW.files.config("transform_cross")
  if type(section) ~= "table" then
    warn("config.toml has no [transform_cross] section: the cross is not drawn")
    return layout
  end
  local values = {}
  for _, key in ipairs(NUMBER_KEYS) do
    local value = section[key]
    if type(value) ~= "number" then
      warn(string.format("[transform_cross] %s is not a number: the cross is not drawn", key))
      return layout
    end
    values[#values + 1] = value
  end
  local directions = section.directions
  for entry = 1, ENTRY_COUNT do
    local code = type(directions) == "table" and DIRECTION_CODES[directions[entry]] or nil
    if code == nil then
      warn(string.format("[transform_cross] directions needs %d of up / left / right / down: the cross is not drawn", ENTRY_COUNT))
      return layout
    end
    values[#values + 1] = code
  end
  layout = values
  info(string.format("layout: ring %s wide at %s,%s, menu plates %s from its sides and %s above and below it at scale %s",
    section.ring_size, section.centre_x, section.centre_y, section.side_gap, section.vertical_gap, section.plate_scale))
  return layout
end

-- CMND_CHARACTERREFORGED_TRANSFORM_CROSS() -> the numbers of NUMBER_KEYS in their order, then the direction code of each of the
-- four entries (false = no layout).
function CharacterReforged.TransformCross.Layout()
  local values = read_layout()
  if not values then return false end
  return table.unpack(values)
end
