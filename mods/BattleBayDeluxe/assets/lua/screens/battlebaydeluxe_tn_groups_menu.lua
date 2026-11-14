INCLUDE("LUA_PROG_BASE")

local MENU = 1994548118           -- battlebaydeluxe_tn_groups_menu
local CMD_VIEW = 2626318594       -- CMND_BATTLEBAYDELUXE_TOURNAMENT_VIEW
local ART = 2658588602
local NODE_QUAD = 1909474081       -- icon_new01 (the quad node of cmn01_10)
local MESH_QUAD = 312193881        -- _icon_new01
local Q = 36                       -- the quad's own size (px at scale 1)

local L = {
  card = 3054287085,   -- battlebaydeluxe_gt_card (546)
  band = 3905389269,   -- battlebaydeluxe_gt_band (547)
  mark = 3329020495,   -- battlebaydeluxe_gt_mark (548)
  row = 2532487227,    -- battlebaydeluxe_gt_row (551, battlebaydeluxe_tn_row_l)
  txt = 250943909,    -- battlebaydeluxe_gt_txt (553, battlebaydeluxe_tn_txt)
  face = 2769050457,
}
local N = {}
local KEY_OF = {}
for k, l in pairs(L) do
  KEY_OF[l] = k
end

-- The retail commands this screen calls, as numbers: the framework kit loads after this chunk, so no name lookup at load.
local C = {
  VISIBLE = 711242136,            -- CMND_SET_LAYER_VISIBLE
  POS = 1389957207,               -- CMND_SET_LAYER_LOCAL_POS
  SCALE = 3778714801,             -- CMND_SET_LAYER_LOCAL_SCALE
  SPRITE = 558735651,             -- the layer sprite command (retail name unknown)
  PRIM_COLOR = 855211291,         -- CMND_SET_PRIM_COLOR
  MESH_VISIBLE = 3405944500,      -- CMND_SET_MESH_VISIBLE
  TEXT = 1083631230,              -- CMND_SET_MENU_TEXT_STRING
  TEXT_VISIBLE = 1505208242,      -- CMND_SET_MENU_TEXT_VISIBLE
  TEXT_STYLE = 2333948100,        -- the menu text style command (retail name unknown)
  TEXT_GET = 4074371074,          -- CMND_TEXT_GET
  LAYER_NUM = 1175615627,         -- CMND_GET_CREATE_LAYER_NUM (layer) -> instances created
  MODEL_ALPHA = 4231609516,       -- CMND_SET_LAYER_MODEL_ALPHA
  TEXT_ALPHA = 1126837159,        -- CMND_SET_MENU_TEXT_ALPHA
  CROSS_CALL = 830228314,         -- (menu, function name, ...): a function of another menu's Lua
}
local PLATE = { 2022529787, 2334302522, 4215821749, 1697431574 }   -- _list_base_xs01_off / _on / _ok / _ol
local MESH_EMBLEM = 3281704751     -- _icon_emblem_dmy01 (its crest: VRFW.team.emblem)
local TXT_ON = 931545948           -- _text_list01_on (white)
local TXT_OFF = 3705682548         -- _text_list01_off (blue)
local OUT_ALPHA = 0.45             -- a team that is out (the overlay's OUT_ALPHA)

-- the sprites of bbd_tn.g4tx (research/mods/BattleBayDeluxe/_tools/bbd_bracket_art.py)
local SP = {
  card = 2624519773, head = 763990034, qual = 308650821, qual_tint = 2315879333, me = 2434295730, pts = 910184237,
  pts_me = 1149433725, sep = 4275471326, stroke = 144416928, stroke2 = 3423307333,
  W = 1675980812, D = 3881513426, L = 3917527520, none = 2704804066,
}

-- the geometry (screen px, y down, 1920 x 1080)
local G = {
  W = 1920, Y0 = 124, Y1 = 984, MX = 40, GAP_X = 20, GAP_Y = 16, LEGEND_Y = 1014, LEGEND_X = 56,
  WIDE_MAX = 900,   -- one group alone: its card at most this wide, centred
  CARD = { W = 256, H = 256, L = 6, T = 6, R = 14, B = 18, SK = 8 },
  PLATE_H = 72, CREST_IN = 22, NAME_L = 98, NAME_PX = 32, NAME_CHAR = 0.48,
  FILL = 0.84, PAD = 6, SEP = 2, QBAR = 6, TXT_HALF = 304,
  ST = {
    num = 3847724198,       -- fs_28_b_cc_2d0_001 (blue, centred, no outline)
    num_dim = 2029954615,   -- fs_28_k_cc_2d0_001 (W D L GF GC)
    num_me = 1911293514,    -- fs_28_w_cc_2d0_001 (white, the player's row)
    pts = 2392563157,       -- fs_32_b_cc_2d0_001
    pts_me = 438306617,     -- fs_32_w_cc_2d0_001
    label = 543999875,      -- fs_22_k_cc_2d0_001_nr_sclw (column labels)
    label_l = 3591594987,   -- fs_22_k_lc_2d0_001_nr_sclw (Team)
    label_pts = 2001536506, -- fs_22_b_cc_2d0_001_sclw (Points)
    label_head = 1829976141, -- fs_22_w_cc_2d0_001_nr (labels in the header band, tiny)
    title = 3945487540,     -- fs_32_w_lc_2d0_001 (GROUP A)
    title_c = 438306617,
    legend = 834427687,     -- fs_26_w_lc_2d2_001 (outlined white, on the background)
  },
  MODES = {
    wide = { head = 50, labels = 30, pitch_max = 84, s_max = 0.8, cw = 42, ptsw = 58, pos_w = 44, pad_r = 16,
      cols = { "pj", "g", "e", "p", "gf", "gc", "dg", "pts" }, form = "col", dot = 22, dot_pitch = 28,
      name_dy = 0, num_s = 0.95, pts_s = 0.95, title_s = 1.0, label_s = 0.95 },
    compact = { head = 46, labels = 28, pitch_max = 84, s_max = 0.66, cw = 28, ptsw = 42, pos_w = 30, pad_r = 14,
      cols = { "pj", "g", "e", "p", "dg", "pts" }, form = "under", dot = 12, dot_pitch = 16, dot_dy = 21,
      name_dy = -8, num_s = 0.8, pts_s = 0.82, title_s = 0.85, label_s = 0.85 },
    tiny = { head = 34, labels = 0, pitch_max = 48, s_max = 0.5, cw = 38, ptsw = 44, pos_w = 30, pad_r = 12,
      cols = { "pj", "dg", "pts" }, form = false, name_dy = 0, num_s = 0.6, pts_s = 0.62, title_s = 0.62,
      label_s = 0.7 },
  },
  DIM = { g = true, e = true, p = true, gf = true, gc = true },
}

-- state of this opening
local S = { page = nil, host = nil, need = 0, got = 0, per = {}, seen = {}, frame = 0, drawn = false, logged = false,
  want = false, used = {}, miss = {}, emb = {}, strip = {}, groups = 0, mode = "", stuck = false }
local Handshake

-- the logger is made at the first line
local logger
local function Log(...)
  logger = logger or VRFW.logger.new("BattleBayDeluxe.tournament_groups")
  logger(...)
end

local function Text(key)
  local t = VRFW.host.command(C.TEXT_GET, VRFW.ids.crc32("battlebaydeluxe_tn_" .. key))
  return type(t) == "string" and t or ""
end

-- The title of group n (1 = A): the one group text with its <VALUE> tag replaced by the letter; empty outside 1-16.
local GROUP_LETTERS = "ABCDEFGHIJKLMNOP"
local function GroupTitle(n)
  if n < 1 or n > #GROUP_LETTERS then
    return ""
  end
  local t = Text("group")
  local i, j = string.find(t, "<VALUE>", 1, true)
  if not i then
    return t
  end
  return string.sub(t, 1, i - 1) .. string.sub(GROUP_LETTERS, n, n) .. string.sub(t, j + 1)
end

local function SetSprite(l, atlas, spr, node, i)
  local done = VRFW.host.menu_command(C.SPRITE, l, atlas, spr, node, 0, i)
  return done == true
end

local function Hide(layer, i)
  funcLuaMenuCommand(C.VISIBLE, layer, i, false)
  funcLuaMenuCommand(C.POS, layer, -4000, 4000, 0, i)
end

local function Take(k)
  local i = S.used[k] or 0
  if i >= N[k] then
    S.miss[k] = (S.miss[k] or 0) + 1
    return nil
  end
  S.used[k] = i + 1
  return i
end

local function Quad(k, spr, x, y, w, h)
  local i = Take(k)
  if i == nil then
    return
  end
  local l = L[k]
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.SCALE, l, w / Q, h / Q, 1, i)
  SetSprite(l, ART, spr, NODE_QUAD, i)
  funcLuaMenuCommand(C.POS, l, x, -y, 0, i)
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, MESH_QUAD, 1, 1, 1)
end

