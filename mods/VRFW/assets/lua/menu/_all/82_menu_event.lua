-- Menu events between menus and mods: on, emit, off. Call only from OnInit, Step or another callback.
-- lua_patch.scope: used
VRFW.menu_event = VRFW.menu_event or {handlers = {}, owners = {}}
do
  local E = VRFW.menu_event
  --- Internal: command hashes of the menu event plugin (EVENT, ON, OFF).
  E.CMD = {EVENT = VRFW.commands.VRFW_MENU_EVENT, ON = VRFW.commands.VRFW_MENU_EVENT_ON,
    OFF = VRFW.commands.VRFW_MENU_EVENT_OFF}

  --- VRFW.menu_event.on(name, menu, owner, fn): runs fn when menu `menu` emits event `name`. Returns true when registered. Call only from OnInit, Step or another callback.
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

  --- VRFW.menu_event.off(owner): drops every event subscription of owner. Call only from OnInit, Step or another callback.
  function E.off(owner)
    E.owners[owner] = nil
    pcall(funcLuaCommand, E.CMD.OFF, owner)
  end

  --- VRFW.menu_event.emit(name, ...): sends a menu event. Returns how many listeners got it. Call only from OnInit, Step or another callback.
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
