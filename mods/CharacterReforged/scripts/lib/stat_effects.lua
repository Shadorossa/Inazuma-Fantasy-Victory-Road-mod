
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
local LUCK = {}            -- character handle -> Suerte, this match
local LUCK_UNREAD = {}     -- actor handle -> true once his failed reading was logged, this match
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

-- The character handle match actor `hdl` plays (0 when the actor or his match unit is not readable).
local function actor_character(hdl)
  local actor = VRFW.players.of(hdl, { chara = true })
  return actor and u32(actor.chara or 0) or 0
end

-- Suerte of match actor `hdl`: his card's value at his level, plus the committed training of his saved character or his rival training.
function Effects.Luck(hdl)
  hdl = u32(hdl or 0)
  if hdl == 0 then return 0 end
  local chara = actor_character(hdl)
  local cached = LUCK[chara]
  if cached then return cached end
  local view, viewError = nil, "no character on the actor's match unit"
  if chara ~= 0 then view, viewError = V.view(chara) end
  local p = view and players()[u32(view.param_id)]
  local level = view and V.level(view.obj)
  if not (view and p and level) then
    if not LUCK_UNREAD[hdl] then
      LUCK_UNREAD[hdl] = true
      warn(string.format("Suerte of actor 0x%08X not read (character 0x%08X, record %s, card %s, level %s): 0 used", hdl, chara,
        view and "read" or ("not read, code " .. tostring(viewError)),
        view and (p and "known" or string.format("0x%08X not in the card table", u32(view.param_id))) or "-", tostring(level)))
    end
    return 0
  end
  local base = nil
  if p.native then
    base = {}
    for i = 0, CS.RETIRED - 1 do base[i] = V.param_stat(view.params, i) or 0 end
  end
  local card_luck = CS.luck(p, level, base)
  local okOwner, owner = pcall(VRFW.character.owner, chara)
  if not okOwner then owner = nil end
  local trained = 0
  if owner then
    local okDelta, delta = pcall(CharacterReforged.TrainingLuckDelta, owner)
    if okDelta and type(delta) == "number" then trained = delta end
  end
  local rival = 0
  local okRival, rivalDelta = pcall(RivalTraining.luck_delta, hdl, view.param_id)
  if okRival and type(rivalDelta) == "number" then rival = rivalDelta end
  local value = math.max(0, card_luck + trained + rival)
  LUCK[chara] = value
  info(string.format("Suerte of actor 0x%08X (character 0x%08X, card 0x%08X, level %d, owner %s): card %d + training %d + rival training %d = %d",
    hdl, chara, u32(view.param_id), math.floor(level), owner and string.format("0x%08X", u32(owner)) or "none", math.floor(card_luck),
    math.floor(trained), math.floor(rival), math.floor(value)))
  return value
end

-- the parada base % of a keeper (a whole number, as the game stores it)
function Effects.CatchPercent(keeper)
  local s = settings()
  local v = s.catch_base + Effects.Luck(keeper) * s.catch_per_luck
  return math.max(0, math.min(s.catch_cap, 100, math.floor(v + 0.5)))
end

-- The critical chance in percent Suerte gives match actor `hdl`, at most the configured cap.
function Effects.CriticalChance(hdl)
  local s = settings()
  return math.max(0, math.min(s.crit_cap, s.crit_base + Effects.Luck(hdl) * s.crit_per_luck))
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
  LUCK_UNREAD = {}
  PLAYERS = nil
end

VRFW.on("match:start", function()
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

-- The critical stage of a special move's execution (docs/framework/rules.md §3.7): the chance grows with the player's Suerte.
VRFW.on("match:crit_check", function(ev)
  local a = ev.actor
  if not a or not a.handle then return nil end
  local s = settings()
  local chance = Effects.CriticalChance(a.handle)
  info(string.format("critical chance of actor 0x%08X: %.2f %% = %.2f + Suerte %d x %.3f (at most %.1f %% from Suerte)", u32(a.handle), chance,
    s.crit_base, math.floor(Effects.Luck(a.handle)), s.crit_per_luck, s.crit_cap))
  return { crit_chance = chance, crit_mult = s.crit_mult }
end)

return Effects
