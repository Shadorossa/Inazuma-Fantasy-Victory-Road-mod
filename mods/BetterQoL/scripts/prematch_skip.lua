local Memory = VRFW.memory
local SKIP_HOLD_MAX = 10.0
local SKIP_HOLD_DEFAULT = 1.0

local function hex64(v)
  local hi = math.floor(v / 2 ^ 32)
  return string.format("0x%X%08X", hi, v - hi * 2 ^ 32)
end

function BetterQoL.SkipHold()
  local v = VRFW.config("prematch_skip.hold")
  if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
    return SKIP_HOLD_DEFAULT
  end
  if v <= 0 then
    return 0
  end
  return math.min(v, SKIP_HOLD_MAX)
end

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
  VRFW.log("pre-match X skip: black cover held (bright fade " .. hex64(obj) .. ", layer 1)")
  return 1
end

local EVM_CURRENT = 0x9154        -- event manager: current slot index (u32)
local EVM_SLOTS = 20
local EVM_STRIDE = 0x7E0
local SLOT_STATE = 0x508          -- u8: 1 load ... 8 playing, 10 finished
local SLOT_TIMELINE = 0x4E8       -- ptr: the event's timeline
local SLOT_CUTS = 0x5B0           -- ptr: the cut table EventSeek needs
local SLOT_CUT_COUNT = 0x5B8
local SLOT_FREE_SEEK = 0x7C0      -- u8: seek allowed without a cut table
local SLOT_SKIP_TO = 0x7BC        -- f32: the retail skip's target (-1 = none)
local SLOT_NAME = 0x79C
local SLOT_ENV_ROW = 0x500        -- ptr: the event's event_env_config row
local ENV_ROW_ID = 0x00           -- u32: crc32 of the name
local ENV_ROW_NAME = 0x08         -- ptr: the event's name
local TL_CLOCK = 0x40             -- f32: the timeline's clock (s)
local TL_STATE = 0x4B             -- u8: 1 loaded, 2 playing, 4 ended
local jump_on = false
local jumps = 0

-- the bytes at `at` up to the first zero (32 at most), "" when not readable
local function read_text(at)
  local bytes = VRFW.memory.read_array("u8", at, 32)
  if type(bytes) ~= "table" then
    return ""
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

local function slot_name(slot)
  local ok, name = pcall(function()
    local override = read_text(slot + SLOT_NAME)
    if override ~= "" then
      return override
    end
    local row = VRFW.memory.read("ptr", slot + SLOT_ENV_ROW)
    if row == 0 then
      return ""
    end
    local text = VRFW.memory.read("ptr", row + ENV_ROW_NAME)
    return text ~= 0 and read_text(text) or ""
  end)
  return ok and name or ""
end

-- the event's name for a log line, or its row id when the name cannot be read
local function slot_label(slot)
  local name = slot_name(slot)
  if name ~= "" then
    return name
  end
  local ok, id = pcall(function()
    local row = VRFW.memory.read("ptr", slot + SLOT_ENV_ROW)
    return row ~= 0 and string.format("row id 0x%08X", VRFW.memory.read("u32", row + ENV_ROW_ID)) or "no row"
  end)
  return "unnamed (" .. (ok and id or "row not readable") .. ")"
end

-- the current event's slot, timeline and index, or nil + why
local function current_event()
  local mgr = VRFW.game["Event.Manager"]()
  if type(mgr) ~= "number" or mgr == 0 then
    return nil, "no event manager"
  end
  local idx = VRFW.memory.read("u32", mgr + EVM_CURRENT)
  if idx >= EVM_SLOTS then
    return nil, "current slot " .. idx .. " out of range"
  end
  local slot = mgr + idx * EVM_STRIDE
  local tl = VRFW.memory.read("ptr", slot + SLOT_TIMELINE)
  if tl == 0 then
    return nil, "slot " .. idx .. " has no timeline"
  end
  return slot, tl, idx
end

function BetterQoL.RunningEvent()
  local ok, slot, tl, idx = pcall(current_event)
  if not ok then
    return { why = tostring(slot) }
  end
  if slot == nil then
    return { why = tostring(tl) }
  end
  return { slot = slot, timeline = tl, index = idx, name = slot_name(slot), label = slot_label(slot) }
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
  local state = VRFW.memory.read("u8", slot + SLOT_STATE)
  local tl_state = VRFW.memory.read("u8", tl + TL_STATE)
  local clock = VRFW.memory.read("f32", tl + TL_CLOCK)
  local name = slot_label(slot)
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
  local cuts = VRFW.memory.read("ptr", slot + SLOT_CUTS)
  local cut_count = VRFW.memory.read("u32", slot + SLOT_CUT_COUNT)
  local free = VRFW.memory.read("u8", slot + SLOT_FREE_SEEK)
  if (cuts ~= 0 and cut_count ~= 0) or free ~= 0 then
    VRFW.call("Event.Seek", slot, -1.0)
    VRFW.log(string.format("pre-match X jump: EventSeek to the end (%d cut(s), free seek %d)", cut_count, free))
  else
    VRFW.call("Event.TimelineSeek", tl, -1.0, 1)
    VRFW.log("pre-match X jump: no cut table: TimelineSeek to the end")
  end
  VRFW.memory.write("f32", slot + SLOT_SKIP_TO, -1.0)
  jump_on = true
  VRFW.log(string.format("pre-match X jump: event ended in this frame (timeline state %d): the flow goes on to the kick-off",
    VRFW.memory.read("u8", tl + TL_STATE)))
  return 1
end

function BetterQoL.XSkipJump(on)
  local ok, r = pcall(xskip_jump, on)
  if ok then
    return r
  end
  VRFW.log("pre-match X jump: failed (" .. tostring(r) .. "): the graft uses the cover path")
  return 0
end

VRFW.on("hook:PrematchSecondEntrance", function(ev)
  if not jump_on then
    return nil
  end
  local st = Memory.read("u32", ev.regs.rsi + 0x20)
  VRFW.log(string.format("pre-match X jump: second entrance event not started (flow state %s -> 13)",
    st and tostring(st) or "?"))
  return { skip = true }
end)

VRFW.on("game_reset", function()
  VRFW.native.table_clear(COVER_TABLE)
  jump_on = false
end)
