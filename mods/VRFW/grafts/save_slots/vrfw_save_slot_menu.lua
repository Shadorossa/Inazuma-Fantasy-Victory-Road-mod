-- vrfw_save_slot_menu (plain Lua 5.2 source)
VRFW.save_slots = VRFW.save_slots or {}
if funcLuaCommand ~= nil then
  pcall(funcLuaCommand, @crc:CMND_VRFW_LOG@, "slot_menu chunk loaded (early)")
end
VRFW.slot_menu_build = "2026-11-10 v5.0"
INCLUDE("LUA_PROG_BASE")
INCLUDE("LUA_SAVEDATA_MANAGEMENT_MENU_INC")   -- UpdateHeader + soccer-top header helpers (+ general window inc)
INCLUDE("LUA_MENU_DEF")                       -- MENU_DEF.OpenSubWindow (options list)

local loader_commands = {
  VERSION = @crc:CMND_VRFW_LOADER_VERSION@,         -- () -> api, modules (bit1 = save_slots)
  GET_SLOT = @crc:CMND_VRFW_SLOT_ACTIVE@,              -- () -> active slot 1..3
  SLOT_INFO = 1195222835,
                                                   -- Slot info fields: hour, minute, victories, maxLevel, storyPhase, gameClear, leaderCharaId, memberCount.
  SLOT_INFO_TEXT = 4119688835,
  SLOT_INFO_EXT = 1726369109,
                                                   -- Team info fields: playerKinds, matches, chronicleRoute, clearBits, futureCleared.
  TEAM = @crc:CMND_VRFW_SLOT_TEAM@,
  FLAGS = 2050519205,               -- (n) -> locked, isActive, hasFile
  COPY = 3238931942,                 -- (src, dst) -> ok, code (dst must be empty, 2/3)
  DELETE = 2349165707,             -- (n) -> ok, code (2/3; backed up first)
  NAME_GET = 1190421685,
  NAME_SET = 1574661913,         -- (n, name) -> ok
  LOG = @crc:CMND_VRFW_LOG@,                        -- (...) -> vrfw_loader\loader.log
  LAYOUT = @crc:CMND_VRFW_SLOT_LAYOUT@,
  STORY_GET = @crc:CMND_VRFW_STORY_START_GET@,
  STORY_SET = @crc:CMND_VRFW_STORY_START_SET@,       -- CMND_VRFW_STORY_START_SET (n, 0|1) -> ok
}

local TXT = {
  HEADER = "Save Slots",
  GROUP_PLAYER = "Saves",
  GUIDE = "Choose the slot you want to play with.",
  TAB_SLOT = "Slot %d",
  TAB_LOCKED = "Slot %d · Original",
  NEW_GAME = "New game",
  EMPTY_HINT = "Empty slot",
  HINT_EMPTY = "Accept: new game · X: duplicate here",
  HINT_LOCKED = "Read only · X: duplicate to play",
  NO_TEAM = "No team",
  LEVEL_LINE = "Lv. %d",
  T_STORY = "Story",
  T_CHRON = "Chronicle",
  MATCHES = "%d matches",
  T_VIC = "Victories",
  T_TIME = "Total time",
  T_SAVED = "Saved",
  ASK_LOAD = "Load Slot %d?\nAnything not saved in the current slot will be lost.",
  ASK_NEW = "Slot %d is empty.\nStart a new game in this slot?",
  LOCKED_MSG = "Slot 1 (the original save) is locked. Duplicate it into another slot to play with mods.",
  ASK_DUP1 = "Slot 1 (the original save) is locked: it can only be duplicated.\nDuplicate it into another slot?",
  NO_EMPTY_FOR = "There is no empty slot to copy Slot %d into.",
  NO_EMPTY = "There is no empty slot.\nDelete the game of another slot first (Delete).",
  COPIED = "Game duplicated into Slot %d.\nPlay Slot %d now?",
  COPY_FAIL = "The game could not be duplicated (code %d).",
  ASK_DELETE = "Do you really want to delete this saved game? This cannot be undone.",
  DELETED = "The game of Slot %d was deleted.\n(A backup copy was kept.)",
  DELETE_FAIL = "The game could not be deleted (code %d).",
  NEED_LOADER = "This feature needs a newer VRFW.",
  KB_GUIDE = "Slot name (max. %d characters)",
  KB_FAILED = "The keyboard could not be opened.\nChoose a name from the list.",
  USE_NAME = "Use «%s» as the slot's name?",
  O_CANCEL = "Cancel",
  O_SLOT = "Slot %d%s",
  O_ASK = "%s?",                         -- fallback (chained yes/no): one question per option
  O_CLEAR_NAME = "(no name)",
  ORIGINAL = "Original save",
  PRESETS = {"Main", "Story", "Chronicle", "Tests", "Second", "New game"},   -- preset names (keyboard unavailable)
  CODE = {   -- reasons of the save engine's result codes (save_engine slots.rs)
    [2] = "the slot is locked",
    [3] = "the target slot is not empty",
    [4] = "the source slot is empty",
    [5] = "the game is saving or loading",
    [6] = "read error",
    [7] = "write error (Steam Cloud quota?)",
    [8] = "the copy does not match when read back",
    [9] = "Steam is not ready",
  },
  STORY_ASK = "Have you already finished the Victory Road story?\n・Story completed (Lv. 50).\n" ..
              "・Story achievements completed.\n・The 15 optional national team players.\nEverything else starts from zero.",
  NAME_SEP = " · ",
}
-- Row ids.
local TXT_ID = {
  HEADER = 1041698948,   -- vrfw_slot_header
  GROUP_PLAYER = 1425625918,   -- vrfw_slot_group_player
  GUIDE = 2857877061,   -- vrfw_slot_guide
  TAB_SLOT = 1493071877,   -- vrfw_slot_tab
  TAB_LOCKED = 1595229800,   -- vrfw_slot_tab_locked
  NEW_GAME = 2675070410,   -- vrfw_slot_new_game
  EMPTY_HINT = 135152820,   -- vrfw_slot_empty
  HINT_EMPTY = 1265100022,   -- vrfw_slot_hint_empty
  HINT_LOCKED = 572930504,   -- vrfw_slot_hint_locked
  NO_TEAM = 3863389431,   -- vrfw_slot_no_team
  LEVEL_LINE = 2891417174,   -- vrfw_slot_level_line
  T_STORY = 2342485320,   -- vrfw_slot_story
  T_CHRON = 3137611248,   -- vrfw_slot_chronicle
  MATCHES = 12633373,   -- vrfw_slot_matches
  T_VIC = 2880976274,   -- vrfw_slot_victories
  T_TIME = 50632840,   -- vrfw_slot_play_time
  T_SAVED = 2569710165,   -- vrfw_slot_saved
  ASK_LOAD = 811989475,   -- vrfw_slot_ask_load
  ASK_NEW = 3537105688,   -- vrfw_slot_ask_new
  LOCKED_MSG = 1477861926,   -- vrfw_slot_locked_msg
  ASK_DUP1 = 670644534,   -- vrfw_slot_ask_dup_locked
  NO_EMPTY_FOR = 2025493524,   -- `vrfw_slot_no_empty_for`
  NO_EMPTY = 3325358476,   -- vrfw_slot_no_empty
  COPIED = 181005854,   -- vrfw_slot_copied
  COPY_FAIL = 819774889,   -- vrfw_slot_copy_fail
  ASK_DELETE = 3542862094,   -- vrfw_slot_ask_delete
  DELETED = 3990724244,   -- vrfw_slot_deleted
  DELETE_FAIL = 2136237120,   -- vrfw_slot_delete_fail
  NEED_LOADER = 1555448090,   -- vrfw_slot_need_update
  KB_GUIDE = 1297769689,   -- vrfw_slot_kb_guide
  KB_FAILED = 934332807,   -- vrfw_slot_kb_failed
  USE_NAME = 2310749529,   -- vrfw_slot_use_name
  O_CANCEL = 108231991,   -- vrfw_slot_cancel
  O_SLOT = 182696181,   -- vrfw_slot_option
  O_ASK = 3393123094,   -- vrfw_slot_option_ask
  O_CLEAR_NAME = 1097846848,   -- vrfw_slot_clear_name
  ORIGINAL = 1741070366,   -- vrfw_slot_original
  PRESETS = {797433226, 3062795312, 3247029414, 1609378053, 686430611, 2984462377},   -- vrfw_slot_preset_1..6
  CODE = {[2] = 2064252170, [3] = 202296732, [4] = 2456442943, [5] = 3849152681, [6] = 2086942995, [7] = 191039877, [8] = 2614891540, [9] = 3973784706},   -- vrfw_slot_code_<n>
  STORY_ASK = 2876748982,   -- vrfw_slot_story_ask
}
local LOCKED_SLOT = 1
local PLAYER = {1, 2, 3}
local SLOT_RESERVED = @crc:CMND_VRFW_SLOT_RESERVED@              -- (n) -> reserved, owner, enterable, rootMenu, groupTitle
local SLOT_RESERVED_LIST = @crc:CMND_VRFW_SLOT_RESERVED_LIST@    -- () -> count, slot1, slot2, ...
local MAX_SLOT = 99       -- save engine MAX_SLOT
-- The carousel (VRFW.layer_carousel): the place of a card by its distance from the centre (px; x mirrored on the left),
-- each part's origin measured from the centre of the 424 x 700 card (y up; the band is its top 76 px) and the slide.
local CAROUSEL = {
  places = {[0] = {x = 0, scale = 1, alpha = 1}, {x = 430, scale = 0.86, alpha = 0.92}, {x = 790, scale = 0.72, alpha = 0.6},
    {x = 1150, scale = 0.6, alpha = 0}},
  band_pivot = {x = 0, y = 312}, window_pivot = {x = 0, y = -38},
  frames = 8,
}
local RING = 6            -- card instances of each part (two neighbours per side and one parked)
-- Group chips and position marks are further instances of the band layer, placed from the cards' attach point.
local CHIPS = {first = RING, limit = 6, scale = 0.7, x = -748, y = 112, pitch = 309}
local MARKS = {first = RING + 6, limit = 24, x = 0, y = -682, pitch = 26, group_gap = 26, scale = {x = 0.05, y = 0.16}}
local ITEMS = {}          -- the carousel's cards in order: { slot, group, reserved = { owner, p, locked } }
local GROUPS = {}         -- { title, first, size, at }: `first` and `at` are 0-based items
local carousel = nil
local opened = false
VRFW.save_slots_reserved = {}
-- Path of the 1.x art.
local ART_PATH = "#/menu/220_img/vrfw_slot/vrfw_slot_base.g4tx"
-- Art of v4.1.
local ART = {
  tex = 2144005326,
  card_on = 4205118495, card_off = 871893273,                          -- slot with data
  locked_on = 556058627, locked_off = 656594074,        -- slot 1 (+ padlock)
  empty_on = 3938736171, empty_off = 308059376,            -- empty slot (plus)
  emblem_generic = 28802727,                                               -- 128x128 fallback
  ri_vic = 2432256778, ri_time = 991268618, ri_saved = 533990963,
}
-- retail row icons of the "Guardar" list (save01_02.g4tx), used unchanged on the title bands
local RETAIL_ICONS = {
  row_tex = 1253411383, row_on = 3989988929, row_off = 3208381064,   -- save_icon_list_s01_on / _off
}
local ROW_OK = 3292070381
local MENU = 2103230976
local KEY_RESULT = 2449975398

