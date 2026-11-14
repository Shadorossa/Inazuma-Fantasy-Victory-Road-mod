
Synergy = Synergy or {}

local GameText = VRFW.names
local SeriesOrder = VRFW.series
local RealPlayers = VRFW.real_players
local function real_player(b) return RealPlayers.of_character(b) ~= false end
local Persons = VRFW.persons
local info, warn = VRFW.logger("synergy")

local N_MEMBERS = 0x1D
local MEMBER_BASE, MEMBER_STRIDE, MEMBER_CLASS = 0x80, 0x10, 0x0E
local TEAM_KIND = 0x2CF
local ANS_ACTIVE, ANS_ROWS = 0x7C, 0x74
local MAX_ROWS = 3
local MAX_PANEL_ROWS = 6
local KIND_NEXUS, KIND_NEXUS_MISSING, KIND_FILLED, KIND_EMPTY = 1, 2, 3, 4
-- a row kind's name in the panel command's answer (the menus compare the names; the numbers stay in this script and its log)
local KIND_NAME = { [KIND_NEXUS] = "nexus", [KIND_NEXUS_MISSING] = "nexus_missing", [KIND_FILLED] = "filled", [KIND_EMPTY] = "empty" }


local Id = VRFW.ids
local u32 = Id.unsigned
local Rows = VRFW.table_files

-- a character: "c11801020" (internal key) / a mod character name / "0x…" → its chara_base id
local function chara_of(v)
  return Id.character(v, { hash_names = true })
end

local rd = VRFW.memory.read

local wr = VRFW.memory.write

local function list_of(v) return VRFW.value.list(v, {}) end

