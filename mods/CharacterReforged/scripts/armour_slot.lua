
CharacterReforged = CharacterReforged or {}

local RULES = nil

local Id = VRFW.ids
local hex = Id.hex_text

local function rules()
  if RULES then return RULES end
  RULES = { armour_without_item = false, from = nil }
  local ok, decl = pcall(VRFW.files.declarations, "content/skill_board")
  for _, f in ipairs(ok and type(decl) == "table" and decl or {}) do
    local d = type(f) == "table" and f.data or nil
    local t = type(d) == "table" and type(d.CharacterReforged) == "table" and d.CharacterReforged.SkillBoard or nil
    if type(t) == "table" and t.armour_without_item ~= nil then
      RULES.armour_without_item = t.armour_without_item == true
      RULES.from = tostring(f.mod or "?")
    end
  end
  VRFW.log(string.format("armour_slot: armour slot without the item %s (%s)",
    RULES.armour_without_item and "on" or "off",
    RULES.from and ("declared by " .. RULES.from) or "no active mod declares [CharacterReforged.SkillBoard] armour_without_item: the game's rule"))
  return RULES
end

local BUF_ARMED, BUF_ADD

local function u32_at(p) return VRFW.memory.read("u32", p) or 0 end

VRFW.on("hook:CharacterReforged.ArmedSlotItem:post", function(ev)
  if not rules().armour_without_item then
    return nil
  end
  local out, keshin_p, card_p, flag = ev.args[1], ev.args[2], ev.args[3], ev.args[4]
  if u32_at(out) ~= 0 then
    return nil -- the player owns a copy: the game's rule
  end
  BUF_ARMED = BUF_ARMED or VRFW.memory.buffer("character_reforged_armed_of_card", 16)
  BUF_ADD = BUF_ADD or VRFW.memory.buffer("character_reforged_item_add", 64)
  VRFW.memory.write("u32", BUF_ARMED, 0)
  if not pcall(VRFW.call, "CharacterReforged.AuraChangeOfCard", BUF_ARMED, keshin_p, card_p) then
    return nil
  end
  local armed = u32_at(BUF_ARMED)
  if armed == 0 then
    return nil -- no armour for this keshin and card: the game's rule
  end
  local ok, err = pcall(VRFW.call, "CharacterReforged.ItemAdd", BUF_ADD, armed, 1, 0)
  if not ok then
    VRFW.warn("armour_slot: armour item " .. hex(armed) .. " not added: " .. tostring(err))
    return nil
  end
  pcall(VRFW.call, "CharacterReforged.ArmedItemHandle", out, keshin_p, card_p, flag or 1)
  VRFW.log(string.format("armour_slot: armour slot of keshin %s (card %s): no copy of armour %s owned, one added -> handle %s",
    hex(u32_at(keshin_p)), hex(u32_at(card_p)), hex(armed), hex(u32_at(out))))
  return nil
end)
