local Memory = VRFW.memory
local OPTION = "match_clock"
local RATE_AT = 0x10

local info = VRFW.logger("match_clock")

local function config_rate()
  local v = VRFW.config("match_clock.game_rate")
  if type(v) == "number" and v > 0 then
    return v
  end
  return 14.1
end
local GAME_RATE = config_rate()

local function chosen()
  local ok, values = pcall(VRFW.options.values)
  local v = ok and type(values) == "table" and tonumber(values[OPTION]) or 0
  return (v and v > 0) and v or 0
end

local last = nil

local function apply(why)
  local s = chosen()
  if s <= 0 then
    return
  end
  local mi = VRFW.game.global("betterqol_match_info")
  if mi == nil then
    return
  end
  local cur = Memory.read("f32", mi + RATE_AT)
  if type(cur) ~= "number" or cur <= 0 then
    return
  end
  if last ~= nil and last.info == mi and math.abs(cur - last.written) < 1e-4 then
    return   -- ours already
  end
  local want = cur * (60 / s) / GAME_RATE
  if not VRFW.memory.write("f32", mi + RATE_AT, want) then
    return
  end
  local back = Memory.read("f32", mi + RATE_AT)
  last = { info = mi, written = (type(back) == "number") and back or want }
  info(string.format("%s: clock rate %.4f -> %.4f game s per real s (%.1f real s per game minute at the normal speed; game rate %.2f)",
    why, cur, last.written, s, GAME_RATE))
end

VRFW.on("match:start", function()
  last = nil
  pcall(apply, "match start")
end)

-- the game may reset the rate at a kick-off
VRFW.on("match:state_enter:9", function()
  pcall(apply, "kick-off")
end)

info(string.format("loaded: %s (game rate %.2f)", chosen() > 0 and string.format("%.1f real s per game minute", chosen()) or "Original (the game's rate)", GAME_RATE))
