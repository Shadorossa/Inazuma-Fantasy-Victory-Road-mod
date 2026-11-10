-- VRFW.value: values with a default, for any mod's scripts (read VRFW.value.<name>, no require).

local floor, ceil = math.floor, math.ceil

local value = {}

--- `v` as a number (`default` when it is none).
function value.number(v, default)
  v = tonumber(v)
  if v == nil or v ~= v then
    return default
  end
  return v
end

--- `v` as an integer rounded toward zero (`default` when it is none).
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

--- `v` as a boolean (`default` when it is none).
function value.boolean(v, default)
  if v == nil then
    return default
  end
  return v == true
end

--- `v` as an array (`default` when it is not one).
function value.list(v, default)
  if v == nil then
    return default
  end
  if type(v) ~= "table" then
    return { v }
  end
  return v
end

--- `v` as a number between `min` and `max` (`default` when it is none).
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

--- `x` rounded half away from zero to `places` decimals.
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
