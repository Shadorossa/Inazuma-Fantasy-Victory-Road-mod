--- Advanced: Library: passive declarations, pools, events and card passives.

local M = {}

local BLOCK_KIND = "VRFW.passive_block/1"
local PASSIVE_KIND = "VRFW.passive/1"
-- [older kind] = kind: the type files' `former_kinds` (files still read under them), filled by read_schema
local FORMER_KIND = {}

local Id = VRFW.ids
local Decl = VRFW.declarations
local u32 = Id.unsigned
--- Advanced: Normalises an id to an unsigned 32-bit number.
M.u32 = u32

--- Advanced: a number, "0x…", decimal text, or a key (its crc32) -> id; nil for nothing usable
function M.id_of(v)
  return Id.parse(v, { hash_names = true })
end

--- Advanced: Formats an id as hex text.
M.hex = Id.hex_text

-- the key specs of an entry type (its table keys) and its plain keys (role, text, apply…)
local function split_entry(e)
  local keys, meta = {}, {}
  for k, x in pairs(e) do
    if type(x) == "table" then
      -- an empty text is a valid value of a text key with `values`
      x.allow_empty = x.type == "string" and x.values ~= nil or nil
      keys[k] = x
    else
      meta[k] = x
    end
  end
  return keys, meta
end

local function read_schema(kind)
  local ok, files = pcall(VRFW.files.declarations, "content/types")
  local t = nil
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local d = f.data
    if type(d) == "table" and d.schema == "VRFW.decl_schema/1" and d.kind == kind and type(d.entry) == "table" then t = d end
  end
  if not t then return nil, "no content\\types\\ schema of kind " .. kind end
  for _, old in ipairs(type(t.former_kinds) == "table" and t.former_kinds or {}) do FORMER_KIND[old] = kind end
  local types = {}
  for name, e in pairs(t.entry) do
    if type(e) == "table" then
      local keys, meta = split_entry(e)
      types[name] = { name = name, keys = keys, meta = meta }
    end
  end
  return types, t
end

