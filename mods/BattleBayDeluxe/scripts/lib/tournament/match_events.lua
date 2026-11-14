-- The Tournament's match hooks: the trial record, the live score and the played results.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local T = require "lib/tourney"
local MatchResults = Shared.MatchResults
local Trophy = require "lib/trophy_celebration"
local Block = require "lib/campaign_block"
local Tn = Shared.Tn
local info = Shared.info
local warn = Shared.warn
local CFG = Shared.CFG
local mk = Shared.mk
local load = Shared.load
local block_is_run = Shared.block_is_run

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

VRFW.on("save:slot_load", function()
  local ok, e = pcall(load)
  if not ok then
    warn("slot_load: run not read: " .. tostring(e))
  end
  return nil
end)

VRFW.on("match:start", function(ev)
  Shared.LIVE, Shared.PLAYED = nil, nil
  local run = load()
  if not run or run.outcome then
    return nil
  end
  local b = Block.read()
  if b and block_is_run(b, run) and b.index then
    Shared.LIVE = { index = b.index, rival = b.rivals[b.index + 1], sc = {} }
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
  if not Shared.LIVE then
    return
  end
  local goals_for, goals_against = event_score(ev)
  if not goals_for then
    return
  end
  local seen = Shared.LIVE.score
  if not seen or goals_for + goals_against >= seen.f + seen.a then
    Shared.LIVE.score = { f = goals_for, a = goals_against }
  end
end

local function played_score()
  if Shared.PLAYED and Shared.PLAYED.native then
    return Shared.PLAYED.gf, Shared.PLAYED.ga
  end
  if Shared.PLAYED and Shared.PLAYED.score then
    return Shared.PLAYED.score.f, Shared.PLAYED.score.a
  end
  return nil
end

VRFW.on("match:goal", function(ev)
  if Shared.LIVE then
    local actor = ev.actor
    if type(actor) == "table" and (actor.side == "user" or actor.side == "rival") and (tonumber(actor.card) or 0) ~= 0 then
      Shared.LIVE.sc[#Shared.LIVE.sc + 1] = { side = actor.side, card = VRFW.ids.unsigned(actor.card) }
    end
    note_live_score(ev)
  end
  return nil
end)

VRFW.on("script:signal:vrfw.match_result", function()
  local last = MatchResults.last()
  local okr, run = pcall(load)
  if type(last) ~= "table" or not okr or not run or run.outcome or not run.loaded then
    return nil
  end
  local native_for, native_against = U.int(last.score_for, 0), U.int(last.score_against, 0)
  local score = Shared.LIVE and Shared.LIVE.score
  Shared.PLAYED = { index = Shared.LIVE and Shared.LIVE.index, rival = Shared.LIVE and Shared.LIVE.rival, gf = native_for, ga = native_against,
    outcome = last.outcome, native = true, sc = Shared.LIVE and Shared.LIVE.sc or {},
    score = score and { f = score.f, a = score.a } or nil }
  info(string.format("match result (framework): %s %d-%d; match events %s", tostring(last.outcome), native_for,
    native_against, score and string.format("%d-%d", score.f, score.a) or "none"))
  if Shared.LIVE and last.outcome == "win" then
    local goals_for, goals_against = played_score()
    local trial = trial_record(run, goals_for, goals_against, last.outcome)
    if trial and trial.outcome == "champion" then
      Trophy.play(run.fmt == "league" and "league" or "tournament", last)
    end
    Shared.PLAYED.ends_run = trial ~= nil and trial.outcome ~= false and trial.outcome ~= nil
    if Shared.PLAYED.ends_run then
      info(string.format("the won match ends the run (%s): no match left", tostring(trial.outcome)))
    end
  end
  return nil
end)

VRFW.on("match:end", function(ev)
  if not Shared.LIVE then
    return nil
  end
  note_live_score(ev)
  local score = Shared.LIVE.score
  if Shared.PLAYED and Shared.PLAYED.native then
    Shared.PLAYED.index, Shared.PLAYED.rival, Shared.PLAYED.sc = Shared.LIVE.index, Shared.LIVE.rival, Shared.LIVE.sc
    Shared.PLAYED.score = score and { f = score.f, a = score.a } or Shared.PLAYED.score
  else
    Shared.PLAYED = { index = Shared.LIVE.index, rival = Shared.LIVE.rival, sc = Shared.LIVE.sc,
      score = score and { f = score.f, a = score.a } or nil }
  end
  Shared.final_request(nil)
  info(string.format("match over: match events %s, game's own result %s", score and string.format("%d-%d", score.f,
    score.a) or "none", (Shared.PLAYED.native and string.format("%d-%d", Shared.PLAYED.gf, Shared.PLAYED.ga)) or "none"))
  Shared.LIVE = nil
  return nil
end)

Tn.roster = nil

-- The names the later parts of the Tournament read.
Shared.trial_record = trial_record
Shared.played_score = played_score
