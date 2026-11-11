
CharacterReforged = CharacterReforged or {}
CharacterReforged.PlayerSets = CharacterReforged.PlayerSets or {}
local PlayerSets = CharacterReforged.PlayerSets

local BLOB = "ss_player_sets.json"
local FILE_VERSION = 4
local DEFAULT_SETS_PER_PAGE = 5
local DEFAULT_PAGES = 4
local PASSIVE_SLOTS = 5
local NAME_MAX = 40
local SAVE_FULL_VALUES = 6 + 1 + 5 + 1 + PASSIVE_SLOTS * 2 + 1

local info, _, err = VRFW.logger("player sets")

local read_memory = VRFW.memory.read

-- an integer toward zero, nil when not a number
local function integer_of(value) return VRFW.value.integer(value, nil) end

local Id = VRFW.ids
-- the unsigned 32-bit value the game stores (T2B ints arrive signed)
local u32 = Id.unsigned

local function hex8(value)
  value = u32(value)
  return string.format("%04X%04X", math.floor(value / 65536), value % 65536)
end

local function active_slot()
  return VRFW.slots.active()
end

local config = VRFW.config

local function set_layout()
  local per = integer_of(config("player_sets.sets_per_page", DEFAULT_SETS_PER_PAGE)) or DEFAULT_SETS_PER_PAGE
  local pages = integer_of(config("player_sets.pages", DEFAULT_PAGES)) or DEFAULT_PAGES
  return math.max(1, per), math.max(1, pages)
end

local function set_count()
  local per, pages = set_layout()
  return per * pages
end

