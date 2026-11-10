-- lua_patch.scope: used
if VRFW.team_dock == nil then
  local TD = { owners = {}, listeners = {} }
  VRFW.team_dock = TD

  --- Claims the team dock for `owner`; `rule` (optional function) decides when the claim applies.
  function TD.claim(owner, rule)
    TD.owners[owner] = type(rule) == "function" and rule or true
  end

  --- Drops the claim of `owner`.
  function TD.release(owner)
    TD.owners[owner] = nil
  end

  --- The first owner whose claim applies; nil when there is none.
  function TD.owner()
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

  --- True when some owner's claim applies.
  function TD.is_owned()
    return TD.owner() ~= nil
  end

  --- The dock shows the online squad (online friendly lobby).
  function TD.online()
    if (VRFW.prematch ~= nil and VRFW.prematch.online ~= nil) then
      local ok, r = pcall(VRFW.prematch.online)
      return ok and r == true
    end
    return funcLuaCommand(3959907440) == true or funcLuaCommand(1191545622) == true
  end

  --- Adds fn as listener `name` of `event`; a second one with the same name replaces it.
  function TD.on(event, name, fn)
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

  local logger
  local function report_failure(event, name, err)
    logger = logger or VRFW.logger.new("VRFW.team_dock")
    logger(event .. " listener " .. tostring(name) .. " failed: " .. tostring(err))
  end

  --- Calls every listener of `event` under pcall.
  function TD.emit(event, ...)
    for _, l in ipairs(TD.listeners[event] or {}) do
      local ok, err = pcall(l.fn, ...)
      if not ok then
        report_failure(event, l.name, err)
      end
    end
  end

  --- The first non-nil answer of the event's listeners.
  function TD.ask(event, ...)
    for _, l in ipairs(TD.listeners[event] or {}) do
      local ok, answer = pcall(l.fn, ...)
      if not ok then
        report_failure(event, l.name, answer)
      elseif answer ~= nil then
        return answer
      end
    end
    return nil
  end

  -- Runs the registrations of the lua_early mods' `_all` files, which load before this file.
  local queue = rawget(VRFW, "team_dock_queue")
  rawset(VRFW, "team_dock_queue", nil)
  if type(queue) == "table" then
    for _, register in ipairs(queue) do
      local ok, err = pcall(register, TD)
      if not ok then
        report_failure("queued registration", "team_dock_queue", err)
      end
    end
  end
end
