-- menu_engine: VRFW_TeamDock, the shared state of the team dock (soccer_team_dock_menu, docs/framework/team-dock.md).
-- A mode with its own squad screen claims the dock; mods that add pages or rows to the dock stay off while it is
-- claimed. Mods that change the shown dock page tell the others through events. Definitions only; no engine call at load.
if VRFW_TeamDock == nil then
  -- EVT_DOCK_OWNERS is the former name of the owners table: kept as the same table so old registrations still count
  EVT_DOCK_OWNERS = type(EVT_DOCK_OWNERS) == "table" and EVT_DOCK_OWNERS or {}
  local TD = { owners = EVT_DOCK_OWNERS, listeners = {} }
  VRFW_TeamDock = TD

  -- a mode claims the dock; rule = function returning true while it owns the dock (nil = owned until Release)
  function TD.Claim(owner, rule)
    TD.owners[owner] = type(rule) == "function" and rule or true
  end

  function TD.Release(owner)
    TD.owners[owner] = nil
  end

  -- the name of the mode that owns the dock now, nil when none
  function TD.Owner()
    for owner, rule in pairs(TD.owners) do
      if rule == true then
        return owner
      elseif type(rule) == "function" then
        local ok, yes = pcall(rule)
        if ok and yes == true then
          return owner
        end
      end
    end
    return nil
  end

  function TD.IsOwned()
    return TD.Owner() ~= nil
  end

  -- the dock shows the online squad (online friendly lobby)
  function TD.Online()
    if EVT_PmOnline ~= nil then
      local ok, r = pcall(EVT_PmOnline)
      return ok and r == true
    end
    return funcLuaCommand(3959907440) == true or funcLuaCommand(1191545622) == true
  end

  -- listen to a dock event: "page_changing" / "page_changed" (a mod mounted another page of docks), "header" (the
  -- screen title was written again), "docks_changed" (a mod edited docks while the dock was closing); name = the listener's id (registering again replaces it)
  function TD.On(event, name, fn)
    local list = TD.listeners[event] or {}
    TD.listeners[event] = list
    for _, l in ipairs(list) do
      if l.name == name then
        l.fn = fn
        return
      end
    end
    list[#list + 1] = { name = name, fn = fn }
  end

  -- send a dock event to its listeners (each one protected: an error is logged, the others still run)
  function TD.Emit(event, ...)
    for _, l in ipairs(TD.listeners[event] or {}) do
      local ok, err = pcall(l.fn, ...)
      if not ok then
        pcall(funcLuaCommand, VRFW_Cmd and VRFW_Cmd.EVT_LOG or 3661580131, "VRFW.team_dock",
          event .. " listener " .. tostring(l.name) .. " failed: " .. tostring(err))
      end
    end
  end
end
