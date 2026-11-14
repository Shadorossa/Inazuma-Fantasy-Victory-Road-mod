if VRFW.host ~= nil then
  local ROWS = 284009563   -- vsroute01_16_sub_list
  local FOCUS_GET = 2603265800   -- (layer) -> the focused row index (0-based)

  local LABEL = {
    LAYER = 375144984,
    INSTANCE = 0,
    TEXT_NODE = 3180095505,      -- _text_list_base01_off
    HIDE_TEXTS = {808187266 --[[`_text_list_base01_on`]]},
    HIDE_MESHES = {688754292 --[[_touch_list01]], 1525181930 --[[`_list_base01_on`]], 4270801635 --[[_list_base01_off]],
      3034975430 --[[_list_base01_ol]], 713202021 --[[_list_base01_ok]], 1409068817 --[[_list_base01_gray]],
      1928480906 --[[`_icon_list01_on`]], 3004512670 --[[_icon_list01_off]]},
    HIDE_NODES = {1849899120 --[[_pos_class01]], 44923504 --[[_pos_lv01]], 3597743423 --[[_pos_team_lv01]],
      2442161064 --[[_pos_list_left01]]},
    C = {
      OPEN = VRFW.commands.OPEN_LAYER, VISIBLE = VRFW.commands.SET_LAYER_VISIBLE, SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE, POS = VRFW.commands.SET_LAYER_LOCAL_POS, GET_POS = VRFW.commands.GET_LAYER_LOCAL_POS,
      MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE, TEXT = VRFW.commands.SET_MENU_TEXT_STRING, LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM,
      DRAW_PRIORITY = VRFW.commands.SET_DRAW_PRIORITY,   -- CMND_SET_DRAW_PRIORITY (layer, instance, priority, children)
      NODE_SCALE = 2885415772,      -- (layer, instance, node, width, height): the text node's box
      NODE_POS = 2575768773,        -- (layer, instance, node, axis 0 x / 1 y, value)
      NODE_VISIBLE = 2158717427,    -- (layer, node, bool, instance)
      TEXT_VISIBLE = VRFW.commands.SET_MENU_TEXT_VISIBLE,    -- (layer, text node, bool, instance)
    },
    FIRST_ROW_MID_Y = 442, ROW_STEP = 70, ROW_HALF_HEIGHT = 30, ROW_GAP = 11, PANEL_MID_X = 436,
    BAND_HEIGHT = 44, TEXT_BOX_WIDTH = 620, TEXT_BOX_HEIGHT = 54, GLYPH_WIDTH = 18, MIN_SCALE = 0.3,
    -- font_color markup (common/font/font_color.cfg.bin): AIMARK01 light blue, R light red, then the reset
    COLOUR_MET = "[CAIMARK01]", COLOUR_UNMET = "[CR]", COLOUR_RESET = "[C]",
    -- the label's inline icons: each one is a gap of spaces in the text with the icon drawn over it.
    -- GAP_CHAR is the ASCII space because the menu fonts (font_ja, font_zh_*) have no U+00A0 glyph and draw it as «*».
    -- faces: layer vrfw_mc_face (VRFW.face_icon.card); series icons: layer vrfw_mc_series (a cmn01_10 quad, 36 px)
    FACE_LAYER = 683908792, FACE_COUNT = 2, FACE_SIZE = 40,
    SERIES_LAYER = 3973112797, SERIES_COUNT = 2, SERIES_WIDTH = 48, SERIES_HEIGHT = 32, QUAD_SIDE = 36,
    QUAD_NODE = 1909474081 --[[icon_new01]], SPRITE = 558735651, SERIES_ICON = 817571471 --[[CMND_VRFW_SERIES_ICON]],
    TEXT_SIZE = 3549540977 --[[CMND_GET_MENU_TEXT_RECT_SIZE]], GAP_CHAR = " ", ICON_PAD = 4, ICON_PRIORITY = 858,
    icons = {}, icon_opened = {}, icon_drawn = {},
    opened = false, shown = false, x = 0, y = 0,
  }

  local function line_width(s)
    s = string.gsub(s, "%[C[^%]]*%]", "")
    s = string.gsub(s, "%[([^%]/]*)/[^%]]*%]", "%1")   -- furigana [base/reading]: the base only
    local units, i, n = 0, 1, string.len(s)
    while i <= n do
      local b = string.byte(s, i)
      local close = b == 60 and string.find(s, ">", i, true) or nil
      if close ~= nil then
        units, i = units + 2, close + 1
      else
        local len = b >= 0xF0 and 4 or (b >= 0xE0 and 3 or (b >= 0xC0 and 2 or 1))
        units, i = units + (len >= 3 and 2 or 1), i + len
      end
    end
    return units * LABEL.GLYPH_WIDTH
  end

  local function instance_count()
    local n = VRFW.host.menu_command(LABEL.C.LAYER_NUM, LABEL.LAYER)
    return type(n) == "number" and n or 0
  end

  local function piece_game()
    local ok, game = pcall(function()
      return VRFW.route_board_commands.L.n4
    end)
    if ok and type(game) == "number" then
      return game
    end
    return nil
  end

  -- the panel's band: asked once per change (the mod that sizes the panel re-sizes it); BAND_ORDER = the first band
  local BAND_ID, BAND_ORDER, LABEL_PRIORITY = "match_challenge", 10, 856   -- over the panel (845) and its rows (847)
  local function panel_band(extra)
    local p = VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel or nil
    if p == nil or p.layer == nil then
      return
    end
    if (VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel_band ~= nil) then
      pcall(VRFW.route_board_commands.panel_band, BAND_ID, extra, BAND_ORDER)
    elseif p.extra ~= extra and (VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel_extra ~= nil) then
      pcall(VRFW.route_board_commands.panel_extra, p.layer, p.kind, p.rows, extra)
    end
  end

  local function panel_shift()
    local p = VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel or nil
    if p == nil or p.layer == nil or p.x == nil or p.y == nil then
      return 0, 0
    end
    local x, y = VRFW.host.menu_command(LABEL.C.GET_POS, p.layer, 0)
    if type(x) ~= "number" or type(y) ~= "number" then
      return 0, 0
    end
    return x - p.x, y - p.y
  end

  local function layer_count(layer, most)
    local n = VRFW.host.menu_command(LABEL.C.LAYER_NUM, layer)
    return math.min(type(n) == "number" and n or 0, most)
  end

  -- the drawn width of s in the label's text node (nil = cannot be measured)
  local function measure(s)
    local w = VRFW.host.menu_command(LABEL.TEXT_SIZE, LABEL.LAYER, LABEL.INSTANCE, LABEL.TEXT_NODE, s)
    w = tonumber(w)
    if w ~= nil and w > 0 and w < 4000 then
      return w
    end
    return nil
  end

  -- an icon instance is opened only when an icon uses it and stays hidden until placed
  local function open_icon(layer, idx)
    local key = layer .. ":" .. idx
    if not LABEL.icon_opened[key] then
      LABEL.icon_opened[key] = true
      VRFW.host.menu_command(LABEL.C.OPEN, layer, idx)
      VRFW.host.menu_command(LABEL.C.VISIBLE, layer, idx, false)
    end
  end

  -- the series quad's sprite: drawn until the sheet answers true (retried from place)
  local function draw_series(icon)
    local key = icon.idx
    if LABEL.icon_drawn[key] == icon.series then
      return true
    end
    local ok, sheet, sprite = VRFW.host.command(LABEL.SERIES_ICON, icon.series, "on")
    if ok ~= true then
      return false
    end
    if VRFW.host.menu_command(LABEL.SPRITE, LABEL.SERIES_LAYER, sheet, sprite, LABEL.QUAD_NODE, 0, icon.idx) == true then
      LABEL.icon_drawn[key] = icon.series
      return true
    end
    return false
  end

  local function place_icons(dx, dy)
    for _, icon in ipairs(LABEL.icons) do
      local x, y = icon.x + dx, LABEL.y + dy
      if icon.face ~= nil then
        VRFW.face_icon.card(LABEL.FACE_LAYER, icon.idx, icon.face, x, -y, icon.size)
      elseif draw_series(icon) then
        VRFW.host.menu_command(LABEL.C.SCALE, LABEL.SERIES_LAYER, icon.w / LABEL.QUAD_SIDE, icon.h / LABEL.QUAD_SIDE, 1, icon.idx)
        VRFW.host.menu_command(LABEL.C.POS, LABEL.SERIES_LAYER, x, y, 0, icon.idx)
        if not icon.visible then
          icon.visible = true
          VRFW.host.menu_command(LABEL.C.DRAW_PRIORITY, LABEL.SERIES_LAYER, icon.idx, LABEL.ICON_PRIORITY, true)
          VRFW.host.menu_command(LABEL.C.VISIBLE, LABEL.SERIES_LAYER, icon.idx, true)
        end
      end
    end
  end

  local function place()
    local dx, dy = panel_shift()
    VRFW.host.menu_command(LABEL.C.POS, LABEL.LAYER, LABEL.x + dx, LABEL.y + dy, 0, LABEL.INSTANCE)
    place_icons(dx, dy)
  end

  local function hide_icons()
    for _, icon in ipairs(LABEL.icons) do
      VRFW.host.menu_command(LABEL.C.VISIBLE, icon.face ~= nil and LABEL.FACE_LAYER or LABEL.SERIES_LAYER, icon.idx, false)
    end
    LABEL.icons = {}
  end

  -- closing = the menu is closing: the text goes, the panel keeps its size while it leaves
  local function hide(closing)
    if not closing then
      panel_band(0)
    end
    if not LABEL.shown then
      return
    end
    LABEL.shown = false
    VRFW.host.menu_command(LABEL.C.VISIBLE, LABEL.LAYER, LABEL.INSTANCE, false)
    hide_icons()
  end

  -- the label's parts as one text line: each icon a gap of spaces wide enough for it (an icon its layer
  -- cannot show falls back to its plain label, `status.label`)
  local function line_of(status)
    local parts = type(status.parts) == "table" and status.parts or {{text = status.label}}
    local faces = VRFW.face_icon ~= nil and layer_count(LABEL.FACE_LAYER, LABEL.FACE_COUNT) or 0
    local series = layer_count(LABEL.SERIES_LAYER, LABEL.SERIES_COUNT)
    local gap_unit = measure(string.rep(LABEL.GAP_CHAR, 10))
    gap_unit = gap_unit ~= nil and gap_unit / 10 or LABEL.GLYPH_WIDTH / 2
    local pieces, icons = {}, {}
    for _, p in ipairs(parts) do
      if p.text ~= nil then
        pieces[#pieces + 1] = p.text
      else
        local is_face = p.face ~= nil
        local idx = is_face and faces or series
        local used = 0
        for _, icon in ipairs(icons) do
          if (icon.face ~= nil) == is_face then
            used = used + 1
          end
        end
        if used >= idx then
          return status.label, {}
        end
        local w = is_face and LABEL.FACE_SIZE or LABEL.SERIES_WIDTH
        local gap = string.rep(LABEL.GAP_CHAR, math.ceil((w + 2 * LABEL.ICON_PAD) / gap_unit))
        pieces[#pieces + 1] = gap
        icons[#icons + 1] = {face = p.face, series = p.series, idx = used, w = w,
                             h = is_face and LABEL.FACE_SIZE or LABEL.SERIES_HEIGHT,
                             before = table.concat(pieces), gap = gap}
      end
    end
    return table.concat(pieces), icons
  end

  -- the band under the list's last row, the label centred in it with its icons inline
  local function show(status, row_count)
    if instance_count() < 1 or type(status.label) ~= "string" or status.label == "" then
      return hide()
    end
    local k = LABEL.INSTANCE
    if not LABEL.opened then
      LABEL.opened = true
      VRFW.host.menu_command(LABEL.C.OPEN, LABEL.LAYER, k)
    end
    panel_band(LABEL.ROW_GAP + LABEL.BAND_HEIGHT)
    LABEL.shown = true
    local colour = status.ok and LABEL.COLOUR_MET or LABEL.COLOUR_UNMET
    for _, mesh in ipairs(LABEL.HIDE_MESHES) do
      VRFW.host.menu_command(LABEL.C.MESH_VISIBLE, LABEL.LAYER, mesh, false, k)
    end
    for _, node in ipairs(LABEL.HIDE_NODES) do
      VRFW.host.menu_command(LABEL.C.NODE_VISIBLE, LABEL.LAYER, node, false, k)
    end
    for _, node in ipairs(LABEL.HIDE_TEXTS) do
      VRFW.host.menu_command(LABEL.C.TEXT_VISIBLE, LABEL.LAYER, node, false, k)
    end
    hide_icons()
    local line, icons = line_of(status)
    local text_width = measure(line) or line_width(line)
    -- the layer scale that fits the line into the box (1 = it fits at the rows' size)
    local scale = 1
    if text_width > LABEL.TEXT_BOX_WIDTH then
      scale = math.max(LABEL.MIN_SCALE, LABEL.TEXT_BOX_WIDTH / text_width)
    end
    local box_width = LABEL.TEXT_BOX_WIDTH / scale
    VRFW.host.menu_command(LABEL.C.NODE_SCALE, LABEL.LAYER, k, LABEL.TEXT_NODE, box_width, LABEL.TEXT_BOX_HEIGHT)
    VRFW.host.menu_command(LABEL.C.NODE_POS, LABEL.LAYER, k, LABEL.TEXT_NODE, 0, -box_width / 2)
    VRFW.host.menu_command(LABEL.C.NODE_POS, LABEL.LAYER, k, LABEL.TEXT_NODE, 1, LABEL.TEXT_BOX_HEIGHT / 2)
    VRFW.host.menu_command(LABEL.C.SCALE, LABEL.LAYER, scale, scale, 1, k)
    VRFW.host.menu_command(LABEL.C.TEXT_VISIBLE, LABEL.LAYER, LABEL.TEXT_NODE, true, k)
    VRFW.host.menu_command(LABEL.C.TEXT, LABEL.LAYER, LABEL.TEXT_NODE, colour .. line .. LABEL.COLOUR_RESET, k)
    local last_row_mid = LABEL.FIRST_ROW_MID_Y + LABEL.ROW_STEP * (math.max(row_count, 1) - 1)
    local y = last_row_mid + LABEL.ROW_HALF_HEIGHT + LABEL.ROW_GAP + LABEL.BAND_HEIGHT / 2
    if (VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel_band_top ~= nil) then
      local ok, top = pcall(VRFW.route_board_commands.panel_band_top, BAND_ID)
      if ok and type(top) == "number" then
        y = top + LABEL.ROW_GAP + LABEL.BAND_HEIGHT / 2
      end
    end
    LABEL.x, LABEL.y = LABEL.PANEL_MID_X, -y
    -- each icon centred on its gap: the line's left edge + the width up to the gap's end - half the gap
    local left = LABEL.x - text_width * scale / 2
    for _, icon in ipairs(icons) do
      local gap_w = measure(icon.gap) or line_width(icon.gap)
      local gap_end = measure(icon.before) or line_width(icon.before)
      icon.x = left + (gap_end - gap_w / 2) * scale
      icon.w, icon.h, icon.size = icon.w * scale, icon.h * scale, icon.w * scale
      open_icon(icon.face ~= nil and LABEL.FACE_LAYER or LABEL.SERIES_LAYER, icon.idx)
    end
    LABEL.icons = icons
    place()
    for _, icon in ipairs(icons) do
      if icon.face ~= nil then
        VRFW.host.menu_command(LABEL.C.DRAW_PRIORITY, LABEL.FACE_LAYER, icon.idx, LABEL.ICON_PRIORITY, true)
        VRFW.host.menu_command(LABEL.C.VISIBLE, LABEL.FACE_LAYER, icon.idx, true)
      end
    end
    VRFW.host.menu_command(LABEL.C.DRAW_PRIORITY, LABEL.LAYER, k, LABEL_PRIORITY, true)
    VRFW.host.menu_command(LABEL.C.VISIBLE, LABEL.LAYER, k, true)
  end

  -- the label of the focused row (no band on a row without a challenge)
  local function update()
    if VRFW.match_challenge == nil or VRFW.route_board_commands == nil then
      return hide()
    end
    local ok, rows = pcall(function()
      return VRFW.route_board_commands.L.t3
    end)
    if not ok or type(rows) ~= "table" then
      return hide()
    end
    local idx = VRFW.host.menu_command(FOCUS_GET, ROWS)
    local row = type(idx) == "number" and rows[idx + 1] or nil
    local game = piece_game()
    local diff = row ~= nil and row.difficultyType or 0
    local status = nil
    if diff > 0 and game ~= nil then
      status = VRFW.match_challenge.status(game, 0, diff)
    end
    if status == nil then
      return hide()
    end
    show(status, #rows)
  end

  -- a new menu object: its label layer is not open yet
  VRFW.host.on("vs_route_town_command_select_menu", "OnInit", {
    id = "menu_engine.match_challenge", phase = "before",
    fn = function()
      LABEL.opened, LABEL.shown = false, false
      LABEL.icons, LABEL.icon_opened, LABEL.icon_drawn = {}, {}, {}
      if VRFW.face_icon ~= nil then
        VRFW.face_icon.forget(LABEL.FACE_LAYER)
      end
    end,
  })

  VRFW.host.on("vs_route_town_command_select_menu", "OnChangeFocus", {
    id = "menu_engine.match_challenge", phase = "after",
    fn = function(r, a1)
      if a1 == ROWS then
        update()
      end
    end,
  })

  VRFW.host.on("vs_route_town_command_select_menu", "VRFW.route_board_commands.list_layer", {
    id = "menu_engine.match_challenge", phase = "after",
    fn = function()
      if VRFW.match_challenge == nil or (VRFW.route_board_commands == nil or VRFW.route_board_commands.panel_band_reserve == nil) then
        return
      end
      local game = piece_game()
      local ok, rows = pcall(function()
        return VRFW.route_board_commands.L.t3
      end)
      if game == nil or not ok or type(rows) ~= "table" then
        return
      end
      for _, row in ipairs(rows) do
        local diff = row.difficultyType or 0
        if diff > 0 and VRFW.match_challenge.of(game, diff) ~= nil then
          pcall(VRFW.route_board_commands.panel_band_reserve, BAND_ID, LABEL.ROW_GAP + LABEL.BAND_HEIGHT, BAND_ORDER)
          return
        end
      end
    end,
  })

  -- the list's first open (its focus is set there)
  VRFW.host.on("vs_route_town_command_select_menu", "OnOpenLayer", {
    id = "menu_engine.match_challenge", phase = "after",
    fn = function(r, a1, a2)
      if a1 == ROWS and a2 == 0 then
        update()
      end
    end,
  })

  -- the line follows the panel while it moves (its open / close slide)
  VRFW.host.on("vs_route_town_command_select_menu", "Step", {
    id = "menu_engine.match_challenge", phase = "after",
    fn = function()
      if LABEL.shown then
        place()
      end
    end,
  })

  -- the menu closes (a row decided, Back)
  VRFW.host.on("vs_route_town_command_select_menu", "OnDecideFocus", {
    id = "menu_engine.match_challenge", phase = "before",
    fn = function()
      hide(true)
    end,
  })

  VRFW.host.on("vs_route_town_command_select_menu", "OnBack", {
    id = "menu_engine.match_challenge", phase = "before",
    fn = function()
      hide(true)
    end,
  })

  -- the required starters that still apply: their own texts in the button guide (no icon, no command)
  VRFW.host.on("vs_route_town_command_select_menu", "VRFW.route_board_commands.guide", {
    id = "menu_engine.match_challenge", phase = "after",
    fn = function(r, item, icons, texts, cmds)
      if VRFW.match_challenge == nil or VRFW.route_board_commands == nil or type(item) ~= "table" or (item.difficultyType or 0) <= 0
        or type(texts) ~= "table" then
        return
      end
      local game = piece_game()
      local i = game ~= nil and VRFW.match_challenge.applies(game, item.difficultyType) or nil
      local c = i ~= nil and VRFW.match_challenge.details(i) or nil
      if c ~= nil and #(c.required or {}) > 0 then
        for _, t in ipairs(VRFW.match_challenge.required_texts(i, VRFW.match_challenge.won(game, item.difficultyType))) do
          icons[#icons + 1] = 0
          texts[#texts + 1] = t
          cmds[#cmds + 1] = 0
        end
      end
    end,
  })
end