local function clean_name(text)
  if type(text) ~= "string" then return "" end
  local out, count, i, length = {}, 0, 1, #text
  while i <= length and count < NAME_MAX do
    local byte = text:byte(i)
    local width = byte < 0x80 and 1 or byte >= 0xF0 and 4 or byte >= 0xE0 and 3 or byte >= 0xC0 and 2 or 1
    local character = text:sub(i, i + width - 1)
    local code_point
    if width == 1 then
      code_point = byte
    elseif width == 2 then
      code_point = (byte % 0x20) * 64 + ((text:byte(i + 1) or 0x80) % 0x40)
    end
    i = i + width
    local control = code_point and (code_point < 0x20 or (code_point >= 0x7F and code_point <= 0x9F))
    if not control and character ~= "[" and character ~= "]" then
      out[#out + 1] = character
      count = count + 1
    end
  end
  return table.concat(out)
end

-- the chara_param id of a saved character (record checked against the handle), nil when unknown
local function param_of(handle)
  local kind = math.floor(handle / 4096) % 16
  if handle == 0 or kind >= 0xD then return nil end
  local ok, record = pcall(VRFW.character.record, handle)
  if not ok or not record or not record.addr or record.addr < 0x10000 then return nil end
  if read_memory("u32", record.addr) ~= handle then return nil end
  return read_memory("i32", record.addr + 4)
end

local function hex_list(values)
  local out = {}
  for k, v in ipairs(values) do out[k] = hex8(v) end
  return "[" .. table.concat(out, ", ") .. "]"
end

local function id_list(values, count)
  local out = {}
  for k = 1, count do out[k] = u32(type(values) == "table" and tonumber(values[k]) or 0) end
  return out
end

local function set_from_json(j)
  if type(j) ~= "table" then return nil end
  local set = {
    name = type(j.name) == "string" and j.name or "",
    moves = id_list(j.moves, 6),
    aura = u32(tonumber(j.hiper) or 0),
    equip = id_list(j.equip, 5),
    sixsense = u32(tonumber(j.sixsense) or 0),
    mix = u32(tonumber(j.mix) or 0),
  }
  if type(j.passives) == "table" then set.passives = id_list(j.passives, PASSIVE_SLOTS) end
  if type(j.passive_cfg) == "table" then set.passive_cfg = id_list(j.passive_cfg, PASSIVE_SLOTS) end
  if tonumber(j.role) then set.role = integer_of(j.role) end
  if tonumber(j.kit) then set.kit = u32(tonumber(j.kit)) end
  return set
end

local function sets_from_json(value)
  local sets = {}
  if type(value) ~= "table" then return sets end
  for key, j in pairs(value) do
    local index = type(key) == "number" and key or tonumber(key)
    if index and index >= 1 and index == math.floor(index) then sets[index] = set_from_json(j) end
  end
  return sets
end

local function decode(text)
  local ok, j, why = pcall(VRFW.json.decode, text)
  if not ok or type(j) ~= "table" then return nil, "bad JSON: " .. tostring(ok and why or j) end
  local file = { players = {} }
  if type(j.players) == "table" then
    for key, entry in pairs(j.players) do
      if type(key) == "string" and type(entry) == "table" then
        file.players[key] = { param_id = integer_of(entry.param_id) or 0, sets = sets_from_json(entry.sets) }
      end
    end
  end
  return file
end

local function set_to_json(set)
  local j = {
    name = set.name,
    moves = set.moves,
    hiper = set.aura,
    equip = set.equip,
    sixsense = set.sixsense,
  }
  if set.mix and set.mix ~= 0 then j.mix = set.mix end
  if set.passives then j.passives = set.passives end
  if set.passive_cfg then j.passive_cfg = set.passive_cfg end
  if set.role then j.role = set.role end
  if set.kit and set.kit ~= 0 then j.kit = set.kit end
  return j
end

local function encode(file)
  local players = {}
  for key, entry in pairs(file.players) do
    local sets = {}
    for index, set in pairs(entry.sets) do
      sets[tostring(index)] = set_to_json(set)
    end
    players[key] = { param_id = entry.param_id, sets = sets }
  end
  return VRFW.json.encode({ version = FILE_VERSION, players = players })
end

local function load()
  local slot = active_slot()
  local ok, text = pcall(VRFW.save.get_blob, slot, BLOB)
  if not ok then
    err(BLOB .. " of slot " .. tostring(slot) .. ": " .. tostring(text) .. " (starting empty)")
    return { players = {} }
  end
  if type(text) ~= "string" or text == "" then return { players = {} } end
  local file, why = decode(text)
  if not file then
    err(BLOB .. " of slot " .. tostring(slot) .. ": " .. tostring(why) .. " (starting empty)")
    return { players = {} }
  end
  return file
end

local function write(file, what)
  local slot = active_slot()
  local ok, text = pcall(encode, file)
  if not ok then
    err("encode: " .. tostring(text))
    return false
  end
  local written, why = pcall(VRFW.save.set_blob, slot, BLOB, text)
  if not written or why == false then
    err("write slot " .. tostring(slot) .. ": " .. tostring(why))
    return false
  end
  info(what .. " (slot " .. tostring(slot) .. ")")
  return true
end

local function get(file, handle, param_id, index)
  local entry = file.players[hex8(handle)]
  if not entry or entry.param_id ~= param_id then return nil end
  return entry.sets[index + 1]
end

local function put(file, handle, param_id, index, set)
  if index >= set_count() then return false end
  local key = hex8(handle)
  local entry = file.players[key]
  if not entry or entry.param_id ~= param_id then
    entry = { param_id = param_id, sets = {} }
    file.players[key] = entry
  end
  entry.sets[index + 1] = set
  if next(entry.sets) == nil then file.players[key] = nil end
  return true
end

-- the player and set index of a command (nil when the handle has no record or the index is out of range)
local function target(handle, index)
  local param_id = param_of(u32(handle))
  local n = integer_of(index)
  if not param_id or not n or n < 0 or n >= set_count() then return nil end
  return param_id, n
end

local function store(handle, index, set, what)
  local param_id, n = target(handle, index)
  if not param_id then return false end
  local file = load()
  return put(file, u32(handle), param_id, n, set) and write(file, what)
end

local function describe(handle, index, set)
  return string.format("0x%s set %s = %q moves %s aura %s mix %s equip %s custom passive %s passives %s configured %s role %s",
    hex8(handle), tostring(index), set.name, hex_list(set.moves), hex8(set.aura), hex8(set.mix or 0), hex_list(set.equip),
    hex8(set.sixsense), set.passives and hex_list(set.passives) or "none",
    set.passive_cfg and hex_list(set.passive_cfg) or "none", tostring(set.role))
end

function PlayerSets.Pages()
  return set_layout()
end

function PlayerSets.Get(handle, index)
  local param_id, n = target(handle, index)
  local set = param_id and get(load(), u32(handle), param_id, n)
  if not set then return false, "" end
  local m, e = set.moves, set.equip
  return true, set.name, m[1], m[2], m[3], m[4], m[5], m[6], set.aura, e[1], e[2], e[3], e[4], e[5], set.sixsense
end

function PlayerSets.Full(handle, index)
  local param_id, n = target(handle, index)
  local set = param_id and get(load(), u32(handle), param_id, n)
  if not set then return false, "" end
  return true, set.name, set.moves, set.aura, set.equip, set.sixsense, set.passives or false, set.passive_cfg or false,
    set.role or -1, set.kit or 0, set.mix or 0
end

function PlayerSets.Save(handle, index, name, ...)
  local values = { ... }
  local set = { name = clean_name(name), moves = {}, equip = {}, mix = 0 }
  for k = 1, 6 do set.moves[k] = u32(values[k]) end
  set.aura = u32(values[7])
  for k = 1, 5 do set.equip[k] = u32(values[7 + k]) end
  set.sixsense = u32(values[13])
  return store(handle, index, set, describe(u32(handle), integer_of(index), set))
end

function PlayerSets.SaveFull(handle, index, name, ...)
  local raw = { ... }
  local values = {}
  for k = 1, SAVE_FULL_VALUES + 2 do
    if type(raw[k]) == "number" then values[k] = integer_of(raw[k]) end
  end
  local function id(k) return values[k + 1] and u32(values[k + 1]) or 0 end
  local set = { name = clean_name(name), moves = {}, equip = {} }
  for k = 0, 5 do set.moves[k + 1] = id(k) end
  set.aura = id(6)
  for k = 0, 4 do set.equip[k + 1] = id(7 + k) end
  set.sixsense = id(12)
  if values[14] ~= nil then
    set.passives, set.passive_cfg = {}, {}
    for k = 0, PASSIVE_SLOTS - 1 do
      set.passives[k + 1] = id(13 + k)
      set.passive_cfg[k + 1] = id(13 + PASSIVE_SLOTS + k)
    end
  end
  local role = values[SAVE_FULL_VALUES]
  if role and role >= 0 and role <= 2 then set.role = role end
  local kit = values[SAVE_FULL_VALUES + 1]
  if kit and kit ~= 0 then set.kit = u32(kit) end
  set.mix = id(SAVE_FULL_VALUES + 1)
  return store(handle, index, set, describe(u32(handle), integer_of(index), set))
end

function PlayerSets.Delete(handle, index)
  return store(handle, index, nil, string.format("0x%s set %s deleted", hex8(u32(handle)), tostring(integer_of(index))))
end

local DEFAULT_EXPORT_AREA = "vrmod/characters"
local EQUIP_SLOTS = { "shoes", "misanga", "pendant", "special", "costume" }   -- equipment types 0..4
local FILE_KIND = "character"

local function own_id()
  return VRFW.mod or "CharacterReforged"
end

local function own_version()
  local ok, manifest = pcall(VRFW.files.toml, "mod.toml")
  return ok and type(manifest) == "table" and type(manifest.version) == "string" and manifest.version or "?"
end

local function export_area()
  local area = config("player_sets.export_area", DEFAULT_EXPORT_AREA)
  if area == "" then area = DEFAULT_EXPORT_AREA end
  return area
end

-- Arguments: handle, player name, level, m1 … m6, aura, e1 … e5, sixsense, role, set name, p1 … p5, c1 … c5, kit, mix and an optional save ticket.
function PlayerSets.Export(handle, player_name, level, ...)
  local h = u32(handle)
  local param_id = param_of(h)
  if not param_id then return false, "no saved player for handle 0x" .. hex8(h) end
  local values = { ... }
  local needed = {}
  local me = own_id()
  local set = { moves = {}, equip = {} }
  for k = 1, 6 do
    local id = u32(values[k])
    if id ~= 0 then
      local entry
      entry, needed = BetterQoL.VrmodFilesReference(needed, "move", "moves", id)
      entry.slot = k
      set.moves[#set.moves + 1] = entry
    end
  end
  for t = 1, 5 do
    local id = u32(values[7 + t])
    if id ~= 0 then set.equip[EQUIP_SLOTS[t]], needed = BetterQoL.VrmodFilesReference(needed, "item", "items", id) end
  end
  if next(set.equip) == nil then set.equip = nil end   -- an empty table would be written as `[]`
  local sixsense = u32(values[13])
  if sixsense ~= 0 then set.sixsense, needed = BetterQoL.VrmodFilesReference(needed, "item", "items", sixsense) end
  local set_name = type(values[15]) == "string" and clean_name(values[15]) or ""
  if set_name ~= "" then set.name = set_name end
  local passives, configured = {}, {}
  for k = 1, PASSIVE_SLOTS do
    local id, chosen = u32(values[15 + k]), u32(values[20 + k])
    if id ~= 0 then
      local entry
      entry, needed = BetterQoL.VrmodFilesReference(needed, "passive", "passives", id)
      entry.slot = k
      passives[#passives + 1] = entry
    end
    if chosen ~= 0 then
      local entry
      entry, needed = BetterQoL.VrmodFilesReference(needed, "passive", "passives", chosen)
      entry.slot = k
      configured[#configured + 1] = entry
    end
  end
  if #passives > 0 then set.passives = passives end
  if #configured > 0 then set.passive_cfg = configured end
  local kit = u32(values[26])
  if kit ~= 0 then set.kit, needed = BetterQoL.VrmodFilesReference(needed, "kit", "kits", kit) end
  local mine = {}
  local aura = u32(values[7])
  if aura ~= 0 then mine.aura, needed = BetterQoL.VrmodFilesReference(needed, "move", "aura", aura) end
  local mix = u32(values[27])
  if mix ~= 0 then mine.mix, needed = BetterQoL.VrmodFilesReference(needed, "move", "mix", mix) end
  local role = integer_of(values[14])
  if role and role >= 0 and role <= 2 then mine.role = role end
  if next(mine) ~= nil then
    set.mods = { [me] = mine }
    local parts = {}
    for part in pairs(mine) do parts[#parts + 1] = part end
    needed = BetterQoL.VrmodFilesNeed(needed, me, own_version(), parts)
  end
  local character
  character, needed = BetterQoL.VrmodFilesReference(needed, "chara", "characters", param_id)
  character.name = clean_name(player_name)
  character.level = integer_of(level)
  character.set = set
  return BetterQoL.VrmodFilesWrite({
    kind = FILE_KIND,
    body = character,
    name = set_name ~= "" and (character.name .. " - " .. set_name) or character.name,
    file_stem = "player_" .. hex8(param_id),
    needed = needed,
    area = export_area(),
    exporter = me .. "@" .. own_version(),
    ticket = values[28],
  })
end

-- CMND_CHARACTERREFORGED_PLAYER_SET_AREA answers the area the player set files go to.
function PlayerSets.Area()
  return export_area()
end

function PlayerSets.ImportList()
  return BetterQoL.VrmodFilesList(export_area(), FILE_KIND)
end

function PlayerSets.ImportEntry(index)
  return BetterQoL.VrmodFilesEntry(export_area(), FILE_KIND, index)
end

-- (listed index, handle[, open ticket]): the file of the open ticket when there is one, else listed entry `index`.
function PlayerSets.ImportRead(index, handle, ticket)
  local read, why
  if ticket ~= nil then
    read, why = BetterQoL.VrmodFilesReadPicked(FILE_KIND, ticket)
  else
    read, why = BetterQoL.VrmodFilesRead(export_area(), FILE_KIND, index)
  end
  if not read then return false, tostring(why) end
  local unresolved = read.missing
  -- The id of one file reference; a name it cannot resolve is added to the missing list.
  local function resolve(id_kind, reference)
    local id, name = BetterQoL.VrmodFilesResolve(id_kind, reference)
    if name then unresolved[#unresolved + 1] = name end
    return u32(id)
  end
  local character = read.body
  local set = type(character.set) == "table" and character.set or {}
  local out = {}
  local moves = {}
  for _, m in ipairs(type(set.moves) == "table" and set.moves or {}) do
    local k = integer_of(type(m) == "table" and m.slot)
    if k and k >= 1 and k <= 6 then moves[k] = resolve("move", m) end
  end
  for k = 1, 6 do out[#out + 1] = moves[k] or 0 end
  local parts = type(set.mods) == "table" and set.mods or {}
  local mine = type(parts[own_id()]) == "table" and parts[own_id()] or {}
  out[#out + 1] = resolve("move", mine.aura)
  local equip = type(set.equip) == "table" and set.equip or {}
  for t = 1, 5 do out[#out + 1] = resolve("item", equip[EQUIP_SLOTS[t]]) end
  out[#out + 1] = resolve("item", set.sixsense)
  local role = integer_of(mine.role)
  out[#out + 1] = (role and role >= 0 and role <= 2) and role or -1
  local passives, configured = {}, {}
  local has_passives = type(set.passives) == "table" or type(set.passive_cfg) == "table"
  for _, x in ipairs(type(set.passives) == "table" and set.passives or {}) do
    local k = integer_of(type(x) == "table" and x.slot)
    if k and k >= 1 and k <= PASSIVE_SLOTS then passives[k] = resolve("passive", x) end
  end
  for _, x in ipairs(type(set.passive_cfg) == "table" and set.passive_cfg or {}) do
    local k = integer_of(type(x) == "table" and x.slot)
    if k and k >= 1 and k <= PASSIVE_SLOTS then configured[k] = resolve("passive", x) end
  end
  for k = 1, PASSIVE_SLOTS do out[#out + 1] = has_passives and (passives[k] or 0) or -1 end
  for k = 1, PASSIVE_SLOTS do out[#out + 1] = has_passives and (configured[k] or 0) or 0 end
  out[#out + 1] = resolve("kit", set.kit)
  out[#out + 1] = resolve("move", mine.mix)
  local set_name = type(set.name) == "string" and clean_name(set.name) or ""
  local param_id = u32(character.id)
  local missing = table.concat(unresolved, ", ")
  info(string.format("import read %s: chara 0x%s for 0x%s, checksum %s, missing [%s]", read.file, hex8(param_id),
    hex8(u32(handle)), read.checksum_ok and "ok" or "BAD", missing))
  return true, set_name, param_id, read.checksum_ok, missing, (table.unpack or unpack)(out)
end
