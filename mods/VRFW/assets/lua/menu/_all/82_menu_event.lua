-- lua_patch.scope: used
VRFW.menu_event = VRFW.menu_event or {handlers = {}, owners = {}}
do
  local E = VRFW.menu_event
  E.CMD = {EVENT = VRFW.commands.VRFW_MENU_EVENT, ON = VRFW.commands.VRFW_MENU_EVENT_ON,
    OFF = VRFW.commands.VRFW_MENU_EVENT_OFF}

  --- Subscribes `owner` to menu event `name` from `menu`; answers true when it was registered.
  function E.on(name, menu, owner, fn)
    E.handlers[name] = fn
    E.owners[owner] = true
    local ok, r = pcall(funcLuaCommand, E.CMD.ON, name, menu, owner)
    if not E.finalize_wrapped then
      E.finalize_wrapped = true
      local game_finalize = FinalizeMenu
      --- Retail override: drops this menu's subscriptions, then finalizes.
      function FinalizeMenu(...)
        for o in pairs(E.owners) do
          VRFW.host.command(E.CMD.OFF, o)
        end
        E.owners = {}
        if type(game_finalize) == "function" then
          return game_finalize(...)
        end
      end
    end
    return ok and r == true
  end

  --- Drops the subscriptions of `owner`.
  function E.off(owner)
    E.owners[owner] = nil
    pcall(funcLuaCommand, E.CMD.OFF, owner)
  end

  --- Sends menu event `name`; answers how many listeners got it.
  function E.emit(name, ...)
    local n = VRFW.host.command(E.CMD.EVENT, name, ...)
    return tonumber(n) or 0
  end
end

--- Called by the framework in this script's state for an event it subscribed to.
function vrfw_menu_event_deliver(name, ...)
  local fn = VRFW.menu_event.handlers[name]
  if type(fn) == "function" then
    fn(...)
  end
end
