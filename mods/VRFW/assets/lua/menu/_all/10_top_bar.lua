--            nearest in x to the element. The menu is set inactive meanwhile (MENU_ACTIVE false: it sees none of the
-- Safety: refused (buzzer) while a message window is open, a fade runs, the game saves, a reserved slot's game (a mod's
if VRFW.top_bar == nil then
  local TB = {
    Y = 34, SIZE = 46, CELL_K = 1.55, GAP = 6, RIGHT = 1892, PLATE = 60, -- row geometry (screen px; fits a short header bar of 67 px)
    HOVER_SCALE = 1.06,                                  -- the highlighted icon grows a little (Windows-like: subtle)
    HOLD = 42, SEL_FRAMES = 300, CHECK_EVERY = 6, MAX = 8,   -- MAX: set at Init from the layer count
    NAV_WAIT = 4,                                        -- frames an UP may take to move the menu's focus
    DEBUG = false,   -- release the "dbg" lines of loader.log only with true
    TEX_MIN = 10, TEX_MAX = 600,
    DEFER_MAX = 3600,                                    -- title: frames a deferred target may wait, then dropped
    DIRECT = true,
    DROP_CELL = 60, DROP_H = 56, DROP_ICON = 38, DROP_PAD = 6, DROP_GAP = 4, DROP_MAX = 6,
    SCREEN_W = 1920, SCREEN_MARGIN = 8,
    DROP_GRACE = 15,                                     -- frames (~250 ms) the pointer may be off icon + dropdown
    dsel = nil, dshut = false, has_drop = false, xs = {}, ws = {}, drop_drawn = false, drop_out = nil,
    on = false, menu = nil, entries = {}, shown = false, sel = nil, sel_t = 0, held = 0, mouse = false,
    px = nil, py = nil, prev = {},
    co = nil, frame = 0, wrapped = false, logn = 0, cur = {}, block = false,
    tex_ready = false, tex_t = 0, dbg_open = nil, dbg_steps = 0, dbg_gpos = false, dbg_ptr = false,
    has_back = false, back_on = false,
    fev = 0, flayer = nil, fidx = nil, nav = false, nav_from = nil, up = nil, release = nil, self_focus = false,
    defer_t = 0, right = 1892, rank_log = false,
    PRIO = {vrfw_topbar_back = 1006, vrfw_topbar_plate = 1007, vrfw_topbar_icon = 1008, vrfw_topbar_hint = 1009,
            vrfw_topbar_drop_plate = 1010, vrfw_topbar_drop_icon = 1011, vrfw_topbar_drop_label = 1012},
    raised = false, fading = false,
  }
  VRFW.top_bar = TB

  local L_ICON, L_PLATE = 2854477426 --[[vrfw_topbar_icon]], 3730537440 --[[vrfw_topbar_plate]]
  local L_BACK = 2725852830 --[[vrfw_topbar_back: the glass strip of a standalone row]]
  local L_DPLATE = 2487596098 --[[vrfw_topbar_drop_plate: instance 0 the dropdown's panel, 1 the row highlight]]
  local L_DICON = 1799961878 --[[vrfw_topbar_drop_icon: the dropdown's row icons]]
  local L_DLABEL = 3950785521 --[[vrfw_topbar_drop_label: the row labels (the styling mod's object; hidden at setup)]]
  local HEADER = 575058101            -- mainmenu90_01_header
  local NODE_POS = 2575768773
  local NODE_QUAD = 1909474081        -- icon_new01 (the cmn01_10 quad's sprite node)
  local MESH_QUAD = 312193881         -- its mesh (CMND_SET_PRIM_COLOR)
  local Q = 36                        -- cmn01_10 quad size
  local VRFW_Cmd = VRFW.commands -- the D6 MENU_ACTIVE line of C keeps its HEAD text
  local C = {
    LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM, DRAW_PRIO = VRFW.commands.SET_DRAW_PRIORITY --[[CMND_SET_DRAW_PRIORITY (layer, idx, prio, children)]], IS_OPEN = VRFW.commands.IS_OPEN_MENU_OBJECT, EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT,
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE, SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE, POS = VRFW.commands.SET_LAYER_LOCAL_POS, SPRITE = 558735651, PRIM_COLOR = VRFW.commands.SET_PRIM_COLOR,
    LOAD_TEX = VRFW.commands.LOAD_MENU_RES_TEXTURE, TEX_LOADING = 1506186496,
    CHECK_INPUT = VRFW.commands.CHECK_INPUT_CMD, MENU_CTRL = 1332654303, ANALOG_CTRL = 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]],
    KEY = 333012723 --[[CMD_VRFW_TOPBAR_ON]],
    OPEN = 4165572102 --[[CMD_VRFW_TOPBAR_OPEN: the bar's open button, a mod's rebindable input action, e.g. L3 / N]],
    INPUT_ACTION = VRFW.commands.VRFW_INPUT_ACTION --[[CMND_VRFW_INPUT_ACTION (command or action id) -> the action's declaration]],
    CLICK = 749879980 --[[CMD_VRFW_MOUSE_LEFT]], MOVED = 3272825600, POINTER = 558229292, GPOS = 4002164178,
    ENTER_CLICK = 1651523701 --[[CMD_ENTER_CLICK: mouse, Enter, A]], ENTER = 1981080283 --[[CMD_ENTER: Enter, A]],
    CANCEL = 3602695835 --[[CMD_CANCEL: Esc, B]],
    UP = 1197218715, DOWN = 3259546669, LEFT = 2765147006, RIGHT = 2075023265,
    FOCUS_SET = 1778826357 --[[(layer, idx, on): the control focus on / off an element (retail ChangeFocusToNextLayer)]],
    SE = VRFW.commands.SND_PLAY_SE, SE_GO = 766561556 --[[sy0080]], SE_NO = 2086672038 --[[sy0003]], SE_MOVE = 3848881948,
    SE_BACK = 202039849 --[[sy0006]],
    MENU_ACTIVE = 1558704558, MSG_BUSY = 898725220, IS_FADE = VRFW_Cmd.BRIGHT_IS_FADE, SAVE_WORKING = 1979970074,
    SESSION = VRFW.commands.VRFW_SESSION_STATE, SLOT_ACTIVE = VRFW.commands.VRFW_SLOT_ACTIVE,
    SLOT_RESERVED = VRFW.commands.VRFW_SLOT_RESERVED,
    TB_HOST = {VRFW.commands.VRFW_MENU_TOPBAR_HOST, VRFW.commands.VRFW_MENU_TOPBAR_HOST},
    TB_TITLE = {VRFW.commands.VRFW_MENU_TOPBAR_TITLE, VRFW.commands.VRFW_MENU_TOPBAR_TITLE},
    AUTO_SAVE = VRFW.commands.SYSTEM_AUTO_SAVE, FADE = 609722083, FADE_DONE = 2259183189, BUSY = 2736534827,
    GAME_RESET = VRFW.commands.GAME_RESET,
    CARRY = VRFW.commands.VRFW_SLOT_CARRY,
  }
  C.NAV = {C.UP, C.DOWN, C.LEFT, C.RIGHT}
  C.CTRL_FOCUS_ACTIVE = VRFW.commands.IS_CTRL_FOCUS_ACTIVE --[[CMND_IS_CTRL_FOCUS_ACTIVE (layer)]]
  C.FOCUS_INDEX = 2603265800 --[[(layer) -> the focused instance]]
  C.LAYER_EXISTS = VRFW.commands.IS_EXIST_LAYER --[[CMND_IS_EXIST_LAYER (layer)]]
  C.PLAY_ANIME = VRFW.commands.PLAY_ANIME_TYPE --[[CMND_PLAY_ANIME_TYPE (layer, idx, type, state, set)]]
  C.ATTACH_TRACE = VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE --[[CMND_SET_LAYER_ATTACH_LOCATOR_TRACE (layer, idx, locator, on)]]
  C.ANIME_FOCUS, C.ANIME_SET_BUTTON = 2734777837 --[[Focus]], 973515837 --[[button]]
  C.LOCATOR_CURSOR = 3313461902 --[[cursor]]
  C.PAD, C.VKEY = VRFW.commands.VRFW_INPUT_PAD, VRFW.commands.VRFW_INPUT_KEY
  C.DEV = {
    [C.OPEN] = {pad = 0x2, vk = {0x4E}}, [C.UP] = {pad = 0x10, vk = {0x26}}, [C.RIGHT] = {pad = 0x20, vk = {0x27}},
    [C.DOWN] = {pad = 0x40, vk = {0x28}}, [C.LEFT] = {pad = 0x80, vk = {0x25}},
    [C.ENTER] = {pad = 0x4000, vk = {0x0D}}, [C.CANCEL] = {pad = 0x2000, vk = {0x1B}},
  }
  local K = {
    BUSY = 2173683199,      -- vrfw_top_bar_busy: a shortcut is in flight (any VM)
    TARGET = 2566540065,
    STEP = 229413441,
    DEFER = 3408963264,
    DIRECT = 1469556327,
    NAV = 1768396853,
    HIDE = 1455983968,
  }
  local TT = {known = false, go = nil, box = nil, item = nil, clear = {}, session = {}}
  local BLOCK_MENUS = {968210065 --[[sub_window]]}
  local TITLE = "title_menu_2"

  local logger
  local function Log(...)
    if TB.logn >= (TB.DEBUG and 200 or 60) then return end
    TB.logn = TB.logn + 1
    local p = {}
    for i = 1, select("#", ...) do p[#p + 1] = tostring((select(i, ...))) end
    logger = logger or VRFW.logger.new("EVT top_bar")
    logger.debug(tostring(TB.name) .. " " .. table.concat(p, " "))
  end

  local function Crc(s)
    local n = tonumber(s)
    if n ~= nil then return n end
    return CRC32(s)
  end

  local function P(k, v)
    if k == nil then return end                       -- a hand-off param no mod declared
    if VRFW.param.has(k) then VRFW.param.clear(k) end
    if v ~= nil then VRFW.param.set(k, v) end
  end

  local function Clear(...)
    for i = 1, select("#", ...) do P((select(i, ...)), nil) end
  end

  local function Take(k)
    return VRFW.param.take(k)
  end

  -- the menu this VM runs, from the script stem the loader gives the patch files ("soccer_top_menu_1.03.98.00")
  local stem = type(VRFW.patch) == "table" and VRFW.patch.script or nil
  if type(stem) == "string" then
    TB.name = stem:gsub("_%d+%.%d+%.%d+[%.%d]*$", "")
  end
  TB.host = {}

  local function Rules(ids, ...)
    for _, id in ipairs(ids) do
      local r = table.pack(VRFW.host.command(id, ...))
      if r[1] ~= nil then return table.unpack(r, 1, r.n) end
    end
    return nil
  end

  local function Nums(s)
    local out = {}
    for n in tostring(s or ""):gmatch("[^,%s]+") do out[#out + 1] = tonumber(n) end
    return out
  end

  local function LoadRules()
    local known, gate, leave, session, dpad, open, rank_centre, standalone, rplate, rnode, rcx, ravoid, open_yield,
      variants, open_hold, active_only, plates = Rules(C.TB_HOST, TB.name or "")
    TB.host = {}
    TB.plates_atlas = (type(plates) == "string" and plates ~= "") and plates or nil
    local function nz(v) return (type(v) == "number" and v ~= 0) and v or nil end
    TB.rank = {plate = nz(rplate), node = nz(rnode), centre_x = nz(rcx), avoid = nz(ravoid)}
    if known == true then
      TB.host = {gate = gate ~= "" and gate or nil, leave = leave ~= "" and leave or nil, session = session == true,
                 dpad = dpad ~= false, open = open == true, rank_centre = rank_centre == true,
                 standalone = (standalone ~= nil and standalone ~= "") and CRC32(standalone) or nil,
                 open_yield = Nums(open_yield), variants = Nums(variants),
                 open_hold = (type(open_hold) == "number" and open_hold > 0) and open_hold or 0, active_only = active_only == true}
    end
    local oka, act = pcall(funcLuaCommand, C.INPUT_ACTION, "CMD_VRFW_TOPBAR_OPEN")
    if oka and type(act) == "table" and act.declared == 1 then
      TB.open_raw = false
      C.DEV[C.OPEN] = {pad = (type(act.pad_mask) == "number" and act.pad_mask > 0) and act.pad_mask or nil,
                       vk = (type(act.vk) == "number" and act.vk > 0) and {act.vk} or {}}
    else
      TB.open_raw = true
      C.DEV[C.OPEN] = {pad = 0x2, vk = {0x4E}}
    end
    if TB.host.open then
      Log("open button", TB.open_raw and "LS / N read from the devices (no action declares CMD_VRFW_TOPBAR_OPEN)"
        or ("action " .. tostring(act.id) .. ", default pad mask " .. tostring(act.pad_mask) .. " vk " .. tostring(act.vk)))
    end
    local tk, go, box, fitem, clear, sess = Rules(C.TB_TITLE)
    TT.known = tk == true
    TT.go = (tk == true and type(go) == "number" and go ~= 0) and go or nil
    TT.box = (type(box) == "number" and box ~= 0) and box or nil
    TT.item = (type(fitem) == "number" and fitem ~= 0) and fitem or nil
    TT.clear, TT.session = Nums(clear), Nums(sess)
  end

  local function HostFn(name)
    if type(name) ~= "string" then return nil end
    local f = _G[name]
    if f == nil and name:find(".", 1, true) then
      f = _G
      for part in name:gmatch("[^%.]+") do
        if type(f) ~= "table" then return nil end
        f = rawget(f, part)
      end
    end
    return type(f) == "function" and f or nil
  end

  local function ResolveMenu()
    if TB.menu_ok then return end
    local vs = TB.host.variants or {}
    if #vs == 0 then TB.menu_ok = true return end
    local cands = {TB.self_crc}
    for _, v in ipairs(vs) do cands[#cands + 1] = v end
    for _, m in ipairs(cands) do
      if funcLuaMenuCommand(C.EXISTS, m) == true then
        TB.menu, TB.menu_ok = m, true
        if VRFW.top_bar.guard ~= nil and VRFW.top_bar.guard.menus ~= nil then VRFW.top_bar.guard.menu = m end
        Log("menu", m, m == TB.self_crc and "(the script's own)" or "(a variant)")
        return
      end
    end
  end

  -- `active_only` hosts: the menu's own Lua wants it active (its last MENU_ACTIVE for itself, kept by the input guard;
  local function OwnActive()
    if not TB.host.active_only then return true end
    local gd = VRFW.top_bar.guard
    return gd == nil or gd.wish ~= false
  end

  local function OpenYields()
    for _, m in ipairs(TB.host.open_yield or {}) do
      if funcLuaMenuCommand(C.EXISTS, m) == true then return true end
    end
    return false
  end

  local function SessionOpen()
    local open, _, _, _, _, _, swapped = VRFW.host.command(C.SESSION)
    return open == true, open == true and swapped == true
  end

  local function ReadEntry(i)
    local key, text, icon, kind, value, _owner, _vid, menus, steps, group, aspect,
      _ord, _pon, _poff, _fl, _pl, _it, _lk, _lt, _gt, dmenu, dvs, dmode, direct =
      funcLuaCommand(VRFW.commands.VRFW_MENU_ENTRY, "top_bar", i)
    if key == nil then return nil end
    -- an entry whose id names a mode switched off ([modes] of a mod's config, CMND_VRFW_MODE_ENABLED) is left out
    local id = tostring(key):match("([^%.]+)$")
    local okm, known, mode_on = pcall(funcLuaCommand, VRFW.commands.VRFW_MODE_ENABLED, id)
    if okm and known == true and mode_on == false then return nil end
    -- a shortcut into a mode the framework blocks (online guard) is left out
    if kind == "title" then
      local okb, blocked = pcall(funcLuaCommand, VRFW.commands.VRFW_BLOCKED, value)
      if okb and blocked == true then return nil end
    end
    local e = {key = key, kind = kind, value = value, menus = {}, steps = tostring(steps or ""),
               group = tostring(group or ""), aspect = (type(aspect) == "number" and aspect > 0) and aspect or 1}
    if direct == true and kind == "title" then
      e.direct = {menu = (type(dmenu) == "number" and dmenu ~= 0) and dmenu or 0, vs = dvs == true,
                  mode = (type(dmode) == "number" and dmode >= 0) and dmode or 0}
    end
    local tex, spr = tostring(icon or ""):match("^(.*):([^:]+)$")
    if tex ~= nil then
      e.tex, e.tex_crc, e.spr = tex, CRC32(tex), CRC32(spr)
    end
    for m in tostring(menus or ""):gmatch("[^,%s]+") do e.menus[#e.menus + 1] = Crc(m) end
    if text ~= nil and text ~= "" then
      local okt, t = pcall(funcLuaCommand, VRFW.commands.VRFW_TEXT_GET, text)
      e.label = (okt and type(t) == "string" and t ~= "") and t or nil
    end
    return e
  end

  local function LoadEntries()
    local out = {}
    local ok, n = pcall(funcLuaCommand, VRFW.commands.VRFW_MENU_ENTRY_COUNT, "top_bar")
    if not ok or type(n) ~= "number" then return out end
    local bar, rows, groups = {}, {}, {}
    for i = 1, n do
      local e = ReadEntry(i)
      if e ~= nil and e.group ~= "" then
        rows[e.group] = rows[e.group] or {}
        table.insert(rows[e.group], e)
      elseif e ~= nil and e.kind == "group" then
        if groups[e.value] == nil then
          groups[e.value] = e
          bar[#bar + 1] = e
        else
          Log("group", e.value, "declared again by", e.key, ": the first,", groups[e.value].key, ", is kept")
        end
      elseif e ~= nil then
        bar[#bar + 1] = e
      end
    end
    local want = rawget(VRFW, "top_bar_order")
    if type(want) == "table" then
      local rank = {}
      for i, k in ipairs(want) do if rank[k] == nil then rank[k] = i end end
      local pos = {}
      for i, e in ipairs(bar) do pos[e] = i end
      table.sort(bar, function(a, b)
        local ra, rb = rank[a.key] or (1000 + pos[a]), rank[b.key] or (1000 + pos[b])
        return ra < rb
      end)
    end
    for g, list in pairs(rows) do
      if groups[g] == nil then Log("group", g, "not declared: its", #list, "entries are left out") end
    end
    for _, e in ipairs(bar) do
      if e.kind == "group" then
        local list = rows[e.value] or {}
        e.items = {}
        for k = 1, math.min(#list, TB.DROP_MAX) do e.items[k] = list[k] end
        if #list > TB.DROP_MAX then Log("group", e.value, ":", #list, "entries, the first", TB.DROP_MAX, "are shown") end
        if #e.items == 0 then
          Log("group", e.value, "left out: no entry")
        elseif not TB.has_drop then
          Log("group", e.value, "left out: this menu has no dropdown layers (vrfw_topbar_drop_icon)")
        else
          out[#out + 1] = e
        end
      else
        out[#out + 1] = e
      end
      if #out >= TB.MAX then break end
    end
    return out
  end

  -- every atlas the row and its dropdowns use (crc32 of the path -> the path)
  local function Atlases()
    local t = {}
    for _, e in ipairs(TB.entries) do
      if e.tex_crc ~= nil then t[e.tex_crc] = e.tex end
      for _, it in ipairs(e.items or {}) do
        if it.tex_crc ~= nil then t[it.tex_crc] = it.tex end
      end
    end
    return t
  end

  local function Layout()
    local n = #TB.entries
    local x = TB.right or TB.RIGHT
    local cell = TB.SIZE * TB.CELL_K
    TB.xs, TB.ws = {}, {}
    for i = n, 1, -1 do
      TB.ws[i], TB.xs[i] = cell, x - cell / 2
      x = x - cell - TB.GAP
    end
  end

  local function X(i)  -- centre x of icon i (1-based)
    if TB.xs[i] == nil then Layout() end
    return TB.xs[i] or (TB.right or TB.RIGHT)
  end

  local function W(i)  -- width of icon i's cell (the same for every shortcut)
    if TB.ws[i] == nil then Layout() end
    return TB.ws[i] or TB.SIZE * TB.CELL_K
  end

  local function IconSize(i)
    local asp = TB.entries[i] and TB.entries[i].aspect or 1
    local w = math.min(TB.SIZE * asp, W(i))
    return w, w / asp
  end

  local function DropGroup()
    local g = TB.sel ~= nil and TB.entries[TB.sel] or nil
    if g == nil or g.kind ~= "group" or TB.dshut then return nil end
    return g
  end

  local function DropBox(gi)
    local g = TB.entries[gi]
    local count = #g.items
    local cell = TB.DROP_CELL
    for _, it in ipairs(g.items) do cell = math.max(cell, math.ceil(TB.DROP_ICON * (it.aspect or 1)) + 16) end
    local w = count * cell + 2 * TB.DROP_PAD
    local h = TB.DROP_H + 2 * TB.DROP_PAD
    local left = X(gi) - w / 2
    left = math.min(left, TB.SCREEN_W - TB.SCREEN_MARGIN - w)
    left = math.max(TB.SCREEN_MARGIN, left)
    local top = TB.Y + TB.PLATE / 2 + TB.DROP_GAP
    return left, top, w, h, cell
  end

  -- centre x of the dropdown's icon k (1-based) in a box of DropBox
  local function DropCellX(left, cell, k)
    return left + TB.DROP_PAD + (k - 0.5) * cell
  end

  -- the dropdown icon under the pointer (0 = on the open dropdown but on no icon, nil = not on it).
  local function DropPointed(mx, my)
    local g = DropGroup()
    if g == nil or type(mx) ~= "number" or type(my) ~= "number" then return nil end
    local left, top, w, h, cell = DropBox(TB.sel)
    -- from the bar's bottom edge (the gap under the icon belongs to the dropdown) to the panel's bottom
    if mx < left or mx > left + w or my < TB.Y + TB.PLATE / 2 - 2 or my > top + h then return nil end
    if my < top + TB.DROP_PAD or my > top + h - TB.DROP_PAD then return 0 end
    local k = math.floor((mx - left - TB.DROP_PAD) / cell) + 1
    if k >= 1 and k <= #g.items then return k end
    return 0
  end

  local function Quad(layer, idx, tex, spr, x, y, s, on, h)
    if not on or tex == nil then
      funcLuaMenuCommand(C.VISIBLE, layer, idx, false)
      funcLuaMenuCommand(C.POS, layer, -4000, 4000, 0, idx)
      return
    end
    funcLuaMenuCommand(C.VISIBLE, layer, idx, true)
    funcLuaMenuCommand(C.SCALE, layer, s / Q, (h or s) / Q, 1, idx)
    funcLuaMenuCommand(C.SPRITE, layer, tex, spr, NODE_QUAD, 0, idx)
    funcLuaMenuCommand(C.POS, layer, x, -y, 0, idx)
  end

  local function HideDropLabels()
    local label_fn = VRFW.top_bar_drop_label
    if type(label_fn) ~= "function" then return end
    for k = 1, TB.DROP_MAX do pcall(label_fn, TB.menu, k, nil, 0, 0, false, false) end
  end

  local function DrawDrop(show)
    if not TB.has_drop then return end
    local g = show and DropGroup() or nil
    if g == nil then
      if TB.drop_drawn then
        Quad(L_DPLATE, 0, nil, nil, 0, 0, 0, false)
        Quad(L_DPLATE, 1, nil, nil, 0, 0, 0, false)
        for k = 1, TB.DROP_MAX do Quad(L_DICON, k - 1, nil, nil, 0, 0, 0, false) end
        HideDropLabels()
        TB.drop_drawn = false
      end
      return
    end
    if not TB.drop_drawn then HideDropLabels() end
    TB.drop_drawn = true
    local left, top, w, h, cell = DropBox(TB.sel)
    local middle_y = top + h / 2
    Quad(L_DPLATE, 0, TB.plate_tex, CRC32("vrfw_tb_back"), left + w / 2, middle_y, w, TB.plate_tex ~= nil, h)
    if TB.dsel ~= nil and TB.plate_tex ~= nil then
      Quad(L_DPLATE, 1, TB.plate_tex, CRC32("vrfw_tb_hover"), DropCellX(left, cell, TB.dsel), middle_y, cell - 4, true,
        TB.DROP_H - 4)
    else
      Quad(L_DPLATE, 1, nil, nil, 0, 0, 0, false)
    end
    for k = 1, TB.DROP_MAX do
      local it = g.items[k]
      if it ~= nil then
        local icon_h = TB.DROP_ICON * ((TB.dsel == k) and TB.HOVER_SCALE or 1)
        Quad(L_DICON, k - 1, it.tex_crc, it.spr, DropCellX(left, cell, k), middle_y, icon_h * (it.aspect or 1),
          it.tex ~= nil, icon_h)
        local grey = (TB.block or it.cur) and 0.55 or 1
        funcLuaMenuCommand(C.PRIM_COLOR, L_DICON, k - 1, MESH_QUAD, grey, grey, grey)
      else
        Quad(L_DICON, k - 1, nil, nil, 0, 0, 0, false)
      end
    end
  end

  local function BadgeSig()
    local bs = VRFW.top_bar_badges
    if type(bs) ~= "table" then return "" end
    local t = {}
    for k, b in pairs(bs) do
      if type(b) == "table" then t[#t + 1] = tostring(k) .. "=" .. tostring(b.tex) .. ":" .. tostring(b.sprite) end
    end
    table.sort(t)
    return table.concat(t, ",")
  end

  -- the bar's layers to their TB.PRIO draw priority (every instance, children included), once per showing
  local function Raise()
    TB.raised = true
    local n = 0
    for name, prio in pairs(TB.PRIO) do
      local layer = CRC32(name)
      local ok, cnt = pcall(funcLuaMenuCommand, C.LAYER_NUM, layer)
      if ok and type(cnt) == "number" then
        for idx = 0, cnt - 1 do
          if pcall(funcLuaMenuCommand, C.DRAW_PRIO, layer, idx, prio, true) then n = n + 1 end
        end
      end
    end
    if TB.DEBUG then Log("dbg draw priorities set on", n, "instances") end
  end

  local function Draw()
    TB.badge_sig = BadgeSig()
    local show = TB.shown and TB.tex_ready and not TB.fading
    if show and not TB.raised then Raise() end
    local n = #TB.entries
    if TB.has_back then
      local l, r = n > 0 and X(1) - W(1) / 2 or 0, n > 0 and X(n) + W(n) / 2 or 0
      local w = (r - l) + (TB.PLATE - TB.SIZE * TB.CELL_K) + 16
      Quad(L_BACK, 0, TB.plate_tex, CRC32("vrfw_tb_back"), (l + r) / 2, TB.Y, w, show and TB.back_on and n > 0, TB.PLATE + 12)
    end
    if TB.host.open then
      local hint = show and n > 0 and not TB.nav and not TB.open_off
      local hf = VRFW.top_bar_hint
      if type(hf) == "function" then
        local okh, err = pcall(hf, TB.menu, (n > 0 and X(1) - W(1) / 2 or TB.RIGHT) - TB.GAP - 17, TB.Y, hint)
        if not okh then Log("hint error", tostring(err)) end
      end
    end
    for i = 1, TB.MAX do
      local e = TB.entries[i]
      local on = show and e ~= nil and e.tex ~= nil
      local idx = i - 1
      if on then
        local sel, cur = TB.sel == i, TB.cur[i] == true
        local sc = sel and TB.HOVER_SCALE or 1
        local iw, ih = IconSize(i)
        Quad(L_ICON, idx, e.tex_crc, e.spr, X(i), TB.Y, iw * sc, true, ih * sc)
        local g = (TB.block and not cur) and 0.55 or 1
        funcLuaMenuCommand(C.PRIM_COLOR, L_ICON, idx, MESH_QUAD, g, g, g)
        local plate = sel and "vrfw_tb_hover" or (cur and "vrfw_tb_current" or nil)
        if plate ~= nil and TB.plate_tex ~= nil then
          Quad(L_PLATE, idx, TB.plate_tex, CRC32(plate), X(i), TB.Y, W(i) + TB.PLATE - TB.SIZE * TB.CELL_K, true, TB.PLATE)
        else
          Quad(L_PLATE, idx, nil, nil, 0, 0, 0, false)
        end
      else
        Quad(L_ICON, idx, nil, nil, 0, 0, 0, false)
        Quad(L_PLATE, idx, nil, nil, 0, 0, 0, false)
      end
    end
    local badge = nil
    local bs = VRFW.top_bar_badges
    if show and type(bs) == "table" then
      for i = 1, math.min(n, TB.MAX) do
        local b = bs[TB.entries[i].key]
        if type(b) == "table" and type(b.tex) == "string" and type(b.sprite) == "string" then
          badge = i
          Quad(L_PLATE, TB.MAX, CRC32(b.tex), CRC32(b.sprite), X(i) + W(i) / 2 - 2, TB.Y - TB.SIZE / 2 + 4, 18, true)
          break
        end
      end
    end
    if badge == nil then Quad(L_PLATE, TB.MAX, nil, nil, 0, 0, 0, false) end
    DrawDrop(show)
  end

  -- the game is in a state where leaving for the title is safe
  local function Blocked()
    if funcLuaCommand(C.MSG_BUSY) == true then return "message window" end
    if funcLuaCommand(C.IS_FADE) == true then return "fade" end
    if funcLuaCommand(C.SAVE_WORKING) == true then return "saving" end
    if VRFW.param.has(K.BUSY) then return "a shortcut is in flight" end
    local _, swapped = SessionOpen()
    if swapped then
      if not (TB.host.session and HostFn(TB.host.leave) ~= nil) then
        return "overlay session (leave from its own menu)"
      end
    else
      local ok, act = pcall(funcLuaCommand, C.SLOT_ACTIVE)
      if ok and type(act) == "number" and act > 0 then
        local okr, res = pcall(funcLuaCommand, C.SLOT_RESERVED, act)
        if okr and res == true then return "reserved slot " .. act .. " (no session)" end
      end
    end
    for _, m in ipairs(BLOCK_MENUS) do
      if funcLuaMenuCommand(C.EXISTS, m) == true then return "window menu" end
    end
    return nil
  end

  local function TexReady()
    if TB.tex_ready then return true end
    TB.tex_t = TB.tex_t + TB.CHECK_EVERY
    local busy = false
    for tc in pairs(Atlases()) do
      local ok, b = pcall(funcLuaCommand, C.TEX_LOADING, tc)
      if ok and b == true then busy = true end
    end
    if TB.plate_tex ~= nil then
      local ok, b = pcall(funcLuaCommand, C.TEX_LOADING, TB.plate_tex)
      if ok and b == true then busy = true end
    end
    if (not busy and TB.tex_t >= TB.TEX_MIN) or TB.tex_t >= TB.TEX_MAX then
      TB.tex_ready = true
      if TB.DEBUG then Log("dbg texture", busy and "still loading after" or "in after", TB.tex_t, "frames") end
    end
    return TB.tex_ready
  end

  local function DebugDump(tag)
    for i = 1, #TB.entries do
      local e = TB.entries[i]
      local ok, gx, gy = pcall(funcLuaMenuCommand, C.GPOS, L_ICON, i - 1)
      Log("dbg", tag, i, e.key, "idx", i - 1, "pos", X(i), -TB.Y, "visible", TB.shown and TB.tex_ready and e.tex ~= nil,
        "gpos", ok and tostring(gx) or "err", ok and tostring(gy) or "")
    end
  end

  local function Select(i, sound)
    if i == TB.sel then return end
    TB.sel, TB.dsel, TB.dshut = i, nil, false
    TB.sel_t = TB.SEL_FRAMES
    if i ~= nil and sound then funcLuaCommand(C.SE, C.SE_MOVE) end
    Draw()
  end

  local function FocusPos(layer, idx)
    if layer == nil then return nil, nil end
    local gx, gy = VRFW.host.menu_command(C.GPOS, layer, idx or 0)
    if type(gx) == "number" and type(gy) == "number" then return gx, gy end
    return nil, nil
  end

  local function NavEnter(why)
    local pick = nil
    for i = 1, #TB.entries do
      if TB.cur[i] then pick = i end
    end
    local fx = FocusPos(TB.flayer, TB.fidx)
    if pick == nil then
      pick = #TB.entries
      if fx ~= nil then
        local best = nil
        for i = 1, #TB.entries do
          local d = math.abs(X(i) - fx)
          if best == nil or d < best then best, pick = d, i end
        end
      end
    end
    TB.nav, TB.mouse, TB.release, TB.nav_t, TB.open_t = true, false, nil, 0, 0
    TB.nav_from = {layer = TB.flayer, idx = TB.fidx}
    VRFW.top_bar.guard.beat(true)
    TB.sel = nil
    Select(pick, true)
    Log("nav enter", why, "icon", pick, "from", tostring(TB.flayer), tostring(TB.fidx), "x", tostring(fx))
  end

  local function NavLeave(key, why)
    TB.nav, TB.dsel = false, nil
    TB.release = key or 0
    Select(nil, false)
    Log("nav leave", why)
  end

  local function DevHeld(cmd)
    if TB.host.standalone == nil and not (TB.open_raw and cmd == C.OPEN) then return false end
    local d = C.DEV[cmd]
    if d == nil then return false end
    if TB.pad_frame ~= TB.frame then
      TB.pad_frame = TB.frame
      local ok, held = pcall(funcLuaCommand, C.PAD)
      TB.pad = (ok and type(held) == "number" and held >= 0) and held or 0
    end
    if d.pad ~= nil and math.floor(TB.pad / d.pad) % 2 == 1 then return true end
    for _, vk in ipairs(d.vk or {}) do
      local ok, v = pcall(funcLuaCommand, C.VKEY, vk)
      if ok and v == true then return true end
    end
    return false
  end

  local function Held(cmd, analog)
    if funcLuaCommand(C.CHECK_INPUT, C.MENU_CTRL, cmd) == true then return true end
    if analog and funcLuaCommand(C.CHECK_INPUT, C.ANALOG_CTRL, cmd) == true then return true end
    if DevHeld(cmd) then
      if TB.DEBUG and not TB.dbg_dev then
        TB.dbg_dev = true
        Log("dbg device input", cmd, "(MENU_CTRL silent in this menu)")
      end
      return true
    end
    return false
  end

  local function NavRelease()
    if TB.release == nil then return end
    TB.release_t = (TB.release_t or 0) + 1
    if TB.release ~= 0 and TB.release_t < 120 and Held(TB.release, true) then
      return
    end
    TB.release, TB.release_t = nil, 0
    if TB.co == nil then
      VRFW.top_bar.guard.beat(false)   -- every guard gives its menu back the state it wants
      Log("nav menu active again")
    end
  end

  local function UndoWrap(old)
    TB.self_focus = true
    pcall(funcLuaMenuCommand, C.FOCUS_SET, TB.flayer, TB.fidx, false)
    pcall(funcLuaMenuCommand, C.FOCUS_SET, old.layer, old.idx, true)
    if type(OnChangeFocus) == "function" then pcall(OnChangeFocus, old.layer, old.idx) end
    TB.self_focus = false
    TB.flayer, TB.fidx = old.layer, old.idx
  end

  local function Refresh()
    ResolveMenu()
    local raw = nil
    if TB.menu ~= nil then raw = funcLuaCommand(C.IS_OPEN, TB.menu, HEADER) end
    local open = raw ~= nil and raw ~= false and raw ~= 0
    if TB.DEBUG and raw ~= TB.dbg_open then
      TB.dbg_open = raw
      Log("dbg header open (raw)", tostring(raw), "menu", TB.menu, "header", HEADER)
    end
    local back = false
    if not open and TB.host.standalone ~= nil and TB.menu ~= nil then
      local r = funcLuaCommand(C.IS_OPEN, TB.menu, TB.host.standalone)
      open = r ~= nil and r ~= false and r ~= 0
      back = open
    end
    if open and not OwnActive() then open = false end
    if open and VRFW.param.has(K.HIDE) then open = false end
    if open and TB.host.gate ~= nil then
      local gf = HostFn(TB.host.gate)
      local okg, g = false, nil
      if gf ~= nil then okg, g = pcall(gf) end
      open = okg and g == true
    end
    if back ~= TB.back_on then
      TB.back_on = back
      TB.dbg_gpos = false
    end
    local function IsCur(e)
      for _, m in ipairs(e.menus) do
        if m == TB.menu or m == TB.self_crc or funcLuaMenuCommand(C.EXISTS, m) == true then return true end
      end
      return false
    end
    local cur, rows_changed = {}, false
    for i, e in ipairs(TB.entries) do
      if IsCur(e) then cur[i] = true end
      for _, it in ipairs(e.items or {}) do
        local c = IsCur(it)
        if c ~= (it.cur == true) then rows_changed = true end
        it.cur = c
        if c then cur[i] = true end
      end
    end
    local block = Blocked() ~= nil
    local open_off = TB.host.open == true and OpenYields()
    if open_off ~= (TB.open_off == true) then
      TB.open_off = open_off
      Log("open button", open_off and "left to the menu on top (open_yield)" or "enters the bar again")
    end
    local right = TB.RIGHT
    local rank = false
    local RK = TB.rank or {}
    if open and RK.plate then
      local r = funcLuaCommand(C.IS_OPEN, TB.menu, RK.plate)
      rank = r ~= nil and r ~= false and r ~= 0
    end
    local hide = false
    if rank then
      local hf = VRFW.top_bar_rank_hide
      if type(hf) == "function" then
        local okh, h = pcall(hf, TB.menu)
        hide = okh and h == true
      end
    end
    if hide ~= (TB.rank_hide == true) then
      TB.rank_hide = hide
      if hide then
        -- the plate's own visibility (the menu may hide it itself), given back when the hide ends
        local okv, v = pcall(funcLuaMenuCommand, VRFW.commands.IS_LAYER_VISIBLE, RK.plate, 0)
        TB.rank_was = not okv or v ~= false
      elseif RK.plate and TB.rank_was ~= false then
        pcall(funcLuaMenuCommand, C.VISIBLE, RK.plate, 0, true)
      end
      Log("rank plate", hide and "hidden (the header shows something else there)" or "shown again")
    end
    if hide then rank = false end
    if rank and TB.host.rank_centre and RK.node and RK.centre_x then
      pcall(funcLuaMenuCommand, NODE_POS, HEADER, 0, RK.node, 0, RK.centre_x)
      if TB.DEBUG and not TB.rank_log then
        TB.rank_log = true
        local okp, gx, gy = pcall(funcLuaMenuCommand, C.GPOS, RK.plate, 0)
        Log("dbg rank plate centred, gpos", okp and tostring(gx) or "err", okp and tostring(gy) or "")
      end
    elseif rank and RK.avoid then
      right = RK.avoid
    end
    local moved = right ~= TB.right
    if moved then
      TB.right = right
      Layout()
      TB.dbg_gpos = false
      Log("row right edge", right, rank and "(rank plate at its retail place)" or "")
    end
    local was_ready = TB.tex_ready
    local ready = TexReady()
    local fading = open and funcLuaCommand(C.IS_FADE) == true
    local changed = open ~= TB.shown or block ~= TB.block or ready ~= was_ready or moved or open_off ~= (TB.open_drawn == true)
      or rows_changed or BadgeSig() ~= (TB.badge_sig or "") or fading ~= TB.fading
    TB.fading = fading
    TB.open_drawn = open_off
    for i = 1, #TB.entries do
      if (cur[i] == true) ~= (TB.cur[i] == true) then changed = true end
    end
    TB.cur, TB.block = cur, block
    if open ~= TB.shown then
      TB.shown = open
      TB.sel, TB.dsel = nil, nil
      if not open then TB.raised = false end   -- priorities applied again at the next showing
      if not open and TB.nav then NavLeave(0, "header closed") end
      Log(open and "shown" or "hidden", #TB.entries, "texture", TB.tex_ready and "ready" or "loading",
        "standalone", tostring(TB.back_on))
      TB.dbg_gpos = false
    end
    if changed then Draw() end
    if TB.DEBUG and TB.shown and TB.tex_ready and not TB.dbg_gpos then
      TB.dbg_gpos = true
      DebugDump("open")
    end
  end

  -- commands pressed this frame and not the last one (MENU_CTRL, arrows also from the analog table)
  local function Edges()
    local E = {}
    local function one(cmd, analog)
      local now = Held(cmd, analog)
      local was = TB.prev[cmd]
      TB.prev[cmd] = now
      E[cmd] = now and not was
    end
    for _, c in ipairs(C.NAV) do one(c, true) end
    one(C.CLICK) one(C.ENTER_CLICK) one(C.ENTER) one(C.CANCEL) one(C.OPEN)
    return E
  end

  local function Pointed()
    local mx, my = funcLuaMenuCommand(C.POINTER)
    if type(mx) ~= "number" or type(my) ~= "number" then return nil end
    local py = -my
    local half = TB.PLATE / 2
    for i = 1, #TB.entries do
      local gx, gy = funcLuaMenuCommand(C.GPOS, L_ICON, i - 1)
      local hw = (W(i) + TB.PLATE - TB.SIZE * TB.CELL_K) / 2
      if type(gx) == "number" and type(gy) == "number" and math.abs(mx - gx) <= hw and math.abs(py - gy) <= half then
        return i
      end
    end
    return nil
  end

  local function ResetToTitle(save)
    if save then funcLuaCommand(C.AUTO_SAVE) end
    funcLuaCommand(C.FADE, 1, 0.3)
    while not funcLuaCommand(C.FADE_DONE) do coroutine.yield() end
    while funcLuaCommand(C.BUSY) do coroutine.yield() end
    funcLuaMenuCommand(3479138216, 0)
    funcLuaCommand(937976662, true)
    funcLuaCommand(419468738, false)
    funcLuaCommand(1507811093, false)
    Log("reset (the title takes over)")
    funcLuaCommand(C.GAME_RESET)
    for _ = 1, 900 do coroutine.yield() end
    Log("still here 900 frames after the reset: screen and input back")
    Clear(TT.go, TT.box, K.BUSY, K.TARGET, K.DEFER)
    funcLuaCommand(C.FADE, 0, 0.3)
    if TB.menu ~= nil then funcLuaMenuCommand(C.MENU_ACTIVE, TB.menu, true) end
  end

  local function ResetDirect(e, item)
    local d = e.direct
    funcLuaCommand(C.AUTO_SAVE)
    funcLuaCommand(C.FADE, 1, 0.3)
    while not funcLuaCommand(C.FADE_DONE) do coroutine.yield() end
    while funcLuaCommand(C.BUSY) do coroutine.yield() end
    Log("reset straight into", d.vs and "the VS menu" or tostring(d.menu), "title mode", d.mode)
    -- the auto-save's job done, the game kept in memory, the next state, the reset (VRFW.reset, 04_reset.lua)
    local straight = VRFW.reset.straight({ menu = d.menu, vs = d.vs, title_mode = d.mode, bgm_stop = true,
      log = function(text) Log("direct:", text) end }) == "straight"
    if straight then
      P(K.DIRECT, CRC32(e.key))
      Log("direct: no title, the next state opens", tostring(e.key), "(InitState loads the kept slot first)")
    else
      P(TT.go, item)
    end
    for _ = 1, 900 do coroutine.yield() end
    Log("still here 900 frames after the reset: screen and input back")
    Clear(TT.go, TT.box, K.BUSY, K.TARGET, K.DEFER, K.DIRECT)
    funcLuaCommand(C.FADE, 0, 0.3)
    if TB.menu ~= nil then funcLuaMenuCommand(C.MENU_ACTIVE, TB.menu, true) end
  end

  local function GoCo(e, path)
    P(K.BUSY, 1)
    funcLuaCommand(C.SE, C.SE_GO)
    funcLuaMenuCommand(C.MENU_ACTIVE, TB.menu, false)
    for _, k in ipairs(TT.clear) do P(k, nil) end
    Clear(TT.box, K.DEFER, K.STEP)
    P(K.TARGET, CRC32(e.key))
    local item = Crc(e.value)
    if e.kind == "focus" then
      item = TT.item
      P(TT.box, CRC32(e.value))
    end
    if path ~= "direct" then P(path == "session" and K.DEFER or TT.go, item) end
    Log("go", e.key, e.kind, e.value, "path", path, "steps", e.steps ~= "" and e.steps or "-")
    coroutine.yield()
    local leave = HostFn(TB.host.leave)
    if path == "leave" and leave ~= nil then
      -- the host's own exit (it resets to the title its own way)
      leave()
      for _ = 1, 900 do coroutine.yield() end
      Log("leave: still here 900 frames after", TB.host.leave)
      Clear(TT.go, TT.box, K.BUSY, K.TARGET)
      return
    elseif path == "session" and leave ~= nil then
      P(K.BUSY, nil)
      Log("session: the host leaves the session first; the title opens the target after it is closed")
      leave()
      return
    elseif path == "direct" then
      ResetDirect(e, item)
      return
    end
    ResetToTitle(true)
  end

  local function GoEntry(e, cur)
    if e == nil then return end
    local why = Blocked()
    if why == nil and cur then why = "current mode" end
    if why == nil and e.kind ~= "title" and e.kind ~= "focus" and e.kind ~= "lua" then why = "action " .. tostring(e.kind) end
    if why == nil and (e.kind == "title" or e.kind == "focus") and TT.go == nil then why = "no [top_bar_title] hand-off declared" end
    if why == nil and e.kind == "focus" and (TT.item == nil or TT.box == nil) then why = "no focus_item / focus_param in [top_bar_title]" end
    if why ~= nil then
      Log("refused", e.key, why)
      funcLuaCommand(C.SE, C.SE_NO)
      return
    end
    if TB.nav then TB.nav, TB.release = false, nil end
    TB.sel = nil
    local here = rawget(VRFW, "top_bar_here")
    if type(here) == "table" and type(here[e.key]) == "function" then
      local okh, done = pcall(here[e.key], e, TB.name)
      if okh and done == true then
        Log("go", e.key, "served here by", tostring(TB.name))
        return
      end
    end
    if e.kind == "lua" then
      local f = HostFn(e.value)
      if type(f) == "function" then pcall(f, e) end
      return
    end
    local path = "reset"
    if HostFn(TB.host.leave) ~= nil then
      if not TB.host.session then
        path = "leave"
      elseif select(2, SessionOpen()) then
        path = "session"
      end
    elseif e.direct ~= nil and e.kind == "title" and TB.DIRECT == true then
      path = "direct"
    end
    VRFW.top_bar.guard.beat(false)
    TB.dsel = nil
    TB.co = coroutine.create(GoCo)
    local ok, err = coroutine.resume(TB.co, e, path)
    if not ok then Log("error", err) TB.co = nil end
  end

  local function Go(i)
    local e = TB.entries[i]
    if e == nil or e.kind == "group" then return end   -- a group's icon only opens its dropdown
    GoEntry(e, TB.cur[i])
  end

  local function DropSelect(k, sound)
    if k == TB.dsel then return end
    TB.dsel = k
    if k ~= nil and sound then funcLuaCommand(C.SE, C.SE_MOVE) end
    Draw()
  end

  local function PollNav(E)
    if TB.nav then
      local g = TB.sel ~= nil and TB.entries[TB.sel] or nil
      local grp = g ~= nil and g.kind == "group"
      if TB.dsel ~= nil and grp then
        if E[C.LEFT] then
          if TB.dsel > 1 then DropSelect(TB.dsel - 1, true) end
        elseif E[C.RIGHT] then
          if TB.dsel < #g.items then DropSelect(TB.dsel + 1, true) end
        elseif E[C.UP] then
          TB.dshut = true
          DropSelect(nil)
          Log("nav drop closed (up)")
        elseif TB.host.open and E[C.OPEN] then
          NavLeave(C.OPEN, "open")
        elseif E[C.CANCEL] then
          funcLuaCommand(C.SE, C.SE_BACK)
          TB.dshut = true
          DropSelect(nil)
          Log("nav drop closed (back)")
        elseif E[C.ENTER] then
          local it = g.items[TB.dsel]
          if it ~= nil then GoEntry(it, it.cur) end
        end
        if TB.nav then
          TB.sel_t = TB.SEL_FRAMES
          TB.nav_t = (E[C.UP] or E[C.DOWN] or E[C.LEFT] or E[C.RIGHT]) and 0 or TB.nav_t + 1
          if TB.nav_t > 600 then NavLeave(0, "idle") end
        end
        return true
      end
      if E[C.LEFT] then
        if TB.sel ~= nil and TB.sel > 1 then Select(TB.sel - 1, true) end
      elseif E[C.RIGHT] then
        if TB.sel ~= nil and TB.sel < #TB.entries then Select(TB.sel + 1, true) end
      elseif (E[C.DOWN] or E[C.ENTER]) and grp then
        TB.dshut = false                             -- DOWN (or A) on a group: into its dropdown, first icon
        DropSelect(1, true)
        Log("nav drop", g.value, "icon 1")
      elseif E[C.DOWN] then
        NavLeave(C.DOWN, "down")
      elseif TB.host.open and E[C.OPEN] then
        NavLeave(C.OPEN, "open")
      elseif E[C.CANCEL] then
        funcLuaCommand(C.SE, C.SE_BACK)
        NavLeave(C.CANCEL, "back")
      elseif E[C.ENTER] then
        if TB.sel ~= nil then Go(TB.sel) end
      end
      if TB.nav then
        TB.sel_t = TB.SEL_FRAMES                     -- the bar focus does not fade, but 10 s without a key = back
        TB.nav_t = (E[C.LEFT] or E[C.RIGHT]) and 0 or TB.nav_t + 1
        if TB.nav_t > 600 then NavLeave(0, "idle") end
      end
      return true
    end
    local hold = TB.host.open_hold or 0
    if TB.host.open and hold > 0 then
      if TB.prev[C.OPEN] and TB.release == nil and TB.co == nil and not OpenYields() then
        TB.open_t = (TB.open_t or 0) + 1
        if TB.open_t == hold then
          TB.up = nil
          NavEnter("open held " .. hold .. " frames")
          return true
        end
      elseif not TB.prev[C.OPEN] then
        TB.open_t = 0
      end
    elseif TB.host.open and E[C.OPEN] and TB.release == nil and TB.co == nil and not OpenYields() then
      TB.up = nil
      NavEnter("open")
      return true
    end
    local up = TB.up
    if up ~= nil then
      up.t = up.t + 1
      if TB.fev ~= up.fev then
        TB.up = nil
        local _, ny = FocusPos(TB.flayer, TB.fidx)
        if up.y ~= nil and ny ~= nil and ny < up.y - 8 then
          Log("nav up wrapped the menu's focus", tostring(up.layer), tostring(up.idx), "->", tostring(TB.flayer),
            tostring(TB.fidx), "y", up.y, "->", ny, ": undone")
          UndoWrap(up)
          NavEnter("wrap")
        end
      elseif up.t >= TB.NAV_WAIT then
        TB.up = nil
        NavEnter("top-most (focus did not move)")
      end
    elseif E[C.UP] and TB.host.dpad ~= false and TB.flayer ~= nil and TB.release == nil and not TB.mouse
        and TB.co == nil then
      local okf, act = pcall(funcLuaMenuCommand, VRFW.commands.IS_CTRL_FOCUS_ACTIVE, TB.flayer)
      if okf and act == true then
        local _, y = FocusPos(TB.flayer, TB.fidx)
        TB.up = {t = 0, fev = TB.fev, layer = TB.flayer, idx = TB.fidx, y = y}
      end
    end
    return false
  end

  local function Poll()
    if TB.nav or TB.release ~= nil then VRFW.top_bar.guard.beat(true) end
    if TB.co ~= nil then
      local ok, err = coroutine.resume(TB.co)
      if not ok then Log("error", err) end
      if not ok or coroutine.status(TB.co) == "dead" then TB.co = nil end
      return
    end
    TB.frame = TB.frame + 1
    if TB.DEBUG and TB.dbg_steps == 0 then
      TB.dbg_steps = 1
      Log("dbg step alive")
    end
    if TB.frame % TB.CHECK_EVERY == 0 then Refresh() end
    NavRelease()
    if TB.rank_hide and TB.rank and TB.rank.plate then
      pcall(funcLuaMenuCommand, C.VISIBLE, TB.rank.plate, 0, false)
    end
    local E = Edges()
    if not TB.shown or #TB.entries == 0 or not TB.tex_ready then
      TB.up = nil
      if TB.nav then NavLeave(0, "row hidden") end
      return
    end
    local mx, my = funcLuaMenuCommand(C.POINTER)
    local moved = false
    if type(mx) == "number" and type(my) == "number" then
      moved = funcLuaMenuCommand(C.MOVED) == true
      if not moved and TB.px ~= nil and (math.abs(mx - TB.px) > 1 or math.abs(my - TB.py) > 1) then
        moved = true
      end
      TB.px, TB.py = mx, my
    end
    local keys = E[C.UP] or E[C.DOWN] or E[C.LEFT] or E[C.RIGHT]
    if moved then
      if TB.DEBUG and not TB.dbg_ptr then
        TB.dbg_ptr = true
        local gx, gy = funcLuaMenuCommand(C.GPOS, L_ICON, 0)
        Log("dbg pointer", mx, my, "icon1 gpos", tostring(gx), tostring(gy))
      end
      if TB.nav then NavLeave(0, "pointer") end
      TB.up = nil
      TB.mouse = true
      local d = DropPointed(mx, my)
      if d ~= nil then
        TB.drop_out = nil
        DropSelect(d > 0 and d or nil, d > 0)
      else
        local k = Pointed()
        if k ~= nil then
          TB.drop_out = nil
          Select(k, true)                    -- another icon: its own (or no) dropdown
          if k == TB.sel and TB.dsel ~= nil then DropSelect(nil) end
        elseif TB.sel ~= nil then
          if DropGroup() ~= nil then
            if TB.drop_out == nil then TB.drop_out = TB.DROP_GRACE end
            if TB.dsel ~= nil then DropSelect(nil) end
          else
            Select(nil, false)
          end
        end
      end
    elseif keys and TB.mouse then
      TB.mouse = false                       -- the menu's arrows lead again: the pointer's highlight goes
      TB.drop_out = nil
      Select(nil, false)
    end
    if TB.drop_out ~= nil then
      if not TB.mouse or DropGroup() == nil then
        TB.drop_out = nil
      else
        TB.drop_out = TB.drop_out - 1
        if TB.drop_out <= 0 then
          TB.drop_out = nil
          Select(nil, false)
        end
      end
    end
    if E[C.CLICK] or (TB.mouse and E[C.ENTER_CLICK]) then
      local d = DropPointed(mx, my)
      if d ~= nil and d > 0 then
        local it = TB.entries[TB.sel].items[d]
        return GoEntry(it, it.cur)           -- an icon of the open dropdown
      elseif d == nil then
        local k = Pointed()
        if k ~= nil then return Go(k) end
        if TB.mouse and DropGroup() ~= nil then
          TB.drop_out = nil
          Select(nil, false)
        end
      end
    end
    if not TB.nav and TB.mouse and E[C.CANCEL] and DropGroup() ~= nil then
      TB.drop_out = nil
      Select(nil, false)
    end
    if PollNav(E) then return end
    if funcLuaCommand(C.CHECK_INPUT, C.MENU_CTRL, C.KEY) == true then
      TB.held = TB.held + 1
      if TB.held == TB.HOLD then
        if TB.sel ~= nil then return Go(TB.sel) end
        Select(1, true)
      end
    elseif TB.held > 0 then
      if TB.held < TB.HOLD then
        TB.mouse = false
        Select(TB.sel == nil and 1 or (TB.sel % #TB.entries) + 1, true)
      end
      TB.held = 0
    end
    if TB.sel ~= nil and not TB.mouse then
      TB.sel_t = TB.sel_t - 1
      if TB.sel_t <= 0 then Select(nil, false) end
    end
  end

  local function DeferPoll()
    if TB.co ~= nil then
      local ok, err = coroutine.resume(TB.co)
      if not ok then Log("error", err) end
      if not ok or coroutine.status(TB.co) == "dead" then TB.co = nil end
      return
    end
    TB.frame = TB.frame + 1
    if TB.frame % 10 ~= 0 or not VRFW.param.has(K.DEFER) then
      TB.defer_t = 0
      return
    end
    TB.defer_t = TB.defer_t + 10
    local open = SessionOpen()
    local host = false
    for _, m in ipairs(TT.session) do
      if funcLuaMenuCommand(C.EXISTS, m) == true then host = true end
    end
    if open or host or TT.go == nil or funcLuaCommand(C.SAVE_WORKING) == true or funcLuaCommand(C.MSG_BUSY) == true then
      if TB.defer_t >= TB.DEFER_MAX then
        Log("deferred target dropped: still", open and "in the session" or (host and "under the session host" or "busy"),
          "after", TB.defer_t, "frames")
        Clear(K.DEFER, TT.box, K.TARGET)
      end
      return
    end
    local item = Take(K.DEFER)
    Log("deferred target", tostring(item), "after", TB.defer_t, "frames: session closed, reset into it")
    P(TT.go, item)
    TB.co = coroutine.create(function()
      coroutine.yield()
      ResetToTitle(false)                    -- the title saved on arrival; the session's sink is off again
    end)
    local ok, err = coroutine.resume(TB.co)
    if not ok then Log("error", err) TB.co = nil end
  end

  local function WrapFocus()
    local ocf = OnChangeFocus
    if type(ocf) == "function" then
      OnChangeFocus = function(a1, a2, ...)
        if not TB.self_focus then TB.fev, TB.flayer, TB.fidx = TB.fev + 1, a1, a2 end
        return ocf(a1, a2, ...)
      end
    end
    local ols = OnFocusLayerShift
    if type(ols) == "function" then
      OnFocusLayerShift = function(a1, a2, ...)
        if not TB.self_focus then TB.fev, TB.flayer, TB.fidx = TB.fev + 1, a1, a2 end
        return ols(a1, a2, ...)
      end
    end
    local raw = funcLuaMenuCommand
    funcLuaMenuCommand = function(id, ...)
      if id == C.FOCUS_SET and not TB.self_focus and select("#", ...) >= 3 then
        local a1, a2, a3 = ...
        if a3 == true then TB.fev, TB.flayer, TB.fidx = TB.fev + 1, a1, a2 end
      end
      return raw(id, ...)
    end
  end

  local function WrapStep(poll)
    if TB.wrapped then return end
    TB.wrapped = true
    local step = Step
    Step = function(...)
      local r = table.pack(step and step(...))
      if TB.on then
        local ok, err = pcall(poll)
        if not ok then Log("error", err) TB.on = false end
      end
      return table.unpack(r, 1, r.n)
    end
  end

  --   * the VM's own MENU_ACTIVE(menu, b) calls for its menu are recorded as the menu's wish (in the VM only);
  -- a mod's grid under it): its script's menu, the menus its own Lua switches with MENU_ACTIVE (learned: a script
  -- whose stem is not its menu's name, e.g.
  local GUARD_TTL = 30
  local GD = VRFW.top_bar.guard or {}
  VRFW.top_bar.guard = GD
  GD.raw, GD.menu, GD.off, GD.last, GD.still, GD.beat_n = GD.raw, nil, false, nil, 0, GD.beat_n or 0
  -- the menu's own wish (its Lua's last MENU_ACTIVE for itself in this VM; none = active, the state a menu opens in).
  local function Wish(m) return GD.wishes == nil or GD.wishes[m] ~= false end
  local function Targets()
    local out, seen = {}, {}
    local function add(m)
      if m ~= nil and not seen[m] then
        seen[m] = true
        if funcLuaMenuCommand(C.EXISTS, m) == true then out[#out + 1] = m end
      end
    end
    add(GD.menu)
    for m in pairs(GD.menus or {}) do add(m) end
    for m in pairs(GD.learned or {}) do add(m) end
    if #out == 0 and type(TB.name) == "string" then
      local n = TB.name
      for _ = 1, 3 do
        local shorter = n:match("^(.+)_[^_]+$")
        if shorter == nil or not shorter:find("_", 1, true) then break end
        n = shorter
        local m = CRC32(n)
        if funcLuaMenuCommand(C.EXISTS, m) == true then
          out[#out + 1] = m
          GD.learned = GD.learned or {}
          GD.learned[m] = true
          Log("top bar focus: menu of", TB.name, "is", n)
          break
        end
      end
    end
    return out
  end
  --- Bumps the navigation heartbeat parameter, or clears it.
  function GD.beat(on)
    if on then
      GD.beat_n = (GD.beat_n % 1000000) + 1
      VRFW.param.set(K.NAV, GD.beat_n)
    elseif VRFW.param.has(K.NAV) then
      VRFW.param.clear(K.NAV)
    end
  end
  local function NavAlive()
    if not VRFW.param.has(K.NAV) then GD.last, GD.still = nil, 0 return false end
    local v = VRFW.param.get(K.NAV)
    if v ~= GD.last then GD.last, GD.still = v, 0 else GD.still = GD.still + 1 end
    return GD.still < GUARD_TTL
  end
  --- Hides the focus cursors that are on, remembering them for focus_show.
  function GD.focus_hide()
    GD.hidden = {}
    for layer, on in pairs(GD.cursor_on or {}) do
      local okf, act = pcall(GD.raw, C.CTRL_FOCUS_ACTIVE, layer)
      local oki, idx = pcall(GD.raw, C.FOCUS_INDEX, layer)
      if okf and act == true and oki and type(idx) == "number" and on[idx] == true then
        pcall(GD.raw, C.PLAY_ANIME, layer, idx, C.ANIME_FOCUS, 2, C.ANIME_SET_BUTTON)
        pcall(GD.raw, C.ATTACH_TRACE, layer, idx, C.LOCATOR_CURSOR, false)
        GD.hidden[#GD.hidden + 1] = {layer = layer, idx = idx}
        Log("top bar focus: focus look of", TB.name, "hidden", layer, idx)
      end
    end
  end
  --- Shows again the cursors focus_hide remembered.
  function GD.focus_show()
    local hidden = GD.hidden or {}
    GD.hidden = {}
    for _, h in ipairs(hidden) do
      local oke, exists = pcall(GD.raw, C.LAYER_EXISTS, h.layer)
      local on = GD.cursor_on ~= nil and GD.cursor_on[h.layer] or nil
      if oke and exists == true and on ~= nil and on[h.idx] == true then
        pcall(GD.raw, C.ATTACH_TRACE, h.layer, h.idx, C.LOCATOR_CURSOR, true)
        local okf, act = pcall(GD.raw, C.CTRL_FOCUS_ACTIVE, h.layer)
        local oki, idx = pcall(GD.raw, C.FOCUS_INDEX, h.layer)
        if okf and act == true and oki and idx == h.idx then
          pcall(GD.raw, C.PLAY_ANIME, h.layer, h.idx, C.ANIME_FOCUS, 0, C.ANIME_SET_BUTTON)
        end
        Log("top bar focus: focus look of", TB.name, "restored", h.layer, h.idx)
      end
    end
  end
  local function GuardStep()
    if GD.menu == nil then return end
    local alive = NavAlive()
    if alive and not GD.off then
      GD.focus_hide()
      GD.off = true
      GD.held = {}
      for _, m in ipairs(Targets()) do
        if Wish(m) then
          GD.raw(C.MENU_ACTIVE, m, false)
          GD.held[#GD.held + 1] = m
        end
      end
      if #GD.held > 0 then Log("top bar focus: input of", TB.name, "suspended (" .. #GD.held .. " menu(s))") end
    elseif not alive and GD.off then
      GD.off = false
      local n = 0
      for _, m in ipairs(GD.held or {}) do
        if Wish(m) and funcLuaMenuCommand(C.EXISTS, m) == true then
          GD.raw(C.MENU_ACTIVE, m, true)
          n = n + 1
        end
      end
      if n > 0 then Log("top bar focus: input of", TB.name, "restored (" .. n .. " menu(s))") end
      GD.held = {}
      GD.focus_show()
    end
  end
  local function Guard()
    if GD.installed or type(TB.name) ~= "string" or TB.name == "?" or TB.name:find("^title") then return end
    GD.installed = true
    GD.menu = CRC32(TB.name)
    GD.menus = {[GD.menu] = true}   -- + the host's `variants` (Init, after the rules are read)
    local raw = funcLuaMenuCommand
    GD.raw = raw
    funcLuaMenuCommand = function(id, ...)
      if id == C.ATTACH_TRACE and select("#", ...) >= 4 then
        local layer, idx, locator, on = ...
        if locator == C.LOCATOR_CURSOR and type(layer) == "number" and type(idx) == "number" then
          GD.cursor_on = GD.cursor_on or {}
          local t = GD.cursor_on[layer]
          if on == true then
            if t == nil then t = {} GD.cursor_on[layer] = t end
            t[idx] = true
          elseif t ~= nil then
            t[idx] = nil
            if next(t) == nil then GD.cursor_on[layer] = nil end
          end
        end
      end
      if id == C.MENU_ACTIVE and select("#", ...) >= 2 then
        local m, b = ...
        if type(m) == "number" then
          -- every menu this VM's Lua switches is one of its menus (learned), with its own wish
          local mine = GD.menus ~= nil and GD.menus[m] == true
          if mine then GD.menu, GD.wish = m, b == true end
          GD.learned = GD.learned or {}
          GD.wishes = GD.wishes or {}
          GD.learned[m], GD.wishes[m] = true, b == true
          if b == true and GD.off then
            local held = false
            for _, x in ipairs(GD.held or {}) do if x == m then held = true break end end
            if not held then GD.held = GD.held or {} GD.held[#GD.held + 1] = m end
            return raw(id, m, false)            -- the bar has the focus: the wish is kept for later
          end
        end
      end
      return raw(id, ...)
    end
    local step = Step
    if type(step) == "function" then
      Step = function(...)
        local r = table.pack(step(...))
        local ok, err = pcall(GuardStep)
        if not ok then Log("guard error", err) GD.menu = nil end
        return table.unpack(r, 1, r.n)
      end
    end
  end

  local function Init()
    TB.init_seq = (TB.init_seq or 0) + 1
    pcall(Guard)
    TB.on, TB.shown, TB.sel, TB.held, TB.co, TB.cur, TB.block = false, false, nil, 0, nil, {}, false
    TB.mouse, TB.px, TB.py, TB.prev = false, nil, nil, {}
    TB.tex_ready, TB.tex_t, TB.dbg_open, TB.dbg_steps, TB.dbg_gpos, TB.dbg_ptr = false, 0, nil, 0, false, false
    TB.nav, TB.up, TB.release, TB.defer_t = false, nil, nil, 0
    TB.right, TB.rank_log, TB.rank_hide, TB.open_t, TB.menu_ok = TB.RIGHT, false, false, 0, false
    TB.raised, TB.fading = false, false
    if type(funcLuaMenuCommand) ~= "function" or TB.name == nil or type(CRC32) ~= "function" then return end
    LoadRules()
    if VRFW.param.has(K.DIRECT) then
      VRFW.param.clear(K.DIRECT)
      local okc, last = pcall(funcLuaCommand, C.CARRY, 2)
      if tostring(TB.name):find("^title") then
        Log("direct: the title runs after all (carry:", tostring(okc and last or "?"), ")")
      else
        Log("direct: landed on", TB.name, "(carry:", tostring(okc and last or "?"), ")")
      end
    end
    if TB.name == TITLE then
      TB.on = true
      if VRFW.param.has(K.HIDE) then VRFW.param.clear(K.HIDE) end   -- stale after a reset
      WrapStep(DeferPoll)
      if VRFW.param.has(K.DEFER) then Log("title: a deferred target is waiting") end
      return
    end
    local n = funcLuaMenuCommand(C.LAYER_NUM, L_ICON)
    if type(n) ~= "number" or n <= 0 then return end
    TB.MAX = n
    TB.menu, TB.self_crc = CRC32(TB.name), CRC32(TB.name)
    if VRFW.top_bar.guard ~= nil and VRFW.top_bar.guard.menus ~= nil then
      for _, v in ipairs(TB.host.variants or {}) do VRFW.top_bar.guard.menus[v] = true end
    end
    ResolveMenu()
    local nb = funcLuaMenuCommand(C.LAYER_NUM, L_BACK)
    TB.has_back, TB.back_on = type(nb) == "number" and nb > 0, false
    if VRFW.param.has(K.BUSY) then VRFW.param.clear(K.BUSY) end -- stale after a reset
    if VRFW.param.has(K.NAV) then VRFW.param.clear(K.NAV) end   -- no focus at a hub's start
    local nd, np = funcLuaMenuCommand(C.LAYER_NUM, L_DICON), funcLuaMenuCommand(C.LAYER_NUM, L_DPLATE)
    TB.has_drop = type(nd) == "number" and nd > 0 and type(np) == "number" and np > 0
    TB.dsel, TB.dshut, TB.drop_drawn = nil, false, TB.has_drop   -- drawn = hide its quads at the first Draw
    TB.drop_out = nil
    TB.entries = LoadEntries()
    TB.xs, TB.ws = {}, {}
    Layout()
    TB.plate_tex = nil
    for _, tex in pairs(Atlases()) do
      funcLuaMenuCommand(C.LOAD_TEX, tex)
    end
    if TB.plates_atlas ~= nil then
      funcLuaMenuCommand(C.LOAD_TEX, TB.plates_atlas)
      TB.plate_tex = CRC32(TB.plates_atlas)
    else
      for _, e in ipairs(TB.entries) do
        if e.tex_crc ~= nil then TB.plate_tex = e.tex_crc break end
      end
      if TB.plate_tex ~= nil then
        Log("WARN no [vrfw.TopBarStyle] PlatesAtlas declared: the plates are read from the first icon's atlas")
      end
    end
    TB.on = #TB.entries > 0
    local ng = 0
    for _, e in ipairs(TB.entries) do if e.kind == "group" then ng = ng + 1 end end
    Log("init", n, "entries", #TB.entries, "groups", ng, "dropdown layers", tostring(TB.has_drop), "gate", tostring(TB.host.gate), "leave", tostring(TB.host.leave),
      "session", tostring(TB.host.session), "title hand-off", tostring(TT.go ~= nil), "variants",
      #(TB.host.variants or {}), "open_hold", tostring(TB.host.open_hold), "active_only", tostring(TB.host.active_only),
      "plates", tostring(TB.plates_atlas or "first icon"))
    if TB.on and not TB.wrapped then
      WrapFocus()
      WrapStep(Poll)
    end
  end

  local init = OnInit
  if type(init) == "function" then
    OnInit = function(...)
      local r = table.pack(init(...))
      local ok, err = pcall(Init)
      if not ok then Log("init error", err) TB.on = false end
      return table.unpack(r, 1, r.n)
    end
  end
  local setup = OnSetupLayer
  if type(setup) == "function" then
    OnSetupLayer = function(a1, a2, ...)
      if a1 == L_ICON or a1 == L_PLATE or a1 == L_BACK or a1 == L_DPLATE or a1 == L_DICON or a1 == L_DLABEL then
        VRFW.host.menu_command(C.VISIBLE, a1, a2, false)
        return
      end
      return setup(a1, a2, ...)
    end
  end
  local open = OnOpenLayer
  if type(open) == "function" then
    OnOpenLayer = function(a1, a2, ...)
      if a1 == L_ICON or a1 == L_PLATE or a1 == L_BACK or a1 == L_DPLATE or a1 == L_DICON or a1 == L_DLABEL then
        if TB.on then pcall(Draw) end
        return
      end
      return open(a1, a2, ...)
    end
  end
  local VH = VRFW.host
  if type(TB.name) == "string" and type(VH) == "table" and type(VH.on) == "function" then
    local function ours(a1) return a1 == L_ICON or a1 == L_PLATE or a1 == L_BACK or a1 == L_DPLATE or a1 == L_DICON or a1 == L_DLABEL end
    pcall(VH.on, TB.name, "OnInit", {id = "VRFW.top_bar_init", phase = "around", fn = function(nxt, ...)
      local seq = TB.init_seq
      local r = table.pack(nxt(...))
      if TB.init_seq == seq then
        local ok, err = pcall(Init)
        if not ok then Log("init error", err) TB.on = false end
      end
      return table.unpack(r, 1, r.n)
    end})
    pcall(VH.on, TB.name, "OnSetupLayer", {id = "VRFW.top_bar_setup", phase = "around", fn = function(nxt, a1, a2, ...)
      if ours(a1) then
        VRFW.host.menu_command(C.VISIBLE, a1, a2, false)
        return
      end
      return nxt(a1, a2, ...)
    end})
    pcall(VH.on, TB.name, "OnOpenLayer", {id = "VRFW.top_bar_open", phase = "around", fn = function(nxt, a1, a2, ...)
      if ours(a1) then
        if TB.on then pcall(Draw) end
        return
      end
      return nxt(a1, a2, ...)
    end})
  end
end

if VRFW.top_bar.step == nil then
  local TARGET, STEP = 2566540065 --[[vrfw_top_bar_target]], 229413441 --[[vrfw_top_bar_step]]
  local function U32(v) return VRFW.ids.unsigned_or(v, v) end
  local function Get(k)
    if not VRFW.param.has(k) then return nil end
    return U32(VRFW.param.get(k))
  end
  local function Clear(k)
    if VRFW.param.has(k) then VRFW.param.clear(k) end
  end
  local step_logger
  local function Log(...)
    local p = {}
    for i = 1, select("#", ...) do p[#p + 1] = tostring((select(i, ...))) end
    step_logger = step_logger or VRFW.logger.new("EVT top_bar step")
    step_logger.debug(table.concat(p, " "))
  end
  --- Applies a pending top-bar target for this frame; answers whether there was one to apply.
  function VRFW.top_bar.step(step)
    if type(CRC32) ~= "function" then return false end
    local target = Get(TARGET)
    if target == nil then return false end
    local ok, n = pcall(funcLuaCommand, VRFW.commands.VRFW_MENU_ENTRY_COUNT, "top_bar")
    if not ok or type(n) ~= "number" then return false end
    for i = 1, n do
      local key, _t, _i, _k, _v, _o, _c, _m, steps = funcLuaCommand(VRFW.commands.VRFW_MENU_ENTRY, "top_bar", i)
      if key ~= nil and U32(CRC32(key)) == target then
        local list = {}
        for s in tostring(steps or ""):gmatch("[^,%s]+") do list[#list + 1] = s end
        local done = Get(STEP) or 0
        if list[done + 1] ~= step then return false end
        if done + 1 >= #list then
          Clear(TARGET)
          Clear(STEP)
        else
          Clear(STEP)
          VRFW.param.set(STEP, done + 1)
        end
        Log(key, "takes", step, done + 1, "of", #list)
        return true
      end
    end
    return false
  end
end

if VRFW.top_bar.hide == nil then
  --- Hides or shows the top bar; answers true.
  function VRFW.top_bar.hide(on)
    local HIDE = 1455983968 --[[vrfw_top_bar_hidden]]
    if on then
      VRFW.param.set(HIDE, 1)
    elseif VRFW.param.has(HIDE) then
      VRFW.param.clear(HIDE)
    end
    return true
  end
end
