-- lua_patch.scope: used
VRFW.reset = VRFW.reset or {}
do
  local R = VRFW.reset
  local C = {
    SAVE_WORKING = 1979970074,   -- a save / load job runs
    CARRY = VRFW.commands.VRFW_SLOT_CARRY,
    STRAIGHT = VRFW.commands.VRFW_MENU_TOPBAR_DIRECT,
    GAME_RESET = VRFW.commands.GAME_RESET,             -- CMND_GAME_RESET
    BGM_STOP = VRFW.commands.BGM_STOP,                 -- CMND_BGM_STOP
    NEXT_MENU = 3479138216,      -- (funcLuaMenuCommand) the root menu of the next state
    NO_PRESS_START = 937976662,
    VS_NEXT = 419468738, VS_NEXT2 = 1507811093,
    TITLE_MODE = 3718253404,     -- the title's mode value
  }

  --- Sets the menu that opens after a reset (`vs` = the VS root) and skips the press-start screen.
  function R.next_state(menu, vs, title_mode)
    if type(menu) == "string" then menu = VRFW.crc32(menu) end
    pcall(funcLuaMenuCommand, C.NEXT_MENU, vs and 0 or (menu or 0))
    pcall(funcLuaCommand, C.NO_PRESS_START, true)
    pcall(funcLuaCommand, C.VS_NEXT, vs == true)
    pcall(funcLuaCommand, C.VS_NEXT2, vs == true)
    if title_mode ~= nil then pcall(funcLuaCommand, C.TITLE_MODE, title_mode) end
  end

  --- Waits at most 300 frames for the game to finish saving; answers true when it had to wait.
  function R.wait_save()
    local waited = false
    for _ = 1, 300 do
      local busy = VRFW.host.command(C.SAVE_WORKING)
      if busy ~= true then break end
      waited = true
      coroutine.yield()
    end
    return waited
  end

  --- Restarts the game into a menu without the title screen; answers "straight", or "title" when it fell back to the title.
  function R.straight(spec)
    spec = spec or {}
    local log = type(spec.log) == "function" and spec.log or function() end
    R.wait_save()
    local okc, kept, kib, play, players, why = pcall(funcLuaCommand, C.CARRY, 1)
    kept = okc and kept == true
    if kept then
      log("game kept in memory: " .. tostring(kib) .. " KiB, play " .. tostring(play) .. " s, " .. tostring(players) .. " players")
    else
      log("no carry (" .. tostring(okc and why or kept) .. ")")
      if spec.need_carry then return "refused" end
    end
    if spec.bgm_stop then pcall(funcLuaCommand, C.BGM_STOP, 2) end
    if spec.menu ~= nil or spec.vs then
      R.next_state(spec.menu, spec.vs, spec.title_mode)
    elseif not kept then
      pcall(funcLuaCommand, C.NO_PRESS_START, true)
    end
    pcall(funcLuaCommand, C.GAME_RESET)
    if not kept then return "title" end
    local okd, r = pcall(funcLuaCommand, C.STRAIGHT)
    if okd and r == true then
      pcall(funcLuaCommand, VRFW.commands.VRFW_RESET_STRAIGHT, tostring(spec.menu or (spec.vs and "the VS menu") or "the next state"))
      log("straight reset: the new rpg scene opens the next state (no title)")
      return "straight"
    end
    pcall(funcLuaCommand, C.CARRY, 0)
    log("straight reset refused (" .. tostring(r) .. "): the title after the reset")
    return "title"
  end

  --- Resets the game to the title screen.
  function R.to_title()
    R.next_state(0, false)
    pcall(funcLuaCommand, C.GAME_RESET)
  end
end
