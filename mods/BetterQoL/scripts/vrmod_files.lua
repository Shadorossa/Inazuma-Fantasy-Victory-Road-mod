-- The cross-mod entry points of the .vrmod share files (lib/vrmod_files.lua): arguments arrive as copies, so every result is returned.
local Files = require "lib/vrmod_files"

BetterQoL = BetterQoL or {}

--- A reference to id `id` of `kind`, and `needed` with the mod of that id added under the part name `part` -> entry, needed.
function BetterQoL.VrmodFilesReference(needed, kind, part, id)
  local entry = Files.reference(needed, kind, part, id)
  return entry, needed
end

--- `needed` with mod `mod_id` (with its version) and the part names `parts` added -> needed.
function BetterQoL.VrmodFilesNeed(needed, mod_id, version, parts)
  Files.need(needed, mod_id, version, parts)
  return needed
end

--- Writes one share file: rules = { kind, body, name, file_stem, needed, area, exporter } -> true, file, area; false, why.
BetterQoL.VrmodFilesWrite = Files.write

--- Lists the share files of `kind` in `area`, newest first -> count, area.
BetterQoL.VrmodFilesList = Files.list

--- The file name and label of listed entry `index` (0-based); nil when there is none.
BetterQoL.VrmodFilesEntry = Files.entry

--- Reads listed entry `index` -> { body, file, checksum_ok, missing }; nil, why (references resolve with VrmodFilesResolve).
function BetterQoL.VrmodFilesRead(area, kind, index)
  local read, why = Files.read(area, kind, index)
  if not read then return nil, why end
  return { body = read.body, file = read.file, checksum_ok = read.checksum_ok, missing = read.missing }
end

--- The id of one `reference` of kind `id_kind` for the active mods -> id, or 0 and the unresolved name.
BetterQoL.VrmodFilesResolve = Files.resolve
