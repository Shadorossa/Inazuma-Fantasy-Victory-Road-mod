--- Advanced: Library: aura skill rows of aura_skill_config (spirit, armour, miximax moves).
local Id = VRFW.ids
local u32 = Id.unsigned

local STEM = "data/common/gamedata/skill/aura_skill_config"
local KESHIN, ARMOUR, MIXIMAX = 0, 1, 2

local M = {}

local rows = {}        -- id -> { key, type, move, chara, cost }
local ids = {}         -- aura ids in table order
local spirit_of = {}
local armours = {}     -- keshin id -> { armour ids } (the reverse of spirit_of)
local spirit_moves = { [false] = {}, [true] = {} }
local loaded = false

--- Advanced: Reads the aura tables once; true when they are available.
function M.load()
  if loaded then
    return true
  end
  loaded = true
  -- col 0 id, 1 key, 4 cost, 6 own move ("change skill"), 7 aura character, 10 auraType
  local ok, list = pcall(VRFW.table.raw, VRFW.table_files.file_name(STEM), "AURA_CMD_INFO", { 1, 2, 5, 7, 8, 11 })
  if not ok or type(list) ~= "table" then
    VRFW.warn("auras: no aura_skill_config: " .. tostring(list))
    return false
  end
  local first_keshin = {}
  for _, r in ipairs(list) do
    if type(r[1]) == "number" then
      local id = u32(r[1])
      local row = { key = tostring(r[2] or ""), type = tonumber(r[11]) or 255, move = u32(r[7]), chara = u32(r[8]),
                    cost = tonumber(r[5]) or 0 }
      rows[id] = row
      ids[#ids + 1] = id
      if row.type == KESHIN and row.chara ~= 0 and not first_keshin[row.chara] then
        first_keshin[row.chara] = id
      end
    end
  end
  local miximax_moves = {}
  for _, id in ipairs(ids) do
    local r = rows[id]
    if r.type == ARMOUR and r.chara ~= 0 then
      spirit_of[id] = first_keshin[r.chara]
      if spirit_of[id] then
        armours[spirit_of[id]] = armours[spirit_of[id]] or {}
        table.insert(armours[spirit_of[id]], id)
      end
    end
    if r.type == MIXIMAX and r.move ~= 0 then
      miximax_moves[r.move] = true
    end
  end
  for _, id in ipairs(ids) do
    local r = rows[id]
    if r.type ~= MIXIMAX and r.move ~= 0 and not miximax_moves[r.move] then
      spirit_moves[true][r.move] = true
      if r.type ~= ARMOUR then
        spirit_moves[false][r.move] = true
      end
    end
  end
  return true
end

--- Advanced: The aura table row of move `id`; nil when it has none.
function M.row(id)
  return rows[id]
end

--- Advanced: Every move id of the aura table, as an array.
function M.ids()
  return ids
end

--- Advanced: The aura type of move `id`; nil when it has none.
function M.type(id)
  local r = rows[id or 0]
  return r and r.type or nil
end

--- Internal: The text key of move `id`.
function M.key(id)
  local r = rows[id or 0]
  if r and r.key ~= "" then
    return r.key
  end
  return string.format("0x%08X", id or 0)
end

--- Internal: The spirit that armour `armour` belongs to.
function M.spirit(armour)
  if VRFW.form and VRFW.form.spirit_of then
    local ok, s = pcall(VRFW.form.spirit_of, armour)
    if ok and type(s) == "number" and s ~= 0 then
      return s
    end
  end
  return spirit_of[armour]
end

--- Advanced: The armours of keshin `keshin`, as an array.
function M.armours_of(keshin)
  return armours[keshin] or {}
end

--- Advanced: The set of spirit moves (with armour moves when `with_armours` is true).
function M.spirit_moves(with_armours)
  return spirit_moves[with_armours == true]
end

--- Advanced: True when move `id` is a spirit move.
function M.is_spirit_move(id, with_armours)
  return id ~= nil and id ~= 0 and spirit_moves[with_armours == true][id] == true
end

--- Internal: The aura move row of move `id`; nil when it is none.
function M.aura_move(id)
  local r = rows[id or 0]
  if not r then
    return 0
  end
  if r.move ~= 0 then
    return r.move
  end
  local k = M.spirit(id)
  return (k and rows[k] and rows[k].move) or 0
end

return M
