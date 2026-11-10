-- Recruit service, script side (game Lua side: assets/lua/menu/_all/62_recruit.lua).

Recruit = Recruit or {}

local Id = VRFW.ids
local u32 = Id.unsigned

local PARAM = nil   -- card -> { element, position }
local GAME_STADIUM = nil   -- match row id -> its stadium's map crc

function Recruit.GameStadium(game)
  if GAME_STADIUM == nil then
    GAME_STADIUM = {}
    local ok, rows = pcall(VRFW.table.rows, "soccer/soccer_game_info")
    if ok and type(rows) == "table" then
      for _, r in ipairs(rows) do
        local id = u32(r.id or r[1])
        if id ~= 0 then GAME_STADIUM[id] = u32(r.stadium_map or r[4]) end
      end
    else
      VRFW.warn("recruit: soccer_game_info is not readable (" .. tostring(rows) .. "): no match row stadium")
    end
  end
  return GAME_STADIUM[u32(game)] or 0
end

local function params()
  if PARAM then return PARAM end
  PARAM = setmetatable({}, { __index = function(t, card)
    local ok, c = pcall(VRFW.character.card, card)
    if not ok or type(c) ~= "table" then return nil end
    local v = { tonumber(c.element) or 0, tonumber(c.position) or 0 }
    rawset(t, card, v)
    return v
  end })
  return PARAM
end

function Recruit.Club()
  local out = { total = 0, element = { 0, 0, 0, 0, 0 }, position = { 0, 0, 0, 0 } }
  local ok, columns = pcall(VRFW.character.saved_columns, { "param" })
  if not ok or type(columns) ~= "table" then
    VRFW.warn("recruit: the club is not readable (" .. tostring(columns) .. ")")
    return out
  end
  local P = params()
  for _, param in ipairs(columns.param) do
    local p = P[u32(param)]
    out.total = out.total + 1
    if p then
      if p[1] >= 1 and p[1] <= 5 then out.element[p[1]] = out.element[p[1]] + 1 end
      if p[2] >= 1 and p[2] <= 4 then out.position[p[2]] = out.position[p[2]] + 1 end
    end
  end
  return out
end

-- a miximax fusion holds the player (as its base or its partner): such a player is never released
local function in_fusion(handle)
  if not (VRFW.miximax and VRFW.miximax.call) then return false end
  for _, op in ipairs({ "fusion_of", "partner_fusion" }) do
    local ok, f = pcall(VRFW.miximax.call, { op = op, hdl = handle })
    if ok and type(f) == "table" and type(f.f) == "table" then return true end
  end
  return false
end

