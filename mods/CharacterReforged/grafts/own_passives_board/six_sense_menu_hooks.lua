do
  CharacterReforged_SixSenseMenu = CharacterReforged_SixSenseMenu or {}
  local Menu = CharacterReforged_SixSenseMenu
  Menu.EQUIP = 4067673008
  Menu.SOUND = 1917805374                             -- play a system sound
  Menu.SOUND_CANNOT = 2086672038

  VRFW.host.wrap("OnFunction", function(previous)
    return function(a1, ...)
      if a1 == Menu.EQUIP then
        pcall(funcLuaCommand, Menu.SOUND, Menu.SOUND_CANNOT)
        return
      end
      return previous(a1, ...)
    end
  end)
end