-- a flat quad from (x0, y0) to (x1, y1)
local function Rect(k, spr, x0, y0, x1, y1)
  if x1 <= x0 or y1 <= y0 then
    return
  end
  Quad(k, spr, (x0 + x1) / 2, (y0 + y1) / 2, x1 - x0, y1 - y0)
end

-- a free text centred on (x, y) at `scale` in a retail font style
local function Txt(s, x, y, scale, style)
  if s == nil or s == "" then
    return
  end
  local i = Take("txt")
  if i == nil then
    return
  end
  local l = L.txt
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.POS, l, x, -y, 0, i)
  funcLuaMenuCommand(C.SCALE, l, scale, scale, 1, i)
  funcLuaMenuCommand(C.TEXT_STYLE, l, i, TXT_ON, style)
  funcLuaMenuCommand(C.TEXT, l, TXT_ON, s, i)
  funcLuaMenuCommand(C.TEXT, l, TXT_OFF, "", i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, TXT_ON, true, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, TXT_OFF, false, i)
end

-- a text left-aligned at x (the text box is 608 px wide, centred on the instance's origin)
local function TxtLeft(s, x, y, scale, style)
  Txt(s, x + G.TXT_HALF * scale, y, scale, style)
end

-- a string's width in glyph units (CJK = 2) and its cut to `units` with an ellipsis
local function Units(s) return VRFW.text_fold.units(s) end

local function Fit(s, units) return VRFW.text_fold.cut(s, units) end

local function TeamRowObject(r, x, y, s, maxpx, white, a)
  local i = Take("row")
  if i == nil then
    return
  end
  local l = L.row
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.SCALE, l, s, s, 1, i)
  funcLuaMenuCommand(C.POS, l, x, -y, 0, i)
  for _, m in ipairs(PLATE) do
    funcLuaMenuCommand(C.MESH_VISIBLE, l, m, false, i)
  end
  local name = Fit(VRFW.team.name(r.team), math.floor(maxpx / (G.NAME_PX * s * G.NAME_CHAR)))
  funcLuaMenuCommand(C.TEXT, l, TXT_ON, white and name or "", i)
  funcLuaMenuCommand(C.TEXT, l, TXT_OFF, white and "" or name, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, TXT_ON, white, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, TXT_OFF, not white, i)
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, MESH_EMBLEM, 1, 1, 1)
  VRFW.host.menu_command(C.MODEL_ALPHA, l, i, 0, a)
  VRFW.host.menu_command(C.TEXT_ALPHA, l, i, TXT_ON, a)
  VRFW.host.menu_command(C.TEXT_ALPHA, l, i, TXT_OFF, a)
  VRFW.team.emblem(L.row, i, r.team, S.emb)
end

local function Row(r, x, y, s, maxpx)
  TeamRowObject(r, x, y, s, maxpx, r.me == true, r.out and OUT_ALPHA or 1)
end

local function GoalDifference(n)
  n = n or 0
  return n > 0 and ("+" .. n) or tostring(n)
end

-- one group's card at (x, y), w x h
local function Card(grp, M, x, y, w, h, pitch)
  local K = G.CARD
  local sx, sy = w / (K.W - K.L - K.R), h / (K.H - K.T - K.B)
  Quad("card", SP.card, x - K.L * sx + K.W * sx / 2, y - K.T * sy + K.H * sy / 2, K.W * sx, K.H * sy)
  local sk = K.SK * sx
  local function lx(yy)
    return x + sk * (1 - (yy - y) / h)
  end
  local function rx(yy)
    return x + w - sk * (yy - y) / h
  end
  local xr = x + w - sk - 3
  local ptsx = xr - M.pad_r - M.ptsw / 2
  local xs = {}
  local nc = #M.cols
  xs[nc] = ptsx
  for c = nc - 1, 1, -1 do
    xs[c] = ptsx - M.ptsw / 2 - M.cw * (nc - c - 0.5)
  end
  local num_left = ptsx - M.ptsw / 2 - M.cw * (nc - 1)
  local form_right = num_left - 10
  local limit = M.form == "col" and (form_right - 3 * M.dot_pitch - 6) or (num_left - 8)
  -- the header band, its strokes and title
  local hb = y + M.head
  local bx0, bx1 = lx(y + M.head / 2), rx(y + M.head / 2)
  Rect("band", SP.head, bx0, y, bx1, hb)
  local stx = M.labels > 0 and (bx1 - M.head * 2.4) or (num_left - M.head * 1.4)
  Quad("mark", SP.stroke, stx, y + M.head / 2, M.head * 0.5, M.head)
  Quad("mark", SP.stroke2, stx + M.head * 0.55, y + M.head / 2, M.head * 0.3, M.head)
  TxtLeft(string.upper(GroupTitle(grp.n or 0)), lx(y) + 18, y + M.head / 2, M.title_s, G.ST.title)
  local xl = lx(y) + 3
  local pos_x = xl + G.QBAR + M.pos_w / 2
  local s = math.min(M.s_max, pitch * G.FILL / G.PLATE_H)
  local ox = xl + G.QBAR + M.pos_w - G.CREST_IN * s
  local name_x = ox + G.NAME_L * s
  if M.labels > 0 then
    local ly = hb + M.labels / 2
    TxtLeft(Text("col_team"), name_x, ly, M.label_s, G.ST.label_l)
    if M.form == "col" then
      Txt(Text("col_form"), form_right - 1.5 * M.dot_pitch, ly, M.label_s, G.ST.label)
    end
  end
  for c, k in ipairs(M.cols) do
    local st = M.labels == 0 and G.ST.label_head or (k == "pts" and G.ST.label_pts or G.ST.label)
    Txt(Text("col_" .. k), xs[c], M.labels > 0 and (hb + M.labels / 2) or (y + M.head / 2), M.label_s, st)
  end
  -- the rows
  local top = hb + M.labels + G.PAD
  for k = 1, 4 do
    local r = grp.rows and grp.rows[k]
    if r and (r.team or 0) ~= 0 then
      local ry = top + (k - 1) * pitch
      local yc = ry + pitch / 2
      local rl, rr = lx(ry) + 3, rx(ry + pitch) - 3
      local qual = (r.pos or k) <= 2
      if r.me then
        Rect("band", SP.me, rl, ry + 1, rr, ry + pitch - 1)
      elseif qual then
        Rect("band", SP.qual_tint, rl, ry + 1, rr, ry + pitch - 1)
      end
      if qual then
        Rect("mark", SP.qual, rl, ry + 1, rl + G.QBAR, ry + pitch - 1)
      end
      if k < 4 then
        Rect("mark", SP.sep, rl + G.QBAR + 4, ry + pitch - G.SEP / 2, rr, ry + pitch + G.SEP / 2)
      end
      Rect("mark", r.me and SP.pts_me or SP.pts, ptsx - M.ptsw / 2, ry + 2, ptsx + M.ptsw / 2, ry + pitch - 2)
      local st_num = r.me and G.ST.num_me or G.ST.num
      Txt(tostring(r.pos or k), pos_x, yc, M.num_s, st_num)
      Row(r, ox, yc + M.name_dy, s, limit - name_x)
      for c, key in ipairs(M.cols) do
        local val = key == "dg" and GoalDifference(r.dg) or tostring(r[key] or 0)
        if key == "pts" then
          Txt(val, xs[c], yc, M.pts_s, r.me and G.ST.pts_me or G.ST.pts)
        else
          Txt(val, xs[c], yc, M.num_s, (G.DIM[key] and not r.me) and G.ST.num_dim or st_num)
        end
      end
      local form = tostring(r.form or "")
      if M.form == "under" then
        for f = 1, #form do
          local spr = SP[form:sub(f, f)]
          if spr then
            Quad("mark", spr, name_x + M.dot / 2 + (f - 1) * M.dot_pitch, yc + M.dot_dy, M.dot, M.dot)
          end
        end
      elseif M.form == "col" then
        for f = 1, 3 do
          local spr = SP[form:sub(f, f)] or SP.none
          Quad("mark", spr, form_right - (3 - f + 0.5) * M.dot_pitch, yc, M.dot, M.dot)
        end
      end
    end
  end
