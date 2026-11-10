-- lua_patch.scope: used
-- mode_engine (VRFW): the VRFW.mode helper, defined in every script VM (lua\_all runs after each retail chunk).
if VRFW.mode == nil then
  local OPEN_MENU = 433545986      -- CMND_OPEN_MENU_OBJECT
  local IS_MENU = 2231168902       -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
  local LANG = 477234096           -- CMND_GET_LANGUAGE_CODE

  VRFW.mode = { run = nil, log = {}, story_provider = nil }

  local function note(...)
    if #VRFW.mode.log < 200 then
      VRFW.mode.log[#VRFW.mode.log + 1] = table.concat({...}, " ")
    end
  end

  -- The engine answers (VERSION); without the plugin every query is empty and every mode counts as on.
  function VRFW.mode.ready()
    local v = VRFW.host.command(VRFW.commands.VRFW_MODE_VERSION)
    return type(v) == "number"
  end

  function VRFW.mode.on(key)
    local known, on = VRFW.host.command(VRFW.commands.VRFW_MODE_ON, key)
    if known ~= true then
      return true
    end
    return on == true
  end

  function VRFW.mode.text(key, field)
    local s = VRFW.host.command(VRFW.commands.VRFW_MODE_TEXT, key, field or "name", VRFW.host.command(LANG) or 3)
    if type(s) ~= "string" or s == "" then
      return field == "description" and "" or key
    end
    return s
  end

  -- the Lua clauses of [mode.unlock] (the Rust ones come with UNLOCKED)
  function VRFW.mode.story_cleared()
    local p = VRFW.mode.story_provider or VRFW.story_provider
    if type(p) ~= "function" then
      return true -- no provider: the clause is not checked
    end
    local ok, cleared = pcall(p)
    if not ok or cleared == nil then
      return true
    end
    return cleared == true or cleared == 1
  end

  function VRFW.mode.unlocked(key)
    local ok, story, lua = VRFW.host.command(VRFW.commands.VRFW_MODE_UNLOCKED, key)
    if ok ~= true then
      return ok == nil -- nil = no plugin
    end
    if story == true and not VRFW.mode.story_cleared() then
      return false
    end
    if type(lua) == "string" and lua ~= "" then
      local f = _G[lua]
      if type(f) ~= "function" or f(key) ~= true then
        return false
      end
    end
    return true
  end

  function VRFW.mode.entries(host)
    local out = {}
    local n = VRFW.host.command(VRFW.commands.VRFW_MODE_ENTRIES, host)
    if type(n) ~= "number" then
      return out
    end
    for i = 0, n - 1 do
      local key, name_id, desc_id, icon, action, arg, unlocked, id = VRFW.host.command(VRFW.commands.VRFW_MODE_ENTRY, host, i)
      if type(key) == "string" then
        out[#out + 1] = {key = key, name_id = name_id, desc_id = desc_id, icon = icon, action = action, arg = arg,
                         unlocked = unlocked == true and VRFW.mode.unlocked(key), id = id}
      end
    end
    return out
  end

  function VRFW.mode.busy()
    return VRFW.mode.run ~= nil
  end

  local function finish(run, cleared)
    local ok, ret, to, focus, send = VRFW.host.command(VRFW.commands.VRFW_MODE_EXIT, run.key, cleared and 1 or 0)
    if type(send) == "string" and send ~= "" then
      VRFW.host.command(VRFW.ids.crc32(send), 0)
    end
    VRFW.mode.run = nil
    note("exit", run.key, tostring(ret), tostring(to), tostring(focus))
    if run.cb and run.cb.back then
      run.cb.back(ret or "host", to or run.host, focus or run.focus)
    end
    return ok == true
  end

  local function body(run)
    coroutine.yield()
    if run.action == "open_menu" then
      local m = VRFW.ids.crc32(run.arg)
      VRFW.host.command(OPEN_MENU, m)
      coroutine.yield()
      while funcLuaMenuCommand(IS_MENU, m) do
        coroutine.yield()
      end
      return finish(run, false)
    elseif run.action == "command" then
      VRFW.host.command(VRFW.ids.crc32(run.arg))
    elseif run.action == "lua" then
      local f = _G[run.arg]
      if type(f) == "function" then
        f(run.key, run.host)
      else
        return finish(run, false)
      end
    end
    -- command / lua: the mode calls VRFW.mode.finish
    while VRFW.mode.run == run and not run.done do
      coroutine.yield()
    end
    if VRFW.mode.run == run then
      return finish(run, run.cleared)
    end
  end

  -- start mode `key` from `host` (focus = the host's entry index, given back at the end).
  function VRFW.mode.start(key, host, focus, cb)
    if VRFW.mode.run ~= nil then
      return false, 4
    end
    if not VRFW.mode.unlocked(key) then
      return false, 8
    end
    local ok, code, action, arg, save, slot, sbegin = VRFW.host.command(VRFW.commands.VRFW_MODE_ENTER, key, host, focus or -1)
    if ok ~= true then
      note("refused", key, tostring(code))
      return false, code
    end
    if type(sbegin) == "string" and sbegin ~= "" then
      local sok = VRFW.host.command(VRFW.ids.crc32(sbegin), 0)
      if sok ~= true then
        VRFW.host.command(VRFW.commands.VRFW_MODE_EXIT, key, 0)
        note("session refused", key)
        return false, 7
      end
    end
    local run = {key = key, host = host, focus = focus or -1, action = action, arg = arg, save = save, slot = slot, cb = cb}
    if cb and cb.before then
      cb.before(run)
    end
    run.co = coroutine.create(body)
    VRFW.mode.run = run
    note("enter", key, host, tostring(action), tostring(arg), tostring(save))
    coroutine.resume(run.co, run)
    return true, 0
  end

  function VRFW.mode.finish(key, cleared)
    local run = VRFW.mode.run
    if run == nil or run.key ~= key then
      return false
    end
    run.done, run.cleared = true, cleared == true
    return true
  end

  function VRFW.mode.step()
    local run = VRFW.mode.run
    if run == nil or run.co == nil then
      return
    end
    if coroutine.status(run.co) == "dead" then
      VRFW.mode.run = nil
      return
    end
    local ok, err = coroutine.resume(run.co)
    if not ok then
      note("error", run.key, tostring(err))
      finish(run, false)
    end
  end

  function VRFW.mode.rules(key, ctx)
    local id = VRFW.host.command(VRFW.commands.VRFW_MODE_RULES, key, ctx or "match")
    return type(id) == "string" and id or ""
  end
end
