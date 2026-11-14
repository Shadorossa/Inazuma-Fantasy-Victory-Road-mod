ChronicleDeluxe = ChronicleDeluxe or {}

local STATE_KEY = "universe_orb."
local MIN_PULLS, MAX_PULLS = 1, 99

local pulls_warned = false

-- config.toml [universe_orbs] pulls_for_rate_up (its only value), or nil with one warning when it is missing or not a number: no rate-up orb
local function pulls_for_rate_up()
  local pulls = VRFW.config("universe_orbs.pulls_for_rate_up", nil, MIN_PULLS, MAX_PULLS)
  if pulls == nil and not pulls_warned then
    pulls_warned = true
    VRFW.warn("config: config.toml universe_orbs.pulls_for_rate_up is missing or not a number: no rate-up orb")
  end
  return pulls
end

local function key_of(sign)
  return STATE_KEY .. string.format("%.0f", sign)
end

-- one constellation: normal pulls since the last rate-up, the rate-up orb (0 = none), the orb of the rate-up pull in progress
local function read(sign)
  local saved = VRFW.save.get(key_of(sign), nil)
  if type(saved) ~= "table" then
    return { count = 0, pending = 0, active = 0 }
  end
  return { count = tonumber(saved.count) or 0, pending = tonumber(saved.pending) or 0, active = tonumber(saved.active) or 0 }
end

function ChronicleDeluxe.UniverseOrbState(sign)
  local state = read(sign)
  return { state.count, state.pending, state.active }
end

-- the confirmed pull of orb `star`: 1 when it is the rate-up orb, else 0
function ChronicleDeluxe.UniverseOrbPull(sign, star)
  local state = read(sign)
  local rate_up = state.pending == star
  if rate_up then
    state.count, state.pending, state.active = 0, 0, star
  else
    state.active = 0
    state.count = state.count + 1
    local pulls = pulls_for_rate_up()
    if pulls ~= nil and state.count >= pulls then
      state.count, state.pending = 0, star
    end
  end
  VRFW.save.set(key_of(sign), state)
  VRFW.save.commit()
  return rate_up and 1 or 0
end
