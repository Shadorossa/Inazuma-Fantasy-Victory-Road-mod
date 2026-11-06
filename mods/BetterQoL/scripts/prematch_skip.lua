-- BetterQoL › pre-match «hold X = straight to the kick-off» (graft research/grafts/util_prematch_skip): the answers
-- of its game Lua commands (content\game\prematch_skip.toml). BetterQoL's (better_ui.lua) until BetterQoL 1.17.0.
-- Functions only: nothing runs at load but the handler registrations (game_reset, hook:PrematchSecondEntrance).

-- The longest hold the pre-match X skip accepts (s); the default when config.toml has no usable value.
local SKIP_HOLD_MAX = 10.0
local SKIP_HOLD_DEFAULT = 1.0

-- CMND_BETTERQOL_XSKIP_HOLD() -> the seconds X must be held in a pre-match event to go straight to the kick-off (graft
-- util_prematch_skip asks it when a pre-match event starts). config.toml [prematch_skip] `hold`: 0 or less = 0 (the
-- X prompt is off), more than 10 = 10, not a number = 1.
function BetterQoL.SkipHold()
  local v = VRFW.files.config("prematch_skip.hold")
  if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
    return SKIP_HOLD_DEFAULT
  end
  if v <= 0 then
    return 0
  end
  return math.min(v, SKIP_HOLD_MAX)
end

-- CMND_BETTERQOL_XSKIP_COVER(on) -> 1 when done, 0 when the native hold is not available (content\game\prematch_skip.toml).
-- on = 1: the pre-match X skip's black cover (bright-fade layer 1) is held by the hook BrightFadeLayer until the kick-off
-- is ready (the table BetterQoL.XSkipCover gets the bright-fade object); any other value: released (the table cleared).
-- The graft util_prematch_skip asks for the hold once its own fade to black is over and releases it right before
-- its one fade in; a 0 answer keeps its Lua-only cover.
local COVER_TABLE = "BetterQoL.XSkipCover"
function BetterQoL.XSkipCover(on)
  VRFW.native.table_clear(COVER_TABLE)
  if on ~= 1 then
    return 1
  end
  if not VRFW.is_on("BrightFadeLayer") then
    return 0
  end
  local obj = VRFW.game["Render.BrightFade"]()
  if type(obj) ~= "number" or obj == 0 then
    return 0
  end
  VRFW.native.table_set(COVER_TABLE, obj, 1)
  -- the bright fade is a 64-bit object address: never "%X" on it (Lua 5.2 formats through a 32-bit `long` on Windows;
  -- «not a non-negative number in proper range» switched the script off), the high and low halves go apart
  local hi = math.floor(obj / 2 ^ 32)
  VRFW.log(string.format("pre-match X skip: black cover held (bright fade 0x%X%08X, layer 1)", hi, obj - hi * 2 ^ 32))
  return 1
end


-- CMND_BETTERQOL_XSKIP_JUMP(on) -> 1 when done, 0 when not possible (content\game\prematch_skip.toml, 1.21.7).
-- on = 1: the pre-match X skip's direct jump. The running event of the event manager (current slot) is ended in this
-- frame without the retail skip's fades: its sounds stopped (StopEventSounds, 0 s, the kept ones too, as the retail
-- skip does) and its timeline run to the end (EventSeek(slot, -1); TimelineSeek(tl, -1, 1) when the event has no cut
-- table). From then on the hook PrematchSecondEntrance keeps BattleSettingFlow from starting the second entrance event
-- (state 12 -> 13). Any other value: the jump is over (flag cleared). Every step is logged.
local EVM_CURRENT = 0x9154        -- event manager: current slot index (u32)
local EVM_SLOTS = 20
local EVM_STRIDE = 0x7E0
local SLOT_STATE = 0x508          -- u8: 1 load ... 8 playing, 10 finished
local SLOT_TIMELINE = 0x4E8       -- ptr: the event's timeline
local SLOT_CUTS = 0x5B0           -- ptr / u32 (+0x5B8): the cut table EventSeek needs
local SLOT_CUT_COUNT = 0x5B8
local SLOT_FREE_SEEK = 0x7C0      -- u8: seek allowed without a cut table
local SLOT_SKIP_TO = 0x7BC        -- f32: the retail skip's target (-1 = none)
local SLOT_NAME = 0x79C           -- char[32]
local TL_CLOCK = 0x40             -- f32: the timeline's clock (s)
local TL_STATE = 0x4B             -- u8: 1 loaded, 2 playing, 4 ended
local jump_on = false
local jumps = 0

