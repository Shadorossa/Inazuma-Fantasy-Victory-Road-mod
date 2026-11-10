
local M = {}

M.N = 9
M.LUCK = 8
M.RETIRED = 7

local Id = VRFW.ids
local u32 = Id.unsigned
M.u32 = u32

function M.ready()
  local ok, r = pcall(function() return CharacterReforged.StatsReady() end)
  return ok and r == true
end

local function card(key)
  local ok, r = pcall(function() return CharacterReforged.StatCard(key) end)
  if not ok or type(r) ~= "table" then return nil end
  local vals = {}
  for i = 0, 8 do
    local v = type(r.vals) == "table" and r.vals[i] or nil
    vals[i] = type(v) == "number" and v or 0
  end
  return { key = key, growth = r.growth or 1, vals = vals, libertad = r.libertad, pos = r.pos or 0, rarity = r.rarity or 0 }
end

local function native_card(key)
  local ok, c = pcall(VRFW.character.card, key)
  if not ok or type(c) ~= "table" then return nil end
  local vals = {}
  for i = 0, M.N - 1 do vals[i] = 0 end
  return { key = key, native = true, growth = 1, vals = vals, libertad = nil, pos = c.position or 0, rarity = c.rarity or 0 }
end

function M.players()
  local miss = {}
  return setmetatable({}, { __index = function(t, key)
    if type(key) ~= "number" then return nil end
    key = u32(key)
    if miss[key] then return nil end
    if not M.ready() then return nil end
    local p = card(key) or native_card(key)
    if p then rawset(t, key, p) else miss[key] = true end
    return p
  end })
end

-- a card that cannot be trained (rarity in `locked`, a set { [rarity] = true })
function M.locked(p, locked)
  return locked[p.rarity] == true
end

function M.luck(p, level, base)
  if not p.native then return M.stat(p, M.LUCK, level) end
  if type(base) ~= "table" then return 0 end
  local ok, v = pcall(function() return CharacterReforged.DerivedLuck(base) end)
  return (ok and type(v) == "number") and v or 0
end

-- stat `idx` (0..8) of a card at `level`
function M.stat(p, idx, level)
  local ok, v = pcall(function() return CharacterReforged.StatAt(p.key, idx, level) end)
  if ok and type(v) == "number" then return v end
  return p.vals[idx] or 0
end

local BUDGET = { percent = 0 }
local BUDGET_AT = {} -- [level] = Budget(level), filled once per level
function M.configure_budget(rule)
  BUDGET = rule
  BUDGET_AT = {}
end

function M.budget(level)
  local l = math.floor(level)
  if BUDGET_AT[l] then return BUDGET_AT[l] end
  local ok, top = pcall(function() return CharacterReforged.StatTotalMax(l) end)
  if not ok or type(top) ~= "number" or top <= 0 then return nil end
  local b = math.floor(top * (1 + BUDGET.percent / 100) + 0.5)
  BUDGET_AT[l] = b
  return b
end

function M.libertad(p, level, base)
  local b = M.budget(level)
  if not b or type(base) ~= "table" then return 0 end
  local sum = 0
  for i = 0, M.N - 1 do
    if i ~= M.RETIRED then sum = sum + (base[i] or 0) end
  end
  return math.max(0, b - sum)
end

return M
