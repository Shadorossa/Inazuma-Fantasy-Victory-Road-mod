-- Player Training › what the stats do in a match (docs/game/mechanics/stats-system.md §10; config.toml [stat_effects]):
--   * Suerte -> the «parada» (critical catch): before each shot's rolls (hook ClassicTraining.ShotLaunch, the shot
--     launch 0x1532110) the game's base criticalCatchPercentage becomes the defending keeper's value
--     round(base + Suerte x per_luck), at most cap; the game applies its own conditions and passives on top.
--   * Suerte -> the critical hit of special moves: this mod's answer to the framework's critical stage (crit_check).
--   * Control -> first touch (option row first_touch): a log-only probe, one line per received pass (no stat-driven
--     miss exists in the game's plain pass reception to hook).
-- Suerte of a match player = his card's Suerte at his level (Character Reforged) + the committed training delta of
-- the saved character he was copied from (a rival trained for the match: his match delta, lib\rival_training.lua). Same rules for both teams; values cached per match. Nothing runs at load.
-- A library required by scripts\player_training.lua: every script runs in its own VM, so it shares that VM to call
-- ClassicTraining.LuckDelta (the committed training) and lib\rival_training.lua's handlers run there too.

ClassicTraining = ClassicTraining or {}
ClassicTraining.StatEffects = ClassicTraining.StatEffects or {}
local Effects = ClassicTraining.StatEffects

local CS = require "lib/card_stats"
local V = require "lib/chara_view"
local R = require "lib/training_rules"
local RivalTraining = require "lib/rival_training"

require "VRFW/lib/basics"
local info, warn = VRFW.logger("stat_effects")
local u32 = require("VRFW/lib/ids").u32

local CONTROL = 1

-- the shot launch's reads (v7.2.1): the ball's kicker, the match info's team blocks and their member rows
local BALL_KICKER = 0x149C
local TEAM_BLOCKS, TEAM_STRIDE = 0x60, 0x1130
local MEMBER_STRIDE, MEMBER_ROWS = 0x80, 0x1D
local MEMBER_SKIP, MEMBER_USED, MEMBER_HANDLE = 0xF1, 0xD8, 0xE4

local SETTINGS = nil
local PLAYERS = nil
local LUCK = {}            -- handle -> Suerte, this match
local LAST_OWNER = 0       -- the ball's last owner handle, this match
local PASS_FROM = 0        -- the passer of the pass in flight (match:pass), 0 = none
local CATCH_WRITTEN = nil  -- the criticalCatchPercentage value last written

local Memory = require "VRFW/lib/memory"
local read_memory = Memory.read_memory

local function setting(key, default)
  local ok, v = pcall(VRFW.files.config, "stat_effects." .. key)
  if ok and type(v) == "number" then return v end
  return default
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
  local view = V.view(hdl)
  local okOwner, owner = pcall(VRFW.character.owner, hdl)
  if not okOwner then owner = nil end
  if not view and owner then view = V.view(owner) end
  if view then
    local p = players()[u32(view.param_id)]
    local level = V.level(view.obj)
    if p and level then
      local base = nil
      if p.native then                         -- a card without per-character values: Suerte from its own values
        base = {}
        for i = 0, CS.RETIRED - 1 do base[i] = V.param_stat(view.params, i) or 0 end
      end
      value = CS.luck(p, level, base)
    end
    local saved = owner or hdl
    local okDelta, delta = pcall(ClassicTraining.LuckDelta, saved)
    if okDelta and type(delta) == "number" then value = value + delta end
    local okRival, rival = pcall(RivalTraining.luck_delta, hdl, view.param_id)
    if okRival and type(rival) == "number" then value = value + rival end
  end
  value = math.max(0, value)
  LUCK[hdl] = value
  return value
end

-- the parada base % of a keeper (a whole number, as the game stores it)
function Effects.CatchPercent(keeper)
  local s = settings()
  local v = s.catch_base + Effects.Luck(keeper) * s.catch_per_luck
  return math.max(0, math.min(s.catch_cap, 100, math.floor(v + 0.5)))
end

-- the move-critical chance this mod answers for a player, in percentage points (before the cap)
function Effects.CriticalChance(hdl)
  local s = settings()
  return s.crit_base + Effects.Luck(hdl) * s.crit_per_luck
end

local function catch_address()
  local ok, a = pcall(VRFW.mem.global_addr, "player_training_critical_catch")
  if ok and a and a ~= 0 then return a end
  return nil
end

local function write_catch(value)
  local a = catch_address()
  if not a then return false end
  if CATCH_WRITTEN == value then return true end
  local ok = pcall(VRFW.mem.write, "i32", a, value)
  if ok then CATCH_WRITTEN = value end
  return ok
end

-- the defending keeper of the shot being launched: the team other than the kicker's, its first member row whose +0xF1
-- is 0 (as the shot launch reads it)
local function defending_keeper()
  local var = VRFW.game.symbol("Ball.Global")
  local ball = var and read_memory("ptr", var)
  if not ball or ball == 0 then return nil end
  local kicker = read_memory("u32", ball + BALL_KICKER)
  if not kicker or kicker == 0 then return nil end
  local a = VRFW.actor(kicker)
  if not a or (a.team ~= 0 and a.team ~= 1) then return nil end
  local info_block = VRFW.game.player_training_match_info()
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
  LAST_OWNER, PASS_FROM = 0, 0
  PLAYERS = nil
end

VRFW.on("match_start", function()
  reset_match()
  settings()
  -- outside a shot the game reads the base (the menu preview of the parada %): the configured base
  write_catch(math.max(0, math.min(100, math.floor(settings().catch_base + 0.5))))
  return nil
end)

-- before the shot's rolls: the defending keeper's parada base
VRFW.on("hook:ClassicTraining.ShotLaunch", function()
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

-- ------------------------------------------------------------------------------------- Control: the reception probe

local function probe_on()
  local ok, v = pcall(VRFW.option, "first_touch")
  return ok and v ~= nil and v ~= 0
end

VRFW.on("match:pass", function(ev)
  if not probe_on() then return nil end
  PASS_FROM = u32((ev.args and ev.args[2]) or 0)
  return nil
end)

VRFW.on("match:possession", function(ev)
  local owner = u32((ev.args and ev.args[2]) or 0)
  if owner == 0 then return nil end
  if owner == LAST_OWNER then return nil end
  LAST_OWNER = owner
  local from = PASS_FROM
  if from == 0 then return nil end
  PASS_FROM = 0
  if not probe_on() then return nil end
  local ra, pa = VRFW.actor(owner), VRFW.actor(from)
  local same = ra and pa and ra.team ~= nil and ra.team == pa.team
  local control = "?"
  local view = V.view(owner)
  if view then
    local _, sum = V.param_stat(view.params, CONTROL)
    local g = V.prm_growth(view.rec)
    if sum then control = tostring(math.max(sum, 1) + ((g and g[CONTROL + 1]) or 0)) end
  end
  info(string.format("first touch probe: pass 0x%08X -> 0x%08X (%s), Control %s", from, owner,
    same and "received" or "intercepted", control))
  return nil
end)

return Effects
