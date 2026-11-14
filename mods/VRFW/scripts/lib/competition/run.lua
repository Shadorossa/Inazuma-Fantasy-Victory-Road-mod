-- Advanced: One competition run as saved state: the draw, the rounds, the player's pending match and the outcome (docs/framework/competition.md).
local Competition = VRFW.competition

local Run = {}

local floor = math.floor

-- The group pairings of four slots: slot a, slot b, matchday.
local GROUP_PAIRS = { { 1, 2, 1 }, { 3, 4, 1 }, { 1, 3, 2 }, { 2, 4, 2 }, { 1, 4, 3 }, { 2, 3, 3 } }

-- The tiebreaks of a run's tables: the drawn lot decides the last tie.
local TABLE_TIEBREAKS = { "points", "goal_diff", "goals_for", "head_to_head", "lot" }

--- Internal: True when `stage` plays matchdays (groups or league) rather than knockout rounds.
function Run.round_robin(stage)
  return stage == "groups" or stage == "league"
end
local round_robin = Run.round_robin

--- Internal: True when the engine can draw format `fmt` with `size` entrants: knockout 2^n, groups 2^n of at least 8, league even.
function Run.supports(fmt, size)
  if type(size) ~= "number" or size ~= floor(size) then
    return false
  end
  if fmt == "league" then
    return size >= 2 and size % 2 == 0
  end
  if fmt == "groups" then
    return size >= 8 and Competition.is_power_of_two(size)
  end
  return fmt == "knockout" and Competition.is_power_of_two(size)
end

--- Internal: The matches the player plays in format `fmt` with `size` entrants when it reaches the end (`double` = league home and away).
function Run.player_matches(fmt, size, double)
  if fmt == "league" then
    return (size - 1) * (double and 2 or 1)
  end
  local ko = size
  local n = 0
  if fmt == "groups" then
    n = 3
    ko = size / 2
  end
  while ko > 1 do
    n = n + 1
    ko = ko / 2
  end
  return n
end

--- Internal: The matches the player of `run` plays when it reaches the end.
function Run.run_matches(run)
  return Run.player_matches(run.fmt, run.size, run.double)
end

-- The generator of one draw of a run, from the run seed and three tags; `make(hi, lo)` is the caller's generator.
local function tag_rng(run, make, a, b, c)
  local h = (run.seed[1] + a * 2654435761) % 4294967296
  local l = (run.seed[2] + b * 2246822519 + c * 3266489917) % 4294967296
  local r = make(h, l)
  r:next()
  return r
end

-- The entrants sorted by strength, the drawn lot breaking ties.
local function by_strength(run, ids)
  local v = {}
  for i, e in ipairs(ids) do
    v[i] = e
  end
  table.sort(v, function(x, y)
    if run.str[x] ~= run.str[y] then
      return run.str[x] > run.str[y]
    end
    return run.lot[x] < run.lot[y]
  end)
  return v
end

