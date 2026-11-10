
CharacterReforged = CharacterReforged or {}
CharacterReforged.KeshinArmed = CharacterReforged.KeshinArmed or {}

local Id = VRFW.ids
local u32 = Id.unsigned

-- the chara_param of a character handle (0 = unknown)
local function card_of(handle)
  if handle == 0 then return 0 end
  local ok, record = pcall(VRFW.character.record, handle)
  if ok and type(record) == "table" and record.param then return u32(record.param) end
  return 0
end

function CharacterReforged.KeshinArmed.HyperArmour(chara_arg, keshin_arg)
  local chara, keshin = u32(chara_arg), u32(keshin_arg)
  if chara == 0 or keshin == 0 then return 0, 0 end
  local card = card_of(chara)
  if card == 0 then
    local owner = VRFW.character.copy_owner(chara)
    card = owner and card_of(owner) or 0
  end
  if card == 0 then return 0, 0 end
  local okspirit, spirit = pcall(VRFW.form.spirit_of, keshin)
  if okspirit and u32(spirit) ~= 0 then return 0, card end
  local okarmour, armour = pcall(VRFW.form.armour_for, keshin, card)
  armour = okarmour and u32(armour) or 0
  if armour == keshin then armour = 0 end
  return armour, card
end
