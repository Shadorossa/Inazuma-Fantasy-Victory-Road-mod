
local Crc = VRFW.ids.crc32

local Draw, StartCo, SwitchTab, ProfileFlow, SearchFlow, CycleFilter, CycleSort, SelectMod, OpenDetails, Toggle
local Order, ClosePopup, RunExtra, PadDecide

local MENU = Crc("vrfw_mods_menu")
local INK = "[CB]"
-- the base mod (vrfw_mod_format::BASE_MOD): kept for dependency labels, hidden from the player's mod lists
local BASE = "VRFW"
local DEBOUNCE = 20

local M = {
  COUNT = Crc("CMND_VRFW_LOADER_MODS_COUNT"),
  GET = Crc("CMND_VRFW_LOADER_MODS_GET"),
                                               -- deltas, applied, pending, pos, size, preview, warnings, level, live
  GET_TEXT = Crc("CMND_VRFW_LOADER_MODS_GET_TEXT"),
                                               -- / 8 tags / 9 date
  SET_ENABLED = Crc("CMND_VRFW_LOADER_MODS_SET_ENABLED"),
  MOVE = Crc("CMND_VRFW_LOADER_MODS_MOVE"),
  PROFILE_NAME = Crc("CMND_VRFW_LOADER_MODS_PROFILE_NAME"),
  PROFILE_SWITCH = Crc("CMND_VRFW_LOADER_MODS_PROFILE_SWITCH"),
  PROFILE_NEW = Crc("CMND_VRFW_LOADER_MODS_PROFILE_NEW"),
  RESCAN = Crc("CMND_VRFW_LOADER_MODS_RESCAN"),
  -- the mods_menu plugin (crates/plugins/mods_menu/src/rt.rs)
  TEXT = Crc("CMND_VRFW_MM_TEXT"),              -- (name, language code) -> text
  STATE = Crc("CMND_VRFW_MM_STATE"),            -- () -> title, screen, version, menu (crc32), ...
  THUMB = Crc("CMND_VRFW_MM_THUMB"),
  ICON = Crc("CMND_VRFW_MM_ICON"),
  TEXT_ID = Crc("CMND_VRFW_TEXT_ID"),           -- text_engine: (key) -> id of a new text
  -- the VRFW core's report of this start (<data dir>\cache\VRFW\report.json)
  REPORT_COUNT = Crc("CMND_VRFW_REPORT_COUNT"), -- (mod) -> entries
  REPORT_ROW = Crc("CMND_VRFW_REPORT_ROW"),
  REPORT_RELOAD = Crc("CMND_VRFW_REPORT_RELOAD"), -- (mod) -> "type=live|next_load|restart;..."
  REPORT_WHO = Crc("CMND_VRFW_REPORT_WHO"),
  REPORT_WHO_ROW = Crc("CMND_VRFW_REPORT_WHO_ROW"),
  -- what the audio engine said at boot about a mod (its page): (mod id) -> "<1|0>|<text>" lines
  AU_NOTES = Crc("CMND_VRFW_MM_AU_NOTES"),
  PROVIDES = Crc("CMND_VRFW_MM_PROVIDES"),
  KEY_ID = Crc("CMND_VRFW_MM_KEY_ID"),
  TAG_DEFS = Crc("CMND_VRFW_MM_TAG_DEFS"),      -- () -> how many mod tags the mods declare ([[VRFW.ModTag]])
  TAG_DEF = Crc("CMND_VRFW_MM_TAG_DEF"),        -- (i) -> id, text key
  MOD_TAGS = Crc("CMND_VRFW_MM_MOD_TAGS"),      -- (mod id) -> its tag ids, one per line
  PERMS = Crc("CMND_VRFW_MM_PERMS"),
  MODULE = Crc("CMND_VRFW_MM_MODULE"),
  FOLDER = Crc("CMND_VRFW_MM_FOLDER"),
  NOTES = Crc("CMND_VRFW_MM_NOTES"),
}
local BG = {LAYER = 367379312 --[[mainmenu90_00_background]], on = nil, page = nil}
local CE = {}
-- the mod info block (110_info_panel.lua).
local INFO = {MAIN = {q = "Q1", l = "TL", c = "TC"}, POPUP = {q = "P1", l = "PL", c = "PC"},
              LABEL_W = 196, STEP = 36, DASH = "—"}
-- a mod's page (120_record_viewer.lua … 123_settings.lua): its caches and sizes
local RV = {cache = {}, MAX = 400, ROWS = 13, ORDER = {dependency = 1, error = 2, skipped = 3, warning = 4}}
RV.NEWS_ROWS, RV.MOD_ROWS, RV.FULL_ROWS = 13, 9, 14
RV.MOD_STEP, RV.MOD_HEAD_H = 48, 38
-- what this file shares with the screen's other files (VRFW.mods_screen, filled at the end of this file)
local Screen = {}
-- the game's keyboard (the same calls as the avatar name screen): open (…), busy, typed text, close
local KB = {OPEN = 962493425, BUSY = 422535539, RESULT = 1487869455, CLOSE = 3351189333}
-- the retail keyboard title "Search" when this mod's is not in menu_text
local RT_SEARCH = 1354833040

-- retail layers of the frame
local L_BASE = Crc("save01_01_list_attach_base")
local L_ROW = Crc("save01_02_list_item")          -- the input anchor (1 instance, off screen)
local L_HEADER = Crc("mainmenu90_01_header")
local L_CURSOR = Crc("cmn05_01_cursor")
local L_BTN_GUIDE = Crc("mainmenu01_06_base_button_guide")
local L_BTN = Crc("mainmenu01_07_button_guide")
local L_RET = Crc("mainmenu01_10_return_arrow_button_guide")
-- free layers (screen.rs FREE): name -> instances
local FREE = {
  Q0 = {Crc("vrfw_mm_q0"), 80}, CARD = {Crc("vrfw_mm_card"), 16}, Q2 = {Crc("vrfw_mm_q2"), 48}, Q1 = {Crc("vrfw_mm_q1"), 144},
  TL = {Crc("vrfw_mm_tl"), 128}, TC = {Crc("vrfw_mm_tc"), 96}, TR = {Crc("vrfw_mm_tr"), 24},
  P0 = {Crc("vrfw_mm_p0"), 24}, P1 = {Crc("vrfw_mm_p1"), 55},
  PL = {Crc("vrfw_mm_pl"), 48}, PC = {Crc("vrfw_mm_pc"), 28}, PR = {Crc("vrfw_mm_pr"), 8},
}
-- the layers of THIS menu (set up with it, counted by the reveal, hidden by Finish)
local FREE_ORDER = {"Q0", "CARD", "Q2", "Q1", "TL", "TC", "TR", "P0", "P1", "PL", "PC", "PR"}
local N = {
  ROW_ON = Crc("_text_list01_on"), ROW_OFF = Crc("_text_list01_off"),
  ROW_MESHES = {Crc("_list_icon_dmy_s01_on"), Crc("_list_icon_dmy_s01_off"), Crc("_list_icon_dmy_s01_ok"), Crc("_list_base_s01_ok"),
                Crc("_list_base_s01_on"), Crc("_list_base_s01_off"), Crc("_list_base_s01_ol")},
  BASE_TIME = Crc("_text_time01"), BASE_MESHES = {Crc("_system_line01"), Crc("_comma01"), Crc("_comma02")},
  SUB_TITLE = 1220590795,          -- _text_sub_title02 of the header
  CURSOR = Crc("cursor"), FOCUS = Crc("Focus"), ACTIVE = Crc("Active"), BUTTON = Crc("button"),
  QUAD = Crc("icon_new01"),        -- the cmn01_10 quad's sprite (the name its material uses)
  PHOTO = Crc("img_photo_dmy01"),  -- the photo frame's picture sprite
  PHOTO_RING = Crc("_photo_focus01"), PHOTO_PIN = Crc("_icon_photo_pin01"), PHOTO_FAV = Crc("_icon_photo_favorite01"),
  PHOTO_OK = Crc("_photo_frame_s01_ok"),
  TEXT = Crc("_text_guide01"),     -- the text node of the text layers
  BAND = Crc("_vs_top_guide_base01_line01"),   -- the retail band of the text layers (hidden)
}
N.BASE_PRIMS = {1162845628, 3567142029, 3057999962}

-- the screen's atlas (crates/plugins/mods_menu/src/atlas.rs) and its sprites
local ATLAS = Crc("#/menu/vrfw_mods/vrfw_mm_ui.g4tx")
local function SP(name)
  return Crc("vrfw_mm_" .. name)
end
local NTILES = 8

local C = {
  TEXT = VRFW.commands.SET_MENU_TEXT_STRING,          -- CMND_SET_MENU_TEXT_STRING (layer, node, string, idx)
  TEXT_GET = VRFW.commands.TEXT_GET,      -- CMND_TEXT_GET (id) -> string
  LANG = VRFW.commands.GET_LANGUAGE_CODE,           -- CMND_GET_LANGUAGE_CODE
  MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,  -- (layer, mesh, bool, idx)
  PRIM_VISIBLE = 1233047821,  -- (layer, idx, prim, bool)
  LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,  -- (layer, idx, bool)
  POS = VRFW.commands.SET_LAYER_LOCAL_POS,
  SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,         -- CMND_SET_LAYER_LOCAL_SCALE (layer, sx, sy, sz, idx)
  SPRITE = 558735651,         -- (layer, texture crc, sprite crc, sprite slot crc, 0, idx)
  LOAD_TEX = VRFW.commands.LOAD_MENU_RES_TEXTURE,       -- CMND_LOAD_MENU_RES_TEXTURE (path)
  ALPHA = VRFW.commands.SET_LAYER_MODEL_ALPHA,         -- CMND_SET_LAYER_MODEL_ALPHA (layer, idx, 0, alpha)
  ATTACH_TRACE = VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE,  -- (layer, idx, locator, bool)
  OPEN_LAYER = VRFW.commands.OPEN_LAYER,
  ANIME = VRFW.commands.PLAY_ANIME_TYPE,         -- CMND_PLAY_ANIME_TYPE (layer, idx, type, 0 in / 2 out, set)
  CTRL = VRFW.commands.SET_ENABLE_CTRL_FOCUS,          -- CMND_SET_ENABLE_CTRL_FOCUS (layer, bool)
  FOCUS_SET = 3466097042,     -- (layer, idx)
  LIST_NUM = 3252599449,      -- (layer, count)
  GUIDE_SET = 2209673388,     -- button guide (menu, layer, texts, icons, offsets, {}, {})
  GUIDE_CMD = 452337289,      -- button guide inputs (menu, layer, inputs)
  SE = VRFW.commands.SND_PLAY_SE,
  MENU_ACTIVE = 1558704558,   -- (menu, bool)
  CLOSE_MENU = VRFW.commands.CLOSE_MENU_OBJECT,     -- CMND_CLOSE_MENU_OBJECT
  FADE = 609722083, FADE_DONE = 2259183189,
  TEX_LOADING = 1506186496,
  -- the mouse, read here (the engine does not send hover to free layers)
  MOVED = 3272825600,
  POINTER = 558229292,        -- funcLuaMenuCommand () -> x, y (screen px, y down)
  CHECK_INPUT = VRFW.commands.CHECK_INPUT_CMD, MENU_CTRL = 1332654303, CLICK = 1651523701,
  ENTER = 1981080283,         -- CMD_ENTER (A / Enter) for the same poll
  LEFT = 749879980,
  W_UP = 2649361876, W_DOWN = 1098743808,   -- CMD_VRFW_WHEEL_UP / _DOWN
}
local FN = {UP = Crc("vrfw_mm_up"), DOWN = Crc("vrfw_mm_down"), LEFT = Crc("vrfw_mm_left"), RIGHT = Crc("vrfw_mm_right"),
            ORDER_UP = Crc("vrfw_mm_order_up"), ORDER_DOWN = Crc("vrfw_mm_order_down"),
            TAB_PREV = Crc("vrfw_mm_tab_prev"), TAB_NEXT = Crc("vrfw_mm_tab_next"), DETAILS = Crc("vrfw_mm_details"),
            SORT = Crc("vrfw_mm_sort"), FILTER = Crc("vrfw_mm_filter"), SEARCH = Crc("vrfw_mm_search"),
            PROFILE = Crc("vrfw_mm_profile"),
            EXTRA3 = Crc("vrfw_mm_extra3")}
