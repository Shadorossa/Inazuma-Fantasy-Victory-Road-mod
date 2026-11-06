-- Character Reforged › per-character stats.
--  the
-- game's own stat reads are native answers of content\game\stats.toml's hooks (the level curve, the specialty type, the
-- growth past Lv 99) and the run speed a match-stat modifier, over the tables this script publishes once from the
-- served chara_param (lib\stats_curve.lua: the curve, config.toml [stats] / [level]). Always on (no option row).
--   CMND_CHARACTERREFORGED_CHARA_STAT(charaStHdl, idx) -> value, hasPerCharacterData
--        idx 0..7 = GetCharaStat 0xD87C40's value (max(1, sum of the 5 param arrays) + prm_growth), 8 = Suerte from the
--        curve at the character's level. Errors: value < 0 (-1 bad args, -2 not ready, -4 exception, -5 no record), false.
-- Exports (mod.toml [exports] functions; other mods call CharacterReforged.X):
--   StatsReady() -> true once the tables are published
--   HasStats(card) -> true when the card (chara_param id) has per-character values
--   StatCard(card) -> { growth (0 slow, 1 normal, 2 fast), v2, pos, rarity, build, agi (0..1000), libertad (nil = no
--                       column), vals = { [0] .. [8] } } or nil
--   StatAt(card, idx, level) -> stat idx (0..8) of the card at that level (nil = no per-character values)
--   Libertad(card, level) -> the card's Libertad at that level (0 without the column; nil = no per-character values)
--   DerivedLuck(vals) -> the Suerte of a card that declares none: the mean of vals[0 .. 6] (the 7 gameplay values)
--   CharaStat(hdl, idx) -> as the command (idx 8 of a card without per-character values = DerivedLuck of its param arrays)
--   LevelCap() -> the level cap in effect (99 = the game's)
--   StatCurve() -> the curve's constants (cap, lv1_ratio, p, f, q, s, gain, shape)
--   LevelFactor(level[, growth]) -> the factor of a Lv 99 value at that level (the cap included; growth 1 = normal)
--   StatTotalMax(level) -> the highest sum of stats 0..8 (ex Rapidez excluded) of any card with per-character values at
--                          that level (levels clamped to 1..cap; computed once per level and cached)

local C = require "lib/stats_curve"
local V = require "lib/chara_view"

CharacterReforged = CharacterReforged or {}

require "VRFW/lib/basics"
local info, warn = VRFW.logger("stats")

local ERR_BAD_ARGS = -1
local READY = false
local PLAYERS, CURVE = {}, nil
local TOTAL_MAX = {} -- [level] = the highest stat total at that level (CharacterReforged.StatTotalMax)

local function num(v) return VRFW.value.num(v, nil) end

local function set_state(k, v)
  local ok, e = pcall(VRFW.state.set, k, v)
  if not ok then warn("state " .. k .. ": " .. tostring(e)) end
end

local function card(id)
  local n = num(id)
  if not n then return nil end
  return PLAYERS[C.u32(n)]
end

function CharacterReforged.StatsReady()
  return READY
end

function CharacterReforged.LevelCap()
  return CURVE and CURVE.cap or C.cap()
end

-- the curve's constants: { cap, lv1_ratio, p = {[0] slow, normal, fast}, f = {…} (Lv 200 / Lv 99), q, s (cap scale),
-- gain = {…}, shape }
function CharacterReforged.StatCurve()
  local c = CURVE or C.curve()
  return { cap = c.cap, lv1_ratio = c.lv1_ratio, p = c.p, f = c.f, q = c.q, s = c.s, gain = c.gain, shape = c.shape }
end

