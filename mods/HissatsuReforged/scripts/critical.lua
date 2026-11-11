
HissatsuReforged = HissatsuReforged or {}
HissatsuReforged.Critical = HissatsuReforged.Critical or {}
local Critical = HissatsuReforged.Critical

local info, warn = VRFW.logger("critical")

local ARCHETYPE_STATE = "VRFW.archetype.team"   -- + match side: the side's team build (VRFW archetype service)
local RANK_STATE = "HissatsuReforged.critical_rank"

local u32 = VRFW.ids.unsigned

local function setting(key, default)
  local v = VRFW.config("critical." .. key, default)
  if type(default) == "table" then
    local out = {}
    for i, x in ipairs(v) do
      if type(x) ~= "number" then return default end
      out[i] = x
    end
    return #out > 0 and out or default
  end
  return v
end

local config = nil

local function settings()
  if config then return config end
  config = {
    base_chance = setting("base_chance", 0),
    multiplier = setting("multiplier", 1),
    cap = setting("cap", 100),
    archetype_build = setting("archetype_build", -1),
    keeper_move_category = setting("keeper_move_category", -1),
    power_per_rank = setting("power_per_rank", 0),
    keeper_per_rank = setting("keeper_per_rank", 0),
    rank_up_seconds = setting("rank_up_seconds", 0),
    rank_down_on_crit = setting("rank_down_on_crit", 0),
    levels = setting("levels", { 0 }),
    keeper_levels = setting("keeper_levels", {}),
  }
  if config.multiplier < 0 then
    warn("multiplier " .. tostring(config.multiplier) .. " below 0: 1 used")
    config.multiplier = 1
  end
  info(string.format("base %.1f %%, power x%.2f, cap %.1f %%; build %d: power +%.1f %%/rank, keepers +%.1f %%/rank; "
    .. "%d ranks (+1 per %ds, -%d per critical)", config.base_chance, config.multiplier, config.cap, config.archetype_build,
    config.power_per_rank, config.keeper_per_rank, #config.levels, config.rank_up_seconds, config.rank_down_on_crit))
  return config
end

-- [skill id] = skill table category, read once at script load (the boot thread, a data read)
local moves = {}
do
  local ok, rows = pcall(VRFW.table.rows, "skill/skill")
  if ok then
    for _, r in ipairs(rows) do
      if r.skill_id then moves[u32(r.skill_id)] = tonumber(r.category) or 0 end
    end
  else
    warn("skill/skill not readable: " .. tostring(rows) .. ": no move gets a critical")
  end
end

local function move_category(skill)
  return moves[u32(skill)]
end

local function on_archetype(side)
  local ok, v = pcall(VRFW.state.get, ARCHETYPE_STATE .. tostring(side))
  return ok and tonumber(v) == settings().archetype_build
end

local CHARGE = {}

local function clock_of(ev)
  local m = ev.match or VRFW.match() or {}
  return tonumber(m.half), tonumber(m.clock)
end

local function publish(side, rank, why)
  pcall(VRFW.state.set, RANK_STATE .. tostring(side), rank)
  info(string.format("side %d rank %d (%s)", side, rank, why))
end

local function rank_now(side, ev)
  local c = settings()
  local top = #c.levels
  local half, clock = clock_of(ev)
  local s = CHARGE[side]
  if not s then
    s = { rank = 1, half = half, clock = clock or 0 }
    CHARGE[side] = s
    publish(side, 1, "start")
  end
  if c.rank_up_seconds > 0 and clock then
    -- a new half counts from its start
    if half ~= s.half then s.half, s.clock = half, 0 end
    local up = math.floor(math.max(0, clock - s.clock) / c.rank_up_seconds)
    if up > 0 then
      s.clock = s.clock + up * c.rank_up_seconds
      if s.rank < top then
        s.rank = math.min(top, s.rank + up)
        publish(side, s.rank, "no critical for " .. tostring(up * c.rank_up_seconds) .. " s")
      end
    end
  end
  return s.rank
end

local function on_team_crit(side, ev)
  local c = settings()
  local r = rank_now(side, ev)
  local s = CHARGE[side]
  local half, clock = clock_of(ev)
  s.rank, s.half, s.clock = math.max(1, r - c.rank_down_on_crit), half, clock or 0
  if s.rank ~= r then publish(side, s.rank, "critical hit") end
end

-- The points, the chance factor and the power multiplier this mod answers for the event's move: the build's charge acts on the whole team.
function Critical.Answer(ev)
  local c = settings()
  local a = ev.actor
  local chance, rate, mult = c.base_chance, 1, c.multiplier
  if a and (a.team == 0 or a.team == 1) and on_archetype(a.team) then
    local rank = rank_now(a.team, ev)
    rate = 1 + (c.levels[rank] or 0) / 100
    if move_category(ev.skill) == c.keeper_move_category then
      rate = rate * (1 + ((c.keeper_levels[rank] or 0) + c.keeper_per_rank * rank) / 100)
    end
    mult = mult * (1 + c.power_per_rank * rank / 100)
  end
  return chance, rate, mult
end

VRFW.on("match_start", function()
  CHARGE = {}
  -- the settings here, not by the match's first move
  settings()
  return nil
end)

VRFW.on("crit_check", function(ev)
  if not ev.actor or not ev.skill or move_category(ev.skill) == nil then return nil end
  local chance, rate, mult = Critical.Answer(ev)
  return { crit_chance = chance, crit_chance_mult = rate, crit_mult = mult, crit_cap = settings().cap }
end)

VRFW.on("crit", function(ev)
  local a = ev.actor
  if not a or not ev.skill or move_category(ev.skill) == nil then return nil end
  info(string.format("CRITICAL: move 0x%08X by 0x%08X (team %s)", u32(ev.skill), u32(a.handle), tostring(a.team)))
  if (a.team == 0 or a.team == 1) and on_archetype(a.team) then on_team_crit(a.team, ev) end
  return nil
end)
