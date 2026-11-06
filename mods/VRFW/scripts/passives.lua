-- VRFW › the passive engine at run time: one generic interpreter of the blocks (scripts\lib\passives.lua
-- reads them; the block types are content\types\passive_block.toml). Every player on the pitch carries the passives of
-- his character / card ([[VRFW.Character]]), of the game passives he carries (carried_by), the
-- equipment passives (Wears / WearsSet blocks) his worn items meet (VRFW.item.equipped, the user's own players; a
-- rival player: the match equipment a mod declares, lib\match_equipment.lua), the
-- spirit passives of his running summon without armour ([[VRFW.Spirit]]) and the passives another mod
-- grants him through a rule flag (`grant = true`, its level = the flag's value). A spirit or granted passive that
-- starts answers the `carried` trigger; one that ends loses its stacks.
--   * The events the passives name (behaviour-rule triggers, docs/framework/rules.md §3): a passive whose Trigger
--     matches (`by` = whose event, seen from the carrier) and whose conditions hold gains a stack (at most its Stack
--     block's max, 1 without one) and applies its at-once effects (Tension, TensionMax, Refuse); a Reset puts its stacks to 0.
--   * Its lasting effects work while it has stacks (a passive without a trigger: always), × its stacks: technique
--     power on move_power, tension cost on tension_pay, move speed on move_speed, recast on recast, critical
--     chance on crit_check (the
--     triggers its effect types name: `hooks`), stat parameters through the framework's set_stat, pool costs through
--     the cost flag and the stamina recovery through VRFW.resource.set_gain_mult (summed per player over every
--     passive). Those three are summed again only when an input they read changed: a stack (gained, reset, its time
--     over at its scheduled end), a reading of the player list, a goal (Score), a possession change (HasBall, Holder,
--     SetPiece), a clock mark of their Clock blocks (the rule engine's `clock:<mark>`, one per threshold). Only the
--     positions on the pitch have no event: passives whose summed effects read Zone / Near are summed again every
--     0.5 s, and only while one of them is carried.
--   * Traits (Trait blocks: tags, element, position, gender, series, team group, carried moves, keshin / miximax, or
--     relative to the carrier) are read from each player's facts, kept with the player list: Present / Absent / Holder
--     conditions, Count stacks, By trigger filters and the effects' `trait` target filter ask them once per list.
--   * The player list is read again only when something can have changed it (no timer): a match start, a soccer state
--     change out of live play (restarts, halves, substitutions), a declared form's start / end, the signals
--     `vrfw.passives.refresh` and `vrfw.off_pitch.layout_done` ([refresh] of passive_block.toml). A character's
--     record, passive slots and equipment are read once per match (again after a form change or those signals). The
--     spirit and granted passives (a summon, another mod's grant flag) are checked again after an answered event (at
--     most once per frame) and at once after a metamorphosis / summon command, a cut-in's end and a match resource
--     event.
--   * Engine events: `half_start` (a half's clock starts) and `interval:<s>` (every <s> s of the clock while he plays)
--     are fired from the tick for the carriers whose passives name them.
--   * Counters: EventCount blocks count their events per carrier (before the triggers of the same event, back to 0 on
--     breaks_on); Limit blocks keep each passive's counted triggers (cooldown, per match / half); AnyOf / NoneOf hold
--     their condition blocks. Summed effects whose conditions read the tension (tension_gain / tension_pay), an aura
--     (the summon command, a cut-in's end, a form change, a knockdown, a resource event) or a resource are summed again
--     on those events; Clock last_minutes / added_time marks (relative to the half's length) on the tick's clock.
--   * Caps ([[PassiveCap]]): the percents of the passives naming a cap are summed per player and answer and held
--     within it; the other passives multiply.
-- One function per condition type and per kind of effect; nothing here names a character, a passive or a value.
-- Nothing calls the game at load: the subscriptions come from the files.

local L = require "lib/passives"
local G = require "lib/team_groups"
local Actors = require "lib/actors"

require "VRFW/lib/basics"
local info, warn = VRFW.logger("passives")

local u32 = L.u32
local N_SLOTS = 5
-- how often the summed answers of passives that read a position (Zone / Near: no event) are summed again (ms)
local POSITION_EVERY_MS = 500

local DATA = L.data(warn)

local function read(kind, at)
  local ok, v = pcall(VRFW.mem.read, kind, at)
  if ok then return v end
  return nil
end

local SC = DATA.spirit
local SPIRITS_ON = #DATA.spirits > 0 and type(SC.summon_skill) == "number" and type(SC.summon_state) == "number"
if #DATA.spirits > 0 and not SPIRITS_ON then warn("special_passive.toml [spirit] is incomplete: no spirit passive is carried") end
local GRANT_PREFIX = tostring(DATA.grant.flag_prefix or "")
-- the spirit pools ([[VRFW.PassivePool]], lib/passives): their resources and each one's cost flag
local POOL_RESOURCES, POOL_COST_FLAG = {}, {}
for _, pool in ipairs(DATA.pools) do
  POOL_RESOURCES[#POOL_RESOURCES + 1] = pool.resource
  POOL_COST_FLAG[pool.resource] = pool.cost_flag
end
local SHOT_WINDOW_MS = (tonumber(DATA.keeper_duel.shot_window_s) or 8) * 1000
-- the last shoot move is kept (move_power) for KeeperShotPower's shooter side / shooter trait and the shot events
local NEED_LAST_SHOT = DATA.has_keeper_shooter
for _, b in pairs(DATA.blocks) do
  if b.shooter_trait then NEED_LAST_SHOT = true end
end
-- the running summon of every player is read when a block needs it
local NEED_SUMMON = SPIRITS_ON or DATA.has_pool_cost
for _, p in pairs(DATA.passives) do
  for _, b in ipairs(p.effects) do
    if b.meta.apply == "pool" or b.meta.apply == "summon_time" then NEED_SUMMON = true end
  end
end

local function has(list, x)
  for _, y in ipairs(list or {}) do
    if y == x then return true end
  end
  return false
end

-- ---------------------------------------------------------------------------------------------- carried passives

local BUF_ID, BUF_VERSION, BUF_OUT

-- the game passives character `chara` (a character handle) carries: the 5 team slots, read as the match builder
-- 0x1604E90 reads them (unlocked slot, slot reader, rarity version), and his own passive slot as its readers answer
-- it (a mod's answer, such as Signature Passives', or the game's); a set of ids. In a framework signature-only mode
-- (vrfw.passive.slots_off) only the custom passive slot counts
local function slots_off()
  local ok, v = pcall(VRFW.state.get, "vrfw.passive.slots_off")
  return ok and tonumber(v) == 1
end

-- the custom passive slot as its readers answer it (every subscriber's answer); 0 = none
local BUF_SIGNATURE = nil
local function live_signature(chara)
  if not BUF_SIGNATURE then BUF_SIGNATURE = VRFW.mem.buffer("signature_passives_signature_id", 8) end
  VRFW.mem.write("u32", BUF_SIGNATURE, 0)
  if not pcall(VRFW.call, "Passive.SignatureSlotId", BUF_SIGNATURE, chara) then return 0 end
  return read("u32", BUF_SIGNATURE) or 0
end

local function carried_of_chara(chara)
  if not chara or chara == 0 then return {} end
  local ok_rec, rec = pcall(VRFW.character.record, chara)
  if not ok_rec or not rec then return {} end
  if not BUF_ID then
    BUF_ID = VRFW.mem.buffer("signature_passives_passive_id", 4)
    BUF_VERSION = VRFW.mem.buffer("signature_passives_passive_version", 4)
    BUF_OUT = VRFW.mem.buffer("signature_passives_passive_out", 8)
  end
  local rarity = rec.rarity or 0
  local out = {}
  for k = 0, (slots_off() and 0 or N_SLOTS) - 1 do
    local ok, unlocked = pcall(VRFW.call, "Passive.TeamPassiveUnlocked", chara, k, 1)
    if ok and unlocked ~= 0 then
      VRFW.mem.write("u32", BUF_ID, 0)
      if pcall(VRFW.call, "Passive.TeamPassiveId", BUF_ID, chara, k, 1) then
        local id = read("u32", BUF_ID) or 0
        if id ~= 0 then
          local v = id
          VRFW.mem.write("u32", BUF_VERSION, id)
          VRFW.mem.write("ptr", BUF_OUT, 0)
          if pcall(VRFW.call, "Passive.RarityVersion", BUF_OUT, BUF_VERSION, rarity) then
            local p = read("ptr", BUF_OUT) or 0
            if p >= 0x10000 then
              local x = read("u32", p) or 0
              if x ~= 0 then v = x end
            end
          end
          out[v] = true
        end
      end
    end
  end
  local own = live_signature(chara)
  if own ~= 0 then out[own] = true end
  return out
end

local actor_chara = Actors.chara

-- ---------------------------------------------------------------------------------------------- spirits

-- an aura key as an id: a mod aura <mod>.<name> through the framework's names, else the key's crc32 (the game's ids)
local function aura_id(key)
  if type(key) == "string" and key:find(".", 1, true) then
    local ok, id = pcall(VRFW.technique, key)
    if ok and type(id) == "number" and id ~= 0 then return u32(id) end
  end
  return L.id_of(key)
end

local SPIRIT_BY_ID = nil   -- [aura id] = spirit entry
local AURA_SETS = {}       -- [block key] = { [aura id] = true }: the auras a SpiritsOut block counts

local function spirit_by_id()
  if SPIRIT_BY_ID then return SPIRIT_BY_ID end
  SPIRIT_BY_ID = {}
  for _, e in ipairs(DATA.spirits) do
    local keys = { e.aura }
    for _, k in ipairs(e.aliases) do keys[#keys + 1] = k end
    for _, k in ipairs(keys) do
      local id = aura_id(k)
      if id and id ~= 0 then SPIRIT_BY_ID[id] = e else warn(e.where .. ": no aura " .. tostring(k)) end
    end
  end
  return SPIRIT_BY_ID
end

-- the auras a SpiritsOut block names: its own list and its family's
local function aura_set(b)
  local set = AURA_SETS[b.key]
  if set then return set end
  set = {}
  local keys = {}
  for _, k in ipairs(b.v.auras or {}) do keys[#keys + 1] = k end
  if b.v.family ~= "" then
    local f = L.lookup(DATA.families, b.mod, b.v.family)
    if f then
      for _, k in ipairs(f.auras) do keys[#keys + 1] = k end
    else
      warn(b.where .. ": no spirit family " .. tostring(b.v.family))
    end
  end
  for _, k in ipairs(keys) do
    local id = aura_id(k)
    if id and id ~= 0 then set[id] = true end
  end
  AURA_SETS[b.key] = set
  return set
end

-- the actor's running summon (aura id), 0 = none
local function summon_of(actor)
  if (read("u8", actor + SC.summon_state) or 0) ~= SC.summon_active then return 0 end
  return read("u32", actor + SC.summon_skill) or 0
end

-- the actor's unit wears an armour (its aura bits)
local function armoured(actor)
  if type(SC.unit_aura_bits) ~= "number" then return false end
  local ok, unit = pcall(VRFW.call, "Match.ActorUnit", actor)
  if not ok or type(unit) ~= "number" or unit < 0x10000 then return false end
  return bit32.band(read("u8", unit + SC.unit_aura_bits) or 0, SC.armour_bits or 0) ~= 0
end

-- the pool resource of player h's running summon (a mod's per-aura resources), nil = it runs on its timer
local function pool_of(h)
  if not h.summon or h.summon == 0 then return nil end
  for _, res in ipairs(POOL_RESOURCES) do
    local ok, v = pcall(VRFW.resource.get, res, h.handle, h.summon)
    if ok and type(v) == "table" and type(v.max) == "number" and v.max > 0 then return res end
  end
  return nil
end

-- seconds added to player h's running summon timer (the engine's own time left and full time)
local function add_summon_time(h, seconds)
  if not seconds or seconds <= 0 or not h.actor or not h.summon or h.summon == 0 then return end
  if type(SC.summon_left) ~= "number" or type(SC.summon_full) ~= "number" then return end
  local left, full = read("f32", h.actor + SC.summon_left), read("f32", h.actor + SC.summon_full)
  if type(left) ~= "number" or type(full) ~= "number" then return end
  pcall(VRFW.mem.write, "f32", h.actor + SC.summon_left, left + seconds)
  pcall(VRFW.mem.write, "f32", h.actor + SC.summon_full, full + seconds)
  info(string.format("actor 0x%X: summon time +%.1f s", h.handle, seconds))
end

local function grant_flag(p, hdl) return string.format("%s.%s.%d", GRANT_PREFIX, p.key, hdl) end

-- ---------------------------------------------------------------------------------------------- players on the pitch

local BY_CHARACTER, BY_CARD = nil, nil

local function index_characters()
  BY_CHARACTER, BY_CARD = {}, {}
  for _, e in ipairs(DATA.characters) do
    if e.card ~= "" then
      local c = L.id_of(e.card)
      if c and c ~= 0 then BY_CARD[c] = e.passives end
    else
      local base = L.character_id(e.character)
      if base and base ~= 0 then BY_CHARACTER[base] = e.passives else warn(e.where .. ": no character " .. tostring(e.character)) end
    end
  end
end

-- the equipment of a player's character handle: { [item id] = true } and the 4 slots, nil = not the user's player;
-- `given` = 4 slots worn for this match only (a rival player's match equipment) instead of the handle's
local function worn_of(chara, given)
  local a, b, c, d
  if given then
    a, b, c, d = given[1], given[2], given[3], given[4]
  else
    if not chara or chara == 0 then return nil end
    local ok
    ok, a, b, c, d = pcall(VRFW.item.equipped, chara)
    if not ok or a == nil then return nil end
  end
  local slots = { a, b, c, d }
  local set = {}
  for _, it in ipairs(slots) do
    if it and it ~= 0 then set[u32(it)] = true end
  end
  -- the exclusive count of the worn sets: a piece counts for one set only (VRFW.item.resolve_sets)
  local okR, counts = pcall(VRFW.item.resolve_sets, a, b, c, d)
  return { set = set, slots = slots, counts = (okR and type(counts) == "table") and counts or nil }
end

local ITEM_IDS, SET_IDS, FAMILY_IDS = {}, {}, {}

-- a Wears block's items as ids (internal names and <mod>.<name> keys: crc32 of the text, the item ids' rule)
local function items_of(b)
  local ids = ITEM_IDS[b.key]
  if ids then return ids end
  ids = {}
  for _, k in ipairs(b.v.items or {}) do
    local id = L.id_of(k)
    if id and id ~= 0 then ids[id] = true end
  end
  ITEM_IDS[b.key] = ids
  return ids
end

-- an equipment set's members (the item type's [[VRFW.EquipmentSet]]), nil = unknown set
local function set_of(name)
  local s = SET_IDS[name]
  if s ~= nil then return s or nil end
  local ok, list = pcall(VRFW.item.set_members, name)
  if ok and type(list) == "table" then
    s = {}
    for _, id in ipairs(list) do s[u32(id)] = true end
  else
    warn("no equipment set " .. tostring(name) .. " (its passives never hold)")
    s = false
  end
  SET_IDS[name] = s
  return s or nil
end

-- a technique family's moves, nil = unknown family
local function family_of(name)
  local s = FAMILY_IDS[name]
  if s ~= nil then return s or nil end
  local ok, list = pcall(VRFW.technique_family, name)
  if ok and type(list) == "table" then
    s = {}
    for _, id in ipairs(list) do s[u32(id)] = true end
  else
    -- a family of an optional mod that is off: its passives simply never hold
    info("no technique family " .. tostring(name) .. " (its passives never hold)")
    s = false
  end
  FAMILY_IDS[name] = s
  return s or nil
end

local function wears_ok(v, h, b)
  if not h.worn then return false end
  local ids = items_of(b)
  for id in pairs(h.worn.set) do
    if ids[id] then return true end
  end
  return false
end

local function wears_set_ok(v, h)
  if not h.worn then return false end
  local members = set_of(v.set)
  if not members then return false end
  if h.worn.counts and type(v.set) == "string" and v.set:find(".", 1, true) then
    return (h.worn.counts[v.set] or 0) >= (v.pieces or 2)
  end
  local n = 0
  for _, it in ipairs(h.worn.slots) do
    if it and it ~= 0 and members[u32(it)] then n = n + 1 end
  end
  return n >= (v.pieces or 2)
end

-- the equipment conditions of a worn passive hold for this player (the other conditions are checked when it counts)
local function worn_holds(p, h)
  for _, b in ipairs(p.conditions) do
    if b.type == "Wears" and not wears_ok(b.v, h, b) then return false end
    if b.type == "WearsSet" and not wears_set_ok(b.v, h) then return false end
  end
  return true
end

local ANY_CARRIED = false
local CARRIABLE = {}   -- the passives with carried_by, in the order the player list walks DATA.passives
for _, p in pairs(DATA.passives) do
  if #p.carried_by > 0 then
    ANY_CARRIED = true
    CARRIABLE[#CARRIABLE + 1] = p
  end
end

local PLAYERS, PLAYERS_AT, CARRIED = nil, -1e12, {}
local BY_HANDLE = {}          -- [handle] = his entry of PLAYERS
local DYNAMIC_STALE = false   -- the spirit / granted passives are read again at the next use of the list
local DYNAMIC_FORCE = false   -- ... at once, even in the frame they were read last
local FRAME = 0               -- the frames seen (tick): the spirit / granted passives are read at most once per frame
local DYNAMIC_FRAME = -1      -- the frame they were read last
local DYNAMIC = {}   -- [handle] = { [passive key] = passive }: his spirit and granted passives at the last reading
local TICK_NOW = 0            -- VRFW.now() of the last tick (ms)
local DYNAMIC_AT = -1e12      -- TICK_NOW of the last reading of the spirit / granted passives
local DYNAMIC_EVERY_MS = 100  -- an event reads them again at most this often (a forced reading: at once)
local ANSWER_EPOCH = 0        -- numbers the states of the answers' inputs: a kept answer of another number is stale
local CHARA_STATIC = {}       -- [character handle] = { carried, level, worn }: read once per match (see chara_static)
local CARD_POSITION = {}      -- [card id] = the card's position number (game data)
local NONE = {}               -- an empty set shared by readers that never write it
-- the state and helpers of the condition types that keep their own bookkeeping (one table: the chunk's local limit)
local CS = {
  counts = {},             -- [carrier handle][EventCount block key] = { n, half }
  limits = {},             -- [carrier handle][passive key] = { at, n, half, n_half }: the triggers a Limit block let count
  aura_every_ms = 50,      -- a unit's aura bits are read at most this often
  aura_bits = {},          -- [handle] = { at, bits }
  aura_mask = {},          -- [block key] = the bits of its kinds
  wheel = nil,             -- [element name] = the element name it beats
  half = { half = nil, length = 0 },   -- the running half's regular length (game seconds)
  clock_dynamic = {},      -- [seconds before the half's regular end] = true: the Clock last_minutes / added_time marks
  clock_prev = nil,        -- the clock at the last tick
  trait_characters_of = {},   -- [trait key] = { [chara_base id] = true }
}
local on_carried     -- (player, passive): a spirit / granted passive starts (set below)
local on_dropped     -- (player, passive): it ends
local ANY_DYNAMIC = SPIRITS_ON or (GRANT_PREFIX ~= "" and #DATA.grantable > 0)

-- the passive level of a character handle: the first level of [levels] from_player_level his player level reached
-- (his passive level, his player level)
local function passive_level(chara)
  local ok, rec = pcall(VRFW.character.record, chara)
  local lv = (ok and rec and rec.level) or 1
  local out = 1
  for i, need in ipairs(DATA.levels) do
    if lv >= need then out = i end
  end
  return out, lv
end

-- what a character handle's record, passive slots and equipment give, read once per match: a lineup change reads only
-- the players new to the pitch (cleared at a match start, a form change and the refresh signals)
local function chara_static(chara)
  local s = CHARA_STATIC[chara]
  if s then return s end
  local lvl, player_lv = passive_level(chara)
  s = { carried = ANY_CARRIED and carried_of_chara(chara) or nil, level = lvl, player_level = player_lv,
    worn = #DATA.worn > 0 and worn_of(chara) or nil }
  CHARA_STATIC[chara] = s
  return s
end

-- a card's position number (game data, kept per card)
local function card_position(card)
  local pos = CARD_POSITION[card]
  if pos == nil then
    local ci = card ~= 0 and VRFW.character.card(card) or nil
    pos = ci and ci.position or 0
    CARD_POSITION[card] = pos
  end
  return pos
end

-- his passives: the ones of his character / card, carried game passives and worn items, then the spirit / granted ones;
-- e.engine = the triggers of the engine's own events (half_start, interval) among them, in the same order
local function compose(e)
  local list = {}
  for _, p in ipairs(e.base) do list[#list + 1] = p end
  local keys = {}
  for k in pairs(e.dynamic) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do list[#list + 1] = e.dynamic[k] end
  e.passives = list
  local engine = {}
  for _, p in ipairs(list) do
    for _, b in ipairs(p.triggers) do
      if b.v.on == "half_start" or b.v.on == "interval" then
        engine[#engine + 1] = { p = p, b = b, key = p.key .. ":" .. tostring(b.v.arg) }
      end
    end
  end
  e.engine = engine
end

-- reads player e's spirit passives (his running summon without armour) and the passives other mods grant him (their
-- level = the flag's value); true when they changed since the last reading (then e.dynamic = { [passive key] =
-- passive }, e.levels = { [passive key] = level } and e.passives are new tables; else nothing is allocated)
local function read_dynamic(e)
  local summon, spirit = 0, 0
  if NEED_SUMMON then summon = summon_of(e.actor) end
  if SPIRITS_ON and summon ~= 0 then
    local sp = spirit_by_id()[summon]
    if sp and not armoured(e.actor) then spirit = summon end
  end
  local same = e.dynamic ~= nil and summon == e.summon and spirit == e.spirit
  e.summon, e.spirit = summon, spirit
  local lv = e.grant_lv
  if GRANT_PREFIX ~= "" then
    for i, name in ipairs(e.grant_flags) do
      local x = tonumber(VRFW.flag(name)) or 0
      if x ~= lv[i] then lv[i], same = x, false end
    end
  end
  if same then return false end
  local dyn, levels = {}, {}
  if spirit ~= 0 then
    for _, p in ipairs(spirit_by_id()[spirit].passives) do dyn[p.key] = p end
  end
  for i, p in ipairs(DATA.grantable) do
    local x = lv[i] or 0
    if x > 0 then
      dyn[p.key] = p
      levels[p.key] = math.floor(x)
    end
  end
  e.dynamic, e.levels = dyn, levels
  compose(e)
  return true
end

-- the spirit / granted passives that started or ended since the last reading
local function settle_dynamic(out)
  local seen = {}
  for _, e in ipairs(out) do
    seen[e.handle] = true
    local before = DYNAMIC[e.handle] or {}
    for k, p in pairs(e.dynamic) do
      if not before[k] then on_carried(e, p) end
    end
    for k, p in pairs(before) do
      if not e.dynamic[k] then on_dropped(e, p) end
    end
    DYNAMIC[e.handle] = e.dynamic
  end
  for hdl in pairs(DYNAMIC) do
    if not seen[hdl] then DYNAMIC[hdl] = nil end
  end
end

-- every player on the pitch: { handle, team, side, element (word), position (number), card, chara, passives }
local function players()
  if PLAYERS then
    -- (read at most once per frame and every DYNAMIC_EVERY_MS, unless an event that starts or ends them asked for it)
    if DYNAMIC_STALE and (DYNAMIC_FORCE or (DYNAMIC_FRAME ~= FRAME and TICK_NOW - DYNAMIC_AT >= DYNAMIC_EVERY_MS)) then
      DYNAMIC_STALE, DYNAMIC_FORCE, DYNAMIC_FRAME, DYNAMIC_AT = false, false, FRAME, TICK_NOW
      local any = false
      for _, e in ipairs(PLAYERS) do
        if read_dynamic(e) then any = true end
      end
      if any then
        ANSWER_EPOCH = ANSWER_EPOCH + 1
        settle_dynamic(PLAYERS)
      end
    end
    return PLAYERS
  end
  DYNAMIC_STALE, DYNAMIC_FORCE, DYNAMIC_FRAME, DYNAMIC_AT = false, false, FRAME, TICK_NOW
  ANSWER_EPOCH = ANSWER_EPOCH + 1
  BY_HANDLE = {}
  -- a mode without player passives (vrfw.passive.all_off, a mod's [[VRFW.NoPassives]]): nobody carries a passive
  local okoff, off = pcall(VRFW.state.get, "vrfw.passive.all_off")
  if okoff and tonumber(off) == 1 then
    PLAYERS, PLAYERS_AT = {}, math.max(PLAYERS_AT, 0) + 1
    return PLAYERS
  end
  if BY_CHARACTER == nil then index_characters() end
  local off_mode = slots_off()
  local out = {}
  CARRIED = {}
  local actors = Actors.list()
  -- the match equipment a mod declares for the rival players of this match (lib\match_equipment.lua), per card
  local rival_worn = nil
  if #DATA.worn > 0 then
    local okM, t = pcall(function() return require("VRFW/lib/match_equipment").running() end)
    rival_worn = okM and t or nil
  end
  if #actors > 0 then
    for _, entry in ipairs(actors) do
      local actor, hdl = entry.address, entry.handle
      local a = VRFW.actor(hdl)
      if a and a.team ~= nil then
        local card = a.card and u32(a.card) or 0
        local st = chara_static(actor_chara(actor))
        local base = {}
        -- in a signature-only mode the per-character passives are off: only what his slots carry counts
        if not off_mode then
          for _, p in ipairs(BY_CARD[card] or BY_CHARACTER[u32(a.chara or 0)] or NONE) do base[#base + 1] = p end
        end
        if ANY_CARRIED then
          CARRIED[hdl] = st.carried
          for _, p in ipairs(CARRIABLE) do
            for _, id in ipairs(p.carried_by) do
              if CARRIED[hdl][id] then
                base[#base + 1] = p
                break
              end
            end
          end
        end
        local grant_flags = {}
        if GRANT_PREFIX ~= "" then
          for i, p in ipairs(DATA.grantable) do grant_flags[i] = grant_flag(p, hdl) end
        end
        local entry = { handle = hdl, team = a.team, side = a.side, element = a.element, position = card_position(card),
          card = card, chara = a.chara, base = base, carried = CARRIED[hdl] or NONE,
          level = st.level, player_level = st.player_level, levels = NONE, actor = actor, summon = 0, spirit = 0, dynamic = nil,
          grant_flags = grant_flags, grant_lv = {} }
        -- equipment passives: the user's own players, by what they wear; a rival player, by his match equipment
        if #DATA.worn > 0 then
          entry.worn = st.worn
          if not entry.worn and a.side == "rival" and rival_worn and rival_worn[card] then
            entry.worn = worn_of(nil, rival_worn[card])
          end
          if entry.worn then
            for _, p in ipairs(DATA.worn) do
              if worn_holds(p, entry) then base[#base + 1] = p end
            end
          end
        end
        read_dynamic(entry)
        out[#out + 1] = entry
        if BY_HANDLE[hdl] == nil then BY_HANDLE[hdl] = entry end
      end
    end
  end
  -- PLAYERS_AT numbers the readings: the trait answers, move slots and plates are kept per reading
  PLAYERS, PLAYERS_AT = out, math.max(PLAYERS_AT, 0) + 1
  settle_dynamic(out)
  return out
end

local function player(hdl)
  players()
  return BY_HANDLE[hdl]
end

-- the first player list of a match reads every player's record, passive slots and equipment: the tick reads them
-- ahead, WARM_PER_FRAME players per frame, and the summed effects and move speed answers wait until they are read
local WARM_PER_FRAME = 2
local WARM = nil   -- nil = not started, { list, next } = running, false = done (until the next match start)

-- one frame of the warm-up; true while it ran this frame
local function warm_step()
  if WARM == false then return false end
  if PLAYERS then
    WARM = false
    return false
  end
  if WARM == nil then
    local okoff, off = pcall(VRFW.state.get, "vrfw.passive.all_off")
    if okoff and tonumber(off) == 1 then
      WARM = false
      return false
    end
    local list = Actors.list()
    -- (no actors yet: nothing to read ahead)
    if #list == 0 then return false end
    WARM = { list = list, next = 1 }
  end
  local done = 0
  while WARM.next <= #WARM.list and done < WARM_PER_FRAME do
    local entry = WARM.list[WARM.next]
    WARM.next = WARM.next + 1
    local a = VRFW.actor(entry.handle)
    if a and a.team ~= nil then
      chara_static(actor_chara(entry.address))
      card_position(a.card and u32(a.card) or 0)
      done = done + 1
    end
  end
  if WARM.next > #WARM.list then WARM = false end
  return true
end

local function warming() return WARM ~= nil and WARM ~= false and PLAYERS == nil end

-- ---------------------------------------------------------------------------------------------- player facts / traits

local MOVE_IDS = {}

-- the moves a block names (Move, Trait `moves`) as ids
local function moves_of(b)
  local ids = MOVE_IDS[b.key]
  if ids then return ids end
  ids = {}
  for _, m in ipairs(b.v.moves) do
    local ok, id = pcall(VRFW.technique, m)
    if ok and type(id) == "number" and id ~= 0 then ids[u32(id)] = true else ids[L.id_of(m) or 0] = true end
  end
  MOVE_IDS[b.key] = ids
  return ids
end

local CHARACTER_FACTS = {}   -- [chara_base id] = { gender, series, teams = { [belong team] = true } }
local TAGS_OF = nil          -- [chara_base id] = { [tag] = true }
local MOVES_OF = {}          -- [handle] = { at = the player list's reading, set = { [move id] = true } }
local PLATES = nil           -- { at = the player list's reading, map = VRFW.extra_slot.players() }
local UNIT_MOVES = DATA.unit_moves

local function character_facts(base)
  local f = CHARACTER_FACTS[base]
  if f then return f end
  f = { teams = {} }
  local ok, c = pcall(VRFW.character.character, base)
  if ok and type(c) == "table" then
    f.gender, f.series = c.gender, c.series
    for _, t in pairs(type(c.teams) == "table" and c.teams or {}) do
      if type(t) == "number" and t ~= 0 then f.teams[u32(t)] = true end
    end
  end
  CHARACTER_FACTS[base] = f
  return f
end

-- the archetype tags of a character ([[CharacterTags]]: a later entry of the same character replaces an earlier one)
local function tags_of(base)
  if TAGS_OF == nil then
    TAGS_OF = {}
    for _, e in ipairs(DATA.character_tags) do
      local id = L.character_id(e.character)
      if id and id ~= 0 then
        local set = {}
        for _, t in ipairs(e.tags) do set[t] = true end
        TAGS_OF[id] = set
      end
    end
  end
  return TAGS_OF[base] or {}
end

-- the moves in the player's match move slots (kept with the player list)
local function moves_of_player(e)
  local m = MOVES_OF[e.handle]
  if m and m.at == PLAYERS_AT then return m.set end
  local set = {}
  local ok, unit = pcall(VRFW.call, "Match.ActorUnit", e.actor)
  if ok and type(unit) == "number" and unit >= 0x10000 and type(UNIT_MOVES.first) == "number" then
    for k = 0, (UNIT_MOVES.count or 0) - 1 do
      local slot = unit + UNIT_MOVES.first + k * UNIT_MOVES.stride
      local kind = read("u8", slot + UNIT_MOVES.kind) or 0
      local id = read("u32", kind == 3 and (slot + UNIT_MOVES.id_kind3) or slot) or 0
      if id ~= 0 then set[u32(id)] = true end
    end
  end
  MOVES_OF[e.handle] = { at = PLAYERS_AT, set = set }
  return set
end

-- his plates this match: keshin (an aura of type 0 on his aura plate), miximax (a move on his mix plate); kept with
-- the player list
local function plates_of(e)
  if not PLATES or PLATES.at ~= PLAYERS_AT then
    local ok, map = pcall(VRFW.extra_slot.players)
    PLATES = { at = PLAYERS_AT, map = (ok and type(map) == "table") and map or {} }
  end
  local x = PLATES.map[e.handle]
  if type(x) ~= "table" then return false, false end
  local aura = x.own_skill or x.skill or 0
  local keshin = false
  if aura ~= 0 then
    local okT, kind = pcall(VRFW.extra_slot.aura_type, aura)
    keshin = okT and kind == 0
  end
  return keshin, (x.mix or 0) ~= 0
end

local SERIES_IDS = {}   -- [series name] = the index's series number (false = unknown)

local function series_id(name)
  local v = SERIES_IDS[name]
  if v == nil then
    local ok, n = pcall(VRFW.character.series_of, name)
    v = (ok and n) or false
    SERIES_IDS[name] = v
  end
  return v or nil
end

local function any_in(list, set)
  for _, x in ipairs(list) do
    if set[x] then return true end
  end
  return false
end

local function shares(a, b)
  for k in pairs(a) do
    if b[k] then return true end
  end
  return false
end

-- a Trait's `characters`, resolved once
function CS.trait_characters(t)
  local set = CS.trait_characters_of[t.key]
  if set then return set end
  set = {}
  for _, c in ipairs(t.v.characters or NONE) do
    local id = L.character_id(c)
    if id and id ~= 0 then set[u32(id)] = true else warn(t.where .. ": no character " .. tostring(c)) end
  end
  CS.trait_characters_of[t.key] = set
  return set
end

-- player `e` belongs to Trait block `t`; `h` = the carrier (the relative keys compare with him)
local function trait_ok_uncached(t, h, e)
  local v = t.v
  local base = u32(e.chara or 0)
  if v.characters and #v.characters > 0 and not CS.trait_characters(t)[base] then return false end
  if #v.tags > 0 and not any_in(v.tags, tags_of(base)) then return false end
  if #v.elements > 0 and not has(v.elements, e.element) then return false end
  if #v.positions > 0 then
    local ok = false
    for _, w in ipairs(v.positions) do
      if DATA.positions[w] == e.position then ok = true end
    end
    if not ok then return false end
  end
  local facts = character_facts(base)
  if v.gender ~= "" and facts.gender ~= DATA.genders[v.gender] then return false end
  if #v.series > 0 then
    local ok = false
    for _, name in ipairs(v.series) do
      if series_id(name) == facts.series then ok = true end
    end
    if not ok then return false end
  end
  if #v.team_groups > 0 then
    local ok = false
    for _, g in ipairs(v.team_groups) do
      if G.members(g)[base] then ok = true end
    end
    if not ok then return false end
  end
  if #v.families > 0 or #v.moves > 0 then
    local carried = moves_of_player(e)
    local ok = false
    for _, name in ipairs(v.families) do
      local f = family_of(name)
      if f and shares(carried, f) then ok = true end
    end
    if not ok and #v.moves > 0 then ok = shares(carried, moves_of(t)) end
    if not ok then return false end
  end
  if v.keshin or v.miximax then
    local keshin, miximax = plates_of(e)
    if (v.keshin and not keshin) or (v.miximax and not miximax) then return false end
  end
  if v.same_element_as_holder and e.element ~= h.element then return false end
  if v.same_saga_as_holder or v.same_team_as_holder or v.same_team_group_as_holder then
    local holder = character_facts(u32(h.chara or 0))
    if v.same_saga_as_holder and (holder.series == nil or holder.series ~= facts.series) then return false end
    local same_team = shares(holder.teams, facts.teams)
    if v.same_team_as_holder and not same_team then return false end
    if v.same_team_group_as_holder and not same_team and not shares(G.groups_of(u32(h.chara or 0)), G.groups_of(base)) then
      return false
    end
  end
  return true
end

local TRAIT_MEMO, TRAIT_MEMO_AT = {}, nil

-- trait_ok_uncached, kept per (trait, carrier, player) until the player list is refreshed: [trait][carrier][player]
local function trait_ok(t, h, e)
  if not t then return false end
  if TRAIT_MEMO_AT ~= PLAYERS_AT then TRAIT_MEMO, TRAIT_MEMO_AT = {}, PLAYERS_AT end
  local by_trait = TRAIT_MEMO[t.key]
  if by_trait == nil then
    by_trait = {}
    TRAIT_MEMO[t.key] = by_trait
  end
  local by_carrier = by_trait[h.handle]
  if by_carrier == nil then
    by_carrier = {}
    by_trait[h.handle] = by_carrier
  end
  local r = by_carrier[e.handle]
  if r == nil then
    r = trait_ok_uncached(t, h, e)
    by_carrier[e.handle] = r
  end
  return r
end

-- player `e` is on `side` (team / opponents / any) seen from carrier `h`; with `others` the carrier himself is not
local function on_side(side, others, h, e)
  if others and e.handle == h.handle then return false end
  if side == "team" then return e.team == h.team end
  if side == "opponents" then return e.team ~= h.team end
  return true
end

-- how many players of a Present / Count block's Trait are on the pitch, seen from carrier h
local function count_trait(b, h)
  local n = 0
  for _, e in ipairs(players()) do
    if on_side(b.v.side, b.v.others, h, e) and trait_ok(b.trait, h, e) then n = n + 1 end
  end
  return n
end

-- ---------------------------------------------------------------------------------------------- value out of a match

-- A passive's value now for a player outside a match (a menu's passive card): its Count blocks counted over the lineup
-- the caller names (character handles of the players on the pitch), × its first effect's amount. Known only for a
-- passive without triggers or other conditions whose Count blocks count his own team by traits the character index
-- answers (no carried moves, families, keshin or miximax).
--   CMND_VRFW_PASSIVE_CURRENT_VALUE(game passive id, charaHdl, "hdl,hdl,…") -> known, value, unit ("percent" / "flat"),
--   count, max
PassiveValue = PassiveValue or {}

do   -- (its own block: the main chunk is near Lua's 200-local limit)
  local BY_GAME_PASSIVE = nil   -- [game passive id] = passive (its GamePassive block)

  local function passive_of_game_id(id)
    if BY_GAME_PASSIVE == nil then
      BY_GAME_PASSIVE = {}
      for _, p in pairs(DATA.passives) do
        local gid = p.slot and L.id_of(p.slot.v.passive)
        if gid and gid ~= 0 then BY_GAME_PASSIVE[gid] = p end
      end
    end
    return BY_GAME_PASSIVE[id]
  end

  -- a character handle as the facts a trait reads (nil when its card is unknown)
  local function lineup_entry(hdl)
    local okr, r = pcall(VRFW.character.record, hdl)
    local card = (okr and type(r) == "table") and u32(r.param or 0) or 0
    if card == 0 then return nil end
    local okc, c = pcall(VRFW.card, card)
    if not okc or type(c) ~= "table" then return nil end
    return { handle = hdl, team = 0, card = card, chara = c.chara, element = c.element, position = card_position(card),
      level = passive_level(hdl) }
  end

  local function index_trait(t)
    local v = t and t.v
    return v ~= nil and #v.families == 0 and #v.moves == 0 and not v.keshin and not v.miximax
  end

  function PassiveValue.CmdCurrent(id, hdl, lineup)
    local p = passive_of_game_id(u32(id or 0))
    hdl = u32(hdl or 0)
    if not p or hdl == 0 or #p.triggers > 0 or #p.conditions > 0 or #p.counts == 0 or type(lineup) ~= "string" then
      return false, 0, "", 0, 0
    end
    local effect = nil
    for _, b in ipairs(p.effects) do
      if b.meta.amount_key and type(b.v[b.meta.amount_key]) == "number" then
        effect = b
        break
      end
    end
    if not effect then return false, 0, "", 0, 0 end
    for _, b in ipairs(p.counts) do
      if b.type ~= "Count" or b.v.side ~= "team" or not index_trait(b.trait) then return false, 0, "", 0, 0 end
    end
    local h = lineup_entry(hdl)
    if not h then return false, 0, "", 0, 0 end
    local players = {}
    for word in lineup:gmatch("%d+") do
      local e = lineup_entry(u32(tonumber(word)))
      if e then players[#players + 1] = e end
    end
    if #players == 0 then return false, 0, "", 0, 0 end
    local n, max = 1, 1
    for _, b in ipairs(p.counts) do
      local c = 0
      for _, e in ipairs(players) do
        if on_side(b.v.side, b.v.others, h, e) and trait_ok_uncached(b.trait, h, e) then c = c + 1 end
      end
      n, max = n * math.min(c, b.v.max), max * b.v.max
    end
    local unit = (effect.meta.amount_key == "percent" or effect.v.mode == "percent") and "percent" or "flat"
    -- the effect's amount at his passive level (as the match sums it), × the count
    local v, per = effect.v[effect.meta.amount_key], effect.v.value_by_level
    if type(per) == "table" and #per > 0 then v = per[math.min(math.max(h.level or 1, 1), #per)] or v end
    return true, v * n, unit, n, max
  end

  -- built at load (files and the character index only) instead of on the first passive card drawn: the game passive
  -- ids, the archetype tags and the members of the team groups the Count traits name
  pcall(passive_of_game_id, 0)
  pcall(tags_of, 0)
  for _, p in pairs(DATA.passives) do
    for _, b in ipairs(p.counts) do
      local v = b.trait and b.trait.v
      for _, g in ipairs(v and v.team_groups or {}) do pcall(G.members, g) end
    end
  end
end

-- the last restart's kicker and kind (set_piece) until another player has the ball (possession): SetPiece blocks
local SET_PIECE = nil
local NEED_SET_PIECE = false
for _, b in pairs(DATA.blocks) do
  if b.type == "SetPiece" then NEED_SET_PIECE = true end
end

local BALL = { at = -1e12, handle = 0 }
local BALL_EVERY_MS = 100

-- the ball owner's handle (0 = nobody), read at most every BALL_EVERY_MS
local function ball_owner()
  local now = VRFW.now()
  if now - BALL.at < BALL_EVERY_MS then return BALL.handle end
  BALL.at = now
  local ok, hdl = pcall(VRFW.ai.ball)
  BALL.handle = (ok and type(hdl) == "number") and u32(hdl) or 0
  return BALL.handle
end

-- ---------------------------------------------------------------------------------------------- stacks

local STACKS = {}   -- [carrier handle][passive key] = { n, at, half }
local DIRTY = true
local NEXT_EXPIRY = math.huge   -- the earliest end of a timed stack (VRFW.now ms): the sums change then

local function current_half(ev)
  local m = (ev and ev.match) or VRFW.match() or {}
  return m.half
end

-- whose spirits a SpiritsOut block counts, seen from carrier h
local COUNT_WHO = {
  teammates = function(h, e) return e.team == h.team and e.handle ~= h.handle end,
  team = function(h, e) return e.team == h.team end,
  opponents = function(h, e) return e.team ~= h.team end,
}

-- the family / partner count of a SpiritsOut block for carrier h: the players with one of its spirits out
local function spirits_out(h, b)
  local set, who = aura_set(b), COUNT_WHO[b.v.who] or COUNT_WHO.teammates
  local n = 0
  for _, e in ipairs(PLAYERS or {}) do
    if e.spirit ~= 0 and set[e.spirit] and who(h, e) then n = n + 1 end
  end
  return math.min(n, b.v.max or n)
end

-- the stacks of the passive for carrier `h` (always 1 without a trigger), 0 = off
local function stacks(h, p, ev)
  if #p.triggers == 0 then return 1 end
  local s = STACKS[h.handle] and STACKS[h.handle][p.key]
  if not s or s.n <= 0 then return 0 end
  local st = p.stack and p.stack.v
  if st and st.duration_s > 0 and VRFW.now() - s.at > st.duration_s * 1000 then
    s.n, DIRTY = 0, true
    return 0
  end
  if st and st.per_half and s.half ~= nil and current_half(ev) ~= s.half then
    s.n, DIRTY = 0, true
    return 0
  end
  return s.n
end

-- the passive's strength for carrier `h`: its stacks × its SpiritsOut / Count counts, 0 = off
local function level(h, p, ev)
  local n = stacks(h, p, ev)
  for _, b in ipairs(p.counts) do
    if n <= 0 then break end
    if b.type == "Count" then
      n = n * math.min(count_trait(b, h), b.v.max)
    else
      n = n * spirits_out(h, b)
    end
  end
  return n
end

-- a passive's conditions with the parts of its AnyOf / NoneOf blocks (kept on the passive)
function CS.all_conditions(p)
  local all = p.all_conditions
  if all == nil then
    all = L.conditions_of(p)
    p.all_conditions = all
  end
  return all
end

-- a counted trigger of a passive with a Limit block: its time and counts
function CS.note_limit(h, p, ev)
  if p.has_limit == nil then
    p.has_limit = false
    for _, b in ipairs(CS.all_conditions(p)) do
      if b.type == "Limit" then p.has_limit = true end
    end
  end
  if not p.has_limit then return end
  local by_h = CS.limits[h.handle]
  if by_h == nil then
    by_h = {}
    CS.limits[h.handle] = by_h
  end
  local half = current_half(ev)
  local l = by_h[p.key]
  if l == nil then
    l = { at = 0, n = 0, half = half, n_half = 0 }
    by_h[p.key] = l
  end
  if l.half ~= half then l.half, l.n_half = half, 0 end
  l.at, l.n, l.n_half = VRFW.now(), l.n + 1, l.n_half + 1
end

local function gain(h, p, ev)
  CS.note_limit(h, p, ev)
  STACKS[h.handle] = STACKS[h.handle] or {}
  local s = STACKS[h.handle][p.key] or { n = 0 }
  stacks(h, p, ev)
  local max = p.stack and p.stack.v.max or 1
  if max == 0 or s.n < max then s.n = s.n + 1 end
  s.at, s.half = VRFW.now(), current_half(ev)
  STACKS[h.handle][p.key] = s
  DIRTY = true
  local st = p.stack and p.stack.v
  if st and st.duration_s > 0 then NEXT_EXPIRY = math.min(NEXT_EXPIRY, s.at + st.duration_s * 1000) end
end

local function reset(h, p)
  local s = STACKS[h.handle] and STACKS[h.handle][p.key]
  if s and s.n > 0 then
    s.n, DIRTY = 0, true
  end
end

-- ---------------------------------------------------------------------------------------------- whose / whom

-- event player `who` (an actor table or nil) seen from carrier `h`
local BY = {
  self = function(h, who) return who ~= nil and u32(who.handle) == h.handle end,
  teammate = function(h, who) return who ~= nil and who.team == h.team and u32(who.handle) ~= h.handle end,
  team = function(h, who) return who ~= nil and who.team == h.team end,
  opponent = function(h, who) return who ~= nil and who.team ~= nil and who.team ~= h.team end,
  anyone = function() return true end,
}

-- player `t` is a target of effect values `v` of carrier `h`
local TARGET = {
  self = function(h, t) return t.handle == h.handle end,
  teammates = function(h, t) return t.team == h.team and t.handle ~= h.handle end,
  team = function(h, t) return t.team == h.team end,
  opponents = function(h, t) return t.team ~= h.team end,
  all = function() return true end,
}

-- the target filters of a passive (Near): one function per type
local FILTERS = {
  Near = function(v, h, t)
    if t.handle == h.handle then return true end
    local a, b = VRFW.actor(h.handle), VRFW.actor(t.handle)
    if not a or not b or not a.x or not b.x then return false end
    return (a.x - b.x) ^ 2 + (a.z - b.z) ^ 2 <= v.metres * v.metres
  end,
}

local function is_target(h, v, t, p, b)
  local f = TARGET[v.target or "self"]
  if not f or not f(h, t) then return false end
  -- a team-only event player (a team's gain no player earned): only the side words hold
  if t.handle == 0 then
    return not (b and b.trait ~= nil) and #(p and p.filters or {}) == 0 and #(v.positions or {}) == 0 and #(v.elements or {}) == 0
  end
  if b and b.trait ~= nil and not trait_ok(b.trait, h, t) then return false end
  for _, b in ipairs(p and p.filters or {}) do
    local g = FILTERS[b.type]
    if g and not g(b.v, h, t) then return false end
  end
  if v.positions and #v.positions > 0 then
    local ok = false
    for _, w in ipairs(v.positions) do
      if DATA.positions[w] == t.position then ok = true end
    end
    if not ok then return false end
  end
  if v.elements and #v.elements > 0 and not has(v.elements, t.element) then return false end
  return true
end

-- ---------------------------------------------------------------------------------------------- conditions

local MOVES = nil   -- [skill id] = { category, flags }

local function move_info(skill)
  if MOVES == nil then
    MOVES = {}
    for _, id in ipairs({ "skill/skill", "skill" }) do
      local ok, rows = pcall(VRFW.table.rows, id)
      if ok and type(rows) == "table" and #rows > 0 then
        for _, r in ipairs(rows) do
          if r.skill_id then
            MOVES[u32(r.skill_id)] = { category = r.category or 0, flags = u32(r.skill_effect_bit_flag or 0),
              performers = math.max(1, tonumber(r.partner_type) or 1), foul = (tonumber(r.foul_rate) or 0) > 0 }
          end
        end
        break
      end
    end
  end
  return MOVES[u32(skill)]
end

-- the move `skill` is one of the kinds (empty = any)
local function move_kind_ok(kinds, skill)
  if not kinds or #kinds == 0 then return true end
  local m = skill and move_info(skill)
  if not m then return false end
  for _, k in ipairs(kinds) do
    local d = DATA.move_kinds[k]
    if d and d.category == m.category and (not d.flag or bit32.band(m.flags, d.flag) ~= 0) then return true end
  end
  return false
end

local MOVE_IDS = {}

local function moves_of(b)
  local ids = MOVE_IDS[b.key]
  if ids then return ids end
  ids = {}
  for _, m in ipairs(b.v.moves) do
    local ok, id = pcall(VRFW.technique, m)
    if ok and type(id) == "number" and id ~= 0 then ids[u32(id)] = true else ids[L.id_of(m) or 0] = true end
  end
  MOVE_IDS[b.key] = ids
  return ids
end

local ROLLS = 0

-- one seeded roll: true `percent` % of the time
local function roll(percent, h)
  if percent >= 100 then return true end
  ROLLS = ROLLS + 1
  return VRFW.rng("VRFW.passive.chance", { VRFW.now(), ROLLS, h.handle }):below(100) < percent
end

local function score_state(h, ev)
  local m = (ev and ev.match) or VRFW.match() or {}
  local s = m.score
  if type(s) ~= "table" or type(h.team) ~= "number" then return nil end
  local mine, theirs = s[h.team + 1], s[2 - h.team]
  if type(mine) ~= "number" or type(theirs) ~= "number" then return nil end
  if mine > theirs then return "leading" elseif mine < theirs then return "trailing" end
  return "level"
end

-- one function per condition type: (block values, carrier, event, block, counting) -> holds. A move condition holds
-- at a moment without a move (it filters the move where the effect applies).
-- a fraction of the Clock block ("2/3", "0.5", "1"); nil = not given or not a fraction in [0, 1]
local function fraction(t)
  if type(t) == "number" then return (t >= 0 and t <= 1) and t or nil end
  if type(t) ~= "string" or t == "" then return nil end
  local a, b = string.match(t, "^%s*([%d%.]+)%s*/%s*([%d%.]+)%s*$")
  local v
  if a ~= nil then
    a, b = tonumber(a), tonumber(b)
    if a == nil or b == nil or b == 0 then return nil end
    v = a / b
  else
    v = tonumber(t)
  end
  if v == nil or v < 0 or v > 1 then return nil end
  return v
end

-- a team's tension gauge (VRFW.match.tension: the HUD's points): cur, max; nil = unreadable
function CS.tension_of(team)
  if type(team) ~= "number" or type(VRFW.match.tension) ~= "function" then return nil end
  local ok, cur, max = pcall(VRFW.match.tension, team)
  if not ok or type(cur) ~= "number" then return nil end
  return cur, tonumber(max) or 0
end

-- a player's unit aura bits ([aura_bits]), read at most once per CS.aura_every_ms
function CS.aura_of(e)
  local now = VRFW.now()
  local c = CS.aura_bits[e.handle]
  if c and now - c.at < CS.aura_every_ms then return c.bits end
  local bits = 0
  if type(SC.unit_aura_bits) == "number" and e.actor then
    local ok, unit = pcall(VRFW.call, "Match.ActorUnit", e.actor)
    if ok and type(unit) == "number" and unit >= 0x10000 then bits = read("u8", unit + SC.unit_aura_bits) or 0 end
  end
  if c then c.at, c.bits = now, bits else CS.aura_bits[e.handle] = { at = now, bits = bits } end
  return bits
end

-- the aura bits an AuraActive block asks
function CS.mask_of(b)
  local m = CS.aura_mask[b.key]
  if m then return m end
  m = 0
  for _, k in ipairs(b.v.kinds) do m = bit32.bor(m, tonumber(DATA.aura_bits[k]) or 0) end
  CS.aura_mask[b.key] = m
  return m
end

CS.aura_who = {
  self = function(h, e) return e.handle == h.handle end,
  teammates = function(h, e) return e.team == h.team and e.handle ~= h.handle end,
  team = function(h, e) return e.team == h.team end,
  opponents = function(h, e) return e.team ~= h.team end,
  anyone = function() return true end,
}

-- the element wheel ([matchup] wheel: its [[element]] rows): [element name] = the element name it beats
function CS.wheel_of()
  if CS.wheel then return CS.wheel end
  local w = {}
  CS.wheel = w
  local path = DATA.matchup.wheel
  local ok, t = pcall(VRFW.files.toml_cached, type(path) == "string" and path or "")
  if not ok or type(t) ~= "table" or type(t.element) ~= "table" then
    warn("[matchup] wheel: no [[element]] rows in " .. tostring(path) .. " (Rival matchup never holds)")
    return w
  end
  local by_id = {}
  for _, r in ipairs(t.element) do by_id[r.id] = r.name end
  for _, r in ipairs(t.element) do
    if r.beats and by_id[r.beats] then w[r.name] = by_id[r.beats] end
  end
  return w
end

function CS.event_count(h, b, ev)
  local c = CS.counts[h.handle] and CS.counts[h.handle][b.key]
  if not c then return 0 end
  if b.v.per_half and c.half ~= current_half(ev) then return 0 end
  return c.n
end

-- the regular length (game seconds) of the running half, read once per half (Clock last_minutes / added_time)
function CS.half_length(half)
  local hl = CS.half
  if hl.half == half and hl.length > 0 then return hl.length end
  local ok, p = pcall(VRFW.match.period)
  local len = ok and type(p) == "table" and tonumber(p.length) or 0
  hl.half, hl.length = half, len
  return len
end


local CONDITIONS = {
  MoveElement = function(v, h, ev)
    if ev.move_element == nil then return true end
    if v.same_as_carrier and ev.move_element ~= h.element then return false end
    return #v.elements == 0 or has(v.elements, ev.move_element)
  end,
  Move = function(_, _, ev, b) return ev.skill == nil or moves_of(b)[u32(ev.skill)] == true end,
  MoveFamily = function(v, _, ev)
    if ev.skill == nil then return true end
    for _, name in ipairs(v.families) do
      local f = family_of(name)
      if f and f[u32(ev.skill)] then return true end
    end
    return false
  end,
  Wears = function(v, h, _, b) return wears_ok(v, h, b) end,
  WearsSet = function(v, h) return wears_set_ok(v, h) end,
  MoveKind = function(v, _, ev) return ev.skill == nil or move_kind_ok(v.kinds, ev.skill) end,
  Outcome = function(v, _, ev)
    if ev.arg == nil or ev.arg == "" then return false end
    return has(DATA.outcomes[v.result], ev.arg)
  end,
  CarrierElement = function(v, h) return has(v.elements, h.element) end,
  Present = function(v, h, _, b) return count_trait(b, h) >= v.min end,
  Absent = function(_, h, _, b) return count_trait(b, h) == 0 end,
  SetPiece = function(v, h)
    local sp = SET_PIECE
    return sp ~= nil and sp.handle == h.handle and has(v.kinds, sp.kind)
  end,
  Holder = function(v, h, _, b)
    local owner = ball_owner()
    if owner == 0 then return false end
    for _, e in ipairs(players()) do
      if e.handle == owner then return on_side(v.side, v.others, h, e) and trait_ok(b.trait, h, e) end
    end
    return false
  end,
  By = function(_, h, ev, b)
    local who = ev.actor
    if not who then return false end
    local e = player(u32(who.handle))
    return e ~= nil and trait_ok(b.trait, h, e)
  end,
  CarriesPassive = function(v, h)
    for _, k in ipairs(v.passives) do
      if h.carried[L.id_of(k) or 0] then return true end
    end
    return false
  end,
  Side = function(v, h) return h.side == v.side end,
  HasBall = function(v, h)
    local a = VRFW.actor(h.handle)
    return (a ~= nil and a.has_ball == true) == (v.holds ~= false)
  end,
  Zone = function(v, h)
    local a = VRFW.actor(h.handle)
    if not a or not a.x then return false end
    local z = (v.frame == "team" and h.team == 1) and -a.z or a.z
    if #v.x == 2 and (a.x < math.min(v.x[1], v.x[2]) or a.x > math.max(v.x[1], v.x[2])) then return false end
    if #v.z == 2 and (z < math.min(v.z[1], v.z[2]) or z > math.max(v.z[1], v.z[2])) then return false end
    return true
  end,
  Score = function(v, h, ev) return has(v.states, score_state(h, ev)) end,
  Half = function(v, _, ev) return has(v.halves, current_half(ev)) end,
  Clock = function(v, _, ev)
    local m = (ev and ev.match) or VRFW.match() or {}
    local c = m.clock
    if type(c) ~= "number" then return false end
    local from, to = fraction(v.half_fraction_from), fraction(v.half_fraction_to)
    if from ~= nil or to ~= nil then
      -- relative to the half's real length (the match period service: its regular length in the clock's seconds)
      local ok, p = pcall(VRFW.match.period)
      local len = ok and type(p) == "table" and tonumber(p.length) or 0
      if len <= 0 then return false end
      local part = c / len
      from, to = from or 0, to or 1
      return part >= from and (to >= 1 or part < to)
    end
    if (v.last_minutes or 0) > 0 or v.added_time then
      local len = CS.half_length(m.half)
      if len <= 0 then return false end
      if v.added_time and c < len then return false end
      if (v.last_minutes or 0) > 0 and c < len - v.last_minutes * 60 then return false end
    end
    return c >= v.from_minute * 60 and (v.until_minute == 0 or c < v.until_minute * 60)
  end,
  Chance = function(v, h, _, _, counting)
    if not counting then return true end
    return roll(v.percent, h)
  end,
  Carrier = function(_, h, _, b) return trait_ok(b.trait, h, h) end,
  PlayerLevel = function(v, h)
    local lv = h.player_level or 1
    return lv >= v.from and lv <= v.to
  end,
  AuraActive = function(v, h, _, b)
    local mask = CS.mask_of(b)
    if mask == 0 then return false end
    if v.who == "self" then return bit32.band(CS.aura_of(h), mask) ~= 0 end
    local who, n = CS.aura_who[v.who] or CS.aura_who.anyone, 0
    for _, e in ipairs(players()) do
      if who(h, e) and bit32.band(CS.aura_of(e), mask) ~= 0 then
        n = n + 1
        if n >= v.min then return true end
      end
    end
    return false
  end,
  Resource = function(v, h)
    local ok, r = pcall(VRFW.resource.get, v.resource, h.handle)
    if not ok or type(r) ~= "table" or type(r.cur) ~= "number" or (tonumber(r.max) or 0) <= 0 then return false end
    local pct = r.cur * 100 / r.max
    return pct >= v.from_percent and pct <= v.to_percent
  end,
  TensionLevel = function(v, h)
    if type(h.team) ~= "number" then return false end
    local mine = v.side == "opponents" and 1 - h.team or h.team
    local cur, max = CS.tension_of(mine)
    if cur == nil then return false end
    if cur < v.from or (v.to > 0 and cur > v.to) then return false end
    local pct = max > 0 and cur * 100 / max or 0
    if pct < v.from_percent or pct > v.to_percent then return false end
    if v.full and (max <= 0 or cur < max - 0.001) then return false end
    if v.versus ~= "" then
      local other = CS.tension_of(1 - mine)
      if other == nil then return false end
      local state = (cur > other + 0.001 and "ahead") or (cur < other - 0.001 and "behind") or "level"
      if state ~= v.versus then return false end
    end
    return true
  end,
  ScoreMargin = function(v, h, ev)
    local m = (ev and ev.match) or VRFW.match() or {}
    local s = m.score
    if type(s) ~= "table" or type(h.team) ~= "number" then return false end
    local mine, theirs = s[h.team + 1], s[2 - h.team]
    if type(mine) ~= "number" or type(theirs) ~= "number" then return false end
    local d, t = mine - theirs, mine + theirs
    return d >= v.margin_from and d <= v.margin_to and mine >= v.scored_from and mine <= v.scored_to
      and theirs >= v.conceded_from and theirs <= v.conceded_to and t >= v.total_from and t <= v.total_to
  end,
  Headcount = function(v, h)
    local mine, theirs = 0, 0
    for _, e in ipairs(players()) do
      if e.team == h.team then mine = mine + 1 else theirs = theirs + 1 end
    end
    local n = v.side == "opponents" and theirs or mine
    if n < v.from or n > v.to then return false end
    if v.versus == "fewer" then return mine < theirs end
    if v.versus == "same" then return mine == theirs end
    if v.versus == "more" then return mine > theirs end
    return true
  end,
  Mode = function(v)
    if #v.modes > 0 then
      local any = false
      for _, k in ipairs(v.modes) do
        local ok, r = pcall(VRFW.mode_is, k)
        if ok and r == true then
          any = true
          break
        end
      end
      if not any then return false end
    end
    if #v.tags > 0 then
      for _, t in ipairs(v.tags) do
        local ok, r = pcall(VRFW.match.has_tag, t)
        if ok and r == true then return true end
      end
      return false
    end
    return true
  end,
  Flag = function(v)
    for _, k in ipairs(v.set) do
      local ok, r = pcall(VRFW.flag, k)
      if not ok or not r or r == 0 then return false end
    end
    for _, k in ipairs(v.not_set) do
      local ok, r = pcall(VRFW.flag, k)
      if ok and r and r ~= 0 then return false end
    end
    return true
  end,
  MoveTraits = function(v, _, ev)
    if ev.skill == nil then return true end
    local m = move_info(ev.skill)
    if not m then return false end
    if m.performers < v.performers_from or m.performers > v.performers_to then return false end
    if v.foul == "yes" then return m.foul end
    if v.foul == "no" then return not m.foul end
    return true
  end,
  Rival = function(v, h, ev, b, counting)
    local r = ev.rival
    if r == nil or not r.handle then return not counting end
    if b.trait then
      local e = player(u32(r.handle))
      if not e or not trait_ok(b.trait, h, e) then return false end
    end
    local special = r.skill ~= nil and r.skill ~= 0
    if (v.special == "yes" and not special) or (v.special == "no" and special) then return false end
    if #v.kinds > 0 and not (special and move_kind_ok(v.kinds, r.skill)) then return false end
    if v.matchup ~= "" then
      local a = VRFW.actor(u32(r.handle))
      local theirs, mine = a and a.element, ev.move_element or h.element
      if not theirs or not mine then return false end
      if v.matchup == "same" then return mine == theirs end
      local w = CS.wheel_of()
      if v.matchup == "advantage" then return w[mine] == theirs end
      return w[theirs] == mine
    end
    return true
  end,
  EventCount = function(v, h, ev, b)
    local n = CS.event_count(h, b, ev)
    return n >= v.from and (v.to == 0 or n <= v.to)
  end,
  Limit = function(v, h, ev, _, counting, p)
    if not counting or not p then return true end
    local l = CS.limits[h.handle] and CS.limits[h.handle][p.key]
    if not l then return true end
    if v.cooldown_s > 0 and VRFW.now() - l.at < v.cooldown_s * 1000 then return false end
    if v.per_match > 0 and l.n >= v.per_match then return false end
    if v.per_half > 0 and l.half == current_half(ev) and l.n_half >= v.per_half then return false end
    return true
  end,
  AnyOf = function(_, h, ev, b, counting, p)
    for _, c in ipairs(b.parts or NONE) do
      if CS.cond_ok(c, h, ev, counting, p) then return true end
    end
    return false
  end,
  NoneOf = function(_, h, ev, b, counting, p)
    for _, c in ipairs(b.parts or NONE) do
      if CS.cond_ok(c, h, ev, counting, p) then return false end
    end
    return true
  end,
}

-- the conditions about the event itself (its move, its outcome): in a passive with a trigger they only decide whether
-- the trigger counts; without a trigger they filter the move the effect applies to
local function about_event(b) return b.meta.needs == "move" or b.meta.needs == "event" or b.type == "Outcome" end

local NO_EVENT = {}   -- the event of a moment without one (read only)

-- one condition block holds for carrier h of passive p (an event condition of a triggered passive: only when counting)
function CS.cond_ok(b, h, ev, counting, p)
  if not counting and #p.triggers > 0 and about_event(b) then return true end
  local f = CONDITIONS[b.type]
  if not f then
    warn(b.where .. ": no rule for condition type " .. tostring(b.type))
    return false
  end
  return f(b.v, h, ev or NO_EVENT, b, counting, p) == true
end

local function holds(p, h, ev, counting)
  for _, b in ipairs(p.conditions) do
    if not CS.cond_ok(b, h, ev, counting, p) then return false end
  end
  return true
end

-- ---------------------------------------------------------------------------------------------- effects

-- an effect's amount for carrier `h` of passive `p` (the value of its level when the block has value_by_level: a
-- granted passive's grant level, else his passive level) × `n`
local function amount(b, n, h, p)
  local per = b.v.value_by_level
  local v = b.v[b.meta.amount_key] or 0
  if type(per) == "table" and #per > 0 then
    local lv = (h and p and h.levels and h.levels[p.key]) or (h and h.level) or 1
    v = per[math.min(math.max(lv, 1), #per)] or v
  end
  return v * n
end

-- at once, on the counting event: one function per kind
-- a Tension / TensionMax block's team word for the rule effect (carrier / carrier_opponent: the carrier's side, nil
-- when his side is not known)
local function tension_team(b, h)
  local team = b.v.team
  if team == "carrier" or team == "carrier_opponent" then
    if h.side ~= "user" and h.side ~= "rival" then return nil end
    team = team == "carrier" and h.side or (h.side == "user" and "rival" or "user")
  end
  return team
end

local AT_ONCE = {
  tension = function(_, b, h, _)
    local team = tension_team(b, h)
    if team then VRFW.add_tension(b.v.units, team) end
  end,
  tension_max = function(_, b, h, _)
    local team = tension_team(b, h)
    if team then VRFW.add_tension_max(b.v.units, team, b.v.ceiling) end
  end,
  refuse = function(out, b, h, who) if who and u32(who.handle) == h.handle then out[b.meta.answer] = true end end,
  pool = function(_, b, h, _, p)
    local res = pool_of(h)
    if res then
      pcall(VRFW.resource.add, res, h.handle, amount(b, 1, h, p), false, h.summon)
    else
      add_summon_time(h, b.v.no_pool_seconds)
    end
  end,
  summon_time = function(_, b, h)
    if not pool_of(h) then add_summon_time(h, b.v.seconds) end
  end,
}

local LAST_SHOT = nil   -- { handle, team, at, skill }: the last shoot move (KeeperShotPower, shot events without a player)

-- a percent of a capped passive: kept aside (out.capped[answer]) and summed within its caps by `settle_caps`
local function add_capped(out, answer_key, percent, p)
  out.capped = out.capped or {}
  local list = out.capped[answer_key] or {}
  list[#list + 1] = { percent = percent, caps = p.caps }
  out.capped[answer_key] = list
end

-- the sum of capped percents: for each cap (smallest first) the items naming it are scaled down so their sum stays
-- within ±max
local function capped_sum(list)
  local caps, seen = {}, {}
  for _, it in ipairs(list) do
    for _, c in ipairs(it.caps) do
      if not seen[c] then
        seen[c] = true
        caps[#caps + 1] = c
      end
    end
  end
  table.sort(caps, function(a, b) return a.max < b.max end)
  for _, c in ipairs(caps) do
    local sum = 0
    for _, it in ipairs(list) do
      if has(it.caps, c) then sum = sum + it.percent end
    end
    if math.abs(sum) > c.max and sum ~= 0 then
      local f = c.max / math.abs(sum)
      for _, it in ipairs(list) do
        if has(it.caps, c) then it.percent = it.percent * f end
      end
    end
  end
  local total = 0
  for _, it in ipairs(list) do total = total + it.percent end
  return total
end

-- the capped percents of an answer, multiplied into it
local function settle_caps(out)
  if not out.capped then return end
  for answer_key, list in pairs(out.capped) do
    out[answer_key] = (out[answer_key] or 1) * math.max(0, 1 + capped_sum(list) / 100)
  end
  out.capped = nil
end

-- lasting, answered on a hook for its user `t`: one function per kind
local LASTING = {
  power = function(out, b, lvl, t, ev, h, p)
    if not is_target(h, b.v, t, p, b) or not move_kind_ok(b.v.kinds, ev.skill) then return end
    if b.v.mode == "flat" then
      out.power_add = (out.power_add or 0) + math.floor(amount(b, lvl, h, p) + 0.5)
    elseif #p.caps > 0 then
      add_capped(out, "power_mult", amount(b, lvl, h, p), p)
    else
      out.power_mult = (out.power_mult or 1) * math.max(0, 1 + amount(b, lvl, h, p) / 100)
    end
  end,
  rate = function(out, b, lvl, t, ev, h, p)
    if not is_target(h, b.v, t, p, b) then return end
    if b.v.kinds and #b.v.kinds > 0 and not move_kind_ok(b.v.kinds, ev.skill) then return end
    if #p.caps > 0 then
      add_capped(out, b.meta.answer, amount(b, lvl, h, p), p)
    else
      out[b.meta.answer] = (out[b.meta.answer] or 1) * math.max(0, 1 + amount(b, lvl, h, p) / 100)
    end
  end,
  -- points added to a chance the framework sums (crit_chance on crit_check): the target's moves of the block's kinds
  chance_add = function(out, b, lvl, t, ev, h, p)
    if not is_target(h, b.v, t, p, b) or not move_kind_ok(b.v.kinds, ev.skill) then return end
    out[b.meta.answer] = (out[b.meta.answer] or 0) + amount(b, lvl, h, p)
  end,
  -- the keeper battle's shot: t = the keeper; side shooter = the last shot of the other team
  keeper = function(out, b, lvl, t, _, h, p)
    if b.v.side == "keeper" then
      if not is_target(h, b.v, t, p, b) then return end
      if b.shooter_trait ~= nil then
        local s = LAST_SHOT
        local shooter = s and VRFW.now() - s.at <= SHOT_WINDOW_MS and s.team ~= t.team and player(s.handle) or nil
        if not shooter or not trait_ok(b.shooter_trait, h, shooter) then return end
      end
    else
      local s = LAST_SHOT
      if not s or VRFW.now() - s.at > SHOT_WINDOW_MS or s.team == t.team then return end
      local shooter = player(s.handle)
      if not shooter or not is_target(h, b.v, shooter, p, b) then return end
    end
    if not roll(b.v.chance or 100, h) then return end
    out.power_mult = (out.power_mult or 1) * math.max(0, 1 + amount(b, lvl, h, p) / 100)
  end,
  -- pool costs go through the cost flag (pool_flags_tick); a player without a pool pays tension: its cost here
  pool_cost = function(out, b, lvl, t, _, h, p)
    if not is_target(h, b.v, t, p, b) or pool_of(t) then return end
    out.cost_mult = (out.cost_mult or 1) * math.max(0, 1 + amount(b, lvl, h, p) / 100)
  end,
}

-- ---------------------------------------------------------------------------------------------- handlers

-- the triggers an effect's lasting part is answered on, as a set (kept per effect block)
local HOOK_SETS = {}
local function hook_set(e)
  local set = HOOK_SETS[e]
  if set == nil then
    set = {}
    for x in tostring(e.meta.hooks or ""):gmatch("[%w_]+") do set[x] = true end
    HOOK_SETS[e] = set
  end
  return set
end

-- what answer() needs of a trigger key, worked out once per key: its base (before «:») and its kind of event
local KEY_INFO = {}
local function key_info(key)
  local k = KEY_INFO[key]
  if k == nil then
    k = { base = key:match("^[^:]+"), set_piece = key:match("^set_piece") ~= nil,
      possession = key:match("^possession") ~= nil, shot = key:match("^shot_") ~= nil }
    KEY_INFO[key] = k
  end
  return k
end

local SHOOT_KIND = { "shoot" }

-- the hooks asked many times a frame (move_speed per player, recast per installed move) keep their answer per player
-- and move until an input changes: the answer epoch (stacks, player list, spirit / granted passives, set piece), the
-- half and the event's argument; answers that read a position, the ball, the clock or the score are kept VOLATILE_MS
-- (move_power, asked several times a frame per move, "frame": its volatile answers hold for that frame only)
local CACHED_KEYS = { move_speed = true, recast = true, move_power = "frame" }
local VOLATILE_MS = 100
local VOLATILE_TYPES = { Zone = true, Near = true, HasBall = true, Holder = true, Clock = true, SetPiece = true,
  Score = true, Half = true, ScoreMargin = true, TensionLevel = true, AuraActive = true, Resource = true, Flag = true }
local ANSWER_CACHE = {}       -- [key][handle][move id or 0] = { epoch, players_at, half, arg, at, volatile, out }
local PASSIVE_VOLATILE = {}   -- [passive] = its conditions or filters read a position, the ball, the clock or the score
local ANSWER_READ_VOLATILE = false   -- the answer being worked out read a volatile passive

local function passive_volatile(p)
  local v = PASSIVE_VOLATILE[p]
  if v == nil then
    v = false
    for _, b in ipairs(CS.all_conditions(p)) do
      if VOLATILE_TYPES[b.type] then v = true end
    end
    for _, b in ipairs(p.filters) do
      if VOLATILE_TYPES[b.type] then v = true end
    end
    PASSIVE_VOLATILE[p] = v
  end
  return v
end

-- the EventCount blocks that count or break on event `key` (its player `who`), for every carrier of their passives
function CS.count_event(key, who, ev, set)
  local half, changed_any = current_half(ev), false
  for _, h in ipairs(players()) do
    for _, p in ipairs(h.passives) do
      if set[p] then
        for _, b in ipairs(CS.all_conditions(p)) do
          if b.type == "EventCount" then
            local v = b.v
            if b.count_key == nil then
              b.count_key = v.arg ~= "" and (v.on .. ":" .. v.arg) or v.on
              b.break_key = v.breaks_on ~= "" and (v.breaks_arg ~= "" and (v.breaks_on .. ":" .. v.breaks_arg) or v.breaks_on) or false
            end
            local by_h = CS.counts[h.handle]
            if by_h == nil then
              by_h = {}
              CS.counts[h.handle] = by_h
            end
            local c = by_h[b.key]
            if c == nil then
              c = { n = 0, half = half }
              by_h[b.key] = c
            end
            if v.per_half and c.half ~= half then c.n, c.half = 0, half end
            if b.count_key == key and (BY[v.by] or BY.self)(h, who) then
              c.n, changed_any = c.n + 1, true
            end
            if b.break_key == key and c.n ~= 0 and (BY[v.breaks_by] or BY.self)(h, who) then
              c.n, changed_any = 0, true
            end
          end
        end
      end
    end
  end
  if changed_any then DIRTY, ANSWER_EPOCH = true, ANSWER_EPOCH + 1 end
end

local function answer(key, ev)
  local out, any = {}, false
  local who = ev.actor
  local ki = key_info(key)
  if key == "move_power" and NEED_LAST_SHOT and who and ev.skill and move_kind_ok(SHOOT_KIND, ev.skill) then
    LAST_SHOT = { handle = u32(who.handle), team = who.team, at = VRFW.now(), skill = u32(ev.skill) }
  end
  -- the play of a set piece: its kicker until another player has the ball
  if NEED_SET_PIECE then
    if ki.set_piece and who then
      SET_PIECE, ANSWER_EPOCH = { handle = u32(who.handle), kind = ev.arg }, ANSWER_EPOCH + 1
    elseif ki.possession and SET_PIECE and (not who or u32(who.handle) ~= SET_PIECE.handle) then
      SET_PIECE, ANSWER_EPOCH = nil, ANSWER_EPOCH + 1
    end
  end
  -- the spirit / granted passives may have started or ended since the last event
  if ANY_DYNAMIC then DYNAMIC_STALE = true end
  -- the shot events carry no player: the shooter of the last shoot move, when recent
  if who == nil and (ev.trigger == "shot_start" or ev.trigger == "shot_end" or ki.shot) and LAST_SHOT
    and VRFW.now() - LAST_SHOT.at <= SHOT_WINDOW_MS then
    who = { handle = LAST_SHOT.handle, team = LAST_SHOT.team }
    ev.actor = who
    -- its move: the move conditions (MoveKind chain_shoot…) read the shot's move
    if ev.skill == nil and LAST_SHOT.skill ~= 0 then ev.skill = LAST_SHOT.skill end
  end
  local counted = DATA.counted_set[key]
  if counted then CS.count_event(key, who, ev, counted) end
  local list = DATA.listen_set[key]
  if list then
    for _, h in ipairs(players()) do
      for _, p in ipairs(h.passives) do
        if list[p] then
          for _, b in ipairs(p.resets) do
            local f = BY[b.v.by]
            if L.event_key(b) == key and f and f(h, who) then reset(h, p) end
          end
          for _, b in ipairs(p.triggers) do
            local f = BY[b.v.by]
            if L.event_key(b) == key and f and f(h, who) and holds(p, h, ev, true) then
              gain(h, p, ev)
              for _, e in ipairs(p.effects) do
                local g = AT_ONCE[e.meta.apply]
                if g then
                  g(out, e, h, who, p)
                  any = true
                end
              end
            end
          end
        end
      end
    end
  end
  -- the lasting effects answered on this trigger, for its player
  local hook = DATA.hooks_set[ki.base]
  local t = who and player(u32(who.handle))
  -- an event of a team without a player (a team-wide tension gain): its side only
  if not t and who and u32(who.handle) == 0 and type(who.team) == "number" then t = { handle = 0, team = who.team } end
  if hook and t then
    for _, h in ipairs(players()) do
      for _, p in ipairs(h.passives) do
        if hook[p] then
          if passive_volatile(p) then ANSWER_READ_VOLATILE = true end
          local lvl = level(h, p, ev)
          if lvl > 0 and holds(p, h, ev, false) then
            for _, e in ipairs(p.effects) do
              local g = LASTING[e.meta.apply]
              if g and hook_set(e)[ki.base] then
                g(out, e, lvl, t, ev, h, p)
                any = true
              end
            end
          end
        end
      end
    end
  end
  settle_caps(out)
  if not any or next(out) == nil then return nil end
  return out
end

-- answer(), kept per player and move for CACHED_KEYS (nothing allocated when the kept answer holds)
local function cached_answer(key, ev)
  if key == "move_speed" and warming() then return nil end
  local who = ev.actor
  local hdl = who and who.handle and u32(who.handle) or 0
  -- (while an input changed this frame, DIRTY, the answers are worked out afresh until the tick numbers the change)
  if hdl == 0 or PLAYERS == nil or DIRTY then return answer(key, ev) end
  -- (answer()'s own bookkeeping of a shoot move runs on a kept answer too)
  if key == "move_power" and NEED_LAST_SHOT and ev.skill and move_kind_ok(SHOOT_KIND, ev.skill) then
    LAST_SHOT = { handle = hdl, team = who.team, at = VRFW.now(), skill = u32(ev.skill) }
  end
  if ANY_DYNAMIC then DYNAMIC_STALE = true end
  local by_player = ANSWER_CACHE[key]
  if by_player == nil then
    by_player = {}
    ANSWER_CACHE[key] = by_player
  end
  local by_move = by_player[hdl]
  if by_move == nil then
    by_move = {}
    by_player[hdl] = by_move
  end
  local move = ev.skill and u32(ev.skill) or 0
  local m = ev.match
  local half = m and m.half
  local c = by_move[move]
  local frame_only = CACHED_KEYS[key] == "frame"
  if c and c.epoch == ANSWER_EPOCH and c.players_at == PLAYERS_AT and c.half == half and c.arg == ev.arg
    and c.element == ev.move_element
    and (not c.volatile or (frame_only and c.frame == FRAME) or (not frame_only and TICK_NOW - c.at < VOLATILE_MS)) then
    return c.out or nil
  end
  ANSWER_READ_VOLATILE = false
  local out = answer(key, ev)
  if c == nil then
    c = {}
    by_move[move] = c
  end
  c.epoch, c.players_at, c.half, c.arg, c.at = ANSWER_EPOCH, PLAYERS_AT, half, ev.arg, TICK_NOW
  c.element, c.frame = ev.move_element, FRAME
  c.volatile, c.out = ANSWER_READ_VOLATILE, out or false
  return out
end

-- an engine event (`carried`, `half_start`, `interval`) for carrier h's passive p: its triggers of that event (and
-- argument) count (stacks, at-once effects); the event's player is the carrier
local function fire_engine_event(h, p, on, arg)
  local ev = { match = VRFW.match(), actor = { handle = h.handle, team = h.team } }
  for _, b in ipairs(p.triggers) do
    if b.v.on == on and (arg == nil or b.v.arg == arg) and holds(p, h, ev, true) then
      gain(h, p, ev)
      for _, e in ipairs(p.effects) do
        local g = AT_ONCE[e.meta.apply]
        if g then pcall(g, {}, e, h, ev.actor, p) end
      end
    end
  end
  DIRTY = true
end

-- a spirit / granted passive starts: its `carried` triggers count
on_carried = function(h, p) fire_engine_event(h, p, "carried") end

local HALF_SEEN = nil       -- the half whose start was fired
local CLOCK_SEEN = nil      -- the clock at the last tick
local INTERVAL_TIME = {}    -- [handle][passive key .. arg] = seconds of clock since its last firing
local CLOCK_STEP_MAX = 5    -- a clock jump larger than this (a new half, a restart of the clock) adds nothing

-- the engine events of the tick: `half_start` once the clock of a new half runs, `interval:<s>` every <s> s of clock
local function engine_events_tick(m)
  local clock, half = m.clock, m.half
  if type(clock) ~= "number" or half == nil then return end
  local step = (CLOCK_SEEN and clock > CLOCK_SEEN and clock - CLOCK_SEEN <= CLOCK_STEP_MAX) and (clock - CLOCK_SEEN) or 0
  local new_half = HALF_SEEN ~= half and CLOCK_SEEN ~= nil and clock > CLOCK_SEEN
  CLOCK_SEEN = clock
  if new_half then
    HALF_SEEN = half
    PLAYERS = nil   -- a new half: the lineup is read again
  end
  if not new_half and step <= 0 then return end
  for _, h in ipairs(players()) do
    for _, it in ipairs(h.engine) do
      local p, b = it.p, it.b
      if new_half and b.v.on == "half_start" then
        fire_engine_event(h, p, "half_start")
      elseif step > 0 and b.v.on == "interval" then
        local every = tonumber(b.v.arg) or 0
        if every > 0 then
          local times = INTERVAL_TIME[h.handle]
          if times == nil then
            times = {}
            INTERVAL_TIME[h.handle] = times
          end
          local acc = (times[it.key] or 0) + step
          if acc >= every then
            acc = acc - every
            fire_engine_event(h, p, "interval", b.v.arg)
          end
          times[it.key] = acc
        end
      end
    end
  end
end

-- it ends: its stacks go
on_dropped = function(h, p)
  if STACKS[h.handle] then STACKS[h.handle][p.key] = nil end
  DIRTY = true
end

-- the stat parameters: per player and stat, the sum over every passive's Stat effects; written when it changes
local APPLIED = {}   -- [handle][stat] = "add|pct"
local function stats_tick(m)
  local want = {}   -- [handle][stat] = { add, pct }
  local all = players()
  local ev = { match = m }
  for _, h in ipairs(all) do
    for _, p in ipairs(h.passives) do
      local lvl = level(h, p, ev)
      if lvl > 0 then
        local ok = nil
        for _, e in ipairs(p.effects) do
          if e.meta.apply == "stat" then
            if ok == nil then ok = holds(p, h, ev, false) end
            if ok then
              for _, t in ipairs(all) do
                if is_target(h, e.v, t, p, e) then
                  want[t.handle] = want[t.handle] or {}
                  for _, s in ipairs(e.v.stats) do
                    local w = want[t.handle][s] or { add = 0, pct = 0, capped = {} }
                    if e.v.mode ~= "percent" then
                      w.add = w.add + amount(e, lvl, h, p)
                    elseif #p.caps > 0 then
                      w.capped[#w.capped + 1] = { percent = amount(e, lvl, h, p), caps = p.caps }
                    else
                      w.pct = w.pct + amount(e, lvl, h, p)
                    end
                    want[t.handle][s] = w
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  -- the writes, grouped: one set_stat per stat and value (and one restore per stat) with every player it is for
  local writes, order = {}, {}
  local function write_for(key, args, handle)
    local w = writes[key]
    if w == nil then
      w = args
      w.handles = {}
      writes[key] = w
      order[#order + 1] = key
    end
    w.handles[#w.handles + 1] = handle
  end
  for _, t in ipairs(all) do
    local before = APPLIED[t.handle] or {}
    local now_t = {}
    local seen = {}
    for s, w in pairs(want[t.handle] or {}) do
      if #w.capped > 0 then w.pct = w.pct + capped_sum(w.capped) end
      local sig = string.format("%g|%g", w.add, w.pct)
      now_t[s], seen[s] = sig, true
      if before[s] ~= sig then write_for(s .. "|" .. sig, { stat = s, add = w.add, mult = 1 + w.pct / 100 }, t.handle) end
    end
    for s in pairs(before) do
      if not seen[s] then write_for(s .. "|restore", { stat = s, restore = true }, t.handle) end
    end
    APPLIED[t.handle] = now_t
  end
  for _, key in ipairs(order) do
    local w = writes[key]
    local ok, why = pcall(VRFW.set_stat, w)
    if not ok and not w.restore then warn("set_stat " .. w.stat .. ": " .. tostring(why)) end
  end
end

-- the pool costs: per player with a pool, the product of the PoolCost effects on him, as the cost flag's percent
local POOL_FLAGS = {}   -- [handle] = { pct = percent written, flag = its flag prefix }
local function pool_flags_tick(m)
  if next(POOL_COST_FLAG) == nil then return end
  local all = players()
  local ev = { match = m }
  local want, want_flag = {}, {}
  for _, h in ipairs(all) do
    for _, p in ipairs(h.passives) do
      local lvl = level(h, p, ev)
      if lvl > 0 then
        local ok = nil
        for _, e in ipairs(p.effects) do
          if e.meta.apply == "pool_cost" then
            if ok == nil then ok = holds(p, h, ev, false) end
            if ok then
              for _, t in ipairs(all) do
                local flag = is_target(h, e.v, t, p, e) and POOL_COST_FLAG[pool_of(t) or ""]
                if flag then
                  want[t.handle] = (want[t.handle] or 1) * math.max(0, 1 + amount(e, lvl, h, p) / 100)
                  want_flag[t.handle] = flag
                end
              end
            end
          end
        end
      end
    end
  end
  for hdl, m in pairs(want) do
    local pct = math.max(1, math.floor(100 * m + 0.5))
    local old, flag = POOL_FLAGS[hdl], want_flag[hdl]
    if not old or old.pct ~= pct or old.flag ~= flag then
      if old and old.flag ~= flag then pcall(VRFW.clear_flag, string.format("%s.%d", old.flag, hdl)) end
      pcall(VRFW.set_flag, string.format("%s.%d", flag, hdl), pct)
      POOL_FLAGS[hdl] = { pct = pct, flag = flag }
    end
  end
  for hdl in pairs(POOL_FLAGS) do
    if not want[hdl] then
      pcall(VRFW.clear_flag, string.format("%s.%d", POOL_FLAGS[hdl].flag, hdl))
      POOL_FLAGS[hdl] = nil
    end
  end
end

-- the stamina recovery: per player, the product of the StaminaRecovery effects on him, given to the framework's match
-- stamina (VRFW.resource.set_gain_mult, key "" = the pe_provider resources); written when it changes
local STAMINA = {}   -- [handle] = multiplier written
local function stamina_tick(m)
  local all = players()
  local ev = { match = m }
  local want = {}
  for _, h in ipairs(all) do
    for _, p in ipairs(h.passives) do
      local lvl = level(h, p, ev)
      if lvl > 0 then
        local ok = nil
        for _, e in ipairs(p.effects) do
          if e.meta.apply == "stamina_recovery" then
            if ok == nil then ok = holds(p, h, ev, false) end
            if ok then
              for _, t in ipairs(all) do
                if is_target(h, e.v, t, p, e) then
                  want[t.handle] = (want[t.handle] or 1) * math.max(0, 1 + amount(e, lvl, h, p) / 100)
                end
              end
            end
          end
        end
      end
    end
  end
  for hdl, m in pairs(want) do
    if STAMINA[hdl] == nil or math.abs(STAMINA[hdl] - m) > 1e-6 then
      -- written once per value (no stamina resource / no such player: not asked again until the list is read again)
      pcall(VRFW.resource.set_gain_mult, "", hdl, "passives", m)
      STAMINA[hdl] = m
    end
  end
  for hdl in pairs(STAMINA) do
    if not want[hdl] then
      pcall(VRFW.resource.set_gain_mult, "", hdl, "passives", 1)
      STAMINA[hdl] = nil
    end
  end
end

-- ---------------------------------------------------------------------------------------------- start

local keys = {}
for k in pairs(DATA.listen) do keys[k] = true end
for k in pairs(DATA.hooks) do keys[k] = true end
for k in pairs(DATA.counted) do keys[k] = true end
-- the engine's own events (no game trigger): the refresh answers `carried`, the tick `half_start` and `interval:<s>`
local ENGINE_TICK = DATA.engine_events.half_start or DATA.engine_events.interval
for k in pairs(keys) do
  if L.ENGINE_EVENTS[k:match("^[^:]+")] then keys[k] = nil end
end
-- the shot events have no player of their own: the last shoot move's shooter stands in
for k in pairs(keys) do
  if k:match("^shot_") then NEED_LAST_SHOT = true end
end
if NEED_LAST_SHOT then keys.move_power = true end
-- SetPiece blocks follow the restarts and the ball's owner
if NEED_SET_PIECE then keys.set_piece, keys.possession = true, true end

-- what makes the player list (or its spirit / granted passives) be read again: [refresh] of passive_block.toml
local LIVE_STATES = {}
for _, st in ipairs(DATA.refresh.live_states or {}) do LIVE_STATES[st] = true end
local AURA_COMMAND = tonumber(DATA.refresh.aura_command)
local STATE_SEEN = nil
local function forget_players()
  -- (the stamina answers are written again too: a new match gives the framework's resources new values)
  PLAYERS, DIRTY, STAMINA = nil, true, {}
end
-- a form change or a refresh signal: the characters' records, slots and equipment are read again as well
local function forget_characters()
  CHARA_STATIC = {}
  forget_players()
end
-- `now`: read them at once (a summon's cut-in ended: its `carried` passives start now)
local function forget_dynamic(now)
  if not ANY_DYNAMIC then return end
  DYNAMIC_STALE, DYNAMIC_FORCE, DIRTY = true, true, true
  if now == true then players() end
end
local INVALIDATE = {
  -- a state change out of live play: a restart, a half, a substitution may have changed the lineup
  state_enter = function(ev)
    local st, before = tonumber(ev.arg), STATE_SEEN
    STATE_SEEN = st
    if not (before and st and LIVE_STATES[before] and LIVE_STATES[st]) then forget_players() end
  end,
  transform = forget_characters,
  ["signal:vrfw.passives.refresh"] = forget_characters,
  ["signal:vrfw.off_pitch.layout_done"] = forget_characters,
  cutin_end = function() forget_dynamic(true) end,
  resource = function() forget_dynamic(true) end,
}
if AURA_COMMAND then
  INVALIDATE.event_build = function(ev) if tonumber(ev.arg) == AURA_COMMAND then forget_dynamic() end end
end

-- the inputs of the summed effects (Stat, PoolCost, StaminaRecovery): one event each, no timer
local SUMMED = { stat = true, pool_cost = true, stamina_recovery = true }
local POSITIONAL = false   -- a summed passive reads a position (Zone / Near): no event, summed again every 0.5 s
local CLOCK_MARKS = {}     -- [clock mark] = true: the thresholds of the summed passives' Clock blocks
local function mark_of_fraction(t)
  local f = fraction(t)
  if f == nil or f <= 0 or f >= 1 then return nil end
  if type(t) == "string" and t:find("/", 1, true) then return (t:gsub("%s", "")) end
  return string.format("%d/1000", math.floor(f * 1000 + 0.5))
end
local function changed() DIRTY = true end
-- the events that also mark the summed effects changed (CS.summed_keys, filled by the scan below; aura_command:
-- the summon / metamorphosis command of event_build only)
CS.summed_keys = {}
function CS.also_changed(key) CS.summed_keys[key] = true end
-- (a function: the scan's loop variables stay out of the chunk's 200 locals)
;(function()
for _, p in pairs(DATA.passives) do
  local summed = false
  for _, e in ipairs(p.effects) do
    if SUMMED[e.meta.apply] then summed = true end
  end
  if summed then
    for _, b in ipairs(CS.all_conditions(p)) do
      if b.type == "Score" or b.type == "ScoreMargin" then
        CS.also_changed("goal")
      elseif b.type == "TensionLevel" then
        CS.also_changed("tension_gain")
        CS.also_changed("tension_pay")
      elseif b.type == "AuraActive" then
        -- an aura starts or ends: a summon command, a cut-in's end, a form change, a knockdown, a restart (list read)
        CS.also_changed("cutin_end")
        CS.also_changed("transform")
        CS.also_changed("knockdown")
        CS.also_changed("resource")
        if AURA_COMMAND then CS.also_changed("aura_command") end
      elseif b.type == "Resource" then
        CS.also_changed("resource")
      elseif b.type == "HasBall" or b.type == "Holder" or b.type == "SetPiece" then
        -- (the ball owner is read again, not from its 100 ms cache)
        INVALIDATE.possession = function()
          BALL.at, DIRTY = -1e12, true
        end
      elseif b.type == "Zone" or b.type == "Near" then
        POSITIONAL = true
      elseif b.type == "Clock" then
        for _, m in ipairs({ mark_of_fraction(b.v.half_fraction_from), mark_of_fraction(b.v.half_fraction_to) }) do
          CLOCK_MARKS[m] = true
        end
        for _, minute in ipairs({ tonumber(b.v.from_minute) or 0, tonumber(b.v.until_minute) or 0 }) do
          if minute > 0 then CLOCK_MARKS[tostring(math.floor(minute * 60 + 0.5))] = true end
        end
        if (tonumber(b.v.last_minutes) or 0) > 0 then CS.clock_dynamic[b.v.last_minutes * 60] = true end
        if b.v.added_time then CS.clock_dynamic[0] = true end
      end
    end
    for _, b in ipairs(p.filters) do
      if b.type == "Near" then POSITIONAL = true end
    end
  end
end
end)()
for key in pairs(CS.summed_keys) do
  local before = INVALIDATE[key == "aura_command" and "event_build" or key]
  if key == "aura_command" then
    INVALIDATE.event_build = function(ev)
      if before then before(ev) end
      if tonumber(ev.arg) == AURA_COMMAND then DIRTY = true end
    end
  elseif before == nil then
    INVALIDATE[key] = changed
  else
    INVALIDATE[key] = function(ev)
      before(ev)
      DIRTY = true
    end
  end
end
for m in pairs(CLOCK_MARKS) do INVALIDATE["clock:" .. m] = changed end

-- the summed effects: written again when an input changed (DIRTY), a timed stack ended, or (positional passives
-- only) every POSITION_EVERY_MS
local POSITION_AT = -1e12
CS.any_clock_dynamic = next(CS.clock_dynamic) ~= nil
-- the Clock marks relative to the half's regular length crossed since the last tick (the length is known per match)
function CS.clock_tick(m)
  local c = m.clock
  if type(c) ~= "number" then return end
  local prev = CS.clock_prev
  CS.clock_prev = c
  if prev == nil or c <= prev then return end
  local len = CS.half_length(m.half)
  if len <= 0 then return end
  for before_end in pairs(CS.clock_dynamic) do
    local at = len - before_end
    if prev < at and c >= at then DIRTY = true end
  end
end
local function summed_tick(m, now)
  if now >= NEXT_EXPIRY then
    DIRTY, NEXT_EXPIRY = true, math.huge
    -- the next end of the stacks still running
    for _, by in pairs(STACKS) do
      for key, st in pairs(by) do
        local pp = DATA.passives[key]
        local d = pp and pp.stack and pp.stack.v.duration_s or 0
        local ends = st.n > 0 and d > 0 and st.at + d * 1000 or math.huge
        if ends > now then NEXT_EXPIRY = math.min(NEXT_EXPIRY, ends) end
      end
    end
  end
  if CS.any_clock_dynamic then CS.clock_tick(m) end
  if POSITIONAL and now - POSITION_AT >= POSITION_EVERY_MS then
    POSITION_AT, DIRTY = now, true
  end
  if not DIRTY then return end
  DIRTY, ANSWER_EPOCH = false, ANSWER_EPOCH + 1
  if DATA.has_stat then stats_tick(m) end
  if DATA.has_pool_cost then pool_flags_tick(m) end
  if DATA.has_stamina then stamina_tick(m) end
end

local n = 0
local ANY_PASSIVE = next(DATA.passives) ~= nil
-- the tick runs the engine events and the summed effects (it also counts the frames and numbers the answers' inputs)
local TICK_ON = DATA.has_stat or keys.tick or ENGINE_TICK or DATA.has_pool_cost or DATA.has_stamina or ANY_DYNAMIC
for key in pairs(keys) do
  local k = key
  if k == "tick" then
    -- (stats share the tick handler below)
  else
    local inv = ANY_PASSIVE and INVALIDATE[k] or nil
    local cached = TICK_ON and CACHED_KEYS[k] and not DATA.listen_set[k] and not DATA.counted_set[k]
    VRFW.on(k, function(ev)
      if inv then inv(ev) end
      if cached then return cached_answer(k, ev) end
      return answer(k, ev)
    end)
    n = n + 1
  end
end
if ANY_PASSIVE then
  for k, inv in pairs(INVALIDATE) do
    if not keys[k] then VRFW.on(k, function(ev) inv(ev) end) end
  end
end
VRFW.on("match_start", function()
  for hdl, old in pairs(POOL_FLAGS) do pcall(VRFW.clear_flag, string.format("%s.%d", old.flag, hdl)) end
  STACKS, APPLIED, CARRIED, PLAYERS, DIRTY, DYNAMIC, POOL_FLAGS, LAST_SHOT = {}, {}, {}, nil, true, {}, {}, nil
  MOVES_OF, PLATES, HALF_SEEN, CLOCK_SEEN, INTERVAL_TIME = {}, nil, nil, nil, {}
  STAMINA, SET_PIECE, STATE_SEEN, DYNAMIC_STALE, NEXT_EXPIRY = {}, nil, nil, false, math.huge
  CHARA_STATIC, BY_HANDLE, DYNAMIC_FORCE = {}, {}, false
  ANSWER_CACHE, ANSWER_EPOCH, DYNAMIC_AT = {}, ANSWER_EPOCH + 1, -1e12
  WARM = nil
  CS.counts, CS.limits, CS.aura_bits, CS.clock_prev, CS.half.half = {}, {}, {}, nil, nil
end)
-- (the tick also counts the frames: the spirit / granted passives are read at most once per frame)
if TICK_ON then
  VRFW.on("tick", function(ev)
    FRAME = FRAME + 1
    TICK_NOW = VRFW.now()
    local out = keys.tick and answer("tick", ev) or nil
    local m = ev.match or VRFW.match() or NO_EVENT
    if ENGINE_TICK then engine_events_tick(m) end
    -- the spirit / granted passives an answered event marked stale (kept answers do not read the list)
    if DYNAMIC_STALE and PLAYERS and TICK_NOW - DYNAMIC_AT >= DYNAMIC_EVERY_MS then players() end
    if warm_step() then return out end
    summed_tick(m, TICK_NOW)
    return out
  end)
  n = n + 1
end
local n_passives = 0
for _ in pairs(DATA.passives) do n_passives = n_passives + 1 end
info(string.format("%d passive(s), %d character entr(ies), %d spirit(s), %d grantable, %d trigger(s) answered", n_passives,
  #DATA.characters, #DATA.spirits, #DATA.grantable, n))
