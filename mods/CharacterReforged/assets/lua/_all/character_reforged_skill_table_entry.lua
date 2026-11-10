CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.LOG_COMMAND = 519897777                                   -- crc32("CMND_VRFW_LOG"): the loader log
CharacterReforged.SKILL_TABLE_MENU = 2221030314                              -- vrfw_skill_slot_menu
CharacterReforged.ABILITY_BOARD_MENU = 1810526795                            -- ability_learning_board_menu

CharacterReforged.OPEN_MENU_COMMAND = 433545986        -- CMND_OPEN_MENU_OBJECT (funcLuaCommand)
CharacterReforged.MENU_EXISTS_COMMAND = 2231168902     -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
CharacterReforged.MENU_UNLOCKED_COMMAND = 347870658    -- is a menu unlocked (funcLuaCommand)

function CharacterReforged.install_board_open_redirect(entry_name, open_skill_table, after_close)
  if CharacterReforged.boardOpenRedirect ~= nil or type(funcLuaCommand) ~= "function"
      or type(funcLuaMenuCommand) ~= "function" then
    return false
  end
  local redirect = {entry = entry_name, waiting = false}
  CharacterReforged.boardOpenRedirect = redirect
  local board = CharacterReforged.ABILITY_BOARD_MENU
  local skill_table = CharacterReforged.SKILL_TABLE_MENU
  local command = funcLuaCommand
  local menu_command = funcLuaMenuCommand
  funcLuaCommand = function(...)
    local id, menu = ...
    if menu == board and select("#", ...) == 2 then
      if id == CharacterReforged.OPEN_MENU_COMMAND then
        pcall(command, CharacterReforged.LOG_COMMAND, "Character Reforged skill table entry", tostring(entry_name),
          "opens vrfw_skill_slot_menu")
        open_skill_table()
        redirect.waiting = true
        return command(CharacterReforged.OPEN_MENU_COMMAND, skill_table)
      elseif id == CharacterReforged.MENU_UNLOCKED_COMMAND then
        return true
      end
    end
    return command(...)
  end
  funcLuaMenuCommand = function(...)
    local id, menu = ...
    if redirect.waiting and id == CharacterReforged.MENU_EXISTS_COMMAND and menu == board
        and select("#", ...) == 2 then
      local exists = menu_command(CharacterReforged.MENU_EXISTS_COMMAND, skill_table)
      if not exists then
        redirect.waiting = false
        if after_close ~= nil then
          after_close()
        end
      end
      return exists
    end
    return menu_command(...)
  end
  return true
end
