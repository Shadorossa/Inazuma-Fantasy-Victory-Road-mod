-- VRFW.host command hooks: the one wrapper of this VM's funcLuaCommand / funcLuaMenuCommand.
VRFW.host = VRFW.host or {}
if VRFW.host.hook_command == nil then
  local H = VRFW.host
  local LOG = VRFW.commands.VRFW_LOG
  local PRIORITY_TEMPORARY = -1000000000
  --- Priority value that puts a command hook closest to the game's own command. Safe at load.
  H.INNERMOST = 1000000000
  local pack, unpack = table.pack, table.unpack

  local SLOTS = {}                   -- function name -> slot
  local seq = 0
  local with_depth = 0

  -- kind: nil / false = funcLuaCommand, "post" = funcLuaMenuPostCommand, any other true value = funcLuaMenuCommand
  local function slot_of(kind)
    local name = (kind == "post" and "funcLuaMenuPostCommand") or (kind and "funcLuaMenuCommand") or "funcLuaCommand"
    local s = SLOTS[name]
    if s == nil then
      s = { name = name, by_id = {}, any = {}, gen = 0, chains = {}, chains_gen = -1, passing = nil, top = nil,
        base = nil, pending = {} }
      SLOTS[name] = s
    end
    return s
  end

  local function log(...)
    local f = _ENV.funcLuaCommand
    if type(f) == "function" then
      pcall(f, LOG, "command_hooks", ...)
    end
  end

  local trace_on = nil
  local function trace(...)
    if trace_on == nil then
      local f = _ENV.funcLuaCommand
      if type(f) ~= "function" then
        return
      end
      local ok, on = pcall(f, VRFW.commands.VRFW_DEBUG_SWITCH, "command_hooks")
      trace_on = ok and (on == true or on == 1)
    end
    if trace_on then
      log(...)
    end
  end

  local function crc_text(c)
    if type(c) ~= "number" then
      return tostring(c)
    end
    c = math.floor(c) % 4294967296
    return string.format("0x%04X%04X", math.floor(c / 65536), c % 65536)
  end

  local function flush_pending(s)
    if type(_ENV.funcLuaCommand) ~= "function" then
      return
    end
    local lines = s.pending
    s.pending = {}
    for _, line in ipairs(lines) do
      trace(line.owner, "hooks", s.name, line.ids)
    end
  end

  -- the handlers of command c, outermost first (cached per registry generation)
  local function chain_of(s, c)
    if s.chains_gen ~= s.gen then
      s.chains, s.chains_gen = {}, s.gen
    end
    local list = s.chains[c]
    if list ~= nil then
      return list
    end
    list = {}
    for _, h in ipairs(s.by_id[c] or {}) do
      list[#list + 1] = h
    end
    for _, h in ipairs(s.any) do
      list[#list + 1] = h
    end
    table.sort(list, function(a, b)
      if a.priority ~= b.priority then
        return a.priority < b.priority
      end
      return a.seq < b.seq
    end)
    s.chains[c] = list
    return list
  end

  local last_nil_caller = nil
  local function note_nil_command(s)
    local where = "?"
    if debug and debug.traceback then
      local ok, tb = pcall(debug.traceback, "", 3)
      if ok and type(tb) == "string" then
        local frames = {}
        for line in tb:gmatch("[^\n]+") do
          line = line:gsub("^%s+", "")
          if line ~= "" and line ~= "stack traceback:" then
            frames[#frames + 1] = line
            if #frames == 3 then
              break
            end
          end
        end
        where = table.concat(frames, " <- ")
      end
    end
    if where ~= last_nil_caller then
      last_nil_caller = where
      log(s.name, "called with a nil command id from", where)
    end
  end

  -- handler k of the chain, then the command function under the dispatcher
  local function run(s, list, k, real, ...)
    local h = list[k]
    if h == nil then
      local before = s.passing
      s.passing = (...)
      local r = pack(pcall(real, ...))
      s.passing = before
      if not r[1] then
        error(r[2], 0)
      end
      return unpack(r, 2, r.n)
    end
    local called, results = false, nil
    local function nxt(...)
      called = true
      results = pack(run(s, list, k + 1, real, ...))
      return unpack(results, 1, results.n)
    end
    local r = pack(pcall(h.fn, nxt, ...))
    if r[1] then
      return unpack(r, 2, r.n)
    end
    if called and results == nil then
      error(r[2], 0)                 -- The command under the handler failed: its error goes on.
    end
    if not h.failed then
      h.failed = true
      log("handler of", h.owner, "failed on", crc_text((...)), tostring(r[2]))
    end
    if called then
      return unpack(results, 1, results.n)
    end
    return run(s, list, k + 1, real, ...)
  end

  local function install(s)
    local current = _ENV[s.name]
    if type(current) ~= "function" then
      return false
    end
    if current == s.top then
      return true
    end
    local real = current
    if s.base == nil then
      s.base = real
    end
    local dispatch
    dispatch = function(...)
      local c = ...
      if s.pending[1] ~= nil then
        flush_pending(s)
      end
      if c == nil then
        note_nil_command(s)
        return real(...)
      end
      if s.passing ~= nil and s.passing == c then
        return real(...)             -- a dispatcher above already ran the handlers of this call
      end
      local list = chain_of(s, c)
      if #list == 0 then
        return real(...)
      end
      return run(s, list, 1, real, ...)
    end
    s.top = dispatch
    _ENV[s.name] = dispatch
    return true
  end

  local function ids_of(id)
    if type(id) == "table" then
      return id
    end
    return { id }
  end

  local function add(s, id, fn, owner, priority)
    seq = seq + 1
    local h = { fn = fn, owner = owner, priority = priority, seq = seq }
    local list
    if id == "*" then
      list = s.any
    else
      list = s.by_id[id]
      if list == nil then
        list = {}
        s.by_id[id] = list
      end
    end
    for i = #list, 1, -1 do
      if list[i].owner == owner then
        table.remove(list, i)
      end
    end
    list[#list + 1] = h
    s.gen = s.gen + 1
  end

  local function remove(s, owner)
    local function drop(list)
      for i = #list, 1, -1 do
        if list[i].owner == owner then
          table.remove(list, i)
        end
      end
    end
    for _, list in pairs(s.by_id) do
      drop(list)
    end
    drop(s.any)
    s.gen = s.gen + 1
  end

  local globals_watched = false
  local function watch_registration()
    if globals_watched then
      return true
    end
    local ok_meta, meta = pcall(getmetatable, _ENV)
    if not ok_meta or (meta ~= nil and type(meta) ~= "table") then
      return false
    end
    if meta == nil then
      meta = {}
      if not pcall(setmetatable, _ENV, meta) then
        return false
      end
    end
    local previous = meta.__newindex
    meta.__newindex = function(globals, key, value)
      if previous == nil then
        rawset(globals, key, value)
      elseif type(previous) == "function" then
        previous(globals, key, value)
      else
        previous[key] = value
      end
      local s = SLOTS[key]
      if s ~= nil and type(rawget(globals, key)) == "function" then
        install(s)
      end
    end
    globals_watched = true
    return true
  end

  local LOGGED = {}

  --- VRFW.host.hook_command(id, fn, owner[, opts]): runs fn when the menu calls command `id`; return VRFW.host.HALT to stop the call. Safe at load.
  function H.hook_command(id, fn, owner, opts)
    opts = opts or {}
    if type(fn) ~= "function" or type(owner) ~= "string" or owner == "" then
      log("HookCommand: a handler function and an owner text are required", tostring(owner))
      return false, "a handler function and an owner text are required"
    end
    local s = slot_of(opts.post and "post" or opts.menu)
    for _, c in ipairs(ids_of(id)) do
      add(s, c, fn, owner, tonumber(opts.priority) or 0)
    end
    local ok = install(s)
    if not ok then
      watch_registration()
    end
    local key = s.name .. "|" .. owner
    if not LOGGED[key] then
      LOGGED[key] = true
      local list = {}
      for _, c in ipairs(ids_of(id)) do
        list[#list + 1] = crc_text(c)
      end
      if ok then
        trace(owner, "hooks", s.name, table.concat(list, " "))
      else
        s.pending[#s.pending + 1] = { owner = owner, ids = table.concat(list, " ") }
      end
    end
    return ok
  end

  local NO_HANDLERS = {}
  local function real_call(s, ...)
    local base = s.base
    if base == nil then
      base = _ENV[s.name]
    end
    return run(s, NO_HANDLERS, 1, base, ...)
  end

  --- Advanced: Calls funcLuaCommand underneath every hook.
  function H.real_command(...)
    return real_call(slot_of(false), ...)
  end

  --- Advanced: Calls funcLuaMenuCommand underneath every hook.
  function H.real_menu_command(...)
    return real_call(slot_of(true), ...)
  end

  --- VRFW.host.unhook_command(owner[, opts]): removes the command hooks of owner. Safe at load.
  function H.unhook_command(owner, opts)
    remove(slot_of(opts and (opts.post and "post" or opts.menu)), owner)
  end

  local function answer_of(v)
    if type(v) == "function" then
      return v
    end
    return function()
      return v
    end
  end

  --- Advanced: Runs fn(...) with command overrides; answers fn's results.
  function H.with_commands(overrides, fn, ...)
    with_depth = with_depth + 1
    seq = seq + 1
    local owner = "with_commands#" .. seq
    local priority = PRIORITY_TEMPORARY - with_depth
    local used = {}
    for c, v in pairs(overrides or {}) do
      if c ~= "menu" and c ~= "post" then
        local s = slot_of(false)
        add(s, c, answer_of(v), owner, priority)
        used[s] = true
      end
    end
    for _, kind in ipairs({ "menu", "post" }) do
      if type(overrides) == "table" and type(overrides[kind]) == "table" then
        for c, v in pairs(overrides[kind]) do
          local s = slot_of(kind == "post" and "post" or true)
          add(s, c, answer_of(v), owner, priority)
          used[s] = true
        end
      end
    end
    for s in pairs(used) do
      if not install(s) then
        log("WithCommands:", s.name, "does not exist yet: run without the answers")
      end
    end
    local r = pack(pcall(fn, ...))
    for s in pairs(used) do
      remove(s, owner)
    end
    with_depth = with_depth - 1
    if not r[1] then
      error(r[2], 0)
    end
    return unpack(r, 2, r.n)
  end

  --- VRFW.host.command(id, ...): calls funcLuaCommand safely. Returns its results, or nil when it failed. Call only from OnInit, Step or another callback.
  function H.command(id, ...)
    local r = pack(pcall(_ENV.funcLuaCommand, id, ...))
    if not r[1] then
      return nil
    end
    return unpack(r, 2, r.n)
  end

  --- VRFW.host.menu_command(id, ...): calls funcLuaMenuCommand safely. Returns its results, or nil when it failed. Call only from OnInit, Step or another callback.
  function H.menu_command(id, ...)
    local r = pack(pcall(_ENV.funcLuaMenuCommand, id, ...))
    if not r[1] then
      return nil
    end
    return unpack(r, 2, r.n)
  end
end