-- the factor of a Lv 99 value at `level` (growth 0 slow, 1 normal (default), 2 fast) along the per-character curve,
-- the configured cap included (Stamina Points scales each player's max PE with it)
function CharacterReforged.LevelFactor(level, growth)
  local l = num(level)
  if not l then return nil end
  return C.factor(CURVE or C.curve(), num(growth) or 1, math.floor(l))
end

-- the highest sum of the trainable stats (0..8 without ex Rapidez) of any card at `level`, cached per level
function CharacterReforged.StatTotalMax(level)
  local l = num(level)
  if not READY or not l then return nil end
  local cap = CURVE and CURVE.cap or C.cap()
  l = math.max(1, math.min(cap, math.floor(l)))
  if TOTAL_MAX[l] then return TOTAL_MAX[l] end
  -- a stat at a level depends only on (growth, v2, rarity multiplier, value): each distinct one is computed once
  local memo = {}
  local best = 0
  for _, p in pairs(PLAYERS) do
    local by_growth = memo[p.growth or false]
    if not by_growth then by_growth = {}; memo[p.growth or false] = by_growth end
    local v2 = p.v2 and true or false
    local by_v2 = by_growth[v2]
    if not by_v2 then by_v2 = {}; by_growth[v2] = by_v2 end
    local m = C.card_mult(CURVE, p)
    local known = by_v2[m]
    if not known then known = {}; by_v2[m] = known end
    local sum = 0
    for i = 0, C.N - 1 do
      if i ~= C.RAPIDEZ then
        local v = p.vals[i]
        local keyed = v ~= nil and v == v
        local x = keyed and known[v]
        if not x then
          x = C.stat(CURVE, p, i, l)
          if keyed then known[v] = x end
        end
        sum = sum + x
      end
    end
    if sum > best then best = sum end
  end
  TOTAL_MAX[l] = best
  return best
end

function CharacterReforged.HasStats(id)
  return card(id) ~= nil
end

function CharacterReforged.StatCard(id)
  local p = card(id)
  if not p then return nil end
  local vals = {}
  for i = 0, 8 do vals[i] = p.vals[i] end
  return { growth = p.growth, v2 = p.v2, pos = p.pos, rarity = p.rarity, build = p.build, agi = p.agi, libertad = p.libertad, vals = vals }
end

function CharacterReforged.StatAt(id, idx, level)
  local p = card(id)
  local i, l = num(idx), num(level)
  if not p or not i or not l or i < 0 or i >= C.N then return nil end
  return C.stat(CURVE, p, math.floor(i), math.floor(l))
end

function CharacterReforged.Libertad(id, level)
  local p = card(id)
  local l = num(level)
  if not p or not l then return nil end
  return C.libertad(CURVE, p, math.floor(l))
end

-- Suerte of a card without per-character values: the rule of C.derived_luck over the 7 gameplay values of the character's
-- own param arrays (the untrained base the game reads, prm_growth not included); 0 when they cannot be read
local function memory_luck(obj)
  local params = V.params(obj)
  if not params then return 0 end
  local vals = {}
  for k = 0, C.AGILIDAD do
    local b = V.param_stat(params, k)
    if b == nil then return 0 end
    vals[k] = b
  end
  return C.derived_luck(vals)
end

-- the Suerte rule of a card that declares none (C.derived_luck): the mean of vals[0 .. 6]
function CharacterReforged.DerivedLuck(vals)
  if type(vals) ~= "table" then return nil end
  return C.derived_luck(vals)
end

-- value, has per-character data | error code (< 0), false
function CharacterReforged.CharaStat(hdl, idx)
  if not READY then return -2, false end
  hdl = C.u32(num(hdl) or 0)
  local i = num(idx)
  i = i and (i >= 0 and math.floor(i) or math.ceil(i))
  if not i or i < 0 or i >= C.N then return ERR_BAD_ARGS, false end
  local obj, e = V.object(hdl)
  if not obj then return e, false end
  local rec, id = V.record(obj), V.param_id(obj)
  if not rec or not id then return V.ERR_NO_RECORD, false end
  local p = PLAYERS[C.u32(id)]
  if i == C.LUCK then
    if not p then return memory_luck(obj), false end
    local lv, le = V.level(obj)
    if not lv then return le, false end
    return C.stat(CURVE, p, C.LUCK, lv), true
  end
  local params = V.params(obj)
  if not params then return V.ERR_NOT_READY, false end
  local _, sum = V.param_stat(params, i)
  if sum == nil then return V.ERR_NOT_READY, false end
  local growth = V.growth_of(rec, i)
  if growth == nil then return V.ERR_NOT_READY, false end
  return math.max(sum, 1) + growth, p ~= nil
end

-- ---------------------------------------------------------------------------------------------- start

local function start()
  if not V.ready() then
    warn("CMND_CHARACTERREFORGED_CHARA_STAT unavailable (signatures)")
  end
  CURVE = C.curve()
  local t0 = VRFW.now()
  local ok, players = pcall(C.load)
  if not ok then
    VRFW.error("stats: chara_param: " .. tostring(players))
    players = {}
  end
  PLAYERS = players
  TOTAL_MAX = {}
  local n = C.publish(CURVE, PLAYERS)
  READY = true
  set_state("CharacterReforged.stats.post99", CURVE.cap > 99 and 1 or 0)
  set_state("CharacterReforged.stats.ready", 1)
  local v1, v2 = 0, 0
  for _, p in pairs(PLAYERS) do
    if p.v2 then v2 = v2 + 1 else v1 = v1 + 1 end
  end
  info(string.format("%d cards with per-character values (%d Lv200 values, %d Lv99 values) published in %d ms: GetCharaParamStatus [%s], specialty type [%s]; level cap %d%s",
    n, v2, v1, VRFW.now() - t0, VRFW.is_on("CharacterReforged.CharaParamStatus") and "hooked" or "OFF",
    VRFW.is_on("CharacterReforged.SpecialtyType") and "hooked" or "OFF", CURVE.cap,
    CURVE.cap > 99 and string.format(" (curve above Lv 99 scaled x%.3f from the Lv 200 reference)", CURVE.s) or " (the game's)"))
  if n == 0 then warn("no card has per-character values: every player keeps the game's stats") end
  -- the run speed from Agilidad: the band, NPC rows, charaMoveSpeedBase's address
  local band = C.cfg("stats.agility_speed", 0.05)
  if type(band) ~= "number" or band ~= band or band < 0 or band > 0.20 then
    warn(string.format("[stats] agility_speed %s out of range 0..0.2, using 0.05", tostring(band)))
    band = 0.05
  end
  local pct = math.floor(band * 100 + 0.5)
  set_state("CharacterReforged.stats.speed_pct", pct)
  set_state("CharacterReforged.stats.speed_npc", C.cfg("stats.speed_npc", true) and 1 or 0)
  local base = VRFW.is_on("character_reforged_move_speed_base") and VRFW.mem.global_addr("character_reforged_move_speed_base") or nil
  if base and base ~= 0 and pct > 0 then
    set_state("CharacterReforged.stats.speed_base", base)
    set_state("CharacterReforged.stats.speed_on", 1)
    info(string.format("run speed from Agilidad +-%d %% ([stats] agility_speed)", pct))
  else
    set_state("CharacterReforged.stats.speed_on", 0)
    if pct > 0 then warn("charaMoveSpeedBase not found: Agilidad does not change run speed") end
  end
end

start()