local Groups = VRFW.teams.groups
local POOLS = Groups.pools()  -- "<mod>.<name>" -> pool (the framework's one reader of [[VRFW.SynergyPool]])
local DECL = {}          -- synergy id -> declaration
local LIST = {}
local ANY_VERSION = Groups.any_version()  -- the mods whose [[VRFW.SynergyRules]] any_version = true (nil: none)

local SYN_KEYS = { key = true, nexus = true, pool = true, count = true, rule = true, distinct = true, hint = true, placeholder = true,
  slots = true, skip_nexus_team = true, slot_members = true, need = true, nexus_pool = true, same_person = true }


local function read_syn(mod, file, s, i)
  local where = string.format("mods/%s/%s: [[VRFW.Synergy]] #%d", tostring(mod), tostring(file), i)
  for k in pairs(s) do
    if not SYN_KEYS[k] then return nil, where .. ": unknown key `" .. tostring(k) .. "`" end
  end
  local id = Id.parse(s.key, { hash_names = true })
  if not id then return nil, where .. ": key = \"<the game's synergy key, e.g. sp04003>\" is required" end
  local x = { id = id, key = tostring(s.key), mod = mod, nexus = {}, nexus_list = {}, count = tonumber(s.count) or 0,
    rule = s.rule or "min", distinct = s.distinct or "person", hint = s.hint and Id.parse(s.hint, { hash_names = true }) or 0 }
  for _, c in ipairs(list_of(s.nexus)) do
    local b = chara_of(c)
    if b and not x.nexus[b] then
      x.nexus[b] = true
      x.nexus_list[#x.nexus_list + 1] = b
    end
  end
  if s.nexus_pool ~= nil then
    -- the nexus = the members of a pool (resolved once the index is read: resolve_nexus)
    if type(s.nexus_pool) ~= "string" then return nil, where .. " " .. x.key .. ": nexus_pool = \"<pool name>\"" end
    x.nexus_pool = s.nexus_pool:find(".", 1, true) and s.nexus_pool or (tostring(mod) .. "." .. s.nexus_pool)
  end
  x.has_nexus = #x.nexus_list > 0 or x.nexus_pool ~= nil
  if s.slots ~= nil then
    -- one pool per slot (each slot filled by a different player of its pool), instead of `pool` + `count`
    if s.pool ~= nil or s.count ~= nil then return nil, where .. " " .. x.key .. ": `slots` replaces `pool` + `count`: give one or the other" end
    if type(s.slots) ~= "table" or #s.slots == 0 then return nil, where .. " " .. x.key .. ': slots = [ "<pool>", ... ] (one pool per slot)' end
    x.slot_keys = {}
    for _, n in ipairs(s.slots) do
      if type(n) ~= "string" then return nil, where .. " " .. x.key .. ": slots: pool names (text)" end
      x.slot_keys[#x.slot_keys + 1] = n:find(".", 1, true) and n or (tostring(mod) .. "." .. n)
    end
    if s.skip_nexus_team ~= nil and type(s.skip_nexus_team) ~= "boolean" then return nil, where .. " " .. x.key .. ": skip_nexus_team = true / false" end
    x.skip_nexus_team = s.skip_nexus_team == true
    if s.slot_members ~= nil and type(s.slot_members) ~= "boolean" then return nil, where .. " " .. x.key .. ": slot_members = true / false" end
    x.slot_members = s.slot_members == true
    if x.skip_nexus_team and not x.has_nexus then return nil, where .. " " .. x.key .. ": skip_nexus_team needs a nexus" end
    if x.rule ~= "min" then return nil, string.format("%s %s: rule %q: with `slots` every slot must be filled (rule min)", where, x.key, tostring(x.rule)) end
    x.count = #x.slot_keys - (x.skip_nexus_team and 1 or 0)
    if s.need ~= nil then
      local n = tonumber(s.need)
      if not n or n ~= math.floor(n) or n < 1 or n > x.count then return nil, where .. " " .. x.key .. ": need = <whole number 1 to the number of slots>" end
      x.need, x.count = n, n
    end
    x.pool_key = table.concat(x.slot_keys, " / ")
  elseif s.need ~= nil then
    return nil, where .. " " .. x.key .. ": need works with `slots` only"
  elseif s.skip_nexus_team ~= nil then
    return nil, where .. " " .. x.key .. ": skip_nexus_team works with `slots` only"
  elseif s.slot_members ~= nil then
    return nil, where .. " " .. x.key .. ": slot_members works with `slots` only"
  end
  if x.count ~= math.floor(x.count) or x.count < 1 then return nil, where .. " " .. x.key .. ": count = <whole number ≥ 1> is required" end
  if not x.slot_keys and x.count + (x.has_nexus and 1 or 0) > MAX_PANEL_ROWS then
    return nil, string.format("%s %s: the nexus + count = %d rows: the panel shows %d at most", where, x.key, x.count + (x.has_nexus and 1 or 0), MAX_PANEL_ROWS)
  end
  if x.rule ~= "min" and x.rule ~= "exact" then return nil, string.format("%s %s: rule %q (min, exact)", where, x.key, tostring(x.rule)) end
  if x.distinct ~= "person" and x.distinct ~= "character" then return nil, string.format("%s %s: distinct %q (person, character)", where, x.key, tostring(x.distinct)) end
  if not x.slot_keys then
    if type(s.pool) ~= "string" then return nil, where .. " " .. x.key .. ": pool = \"<a [[VRFW.SynergyPool]] name>\" is required" end
    x.pool_key = s.pool:find(".", 1, true) and s.pool or (tostring(mod) .. "." .. s.pool)
  end
  x.same_person = {}
  if s.same_person ~= nil then
    if type(s.same_person) ~= "table" then return nil, where .. " " .. x.key .. ": same_person = [ [ \"<chara>\", \"<chara>\" ], ... ]" end
    for _, g in ipairs(s.same_person) do
      local group = {}
      for _, c in ipairs(type(g) == "table" and g or {}) do
        local b = chara_of(c)
        if not b then return nil, where .. " " .. x.key .. ": same_person: unknown character " .. tostring(c) end
        group[#group + 1] = b
      end
      if #group < 2 then return nil, where .. " " .. x.key .. ": same_person: each group lists two or more characters" end
      x.same_person[#x.same_person + 1] = group
    end
  end
  x.placeholder = s.placeholder and chara_of(s.placeholder) or nil
  return x
end

-- the condition characters of every game synergy (synergy_flag_config as served: the game's rows and the mods'), in row order
local function game_conditions()
  local out = {}
  local ents = VRFW.table.entries(Rows.file_name("data/common/gamedata/skill/synergy_flag_config"),
    { "SYNERGY_FLAG_INFO", "SYNERGY_FLAG_INFO_REF_EXEC_COND", "SYNERGY_FLAG_EXEC_COND" })
  local conds = {}
  for _, e in ipairs(ents) do
    if e.name == "SYNERGY_FLAG_EXEC_COND" then conds[#conds + 1] = e end
  end
  local sid = nil
  for _, e in ipairs(ents) do
    if e.name == "SYNERGY_FLAG_INFO" then
      sid = u32(tonumber(e[1]) or 0)
    elseif e.name == "SYNERGY_FLAG_INFO_REF_EXEC_COND" and sid and sid ~= 0 then
      local charas = {}
      for k = 0, (tonumber(e[2]) or 0) - 1 do
        local c = conds[(tonumber(e[1]) or 0) + k + 1]
        local b = c and u32(tonumber(c[2]) or 0) or 0
        if b ~= 0 then charas[#charas + 1] = b end
      end
      if #charas > 0 then out[#out + 1] = { id = sid, charas = charas } end
      sid = nil
    end
  end
  return out
end

-- any_version: every game synergy no mod declares becomes one slot per condition character (a pool of that character)
local function game_synergies(syns)
  if not ANY_VERSION then return end
  local declared = {}
  for _, e in ipairs(syns) do
    local id = Id.parse(e.s.key, { hash_names = true })
    if id then declared[u32(id)] = true end
  end
  local ok, list = pcall(game_conditions)
  if not ok then
    warn("any_version: synergy_flag_config not readable (" .. tostring(list) .. "): the game's synergies keep their own check")
    return
  end
  local mod = ANY_VERSION[1]
  local where = { mod = mod, file = "synergy_flag_config (any_version)" }
  for _, g in ipairs(list) do
    if not declared[g.id] and #g.charas <= MAX_PANEL_ROWS then
      local slots = {}
      for i, b in ipairs(g.charas) do
        local name = string.format("game_%08x_%d", g.id, i)
        local x, why = Groups.add(mod, where.file, { name = name, charas = { string.format("0x%08X", b) } }, i)
        if not x then
          warn(why .. ": left out")
          slots = nil
          break
        end
        slots[#slots + 1] = name
      end
      if slots then syns[#syns + 1] = { f = where, s = { key = string.format("0x%08X", g.id), slots = slots }, i = #syns + 1 } end
    end
  end
end

local function load_decls()
  local ok, files = pcall(VRFW.files.declarations, "content/synergies")
  if not ok or type(files) ~= "table" then return end
  local syns = {}
  for _, f in ipairs(files) do
    local d = f.data or {}
    if d.schema ~= nil and d.schema ~= "VRFW.synergy/1" then
      warn(string.format("mods/%s/%s: schema %q is not VRFW.synergy/1: file left out", tostring(f.mod), tostring(f.file), tostring(d.schema)))
    else
      local v = type(d.VRFW) == "table" and d.VRFW or {}
      for i, s in ipairs(v.Synergy or {}) do syns[#syns + 1] = { f = f, s = s, i = i } end
    end
  end
  game_synergies(syns)
  for _, e in ipairs(syns) do
    local x, why = read_syn(e.f.mod, e.f.file, e.s, e.i)
    local miss = nil
    if x and x.nexus_pool and not POOLS[x.nexus_pool] then miss = x.nexus_pool end
    if x and not miss then
      for _, k in ipairs(x.slot_keys or { x.pool_key }) do
        if not POOLS[k] then miss = k; break end
      end
    end
    if not x then
      warn(why .. ": left out")
    elseif miss then
      warn(string.format("%s (mods/%s): pool %q is not declared: left out", x.key, tostring(x.mod), miss))
    elseif x.slot_members and (function()
      for _, k in ipairs(x.slot_keys) do
        if #POOLS[k].team_list == 0 and #POOLS[k].crest_list == 0 then return true end
      end
      return false
    end)() then
      warn(string.format("%s (mods/%s): slot_members needs every slot pool to name its belong team(s) (`teams`) or its crest (`crests`): left out", x.key, tostring(x.mod)))
    elseif DECL[x.id] then
      warn(string.format("%s: declared by %s already: %s's left out", x.key, tostring(DECL[x.id].mod), tostring(x.mod)))
    else
      if x.slot_keys then
        x.slots = {}
        for j, k in ipairs(x.slot_keys) do x.slots[j] = POOLS[k] end
      else
        x.pool = POOLS[x.pool_key]
      end
      DECL[x.id] = x
      LIST[#LIST + 1] = x
    end
  end
end

load_decls()

local IDX = nil

local function index()
  if IDX then return IDX end
  local t0 = VRFW.now_ms()
  IDX = { card = {}, role = {}, info = {}, order = {} }
  -- a card's character, asked once per card id (the members' cards)
  IDX.base_of = setmetatable({}, { __index = function(t, param)
    local ok, b = pcall(VRFW.character.base_of, param)
    if ok and type(b) == "number" then
      b = u32(b)
      rawset(t, param, b)
      return b
    end
    return nil
  end })
  local ok, e = pcall(function()
    for _, c in ipairs(VRFW.character.characters()) do
      local id = u32(c.id)
      IDX.info[id] = {
        person = u32(c.name_text),
        gender = math.floor(c.gender or 0),
        series = math.floor(c.series or 0),
        teams = { u32(c.teams[1] or 0), u32(c.teams[2] or 0), u32(c.teams[3] or 0) },
      }
      if (c.cards or 0) > 0 then IDX.card[id] = true end
      if c.coach or c.manager then IDX.role[id] = { coach = c.coach or nil, manager = c.manager or nil } end
      IDX.order[#IDX.order + 1] = id
    end
  end)
  IDX.ok = ok
  if not ok then warn("character index not readable: " .. tostring(e) .. " (declared synergies stay off)") end
  info(string.format("character index: %d characters, %d staff, taken in %d ms (the framework's, shared)",
    #IDX.order, (function()
      local n = 0
      for _ in pairs(IDX.role) do n = n + 1 end
      return n
    end)(), math.floor(VRFW.now_ms() - t0)))
  return IDX
end


-- the person a same_person group counts as (the synergy's groups, then its pool's), per declaration, built once
local function person_aliases(decl)
  if decl.person_alias then return decl.person_alias end
  local alias = {}
  local function root(p)
    while alias[p] do p = alias[p] end
    return p
  end
  local function join(groups)
    for _, group in ipairs(groups or {}) do
      local rep = root(Persons.of_character(group[1]))
      for i = 2, #group do
        local p = root(Persons.of_character(group[i]))
        if p ~= rep then alias[p] = rep end
      end
    end
  end
  join(decl.same_person)
  join(type(decl.pool) == "table" and decl.pool.same_person or nil)
  local flat = {}
  for p in pairs(alias) do flat[p] = root(p) end
  decl.person_alias = flat
  return flat
end

-- the person of a character (VRFW.persons: every version of him), or the character itself with distinct = "character"
local function person(base, decl)
  if decl.distinct == "character" then return base end
  local p = Persons.of_character(base)
  return person_aliases(decl)[p] or p
end

local STATE = {}
local STATE_N = 0
local LAST = {}
local logs, ERRS = 0, {}

-- handle -> chara_base (cached: the check runs for every member card the menus draw; a handle keeps its card)
local HBASE, HBASE_N = {}, 0
local function base_of_handle(h)
  local b = HBASE[h]
  if b then return b end
  local ok, rec = pcall(VRFW.character.record, h)
  if not ok or type(rec) ~= "table" or not rec.param then return nil end
  b = IDX.base_of[u32(rec.param)]
  if b then
    if HBASE_N > 4096 then HBASE, HBASE_N = {}, 0 end
    HBASE[h], HBASE_N = b, HBASE_N + 1
  end
  return b
end

local function member_slots(team)
  local first = team + MEMBER_BASE
  local handles = VRFW.memory.read_array("u32", first, N_MEMBERS, MEMBER_STRIDE)
  local okh = handles ~= nil
  local classes = VRFW.memory.read_array("u8", first + MEMBER_CLASS, N_MEMBERS, MEMBER_STRIDE)
  local okc = classes ~= nil
  if okh and type(handles) == "table" and okc and type(classes) == "table" then return handles, classes end
  handles, classes = {}, {}
  for i = 0, N_MEMBERS - 1 do
    local m = first + i * MEMBER_STRIDE
    handles[i + 1] = rd("u32", m) or 0
    classes[i + 1] = rd("u8", m + MEMBER_CLASS) or 0xFF
  end
  return handles, classes
end

local function same_values(a, b)
  for i = 1, N_MEMBERS do
    if a[i] ~= b[i] then return false end
  end
  return true
end

local MEMBERS = {}       -- team address -> { kind, handles, classes, list }
local MEMBERS_N = 0
local function members(team)
  local kind = rd("u8", team + TEAM_KIND)
  if not kind or kind >= 2 then return nil end
  local limit = kind == 0 and 11 or 5
  local handles, classes = member_slots(team)
  local known = MEMBERS[team]
  if known and known.kind == kind and same_values(known.handles, handles) and same_values(known.classes, classes) then
    return known.list
  end
  local out, unresolved = {}, false
  for i = 0, N_MEMBERS - 1 do
    local h, cls = handles[i + 1], classes[i + 1]
    if h ~= 0 and (cls < limit or cls > 0x0F) and not (cls >= 0x14 and cls <= 0x1C) then
      local b = base_of_handle(h)
      if b then out[#out + 1] = { i = i, h = h, base = b, staff = cls >= 0x10 } else unresolved = true end
    end
  end
  table.sort(out, function(a, b)
    if a.staff ~= b.staff then return not a.staff end
    return a.i < b.i
  end)
  if not known then
    if MEMBERS_N > 32 then MEMBERS, MEMBERS_N = {}, 0 end
    MEMBERS_N = MEMBERS_N + 1
  end
  -- a handle not resolved yet (its card unknown): not kept, read again at the next check
  MEMBERS[team] = (not unresolved) and { kind = kind, handles = handles, classes = classes, list = out } or nil
  return out
end

local function active_slots(d, nexus_base)
  local out = {}
  local c = IDX.info[nexus_base or 0]
  local nt = c and c.teams or {}
  for _, p in ipairs(d.slots) do
    local skip = false
    if d.skip_nexus_team then
      for _, t in ipairs(nt) do
        if t ~= 0 and p.teams[t] then skip = true end
      end
    end
    if not skip then out[#out + 1] = p end
  end
  return out
end

local function fill_slots(d, slots, cands)
  local persons, order = {}, {}
  for _, m in ipairs(cands) do
    local k = person(m.base, d)
    local e = persons[k]
    if not e then
      e = { cards = {} }
      persons[k] = e
      order[#order + 1] = k
    end
    e.cards[#e.cards + 1] = m
  end
  local function card_for(k, p)
    for _, m in ipairs(persons[k].cards) do
      if p.set[m.base] then return m end
    end
    return nil
  end
  local owner, got = {}, {}
  local function try(si, seen)
    for _, k in ipairs(order) do
      if not seen[k] and card_for(k, slots[si]) then
        seen[k] = true
        if owner[k] == nil or try(owner[k], seen) then
          owner[k] = si
          got[si] = k
          return true
        end
      end
    end
    return false
  end
  for si = 1, #slots do try(si, {}) end
  local filled, extra = {}, 0
  for si = 1, #slots do filled[si] = got[si] and card_for(got[si], slots[si]) or nil end
  for _, k in ipairs(order) do
    if owner[k] == nil then extra = extra + 1 end
  end
  return filled, extra
end

-- the nexus, once: a pool's members (`nexus_pool`) and, with any_version, every version of a nexus character
local function resolve_nexus(d)
  if d.nexus_resolved then return end
  d.nexus_resolved = true
  local function add(b)
    if not d.nexus[b] then
      d.nexus[b] = true
      d.nexus_list[#d.nexus_list + 1] = b
    end
  end
  if d.nexus_pool then
    for _, b in ipairs(Groups.member_list(POOLS[d.nexus_pool])) do add(b) end
  end
  if ANY_VERSION then
    local declared = {}
    for _, b in ipairs(d.nexus_list) do declared[b] = true end
    for _, b in ipairs(Groups.with_versions(declared)) do add(b) end
  end
end

-- the nexus among the members (the first one), its row and mark added to the state; nil when absent or not declared
local function nexus_row(d, ms, st, team)
  if not d.has_nexus then return nil end
  local nexus = nil
  for _, m in ipairs(ms or {}) do
    if d.nexus[m.base] then nexus = m; break end
  end
  if nexus then
    st.rows[#st.rows + 1] = { kind = KIND_NEXUS, base = nexus.base }
    st.marks[#st.marks + 1] = nexus
  else
    st.rows[#st.rows + 1] = { kind = (team ~= 0) and KIND_NEXUS_MISSING or KIND_NEXUS, base = d.nexus_list[1] }
  end
  return nexus
end

-- the character an empty row of pool `p` is drawn with: the pool's named characters first, then any member, never one in
-- the team, a nexus or one already drawn
local function placeholder_of(p, d, in_team, shown)
  for pass = 1, 2 do
    for _, b in ipairs(p.members) do
      if (pass == 2 or p.charas[b]) and not in_team[b] and not d.nexus[b] and not shown[b] then return b end
    end
  end
  return nil
end

local function evaluate_slots(d, team)
  resolve_nexus(d)
  local st = { sid = d.id, active = false, rows = {}, extra = 0, team = team ~= 0, marks = {} }
  local ms = (team ~= 0) and members(team) or nil
  local in_team = {}
  for _, m in ipairs(ms or {}) do in_team[m.base] = true end
  local nexus = nexus_row(d, ms, st, team)
  local slots = active_slots(d, nexus and nexus.base or d.nexus_list[1])
  for _, p in ipairs(slots) do Groups.member_list(p) end
  local np = nexus and person(nexus.base, d) or nil
  local cands = {}
  for _, m in ipairs(ms or {}) do
    if m ~= nexus and (np == nil or person(m.base, d) ~= np) then
      for _, p in ipairs(slots) do
        if p.set[m.base] then cands[#cands + 1] = m; break end
      end
    end
  end
  local filled, extra = fill_slots(d, slots, cands)
  local shown, n_filled = {}, 0
  local need = d.need or #slots
  local function empty_row(p)
    local ph = placeholder_of(p, d, in_team, shown)
    if ph then shown[ph] = true end
    st.rows[#st.rows + 1] = { kind = KIND_EMPTY, base = ph or 0, pool = p }
  end
  if d.need then
    -- need < slots: the filled slots first (at most `need`), then empty rows of the unfilled pools up to `need` rows
    for si, p in ipairs(slots) do
      local m = filled[si]
      if m and n_filled < need then
        n_filled = n_filled + 1
        st.rows[#st.rows + 1] = { kind = KIND_FILLED, base = m.base, pool = p }
        st.marks[#st.marks + 1] = m
      end
    end
    local rows_n = n_filled
    for si, p in ipairs(slots) do
      if not filled[si] and rows_n < need then
        rows_n = rows_n + 1
        empty_row(p)
      end
    end
  else
    for si, p in ipairs(slots) do
      local m = filled[si]
      if m then
        n_filled = n_filled + 1
        st.rows[#st.rows + 1] = { kind = KIND_FILLED, base = m.base, pool = p }
        st.marks[#st.marks + 1] = m
      else
        empty_row(p)
      end
    end
  end
  st.extra = extra
  st.active = (team ~= 0) and n_filled >= need and (nexus ~= nil or not d.has_nexus)
  return st
end

-- the synergy's state for one team (team = 0: no team, e.g. the shop's panel), computed (evaluate: the memo)
local function evaluate_uncached(d, team)
  resolve_nexus(d)
  if d.slots then return evaluate_slots(d, team) end
  -- pool_members gives the member list; the membership set is the pool's own `set`
  Groups.member_list(d.pool)
  local pset = d.pool.set
  local st = { sid = d.id, active = false, rows = {}, extra = 0, team = team ~= 0, marks = {} }
  local ms = (team ~= 0) and members(team) or nil
  local in_team = {}
  for _, m in ipairs(ms or {}) do in_team[m.base] = true end
  local nexus = nexus_row(d, ms, st, team)
  local used, cand = {}, {}
  if nexus then used[person(nexus.base, d)] = true end
  for _, m in ipairs(ms or {}) do
    if m ~= nexus and pset[m.base] then
      local k = person(m.base, d)
      if not used[k] then
        used[k] = true
        cand[#cand + 1] = m
      end
    end
  end
  local shown = {}
  for k = 1, d.count do
    local m = cand[k]
    if m then
      st.rows[#st.rows + 1] = { kind = KIND_FILLED, base = m.base, pool = d.pool }
      st.marks[#st.marks + 1] = m
    else
      local ph = d.placeholder
      if not ph or in_team[ph] or shown[ph] then ph = placeholder_of(d.pool, d, in_team, shown) end
      if ph then shown[ph] = true end
      st.rows[#st.rows + 1] = { kind = KIND_EMPTY, base = ph or 0, pool = d.pool }
    end
  end
  st.extra = math.max(0, #cand - d.count)
  local enough
  if d.rule == "exact" then enough = (#cand == d.count) else enough = (#cand >= d.count) end
  st.active = (team ~= 0) and enough and (nexus ~= nil or not d.has_nexus)
  return st
end

local MAX_MEMOS = 32     -- team states kept per synergy (all dropped past it)
local function evaluate(d, team)
  index()
  local ms = (team ~= 0) and members(team) or false
  local memos = d.memos
  if memos == nil then
    memos = { n = 0 }
    d.memos = memos
  end
  local memo = memos[team]
  if memo and memo.members == ms and ms ~= nil then return memo.state end
  local t0 = VRFW.now_ms()
  local st = evaluate_uncached(d, team)
  st.check_ms = VRFW.now_ms() - t0
  if memo == nil then
    if memos.n >= MAX_MEMOS then
      memos = { n = 0 }
      d.memos = memos
    end
    memos.n = memos.n + 1
  end
  memos[team] = { members = ms, state = st }
  return st
end

local N_ROW_BYTES = ANS_ACTIVE - ANS_ROWS + 1
local function answer_values(st)
  if st.words then return st.words, st.bytes end
  local words, bytes = {}, {}
  for i = 1, N_MEMBERS do words[i] = 0 end
  for i = 1, N_ROW_BYTES do bytes[i] = 0 end
  for _, m in ipairs(st.marks) do words[m.i + 1] = m.h end
  for r, row in ipairs(st.rows) do
    if r <= 8 and (row.kind == KIND_NEXUS and st.team or row.kind == KIND_FILLED) then bytes[r] = 1 end
  end
  bytes[N_ROW_BYTES] = st.active and 1 or 0
  st.words, st.bytes = words, bytes
  return words, bytes
end

local function write_answer(out, st)
  local words, bytes = answer_values(st)
  local ok_words = VRFW.memory.write_array("u32", out, words)
  local ok_bytes = VRFW.memory.write_array("u8", out + ANS_ROWS, bytes)
  if ok_words and ok_bytes then return end
  -- (one value at a time when the arrays could not be written)
  for i = 0, N_MEMBERS - 1 do wr("u32", out + 4 * i, words[i + 1]) end
  for r = 0, N_ROW_BYTES - 1 do wr("u8", out + ANS_ROWS + r, bytes[r + 1]) end
end

-- the state's log line, built once per state
local function state_line(d, st)
  if st.line then return st.line end
  local parts = {}
  for _, r in ipairs(st.rows) do parts[#parts + 1] = string.format("%d:%08X", r.kind, r.base) end
  st.line = string.format("%s: %s (%s, rows %s, +%d more)", d.key, st.active and "active" or "off",
    st.team and "team" or "no team", table.concat(parts, " "), st.extra)
  return st.line
end

local NO_TEAM_LAYERS = {}
local MATCH_LINES = nil  -- during a match: "<synergy id>:<team>" -> true once its state is logged

if #LIST > 0 then
  for _, d in ipairs(LIST) do pcall(VRFW.native.table_set, "Synergy.Declared", d.id, 1) end

  -- the first check of each synergy and team in a match is logged at INFO: whether a declared synergy was active in it
  VRFW.on("match:start", function()
    MATCH_LINES = {}
    return nil
  end)
  VRFW.on("match:end", function()
    MATCH_LINES = nil
    return nil
  end)

  VRFW.on("hook:SynergyCheck:post", function(ev)
    local a = ev.args or {}
    local out, sidp, team = a[1], a[2], a[3]
    local d = DECL[rd("u32", sidp) or 0]
    if not d or not out or out < 0x10000 then return nil end
    local ok, st = pcall(evaluate, d, (team and team >= 0x10000) and team or 0)
    if not ok then
      local k = d.key .. ": " .. tostring(st)
      if not ERRS[k] and logs < 200 then ERRS[k] = true; logs = logs + 1; warn(k) end
      return nil
    end
    write_answer(out, st)
    if MATCH_LINES and st.team then
      local k = string.format("%08X:%X", d.id, team)
      if not MATCH_LINES[k] then
        MATCH_LINES[k] = true
        info(string.format("match: %s (team 0x%X)", state_line(d, st), team))
      end
    end
    if STATE_N > 64 then STATE, STATE_N = {}, 0 end
    if not STATE[out] then STATE_N = STATE_N + 1 end
    STATE[out] = st
    if logs >= 200 then return nil end
    local line = state_line(d, st)
    if LAST[d.id] ~= line then
      LAST[d.id], logs = line, logs + 1
      VRFW.debug("synergy: " .. string.format("%s; check %.1f ms", line, st.check_ms or 0))
    end
    return nil
  end)

  local CUR = nil          -- the panel being drawn: { answer, sid }
  local PANEL = nil        -- the last panel drawn: { sid, state }

  VRFW.on("hook:SynergyDetail", function(ev)
    local a = ev.args or {}
    local sid = rd("u32", a[2]) or 0
    if DECL[sid] and a[3] then
      CUR = { answer = a[3], sid = sid }
      pcall(VRFW.native.table_set, "Synergy.Answers", a[3], 1)
    end
    return nil
  end)

  VRFW.on("hook:SynergyDetail:post", function(ev)
    local a = ev.args or {}
    if a[3] then pcall(VRFW.native.table_set, "Synergy.Answers", a[3], nil) end
    CUR = nil
    return nil
  end)

  local function row_locators(prop)
    if not prop or prop < 0x10000 then return nil end
    local function ids(offsets)
      local out = {}
      for _, o in ipairs(offsets) do out[#out + 1] = string.format("%d", u32(rd("u32", prop + o) or 0)) end
      return table.concat(out, ",")
    end
    return { off = ids({ 0xA0, 0xA4 }), on = ids({ 0xA8, 0xAC, 0xB0 }) }
  end

  VRFW.on("hook:SynergyDetailRows", function(ev)
    local a = ev.args or {}
    local prop, list, answer = a[1], a[2], a[3]
    if not CUR or CUR.answer ~= answer then return nil end
    local st = STATE[answer]
    local layer = (prop and prop >= 0x10000) and u32(rd("u32", prop + 0x3C) or 0) or 0
    if not st or st.sid ~= CUR.sid or NO_TEAM_LAYERS[layer] then
      local ok, s2 = pcall(evaluate, DECL[CUR.sid], 0)
      if not ok then return nil end
      st = s2
    end
    local ids = rd("ptr", list)
    if not ids or ids < 0x10000 then return nil end
    local order = #st.rows > MAX_ROWS and { 1, 3, 5 } or { 1, 2, 3 }
    local drawn = {}
    for i = 1, MAX_ROWS do
      local row = order[i] and st.rows[order[i]]
      local base = (row and row.kind ~= KIND_EMPTY) and row.base or 0
      wr("u32", ids + 4 * (i - 1), base)
      drawn[i] = base ~= 0 and "1" or "0"
    end
    PANEL = { sid = CUR.sid, state = st, locators = row_locators(prop), drawn = table.concat(drawn) }
    return nil
  end)

  local NAMES_READ = {}    -- language folder -> true once the panel's name ids are read
  local NAME_IDS = nil

  local function name_ids()
    if NAME_IDS then return NAME_IDS end
    index()
    local seen, list = {}, {}
    local function add(b)
      local c = IDX.info[b or 0]
      local id = c and c.person
      if id and id ~= 0 and not seen[id] then seen[id] = true; list[#list + 1] = id end
    end
    for _, d in ipairs(LIST) do
      for _, b in ipairs(d.nexus_list or {}) do add(b) end
      if d.placeholder then add(d.placeholder) end
      for _, p in ipairs(d.slots or { d.pool }) do
        for _, b in ipairs(Groups.member_list(p)) do add(b) end
      end
    end
    NAME_IDS = list
    return list
  end

  local function name_of(base, lang)
    if not NAMES_READ[lang] then
      local t0 = VRFW.now_ms()
      local ids = name_ids()
      GameText.texts("chara_text", lang, ids)
      NAMES_READ[lang] = true
      info(string.format("names (%s): %d text ids read in %.1f ms", lang, #ids, VRFW.now_ms() - t0))
    end
    local c = IDX and IDX.info[base]
    if not c or c.person == nil then return "" end
    return GameText.chara_names({ c.person }, lang, true)[c.person] or ""
  end

  -- belong team id -> its crest (item_emblem id of the first era that has one), read once at load
  local EMBLEMS = nil
  local ERA_EMBLEMS = {}   -- belong team id -> { [era 1-4] = crest }
  local TEAM_TEXT = {}
  local EMBLEM_COLS = { "team_emblem_id_ie", "team_emblem_id_go", "team_emblem_id_areori", "team_emblem_id_v" }
  local function emblems()
    if EMBLEMS then return EMBLEMS end
    EMBLEMS = {}
    local ok, e = pcall(function()
      for _, r in ipairs(VRFW.table.rows("character/belong_team") or {}) do
        local id = u32(r.belong_team_id or r[1] or 0)
        local text_id = u32(r.team_name_text_id or r.teamNameTextId or 0)
        if id ~= 0 and text_id ~= 0 then TEAM_TEXT[id] = text_id end
        ERA_EMBLEMS[id] = {}
        for i, c in ipairs(EMBLEM_COLS) do
          local v = u32(r[c] or r[i + 3] or 0)   -- by the schema's name, else in column order (cols 3-6)
          if v ~= 0 then
            ERA_EMBLEMS[id][i] = v
            if EMBLEMS[id] == nil then EMBLEMS[id] = v end
          end
        end
      end
    end)
    if not ok then warn("team crests: " .. tostring(e)) end
    return EMBLEMS
  end

  -- the crests of a slot pool's teams, comma-joined (at most MAX_CRESTS, the panel's room)
  local MAX_CRESTS = 12
  local function crests_of(p)
    if not (p and p.team_list) or (p.show_candidates and not p.any_team) then return "" end   -- a team pool always draws its crests
    local m, out, seen = emblems(), {}, {}
    if #p.crest_list > 0 then
      emblems()
      local by_key = nil
      for _, c in ipairs(p.crest_list) do
        local e
        if c.game_team then
          if not by_key then
            by_key = {}
            for _, t in ipairs(Groups.team_captains()) do by_key[t.key] = t.emblem end
          end
          e = by_key[c.game_team]
        else
          e = c.emblem or (ERA_EMBLEMS[c.team] and ERA_EMBLEMS[c.team][c.era])
        end
        if e and not seen[e] and #out < MAX_CRESTS then seen[e] = true; out[#out + 1] = string.format("%d", e) end
      end
      return table.concat(out, ",")
    end
    if p.era then
      -- a pool of one era's series: the first team's crest of that era
      for _, t in ipairs(p.team_list) do
        local e = ERA_EMBLEMS[t] and ERA_EMBLEMS[t][p.era]
        if e then return string.format("%d", e) end
      end
    elseif p.crest_eras then
      for _, t in ipairs(p.team_list) do
        for i = 1, 4 do
          local e = ERA_EMBLEMS[t] and ERA_EMBLEMS[t][i]
          if e and not seen[e] and #out < MAX_CRESTS then seen[e] = true; out[#out + 1] = string.format("%d", e) end
        end
      end
      return table.concat(out, ",")
    end
    for _, t in ipairs(p.team_list) do
      local e = m[t]
      if e and not seen[e] and #out < MAX_CRESTS then seen[e] = true; out[#out + 1] = string.format("%d", e) end
    end
    return table.concat(out, ",")
  end

  -- a panel's face lists depend only on the declaration, the pool and the language: each is built once and kept on the
  -- declaration (d.face_cache), so a redraw with a new team state walks no pool again
  local function face_cache(d, key)
    d.face_cache = d.face_cache or {}
    local c = d.face_cache[key]
    if c == nil then c = {}; d.face_cache[key] = c end
    return c
  end

  local MAX_FACES = 5
  local function faces_of(d, skip_base)
    local c = face_cache(d, "nexus")
    local s = c[skip_base or 0]
    if s then return s end
    local out, seen = {}, {}
    if skip_base then seen[person(skip_base, d)] = true end
    for _, b in ipairs(d.nexus_list) do
      if #out >= MAX_FACES then break end
      local k = person(b, d)
      -- only characters with a card have a face picture (a card-less version would draw a blank box)
      if not seen[k] and IDX.card[b] and real_player(b) then seen[k] = true; out[#out + 1] = string.format("%d", b) end
    end
    s = table.concat(out, ",")
    c[skip_base or 0] = s
    return s
  end

  local MAX_SLOT_FACES = 11
  local function crest_of(p)
    -- a pool's declared crests come first, so a pool that names its team only through `rosters` still has its crest
    if p and p.crest_list and #p.crest_list > 0 then return (crests_of(p):match("^(%d+)")) or "" end
    local t = p and p.team_list and p.team_list[1]
    local e = t and emblems()[t]
    return e and string.format("%d", e) or ""
  end

  local function members_faces(p, d)
    Groups.member_list(p)
    local c = face_cache(d, p)
    if c.members == p.members and c.slot_faces then return c.slot_faces end
    local pick, order = {}, {}
    for _, b in ipairs(p.members) do
      local k = person(b, d)
      local cur = pick[k]
      -- a person first met past the panel's room is never drawn: no face check for him
      local wanted = (cur == nil and #order < MAX_SLOT_FACES) or (cur ~= nil and not IDX.card[cur] and IDX.card[b])
      if wanted and real_player(b) then
        if cur == nil then order[#order + 1] = k end
        pick[k] = b
      end
    end
    local out = {}
    for i = 1, #order do out[i] = string.format("%d", pick[order[i]]) end
    c.members, c.slot_faces = p.members, table.concat(out, ",")
    return c.slot_faces
  end

  local MAX_ROW_FACES = 24
  local function candidate_faces(p, d, marks, lang)
    -- a pure team pool shows its crests; a pool that also names characters shows those as candidates (and the crests)
    if not p or p.role or (p.any_team and not p.any_chara) then return "", "" end
    Groups.member_list(p)
    -- one candidate per displayed name: the versions of a character carry their own name text (several cards of one name)
    local function who(b)
      local nm = name_of(b, lang)
      return nm ~= "" and nm or person(b, d)
    end
    -- the candidates, walked once per pool and language; the walk stops one person past the room (that proves the pool too big)
    local c = face_cache(d, p)
    local cand = c.members == p.members and c[lang] or nil
    if not cand then
      cand = { pick = {}, order = {}, over = false }
      for _, b in ipairs(p.members) do
        -- the team's own players are not listed as faces (only the characters a pool names itself); every candidate has a card
        if (not p.any_team or p.charas[b]) and IDX.card[b] then
          local k = who(b)
          if cand.pick[k] == nil and real_player(b) then
            cand.pick[k] = b
            cand.order[#cand.order + 1] = k
            if #cand.order > MAX_ROW_FACES then
              cand.over = true
              cand.order[#cand.order] = nil
              break
            end
          end
        end
      end
      c.members, c[lang] = p.members, cand
    end
    local pick, order = cand.pick, cand.order
    if #order == 0 then return "", "" end
    if cand.over and not p.show_candidates then return "", "" end
    local inm = {}
    for _, m in ipairs(marks or {}) do inm[who(m.base)] = true end
    local ids, have = {}, {}
    for i, k in ipairs(order) do
      ids[i] = string.format("%d", pick[k])
      have[i] = inm[k] and "1" or "0"
    end
    return table.concat(ids, ","), table.concat(have, ",")
  end

  -- the nexus is one person (every declared nexus character a version of him): the panel draws his face as the icon
  local function single_nexus(d)
    if d.single_nexus == nil then
      local first, one = nil, true
      for _, b in ipairs(d.nexus_list) do
        local k = person(b, d)
        if first == nil then first = k elseif k ~= first then one = false end
      end
      d.single_nexus = one and first ~= nil
    end
    return d.single_nexus
  end

  local TEAM_NAMES = {}

  -- the name of a slot pool's (first) belong team in that language, "" when the pool names no team
  local function team_name(p, lang)
    local t = p and p.team_list and p.team_list[1]
    if not t then return "" end
    local m = TEAM_NAMES[lang]
    if not m then
      m = {}
      local ok, e = pcall(function()
        emblems()
        local ids, seen = {}, {}
        for _, d in ipairs(LIST) do
          for _, sp in ipairs(d.slots or { d.pool }) do
            local text_id = sp.team_list and TEAM_TEXT[sp.team_list[1] or 0]
            if text_id and not seen[text_id] then seen[text_id] = true; ids[#ids + 1] = text_id end
          end
        end
        local texts = GameText.texts("team_text", lang, ids)
        for _, d in ipairs(LIST) do
          for _, sp in ipairs(d.slots or { d.pool }) do
            local team = sp.team_list and sp.team_list[1]
            local s = team and texts[TEAM_TEXT[team] or 0]
            if s then m[team] = GameText.without_furigana(s) end
          end
        end
      end)
      if not ok then warn("team names (" .. lang .. "): " .. tostring(e)) end
      TEAM_NAMES[lang] = m
    end
    return m[t] or ""
  end

  local function pool_series(p)
    if not (p and p.any_series) then return "" end
    if p.series_text then return p.series_text end
    local out = {}
    for _, s in ipairs(p.series) do
      local n = type(s) == "number" and s or nil
      if not n then
        local ok, v = pcall(VRFW.character.series_of, s)
        n = ok and tonumber(v) or nil
      end
      if n then out[#out + 1] = string.format("%d", n) end
    end
    p.series_text = table.concat(out, ",")
    return p.series_text
  end

  local MAX_ROW_SERIES = 3
  local ROW_SERIES = {}    -- chara_base id -> "a,b,c"
  local function row_series(base)
    if not base or base == 0 then return "" end
    local c = ROW_SERIES[base]
    if c then return c end
    local out = {}
    local ok, ch = pcall(VRFW.character.character, base)
    if ok and type(ch) == "table" and type(ch.appears) == "table" then
      local ks = {}
      for k, on in pairs(ch.appears) do
        if on and tonumber(k) then ks[#ks + 1] = math.floor(tonumber(k)) end
      end
      table.sort(ks)
      for i = 1, math.min(#ks, MAX_ROW_SERIES) do out[i] = string.format("%d", ks[i]) end
    end
    c = table.concat(out, ",")
    ROW_SERIES[base] = c
    return c
  end

  local ANSWER = nil
  local LANGUAGE_OF = {}
  function Synergy.CmdPanel(item, code)
    local sid = u32(item)
    if not PANEL or PANEL.sid ~= sid then return nil end
    local d, st = DECL[sid], PANEL.state
    local lang = LANGUAGE_OF[code or false]
    if lang == nil then
      lang = GameText.language(code)
      local ok, list = pcall(VRFW.files.game_languages)
      if ok and type(list) == "table" then LANGUAGE_OF[code or false] = lang end
    end
    if ANSWER and ANSWER.state == st and ANSWER.lang == lang then
      ANSWER.answer.locators, ANSWER.answer.drawn = PANEL.locators, PANEL.drawn
      return ANSWER.answer
    end
    local rows = {}
    for r, row in ipairs(st.rows) do
      if r > MAX_PANEL_ROWS then break end   -- 4-6 rows: the menu patch draws them as a 2-column grid
      local members = d.slot_members and row.pool ~= nil
      rows[r] = { kind = KIND_NAME[row.kind], name = (row.kind ~= KIND_EMPTY) and name_of(row.base, lang) or "",
        hint = (row.pool and row.pool.hint) or d.hint,
        team_name = (row.kind == KIND_EMPTY) and team_name(row.pool, lang) or "",
        crests = ((row.kind == KIND_EMPTY or row.kind == KIND_FILLED) and not members) and crests_of(row.pool) or "",
        crest = members and crest_of(row.pool) or "",
        faces = (row.kind == KIND_NEXUS_MISSING) and faces_of(d)
          or (row.kind == KIND_NEXUS) and faces_of(d, row.base)
          or (members and row.kind == KIND_EMPTY) and members_faces(row.pool, d) or "",
        single = ((row.kind == KIND_NEXUS or row.kind == KIND_NEXUS_MISSING) and single_nexus(d)) and 1 or 0,
        pool = row.pool and row.pool.key or "",
        base = row.base or 0 }
      local x = rows[r]
      x.have = ""
      if row.kind == KIND_EMPTY and not members and x.faces == "" then x.faces, x.have = candidate_faces(row.pool, d, st.marks, lang) end
      if row.kind == KIND_EMPTY and x.faces ~= "" then
        local first = tonumber(x.faces:match("^(%d+)"))
        if first then x.base, x.name = first, name_of(first, lang) end
      end
      local staff = row.kind == KIND_EMPTY and not members and row.pool and row.pool.role or nil
      x.role = staff or ""
      x.series = staff and pool_series(row.pool)
        or ((row.kind == KIND_FILLED or row.kind == KIND_NEXUS or row.kind == KIND_NEXUS_MISSING) and x.crests ~= "") and row_series(row.base)
        or (#st.rows > MAX_ROWS and x.base ~= 0) and row_series(x.base) or ""
      -- the series order of the candidates (series_order.lua), parallel to faces / crests: the panel sorts its strips by it
      local fr, cr = {}, {}
      for id in x.faces:gmatch("%d+") do fr[#fr + 1] = string.format("%d", SeriesOrder.character(tonumber(id))) end
      local by_emblem = {}
      for _, c in ipairs(row.pool and row.pool.crest_list or {}) do
        if c.emblem then by_emblem[c.emblem] = SeriesOrder.team_crest(c.team, c.era) end
      end
      for id in x.crests:gmatch("%d+") do cr[#cr + 1] = string.format("%d", by_emblem[tonumber(id)] or SeriesOrder.crest(tonumber(id))) end
      x.face_rank, x.crest_rank = table.concat(fr, ","), table.concat(cr, ",")
    end
    local answer = { active = st.active and 1 or 0, extra = st.extra, team = st.team and 1 or 0, rows = rows,
      locators = PANEL.locators, drawn = PANEL.drawn }
    ANSWER = { state = st, lang = lang, answer = answer }
    return answer
  end

  -- the character index and every pool, once, at load; if not readable then, built at the first check
  local tw = VRFW.now_ms()
  index()
  if IDX.ok then
    local kept = VRFW.derived("synergy_pools", { any_version = ANY_VERSION ~= nil }, function()
      local out = { members = {} }
      for _, d in ipairs(LIST) do
        resolve_nexus(d)
        for _, p in ipairs(d.slots or { d.pool }) do Groups.member_list(p) end
      end
      for k, p in pairs(POOLS) do
        if p.members then out.members[k] = p.members end
      end
      out.captains, out.rosters = Groups.team_tables()
      return out
    end)
    Groups.seed_members(kept.members)
    Groups.seed_teams(kept.captains, kept.rosters)
    for _, d in ipairs(LIST) do resolve_nexus(d) end
    info(string.format("index and pools ready at load in %d ms", math.floor(VRFW.now_ms() - tw)))
    -- one line per declared synergy: its state without a team (proves the declaration evaluates end to end)
    for _, d in ipairs(LIST) do
      local ok, st = pcall(evaluate, d, 0)
      if ok then
        local parts = {}
        for _, r in ipairs(st.rows) do parts[#parts + 1] = string.format("%d:%08X", r.kind, r.base) end
        local sizes = {}
        for _, p in ipairs(d.slots or { d.pool }) do sizes[#sizes + 1] = string.format("%s %d", p.key, #(p.members or {})) end
        VRFW.debug("synergy: " .. string.format("%s: ok at load (%s; no-team rows %s)", d.key, table.concat(sizes, ", "), table.concat(parts, " ")))
      else
        warn(string.format("%s: fails at load: %s", d.key, tostring(st)))
      end
    end
  else
    IDX = nil
    info("character index not readable at load: built at the first check")
  end

  if IDX then
    emblems()
    name_ids()
    local okl, lang = pcall(VRFW.files.game_language)
    if okl and type(lang) == "string" and lang ~= "" then
      pcall(name_of, 0, lang)
      pcall(team_name, { team_list = { 0 } }, lang)
    end
    local any = next(IDX.info or {})
    if any then
      pcall(real_player, any)
      pcall(SeriesOrder.character, any)
    end
    pcall(SeriesOrder.crest, 0)
    -- every panel's face lists in the game language are walked here, so a panel's first draw walks no pool on the game thread
    if okl and type(lang) == "string" and lang ~= "" then
      local tf = VRFW.now_ms()
      for _, d in ipairs(LIST) do
        pcall(faces_of, d)
        for _, p in ipairs(d.slots or { d.pool }) do
          if d.slot_members then pcall(members_faces, p, d) else pcall(candidate_faces, p, d, nil, lang) end
        end
      end
      info(string.format("panel face lists (%s) built at load in %d ms", lang, math.floor(VRFW.now_ms() - tf)))
    end
  end

  local names = {}
  for _, d in ipairs(LIST) do
    names[#names + 1] = string.format("%s (%s, %s%d of %s, %s)", d.key, tostring(d.mod), d.has_nexus and "nexus + " or "", d.count,
      d.pool_key, d.slots and ("one per slot" .. (d.skip_nexus_team and ", the nexus's team skipped" or "")
      .. (d.slot_members and ", rows: crest + members" or "")) or d.rule)
  end
  info(string.format("%d synergy(ies): %s; check hook %s, panel hooks %s", #LIST, table.concat(names, "; "),
    VRFW.is_on("SynergyCheck") and "on" or "OFF (not installed)",
    (VRFW.is_on("SynergyDetail") and VRFW.is_on("SynergyDetailRows")) and "on" or "OFF (not installed)"))
end

function Synergy.ShopConditions(layer)
  local on = VRFW.config("shop.synergy_conditions", true)
  if on and type(layer) == "number" and layer ~= 0 then NO_TEAM_LAYERS[u32(layer)] = true end
  return on
end

if #LIST == 0 then
  function Synergy.CmdPanel() return nil end
  info("0 synergies declared (no active mod has content/synergies/*.toml): the game's check and panel unchanged")
end
