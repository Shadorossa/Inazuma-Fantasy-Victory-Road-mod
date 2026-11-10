-- VRFW faces (docs/framework/chara-index.md §2): whether a character has a face icon of its own.
local M = {}

local FACE_FILE = "data/dx11/menu/200_icon/10_icon_chr/face/%s_l.g4tx"
local HAS = {}         -- internal name -> true / false
local NAMES = {}       -- character id -> internal name, false when it has none

local u32 = VRFW.ids.unsigned

--- an internal name -> true = a face icon of its own, false = none (the default face), nil = cannot tell
function M.of_name(name)
  if type(name) ~= "string" or name == "" then return nil end
  local has = HAS[name]
  if has ~= nil then return has end
  if type(VRFW.files) ~= "table" or type(VRFW.files.game_file) ~= "function" then return nil end
  local ok, key, why = pcall(VRFW.files.game_file, string.format(FACE_FILE, name))
  if not ok or (key == nil and why == "no host") then return nil end
  has = key ~= nil or VRFW.files.game_exists(string.format(FACE_FILE, name)) == true
  HAS[name] = has
  return has
end

--- a character (chara_base id) -> as of_name of its internal name
function M.of_character(base)
  base = u32(base)
  local name = NAMES[base]
  if name == nil then
    local ok, ch = pcall(VRFW.character.character, base)
    name = ok and type(ch) == "table" and type(ch.name) == "string" and ch.name ~= "" and ch.name or false
    NAMES[base] = name
  end
  if not name then return nil end
  return M.of_name(name)
end

--- a card (chara_param id) -> as of_character of its character
function M.of_card(card)
  local ok, base = pcall(VRFW.character.base_of, u32(card))
  if not ok or type(base) ~= "number" then return nil end
  return M.of_character(base)
end

return M
