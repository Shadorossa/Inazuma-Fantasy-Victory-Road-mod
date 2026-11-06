-- Legendary AI › the foul chance of the rival's power charges / power blocks and aggressive sprint charges.
-- Declarations: content\game\legendary_ai.toml (hook LegendaryAI.FoulRate on the game's foul chance). Setting:
-- config.toml [fouls] rival_power_action_foul_rate (the game: focusFoulBaseRatePowerAction 0.15) and
-- rival_dash_foul_scale (a factor on the game's aggressive sprint chance). Every other section of config.toml is read
-- by the content files (the core fills their config references); this script logs what it holds at load.
-- A duel foul of a rival player (not the user's team) whose duel ended in a power charge / power block gets that chance
-- instead of the game's; a rival's aggressive sprint charge gets the game's chance x rival_dash_foul_scale; an immune
-- player (chance 0) stays immune. Your own actions keep the game's chance.

LegendaryAI = LegendaryAI or {}

local Basics = require "VRFW/lib/basics"
local clamp = Basics.value.clamp   -- a config number with a default, kept inside its range

local function config_section(name)
  local ok, t = pcall(VRFW.files.config, name)
  if ok and type(t) == "table" then return t end
  return {}
end

local RAW = config_section("fouls")
local SETTINGS = {
  rival_power_action_foul_rate = clamp(RAW.rival_power_action_foul_rate, 0.05, 0, 1),
  rival_dash_foul_scale = clamp(RAW.rival_dash_foul_scale, 0.125, 0, 1),
}
LegendaryAI.settings = SETTINGS

-- the level of the option row «Difficulty» (config.toml [difficulty]; the AI rules' values: content\rules\ai\legendary.toml):
-- the foul chances move with it, read at each match start
local DIFFICULTY = config_section("difficulty")
local TOP = {}
for key, value in pairs(SETTINGS) do TOP[key] = value end
local function apply_difficulty()
  local factors, names = DIFFICULTY.factors or {}, DIFFICULTY.names or {}
  local value = tonumber(VRFW.option("difficulty"))
  local level = value and clamp(value + 1, #factors, 1, #factors) or #factors
  local factor = factors[level] or 1
  local start = (DIFFICULTY.from or {}).fouls or {}
  for key, top in pairs(TOP) do
    local from = start[key] or top
    SETTINGS[key] = factor >= 1 and top or from + factor * (top - from)
  end
  VRFW.log(string.format("legendary difficulty: %s (factor %.2f)", tostring(names[level]), factor))
end

-- the values of config.toml (with the loader's [mods.LegendaryAI] over them), one count per section
local SECTIONS = { "fouls", "errors", "focus_duel", "press", "offside_trap", "low_block", "box_line",
  "shot_chain_read", "pass_read", "through_ball_cover", "behind_line", "shape", "man_marking", "counter", "passing", "shoot_zone", "moves", "stamina", "team", "furor",
  "retail_ai", "situations" }
local function count_values(t)
  local n = 0
  for _, v in pairs(t) do
    if type(v) == "table" then n = n + count_values(v) else n = n + 1 end
  end
  return n
end
local total, parts = 0, {}
for _, name in ipairs(SECTIONS) do
  local n = count_values(config_section(name))
  total = total + n
  parts[#parts + 1] = name .. " " .. n
end
VRFW.log(string.format("legendary_ai: config loaded: %d values (%s); rival foul chance %.3f, sprint charge x%.3f, duel read error %s, offside miss %s",
  total, table.concat(parts, ", "), SETTINGS.rival_power_action_foul_rate, SETTINGS.rival_dash_foul_scale,
  tostring(config_section("errors").focus_duel_read_error), tostring(config_section("errors").offside_trap_miss)))

-- game layout: the actor table through the framework (VRFW/lib/actors); the match
-- info, the focus manager and the foul request as structs of content\game\legendary_ai.toml
local Actors = require "VRFW/lib/actors"
local DUEL_KIND_POWER = 6
local FOUL_KIND_DUEL = 1
local FOUL_KIND_SPRINT = 3

-- one field of a [[VRFW.Struct]] of content\game\legendary_ai.toml at `at`; nil when not readable
local function struct_field(struct, at, name)
  if not at or at < 0x10000 then return nil end
  local ok, s = pcall(VRFW.mem.struct, struct, at)
  if not ok then return nil end
  local ok_value, v = pcall(function() return s[name] end)
  if ok_value then return v end
  return nil
end

local function game_global(name)
  local ok, p = pcall(VRFW.game[name])
  if ok and type(p) == "number" and p >= 0x10000 then return p end
  return nil
end

local function team_of(handle)
  local a = Actors.of(handle)
  return a and a.team or nil
end

VRFW.on("hook:LegendaryAI.FoulRate:post", function(ev)
  local kind = struct_field("LegendaryFoulRequest", ev.args[1], "kind")
  if kind == FOUL_KIND_DUEL then
    local duel = game_global("legendary_duel")
    if not duel or struct_field("LegendaryDuel", duel, "result_kind") ~= DUEL_KIND_POWER then return nil end
  elseif kind ~= FOUL_KIND_SPRINT then
    return nil
  end
  local match = game_global("legendary_ai_match_info")
  local user = match and struct_field("LegendaryAIMatchInfo", match, "user_team")
  if user ~= 0 and user ~= 1 then return nil end
  local offender = struct_field("LegendaryFoulRequest", ev.args[1], "offender")
  local team = team_of(offender)
  if team == nil or team == user then return nil end
  local rate, what = SETTINGS.rival_power_action_foul_rate, "power action"
  if kind == FOUL_KIND_SPRINT then rate, what = (ev.ret or 0) * SETTINGS.rival_dash_foul_scale, "sprint charge" end
  VRFW.log(string.format("legendary_ai: rival %s foul chance 0x%08X: %.3f -> %.3f", what, offender, ev.ret or 0, rate))
  return { ret = rate }
end)

-- Furor (soft companion, content\rules\furor.toml): Furor's signal Furor.gauge.start starts the phase of its actor's
-- team (the same function as the furor button; the gauge check stays Furor's), so each start goes out with a rival player.

-- the user's team (0 / 1) from the match info, nil when unknown
local function user_team()
  local match = game_global("legendary_ai_match_info")
  local user = match and struct_field("LegendaryAIMatchInfo", match, "user_team")
  if user == 0 or user == 1 then return user end
  return nil
end

-- the last ball carrier (hook bus ball_owner; a loose ball keeps the last one)
local carrier = nil
VRFW.on("possession", function(ev)
  local a = ev.actor
  if a and a.handle and a.handle ~= 0 and (a.team == 0 or a.team == 1) then carrier = { handle = a.handle, team = a.team } end
  return nil
end)
VRFW.on("match_start", function(ev)
  carrier = nil
  apply_difficulty()
  return nil
end)
VRFW.on("match_end", function(ev) carrier = nil return nil end)

-- its shoot zone started (or its gauge filled during one) with a full gauge: the phase starts with its carrier
VRFW.on("signal:LegendaryAI.furor_zone", function(ev)
  local user = user_team()
  if user == nil or carrier == nil or carrier.team ~= 1 - user then return nil end
  VRFW.signal("Furor.gauge.start", carrier.handle)
  VRFW.log(string.format("legendary_ai: furor zone start for team %d (carrier 0x%08X)", carrier.team, carrier.handle))
  return nil
end)

-- your carrier got the ball near the rival's goal while the rival's gauge is full: one of the rival's players starts it
VRFW.on("signal:LegendaryAI.furor_defend", function(ev)
  local user = ev.actor and ev.actor.team
  if user ~= 0 and user ~= 1 then return nil end
  for _, a in ipairs(Actors.list()) do
    if a.team == 1 - user then
      VRFW.signal("Furor.gauge.start", a.handle)
      VRFW.log(string.format("legendary_ai: furor defence start for team %d (via 0x%08X)", a.team, a.handle))
      return nil
    end
  end
  return nil
end)
