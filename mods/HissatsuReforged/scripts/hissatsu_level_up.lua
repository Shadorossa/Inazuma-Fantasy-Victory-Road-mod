
local A = VRFW.auras
local Id = VRFW.ids
local Actors = VRFW.players
local MatchMoveLevel = VRFW.match.move_level

HissatsuReforged = HissatsuReforged or {}
HissatsuReforged.Cmd = HissatsuReforged.Cmd or {}
local TH = HissatsuReforged

local info, warn, err = VRFW.logger("HissatsuReforged")
local band, rshift = bit32.band, bit32.rshift

local u32, hex = Id.unsigned, Id.hex_text

-- a value of this mod's merged config.toml (dotted path), `default` when missing or of another type
local cfg = VRFW.config

local BLOB = "skill_uses.json"
local FILE_VERSION = 2
local MAX_GRADE = 5
local UNIT_STRIDE, UNIT_MAX, UNIT_HDL, UNIT_CHARA = 0x380, 0x60, 0x368, 0x370
local UNIT_SKILLS, UNIT_SKILL_STRIDE, UNIT_SKILL_RANK, UNIT_SKILL_RECAST = 0x30, 0x1C, 0x15, 0x04
local MATCH_USER_TEAM = 0x2C29
local INFO_RECAST = 0x34
local REC_SKILL_LIST, SKILL_ENTRY, SKILL_SLOTS = 0x50, 8, 6
local REC_HEAD_WORDS = 2
local REC_LIST_WORD = math.floor(REC_SKILL_LIST / 4)
local REC_LIST_WORDS = REC_LIST_WORD + SKILL_SLOTS * 2
local REC_PLACED, REC_NATIVE, BOARD_SLOTS = 0x94, 0xC8, 9
local POPUP_TTL_MS, POPUP_MAX = 8000, 16
local MATCH_GAP_MS = 30000
local SWEEP_EVERY_MS = 60000
local SEED_LOG_MAX = 24
local ERR_BAD_ARGS, ERR_NOT_READY, ERR_NOT_ALLOWED = -1, -2, -3

local ON = false
local DEFAULT_TH = { 10, 25, 50, 120 }
local THR = DEFAULT_TH
local MODE = "uses"
local LOG_USES = true
local K = 0.025          -- recast_per_grade (as f32)
local POPUP = true
local USE_CAP = MAX_GRADE - 1
local ITEM_RAISE, ITEM_LAST = 0, 0
local BLOCK_DUP = true               -- [duplicates] block

local function now_ms() return VRFW.now_ms() end

local Memory = VRFW.memory
local read_memory, write_memory, game_global = Memory.read, Memory.write, VRFW.game.global

local function rd_array(t, a, n)
  if not a or a < 0x10000 or n < 1 then return nil end
  local v = VRFW.memory.read_array(t, a, n)
  local ok = v ~= nil
  if ok and type(v) == "table" then return v end
  return nil
end

-- f32 rounding (the engine computes the recast in single precision)
local F32 = nil
local function f32(x)
  F32 = F32 or VRFW.memory.buffer("HissatsuReforged.f32", 8)
  write_memory("f32", F32, x)
  return read_memory("f32", F32) or x
end

-- [HissatsuReforged.Rules] of every active mod's content\hissatsu_level_up\*.toml, later mods win key by key
local RULES = nil

local function rules()
  if RULES then return RULES end
  RULES = {}
  local ok, decl = pcall(VRFW.files.declarations, "content/hissatsu_level_up")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local r = type(d) == "table" and type(d.HissatsuReforged) == "table" and d.HissatsuReforged.Rules or nil
    if type(r) == "table" then
      for k, v in pairs(r) do RULES[k] = v end
    end
  end
  return RULES
end

