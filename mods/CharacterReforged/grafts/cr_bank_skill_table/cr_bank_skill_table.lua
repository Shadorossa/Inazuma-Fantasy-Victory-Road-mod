-- Character Reforged's declaration for the character bank's COMANDOS popup (docs/framework/bank-commands.md):
-- «Tabla de habilidades» opens the skill table (evt_skill_slot_menu) with the formation's equip parameters (the stale
-- «open the original board» request key evt_ss_open_board is deleted before and after). Declared in the framework's
-- registry VRFW_BankCommands; the mod that draws the popup asks it at call time. No engine call at load.
CharacterReforged = CharacterReforged or {}
CharacterReforged.BANK_SKILL_TABLE = {Menu = 1041963128 --[[evt_skill_slot_menu]], Params = "equip",
  Clear = {1881233917 --[[evt_ss_open_board]]}}
if type(VRFW_BankCommands) == "table" and type(VRFW_BankCommands.SetSkillTable) == "function" then
  VRFW_BankCommands.SetSkillTable("CharacterReforged", CharacterReforged.BANK_SKILL_TABLE)
end