end

local function Legend(v, M)
  local y, x = G.LEGEND_Y, G.LEGEND_X
  local ls = 0.9
  local function item(txt)
    TxtLeft(txt, x, y, ls, G.ST.legend)
    x = x + Units(txt) * 26 * ls * 0.45 + 44
  end
  Rect("mark", SP.qual, x, y - 13, x + 10, y + 13)
  x = x + 20
  item(Text("legend_qualify_" .. tostring(v.qualify or 0)))
  Rect("mark", SP.me, x, y - 13, x + 10, y + 13)
  x = x + 20
  item(Text("legend_you"))
  if M.form then
    for _, f in ipairs({ "W", "D", "L" }) do
      Quad("mark", SP[f], x + 9, y, 18, 18)
      x = x + 24
      local t = Text("form_" .. f:lower())
      TxtLeft(t, x, y, ls, G.ST.legend)
      x = x + Units(t) * 26 * ls * 0.45 + 18
    end
    item(Text("legend_form"))
  end
end

local function Grid(n)
  if n <= 2 then
    return "wide", math.max(1, n), 1
  elseif n <= 4 then
    return "wide", 2, 2
  elseif n <= 8 then
    return "compact", 4, 2
  end
  return "tiny", 4, math.ceil(n / 4)
end

local function DrawGroups(v)
  local groups = v.groups or {}
  local n = #groups
  S.groups, S.mode = 0, ""
  if n == 0 then
    return
  end
  local mode, cols, rows = Grid(n)
  local M = G.MODES[mode]
  local cw = (G.W - 2 * G.MX - (cols - 1) * G.GAP_X) / cols
  if cols == 1 then
    cw = math.min(cw, G.WIDE_MAX)
  end
  local x0 = (G.W - (cols * cw + (cols - 1) * G.GAP_X)) / 2
  local ch_max = (G.Y1 - G.Y0 - (rows - 1) * G.GAP_Y) / rows
  local pitch = math.min(M.pitch_max, (ch_max - M.head - M.labels - 2 * G.PAD) / 4)
  local ch = M.head + M.labels + 2 * G.PAD + 4 * pitch
  local top = (G.Y0 + G.Y1) / 2 - (rows * ch + (rows - 1) * G.GAP_Y) / 2
  for gi, grp in ipairs(groups) do
    local c, r = (gi - 1) % cols, math.floor((gi - 1) / cols)
    if r < rows then
      Card(grp, M, x0 + c * (cw + G.GAP_X), top + r * (ch + G.GAP_Y), cw, ch, pitch)
      S.groups = S.groups + 1
    end
  end
  Legend(v, M)
  S.mode = string.format("%s %dx%d", mode, cols, rows)
end

local LG = {
  W_MAX = 1320, head = 50, labels = 32, pitch_max = 66, s_max = 392 / 520, pos_w = 56, cw = 64, ptsw = 76, pad_r = 18,
  cols = { "pj", "g", "e", "p", "gf", "gc", "dg", "pts" }, dot = 22, dot_pitch = 28, form = 5, form_gap = 24,
  plate_gap = 20, name_pad = 24, num_s = 0.95, pts_s = 0.95, title_s = 1.0, label_s = 0.95,
  PLATE_W = 520, FRAME_W = 408 / 392, FRAME_H = 88 / 72,
  -- the team strips in the order of config.toml [bracket_strips] names (a row's .strip = its 1-based index)
  STRIPS = { "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "black", "silver" },
  PLATE_ATLAS_PATH = "#/menu/102_team/team06/team06_02/team06_02.g4tx",
}
local LG_SPR = nil

-- the sprite crcs of the league's pieces (once)
local function LeagueSprites()
  if LG_SPR == nil then
    LG_SPR = { strip = {}, frame = VRFW.ids.crc32("bbd_tn_frame_l"), plate = VRFW.ids.crc32("list_base_xs01_off"),
      neutral = VRFW.ids.crc32("bbd_tn_strip_black"), focus = VRFW.ids.crc32("bbd_tn_line_me") }
    for i, n in ipairs(LG.STRIPS) do
      LG_SPR.strip[i] = VRFW.ids.crc32("bbd_tn_strip_" .. n)
    end
  end
  return LG_SPR
end

local function Plate(r, x, y, s, maxpx)
  local sp = LeagueSprites()
  local spr = sp.strip[tonumber(r.strip) or 0] or sp.neutral
  Quad("band", spr, x + LG.PLATE_W * s / 2, y, LG.PLATE_W * s, G.PLATE_H * s)
  TeamRowObject(r, x, y, s, maxpx, true, 1)
end

local LG_ART = {
  ATLAS = "#/menu/220_img/bbd_lg/bbd_lg.g4tx", L = 6, T = 6, R = 14, B = 18, SK = 18,
  STROKES = 2.4,
  table = { spr = "bbd_lg_table", w = 1320, h = 860, head = 50 },
  hero = { spr = "bbd_lg_hero", w = 766, h = 354 }, stand = { spr = "bbd_lg_stand", w = 776, h = 354 },
  panel = { spr = "bbd_lg_panel", w = 508, h = 220 }, cal = { spr = "bbd_lg_cal", w = 1558, h = 214 },
}

local function CardTitle(kind, x, y, w, h, head, title, scale)
  local A = LG_ART
  local c = A[kind]
  local yc = y + head / 2
  local x0 = x + A.SK * (w / c.w) * (1 - (yc - y) / h)
  local x1 = x + w - A.STROKES * c.head * (w / c.w)
  Txt(title, (x0 + x1) / 2, yc, scale, G.ST.title_c)
end

local function BigCard(kind, x, y, w, h)
  local A = LG_ART
  local c = A[kind]
  if A.atlas == nil then
    A.atlas = VRFW.ids.crc32(A.ATLAS)
  end
  c.crc = c.crc or VRFW.ids.crc32(c.spr)
  local sx, sy = w / c.w, h / c.h
  local i = Take("card")
  if i == nil then
    return A.SK
  end
  local l = L.card
  local fw, fh = (c.w + A.L + A.R) * sx, (c.h + A.T + A.B) * sy
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.SCALE, l, fw / Q, fh / Q, 1, i)
  SetSprite(l, A.atlas, c.crc, NODE_QUAD, i)
  funcLuaMenuCommand(C.POS, l, x - A.L * sx + fw / 2, -(y - A.T * sy + fh / 2), 0, i)
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, MESH_QUAD, 1, 1, 1)
  return A.SK * sx
end

