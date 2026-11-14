-- lua_patch.scope: used
-- menu_engine: header shift, VRFW.header_shift (VRFW base feature).
if VRFW.header_shift == nil then
  local S = {
    RULE = VRFW.commands.VRFW_HEADER_SHIFT,
    SET_POS = VRFW.commands.SET_LAYER_LOCAL_POS,         -- (layer, x, y, z, instance)
    SET_SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,     -- (layer, sx, sy, sz, instance)
    NODE_POSITION = 2575768773,                          -- (layer, instance, node, axis 0 x / 1 y, value): node local translation
    LOG = VRFW.commands.VRFW_LOG,
    OWNER = "VRFW.header_shift",
    MAX_LAYERS = 64,
    CAP = 400,
    stem = nil,
    owners = {},
    layers_cache = nil,                                  -- layer crc -> { dy, scale, x, y, node }
    busy = false,
    count = 0,
    logged = false,
  }
  --- Internal: Namespace: shifts the header layers of a menu by a per-menu rule (dy).
  VRFW.header_shift = S

  local pack, unpack = table.pack, table.unpack

  --- Internal: This VM's declared layers (read once).
  function S.layers()
    if S.layers_cache ~= nil then
      return S.layers_cache
    end
    local layers = {}
    --- Internal: cached list of the layers this VM declares.
    S.layers_cache = layers
    if type(S.stem) ~= "string" then
      return layers
    end
    local stem = VRFW.crc32(S.stem)
    for i = 1, S.MAX_LAYERS do
      local ok, layer, dy, scale, x, y, node = pcall(funcLuaCommand, S.RULE, stem, i)
      if not ok or type(layer) ~= "number" or layer == 0 then
        break
      end
      layers[layer] = { dy = tonumber(dy) or 0, scale = tonumber(scale) or 0, x = tonumber(x) or 0, y = tonumber(y) or 0,
                        node = tonumber(node) or 0 }
    end
    return layers
  end

  --- Internal: True while some owner's header shift is active.
  function S.active()
    for _, when in pairs(S.owners) do
      if when == false then
        return true
      end
      local ok, on = pcall(when)
      if ok and on == true then
        return true
      end
    end
    return false
  end

  local function shift_position(nxt, id, layer, x, y, ...)
    if S.busy or S.count >= S.CAP or type(layer) ~= "number" or type(y) ~= "number" then
      return nxt(id, layer, x, y, ...)
    end
    local rule = S.layers()[layer]
    if rule == nil or rule.node ~= 0 then        -- A list view keeps its retail layer position; its root node moves instead.
      return nxt(id, layer, x, y, ...)
    end
    --- Internal: true while a header shift position call is running, against re-entry.
    S.busy = true
    local active = S.active()
    if not active then
      S.busy = false
      return nxt(id, layer, x, y, ...)
    end
    --- Internal: number of header shifts applied.
    S.count = S.count + 1
    local r = pack(pcall(nxt, id, layer, x, y + rule.dy, ...))   -- layout y is up: + moves the layer up
    S.busy = false
    if not r[1] then
      pcall(funcLuaCommand, S.LOG, "vrfw.HeaderShift", "position", tostring(r[2]))
      return
    end
    return unpack(r, 2, r.n)
  end

  local function setup(layer, instance)
    if S.busy or type(layer) ~= "number" or S.count >= S.CAP or type(funcLuaMenuCommand) ~= "function" then
      return
    end
    local rule = S.layers()[layer]
    if rule == nil then
      return
    end
    local active = S.active()
    local idx = type(instance) == "number" and instance or 0
    if active then                 -- inactive: no call at all, the layer keeps its retail state
      if rule.node ~= 0 then
        -- The list places its rows at its locators' layout positions, so the root node moves them, the scissor and the scroll bar together.
        funcLuaMenuCommand(S.NODE_POSITION, layer, idx, rule.node, 1, rule.dy)
      elseif rule.scale ~= 0 then
        funcLuaMenuCommand(S.SET_SCALE, layer, rule.scale, rule.scale, 1, idx)
        funcLuaMenuCommand(S.SET_POS, layer, rule.x, rule.y - rule.dy, 0, idx)   -- the position hook adds dy
      else
        funcLuaMenuCommand(S.SET_POS, layer, 0, 0, 0, idx)                      -- 0 + dy
      end
    end
    if not S.logged then
      S.logged = true
      pcall(funcLuaCommand, S.LOG, "vrfw.HeaderShift", tostring(S.stem), layer, idx, active and "on" or "off")
    end
  end

  local function stem_here()
    local f = VRFW.patch and VRFW.patch.file
    local dir = type(f) == "string" and f:match("([^/]+)/[^/]+$") or nil
    return dir ~= nil and (dir:gsub("_%d+%.%d+[%.%d]*$", "")) or nil
  end

  --- Internal: Sets the header shift of `owner`; answers true, or false, why.
  function S.apply(owner, when)
    if type(owner) ~= "string" then
      return false, "an owner text expected"
    end
    S.owners[owner] = type(when) == "function" and when or false
    if S.stem ~= nil then
      return true                  -- hooks already in place in this VM
    end
    --- Internal: the stem name of the menu script this VM runs.
    S.stem = stem_here()
    VRFW.host.hook_command(S.SET_POS, shift_position, S.OWNER, {menu = true})
    local function make(orig)
      return function(...)
        local r = pack(orig(...))
        local ok, err = pcall(setup, ...)
        if not ok then
          pcall(funcLuaCommand, S.LOG, "vrfw.HeaderShift", "OnSetupLayer", tostring(err))
        end
        return unpack(r, 1, r.n)
      end
    end
    if not VRFW.host.wrap("OnSetupLayer", make, {stem = S.stem, id = S.OWNER .. ".OnSetupLayer"}) then
      OnSetupLayer = function(layer, instance)
        local ok, err = pcall(setup, layer, instance)
        if not ok then
          pcall(funcLuaCommand, S.LOG, "vrfw.HeaderShift", "OnSetupLayer", tostring(err))
        end
      end
    end
    return true
  end
end
