
local LENGTH_MIN, LENGTH_MAX = 1, 31
local DEFAULT_LENGTH, DEFAULT_ROOM = 24, 436

local cfg = VRFW.config("team_name", {})

local function whole(value, default, low, high, key)
  local n = tonumber(value)
  if n == nil or n ~= n then
    return default
  end
  n = math.floor(n)
  if n < low or n > high then
    local clamped = math.min(math.max(n, low), high)
    VRFW.warn(string.format("config.toml [team_name]: %s %d out of %d..%d: %d", key, n, low, high, clamped))
    return clamped
  end
  return n
end

local max_length = whole(cfg.max_length, DEFAULT_LENGTH, LENGTH_MIN, LENGTH_MAX, "max_length")
local room = whole(cfg.room, DEFAULT_ROOM, 50, 1920, "room")

-- style key = crc32 of the style name
local function style_key(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  return VRFW.crc32(name)
end

local base_style = style_key(cfg.style) or 0
local fit_styles = {}
for _, name in ipairs(type(cfg.fit_styles) == "table" and cfg.fit_styles or {}) do
  local key = style_key(name)
  if key ~= nil then
    fit_styles[#fit_styles + 1] = tostring(key)
  else
    VRFW.warn("config.toml [team_name]: fit_styles entry " .. tostring(name) .. " is not a style name: ignored")
  end
end
if base_style == 0 then
  fit_styles = {}
end
local fit_list = table.concat(fit_styles, ",")

VRFW.log(string.format("team name: up to %d characters, room %d px, %d fit styles", max_length, room, #fit_styles))

BetterQoL = BetterQoL or {}
BetterQoL.TeamName = BetterQoL.TeamName or {}

-- () -> max length (characters), room (px), the dock's own style key (0 = no fit), fit style keys (comma-separated)
function BetterQoL.TeamName.Settings()
  return max_length, room, base_style, fit_list
end
