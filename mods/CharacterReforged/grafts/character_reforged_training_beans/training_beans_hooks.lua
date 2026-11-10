-- window instead of the bean menu and ends like the retail one (board active, notices 7 and 8)
do
  CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
  CharacterReforged.training_beans = CharacterReforged.training_beans or {}
  local Beans = CharacterReforged.training_beans
  Beans.BEANS_OFF = 947107686
  Beans.TEXT_GET = 4074371074                       -- CMND_TEXT_GET (text id) -> the text in the game's language
  Beans.MESSAGE = 1655867507                        -- menu_text character_reforged_tr_beans_off (text\rows\training.toml)
  Beans.BOARD_MENU = 1810526795                     -- ability_learning_board_menu
  Beans.SET_MENU_ACTIVE = 1558704558                -- (menu, active): the retail coroutine's own switch
  Beans.BOARD_NOTICE = 1340085986
  Beans.NOTICE_SET_DONE = 7
  Beans.NOTICE_EFFECT_DONE = 8
  Beans.PLAY_SOUND = 1917805374
  Beans.SOUND_REFUSED = 2086672038
  Beans.WINDOW_BUSY = 898725220                     -- general window: still opening
  Beans.WINDOW_CLOSED = 682363669                   -- general window: closed
  Beans.WINDOW_WAIT = 600

  function Beans.off()
    local ok, off = pcall(funcLuaCommand, Beans.BEANS_OFF)
    return ok and off == true
  end

  function Beans.message_text()
    local ok, text = pcall(funcLuaCommand, Beans.TEXT_GET, Beans.MESSAGE)
    if ok and type(text) == "string" and text ~= "" then
      return text
    end
    return nil
  end

  -- Shows the no-effect message inside the board's coroutine 7.
  function Beans.show_no_effect()
    local text = Beans.message_text()
    funcLuaMenuCommand(Beans.SET_MENU_ACTIVE, Beans.BOARD_MENU, false)
    if text ~= nil and GENERAL_WINDOW ~= nil and GENERAL_WINDOW.ReserveGeneralWindow ~= nil then
      GENERAL_WINDOW.ReserveGeneralWindow("", "", "", text, 0, 0, 0, 0, 0, false)
      funcLuaCommand(Beans.PLAY_SOUND, Beans.SOUND_REFUSED)
      local frames = 0
      waitFalse(function()
        frames = frames + 1
        return funcLuaCommand(Beans.WINDOW_BUSY) and frames < Beans.WINDOW_WAIT
      end)
      waitTrue(function()
        frames = frames + 1
        return funcLuaCommand(Beans.WINDOW_CLOSED) or frames >= Beans.WINDOW_WAIT
      end)
    else
      funcLuaCommand(Beans.PLAY_SOUND, Beans.SOUND_REFUSED)
    end
    funcLuaMenuCommand(Beans.SET_MENU_ACTIVE, Beans.BOARD_MENU, true)
    funcLuaMenuCommand(Beans.BOARD_NOTICE, Beans.NOTICE_SET_DONE)
    funcLuaMenuCommand(Beans.BOARD_NOTICE, Beans.NOTICE_EFFECT_DONE)
  end

  -- Wraps the beans menu opener once per VM.
  if not Beans.wrapped and OpenBeansSetMenu_Coroutine ~= nil then
    local previous = OpenBeansSetMenu_Coroutine
    OpenBeansSetMenu_Coroutine = function(...)
      if not Beans.off() then
        return previous(...)
      end
      return Beans.show_no_effect()
    end
    Beans.wrapped = true
  end
end
