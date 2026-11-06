-- util_album_menu (plain Lua 5.2 source): BetterQoL's «Álbum de jugadores» page. Declared in content\menus\album.toml
-- ([[screen]], served as common/script/lua/menu/util_album_menu.lua.bin). Opened from «Caseta del club»
-- (play_guide_top_menu, assets\lua\play_guide_top_menu\155_album.lua) the way that menu opens its «Archivo de
-- escenas»: the Caseta keeps its header (title «Álbum de jugadores»), its button guide and its return arrow (its
-- background is hidden while this page is up: this page has its own, util_alb_backdrop, drawn before the 3D pass);
-- this page draws the LEFT half over them:
--   * the type row: Y at the left end, «Nombre» / «Juego» right of it;
--   * the group row: LB / RB at the ends, the groups between them (the game's series tab icons, or letter ranges);
--     a mod category's `page` = its own page of the bar («<» / «>» in the strip's end caps; LB / RB cross pages);
--   * two columns of 10 rows (down the first, then the second), each row the
--     game's check box (ticked = the club has the player), his kit miniface and his name; «Página N/M» under them;
-- and opens the game's player plate (personal_plate_menu) on the RIGHT half in its players-universe mode (a card id,
-- a level and a rarity, as the game's pack list chara_pack_probability_list_menu does): the selected player as his
-- base card at the level cap in effect (scripts/album.lua), the «No lo tienes» badge under it when the club does not
-- have him. The plate keeps its own menu inactive in that mode; this page turns its pages (L2 / R2). Its 3D model:
-- Character Reforged's plate model on its normal menu-camera layer, drawn over this page's background-pass backdrop
-- as the transfer office's model over shop01_00_background; it follows the plate's player (built per selection,
-- swapped in place, released with the plate). Keys (cmd rows of the off-screen anchor row -> OnFunction / OnBack): up
-- / down move, left / right the other column of the same row (from the right column a right goes to the next page's
-- left column, from the left column a left to the previous page's right column; the pages wrap), Y the type, LB / RB
-- the group, L2 / R2 the plate's pages, B / Esc / right click close (the engine closes the page; the plate is asked
-- to close here and by the opener). Mouse / free cursor: the zones of the drawn rows, type and group tabs, the group
-- keys, the page arrows and the guide's A and X entries (hover selects a row when the pointer moves and lights any
-- other zone, a click picks; a click on the selected row = A), the wheel moves. A: the selected player's action of another mod, BetterQoL.AlbumActions: the first entry whose
-- On holds runs Run(row) as a coroutine resumed from Step (it may open the game's message windows); keys and the
-- pointer wait while it runs; when it answers true (the club changed) the album data is read again. An entry's optional
-- RowExtras(rows) gives what its mod shows at the right edge of the rows: asked once per page load, never per draw
-- ({ [row index] = { text, atlas, sprite } }; nil = no answer yet: asked again for at most EXTRA_RETRIES frames). X: the player
-- search (BetterQoL.TextSearch, the shop search's text entry; the pass is CMND_BETTERQOL_ALBUM_SEARCH, once per
-- confirmed text over the names already loaded): the results are one list under every letter, the group bar shows
-- the search and the type and group keys buzz; B clears it back to the tab, page and row it came from, an empty
-- text too; no match buzzes and leaves the list as it was. Data: BetterQoL's
-- scripts\album.lua (CMND_BETTERQOL_ALBUM_OPEN when the page opens, CMND_BETTERQOL_ALBUM_PAGE on each page / group /
-- type change). Drawing only when something changed; the plate follows the row once the selection rests; minifaces
-- are asked a few per frame. No engine call at load time.
INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_PROG_COMMON")

local CMD = { OPEN = 3117903358 --[[CMND_BETTERQOL_ALBUM_OPEN]], PAGE = 162355322 --[[CMND_BETTERQOL_ALBUM_PAGE]],
  SEARCH = 503101643 --[[CMND_BETTERQOL_ALBUM_SEARCH]] }
local C = {
  LOG = 3661580131, TEXT_GET = 4074371074, LANG = 477234096, SND = 3073642526,
  LAYER_NUM = 1175615627, OPEN_LAYER = 629267548, VISIBLE = 711242136, POS = 1389957207, SCALE = 3778714801,
  SPRITE = 558735651, ALPHA = 4231609516, MESH_VISIBLE = 3405944500, NODE_VISIBLE = 2158717427,
  TEXT_VISIBLE = 2735666188, SET_TEXT = 1083631230, LOAD_TEX = 839427544, TEX_LOADING = 1506186496,
  RESET_FACE = 4176779611,
  TEXT_STYLE = 2333948100, CTRL = 3518307824, LIST_NUM = 3252599449, FOCUS_SET = 3466097042,
  ATTACH_TRACE = 1774843228, CHARA_INFO = 4060384944,
  GET_PRIO = 1018283794 --[[CMND_GET_DRAW_PRIORITY]], SET_PRIO = 1491630496 --[[CMND_SET_DRAW_PRIORITY]],
  OPEN_MENU = 433545986, CLOSE_MENU = 320421347, IS_MENU = 2231168902, IS_OPEN_MENU = 3693934564,
}
-- the page's layers (content\menus\album.toml)
local L = { PLATE = 4160871141, ICON = 699561794, FACE = 1228023294, TEXT = 2007890270, CREST = 1300171250 }
local L_ANCHOR = 3455690937        -- save01_02_list_item: the input anchor (1 instance, off screen)
local L_LINE = 3078308064          -- mainmenu90_05_content_guide_line01
-- the page's background (util_alb_backdrop, drawn before the 3D pass): shown only while the player plate (and its 3D
-- model) is up, in the same step as the Caseta's background is hidden (Cover); hidden again on close in the same step
-- as the Caseta's comes back, so the transition shows the Caseta's own background
local L_BACKDROP = 4045471075
local CASETA = { MENU = 1281873114 --[[play_guide_top_menu]], CROSS_CALL = 830228314 --[[(menu, global function, ...)]],
  BACKGROUND = "BetterQoL_AlbumCasetaBackground" }
-- the Caseta's button guide: one row instance per entry, its glyph node (layout units, y up, top-left of the glyph)
local GUIDE = { BUTTON = 9396745 --[[mainmenu01_07_button_guide]], GLYPH = 950238781 --[[_text_btn01]], GLYPH_W = 50,
  GAP = 16, TEXT_PX = 26, SEARCH_TEXT = 2214150166 --[[betterqol_technique_search]] }
