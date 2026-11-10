CharacterReforged = CharacterReforged or {}
CharacterReforged.BANK_SKILL_TABLE = {Menu = 2221030314 --[[vrfw_skill_slot_menu]], Params = "equip",
  Clear = {3646488081 --[[vrfw_ss_open_board]]}}
if type(VRFW.bank_commands) == "table" and type(VRFW.bank_commands.set_skill_table) == "function" then
  VRFW.bank_commands.set_skill_table("CharacterReforged", CharacterReforged.BANK_SKILL_TABLE)
end
