
local U = require "lib/util"
local T = require "lib/tourney"
local V = require "lib/tourney_view"
local G = require "lib/game"
local Catalogue = VRFW.catalogue
local MatchResults = VRFW.match.results
local LS = require "league_squad"
local Trophy = require "lib/trophy_celebration"
local Block = require "lib/campaign_block"

local Tn = {}

local floor = math.floor

local BLOB = "bb_tournament.json"
local RUN_VERSION = 1

local info, warn = VRFW.logger("tournament")

local function cfg_num(key, def, lo, hi)
  local v = tonumber(U.config("tournament." .. key, def)) or def
  if v < lo or v > hi then
    warn(string.format("config [tournament] %s = %s out of %s..%s: %s used", key, tostring(v), tostring(lo),
      tostring(hi), tostring(def)))
    return def
  end
  return v
end

local CFG = {
  fmt = tostring(U.config("tournament.format", T.DEFAULTS.fmt)),
  size = cfg_num("teams", T.DEFAULTS.size, T.MIN_SIZE, T.MAX_SIZE),
  seeded = U.config("tournament.seeded", T.DEFAULTS.seeded) ~= false,
  goals = cfg_num("goals", T.DEFAULTS.goals, 0.2, 5),
  weight = cfg_num("strength_weight", T.DEFAULTS.weight, 0, 1),
  pen_kick = cfg_num("penalty_score", T.DEFAULTS.pen_kick, 0.05, 0.99),
  pen_kicks = cfg_num("penalty_kicks", T.DEFAULTS.pen_kicks, 1, 11),
  seed = tonumber(U.config("tournament.seed", 0)) or 0,
  rules = tostring(U.config("tournament.knockout_rules", "bbd_knockout")),
  final_rules = tostring(U.config("tournament.final_rules", "bbd_final")),
  final_stadiums = {},
  -- "Filter minor teams" (the options' cursor start) and the story matches' game key patterns
  filter = U.config("tournament.filter_minor", false) == true,
  story_games = {},
}
do
  local g = U.config("tournament.filter_story_games", {})
  if type(g) == "string" then
    g = { g }
  end
  if type(g) == "table" then
    for _, x in ipairs(g) do
      CFG.story_games[#CFG.story_games + 1] = tostring(x)
    end
  end
end
do
  local list = U.config("tournament.final_stadiums", {})
  if type(list) == "string" then
    list = { list }
  end
  if type(list) == "table" then
    for _, x in ipairs(list) do
      if type(x) == "string" and x ~= "" then
        CFG.final_stadiums[#CFG.final_stadiums + 1] = x
      end
    end
  end
end
if CFG.fmt == "league" or not T.valid(CFG.fmt, CFG.size) then
  warn(string.format("config [tournament] format %q / teams %d not offered: knockout / 16", CFG.fmt, CFG.size))
  CFG.fmt, CFG.size = "knockout", 16
end
CFG.league_size = tonumber(U.config("league.teams", 12)) or 12
if not T.valid("league", CFG.league_size) then
  warn(string.format("config [league] teams = %s not offered (an even count, %d .. %d): 12 used",
    tostring(CFG.league_size), T.LEAGUE.MIN, T.LEAGUE.MAX))
  CFG.league_size = 12
end
CFG.league_double = U.config("league.double", false) == true
CFG.league_no_national = U.config("league.no_national", false) == true
CFG.scorer_weight = {
  [2] = tonumber(U.config("league.scorer_weight_forward", 1.0)) or 1.0,
  [3] = tonumber(U.config("league.scorer_weight_midfielder", 0.45)) or 0.45,
}
CFG.name_language = VRFW.strings.trim(tostring(U.config("league.name_language", "es")))
V.LEAGUE_ROWS = floor(tonumber(U.config("league.rows_per_page", V.LEAGUE_ROWS)) or V.LEAGUE_ROWS)
if V.LEAGUE_ROWS < 4 or V.LEAGUE_ROWS > V.LEAGUE_ROWS_MAX then
  warn(string.format("config [league] rows_per_page = %d out of 4..%d: 12 used", V.LEAGUE_ROWS, V.LEAGUE_ROWS_MAX))
  V.LEAGUE_ROWS = 12
end

-- the format's number in the commands (0 knockout, 1 groups, 2 league) and back (-1 / unknown = nil)
local function fmt_id(fmt)
  return T.FORMAT_IDS[fmt] or 0
end
local function fmt_name(n)
  return T.FORMAT_OF[U.int(n, -1)]
end
info(string.format("defaults %s / %d teams, seeded %s, seed %s, knockout rulebook %q", CFG.fmt, CFG.size,
  tostring(CFG.seeded), tostring(CFG.seed), CFG.rules))

local function mk(h, l)
  return U.rng(h, l)
end

local LEVELS = nil

local function team_rows()
  local rows, why = Catalogue.team_rows()
  if rows then
    return true, rows
  end
  return false, why
end

-- team -> level (team_config col 8 "level" as the game loads it, the mods' teams included)
local function levels()
  if LEVELS then
    return LEVELS
  end
  LEVELS = {}
  local ok, rows = team_rows()
  if ok and type(rows) == "table" then
    for _, r in ipairs(rows) do
      local id, lv = r.id or r[1], r.level or r[9]
      if type(id) == "number" and type(lv) == "number" then
        LEVELS[U.u32(id)] = lv
      end
    end
  else
    warn("team table not readable: team levels left out of the strength")
  end
  return LEVELS
end

local function strength(team, ratings, med)
  return (ratings[team] or med or 0) + (levels()[team] or 0)
end

local function median(ratings)
  local v = {}
  for _, r in pairs(ratings) do
    v[#v + 1] = r
  end
  if #v == 0 then
    return 0
  end
  table.sort(v)
  return v[floor(#v / 2) + 1]
end

-- "Filter minor teams".
local STORY = nil

local function glob_match(pat, s)
  local lp = "^" .. tostring(pat):gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0"):gsub("%*", ".*") .. "$"
  return tostring(s):match(lp) ~= nil
end

local function story_set()
  if STORY then
    return STORY
  end
  STORY = { teams = {}, names = {}, games = 0, n = 0 }
  local ok, err = pcall(function()
    local games = {}
    local function team(t, set)
      t = U.u32(t or 0)
      if t ~= 0 then
        STORY.teams[t] = true
      end
    end
    for _, r in ipairs(VRFW.table.rows("vsroute/vs_route_piece_event")) do
      local g = U.u32(r.paramCrc1 or r[1] or 0)
      if g ~= 0 then
        games[g] = true
      end
      team(r.paramCrc2 or r[2])
    end
    local globs = CFG.story_games
    if #globs > 0 then
      for _, r in ipairs(VRFW.table.rows("soccer/soccer_game_info")) do
        local name = r.name or r[2]
        for _, gl in ipairs(globs) do
          if type(name) == "string" and glob_match(gl, name) then
            games[U.u32(r.id or r[1])] = true
          end
        end
      end
    end
    local key = VRFW.table.source("soccer/soccer_game_info")
    local cur, slice, diffs = nil, {}, {}
    for _, e in ipairs(VRFW.table.entries(key, { "SOCCER_GAME_INFO", "SOCCER_GAME_INFO_REF_DIFFICULTY",
      "SOCCER_GAME_DIFFICULTY" }, true)) do
      if e.name == "SOCCER_GAME_INFO" then
        cur = U.u32(e[1] or 0)
      elseif e.name == "SOCCER_GAME_INFO_REF_DIFFICULTY" then
        if cur then
          slice[cur] = { e[1] or 0, e[2] or 0 }
        end
      elseif e.name == "SOCCER_GAME_DIFFICULTY" then
        diffs[#diffs + 1] = { e[2], e[6] }
      end
    end
    for g in pairs(games) do
      local sl = slice[g]
      if sl then
        STORY.games = STORY.games + 1
        for k = sl[1] + 1, sl[1] + sl[2] do
          local d = diffs[k]
          if d then
            team(d[1])
            team(d[2])
          end
        end
      end
    end
    -- the name texts of those teams
    local okT, trows = team_rows()
    if not okT then
      error(trows, 0)
    end
    for _, r in ipairs(trows) do
      local id = U.u32(r.id or r[1] or 0)
      if STORY.teams[id] then
        local nt = U.u32(r.name_text or r[4] or 0)
        if nt ~= 0 then
          STORY.names[nt] = true
        end
      end
    end
    for _ in pairs(STORY.teams) do
      STORY.n = STORY.n + 1
    end
  end)
  if not ok then
    warn("minor teams filter: the story / Chronicle teams not readable (" .. tostring(err) .. "): no team counts as one")
  else
    info(string.format("minor teams filter: %d story / Chronicle teams from %d games", STORY.n, STORY.games))
  end
  return STORY
end

local NAME_TEXT = nil
local function name_text(t)
  if not NAME_TEXT then
    NAME_TEXT = {}
    local ok, rows = team_rows()
    if ok and type(rows) == "table" then
      for _, r in ipairs(rows) do
        NAME_TEXT[U.u32(r.id or r[1] or 0)] = U.u32(r.name_text or r[4] or 0)
      end
    end
  end
  return NAME_TEXT[t] or 0
end
Tn.name_text = name_text

local function is_story(t)
  local S = story_set()
  if S.teams[t] then
    return true
  end
  local nt = name_text(t)
  return nt ~= 0 and S.names[nt] == true
end
Tn.is_story = is_story

local function filtered_opponents(v, n, ratings, med)
  local story, rest = {}, {}
  for _, t in ipairs(v) do
    if is_story(t) then
      story[#story + 1] = t
    else
      rest[#rest + 1] = { t = t, s = strength(t, ratings, med), k = #rest }
    end
  end
  local out = {}
  for i = 1, math.min(n, #story) do
    out[#out + 1] = story[i]
  end
  if #out < n then
    table.sort(rest, function(a, b)
      if a.s ~= b.s then
        return a.s > b.s
      end
      return a.k < b.k
    end)
    for i = 1, n - #out do
      if rest[i] then
        out[#out + 1] = rest[i].t
      end
    end
  end
  info(string.format("minor teams filter: %d of %d story / Chronicle candidates, %d strongest of the rest", math.min(n,
    #story), #story, math.max(0, n - #story)))
  return out
end

local RUN, RUN_SLOT = nil, nil
local ARMED = nil
local PENDING = nil
local PENDING_DIFF = nil
local FAILED = nil
local POOL = nil
local POOL_LEAGUE = nil
local PLAYED = nil
local LIVE = nil
local final_request

local RUN_STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "tournament",
  default = function() return nil end,
  decode = function(doc)
    if doc.v ~= RUN_VERSION then return nil, "version: no tournament" end
    return doc
  end,
})

local function blob_off(why)
  local n = VRFW.slots.active()
  if type(VRFW.save.doc.read_text(BLOB, n)) == "string" then
    local ok2, where = VRFW.save.doc.set_aside(BLOB, n)
    info(BLOB .. " (slot " .. n .. ") put aside (" .. why .. "): " .. tostring(ok2 and where or "failed"))
  end
end

local function save()
  if not RUN then
    return
  end
  if RUN.outcome then
    blob_off(RUN.outcome)
    return
  end
  local n = VRFW.slots.active()
  local done, why = RUN_STORE:write(RUN, n, true)
  if not done then
    warn(BLOB .. " (slot " .. n .. ") not written: " .. tostring(why))
  end
end

local function load()
  local n = VRFW.slots.active()
  if RUN_SLOT == n then
    return RUN
  end
  RUN, RUN_SLOT = nil, n
  local doc, state = RUN_STORE:load(n)
  if state == "ok" and doc.outcome then
    local aside, why = VRFW.save.doc.set_aside(BLOB, n)
    if not aside then
      warn(BLOB .. " (slot " .. n .. ") stays on record after its run ended: " .. tostring(why))
    end
    Tn.stale = string.format("an ended %s (%s)", tostring(doc.fmt), tostring(doc.outcome))
  elseif state == "ok" then
    RUN = doc
    info(string.format("run of slot %d: %s / %d teams%s, %d match(es) played, stage %s", n, doc.fmt, doc.size,
      doc.double and " (home and away)" or "", doc.k, tostring(doc.stage)))
  end
  return RUN
end

local function drop(why)
  blob_off(why)
  RUN = nil
end

-- the block holds this run (player team and first rival)
local function block_is_run(b, run)
  return b and run.sess and b.player == run.sess.player and b.rivals[1] == run.sess.r1 and b.rivals[1] ~= 0
end

local function write_block(run)
  if not Block.session() or not run.sess then
    return false
  end
  local opp = T.opponent(run)
  if opp == 0 then
    return false
  end
  run.sess.r1 = run.teams[opp]
  local ok = Block.write(run.sess.game, run.sess.diff, run.sess.player, { run.teams[opp] }, 0)
  if ok then
    info(string.format("match %d/%d: rival %s (the Campaña's block borrowed)", run.k + 1, T.run_matches(run),
      U.hex(run.teams[opp])))
  else
    warn("campaign block not written")
  end
  return ok
end

local CAMP_BLOB = "bb_tournament_campaign.json"

-- Puts the kept copy of the campaign block aside.
local function campaign_copy_off()
  local aside, why = VRFW.save.doc.set_aside(CAMP_BLOB, VRFW.slots.active())
  if not aside then
    warn(CAMP_BLOB .. " stays on record: " .. tostring(why))
  end
end

-- the block zeroed as the game's own reset does, its kept copy put aside
local function campaign_clear()
  local ok = Block.clear()
  if ok then
    campaign_copy_off()
  end
  return ok
end

local ONE_RUN_STORE = VRFW.save.doc.new("bb_one_run.json", {
  aside = false,
  log = "tournament",
  default = function() return nil end,
})
local ONE_RUN = { slot = nil, mark = nil, first = false }

local function one_run_mark(n)
  if ONE_RUN.slot ~= n then
    local doc, state = ONE_RUN_STORE:load(n)
    ONE_RUN.slot, ONE_RUN.mark, ONE_RUN.first = n, doc, state == "new"
  end
  return ONE_RUN
end

local function one_run_write(n, doc)
  ONE_RUN.mark, ONE_RUN.first = doc, false
  local done, why = ONE_RUN_STORE:write(doc, n, true)
  if not done then
    warn("bb_one_run.json not written: " .. tostring(why))
  end
end

-- After every top menu sync.
local function one_run_check()
  local n = VRFW.slots.active()
  local run = load()
  local notes = {}
  if Tn.stale then
    notes[1] = Tn.stale
    Tn.stale = nil
  end
  local b = Block.read()
  local lent = (run and run.loaded) or ARMED ~= nil or PENDING ~= nil
  for _, name in ipairs(Block.LENT_BLOBS) do
    lent = lent or (name ~= CAMP_BLOB and Block.has_snapshot(name))
  end
  if b and not lent then
    local m = one_run_mark(n)
    local running = run ~= nil and not run.outcome
    local again = type(m.mark) == "table" and m.mark.player == b.player and m.mark.r1 == b.rivals[1]
    if Block.alive(b) and (running or (b.index == 0 and (m.first or again))) then
      if campaign_clear() then
        notes[#notes + 1] = string.format("a Campaña (player %s, rival 1 %s, match %d, %s)", U.hex(b.player),
          U.hex(b.rivals[1]), b.index + 1, running and "behind a running run" or "no match won")
        one_run_write(n, { v = 1, player = b.player, r1 = b.rivals[1], index = b.index })
      end
    elseif m.first then
      one_run_write(n, { v = 1 })
    end
  end
  if #notes > 0 then
    info(string.format("one saved run (slot %d): removed %s", n, table.concat(notes, " and ")))
  end
end

function Tn.armed()
  return ARMED ~= nil
end

function Tn.note_pool(n, list, player)
  if type(n) == "number" and n >= 0 then
    POOL = n
  end
  if type(list) == "table" then
    local ok, a, b = pcall(function()
      local x = Tn.excluded(list)
      return #Tn.league_pool(x, player or 0, false), #Tn.league_pool(x, player or 0, true)
    end)
    if ok then
      POOL_LEAGUE = { a, b }
    end
  end
end

-- the team counts the options offer per format ({ knockout = {…}, groups = {…}, league = {…} }, smallest first).
local function offered_sizes()
  local cap = POOL and (POOL + 1) or nil
  local lg = POOL_LEAGUE or {}
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
    return U.u32(r.uniform or r.kit or r[6] or 0)
  end
  local function emblem_of(r)
    return U.u32(r.emblem or r[7] or 0)
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
      EXCL[U.u32(r.id or r[1] or 0)] = why
      n = n + 1
      -- the first ones named, the rest counted
      if n <= 20 then
        VRFW.debug("tournament: " .. string.format("exclusions: %s (0x%08X, name text 0x%08X): %s", key, U.u32(r.id or r[1] or 0),
          U.u32(r.name_text or r[4] or 0), why))
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
    if X[U.u32(t)] then
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

local function team_name_strings()
  local out = {}
  local ok, rows = pcall(VRFW.table.raw, VRFW.table_files.file_name("data/common/text/" .. CFG.name_language .. "/team_text"),
    "NOUN_INFO", { 1, 2, 6 })
  if ok and type(rows) == "table" then
    for _, r in ipairs(rows) do
      if type(r[1]) == "number" and r[2] == 0 and type(r[6]) == "string" then
        out[U.u32(r[1])] = VRFW.strings.trim(r[6])
      end
    end
  else
    warn("league: team names not readable (" .. tostring(rows) .. "): club variants by key only")
  end
  return out
end

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
  local names = team_name_strings()
  local fam, root = {}, {}
  local function find(t)
    while root[t] and root[t] ~= t do
      t = root[t]
    end
    return t
  end
  local nat_ids, nat_names, n_tagged = Catalogue.tagged("national"), {}, 0
  for _ in pairs(nat_ids) do
    n_tagged = n_tagged + 1
  end
  for _, r in ipairs(rows) do
    local id = U.u32(r.id or r[1] or 0)
    local key = tostring(r.key or r[2] or "")
    local nt = U.u32(r.name_text or r[4] or 0)
    root[id] = id
    if nat_ids[id] and nt ~= 0 then
      nat_names[nt] = true
    end
    local fams = {}
    local kb = key:match("^(.-%d)[a-z]$")
    if kb then
      fams[#fams + 1] = "k:" .. kb
    end
    local name = names[nt]
    if name then
      local nb = name:match("^(.-)%s+[A-Z]$")
      fams[#fams + 1] = "n:" .. (nb or name)
    end
    for _, f in ipairs(fams) do
      if fam[f] then
        local a, b = find(fam[f]), find(id)
        if a ~= b then
          root[b] = a
        end
      else
        fam[f] = id
      end
    end
  end
  local n_nat = 0
  for _, r in ipairs(rows) do
    local id = U.u32(r.id or r[1] or 0)
    CLUB[id] = find(id)
    if nat_ids[id] or nat_names[U.u32(r.name_text or r[4] or 0)] then
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
    if not (no_national and nat[U.u32(t)]) then
      v[#v + 1] = t
    end
  end
  if rng then
    rng:shuffle(v)
  end
  local seen = { [club[U.u32(player)] or U.u32(player)] = true }
  local out = {}
  for _, t in ipairs(v) do
    local c = club[U.u32(t)] or U.u32(t)
    if not seen[c] then
      seen[c] = true
      out[#out + 1] = t
    end
  end
  return out
end

local PICKS_BLOB = "bb_picks.json"
local PICK = nil   -- { mode, player, teams, max }

local PICKS_STORE = VRFW.save.doc.new(PICKS_BLOB, {
  aside = false,
  log = "tournament picks",
  default = function() return { v = 1 } end,
})

local function picks_doc()
  return (PICKS_STORE:load(VRFW.slots.active()))
end

local function pick_mode(fmt)
  return T.FORMAT_OF[U.int(fmt, 0)] == "league" and "league" or "tournament"
end

-- the saved picks of a format's mode, without the player's team nor another version of his club or of each other
function Tn.picks_of(fmt, player)
  local mode = type(fmt) == "string" and (fmt == "league" and "league" or "tournament") or pick_mode(fmt)
  local list = picks_doc()[mode]
  local club = league_sets()
  local seen = { [club[U.u32(player)] or U.u32(player)] = true }
  local out = {}
  for _, t in ipairs(type(list) == "table" and list or {}) do
    t = U.u32(t)
    local c = club[t] or t
    if t ~= 0 and t ~= U.u32(player) and not seen[c] then
      seen[c] = true
      out[#out + 1] = t
    end
  end
  return out
end

function BattleBayDeluxe.TournamentPick(op, fmt, team, player)
  op, team, player = U.int(op, -1), U.u32(team or 0), U.u32(player or 0)
  local mode = pick_mode(fmt)
  local max = mode == "league" and T.LEAGUE.MAX or T.MAX_SIZE
  local begin = op == 0 or op == 5
  if begin or PICK == nil or PICK.mode ~= mode then
    local same_visit = op == 0 and PICK ~= nil and PICK.mode == mode and PICK.player == player
    local teams = same_visit and PICK.teams or {}
    local want = begin and U.int(team, 0) or 0
    if want >= 2 and want <= max then
      max = want
      for i = #teams, max, -1 do
        teams[i] = nil
      end
    end
    PICK = { mode = mode, player = player, teams = teams, max = max }
  end
  local P = PICK
  max = P.max or max
  if op == 4 or begin then
    return { teams = P.teams, n = #P.teams + 1, max = max }
  end
  if op == 1 then
    if team == P.player then
      return { ok = false, why = "player", n = #P.teams + 1 }
    end
    for i, t in ipairs(P.teams) do
      if t == team then
        table.remove(P.teams, i)
        return { ok = true, on = false, n = #P.teams + 1, teams = P.teams }
      end
    end
    local club = league_sets()
    local c = club[team] or team
    if c == (club[P.player] or P.player) then
      return { ok = false, why = "club", n = #P.teams + 1 }
    end
    for _, t in ipairs(P.teams) do
      if (club[t] or t) == c then
        return { ok = false, why = "club", n = #P.teams + 1 }
      end
    end
    if #P.teams + 1 >= max then
      return { ok = false, why = "max", n = #P.teams + 1 }
    end
    P.teams[#P.teams + 1] = team
    return { ok = true, on = true, n = #P.teams + 1, teams = P.teams }
  end
  if op == 2 then
    local doc = picks_doc()
    doc.v = 1
    doc[mode] = P.teams
    local done, why = PICKS_STORE:write(doc, VRFW.slots.active(), true)
    if not done then
      warn(PICKS_BLOB .. " not written: " .. tostring(why))
    end
    info(string.format("teams picked by hand (%s): %d + the player's", mode, #P.teams))
    return { n = #P.teams + 1 }
  end
  return { n = #P.teams + 1 }
end

function Tn.configured()
  return ARMED ~= nil and ARMED.configured == true
end

-- the player's team of an armed "Custom" tournament (the team the picker opened for), nil = none
function Tn.picked_player()
  if ARMED == nil or not ARMED.custom or PICK == nil or PICK.player == 0 then
    return nil
  end
  return PICK.mode == (ARMED.fmt == "league" and "league" or "tournament") and PICK.player or nil
end

function Tn.begin(cands, player, ratings, h, l)
  local a = ARMED
  if not a then
    return nil, "not armed"
  end
  if CFG.seed ~= 0 then
    h, l = U.split64(CFG.seed)
    l = bit32.bxor(l, player)
  end
  if a.custom then
    local picks = Tn.picks_of(a.fmt, player)
    for i = #picks, a.size, -1 do
      picks[i] = nil
    end
    local size = #picks + 1
    if size ~= a.size or not T.valid(a.fmt, size) then
      return nil, string.format("%d teams picked by hand: not the %d of the %s", size, a.size, a.fmt)
    end
    local rng = U.rng(h, l)
    if not a.ordered then
      rng:shuffle(picks)
    end
    local med = median(ratings)
    local opps = {}
    for i, t in ipairs(picks) do
      opps[i] = { team = t, str = strength(t, ratings, med) }
    end
    local run, why = T.new({ fmt = a.fmt, size = size, seed = { h, l }, player = player,
      player_str = strength(player, ratings, med), opponents = opps, seeded = CFG.seeded, double = a.double, mk = mk,
      ordered = a.ordered })
    if not run then
      return nil, why
    end
    run.v = RUN_VERSION
    run.player_team = player
    info(string.format("teams picked by hand: %d + the player's, %s", #picks, a.ordered and "in the pick order"
      or "shuffled"))
    return run
  end
  cands = excluded(cands)
  if a.fmt == "league" then
    cands = Tn.league_pool(cands, player, a.no_national, U.rng((h + 0x4C454147) % 4294967296, l))
  end
  POOL = #cands
  local size = a.size
  if #cands < size - 1 then
    local fit = T.sizes(a.fmt, #cands + 1)
    size = fit[#fit]
    if not size then
      return nil, string.format("%d candidate teams: not enough for any %s tournament", #cands, a.fmt)
    end
    warn(string.format("only %d candidate teams: %d teams instead of %d", #cands, size, a.size))
  end
  local rng = U.rng(h, l)
  local v = {}
  for i, t in ipairs(cands) do
    v[i] = t
  end
  rng:shuffle(v)
  local med = median(ratings)
  -- the minor teams filter picks WHO plays, never how many (the count stays the power of two above)
  if a.filter then
    v = filtered_opponents(v, size - 1, ratings, med)
    rng:shuffle(v)
  end
  local opps = {}
  for i = 1, size - 1 do
    opps[i] = { team = v[i], str = strength(v[i], ratings, med) }
  end
  local run, why = T.new({ fmt = a.fmt, size = size, seed = { h, l }, player = player,
    player_str = strength(player, ratings, med), opponents = opps, seeded = CFG.seeded, double = a.double, mk = mk })
  if not run then
    return nil, why
  end
  run.v = RUN_VERSION
  run.player_team = player
  return run
end

local function start_now()
  local run, diff = PENDING, PENDING_DIFF
  if not run or not diff then
    return false
  end
  PENDING, PENDING_DIFF = nil, nil
  local r1 = run.teams[T.opponent(run)]
  run.sess = { game = 0, diff = diff, player = run.player_team, r1 = r1 }
  run.loaded = false
  ARMED = nil
  RUN, RUN_SLOT = run, VRFW.slots.active()
  save()
  campaign_copy_off()
  local kept = Block.read()
  if Block.alive(kept) then
    if campaign_clear() then
      info(string.format("the saved Campaña (player %s, rival 1 %s, match %d) ended by this start", U.hex(kept.player),
        U.hex(kept.rivals[1]), kept.index + 1))
    else
      warn("the saved Campaña was not cleared at this start (the next sync clears it)")
    end
  end
  if Tn.on_started then
    pcall(Tn.on_started, run)
  end
  info(string.format("started: %s / %d teams%s, player %s, difficulty %d, first rival %s, seed %s:%s", run.fmt,
    run.size, run.double and " (home and away)" or "", U.hex(run.player_team), diff, U.hex(r1), U.hex(run.seed[1]),
    U.hex(run.seed[2])))
  return true
end

function Tn.pend(run)
  PENDING = run
  FAILED = nil
  info("drawn at the grid's start (the game's own start refused); waiting for the difficulty")
  return start_now()
end

function BattleBayDeluxe.TournamentStart(diff)
  diff = U.int(diff, 0)
  if diff < 1 or diff > 16 then
    return { ok = false, why = "difficulty" }
  end
  PENDING_DIFF = diff
  local ok = start_now()
  return { ok = ok or (RUN ~= nil and RUN.k == 0 and not RUN.outcome), waiting = PENDING_DIFF ~= nil }
end

function Tn.fail(why)
  FAILED = tostring(why or "?")
  warn("start failed: " .. FAILED)
end

function Tn.player_team()
  local run = load()
  if not run or run.outcome then
    return 0
  end
  return run.player_team or 0
end

Tn.before_match = nil

local function copy_table(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = copy_table(v)
  end
  return out
end

local function trial_record(run, gf, ga, outcome)
  local trial = copy_table(run)
  local cfg = { goals = CFG.goals, weight = CFG.weight, pen_kick = CFG.pen_kick, pen_kicks = CFG.pen_kicks }
  if not T.record(trial, cfg, mk, gf, ga, 0, 0, false, outcome) then
    return nil
  end
  return trial
end

VRFW.on("slot_load", function()
  local ok, e = pcall(load)
  if not ok then
    warn("slot_load: run not read: " .. tostring(e))
  end
  return nil
end)

VRFW.on("match_start", function(ev)
  LIVE, PLAYED = nil, nil
  local run = load()
  if not run or run.outcome then
    return nil
  end
  local b = Block.read()
  if b and block_is_run(b, run) and b.index then
    LIVE = { index = b.index, rival = b.rivals[b.index + 1], sc = {} }
  end
  return nil
end)

local function event_score(ev)
  local m = type(ev) == "table" and ev.match or nil
  if type(m) ~= "table" or type(m.score) ~= "table" then
    return nil
  end
  local side = tonumber(m.user_team)
  local team0, team1 = tonumber(m.score[1]), tonumber(m.score[2])
  if (side ~= 0 and side ~= 1) or not team0 or not team1 then
    return nil
  end
  if side == 1 then
    return U.int(team1, 0), U.int(team0, 0)
  end
  return U.int(team0, 0), U.int(team1, 0)
end

-- keeps the live match's score from a match event (each goal, the full time).
local function note_live_score(ev)
  if not LIVE then
    return
  end
  local goals_for, goals_against = event_score(ev)
  if not goals_for then
    return
  end
  local seen = LIVE.score
  if not seen or goals_for + goals_against >= seen.f + seen.a then
    LIVE.score = { f = goals_for, a = goals_against }
  end
end

local function played_score()
  if PLAYED and PLAYED.native then
    return PLAYED.gf, PLAYED.ga
  end
  if PLAYED and PLAYED.score then
    return PLAYED.score.f, PLAYED.score.a
  end
  return nil
end

VRFW.on("goal", function(ev)
  if LIVE then
    local actor = ev.actor
    if type(actor) == "table" and (actor.side == "user" or actor.side == "rival") and (tonumber(actor.card) or 0) ~= 0 then
      LIVE.sc[#LIVE.sc + 1] = { side = actor.side, card = U.u32(actor.card) }
    end
    note_live_score(ev)
  end
  return nil
end)

VRFW.on("signal:vrfw.match_result", function()
  local last = MatchResults.last()
  local okr, run = pcall(load)
  if type(last) ~= "table" or not okr or not run or run.outcome or not run.loaded then
    return nil
  end
  local native_for, native_against = U.int(last.score_for, 0), U.int(last.score_against, 0)
  local score = LIVE and LIVE.score
  PLAYED = { index = LIVE and LIVE.index, rival = LIVE and LIVE.rival, gf = native_for, ga = native_against,
    outcome = last.outcome, native = true, sc = LIVE and LIVE.sc or {},
    score = score and { f = score.f, a = score.a } or nil }
  info(string.format("match result (framework): %s %d-%d; match events %s", tostring(last.outcome), native_for,
    native_against, score and string.format("%d-%d", score.f, score.a) or "none"))
  if LIVE and last.outcome == "win" then
    local goals_for, goals_against = played_score()
    local trial = trial_record(run, goals_for, goals_against, last.outcome)
    if trial and trial.outcome == "champion" then
      Trophy.play(run.fmt == "league" and "league" or "tournament", last)
    end
    PLAYED.ends_run = trial ~= nil and trial.outcome ~= false and trial.outcome ~= nil
    if PLAYED.ends_run then
      info(string.format("the won match ends the run (%s): no match left", tostring(trial.outcome)))
    end
  end
  return nil
end)

VRFW.on("match_end", function(ev)
  if not LIVE then
    return nil
  end
  note_live_score(ev)
  local score = LIVE.score
  if PLAYED and PLAYED.native then
    PLAYED.index, PLAYED.rival, PLAYED.sc = LIVE.index, LIVE.rival, LIVE.sc
    PLAYED.score = score and { f = score.f, a = score.a } or PLAYED.score
  else
    PLAYED = { index = LIVE.index, rival = LIVE.rival, sc = LIVE.sc,
      score = score and { f = score.f, a = score.a } or nil }
  end
  final_request(nil)
  info(string.format("match over: match events %s, game's own result %s", score and string.format("%d-%d", score.f,
    score.a) or "none", (PLAYED.native and string.format("%d-%d", PLAYED.gf, PLAYED.ga)) or "none"))
  LIVE = nil
  return nil
end)

Tn.roster = nil
local STATS = nil
local SQUADS = {}

local function card_stats()
  if STATS then
    return STATS
  end
  STATS = {}
  local ok, cards = pcall(VRFW.character.cards, { columns = { "stat_kick" } })
  if ok and type(cards) == "table" then
    for _, c in ipairs(cards) do
      STATS[U.u32(c.id)] = { pos = U.int(c.position, 0), kick = tonumber(c.cols and c.cols.stat_kick) or 0 }
    end
  else
    warn("top scorers: chara_param not readable (" .. tostring(cards) .. ")")
  end
  return STATS
end

local function scorer_pool(team)
  if SQUADS[team] then
    return SQUADS[team]
  end
  local list = {}
  local rows = nil
  if Tn.roster then
    local ok, r = pcall(Tn.roster, team)
    rows = ok and r or nil
  end
  local st = card_stats()
  for _, m in ipairs(type(rows) == "table" and rows or {}) do
    local slot, card = U.int(m[1], 99), U.u32(m[2] or 0)
    local x = st[card]
    local w = x and (CFG.scorer_weight[x.pos] or 0) * math.max(1, x.kick) or 0
    if slot < 11 and card ~= 0 and w > 0 then
      list[#list + 1] = { card = card, w = w }
    end
  end
  SQUADS[team] = list
  return list
end

local function add_goal(run, e, card)
  run.scorers = run.scorers or {}
  for _, x in ipairs(run.scorers) do
    if x.e == e and x.c == card then
      x.g = x.g + 1
      return
    end
  end
  run.scorers[#run.scorers + 1] = { e = e, c = card, g = 1 }
end

local function drawn_goals(run, e, n, r)
  local pool = scorer_pool(run.teams[e] or 0)
  local total = 0
  for _, x in ipairs(pool) do
    total = total + x.w
  end
  if total <= 0 then
    return
  end
  for _ = 1, n do
    local pick = r:below(1000000) / 1000000 * total
    for _, x in ipairs(pool) do
      pick = pick - x.w
      if pick < 0 then
        add_goal(run, e, x.card)
        break
      end
    end
  end
end

function Tn.league_scorers(run, md, live)
  local p = run.player
  for i, m in ipairs(run.gm[1]) do
    if m.md == md and m.done then
      local mine = m.a == p or m.b == p
      for side = 1, 2 do
        local e = side == 1 and m.a or m.b
        local goals = side == 1 and m.ga or m.gb
        local given = 0
        if mine then
          local want = e == p and "user" or "rival"
          for _, x in ipairs(live or {}) do
            if x.side == want and given < goals then
              add_goal(run, e, x.card)
              given = given + 1
            end
          end
        end
        if goals > given then
          local r = U.rng((run.seed[1] + 0x53434F52 + md * 977) % 4294967296, (run.seed[2] + i * 7919 + side) % 4294967296)
          r:next()
          drawn_goals(run, e, goals - given, r)
        end
      end
    end
  end
end

-- the player's next match is the tournament's final
local function final_next(run)
  local m, stage, round = T.pending(run)
  return m ~= nil and stage == "ko" and T.round_from_end(run, round) == 1
end

local function rules_of(run)
  local m, stage = T.pending(run)
  if m and stage == "ko" then
    if final_next(run) and CFG.final_rules ~= "" then
      return CFG.final_rules
    end
    return CFG.rules
  end
  return ""
end

local FINAL_STADIUM_TAG = 0x46494E41
local function final_stadium(run)
  if type(run.final_stadium) == "string" then
    return run.final_stadium
  end
  local n = #CFG.final_stadiums
  local pick = ""
  if n > 0 then
    local r = U.rng((run.seed[1] + FINAL_STADIUM_TAG) % 4294967296, run.seed[2])
    r:next()
    pick = CFG.final_stadiums[r:below(n) + 1]
  end
  run.final_stadium = pick
  save()
  info(string.format("final stadium: %s (drawn among %d)", pick ~= "" and pick or "none", n))
  return pick
end

-- a league match is played at the home side's stadium.
local function home_venue(run)
  local m, stage = T.pending(run)
  if not m or stage ~= "league" or m.a ~= run.player then
    return nil
  end
  local team = run.teams[run.player] or 0
  local row = G.enjoy_row(team)
  local map = row and U.get(U.struct("EnjoyRow", row), "stadium") or 0
  if map ~= 0 then
    return U.u32(map), "the league team's own stadium"
  end
  warn(string.format("league home match: team %s has no stadium of its own (enjoy row %s): the request's own stadium",
    U.hex(team), row and "without one" or "missing"))
  return nil
end

local FINAL_TABLE = "BattleBayDeluxe.FinalStadium"
final_request = function(run)
  local map = run and not run.outcome and final_next(run) and final_stadium(run) or ""
  local id = map ~= "" and VRFW.crc32(map) or nil
  local why = "final stadium " .. map
  if not id and run and not run.outcome then
    local hv, src = home_venue(run)
    if hv then
      id, why = hv, "league home match, " .. src
    end
  end
  local ok, e = pcall(VRFW.native.table_set, FINAL_TABLE, 0, id)
  if not ok then
    warn("venue request not set: " .. tostring(e))
  elseif id then
    info(string.format("venue request: 0x%08X (%s) for the next Battle Bay match", id, why))
  end
end

function BattleBayDeluxe.TournamentInfo()
  local run = load()
  local b = Block.read()
  local t = {
    active = run ~= nil and not run.outcome, ended = run ~= nil and run.outcome ~= false, armed = ARMED ~= nil,
    configured = ARMED ~= nil and ARMED.configured == true, pending = PENDING ~= nil, failed = FAILED,
    campaign = false,
    defaults = { fmt = fmt_id(CFG.fmt), size = CFG.size, filter = CFG.filter and 1 or 0,
      league_size = CFG.league_size, double = CFG.league_double and 1 or 0,
      no_national = CFG.league_no_national and 1 or 0 },
    sizes = offered_sizes(),
  }
  FAILED = nil
  if run then
    t.fmt, t.size, t.k, t.stage = fmt_id(run.fmt), run.size, run.k, run.stage
    t.double = run.double and 1 or 0
    t.matches = T.run_matches(run)
    t.outcome = run.outcome or ""
    t.rules = rules_of(run)
    t.final = final_next(run)
    local map = final_stadium(run)
    if map ~= "" then
      t.final_stadium = { map = map, id = VRFW.crc32(map) }
    end
    local opp = T.opponent(run)
    t.rival = opp ~= 0 and run.teams[opp] or 0
    local m, stage, round = T.pending(run)
    if m then
      t.next_stage = stage
      t.next_round = T.round_robin(stage) and round or T.round_from_end(run, round)
    end
  end
  if ARMED and ARMED.configured and b then
    local snap = Block.kept(CAMP_BLOB)
    if snap and (U.u32(snap.player) ~= b.player or U.u32(snap.rivals[1]) ~= b.rivals[1]) then
      t.campaign = true
    end
  end
  if ARMED then
    t.rules = ARMED.fmt == "knockout" and CFG.rules or ""
    t.fmt, t.size = fmt_id(ARMED.fmt), ARMED.size
    t.filter = ARMED.custom and 2 or (ARMED.filter and 1 or 0)
    t.double = ARMED.double and 1 or 0
    t.no_national = ARMED.no_national and 1 or 0
  end
  if run and not run.outcome then
    t.loaded = run.loaded == true
    t.ends_run = PLAYED ~= nil and PLAYED.ends_run == true
    local first, len = Tn.path_window(run)
    t.path = Tn.path_len(run)
    t.ci1 = run.k - first + (PLAYED and 1 or 0)
    t.ci3 = {}
    for k = 1, math.max(len, T.MAX_PLAYER_MATCHES) do
      t.ci3[k] = Tn.rival_of(run, first + k)
    end
  end
  return t
end

function BattleBayDeluxe.TournamentArm(fmt, size, configured, filter, double, no_national, ordered)
  fmt = fmt_name(fmt) or CFG.fmt
  size = U.int(size, 0)
  if size == 0 then
    size = fmt == "league" and CFG.league_size or CFG.size
  end
  if not T.valid(fmt, size) then
    return false, "format not offered"
  end
  if load() and not RUN.outcome then
    return false, "a tournament is running"
  end
  if not VRFW.is_on("Decide") then
    warn("not armed: the Decide hook is off on this build (content/game/campaign.toml)")
    return false, "the Decide hook is off"
  end
  local fl = U.int(filter, -1)
  local dbl = U.int(double, -1)
  ARMED = { fmt = fmt, size = size, configured = U.int(configured, 0) == 1, filter = fl == 1 or (fl == -1 and CFG.filter),
    double = fmt == "league" and (dbl == 1 or (dbl == -1 and CFG.league_double)) }
  ARMED.custom = fl == 2
  ARMED.ordered = ARMED.custom and U.int(ordered, 0) == 1
  local nn = U.int(no_national, -1)
  ARMED.no_national = fmt == "league" and (nn == 1 or (nn == -1 and CFG.league_no_national))
  PENDING, PENDING_DIFF = nil, nil
  if ARMED.configured and not (RUN and RUN.loaded) then
    if Block.snapshot(CAMP_BLOB) then
      ARMED.snap = true
    end
  end
  info(string.format("armed: %s / %d teams%s%s%s", fmt, size, ARMED.custom and (ARMED.ordered and ", teams picked by hand (pick order)" or ", teams picked by hand (shuffled)")
    or (ARMED.filter and ", minor teams filtered" or ""),
    ARMED.double and ", home and away" or "", ARMED.configured and " (options confirmed)" or ""))
  return true
end

function BattleBayDeluxe.TournamentDisarm()
  if ARMED or PENDING then
    info("disarmed")
  end
  if ARMED and ARMED.snap then
    campaign_copy_off()
  end
  ARMED, PENDING, PENDING_DIFF = nil, nil, nil
  return true
end

local function player_match_result(st, fix)
  local goals_for, goals_against = played_score()
  local source = PLAYED and PLAYED.native and "framework's match result" or "match events"
  if not goals_for then
    if not st.ok then
      return false
    end
    goals_for, goals_against, source = st.gf, st.ga, "rule engine state"
  end
  local r = { gf = goals_for, ga = goals_against, pf = 0, pa = 0, et = false, outcome = PLAYED and PLAYED.outcome or nil }
  if st.ok then
    r.pf, r.pa, r.et = st.pf, st.pa, st.et
    if not r.outcome and r.pf + r.pa > 0 then
      r.outcome = (st.winner == 1 and "win") or (st.winner == 2 and "loss") or nil
    end
  end
  r = fix(r)
  info(string.format("player's match: %d-%d%s from the %s%s", r.gf, r.ga,
    (r.pf + r.pa > 0) and string.format(" (pen. %d-%d)", r.pf, r.pa) or "", source,
    r.et and ", extra time played" or ""))
  return r
end

local function result_of(run, b, st)
  local function fix(r)
    if r.pf + r.pa > 0 and math.abs(r.gf - r.ga) == 1 then
      if r.gf > r.ga then
        r.gf = r.gf - 1
      else
        r.ga = r.ga - 1
      end
    end
    return r
  end
  local mine = b and block_is_run(b, run)
  local touched = b and (((b.rivals[1] or 0) == 0) or (mine and b.index ~= 0))
  if not touched then
    return nil
  end
  return player_match_result(st, fix)
end

local function note_league_scorers(run, round, live_sc)
  if run.fmt == "league" then
    local oks, es = pcall(Tn.league_scorers, run, round, live_sc)
    if not oks then
      warn("top scorers of matchday " .. tostring(round) .. " not recorded: " .. tostring(es))
    end
  end
end

local function sync_run(phase, rules, gf, ga, pf, pa, winner, et)
  local run = load()
  if ARMED and ARMED.snap and not (run and run.loaded) then
    warn("the game's own campaign start ran for a tournament start: the Campaña's block put back")
    Block.restore(CAMP_BLOB)
    ARMED = nil
  end
  if not run then
    PLAYED = nil
    return { event = "none" }
  end
  if run.outcome then
    return { event = "ended", show = true }
  end
  local b = Block.read()
  local st = { ok = type(phase) == "string" and phase ~= "" and type(gf) == "number",
    gf = U.int(gf, 0), ga = U.int(ga, 0), pf = U.int(pf, 0), pa = U.int(pa, 0), et = et == true or et == 1,
    winner = U.int(winner, 0) }
  if not run.loaded then
    PLAYED = nil
    return { event = "none", show = false }
  end
  local res = result_of(run, b, st)
  local live_sc = PLAYED and PLAYED.sc
  PLAYED = nil
  run.loaded = false
  Block.restore(CAMP_BLOB)
  if res == false then
    save()
    warn("the match ended but no result was seen (no vrfw.match_result or rule engine STATE): " ..
      "nothing recorded, the match stays pending")
    return { event = "none", show = false }
  end
  if not res then
    save()
    info("the borrowed block was not played (a cancelled load or a restart): the Campaña's block is back")
    return { event = "none", show = false }
  end
  local m, stage = T.pending(run)
  if stage == "ko" and res.gf == res.ga and res.pf == res.pa and res.outcome ~= "win" and res.outcome ~= "loss" then
    warn(string.format("knockout match ended %d-%d with no winner (an exact tie in the Advantage Judgement, or rulebook %q not applied): a defeat",
      res.gf, res.ga, CFG.rules))
  end
  local cfg = { goals = CFG.goals, weight = CFG.weight, pen_kick = CFG.pen_kick, pen_kicks = CFG.pen_kicks }
  local done, why = T.record(run, cfg, mk, res.gf, res.ga, res.pf, res.pa, res.et, res.outcome)
  if not done then
    warn("result not recorded: " .. tostring(why))
    return { event = "none", show = false }
  end
  note_league_scorers(run, done.round, live_sc)
  info(string.format("match %d: %d-%d%s%s; %s round %d complete", run.k, res.gf, res.ga,
    (res.pf + res.pa > 0) and string.format(" (pen. %d-%d)", res.pf, res.pa) or "",
    res.outcome and (" " .. res.outcome) or "", done.stage, done.round))
  local event = "result"
  if run.outcome == "out" then
    -- the rest of the tournament is simulated round by round while the player watches (CMND_BATTLEBAYDELUXE_TOURNAMENT_STEP)
    event = "out"
    info(string.format("eliminated (%s round %d, place %d): the remaining rounds one at a time", run.place.stage,
      run.place.round, run.place.pos))
  elseif run.outcome == "champion" then
    event = "champion"
    info("CHAMPION (the tournament's own end; the Campaña's clear is not touched)")
  end
  save()
  return { event = event, show = true, rules = rules_of(run) }
end

function BattleBayDeluxe.TournamentSync(...)
  local r = sync_run(...)
  local ok, why = pcall(one_run_check)
  if not ok then
    warn("one saved run check: " .. tostring(why))
  end
  return r
end

function BattleBayDeluxe.TournamentStep()
  local run = load()
  if not run or run.outcome ~= "out" then
    return { event = "none" }
  end
  local cfg = { goals = CFG.goals, weight = CFG.weight, pen_kick = CFG.pen_kick, pen_kicks = CFG.pen_kicks }
  local done = T.sim_step(run, cfg, mk)
  save()
  if not done then
    return { event = "over" }
  end
  info(string.format("simulated %s round %d%s", done.stage, done.round,
    run.stage == "over" and string.format(": champion %s", U.hex(run.teams[T.champion(run)] or 0)) or ""))
  return { event = "step" }
end

function BattleBayDeluxe.TournamentSim()
  local run = load()
  if not run or run.fmt ~= "league" or run.outcome or run.loaded then
    return { ok = false, why = "no league match to simulate" }
  end
  local cfg = { goals = CFG.goals, weight = CFG.weight, pen_kick = CFG.pen_kick, pen_kicks = CFG.pen_kicks }
  local done, gf, ga = T.sim_player(run, cfg, mk)
  if not done then
    return { ok = false, why = tostring(gf) }
  end
  note_league_scorers(run, done.round, nil)
  info(string.format("match %d simulated: %d-%d; %s round %d complete", run.k, gf, ga, done.stage, done.round))
  save()
  return { ok = true, event = run.outcome and (run.outcome == "champion" and "champion" or "out") or "result", gf = gf, ga = ga }
end

function BattleBayDeluxe.TournamentPrepare()
  local run = load()
  if not run or run.outcome or T.opponent(run) == 0 then
    return { ok = false }
  end
  if not Block.read() then
    return { ok = false }
  end
  if Tn.before_match then
    local okb, e = pcall(Tn.before_match, run)
    if not okb then
      warn("before the match: " .. tostring(e))
    end
  end
  -- the league team plays the order the player left in the team dock (league_squad.lua)
  local okl, el = pcall(LS.ensure, run.fmt == "league" and run.lineup or nil)
  if not okl then
    warn("league lineup: " .. tostring(el))
  end
  if not run.loaded then
    if not Block.snapshot(CAMP_BLOB) then
      return { ok = false }
    end
  end
  if not write_block(run) then
    Block.restore(CAMP_BLOB)
    return { ok = false }
  end
  run.loaded = true
  save()
  final_request(run)
  return { ok = true, rules = rules_of(run) }
end

function BattleBayDeluxe.TournamentUnload()
  local run = load()
  final_request(nil)
  if run then
    run.loaded = false
    save()
  end
  Block.restore(CAMP_BLOB)
  return true
end

function BattleBayDeluxe.TournamentAbandon()
  load()
  if RUN then
    RUN.loaded = false
    Block.restore(CAMP_BLOB)
    drop("abandoned")
  end
  ARMED = nil
  return true
end

function BattleBayDeluxe.TournamentClose()
  local run = load()
  if run and run.outcome then
    drop(run.outcome)
  end
  return true
end

function BattleBayDeluxe.TournamentStillIn()
  local run = load()
  if not run or not run.loaded or run.outcome then
    return false
  end
  local _, stage = T.pending(run)
  if stage == "league" then
    info("game over after a league match: a draw or a defeat is a league result, the telop is closed unseen")
    return true
  end
  if stage ~= "groups" then
    return false
  end
  local gf, ga = played_score()
  if not gf then
    info("game over after a group match with no result seen: the telop stays")
    return false
  end
  local trial = trial_record(run, gf, ga, PLAYED.outcome)
  local still_in = trial ~= nil and trial.outcome ~= "out"
  info(string.format("game over after a group match %d-%d: %s", gf, ga,
    still_in and "still in the run, the telop is skipped" or "eliminated, the telop stays"))
  return still_in
end

function Tn.path_len(run)
  if run and not run.outcome and run.loaded then
    local _, len = Tn.path_window(run)
    return len
  end
  return G.RIVALS
end

function Tn.path_window(run)
  local total = T.run_matches(run)
  if run.fmt ~= "league" or total <= G.RIVALS then
    return 0, total
  end
  local len = G.RIVALS
  local first = math.max(0, math.min(run.k - floor(len / 2), total - len))
  return first, len
end

function BattleBayDeluxe.TournamentCampaignInfo(sub, i)
  local run = RUN_SLOT == VRFW.slots.active() and RUN or load()
  if U.int(sub, -1) == 4 then
    return true, Tn.path_len(run)
  end
  if not run or run.outcome then
    return false
  end
  if not run.loaded then
    return false
  end
  sub = U.int(sub, -1)
  local first = Tn.path_window(run)
  if sub == 1 then
    return true, run.k - first + (PLAYED and 1 or 0)
  elseif sub == 3 then
    i = U.int(i, 0)
    return true, Tn.rival_of(run, first + i + 1)
  end
  return false
end

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
        EMBLEMS[U.u32(id)] = U.u32(em)
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
  local em = emblems()[U.u32(team or 0)]
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
        local slot, card = U.int(m[1], 99), U.u32(m[2] or 0)
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
        return levels()[U.u32(v.team)]
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
        local id = U.u32(tonumber(scalar(t[1])) or 0)
        local first, count = tonumber(scalar(refs[i][1])), tonumber(scalar(refs[i][2]))
        if id ~= 0 and TACTICS[id] == nil and first and count then
          local ids = {}
          for k = first + 1, first + count do
            local v = list[k] and tonumber(scalar(list[k][1]))
            if v and v ~= 0 then
              ids[#ids + 1] = U.u32(v)
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
  return TACTICS[U.u32(team or 0)] or {}
end

function BattleBayDeluxe.LeagueSquad()
  local run = load()
  if not run or run.outcome or run.fmt ~= "league" then
    return { ok = false, why = "no running league" }
  end
  local team = U.u32(run.player_team or 0)
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
  local stadium = row and U.u32(U.get(U.struct("EnjoyRow", row), "stadium") or 0) or 0
  local emblem = (rec.emblem or 0) ~= 0 and rec.emblem or emblems()[team] or 0
  info(string.format("league squad of %s: coach %s, kit %s, emblem %s, %d tactic(s), stadium %s", U.hex(team),
    U.hex(rec.coach or 0), U.hex(rec.kit or 0), U.hex(emblem), #team_tactics(team), U.hex(stadium)))
  return { ok = true, kind = kind, team = team, formation = LS.formation(team), level = okl and lv or 1,
    emblem = emblem, kit = rec.kit or 0, coach = rec.coach or 0, tactics = team_tactics(team), synergies = {},
    stadium = stadium, members = members }
end

function BattleBayDeluxe.LeagueSquadSet(formation, placed)
  local run = load()
  if not run or run.outcome or run.fmt ~= "league" then
    return { ok = false, why = "no running league" }
  end
  local team = U.u32(run.player_team or 0)
  local list = {}
  for position, param in string.gmatch(tostring(placed or ""), "(%d+):(%d+)") do
    list[#list + 1] = { tonumber(position), tonumber(param) }
  end
  local slots = {}
  for _, m in ipairs(LS.members(team) or {}) do
    slots[#slots + 1] = m[1] .. ":" .. m[2]
  end
  info(string.format("league lineup from the dock for %s: formation %s, dock positions %s; the team's slots %s",
    U.hex(team), U.hex(formation or 0), tostring(placed), table.concat(slots, ",")))
  local order, why = LS.from_dock(team, list)
  if not order then
    warn("league lineup refused: " .. tostring(why))
    return { ok = false, why = tostring(why) }
  end
  local f = U.u32(formation or 0)
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
  info(string.format("league lineup of %s kept: %d rows changed, formation %s (%s)", U.hex(team), n, U.hex(f),
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

return Tn
