
CharacterReforged = CharacterReforged or {}

local BLOB, TABLE, DEFAULTS = "hiper_slots.json", "MixSlot", "MovesetDefault"
local REC_PLACED, REC_NATIVE, REC_ROUTE, REC_LIST, LIST_ENTRY = 0x94, 0xC8, 0x1AC, 0x50, 8
local BOARD_SLOTS, LIST_SLOTS = 9, 6

local Id = VRFW.ids
local u32 = Id.unsigned
local hex = Id.hex_text
local info, warn = VRFW.logger("skill set")

local Memory = VRFW.memory
local read_memory = Memory.read

local RULES = nil
local function build_rules()
  local r = { aura = {}, mix = {}, mix_stats = {}, carriers = {}, create = {}, moveset_export = "" }
  local okd, decl = pcall(VRFW.files.declarations, "content/skill_set")
  local merged = { aura_types = { 0, 3 }, mix_types = { 2, 6 }, mix_stat_types = { 2 } }
  for _, f in ipairs(okd and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local t = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.SkillSet or nil
    if type(t) == "table" then
      for k, v in pairs(t) do merged[k] = v end
    end
  end
  for _, x in ipairs(merged.aura_types or {}) do r.aura[tonumber(x) or -1] = true end
  for _, x in ipairs(merged.mix_types or {}) do r.mix[tonumber(x) or -1] = true end
  for _, x in ipairs(merged.mix_stat_types or {}) do r.mix_stats[tonumber(x) or -1] = true end
  r.moveset_export = tostring(merged.moveset_export or "")
  local oks, slots = pcall(VRFW.files.declarations, "content/extra_slots")
  for _, f in ipairs(oks and type(slots) == "table" and slots or {}) do
    local v = type(f.data) == "table" and type(f.data.VRFW) == "table" and f.data.VRFW or {}
    for _, list in ipairs({ v.ExtraSlot or {}, v.ExtraSlotExtend or {} }) do
      for _, s in ipairs(type(list) == "table" and list or {}) do
        if type(s) == "table" and type(s.fusion) == "table" and type(s.fusion.carrier) == "string" then
          r.carriers[u32(VRFW.crc32(s.fusion.carrier))] = "fusion"
        end
        if type(s) == "table" and type(s.swap) == "table" and type(s.swap.carriers) == "string" then
          for k = 0, (tonumber(s.swap.count) or 0) - 1 do
            r.carriers[u32(VRFW.crc32((s.swap.carriers:gsub("{k}", tostring(k)))))] = "change"
          end
        end
      end
    end
  end
  -- The picker's create entries ([ability_list] create of the transform tables) open a creation flow and are never stored in a slot.
  local okt, transforms = pcall(VRFW.files.declarations, "content/transforms")
  for _, f in ipairs(okt and type(transforms) == "table" and transforms or {}) do
    local list = type(f.data) == "table" and type(f.data.ability_list) == "table" and f.data.ability_list.create or nil
    for _, key in ipairs(type(list) == "table" and list or {}) do
      if type(key) == "string" then r.create[u32(VRFW.crc32(key))] = true end
    end
  end
  return r
end

-- The slot rules are a derived table (kept between starts): the declarations are only read again when the mods' files change.
local function rules()
  if RULES then return RULES end
  RULES = VRFW.derived("skill_set_rules", nil, build_rules)
  return RULES
end
-- The slot rules come from the mods' files only, so they are built at script load (the boot thread), not in the save's load.
do
  local ok, e = pcall(rules)
  if not ok then warn("slot rules not built at script load: " .. tostring(e)) end
end

local AURA_TYPE_OF, SLOT_OF = {}, {}

local function aura_type(id)
  if not id or id == 0 then return nil end
  local known = AURA_TYPE_OF[id]
  if known ~= nil then return known or nil end
  local ok, t = pcall(VRFW.extra_slot.aura_type, id)
  if not ok then return nil end
  if type(t) ~= "number" then t = false end
  AURA_TYPE_OF[id] = t
  return t or nil
end

-- "aura", "mix", "armour" (+ its keshin, 0 = none), "create" (a menu entry, never stored) or nil (a special move / nothing)
local function read_slot_of(id)
  local r = rules()
  if r.create[id] then return "create" end
  if r.carriers[id] then return "mix" end
  local t = aura_type(id)
  if t == nil then return nil end
  if r.mix[t] then return "mix" end
  if r.aura[t] then return "aura" end
  if t == 1 then
    local ok, k = pcall(VRFW.form.spirit_of, id)
    k = ok and u32(k or 0) or 0
    return "armour", k
  end
  return "other"
end

local function slot_of(id)
  id = u32(id or 0)
  if id == 0 then return nil end
  local known = SLOT_OF[id]
  if known == nil then
    local what, k = read_slot_of(id)
    known = { what or false, k }
    SLOT_OF[id] = known
  end
  return known[1] or nil, known[2]
end

local KIND = { aura = 0, mix = 1, armour = 2, create = 3 }
local CARRIER = { fusion = 1, change = 2 }
-- (move) -> kind, keshin of an armour, carrier (1 a fusion carrier, 2 a mode change carrier, 0 a plain move).
function CharacterReforged.SlotOfCmd(id)
  local what, k = slot_of(id)
  return KIND[what] or -1, k or 0, CARRIER[rules().carriers[u32(id or 0)]] or 0
end
function CharacterReforged.SlotOf(id)
  local a, b, c = CharacterReforged.SlotOfCmd(id)
  return { a, b, c }
end

local function record(hdl)
  local ok, r = pcall(VRFW.character.record, hdl)
  if ok and type(r) == "table" and r.addr and r.addr >= 0x10000 then return r end
  return nil
end

local function item_of(inv, cache)
  if not inv or inv == 0 then return 0 end
  local known = cache and cache[inv]
  if known then return known end
  local ok, item = pcall(VRFW.item.of_inv, inv)
  item = ok and u32(item or 0) or 0
  if cache then cache[inv] = item end
  return item
end

-- the items on the card's board slots 0..8 (placed, else native)
local function board(addr)
  local out = {}
  for s = 0, BOARD_SLOTS - 1 do
    local inv = u32(read_memory("u32", addr + REC_PLACED + s * 4) or 0)
    if inv == 0 then inv = u32(read_memory("u32", addr + REC_NATIVE + s * 4) or 0) end
    out[s] = item_of(inv)
  end
  return out
end

local function list(addr)
  local out = {}
  for k = 0, LIST_SLOTS - 1 do
    out[k] = u32(read_memory("u32", addr + REC_LIST + k * LIST_ENTRY) or 0)
  end
  return out
end

local RECORD_WORDS = math.floor((REC_NATIVE + BOARD_SLOTS * 4 - REC_LIST) / 4)
local PLACED_WORD, NATIVE_WORD = math.floor((REC_PLACED - REC_LIST) / 4), math.floor((REC_NATIVE - REC_LIST) / 4)
local LIST_ENTRY_WORDS = math.floor(LIST_ENTRY / 4)
local function list_and_board(addr, inv_items)
  local w = VRFW.memory.read_array("u32", addr + REC_LIST, RECORD_WORDS, 4)
  local ok = w ~= nil
  if not ok or type(w) ~= "table" or #w ~= RECORD_WORDS then return list(addr), board(addr) end
  local l, b = {}, {}
  for k = 0, LIST_SLOTS - 1 do
    l[k] = u32(w[k * LIST_ENTRY_WORDS + 1] or 0)
  end
  for s = 0, BOARD_SLOTS - 1 do
    local inv = u32(w[PLACED_WORD + s + 1] or 0)
    if inv == 0 then inv = u32(w[NATIVE_WORD + s + 1] or 0) end
    b[s] = item_of(inv, inv_items)
  end
  return l, b
end

local OWNED_MAX_AGE_MS = 6000
local OWNED = { at = nil, list = nil }

local function read_owned()
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param", "addr" })
  if ok and type(columns) == "table" then return columns end
  return { handle = {}, param = {}, addr = {} }
end

-- owned cards as { handle = {...}, param = {...}, addr = {...} }, re-read at most every OWNED_MAX_AGE_MS (save load, slot switch and game_reset re-read them)
local function owned()
  local now = VRFW.now_ms()
  if not OWNED.list or now - OWNED.at >= OWNED_MAX_AGE_MS then
    OWNED.list, OWNED.at = read_owned(), now
  end
  return OWNED.list
end

local AURA_FROM_BOARD_SLOT, MIX_FROM_STORE, MIX_FROM_BOARD = 8, 100, 200
local function project_with_board(hdl, addr, stored, inv_items)
  local l, b = list_and_board(addr, inv_items)
  local out = { techniques = {}, rows = {}, aura_positions = {}, aura = 0, mix = 0, aura_from = -1, mix_from = -1, hidden = {} }
  for k = 0, LIST_SLOTS - 1 do
    local x = l[k]
    local is_aura = x ~= 0 and aura_type(x) ~= nil
    out.rows[k + 1] = k
    out.techniques[k + 1] = is_aura and 0 or x
    if is_aura then out.aura_positions[k] = true end
  end
  local own = slot_of(b[8])
  if b[8] ~= 0 and (own == "aura" or own == "armour") then
    out.aura, out.aura_from = b[8], AURA_FROM_BOARD_SLOT
  end
  local m = stored or (CharacterReforged.MixStored and CharacterReforged.MixStored(hdl)) or 0   -- the stored mix (the mix store below)
  if m ~= 0 and slot_of(m) == "mix" then out.mix, out.mix_from = m, MIX_FROM_STORE end
  for k = 0, LIST_SLOTS - 1 do
    local x = l[k]
    if x ~= 0 and aura_type(x) ~= nil then
      local w = slot_of(x)
      if (w == "aura" or w == "armour") and out.aura == 0 then
        out.aura, out.aura_from = x, k
      elseif w == "mix" and out.mix == 0 then
        out.mix, out.mix_from = x, k
      elseif x ~= out.aura and x ~= out.mix then
        out.hidden[#out.hidden + 1] = { pos = k, id = x, kind = w or "other" }
      end
    end
  end
  if out.mix == 0 then
    for s = 0, BOARD_SLOTS - 1 do
      if b[s] ~= 0 and slot_of(b[s]) == "mix" then
        out.mix, out.mix_from = b[s], MIX_FROM_BOARD
        break
      end
    end
  end
  return out, b
end

local function project(hdl, addr)
  local out = project_with_board(hdl, addr)
  return out
end

function CharacterReforged.ProjectSkillSet(card)
  local r = record(u32(card or 0))
  if not r then return nil end
  return project(u32(card), r.addr)
end

function CharacterReforged.ProjectSkillSetCmd(card)
  card = u32(card or 0)
  -- the menu-time step of the tables and the shown card's rows at once, whatever the sweep's progress (both below)
  if CharacterReforged.CommandStep then pcall(CharacterReforged.CommandStep) end
  local p = CharacterReforged.ProjectSkillSet(card)
  if not p then
    local owner = VRFW.character.copy_owner(card)
    p = owner and CharacterReforged.ProjectSkillSet(owner) or nil
  end
  if p and CharacterReforged.PublishCardRows then pcall(CharacterReforged.PublishCardRows, card, p) end
  if not p then return 0, 0, -1, -1, -1, -1, -1, -1, -1, -1 end
  local r = p.rows
  return p.aura, p.mix, p.aura_from, p.mix_from, r[1], r[2], r[3], r[4], r[5], r[6]
end

local ST = { slot = -1, st = nil }

local function save_slot()
  if VRFW.slots.ready() then return VRFW.slots.active() end
  return 1
end

local function key(card) return string.format("%08X", u32(card)) end

local CARDS_PER_TICK = 150
local BUDGET_CHECK_EVERY = 10  -- cards between two clock reads of a time-budgeted slice
local SWEEP = { running = false, dirty = true }
local CONTEXT = "FormContext"
local CONTEXT_LOG = { logged = false }

local MIX_DOC = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "mix slots",
  default = function() return { version = 1, migrated = false, mix = {} } end,
  decode = function(v)
    local st = { version = 1, migrated = v.migrated == true, mix = {} }
    for k, x in pairs(type(v.mix) == "table" and v.mix or {}) do
      local id = u32(tonumber(tostring(x), 16) or 0)
      if id ~= 0 and tonumber(k, 16) then st.mix[string.upper(k)] = id end
    end
    return st
  end,
  encode = function(st)
    local mix = {}
    for k, id in pairs(st.mix) do mix[k] = string.format("%08X", id) end
    return { version = 1, migrated = st.migrated, mix = mix }
  end,
})