local SE_OK, SE_BACK, SE_NG, SE_MOVE = 3848881948 --[[sy0000]], 202039849, 2086672038 --[[sy0003]], 2500047763 --[[sy0005]]
-- button guide icons (retail menu_text ids of the key glyphs) and inputs
local I_ENTER, I_L1, I_R1, I_F4, I_F1 = 2750714971 --[[<CMD_ENTER>]], 3020352056 --[[<CMD_FUNCL1>]], 1596629152 --[[<CMD_FUNCR1>]],
                                        1097287577 --[[<CMD_FUNC4>]], 203473330 --[[<CMD_FUNC1>]]
-- retail texts used when this mod's guide labels are not in menu_text (no text_engine): "ON" / "OFF", "Move"
local RT_ON, RT_OFF, RT_MOVE = 2951736153, 3639139279, 875903600
local G_ACCEPT = 1847312674 --[[Accept]]
-- key glyphs inside the mod's texts (the game draws them like in its own strings)
local K = {A = "<CMD_ENTER>", B = "<CMD_BACK>", L1 = "<CMD_FUNCL1>", R1 = "<CMD_FUNCR1>", L2 = "<CMD_FUNCL2>",
           R2 = "<CMD_FUNCR2>", START = "<CMD_FUNC1>", SELECT = "<CMD_FUNC2>", Y = "<CMD_FUNC3>", X = "<CMD_FUNC4>",
           L3 = "<CMD_FUNC5>", R3 = "<CMD_FUNC6>", LEFT = "<CMD_LEFT>", RIGHT = "<CMD_RIGHT>"}

local G = {
  TABBAR_X = 0, TABBAR_W = 990,
  TAB_X = 55, TAB_Y = 137, TAB_W = 270, TAB_H = 50, TAB_STEP = 270,
  TOOLS_Y = 202, TOOLS_H = 42,
  ROW_SEARCH_X = 25, ROW_SEARCH_W = 300, ROW_FILTER_X = 335, ROW_FILTER_W = 150, ROW_SORT_X = 495, ROW_SORT_W = 160,
  PROF_X = 828, PROF_Y = 202, PROF_W = 204, PROF_H = 42,
  NOTICE_X = 1260, NOTICE_Y = 104, NOTICE_W = 620, NOTICE_H = 40,
  BOX_X = 0, BOX_Y = 260, BOX_W = 1000, BOX_BOTTOM = 1003, BOX_PAD = 15, BOX_R = 14,
  LIST_X = 22, LIST_Y = 275, ROW_W = 950, ROW_H = 46, ROW_STEP = 50, LIST_ROWS = 14,
  -- the Mods tab: the list pane at the left (its box, rows, scroll bar), the selected mod's page docked at the right
  LIST_PANE_W = 660, LIST_ROW_W = 610, LIST_SB_X = 640,
  BACKDROP_ALPHA = 0.92,     -- opacity of the panes' backdrop (the list box, the page body)
  COLS = 1,                  -- "Instalados" is one column (ui.sel / ui.top count rows)
  SB_X = 980, SB_W = 6,
  -- the info panel of the selected mod: its header bar (stripes, name, version), the white body under it
  PANEL_X = 1040, PANEL_Y = 151, PANEL_W = 864, PANEL_HEAD = 54, PANEL_BODY_Y = 225, PANEL_BODY_H = 612, PANEL_H = 686,
  PANEL_R = 14,
  WIN_X = 690, WIN_Y = 260, WIN_W = 1210, WIN_H = 743,   -- the docked page
  COVER_W = 142, COVER_H = 80,
  BAND_H = 96, VTABS_H = 56, FOOT_H = 64,   -- a mod's page: header band, view tabs, shortcut bar
  INFO_TEXT_W = 620,         -- the page's information view: width of the description column
  MOD_LIST_W = 650, MOD_PANE_X = 1410, MOD_PANE_W = 460, MOD_PANE_HEAD = 48,
  MOD_VER_W = 150, MOD_NOTES = 3, MOD_CHIPS = 3,   -- the version column, the sheet's points and requirement chips
  SET_VAL_W = 230, SET_HELP_LINES = 6,   -- Settings: the value box's width, the sheet's help lines
  SET_STRIP_H = 140, SET_STRIP_LINES = 2,   -- Settings of a page: the focused setting's strip under the rows, its help lines
  Q = 36,                    -- the cmn01_10 quad side
  TXT_X = 48, TXT_Y = 915, TXT_W = 800, TXT_MID = 949,   -- the text node of the text layers (mainmenu90_05)
  PX = 14.5,                 -- width of one Latin character at text scale 1 (28 px font)
  NTABS = 2,
  -- the top-anchored y keys a header mod's top_dy moves (CE.apply_layout); TXT_Y stays
  SHIFT_Y = {"TAB_Y", "TOOLS_Y", "PROF_Y", "NOTICE_Y", "BOX_Y", "LIST_Y", "PANEL_Y", "PANEL_BODY_Y", "WIN_Y"},
}

local have = false          -- the ModLoader answers CMND_VRFW_LOADER_MODS_COUNT
local mods = {}
local base_mod = nil        -- framework metadata, never a card or load-order row
local cnt = {installed = 0, mods = 0, active = 0, changes = 0, profiles = 1, profile = 0}
local profiles = {}
local ui = {}               -- see Reset()
local changed = false
local co = nil
local frame, last_act = 0, -1000
local lang = nil
local extras = nil
local text_ids = {}
local tex_asked, tex_wait, tex_frames = {}, false, 0
local mouse = {on = false, x = -1, y = -1, logs = 0}
local dirty = false
local decided = false
local hits = {}              -- mouse zones of the last drawing: {x0, y0, x1, y1, id, act}
local DEBUG_EVENTS = 60
local dbg = 0

local FILTERS = {"all", "on", "off", "warn", "pending"}
local SORTS = {"order", "name", "size", "date"}