local function DrawLeague(v)
  local rows = v.standings or {}
  S.groups, S.mode = 0, ""
  local R = math.max(#rows, tonumber(v.page_rows) or #rows, 1)
  local w = math.min(LG.W_MAX, G.W - 2 * G.MX)
  local x = (G.W - w) / 2
  local pitch = math.min(LG.pitch_max, (G.Y1 - G.Y0 - LG.head - LG.labels - 2 * G.PAD) / R)
  local h = LG.head + LG.labels + 2 * G.PAD + R * pitch
  local y = (G.Y0 + G.Y1) / 2 - h / 2
  -- the card and its slanted edges (the card art 1:1, its header band and strokes baked in)
  local sk = BigCard("table", x, y, w, h)
  local function lx(yy)
    return x + sk * (1 - (yy - y) / h)
  end
  local function rx(yy)
    return x + w - sk * (yy - y) / h
  end
  local xr = x + w - sk - 3
  local ptsx = xr - LG.pad_r - LG.ptsw / 2
  local xs, nc = {}, #LG.cols
  xs[nc] = ptsx
  for c = nc - 1, 1, -1 do
    xs[c] = ptsx - LG.ptsw / 2 - LG.cw * (nc - c - 0.5)
  end
  local num_left = ptsx - LG.ptsw / 2 - LG.cw * (nc - 1)
  local form_right = num_left - LG.form_gap
  local form_left = form_right - LG.form * LG.dot_pitch
  -- the title on the card's header band
  local hb = y + LG.head
  CardTitle("table", x, y, w, h, LG.head, Text("league_title"), LG.title_s)
  local xl = lx(y) + 3
  local pos_x = xl + G.QBAR + LG.pos_w / 2
  local s = math.min(LG.s_max, pitch * G.FILL / G.PLATE_H)
  local ox = xl + G.QBAR + LG.pos_w
  local name_x = ox + G.NAME_L * s
  local name_px = math.min((LG.PLATE_W - G.NAME_L - LG.name_pad) * s, form_left - LG.plate_gap - name_x)
  -- the column labels under the band
  local ly = hb + LG.labels / 2
  TxtLeft(Text("col_team"), name_x, ly, LG.label_s, G.ST.label_l)
  Txt(Text("col_form"), (form_left + form_right) / 2, ly, LG.label_s, G.ST.label)
  for c, k in ipairs(LG.cols) do
    Txt(Text("col_" .. k), xs[c], ly, LG.label_s, k == "pts" and G.ST.label_pts or G.ST.label)
  end
  local top = hb + LG.labels + G.PAD
  local sp = LeagueSprites()
  for k, r in ipairs(rows) do
    if (r.team or 0) ~= 0 then
      local ry = top + (k - 1) * pitch
      local yc = ry + pitch / 2
      local rl, rr = lx(ry) + 3, rx(ry + pitch) - 3
      if (r.pos or k) == 1 then
        Rect("mark", SP.qual, rl, ry + 1, rl + G.QBAR, ry + pitch - 1)
      end
      if k < #rows then
        Rect("mark", SP.sep, rl + G.QBAR + 4, ry + pitch - G.SEP / 2, rr, ry + pitch + G.SEP / 2)
      end
      Rect("mark", r.me and SP.pts_me or SP.pts, ptsx - LG.ptsw / 2, ry + 2, ptsx + LG.ptsw / 2, ry + pitch - 2)
      Txt(tostring(r.pos or k), pos_x, yc, LG.num_s, G.ST.num)
      if r.me then
        local pw = LG.PLATE_W * s
        Quad("mark", sp.frame, ox + pw / 2, yc, pw * LG.FRAME_W, G.PLATE_H * s * LG.FRAME_H)
      end
      Plate(r, ox, yc, s, name_px)
      for c, key in ipairs(LG.cols) do
        local val = key == "dg" and GoalDifference(r.dg) or tostring(r[key] or 0)
        if key == "pts" then
          Txt(val, xs[c], yc, LG.pts_s, r.me and G.ST.pts_me or G.ST.pts)
        else
          Txt(val, xs[c], yc, LG.num_s, G.DIM[key] and G.ST.num_dim or G.ST.num)
        end
      end
      -- the last results, oldest first (the slots not played yet as rings)
      local form = tostring(r.form or "")
      for f = 1, LG.form do
        local spr = SP[form:sub(f, f)] or SP.none
        Quad("mark", spr, form_left + (f - 0.5) * LG.dot_pitch, yc, LG.dot, LG.dot)
      end
      S.groups = S.groups + 1
    end
  end
  -- no legend under the standings (it covered the button guide)
  S.mode = string.format("league page %d/%d, %d rows", v.page_n or 1, v.page_count or 1, #rows)
end

local HUB = {
  NAV = { X = 24, Y = 84, W = 294, H = 908, CREST = 112, CREST_Y = 162, NAME_Y = 244, LEVEL_Y = 278, SEP_Y = 306,
    ITEM_X = 40, ITEM_W = 262, ITEM_H = 66, ITEM_Y = 330, ITEM_PITCH = 80, ICON = 34, ICON_X = 74, LABEL_X = 112,
    PILL_Y = { 858, 924 }, PILL_W = 262, PILL_H = 56 },
  HEAD = { X = 338, Y = 84, W = 1558, H = 78, BAR_X0 = 790, BAR_X1 = 1370, BAR_Y = 112, BAR_H = 18, LABEL_Y = 146 },
  HERO = { X = 338, Y = 176, W = 766, H = 354, head = 50, CREST = 124, CREST_DX = 190, CREST_Y = 288, PLATE_S = 330 / 520,
    PLATE_Y = 382, INFO_Y = 422, BTN_W = 280, BTN_H = 52, BTN_Y = 454, BTN_GAP = 24 },
  STAND = { X = 1120, Y = 176, W = 776, H = 354, head = 50, LABEL_Y = 240, TOP = 256, PITCH = 40, GAP = 16, CREST = 30 },
  PANEL = { Y = 544, W = 508, H = 220, head = 44, XS = { 338, 862, 1386 } },
  CAL = { X = 338, Y = 778, W = 1558, H = 214, head = 44, FIX_W = 292, FIX_H = 146, FIX_BAND = 30, GAP = 14, PAD = 18 },
  title_s = 1.0, band_title_s = 0.9, icon_h = 30,
}
-- the atlases of the retail sprites the hub shows (loaded by this screen's res, content\menus\bb_tournament.toml)
local HUB_ATLAS = {
  icons = "#/menu/200_icon/16_icon_list_tab/icon_list_tab.g4tx",   -- icon_list_tab_* (white)
  button = "#/menu/20_cmn/cmn03/cmn03_02/cmn03_02.g4tx",            -- cmd_btn_base01_on / _off
}
local HUB_NAV = {
  { key = "hub_nav_home", icon = "town01" },
  { key = "hub_calendar", icon = "history01" },
  { key = "hub_competition", icon = "vroad01" },
  { key = "hub_roster", icon = "uniform01" },
}
local P_NAV = 667806374           -- battlebaydeluxe_lg_nav
local P_FOCUS = 2824721767        -- battlebaydeluxe_lg_focus
local P_CAL_MD = 497426575        -- battlebaydeluxe_lg_cal_md
local SCORERS = { name_w = 460, gap = 24, name_s = 1.25, name_px = 22 }
local CHARA_OF_CARD = 347353059    -- (card) -> chara id
local CHARA_NAME = 523676951       -- (chara id) -> name

-- a text of the mod with <VALUE> / <VALUE2> filled (the retail text value command)
local function TextValue2(key, a, b)
  return VRFW.bracket.text_value2(Text(key), a, b)
end

local function CharaName(card)
  local id = VRFW.host.command(CHARA_OF_CARD, card)
  if type(id) ~= "number" or id == 0 then
    return ""
  end
  local name = VRFW.host.command(CHARA_NAME, id)
  return type(name) == "string" and name or ""
end

local function QuadA(k, atlas, spr, x, y, w, h)
  local i = Take(k)
  if i == nil then
    return
  end
  local l = L[k]
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.SCALE, l, w / Q, h / Q, 1, i)
  SetSprite(l, VRFW.ids.crc32(atlas), VRFW.ids.crc32(spr), NODE_QUAD, i)
  funcLuaMenuCommand(C.POS, l, x, -y, 0, i)
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, MESH_QUAD, 1, 1, 1)
end

-- a sprite of the League art (bbd_lg) at its own size, its box's top left at (x, y) (the cards' margins around it)
local function Art(k, spr, x, y, w, h)
  local A = LG_ART
  QuadA(k, A.ATLAS, spr, x - A.L + (w + A.L + A.R) / 2, y - A.T + (h + A.T + A.B) / 2, w + A.L + A.R, h + A.T + A.B)
end

-- a list-tab icon (white, 144 x 96) of height h centred on (x, y)
local function Icon(name, x, y, h)
  QuadA("mark", HUB_ATLAS.icons, "icon_list_tab_" .. name, x, y, h * 1.5, h)
end

-- a team's crest alone (the team row object, plate and name hidden) centred on (x, y), px tall
local function Crest(team, x, y, px)
  if (team or 0) == 0 then
    return
  end
  local s = px / 68
  local i = Take("row")
  if i == nil then
    return
  end
  local l = L.row
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.SCALE, l, s, s, 1, i)
  funcLuaMenuCommand(C.POS, l, x - 56 * s, -y, 0, i)
  for _, m in ipairs(PLATE) do
    funcLuaMenuCommand(C.MESH_VISIBLE, l, m, false, i)
  end
  funcLuaMenuCommand(C.TEXT, l, TXT_ON, "", i)
  funcLuaMenuCommand(C.TEXT, l, TXT_OFF, "", i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, TXT_ON, false, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, TXT_OFF, false, i)
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, MESH_EMBLEM, 1, 1, 1)
  VRFW.host.menu_command(C.MODEL_ALPHA, l, i, 0, 1)
  VRFW.team.emblem(L.row, i, team, S.emb)
end

-- a card's header title with its list-tab icon on the navy band
local function BandTitle(x, y, head, icon, title)
  Icon(icon, x + 34, y + head / 2, HUB.icon_h)
  TxtLeft(title, x + 64, y + head / 2, HUB.band_title_s, G.ST.title)
end

local function BandRight(x1, y, head, s)
  if s and s ~= "" then
    Txt(s, x1 - 150 - Units(s) * 6, y + head / 2, 0.9, G.ST.label_head)
  end
end

