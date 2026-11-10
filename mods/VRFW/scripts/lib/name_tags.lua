local M = {}

local GameText = VRFW.names
local Columns = VRFW.table_files
local Memory = VRFW.memory
local _, warn = VRFW.logger("name_tags")

local CHARA_TAG_LIST = "m_charaNameTagConfigList"
local MAP_TAG_LIST = "m_mapNameTagConfigList"
local SETTINGS_GLOBAL = "Game.Settings"
local ORIGINAL_NAMES_FIELD = "GameSettings.CharacterNames"

local CHARA_TAGS = nil -- tag id -> { chara, override }
local MAP_TAGS = nil   -- tag id -> map_text id
local CHARAS = nil     -- chara id -> { name_text, short_name_text }

-- a cell's u32; a table cell holds it first
local function u32(v)
  if type(v) == "table" then v = v[1] end
  return VRFW.ids.unsigned(v)
end

local function rows_of(stem, list, columns, what)
  local ok, rows = pcall(VRFW.table.raw, Columns.file_name(stem), list, columns)
  if not ok or type(rows) ~= "table" then
    warn(what .. " not readable: " .. tostring(rows))
    return {}
  end
  return rows
end

local function chara_tags()
  if CHARA_TAGS ~= nil then return CHARA_TAGS end
  CHARA_TAGS = {}
  for _, r in ipairs(rows_of(Columns.CHARA_NAME_TAG, CHARA_TAG_LIST, { 1, 2, 3 }, "chara_name_tag")) do
    local id = u32(r[1])
    if id ~= 0 then CHARA_TAGS[id] = { chara = u32(r[2]), override = u32(r[3]) } end
  end
  return CHARA_TAGS
end

local function map_tags()
  if MAP_TAGS ~= nil then return MAP_TAGS end
  MAP_TAGS = {}
  for _, r in ipairs(rows_of(Columns.MAP_NAME_TAG, MAP_TAG_LIST, { 1, 2 }, "map_name_tag")) do
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

--- True when the original names option is on.
function M.original_names()
  local okf, at = pcall(VRFW.game.field, ORIGINAL_NAMES_FIELD)
  local settings = VRFW.game.global(SETTINGS_GLOBAL)
  if not (okf and type(at) == "number") or not settings then return false end
  local b = Memory.read("u8", settings + at)
  return b ~= nil and b ~= 0
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

--- Text `s` with its name tags filled in language `lang`: text, whether a tag was left.
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

--- Text `s` with its name tags filled and any left tag removed.
function M.clean(s, lang)
  local out, left = M.expand(s, lang)
  if type(out) ~= "string" then return "" end
  if left then out = out:gsub("%s*<%u%u%u:[^>]*>%s*", " ") end
  return VRFW.strings.trim(out)
end

return M