local function load()
  local s = save_slot()
  if ST.slot == s and ST.st then return ST.st end
  if ST.slot ~= -1 and ST.slot ~= s then ST.changed = true end
  ST.slot, ST.st = s, (MIX_DOC:load(s))
  SWEEP.dirty = true                                -- the tables follow on the next ticks (never inside a command)
  return ST.st
end

local function save()
  local st = load()
  local ok, why = MIX_DOC:write(st, ST.slot, true)
  if not ok then return false, tostring(why) end
  return true
end

-- A stored move the mix slot no longer takes (e.g. a kind the slot declarations dropped) shows as empty; the save keeps it.
local function shown_mix(id)
  id = u32(id or 0)
  if id == 0 or slot_of(id) ~= "mix" then return 0 end
  return id
end

function CharacterReforged.MixGet(card)
  local mix = load().mix
  local own = mix[key(card)]
  if own then return shown_mix(own) end
  local owner = VRFW.character.copy_owner(card)
  return owner and shown_mix(mix[key(owner)]) or 0
end
function CharacterReforged.MixStored(card)
  local st = load()
  return st.mix[key(card)] or 0
end

function CharacterReforged.MixAddsStats(card)
  local p = CharacterReforged.ProjectSkillSet(u32(card or 0))
  local m = p and u32(p.mix or 0) or 0
  if m == 0 then return true end
  local t = aura_type(m)
  if t == nil then return true end
  return rules().mix_stats[t] == true
