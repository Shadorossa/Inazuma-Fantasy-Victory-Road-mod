-- lua_patch.scope: used
-- menu_engine: UNLIMITED COPIES (VRFW base feature; docs/framework/unlimited-copies.md).
if VRFW.copies == nil then
  local M = {
    RULES = VRFW.commands.VRFW_UNLIMITED_COPIES_RULES,
    SLOT = VRFW.commands.VRFW_UNLIMITED_COPIES_SLOT,         -- CMND_VRFW_UNLIMITED_COPIES_SLOT () -> 1 / -1 / -2
    CAP = VRFW.commands.VRFW_UNLIMITED_COPIES_CAP,
    ITEM_NUM = VRFW.commands.GET_ITEM_NUM,     -- CMND_GET_ITEM_NUM (item) = the stock
    CLEAR_GET = VRFW.commands.GET_CHRONICLE_CLEAR_STATUS,
    ADD = VRFW.commands.ADD_ITEM_ONLY,
    DEL = VRFW.commands.DELETE_ITEM,           -- CMND_DELETE_ITEM (item, count)
    rules = {},                -- item -> its rules (static per VM)
    all = nil,                 -- every declared rule (static per VM)
    state = {},
    slot = nil,                -- slot answer (until Reset)
  }
  VRFW.copies = M

  local function u32(v) return VRFW.ids.unsigned(v) end

  local logger
  --- Logs through the unlimited-copies logger.
  function M.log(...)
    logger = logger or VRFW.logger.new("unlimited_copies")
    logger(...)
  end

  -- a flat rule { chroniclesDifficulty, nKeys, key…, nClears, statusFlagIndex, difficulty, … } -> a table
  local function parse(flat)
    if type(flat) ~= "table" then
      return nil
    end
    local r = {chronicles = tonumber(flat[1]) or 0, keys = {}, clears = {}}
    local i, nk = 3, tonumber(flat[2]) or 0
    for _ = 1, nk do
      r.keys[#r.keys + 1] = u32(flat[i])
      i = i + 1
    end
    local nc = tonumber(flat[i]) or 0
    i = i + 1
    for _ = 1, nc do
      r.clears[#r.clears + 1] = {tonumber(flat[i]) or 0, tonumber(flat[i + 1]) or 2}
      i = i + 2
    end
    return r
  end

  local function parse_list(got)
    local out = {}
    if type(got) == "table" then
      for _, flat in ipairs(got) do
        local r = parse(flat)
        if r ~= nil then
          out[#out + 1] = r
        end
      end
    end
    return out
  end

  local function rules_of(item)
    local r = M.rules[item]
    if r == nil then
      local got = VRFW.host.command(M.RULES, item)
      if type(got) ~= "table" then
        return {}                                  -- no answer: asked again next time
      end
      r = parse_list(got)
      M.rules[item] = r
    end
    return r
  end

  local function owned(r)
    if #r.keys == 0 and #r.clears == 0 then
      return true
    end
    for _, k in ipairs(r.keys) do
      local ok, n = pcall(funcLuaCommand, M.ITEM_NUM, k)
      if ok and (tonumber(n) or 0) > 0 then
        return true
      end
    end
    for _, c in ipairs(r.clears) do
      local ok, v = pcall(funcLuaCommand, M.CLEAR_GET, c[1], c[2])
      if ok and v == true then
        return true
      end
    end
    return false
  end

  local function holds(r)
    if not owned(r) then
      return false
    end
    if r.chronicles > 0 then
      if VRFW.chronicle == nil then
        return false                               -- no completion service: never by accident
      end
      local ok, done = pcall(VRFW.chronicle.complete, r.chronicles)
      return ok and done == true
    end
    return true
  end

  --- Forgets the cached state, the slot and the hidden counters.
  function M.reset()
    M.state, M.slot, M.hidden = {}, nil, nil
    if VRFW.chronicle ~= nil then
      pcall(VRFW.chronicle.reset)
    end
  end

  --- True when the active save slot is the one the rule covers.
  function M.slot_ok()
    if M.slot == nil then
      local st = VRFW.host.command(M.SLOT)
      if type(st) ~= "number" then
        return false                               -- no answer: asked again next time
      end
      M.slot = st
    end
    return M.slot == 1
  end

  --- True when item `item` has unlimited copies in this save.
  function M.unlimited(item)
    item = u32(item)
    if item == 0 then
      return false
    end
    local s = M.state[item]
    if s ~= nil then
      return s
    end
    s = false
    local list = (M.any_rule() and M.slot_ok()) and rules_of(item) or {}
    if #list > 0 then
      for _, r in ipairs(list) do
        if holds(r) then
          s = true
          break
        end
      end
    end
    M.state[item] = s
    return s
  end

  --- Some active mod declares a rule (no answer = no, asked again next time).
  function M.any_rule()
    if M.all == nil then
      local got = VRFW.host.command(M.RULES)
      if type(got) ~= "table" then
        return false
      end
      M.all = parse_list(got)
    end
    return #M.all > 0
  end

  --- True when an unlimited rule covers `key` and it is owned.
  function M.owned(key)
    key = u32(key)
    if not M.any_rule() then
      return false
    end
    for _, r in ipairs(M.all) do
      for _, k in ipairs(r.keys) do
        if k == key and owned(r) then
          return true
        end
      end
    end
    return false
  end

  M.STOCK_MESHES = {1202991162 --[[_base_equip01]], 1139638886 --[[_gtxt_equip01]], 1087832946,
    1228576956 --[[_base_have01]], 2037408502 --[[_icon_have01]], 132349475}

  --- Hides the stock counters of a list row.
  function M.hide_counters(layer, inst)
    funcLuaMenuCommand(2158717427, layer, 442049775 --[[_pos_equip01]], false, inst)
    funcLuaMenuCommand(2158717427, layer, 3426045766 --[[_pos_have01]], false, inst)
    for _, m in ipairs(M.STOCK_MESHES) do
      pcall(funcLuaMenuCommand, VRFW.commands.SET_MESH_VISIBLE, layer, m, false, inst)
    end
    funcLuaMenuCommand(1233047821 --[[number visible]], layer, inst, 3974820126 --[[num_equip01]], false)
    funcLuaMenuCommand(1233047821 --[[number visible]], layer, inst, 3334923667 --[[num_have01]], false)
  end

  --- Shows the stock counters of a list row again.
  function M.show_counters(layer, inst)
    funcLuaMenuCommand(2158717427, layer, 442049775 --[[_pos_equip01]], true, inst)
    funcLuaMenuCommand(2158717427, layer, 3426045766 --[[_pos_have01]], true, inst)
    funcLuaMenuCommand(1233047821 --[[number visible]], layer, inst, 3974820126 --[[num_equip01]], true)
    funcLuaMenuCommand(1233047821 --[[number visible]], layer, inst, 3334923667 --[[num_have01]], true)
  end

  --- Sets up the counters of a list row for `item`; answers true when the item is unlimited.
  function M.list_row(layer, inst, item)
    if not M.unlimited(item) then
      if M.hidden ~= nil and M.hidden[layer .. ":" .. inst] then
        M.hidden[layer .. ":" .. inst] = nil
        M.show_counters(layer, inst)               -- a reused instance that held an unlimited row
      end
      return false
    end
    M.hidden = M.hidden or {}
    M.hidden[layer .. ":" .. inst] = true
    M.hide_counters(layer, inst)
    return true
  end

  local function num(item)
    local n = VRFW.host.command(M.ITEM_NUM, item)
    return tonumber(n) or 0
  end

  --- The current stock of each item id, as a table.
  function M.snapshot(items)
    local t = {}
    for _, id in ipairs(items) do
      id = u32(id)
      if id ~= 0 and t[id] == nil and M.unlimited(id) then
        local c = num(id)
        if c >= 1 then
          t[id] = c                                -- only owned items: an item is never created or emptied
        end
      end
    end
    return t
  end

  --- Gives back the stock added since `before` (table from snapshot).
  function M.restore(before, handleOf)
    for id, s0 in pairs(before) do
      local now = num(id)
      if now > s0 then
        local h, extra = handleOf ~= nil and handleOf(id) or nil, false
        if h == nil or h == 0 then                 -- not on this board: the stack's handle the retail way
          h = funcLuaCommand(M.ADD, id, 1, false) or 0
          extra = true
          now = num(id)
        end
        local okC, st, e0, e1 = pcall(funcLuaCommand, M.CAP, h, id, now, s0)
        if okC and st == 1 then
          funcLuaCommand(M.DEL, id, now - s0)
        elseif extra then
          funcLuaCommand(M.DEL, id, 1)             -- at least undo the own copy
        end
        local after = num(id)
        M.log("equip keeps the owned count", string.format("%08X", id), "owned", s0, "after equip", now,
          "equipped", tostring(e0), "->", tostring(e1), "status", tostring(st), "now", after,
          after == s0 and "OK" or "NOT RESTORED")
      end
    end
  end
end
