-- Stoppage Time (a module of Football Reforged): added time at the end of every
-- half, from what happened in it, and an end decided by the play when that time runs out. Settings: config.toml.
-- The mechanisms are the VR-Framework's period service ( time_up):
-- * the engine ends a period when int(clock) >= its length + its added time (InPlayState::Update); the added time is
--   VRFW.match.set_added(seconds); VRFW.match.end_period() ends it at the next open-play frame.
-- * time_up:regular fires 2 game s before the regular length, time_up:end 2 game s before length + added time.
-- Everything here runs on events: the half's events add seconds (foul, cutin_start of a technique group, keeper_scene,
-- goal, match:substitution); time_up:regular turns them into whole minutes, sets the added time and sets the «+N» text;
-- the text lives on a layer of the scoreboard's screen, so the game shows and hides it with the scoreboard
-- (assets\lua\_all\stoppage_time_telop.lua); the half's end states clear the text; time_up:end
-- checks the team with the ball: in its own half the whistle blows at once; further up the added time grows to the
-- zone's limit and the whistle blows when the play ends (possession to the rival, a shot resolved, a goal, a foul, an end
-- state such as OutOfPlay, in midfield also a pass back). A running shot, chain window or cut-in delays the whistle.
-- A match with a tag of skip_match_tags (VRFW.match.has_tag: the pachangas' friendlies declare tags = ["pachanga"])
-- gets no added time.

StoppageTime = StoppageTime or {}

local Basics = require "VRFW/lib/basics"
local info = VRFW.logger("stoppage_time")

local clamp = Basics.value.clamp   -- a config number with a default, kept inside its range

local function list_setting(t, k, default)
  local v = t and t[k]
  if type(v) ~= "table" then return default end
  return v
end

local function config(name)
  local t = VRFW.config(name)
  return type(t) == "table" and t or {}
end

local RAW = config("stoppage_time")
local RAW_PLAY_ON = config("play_on")
local RAW_TELOP = config("telop")
local SECONDS = type(RAW.seconds) == "table" and RAW.seconds or {}
local TECHNIQUE = type(RAW.technique) == "table" and RAW.technique or {}

local function set_of(list)
  local s = {}
  for _, v in ipairs(list) do s[v] = true end
  return s
end

local SETTINGS = {
  halves = set_of(list_setting(RAW, "halves", { 1, 2, 3, 4 })),
  round_up = RAW.rounding == "up",
  min_minutes = clamp(RAW.min_minutes, 1, 0, 60),
  max_minutes = clamp(RAW.max_minutes, 5, 0, 60),
  blocked_modes = list_setting(RAW, "blocked_modes", { "story" }),
  blocked_states = list_setting(RAW, "blocked_states", { "match.challenge.active", "match.training" }),
  skip_match_tags = list_setting(RAW, "skip_match_tags", { "pachanga" }),
  log = RAW.log ~= false,
  seconds = {
    foul = clamp(SECONDS.foul, 15, 0, 600),
    technique = clamp(SECONDS.technique, 5, 0, 600),
    keeper_scene = clamp(SECONDS.keeper_scene, 5, 0, 600),
    goal = clamp(SECONDS.goal, 30, 0, 600),
    substitution = clamp(SECONDS.substitution, 20, 0, 600),
  },
  technique_groups = set_of(list_setting(TECHNIQUE, "groups", { "shot", "dribble", "defense" })),
  play_on = RAW_PLAY_ON.enabled ~= false,
  own_half_until = clamp(RAW_PLAY_ON.own_half_until, 0.5, 0, 1),
  near_goal_from = clamp(RAW_PLAY_ON.near_goal_from, 0.7, 0, 1),
  back_pass_margin = clamp(RAW_PLAY_ON.back_pass_margin, 0.05, 0, 1),
  max_overrun = clamp(RAW_PLAY_ON.max_overrun_seconds, 110, 0, 600),
  midfield_max_overrun = clamp(RAW_PLAY_ON.midfield_max_overrun_seconds, 45, 0, 600),
  wait_step = clamp(RAW_PLAY_ON.wait_step_seconds, 30, 1, 120),
  wait_max = clamp(RAW_PLAY_ON.wait_max_seconds, 90, 0, 600),
  shot_settle = clamp(RAW_PLAY_ON.shot_settle_seconds, 30, 1, 120),
  end_states = list_setting(RAW_PLAY_ON, "end_states", { 12, 17 }),
  telop = RAW_TELOP.enabled ~= false,
  telop_x = clamp(RAW_TELOP.center_x, 960, 0, 1920),
  telop_y = clamp(RAW_TELOP.middle_y, 148, 0, 1080),
  telop_height = clamp(RAW_TELOP.text_height, 28, 8, 120),
  telop_end_states = list_setting(RAW_TELOP, "end_states", { 2, 3, 6, 7, 8, 11, 22, 28 }),
}
SETTINGS.min_minutes, SETTINGS.max_minutes = math.floor(SETTINGS.min_minutes), math.floor(SETTINGS.max_minutes)
if SETTINGS.max_minutes < SETTINGS.min_minutes then SETTINGS.max_minutes = SETTINGS.min_minutes end

local function log(...)
  if SETTINGS.log then info(...) end
end

local TELOP_MENU = "soccer_constant_menu"   -- the screen of the scoreboard, in every kind of match
local TELOP_REFRESH = "StoppageTime_TelopRefresh"
local MENU_CALL_SLOT = 0x70 / 8

-- the half being counted
local S = {
  half = nil,          -- its number (1-4), nil = none yet
  counting = false,    -- its events add seconds (from its kick-off to the regular end)
  total = 0,           -- game seconds its events added
  counts = {},         -- events by kind
  announced = nil,     -- the minutes set at the regular end
  announced_end = nil, -- the clock second the announced time ends
  over_time = false,   -- the announced time is used up
  whistled = false,    -- the end of the half was asked
  whistle_clock = nil, -- the clock when it was asked
  refusal_logged = false, -- the engine's late whistle was logged
  half_over_logged = false, -- the half's end was logged
  play_on = nil,       -- { team, zone, front } while the play goes on past the announced time
  waiting = false,     -- the decision waits for a running shot, chain window or cut-in
  waited = 0,          -- game seconds added while waiting
  pending_whistle = nil, -- the reason of a whistle that waits for the same
  shot_running = false,  -- the ball is in the shot state
  shot_over = false,   -- past the announced time, the ball left the shot state
  chain_open = false,  -- a shot can be chained now
  last_owner = nil,    -- { team, handle } of the last ball owner (a loose ball's attacking team)
  telop_text = nil,    -- «+N» from the half's regular end to its end, nil = no telop
  cutin_running = false, -- a cut-in is playing
  skip_logged = nil,   -- the reason a match tag gave, logged once per match (nil = not logged)
}

-- the scoreboard's screen reads the text again: the game's own way to call a function of a menu's script
-- (CLuaMenuObject vtable +0x70: menu, function name, no arguments; a script without the function does nothing)
local function telop_notify()
  local ok, menu = pcall(VRFW.call, "StoppageTime.MenuFind", VRFW.crc32(TELOP_MENU))
  if not ok or type(menu) ~= "number" or menu == 0 then return end
  if S.refresh_name == nil then
    local bytes = { string.byte(TELOP_REFRESH, 1, -1) }
    bytes[#bytes + 1] = 0
    S.refresh_name = VRFW.mem.buffer("telop_refresh_name", #bytes)
    VRFW.mem.write_array("u8", S.refresh_name, bytes)
  end
  local called, why = pcall(VRFW.call_vslot, menu, MENU_CALL_SLOT, "ptr, ptr, u32 -> ptr", S.refresh_name, 0, 0)
  if not called then log("telop: the scoreboard's screen was not told (" .. tostring(why) .. ")") end
end

local function telop_set(text)
  if S.telop_text == text then return end
  S.telop_text = text
  telop_notify()
end

-- the half or the match ended: no telop until the next half's regular end
local function telop_end()
  S.cutin_running = false
  telop_set(nil)
end

local function period()
  local ok, p = pcall(VRFW.match.period)
  return (ok and type(p) == "table") and p or nil
end

-- a tag of the match (VRFW.match.has_tag: the tags its friendly declares) in skip_match_tags
local function skipped_tag()
  for _, t in ipairs(SETTINGS.skip_match_tags) do
    local ok, on = pcall(VRFW.match.has_tag, tostring(t))
    if ok and on then return "match tag " .. tostring(t) end
  end
  return nil
end

local function blocked()
  local tag = skipped_tag()
  if tag then return tag, true end
  for _, k in ipairs(SETTINGS.blocked_modes) do
    local ok, on = pcall(VRFW.mode_is, k)
    if ok and on then return "mode " .. k end
  end
  for _, k in ipairs(SETTINGS.blocked_states) do
    local ok, v = pcall(VRFW.state, k)
    if ok and v ~= nil and v ~= false and v ~= 0 then return "state " .. k end
  end
  return nil
end

-- nothing decided yet about the end of a half
local function reset_half_end()
  S.announced_end, S.over_time, S.whistled = nil, false, false
  S.whistle_clock, S.refusal_logged, S.half_over_logged = nil, false, false
  S.play_on, S.waiting, S.waited, S.pending_whistle = nil, false, 0, nil
  S.shot_running, S.shot_over, S.chain_open = false, false, false
end

-- a new half: its count starts (only in a period that gets added time)
local function start_half(p)
  S.half, S.total, S.counts = p.half, 0, {}
  S.announced = nil
  reset_half_end()
  S.last_owner = nil
  telop_end()
  local why, by_tag = nil, false
  if not SETTINGS.halves[p.half] then
    why = "half not in halves"
  else
    why, by_tag = blocked()
  end
  S.counting = why == nil
  if by_tag then
    -- once per match: every half of a tagged match is skipped for the same reason
    if S.skip_logged ~= why then
      S.skip_logged = why
      log(string.format("no added time in this match (%s, skip_match_tags)", why))
    end
  elseif why then
    log(string.format("half %d: no added time (%s)", p.half, why))
  end
end

-- the period now, the half being counted (a half not seen at its kick-off starts its count here)
local function current()
  local p = period()
  if p == nil then return nil end
  if S.half ~= p.half then start_half(p) end
  return p
end

local function add(kind)
  if not S.counting then return end
  local p = period()
  if p == nil or p.half ~= S.half or p.clock >= p.length then return end
  S.total = S.total + SETTINGS.seconds[kind]
  S.counts[kind] = (S.counts[kind] or 0) + 1
end

local function minutes_of(total)
  local m = total / 60
  m = SETTINGS.round_up and math.ceil(m - 1e-9) or math.floor(m + 0.5)
  if m < SETTINGS.min_minutes then m = SETTINGS.min_minutes end
  if m > SETTINGS.max_minutes then m = SETTINGS.max_minutes end
  return m
end

local function summary()
  local parts = {}
  for _, k in ipairs({ "foul", "technique", "keeper_scene", "goal", "substitution" }) do
    if S.counts[k] then parts[#parts + 1] = string.format("%s %d", k, S.counts[k]) end
  end
  return #parts > 0 and table.concat(parts, ", ") or "no events"
end

local function telop_text(minutes)
  return "+" .. tostring(minutes)
end

-- the pitch fraction (0 own goal .. 1 the goal it attacks) of x, z for `team`, nil = no pitch data
local function attack_fraction(team, x, z)
  local ok_own, ox, oz = pcall(VRFW.ai.own_goal, team)
  local ok_rival, rx, rz = pcall(VRFW.ai.own_goal, 1 - team)
  if not (ok_own and ox and ok_rival and rx) then return nil end
  local ax, az = rx - ox, rz - oz
  local len2 = ax * ax + az * az
  if len2 <= 0 then return nil end
  return ((x - ox) * ax + (z - oz) * az) / len2
end

-- the attacking side now: team, x, z of the ball's owner, or of the last owner while the ball is loose (a pass, a shot)
local function attacker()
  local ok, hdl, team, x, z = pcall(VRFW.ai.ball)
  if ok and hdl and team and x and z then return team, x, z, "carrier" end
  local last = S.last_owner
  if last == nil then return nil end
  local okp, players = pcall(VRFW.ai.players, last.team)
  if not okp or type(players) ~= "table" then return nil end
  for _, pl in ipairs(players) do
    if pl.handle == last.handle then return last.team, pl.x, pl.z, "last owner" end
  end
  return nil
end

-- a shot, a chain window or a cut-in is running: the whistle never cuts them
local function play_running()
  return S.shot_running or S.chain_open or S.cutin_running
end

-- ask the end of the half now
local function blow_whistle(why)
  local p = period()
  local past = (p and S.announced_end) and math.max(0, p.clock - S.announced_end) or 0
  local ok, done = pcall(VRFW.match.end_period)
  log(string.format("half %s: whistle (%s), %.0f game s past the announced +%s, clock %.0f, end of the half %s",
    tostring(S.half), why, past, tostring(S.announced), p and p.clock or -1, (ok and done) and "asked" or "NOT asked"))
  S.whistled, S.play_on, S.waiting, S.pending_whistle = true, nil, false, nil
  S.whistle_clock = p and p.clock or nil
end

-- the play is over: the whistle, now or when what is running ends
local function whistle(why)
  if S.whistled or not S.over_time then return end
  if play_running() then
    S.pending_whistle = S.pending_whistle or why
    return
  end
  blow_whistle(why)
end

-- the half's end moves to `added` game seconds past its length
local function set_end(added)
  local ok, done = pcall(VRFW.match.set_added, math.ceil(added))
  return ok and done == true
end

-- what the position of the ball says now: the whistle, or the play goes on up to its zone's limit
local function decide(p)
  local team, x, z, whose = attacker()
  if team == nil then
    whistle("nobody has the ball, no owner seen")
    return
  end
  local f = attack_fraction(team, x, z)
  if f == nil or f < SETTINGS.own_half_until then
    whistle(string.format("team %d in its own half, %s at %s of the pitch", team, whose,
      f and string.format("%.2f", f) or "?"))
    return
  end
  local near = f >= SETTINGS.near_goal_from
  local zone = near and "near goal" or "midfield"
  local stop_at = S.announced_end + (near and SETTINGS.max_overrun or SETTINGS.midfield_max_overrun)
  if p.clock >= stop_at - 3 then
    whistle(string.format("%s limit reached, team %d, %s at %.2f of the pitch", zone, team, whose, f))
    return
  end
  if not set_end(stop_at - p.length) then
    whistle("the added time was not written")
    return
  end
  local was = S.play_on
  if was == nil or was.zone ~= zone or was.team ~= team then
    log(string.format("half %d: time up, team %d plays on (%s, %s at %.2f of the pitch), at most until clock %.0f",
      p.half, team, zone, whose, f, stop_at))
  end
  S.play_on = { team = team, zone = zone, front = (was and was.team == team) and math.max(was.front, f) or f }
end

-- a running shot, chain window or cut-in ended: what waited for it
local function running_ended()
  if S.whistled or play_running() then return end
  if S.pending_whistle then
    blow_whistle(S.pending_whistle)
  elseif S.waiting then
    S.waiting = false
    local p = period()
    if p and not S.shot_over then decide(p) end
  end
end

-- the clock when a half with added time ended, once per half
local function log_half_over(state)
  if not S.announced_end or S.half_over_logged then return end
  S.half_over_logged = true
  local p = period()
  log(string.format("half %s over in state %d: clock %.0f, length %s, announced end %.0f", tostring(S.half), state,
    p and p.clock or -1, p and tostring(p.length) or "?", S.announced_end))
end

-- ---------------------------------------------------------------- events

VRFW.on("match_start", function()
  S.half, S.counting, S.skip_logged = nil, false, nil
  reset_half_end()
  telop_end()
  return nil
end)
VRFW.on("match_end", function()
  S.half, S.counting, S.skip_logged = nil, false, nil
  reset_half_end()
  telop_end()
  return nil
end)

-- each kick-off: a new half starts its count
VRFW.on("state_enter:9", function()
  current()
  return nil
end)

-- the half-time break: nothing counts until the next kick-off
VRFW.on("state_enter:11", function()
  log_half_over(11)
  S.counting = false
  reset_half_end()
  return nil
end)

VRFW.on("foul", function()
  add("foul")
  whistle("foul")
  return nil
end)

VRFW.on("goal", function()
  add("goal")
  S.shot_running = false
  whistle("goal")
  return nil
end)

VRFW.on("cutin_start", function(ev)
  if SETTINGS.technique_groups[ev.arg] then add("technique") end
  S.cutin_running = true
  return nil
end)

VRFW.on("cutin_end", function()
  S.cutin_running = false
  running_ended()
  return nil
end)

VRFW.on("shot_start", function()
  S.shot_running, S.shot_over, S.pending_whistle = true, false, nil
  return nil
end)

-- the ball left the shot state: a save, a goal or the ball out resolves it; a ball left loose ends it after a moment
VRFW.on("shot_end", function()
  S.shot_running = false
  if S.over_time and not S.whistled then
    S.shot_over = true
    local p = period()
    if p and not S.pending_whistle and not play_running() then
      set_end(math.floor(p.clock) - p.length + SETTINGS.shot_settle)
    end
  end
  running_ended()
  return nil
end)

VRFW.on("chain_window_start", function()
  S.chain_open = true
  return nil
end)

VRFW.on("chain_window_end", function()
  S.chain_open = false
  running_ended()
  return nil
end)

VRFW.on("keeper_save", function()
  whistle("the keeper saved the shot")
  return nil
end)

VRFW.on("ball_stopped", function()
  whistle("the shot was stopped")
  return nil
end)

VRFW.on("keeper_scene", function()
  add("keeper_scene")
  return nil
end)

VRFW.on("match:substitution:post", function()
  add("substitution")
  return nil
end)

VRFW.on("possession", function(ev)
  local a = ev.actor
  if a == nil or a.team == nil then return nil end
  S.last_owner = { team = a.team, handle = a.handle }
  if S.whistled then
    -- the engine holds its whistle while the ball is in the shot state or the owner's event check is in state 2
    local now = period()
    if now and S.whistle_clock and not S.refusal_logged and now.clock >= S.whistle_clock + SETTINGS.wait_max then
      S.refusal_logged = true
      log(string.format("half %d: the engine has not whistled: clock %.0f, %.0f game s after the end was asked",
        now.half, now.clock, now.clock - S.whistle_clock))
    end
    return nil
  end
  if not S.over_time then return nil end
  if S.shot_over then
    whistle("the shot is over, the ball has a new owner")
    return nil
  end
  local play = S.play_on
  if play == nil then return nil end
  if a.team ~= play.team then
    whistle("the rival won the ball")
    return nil
  end
  if play_running() then return nil end
  -- a pass arrived: further up, the zone may change; back in midfield, the play is over
  local p = period()
  local team, x, z, whose = attacker()
  local f = (p and team) and attack_fraction(team, x, z) or nil
  if f == nil then return nil end
  if play.zone == "midfield" and f < SETTINGS.near_goal_from and f < play.front - SETTINGS.back_pass_margin then
    whistle(string.format("pass back in midfield, %s at %.2f of the pitch, it had reached %.2f", whose, f, play.front))
  else
    decide(p)
  end
  return nil
end)

for _, st in ipairs(SETTINGS.end_states) do
  local n = tonumber(st)
  if n then
    VRFW.on("state_enter:" .. math.floor(n), function()
      S.shot_running = false
      whistle("state " .. math.floor(n))
      return nil
    end)
  end
end

-- the regular time ends: the added time and its telop
VRFW.on("time_up:regular", function()
  local p = current()
  if p == nil or not S.counting or S.announced then return nil end
  S.counting = false
  local minutes = minutes_of(S.total)
  local want = minutes * 60
  local wrote = true
  if want > p.added then
    local ok, done = pcall(VRFW.match.set_added, want)
    wrote = ok and done == true
  end
  S.announced = minutes
  S.announced_end = p.length + math.max(want, p.added)
  if SETTINGS.telop and minutes > 0 then
    telop_set(telop_text(minutes))
  end
  log(string.format("half %d: +%d min at clock %.0f, length %d (%.0f s of events: %s; added time %d -> %d game s, write %s)",
    p.half, minutes, p.clock, p.length, S.total, summary(), p.added, math.max(want, p.added), tostring(wrote)))
  return nil
end)

-- the announced time is used up, or a limit set after it is reached
VRFW.on("time_up:end", function()
  local p = current()
  if p == nil or S.announced == nil or not SETTINGS.play_on or S.whistled then return nil end
  -- only at the end itself (length + added time, the trigger's 2 s lead)
  if p.clock < p.length + p.added - 3 then return nil end
  S.over_time = true
  if play_running() then
    if S.waited >= SETTINGS.wait_max then
      -- a running flag never cleared must not hold the half
      S.shot_running, S.chain_open = false, false
      blow_whistle(S.pending_whistle or "wait limit reached")
      return nil
    end
    S.waited = S.waited + SETTINGS.wait_step
    S.waiting = true
    log(string.format("half %d: time up at clock %.0f, the whistle waits for the running play", p.half, p.clock))
    set_end(math.ceil(p.clock) - p.length + SETTINGS.wait_step)
    return nil
  end
  if S.shot_over then
    whistle("the shot is over, loose ball")
    return nil
  end
  decide(p)
  return nil
end)

-- ---------------------------------------------------------------- the telop

-- the half or the match ends: its period-end banner comes with these states
for _, st in ipairs(SETTINGS.telop_end_states) do
  VRFW.on("state_enter:" .. math.floor(st), function()
    log_half_over(math.floor(st))
    telop_end()
    return nil
  end)
end

-- CMND_STOPPAGETIME_TELOP() -> text, centre x, middle y, text height: asked by the layer when it opens and when told
function StoppageTime.Telop()
  return S.telop_text or "", SETTINGS.telop_x, SETTINGS.telop_y, SETTINGS.telop_height
end

info(string.format("loaded: %s, %g-%g min, play-on %s (own half until %.2f, near goal from %.2f, at most %g game s, midfield %g), telop %s",
  table.concat((function()
    local t = {}
    for _, k in ipairs({ "foul", "technique", "keeper_scene", "goal", "substitution" }) do
      t[#t + 1] = string.format("%s %gs", k, SETTINGS.seconds[k])
    end
    return t
  end)(), ", "), SETTINGS.min_minutes, SETTINGS.max_minutes, tostring(SETTINGS.play_on), SETTINGS.own_half_until,
  SETTINGS.near_goal_from, SETTINGS.max_overrun, SETTINGS.midfield_max_overrun, tostring(SETTINGS.telop)))
