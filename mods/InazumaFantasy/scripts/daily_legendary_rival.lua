
local info, warn = VRFW.logger("daily legendary rival")

local BLOB = "if_daily_legendary_rival.json"
local DOC_VERSION = 1
local SLOT_TEAM_PLAYERS = 16

local function settings()
  local s = {
    salt = tostring(VRFW.config("daily_legendary_rival.salt", "InazumaFantasy.DailyLegendaryRival")),
    version = VRFW.config("daily_legendary_rival.version", 1, 1, 1000000),
    level = VRFW.config("daily_legendary_rival.level", 250, 1, 999),
    class = VRFW.config("daily_legendary_rival.class", 9, 1, 255),
    game = tostring(VRFW.config("daily_legendary_rival.game", "inazuma_fantasy_daily_legendary_rival")),
    min_players = VRFW.config("daily_legendary_rival.min_players", 11, 1, 19),
    keep_days = VRFW.config("daily_legendary_rival.keep_days", 60, 1, 3650),
    reward = VRFW.config("daily_legendary_rival.reward", 10, 0, 255),
    reward_item = tostring(VRFW.config("daily_legendary_rival.reward_item", "tk_bb000001")),
    chronicle_prefix = tostring(VRFW.config("daily_legendary_rival.chronicle_prefix", "fbtl_cro")),
    exclude = {},
  }
  local x = VRFW.config("daily_legendary_rival.exclude", {})
  for _, k in ipairs(type(x) == "table" and x or {}) do
    if type(k) == "string" then s.exclude[VRFW.crc32(k)] = true end
  end
  return s
end

local Id = VRFW.ids
local Catalogue = VRFW.catalogue
local TeamConfig = VRFW.teams.config
local Daily = VRFW.daily
local u32 = Id.unsigned

local POOL = nil   -- the eligible team ids, sorted

