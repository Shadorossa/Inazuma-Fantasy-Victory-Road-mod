-- The Tournament's libraries, its config.toml values and the log.
local Shared = require "lib/tournament/context"

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

-- The names the later parts of the Tournament read.
Shared.Catalogue = Catalogue
Shared.MatchResults = MatchResults
Shared.Tn = Tn
Shared.BLOB = BLOB
Shared.RUN_VERSION = RUN_VERSION
Shared.info = info
Shared.warn = warn
Shared.CFG = CFG
Shared.fmt_id = fmt_id
Shared.fmt_name = fmt_name