end

-- the command a retail mix item becomes for this card (per-card changes), else the item itself
local function own_row(card, id)
  local ok, row = pcall(VRFW.miximax.call, { op = "item_row", aura = id, hdl = card })
  row = ok and u32(row or 0) or 0
  if row == 0 or row == id or slot_of(row) ~= "mix" then return id end
  info(string.format("mix slot of %s: item %s is %s for this card", hex(card), hex(id), hex(row)))
  return row
end

function CharacterReforged.MixSetCmd(card, id)
  card, id = u32(card or 0), u32(id or 0)
  if card == 0 then return false, 1 end
  if id ~= 0 and slot_of(id) ~= "mix" then
    info(string.format("mix slot of %s: %s refused: not a Mix-Max / «Modo cambio» move", hex(card), hex(id)))
    return false, 1
  end
  -- A fusion carrier is the slot's move only while the card has a stored fusion: without one it is no miximax.
  if id ~= 0 and rules().carriers[id] == "fusion" then
    local function partner_of(h)
      local okf, l = pcall(VRFW.miximax.call, { op = "fusion_of", hdl = h })
      local f = okf and type(l) == "table" and (l.f or l) or nil
      return type(f) == "table" and u32(f.partner_hdl or 0) or 0
    end
    local owner = VRFW.character.copy_owner(card)
    if partner_of(card) == 0 and (not owner or partner_of(u32(owner)) == 0) then
      info(string.format("mix slot of %s: carrier %s refused: no stored fusion", hex(card), hex(id)))
      return false, 1
    end
  end
  if id ~= 0 then id = own_row(card, id) end
  local st = load()
  local old = st.mix[key(card)] or 0
  st.mix[key(card)] = id ~= 0 and id or nil
  local ok, why = save()
  if not ok then
    st.mix[key(card)] = old ~= 0 and old or nil
    warn(string.format("mix slot of %s not saved (%s)", hex(card), tostring(why)))
    return false, 2
  end
  if id ~= 0 then pcall(VRFW.native.table_set, TABLE, card, id) end
  SWEEP.dirty = true
  info(string.format("mix slot of %s: %s -> %s", hex(card), hex(old), hex(id)))
  return true, 0