-- an integer parameter the host sets (0 when it is not set)
local function ParamInt(p)
  if VRFW.param.has(p) then
    local n = VRFW.param.get(p)
    if type(n) == "number" then
      return math.floor(n)
    end
  end
  return 0
end

local function NavCursor()
  return ParamInt(P_NAV)
end

local function FocusPanel()
  return ParamInt(P_FOCUS)
end

local function FocusFrame(x0, y0, x1, y1)
  local f, t = LeagueSprites().focus, 5
  Rect("mark", f, x0 - t - 2, y0 - t - 2, x1 + t + 2, y0 - 2)
  Rect("mark", f, x0 - t - 2, y1 + 2, x1 + t + 2, y1 + t + 2)
  Rect("mark", f, x0 - t - 2, y0 - 2, x0 - 2, y1 + 2)
  Rect("mark", f, x1 + 2, y0 - 2, x1 + t + 2, y1 + 2)
end

local function Zone(kind, n, x0, y0, x1, y1)
  S.zones[#S.zones + 1] = string.format("%s,%d,%d,%d,%d,%d", kind, n, math.floor(x0), math.floor(y0), math.ceil(x1),
    math.ceil(y1))
end

-- the hub's zones to the host's pointer (BattleBayDeluxeTournamentHubZones, cross-menu call)
local function SendZones()
  if S.host ~= nil then
    VRFW.host.command(C.CROSS_CALL, S.host, "BattleBayDeluxeTournamentHubZones", table.concat(S.zones, ";"))
  end
end