-- every entry of `kind` in the active mods' `folder`, checked: { mod, file, type, index, where, v }
local function load_entries(folder, kind, types, warn)
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, folder)
  if not ok or type(files) ~= "table" then return out end
  for _, f in ipairs(files) do
    local data = f.data or {}
    local where = string.format("mods/%s/%s", tostring(f.mod), tostring(f.file))
    if data.schema ~= kind and FORMER_KIND[data.schema] ~= kind then
      warn(string.format("%s: schema is not %q (file left out)", where, kind))
    else
      local PREFIX = tostring(data.schema):match("^([^.]+)")
      local own = type(data[PREFIX]) == "table" and data[PREFIX] or {}
      local names = {}
      for name in pairs(own) do names[#names + 1] = name end
      table.sort(names)
      for _, name in ipairs(names) do
        local ty, arr = types[name], own[name]
        if not ty then
          warn(string.format("%s: [[%s.%s]] is not a type of %s (left out)", where, PREFIX, tostring(name), kind))
        elseif type(arr) == "table" then
          for i, raw in ipairs(arr) do
            local w = string.format("%s: [[%s.%s]] #%d", where, PREFIX, name, i)
            local v, bad = {}, nil
            for k, x in pairs(raw) do
              local spec = ty.keys[k]
              if not spec then
                bad = "unknown key `" .. tostring(k) .. "`"
                break
              end
              local val, why = Decl.check_value(spec, x)
              if val == nil then
                bad = string.format("%s: %s", tostring(k), why)
                break
              end
              v[k] = val
            end
            if not bad then
              for k, spec in pairs(ty.keys) do
                if v[k] == nil then
                  if spec.required then
                    bad = tostring(k) .. " is required"
                    break
                  end
                  v[k] = spec.default
                end
              end
            end
            if bad then
              warn(w .. ": " .. bad .. " (left out)")
            else
              out[#out + 1] = { mod = tostring(f.mod), file = tostring(f.file), type = ty, index = i, where = w, v = v }
            end
          end
        end
      end
    end
  end
  return out
end

local function lookup(map, mod, name)
  if type(name) ~= "string" then return nil end
  return map[mod .. "." .. name] or map[name]
end

local function add_to(map, key, p)
  map[key] = map[key] or {}
  for _, x in ipairs(map[key]) do
    if x == p then return end
  end
  table.insert(map[key], p)
end

--- Internal: a passive's condition blocks with the parts of its AnyOf / NoneOf blocks (one level: a bounded walk)
function M.conditions_of(p)
  local out = {}
  for _, b in ipairs(p.conditions) do
    out[#out + 1] = b
    for _, c in ipairs(b.parts or {}) do out[#out + 1] = c end
  end
  return out
end

local function event_key(b)
  return b.v.arg ~= "" and (b.v.on .. ":" .. b.v.arg) or b.v.on
end

local DATA = nil
-- the events the interpreter makes itself (no behaviour-rule trigger): `carried`, `half_start`, `interval:<seconds>`
local ENGINE_EVENTS = { carried = true, half_start = true, interval = true }
--- Internal: Set of the events the passive interpreter raises itself (carried, half_start, interval).
M.ENGINE_EVENTS = ENGINE_EVENTS

--- Internal: The passive pools from `points`.
function M.pools(points, warn)
  local out, seen = {}, {}
  local function add(resource, cost_flag)
    if type(resource) ~= "string" or resource == "" or seen[resource] then return end
    seen[resource] = true
    out[#out + 1] = { resource = resource, cost_flag = (type(cost_flag) == "string" and cost_flag ~= "") and cost_flag or nil }
  end
  local schema, why = Decl.schema("passive_pool")
  if schema then
    for _, d in ipairs(Decl.load(schema, warn)) do add(d.v.resource, d.v.cost_flag) end
  else
    warn(tostring(why) .. ": no [[VRFW.PassivePool]] is read")
  end
  if type(points) == "table" and type(points.pool_resources) == "table" then
    for _, r in ipairs(points.pool_resources) do add(r, points.cost_flag) end
  end
  return out
end

-- blocks, passives and character entries of every active mod (built from the files)
local function build_data(warn)
  local d = { blocks = {}, passives = {}, characters = {}, listen = {}, hooks = {}, has_stat = false, move_kinds = {}, positions = {},
    outcomes = {}, tension_plays = {}, levels = {}, spirits = {}, families = {}, grantable = {}, spirit = {}, grant = {}, points = {}, pools = {}, keeper_duel = {},
    has_keeper_shooter = false, has_pool_cost = false, tags = {}, character_tags = {}, caps = {}, listen_set = {}, hooks_set = {},
    unit_moves = {}, genders = {}, has_trait = false, engine_events = {}, has_stamina = false, has_ball_walls = false, refresh = {},
    counted = {}, counted_set = {}, aura_bits = {}, matchup = {} }
  local block_types, schema_or_err = read_schema(BLOCK_KIND)
  local passive_types, e2 = read_schema(PASSIVE_KIND)
  if not block_types or not passive_types then
    warn(tostring(block_types and e2 or schema_or_err) .. ": no special passive is read")
    return d
  end
  d.move_kinds = type(schema_or_err.move_kinds) == "table" and schema_or_err.move_kinds or {}
  d.positions = type(schema_or_err.positions) == "table" and schema_or_err.positions or {}
  d.outcomes = type(schema_or_err.outcomes) == "table" and schema_or_err.outcomes or {}
  d.tension_plays = type(schema_or_err.tension_plays) == "table" and schema_or_err.tension_plays or {}
  d.levels = type(schema_or_err.levels) == "table" and type(schema_or_err.levels.from_player_level) == "table" and schema_or_err.levels.from_player_level or {}
  d.points = type(schema_or_err.points) == "table" and schema_or_err.points or {}
  d.pools = M.pools(d.points, warn)
  d.keeper_duel = type(schema_or_err.keeper_duel) == "table" and schema_or_err.keeper_duel or {}
  d.unit_moves = type(schema_or_err.unit_moves) == "table" and schema_or_err.unit_moves or {}
  d.genders = type(schema_or_err.genders) == "table" and schema_or_err.genders or {}
  d.refresh = type(schema_or_err.refresh) == "table" and schema_or_err.refresh or {}
  d.aura_bits = type(schema_or_err.aura_bits) == "table" and schema_or_err.aura_bits or {}
  d.matchup = type(schema_or_err.matchup) == "table" and schema_or_err.matchup or {}
  d.spirit = type(e2.spirit) == "table" and e2.spirit or {}
  d.grant = type(e2.grant) == "table" and e2.grant or {}
  for _, e in ipairs(load_entries("content/passive_blocks", BLOCK_KIND, block_types, warn)) do
    local key = e.mod .. "." .. e.v.name
    if d.blocks[key] then warn(e.where .. ": block " .. key .. " declared again (the later one is used)") end
    d.blocks[key] = { key = key, mod = e.mod, type = e.type.name, role = e.type.meta.role, meta = e.type.meta, v = e.v, where = e.where }
  end
  -- the Trait blocks other blocks name (`trait`, `shooter_trait`)
  for _, b in pairs(d.blocks) do
    for _, k in ipairs({ "trait", "shooter_trait" }) do
      local tn = b.v[k]
      if type(tn) == "string" and tn ~= "" then
        local t = lookup(d.blocks, b.mod, tn)
        if t and t.role == "trait" then
          b[k] = t
          d.has_trait = true
        else
          warn(b.where .. ": " .. k .. " `" .. tn .. "` is not a Trait block (the block never holds)")
          b[k] = false
        end
      end
    end
  end
  -- the condition blocks AnyOf / NoneOf name (`conditions`): plain conditions only, resolved as b.parts (one level)
  for _, b in pairs(d.blocks) do
    if b.role == "condition" and type(b.v.conditions) == "table" then
      b.parts = {}
      for _, cn in ipairs(b.v.conditions) do
        local c = lookup(d.blocks, b.mod, cn)
        if not c or c.role ~= "condition" or c.meta.scale or c.meta.filter or type(c.v.conditions) == "table" then
          warn(b.where .. ": `" .. tostring(cn) .. "` is not a plain condition block (left out of " .. b.key .. ")")
        else
          b.parts[#b.parts + 1] = c
        end
      end
    end
  end
  local chars, spirits, cap_names = {}, {}, {}
  for _, e in ipairs(load_entries("content/special_passives", PASSIVE_KIND, passive_types, warn)) do
    if e.type.name == "Passive" then
      local key = e.mod .. "." .. e.v.name
      local p = { key = key, mod = e.mod, triggers = {}, stack = nil, resets = {}, conditions = {}, counts = {}, filters = {}, effects = {},
        slot = nil, carried_by = {}, grant = e.v.grant == true, where = e.where, caps = {},
        icon = (type(e.v.icon) == "string" and e.v.icon ~= "") and e.v.icon or nil }
      cap_names[p] = e.v.caps or {}
      for _, bn in ipairs(e.v.blocks) do
        local b = lookup(d.blocks, e.mod, bn)
        local role = b and b.role
        if not b then
          warn(e.where .. ": no block `" .. bn .. "` (left out of the passive)")
        elseif role == "trigger" then
          p.triggers[#p.triggers + 1] = b
        elseif role == "reset" then
          p.resets[#p.resets + 1] = b
        elseif role == "stack" then
          if p.stack then warn(e.where .. ": more than one Stack block (" .. b.key .. " left out)") else p.stack = b end
        elseif role == "condition" and b.meta.scale == "count" then
          p.counts[#p.counts + 1] = b
        elseif role == "condition" and b.meta.filter == "target" then
          p.filters[#p.filters + 1] = b
        elseif role == "trait" then
          warn(e.where .. ": `" .. bn .. "` is a Trait block: name it from a Present / Count / By / Holder block or an effect's `trait` (left out of the passive)")
        elseif role == "condition" then
          p.conditions[#p.conditions + 1] = b
          if b.meta.carrier == "equipment" then p.worn = true end
        elseif b.meta.apply == "own_slot" then
          if p.slot then warn(e.where .. ": more than one GamePassive block (" .. b.key .. " left out)") else p.slot = b end
        else
          p.effects[#p.effects + 1] = b
        end
      end
      for _, k in ipairs(e.v.carried_by or {}) do
        local id = Id.parse(k, { hash_names = true })
        if id and id ~= 0 then p.carried_by[#p.carried_by + 1] = id end
      end
      if d.passives[key] then warn(e.where .. ": passive " .. key .. " declared again (the later one is used)") end
      d.passives[key] = p
    elseif e.type.name == "Spirit" then
      spirits[#spirits + 1] = e
    elseif e.type.name == "PassiveCap" then
      local key = e.mod .. "." .. e.v.name
      d.caps[key] = { key = key, max = e.v.max_percent }
    elseif e.type.name == "Tag" then
      local before = d.tags[e.v.name]
      d.tags[e.v.name] = { name = e.v.name, text = (e.v.text ~= "" or not before) and e.v.text or before.text, mod = e.mod,
                           icon = ((e.v.icon or "") ~= "" or not before) and (e.v.icon or "") or before.icon }
    elseif e.type.name == "CharacterTags" then
      d.character_tags[#d.character_tags + 1] = { character = e.v.character, tags = e.v.tags, where = e.where }
    elseif e.type.name == "SpiritFamily" then
      local key = e.mod .. "." .. e.v.name
      if d.families[key] then warn(e.where .. ": family " .. key .. " declared again (the later one is used)") end
      d.families[key] = { key = key, auras = e.v.auras, where = e.where }
    else
      chars[#chars + 1] = e
    end
  end
  local by_aura = {}
  for _, e in ipairs(spirits) do
    local list = {}
    for _, pn in ipairs({ e.v.passive, e.v.synergy }) do
      if pn ~= nil and pn ~= "" then
        local p = lookup(d.passives, e.mod, pn)
        if p then list[#list + 1] = p else warn(e.where .. ": no passive `" .. pn .. "` (left out)") end
      end
    end
    local s = { mod = e.mod, where = e.where, aura = e.v.aura, aliases = e.v.aliases or {}, passives = list }
    if by_aura[e.v.aura] then
      d.spirits[by_aura[e.v.aura]] = s
    else
      d.spirits[#d.spirits + 1] = s
      by_aura[e.v.aura] = #d.spirits
    end
  end
  -- the caps each passive names
  for p, names in pairs(cap_names) do
    for _, cn in ipairs(names) do
      local c = lookup(d.caps, p.mod, cn)
      if c then p.caps[#p.caps + 1] = c else warn(p.where .. ": no passive cap `" .. cn .. "` (not capped by it)") end
    end
  end
  -- the tags the characters name must be declared
  for _, e in ipairs(d.character_tags) do
    for _, t in ipairs(e.tags) do
      if not d.tags[t] then warn(e.where .. ": tag `" .. t .. "` is not a [[Tag]] (it still counts for the Trait blocks naming it)") end
    end
  end
  -- one own passive per player: `passive`, or the first of an older `passives` list
  for _, e in ipairs(chars) do
    local list = {}
    local names = e.v.passives or {}
    local pn = (e.v.passive ~= nil and e.v.passive ~= "") and e.v.passive or names[1]
    if (e.v.passive ~= nil and e.v.passive ~= "" and #names > 0) or #names > 1 then
      warn(e.where .. ": a player has one own passive: " .. tostring(pn) .. " is used, the others are left out")
    end
    if pn then
      local p = lookup(d.passives, e.mod, pn)
      if p then list[1] = p else warn(e.where .. ": no passive `" .. pn .. "` (left out)") end
    else
      warn(e.where .. ": no `passive` (left out)")
    end
    if e.v.character == "" and e.v.card == "" then
      warn(e.where .. ": needs `character` or `card` (left out)")
    else
      d.characters[#d.characters + 1] = { mod = e.mod, where = e.where, character = e.v.character, card = e.v.card, passives = list }
    end
  end
  local live = {}
  for _, e in ipairs(d.characters) do
    for _, p in ipairs(e.passives) do live[p] = true end
  end
  for _, s in ipairs(d.spirits) do
    for _, p in ipairs(s.passives) do live[p] = true end
  end
  d.worn = {}
  for _, p in pairs(d.passives) do
    if #p.carried_by > 0 or p.worn or p.grant then live[p] = true end
    if p.worn then d.worn[#d.worn + 1] = p end
    if p.grant then d.grantable[#d.grantable + 1] = p end
  end
  table.sort(d.worn, function(a, b) return a.key < b.key end)
  table.sort(d.grantable, function(a, b) return a.key < b.key end)
  for p in pairs(live) do
    for _, b in ipairs(p.triggers) do
      add_to(d.listen, event_key(b), p)
      if ENGINE_EVENTS[b.v.on] then d.engine_events[b.v.on] = true end
    end
    for _, b in ipairs(p.resets) do add_to(d.listen, event_key(b), p) end
    for _, b in ipairs(M.conditions_of(p)) do
      if b.type == "EventCount" then
        add_to(d.counted, event_key(b), p)
        if b.v.breaks_on ~= "" then
          add_to(d.counted, b.v.breaks_arg ~= "" and (b.v.breaks_on .. ":" .. b.v.breaks_arg) or b.v.breaks_on, p)
        end
      end
    end
    for _, b in ipairs(p.effects) do
      if b.meta.apply == "stat" then d.has_stat = true end
      if b.meta.apply == "keeper" and b.v.side ~= "keeper" then d.has_keeper_shooter = true end
      if b.meta.apply == "pool_cost" then d.has_pool_cost = true end
      if b.meta.apply == "stamina_recovery" then d.has_stamina = true end
      if b.meta.apply == "ball_walls" then d.has_ball_walls = true end
      for h in tostring(b.meta.hooks or ""):gmatch("[%w_:]+") do add_to(d.hooks, h, p) end
    end
  end
  for _, map in ipairs({ d.listen, d.hooks }) do
    for _, list in pairs(map) do
      table.sort(list, function(a, b) return a.key < b.key end)
    end
  end
  for _, pair in ipairs({ { d.listen, d.listen_set }, { d.hooks, d.hooks_set }, { d.counted, d.counted_set } }) do
    for k, list in pairs(pair[1]) do
      local set = {}
      for _, p in ipairs(list) do set[p] = true end
      pair[2][k] = set
    end
  end
  return d
end

--- Advanced: the data above, built once per VM and kept between starts while the mods' files and the game's data are the same
function M.data(warn)
  if DATA then return DATA end
  if type(VRFW.derived) == "function" then
    DATA = VRFW.derived("passive_data." .. tostring(VRFW.script), nil, function() return build_data(warn) end)
  else
    DATA = build_data(warn)
  end
  return DATA
end

--- Advanced: drops this VM's copy of the data; a script that only reads it at load calls this at the end of its top-level run, so the collector frees it before the first command and every later collection cycle stays small.
function M.release_data()
  DATA = nil
end

--- Internal: Event key of a behaviour: its trigger, plus ":arg" when it has an argument.
M.event_key = event_key
--- Advanced: Reads map[mod.name], else map[name]; answers the value, or nil when name is not text.
M.lookup = lookup

--- Internal: a character entry's chara_base id (a key / id resolved by the framework)
function M.character_id(value)
  if type(value) ~= "number" and (type(value) ~= "string" or value == "") then return nil end
  return Id.character(value, { hash_names = true })
end

-- [chara_base id] = { card ids }: built once per VM from the character index
local CARDS_BY_BASE = nil

local function cards_of_character(value)
  local base = M.character_id(value)
  if base == nil or base == 0 then return {} end
  if CARDS_BY_BASE == nil then
    local index = {}
    for _, card in ipairs(VRFW.character.cards()) do
      local b = u32(card.base)
      local list = index[b]
      if list == nil then
        list = {}
        index[b] = list
      end
      list[#list + 1] = u32(card.id)
    end
    CARDS_BY_BASE = index
  end
  local out = {}
  for i, c in ipairs(CARDS_BY_BASE[base] or {}) do out[i] = c end
  return out
end

--- Advanced: the cards of a character entry ({ character } or { card })
function M.cards_of(e)
  if e.card ~= nil and e.card ~= "" then
    local c = Id.parse(e.card, { hash_names = true })
    return (c and c ~= 0) and { c } or {}
  end
  return cards_of_character(e.character)
end

local TEAM_PASSIVE_UNLOCKED = "Passive.TeamPassiveUnlocked"
local TEAM_PASSIVE_ID = "Passive.TeamPassiveId"
local SIGNATURE_ID = "Passive.SignatureSlotId"
local SIGNATURE_OPEN = "Passive.SignaturePieceOpen"

local BUF_ID, BUF_HDL = nil, nil

local function buffers()
  if BUF_ID == nil then
    BUF_ID = VRFW.memory.buffer("passive_reader_id", 8)
    BUF_HDL = VRFW.memory.buffer("passive_reader_hdl", 4)
  end
  return BUF_ID, BUF_HDL
end

local function truthy(v)
  return v == true or (type(v) == "number" and v ~= 0)
end

--- Advanced: The passive of character `hdl` in slot `k`; nil when none.
function M.slot_passive(hdl, k, copy)
  local id_buf = buffers()
  local oku, unlocked = pcall(VRFW.call, TEAM_PASSIVE_UNLOCKED, hdl, k, copy)
  VRFW.memory.write("u32", id_buf, 0)
  local oki = pcall(VRFW.call, TEAM_PASSIVE_ID, id_buf, hdl, k, copy)
  if not (oku and oki) then
    return nil
  end
  return VRFW.memory.read("u32", id_buf) or 0, truthy(unlocked)
end

--- Advanced: The own passive of character `hdl`; nil when none.
function M.own_passive(hdl, opts)
  opts = opts or {}
  local id_buf, hdl_buf = buffers()
  VRFW.memory.write("u32", id_buf, 0)
  if not pcall(VRFW.call, opts.id or SIGNATURE_ID, id_buf, hdl) then
    return 0, false
  end
  local id = VRFW.memory.read("u32", id_buf) or 0
  if opts.open == false then
    return id, nil
  end
  VRFW.memory.write("u32", hdl_buf, hdl)
  local ok, open = pcall(VRFW.call, opts.open or SIGNATURE_OPEN, hdl_buf)
  return id, ok and tonumber(open) ~= nil and tonumber(open) % 256 ~= 0
end

return M
