
local SCREEN = "betterui_power_counter_menu"

local KIND_SPECIAL_MOVE = 5
local KIND_POWER_ACTION = 6
local RESULT_BLOCK_FROM_RBP = 0x30   -- the result block is at rbp - 0x30 at the hook site

local LABEL_DRIBBLE = 1
local LABEL_DEFENSE = 2
local LABEL_POWER_CHARGE = 3
local LABEL_POWER_BLOCK = 4

local counters = nil                 -- the running duel's counters; nil = no duel with counters
local duel_running = false
local screen_open = false
local close_next_tick = false

local function read_struct(name, address)
  local value = VRFW.memory.read_struct(name, address)
  local ok = value ~= nil
  if ok and type(value) == "table" then
    return value
  end
  return nil
end

local function label_of(is_offense, power_action)
  if is_offense then
    return power_action and LABEL_POWER_CHARGE or LABEL_DRIBBLE
  end
  return power_action and LABEL_POWER_BLOCK or LABEL_DEFENSE
end

-- The only read of the joint option; the shot readout graft asks through CMND_BETTERUI_DUEL_AND_SHOT_COUNTERS_ON.
function BetterUI.DuelAndShotCountersOn()
  return VRFW.option("duel_and_shot_counters") == 1
end

local function close_screen()
  close_next_tick = false
  if screen_open then
    screen_open = false
    local ok, done, why = pcall(VRFW.ui.close_menu, SCREEN, false)
    if not ok or not done then
      VRFW.log("power counter: close failed: " .. tostring(ok and why or done))
    end
  end
  return nil
end

-- a cut-in of the duel starts
local function on_cutin_start()
  close_next_tick = false
  if not duel_running or screen_open then
    return nil
  end
  local ok, done, why = pcall(VRFW.ui.open_menu, SCREEN)
  if ok and done then
    screen_open = true
    VRFW.log(string.format("power counter shown: left %d label %d move %08X, right %d label %d move %08X",
      counters.left_power, counters.left_label, counters.left_move, counters.right_power, counters.right_label,
      counters.right_move))
  else
    VRFW.log("power counter: open failed: " .. tostring(ok and why or done))
  end
  return nil
end

VRFW.on("hook:DuelClashResult", function(ev)
  local regs = ev and ev.regs
  if type(regs) ~= "table" or type(regs.rbp) ~= "number" or type(regs.r13) ~= "number" then
    return nil
  end
  local result = read_struct("ClashResultBlock", regs.rbp - RESULT_BLOCK_FROM_RBP)
  if result == nil or (result.kind ~= KIND_SPECIAL_MOVE and result.kind ~= KIND_POWER_ACTION) then
    return nil
  end
  if result.winner_side > 1 or result.winner_power <= 0 then
    return nil
  end
  local duel = read_struct("FocusDuel", regs.r13)
  if duel == nil or duel.offense_side > 1 then
    return nil
  end
  duel_running = false
  close_screen()
  local power = {}
  power[result.winner_side] = result.winner_power
  power[1 - result.winner_side] = math.max(result.loser_power, 0)
  local power_action = { [0] = duel.power_action_side0 ~= 0, [1] = duel.power_action_side1 ~= 0 }
  local move = { [0] = duel.move_side0, [1] = duel.move_side1 }
  local chara = { [0] = duel.chara_side0, [1] = duel.chara_side1 }
  -- the side this PC shows on the left (its own side in a synced match); none = the offense
  local left = VRFW.match.viewer_team() or duel.offense_side
  local right = 1 - left
  counters = {
    left_power = power[left],
    left_label = label_of(left == duel.offense_side, power_action[left]),
    right_power = power[right],
    right_label = label_of(right == duel.offense_side, power_action[right]),
    left_move = power_action[left] and 0 or move[left],
    right_move = power_action[right] and 0 or move[right],
    left_chara = chara[left],
    right_chara = chara[right],
  }
  duel_running = BetterUI.DuelAndShotCountersOn()
  return nil
end)

local function end_duel()
  duel_running = false
  close_screen()
  return nil
end

VRFW.on("match:cutin_start", on_cutin_start)

VRFW.on("match:cutin_end", function()
  close_next_tick = screen_open
  return nil
end)

VRFW.on("frame:tick", function()
  if close_next_tick then
    close_screen()
  end
  return nil
end)

-- the result is applied (after the cut-ins) or the match is over
VRFW.on("match:duel_won", end_duel)
VRFW.on("match:end", end_duel)

-- the last keeper battle: the keeper, his move, the shooter and the shot (the shot readout's critical tags)
local keeper_battle = nil

VRFW.on("match:keeper_duel", function(ev)
  local keeper, shooter = ev.actor and ev.actor.handle, ev.rival and ev.rival.handle
  if keeper == nil or shooter == nil then
    return nil
  end
  keeper_battle = { keeper = keeper, keeper_move = ev.skill or 0, shooter = shooter, shot = ev.rival.skill or 0 }
  return nil
end)

-- CMND_BETTERUI_SHOT_MOVES(shooter, keeper) -> the shot's move, the keeper's move (0 = none or another battle)
function BetterUI.ShotMoves(shooter, keeper)
  local b = keeper_battle
  if b == nil or b.shooter ~= shooter or b.keeper ~= keeper then
    return 0, 0
  end
  return b.shot, b.keeper_move
end

function BetterUI.DuelReadout()
  if counters == nil then
    return 0, 0, 0, 0, 0, 0, 0, 0
  end
  return counters.left_power, counters.left_label, counters.right_power, counters.right_label, counters.left_move,
    counters.right_move, counters.left_chara, counters.right_chara
end
