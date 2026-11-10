-- lua_patch.scope: used
-- menu_engine: tab bar end-cap prompts, VRFW.tab_bar_caps (VRFW base feature).
if VRFW.tab_bar_caps == nil then
  local T = {
    EXIST = VRFW.commands.IS_EXIST_LAYER,
    OPEN = VRFW.commands.OPEN_LAYER,
    IS_OPEN = VRFW.commands.IS_OPEN_LAYER,
    LOADING = VRFW.commands.IS_LOADING_LAYER,
    LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    TEXT_PLATE = VRFW.commands.UPDATE_TEXT_PLATE,       -- (layer, instance, text node)
    PRIORITY = VRFW.commands.SET_DRAW_PRIORITY,         -- (layer, instance, priority, children)
    LOCAL_POS = VRFW.commands.SET_LAYER_LOCAL_POS,      -- (layer, x, y, z, instance)
    LOCAL_SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,  -- (layer, sx, sy, sz, instance)
    MESH_POS = VRFW.commands.GET_MESH_GLOBAL_POSITION,  -- (layer, instance, mesh) -> x, y (screen px, y up)
    TEXT_NODE = 378156699,        -- _text_guide01
    BUTTON_NODE = 950238781,      -- _text_btn01
    PLATE_BASE = 3491851413,      -- _win_guide_base01
    SLOT_CENTRE = 1517329426,     -- _pos_base01 (the tab item's centre)
    SLOT_CORNER = 4013273506,     -- _icon_base01 (the tab plate's top-left corner)
    CORNER_DX = 46, CORNER_DY = -26,   -- the plate's centre from that corner (92 x 52 plate, y up)
    TEXT_CX = 102,                -- the plate's origin to its glyph's centre, at scale 1
    GLYPH_W = 48,
    DEFAULT_LEFT = "<CMD_FUNCL2>", DEFAULT_RIGHT = "<CMD_FUNCR2>",
    DEFAULT_OFFSET = 430.5, DEFAULT_WIDTH = 139,
    DEFAULT_PRIORITY = 700,
    TRIES = 300,                  -- Step calls the placement waits for the layer at most
    logs = 0,
  }
  VRFW.tab_bar_caps = T

  local logger
  local function log(...)
    if T.logs >= 10 then
      return
    end
    T.logs = T.logs + 1
    logger = logger or VRFW.logger.new("VRFW tab_bar_caps")
    logger(...)
  end

  local function mesh(...)
    local x, y = VRFW.host.menu_command(T.MESH_POS, ...)
    if type(x) == "number" and type(y) == "number" and (x ~= 0 or y ~= 0) then
      return x, y
    end
    return nil
  end

  -- the centre of one tab slot on screen
  local function slot_centre(layer, slot)
    local x, y = mesh(layer, slot, T.SLOT_CENTRE)
    if x ~= nil then
      return x, y
    end
    x, y = mesh(layer, slot, T.SLOT_CORNER)
    if x ~= nil then
      return x + T.CORNER_DX, y + T.CORNER_DY
    end
    return nil
  end

  -- first tab centre x, last tab centre x, centre y; nil while the bar is not measurable yet
  local function measure(spec)
    if type(spec.measure) == "function" then
      local ok, a, b, c = pcall(spec.measure)
      if ok and type(a) == "number" and type(b) == "number" and type(c) == "number" then
        return a, b, c
      end
      return nil
    end
    local s = spec.slots
    if type(s) ~= "table" then
      return nil
    end
    local xf, y = slot_centre(s.layer, s.first or 0)
    local xl = slot_centre(s.layer, s.last)
    if xf == nil or xl == nil then
      return nil
    end
    return xf, xl, y
  end

  --- A new caps state table.
  function T.new()
    return {opened = false, pending = false, tries = 0, set = false}
  end

  --- Opens the tab bar caps for `spec` once.
  function T.open(state, spec)
    if state.opened then
      return
    end
    state.opened = true
    local ok, exist = pcall(funcLuaMenuCommand, T.EXIST, spec.layer)
    if not ok or exist ~= true then
      log("no cap prompt layer")
      return
    end
    for i = 0, 1 do
      pcall(funcLuaMenuCommand, T.OPEN, spec.layer, i)
    end
    state.pending, state.tries = true, 0
  end

  --- Hides the caps of `state`.
  function T.hide(state, spec)
    state.pending = false
    if state.set then
      for i = 0, 1 do
        pcall(funcLuaMenuCommand, T.LAYER_VISIBLE, spec.layer, i, false)
      end
      state.set, state.at = false, nil
    end
  end

  --- One frame of the caps: places them once the bar is up.
  function T.step(state, spec)
    if not state.pending then
      return
    end
    state.tries = state.tries + 1
    if state.tries > T.TRIES then
      state.pending = false
      log("cap prompts not placed")
      return
    end
    for i = 0, 1 do
      local ok, open = pcall(funcLuaMenuCommand, T.IS_OPEN, spec.layer, i)
      if not ok or open ~= true then
        return
      end
    end
    local okl, loading = pcall(funcLuaMenuCommand, T.LOADING, spec.layer)
    if okl and loading == true then
      return
    end
    local xf, xl, y = measure(spec)
    if xf == nil then
      return
    end
    local offset = tonumber(spec.cap_offset) or T.DEFAULT_OFFSET
    local width = tonumber(spec.cap_width) or T.DEFAULT_WIDTH
    local scale = math.min(1, (width + 6) / T.GLYPH_W)
    local centre = (xf + xl) / 2
    local at = {centre - offset, centre + offset}
    local inset = tonumber(spec.edge_inset)
    if inset ~= nil then
      -- glyph centre = the cap's outer edge pulled in by the inset and half the (scaled) glyph
      local pull = width / 2 - inset - T.GLYPH_W * scale / 2
      at = {centre - offset - pull, centre + offset + pull}
    end
    local screen_left = tonumber(spec.screen_left)
    if screen_left ~= nil then
      local least = screen_left + (inset or 0) + T.GLYPH_W * scale / 2
      if at[1] < least then
        at[1] = least
      end
    end
    if spec.symmetric == true then
      at[2] = 2 * centre - at[1]
    end
    if state.at ~= nil and math.abs(state.at[1] - at[1]) < 0.5 and math.abs(state.at[2] - at[2]) < 0.5
        and math.abs(state.y - y) < 0.5 then
      state.pending = false      -- the bar stopped moving (its open animation is over)
      return
    end
    state.at, state.y = at, y
    local texts = {spec.left_text or T.DEFAULT_LEFT, spec.right_text or T.DEFAULT_RIGHT}
    for i = 0, 1 do
      if not state.set then
        funcLuaMenuCommand(T.LAYER_VISIBLE, spec.layer, i, true)
        funcLuaMenuCommand(T.MESH_VISIBLE, spec.layer, T.PLATE_BASE, false, i)
        funcLuaMenuCommand(T.SET_TEXT, spec.layer, T.BUTTON_NODE, "", i)
        funcLuaMenuCommand(T.SET_TEXT, spec.layer, T.TEXT_NODE, texts[i + 1], i)
        funcLuaMenuCommand(T.TEXT_PLATE, spec.layer, i, T.TEXT_NODE)
        funcLuaMenuCommand(T.PRIORITY, spec.layer, i, tonumber(spec.priority) or T.DEFAULT_PRIORITY, true)
        funcLuaMenuCommand(T.LOCAL_SCALE, spec.layer, scale, scale, 1, i)
      end
      -- the plate is right-anchored: its origin sits TEXT_CX (scaled) right of the glyph's centre
      funcLuaMenuCommand(T.LOCAL_POS, spec.layer, at[i + 1] + T.TEXT_CX * scale, y, 0, i)
    end
    if not state.set then
      state.set = true
      log("cap prompts at", math.floor(at[1]), math.floor(at[2]), math.floor(y), "scale", scale)
    end
  end
end