local LINE_TEXT = 378156699        -- _text_guide01
local ANCHOR = {
  TEXTS = { 931545948 --[[_text_list01_on]], 3705682548 --[[_text_list01_off]] },
  CURSOR = 3313461902,             -- the «cursor» locator
}
-- the anchor's functions (cmd rows: crc32 of the names)
local FN = {
  [3533807059] = "up", [1356451490] = "down", [910277105] = "left", [1029011626] = "right",
  [4230302454] = "type_prev", [1156108959] = "type_next", [3559612738] = "group_prev", [1827076395] = "group_next",
  [2512251038] = "plate_prev", [762343671] = "plate_next", [2674977970] = "accept",
  [2560678433] = "search",
}
local TXT = { NODE = 378327766 --[[_text_cmd_back01]], MESHES = {298211823, 2853207670}, BOX_LEFT = -384, BOX_W = 384, BOX_MID_Y = 144 }
-- the player plate the page opens (personal_plate_menu, players-universe mode: personal_plate_menu OnInit)
local PLATE = {
  MENU = 1427722143 --[[personal_plate_menu]], PAGE = 878737202 --[[team11_01_personal_plate]],
  P_PARAM = 3928123478, P_LEVEL = 3894267099, P_RARITY = 571278276,
  FLAG = 2398708549 --[[BetterQoL.album_plate: set while this page shows the plate (assets\lua\personal_plate_menu\135_album_pages.lua)]],
  SET = 1101551215 --[[(param, level, rarity, false): the plate's player]],
  PAGE_PREV = 567813453, PAGE_NEXT = 2019940505, PAGE_UPDATE = 3297841487,
  RARITY_DEFAULT = 4, WAIT = 180,
  -- frames the selection rests before the plate shows it, when it moved less than this ago (a whole plate refresh per
  -- row crossed is the page's dearest work); a move after a longer rest shows at once
  REST = 8,
  -- VRFW.plate_card: the card the plate shows, so the plate's 3D model wears that card's own team kit (the
  -- VR-Framework's VRFW_PlateMember.Kit: CMND_VRFW_CONTACT_KIT, as the transfer office's contact map); cleared on close
  CARD = 2716223290,
  -- VRFW.plate_card_team: the team that dresses that card (a mod category's own team, BetterQoL.Album.Page); cleared
  -- when the row has none and on close
  CARD_TEAM = 1860450077,
}
local SY_MOVE, SY_PAGE, SY_ERROR, SY_BACK = 2500047763, 2629173176 --[[sy0009]], 2086672038, 202039849
local GLYPH = 0.5
local STYLE = {
  section = "fs2_26_w_lc_2d2_001_nr", tab = "fs_28_b_lc_2d0_001", name = "fs_28_b_lc_2d0_001",
  bar = "fs_28_w_cc_2d2_001",          -- white, centred: the group labels on the tab bar
  head = "fs2_26_w_lc_2d2_001_nr",   -- on the page's background: outlined white (the page counter, the empty list)
}
-- the page (screen px at 1080p, y down): the left half under the Caseta's header (0-145), above its content guide
-- line (913); the plate's half from plate_x; the «No lo tienes» badge under the plate
local P = { x = 60, width = 900, type_y = 168, type_h = 44, tabs_y = 206, tab_h = 58, tab_gap = 4, key_w = 46,
  band_y = 274, band_h = 40, top = 280, cols = 2, rows = 10, row_h = 50, row_gap = 4, col_gap = 14, box = 32,
  mark = 44, face = 50, extra_icon = 25, extra_gap = 2, extra_unit = 12, box_body = 114, box_gap = 8, box_pad = 10, name_pad = 22,
  extra_scale = 0.75, name_scale = 0.95, name_min = 0.78, name_unit = 15.5, box_x = 30, band_text_x = 36, band_right = 70, band_count_w = 260, crest = 34, page_y = 878, badge_x = 1880, badge_y = 912, badge_h = 44 }
P.col_w = math.floor((P.width - P.col_gap) / 2)
-- the row plate's art (the album_row_* / album_focus_* slices of the atlas, research/scripts/club_stats_art.py: the retail
-- list plate redrawn with antialiased slanted edges, 50 px high = P.row_h): the slice width at each end, the body's left
-- edge at its top (the slant goes left going down by `slant`), the body's right edge's distance from the plate's end
local ROW = { cap = 32, left = 26.125, right = 11, slant = 15.125 }
local PER_PAGE = P.cols * P.rows
local ART, SPRITE = "#/menu/220_img/util_club_stats/util_club_stats.g4tx", "util_club_stats_"
local RETAIL = {
  list = { tex = "#/menu/51_save/save01/save01_02/save01_02.g4tx",
           off = "list_base_s01_off", focus = "list_base_s01_ol" },
  cursor = { tex = "#/menu/20_cmn/cmn05/cmn05_01/cmn05_01.g4tx", sprite = "cur01", w = 128, h = 152 },
  check = { tex = "#/menu/102_team/team16/team16_03/team16_03.g4tx", box = "icon_check_box01", mark = "icon_list_check01" },
  tabs = { tex = "#/menu/200_icon/16_icon_list_tab/<LG>/icon_list_tab.g4tx", w = 144, h = 96 },
  -- the game's list tab bar (free-match rival list): the strip with its dark end caps and its blue part, the bright
  -- block under the focused tab. The strip comes in two retail widths (narrow caps = a wider blue part for more tabs);
  -- per variant: the blue part's top-left / top-right corner x at band_t (sprite px, 1036 x 76); every blue edge
  -- slants left going down by `slant` px per sprite row, as the caps' edges do
  strip = { tex = "#/menu/20_cmn/cmn06/cmn06_01/cmn06_01.g4tx", w = 1036, h = 76, band_t = 14, band_b = 62,
            slant = 8 / 42, tab_aspect = 1.5,
            variants = { { sprite = "list_tab_base01", left = 162, right = 882 },
                         { sprite = "list_tab_base01_02", left = 122, right = 922 } } },
  -- the focus block's visible parallelogram in its sprite (92 x 52): at mid height it spans mid_l .. mid_r
  focus = { tex = "#/menu/20_cmn/cmn06/cmn06_20/cmn06_20.g4tx", sprite = "icon_base01", w = 92, h = 52,
            mid_l = 5, mid_r = 85 },
}
local KIND_NAME, KIND_GAME, KIND_TEAM, KIND_SEARCH = 1, 2, 3, 4   -- KIND_SEARCH: the results of the player search
local WAIT_FRAMES = 300            -- frames a change keeps redrawing while textures / crests still load
local FACES_A_FRAME = 5            -- minifaces asked per frame after a drawing
local EXTRA_RETRIES = 30           -- frames a row extra provider that did not answer is asked again
-- the zones lit under the pointer (a row takes the selection instead; the guide entries have the guide's own look)
local HOVER_LIT = { type = true, type_key = true, group = true, group_key = true, bar_page = true, page = true }
local HOVER_ALPHA = 0.5

-- state of this opening
local S = { ready = false, ok = false, kind = KIND_GAME, group = 1, page = 1, pages = 1, sel = 1, data = nil,
  rows = {}, total = 0, owned = 0, texts = {}, loaded = {},
  dirty = true, frame = 0, plate = nil, line = nil, zones = {}, ptr = {},
  face_queue = {}, face_next = 1, face_sig = {}, face_key = {} }

-- ---- helpers (this menu has its own VM) ------------------------------------------------------------------------------
local function Crc(text)
  return VRFW_Id.Crc(text)
end

local function Log(...)
  local p = {}
  for i = 1, select("#", ...) do p[#p + 1] = tostring((select(i, ...))) end
  pcall(funcLuaCommand, C.LOG, "betterqol album " .. table.concat(p, " "))
end

-- a text of text/rows/album.toml (id "BetterQoL.Album.<name>"), in the game's language
local function Tx(name)
  local t = S.texts[name]
  if t == nil then
    local ok, s = pcall(funcLuaCommand, C.TEXT_GET, Crc("BetterQoL.Album." .. name))
    t = (ok and type(s) == "string" and s ~= "") and s or name
    S.texts[name] = t
  end
  return t
end

-- the same, but an empty text stays empty (the name groups: empty = one group with every name)
local function TxRaw(name)
  local ok, s = pcall(funcLuaCommand, C.TEXT_GET, Crc("BetterQoL.Album." .. name))
  return (ok and type(s) == "string") and s or ""
end

local function Fill(s, a, b)
  s = tostring(s):gsub("{1}", function() return tostring(a) end)
  return (s:gsub("{2}", function() return tostring(b) end))
end

local function M(cmd, ...)
  local ok, a, b = pcall(funcLuaMenuCommand, cmd, ...)
  if ok then return a, b end
  return nil
end

local function Snd(s) pcall(funcLuaCommand, C.SND, s) end

-- ---- drawing pools (VRFW_ScreenKit: only what changed is sent) ---------------------------------------------------------

local Kit   -- VRFW_ScreenKit.New in OnInit

local function TexReady(tex)
  local state = S.loaded[tex]
  if state == "in" then return true end     -- asked of the engine only until it is in
  if state == nil then
    pcall(funcLuaMenuCommand, C.LOAD_TEX, tex)   -- CMND_LOAD_MENU_RES_TEXTURE is a menu command
    S.loaded[tex] = "asked"
  end
  local ok, loading = pcall(funcLuaCommand, C.TEX_LOADING, Crc(tex))
  if ok and loading == false then
    S.loaded[tex] = "in"
    return true
  end
  return false
end

-- raise = 1: drawn one priority above the layer's other instances (the tick over its check box: instances of one
-- priority have no fixed order); 0 / nil: the layer's own priority
local function Quad(layer, tex, sprite, x, y, w, h, raise)
  return Kit.Quad(layer, tex, sprite, x, y, w, h, { raise = raise })
end

local function Plate(layer, look, x, y, w, h)
  return Quad(layer, RETAIL.list.tex, RETAIL.list[look], x, y, w, h)
end

-- a plate of the album's own art in three slices (`look` "row" / "focus"): x, y, w = its rectangle, w at least two caps
local function RowPlate(layer, look, x, y, w)
  local c = ROW.cap
  Quad(layer, ART, SPRITE .. "album_" .. look .. "_l", x, y, c, P.row_h)
  Quad(layer, ART, SPRITE .. "album_" .. look .. "_m", x + c, y, w - 2 * c, P.row_h)
  Quad(layer, ART, SPRITE .. "album_" .. look .. "_r", x + w - c, y, c, P.row_h)
end

-- a row's plate width and its price box's width (nil: no box): a row with a price of another mod (r.extra) has its plate
-- shortened by the box and the gap, so plate + gap + box take the room of a row without one
local function RowLayout(r, rw)
  if r == nil or r.extra == nil then return rw, nil end
  return rw - P.box_body - P.box_gap, P.box_body + ROW.left + ROW.right
end

local function Cursor(x, y, h)
  local R = RETAIL.cursor
  local w = h * R.w / R.h
  return Quad(L.ICON, R.tex, R.sprite, x - w, y - h / 2, w, h)
end

local function Units(s) return VRFW_Text.Units(s) end

-- a text: left edge x, vertical middle y, a style of STYLE, scale (1 = the style's own size)
local function Text(s, x, y, style, sc)
  if s == nil or s == "" then return nil end
  local i = Kit.Slot(L.TEXT)
  if i == nil then return nil end
  sc = sc or 1
  Kit.Show(L.TEXT, i)
  for _, m in ipairs(TXT.MESHES) do Kit.Set(L.TEXT, i, "m" .. m, C.MESH_VISIBLE, L.TEXT, m, false, i) end
  Kit.Set(L.TEXT, i, "st", C.TEXT_STYLE, L.TEXT, i, TXT.NODE, Crc(STYLE[style] or STYLE.name))
  Kit.Set(L.TEXT, i, "txt", C.SET_TEXT, L.TEXT, TXT.NODE, s, i)
  Kit.Set(L.TEXT, i, "sc", C.SCALE, L.TEXT, sc, sc, 1, i)
  Kit.Set(L.TEXT, i, "pos", C.POS, L.TEXT, x - TXT.BOX_LEFT * sc, -y - TXT.BOX_MID_Y * sc, 0, i)
  return i
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

local function Fit(s, px, size) return VRFW_Text.Fit(s, px, size, GLYPH) end

-- the kit of a row's miniface: a row with a dressing team (a mod category's own team, the one that dresses the
-- plate's 3D model through VRFW.plate_card_team) wears that team's uniform as CMND_VRFW_CONTACT_KIT(card, team)
-- gives it (the keeper shirt for a keeper), so the miniface and the model show the same kit; asked once per card and
-- team. nil = no dressing team or no kit in the data: the character's own kit, as before
local KEEPER_SHIRT = 2           -- CMND_VRFW_CONTACT_KIT flags: the keeper shirt
local function RowKit(r)
  if (r.dress_team or 0) == 0 or (r.param or 0) == 0 or VRFW_Cmd == nil then return nil end
  local id = r.param .. ":" .. r.dress_team
  local kit = S.kits[id]
  if kit == nil then
    kit = false
    local ok, t = pcall(funcLuaCommand, VRFW_Cmd.VRFW_CONTACT_KIT, r.param, r.dress_team)
    if ok and type(t) == "table" and type(t.uniform) == "number" and t.uniform ~= 0 then
      kit = { kit = t.uniform, keeper = bit32.band(tonumber(t.flags) or 0, KEEPER_SHIRT) ~= 0, use_args = true }
    end
    S.kits[id] = kit
  end
  return kit or nil
end

-- the retail list character card, portrait only (face + kit, as the game composes it), centred at (cx, cy): the
-- VR-Framework's shared miniface (VRFW_FaceIcon.Card); nothing shown while it loads. A drawing only queues the slots
-- whose card changed (FaceStep asks them); a row with a dressing team wears that team's kit (RowKit)
local function Face(r, cx, cy, size)
  if VRFW_FaceIcon == nil then return end
  local i = Kit.Slot(L.FACE)
  if i == nil then return end
  Kit.Show(L.FACE, i)
  local sig = r.base .. ":" .. r.param .. ":" .. r.dress_team .. ":" .. cx .. ":" .. cy
  if S.face_sig[i] == sig then return end
  -- the slot's last miniface goes at once: never another player's face beside this row's name
  if S.face_key[i] ~= nil and S.face_key[i] ~= r.base then
    M(C.MESH_VISIBLE, L.FACE, VRFW_FaceIcon.CARD.MESH, false, i)
  end
  S.face_queue[#S.face_queue + 1] = { i = i, r = r, cx = cx, cy = cy, size = size, sig = sig }
end

-- once per Step: the next queued minifaces asked, then the ones still loading shown when they are in
local function FaceStep()
  if VRFW_FaceIcon == nil then return end
  local q = S.face_queue
  local last = math.min(#q, S.face_next + FACES_A_FRAME - 1)
  for n = S.face_next, last do
    local e = q[n]
    VRFW_FaceIcon.Card(L.FACE, e.i, e.r.base, e.cx, e.cy, e.size, RowKit(e.r) or { use_args = true })
    S.face_sig[e.i], S.face_key[e.i] = e.sig, e.r.base
  end
  S.face_next = math.max(S.face_next, last + 1)
  if VRFW_FaceIcon.Pending() then VRFW_FaceIcon.Settle() end
end

local function BeginFrame()
  Kit.Begin()
  S.waiting, S.zones = false, {}
  S.face_queue, S.face_next = {}, 1
  if S.ptr then S.ptr.Begin() end
end

-- a pointer zone (screen px, top-left + size, y down) of something drawn now: kind + value
local function Zone(x, y, w, h, kind, v)
  local id = kind .. ":" .. tostring(v)
  S.zones[id] = { kind = kind, v = v, x = x, y = y, w = w, h = h }
  if S.ptr then S.ptr.Rect(x, y, w, h, id) end
end

local function EndFrame()
  Kit.Finish(function(layer, i)
    if layer == L.FACE and VRFW_FaceIcon ~= nil then
      VRFW_FaceIcon.Forget(L.FACE, i)
      S.face_sig[i], S.face_key[i] = nil, nil
    end
    if layer == L.CREST then S.crests[i] = nil end
  end)
end

-- ---- the player plate (the right half) -----------------------------------------------------------------------------

local function ParamSet(k, v)
  if VRFW_Param.Has(k) then VRFW_Param.Clear(k) end
  VRFW_Param.Set(k, v)
end

local function ParamClear(k)
  if VRFW_Param.Has(k) then VRFW_Param.Clear(k) end
end

local function PlateExists() return M(C.IS_MENU, PLATE.MENU) == true end

local function PlateUp()
  local ok, up = pcall(funcLuaCommand, C.IS_OPEN_MENU, PLATE.MENU, PLATE.PAGE)
  return ok and up == true
end

-- the plate's player of a row: the card, level and rarity the album shows (BetterQoL.Album.Page: the base card at the
-- level cap in effect)
-- the plate card's dressing team (VRFW.plate_card_team), set before the plate builds the model
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
  pcall(funcLuaCommand, C.OPEN_MENU, PLATE.MENU)
  S.plate = { state = "opening", at = S.frame, seen = false, param = param, pending = nil }
  Log("plate open asked: param", param, "level", level, "rarity", rar)
end

-- the selected row on the plate, now
local function PlateApply()
  local r, P_ = S.rows[S.sel], S.plate
  P_.pending = nil
  if r == nil then return end
  local param, level, rar = Who(r)
  if P_.param == param and P_.level == level and P_.rarity == rar then return end
  ParamSet(PLATE.CARD, param)            -- before the plate's refresh builds the next model
  DressTeam(r)
  M(PLATE.SET, param, level, rar, false)
  P_.param, P_.level, P_.rarity = param, level, rar
end

-- the selection changed: on the plate at once after a rest, else when it rests again (PlateStep), so running over rows
-- with the pointer or a held key refreshes the plate once, for the row it stops on
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

-- the page's background-pass backdrop on / the Caseta's normal-pass background off (on = true), or the reverse; one
-- step each way (the plate is up / the page closes)
local function Cover(on)
  if S.cover == on then return end
  S.cover = on
  M(C.VISIBLE, L_BACKDROP, 0, on)
  pcall(funcLuaCommand, CASETA.CROSS_CALL, CASETA.MENU, CASETA.BACKGROUND, not on)
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
      S.dirty = true                     -- the guide's zones are read again, its row settled by now
      if P_.pending ~= nil then PlateApply() end
    end
  elseif P_.seen or S.frame - P_.at > PLATE.WAIT then
    Log("the plate did not open")
    P_.state = "failed"
  end
end

-- the plate's page step says whether it shows its first page (135_album_pages.lua, a cross-menu call): the «No lo
-- tienes» badge shows only there
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

-- ---- data --------------------------------------------------------------------------------------------------------------

local function Groups() return S.data and S.data.groups and S.data.groups[S.kind] or {} end

-- the bar page of group k (BetterQoL.Album.Open: a group's 8th value; 1 = the main bar)
local function BarPage(gl, k)
  local g = gl[k]
  return g and tonumber(g[8]) or 1
end

-- the content guide line: the page's fixed description
local function LineText()
  if not S.ok then return Tx("NoSave") end
  return Tx("Line")
end

local function SetLine()
  local s = LineText()
  if s ~= S.line then
    S.line = s
    M(C.SET_TEXT, L_LINE, LINE_TEXT, s)
  end
end

-- what another mod shows on this page's rows (an AlbumActions entry's RowExtras), the entry Accept would run
local function LoadRowExtras()
  S.extra_retries = S.extra_retries - 1
  local acts = type(BetterQoL) == "table" and BetterQoL.AlbumActions or nil
  for _, a in ipairs(type(acts) == "table" and acts or {}) do
    if type(a) == "table" and type(a.RowExtras) == "function" and type(a.On) == "function" then
      local ok_on, on = pcall(a.On)
      if ok_on and on == true then
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
            r.extra = whole and e or nil
          end
          S.dirty = true
        end
        return
      end
    end
  end
  S.extra_retries = 0
end

local function LoadPage()
  S.rows = {}
  S.extra_retries = 0
  local ok, t = pcall(funcLuaCommand, CMD.PAGE, S.kind, S.group, S.page, PER_PAGE)
  if not ok or type(t) ~= "table" then
    S.pages, S.total, S.owned = 1, 0, 0
    return
  end
  S.page, S.pages, S.total, S.owned = t.page or 1, t.pages or 1, t.total or 0, t.owned or 0
  for k, e in ipairs(type(t.rows) == "table" and t.rows or {}) do
    S.rows[k] = { base = tonumber(e[1]) or 0, param = tonumber(e[2]) or 0, name = tostring(e[3] or ""),
      team = tostring(e[4] or ""), game = tostring(e[5] or ""), owned = e[6] == true, level = tonumber(e[7]) or 1,
      rarity = tonumber(e[8]) or 0, dress_team = tonumber(e[9]) or 0 }
  end
  S.sel = math.max(1, math.min(#S.rows, S.sel))
  S.dirty = true
  S.extra_retries = EXTRA_RETRIES
  LoadRowExtras()
  SetLine()
  PlateShow()
end

local function Load()
  local okl, lang = pcall(funcLuaCommand, C.LANG)
  local ok, t = pcall(funcLuaCommand, CMD.OPEN, okl and lang or 1, TxRaw("NameGroups"), Tx("OtherGroup"), Tx("Specials"),
    Tx("OtherTeams"))
  S.ok = ok and type(t) == "table" and type(t.groups) == "table"
  S.data = S.ok and t or nil
  if not S.ok then
    Log("no album data", tostring(t))
    return
  end
  Log("page opened:", t.total, "player(s),", t.owned, "in the club")
end

-- ---- drawing -----------------------------------------------------------------------------------------------------------

local BLUE_STYLE = "tab"

-- the type row: L2 left, R2 right, the two types spread between them
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

-- the group row: LB left, RB right, the groups between them (series tab icons, else their labels)
-- the game groups on the game's tab bar: one strip, each series logo flat on it (its dimmed sprite), the focused one
-- white on the bright block
-- a team crest (layer util_alb_crest: the game's emblem list row team06_02, as the Battle Bay bracket's crests): its
-- plates, check and texts hidden, its emblem quad (68 px, centre CX from the row's origin) centred at (cx, cy)
local CREST = { MESH = 3281704751 --[[_icon_emblem_dmy01]], TEX = 255812047 --[[icon_emblem_dmy01]], PX = 68, CX = 78,
  HIDE = { "_list_base_xs01_off", "_list_base_xs01_on", "_list_base_xs01_ok", "_list_base_xs01_ol", "_icon_check01" },
  TEXTS = { 931545948 --[[_text_list01_on]], 3705682548 --[[_text_list01_off]] }, ASK_FRAMES = 30 }
local function Crest(id, cx, cy, px)
  local i = Kit.Slot(L.CREST)
  if i == nil then return end
  local s = px / CREST.PX
  Kit.Show(L.CREST, i)
  Kit.Set(L.CREST, i, "sc", C.SCALE, L.CREST, s, s, 1, i)
  Kit.Set(L.CREST, i, "pos", C.POS, L.CREST, cx - CREST.CX * s, -cy, 0, i)
  local c = S.crests[i]
  if c == nil or c.id ~= id then
    if c ~= nil then M(C.RESET_FACE, L.CREST, i, CREST.TEX) end
    c = { id = id, at = S.frame }
    S.crests[i] = c
  end
  -- asked again for a few frames: an instance opened this frame is built later
  if S.frame - c.at <= CREST.ASK_FRAMES then
    for _, m in ipairs(CREST.HIDE) do M(C.MESH_VISIBLE, L.CREST, Crc(m), false, i) end
    for _, t in ipairs(CREST.TEXTS) do M(C.TEXT_VISIBLE, L.CREST, t, false, i) end
    VRFW_Team.Crest(L.CREST, i, id, nil, CREST.MESH, CREST.TEX)   -- the framework's crest request
    S.waiting = true
  end
end

-- the group bar, every type on the game's list tab bar (free-match rival list): one strip with its dark end caps, the
-- groups as segments of its blue part (a series logo, else the label, dimmed), the focused one on the bright block
-- (white logo / label). «Equipo»: one segment, the focused team's crest, name and place among the teams
local function DrawStripBar(gl, y, h)
  local R, F = RETAIL.strip, RETAIL.focus
  local x0, w = P.x + P.key_w, P.width - 2 * P.key_w
  local sx, sy = w / R.w, h / R.h
  local by, bh = y + R.band_t * sy, (R.band_b - R.band_t) * sy
  local segs = {}
  if S.search ~= nil then
    -- the search: one segment, its text and how many players it found
    segs[1] = { k = S.group, left = true, label = Fill(Tx("SearchBand"), S.search.text, S.total) }
  elseif S.kind == KIND_TEAM then
    local g = gl[S.group]
    if g then
      segs[1] = { k = S.group, emblem = tonumber(g[5]) or 0, left = true,
                  label = tostring(g[6] or g[1] or "") }
    end
  else
    -- the bar page of the focused group: only its groups are on the bar
    local page = BarPage(gl, S.group)
    for k, g in ipairs(gl) do
      if BarPage(gl, k) == page then
        local icon = S.kind == KIND_GAME and type(g[7]) == "string" and g[7] ~= "" and g[7] or nil
        segs[#segs + 1] = { k = k, ty = S.kind == KIND_GAME and tonumber(g[4]) or nil, icon = icon,
                            label = tostring(g[1] or "") }
      end
    end
  end
  -- the strip variant whose blue part holds every tab at the natural tab width (tab_aspect x band height); the widest
  -- one when none does. Its blue edges are measured at the band's mid height, where the segments' edges are placed
  local variant = R.variants[#R.variants]
  for _, v in ipairs(R.variants) do
    if (v.right - v.left) * sx >= #segs * R.tab_aspect * bh then variant = v break end
  end
  Quad(L.PLATE, R.tex, variant.sprite, x0, y, w, h)
  -- the bar pages (a mod's album page, [[series]] page): «<» / «>» in the strip's dark end caps when a page lies that
  -- way; a click there turns the bar page (LB / RB cross pages too)
  if S.kind ~= KIND_TEAM then
    local page, last = BarPage(gl, S.group), BarPage(gl, #gl)
    local cap = variant.left * sx
    if page > 1 then
      Text("<", x0 + cap / 2 - TXT.BOX_W / 2, by + bh / 2 + 1, "bar")
      Zone(x0, y, cap, h, "bar_page", -1)
    end
    if page < last then
      Text(">", x0 + w - cap / 2 - TXT.BOX_W / 2, by + bh / 2 + 1, "bar")
      Zone(x0 + w - cap, y, cap, h, "bar_page", 1)
    end
  end
  local mid = ((R.band_t + R.band_b) / 2 - R.band_t) * R.slant
  local il, ir = x0 + (variant.left - mid) * sx, x0 + (variant.right - mid) * sx
  -- a tab keeps its natural width (tab_aspect x band height); it
  -- is never stretched over a bar that holds fewer tabs than it could
  local tw = (ir - il) / math.max(1, #segs)
  if S.kind ~= KIND_TEAM and S.search == nil then tw = math.min(tw, R.tab_aspect * bh) end
  -- the tabs sit centred in the blue part (the offset follows the real tab count), evenly spaced
  local first = il + ((ir - il) - #segs * tw) / 2
  for n, sg in ipairs(segs) do
    local x = first + (n - 1) * tw
    Zone(x, y, tw, h, "group", sg.k)
    local on = sg.k == S.group
    if on and not sg.left then
      -- the block's visible parallelogram spans exactly this segment at mid height, so its slanted edges meet the
      -- neighbours' and the strip's slanted ends
      local qw = tw * F.w / (F.mid_r - F.mid_l)
      Quad(L.ICON, F.tex, F.sprite, x - F.mid_l * qw / F.w, by, qw, bh)
    end
    local drawn = false
    -- the group's own tab icon (the «Especiales» group), else its series type's
    local sprite = sg.icon or (sg.ty and sg.ty >= 1 and sg.ty <= 99 and string.format("icon_list_tab_series%02d", sg.ty))
    if sprite then
      local iw = math.min(tw, bh * RETAIL.tabs.w / RETAIL.tabs.h)
      drawn = Quad(L.ICON, RETAIL.tabs.tex, sprite .. (on and "" or "_off"),
        x + (tw - iw) / 2, by, iw, bh, on and 1 or 0) ~= nil
    end
    if not drawn then
      -- the label centred on its segment (a centred style on the text box's centre); a crest at the segment's left,
      -- the label centred on the rest
      local lx, lw = x, tw
      if sg.emblem and sg.emblem ~= 0 then
        local cs = bh - 4
        local cx = x + 8
        if sg.left then
          -- «Equipo»: crest and name centred together in the band
          local nw = math.min(Units(sg.label) * 26 * GLYPH, tw - cs - 40)
          cx = x + (tw - (cs + 8 + nw)) / 2
        end
        Crest(sg.emblem, cx + cs / 2, by + bh / 2, cs)
        lx, lw = cx + cs + 8, tw - (cx - x) - cs - 8
      end
      local sc = 0.9
      if sg.left then
        -- «Equipo»: crest and label straight on the strip, centred together (the label right after the crest)
        local t = Fit(sg.label, lw - 12, 26)
        local nx = lx
        if not (sg.emblem and sg.emblem ~= 0) then nx = x + (tw - Units(t) * 26 * GLYPH) / 2 end
        Text(t, nx, by + bh / 2 + 1, "section")
      else
        -- a centred style centres on the text box (BOX_LEFT .. BOX_LEFT + BOX_W): its centre on the segment's centre
        Text(Fit(sg.label, lw - 12, 28 * sc), lx + lw / 2 - TXT.BOX_W / 2 * sc, by + bh / 2 + 1, "bar", sc)
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

-- the band of «Estadísticas del club» (its atlas: cap, stretched middle, cap)
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

-- the selected row's highlight (3 slices) and cursor: the first four instances of the icon layer, so moving the selection
-- moves only these and never renumbers the check boxes and ticks drawn after them
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
  Kit.Quad(L.ICON, RETAIL.list.tex, RETAIL.list.focus, z.x, z.y, z.w, z.h, { alpha = HOVER_ALPHA })
end

-- a click zone on the entry of the Caseta's button guide at row `entry` (the guide belongs to the Caseta, whose input
-- is off while this page is up); `text` = the entry's label, for its width. No zone while the row has no position
local function GuideZone(entry, text, v)
  local x, y = M(VRFW_Cmd.GET_MESH_GLOBAL_POSITION, GUIDE.BUTTON, entry, GUIDE.GLYPH, CASETA.MENU)
  if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return end
  local ok, s = pcall(funcLuaCommand, C.TEXT_GET, text)
  local w = (ok and type(s) == "string") and Units(s) * GUIDE.TEXT_PX * GLYPH or 0
  Zone(x, -y, GUIDE.GLYPH_W + GUIDE.GAP + w, GUIDE.GLYPH_W, "guide", v)
end

-- the guide's entries as the opener set them (play_guide_top_menu\155_album.lua PageGuide): the first action on offer
-- with a label, then X
local function GuideZones()
  local acts = type(BetterQoL) == "table" and type(BetterQoL.AlbumActions) == "table" and BetterQoL.AlbumActions or {}
  local entry = 0
  for _, a in ipairs(acts) do
    if type(a) == "table" and type(a.guide) == "number" and type(a.On) == "function" then
      local ok, on = pcall(a.On)
      if ok and on == true then
        GuideZone(0, a.guide, "accept")
        entry = 1
        break
      end
    end
  end
  GuideZone(entry, GUIDE.SEARCH_TEXT, "search")
end

local function DrawRow(r, k)
  local rx, ry, rw = RowAt(k)
  local plate_w, box_w = RowLayout(r, rw)
  RowPlate(L.PLATE, "row", rx, ry, plate_w)
  if box_w ~= nil then RowPlate(L.PLATE, "row", rx + rw - box_w, ry, box_w) end
  Zone(rx, ry, rw, P.row_h, "row", k)
  local cy = ry + P.row_h / 2
  local bx = rx + P.box_x
  local K = RETAIL.check
  Quad(L.ICON, K.tex, K.box, bx, cy - P.box / 2, P.box, P.box)
  if r.owned then Quad(L.ICON, K.tex, K.mark, bx - 4, cy - P.mark / 2 - 4, P.mark, P.mark, 1) end
  local fx = bx + P.box + 12
  if r.base ~= 0 then Face(r, fx + P.face / 2, cy, P.face) end
  local nx = fx + P.face + 10
  local name, name_right, scale, size = r.name ~= "" and r.name or "-", rx + rw - 40, P.name_scale, 26
  local extra = r.extra
  if extra ~= nil then
    -- the price (text, then icon) centred in the box at the row's mid height (the box's slanted edges are ROW.slant / 2
    -- off its top corners there); the text gets smaller before it would leave the box. The name keeps clear of the
    -- shortened plate's right end, smaller before it is cut
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

local function Draw()
  BeginFrame()
  if S.ready and S.ok then
    DrawSelection()
    DrawTypes()
    DrawGroups()
    if #S.rows == 0 then
      Text(Tx("Empty"), P.x + 40, P.top + P.row_h / 2, "head")
    end
    for k, r in ipairs(S.rows) do DrawRow(r, k) end
    -- the counter, its page keys at both ends: each key its own text under its own zone
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
      local s = Tx("NotOwned")
      local w = Units(s) * 28 * GLYPH + 2 * BAND_CAP + 20
      Band(P.badge_x - w, P.badge_y, w, P.badge_h)
      TextC(s, P.badge_x - w / 2, P.badge_y + P.badge_h / 2 + 1, "section", 28)
    end
    GuideZones()
    DrawHover()
  elseif S.ready then
    Text(Tx("NoSave"), P.x + 40, P.top, "head")
  end
  EndFrame()
end

-- ---- keys --------------------------------------------------------------------------------------------------------------

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

local function Page(d)
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

-- left / right: the other column of the same row; past the first / last column the previous / next page, landing in
-- its last / first column on the same row (a shorter column: its last row)
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
  Page(d)
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

-- the bar page next to the shown one (d = -1 / 1): its first group
local function BarTurn(d)
  local gl = Groups()
  local want = BarPage(gl, S.group) + d
  for k = 1, #gl do
    if BarPage(gl, k) == want then return SetGroup(k) end
  end
end

-- the pointer, once per Step (the framework's VRFW_Pointer): a row is selected under it only on a frame the pointer
-- moved (a redraw under a resting pointer never re-selects); a click picks the zone under it.
local Accept, OpenSearch

local function PointerStep()
  local ev = S.ptr.Poll()
  if ev.changed then
    local h = ev.hot ~= nil and S.zones[ev.hot] or nil
    local lit = (h ~= nil and HOVER_LIT[h.kind]) and ev.hot or nil
    if lit ~= S.hover then
      S.hover = lit
      S.dirty = true
    end
  end
  local z = ev.hot ~= nil and S.zones[ev.hot] or nil
  if z == nil then return nil end
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
    elseif z.kind == "page" then Page(z.v)
    elseif z.kind == "guide" then
      if z.v == "search" then OpenSearch() else Accept(true) end
    end
  end
  return nil
end

-- ---- A: another mod's action on the selected player (BetterQoL.AlbumActions) --------------------------------------------

local function Offered(a)
  if type(a) ~= "table" or type(a.On) ~= "function" or type(a.Run) ~= "function" then return false end
  local ok, on = pcall(a.On)
  return ok and on == true
end

Accept = function(by_pointer)
  if S.task ~= nil then return end
  if not by_pointer and S.ptr.Owns() then return end      -- a pointer click: the pointer takes it
  local r = S.rows[S.sel]
  local acts = type(BetterQoL) == "table" and BetterQoL.AlbumActions or nil
  if r == nil or type(acts) ~= "table" then return end
  for _, a in ipairs(acts) do
    if Offered(a) then
      local row = { base = r.base, param = r.param, name = r.name, owned = r.owned, level = r.level, rarity = r.rarity }
      S.task = coroutine.create(function() return a.Run(row) end)
      Log("action", tostring(a.id), "param", r.param)
      return
    end
  end
end

local function TaskStep()
  if S.task == nil then return end
  local ok, changed = coroutine.resume(S.task)
  if not ok then
    Log("action error", tostring(changed))
    M(VRFW_Cmd.SET_INPUT_ENABLE_MENU_OBJECT, Crc("util_album_menu"), true)   -- a search stopped with its input off
  end
  if ok and coroutine.status(S.task) ~= "dead" then return end
  S.task = nil
  S.ptr.Reset()                    -- a button still held from the windows is no click
  if ok and changed == true then
    Load()
    if S.ok then
      if S.search ~= nil then pcall(funcLuaCommand, CMD.SEARCH, S.search.text) end
      LoadPage()
    end
  end
end

-- ---- X: the player search ------------------------------------------------------------------------------------------

-- back to the tab, page and row the search came from
local function ClearSearch()
  local b = S.before
  S.search, S.before = nil, nil
  S.kind, S.group, S.page, S.sel = b.kind, b.group, b.page, b.sel
  LoadPage()
end

-- a confirmed text. The pass over the names runs once, in the script's command, without an engine command per row
local function ApplySearch(query, text)
  if query == "" then
    if S.search ~= nil then ClearSearch() end
    return
  end
  if S.search ~= nil and S.search.query == query then return end
  local ok, found = pcall(funcLuaCommand, CMD.SEARCH, text)
  found = ok and tonumber(found) or 0
  Log("search", query, "found", found)
  if found == 0 then
    BetterQoL.TextSearch.Refuse()
    return
  end
  S.before = S.before or { kind = S.kind, group = S.group, page = S.page, sel = S.sel }
  S.search = { text = text, query = query }
  S.kind, S.group, S.page, S.sel = KIND_SEARCH, 1, 1, 1
  LoadPage()
end

-- S.task stays set one frame after the input is back: the key that closed the window never reaches OnBack / OnFunction
local function SearchTask()
  local title = Crc("BetterQoL.Album.SearchTitle")
  if not BetterQoL.TextSearch.Run(Crc("util_album_menu"), title, S.search and S.search.text or "", ApplySearch) then
    Log("text entry did not open")
  end
  coroutine.yield()
  return false
end

OpenSearch = function()
  if S.task ~= nil or not S.ok then return end
  S.task = coroutine.create(SearchTask)
end

local ACT = {
  search = OpenSearch,
  accept = function() Accept(false) end,
  up = function() Move(-1) end, down = function() Move(1) end,
  left = function() Side(-1) end, right = function() Side(1) end,
  type_prev = function() Kind(-1) end, type_next = function() Kind(1) end,
  group_prev = function() Group(-1) end, group_next = function() Group(1) end,
  plate_prev = function() PlatePage(-1) end, plate_next = function() PlatePage(1) end,
}

-- ---- menu callbacks ----------------------------------------------------------------------------------------------------

function OnInit()
  S.ready, S.ok, S.frame, S.dirty, S.plate, S.line, S.task = false, false, 0, true, nil, nil, nil
  S.search, S.before, S.hover = nil, nil, nil
  S.kind, S.group, S.page, S.sel, S.rows, S.zones = KIND_GAME, 1, 1, 1, {}, {}
  S.loaded, S.face_queue, S.face_next, S.face_sig, S.face_key = {}, {}, 1, {}, {}
  S.ptr = VRFW_Pointer.New()       -- the mouse / free cursor (VRFW)
  S.ptr.Reset()                    -- a button held from the Caseta's Accept is no click
  Kit = VRFW_ScreenKit.New({ tex_ready = TexReady })
  S.texts = {}
  if VRFW_FaceIcon ~= nil then VRFW_FaceIcon.Forget(L.FACE) end
  S.crests, S.first_page, S.kits = {}, true, {}
  Load()
end

function OnSetupLayer(a1, a2)
  if a1 == L_ANCHOR then
    -- the input anchor: nothing of it shows
    for _, node in ipairs(ANCHOR.TEXTS) do M(C.SET_TEXT, a1, node, "", a2) end
    M(C.ATTACH_TRACE, a1, a2, ANCHOR.CURSOR, false)
  elseif a1 == L_BACKDROP then
    M(C.VISIBLE, a1, a2, false)          -- until the plate is up (Cover)
    S.cover = false
  elseif a1 == L_LINE then
    S.line = nil
    SetLine()
  else
    for _, layer in pairs(L) do
      if a1 == layer then
        -- a pool instance: hidden until the page draws it
        M(C.VISIBLE, a1, a2, false)
        if Kit ~= nil then Kit.Forget(a1, a2) end
        if a1 == L.FACE then S.face_sig[a2] = nil end
        S.dirty = true
      end
    end
  end
end

function OnOpenLayer(a1, a2)
  if a1 == L_ANCHOR and a2 == 0 then
    M(C.CTRL, L_ANCHOR, true)
    M(C.LIST_NUM, L_ANCHOR, 1)
    M(C.FOCUS_SET, L_ANCHOR, 0)
    M(C.ATTACH_TRACE, L_ANCHOR, 0, ANCHOR.CURSOR, false)
    M(C.POS, L_ANCHOR, -4000, 4000, 0, 0)       -- off screen, still holding the focus
    for _, layer in pairs(L) do
      local n = M(C.LAYER_NUM, layer)
      Kit.caps[layer] = type(n) == "number" and n or 0
    end
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
  ACT[act]()
  return 1
end

-- B / Esc / right click: a window of a running task first (return 1: the page stays), then the search, else the engine
-- closes the page; the plate is asked to close (the opener waits for it)
function OnBack(a1)
  if S.task ~= nil then return 1 end
  if S.search ~= nil then
    Snd(SY_BACK)
    ClearSearch()
    return 1
  end
  Cover(false)
  if PlateExists() then pcall(funcLuaCommand, C.CLOSE_MENU, PLATE.MENU) end
  pcall(ParamClear, PLATE.CARD)
  pcall(ParamClear, PLATE.CARD_TEAM)
  Log("page closed")
end

function Step()
  S.frame = S.frame + 1
  if not S.ready then return end
  PlateStep()
  FaceStep()
  if (S.extra_retries or 0) > 0 then LoadRowExtras() end
  if S.task ~= nil then
    TaskStep()
    return
  end
  -- the wheel has no menu command of its own: read like the game's other mouse pages
  local K = VRFW_Keys
  if K.Held(K.WHEEL_UP, K.MENU_CTRL) then Move(-1) elseif K.Held(K.WHEEL_DOWN, K.MENU_CTRL) then Move(1) end
  PointerStep()
  -- drawn when something changed, and again while a texture or a miniface of the page is still loading
  if S.dirty then S.wait_until = S.frame + WAIT_FRAMES end
  if S.dirty or ((S.waiting or Kit.waiting) and S.frame < (S.wait_until or 0)) then
    S.dirty = false
    local ok, err = pcall(Draw)
    if not ok then Log("draw error", tostring(err)) end
  end
end
