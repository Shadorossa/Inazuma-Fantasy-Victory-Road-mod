-- Aura Reworked › banner trace (diagnostics): after each aura command the engine runs (event `match:aura:post`) a
-- window of WINDOW_FRAMES opens. Inside it every menu open / close and announce line is logged once:
--   «AuraOverhaul banner_trace aura #<n> cmd <4 words of the aura command>»
--   «AuraOverhaul banner_trace #<n> +<frames> frames menu open 0x<menu hash> param <p>»
-- The menu VMs ask CMND_AURAOVERHAUL_BANNER_TRACE (content\game\banner_trace.toml) and log their own layer calls.

AuraOverhaul = AuraOverhaul or {}
AuraOverhaul.BannerTrace = AuraOverhaul.BannerTrace or {}
local B = AuraOverhaul.BannerTrace

local info = VRFW.logger("AuraOverhaul banner_trace")
local WINDOW_FRAMES = 120   -- about 2 s of match time
local MAX_LINES = 40          -- lines per window
local U32, U64 = 4294967296, 18446744073709551616

local window = { n = 0, at = -1e12, lines = 0 }

-- the match frame counter (the gameplay clock); the last one seen outside a match
local last_frame = 0
local function now()
  local ok, f = pcall(VRFW.match.frame)
  if ok and type(f) == "number" then last_frame = f end
  return last_frame
end

local function u32_at(ptr)
  if ptr < 0x10000 then return nil end
  local ok, v = pcall(VRFW.memory.read, "u32", ptr)
  if ok and type(v) == "number" then return v % U32 end
  return nil
end

local function arg(ev, i)
  return (tonumber(ev.args and ev.args[i]) or 0) % U64
end

local function hex(v)
  if v == nil then return "?" end
  return string.format("0x%08X", v)
end

local function left_frames()
  local left = window.at + WINDOW_FRAMES - now()
  return left > 0 and left or 0
end

local function line(what)
  if left_frames() <= 0 or window.lines >= MAX_LINES then return end
  window.lines = window.lines + 1
  info(string.format("#%d +%d frames %s", window.n, math.floor(now() - window.at), what))
end

-- CMND_AURAOVERHAUL_BANNER_TRACE() -> frames left (0 = closed), window number
function B.Window()
  return math.floor(left_frames()), window.n
end

VRFW.on("match:aura:post", function(ev)
  window.n, window.at, window.lines = window.n + 1, now(), 0
  local p = arg(ev, 1)
  local words = {}
  for i = 0, 3 do words[#words + 1] = hex(u32_at(p + i * 4)) end
  info(string.format("aura #%d cmd %s", window.n, table.concat(words, " ")))
  return nil
end)

VRFW.on("menu:open:post", function(ev)
  if left_frames() > 0 then
    line(string.format("menu open %s param %d", hex(u32_at(arg(ev, 2))), arg(ev, 3) % U32))
  end
  return nil
end)

VRFW.on("menu:close:post", function(ev)
  if left_frames() > 0 then line("menu close " .. hex(arg(ev, 1) % U32)) end
  return nil
end)

VRFW.on("hud:announce:post", function(ev)
  if left_frames() > 0 then line("announce entry " .. hex(u32_at(arg(ev, 2)))) end
  return nil
end)
