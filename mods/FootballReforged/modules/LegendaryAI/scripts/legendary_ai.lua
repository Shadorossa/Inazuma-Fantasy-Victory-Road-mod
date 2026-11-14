-- Legendary AI › the foul chance of the rival's power charges / power blocks and aggressive sprint charges.

LegendaryAI = LegendaryAI or {}
local clamp = VRFW.value.clamp   -- a config number with a default, kept inside its range

local RAW = VRFW.config("fouls", {})
local SETTINGS = {
  rival_power_action_foul_rate = clamp(RAW.rival_power_action_foul_rate, 0.05, 0, 1),
  rival_dash_foul_scale = clamp(RAW.rival_dash_foul_scale, 0.125, 0, 1),
}
LegendaryAI.settings = SETTINGS

local DIFFICULTY = VRFW.config("difficulty", {})
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
  local n = count_values(VRFW.config(name, {}))
  total = total + n
  parts[#parts + 1] = name .. " " .. n
end
VRFW.log(string.format("legendary_ai: config loaded: %d values (%s); rival foul chance %.3f, sprint charge x%.3f, duel read error %s, offside miss %s",
  total, table.concat(parts, ", "), SETTINGS.rival_power_action_foul_rate, SETTINGS.rival_dash_foul_scale,
  tostring(VRFW.config("errors", {}).focus_duel_read_error), tostring(VRFW.config("errors", {}).offside_trap_miss)))

local Actors = VRFW.players
local DUEL_KIND_POWER = 6
local FOUL_KIND_DUEL = 1
local FOUL_KIND_SPRINT = 3

local Memory = VRFW.memory

local function struct_field(struct, at, name)
  local view = Memory.struct(struct, at)
  return view and view[name]
end

local game_global = VRFW.game.global

local function team_of(handle)
  local a = Actors.of(handle)
  return a and a.team or nil
end

VRFW.on("hook:LegendaryAI.FoulRate:post", function(ev)
  local kind = struct_field("LegendaryFoulRequest", ev.args[1], "Kind")
  if kind == FOUL_KIND_DUEL then
    local duel = game_global("legendary_duel")
    if not duel or struct_field("LegendaryDuel", duel, "ResultKind") ~= DUEL_KIND_POWER then return nil end
  elseif kind ~= FOUL_KIND_SPRINT then
    return nil
  end
  local match = game_global("legendary_ai_match_info")
  local user = match and struct_field("LegendaryAIMatchInfo", match, "UserTeam")
  if user ~= 0 and user ~= 1 then return nil end
  local offender = struct_field("LegendaryFoulRequest", ev.args[1], "Offender")
  local team = team_of(offender)
  if team == nil or VRFW.ai.human(team) then return nil end
  local rate, what = SETTINGS.rival_power_action_foul_rate, "power action"
  if kind == FOUL_KIND_SPRINT then rate, what = (ev.ret or 0) * SETTINGS.rival_dash_foul_scale, "sprint charge" end
  VRFW.log(string.format("legendary_ai: rival %s foul chance 0x%08X: %.3f -> %.3f", what, offender, ev.ret or 0, rate))
  return { ret = rate }
end)

-- the user's team (0 / 1) from the match info, nil when unknown
local function user_team()
  local match = game_global("legendary_ai_match_info")
  local user = match and struct_field("LegendaryAIMatchInfo", match, "UserTeam")
  if user == 0 or user == 1 then return user end
  return nil
end

local carrier = nil
VRFW.on("match:possession", function(ev)
  local a = ev.actor
  if a and a.handle and a.handle ~= 0 and (a.team == 0 or a.team == 1) then carrier = { handle = a.handle, team = a.team } end
  return nil
end)
VRFW.on("match:start", function(ev)
  carrier = nil
  apply_difficulty()
  return nil
end)
VRFW.on("match:end", function(ev) carrier = nil return nil end)

VRFW.on("script:signal:LegendaryAI.furor_zone", function(ev)
  local user = user_team()
  if user == nil or carrier == nil or carrier.team ~= 1 - user or VRFW.ai.human(carrier.team) then return nil end
  VRFW.signal("Furor.gauge.start", carrier.handle)
  VRFW.log(string.format("legendary_ai: furor zone start for team %d (carrier 0x%08X)", carrier.team, carrier.handle))
  return nil
end)

VRFW.on("script:signal:LegendaryAI.furor_defend", function(ev)
  local user = ev.actor and ev.actor.team
  if (user ~= 0 and user ~= 1) or VRFW.ai.human(1 - user) then return nil end
  for _, a in ipairs(Actors.list()) do
    if a.team == 1 - user then
      VRFW.signal("Furor.gauge.start", a.handle)
      VRFW.log(string.format("legendary_ai: furor defence start for team %d (via 0x%08X)", a.team, a.handle))
      return nil
    end
  end
  return nil
end)
