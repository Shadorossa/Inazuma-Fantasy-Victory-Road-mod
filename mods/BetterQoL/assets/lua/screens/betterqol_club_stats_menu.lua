INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_PROG_COMMON")

local CMD = { CLUB = 1223180080 --[[CMND_BETTERQOL_CLUB_STATS]], ROW = 1849706465 --[[CMND_BETTERQOL_CLUB_STATS_ROW]],
  HISTORY_ROW = 2360975261 --[[CMND_BETTERQOL_CLUB_HISTORY_ROW]] }
local C = {
  TEXT_GET = 4074371074, LANG = 477234096, SND = 3073642526, POS = 1389957207, SCALE = 3778714801,
  SPRITE = 558735651, ALPHA = 4231609516, MESH_VISIBLE = 3405944500, SET_TEXT = 1083631230, LOAD_TEX = 839427544,
  TEX_LOADING = 1506186496,
}
-- the page's layers (content\menus\club_stats.toml)
local L = { BACK = 2827165426, PLATE = 2589306043, ICON = 2698638878, FACE = 3227100322, TEXT = 4274419714 }
local L_LINE = 3078308064          -- mainmenu90_05_content_guide_line01
local LINE_TEXT = 378156699        -- _text_guide01
-- the anchor's functions (crc32 of the cmd row names)
local FN = { UP = 3317173220, DOWN = 3652341758, TAB_PREV = 1807731998, TAB_NEXT = 3547485559, SORT = 2489920999 }
local QUAD = 1909474081            -- icon_new01: the cmn01_10 quad's sprite slot
local Q = 36                       -- the cmn01_10 quad side
local SY_MOVE, SY_ERROR = 2500047763, 2086672038
local BOB, GLYPH = 30, 0.5
local STYLE = {
  section = "fs_26_w_lc_2d0_001", label = "fs_22_k_lc_2d0_001_nr_sclw", value = "fs_32_b_lc_2d0_001",
  name = "fs_28_b_lc_2d0_001", cell = "fs_28_b_lc_2d0_001",
  head = "fs_28_k_lc_2d0_001", dim = "fs_28_k_lc_2d0_001",
}
-- retail text rules: no outline (2d0), white for the open tab and the sort hint, grey for the other tab, headings and the empty line
local TAB_PX, TAB_GLYPH, KEY_W, TAB_GAP = 26, 0.68, 40, 56   -- tab label size, widest glyph share (upper case), key glyph width, space between tabs
local P = { x = 60, width = 1800, top = 84, cell_h = 92, cell_gap = 10, section_h = 40, columns_h = 32, row_h = 56,
  row_gap = 2, rows = 9, face = 56, facebox = 56, band_gap = 10, head_gap = 6, bar_w = 8, bar_gap = 16 }
-- the rows span the tiles' left edge up to the scrollbar, which sits on the tiles' right edge
P.list_w = P.width - P.bar_w - P.bar_gap
local COL = { face = 140, name = 182, matches = 900, goals = 1040, assists = 1180, mvp = 1320, winpct = 1470, signed = 1660 }
-- the match history's columns (centres for number / date / score / result, left edges for the rest)
local HCOL = { number = 130, date = 270, mode = 380, rival = 640, score = 1080, result = 1190, mvp = 1270, scorers = 1530,
  right = 1790 }
local TAB_PLAYERS, TAB_HISTORY = 1, 2
local RESULT_TEXT = { "ResultWin", "ResultDraw", "ResultLoss" }
local SORTS = { "goals", "matches", "assists", "mvp", "winpct", "signed" }
local SORT_TEXT = { goals = "SortGoals", matches = "SortMatches", assists = "SortAssists", mvp = "SortMvp",
  winpct = "SortWinPct", signed = "SortSigned" }
local ART, SPRITE = "#/menu/220_img/betterqol_club_stats/betterqol_club_stats.g4tx", "betterqol_club_stats_"
local RETAIL = {
  list = { tex = "#/menu/51_save/save01/save01_02/save01_02.g4tx",
           off = "list_base_s01_off", on = "list_base_s01_on", focus = "list_base_s01_ol" },
  cursor = { tex = "#/menu/20_cmn/cmn05/cmn05_01/cmn05_01.g4tx", sprite = "cur01", w = 128, h = 152 },
}

local S = { ready = false, art_ok = false, frame = 0, ok = false, club = nil, rows = {}, sel = 1, top = 1, sort = 1,
  texts = {}, loaded = {}, faces = {}, dirty = true, tab = TAB_PLAYERS, hist = {}, hsel = 1, htop = 1 }

