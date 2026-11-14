-- The Tournament's run commands: the final's rules and venue, info, arm, sync, step, sim, prepare, abandon and the path.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local T = require "lib/tourney"
local G = require "lib/game"
local LS = require "league_squad"
local Block = require "lib/campaign_block"
local Tn = Shared.Tn
local floor = math.floor
local info = Shared.info
local warn = Shared.warn
local CFG = Shared.CFG
local fmt_id = Shared.fmt_id
local fmt_name = Shared.fmt_name
local mk = Shared.mk
local save = Shared.save
local load = Shared.load
local drop = Shared.drop
local block_is_run = Shared.block_is_run
local write_block = Shared.write_block
local CAMP_BLOB = Shared.CAMP_BLOB
local campaign_copy_off = Shared.campaign_copy_off
local one_run_check = Shared.one_run_check
local offered_sizes = Shared.offered_sizes
local trial_record = Shared.trial_record
local played_score = Shared.played_score

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
  local map = row and U.get(VRFW.memory.struct("EnjoyRow", row), "stadium") or 0
  if map ~= 0 then
    return VRFW.ids.unsigned(map), "the league team's own stadium"
  end
  warn(string.format("league home match: team %s has no stadium of its own (enjoy row %s): the request's own stadium",
    VRFW.ids.hex_text(team), row and "without one" or "missing"))
  return nil
end

local FINAL_TABLE = "BattleBayDeluxe.FinalStadium"
Shared.final_request = function(run)
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
    active = run ~= nil and not run.outcome, ended = run ~= nil and run.outcome ~= false, armed = Shared.ARMED ~= nil,
    configured = Shared.ARMED ~= nil and Shared.ARMED.configured == true, pending = Shared.PENDING ~= nil, failed = Shared.FAILED,
    campaign = false,
    defaults = { fmt = fmt_id(CFG.fmt), size = CFG.size, filter = CFG.filter and 1 or 0,
      league_size = CFG.league_size, double = CFG.league_double and 1 or 0,
      no_national = CFG.league_no_national and 1 or 0 },
    sizes = offered_sizes(),
  }
  Shared.FAILED = nil
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
  if Shared.ARMED and Shared.ARMED.configured and b then
    local snap = Block.kept(CAMP_BLOB)
    if snap and (VRFW.ids.unsigned(snap.player) ~= b.player or VRFW.ids.unsigned(snap.rivals[1]) ~= b.rivals[1]) then
      t.campaign = true
    end
  end
  if Shared.ARMED then
    t.rules = Shared.ARMED.fmt == "knockout" and CFG.rules or ""
    t.fmt, t.size = fmt_id(Shared.ARMED.fmt), Shared.ARMED.size
    t.filter = Shared.ARMED.custom and 2 or (Shared.ARMED.filter and 1 or 0)
    t.double = Shared.ARMED.double and 1 or 0
    t.no_national = Shared.ARMED.no_national and 1 or 0
  end
  if run and not run.outcome then
    t.loaded = run.loaded == true
    t.ends_run = Shared.PLAYED ~= nil and Shared.PLAYED.ends_run == true
    local first, len = Tn.path_window(run)
    t.path = Tn.path_len(run)
    t.ci1 = run.k - first + (Shared.PLAYED and 1 or 0)
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
  if load() and not Shared.RUN.outcome then
    return false, "a tournament is running"
  end
  if not VRFW.is_on("Decide") then
    warn("not armed: the Decide hook is off on this build (content/game/campaign.toml)")
    return false, "the Decide hook is off"
  end
  local fl = U.int(filter, -1)
  local dbl = U.int(double, -1)
  Shared.ARMED = { fmt = fmt, size = size, configured = U.int(configured, 0) == 1, filter = fl == 1 or (fl == -1 and CFG.filter),
    double = fmt == "league" and (dbl == 1 or (dbl == -1 and CFG.league_double)) }
  Shared.ARMED.custom = fl == 2
  Shared.ARMED.ordered = Shared.ARMED.custom and U.int(ordered, 0) == 1
  local nn = U.int(no_national, -1)
  Shared.ARMED.no_national = fmt == "league" and (nn == 1 or (nn == -1 and CFG.league_no_national))
  Shared.PENDING, Shared.PENDING_DIFF = nil, nil
  if Shared.ARMED.configured and not (Shared.RUN and Shared.RUN.loaded) then
    if Block.snapshot(CAMP_BLOB) then
      Shared.ARMED.snap = true
    end
  end
  info(string.format("armed: %s / %d teams%s%s%s", fmt, size, Shared.ARMED.custom and (Shared.ARMED.ordered and ", teams picked by hand (pick order)" or ", teams picked by hand (shuffled)")
    or (Shared.ARMED.filter and ", minor teams filtered" or ""),
    Shared.ARMED.double and ", home and away" or "", Shared.ARMED.configured and " (options confirmed)" or ""))
  return true
end

function BattleBayDeluxe.TournamentDisarm()
  if Shared.ARMED or Shared.PENDING then
    info("disarmed")
  end
  if Shared.ARMED and Shared.ARMED.snap then
    campaign_copy_off()
  end
  Shared.ARMED, Shared.PENDING, Shared.PENDING_DIFF = nil, nil, nil
  return true
end

local function player_match_result(st, fix)
  local goals_for, goals_against = played_score()
  local source = Shared.PLAYED and Shared.PLAYED.native and "framework's match result" or "match events"
  if not goals_for then
    if not st.ok then
      return false
    end
    goals_for, goals_against, source = st.gf, st.ga, "rule engine state"
  end
  local r = { gf = goals_for, ga = goals_against, pf = 0, pa = 0, et = false, outcome = Shared.PLAYED and Shared.PLAYED.outcome or nil }
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
  if Shared.ARMED and Shared.ARMED.snap and not (run and run.loaded) then
    warn("the game's own campaign start ran for a tournament start: the Campaña's block put back")
    Block.restore(CAMP_BLOB)
    Shared.ARMED = nil
  end
  if not run then
    Shared.PLAYED = nil
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
    Shared.PLAYED = nil
    return { event = "none", show = false }
  end
  local res = result_of(run, b, st)
  local live_sc = Shared.PLAYED and Shared.PLAYED.sc
  Shared.PLAYED = nil
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
    run.stage == "over" and string.format(": champion %s", VRFW.ids.hex_text(run.teams[T.champion(run)] or 0)) or ""))
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
  Shared.final_request(run)
  return { ok = true, rules = rules_of(run) }
end

function BattleBayDeluxe.TournamentUnload()
  local run = load()
  Shared.final_request(nil)
  if run then
    run.loaded = false
    save()
  end
  Block.restore(CAMP_BLOB)
  return true
end

function BattleBayDeluxe.TournamentAbandon()
  load()
  if Shared.RUN then
    Shared.RUN.loaded = false
    Block.restore(CAMP_BLOB)
    drop("abandoned")
  end
  Shared.ARMED = nil
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
  local trial = trial_record(run, gf, ga, Shared.PLAYED.outcome)
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
  local run = Shared.RUN_SLOT == VRFW.slots.active() and Shared.RUN or load()
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
    return true, run.k - first + (Shared.PLAYED and 1 or 0)
  elseif sub == 3 then
    i = U.int(i, 0)
    return true, Tn.rival_of(run, first + i + 1)
  end
  return false
end

-- The names the later parts of the Tournament read.
Shared.final_stadium = final_stadium