-- the side menu
local function DrawNav(v, cur)
  local N = HUB.NAV
  Art("card", "bbd_lg_nav", N.X, N.Y, N.W, N.H)
  local cx = N.X + N.W / 2
  Crest(v.team, cx, N.CREST_Y, N.CREST)
  Txt(Fit(VRFW.team.name(v.team), 16), cx, N.NAME_Y, 0.85, G.ST.pts_me)
  if v.level then
    Txt(TextValue2("hub_level", v.level), cx, N.LEVEL_Y, 1.0, G.ST.label_head)
  end
  Rect("mark", SP.sep, N.X + 20, N.SEP_Y - 1, N.X + N.W - 20, N.SEP_Y + 1)
  for k, it in ipairs(HUB_NAV) do
    local y = N.ITEM_Y + (k - 1) * N.ITEM_PITCH
    local yc = y + N.ITEM_H / 2
    local on = cur == k - 1
    if on then
      QuadA("band", LG.PLATE_ATLAS_PATH, "list_base_xs01_on", N.ITEM_X + N.ITEM_W / 2, yc, N.ITEM_W, N.ITEM_H)
      QuadA("band", LG.PLATE_ATLAS_PATH, "list_base_xs01_ol", N.ITEM_X + N.ITEM_W / 2, yc, N.ITEM_W, N.ITEM_H)
    end
    Icon(it.icon, N.ICON_X, yc, N.ICON)
    TxtLeft(Text(it.key), N.LABEL_X, yc, on and 0.9 or 0.85, G.ST.title)
    Zone("n", k - 1, N.ITEM_X, y, N.ITEM_X + N.ITEM_W, y + N.ITEM_H)
  end
  for k, key in ipairs({ "new_league", "hub_exit" }) do
    local y = N.PILL_Y[k]
    local yc = y + N.PILL_H / 2
    QuadA("card", LG_ART.ATLAS, "bbd_lg_pill", cx, yc, N.PILL_W + 4, N.PILL_H + 4)
    local on = cur == #HUB_NAV + k - 1
    if on then
      QuadA("band", LG.PLATE_ATLAS_PATH, "list_base_xs01_on", cx, yc, N.PILL_W, N.PILL_H)
      QuadA("band", LG.PLATE_ATLAS_PATH, "list_base_xs01_ol", cx, yc, N.PILL_W, N.PILL_H)
    end
    Txt(Text(key), cx, yc, on and 0.85 or 0.8, G.ST.pts_me)
    Zone("n", #HUB_NAV + k - 1, cx - N.PILL_W / 2, y, cx + N.PILL_W / 2, y + N.PILL_H)
  end
end

local function DrawHeader(v)
  local H = HUB.HEAD
  Art("card", "bbd_lg_head", H.X, H.Y, H.W, H.H)
  TxtLeft(Text("hub_title"), H.X + 30, H.Y + 26, 1.0, G.ST.title)
  local md = v.fixture and v.fixture.md or v.mds
  TxtLeft(TextValue2("league_md_of", md or 0, v.mds or 0) .. "  ·  " .. TextValue2("hub_teams", v.size or 0),
    H.X + 30, H.Y + 58, 0.8, G.ST.legend)
  local mds = math.max(1, v.mds or 1)
  local played = math.max(0, math.min(mds, v.played or 0))
  QuadA("band", LG_ART.ATLAS, "bbd_lg_bar_base", (H.BAR_X0 + H.BAR_X1) / 2, H.BAR_Y + H.BAR_H / 2, H.BAR_X1 - H.BAR_X0 + 8,
    H.BAR_H + 8)
  local inner = H.BAR_X1 - H.BAR_X0
  if played > 0 then
    local w = inner * played / mds
    QuadA("band", LG_ART.ATLAS, "bbd_lg_bar_fill", H.BAR_X0 + w / 2, H.BAR_Y + H.BAR_H / 2, w, H.BAR_H)
  end
  if mds <= 40 then
    for k = 1, mds - 1 do
      local x = H.BAR_X0 + inner * k / mds
      Rect("mark", SP.sep, x - 1, H.BAR_Y, x + 1, H.BAR_Y + H.BAR_H)
    end
  end
  Txt(TextValue2("hub_played", played), H.BAR_X0 + 70, H.LABEL_Y, 0.85, G.ST.label_head)
  Txt(TextValue2("hub_left", mds - played), H.BAR_X1 - 70, H.LABEL_Y, 0.85, G.ST.label_head)
  -- no points / place badge / Battle Bay logo here (the standings card shows them)
end

-- the next match
local function DrawHero(v, focus)
  local P = HUB.HERO
  local x0, y0, x1 = P.X, P.Y, P.X + P.W
  BigCard("hero", x0, y0, P.W, P.H)
  BandTitle(x0 + 8, y0, P.head, "quest01", Text("hub_next"))
  local f = v.fixture
  local cx = (x0 + x1) / 2
  if not f then
    Txt(Text("league_over"), cx, y0 + P.H / 2 + 20, 1.0, G.ST.num)
    return
  end
  BandRight(x1, y0, P.head, TextValue2("hub_md_short", f.md) .. "  ·  " .. Text(f.home.me and "hub_home" or "hub_away"))
  local s = P.PLATE_S
  local pw = LG.PLATE_W * s
  local sp = LeagueSprites()
  for side, r in ipairs({ f.home, f.away }) do
    local ccx = side == 1 and (x0 + P.CREST_DX) or (x1 - P.CREST_DX)
    Crest(r.team, ccx, P.CREST_Y, P.CREST)
    local px = side == 1 and (x0 + 30) or (x1 - 30 - pw)
    if r.me then
      Quad("mark", sp.frame, px + pw / 2, P.PLATE_Y, pw * LG.FRAME_W, G.PLATE_H * s * LG.FRAME_H)
    end
    Plate(r, px, P.PLATE_Y, s, (LG.PLATE_W - G.NAME_L - LG.name_pad) * s)
    if (r.pos or 0) > 0 then
      Txt(TextValue2("hub_place", r.pos, r.pts or 0), px + pw / 2, P.INFO_Y, 0.85, G.ST.num)
    end
  end
  Txt(Text("hub_vs"), cx, P.CREST_Y, 1.6, G.ST.pts)
  local by = P.BTN_Y + P.BTN_H / 2
  local step = (P.BTN_W + P.BTN_GAP) / 2
  QuadA("mark", HUB_ATLAS.button, focus == 1 and "cmd_btn_base01_on" or "cmd_btn_base01_off", cx - step, by, P.BTN_W, P.BTN_H)
  Txt(Text("key_play") .. " " .. Text("hub_play"), cx - step, by, 0.95, G.ST.pts_me)
  S.play_zone = { cx - step - P.BTN_W / 2, P.BTN_Y, cx - step + P.BTN_W / 2, P.BTN_Y + P.BTN_H }
  QuadA("mark", HUB_ATLAS.button, "cmd_btn_base01_off", cx + step, by, P.BTN_W, P.BTN_H)
  Txt(Text("key_sim") .. " " .. Text("hub_sim"), cx + step, by, 0.95, G.ST.pts_me)
  S.sim_zone = { cx + step - P.BTN_W / 2, P.BTN_Y, cx + step + P.BTN_W / 2, P.BTN_Y + P.BTN_H }
end

local function DrawStandings(v)
  local P = HUB.STAND
  local x0, y0, x1 = P.X, P.Y, P.X + P.W
  BigCard("stand", x0, y0, P.W, P.H)
  BandTitle(x0 + 8, y0, P.head, "vroad01", Text("hub_standings"))
  local cols = { { "pj", x1 - 196 }, { "dg", x1 - 124 }, { "pts", x1 - 56 } }
  TxtLeft(Text("col_team"), x0 + 116, P.LABEL_Y, 0.9, G.ST.label_l)
  for _, c in ipairs(cols) do
    Txt(Text("col_" .. c[1]), c[2], P.LABEL_Y, 0.9, c[1] == "pts" and G.ST.label_pts or G.ST.label)
  end
  local y = P.TOP
  for _, r in ipairs(v.top or {}) do
    if r.gap then
      Txt("…", (x0 + x1) / 2, y + P.GAP / 2, 0.9, G.ST.num_dim)
      y = y + P.GAP
    end
    local yc = y + P.PITCH / 2
    if r.me then
      Rect("mark", SP.me, x0 + 22, y + 2, x1 - 30, y + P.PITCH - 2)
    else
      Rect("mark", SP.sep, x0 + 30, y + P.PITCH - 1, x1 - 30, y + P.PITCH + 1)
    end
    if r.pos == 1 then
      Rect("mark", SP.qual, x0 + 22, y + 2, x0 + 22 + G.QBAR, y + P.PITCH - 2)
    end
    Txt(tostring(r.pos or 0), x0 + 48, yc, 0.9, r.me and G.ST.num_me or G.ST.num)
    Crest(r.team, x0 + 92, yc, P.CREST)
    local name = Fit(VRFW.team.name(r.team), 26)
    if r.me then
      TxtLeft(name, x0 + 116, yc, 0.72, G.ST.title)
    else
      TxtLeft(name, x0 + 116, yc, 1.05, G.ST.label_l)
    end
    local vals = { pj = tostring(r.pj or 0), dg = GoalDifference(r.dg), pts = tostring(r.pts or 0) }
    for _, c in ipairs(cols) do
      local st = r.me and G.ST.num_me or (c[1] == "pts" and G.ST.num or G.ST.num_dim)
      Txt(vals[c[1]], c[2], yc, c[1] == "pts" and 0.95 or 0.85, st)
    end
    y = y + P.PITCH
  end
end

local function Face(card, x, y, px)
  if (card or 0) == 0 or VRFW.face_icon == nil then
    return
  end
  local i = Take("face")
  if i == nil then
    return
  end
  funcLuaMenuCommand(C.VISIBLE, L.face, i, true)
  VRFW.face_icon.card(L.face, i, { card = card }, x, y, px, { use_args = true })
end

local function DrawScorersPanel(v, x0)
  local P = HUB.PANEL
  local y0, x1 = P.Y, x0 + P.W
  BigCard("panel", x0, y0, P.W, P.H)
  BandTitle(x0 + 8, y0, P.head, "help01", Text("scorers_title"))
  local rows = v.scorers or {}
  if #rows == 0 then
    Txt(Text("scorers_none"), (x0 + x1) / 2, y0 + P.head + (P.H - P.head) / 2, 0.85, G.ST.num_dim)
    return
  end
  local pitch = (P.H - P.head - 12) / 3
  for k, r in ipairs(rows) do
    local y = y0 + P.head + 6 + (k - 1) * pitch
    local yc = y + pitch / 2
    Txt(tostring(r.pos or k), x0 + 40, yc, 0.95, G.ST.num)
    -- the player's miniface, the team's crest to its right, the name on one line after them
    local fp, cp = pitch * 0.9, pitch * 0.6
    Face(r.card, x0 + 66 + fp / 2, yc, fp)
    local cx = x0 + 66 + fp + 8 + cp / 2
    Crest(r.team, cx, yc, cp)
    TxtLeft(Fit(CharaName(r.card), 20), cx + cp / 2 + 12, yc, 1.1, G.ST.label_l)
    Rect("mark", r.me and SP.pts_me or SP.pts, x1 - 96, y + 6, x1 - 40, y + pitch - 6)
    Txt(tostring(r.goals or 0), x1 - 68, yc, 0.95, r.me and G.ST.pts_me or G.ST.pts)
    if k < #rows then
      Rect("mark", SP.sep, x0 + 30, y + pitch - 1, x1 - 30, y + pitch + 1)
    end
  end
end

local function DrawResultsPanel(v, x0)
  local P = HUB.PANEL
  local y0, x1 = P.Y, x0 + P.W
  BigCard("panel", x0, y0, P.W, P.H)
  BandTitle(x0 + 8, y0, P.head, "history01", Text("hub_results"))
  local res = v.results or {}
  local fy = y0 + P.head + 26
  TxtLeft(Text("col_form"), x0 + 34, fy, 0.9, G.ST.label_l)
  local form = tostring(v.form or "")
  for f = 1, LG.form do
    local spr = SP[form:sub(f, f)] or SP.none
    Quad("mark", spr, x0 + 150 + (f - 1) * 38, fy, 28, 28)
  end
  if #res == 0 then
    Txt(Text("hub_no_results"), (x0 + x1) / 2, fy + 70, 0.85, G.ST.num_dim)
    return
  end
  local pitch = 40
  local y = fy + 22
  for k = #res, math.max(1, #res - 2), -1 do
    local r = res[k]
    local yc = y + pitch / 2
    Txt(TextValue2("hub_md_short", r.md or 0), x0 + 46, yc, 0.8, G.ST.num_dim)
    Txt(Text(r.home and "hub_home_short" or "hub_away_short"), x0 + 92, yc, 0.8, G.ST.num_dim)
    Crest(r.team, x0 + 134, yc, 30)
    TxtLeft(Fit(VRFW.team.name(r.team), 18), x0 + 158, yc, 1.0, G.ST.label_l)
    Rect("mark", SP.pts_me, x1 - 150, y + 6, x1 - 76, y + pitch - 6)
    Txt(string.format("%d - %d", r.gf or 0, r.ga or 0), x1 - 113, yc, 0.85, G.ST.num_me)
    Quad("mark", SP[r.r] or SP.none, x1 - 50, yc, 24, 24)
    y = y + pitch
  end
end

local function DrawSquadPanel(v, x0)
  local P = HUB.PANEL
  local y0, x1 = P.Y, x0 + P.W
  BigCard("panel", x0, y0, P.W, P.H)
  BandTitle(x0 + 8, y0, P.head, "uniform01", Text("hub_roster"))
  local by = y0 + P.head
  Crest(v.team, x0 + 92, by + (P.H - P.head) / 2, 112)
  local tx = x0 + 172
  TxtLeft(Fit(VRFW.team.name(v.team), 22), tx, by + 34, 1.2, G.ST.label_l)
  if v.level then
    TxtLeft(TextValue2("hub_level", v.level), tx, by + 72, 1.0, G.ST.label_l)
  end
  if v.my_scorer then
    TxtLeft(Text("hub_team_scorer"), tx, by + 108, 0.85, G.ST.label_l)
    TxtLeft(Fit(CharaName(v.my_scorer.card), 20) .. "  ·  " .. TextValue2("hub_goals", v.my_scorer.goals or 0), tx,
      by + 136, 1.0, G.ST.label_l)
  end
end

local function FixtureCard(team, r, x, y)
  local P = HUB.CAL
  Art("band", r.next and "bbd_lg_fix_next" or "bbd_lg_fix", x, y, P.FIX_W, P.FIX_H)
  local by = y + P.FIX_BAND / 2
  TxtLeft(TextValue2("calendar_md_short", r.md or 0), x + 18, by, 0.62, G.ST.title)
  if r.none then
    return
  end
  Txt(Text(r.home and "hub_home" or "hub_away"), x + P.FIX_W - 112, by, 0.8, G.ST.label_head)
  local cx, cy = x + P.FIX_W / 2, y + P.FIX_BAND + 42
  local left, right = r.home and team or r.team, r.home and r.team or team
  local dx = r.done and 86 or 62
  Crest(left, cx - dx, cy, 54)
  Crest(right, cx + dx, cy, 54)
  if r.done then
    local gf, ga = r.gf or 0, r.ga or 0
    local hs, as = r.home and gf or ga, r.home and ga or gf
    Rect("mark", SP.pts_me, cx - 40, cy - 16, cx + 40, cy + 16)
    Txt(string.format("%d - %d", hs, as), cx, cy, 0.85, G.ST.num_me)
    Quad("mark", SP[r.r] or SP.none, x + P.FIX_W - 22, by, 20, 20)
  else
    Txt(Text("hub_vs"), cx, cy, 0.9, G.ST.pts)
  end
  Txt(Fit(VRFW.team.name(r.team), 22), cx, y + P.FIX_H - 22, 0.95, G.ST.label)
end

local function DrawCalendar(v)
  local P = HUB.CAL
  local x0, y0, x1 = P.X, P.Y, P.X + P.W
  BigCard("cal", x0, y0, P.W, P.H)
  BandTitle(x0 + 8, y0, P.head, "history01", Text("hub_calendar"))
  local fx = v.fixtures or {}
  if #fx == 0 then
    Txt(Text("league_over"), (x0 + x1) / 2, y0 + P.head + (P.H - P.head) / 2, 1.0, G.ST.num)
    return
  end
  local fy = y0 + P.head + 12
  for k, r in ipairs(fx) do
    local x = x0 + P.PAD + (k - 1) * (P.FIX_W + P.GAP)
    FixtureCard(v.team, r, x, fy)
    S.cal_zones[#S.cal_zones + 1] = { x, fy, x + P.FIX_W, fy + P.FIX_H }
  end
end

local function DrawFixtures(v)
  S.groups, S.mode = 0, ""
  S.zones = {}
  local P = HUB.CAL
  local cards = v.cards or {}
  local cols = math.max(1, math.min(v.cols or #cards, #cards))
  local rows = math.ceil(#cards / cols)
  local gw = cols * P.FIX_W + (cols - 1) * P.GAP
  local gh = rows * P.FIX_H + (rows - 1) * P.GAP
  local x0, y0 = (G.W - gw) / 2, (G.Y0 + G.Y1) / 2 - gh / 2
  local focus = ParamInt(P_CAL_MD)
  for k, r in ipairs(cards) do
    local x = x0 + ((k - 1) % cols) * (P.FIX_W + P.GAP)
    local y = y0 + math.floor((k - 1) / cols) * (P.FIX_H + P.GAP)
    FixtureCard(v.team, r, x, y)
    if r.md == focus then
      FocusFrame(x, y, x + P.FIX_W, y + P.FIX_H)
    end
    Zone("c", r.md, x, y, x + P.FIX_W, y + P.FIX_H)
  end
  SendZones()
  S.groups = #cards
  S.mode = string.format("matchday grid: %d cards, page %d of %d, focus %d", #cards, v.page_n or 1, v.page_count or 1,
    focus)
end

local function DrawHub(v)
  S.groups, S.mode = 0, ""
  S.zones, S.play_zone, S.sim_zone, S.cal_zones = {}, nil, nil, {}
  local cur = NavCursor()
  local focus = FocusPanel()
  DrawNav(v, cur)
  DrawHeader(v)
  DrawHero(v, focus)
  DrawStandings(v)
  DrawScorersPanel(v, HUB.PANEL.XS[1])
  DrawResultsPanel(v, HUB.PANEL.XS[2])
  DrawSquadPanel(v, HUB.PANEL.XS[3])
  DrawCalendar(v)
  local boxes = {
    { HUB.HERO.X, HUB.HERO.Y, HUB.HERO.X + HUB.HERO.W, HUB.HERO.Y + HUB.HERO.H },
    { HUB.STAND.X, HUB.STAND.Y, HUB.STAND.X + HUB.STAND.W, HUB.STAND.Y + HUB.STAND.H },
  }
  for k = 1, 3 do
    local x = HUB.PANEL.XS[k]
    boxes[#boxes + 1] = { x, HUB.PANEL.Y, x + HUB.PANEL.W, HUB.PANEL.Y + HUB.PANEL.H }
  end
  boxes[#boxes + 1] = { HUB.CAL.X, HUB.CAL.Y, HUB.CAL.X + HUB.CAL.W, HUB.CAL.Y + HUB.CAL.H }
  local b = boxes[focus]
  if b then
    FocusFrame(b[1], b[2], b[3], b[4])
  end
  for k, box in ipairs(boxes) do
    Zone("p", k, box[1], box[2], box[3], box[4])
  end
  if S.play_zone then
    local z = S.play_zone
    Zone("p", 1, z[1], z[2], z[3], z[4])
  end
  if S.sim_zone then
    local z = S.sim_zone
    Zone("s", 0, z[1], z[2], z[3], z[4])
  end
  for _, c in ipairs(S.cal_zones) do
    Zone("p", #boxes, c[1], c[2], c[3], c[4])
  end
  SendZones()
  S.groups = #(v.top or {})
  S.mode = string.format("hub dashboard: matchday %s of %d, side menu %d, panel %d",
    tostring(v.fixture and v.fixture.md or "-"), v.mds or 0, cur, focus)
end

local function DrawScorers(v)
  local rows = v.rows or {}
  S.groups, S.mode = 0, ""
  local R = math.max(#rows, tonumber(v.page_rows) or #rows, 1)
  local w = math.min(LG.W_MAX, G.W - 2 * G.MX)
  local x = (G.W - w) / 2
  local pitch = math.min(LG.pitch_max, (G.Y1 - G.Y0 - LG.head - LG.labels - 2 * G.PAD) / R)
  local h = LG.head + LG.labels + 2 * G.PAD + R * pitch
  local y = (G.Y0 + G.Y1) / 2 - h / 2
  local sk = BigCard("table", x, y, w, h)
  CardTitle("table", x, y, w, h, LG.head, Text("scorers_title"), HUB.title_s)
  local xl = x + sk + 3
  local xr = x + w - sk - 3
  local ptsx = xr - LG.pad_r - LG.ptsw / 2
  local pos_x = xl + G.QBAR + LG.pos_w / 2
  local name_x = xl + G.QBAR + LG.pos_w + 10
  local s = math.min(LG.s_max, pitch * G.FILL / G.PLATE_H)
  local plate_x = name_x + SCORERS.name_w + SCORERS.gap
  local hb = y + LG.head
  local ly = hb + LG.labels / 2
  TxtLeft(Text("col_player"), name_x, ly, LG.label_s, G.ST.label_l)
  TxtLeft(Text("col_team"), plate_x + G.NAME_L * s, ly, LG.label_s, G.ST.label_l)
  Txt(Text("col_goals"), ptsx, ly, LG.label_s, G.ST.label_pts)
  if #rows == 0 then
    Txt(Text("scorers_none"), x + w / 2, hb + LG.labels + G.PAD + pitch, LG.num_s, G.ST.num)
  end
  local top = hb + LG.labels + G.PAD
  local sp = LeagueSprites()
  local name_px = math.min((LG.PLATE_W - G.NAME_L - LG.name_pad) * s, ptsx - LG.ptsw / 2 - 20 - plate_x - G.NAME_L * s)
  for k, r in ipairs(rows) do
    local ry = top + (k - 1) * pitch
    local yc = ry + pitch / 2
    if k < #rows then
      Rect("mark", SP.sep, xl + G.QBAR + 4, ry + pitch - G.SEP / 2, xr, ry + pitch + G.SEP / 2)
    end
    if (r.pos or k) == 1 then
      Rect("mark", SP.qual, xl, ry + 1, xl + G.QBAR, ry + pitch - 1)
    end
    Rect("mark", r.me and SP.pts_me or SP.pts, ptsx - LG.ptsw / 2, ry + 2, ptsx + LG.ptsw / 2, ry + pitch - 2)
    Txt(tostring(r.pos or k), pos_x, yc, LG.num_s, G.ST.num)
    local fp = pitch * 0.9
    Face(r.card, name_x + fp / 2, yc, fp)
    local nx = name_x + fp + 8
    TxtLeft(Fit(CharaName(r.card), math.floor((SCORERS.name_w - fp - 8) / (SCORERS.name_px * SCORERS.name_s * G.NAME_CHAR))), nx, yc,
      SCORERS.name_s, G.ST.label_l)
    if r.me then
      local pw = LG.PLATE_W * s
      Quad("mark", sp.frame, plate_x + pw / 2, yc, pw * LG.FRAME_W, G.PLATE_H * s * LG.FRAME_H)
    end
    Plate(r, plate_x, yc, s, name_px)
    Txt(tostring(r.goals or 0), ptsx, yc, LG.pts_s, r.me and G.ST.pts_me or G.ST.pts)
    S.groups = S.groups + 1
  end
  S.mode = string.format("scorers, %d rows", #rows)
end

local SQUAD = { W = 1320, H = 800, head = 50, PAD = 24, PITCH = 52, CREST = 34, COL_GAP = 40 }
local POS_TEXT = { [1] = 1006946191, [2] = 2769131061, [3] = 3523913379, [4] = 1282290432 }   -- battlebaydeluxe_pos_1..4

local function RawText(id)
  local t = VRFW.host.command(C.TEXT_GET, id)
  return type(t) == "string" and t or ""
end

local function DrawSquad(v)
  S.groups, S.mode = 0, ""
  local x = (G.W - SQUAD.W) / 2
  local y = (G.Y0 + G.Y1) / 2 - SQUAD.H / 2
  local sk = BigCard("table", x, y, SQUAD.W, SQUAD.H)
  Crest(v.team, x + sk + 46, y + SQUAD.head / 2, SQUAD.CREST)
  local head = Fit(VRFW.team.name(v.team), 30)
  if v.level then
    head = head .. "  ·  " .. TextValue2("hub_level", v.level)
  end
  TxtLeft(head, x + sk + 76, y + SQUAD.head / 2, HUB.title_s, G.ST.title)
  local rows = v.rows or {}
  if #rows == 0 then
    Txt(Text("squad_none"), x + SQUAD.W / 2, y + SQUAD.H / 2, 1.0, G.ST.num)
    S.mode = "squad: no members"
    return
  end
  local colw = (SQUAD.W - 2 * sk - 2 * SQUAD.PAD - SQUAD.COL_GAP) / 2
  local top = y + SQUAD.head + 16
  local cols = { { key = "squad_starters", x = x + sk + SQUAD.PAD, n = 0 },
                 { key = "squad_subs", x = x + sk + SQUAD.PAD + colw + SQUAD.COL_GAP, n = 0 } }
  for _, c in ipairs(cols) do
    TxtLeft(Text(c.key), c.x + 8, top + 14, 0.95, G.ST.label_l)
  end
  for _, r in ipairs(rows) do
    local c = cols[(r.slot or 0) < 11 and 1 or 2]
    local ry = top + 34 + c.n * SQUAD.PITCH
    local yc = ry + SQUAD.PITCH / 2
    if ry + SQUAD.PITCH <= y + SQUAD.H - 10 then
      Rect("mark", SP.sep, c.x, ry + SQUAD.PITCH - 1, c.x + colw, ry + SQUAD.PITCH + 1)
      Rect("mark", SP.pts, c.x, ry + 6, c.x + 52, ry + SQUAD.PITCH - 6)
      Txt(tostring((r.slot or 0) + 1), c.x + 26, yc, 0.9, G.ST.num)
      local pos = POS_TEXT[r.pos or 0]
      if pos then
        Txt(RawText(pos), c.x + 150, yc, 0.9, G.ST.num_dim)
      end
      TxtLeft(Fit(CharaName(r.card), 26), c.x + 250, yc, 1.1, G.ST.label_l)
      S.groups = S.groups + 1
    end
    c.n = c.n + 1
  end
  S.mode = string.format("squad: %d members", #rows)
end

local function SetupText()
  local parts, short = {}, 0
  for k, n in pairs(N) do
    local got = S.per[L[k]] or 0
    if got < n then
      short = short + 1
    end
    parts[#parts + 1] = string.format("%s %d/%d", k, got, n)
  end
  table.sort(parts)
  return table.concat(parts, ", "), short
end

local function Draw()
  local v = VRFW.host.command(CMD_VIEW, S.page or -1)
  if type(v) ~= "table" then
    return false
  end
  S.used, S.miss = {}, {}
  local okd, err = pcall(function()
    if v.kind == "groups" then
      DrawGroups(v)
    elseif v.kind == "league" then
      DrawLeague(v)
    elseif v.kind == "hub" then
      DrawHub(v)
    elseif v.kind == "scorers" then
      DrawScorers(v)
    elseif v.kind == "squad" then
      DrawSquad(v)
    elseif v.kind == "fixtures" then
      DrawFixtures(v)
    end
  end)
  if not okd then
    Log("groups menu: draw error", tostring(err))
  end
  for k, l in pairs(L) do
    for i = S.used[k] or 0, N[k] - 1 do
      Hide(l, i)
      if l == L.face and VRFW.face_icon ~= nil then
        VRFW.face_icon.forget(l, i)
      end
    end
  end
  S.drawn = true
  if not S.logged then
    S.logged = true
    local setup, short = SetupText()
    local used, miss = {}, {}
    for k, _ in pairs(N) do
      used[#used + 1] = string.format("%s %d", k, S.used[k] or 0)
      if (S.miss[k] or 0) > 0 then
        miss[#miss + 1] = string.format("%s %d", k, S.miss[k])
      end
    end
    table.sort(used)
    table.sort(miss)
    Log(string.format("groups menu open (host %s, page %s, kind %s): instances requested %d, set up %d/%d after %d "
      .. "frames [%s]%s; groups drawn %d of %d (%s); pieces used [%s]%s", VRFW.ids.hex_text(S.host), tostring(S.page),
      tostring(v.kind), S.need, S.got, S.need, S.frame, setup, short > 0 and " SHORT" or "", S.groups,
      #(v.groups or v.standings or v.rows or {}), S.mode, table.concat(used, ", "),
      #miss > 0 and ("; NOT DRAWN (pool full): " .. table.concat(miss, ", ")) or ""))
  end
  return true
end

-- every instance of every pool hidden (nothing of the tables left on screen)
local function HideAll()
  for k, l in pairs(L) do
    for i = 0, N[k] - 1 do
      pcall(Hide, l, i)
    end
  end
  if VRFW.face_icon ~= nil then
    VRFW.face_icon.forget(L.face)
  end
  S.used = {}
end

local function OnClose()
  S.want, S.drawn = false, false
  HideAll()
end

local function OnRedraw(page)
  S.page = page
  S.host = Handshake.host()
  S.want = true
end

-- The instances the engine created of each pool (the [[screen]] rows) and their sum, the instances to wait for.
local function ReadCounts()
  S.need = 0
  for k, l in pairs(L) do
    local n = funcLuaMenuCommand(C.LAYER_NUM, l)
    N[k] = type(n) == "number" and n or 0
    S.need = S.need + N[k]
  end
end

function OnInit()
  Handshake = VRFW.child_menu.child(MENU, { prefix = "battlebaydeluxe_tn_groups_", on_redraw = OnRedraw, on_close = OnClose,
    log = function(...) Log("groups menu:", ...) end })
  S.page, S.host = Handshake.init()
  S.need, S.got, S.per, S.seen, S.frame = 0, 0, {}, {}, 0
  S.drawn, S.logged, S.want, S.stuck, S.emb, S.strip = false, false, true, false, {}, {}
  if VRFW.face_icon ~= nil then
    VRFW.face_icon.forget(L.face)
  end
  ReadCounts()
end

function OnSetupLayer(a1, a2)
  if KEY_OF[a1] == nil then
    return
  end
  if (a2 or 0) >= (N[KEY_OF[a1]] or 0) then
    ReadCounts()
  end
  Hide(a1, a2 or 0)
  local k = tostring(a1) .. ":" .. tostring(a2)
  if not S.seen[k] then
    S.seen[k] = true
    S.got = S.got + 1
    S.per[a1] = (S.per[a1] or 0) + 1
  end
  if a1 == L.row then
    VRFW.team.emblem_forget(a1, a2 or 0, S.emb)
    S.strip[a2 or 0] = nil
  end
  if a1 == L.face and VRFW.face_icon ~= nil then
    VRFW.face_icon.forget(a1, a2 or 0)
  end
  if S.drawn then
    S.want = true
  end
end

function OnOpenLayer(a1, a2)
end

function Step()
  S.frame = S.frame + 1
  if Handshake.step() then
    return   -- closing
  end
  -- draw once every instance is set up (or after STUCK_FRAMES with what there is)
  if S.want and (S.got >= S.need or S.frame >= 120) then
    if S.got < S.need and not S.stuck then
      S.stuck = true
      Log("groups menu: STUCK? only", S.got, "of", S.need, "instances set up after", S.frame, "frames: drawn anyway")
    end
    if Draw() then
      S.want = false
    end
  end
end

function FinalizeMenu()
  if Handshake then
    Handshake.finalize()
  end
end
