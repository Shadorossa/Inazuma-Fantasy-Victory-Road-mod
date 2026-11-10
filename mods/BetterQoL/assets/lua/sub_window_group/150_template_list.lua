-- The team list window as the team dock's template list: a row is a template of the page shown, read without a dock swap.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.template_list_window == nil and type(SetupWindowParams) == "function" and type(UpdateTeamDocListItem) == "function"
    and type(OnOpenLayer) == "function" and type(PostStep) == "function" then
  local P = {
    EVENT = "BetterQoL.TemplateListPage",   -- (first template - 1, pages, page, rows, focused row or -1, active template); 0 pages = closed
    OWNER = "BetterQoL.template_list_window",
    SUB_WINDOW = 968210065,
    WINDOW = 193803588,              -- win05_15_sub_list_locator_doc
    ROW = 2279382105,                -- mainmenu90_31_doc_item
    PAGER = 2025071631,              -- betterqol_template_list_pager
    TRACE_PREFIX = "betterqol_template_list_pager",   -- attach locator names: this + the instance
    TEAM_LIST_WINDOW = 2,            -- the sub window type of the team list
    DOTS = 32,                       -- the dots of the layer's 34 copies
    PRIORITY = 870,
    ROOM = 496,
    OFFSET_Y = -100,
    MAX_TRIES = 120,                 -- frames to wait for the copies to open
    LIST_REFRESH = 4114514990,       -- redraws the rows on screen
    SET_FOCUS = 1778826357,          -- (list, row, true): the focused row
    ROW_PLAIN = 1, ROW_EMPTY = 2,    -- SetBtnEnable values: both can be chosen, the second one is drawn grey
    first = nil, active = 0, cards = {}, want = nil, tries = 0, dots = nil,
  }
  BetterQoL.template_list_window = P

  local function log(...)
    P.logger = P.logger or VRFW.logger.new("BetterQoL template list window")
    P.logger(...)
  end

  -- the card of a template of the page (BetterQoL.template_cards), read once per page; false = an empty template
  local function card_of(template)
    local card = P.cards[template]
    if card == nil then
      card = BetterQoL.template_cards.read(template) or false
      P.cards[template] = card
    end
    return card
  end

  local function is_empty(card)
    return card == false or #card.members == 0
  end

  local function hide_dots()
    P.want = nil
    if P.dots ~= nil and P.dots:opened() then
      P.dots:hide()
    end
  end

  -- places the page dots once their copies are open
  local function try_show_dots()
    local want = P.want
    if want == nil then
      return
    end
    P.tries = P.tries + 1
    if P.tries > P.MAX_TRIES then
      P.want = nil
      log("page dots not shown: the layer did not open")
      return
    end
    if P.dots:opened() then
      if funcLuaMenuCommand(VRFW.commands.IS_OPEN_LAYER, P.PAGER, P.DOTS + 1) ~= true
          or funcLuaMenuCommand(VRFW.commands.IS_LOADING_LAYER, P.PAGER) == true then
        return
      end
    end
    local shown = math.min(want.pages, P.DOTS)
    if P.dots:show(shown, VRFW.pager.dot_of_page(want.page, want.pages, shown), 0, P.OFFSET_Y) then
      P.want = nil
    end
  end

  local function window_is_open()
    return funcLuaMenuCommand(VRFW.commands.IS_OPEN_LAYER, P.WINDOW, 0) == true
  end

  local function on_page(first, pages, page, rows, focused_row, active)
    if type(pages) ~= "number" or pages < 1 then
      P.first = nil
      hide_dots()
      return
    end
    P.first, P.active, P.cards = first, active, {}
    for row = 0, rows - 1 do
      SetBtnEnable(row, is_empty(card_of(first + row + 1)) and P.ROW_EMPTY or P.ROW_PLAIN)
    end
    if window_is_open() then
      funcLuaMenuCommand(P.LIST_REFRESH, P.WINDOW)
      if focused_row >= 0 then
        funcLuaMenuCommand(P.SET_FOCUS, P.WINDOW, focused_row, true)
        OnChangeFocus(P.ROW, 0)
      end
    end
    if pages < 2 then
      hide_dots()
      return
    end
    if P.dots == nil then
      P.dots = VRFW.pager.new({layer = P.PAGER, name = "team templates", dots = P.DOTS, room = P.ROOM, prio = P.PRIORITY,
        setup = function(instance)
          funcLuaMenuCommand(VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE, P.WINDOW, 0, VRFW.crc32(P.TRACE_PREFIX .. instance), true)
        end})
    end
    P.want = {pages = pages, page = page}
    P.tries = 0
    try_show_dots()
  end

  -- A team list window being set up is the game's own list until the team dock sends a page.
  local setup_window = SetupWindowParams
  SetupWindowParams = function(count, texts, size, a4, a5, a6, a7, a8, window_type, ...)
    local results = table.pack(setup_window(count, texts, size, a4, a5, a6, a7, a8, window_type, ...))
    -- the window's layers are opened again with every window: the page dots start over
    P.first, P.want, P.dots = nil, nil, nil
    if window_type == P.TEAM_LIST_WINDOW then
      VRFW.menu_event.on(P.EVENT, P.SUB_WINDOW, P.OWNER, on_page)
    end
    return table.unpack(results, 1, results.n)
  end

  local open_layer = OnOpenLayer
  OnOpenLayer = function(layer, instance, ...)
    if layer == P.PAGER then
      VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, layer, instance, false)   -- the whole status base, until placed
    end
    return open_layer(layer, instance, ...)
  end

  -- (instance, row): the row of a template page shows that template; the game's own list shows the dock at that row
  local draw_dock_row = UpdateTeamDocListItem
  UpdateTeamDocListItem = function(instance, row, ...)
    if P.first == nil then
      return draw_dock_row(instance, row, ...)
    end
    local template = P.first + row + 1
    local card = card_of(template)
    local name, level, emblem = "", 0, 0
    if card ~= false then
      local cards = BetterQoL.template_cards
      name = cards.field(card, "", cards.FIELD.NAME)
      level = cards.field(card, 0, cards.FIELD.LEVEL)
      emblem = cards.field(card, 0, cards.FIELD.EMBLEM, 0)
    end
    BetterQoL.template_numbers.draw_plate(P.ROW, instance, name, template, level, emblem, template == P.active)
  end

  local post_step = PostStep
  PostStep = function(...)
    local results = table.pack(post_step(...))
    if P.want ~= nil then
      local ok, problem = pcall(try_show_dots)
      if not ok then
        P.want = nil
        log("page dots error", tostring(problem))
      end
    end
    return table.unpack(results, 1, results.n)
  end
end
