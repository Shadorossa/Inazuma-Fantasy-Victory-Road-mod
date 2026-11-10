
CharacterReforged = CharacterReforged or {}
CharacterReforged.Training = CharacterReforged.Training or {}
CharacterReforged.Training.StatEffects = CharacterReforged.Training.StatEffects or {}
local Effects = CharacterReforged.Training.StatEffects

local CS = require "lib/card_stats"
local V = require "lib/chara_view"
local R = require "lib/training_rules"
local RivalTraining = require "lib/rival_training"

local info, warn = VRFW.logger("stat_effects")
local u32 = VRFW.ids.unsigned

local BALL_KICKER = 0x149C
local TEAM_BLOCKS, TEAM_STRIDE = 0x60, 0x1130
local MEMBER_STRIDE, MEMBER_ROWS = 0x80, 0x1D
local MEMBER_SKIP, MEMBER_USED, MEMBER_HANDLE = 0xF1, 0xD8, 0xE4

local SETTINGS = nil
local PLAYERS = nil
local LUCK = {}            -- handle -> Suerte, this match
local CATCH_WRITTEN = nil  -- the criticalCatchPercentage value last written

local Memory = VRFW.memory
local read_memory = Memory.read

local function setting(key, default)
  return VRFW.config("stat_effects." .. key, default)
end

local function settings()
  if SETTINGS then return SETTINGS end
  SETTINGS = {
    catch_base = setting("critical_catch_base_percent", 1),
    catch_per_luck = setting("critical_catch_per_luck", 0),
    catch_cap = setting("critical_catch_cap_percent", 100),
    crit_base = setting("move_critical_base_percent", 0),
    crit_per_luck = setting("move_critical_per_luck", 0),
    crit_cap = setting("move_critical_cap_percent", 100),
    crit_mult = math.max(0, setting("move_critical_power_multiplier", 1)),
  }
  return SETTINGS
end

local function players()
  if not PLAYERS then PLAYERS = CS.players() end
  return PLAYERS
end

-- Suerte of a match player (0 when his card or record is not known)
function Effects.Luck(hdl)
  hdl = u32(hdl or 0)
  if hdl == 0 then return 0 end
  local cached = LUCK[hdl]
  if cached then return cached end
  local value = 0
  local view, viewError = V.view(hdl)
  local okOwner, owner = pcall(VRFW.character.owner, hdl)
  if not okOwner then owner = nil end
  if not view and owner then view, viewError = V.view(owner) end
  local p, level = nil, nil
  if view then
    p = players()[u32(view.param_id)]
    level = V.level(view.obj)
    if p and level then
      local base = nil
      if p.native then
        base = {}
        for i = 0, CS.RETIRED - 1 do base[i] = V.param_stat(view.params, i) or 0 end
      end
      value = CS.luck(p, level, base)
    end
    local saved = owner or hdl
    local okDelta, delta = pcall(CharacterReforged.TrainingLuckDelta, saved)
    if okDelta and type(delta) == "number" then value = value + delta end
    local okRival, rival = pcall(RivalTraining.luck_delta, hdl, view.param_id)
    if okRival and type(rival) == "number" then value = value + rival end
  end
  value = math.max(0, value)
  LUCK[hdl] = value
  -- One line per player and match tells which step of the reading answered, because a Luck of 0 for every player was seen on 2026-11-10.
  info(string.format("Suerte of 0x%08X: %d (owner %s, record %s, card %s, level %s)", hdl, math.floor(value),
    owner and string.format("0x%08X", u32(owner)) or "none", view and "read" or ("not read, code " .. tostring(viewError)),
    view and (p and "known" or string.format("0x%08X not in the card table", u32(view.param_id))) or "-", tostring(level)))
  return value
end

-- the parada base % of a keeper (a whole number, as the game stores it)
function Effects.CatchPercent(keeper)
  local s = settings()
  local v = s.catch_base + Effects.Luck(keeper) * s.catch_per_luck
  return math.max(0, math.min(s.catch_cap, 100, math.floor(v + 0.5)))
end

function Effects.CriticalChance(hdl)
  local s = settings()
  return s.crit_base + Effects.Luck(hdl) * s.crit_per_luck
end

local function catch_address()
  local a = VRFW.memory.global_addr("character_reforged_critical_catch")
  local ok = a ~= nil
  if ok and a and a ~= 0 then return a end
  return nil
end

local function write_catch(value)
  local a = catch_address()
  if not a then return false end
  if CATCH_WRITTEN == value then return true end
  local ok = VRFW.memory.write("i32", a, value)
  if ok then CATCH_WRITTEN = value end
  return ok
end

local function defending_keeper()
  local var = VRFW.game.symbol("Ball.Global")
  local ball = var and read_memory("ptr", var)
  if not ball or ball == 0 then return nil end
  local kicker = read_memory("u32", ball + BALL_KICKER)
  if not kicker or kicker == 0 then return nil end
  local a = VRFW.actor(kicker)
  if not a or (a.team ~= 0 and a.team ~= 1) then return nil end
  local info_block = VRFW.game.character_reforged_match_info()
  if not info_block or info_block == 0 then return nil end
  local row = info_block + TEAM_BLOCKS + (1 - a.team) * TEAM_STRIDE
  for _ = 1, MEMBER_ROWS do
    local skip = read_memory("u8", row + MEMBER_SKIP)
    if skip == nil then return nil end
    if skip == 0 then
      if (read_memory("u32", row + MEMBER_USED) or 0) == 0 then return nil end
      local hdl = read_memory("u32", row + MEMBER_HANDLE)
      if hdl and hdl ~= 0 then return hdl, kicker end
      return nil
    end
    row = row + MEMBER_STRIDE
  end
  return nil
end

local function reset_match()
  LUCK = {}
  PLAYERS = nil
end

VRFW.on("match_start", function()
  reset_match()
  settings()
  write_catch(math.max(0, math.min(100, math.floor(settings().catch_base + 0.5))))
  return nil
end)

VRFW.on("hook:CharacterReforged.TrainingShotLaunch", function()
  local keeper, kicker = defending_keeper()
  if not keeper then return nil end
  local pct = Effects.CatchPercent(keeper)
  if write_catch(pct) then
    info(string.format("shot by 0x%08X: keeper 0x%08X, Suerte %d, parada base %d %%", kicker, keeper, math.floor(Effects.Luck(keeper)), pct))
  end
  return nil
end)

-- the critical stage of special moves (docs/framework/rules.md §3.7)
VRFW.on("crit_check", function(ev)
  local a = ev.actor
  if not a or not a.handle then return nil end
  local s = settings()
  return { crit_chance = Effects.CriticalChance(a.handle), crit_cap = s.crit_cap, crit_mult = s.crit_mult }
end)

return Effects
