
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
local SKIP_ASK_LIMIT = 30
local cutin_playing = false
local cutin_started_ms = 0
local cutin_label = nil           -- the running event's name, read when its slot can be read
local cutin_label_why = nil       -- why the name was not read
local press_seen = false          -- a press reached this script during the running event
local menu_reports = 0            -- reports of event_menu's Step during the running event
local menu_device_presses = 0     -- of them, with a fresh pad A / Enter read from the devices
local menu_command_presses = 0    -- of them, with CMD_CUTINSKIP_SKIP on in an event controller
local DEVICE_NAMES = { "pad A", "Enter" }
local CONTROLLER_NAMES = { "EVENT_CTRL_VISUAL", "EVENT_CTRL_TALK", "EVENT_CTRL_RPG_FUNC" }
local NOT_ASKED_NAMES = { "the game is paused", "the pause closed just now", "network match", "observer" }
local skips = 0
local skip_log = nil
local pending_slot = nil          -- the slot whose timeline stopped at a blocking command
local pending_asks = 0

local function name_in(key, name)
  local list = VRFW.config(key)
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
  local v = VRFW.config("cutin_skip.min_seconds")
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

-- the running event's name for a log line; read again until its slot can be read
local function event_label()
  if cutin_label == nil then
    local ev = BetterQoL.RunningEvent()
    cutin_label = ev.label
    cutin_label_why = ev.why
  end
  return cutin_label or ("not read (" .. tostring(cutin_label_why) .. ")")
end

local function end_timeline(ev)
  local slot, tl = ev.slot, ev.timeline
  VRFW.call("Audio.StopEventSounds", slot, 0.0, 1)
  local cuts = VRFW.memory.read("ptr", slot + SLOT_CUTS)
  local cut_count = VRFW.memory.read("u32", slot + SLOT_CUT_COUNT)
  local free = VRFW.memory.read("u8", slot + SLOT_FREE_SEEK)
  if (cuts ~= 0 and cut_count ~= 0) or free ~= 0 then
    VRFW.call("Event.Seek", slot, -1.0)
  else
    VRFW.call("Event.TimelineSeek", tl, -1.0, 1)
  end
  VRFW.memory.write("f32", slot + SLOT_SKIP_TO, -1.0)
  local tl_state = VRFW.memory.read("u8", tl + TL_STATE)
  VRFW.log(string.format("cut-in skip [%d]: %s (slot %d): sounds stopped, timeline run to the end: timeline state %d, next command %d of %d",
    skips, ev.label, ev.index, tl_state, VRFW.memory.read("u32", tl + TL_NEXT_COMMAND), VRFW.memory.read("u32", tl + TL_COMMAND_COUNT)))
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
    VRFW.log("cut-in skip: not skipped: " .. ev.label .. " is not a listed event")
    return 0
  end
  local state = VRFW.memory.read("u8", slot + SLOT_STATE)
  local tl_state = VRFW.memory.read("u8", tl + TL_STATE)
  local clock = VRFW.memory.read("f32", tl + TL_CLOCK)
  if state ~= SLOT_STATE_PLAYING or tl_state ~= TL_STATE_PLAYING or clock < min_seconds() then
    VRFW.log(string.format("cut-in skip: too early or over: %s slot state %d, timeline state %d at %.2f s", ev.label, state, tl_state, clock))
    return 0
  end
  skips = skips + 1
  pending_asks = 0
  skip_log = { number = skips, at = VRFW.now_ms() }
  VRFW.log(string.format("cut-in skip [%d]: event %s at %.2f s (%d ms after cutin_start), slot %d state %d, timeline state %d, ball carrier %s",
    skips, ev.label, clock, math.floor(VRFW.now_ms() - cutin_started_ms), ev.index, state, tl_state, carrier_text()))
  return end_timeline(ev)
end

-- event_menu's Step reports each fresh press it reads, and one heartbeat a second: one log line per press in a cut-in.
function CutinSkip.MenuReport(device, controller, not_asked)
  if not cutin_playing then
    return 0
  end
  menu_reports = menu_reports + 1
  if device == 0 and controller == 0 then
    return 0
  end
  menu_device_presses = menu_device_presses + (device ~= 0 and 1 or 0)
  menu_command_presses = menu_command_presses + (controller ~= 0 and 1 or 0)
  local asked = "the skip is asked"
  if controller == 0 then
    asked = "not asked: no event controller answers CMD_CUTINSKIP_SKIP"
  elseif not_asked ~= 0 then
    asked = "not asked: " .. tostring(NOT_ASKED_NAMES[not_asked])
  end
  VRFW.log(string.format("cut-in skip: press seen by event_menu in %s: device %s, controller %s: %s", event_label(),
    DEVICE_NAMES[device] or "none", CONTROLLER_NAMES[controller] or "none", asked))
  return 0
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
  cutin_started_ms = VRFW.now_ms()
  press_seen = false
  pending_slot = nil
  cutin_label, cutin_label_why = nil, nil
  menu_reports, menu_device_presses, menu_command_presses = 0, 0, 0
  event_label()
  return nil
end)

VRFW.on("cutin_end", function()
  cutin_playing = false
  pending_slot = nil
  if skip_log then
    VRFW.log(string.format("cut-in skip [%d]: the game saw the event end %d ms after the press; ball carrier %s",
      skip_log.number, math.floor(VRFW.now_ms() - skip_log.at), carrier_text()))
    skip_log = nil
  elseif not press_seen then
    VRFW.log(string.format("cut-in skip: event %s played to its end, no press reached the skip: event_menu's Step reported %d time(s), %d device press(es), %d CMD_CUTINSKIP_SKIP press(es)",
      event_label(), menu_reports, menu_device_presses, menu_command_presses))
  end
  return nil
end)