local Page, Log, M

local function Bind()
  if Page ~= nil then return end
  Page = BetterQoL.page
  Log, M = Page.logger("BetterQoL club_stats"), VRFW.host.menu_command
end

local function Crc(text)
  return VRFW.ids.crc32(text)
end

local function Tx(name)
  return Page.tx(S.texts, "BetterQoL.ClubStats.", name)
end

local function Fill(s, v)
  return (tostring(s):gsub("{1}", function() return tostring(v) end))
end

local function Snd(s) VRFW.host.command(C.SND, s) end

local function Day(d)
  d = tonumber(d) or 0
  if d <= 0 then return Tx("Unknown") end
  local fmt = S.texts["@date"]
  if fmt == nil then
    local s = VRFW.host.command(C.TEXT_GET, Crc("BetterQoL.cs_date"))
    fmt = (type(s) == "string" and s:find("{d}", 1, true)) and s or "{d}/{m}/{yy}"
    S.texts["@date"] = fmt
  end
  local y, m, dd = math.floor(d / 10000), math.floor(d / 100) % 100, d % 100
  return (fmt:gsub("{d}", string.format("%02d", dd)):gsub("{m}", string.format("%02d", m))
    :gsub("{yy}", string.format("%02d", y % 100)))
end

-- the game mode's name (the career page's mode rows)
local function ModeName(mode)
  local key = "@mode_" .. mode
  if S.texts[key] == nil then
    local s = VRFW.host.command(C.TEXT_GET, Crc("BetterQoL.cs_mode_" .. mode))
    S.texts[key] = type(s) == "string" and s or mode
  end
  return S.texts[key]
end

local function Pct(w, m)
  if (m or 0) <= 0 then return "-" end
  return tostring(math.floor(w * 100 / m + 0.5)) .. "%"
end

local Kit   -- VRFW.screen_kit.new in OnInit (only what changed is sent)

local function Quad(layer, tex, sprite, x, y, w, h, alpha)
  local i = Kit.slot(layer)
  if i == nil then return nil end
  Kit.show(layer, i)
  Kit.set(layer, i, "sc", C.SCALE, layer, w / Q, h / Q, 1, i)
  Kit.set(layer, i, "sp", C.SPRITE, layer, Crc(tex), Crc(sprite), QUAD, 0, i)
  Kit.set(layer, i, "pos", C.POS, layer, x + w / 2, -(y + h / 2), 0, i)
  Kit.set(layer, i, "a", C.ALPHA, layer, i, 0, alpha or 1)
  return i
end

local function Art(layer, name, x, y, w, h, alpha)
  return Quad(layer, ART, SPRITE .. name, x, y, w, h, alpha)
end

local function TexReady(tex)
  if S.loaded[tex] == nil then
    VRFW.host.menu_command(C.LOAD_TEX, tex)   -- CMND_LOAD_MENU_RES_TEXTURE is a menu command
    S.loaded[tex] = true
  end
  local loading = VRFW.host.command(C.TEX_LOADING, Crc(tex))
  return loading == false
end

local FALLBACK = { off = "row", on = "sel", focus = "focus" }
local function Plate(layer, look, x, y, w, h)
  local R = RETAIL.list
  if TexReady(R.tex) then return Quad(layer, R.tex, R[look], x, y, w, h, 1) end
  return Art(layer, FALLBACK[look], x, y, w, h, 1)
end

local CAP = 24
local function Bar(layer, look, x, y, w, h)
  Art(layer, look .. "_l", x, y, CAP, h, 1)
  Art(layer, look .. "_m", x + CAP, y, w - 2 * CAP, h, 1)
  Art(layer, look .. "_r", x + w - CAP, y, CAP, h, 1)
end

local function Cursor(x, y, h)
  local R = RETAIL.cursor
  local w = h * R.w / R.h
  local bob = math.floor(3 * math.sin(S.frame * 2 * math.pi / BOB) + 0.5)
  if TexReady(R.tex) then return Quad(L.ICON, R.tex, R.sprite, x - w + bob, y - h / 2, w, h, 1) end
  return Art(L.ICON, "cursor", x - w + bob, y - h / 2, w, h, 1)
end

local function Text(s, x, y, style, sc)
  return Page.text(Kit, L.TEXT, STYLE[style] or STYLE.cell, s, x, y, sc)
