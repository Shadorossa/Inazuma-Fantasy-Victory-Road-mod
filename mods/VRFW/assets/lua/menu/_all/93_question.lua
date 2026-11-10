if VRFW.question == nil then
  local Q = {
    OPEN = 2289627655,      -- (text, …) the general window
    KIND = 2351835063,      -- (kind, 0): 1 = one button, 2 = yes / no
    RESULT = 1523741473,
    GONE = 682363669,       -- () -> true when no general window is open
    BUSY = 898725220,       -- () -> true while a general window opens or closes
    TEXT = VRFW.commands.TEXT_GET,
    JOIN = 3451366411,
    LAST = 2936921468,
    FREE_WAIT = 300,
    UP_WAIT = 90,           -- frames for this window to come up
    MAX_WAIT = 108000,      -- frames an open window is waited for (30 minutes)
    SCREEN_BLACK = 2259183189, -- (true) -> true while the screen fade holds black
    SCREEN_FADE = 3085729424,
    BRIGHT_FADE = 609722083,   -- (0 = back in, seconds) the bright fade
    IS_FADE = VRFW.commands.BRIGHT_IS_FADE,
    FADE_TIME = 0.3,        -- Seconds of the fade back in.
    FADE_WAIT = 60,         -- Frames that fade is waited for.
    ITEM_GET_TEXT = 3675423478, -- sysmes_item_get
    ITEM_GET_WINDOW = 11,
  }
  VRFW.question = Q
  local log = VRFW.logger.new("VRFW question")
  local NO_OPTIONS = {}

  local call = VRFW.host.command

  local function free()
    for _ = 1, Q.FREE_WAIT do
      if call(Q.GONE) == true and call(Q.BUSY) ~= true then
        return true
      end
      coroutine.yield()
    end
    log("an earlier window is still open: opening anyway")
    return false
  end

  --- Fades the screen back in when it is held black; answers true when it did.
  function Q.uncover()
    if call(Q.SCREEN_BLACK, true) ~= true then
      return false
    end
    call(Q.SCREEN_FADE, 0, Q.FADE_TIME)
    call(Q.BRIGHT_FADE, 0, Q.FADE_TIME)
    log("screen black before a window: faded back in")
    for _ = 1, Q.FADE_WAIT do
      coroutine.yield()
      if call(Q.IS_FADE) ~= true and call(Q.SCREEN_BLACK, true) ~= true then
        break
      end
    end
    return true
  end

  -- one window of `kind` (nil: the window type sets its buttons); opts: window, object, button, on_open()
  -- -> the chosen button (>= 0), -1 closed without one, nil never came up
  local function show(text, kind, opts)
    opts = opts or NO_OPTIONS
    free()
    Q.uncover()
    call(Q.OPEN, text, opts.window or 0, 0, opts.object or 0, 0, 0, false)
    if kind ~= nil then
      call(Q.KIND, kind, opts.button or 0)
    end
    if opts.on_open ~= nil then
      opts.on_open()
    end
    local up = false
    for f = 1, Q.MAX_WAIT do
      coroutine.yield()
      local chosen, cancelled = call(Q.RESULT)
      local gone = call(Q.GONE) == true
      local busy = call(Q.BUSY) == true
      if not up and (not gone or busy) then
        up = true
        log("opened", kind == 2 and "question" or "notice", "after", f, "frames:", text)
      end
      if up and type(chosen) == "number" and chosen >= 0 then
        for _ = 1, Q.FREE_WAIT do
          if call(Q.GONE) == true then break end
          coroutine.yield()
        end
        return chosen
      end
      if up and (cancelled == true or (gone and not busy)) then
        return -1
      end
      if not up and f > Q.UP_WAIT then
        log("never came up after", f, "frames:", text)
        return nil
      end
    end
    log("still open after", Q.MAX_WAIT, "frames:", text)
    return -1
  end

  --- Asks a yes / no question; answers true only for yes (false when no window came up).
  function Q.ask(text, opts)
    local chosen = show(text, 2, opts)
    log("answered", chosen == 0 and "yes" or (chosen == nil and "none (no window)" or "no"), text)
    return chosen == 0
  end

  --- Shows an OK window; answers true when a window came up.
  function Q.notice(text, opts)
    return show(text, 1, opts) ~= nil
  end

  --- Shows the game's item-obtained window; answers true when a window came up.
  function Q.item_get(item)
    return show(Q.ITEM_GET_TEXT, nil, {window = Q.ITEM_GET_WINDOW, object = item}) ~= nil
  end

  local function pattern(id, fallback)
    local s = call(Q.TEXT, id)
    if type(s) ~= "string" or select(2, s:gsub("%%s", "")) ~= 2 then
      return fallback
    end
    return s
  end

  --- The text list of `names`, joined with the game's separators.
  function Q.list(names)
    local n = #names
    if n == 0 then return "" end
    local list = tostring(names[1])
    if n == 1 then return list end
    local join, last = pattern(Q.JOIN, "%s, %s"), pattern(Q.LAST, "%s, %s")
    for i = 2, n - 1 do
      list = string.format(join, list, tostring(names[i]))
    end
    return string.format(last, list, tostring(names[n]))
  end
end
