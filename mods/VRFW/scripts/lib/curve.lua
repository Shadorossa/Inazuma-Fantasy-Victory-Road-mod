--- Advanced: Library: piecewise curve values from point lists.
local M = {}

--- Advanced: The value of the curve `points` at `x` (`empty` when the curve has no points).
function M.value_at(points, x, empty)
  if type(points) ~= "table" or #points == 0 then
    return empty
  end
  if x <= points[1][1] then
    return points[1][2]
  end
  for i = 2, #points do
    local a, b = points[i - 1], points[i]
    if x <= b[1] then
      if b[1] == a[1] then
        return b[2]
      end
      return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
    end
  end
  return points[#points][2]
end

--- Advanced: The curve points of configuration value `v` (`default` when it has none).
function M.read_points(v, default)
  local out = {}
  for _, p in ipairs(type(v) == "table" and v or {}) do
    if type(p) == "table" and tonumber(p[1]) and tonumber(p[2]) then
      out[#out + 1] = { tonumber(p[1]), tonumber(p[2]), tonumber(p[3]) }
    end
  end
  if #out > 0 then
    return out
  end
  return default
end

return M
