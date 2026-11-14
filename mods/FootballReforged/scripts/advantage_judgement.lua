local Memory = VRFW.memory
-- The game's own Advantage Judgement replaces every penalty shoot-out, in any mode, while this mod is on.
local MatchResults = VRFW.match.results
local info, warn = VRFW.logger("advantage_judgement")
local int = function(v) return VRFW.value.integer(v, 0) end

local SHOOTOUT_HALF, MATCH_OVER = 5, 6
local JUDGEMENT_BIT = 4
local JUDGEMENT_MENU = VRFW.crc32("soccer_advance_judge_menu")

local armed = false        -- this match skipped its shoot-out
local menu_seen = false

local function set_judgement_bit()
  local match = VRFW.game.global("football_reforged_match_info")
  if match == nil then return false end
  local ok, done = pcall(function()
    local rules = VRFW.memory.struct("FootballReforgedMatchRules", match)
    local bits = int(rules.rule_bits)
    if math.floor(bits / JUDGEMENT_BIT) % 2 == 0 then rules.rule_bits = bits + JUDGEMENT_BIT end
    return true
  end)
  return ok and done == true
end

VRFW.on("match:start", function()
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
  local hash = Memory.read("u32", ev.args and ev.args[2])
  if hash == JUDGEMENT_MENU then
    menu_seen = true
    info("soccer_advance_judge_menu opened")
  end
  return nil
end)

VRFW.on("script:signal:vrfw.match_result", function()
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
