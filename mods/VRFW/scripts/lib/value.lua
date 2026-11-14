-- Read a value with a default: number, integer, boolean, list, clamp, round. Call: at load or in a handler.
-- VRFW.value: values with a default, for any mod's scripts (read VRFW.value.<name>, no require).

local floor, ceil = math.floor, math.ceil

local value = {}

--- VRFW.value.number(v, default): v as a number, or default when v is not one. Call: at load or in a handler.
function value.number(v, default)
  v = tonumber(v)
  if v == nil or v ~= v then
    return default
  end
  return v
end

--- VRFW.value.integer(v, default): v as a whole number (rounded toward zero), or default. Call: at load or in a handler.
function value.integer(v, default)
  v = value.number(v, nil)
  if v == nil then
    return default
  end
  if v >= 0 then
    return floor(v)
  end
  return ceil(v)
end

--- VRFW.value.boolean(v, default): v as a boolean, or default when v is not one. Call: at load or in a handler.
function value.boolean(v, default)
  if v == nil then
    return default
  end
  return v == true
end

--- VRFW.value.list(v, default): v when it is a list, else default. Call: at load or in a handler.
function value.list(v, default)
  if v == nil then
    return default
  end
  if type(v) ~= "table" then
    return { v }
  end
  return v
end

--- VRFW.value.clamp(v, default, min, max): v as a number kept between min and max, or default. Call: at load or in a handler.
function value.clamp(v, default, min, max)
  v = value.number(v, nil)
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

--- VRFW.value.round(x, places): x rounded to `places` decimals (halves away from zero). Call: at load or in a handler.
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

return value