-- layers
local L_ROW = 3455690937        -- save01_02_list_item (4 instances: the title bands)
local L_ROWBASE = 2782306059    -- save01_01_list_attach_base (cloned layout: 4 row locators)
local L_WINBASE = 3903826878
local L_WIN = 536044352
local L_HEADER = 575058101      -- mainmenu90_01_header
local L_GUIDE_LINE = 3078308064 -- mainmenu90_05_content_guide_line01
local L_CURSOR = 2296367164     -- cmn05_01_cursor
local L_BTN_GUIDE = 1138543975  -- mainmenu01_06_base_button_guide
local WIN_LABELS = {1743182552, 482811290, 1807756556, 4121213103, 1619730113, 4186066811}   -- the windows' attach labels (objbin); the last two: vrfw_slot_win05 / 06

local C = {
  TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,          -- CMND_SET_MENU_TEXT_STRING (layer, node, string, idx)
  TEXT_GET = @crc:CMND_TEXT_GET@,      -- CMND_TEXT_GET (text id) -> string
  TEXT_NUM = 1583337767,      -- (string, "NUM", n) -> string (retail "Chapter <NUM>")
  MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@,  -- (layer, mesh, bool, idx)
  LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@,  -- (layer, idx, bool)
  SPRITE = 558735651,         -- (layer, textureCrc, spriteCrc, nodeCrc, 0, idx)
  LOAD_TEX = @crc:CMND_LOAD_MENU_RES_TEXTURE@,       -- CMND_LOAD_MENU_RES_TEXTURE (path)
  TEX_LOADING = 1506186496,   -- (textureCrc) -> true while still loading (kizuna_town_menu_inc)
  PRIM_INDEX = @crc:CMND_SEARCH_PRIM_INDEX@,    -- CMND_SEARCH_PRIM_INDEX (layer, idx, primName) -> prim
  PRIM_VALUE = 3609943765,    -- (layer, idx, prim, value)
  PRIM_VISIBLE = 1233047821,  -- (layer, idx, primName, bool)
  ATTACH_TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@,  -- CMND_SET_LAYER_ATTACH_LOCATOR_TRACE (layer, idx, label, bool)
  OPEN_LAYER = @crc:CMND_OPEN_LAYER@,
  ANIME = @crc:CMND_PLAY_ANIME_TYPE@,         -- CMND_PLAY_ANIME_TYPE (layer, idx, type, event 0 in / 2 out, set)
  FOCUS_ENABLE = @crc:CMND_SET_ENABLE_CTRL_FOCUS@,  -- CMND_SET_ENABLE_CTRL_FOCUS (layer, bool)
  FOCUS_ACTIVE = @crc:CMND_IS_CTRL_FOCUS_ACTIVE@,   -- CMND_IS_CTRL_FOCUS_ACTIVE (layer)
  FOCUS_IDX = 2603265800,     -- (layer) -> focused instance
  FOCUS_SET = 3466097042,     -- (layer, idx) set the focused instance (retail OnChangeLayerGroup)
  FOCUS_MARK = 1778826357,    -- (layer, idx, bool) (retail OnChangeFocus)
  LIST_NUM = 3252599449,      -- (layer, count) (retail OnOpenLayer of the list)
  CURSOR_LOC = @crc:CMND_SET_CURSOR_LOCATOR@,
  GUIDE_SET = 2209673388,     -- button guide (menu, layer, texts, icons, a, b, c)
  GUIDE_CMD = 452337289,      -- button guide commands (menu, layer, cmds)
  SE = @crc:CMND_SND_PLAY_SE@,
  MENU_ACTIVE = 1558704558,   -- (menu, bool)
  CLOSE_MENU = @crc:CMND_CLOSE_MENU_OBJECT@,     -- CMND_CLOSE_MENU_OBJECT
  FADE = 609722083,           -- (1 out / 0 in, seconds)
  FADE_DONE = 2259183189,
  MSG_OPEN = 2289627655, MSG_KIND = 2351835063, MSG_RESULT = 1523741473, MSG_DONE = 682363669,
  MSG_BUSY = 898725220,
  MSG_DEFAULT_NO = 3125954271,
  -- game keyboard (GENERAL_WINDOW.WaitAndSwkbWindowCoroutine, general_window_inc_6.00.11.00:36)
  KB_OPEN = 962493425, KB_ACTIVE = 422535539, KB_TEXT = 1487869455, KB_CANCELLED = 1447363287, KB_FORCE_END = 3351189333,
  STR_LEN = 1407583914, STR_SPACES = 2431241294,
  -- generic sub_window list (research/test-mods/skill_slots/vrfw_skill_slots.lua pick, worked in game)
  SUBWIN_TEXT = 2315959435,      -- 0x8A0ABC8B (row 0.., string)
  SUBWIN_POS = 63483614,         -- 0x03C8AEDE (x, y)
  IS_OPEN_MENU = @crc:CMND_IS_OPEN_MENU_OBJECT@,     -- CMND_IS_OPEN_MENU_OBJECT (menu, layer)
  EXIST_MENU = @crc:CMND_IS_EXIST_MENU_OBJECT@,       -- CMND_IS_EXIST_MENU_OBJECT (menu)
}
local function LoadTexts()
  local function Get(id, fallback)
    local ok, s = pcall(funcLuaCommand, C.TEXT_GET, id)
    if ok and type(s) == "string" and s ~= "" then
      return s
    end
    return fallback
  end
  for k, id in pairs(TXT_ID) do
    if type(id) == "table" then
      for i, sub in pairs(id) do
        TXT[k][i] = Get(sub, TXT[k][i])
      end
    else
      TXT[k] = Get(id, TXT[k])
    end
  end
end

local SUB_WINDOW = 968210065      -- sub_window
local KB_MENU = 1671247147        -- keyboard_input_menu
local PLACEHOLDER_TEXT = 968662090 -- any valid text id; every row is overwritten with SUBWIN_TEXT
-- Extra keys on the rows (MENU_CMD_INFO added by slot_build.py).
local FN_RENAME = 2314791947     -- CMD_FUNC1
local FN_DELETE = 1786234050     -- CMD_FUNC3
local FN_DUP = 3393070439           -- CMD_FUNC4 (X): duplicate
local FN_PREVIOUS, FN_NEXT = 1249594695, 2111354275   -- CMD_LEFT / CMD_UP: vrfw_slot_previous; CMD_RIGHT / CMD_DOWN: vrfw_slot_next
local KB_TITLE = 2568160623                 -- retail menu_text "Nombre" (Name)
local KB_MAX = 20
-- Button guide ids.
local G_ACCEPT, G_NAME, G_DELETE = 1847312674 --[[Accept]], 2568160623 --[[Nombre]], 3961481199 --[[Eliminar]]
local I_ENTER, I_FUNC1, I_FUNC3 = 2750714971 --[[<CMD_ENTER>]], 203473330 --[[<CMD_FUNC1>]], 3794706590 --[[<CMD_FUNC3>]]
local K_ENTER, K_FUNC1, K_FUNC3 = 1981080283 --[[CMD_ENTER]], 637335895 --[[CMD_FUNC1]], 3421673595 --[[CMD_FUNC3]]
-- Key X (CMD_FUNC4).
local K_FUNC4, I_FUNC4 = 1435897304 --[[CMD_FUNC4]], 2085238077 --[[<CMD_FUNC4>]]
-- The reserved card's provider `reset` (button text id, texts, run) uses CMD_FUNC2, which this screen does not use and polls in Step like X.
local K_FUNC2, I_FUNC2 = 3170216173 --[[CMD_FUNC2]], 2387151820 --[[<CMD_FUNC2>]]
local G_DUP = 1825141567
-- Groups (L1 / R1).
local K_GROUP_PREVIOUS, K_GROUP_NEXT = 3559725168, 2955903379
local G_GROUP, I_R1, K_R1 = 2511301214 --[[vrfw_slot_guide_group]], 1596629152 --[[<CMD_FUNCR1>]], 942075773 --[[CMD_FUNCR1]]
local MENU_CTRL, CHECK_INPUT = 1332654303, @crc:CMND_CHECK_INPUT_CMD@   -- (MENU_CTRL, cmd)
local SE_OK, SE_DECIDE, SE_BACK = 3848881948, 4235359837, 202039849

