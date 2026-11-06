-- The everyday helpers of a mod script: values with a default, the mod's config with a default, a tagged logger.
--   require "VRFW/lib/basics"     -- any mod's scripts, the framework's own included
-- Requiring it sets VRFW.value, VRFW.config and VRFW.logger in that script's VM (and returns them as one table).
--   VRFW.value.num(v, default)    -> v as a number (a number or numeric text; NaN is not a number), else default
--   VRFW.value.int(v, default)    -> num(v) truncated toward zero, else default
--   VRFW.value.bool(v, default)   -> default when v is nil, else v == true
--   VRFW.value.list(v, default)   -> v when it is a table, { v } for one other value, default when v is nil
--   VRFW.value.clamp(v, default, min, max) -> num(v) kept inside min..max (either may be nil), else default as it is
--   VRFW.value.round(x, places)   -> x rounded half away from zero (2.5 -> 3, -2.5 -> -3); with places, to that many
--                                    decimals (round(1.25, 1) -> 1.3)
--   VRFW.value.trim(s)            -> tostring(s) without leading and trailing white space; "" for nil and false
--   VRFW.config(path, default)    -> the mod's config value at a dotted path (VRFW.files.config); default when the
--                                    value is missing or cannot be read
--   VRFW.config(path, default, min, max) -> the same value as a number kept inside min..max (value.clamp)
--   VRFW.logger(tag)              -> info, warn, err: each writes one line "<tag>: ..." through VRFW.log / VRFW.warn /
--                                    VRFW.error
-- VRFW.crc32(text) is built in and already unsigned (0..4294967295); VRFW.ui.crc32 is the same hash.

local floor, ceil = math.floor, math.ceil

local value = {}

function value.num(v, default)
  v = tonumber(v)
  if v == nil or v ~= v then
    return default
  end
  return v
end

function value.int(v, default)
  v = value.num(v, nil)
  if v == nil then
    return default
  end
  if v >= 0 then
    return floor(v)
  end
  return ceil(v)
end

function value.bool(v, default)
  if v == nil then
    return default
  end
  return v == true
end

function value.list(v, default)
  if v == nil then
    return default
  end
  if type(v) ~= "table" then
    return { v }
  end
  return v
end

function value.clamp(v, default, min, max)
  v = value.num(v, nil)
  if v == nil then
    return default
  end
  if min and v < min then
    v = min
  end
  if max and v > max then
    v = max
  end
  return v
end

function value.round(x, places)
  local scale = 1
  if places ~= nil and places ~= 0 then
    scale = 10 ^ places
    x = x * scale
  end
  if x >= 0 then
    x = floor(x + 0.5)
  else
    x = -floor(-x + 0.5)
  end
  if scale ~= 1 then
    return x / scale
  end
  return x
end

function value.trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function config(path, default, min, max)
  local files = VRFW.files
  local v = nil
  if type(files) == "table" then
    local ok, got = pcall(files.config, path)
    if ok then
      v = got
    end
  end
  if min ~= nil or max ~= nil then
    return value.clamp(v, default, min, max)
  end
  if v ~= nil then
    return v
  end
  return default
end

local function logger(tag)
  local prefix = tostring(tag) .. ":"
  local function info(...)
    VRFW.log(prefix, ...)
  end
  local function warn(...)
    VRFW.warn(prefix, ...)
  end
  local function err(...)
    VRFW.error(prefix, ...)
  end
  local function debug(...)
    VRFW.debug(prefix, ...)
  end
  return info, warn, err, debug
end

local M = { value = value, config = config, logger = logger }

if type(VRFW) == "table" then
  for k, f in pairs(M) do
    if rawget(VRFW, k) == nil then
      pcall(rawset, VRFW, k, f)
    end
  end
end

return M
