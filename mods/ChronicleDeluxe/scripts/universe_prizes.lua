
ChronicleDeluxe = ChronicleDeluxe or {}

local Id = VRFW.ids
local u32 = Id.unsigned

local info, warn = VRFW.logger("ChronicleDeluxe.UniversePrizes")

local FOLDER = "content/universe_prizes"
local KIND = "ChronicleDeluxe.universe_prize/1"
local DEFAULT_POOL = "items"
-- the chance shown for a pool without its config value
local NO_CHANCE = 0
local POOL_TEXT = "ChronicleDeluxe.universe_prize_pool_"

local ITEM_TABLE = "data/common/gamedata/item/item_config"
local ITEM_ID, ITEM_SUB_CATEGORY = 1, 7              -- 1-based columns shared by the item lists
local SKILL_TABLE = "data/common/gamedata/skill/skill_config"
local SKILL_ROWS = "m_skillInfoList"

local POOLS = nil
local rolls = 0

local function skill_powers()
  local powers = {}
  for _, row in ipairs(VRFW.table.raw(VRFW.table_files.file_name(SKILL_TABLE), SKILL_ROWS)) do
    powers[u32(row.skillID)] = tonumber(row.power_min)
  end
  return powers
end

local settings_warned = {}

-- a number of config.toml (its only value), or nil with one warning when it is missing or not a number
local function setting(path, min, max, effect)
  local v = VRFW.config(path, nil, min, max)
  if v == nil and not settings_warned[path] then
    settings_warned[path] = true
    VRFW.warn("config: config.toml " .. path .. " is missing or not a number: " .. effect)
  end
  return v
end

local function resolve_category(prize, pool_name, where)
  local wanted = {}
  for _, sub_category in ipairs(type(prize.sub_categories) == "table" and prize.sub_categories or {}) do
    wanted[sub_category] = true
  end
  local sold = prize.sold_in_shop and VRFW.shop.sold_items() or nil
  local powers = prize.weight_by_skill_power and skill_powers() or nil
  local exponent = powers and setting("universe_prizes." .. pool_name .. ".power_exponent", 0, 8, "its techniques weigh the same") or nil
  local items, running, total = {}, {}, 0
  for _, row in ipairs(VRFW.table.raw(VRFW.table_files.file_name(ITEM_TABLE), tostring(prize.list), { ITEM_ID, ITEM_SUB_CATEGORY })) do
    local id = u32(row[ITEM_ID])
    if wanted[row[ITEM_SUB_CATEGORY]] and (sold == nil or sold[id]) then
      local power = powers and powers[id] or nil
      if powers == nil or (power ~= nil and power > 0) then
        total = total + (exponent and power ^ -exponent or 1)
        items[#items + 1] = id
        running[#items] = total
      end
    end
  end
  info(string.format("%s: pool %s: %d item(s) of %s", where, pool_name, #items, tostring(prize.list)))
  return items, running, total
end

local function pools()
  if POOLS ~= nil then
    return POOLS
  end
  POOLS = {}
  local by_name = {}
  for _, file in ipairs(VRFW.files.declarations(FOLDER)) do
    local where = string.format("mods/%s/%s", tostring(file.mod), tostring(file.file))
    local data = type(file.data) == "table" and file.data or {}
    if data.schema ~= KIND then
      warn(where .. ": schema " .. tostring(data.schema) .. " is not " .. KIND .. ": file left out")
    else
      local own = type(data.ChronicleDeluxe) == "table" and data.ChronicleDeluxe.UniversePrize or nil
      for _, prize in ipairs(type(own) == "table" and own or {}) do
        local pool_name = type(prize.pool) == "string" and prize.pool or DEFAULT_POOL
        local entry = { weight = tonumber(prize.weight) or 0 }
        if prize.kind == "category" then
          entry.items, entry.running, entry.total = resolve_category(prize, pool_name, where)
        elseif type(prize.item) == "string" and prize.item ~= "" then
          entry.item = VRFW.crc32(prize.item)
        end
        if entry.weight <= 0 or (entry.item == nil and (entry.items == nil or #entry.items == 0)) then
          warn(where .. ": a prize needs a weight above 0 and an item or a category with items: left out")
        else
          local pool = by_name[pool_name]
          if pool == nil then
            pool = { name = pool_name, entries = {}, weights = {} }
            by_name[pool_name] = pool
            POOLS[#POOLS + 1] = pool
          end
          pool.entries[#pool.entries + 1] = entry
          pool.weights[#pool.entries] = entry.weight
        end
      end
    end
  end
  info(string.format("prize pools declared: %d", #POOLS))
  return POOLS
end

local function pick_from_category(entry, random)
  local target = random:float() * entry.total
  local low, high = 1, #entry.items
  while low < high do
    local middle = math.floor((low + high) / 2)
    if entry.running[middle] > target then
      high = middle
    else
      low = middle + 1
    end
  end
  return entry.items[low]
end

-- the chance in percent that a pull adds an item of this pool (nil without its config value: the pool gives nothing)
local function pool_chance(pool, is_last_star)
  local key = is_last_star and ".last_star_chance_percent" or ".chance_percent"
  return setting("universe_prizes." .. pool.name .. key, 0, 100, "the pool gives nothing")
end

local function pool_summary(pool)
  if pool.count ~= nil then
    return pool.count, pool.likely
  end
  local total = 0
  for _, weight in ipairs(pool.weights) do
    total = total + weight
  end
  local count, likely, best = 0, 0, -1
  for _, entry in ipairs(pool.entries) do
    local share = entry.weight / total
    if entry.item ~= nil then
      count = count + 1
      if share > best then
        likely, best = entry.item, share
      end
    else
      count = count + #entry.items
      local previous = 0
      for k, item in ipairs(entry.items) do
        local item_share = share * (entry.running[k] - previous) / entry.total
        previous = entry.running[k]
        if item_share > best then
          likely, best = item, item_share
        end
      end
    end
  end
  pool.count, pool.likely = count, likely
  return count, likely
end

function ChronicleDeluxe.UniversePrizeRates(is_last_star)
  is_last_star = is_last_star == 1
  local rows = {}
  for _, pool in ipairs(pools()) do
    local count, likely = pool_summary(pool)
    rows[#rows + 1] = VRFW.crc32(POOL_TEXT .. pool.name)
    rows[#rows + 1] = pool_chance(pool, is_last_star) or NO_CHANCE
    rows[#rows + 1] = count
    rows[#rows + 1] = likely
  end
  return rows
end

function ChronicleDeluxe.RollUniversePrize(is_last_star)
  is_last_star = is_last_star == 1
  local won = {}
  for _, pool in ipairs(pools()) do
    local chance = pool_chance(pool, is_last_star)
    rolls = rolls + 1
    local random = VRFW.random("ChronicleDeluxe.universe_prize", { VRFW.random.int(0, 2147483646), rolls })
    if chance ~= nil and random:float() * 100 < chance then
      local entry = pool.entries[random:weighted(pool.weights)]
      won[#won + 1] = entry.item or pick_from_category(entry, random)
    end
  end
  return table.unpack(won)
end

-- (upper) -> a whole number from 1 to upper for the pulls that leave out the held cards
function ChronicleDeluxe.UniverseRoll(upper)
  rolls = rolls + 1
  local random = VRFW.random("ChronicleDeluxe.universe_pool", { VRFW.random.int(0, 2147483646), rolls })
  return math.floor(random:float() * upper) + 1
end
