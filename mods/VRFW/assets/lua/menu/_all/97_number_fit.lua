-- menu_engine: number fit, VRFW_NumberFit (VRFW base feature). A bitmap number of a menu layer declared by a mod's
-- [[VRFW.NumberFit]] (content\number_fit\*.toml, answered by scripts\number_fit.lua through CMND_VRFW_NUMBER_FIT) keeps
-- the width its layout was designed for: when the game's *set number* command (0xD72B5ED5: layer, instance, primitive,
-- value) gives one of its primitives a value with more digits than the declaration's `digits`, the layer instance is
-- scaled by digits / value digits around its origin (the number's centre in a centred layout), so 4 digits take the
-- space of 3. Back to fewer digits, the instance goes back to scale 1. The widest primitive of the instance decides.
-- Runs on each number the game sets (the page's own refresh), never per frame. Definitions only (this file runs in
-- every script VM, lua\_all): the command hook is registered here and goes on when the engine stores the command
-- function (VRFW_Host.HookCommand); the declarations are read at the first number set in this VM.
--   VRFW_NumberFit.Rules()   -> { [layer crc] = { digits, both } } of this VM (read once)
--   VRFW_NumberFit.Digits(v) -> digits of a value (its whole part, no sign)
if VRFW_NumberFit == nil then
  local F = {
    SET_NUMBER = 3609943765,                      -- *set number* (layer, instance, primitive, value)
    LIST = VRFW_Cmd.VRFW_NUMBER_FIT,              -- CMND_VRFW_NUMBER_FIT (i) -> layer crc, digits, both
    SCALE = VRFW_Cmd.SET_LAYER_LOCAL_SCALE,       -- CMND_SET_LAYER_LOCAL_SCALE (layer, sx, sy, sz, instance)
    LOG = VRFW_Cmd.EVT_LOG,                       -- CMND_EVT_LOG
    MAX_RULES = 256,
    rules = nil,
    seen = {},                                    -- [layer][instance][primitive] = digits
    applied = {},                                 -- [layer][instance] = scale set last
  }
  VRFW_NumberFit = F

  function F.Rules()
    if F.rules ~= nil then
      return F.rules
    end
    local rules = {}
    for i = 1, F.MAX_RULES do
      local ok, layer, digits, both = pcall(funcLuaCommand, F.LIST, i)
      if not ok or type(layer) ~= "number" or layer == 0 then
        break
      end
      rules[layer] = { digits = tonumber(digits) or 3, both = both == true }
    end
    F.rules = rules
    return rules
  end

  function F.Digits(v)
    v = math.floor(math.abs(tonumber(v) or 0))
    local n = 1
    while v >= 10 do
      v = math.floor(v / 10)
      n = n + 1
    end
    return n
  end

  local function slot(t, layer, instance)
    local l = t[layer]
    if l == nil then
      l = {}
      t[layer] = l
    end
    local s = l[instance]
    if s == nil then
      s = {}
      l[instance] = s
    end
    return s
  end

  function F.Fit(layer, instance, primitive, value)
    local rule = F.Rules()[layer]
    if rule == nil or type(instance) ~= "number" then
      return
    end
    local prims = slot(F.seen, layer, instance)
    prims[primitive or 0] = F.Digits(value)
    local widest = 0
    for _, n in pairs(prims) do
      if n > widest then
        widest = n
      end
    end
    local fit = widest > rule.digits and rule.digits / widest or 1
    local by_layer = F.applied[layer] or {}
    F.applied[layer] = by_layer
    local last = by_layer[instance] or 1
    if fit == 1 and last == 1 then
      return
    end
    VRFW_Host.RealMenuCommand(F.SCALE, layer, fit, rule.both and fit or 1, 1, instance)
    by_layer[instance] = fit
    if fit ~= last then
      pcall(funcLuaCommand, F.LOG, "VRFW number fit", layer, instance, widest, fit)
    end
  end

  VRFW_Host.HookCommand(F.SET_NUMBER, function(nxt, cmd, layer, instance, primitive, value, ...)
    local r = table.pack(nxt(cmd, layer, instance, primitive, value, ...))
    local ok, e = pcall(F.Fit, layer, instance, primitive, value)
    if not ok and not F.failed then
      F.failed = true
      pcall(funcLuaCommand, F.LOG, "VRFW number fit failed", tostring(e))
    end
    return table.unpack(r, 1, r.n)
  end, "VRFW.number_fit", { menu = true })
end
