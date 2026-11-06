-- Classic Equipment › the Suerte of the classic items a player wears, for Character Reforged's player page
-- (content\menus\player_page_slots.toml, host CharacterReforged.page_luck_bonus). Data: every active mod's
-- content\classic_equipment\luck.toml (per item: Suerte as a fraction of S, the item type's VRFW.item.equipment_scale).
-- Read once; computed only when the page asks.

ClassicEquipment = ClassicEquipment or {}

require "VRFW/lib/basics"

local TWO32 = 4294967296
local LUCK = nil   -- { [item id] = fraction of S }

local function id_of(key)
  local f = VRFW.crc32 or (VRFW.ui and VRFW.ui.crc32)
  return f(key) % TWO32
end

local function load()
  if LUCK then return LUCK end
  LUCK = {}
  local ok, files = pcall(VRFW.files.declarations, "content/classic_equipment/luck.toml")
  for _, f in ipairs((ok and files) or {}) do
    for _, e in ipairs((f.data or {}).item or {}) do
      if type(e.item) == "string" and type(e.luck) == "number" then LUCK[id_of(e.item)] = e.luck end
    end
  end
  return LUCK
end

-- CMND_CLASSICEQUIPMENT_LUCK(charaStHdl) -> the Suerte of the classic items he wears (0 = none or unknown)
function ClassicEquipment.Luck(hdl)
  local luck = load()
  local ok, a, b, c, d = pcall(VRFW.item.equipped, tonumber(hdl) or 0)
  if not ok or a == nil then return 0 end
  local okS, s = pcall(VRFW.item.equipment_scale)
  if not okS or type(s) ~= "number" then return 0 end
  local sum = 0
  for _, id in ipairs({ a, b, c, d }) do
    local frac = id and luck[id % TWO32]
    if frac then sum = sum + frac end
  end
  return math.floor(sum * s + 0.5)
end
