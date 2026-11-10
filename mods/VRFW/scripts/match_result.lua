
local Results = VRFW.match.results
local Memory = VRFW.memory
local u32 = VRFW.ids.unsigned
local info, warn = VRFW.logger("match_result")
local int = function(v) return VRFW.value.integer(v, 0) end

local HOOK = "MatchExp.Result"
-- the engine's half byte: 1-2 regular time, 3-4 extra time, 5 the penalty shoot-out, 6 over
local FIRST_EXTRA_HALF, SHOOTOUT_HALF = 3, 5
local IN_PLAY_STATE, FULL_TIME_STATE = 9, 6
-- match info (MatchExpInfo): +4 the game id, +0x15 the difficulty row
local INFO_GAME, INFO_DIFFICULTY = 4, 0x15
-- the judge (Match.EndPrizes): +0xDE8 won, +0xDE9 lost, +0xDEA drawn; bit 0 of +0xD74 set = +0xD75 / +0xD76 / +0xD77
local RESULT_OVERRIDE_FLAGS, RESULT_OVERRIDE_WON, RESULT_WON = 0xD74, 0xD75, 0xDE8
local RESULT_OVERRIDE_LOST, RESULT_OVERRIDE_DRAWN, RESULT_LOST, RESULT_DRAWN = 0xD76, 0xD77, 0xDE9, 0xDEA
-- the match request's teams (scripts\team_lineup.lua's block): +0 the player's team, +4 the rival
local MATCH_TEAMS_KEY = "VRFW.team_lineup.match_teams"

local SEQ = 0
local LIVE = nil   -- the match being played (match_start .. its result)

local rd = Memory.read

local global = VRFW.game.global

-- the match's game, difficulty and teams (kept from kick-off, read again at the result)
local function read_match(m)
  local minfo = global("MatchExpInfo")
  if minfo then
    m.game = u32(rd("u32", minfo + INFO_GAME))
    m.difficulty = int(rd("u8", minfo + INFO_DIFFICULTY))
  end
  local okb, block = pcall(VRFW.state.get, MATCH_TEAMS_KEY)
  if okb and type(block) == "number" then
    local mine, rival = rd("u32", block), rd("u32", block + 4)
    if mine and rival and (mine ~= 0 or rival ~= 0) then
      m.player_team, m.rival_team = u32(mine), u32(rival)
    end
  end
end

local function new_match(ev)
  local m = (type(ev) == "table" and ev.match) or (VRFW.match and VRFW.match()) or {}
  local okm, mode = pcall(VRFW.mode)
  LIVE = {
    user_side = (m.user_team == 1) and 1 or 0,
    score = { 0, 0 },
    seen = nil,
    shootout = { 0, 0 },
    shootout_played = false,
    extra_time = false,
    full_time = false,
    sent = false,
    mode_id = okm and type(mode) == "string" and VRFW.crc32(mode) or 0,
    game = 0, difficulty = -1,
  }
  if type(m.score) == "table" then
    LIVE.score = { int(m.score[1]), int(m.score[2]) }
  end
  read_match(LIVE)
end

-- the player's side as a match event (or the live match facts) gives it
local function note_side(m)
  if LIVE and type(m) == "table" and (m.user_team == 0 or m.user_team == 1) then LIVE.user_side = m.user_team end
end

local function note_half(m)
  local half = type(m) == "table" and int(m.half) or 0
  if LIVE and half >= FIRST_EXTRA_HALF and half < SHOOTOUT_HALF then LIVE.extra_time = true end
  return half
end

VRFW.on("match_start", function(ev)
  new_match(ev)
  return nil
end)

VRFW.on("game_reset", function()
  LIVE = nil
  return nil
end)

-- every goal: the score of the match, a shoot-out goal apart (the score never goes down inside a match)
VRFW.on("goal", function(ev)
  local m = type(ev) == "table" and ev.match or nil
  if not LIVE or type(m) ~= "table" or type(m.score) ~= "table" then return nil end
  local now = { int(m.score[1]), int(m.score[2]) }
  note_side(m)
  local half = note_half(m)
  if half >= SHOOTOUT_HALF then
    local before = LIVE.seen or LIVE.score
    for side = 1, 2 do
      if now[side] > before[side] then
        LIVE.shootout[side] = LIVE.shootout[side] + (now[side] - before[side])
        LIVE.shootout_played = true
      end
    end
  else
    for side = 1, 2 do
      if now[side] > LIVE.score[side] then LIVE.score[side] = now[side] end
    end
  end
  LIVE.seen = now
  return nil
end)

