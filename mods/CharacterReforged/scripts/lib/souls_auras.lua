
local M = {}


local rows = {}     -- id -> { key, type, move, element }
local by_key = {}   -- key -> id
local loaded = false

local Id = VRFW.ids
local u32 = Id.unsigned

function M.load()
  if loaded then return true end
  loaded = true
  local ok, list = pcall(VRFW.table.raw, VRFW.table_files.file_name(VRFW.table_files.AURA_SKILL_CONFIG), "AURA_CMD_INFO", { 1, 2, 7, 9, 11 })
  if not ok or type(list) ~= "table" then
    VRFW.warn("CharacterReforged auras: no aura_skill_config: " .. tostring(list))
    return false
  end
  for _, r in ipairs(list) do
    if type(r[1]) == "number" then
      local id = u32(r[1])
      local key = tostring(r[2] or "")
      -- VRFW.table.raw keys each row by the asked column positions (r[7], not r[3])
      rows[id] = { key = key, type = tonumber(r[11]) or 255, move = u32(r[7]), element = tonumber(r[9]) or 0 }
      if key ~= "" then by_key[key] = id end
    end
  end
  return true
end

function M.type(id)
  local r = rows[id or 0]
  return r and r.type or nil
end

function M.key(id)
  local r = rows[id or 0]
  if r and r.key ~= "" then return r.key end
  return Id.hex_text(id)
end

-- an aura key of the table, else a mod aura <mod>.<name> through the framework's names
function M.id(key)
  if by_key[key] then return by_key[key] end
  local ok, id = pcall(VRFW.technique, key)
  if ok and type(id) == "number" and rows[u32(id)] then return u32(id) end
  return nil
end

function M.move(id)
  local r = rows[id or 0]
  return r and r.move or 0
end

function M.element(id)
  local r = rows[id or 0]
  return r and r.element or 0
end

return M
