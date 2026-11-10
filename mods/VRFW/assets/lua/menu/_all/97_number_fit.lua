-- menu_engine: number fit, VRFW.number_fit (VRFW base feature).
if VRFW.number_fit == nil then
  local F = {
    SET_NUMBER = 3609943765,                      -- *set number* (layer, instance, primitive, value)
    LIST = VRFW.commands.VRFW_NUMBER_FIT,              -- CMND_VRFW_NUMBER_FIT (i) -> layer crc, digits, both, node crc, number crc
    SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,       -- CMND_SET_LAYER_LOCAL_SCALE (layer, sx, sy, sz, instance)
    NODE_SCALE = 2885415772,                      -- (layer, instance, node, sx, sy): the local scale of a joint
    PRIMITIVE_INDEX = VRFW.commands.SEARCH_PRIM_INDEX, -- CMND_SEARCH_PRIM_INDEX (layer, instance, number crc) -> primitive index
    LOG = VRFW.commands.VRFW_LOG,                       -- CMND_VRFW_LOG
    MAX_RULES = 256,
    rules_cache = nil,
    seen = {},                                    -- [layer][instance][primitive] = digits
    applied = {},                                 -- [layer][instance] = scale set last
    node_rules_cache = nil,                       -- [layer] = list of { digits, both, node, number }
    node_applied = {},                            -- [layer][instance][node] = scale set last
  }
  VRFW.number_fit = F

  --- The declared number-fit rules, by layer (read once).
  function F.rules()
    if F.rules_cache ~= nil then
      return F.rules_cache
    end
    local rules, node_rules = {}, {}
    for i = 1, F.MAX_RULES do
      local ok, layer, digits, both, node, number = pcall(funcLuaCommand, F.LIST, i)
      if not ok or type(layer) ~= "number" or layer == 0 then
        break
      end
      local rule = { digits = tonumber(digits) or 3, both = both == true }
      if type(node) == "number" and node ~= 0 then
        rule.node, rule.number = node, tonumber(number) or 0
        node_rules[layer] = node_rules[layer] or {}
        table.insert(node_rules[layer], rule)
      else
        rules[layer] = rule
      end
    end
    F.rules_cache = rules
    F.node_rules_cache = node_rules
    return rules
  end

  --- The number of decimal digits of v.
  function F.digits(v)
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

  --- Scales the joint of one number of (layer, instance) when the number is the rule's and has more digits than the rule's.
  function F.fit_node(rule, layer, instance, primitive, value)
    if VRFW.host.real_menu_command(F.PRIMITIVE_INDEX, layer, instance, rule.number) ~= primitive then
      return
    end
    local count = F.digits(value)
    local fit = count > rule.digits and rule.digits / count or 1
    local nodes = slot(F.node_applied, layer, instance)
    local last = nodes[rule.node] or 1
    if fit == 1 and last == 1 then
      return
    end
    VRFW.host.real_menu_command(F.NODE_SCALE, layer, instance, rule.node, fit, rule.both and fit or 1)
    nodes[rule.node] = fit
    if fit ~= last then
      VRFW.host.command(F.LOG, "VRFW number fit", layer, instance, "node", rule.node, count, fit)
    end
  end

  --- Scales the number on (layer, instance, primitive) to fit its rule.
  function F.fit(layer, instance, primitive, value)
    local rule = F.rules()[layer]
    local node_rules = F.node_rules_cache[layer]
    if node_rules ~= nil and type(instance) == "number" then
      for _, node_rule in ipairs(node_rules) do
        F.fit_node(node_rule, layer, instance, primitive, value)
      end
    end
    if rule == nil or type(instance) ~= "number" then
      return
    end
    local prims = slot(F.seen, layer, instance)
    prims[primitive or 0] = F.digits(value)
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
    VRFW.host.real_menu_command(F.SCALE, layer, fit, rule.both and fit or 1, 1, instance)
    by_layer[instance] = fit
    if fit ~= last then
      pcall(funcLuaCommand, F.LOG, "VRFW number fit", layer, instance, widest, fit)
    end
  end

  VRFW.host.hook_command(F.SET_NUMBER, function(nxt, cmd, layer, instance, primitive, value, ...)
    local r = table.pack(nxt(cmd, layer, instance, primitive, value, ...))
    local ok, e = pcall(F.fit, layer, instance, primitive, value)
    if not ok and not F.failed then
      F.failed = true
      pcall(funcLuaCommand, F.LOG, "VRFW number fit failed", tostring(e))
    end
    return table.unpack(r, 1, r.n)
  end, "VRFW.number_fit", { menu = true })
end
