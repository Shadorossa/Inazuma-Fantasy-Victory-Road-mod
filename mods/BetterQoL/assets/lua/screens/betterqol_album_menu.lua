INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_PROG_COMMON")

local CMD = { OPEN = 3117903358 --[[CMND_BETTERQOL_ALBUM_OPEN]], PAGE = 162355322 --[[CMND_BETTERQOL_ALBUM_PAGE]],
  SEARCH = 503101643 --[[CMND_BETTERQOL_ALBUM_SEARCH]],
  FILTER_INFO = 2527627263 --[[CMND_BETTERQOL_ALBUM_FILTER_INFO]],
  FILTER_COUNT = 1726443206 --[[CMND_BETTERQOL_ALBUM_FILTER_COUNT]],
  FILTER_SET = 2948173574 --[[CMND_BETTERQOL_ALBUM_FILTER_SET]] }
local C = {
  TEXT_GET = 4074371074, LANG = 477234096, SND = 3073642526, VISIBLE = 711242136, POS = 1389957207,
  SCALE = 3778714801, MESH_VISIBLE = 3405944500, TEXT_VISIBLE = 2735666188, SET_TEXT = 1083631230,
  LOAD_TEX = 839427544, TEX_LOADING = 1506186496, RESET_FACE = 4176779611,
  OPEN_MENU = 433545986, CLOSE_MENU = 320421347, IS_MENU = 2231168902, IS_OPEN_MENU = 3693934564,
  HIDE_MENU = 1670867360, SHOW_MENU = 3257327861,     -- (1, menu): not drawn / (menu): drawn again
}
-- the page's layers (content\menus\album.toml)
local L = { PLATE = 355864142, ICON = 2800090306, FACE = 3328552574, TEXT = 4177162974, CREST = 2689129817,
  FILTER_PLATE = 2182559463 --[[betterqol_alb_fw_plate]], FILTER_ICON = 1426382281 --[[betterqol_alb_fw_icon]],
  FILTER_TEXT = 186340309 --[[betterqol_alb_fw_text]] }
local L_LINE = 3078308064          -- mainmenu90_05_content_guide_line01
local L_BACKDROP = 2045045275
local CASETA = { MENU = 1281873114 --[[play_guide_top_menu]], CROSS_CALL = 830228314 --[[(menu, global function, ...)]],
  BACKGROUND = "BetterQoL_AlbumCasetaBackground" }
local GUIDE = { BUTTON = 9396745 --[[mainmenu01_07_button_guide]], GLYPH = 950238781 --[[_text_btn01]], GLYPH_W = 50,
  GAP = 16, TEXT_PX = 26, REFRESH_NAME = "BetterQoL_AlbumGuide" }
