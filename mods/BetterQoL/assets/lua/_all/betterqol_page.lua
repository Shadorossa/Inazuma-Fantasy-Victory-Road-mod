BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.page == nil then
  local Page = {}
  BetterQoL.page = Page

  local LOG, TEXT_GET = 519897777, 4074371074
  local C = { SCALE = 3778714801, POS = 1389957207, MESH_VISIBLE = 3405944500, SET_TEXT = 1083631230,
    TEXT_STYLE = 2333948100, VISIBLE = 711242136, CTRL = 3518307824, LIST_NUM = 3252599449,
    FOCUS_SET = 3466097042, ATTACH_TRACE = 1774843228 }
  Page.TXT = { NODE = 378327766 --[[_text_cmd_back01]], MESHES = {298211823, 2853207670}, BOX_LEFT = -384,
    BOX_W = 384, BOX_MID_Y = 144 }
  Page.ANCHOR = { LAYER = 3455690937, TEXTS = { 931545948 --[[`_text_list01_on`]], 3705682548 --[[_text_list01_off]] },
    CURSOR = 3313461902 }

  -- a log function whose lines start with `prefix`
  function Page.logger(prefix)
    return function(...)
      local p = {}
      for i = 1, select("#", ...) do p[#p + 1] = tostring((select(i, ...))) end
      VRFW.host.command(LOG, prefix .. " " .. table.concat(p, " "))
    end
  end

  function Page.tx(cache, id_prefix, name)
    local t = cache[name]
    if t == nil then
      local s = VRFW.host.command(TEXT_GET, VRFW.ids.crc32(id_prefix .. name))
      t = (type(s) == "string" and s ~= "") and s or name
      cache[name] = t
    end
    return t
  end

  function Page.text(kit, layer, style, s, x, y, sc)
    if s == nil or s == "" then return nil end
    local i = kit.slot(layer)
    if i == nil then return nil end
    local T = Page.TXT
    sc = sc or 1
    kit.show(layer, i)
    for _, m in ipairs(T.MESHES) do kit.set(layer, i, "m" .. m, C.MESH_VISIBLE, layer, m, false, i) end
    kit.set(layer, i, "st", C.TEXT_STYLE, layer, i, T.NODE, VRFW.ids.crc32(style))
    kit.set(layer, i, "txt", C.SET_TEXT, layer, T.NODE, s, i)
    kit.set(layer, i, "sc", C.SCALE, layer, sc, sc, 1, i)
    kit.set(layer, i, "pos", C.POS, layer, x - T.BOX_LEFT * sc, -y - T.BOX_MID_Y * sc, 0, i)
    return i
  end

  function Page.setup_layer(kit, layers, a1, a2)
    local A = Page.ANCHOR
    if a1 == A.LAYER then
      for _, node in ipairs(A.TEXTS) do VRFW.host.menu_command(C.SET_TEXT, a1, node, "", a2) end
      VRFW.host.menu_command(C.ATTACH_TRACE, a1, a2, A.CURSOR, false)
      return false
    end
    for _, layer in pairs(layers) do
      if a1 == layer then
        VRFW.host.menu_command(C.VISIBLE, a1, a2, false)
        if kit ~= nil then kit.forget(a1, a2) end
        return true
      end
    end
    return false
  end

  function Page.open_layer(kit, layers, a1, a2)
    local A = Page.ANCHOR
    if a1 ~= A.LAYER or a2 ~= 0 then return false end
    VRFW.host.menu_command(C.CTRL, A.LAYER, true)
    VRFW.host.menu_command(C.LIST_NUM, A.LAYER, 1)
    VRFW.host.menu_command(C.FOCUS_SET, A.LAYER, 0)
    VRFW.host.menu_command(C.ATTACH_TRACE, A.LAYER, 0, A.CURSOR, false)
    VRFW.host.menu_command(C.POS, A.LAYER, -4000, 4000, 0, 0)
    for _, layer in pairs(layers) do
      local n = VRFW.host.menu_command(1175615627 --[[layer instance count]], layer)
      kit.caps[layer] = type(n) == "number" and n or 0
    end
    return true
  end

  Page.ALBUM_GUIDE = {
    SEARCH = 2214150166 --[[betterqol_technique_search]], MULTI = 1115342952 --[[BetterQoL.Album.MultiSelect]],
    MARK = 628619577 --[[BetterQoL.Album.Mark]], EXIT = 2499630057 --[[BetterQoL.Album.MultiExit]],
    ICON_ENTER = 2750714971 --[[<CMD_ENTER>]], ICON_START = 203473330 --[[<CMD_FUNC1>]],
    ICON_SELECT = 2387151820 --[[<CMD_FUNC2>]], ICON_X = 3607854790 --[[<CMD_FUNC4>]],
    ENTER = 1981080283 --[[CMD_ENTER]], START = 637335895 --[[CMD_FUNC1]], SELECT = 3170216173 --[[CMD_FUNC2]],
    X = 1435897304 --[[CMD_FUNC4]],
  }

  function Page.album_action(field, kind)
    local acts = BetterQoL.album_actions
    if type(acts) ~= "table" then return nil end
    for _, a in ipairs(acts) do
      if type(a) == "table" and type(a.On) == "function" and type(a[field]) == kind then
        local ok, on = pcall(a.On)
        if ok and on == true then return a end
      end
    end
    return nil
  end

  -- the album's footer: [{text, icon, command, act}], in the order the page's pointer zones read it
  function Page.album_guide(multi)
    local G = Page.ALBUM_GUIDE
    local many = Page.album_action("RunMany", "function")
    local single = Page.album_action("guide", "number")
    local entries = {}
    local function add(text, icon, command, act)
      entries[#entries + 1] = {text = text, icon = icon, command = command, act = act}
    end
    if multi and many ~= nil then
      add(G.MARK, G.ICON_ENTER, G.ENTER, "accept")
      add(many.multi_guide, G.ICON_START, G.START, "recruit_marked")
    elseif single ~= nil then
      add(single.guide, G.ICON_ENTER, G.ENTER, "accept")
    end
    add(G.SEARCH, G.ICON_SELECT, G.SELECT, "search")
    if many ~= nil then add(multi and G.EXIT or G.MULTI, G.ICON_X, G.X, "multi") end
    return entries
  end

  function Page.wheel()
    local K = VRFW.keys
    if K.held(K.WHEEL_UP, K.MENU_CTRL) then return -1 end
    if K.held(K.WHEEL_DOWN, K.MENU_CTRL) then return 1 end
    return 0
  end

  -- the Clubhouse (play_guide_top_menu) side of a page visit, the way it opens its "Scene archive"
  local Caseta = {
    MENU = 1281873114, STEM = "play_guide_top_menu",
    LIST = 530619243 --[[mainmenu90_12_list_item_small]], PICTURE = 243035880 --[[playguide01_00_p1_background]],
    GUIDE = 1138543975 --[[mainmenu01_06_base_button_guide]], OPEN_ANIME = 71445658,
    INPUT = 1558704558 --[[CMND_SET_INPUT_ENABLE_MENU_OBJECT]], HIDE_MENU = 369172623, SHOW_MENU = 66378409,
    FOCUS_GET = 2603265800, FOCUS_SET = 3466097042,
    HEADER_TYPE = 14, HEADER_ICON = 3275740866 --[[mode_base05]], HEADER_TITLE = 882201751,
    GUIDE_OWN = { {text = 1847312674, icon = 2750714971 --[[<CMD_ENTER>]], command = 1981080283 --[[CMD_ENTER]]} },
  }
  Page.caseta = Caseta

  function Caseta.header(kind, text)
    if type(SwapSoccerTopCommonHeaderByHeaderType) ~= "function" then return end
    if type(text) == "number" then
      local t = VRFW.host.command(TEXT_GET, text)
      text = t or nil
    end
    if type(text) == "string" then pcall(SwapSoccerTopCommonHeaderByHeaderType, kind, text, Caseta.HEADER_ICON) end
  end

  function Caseta.guide(entries)
    if VRFW.footer_prompts ~= nil and VRFW.footer_prompts.set ~= nil then
      VRFW.footer_prompts.set(Caseta.STEM, Caseta.MENU, entries, Caseta.GUIDE)
    end
  end

  function Caseta.leave(page, header_kind, title, guide)
    local row = VRFW.host.menu_command(Caseta.FOCUS_GET, Caseta.LIST) or 0
    VRFW.host.menu_command(Caseta.INPUT, Caseta.MENU, false)
    VRFW.host.menu_command(VRFW.commands.PLAY_ANIME_TYPE, Caseta.PICTURE, 0, Caseta.OPEN_ANIME, 2)
    VRFW.host.menu_command(Caseta.HIDE_MENU, Caseta.MENU)
    Caseta.header(header_kind, title)
    Caseta.guide(guide)
    VRFW.host.command(VRFW.commands.OPEN_MENU_OBJECT, page)
    return row
  end

  -- the Caseta back with its cursor, help line, header and guide on `row`
  function Caseta.go_back(row)
    VRFW.host.menu_command(Caseta.SHOW_MENU, Caseta.MENU)
    VRFW.host.menu_command(VRFW.commands.PLAY_ANIME_TYPE, Caseta.PICTURE, 0, Caseta.OPEN_ANIME, 0)
    Caseta.guide(Caseta.GUIDE_OWN)
    VRFW.host.menu_command(VRFW.commands.SET_ENABLE_CTRL_FOCUS, Caseta.LIST, true)
    VRFW.host.menu_command(Caseta.FOCUS_SET, Caseta.LIST, row)
    if type(OnChangeFocus) == "function" then pcall(OnChangeFocus, Caseta.LIST, row) end
    Caseta.header(Caseta.HEADER_TYPE, Caseta.HEADER_TITLE)
    VRFW.host.menu_command(Caseta.INPUT, Caseta.MENU, true)
  end

  -- waits (inside the visit coroutine) while `page` exists
  function Caseta.wait_closed(page)
    coroutine.yield()
    while VRFW.host.menu_command(VRFW.commands.IS_EXIST_MENU_OBJECT, page) == true do coroutine.yield() end
  end

  function Caseta.visits(state, visit, log, reset, on_error)
    local init = OnInit
    if type(init) == "function" then
      OnInit = function(...)
        reset()
        return init(...)
      end
    end
    local step = Step
    Step = function(...)
      if state.co ~= nil then
        local ok, err = coroutine.resume(state.co)
        if not ok then
          log("visit error", tostring(err))
          if on_error ~= nil then on_error(err) end
        end
        if not ok or coroutine.status(state.co) == "dead" then state.co = nil end
      end
      if type(step) == "function" then return step(...) end
    end
    return function()
      if state.co ~= nil then return end
      state.co = coroutine.create(visit)
      local ok, err = coroutine.resume(state.co)
      if not ok then
        log("open failed", tostring(err))
        state.co = nil
      end
    end
  end
end
