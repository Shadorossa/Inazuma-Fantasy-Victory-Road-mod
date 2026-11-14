-- Furor > the timing of the "Furor phase active" entry banner.

Furor = Furor or {}
local clamp = VRFW.value.clamp   -- a config number with a default, kept inside its range

local RAW = VRFW.config("furor_banner", {})
local SETTINGS = {
  in_ms = clamp(RAW.in_seconds, 0.35, 0, 10) * 1000,
  hold_ms = clamp(RAW.hold_seconds, 2.0, 0, 60) * 1000,
  out_ms = clamp(RAW.out_seconds, 0.35, 0, 10) * 1000,
  slide_units = clamp(RAW.slide_units, 3000, 0, 20000),
  top_units = clamp(RAW.top_units, 40, -2000, 2000),
  height_units = clamp(RAW.height_units, 56, 1, 1000),
  enter = (RAW.enter_from == "right") and 1 or -1,
  exit = (RAW.exit_to == "left") and -1 or 1,
}

local started_at = nil

-- 0..1 eased (slow at both ends)
local function ease(t)
  if t <= 0 then return 0 end
  if t >= 1 then return 1 end
  return t * t * (3 - 2 * t)
end

VRFW.on("script:signal:Furor.gauge.phase", function(ev)
  started_at = VRFW.now_ms()
  return nil
end)
VRFW.on("match:start", function(ev) started_at = nil return nil end)
VRFW.on("match:end", function(ev) started_at = nil return nil end)

function Furor.Banner()
  local s = SETTINGS
  if started_at == nil then
    return false, 1, s.slide_units, s.top_units, s.height_units
  end
  local t = VRFW.now_ms() - started_at
  local offset
  if t < s.in_ms then
    offset = s.enter * (1 - ease(t / s.in_ms))
  elseif t < s.in_ms + s.hold_ms then
    offset = 0
  elseif t < s.in_ms + s.hold_ms + s.out_ms then
    offset = s.exit * ease((t - s.in_ms - s.hold_ms) / s.out_ms)
  else
    started_at = nil
    return false, 1, s.slide_units, s.top_units, s.height_units
  end
  return true, offset, s.slide_units, s.top_units, s.height_units
end

local HUD_RAW = VRFW.config("furor_hud", {})
local HUD_DEBUG = HUD_RAW.debug == true
function Furor.HudDebug()
  return HUD_DEBUG and 1 or 0
end

VRFW.log(string.format("furor banner: in %.2f s from the %s, hold %.2f s, out %.2f s to the %s, slide %d units",
  SETTINGS.in_ms / 1000, SETTINGS.enter < 0 and "left" or "right", SETTINGS.hold_ms / 1000, SETTINGS.out_ms / 1000,
  SETTINGS.exit < 0 and "left" or "right", SETTINGS.slide_units))
