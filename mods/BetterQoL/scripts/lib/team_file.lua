-- Team files: the team shown on the team dock written to, and read from, a .vrmod share file (container: lib/vrmod_files.lua).
local B = VRFW.bytes
local S = require "lib/template_store"
local Files = require "lib/vrmod_files"

BetterQoL = BetterQoL or {}
BetterQoL.TeamFile = BetterQoL.TeamFile or {}
local TeamFile = BetterQoL.TeamFile

local info = VRFW.logger("team file")

local band, bor, lshift, rshift = bit32.band, bit32.bor, bit32.lshift, bit32.rshift
local int = VRFW.value.integer
local u32 = VRFW.ids.unsigned

local FILE_KIND = "team"
local DEFAULT_EXPORT_AREA = "vrmod/teams"
local NAME_MAX = 64
-- TeamInfo fields after the member list (docs/game/ui/pachanga-templates.md 9.1).
local FIELD = {
  NAME = 0x000, AURA_SLOTS = 0x250, COACH = 0x288, FORMATION = 0x28C, KIT = 0x290, KIT_ITEM = 0x294, EMBLEM = 0x298,
  CAPTAIN_CHARACTER = 0x2A0, CAPTAIN_HANDLE = 0x2A4, TACTICS = 0x2A8, TACTIC_ITEMS = 0x2B8,
}
local AURA_SLOT_COUNT = 4
local TACTIC_COUNT = 4
-- Words of a member record: +0x0 handle, +0x4 cleared by the game when it places a player, +0x8 kept with the slot, +0xC the shirt number (u16), the position (byte +0xE) and the game's recount flags (byte +0xF).
local RECORD = { HANDLE = 0, PLACED = 1, SLOT = 2, NUMBER_POSITION = 3 }

local function export_area()
  local area = VRFW.config("team_files.export_area", DEFAULT_EXPORT_AREA)
  if type(area) ~= "string" or area == "" then area = DEFAULT_EXPORT_AREA end
  return area
end

local function own_version()
  local ok, manifest = pcall(VRFW.files.toml, "mod.toml")
  return ok and type(manifest) == "table" and type(manifest.version) == "string" and manifest.version or "?"
end

-- The 1-based word index of byte `offset` of team `team` in the words of one team set.
local function word_at(team, offset)
  return S.wi(0, team * S.TEAM_SIZE + offset)
end

local function team_name(words, team)
  local first = word_at(team, FIELD.NAME)
  return B.before_zero(B.text_of_words(words, first, first + S.NAME_LEN / 4 - 1))
end

