-- The champions' celebration of a won competition (docs/framework/trophy.md): the game's own end of the Victory Road
-- final, the trophy lift ev72_00050 with the winning side's players in the match's stadium, then the photo scene
-- (victory_road_final_game_*_photo_menu), then the normal result menu and the mode's own flow.
-- Bit 24 of the match's rule word ([[g_gameRoot]+Game.RootMatch]+0) makes the full-time state ResultEventState go to
-- TournamentFinalGameEnd (soccer state 0x1C) instead of the result menu. ResultEventState reads the bit at its last
-- step; it is written here when a mod sends the signal vrfw.trophy from its vrfw.match_result handler (before the
-- result music and that last step), so the Victory Road mode is never started and the bit lives in this match only.
-- Only on a won match: the scene casts the winning side, so it is always the player's team.
-- Required by scripts\match_exp.lua; the finished match's result: lib\match_result.lua.
local Trophy = {}
local MatchResults = require "lib/match_result"

require "VRFW/lib/basics"
local info, warn = VRFW.logger("trophy")

-- the rule word's tournament-final end (ResultEventState v7.2.1 0x1452A20 step 0x14: next state 0x1C when set)
local RULE_TOURNAMENT_FINAL_END = 0x1000000

-- game_state keys: the text key of the name the photo's tournament plate shows, set by the sender before the signal
-- (consumed); the name used when the sender gives none (set by a mod); a celebration is set for the match being
-- finished (true / false) and the name its plate shows
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

-- the finished match wins a competition: the celebration plays after its full time when the player won the match.
-- `name` = the text key of the competition's name on the photo's plate ("" = the plate keeps the game's text).
-- true when the celebration is set.
function Trophy.play(name, result)
  if type(result) ~= "table" or result.outcome ~= "win" then
    info(string.format("%s decided without a won match (%s): no celebration", name ~= "" and name or "a competition",
      type(result) == "table" and tostring(result.outcome) or "no result"))
    return false
  end
  local mi = match_info()
  local ok, old = pcall(VRFW.mem.read, "u32", mi or 0)
  if not mi or not ok or type(old) ~= "number" then
    warn("competition won, but the match's rule word is not readable: no celebration")
    return false
  end
  local new = bit32.bor(old, RULE_TOURNAMENT_FINAL_END)
  if new ~= old and not pcall(VRFW.mem.write, "u32", mi, new) then
    warn(string.format("competition won, but the rule word 0x%08X was not written: no celebration", old))
    return false
  end
  pcall(VRFW.state.set, SHOWN_KEY, name)
  pcall(VRFW.state.set, ACTIVE_KEY, true)
  info(string.format("%s won %d-%d: rule word 0x%08X -> 0x%08X (trophy lift, photo, then the result screen)",
    name ~= "" and name or "competition", VRFW.value.int(result.score_for, 0), VRFW.value.int(result.score_against, 0),
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

-- CMND_VRFW_TROPHY_INFO -> table { active, name (the text key of the competition's name, "" = none), name_id (its
-- crc32, as CMND_TEXT_GET takes it; 0 = none) }: the celebration of the match that just ended
function Trophy.Info()
  local ok, active = pcall(VRFW.state.get, ACTIVE_KEY)
  if not ok or active ~= true then
    return { active = false }
  end
  local name = text_at(SHOWN_KEY)
  return { active = true, name = name, name_id = name ~= "" and VRFW.crc32(name) or 0 }
end

return Trophy
