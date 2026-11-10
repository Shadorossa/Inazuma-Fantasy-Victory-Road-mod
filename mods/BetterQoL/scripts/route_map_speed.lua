local Memory = VRFW.memory
local PAD_RT = 0x200
local FACTOR_MIN, FACTOR_MAX = 1.0, 5.0

local cfg = VRFW.config("route_map_speed", {})

local NAMED = { SHIFT = 0x10, CTRL = 0x11, CONTROL = 0x11, ALT = 0x12, SPACE = 0x20, TAB = 0x09, LSHIFT = 0xA0, RSHIFT = 0xA1, LCTRL = 0xA2, RCTRL = 0xA3 }

-- a key name of the config ("E", "Shift", "0x45"...) -> Windows virtual key
local function vk_of(name)
  if type(name) ~= "string" then
    return nil
  end
  local n = string.upper((string.gsub(name, "^%s*(.-)%s*$", "%1")))
  local hex = string.match(n, "^0X(%x+)$")
  if hex then
    local v = tonumber(hex, 16)
    return (v and v >= 1 and v <= 0xFE) and v or nil
  end
  if #n == 1 and string.match(n, "[A-Z0-9]") then
    return string.byte(n)
  end
  return NAMED[n]
end

local factor = tonumber(cfg.factor) or 2.0
if factor ~= factor then
  factor = 2.0
end
if factor < FACTOR_MIN or factor > FACTOR_MAX then
  local c = math.min(math.max(factor, FACTOR_MIN), FACTOR_MAX)
  VRFW.warn(string.format("config.toml [route_map_speed]: factor %s out of %s..%s: %s", tostring(factor), FACTOR_MIN, FACTOR_MAX, c))
  factor = c
end
local keys = {}
for _, k in ipairs(type(cfg.keys) == "table" and cfg.keys or { "E" }) do
  local vk = vk_of(k)
  if vk then
    keys[#keys + 1] = vk
  else
    VRFW.warn("config.toml [route_map_speed]: key " .. tostring(k) .. " not known: ignored")
  end
end
local log = cfg.log ~= false

local band = bit32.band
local input_pad, input_key
local input_missing_logged = false

local function input_ready()
  if input_pad then
    return true
  end
  local api = type(VRFW.input) == "table" and VRFW.input or nil
  local pad, key = api and api.pad, api and api.key
  if type(pad) == "function" and type(key) == "function" then
    input_pad, input_key = pad, key
    return true
  end
  if not input_missing_logged then
    input_missing_logged = true
    VRFW.warn("route map speed: VRFW.input.pad / VRFW.input.key not available: the map cursor keeps the game's speed")
  end
  return false
end

local n_keys = #keys
local key_args = n_keys > 0 and keys or nil

local function r2_held()
  if not input_pad and not input_ready() then
    return false
  end
  local ok, pad = pcall(input_pad)
  if ok and pad and band(pad, PAD_RT) ~= 0 then
    return true
  end
  if key_args == nil then
    return false
  end
  local okk, down = pcall(input_key, table.unpack(key_args, 1, n_keys))
  return okk and down == true
end

if input_ready() then
  pcall(input_pad)
end

local held = false
local saved -- { the menu record, the game's speed } between pre and post

VRFW.on("hook:RouteMapUpdate", function(ev)
  local this = ev.args[1]
  local boost = this ~= 0 and r2_held()
  if not boost then
    if held and log then
      VRFW.log("R2 released: the route map cursor is back to the game's speed")
    end
    held = false
    return nil
  end
  local menu = Memory.struct("RouteMapMenu", this)
  local game = menu and menu.cursor_speed
  if game == nil or game ~= game or game <= 0 then
    return nil
  end
  if not held and log then
    VRFW.log(string.format("R2 held on the route map: cursor speed %s x %s = %s", tostring(game), tostring(factor), tostring(game * factor)))
  end
  held = true
  menu.cursor_speed = game * factor
  saved = { menu, game }
  return nil
end)

VRFW.on("hook:RouteMapUpdate:post", function()
  if saved then
    saved[1].cursor_speed = saved[2]
    saved = nil
  end
  return nil
end)

function BetterQoL.RouteMapSpeedOn()
  return VRFW.is_on("RouteMapUpdate") and input_ready()
end