local function grade_animations()
  local by_key, order = {}, {}
  local ok, decl = pcall(VRFW.files.declarations, "content/hissatsu_level_up")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local list = type(d) == "table" and type(d.HissatsuReforged) == "table" and d.HissatsuReforged.GradeAnimation or nil
    for i, e in ipairs(type(list) == "table" and list or {}) do
      local where = string.format("%s %s entry %d", tostring(f.mod), tostring(f.file), i)
      local t, g, a = type(e) == "table" and e.technique, type(e) == "table" and tonumber(e.grade), type(e) == "table" and e.animation_of
      local ref_ok = function(v) return (type(v) == "string" and v ~= "") or type(v) == "number" end
      if not ref_ok(t) or not g or g ~= math.floor(g) or g < 1 or g > MAX_GRADE + 1 then
        warn(string.format("[[HissatsuReforged.GradeAnimation]] %s: needs `technique` and `grade` 1..%d: left out", where, MAX_GRADE + 1))
      else
        local key = tostring(t) .. "#" .. g
        if by_key[key] == nil then order[#order + 1] = key end
        if e.enabled == false then
          by_key[key] = false
        elseif not ref_ok(a) then
          warn(string.format("[[HissatsuReforged.GradeAnimation]] %s: needs `animation_of` (the move whose cut-in plays): left out", where))
        else
          by_key[key] = { technique = t, grade = g, cutin_of = a }
        end
      end
    end
  end
  local out = {}
  for _, k in ipairs(order) do
    if by_key[k] then out[#out + 1] = by_key[k] end
  end
  return out
end

local function apply_grade_animations()
  local list = grade_animations()
  if #list == 0 then
    info("grade animations: none declared")
    return
  end
  local ok, n, why = pcall(VRFW.cutin.by_grade, list)
  if not ok or not n then
    err("grade animations off: " .. tostring(ok and why or n))
    return
  end
  local parts = {}
  for _, e in ipairs(list) do
    parts[#parts + 1] = string.format("%s from grade %d plays %s's cut-in", tostring(e.technique), e.grade, tostring(e.cutin_of))
  end
  info(string.format("grade animations on (%d): %s; titles: %s", #list, table.concat(parts, "; "), tostring(why or "-")))
end

local function state_on(name)
  local keys = rules()[name]
  if type(keys) ~= "table" then return nil end
  for _, k in ipairs(keys) do
    if type(k) == "string" then
      local ok, v = pcall(VRFW.state.get, k)
      if ok and (v == 1 or v == true) then return k end
    end
  end
  return nil
end

local function thresholds_ok(v)
  if type(v) ~= "table" or #v == 0 or #v > MAX_GRADE then return false, tostring(type(v) == "table" and #v or 0) .. " thresholds (need 1..=5)" end
  if (tonumber(v[1]) or 0) < 1 then return false, "thresholds must be >= 1" end
  for i = 2, #v do
    if (tonumber(v[i]) or 0) <= (tonumber(v[i - 1]) or 0) then return false, "thresholds are not strictly increasing" end
  end
  return true
end

local function max_grade() return #THR end

local function grade_for(uses)
  local g = 0
  for _, t in ipairs(THR) do
    if uses >= t then g = g + 1 else break end
  end
  return g
end

local function use_cap() return math.min(max_grade(), USE_CAP) end

local function next_at(grade)
  if grade >= use_cap() then return 0 end
  return THR[grade + 1] or 0
end

local function uses_for(grade)
  if grade == 0 then return 0 end
  return THR[math.min(grade, max_grade())]
end

local function mode_rank(dup, grade)
  local r = MODE == "max" and math.max(dup, grade) or grade
  return math.min(r, MAX_GRADE)
end

-- { slot, map = { [chara key] = { [skill key] = { uses, grade } } }, n, dirty }; the keys are 8-digit hex texts, the file's own object keys
local function new_store(slot) return { slot = slot, map = {}, n = 0, dirty = false } end

local function key(x) return string.format("%08X", x) end

local function get(st, c, s)
  local m = st.map[key(c)]
  local e = m and m[key(s)]
  if e then return e[1], e[2] end
  return 0, 0
end

local function has(st, c, s)
  local m = st.map[key(c)]
  return m ~= nil and m[key(s)] ~= nil
end

local function put(st, c, s, uses, grade)
  local ck, sk = key(c), key(s)
  local m = st.map[ck]
  if not m then m = {}; st.map[ck] = m end
  if not m[sk] then st.n = st.n + 1 end
  m[sk] = { uses, grade }
  st.dirty = true
end

local function remove(st, c, s)
  local ck, sk = key(c), key(s)
  local m = st.map[ck]
  if m and m[sk] then
    m[sk] = nil
    st.n = st.n - 1
    if next(m) == nil then st.map[ck] = nil end
  end
  st.dirty = true
end

local function add_use(st, c, s)
  local uses, old = get(st, c, s)
  uses = math.min(uses + 1, 4294967295)
  local g = math.min(math.max(old, math.min(grade_for(uses), use_cap())), MAX_GRADE)
  put(st, c, s, uses, g)
  return uses, old, g
end

local function set_grade(st, c, s, grade)
  local g = math.min(grade, max_grade(), MAX_GRADE)
  if g == 0 then
    remove(st, c, s)
    return 0, 0
  end
  put(st, c, s, uses_for(g), g)
  return uses_for(g), g
end

local function seed(st, c, s, grade)
  if c == 0 or s == 0 or has(st, c, s) then return nil end
  local g = math.min(grade, max_grade(), MAX_GRADE)
  if g == 0 then return nil end
  put(st, c, s, uses_for(g), g)
  return g, uses_for(g)
end

local function boost(st, c, s, base, steps)
  if base then seed(st, c, s, base) end
  local _, og = get(st, c, s)
  local want = math.min(og + steps, max_grade(), MAX_GRADE)
  if c == 0 or s == 0 or want == og then return og, og end
  local _, g = set_grade(st, c, s, want)
  return og, g
end

-- Version 1 kept one { chara, skill, uses, grade } row per entry; version 2 is the store's own keyed map, so a load or a write runs no Lua loop.
local function migrate(j)
  if tonumber(j.version) ~= 1 then return nil, "version " .. tostring(j.version) .. " is unknown" end
  local st, auras = new_store(0), 0
  for _, e in ipairs(type(j.entries) == "table" and j.entries or {}) do
    local c, s = u32(e[1]), u32(e[2])
    if c ~= 0 and s ~= 0 then
      if A.type(s) ~= nil then
        auras = auras + 1
      else
        put(st, c, s, u32(e[3]), math.min(tonumber(e[4]) or 0, MAX_GRADE))
      end
    end
  end
  info(string.format("skill uses file version 1 -> %d: %d entries kept, %d aura-skill entries dropped (aura skills have no grade)", FILE_VERSION, st.n, auras))
  return { version = FILE_VERSION, count = st.n, players = st.map }
end

local DOC = VRFW.save.doc.new(BLOB, { version = FILE_VERSION, stage = true, log = "hissatsu level up", migrate = migrate,
  default = function() return { version = FILE_VERSION, count = 0, players = {} } end })

-- The framework's JSON writer orders object keys itself, so the store goes out as it is.
local function to_doc(st)
  return { version = FILE_VERSION, slot = st.slot, count = st.n, players = st.map }
end

local function load_store(slot)
  local st = new_store(slot)
  local j, state = DOC:load(slot)
  if state == "bad" then return st end
  if type(j.players) == "table" then st.map = j.players end
  st.n = math.max(math.floor(tonumber(j.count) or 0), 0)
  st.dirty = state == "migrated"
  info(string.format("slot %d: %d (player, move) entries loaded%s", slot, st.n, st.dirty and " (migrated, written at the next game save)" or ""))
  return st
end

local store = new_store(0)
local parked = nil

local function commit_on_save()
  local ok, ready = pcall(VRFW.slots.ready)
  return ok and ready == true
end

local function cur()
  local slot = VRFW.slots.active()
  if store.slot == slot then return store end
  local from = store.slot
  local okk, sink = pcall(VRFW.session.sink)
  local overlay_in = from ~= 0 and okk and sink == from
  if overlay_in then
    info(string.format("overlay session over slot %d: its store is parked in memory (%d entries%s), slot %d's store is loaded; slot %d's data is not written meanwhile",
      from, store.n, store.dirty and ", uses not saved by the game yet kept" or "", slot, from))
    parked = store
    store = load_store(slot)
  elseif parked and parked.slot == slot then
    if store.dirty then warn(string.format("slot %d -> %d: dropping uses not saved by the game", from, slot)) end
    store = parked
    parked = nil
    info(string.format("slot %d is back after the overlay session: its parked store is used again (%d entries)", slot, store.n))
    if store.dirty and commit_on_save() then
      DOC:write(to_doc(store), slot)
    end
  else
    if store.dirty and from ~= 0 then warn(string.format("slot %d -> %d: dropping uses not saved by the game", from, slot)) end
    parked = nil
    store = load_store(slot)
  end
  return store
end

-- Writes the store of its slot: staged for the game's save (cleared then), or written at once outside a save.
local function commit(st, why)
  if not st.dirty or st.slot == 0 then return end
  local ok, where = DOC:write(to_doc(st), st.slot)
  if ok then
    st.dirty = false
  else
    err(string.format("cannot write slot %d (%s): %s", st.slot, why, tostring(where)))
  end
end

local grades_cache = {}

local function grades_of(param)
  if param == 0 then return {} end
  local c = grades_cache[param]
  if c then return c end
  local ok, list = pcall(VRFW.traits.move_grades, param)
  if not ok or type(list) ~= "table" then return {} end
  c = {}
  for _, e in ipairs(list) do
    local m, g = u32(e[1]), tonumber(e[2]) or 0
    if m ~= 0 and g > 0 and c[m] == nil then c[m] = g end
  end
  grades_cache[param] = c
  return c
end

local function record(hdl)
  local ok, r = pcall(VRFW.character.record, hdl)
  if ok and type(r) == "table" then return r end
  return nil
end

local function is_saved_handle(h)
  local k = band(rshift(h, 12), 0xF)
  return h ~= 0 and (k == 0 or k == 7)
end

local function is_chara_handle(h)
  local k = band(rshift(h, 12), 0xF)
  return h ~= 0 and k < 0xD and k ~= 6
end

local function owner(h)
  if h == 0 then return nil end
  local ok, o = pcall(VRFW.character.owner, h)
  if ok and type(o) == "number" and o ~= 0 then return o end
  return nil
end

local function write_saved_rank(hdl, skill, f)
  local r = record(hdl)
  if not r or not r.addr then return nil end
  for i = 0, SKILL_SLOTS - 1 do
    local e = r.addr + REC_SKILL_LIST + i * SKILL_ENTRY
    if read_memory("u32", e) == skill then
      local cur_r = read_memory("u8", e + 4)
      if cur_r == nil then return nil end
      local n = f(cur_r)
      if n ~= nil and n ~= cur_r and write_memory("u8", e + 4, n) then return i, cur_r, n end
      return i, cur_r, cur_r
    end
  end
  return nil
end

local function unit_slot(unit, skill)
  for i = 0, SKILL_SLOTS - 1 do
    if read_memory("u32", unit + UNIT_SKILLS + i * UNIT_SKILL_STRIDE) == skill then return i end
  end
  return nil
end

local function live_rank_addr(unit, slot) return unit + UNIT_SKILLS + slot * UNIT_SKILL_STRIDE + UNIT_SKILL_RANK end

local INFO_OUT, SKILL_ID = nil, nil
local install_hits = 0

local function recast_value(base, rank)
  if base ~= base or base == math.huge or base == -math.huge then return 0 end
  local m = f32(1.0 + f32(K * math.min(rank, MAX_GRADE)))
  return math.max(math.floor(f32(base * m)), 0)
end

local function apply_recast(unit, slot)
  if slot >= SKILL_SLOTS then return nil end
  local entry = unit + UNIT_SKILLS + slot * UNIT_SKILL_STRIDE
  local id = read_memory("u32", entry)
  if not id or id == 0 then return nil end
  local rank = read_memory("u8", entry + UNIT_SKILL_RANK)
  local tbl = game_global("hissatsu_level_up_skill_table")
  if not rank or not tbl then return nil end
  INFO_OUT = INFO_OUT or VRFW.memory.buffer("HissatsuReforged.info", 8)
  SKILL_ID = SKILL_ID or VRFW.memory.buffer("HissatsuReforged.id", 8)
  write_memory("ptr", INFO_OUT, 0)
  write_memory("u32", SKILL_ID, id)
  if not pcall(VRFW.call, "Technique.SkillInfoFind", tbl, INFO_OUT, SKILL_ID) then return nil end
  local inf = read_memory("ptr", INFO_OUT) or 0
  if inf < 0x10000 then return nil end
  local base = read_memory("f32", inf + INFO_RECAST)
  local old = read_memory("f32", entry + UNIT_SKILL_RECAST)
  if not base or not old then return nil end
  local new = recast_value(base, rank)
  if old ~= new then write_memory("f32", entry + UNIT_SKILL_RECAST, new) end
  return id, rank, old, new
end

local match_epoch, last_install, rule_logged = 1, 0, 0

local function log_rule(key, why)
  if rule_logged == match_epoch then return end
  rule_logged = match_epoch
  info("rank-up by use off while " .. key .. " ([HissatsuReforged.Rules] no_rank_up_states; " .. why .. "): moves keep their grades; no use counted, no grade-up, no banner")
end

local function note_install()
  local now = math.max(now_ms(), 1)
  local prev = last_install
  last_install = now
  if prev == 0 or now - prev > MATCH_GAP_MS then
    match_epoch = match_epoch + 1
    if ON then
      local k = state_on("no_rank_up_states")
      if k then log_rule(k, "match setup") end
    end
  end
end

local popups = {}   -- { { skill, grade, at } } oldest first
local telop_ok = true

local function popup_prune(now)
  local keep = {}
  for _, p in ipairs(popups) do
    if now - p.at <= POPUP_TTL_MS then keep[#keep + 1] = p end
  end
  popups = keep
end

local function popup_push(skill, grade)
  local now = now_ms()
  popup_prune(now)
  for i = #popups, 1, -1 do
    if popups[i].skill == skill then table.remove(popups, i) end
  end
  if #popups >= POPUP_MAX then table.remove(popups, 1) end
  popups[#popups + 1] = { skill = skill, grade = grade, at = now }
end

local function popup_take(skill)
  popup_prune(now_ms())
  for i, p in ipairs(popups) do
    if p.skill == skill then
      table.remove(popups, i)
      return p.grade
    end
  end
  return nil
end

local function show_popup(skill, grade)
  if not (POPUP and telop_ok) then return "" end
  popup_push(skill, grade)
  SKILL_ID = SKILL_ID or VRFW.memory.buffer("HissatsuReforged.id", 8)
  write_memory("u32", SKILL_ID, skill)
  local ok, e = pcall(VRFW.call, "HissatsuReforged.OpenSkillTelop", SKILL_ID)
  if ok then return ", banner opened" end
  err("OpenCommonSkillTelop failed (" .. tostring(e) .. "): banner disabled")
  telop_ok = false
  return ", banner FAILED"
end

local used_hits = 0

local function raise(unit, slot, own, chara, skill, old_grade, grade)
  local g = math.min(grade, MAX_GRADE)
  local live
  if slot then
    local a = live_rank_addr(unit, slot)
    local c = read_memory("u8", a)
    if c and c < g then
      write_memory("u8", a, g)
      local _, _, o, n = apply_recast(unit, slot)
      live = o and string.format("live %d->%d, recast %s->%s", c, g, tostring(o), tostring(n)) or string.format("live %d->%d", c, g)
    elseif c then
      live = string.format("live %d kept", c)
    else
      live = "live unreadable"
    end
  else
    live = "live: move not in unit table"
  end
  local up = function(c) if c < g then return g end return nil end
  local i, o, n = write_saved_rank(own, skill, up)
  local saved = i and string.format("saved list[%d] %d->%d", i, o, n) or "saved: move not in skill_list"
  if chara ~= own then
    local ci, co, cn = write_saved_rank(chara, skill, up)
    if ci then saved = saved .. string.format(", copy list[%d] %d->%d", ci, co, cn) end
  end
  return string.format("; GRADE UP %d->%d: %s, %s%s", old_grade, g, live, saved, show_popup(skill, g))
end

local function on_used(ev)
  if not ON then return end
  local hdl = u32(ev.args[1])
  local skill = read_memory("u32", ev.args[2] or 0)
  if not skill or skill == 0 then return end
  if A.type(skill) ~= nil then return end -- aura skills have no grade
  if A.is_spirit_move(skill) then
    info(string.format("spirit move %s used by actor 0x%X: non-miximax aura move, no grade (not counted)", hex(skill), hdl))
    return
  end
  local off = state_on("no_rank_up_states")
  if off then
    log_rule(off, "first move used")
    return
  end
  used_hits = used_hits + 1
  local n = used_hits
  local a = Actors.of(hdl)
  if not a then return end
  local actor, team = a.address, a.team
  local unit = Actors.unit_of(actor) or 0
  local chara = unit >= 0x10000 and (read_memory("u32", unit + UNIT_CHARA) or 0) or 0
  local m = game_global("hissatsu_level_up_match")
  local user = m and read_memory("u8", m + MATCH_USER_TEAM)
  if team == nil or team ~= user then return end
  local own = is_saved_handle(chara) and chara or VRFW.character.copy_owner(chara)
  if not own then
    info(string.format("call #%d actor 0x%X skill %s: unit 0x%X chara %s (kind %d) has no saved owner: not counted",
      n, hdl, hex(skill), unit, hex(chara), band(rshift(chara, 12), 0xF)))
    return
  end
  local slot = unit_slot(unit, skill)
  local st = cur()
  local r = record(own)
  local param = r and u32(r.param) or 0
  local rg = grades_of(param)[skill]
  if rg then
    local sg, su = seed(st, own, skill, rg)
    if sg then
      info(string.format("recruit grade: chara %s (card %s) skill %s starts at grade %d (uses %d) [first use]", hex(own), hex(param), hex(skill), sg, su))
    end
  end
  local uses, old, g = add_use(st, own, skill)
  local extra = ""
  if g > old then extra = raise(unit, slot, own, chara, skill, old, g) end
  if LOG_USES or g > old then
    info(string.format("use #%d: chara %s (match chara %s kind %d, actor 0x%X) skill %s unit slot %s -> uses %d, grade %d (next at %d)%s",
      n, hex(own), hex(chara), band(rshift(chara, 12), 0xF), hdl, hex(skill), tostring(slot), uses, g, next_at(g), extra))
  end
end

local swept_slot, swept_at = nil, 0
local build_kinds = {}
local SWEEP_STEP = 200
local sweep_list, sweep_pos = nil, 1
local sweep_seeded, sweep_charas, sweep_raised = 0, 0, 0

-- Seeds the declared grades of one saved record's moves at once: the walk keeps no list that grows with the save.
local function sweep_record(st, handle, param, declared)
  local r = record(handle)
  if not r or not r.addr then return end
  local any = false
  for i = 0, SKILL_SLOTS - 1 do
    local id = read_memory("u32", r.addr + REC_SKILL_LIST + i * SKILL_ENTRY)
    local dg = id and id ~= 0 and A.type(id) == nil and not A.is_spirit_move(id) and declared[id]
    local g, u = nil, nil
    if dg then g, u = seed(st, handle, id, dg) end
    if g then
      any = true
      sweep_seeded = sweep_seeded + 1
      local li, o, nr = write_saved_rank(handle, id, function(c) if g > c then return g end return nil end)
      if li and nr > o then sweep_raised = sweep_raised + 1 end
      if sweep_seeded <= SEED_LOG_MAX then
        info(string.format("recruit grade: chara %s (card %s) skill %s starts at grade %d (uses %d), saved list %s [sweep]",
          hex(handle), hex(param), hex(id), g, u, li and string.format("[%d] %d->%d", li, o, nr) or "none"))
      end
    end
  end
  if any then sweep_charas = sweep_charas + 1 end
end

local function sweep(st)
  local slot = st.slot
  if sweep_list == nil then
    local now = now_ms()
    if swept_slot == slot and now - swept_at < SWEEP_EVERY_MS then return end
    swept_slot, swept_at = slot, now
    local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param" })
    if not ok or type(columns) ~= "table" then return end
    sweep_list, sweep_pos = columns, 1
    sweep_seeded, sweep_charas, sweep_raised = 0, 0, 0
  elseif swept_slot ~= slot then
    sweep_list, sweep_pos = nil, 1   -- the slot changed mid-walk: start again on the next build
    return
  end
  local handles, params = sweep_list.handle, sweep_list.param
  local last = math.min(#handles, sweep_pos + SWEEP_STEP - 1)
  for n = sweep_pos, last do
    local param = u32(params[n])
    local declared = grades_of(param)
    if next(declared) ~= nil then sweep_record(st, u32(handles[n]), param, declared) end
  end
  sweep_pos = last + 1
  if sweep_pos <= #handles then return end
  sweep_list, sweep_pos = nil, 1
  if sweep_seeded > 0 then
    info(string.format("recruit grades sweep (slot %d): %d move(s) seeded on %d saved character(s), %d saved rank(s) raised (%d saved records scanned)",
      slot, sweep_seeded, sweep_charas, sweep_raised, #handles))
  end
end

local build_owners = {}

local function build_owner(hdl, head)
  local card = u32(head[2] or 0)
  local o = build_owners[hdl]
  if o and o.card == card then return o.own, o.param end
  local own = is_saved_handle(hdl) and hdl or owner(hdl)
  if not own then return nil end
  local param
  if own == hdl then
    param = u32(head[2])
  else
    local r = record(own)
    param = r and u32(r.param) or 0
  end
  build_owners[hdl] = { card = card, own = own, param = param }
  return own, param
end

local function on_build(ev)
  if not ON then return end
  local obj, list = ev.args[1] or 0, ev.args[2] or 0
  local head = rd_array("u32", read_memory("ptr", obj + 8), REC_HEAD_WORDS)
  local hdl = head and u32(head[1])
  if not hdl or not is_chara_handle(hdl) then return end
  local own, param = build_owner(hdl, head)
  if not own then return end
  local list_words = rd_array("u64", list, 2)
  if not list_words then return end
  local entries, count = list_words[1], math.min(list_words[2], 16)
  local words = count > 0 and rd_array("u32", entries, count * 2) or {}
  if count > 0 and #words == 0 then return end
  local declared = grades_of(param)
  local st = cur()
  local changes = {}
  for i = 0, count - 1 do
    local e = entries + i * SKILL_ENTRY
    local id, tail = u32(words[i * 2 + 1]), words[i * 2 + 2]
    local dup, flag = band(tail, 0xFF), band(rshift(tail, 16), 0xFF)
    if id ~= 0 and flag == 0 and A.type(id) == nil and not A.is_spirit_move(id) then
      local dg = declared[id]
      if dg then
        local sg, su = seed(st, own, id, dg)
        if sg then
          info(string.format("recruit grade: chara %s (card %s) skill %s starts at grade %d (uses %d) [list build]", hex(own), hex(param), hex(id), sg, su))
        end
      end
      local _, g = get(st, own, id)
      local rank = mode_rank(dup, g)
      if rank ~= dup and write_memory("u8", e + 4, rank) then
        changes[#changes + 1] = string.format("(%s, %d, %d)", hex(id), dup, rank)
      end
    end
  end
  sweep(st)
  local kind = band(rshift(hdl, 12), 0xF)
  if not build_kinds[kind] then
    build_kinds[kind] = true
    info(string.format("first skill_list build of kind %d: chara %s (owner %s), %d entries, (skill, dupRank, rank) [%s]",
      kind, hex(hdl), hex(own), count, table.concat(changes, ", ")))
  end
end

local rival_grade
local grade_of
local REQUEST_GRADE = nil

local function rival_list_grade(hdl)
  if is_saved_handle(hdl) or owner(hdl) then return nil end
  local ok, in_match = pcall(VRFW.in_match)
  if not ok or not in_match then return REQUEST_GRADE end
  return rival_grade()
end

local function sync_saved_ranks(hdl, addr)
  if not ON or not hdl or hdl == 0 or not is_chara_handle(hdl) then return {} end
  if not addr then
    local r = record(hdl)
    addr = r and r.addr
  end
  -- the record's handle, card and skill_list in one read
  local w = rd_array("u32", addr, REC_LIST_WORDS)
  if not w or u32(w[1]) ~= hdl then return {} end
  local rival = rival_list_grade(hdl)
  local own = is_saved_handle(hdl) and hdl or owner(hdl) or hdl
  local st = cur()
  local declared = grades_of(u32(w[2]))
  local changes = {}
  for i = 0, SKILL_SLOTS - 1 do
    local e = addr + REC_SKILL_LIST + i * SKILL_ENTRY
    local k = REC_LIST_WORD + i * 2 + 1
    local id, cur_r = u32(w[k]), band(w[k + 1], 0xFF)
    if id ~= 0 and A.type(id) == nil and not A.is_spirit_move(id) then
      local want = rival
      if not want then
        if declared[id] then seed(st, own, id, declared[id]) end
        local _, g = get(st, own, id)
        want = mode_rank(cur_r, g)
      end
      if want ~= cur_r and write_memory("u8", e + 4, want) then
        changes[#changes + 1] = string.format("(%s, %d, %d)", hex(id), cur_r, want)
      end
    end
  end
  return changes
end

function HissatsuReforged.AfterSetSkill(args)
  local hdl = u32(type(args) == "table" and tonumber(args[1]) or 0)
  local changes = sync_saved_ranks(hdl)
  if #changes > 0 then
    info(string.format("CMND_SET_SKILL on chara %s: saved ranks follow the stored grades [%s]", hex(hdl), table.concat(changes, ", ")))
  end
  return nil
end

local function on_moves(ev)
  local obj = ev.args and ev.args[1] or 0
  if obj < 0x10000 then return end
  local rec = read_memory("ptr", obj + 8)
  local hdl = rec and read_memory("u32", rec)
  local changes = sync_saved_ranks(hdl, hdl and is_saved_handle(hdl) and rec or nil)
  if #changes > 0 then
    VRFW.debug(string.format("HissatsuReforged: list rebuilt for chara %s: saved ranks follow the stored grades [%s]", hex(hdl), table.concat(changes, ", ")))
  end
end

local install_synced = 0
local rival_logged = 0
local RIVAL_LISTED = {}

function grade_of(rule)
  if type(rule) ~= "table" then return nil end
  local g = rule.grade == "max" and MAX_GRADE or tonumber(rule.grade)
  if not g then return nil end
  return math.max(0, math.min(math.floor(g), MAX_GRADE))
end

-- the grade a match move level rule gives the opponents' moves in the running match, nil when none holds
function rival_grade()
  local ok, rule = pcall(MatchMoveLevel.running, "rival")
  if not ok or type(rule) ~= "table" then return nil end
  local g = grade_of(rule)
  if not g then return nil end
  if rival_logged ~= match_epoch then
    rival_logged = match_epoch
    info(string.format("match move level: rival moves at grade %d of %d for this match (rule of %s)", g, MAX_GRADE, tostring(rule.source)))
  end
  return g
end

local function sync_install_rank(unit, slot)
  if slot >= SKILL_SLOTS then return end
  local entry = unit + UNIT_SKILLS + slot * UNIT_SKILL_STRIDE
  local id, cur_r = read_memory("u32", entry), read_memory("u8", entry + UNIT_SKILL_RANK)
  if not id or id == 0 or not cur_r or A.type(id) ~= nil or A.is_spirit_move(id) then return end
  local chara = read_memory("u32", unit + UNIT_CHARA) or 0
  local own = chara ~= 0 and owner(chara) or nil
  if not own then
    local g = rival_grade()
    if g and g ~= cur_r then write_memory("u8", entry + UNIT_SKILL_RANK, g) end
    -- his list (what the team views read) takes the same grade, once per player and match
    if g and chara ~= 0 and RIVAL_LISTED.epoch ~= match_epoch then RIVAL_LISTED = { epoch = match_epoch } end
    if g and chara ~= 0 and not RIVAL_LISTED[chara] then
      RIVAL_LISTED[chara] = true
      local changes = sync_saved_ranks(chara)
      if #changes > 0 then
        info(string.format("match install: rival chara %s list follows grade %d [%s]", hex(chara), g, table.concat(changes, ", ")))
      end
    end
    return
  end
  local _, g = get(cur(), own, id)
  local want = mode_rank(cur_r, g)
  if state_on("max_grade_states") then want = MAX_GRADE end
  if want ~= cur_r and write_memory("u8", entry + UNIT_SKILL_RANK, want) then
    install_synced = install_synced + 1
    if install_synced <= 24 then
      info(string.format("match install: chara %s (owner %s) skill %s live rank %d -> %d (stored grade)", hex(chara), hex(own), hex(id), cur_r, want))
    end
  end
end

local function on_install(ev)
  note_install()
  local unit = ev.args[1] or 0
  if unit < 0x10000 then return end
  sync_install_rank(unit, band(ev.args[2] or 0, 0xFF))
  local id, rank, old, new = apply_recast(unit, band(ev.args[2] or 0, 0xFF))
  if id then
    install_hits = install_hits + 1
    if install_hits == 1 then
      local ch = read_memory("u32", unit + UNIT_CHARA) or 0
      info(string.format("first recast install: unit chara %s (kind %d) skill %s rank %d: %s -> %s", hex(ch), band(rshift(ch, 12), 0xF), hex(id), rank, tostring(old), tostring(new)))
    end
  end
end

local function item_of(inv)
  if not inv or inv == 0 then return 0 end
  local ok, item = pcall(VRFW.item.of_inv, inv)
  return ok and u32(item or 0) or 0
end

local function same_set(t, s)
  if t == s then return false end
  if t >= 3 and t <= 5 and s >= 6 and s <= 8 then return false end
  if t >= 6 and t <= 8 and s >= 3 and s <= 5 then return false end
  return true
end

-- may `item` go on board slot `slot` of card `hdl`?
function HissatsuReforged.CanPlace(hdl, slot, item)
  hdl, item = u32(tonumber(hdl) or 0), u32(tonumber(item) or 0)
  slot = math.floor(tonumber(slot) or 0xFF)
  if not BLOCK_DUP or hdl == 0 or item == 0 then return true, -1 end
  local r = record(hdl)
  if not r or not r.addr then return true, -1 end
  -- the placed and the native inventory handles of the whole board in two reads (one per slot when not readable at once)
  local placed = rd_array("u32", r.addr + REC_PLACED, BOARD_SLOTS)
  local native = rd_array("u32", r.addr + REC_NATIVE, BOARD_SLOTS)
  for s = 0, BOARD_SLOTS - 1 do
    if same_set(slot, s) then
      local p = placed and placed[s + 1]
      if not placed then p = read_memory("u32", r.addr + REC_PLACED + s * 4) end
      local inv = u32(p or 0)
      if inv == 0 then
        local n = native and native[s + 1]
        if not native then n = read_memory("u32", r.addr + REC_NATIVE + s * 4) end
        inv = u32(n or 0)
      end
      if inv ~= 0 and item_of(inv) == item then return false, s end
    end
  end
  return true, -1
end

local CACHE_CALLS = 4096
local RECORD_WORDS = math.floor((REC_NATIVE + BOARD_SLOTS * 4) / 4)   -- handle .. the last native board handle
local PLACED_WORD, NATIVE_WORD = math.floor(REC_PLACED / 4), math.floor(REC_NATIVE / 4)
local inv_items, record_addrs, boards, cache_calls = {}, {}, {}, 0

local function drop_board_caches()
  inv_items, record_addrs, boards, cache_calls = {}, {}, {}, 0
  return nil
end

local function cached_item(inv)
  if inv == 0 then return 0 end
  local item = inv_items[inv]
  if item == nil then
    item = item_of(inv)
    inv_items[inv] = item
  end
  return item
end

local function record_words(hdl)
  local addr = record_addrs[hdl]
  local w = addr and rd_array("u32", addr, RECORD_WORDS)
  if w and u32(w[1]) == hdl then return w end
  local r = record(hdl)
  addr = r and r.addr
  w = addr and rd_array("u32", addr, RECORD_WORDS)
  if not w or u32(w[1]) ~= hdl then
    record_addrs[hdl] = nil
    return nil
  end
  record_addrs[hdl] = addr
  return w
end

-- the item ids on the 9 board slots of `hdl` ([slot] = item, 0 = empty), recomputed when a board handle changed
local function board_items(hdl)
  local w = record_words(hdl)
  if not w then return nil end
  local b = boards[hdl]
  if b then
    local same = true
    for s = 1, BOARD_SLOTS do
      if b.placed[s] ~= w[PLACED_WORD + s] or b.native[s] ~= w[NATIVE_WORD + s] then
        same = false
        break
      end
    end
    if same then return b.items end
  end
  b = { placed = {}, native = {}, items = {} }
  for s = 1, BOARD_SLOTS do
    local p, n = w[PLACED_WORD + s], w[NATIVE_WORD + s]
    b.placed[s], b.native[s] = p, n
    local inv = u32(p or 0)
    if inv == 0 then inv = u32(n or 0) end
    b.items[s - 1] = cached_item(inv)
  end
  boards[hdl] = b
  return b.items
end

local function can_place_cached(hdl, slot, item)
  local items = board_items(hdl)
  if not items then return TH.CanPlace(hdl, slot, item) end
  for s = 0, BOARD_SLOTS - 1 do
    if same_set(slot, s) and items[s] == item then return false, s end
  end
  return true, -1
end

local dup_refusals = 0

local function on_can_equip(ev)
  if not BLOCK_DUP then return nil end
  local args = ev.args
  local hdl, inv = u32(args[1]), u32(args[2])
  if hdl == 0 or inv == 0 then return nil end
  cache_calls = cache_calls + 1
  if cache_calls > CACHE_CALLS then drop_board_caches() end
  local item = cached_item(inv)
  if item == 0 then return nil end
  local slot = band(args[5] or 0xFF, 0xFF)
  local ok, other = can_place_cached(hdl, slot, item)
  if ok then return nil end
  dup_refusals = dup_refusals + 1
  if dup_refusals <= 50 then
    info(string.format("one copy per set: chara %s item %s refused on board slot %d (already on slot %d)", hex(hdl), hex(item), slot, other))
  end
  return { ret = 0 }
end

local function apply_grade(hdl, skill, g)
  local pick = function(c)
    local n = mode_rank(c, g)
    if n ~= c then return n end
    return nil
  end
  local i, o, n = write_saved_rank(hdl, skill, pick)
  local saved = i and string.format("[%d] %d->%d", i, o, n) or "none"
  local live = 0
  local units = game_global("Match.SoccerUnits")
  if units then
    for k = 0, UNIT_MAX - 1 do
      local u = units + k * UNIT_STRIDE
      if (read_memory("u32", u + UNIT_HDL) or 0) ~= 0 then
        local ch = read_memory("u32", u + UNIT_CHARA) or 0
        if ch ~= 0 and (ch == hdl or owner(ch) == hdl) then
          if ch ~= hdl then write_saved_rank(ch, skill, pick) end
          local s = unit_slot(u, skill)
          if s then
            local a = live_rank_addr(u, s)
            local c = read_memory("u8", a)
            local nr = c and pick(c)
            if nr then
              write_memory("u8", a, nr)
              apply_recast(u, s)
            end
            live = live + 1
          end
        end
      end
    end
  end
  return saved, live
end

function HissatsuReforged.Uses(hdl, skill)
  hdl, skill = u32(tonumber(hdl) or 0), u32(tonumber(skill) or 0)
  if hdl == 0 or skill == 0 then return ERR_BAD_ARGS, ERR_BAD_ARGS, 0 end
  if not ON then return ERR_NOT_READY, ERR_NOT_READY, 0 end
  if A.is_spirit_move(skill) then return 0, 0, 0 end -- keshin / totem moves have no grade
  local key = owner(hdl) or hdl
  local uses, g = get(cur(), key, skill)
  return uses, g, next_at(g)
end

function HissatsuReforged.Grade(hdl, skill)
  local _, g = TH.Uses(hdl, skill)
  return math.max(tonumber(g) or 0, 0)
end

function HissatsuReforged.Cmd.Uses(hdl, skill) return TH.Uses(hdl, skill) end

function HissatsuReforged.Cmd.Set(hdl, skill, grade)
  hdl, skill = u32(tonumber(hdl) or 0), u32(tonumber(skill) or 0)
  local gr = tonumber(grade)
  if gr then gr = gr >= 0 and math.floor(gr) or math.ceil(gr) end
  if not ON or not gr or gr < 0 or gr > MAX_GRADE or not is_saved_handle(hdl) or skill == 0 then
    info(string.format("RANK_SET(%s, %s, %s) refused (bad args / not active)", hex(hdl), hex(skill), tostring(grade)))
    return false, ERR_BAD_ARGS
  end
  local st = cur()
  local _, g = set_grade(st, hdl, skill, gr)
  local saved, live = apply_grade(hdl, skill, g)
  info(string.format("RANK_SET(%s, %s, %d) -> grade %d, saved %s, live units %d", hex(hdl), hex(skill), gr, g, saved, live))
  return true, g
end

function HissatsuReforged.Cmd.Boost(hdl, skill, steps)
  hdl, skill = u32(tonumber(hdl) or 0), u32(tonumber(skill) or 0)
  steps = tonumber(steps) or 1
  if not ON then return false, ERR_NOT_READY, 0 end
  if not is_saved_handle(hdl) or skill == 0 or steps < 1 or steps > MAX_GRADE or steps ~= math.floor(steps) then
    info(string.format("RANK_BOOST(%s, %s, %s) refused (bad args)", hex(hdl), hex(skill), tostring(steps)))
    return false, ERR_BAD_ARGS, 0
  end
  local why = state_on("boost_states")
  if not why then
    info(string.format("RANK_BOOST(%s, %s, %d) refused: no [HissatsuReforged.Rules] boost_states key is on", hex(hdl), hex(skill), steps))
    return false, ERR_NOT_ALLOWED, 0
  end
  if A.type(skill) ~= nil or A.is_spirit_move(skill) then
    info(string.format("RANK_BOOST(%s, %s) refused: aura / spirit moves have no grade", hex(hdl), hex(skill)))
    return false, ERR_BAD_ARGS, 0
  end
  local r = record(hdl)
  local param = r and u32(r.param) or 0
  local base = grades_of(param)[skill]
  local st = cur()
  local old, g = boost(st, hdl, skill, base, steps)
  local saved, live = apply_grade(hdl, skill, g)
  info(string.format("boost (%s): chara %s (card %s, card grade %s) skill %s +%d: grade %d -> %d (slot %d store), saved %s, live units %d",
    why, hex(hdl), hex(param), tostring(base), hex(skill), steps, old, g, st.slot, saved, live))
  return true, g, old
end

local IT_OK, IT_NOT_ITEM, IT_NO_GRADE, IT_CAPPED, IT_NEEDS_PREV, IT_NOT_LISTED = 0, 1, 2, 3, 4, 5

-- is `skill` one of the player's moves as a skill view shows them?
local function in_set(hdl, skill)
  local r = record(hdl)
  if not r or not r.addr then return nil end
  for i = 0, SKILL_SLOTS - 1 do
    if read_memory("u32", r.addr + REC_SKILL_LIST + i * SKILL_ENTRY) == skill then return "list" end
  end
  for s = 0, BOARD_SLOTS - 1 do
    for _, at in ipairs({ REC_PLACED, REC_NATIVE }) do
      local inv = u32(read_memory("u32", r.addr + at + s * 4) or 0)
      if inv ~= 0 and item_of(inv) == skill then return "board" end
    end
  end
  return nil
end

function HissatsuReforged.Items()
  return ITEM_RAISE, ITEM_LAST, use_cap(), MAX_GRADE
end

function HissatsuReforged.Cmd.Items() return TH.Items() end

function HissatsuReforged.Cmd.Item(hdl, skill, item, apply)
  hdl, skill, item = u32(tonumber(hdl) or 0), u32(tonumber(skill) or 0), u32(tonumber(item) or 0)
  apply = apply == true or apply == 1
  if hdl == 0 or skill == 0 or item == 0 or not is_saved_handle(hdl) then return ERR_BAD_ARGS, 0, 0 end
  if not ON then return ERR_NOT_READY, 0, 0 end
  if item ~= ITEM_RAISE and item ~= ITEM_LAST then return IT_NOT_ITEM, 0, 0 end
  if A.type(skill) ~= nil or A.is_spirit_move(skill) then return IT_NO_GRADE, 0, 0 end
  local where = in_set(hdl, skill)
  if not where then
    info(string.format("rank item %s: chara %s skill %s refused: in neither the skill list nor the board", hex(item), hex(hdl), hex(skill)))
    return IT_NOT_LISTED, 0, 0
  end
  local r = record(hdl)
  local param = r and u32(r.param) or 0
  local base = grades_of(param)[skill]
  local st = cur()
  if base then seed(st, hdl, skill, base) end   -- the card's own grade first (as a use or a boost would)
  local uses, old = get(st, hdl, skill)
  local want
  if item == ITEM_RAISE then
    if old >= MAX_GRADE - 1 then return IT_CAPPED, old, old end
    want = old + 1
  else
    if old >= MAX_GRADE then return IT_CAPPED, old, old end
    if old ~= MAX_GRADE - 1 then return IT_NEEDS_PREV, old, old end
    want = MAX_GRADE
  end
  if not apply then return IT_OK, old, want end
  put(st, hdl, skill, math.max(uses, uses_for(want)), want)
  local saved, live = apply_grade(hdl, skill, want)
  info(string.format("rank item %s: chara %s (card %s) skill %s (from the %s) grade %d -> %d (slot %d store), saved %s, live units %d",
    hex(item), hex(hdl), hex(param), hex(skill), where, old, want, st.slot, saved, live))
  return IT_OK, old, want
end

function HissatsuReforged.Cmd.Popup(skill)
  skill = u32(tonumber(skill) or 0)
  local g = (skill ~= 0 and ON) and popup_take(skill) or nil
  if not g then return false, 0, "" end
  info(string.format("banner for skill %s: grade %d (Nv.%d)", hex(skill), g, g + 1))
  return true, g, ""
end

local OLD_BOOK_KEY = "abl_ub000001"
local retail_stock_logged = {}   -- slot -> true

function HissatsuReforged.Cmd.RetailStock(count)
  local slot = VRFW.slots.active()
  if retail_stock_logged[slot] or ITEM_RAISE == 0 then return false end
  count = tonumber(count)
  if count == nil or count < 0 then return true, u32(VRFW.crc32(OLD_BOOK_KEY)), ITEM_RAISE end   -- the graft asks with -1
  retail_stock_logged[slot] = true
  if count > 0 then
    info(string.format("slot %d: %d x old upgrade book %s converted into %s", slot, math.floor(count), OLD_BOOK_KEY, hex(ITEM_RAISE)))
  end
  return false
end

function HissatsuReforged.Cmd.CanPlace(hdl, slot, item)
  local ok, other = TH.CanPlace(hdl, slot, item)
  return ok, other
end

function HissatsuReforged.StoreBlob(slot)
  slot = math.floor(tonumber(slot) or 1)
  local text = VRFW.save.doc.read_text(BLOB, slot)
  if type(text) == "string" then return text end
  return nil
end

function HissatsuReforged.StoreBlobWrite(slot, text)
  slot = math.floor(tonumber(slot) or 0)
  if slot < 1 or type(text) ~= "string" then return false, "bad arguments" end
  local j = VRFW.json.decode(text)
  if type(j) ~= "table" or j.version ~= FILE_VERSION then return false, "not a skill_uses.json version " .. FILE_VERSION end
  local ok, where = VRFW.save.doc.write_text(BLOB, text, slot)
  if not ok then return false, tostring(where) end
  if store.slot == slot then store = load_store(slot) end
  if parked and parked.slot == slot then parked = load_store(slot) end
  info(string.format("slot %d: store replaced by another mod's repair", slot))
  return true, nil
end

local function start()
  A.load()
  BLOCK_DUP = cfg("duplicates.block", true) ~= false
  info("one copy of a move per player set: " .. (BLOCK_DUP and "on" or "off ([duplicates] block = false)"))
  local k = cfg("ranks.recast_per_grade", 0.025)
  if type(k) ~= "number" or k ~= k or k < 0 or k > 1 then
    warn("recast_per_grade " .. tostring(k) .. " out of range 0..1, using 0.025")
    k = 0.025
  end
  K = f32(k)
  info(string.format("recast per grade +%.1f %% (grade 1 x%.3f, grade 5 x%.3f)", K * 100, f32(1 + f32(K)), f32(1 + f32(K * 5))))
  local th = cfg("ranks.thresholds", DEFAULT_TH)
  local ok, why = thresholds_ok(th)
  if not ok then
    err("[ranks] thresholds invalid (" .. why .. "): levels by use off")
    return
  end
  THR = {}
  for i, v in ipairs(th) do THR[i] = math.floor(v) end
  local mode = string.lower(VRFW.strings.trim(cfg("ranks.mode", "uses")))
  if mode == "uses" or mode == "uses_only" then
    MODE = "uses"
  elseif mode == "max" then
    MODE = "max"
  else
    warn("mode " .. mode .. " unknown (uses | max), using \"uses\"")
    MODE = "uses"
  end
  LOG_USES = cfg("ranks.log_uses", true)
  POPUP = cfg("ranks.popup", true)
  USE_CAP = cfg("ranks.last_grade_item_only", true) == false and MAX_GRADE or MAX_GRADE - 1
  local function item_id(key)
    return Id.parse(cfg(key), { hash_names = true }) or 0
  end
  ITEM_RAISE, ITEM_LAST = item_id("ranks.raise_item"), item_id("ranks.last_grade_item")
  ON = true
  local r = rules()
  info(string.format("thresholds [%s] (max grade %d), mode %s, log_uses %s, store blob %s per slot",
    table.concat(THR, ", "), max_grade(), MODE, tostring(LOG_USES), BLOB))
  info(string.format("rules of other mods: no rank-up while [%s]; boosts while [%s]; last grade in a match while [%s]",
    table.concat(type(r.no_rank_up_states) == "table" and r.no_rank_up_states or {}, ", "),
    table.concat(type(r.boost_states) == "table" and r.boost_states or {}, ", "),
    table.concat(type(r.max_grade_states) == "table" and r.max_grade_states or {}, ", ")))
  if POPUP then info("level-up banner on (skill telop + graft sr_popup)") end
  info(string.format("rank-up by use up to grade %d (last grade %d: %s); rank items: raise %s, last grade %s",
    use_cap(), MAX_GRADE, USE_CAP < MAX_GRADE and "rank item only" or "by use too", hex(ITEM_RAISE), hex(ITEM_LAST)))
end

start()
apply_grade_animations()
VRFW.on("hook:HissatsuReforged.SkillUsed:post", on_used)
VRFW.on("hook:HissatsuReforged.BuildSkillList:post", on_build)
VRFW.on("hook:HissatsuReforged.MatchSkillInstall:post", on_install)
VRFW.on("chara:moves:post", on_moves)
VRFW.on("hook:HissatsuReforged.CanEquip:post", on_can_equip)
local function drop_caches()
  build_owners = {}
  return drop_board_caches()
end
VRFW.on("match:start_request", function(ev)
  REQUEST_GRADE = nil
  local request = ev.args and ev.args[2]
  local okF, off = pcall(VRFW.game.field, "Match.StartRequestInfo")
  if not okF or type(off) ~= "number" or type(request) ~= "number" or request < 0x10000 then return end
  local ok, rule = pcall(MatchMoveLevel.for_match_info, request + off, "rival")
  REQUEST_GRADE = ok and grade_of(rule) or nil
  if REQUEST_GRADE then
    info(string.format("match move level: requested match, rival lists show grade %d (rule of %s)", REQUEST_GRADE,
      tostring(rule.source)))
  end
end)
VRFW.on("match_end", function() REQUEST_GRADE = nil end)
VRFW.on("menu:open:post", drop_caches)
-- The store of the loaded slot is read here, so no game hook pays for a load.
VRFW.on("slot_load", function(ev)
  drop_caches()
  local slot = ev and tonumber(ev.slot) or 0
  if slot >= 1 and not (parked and parked.slot == slot) then
    if store.dirty and store.slot ~= 0 then warn(string.format("slot %d -> %d: dropping uses not saved by the game", store.slot, slot)) end
    store = load_store(slot)
  end
  return nil
end)
-- Every change waits in memory and is staged once here, when the game copies its live data into the save it writes.
VRFW.on("save:before", function()
  commit(store, "game save")
  return nil
end)
VRFW.on("game_reset", drop_caches)
