-- VRFW board node menus, game Lua side (every menu VM; script side scripts\node_menu.lua; docs/framework/node-menu.md).
if VRFW.node_menu == nil then
  VRFW.node_menu_providers = VRFW.node_menu_providers or {}
  local N = {
    OF_PIECE = VRFW.commands.VRFW_NODE_MENU_OF_PIECE,     -- CMND_VRFW_NODE_MENU_OF_PIECE (pieceId) -> handler, node, key
    ROWS = VRFW.commands.VRFW_NODE_MENU_ROWS,             -- CMND_VRFW_NODE_MENU_ROWS (pieceId) -> the declared rows
    GAME_CLEAR = VRFW.commands.GET_SOCCER_GAME_CLEAR_FLAG,   -- (game, difficulty) -> won
    CLOSE_MENU = VRFW.commands.CLOSE_MENU_OBJECT,
    TEXT_GET = VRFW.commands.TEXT_GET,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,         -- (layer, text node, string, instance)
    MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,         -- (layer, mesh, on, instance)
    LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,       -- (layer, instance, on)
    LOC_VISIBLE = 2158717427,        -- (layer, locator, on, instance)
    SET_TEX = 558735651,             -- (layer, atlas path, sprite, texture slot, 0, instance)
    PRIM_VISIBLE = 1233047821,       -- CMND_SET_PRIM_VISIBLE (layer, instance, number setting, on)
    PRIM_INDEX = 1927054058,
    PRIM_VALUE = 3609943765,
    CRONICA = 1,                     -- the difficulty row a row's unlock and drop-rate list use
    MAX_ROWS = 9,
                                     -- joints _atc_list01 ..
    RETAIL_ROWS = 8,                 -- the rows the retail panel fits over the button guide
    ROW_STEP = 70,                   -- px between two rows (vsroute01_15c _atc_listNN)
    SET_LAYER_POS = 1389957207,      -- CMND_SET_LAYER_LOCAL_POS (layer, x, y, z)
    NORMAL_PANEL = 14202445,         -- vsroute01_15c_list_locator: the panel of a normal piece
    MENU = "vs_route_town_command_select_menu",
    MENU_ID = 1193383590,            -- its menu object
    REQUEST_SLOT = 62293565,
    REQUEST_ROW = 915267698,
    ROW_ITEM = 0x56524E4D,           -- a row's listItemType ("VRNM"): never a retail command
    SUB_LIST = 284009563,            -- vsroute01_16_sub_list (the command rows)
    BANNER = 1483086491,             -- vsroute01_17_myteam_banner
    INFO_WINDOW = 1303149463,        -- team02_04_info_window (the flavour text under the panel)
    BANNER_ATLAS = 1503831295,
    BANNER_SLOT = 3668937361,        -- myteam_dmy01: the one-picture banner's texture slot
    BANNER_SHOW = {1711801685},      -- _myteam_dmy01_b (vsroute01_17.g4pkm)
    BANNER_HIDE = {447975417, 689040068, 13372060, 1546785142},
    BANNER_NUMBERS = {2269507340, 508346038},
                                     -- ignores its locator's visibility, so it is hidden by itself
    ROW_TEXTS = {808187266, 3180095505},   -- _text_list_base01_on / _off: the centred label
    ROW_LABELS = {580803180, 4197192385},  -- _text_list_base02_on / _off: the left label
    ROW_NUMBERS = {861327194, 1146224588}, -- the row's team level numbers (on / off)
    ROW_LEVEL_LABELS = {165487784, 1712215830},   -- _gtxt_teamlevel01_on / _off: the "team level" label
    ROW_ICONS = {1928480906, 3004512670},  -- _icon_list01_on / _off: the row's left icon (hidden)
    ROW_LEVEL = 3597743423,          -- _pos_team_lv01: the label and the numbers
    by_idx = {},                     -- board piece index -> {handler, node, key} or false (cached)
    declared = {},                   -- pieceId -> the declared rows' answer (cached)
    cache = {},                      -- save slot -> its rows menu or false (N.MenuOfSlot)
    providers = VRFW.node_menu_providers,
  }
  VRFW.node_menu = N

  --- Logs through the node-menu tag.
  function N.log(...)
    if PRINT ~= nil then
      pcall(PRINT, "VRFW.node_menu", ...)
    end
  end

  -- a Lua function of this VM by name (`Name` or `Table.Name`)
  local function fn_of(name)
    local fn = _G
    for part in string.gmatch(name, "[^%.]+") do
      fn = type(fn) == "table" and fn[part] or nil
    end
    return type(fn) == "function" and fn or nil
  end

  --- The service node of board piece idx: handler, node, key; nil when there is none.
  function N.of(idx)
    if idx == nil or idx < 0 or (VRFW.route_nodes == nil or VRFW.route_nodes.load == nil) then
      return nil
    end
    local m = N.by_idx[idx]
    if m == nil then
      m = false
      local node = (VRFW.route_nodes.load().byIdx or {})[idx]
      if node ~= nil and node.piece ~= nil then
        local handler, name, key = VRFW.host.command(N.OF_PIECE, node.piece)
        if type(handler) == "string" and handler ~= "" then
          m = {handler = handler, node = name, key = key, piece = node.piece}
        end
      end
      N.by_idx[idx] = m
    end
    if m == false then
      return nil
    end
    return m.handler, m.node, m.key
  end

  --- True when idx is a service node.
  function N.is_piece(idx)
    return N.of(idx) ~= nil
  end

  -- the declared rows of a node's piece (CMND_VRFW_NODE_MENU_ROWS): {handler, node, key, rows = {…}} or false
  local function declared(piece)
    local d = N.declared[piece]
    if d == nil then
      d = false
      local ans = VRFW.host.command(N.ROWS, piece)
      if type(ans) == "table" and type(ans.rows) == "table" and #ans.rows > 0 then
        d = ans
      end
      N.declared[piece] = d
    end
    return d
  end

  -- the shown level of a row: its `level`, or the club's team level kept inside its `levels` band
  local function shown_level(r)
    if type(r.min) == "number" and r.min > 0 then
      local level = VRFW.recruit ~= nil and VRFW.recruit.team_level() or r.min
      return math.max(r.min, math.min(r.max or r.min, level or r.min))
    end
    if type(r.level) == "number" and r.level > 0 then
      return r.level
    end
    return nil
  end

  local function unlocked(r)
    return (r.unlock or 0) == 0 or VRFW.host.command(N.GAME_CLEAR, r.unlock, N.CRONICA) == true
  end

  -- the rows menu of a declared node: the unlocked rows, their shown level; run = the handler of the board's VM
  local function declared_menu(slot)
    if (VRFW.route_nodes == nil or VRFW.route_nodes.load == nil) then
      return nil
    end
    for _, node in ipairs(VRFW.route_nodes.load().nodes or {}) do
      if node.slot == slot then
        local d = declared(node.piece)
        if not d then
          return nil
        end
        local rows = {}
        for i, r in ipairs(d.rows) do
          if unlocked(r) then
            local level = shown_level(r)
            rows[#rows + 1] = {index = i, text = r.text, arg = level, level = level, min = r.min, max = r.max,
                               game = (r.game or 0) ~= 0 and r.game or nil}
          end
        end
        return {key = d.key, banner = d.banner or 0, rows = rows, node = d.node, run = function(row, idx)
          local fn = fn_of(d.handler)
          if fn == nil then
            N.log("menu", d.key, "handler", d.handler, "is not defined in this VM")
            return false
          end
          local ok, ran = pcall(fn, row, idx, d.node, d.key)
          if not ok then
            N.log("menu", d.key, "handler", d.handler, "error", tostring(ran))
            return false
          end
          return ran ~= false
        end}
      end
    end
    return nil
  end

  --- The rows menu of a piece's save slot: a service's (the providers) or a declared node's; nil = none.
  function N.menu_of_slot(slot)
    if type(slot) ~= "number" then
      return nil
    end
    local menu = N.cache[slot]
    if menu == nil then
      menu = false
      for _, p in ipairs(N.providers) do
        local ok, m = pcall(p.of_slot, slot)
        if ok and type(m) == "table" then
          menu = m
          break
        end
      end
      if menu == false then
        menu = declared_menu(slot) or false
      end
      N.cache[slot] = menu
    end
    return menu or nil
  end

  --- Runs the piece's handler; answers true when it ran.
  function N.open_piece(idx)
    local handler, node, key = N.of(idx)
    if handler == nil then
      return false
    end
    if declared(N.by_idx[idx].piece) then
      return false              -- a rows node: its command menu lists the rows
    end
    local fn = fn_of(handler)
    if fn == nil then
      N.log("piece", idx, "node", node, "handler", handler, "is not defined in this VM")
      return false
    end
    local ok, ran = pcall(fn, idx, node, key)
    if not ok then
      N.log("piece", idx, "node", node, "handler", handler, "error", tostring(ran))
      return false
    end
    N.log("piece", idx, "node", node, "handler", handler, ran == true and "ran" or "passed")
    return ran == true
  end

  -- the menu of the open command menu's piece (VRFW.route_board_commands.L.n2: its save slot)
  local function open_menu()
    if VRFW.route_board_commands == nil or VRFW.route_board_commands.L == nil then
      return nil
    end
    local ok, slot = pcall(function() return VRFW.route_board_commands.L.n2 end)
    if not ok then
      return nil
    end
    return N.menu_of_slot(slot), slot
  end

  --- The command menu's rows of a rows node (route_board's VRFW.route_board_commands.rows default); nil = not one.
  function N.rows_for(slot, rows)
    N.cache = {}
    local menu = N.menu_of_slot(slot)
    if menu == nil or #menu.rows == 0 then
      if menu ~= nil then
        N.log("slot", slot, "menu", menu.key, "has no row to list: the battle rows stay")
      end
      return nil
    end
    if #menu.rows > N.MAX_ROWS then
      N.log("slot", slot, "menu", menu.key, #menu.rows, "rows: the panel places", N.MAX_ROWS, "(the rest are not listed)")
    end
    local base = (type(rows) == "table" and rows[1]) or {}
    local out = {}
    for k, row in ipairs(menu.rows) do
      if k > N.MAX_ROWS then
        break
      end
      out[#out + 1] = {listItemType = N.ROW_ITEM, pattern = 0, text = row.text, classTexture = 0, difficultyType = N.CRONICA,
                       textureOn = 2928350469 --[[`icon_list01_on`]], textureOff = 3469663858 --[[icon_list01_off]],
                       textureDiffBase = 0, heroDropControlEnabled = false, base = base.listItemType}
    end
    return out
  end

  local function text_of(id)
    local s = VRFW.host.command(N.TEXT_GET, id)
    return type(s) == "string" and s or ""
  end

  -- a row's text; %d in it = the row's arg
  local function row_label(row)
    local s = text_of(row.text)
    if row.arg == nil then
      return s
    end
    local ok, label = pcall(string.format, s, row.arg)
    return ok and label or s
  end

  local function set_texts(layer, inst, nodes, text)
    for _, node in ipairs(nodes) do
      pcall(funcLuaMenuCommand, N.SET_TEXT, layer, node, text, inst)
    end
  end

  --- Fills a row of the command menu.
  function N.setup_row(layer, inst, menu)
    local row = menu.rows[inst + 1]
    if row == nil then
      return
    end
    local label = row_label(row)
    local with_level = row.level ~= nil
    set_texts(layer, inst, N.ROW_LABELS, with_level and label or "")
    set_texts(layer, inst, N.ROW_TEXTS, with_level and "" or label)
    for _, mesh in ipairs(N.ROW_LEVEL_LABELS) do
      pcall(funcLuaMenuCommand, N.MESH_VISIBLE, layer, mesh, with_level, inst)
    end
    for _, mesh in ipairs(N.ROW_ICONS) do
      pcall(funcLuaMenuCommand, N.MESH_VISIBLE, layer, mesh, false, inst)
    end
    if menu.setup ~= nil then
      pcall(menu.setup)
    end
    pcall(funcLuaMenuCommand, N.LOC_VISIBLE, layer, N.ROW_LEVEL, with_level, inst)
    for _, number in ipairs(N.ROW_NUMBERS) do
      if with_level then
        local ok, p = pcall(funcLuaMenuCommand, N.PRIM_INDEX, layer, 0, number)
        if ok and p then
          pcall(funcLuaMenuCommand, N.PRIM_VALUE, layer, inst, p, row.level)
        end
      end
      pcall(funcLuaMenuCommand, N.PRIM_VISIBLE, layer, inst, number, with_level)
    end
  end

  local function menu_setup(r, layer, inst)
    local menu = open_menu()
    if menu == nil then
      return
    end
    if layer == N.SUB_LIST then
      N.setup_row(layer, inst, menu)
    elseif layer == N.INFO_WINDOW then
      pcall(funcLuaMenuCommand, N.LAYER_VISIBLE, layer, inst, false)
    end
  end

  -- the banner: with the menu's picture, the one-picture style (_pos_team01_b) with it alone (no level, no «MY TEAM»)
  local function menu_open(r, layer, inst)
    local menu = open_menu()
    if menu == nil then
      return
    end
    if layer == N.INFO_WINDOW then
      pcall(funcLuaMenuCommand, N.LAYER_VISIBLE, layer, inst, false)
      return
    end
    if layer ~= N.BANNER or type(menu.banner) ~= "number" or menu.banner == 0 then
      return
    end
    pcall(funcLuaMenuCommand, N.LOC_VISIBLE, layer, 4160160648 --[[`_pos_team01_a`]], false, inst)
    pcall(funcLuaMenuCommand, N.LOC_VISIBLE, layer, 1862160946 --[[_pos_team01_b]], true, inst)
    pcall(funcLuaMenuCommand, N.SET_TEX, layer, N.BANNER_ATLAS, menu.banner, N.BANNER_SLOT, 0, inst)
    for _, m in ipairs(N.BANNER_SHOW) do
      pcall(funcLuaMenuCommand, N.MESH_VISIBLE, layer, m, true, inst)
    end
    for _, m in ipairs(N.BANNER_HIDE) do
      pcall(funcLuaMenuCommand, N.MESH_VISIBLE, layer, m, false, inst)
    end
    for _, number in ipairs(N.BANNER_NUMBERS) do
      pcall(funcLuaMenuCommand, N.PRIM_VISIBLE, layer, inst, number, false)
    end
  end

  -- picking a row: the request in the parameter store, the menu closed with no retail result
  local function menu_decide(nxt, layer, inst, ...)
    local menu, slot = nil, nil
    if layer == N.SUB_LIST then
      menu, slot = open_menu()
    end
    local row = menu ~= nil and menu.rows[inst + 1] or nil
    if row ~= nil then
      VRFW.param.replace(N.REQUEST_SLOT, slot)
      VRFW.param.replace(N.REQUEST_ROW, row.index)
      VRFW.host.command(N.CLOSE_MENU, N.MENU_ID)
      N.log("row picked: menu", menu.key, "row", row.index)
      return
    end
    return nxt(layer, inst, ...)
  end

  -- the X key: the drop-rate list of the focused row's game (the window reads the piece's game, n4, when it opens)
  local function menu_drop_list(nxt, ...)
    local menu = open_menu()
    local row = nil
    if menu ~= nil then
      local ok, focus = pcall(funcLuaMenuCommand, 2603265800 --[[the list's focused row]], N.SUB_LIST)
      row = ok and type(focus) == "number" and menu.rows[focus + 1] or nil
    end
    if row == nil or row.game == nil then
      return nxt(...)
    end
    local game = VRFW.route_board_commands.L.n4
    VRFW.route_board_commands.L.n4 = row.game
    local r = table.pack(pcall(nxt, ...))
    VRFW.route_board_commands.L.n4 = game
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  local function menu_final()
    N.cache = {}
  end

  local function menu_place(r, layer, kind, rows)
    local menu = layer == N.NORMAL_PANEL and open_menu() or nil
    local extra = menu ~= nil and math.min(#menu.rows, N.MAX_ROWS) - N.RETAIL_ROWS or 0
    local p = VRFW.route_board_commands ~= nil and VRFW.route_board_commands.panel or nil
    if extra <= 0 or p == nil or p.x == nil or p.y == nil then
      return
    end
    p.y = p.y + N.ROW_STEP * extra
    pcall(funcLuaMenuCommand, N.SET_LAYER_POS, layer, p.x, p.y, 0)
    N.log("menu", menu.key, #menu.rows, "rows: the panel raised", N.ROW_STEP * extra, "px")
  end

  if VRFW.host ~= nil then
    VRFW.host.on(N.MENU, "OnSetupLayer", {id = "VRFW.node_menu_rows", phase = "after", fn = menu_setup})
    VRFW.host.on(N.MENU, "OnOpenLayer", {id = "VRFW.node_menu_banner", phase = "after", fn = menu_open})
    VRFW.host.on(N.MENU, "OnDecideFocus", {id = "VRFW.node_menu_row", phase = "around", fn = menu_decide})
    VRFW.host.on(N.MENU, "OpenDropRateWindow", {id = "VRFW.node_menu_drop_list", phase = "around", fn = menu_drop_list})
    VRFW.host.on(N.MENU, "FinalizeMenu", {id = "VRFW.node_menu_final", phase = "after", fn = menu_final})
    VRFW.host.on(N.MENU, "VRFW.route_board_commands.list_layer", {id = "VRFW.node_menu_place", phase = "after", fn = menu_place})
  end

  --- Runs the row asked for after a menu; answers true when there was one.
  function N.after_menu(idx)
    if not VRFW.param.has(N.REQUEST_ROW) then
      return false
    end
    N.cache = {}
    local slot = VRFW.param.take(N.REQUEST_SLOT)
    local index = VRFW.param.take(N.REQUEST_ROW)
    local menu = N.menu_of_slot(slot)
    local row = nil
    for _, r in ipairs(menu ~= nil and menu.rows or {}) do
      if r.index == index then
        row = r
      end
    end
    if row == nil then
      N.log("piece", idx, "slot", slot, "row", index, "not served")
      return false
    end
    local ok, ran = pcall(menu.run, row, idx)
    N.log("piece", idx, "menu", menu.key, "row", index, ok and tostring(ran) or ("error " .. tostring(ran)))
    return true
  end
end
