-- The Tournament's team pools: the offered sizes, the excluded teams and the club and national league sets.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local T = require "lib/tourney"
local Catalogue = Shared.Catalogue
local Tn = Shared.Tn
local info = Shared.info
local warn = Shared.warn
local CFG = Shared.CFG
local team_rows = Shared.team_rows

-- the team counts the options offer per format ({ knockout = {…}, groups = {…}, league = {…} }, smallest first).
local function offered_sizes()
  local cap = Shared.POOL and (Shared.POOL + 1) or nil
  local lg = Shared.POOL_LEAGUE or {}
  return { knockout = T.sizes("knockout", cap), groups = T.sizes("groups", cap),
    league = T.sizes("league", lg[1] and (lg[1] + 1) or cap),
    league_no_national = T.sizes("league", lg[2] and (lg[2] + 1) or cap) }
end

local EXCL = nil
local function exclusion_set()
  if EXCL then
    return EXCL
  end
  EXCL = {}
  local function keys(name)
    local v = U.config("tournament." .. name, {})
    return type(v) == "table" and v or {}
  end
  local by_kit, by_emblem, by_key = {}, {}, {}
  for _, k in ipairs(keys("exclude_teams")) do
    by_key[tostring(k)] = true
  end
  local ok, rows = team_rows()
  if not ok or type(rows) ~= "table" then
    warn("exclusions: the team table is not readable: none applied")
    return EXCL
  end
  local function kit_of(r)
    return VRFW.ids.unsigned(r.uniform or r.kit or r[6] or 0)
  end
  local function emblem_of(r)
    return VRFW.ids.unsigned(r.emblem or r[7] or 0)
  end
  local want_kit, want_emblem = {}, {}
  for _, k in ipairs(keys("exclude_same_kit_as")) do
    want_kit[tostring(k)] = true
  end
  for _, k in ipairs(keys("exclude_same_emblem_as")) do
    want_emblem[tostring(k)] = true
  end
  for _, r in ipairs(rows) do
    local key = tostring(r.key or r[2] or "")
    if want_kit[key] and kit_of(r) ~= 0 then
      by_kit[kit_of(r)] = key
    end
    if want_emblem[key] and emblem_of(r) ~= 0 then
      by_emblem[emblem_of(r)] = key
    end
  end
  local n = 0
  for _, r in ipairs(rows) do
    local key = tostring(r.key or r[2] or "")
    local why = (by_key[key] and "listed") or (by_kit[kit_of(r)] and ("kit of " .. by_kit[kit_of(r)]))
      or (by_emblem[emblem_of(r)] and ("emblem of " .. by_emblem[emblem_of(r)]))
    if why then
      EXCL[VRFW.ids.unsigned(r.id or r[1] or 0)] = why
      n = n + 1
      -- the first ones named, the rest counted
      if n <= 20 then
        VRFW.debug("tournament: " .. string.format("exclusions: %s (0x%08X, name text 0x%08X): %s", key, VRFW.ids.unsigned(r.id or r[1] or 0),
          VRFW.ids.unsigned(r.name_text or r[4] or 0), why))
      end
    end
  end
  info(string.format("exclusions: %d team(s) never drawn for the Torneo", n))
  return EXCL
end

-- the candidates without the excluded teams
local function excluded(cands)
  local X = exclusion_set()
  local out, dropped = {}, 0
  for _, t in ipairs(cands) do
    if X[VRFW.ids.unsigned(t)] then
      dropped = dropped + 1
    else
      out[#out + 1] = t
    end
  end
  if dropped > 0 then
    info(string.format("exclusions: %d of %d candidates left out", dropped, #cands))
  end
  return out
end
Tn.excluded = excluded

local CLUB, NATIONAL = nil, nil

local function league_sets()
  if CLUB then
    return CLUB, NATIONAL
  end
  CLUB, NATIONAL = {}, {}
  local ok, rows = team_rows()
  if not ok or type(rows) ~= "table" then
    warn("league: the team table is not readable: no club variants, no national sides")
    return CLUB, NATIONAL
  end
  -- a tile that plays a team set at runtime (Active team, Personal Teams) has a placeholder key and crest: its own club
  local oka, Active = pcall(require, "active_team")
  local plays_set = oka and type(Active) == "table" and type(Active.is_tile) == "function" and Active.is_tile
    or function() return false end
  local Clubs = VRFW.teams.clubs
  local nat_ids, nat_names, n_tagged = Catalogue.tagged("national"), {}, 0
  for _ in pairs(nat_ids) do
    n_tagged = n_tagged + 1
  end
  for _, r in ipairs(rows) do
    local id = VRFW.ids.unsigned(r.id or r[1] or 0)
    local nt = VRFW.ids.unsigned(r.name_text or r[4] or 0)
    if nat_ids[id] and nt ~= 0 then
      nat_names[nt] = true
    end
    CLUB[id] = plays_set(id) and id or Clubs.of_team(id)
  end
  local n_nat = 0
  for _, r in ipairs(rows) do
    local id = VRFW.ids.unsigned(r.id or r[1] or 0)
    if nat_ids[id] or nat_names[VRFW.ids.unsigned(r.name_text or r[4] or 0)] then
      NATIONAL[id] = true
      n_nat = n_nat + 1
    end
  end
  info(string.format("league: club families of %d teams, %d national side(s) from %d tagged team(s)", #rows, n_nat,
    n_tagged))
  return CLUB, NATIONAL
end

function Tn.league_pool(cands, player, no_national, rng)
  local club, nat = league_sets()
  local v = {}
  for _, t in ipairs(cands) do
    if not (no_national and nat[VRFW.ids.unsigned(t)]) then
      v[#v + 1] = t
    end
  end
  if rng then
    rng:shuffle(v)
  end
  local seen = { [club[VRFW.ids.unsigned(player)] or VRFW.ids.unsigned(player)] = true }
  local out = {}
  for _, t in ipairs(v) do
    local c = club[VRFW.ids.unsigned(t)] or VRFW.ids.unsigned(t)
    if not seen[c] then
      seen[c] = true
      out[#out + 1] = t
    end
  end
  return out
end

-- The names the later parts of the Tournament read.
Shared.offered_sizes = offered_sizes
Shared.exclusion_set = exclusion_set
Shared.excluded = excluded
Shared.league_sets = league_sets
