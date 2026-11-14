--- Advanced: Library: entries of a pool picked or cycled for a given day by a rule.

local M = {}

local function int(v, default)
  v = tonumber(v)
  return v and math.floor(v) or default
end

-- n distinct candidates in draw order: a forward partial Fisher-Yates with the generator's unbiased integer draws
local function draw_distinct(rng, pool, n)
  local index = {}
  for i = 1, #pool do
    index[i] = i
  end
  local out = {}
  for i = 1, n do
    local j = i + rng:below(#index - i + 1)
    index[i], index[j] = index[j], index[i]
    out[i] = pool[index[i]]
  end
  return out
end

-- per pick, a drawn index taken when `accept` returns a value; nil when a pick finds none in `tries` draws
local function draw_accepted(rng, pool, n, accept, tries)
  local out = {}
  for i = 1, n do
    for _ = 1, tries do
      local value = accept(pool[rng:below(#pool) + 1])
      if value then
        out[i] = value
        break
      end
    end
    if out[i] == nil then
      return nil
    end
  end
  return out
end

local function greatest_divisor(a, b)
  while b ~= 0 do
    a, b = b, a % b
  end
  return a
end

--- Advanced: The pool entry of day `id` going through the pool in order; nil, why on a bad rule.
function M.cycle(rule, id)
  if type(rule) ~= "table" or type(rule.pool) ~= "table" then
    return nil, "rule"
  end
  local pool = rule.pool
  local n = #pool
  if n == 0 then
    return nil, "empty pool"
  end
  if n == 1 then
    return pool[1]
  end
  local rng = VRFW.random(tostring(rule.salt or ""), { n, int(rule.version, 1) })
  local start = rng:below(n)
  local step = rng:below(n - 1) + 1
  while greatest_divisor(step, n) ~= 1 do
    step = step % (n - 1) + 1
  end
  return pool[(start + (int(id, 0) % n) * step) % n + 1]
end

--- Advanced: The entries of `rule` drawn for day `id`; nil, why on a bad rule.
function M.pick(rule, id)
  if type(rule) ~= "table" or type(rule.pool) ~= "table" then
    return nil, "rule"
  end
  local pool = rule.pool
  local n = int(rule.picks, 1)
  if n < 1 then
    return nil, "picks"
  end
  local rng = VRFW.random(tostring(rule.salt or ""), { int(id, 0), int(rule.version, 1) })
  if rule.distinct == false then
    if #pool == 0 then
      return nil, "empty pool"
    end
    local accept = type(rule.accept) == "function" and rule.accept or function(c) return c end
    local out = draw_accepted(rng, pool, n, accept, int(rule.tries, 64))
    if not out then
      return nil, "no candidate accepted"
    end
    return out
  end
  if #pool < n then
    return nil, string.format("pool of %d, %d needed", #pool, n)
  end
  return draw_distinct(rng, pool, n)
end

return M
