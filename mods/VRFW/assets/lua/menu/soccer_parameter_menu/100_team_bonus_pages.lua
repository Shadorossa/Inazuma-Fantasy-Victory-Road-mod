-- VRFW.team_bonus_pages: pages a mod adds to «Bonificaciones de equipo» (soccer_parameter_menu), turned with L1 / R1
-- like the game's own pages (docs/framework/team-bonus-pages.md). The game keeps its pages in the chunk local t4
-- (one row per page: frame layer, title text, valid, open); an added page is one more row of t4, shown at its place in
-- the turning order, on a frame layer the mod declares from the framework object vrfw_team_bonus_page (the game's page
-- frame without its native list). The page dots of the frames are replaced by the framework's own row
-- (layer vrfw_team_bonus_dots) while an added page is valid: the game draws 2 or 3 dots only.
--   VRFW.team_bonus_pages.add{
--     id = "<Mod>.<name>",     the page's id (a second add with the same id replaces the first)
--     frame = "<layer name>",  the mod's frame layer (an add_layer of object vrfw_team_bonus_page with the page's
--                              input rows and focus, content\menus\*.toml)
--     title = <text id>,       the page's title (CMND_TEXT_GET id, e.g. VRFW.crc32 of a menu_text row id)
--     after = 1,               the game's page it follows in the turning order (1 team passives, 2 aura passives,
--                              3 overdrive skills; default 1)
--     guide = 1,               the game's page whose button guide it shows (default 1)
--     valid = function() end,  -> true when the page shows this time (called once per screen open, after OnInit)
--     draw = function(layer, instance) end,  the frame opened
--     enter = function() end, leave = function() end,  the page became the current one / stopped being it
--     step = function() end,  every Step while the page is the current one
--   } -> true, or false, why
--   VRFW.team_bonus_pages.context() -> { dock, kind, in_match, side }: the team the screen shows (its OnInit reads)
--   VRFW.team_bonus_pages.is_frame(layer) -> true for the frame layer of any page (the game's three and the added ones)
-- No engine call at load time.
if VRFW.host ~= nil and VRFW.team_bonus_pages == nil then
  local P = { list = {} }
  --- Advanced: State of the team bonus pages added to the parameter screen.
  VRFW.team_bonus_pages = P

  local STEM = "soccer_parameter_menu"
  local RETAIL_FRAMES = { 862546245, 894775456, 1271870573 }   -- the game's team / aura / override frames
  local DOT_LAYER = VRFW.crc32("vrfw_team_bonus_dots")
  local DOT_COUNT = 6                       -- instances of vrfw_team_bonus_dots (content\menus\team_bonus_pages.toml)
  local DOT_PITCH = 28                      -- the game's page dots: 28 px apart (soccer11_21 _page02_01 .. _03)
  local DOT_CENTRE = 960                    -- the row's centre (the game's dots are centred on the screen)
  local DOT_SELF = 932                      -- the centre of the dot the copies keep (_page02_01, x 916 + 16)
  local DOT_WAIT = 300                      -- Steps a copy may take to open before the row is given up
  local NODE_VISIBLE = 2158717427           -- (layer, node, visible, instance)
  local TEXT_VISIBLE = 2735666188           -- (layer, text node, visible, instance)
  local C = VRFW.commands

  local log = VRFW.logger.new("VRFW team bonus pages")
  local S = { retail = nil, order = {}, index = {}, frames = {}, current = nil, dots = {}, dot_wait = 0, dots_gone = false }

  local function crc(name)
    return VRFW.crc32(name)
  end

  -- the game's dot nodes of a frame (both the 2-dot and the 3-dot rows)
  local RETAIL_DOTS = { "_page01_off", "_page02_off", "_page01_on", "_page02_on", "_page02_01_off", "_page02_02_off",
    "_page02_03_off", "_page02_01_on", "_page02_02_on", "_page02_03_on" }
  -- every part of a dot copy but its one dot
  local DOT_HIDE = { "_win_teamparameter01", "_gtxt_teamparameter01", "_scr_line01", "_scr_obj01", "_arrow01_r",
    "_arrow01_l", "_page01_off", "_page02_off", "_page02_02_off", "_page02_03_off", "_teambuild_base01", "_page01_on",
    "_page02_on", "_page02_02_on", "_page02_03_on", "_gtxt_teambuild01", "_icon_build_dmy01" }
  local DOT_TEXTS = { "_text_page01", "_text_btn_l01", "_text_btn_r01", "_text_build01" }
  local DOT_OFF, DOT_ON = crc("_page02_01_off"), crc("_page02_01_on")

  local function locals()
    local h = VRFW.host.hosts[STEM]
    return h and h.L or nil
  end

  --- Advanced: Adds page `d` (see the header); answers true, or false, why.
  function P.add(d)
    if type(d) ~= "table" or type(d.id) ~= "string" or type(d.frame) ~= "string" or type(d.title) ~= "number" then
      return false, "a page needs id, frame (layer name) and title (text id)"
    end
    local after = d.after or 1
    if type(after) ~= "number" or after < 1 or after > #RETAIL_FRAMES then
      return false, "after must be one of the game's pages 1.." .. #RETAIL_FRAMES
    end
    local page = { id = d.id, frame = crc(d.frame), title = d.title, after = after, guide = d.guide or 1, valid = d.valid,
      draw = d.draw, enter = d.enter, leave = d.leave, step = d.step }
    for k, old in ipairs(P.list) do
      if old.id == d.id then
        P.list[k] = page
        return true
      end
    end
    P.list[#P.list + 1] = page
    return true
  end

  --- Advanced: The team the screen shows: { dock, kind, in_match, side } (its OnInit reads); nil before OnInit.
  function P.context()
    local L = locals()
    if L == nil then
      return nil
    end
    return { dock = L.n4, kind = L.n5, in_match = L.flag == true, side = L.n7 }
  end

  --- Internal: True for the frame layer of any page (the game's three and the added ones).
  function P.is_frame(layer)
    for _, f in ipairs(RETAIL_FRAMES) do
      if f == layer then
        return true
      end
    end
    return S.frames[layer] ~= nil
  end

  local function call(page, name, ...)
    local fn = page[name]
    if type(fn) ~= "function" then
      return nil
    end
    local ok, r = pcall(fn, ...)
    if not ok then
      log(page.id, name, "failed:", tostring(r))
      return nil
    end
    return r
  end

  -- t4 index -> added page (nil for the game's)
  local function page_at(i)
    return S.index[i]
  end

  local function any_valid(L)
    for i, _ in pairs(S.index) do
      if L.t4[i] ~= nil and L.t4[i].isValid then
        return true
      end
    end
    return false
  end

  -- the turning order: each game page, then the pages added after it
  local function build_order()
    local order = {}
    for i = 1, S.retail do
      order[#order + 1] = i
      for k = S.retail + 1, S.retail + #P.list do
        local page = S.index[k]
        if page ~= nil and page.after == i then
          order[#order + 1] = k
        end
      end
    end
    S.order = order
  end

  -- the place of the current page among the valid ones, and their count
  local function place(L)
    local count, at = 0, 0
    for _, i in ipairs(S.order) do
      local tab = L.t4[i]
      if tab ~= nil and tab.isValid then
        count = count + 1
        if i == L.n then
          at = count
        end
      end
    end
    return at, count
  end

  -- dot copy k open and set up; false while it opens
  local function dot_ready(k)
    if S.dots[k] == "set" then
      return VRFW.host.menu_command(C.IS_OPEN_LAYER, DOT_LAYER, k) == true
    end
    if VRFW.host.menu_command(C.IS_OPEN_LAYER, DOT_LAYER, k) ~= true then
      if S.dots[k] == nil then
        S.dots[k] = "opening"
        VRFW.host.menu_command(C.OPEN_LAYER, DOT_LAYER, k)
      end
      return false
    end
    if VRFW.host.menu_command(C.IS_LOADING_LAYER, DOT_LAYER) == true then
      return false
    end
    for _, m in ipairs(DOT_HIDE) do
      VRFW.host.menu_command(C.SET_MESH_VISIBLE, DOT_LAYER, crc(m), false, k)
    end
    for _, t in ipairs(DOT_TEXTS) do
      VRFW.host.menu_command(TEXT_VISIBLE, DOT_LAYER, crc(t), false, k)
    end
    S.dots[k] = "set"
    return true
  end

  -- the dot row for the current page; true when drawn (false while a copy still opens)
  local function draw_dots()
    local L = locals()
    if L == nil or S.dots_gone or VRFW.host.menu_command(C.IS_EXIST_LAYER, DOT_LAYER) ~= true then
      return true
    end
    local at, count = place(L)
    local wanted = any_valid(L) and count >= 2
    if count > DOT_COUNT then
      log("more pages than dots:", count, DOT_COUNT)
      count = DOT_COUNT
    end
    local ready = true
    for k = 0, DOT_COUNT - 1 do
      if wanted and k < count then
        if dot_ready(k) then
          local x = DOT_CENTRE - (count - 1) * DOT_PITCH / 2 + k * DOT_PITCH - DOT_SELF
          VRFW.host.menu_command(C.SET_LAYER_LOCAL_POS, DOT_LAYER, x, 0, 0, k)
          VRFW.host.menu_command(C.SET_MESH_VISIBLE, DOT_LAYER, DOT_OFF, true, k)
          VRFW.host.menu_command(C.SET_MESH_VISIBLE, DOT_LAYER, DOT_ON, k == at - 1, k)
          VRFW.host.menu_command(C.SET_LAYER_VISIBLE, DOT_LAYER, k, true)
        else
          ready = false
        end
      elseif S.dots[k] == "set" then
        VRFW.host.menu_command(C.SET_LAYER_VISIBLE, DOT_LAYER, k, false)
      end
    end
    if ready then
      S.dot_wait = 0
    elseif S.dot_wait == 0 then
      S.dot_wait = DOT_WAIT             -- Step draws the row again until the copies are open
    end
    return ready
  end

  local function set_current(L)
    local now = page_at(L.n)
    if now == S.current then
      return
    end
    if S.current ~= nil then
      call(S.current, "leave")
    end
    S.current = now
    if now ~= nil then
      call(now, "enter")
    end
  end

  -- after OnInit (it read the dock, kind and match side): the added pages join t4, the turning order is built
  VRFW.host.on(STEM, "OnInit", { id = "VRFW.team_bonus_pages", phase = "after", fn = function()
    local L = locals()
    if L == nil or type(L.t4) ~= "table" then
      log("no t4: pages not added")
      return
    end
    local t4 = L.t4
    S.retail = S.retail or #t4
    for i = #t4, S.retail + 1, -1 do
      t4[i] = nil
    end
    S.index, S.frames, S.current, S.dots, S.dots_gone = {}, {}, nil, {}, false
    if #P.list == 0 then
      S.order = {}
      return
    end
    for _, page in ipairs(P.list) do
      local i = #t4 + 1
      t4[i] = { baseLayerName = page.frame, itemLayerName = 0, nameTextId = page.title,
        isValid = call(page, "valid") == true, isOpen = false }
      S.index[i] = page
      S.frames[page.frame] = page
    end
    build_order()
    local valid = 0
    for i = 1, #t4 do
      if t4[i].isValid then
        valid = valid + 1
      end
    end
    L.n2 = valid
  end })

  -- the turning order walks the game's pages and the added ones; invalid pages are skipped (one lap at most)
  VRFW.host.on(STEM, "SearchMoveTabIndex", { id = "VRFW.team_bonus_pages", fn = function(nxt, from, dir)
    local L = locals()
    if L == nil or #S.order == 0 then
      return nxt(from, dir)
    end
    if (L.n2 or 0) <= 1 then
      return from
    end
    local pos = 1
    for k, i in ipairs(S.order) do
      if i == from then
        pos = k
      end
    end
    local step = (dir or 1) < 0 and -1 or 1
    for _ = 1, #S.order do
      pos = (pos - 1 + step) % #S.order + 1
      local tab = L.t4[S.order[pos]]
      if tab ~= nil and tab.isValid then
        return S.order[pos]
      end
    end
    return from
  end })

  -- an added page leaves before the frame's slide-out
  VRFW.host.on(STEM, "ChangeCurrentTabIndex", { id = "VRFW.team_bonus_pages", phase = "before", fn = function()
    if S.current ~= nil then
      call(S.current, "leave")
      S.current = nil
    end
  end })

  -- an added frame: the build header like the game's frames (before, so a later header patch still draws over it)
  VRFW.host.on(STEM, "OnSetupLayer", { id = "VRFW.team_bonus_pages", phase = "before", fn = function(layer, instance)
    if S.frames[layer] ~= nil and type(SetTeamBuildIconInfo) == "function" then
      SetTeamBuildIconInfo(layer, instance)
    end
  end })

  -- an added frame opened: set up like the game's last frame (title, focus, collisions, the current page shown)
  VRFW.host.on(STEM, "OnOpenLayer", { id = "VRFW.team_bonus_pages", phase = "after", fn = function(_, layer, instance)
    local page = S.frames[layer]
    if page == nil then
      return
    end
    local L = locals()
    for i, p in pairs(S.index) do
      if p == page and L.t4[i] ~= nil then
        SetupViewTab(i, instance)
        L.t4[i].isOpen = true
      end
    end
    RefreshOnChangeFocusMouse()
    RefreshFullScreenCollision()
    OnEndChangeCurrentTab()
    call(page, "draw", layer, instance)
  end })

  -- a frame set up: its own dots hidden while the framework's row is drawn
  VRFW.host.on(STEM, "SetupViewTab", { id = "VRFW.team_bonus_pages", phase = "after", fn = function(_, i, instance)
    local L = locals()
    if L == nil or not any_valid(L) or L.t4[i] == nil then
      return
    end
    local frame = L.t4[i].baseLayerName
    for _, node in ipairs(RETAIL_DOTS) do
      VRFW.host.menu_command(NODE_VISIBLE, frame, crc(node), false, instance)
    end
    draw_dots()
  end })

  -- the page turned: the added page entered / left, the dots follow
  VRFW.host.on(STEM, "OnEndChangeCurrentTab", { id = "VRFW.team_bonus_pages", phase = "after", fn = function()
    local L = locals()
    if L == nil or #S.order == 0 then
      return
    end
    set_current(L)
    draw_dots()
  end })

  -- an added page shows the button guide of the game's page it names
  VRFW.host.on(STEM, "RefreshButtonGuide", { id = "VRFW.team_bonus_pages", fn = function(nxt, i, ...)
    local page = page_at(i)
    if page ~= nil then
      return nxt(page.guide, ...)
    end
    return nxt(i, ...)
  end })

  VRFW.host.on(STEM, "Step", { id = "VRFW.team_bonus_pages", phase = "after", create = true, fn = function()
    if S.dot_wait > 0 then
      S.dot_wait = S.dot_wait - 1
      if S.dot_wait == 0 then
        S.dots_gone = true
        log("page dots did not open: not drawn")
      else
        draw_dots()
      end
    end
    if S.current ~= nil then
      call(S.current, "step")
    end
  end })
end
