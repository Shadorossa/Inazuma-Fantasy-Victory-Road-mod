-- lua_patch.scope: used
-- save_engine: the VRFW.save helper, defined in every script VM (lua\_all runs after each retail chunk).
-- Command hashes (crc32 of the names) are listed in mods\save_engine\README.md.
if VRFW.save == nil then
  local H = {
    GET = 2187277743, SET = 2574269955, SET_BOOL = 2635532156, DEL = 2473923488,
    GGET = 2239362470, GSET = 2656501258, GSET_BOOL = 2513119134, GDEL = 2488521641,
    COMMIT = 3176099982, SLOT = 2171841521,
  }

  local function caller_id()
    local f = VRFW.patch and VRFW.patch.file
    if type(f) ~= "string" then return nil end
    return string.match(f, "^mods/([^/]+)/")
  end

  local function put(h, hbool, id, key, value, now)
    local n = nil
    if now then n = 1 end
    if type(value) == "boolean" then
      local b = 0
      if value then b = 1 end
      return funcLuaCommand(hbool, id, key, b, n)
    end
    return funcLuaCommand(h, id, key, value, n)
  end

  -- The get commands echo only a string or number default; when they push nothing the game's dispatcher answers true,
  -- so a boolean or nil default is sent as this marker and given back by the helper.
  local NO_VALUE = "vrfw.save:no-value"

  local function read(h, id, key, default)
    local kind = type(default)
    if kind == "string" or kind == "number" then
      return funcLuaCommand(h, id, key, default)
    end
    local value = funcLuaCommand(h, id, key, NO_VALUE)
    if value == NO_VALUE then return default end
    return value
  end

  --- The save engine of the menu VM: VRFW.save.open(mod id). Safe at load.
  VRFW.save = { H = H }

  -- VRFW.save.open(id): a save handle bound to mod `id` (read and write its saved values from a menu). Call only from OnInit, Step or another callback.
  function VRFW.save.open(id)
    id = id or caller_id()
    if id == nil then return nil end
    local s = { id = id }
    function s.get(key, default) return read(H.GET, id, key, default) end
    function s.set(key, value, now) return put(H.SET, H.SET_BOOL, id, key, value, now) end
    function s.delete(key) return funcLuaCommand(H.DEL, id, key) end
    function s.global_get(key, default) return read(H.GGET, id, key, default) end
    function s.global_set(key, value) return put(H.GSET, H.GSET_BOOL, id, key, value, nil) end
    function s.global_delete(key) return funcLuaCommand(H.GDEL, id, key) end
    s.del, s.gget, s.gset, s.gdel = s.delete, s.global_get, s.global_set, s.global_delete
    function s.commit() return funcLuaCommand(H.COMMIT, id) end
    function s.slot() return funcLuaCommand(H.SLOT) end
    return s
  end
end
