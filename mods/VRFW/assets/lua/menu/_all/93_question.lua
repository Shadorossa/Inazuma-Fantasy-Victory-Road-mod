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
    MORE = 1854178976,      -- VRFW.Text.ListMore: the last line of a cut list ("… and %s more")
    LINE_UNITS = 64,        -- The widest line (text_fold units) the general window draws at full size; retail system_text keeps 99 % of its lines under 80 and the window squeezes the whole text when one line is wider.
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
  --- Game dialog windows: ask, notice, item_get, list. Call only from OnInit, Step or another callback.
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

  --- Internal: Fades the screen back in when it is held black; answers true when it did.
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

  local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"
  local MARKUP = "^%[C%u*%]"
  local TAG = "^<[%u%d_]+>"

  -- The pieces of one line that a break may separate: words with their following spaces, and each wide character on its own.
  local function pieces(line)
    local out, at, word = {}, 1, ""
    while at <= #line do
      local mark = line:match(MARKUP, at) or line:match(TAG, at)
      local ch = mark or line:match(UTF8_CHAR, at) or line:sub(at, at)
      at = at + #ch
      if mark == nil and (string.byte(ch, 1) or 0) >= 0xE3 then
        if word ~= "" then out[#out + 1] = word end
        out[#out + 1], word = ch, ""
      else
        word = word .. ch
        if ch == " " and line:sub(at, at) ~= " " then
          out[#out + 1], word = word, ""
        end
      end
    end
    if word ~= "" then out[#out + 1] = word end
    return out
  end

  -- Line `line` broken into lines of at most `units` (one longer word stays whole on its own line).
  local function wrap_line(line, units, out)
    local units_of = VRFW.text_fold.units
    if units_of(line) <= units then
      out[#out + 1] = line
      return
    end
    local current = ""
    for _, piece in ipairs(pieces(line)) do
      if current ~= "" and units_of(current .. piece:gsub(" +$", "")) > units then
        out[#out + 1] = (current:gsub(" +$", ""))
        current = ""
      end
      current = current .. piece
    end
    if current ~= "" then out[#out + 1] = (current:gsub(" +$", "")) end
  end

  --- Internal: Text `text` with every line wider than the general window broken at its spaces (or between wide characters).
  function Q.wrap(text, units)
    if type(text) ~= "string" then return text end
    units = units or Q.LINE_UNITS
    local lines = {}
    for line in (text:gsub("\\n", "\n") .. "\n"):gmatch("(.-)\n") do
      wrap_line(line, units, lines)
    end
    return table.concat(lines, "\n")
  end

  -- one window of `kind` (nil: the window type sets its buttons); opts: window, object, button, on_open()
  -- -> the chosen button (>= 0), -1 closed without one, nil never came up
  local function show(text, kind, opts)
    opts = opts or NO_OPTIONS
    text = Q.wrap(text)
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

  --- VRFW.question.ask(text[, opts]): a yes / no window. Returns true only for yes. Call only from OnInit, Step or another callback.
  function Q.ask(text, opts)
    local chosen = show(text, 2, opts)
    log("answered", chosen == 0 and "yes" or (chosen == nil and "none (no window)" or "no"), text)
    return chosen == 0
  end

  --- VRFW.question.notice(text[, opts]): an OK window. Returns true when the window came up. Call only from OnInit, Step or another callback.
  function Q.notice(text, opts)
    return show(text, 1, opts) ~= nil
  end

  --- VRFW.question.item_get(item): the game's item-obtained window. Returns true when it came up. Call only from OnInit, Step or another callback.
  function Q.item_get(item)
    return show(Q.ITEM_GET_TEXT, nil, {window = Q.ITEM_GET_WINDOW, object = item}) ~= nil
  end

  local function pattern(id, fallback, slots)
    local s = call(Q.TEXT, id)
    if type(s) ~= "string" or select(2, s:gsub("%%s", "")) ~= (slots or 2) then
      return fallback
    end
    return s
  end

  -- The first `last_index` names of `names` in lines of at most Q.LINE_UNITS, each break after a separator; `cut` joins the last one with `join` too.
  local function name_lines(names, last_index, cut, join, last)
    local units_of = VRFW.text_fold.units
    local lines, current = {}, tostring(names[1])
    for i = 2, last_index do
      local sep_pattern = (i == last_index and not cut) and last or join
      local joined = string.format(sep_pattern, current, tostring(names[i]))
      if units_of(joined) > Q.LINE_UNITS then
        local before = string.format(sep_pattern, current, "")
        lines[#lines + 1] = (before:gsub(" +$", ""))
        current = tostring(names[i])
      else
        current = joined
      end
    end
    lines[#lines + 1] = current
    return lines
  end

  --- VRFW.question.list(names[, max_lines]): names joined into lines that fit a dialog window. Safe at load.
  function Q.list(names, max_lines)
    local n = #names
    if n == 0 then return "" end
    local join, last = pattern(Q.JOIN, "%s, %s"), pattern(Q.LAST, "%s, %s")
    local lines = name_lines(names, n, false, join, last)
    if max_lines == nil or #lines <= max_lines then
      return table.concat(lines, "\n")
    end
    local shown = n
    repeat
      shown = shown - 1
      lines = name_lines(names, shown, true, join, last)
    until shown <= 1 or #lines < max_lines
    lines[#lines + 1] = string.format(pattern(Q.MORE, "… +%s", 1), tostring(n - shown))
    return table.concat(lines, "\n")
  end
end
