if VRFW.param == nil then
  local names = {}

  local function key_of(key)
    if type(key) ~= "string" then
      return key
    end
    local id = names[key]
    if id == nil then
      id = VRFW.crc32(key)
      names[key] = id
    end
    return id
  end

  local function command(...)
    local f = _ENV.funcLuaCommand
    if type(f) ~= "function" then
      return false, nil
    end
    return pcall(f, ...)
  end

  local P = {}

  --- VRFW.param.has(key): whether a parameter exists. Safe at load.
  function P.has(key)
    local ok, has = command(VRFW.commands.PARAM_HAS, key_of(key))
    return ok and has == true
  end

  local function read(id)
    local ok, value = command(VRFW.commands.PARAM_GET, id)
    if ok then
      return value
    end
    return nil
  end

  --- VRFW.param.get(key): the value of a parameter, or nil. Safe at load.
  function P.get(key)
    local id = key_of(key)
    if not P.has(id) then
      return nil
    end
    return read(id)
  end

  --- VRFW.param.set(key, value[, kind]): writes a parameter (kind "plain" keeps the raw value). Safe at load.
  function P.set(key, value, kind)
    if kind == "plain" then
      command(VRFW.commands.PARAM_SET, key_of(key), 0, value)
    else
      command(VRFW.commands.PARAM_SET, key_of(key), 0, value, 1)
    end
  end

  --- VRFW.param.clear(key): deletes a parameter. Safe at load.
  function P.clear(key)
    command(VRFW.commands.PARAM_DELETE, key_of(key))
  end

  --- VRFW.param.replace(key, value[, kind]): deletes a parameter, then writes it. Safe at load.
  function P.replace(key, value, kind)
    local id = key_of(key)
    P.clear(id)
    P.set(id, value, kind)
  end

  --- VRFW.param.take(key): the value of a parameter, deleting it (nil when missing). Safe at load.
  function P.take(key)
    local id = key_of(key)
    if not P.has(id) then
      return nil
    end
    local value = read(id)
    P.clear(id)
    return value
  end

  --- VRFW.param.set_u32(name, n): stores an unsigned 32-bit number as two parameters <name>_hi and <name>_lo. Safe at load.
  function P.set_u32(name, n)
    n = math.floor(tonumber(n) or 0) % 4294967296
    P.replace(name .. "_hi", math.floor(n / 65536))
    P.replace(name .. "_lo", n % 65536)
  end

  --- VRFW.param.get_u32(name): the number set_u32 stored, or nil when a half is missing. Safe at load.
  function P.get_u32(name)
    local hi, lo = tonumber(P.get(name .. "_hi")), tonumber(P.get(name .. "_lo"))
    if hi == nil or lo == nil then
      return nil
    end
    return (hi % 65536) * 65536 + lo % 65536
  end

  --- The menu parameter store (values shared between menus by key): get, set, has, take. Safe at load.
  VRFW.param = P
end