end

local function Units(s) return VRFW.text_fold.units(s) end

-- a text centred on cx (its width estimated from the glyph size `px` of the style at scale 1)
local function TextC(s, cx, y, style, px, sc, glyph)
  sc = sc or 1
  local w = Units(s) * px * sc * (glyph or GLYPH)
  return Text(s, cx - w / 2, y, style, sc)
end

local function Fit(s, px, size) return VRFW.text_fold.fit(s, px, size, GLYPH) end

local MINI = { MESH = 478320441 --[[_icon_chr_dmy01]], SLOT = 3237726902 --[[icon_chr_dmy01]], PX = 64, CX = 63,
  TEXT = 1704438437 --[[_text_name01]], TEXT_VISIBLE = 1505208242, PRIM_COLOR = 855211291,
  HIDE = { 4051829508, 2309656400, 2519428701, 3231997250, 1504513272, 782908526, 1042467758 } }
local function Face(key, cx, cy, size)
  if VRFW.face_icon == nil then return end
  local i = Kit.slot(L.FACE)
  if i == nil then return end
  local s = size / MINI.PX
  Kit.show(L.FACE, i)
  Kit.set(L.FACE, i, "sc", C.SCALE, L.FACE, s, s, 1, i)
  Kit.set(L.FACE, i, "pos", C.POS, L.FACE, cx - MINI.CX * s, -cy, 0, i)
  if S.faces[i] ~= key then
    for _, m in ipairs(MINI.HIDE) do M(C.MESH_VISIBLE, L.FACE, m, false, i) end
    M(MINI.TEXT_VISIBLE, L.FACE, MINI.TEXT, false, i)
    M(MINI.PRIM_COLOR, L.FACE, i, MINI.MESH, 1, 1, 1)
    S.faces[i] = key
  end
  VRFW.face_icon.face(L.FACE, i, key, MINI.MESH, MINI.SLOT)
end

local function BeginFrame() Kit.begin() end

local function EndFrame()
  Kit.finish(function(layer, i)
    if layer == L.FACE then
      S.faces[i] = nil
      if VRFW.face_icon ~= nil then VRFW.face_icon.forget(L.FACE, i) end
    end
  end)
end

local function SortRows()
  local key = SORTS[S.sort]
  local function value(r)
    if key == "winpct" then return r.matches > 0 and r.wins / r.matches or -1 end
    return r[key] or 0
  end
  table.sort(S.rows, function(a, b)
    local va, vb = value(a), value(b)
    if va ~= vb then return va > vb end
    if a.goals ~= b.goals then return a.goals > b.goals end
    if a.matches ~= b.matches then return a.matches > b.matches end
    return a.name < b.name
  end)
end

