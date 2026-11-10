local Trophy = {}
local MatchResults = VRFW.match.results

local info, warn = VRFW.logger("trophy")

-- the rule word's tournament-final end (ResultEventState v7.2.1 0x1452A20 step 0x14: next state 0x1C when set)
local RULE_TOURNAMENT_FINAL_END = 0x1000000

local NAME_KEY, DEFAULT_NAME_KEY = "vrfw.trophy.name", "vrfw.trophy.default_name"
local ACTIVE_KEY, SHOWN_KEY = "vrfw.trophy.active", "vrfw.trophy.shown"

local function text_at(key)
  local ok, v = pcall(VRFW.state.get, key)
  if ok and type(v) == "string" then
    return v
  end
  return ""
end

local function match_info()
  local ok, p = pcall(VRFW.game.MatchExpInfo)
  if ok and type(p) == "number" and p >= 0x10000 then
    return p
  end
  return nil
end

--- the finished match wins a competition: the celebration plays after its full time when the player won the match.
function Trophy.play(name, result)
  if type(result) ~= "table" or result.outcome ~= "win" then
    info(string.format("%s decided without a won match (%s): no celebration", name ~= "" and name or "a competition",
      type(result) == "table" and tostring(result.outcome) or "no result"))
    return false
  end
  local mi = match_info()
  local old = VRFW.memory.read("u32", mi or 0)
  local ok = old ~= nil
  if not mi or not ok or type(old) ~= "number" then
    warn("competition won, but the match's rule word is not readable: no celebration")
    return false
  end
  local new = bit32.bor(old, RULE_TOURNAMENT_FINAL_END)
  if new ~= old and not VRFW.memory.write("u32", mi, new) then
    warn(string.format("competition won, but the rule word 0x%08X was not written: no celebration", old))
    return false
  end
  pcall(VRFW.state.set, SHOWN_KEY, name)
  pcall(VRFW.state.set, ACTIVE_KEY, true)
  info(string.format("%s won %d-%d: rule word 0x%08X -> 0x%08X (trophy lift, photo, then the result screen)",
    name ~= "" and name or "competition", VRFW.value.integer(result.score_for, 0), VRFW.value.integer(result.score_against, 0),
    old, new))
  return true
end

local function clear()
  local ok, active = pcall(VRFW.state.get, ACTIVE_KEY)
  if ok and active == true then
    pcall(VRFW.state.set, ACTIVE_KEY, false)
    pcall(VRFW.state.set, SHOWN_KEY, "")
  end
  return nil
end

VRFW.on("match_start", clear)
VRFW.on("game_reset", clear)

-- a mod's competition won by the finished match (that mod's own rule decided it, from vrfw.match_result)
VRFW.on("signal:vrfw.trophy", function()
  local name = text_at(NAME_KEY)
  if name ~= "" then
    pcall(VRFW.state.set, NAME_KEY, "")
  else
    name = text_at(DEFAULT_NAME_KEY)
  end
  Trophy.play(name, MatchResults.last())
  return nil
end)

--- The trophy shown now: { active, name, name_id } ({ active = false } when none).
function Trophy.details()
  local ok, active = pcall(VRFW.state.get, ACTIVE_KEY)
  if not ok or active ~= true then
    return { active = false }
  end
  local name = text_at(SHOWN_KEY)
  return { active = true, name = name, name_id = name ~= "" and VRFW.crc32(name) or 0 }
end

return Trophy
