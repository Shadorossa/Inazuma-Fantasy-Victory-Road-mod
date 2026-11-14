-- lua_patch.scope: used
-- menu_engine: the in-match settings window.
if VRFW.match_panel == nil then
  local MP = {
    ROWS_MAX = 20, HINTS_MAX = 4, REPEAT_WAIT = 18, REPEAT_EVERY = 5, OPEN_GUARD = 8, TEX_MAX = 300,
    LABEL_LEFT = -384, LABEL_MID_Y = 144,    -- the corner button's text node in its object (px)
    SCALE_ROW = 0.8, SCALE_TITLE = 0.9, SCALE_HINT = 0.7,
    TITLE_H = 64, HINT_H = 46, GAP = 12,
    open_now = false, spec = nil, sel = 1, rows = {}, prev = 0, prev_keys = {}, hold = 0, hold_dir = nil,
    guard = 0, paused_before = nil, tex = {}, tex_ok = false, tex_t = 0, logn = 0, drawn = false,
  }
  --- Internal: Namespace of the match panel: a generic list or table panel drawn over a host menu from a spec.
  VRFW.match_panel = MP

  -- the retail options screen's sprites (data\dx11\menu\108_option): the default look
  local ATL_CELL = "#/menu/108_option/option01/option01_23/option01_23.g4tx"
  local ATL_LIST = "#/menu/108_option/option01/option01_02/option01_02.g4tx"
  --- Internal: the sprite atlases the default style uses.
  MP.ATLASES = {ATL_CELL, ATL_LIST}
  --- Internal: default sprite style of the panel, row, cursor and labels (the retail options screen look).
  MP.DEFAULT_STYLE = {
    panel = {ATL_CELL, "cel_base01_gray01"},       -- black 30 %, slanted: the window behind the rows
    row = {ATL_CELL, "cel_base01_gray01"},         -- a list cell
    title = {ATL_LIST, "option_list_base02_on"},   -- the blue bar of a focused options row
    hint = {ATL_CELL, "cel_base01_gray01"},
    focus = {ATL_CELL, "cel_base01_on"},           -- the cyan-blue fill of the focused cell
    frame = {ATL_CELL, "cel_focus01"},             -- its cyan frame
    arrow_l = {ATL_CELL, "btn_arrow_l01"},
    arrow_r = {ATL_CELL, "btn_arrow_r01"},
    solid = {ATL_CELL, "cel_base01_off"},          -- an opaque cell, tinted dark: the window of an opaque table
    accent = {ATL_CELL, "keyconfig_title_line01"}, -- the bar left of a section row
    button_off = {ATL_LIST, "option_list_base02_off"}, -- a disabled button
    lock = {ATL_CELL, "cel_key01"},                -- the lock on a disabled button
  }
  local PARTS = {"panel", "row", "title", "hint", "focus", "frame", "arrow_l", "arrow_r", "solid", "accent", "button_off", "lock"}
  local SOLID_TINT = {0.07, 0.08, 0.1}            -- the opaque window's colour multiplier
  local BUTTON_OFF_TINT = {0.45, 0.47, 0.5}       -- a disabled button's colour multiplier
  local DIM = "WG"                                -- the colour tag of dimmed text

  local L_PLATE = 837372328 --[[vrfw_mp_plate]]
  local L_LABEL = 1322307099 --[[vrfw_mp_label]]
  local NODE_QUAD = 1909474081         -- icon_new01 (the cmn01_10 quad's sprite node)
  local MESH_QUAD = 312193881          -- the cmn01_10 quad's mesh (CMND_SET_PRIM_COLOR)
  local Q = 36                         -- cmn01_10 quad size
  local TEXT_NODE = 378327766          -- _text_cmd_back01
  local TEXT_MESHES = {298211823 --[[_cmd_back_base01]], 2853207670 --[[_cmd_back_base01_add]]}
  local P_PANEL = 0                     -- and P_PANEL + 1
  local P_ROW0 = 2                      -- rows 1 .. ROWS_MAX
  local P_TITLE = MP.ROWS_MAX + 2
  local P_HINT = MP.ROWS_MAX + 3
  local P_FOCUS = MP.ROWS_MAX + 4
  local P_FRAME = MP.ROWS_MAX + 5
  local P_ARROW_L = MP.ROWS_MAX + 6
  local P_ARROW_R = MP.ROWS_MAX + 7
  --- Internal: number of plate layer instances the panel needs.
  MP.PLATES = MP.ROWS_MAX + 8
  -- label instances
  local T_TITLE = 0
  local T_HINT0 = 1
  local T_ROW0 = 1 + MP.HINTS_MAX       -- row k: label T_ROW0 + 2 (k - 1), value + 1
  --- Internal: number of label layer instances the panel needs.
  MP.LABELS = T_ROW0 + 2 * MP.ROWS_MAX
  local C = {
    LAYER_NUM = VRFW.commands.GET_CREATE_LAYER_NUM, VISIBLE = VRFW.commands.SET_LAYER_VISIBLE, SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE, POS = VRFW.commands.SET_LAYER_LOCAL_POS,
    SPRITE = 558735651, PRIM_COLOR = VRFW.commands.SET_PRIM_COLOR, MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE, TEXT = VRFW.commands.SET_MENU_TEXT_STRING, LOAD_TEX = VRFW.commands.LOAD_MENU_RES_TEXTURE, TEX_LOADING = 1506186496,
    PAD = VRFW.commands.VRFW_INPUT_PAD, KEY = VRFW.commands.VRFW_INPUT_KEY,
    PAUSE = VRFW.commands.VRFW_GAME_PAUSE,
    SE = VRFW.commands.SND_PLAY_SE, SE_MOVE = 3848881948, SE_GO = 766561556 --[[sy0080]], SE_BACK = 202039849 --[[sy0006]],
    SE_NO = 2086672038 --[[sy0003]],
  }
  -- the game pad (Steam / PS layout masks of vr_sigs::input) and the Windows virtual keys
  local PAD = {BACK = 0x1, UP = 0x10, RIGHT = 0x20, DOWN = 0x40, LEFT = 0x80, B = 0x2000, A = 0x4000}
  local VK = {UP = 0x26, DOWN = 0x28, LEFT = 0x25, RIGHT = 0x27, ENTER = 0x0D, ESC = 0x1B, BACKSPACE = 0x08}

  local logger
  local function Log(...)
    if MP.logn >= 80 then return end
    --- Internal: count of log lines written by the match panel.
    MP.logn = MP.logn + 1
    logger = logger or VRFW.logger.new("VRFW match_panel")
    logger(tostring(MP.spec and MP.spec.id), ...)
  end

  local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then Log("callback error", tostring(err)) end
  end

  local function Se(id) pcall(funcLuaCommand, C.SE, id) end

  local function Count(layer)
    local n = VRFW.host.menu_command(C.LAYER_NUM, layer)
    return type(n) == "number" and n or 0
  end

  -- the style of a spec: every part { atlas, sprite } (the retail default for a part the mod left out)
  local function Resolve(st)
    local out = {}
    st = type(st) == "table" and st or {}
    local legacy = {}
    if type(st.atlas) == "string" and st.atlas ~= "" then
      if type(st.back) == "string" then legacy.row = {st.atlas, st.back} end
      if type(st.hover) == "string" then legacy.focus = {st.atlas, st.hover} end
    end
    for _, k in ipairs(PARTS) do
      local v = st[k]
      if type(v) == "table" and type(v[1]) == "string" and type(v[2]) == "string" then
        out[k] = {v[1], v[2]}
      else
        out[k] = legacy[k] or MP.DEFAULT_STYLE[k]
      end
    end
    -- the spec's own parts (row icons) by name
    for k, v in pairs(st) do
      if out[k] == nil and type(k) == "string" and type(v) == "table" and type(v[1]) == "string" and type(v[2]) == "string" then
        out[k] = {v[1], v[2]}
      end
    end
    return out
  end

  local function HideQuad(idx)
    VRFW.host.menu_command(C.VISIBLE, L_PLATE, idx, false)
    VRFW.host.menu_command(C.POS, L_PLATE, -4000, 4000, 0, idx)
  end

  -- quad idx with style part `part` centred at (x, y), its colour multiplied by tint {r, g, b} (none = as drawn)
  local function Quad(idx, part, x, y, w, h, tint)
    local sp = part and MP.style and MP.style[part]
    if sp == nil or not MP.tex_ok then return HideQuad(idx) end
    VRFW.host.menu_command(C.VISIBLE, L_PLATE, idx, true)
    VRFW.host.menu_command(C.SCALE, L_PLATE, w / Q, h / Q, 1, idx)
    VRFW.host.menu_command(C.SPRITE, L_PLATE, CRC32(sp[1]), CRC32(sp[2]), NODE_QUAD, 0, idx)
    local t = type(tint) == "table" and tint or nil
    VRFW.host.menu_command(C.PRIM_COLOR, L_PLATE, idx, MESH_QUAD, t and t[1] or 1, t and t[2] or 1, t and t[3] or 1)
    VRFW.host.menu_command(C.POS, L_PLATE, x, -y, 0, idx)
  end

  -- a text at (x = its left edge, y = its centre line), or hidden
  local function Text(idx, s, x, y, scale)
    if idx >= Count(L_LABEL) then return end
    if type(s) ~= "string" or s == "" then
      VRFW.host.menu_command(C.VISIBLE, L_LABEL, idx, false)
      VRFW.host.menu_command(C.POS, L_LABEL, -4000, 4000, 0, idx)
      return
    end
    scale = scale or MP.SCALE_ROW
    for _, m in ipairs(TEXT_MESHES) do VRFW.host.menu_command(C.MESH_VISIBLE, L_LABEL, m, false, idx) end
    VRFW.host.menu_command(C.TEXT, L_LABEL, TEXT_NODE, s, idx)
    VRFW.host.menu_command(C.SCALE, L_LABEL, scale, scale, 1, idx)
    VRFW.host.menu_command(C.POS, L_LABEL, x - MP.LABEL_LEFT * scale, -y - MP.LABEL_MID_Y * scale, 0, idx)
    VRFW.host.menu_command(C.VISIBLE, L_LABEL, idx, true)
  end

  local function HideAll()
    for i = 0, Count(L_PLATE) - 1 do HideQuad(i) end
    for i = 0, Count(L_LABEL) - 1 do
      VRFW.host.menu_command(C.VISIBLE, L_LABEL, i, false)
      VRFW.host.menu_command(C.POS, L_LABEL, -4000, 4000, 0, i)
    end
    --- Internal: true while the panel is drawn on screen.
    MP.drawn = false
  end

  local function ReadRows()
    local ok, rows = pcall(MP.spec.rows)
    if not ok or type(rows) ~= "table" then
      Log("rows error", tostring(rows))
      return {}
    end
    local out = {}
    local max = type(MP.spec.columns) == "table" and #rows or MP.ROWS_MAX
    for i = 1, math.min(#rows, max) do out[i] = rows[i] end
    return out
  end

  local function Hints()
    local h = MP.spec.hint
    if type(h) == "string" then return {h} end
    if type(h) ~= "table" then return {} end
    local out = {}
    for i = 1, math.min(#h, MP.HINTS_MAX) do
      if type(h[i]) == "string" and h[i] ~= "" then out[#out + 1] = h[i] end
    end
    return out
  end

  -- the window's frame: left, top, width, height, row height, the rows' top
  local function Geometry()
    local s = MP.spec
    local n = #MP.rows
    local w, rh = s.width or 1040, s.row_h or 46
    local h = MP.TITLE_H + MP.GAP + rh * n + MP.GAP + MP.HINT_H + 10
    local left = (1920 - w) / 2
    local top = s.top or (1080 - h) / 2
    return left, top, w, h, rh, top + MP.TITLE_H + MP.GAP
  end
  --- Internal: function computing the panel layout geometry from a spec.
  MP.geometry = Geometry

  -- TABLE MODE ------------------------------------------------------------------------------------------------------
  local function VisibleOf(spec)
    return math.max(1, math.min(tonumber(spec.visible) or 12, MP.ROWS_MAX - 3))
  end
  local function TableVisible()
    return VisibleOf(MP.spec)
  end
  -- row k's icon plates (box, glyph) and the disabled button's lock, after the list-mode plates
  local function PIcon(k) return MP.PLATES + 2 * (k - 1) end
  local function PLock(vis) return MP.PLATES + 2 * vis end

  local function TableButtons()
    local out = {}
    local bs = MP.spec.buttons
    if type(bs) ~= "table" then return out end
    for i = 1, math.min(#bs, 2) do out[i] = bs[i] end
    return out
  end

  -- a cell's text cut to its column (VRFW.text_fold.fit when present)
  local function Fit(s, px, scale)
    s = tostring(s or "")
    if type(VRFW.text_fold) == "table" and type(VRFW.text_fold.fit) == "function" then
      local ok, t = pcall(VRFW.text_fold.fit, s, px, 32 * scale)
      if ok and type(t) == "string" then return t end
    end
    return s
  end

  -- the estimated drawn width of s (the same glyph unit as Fit); nil when VRFW.text_fold is missing
  local function Width(s, scale)
    if type(VRFW.text_fold) == "table" and type(VRFW.text_fold.width) == "function" then
      local ok, w = pcall(VRFW.text_fold.width, s, 16 * scale)
      if ok and type(w) == "number" then return w end
    end
    return nil
  end

  -- s in colour tag `color` (none = as is)
  local function Paint(s, color)
    if type(color) ~= "string" or color == "" or s == "" then return s end
    return "[C" .. color .. "]" .. s .. "[C]"
  end

  -- the drawn width of s on label idx at scale (the game's measure, else the estimate)
  local function Drawn(idx, s, scale)
    if type(VRFW.text_fold) == "table" and type(VRFW.text_fold.measure) == "function" and idx < Count(L_LABEL) then
      local ok, w = pcall(VRFW.text_fold.measure, L_LABEL, idx, TEXT_NODE, s)
      if ok and type(w) == "number" then return w * scale end
    end
    return Width(s, scale)
  end

  -- a cell (a text, or a list of {text, colour tag} parts) as one marked-up text cut to px on label idx
  local function CellText(cell, color, px, scale, idx)
    if cell == nil or cell == "" then return nil end
    local parts = type(cell) == "table" and cell or {{tostring(cell), color}}
    local full = ""
    for _, part in ipairs(parts) do full = full .. Paint(tostring(part[1] or ""), part[2]) end
    local T = VRFW.text_fold
    if type(T) ~= "table" or type(T.units) ~= "function" or type(T.cut) ~= "function" then return full ~= "" and full or nil end
    -- one measure of the whole text; too wide: every part cut to its share of the units that fit
    local w = Drawn(idx, full, scale)
    if w == nil or w <= px then return full ~= "" and full or nil end
    local budget = math.floor(T.units(full) * px / w)
    local out = ""
    for _, part in ipairs(parts) do
      local t = tostring(part[1] or "")
      local u = T.units(t)
      if u < budget then
        out, budget = out .. Paint(t, part[2]), budget - u
      else
        out = out .. Paint(T.cut(t, budget), part[2])
        break
      end
    end
    return out ~= "" and out or nil
  end

  -- a text drawn with its right edge at x (at x itself when its width is unknown)
  local function TextRight(idx, s, x, y, scale)
    if s == nil then return Text(idx, nil) end
    local w = Drawn(idx, s, scale)
    Text(idx, s, w and (x - w) or x, y, scale)
  end

  -- a text centred on x (left-aligned at fallback_x when its width is unknown)
  local function TextCentre(idx, s, x, y, scale, fallback_x)
    if s == nil then return Text(idx, nil) end
    local w = Drawn(idx, s, scale)
    Text(idx, s, w and (x - w / 2) or fallback_x, y, scale)
  end

  -- a row's kind: "section" (a heading with its bar), "group" (a heading), else a list row on its cell
  local function Heading(row) return row ~= nil and (row.kind == "section" or row.kind == "group") end

  local function DrawTable()
    local s = MP.spec
    local cols = s.columns
    local vis = TableVisible()
    local n = #MP.rows
    local shown = math.min(vis, n)
    local bs = TableButtons()
    local w, rh = s.width or 1280, s.row_h or 44
    local note_h = (type(s.note) == "string" and s.note ~= "") and rh or 0
    local h = MP.TITLE_H + MP.GAP + rh * (vis + 1) + note_h + MP.GAP + (#bs > 0 and rh + MP.GAP or 0) + MP.HINT_H + 10
    local left = (1920 - w) / 2
    local top = s.top or (1080 - h) / 2
    local cx = left + w / 2
    local inner_l, inner_w = left + 40, w - 80
    local head_y = top + MP.TITLE_H + MP.GAP + rh / 2
    local function rowy(k) return head_y + rh * k end
    -- the window: one opaque tinted cell (spec.opaque), else the see-through retail cell twice
    if s.opaque then
      Quad(P_PANEL, "solid", cx, top + h / 2, w + 24, h + 20, s.solid_tint or SOLID_TINT)
      HideQuad(P_PANEL + 1)
    else
      Quad(P_PANEL, "panel", cx, top + h / 2, w + 24, h + 20)
      Quad(P_PANEL + 1, "panel", cx, top + h / 2, w + 24, h + 20)
    end
    Quad(P_TITLE, "title", cx, top + MP.TITLE_H / 2, w, MP.TITLE_H - 6)
    -- the head row (quad vis + 1, none on an opaque window), the list rows (quads 1 .. vis), the buttons after them
    if s.opaque then HideQuad(P_ROW0 + vis) else Quad(P_ROW0 + vis, "hint", cx, head_y, w - 32, rh - 6) end
    for k = 1, MP.ROWS_MAX - 3 do
      local row = MP.rows[MP.first + k - 1]
      local q = P_ROW0 + k - 1
      if k <= shown and not Heading(row) then
        local ind = tonumber(row.indent) or 0
        Quad(q, "row", cx + ind / 2, rowy(k), w - 32 - ind, rh - 6)
      elseif k ~= vis + 1 then
        HideQuad(q)
      end
      -- the row's icon (box + glyph) or a section's bar
      if k <= vis then
        local ic = k <= shown and row ~= nil and row.icon or nil
        local ix = inner_l + (tonumber(row and row.indent) or 0)
        if row ~= nil and k <= shown and row.kind == "section" then
          Quad(PIcon(k), "accent", inner_l - 14, rowy(k), 8, rh - 14)
          HideQuad(PIcon(k) + 1)
        elseif type(ic) == "table" then
          local sz = rh - 14
          if ic.box ~= nil then Quad(PIcon(k), ic.box, ix + sz / 2, rowy(k), sz, sz) else HideQuad(PIcon(k)) end
          local g = ic.box ~= nil and sz * 0.7 or sz
          Quad(PIcon(k) + 1, ic.part, ix + sz / 2, rowy(k), g, g, ic.tint)
        else
          HideQuad(PIcon(k))
          HideQuad(PIcon(k) + 1)
        end
      end
    end
    local by = rowy(vis) + rh / 2 + note_h + MP.GAP + rh / 2
    local bw = (w - 32 - MP.GAP) / 2
    local function bx(i) return left + 16 + bw / 2 + (i - 1) * (bw + MP.GAP) end
    local locked = nil
    for i = 1, 2 do
      local q = P_ROW0 + vis + i
      local b = bs[i]
      if b ~= nil then
        if b.disabled then
          Quad(q, "button_off", bx(i), by, bw, rh - 6, BUTTON_OFF_TINT)
          locked = locked or i
        else
          Quad(q, "row", bx(i), by, bw, rh - 6)
        end
      elseif q < P_ROW0 + MP.ROWS_MAX then
        HideQuad(q)
      end
    end
    if locked ~= nil then Quad(PLock(vis), "lock", bx(locked) - bw / 2 + 36, by, rh - 14, rh - 14) else HideQuad(PLock(vis)) end
    local fb = bs[MP.button]
    if fb ~= nil then
      Quad(P_FOCUS, "focus", bx(MP.button), by, bw, rh - 6)
      Quad(P_FRAME, "frame", bx(MP.button), by, bw + 8, rh + 2)
    else
      HideQuad(P_FOCUS)
      HideQuad(P_FRAME)
    end
    -- scroll arrows: shown when rows lie above / below the window
    local ah = rh - 16
    if MP.first > 1 then Quad(P_ARROW_L, "arrow_l", left + w - 40, rowy(1), ah * 40 / 48, ah) else HideQuad(P_ARROW_L) end
    if MP.first + vis - 1 < n then Quad(P_ARROW_R, "arrow_r", left + w - 40, rowy(shown), ah * 40 / 48, ah) else HideQuad(P_ARROW_R) end
    local hy = (#bs > 0 and by + rh / 2 or rowy(vis) + rh / 2) + MP.GAP + MP.HINT_H / 2
    if s.opaque then HideQuad(P_HINT) else Quad(P_HINT, "hint", cx, hy, w - 32, MP.HINT_H - 6) end
    -- the texts
    Text(T_TITLE, s.title, left + 40, top + MP.TITLE_H / 2, MP.SCALE_TITLE)
    TextRight(T_HINT0 + 1, (type(s.title_right) == "string" and s.title_right ~= "") and s.title_right or nil, left + w - 40, top + MP.TITLE_H / 2, MP.SCALE_TITLE)
    Text(T_HINT0 + 2, note_h > 0 and Paint(Fit(s.note, inner_w, MP.SCALE_HINT), DIM) or nil, inner_l, rowy(vis) + rh / 2 + note_h / 2, MP.SCALE_HINT)
    for i = 4, MP.HINTS_MAX do Text(T_HINT0 + i - 1, nil) end
    local hint = (fb ~= nil and type(fb.hint) == "string" and fb.hint ~= "") and fb.hint or s.hint
    if n > vis then
      hint = (type(hint) == "string" and hint ~= "" and (hint .. "   ") or "") .. MP.first .. "-" .. math.min(n, MP.first + vis - 1) .. " / " .. n
    end
    hint = type(hint) == "string" and hint ~= "" and Fit(hint, w - 80, MP.SCALE_HINT) or nil
    if hint ~= nil and s.opaque then hint = Paint(hint, DIM) end
    if s.opaque then TextCentre(T_HINT0, hint, cx, hy, MP.SCALE_HINT, left + 40) else Text(T_HINT0, hint, left + 40, hy, MP.SCALE_HINT) end
    local nc = #cols
    for c = 1, nc do
      local col = cols[c]
      local x = inner_l + (tonumber(col.x) or 0) * inner_w
      local cw = (tonumber(col.w) or (1 / nc)) * inner_w - 8
      local right = col.align == "right"
      local head = type(s.head) == "table" and s.head[c] and s.head[c] ~= "" and Fit(s.head[c], cw, MP.SCALE_HINT) or nil
      if right then TextRight(T_ROW0 + c - 1, head, x + cw, head_y, MP.SCALE_HINT) else Text(T_ROW0 + c - 1, head, x, head_y, MP.SCALE_HINT) end
      for k = 1, vis do
        local row = MP.rows[MP.first + k - 1]
        local idx = T_ROW0 + k * nc + c - 1
        local cell = (k <= shown and row ~= nil and type(row.cells) == "table") and row.cells[c] or nil
        if cell == nil or cell == "" then
          Text(idx, nil)
        else
          -- a cell spans the empty cells after it, up to a gap before the next filled column; the first one starts after the row's indent and icon
          local cx0, span = x, cw
          for e = c + 1, nc do
            local nxt = row.cells[e]
            if nxt ~= nil and nxt ~= "" then
              span = span - MP.GAP
              break
            end
            span = span + (tonumber(cols[e].w) or (1 / nc)) * inner_w
          end
          if c == 1 then
            local shift = (tonumber(row.indent) or 0) + (row.icon ~= nil and rh or 0)
            cx0, span = cx0 + shift, span - shift
          end
          local scale = row.kind == "section" and MP.SCALE_TITLE * 0.9 or MP.SCALE_ROW
          local t = CellText(cell, type(row.colors) == "table" and row.colors[c] or nil, span, scale, idx)
          if right then TextRight(idx, t, x + cw, rowy(k), scale) else Text(idx, t, cx0, rowy(k), scale) end
        end
      end
    end
    for i = 1, 2 do
      local idx = T_ROW0 + (vis + 1) * nc + i - 1
      local b = bs[i]
      local label = b ~= nil and tostring(b.label or "") or nil
      if label ~= nil and b.disabled then label = Paint(label, DIM) end
      TextCentre(idx, label, bx(i), by, MP.SCALE_ROW, left + 16 + (i - 1) * (bw + MP.GAP) + 28)
    end
    MP.drawn = true
  end

  local function StepTable(b, edge)
    local n, vis = #MP.rows, TableVisible()
    local bs = TableButtons()
    -- UP / DOWN: scroll one row at the press, then repeat while held
    local dir = (b.up and -1) or (b.down and 1) or nil
    local fire = nil
    if dir ~= nil then
      if dir ~= MP.hold_dir then
        MP.hold_dir, MP.hold, fire = dir, 0, dir
      else
        MP.hold = MP.hold + 1
        if MP.hold >= MP.REPEAT_WAIT and (MP.hold - MP.REPEAT_WAIT) % MP.REPEAT_EVERY == 0 then fire = dir end
      end
    else
      MP.hold_dir, MP.hold = nil, 0
    end
    if fire ~= nil then
      local first = math.max(1, math.min(MP.first + fire, math.max(1, n - vis + 1)))
      if first ~= MP.first then
        MP.first = first
        Se(C.SE_MOVE)
        DrawTable()
      end
      return
    end
    if (edge("left") or edge("right")) and #bs > 1 then
      MP.button = MP.button == 1 and 2 or 1
      Se(C.SE_MOVE)
      DrawTable()
      return
    end
    if edge("ok") then
      local bt = bs[MP.button]
      if bt ~= nil and not bt.disabled then
        Se(C.SE_GO)
        Call(MP.spec.press, MP.button)
      else
        Se(C.SE_NO)
      end
    end
  end

  local function Draw()
    if not MP.open_now then return end
    if type(MP.spec.columns) == "table" then return DrawTable() end
    local left, top, w, h, rh, rtop = Geometry()
    local n = #MP.rows
    local cx = left + w / 2
    local function rowy(k) return rtop + rh * (k - 0.5) end
    -- the window, the cells, the title bar, the hint strip
    Quad(P_PANEL, "panel", cx, top + h / 2, w + 24, h + 20)
    Quad(P_PANEL + 1, "panel", cx, top + h / 2, w + 24, h + 20)
    for k = 1, MP.ROWS_MAX do
      if k <= n then Quad(P_ROW0 + k - 1, "row", cx, rowy(k), w - 32, rh - 6) else HideQuad(P_ROW0 + k - 1) end
    end
    Quad(P_TITLE, "title", cx, top + MP.TITLE_H / 2, w, MP.TITLE_H - 6)
    local hy = rtop + rh * n + MP.GAP + MP.HINT_H / 2
    Quad(P_HINT, "hint", cx, hy, w - 32, MP.HINT_H - 6)
    -- the focused row: fill + frame; its arrows when its value cycles
    local r = MP.rows[MP.sel]
    local vx = left + math.floor(w * 0.56)            -- the value column (the left arrow's centre)
    local rx = left + w - 52                          -- the right arrow's centre
    if r ~= nil then
      Quad(P_FOCUS, "focus", cx, rowy(MP.sel), w - 32, rh - 6)
      Quad(P_FRAME, "frame", cx, rowy(MP.sel), w - 24, rh + 2)
    else
      HideQuad(P_FOCUS)
      HideQuad(P_FRAME)
    end
    local arrows = r ~= nil and r.value ~= nil and r.value ~= "" and not r.disabled and r.cycle ~= false
    if arrows then
      local ah = rh - 12
      Quad(P_ARROW_L, "arrow_l", vx, rowy(MP.sel), ah * 40 / 48, ah)
      Quad(P_ARROW_R, "arrow_r", rx, rowy(MP.sel), ah * 40 / 48, ah)
    else
      HideQuad(P_ARROW_L)
      HideQuad(P_ARROW_R)
    end
    -- the texts
    Text(T_TITLE, MP.spec.title, left + 40, top + MP.TITLE_H / 2, MP.SCALE_TITLE)
    local hs = Hints()
    for i = 1, MP.HINTS_MAX do
      local x = left + 40 + (i - 1) * (w - 80) / math.max(1, #hs)
      Text(T_HINT0 + i - 1, hs[i], x, hy, MP.SCALE_HINT)
    end
    for k = 1, MP.ROWS_MAX do
      local row = MP.rows[k]
      local li = T_ROW0 + 2 * (k - 1)
      if row ~= nil then
        Text(li, tostring(row.label or ""), left + 40, rowy(k))
        -- every value starts where the left arrow ends: the column does not jump with the focus
        local v = row.value
        Text(li + 1, v ~= nil and tostring(v) or nil, vx + 30, rowy(k))
      else
        Text(li, nil)
        Text(li + 1, nil)
      end
    end
    MP.drawn = true
  end

  local function Refresh()
    --- Internal: rows read from the current spec's data source.
    MP.rows = ReadRows()
    if MP.sel > #MP.rows then MP.sel = math.max(1, #MP.rows) end
    if type(MP.spec.columns) == "table" then
      MP.first = math.max(1, math.min(MP.first or 1, #MP.rows - TableVisible() + 1))
    end
    Draw()
  end

  local function Pause(on)
    if not MP.spec.pause then return end
    if on then
      local ok, okc, now = pcall(funcLuaCommand, C.PAUSE)
      MP.paused_before = (ok and okc == true) and (now == 1) or nil
      pcall(funcLuaCommand, C.PAUSE, 1)
    elseif MP.paused_before ~= true then
      pcall(funcLuaCommand, C.PAUSE, 0)
    end
  end

  -- the pad's held mask (-1 = not resolved) and the keys, as one set of "buttons" this frame
  local function Buttons()
    local ok, held = pcall(funcLuaCommand, C.PAD)
    held = (ok and type(held) == "number" and held >= 0) and held or 0
    local b = {}
    local function pad(m) return math.floor(held / m) % 2 == 1 end
    local function key(vk)
      local v = VRFW.host.command(C.KEY, vk)
      return v == true
    end
    b.up = pad(PAD.UP) or key(VK.UP)
    b.down = pad(PAD.DOWN) or key(VK.DOWN)
    b.left = pad(PAD.LEFT) or key(VK.LEFT)
    b.right = pad(PAD.RIGHT) or key(VK.RIGHT)
    b.ok = pad(PAD.A) or key(VK.ENTER)
    b.back = pad(PAD.B) or pad(PAD.BACK) or key(VK.ESC) or key(VK.BACKSPACE)
    return b
  end

  -- public -----------------------------------------------------------------------------------------------------------

  --- Internal: True while the panel is open.
  function MP.is_open() return MP.open_now end

  --- Internal: Hides the panel's parts while it is closed.
  function MP.hide()
    if not MP.open_now then HideAll() end
  end

  --- Internal: Labels a spec needs (table mode: title, hints, the cells of the head and visible rows, the buttons).
  function MP.labels_needed(spec)
    if type(spec) ~= "table" or type(spec.columns) ~= "table" then return MP.LABELS end
    local nb = type(spec.buttons) == "table" and math.min(#spec.buttons, 2) or 0
    return T_ROW0 + #spec.columns * (VisibleOf(spec) + 1) + nb
  end

  --- Internal: Plates a spec needs (table mode: the list-mode plates, two icon plates per visible row and the lock).
  function MP.plates_needed(spec)
    if type(spec) ~= "table" or type(spec.columns) ~= "table" then return MP.PLATES end
    return PLock(VisibleOf(spec)) + 1
  end

  --- Internal: The host menu has the two layers (a mod's [[patch]] add_layer) with enough instances (for `spec`, if given).
  function MP.available(spec)
    return Count(L_PLATE) >= MP.plates_needed(spec) and Count(L_LABEL) >= MP.labels_needed(spec)
  end

  --- Internal: Opens the panel with spec; answers true, or false, why.
  function MP.open(spec)
    if MP.open_now then return false, "already open" end
    if type(spec) ~= "table" or type(spec.rows) ~= "function" then return false, "a spec with rows expected" end
    --- Internal: the spec of the panel that is currently open.
    MP.spec = spec
    if not MP.available(spec) then
      Log("refused: the host menu needs the layers vrfw_mp_plate x" .. MP.plates_needed(spec) .. " / vrfw_mp_label x" .. MP.labels_needed(spec) ..
        " (has " .. Count(L_PLATE) .. " / " .. Count(L_LABEL) .. ")")
      MP.spec = nil
      return false, "the host menu lacks the panel layers"
    end
    MP.open_now, MP.sel, MP.guard, MP.hold, MP.hold_dir = true, 1, MP.OPEN_GUARD, 0, nil
    MP.first, MP.button = 1, (spec.focus == 2 and type(spec.buttons) == "table" and spec.buttons[2] ~= nil) and 2 or 1
    --- Internal: key edge state of the panel's input keys, set after release.
    MP.prev_keys = {up = true, down = true, left = true, right = true, ok = true, back = true}  -- edges after release
    --- Internal: resolved style of the open panel (spec style over the default).
    MP.style = Resolve(spec.style)
    MP.tex, MP.tex_ok, MP.tex_t = {}, false, 0
    for _, part in pairs(MP.style) do
      local a = part[1]
      if MP.tex[a] == nil then
        VRFW.host.menu_command(C.LOAD_TEX, a)
        MP.tex[a] = CRC32(a)
      end
    end
    Pause(true)
    Refresh()
    Se(C.SE_GO)
    Log("open", #MP.rows, "rows")
    return true
  end

  --- Internal: Closes the panel; `why` goes to its close callback.
  function MP.close(why)
    if not MP.open_now then return end
    MP.open_now, MP.suspended = false, nil
    HideAll()
    Pause(false)
    Log("close", why or "closed")
    local s = MP.spec
    MP.spec = nil
    if s ~= nil then Call(s.closed, why or "closed") end
  end

  --- Internal: Suspends the panel (on) or resumes it; `title` shows while suspended.
  function MP.suspend(on, title)
    if not MP.open_now then return end
    --- Internal: true (or nil) while the panel is suspended and hidden.
    MP.suspended = on and true or nil
    if on then
      HideAll()
      if type(title) == "string" and title ~= "" then Text(T_TITLE, title, 120, 90, MP.SCALE_TITLE) end
    else
      MP.guard, MP.hold, MP.hold_dir = MP.OPEN_GUARD, 0, nil
      MP.prev_keys = {up = true, down = true, left = true, right = true, ok = true, back = true}
      Refresh()
    end
  end

  --- Internal: The rows changed outside (a mod's own state): read and draw them again.
  function MP.refresh()
    if MP.open_now then Refresh() end
  end

  --- Internal: One frame of the open panel.
  function MP.step()
    if not MP.open_now or MP.suspended then return end
    if not MP.tex_ok then
      MP.tex_t = MP.tex_t + 1
      local busy = false
      for _, t in pairs(MP.tex) do
        local ok, b = pcall(funcLuaCommand, C.TEX_LOADING, t)
        if ok and b == true then busy = true end
      end
      if not busy or MP.tex_t >= MP.TEX_MAX then
        MP.tex_ok = true
        Draw()
      end
    end
    local b = Buttons()
    local p = MP.prev_keys
    local function edge(k) return b[k] and not p[k] end
    MP.prev_keys = b
    if MP.guard > 0 then
      MP.guard = MP.guard - 1
      return
    end
    if edge("back") then
      Se(C.SE_BACK)
      return MP.close("back")
    end
    if type(MP.spec.columns) == "table" then return StepTable(b, edge) end
    local n = #MP.rows
    if n == 0 then return end
    local moved = false
    if edge("up") then
      MP.sel = MP.sel > 1 and MP.sel - 1 or n
      moved = true
    elseif edge("down") then
      MP.sel = MP.sel < n and MP.sel + 1 or 1
      moved = true
    end
    if moved then
      Se(C.SE_MOVE)
      Draw()
      return
    end
    -- LEFT / RIGHT: a step at the press, then repeat while held
    local dir = (b.left and -1) or (b.right and 1) or nil
    local fire = nil
    if dir ~= nil then
      if dir ~= MP.hold_dir then
        MP.hold_dir, MP.hold, fire = dir, 0, dir
      else
        MP.hold = MP.hold + 1
        if MP.hold >= MP.REPEAT_WAIT and (MP.hold - MP.REPEAT_WAIT) % MP.REPEAT_EVERY == 0 then fire = dir end
      end
    else
      MP.hold_dir, MP.hold = nil, 0
    end
    local r = MP.rows[MP.sel]
    if fire ~= nil then
      if r ~= nil and not r.disabled then
        Call(MP.spec.change, MP.sel, fire)
        Se(C.SE_MOVE)
        if MP.open_now then Refresh() end
      else
        Se(C.SE_NO)
      end
      return
    end
    if edge("ok") then
      if r ~= nil and not r.disabled then
        Se(C.SE_GO)
        if type(MP.spec.decide) == "function" then
          Call(MP.spec.decide, MP.sel)
        else
          Call(MP.spec.change, MP.sel, 1)
        end
        if MP.open_now then Refresh() end
      else
        Se(C.SE_NO)
      end
    end
  end
end
