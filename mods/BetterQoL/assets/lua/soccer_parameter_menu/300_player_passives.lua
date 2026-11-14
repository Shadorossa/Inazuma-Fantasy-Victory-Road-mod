-- BetterQoL › «Pasivas de jugador»: a page of «Bonificaciones de equipo» after «Pasivas de equipo» (VRFW.team_bonus_pages,
-- layers in content\menus\player_passives.toml). Two columns of player cards, paired by rows: each card is the player's
-- miniface and name over the passives of his first three passive slots, one row per passive effect (the same effect
-- and condition = one effect id: their values summed), drawn by the game's own UpdateListItem like the team passive
-- rows. The players are the team the screen shows: its 11 and its bench, in the team's slot order (a player without an
-- unlocked passive in those slots has no card). Up / down (or the wheel) scroll by one row when the cards do not fit.
-- The team is read once per screen open (when the page is asked whether it shows); no engine call at load time.
if VRFW.team_bonus_pages ~= nil then
  local Pages = VRFW.team_bonus_pages
  local C = VRFW.commands
  local log = VRFW.logger.new("BetterQoL player passives")

  local FRAME = "betterqol_pp_page"
  local ROW = VRFW.crc32("betterqol_pp_row")
  local HEAD = VRFW.crc32("betterqol_pp_head")
  local ROW_COUNT, HEAD_COUNT = 20, 8          -- the layers' instances (player_passives.toml)
  local SLOTS = 3                              -- the passive slots read: the first three
  local PASSIVE = C.GET_CHARA_TEAM_PASSIVE_INFO   -- (hdl, slot, field): 0 passive id, 1 value, 2 unlocked
  local EFFECT_OF = 4054311845                 -- (passive id) -> ok, its effect id (retail soccer_common)
  local NAME = C.GET_CHARA_NAME_TEXT           -- (hdl) -> the player's name
  local CHECK_INPUT = C.CHECK_INPUT_CMD        -- (control, command) -> true while held
  local MENU_CTRL = 1332654303                 -- the menu control
  local KEYS = { up = { 1197218715, 2649361876 }, down = { 3259546669, 1098743808 } }   -- CMD_UP / CMD_VRFW_WHEEL_UP, CMD_DOWN / CMD_VRFW_WHEEL_DOWN
  local ANIME_ACTIVE, ANIME_DEFAULT = 1286797620, 753088835   -- the row's «Active» look, as the game's rows get it
  local TEXT_NAME = 1704438437                 -- _text_name01
  local FACE, FACE_SLOT = 478320441, 3237726902   -- _icon_chr_dmy01, its texture slot icon_chr_dmy01
  local HEAD_HIDE = { 4051829508, 2309656400, 3231997250, 1504513272, 782908526 }   -- check box, check, series icons x3
  local SCROLL_MESHES = { VRFW.crc32("_scr_line01"), VRFW.crc32("_scr_obj01") }
  local WAIT = 300                             -- Steps the instances may take to open before the page gives up

  -- layout (screen px, y down): the frame's list area (soccer11_21: scroll bar 251..939, first row at x 539; the
  -- second column mirrors it about the screen centre), the row (soccer11_20: 828 x 92, rows 84 apart as in the list),
  -- the head (team16_03: face 100 px, line 788 px from x -17)
  local LIST_TOP, LIST_BOTTOM, TOP_PAD = 251, 939, 10
  local COLUMN_X = { 539, 1920 - 539 }
  local ROW_HALF_W, ROW_HALF_H, ROW_STEP = 414, 46, 84
  local HEAD_H, HEAD_HALF_H, HEAD_INSET = 96, 50, 24
  local CARD_GAP = 18

  local S = { cards = {}, elems = {}, total = 0, scroll = 0, max_scroll = 0, active = false, opening = 0,
    ready = false, row_set = {}, head_set = {}, row_key = {}, head_key = {}, held = {} }

  local function cmd(...)
    return VRFW.host.command(...)
  end

  local function menu(...)
    return VRFW.host.menu_command(...)
  end

  -- the cards of the team the screen shows: { handle, name, rows = { { effect, value } } }
  local function read_cards()
    local ctx = Pages.context()
    if ctx == nil then
      return {}
    end
    local set = ctx.in_match and VRFW.team_loadout.active_set() or ctx.dock
    local members = type(set) == "number" and VRFW.team_loadout.members(set) or nil
    if members == nil then
      log("team not readable:", tostring(set))
      return {}
    end
    local cards = {}
    for _, hdl in ipairs(members) do
      local card, by_effect = { handle = hdl, rows = {} }, {}
      for slot = 0, SLOTS - 1 do
        local ok, id = cmd(PASSIVE, hdl, slot, 0)
        local oku, unlocked = cmd(PASSIVE, hdl, slot, 2)
        if ok == true and type(id) == "number" and id ~= 0 and oku == true and unlocked == true then
          local okv, value = cmd(PASSIVE, hdl, slot, 1)
          local oke, effect = cmd(EFFECT_OF, id)
          if okv == true and oke == true and type(value) == "number" and type(effect) == "number" and effect ~= 0 then
            local row = by_effect[effect]
            if row == nil then
              row = { effect = effect, value = 0 }
              by_effect[effect] = row
              card.rows[#card.rows + 1] = row
            end
            row.value = row.value + value
          end
        end
      end
      if #card.rows > 0 then
        local name = cmd(NAME, hdl)
        card.name = type(name) == "string" and name or ""
        cards[#cards + 1] = card
      end
    end
    return cards
  end

  -- the heads and rows of the cards, two cards a line (content y, down from the list's top)
  local function lay_out(cards)
    local elems, y0 = {}, 0
    for i = 1, #cards, 2 do
      local tall = 0
      for c = 0, 1 do
        local card = cards[i + c]
        if card ~= nil then
          local cx = COLUMN_X[c + 1]
          elems[#elems + 1] = { kind = "head", card = card, x = cx - ROW_HALF_W + HEAD_INSET, y = y0 + HEAD_H / 2 }
          for j, row in ipairs(card.rows) do
            elems[#elems + 1] = { kind = "row", row = row, x = cx, y = y0 + HEAD_H + ROW_HALF_H + (j - 1) * ROW_STEP }
          end
          tall = math.max(tall, HEAD_H + #card.rows * ROW_STEP)
        end
      end
      y0 = y0 + tall + CARD_GAP
    end
    local total = math.max(0, y0 - CARD_GAP)
    local over = total + TOP_PAD - (LIST_BOTTOM - LIST_TOP)
    return elems, total, over > 0 and math.ceil(over / ROW_STEP) * ROW_STEP or 0
  end

  local function frame_layer()
    return VRFW.crc32(FRAME)
  end

  -- every instance open and loaded (opened once, on the first visit), then set up once
  local function ready()
    if S.ready then
      return true
    end
    local all = true
    for _, pool in ipairs({ { ROW, ROW_COUNT }, { HEAD, HEAD_COUNT } }) do
      for k = 0, pool[2] - 1 do
        if menu(C.IS_OPEN_LAYER, pool[1], k) ~= true then
          all = false
        end
      end
      if menu(C.IS_LOADING_LAYER, pool[1]) == true then
        all = false
      end
    end
    if not all then
      return false
    end
    for k = 0, ROW_COUNT - 1 do
      menu(C.SET_LAYER_VISIBLE, ROW, k, false)
      menu(C.PLAY_ANIME_TYPE, ROW, k, ANIME_ACTIVE, 0, ANIME_DEFAULT)
    end
    for k = 0, HEAD_COUNT - 1 do
      menu(C.SET_LAYER_VISIBLE, HEAD, k, false)
      for _, m in ipairs(HEAD_HIDE) do
        menu(C.SET_MESH_VISIBLE, HEAD, m, false, k)
      end
    end
    S.ready = true
    return true
  end

  local function open_all()
    for _, pool in ipairs({ { ROW, ROW_COUNT }, { HEAD, HEAD_COUNT } }) do
      for k = 0, pool[2] - 1 do
        if menu(C.IS_OPEN_LAYER, pool[1], k) ~= true then
          menu(C.OPEN_LAYER, pool[1], k)
        end
      end
    end
    S.opening = WAIT
  end

  local function put_row(k, e, sy)
    if S.row_key[k] ~= e.row then
      S.row_key[k] = e.row
      UpdateListItem(ROW, k, e.row.effect, e.row.value, 0, 0)
    end
    menu(C.SET_LAYER_LOCAL_POS, ROW, e.x, -sy, 0, k)
    menu(C.SET_LAYER_VISIBLE, ROW, k, true)
    S.row_set[k] = true
  end

  local function put_head(k, e, sy)
    if S.head_key[k] ~= e.card then
      S.head_key[k] = e.card
      VRFW.face_icon.face(HEAD, k, { handle = e.card.handle }, FACE, FACE_SLOT)
      menu(C.SET_MENU_TEXT_STRING, HEAD, TEXT_NAME, e.card.name, k)
    end
    menu(C.SET_LAYER_LOCAL_POS, HEAD, e.x, -sy, 0, k)
    menu(C.SET_LAYER_VISIBLE, HEAD, k, true)
    S.head_set[k] = true
  end

  local function hide_from(set, layer, first, count)
    for k = first, count - 1 do
      if set[k] then
        set[k] = nil
        menu(C.SET_LAYER_VISIBLE, layer, k, false)
      end
    end
  end

  -- the cards at the current scroll: every head / row wholly inside the list area takes the next free instance
  local function draw()
    if not S.active or not ready() then
      return
    end
    local rows, heads = 0, 0
    for _, e in ipairs(S.elems) do
      local sy = LIST_TOP + TOP_PAD + e.y - S.scroll
      local half = e.kind == "row" and ROW_HALF_H or HEAD_HALF_H
      if sy - half >= LIST_TOP and sy + half <= LIST_BOTTOM then
        if e.kind == "row" and rows < ROW_COUNT then
          put_row(rows, e, sy)
          rows = rows + 1
        elseif e.kind == "head" and heads < HEAD_COUNT then
          put_head(heads, e, sy)
          heads = heads + 1
        end
      end
    end
    hide_from(S.row_set, ROW, rows, ROW_COUNT)
    hide_from(S.head_set, HEAD, heads, HEAD_COUNT)
    for _, m in ipairs(SCROLL_MESHES) do
      menu(C.SET_MESH_VISIBLE, frame_layer(), m, S.max_scroll > 0, 0)
    end
  end

  local function pressed(name)
    local now = false
    for _, key in ipairs(KEYS[name]) do
      if cmd(CHECK_INPUT, MENU_CTRL, key) == true then
        now = true
      end
    end
    local was = S.held[name]
    S.held[name] = now
    return now and not was
  end

  Pages.add({
    id = "BetterQoL.player_passives",
    frame = FRAME,
    title = VRFW.crc32("betterqol_player_passives"),
    after = 1,
    valid = function()
      S.cards = read_cards()
      S.elems, S.total, S.max_scroll = lay_out(S.cards)
      S.scroll, S.active, S.ready, S.opening = 0, false, false, 0
      S.row_set, S.head_set, S.row_key, S.head_key, S.held = {}, {}, {}, {}, {}
      VRFW.face_icon.forget(HEAD)
      return #S.cards > 0
    end,
    enter = function()
      S.active, S.scroll, S.held = true, 0, { up = true, down = true }
      if ready() then
        draw()
      else
        open_all()
      end
    end,
    leave = function()
      S.active = false
      hide_from(S.row_set, ROW, 0, ROW_COUNT)
      hide_from(S.head_set, HEAD, 0, HEAD_COUNT)
    end,
    step = function()
      if S.opening > 0 then
        S.opening = S.opening - 1
        if ready() then
          S.opening = 0
          draw()
        elseif S.opening == 0 then
          log("rows did not open: page left empty")
        end
        return
      end
      if S.max_scroll <= 0 then
        return
      end
      local step = (pressed("down") and ROW_STEP or 0) - (pressed("up") and ROW_STEP or 0)
      local to = math.max(0, math.min(S.max_scroll, S.scroll + step))
      if to ~= S.scroll then
        S.scroll = to
        draw()
      end
    end,
  })
end