-- each kick-off: the half being played (extra time with no goal is seen here)
VRFW.on("state_enter:" .. IN_PLAY_STATE, function(ev)
  note_half(type(ev) == "table" and ev.match or nil)
  return nil
end)

-- the full-time state: the match reached its end (a match left from the pause menu never does)
VRFW.on("state_enter:" .. FULL_TIME_STATE, function(ev)
  if LIVE then LIVE.full_time = true end
  note_side(type(ev) == "table" and ev.match or nil)
  return nil
end)

-- the game's own judge of the finished match (Match.EndPrizes's result flags): "win" | "draw" | "loss", nil = none
local function judge()
  local block = global("MatchExpResultBlock")
  if not block then return nil end
  local override = int(rd("u8", block + RESULT_OVERRIDE_FLAGS)) % 2 == 1
  local function flag(own, overridden)
    return int(rd("u8", block + (override and overridden or own))) ~= 0
  end
  if flag(RESULT_WON, RESULT_OVERRIDE_WON) then return "win" end
  if flag(RESULT_DRAWN, RESULT_OVERRIDE_DRAWN) then return "draw" end
  if flag(RESULT_LOST, RESULT_OVERRIDE_LOST) then return "loss" end
  return nil
end

-- the one result of the match: written, logged, then the signal
local function send(source, verdict)
  if not LIVE or LIVE.sent then return end
  LIVE.sent = true
  if source == "result_builder" then
    read_match(LIVE)
    local okm, m = pcall(VRFW.match)
    if okm then note_side(m) end
  end
  local user = LIVE.user_side
  local home, away = LIVE.score[1], LIVE.score[2]
  local pens = LIVE.shootout_played
  local mine = function(t) return t[user + 1], t[2 - user] end
  local goals_for, goals_against = mine(LIVE.score)
  local pens_for, pens_against = mine(LIVE.shootout)
  local outcome = verdict
  if not outcome then
    if goals_for ~= goals_against then
      outcome = goals_for > goals_against and "win" or "loss"
    elseif pens and pens_for ~= pens_against then
      outcome = pens_for > pens_against and "win" or "loss"
    else
      outcome = "draw"
    end
  end
  local winner_side = nil
  if outcome == "win" then winner_side = user elseif outcome == "loss" then winner_side = 1 - user end
  local teams = { LIVE.player_team or 0, LIVE.rival_team or 0 }
  SEQ = SEQ + 1
  Results.write({
    seq = SEQ, home_score = home, away_score = away, user_side = user, shootout = pens,
    shootout_home = pens and LIVE.shootout[1] or nil, shootout_away = pens and LIVE.shootout[2] or nil,
    extra_time = LIVE.extra_time, winner_side = winner_side, won = outcome == "win", outcome = outcome,
    game = LIVE.game, difficulty = LIVE.difficulty, home_team = teams[user + 1], away_team = teams[2 - user],
    mode_id = LIVE.mode_id, source = source,
  })
  info(string.format("result #%d (%s): %s %d-%d%s%s, player %s, game 0x%08X difficulty %d, teams 0x%08X-0x%08X%s",
    SEQ, source, outcome, home, away, pens and string.format(" (pen. %d-%d)", LIVE.shootout[1], LIVE.shootout[2]) or "",
    LIVE.extra_time and " a.e.t." or "", user == 0 and "home" or "away", LIVE.game, LIVE.difficulty,
    teams[user + 1], teams[2 - user], verdict and "" or " (no game judge: from the score)"))
  local ok, e = pcall(VRFW.signal, "vrfw.match_result")
  if not ok then warn("signal vrfw.match_result not sent: " .. tostring(e)) end
end

VRFW.on("hook:" .. HOOK .. ":post", function()
  if not LIVE then
    -- a match this service did not see start (a script reload during it): kick-off values only
    new_match(nil)
  end
  local ok, e = pcall(send, "result_builder", judge())
  if not ok then warn("result not sent (" .. tostring(e) .. ")") end
  return nil
end)

-- the match is over: a match that reached its full time without the result builder is sent from the kept score
VRFW.on("match_end", function()
  if LIVE and LIVE.full_time and not LIVE.sent then
    local ok, e = pcall(send, "full_time", nil)
    if not ok then warn("result not sent (" .. tostring(e) .. ")") end
  elseif LIVE and not LIVE.sent then
    info("match left before its full time: no result")
  end
  LIVE = nil
  return nil
end)
