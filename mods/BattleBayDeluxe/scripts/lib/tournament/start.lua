-- The Tournament's picks and start: the stored picks, the pick command, begin, pend and the player's team.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local T = require "lib/tourney"
local Block = require "lib/campaign_block"
local Tn = Shared.Tn
local RUN_VERSION = Shared.RUN_VERSION
local info = Shared.info
local warn = Shared.warn
local CFG = Shared.CFG
local mk = Shared.mk
local strength = Shared.strength
local filtered_opponents = Shared.filtered_opponents
local save = Shared.save
local load = Shared.load
local campaign_copy_off = Shared.campaign_copy_off
local campaign_clear = Shared.campaign_clear
local excluded = Shared.excluded
local league_sets = Shared.league_sets

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
  local seen = { [club[VRFW.ids.unsigned(player)] or VRFW.ids.unsigned(player)] = true }
  local out = {}
  for _, t in ipairs(type(list) == "table" and list or {}) do
    t = VRFW.ids.unsigned(t)
    local c = club[t] or t
    if t ~= 0 and t ~= VRFW.ids.unsigned(player) and not seen[c] then
      seen[c] = true
      out[#out + 1] = t
    end
  end
  return out
end

function BattleBayDeluxe.TournamentPick(op, fmt, team, player)
  op, team, player = U.int(op, -1), VRFW.ids.unsigned(team or 0), VRFW.ids.unsigned(player or 0)
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
  return Shared.ARMED ~= nil and Shared.ARMED.configured == true
end

-- the player's team of an armed "Custom" tournament (the team the picker opened for), nil = none
function Tn.picked_player()
  if Shared.ARMED == nil or not Shared.ARMED.custom or PICK == nil or PICK.player == 0 then
    return nil
  end
  return PICK.mode == (Shared.ARMED.fmt == "league" and "league" or "tournament") and PICK.player or nil
end

function Tn.begin(cands, player, h, l)
  local a = Shared.ARMED
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
    local opps = {}
    for i, t in ipairs(picks) do
      opps[i] = { team = t, str = strength(t) }
    end
    local run, why = T.new({ fmt = a.fmt, size = size, seed = { h, l }, player = player,
      player_str = strength(player), opponents = opps, seeded = CFG.seeded, double = a.double, mk = mk,
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
  Shared.POOL = #cands
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
  -- the minor teams filter picks WHO plays, never how many (the count stays the power of two above)
  if a.filter then
    v = filtered_opponents(v, size - 1)
    rng:shuffle(v)
  end
  local opps = {}
  for i = 1, size - 1 do
    opps[i] = { team = v[i], str = strength(v[i]) }
  end
  local run, why = T.new({ fmt = a.fmt, size = size, seed = { h, l }, player = player,
    player_str = strength(player), opponents = opps, seeded = CFG.seeded, double = a.double, mk = mk })
  if not run then
    return nil, why
  end
  run.v = RUN_VERSION
  run.player_team = player
  return run
end

local function start_now()
  local run, diff = Shared.PENDING, Shared.PENDING_DIFF
  if not run or not diff then
    return false
  end
  Shared.PENDING, Shared.PENDING_DIFF = nil, nil
  local r1 = run.teams[T.opponent(run)]
  run.sess = { game = 0, diff = diff, player = run.player_team, r1 = r1 }
  run.loaded = false
  Shared.ARMED = nil
  Shared.RUN, Shared.RUN_SLOT = run, VRFW.slots.active()
  save()
  campaign_copy_off()
  local kept = Block.read()
  if Block.alive(kept) then
    if campaign_clear() then
      info(string.format("the saved Campaña (player %s, rival 1 %s, match %d) ended by this start", VRFW.ids.hex_text(kept.player),
        VRFW.ids.hex_text(kept.rivals[1]), kept.index + 1))
    else
      warn("the saved Campaña was not cleared at this start (the next sync clears it)")
    end
  end
  if Tn.on_started then
    pcall(Tn.on_started, run)
  end
  info(string.format("started: %s / %d teams%s, player %s, difficulty %d, first rival %s, seed %s:%s", run.fmt,
    run.size, run.double and " (home and away)" or "", VRFW.ids.hex_text(run.player_team), diff, VRFW.ids.hex_text(r1), VRFW.ids.hex_text(run.seed[1]),
    VRFW.ids.hex_text(run.seed[2])))
  return true
end

function Tn.pend(run)
  Shared.PENDING = run
  Shared.FAILED = nil
  info("drawn at the grid's start (the game's own start refused); waiting for the difficulty")
  return start_now()
end

function BattleBayDeluxe.TournamentStart(diff)
  diff = U.int(diff, 0)
  if diff < 1 or diff > 16 then
    return { ok = false, why = "difficulty" }
  end
  Shared.PENDING_DIFF = diff
  local ok = start_now()
  return { ok = ok or (Shared.RUN ~= nil and Shared.RUN.k == 0 and not Shared.RUN.outcome), waiting = Shared.PENDING_DIFF ~= nil }
end

function Tn.fail(why)
  Shared.FAILED = tostring(why or "?")
  warn("start failed: " .. Shared.FAILED)
end

function Tn.player_team()
  local run = load()
  if not run or run.outcome then
    return 0
  end
  return run.player_team or 0
end

Tn.before_match = nil
