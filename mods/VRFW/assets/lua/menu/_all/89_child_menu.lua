if VRFW.child_menu == nil then
  local ChildMenu = {}

  local CROSS_CALL = 830228314    -- (menu, function name, ...): a function of another menu's Lua
  local REVIVE_STEPS = 30
  local CLOSE_RETRY_STEPS = 30
  local CLOSE_RETRIES = 10        -- at most this many close requests of a closing child

  local function crc(s)
    return type(s) == "number" and s or VRFW.crc32(s)
  end

  local function exists(menu)
    return funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, menu) == true
  end

  local function logger_of(spec, label)
    if type(spec.log) == "function" then
      return spec.log
    end
    local log
    return function(...)
      log = log or VRFW.logger.new("VRFW.child_menu")
      log(label, ...)
    end
  end

  local hosted = {}               -- menu crc -> host object of this VM
  local finalize_hooked = false

  local function hook_finalize()
    if finalize_hooked then
      return
    end
    finalize_hooked = true
    local previous = _ENV.FinalizeMenu
    _ENV.FinalizeMenu = function(...)
      for _, h in pairs(hosted) do
        pcall(h.gone)
      end
      if type(previous) == "function" then
        return previous(...)
      end
    end
  end

  --- The child's own reports (cross-menu calls of the child).
  function vrfw_child_menu_opened(menu)
    local h = hosted[menu]
    if h then
      h.event("opened")
    end
  end

  --- The child menu's closed report.
  function vrfw_child_menu_closed(menu)
    local h = hosted[menu]
    if h then
      h.event("closed")
    end
  end

  --- VRFW.child_menu.host(menu_name, spec): opens child menu `menu_name` inside this menu. Returns its handle table. Call only from OnInit, Step or another callback.
  function ChildMenu.host(menu_name, spec)
    spec = type(spec) == "table" and spec or {}
    local menu = crc(menu_name)
    local prefix = spec.prefix or (tostring(menu_name) .. "_")
    local label = spec.label or tostring(menu_name)
    local log = logger_of(spec, label)
    -- state: "closed" | "open" | "closing" (asked to close, its closed report not in yet)
    local S = { state = "closed", want = nil, host = 0, args = {}, wait = 0, unwanted = false }
    local h = {}

    local function send()
      VRFW.param.replace(crc(prefix .. "page"), S.want or -1)
      VRFW.param.set_u32(prefix .. "host", S.host or 0)
      if type(spec.send) == "function" then
        spec.send(S.want)
      end
    end

    local function redraw()
      send()
      pcall(funcLuaCommand, CROSS_CALL, menu, "vrfw_child_menu_redraw", S.want, S.host,
        table.unpack(S.args, 1, S.args.n or #S.args))
    end

    local function open()
      send()
      funcLuaCommand(VRFW.commands.OPEN_MENU_OBJECT, menu)
      S.state, S.wait = "open", 0
      log("opened (page " .. tostring(S.want) .. ")")
    end

    local function request_close(why, gone)
      pcall(funcLuaCommand, CROSS_CALL, menu, "vrfw_child_menu_close", why, gone == true)
      pcall(funcLuaCommand, VRFW.commands.CLOSE_MENU_OBJECT, menu)
      S.state, S.wait = "closing", 0
    end

    --- Asks the child to open on `page` over `host`.
    function h.show(page, host, ...)
      hook_finalize()
      S.want = page or -1
      S.host = host or 0
      S.args = table.pack(...)
      if S.state == "open" then
        redraw()
      elseif S.state == "closed" then
        if exists(menu) then
          S.state, S.wait = "closing", 0
        else
          open()
        end
      end
    end

    --- Asks the child to close.
    function h.hide(why)
      local was = S.want ~= nil
      S.want = nil
      local there = S.state == "closed" and exists(menu)
      if S.state == "open" or there then
        request_close(why or "the host left it")
        log("closed (" .. tostring(why) .. ", wanted " .. tostring(was) .. ", existed " .. tostring(there) .. ")")
      end
    end

    --- The host menu destroyed.
    function h.gone()
      S.want = nil
      if S.state ~= "closed" or exists(menu) then
        request_close("host closed", true)
        log("closed (its host closed)")
      end
    end

    --- Handles a report of the child ("opened", "closed").
    function h.event(what)
      if what == "closed" then
        local was = S.state
        S.state, S.wait = "closed", 0
        if S.want ~= nil and was == "open" then
          log("gone while it is wanted; opened again")
        end
      elseif what == "opened" and S.want == nil and S.state == "closing" then
        S.unwanted = true
      end
    end

    --- One frame of the child host.
    function h.step()
      if S.unwanted then
        S.unwanted = false
        if S.want == nil then
          request_close("opened while not wanted")
          log("opened while not wanted; asked to close again")
        end
      end
      if S.want == nil then
        return
      end
      if S.state == "closed" then
        open()
      elseif S.state == "closing" then
        S.wait = S.wait + 1
        if S.wait >= REVIVE_STEPS then
          if exists(menu) then
            redraw()
            S.state, S.wait = "open", 0
            log("the earlier one still existed; shown again")
          else
            open()
          end
        end
      end
    end

    --- Calls `fn` in the open child; answers pcall's results, false when it is not open.
    function h.call(fn, ...)
      if S.state == "open" then
        return pcall(funcLuaCommand, CROSS_CALL, menu, fn, ...)
      end
      return false
    end

    --- True while the child is open.
    function h.open()
      return S.state == "open"
    end

    --- True while the child is wanted.
    function h.wanted()
      return S.want ~= nil
    end

    hosted[menu] = h
    return h
  end

  --- VRFW.child_menu.close(menu_name[, why]): closes a child menu. Returns true when it was open. Call only from OnInit, Step or another callback.
  function ChildMenu.close(menu_name, why)
    local menu = crc(menu_name)
    if not exists(menu) then
      return false
    end
    pcall(funcLuaCommand, CROSS_CALL, menu, "vrfw_child_menu_close", why)
    pcall(funcLuaCommand, VRFW.commands.CLOSE_MENU_OBJECT, menu)
    return true
  end

  --- VRFW.child_menu.child(menu_name, spec): makes this script a child menu. Returns its handle table. Call only from OnInit, Step or another callback.
  function ChildMenu.child(menu_name, spec)
    spec = type(spec) == "table" and spec or {}
    local menu = crc(menu_name)
    local prefix = spec.prefix or (tostring(menu_name) .. "_")
    local label = spec.label or tostring(menu_name)
    local log = logger_of(spec, label)
    local S = { page = -1, host = nil, closing = false, tries = 0, frame = 0, told = false }
    local c = {}

    local function read()
      local page = tonumber(VRFW.param.get(crc(prefix .. "page")))
      local host = VRFW.param.get_u32(prefix .. "host")
      if page ~= nil then
        S.page = page
      end
      if host ~= nil and host ~= 0 then
        S.host = host
      end
    end

    local function tell_host(fn)
      if S.host ~= nil and exists(S.host) then
        pcall(funcLuaCommand, CROSS_CALL, S.host, fn, menu)
      end
    end

    local function close_now()
      S.tries = S.tries + 1
      pcall(funcLuaCommand, VRFW.commands.CLOSE_MENU_OBJECT, menu)
    end

    local function begin_close(why)
      if not S.closing then
        log("closing (" .. tostring(why) .. ")")
      end
      S.closing, S.frame = true, 0
      if type(spec.on_close) == "function" then
        pcall(spec.on_close, why)
      end
      close_now()
    end

    --- The host's calls (cross-menu call).
    function vrfw_child_menu_redraw(page, host, ...)
      read()
      if page ~= nil then
        S.page = page
      end
      if host ~= nil and host ~= 0 then
        S.host = host
      end
      if S.closing then
        log("shown again before it closed (tries " .. S.tries .. ")")
        S.closing, S.tries = false, 0
      end
      if type(spec.on_redraw) == "function" then
        spec.on_redraw(S.page, ...)
      end
    end

    --- Host's request to close; `host_gone` drops the host.
    function vrfw_child_menu_close(why, host_gone)
      if host_gone then
        S.host = nil
      end
      begin_close(why or "the host left it")
    end

    --- Reads the child's start state; answers page, host.
    function c.init()
      S.page, S.host, S.closing, S.tries, S.frame, S.told = -1, nil, false, 0, 0, false
      read()
      return S.page, S.host
    end

    --- One frame of the child; answers true while closing is in progress.
    function c.step()
      if not S.told then
        S.told = true
        tell_host("vrfw_child_menu_opened")
      end
      if not S.closing then
        return false
      end
      S.frame = S.frame + 1
      if S.tries < CLOSE_RETRIES and S.frame % CLOSE_RETRY_STEPS == 0 then
        close_now()
        if S.tries == CLOSE_RETRIES then
          log("still open after " .. S.tries .. " close requests (hidden meanwhile)")
        end
      end
      return true
    end

    --- Tells the host the child closed.
    function c.finalize()
      tell_host("vrfw_child_menu_closed")
    end

    --- The host menu of this child.
    function c.host()
      return S.host
    end

    --- The page this child shows.
    function c.page()
      return S.page
    end

    --- True while the child is closing.
    function c.closing()
      return S.closing
    end

    return c
  end

  --- Child menus opened inside a menu: host, child, close. Call only from OnInit, Step or another callback.
  VRFW.child_menu = ChildMenu
end
