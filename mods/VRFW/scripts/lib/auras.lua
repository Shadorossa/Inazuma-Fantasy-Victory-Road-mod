-- The aura commands the game loads (the served aura_skill_config: the game's rows and every mod's), read once per
-- script VM: type, key, own move, aura character, cost; the keshin an armour pays from; the spirit moves. Derived from
-- the game's table, no built-in list.
--   local Auras = require "VRFW/lib/auras"     -- any mod's scripts (the framework's own: require "lib/auras")
--   Auras.load()                  -> true once the table was read (later calls answer true without reading again)
--   Auras.type(id)                -> auraType: 0 keshin, 1 armour, 2 miximax, 3 totem, ... (nil = not an aura command)
--   Auras.key(id)                 -> the row's key, else "0x%08X" of id
--   Auras.row(id)                 -> { key, type, move, chara, cost } of an aura command, nil when it is none
--   Auras.ids()                   -> every aura id, in table order
--   Auras.spirit(armour)          -> the keshin of an armour (the framework's transform pairs first, else the first keshin
--                                    of the same aura character)
--   Auras.armours_of(keshin)      -> the armour ids of a keshin (the aura character pairing)
--   Auras.aura_move(id)           -> the aura's own move («change skill»), else (armour forms) its keshin's; 0 = none
--   Auras.is_spirit_move(id, with_armours) -> true for the own move of a keshin / totem / mode-change aura; with
--                                    `with_armours` an armour's own move counts too. A move that is also a miximax's own
--                                    move never counts.
--   Auras.spirit_moves(with_armours) -> the set { [move] = true } is_spirit_move answers from
-- Requiring it also sets VRFW.auras to the same table in that script's VM.
local Id = require "VRFW/lib/ids"
local u32 = Id.u32

local KEY = "data/common/gamedata/skill/aura_skill_config_*.cfg.bin"
local KESHIN, ARMOUR, MIXIMAX = 0, 1, 2

local M = {}

local rows = {}        -- id -> { key, type, move, chara, cost }
local ids = {}         -- aura ids in table order
local spirit_of = {}   -- armour id -> its keshin id (same aura character, the first keshin in table order)
local armours = {}     -- keshin id -> { armour ids } (the reverse of spirit_of)
local spirit_moves = { [false] = {}, [true] = {} }
local loaded = false

function M.load()
  if loaded then
    return true
  end
  loaded = true
  -- col 0 id, 1 key, 4 cost, 6 own move («change skill»), 7 aura character, 10 auraType
  local ok, list = pcall(VRFW.table.raw, KEY, "AURA_CMD_INFO", { 1, 2, 5, 7, 8, 11 })
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

function M.row(id)
  return rows[id]
end

function M.ids()
  return ids
end

function M.type(id)
  local r = rows[id or 0]
  return r and r.type or nil
end

function M.key(id)
  local r = rows[id or 0]
  if r and r.key ~= "" then
    return r.key
  end
  return string.format("0x%08X", id or 0)
end

function M.spirit(armour)
  if VRFW.form and VRFW.form.spirit_of then
    local ok, s = pcall(VRFW.form.spirit_of, armour)
    if ok and type(s) == "number" and s ~= 0 then
      return s
    end
  end
  return spirit_of[armour]
end

function M.armours_of(keshin)
  return armours[keshin] or {}
end

function M.spirit_moves(with_armours)
  return spirit_moves[with_armours == true]
end

function M.is_spirit_move(id, with_armours)
  return id ~= nil and id ~= 0 and spirit_moves[with_armours == true][id] == true
end

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

if type(VRFW) == "table" and rawget(VRFW, "auras") == nil then
  pcall(rawset, VRFW, "auras", M)
end

return M
