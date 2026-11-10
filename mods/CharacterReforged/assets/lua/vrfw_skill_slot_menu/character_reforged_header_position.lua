-- This screen's header shows the player's own position (_all/character_reforged_header_position.lua).
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.header_position_wanted = true
if type(CharacterReforged.enable_header_position) == "function" then
  CharacterReforged.enable_header_position()
end