--- Internal: The league fixtures of `ids` as a flat list { a, b, md } (`double` = home and away).
function Run.league_schedule(ids, double)
  local out = {}
  for md, day in ipairs(Competition.round_robin(ids, { double = double, rotate = "left" })) do
    for _, m in ipairs(day) do
      out[#out + 1] = { a = m[1], b = m[2], md = md }
    end
  end
  return out
end

--- Internal: A match between entrants `a` and `b` that is not played yet (0 = not known).
function Run.match(a, b)
  return { a = a or 0, b = b or 0, ga = 0, gb = 0, pa = 0, pb = 0, et = false, w = 0, done = false, md = 0 }
end

local function round_robin_match(a, b, md)
  return { a = a, b = b, md = md, ga = 0, gb = 0, pa = 0, pb = 0, et = false, w = 0, done = false }
end

--- Internal: A new run drawn from `opts` (fmt, size, seed {hi, lo}, player, player_str, opponents {team, str}, seeded, ordered, double) with `rules.rng`.
function Run.new(opts, rules)
  local fmt, size = opts.fmt, opts.size
  if not Run.supports(fmt, size) then
    return nil, "format " .. tostring(fmt) .. " / " .. tostring(size) .. " teams cannot be drawn"
  end
  if #opts.opponents < size - 1 then
    return nil, string.format("%d opponents for %d teams", #opts.opponents, size)
  end
  local run = {
    v = 1, fmt = fmt, size = size, seed = { opts.seed[1], opts.seed[2] }, player = 1,
    teams = { opts.player }, str = { opts.player_str or 0 }, lot = {},
    stage = fmt == "knockout" and "ko" or fmt, md = 1, mds = 3, kr = 1, k = 0, outcome = false,
    place = false, last = false, ko = {}, seeded = opts.seeded ~= false and opts.ordered ~= true,
    double = fmt == "league" and opts.double == true,
  }
  for i = 1, size - 1 do
    run.teams[i + 1] = opts.opponents[i].team
    run.str[i + 1] = opts.opponents[i].str or 0
  end
  local r = tag_rng(run, rules.rng, 1, 0, 0)
  local ids = {}
  for e = 1, size do
    ids[e] = e
  end
  if opts.ordered ~= true then
    r:shuffle(ids)
  end
  for i, e in ipairs(ids) do
    run.lot[e] = i
  end
  if fmt == "league" then
    local order = {}
    for i, e in ipairs(ids) do
      order[i] = e
    end
    run.groups, run.gm = { order }, { {} }
    for i, m in ipairs(Run.league_schedule(order, run.double)) do
      run.gm[1][i] = round_robin_match(m.a, m.b, m.md)
    end
    run.mds = (size - 1) * (run.double and 2 or 1)
  elseif fmt == "groups" then
    local G = size / 4
    run.groups, run.gm = {}, {}
    local order
    if run.seeded then
      order = by_strength(run, ids)
      for p = 0, 3 do
        local pot = {}
        for g = 1, G do
          pot[g] = order[p * G + g]
        end
        r:shuffle(pot)
        for g = 1, G do
          order[p * G + g] = pot[g]
        end
      end
    else
      order = ids
    end
    for g = 1, G do
      run.groups[g] = { order[g], order[G + g], order[2 * G + g], order[3 * G + g] }
      -- The group's slots are shuffled so the seed is not always the first team of the schedule.
      r:shuffle(run.groups[g])
      local s = run.groups[g]
      run.gm[g] = {}
      for i, p in ipairs(GROUP_PAIRS) do
        run.gm[g][i] = round_robin_match(s[p[1]], s[p[2]], p[3])
      end
    end
  else
    local leaves
    if run.seeded then
      local order = by_strength(run, ids)
      local so = Competition.seed_order(size)
      leaves = {}
      for i = 1, size do
        leaves[i] = order[so[i]]
      end
    else
      leaves = ids
    end
    run.ko[1] = {}
    for i = 1, size / 2 do
      run.ko[1][i] = Run.match(leaves[2 * i - 1], leaves[2 * i])
    end
  end
  return run
end

local function set(m, ga, gb, pa, pb, et, w)
  m.ga, m.gb, m.pa, m.pb, m.et, m.w, m.done = ga, gb, pa, pb, et, w, true
end

--- Internal: The table of group `g` of `run` (rows e, pl, w, d, l, gf, ga, gd, pts), best first.
function Run.table(run, g)
  local results = {}
  for _, m in ipairs(run.gm[g]) do
    if m.done then
      results[#results + 1] = { m.a, m.b, m.ga, m.gb }
    end
  end
  local rows = {}
  for i, x in ipairs(Competition.standings(run.groups[g], results, { tiebreaks = TABLE_TIEBREAKS, lot = run.lot })) do
    rows[i] = { e = x.team, pl = x.played, w = x.won, d = x.drawn, l = x.lost, gf = x.goals_for, ga = x.goals_against,
      gd = x.goal_diff, pts = x.points }
  end
  return rows
end

-- The first knockout round after the groups: group winners meet the runners-up of the neighbour group.
local function ko_from_groups(run)
  local G = #run.groups
  local W, R = {}, {}
  for g = 1, G do
    local t = Run.table(run, g)
    W[g], R[g] = t[1].e, t[2].e
  end
  local r1 = {}
  for g = 1, G, 2 do
    r1[#r1 + 1] = Run.match(W[g], R[g + 1])
  end
  for g = 1, G, 2 do
    r1[#r1 + 1] = Run.match(W[g + 1], R[g])
  end
  run.ko[1] = r1
end

--- Internal: The player's next match of `run`, its stage, its round or matchday and its group; nil when none is open.
function Run.pending(run)
  if run.outcome then
    return nil
  end
  local p = run.player
  if round_robin(run.stage) then
    for g, gm in ipairs(run.gm) do
      for _, m in ipairs(gm) do
        if m.md == run.md and not m.done and (m.a == p or m.b == p) then
          return m, run.stage, run.md, g
        end
      end
    end
    return nil
  end
  local rd = run.ko[run.kr]
  if not rd then
    return nil
  end
  for _, m in ipairs(rd) do
    if not m.done and (m.a == p or m.b == p) then
      return m, "ko", run.kr
    end
  end
  return nil
end

--- Internal: The entrant the player meets next in `run` (0 = none).
function Run.opponent(run)
  local m = Run.pending(run)
  if not m then
    return 0
  end
  return m.a == run.player and m.b or m.a
end

-- The next knockout round from the winners of the current one; false after the final.
local function next_round(run)
  local rd = run.ko[run.kr]
  if #rd == 1 then
    return false
  end
  local nx = {}
  for i = 1, #rd, 2 do
    nx[#nx + 1] = Run.match(rd[i].w, rd[i + 1].w)
  end
  run.kr = run.kr + 1
  run.ko[run.kr] = nx
  return true
end

-- Simulates every open match of the current round, the player's own one only when `all` is true.
local function sim_round(run, rules, all)
  if round_robin(run.stage) then
    for g, gm in ipairs(run.gm) do
      for i, m in ipairs(gm) do
        if m.md == run.md and not m.done and (all or (m.a ~= run.player and m.b ~= run.player)) then
          set(m, rules.simulate(run, tag_rng(run, rules.rng, 2, run.md * 64 + g, i), m.a, m.b, false))
        end
      end
    end
  else
    for i, m in ipairs(run.ko[run.kr]) do
      if not m.done and (all or (m.a ~= run.player and m.b ~= run.player)) then
        set(m, rules.simulate(run, tag_rng(run, rules.rng, 3, run.kr, i), m.a, m.b, true))
      end
    end
  end
end

local function finish(run, outcome, stage, round, pos)
  run.outcome = outcome
  run.place = { stage = stage, round = round, pos = pos or 0 }
end

-- The player's place in group `g`'s table (0 = not in it).
local function place_in(run, g)
  for i, x in ipairs(Run.table(run, g)) do
    if x.e == run.player then
      return i
    end
  end
  return 0
end

-- Moves the run on after the current round is complete.
local function advance(run)
  local p = run.player
  if run.stage == "league" then
    if run.md < run.mds then
      run.md = run.md + 1
      return
    end
    local pos = place_in(run, 1)
    run.stage = "over"
    finish(run, pos == 1 and "champion" or "out", "league", run.md, pos)
    return
  end
  if run.stage == "groups" then
    if run.md < (run.mds or 3) then
      run.md = run.md + 1
      return
    end
    local pos = 0
    for g = 1, #run.groups do
      local at = place_in(run, g)
      if at ~= 0 then
        pos = at
      end
    end
    ko_from_groups(run)
    run.stage, run.kr = "ko", 1
    if pos > 2 then
      finish(run, "out", "groups", 3, pos)
    end
    return
  end
  local rd = run.ko[run.kr]
  local mine
  for _, m in ipairs(rd) do
    if m.a == p or m.b == p then
      mine = m
    end
  end
  if mine and mine.w ~= p and not run.outcome then
    finish(run, "out", "ko", run.kr, 0)
  end
  if not next_round(run) then
    run.stage = "over"
    if mine and mine.w == p then
      finish(run, "champion", "ko", run.kr, 1)
    end
  end
end

--- Internal: Records the player's result (goals for / against, penalties, extra time, `outcome` "win" / "loss" when the score is level) and plays the round on.
function Run.record(run, rules, gf, ga, pf, pa, et, outcome)
  local m, stage, round = Run.pending(run)
  if not m then
    return nil, "no pending match"
  end
  local mine_a = m.a == run.player
  local ka, kb = mine_a and gf or ga, mine_a and ga or gf
  local qa, qb = mine_a and pf or pa, mine_a and pa or pf
  local w = 0
  if ka > kb or (ka == kb and qa > qb) then
    w = m.a
  elseif kb > ka or (ka == kb and qb > qa) then
    w = m.b
  elseif outcome == "win" or outcome == "loss" then
    w = ((outcome == "win") == mine_a) and m.a or m.b
  end
  if stage == "ko" and w == 0 then
    w = mine_a and m.b or m.a
  end
  set(m, ka, kb, qa, qb, et == true, w)
  run.k = run.k + 1
  sim_round(run, rules, false)
  run.last = { stage = stage, round = round }
  advance(run)
  return run.last
end

--- Internal: Simulates the player's own match with `rules.simulate` and records it; returns the round played and the player's goals for / against.
function Run.sim_player(run, rules)
  local m, stage, round = Run.pending(run)
  if not m then
    return nil, "no pending match"
  end
  local ko = stage == "ko"
  local ka, kb, qa, qb, et = rules.simulate(run, tag_rng(run, rules.rng, 4, ko and 1 or 0, round), m.a, m.b, ko)
  local mine_a = m.a == run.player
  local gf, ga = mine_a and ka or kb, mine_a and kb or ka
  local done, why = Run.record(run, rules, gf, ga, mine_a and qa or qb, mine_a and qb or qa, et, nil)
  if not done then
    return nil, why
  end
  return done, gf, ga
end

--- Internal: Simulates the whole current round, the player's match included, once the player is out; nil when the run is over.
function Run.sim_step(run, rules)
  if run.stage == "over" then
    return nil
  end
  local st = run.stage
  local rd = round_robin(st) and run.md or run.kr
  sim_round(run, rules, true)
  run.last = { stage = st, round = rd }
  if round_robin(st) then
    advance(run)
  elseif not next_round(run) then
    run.stage = "over"
  end
  return run.last
end

--- Internal: The winner of `run` (0 = not decided yet).
function Run.champion(run)
  if run.fmt == "league" then
    if run.stage ~= "over" then
      return 0
    end
    local t = Run.table(run, 1)
    return t[1] and t[1].e or 0
  end
  local last = run.ko[#run.ko]
  if last and #last == 1 and last[1].done then
    return last[1].w
  end
  return 0
end

--- Internal: The number of knockout rounds of `run`.
function Run.ko_rounds(run)
  local n = run.fmt == "groups" and run.size / 2 or run.size
  local r = 0
  while n > 1 do
    r = r + 1
    n = n / 2
  end
  return r
end

--- Internal: Knockout round `r` of `run` counted from the final (1 = the final).
function Run.round_from_end(run, r)
  return Run.ko_rounds(run) - r + 1
end

return Run
