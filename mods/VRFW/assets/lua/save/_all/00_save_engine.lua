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

  VRFW.save = { H = H }

  -- open(id): a handle bound to one mod id.
  function VRFW.save.open(id)
    id = id or caller_id()
    if id == nil then return nil end
    local s = { id = id }
    function s.get(key, default) return funcLuaCommand(H.GET, id, key, default) end
    function s.set(key, value, now) return put(H.SET, H.SET_BOOL, id, key, value, now) end
    function s.delete(key) return funcLuaCommand(H.DEL, id, key) end
    function s.global_get(key, default) return funcLuaCommand(H.GGET, id, key, default) end
    function s.global_set(key, value) return put(H.GSET, H.GSET_BOOL, id, key, value, nil) end
    function s.global_delete(key) return funcLuaCommand(H.GDEL, id, key) end
    s.del, s.gget, s.gset, s.gdel = s.delete, s.global_get, s.global_set, s.global_delete
    function s.commit() return funcLuaCommand(H.COMMIT, id) end
    function s.slot() return funcLuaCommand(H.SLOT) end
    return s
  end
end
