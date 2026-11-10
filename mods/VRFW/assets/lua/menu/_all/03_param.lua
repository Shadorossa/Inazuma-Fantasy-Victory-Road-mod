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

  --- True when the parameter exists.
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

  --- The parameter's value, or nil when it does not exist.
  function P.get(key)
    local id = key_of(key)
    if not P.has(id) then
      return nil
    end
    return read(id)
  end

  --- Writes a parameter; kind = "plain" stores the raw value.
  function P.set(key, value, kind)
    if kind == "plain" then
      command(VRFW.commands.PARAM_SET, key_of(key), 0, value)
    else
      command(VRFW.commands.PARAM_SET, key_of(key), 0, value, 1)
    end
  end

  --- Deletes a parameter.
  function P.clear(key)
    command(VRFW.commands.PARAM_DELETE, key_of(key))
  end

  --- Deletes a parameter, then writes it.
  function P.replace(key, value, kind)
    local id = key_of(key)
    P.clear(id)
    P.set(id, value, kind)
  end

  --- Answers the parameter's value and deletes it; nil when it does not exist.
  function P.take(key)
    local id = key_of(key)
    if not P.has(id) then
      return nil
    end
    local value = read(id)
    P.clear(id)
    return value
  end

  --- Stores an unsigned 32-bit number in two parameters, <name>_hi and <name>_lo.
  function P.set_u32(name, n)
    n = math.floor(tonumber(n) or 0) % 4294967296
    P.replace(name .. "_hi", math.floor(n / 65536))
    P.replace(name .. "_lo", n % 65536)
  end

  --- Reads back what set_u32 stored; nil when either half is missing.
  function P.get_u32(name)
    local hi, lo = tonumber(P.get(name .. "_hi")), tonumber(P.get(name .. "_lo"))
    if hi == nil or lo == nil then
      return nil
    end
    return (hi % 65536) * 65536 + lo % 65536
  end

  VRFW.param = P
end
