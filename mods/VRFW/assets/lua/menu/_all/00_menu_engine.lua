VRFW = VRFW or {}

if VRFW.menu == nil then
  local H = { COUNT = 1063911870, ENTRY = 2768609349, HIDDEN = 3842910571 }

  --- Advanced: Table of the menu engine; holds the host table H and the menu entry helpers.
  VRFW.menu = { H = H }

  --- Advanced: The menu entries registered for `host`; an empty table when there are none.
  function VRFW.menu.entries(host)
    local out = {}
    local n = VRFW.host.command(H.COUNT, host)
    if type(n) ~= "number" then return out end
    for i = 1, n do
      local key, text, icon, kind, value, owner, value_id, menus = funcLuaCommand(H.ENTRY, host, i)
      if key ~= nil then
        out[#out + 1] = { key = key, text = text, icon = icon, kind = kind, value = value, owner = owner, value_id = value_id,
                          menus = menus }
      end
    end
    return out
  end

  --- Internal: True when entry `key` of `host` is hidden.
  function VRFW.menu.hidden(host, key)
    local h = VRFW.host.command(H.HIDDEN, host, key)
    return h == true
  end

  --- Internal: Runs a menu entry (a Lua global or a menu to open); answers true when it ran, false otherwise.
  function VRFW.menu.run(e, open_menu)
    if e == nil then return false end
    if e.kind == "lua" then
      local f = _G                               -- e.value: a global function or a dotted path (VRFW.x.y)
      for part in tostring(e.value):gmatch("[^.]+") do
        f = type(f) == "table" and f[part] or nil
      end
      if type(f) == "function" then f(e) return true end
    elseif e.kind == "command" then
      funcLuaCommand(e.value_id)
      return true
    elseif e.kind == "open_menu" and type(open_menu) == "function" then
      open_menu(e.value)
      return true
    end
    return false
  end
end
