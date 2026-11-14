-- Persons, menu side: the versions of a character (VRFW.persons) for the menu Lua (CMND_VRFW_PERSON_VERSIONS).

PersonCommands = PersonCommands or {}

--- Every version of character `chara` (chara_base ids; { chara } when he has no other).
function PersonCommands.Versions(chara)
  return VRFW.persons.versions(chara)
end