function Recruit.Holders(...)
  local want = {}
  for _, c in ipairs({ ... }) do want[u32(c)] = true end
  local out = {}
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param", "level" })
  if not ok or type(columns) ~= "table" then return out end
  for n, handle in ipairs(columns.handle) do
    local h, param = u32(handle), u32(columns.param[n])
    if math.floor(h / 4096) % 16 == 0 and want[param] then
      out[#out + 1] = { handle = h, param = param, level = tonumber(columns.level[n]) or 1, busy = in_fusion(h) }
    end
  end
  return out
end

-- every player of the club, as Holders reads it: { param, level, rarity }; nil = the club is not readable
function Recruit.Roster()
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param", "level" })
  if not ok or type(columns) ~= "table" then return nil end
  local out = {}
  for n, handle in ipairs(columns.handle) do
    local h = u32(handle)
    if math.floor(h / 4096) % 16 == 0 then
      local okR, record = pcall(VRFW.character.record, h)
      out[#out + 1] = { param = u32(columns.param[n]), level = tonumber(columns.level[n]) or 1, rarity = okR and record and record.rarity or 0 }
    end
  end
  return out
end

local ATTRIBUTE_SEASON, ATTRIBUTE_NORMAL_BANK = 0x100000, 0x400
local Protected = VRFW.protected_attributes   -- story / mod-owned record bits (content\protected_attributes)
local SEASON_RARITY = 9
local RECRUIT_SOURCES = { [2] = true, [4] = true }

local function has_bit(v, bit) return math.floor(v / bit) % 2 == 1 end

local function word(s, i)
  local a, b, c, d = string.byte(s, i * 4 + 1, i * 4 + 4)
  return a + b * 0x100 + c * 0x10000 + d * 0x1000000
end

local function leaf(t, base, name)
  local g = t:get(base .. "." .. name)
  if g and g.kind == "leaf" then return t:bytes(base .. "." .. name) end
  return nil
end

-- the players table of the save: block5 (m_Permanent).m_saveHumanP, nil when absent
local function humans_of(t)
  local base = "block5"
  local g = t:get(base .. ".m_Permanent")
  if g and g.kind == "struct" then base = base .. ".m_Permanent" end
  local h = base .. ".m_saveHumanP"
  g = t:get(h)
  if g and g.kind == "struct" then return h end
  return nil
end

Recruit.SaveAdjust = Recruit.SaveAdjust or {}

function Recruit.SaveAdjust.can_clear_season() return true end

function Recruit.SaveAdjust.clear_season(t, ev)
  local humans = humans_of(t)
  if not humans then return { error = "m_saveHumanP not found" } end
  local handles, attributes = leaf(t, humans, "handle"), leaf(t, humans, "attribute")
  local rarities, sources = leaf(t, humans, "charaRarity"), leaf(t, humans, "addPartySource")
  if not (handles and attributes and rarities and sources) then
    return { error = "m_saveHumanP handle / attribute / charaRarity / addPartySource not found" }
  end
  local count = math.floor(#handles / 4)
  if #attributes ~= #handles or #rarities ~= #handles or #sources ~= count then
    return { error = "m_saveHumanP columns of different lengths" }
  end
  local cards = leaf(t, humans, "param_id_crc")
  local out, cleared, kept = {}, 0, 0
  for i = 0, count - 1 do
    local handle, attribute = word(handles, i), word(attributes, i)
    if handle ~= 0 and has_bit(attribute, ATTRIBUTE_SEASON) then
      local rarity, source = word(rarities, i), string.byte(sources, i + 1)
      if has_bit(attribute, ATTRIBUTE_NORMAL_BANK) and not Protected.has_any(attribute) and rarity ~= SEASON_RARITY and RECRUIT_SOURCES[source] then
        out[#out + 1] = { i, attribute - ATTRIBUTE_SEASON }
        VRFW.log(string.format("save adjust: clear_season: 0x%08X card 0x%08X rarity %d source %d attribute 0x%X -> 0x%X",
          handle, cards and word(cards, i) or 0, rarity, source, attribute, attribute - ATTRIBUTE_SEASON))
      else
        kept = kept + 1
      end
    end
  end
  if #out > 0 then
    local parts, last = {}, 0
    for _, e in ipairs(out) do
      parts[#parts + 1] = attributes:sub(last * 4 + 1, e[1] * 4)
      local v = e[2]
      parts[#parts + 1] = string.char(v % 256, math.floor(v / 0x100) % 256, math.floor(v / 0x10000) % 256,
        math.floor(v / 0x1000000) % 256)
      last = e[1] + 1
    end
    parts[#parts + 1] = attributes:sub(last * 4 + 1)
    t:set_bytes(humans .. ".attribute", table.concat(parts))
    cleared = #out
  end
  local log = string.format("clear_season: %d recruited player(s) cleared, %d other season record(s) kept", cleared, kept)
  VRFW.log("save adjust: " .. log)
  return { count = cleared, log = log }
end

local match = nil   -- { user, rival } goals of the match being played

local function bump(key, n)
  local v = tonumber(VRFW.save.get(key, 0)) or 0
  VRFW.save.set(key, v + n)
end

VRFW.on("match_start", function(ev) match = { user = 0, rival = 0 } end)

VRFW.on("goal:user", function(ev)
  if match then match.user = match.user + 1 end
  bump("stats.goals", 1)
end)

VRFW.on("goal:rival", function(ev)
  if match then match.rival = match.rival + 1 end
end)

VRFW.on("match_end", function(ev)
  if match and match.user > match.rival then
    bump("stats.matches_won", 1)
  end
  match = nil
end)
