-- The Draft's filter panel: the open pool, the stored filters, the scouts and whether the filtered pool fills a draft.
local Shared = require "lib/draft/context"
local G = require "lib/game"
local POS_GK = Shared.POS_GK
local POS_DF = Shared.POS_DF
local FILTER_BLOB = Shared.FILTER_BLOB
local FILTER_ROWS = Shared.FILTER_ROWS
local GENDER_ALL = Shared.GENDER_ALL
local GENDER_MALE = Shared.GENDER_MALE
local GENDER_FEMALE = Shared.GENDER_FEMALE
local FILTER_CHOICES = Shared.FILTER_CHOICES
local FILTERS = Shared.FILTERS
local info = Shared.info
local warn = Shared.warn
local fail = Shared.fail
local DECL = Shared.DECL
local formation_places = Shared.formation_places
local slot_specs = Shared.slot_specs
local pool_from = Shared.pool_from
local index_players = Shared.index_players
local validate = Shared.validate

local function locked_of(src, pending)
  if not VRFW.is_on("EvalCondition") then
    return nil
  end
  local out = {}
  for _, t in ipairs(pending) do
    for _, c in ipairs(src.conds and src.conds[t] or {}) do
      if c ~= 0 and G.eval(c) ~= true then
        out[t] = true
        break
      end
    end
  end
  return out
end

