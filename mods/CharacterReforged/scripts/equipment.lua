
CharacterReforged = CharacterReforged or {}

local info, warn = VRFW.logger("equipment")

local T_ADD = "CharacterReforged.StatAdd"
local T_RIVAL = "CharacterReforged.RivalAdd"
local ME = VRFW.match.equipment
-- the match equipment rules are built (or read from the start cache) at load, so the match request stays short
ME.prepare()
local STAT_INDEX = VRFW.rivals.STAT   -- the engine's stat order
local POSITION = { GK = 1, FW = 2, MF = 3, DF = 4 }
local ELEMENT = { wind = 1, forest = 2, fire = 3, mountain = 4 }
local Id = VRFW.ids
local u32 = Id.unsigned

local DATA = nil

local function id_of(key) return Id.parse(key, { hash_names = true }) end

local function resolve(worn)
  local ok, counts, slots = pcall(VRFW.item.resolve_sets, worn[1], worn[2], worn[3], worn[4])
  if ok and type(counts) == "table" then return counts, (type(slots) == "table" and slots or {}) end
  return nil, nil
end

local round = VRFW.value.round

local function build_data()
  local d = { rules = {}, affinity = {}, sets = {} }
  local ok, rules = pcall(VRFW.files.toml, "content/equipment/rules.toml")
  d.rules = (ok and type(rules) == "table") and rules or {}
  local okA, files = pcall(VRFW.files.declarations, "content/equipment/affinity.toml")
  for _, f in ipairs((okA and files) or {}) do
    for _, e in ipairs((f.data or {}).item or {}) do
      if type(e.item) == "string" then d.affinity[id_of(e.item)] = e end
    end
  end
  local okS, sfiles = pcall(VRFW.files.declarations, { "content/equipment/sets.toml", "content/equipment/classic_sets.toml" })
  local by_key = {}
  for _, f in ipairs((okS and sfiles) or {}) do
    for _, s in ipairs((f.data or {}).set or {}) do
      if type(s.name) == "string" then
        local key = tostring(f.mod) .. "." .. s.name
        local members, ordered = {}, {}
        local okM, list = pcall(VRFW.item.set_members, key)
        if okM and type(list) == "table" then
          for _, id in ipairs(list) do members[u32(id)] = true; ordered[#ordered + 1] = u32(id) end
        else
          for _, m in ipairs(s.members or {}) do members[id_of(m)] = true; ordered[#ordered + 1] = id_of(m) end
        end
        local entry = { key = key, name = s.name, mod = f.mod, members = members, list = ordered, bonus = s.bonus or {} }
        if by_key[key] then d.sets[by_key[key]] = entry else d.sets[#d.sets + 1] = entry; by_key[key] = #d.sets end
      end
    end
  end
  d.set_index, d.sets_of_item = by_key, {}
  for i, set in ipairs(d.sets) do
    for id in pairs(set.members) do
      local l = d.sets_of_item[id]
      if not l then l = {}; d.sets_of_item[id] = l end
      l[#l + 1] = i
    end
  end
  for _, l in pairs(d.sets_of_item) do table.sort(l) end
  local okI, ifiles = pcall(VRFW.files.declarations, "content/equipment/items.toml")
  d.items = {}
  for _, f in ipairs((okI and ifiles) or {}) do
    for _, e in ipairs((f.data or {}).item or {}) do
      if type(e.item) == "string" then d.items[id_of(e.item)] = { passive = e.passive, mod = f.mod } end
    end
  end
  d.profiles, d.item_key = {}, {}
  local okP, pfiles = pcall(VRFW.files.declarations, "content/items/profiles.toml")
  for _, f in ipairs((okP and pfiles) or {}) do
    for _, e in ipairs((f.data or {}).edit or {}) do
      if type(e.target) == "string" and type(e.scale_stats) == "table" then
        d.profiles[id_of(e.target)] = e.scale_stats
        d.item_key[id_of(e.target)] = e.target
      end
    end
  end
  return d
end

-- The equipment tables are a derived table (kept between starts): the declarations are only read again when the mods' files change.
local function load()
  if DATA then return DATA end
  DATA = VRFW.derived("equipment_data", nil, build_data)
  return DATA
end

-- Whether an item's affinity fits a card: its position, its element.
local function affinity_match(a, card)
  local pos = a.position and POSITION[a.position] == card.position
  local el = a.element and (ELEMENT[a.element] == card.element or a.element == card.element)
  return pos, el
end

local function affinity_rate(a, card, rules)
  local r = rules.affinity or {}
  local pos, el = affinity_match(a, card)
  if pos and el then return r.both or 0 end
  if pos then return r.one or 0 end
  return 0                          -- the element alone gives nothing (rules.toml [affinity])
end

local function scaled(d, s)
  local c = d.scaled
  if c and c.s == s then return c end
  c = { s = s, raises = {}, tiers = {}, own = {}, cap = ((d.rules.scale or {}).cap or 1) * s }
  for id, prof in pairs(d.profiles or {}) do
    local l = {}
    for stat, frac in pairs(prof) do
      local k = STAT_INDEX[stat]
      if k and type(frac) == "number" then l[#l + 1] = { k + 1, round(frac * s) } end
    end
    c.own[id] = l
  end
  for id, aff in pairs(d.affinity) do
    local l = {}
    for stat, frac in pairs(aff.raises or {}) do
      local k = STAT_INDEX[stat]
      if k then l[#l + 1] = { k + 1, round(frac * s) } end
    end
    c.raises[id] = l
  end
  for i, set in ipairs(d.sets) do
    local t = {}
    for _, tier in ipairs(set.bonus) do
      local adds = {}
      for stat, frac in pairs(tier.stats or {}) do
        local k = STAT_INDEX[stat]
        local v = k and round(frac * s) or 0
        if v ~= 0 then adds[#adds + 1] = { k + 1, v } end
      end
      t[#t + 1] = { tier.pieces or 2, adds, type(tier.effects) == "table" and #tier.effects > 0 }
    end
    c.tiers[i] = t
  end
  d.scaled = c
  return c
end

local function additions_worn(worn, card_of, d, c, own)
  local add = { 0, 0, 0, 0, 0, 0, 0, 0 }
  local any = false
  local card, card_read = nil, false
  for i = 1, 4 do
    local item = worn[i]
    local stats = own and item ~= 0 and c.own[item] or nil
    if stats then
      for _, r in ipairs(stats) do
        if r[2] ~= 0 then add[r[1]], any = add[r[1]] + r[2], true end
      end
    end
    local aff = item ~= 0 and d.affinity[item] or nil
    if aff then
      if not card_read then
        card_read = true
        card = card_of()
      end
      local rate = card and affinity_rate(aff, card, d.rules) or 0
      if rate > 0 then
        for _, r in ipairs(c.raises[item]) do
          local base = r[2]
          local bonus = math.min(round(base * rate), math.max(0, c.cap - base))
          if bonus ~= 0 then add[r[1]], any = add[r[1]] + bonus, true end
        end
      end
    end
  end
  local pieces, in_sets, effects = {}, 0, 0
  for i = 1, 4 do
    local l = worn[i] ~= 0 and d.sets_of_item[worn[i]] or nil
    if l then
      in_sets = in_sets + 1
      for _, si in ipairs(l) do pieces[si] = (pieces[si] or 0) + 1 end
    end
  end
  if in_sets >= 2 then
    local counts = resolve(worn)
    if counts then
      pieces = {}
      for key, n in pairs(counts) do
        local si = d.set_index[key]
        if si then pieces[si] = n end
      end
    end
    for si, n in pairs(pieces) do
      if n >= 2 then
        for _, tier in ipairs(c.tiers[si]) do
          if n >= tier[1] then
            for _, av in ipairs(tier[2]) do add[av[1]], any = add[av[1]] + av[2], true end
            if tier[3] then effects = effects + 1 end
          end
        end
      end
    end
  end
  return any and add or nil, effects
end

local function wearer(hdl)
  if type(hdl) ~= "number" or hdl == 0 then return nil end
  local okR, rec = pcall(VRFW.character.record, hdl)
  if not okR or not rec or not rec.param then return nil end
  local okC, card = pcall(VRFW.character.card, rec.param)
  return okC and card or nil
end

-- The 4 items a saved character wears (nil = not one of the user's players).
local function worn_of(hdl)
  local ok, a, b, cc, e = pcall(VRFW.item.equipped, hdl)
  if not ok or a == nil then return nil end
  return { u32(a), u32(b), u32(cc), u32(e) }
end

-- the 8 stat additions of a saved character (nil = nothing worn / not one of the user's players)
local function additions(hdl, d, c)
  local worn = worn_of(hdl)
  if not worn then return nil end
  if worn[1] == 0 and worn[2] == 0 and worn[3] == 0 and worn[4] == 0 then return nil end
  return additions_worn(worn, function() return wearer(hdl) end, d, c, false)
end

local function scale()
  local okS, s = pcall(VRFW.item.equipment_scale)
  s = (okS and tonumber(s)) or 0
  if s <= 0 then return nil end
  local d = load()
  return d, scaled(d, s), s
end

-- the table for every saved character (a save load)
local function refresh(why)
  local d, c, s = scale()
  if not d then
    pcall(VRFW.native.table_clear, T_ADD)
    return
  end
  local okC, columns = pcall(VRFW.character.saved_columns, { "handle" })
  local handles = (okC and columns and columns.handle) or {}
  local entries, players = {}, 0
  for _, handle in ipairs(handles) do
    local add = additions(handle, d, c)
    if add then
      players = players + 1
      for k = 1, 8 do
        if add[k] ~= 0 then entries[#entries + 1] = { { handle, k - 1 }, add[k] } end
      end
    end
  end
  local ok, e = pcall(VRFW.native.table_replace, T_ADD, nil, entries)
  if not ok then warn(T_ADD .. ": " .. tostring(e)) end
  info(string.format("%s: %d player(s) with affinity / set stats of %d saved character(s) read (S = %d)", why, players,
    #handles, s))
end

local function refresh_one(hdl)
  local d, c = scale()
  if not d then return end
  local add = additions(hdl, d, c)
  local entries = {}
  for k = 1, 8 do
    if add and add[k] ~= 0 then entries[#entries + 1] = { { hdl, k - 1 }, add[k] } end
  end
  local ok, e = pcall(VRFW.native.table_replace, T_ADD, hdl, entries)
  if not ok then warn(T_ADD .. ": " .. tostring(e)) end
end

local MOD = "CharacterReforged"

local function T(key, mod)
  local ok, s = pcall(VRFW.text, (mod or MOD) .. "." .. key)
  return (ok and type(s) == "string" and s ~= "") and s or nil
end

local function fill(template, args)
  return (string.gsub(template, "{(%w+)}", function(k)
    local v = args[k]
    return v ~= nil and tostring(v) or ""
  end))
end

local function signed(v)
  v = tonumber(v) or 0
  return (v > 0 and "+" or "") .. tostring(v)
end

local FAMILY_TEXT = nil
local function family_name(family)
  if FAMILY_TEXT == nil then
    FAMILY_TEXT = {}
    local ok, files = pcall(VRFW.files.declarations, "content/techniques/families.toml", "VRFW.TechniqueFamily")
    for _, f in ipairs((ok and files) or {}) do
      local v = type(f.data) == "table" and f.data.VRFW or nil
      for _, decl in ipairs((type(v) == "table" and type(v.TechniqueFamily) == "table") and v.TechniqueFamily or {}) do
        if type(decl.name) == "string" and type(decl.text) == "string" then
          local short = string.match(decl.name, "([^%.]+)$") or decl.name
          local s = nil
          local okT, t = pcall(VRFW.text, decl.text)
          if okT and type(t) == "string" and t ~= "" then s = t end
          local rest = string.match(decl.text, "^[^%.]+%.(.+)$")
          if s == nil and rest ~= nil then
            local okA, a = pcall(VRFW.text, tostring(f.mod) .. "." .. rest)
            if okA and type(a) == "string" and a ~= "" then s = a end
          end
          if s ~= nil then
            FAMILY_TEXT[decl.name] = s
            FAMILY_TEXT[short] = FAMILY_TEXT[short] or s
          end
        end
      end
    end
  end
  return FAMILY_TEXT[family] or FAMILY_TEXT[string.match(family, "([^%.]+)$") or family] or family
end

local function element_icon(element)
  local c = load().rules.card or {}
  local icons = type(c.element_icon) == "table" and c.element_icon or {}
  local tag = icons[element]
  return type(tag) == "string" and tag ~= "" and tag or nil
end

local function effect_text(e, short)
  local tpl = (short and T("short_" .. tostring(e.kind))) or T("eff_" .. tostring(e.kind))
  if not tpl then return nil end
  local stats = {}
  for _, st in ipairs(type(e.stats) == "table" and e.stats or {}) do stats[#stats + 1] = T("stat_" .. st) or st end
  return fill(tpl, {
    v = signed(e.value),
    family = e.family and family_name(e.family) or "",
    move = e.move_kind and (T("move_" .. e.move_kind) or e.move_kind) or T("move_any") or "",
    element = e.element and ((short and element_icon(e.element)) or T("element_" .. e.element) or e.element) or "",
    when = e.when and (T("when_" .. e.when) or "") or "",
    event = e.event and (T("event_" .. e.event) or e.event) or "",
    score = e.score and (T("score_" .. e.score) or e.score) or "",
    effect = e.effect and (T("effect_" .. e.effect) or e.effect) or "",
    stats = table.concat(stats, " / "),
  })
end

local function set_of(d, id)
  for _, set in ipairs(d.sets) do
    if set.members[id] then return set end
  end
  return nil
end

local SLOT_OF_TYPE = { sh = 1, mi = 2, ac = 3, sp = 4 }
local function slot_of(d, id)
  local a = d.affinity[id]
  local kind = a and type(a.item) == "string" and string.match(a.item, "eq_(%a%a)") or nil
  return kind and SLOT_OF_TYPE[kind] or nil
end

local function counted_set(d, id, hdl)
  if type(hdl) ~= "number" or hdl == 0 then return nil end
  local ok, a, b, c, e = pcall(VRFW.item.equipped, hdl)
  if not ok or a == nil then return nil end
  local worn = { a, b, c, e }
  local k = slot_of(d, id)
  if k then worn[k] = id end
  local counts, slots = resolve(worn)
  if not counts then return nil end
  local key = nil
  for i = 1, 4 do
    if worn[i] and u32(worn[i]) == id then key = slots[i] end
  end
  for _, set in ipairs(d.sets) do
    if set.key == key then return set, counts[key] end
  end
  return nil
end

-- a set's bonus tiers as { pieces, text } (stats at the item type's S, then the effects' compact form)
local function tiers_of(set)
  local okS, s = pcall(VRFW.item.equipment_scale)
  s = (okS and tonumber(s)) or 0
  local out = {}
  for _, tier in ipairs(set.bonus) do
    local parts = {}
    for stat, frac in pairs(tier.stats or {}) do
      if s > 0 then parts[#parts + 1] = (T("stat_" .. stat) or stat) .. " " .. signed(round(frac * s)) end
    end
    table.sort(parts)
    for _, e in ipairs(tier.effects or {}) do
      local t = effect_text(e, true)
      if t then parts[#parts + 1] = t end
    end
    if #parts > 0 then out[#out + 1] = { pieces = tier.pieces or 2, text = table.concat(parts, ", ") } end
  end
  return out
end

local function set_name(set)
  return T("set_" .. string.lower(tostring(set.name)), set.mod) or tostring(set.name)
end

local EXT_ICONS = nil
local function ext_element_icon(element)
  if EXT_ICONS == nil then
    EXT_ICONS = {}
    local c = load().rules.card or {}
    for _, path in ipairs(type(c.element_icon_files) == "table" and c.element_icon_files or {}) do
      local ok, files = pcall(VRFW.files.declarations, path)
      for _, f in ipairs((ok and files) or {}) do
        local v = type(f.data) == "table" and f.data.VRFW or nil
        for _, d in ipairs((type(v) == "table" and type(v.ElementIcon) == "table") and v.ElementIcon or {}) do
          if type(d.Element) == "string" and type(d.Atlas) == "string" and type(d.Sprite) == "string"
              and EXT_ICONS[d.Element] == nil then
            EXT_ICONS[d.Element] = { atlas = id_of(d.Atlas), sprite = id_of(d.Sprite) }
          end
        end
      end
    end
  end
  return element and EXT_ICONS[element] or nil
end

local function chip_part(e, s)
  if e.stat ~= nil then
    return { stat = e.stat, stat_index = STAT_INDEX[e.stat], stat_name = T("stat_" .. e.stat) or e.stat,
      value = signed(e.value) }
  end
  local v = signed(e.value) .. " %"
  if e.kind == "element_power" and e.element then
    return { label = T("chip_move") or "", element = e.element, element_name = T("element_" .. e.element) or e.element,
      element_icon = ext_element_icon(e.element), value = v }
  end
  if e.kind == "family_power" and e.family then
    return { label = T("chip_move") or "", family = family_name(e.family), value = v }
  end
  return { text = effect_text(e, true) or effect_text(e) or "" }
end

function CharacterReforged.ItemPage(item, hdl)
  local d = load()
  local id = u32(item)
  local out = { lines = {}, tiers = {},
    -- the card pages' names (the item card's page prompt)
    page_names = { stats = T("page_name_stats"), effect = T("page_name_effect"), set = T("page_name_set") } }
  if id == 0 then return out end
  local lines = out.lines
  local it = d.items[id]
  if it and type(it.passive) == "table" then
    local p = effect_text(it.passive)
    if p then lines[#lines + 1] = p end
    out.passive = chip_part(it.passive)
  end
  local set = counted_set(d, id, hdl) or set_of(d, id)
  if set then
    local okS, s = pcall(VRFW.item.equipment_scale)
    s = (okS and tonumber(s)) or 0
    local tiers = {}
    for i, t in ipairs(tiers_of(set)) do
      tiers[#tiers + 1] = fill(T(i == 1 and "page_tier_first" or "page_tier") or "{n}: {text}", { n = t.pieces, text = t.text })
    end
    if #tiers > 0 then lines[#lines + 1] = table.concat(tiers, " · ") end
    for _, tier in ipairs(set.bonus) do
      local best, bv = nil, 0
      for stat, frac in pairs(tier.stats or {}) do
        local v = s > 0 and round(frac * s) or 0
        if v > bv then best, bv = stat, v end
      end
      local reward = nil
      if best then
        reward = chip_part({ stat = best, value = bv })
      elseif type(tier.effects) == "table" and tier.effects[1] then
        reward = chip_part(tier.effects[1])
      end
      if reward then out.tiers[#out.tiers + 1] = { pieces = tier.pieces or 2, reward = reward } end
    end
  end
  local aff = d.affinity[id]
  if aff and (aff.position or aff.element) then
    local r = d.rules.affinity or {}
    local one, both = round((r.one or 0) * 100), round((r.both or 0) * 100)
    local stats = {}
    for stat, frac in pairs(aff.raises or {}) do stats[#stats + 1] = { stat, frac } end
    table.sort(stats, function(x, y) return x[2] > y[2] end)
    local keys = {}
    for i, st in ipairs(stats) do keys[i] = st[1] end
    local card = wearer(hdl)
    local pos_ok = card ~= nil and aff.position ~= nil and POSITION[aff.position] == card.position
    local el_ok = card ~= nil and aff.element ~= nil and (ELEMENT[aff.element] == card.element or aff.element == card.element)
    out.affinity = {
      position = aff.position, element = aff.element, element_icon = ext_element_icon(aff.element), stats = keys,
      pos_ok = pos_ok, el_ok = el_ok,
      rate = (pos_ok and el_ok) and "both" or (pos_ok and "one" or "none"),
      text = fill(T("chip_affinity") or "x {one} % / {both} %",
        { one = card == nil and one or ((pos_ok and el_ok) and both or (pos_ok and one or 0)), both = both }),
    }
    local both_known = aff.position and aff.element
    lines[#lines + 1] = fill(T(both_known and "page_affinity_value_both" or "page_affinity_value") or "+{one} %",
      { one = one, both = both })
  end
  return out
end

function CharacterReforged.ItemSet(item, hdl)
  local d = load()
  local id = u32(item)
  if id == 0 then return nil end
  local all = {}
  for _, set in ipairs(d.sets) do
    if set.members[id] then all[#all + 1] = set end
  end
  if #all == 0 then return nil end
  local set, worn = counted_set(d, id, tonumber(hdl))
  set = set or all[1]
  local members = {}
  for i, m in ipairs(set.list or {}) do members[i] = m end
  local others = {}
  for _, o in ipairs(all) do
    if o ~= set then others[#others + 1] = set_name(o) end
  end
  local also = #others > 0 and fill(T("page3_also") or "also: {sets}", { sets = table.concat(others, ", ") }) or nil
  return { name = set_name(set), count = #members, members = members, tiers = tiers_of(set), worn = worn, also = also,
    title = T("page3_title") or "{set}: {worn}/{count}", title_any = T("page3_title_any") or "{set} ({count})",
    tiers_label = T("page3_tiers") or "{tiers}" }
end

-- CMND_CHARACTERREFORGED_EQUIPMENT_STAT_BONUS (charaStHdl, item, slot): the 8 stat points the match table adds for the worn items.
-- The item goes into slot 1..4 (0 = its own slot); item 0 with a slot empties that slot; item 0 without one = as worn.
function CharacterReforged.StatBonus(hdl, item, slot)
  local zero = { 0, 0, 0, 0, 0, 0, 0, 0 }
  hdl = tonumber(hdl) or 0
  local d, c = scale()
  local worn = (d and hdl ~= 0) and worn_of(hdl) or nil
  if not worn then return table.unpack(zero) end
  local id, k = u32(tonumber(item) or 0), tonumber(slot) or 0
  if k < 1 or k > 4 then k = id ~= 0 and slot_of(d, id) or nil end
  if k then worn[k] = id end
  return table.unpack(additions_worn(worn, function() return wearer(hdl) end, d, c, false) or zero)
end

-- [[VRFW.CommandFilter]] of the retail CMND_EQUIP_OPTIMAL_ITEM (chara).
local Optimal = { SLOTS = 4, POSITION_NAME = {} }
for name, code in pairs(POSITION) do Optimal.POSITION_NAME[code] = name end

function Optimal.truthy(v)
  return v == true or (type(v) == "number" and v ~= 0)
end

Optimal.read = VRFW.memory.read

function Optimal.call(name, ...)
  local ok, v = pcall(VRFW.call, name, ...)
  if not ok then return nil end
  return v
end

function Optimal.layout()
  if Optimal.L ~= nil then return Optimal.L or nil end
  local names = { containers = "Inventory.Containers", first = "Inventory.FirstEquipType",
    capacity = "Inventory.VtCapacity", count = "Inventory.VtCount", at = "Inventory.VtAt",
    handle = "Inventory.RecordVtHandle", item = "Inventory.RecordVtItem", mode_bits = "Inventory.ItemModeBits",
    all_modes = "Inventory.AllModes", mode_play = "Inventory.ModeItemPlayMode", play_mode = "Game.PlayMode" }
  local l = {}
  for key, name in pairs(names) do
    local ok, v = pcall(VRFW.game.field, name)
    if not ok or type(v) ~= "number" then
      warn("equip optimal: the profile has no " .. name .. ": the game's own pick runs")
      Optimal.L = false
      return nil
    end
    l[key] = v
  end
  Optimal.L = l
  return l
end

function Optimal.global(name)
  local g = VRFW.game and VRFW.game[name]
  if type(g) ~= "function" then return nil end
  local ok, p = pcall(g)
  return (ok and type(p) == "number" and p >= 0x10000) and p or nil
end

function Optimal.vcall(obj, offset, sig, ...)
  local ok, v = pcall(VRFW.call_vslot, obj, math.floor(offset / 8), sig, ...)
  if not ok then return nil end
  return v
end

-- the inventory handle the player wears in slot 0..3 (0 = none)
function Optimal.worn_handle(hdl, slot)
  Optimal.slot_out = Optimal.slot_out or VRFW.memory.buffer("be_optimal_slot", 8)
  VRFW.memory.write("u32", Optimal.slot_out, 0)
  if Optimal.call("CharacterReforged.EquipInvHdl", Optimal.slot_out, hdl, slot) == nil then return 0 end
  return Optimal.read("u32", Optimal.slot_out) or 0
end

-- the 8 stats of an item record (the game's EquipStats)
function Optimal.own_stats(info)
  Optimal.stats_out = Optimal.stats_out or VRFW.memory.buffer("be_optimal_stats", 32)
  local out = Optimal.stats_out
  local done = Optimal.truthy(Optimal.call("CharacterReforged.EquipStats", info, out))
  local stats = {}
  for k = 1, 8 do stats[k] = done and (Optimal.read("i32", out + (k - 1) * 4) or 0) or 0 end
  return stats
end

-- the game filler's checks of one record (the slot's own worn record needs no free copy)
function Optimal.accepts(ctx, h, info, worn_here)
  if not Optimal.truthy(Optimal.call("CharacterReforged.InventoryUsable", info)) then return false end
  if not ctx.all_modes then
    local bits = Optimal.read("u8", info + ctx.l.mode_bits) or 0
    if (bits % 4 == 1) ~= (ctx.play_mode == ctx.l.mode_play) then return false end
  end
  if not worn_here and not Optimal.truthy(Optimal.call("CharacterReforged.HasFreeCopy", ctx.items, h, 1)) then
    return false
  end
  return Optimal.truthy(Optimal.call("CharacterReforged.CharaCanEquip", ctx.hdl, h))
end

function Optimal.single(ctx, slot, cand)
  local own = 0
  for k = 1, 8 do own = own + (ctx.w[k] or 0) * cand.stats[k] end
  cand.own = own + (cand.current and ctx.keep or 0) + ((ctx.d.items[cand.item] or {}).passive and ctx.passive or 0)
  local worn = { 0, 0, 0, 0 }
  worn[slot] = cand.item
  local add = additions_worn(worn, ctx.card_of, ctx.d, ctx.c, false)
  local alone = cand.own
  if add then for k = 1, 8 do alone = alone + (ctx.w[k] or 0) * add[k] end end
  cand.alone = alone
end

function Optimal.candidates(ctx, slot, current)
  local list, l = {}, ctx.l
  local c = Optimal.read("ptr", ctx.items + l.containers + (slot - 1 + l.first) * 8)
  if not c then return list end
  local cap, count = Optimal.vcall(c, l.capacity, "-> u32"), Optimal.vcall(c, l.count, "-> u32")
  if type(cap) ~= "number" or type(count) ~= "number" then return list end
  local used = 0
  for i = 0, cap - 1 do
    if used >= count then break end
    local rec = Optimal.vcall(c, l.at, "u32 -> ptr", i)
    local h = 0
    if type(rec) == "number" and rec >= 0x10000 then
      h = Optimal.read("u32", Optimal.vcall(rec, l.handle, "-> ptr")) or 0
    end
    if h ~= 0 then
      used = used + 1
      local info = Optimal.vcall(rec, l.item, "-> ptr")
      if type(info) == "number" and info >= 0x10000 and Optimal.accepts(ctx, h, info, h == current) then
        local okI, item = pcall(VRFW.item.of_inv, h)
        if okI and type(item) == "number" and item ~= 0 then
          local cand = { handle = h, item = u32(item), stats = Optimal.own_stats(info), current = h == current }
          Optimal.single(ctx, slot, cand)
          list[#list + 1] = cand
        end
      end
    end
  end
  return list
end

-- the score of 4 picks (a pick = a candidate, or false = the slot left as it is when nothing fits)
function Optimal.score(ctx, picks)
  local ids, total = { 0, 0, 0, 0 }, 0
  for k = 1, Optimal.SLOTS do
    if picks[k] then ids[k], total = picks[k].item, total + picks[k].own end
  end
  local add, effects = additions_worn(ids, ctx.card_of, ctx.d, ctx.c, false)
  if add then for k = 1, 8 do total = total + (ctx.w[k] or 0) * add[k] end end
  return total + (effects or 0) * ctx.set_effect
end

-- the sub-masks of a slot mask with 2 slots or more (all = every one, pairs = those of exactly 2)
function Optimal.sub_masks(mask)
  local all, pairs2 = {}, {}
  for sub = 3, 2 ^ Optimal.SLOTS - 1 do
    local inside, bits = true, 0
    for k = 1, Optimal.SLOTS do
      local bit = 2 ^ (k - 1)
      if sub % (2 * bit) >= bit then
        bits = bits + 1
        if mask % (2 * bit) < bit then inside = false end
      end
    end
    if inside and bits >= 2 then
      all[#all + 1] = sub
      if bits == 2 then pairs2[#pairs2 + 1] = sub end
    end
  end
  return all, pairs2
end

function Optimal.has(mask, k)
  local bit = 2 ^ (k - 1)
  return mask % (2 * bit) >= bit
end

function Optimal.search(ctx, cands)
  local base, per_set, sets = {}, {}, {}
  for k = 1, Optimal.SLOTS do
    local best = false
    for _, cand in ipairs(cands[k]) do
      if not best or cand.alone > best.alone then best = cand end
      for _, si in ipairs(ctx.d.sets_of_item[cand.item] or {}) do
        local row = per_set[si]
        if not row then row = {}; per_set[si] = row; sets[#sets + 1] = si end
        if not row[k] or cand.alone > row[k].alone then row[k] = cand end
      end
    end
    base[k] = best
  end
  local promise = {}
  for _, si in ipairs(sets) do
    local sum = 0
    for k = 1, Optimal.SLOTS do sum = sum + (per_set[si][k] and per_set[si][k].alone or 0) end
    promise[si] = sum
  end
  table.sort(sets, function(x, y)
    if promise[x] ~= promise[y] then return promise[x] > promise[y] end
    return x < y
  end)
  local best_picks, best_score, scored, limit = base, Optimal.score(ctx, base), 1, ctx.max_plans
  local function try(si, mask, sj, mask2)
    if scored >= limit then return end
    local picks = {}
    for k = 1, Optimal.SLOTS do
      if Optimal.has(mask, k) then picks[k] = per_set[si][k]
      elseif sj and Optimal.has(mask2, k) then picks[k] = per_set[sj][k]
      else picks[k] = base[k] end
    end
    scored = scored + 1
    local s = Optimal.score(ctx, picks)
    if s > best_score then best_picks, best_score = picks, s end
  end
  local masks = {}
  for _, si in ipairs(sets) do
    local m = 0
    for k = 1, Optimal.SLOTS do if per_set[si][k] then m = m + 2 ^ (k - 1) end end
    local all, pairs2 = Optimal.sub_masks(m)
    masks[si] = { all = all, pairs = pairs2 }
  end
  for _, si in ipairs(sets) do
    for _, sub in ipairs(masks[si].all) do try(si, sub) end
  end
  for a = 1, #sets do
    for b = a + 1, #sets do
      local si, sj = sets[a], sets[b]
      for _, p in ipairs(masks[si].pairs) do
        for _, q in ipairs(masks[sj].pairs) do
          local overlap = false
          for k = 1, Optimal.SLOTS do
            if Optimal.has(p, k) and Optimal.has(q, k) then overlap = true end
          end
          if not overlap then try(si, p, sj, q) end
        end
      end
    end
  end
  if scored >= limit then
    warn(string.format("equip optimal: max_plans = %d reached (rules.toml [optimizer]): the rest not scored", limit))
  end
  return best_picks, scored
end

function Optimal.context(hdl, l, items, pd)
  local d = load()
  local opt = d.rules.optimizer or {}
  local okS, s = pcall(VRFW.item.equipment_scale)
  s = (okS and tonumber(s)) or 0
  local card_read, card = false, nil
  local function card_of()
    if not card_read then
      card_read = true
      local okR, rec = pcall(VRFW.character.record, hdl)
      if okR and rec and rec.param then
        local okC, cd = pcall(VRFW.character.card, rec.param)
        card = okC and cd or nil
      end
    end
    return card
  end
  local weights = (opt.weights or {})[Optimal.POSITION_NAME[(card_of() or {}).position] or ""] or {}
  local w = {}
  for stat, k in pairs(STAT_INDEX) do w[k + 1] = tonumber(weights[stat]) or 0 end
  local c = s > 0 and scaled(d, s) or nil
  if not c then
    c = { s = 0, raises = {}, tiers = {}, own = {}, cap = 0 }
    for id in pairs(d.affinity) do c.raises[id] = {} end
    for i in ipairs(d.sets) do c.tiers[i] = {} end
  end
  return { hdl = hdl, l = l, items = items, d = d, c = c, card_of = card_of, w = w,
    passive = tonumber(opt.passive) or 0, set_effect = tonumber(opt.set_effect) or 0,
    keep = tonumber(opt.keep_current) or 0, max_plans = math.max(1, tonumber(opt.max_plans) or 20000),
    play_mode = Optimal.read("u8", pd + l.play_mode),
    all_modes = (Optimal.read("u8", items + l.all_modes) or 0) ~= 0 }
end

function CharacterReforged.EquipOptimal(chara)
  local hdl = u32(chara)
  if hdl == 0 then return false end
  local l = Optimal.layout()
  local items = Optimal.global("equipment_items")
  local pd = Optimal.global("match_equipment_play_data")
  if not l or not items or not pd then return false end
  -- The game's filler leaves a character without position bits as he is.
  local role = Optimal.call("CharacterReforged.CharaEquipRole", hdl)
  if role == nil then return false end
  if not Optimal.truthy(role) then return true end
  local ctx = Optimal.context(hdl, l, items, pd)
  local current, cands = {}, {}
  for k = 1, Optimal.SLOTS do
    current[k] = Optimal.worn_handle(hdl, k - 1)
    cands[k] = Optimal.candidates(ctx, k, current[k])
  end
  local picks, scored = Optimal.search(ctx, cands)
  local changed = 0
  for k = 1, Optimal.SLOTS do
    local pick = picks[k]
    if pick and pick.handle ~= current[k] then
      if Optimal.truthy(Optimal.call("CharacterReforged.EquipToSlot", hdl, pick.handle, k - 1)) then
        changed = changed + 1
      else
        warn(string.format("equip optimal: slot %d: the game refused item 0x%08X", k - 1, pick.item))
      end
    end
  end
  info(string.format("equip optimal: character 0x%08X, %d slot(s) changed, %d plan(s) scored", hdl, changed, scored))
  return true
end

VRFW.on("chara:equip:post", function(ev)
  local hdl = u32(ev.args and ev.args[1])
  local okK, kind = pcall(VRFW.character.kind, hdl)
  if hdl == 0 or not okK or (kind ~= 0 and kind ~= 7) then return nil end
  local ok, e = pcall(refresh_one, hdl)
  if not ok then warn("equip change: " .. tostring(e)) end
  return nil
end)

VRFW.on("save:slot_load", function()
  local ok, e = pcall(refresh, "save load")
  if not ok then warn("save load: " .. tostring(e)) end
  -- the item card's lookups (family names, element icons) built on the loading screen, not by the first card shown
  local okW, eW = pcall(function()
    family_name("")
    ext_element_icon(nil)
  end)
  if not okW then warn("save load: card lookups: " .. tostring(eW)) end
end)

local RIVAL_FILLED = false
local rival_view_set     -- the team view of the requested match (below)
local RIVAL_SLOT_NAMES = { "boots", "bracelet", "pendant", "special" }

local function counted_of(slots)
  local counts = resolve(slots)
  local best, n = nil, 1
  for key, c in pairs(counts or {}) do
    if c > n or (c == n and best and key < best) then best, n = key, c end
  end
  return best
end

local function rival_refresh(request)
  local off = select(2, pcall(VRFW.game.field, "Match.StartRequestInfo"))
  local worn = (type(off) == "number" and request and request >= 0x10000) and ME.for_match_info(request + off) or nil
  if not worn then
    if RIVAL_FILLED then pcall(VRFW.native.table_clear, T_RIVAL); RIVAL_FILLED = false end
    return
  end
  rival_view_set(worn)
  local d = load()
  local okS, s = pcall(VRFW.item.equipment_scale)
  s = (okS and tonumber(s)) or 0
  if s <= 0 then return end
  local c = scaled(d, s)
  local entries, players = {}, 0
  for card, slots in pairs(worn) do
    local add = additions_worn(slots, function()
      local okC, ci = pcall(VRFW.character.card, card)
      return okC and ci or nil
    end, d, c, true)
    local keys = {}
    for k = 1, 4 do keys[k] = slots[k] ~= 0 and (d.item_key[slots[k]] or Id.hex_text(slots[k])) or "-" end
    VRFW.debug("equipment: " .. string.format("rival equipment: 0x%08X slots boots %s, bracelet %s, pendant %s, special %s (set %s)", card,
      keys[1], keys[2], keys[3], keys[4], tostring(counted_of(slots) or "none")))
    if add then
      players = players + 1
      for k = 1, 8 do
        if add[k] ~= 0 then entries[#entries + 1] = { { card, k - 1 }, add[k] } end
      end
    end
  end
  local ok, e = pcall(VRFW.native.table_replace, T_RIVAL, nil, entries)
  if not ok then warn(T_RIVAL .. ": " .. tostring(e)) end
  RIVAL_FILLED = players > 0
  info(string.format("rival equipment: %d rival player(s) equipped for this match (S = %d)", players, s))
end

local PSEUDO_BASE = 0xFE000000
local RIVAL_VIEW = nil

function rival_view_set(worn)
  RIVAL_VIEW = worn and { worn = worn, chara = {}, handles = {}, by_key = {}, next = 0, shown = false } or nil
end

-- the card of a rival chara wearing match equipment, nil for any other chara (cached per chara for the match)
local function rival_card(v, chara)
  local cached = v.chara[chara]
  if cached ~= nil then return cached or nil end
  local card = false
  local okR, rec = pcall(VRFW.character.record, chara)
  local id = (okR and type(rec) == "table" and type(rec.param) == "number") and u32(rec.param) or nil
  if id and v.worn[id] then
    local okO, owner = pcall(VRFW.character.owner, chara)
    if okO and owner == nil then card = id end
  end
  v.chara[chara] = card
  if card and not v.shown then
    v.shown = true
    info(string.format("rival equipment: team view shows the match equipment (first rival chara 0x%08X, card 0x%08X)", chara, card))
  end
  return card or nil
end

function CharacterReforged.RivalEquipHandle(chara, slot)
  local v = RIVAL_VIEW
  if not v or type(chara) ~= "number" or type(slot) ~= "number" or chara == 0 or slot < 0 or slot > 3 then return false end
  local card = rival_card(v, u32(chara))
  if not card then return false end
  local item = v.worn[card][slot + 1]
  if not item or item == 0 then return true, 0 end
  local key = card * 4 + slot
  local h = v.by_key[key]
  if not h then
    h = PSEUDO_BASE + v.next
    v.next = v.next + 1
    v.by_key[key], v.handles[h] = h, item
  end
  return true, h
end

function CharacterReforged.RivalInventoryField(inv, field)
  if not RIVAL_VIEW or type(inv) ~= "number" then return false end
  local item = RIVAL_VIEW.handles[u32(inv)]
  if not item then return false end
  if field == 0 then return true, item end
  return true, 0
end

VRFW.on("match:end", function() rival_view_set(nil) end)

VRFW.on("match:start_request", function(ev)
  rival_view_set(nil)
  local ok, e = pcall(rival_refresh, ev.args and ev.args[2])
  if not ok then warn("rival equipment: " .. tostring(e)) end
end)

VRFW.on("game:reset", function()
  rival_view_set(nil)
  pcall(VRFW.native.table_clear, T_ADD)
  pcall(VRFW.native.table_clear, T_RIVAL)
  RIVAL_FILLED = false
end)

-- set names sort without their accents
local ACCENT_FOLD = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n", ["Á"] = "a",
  ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n" }

local function sort_key(label)
  local folded = string.gsub(label, "[\195][\128-\191]", ACCENT_FOLD)
  return string.lower(folded)
end

-- The tabs of the equipment picker's and the shop's filter windows (content\item_filter_sections\equipment.toml): the rows'
-- tests, answered from the same data and functions as the item card and the match table.
do
  -- "a,b" -> { a = true, b = true }
  local function word_set(text)
    local words = {}
    for word in string.gmatch(text, "[^,]+") do words[word] = true end
    return words
  end

  -- What a test worked out for a player stays until his worn items or the item scale change.
  local PLAYER_FACTS = { key = nil, facts = {} }
  local function player_facts(name, hdl, worn, s)
    local key = table.concat({ tostring(hdl), tostring(s), worn[1], worn[2], worn[3], worn[4] }, ":")
    if PLAYER_FACTS.key ~= key then PLAYER_FACTS.key, PLAYER_FACTS.facts = key, {} end
    local facts = PLAYER_FACTS.facts[name]
    if not facts then
      facts = {}
      PLAYER_FACTS.facts[name] = facts
    end
    return facts
  end

  local function nothing() return false end

  -- (item) -> true when the item, worn in its slot by `hdl`, counts for a set with a bonus tier reached.
  local function completes_set_test(d, hdl)
    local worn = worn_of(hdl)
    if not worn then return nothing end
    -- Only a piece of a set one of the worn items belongs to can reach a tier.
    local candidates = {}
    for i = 1, 4 do
      for _, si in ipairs(worn[i] ~= 0 and d.sets_of_item[worn[i]] or {}) do
        for id in pairs(d.sets[si].members) do candidates[id] = true end
      end
    end
    local known = player_facts("completes_set", hdl, worn, 0)
    return function(item)
      if not candidates[item] then return false end
      if known[item] == nil then
        local set, count = counted_set(d, item, hdl)
        local reached = false
        for _, tier in ipairs(set and set.bonus or {}) do
          if (count or 0) >= (tier.pieces or 2) then reached = true end
        end
        known[item] = reached
      end
      return known[item]
    end
  end

  -- (item) -> true when wearing the item in its slot changes the points or effects `hdl` gets from affinity and sets.
  local function active_bonus_test(d, hdl)
    local _, c, s = scale()
    local worn = c and worn_of(hdl) or nil
    if not worn then return nothing end
    local card, card_read = nil, false
    local function card_of()
      if not card_read then card_read, card = true, wearer(hdl) end
      return card
    end
    local function bonus(list)
      local add, effects = additions_worn(list, card_of, d, c, false)
      return table.concat(add or {}, ",") .. "/" .. tostring(effects or 0)
    end
    local known = player_facts("active_bonus", hdl, worn, s)
    local without = player_facts("bonus_without", hdl, worn, s)
    return function(item)
      if known[item] == nil then
        local slot = slot_of(d, item)
        if not slot then
          known[item] = false
        else
          local list = { worn[1], worn[2], worn[3], worn[4] }
          if without[slot] == nil then
            list[slot] = 0
            without[slot] = bonus(list)
          end
          list[slot] = item
          known[item] = bonus(list) ~= without[slot]
        end
      end
      return known[item]
    end
  end

  -- The item's own effect (items.toml `passive`), or nil.
  local function effect_of(d, item)
    local e = d.items[item]
    return e and type(e.passive) == "table" and e.passive or nil
  end

  -- A row's test (the words of equipment.toml's header) -> (item) -> true when the row holds for the item.
  local function row_test(test, hdl, rows)
    local d = load()
    local what, arg = string.match(test, "^([%a_]+):?(.*)$")
    if what == "set" then
      local index = d.set_index[arg]
      local set = index and d.sets[index]
      if not set then return nil end
      return function(item) return set.members[item] == true end
    elseif what == "element" or what == "position" then
      if arg ~= "player" then
        return function(item)
          local a = d.affinity[item]
          return a ~= nil and a[what] == arg
        end
      end
      local card = wearer(hdl)
      if not card then return nothing end
      local part = what == "position" and 1 or 2
      return function(item)
        local a = d.affinity[item]
        return a ~= nil and select(part, affinity_match(a, card)) == true
      end
    elseif what == "effect_kind" or what == "effect_move" then
      local words = word_set(arg)
      local field = what == "effect_kind" and "kind" or "move_kind"
      return function(item)
        local e = effect_of(d, item)
        return e ~= nil and words[e[field]] == true
      end
    elseif what == "effect_rest" then
      local named = {}
      for _, row in ipairs(rows) do
        if string.find(row.test, "^effect_kind:") or string.find(row.test, "^effect_move:") then
          named[#named + 1] = row_test(row.test, hdl, rows)
        end
      end
      return function(item)
        if effect_of(d, item) == nil then return false end
        for _, other in ipairs(named) do
          if other(item) then return false end
        end
        return true
      end
    elseif what == "set_completes" then
      return completes_set_test(d, hdl)
    elseif what == "bonus_active" then
      return active_bonus_test(d, hdl)
    end
    return nil
  end

  -- The rows of an `each` list: "sets" = one row per set, by name, shown in the lists of its pieces' slots.
  local function row_list(name)
    if name ~= "sets" then return {} end
    local d = load()
    local rows = {}
    for _, set in ipairs(d.sets) do
      local label = set_name(set)
      local inventories = {}
      for id in pairs(set.members) do
        local slot = slot_of(d, id)
        if slot then inventories[slot - 1] = true end
      end
      rows[#rows + 1] = { name = set.key, label = label, test = "set:" .. set.key, inventories = inventories,
        order = sort_key(label) }
    end
    table.sort(rows, function(a, b)
      if a.order ~= b.order then return a.order < b.order end
      return a.name < b.name
    end)
    return rows
  end

  -- Every equipment item the tests know (the items with an affinity record).
  local function every_item()
    local items = {}
    for id in pairs(load().affinity) do items[#items + 1] = id end
    return items
  end

  if type(VRFW.item_filter) == "table" then
    -- an item's inventory type: its equipment slot (boots 0, bracelet 1, pendant 2, special 3)
    local function inventory_of(item)
      local slot = slot_of(load(), item)
      return slot and slot - 1 or nil
    end
    CharacterReforged.ItemFilter = VRFW.item_filter.server({ command = "CMND_CHARACTERREFORGED_EQUIPMENT_ITEM_FILTER", items = every_item,
      test = row_test, list = row_list, inventory_of = inventory_of })
  else
    warn("VRFW.item_filter is missing: the filter window's tabs answer nothing")
  end
end

local LUCK = nil

local function luck_table()
  if LUCK then return LUCK end
  LUCK = {}
  local ok, lfiles = pcall(VRFW.files.declarations, "content/equipment/luck.toml")
  for _, f in ipairs((ok and lfiles) or {}) do
    for _, e in ipairs((f.data or {}).item or {}) do
      if type(e.item) == "string" and type(e.luck) == "number" then LUCK[id_of(e.item)] = e.luck end
    end
  end
  return LUCK
end

function CharacterReforged.Luck(hdl)
  local luck = luck_table()
  local ok, a, b, c, d = pcall(VRFW.item.equipped, tonumber(hdl) or 0)
  if not ok or a == nil then return 0 end
  local okS, s = pcall(VRFW.item.equipment_scale)
  if not okS or type(s) ~= "number" then return 0 end
  local sum = 0
  for _, id in ipairs({ a, b, c, d }) do
    local frac = id and luck[u32(id)]
    if frac then sum = sum + frac end
  end
  return math.floor(sum * s + 0.5)
end


-- The equipment tables come from the mods' files only, so they are built at script load (the boot thread), not in the save's load.
do
  local ok, e = pcall(load)
  if not ok then warn("equipment tables not built at script load: " .. tostring(e)) end
end
