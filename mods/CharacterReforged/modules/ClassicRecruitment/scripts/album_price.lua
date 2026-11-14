ClassicRecruitment = ClassicRecruitment or {}

local info, warn = VRFW.logger("album_price")

local RULE = nil

local function card_values(file)
  local value, prices = {}, {}
  if type(file) ~= "string" or file == "" then return value, 0 end
  local ok, doc, why = pcall(VRFW.files.toml, file)
  if not ok or type(doc) ~= "table" then
    warn(string.format("%s not read (%s): every card takes value 0", file, tostring(ok and why or doc)))
    return value, 0
  end
  local sets = type(doc.VRFW) == "table" and doc.VRFW.ContactTerms or nil
  for _, set in ipairs(type(sets) == "table" and sets or {}) do
    for _, t in ipairs(type(set.Terms) == "table" and set.Terms or {}) do
      local card, price = tonumber(t.Card), tonumber(t.Price)
      if card ~= nil and price ~= nil and value[card] == nil then
        value[card] = price
        prices[#prices + 1] = price
      end
    end
  end
  table.sort(prices)
  local median = #prices > 0 and prices[math.floor((#prices + 1) / 2)] or 0
  return value, median, #prices
end

-- the values the mods declare (content/album/*.toml album_values) over `value`
local function add_declared_values(value)
  local ok, decls = pcall(VRFW.files.declarations, { "content/album" })
  for _, d in ipairs(ok and type(decls) == "table" and decls or {}) do
    local rows = type(d.data) == "table" and d.data.album_values or nil
    for _, row in ipairs(type(rows) == "table" and rows or {}) do
      local card, v = tonumber(row.card), tonumber(row.value)
      if card ~= nil and v ~= nil then value[card] = v end
    end
  end
end

local function rule()
  if RULE ~= nil then return RULE end
  RULE = false
  local cfg = VRFW.config("album")
  if type(cfg) ~= "table" or type(cfg.currency) ~= "string" or cfg.currency == "" then
    warn("config.toml [album] has no currency: album signings are free")
    return RULE
  end
  local factor = {}
  for k, v in pairs(type(cfg.rarity_factor) == "table" and cfg.rarity_factor or {}) do
    local r, f = tonumber(k), tonumber(v)
    if r ~= nil and f ~= nil and f >= 0 then factor[math.floor(r)] = f end
  end
  -- The card values come from mod files only, so the derived store keeps them between starts.
  local kept = VRFW.derived("album_values", { cfg.value_file }, function()
    local v, m, n = card_values(cfg.value_file)
    add_declared_values(v)
    return { value = v, median = m, count = n }
  end)
  local value, median, count = kept.value, kept.median, kept.count
  RULE = { item = VRFW.crc32(cfg.currency), base = tonumber(cfg.base) or 0, per_value = tonumber(cfg.per_value) or 0,
    per_level = tonumber(cfg.per_level) or 0, level_cap = tonumber(cfg.level_cap), factor = factor, value = value,
    median = median, icon_atlas = cfg.icon_atlas, icon_sprite = cfg.currency }
  info(string.format("album price: %s, %s + %s per value point (%d card(s) valued, median %s) + %s per level",
    cfg.currency, tostring(RULE.base), tostring(RULE.per_value), count or 0, tostring(median), tostring(RULE.per_level)))
  return RULE
end

-- CMND_CLASSICRECRUITMENT_ALBUM_PRICE(rarity, level, card) -> item id, count
function ClassicRecruitment.AlbumPrice(rarity, level, card)
  local r = rule()
  if not r then return end
  local lv = math.max(1, math.floor(tonumber(level) or 1))
  if r.level_cap ~= nil and r.level_cap > 0 then lv = math.min(lv, r.level_cap) end
  local f = r.factor[math.floor(tonumber(rarity) or 0)] or 1
  local v = r.value[tonumber(card) or -1] or r.median
  local count = math.max(0, math.floor((r.base + r.per_value * v + r.per_level * lv) * f + 0.5))
  return r.item, count
end

function ClassicRecruitment.AlbumPrices(level, cards)
  local counts = {}
  local r = rule()
  if not r then return counts end
  for _, entry in ipairs(VRFW.strings.split(cards, ",")) do
    local rarity, card = string.match(entry, "^(-?%d+):(-?%d+)$")
    local ok, _, count = pcall(ClassicRecruitment.AlbumPrice, tonumber(rarity), level, tonumber(card))
    if not ok then warn(string.format("no album price for %s: %s", entry, tostring(_))) end
    counts[#counts + 1] = ok and tonumber(count) or 0
  end
  return counts, r.icon_atlas, r.icon_sprite
end

-- The rule reads mod files only, so the script load (off the game thread) builds it before any save load.
rule()
