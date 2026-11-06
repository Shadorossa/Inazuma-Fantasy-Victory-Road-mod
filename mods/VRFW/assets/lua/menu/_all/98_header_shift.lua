-- menu_engine: header shift, VRFW_HeaderShift (VRFW base feature). Root layers of a menu declared by a mod's
-- [[VRFW.HeaderShift]] (content\header_shift\*.toml, answered by scripts\header_shift.lua through
-- CMND_VRFW_HEADER_SHIFT) move up by the declaration's dy, e.g. under a shorter top header:
--   * when the menu sets up such a layer (OnSetupLayer), the layer is placed at 0 + dy (a stretch layer: scaled and
--     placed so its top moves up while its bottom and right edges stay);
--   * every CMND_SET_LAYER_LOCAL_POS the menu sends for such a layer gets + dy on y, so its own slide-ins and list
--     scrolls keep working on top of it. A layer attached to a shifted one follows it.
-- Definitions only (this file runs in every script VM, lua\_all). A hook file of the menu's script turns it on:
--   VRFW_HeaderShift.Apply(owner [, when])
--     owner  "<mod>.<feature>" (one registration per owner)
--     when   optional function() -> bool: the shift applies while it says true (no when = always)
--   The stem is the hook file's script; the declarations are read at the first use in this VM. A second Apply in the
--   same VM adds its owner: the shift applies while any owner's when holds.
-- Re-entrancy guard and hard cap: a nested position call passes through unchanged, and after CAP shifted calls the
-- block stops acting in this VM.
if VRFW_HeaderShift == nil then
  local S = {
    RULE = VRFW_Cmd.VRFW_HEADER_SHIFT,              -- CMND_VRFW_HEADER_SHIFT (stem crc, i) -> layer, dy, scale, x, y
    SET_POS = VRFW_Cmd.SET_LAYER_LOCAL_POS,         -- (layer, x, y, z, instance)
    SET_SCALE = VRFW_Cmd.SET_LAYER_LOCAL_SCALE,     -- (layer, sx, sy, sz, instance)
    LOG = VRFW_Cmd.EVT_LOG,
    OWNER = "VRFW.header_shift",
    MAX_LAYERS = 64,
    CAP = 400,
    stem = nil,
    owners = {},                                   -- owner -> when (false = always)
    layers = nil,                                  -- layer crc -> { dy, scale, x, y }
    busy = false,
    count = 0,
    logged = false,
  }
  VRFW_HeaderShift = S

  local pack, unpack = table.pack, table.unpack

  -- this VM's declared layers (read once)
  function S.Layers()
    if S.layers ~= nil then
      return S.layers
    end
    local layers = {}
    S.layers = layers
    if type(S.stem) ~= "string" then
      return layers
    end
    local stem = VRFW_Crc32(S.stem)
    for i = 1, S.MAX_LAYERS do
      local ok, layer, dy, scale, x, y = pcall(funcLuaCommand, S.RULE, stem, i)
      if not ok or type(layer) ~= "number" or layer == 0 then
        break
      end
      layers[layer] = { dy = tonumber(dy) or 0, scale = tonumber(scale) or 0, x = tonumber(x) or 0, y = tonumber(y) or 0 }
    end
    return layers
  end

  function S.Active()
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
    local rule = S.Layers()[layer]
    if rule == nil then
      return nxt(id, layer, x, y, ...)
    end
    S.busy = true
    local active = S.Active()
    if not active then
      S.busy = false
      return nxt(id, layer, x, y, ...)
    end
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
    local rule = S.Layers()[layer]
    if rule == nil then
      return
    end
    local active = S.Active()
    local idx = type(instance) == "number" and instance or 0
    if active then                 -- inactive: no call at all, the layer keeps its retail state
      if rule.scale ~= 0 then
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
    local f = EVT_PATCH and EVT_PATCH.file
    local dir = type(f) == "string" and f:match("([^/]+)/[^/]+$") or nil
    return dir ~= nil and (dir:gsub("_%d+%.%d+[%.%d]*$", "")) or nil
  end

  function S.Apply(owner, when)
    if type(owner) ~= "string" then
      return false
    end
    S.owners[owner] = type(when) == "function" and when or false
    if S.stem ~= nil then
      return true                  -- hooks already in place in this VM
    end
    S.stem = stem_here()
    VRFW_Host.HookCommand(S.SET_POS, shift_position, S.OWNER, {menu = true})
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
    if not VRFW_Host.wrap("OnSetupLayer", make, {stem = S.stem, id = S.OWNER .. ".OnSetupLayer"}) then
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