end

function CharacterReforged.MixSet(card, id)
  local ok, code = CharacterReforged.MixSetCmd(card, id)
  return { ok, code }
end

local DEF = { done = false, map = {} }

-- Returns `id` once the saved card `hdl` has reached its learn level (the learn-level service's move_locked), else 0.
local function learned(hdl, id)
  id = u32(id or 0)
  if id == 0 then return 0 end
  local ok, need = pcall(VRFW.learn.move_locked, hdl, id)
  if ok and type(need) == "number" and need > 0 then return 0 end
  return id
end

-- Fills an empty aura / mix slot of saved card `hdl` (chara_param `param`) with his moveset's own move once he has learned it (from = 200).
local function default_fill(hdl, param, aura, aura_from, mix, mix_from)
  local d = DEF.map[param]
  if d then
    local da, dm = learned(hdl, d.aura), learned(hdl, d.mix)
    if aura == 0 and da ~= 0 then aura, aura_from = da, 200 end
    if mix == 0 and dm ~= 0 then mix, mix_from = dm, 200 end
  end
  return aura, aura_from, mix, mix_from
end
local function moveset_fn()
  local name = rules().moveset_export
  if name == "" then return nil, "" end
  local prefix, fn = name:match("^([%w_]+)%.([%w_]+)$")
  local t = prefix and rawget(_G, prefix) or nil
  local f = type(t) == "table" and t[fn] or nil
  return type(f) == "function" and f or nil, name
end

-- The defaults are a derived table (kept between starts): the chara_param walk and the moveset export only run when the mods' files change.
-- The export is called once for every card's mix (one call into another script per card cost about 30 microseconds each).
local function build_defaults(f)
  local rows = VRFW.table.raw(VRFW.table_files.file_name(VRFW.table_files.CHARA_PARAM), "CHARA_PARAM_INFO", { 1, 27 })
  if type(rows) ~= "table" then error("no CHARA_PARAM_INFO rows") end
  local mixes = {}
  if f then
    local okm, m = pcall(f)
    if okm and type(m) == "table" then
      for card, id in pairs(m) do mixes[u32(card)] = u32(id) end
    end
  end
  local out = { rows = #rows, nx = 0, list = {} }
  for _, r in ipairs(rows) do
    local param, nine = u32(r[1]), u32(r[27])
    if param ~= 0 then
      local aura, mix = 0, 0
      local w = slot_of(nine)
      if w == "aura" then aura = nine elseif w == "mix" then mix = nine end
      local own = mixes[param]
      if mix == 0 and own and slot_of(own) == "mix" then mix = own; out.nx = out.nx + 1 end
      if aura ~= 0 or mix ~= 0 then out.list[#out.list + 1] = { param, aura, mix } end
    end
  end
  return out
end

local function publish_defaults()
  if DEF.done then return DEF.n end
  DEF.done = true
  local f, name = moveset_fn()
  local ok, built = pcall(VRFW.derived, "moveset_defaults", { name, f ~= nil }, function() return build_defaults(f) end)
  if not ok or type(built) ~= "table" then
    warn("moveset defaults: chara_param not readable (" .. tostring(built) .. "): no defaults")
    DEF.n = 0
    return 0
  end
  pcall(VRFW.native.table_clear, DEFAULTS)
  DEF.map = {}
  local n, na, nm = 0, 0, 0
  for _, e in ipairs(built.list) do
    local param, aura, mix = e[1], e[2], e[3]
    DEF.map[param] = { aura = aura, mix = mix }
    pcall(VRFW.native.table_set, DEFAULTS, param, { aura = aura, mix = mix })
    n = n + 1
    if aura ~= 0 then na = na + 1 end
    if mix ~= 0 then nm = nm + 1 end
  end
  info(string.format("moveset defaults: %d of %d characters with an own aura (%d) / mix (%d) for the empty slots; moveset export %s%s",
    n, built.rows, na, nm, name ~= "" and name or "none", f and string.format(" (gave %d mix)", built.nx) or (name ~= "" and " not visible here: learn list slot 9 only" or "")))
  DEF.n = n
  return n
end

function CharacterReforged.DefaultSetCmd(card)
  card = u32(card or 0)
  if card == 0 then return 0, 0 end
  local ok, r = pcall(VRFW.character.record, card)
  local param = (ok and type(r) == "table") and u32(r.param or 0) or 0
  if param == 0 then return 0, 0 end
  pcall(publish_defaults)
  local d = DEF.map[param]
  if not d then return 0, 0 end
  return learned(card, d.aura), learned(card, d.mix)
end

local function spirit(id)
  local w, k = slot_of(id)
  if w == "aura" then return u32(id) end
  if w == "armour" and k and k ~= 0 then return u32(k) end
  return 0
end

local function sweep_start(report_why)
  local st = load()
  local cards = owned()
  if #cards.handle == 0 then
    OWNED.list = nil
    SWEEP.running, SWEEP.dirty = false, true
    SWEEP.report_next = SWEEP.report_next or report_why
    return
  end
  SWEEP.running, SWEEP.dirty = true, false
  SWEEP.report_why = report_why
  SWEEP.cards, SWEEP.next_card = cards, 1
  SWEEP.mix_rows, SWEEP.context_rows, SWEEP.inv_items, SWEEP.touched = {}, {}, {}, {}
  SWEEP.stored, SWEEP.projected = 0, 0
  SWEEP.with_aura, SWEEP.with_mix = 0, 0
  SWEEP.report_players, SWEEP.report_examples, SWEEP.report_hidden = 0, {}, 0
  for k, id in pairs(st.mix) do
    local card = tonumber(k, 16)
    if card then
      SWEEP.mix_rows[#SWEEP.mix_rows + 1] = { card, id }
      SWEEP.stored = SWEEP.stored + 1
    end
  end
end

local function context_row(hdl, param, p, b)
  local aura, aura_from, mix, mix_from = spirit(p.aura), -1, 0, -1
  if aura ~= 0 then aura_from = p.aura_from end
  if p.mix ~= 0 then mix, mix_from = p.mix, p.mix_from end
  if mix == 0 then
    for s = 0, BOARD_SLOTS - 1 do
      if b[s] ~= 0 and slot_of(b[s]) == "mix" then mix, mix_from = b[s], s break end
    end
  end
  aura, aura_from, mix, mix_from = default_fill(hdl, param, aura, aura_from, mix, mix_from)
  return { aura = aura, mix = mix, aura_from = aura_from, mix_from = mix_from }
end

-- the hidden entries shown in a projection's summary line
local REPORT_EXAMPLES = 3

local function sweep_card(st, hdl, param, addr)
  local stored = st.mix[key(hdl)]
  local p, b = project_with_board(hdl, addr, stored or 0, SWEEP.inv_items)
  if not stored and p.mix ~= 0 then
    SWEEP.mix_rows[#SWEEP.mix_rows + 1] = { hdl, p.mix }
    SWEEP.projected = SWEEP.projected + 1
  end
  local row = context_row(hdl, param, p, b)
  local aura, mix = row.aura, row.mix
  SWEEP.context_rows[#SWEEP.context_rows + 1] = { hdl, row }
  if aura ~= 0 then SWEEP.with_aura = SWEEP.with_aura + 1 end
  if mix ~= 0 then SWEEP.with_mix = SWEEP.with_mix + 1 end
  if SWEEP.report_why and #p.hidden > 0 then
    SWEEP.report_players = SWEEP.report_players + 1
    SWEEP.report_hidden = SWEEP.report_hidden + #p.hidden
    if #SWEEP.report_examples < REPORT_EXAMPLES then
      local hidden = {}
      for _, h in ipairs(p.hidden) do
        hidden[#hidden + 1] = string.format("%s %s (list position %d)", h.kind, hex(h.id), h.pos + 1)
      end
      SWEEP.report_examples[#SWEEP.report_examples + 1] = string.format("card %s: %s", hex(hdl), table.concat(hidden, ", "))
    end
  end
end

local function sweep_finish()
  SWEEP.running = false
  local okm, em = pcall(VRFW.native.table_replace, TABLE, nil, SWEEP.mix_rows)
  if not okm then warn("MixSlot not written: " .. tostring(em)) end
  local okc, ec = pcall(VRFW.native.table_replace, CONTEXT, nil, SWEEP.context_rows)
  if not okc then warn("form context not written: " .. tostring(ec)) end
  -- the cards published while the sweep ran keep their newer rows
  for card, t in pairs(SWEEP.touched or {}) do
    pcall(VRFW.native.table_set, CONTEXT, card, t.row)
    if t.mix ~= 0 then pcall(VRFW.native.table_set, TABLE, card, t.mix) end
  end
  if not CONTEXT_LOG.logged then
    CONTEXT_LOG.logged = true
    info(string.format("form context: %d owned card(s), %d with an aura, %d with a mix (table %s, read by the form viewer); MixSlot: %d stored, %d projected",
      #SWEEP.context_rows, SWEEP.with_aura, SWEEP.with_mix, CONTEXT,
      SWEEP.stored, SWEEP.projected))
  end
  if SWEEP.report_why and SWEEP.report_players > 0 then
    info(string.format("projection (%s): %d player(s) with entries hidden in the new set (%d in all, kept in their lists); first: %s",
      SWEEP.report_why, SWEEP.report_players, SWEEP.report_hidden, table.concat(SWEEP.report_examples, "; ")))
  end
  SWEEP.cards, SWEEP.mix_rows, SWEEP.context_rows, SWEEP.inv_items, SWEEP.touched = nil, nil, nil, nil, nil
end

-- one card's rows at once (the card a menu shows)
local CARD_ROWS_EVERY_MS = 500
local CARD_ROWS_AT = {}
function CharacterReforged.PublishCardRows(card, p)
  local now = VRFW.now_ms()
  if (CARD_ROWS_AT[card] or -CARD_ROWS_EVERY_MS) + CARD_ROWS_EVERY_MS > now then return end
  CARD_ROWS_AT[card] = now
  local r = record(card)
  if not r then return end
  -- the branch rule for the shown card (a new recruit), without a whole-roster scan
  local route = read_memory("u32", r.addr + REC_ROUTE)
  if route ~= nil and route ~= 0 then VRFW.memory.write("u32", r.addr + REC_ROUTE, 0) end
  local row = context_row(card, u32(r.param or 0), p, board(r.addr))
  pcall(VRFW.native.table_set, CONTEXT, card, row)
  local st = load()
  local stored = st.mix[key(card)] or 0
  local mix = stored ~= 0 and stored or (p.mix or 0)
  if mix ~= 0 then pcall(VRFW.native.table_set, TABLE, card, mix) end
  if SWEEP.running and SWEEP.touched then SWEEP.touched[card] = { row = row, mix = mix } end
end

local function learned_moves(hdl, param)
  local out = {}
  local okl, set = pcall(VRFW.learn.learnset, param)
  if not okl or type(set) ~= "table" then return out end
  local oko, _, level = pcall(VRFW.learn.of, hdl)
  level = oko and tonumber(level) or 0
  for k, e in ipairs(set) do
    local m, need = u32(e.move or 0), tonumber(e.level) or 0
    if m ~= 0 and (need <= 1 or level >= need) then out[k] = m end
  end
  return out
end

function CharacterReforged.EffectiveSkillSet(card)
  card = u32(card or 0)
  local r = record(card)
  -- a team copy without a record of its own answers with its owner's set (as ProjectSkillSetCmd and MixGet do)
  if not r then
    local owner = card ~= 0 and VRFW.character.copy_owner(card) or nil
    r = owner and record(owner) or nil
    if not r then return nil end
    card = u32(owner)
  end
  local p, b = project_with_board(card, r.addr)
  local aura, aura_from, mix, mix_from = default_fill(card, u32(r.param or 0), p.aura, p.aura_from, p.mix, p.mix_from)
  local listed, techniques, rows = {}, {}, {}
  for _, x in ipairs(p.techniques) do
    if x ~= 0 then listed[x] = true end
  end
  local learn = nil
  for i, x in ipairs(p.techniques) do
    local pos = p.rows[i]
    if x == 0 and not p.aura_positions[pos] then
      local m = b[pos] or 0
      if m == 0 then
        learn = learn or learned_moves(card, u32(r.param or 0))
        m = learn[pos + 1] or 0
      end
      if m ~= 0 and aura_type(m) == nil and not listed[m] then
        x = m
        listed[m] = true
      end
    end
    techniques[i], rows[i] = x, pos
  end
  return { aura = aura, mix = mix, aura_from = aura_from, mix_from = mix_from, techniques = techniques, rows = rows }
end
if type(VRFW.skill_set) == "table" and type(VRFW.skill_set.provide) == "function" then
  VRFW.skill_set.provide("CharacterReforged.EffectiveSkillSet")
end

-- one slice of the running sweep -> true when it has finished
local function sweep_step(deadline)
  local st = load()
  local cards = SWEEP.cards
  local handles, params, addrs = cards.handle, cards.param, cards.addr
  local last = math.min(#handles, SWEEP.next_card + CARDS_PER_TICK - 1)
  for i = SWEEP.next_card, last do
    local ok, e = pcall(sweep_card, st, handles[i], params[i], addrs[i])
    if not ok then
      warn("sweep: card " .. hex(handles[i]) .. ": " .. tostring(e))
    end
    -- the slice ends at the caller's time budget (the rest on the next step)
    if deadline and i < last and (i - SWEEP.next_card) % BUDGET_CHECK_EVERY == BUDGET_CHECK_EVERY - 1 and VRFW.now_ms() >= deadline then
      last = i
      break
    end
  end
  SWEEP.next_card = last + 1
  if SWEEP.next_card > #handles then
    sweep_finish()
    return true
  end
  return false
end

local BRANCH_CARDS_PER_STEP = 500
local BRANCH = { cards = nil, next_card = 1, switched = 0, total = 0 }
local function branch_start()
  BRANCH.cards, BRANCH.next_card, BRANCH.switched = owned(), 1, 0
  BRANCH.total = #BRANCH.cards.addr
end
local function branch_step(deadline)
  local addrs = BRANCH.cards.addr
  local last = math.min(#addrs, BRANCH.next_card + BRANCH_CARDS_PER_STEP - 1)
  for i = BRANCH.next_card, last do
    local r = read_memory("u32", addrs[i] + REC_ROUTE)
    if r ~= nil and r ~= 0 then
      if VRFW.memory.write("u32", addrs[i] + REC_ROUTE, 0) then BRANCH.switched = BRANCH.switched + 1 end
    end
    if deadline and i < last and (i - BRANCH.next_card) % BUDGET_CHECK_EVERY == BUDGET_CHECK_EVERY - 1 and VRFW.now_ms() >= deadline then
      last = i
      break
    end
  end
  BRANCH.next_card = last + 1
  if BRANCH.next_card > #addrs then
    BRANCH.cards = nil
    return true
  end
  return false
end

local RT = { branch_due = true, edge = true, why = "first load" }

-- one step of the due work (branch rule pass, then the sweep) -> true when more work is left for the next step
local function tick(deadline)
  if ST.changed then
    ST.changed = false
    OWNED.list = nil
    SWEEP.running, SWEEP.dirty = false, true
    RT.branch_due = true
  end
  local idle = VRFW.slots.ready() and not (VRFW.in_match and VRFW.in_match())
  if not idle then return false end
  if RT.branch_due then
    RT.branch_due = false
    local ok, e = pcall(branch_start)
    VRFW.time.mark_step("owned cards")
    if not ok then
      BRANCH.cards = nil
      warn("branch rule: " .. tostring(e))
    end
    return BRANCH.cards ~= nil
  end
  if BRANCH.cards then
    local ok, finished = pcall(branch_step, deadline)
    VRFW.time.mark_step("branch rule")
    if not ok then
      BRANCH.cards = nil
      warn("branch rule: " .. tostring(finished))
      return false
    end
    if not finished then return true end
    local n, total = BRANCH.switched, BRANCH.total
    if RT.edge then
      if total > 0 then
        RT.edge = false
        info(string.format("branch rule (%s): %d of %d owned player(s) switched to branch 1", RT.why or "first load", n, total))
        SWEEP.report_next = RT.why or "first load"
        SWEEP.dirty, SWEEP.running = true, false
      end
    elseif n > 0 then
      info(string.format("branch rule: %d player(s) back on branch 1 (a recruit or a match)", n))
    end
    return true
  end
  if SWEEP.running then
    local ok, finished = pcall(sweep_step, deadline)
    VRFW.time.mark_step(ok and finished and "sweep slice and tables" or "sweep slice")
    return ok and not finished
  elseif SWEEP.dirty then
    local why = SWEEP.report_next
    SWEEP.report_next = nil
    local ok, e = pcall(sweep_start, why)
    VRFW.time.mark_step("sweep start")
    if not ok then
      SWEEP.running = false
      warn("sweep: " .. tostring(e))
    end
    return SWEEP.running
  end
  return false
end

-- Steps are driven by menu opens (menu:open, MENU_SLICES slices within MENU_STEP_BUDGET_MS) and by this mod's commands.
local MENU_SLICES, MENU_STEP_BUDGET_MS, COMMAND_STEP_EVERY_MS = 8, 16, 250
local LAST_COMMAND_STEP = { at = -COMMAND_STEP_EVERY_MS }
local function menu_step()
  local started = VRFW.now_ms()
  local deadline = started + MENU_STEP_BUDGET_MS
  local more = tick(deadline)
  for _ = 2, MENU_SLICES do
    if not more or VRFW.now_ms() >= deadline then break end
    more = tick(deadline)
  end
end
function CharacterReforged.CommandStep()
  local now = VRFW.now_ms()
  if LAST_COMMAND_STEP.at + COMMAND_STEP_EVERY_MS > now then return end
  LAST_COMMAND_STEP.at = now
  tick(now + MENU_STEP_BUDGET_MS)
end

VRFW.on("match:end", function()
  OWNED.list = nil
  SWEEP.dirty = true
  RT.branch_due = true
end)
VRFW.on("menu:open:post", function() pcall(menu_step) end)
VRFW.on("save:slot_load", function()
  ST.slot, ST.st = -1, nil
  OWNED.list = nil
  RT.branch_due = true
  RT.edge, RT.why = true, "save loaded"
  pcall(publish_defaults)
  SWEEP.dirty, SWEEP.running = true, false
end)
-- The rules, the slot kinds and the moveset defaults come from the game tables and the mods' files, which stay the same for the session, so a title return keeps them.
VRFW.on("game:reset", function()
  ST.slot, ST.st = -1, nil
  OWNED.list = nil
  SWEEP.dirty, SWEEP.running = true, false
  RT.branch_due = true
end)
