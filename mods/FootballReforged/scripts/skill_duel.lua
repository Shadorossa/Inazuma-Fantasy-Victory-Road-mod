
FootballReforged = FootballReforged or {}
FootballReforged.SkillDuel = FootballReforged.SkillDuel or {}
local M = FootballReforged.SkillDuel
local info = VRFW.logger("skill_duel")

local clamp = VRFW.value.clamp   -- a config number with a default, kept inside its range

local RAW = VRFW.config("skill_duel", {})
local SETTINGS = {
  reach = {
    stat_weight = clamp(RAW.stat_weight, 1.0, 0, 1),
    reach_min_m = clamp(RAW.reach_min_m, 1.8, 0.1, 20),
    reach_max_m = clamp(RAW.reach_max_m, 3.6, 0.1, 20),
    hand_scale_min = clamp(RAW.hand_scale_min, 1.0, 0.1, 5),
    hand_scale_max = clamp(RAW.hand_scale_max, 1.4, 0.1, 5),
  },
  contact = {
    slip_per_point = clamp(RAW.contact_slip_per_point, 0.2, 0, 100),
    slip_max_percent = clamp(RAW.contact_slip_max_percent, 0, 0, 100),
  },
  log = RAW.log ~= false,
}
if SETTINGS.reach.reach_max_m < SETTINGS.reach.reach_min_m then SETTINGS.reach.reach_max_m = SETTINGS.reach.reach_min_m end
if SETTINGS.reach.hand_scale_max < SETTINGS.reach.hand_scale_min then SETTINGS.reach.hand_scale_max = SETTINGS.reach.hand_scale_min end
M.settings = SETTINGS

local rule_set = false

local function set_rule()
  if rule_set then return end
  if not (VRFW.duel and VRFW.duel.line_rule) then
    info("VRFW.duel.line_rule is missing (VRFW too old): the game's duel stays")
    rule_set = true
    return
  end
  local line, why = VRFW.duel.line_rule(SETTINGS)
  rule_set = true
  if line then
    info("focus line rule:", line)
  else
    info("focus line rule refused:", why)
  end
end

VRFW.on("match_start", function()
  set_rule()
  return nil
end)
