-- BetterUI › duel power counter: the totals the game compares in a special-move / power-action duel, shown during the
-- cut-ins on the shot zone's plates (content\game\duel_readout.toml). The mid hook DuelClashResult runs when the resolver
-- posts its result, before the performance. The screen betterui_power_counter_menu opens when a cut-in of that duel starts
-- and closes when the cut-in ends, never on the clash banner. A duel with no cut-in shows nothing, as in retail. The
-- hook also keeps each side's chara handle: the screen draws that player's 3D bust on the plate.
-- Nothing runs at load but the handler registration.

local SCREEN = "betterui_power_counter_menu"
local OPTION = "duel_readout"

local KIND_SPECIAL_MOVE = 5
local KIND_POWER_ACTION = 6
local RESULT_BLOCK_FROM_RBP = 0x30   -- the result block is at rbp - 0x30 at the hook site

local LABEL_DRIBBLE = 1
local LABEL_DEFENSE = 2
local LABEL_POWER_CHARGE = 3
local LABEL_POWER_BLOCK = 4

local counters = nil                 -- the running duel's counters; nil = no duel with counters
local duel_running = false           -- the result is known and not applied yet: its cut-ins open the screen
local screen_open = false
local close_next_tick = false        -- a cut-in ended; the next one may start in the same frame and keep the screen

local function read_struct(name, address)
  local ok, value = pcall(VRFW.mem.read_struct, name, address)
  if ok and type(value) == "table" then
    return value
  end
  return nil
end

-- the side the player controls, or nil (no player side: a CPU match, the data not readable)
local function user_side()
  local ok, match = pcall(VRFW.game.DuelMatchData)
  if not ok or type(match) ~= "number" or match == 0 then
    return nil
  end
  local sides = read_struct("DuelMatchSides", match)
  if sides == nil or sides.user_side > 1 then
    return nil
  end
  return sides.user_side
end

local function label_of(is_offense, power_action)
  if is_offense then
    return power_action and LABEL_POWER_CHARGE or LABEL_DRIBBLE
  end
  return power_action and LABEL_POWER_BLOCK or LABEL_DEFENSE
end

local function option_on()
  local ok, value = pcall(VRFW.option, OPTION)
  return not ok or (value ~= 0 and value ~= false)
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
  -- a side without a command has power 0 in the game's comparison: its plate stays hidden
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
  local left = user_side() or duel.offense_side
  local right = 1 - left
  counters = {
    left_power = power[left],
    left_label = label_of(left == duel.offense_side, power_action[left]),
    right_power = power[right],
    right_label = label_of(right == duel.offense_side, power_action[right]),
    -- a power charge / power block is not a move: its plate keeps its label
    left_move = power_action[left] and 0 or move[left],
    right_move = power_action[right] and 0 or move[right],
    left_chara = chara[left],
    right_chara = chara[right],
  }
  duel_running = option_on()
  return nil
end)

local function end_duel()
  duel_running = false
  close_screen()
  return nil
end

VRFW.on("cutin_start", on_cutin_start)

VRFW.on("cutin_end", function()
  close_next_tick = screen_open
  return nil
end)

VRFW.on("tick", function()
  if close_next_tick then
    close_screen()
  end
  return nil
end)

-- the result is applied (after the cut-ins) or the match is over
VRFW.on("duel_won", end_duel)
VRFW.on("match_end", end_duel)

-- CMND_BETTERUI_DUEL_READOUT() -> left power, left label, right power, right label, left move, right move, left chara,
-- right chara; asked once by the screen when it opens. Left = the player's side, right = the rival's; a power of 0 = that
-- side has no plate; a move of 0 = the plate shows its label; a chara of 0 = that plate has no bust.
function BetterUI.DuelReadout()
  if counters == nil then
    return 0, 0, 0, 0, 0, 0, 0, 0
  end
  return counters.left_power, counters.left_label, counters.right_power, counters.right_label, counters.left_move,
    counters.right_move, counters.left_chara, counters.right_chara
end

local PLATE_LAYOUT_KEYS = { "left_number_x", "right_number_x", "label_room", "bust_settle_frames" }

-- CMND_BETTERUI_DUEL_PLATE_LAYOUT() -> the tunables of config.toml [duel_counter], or nil when one is missing.
function BetterUI.DuelPlateLayout()
  local layout = {}
  for _, key in ipairs(PLATE_LAYOUT_KEYS) do
    local value = VRFW.files.config("duel_counter." .. key)
    if type(value) ~= "number" then
      return nil
    end
    layout[key] = value
  end
  return layout
end