local N = {
  TITLE = 3034079643,
  CAT = {713023922, 3010899976, 3295772830, 1511331133, 756164011, 3021698065},
  SUB = {3220414085, 653971263, 1375600553, 3482937866},
  DATE = 1259583259,
  STORY_IMG = 3518571570,
  STORY_IMG_NODE = 2597729045, -- savedata_story_img01_dmy (sprite target)
  CH_IMG = 2041544085,
  CH_IMG_NODE = 799111224,     -- savedata_ch_img01_dmy (texture slot)
  STORY_STAR = 4023127831,
  CH_STARS = {2046236296, 3774760754, 2549708708, 161341959, 2124075665, 3885204267, 2425664445, 2862636, 1999412922},
  FACES = {616408107, 3182753169, 3400779015, 1423397028, 600858674, 3134796168, 3453878558, 1566645391, 711339033, 1252107772},
  PLATFORM = {4063249485, 2766120397, 1037497463, 1255261409, 3568652610},
  PLATFORM_NODES = {3110032234, 2201512143, 439433589, 1832258019, 4082277440},
  MODE_PLATES = {2824491253, 827523407},
  COLONS = {2607508411, 1633965784},
  VICTORY_MESH = {1177874785, 3542215152},
  BASE_NODE = 3786803635,      -- save_info_base01 (the body sprite target)
}
local P = {
  H = 973998683, M = 1292450509, S = 3556797303,              -- retail total play time (off screen, hidden)
  H2 = 683386293, M2 = 1606194467, S2 = 3333801113,           -- compare copy (hidden)
  MAX = 4178101926, MAX2 = 1610716956,                        -- MAX: row 3 count (victories / fragments); MAX2 hidden
  AVG = 2856230673, AVG2 = 859295403,                         -- retail players (off screen, hidden)
  VIC = 3602710871, VIC_BIG = 1337217261,                     -- retail victories (off screen, hidden)
}
local HIDDEN_PRIMS = {P.H, P.M, P.S, P.H2, P.M2, P.S2, P.MAX2, P.AVG, P.AVG2, P.VIC, P.VIC_BIG}

local info = {}
local names = {unnamed = {}}
local active = 1
local focus = 0           -- the band instance of the centre card
local start_item = 0
local vrfw_co = nil
local has_ext = false

--@lib vrfw_menu_kit.lua#Call

--@lib vrfw_menu_kit.lua#Int

-- The provider of mod `owner` (its Lua patch of this screen); an empty table when it registered none.
local function Provider(owner)
  local p = VRFW.save_slots_reserved[owner]
  return type(p) == "table" and p or {}
end

-- The chip text of the group of mod `owner`: its declared text key ([[VRFW.SaveSlot]] group_title), else the mod id.
local function GroupTitle(owner, text_key)
  if type(text_key) == "string" and text_key ~= "" then
    local ok, s = pcall(funcLuaCommand, C.TEXT_GET, CRC32(text_key))
    if ok and type(s) == "string" and s ~= "" then
      return s
    end
  end
  return owner
end

