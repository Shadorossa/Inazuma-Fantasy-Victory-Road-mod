-- lua_patch.scope: used
-- VRFW.free_match_lock: the retail lock rule of a free-match class, read by the list menu and by the class menu.
if VRFW.free_match_lock == nil then
  local L = {}

  --- Internal: True when class index c (0..3) of opponent `game` is locked by the retail rule.
  function L.retail_locked(game, story, c)
    local flag = true
    local ret, ret2 = funcLuaMenuCommand(1984141647, game, c + 6)
    if not ret then
      ret2 = -1
    end
    if ret2 == -1 then
      if story == 1 then
        if game == 281360633 --[[fbtl_free_001]] then
          flag = false
        else
          local ok, sfi = funcLuaCommand(2610596259, game)
          if ok then
            flag = not funcLuaCommand(VRFW.commands.GET_CHRONICLE_CLEAR_STATUS, sfi, c + 1)
          end
          local ok2, ev = funcLuaCommand(2610596259, game, 1)
          if ok2 and ev > 0 then
            flag = false
          end
        end
      else
        flag = false
      end
    elseif ret2 == 0 then
      flag = false
    end
    return flag
  end

  --- Internal: Namespace of the free match lock helpers.
  VRFW.free_match_lock = L
end
