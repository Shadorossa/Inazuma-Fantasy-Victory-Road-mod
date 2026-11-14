-- VRFW › image spill, menu side (every script VM).
if VRFW.image_spill == nil then
  local S = {
    SET_SPRITE = 558735651,
    LOAD_TEX = VRFW.commands.LOAD_MENU_RES_TEXTURE,
    TEX_LOADING = 1506186496,   -- (texture id) -> true while it loads (funcLuaCommand)
    ATLASES = VRFW.commands.VRFW_IMAGE_SPILL_ATLASES,
    FIND = VRFW.commands.VRFW_IMAGE_SPILL_FIND,
    SIBLINGS = VRFW.commands.VRFW_IMAGE_SPILL_SIBLINGS,
    OWN_ATLASES = VRFW.commands.VRFW_SPRITE_REDIRECT_ATLASES,
    LOG = VRFW.commands.VRFW_LOG,           -- CMND_VRFW_LOG
    atlases = nil,
    any = false,
    found = {},                 -- [atlas][sprite] -> { id, path } or false
    by_path = {},               -- game atlas path -> { { id, path } of a sibling atlas, ... }
    loaded = {},                -- sibling texture id -> true once asked to load in this VM
    pending = {},
    waiting = false,
    hooked = false,
    own_asked = false,
    own_tries = 0,
    own_loaded = {},            -- own atlas path -> true once loaded in this VM
    own_by_game = nil,
    own_count = 0,              -- own atlases this VM loaded itself
    own_shared = 0,
    holder = false,
    shared = false,
  }
  --- Internal: State of the image spill: moves menu image atlases to a second holder when the first is full.
  VRFW.image_spill = S

  local function unsigned(v)
    if type(v) == "number" and v < 0 then return v + 4294967296 end
    return v
  end

  local function read_atlases()
    --- Internal: atlases read from the spill command, by index.
    S.atlases = {}
    local ok, n = pcall(funcLuaCommand, S.ATLASES, 0)
    if ok and type(n) == "number" then
      for i = 1, n do
        local o, id = pcall(funcLuaCommand, S.ATLASES, i)
        if o and type(id) == "number" then S.atlases[unsigned(id)] = true end
      end
    end
    --- Internal: True when at least one atlas is registered for the spill.
    S.any = next(S.atlases) ~= nil
  end

  local function find(tex, spr)
    local t = unsigned(tex)
    local row = S.found[t]
    if row == nil then row = {} S.found[t] = row end
    local s = unsigned(spr)
    local hit = row[s]
    if hit == nil then
      local ok, id, path = pcall(funcLuaCommand, S.FIND, tex, spr)
      hit = (ok and type(id) == "number" and type(path) == "string") and { id = unsigned(id), path = path } or false
      row[s] = hit
    end
    return hit
  end

  local function load(real, hit, why)
    if S.loaded[hit.id] then return end
    S.loaded[hit.id] = true
    pcall(real, S.LOAD_TEX, hit.path)
    pcall(funcLuaCommand, S.LOG, "VRFW image spill: loading " .. hit.path .. " (" .. why .. ")")
  end

  local function loading(id)
    local b = VRFW.host.command(S.TEX_LOADING, id)
    return b == true
  end

  -- The sprite calls that waited for their sibling atlas, made again once it is in.
  local function replay(real)
    local left = false
    for key, w in pairs(S.pending) do
      if loading(w.id) then
        left = true
      else
        S.pending[key] = nil
        pcall(real, table.unpack(w.args, 1, w.args.n))
      end
    end
    --- Internal: count of atlases still waiting to be handled.
    S.waiting = left
  end

  local function held(id)
    local b = VRFW.host.command(S.TEX_LOADING, id)
    return b ~= nil
  end

  local function load_own_atlas(real, path)
    local id = unsigned(VRFW.crc32(path))
    if not S.own_loaded[path] then
      S.own_loaded[path] = true
      if S.shared then
        S.own_shared = S.own_shared + 1
      else
        pcall(real, S.LOAD_TEX, path)
        S.own_count = S.own_count + 1
      end
    end
    return loading(id), id
  end

  local function load_own_for(real, game)
    local list = S.own_by_game[game]
    if list == nil then return nil end
    S.own_by_game[game] = nil
    local wait = nil
    for _, own in ipairs(list) do
      local busy, id = load_own_atlas(real, own)
      if busy then wait = id end
    end
    return wait
  end

  local function own_ask(...)
    local v = VRFW.host.command(S.OWN_ATLASES, ...)
    if v == nil then return nil, false end
    return v, true
  end

  local function load_own(real)
    if _ENV.__menuObjPtr == nil then return false end
    --- Internal: image ids the game itself holds in this menu.
    S.own_by_game = {}
    local n, an = own_ask(0)
    if not an then return false end
    if type(n) ~= "number" then return true end   -- a failure answer: the command has no list
    local on, aon = own_ask(-1, 0)
    if not aon then return false end
    --- Internal: true when a second holder also takes the shared images.
    S.shared = on == true   -- a second holder takes them from the first one too
    local complete = true
    for i = 1, n do
      local path, ap = own_ask(i, 0)
      if not ap then
        complete = false
      elseif type(path) == "string" and (S.holder or S.shared) then
        load_own_atlas(real, path)
      elseif type(path) == "string" then
        local games, now = {}, false
        -- a bounded walk over the count the command gives (it answers 0, not nil, past the last id)
        local count, ac = own_ask(i, -1)
        local asked = ac
        for k = 1, math.min(ac and tonumber(count) or 0, 8) do
          local id, ag = own_ask(i, k)
          if not ag then asked = false break end
          if type(id) ~= "number" or id == 0 then break end
          games[#games + 1] = unsigned(id)
          if not now and held(id) then now = true end
        end
        if not asked then
          complete = false
        elseif now or #games == 0 then
          load_own_atlas(real, path)
        else
          for _, id in ipairs(games) do
            local list = S.own_by_game[id]
            if list == nil then
              list = {}
              S.own_by_game[id] = list
            end
            list[#list + 1] = path
          end
        end
      end
    end
    if not complete then return false end
    if S.holder and not S.shared and n > 0 then pcall(funcLuaCommand, S.OWN_ATLASES, -1, 1) end
    -- one line per holder menu, and per other menu that had to load own atlases itself
    if S.holder or S.own_count > 0 then
      pcall(funcLuaCommand, 3626744379 --[[CMND_VRFW_LOG_DEBUG]], string.format("VRFW sprite redirect: %s %s: %d of %d own atlas(es) loaded here, %d taken from a holder",
        S.holder and "holder" or "menu", tostring(type(S.holder) == "string" and S.holder or _ENV.__menuObjName or "?"),
        S.own_count, n, S.own_shared))
    end
    return true
  end

  local OWN_TRIES = 4
  local function ask_own(real)
    if load_own(real) then
      S.own_asked = true
    elseif _ENV.__menuObjPtr ~= nil then
      S.own_tries = S.own_tries + 1
      if S.own_tries >= OWN_TRIES then
        S.own_asked = true
        pcall(funcLuaCommand, S.LOG, string.format("VRFW sprite redirect: %s: own atlases not asked: the scripts were busy %d time(s)",
          tostring(_ENV.__menuObjName or "?"), S.own_tries))
      end
    end
  end

  local function make(real)
    local function load_game_atlas(path, ...)
      if S.atlases == nil then read_atlases() end
      if not S.any then
        return real(...)
      end
      local list = S.by_path[path]
      if list == nil then
        list = {}
        local ok, n = pcall(funcLuaCommand, S.SIBLINGS, path, 0)
        if ok and type(n) == "number" then
          for i = 1, n do
            local o, p, id = pcall(funcLuaCommand, S.SIBLINGS, path, i)
            if o and type(p) == "string" and type(id) == "number" then list[#list + 1] = { id = unsigned(id), path = p } end
          end
        end
        S.by_path[path] = list
      end
      local r = table.pack(real(...))
      for _, sib in ipairs(list) do load(real, sib, "with " .. path) end
      return table.unpack(r, 1, r.n)
    end

    local function handle(...)
      local cmd = ...
      if S.waiting then replay(real) end
      if cmd == S.SET_SPRITE then
        local _, layer, tex, spr, slot, _, inst = ...
        local key = tostring(layer) .. " " .. tostring(slot) .. " " .. tostring(inst)
        S.pending[key] = nil   -- a newer sprite for the same place
        if tex ~= nil and S.own_by_game ~= nil and next(S.own_by_game) ~= nil then
          local game = type(tex) == "string" and unsigned(VRFW.crc32(tex)) or unsigned(tex)
          local wait = load_own_for(real, game)
          if wait ~= nil then
            S.pending[key] = { id = wait, args = table.pack(...) }
            S.waiting = true
          end
        end
        if S.atlases == nil then read_atlases() end
        if S.any then
          if tex ~= nil and spr ~= nil and (type(tex) == "string" or S.atlases[unsigned(tex)]) then
            local hit = find(tex, spr)
            if hit then
              local args = table.pack(...)
              args[3] = hit.id
              load(real, hit, "sprite " .. tostring(spr))
              if loading(hit.id) then
                S.pending[key] = { id = hit.id, args = args }
                S.waiting = true
              else
                S.pending[key] = nil
              end
              return real(table.unpack(args, 1, args.n))
            end
          end
        end
      elseif cmd == S.LOAD_TEX then
        local _, path = ...
        if type(path) == "string" then
          if S.own_by_game == nil or next(S.own_by_game) == nil then
            return load_game_atlas(path, ...)
          end
          local r = table.pack(load_game_atlas(path, ...))
          load_own_for(real, unsigned(VRFW.crc32(path)))
          return table.unpack(r, 1, r.n)
        end
      end
      return real(...)
    end

    return function(...)
      if not S.own_asked and (S.own_tries == 0 or (...) == S.LOAD_TEX) then
        local r = table.pack(handle(...))
        ask_own(real)
        return table.unpack(r, 1, r.n)
      end
      return handle(...)
    end
  end

  local current = rawget(_ENV, "funcLuaMenuCommand")
  if type(current) == "function" then
    --- Internal: true once funcLuaMenuCommand is wrapped for the spill.
    S.hooked = true
    rawset(_ENV, "funcLuaMenuCommand", make(current))
  else
    local okm, meta = pcall(getmetatable, _ENV)
    if okm and (meta == nil or type(meta) == "table") then
      if meta == nil then
        meta = {}
        if not pcall(setmetatable, _ENV, meta) then meta = nil end
      end
      if meta ~= nil then
        local previous = meta.__newindex
        meta.__newindex = function(globals, k, v)
          if previous == nil then
            rawset(globals, k, v)
          elseif type(previous) == "function" then
            previous(globals, k, v)
          else
            previous[k] = v
          end
          if k == "funcLuaMenuCommand" and type(v) == "function" and not S.hooked then
            local stored = rawget(globals, k)
            if type(stored) == "function" then
              S.hooked = true
              rawset(globals, k, make(stored))
            end
          end
        end
      end
    end
  end
end
