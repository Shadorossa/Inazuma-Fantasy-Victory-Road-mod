-- Advanced:
-- lua_patch.scope: used
VRFW.pager = VRFW.pager or {}
do
  local P = VRFW.pager
  local C = {
    EXIST = VRFW.commands.IS_EXIST_LAYER, OPEN = VRFW.commands.OPEN_LAYER, IS_OPEN = VRFW.commands.IS_OPEN_LAYER, LOADING = VRFW.commands.IS_LOADING_LAYER,
    VIS = VRFW.commands.SET_LAYER_VISIBLE,                  -- CMND_SET_LAYER_VISIBLE
    POS = VRFW.commands.SET_LAYER_LOCAL_POS,                 -- layer local position (layer, x, y, z, instance)
    MESH = VRFW.commands.SET_MESH_VISIBLE,                -- CMND_SET_MESH_VISIBLE
    NODE_SIZE = 2885415772,           -- (layer, instance, node, width, height): a quad's size in px
    NODE_VIS = 2158717427,
    TEXT_VIS = VRFW.commands.SET_MENU_TEXT_VISIBLE,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    PRIO = VRFW.commands.SET_DRAW_PRIORITY,                -- CMND_SET_DRAW_PRIORITY (layer, instance, priority, children)
    PLATE = VRFW.commands.UPDATE_TEXT_PLATE,               -- (layer, instance, node): the plate grows to its text
    N_BTN = 950238781,                -- _text_btn01 (the guide's key glyph)
    N_GUIDE = 378156699,              -- _text_guide01 (the guide's text)
    GUIDE_PRIO = 655,                 -- over the card's 570
  }
  -- Advanced: the status base's parts (soccer11_05) and their layout places (x right / y up, top-left of each part)
  P.LOOK = {
    dot_off = 3784855471, dot_on = 2540064569,                 -- _page01_off / _page01_on (32 px)
    glyph_l = 355816102, glyph_r = 59628764,                   -- _text_btn_l01 / _text_btn_r01
    hide = {2788701567, 2606243023, 695779551},                -- _page02..04_off
    locators = {3407216458, 1377611504, 622567014, 3145665477, 1753514051, 790952595, 442049775, 1056264686,
      2946906320, 1437140403},                                 -- every _pos_page* / _pos_equip* / arrow locator
    at_dot = {1362, -949}, at_l = 1039, at_r = 1811, at_gy = -496,
    pitch = 28, dot = 32, gap_l = 40, gap_r = 36, glyph_dy = 8, max = 6,
    left = "<CMD_FUNCL2>", right = "<CMD_FUNCR2>",
    prio = 580,
  }

  -- Internal: the card guide pills' shared stack
  P.LOOK.pill_step = 56
  --- Internal: pager pill states by id (shown, rank).
  P.pills = P.pills or {}
  local function PillDy(id)
    local me = P.pills[id]
    local dy = 0
    for other, p in pairs(P.pills) do
      if me ~= nil and other ~= id and p.shown and p.rank < me.rank then
        dy = dy + P.LOOK.pill_step
      end
    end
    return dy
  end
  --- Internal: The pill offset of `id`: x, y.
  function P.pill_offset(id)
    return 0, PillDy(id)
  end
  --- Advanced: Registers pill `id` with rank and apply function.
  function P.pill_register(id, rank, apply)
    local p = P.pills[id]
    if p == nil then
      p = {shown = false}
      P.pills[id] = p
    end
    p.rank, p.apply = rank, apply
  end
  --- Advanced: Shows or hides pill `id`.
  function P.pill_show(id, shown)
    local p = P.pills[id]
    if p == nil or p.shown == shown then
      return
    end
    p.shown = shown
    for other, q in pairs(P.pills) do
      if q.apply ~= nil then
        pcall(q.apply, P.pill_offset(other))
      end
    end
  end

  --- Advanced: The lit dot of `page` when `pages` pages share `dots` dots: the page's place along the row.
  function P.dot_of_page(page, pages, dots)
    if pages <= dots then
      return page
    end
    return 1 + math.floor((page - 1) * (dots - 1) / (pages - 1) + 0.5)
  end

  --- Advanced: The page a click on `dot` opens when `pages` pages share `dots` dots.
  function P.page_of_dot(dot, pages, dots)
    if pages <= dots then
      return dot
    end
    return 1 + math.floor((dot - 1) * (pages - 1) / (dots - 1) + 0.5)
  end

  local logger
  local function Log(row, ...)
    logger = logger or VRFW.logger.new("VRFW pager")
    logger(tostring(row.name), ...)
  end

  local Row = {}
  Row.__index = Row

  --- Advanced: A new pager row for spec.
  function P.new(spec)
    local row = setmetatable({}, Row)
    row.layer = spec.layer
    row.name = spec.name or tostring(spec.layer)
    row.setup = spec.setup
    row.reopen = spec.reopen
    row.prio = spec.prio or P.LOOK.prio
    row.dots = spec.dots or P.LOOK.max
    row.total = row.dots + 2             -- the two glyphs + the dots
    row.room = spec.room
    row.ycycle = spec.style == "ycycle" and spec.guide ~= nil
    row.guide = spec.guide
    row.key = spec.key or "<CMD_FUNC3>"
    row.guide_set, row.guide_label = false, nil
    if row.ycycle then
      P.pill_register("page_cycle", 1, nil)
    end
    row.opened_instances, row.set, row.gone, row.shown, row.placed = {}, {}, false, false, nil
    return row
  end

  --- True when an instance of the row is open.
  function Row:opened()
    return next(self.opened_instances) ~= nil
  end

  -- instance k: open and loaded; opened once when first asked (again only while spec.reopen answers true)
  local function Ready(row, k)
    if VRFW.host.menu_command(C.IS_OPEN, row.layer, k) == true then
      return VRFW.host.menu_command(C.LOADING, row.layer) ~= true
    end
    if row.opened_instances[k] then
      local again = type(row.reopen) == "function" and row.reopen() == true
      if not again then
        if not row.gone then
          row.gone = true
          Log(row, "closed by the menu: not reopened", k)
        end
        return false
      end
      row.set[k] = nil
    end
    if not row.gone then
      row.opened_instances[k] = true
      VRFW.host.menu_command(C.OPEN, row.layer, k)
    end
    return false
  end

  -- instance k shows one part only (0 = L2 glyph, the last one = R2 glyph, else a dot)
  local function Setup(row, k)
    local L = P.LOOK
    if type(row.setup) == "function" then
      pcall(row.setup, k)
    end
    for _, n in ipairs(L.locators) do
      VRFW.host.menu_command(C.NODE_VIS, row.layer, n, false, k)
    end
    for _, m in ipairs(L.hide) do
      VRFW.host.menu_command(C.MESH, row.layer, m, false, k)
    end
    VRFW.host.menu_command(C.PRIO, row.layer, k, row.prio, true)
    VRFW.host.menu_command(C.TEXT_VIS, row.layer, L.glyph_l, k == 0, k)
    VRFW.host.menu_command(C.TEXT_VIS, row.layer, L.glyph_r, k == row.total - 1, k)
    if k == 0 then
      VRFW.host.menu_command(C.SET_TEXT, row.layer, L.glyph_l, L.left, k)
    elseif k == row.total - 1 then
      VRFW.host.menu_command(C.SET_TEXT, row.layer, L.glyph_r, L.right, k)
    end
    row.placed = nil
  end

  --- True when the row's layer is ready to draw.
  function Row:ready()
    if VRFW.host.menu_command(C.EXIST, self.layer) ~= true then
      return false
    end
    local ready = true
    for k = 0, self.total - 1 do
      if not Ready(self, k) then
        ready = false
      elseif not self.set[k] then
        self.set[k] = true
        Setup(self, k)
      end
    end
    if ready and self.ycycle then
      local g = self.guide
      if VRFW.host.menu_command(C.EXIST, g) ~= true then
        ready = false
      elseif VRFW.host.menu_command(C.IS_OPEN, g, 0) == true then
        if VRFW.host.menu_command(C.LOADING, g) == true then
          ready = false
        elseif not self.guide_set then
          self.guide_set = true
          VRFW.host.menu_command(C.PRIO, g, 0, C.GUIDE_PRIO, true)
          VRFW.host.menu_command(C.SET_TEXT, g, C.N_BTN, self.key, 0)
          VRFW.host.menu_command(C.VIS, g, 0, false)
        end
      else
        ready = false
        if not self.guide_opened and not self.gone then
          self.guide_opened = true
          VRFW.host.menu_command(C.OPEN, g, 0)
        elseif self.guide_opened then
          self.gone = true                         -- the menu closed it: not opened again
          Log(self, "guide closed by the menu: not reopened")
        end
      end
    end
    if ready and not self.logged then
      self.logged = true
      Log(self, "opened", self.total)
    end
    return ready and not self.gone
  end

  --- The distance between dots and their size for n dots: the look's, or both smaller when the row would pass spec.room.
  function Row:fit(n)
    local L = P.LOOK
    if self.room == nil or n < 2 then
      return L.pitch, L.dot
    end
    local pitch = math.min(L.pitch, (self.room - L.gap_l - L.gap_r - L.dot) / (n - 1))
    return pitch, L.dot * pitch / L.pitch
  end

  -- the parts' places for n dots centred at (x, y): position = target top-left - the part's layout place
  local function Place(row, n, x, y)
    local L = P.LOOK
    local pitch, size = row:fit(n)
    local first = x - (n - 1) * pitch / 2
    local glyph_y = y + L.dot / 2 + L.glyph_dy - L.at_gy
    local resize = (row.size or L.dot) ~= size
    for k = 0, row.total - 1 do
      local px, py
      if k == 0 then
        px, py = first - L.dot / 2 - L.gap_l - L.at_l, glyph_y
      elseif k == row.total - 1 then
        px, py = first + (n - 1) * pitch - L.dot / 2 + L.gap_r - L.at_r, glyph_y
      else
        px, py = first + (k - 1) * pitch - size / 2 - L.at_dot[1], y + size / 2 - L.at_dot[2]
        if resize then
          VRFW.host.menu_command(C.NODE_SIZE, row.layer, k, L.dot_off, size, size)
          VRFW.host.menu_command(C.NODE_SIZE, row.layer, k, L.dot_on, size, size)
        end
      end
      VRFW.host.menu_command(C.POS, row.layer, px, py, 0, k)
    end
    row.size = size
    row.placed = string.format("%d %.1f %.1f", n, x, y)
  end

  --- Draws the pager; answers true, or false when it is not ready.
  function Row:show(n, page, x, y, label)
    if not self:ready() then
      return false
    end
    local L = P.LOOK
    n = math.min(n, self.dots)
    if self.placed ~= string.format("%d %.1f %.1f", n, x, y) then
      Place(self, n, x, y)
    end
    for k = 0, self.total - 1 do
      local dot = k >= 1 and k <= n
      VRFW.host.menu_command(C.MESH, self.layer, L.dot_off, dot, k)
      VRFW.host.menu_command(C.MESH, self.layer, L.dot_on, dot and page == k, k)
      local glyph = (k == 0 or k == self.total - 1) and not self.ycycle
      VRFW.host.menu_command(C.TEXT_VIS, self.layer, L.glyph_l, glyph and k == 0, k)
      VRFW.host.menu_command(C.TEXT_VIS, self.layer, L.glyph_r, glyph and k == self.total - 1, k)
      VRFW.host.menu_command(C.VIS, self.layer, k, dot or glyph)
    end
    if self.ycycle then
      local g = self.guide
      if self.guide_label ~= label then
        self.guide_label = label
        VRFW.host.menu_command(C.SET_TEXT, g, C.N_GUIDE, label or "", 0)
        VRFW.host.menu_command(C.PLATE, g, 0, C.N_GUIDE)
      end
      VRFW.host.menu_command(C.VIS, g, 0, true)
      P.pill_show("page_cycle", true)
    end
    self.shown = true
    return true
  end

  --- Every open instance hidden, whoever opened it (the menu opens a layer's instances with its group).
  function Row:hide()
    if VRFW.host.menu_command(C.EXIST, self.layer) ~= true then
      return
    end
    local L = P.LOOK
    for k = 0, self.total - 1 do
      if VRFW.host.menu_command(C.IS_OPEN, self.layer, k) == true then
        VRFW.host.menu_command(C.VIS, self.layer, k, false)
        VRFW.host.menu_command(C.MESH, self.layer, L.dot_off, false, k)
        VRFW.host.menu_command(C.MESH, self.layer, L.dot_on, false, k)
        VRFW.host.menu_command(C.TEXT_VIS, self.layer, L.glyph_l, false, k)
        VRFW.host.menu_command(C.TEXT_VIS, self.layer, L.glyph_r, false, k)
      end
    end
    if self.ycycle and VRFW.host.menu_command(C.IS_OPEN, self.guide, 0) == true then
      VRFW.host.menu_command(C.VIS, self.guide, 0, false)
    end
    if self.ycycle then
      P.pill_show("page_cycle", false)
    end
    self.shown = false
  end
end