-- the player cards of `team` in slot order (staff out), at most SLOT_TEAM_PLAYERS, its count, its coach card (0 = none)
local function players_of(team)
  local list, coach = {}, 0
  for _, m in ipairs(Catalogue.members(team)) do
    if m.card ~= 0 and not TeamConfig.is_staff(m.slot) then list[#list + 1] = { card = m.card, slot = m.slot } end
    if m.card ~= 0 and m.slot == TeamConfig.COACH_SLOT then coach = m.card end
  end
  table.sort(list, function(a, b) return a.slot < b.slot end)
  local cards = {}
  for i = 1, math.min(#list, SLOT_TEAM_PLAYERS) do cards[i] = list[i].card end
  return cards, #list, coach
end

local function pool(s)
  if POOL then return POOL end
  local teams, why = Catalogue.free_match_teams(s.class)
  if not teams then
    warn("free-match list not readable (" .. tostring(why) .. "): no rival")
    return {}
  end
  local slot_team = VRFW.crc32("evt_ct_ft_daily_legendary_rival")
  local ids = {}
  for _, team in ipairs(teams) do
    local _, players = players_of(team)
    if team ~= slot_team and not s.exclude[u32(team)] and players >= s.min_players then ids[#ids + 1] = team end
  end
  table.sort(ids)
  info(string.format("pool: %d of the %d free-match team(s), each with at least %d players", #ids, #teams, s.min_players))
  if #ids > 0 then POOL = ids end
  return ids
end

local function pick(s, day)
  local team, why = Daily.cycle({ salt = s.salt, version = s.version, pool = pool(s) }, day)
  if not team then
    warn(string.format("day %d: no rival (%s), the row keeps its own team", day, tostring(why)))
    return nil
  end
  local cards, _, coach = players_of(team)
  return { team = team, cards = cards, coach = coach }
end

local PICKED = {}   -- [day] = the day's pick (one per session)

local VENUES = nil   -- what the tables say about stadiums, read once

local function scalar(v)
  if type(v) == "table" then return v.text or v[1] end
  return v
end

local function map_id(v)
  v = tonumber(scalar(v))
  if v == nil or v == 0 then return nil end
  return u32(v)
end

local function count_best(counts, best, key, value)
  local c = counts[key]
  if not c then
    c = {}
    counts[key] = c
  end
  c[value] = (c[value] or 0) + 1
  if not best[key] or c[value] > c[best[key]] then best[key] = value end
end

local function read_maps()
  local maps = {}   -- map crc -> map name
  local ok, rows = pcall(VRFW.table.rows, "map/map")
  if not ok or type(rows) ~= "table" or #rows == 0 then
    warn("map table not readable (" .. tostring(rows) .. "): stadiums are not checked against it")
    return nil
  end
  for _, r in ipairs(rows) do
    local id = map_id(r.map_id or r[1])
    if id then maps[id] = tostring(scalar(r.map_name or r[2])) end
  end
  return maps
end

local function read_team_names()
  local names = {}   -- team id -> name text (first row of the id)
  for _, r in ipairs(Catalogue.team_rows() or {}) do
    local id = u32(tonumber(scalar(r.id or r[1])) or 0)
    if id ~= 0 and names[id] == nil then names[id] = u32(tonumber(scalar(r.name_text or r[4])) or 0) end
  end
  return names
end

local function read_battle_bay(names)
  local best, counts = {}, {}   -- team name -> map
  local ok, rows = pcall(VRFW.table.rows, "team/enjoy_mode_team")
  if not ok or type(rows) ~= "table" then
    warn("Battle Bay teams not readable (" .. tostring(rows) .. ")")
    return best
  end
  for _, r in ipairs(rows) do
    local name = names[u32(tonumber(scalar(r.team or r[1])) or 0)]
    local map = map_id(r.stadium_map or r[5])
    if name and name ~= 0 and map then count_best(counts, best, name, map) end
  end
  return best
end

local function read_games()
  local key = VRFW.table.source("soccer/soccer_game_info")
  local list, by_id, cur, diffs = {}, {}, nil, {}
  for _, e in ipairs(VRFW.table.entries(key, { "SOCCER_GAME_INFO", "SOCCER_GAME_INFO_REF_DIFFICULTY",
    "SOCCER_GAME_DIFFICULTY" }, true)) do
    if e.name == "SOCCER_GAME_INFO" then
      cur = { id = u32(tonumber(scalar(e[1])) or 0), key = scalar(e[2]), map = map_id(e[4]) }
      list[#list + 1] = cur
      by_id[cur.id] = cur
    elseif e.name == "SOCCER_GAME_INFO_REF_DIFFICULTY" then
      if cur then cur.first, cur.count = tonumber(e[1]) or 0, tonumber(e[2]) or 0 end
    elseif e.name == "SOCCER_GAME_DIFFICULTY" then
      diffs[#diffs + 1] = { class = tonumber(e[1]) or 0, team = u32(tonumber(e[2]) or 0) }
    end
  end
  for _, g in ipairs(list) do
    g.rows = {}
    for k = (g.first or 0) + 1, (g.first or 0) + (g.count or 0) do
      if diffs[k] then g.rows[#g.rows + 1] = diffs[k] end
    end
  end
  return list, by_id
end

local function read_venues(s)
  local names = read_team_names()
  local out = { names = names, maps = read_maps(), battle_bay = read_battle_bay(names), chronicle = {}, row = {} }
  local ok, why = pcall(function()
    local list, by_id = read_games()
    local counts = {}
    for _, g in ipairs(list) do
      if type(g.key) == "string" and g.key:sub(1, #s.chronicle_prefix) == s.chronicle_prefix and g.map then
        local seen = {}
        for _, d in ipairs(g.rows) do
          local name = names[d.team]
          if name and name ~= 0 and not seen[name] then
            seen[name] = true
            count_best(counts, out.chronicle, name, g.map)
          end
        end
      end
    end
    -- the team's own free-match game, in list order.
    for _, r in ipairs(VRFW.table.rows("soccer/soccer_opponent_info")) do
      local g = by_id[u32(tonumber(scalar(r.battleId or r[2])) or 0)]
      if g and g.map then
        for _, d in ipairs(g.rows) do
          if d.class == s.class and d.team ~= 0 and out.row[d.team] == nil then out.row[d.team] = g.map end
        end
      end
    end
    local own = by_id[u32(VRFW.crc32(s.game))]
    out.template = own and own.map or nil
  end)
  if not ok then warn("game rows not readable (" .. tostring(why) .. "): no Chronicle venue, no free-match stadium") end
  return out
end

local function venues(s)
  if not VENUES then VENUES = read_venues(s) end
  return VENUES
end

local function rival_stadium(s, team, declared)
  local v = venues(s)
  local name = v.names[team]
  local row = v.row[team]
  if row == v.template then row = nil end
  local choices = {
    { map = map_id(declared), source = "declared" },
    { map = name and v.battle_bay[name], source = "battle_bay" },
    { map = name and v.chronicle[name], source = "chronicle" },
    { map = row, source = "free_match_row" },
  }
  for _, c in ipairs(choices) do
    if c.map then
      if v.maps == nil or v.maps[c.map] then return c.map, c.source end
      warn(string.format("team 0x%08X: %s stadium 0x%08X is not in the map table (ignored)", team, c.source, c.map))
    end
  end
  return nil, "none"
end

local CENSUS_DONE = false

local function census(s)
  if CENSUS_DONE then return end
  CENSUS_DONE = true
  local ids = pool(s)
  local keys, without = {}, {}
  for _, r in ipairs(Catalogue.team_rows() or {}) do
    local id = u32(tonumber(scalar(r.id or r[1])) or 0)
    if keys[id] == nil then keys[id] = tostring(scalar(r.key or r[2])) end
  end
  for _, team in ipairs(ids) do
    if not rival_stadium(s, team, 0) then without[#without + 1] = keys[team] or string.format("0x%08X", team) end
  end
  info(string.format("stadiums: %d of the %d pool team(s) have none in the tables: %s", #without, #ids,
    #without > 0 and table.concat(without, ", ") or "-"))
end

local STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "daily legendary rival",
  default = function() return { v = DOC_VERSION, days = {}, paid = {} } end,
  decode = function(doc)
    if doc.v ~= DOC_VERSION or type(doc.days) ~= "table" then return nil, "not a version " .. DOC_VERSION .. " record" end
    if type(doc.paid) ~= "table" then doc.paid = {} end
    return doc
  end,
})

local function load()
  return (STORE:get())
end

local function save(keep)
  local doc = load()
  local keys = {}
  for k in pairs(doc.days) do keys[#keys + 1] = k end
  table.sort(keys)
  for i = 1, #keys - keep do doc.days[keys[i]] = nil end
  for k in pairs(doc.paid) do
    if doc.days[k] == nil then doc.paid[k] = nil end
  end
  local ok, why = STORE:put(doc, nil, true)
  if not ok then warn(BLOB .. " not written: " .. tostring(why)) end
end

local LAST_DAY = nil   -- the day the menu last asked for (the day a win counts for)

InazumaFantasy = InazumaFantasy or {}

function InazumaFantasy.DailyRival(day)
  day = math.floor(tonumber(day) or -1)
  if day < 0 then return { ok = false, why = "day" } end
  local s = settings()
  local got = PICKED[day]
  if got == nil then
    got = pick(s, day) or false
    PICKED[day] = got
  end
  local doc = load()
  if not got then
    return { ok = false, why = "no team", level = s.level, reward = s.reward, done = doc.days[tostring(day)] == true }
  end
  LAST_DAY = day
  return { ok = true, day = day, team = got.team, cards = got.cards, coach = got.coach, level = s.level,
    done = doc.days[tostring(day)] == true, paid = doc.paid[tostring(day)] == true, reward = s.reward,
    pool = #pool(s) }
end

function InazumaFantasy.DailyRivalStadium(team, declared, row_map)
  local s = settings()
  team = u32(tonumber(team) or 0)
  census(s)
  local map, source = rival_stadium(s, team, declared)
  local names = venues(s).maps
  local shown = map or map_id(row_map) or 0
  info(string.format("match: rival team 0x%08X, stadium 0x%08X (%s), source %s", team, shown,
    names and names[shown] or "?", source))
  return map or 0, source
end

function InazumaFantasy.DailyRivalReward(day)
  local key = tostring(math.floor(tonumber(day) or -1))
  local s = settings()
  local doc = load()
  if s.reward <= 0 or doc.days[key] ~= true or doc.paid[key] == true then return 0, 0 end
  return VRFW.crc32(s.reward_item), s.reward
end

-- the day's reward given (the menu added it to the bag)
function InazumaFantasy.DailyRivalPaid(day)
  local key = tostring(math.floor(tonumber(day) or -1))
  local s = settings()
  local doc = load()
  if doc.days[key] ~= true or doc.paid[key] == true then return false end
  doc.paid[key] = true
  save(s.keep_days)
  info(string.format("day %s: reward paid (%d x %s)", key, s.reward, s.reward_item))
  return true
end

VRFW.on("signal:vrfw.match_result", function()
  local last = VRFW.match.results.last()
  if type(last) ~= "table" or LAST_DAY == nil then return nil end
  local s = settings()
  if last.game ~= VRFW.crc32(s.game) or last.difficulty ~= s.class or last.outcome ~= "win" then return nil end
  local doc = load()
  local key = tostring(LAST_DAY)
  if not doc.days[key] then
    doc.days[key] = true
    save(s.keep_days)
    info(string.format("day %d beaten (%d-%d)", LAST_DAY, last.score_for or 0, last.score_against or 0))
  end
  return nil
end)
