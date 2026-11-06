-- Character Reforged: this screen's player header shows the player's OWN position (see _all/character_reforged_header_position.lua).
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.HeaderPositionWanted = true
if type(CharacterReforged.EnableHeaderPosition) == "function" then
  CharacterReforged.EnableHeaderPosition()
end
