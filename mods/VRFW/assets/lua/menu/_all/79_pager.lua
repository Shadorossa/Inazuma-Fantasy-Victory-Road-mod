-- VRFW page pager: the «L2 • • R2» row of a paged card, as the player page draws it: the L2 and R2 button glyphs and
-- one dot per page (the current one lit: the status base's _page01_on over _page01_off). One function for every card
-- that turns pages (e.g. a technique card or an equipment item card); the callers
-- differ only by their spec.
-- The row lives on a menu layer of copies of the status base (an [[object]] from soccer11_05_formation_status_base,
-- its NullLayerName and touch arrows removed), declared by the caller's menu TOML: instance 0 = the L2 glyph,
-- 1..spec.dots = the page dots, spec.dots + 1 = the R2 glyph (8 copies with the default 6 dots). Each instance shows
-- only its part.
--   local row = VRFW_Pager.New{ layer = <layer crc>, name = "...", setup = function(k) end (optional: extra set-up of
--     instance k, e.g. a trace to the card), reopen = function() return true end (optional: an instance the menu closed
--     may be opened again while it answers true; default never: a closing menu waits on nothing of ours),
--     prio = draw priority of the row (default LOOK.prio), dots = dots the layer has room for (default LOOK.max),
--     room = width in px the whole row may take (optional: more dots than fit bring the dots closer and make them
--     smaller, together) }
--   Y-cycle style (spec.style = "ycycle", spec.guide = <layer crc>): the L2 / R2 glyphs are left out and the card shows
--   the retail keshin cards' page prompt instead: «Y <next page's name>» on the retail change-page plate (an [[object]]
--   from team00_40_change_page_guide, ONE instance, declared by the caller's menu TOML), the dots showing the page; the
--   caller turns the page itself on the key (spec.key = the glyph markup, default "<CMD_FUNC3>", the engine draws the
--   bound button of the device in use) and wraps from the last page to the first.
--   row:Show(n, page, x, y, label) -- the Y style takes the next page's name as `label`
--   Card guide pills (the retail change-page plates at the card's bottom right): one shared stack so two mods' pills never
--   share a spot. Each pill registers with a rank (1 = the bottom one: the Y page pill) and an apply(dx, dy) callback,
--   and reports when it shows or hides; a pill sits above every shown pill of a lower rank:
--     VRFW_Pager.PillRegister(id, rank, apply)   VRFW_Pager.PillShow(id, shown)   VRFW_Pager.PillOffset(id) -> dx, dy
--   (dy in layer position units, y up; VRFW_Pager.LOOK.pill_step apart.) The Y pill of the "ycycle" style is rank 1.
--   row:Ready()            -> true once the instances are open, loaded and set up (opens them when first asked)
--   row:Opened()           -> true once the instances were asked to open
--   row:Show(n, page, x, y) -> the row for n pages (at most spec.dots), page 1..n lit, centred at (x, y) in the layer's
--                              position space (y up); false while the instances are not ready
--   row:Hide()             -> every open instance hidden
--   row.gone               -> an instance was closed by the menu and is not opened again
-- No engine call at load time.
VRFW_Pager = VRFW_Pager or {}
do
  local P = VRFW_Pager
  local C = {
    EXIST = VRFW_Cmd.IS_EXIST_LAYER, OPEN = VRFW_Cmd.OPEN_LAYER, IS_OPEN = VRFW_Cmd.IS_OPEN_LAYER, LOADING = VRFW_Cmd.IS_LOADING_LAYER,
    VIS = VRFW_Cmd.SET_LAYER_VISIBLE,                  -- CMND_SET_LAYER_VISIBLE
    POS = VRFW_Cmd.SET_LAYER_LOCAL_POS,                 -- layer local position (layer, x, y, z, instance)
    MESH = VRFW_Cmd.SET_MESH_VISIBLE,                -- CMND_SET_MESH_VISIBLE
    NODE_SIZE = 2885415772,           -- (layer, instance, node, width, height): a quad's size in px
    NODE_VIS = 2158717427,
    TEXT_VIS = VRFW_Cmd.SET_MENU_TEXT_VISIBLE,
    SET_TEXT = VRFW_Cmd.SET_MENU_TEXT_STRING,
    PRIO = VRFW_Cmd.SET_DRAW_PRIORITY,                -- CMND_SET_DRAW_PRIORITY (layer, instance, priority, children)
    LOG = VRFW_Cmd.EVT_LOG,
    PLATE = VRFW_Cmd.UPDATE_TEXT_PLATE,               -- (layer, instance, node): the plate grows to its text
    N_BTN = 950238781,                -- _text_btn01 (the guide's key glyph)
    N_GUIDE = 378156699,              -- _text_guide01 (the guide's text)
    GUIDE_PRIO = 655,                 -- over the card's 570
  }
  -- the status base's parts (soccer11_05) and their layout places (x right / y up, top-left of each part)
  P.LOOK = {
    dot_off = 3784855471, dot_on = 2540064569,                 -- _page01_off / _page01_on (32 px)
    glyph_l = 355816102, glyph_r = 59628764,                   -- _text_btn_l01 / _text_btn_r01
    hide = {2788701567, 2606243023, 695779551},                -- _page02..04_off
    locators = {3407216458, 1377611504, 622567014, 3145665477, 1753514051, 790952595, 442049775, 1056264686,
      2946906320, 1437140403},                                 -- every _pos_page* / _pos_equip* / arrow locator
    at_dot = {1362, -949}, at_l = 1039, at_r = 1811, at_gy = -496,
    -- the player page's row: dots 28 px apart, L2 40 px left of the first dot, R2 36 px right of the last one, the
    -- glyphs 8 px higher
    pitch = 28, dot = 32, gap_l = 40, gap_r = 36, glyph_dy = 8, max = 6,
    left = "<CMD_FUNCL2>", right = "<CMD_FUNCR2>",
    prio = 580,
  }

  -- the card guide pills' shared stack
  P.LOOK.pill_step = 56
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
  function P.PillOffset(id)
    return 0, PillDy(id)
  end
  function P.PillRegister(id, rank, apply)
    local p = P.pills[id]
    if p == nil then
      p = {shown = false}
      P.pills[id] = p
    end
    p.rank, p.apply = rank, apply
  end
  function P.PillShow(id, shown)
    local p = P.pills[id]
    if p == nil or p.shown == shown then
      return
    end
    p.shown = shown
    for other, q in pairs(P.pills) do
      if q.apply ~= nil then
        pcall(q.apply, P.PillOffset(other))
      end
    end
  end

  local function Cmd(...)
    local r = table.pack(pcall(funcLuaMenuCommand, ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
  end

  local function Log(row, ...)
    pcall(funcLuaCommand, C.LOG, "VRFW pager " .. tostring(row.name), ...)
  end

  local Row = {}
  Row.__index = Row

  function P.New(spec)
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
      P.PillRegister("page_cycle", 1, nil)
    end
    row.opened, row.set, row.gone, row.shown, row.placed = {}, {}, false, false, nil
    return row
  end

  function Row:Opened()
    return next(self.opened) ~= nil
  end

  -- instance k: open and loaded; opened once when first asked (again only while spec.reopen answers true)
  local function Ready(row, k)
    if Cmd(C.IS_OPEN, row.layer, k) == true then
      return Cmd(C.LOADING, row.layer) ~= true
    end
    if row.opened[k] then
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
      row.opened[k] = true
      Cmd(C.OPEN, row.layer, k)
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
      Cmd(C.NODE_VIS, row.layer, n, false, k)
    end
    for _, m in ipairs(L.hide) do
      Cmd(C.MESH, row.layer, m, false, k)
    end
    Cmd(C.PRIO, row.layer, k, row.prio, true)
    Cmd(C.TEXT_VIS, row.layer, L.glyph_l, k == 0, k)
    Cmd(C.TEXT_VIS, row.layer, L.glyph_r, k == row.total - 1, k)
    if k == 0 then
      Cmd(C.SET_TEXT, row.layer, L.glyph_l, L.left, k)
    elseif k == row.total - 1 then
      Cmd(C.SET_TEXT, row.layer, L.glyph_r, L.right, k)
    end
    row.placed = nil
  end

  function Row:Ready()
    if Cmd(C.EXIST, self.layer) ~= true then
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
      if Cmd(C.EXIST, g) ~= true then
        ready = false
      elseif Cmd(C.IS_OPEN, g, 0) == true then
        if Cmd(C.LOADING, g) == true then
          ready = false
        elseif not self.guide_set then
          self.guide_set = true
          Cmd(C.PRIO, g, 0, C.GUIDE_PRIO, true)
          Cmd(C.SET_TEXT, g, C.N_BTN, self.key, 0)
          Cmd(C.VIS, g, 0, false)
        end
      else
        ready = false
        if not self.guide_opened and not self.gone then
          self.guide_opened = true
          Cmd(C.OPEN, g, 0)
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

  -- the distance between dots and their size for n dots: the look's, or both smaller when the row would pass spec.room
  local function Fit(row, n)
    local L = P.LOOK
    if row.room == nil or n < 2 then
      return L.pitch, L.dot
    end
    local pitch = math.min(L.pitch, (row.room - L.gap_l - L.gap_r - L.dot) / (n - 1))
    return pitch, L.dot * pitch / L.pitch
  end

  -- the parts' places for n dots centred at (x, y): position = target top-left - the part's layout place
  local function Place(row, n, x, y)
    local L = P.LOOK
    local pitch, size = Fit(row, n)
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
          Cmd(C.NODE_SIZE, row.layer, k, L.dot_off, size, size)
          Cmd(C.NODE_SIZE, row.layer, k, L.dot_on, size, size)
        end
      end
      Cmd(C.POS, row.layer, px, py, 0, k)
    end
    row.size = size
    row.placed = string.format("%d %.1f %.1f", n, x, y)
  end

  function Row:Show(n, page, x, y, label)
    if not self:Ready() then
      return false
    end
    local L = P.LOOK
    n = math.min(n, self.dots)
    if self.placed ~= string.format("%d %.1f %.1f", n, x, y) then
      Place(self, n, x, y)
    end
    for k = 0, self.total - 1 do
      local dot = k >= 1 and k <= n
      Cmd(C.MESH, self.layer, L.dot_off, dot, k)
      Cmd(C.MESH, self.layer, L.dot_on, dot and page == k, k)
      local glyph = (k == 0 or k == self.total - 1) and not self.ycycle
      Cmd(C.TEXT_VIS, self.layer, L.glyph_l, glyph and k == 0, k)
      Cmd(C.TEXT_VIS, self.layer, L.glyph_r, glyph and k == self.total - 1, k)
      Cmd(C.VIS, self.layer, k, dot or glyph)
    end
    if self.ycycle then
      local g = self.guide
      if self.guide_label ~= label then
        self.guide_label = label
        Cmd(C.SET_TEXT, g, C.N_GUIDE, label or "", 0)
        Cmd(C.PLATE, g, 0, C.N_GUIDE)
      end
      Cmd(C.VIS, g, 0, true)
      P.PillShow("page_cycle", true)
    end
    self.shown = true
    return true
  end

  -- every open instance hidden, whoever opened it (the menu opens a layer's instances with its group)
  function Row:Hide()
    if Cmd(C.EXIST, self.layer) ~= true then
      return
    end
    local L = P.LOOK
    for k = 0, self.total - 1 do
      if Cmd(C.IS_OPEN, self.layer, k) == true then
        Cmd(C.VIS, self.layer, k, false)
        Cmd(C.MESH, self.layer, L.dot_off, false, k)
        Cmd(C.MESH, self.layer, L.dot_on, false, k)
        Cmd(C.TEXT_VIS, self.layer, L.glyph_l, false, k)
        Cmd(C.TEXT_VIS, self.layer, L.glyph_r, false, k)
      end
    end
    if self.ycycle and Cmd(C.IS_OPEN, self.guide, 0) == true then
      Cmd(C.VIS, self.guide, 0, false)
    end
    if self.ycycle then
      P.PillShow("page_cycle", false)
    end
    self.shown = false
  end
end