-- A team name without control characters, at most NAME_MAX bytes (cut at a character border).
local function clean_name(text)
  if type(text) ~= "string" then return "" end
  text = text:gsub("%c", "")
  local length = math.min(#text, NAME_MAX)
  while length > 0 and length < #text and band(text:byte(length + 1), 0xC0) == 0x80 do length = length - 1 end
  return text:sub(1, length)
end

-- The chara_param id and get order of a live character handle; nil when it has no record.
local function identity(handle)
  local ok, record = pcall(VRFW.character.record, handle)
  if ok and type(record) == "table" then return u32(record.param or 0), record.get_order or 0 end
  return nil
end

-- The internal name of the character of card `param` (shown in the result window when the save has no such player).
local function character_name(param)
  local ok, base = pcall(VRFW.character.base_of, param)
  if ok and base ~= nil then
    local ok_character, character = pcall(VRFW.character.character, base)
    if ok_character and type(character) == "table" and type(character.name) == "string" then return character.name end
  end
  return string.format("%08X", param)
end

-- The team `team` of the set `words` as a file table; nil when it has no member and no name.
local function team_to_file(needed, words, team)
  local out = { index = team, member = {} }
  local slot_of_handle = {}
  for slot = 0, S.MEMBERS - 1 do
    local at = S.wi(0, S.member_off(team, slot))
    local handle = words[at]
    if handle ~= 0 then
      local param, order = identity(handle)
      if param then
        local detail = words[at + RECORD.NUMBER_POSITION]
        local chara = Files.reference(needed, "chara", "characters", param)
        chara.name = character_name(param)
        out.member[#out.member + 1] = {
          slot = slot, chara = chara, order = order, number = band(detail, 0xFFFF), position = band(rshift(detail, 16), 0xFF),
        }
        slot_of_handle[handle] = slot
      end
    end
  end
  -- Every slot keeps its position, filled or not, so the import rebuilds the formation slot by slot.
  out.positions = {}
  for slot = 0, S.MEMBERS - 1 do
    out.positions[slot + 1] = band(rshift(words[S.wi(0, S.member_off(team, slot)) + RECORD.NUMBER_POSITION], 16), 0xFF)
  end
  local name = clean_name(team_name(words, team))
  if #out.member == 0 and name == "" then return nil end
  out.name = name
  local function field(offset) return words[word_at(team, offset)] end
  if field(FIELD.COACH) ~= 0 then out.coach = Files.reference(needed, "chara", "characters", field(FIELD.COACH)) end
  if field(FIELD.FORMATION) ~= 0 then out.formation = Files.reference(needed, "formation", "formations", field(FIELD.FORMATION)) end
  if field(FIELD.KIT) ~= 0 then out.kit = Files.reference(needed, "kit", "kits", field(FIELD.KIT)) end
  if field(FIELD.EMBLEM) ~= 0 then out.emblem = Files.reference(needed, "emblem", "emblems", field(FIELD.EMBLEM)) end
  out.captain = slot_of_handle[field(FIELD.CAPTAIN_HANDLE)]
  local tactics = {}
  for k = 0, TACTIC_COUNT - 1 do
    local id = field(FIELD.TACTICS + k * 4)
    if id ~= 0 then
      local entry = Files.reference(needed, "tactic", "tactics", id)
      entry.slot = k + 1
      tactics[#tactics + 1] = entry
    end
  end
  if #tactics > 0 then out.tactics = tactics end
  local auras = {}
  for k = 0, AURA_SLOT_COUNT - 1 do
    local member_slot, skill = slot_of_handle[field(FIELD.AURA_SLOTS + k * 8)], field(FIELD.AURA_SLOTS + k * 8 + 4)
    if member_slot and skill ~= 0 then
      local entry = Files.reference(needed, "move", "auras", skill)
      entry.slot, entry.member = k + 1, member_slot
      auras[#auras + 1] = entry
    end
  end
  if #auras > 0 then out.auras = auras end
  if #out.member == 0 then out.member = nil end   -- an empty table would be written as `[]`
  return out
end

-- CMND_BETTERQOL_TEAM_FILE_EXPORT (team set[, save ticket]) answers true, file and area (nil for a picked file), or false and why.
function TeamFile.Export(set, ticket)
  local words = BetterQoL.TeamTemplates.DockWords(set)
  if not words then return false, "the shown team cannot be read" end
  local needed, teams = {}, {}
  for team = 0, S.TEAMS - 1 do
    teams[#teams + 1] = team_to_file(needed, words, team)
  end
  if #teams == 0 then return false, "empty" end
  local name = teams[1].name
  return Files.write({
    kind = FILE_KIND,
    body = { members_per_team = S.MEMBERS, teams = teams },
    name = name,
    file_stem = "team_" .. tostring(BetterQoL.TemplateOfDock(int(set, -1)) or 0),
    needed = needed,
    area = export_area(),
    exporter = "BetterQoL@" .. own_version(),
    ticket = ticket,
  })
end

-- CMND_BETTERQOL_TEAM_FILE_NAME (team set) answers the name of the shown team and the area its files go to.
function TeamFile.Name(set)
  local words = BetterQoL.TeamTemplates.DockWords(set)
  return words and clean_name(team_name(words, 0)) or "", export_area()
end

-- The read share file: listed entry `index`, or the file of open pick `ticket` when there is one.
local function read_file(index, ticket)
  if ticket ~= nil then return Files.read_picked(FILE_KIND, ticket) end
  return Files.read(export_area(), FILE_KIND, index)
end

-- CMND_BETTERQOL_TEAM_FILE_EMPTY (team set) -> true when the shown team has no member and no name
function TeamFile.Empty(set)
  local words = BetterQoL.TeamTemplates.DockWords(set)
  if not words then return false end
  return S.unused_set(words, 0) == true
end

-- CMND_BETTERQOL_TEAM_FILE_LIST -> count, area (the area's team files, newest first)
function TeamFile.List()
  return Files.list(export_area(), FILE_KIND)
end

-- CMND_BETTERQOL_TEAM_FILE_ENTRY (index) -> file, label
function TeamFile.Entry(index)
  return Files.entry(export_area(), FILE_KIND, index)
end

-- CMND_BETTERQOL_TEAM_FILE_CHECK (index[, open ticket]) answers true, checksum ok, missing mods text and team name, or false and why.
function TeamFile.Check(index, ticket)
  local read, why = read_file(index, ticket)
  if not read then return false, tostring(why) end
  local first = type(read.body.teams) == "table" and read.body.teams[1] or nil
  return true, read.checksum_ok, table.concat(read.missing, ", "), type(first) == "table" and clean_name(first.name) or ""
end

-- The handles of the save's players by chara_param id, each list with its get orders.
local function owned_players()
  local by_param = {}
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param", "get_order" })
  if not ok or type(columns) ~= "table" or type(columns.handle) ~= "table" then return by_param end
  for i, handle in ipairs(columns.handle) do
    local param = u32(columns.param[i])
    local list = by_param[param] or {}
    list[#list + 1] = { handle = handle, order = columns.get_order[i] or 0 }
    by_param[param] = list
  end
  return by_param
end

-- What the save's own docks already use: field offset -> id -> the item handle stored with it (0 when the field has none).
local function values_in_use()
  local in_use = { [FIELD.COACH] = {}, [FIELD.FORMATION] = {}, [FIELD.KIT] = {}, [FIELD.EMBLEM] = {}, [FIELD.TACTICS] = {} }
  for set = S.FIRST_DOCK, S.LAST_DOCK do
    local words = BetterQoL.TeamTemplates.DockWords(set)
    for team = 0, words and S.TEAMS - 1 or -1 do
      local function field(offset) return words[word_at(team, offset)] end
      in_use[FIELD.COACH][field(FIELD.COACH)] = 0
      in_use[FIELD.FORMATION][field(FIELD.FORMATION)] = 0
      in_use[FIELD.EMBLEM][field(FIELD.EMBLEM)] = 0
      in_use[FIELD.KIT][field(FIELD.KIT)] = field(FIELD.KIT_ITEM)
      for k = 0, TACTIC_COUNT - 1 do
        in_use[FIELD.TACTICS][field(FIELD.TACTICS + k * 4)] = field(FIELD.TACTIC_ITEMS + k * 4)
      end
    end
  end
  return in_use
end

-- Writes file team `source` over team `team` of `words` -> members placed, names of the members the save does not own, fields kept.
local function file_to_team(read, source, words, team, owned, in_use)
  local placed, skipped, kept = 0, {}, 0
  local function put(offset, value) words[word_at(team, offset)] = value end
  for slot = 0, S.MEMBERS - 1 do
    S.clear_member(words, 0, team, slot)
    local at = S.wi(0, S.member_off(team, slot))
    words[at + RECORD.NUMBER_POSITION] = lshift(band(int(source.positions[slot + 1], 0), 0xFF), 16)
  end
  for k = 0, AURA_SLOT_COUNT * 2 - 1 do put(FIELD.AURA_SLOTS + k * 4, 0) end
  put(FIELD.CAPTAIN_CHARACTER, 0)
  put(FIELD.CAPTAIN_HANDLE, 0)
  local name_words = B.read_words(B.padded(clean_name(source.name), S.NAME_LEN), 0, S.NAME_LEN / 4)
  for k = 1, #name_words do words[word_at(team, FIELD.NAME) + k - 1] = name_words[k] end
  local handle_of_slot, taken = {}, {}
  for _, member in ipairs(type(source.member) == "table" and source.member or {}) do
    local slot = int(type(member) == "table" and member.slot, -1)
    if slot >= 0 and slot < S.MEMBERS and handle_of_slot[slot] == nil then
      local param = read.resolve("chara", member.chara)
      local chosen
      for _, player in ipairs(owned[param] or {}) do
        if not taken[player.handle] and (chosen == nil or player.order == member.order) then chosen = player end
      end
      if chosen then
        taken[chosen.handle] = true
        handle_of_slot[slot] = chosen.handle
        local at = S.wi(0, S.member_off(team, slot))
        words[at + RECORD.HANDLE] = chosen.handle
        words[at + RECORD.NUMBER_POSITION] = bor(band(int(member.number, 0), 0xFFFF), lshift(band(int(source.positions[slot + 1], 0), 0xFF), 16))
        placed = placed + 1
        if slot == int(source.captain, -1) then
          put(FIELD.CAPTAIN_CHARACTER, param)
          put(FIELD.CAPTAIN_HANDLE, chosen.handle)
        end
      else
        skipped[#skipped + 1] = type(member.chara) == "table" and type(member.chara.name) == "string" and member.chara.name or "?"
      end
    end
  end
  for _, aura in ipairs(type(source.auras) == "table" and source.auras or {}) do
    local k, handle = int(aura.slot, 0) - 1, handle_of_slot[int(aura.member, -1)]
    local skill = read.resolve("move", aura)
    if k >= 0 and k < AURA_SLOT_COUNT and handle and skill ~= 0 then
      put(FIELD.AURA_SLOTS + k * 8, handle)
      put(FIELD.AURA_SLOTS + k * 8 + 4, skill)
    end
  end
  -- A coach, formation, kit, emblem or tactic is written only when one of the save's own teams already uses it.
  local function put_in_use(offset, item_offset, id_kind, reference)
    if type(reference) ~= "table" then return end
    local id = read.resolve(id_kind, reference)
    local item = id ~= 0 and in_use[offset >= FIELD.TACTICS and FIELD.TACTICS or offset][id] or nil
    if item == nil then
      kept = kept + 1
      return
    end
    put(offset, id)
    if item_offset then put(item_offset, item) end
  end
  put_in_use(FIELD.COACH, nil, "chara", source.coach)
  put_in_use(FIELD.FORMATION, nil, "formation", source.formation)
  put_in_use(FIELD.KIT, FIELD.KIT_ITEM, "kit", source.kit)
  put_in_use(FIELD.EMBLEM, nil, "emblem", source.emblem)
  for _, tactic in ipairs(type(source.tactics) == "table" and source.tactics or {}) do
    local k = int(type(tactic) == "table" and tactic.slot, 0) - 1
    if k >= 0 and k < TACTIC_COUNT then
      put_in_use(FIELD.TACTICS + k * 4, FIELD.TACTIC_ITEMS + k * 4, "tactic", tactic)
    end
  end
  return placed, skipped, kept
end

-- CMND_BETTERQOL_TEAM_FILE_APPLY (index, team set[, open ticket]) answers true, members placed, members skipped, their names and fields kept, or false and why.
function TeamFile.Apply(index, set, ticket)
  local read, why = read_file(index, ticket)
  if not read then return false, tostring(why) end
  local body = read.body
  if int(body.members_per_team, -1) ~= S.MEMBERS or type(body.teams) ~= "table" then
    return false, "the file's team layout is not this game's"
  end
  for _, source in ipairs(body.teams) do
    if type(source) ~= "table" or type(source.positions) ~= "table" or #source.positions ~= S.MEMBERS then
      return false, "the file has no slot positions (an older export): export the team again"
    end
  end
  local current = BetterQoL.TeamTemplates.DockWords(set)
  if not current then return false, "the shown team cannot be read" end
  local words = S.copy_words(current)
  local owned, in_use = owned_players(), values_in_use()
  local placed, skipped, kept = 0, {}, 0
  for _, source in ipairs(body.teams) do
    local team = int(type(source) == "table" and source.index, -1)
    if team >= 0 and team < S.TEAMS then
      local team_placed, team_skipped, team_kept = file_to_team(read, source, words, team, owned, in_use)
      placed, kept = placed + team_placed, kept + team_kept
      for _, name in ipairs(team_skipped) do skipped[#skipped + 1] = name end
    end
  end
  S.recount(words, 0)
  local ok, write_why = BetterQoL.TeamTemplates.WriteDock(set, words)
  if not ok then return false, tostring(write_why) end
  info(string.format("import %s into team set %s: %d member(s) placed, %d not owned [%s], %d field(s) kept", read.file,
    tostring(set), placed, #skipped, table.concat(skipped, ", "), kept))
  return true, placed, #skipped, table.concat(skipped, ", "), kept
end