local function hex64(v)            -- a 64-bit address as hex without "%X" on it (see XSkipCover)
  local hi = math.floor(v / 2 ^ 32)
  return string.format("0x%X%08X", hi, v - hi * 2 ^ 32)
end

local function slot_name(slot)
  local ok, bytes = pcall(VRFW.mem.read_array, "u8", slot + SLOT_NAME, 32)
  if not ok or type(bytes) ~= "table" then
    return "?"
  end
  local out = {}
  for i = 1, #bytes do
    if bytes[i] == 0 then
      break
    end
    out[#out + 1] = string.char(bytes[i])
  end
  return table.concat(out)
end

-- The current event's slot and timeline, or nil + why.
local function current_event()
  local mgr = VRFW.game["Event.Manager"]()
  if type(mgr) ~= "number" or mgr == 0 then
    return nil, "no event manager"
  end
  local idx = VRFW.mem.read("u32", mgr + EVM_CURRENT)
  if idx >= EVM_SLOTS then
    return nil, "current slot " .. idx .. " out of range"
  end
  local slot = mgr + idx * EVM_STRIDE
  local tl = VRFW.mem.read("ptr", slot + SLOT_TIMELINE)
  if tl == 0 then
    return nil, "slot " .. idx .. " has no timeline"
  end
  return slot, tl, idx
end

local function xskip_jump(on)
  if on ~= 1 then
    if jump_on then
      VRFW.log("pre-match X jump: over (kick-off reached / disarmed)")
    end
    jump_on = false
    return 1
  end
  local ok, slot, tl, idx = pcall(current_event)
  if not ok or slot == nil then
    VRFW.log("pre-match X jump: not possible (" .. tostring(ok and tl or slot) .. "): the graft uses the cover path")
    return 0
  end
  local state = VRFW.mem.read("u8", slot + SLOT_STATE)
  local tl_state = VRFW.mem.read("u8", tl + TL_STATE)
  local clock = VRFW.mem.read("f32", tl + TL_CLOCK)
  local name = slot_name(slot)
  if tl_state == 4 then
    VRFW.log(string.format("pre-match X jump: event %s (slot %d) already at its end: nothing to end", name, idx))
    jump_on = true
    return 1
  end
  jumps = jumps + 1
  VRFW.log(string.format("pre-match X jump [%d]: event %s (slot %d, state %d, timeline %d at %.2f s, slot %s)", jumps,
    name, idx, state, tl_state, clock, hex64(slot)))
  VRFW.call("Audio.StopEventSounds", slot, 0.0, 1)
  VRFW.log("pre-match X jump: event sounds stopped")
  local cuts = VRFW.mem.read("ptr", slot + SLOT_CUTS)
  local cut_count = VRFW.mem.read("u32", slot + SLOT_CUT_COUNT)
  local free = VRFW.mem.read("u8", slot + SLOT_FREE_SEEK)
  if (cuts ~= 0 and cut_count ~= 0) or free ~= 0 then
    VRFW.call("Event.Seek", slot, -1.0)
    VRFW.log(string.format("pre-match X jump: EventSeek to the end (%d cut(s), free seek %d)", cut_count, free))
  else
    VRFW.call("Event.TimelineSeek", tl, -1.0, 1)
    VRFW.log("pre-match X jump: no cut table: TimelineSeek to the end")
  end
  VRFW.mem.write("f32", slot + SLOT_SKIP_TO, -1.0)
  jump_on = true
  VRFW.log(string.format("pre-match X jump: event ended in this frame (timeline state %d): the flow goes on to the kick-off",
    VRFW.mem.read("u8", tl + TL_STATE)))
  return 1
end

-- A failing step answers 0 (the graft's cover path) instead of an error, which would switch this script off.
function BetterQoL.XSkipJump(on)
  local ok, r = pcall(xskip_jump, on)
  if ok then
    return r
  end
  VRFW.log("pre-match X jump: failed (" .. tostring(r) .. "): the graft uses the cover path")
  return 0
end

-- BattleSettingFlow state 12, before its «match info bit 0x80: one more entrance event» test: while the X jump is on,
-- skip = resume at its `mov dword [rsi+20h], 0Dh` (state 13: the lineups / kick-off), no second event.
VRFW.on("hook:PrematchSecondEntrance", function(ev)
  if not jump_on then
    return nil
  end
  local ok, st = pcall(VRFW.mem.read, "u32", ev.regs.rsi + 0x20)
  VRFW.log(string.format("pre-match X jump: second entrance event not started (flow state %s -> 13)",
    ok and tostring(st) or "?"))
  return { skip = true }
end)

-- Back to the title with the cover still held / the jump on (a pre-match left during the X skip): both released, so no
-- menu is held black and no later flow loses its second entrance event.
VRFW.on("game_reset", function()
  VRFW.native.table_clear(COVER_TABLE)
  jump_on = false
end)

-- ---------------------------------------------------------------------------------------------------------------------
-- In-match cut-in skip (docs/game/match/cutin-skip.md). The graft block cs_event.lua (event_menu Step) asks
-- CMND_BETTERQOL_CUTIN_SKIP() on a fresh press of CMD_BETTERQOL_CUTIN_SKIP. The running technique event is ended the way
-- the pre-match jump ends one: its sounds stopped and its timeline run to the end in skip mode. The game's own flow
-- (event scene, command phases, focus battle) only waits for the event to stop playing, so it goes on by itself.
-- Answers: 1 = ended, 2 = the timeline stopped at a blocking command (asked again next Step), 0 = nothing done.
local TL_NEXT_COMMAND = 0x3C      -- u32: the next command to run
local TL_COMMAND_COUNT = 0x10     -- u32: the commands of the timeline
local SLOT_STATE_PLAYING = 8
local TL_STATE_PLAYING = 2
local SKIP_ASK_LIMIT = 30         -- blocking stops of one event before the skip gives up
local cutin_playing = false       -- between the match events cutin_start and cutin_end: only then a skip applies
local cutin_started_ms = 0
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

local function end_timeline(slot, tl, name, idx)
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
    skips, name, idx, tl_state, VRFW.mem.read("u32", tl + TL_NEXT_COMMAND), VRFW.mem.read("u32", tl + TL_COMMAND_COUNT)))
  if tl_state == 4 then
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
  local synced = VRFW.match and VRFW.match.synced
  if synced and synced() then
    VRFW.log("cut-in skip: refused: synced match")
    return 0
  end
  local slot, tl, idx = current_event()
  if slot == nil then
    VRFW.log("cut-in skip: refused: " .. tostring(tl))
    return 0
  end
  local name = slot_name(slot)
  if pending_slot == slot then
    pending_asks = pending_asks + 1
    if pending_asks > SKIP_ASK_LIMIT then
      VRFW.log(string.format("cut-in skip [%d]: %s: still blocked after %d tries: it plays on", skips, name, SKIP_ASK_LIMIT))
      pending_slot = nil
      return 0
    end
    return end_timeline(slot, tl, name, idx)
  end
  if not name_in("cutin_skip.events", name) or name_in("cutin_skip.not_events", name) then
    VRFW.log("cut-in skip: not skipped: " .. name .. " is not a listed technique event")
    return 0
  end
  local state = VRFW.mem.read("u8", slot + SLOT_STATE)
  local tl_state = VRFW.mem.read("u8", tl + TL_STATE)
  local clock = VRFW.mem.read("f32", tl + TL_CLOCK)
  if state ~= SLOT_STATE_PLAYING or tl_state ~= TL_STATE_PLAYING or clock < min_seconds() then
    VRFW.log(string.format("cut-in skip: too early or over: %s slot state %d, timeline state %d at %.2f s", name, state, tl_state, clock))
    return 0
  end
  skips = skips + 1
  pending_asks = 0
  skip_log = { number = skips, at = VRFW.now() }
  VRFW.log(string.format("cut-in skip [%d]: technique event %s at %.2f s (%d ms after cutin_start), slot %d state %d, timeline state %d, ball carrier %s",
    skips, name, clock, math.floor(VRFW.now() - cutin_started_ms), idx, state, tl_state, carrier_text()))
  return end_timeline(slot, tl, name, idx)
end

-- A failing step answers 0 (the event plays on) instead of an error, which would switch this script off.
function BetterQoL.CutinSkip()
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
  pending_slot = nil
  return nil
end)

VRFW.on("cutin_end", function()
  cutin_playing = false
  pending_slot = nil
  if skip_log then
    VRFW.log(string.format("cut-in skip [%d]: the game saw the event end %d ms after the press; ball carrier %s",
      skip_log.number, math.floor(VRFW.now() - skip_log.at), carrier_text()))
    skip_log = nil
  end
  return nil
end)
