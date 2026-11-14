-- lua_patch.scope: used
-- audio_engine (VRFW, sound type): the menu music swap, VRFW.menu_music.
if VRFW.menu_music == nil then
  local M = {
    EXEC = 3048355248,   -- CMND_EXEC_CRAFT_OBJ_ID (retail: plays a bgm_config id)
    ASK = 568638161,
  }
  --- Advanced: Namespace of the menu music helpers.
  VRFW.menu_music = M

  -- the arguments go on as the caller gave them (a C command counts them: no extra nil for a call without one)
  local function swap(nxt, ...)
    local cmd, a = ...
    if type(a) == "number" then
      local v = VRFW.host.command(M.ASK, a)
      if type(v) == "number" and v ~= 0 then
        return nxt(cmd, v, select(3, ...))
      end
    end
    return nxt(...)
  end

  -- Advanced: the VM's funcLuaCommand with the swap (idempotent: one handler per VM)
  function M.install()
    return VRFW.host.hook_command(M.EXEC, swap, "VRFW.menu_music")
  end

  -- Internal: watch the menu script of this VM: the swap goes in at its OnInit (the engine's first callback)
  function M.watch()
    local prev = OnInit
    OnInit = function(...)
      M.install()
      if prev ~= nil then
        return prev(...)
      end
    end
    return true
  end
end