-- Builds the cards and their groups: the player slots first, then one group per mod that owns slots.
-- A mod's slot has a card while its mode can be entered, or while its provider shows it locked.
local function BuildItems()
  ITEMS, GROUPS = {}, {}
  for _, n in ipairs(PLAYER) do
    ITEMS[#ITEMS + 1] = {slot = n, group = 1}
  end
  GROUPS[1] = {title = TXT.GROUP_PLAYER, first = 0, size = #ITEMS}
  local list = {Call(SLOT_RESERVED_LIST)}
  local owners, slots_of = {}, {}
  for k = 2, 1 + Int(list[1]) do
    local n = Int(list[k])
    local reserved, owner, enterable, _, text_key = Call(SLOT_RESERVED, n)
    if reserved == true and type(owner) == "string" and owner ~= "" then
      local p = Provider(owner)
      if enterable == true or p.locked == true then
        if slots_of[owner] == nil then
          slots_of[owner] = {title = GroupTitle(owner, text_key)}
          owners[#owners + 1] = owner
        end
        table.insert(slots_of[owner], {slot = n, reserved = {owner = owner, p = p, locked = enterable ~= true}})
      end
    end
  end
  for _, owner in ipairs(owners) do
    local g = #GROUPS + 1
    GROUPS[g] = {title = slots_of[owner].title, first = #ITEMS, size = #slots_of[owner]}
    for _, it in ipairs(slots_of[owner]) do
      it.group = g
      ITEMS[#ITEMS + 1] = it
    end
  end
end

-- A provider text: a string, or a function of (api, slot).
local function ResText(v, it)
  if type(v) == "function" then
    local ok, s = pcall(v, VRFW.save_slots.API, it.slot)
    v = ok and s or nil
  end
  if v == nil then
    return nil
  end
  return tostring(v)
end

-- texture and sprite crc of the provider's art `key` (nil = the provider names none)
local function ResArt(it, key)
  local a = it.reserved ~= nil and it.reserved.p.art or nil
  if type(a) ~= "table" or type(a.tex) ~= "string" or type(a[key]) ~= "string" then
    return nil, nil
  end
  return CRC32(a.tex), CRC32(a[key])
end

local function Chapter(s)
  local c = Int(s.chapter)
  if c < 1 and Int(s.storyPhase) > 0 then
    c = math.floor(Int(s.storyPhase) / 10000)
  end
  if c < 1 then
    c = 1
  elseif c > 9 then
    c = 9            -- savedata_story_img01..09 are shipped
  end
  return c
end

local function StoryTex(c)
  local path = string.format("#/menu/220_img/savedata_img/savedata_story_img%02d.g4tx", c)
  local name = string.format("savedata_story_img%02d", c)
  return path, name
end

-- Returns the team emblem texture.
local function EmblemTex(em)
  return "#/menu/200_icon/01_icon_emblem/" .. em .. ".g4tx", em
end

-- The card instance i shows; nil when it shows none.
local function ItemAt(i)
  if not opened or type(i) ~= "number" then
    return nil
  end
  local k = carousel:item_of(i)
  return k ~= nil and ITEMS[k + 1] or nil
end

local function SlotAt(i)
  local it = ItemAt(i)
  return it ~= nil and it.slot or nil
end

-- one string per line (the loader prints at most 8 arguments)
local function Log(...)
  local t = table.pack(...)
  local parts = {}
  for k = 1, t.n do
    parts[k] = tostring(t[k])
  end
  Call(loader_commands.LOG, "slot_menu " .. table.concat(parts, " "))
end

local function NameSuffix(n, short)
  local nm = names[n]
  if type(nm) ~= "string" or nm == "" then
    return ""
  end
  if short then
    -- The band is 424 px wide.
    local out, k = "", 0
    for ch in string.gmatch(nm, "[^\128-\191][\128-\191]*") do
      k = k + 1
      if k > 14 then
        out = out .. "…"
        break
      end
      out = out .. ch
    end
    nm = out
  end
  return TXT.NAME_SEP .. nm
end

local function TabLabel(n)
  local suffix = NameSuffix(n, true)
  if n == LOCKED_SLOT and (suffix == "" or names.unnamed[n]) then
    return string.format(TXT.TAB_LOCKED, n)
  end
  return string.format(TXT.TAB_SLOT, n) .. suffix
end

local function ReadName(n)
  local nm, default = Call(loader_commands.NAME_GET, n)
  -- The default name is a flag of the loader, never compared as text.
  names.unnamed[n] = default == true or (n == LOCKED_SLOT and (type(nm) ~= "string" or nm == ""))
  if names.unnamed[n] and n == LOCKED_SLOT then
    names[n] = TXT.ORIGINAL
  elseif type(nm) == "string" then
    names[n] = nm
  else
    names[n] = ""
  end
end

local function ShortDate(dt)
  local d, m, yy, rest = string.match(dt, "^(%d+)/(%d+)/%d%d(%d%d)%s+(.-)%s*$")
  if d ~= nil then
    return d .. "/" .. m .. "/" .. yy .. " " .. rest
  end
  return dt
end

local function ReadInfo(n)
  local t = {Call(loader_commands.SLOT_INFO, n)}
  local s = {
    exists = t[1] == true, chapter = t[2], avgLevel = t[3], playSeconds = t[4], year = t[5], month = t[6], day = t[7],
    hour = t[8], minute = t[9], victories = t[10], maxLevel = t[11], storyPhase = t[12], gameClear = t[13],
    leader = t[14], members = t[15], playTime = "", date = "", teamName = "", emblem = "",
  }
  if s.exists then
    local e = {Call(loader_commands.SLOT_INFO_EXT, n)}
    s.storyMembers, s.chBattles, s.chHistory, s.playerKinds = Int(e[2]), Int(e[3]), Int(e[4]), Int(e[5])
    s.matches, s.chRoute, s.clearBits = Int(e[6]), Int(e[7]), Int(e[8])
    local pt, dt = Call(loader_commands.SLOT_INFO_TEXT, n)
    if type(pt) == "string" then
      s.playTime = pt
    end
    if type(dt) == "string" and dt ~= "" then
      s.date = ShortDate(dt)
    else
      s.date = string.format("%02d/%02d/%02d %02d:%02d", Int(s.day), Int(s.month), Int(s.year) % 100, Int(s.hour), Int(s.minute))
    end
    local ok, tn, em = Call(loader_commands.TEAM, n)
    if ok == true then
      if type(tn) == "string" then
        s.teamName = tn
      end
      if type(em) == "string" and em:match("^em%d+%a?$") then
        s.emblem = em
      end
    end
    Log("card", n, "team", tostring(tn), "emblem", tostring(em), "time", s.playTime, "date", s.date)
  end
  return s
end

local function SetPrim(idx, name, value, visible)
  local prim = funcLuaMenuCommand(C.PRIM_INDEX, L_WIN, idx, name)
  if prim ~= nil then
    funcLuaMenuCommand(C.PRIM_VALUE, L_WIN, idx, prim, value)
  end
  funcLuaMenuCommand(C.PRIM_VISIBLE, L_WIN, idx, name, visible)
end

local function Mesh(idx, mesh, visible)
  funcLuaMenuCommand(C.MESH_VISIBLE, L_WIN, mesh, visible, idx)
end

local function Text(idx, node, s)
  funcLuaMenuCommand(C.TEXT, L_WIN, node, s, idx)
end

local function Sprite(idx, tex, sprite, node)
  funcLuaMenuCommand(C.SPRITE, L_WIN, tex, sprite, node, 0, idx)
end

local wait_tex = {}
local windows_ready = false
local wait_frames = 0
local function TexReady(crc)
  if funcLuaCommand(C.TEX_LOADING, crc) == true then
    if wait_frames < 900 then
      wait_tex[crc] = true
    end
    return false
  end
  return true
end

-- Draws the row 4 value.
local function TimeText(idx, s, visible)
  local t = ""
  if visible then
    t = s.playTime
    if type(t) ~= "string" or t == "" then
      local secs = Int(s.playSeconds)
      t = string.format("%d:%02d:%02d", math.floor(secs / 3600), math.floor(secs / 60) % 60, secs % 60)
    end
  end
  Text(idx, N.TITLE, t)
end

-- Draws the row 3 value.
local function CountPrim(idx, v, visible)
  SetPrim(idx, P.MAX, v, visible)
end

-- Row icons.
local ROW_ICONS = {
  slot = {false, false, ART.ri_vic, ART.ri_time, ART.ri_saved},
}
local ROW_PLATFORM = {4, 5, 1, 2, 3}
local function RowIcons(idx, kind, it)
  local set, tex = ROW_ICONS[kind], ART.tex
  if kind == "reserved" then
    set, tex = nil, nil
    local a = it.reserved.p.art
    if type(a) == "table" and type(a.tex) == "string" and type(a.rows) == "table" then
      tex, set = CRC32(a.tex), {}
      for r = 1, 5 do
        set[r] = type(a.rows[r]) == "string" and CRC32(a.rows[r]) or false
      end
    end
  end
  for _, m in ipairs(N.MODE_PLATES) do
    Mesh(idx, m, kind == "slot")
  end
  for r = 1, 5 do
    local p = ROW_PLATFORM[r]
    local sp = set ~= nil and set[r] or false
    if sp then
      Sprite(idx, tex, sp, N.PLATFORM_NODES[p])
    end
    Mesh(idx, N.PLATFORM[p], sp ~= false)
  end
end

-- everything a card can show, off (the fill functions turn on what they use)
local function ClearCard(idx)
  Text(idx, N.TITLE, "")
  for _, node in ipairs(N.CAT) do
    Text(idx, node, "")
  end
  for _, node in ipairs(N.SUB) do
    Text(idx, node, "")
  end
  Text(idx, N.DATE, "")
  for _, m in ipairs(N.CH_STARS) do
    Mesh(idx, m, false)
  end
  for k = 1, #N.FACES do
    Mesh(idx, N.FACES[k], false)
  end
  for _, m in ipairs(N.VICTORY_MESH) do
    Mesh(idx, m, false)
  end
  Mesh(idx, N.STORY_IMG, false)
  Mesh(idx, N.CH_IMG, false)
  Mesh(idx, N.STORY_STAR, false)
  for _, name in ipairs(HIDDEN_PRIMS) do
    SetPrim(idx, name, 0, false)
  end
  CountPrim(idx, 0, false)
  TimeText(idx, nil, false)
  for _, m in ipairs(N.COLONS) do
    Mesh(idx, m, false)
  end
  RowIcons(idx, "none")
end

local function FillReservedWindow(idx, it)
  local s = info[it.slot] or {exists = false}
  local p = it.reserved.p
  local d = {}
  if type(p.fill) == "function" then
    local ok, v = pcall(p.fill, VRFW.save_slots.API, it.slot)
    if ok and type(v) == "table" then
      d = v
    else
      Log("reserved card", it.reserved.owner, "fill error", tostring(v))
    end
  end
  local stex, strip = ResArt(it, "strip")
  if stex ~= nil and TexReady(stex) then
    Sprite(idx, stex, strip, N.STORY_IMG_NODE)
    Mesh(idx, N.STORY_IMG, true)
  end
  Text(idx, N.CAT[6], ResText(p.title, it) or it.reserved.owner)
  Text(idx, N.SUB[1], tostring(d.line or ""))
  local rows = type(d.rows) == "table" and d.rows or {}
  for r = 1, 3 do
    local row = rows[r]
    if type(row) == "table" then
      Text(idx, N.CAT[r], tostring(row[1] or ""))
      if r < 3 then
        Text(idx, N.SUB[r + 1], tostring(row[2] or ""))
      end
    end
  end
  if type(d.count) == "number" then
    CountPrim(idx, d.count, true)
  end
  Text(idx, N.CAT[4], TXT.T_TIME)
  TimeText(idx, s, s.exists)
  Text(idx, N.CAT[5], TXT.T_SAVED)
  Text(idx, N.DATE, s.exists and s.date or tostring(d.empty or TXT.EMPTY_HINT))
  if d.footer ~= nil then
    Text(idx, N.SUB[4], tostring(d.footer))
  end
  RowIcons(idx, "reserved", it)
end

local function FillWindow(idx)
  local it = ItemAt(idx)
  ClearCard(idx)
  if it == nil then
    return
  end
  if it.reserved ~= nil then
    FillReservedWindow(idx, it)
    return
  end
  local n = it.slot
  local s = info[n] or {exists = false}
  if not s.exists then
    -- the dashed circle + plus is in the body (vrfw_slot_card_empty_*, SetBase)
    Text(idx, N.CAT[6], TXT.NEW_GAME)
    Text(idx, N.SUB[1], TXT.EMPTY_HINT)
    Text(idx, N.SUB[4], has_ext and TXT.HINT_EMPTY or "")
    return
  end
  local ch = Chapter(s)
  local path, name = StoryTex(ch)
  local pc = CRC32(path)
  if TexReady(pc) then
    Sprite(idx, pc, CRC32(name), N.STORY_IMG_NODE)
  end
  Mesh(idx, N.STORY_IMG, TexReady(pc))
  local etex, esprite = ART.tex, ART.emblem_generic
  if s.emblem ~= "" then
    local epath, ename = EmblemTex(s.emblem)
    if TexReady(CRC32(epath)) then
      etex, esprite = CRC32(epath), CRC32(ename)
    end
  end
  TexReady(ART.tex)
  Sprite(idx, etex, esprite, N.CH_IMG_NODE)
  Mesh(idx, N.CH_IMG, true)
  local team = s.teamName ~= "" and s.teamName or TXT.NO_TEAM
  Text(idx, N.CAT[6], team)
  Text(idx, N.SUB[1], string.format(TXT.LEVEL_LINE, Int(s.avgLevel)))
  local function Num(textId, v)
    return funcLuaCommand(C.TEXT_NUM, funcLuaCommand(C.TEXT_GET, textId), "NUM", v)
  end
  Text(idx, N.CAT[1], TXT.T_STORY)
  Text(idx, N.SUB[2], Num(2849482415, ch))                 -- Chapter <NUM>
  Mesh(idx, N.STORY_STAR, s.clearBits % 2 == 1)
  Text(idx, N.CAT[2], TXT.T_CHRON)
  Text(idx, N.SUB[3], string.format(TXT.MATCHES, s.chBattles))
  Text(idx, N.CAT[3], TXT.T_VIC)
  CountPrim(idx, Int(s.victories), true)
  Text(idx, N.CAT[4], TXT.T_TIME)
  TimeText(idx, s, true)
  Text(idx, N.CAT[5], TXT.T_SAVED)
  Text(idx, N.DATE, s.date)
  if n == LOCKED_SLOT then
    Text(idx, N.SUB[4], TXT.HINT_LOCKED)
  end
  RowIcons(idx, "slot")
end

-- Draws the body of the card in instance i (the carousel owns its alpha).
local function SetBase(i)
  local it = ItemAt(i)
  if it == nil then
    return
  end
  local on = i == focus
  local s = info[it.slot] or {exists = false}
  local sp
  if it.reserved ~= nil and it.reserved.locked then
    sp = on and ART.locked_on or ART.locked_off
  elseif it.reserved ~= nil then
    local t, b = ResArt(it, on and "body_on" or "body_off")
    if t ~= nil then
      TexReady(t)
      Sprite(i, t, b, N.BASE_NODE)
      return
    end
    sp = on and ART.card_on or ART.card_off
  elseif not s.exists then
    sp = on and ART.empty_on or ART.empty_off
  elseif it.slot == LOCKED_SLOT then
    sp = on and ART.locked_on or ART.locked_off
  else
    sp = on and ART.card_on or ART.card_off
  end
  TexReady(ART.tex)
  Sprite(i, ART.tex, sp, N.BASE_NODE)
end

local function RowText(it)
  if it.reserved ~= nil then
    return ResText(it.reserved.p.row, it) or it.reserved.owner
  end
  return TabLabel(it.slot)
end

-- band nodes and meshes (save01_02): the two texts, the plate of the unfocused state, the icon dummies, the "current" mark
local BAND = {
  text_on = 931545948, text_off = 3705682548,               -- _text_list01_on / _text_list01_off
  plate_on = 496140502, plate_off = 3517400201,             -- list_base_s01_on / list_base_s01_off (node and sprite names)
  icon_on = 2880627768, icon_ok = 3688370359, icon_off = 2527308690,   -- list_icon_dmy_s01_on / _ok / _off (nodes)
  icon_meshes = {376662541, 1712955010, 3232607807},        -- _list_icon_dmy_s01_on / _ok / _off (meshes)
}

-- retail "Guardar" row icon (save_icon_list_s01) on the icon dummies of band instance i
local function RetailBandIcons(i)
  funcLuaMenuCommand(C.SPRITE, L_ROW, RETAIL_ICONS.row_tex, RETAIL_ICONS.row_on, BAND.icon_on, 0, i)
  funcLuaMenuCommand(C.SPRITE, L_ROW, RETAIL_ICONS.row_tex, RETAIL_ICONS.row_on, BAND.icon_ok, 0, i)
  funcLuaMenuCommand(C.SPRITE, L_ROW, RETAIL_ICONS.row_tex, RETAIL_ICONS.row_off, BAND.icon_off, 0, i)
end

-- Draws the band of the card in instance i.
local function SetupRow(i)
  local it = ItemAt(i)
  if it == nil then
    return
  end
  local t = RowText(it)
  -- Marks the current slot.
  funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, ROW_OK, it.reserved == nil and it.slot == active and it.slot ~= LOCKED_SLOT, i)
  funcLuaMenuCommand(C.TEXT, L_ROW, BAND.text_on, t, i)
  funcLuaMenuCommand(C.TEXT, L_ROW, BAND.text_off, t, i)
  local bt, bon = ResArt(it, "band_on")
  local _, boff = ResArt(it, "band_off")
  if bt ~= nil and boff ~= nil then
    TexReady(bt)
    funcLuaMenuCommand(C.SPRITE, L_ROW, bt, bon, BAND.plate_on, 0, i)
    funcLuaMenuCommand(C.SPRITE, L_ROW, bt, boff, BAND.plate_off, 0, i)
  else
    -- an instance shows another card after each move: the retail plates come back
    funcLuaMenuCommand(C.SPRITE, L_ROW, RETAIL_ICONS.row_tex, BAND.plate_on, BAND.plate_on, 0, i)
    funcLuaMenuCommand(C.SPRITE, L_ROW, RETAIL_ICONS.row_tex, BAND.plate_off, BAND.plate_off, 0, i)
  end
  local itex, ion = ResArt(it, "icon")
  local _, ioff = ResArt(it, "icon_off")
  if itex ~= nil then
    TexReady(itex)
    funcLuaMenuCommand(C.SPRITE, L_ROW, itex, ion, BAND.icon_on, 0, i)
    funcLuaMenuCommand(C.SPRITE, L_ROW, itex, ion, BAND.icon_ok, 0, i)
    funcLuaMenuCommand(C.SPRITE, L_ROW, itex, ioff or ion, BAND.icon_off, 0, i)
    return
  end
  RetailBandIcons(i)
end

-- Returns whether slot n can be renamed (Accept always).
local function CanRename(n)
  return has_ext and n ~= nil and info[n] ~= nil and info[n].exists
end

local function CanDelete(n)
  return has_ext and n ~= nil and n ~= LOCKED_SLOT and info[n] ~= nil and (info[n].exists or info[n].hasFile)
end

local function UpdateButtonGuide()
  local it = ItemAt(focus)
  local texts, icons, cmds, z = {G_ACCEPT}, {I_ENTER}, {K_ENTER}, {0}
  local function Add(text, icon, cmd)
    table.insert(texts, text)
    table.insert(icons, icon)
    table.insert(cmds, cmd)
    table.insert(z, 0)
  end
  if #GROUPS > 1 then
    Add(G_GROUP, I_R1, K_R1)
  end
  if it ~= nil and it.reserved ~= nil then
    local rs = not it.reserved.locked and it.reserved.p.reset or nil
    if type(rs) == "table" and type(rs.run) == "function" and type(rs.button) == "number" then
      -- the provider's reset key, next to Accept where the other cards show Delete
      Add(rs.button, I_FUNC2, K_FUNC2)
    end
  elseif it ~= nil then
    if has_ext then
      Add(G_DUP, I_FUNC4, K_FUNC4)
    end
    if CanRename(it.slot) then
      Add(G_NAME, I_FUNC1, K_FUNC1)
    end
    if CanDelete(it.slot) then
      Add(G_DELETE, I_FUNC3, K_FUNC3)
    end
  end
  funcLuaMenuCommand(C.GUIDE_SET, MENU, L_BTN_GUIDE, texts, icons, z, z, z)
  funcLuaMenuCommand(C.GUIDE_CMD, MENU, L_BTN_GUIDE, cmds)
end

--@lib vrfw_menu_kit.lua#Close

-- Asks a yes/no question in a general window (retail pattern of title_menu_inc "gameend").
local function Ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  local yes = VRFW.question.ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  return yes
end

-- Yes/no with the cursor on "No" (retail savedata_management_menu_reset CheckWindowCoroutine).
local P_YES = 1449645767
local function AskDanger(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  VRFW.param.clear(P_YES)
  funcLuaCommand(C.MSG_OPEN, text, 0, 0, 0, 0, 0, false)
  funcLuaCommand(C.MSG_KIND, 2, 15)
  funcLuaCommand(C.MSG_DEFAULT_NO, true, false)
  while funcLuaCommand(C.MSG_BUSY) do
    coroutine.yield()
  end
  local yes = false
  while not funcLuaCommand(C.MSG_DONE) and not yes do
    yes = VRFW.param.has(P_YES)
    coroutine.yield()
  end
  if not yes then
    yes = VRFW.param.has(P_YES)
  end
  local r = funcLuaCommand(C.MSG_RESULT)
  VRFW.param.clear(P_YES)
  while not funcLuaCommand(C.MSG_DONE) do
    coroutine.yield()
  end
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  Log("ask(danger) raw result", tostring(r), "param yes", yes and "yes" or "no")
  return yes
end

--@lib vrfw_menu_kit.lua#Message

local function CodeText(fmt, code)
  local t = string.format(fmt, Int(code))
  if TXT.CODE[Int(code)] ~= nil then
    t = t .. "\n(" .. TXT.CODE[Int(code)] .. ")"
  end
  return t
end

VRFW.save_slots.HOOKS = {new_game = {}}
VRFW.save_slots.API = {
  version = 1,
  call = Call, log = Log, ask = Ask, ask_danger = AskDanger, message = Message,
  C = {TEXT_GET = C.TEXT_GET, TEXT_NUM = C.TEXT_NUM, SE = C.SE},
  SE = {OK = SE_OK, DECIDE = SE_DECIDE, BACK = SE_BACK},
  MENU = MENU,
}

local function RunHooks(name, n)
  local list = VRFW.save_slots.HOOKS[name]
  if type(list) ~= "table" then
    return
  end
  for k, fn in ipairs(list) do
    if type(fn) == "function" then
      local ok, err = pcall(fn, n, VRFW.save_slots.API)
      if not ok then
        Log("hook error", name, k, tostring(err))
      end
    end
  end
end

local loaded_tex = {}
local function LoadCardTextures(s)
  if not s.exists then
    return
  end
  local paths = {(StoryTex(Chapter(s)))}
  if s.emblem ~= "" then
    table.insert(paths, (EmblemTex(s.emblem)))
  end
  for _, path in ipairs(paths) do
    if not loaded_tex[path] then
      loaded_tex[path] = true
      funcLuaMenuCommand(C.LOAD_TEX, path)
    end
  end
end

-- read slot n (info, name, file flag)
local function ReadSlot(n)
  info[n] = ReadInfo(n)
  ReadName(n)
  if has_ext then
    local _, _, hasFile = Call(loader_commands.FLAGS, n)
    info[n].hasFile = hasFile == true
  end
end

-- Draws the card in instance i: its textures, band, window and body.
local function FillCard(i)
  local it = ItemAt(i)
  if it ~= nil and info[it.slot] ~= nil then
    LoadCardTextures(info[it.slot])
  end
  SetupRow(i)
  FillWindow(i)
  SetBase(i)
end

local function FillCards()
  for i = 0, RING - 1 do
    FillCard(i)
  end
end

-- re-read every slot (after duplicate / delete / rename) and redraw the cards and the guide
local function Refresh()
  local a = Call(loader_commands.GET_SLOT)
  if type(a) == "number" and a >= 1 and a <= MAX_SLOT then
    active = math.floor(a)
  end
  for _, it in ipairs(ITEMS) do
    if it.reserved == nil then
      ReadSlot(it.slot)
    else
      info[it.slot] = ReadInfo(it.slot)
    end
  end
  FillCards()
  UpdateButtonGuide()
end

local function EmptyTargets()
  local t = {}
  for _, n in ipairs(PLAYER) do
    if n ~= LOCKED_SLOT and info[n] ~= nil and not info[n].exists then
      table.insert(t, n)
    end
  end
  return t
end

local subwin_result = -1

function vrfw_save_slots_on_sub_window(a1)
  subwin_result = type(a1) == "number" and a1 or -1
  Log("subwindow callback", tostring(a1))
  funcLuaCommand(C.CLOSE_MENU, SUB_WINDOW)
end

-- Chained yes/no fallback.
local function ChooseByQuestions(options)
  for i = 1, #options - 1 do
    if Ask(string.format(TXT.O_ASK, options[i])) then
      return i
    end
  end
  return 0
end

-- Shows the options list.
local function Choose(tag, options)
  Log("choose open", tag, #options)
  subwin_result = -1
  local ids = {}
  for i = 1, #options do
    ids[i] = PLACEHOLDER_TEXT
  end
  local opened = false
  if MENU_DEF ~= nil and MENU_DEF.OpenSubWindow ~= nil then
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
    MENU_DEF.OpenSubWindow("vrfw_save_slots_on_sub_window", "", #ids, ids, 9, 0, {}, 0, false, false, 15)
    for i = 1, #options do
      funcLuaCommand(C.SUBWIN_TEXT, i - 1, options[i])
    end
    for _ = 1, 60 do          -- ~1 s: the list must appear, else fall back to yes/no windows
      if funcLuaCommand(C.IS_OPEN_MENU, SUB_WINDOW, L_CURSOR) then
        opened = true
        break
      end
      coroutine.yield()
    end
    if opened then
      funcLuaCommand(C.SUBWIN_POS, 960, -300)
      while funcLuaMenuCommand(C.EXIST_MENU, SUB_WINDOW) do
        coroutine.yield()
      end
    else
      funcLuaCommand(C.CLOSE_MENU, SUB_WINDOW)
      coroutine.yield()
    end
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  end
  local r
  if opened then
    r = subwin_result >= 0 and subwin_result + 1 or 0
  else
    Log("choose fallback yes/no", tag)
    r = ChooseByQuestions(options)
  end
  if r >= #options then
    r = 0             -- "Cancel"
  end
  Log("choose result", tag, r, r > 0 and options[r] or "cancel")
  return r
end

local function SlotLabel(m)
  return string.format(TXT.O_SLOT, m, NameSuffix(m, false))
end

local function DoCopy(src, dst)
  local ok, code = Call(loader_commands.COPY, src, dst)
  Log("copy", src, dst, ok == true, code)
  if ok ~= true then
    Message(CodeText(TXT.COPY_FAIL, code))
    Refresh()
    return false
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  Refresh()
  if Ask(string.format(TXT.COPIED, dst, dst)) then
    funcLuaCommand(C.SE, SE_DECIDE)
    Log("close after copy", dst)
    Close(dst)
    return true
  end
  return false
end

local function AskName(initial)
  if funcLuaCommand(C.KB_ACTIVE) then
    Log("keyboard was still active: force end")
    funcLuaCommand(C.KB_FORCE_END, "")
    coroutine.yield()
  end
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  local opened = false
  for attempt = 1, 2 do
    funcLuaCommand(C.KB_OPEN, 0, initial or "", KB_TITLE, 0, KB_MAX, 0, 0, 0, 0, 0, 0, true, true, 2, string.format(TXT.KB_GUIDE, KB_MAX), 0, false, false)
    local act = funcLuaCommand(C.KB_ACTIVE) == true
    local exists = funcLuaMenuCommand(C.EXIST_MENU, KB_MENU) == true
    Log("keyboard open attempt", attempt, "active", act and "yes" or "no", "menu exists", exists and "yes" or "no")
    if act then
      opened = true
      break
    end
    for _ = 1, 10 do         -- the menu may appear a few frames later
      coroutine.yield()
      if funcLuaCommand(C.KB_ACTIVE) == true then
        opened = true
        break
      end
    end
    if opened then
      break
    end
  end
  if not opened then
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
    Log("keyboard did NOT open")
    return false
  end
  local frames, live, changes = 0, "", 0
  while funcLuaCommand(C.KB_ACTIVE) do
    frames = frames + 1
    local t = funcLuaCommand(C.KB_TEXT)      -- live buffer (same getter; no side effects)
    if type(t) == "string" and t ~= live then
      if t ~= "" then
        live = t
      end
      changes = changes + 1
      if changes <= 8 then
        Log("keyboard live text", t)
      end
    end
    coroutine.yield()
  end
  local text = funcLuaCommand(C.KB_TEXT)
  local rawc = funcLuaCommand(C.KB_CANCELLED)
  local cancelled = rawc == true
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  Log("keyboard closed after frames", frames, "raw cancelled", tostring(rawc), "text [" .. tostring(text) .. "]", "live [" .. live .. "]")
  if (type(text) ~= "string" or text == "") and live ~= "" then
    if Ask(string.format(TXT.USE_NAME, live)) then
      return live
    end
    return nil
  end
  if cancelled or type(text) ~= "string" then
    return nil
  end
  local len = funcLuaCommand(C.STR_LEN, text)
  if len == 0 or funcLuaCommand(C.STR_SPACES, text) == true then
    return ""    -- empty / spaces only = back to the default name
  end
  return text
end

local function Rename(i)
  local n = SlotAt(i)
  if not CanRename(n) then
    Log("rename refused", n, "has_ext", has_ext and "yes" or "no", "exists", info[n] ~= nil and info[n].exists and "yes" or "no")
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  local cur = names[n]
  if n == LOCKED_SLOT and names.unnamed[n] then
    cur = ""
  end
  local nm = AskName(cur)
  if nm == false then
    -- The keyboard is unavailable here.
    Message(TXT.KB_FAILED)
    local opts = {}
    for _, v in ipairs(TXT.PRESETS) do
      table.insert(opts, v)
    end
    table.insert(opts, TXT.O_CLEAR_NAME)
    table.insert(opts, TXT.O_CANCEL)
    local k = Choose("preset name", opts)
    if k == 0 then
      return
    end
    nm = k == #opts - 1 and "" or opts[k]
  end
  if nm == nil then
    Log("rename cancelled", n)
    return
  end
  local ok = Call(loader_commands.NAME_SET, n, nm)
  Log("rename", n, ok == true, nm)
  funcLuaCommand(C.SE, SE_DECIDE)
  Refresh()
end

-- Resets a mod's slot: its question, its run (the owner archives its slot) and the answer texts ({1} is the code it returns).
local function ReservedReset(it)
  local rs = it.reserved.p.reset
  if type(rs) ~= "table" or type(rs.run) ~= "function" then
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  if not AskDanger(ResText(rs.ask, it) or "") then
    Log("reserved reset: answered No", it.reserved.owner)
    return
  end
  local okc, ok, code = pcall(rs.run, VRFW.save_slots.API, it.slot)
  Log("reserved reset", it.reserved.owner, okc and ok == true, tostring(okc and code or ok))
  Refresh()
  if okc and ok == true then
    funcLuaCommand(C.SE, SE_DECIDE)
    local done = ResText(rs.done, it)
    if done ~= nil then
      Message(done)
    end
  else
    local fail = ResText(rs.fail, it)
    if fail ~= nil then
      Message((fail:gsub("{1}", tostring(code))))
    end
  end
end

local function Delete(i)
  local n = SlotAt(i)
  if not CanDelete(n) then
    if n == nil then
      return
    end
    Log("delete refused", n, "has_ext", has_ext and "yes" or "no", "exists", info[n] ~= nil and info[n].exists and "yes" or "no",
        "hasFile", info[n] ~= nil and info[n].hasFile and "yes" or "no")
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  if not AskDanger(TXT.ASK_DELETE) then
    Log("delete: answered No", n)
    return
  end
  local ok, code = Call(loader_commands.DELETE, n)
  Log("delete", n, ok == true, code)
  if ok == true then
    funcLuaCommand(C.SE, SE_DECIDE)
    Refresh()
    Message(string.format(TXT.DELETED, n))
  else
    Message(CodeText(TXT.DELETE_FAIL, code))
    Refresh()
  end
end

local function Play(n)
  if n == active or Ask(string.format(TXT.ASK_LOAD, n)) then
    funcLuaCommand(C.SE, SE_DECIDE)
    Log("close: play", n, "active", active)
    Close(n)
  end
end

-- Asks the story-complete start (save part story_start).
local function StoryAsk(n)
  local st = Call(loader_commands.STORY_GET, n)
  if type(st) ~= "number" then
    Log("story question: no story-complete start in the save part: not asked")
    return
  end
  local yes = Ask(TXT.STORY_ASK)
  local ok = Call(loader_commands.STORY_SET, n, yes and 1 or 0)
  Log("story question slot", n, yes and "yes" or "no", "marker", ok == true and "written" or "refused")
end

local function NewGame(n)
  if Ask(string.format(TXT.ASK_NEW, n)) then
    funcLuaCommand(C.SE, SE_DECIDE)
    StoryAsk(n)
    RunHooks("new_game", n)
    Log("close: new game", n)
    Close(n)
  end
end

-- Duplicates into empty slot n.
local function DuplicateInto(n)
  local sources, opts = {}, {}
  for _, m in ipairs(PLAYER) do
    if m ~= n and info[m] ~= nil and info[m].exists then
      table.insert(sources, m)
      table.insert(opts, SlotLabel(m))
    end
  end
  if #sources == 0 then
    Message(string.format(TXT.ASK_NEW, n))
    return
  end
  table.insert(opts, TXT.O_CANCEL)
  local k = Choose("copy source", opts)
  if k > 0 then
    DoCopy(sources[k], n)
  end
end

-- Duplicates from slot src.
local function DuplicateFrom(src)
  local targets = EmptyTargets()
  if #targets == 0 then
    Message(TXT.NO_EMPTY)
    return
  end
  local opts = {}
  for _, t in ipairs(targets) do
    table.insert(opts, string.format(TXT.O_SLOT, t, ""))
  end
  table.insert(opts, TXT.O_CANCEL)
  local k = Choose("copy target", opts)
  if k > 0 then
    DoCopy(src, targets[k])
  end
end

local function Decide(i)
  local it = ItemAt(i)
  if it == nil then
    return
  end
  local r = it.reserved
  if r ~= nil then
    Log("decide reserved card", it.slot, r.owner, "active", active, "locked", r.locked == true)
    if r.locked then
      funcLuaCommand(C.SE, SE_BACK)
      local msg = ResText(r.p.locked_msg, it)
      if msg ~= nil and msg ~= "" then
        Message(msg)
      end
      return
    end
    funcLuaCommand(C.SE, SE_OK)
    if active == it.slot or r.p.ask == false or Ask(ResText(r.p.ask, it) or string.format(TXT.ASK_LOAD, it.slot)) then
      funcLuaCommand(C.SE, SE_DECIDE)
      Close(it.slot)
    end
    return
  end
  local n = it.slot
  local s = info[n] or {exists = false}
  Log("decide slot", n, "exists", s.exists and "yes" or "no", "active", active)
  funcLuaCommand(C.SE, SE_OK)
  if n == LOCKED_SLOT then
    if has_ext and Ask(TXT.ASK_DUP1) then
      DuplicateFrom(n)
    elseif not has_ext then
      Message(TXT.LOCKED_MSG)
    end
  elseif s.exists then
    Play(n)
  else
    NewGame(n)
  end
end

-- Handles X (duplicate).
local function Duplicate(i)
  local it = ItemAt(i)
  if it == nil or it.reserved ~= nil then
    return            -- a mod's slot is never duplicated
  end
  local n = it.slot
  local s = info[n] or {exists = false}
  Log("duplicate key slot", n, "exists", s.exists and "yes" or "no")
  if not has_ext then
    Message(TXT.NEED_LOADER)
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  if s.exists then
    if #EmptyTargets() == 0 then
      Message(string.format(TXT.NO_EMPTY_FOR, n))
      return
    end
    DuplicateFrom(n)
  else
    DuplicateInto(n)
  end
end

local LAYER_SET, LAYER_SCALE = @crc:CMND_SET_LAYER_LOCAL_POS@, @crc:CMND_SET_LAYER_LOCAL_SCALE@   -- (layer, x, y, z, instance)
local ANIME_FOCUS, ANIME_BUTTON = 2734777837, 973515837   -- Focus, button
local marked = {item = nil, group = nil, count = 0}

-- Makes instance i (the carousel's centre card) the list's focused row.
local function FocusCard(i)
  local before = focus
  if i ~= before then
    funcLuaMenuCommand(C.ANIME, L_ROW, before, ANIME_FOCUS, 2, ANIME_BUTTON)
  end
  funcLuaMenuCommand(C.FOCUS_SET, L_ROW, i)
  funcLuaMenuCommand(C.FOCUS_MARK, L_ROW, i, true)
  funcLuaMenuCommand(C.ANIME, L_ROW, i, ANIME_FOCUS, 0, ANIME_BUTTON)   -- not Active: it slides the row
  funcLuaMenuCommand(C.CURSOR_LOC, L_ROW, 3313461902 --[[cursor]], i, RING)
  focus = i
  SetBase(before)
  SetBase(i)
end

-- The group chips: one small band per group, shown while there is more than one group.
local function SetupChips()
  for k = 1, CHIPS.limit do
    local i = CHIPS.first + k - 1
    local group = #GROUPS > 1 and GROUPS[k] or nil
    funcLuaMenuCommand(C.LAYER_VISIBLE, L_ROW, i, group ~= nil)
    if group ~= nil then
      funcLuaMenuCommand(LAYER_SET, L_ROW, CHIPS.x + (k - 1) * CHIPS.pitch, CHIPS.y, 0, i)
      funcLuaMenuCommand(LAYER_SCALE, L_ROW, CHIPS.scale, CHIPS.scale, 1, i)
      funcLuaMenuCommand(C.TEXT, L_ROW, BAND.text_on, group.title, i)
      funcLuaMenuCommand(C.TEXT, L_ROW, BAND.text_off, group.title, i)
      funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, ROW_OK, false, i)
      RetailBandIcons(i)
    end
  end
  if #GROUPS > CHIPS.limit then
    Log("WARN", #GROUPS, "groups, chips for the first", CHIPS.limit)
  end
end

-- The position marks: one small plate per card, a wider gap between groups.
local function SetupMarks()
  local sizes = {}
  for g, group in ipairs(GROUPS) do
    sizes[g] = group.size
  end
  marked.count = VRFW.layer_carousel.lay_marks({layer = L_ROW, first = MARKS.first, limit = MARKS.limit, x = MARKS.x, y = MARKS.y,
    pitch = MARKS.pitch, group_gap = MARKS.group_gap, scale = MARKS.scale}, sizes)
  for k = 0, marked.count - 1 do
    local i = MARKS.first + k
    funcLuaMenuCommand(C.TEXT, L_ROW, BAND.text_on, "", i)
    funcLuaMenuCommand(C.TEXT, L_ROW, BAND.text_off, "", i)
    funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, ROW_OK, false, i)
    for _, mesh in ipairs(BAND.icon_meshes) do
      funcLuaMenuCommand(C.MESH_VISIBLE, L_ROW, mesh, false, i)
    end
  end
end

local function MarkLook(item, on)
  if item < marked.count then
    funcLuaMenuCommand(C.SPRITE, L_ROW, RETAIL_ICONS.row_tex, on and BAND.plate_on or BAND.plate_off, BAND.plate_off, 0, MARKS.first + item)
  end
end

local function ChipLook(group, on)
  if group <= CHIPS.limit then
    funcLuaMenuCommand(C.ANIME, L_ROW, CHIPS.first + group - 1, ANIME_FOCUS, on and 0 or 2, ANIME_BUTTON)
  end
end

-- The centre card changed: the focused row, the guide, the lit mark and the lit chip follow it.
local function CentreChanged()
  FocusCard(carousel:centre_instance())
  UpdateButtonGuide()
  local item = carousel:centre_item()
  local group = ITEMS[item + 1].group
  GROUPS[group].at = item
  if item ~= marked.item then
    if marked.item ~= nil then
      MarkLook(marked.item, false)
    end
    MarkLook(item, true)
    marked.item = item
  end
  if group ~= marked.group and #GROUPS > 1 then
    if marked.group ~= nil then
      ChipLook(marked.group, false)
    end
    ChipLook(group, true)
    marked.group = group
  end
end

-- Moves the carousel one card: 1 = the next slot, -1 = the previous one.
local function Move(direction)
  local moved, fill = carousel:move(direction)
  if not moved then
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  if fill ~= nil then
    FillCard(fill.instance)
  end
  CentreChanged()
end

-- Brings the card of instance i to the centre (a click on a neighbour card).
local function MoveToInstance(i)
  local offset = carousel:offset_of(i)
  for _ = 1, math.abs(offset) do
    Move(offset)
  end
end

-- Switches to the next (1) or previous (-1) group: its card last seen, else its first one.
local function MoveGroup(direction)
  local group = ITEMS[carousel:centre_item() + 1].group
  local to = GROUPS[(group - 1 + direction) % #GROUPS + 1]
  funcLuaCommand(C.SE, SE_OK)
  Log("group", to.title, "card", (to.at or to.first) + 1, "of", #ITEMS)
  carousel:jump(to.at or to.first)
  FillCards()
  CentreChanged()
end

--@lib vrfw_menu_kit.lua#StartCo

local IDENT_KEY = "vrfw_slot_screen_identified"
local function LogIdentification()
  local now = VRFW.save_slots.IDENTIFIED ~= nil and 1 or 2
  if VRFW.param.get(IDENT_KEY) == now then
    return
  end
  VRFW.param.replace(IDENT_KEY, now, "plain")
  if now == 1 then
    Log("screen identified as", VRFW.save_slots.IDENTIFIED, "by the framework's fingerprint (require vrfw_save_slots_on_sub_window)")
  else
    Log("WARN screen not identified by the framework's fingerprint: its patch folder did not run")
  end
end

function OnInit()
  LoadTexts()
  LogIdentification()
  Log("OnInit build", VRFW.slot_menu_build, "MENU_DEF", MENU_DEF ~= nil and MENU_DEF.OpenSubWindow ~= nil and "yes" or "no")
  local a = Call(loader_commands.GET_SLOT)
  if type(a) == "number" and a >= 1 and a <= MAX_SLOT then
    active = math.floor(a)
  end
  local lay = {Call(loader_commands.LAYOUT)}
  if type(lay[1]) == "number" and lay[1] >= 1 then
    PLAYER = {}
    for k = 4, 3 + math.floor(lay[1]) do
      if type(lay[k]) == "number" and lay[k] >= 1 then
        table.insert(PLAYER, math.floor(lay[k]))
      end
    end
    if #PLAYER == 0 then
      PLAYER = {1, 2, 3}
    end
    LOCKED_SLOT = type(lay[2]) == "number" and math.floor(lay[2]) or LOCKED_SLOT
  end
  has_ext = type(Call(loader_commands.NAME_GET, PLAYER[1])) == "string"
  BuildItems()
  Log("layout: player slots", table.concat(PLAYER, ","), "locked", LOCKED_SLOT, "cards", #ITEMS, "groups", #GROUPS)
  carousel = VRFW.layer_carousel.new({
    parts = {{layer = L_ROW, pivot = CAROUSEL.band_pivot}, {layer = L_WIN, pivot = CAROUSEL.window_pivot}},
    places = CAROUSEL.places, frames = CAROUSEL.frames, wrap = true,
  })
  if carousel:instances() ~= RING then
    Log("ERROR the carousel needs", carousel:instances(), "instances, the screen has", RING)
  end
  -- The start card: the active slot, else the first player slot that can be played.
  start_item = (PLAYER[1] == LOCKED_SLOT and #PLAYER > 1) and 1 or 0
  for k, it in ipairs(ITEMS) do
    if it.slot == active and it.slot ~= LOCKED_SLOT and (it.reserved == nil or not it.reserved.locked) then
      start_item = k - 1
    end
    if it.reserved ~= nil then
      Log("mod card: slot", it.slot, "owner", it.reserved.owner, "provider", next(it.reserved.p) ~= nil and "yes" or "no",
          it.reserved.locked and "LOCKED (mode off)" or "enterable")
      local art = it.reserved.p.art
      if type(art) == "table" and type(art.tex) == "string" and not loaded_tex[art.tex] then
        loaded_tex[art.tex] = true
        funcLuaMenuCommand(C.LOAD_TEX, art.tex)
      end
      info[it.slot] = ReadInfo(it.slot)
    else
      ReadSlot(it.slot)
    end
  end
  GROUPS[ITEMS[start_item + 1].group].at = start_item
  funcLuaMenuCommand(C.LOAD_TEX, ART_PATH)
  VRFW.param.clear(KEY_RESULT)
end

local rows_open, open_wait = false, 3

-- Opens the carousel once the bands and the windows exist and their open animations started (called from Step).
local function StepOpen()
  if opened or not (windows_ready and rows_open) then
    return
  end
  if open_wait > 0 then
    open_wait = open_wait - 1
    return
  end
  carousel:open(#ITEMS, start_item)
  opened = true
  focus = carousel:centre_instance()
  FillCards()
  SetupChips()
  SetupMarks()
  CentreChanged()
  Log("carousel open: card", start_item + 1, "of", #ITEMS, "marks", marked.count, "chips", #GROUPS > 1 and #GROUPS or 0)
end

function OnSetupLayer(a1, a2)
  if a1 == L_HEADER then
    SetupSoccerTopCommonHeaderLayerInfo(a1, 4153539961, 253801632, 3969848060, 1144161661, 3293713115, 253801632, 1152304044, 305955024, 3007971317)
    SwapSoccerTopCommonHeaderMenuModeIconTexture(758233070 --[[mode_base07]])
    UpdateHeader(3586861540)
    funcLuaMenuCommand(C.TEXT, a1, 1220590795 --[[_text_sub_title02]], TXT.HEADER)
  elseif a1 == L_ROW then
    if a2 >= RING then
      -- a chip or a mark: hidden until the carousel opens, never the cursor's row, no click zone
      funcLuaMenuCommand(C.LAYER_VISIBLE, a1, a2, false)
      funcLuaMenuCommand(C.ATTACH_TRACE, a1, a2, 3313461902 --[[cursor]], false)
      pcall(funcLuaMenuCommand, 855005857 --[[enable / remove an instance's zone]], a1, a2, false)
      return
    end
    -- a card's band: blank until the carousel opens and fills it
    funcLuaMenuCommand(C.TEXT, a1, BAND.text_on, "", a2)
    funcLuaMenuCommand(C.TEXT, a1, BAND.text_off, "", a2)
  elseif a1 == L_WINBASE then
    funcLuaMenuCommand(C.MESH_VISIBLE, a1, 3186689458 --[[_save_arrow_01]], false)
    for i = 1, RING do
      funcLuaMenuCommand(C.ATTACH_TRACE, a1, 0, WIN_LABELS[i], true)
    end
    for i = 0, RING - 1 do
      funcLuaMenuCommand(C.OPEN_LAYER, L_WIN, i)
    end
  elseif a1 == L_WIN then
    ClearCard(a2)   -- blank until the carousel opens and fills it
    if a2 == RING - 1 then
      windows_ready = true
    end
  elseif a1 == L_GUIDE_LINE then
    funcLuaMenuCommand(C.TEXT, a1, 378156699 --[[_text_guide01]], TXT.GUIDE, 0)
  end
end

function OnOpenLayer(a1, a2)
  if a1 == L_ROW and a2 == 0 then
    rows_open = true
    funcLuaMenuCommand(C.OPEN_LAYER, L_CURSOR, 0)
    funcLuaMenuCommand(C.FOCUS_ENABLE, a1, true)
    funcLuaMenuCommand(C.LIST_NUM, a1, RING)
    if funcLuaCommand(C.FADE_DONE) then
      funcLuaCommand(C.FADE, 0, 0.3)
    end
  elseif a1 == L_GUIDE_LINE then
    funcLuaMenuCommand(C.TEXT, a1, 378156699 --[[_text_guide01]], TXT.GUIDE, 0)
  end
end

-- The carousel keeps the focused row on its centre card: the engine's own focus changes (the pointer) move nothing.
function OnChangeFocus(a1, a2)
end

function OnDecideFocus(a1, a2)
  Log("OnDecideFocus", a1, "slot", type(a2) == "number" and tostring(SlotAt(a2)) or tostring(a2), "busy", vrfw_co ~= nil and "yes" or "no")
  if a1 ~= L_ROW or vrfw_co ~= nil or not opened or type(a2) ~= "number" or a2 < 0 or a2 >= RING then
    return
  end
  if a2 ~= focus then
    MoveToInstance(a2)   -- a neighbour card was clicked: it comes to the centre
    return
  end
  StartCo(Decide, a2)
end

-- The function keys of the rows (MENU_CMD_INFO CMD_FUNCTION ids): previous / next slot, rename, delete, duplicate.
function OnFunction(a1, a2)
  Log("OnFunction", tostring(a1), tostring(a2), "slot", tostring(SlotAt(focus)), "busy", vrfw_co ~= nil and "yes" or "no")
  if vrfw_co ~= nil or not opened then
    return 1
  end
  local id = a1
  if a1 ~= FN_RENAME and a1 ~= FN_DELETE and a1 ~= FN_DUP and a1 ~= FN_PREVIOUS and a1 ~= FN_NEXT then
    id = a2
  end
  if id == FN_PREVIOUS then
    Move(-1)
    return 1
  elseif id == FN_NEXT then
    Move(1)
    return 1
  end
  local it = ItemAt(focus)
  if it == nil or it.reserved ~= nil then
    return 1          -- no name / delete / duplicate on a mod's slot
  end
  if id == FN_DUP then
    Log("key X (CMD_FUNC4) slot", tostring(it.slot))
    StartCo(Duplicate, focus)
    return 1
  elseif id == FN_RENAME then
    StartCo(Rename, focus)
    return 1
  elseif id == FN_DELETE then
    StartCo(Delete, focus)
    return 1
  end
end

function OnEnter(a1, a2)
  Log("OnEnter", tostring(a1), tostring(a2), "slot", tostring(SlotAt(focus)))
  if a1 == 9396745 --[[mainmenu01_07_button_guide]] or a1 == 2005383485 --[[mainmenu01_10_return_arrow_button_guide]] then
    return 1
  end
  if a1 == L_ROW then
    local i = a2
    if i == nil or i < 0 or i >= RING then
      i = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
    end
    OnDecideFocus(a1, i)
  end
end

function OnBack(a1)
  Log("OnBack", tostring(a1), "busy", vrfw_co ~= nil and "yes" or "no")
  if vrfw_co ~= nil then
    return 1
  end
  funcLuaCommand(C.SE, SE_BACK)
  Close(0)
  return 1
end

-- Redraws when the loading is waiting.
local function RedrawWhenLoaded()
  if not opened or next(wait_tex) == nil then
    return
  end
  wait_frames = wait_frames + 1
  for crc in pairs(wait_tex) do
    if funcLuaCommand(C.TEX_LOADING, crc) ~= true then
      wait_tex[crc] = nil
    end
  end
  if next(wait_tex) == nil or wait_frames >= 900 then
    Log("textures in after frames", wait_frames, "pending", next(wait_tex) ~= nil and "yes" or "no")
    wait_tex = {}
    FillCards()
  end
end

function Step()
  StepOpen()
  if opened then
    carousel:step()
    RedrawWhenLoaded()
  end
  if vrfw_co == nil and opened then
    -- the provider's reset (CMD_FUNC2) on a mod's card
    local it = ItemAt(focus)
    if it ~= nil and it.reserved ~= nil and not it.reserved.locked and type(it.reserved.p.reset) == "table"
        and funcLuaCommand(CHECK_INPUT, MENU_CTRL, K_FUNC2) == true then
      StartCo(ReservedReset, it)
    elseif #GROUPS > 1 then
      -- the groups (L1 / R1)
      if funcLuaCommand(CHECK_INPUT, MENU_CTRL, K_GROUP_PREVIOUS) == true then
        MoveGroup(-1)
      elseif funcLuaCommand(CHECK_INPUT, MENU_CTRL, K_GROUP_NEXT) == true then
        MoveGroup(1)
      end
    end
  end
  if vrfw_co ~= nil then
    if coroutine.status(vrfw_co) == "dead" then
      vrfw_co = nil
    else
      local ok, err = coroutine.resume(vrfw_co)
      if not ok then
        PRINT("vrfw_save_slot_menu: " .. tostring(err))
        Log("error", tostring(err))
        vrfw_co = nil
        funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
      elseif coroutine.status(vrfw_co) == "dead" then
        vrfw_co = nil
      end
    end
  end
end