local function Load()
  S.rows, S.club, S.hist = {}, nil, {}
  local lang = VRFW.host.command(C.LANG)
  local r = table.pack(VRFW.host.command(CMD.CLUB, lang or 1))
  S.ok = r[1] == true
  if not S.ok then
    Log("no numbers for this save", tostring(r[1]))
    return
  end
  local v = {}
  for i = 2, r.n do v[#v + 1] = tonumber(r[i]) or 0 end
  S.club = { players = v[1], since = v[2], matches = v[3], wins = v[4], draws = v[5], losses = v[6], gf = v[7],
    ga = v[8], clean = v[9], best_for = v[10], best_against = v[11], best_day = v[12], win_run = v[13],
    unbeaten_run = v[14], store_since = v[15], today = v[16], history = v[17] }
  for i = 1, S.club.players do
    local base, name, m, w, d, l, g, a, mvp, signed = VRFW.host.command(CMD.ROW, i)
    if base == "" or base == nil then break end
    S.rows[#S.rows + 1] = { base = tonumber(base) or 0, name = tostring(name or ""), matches = tonumber(m) or 0,
      wins = tonumber(w) or 0, draws = tonumber(d) or 0, losses = tonumber(l) or 0, goals = tonumber(g) or 0,
      assists = tonumber(a) or 0, mvp = tonumber(mvp) or 0, signed = tonumber(signed) or 0 }
  end
  SortRows()
  for i = 1, S.club.history do
    local number, day, mode, rival, gf, ga, result, mvp, scorers = VRFW.host.command(CMD.HISTORY_ROW, i)
    if number == "" or number == nil then break end
    S.hist[#S.hist + 1] = { number = tonumber(number) or 0, day = tonumber(day) or 0, mode = tostring(mode or ""),
      rival = tostring(rival or ""), gf = tonumber(gf) or 0, ga = tonumber(ga) or 0, result = tonumber(result) or 0,
      mvp = tostring(mvp or ""), scorers = tostring(scorers or "") }
  end
  Log("page opened:", #S.rows, "player(s),", S.club.matches, "club match(es) since", S.club.since, ",", #S.hist,
    "in the history")
end

local function SinceLine()
  local c = S.club
  if not S.ok or c == nil then return Tx("NoSave") end
  if c.matches <= 0 then return Tx("ClubNone") end
  if c.since > 0 then return Fill(Tx("ClubSince"), Day(c.since)) end
  return Tx("ClubTotals")
end

local function DrawTotals(x, y, w)
  local c = S.club
  local cells = {
    { "Matches", tostring(c.matches) },
    { "Record", string.format("%d-%d-%d", c.wins, c.draws, c.losses) },
    { "WinPct", Pct(c.wins, c.matches) },
    { "GoalsFor", tostring(c.gf) },
    { "GoalsAgainst", tostring(c.ga) },
    { "GoalDiff", (c.gf - c.ga > 0 and "+" or "") .. tostring(c.gf - c.ga) },
    { "CleanSheets", tostring(c.clean) },
    { "BestWin", c.best_day > 0 and string.format("%d-%d", c.best_for, c.best_against) or "-" },
    { "WinRun", tostring(c.win_run) },
    { "UnbeatenRun", tostring(c.unbeaten_run) },
  }
  local per_row = 5
  local cw = math.floor((w - (per_row - 1) * P.cell_gap) / per_row)
  for i, cell in ipairs(cells) do
    local col, row = (i - 1) % per_row, math.floor((i - 1) / per_row)
    local cx, cy = x + col * (cw + P.cell_gap), y + row * (P.cell_h + P.cell_gap)
    Plate(L.PLATE, "off", cx, cy, cw, P.cell_h)
    TextC(Fit(Tx(cell[1]), cw - 40, 22), cx + cw / 2, cy + 25, "label", 22)
    TextC(cell[2], cx + cw / 2, cy + 60, "value", 32, 1.15)
  end
  return y + 2 * P.cell_h + P.cell_gap
end

local function DrawRow(r, y, on)
  local px, pw = P.x, P.list_w
  Bar(L.PLATE, "row", px, y, pw, P.row_h)
  if on then
    Bar(L.ICON, "focus", px, y, pw, P.row_h)
    Cursor(px + 8, y + P.row_h / 2, 40)
  end
  local mid = y + P.row_h / 2
  Art(L.ICON, "facebox", COL.face - P.facebox / 2, mid - P.facebox / 2, P.facebox, P.facebox, 1)
  if r.base ~= 0 then Face(r.base, COL.face, mid, P.face) end
  Text(Fit(r.name ~= "" and r.name or "-", COL.matches - COL.name - 90, 28), COL.name, mid, "name")
  TextC(tostring(r.matches), COL.matches, mid, "cell", 28)
  TextC(tostring(r.goals), COL.goals, mid, "cell", 28)
  TextC(tostring(r.assists), COL.assists, mid, "cell", 28)
  TextC(tostring(r.mvp), COL.mvp, mid, "cell", 28)
  TextC(Pct(r.wins, r.matches), COL.winpct, mid, "cell", 28)
  TextC(Day(r.signed), COL.signed, mid, "cell", 28)
end

-- the list the open tab shows: rows, selected index, first visible index
local function List()
  if S.tab == TAB_HISTORY then return S.hist, S.hsel, S.htop end
  return S.rows, S.sel, S.top
end

local function SetList(sel, top)
  if S.tab == TAB_HISTORY then S.hsel, S.htop = sel, top else S.sel, S.top = sel, top end
end

local function DrawScrollbar(x, y0, y1)   -- x = the bar's left edge
  local rows, _, top = List()
  local n, view = #rows, P.rows
  if n <= view then return end
  Art(L.PLATE, "sbar", x, y0, P.bar_w, y1 - y0, 1)
  local h = y1 - y0
  local th = math.max(40, math.floor(h * view / n))
  local ty = y0 + math.floor((h - th) * (top - 1) / (n - view) + 0.5)
  Art(L.ICON, "sthumb", x, ty, P.bar_w, th, 1)
end

local function DrawHistoryRow(r, y, on)
  local px, pw = P.x, P.list_w
  Bar(L.PLATE, "row", px, y, pw, P.row_h)
  if on then
    Bar(L.ICON, "focus", px, y, pw, P.row_h)
    Cursor(px + 8, y + P.row_h / 2, 40)
  end
  local mid = y + P.row_h / 2
  TextC(tostring(r.number), HCOL.number, mid, "cell", 28)
  TextC(Day(r.day), HCOL.date, mid, "cell", 28)
  Text(Fit(ModeName(r.mode), HCOL.rival - HCOL.mode - 20, 28), HCOL.mode, mid, "cell")
  Text(Fit(r.rival ~= "" and r.rival or Tx("Unknown"), HCOL.score - HCOL.rival - 70, 28), HCOL.rival, mid, "name")
  TextC(string.format("%d-%d", r.gf, r.ga), HCOL.score, mid, "cell", 28)
  TextC(Tx(RESULT_TEXT[r.result] or "Unknown"), HCOL.result, mid, "cell", 28)
  Text(Fit(r.mvp ~= "" and r.mvp or Tx("Unknown"), HCOL.scorers - HCOL.mvp - 20, 28), HCOL.mvp, mid, "cell")
  Text(Fit(r.scorers ~= "" and r.scorers or Tx("Unknown"), HCOL.right - HCOL.scorers, 28), HCOL.scorers, mid, "cell")
end

-- the lower section's band: L1 key, the two tab names (the open one white, the other grey), R1 key, evenly spaced; the sort column on the players tab
local function DrawBand(x, y, w)
  Art(L.PLATE, "section_l", x, y, 40, P.section_h, 1)
  Art(L.PLATE, "section_m", x + 40, y, w - 80, P.section_h, 1)
  Art(L.PLATE, "section_r", x + w - 40, y, 40, P.section_h, 1)
  local mid = y + P.section_h / 2 + 1
  local keys = Tx("TabKeys")
  local left, right = keys:match("^(<[^>]+>)") or "", keys:match("(<[^>]+>)$") or ""
  local cx = x + 52
  Text(left, cx, mid, "section")
  cx = cx + KEY_W + 12
  local names = { Fill(Tx("Players"), #S.rows), Fill(Tx("History"), #S.hist) }
  for k, name in ipairs(names) do
    local tw = Units(name) * TAB_PX * TAB_GLYPH
    if k == S.tab then
      Text(name, cx, mid, "section")
    else
      Text(name, cx, mid, "dim", TAB_PX / 28)
    end
    cx = cx + tw + (k == 1 and TAB_GAP or 12)
  end
  Text(right, cx, mid, "section")
  if S.tab == TAB_PLAYERS then
    local sort = Fill(Tx("SortBy"), Tx(SORT_TEXT[SORTS[S.sort]]))
    Text(sort, x + w - 52 - Units(sort) * TAB_PX * TAB_GLYPH, mid, "section")
  end
end

-- the empty-state line: grey, centred in the list area that starts at y
local function EmptyLine(s, cx, y)
  TextC(s, cx, y + (P.rows * (P.row_h + P.row_gap) - P.row_gap) / 2, "dim", 28, 1, 0.56)
end

local function Draw()
  BeginFrame()
  if S.ready and S.art_ok and S.ok and S.club ~= nil then
    local x, w = P.x, P.width
    local y = DrawTotals(x, P.top, w) + P.band_gap
    DrawBand(x, y, w)
    y = y + P.section_h + P.head_gap
    -- column titles
    local cy = y + P.columns_h / 2
    local hs = 0.8
    if S.tab == TAB_HISTORY then
      TextC(Tx("ColNumber"), HCOL.number, cy, "head", 26, hs)
      TextC(Tx("ColDate"), HCOL.date, cy, "head", 26, hs)
      Text(Tx("ColMode"), HCOL.mode, cy, "head", hs)
      Text(Tx("ColRival"), HCOL.rival, cy, "head", hs)
      TextC(Tx("ColScore"), HCOL.score, cy, "head", 26, hs)
      TextC(Tx("ColResult"), HCOL.result, cy, "head", 26, hs)
      Text(Tx("ColMvp"), HCOL.mvp, cy, "head", hs)
      Text(Tx("ColScorers"), HCOL.scorers, cy, "head", hs)
      y = y + P.columns_h + P.head_gap
      local y0 = y
      if #S.hist == 0 then EmptyLine(Tx("HistoryNone"), x + w / 2, y) end
      for k = 0, P.rows - 1 do
        local r = S.hist[S.htop + k]
        if r == nil then break end
        DrawHistoryRow(r, y, S.htop + k == S.hsel)
        y = y + P.row_h + P.row_gap
      end
      DrawScrollbar(x + w - P.bar_w, y0, y0 + P.rows * (P.row_h + P.row_gap) - P.row_gap)
      EndFrame()
      return
    end
    Text(Tx("ColName"), COL.name, cy, "head", hs)
    TextC(Tx("ColMatches"), COL.matches, cy, "head", 26, hs)
    TextC(Tx("ColGoals"), COL.goals, cy, "head", 26, hs)
    TextC(Tx("ColAssists"), COL.assists, cy, "head", 26, hs)
    TextC(Tx("ColMvp"), COL.mvp, cy, "head", 26, hs)
    TextC(Tx("ColWinPct"), COL.winpct, cy, "head", 26, hs)
    TextC(Tx("ColSigned"), COL.signed, cy, "head", 26, hs)
    y = y + P.columns_h + P.head_gap
    local y0 = y
    if #S.rows == 0 then
      EmptyLine(Tx("NoPlayers"), x + w / 2, y)
    end
    for k = 0, P.rows - 1 do
      local r = S.rows[S.top + k]
      if r == nil then break end
      DrawRow(r, y, S.top + k == S.sel)
      y = y + P.row_h + P.row_gap
    end
    DrawScrollbar(x + w - P.bar_w, y0, y0 + P.rows * (P.row_h + P.row_gap) - P.row_gap)
  end
  EndFrame()
end

local function Move(d)
  local rows, sel, top = List()
  local n = #rows
  if n == 0 then return end
  local s = math.max(1, math.min(n, sel + d))
  if s == sel then return end
  if s < top then top = s end
  if s >= top + P.rows then top = s - P.rows + 1 end
  SetList(s, top)
  Snd(SY_MOVE)
  S.dirty = true
end

-- L1 / R1: the players tab and the match history tab
local function SwitchTab()
  S.tab = S.tab == TAB_PLAYERS and TAB_HISTORY or TAB_PLAYERS
  Snd(SY_MOVE)
  S.dirty = true
end

local function NextSort()
  if S.tab ~= TAB_PLAYERS or #S.rows == 0 then
    Snd(SY_ERROR)
    return
  end
  S.sort = S.sort % #SORTS + 1
  SortRows()
  S.sel, S.top = 1, 1
  Snd(SY_MOVE)
  S.dirty = true
end

function OnInit()
  S.ready, S.art_ok, S.frame, S.sel, S.top, S.sort, S.dirty = false, false, 0, 1, 1, 1, true
  S.tab, S.hsel, S.htop = TAB_PLAYERS, 1, 1
  Bind()
  Kit = VRFW.screen_kit.new()
  S.faces, S.texts = {}, {}
  if VRFW.face_icon ~= nil then VRFW.face_icon.forget(L.FACE) end
  Load()
end

function OnSetupLayer(a1, a2)
  Bind()
  if a1 == L_LINE then
    M(C.SET_TEXT, a1, LINE_TEXT, SinceLine())
  elseif Page.setup_layer(Kit, L, a1, a2) then
    S.dirty = true
  end
end

function OnOpenLayer(a1, a2)
  if Page.open_layer(Kit, L, a1, a2) then
    S.ready = true
    S.dirty = true
  end
end

function OnFunction(a1, a2)
  local id = a2
  if id ~= FN.UP and id ~= FN.DOWN and id ~= FN.TAB_PREV and id ~= FN.TAB_NEXT and id ~= FN.SORT then id = a1 end
  if id == FN.UP then Move(-1)
  elseif id == FN.DOWN then Move(1)
  elseif id == FN.TAB_PREV or id == FN.TAB_NEXT then SwitchTab()
  elseif id == FN.SORT then NextSort()
  else return end
  return 1
end

function OnBack(a1)
  Log("page closed")
end

function Step()
  S.frame = S.frame + 1
  if not S.ready then return end
  if not S.art_ok and TexReady(ART) then
    S.art_ok = true
    Kit.forget()
    S.dirty = true
  end
  local wheel = Page.wheel()
  if wheel ~= 0 then Move(wheel) end
  if S.dirty or #S.rows > 0 or #S.hist > 0 then
    S.dirty = false
    local ok, err = pcall(Draw)
    if not ok then Log("draw error", tostring(err)) end
  end
end