local function open_pool(r)
  local src = r.src
  if not src then
    return
  end
  local pending = {}
  for _, sq in ipairs(src.squads) do
    if (G.unlock_rule(sq.team) or -1) == 0 then
      pending[#pending + 1] = sq.team
    end
  end
  local players = src.all
  if #pending > 0 then
    local locked = locked_of(src, pending)
    if locked then
      local shut, nshut, sig = {}, 0, {}
      for _, t in ipairs(pending) do
        if locked[t] then
          shut[t] = true
          nshut = nshut + 1
          sig[#sig + 1] = t
        end
      end
      local key = table.concat(sig, ",")
      local o = src.open
      if not o or o.key ~= key then
        -- the pool of these squads (none left out = the derived pool), kept until the locked set changes
        local lists = {}
        for _, sq in ipairs(src.squads) do
          if not shut[sq.team] then
            lists[#lists + 1] = sq.elig
          end
        end
        local pl = nshut == 0 and src.all or pool_from(lists, src.params, src.keys)
        o = { key = key, players = pl, squads = #lists, shut = nshut,
          bad = validate({ team = r.pool.team, slots = r.pool.slots, players = pl, staff = r.pool.staff }) }
        src.open = o
      end
      if not o.bad then
        info(string.format("pool of this draft: %d players from %d squads (%d squad(s) of teams still locked left out)",
          #o.players, o.squads, o.shut))
        players = o.players
      else
        warn(string.format("without the %d locked squad(s) the pool cannot fill the draft (%s): every squad is used",
          o.shut, o.bad))
      end
    else
      warn("the unlock conditions cannot be evaluated: every squad is used")
    end
  end
  src.base = players
  if r.pool.players ~= players then
    r.pool.players = players
    index_players(r.pool)
  end
end

local function filters_load()
  local n = VRFW.save.doc.slot()
  if Shared.FILTER_SLOT == n then
    return
  end
  Shared.FILTER_SLOT = n
  for _, k in ipairs(FILTER_ROWS) do
    FILTERS[k] = FILTER_CHOICES[k][1]
  end
  local b = VRFW.save.doc.read_text(FILTER_BLOB, n)
  if type(b) == "string" then
    local doc = VRFW.json.decode(b)
    if type(doc) == "table" then
      for _, k in ipairs(FILTER_ROWS) do
        if type(doc[k]) == "number" then
          FILTERS[k] = doc[k]
        end
      end
    end
  end
end

local function filters_save()
  local ok, why = VRFW.save.doc.write_text(FILTER_BLOB, VRFW.json.encode(FILTERS, true), VRFW.save.doc.slot())
  if not ok then
    warn(FILTER_BLOB .. " not written: " .. tostring(why))
  end
end

-- the characters (chara_base ids) that speak with a generic scout voice: the scouts
local SCOUT_BASES = nil
local function scout_bases()
  if SCOUT_BASES then
    return SCOUT_BASES
  end
  local voices, v = VRFW.table_files.read("character/general_battle_voice", "m_generalBattleVoice", { "voice_id" })
  local bases, b = VRFW.table_files.read("character/chara_base", "CHARA_BASE_INFO", { "id", "voice_bank" })
  if not (voices and bases) then
    fail("scout voices unreadable: " .. tostring(v or b))
  end
  local generic = {}
  for _, r in ipairs(voices) do
    generic[VRFW.ids.unsigned(r[v.voice_id])] = true
  end
  SCOUT_BASES = {}
  for _, r in ipairs(bases) do
    if generic[VRFW.ids.unsigned(r[b.voice_bank])] then
      SCOUT_BASES[VRFW.ids.unsigned(r[b.id])] = true
    end
  end
  return SCOUT_BASES
end

-- one row's next value (dir 1 / -1), wrapping; a stored value the row no longer offers shows as its first
local function filter_step(key, dir)
  local list, at = FILTER_CHOICES[key], 0
  for i, v in ipairs(list) do
    if v == FILTERS[key] then
      at = i
    end
  end
  if at == 0 then
    FILTERS[key], at = list[1], 1
  end
  if dir ~= 0 then
    FILTERS[key] = list[(at - 1 + (dir > 0 and 1 or -1)) % #list + 1]
  end
end

local function filtered_players(src)
  local scouts = FILTERS.scouts ~= 0 and {} or scout_bases()
  local out = {}
  for _, p in ipairs(src.base or src.all) do
    local inf = src.params[p.param]
    local person = inf and (inf.gender == GENDER_MALE or inf.gender == GENDER_FEMALE)
    if person and (FILTERS.gender == GENDER_ALL or inf.gender == FILTERS.gender) and not scouts[inf.base] then
      out[#out + 1] = p
    end
  end
  return out
end

-- can `players` fill the places of `slots` still open (`picks` by place index)?
local function slots_feasible(slots, players, picks)
  local picked, have, need = {}, {}, {}
  local free, open = 0, 0
  for _, id in pairs(picks) do
    picked[id] = true
  end
  for _, p in ipairs(players) do
    if not picked[p.param] then
      have[p.pos] = (have[p.pos] or 0) + 1
      free = free + 1
    end
  end
  for k, s in ipairs(slots) do
    if not picks[k] and s.pos <= POS_DF then
      open = open + 1
      if s.pos >= POS_GK then
        need[s.pos] = (need[s.pos] or 0) + 1
      end
    end
  end
  for pos, n in pairs(need) do
    if (have[pos] or 0) < n then
      return false
    end
  end
  return free >= open
end

Shared.formation_list = nil -- defined with the formation offer, below

local FORMATION_SLOTS = {}
local function formation_slots(id)
  if FORMATION_SLOTS[id] == nil then
    local ok, places = pcall(formation_places, id)
    local ok2, slots = false, nil
    if ok then
      ok2, slots = pcall(slot_specs, DECL, places)
    end
    FORMATION_SLOTS[id] = ok2 and slots or false
  end
  return FORMATION_SLOTS[id] or nil
end

-- the pool the player's filters leave fills a draft: true (and the formation to start in, when the team's own cannot be filled)
local function pool_fillable(r, players)
  if slots_feasible(r.pool.slots, players, {}) then
    return true
  end
  local ok, list = pcall(Shared.formation_list)
  if ok then
    for _, id in ipairs(list) do
      local slots = formation_slots(id)
      if slots and slots_feasible(slots, players, {}) then
        return true, id
      end
    end
  end
  return false
end

-- The names the later parts of the Draft read.
Shared.open_pool = open_pool
Shared.filters_load = filters_load
Shared.filters_save = filters_save
Shared.filter_step = filter_step
Shared.filtered_players = filtered_players
Shared.slots_feasible = slots_feasible
Shared.formation_slots = formation_slots
Shared.pool_fillable = pool_fillable
