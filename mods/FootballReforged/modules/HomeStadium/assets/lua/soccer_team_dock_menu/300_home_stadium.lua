if VRFW.host ~= nil and type(VRFW.host.note) == "function" then
  VRFW.host.note("soccer_team_dock_menu", "home_stadium: dock file loaded (HomeStadium " .. type(HomeStadium)
    .. ", BetterUI.AddDockButton " .. type(type(BetterUI) == "table" and BetterUI.add_dock_button or nil) .. ")")
end
if type(HomeStadium) == "table" and type(HomeStadium.owned) == "function" then
  local H = HomeStadium
  local K = {
    MENU = 937147172,           -- soccer_team_dock_menu
    LIST = 3367997069,          -- team01_02_list_item
    BUTTON = 72691397,
    CURSOR = 2296367164,        -- cmn05_01_cursor
    FRAME = 2817282936,         -- win05_40_sub_image_frame (the selector's stadium picture)
    IMG_NODE = 2351399094,      -- _tutorial_img01 (the picture mesh of both frames)
    IMG_SPRITE = 1348394297,    -- tutorial_img01
    FRAME_BASE = 2725437086,    -- _tutorial_base01 (the frame's lighter plate, hidden)
    PLATE = 835686663,          -- home_stadium_sel_plate (vrfw_mp_plate quads)
    LABEL = 1324750516,         -- home_stadium_sel_label (vrfw_mp_label texts)
    QUAD_NODE = 1909474081,     -- icon_new01 (the quad's sprite node, 36 px)
    TEXT_NODE = 378327766,      -- _text_cmd_back01 (the label's text node)
    TEXT_MESHES = {298211823, 2853207670, 1859006685, 3449512431},
    TEXT_HINT = 354474455,      -- HomeStadium.select_hint (Accept / Back glyphs)
    SPRITE_WINDOW = {3320993727, 4239622167},    -- home_stadium_ui_window (deep blue)
    SPRITE_PLATE = {3320993727, 567774042},      -- home_stadium_ui_plate (light blue-grey)
    SPRITE_ARROW_L = {3320993727, 1162809077},   -- home_stadium_ui_arrow_l (active blue)
    SPRITE_ARROW_R = {3320993727, 3208655766},   -- home_stadium_ui_arrow_r
    SPRITE_ARROW_L_DIM = {3320993727, 2964931413},
    SPRITE_ARROW_R_DIM = {3320993727, 1869179574},   -- home_stadium_ui_arrow_r_dim (list end: nothing after)
    SPRITE_CHECK = {2587461336, 3555847673},     -- win05_02 icon_check01
    -- commands
    LAYER_POS = VRFW.commands.SET_LAYER_LOCAL_POS, LAYER_SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE, SPRITE = 558735651, MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,
    TEXT_SET = VRFW.commands.SET_MENU_TEXT_STRING, TEXT_STYLE = 2333948100, TEXT_WIDTH = VRFW.commands.GET_MENU_TEXT_RECT_SIZE, DRAW_PRIORITY = VRFW.commands.SET_DRAW_PRIORITY, VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,
    OPEN_LAYER = VRFW.commands.OPEN_LAYER, CLOSE_LAYER = VRFW.commands.CLOSE_LAYER,
    PAD = VRFW.commands.VRFW_INPUT_PAD,           -- CMND_VRFW_INPUT_PAD -> held mask (vr_sigs::input)
    KEY = VRFW.commands.VRFW_INPUT_KEY,           -- CMND_VRFW_INPUT_KEY (vk) -> held
    SE_MOVE = 3848881948, SE_GO = 766561556 --[[sy0080]], SE_BACK = 202039849 --[[sy0006]],
    KIND = 64,
    TEXT_ROW = 4018035431,      -- HomeStadium.row
    TEXT_HELP = 3966726855,     -- HomeStadium.row_help
    TEXT_NONE = 1351889636,     -- HomeStadium.none
    TITLE_ATLAS = 4231227197,
    TITLE = 1065353421,         -- gtxt_stadium01
    TITLE_SLOT = 3259336903,    -- gtxt_formation01
    NAME_NODE = 1509045176,     -- _text_formation01
    BOX = 1083262227,
    BOX_BLANK = 579557469,
    FORM_BOX = 3286546665,
    MAP_NAME = VRFW.commands.GET_MAP_NAME,      -- CMND_GET_MAP_NAME (map)
    TEXT_GET = VRFW.commands.TEXT_GET,      -- CMND_TEXT_GET (id)
    WAIT = 300,                 -- frames a layer may take to open
    SE_NO = 2086672038,         -- sy0003
    SOUND = VRFW.commands.SND_PLAY_SE,
    EXIST_LAYER = VRFW.commands.IS_EXIST_LAYER,    -- CMND_IS_EXIST_LAYER (layer)
    IS_OPEN = VRFW.commands.IS_OPEN_LAYER,       -- CMND_IS_OPEN_LAYER (layer[, idx])
    STADIUM_TEXTURE = 1232438844,
    FRAME_PICTURE = 952390423,
    NODE_POS = 2575768773,      -- (layer, idx, node, axis 0 x / 1 y, value)
    NODE_SCALE = 2885415772,    -- (layer, idx, node, sx, sy)
    LOG_ONCE = 3,
    CHECK_INPUT = 4265778440, MENU_CTRL = 1332654303,
    MOUSE_LEFT = 749879980,
    MOUSE_RIGHT = 3473063670,   -- CMD_MOUSE_RIGHT_CLICK (retail row: right click = Back)
  }
  local S = { owned = nil, set = -1, kinds = nil, logged = false, co = nil, from = nil,
    titled = false, shownSet = nil, shown = nil, logs = 0, steps = 0 }

  local function once(...)
    if S.logs < K.LOG_ONCE * 4 then
      S.logs = S.logs + 1
      H.log(...)
    end
  end

  local function wait(test)
    for _ = 1, K.WAIT do
      local ok, done = pcall(test)
      if ok and done then return true end
      coroutine.yield()
    end
    return false
  end

  local function is_open(layer)
    local yes = VRFW.host.menu_command(K.IS_OPEN, layer, 0)
    return yes == true
  end

  local button = false

  local function has_button()
    local yes = VRFW.host.menu_command(K.EXIST_LAYER, K.BUTTON)
    return yes == true
  end

  -- the first upvalue of the live global function `name` (or of the functions it wraps, 4 levels) for which pred holds
  local function upvalue(name, pred)
    local D = VRFW.debug
    if D == nil then return nil end
    local seen = {}
    local function scan(f, depth)
      if type(f) ~= "function" or seen[f] or depth > 4 then return nil end
      seen[f] = true
      local i = 1
      while true do
        local n, v = D.getupvalue(f, i)
        if n == nil then return nil end
        if pred(v, n) then return v end
        if type(v) == "function" then
          local r = scan(v, depth + 1)
          if r ~= nil then return r end
        end
        i = i + 1
      end
    end
    return scan(rawget(_ENV, name), 0)
  end

  local function is_kinds(v)
    if type(v) ~= "table" or v[0] ~= nil or #v < 1 or #v > 16 then return false end
    for _, k in ipairs(v) do
      if type(k) ~= "number" then return false end
    end
    return true
  end

  local function is_texts(v)
    return type(v) == "table" and type(v[1]) == "table" and v[1].itemExplation ~= nil
  end

  local function shown_set()
    local named = upvalue("UpdateTeamDockNo", function(v, n) return n == "n5" and type(v) == "number" end)
    if type(named) == "number" then return named end
    local first = upvalue("UpdateTeamDockNo", function(v) return type(v) == "number" end)
    if type(first) == "number" then return first end
    local h = VRFW.host and VRFW.host.hosts and VRFW.host.hosts.soccer_team_dock_menu
    local L = h and h.L
    return L and L.n5
  end

  local function picture(layer, map)
    local has, pic = VRFW.host.command(K.STADIUM_TEXTURE, 2, map)
    if has ~= true then return false end
    return (pcall(funcLuaMenuCommand, K.FRAME_PICTURE, layer, 0, K.IMG_NODE, map, pic, K.IMG_SPRITE))
  end

  local function idle_look(why)
    local focused = VRFW.host.menu_command(VRFW.commands.IS_CTRL_FOCUS_ACTIVE, K.BUTTON)
    if focused == true then return end
    VRFW.host.menu_command(VRFW.commands.PLAY_ANIME_TYPE, K.BUTTON, 0, 2734777837 --[[Focus]], 2,
      973515837 --[[button]])
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE, K.BUTTON, 0, 3313461902 --[[cursor]],
      false)
    VRFW.host.menu_command(1778826357 --[[focus mark]], K.BUTTON, 0, false)
    once("dock button: unfocused look (" .. tostring(why) .. ")")
  end

  local function foreign_stadium()
    local editor = VRFW.team_editor
    local foreign = type(editor) == "table" and type(editor.foreign) == "function" and editor.foreign() or nil
    return foreign ~= nil and (foreign.stadium or 0) or nil
  end

  local function dress(why)
    if not is_open(K.BUTTON) then return end
    VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, K.BUTTON, K.BOX, true, 0)
    VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, K.BUTTON, K.BOX_BLANK, false, 0)
    local prio = VRFW.host.menu_command(VRFW.commands.GET_DRAW_PRIORITY, K.FORM_BOX, 0)
    if type(prio) == "number" then
      VRFW.host.menu_command(VRFW.commands.SET_DRAW_PRIORITY, K.BUTTON, 0, prio)
      VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_PRIORITY, K.BUTTON, 0, K.NAME_NODE, prio + 1)
    end
    if not S.titled then
      S.titled = true
      local ok = pcall(funcLuaMenuCommand, 558735651 --[[sprite of a material slot]], K.BUTTON, K.TITLE_ATLAS, K.TITLE,
        K.TITLE_SLOT, 0, 0)
      once("dock button: title", ok and "set" or "refused", "(" .. tostring(why) .. ")")
    end
    local set = shown_set()
    if type(set) ~= "number" then return end
    local map = foreign_stadium() or H.get(set)
    if S.shownSet == set and S.shown == map then return end
    S.shownSet, S.shown = set, map
    local name
    if map ~= 0 then
      local n = VRFW.host.command(K.MAP_NAME, map)
      name = (type(n) == "string") and n or nil
    end
    if name == nil then
      local n = VRFW.host.command(K.TEXT_GET, K.TEXT_NONE)
      name = (type(n) == "string") and n or ""
    end
    VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_STRING, K.BUTTON, K.NAME_NODE, name, 0)
    once("dock button: team", set, "stadium", string.format("0x%08X", map), "(" .. tostring(why) .. ")")
  end

  local function add_row()
    if button or has_button() then return end
    local kinds = upvalue("SetupTeamDockListItem", is_kinds) or upvalue("UpdateViewTeamDockListItem", is_kinds)
    local texts = upvalue("SetupTeamDockListItemText", is_texts) or upvalue("OnChangeFocus", is_texts)
    if kinds == nil or texts == nil then
      if not S.logged then
        S.logged = true
        H.log("dock row: the list tables were not found (no VRFW.debug?): no «Estadio local» row")
      end
      return
    end
    S.kinds = kinds
    texts[K.KIND + 1] = { itemName = K.TEXT_ROW, itemExplation = K.TEXT_HELP }
    for _, kind in ipairs(kinds) do
      if kind == K.KIND then return end
    end
    table.insert(kinds, K.KIND)
    if not S.logged then
      S.logged = true
      H.log("dock row added", #kinds, "row(s)")
    end
  end

  local L = {
    CX = 518, TOP = 214, PAD = 14, GAP = 14,
    FRAME_IMG = {732, 403},
    FRAME_TOPLEFT = {834, 371},           -- its top-left on screen (layer at position 0)
    HINT_GAP = 6, BOTTOM = 14,
    SEL_H = 60,                           -- the name plate (a plain rect, the picture's width)
    ARROW_W = 40, ARROW_H = 48, ARROW_IN = 26,          -- the arrows, ARROW_IN px inside the plate's ends
    NAME_ROOM = 14,                       -- px kept free between the name and each arrow
    NAME_SCALE = 1, NAME_MIN = 0.7,
    CHECK = 40, CHECK_GAP = 10,
    HINT_H = 40, HINT_SCALE = 0.7,
    NUDGE = 10, PULSE = 0.25, NUDGE_FRAMES = 10,
    QUAD = 36,                            -- the quad object's size
    LABEL_LEFT = -384, LABEL_MID_Y = 144, -- the label's text node in its object (left edge, middle)
    TEXT_BOX_W = 384,
    NAME_STYLE = 2392563157,              -- fs_32_b_cc_2d0_001 (blue, centred: the dock list rows' text)
    PRIORITY = {WINDOW = 667, FRAME = 669, PLATE = 670, OVER = 671},
    GUARD = 8, REPEAT_WAIT = 18, REPEAT_EVERY = 5,
    ARROW_HOVER = 1.18, NAME_HOVER = 1.08, HINT_HOVER = 0.76, ARROW_HIT = 10,
  }
  -- quads and texts
  local Q_WINDOW, Q_PLATE, Q_SPARE, Q_ARROW_L, Q_ARROW_R, Q_CHECK = 0, 1, 2, 3, 4, 5   -- Q_SPARE: unused, hidden
  local T_NAME, T_HINT = 0, 1
  local QUADS, TEXTS = 6, 2
  local PRIORITY_OF = {[Q_WINDOW] = L.PRIORITY.WINDOW, [Q_PLATE] = L.PRIORITY.PLATE}
  -- the game pad (vr_sigs::input masks) and the Windows virtual keys
  local PAD = {LEFT = 0x80, RIGHT = 0x20, L1 = 0x400, R1 = 0x800, A = 0x4000, B = 0x2000, BACK = 0x1}
  local VK = {LEFT = 0x25, RIGHT = 0x27, PRIOR = 0x21, NEXT = 0x22, ENTER = 0x0D, ESC = 0x1B, BACKSPACE = 0x08}

  local function text_of(id)
    local s = VRFW.host.command(K.TEXT_GET, id)
    return (type(s) == "string") and s or ""
  end

  -- the picture's box (left, top, width, height), the plate's centre line, the hint's, the window's height
  local function geometry()
    local iw, ih = L.FRAME_IMG[1], L.FRAME_IMG[2]
    local il, it = L.CX - iw / 2, L.TOP + L.PAD
    local sel_y = it + ih + L.GAP + L.SEL_H / 2
    local hint_y = sel_y + L.SEL_H / 2 + L.HINT_GAP + L.HINT_H / 2
    local h = hint_y + L.HINT_H / 2 + L.BOTTOM - L.TOP
    return il, it, iw, ih, sel_y, hint_y, h, iw + 2 * L.PAD
  end

  local function quad(idx, sprite, x, y, w, h)
    VRFW.host.menu_command(K.LAYER_SCALE, K.PLATE, w / L.QUAD, h / L.QUAD, 1, idx)
    VRFW.host.menu_command(K.SPRITE, K.PLATE, sprite[1], sprite[2], K.QUAD_NODE, 0, idx)
    VRFW.host.menu_command(K.LAYER_POS, K.PLATE, x, -y, 0, idx)
    VRFW.host.menu_command(K.DRAW_PRIORITY, K.PLATE, idx, PRIORITY_OF[idx] or L.PRIORITY.OVER, true)
    VRFW.host.menu_command(K.VISIBLE, K.PLATE, idx, true)
  end

  local function hide_quad(idx)
    VRFW.host.menu_command(K.VISIBLE, K.PLATE, idx, false)
  end

  local function label(idx, s, cx, y, scale, room, min, style)
    for _, m in ipairs(K.TEXT_MESHES) do VRFW.host.menu_command(K.MESH_VISIBLE, K.LABEL, m, false, idx) end
    if style ~= nil then VRFW.host.menu_command(K.TEXT_STYLE, K.LABEL, idx, K.TEXT_NODE, style) end
    VRFW.host.menu_command(K.LAYER_SCALE, K.LABEL, 1, 1, 1, idx)
    VRFW.host.menu_command(K.TEXT_SET, K.LABEL, K.TEXT_NODE, s, idx)
    local w = VRFW.host.menu_command(K.TEXT_WIDTH, K.LABEL, idx, K.TEXT_NODE)
    w = (type(w) == "number" and w > 0) and w or 16 * #s
    if room ~= nil and w * scale > room then scale = math.max(min or scale, room / w) end
    VRFW.host.menu_command(K.LAYER_SCALE, K.LABEL, scale, scale, 1, idx)
    local left
    if style ~= nil then
      left = cx - (L.LABEL_LEFT + L.TEXT_BOX_W / 2) * scale      -- the rectangle's centre on cx
    else
      left = cx - w * scale / 2 - L.LABEL_LEFT * scale           -- a left-aligned text: its measured width
    end
    VRFW.host.menu_command(K.LAYER_POS, K.LABEL, left, -y - L.LABEL_MID_Y * scale, 0, idx)
    VRFW.host.menu_command(K.VISIBLE, K.LABEL, idx, s ~= "")
    return w * scale
  end

  local function frame_position(il, it)
    S.frame = {x = il - L.FRAME_TOPLEFT[1], y = -(it - L.FRAME_TOPLEFT[2])}
  end

  local function place_frame()
    local f = S.frame
    if f == nil then return end
    VRFW.host.menu_command(K.LAYER_SCALE, K.FRAME, 1, 1, 1, 0)
    VRFW.host.menu_command(K.LAYER_POS, K.FRAME, f.x, f.y, 0, 0)
    VRFW.host.menu_command(K.MESH_VISIBLE, K.FRAME, K.FRAME_BASE, false, 0)
    VRFW.host.menu_command(K.DRAW_PRIORITY, K.FRAME, 0, L.PRIORITY.FRAME, true)
  end

  local function check_input(cmd)
    local on = VRFW.host.command(K.CHECK_INPUT, K.MENU_CTRL, cmd)
    return on == true
  end

  local function hint_parts(s)
    if S.hint_text == s then return S.hint_w1, S.hint_w2 end
    local a, b = s:match("^(.-%S)%s%s+(%S.*)$")
    local function width(t)
      if t == nil then return nil end
      VRFW.host.menu_command(K.TEXT_SET, K.LABEL, K.TEXT_NODE, t, T_HINT)
      local w = VRFW.host.menu_command(K.TEXT_WIDTH, K.LABEL, T_HINT, K.TEXT_NODE)
      return (type(w) == "number" and w > 0) and w or nil
    end
    S.hint_text, S.hint_w1, S.hint_w2 = s, width(a), width(b)
    return S.hint_w1, S.hint_w2
  end

  local function draw(rows, i, current, look_only)
    local il, it, iw, ih, sel_y, hint_y, h, ww = geometry()
    local hot, P = S.hot, S.ptr
    local st = rows[i]
    quad(Q_WINDOW, K.SPRITE_WINDOW, L.CX, L.TOP + h / 2, ww, h)
    quad(Q_PLATE, K.SPRITE_PLATE, L.CX, sel_y, iw, L.SEL_H)
    local ax = iw / 2 - L.ARROW_IN - L.ARROW_W / 2
    S.arrows = {y = sel_y, [Q_ARROW_L] = L.CX - ax, [Q_ARROW_R] = L.CX + ax}
    local gl = hot == "left" and L.ARROW_HOVER or 1
    local gr = hot == "right" and L.ARROW_HOVER or 1
    quad(Q_ARROW_L, i > 1 and K.SPRITE_ARROW_L or K.SPRITE_ARROW_L_DIM, L.CX - ax, sel_y, L.ARROW_W * gl, L.ARROW_H * gl)
    quad(Q_ARROW_R, i < #rows and K.SPRITE_ARROW_R or K.SPRITE_ARROW_R_DIM, L.CX + ax, sel_y, L.ARROW_W * gr,
      L.ARROW_H * gr)
    local hint = text_of(K.TEXT_HINT)
    local w1, w2 = hint_parts(hint)
    local hs = (hot == "guide_ok" or hot == "guide_back") and L.HINT_HOVER or L.HINT_SCALE
    local hw = label(T_HINT, hint, L.CX, hint_y, hs)
    local room = 2 * (ax - L.ARROW_W / 2 - L.NAME_ROOM)
    local mark = st.map == current
    local cx = L.CX
    if mark then
      room = room - L.CHECK - L.CHECK_GAP
      cx = L.CX + (L.CHECK + L.CHECK_GAP) / 2
    end
    local ns = hot == "accept" and L.NAME_HOVER or 1
    local w = label(T_NAME, st.name, cx, sel_y, L.NAME_SCALE * ns, room * ns, L.NAME_MIN * ns, L.NAME_STYLE)
    if mark then
      quad(Q_CHECK, K.SPRITE_CHECK, cx - math.min(w, room) / 2 - L.CHECK_GAP - L.CHECK / 2, sel_y, L.CHECK, L.CHECK)
    else
      hide_quad(Q_CHECK)
    end
    if P ~= nil then
      P.begin()
      P.rect(il, it, iw, ih, "accept")
      P.box(L.CX, sel_y, iw / 2, L.SEL_H / 2, "accept")
      local aw, ah = L.ARROW_W / 2 + L.ARROW_HIT, L.SEL_H / 2
      if i > 1 then P.box(L.CX - ax, sel_y, aw, ah, "left") end
      if i < #rows then P.box(L.CX + ax, sel_y, aw, ah, "right") end
      local left, top = L.CX - hw / 2, hint_y - L.HINT_H / 2
      if w1 ~= nil and w2 ~= nil then
        -- the split in the middle of the gap between the two guides (hw / hs = the whole line's width at scale 1)
        local split = left + (w1 + (hw / hs - w1 - w2) / 2) * hs
        P.rect(left, top, split - left, L.HINT_H, "guide_ok")
        P.rect(split, top, left + hw - split, L.HINT_H, "guide_back")
      else
        P.rect(left, top, hw, L.HINT_H, "guide_ok")
      end
    end
    if look_only then
      hide_quad(Q_SPARE)
      return
    end
    local ok = false
    if is_open(K.FRAME) then
      place_frame()
      ok = st.map ~= 0 and picture(K.FRAME, st.map) == true
      VRFW.host.menu_command(K.VISIBLE, K.FRAME, 0, ok)
    end
    hide_quad(Q_SPARE)
  end

  local function nudge_start(dir)
    S.nudge = {q = dir < 0 and Q_ARROW_L or Q_ARROW_R, dir = dir, t = 0}
  end

  local function nudge_step()
    local n, a = S.nudge, S.arrows
    if n == nil or a == nil then return end
    n.t = n.t + 1
    local k = n.t < L.NUDGE_FRAMES and math.sin(math.pi * n.t / L.NUDGE_FRAMES) or 0
    local s = (S.hot == (n.q == Q_ARROW_L and "left" or "right") and L.ARROW_HOVER or 1) + L.PULSE * k
    VRFW.host.menu_command(K.LAYER_SCALE, K.PLATE, L.ARROW_W * s / L.QUAD, L.ARROW_H * s / L.QUAD, 1, n.q)
    VRFW.host.menu_command(K.LAYER_POS, K.PLATE, a[n.q] + n.dir * L.NUDGE * k, -a.y, 0, n.q)
    if k == 0 then S.nudge = nil end
  end

  local function open_layers(on)
    for i = 0, QUADS - 1 do
      if on then VRFW.host.menu_command(K.OPEN_LAYER, K.PLATE, i) else VRFW.host.menu_command(K.CLOSE_LAYER, K.PLATE, i) end
    end
    for i = 0, TEXTS - 1 do
      if on then VRFW.host.menu_command(K.OPEN_LAYER, K.LABEL, i) else VRFW.host.menu_command(K.CLOSE_LAYER, K.LABEL, i) end
    end
    if on then VRFW.host.menu_command(K.OPEN_LAYER, K.FRAME, 0) else VRFW.host.menu_command(K.CLOSE_LAYER, K.FRAME, 0) end
  end

  -- the pad and the keys held this frame
  local function buttons()
    local held = VRFW.host.command(K.PAD)
    held = (type(held) == "number" and held >= 0) and held or 0
    local function pad(m) return math.floor(held / m) % 2 == 1 end
    local function key(vk)
      local v = VRFW.host.command(K.KEY, vk)
      return v == true
    end
    return {
      left = pad(PAD.LEFT) or key(VK.LEFT), right = pad(PAD.RIGHT) or key(VK.RIGHT),
      l1 = pad(PAD.L1) or key(VK.PRIOR), r1 = pad(PAD.R1) or key(VK.NEXT),
      ok = pad(PAD.A) or key(VK.ENTER),
      back = pad(PAD.B) or pad(PAD.BACK) or key(VK.ESC) or key(VK.BACKSPACE) or check_input(K.MOUSE_RIGHT),
      mouse = check_input(K.MOUSE_LEFT),
    }
  end

  local function dock_cursor(a1, on)
    if a1 == K.BUTTON then
      VRFW.host.menu_command(VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE, K.BUTTON, 0, 3313461902 --[[cursor]], on)
    end
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, K.CURSOR, 0, on, K.MENU)
    VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, K.CURSOR, 0, on)
  end

  local function pick(a1)
    local set = shown_set()
    local function back()
      open_layers(false)
      dock_cursor(a1, true)
      funcLuaMenuCommand(1558704558, K.MENU, true)
      funcLuaMenuCommand(VRFW.commands.SET_ENABLE_CTRL_FOCUS, a1, true)
      pcall(dress, "pick")       -- the button picture follows the pick
    end
    if foreign_stadium() ~= nil then
      H.log("dock: the team on screen is not one of the player's: its own stadium stays")
      VRFW.host.command(K.SOUND, K.SE_NO)
      back()
      return
    end
    if type(set) ~= "number" or set < 0 then
      H.log("dock: no team on screen")
      VRFW.host.command(K.SOUND, K.SE_NO)
      back()
      return
    end
    local current = H.get(set)
    local rows, sel = { { map = 0, name = text_of(K.TEXT_NONE) } }, 1
    for _, st in ipairs(H.owned()) do
      rows[#rows + 1] = st
      if st.map == current then sel = #rows end
    end
    S.set = set
    H.log("team", set, "selector:", #rows - 1, "owned stadium(s), current", string.format("0x%08X", current))
    funcLuaMenuCommand(1558704558, K.MENU, false)
    dock_cursor(a1, false)
    open_layers(true)
    wait(function() return is_open(K.FRAME) end)
    local il, it = geometry()
    frame_position(il, it)
    VRFW.host.command(K.SOUND, K.SE_GO)
    S.hot, S.ptr = nil, type(VRFW.pointer.new) == "function" and VRFW.pointer.new() or nil
    if S.ptr ~= nil then S.ptr.reset() end
    local P = S.ptr
    draw(rows, sel, current)
    local function move(step)
      if sel + step < 1 or sel + step > #rows then return false end
      sel = sel + step
      VRFW.host.command(K.SOUND, K.SE_MOVE)
      draw(rows, sel, current)
      nudge_start(step)
      return true
    end
    local function accept()
      local map = rows[sel].map
      if H.set(set, map) then
        VRFW.host.command(K.SOUND, K.SE_GO)
        H.log("team", set, "home stadium", string.format("0x%08X", map))
      else
        VRFW.host.command(K.SOUND, K.SE_NO)
      end
    end
    local prev = {left = true, right = true, l1 = true, r1 = true, ok = true, back = true}
    local guard, hold, hold_dir = L.GUARD, 0, nil
    S.nudge = nil
    while true do
      coroutine.yield()
      nudge_step()
      local b = buttons()
      local p = prev
      local function edge(k) return b[k] and not p[k] end
      prev = b
      local ev = P ~= nil and P.poll() or {}
      local owned = P ~= nil and P.owns()
      if ev.changed then
        S.hot = ev.hot
        draw(rows, sel, current, true)
        if ev.hot ~= nil and ev.moved and guard == 0 then VRFW.host.command(K.SOUND, K.SE_MOVE) end
      end
      if guard > 0 then
        guard = guard - 1
      elseif edge("back") then
        VRFW.host.command(K.SOUND, K.SE_BACK)
        break
      elseif ev.click == "accept" or ev.click == "guide_ok" then
        accept()
        break
      elseif ev.click == "guide_back" then
        VRFW.host.command(K.SOUND, K.SE_BACK)
        break
      elseif ev.click == "left" or ev.click == "right" then
        move(ev.click == "left" and -1 or 1)
      elseif ev.wheel ~= nil then
        move(ev.wheel)
      elseif edge("ok") and not owned then
        accept()
        break
      else
        local dir = (b.left and -1) or (b.right and 1) or nil
        local step = nil
        if dir ~= nil then
          if dir ~= hold_dir then
            hold_dir, hold, step = dir, 0, dir
          else
            hold = hold + 1
            if hold >= L.REPEAT_WAIT and (hold - L.REPEAT_WAIT) % L.REPEAT_EVERY == 0 then step = dir end
          end
        else
          hold_dir, hold = nil, 0
          step = (edge("l1") and -1) or (edge("r1") and 1) or nil
        end
        if step ~= nil and move(step) and P ~= nil then
          P.key_step()             -- the keys lead again: the hover look goes
          if S.hot ~= nil then
            S.hot = nil
            draw(rows, sel, current, true)
          end
        end
      end
    end
    S.ptr, S.hot = nil, nil
    S.nudge = nil
    open_layers(false)
    wait(function()
      local b = buttons()
      return not (b.back or b.ok or b.mouse)
    end)
    coroutine.yield()
    back()
  end

  -- the selector starts in a coroutine of this file (button decide, OnEnter, OnDecideFocus), one at a time
  local function start(a1, why)
    if S.co ~= nil then return true end
    H.log("dock: selector requested by", why)
    S.from = a1
    S.co = coroutine.create(function() pick(a1) end)
    return true
  end

  local function tick()
    if S.co == nil then return end
    local ok, err = coroutine.resume(S.co)
    if not ok then
      H.log("dock: selector error", tostring(err))
      pcall(open_layers, false)
      pcall(dock_cursor, S.from, true)
      VRFW.host.menu_command(1558704558, K.MENU, true)
      VRFW.host.menu_command(VRFW.commands.SET_ENABLE_CTRL_FOCUS, S.from, true)
    end
    if not ok or coroutine.status(S.co) == "dead" then
      S.co = nil
    end
  end

  local install                     -- defined below (the button's step() may call it first)
  if type(BetterUI) == "table" and type(BetterUI.add_dock_button) == "function" then
    button = BetterUI.add_dock_button({
      id = "HomeStadium.dock", layer = K.BUTTON, help = K.TEXT_HELP, column = "panel",
      mesh = { node = K.BOX, x = -403, y = -24 }, center = { x = -198, y = -46.5 },   -- the box + title's centre
      step = function()
        if not S.installed then install("first button step") end
        S.steps = S.steps + 1
        tick()
      end,
    }) == true
  end

  local wraps = {}
  local function wrap(name, make)
    wraps[#wraps + 1] = {name, make}
  end
  install = function(why)
    if S.installed then return end
    S.installed = true
    local done = {}
    for _, w in ipairs(wraps) do
      local prev = rawget(_ENV, w[1])
      if type(prev) == "function" then
        rawset(_ENV, w[1], w[2](prev))
        done[#done + 1] = w[1]
      end
    end
    H.log("dock: callbacks wrapped (" .. tostring(why) .. "):", table.concat(done, ", "))
    pcall(idle_look, "install")
    pcall(dress, "install")
    pcall(add_row)
  end

  wrap("OnSetupLayer", function(prev)
    return function(a1, a2, ...)
      if a1 == K.LIST and a2 == 0 then
        pcall(add_row)
      end
      local r = table.pack(prev(a1, a2, ...))
      if button and a1 == K.BUTTON then
        VRFW.host.menu_command(VRFW.commands.SET_DRAW_PRIORITY, a1, a2 or 0, 453)
        VRFW.host.menu_command(VRFW.commands.SET_MENU_TEXT_PRIORITY, a1, a2 or 0, K.NAME_NODE, 454)
        VRFW.host.menu_command(3252599449, a1, 1)
        pcall(dress, "setup " .. tostring(a1))
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  wrap("OnOpenLayer", function(prev)
    return function(a1, a2, ...)
      local r = table.pack(prev(a1, a2, ...))
      if a1 == K.BUTTON then
        pcall(idle_look, "open")
        pcall(dress, "open " .. tostring(a1))
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  wrap("UpdateTeamDockNo", function(prev)
    return function(...)
      local r = table.pack(prev(...))
      if button then
        pcall(dress, "team switch")
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  wrap("Step", function(prev)
    return function(...)
      local r = table.pack(prev(...))
      if not (button and S.steps > 0) then
        pcall(tick)
      end
      return table.unpack(r, 1, r.n)
    end
  end)

  wrap("OnEnter", function(prev)
    return function(a1, a2, ...)
      if a1 == K.BUTTON then
        start(a1, "OnEnter")
        return 1
      end
      return prev(a1, a2, ...)
    end
  end)

  wrap("OnDecideFocus", function(prev)
    return function(a1, a2, ...)
      if a1 == K.BUTTON then
        start(a1, "OnDecideFocus")
        return
      end
      if a1 == K.LIST and type(a2) == "number" and S.kinds ~= nil and S.kinds[a2 + 1] == K.KIND then
        start(a1, "the list row")
        return
      end
      return prev(a1, a2, ...)
    end
  end)

  if VRFW.host ~= nil then
    VRFW.host.on("soccer_team_dock_menu", "@edit", { id = "HomeStadium.dock_install", fn = function() install("host") end })
  end
end
