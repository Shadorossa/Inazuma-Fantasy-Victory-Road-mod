-- The game's own Advantage Judgement replaces every penalty shoot-out, in any mode, while this mod is on.
-- A shoot-out only exists as a period the rule engine adds: its answer to the game's NextHalf is half 5 when a level
-- match ends under a rulebook with `penalties = true`. This script takes that answer (match:half_end post: the scripts
-- subscribe after the rule engine) and gives the game "match over" with bit 2 of the match's rule bits on. From there
-- the game does the rest: its end-of-match flow opens soccer_advance_judge_menu on level goals with that bit, and its
-- result function gives the win from the points (shots + focus wins + possession % x 0.1), so the result screen and
-- vrfw.match_result name the winner of the level score. Extra time is untouched. An exact tie in points stays a draw:
-- each mode decides what a draw means. Details: docs/game/mechanics/advantage-judgement.md.
-- Declarations: content\game\advantage_judgement.toml.

local Basics = require "VRFW/lib/basics"
local MatchResults = require "VRFW/lib/match_result"
local info, warn = VRFW.logger("advantage_judgement")
local int = function(v) return Basics.value.int(v, 0) end

-- the engine's half byte: 5 the shoot-out period, 6 the match is over
local SHOOTOUT_HALF, MATCH_OVER = 5, 6
local JUDGEMENT_BIT = 4
local JUDGEMENT_MENU = VRFW.crc32("soccer_advance_judge_menu")

local armed = false        -- this match skipped its shoot-out
local menu_seen = false

-- turns the rule bit on; false when the match info cannot be written (the shoot-out then stays)
local function set_judgement_bit()
  local ok_info, match = pcall(VRFW.game.football_reforged_match_info)
  if not ok_info or type(match) ~= "number" or match < 0x10000 then return false end
  local ok, done = pcall(function()
    local rules = VRFW.mem.struct("FootballReforgedMatchRules", match)
    local bits = int(rules.rule_bits)
    if math.floor(bits / JUDGEMENT_BIT) % 2 == 0 then rules.rule_bits = bits + JUDGEMENT_BIT end
    return true
  end)
  return ok and done == true
end

VRFW.on("match_start", function()
  armed, menu_seen = false, false
  return nil
end)

VRFW.on("match:half_end:post", function(ev)
  if type(ev.ret) ~= "number" or ev.ret % 256 ~= SHOOTOUT_HALF then return nil end
  if not set_judgement_bit() then
    warn("the match's rule bits cannot be written: the penalty shoot-out stays")
    return nil
  end
  if not armed then
    armed = true
    info(string.format("level at the end of half %d: Advantage Judgement instead of the penalty shoot-out", int(ev.args and ev.args[1])))
  end
  return { ret = MATCH_OVER }
end)

VRFW.on("menu:open:post", function(ev)
  if not armed or menu_seen then return nil end
  local ok, hash = pcall(VRFW.mem.read, "u32", ev.args and ev.args[2])
  if ok and hash == JUDGEMENT_MENU then
    menu_seen = true
    info("soccer_advance_judge_menu opened")
  end
  return nil
end)

VRFW.on("signal:vrfw.match_result", function()
  if not armed then return nil end
  armed = false
  local r = MatchResults.last()
  if type(r) ~= "table" then return nil end
  local line = string.format("judged result: %s for the player at %d-%d", tostring(r.outcome), int(r.score_for), int(r.score_against))
  if r.outcome == "draw" then
    warn(line .. ": exact tie in points, the mode decides what a draw means")
  else
    info(line)
  end
  return nil
end)
