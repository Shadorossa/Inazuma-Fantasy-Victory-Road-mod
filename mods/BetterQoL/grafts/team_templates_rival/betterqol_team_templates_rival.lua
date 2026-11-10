--@lib vrfw_menu_kit.lua#Pointer
do
  local STEM = "soccer_vs_mydock_menu"
  local R = {
    INFO = @crc:CMND_BETTERQOL_TEMPLATE_INFO@,
    OF_DOCK = @crc:CMND_BETTERQOL_TEMPLATE_OF_DOCK@,
    NUMBERS = @crc:CMND_BETTERQOL_TEMPLATE_LIST@,    -- -> the numbers of the templates that are not empty "1,2,..."
    RIVAL_FREE = @crc:CMND_BETTERQOL_TEMPLATE_RIVAL_FREE@,
    RIVAL = @crc:CMND_BETTERQOL_TEMPLATE_RIVAL@,
    MENU_ID = @crc:soccer_vs_mydock_menu@,
    LAYER = @crc:betterqol_rival_pager@,
    LIST = @crc:mainmenu90_26_list_item_locator@,
    ITEM = @crc:mainmenu90_19_02_list_item@,
    OPTION_BASE = @crc:win05_43_soccer_game_option_list_base@,
    IS_OPEN_LAYER = @crc:CMND_IS_OPEN_LAYER@,
    SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@,
    TEAM_SET_INFO = @crc:CMND_GET_TEAM_SET_INFO@,   -- (set, team, field, ...) -> ok, value
    RESERVE = @crc:CMND_RESERVE_SOCCER@,
    TEMP_BYTE_FLAG = @crc:CMND_SET_TEMP_BYTE_FLAG@,
    FIRST_SET = 4017866835,            -- the first team dock's logical set
    TEAM_MEMBER = 1720957768,          -- (set, team, member, 0 handle / 1 position) -> ok, value
    CAN_BE_ACTIVE = 1104634465,        -- (set, team) -> the team can play
    MEMBER_CHECK = 1538643580,         -- (set, team, false) -> 0 = no member error
    LEVEL_CAP_FLAG = 4272841233,       -- temp byte flag of the level sync option (the retail SetLevelCapByteFlag)
    MEMBER_HANDLE = 0, MEMBER_POSITION = 1,
    ROW_SETS = 256,                    -- row r of the page is team set ROW_SETS + r - 1: above every real team set (a byte in the game)
    MENU_LOCK = 1558704558,            -- (menu, true = takes input)
    LIST_REFRESH = 4114514990,         -- redraws the rows on screen
    CHECK_INPUT = 4265778440,
    MENU_CTRL = 1332654303,
    MENU_CTRL_AN = 2748927068,
    CMD_L2 = 1970176280,               -- CMD_FUNCL2 (pad L2, keyboard Q)
    CMD_R2 = 2704260807,               -- CMD_FUNCR2 (pad R2, keyboard E)
    SOUND = 1917805374,
    SE_PAGE = 2629173176,              -- sy0009
    DOTS = 32,                         -- the layer's copies minus the two key glyphs
    ROOM = 480,
    PRIORITY = 700,
    ROW_X = 254,                       -- centre of the row, over the «team sheet» title
    ROW_Y = -278,
    KEY_HALF_W = 20, HALF_H = 24, KEY_CENTRE = 14,
    active = false, templates = {}, cards = {}, rows = 0, first = 0, index = 1, count = 1, level_cap = 0,
    reading_rows = false, want = false, held = false, locked = false, hooked = false,
  }

  local function log(...)
    R.logger = R.logger or VRFW.logger.new("BetterQoL team templates rival")
    R.logger(...)
  end

  local function wrap(name, fn)
    VRFW.host.on(STEM, name, {id = "BetterQoL.team_templates_rival." .. name, phase = "around", fn = fn})
  end

  local function pressed(cmd)
    return funcLuaCommand(R.CHECK_INPUT, R.MENU_CTRL, cmd) == true
      or funcLuaCommand(R.CHECK_INPUT, R.MENU_CTRL_AN, cmd) == true
  end

  -- a retail window or question has the input
  local function busy()
    return R.locked or funcLuaMenuCommand(R.IS_OPEN_LAYER, R.OPTION_BASE, 0) == true
  end

  -- the rows and the formation preview of the focused team, from the templates of the page
  local function redraw()
    funcLuaMenuCommand(R.LIST_REFRESH, R.LIST)
    OnChangeFocus(R.ITEM, 0)
  end

  -- the card of a template (BetterQoL.template_cards), read once per list
  local function card_of(template)
    local card = R.cards[template]
    if card == nil then
      card = BetterQoL.template_cards.read(template)
      R.cards[template] = card
    end
    return card
  end

  -- `row` from 1 on the page shown
  local function template_of_row(row)
    if type(row) ~= "number" or row < 1 or row > R.rows then
      return nil
    end
    return R.templates[R.first + row]
  end

  local function is_row_set(set)
    return type(set) == "number" and set >= R.ROW_SETS
  end

  local function card_of_row_set(set)
    local template = template_of_row(set - R.ROW_SETS + 1)
    return template and card_of(template)
  end

  -- `index`: the page, `rows` templates each; the last page ends on the last template
  local function show_page(index)
    R.index, R.want = index, true
    R.first = math.max(0, math.min((index - 1) * R.rows, #R.templates - R.rows))
  end

  local function turn(index)
    if index == R.index or index < 1 or index > R.count or busy() then
      return
    end
    show_page(index)
    funcLuaCommand(R.SOUND, R.SE_PAGE)
    redraw()
  end

  local function pointer_step(shown)
    R.ptr = R.ptr or VRFW.pointer.new()
    R.ptr.begin()
    local look = VRFW.pager.LOOK
    local pitch = R.row:fit(shown)
    local first = R.ROW_X - (shown - 1) * pitch / 2
    local y = -R.ROW_Y
    for i = 1, shown do
      R.ptr.box(first + (i - 1) * pitch, y, pitch / 2, R.HALF_H, i)
    end
    local left = first - look.dot / 2 - look.gap_l + R.KEY_CENTRE
    local right = first + (shown - 1) * pitch - look.dot / 2 + look.gap_r + R.KEY_CENTRE
    R.ptr.box(left, y, R.KEY_HALF_W, R.HALF_H, "left")
    R.ptr.box(right, y, R.KEY_HALF_W, R.HALF_H, "right")
    local ev = R.ptr.poll()
    if not ev.left or ev.click == nil or ev.click ~= ev.hot then
      return
    end
    if ev.click == "left" then
      turn((R.index - 2) % R.count + 1)
    elseif ev.click == "right" then
      turn(R.index % R.count + 1)
    else
      turn(VRFW.pager.page_of_dot(ev.click, R.count, shown))
    end
  end

  local function step()
    local shown = math.min(R.count, R.DOTS)
    if R.want and R.row:show(shown, VRFW.pager.dot_of_page(R.index, R.count, shown), R.ROW_X, R.ROW_Y) then
      R.want = false
    end
    local l2, r2 = pressed(R.CMD_L2), pressed(R.CMD_R2)
    if R.held then
      R.held = l2 or r2
    elseif l2 then
      R.held = true
      turn((R.index - 2) % R.count + 1)
    elseif r2 then
      R.held = true
      turn(R.index % R.count + 1)
    end
    pointer_step(shown)
  end

  -- The retail screen reads team set ROW_SETS + row for its rows, preview, level sync and match: the row's template answers.
  local function hook_row_sets()
    local owner = "BetterQoL.team_templates_rival"
    VRFW.host.hook_command(R.TEAM_SET_INFO, function(nxt, id, set, ...)
      if not is_row_set(set) then
        return nxt(id, set, ...)
      end
      local card = card_of_row_set(set)
      if card == nil then
        return false
      elseif card.set then
        return nxt(id, card.set, ...)
      end
      local _, field, extra = ...
      return BetterQoL.template_cards.stored_info(card, field, extra, R.level_cap)
    end, owner)
    VRFW.host.hook_command(R.TEAM_MEMBER, function(nxt, id, set, ...)
      if not is_row_set(set) then
        return nxt(id, set, ...)
      end
      local card = card_of_row_set(set)
      if card == nil then
        return false
      elseif card.set then
        return nxt(id, card.set, ...)
      end
      local _, index, what = ...
      local member = card.members[(tonumber(index) or -1) + 1]
      if member and what == R.MEMBER_HANDLE then
        return true, member.handle
      elseif member and what == R.MEMBER_POSITION then
        return true, member.position
      end
      return false
    end, owner)
    VRFW.host.hook_command(R.CAN_BE_ACTIVE, function(nxt, id, set, ...)
      if not is_row_set(set) then
        return nxt(id, set, ...)
      end
      local card = card_of_row_set(set)
      if card == nil then
        return false
      elseif card.set then
        return nxt(id, card.set, ...)
      end
      return card.starters == BetterQoL.template_cards.STARTERS
    end, owner)
    VRFW.host.hook_command(R.MEMBER_CHECK, function(nxt, id, set, ...)
      if not is_row_set(set) then
        return nxt(id, set, ...)
      end
      local card = card_of_row_set(set)
      if card and card.set then
        return nxt(id, card.set, ...)
      end
      return 0
    end, owner)
    -- the rival: a docked template plays from its dock, a stored one from its copy in the rival team set
    VRFW.host.hook_command(R.RESERVE, function(nxt, id, game, stadium, a, b, c, d, e, f, g, rival, ...)
      if not is_row_set(rival) then
        return nxt(id, game, stadium, a, b, c, d, e, f, g, rival, ...)
      end
      local card = card_of_row_set(rival)
      local set = card and card.set
      if card and set == nil then
        set = VRFW.host.real_command(R.RIVAL, card.template)
      end
      if type(set) ~= "number" then
        log("match refused: template", tostring(card and card.template), "has no team set")
        return false
      end
      return nxt(id, game, stadium, a, b, c, d, e, f, g, set, ...)
    end, owner)
    VRFW.host.hook_command(R.TEMP_BYTE_FLAG, function(nxt, id, flag, value, ...)
      if flag == R.LEVEL_CAP_FLAG then
        R.level_cap = value
      end
      return nxt(id, flag, value, ...)
    end, owner)
    VRFW.host.hook_command(R.MENU_LOCK, function(nxt, id, menu, on, ...)
      if menu == R.MENU_ID then
        R.locked = on == false
      end
      return nxt(id, menu, on, ...)
    end, owner, {menu = true})
  end

  local function setup()
    R.active = false
    local usable, count = VRFW.host.command(R.INFO)
    if usable ~= true or type(count) ~= "number" or VRFW.host.command(R.RIVAL_FREE) ~= true then
      return
    end
    R.templates, R.cards = {}, {}
    local numbers = VRFW.host.command(R.NUMBERS)
    if type(numbers) ~= "string" then
      return
    end
    for number in numbers:gmatch("%d+") do
      R.templates[#R.templates + 1] = tonumber(number)
    end
    R.rows = MENU_DEF.GetTeamDockNum()
    if #R.templates <= R.rows then
      return
    end
    R.count = math.ceil(#R.templates / R.rows)
    show_page(1)
    if not R.hooked then
      R.hooked = true
      hook_row_sets()
    end
    R.active, R.held = true, true
    R.row = VRFW.pager.new({layer = R.LAYER, name = "team templates rival", dots = R.DOTS, room = R.ROOM, prio = R.PRIORITY})
  end

  -- Runs a retail function that computes its rows' team sets from the first dock: with pages they start at ROW_SETS.
  local function read_rows(nxt, ...)
    if not R.active or R.reading_rows then
      return nxt(...)
    end
    R.reading_rows = true
    local r = table.pack(pcall(VRFW.host.with_commands, {[R.FIRST_SET] = R.ROW_SETS}, nxt, ...))
    R.reading_rows = false
    if not r[1] then
      error(r[2], 0)
    end
    return table.unpack(r, 2, r.n)
  end

  wrap("OnInit", function(nxt, ...)
    local r = table.pack(nxt(...))
    local ok, e = pcall(setup)
    if not ok then
      R.active = false
      log("setup error", tostring(e))
    end
    return table.unpack(r, 1, r.n)
  end)

  wrap("OnOpenLayer", function(nxt, layer, idx, ...)
    if layer == R.LAYER then
      funcLuaMenuCommand(R.SET_LAYER_VISIBLE, layer, idx, false)   -- the whole status base, until placed
    end
    return nxt(layer, idx, ...)
  end)

  wrap("Step", function(nxt, ...)
    local r = table.pack(nxt(...))
    if R.active then
      local ok, e = pcall(step)
      if not ok then
        R.active = false
        log("step error", tostring(e))
      end
    end
    return table.unpack(r, 1, r.n)
  end)

  wrap("OnEnter", read_rows)
  wrap("OnChangeFocus", read_rows)
  wrap("SetListItemPrimitiveByListIdx", read_rows)

  -- A row of the list: the level, name and emblem of its template (the game sends those of the dock at that row).
  wrap("UpdateItem", function(nxt, layer, inst, number, level, name, emblem, ...)
    local template = R.active and template_of_row(number)
    local card = template and card_of(template)
    if card then
      local cards = BetterQoL.template_cards
      level = cards.field(card, 0, cards.FIELD.LEVEL, nil, R.level_cap)
      name = cards.field(card, "", cards.FIELD.NAME)
      emblem = cards.field(card, 0, cards.FIELD.EMBLEM, 0)
    end
    return read_rows(nxt, layer, inst, number, level, name, emblem, ...)
  end)

  -- A row shows its template's number (`number` = the row, from 1): the page's template, or the dock's without pages.
  wrap("SetListItemNumPrimitive", function(nxt, layer, inst, number, ...)
    local template
    if R.active then
      template = template_of_row(number)
    elseif type(number) == "number" then
      template = VRFW.host.command(R.OF_DOCK, VRFW.host.real_command(R.FIRST_SET) + number - 1)
    end
    if type(template) == "number" then
      number = template
    end
    return nxt(layer, inst, number, ...)
  end)
end
