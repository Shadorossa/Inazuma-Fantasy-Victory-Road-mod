-- The Tournament's view: the rival, emblems, kit strips, the view command, team tactics and the league squad commands.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local V = require "lib/tourney_view"
local G = require "lib/game"
local Catalogue = Shared.Catalogue
local LS = require "league_squad"
local Tn = Shared.Tn
local info = Shared.info
local warn = Shared.warn
local team_rows = Shared.team_rows
local levels = Shared.levels
local story_set = Shared.story_set
local name_text = Shared.name_text
local save = Shared.save
local load = Shared.load
local exclusion_set = Shared.exclusion_set
local card_stats = Shared.card_stats
local final_stadium = Shared.final_stadium

-- the rival of the player's match k (team hash, 0 = not known yet)
function Tn.rival_of(run, k)
  local n = 0
  local p = run.player
  local function walk(m)
    if m.a == p or m.b == p then
      n = n + 1
      if n == k then
        local o = m.a == p and m.b or m.a
        return o ~= 0 and run.teams[o] or 0
      end
    end
    return nil
  end
  if run.gm then
    for md = 1, run.mds or 3 do
      for _, gm in ipairs(run.gm) do
        for _, m in ipairs(gm) do
          if m.md == md then
            local r = walk(m)
            if r then
              return r
            end
          end
        end
      end
    end
  end
  for _, rd in ipairs(run.ko) do
    for _, m in ipairs(rd) do
      local r = walk(m)
      if r then
        return r
      end
    end
  end
  return 0
end

local EMBLEMS = nil
local function emblems()
  if EMBLEMS then
    return EMBLEMS
  end
  EMBLEMS = {}
  local ok, rows = team_rows()
  if ok and type(rows) == "table" then
    for _, r in ipairs(rows) do
      local id, em = r.id or r[1], r.emblem or r[7]
      if type(id) == "number" and type(em) == "number" then
        EMBLEMS[VRFW.ids.unsigned(id)] = VRFW.ids.unsigned(em)
      end
    end
  else
    warn("team table not readable: the bracket's plates keep the list plate")
  end
  return EMBLEMS
end

local STRIP = U.config("bracket_strips", {})
STRIP = type(STRIP) == "table" and STRIP or {}
STRIP.names = type(STRIP.names) == "table" and STRIP.names or {}
STRIP.index = {}
for i, n in ipairs(STRIP.names) do
  STRIP.index[n] = i
end

