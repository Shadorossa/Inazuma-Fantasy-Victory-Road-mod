-- Classic training rules, pure Lua.

local R = {}

R.N = 9
local KICK, CONTROL, TECHNIQUE, PRESSURE, PHYSICAL, INTELLIGENCE, AGILITY, SPEED, LUCK = 0, 1, 2, 3, 4, 5, 6, 7, 8
R.SPEED, R.LUCK = SPEED, LUCK

-- stop codes (CMND_CHARACTERREFORGED_TRAINING_SET's second answer)
R.NONE, R.NO_ROOM, R.CAP, R.NOT_TRAINED, R.NO_RETURN, R.FLOOR = 0, 1, 2, 3, 4, 5

function R.position(col)
  if col == 1 or col == 2 or col == 4 then return col end
  return 3
end

local PAIRS = {
  [2] = { { KICK, TECHNIQUE }, { CONTROL, PRESSURE }, { AGILITY, LUCK }, { INTELLIGENCE, PHYSICAL } },
  [3] = { { KICK, AGILITY }, { CONTROL, TECHNIQUE }, { PRESSURE, LUCK }, { INTELLIGENCE, PHYSICAL } },
  [4] = { { KICK, AGILITY }, { CONTROL, LUCK }, { PRESSURE, TECHNIQUE }, { INTELLIGENCE, PHYSICAL } },
  [1] = { { KICK, LUCK }, { CONTROL, PRESSURE }, { AGILITY, TECHNIQUE }, { INTELLIGENCE, PHYSICAL } },
}

-- Returns the positions that have training pairs, in ascending order.
function R.positions()
  local out = {}
  for pos in pairs(PAIRS) do out[#out + 1] = pos end
  table.sort(out)
  return out
end

function R.partners(pos, i)
  local out = {}
  for _, p in ipairs(PAIRS[pos]) do
    local other
    if p[1] == i then other = p[2] elseif p[2] == i then other = p[1] end
    if other and #out < 2 then out[#out + 1] = other end
  end
  return out
end

function R.parse_rule(s)
  if type(s) ~= "string" then return nil end
  s = s:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if s == "trade" or s == "contraria" or s == "1x1" then return "trade" end
  if s == "pool" or s == "libre" then return "pool" end
  if s == "pairs" or s == "seesaw" or s == "parejas" then return "pairs" end
  return nil
end

function R.read_config(cfg)
  local name = cfg("training.rule", "trade")
  local rule = R.parse_rule(name)
  local unknown = nil
  if not rule then rule, unknown = "trade", tostring(name) end
  local rules = { rule = rule, floor_percent = math.floor(cfg("training.floor_percent", 0)),
    max_value = math.floor(cfg("training.max_value", 9999)) }
  local locked = {}
  local list = cfg("training.locked_rarities", {})
  if type(list) == "table" then
    for _, r in ipairs(list) do
      if type(r) == "number" then locked[math.floor(r)] = true end
    end
  end
  return rules, locked, unknown
end

function R.rule_code(rule)
  if rule == "pairs" then return 0 end
  if rule == "pool" then return 1 end
  return 2
end

function R.ctx(rules, pos, base, bonus, total)
  local fp = math.max(0, math.min(100, rules.floor_percent))
  local maxv = math.max(1, math.min(9999, rules.max_value))
  local c = { rule = rules.rule, pos = pos, base = base, bonus = bonus, lo = {}, hi = {}, total = math.max(total, 0) }
  for i = 0, R.N - 1 do
    c.lo[i], c.hi[i] = 0, 0
    if i ~= SPEED then
      local b = base[i]
      local floor = math.max(math.floor((math.max(b, 0) * fp + 99) / 100), 1)
      c.lo[i] = math.min(floor - b, 0)
      local extra = rules.rule == "pairs" and bonus[i] or 0
      c.hi[i] = math.max(maxv - b - extra, 0)
    end
  end
  return c
end

function R.copy(d)
  local o = {}
  for i = 0, R.N - 1 do o[i] = d[i] end
  return o
end

function R.zeros()
  local o = {}
  for i = 0, R.N - 1 do o[i] = 0 end
  return o
end

function R.equal(a, b)
  for i = 0, R.N - 1 do
    if a[i] ~= b[i] then return false end
  end
  return true
end

-- shown value (base + bonuses + delta) and trained base (base + delta)
function R.value(c, d, i) return c.base[i] + c.bonus[i] + d[i] end
local function trained_base(c, d, i) return c.base[i] + d[i] end

function R.spent(d)
  local s = 0
  for i = 0, R.N - 1 do s = s + d[i] end
  return s
end

function R.available(c, d) return c.total - R.spent(d) end

local function rank(c, d, p)
  if c.rule == "pairs" then return R.value(c, d, p) end
  return trained_base(c, d, p)
end

local function drain_partner(c, d, i)
  local best
  for _, p in ipairs(R.partners(c.pos, i)) do
    if d[p] - 1 >= c.lo[p] then
      if not (best and rank(c, d, best) >= rank(c, d, p)) then best = p end
    end
  end
  return best
end

local function raise(c, d, i)
  if d[i] + 1 > c.hi[i] then return R.CAP end
  if R.available(c, d) < 0 then return R.NO_ROOM end
  if R.available(c, d) > 0 then
    d[i] = d[i] + 1
    return nil
  end
  if c.rule == "pool" then return R.NO_ROOM end
  local p = drain_partner(c, d, i)
  if not p then return R.NO_ROOM end
  d[p] = d[p] - 1
  d[i] = d[i] + 1
  return nil
end

local function lower(c, d, i)
  if c.rule == "pool" then
    if d[i] - 1 < c.lo[i] then return R.FLOOR end
    d[i] = d[i] - 1
    return nil
  end
  if d[i] <= 0 then return c.rule == "trade" and R.FLOOR or R.NOT_TRAINED end
  local repay
  for _, p in ipairs(R.partners(c.pos, i)) do
    if d[p] < 0 then
      local keep = false
      if repay then
        local dr, dp = d[repay], d[p]
        keep = dr < dp or (dr == dp and R.value(c, d, repay) <= R.value(c, d, p))
      end
      if not keep then repay = p end
    end
  end
  local can_return = R.spent(d) >= 1
  local prefer_repay = R.available(c, d) == 0
  if repay and (prefer_repay or not can_return) then
    d[repay] = d[repay] + 1
    d[i] = d[i] - 1
    return nil
  end
  if can_return then
    d[i] = d[i] - 1
    return nil
  end
  if repay then
    d[repay] = d[repay] + 1
    d[i] = d[i] - 1
    return nil
  end
  return R.NO_RETURN
end

local function raise_many(c, d, i, want)
  while want > 0 do
    local room = c.hi[i] - d[i]
    if room <= 0 then return R.CAP end
    local free = R.available(c, d)
    if free < 0 then return R.NO_ROOM end
    local n
    if free > 0 then
      n = math.min(want, room, free)
    else
      if c.rule == "pool" then return R.NO_ROOM end
      local p = drain_partner(c, d, i)
      if not p then return R.NO_ROOM end
      n = #R.partners(c.pos, i) == 1 and math.min(want, room, d[p] - c.lo[p]) or 1
      d[p] = d[p] - n
    end
    d[i] = d[i] + n
    want = want - n
  end
  return nil
end

function R.set(c, d, i, target)
  if target > d[i] then
    local stop = raise_many(c, d, i, target - d[i])
    return d[i], stop or R.NONE
  end
  local steps = d[i] - target
  for _ = 1, steps do
    local stop = lower(c, d, i)
    if stop then return d[i], stop end
  end
  return d[i], R.NONE
end

-- the lowest and highest delta set() can reach for stat i from d (d unchanged)
function R.range(c, d, i)
  local lo = R.copy(d)
  local min = R.set(c, lo, i, math.min(c.lo[i], d[i], 0) - 1)
  local hi = R.copy(d)
  local max = R.set(c, hi, i, c.hi[i] + 1)
  return min, math.max(max, d[i])
end

-- the stable maximum delta of stat i the menu shows (not what is reachable from the current state)
function R.cap(c, d, i)
  if c.rule == "pool" then
    local _, from_zero = R.range(c, R.zeros(), i)
    return math.max(from_zero, d[i])
  end
  local group = {}
  for k = 0, R.N - 1 do group[k] = false end
  group[i] = true
  repeat
    local grew = false
    for _, p in ipairs(PAIRS[c.pos]) do
      if group[p[1]] ~= group[p[2]] then
        group[p[1]], group[p[2]] = true, true
        grew = true
      end
    end
  until not grew
  local give = 0
  for k = 0, R.N - 1 do
    if group[k] and k ~= i then give = give - c.lo[k] end
  end
  return math.max(math.min(c.total + give, c.hi[i]), d[i])
end

return R
