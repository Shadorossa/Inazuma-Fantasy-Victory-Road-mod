-- VRFW_MATCH_EXIT in soccer_top_menu (Competición), the menu side of match_exit (lua\menu\_all\14_match_exit.lua).
-- After a match this hub opens first, then routes on by itself to the menu the match was started from: its background
-- layer's OnOpenLayer reads the game's return menu (3163201916) and runs MoveToVsCpuMenuCoroutine / OpenList (the
-- free-match list), MoveToVsMydockMenuCoroutine («Competir contra mis equipos») or RunManageCoroutine (online). Under
-- the cover those calls mark the hub as passed through: the menu they open lands (releases the cover). With no return
-- menu the hub itself is the landing: the cover is released once its background layer finished opening (the moment
-- the game's own code fades the hub in). The cover (bright-fade layer 1) is drawn under the hub's layers and the
-- game's layer-0 fade-in at the background's open end shows them: a hub routing on to the free-match list under the
-- cover is suspended right before that fade-in (as OpenList(true) does later), so only the list is ever seen.
-- Wraps global functions only; no engine call at load time.
do
  local X = VRFW_MATCH_EXIT
  if type(X) == "table" and not X.hub_wrapped then
    X.hub_wrapped = true
    X.manual = true
    local BACKGROUND = 367379312     -- the hub's background layer (its open end: the retail flag2, the hub is open)
    local HUB = 811496143            -- soccer_top_menu
    local SUSPEND_MENU, RESUME_MENU = 369172623, 66378409   -- these suspend and resume the menu: its layers stop and start drawing, and its coroutines keep running.
    local TO_LIST = { MoveToVsCpuMenuCoroutine = true, OpenList = true }   -- routes that end in OpenList(true)
    local route_name, hub_suspended, list_opened = nil, false, false

    for _, name in ipairs({ "MoveToVsCpuMenuCoroutine", "MoveToVsMydockMenuCoroutine", "OpenList", "RunManageCoroutine" }) do
      local f = rawget(_ENV, name)
      if type(f) == "function" then
        rawset(_ENV, name, function(...)
          if X.born and not X.done and not X.route then
            X.route = true
            route_name = name
            if type(X.log) == "function" then X.log("routes on (" .. name .. "): the next menu lands") end
          end
          if name == "OpenList" then list_opened = true end
          local r = table.pack(f(...))
          -- an invite ended the free-match route without the list: the hub is the menu, draw it again
          if name == "MoveToVsCpuMenuCoroutine" and hub_suspended and not list_opened then
            hub_suspended = false
            pcall(funcLuaMenuCommand, RESUME_MENU, HUB)
          end
          return table.unpack(r, 1, r.n)
        end)
      end
    end

    local open_end = rawget(_ENV, "OnOpenEndLayer")
    if type(open_end) == "function" then
      rawset(_ENV, "OnOpenEndLayer", function(a1, ...)
        if a1 == BACKGROUND and X.route and TO_LIST[route_name] and not hub_suspended and not list_opened then
          hub_suspended = true
          pcall(funcLuaMenuCommand, SUSPEND_MENU, HUB)
          if type(X.log) == "function" then X.log("hub suspended before its fade-in: the list is the first menu seen") end
        end
        local r = table.pack(open_end(a1, ...))
        if a1 == BACKGROUND and not X.route and type(X.land) == "function" then
          pcall(X.land, "hub open")
        end
        return table.unpack(r, 1, r.n)
      end)
    end
  end
end