local function strip_of(team)
  local em = emblems()[VRFW.ids.unsigned(team or 0)]
  if not em or em == 0 then
    return nil
  end
  local names = STRIP.names
  local index = STRIP.index[Catalogue.colour_name(em, STRIP) or ""]
  return index or (em % math.max(#names, 1)) + 1
end

-- every team plate of a view (tree leaves, results rows) gets .strip
local function add_strips(v)
  local function one(p)
    if type(p) == "table" and (p.team or 0) ~= 0 then
      p.strip = strip_of(p.team)
    end
  end
  for _, p in pairs(type(v.leaves) == "table" and v.leaves or {}) do
    one(p)
  end
  if type(v.rows) == "table" then
    for _, r in pairs(v.rows) do
      if type(r) == "table" then
        one(r.a)
        one(r.b)
        one(r)   -- a top scorers row (its team)
      end
    end
  end
  -- the hub's next fixture
  if type(v.fixture) == "table" then
    one(v.fixture.home)
    one(v.fixture.away)
  end
  -- the hub's dashboard rows (standings, top scorers, results, fixtures)
  for _, list in ipairs({ v.top, v.scorers, v.results, v.fixtures }) do
    if type(list) == "table" then
      for _, r in pairs(list) do
        one(r)
      end
    end
  end
  -- the league's standings rows (their plates are the bracket's team strips)
  if type(v.standings) == "table" then
    for _, r in pairs(v.standings) do
      one(r)
    end
  end
  return v
end

-- What the overlay draws (the graft resolves names / emblems from the team hashes and texts from text keys).
function BattleBayDeluxe.TournamentView(page)
  local run = load()
  if not run then
    return { kind = "none" }
  end
  local v = V.build(run, U.int(page, -1))
  if type(v) == "table" then
    pcall(add_strips, v)
    -- the tree page's final stadium (the bracket screen, VRFW_Bracket, draws it from the view)
    if v.kind == "tree" then
      local okf, map = pcall(final_stadium, run)
      if okf and type(map) == "string" and map ~= "" then
        v.final_stadium = { map = map, id = VRFW.crc32(map) }
      end
    end
    if v.kind == "squad" and (v.team or 0) ~= 0 and Tn.roster then
      pcall(LS.ensure, run.fmt == "league" and run.lineup or nil)
      local ok, rows = pcall(Tn.roster, v.team)
      local st = card_stats()
      for _, m in ipairs(ok and type(rows) == "table" and rows or {}) do
        local slot, card = U.int(m[1], 99), VRFW.ids.unsigned(m[2] or 0)
        if card ~= 0 then
          v.rows[#v.rows + 1] = { slot = slot, card = card, pos = st[card] and st[card].pos or 0 }
        end
      end
      table.sort(v.rows, function(a, b)
        return a.slot < b.slot
      end)
    end
    if (v.kind == "hub" or v.kind == "squad") and (v.team or 0) ~= 0 then
      local ok, lv = pcall(function()
        return levels()[VRFW.ids.unsigned(v.team)]
      end)
      v.level = ok and lv or false
    end
  end
  return v
end

local TACTICS = nil
local function team_tactics(team)
  if TACTICS == nil then
    TACTICS = {}
    local ok, err = pcall(function()
      local key = VRFW.table.source("team/team")
      local info = VRFW.table.raw(key, "SOCCER_TEAM_INFO", { 1 })
      local refs = VRFW.table.raw(key, "SOCCER_TEAM_INFO_REF_TACTICS", { 1, 2 })
      local list = VRFW.table.raw(key, "SOCCER_TEAM_TACTICS", { 1 })
      if type(info) ~= "table" or type(refs) ~= "table" or type(list) ~= "table" or #refs ~= #info then
        error("team rows and tactics refs do not match")
      end
      local function scalar(v)
        if type(v) == "table" then
          return v[1]
        end
        return v
      end
      for i, t in ipairs(info) do
        local id = VRFW.ids.unsigned(tonumber(scalar(t[1])) or 0)
        local first, count = tonumber(scalar(refs[i][1])), tonumber(scalar(refs[i][2]))
        if id ~= 0 and TACTICS[id] == nil and first and count then
          local ids = {}
          for k = first + 1, first + count do
            local v = list[k] and tonumber(scalar(list[k][1]))
            if v and v ~= 0 then
              ids[#ids + 1] = VRFW.ids.unsigned(v)
            end
          end
          TACTICS[id] = ids
        end
      end
    end)
    if not ok then
      warn("team tactics not readable (" .. tostring(err) .. "): the league team's dock shows none")
    end
  end
  return TACTICS[VRFW.ids.unsigned(team or 0)] or {}
end

function BattleBayDeluxe.LeagueSquad()
  local run = load()
  if not run or run.outcome or run.fmt ~= "league" then
    return { ok = false, why = "no running league" }
  end
  local team = VRFW.ids.unsigned(run.player_team or 0)
  if team == 0 then
    return { ok = false, why = "the league has no player team" }
  end
  local kind = "copy"
  local okd, Draft = pcall(require, "draft")
  local oka, Active = pcall(require, "active_team")
  if okd and type(Draft) == "table" and Draft.team() == team then
    kind = "draft"
  elseif oka and type(Active) == "table" and Active.is_tile(team) then
    kind = "own"
  end
  pcall(LS.ensure, run.lineup)
  local members, why = LS.members(team)
  if not members then
    return { ok = false, why = tostring(why) }
  end
  local okl, lv = pcall(function()
    return levels()[team]
  end)
  local okr, rec = pcall(LS.record, team)
  rec = okr and type(rec) == "table" and rec or {}
  local row = G.enjoy_row(team)
  local stadium = row and VRFW.ids.unsigned(U.get(VRFW.memory.struct("EnjoyRow", row), "stadium") or 0) or 0
  local emblem = (rec.emblem or 0) ~= 0 and rec.emblem or emblems()[team] or 0
  info(string.format("league squad of %s: coach %s, kit %s, emblem %s, %d tactic(s), stadium %s", VRFW.ids.hex_text(team),
    VRFW.ids.hex_text(rec.coach or 0), VRFW.ids.hex_text(rec.kit or 0), VRFW.ids.hex_text(emblem), #team_tactics(team), VRFW.ids.hex_text(stadium)))
  return { ok = true, kind = kind, team = team, formation = LS.formation(team), level = okl and lv or 1,
    emblem = emblem, kit = rec.kit or 0, coach = rec.coach or 0, tactics = team_tactics(team), synergies = {},
    stadium = stadium, members = members }
end

function BattleBayDeluxe.LeagueSquadSet(formation, placed)
  local run = load()
  if not run or run.outcome or run.fmt ~= "league" then
    return { ok = false, why = "no running league" }
  end
  local team = VRFW.ids.unsigned(run.player_team or 0)
  local list = {}
  for position, param in string.gmatch(tostring(placed or ""), "(%d+):(%d+)") do
    list[#list + 1] = { tonumber(position), tonumber(param) }
  end
  local slots = {}
  for _, m in ipairs(LS.members(team) or {}) do
    slots[#slots + 1] = m[1] .. ":" .. m[2]
  end
  info(string.format("league lineup from the dock for %s: formation %s, dock positions %s; the team's slots %s",
    VRFW.ids.hex_text(team), VRFW.ids.hex_text(formation or 0), tostring(placed), table.concat(slots, ",")))
  local order, why = LS.from_dock(team, list)
  if not order then
    warn("league lineup refused: " .. tostring(why))
    return { ok = false, why = tostring(why) }
  end
  local f = VRFW.ids.unsigned(formation or 0)
  if f == 0 then
    f = LS.formation(team)
  end
  local n, why2 = LS.apply(team, order, f)
  if n == nil then
    warn("league lineup not written: " .. tostring(why2))
    return { ok = false, why = tostring(why2) }
  end
  run.lineup = { team = team, formation = f, order = LS.encode(order) }
  save()
  info(string.format("league lineup of %s kept: %d rows changed, formation %s (%s)", VRFW.ids.hex_text(team), n, VRFW.ids.hex_text(f),
    run.lineup.order))
  return { ok = true, changed = n }
end

-- The team table's derived sets at script load (the boot thread), not in the first draw's frame.
do
  local t0 = VRFW.now_ms()
  local ok, rows = team_rows()
  if ok and #rows > 0 then
    pcall(levels)
    pcall(name_text, 0)
    pcall(exclusion_set)
    pcall(story_set)
    pcall(emblems)
    info(string.format("team sets (levels, names, exclusions, story teams, emblems) read at load in %d ms", VRFW.now_ms() - t0))
  end
end