local LINE_TEXT = 378156699        -- _text_guide01
-- the anchor's functions (crc32 of the cmd row names)
local FN = {
  [531800831] = "up", [3750642978] = "down", [3105239665] = "left", [3496127489] = "right",
  [4230302454] = "type_prev", [448720774] = "type_next", [2954796991] = "group_prev", [148047830] = "group_next",
  [4052227683] = "plate_prev", [1229295114] = "plate_next", [3734610182] = "accept",
  [2704906768] = "multi", [310186799] = "filter", [4158742174] = "select_key",
}
local TXT_BOX_W = 384               -- the text node's box width: a centred style centres on it
-- the player plate the page opens (personal_plate_menu in its players-universe mode)
local PLATE = {
  MENU = 1427722143 --[[personal_plate_menu]], PAGE = 878737202 --[[team11_01_personal_plate]],
  P_PARAM = 3928123478, P_LEVEL = 3894267099, P_RARITY = 571278276,
  FLAG = 2398708549 --[[BetterQoL.album_plate: set while this page shows the plate]],
  SET = 1101551215 --[[(param, level, rarity, false): the plate's player]],
  PAGE_PREV = 567813453, PAGE_NEXT = 2019940505, PAGE_UPDATE = 3297841487,
  RARITY_DEFAULT = 4, WAIT = 180,
  REST = 8,
  CARD = 2716223290,
  CARD_TEAM = 1860450077,            -- VRFW.plate_card_team: the team that dresses that card
}
local SY_MOVE, SY_PAGE, SY_ERROR, SY_BACK = 2500047763, 2629173176 --[[sy0009]], 2086672038, 202039849
local GLYPH = 0.5
local STYLE = {
  section = "fs2_26_w_lc_2d2_001_nr", tab = "fs_28_b_lc_2d0_001", name = "fs_28_b_lc_2d0_001",
  bar = "fs_28_w_cc_2d2_001",          -- white, centred: the group labels on the tab bar
  head = "fs2_26_w_lc_2d2_001_nr",
}
local P = { x = 60, width = 900, type_y = 168, type_h = 44, tabs_y = 206, tab_h = 58, tab_gap = 4, key_w = 46,
  band_y = 274, band_h = 40, top = 280, cols = 2, rows = 10, row_h = 50, row_gap = 4, col_gap = 14, bar_gap = 10, face = 50, extra_icon = 25, extra_gap = 6, extra_unit = 13.25, box_body = 114, box_gap = 8, box_pad = 10, name_pad = 22,
  extra_scale = 0.75, name_scale = 0.95, name_min = 0.78, name_unit = 15.5, band_text_x = 36, band_right = 70, band_count_w = 260, crest = 34, page_y = 878, badge_x = 1880, badge_y = 912, badge_h = 44 }
P.col_w = math.floor((P.width - P.col_gap) / 2)
local ROW = { cap = 32, left = 26.125, right = 11, slant = 15.125, edge_inset = 5 }  -- edge_inset: the plate's visible top and bottom margin
local PER_PAGE = P.cols * P.rows
local ART, SPRITE = "#/menu/220_img/betterqol_club_stats/betterqol_club_stats.g4tx", "betterqol_club_stats_"
local RETAIL = {
  list = { tex = "#/menu/51_save/save01/save01_02/save01_02.g4tx",
           off = "list_base_s01_off", focus = "list_base_s01_ol" },
  cursor = { tex = "#/menu/20_cmn/cmn05/cmn05_01/cmn05_01.g4tx", sprite = "cur01", w = 128, h = 152 },
  tabs = { tex = "#/menu/200_icon/16_icon_list_tab/<LG>/icon_list_tab.g4tx", w = 144, h = 96 },
  strip = { tex = "#/menu/20_cmn/cmn06/cmn06_01/cmn06_01.g4tx", w = 1036, h = 76, band_t = 14, band_b = 62,
            slant = 8 / 42, tab_aspect = 1.5,
            variants = { { sprite = "list_tab_base01", left = 162, right = 882 },
                         { sprite = "list_tab_base01_02", left = 122, right = 922 } } },
  focus = { tex = "#/menu/20_cmn/cmn06/cmn06_20/cmn06_20.g4tx", sprite = "icon_base01", w = 92, h = 52,
            mid_l = 5, mid_r = 85 },
}
-- the small slanted bar on a row plate's left border (a flat coloured sprite per state: CMND_SET_PRIM_COLOR does not tint the cmn01_10 quad; transparent pad on every side for bilinear sampling): blue = in the club, red = not; its left side is the plate's border (ROW.right at the bottom, ROW.left at the top); rgb 0..1
local OWNED_BAR = { w = 32, h = 44, pad = 2, owned = "album_owned_bar", missing = "album_missing_bar", marked = "album_marked_bar" }
-- the tick of a marked row (the filter window's sprites), over the row's bar
local MARK_TICK = { tex = "#/menu/10_win/win07/win07_04/win07_04.g4tx", base = "icon_base01", check = "icon_check01", dx = 2, check_dx = -4, check_w = 44, size = 32 }
-- a player of a team not beaten yet in the Chronicle / story (VRFW.team_beaten): the game's padlock in the row's box
local LOCK = { atlas = "#/menu/102_team/team00/team00_01/team00_01.g4tx", sprite = "icon_lock01" }
-- the bust's bottom meets the row plate's bottom edge
local FACE_LIFT = 3
local KIND_GAME, KIND_TEAM, KIND_SEARCH = 2, 3, 4
local WAIT_FRAMES = 300
local FACES_A_FRAME = 5            -- minifaces asked per frame after a drawing
local EXTRA_RETRIES = 30
-- the pointer zones lit on hover (a row takes the selection instead)
local HOVER_LIT = { type = true, type_key = true, group = true, group_key = true, bar_page = true, page = true }
local HOVER_ALPHA = 0.5

local S = { diag = {}, ready = false, ok = false, kind = KIND_GAME, group = 1, page = 1, pages = 1, sel = 1, data = nil,
  rows = {}, total = 0, owned = 0, texts = {}, loaded = {},
  dirty = true, frame = 0, plate = nil, line = nil, zones = {}, ptr = {},
  face_queue = {}, face_next = 1, face_sig = {}, face_key = {},
  multi = false, marks = {}, marked = 0, marked_seq = 0, balance = 0 }

local Page, Log, M

local function Bind()
  if Page ~= nil then return end
  Page = BetterQoL.page
  Log, M = Page.logger("betterqol album"), VRFW.host.menu_command
end

local function Crc(text)
  return VRFW.ids.crc32(text)
end

local function Tx(name)
  return Page.tx(S.texts, "BetterQoL.Album.", name)
end

-- the same, but an empty text stays empty
local function TxRaw(name)
  local s = VRFW.host.command(C.TEXT_GET, Crc("BetterQoL.Album." .. name))
  return (type(s) == "string") and s or ""
end

local function Fill(s, a, b, c)
  s = tostring(s):gsub("{1}", function() return tostring(a) end)
  s = s:gsub("{2}", function() return tostring(b) end)
  return (s:gsub("{3}", function() return tostring(c) end))
end

local function Snd(s) VRFW.host.command(C.SND, s) end

local Kit   -- VRFW.screen_kit.new in OnInit

local function TexReady(tex)
  local state = S.loaded[tex]
  if state == "in" then return true end
  if state == nil then
    VRFW.host.menu_command(C.LOAD_TEX, tex)   -- CMND_LOAD_MENU_RES_TEXTURE is a menu command
    S.loaded[tex] = "asked"
  end
  local loading = VRFW.host.command(C.TEX_LOADING, Crc(tex))
  if loading == false then
    S.loaded[tex] = "in"
    return true
  end
  return false
end

local function Quad(layer, tex, sprite, x, y, w, h, raise)
  return Kit.quad(layer, tex, sprite, x, y, w, h, { raise = raise })
end

local function Plate(layer, look, x, y, w, h)
  return Quad(layer, RETAIL.list.tex, RETAIL.list[look], x, y, w, h)
end

local function RowPlate(layer, look, x, y, w)
  local c = ROW.cap
  Quad(layer, ART, SPRITE .. "album_" .. look .. "_l", x, y, c, P.row_h)
  Quad(layer, ART, SPRITE .. "album_" .. look .. "_m", x + c, y, w - 2 * c, P.row_h)
  Quad(layer, ART, SPRITE .. "album_" .. look .. "_r", x + w - c, y, c, P.row_h)
end

local function RowLayout(r, rw)
  if r == nil or r.extra == nil then return rw, nil end
  return rw - P.box_body - P.box_gap, P.box_body + ROW.left + ROW.right
end

local function Cursor(x, y, h)
  local R = RETAIL.cursor
  local w = h * R.w / R.h
  return Quad(L.ICON, R.tex, R.sprite, x - w, y - h / 2, w, h)
end

local function Units(s) return VRFW.text_fold.units(s) end

local function Text(s, x, y, style, sc)
  return Page.text(Kit, L.TEXT, STYLE[style] or STYLE.name, s, x, y, sc)
end

-- a text centred on cx (its width estimated from the glyph size `px` of the style at scale 1)
local function TextC(s, cx, y, style, px, sc)
  sc = sc or 1
  return Text(s, cx - Units(s) * px * sc * GLYPH / 2, y, style, sc)
end

local function TextR(s, rx, y, style, px, sc)
  sc = sc or 1
  return Text(s, rx - Units(s) * px * sc * GLYPH, y, style, sc)
end

local function Fit(s, px, size) return VRFW.text_fold.fit(s, px, size, GLYPH) end

local KEEPER_SHIRT = 2           -- CMND_VRFW_CONTACT_KIT flags: the keeper shirt
local function RowKit(r)
  if (r.param or 0) == 0 or VRFW.commands == nil then return nil end
  local team = r.dress_team or 0
  local id = r.param .. ":" .. team
  local kit = S.kits[id]
  if kit == nil then
    kit = false
    local t = VRFW.host.command(VRFW.commands.VRFW_CONTACT_KIT, r.param, team)
    if type(t) == "table" and type(t.uniform) == "number" and t.uniform ~= 0 then
      kit = { kit = t.uniform, keeper = bit32.band(tonumber(t.flags) or 0, KEEPER_SHIRT) ~= 0, use_args = true }
    end
    S.kits[id] = kit
  end
  return kit or nil
end

local function Face(r, cx, cy, size)
  if VRFW.face_icon == nil then return end
  local i = Kit.slot(L.FACE)
  if i == nil then return end
  Kit.show(L.FACE, i)
  local sig = r.base .. ":" .. r.param .. ":" .. r.dress_team .. ":" .. cx .. ":" .. cy
  if S.face_sig[i] == sig then return end
  -- the slot's previous face goes at once
  if S.face_key[i] ~= nil and S.face_key[i] ~= r.base then
    M(C.MESH_VISIBLE, L.FACE, VRFW.face_icon.CARD.MESH, false, i)
  end
  S.face_queue[#S.face_queue + 1] = { i = i, r = r, cx = cx, cy = cy, size = size, sig = sig }
end

local function FaceStep()
  if VRFW.face_icon == nil then return end
  local q = S.face_queue
  local last = math.min(#q, S.face_next + FACES_A_FRAME - 1)
  for n = S.face_next, last do
    local e = q[n]
    VRFW.face_icon.card(L.FACE, e.i, e.r.base, e.cx, e.cy, e.size, RowKit(e.r) or { use_args = true })
    S.face_sig[e.i], S.face_key[e.i] = e.sig, e.r.base
  end
  S.face_next = math.max(S.face_next, last + 1)
  if VRFW.face_icon.pending() then VRFW.face_icon.settle() end
end

local function BeginFrame()
  Kit.begin()
  S.waiting, S.zones = false, {}
  S.face_queue, S.face_next = {}, 1
  if S.ptr then S.ptr.begin() end
end

local function Zone(x, y, w, h, kind, v)
  -- behind the open filter window only its own zones exist
  if S.filter_window ~= nil and (kind == "filter_open" or kind:sub(1, 7) ~= "filter_") then return end
  local id = kind .. ":" .. tostring(v)
  S.zones[id] = { kind = kind, v = v, x = x, y = y, w = w, h = h }
  if S.ptr then S.ptr.rect(x, y, w, h, id) end
end

local function EndFrame()
  Kit.finish(function(layer, i)
    if layer == L.FACE and VRFW.face_icon ~= nil then
      VRFW.face_icon.forget(L.FACE, i)
      S.face_sig[i], S.face_key[i] = nil, nil
    end
    if layer == L.CREST then S.crests[i] = nil end
  end)
end

local function ParamSet(k, v)
  if VRFW.param.has(k) then VRFW.param.clear(k) end
  VRFW.param.set(k, v)
end

local function ParamClear(k)
  if VRFW.param.has(k) then VRFW.param.clear(k) end
end

local function PlateExists() return M(C.IS_MENU, PLATE.MENU) == true end

local function PlateUp()
  local up = VRFW.host.command(C.IS_OPEN_MENU, PLATE.MENU, PLATE.PAGE)
  return up == true
end

local function DressTeam(r)
  if r.dress_team ~= nil and r.dress_team ~= 0 then
    ParamSet(PLATE.CARD_TEAM, r.dress_team)
  else
    ParamClear(PLATE.CARD_TEAM)
  end
end

local function Who(r)
  local rar = r.rarity
  if rar == nil or rar < 0 then rar = PLATE.RARITY_DEFAULT end
  return r.param, math.max(1, r.level), rar
end

local function PlateOpen(r)
  local param, level, rar = Who(r)
  ParamSet(PLATE.P_PARAM, param)
  ParamSet(PLATE.P_LEVEL, level)
  ParamSet(PLATE.P_RARITY, rar)
  ParamSet(PLATE.FLAG, 1)
  ParamSet(PLATE.CARD, param)
  DressTeam(r)
  VRFW.host.command(C.OPEN_MENU, PLATE.MENU)
  S.plate = { state = "opening", at = S.frame, seen = false, param = param, pending = nil }
  Log("plate open asked: param", param, "level", level, "rarity", rar)
end

local function PlateApply()
  local r, P_ = S.rows[S.sel], S.plate
  P_.pending = nil
  if r == nil then return end
  local param, level, rar = Who(r)
  if P_.param == param and P_.level == level and P_.rarity == rar then return end
  ParamSet(PLATE.CARD, param)
  DressTeam(r)
  M(PLATE.SET, param, level, rar, false)
  P_.param, P_.level, P_.rarity = param, level, rar
end

local function PlateShow()
  local r = S.rows[S.sel]
  local P_ = S.plate
  if r == nil or P_ == nil then return end
  if P_.state == nil and not PlateExists() then
    PlateOpen(r)
    return
  end
  P_.pending = r
  if P_.state ~= "up" then return end
  local rested = P_.moved == nil or S.frame - P_.moved >= PLATE.REST
  P_.moved = S.frame
  if rested then PlateApply() end
end

-- the page's backdrop on and the Caseta's background off (on = true), or the reverse, in one step
local function Cover(on)
  if S.cover == on then return end
  S.cover = on
  M(C.VISIBLE, L_BACKDROP, 0, on)
  VRFW.host.command(CASETA.CROSS_CALL, CASETA.MENU, CASETA.BACKGROUND, not on)
  Log("backdrop", on and "shown, caseta background hidden" or "hidden, caseta background shown")
end

local function PlateStep()
  local P_ = S.plate
  if P_ == nil or P_.state ~= "opening" then
    if P_ ~= nil and P_.state == "up" and P_.pending ~= nil and S.frame - P_.moved >= PLATE.REST then PlateApply() end
    return
  end
  if PlateExists() then
    P_.seen = true
    if PlateUp() then
      P_.state = "up"
      ParamClear(PLATE.P_PARAM)
      ParamClear(PLATE.P_LEVEL)
      ParamClear(PLATE.P_RARITY)
      Log("plate up")
      Cover(true)
      S.dirty = true                     -- the guide's zones are read again
      if P_.pending ~= nil then PlateApply() end
    end
  elseif P_.seen or S.frame - P_.at > PLATE.WAIT then
    Log("the plate did not open")
    P_.state = "failed"
  end
end

BetterQoL_AlbumPlateFirstPage = function(first)
  first = first ~= false
  if first ~= S.first_page then
    S.first_page = first
    S.dirty = true
  end
end

local function PlatePage(d)
  if S.plate == nil or S.plate.state ~= "up" or not PlateUp() then
    Snd(SY_ERROR)
    return
  end
  M(d < 0 and PLATE.PAGE_PREV or PLATE.PAGE_NEXT)
  M(PLATE.PAGE_UPDATE)
end

local function Groups() return S.data and S.data.groups and S.data.groups[S.kind] or {} end

local function BarPage(gl, k)
  local g = gl[k]
  return g and tonumber(g[8]) or 1
end

local function LineText()
  if not S.ok then return Tx("NoSave") end
  if S.multi then
    local total = 0
    for _, m in pairs(S.marks) do total = total + m.count end
    return Fill(Tx("MarkedLine"), S.marked, total, S.balance)
  end
  return Tx("Line")
end

local function SetLine()
  local s = LineText()
  if s ~= S.line then
    S.line = s
    M(C.SET_TEXT, L_LINE, LINE_TEXT, s)
  end
end

-- the row extras of the first offered AlbumActions entry with RowExtras
local function LoadRowExtras()
  S.extra_retries = S.extra_retries - 1
  local a = Page.album_action("RowExtras", "function")
  if a == nil then
    S.extra_retries = 0
    return
  end
  local ok, extras = pcall(a.RowExtras, S.rows)
  if not ok then
    Log("row extras error", tostring(extras))
    S.extra_retries = 0
    return
  end
  if type(extras) == "table" then
    S.extra_retries = 0
    for k, r in ipairs(S.rows) do
      local e = extras[k]
      local whole = type(e) == "table" and type(e.text) == "string" and type(e.atlas) == "string"
        and type(e.sprite) == "string"
      r.extra = r.lock and LockExtra() or (whole and e or nil)
    end
    S.dirty = true
  end
end

-- the lock of a player the club lacks: the first of his teams under the team-beaten rule when none of them was beaten; nil = free
local function RowLock(r)
  if r.owned then return nil end
  local first = nil
  for _, t in ipairs(r.teams) do
    local beaten, chronicle, story = VRFW.team_beaten.state(t[1])
    if beaten == true then return nil end
    if beaten == false and first == nil then first = { name = t[2], chronicle = chronicle, story = story } end
  end
  return first
end

-- the box of a locked row: the padlock, no price
local function LockExtra()
  return { text = "", count = 0, atlas = LOCK.atlas, sprite = LOCK.sprite }
end

-- why a row is locked: "beat <team> in the Chronicle / story"
local function LockText(r)
  local k = r.lock
  local key = (k.chronicle and k.story) and "LockBoth" or (k.story and "LockStory" or "LockChronicle")
  local name = k.name ~= "" and k.name or (r.team ~= "" and r.team or Tx("LockTheirTeam"))
  return Fill(Tx(key), name)
end

local function LoadPage()
  S.rows = {}
  S.extra_retries = 0
  local t = VRFW.host.command(CMD.PAGE, S.kind, S.group, S.page, PER_PAGE)
  if type(t) ~= "table" then
    Log("diag: page data refused:", tostring(t))
    S.pages, S.total, S.owned = 1, 0, 0
    return
  end
  S.page, S.pages, S.total, S.owned = t.page or 1, t.pages or 1, t.total or 0, t.owned or 0
  for k, e in ipairs(type(t.rows) == "table" and t.rows or {}) do
    S.rows[k] = { base = tonumber(e[1]) or 0, param = tonumber(e[2]) or 0, name = tostring(e[3] or ""),
      team = tostring(e[4] or ""), game = tostring(e[5] or ""), owned = e[6] == true, level = tonumber(e[7]) or 1,
      rarity = tonumber(e[8]) or 0, dress_team = tonumber(e[9]) or 0, teams = {} }
    for _, t in ipairs(type(e[10]) == "table" and e[10] or {}) do
      S.rows[k].teams[#S.rows[k].teams + 1] = { tonumber(t[1]) or 0, tostring(t[2] or "") }
    end
    S.rows[k].lock = RowLock(S.rows[k])
    S.rows[k].extra = S.rows[k].lock and LockExtra() or nil
  end
  S.sel = math.max(1, math.min(#S.rows, S.sel))
  S.dirty = true
  S.extra_retries = EXTRA_RETRIES
  LoadRowExtras()
  SetLine()
  PlateShow()
end

local FilterApply

local function Load()
  VRFW.team_beaten.reset()
  local lang = VRFW.host.command(C.LANG)
  local t = VRFW.host.command(CMD.OPEN, lang or 1, TxRaw("NameGroups"), Tx("OtherGroup"), Tx("Specials"),
    Tx("OtherTeams"))
  S.ok = type(t) == "table" and type(t.groups) == "table"
  S.data = S.ok and t or nil
  if not S.ok then
    Log("no album data", tostring(t))
    return
  end
  Log("page opened:", t.total, "player(s),", t.owned, "in the club")
  if S.filter_spec ~= nil then FilterApply() end
end

local BLUE_STYLE = "tab"

local function DrawTypes()
  local y, h = P.type_y, P.type_h
  if S.search == nil then
    Text(Tx("KeysType"):match("^(<[^>]+>)") or "", P.x, y, "head")
    Zone(P.x, y - h / 2, P.key_w, h, "type_key", 1)
  end
  local x0, x1 = P.x + P.key_w + 6, P.x + P.width
  local names = { Tx("TypeName"), Tx("TypeSeries"), Tx("TypeTeam") }
  local w = (x1 - x0 - 4) / #names
  for k, s in ipairs(names) do
    local x = x0 + (k - 1) * (w + 4)
    Plate(L.PLATE, "off", x, y - h / 2, w, h)
    if k == S.kind then Plate(L.ICON, "focus", x, y - h / 2, w, h) end
    TextC(s, x + w / 2, y + 1, BLUE_STYLE, 28)
    Zone(x, y - h / 2, w, h, "type", k)
  end
end

-- a team crest on betterqol_alb_crest (the emblem list row team06_02, only its emblem quad shown) centred at (cx, cy)
local CREST = { MESH = 3281704751 --[[_icon_emblem_dmy01]], TEX = 255812047 --[[icon_emblem_dmy01]], PX = 68, CX = 78,
  HIDE = { "_list_base_xs01_off", "_list_base_xs01_on", "_list_base_xs01_ok", "_list_base_xs01_ol", "_icon_check01" },
  TEXTS = { 931545948 --[[`_text_list01_on`]], 3705682548 --[[_text_list01_off]] }, ASK_FRAMES = 30 }
local function Crest(id, cx, cy, px)
  local i = Kit.slot(L.CREST)
  if i == nil then return end
  local s = px / CREST.PX
  Kit.show(L.CREST, i)
  Kit.set(L.CREST, i, "sc", C.SCALE, L.CREST, s, s, 1, i)
  Kit.set(L.CREST, i, "pos", C.POS, L.CREST, cx - CREST.CX * s, -cy, 0, i)
  local c = S.crests[i]
  if c == nil or c.id ~= id then
    if c ~= nil then M(C.RESET_FACE, L.CREST, i, CREST.TEX) end
    c = { id = id, at = S.frame }
    S.crests[i] = c
  end
  if S.frame - c.at <= CREST.ASK_FRAMES then
    for _, m in ipairs(CREST.HIDE) do M(C.MESH_VISIBLE, L.CREST, Crc(m), false, i) end
    for _, t in ipairs(CREST.TEXTS) do M(C.TEXT_VISIBLE, L.CREST, t, false, i) end
    VRFW.team.crest(L.CREST, i, id, nil, CREST.MESH, CREST.TEX)   -- the framework's crest request
    S.waiting = true
  end
end

local function DrawStripBar(gl, y, h)
  local R, F = RETAIL.strip, RETAIL.focus
  local x0, w = P.x + P.key_w, P.width - 2 * P.key_w
  local sx, sy = w / R.w, h / R.h
  local by, bh = y + R.band_t * sy, (R.band_b - R.band_t) * sy
  local segs = {}
  if S.search ~= nil then
    segs[1] = { k = S.group, left = true, label = Fill(Tx("SearchBand"), S.search.text, S.total) }
  elseif S.kind == KIND_TEAM then
    local g = gl[S.group]
    if g then
      segs[1] = { k = S.group, emblem = tonumber(g[5]) or 0, left = true,
                  label = tostring(g[6] or g[1] or "") }
    end
  else
    local page = BarPage(gl, S.group)
    for k, g in ipairs(gl) do
      if BarPage(gl, k) == page then
        local icon = S.kind == KIND_GAME and type(g[7]) == "string" and g[7] ~= "" and g[7] or nil
        segs[#segs + 1] = { k = k, ty = S.kind == KIND_GAME and tonumber(g[4]) or nil, icon = icon,
                            label = tostring(g[1] or "") }
      end
    end
  end
  -- the first variant whose blue part holds every tab at its natural width, else the widest
  local variant = R.variants[#R.variants]
  for _, v in ipairs(R.variants) do
    if (v.right - v.left) * sx >= #segs * R.tab_aspect * bh then variant = v break end
  end
  Quad(L.PLATE, R.tex, variant.sprite, x0, y, w, h)
  -- "<" / ">" in the end caps when another bar page lies that way
  if S.kind ~= KIND_TEAM then
    local page, last = BarPage(gl, S.group), BarPage(gl, #gl)
    local cap = variant.left * sx
    if page > 1 then
      Text("<", x0 + cap / 2 - TXT_BOX_W / 2, by + bh / 2 + 1, "bar")
      Zone(x0, y, cap, h, "bar_page", -1)
    end
    if page < last then
      Text(">", x0 + w - cap / 2 - TXT_BOX_W / 2, by + bh / 2 + 1, "bar")
      Zone(x0 + w - cap, y, cap, h, "bar_page", 1)
    end
  end
  local mid = ((R.band_t + R.band_b) / 2 - R.band_t) * R.slant
  local il, ir = x0 + (variant.left - mid) * sx, x0 + (variant.right - mid) * sx
  -- a tab keeps its natural width (tab_aspect x band height), never stretched
  local tw = (ir - il) / math.max(1, #segs)
  if S.kind ~= KIND_TEAM and S.search == nil then tw = math.min(tw, R.tab_aspect * bh) end
  -- the tabs centred in the blue part
  local first = il + ((ir - il) - #segs * tw) / 2
  for n, sg in ipairs(segs) do
    local x = first + (n - 1) * tw
    Zone(x, y, tw, h, "group", sg.k)
    local on = sg.k == S.group
    if on and not sg.left then
      -- the block's visible parallelogram spans exactly this segment at mid height
      local qw = tw * F.w / (F.mid_r - F.mid_l)
      Quad(L.ICON, F.tex, F.sprite, x - F.mid_l * qw / F.w, by, qw, bh)
    end
    local drawn = false
    -- the group's own tab icon, else its series type's
    local sprite = sg.icon or (sg.ty and sg.ty >= 1 and sg.ty <= 99 and string.format("icon_list_tab_series%02d", sg.ty))
    if sprite then
      local iw = math.min(tw, bh * RETAIL.tabs.w / RETAIL.tabs.h)
      drawn = Quad(L.ICON, RETAIL.tabs.tex, sprite .. (on and "" or "_off"),
        x + (tw - iw) / 2, by, iw, bh, on and 1 or 0) ~= nil
    end
    if not drawn then
      -- the label centred on its segment, right of the crest when there is one
      local lx, lw = x, tw
      if sg.emblem and sg.emblem ~= 0 then
        local cs = bh - 4
        local cx = x + 8
        if sg.left then
          local nw = math.min(Units(sg.label) * 26 * GLYPH, tw - cs - 40)
          cx = x + (tw - (cs + 8 + nw)) / 2
        end
        Crest(sg.emblem, cx + cs / 2, by + bh / 2, cs)
        lx, lw = cx + cs + 8, tw - (cx - x) - cs - 8
      end
      local sc = 0.9
      if sg.left then
        local t = Fit(sg.label, lw - 12, 26)
        local nx = lx
        if not (sg.emblem and sg.emblem ~= 0) then nx = x + (tw - Units(t) * 26 * GLYPH) / 2 end
        Text(t, nx, by + bh / 2 + 1, "section")
      else
        Text(Fit(sg.label, lw - 12, 28 * sc), lx + lw / 2 - TXT_BOX_W / 2 * sc, by + bh / 2 + 1, "bar", sc)
      end
    end
  end
end

local function DrawGroups()
  local gl = Groups()
  local y, h = P.tabs_y, P.tab_h
  local mid = y + h / 2
  if S.search == nil then
    Text(Tx("KeysGroup"):match("^(<[^>]+>)") or "", P.x, mid, "head")
    TextR(Tx("KeysGroup"):match("(<[^>]+>)$") or "", P.x + P.width, mid, "head", 26)
    Zone(P.x, y, P.key_w, h, "group_key", -1)
    Zone(P.x + P.width - P.key_w, y, P.key_w, h, "group_key", 1)
  end
  DrawStripBar(gl, y, h)
end

-- a band of the page's atlas (cap, stretched middle, cap)
local BAND_CAP = 40
local function Band(x, y, w, h)
  Quad(L.PLATE, ART, SPRITE .. "section_l", x, y, BAND_CAP, h)
  Quad(L.PLATE, ART, SPRITE .. "section_m", x + BAND_CAP, y, w - 2 * BAND_CAP, h)
  Quad(L.PLATE, ART, SPRITE .. "section_r", x + w - BAND_CAP, y, BAND_CAP, h)
end

-- the top-left corner and width of row k
local function RowAt(k)
  local col, row = math.floor((k - 1) / P.rows), (k - 1) % P.rows
  return P.x + 14 + col * (P.col_w + P.col_gap), P.top + row * (P.row_h + P.row_gap), P.col_w - 14
end

local function DrawSelection()
  if S.rows[S.sel] == nil then return end
  local rx, ry, rw = RowAt(S.sel)
  RowPlate(L.ICON, "focus", rx, ry, (RowLayout(S.rows[S.sel], rw)))
  Cursor(rx + 6, ry + P.row_h / 2, 38)
end

-- the zone under the pointer lit, last so that it renumbers nothing
local function DrawHover()
  local z = S.hover ~= nil and S.zones[S.hover] or nil
  if z == nil then return end
  if (z.kind == "type" and z.v == S.kind) or (z.kind == "group" and z.v == S.group) then return end
  Kit.quad(L.ICON, RETAIL.list.tex, RETAIL.list.focus, z.x, z.y, z.w, z.h, { alpha = HOVER_ALPHA })
end

local function GuideZone(entry, text, v)
  local x, y = M(VRFW.commands.GET_MESH_GLOBAL_POSITION, GUIDE.BUTTON, entry, GUIDE.GLYPH, CASETA.MENU)
  if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return end
  local s = VRFW.host.command(C.TEXT_GET, text)
  local w = (type(s) == "string") and Units(s) * GUIDE.TEXT_PX * GLYPH or 0
  Zone(x, -y, GUIDE.GLYPH_W + GUIDE.GAP + w, GUIDE.GLYPH_W, "guide", v)
end

local function GuideZones()
  for i, e in ipairs(Page.album_guide(S.multi)) do GuideZone(i - 1, e.text, e.act) end
end

local function DrawRow(r, k)
  local rx, ry, rw = RowAt(k)
  local plate_w, box_w = RowLayout(r, rw)
  RowPlate(L.PLATE, "row", rx, ry, plate_w)
  if box_w ~= nil then RowPlate(L.PLATE, "row", rx + rw - box_w, ry, box_w) end
  Zone(rx, ry, rw, P.row_h, "row", k)
  local cy = ry + P.row_h / 2
  local marked = S.multi and S.marks[r.param] ~= nil
  local bar = marked and OWNED_BAR.marked or (r.owned and OWNED_BAR.owned or OWNED_BAR.missing)
  Quad(L.ICON, ART, SPRITE .. bar, rx + ROW.right - OWNED_BAR.pad, ry + ROW.edge_inset - OWNED_BAR.pad, OWNED_BAR.w, OWNED_BAR.h)
  if marked then
    local tx, T = rx + ROW.right, MARK_TICK
    Quad(L.ICON, T.tex, T.base, tx + T.dx, cy - T.size / 2, T.size, T.size, 1)
    Quad(L.ICON, T.tex, T.check, tx + T.dx + T.check_dx, cy - T.size / 2, T.check_w, T.size, 2)
  end
  local fx = rx + ROW.right + OWNED_BAR.w - 2 * OWNED_BAR.pad + P.bar_gap
  if r.base ~= 0 then Face(r, fx + P.face / 2, cy - FACE_LIFT, P.face) end
  local nx = fx + P.face + 10
  local name, name_right, scale, size = r.name ~= "" and r.name or "-", rx + rw - 40, P.name_scale, 26
  local extra = r.extra
  if extra ~= nil then
    local mid = rx + rw - box_w + ROW.left + P.box_body / 2 - ROW.slant / 2
    local room = P.box_body - 2 * P.box_pad - P.extra_gap - P.extra_icon
    local width, tscale = Units(extra.text) * P.extra_unit, P.extra_scale
    if width > room then tscale, width = tscale * room / width, room end
    local gx = mid - (width + P.extra_gap + P.extra_icon) / 2
    Text(extra.text, gx, cy + 2, "name", tscale)
    Quad(L.ICON, extra.atlas, extra.sprite, gx + width + P.extra_gap, cy - P.extra_icon / 2, P.extra_icon, P.extra_icon)
    name_right = rx + plate_w - P.name_pad
    local fit = (name_right - nx) / (Units(name) * P.name_unit)
    scale = P.name_scale * math.max(P.name_min, math.min(1, fit))
    size = 0.99 * P.name_unit / GLYPH * scale / P.name_scale
  end
  Text(Fit(name, name_right - nx, size), nx, cy + 1, "name", scale)
end

-- The album's filter window: the look and layout of the game's own filter window (win07_*), filled from the album's rows
local FILTER = {
  WINDOW = "#/menu/10_win/win07/win07_01/<LG>/win07_01.g4tx", HEAD = "#/menu/10_win/win07/win07_03/win07_03.g4tx",
  ITEM = MARK_TICK.tex, ALL_BUTTON = "#/menu/10_win/win07/win07_10/win07_10.g4tx",
  RESET_BUTTON = "#/menu/10_win/win07/win07_11/win07_11.g4tx", OK_BUTTON = "#/menu/20_cmn/cmn03/cmn03_10/cmn03_10.g4tx",
  OPEN_BUTTON = "#/menu/20_cmn/cmn06/cmn06_04/cmn06_04.g4tx", TAB_BASE = "#/menu/20_cmn/cmn06/cmn06_20/cmn06_20.g4tx",
  TABS_ART = "#/menu/200_icon/16_icon_list_tab_filter/<LG>/icon_list_tab_filter.g4tx",
  ICONS = "#/menu/200_icon/15_icon_common/icon_common.g4tx",
  POSITIONS = "#/menu/200_icon/15_icon_common2/<LG>/icon_common2.g4tx",
  TEXT = { KEY_ACCEPT = 2088669554, ACCEPT = 2739299238, KEY_ALL = 117204058, ALL_BUTTON = 644427157, KEY_RESET = 2352215829,
           RESET = 1017088746, ALL_ROW = 2774495339, ACTIVE = 3763611344 },
  TAB_X = 960, TAB_Y = 174, TAB_GAP = 104, ROW_Y = 308, ROW_STEP = 70, ROWS = 8, COLUMN = { 498, 1048 },
  OK = { x = 960, y = 902 }, ALL = { x = 1502, y = 806 }, RESET = { x = 388, y = 907 },
  SOUND_OK = 3848881948 --[[sy0000]],
}
FILTER.TABS = {
  { title = 2058233886, symbol = "filter_symbol01", icon = "icon_list_tab_filter01", teams = true },
  { title = 1009217165, symbol = "filter_symbol02", icon = "icon_list_tab_filter02", sections = {
    { cat = "position", options = {
      { v = 1, tex = FILTER.POSITIONS, sprite = "icon_cmd_position04", w = 90, h = 64 },
      { v = 2, tex = FILTER.POSITIONS, sprite = "icon_cmd_position01", w = 90, h = 64 },
      { v = 3, tex = FILTER.POSITIONS, sprite = "icon_cmd_position02", w = 90, h = 64 },
      { v = 4, tex = FILTER.POSITIONS, sprite = "icon_cmd_position03", w = 90, h = 64 } } } } },
  { title = 546344626, symbol = "filter_symbol03", icon = "icon_list_tab_filter03", sections = {
    { cat = "element", options = {
      { v = 1, text = 247022515, tex = FILTER.ICONS, sprite = "icon_cmd_type01", w = 44, h = 44 },
      { v = 2, text = 1851377801, tex = FILTER.ICONS, sprite = "icon_cmd_type02", w = 44, h = 44 },
      { v = 3, text = 2003574402, tex = FILTER.ICONS, sprite = "icon_cmd_type03", w = 44, h = 44 },
      { v = 4, text = 2425867594, tex = FILTER.ICONS, sprite = "icon_cmd_type04", w = 44, h = 44 } } } } },
  { title = 1077436763, symbol = "filter_symbol05", icon = "icon_list_tab_filter05", sections = {
    { cat = "gender", options = {
      { v = 1, text = 1055651943, tex = FILTER.ICONS, sprite = "icon_gender01", w = 44, h = 44 },
      { v = 2, text = 207717276, tex = FILTER.ICONS, sprite = "icon_gender02", w = 44, h = 44 },
      { v = 3, text = 282935506, tex = FILTER.ICONS, sprite = "icon_gender03", w = 44, h = 44 } } },
    { cat = "build", options = {
      { v = 1, text = 954158314 }, { v = 2, text = 1129813381 }, { v = 3, text = 3884979346 },
      { v = 4, text = 276111538 }, { v = 5, text = 3930799585 }, { v = 6, text = 2253578851 } } } } },
}

local function RetailText(id)
  local s = VRFW.host.command(C.TEXT_GET, id)
  return (type(s) == "string") and s or ""
end

local function WindowText(s, x, y, style)
  return Page.text(Kit, L.FILTER_TEXT, STYLE[style] or STYLE.section, s, x, y)
end

local function WindowTextCentred(s, cx, y, style, px)
  return WindowText(s, cx - Units(s) * px * GLYPH / 2, y, style)
end

-- every category of the window: { cat, values, saga } (each saga's teams are one category)
local function FilterCategories()
  local out = {}
  for i, saga in ipairs(S.filter_info.sagas) do
    local values = {}
    for k, team in ipairs(saga[2]) do values[k] = team[1] end
    out[#out + 1] = { cat = "saga" .. i, values = values, saga = i }
  end
  for _, tab in ipairs(FILTER.TABS) do
    for _, section in ipairs(tab.sections or {}) do
      local values = {}
      for k, option in ipairs(section.options) do values[k] = option.v end
      out[#out + 1] = { cat = section.cat, values = values }
    end
  end
  return out
end

local function FilterSelectAll(selection, category)
  local set = {}
  for _, v in ipairs(category.values) do set[v] = true end
  selection[category.cat] = set
end

local function FilterIsComplete(selection, category)
  for _, v in ipairs(category.values) do
    if not selection[category.cat][v] then return false end
  end
  return true
end

local function FilterCategory(cat)
  for _, category in ipairs(S.filter_categories) do
    if category.cat == cat then return category end
  end
  return nil
end

local function FilterCopy(selection)
  local out = {}
  for cat, set in pairs(selection) do
    local copy = {}
    for v in pairs(set) do copy[v] = true end
    out[cat] = copy
  end
  return out
end

-- position=1,2;teams=1:11,12/3:  (a category left out is complete; an empty string is no filter)
local function FilterSpec(selection)
  local parts, sagas = {}, {}
  for _, category in ipairs(S.filter_categories) do
    if not FilterIsComplete(selection, category) then
      local kept = {}
      for _, v in ipairs(category.values) do
        if selection[category.cat][v] then kept[#kept + 1] = string.format("%d", v) end
      end
      if category.saga ~= nil then
        sagas[#sagas + 1] = category.saga .. ":" .. table.concat(kept, ",")
      else
        parts[#parts + 1] = category.cat .. "=" .. table.concat(kept, ",")
      end
    end
  end
  if #sagas > 0 then parts[#parts + 1] = "teams=" .. table.concat(sagas, "/") end
  return table.concat(parts, ";")
end

local function FilterRefreshCount()
  local shown = VRFW.host.command(CMD.FILTER_COUNT, FilterSpec(S.filter_window.selection))
  S.filter_window.shown = tonumber(shown) or 0
  S.dirty = true
end

local function PairedLines(out, items)
  for k = 1, #items, 2 do
    out[#out + 1] = { items = { items[k], items[k + 1] } }
  end
end

-- a tab's lines: a saga or section title, then its boxes two by two
local function FilterLines(tab)
  local out = {}
  if tab.teams then
    for i, saga in ipairs(S.filter_info.sagas) do
      out[#out + 1] = { head = saga[1] }
      local cat = "saga" .. i
      local items = { { cat = cat, all = true } }
      for _, team in ipairs(saga[2]) do items[#items + 1] = { cat = cat, v = team[1], label = team[2] } end
      PairedLines(out, items)
    end
    return out
  end
  for n, section in ipairs(tab.sections) do
    if n > 1 then out[#out + 1] = { head = "" } end
    local items = { { cat = section.cat, all = true } }
    for _, option in ipairs(section.options) do
      items[#items + 1] = { cat = section.cat, v = option.v, option = option }
    end
    PairedLines(out, items)
  end
  return out
end

local function FilterFirstLine(lines, from, step)
  local k = from
  while lines[k] ~= nil do
    if lines[k].items ~= nil then return k end
    k = k + step
  end
  return nil
end

local function FilterSetTab(n)
  local W = S.filter_window
  W.tab, W.lines = n, FilterLines(FILTER.TABS[n])
  W.line, W.column, W.top = FilterFirstLine(W.lines, 1, 1) or 1, 1, 1
  S.dirty = true
end

local function FilterKeepVisible()
  local W = S.filter_window
  if W.line < W.top then W.top = W.line end
  if W.line >= W.top + FILTER.ROWS then W.top = W.line - FILTER.ROWS + 1 end
  -- a title just above the first visible line comes into view with it
  if W.top > 1 and W.lines[W.top - 1].head ~= nil and W.line < W.top + FILTER.ROWS - 1 then W.top = W.top - 1 end
end

local function FilterMove(d)
  local W = S.filter_window
  local k = FilterFirstLine(W.lines, W.line + d, d)
  if k == nil then return end
  W.line = k
  W.column = math.min(W.column, #W.lines[k].items)
  FilterKeepVisible()
  Snd(SY_MOVE)
  S.dirty = true
end

local function FilterSide(d)
  local W = S.filter_window
  local c = W.column + d
  if W.lines[W.line].items[c] == nil then return end
  W.column = c
  Snd(SY_MOVE)
  S.dirty = true
end

local function FilterTurnTab(d)
  local W = S.filter_window
  FilterSetTab((W.tab - 1 + d) % #FILTER.TABS + 1)
  Snd(SY_PAGE)
end

local function FilterToggle(item)
  local W = S.filter_window
  local category = FilterCategory(item.cat)
  if item.all then
    if FilterIsComplete(W.selection, category) then
      W.selection[item.cat] = {}
    else
      FilterSelectAll(W.selection, category)
    end
  elseif W.selection[item.cat][item.v] then
    W.selection[item.cat][item.v] = nil
  else
    W.selection[item.cat][item.v] = true
  end
  Snd(FILTER.SOUND_OK)
  FilterRefreshCount()
end

local function FilterToggleCursor()
  local W = S.filter_window
  FilterToggle(W.lines[W.line].items[W.column])
end

local function FilterTabCategories(tab)
  local out = {}
  for _, category in ipairs(S.filter_categories) do
    local of_tab = tab.teams == true and category.saga ~= nil
    for _, section in ipairs(tab.sections or {}) do
      of_tab = of_tab or section.cat == category.cat
    end
    if of_tab then out[#out + 1] = category end
  end
  return out
end

-- Every box of the tab on, or off when they already all are.
local function FilterToggleTab()
  local W = S.filter_window
  local categories = FilterTabCategories(FILTER.TABS[W.tab])
  local complete = true
  for _, category in ipairs(categories) do
    complete = complete and FilterIsComplete(W.selection, category)
  end
  for _, category in ipairs(categories) do
    if complete then W.selection[category.cat] = {} else FilterSelectAll(W.selection, category) end
  end
  Snd(FILTER.SOUND_OK)
  FilterRefreshCount()
end

local function FilterReset()
  for _, category in ipairs(S.filter_categories) do FilterSelectAll(S.filter_window.selection, category) end
  Snd(FILTER.SOUND_OK)
  FilterRefreshCount()
end

-- the album's lists and tabs under the filter in force
FilterApply = function()
  local t = VRFW.host.command(CMD.FILTER_SET, S.filter_spec or "")
  if type(t) == "table" and type(t.groups) == "table" then
    S.data.groups = t.groups
  else
    Log("filter not applied", tostring(t))
  end
end

local function FilterOpen()
  if S.task ~= nil or not S.ok or S.search ~= nil or S.filter_window ~= nil then
    Snd(SY_ERROR)
    return
  end
  if S.filter_info == nil then
    local t = VRFW.host.command(CMD.FILTER_INFO)
    if type(t) ~= "table" or type(t.sagas) ~= "table" then
      Log("no filter data", tostring(t))
      Snd(SY_ERROR)
      return
    end
    S.filter_info = t
    S.filter_categories = FilterCategories()
  end
  if S.filter_selection == nil then
    S.filter_selection = {}
    for _, category in ipairs(S.filter_categories) do FilterSelectAll(S.filter_selection, category) end
  end
  S.filter_window = { selection = FilterCopy(S.filter_selection), shown = 0 }
  FilterSetTab(1)
  FilterRefreshCount()
  if PlateExists() then VRFW.host.command(C.CLOSE_MENU, PLATE.MENU) end
  S.plate, S.hover = nil, nil
  Snd(FILTER.SOUND_OK)
end

local function FilterReopenPlate()
  local r = S.rows[S.sel]
  if r ~= nil then PlateOpen(r) end
  S.dirty = true
end

local function FilterAccept()
  S.filter_selection = S.filter_window.selection
  local spec = FilterSpec(S.filter_selection)
  S.filter_spec = spec ~= "" and spec or nil
  S.filter_window = nil
  FilterApply()
  S.group, S.page, S.sel = 1, 1, 1
  Snd(FILTER.SOUND_OK)
  LoadPage()
  FilterReopenPlate()
end

local function FilterCancel()
  S.filter_window = nil
  Snd(SY_BACK)
  FilterReopenPlate()
end

local FILTER_ACT = {
  filter = FilterAccept, select_key = FilterReset, accept = FilterToggleCursor, type_next = FilterToggleTab,
  up = function() FilterMove(-1) end, down = function() FilterMove(1) end,
  left = function() FilterSide(-1) end, right = function() FilterSide(1) end,
  group_prev = function() FilterTurnTab(-1) end, group_next = function() FilterTurnTab(1) end,
}

-- the pointer inside the window; a zone of any other kind lies under the window and is ignored
local function FilterPointer(z, ev)
  if z.kind == "filter_item" then
    local W = S.filter_window
    local line, column = math.floor(z.v / 10), z.v % 10
    if (ev.hover ~= nil or ev.click ~= nil) and (W.line ~= line or W.column ~= column) then
      W.line, W.column = line, column
      S.dirty = true
    end
    if ev.click ~= nil then FilterToggleCursor() end
  elseif ev.click ~= nil then
    if z.kind == "filter_tab" then
      FilterSetTab(z.v)
      Snd(SY_PAGE)
    elseif z.kind == "filter_ok" then
      FilterAccept()
    elseif z.kind == "filter_all" then
      FilterToggleTab()
    elseif z.kind == "filter_reset" then
      FilterReset()
    end
  end
end

local function DrawFilterButton()
  local x, y = P.x + P.width - 120, P.page_y - 22
  Quad(L.PLATE, FILTER.OPEN_BUTTON, "sort_base03", x, y, 120, 44)
  Quad(L.ICON, FILTER.OPEN_BUTTON, "icon_sort01", x + 18, y + 6, 48, 32)
  if not S.multi then Text(RetailText(FILTER.TEXT.KEY_ACCEPT), x + 68, y + 22, "head") end   -- Start recruits meanwhile
  Zone(x, y, 120, 44, "filter_open", 1)
  if S.filter_spec ~= nil then
    local state = RetailText(FILTER.TEXT.ACTIVE):gsub("^<[^>]+>", "")
    local plain = state:gsub("%[[^%]]*%]", "")
    Text(state, x - 14 - Units(plain) * 26 * GLYPH, P.page_y, "head")
  end
end

local function DrawFilterItem(item, cx, y, k, column)
  local W = S.filter_window
  Quad(L.FILTER_ICON, FILTER.ITEM, "icon_base01", cx - 16, y - 16, 32, 32)
  local on
  if item.all then
    on = FilterIsComplete(W.selection, FilterCategory(item.cat))
  else
    on = W.selection[item.cat][item.v] == true
  end
  if on then Quad(L.FILTER_ICON, FILTER.ITEM, "icon_check01", cx - 22, y - 16, 44, 32, 1) end
  local option, text_x = item.option, cx + 36
  if option ~= nil and option.sprite ~= nil then
    Quad(L.FILTER_ICON, option.tex, option.sprite, cx + 26, y - option.h / 2, option.w, option.h)
    text_x = cx + 26 + option.w + 10
  end
  local label = item.label
  if item.all then
    label = RetailText(FILTER.TEXT.ALL_ROW)
  elseif option ~= nil and option.text ~= nil then
    label = RetailText(option.text)
  end
  if label ~= nil then WindowText(Fit(label, 440, 28), text_x, y, "section") end
  Zone(cx - 40, y - 35, 520, 70, "filter_item", k * 10 + column)
  if k == W.line and column == W.column then
    local R = RETAIL.cursor
    local h = 44
    local w = h * R.w / R.h
    Quad(L.FILTER_ICON, R.tex, R.sprite, cx - 26 - w, y - h / 2, w, h, 2)
  end
end

local function DrawFilterButtons()
  local T, B = FILTER.TEXT, FILTER.OK
  Quad(L.FILTER_PLATE, FILTER.OK_BUTTON, "cmd_sub_btn_base01_on", B.x - 188, B.y - 42, 376, 84, 1)
  WindowText(RetailText(T.KEY_ACCEPT), B.x - 160, B.y, "section")
  WindowText(RetailText(T.ACCEPT), B.x - 100, B.y, "section")
  Zone(B.x - 188, B.y - 42, 376, 84, "filter_ok", 1)
  B = FILTER.ALL
  Quad(L.FILTER_PLATE, FILTER.ALL_BUTTON, "button_base01_off", B.x - 264, B.y - 28, 264, 56, 1)
  WindowText(RetailText(T.KEY_ALL), B.x - 236, B.y, "section")
  WindowText(RetailText(T.ALL_BUTTON), B.x - 177, B.y, "section")
  Zone(B.x - 264, B.y - 28, 264, 56, "filter_all", 1)
  B = FILTER.RESET
  Quad(L.FILTER_PLATE, FILTER.RESET_BUTTON, "button_base02_off", B.x, B.y - 28, 284, 56, 1)
  WindowText(RetailText(T.KEY_RESET), B.x + 26, B.y, "section")
  WindowText(RetailText(T.RESET), B.x + 79, B.y, "section")
  Zone(B.x, B.y - 28, 284, 56, "filter_reset", 1)
end

local function DrawFilterWindow()
  local W = S.filter_window
  local tab = FILTER.TABS[W.tab]
  Quad(L.FILTER_PLATE, FILTER.WINDOW, "win_filter_base01", 330, 90, 1260, 900)
  Quad(L.FILTER_PLATE, FILTER.WINDOW, tab.symbol, 662, 247, 884, 604, 1)
  Quad(L.FILTER_PLATE, FILTER.WINDOW, "gtxt_filter01", 368, 110, 292, 80, 1)
  local tabs = #FILTER.TABS
  local first_x = FILTER.TAB_X - FILTER.TAB_GAP * (tabs - 1) / 2
  for n, t in ipairs(FILTER.TABS) do
    local cx = first_x + FILTER.TAB_GAP * (n - 1)
    Quad(L.FILTER_ICON, FILTER.TAB_BASE, "icon_base01", cx - 46, FILTER.TAB_Y - 26, 92, 52)
    Quad(L.FILTER_ICON, FILTER.TABS_ART, t.icon .. (n == W.tab and "" or "_off"), cx - 36, FILTER.TAB_Y - 24, 72, 48, 1)
    Zone(cx - 46, FILTER.TAB_Y - 26, 92, 52, "filter_tab", n)
  end
  local keys = Tx("KeysGroup")
  WindowText(keys:match("^(<[^>]+>)") or "", first_x - FILTER.TAB_GAP + 16, FILTER.TAB_Y, "section")
  WindowText(keys:match("(<[^>]+>)$") or "", first_x + FILTER.TAB_GAP * tabs - 30, FILTER.TAB_Y, "section")
  WindowTextCentred(RetailText(tab.title), FILTER.TAB_X, FILTER.TAB_Y + 54, "section", 28)
  local last = math.min(#W.lines, W.top + FILTER.ROWS - 1)
  for k = W.top, last do
    local y = FILTER.ROW_Y + (k - W.top) * FILTER.ROW_STEP
    local line = W.lines[k]
    if line.head ~= nil then
      Quad(L.FILTER_PLATE, FILTER.HEAD, "line01", FILTER.COLUMN[1] + 32, y + 12, 938, 4, 1)
      WindowText(Fit(line.head, 900, 28), FILTER.COLUMN[1] - 47, y - 8, "section")
    else
      for column, item in ipairs(line.items) do DrawFilterItem(item, FILTER.COLUMN[column], y, k, column) end
    end
  end
  if #W.lines > FILTER.ROWS then
    local thumb = math.max(32, 506 * FILTER.ROWS / #W.lines)
    local offset = (506 - thumb) * (W.top - 1) / (#W.lines - FILTER.ROWS)
    Quad(L.FILTER_PLATE, FILTER.WINDOW, "scr_line02", 1502, 265, 28, 506, 1)
    Quad(L.FILTER_ICON, FILTER.WINDOW, "scr_obj02", 1502, 265 + offset, 28, thumb, 1)
  end
  DrawFilterButtons()
  Quad(L.FILTER_PLATE, FILTER.WINDOW, "base_person01", 1318, 896, 184, 40, 1)
  WindowText(W.shown .. " / " .. S.filter_info.total, 1370, 916, "section")
end

local function Draw()
  BeginFrame()
  if S.ready and S.ok then
    DrawSelection()
    DrawTypes()
    DrawGroups()
    if #S.rows == 0 then
      Text(Tx(S.filter_spec ~= nil and "FilterEmpty" or "Empty"), P.x + 40, P.top + P.row_h / 2, "head")
    end
    for k, r in ipairs(S.rows) do DrawRow(r, k) end
    -- the page counter between its two key glyphs
    local keys, cx = Tx("KeysPage"), P.x + P.width / 2
    local count = Fill(Tx("Page"), S.page, S.pages)
    TextC(count, cx, P.page_y, "head", 26)
    local half = Units(count) * 26 * GLYPH / 2 + 14
    local left, right = keys:match("^(<[^>]+>)"), keys:match("(<[^>]+>)$")
    local lw, rw = Units(left or "") * 26 * GLYPH, Units(right or "") * 26 * GLYPH
    Text(left, cx - half - lw, P.page_y, "head")
    Text(right, cx + half, P.page_y, "head")
    Zone(cx - half - lw - 10, P.page_y - 22, lw + 20, 44, "page", -1)
    Zone(cx + half - 10, P.page_y - 22, rw + 20, 44, "page", 1)
    local r = S.rows[S.sel]
    if r ~= nil and not r.owned and S.first_page ~= false then
      local s = r.lock and LockText(r) or Tx("NotOwned")
      local w = Units(s) * 28 * GLYPH + 2 * BAND_CAP + 20
      Band(P.badge_x - w, P.badge_y, w, P.badge_h)
      TextC(s, P.badge_x - w / 2, P.badge_y + P.badge_h / 2 + 1, "section", 28)
    end
    GuideZones()
    DrawHover()
    if S.search == nil then DrawFilterButton() end
    if S.filter_window ~= nil then DrawFilterWindow() end
  elseif S.ready then
    Text(Tx("NoSave"), P.x + 40, P.top, "head")
  end
  EndFrame()
end

local function Move(d)
  local n = #S.rows
  if n == 0 then return end
  local s = math.max(1, math.min(n, S.sel + d))
  if s == S.sel then return end
  S.sel = s
  Snd(SY_MOVE)
  S.dirty = true
  SetLine()
  PlateShow()
end

local function TurnPage(d)
  if S.pages <= 1 then
    Snd(SY_ERROR)
    return
  end
  S.page = (S.page - 1 + d) % S.pages + 1
  Snd(SY_PAGE)
  LoadPage()
end

local function Group(d)
  local n = #Groups()
  if n <= 1 or S.search ~= nil then
    Snd(SY_ERROR)
    return
  end
  S.group = (S.group - 1 + d) % n + 1
  S.page, S.sel = 1, 1
  Snd(SY_PAGE)
  LoadPage()
end

local function Kind(d)
  if S.search ~= nil then
    Snd(SY_ERROR)
    return
  end
  local n = S.data and #S.data.groups or 0
  if n <= 1 then return end
  S.kind = (S.kind - 1 + d) % n + 1
  S.group, S.page, S.sel = 1, 1, 1
  Snd(SY_PAGE)
  LoadPage()
end

local function Side(d)
  local n = #S.rows
  local col, row = math.floor((S.sel - 1) / P.rows), (S.sel - 1) % P.rows
  local c = col + d
  if n > 0 and c >= 0 and c < P.cols then
    local k = c * P.rows + row + 1
    if k > n and n > c * P.rows then k = n end
    if k <= n then
      S.sel = k
      Snd(SY_MOVE)
      S.dirty = true
      SetLine()
      PlateShow()
      return
    end
  end
  if S.pages <= 1 then
    Snd(SY_ERROR)
    return
  end
  S.sel = (d > 0 and 0 or P.cols - 1) * P.rows + row + 1
  TurnPage(d)
end

local function Select(k)
  if k == S.sel or S.rows[k] == nil then return end
  Move(k - S.sel)
end

local function SetKind(k)
  if k ~= S.kind then Kind(k - S.kind) end
end

local function SetGroup(k)
  if k ~= S.group then Group(k - S.group) end
end

local function BarTurn(d)
  local gl = Groups()
  local want = BarPage(gl, S.group) + d
  for k = 1, #gl do
    if BarPage(gl, k) == want then return SetGroup(k) end
  end
end

local Accept, OpenSearch, MultiToggle, RecruitMarked

local function PointerStep()
  local ev = S.ptr.poll()
  if ev.changed then
    local h = ev.hot ~= nil and S.zones[ev.hot] or nil
    local lit = (S.filter_window == nil and h ~= nil and HOVER_LIT[h.kind]) and ev.hot or nil
    if lit ~= S.hover then
      S.hover = lit
      S.dirty = true
    end
  end
  local z = ev.hot ~= nil and S.zones[ev.hot] or nil
  if z == nil then return nil end
  if S.filter_window ~= nil then
    FilterPointer(z, ev)
    return nil
  end
  if z.kind == "filter_open" then
    if ev.click ~= nil then FilterOpen() end
    return nil
  end
  if z.kind == "row" then
    if ev.hover == nil and ev.click == nil then return nil end
    local was = S.sel
    Select(z.v)
    if ev.click ~= nil and was == z.v then Accept(true) end
  elseif ev.click ~= nil then
    if z.kind == "type" then SetKind(z.v)
    elseif z.kind == "type_key" then Kind(z.v)
    elseif z.kind == "group" then SetGroup(z.v)
    elseif z.kind == "group_key" then Group(z.v)
    elseif z.kind == "bar_page" then BarTurn(z.v)
    elseif z.kind == "page" then TurnPage(z.v)
    elseif z.kind == "guide" then
      if z.v == "search" then OpenSearch()
      elseif z.v == "multi" then MultiToggle()
      elseif z.v == "recruit_marked" then RecruitMarked()
      else Accept(true) end
    end
  end
  return nil
end

local function Unmark(param)
  if S.marks[param] == nil then return end
  S.marks[param] = nil
  S.marked = S.marked - 1
end

-- the album read again after the club changed
local function ReloadClub()
  Load()
  if S.ok then
    if S.search ~= nil then VRFW.host.command(CMD.SEARCH, S.search.text) end
    LoadPage()
  end
end

-- What an album action's full-screen presentation needs around it (VRFW.summon_presentation), run on a black screen:
-- the plate closes (a suspended plate never releases its 3D model), the page and the Caseta are not drawn, then the reverse.
local ACTION_PAGE = {
  before_presentation = function()
    if PlateExists() then VRFW.host.command(C.CLOSE_MENU, PLATE.MENU) end
    local frames = 0
    while PlateExists() and frames < PLATE.WAIT do
      frames = frames + 1
      coroutine.yield()
    end
    S.plate = nil
    ParamClear(PLATE.FLAG)
    ParamClear(PLATE.CARD)
    ParamClear(PLATE.CARD_TEAM)
    M(C.HIDE_MENU, 1, CASETA.MENU)
    M(C.HIDE_MENU, 1, Crc("betterqol_album_menu"))
    -- hiding the menu does not stop the page's own layers being drawn: an empty frame hides every quad, text and face
    BeginFrame()
    EndFrame()
    M(C.VISIBLE, L_LINE, 0, false)
    VRFW.host.command(CASETA.CROSS_CALL, CASETA.MENU, GUIDE.REFRESH_NAME, S.multi, true)
  end,
  -- signed = the cards signed from the marks, when there were marks
  after_presentation = function(signed)
    M(C.SHOW_MENU, Crc("betterqol_album_menu"))
    M(C.SHOW_MENU, CASETA.MENU)
    M(C.VISIBLE, L_LINE, 0, true)
    VRFW.host.command(CASETA.CROSS_CALL, CASETA.MENU, GUIDE.REFRESH_NAME, S.multi)
    for _, param in ipairs(type(signed) == "table" and signed or {}) do Unmark(param) end
    local many = Page.album_action("RunMany", "function")
    if S.multi and many ~= nil then S.balance = many.Balance() end
    ReloadClub()
    S.reloaded = true
    local drawn, why = pcall(Draw)
    if not drawn then Log("draw error", tostring(why)) end
    S.dirty = true                 -- once more when the task ends: faces and textures are still arriving
    local r = S.rows[S.sel]
    if r == nil then return end
    PlateOpen(r)
    while S.plate ~= nil and S.plate.state == "opening" do coroutine.yield() end
  end,
}

-- only a player the club lacks can be marked, up to what the album action can sign at once
local function ToggleMark(r)
  if S.marks[r.param] ~= nil then
    Unmark(r.param)
    Snd(SY_MOVE)
  else
    local a = Page.album_action("RunMany", "function")
    if a == nil or r.owned or r.lock or r.param == 0 or S.marked >= a.MarkLimit() then
      Snd(SY_ERROR)
      return
    end
    S.marked, S.marked_seq = S.marked + 1, S.marked_seq + 1
    S.marks[r.param] = { base = r.base, param = r.param, name = r.name, owned = r.owned, level = r.level, rarity = r.rarity,
      count = r.extra ~= nil and r.extra.count or 0, seq = S.marked_seq }
    Snd(SY_PAGE)
  end
  S.dirty = true
  SetLine()
end

Accept = function(by_pointer)
  if S.task ~= nil then return end
  if not by_pointer and S.ptr.owns() then return end      -- the pointer's click handles it
  local r = S.rows[S.sel]
  if r == nil then return end
  if S.multi then
    ToggleMark(r)
    return
  end
  if r.lock then
    Snd(SY_ERROR)
    return
  end
  local a = Page.album_action("Run", "function")
  if a == nil then return end
  local row = { base = r.base, param = r.param, name = r.name, owned = r.owned, level = r.level, rarity = r.rarity }
  S.task = coroutine.create(function() return a.Run(row, ACTION_PAGE) end)
  Log("action", tostring(a.id), "param", r.param)
end

local function TaskStep()
  if S.task == nil then return end
  local ok, changed = coroutine.resume(S.task)
  if not ok then
    Log("action error", tostring(changed))
    M(VRFW.commands.SET_INPUT_ENABLE_MENU_OBJECT, Crc("betterqol_album_menu"), true)   -- a failed search left the input off
  end
  if ok and coroutine.status(S.task) ~= "dead" then return end
  S.task = nil
  S.ptr.reset()                    -- a button still held from the windows is no click
  S.dirty = true                   -- the reset dropped the pointer zones, and only a drawing builds them
  if ok and changed == true and not S.reloaded then ReloadClub() end
  S.reloaded = nil
end

-- Back to the tab, page and row the search came from.
local function ClearSearch()
  local b = S.before
  S.search, S.before = nil, nil
  S.kind, S.group, S.page, S.sel = b.kind, b.group, b.page, b.sel
  LoadPage()
end

local function ApplySearch(query, text)
  if query == "" then
    if S.search ~= nil then ClearSearch() end
    return
  end
  if S.search ~= nil and S.search.query == query then return end
  local found = VRFW.host.command(CMD.SEARCH, text)
  found = tonumber(found) or 0
  Log("search", query, "found", found)
  if found == 0 then
    BetterQoL.text_search.refuse()
    return
  end
  S.before = S.before or { kind = S.kind, group = S.group, page = S.page, sel = S.sel }
  S.search = { text = text, query = query }
  S.kind, S.group, S.page, S.sel = KIND_SEARCH, 1, 1, 1
  LoadPage()
end

-- S.task stays set one frame after the input is back, so the key that closed the entry is not seen
local function SearchTask()
  local title = Crc("BetterQoL.Album.SearchTitle")
  if not BetterQoL.text_search.run(Crc("betterqol_album_menu"), title, S.search and S.search.text or "", ApplySearch) then
    Log("text entry did not open")
  end
  coroutine.yield()
  return false
end

OpenSearch = function()
  if S.task ~= nil or not S.ok then return end
  S.task = coroutine.create(SearchTask)
end

-- the footer lives in the Caseta's menu; its entries take their places on the next frame, so the pointer zones are redrawn then
local function SetMulti(on)
  S.multi = on
  VRFW.host.command(CASETA.CROSS_CALL, CASETA.MENU, GUIDE.REFRESH_NAME, on)
  S.dirty, S.redraw_at = true, S.frame + 1
  SetLine()
end

-- X: leaves the marks in place, so a filter (Start, outside the mode) can be used between two rounds of marking
MultiToggle = function()
  if S.task ~= nil or not S.ok then return end
  local a = Page.album_action("RunMany", "function")
  if a == nil then return end
  S.balance = a.Balance()
  Snd(SY_PAGE)
  SetMulti(not S.multi)
end

RecruitMarked = function()
  if S.task ~= nil then return end
  local a = Page.album_action("RunMany", "function")
  if a == nil or S.marked == 0 then
    Snd(SY_ERROR)
    return
  end
  local rows = {}
  for _, m in pairs(S.marks) do rows[#rows + 1] = m end
  table.sort(rows, function(x, y) return x.seq < y.seq end)
  S.task = coroutine.create(function()
    return (a.RunMany(rows, ACTION_PAGE))
  end)
  Log("recruit marked", #rows)
end

local ACT = {
  select_key = OpenSearch, multi = MultiToggle,
  filter = function()
    if S.multi then RecruitMarked() else FilterOpen() end
  end,
  accept = function() Accept(false) end,
  up = function() Move(-1) end, down = function() Move(1) end,
  left = function() Side(-1) end, right = function() Side(1) end,
  type_prev = function() Kind(-1) end, type_next = function() Kind(1) end,
  group_prev = function() Group(-1) end, group_next = function() Group(1) end,
  plate_prev = function() PlatePage(-1) end, plate_next = function() PlatePage(1) end,
}

local DIAG_MAX = 12
local function Diag(kind, a1, a2)
  local d = S.diag
  if d == nil then return end
  Bind()
  d[kind] = (d[kind] or 0) + 1
  if a1 == Page.ANCHOR.LAYER or d[kind] <= DIAG_MAX then
    Log("diag:", kind, d[kind], "layer", a1, "inst", a2, a1 == Page.ANCHOR.LAYER and "(anchor)" or "")
  end
end

function OnInit()
  Bind()
  S.diag = {}
  S.ready, S.ok, S.frame, S.dirty, S.plate, S.line, S.task = false, false, 0, true, nil, nil, nil
  S.search, S.before, S.hover = nil, nil, nil
  S.multi, S.marks, S.marked, S.marked_seq, S.balance, S.redraw_at = false, {}, 0, 0, 0, nil
  S.filter_window, S.filter_info, S.filter_categories, S.filter_selection, S.filter_spec = nil, nil, nil, nil, nil
  S.kind, S.group, S.page, S.sel, S.rows, S.zones = KIND_GAME, 1, 1, 1, {}, {}
  S.loaded, S.face_queue, S.face_next, S.face_sig, S.face_key = {}, {}, 1, {}, {}
  S.ptr = VRFW.pointer.new()
  S.ptr.reset()                    -- a button held from the Caseta's Accept is no click
  Kit = VRFW.screen_kit.new({ tex_ready = TexReady })
  S.texts = {}
  if VRFW.face_icon ~= nil then VRFW.face_icon.forget(L.FACE) end
  S.crests, S.first_page, S.kits = {}, true, {}
  Load()
end

function OnSetupLayer(a1, a2)
  Bind()
  Diag("setup", a1, a2)
  if a1 == L_BACKDROP then
    M(C.VISIBLE, a1, a2, false)          -- until the plate is up (Cover)
    S.cover = false
  elseif a1 == L_LINE then
    S.line = nil
    SetLine()
  elseif Page.setup_layer(Kit, L, a1, a2) then
    if a1 == L.FACE then S.face_sig[a2] = nil end
    S.dirty = true
  end
end

function OnOpenLayer(a1, a2)
  Diag("open", a1, a2)
  if Page.open_layer(Kit, L, a1, a2) then
    Log("diag: anchor open, pools", Kit.caps[L.PLATE], Kit.caps[L.ICON], Kit.caps[L.FACE], Kit.caps[L.TEXT], Kit.caps[L.CREST])
    S.ready = true
    if S.ok then
      LoadPage()
      local r = S.rows[S.sel]
      if r ~= nil then PlateOpen(r) end
    end
    S.dirty = true
  end
end

function OnFunction(a1, a2)
  local act = FN[a2] or FN[a1]
  if act == nil or not S.ready or S.task ~= nil then return end
  if S.filter_window ~= nil then
    local handler = FILTER_ACT[act]
    if handler ~= nil then handler() end
    return 1
  end
  ACT[act]()
  return 1
end

function OnBack(a1)
  if S.task ~= nil then return 1 end
  if S.filter_window ~= nil then
    FilterCancel()
    return 1
  end
  if S.search ~= nil then
    Snd(SY_BACK)
    ClearSearch()
    return 1
  end
  if S.multi then
    Snd(SY_BACK)
    S.marks, S.marked = {}, 0
    SetMulti(false)
    return 1
  end
  Cover(false)
  if PlateExists() then VRFW.host.command(C.CLOSE_MENU, PLATE.MENU) end
  pcall(ParamClear, PLATE.CARD)
  pcall(ParamClear, PLATE.CARD_TEAM)
  Log("page closed")
end

function Step()
  S.frame = S.frame + 1
  if S.diag ~= nil and not S.diag.step then
    S.diag.step = true
    Log("diag: first step, ready", tostring(S.ready), "ok", tostring(S.ok), "rows", #S.rows)
  end
  if not S.ready then return end
  PlateStep()
  FaceStep()
  if (S.extra_retries or 0) > 0 then LoadRowExtras() end
  if S.task ~= nil then
    TaskStep()
    return
  end
  local wheel = Page.wheel()
  if wheel ~= 0 then
    if S.filter_window ~= nil then FilterMove(wheel) else Move(wheel) end
  end
  PointerStep()
  -- drawn when something changed, and again while a texture or crest is still loading
  if S.redraw_at ~= nil and S.frame >= S.redraw_at then S.dirty, S.redraw_at = true, nil end
  if S.dirty then S.wait_until = S.frame + WAIT_FRAMES end
  if S.dirty or ((S.waiting or Kit.waiting) and S.frame < (S.wait_until or 0)) then
    S.dirty = false
    local ok, err = pcall(Draw)
    if not ok then Log("draw error", tostring(err)) end
    if S.diag ~= nil and not S.diag.drawn then
      S.diag.drawn = true
      Log("diag: first draw, rows", #S.rows, "page", S.page, "of", S.pages, "textures waiting", tostring(S.waiting),
        tostring(Kit.waiting))
    end
  end
end
