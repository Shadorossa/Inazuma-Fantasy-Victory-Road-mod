-- The .vrmod share files: one text container (header, needed mods, checksum) that every exporter and importer uses.
-- Each script VM that requires this library gets its own copy, so a list and its entry and read calls share one VM.
local Files = {}

-- The schema this version writes, and every schema it reads (files written before the container moved here included).
local WRITTEN_SCHEMA = "BetterQoL.vrmod/1"
local READ_SCHEMAS = { ["BetterQoL.vrmod/1"] = true, ["CharacterReforged.vrmod/1"] = true }
local FILE_EXTENSION = ".vrmod"
local EXPORT_ROOT = "modloader_exports"

local info, _, err = VRFW.logger("vrmod files")

local u32 = VRFW.ids.unsigned

-- The files of an area listed last, by "area|kind" (a list command caches them for the entry and read commands).
local listed_by_area = {}

--- The folder the game shows for `area` (the place the files are written to and read from).
function Files.shown_folder(area)
  return EXPORT_ROOT .. "/" .. tostring(area or "")
end

--- True and the slot when the active save slot is a reserved one (no file leaves or enters it).
function Files.reserved_slot()
  local slot = VRFW.slots.active()
  local ok, reserved = pcall(VRFW.slots.reserved, slot)
  return ok and reserved == true, slot
end

--- A reference to id `id` of `kind` with the mod it comes from; `needed` collects that mod under the part name `part`.
function Files.reference(needed, kind, part, id)
  local entry = { id = u32(id), origin = "game" }
  local ok, origin = pcall(VRFW.ids.origin, kind, id)
  if ok and type(origin) == "table" and type(origin.origin) == "string" and origin.origin ~= "game" then
    entry.origin = origin.origin
    if type(origin.key) == "string" then entry.key = origin.key end
    Files.need(needed, origin.origin, origin.version, { part })
  end
  return entry
end

--- Adds mod `mod_id` (with its version) and the part names `parts` to `needed`.
function Files.need(needed, mod_id, version, parts)
  local need = needed[mod_id] or { version = version, parts = {} }
  for _, part in ipairs(parts) do need.parts[part] = true end
  needed[mod_id] = need
end

