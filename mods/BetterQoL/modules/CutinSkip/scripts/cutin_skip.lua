-- Technique Cut-in Skip (a module of BetterQoL, docs/game/match/cutin-skip.md). The graft cutin_skip (event_menu Step)
-- asks CMND_CUTINSKIP_SKIP on a fresh press of CMD_CUTINSKIP_SKIP. The running technique event is ended the way the
-- pre-match jump ends one: its sounds stopped and its timeline run to the end in skip mode. The game's own flow (event
-- scene, command phases, focus battle) only waits for the event to stop playing, so it goes on by itself.
-- Answers: 1 = ended, 2 = the timeline stopped at a blocking command (asked again next Step), 0 = nothing done.
-- Functions only: nothing runs at load but the handler registrations (cutin_start, cutin_end).

local SLOT_STATE = 0x508          -- u8: 1 load ... 8 playing, 10 finished
local SLOT_CUTS = 0x5B0           -- ptr / u32 (+0x5B8): the cut table EventSeek needs
local SLOT_CUT_COUNT = 0x5B8
local SLOT_FREE_SEEK = 0x7C0      -- u8: seek allowed without a cut table
local SLOT_SKIP_TO = 0x7BC        -- f32: the retail skip's target (-1 = none)
local TL_COMMAND_COUNT = 0x10     -- u32: the commands of the timeline
local TL_NEXT_COMMAND = 0x3C      -- u32: the next command to run
local TL_CLOCK = 0x40             -- f32: the timeline's clock (s)
local TL_STATE = 0x4B             -- u8: 1 loaded, 2 playing, 4 ended
local SLOT_STATE_PLAYING = 8
local TL_STATE_PLAYING = 2
local TL_STATE_ENDED = 4
local SKIP_ASK_LIMIT = 30         -- blocking stops of one event before the skip gives up
local cutin_playing = false       -- between the match events cutin_start and cutin_end: only then a skip applies
local cutin_started_ms = 0
local cutin_label = "?"           -- the running event's name at its cutin_start, for the line at its cutin_end
local press_seen = false          -- a press reached this script during the running event
local skips = 0
local skip_log = nil              -- the last skip's number and time, for the line at its cutin_end
local pending_slot = nil          -- the slot whose timeline stopped at a blocking command
local pending_asks = 0

-- config.toml [cutin_skip] `events` / `not_events`: the event name prefixes a skip applies to / never applies to
local function name_in(key, name)
  local list = VRFW.files.config(key)
  if type(list) ~= "table" then
    return false
  end
  for _, prefix in ipairs(list) do
    if type(prefix) == "string" and prefix ~= "" and name:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

local function min_seconds()
  local v = VRFW.files.config("cutin_skip.min_seconds")
  return (type(v) == "number" and v == v and v >= 0) and v or 0
end

local function carrier_text()
  local ball = VRFW.ai and VRFW.ai.ball
  if not ball then
    return "unknown"
  end
  local ok, hdl, team = pcall(ball)
  if ok and hdl then
    return string.format("%08X (team %s)", hdl, tostring(team))
  end
  return "none"
end

local function end_timeline(ev)
  local slot, tl = ev.slot, ev.timeline
  VRFW.call("Audio.StopEventSounds", slot, 0.0, 1)
  local cuts = VRFW.mem.read("ptr", slot + SLOT_CUTS)
  local cut_count = VRFW.mem.read("u32", slot + SLOT_CUT_COUNT)
  local free = VRFW.mem.read("u8", slot + SLOT_FREE_SEEK)
  if (cuts ~= 0 and cut_count ~= 0) or free ~= 0 then
    VRFW.call("Event.Seek", slot, -1.0)
  else
    VRFW.call("Event.TimelineSeek", tl, -1.0, 1)
  end
  VRFW.mem.write("f32", slot + SLOT_SKIP_TO, -1.0)
  local tl_state = VRFW.mem.read("u8", tl + TL_STATE)
  VRFW.log(string.format("cut-in skip [%d]: %s (slot %d): sounds stopped, timeline run to the end: timeline state %d, next command %d of %d",
    skips, ev.label, ev.index, tl_state, VRFW.mem.read("u32", tl + TL_NEXT_COMMAND), VRFW.mem.read("u32", tl + TL_COMMAND_COUNT)))
  if tl_state == TL_STATE_ENDED then
    pending_slot = nil
    return 1
  end
  pending_slot = slot
  return 2
end

local function cutin_skip()
  if not cutin_playing then
    return 0
  end
  press_seen = true
  local synced = VRFW.match and VRFW.match.synced
  if synced and synced() then
    VRFW.log("cut-in skip: refused: synced match")
    return 0
  end
  local ev = BetterQoL.RunningEvent()
  if ev.slot == nil then
    VRFW.log("cut-in skip: refused: " .. tostring(ev.why))
    return 0
  end
  local slot, tl = ev.slot, ev.timeline
  if pending_slot == slot then
    pending_asks = pending_asks + 1
    if pending_asks > SKIP_ASK_LIMIT then
      VRFW.log(string.format("cut-in skip [%d]: %s: still blocked after %d tries: it plays on", skips, ev.label, SKIP_ASK_LIMIT))
      pending_slot = nil
      return 0
    end
    return end_timeline(ev)
  end
  if not name_in("cutin_skip.events", ev.name) or name_in("cutin_skip.not_events", ev.name) then
    VRFW.log("cut-in skip: not skipped: " .. ev.label .. " is not a listed technique event")
    return 0
  end
  local state = VRFW.mem.read("u8", slot + SLOT_STATE)
  local tl_state = VRFW.mem.read("u8", tl + TL_STATE)
  local clock = VRFW.mem.read("f32", tl + TL_CLOCK)
  if state ~= SLOT_STATE_PLAYING or tl_state ~= TL_STATE_PLAYING or clock < min_seconds() then
    VRFW.log(string.format("cut-in skip: too early or over: %s slot state %d, timeline state %d at %.2f s", ev.label, state, tl_state, clock))
    return 0
  end
  skips = skips + 1
  pending_asks = 0
  skip_log = { number = skips, at = VRFW.now() }
  VRFW.log(string.format("cut-in skip [%d]: technique event %s at %.2f s (%d ms after cutin_start), slot %d state %d, timeline state %d, ball carrier %s",
    skips, ev.label, clock, math.floor(VRFW.now() - cutin_started_ms), ev.index, state, tl_state, carrier_text()))
  return end_timeline(ev)
end

-- A failing step answers 0 (the event plays on) instead of an error, which would switch this script off.
function CutinSkip.Skip()
  local ok, r = pcall(cutin_skip)
  if ok then
    return r
  end
  VRFW.log("cut-in skip: failed: " .. tostring(r))
  pending_slot = nil
  return 0
end

VRFW.on("cutin_start", function()
  cutin_playing = true
  cutin_started_ms = VRFW.now()
  press_seen = false
  pending_slot = nil
  local ok, ev = pcall(BetterQoL.RunningEvent)
  cutin_label = ok and ev.label or "?"
  return nil
end)

VRFW.on("cutin_end", function()
  cutin_playing = false
  pending_slot = nil
  if skip_log then
    VRFW.log(string.format("cut-in skip [%d]: the game saw the event end %d ms after the press; ball carrier %s",
      skip_log.number, math.floor(VRFW.now() - skip_log.at), carrier_text()))
    skip_log = nil
  elseif not press_seen then
    VRFW.log("cut-in skip: event " .. tostring(cutin_label) .. " played to its end, no press reached the skip")
  end
  return nil
end)
