-- VRFW_Question: the game's general window as a yes / no question or a notice, waited for inside the caller's coroutine
-- (one yield per frame, as the retail windows are waited for). Definitions only: no engine call at load.
--   VRFW_Question.Ask(text) -> true (the first button, «Sí») | false (the second button, Back, or no window)
--   VRFW_Question.Notice(text) -> true when the window was shown and closed
--   VRFW_Question.Uncover() -> true when the screen was black (an event's fade left it there) and was faded back in:
--       the retail board's step after an event (vs_route_town_menu state 4); every window calls it before it opens
--   VRFW_Question.List(names) -> the names as one list in the game's language («A, B y C»): text rows
--       VRFW.Text.ListJoin («%s, %s») and VRFW.Text.ListLast («%s y %s»); "" for no names
-- Rules: a general window still open (another one, or one closing) is waited for before this one opens; an answer
-- counts only once this window was seen up, so an answer left by an earlier window is never taken; a window that never
-- comes up gives false (logged). A window never opens over a black screen:
-- a fade left at black by an event before it is faded back in first. Every wait is bounded. Log lines on changes only: opened, answered, never came up.
if VRFW_Question == nil then
  local Q = {
    OPEN = 2289627655,      -- (text, …) the general window
    KIND = 2351835063,      -- (kind, 0): 1 = one button, 2 = yes / no
    RESULT = 1523741473,    -- () -> the chosen button (0 = the first; -1 while none), cancelled
    GONE = 682363669,       -- () -> true when no general window is open
    BUSY = 898725220,       -- () -> true while a general window opens or closes
    TEXT = VRFW_Cmd.TEXT_GET,
    JOIN = 3451366411,      -- crc32("VRFW.Text.ListJoin")
    LAST = 2936921468,      -- crc32("VRFW.Text.ListLast")
    FREE_WAIT = 300,        -- frames for an earlier window to close
    UP_WAIT = 90,           -- frames for this window to come up
    MAX_WAIT = 108000,      -- frames an open window is waited for (30 minutes)
    SCREEN_BLACK = 2259183189, -- (true) -> true while the screen fade holds black
    SCREEN_FADE = 3085729424,  -- CMND_START_SCREEN_FADE (0 = back in, seconds), the retail step after an event
    BRIGHT_FADE = 609722083,   -- (0 = back in, seconds) the bright fade
    IS_FADE = VRFW_Cmd.BRIGHT_IS_FADE,
    FADE_TIME = 0.3,        -- seconds of the fade back in
    FADE_WAIT = 60,         -- frames that fade is waited for
  }
  VRFW_Question = Q
  local log = VRFW_Log.New("VRFW question")

  local function call(cmd, ...)
    local f = _ENV.funcLuaCommand
    if type(f) ~= "function" then return nil end
    local r = table.pack(pcall(f, cmd, ...))
    if not r[1] then return nil end
    return table.unpack(r, 2, r.n)
  end

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

  function Q.Uncover()
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

  -- one window of `kind`; -> the chosen button (>= 0), -1 closed without one, nil never came up
  local function show(text, kind)
    free()
    Q.Uncover()
    call(Q.OPEN, text, 0, 0, 0, 0, 0, false)
    call(Q.KIND, kind, 0)
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

  function Q.Ask(text)
    local chosen = show(text, 2)
    log("answered", chosen == 0 and "yes" or (chosen == nil and "none (no window)" or "no"), text)
    return chosen == 0
  end

  function Q.Notice(text)
    return show(text, 1) ~= nil
  end

  local function pattern(id, fallback)
    local s = call(Q.TEXT, id)
    if type(s) ~= "string" or select(2, s:gsub("%%s", "")) ~= 2 then
      return fallback
    end
    return s
  end

  function Q.List(names)
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