-- a state table filled again in place (the screen's other files hold the same table)
local function Refill(t, values)
  for k in pairs(t) do
    t[k] = nil
  end
  for k, v in pairs(values) do
    t[k] = v
  end
end

local function Reset()
  Refill(ui, {
    tab = 1,                 -- 1 installed mods, 2 problems (each mod's settings live on its page)
    zone = "grid",           -- Instalados: "grid" | "bar" (search, filter, sort)
    bar = 1,                 -- 1 search, 2 filter, 3 sort
    sel = 1, top = 0,
    osel = 1, otop = 1,      -- load order list
    psel = 0, ptop = 0, pfilter = 1,
    ssel = 0, stop = 0,
    query = "", filter = 1, sort = 1,
    popup = nil,             -- the docked page of the selected mod: {kind = "mod", id = …, btn = 1, view = …}
    pane = "list",           -- the Mods tab's pane the keys go to: "list" | "page"
    page = nil,
    toast = nil, toast_t = 0,
  })
end
Reset()

local Call = VRFW.host.command

local logger = VRFW.logger.new("mods_menu")
local Log = logger.debug

local function Trace(...)
  if dbg < DEBUG_EVENTS then
    dbg = dbg + 1
    Log("input", ...)
  end
end

local function Int(v)
  return type(v) == "number" and math.floor(v + 0.5) or 0
end

local function Str(v)
  return type(v) == "string" and v or ""
end

-- text `name` of the mod's text.toml in the game's language, {x} filled from vars
local function T(name, vars)
  if lang == nil then
    lang = Call(C.LANG) or 1
  end
  local s = Str(Call(M.TEXT, name, lang))
  if s == "" then
    s = name
  end
  if vars ~= nil then
    s = string.gsub(s, "{(%a+)}", function(k)
      local v = vars[k]
      return v == nil and ("{" .. k .. "}") or tostring(v)
    end)
  end
  return s
end

local function TextIdKey(key)
  if text_ids[key] ~= nil then
    return text_ids[key] or nil
  end
  local id = Call(M.TEXT_ID, key)
  if type(id) ~= "number" or id == 0 then
    id = Crc(key)
  end
  local s = Call(C.TEXT_GET, id)
  if type(s) == "string" and s ~= "" then
    text_ids[key] = id
    return id
  end
  text_ids[key] = false
  return nil
end

local function TextId(name)
  return TextIdKey("mods_menu." .. name)
end

local function Extras()
  if extras == nil then
    extras = {}
    if type(VRFW.mods_menu_changelog) == "table" then
      for _, e in ipairs(VRFW.mods_menu_changelog) do
        local ok, avail = pcall(function() return e.available == nil or e.available() end)
        if type(e) == "table" and type(e.flow) == "function" and ok and avail then
          extras[#extras + 1] = e
        end
      end
    end
  end
  return extras
end

local function ExtraFor(id)
  for _, e in ipairs(Extras()) do
    if e.fn == id then
      return e
    end
  end
  return nil
end

-- UTF-8 characters with width units (1 Latin, 2 CJK); an inline icon tag [$gaiji_...] is one unit-2 piece (never cut)
local function Chars(s)
  local out, i, n = {}, 1, string.len(s)
  while i <= n do
    local g = string.match(s, "^%[%$[%w_]+%]", i)
    if g then
      out[#out + 1] = {ch = g, w = 2}
      i = i + string.len(g)
      goto continue
    end
    local b = string.byte(s, i)
    local len = b >= 0xF0 and 4 or (b >= 0xE0 and 3 or (b >= 0xC0 and 2 or 1))
    out[#out + 1] = {ch = string.sub(s, i, i + len - 1), w = (len >= 3) and 2 or 1}
    i = i + len
    ::continue::
  end
  return out
end

-- width units of a text without its markup ([CN] … [C], <CMD_…> = 2 units)
local function Units(s) return VRFW.text_fold.units(s) end

-- untrusted text (problem messages, paths, mod names) as written, never read as markup
function Screen.literal(s) return VRFW.text_fold.literal(s) end

local function Cut(s, units)
  if #s <= units then
    return s
  end
  local head = #s > units * 8 + 64 and string.sub(s, 1, units * 8 + 64) or s
  if head == s or Units(head) <= units + 16 then
    if Units(s) <= units then
      return s
    end
  end
  local out, u = {}, 0
  for _, c in ipairs(Chars(head)) do
    if u + c.w > units - 3 then
      break
    end
    out[#out + 1] = c.ch
    u = u + c.w
  end
  return table.concat(out) .. "..."
end

-- word wrap into at most `maxl` lines of `units`
local function Wrap(s, units, maxl)
  local lines = {}
  for para in string.gmatch(string.gsub(s, "\r", "") .. "\n", "(.-)\n") do
    local line, lu = {}, 0
    local word, wu = {}, 0
    local function flush()
      if wu == 0 then
        return
      end
      if lu > 0 and lu + wu > units then
        lines[#lines + 1] = table.concat(line)
        line, lu = {}, 0
        while #word > 0 and word[1] == " " do
          table.remove(word, 1)
          wu = wu - 1
        end
      end
      for _, ch in ipairs(word) do
        line[#line + 1] = ch
      end
      lu, word, wu = lu + wu, {}, 0
    end
    for _, c in ipairs(Chars(para)) do
      if c.ch == " " then
        flush()
        word, wu = {" "}, 1
      elseif c.w == 2 then
        flush()
        word, wu = {c.ch}, 2
        flush()
      else
        word[#word + 1] = c.ch
        wu = wu + 1
        if wu >= units then
          flush()
        end
      end
    end
    flush()
    lines[#lines + 1] = table.concat(line)
  end
  while #lines > 0 and lines[#lines] == "" do
    lines[#lines] = nil
  end
  if #lines > maxl then
    local last = lines[maxl]
    lines = {table.unpack(lines, 1, maxl)}
    lines[maxl] = Cut(last .. " ...", units)
  end
  return lines
end

-- units that fit `px` pixels at text scale `sc`
local function Fit(px, sc)
  return math.max(4, math.floor(px / (G.PX * (sc or 1))))
end

local function Size(bytes)
  if type(bytes) ~= "number" or bytes <= 0 then
    return ""
  end
  if bytes >= 1048576 then
    return string.format("%.1f MB", bytes / 1048576)
  end
  return string.format("%d KB", math.max(1, math.floor(bytes / 1024 + 0.5)))
end

local key_names = {}

local function KeyOf(name)
  if name == nil or name == "" then
    return name
  end
  local k = key_names[name]
  if k == nil then
    k = Str(Call(M.KEY_ID, name))
    if k == "" then
      k = name
    end
    key_names[name] = k
  end
  return k
end

local function ReadAll()
  base_mod = nil
  key_names = {}
  mods = {}
  local installed, active, _skipped, _conflicts, _dirty, changes, np, p = Call(M.COUNT)
  have = type(installed) == "number"
  if not have then
    Refill(cnt, {installed = 0, mods = 0, active = 0, changes = 0, profiles = 1, profile = 0})
    return
  end
  Refill(cnt, {installed = Int(installed), active = Int(active), changes = Int(changes), profiles = math.max(1, Int(np)), profile = Int(p)})
  for i = 0, cnt.installed - 1 do
    local ok, id, name, version, author, _prio, enabled, state, _lua, _files, _deltas, _applied, pending, pos, size, preview,
          nwarn, level, live = Call(M.GET, i)
    if ok == true then
      local m = {idx = i, id = Str(id), name = Str(name), version = Str(version), author = Str(author),
                 enabled = enabled == true, state = Int(state), pending = pending == true, pos = Int(pos),
                 size = type(size) == "number" and size or 0, preview = preview == true, nwarn = Int(nwarn),
                 level = Int(level), live = live == true}
      local nid = TextIdKey(m.id .. ".mod_name")
      local ln = nid ~= nil and Str(Call(C.TEXT_GET, nid)) or ""
      if ln ~= "" then
        m.name = ln
      end
      local par, ord, nkey, internal = Call(M.MODULE, m.id)
      m.parent, m.morder, m.internal = Str(par), Int(ord), {}
      if Str(nkey) ~= "" then
        local kid = TextIdKey(m.id .. "." .. Str(nkey))
        local s = kid ~= nil and Str(Call(C.TEXT_GET, kid)) or ""
        m.mname = s ~= "" and s or nil
      end
      for o in string.gmatch(Str(internal), "[^\n]+") do
        m.internal[#m.internal + 1] = m.id .. "." .. o
      end
      if m.id == BASE then
        if base_mod == nil then base_mod = m end
      else
        m.order = #mods + 1
        mods[#mods + 1] = m
      end
    end
  end
  local byid = {}
  for _, m in ipairs(mods) do
    byid[m.id] = m
    m.modules = {}
  end
  for _, m in ipairs(mods) do
    m.family = m.parent ~= "" and m.parent ~= m.id and byid[m.parent] or nil
    if m.family ~= nil then
      m.family.modules[#m.family.modules + 1] = m
    end
  end
  for _, m in ipairs(mods) do
    table.sort(m.modules, function(a, b)
      if a.morder ~= b.morder then return a.morder < b.morder end
      return string.lower(a.mname or a.name) < string.lower(b.mname or b.name)
    end)
  end
  if base_mod ~= nil and base_mod.enabled then
    if base_mod.state == 0 then cnt.active = math.max(0, cnt.active - 1) end
    for _, m in ipairs(mods) do
      if m.pos > 0 then m.pos = m.pos - 1 end
    end
  end
  if base_mod ~= nil then
    base_mod.pos = 0   -- the framework always loads first: no load-order number, never moved
  end
  local top_mods, place = 0, 0
  for _, m in ipairs(mods) do
    if m.family == nil then
      top_mods = top_mods + 1
      if m.enabled and m.pos > 0 then
        place = place + 1
        m.pos = place
      else
        m.pos = 0
      end
    end
  end
  for _, m in ipairs(mods) do
    if m.family ~= nil then
      m.pos = (m.enabled and m.pos > 0) and m.family.pos or 0
    end
  end
  cnt.mods, cnt.active = top_mods, place
  profiles = {}
  for k = 0, cnt.profiles - 1 do
    profiles[k + 1] = Str(Call(M.PROFILE_NAME, k))
  end
end

local function Text(m, what)
  m.texts = m.texts or {}
  if m.texts[what] == nil then
    m.texts[what] = Str(Call(M.GET_TEXT, m.idx, what))
  end
  return m.texts[what]
end

local function NameOf(id)
  id = KeyOf(id)
  if id == BASE and base_mod ~= nil then return base_mod.name end
  for _, m in ipairs(mods) do
    if m.id == id then
      return m.name
    end
  end
  return id
end

local function ModById(id)
  id = KeyOf(id)
  if id == BASE then return base_mod end
  for _, m in ipairs(mods) do
    if m.id == id then
      return m
    end
  end
  return nil
end

-- accent / case folded search key (the framework's folding, VRFW.text_fold)
local function Fold(s)
  return VRFW.text_fold.fold(s)
end

-- warnings of a mod in plain words: {red, text}
local function Warnings(m)
  local out = {}
  for line in string.gmatch(Text(m, 7), "[^\n]+") do
    local kind, other, count, wins, detail = string.match(line, "^(%a+)|([^|]*)|(%d+)|(%d)|(.*)$")
    local o = NameOf(other or "")
    if kind == "missing" then
      out[#out + 1] = {true, T("w_missing", {o = o})}
    elseif kind == "disabled" then
      out[#out + 1] = {m.enabled, T("w_disabled", {o = o})}
    elseif kind == "version" then
      local c, v = string.match(detail or "", "^(.-)|(.*)$")
      out[#out + 1] = {true, T("w_version", {o = o, c = c or "", v = v or ""})}
    elseif kind == "incompatible" then
      out[#out + 1] = {m.enabled, T("w_incompat", {o = o})}
    elseif kind == "shared" then
      out[#out + 1] = {false, T(wins == "1" and "w_win" or "w_lose", {n = count, o = o})}
    elseif kind == "duplicate" then
      out[#out + 1] = {true, T("w_dup")}
    end
  end
  return out
end

-- the mods the grid shows: search, filter, sort
-- true when mod m passes the list's search q (folded) and view filter f
local function Passes(m, q, f)
  local ok = true
  if q ~= "" then
    local hay = m.name .. " " .. m.id .. " " .. m.author .. " " .. Text(m, 8)
    for _, mm in ipairs(m.modules or {}) do
      hay = hay .. " " .. mm.name .. " " .. mm.id .. " " .. (mm.mname or "")
    end
    ok = string.find(Fold(hay), q, 1, true) ~= nil
  end
  if ok and f == "on" then
    ok = m.enabled
  elseif ok and f == "off" then
    ok = not m.enabled
  elseif ok and f == "warn" then
    ok = m.level > 0 or m.nwarn > 0 or (m.enabled and m.state == 1)
  elseif ok and f == "pending" then
    ok = m.pending
  end
  return ok
end

local function Shown()
  local q = Fold(ui.query)
  local f = FILTERS[ui.filter]
  local out = {}
  for _, m in ipairs(mods) do
    -- a module mod is a row of its parent's page, not a card
    if m.family == nil and Passes(m, q, f) then
      out[#out + 1] = m
    end
  end
  local s = SORTS[ui.sort]
  if s == "order" then
    -- the load order: the numbered (switched-on) mods by their number, then the others (greyed, no number)
    table.sort(out, function(a, b)
      local pa, pb = a.pos > 0 and a.pos or math.huge, b.pos > 0 and b.pos or math.huge
      if pa ~= pb then return pa < pb end
      return a.order < b.order
    end)
  elseif s == "name" then
    table.sort(out, function(a, b)
      local fa, fb = Fold(a.name), Fold(b.name)
      if fa == fb then return a.order < b.order end
      return fa < fb
    end)
  elseif s == "size" then
    table.sort(out, function(a, b)
      if a.size == b.size then return a.order < b.order end
      return a.size > b.size
    end)
  elseif s == "date" then
    table.sort(out, function(a, b)
      local da, db = Text(a, 9), Text(b, 9)
      if da == db then return a.order < b.order end
      return da > db
    end)
  end
  if base_mod ~= nil and Passes(base_mod, q, f) then
    -- the framework's row stays first in every sort: its page holds its information, problems and settings
    table.insert(out, 1, base_mod)
  end
  return out
end

-- the load order list: switched-on mods (top = highest priority), then a header, then the others
local function OrderRows()
  local on, off = {}, {}
  for _, m in ipairs(mods) do
    -- a module mod is not a row of its own: it loads with its parent and moves with it
    if m.family == nil then
      if m.enabled then on[#on + 1] = m else off[#off + 1] = m end
    end
  end
  local rows = {{head = true, first = true, text = T("order_on", {n = #on})}}
  for _, m in ipairs(on) do rows[#rows + 1] = {m = m} end
  rows[#rows + 1] = {head = true, text = T("order_off", {n = #off})}
  for _, m in ipairs(off) do rows[#rows + 1] = {m = m} end
  return rows
end

-- The hash of texture `path`, asked from the game the first time it is named.
function CE.texture(path)
  if not tex_asked[path] then
    tex_asked[path] = true
    tex_wait, tex_frames = true, 0
    funcLuaMenuCommand(C.LOAD_TEX, path)
  end
  return Crc(path)
end

-- the picture of a mod: (texture crc, card sprite crc, large sprite crc) or nil (placeholder)
local thumbs = {}
local function Thumb(m)
  if thumbs[m.id] == nil then
    local path, card, large = Call(M.THUMB, m.id)
    if type(path) == "string" and path ~= "" then
      thumbs[m.id] = {Crc(path), Crc(card), Crc(large), path}
    elseif m.preview then
      -- a preview.g4tx the ModLoader serves (built by the app): vrfw_mods/preview/<id>.g4tx, 16:9 sprites _t / _l
      local p = "#/menu/vrfw_mods/preview/" .. m.id .. ".g4tx"
      thumbs[m.id] = {Crc(p), Crc("vrfw_mp_" .. m.id .. "_t"), Crc("vrfw_mp_" .. m.id .. "_l"), p}
    else
      thumbs[m.id] = false
    end
  end
  local t = thumbs[m.id]
  if t then
    CE.texture(t[4])
  end
  return t or nil
end

local function TileOf(id)
  return Crc(id) % NTILES
end

local function Initials(m)
  local s = m.name ~= "" and m.name or m.id
  local words = {}
  for w in string.gmatch(s, "[^%s%-_]+") do
    words[#words + 1] = Chars(w)
  end
  local out = {}
  if #words >= 2 then
    out = {words[1][1].ch, words[2][1].ch}
  elseif #words == 1 then
    out = {words[1][1].ch, words[1][2] and words[1][2].ch or nil}
  end
  local t = string.upper(table.concat(out))
  return t ~= "" and t or "?"
end

-- the icon of a mod's mod.toml (`icon`): (texture crc, sprite crc) or nil (the initials in the grey frame)
local icons = {}
local function IconOf(m)
  if icons[m.id] == nil then
    local path, sprite, game = Call(M.ICON, m.id)
    icons[m.id] = (type(path) == "string" and path ~= "") and {Crc(path), Crc(Str(sprite)), path, game == true} or false
  end
  local t = icons[m.id]
  if t then
    CE.texture(t[3])
  end
  return t or nil
end

local used, was, sent = {}, {}, {}

local overflow = 0
local function Slot(key)
  local L = FREE[key]
  if L == nil then
    return nil
  end
  local i = used[key] or 0
  if i >= L[2] then
    overflow = overflow + 1
    return nil
  end
  used[key] = i + 1
  return i
end

-- funcLuaMenuCommand for one instance, skipped when it repeats the last one sent for that property
local function Set(layer, idx, prop, cmd, ...)
  local k = layer .. ":" .. idx .. ":" .. prop
  local args = table.pack(...)
  local sig = {}
  for i = 1, args.n do
    sig[#sig + 1] = tostring(args[i])
  end
  sig = table.concat(sig, ",")
  if sent[k] == sig then
    return
  end
  sent[k] = sig
  funcLuaMenuCommand(cmd, ...)
end

local function Show(key, i)
  local L = FREE[key][1]
  Set(L, i, "vis", C.LAYER_VISIBLE, L, i, true)
end

-- a quad of the atlas (or of a mod's texture): top-left x, y, w x h
local function Quad(key, sprite, x, y, w, h, alpha, tex)
  local i = Slot(key)
  if i == nil then
    return nil
  end
  local L = FREE[key][1]
  Show(key, i)
  Set(L, i, "sc", C.SCALE, L, w / G.Q, h / G.Q, 1, i)
  Set(L, i, "sp", C.SPRITE, L, tex or ATLAS, sprite, N.QUAD, 0, i)
  Set(L, i, "pos", C.POS, L, x + w / 2, -(y + h / 2), 0, i)
  Set(L, i, "a", C.ALPHA, L, i, 0, alpha or 1)
  return i
end

-- The retail plate a game picture icon sits on (the list tabs' icon base), its size and the icon's inset and aspect.
local ICON_BASE = {atlas = "#/menu/20_cmn/cmn06/cmn06_20/cmn06_20.g4tx", sprite = Crc("icon_base01"), W = 92, H = 52, INSET = 2,
                   ICON_ASPECT = 3 / 2}

-- Mod m's icon in the square slot (x, y, s) of layer q: a game picture on the retail icon base as wide as the slot, a PNG
-- icon filling the slot. False when the mod has no icon (the caller draws its initials).
function CE.draw_icon(q, m, x, y, s, alpha)
  local ic = m ~= nil and IconOf(m) or nil
  if ic == nil then
    return false
  end
  if not ic[4] then
    Quad(q, ic[2], x, y, s, s, alpha, ic[1])
    return true
  end
  local bh = s * ICON_BASE.H / ICON_BASE.W
  local by = y + (s - bh) / 2
  Quad(q, ICON_BASE.sprite, x, by, s, bh, alpha, CE.texture(ICON_BASE.atlas))
  local ih = bh - 2 * ICON_BASE.INSET
  local iw = ih * ICON_BASE.ICON_ASPECT
  Quad(q, ic[2], x + (s - iw) / 2, by + ICON_BASE.INSET, iw, ih, alpha, ic[1])
  return true
end

-- a text anchored at x (left / centre / right edge by the layer: TL / TC / TR, PL / PC / PR), vertical middle y
local ALIGN = {TL = 0, TC = 1, TR = 2, PL = 0, PC = 1, PR = 2}
local function Txt(key, s, x, y, sc)
  if s == nil or s == "" then
    return nil
  end
  local i = Slot(key)
  if i == nil then
    return nil
  end
  sc = sc or 1
  local L = FREE[key][1]
  local a = ALIGN[key]
  local ox = a == 0 and G.TXT_X or (a == 1 and (G.TXT_X + G.TXT_W / 2) or (G.TXT_X + G.TXT_W))
  Show(key, i)
  Set(L, i, "band", C.MESH_VISIBLE, L, N.BAND, false, i)
  if INK ~= "[CB]" then
    s = (string.gsub(s, "%[CB%]", INK))
  end
  Set(L, i, "txt", C.TEXT, L, N.TEXT, s, i)
  Set(L, i, "sc", C.SCALE, L, sc, sc, 1, i)
  Set(L, i, "pos", C.POS, L, x - ox * sc, G.TXT_MID * sc - y, 0, i)
  return i
end

local function Hit(x0, y0, w, h, id, act)
  hits[#hits + 1] = {x0, y0, x0 + w, y0 + h, id, act}
end

local function Begin()
  used, hits = {}, {}
end

-- hide what the last drawing used and this one did not
local function Finish()
  for _, key in ipairs(FREE_ORDER) do
    local L = FREE[key][1]
    local n = used[key] or 0
    for i = n, (was[key] or FREE[key][2]) - 1 do
      Set(L, i, "vis", C.LAYER_VISIBLE, L, i, false)
    end
    was[key] = n
  end
end

local function ProfileName()
  local name = profiles[cnt.profile + 1] or ""
  if name == "" or name == "Principal" then
    name = T("profile_main")
  end
  return name
end

local function DrawHeader()
  local s = T("header")
  funcLuaMenuCommand(C.TEXT, L_HEADER, N.SUB_TITLE, s)
end

local function TabLabel(k)
  if k == 1 then
    return T("tab_installed", {n = cnt.mods or #mods})
  end
  return CE.problem_tab_label()
end

local function DrawTabs()
  -- the navy bar (Q, the tabs, E) at the top left
  Quad("Q0", SP("tabbar"), G.TABBAR_X, G.TAB_Y, G.TABBAR_W, G.TAB_H)
  for k = 1, G.NTABS do
    local x = G.TAB_X + (k - 1) * G.TAB_STEP
    local sel = ui.tab == k
    local hot = mouse.on and mouse.hot == "tab" .. k and not sel
    local locked = ui.page ~= nil and not sel
    if sel or hot then
      Quad("Q2", SP(sel and "tab_sel" or "tab_hot"), x, G.TAB_Y, G.TAB_W, G.TAB_H, locked and 0.45 or 1)
    end
    Txt("TC", (sel and "" or "[CWG]") .. Cut(TabLabel(k), Fit(G.TAB_W - 40, 0.82)) .. (sel and "" or "[C]"), x + G.TAB_W / 2, G.TAB_Y + G.TAB_H / 2, 0.82)
    if ui.page == nil then
      Hit(x + 10, G.TAB_Y, G.TAB_W - 20, G.TAB_H, "tab" .. k, function() SwitchTab(k) end)
    end
  end
  if ui.page == nil and G.NTABS > 1 then
    Txt("TC", K.L2, G.TAB_X - 22, G.TAB_Y + G.TAB_H / 2, 0.8)
    Txt("TC", K.R2, G.TAB_X + G.NTABS * G.TAB_STEP + 28, G.TAB_Y + G.TAB_H / 2, 0.8)
  end
  -- the profile (the last button of the row under the tabs)
  if have then
    local s = T("profile", {p = ProfileName()})
    if cnt.profiles > 1 then
      s = s .. " (" .. (cnt.profile + 1) .. "/" .. cnt.profiles .. ")"
    end
    local pfoc = mouse.hot == "profile" or (ui.tab == 1 and ui.zone == "bar" and ui.bar == 4 and not CE.page_focused() and ui.page == nil)
    CE.row_tool(G.PROF_X, {id = "profile", key = K.X, text = s, value = ProfileName(), w = G.PROF_W,
                          act = function() StartCo(ProfileFlow) end}, ui.page == nil, pfoc)
  end
end

local function FilterLabel()
  return T("filter_" .. FILTERS[ui.filter])
end

local function SortLabel()
  return T("sort_" .. SORTS[ui.sort])
end

-- same places, the count inside the search box -------------------------------------------------------------------------

-- the search box: s = {query, hint (text key), count (nil = none), foc, on, id (hit id), act (click)}
function CE.row_search(s)
  local x, y, w, h = G.ROW_SEARCH_X, G.TOOLS_Y, G.ROW_SEARCH_W, G.TOOLS_H
  local cy = y + h / 2
  Quad("Q0", SP(s.foc and "search2_sel" or "search2"), x, y, w, h, s.on and 1 or 0.45)
  local q = (s.query or "") ~= "" and ("[CB]" .. Cut(s.query, 14) .. "[C]") or ("[CWG]" .. T(s.hint) .. "[C]")
  Txt("TL", q, x + 20, cy, 0.72)
  if not s.on then
    return
  end
  Txt("TR", "[CWG]" .. K.R3 .. "[C]", x + w - 12, cy, 0.66)
  if s.count ~= nil then
    -- the count, small, inside the box
    Txt("TR", "[CWG]" .. Cut(s.count, Fit(w / 2 - 30, 0.56)) .. "[C]", x + w - 50, cy, 0.56)
  end
  Hit(x, y, w, h, s.id or "search", s.act)
end

function CE.row_tool(x, t, live, foc)
  local y, h, tw = G.TOOLS_Y, G.TOOLS_H, t.w or G.ROW_FILTER_W
  local cy = y + h / 2
  Quad("Q0", SP(foc and "tool2_sel" or "tool2"), x, y, tw, h, live and 1 or 0.45)
  Txt("TL", (live and "" or "[CWG]") .. t.key .. (live and "" or "[C]"), x + 16, cy, 0.68)
  -- "View: All" when it fits, else the value alone after its key (the key is the control's icon)
  local label = Units(t.text) <= Fit(tw - 64, 0.66) and t.text or t.value
  Txt("TL", (live and "" or "[CWG]") .. Cut(label, Fit(tw - 64, 0.66)) .. (live and "" or "[C]"), x + 50, cy, 0.66)
  if live then
    Hit(x, y, tw, h, t.id, t.act)
  end
end

-- the row under the tabs: search | Ver | Orden (| Perfil, DrawTabs), in the same places on both tabs.
local function DrawToolbar(shown)
  if have and cnt.changes > 0 then
    -- the restart notice: above the row, right of the header
    Quad("Q0", SP("notice"), G.NOTICE_X, G.NOTICE_Y, G.NOTICE_W, G.NOTICE_H)
    local s = cnt.changes == 1 and T("band1") or T("band", {n = cnt.changes})
    Txt("TL", "[CB]" .. Cut(s, Fit(G.NOTICE_W - 60, 0.66)) .. "[C]", G.NOTICE_X + 46, G.NOTICE_Y + G.NOTICE_H / 2, 0.66)
  end
  if ui.page ~= nil then
    CE.draw_page_row(ui.page)
    return
  end
  if ui.tab == 2 then
    CE.draw_problem_filters()
    return
  end
  local tab = ui.tab
  local focus = tab == 1 and ui.zone == "bar"
  CE.row_search({on = tab == 1, query = ui.query, hint = "search_hint", foc = (focus and ui.bar == 1) or mouse.hot == "search",
             count = (tab == 1 and have) and T("count_short", {n = #shown - ((shown[1] ~= nil and shown[1] == base_mod) and 1 or 0), t = cnt.mods or #mods, a = cnt.active}) or nil,
             act = function() StartCo(SearchFlow) end})
  -- View / Order: "Installed" only (drawn off elsewhere: the row never moves)
  local tools = {{x = G.ROW_FILTER_X, w = G.ROW_FILTER_W, id = "filter", key = K.L3, text = T("filter", {f = FilterLabel()}), value = FilterLabel(), bar = 2, act = function() CycleFilter(1) end},
                 {x = G.ROW_SORT_X, w = G.ROW_SORT_W, id = "sort", key = K.SELECT, text = T("sort", {s = SortLabel()}), value = SortLabel(), bar = 3, act = function() CycleSort(1) end}}
  for _, t in ipairs(tools) do
    local live = tab == 1
    CE.row_tool(t.x, t, live, live and ((focus and ui.bar == t.bar) or mouse.hot == t.id))
  end
end

-- state badge of a mod: sprite, text
local function Badge(m)
  if m.enabled and m.state == 1 then
    return "pill_red", T("badge_skip")
  elseif m.pending then
    return "pill_amber", T(m.enabled and "badge_will_on" or "badge_will_off")
  elseif m.enabled then
    return "pill_green", T("badge_on")
  end
  return "pill_grey", T("badge_off")
end

local function DrawScrollbar(total_rows, first, visible, x, y0, h, set)
  if total_rows <= visible then
    return
  end
  Quad("Q2", SP("track"), x, y0, G.SB_W, h)
  local th = math.max(40, h * visible / total_rows)
  local ty = y0 + (h - th) * first / math.max(1, total_rows - visible)
  Quad("Q1", SP("thumb"), x, ty, G.SB_W, th)
  if set ~= nil then
    local n = total_rows - visible
    Hit(x - 10, y0, G.SB_W + 20, h, "sbar", function()
      mouse.drag = {y0 = y0, h = h, th = th, n = n, set = set}
      CE.drag_to(mouse.y)
    end)
  end
end

local function DrawGrid()
  local shown = Shown()
  CE.list_box(G.LIST_PANE_W)
  if not have or #shown == 0 then
    -- one white plate with the reason, the panel empty
    local title = (not have) and "" or (#mods == 0 and T("empty_title") or T("no_match_title"))
    local desc = (not have) and T("noloader") or (#mods == 0 and T("empty_desc") or T("no_match_desc"))
    Quad("Q2", SP("white"), G.LIST_X, G.LIST_Y, G.LIST_ROW_W - 12, 200)
    local y = G.LIST_Y + 44
    if title ~= "" then
      Txt("TL", "[CN]" .. Cut(title, Fit(G.LIST_ROW_W - 80, 1.0)) .. "[C]", G.LIST_X + 30, y, 1.0)
      y = y + 46
    end
    for i, l in ipairs(Wrap(desc, Fit(G.LIST_ROW_W - 80, 0.78), 3)) do
      Txt("TL", "[CB]" .. l .. "[C]", G.LIST_X + 30, y + (i - 1) * 34, 0.78)
    end
    return shown
  end
  for k = 0, G.LIST_ROWS - 1 do
    local n = ui.top + k + 1
    local m = shown[n]
    if m ~= nil then
      local cur = ui.zone == "grid" and n == ui.sel
      CE.list_row(k, m, cur and not CE.page_focused(), "card" .. m.id, "btn" .. m.id, function() SelectMod(m.id) Draw() end, nil, cur)
    end
  end
  DrawScrollbar(#shown, ui.top, G.LIST_ROWS, G.LIST_SB_X, G.LIST_Y, G.LIST_ROWS * G.ROW_STEP - (G.ROW_STEP - G.ROW_H), function(f)
    ui.top = f
    ui.sel = math.max(ui.top + 1, math.min(ui.sel, ui.top + G.LIST_ROWS))
    ui.zone = "grid"
  end)
  return shown
end

-- right-hand information panel of the list pages: title bar + lines {text, scale}
local function DrawPanel(title, lines)
  CE.panel_frame()
  Txt("TL", Cut(title, Fit(G.PANEL_W - 160, 1.0)), G.PANEL_X + 96, G.PANEL_Y + G.PANEL_HEAD / 2, 1.0)
  local x, w = G.PANEL_X + 30, G.PANEL_W - 60
  local y = G.PANEL_BODY_Y + 36
  for _, l in ipairs(lines) do
    if l.gap then
      y = y + l.gap
    else
      local sc = l.sc or 0.78
      for _, t in ipairs(Wrap(l.t, Fit(w, sc), l.max or 3)) do
        if y < G.PANEL_BODY_Y + G.PANEL_BODY_H - 24 then
          Txt("TL", (l.c or "[CB]") .. t .. "[C]", x, y, sc)
        end
        y = y + math.floor(34 * sc / 0.78)
      end
    end
  end
end

local function UpdateButtonGuide()
  local texts, icons, offs, cmds = {}, {}, {}, {}
  local function add(text, icon, cmd, off)
    if text ~= nil then
      texts[#texts + 1], icons[#icons + 1], offs[#offs + 1], cmds[#cmds + 1] = text, icon, off or 18, cmd
    end
  end
  local m = nil
  if CE.page_focused() then
    m = ModById(ui.popup.id)
  elseif ui.page == nil and ui.tab == 1 and ui.zone == "grid" then
    m = Shown()[ui.sel]
  elseif ui.page == nil and ui.tab == 2 then
    -- "Problems": A opens the page of the focused problem's mod
    if CE.problem_mod() ~= nil then
      add(TextId("g_open_mod") or TextId("g_details"), I_ENTER, Crc("CMD_ENTER"))
    end
  end
  if ui.page ~= nil or (ui.tab == 1 and ui.zone == "bar") then
    -- a list page or the top row: A (a text the game lacks: "Accept")
    add(G_ACCEPT, I_ENTER, Crc("CMD_ENTER"), 0)
  elseif CE.page_focused() then
    -- the page's own buttons show their keys (A, Y, L1 / R1): no second copy at the bottom
  elseif have and m ~= nil then
    if m.enabled and m.family == nil and m.pos > 0 and ui.tab == 1 and ui.zone == "grid" then
      texts, icons, offs, cmds = {0, TextId("g_order") or RT_MOVE}, {I_L1, I_R1}, {0, 54}, {Crc("CMD_FUNCL1"), Crc("CMD_FUNCR1")}
    end
    if m ~= base_mod then
      add(TextId("g_toggle") or (m.enabled and RT_OFF or RT_ON), I_ENTER, Crc("CMD_ENTER"))
    end
    if not CE.page_focused() then
      add(TextId("g_details"), I_F1, Crc("CMD_FUNC1"))
    end
  end
  if have and ui.page == nil and not CE.page_focused() then
    add(TextId("g_profile"), I_F4, Crc("CMD_FUNC4"))
  end
  if ui.page == nil and not CE.page_focused() then
    for _, e in ipairs(Extras()) do
      local id = type(e.key) == "string" and TextIdKey(e.key) or nil
      if id ~= nil and type(e.icon) == "number" and type(e.cmd) == "number" then
        add(id, e.icon, e.cmd)
      end
    end
  end
  -- sent only when it changes (it is rebuilt by the engine: a flicker at every key otherwise)
  local sig = table.concat(texts, ",") .. "|" .. table.concat(icons, ",") .. "|" .. table.concat(cmds, ",")
  if sent.guide ~= sig then
    sent.guide = sig
    funcLuaMenuCommand(C.GUIDE_SET, MENU, L_BTN_GUIDE, texts, icons, offs, {}, {})
    funcLuaMenuCommand(C.GUIDE_CMD, MENU, L_BTN_GUIDE, cmds)
  end
end

local function ClampGrid(shown)
  local n = #shown
  if n == 0 then
    ui.sel, ui.top = 1, 0
    return
  end
  ui.sel = math.max(1, math.min(ui.sel, n))
  local row = math.floor((ui.sel - 1) / G.COLS)
  if row < ui.top then
    ui.top = row
  elseif row >= ui.top + G.LIST_ROWS then
    ui.top = row - G.LIST_ROWS + 1
  end
  ui.top = math.max(0, math.min(ui.top, math.max(0, math.ceil(n / G.COLS) - G.LIST_ROWS)))
end

local function DrawToast()
  if ui.toast ~= nil and ui.popup == nil then
    -- under the info panel (the top rows are full)
    local y = G.PANEL_BODY_Y + G.PANEL_BODY_H + 14
    Quad("Q0", SP("night"), G.PANEL_X, y, G.PANEL_W, 44)
    Txt("TC", Cut(ui.toast, Fit(G.PANEL_W - 30, 0.64)), G.PANEL_X + G.PANEL_W / 2, y + 22, 0.64)
  end
end

function Draw()
  if not CE.ready() then
    return
  end
  CE.dock_sync()
  Begin()
  DrawHeader()
  DrawTabs()
  DrawToolbar(ui.page == nil and ui.tab == 1 and Shown() or {})
  if ui.page ~= nil then
    Screen.draw_page()
  elseif ui.tab == 1 then
    ClampGrid(Shown())
    DrawGrid()
  else
    CE.draw_problems()
  end
  if ui.popup ~= nil then
    Screen.draw_details()
  end
  DrawToast()
  Finish()
  CE.background()
  UpdateButtonGuide()
end

local function Toast(s)
  ui.toast, ui.toast_t = s, 150
end

local function Message(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  VRFW.question.notice(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  CE.bg_dirty = true       -- a window / keyboard closed: the background again
end

-- yes / no window: true = yes
local function Ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  local yes = VRFW.question.ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  CE.bg_dirty = true       -- a window / keyboard closed: the background again
  return yes
end

function StartCo(fn)
  if co ~= nil then
    return
  end
  co = coroutine.create(fn)
  local ok, err = coroutine.resume(co)
  if not ok then
    logger("error", tostring(err))
    co = nil
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
    CE.bg_dirty = true       -- a window / keyboard closed: the background again
  elseif coroutine.status(co) == "dead" then
    co = nil
  end
end

-- the game's keyboard; nil = nothing typed (B)
local function Keyboard(initial, title_name, fallback_title, max)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  if funcLuaCommand(KB.BUSY) then
    funcLuaCommand(KB.CLOSE, "")
  end
  local title = TextId(title_name) or fallback_title
  funcLuaCommand(KB.OPEN, 0, initial or "", title, 0, max, 1, 0, 0, "", 0, 0, true, true, 1, "", 0, false)
  local n = 0
  while not funcLuaCommand(KB.BUSY) and n < 30 do    -- until the keyboard is up
    coroutine.yield()
    n = n + 1
  end
  while funcLuaCommand(KB.BUSY) do
    coroutine.yield()
  end
  local s = funcLuaCommand(KB.RESULT)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  CE.bg_dirty = true       -- a window / keyboard closed: the background again
  if type(s) ~= "string" then
    return nil
  end
  return (string.gsub(string.gsub(s, "^%s+", ""), "%s+$", ""))
end

-- the mod the keys act on: the popup's, the grid's selected card, the load order's row
local function Focused()
  if CE.page_focused() then
    return ModById(ui.popup.id)
  end
  if ui.page ~= nil then
    return nil
  end
  if ui.tab == 1 and ui.zone == "grid" then
    return Shown()[ui.sel]
  elseif ui.tab == 2 then
    return CE.problem_mod()
  end
  return nil
end

-- keep the selection on mod `id` (grid and load order)
function SelectMod(id)
  local shown = Shown()
  for k, m in ipairs(shown) do
    if m.id == id then
      ui.sel = k
      ui.zone = "grid"
    end
  end
  for k, r in ipairs(OrderRows()) do
    if r.m ~= nil and r.m.id == id then
      ui.osel = k
    end
  end
end

function Toggle()
  local m = Focused()
  if not have or m == nil or m == base_mod then
    funcLuaCommand(C.SE, SE_NG)
    if not have then
      Message(T("noloader"))
    end
    return
  end
  local id = m.id
  local active_modules = RV.active_modules(m)
  if m.enabled and active_modules > 0 and not Ask(T("confirm_family_off", {n = NameOf(id), c = active_modules})) then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local ok, msg = RV.switch_mod(m, not m.enabled)
  if ok ~= true then
    funcLuaCommand(C.SE, SE_NG)
    Message(T("fail"))
    Draw()
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  changed = true
  SelectMod(id)
  Toast(msg)
  Draw()
end

-- The module mods of family parent `m` that are on.
function RV.active_modules(m)
  local n = 0
  for _, mm in ipairs(m.modules or {}) do
    if mm.enabled then n = n + 1 end
  end
  return n
end

function RV.switch_mod(m, on)
  local ok = Call(M.SET_ENABLED, m.idx, on and 1 or 0)
  Log("toggle", m.id, on and "ON" or "OFF", "ok", tostring(ok))
  if ok ~= true then
    ReadAll()
    return false
  end
  local id, nmods, parent = m.id, RV.active_modules(m), nil
  if on and m.family ~= nil and not m.family.enabled then
    parent = m.family.id
  end
  ReadAll()
  local now, again = ModById(id), false
  if now ~= nil and not on then
    for _, mm in ipairs(now.modules) do
      if mm.enabled then
        Call(M.SET_ENABLED, mm.idx, 0)
        again = true
      end
    end
  elseif now ~= nil and parent ~= nil then
    local p = ModById(parent)
    if p ~= nil and not p.enabled then
      Call(M.SET_ENABLED, p.idx, 1)
      again = true
    end
  end
  if again then
    ReadAll()
    now = ModById(id)
  end
  local n = NameOf(id)
  local restored = (on and now ~= nil) and RV.active_modules(now) or 0
  -- Back to how the game started (off -> on): nothing to restart for.
  if now ~= nil and now.live and not now.pending then
    return true, T(on and "toast_live_on" or "toast_live_off", {n = n})
  elseif now ~= nil and not now.pending then
    return true, T("toast_same", {n = n})
  elseif not on and nmods > 0 then
    return true, T("toast_family_off", {n = n, c = nmods})
  elseif parent ~= nil then
    return true, T("toast_parent_on", {n = n, o = NameOf(parent)})
  elseif restored > 0 then
    return true, T("toast_family_on", {n = n, c = restored})
  end
  return true, T(on and "toast_on" or "toast_off", {n = n})
end

-- a "Modules" row of a mod's page: its module mod switched on / off (with the family rules of RV.switch_mod)
function RV.toggle_module(mm)
  local ok, msg = RV.switch_mod(mm, not mm.enabled)
  funcLuaCommand(C.SE, ok and SE_OK or SE_NG)
  if ok then
    changed = true
    RV.cache = {}
  end
  Toast(ok and msg or T("fail"))
  Draw()
end

function Order(delta)
  -- the load order is edited from the mods list (its rows or a mod's page), not from the top row or a list page
  if ui.page ~= nil or ui.tab ~= 1 or ui.zone ~= "grid" then
    funcLuaCommand(C.SE, SE_NG)
    return
  end

  local m = Focused()
  -- a module mod has no place of its own: it moves with its parent
  if not have or m == nil or not m.enabled or m.family ~= nil or m.pos == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if SORTS[ui.sort] ~= "order" then
    -- another sort shows the list out of load order: it returns to load order first, the move happens on the next press
    ui.sort = 1
    SelectMod(m.id)
    funcLuaCommand(C.SE, SE_MOVE)
    Toast(T("sort", {s = SortLabel()}))
    Draw()
    return
  end
  if delta < 0 and m.pos <= 1 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local ok, moved = Call(M.MOVE, m.idx, delta)
  if ok ~= true or moved ~= true then
    funcLuaCommand(C.SE, SE_NG)
    if ok ~= true then
      ReadAll()
      Draw()
    end
    return
  end
  funcLuaCommand(C.SE, SE_MOVE)
  changed = true
  local id = m.id
  ReadAll()
  SelectMod(id)
  local n = ModById(id)
  Toast(T("toast_order", {n = NameOf(id), p = n and n.pos or 0, t = cnt.active}))
  Draw()
end

function OpenDetails()
  local m = Focused()
  if m == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  RV.cache = {}
  local view, srow = nil, 1
  if ui.tab == 2 then
    -- from "Problems": the page opens on the view that lists the focused problem
    view = CE.problem_view()
  end
  if ui.tab ~= 1 then
    -- the page lives in the Mods tab: go there with the mod selected (the search and the filter cleared when they hide it)
    ui.tab, ui.zone = 1, "grid"
    SelectMod(m.id)
    local s = Shown()[ui.sel]
    if s == nil or s.id ~= m.id then
      ui.query, ui.filter, ui.sel, ui.top = "", 1, 1, 0
      SelectMod(m.id)
    end
  end
  if view ~= nil or ui.popup == nil or ui.popup.id ~= m.id then
    ui.popup = CE.new_page(m, view, srow)
  end
  ui.pane = "page"
  Draw()
end

-- B on the page: the page it was opened from, else the focus back to the list (the page stays docked)
function ClosePopup()
  funcLuaCommand(C.SE, SE_BACK)
  local p = ui.popup
  if p ~= nil and p.back ~= nil then
    ui.popup = p.back
    SelectMod(ui.popup.id)
  else
    ui.pane = "list"
    if p ~= nil then
      SelectMod(p.id)
    end
  end
  Draw()
end

-- The keys go to the docked page.
function CE.page_focused()
  return ui.popup ~= nil and ui.pane == "page"
end

-- A fresh page of mod m on view `view` (its default when m has no such view: the modules of a mod with modules, else the information).
function CE.new_page(m, view, srow)
  local known = false
  for _, v in ipairs(RV.views(m)) do
    known = known or v == view
  end
  if not known then
    view = RV.has_modules(m) and "modules" or "info"
  end
  return {kind = "mod", id = m.id, btn = 1, view = view, top = 0, srow = srow or 1, stop = 0, szone = "rows", mrow = 1}
end

-- The docked page follows the list: the selected mod's page (on the same view) while the list has the keys; none outside the Mods tab.
function CE.dock_sync()
  if ui.page ~= nil then
    return
  end
  if ui.tab ~= 1 then
    ui.popup, ui.pane = nil, "list"
    return
  end
  if CE.page_focused() then
    return
  end
  local m = Shown()[ui.sel]
  if m == nil then
    ui.popup, ui.pane = nil, "list"
  elseif ui.popup == nil or ui.popup.id ~= m.id or ui.popup.back ~= nil then
    ui.popup = CE.new_page(m, ui.popup and ui.popup.view or nil)
  end
end

-- The mod page's tabs: L2 / R2 move to the previous / next view of RV.views (the full description closes first)
function RV.switch(d)
  local p = ui.popup
  local m = p and ModById(p.id)
  if m == nil then
    return
  end
  local views = RV.views(m)
  local k = 1
  for i, v in ipairs(views) do
    if v == p.view then
      k = i
    end
  end
  RV.go(views[(k - 1 + d) % #views + 1])
end

function RV.open_child(id, view)
  local o = ModById(id)
  if o == nil or ui.popup == nil or o.id == ui.popup.id then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  ui.popup = {kind = "mod", id = o.id, btn = 1, view = view or "info", top = 0, srow = 1, stop = 0, szone = "rows", mrow = 1,
              back = ui.popup}
  ui.pane = "page"
  SelectMod(o.id)
  Draw()
end

function RV.module_toggle(m, n)
  local r = RV.module_rows(m)[n]
  if r == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if r.mod == nil then
    RV.change(m, 1, r.opt)
    return
  end
  local need = RV.module_need(r.mod)
  if need ~= nil and not r.mod.enabled then
    funcLuaCommand(C.SE, SE_NG)
    Toast(T("module_needs", {o = need}))
    Draw()
    return
  end
  RV.toggle_module(r.mod)
end

function RV.modules_move(m, id)
  local p, n = ui.popup, #RV.module_rows(m)
  local d = (id == FN.UP and -1) or (id == FN.DOWN and 1) or (id == FN.LEFT and -RV.MOD_ROWS) or RV.MOD_ROWS
  local k = math.max(1, math.min(n, (p.mrow or 1) + d))
  funcLuaCommand(C.SE, k ~= p.mrow and SE_MOVE or SE_NG)
  p.mrow = k
  Draw()
end

function RV.module_open(m)
  local r = RV.module_rows(m)[ui.popup.mrow or 1]
  if r == nil or r.mod == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  RV.open_child(r.mod.id)
end

function RV.decide()
  local p = ui.popup
  local m = ModById(p.id)
  local v = RV.view()
  if m == nil or p.full then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if v == "info" then
    local t = RV.info_target(m)
    if t.kind == "chip" then
      RV.open_child(t.id)
    elseif t.kind == "desc" then
      RV.open_full()
    else
      StartCo(Toggle)
    end
  elseif v == "modules" then
    RV.module_toggle(m, p.mrow or 1)
  elseif v == "settings" and #RV.set_rows(m) > 0 and p.szone ~= "buttons" then
    RV.activate(m, p.srow or 1)
  else
    StartCo(Toggle)
  end
end

function RV.key(id)
  local p = ui.popup
  local m = ModById(p.id)
  if m == nil then
    return
  end
  local v = RV.view()
  local arrow = id == FN.UP or id == FN.DOWN or id == FN.LEFT or id == FN.RIGHT
  if id == FN.TAB_PREV or id == FN.TAB_NEXT then
    RV.switch(id == FN.TAB_PREV and -1 or 1)
  elseif id == FN.DETAILS then
    ClosePopup()
  elseif id == FN.ORDER_UP or id == FN.ORDER_DOWN then
    if frame - last_act >= 4 then
      last_act = frame
      Order(id == FN.ORDER_UP and -1 or 1)
    end
  elseif p.full then
    if arrow then
      local d = (id == FN.UP and -1) or (id == FN.DOWN and 1) or (id == FN.LEFT and -RV.FULL_ROWS) or RV.FULL_ROWS
      local n = #RV.full_lines(m)
      local t = math.max(1, math.min((p.ftop or 1) + d, math.max(1, n - RV.FULL_ROWS + 1)))
      funcLuaCommand(C.SE, t ~= p.ftop and SE_MOVE or SE_NG)
      p.ftop = t
      Draw()
    else
      funcLuaCommand(C.SE, SE_NG)
    end
  elseif arrow and v == "info" then
    RV.info_move(m, (id == FN.LEFT or id == FN.UP) and -1 or 1)
  elseif id == FN.PROFILE and v == "info" then
    RV.open_full()
  elseif arrow and v == "modules" then
    RV.modules_move(m, id)
  elseif id == FN.EXTRA3 and v == "modules" then
    RV.module_open(m)
  elseif id == FN.SEARCH and v == "modules" then
    RV.module_settings(m)
  elseif id == FN.PROFILE and v == "modules" then
    StartCo(Toggle)
  elseif id == FN.EXTRA3 and v == "settings" then
    RV.restore_default(m)
  elseif id == FN.PROFILE and v == "settings" then
    StartCo(function() RV.restore_mod(m) end)
  elseif arrow and v == "settings" and RV.settings_key(id) then
    -- "Settings": the keys went to the setting rows
  elseif (id == FN.UP or id == FN.DOWN) and (v == "problems" or v == "conflicts" or v == "news") then
    local n, rows = 0, RV.ROWS
    if v == "news" then
      n, rows = #RV.news_lines(m), RV.NEWS_ROWS
    else
      local r = RV.of(m.id)
      n = #(v == "problems" and r.problems or r.conflicts)
    end
    local t = math.max(0, math.min((p.top or 0) + (id == FN.UP and -1 or 1), n - rows))
    funcLuaCommand(C.SE, t ~= p.top and SE_MOVE or SE_NG)
    p.top = t
    Draw()
  elseif id == FN.SEARCH and v == "conflicts" then
    -- "Conflicts": R3 = who touches the first conflict's id on the page (the search box takes another)
    local e = RV.of(m.id).conflicts[(p.top or 0) + 1]
    RV.open_who(e and RV.who_id(e) or "")
  elseif id == FN.EXTRA3 and v ~= "news" and #RV.notes(m).notes > 0 then
    RV.go("news")
  else
    funcLuaCommand(C.SE, SE_NG)
  end
end

function SwitchTab(k)
  if ui.page ~= nil or CE.page_focused() then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  k = ((k - 1) % G.NTABS) + 1
  if k == ui.tab then
    return
  end
  funcLuaCommand(C.SE, SE_MOVE)
  ui.tab = k
  if k == 1 then
    ui.zone = "grid"
  end
  Draw()
end

function CycleFilter(d)
  ui.filter = ((ui.filter - 1 + d) % #FILTERS) + 1
  ui.sel, ui.top = 1, 0
  funcLuaCommand(C.SE, SE_MOVE)
  Draw()
end

function CycleSort(d)
  ui.sort = ((ui.sort - 1 + d) % #SORTS) + 1
  ui.sel, ui.top = 1, 0
  funcLuaCommand(C.SE, SE_MOVE)
  Draw()
end

-- R3 / the search bar: type part of a name (empty = no search)
function SearchFlow()
  if ui.tab ~= 1 then
    ui.tab = 1
  end
  local q = Keyboard(ui.query, "kb_search", RT_SEARCH, 24)
  if q ~= nil then
    ui.query = q
    ui.sel, ui.top, ui.zone = 1, 0, "grid"
    Log("search", q, "shown", #Shown())
  end
  Draw()
end

function ProfileFlow()
  if not have then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local k = cnt.profile + 1
  if k >= cnt.profiles then
    funcLuaCommand(C.SE, SE_OK)
    if Ask(T("profile_ask_new")) then
      local ok, nk = Call(M.PROFILE_NEW, T("profile_prefix"))
      if ok ~= true then
        Message(T("fail"))
        return
      end
      changed = true
      ReadAll()
      Draw()
      Message(T("profile_new_done", {p = profiles[Int(nk) + 1] or ""}))
      return
    end
    if cnt.profiles <= 1 then
      return
    end
    k = 0
  end
  if Call(M.PROFILE_SWITCH, k) ~= true then
    funcLuaCommand(C.SE, SE_NG)
    ReadAll()
    Draw()
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  changed = true
  Log("profile", k)
  ReadAll()
  Toast(T("toast_profile", {p = ProfileName()}))
  Draw()
end

function RunExtra(e)
  funcLuaCommand(C.SE, SE_OK)
  StartCo(function()
    if e.flow(MENU) ~= true then
      funcLuaCommand(C.SE, SE_NG)
    end
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
    CE.bg_dirty = true       -- a window / keyboard closed: the background again
    Draw()
  end)
end

CE.REVEAL_MAX = 30
function CE.reveal_reset()
  local need = 0
  for _, key in ipairs(FREE_ORDER) do
    need = need + FREE[key][2]
  end
  CE.rv = {need = need, got = {}, n = 0, ready = false, opened = nil, done = false, init = frame, per = {}, stuck = false}
end

CE.STUCK_FRAMES = 300
function CE.reveal_stuck()
  local rv = CE.rv
  if rv.stuck or rv.opened ~= nil or frame - (rv.init or 0) < CE.STUCK_FRAMES then
    return
  end
  rv.stuck = true
  local parts = {}
  for _, key in ipairs(FREE_ORDER) do
    parts[#parts + 1] = key .. " " .. (rv.per[key] or 0) .. "/" .. FREE[key][2]
  end
  Log("reveal", "STUCK: the input anchor never opened", "frames", frame - (rv.init or 0), "free layers set up",
      rv.n .. "/" .. rv.need, table.concat(parts, ", "))
end

-- every free layer set up (or the wait is over): the screen may draw
function CE.ready()
  local rv = CE.rv
  if rv == nil or rv.ready then
    return true
  end
  if rv.n >= rv.need or (rv.opened ~= nil and frame - rv.opened >= CE.REVEAL_MAX) then
    rv.ready = true
    Log("reveal", "free layers", rv.n .. "/" .. rv.need, "frames", rv.opened and (frame - rv.opened) or -1)
  end
  return rv.ready
end

-- Step: draw once ready (the anchor opened); until then, the "STUCK" line when it never opens
function CE.reveal_step()
  local rv = CE.rv
  if rv == nil or rv.done then
    return
  end
  CE.reveal_stuck()
  if not rv.ready and rv.opened ~= nil and CE.ready() then
    Draw()
  end
  rv.done = rv.ready and rv.opened ~= nil
end

function CE.background()
  if BG.on ~= true or BG.page ~= ui.page or CE.bg_dirty then
    BG.on, BG.page, CE.bg_dirty = true, ui.page, false
    funcLuaMenuCommand(C.LAYER_VISIBLE, BG.LAYER, 0, true)
  end
end

-- the cursor of every picker (dropdowns, grids): a cyan frame of four edges around a cell.
function CE.focus(layer, x, y, w, h, t)
  t = t or 5
  Quad(layer, SP("cyan"), x - t, y - t, w + 2 * t, t)
  Quad(layer, SP("cyan"), x - t, y + h, w + 2 * t, t)
  Quad(layer, SP("cyan"), x - t, y, t, h)
  Quad(layer, SP("cyan"), x + w, y, t, h)
end

local function MoveGrid(dx, dy)
  if ui.zone == "grid" and dx > 0 and ui.popup ~= nil then
    -- right from the list: the keys go to the docked page
    OpenDetails()
    return
  end
  local shown = Shown()
  local n = #shown
  if ui.zone == "bar" then
    if dy > 0 then
      if n > 0 then
        ui.zone = "grid"
        funcLuaCommand(C.SE, SE_MOVE)
      else
        funcLuaCommand(C.SE, SE_NG)
      end
    elseif dx ~= 0 then
      local b = math.max(1, math.min(4, ui.bar + dx))
      funcLuaCommand(C.SE, b ~= ui.bar and SE_MOVE or SE_NG)
      ui.bar = b
    else
      funcLuaCommand(C.SE, SE_NG)
    end
    Draw()
    return
  end
  if n == 0 then
    if dy < 0 then
      ui.zone = "bar"
      funcLuaCommand(C.SE, SE_MOVE)
      Draw()
    else
      funcLuaCommand(C.SE, SE_NG)
    end
    return
  end
  local s = ui.sel
  if dx ~= 0 then
    s = math.max(1, math.min(n, s + dx * G.LIST_ROWS))
  else
    s = s + dy * G.COLS
  end
  if dy < 0 and s < 1 then
    ui.zone = "bar"
    ui.bar = math.min(3, ((ui.sel - 1) % G.COLS) + 1)
    funcLuaCommand(C.SE, SE_MOVE)
    Draw()
    return
  end
  if dy > 0 and s > n then
    -- the last row: go to the last card if it is on a lower row
    if math.floor((n - 1) / G.COLS) > math.floor((ui.sel - 1) / G.COLS) then
      s = n
    else
      s = ui.sel
    end
  end
  s = math.max(1, math.min(n, s))
  if s == ui.sel then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_MOVE)
  ui.sel = s
  Draw()
end

-- A on a list row: the framework and a mod with modules open their page instead of switching
local function DecideRow()
  local m = Focused()
  if m ~= nil and (m == base_mod or RV.has_modules(m)) then
    OpenDetails()
  else
    StartCo(Toggle)
  end
end

-- A / Enter / a click without the mouse: the selected thing
local function Decide()
  if CE.page_focused() then
    RV.decide()
  elseif ui.tab == 1 then
    if ui.zone == "bar" then
      if ui.bar == 1 then
        StartCo(SearchFlow)
      elseif ui.bar == 2 then
        CycleFilter(1)
      elseif ui.bar == 3 then
        CycleSort(1)
      else
        funcLuaCommand(C.SE, SE_OK)
        StartCo(ProfileFlow)
      end
    else
      DecideRow()
    end
  else
    CE.problem_open()
  end
end

local function Close()
  Call(Crc("CMND_VRFW_NO_PHOTO"), "mods_menu", 0)   -- the game's photos again outside the Mods panel
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  funcLuaCommand(C.CLOSE_MENU, MENU)
end

local function CloseFlow()
  if changed then
    ReadAll()
    if cnt.changes > 0 then
      Message(T("restart_msg"))
    end
  end
  Close()
end

local function HitAt(x, y)
  for i = #hits, 1, -1 do         -- the last drawn (the popup, a card's button) wins
    local h = hits[i]
    if x >= h[1] and x < h[3] and y >= h[2] and y < h[4] then
      return h
    end
  end
  return nil
end

-- hover: cards / rows follow the pointer; buttons light up
local function Hover(h)
  local id = h and h[5] or nil
  local redraw = id ~= mouse.hot
  mouse.hot = id
  if id ~= nil and ui.popup ~= nil then
    -- a mod page's module / setting row under the pointer becomes the focused row (the one the keys move on from)
    local p = ui.popup
    local mr = tonumber(string.match(id, "^mrow(%d+)$") or string.match(id, "^mtog(%d+)$") or "")
    local sr = tonumber(string.match(id, "^set(%d+)$") or "")
    if mr ~= nil and mr ~= p.mrow then
      p.mrow, redraw = mr, true
    elseif sr ~= nil and (sr ~= p.srow or p.szone ~= "rows") then
      p.srow, p.szone, redraw = sr, "rows", true
    end
  end
  if id ~= nil and not CE.page_focused() then
    local cid = string.match(id, "^card(.+)$") or string.match(id, "^btn(.+)$")
    if cid ~= nil and ui.page == nil and ui.tab == 1 then
      local before = ui.sel
      SelectMod(cid)
      redraw = redraw or before ~= ui.sel or ui.zone ~= "grid"
      ui.zone = "grid"
    end
    if ui.tab == 2 and ui.page == nil and CE.problem_hover(id) then
      redraw = true
    end
    local on = tonumber(string.match(id, "^orow(%d+)$") or string.match(id, "^otag(%d+)$") or "")
    if on ~= nil and on ~= ui.osel then
      ui.osel, redraw = on, true
    end
    local pr = tonumber(string.match(id, "^prow(%d+)$") or "")
    if pr ~= nil and ui.page ~= nil and ui.page.kind == "list" and pr ~= ui.page.sel then
      ui.page.sel, ui.page.zone, redraw = pr, "list", true
    end
  end
  if redraw then
    Draw()
  end
end

local function Click()
  local h = HitAt(mouse.x, mouse.y)
  if h == nil then
    return false
  end
  Log("click", h[5])
  last_act = frame
  decided = true
  if ui.tab == 1 and ui.page == nil and ui.popup ~= nil then
    -- A click gives the keys to the pane it lands in.
    ui.pane = mouse.x >= G.WIN_X and "page" or "list"
  end
  h[6]()
  return true
end

local function PollMouse()
  -- CMD_ENTER of the last frame (mouse.enter): the poll acts on the press, not while A is held
  local enter_now = Call(C.CHECK_INPUT, C.MENU_CTRL, C.ENTER) == true
  local enter_edge = enter_now and not mouse.enter
  mouse.enter = enter_now
  -- a pointer click: the mouse's left button, or Accept / the free cursor's A while the pointer leads
  local click_now = Call(C.CHECK_INPUT, C.MENU_CTRL, C.LEFT) == true or (mouse.on and Call(C.CHECK_INPUT, C.MENU_CTRL, C.CLICK) == true)
  local click_edge = click_now and not mouse.click
  mouse.click = click_now
  local waiting_page = ui.page ~= nil and co ~= nil and ui.page.pick == nil and not ui.page.back and ui.page.act == nil
  local x, y = funcLuaMenuCommand(C.POINTER)
  local moved = false
  if type(x) == "number" and type(y) == "number" then
    moved = funcLuaMenuCommand(C.MOVED) == true
    if not moved and mouse.px ~= nil and (math.abs(x - mouse.px) > 1 or math.abs(y - mouse.py) > 1) then
      moved = true
    end
    mouse.px, mouse.py = x, y
  end
  if co ~= nil and not waiting_page then
    return
  end
  if moved then
    mouse.on, mouse.x, mouse.y = true, x, y
    if mouse.logs < 6 then
      mouse.logs = mouse.logs + 1
      Log("mouse", x, y)
    end
    Hover(HitAt(x, y))
  end
  if mouse.drag ~= nil then
    -- a scrollbar held (DrawScrollbar): it follows the pointer until the button is let go
    if click_now then
      if moved then
        CE.drag_to(y)
      end
      return
    end
    mouse.drag = nil
  end
  if decided or frame - last_act < 4 then
    return
  end
  if click_edge then
    mouse.on = true
    Click()                 -- on no zone: nothing
  elseif enter_edge then
    PadDecide("poll")       -- A / Enter when the anchor gave no callback this frame
  elseif mouse.on and (not CE.page_focused() or ui.popup.full or ui.popup.view ~= "info") then
    -- the wheel scrolls what the arrows scroll (lists, the grid, report views); the pointer keeps the lead
    local d = (Call(C.CHECK_INPUT, C.MENU_CTRL, C.W_DOWN) == true and 1) or (Call(C.CHECK_INPUT, C.MENU_CTRL, C.W_UP) == true and -1) or 0
    if d ~= 0 then
      OnFunction(0, d > 0 and FN.DOWN or FN.UP)
      mouse.on = true
    end
  end
end

function OnInit()
  local _, _, _, menu, _, _, _, _, _, _, _, _, _, ink = Call(M.STATE)
  if type(menu) == "number" and menu ~= 0 then
    MENU = menu
  end
  INK = (type(ink) == "string" and ink ~= "") and ink or "[CB]"
  CE.apply_layout()
  Call(M.RESCAN)            -- the app may have changed mods\ while the game runs
  Reset()
  changed, co, frame, last_act, lang, text_ids = false, nil, 0, -1000, nil, {}
  sent, used, was, hits = {}, {}, {}, {}
  tex_asked, tex_wait, tex_frames, thumbs, icons = {}, false, 0, {}, {}
  Refill(mouse, {on = false, x = -1, y = -1, logs = 0})
  dbg, extras, decided = 0, nil, false
  BG.on, BG.page = nil, nil  -- the background asserted again at the first drawing
  CE.reveal_reset()
  Call(Crc("CMND_VRFW_NO_PHOTO"), "mods_menu", 1)
  ReadAll()
  Log("open", "loader", tostring(have), "installed", cnt.installed, "changes", cnt.changes, "profiles", cnt.profiles, "top_dy", G.TOP_DY)
end

function OnSetupLayer(a1, a2)
  if a1 == L_HEADER then
    if SetupSoccerTopCommonHeaderLayerInfo then
      SetupSoccerTopCommonHeaderLayerInfo(a1, 4153539961, 253801632, 3969848060, 1144161661, 3293713115, 253801632, 1152304044, 305955024, 3007971317)
    end
    if SwapSoccerTopCommonHeaderMenuModeIconTexture then
      SwapSoccerTopCommonHeaderMenuModeIconTexture(758233070 --[[mode_base07]])
    end
    if UpdateHeader then
      UpdateHeader(3586861540)
    end
    DrawHeader()
  elseif a1 == L_BASE then
    -- the retail "total play time" line of the save list: not used
    funcLuaMenuCommand(C.TEXT, a1, N.BASE_TIME, "", a2)
    for _, mesh in ipairs(N.BASE_MESHES) do
      funcLuaMenuCommand(C.MESH_VISIBLE, a1, mesh, false, a2)
    end
    for _, p in ipairs(N.BASE_PRIMS) do
      funcLuaMenuCommand(C.PRIM_VISIBLE, a1, a2, p, false)
    end
  elseif a1 == BG.LAYER then
    -- the Guardar background: hidden until the first full drawing shows it with the content (CE.ready)
    if BG.on ~= true then
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
    end
  elseif a1 == L_ROW then
    -- the input anchor: nothing of it shows
    funcLuaMenuCommand(C.TEXT, a1, N.ROW_ON, "", a2)
    funcLuaMenuCommand(C.TEXT, a1, N.ROW_OFF, "", a2)
    for _, mesh in ipairs(N.ROW_MESHES) do
      funcLuaMenuCommand(C.MESH_VISIBLE, a1, mesh, false, a2)
    end
    funcLuaMenuCommand(C.ATTACH_TRACE, a1, a2, N.CURSOR, false)
  else
    for _, key in ipairs(FREE_ORDER) do
      if a1 == FREE[key][1] then
        local prefix = a1 .. ":" .. a2 .. ":"
        if CE.rv ~= nil and not CE.rv.got[prefix] then
          CE.rv.got[prefix] = true
          CE.rv.n = CE.rv.n + 1
          CE.rv.per[key] = (CE.rv.per[key] or 0) + 1
        end
        for k in pairs(sent) do
          if string.sub(k, 1, #prefix) == prefix then
            sent[k] = nil
          end
        end
        funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
        sent[prefix .. "vis"] = a1 .. "," .. a2 .. ",false"
        if key == "CARD" then
          funcLuaMenuCommand(C.ANIME, a1, a2, N.FOCUS, 2, N.BUTTON)
        end
        dirty = true
      end
    end
  end
end

function OnOpenLayer(a1, a2)
  if a1 == L_ROW and a2 == 0 then
    funcLuaMenuCommand(C.OPEN_LAYER, L_CURSOR, 0)
    funcLuaMenuCommand(C.CTRL, L_ROW, true)
    funcLuaMenuCommand(C.LIST_NUM, L_ROW, 1)
    funcLuaMenuCommand(C.FOCUS_SET, L_ROW, 0)
    funcLuaMenuCommand(C.ATTACH_TRACE, L_ROW, 0, N.CURSOR, false)
    funcLuaMenuCommand(C.POS, L_ROW, -4000, 4000, 0, 0)       -- the anchor: off screen, still holding the focus
    -- every free instance starts hidden (a layout may open with its own pose)
    for _, key in ipairs(FREE_ORDER) do
      was[key] = FREE[key][2]
    end
    if CE.rv ~= nil and CE.rv.opened == nil then
      CE.rv.opened = frame
    end
    Draw()
    if funcLuaCommand(C.FADE_DONE) then
      funcLuaCommand(C.FADE, 0, 0.3)
    end
  end
end

-- the anchor holds the focus; nothing moves with it (the mouse is read in Step)
function OnChangeFocus(a1, a2)
  Trace("focus", tostring(a1), tostring(a2))
end

function PadDecide(src)
  if frame - last_act < DEBOUNCE or decided then
    return false
  end
  local waiting_page = ui.page ~= nil and ui.page.pick == nil and not ui.page.back and ui.page.act == nil
  if co ~= nil and not waiting_page then
    return false
  end
  last_act = frame
  decided = true
  if Call(C.CHECK_INPUT, C.MENU_CTRL, C.LEFT) == true or (mouse.on and Call(C.CHECK_INPUT, C.MENU_CTRL, C.CLICK) == true) then
    mouse.on, mouse.click = true, true
    Click()
    return true
  end
  mouse.on = false            -- the keys lead again
  Trace("decide", src)
  if ui.page ~= nil then
    local p = ui.page
    funcLuaCommand(C.SE, SE_OK)
    if p.zone == "search" then
      p.act = "search"
    else
      p.pick = p.sel
    end
    return true
  end
  Decide()
  return true
end
function OnDecideFocus(a1, a2)
  Trace("decide-event", tostring(a1), tostring(a2))
  if a1 == L_ROW then
    PadDecide("decide")
  end
end

function OnFunction(a1, a2)
  Trace("function", tostring(a1), tostring(a2))
  local id = a1
  for _, v in pairs(FN) do
    if a2 == v then
      id = a2
    end
  end
  local waiting_page = ui.page ~= nil and co ~= nil and ui.page.pick == nil and not ui.page.back and ui.page.act == nil
  if co ~= nil and not waiting_page then
    return 1
  end
  mouse.on = false          -- the keys lead again
  if ui.page ~= nil then
    if not Screen.page_key(id) then
      funcLuaCommand(C.SE, SE_NG)
    end
    return 1
  end
  if CE.page_focused() then
    RV.key(id)
    return 1
  end
  if id == FN.UP or id == FN.DOWN or id == FN.LEFT or id == FN.RIGHT then
    local dx = (id == FN.LEFT and -1) or (id == FN.RIGHT and 1) or 0
    local dy = (id == FN.UP and -1) or (id == FN.DOWN and 1) or 0
    if ui.tab == 1 then
      MoveGrid(dx, dy)
    else
      CE.problem_move(dy ~= 0 and dy or dx * CE.PROBLEM_ROWS)
    end
  elseif id == FN.TAB_PREV or id == FN.TAB_NEXT then
    SwitchTab(ui.tab + (id == FN.TAB_PREV and -1 or 1))
  elseif id == FN.ORDER_UP or id == FN.ORDER_DOWN then
    if frame - last_act >= 4 then
      last_act = frame
      Order(id == FN.ORDER_UP and -1 or 1)
    end
  elseif id == FN.DETAILS then
    OpenDetails()
  elseif id == FN.SORT then
    if ui.tab == 1 then
      CycleSort(1)
    end
  elseif id == FN.FILTER then
    if ui.tab == 2 then
      CE.problem_filter(1)
    elseif ui.tab == 1 then
      CycleFilter(1)
    end
  elseif id == FN.SEARCH then
    funcLuaCommand(C.SE, SE_OK)
    StartCo(SearchFlow)
  elseif id == FN.PROFILE then
    StartCo(ProfileFlow)
  elseif ExtraFor(id) ~= nil then
    RunExtra(ExtraFor(id))
  else
    return
  end
  return 1
end

function OnEnter(a1, a2)
  if a1 == L_BTN or a1 == L_RET then
    return 1
  end
  if a1 == L_ROW then
    PadDecide("enter")
    return 1
  end
end

function OnBack(a1)
  if ui.page ~= nil and co ~= nil then
    funcLuaCommand(C.SE, SE_BACK)
    ui.page.back = true         -- the page's flow goes one step back
    return 1
  end
  if co ~= nil then
    return 1
  end
  if CE.page_focused() then
    if ui.popup.full then
      funcLuaCommand(C.SE, SE_BACK)
      ui.popup.full = nil
      Draw()
    else
      ClosePopup()
    end
    return 1
  end
  if ui.tab == 1 and (ui.query ~= "" or ui.filter ~= 1) and ui.zone == "grid" then
    -- B first clears the search and the filter
    funcLuaCommand(C.SE, SE_BACK)
    ui.query, ui.filter, ui.sel, ui.top = "", 1, 1, 0
    Draw()
    return 1
  end
  funcLuaCommand(C.SE, SE_BACK)
  StartCo(CloseFlow)
  return 1
end

function Step()
  frame = frame + 1
  CE.reveal_step()
  if co ~= nil then
    if coroutine.status(co) == "dead" then
      co = nil
    else
      local ok, err = coroutine.resume(co)
      if not ok then
        logger("error", tostring(err))
        co = nil
        ui.page = nil
        funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
        CE.bg_dirty = true       -- a window / keyboard closed: the background again
        Draw()
      elseif coroutine.status(co) == "dead" then
        co = nil
        last_act = frame
      end
    end
  end
  if dirty and (co == nil or (ui.page ~= nil and ui.page.pick == nil and not ui.page.back and ui.page.act == nil)) then
    dirty = false
    Draw()
  end
  PollMouse()
  decided = false
  if ui.toast ~= nil then
    ui.toast_t = ui.toast_t - 1
    if ui.toast_t <= 0 then
      ui.toast = nil
      Draw()
    end
  end
  -- The mods' pictures load asynchronously: draw again once they are in.
  if tex_wait then
    tex_frames = tex_frames + 1
    if tex_frames % 10 == 0 then
      local busy = false
      for path, st in pairs(tex_asked) do
        -- a picture already in is not asked again (2): after a gallery of hundreds, only the new ones are polled
        if st ~= 2 then
          local loading = funcLuaCommand(C.TEX_LOADING, Crc(path)) == true
          if loading and tex_frames < 600 then
            busy = true
          elseif not loading then
            tex_asked[path] = 2
          end
        end
      end
      if not busy then
        tex_wait = false
        for k in pairs(sent) do
          if string.sub(k, -3) == ":sp" then
            sent[k] = nil
          end
        end
        Draw()
      end
    end
  end
end

-- for the tests / other mods: the state as drawn
VRFW.mods_menu = {
  wrap = Wrap, units = Units, crc = Crc, hits = function() return hits end,
  -- the free layers this script draws on: layer crc -> instances (the plugin's setting must have as many)
  capacity = function()
    local o = {}
    for _, v in pairs(FREE) do o[#o + 1] = {v[1], v[2]} end
    return o
  end,
  -- the page on screen (tests)
  page = function()
    return ui.page
  end,
  -- the items of the list page (tests)
  page_items = function()
    return ui.page and ui.page.items or {}
  end,
  state = function()
    local shown = Shown()
    local ids = {}
    for _, m in ipairs(shown) do ids[#ids + 1] = m.id end
    return {tab = ui.tab, zone = ui.zone, bar = ui.bar, sel = ui.sel, top = ui.top, osel = ui.osel,
            query = ui.query, filter = FILTERS[ui.filter], sort = SORTS[ui.sort], shown = ids,
            selected = shown[ui.sel] and shown[ui.sel].id or "", popup = ui.popup and ui.popup.id or "",
            popup_btn = ui.popup and ui.popup.btn or 0,
            popup_view = ui.popup and RV.view_index() or 0, popup_view_key = ui.popup and ui.popup.view or "",
            popup_top = ui.popup and ui.popup.top or 0,
            page = ui.page and ui.page.kind or "", page_sel = ui.page and ui.page.sel or 0, page_zone = ui.page and ui.page.zone or "",
            page_items = ui.page and ui.page.items and #ui.page.items or 0, page_title = ui.page and ui.page.title or "",
            toast = ui.toast or "", overflow = overflow}
  end,
}

for name, value in pairs({
  ask = Ask, BASE = BASE, badge = Badge, C = C, CE = CE, call = Call, close_popup = ClosePopup, crc = Crc, cut = Cut, draw = Draw,
  draw_panel = DrawPanel, draw_scrollbar = DrawScrollbar, FN = FN, fit = Fit, G = G, hit = Hit, INFO = INFO,
  icon_of = IconOf, initials = Initials, int = Int, K = K, key_of = KeyOf, keyboard = Keyboard, log = Log, M = M,
  mod_by_id = ModById, name_of = NameOf, open_details = OpenDetails, order_rows = OrderRows, quad = Quad,
  RT_SEARCH = RT_SEARCH, RV = RV, SE_MOVE = SE_MOVE, SE_NG = SE_NG, SE_OK = SE_OK, SP = SP, select_mod = SelectMod,
  size = Size, start_co = StartCo, str = Str, T = T, text = Text, text_id_key = TextIdKey, thumb = Thumb,
  tile_of = TileOf, toggle = Toggle, txt = Txt, units = Units, warnings = Warnings, wrap = Wrap, cnt = cnt,
  mouse = mouse, ui = ui,
}) do
  Screen[name] = value
end
function Screen.mods()
  return mods
end
function Screen.base_mod()
  return base_mod
end
function Screen.lang()
  return lang
end
function Screen.set_lang(value)
  lang = value
end
function Screen.text_ids()
  return text_ids
end
VRFW.mods_screen = Screen