-- The [[vrmod.requires]] rows of `needed`, sorted by mod id.
local function requires_of(needed)
  local ids = {}
  for mod_id in pairs(needed) do ids[#ids + 1] = mod_id end
  table.sort(ids)
  local out = {}
  for _, mod_id in ipairs(ids) do
    local parts = {}
    for part in pairs(needed[mod_id].parts) do parts[#parts + 1] = part end
    table.sort(parts)
    out[#out + 1] = { id = mod_id, version = needed[mod_id].version and tostring(needed[mod_id].version) or nil, parts = parts }
  end
  return out
end

-- The crc32 line of a document (its text written without `checksum`).
local function checksum(doc)
  local keep = doc.vrmod.checksum
  doc.vrmod.checksum = nil
  local body, why = VRFW.files.toml_string(doc)
  doc.vrmod.checksum = keep
  if not body then return nil, why end
  return string.format("crc32:%08X", u32(VRFW.crc32(body)))
end

--- Writes one share file: rules = { kind, body, name, file_stem, needed, area, exporter[, ticket] } -> true, file, area; false, why.
-- With `ticket` (a save the player picked, VRFW.file_pick) the file goes where the player chose and the area result is nil.
function Files.write(rules)
  local reserved, slot = Files.reserved_slot()
  if reserved then return false, "reserved save slot " .. tostring(slot) end
  local doc = {
    vrmod = {
      schema = WRITTEN_SCHEMA,
      kind = rules.kind,
      name = rules.name,
      author = "",
      created = VRFW.time.stamp(),
      exporter = rules.exporter,
      requires = requires_of(rules.needed or {}),
    },
    [rules.kind] = rules.body,
  }
  local sum, why = checksum(doc)
  if not sum then return false, "toml: " .. tostring(why) end
  doc.vrmod.checksum = sum
  local text
  text, why = VRFW.files.toml_string(doc)
  if not text then return false, "toml: " .. tostring(why) end
  local written, write_error, area
  if rules.ticket ~= nil then
    written, write_error = VRFW.files.picked_write(rules.ticket, text)
  else
    local stem = VRFW.files.user_clean(rules.name ~= "" and rules.name or rules.file_stem)
    written, write_error = VRFW.files.user_write(rules.area, stem .. "_" .. VRFW.time.file_stamp() .. FILE_EXTENSION, text, "new")
    area = rules.area
  end
  if not written then
    err("export " .. tostring(rules.kind) .. ": " .. tostring(write_error))
    return false, tostring(write_error)
  end
  info(string.format("exported %s «%s» -> %s/%s", tostring(rules.kind), tostring(rules.name), tostring(area or "picked"), written))
  return true, written, area
end

-- The parsed document of share file text `text` when it is a share file of `kind`; nil, why otherwise.
local function parse_text(text, kind)
  local doc, why = VRFW.files.toml_parse(text)
  if type(doc) ~= "table" then return nil, "toml: " .. tostring(why) end
  if type(doc.vrmod) ~= "table" then return nil, "no [vrmod] table" end
  local schema = tostring(doc.vrmod.schema or "")
  if not READ_SCHEMAS[schema] then return nil, "schema " .. schema .. " (this version reads " .. WRITTEN_SCHEMA .. ")" end
  if doc.vrmod.kind ~= kind or type(doc[kind]) ~= "table" then
    return nil, "kind " .. tostring(doc.vrmod.kind) .. " (this list reads \"" .. kind .. "\")"
  end
  return doc
end

-- The parsed document of `file` in `area` when it is a share file of `kind`; nil, why otherwise.
local function parse(area, kind, file)
  local text, why = VRFW.files.user_read(area, file)
  if not text then return nil, why end
  return parse_text(text, kind)
end

--- Lists the share files of `kind` in `area`, newest first -> count, area.
function Files.list(area, kind)
  local listed = {}
  listed_by_area[area .. "|" .. kind] = listed
  local ok, files = pcall(VRFW.files.user_list, area, "*" .. FILE_EXTENSION)
  if not ok or type(files) ~= "table" then return 0, area end
  local found = {}
  for _, entry in ipairs(files) do
    if not entry.dir then found[#found + 1] = { file = entry.name, modified = tonumber(entry.modified) or 0 } end
  end
  table.sort(found, function(a, b)
    if a.modified ~= b.modified then return a.modified > b.modified end
    return a.file < b.file
  end)
  for _, entry in ipairs(found) do
    local doc = parse(area, kind, entry.file)
    if doc then
      local created = tostring(doc.vrmod.created or ""):sub(1, 16)
      local name = tostring(doc.vrmod.name or entry.file)
      entry.label = created ~= "" and (name .. " · " .. created) or name
      listed[#listed + 1] = entry
    end
  end
  info("import list: " .. #listed .. " " .. kind .. " file(s) in " .. Files.shown_folder(area))
  return #listed, area
end

--- The file name and label of listed entry `index` (0-based); nil when there is none.
function Files.entry(area, kind, index)
  local listed = listed_by_area[area .. "|" .. kind] or {}
  local entry = listed[(VRFW.value.integer(index, -1)) + 1]
  if not entry then return nil end
  return entry.file, entry.label
end

-- The ids of the active mods.
local function active_mods()
  local out = {}
  local ok, declarations = pcall(VRFW.files.declarations, "mod.toml")
  if ok and type(declarations) == "table" then
    for _, declaration in ipairs(declarations) do
      if type(declaration.mod) == "string" then out[declaration.mod] = true end
    end
  end
  return out
end

-- The id of `reference` (a table written by Files.reference) for the active mods `mods` -> id, or 0 and the unresolved name.
-- A reference of a mod that is not active resolves to 0 without a name: that mod is already named once in the file's requires.
local function resolve_with(mods, id_kind, reference)
  if type(reference) ~= "table" then return 0 end
  local id = u32(reference.id)
  if reference.origin == nil or reference.origin == "game" then return id end
  if not mods[reference.origin] then return 0 end
  local ok, origin = pcall(VRFW.ids.origin, id_kind, id)
  if ok and type(origin) == "table" and origin.origin == reference.origin then return id end
  if type(reference.key) == "string" then
    local ok_key, resolved = pcall(VRFW.ids.resolve, id_kind, reference.key)
    if ok_key and type(resolved) == "number" then return u32(resolved) end
  end
  return 0, tostring(reference.key or string.format("%s:%08X", tostring(reference.origin), id))
end

--- The id of one `reference` of kind `id_kind` for the active mods -> id, or 0 and the unresolved name.
function Files.resolve(id_kind, reference)
  return resolve_with(active_mods(), id_kind, reference)
end

--- Reads listed entry `index`: { body, file, checksum_ok, missing, resolve(kind, reference) -> id or 0 }; nil, why.
function Files.read(area, kind, index)
  local reserved, slot = Files.reserved_slot()
  if reserved then return nil, "reserved save slot " .. tostring(slot) end
  local file = Files.entry(area, kind, index)
  if not file then return nil, "no listed file " .. tostring(index) end
  return Files.read_doc(kind, file, parse(area, kind, file))
end

--- Reads the file of open pick `ticket` (VRFW.file_pick): the same result as Files.read; nil, why.
function Files.read_picked(kind, ticket)
  local reserved, slot = Files.reserved_slot()
  if reserved then return nil, "reserved save slot " .. tostring(slot) end
  local text, file = VRFW.files.picked_read(ticket)
  if not text then return nil, tostring(file) end
  return Files.read_doc(kind, file, parse_text(text, kind))
end

--- The read result of parsed document `doc` of file `file` (nil, why when `doc` is nil).
function Files.read_doc(kind, file, doc, why)
  if not doc then
    err("import " .. tostring(file) .. ": " .. tostring(why))
    return nil, tostring(why)
  end
  local sum = checksum(doc)
  local mods = active_mods()
  local missing = {}
  if type(doc.vrmod.requires) == "table" then
    for _, required in ipairs(doc.vrmod.requires) do
      if type(required) == "table" and type(required.id) == "string" and not mods[required.id] then
        missing[#missing + 1] = required.id
      end
    end
  end
  local function resolve(id_kind, reference)
    local id, unresolved = resolve_with(mods, id_kind, reference)
    if unresolved then missing[#missing + 1] = unresolved end
    return id
  end
  return {
    body = doc[kind], file = file, missing = missing, resolve = resolve,
    checksum_ok = sum ~= nil and sum == doc.vrmod.checksum,
  }
end

return Files
