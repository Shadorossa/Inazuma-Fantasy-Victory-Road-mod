-- Character Reforged: every «Tabla de habilidades» entry opens the skill table evt_skill_slot_menu (6 special moves +
-- the aura slot + the mix slot); the game's own ability board is never opened.
-- One mechanism for every entry, in every menu VM (this file is in `_all`):
--   * the team dock's player popup «PERSONAJE» (graft ss2_dock, a hook file since 1.7.9): Character Reforged does not
--     touch the popup; its retail «Tabla de habilidades» branch opens the board with CMND_OPEN_MENU_OBJECT, and
--     CharacterReforged.InstallBoardOpenRedirect (below) turns that open into the skill table at the target (and the
--     retail wait for the board into a wait for the skill table);
--   * the story field dock team_dock_menu_rpg_battle and the scout screen rpg_select_scout_chara_menu (graft
--     board_entry: their retail open functions ExecAbilityBoardMenu / OpenAbilityLearningBoard);
--   * Utilities' Banco COMANDOS popup (graft cr_bank_skill_table).
-- Definitions only, no engine call at load.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.LOG_COMMAND = 3661580131                                   -- crc32("CMND_EVT_LOG"): the loader log
CharacterReforged.SKILL_TABLE_MENU = 1041963128                              -- evt_skill_slot_menu
CharacterReforged.ABILITY_BOARD_MENU = 1810526795                            -- ability_learning_board_menu

-- ---- the open target ------------------------------------------------------------------------------------------------
-- A screen whose retail code opens the ability board itself (funcLuaCommand(CMND_OPEN_MENU_OBJECT,
-- ability_learning_board_menu), then waits while funcLuaMenuCommand(CMND_IS_EXIST_MENU_OBJECT, the board) is true):
-- once per VM (from the screen's own OnInit handler: funcLuaCommand exists only then), the two commands are wrapped so
--   * the open of the board (one log line per use) runs open_skill_table() (the screen's parameters for
--     evt_skill_slot_menu) and opens the skill table instead;
--   * the retail wait for the board waits for the skill table; when it is gone, after_close() runs once;
--   * «is the board unlocked» (command 347870658 with the board) answers true, so the retail code does not grey the
--     entry out before the board is unlocked.
-- Every other call passes through unchanged.
CharacterReforged.OPEN_MENU_COMMAND = 433545986        -- CMND_OPEN_MENU_OBJECT (funcLuaCommand)
CharacterReforged.MENU_EXISTS_COMMAND = 2231168902     -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
CharacterReforged.MENU_UNLOCKED_COMMAND = 347870658    -- is a menu unlocked (funcLuaCommand)

function CharacterReforged.InstallBoardOpenRedirect(entry_name, open_skill_table, after_close)
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
          "opens evt_skill_slot_menu")
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
