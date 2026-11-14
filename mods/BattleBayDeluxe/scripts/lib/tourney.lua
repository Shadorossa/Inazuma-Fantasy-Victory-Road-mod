-- The Tournament's rules over the framework's competition run (VRFW.competition.run): the offered formats and sizes and the match model.
local Competition = VRFW.competition
local Run = Competition.run

local T = {}

local floor, exp, min, max = math.floor, math.exp, math.min, math.max

T.round_robin = Run.round_robin

T.FORMATS = { knockout = true, groups = true, league = true }
T.FORMAT_IDS = { knockout = 0, groups = 1, league = 2 }
T.FORMAT_OF = { [0] = "knockout", [1] = "groups", [2] = "league" }
T.LEAGUE = { MIN = 4, MAX = 36, STEP = 2 }
T.MIN_SIZE, T.MAX_SIZE, T.MIN_GROUPS_SIZE = 4, 64, 8

-- the defaults of config.toml [tournament] (the in-game setup step overrides fmt / size)
T.DEFAULTS = {
  fmt = "knockout",
  size = 16,
  seeded = true,        -- seeds kept apart in the knockout tree / one per group (pots)
  goals = 1.3,          -- mean goals of a side between equal teams
  weight = 0.035,
  pen_kick = 0.75,      -- a penalty's chance to score
  pen_kicks = 5,
}

-- n is a power of two in MIN_SIZE ..
local function isize(n)
  if type(n) ~= "number" or n < T.MIN_SIZE or n > T.MAX_SIZE or n ~= floor(n) then
    return false
  end
  return Competition.is_power_of_two(n)
end
T.is_size = isize

T.player_matches = Run.player_matches
T.run_matches = Run.run_matches

T.MAX_PLAYER_MATCHES = math.max(T.player_matches("knockout", T.MAX_SIZE), T.player_matches("groups", T.MAX_SIZE))

local function league_size(n)
  local L = T.LEAGUE
  return type(n) == "number" and n == floor(n) and n >= L.MIN and n <= L.MAX and (n - L.MIN) % L.STEP == 0
    and n % 2 == 0
end

function T.valid(fmt, size)
  if fmt == "league" then
    return league_size(size)
  end
  return T.FORMATS[fmt] == true and isize(size) and (fmt ~= "groups" or size >= T.MIN_GROUPS_SIZE)
    and T.player_matches(fmt, size) <= T.MAX_PLAYER_MATCHES
end

function T.sizes(fmt, cap)
  local out = {}
  if fmt == "league" then
    for n = T.LEAGUE.MIN, T.LEAGUE.MAX, T.LEAGUE.STEP do
      if T.valid(fmt, n) and (cap == nil or n <= cap) then
        out[#out + 1] = n
      end
    end
    return out
  end
  local n = T.MIN_SIZE
  while n <= T.MAX_SIZE do
    if T.valid(fmt, n) and (cap == nil or n <= cap) then
      out[#out + 1] = n
    end
    n = n * 2
  end
  return out
end

local function unit(r)
  return r:below(2147483648) / 2147483648
end

-- a goal count of mean lambda (at most 13 draws)
local function poisson(r, lambda)
  return Competition.poisson(function()
    return unit(r)
  end, lambda, 12)
end

T.seed_order = Competition.seed_order
T.league_schedule = Run.league_schedule

-- The Tournament's match model: Poisson goals from the strength gap, extra time and a shoot-out in a knockout.
function T.simulate(run, cfg, r, a, b, ko)
  local d = ((run.str[a] or 0) - (run.str[b] or 0)) * cfg.weight
  local la = min(5, max(0.15, cfg.goals * exp(d / 2)))
  local lb = min(5, max(0.15, cfg.goals * exp(-d / 2)))
  local ga, gb = poisson(r, la), poisson(r, lb)
  local pa, pb, et = 0, 0, false
  if ko and ga == gb then
    et = true
    ga = ga + poisson(r, la / 3)
    gb = gb + poisson(r, lb / 3)
    if ga == gb then
      local tilt = min(0.1, max(-0.1, d / 20))
      pa, pb = Competition.shootout(function()
        return unit(r)
      end, cfg.pen_kick + tilt, cfg.pen_kick - tilt, cfg.pen_kicks, 30)
    end
  end
  local w = 0
  if ga > gb or (ga == gb and pa > pb) then
    w = a
  elseif gb > ga or (ga == gb and pb > pa) then
    w = b
  end
  return ga, gb, pa, pb, et, w
end

-- The run rules of the Tournament: the caller's generator and the match model with `cfg`.
local function rules(cfg, mk)
  return {
    rng = mk,
    simulate = function(run, r, a, b, ko)
      return T.simulate(run, cfg, r, a, b, ko)
    end,
  }
end

-- a new run.
function T.new(opts)
  if not T.valid(opts.fmt, opts.size) then
    return nil, "format " .. tostring(opts.fmt) .. " / " .. tostring(opts.size) .. " teams is not offered"
  end
  return Run.new(opts, { rng = opts.mk })
end

T.match = Run.match
T.table = Run.table
T.pending = Run.pending
T.opponent = Run.opponent

function T.record(run, cfg, mk, gf, ga, pf, pa, et, outcome)
  return Run.record(run, rules(cfg, mk), gf, ga, pf, pa, et, outcome)
end

function T.sim_player(run, cfg, mk)
  return Run.sim_player(run, rules(cfg, mk))
end

function T.sim_step(run, cfg, mk)
  return Run.sim_step(run, rules(cfg, mk))
end

T.champion = Run.champion
T.ko_rounds = Run.ko_rounds
T.round_from_end = Run.round_from_end

return T
