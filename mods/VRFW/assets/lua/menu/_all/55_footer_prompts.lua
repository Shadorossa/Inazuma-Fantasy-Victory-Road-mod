-- lua_patch.scope: used
-- menu_engine: footer prompts, VRFW.FooterPrompts (VRFW base feature).
if VRFW.footer_prompts == nil then
  local F = {
    GUIDE = 1138543975,          -- mainmenu01_06_base_button_guide
    GUIDE_TEXTS = 2209673388,    -- (menu, guide, texts, glyphs, offsets, spare1, spare2)
    GUIDE_KEYS = 452337289,      -- (menu, guide, commands)
    STEP = 18,
    decls = {},                  -- name -> declaration
    attached = {},
    wrapping = {},
  }
  VRFW.footer_prompts = F

  local logger
  --- Logs through the footer-prompts logger.
  function F.log(...)
    logger = logger or VRFW.logger.new("vrfw.FooterPrompts")
    logger(...)
  end

  --- Adds a footer prompt; answers true, or false, why.
  function F.add(d)
    if type(d) ~= "table" or type(d.name) ~= "string" or type(d.menu) ~= "string" or type(d.text) ~= "number"
        or type(d.icon) ~= "number" then
      return false, "a prompt needs a name, a menu, a text and an icon"
    end
    F.decls[d.name] = d
    return true
  end

  local function shown(d)
    local w = d.when
    if w == nil then
      return true
    end
    local ok, on
    if type(w) == "function" then
      ok, on = pcall(w)
    else
      ok, on = pcall(funcLuaCommand, w)
    end
    if not ok then
      if not d.warned then
        d.warned = true
        F.log(d.name .. ": when failed: " .. tostring(on))
      end
      return false
    end
    return on == true
  end

  --- The shown entries of a menu, in order.
  function F.entries(menu)
    local list = {}
    for _, d in pairs(F.decls) do
      if d.menu == menu and shown(d) then
        list[#list + 1] = d
      end
    end
    table.sort(list, function(a, b)
      local oa, ob = a.order or 0, b.order or 0
      if oa ~= ob then
        return oa < ob
      end
      return a.name < b.name
    end)
    return list
  end

  local function push(texts, glyphs, offs, s1, s2, cmds, d)
    texts[#texts + 1] = d.text
    glyphs[#glyphs + 1] = d.icon
    if type(offs) == "table" then
      local last = offs[#offs]
      offs[#offs + 1] = (type(last) == "number") and (last + F.STEP) or (#offs * F.STEP)
    end
    if type(s1) == "table" then
      s1[#s1 + 1] = 0
    end
    if type(s2) == "table" then
      s2[#s2 + 1] = 0
    end
    if type(cmds) == "table" then
      cmds[#cmds + 1] = d.command or 0
    end
  end

  -- the position of the script's entry a declaration replaces (its Replaces glyph), nil = none / not there
  local function replaced_position(glyphs, d)
    if type(d.replaces) ~= "number" then
      return nil
    end
    for i = 1, #glyphs do
      if glyphs[i] == d.replaces then
        return i
      end
    end
    return nil
  end

  -- adds the shown entries to the text tables (in place): a Replaces entry over the script's entry, the others appended.
  local function add_entries(list, texts, glyphs, offs, s1, s2, cmds)
    local replaced, appended = {}, {}
    for _, d in ipairs(list) do
      local at = replaced_position(glyphs, d)
      if at ~= nil and replaced[at] == nil then
        texts[at], glyphs[at] = d.text, d.icon
        replaced[at] = d
        if type(cmds) == "table" then
          cmds[at] = d.command or cmds[at]
        end
      else
        push(texts, glyphs, offs, s1, s2, cmds, d)
        appended[#appended + 1] = d
      end
    end
    return replaced, appended
  end

  --- Adds the shown entries of a menu to the guide tables (in place); returns how many.
  function F.apply(menu, texts, glyphs, offs, s1, s2, cmds)
    if type(texts) ~= "table" or type(glyphs) ~= "table" then
      return 0
    end
    local list = F.entries(menu)
    add_entries(list, texts, glyphs, offs, s1, s2, cmds)
    return #list
  end

  local function copy(t)
    local r = {}
    for i = 1, #t do
      r[i] = t[i]
    end
    return r
  end

  --- Replaces the footer of `menu` with `entries`; answers how many it wrote.
  function F.set(stem, menu, entries, options)
    local o = type(options) == "table" and options or { guide = options }
    local texts, glyphs, offs, s1, s2, cmds = {}, {}, {}, {}, {}, {}
    for _, d in ipairs(type(entries) == "table" and entries or {}) do
      push(texts, glyphs, offs, s1, s2, cmds, d)
      if type(d.offset) == "number" then
        offs[#offs] = d.offset
      end
    end
    if o.declared ~= false and (F.wrapping[stem] or 0) == 0 then   -- inside an Attach wrap the wrap adds them
      F.apply(stem, texts, glyphs, offs, s1, s2, cmds)
    end
    local layer = o.guide or F.GUIDE
    local call = o.call or funcLuaMenuCommand
    pcall(call, F.GUIDE_TEXTS, menu, layer, texts, glyphs, offs, s1, s2)
    pcall(call, F.GUIDE_KEYS, menu, layer, cmds)
    return #texts
  end

  F.hides = {}                   -- name -> hide declaration
  F.hidden_places = {}

  local function hide_place(d, texts, glyphs)
    local list = type(d.text) == "number" and texts or glyphs
    local id = type(d.text) == "number" and d.text or d.icon
    if type(list) ~= "table" then
      return nil
    end
    for i = 1, #list do
      if list[i] == id then
        return i
      end
    end
    return nil
  end

  local function without_place(list, place)
    local out = {}
    for i = 1, #list do
      if i ~= place then
        out[#out + 1] = list[i]
      end
    end
    return out
  end

  local function hide_texts(nxt, ...)
    local args = table.pack(...)
    local layer = args[3]
    local places = {}
    if type(args[4]) == "table" then
      local names = {}
      for name in pairs(F.hides) do
        names[#names + 1] = name
      end
      table.sort(names)
      for _, name in ipairs(names) do
        local d = F.hides[name]
        if (d.layer == nil or d.layer == layer) and shown(d) then
          local place = hide_place(d, args[4], args[5])
          if place ~= nil then
            local size = #args[4]
            for k = 4, args.n do
              if type(args[k]) == "table" and #args[k] == size then
                args[k] = without_place(args[k], place)
              end
            end
            places[#places + 1] = place
          end
        end
      end
    end
    F.hidden_places[tostring(args[2]) .. ":" .. tostring(layer)] = #places > 0 and places or nil
    return nxt(table.unpack(args, 1, args.n))
  end

  local function hide_keys(nxt, ...)
    local args = table.pack(...)
    local key = tostring(args[2]) .. ":" .. tostring(args[3])
    local places = F.hidden_places[key]
    if places ~= nil and type(args[4]) == "table" then
      F.hidden_places[key] = nil
      for _, place in ipairs(places) do
        args[4] = without_place(args[4], place)
      end
      return nxt(table.unpack(args, 1, args.n))
    end
    return nxt(...)
  end

  --- Hides a retail footer prompt; answers true, or false, why.
  function F.hide(d)
    if type(d) ~= "table" or type(d.name) ~= "string" or (type(d.text) ~= "number" and type(d.icon) ~= "number") then
      return false, "a name and a text or an icon expected"
    end
    F.hides[d.name] = d
    if not F.hide_hooked and VRFW.host ~= nil and VRFW.host.hook_command ~= nil then
      F.hide_hooked = true
      VRFW.host.hook_command(F.GUIDE_TEXTS, hide_texts, "vrfw.FooterPrompts.Hide", { menu = true })
      VRFW.host.hook_command(F.GUIDE_KEYS, hide_keys, "vrfw.FooterPrompts.HideKeys", { menu = true })
    end
    return true
  end

  -- the guide call of a script with the entries added: runs nxt(...) with the two guide commands rewritten
  local function call_with_entries(stem, layers, nxt, ...)
    local list = F.entries(stem)
    if #list == 0 or type(funcLuaMenuCommand) ~= "function" then
      return nxt(...)
    end
    F.wrapping[stem] = (F.wrapping[stem] or 0) + 1
    local orig = funcLuaMenuCommand
    local replaced, appended = {}, {}
    funcLuaMenuCommand = function(cmd, menu, lay, a, b, c, d, e, ...)
      if layers[lay] and cmd == F.GUIDE_TEXTS and type(a) == "table" and type(b) == "table" then
        a, b = copy(a), copy(b)
        c = type(c) == "table" and copy(c) or c
        d = type(d) == "table" and copy(d) or d
        e = type(e) == "table" and copy(e) or e
        replaced, appended = add_entries(list, a, b, c, d, e, nil)
      elseif layers[lay] and cmd == F.GUIDE_KEYS and type(a) == "table" then
        a = copy(a)
        for at, x in pairs(replaced) do
          a[at] = x.command or a[at]
        end
        for _, x in ipairs(appended) do
          a[#a + 1] = x.command or 0
        end
      end
      return orig(cmd, menu, lay, a, b, c, d, e, ...)
    end
    local r = table.pack(pcall(nxt, ...))
    funcLuaMenuCommand = orig
    F.wrapping[stem] = F.wrapping[stem] - 1
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  --- Adds the shown entries to footer function `fn` of `stem`; answers true, or false, why.
  function F.attach(stem, fn, guide)
    local key = stem .. "/" .. fn
    if F.attached[key] then
      return false, "already attached"
    end
    local layer = {}
    for _, g in ipairs(type(guide) == "table" and guide or { guide or F.GUIDE }) do
      layer[g] = true
    end
    local host = VRFW.host ~= nil and type(VRFW.host.hosts) == "table" and VRFW.host.hosts[stem] ~= nil
    if host and VRFW.host.on ~= nil then
      F.attached[key] = true
      VRFW.host.on(stem, fn, {id = "vrfw.FooterPrompts", phase = "around", fn = function(nxt, ...)
        return call_with_entries(stem, layer, nxt, ...)
      end})
      return true
    end
    local current = rawget(_ENV, fn)
    if type(current) ~= "function" then
      return false, "no such function in this menu"
    end
    F.attached[key] = true
    _ENV[fn] = function(...)
      return call_with_entries(stem, layer, current, ...)
    end
    return true
  end

  -- Hold prompts: a guide entry whose key acts when held.
  F.HOLD = {
    SECONDS = 2,
    SHOW_AFTER = 0.1,
    KEY_GRACE = 30,                -- frames without a Pressed repeat = released
    GUIDE_BUTTON = 9396745,        -- mainmenu01_07_button_guide: one instance per guide entry
    GLYPH_NODE = 950238781,        -- its _text_btn01 (50 x 50, top-left)
    RING_TEXT = 950238781,         -- the ring's _text_btn01
    RING_RATE = 1996459178,        -- the ring's rate bar (0 empty .. 1 full)
    RING_SCALE = 50 / 68,          -- the ring's glyph box is 68 px, the guide's 50 px
    RING_DX = 25, RING_DY = -25,   -- glyph top-left -> centre (layout units, y up)
    PRIORITY = 700,
  }
  F.holds = {}

  --- Declares a hold prompt; answers true, or false, why.
  function F.add_hold(d)
    if type(d) ~= "table" or type(d.name) ~= "string" or type(d.ring) ~= "number" or type(d.icon) ~= "number" then
      return false, "a hold needs a name, a ring and an icon"
    end
    F.holds[d.name] = d
    return true
  end

  local function glyph_position(menu, entry)
    local ok, x, y
    if menu == nil then
      ok, x, y = pcall(funcLuaMenuCommand, VRFW.commands.GET_MESH_GLOBAL_POSITION, F.HOLD.GUIDE_BUTTON, entry,
        F.HOLD.GLYPH_NODE)
    else
      ok, x, y = pcall(funcLuaMenuCommand, VRFW.commands.GET_MESH_GLOBAL_POSITION, F.HOLD.GUIDE_BUTTON, entry, F.HOLD.GLYPH_NODE, menu)
    end
    -- (0, 0) is what a missing node answers
    if ok and type(x) == "number" and type(y) == "number" and (x ~= 0 or y ~= 0) then
      return x, y
    end
    return nil
  end

  -- the ring's centre over the entry's glyph (the guide's menus first, then no menu); nil = not found
  local function ring_position(d)
    local entry = d.entry or 0
    if type(d.menus) == "function" then
      local ok, menus = pcall(d.menus)
      if ok and type(menus) == "table" then
        for _, m in ipairs(menus) do
          if type(m) == "number" and m ~= 0 then
            local x, y = glyph_position(m, entry)
            if x ~= nil then
              return x + F.HOLD.RING_DX, y + F.HOLD.RING_DY
            end
          end
        end
      end
    end
    local x, y = glyph_position(nil, entry)
    if x ~= nil then
      return x + F.HOLD.RING_DX, y + F.HOLD.RING_DY
    end
    return nil
  end

  --- One frame of the hold: the ring at `progress` over the entry's glyph; false = unknown hold / no ring layer.
  function F.hold_progress(name, progress)
    local d = F.holds[name]
    if d == nil then
      return false
    end
    local L = d.ring
    if funcLuaMenuCommand(VRFW.commands.IS_EXIST_LAYER, L) ~= true then
      return false
    end
    if funcLuaMenuCommand(VRFW.commands.IS_OPEN_LAYER, L, 0) ~= true then
      funcLuaMenuCommand(VRFW.commands.OPEN_LAYER, L, 0)
      d.ready, d.glyph_set = false, false
      return true
    end
    if funcLuaMenuCommand(VRFW.commands.IS_LOADING_LAYER, L) == true then
      return true
    end
    if not d.ready then
      d.ready = true
      funcLuaMenuCommand(VRFW.commands.SET_DRAW_PRIORITY, L, 0, F.HOLD.PRIORITY, true)
      funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_SCALE, L, F.HOLD.RING_SCALE, F.HOLD.RING_SCALE, 1, 0)
      funcLuaMenuCommand(541357333 --[[rate init]], L, F.HOLD.RING_RATE, 0, 0)
    end
    if not d.glyph_set then
      -- read at every hold, so the glyph follows the device in use
      d.glyph_set = true
      local ok, glyph = pcall(funcLuaCommand, VRFW.commands.TEXT_GET, d.icon)
      funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, L, F.HOLD.RING_TEXT,
        (ok and type(glyph) == "string") and glyph or "", 0)
    end
    local x, y = ring_position(d)
    if x == nil then
      if not d.warned then
        d.warned = true
        F.log(d.name .. ": the guide glyph of entry " .. tostring(d.entry or 0) .. " was not found; ring hidden")
      end
      funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, L, 0, false)
      return true
    end
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_POS, L, x, y, 0, 0)
    funcLuaMenuCommand(1595998683 --[[CMND_SET_RATE]], L, F.HOLD.RING_RATE, 0, math.max(0, math.min(1, progress)), 0)
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, L, 0, true)
    return true
  end

  --- Hides the ring of hold `name`.
  function F.hold_hide(name)
    local d = F.holds[name]
    if d == nil then
      return
    end
    d.glyph_set = false
    local L = d.ring
    if funcLuaMenuCommand(VRFW.commands.IS_EXIST_LAYER, L) == true and funcLuaMenuCommand(VRFW.commands.IS_OPEN_LAYER, L, 0) == true then
      funcLuaMenuCommand(1595998683, L, F.HOLD.RING_RATE, 0, 0, 0)
      funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, L, 0, false)
    end
  end

  --- Waits for hold `name` to finish or be released; answers its result, nil for an unknown hold.
  function F.wait_hold(name)
    local d = F.holds[name]
    if d == nil then
      return nil
    end
    local H = F.HOLD
    local seconds = (type(d.seconds) == "number" and d.seconds > 0) and d.seconds or H.SECONDS
    local frames, last_press, timer_seen, result = 0, 0, false, nil
    d.glyph_set = false
    while true do
      local timer = nil
      if type(d.held_seconds) == "function" then
        local ok, s = pcall(d.held_seconds)
        if ok and type(s) == "number" then
          timer = s
        end
      end
      if timer ~= nil and timer > 0 then
        timer_seen = true
      end
      if type(d.pressed) == "function" then
        local ok, on = pcall(d.pressed)
        if ok and on == true then
          last_press = frames
        end
      end
      local held, time
      if timer_seen then
        held, time = timer ~= nil and timer > 0, timer or 0
      else
        held, time = frames - last_press <= H.KEY_GRACE, frames / 60
      end
      if result == nil then
        if not held then
          result = "tap"
          break
        end
        if time >= seconds then
          result = "held"
          pcall(F.hold_hide, name)
          if type(d.on_held) == "function" then
            pcall(d.on_held)
          end
        elseif time >= H.SHOW_AFTER then
          pcall(F.hold_progress, name, time / seconds)
        end
      elseif not held then
        break
      end
      coroutine.yield()
      frames = frames + 1
    end
    pcall(F.hold_hide, name)
    return result
  end
end
