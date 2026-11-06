-- The game's name tags inside a text (<PFX:KEY>, e.g. «Secundaria <MNT:NAGUMOHARA>»): the engine replaces them only
-- in its own text widgets, so a script that shows a game text replaces them itself. The tag's KEY hashes with crc32:
-- MNT = a place name (map/map_name_tag: tag -> map_text noun; map_text_roma when the game's «Nombres de los
-- personajes» is «Originales»), the other prefixes a character (character/chara_name_tag: tag -> character, optional
-- override name text) in the character names the game loaded (a mod's served chara_text, chara_text_roma with
-- «Originales», else chara_text): FUL = the full name, FST = its first word, LST / LAF / LFC = its last word, the other
-- forms (FLC, FFC, FLA…) the short name. Tag tables are read once per script VM, on first use.
--   local NameTags = require "VRFW/lib/name_tags"
--   NameTags.expand(s, lang)  -> s with every known tag replaced; second value: true when a tag is left unresolved
--   NameTags.clean(s, lang)   -> s with every known tag replaced and the unknown ones removed, trimmed
--   NameTags.original_names() -> true when the game's «Nombres de los personajes» is «Originales»
local M = {}

require "VRFW/lib/basics"
local GameText = require "VRFW/lib/game_text"
local Columns = require "VRFW/lib/table_columns"
local _, warn = VRFW.logger("name_tags")

local CHARA_TAG_STEM = "data/common/gamedata/character/chara_name_tag"
local CHARA_TAG_LIST = "m_charaNameTagConfigList"
local MAP_TAG_STEM = "data/common/gamedata/map/map_name_tag"
local MAP_TAG_LIST = "m_mapNameTagConfigList"
local SETTINGS_GLOBAL = "Game.Settings"
local ORIGINAL_NAMES_FIELD = "GameSettings.CharacterNames"

local CHARA_TAGS = nil -- tag id -> { chara, override }
local MAP_TAGS = nil   -- tag id -> map_text id
local CHARAS = nil     -- chara id -> { name_text, short_name_text }

local function u32(v)
  if type(v) == "table" then v = v[1] end
  return math.floor(tonumber(v) or 0) % 4294967296
end

local function table_key(stem)
  local plain = stem .. ".cfg.bin"
  local ok, k = pcall(VRFW.table.keys, plain)
  if ok and type(k) == "table" and #k > 0 then return plain end
  return stem .. "_*.cfg.bin"
end

local function rows_of(stem, list, columns, what)
  local ok, rows = pcall(VRFW.table.raw, table_key(stem), list, columns)
  if not ok or type(rows) ~= "table" then
    warn(what .. " not readable: " .. tostring(rows))
    return {}
  end
  return rows
end

local function chara_tags()
  if CHARA_TAGS ~= nil then return CHARA_TAGS end
  CHARA_TAGS = {}
  for _, r in ipairs(rows_of(CHARA_TAG_STEM, CHARA_TAG_LIST, { 1, 2, 3 }, "chara_name_tag")) do
    local id = u32(r[1])
    if id ~= 0 then CHARA_TAGS[id] = { chara = u32(r[2]), override = u32(r[3]) } end
  end
  return CHARA_TAGS
end

local function map_tags()
  if MAP_TAGS ~= nil then return MAP_TAGS end
  MAP_TAGS = {}
  for _, r in ipairs(rows_of(MAP_TAG_STEM, MAP_TAG_LIST, { 1, 2 }, "map_name_tag")) do
    local id = u32(r[1])
    if id ~= 0 then MAP_TAGS[id] = u32(r[2]) end
  end
  return MAP_TAGS
end

local function charas()
  if CHARAS ~= nil then return CHARAS end
  CHARAS = {}
  local rows, at = Columns.read("character/chara_base", "CHARA_BASE_INFO", { "id", "name_text", "short_name_text" })
  if rows == nil then
    warn("chara_base names not readable: " .. tostring(at))
    return CHARAS
  end
  for _, r in ipairs(rows) do
    CHARAS[u32(r[at.id])] = { name_text = u32(r[at.name_text]), short_name_text = u32(r[at.short_name_text]) }
  end
  return CHARAS
end

function M.original_names()
  local okf, at = pcall(VRFW.game.field, ORIGINAL_NAMES_FIELD)
  local okg, getter = pcall(function() return VRFW.game[SETTINGS_GLOBAL] end)
  if not (okf and type(at) == "number") or not okg or type(getter) ~= "function" then return false end
  local oks, settings = pcall(getter)
  if not (oks and type(settings) == "number" and settings >= 0x10000) then return false end
  local okr, b = pcall(VRFW.mem.read, "u8", settings + at)
  return okr and type(b) == "number" and b ~= 0
end

-- one text of the character names the game loaded, nil when it has none
local function chara_text(id, lang)
  if id == 0 then return nil end
  local key = GameText.shown_key(lang, "chara_text")
  local tbl = (key == nil and M.original_names()) and "chara_text_roma" or "chara_text"
  local s = GameText.texts(tbl, lang, { id }, key)[id]
  return (s ~= nil and s ~= "") and s or nil
end

local function map_name(key, lang)
  local id = map_tags()[u32(VRFW.crc32(key))]
  if id == nil or id == 0 then return nil end
  local tbl = M.original_names() and "map_text_roma" or "map_text"
  local s = GameText.texts(tbl, lang, { id })[id]
  if (s == nil or s == "") and tbl ~= "map_text" then s = GameText.texts("map_text", lang, { id })[id] end
  return (s ~= nil and s ~= "") and s or nil
end

local function chara_name(prefix, key, lang)
  local t = chara_tags()[u32(VRFW.crc32(key))]
  if t == nil then return nil end
  local c = charas()[t.chara]
  local full = chara_text(t.override, lang) or (c and chara_text(c.name_text, lang))
  if full == nil then return nil end
  if prefix == "FUL" then return full end
  if prefix == "FST" then return full:match("^%S+") or full end
  if prefix == "LST" or prefix == "LAF" or prefix == "LFC" then return full:match("(%S+)%s*$") or full end
  return (t.override == 0 and c and chara_text(c.short_name_text, lang)) or full:match("^%S+") or full
end

-- one tag's name in `lang`, nil when the tag is unknown
local function tag_name(prefix, key, lang)
  if prefix == "MNT" then return map_name(key, lang) or chara_name(prefix, key, lang) end
  return chara_name(prefix, key, lang)
end

function M.expand(s, lang)
  if type(s) ~= "string" or not s:find("<", 1, true) then return s, false end
  local left = false
  local out = s:gsub("<(%u%u%u):([^>]+)>", function(prefix, key)
    local name = tag_name(prefix, key, lang)
    if name == nil then
      left = true
      return nil
    end
    return name
  end)
  return out, left
end

function M.clean(s, lang)
  local out, left = M.expand(s, lang)
  if type(out) ~= "string" then return "" end
  if left then out = out:gsub("%s*<%u%u%u:[^>]*>%s*", " ") end
  return (out:gsub("^%s+", ""):gsub("%s+$", ""))
end

return M
