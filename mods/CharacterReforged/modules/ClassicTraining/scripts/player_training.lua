-- Player Training › classic training (Chrono Stone rules): each player spreads his Libertad points over his base stats.
-- The commands are content\game\player_training.toml; the old names
-- CMND_EVT_TRAIN_* are aliases (the training window evt_training_menu and the skill table's training mode call them):
--
--   CMND_CLASSICTRAINING_INFO(charaStHdl, fresh)  -> ok, status, libTotal, libAvail, level, position, dirty, growthType, rule
--   CMND_CLASSICTRAINING_STAT(charaStHdl, idx)    -> ok, value, base, bonus, delta, committed, min, max, partner1, partner2
--   CMND_CLASSICTRAINING_SET(charaStHdl, idx, d)  -> ok, stop, reached, libAvail, d0 … d8
--   CMND_CLASSICTRAINING_COMMIT(charaStHdl)       -> ok, status
--   CMND_CLASSICTRAINING_CANCEL(charaStHdl)       -> ok        (0 = every session)
--   CMND_CLASSICTRAINING_RESET(charaStHdl)        -> ok, libAvail
--   CMND_CLASSICTRAINING_LUCK_DELTA(charaStHdl)   -> the committed Suerte delta (0 = none)
--   CMND_CLASSICTRAINING_POSITION(charaStHdl)     -> ok, chosen, main, sub (0 = none), trained
--   CMND_CLASSICTRAINING_SET_POSITION(charaStHdl, pos) -> ok, libAvail
--
-- The training criterion (the counterpart pairs of lib/training_rules.lua) is the position chosen for the player: his
-- card's main position (chara_param main_position) or its sub position (sub_position). The choice is part of the
-- session: SET_POSITION drops the whole working training (every delta back to 0) and COMMIT stores the choice with the
-- deltas in the slot blob (lib/training_store.lua); no stored choice = the main position. The game's own save field
-- sub_position is never written.
--
-- (rule 0 pairs / 1 pool / 2 trade; position 1 GK 2 FW 3 MF 4 DF; growthType 0 slow 1 normal 2 fast; fresh = 1 drops
-- the working copy first.) A session per character holds the committed deltas (prm_growth[0..7] + the Suerte delta of
-- the slot blob training.json, lib/training_store.lua) and a working copy SET / RESET change; nothing reaches the game
-- before COMMIT (prm_growth written in memory, saved by the game at its next save; Suerte into the blob). Sessions are
-- per (handle, card); a session whose committed prm_growth no longer matches memory (a load, a slot switch) is rebuilt
-- from memory first. Cards of a locked
-- rarity (config.toml [training] locked_rarities, empty by default) answer -9. Libertad = Budget(level) - the sum of
-- the card's untrained base stats, so every card reaches the same total (lib/card_stats.lua). The per-card values
-- (Suerte, position, growth) and the budget's card totals are Character Reforged's (its exports); the commands answer
-- false until it published them. The trained points reach
-- matches through the framework's match-build service ([[VRFW.MatchStat]] ClassicTraining.TrainedPoints, while the
-- state ClassicTraining.active = 1, set here).
--
-- Exports (mod.toml [exports]): Info / Stat / Set / Commit / Cancel / Reset (the commands) and LuckDelta(hdl) (the
-- committed Suerte delta: Inazuma Fantasy's CMND_EVT_CHARA_STAT adds it to the Suerte it shows).

local CS = require "lib/card_stats"
local V = require "lib/chara_view"
local R = require "lib/training_rules"
local S = require "lib/training_store"
local RivalTraining = require "lib/rival_training"

ClassicTraining = ClassicTraining or {}

require "VRFW/lib/basics"
local info, warn, err = VRFW.logger("training")

local ERR_BAD_ARGS, ERR_NOT_READY, ERR_NO_DATA, ERR_WRITE, ERR_LOCKED = -1, -2, -6, -8, -9
local N = R.N
local STATE_KEY = "ClassicTraining.active"

local ON = false
local RULES = { rule = "trade", floor_percent = 0, max_value = 9999 }
local LOCKED = {}
local PLAYERS
local SESSIONS = {}
local STORE -- { slot, file }
local SUB_POSITIONS -- [card id] = the card's sub position (chara_param sub_position), read once per VM

-- ---------------------------------------------------------------------------------------------- helpers

local function num(v) return VRFW.value.num(v, nil) end
local function int(v) return VRFW.value.int(v, nil) end

local function hdl_arg(v) return CS.u32(num(v) or 0) end

local function idx_arg(v)
  local i = int(v)
  if i and i >= 0 and i < N then return i end
  return nil
end

local Id = require "VRFW/lib/ids"
local hex = Id.hex

local function list(d)
  local t = {}
  for i = 0, N - 1 do t[#t + 1] = tostring(d[i]) end
  return "[" .. table.concat(t, ", ") .. "]"
end

-- a value of this mod's config.toml (dotted path), `default` when missing or of another type
local function cfg(path, default)
  local ok, v = pcall(VRFW.files.config, path)
  if not ok or v == nil then return default end
  if default ~= nil and type(v) ~= type(default) then return default end
  return v
end

-- the training answers while Character Reforged's per-card values are published; otherwise false (as before)
local function active()
  return ON and CS.ready()
end

local function players()
  if not PLAYERS then PLAYERS = CS.players() end
  return PLAYERS
end

-- ---------------------------------------------------------------------------------------------- Suerte store

-- the store of the active slot (loaded on first use and after a slot change)
local function store()
  local s = VRFW.slots.active()
  if not STORE or STORE.slot ~= s then
    local f, why = S.load(s)
    if not f then
      err(string.format("slot %d: Suerte store unreadable (%s): deltas start at 0 (the stored version is kept in the backups at the next commit)", s, tostring(why)))
      f = S.empty()
    end
    STORE = { slot = s, file = f }
  end
  return STORE.file, STORE.slot
end

-- ---------------------------------------------------------------------------------------------- positions

-- the sub position of card `id` (0 = none): the character index's column sub_position, read once
local function sub_position(id)
  if not SUB_POSITIONS then
    SUB_POSITIONS = {}
    local ok, cards = pcall(VRFW.character.cards, { columns = { "sub_position" } })
    if ok and type(cards) == "table" then
      for _, c in ipairs(cards) do
        local v = type(c.cols) == "table" and c.cols.sub_position or nil
        if type(c.id) == "number" and type(v) == "number" and v ~= 0 then SUB_POSITIONS[CS.u32(c.id)] = v end
      end
    else
      warn("character index unreadable: no sub positions (" .. tostring(cards) .. ")")
    end
  end
  return SUB_POSITIONS[CS.u32(id)] or 0
end

-- the two positions a player can train for: main, sub (nil when the card has none or it is the main one)
local function positions(pl)
  local main = R.position(pl.stats.pos)
  local raw = sub_position(pl.view.param_id)
  local sub = raw ~= 0 and R.position(raw) or nil
  if sub == main then sub = nil end
  return main, sub
end

-- a stored choice that is one of the player's positions, else his main position
local function valid_position(pl, pos)
  local main, sub = positions(pl)
  if pos ~= nil and pos == sub then return sub end
  return main
end

-- ---------------------------------------------------------------------------------------------- characters, sessions

-- everything a command needs about one character, or nil + error code
local function load_player(hdl)
  if hdl == 0 then return nil, ERR_BAD_ARGS end
  local view, e = V.view(hdl)
  if not view then return nil, e end
  local p = players()[CS.u32(view.param_id)]
  if not p then return nil, ERR_NO_DATA end
  if CS.locked(p, LOCKED) then return nil, ERR_LOCKED end
  local level, le = V.level(view.obj)
  if not level then return nil, le end
  local base, bonus = {}, {}
  for i = 0, 7 do
    local b, sum = V.param_stat(view.params, i)
    if b == nil then return nil, ERR_NOT_READY end
    base[i] = b
    bonus[i] = math.max(sum, 1) - b -- shown = max(1, sum of the 5 arrays) + prm_growth, as GetCharaStat 0xD87C40
  end
  base[R.LUCK] = CS.luck(p, level, base)
  bonus[R.LUCK] = 0
  local total = CS.libertad(p, level, base)
  local mem_g = V.prm_growth(view.rec)
  if not mem_g then return nil, ERR_NOT_READY end
  return { view = view, stats = p, level = level, ctx = R.ctx(RULES, R.position(p.pos), base, bonus, total), mem_g = mem_g }
end

local function committed_of(pl, hdl)
  local c = {}
  for i = 0, 7 do c[i] = pl.mem_g[i + 1] end
  c[R.LUCK] = S.suerte(store(), hdl, pl.view.param_id, pl.mem_g)
  return c
end

-- sessions are per (handle, card): a handle a menu fills with another card in turn (the album's player sheet) keeps
-- one session per card, so browsing never drops a working copy
local function session_key(hdl, param_id) return string.format("%08X:%08X", hdl, CS.u32(param_id)) end

-- the session of hdl (created or rebuilt from memory when needed): pl, session or nil + error code
-- The player last loaded (one per screen: the commands of a training view ask about one player at a time, Stat once per
-- stat). Loaded again on another player, an opened view (Info fresh), after Commit / Cancel / SetPosition, after a
-- match, a slot load or a game reset; never per call.
local LOADED = nil   -- { hdl, pl }

local function forget_player()
  LOADED = nil
end

local function loaded_player(hdl, fresh)
  if not fresh and LOADED and LOADED.hdl == hdl then return LOADED.pl end
  local t0 = VRFW.now and VRFW.now() or nil
  local pl, e = load_player(hdl)
  if not pl then
    LOADED = nil
    return nil, e
  end
  LOADED = { hdl = hdl, pl = pl }
  if t0 then VRFW.debug(string.format("training: player %s (id %d) loaded for the training view in %d ms", hex(hdl), pl.view.param_id, math.floor(VRFW.now() - t0))) end
  return pl
end

local function session(hdl, fresh)
  local pl, e = loaded_player(hdl, fresh)
  if not pl then return nil, e end
  local key = session_key(hdl, pl.view.param_id)
  local s = SESSIONS[key]
  local stale = false
  if s then
    for i = 0, 7 do
      if s.committed[i] ~= pl.mem_g[i + 1] then stale = true end
    end
  end
  if fresh or stale or not s then
    if stale and not fresh then
      warn(string.format("%s (id %d): prm_growth changed under an open session (load / slot switch): working copy dropped", hex(hdl), pl.view.param_id))
    end
    local c = committed_of(pl, hdl)
    local pos = valid_position(pl, S.position(store(), hdl, pl.view.param_id, pl.mem_g))
    s = { hdl = hdl, param_id = pl.view.param_id, committed = c, working = R.copy(c), pos = pos, committed_pos = pos }
    SESSIONS[key] = s
  end
  pl.ctx.pos = s.pos -- the chosen position's pairs
  return pl, s
end

-- ---------------------------------------------------------------------------------------------- commands

function ClassicTraining.Info(hdl, fresh)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local f = num(fresh)
  local pl, s = session(hdl, f ~= nil and f ~= 0)
  local rule = R.rule_code(RULES.rule)
  if not pl then
    info(string.format("INFO(%s) -> error %d", hex(hdl), s))
    return false, s, 0, 0, 0, 0, false, 0, rule
  end
  local c = pl.ctx
  local dirty = not R.equal(s.working, s.committed) or s.pos ~= s.committed_pos
  return true, 0, c.total, R.available(c, s.working), pl.level, c.pos, dirty, pl.stats.growth, rule
end

function ClassicTraining.Stat(hdl, idx)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local i = idx_arg(idx)
  if not i then
    return false, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS, ERR_BAD_ARGS
  end
  local pl, s = session(hdl, false)
  if not pl then return false, s, s, s, s, s, s, s, s, s end
  local c = pl.ctx
  local min, reach = R.range(c, s.working, i)
  local max = math.max(R.cap(c, s.working, i), reach)
  local pr = R.partners(c.pos, i)
  return true, R.value(c, s.working, i), c.base[i], c.bonus[i], s.working[i], s.committed[i], min, max, pr[1] or -1, pr[2] or -1
end

local function fail(code, extra)
  local out = { false, code }
  for k = 1, extra do out[#out + 1] = 0 end
  return table.unpack(out)
end

function ClassicTraining.Set(hdl, idx, target)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local i, t = idx_arg(idx), int(target)
  if not i or not t then return fail(ERR_BAD_ARGS, 2 + N) end
  t = math.max(-99999, math.min(99999, t))
  local pl, s = session(hdl, false)
  if not pl then return fail(s, 2 + N) end
  local reached, stop = R.set(pl.ctx, s.working, i, t)
  local d = s.working
  return stop == R.NONE, stop, reached, R.available(pl.ctx, d), d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8]
end

function ClassicTraining.Commit(hdl)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local pl, s = session(hdl, false)
  if not pl then return false, s end
  local g = {}
  for i = 0, 7 do g[i + 1] = s.working[i] end
  if not V.write_prm_growth(pl.view.rec, g) then
    err(string.format("COMMIT(%s): prm_growth write failed", hex(hdl)))
    return false, ERR_WRITE
  end
  local f, slot = store()
  local main = positions(pl)
  if S.record(f, hdl, pl.view.param_id, g, s.working[R.LUCK], s.pos ~= main and s.pos or nil) then
    local ok, where = S.save(f, slot)
    if not ok then err("cannot write: " .. tostring(where)) end
  end
  info(string.format("COMMIT %s (id %d): %s -> %s, Libertad %d/%d, position %d", hex(hdl), pl.view.param_id, list(s.committed),
    list(s.working), R.available(pl.ctx, s.working), pl.ctx.total, s.pos))
  s.committed = R.copy(s.working)
  s.committed_pos = s.pos
  forget_player()
  return true, 0
end

function ClassicTraining.Cancel(hdl)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  forget_player()
  if hdl == 0 then
    SESSIONS = {}
  else
    for k, s in pairs(SESSIONS) do
      if s.hdl == hdl then SESSIONS[k] = nil end
    end
  end
  return true
end

function ClassicTraining.Reset(hdl)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local pl, s = session(hdl, false)
  if not pl then return false, s end
  s.working = R.zeros()
  return true, R.available(pl.ctx, s.working)
end

-- the player's training positions: ok, chosen, main, sub (0 = none), trained (any working or committed delta)
function ClassicTraining.Position(hdl)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local pl, s = session(hdl, false)
  if not pl then return false, s, 0, 0, false end
  local main, sub = positions(pl)
  local zero = R.zeros()
  local trained = not R.equal(s.working, zero) or not R.equal(s.committed, zero)
  return true, s.pos, main, sub or 0, trained
end

-- choose the training position (the main or the sub one): the working training is dropped (every delta 0, the whole
-- Libertad back); COMMIT stores both. ok, libAvail
function ClassicTraining.SetPosition(hdl, pos)
  if not active() then return false end
  hdl = hdl_arg(hdl)
  local p = int(pos)
  local pl, s = session(hdl, false)
  if not pl then return false, s end
  local main, sub = positions(pl)
  if p ~= main and (sub == nil or p ~= sub) then return false, ERR_BAD_ARGS end
  s.pos = p
  s.working = R.zeros()
  pl.ctx.pos = p
  forget_player()
  info(string.format("POSITION %s (id %d): %d (main %d, sub %d), working training dropped", hex(hdl), pl.view.param_id, p,
    main, sub or 0))
  return true, R.available(pl.ctx, s.working)
end

-- the committed Suerte delta of a character (0 when none / the training is off): the Suerte other mods show adds it
function ClassicTraining.LuckDelta(hdl)
  if not ON then return 0 end
  hdl = hdl_arg(hdl)
  if hdl == 0 then return 0 end
  local view = V.view(hdl)
  if not view then return 0 end
  local rival = RivalTraining.view_luck(hdl, view.param_id)
  if rival then return rival end
  local g = V.prm_growth(view.rec)
  if not g then return 0 end
  local ok, f = pcall(store)
  if not ok or not f then return 0 end
  return S.suerte(f, hdl, view.param_id, g)
end

-- ---------------------------------------------------------------------------------------------- the training beans

-- The training replaces the retail beans (content\game\player_training.toml «the training beans»): the stat term is
-- zeroed natively (hook ClassicTraining.BeansGiveNothing) and the team auto-equip skipped (ClassicTraining.NoBeanAutoEquip).

-- CMND_CLASSICTRAINING_BEANS_OFF() -> true while an equipped bean adds nothing (the board's bean slot message)
function ClassicTraining.BeansOff()
  return VRFW.is_on("ClassicTraining.BeansGiveNothing") == true
end

-- retail 0x2086CD04 («Autoequipar judías» get): always off
function ClassicTraining.AutoBeansGet()
  return true, false
end

-- retail 0x799BDB53 («Autoequipar judías» set): ignored (the setting stays as it is; no automatic equip runs anyway)
function ClassicTraining.AutoBeansSet()
  return true
end

-- ---------------------------------------------------------------------------------------------- start

local function start()
  local unknown
  RULES, LOCKED, unknown = R.read_config(cfg)
  if unknown then
    warn(string.format("[training] rule = %q unknown (\"trade\", \"pool\" or \"pairs\"): using trade", unknown))
  end
  local rule = RULES.rule
  local bp = cfg("training.budget_percent", 0)
  if type(bp) ~= "number" or bp ~= bp or bp < 0 or bp > 1000 then
    warn(string.format("[training] budget_percent = %s out of range 0..1000: using 0", tostring(bp)))
    bp = 0
  end
  CS.configure_budget({ percent = bp })
  if not V.ready() then
    err("FindCharaRecord / GetLevel / the character containers not resolved: the training commands answer false")
    return
  end
  ON = true
  local ok, e = pcall(VRFW.state.set, STATE_KEY, 1)
  if not ok then err(STATE_KEY .. ": " .. tostring(e)) end
  info(string.format("commands active (rule %s, floor %d %% of the untrained base, max value %d); Suerte blob %s per slot; the match copies get the trained points (ClassicTraining.TrainedPoints: %s)",
    rule, math.max(0, math.min(100, RULES.floor_percent)), math.max(1, math.min(9999, RULES.max_value)), S.BLOB, VRFW.is_on("ClassicTraining.TrainedPoints") and "on" or "OFF"))
end

-- the save's loading screen: the slot's Suerte store and the sub positions ready before the first training command
-- (the same caches the commands fill on first use)
VRFW.on("match_end", function() forget_player() end)
VRFW.on("game_reset", function() forget_player() end)

VRFW.on("slot_load", function()
  forget_player()
  if not ON then return nil end
  local ok, e = pcall(store)
  if not ok then warn("slot_load: Suerte store: " .. tostring(e)) end
  -- the cards' sub positions (every card of the character index), read here instead of on the first training view
  pcall(sub_position, 0)
  return nil
end)

start()

-- the stats in a match (Suerte, first touch) and the rival match training, in this VM: they call ClassicTraining.LuckDelta
require "lib/stat_effects"
