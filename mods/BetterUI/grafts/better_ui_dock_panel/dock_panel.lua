-- Only node / layer transforms of this menu's layer instances
BetterUI = type(BetterUI) == "table" and BetterUI or {}
-- @@dock_panel_layout BEGIN (research/mods/BetterUI/_tools/betterui_dock_panel.py --write; computed from the retail layouts, not seen in game)
local FRAME_LAYOUT = {
  [@crc:soccer11_02_formation_frame@] = {  -- soccer11_02_formation_frame
    {@crc:_atc_formation01@, -426.13, -253.0},
    {@crc:_atc_build01@, -318.13, -220.0},
    {@crc:_atc_uniform01@, -35.4, 460.0},
    {@crc:_atc_tactics01@, -366.0, -132.0},
  },
  [@crc:mainmenu04_10_formation_base@] = {  -- mainmenu04_10_formation_base
    {@crc:_atc_formation01@, -426.13, -233.0},
    {@crc:_atc_build01@, -318.13, -200.0},
    {@crc:_atc_uniform01@, -35.4, 480.0},
    {@crc:_atc_tactics01@, -366.0, -112.0},
  },
}
local TACTICS_BASE_LAYOUT = {
  {@crc:_atc_tactics01@, -108.0, -9.0},
  {@crc:_atc_tactics02@, 0.0, -9.0},
  {@crc:_atc_tactics03@, 108.0, -9.0},
}
local TACTIC_PLATE_CLIPPED = {
  [0] = {
    {@crc:_cmd_base_t01@, -309.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_add01@, -309.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_add02@, -309.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_grayout01@, -309.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_blank01@, -309.09, 58.97, 378.18, 117.95},
    {@crc:_t_ring01@, -60.61, 71.79, 121.21, 143.59},
    {@crc:_cmd_base_t_effect01@, -80.0, 50.0, 160.0, 100.0},
    {@crc:_touch_cmd_base01@, -53.33, 33.33, 106.67, 66.67},
    {@crc:_icon_tactics_dmy01@, -22.86, 22.86, 45.71, 45.71},
  },
  [1] = {
    {@crc:_cmd_base_t01@, -189.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_add01@, -189.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_add02@, -189.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_grayout01@, -189.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_blank01@, -189.09, 58.97, 378.18, 117.95},
    {@crc:_t_ring01@, -60.61, 71.79, 121.21, 143.59},
    {@crc:_cmd_base_t_effect01@, -80.0, 50.0, 160.0, 100.0},
    {@crc:_touch_cmd_base01@, -53.33, 33.33, 106.67, 66.67},
    {@crc:_icon_tactics_dmy01@, -22.86, 22.86, 45.71, 45.71},
  },
  [2] = {
    {@crc:_cmd_base_t01@, -69.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_add01@, -69.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_add02@, -69.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_grayout01@, -69.09, 58.97, 378.18, 117.95},
    {@crc:_cmd_base_t_blank01@, -69.09, 58.97, 378.18, 117.95},
    {@crc:_t_ring01@, -60.61, 71.79, 121.21, 143.59},
    {@crc:_cmd_base_t_effect01@, -80.0, 50.0, 160.0, 100.0},
    {@crc:_touch_cmd_base01@, -53.33, 33.33, 106.67, 66.67},
    {@crc:_icon_tactics_dmy01@, -22.86, 22.86, 45.71, 45.71},
  },
}
local TACTIC_PLATE_SQUEEZED = {
  {@crc:_cmd_base_t01@, -58.18, 58.97, 116.36, 117.95},
  {@crc:_cmd_base_t_add01@, -58.18, 58.97, 116.36, 117.95},
  {@crc:_cmd_base_t_add02@, -58.18, 58.97, 116.36, 117.95},
  {@crc:_cmd_base_t_grayout01@, -58.18, 58.97, 116.36, 117.95},
  {@crc:_cmd_base_t_blank01@, -58.18, 58.97, 116.36, 117.95},
  {@crc:_t_ring01@, -60.61, 71.79, 121.21, 143.59},
  {@crc:_cmd_base_t_effect01@, -80.0, 50.0, 160.0, 100.0},
  {@crc:_touch_cmd_base01@, -53.33, 33.33, 106.67, 66.67},
  {@crc:_icon_tactics_dmy01@, -22.86, 22.86, 45.71, 45.71},
}
local TACTIC_FOCUS_LAYOUT = {
  {@crc:_list_t_focus01@, -54.79, 41.03, 109.58, 82.05},
  {@crc:_touch_list01@, -53.33, 33.33, 106.67, 66.67},
  {@crc:_pos_atc_cur01@, -53.33, 0.0},
}
local FORMATION_BOX_LAYOUT = {
  {@crc:_base_formation01@, -342.87, -24.0, 289.75, 76.0},
  {@crc:_focus_formation01@, -342.87, -24.0, 289.75, 76.0},
  {@crc:_base_formation_blank_stop01@, -340.75, -28.0, 285.51, 68.0},
  {@crc:_touch_formation01@, -338.63, -30.0, 281.27, 64.0},
  {@crc:_gtxt_formation01@, -318.0, 7.0},
  {@crc:_pos_atc_cur01@, -333.69, -60.0},
  {@crc:_pos_atc_free01@, -162.67, -74.0},
}
local TEAM_CONFIG_LAYOUT = {
  {@crc:_base_build01@, -151.13, -57.0, 110.25, 76.0},
  {@crc:_focus_build01@, -151.13, -57.0, 110.25, 76.0},
  {@crc:_touch_build01@, -193.0, -30.0, 194.0, 130.0},
  {@crc:_gtxt_teambuild01@, -142.03, -40.41, 92.06, 19.27},
  {@crc:_icon_build_dmy01@, -121.15, -69.85, 50.31, 50.31},
  {@crc:_pos_atc_cur01@, -134.0, -93.93},
  {@crc:_pos_atc_free01@, -53.18, -93.93},
  {@crc:_pos_atc_flavor01@, -53.18, -50.04},
}
local KIT_ICON_LAYOUT = {
  {@crc:_icon_uniform_dmy01@, -106.0, -53.0, 84.0, 84.0},
  {@crc:_icon_uniform_dmy02@, -106.0, -53.0, 0.0, 0.0},
  {@crc:_focus_uniform01@, -114.0, -45.0, 100.0, 100.0},
  {@crc:_touch_uniform01@, -114.0, -45.0, 100.0, 100.0},
  {@crc:_pos_atc_cur01@, -114.0, -95.0},
  {@crc:_pos_atc_free01@, -14.0, -145.0},
}
local KIT_HIDDEN_NODES = {@crc:_base_uniform01@, @crc:_gtxt_uniform01@, @crc:_icon_uniform_dmy02@}
local HEADER_BAR_LAYOUT = {
  {@crc:_icon_emblem_dmy01@, -535.0, 50.0},
  {@crc:_focus_emblem01@, -540.0, 50.0},
  {@crc:_touch_emblem01@, -534.0, 44.0},
  {@crc:_pos_atc_cur01@, -520.0, 0.0},
  {@crc:_pos_atc_free01@, -484.0, 0.0},
  {@crc:_gtxt_team_lv01@, 532.6, 8.8, 48.0, 30.0},
  {@crc:num_team_lv01@, 584.6, 21.2, 0.8, 0.8},  -- num_team_lv01
  {@crc:_atc_deck01@, 280.6, 0.0},
  {@crc:_atc_lock01@, 280.6, 0.0},
  {@crc:_atc_name01@, -155.0, 0.0},
}
local TEAM_NAME_LAYOUT = {    -- team01_04_p1_team_name_frame: 307.6 px wide
  {@crc:_base_team01@, -234.0, 30.0, 307.6, 60.0},
  {@crc:_base_focus01@, -234.0, 30.0, 307.6, 60.0},
  {@crc:_touch_base01@, -228.0, 24.0, 295.6, 48.0},
  {@crc:_pos_atc_free01@, -28.93, -10.0},
}
local HEADER_LAYOUT = {crest = @crc:_icon_emblem_dmy01@, cx = -484.0, cy = -1.0, kx = -21.4, ky = -1.0,  -- crest centre, kit centre (bar units)
  ux = -64.0, uy = -95.0,  -- the kit's centre in its own layer (the retail hit zone's centre)
  nv_atlas = 4225297828, nv_sprite = @crc:gtxt_lv_l01@, nv_slot = @crc:gtxt_team_lv@,
  nv_mesh = @crc:_gtxt_team_lv01@, nv_rgb = {0.192, 0.463, 1.0}}
local HEADER_BAR_RETAIL = {  -- the same nodes at their retail values (header left retail)
  {@crc:_icon_emblem_dmy01@, -651.0, 50.0},
  {@crc:_focus_emblem01@, -656.0, 50.0},
  {@crc:_touch_emblem01@, -650.0, 44.0},
  {@crc:_pos_atc_cur01@, -636.0, 0.0},
  {@crc:_pos_atc_free01@, -600.0, 0.0},
  {@crc:_gtxt_team_lv01@, -75.0, 30.0, 140.0, 60.0},
  {@crc:num_team_lv01@, 64.0, 25.0, 1.0, 1.0},  -- num_team_lv01
  {@crc:_atc_deck01@, 418.0, 0.0},
  {@crc:_atc_lock01@, 418.0, 0.0},
  {@crc:_atc_name01@, -308.0, 0.0},
}
local TEAM_NAME_RETAIL = {
  {@crc:_base_team01@, -234.0, 30.0, 468.0, 60.0},
  {@crc:_base_focus01@, -234.0, 30.0, 468.0, 60.0},
  {@crc:_touch_base01@, -228.0, 24.0, 456.0, 48.0},
  {@crc:_pos_atc_free01@, 78.0, -10.0},
}
local KIT_BOX_RETAIL = {
  {@crc:_icon_uniform_dmy01@, -111.0, -48.0, 94.0, 94.0},
  {@crc:_icon_uniform_dmy02@, -103.0, -56.0, 94.0, 94.0},
  {@crc:_focus_uniform01@, -135.0, -24.0, 142.0, 142.0},
  {@crc:_touch_uniform01@, -129.0, -30.0, 130.0, 130.0},
  {@crc:_pos_atc_cur01@, -103.0, -93.0},
  {@crc:_pos_atc_free01@, -16.0, -93.0},
}
local KIT_PANEL_LAYOUT = {    -- panel mode: the kit's field locator, centred under the panel
  [@crc:soccer11_02_formation_frame@] = {-507.0, -92.0},  -- soccer11_02_formation_frame
  [@crc:mainmenu04_10_formation_base@] = {-507.0, -72.0},  -- mainmenu04_10_formation_base
}
local HEADER_CHECK = {name_l = -389.0, deck_l = 38.6, tol = 16,
  nv_atlas = 3197067911}
local HEADER_CREST_CORNER = {-535.0, 50.0}  -- crest mesh top-left (bar units): the run-time scale reference
local ATTACK_DEFENSE_LAYOUT = {
  layer = @crc:mainmenu04_06_team_atdf@, frame = @crc:soccer11_02_formation_frame@, scl = @crc:_pos_scl01@, num = @crc:_pos_num_team_at01@, field = @crc:_formation_field01@, gk = @crc:_pos_formation01@,
  dx = 221.0, dy = 46.0, fx = -348.0, fy = 280.0, tx = 0.0, ty = -58.0, scale = 0.5}  -- base->scl x, scl->AT number y; field mesh from _pos_base01
local DOCK_NUMBER_LAYOUT = {
  {@crc:_arrow01_l@, 8.8, -16.0, 26.4, 48.0},
  {@crc:_arrow01_r@, 8.8, -16.0, 26.4, 48.0},
  {@crc:_text_btn_l01@, -336.8, 103.0},
  {@crc:_text_btn_r01@, 31.8, 103.0},
}
local MOD_BUTTON_LAYOUT = {
  step = -72.0, dx = 0.0, pdx = -139.0, dy = -384.5, h = 107.0, mesh = @crc:_synergy_top_base01@, mx = -66.0, my = 36.0, mw = 132.0, mh = 72.0}
local TEAM_ICON_LAYOUT = {
  dy = -292.6, pdx = -139.0, step = 132.8, scale = 0.9}
-- @@dock_panel_layout END

if BetterUI.dock_panel == nil then
  BetterUI.dock_panel = true
end
if BetterUI.dock_clip == nil then
  BetterUI.dock_clip = false
end
if BetterUI.dock_tactics == nil then
  BetterUI.dock_tactics = false
end
if BetterUI.dock_arrows == nil then
  BetterUI.dock_arrows = true
end
if BetterUI.dock_atdf == nil then
  BetterUI.dock_atdf = true             -- AT / DF block under the goalkeeper
end

local Dock = {
  -- layers (crc32 of the setting's layer names)
  TAC = @crc:team00_11_p1_tactics_focus@,               -- team00_11_p1_tactics_focus x3 (the focusable boxes, scissor frames)
  CMD = @crc:soccer08_12_tactics_cmd@,               -- soccer08_12_tactics_cmd x3 (plate + icon)
  BASE = @crc:team00_10_tactics_base@,
  FORM = @crc:team00_12_formation_style@,              -- team00_12_formation_style
  UNI = @crc:team00_13_uniform_icon@,               -- team00_13_uniform_icon
  CONF = @crc:team00_14_build_type_icon@,               -- team00_14_build_type_icon
  BALLOON = @crc:team00_15_build_type_balloon@,           -- team00_15_build_type_balloon
  DOCKNO = @crc:team01_05_team_dock_no@,            -- team01_05_team_dock_no
  BAR = @crc:team01_04_team_name_bar@,
  NAME = @crc:team01_04_p1_team_name_frame@,              -- team01_04_p1_team_name_frame
  DECK = @crc:team01_04_p2_deck_name_frame@,              -- team01_04_p2_deck_name_frame (the player plate)
  VR_MENU = @crc:victory_road_top_menu@,           -- victory_road_top_menu (g_parentMenuId): its own header, left retail
  IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@,        -- CMND_IS_LAYER_VISIBLE (layer, idx) -> bool
  NAME_BASE = @crc:_base_team01@,
  DECK_BASE = @crc:_base_deck01@,
  LIST = @crc:team01_02_list_item@,              -- team01_02_list_item
  CARDS = @crc:team00_01_chara_card_for_soccer@,             -- team00_01_chara_card_for_soccer
  LEADER = @crc:team00_01_chara_card_for_leader@,            -- team00_01_chara_card_for_leader (the coach card)
  FRAMES = {@crc:soccer11_02_formation_frame@, @crc:mainmenu04_10_formation_base@},   -- soccer11_02_formation_frame / mainmenu04_10_formation_base
  GUIDE_LINE = @crc:mainmenu90_05_content_guide_line01@, GUIDE_NODE = @crc:_text_guide01@,   -- mainmenu90_05_content_guide_line01 / _text_guide01
  -- nodes
  TEXT_CMD = @crc:_text_cmd01@,
  TEXT_BUILD = @crc:_text_build01@,
  CURSOR = @crc:cursor@,
  POS_BASE = @crc:_pos_base01@,
  ATC_UNI = @crc:_atc_uniform01@,
  KIT_ICON = @crc:_icon_uniform_dmy01@,
  KIT_SHADOW = @crc:_icon_uniform_dmy02@,
  TOUCH_LIST = @crc:_touch_list01@,
  MESH_VIS = @crc:CMND_SET_MESH_VISIBLE@,          -- CMND_SET_MESH_VISIBLE (layer, mesh, bool, idx)
  SET_PRIO = @crc:CMND_SET_DRAW_PRIORITY@,
  KIT_PRIO = 460,
  SLICE_ATLAS = 2640011428,
  SLICES = {[2] = @crc:better_ui_tactic_row_l@, [1] = @crc:better_ui_tactic_row_m@, [0] = @crc:better_ui_tactic_row_r@},   -- better_ui_tactic_row_l / _m / _r by instance
  PLATE_SLOT = @crc:cmd_base_t01@,        -- 0xE7DB0771: _cmd_base_t01 (and its additive overlays)
  SLICES_READY = @crc:CMND_BETTERUI_TACTIC_SLICES@,
  -- menu commands
  NODE_POS = 2575768773,
  NODE_SCALE = 2885415772,        -- (layer, idx, node, sx, sy): node local scale (nie 0xCE7960)
  NODE_VIS = 2158717427,          -- (layer, node, bool, idx)
  TEXT_VIS = @crc:CMND_SET_MENU_TEXT_VISIBLE@,          -- (layer, text node, bool, idx)
  SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@,          -- (layer, text node, string, idx)
  SWAP = 558735651,
  PRIM_COLOR = @crc:CMND_SET_PRIM_COLOR@,
  PRIM_ALPHA = @crc:CMND_SET_PRIM_ALPHA@,        -- CMND_SET_PRIM_ALPHA (layer, idx, mesh, a)
  GPOS = @crc:CMND_GET_MESH_GLOBAL_POSITION@,               -- CMND_GET_MESH_GLOBAL_POSITION (layer, idx, node) -> x, y, z
  SCISSOR_UPDATE = 1607272191,    -- (layer, idx)
  SCISSOR_COPY = @crc:CMND_REQ_FP_BUILD_SET@,      -- (layer, idx, from layer, from idx)
  SCISSOR_ON = @crc:CMND_DELETE_PURCHASE_TO@,         -- (layer, idx, bool)
  LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@,      -- (layer, idx, bool)
  FOCUS_ACTIVE = @crc:CMND_IS_CTRL_FOCUS_ACTIVE@,       -- (layer) -> bool
  FOCUS_IDX = 2603265800,         -- (layer) -> focused instance
  FOCUS_SET = 3466097042,         -- (layer, idx)
  FOCUS_MARK = 1778826357,        -- (layer, idx, bool): what the retail dock sends to move its focus
  FOCUS_ENABLE = @crc:CMND_SET_ENABLE_CTRL_FOCUS@,      -- (layer, bool)
  CURSOR_LOC = @crc:CMND_SET_CURSOR_LOCATOR@,         -- (layer, crc32("cursor"), idx, count)
  CURSOR_TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@,
  CARD_CURSOR = 945715707,
  CREATE_NUM = @crc:CMND_GET_CREATE_LAYER_NUM@,        -- (layer) -> instances
  IS_OPEN = @crc:CMND_IS_OPEN_LAYER@,           -- (layer[, idx]) -> bool
  LAYER_ACTIVE = @crc:CMND_IS_MENU_LAYER_ACTIVE@,
  LAYER_POS = @crc:CMND_SET_LAYER_LOCAL_POS@,
  LAYER_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@,       -- CMND_SET_LAYER_LOCAL_SCALE (layer, sx, sy, sz, idx)
  ZONE = @crc:CMND_SET_MENU_COLLISION_HIT_ALL@,
  POINTER = 558229292,            -- () -> x, y: the pointer, screen px, y down
  PLAY_ANIME = @crc:CMND_PLAY_ANIME_TYPE@,        -- CMND_PLAY_ANIME_TYPE (layer, idx, anime, mode, kind)
  ANIME_ACTIVE = @crc:Active@, ANIME_FOCUS = @crc:Focus@, ANIME_BUTTON = @crc:button@,   -- "Active", "Focus", "button"
  -- funcLuaCommand
  SOUND = @crc:CMND_SND_PLAY_SE@, SE_MOVE = @crc:sy0005@,   -- sy0005: the dock's cursor sound
  TEXT_GET = @crc:CMND_TEXT_GET@, CARD_GUIDE = 104932408,   -- t2[1].itemExplation of the retail dock (a card is focused)
  LOG = @crc:CMND_VRFW_LOG@,               -- CMND_VRFW_LOG
  LOG_DEBUG = @crc:CMND_VRFW_LOG_DEBUG@,         -- CMND_VRFW_LOG_DEBUG
  -- OnChangeFocus argument of the retail FCS_CHANGE right row
  ARG_RIGHT = 2682339866,
  busy = false, echo = false, logged = false, kit = {}, clipLogged = false,
  hdr = nil,
  check = 0,                      -- Steps left to measure the placed header
  wait = 0,
  shift = nil, going = false, moves = 0,
  ghost = nil,
  kitc = nil, nameR = nil, zoneLogs = 0,
  zoneOff = {},
  hfocus = nil, hfocusLogs = 0,   -- the header item holding the focus (logged once per change)
  atdf = {x = 0, y = 0, s = 1, wait = 0, n = 0},   -- the AT / DF layer's local pos / scale as last sent
}

local function menu_command(...)
  if type(funcLuaMenuCommand) == "function" then
    return pcall(funcLuaMenuCommand, ...)
  end
  return false
end

local function menu_query(...)
  local ok, v = menu_command(...)
  if ok then
    return v
  end
  return nil
end

local function engine_command(...)
  if type(funcLuaCommand) == "function" then
    local ok, v = pcall(funcLuaCommand, ...)
    if ok then
      return v
    end
  end
  return nil
end

local function log_info(msg)
  engine_command(Dock.LOG, "EVT dock_panel " .. msg)
end

local function log_debug(msg)
  engine_command(Dock.LOG_DEBUG, "EVT dock_panel " .. msg)
end

-- focus moves and shifts share one log budget (first 80)
local function log_move(msg)
  if Dock.moves < 80 then
    Dock.moves = Dock.moves + 1
    log_info(msg)
  end
end

local function pack_args(...)
  return {n = select("#", ...), ...}
end

local function is_open(layer, idx)
  return menu_query(Dock.IS_OPEN, layer, idx or 0) == true
end

-- open and its layer group not suspended (a child menu / a dock move owns the zones then)
local function is_live(layer)
  return is_open(layer, 0) and menu_query(Dock.LAYER_ACTIVE, layer) ~= false
end

-- a node's global position -> x, y (nil when not measurable)
local function global_position(layer, idx, node)
  local ok, x, y = menu_command(Dock.GPOS, layer, idx, node)
  if ok and type(x) == "number" and type(y) == "number" then
    return x, y
  end
  return nil
end

local function pointer_position()
  local ok, x, y = menu_command(Dock.POINTER)
  if ok and type(x) == "number" and type(y) == "number" then
    return x, y
  end
  return nil
end

local function set_guide_text(text)
  menu_command(Dock.SET_TEXT, Dock.GUIDE_LINE, Dock.GUIDE_NODE, text, 0)
end

local function play_anime(layer, idx, anime, mode)
  menu_command(Dock.PLAY_ANIME, layer, idx, anime, mode, Dock.ANIME_BUTTON)
end

-- the dock opener's team editor spec (VRFW.team_editor.foreign()), nil when none
local function foreign_editor_spec()
  return type(VRFW.team_editor) == "table" and type(VRFW.team_editor.foreign) == "function"
    and VRFW.team_editor.foreign() or nil
end

local function panel_enabled()
  return BetterUI.dock_panel == true
end

local function tactics_enabled()
  return panel_enabled() and BetterUI.dock_tactics == true
end

local function clip_enabled()
  return tactics_enabled() and BetterUI.dock_clip == true
end

local function arrows_enabled()
  return BetterUI.dock_arrows == true
end

local function attack_defense_enabled()
  return panel_enabled() and BetterUI.dock_atdf == true
end

local function send_attack_defense()
  local st = Dock.atdf
  menu_command(Dock.LAYER_SCALE, ATTACK_DEFENSE_LAYOUT.layer, st.s, st.s, 1, 0)
  menu_command(Dock.LAYER_POS, ATTACK_DEFENSE_LAYOUT.layer, st.x, st.y, 0, 0)
end

local TACTICS_FRAME_LOCATOR = @crc:_atc_tactics01@

local function place_nodes(layer, idx, rows, skip)
  for _, r in ipairs(rows) do
    if r[1] ~= skip then
      menu_command(Dock.NODE_POS, layer, idx, r[1], 0, r[2])
      menu_command(Dock.NODE_POS, layer, idx, r[1], 1, r[3])
      if r[4] ~= nil then
        menu_command(Dock.NODE_SCALE, layer, idx, r[1], r[4], r[5])
      end
    end
  end
end

local function hide_tactic_text(idx)
  menu_command(Dock.SET_TEXT, Dock.CMD, Dock.TEXT_CMD, "", idx)
  menu_command(Dock.NODE_VIS, Dock.CMD, Dock.TEXT_CMD, false, idx)
end

local function hide_config_text()
  menu_command(Dock.TEXT_VIS, Dock.CONF, Dock.TEXT_BUILD, false, 0)
  menu_command(Dock.NODE_VIS, Dock.CONF, Dock.TEXT_BUILD, false, 0)
end

-- the kit's frame locator (absolute frame units), as placed last
local function kit_locator(frame)
  if Dock.kit[frame] == nil then
    for _, r in ipairs(FRAME_LAYOUT[frame]) do
      if r[1] == Dock.ATC_UNI then
        Dock.kit[frame] = {r[2], r[3]}
      end
    end
  end
  return Dock.kit[frame]
end

local function set_kit_locator(frame, k)
  menu_command(Dock.NODE_POS, frame, 0, Dock.ATC_UNI, 0, k[1])
  menu_command(Dock.NODE_POS, frame, 0, Dock.ATC_UNI, 1, k[2])
end

-- Panel mode: places the kit under the panel.
local KIT_ASIDE_DX = -445.0
local function place_kit_under_panel(frame)
  local k = KIT_PANEL_LAYOUT[frame]
  if k == nil then
    return nil
  end
  local I = Dock.read_icons()
  if I.n > 0 and I.hide then
    return {k[1] + KIT_ASIDE_DX, k[2]}
  end
  return k
end

local function apply_header(layer, mode)
  local hdr = mode == "header"
  if layer == Dock.UNI then
    if hdr then
      place_nodes(layer, 0, KIT_ICON_LAYOUT)
      menu_command(Dock.SET_PRIO, layer, 0, Dock.KIT_PRIO)
    else
      place_nodes(layer, 0, KIT_BOX_RETAIL)
    end
    for _, n in ipairs(KIT_HIDDEN_NODES) do
      menu_command(Dock.NODE_VIS, layer, n, not hdr, 0)
    end
    menu_command(Dock.MESH_VIS, layer, Dock.KIT_SHADOW, not hdr, 0)
  elseif layer == Dock.BAR then
    if hdr then
      place_nodes(layer, 0, HEADER_BAR_LAYOUT)
      menu_command(Dock.SWAP, layer, HEADER_LAYOUT.nv_atlas, HEADER_LAYOUT.nv_sprite, HEADER_LAYOUT.nv_slot, 0, 0)
      local c = HEADER_LAYOUT.nv_rgb
      menu_command(Dock.PRIM_COLOR, layer, 0, HEADER_LAYOUT.nv_mesh, c[1], c[2], c[3])
      menu_command(Dock.PRIM_ALPHA, layer, 0, HEADER_LAYOUT.nv_mesh, 1)
    else
      place_nodes(layer, 0, HEADER_BAR_RETAIL)
      menu_command(Dock.SWAP, layer, HEADER_CHECK.nv_atlas, HEADER_LAYOUT.nv_slot, HEADER_LAYOUT.nv_slot, 0, 0)
      menu_command(Dock.PRIM_COLOR, layer, 0, HEADER_LAYOUT.nv_mesh, 1, 1, 1)   -- the retail label carries its own blue
    end
  elseif layer == Dock.NAME then
    place_nodes(layer, 0, hdr and TEAM_NAME_LAYOUT or TEAM_NAME_RETAIL)
  end
end

local function apply_layer(layer, idx)
  idx = idx or 0
  if panel_enabled() then
    if FRAME_LAYOUT[layer] ~= nil then
      if idx == 0 then
        place_nodes(layer, 0, FRAME_LAYOUT[layer], (not tactics_enabled()) and TACTICS_FRAME_LOCATOR or nil)
        local k = Dock.hdr == "header" and kit_locator(layer) or place_kit_under_panel(layer)
        if k ~= nil then
          set_kit_locator(layer, k)
        end
      end
    elseif layer == Dock.BASE then
      if tactics_enabled() then
        place_nodes(layer, 0, TACTICS_BASE_LAYOUT)
      end
    elseif layer == Dock.CMD then
      if not tactics_enabled() then
        return
      end
      if idx <= 2 then
        place_nodes(layer, idx, clip_enabled() and TACTIC_PLATE_CLIPPED[idx] or TACTIC_PLATE_SQUEEZED)
        hide_tactic_text(idx)
        if not clip_enabled() and engine_command(Dock.SLICES_READY) == true then
          menu_command(Dock.SWAP, layer, Dock.SLICE_ATLAS, Dock.SLICES[idx], Dock.PLATE_SLOT, 0, idx)
        end
      end
    elseif layer == Dock.TAC then
      if idx <= 2 and tactics_enabled() then
        place_nodes(layer, idx, TACTIC_FOCUS_LAYOUT)
      end
    elseif layer == Dock.FORM then
      place_nodes(layer, 0, FORMATION_BOX_LAYOUT)
    elseif layer == Dock.CONF then
      place_nodes(layer, 0, TEAM_CONFIG_LAYOUT)
      hide_config_text()
    elseif (layer == Dock.UNI or layer == Dock.BAR or layer == Dock.NAME) and Dock.hdr ~= nil then
      apply_header(layer, Dock.hdr)
    end
  end
  if layer == ATTACK_DEFENSE_LAYOUT.layer and (Dock.atdf.x ~= 0 or Dock.atdf.y ~= 0 or Dock.atdf.s ~= 1) then
    send_attack_defense()
  end
  if layer == Dock.DOCKNO and arrows_enabled() then
    place_nodes(layer, 0, DOCK_NUMBER_LAYOUT)
  end
  if not Dock.logged and (panel_enabled() or arrows_enabled()) then
    Dock.logged = true
    log_info("on (panel " .. tostring(panel_enabled()) .. ", clip " .. tostring(clip_enabled()) .. ", arrows "
      .. tostring(arrows_enabled()) .. ")")
  end
end

-- Clips the tactic plates; runs every Step.
local function clip_tactic_plates()
  for i = 0, 2 do
    if is_open(Dock.CMD, i) and is_open(Dock.TAC, i) then
      -- the frame must be somewhere on screen, else the box is left unclipped
      local fx, fy = global_position(Dock.TAC, i, Dock.TOUCH_LIST)
      if not Dock.clipLogged then
        log_info("clip box " .. i .. " frame at " .. tostring(fx) .. "," .. tostring(fy))
        if i == 2 then
          Dock.clipLogged = true
        end
      end
      if fx ~= nil and math.abs(fx) < 4096 and math.abs(fy) < 4096 then
        menu_command(Dock.SCISSOR_UPDATE, Dock.TAC, i)
        menu_command(Dock.SCISSOR_COPY, Dock.CMD, i, Dock.TAC, i)
        menu_command(Dock.SCISSOR_ON, Dock.CMD, i, true)
      else
        menu_command(Dock.SCISSOR_ON, Dock.CMD, i, false)
      end
    end
  end
end

-- Corrects the kit position; runs every Step.
local function fix_kit_position()
  if Dock.hdr ~= "header" or not is_open(Dock.BAR, 0) or not is_open(Dock.UNI, 0) then
    return
  end
  local bx, by = global_position(Dock.BAR, 0, Dock.POS_BASE)
  local ex, ey = global_position(Dock.BAR, 0, HEADER_LAYOUT.crest)
  local ux, uy = global_position(Dock.UNI, 0, Dock.POS_BASE)
  local ix, iy = global_position(Dock.UNI, 0, Dock.KIT_ICON)
  if bx == nil or ex == nil or ux == nil or ix == nil then
    return
  end
  local cr = HEADER_CREST_CORNER
  local kbx, kby = (ex - bx) / cr[1], (ey - by) / cr[2]
  local kux, kuy = (ix - ux) / KIT_ICON_LAYOUT[1][2], (iy - uy) / KIT_ICON_LAYOUT[1][3]
  if math.abs(kbx) < 0.05 or math.abs(kby) < 0.05 or math.abs(kux) < 0.05 or math.abs(kuy) < 0.05 then
    return
  end
  Dock.kitc = {ux + HEADER_LAYOUT.ux * kux, uy + HEADER_LAYOUT.uy * kuy, KIT_ICON_LAYOUT[3][4] / 2 * math.abs(kux),
    KIT_ICON_LAYOUT[3][5] / 2 * math.abs(kuy)}
  -- Computes the kit's centre.
  local kx = HEADER_LAYOUT.kx
  local nx = global_position(Dock.NAME, 0, Dock.NAME_BASE)
  local px = global_position(Dock.DECK, 0, Dock.DECK_BASE)
  Dock.nameR = nx ~= nil and nx + TEAM_NAME_LAYOUT[1][4] * kbx or nil   -- the drawn team name plate's right edge (global)
  if nx ~= nil and px ~= nil then
    local gl, gr = (nx - bx) / kbx + TEAM_NAME_LAYOUT[1][4], (px - bx) / kbx
    if gr > gl and gr - gl < 600 then
      kx = (gl + gr) / 2
    end
  end
  local tx, ty = bx + kx * kbx - HEADER_LAYOUT.ux * kux, by + HEADER_LAYOUT.ky * kby - HEADER_LAYOUT.uy * kuy
  local dx, dy = (tx - ux) / kux, (ty - uy) / kuy
  if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
    return
  end
  for _, frame in ipairs(Dock.FRAMES) do
    if is_open(frame, 0) then
      local k = kit_locator(frame)
      if k ~= nil then
        k[1], k[2] = k[1] + dx, k[2] + dy
        set_kit_locator(frame, k)
      end
    end
  end
end

local function is_focus_active(layer)
  return menu_query(Dock.FOCUS_ACTIVE, layer) == true
end

local function focused_index(layer)
  local v = menu_query(Dock.FOCUS_IDX, layer)
  if type(v) == "number" then
    return v
  end
  return 0
end

local function instance_count(layer)
  local v = menu_query(Dock.CREATE_NUM, layer)
  if type(v) == "number" then
    return v
  end
  return 1
end

-- Places the attack and defense items; runs every Step with one correction, then 2 Steps to let the global positions follow.
local function place_attack_defense()
  local A, st = ATTACK_DEFENSE_LAYOUT, Dock.atdf
  if not is_open(A.layer, 0) then
    return
  end
  if not attack_defense_enabled() or not is_open(A.frame, 0) then
    if st.x ~= 0 or st.y ~= 0 or st.s ~= 1 then
      st.x, st.y, st.s = 0, 0, 1
      send_attack_defense()
    end
    return
  end
  if st.wait > 0 then
    st.wait = st.wait - 1
    return
  end
  local fbx, fby = global_position(A.frame, 0, Dock.POS_BASE)
  local ffx, ffy = global_position(A.frame, 0, A.field)
  local gx, gy = global_position(A.frame, 0, A.gk)
  local abx = global_position(A.layer, 0, Dock.POS_BASE)
  local asx, asy = global_position(A.layer, 0, A.scl)
  local _, any = global_position(A.layer, 0, A.num)
  if fbx == nil or ffx == nil or gx == nil or abx == nil or asx == nil or any == nil then
    return
  end
  local kfx, kfy = (ffx - fbx) / A.fx, (ffy - fby) / A.fy        -- global units per field unit
  local kax, kay = (asx - abx) / A.dx / st.s, (any - asy) / A.dy / st.s   -- per unscaled layer unit
  if math.abs(kfx) < 0.05 or math.abs(kfy) < 0.05 or math.abs(kax) < 0.05 or math.abs(kay) < 0.05 then
    return
  end
  local s = A.scale * kfy / kay
  if s < 0.2 or s > 1.5 then
    s = A.scale
  end
  local tx, ty = gx + A.tx * kfx, gy + A.ty * kfy
  local dx, dy = (tx - asx) / kax, (ty - asy) / kay
  if math.abs(s - st.s) < 0.005 and math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
    return
  end
  if math.abs(s - st.s) >= 0.005 then
    st.s = s
  else
    st.x, st.y = st.x + dx, st.y + dy
  end
  send_attack_defense()
  st.wait = 2
  if st.n < 12 then
    st.n = st.n + 1
    log_info(string.format("atdf -> pos %.1f, %.1f scale %.3f (block was %.1f, %.1f from target)", st.x, st.y, st.s,
      dx, dy))
  end
end

local function is_config_shown()
  if not is_open(Dock.CONF, 0) then
    return false
  end
  if type(IsVisibleTeamBuildTypeIcon) == "function" then
    local ok, v = pcall(IsVisibleTeamBuildTypeIcon, Dock.CONF)
    if ok and v == false then
      return false
    end
  end
  return true
end

-- Sets the focus to (layer, idx).
local function set_focus(layer, idx)
  Dock.busy, Dock.echo = true, false
  menu_command(Dock.FOCUS_MARK, layer, idx, true)
  if focused_index(layer) ~= idx then
    menu_command(Dock.FOCUS_SET, layer, idx)
  end
  Dock.busy = false
  if not Dock.echo and type(OnChangeFocus) == "function" then
    pcall(OnChangeFocus, layer, idx)
  end
end

-- the Active and Focus out animations of an instance that loses the focus
local function play_focus_out(layer, idx)
  play_anime(layer, idx, Dock.ANIME_ACTIVE, 2)
  play_anime(layer, idx, Dock.ANIME_FOCUS, 2)
end

-- one instance of the tactics row to another, as the engine's own step inside a layer
local function step_tactics_focus(from, to)
  play_focus_out(Dock.TAC, from)
  menu_command(Dock.CURSOR_LOC, Dock.TAC, Dock.CURSOR, to, instance_count(Dock.TAC))
  set_focus(Dock.TAC, to)
end

local function unfocus(layer, idx)
  Dock.busy = true
  menu_command(Dock.FOCUS_MARK, layer, idx, false)
  Dock.busy = false
  play_focus_out(layer, idx)
end

-- (from, fi) -> (to, ti) like a retail focus shift row
local GHOST_STEPS = 3
-- Layers of the team's identity fixed by the dock's opener (VRFW.team_editor.foreign().lock_identity, a team page).
Dock.LOCKED_LAYERS = {[@crc:team01_04_team_name_bar@] = true, [@crc:team01_04_p1_team_name_frame@] = true, [@crc:team00_13_uniform_icon@] = true,   -- bar (crest), team name, kit
  [@crc:home_stadium_dock_button@] = true}
function Dock.locked()
  if Dock.lock == nil then
    local f = foreign_editor_spec()
    Dock.lock = type(f) == "table" and f.tab == true and f.lock_identity == true
  end
  return Dock.lock
end

local function move_focus(from, fi, to, ti)
  log_move("focus " .. tostring(from) .. "[" .. tostring(fi) .. "] -> " .. tostring(to) .. "[" .. tostring(ti) .. "]")
  Dock.going = true
  if type(OnFocusLayerShift) == "function" then
    pcall(OnFocusLayerShift, from, fi, to, ti)
  end
  Dock.going = false
  Dock.focusAt = to
  menu_command(Dock.FOCUS_ENABLE, from, false)
  menu_command(Dock.FOCUS_ENABLE, to, true)
  menu_command(Dock.CURSOR_LOC, to, Dock.CURSOR, ti, instance_count(to))
  set_focus(to, ti)
  if from ~= to then
    unfocus(from, fi)
    Dock.ghost = {from, fi, GHOST_STEPS}
  end
end

-- Clears the ghost focus; runs every Step after a move_focus.
local function clear_ghost_focus()
  local g = Dock.ghost
  if g == nil then
    return
  end
  g[3] = g[3] - 1
  if g[3] <= 0 then
    Dock.ghost = nil
  end
  if not is_focus_active(g[1]) then
    unfocus(g[1], g[2])
  else
    Dock.ghost = nil                -- the focus came back to it: leave it alone
  end
end

local function card_from(dir, layer, idx, cone)
  if type(CalcMoveFocusLayerIdx) ~= "function" then
    return nil
  end
  local ok, ci = pcall(CalcMoveFocusLayerIdx, layer, idx, dir, cone or 37, 0, Dock.POS_BASE, Dock.CARDS, nil, Dock.POS_BASE)
  if not ok or ci == nil or ci == -1 then
    return nil
  end
  return ci
end

local function move_to_card(from, fi, ci, to)
  to = to or Dock.CARDS
  -- the green cursor leaves `from` for the card, as the retail OnFocusLayerShift does (else it stays on the kit)
  for i = 0, instance_count(from) - 1 do
    menu_command(Dock.CURSOR_TRACE, from, i, Dock.CURSOR, false)
  end
  menu_command(Dock.CURSOR_TRACE, to, ci, Dock.CARD_CURSOR, true)
  Dock.focusAt = to
  menu_command(Dock.FOCUS_ENABLE, from, false)
  menu_command(Dock.FOCUS_ENABLE, to, true)
  menu_command(Dock.CURSOR_LOC, to, Dock.CURSOR, ci, instance_count(to))
  if type(SetIsTeamDockTop) == "function" then
    pcall(SetIsTeamDockTop, false)
  end
  if type(UpdateChangeFocusLayer) == "function" then
    local fromCard = from == Dock.CARDS or from == Dock.LEADER
    pcall(UpdateChangeFocusLayer, to, fromCard and fi or ci, ci, fromCard and from or to)
  end
  if type(SetSelectCharaIdx) == "function" then
    pcall(SetSelectCharaIdx, ci)
  end
  local text = engine_command(Dock.TEXT_GET, Dock.CARD_GUIDE)
  if type(text) == "string" then
    set_guide_text(text)
  end
  menu_command(Dock.LAYER_VISIBLE, Dock.BALLOON, 0, false)
  if from ~= to then
    unfocus(from, fi)
    Dock.ghost = {from, fi, GHOST_STEPS}
  end
end

-- Moves down from the formation and keeps the focus.
local function formation_down(at, ai)
  local ci = card_from(2, Dock.FORM, 0)
  if ci ~= nil then
    log_move("focus " .. tostring(at) .. "[" .. tostring(ai) .. "] -> card " .. tostring(ci) .. " (formation box, down)")
    move_to_card(at, ai, ci)
    if at ~= Dock.FORM then
      unfocus(Dock.FORM, 0)
    end
  elseif at ~= Dock.FORM then
    move_focus(at, ai, Dock.FORM, 0)
  end
end

local function config_to_pitch(at, ai)
  at, ai = at or Dock.CONF, ai or 0
  local ci = card_from(4, Dock.CONF, 0)
  if ci ~= nil then
    move_to_card(at, ai, ci)
    if at ~= Dock.CONF then
      unfocus(Dock.CONF, 0)
    end
  elseif at ~= Dock.CONF then
    move_focus(at, ai, Dock.CONF, 0)   -- no card on the right: CONF. keeps the focus
  end
end

Dock.SYN_UPPER, Dock.SYN_LOWER = @crc:team00_17_synergy_attachment_button_flag@, @crc:team00_17_synergy_attachment_button_pillar@   -- team00_17_synergy_attachment_button_flag / _pillar
Dock.slot = {layer = nil, x = 0, y = 0, wait = 0, placed = false, n = 0, extra = {}, live = 0, still = 0}
local MOD_BUTTON_STILL_STEPS = 8

-- Returns the lower synergy button's global position and the global units per field unit (y, signed).
local function synergy_reference()
  local _, uy = global_position(Dock.SYN_UPPER, 0, Dock.POS_BASE)
  local lx, ly = global_position(Dock.SYN_LOWER, 0, Dock.POS_BASE)
  if uy == nil or lx == nil then
    return nil
  end
  local k = (ly - uy) / MOD_BUTTON_LAYOUT.step
  if math.abs(k) < 0.05 then
    return nil
  end
  return lx, ly, k
end

-- Returns the layer of the shown button.
local function mod_button_layer()
  if tactics_enabled() then
    return nil
  end
  local bu = rawget(_ENV, "BetterUI")
  local list = type(bu) == "table" and rawget(bu, "dock_buttons") or nil
  if type(list) ~= "table" then
    return nil
  end
  for _, e in ipairs(list) do
    if type(e) == "table" and type(e.layer) == "number" and is_open(e.layer, 0) then
      return e.layer, e
    end
  end
  return nil
end

-- the button's help line in the dock's guide line
local function mod_button_help(spec)
  if type(spec) == "table" and type(spec.help) == "number" then
    local text = engine_command(Dock.TEXT_GET, spec.help)
    if type(text) == "string" then
      set_guide_text(text)
    end
  end
end

-- (from, fi) -> the button, with its help line
local function move_to_mod_button(from, fi)
  local layer, spec = mod_button_layer()
  if layer == nil or not Dock.slot.placed or (Dock.locked() and Dock.LOCKED_LAYERS[layer]) then
    return false
  end
  move_focus(from, fi, layer, 0)
  mod_button_help(spec)
  return true
end

local function place_mod_button_extras(spec, bx, by, kbx, kby)
  local st = Dock.slot
  for _, ex in ipairs(type(spec) == "table" and type(spec.extra) == "table" and spec.extra or {}) do
    -- An extra layer need not report itself open.
    if type(ex) == "number" and global_position(ex, 0, Dock.POS_BASE) ~= nil then
      local e = st.extra[ex]
      if e == nil then
        e = {x = 0, y = 0, wait = 0, placed = false}
        st.extra[ex] = e
        menu_command(Dock.LAYER_VISIBLE, ex, 0, false)
      end
      if e.wait > 0 then
        e.wait = e.wait - 1
      else
        local ex_x, ex_y = global_position(ex, 0, Dock.POS_BASE)
        if ex_x ~= nil then
          local dx, dy = (bx - ex_x) / kbx, (by - ex_y) / kby
          if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
            if not e.placed then
              e.placed = true
              menu_command(Dock.LAYER_VISIBLE, ex, 0, true)
              log_info("dock button " .. tostring(st.layer) .. ": layer " .. tostring(ex) .. " placed on it")
            end
          else
            e.x, e.y = e.x + dx, e.y + dy
            menu_command(Dock.LAYER_POS, ex, e.x, e.y, 0, 0)
            e.wait = 2
          end
        end
      end
    end
  end
end

-- (re)start placing the button
local function arm_mod_button()
  local st = Dock.slot
  st.live, st.still = 1, 0
  for _, e in pairs(st.extra or {}) do
    e.wait = 0
  end
  if type(Dock.icons_arm) == "function" then
    Dock.icons_arm()
  end
end
Dock.slot_arm = arm_mod_button

local function place_mod_button()
  local layer, spec = mod_button_layer()
  local st = Dock.slot
  if layer == nil then
    return
  end
  if st.layer ~= layer then
    st.layer, st.x, st.y, st.wait, st.placed, st.n, st.extra, st.live, st.still = layer, 0, 0, 0, false, 0, {}, 1, 0
    menu_command(Dock.LAYER_VISIBLE, layer, 0, false)
  end
  -- Calls the spec's own tick (its selector while it is open).
  if type(spec.step) == "function" then
    local ok, err = pcall(spec.step, st.placed)
    if not ok and not st.stepErr then
      st.stepErr = true
      log_info("dock button " .. tostring(layer) .. " step error " .. tostring(err))
    end
  end
  if st.live <= 0 then
    return
  end
  if st.wait > 0 then
    st.wait = st.wait - 1
    return
  end
  if st.placed and st.kb ~= nil then
    local bx0, by0 = global_position(layer, 0, Dock.POS_BASE)
    if bx0 ~= nil then
      place_mod_button_extras(spec, bx0, by0, st.kb[1], st.kb[2])
    end
  end
  local lx, ly, k = synergy_reference()
  if lx == nil then
    return
  end
  local ms = type(spec.mesh) == "table" and spec.mesh or {node = MOD_BUTTON_LAYOUT.mesh, x = MOD_BUTTON_LAYOUT.mx, y = MOD_BUTTON_LAYOUT.my}
  local ce = type(spec.center) == "table" and spec.center or {x = 0, y = 0}
  local bx, by = global_position(layer, 0, Dock.POS_BASE)
  local mx, my = global_position(layer, 0, ms.node)
  if bx == nil or mx == nil then
    return
  end
  local kbx, kby = (mx - bx) / ms.x, (my - by) / ms.y     -- per button layer unit
  if math.abs(kbx) < 0.05 or math.abs(kby) < 0.05 then
    return
  end
  st.kb = {kbx, kby}
  local col = spec.column == "panel" and MOD_BUTTON_LAYOUT.pdx or MOD_BUTTON_LAYOUT.dx
  local tx, ty = lx + col * math.abs(k), ly + MOD_BUTTON_LAYOUT.dy * k
  local dx, dy = (tx - (bx + ce.x * kbx)) / kbx, (ty - (by + ce.y * kby)) / kby
  if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
    if not st.placed then
      st.placed = true
      menu_command(Dock.LAYER_VISIBLE, layer, 0, true)
      log_info(string.format("dock button %s placed at %.1f, %.1f", tostring(layer), st.x, st.y))
    end
    st.still = st.still + 1
    if st.still >= MOD_BUTTON_STILL_STEPS then
      st.live = 0                 -- the slide-in is over: placing stops until the next event
    end
    return
  end
  st.still = 0
  st.x, st.y = st.x + dx, st.y + dy
  menu_command(Dock.LAYER_POS, layer, st.x, st.y, 0, 0)
  st.wait = 2
  if st.n < 8 then
    st.n = st.n + 1
    log_info(string.format("dock button %s -> pos %.1f, %.1f (was %.1f, %.1f from its place)", tostring(layer), st.x, st.y,
      dx, dy))
  end
end

Dock.focusAt = nil

-- Returns whether the layer has a cursor but no focus mark.
local function is_unfocused(layer, idx)
  if Dock.focusAt == layer then
    return
  end
  menu_command(Dock.FOCUS_ENABLE, layer, false)
  play_anime(layer, idx, Dock.ANIME_FOCUS, 2)
  menu_command(Dock.CURSOR_TRACE, layer, idx, Dock.CURSOR, false)
  menu_command(Dock.FOCUS_MARK, layer, idx, false)
end

Dock.ICON = @crc:vrfw_team_icon@              -- vrfw_team_icon
Dock.ICON_MAX = 3                  -- vrfw_team_icon instances
Dock.ICON_JOINTS = {
  {@crc:_atc_vrfw_icon01@, -271.8, -292.6},
  {@crc:_atc_vrfw_icon02@, -139.0, -292.6},
  {@crc:_atc_vrfw_icon03@, -6.2, -292.6},
}

-- the pitch frame layer the icons hang from (the frame of this dock that has their joints), nil = none
function Dock.icon_frame()
  local I = Dock.read_icons()
  if I.frame == nil then
    I.frame = false
    for _, frame in ipairs(Dock.FRAMES) do
      if global_position(frame, 0, Dock.ICON_JOINTS[1][1]) ~= nil then
        I.frame = frame
        break
      end
    end
    log_info("icons hang from " .. (I.frame and ("frame " .. tostring(I.frame)) or "no frame joint: layer moves"))
  end
  return I.frame or nil
end

function Dock.read_icons()
  if Dock.icons == nil then
    local f = foreign_editor_spec()
    local n = type(f) == "table" and type(f.icons) == "table" and #f.icons or 0
    Dock.icons = {n = tactics_enabled() and 0 or math.min(n, Dock.ICON_MAX), hide = type(f) == "table" and f.hide_list == true,
      live = 1, still = 0, wait = 0, placed = false, spare = false, st = {}}
    if n > 0 or Dock.icons.hide then
      log_info("icons: " .. Dock.icons.n .. ", list hidden " .. tostring(Dock.icons.hide))
    end
  end
  return Dock.icons
end

function Dock.icons_shown()
  local I = Dock.read_icons()
  return I.n > 0 and I.placed
end

function Dock.icon_help(i)
  local f = type(VRFW.team_editor) == "table" and VRFW.team_editor.icon_help or nil
  if type(f) ~= "function" then
    return
  end
  local ok, text = pcall(f, i)
  if ok and type(text) == "string" then
    set_guide_text(text)
  end
end

function Dock.to_icon(from, fi, i)
  local I = Dock.read_icons()
  if not Dock.icons_shown() then
    return false
  end
  i = math.max(0, math.min(i or 0, I.n - 1))
  if from == Dock.ICON and fi ~= i then
    unfocus(Dock.ICON, fi)
  end
  move_focus(from, fi, Dock.ICON, i)
  Dock.icon_help(i)
  return true
end

-- Handles the focus landing on the hidden list.
function Dock.off_list(at, ai, from, fi)
  if Dock.to_icon(at, ai, 0) then
    return
  end
  if from ~= nil and from ~= at then
    move_focus(at, ai, from, fi or 0)
  end
end

-- Places the icons; runs every Step while armed.
function Dock.icons_place()
  local I = Dock.read_icons()
  if not I.spare and is_open(Dock.ICON, 0) then
    I.spare = true
    for i = I.n, instance_count(Dock.ICON) - 1 do
      menu_command(Dock.LAYER_VISIBLE, Dock.ICON, i, false)
      menu_command(Dock.ZONE, Dock.ICON, i, false)
    end
  end
  if I.n == 0 or I.live <= 0 then
    return
  end
  local lx, ly, k = synergy_reference()
  if lx == nil then
    return
  end
  local all = true
  for i = 0, I.n - 1 do
    local s = I.st[i]
    if s == nil and is_open(Dock.ICON, i) then
      local j = Dock.ICON_JOINTS[i + 1]
      s = {x = j and j[2] or 0, y = j and j[3] or 0, joint = j and Dock.icon_frame() and j[1] or nil, wait = 1,
        placed = false}
      I.st[i] = s
      menu_command(Dock.LAYER_VISIBLE, Dock.ICON, i, false)
      menu_command(Dock.LAYER_SCALE, Dock.ICON, TEAM_ICON_LAYOUT.scale, TEAM_ICON_LAYOUT.scale, 1, i)
    end
    if s == nil then
      all = false
    elseif s.wait > 0 then
      s.wait = s.wait - 1
      all = false
    else
      local bx, by = global_position(Dock.ICON, i, Dock.POS_BASE)
      local mx, my = global_position(Dock.ICON, i, MOD_BUTTON_LAYOUT.mesh)
      local kbx = bx ~= nil and mx ~= nil and (mx - bx) / MOD_BUTTON_LAYOUT.mx or 0   -- global units per layer unit (scaled)
      local kby = bx ~= nil and mx ~= nil and (my - by) / MOD_BUTTON_LAYOUT.my or 0
      if math.abs(kbx) < 0.05 or math.abs(kby) < 0.05 then
        all = false
      else
        local tx = lx + (TEAM_ICON_LAYOUT.pdx + (i - (I.n - 1) / 2) * TEAM_ICON_LAYOUT.step) * math.abs(k)
        local ty = ly + TEAM_ICON_LAYOUT.dy * k
        local dx, dy = (tx - bx) / kbx * TEAM_ICON_LAYOUT.scale, (ty - by) / kby * TEAM_ICON_LAYOUT.scale
        if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
          if not s.placed then
            s.placed = true
            menu_command(Dock.LAYER_VISIBLE, Dock.ICON, i, true)
          end
        elseif s.joint ~= nil then
          s.x, s.y, s.wait = s.x + (tx - bx) / math.abs(k), s.y + (ty - by) / k, 2
          menu_command(Dock.NODE_POS, Dock.icon_frame(), 0, s.joint, 0, s.x)
          menu_command(Dock.NODE_POS, Dock.icon_frame(), 0, s.joint, 1, s.y)
          all = false
        else
          s.x, s.y, s.wait = s.x + dx, s.y + dy, 2
          menu_command(Dock.LAYER_POS, Dock.ICON, s.x, s.y, 0, i)
          all = false
        end
      end
    end
  end
  if not all then
    I.still = 0
    return
  end
  I.still = I.still + 1
  if I.still >= MOD_BUTTON_STILL_STEPS then
    I.live = 0
  end
  if not I.placed then
    I.placed = true
    log_info(string.format("icons placed (%d), list hidden %s", I.n, tostring(I.hide)))
    if I.hide and is_focus_active(Dock.LIST) then
      Dock.to_icon(Dock.LIST, focused_index(Dock.LIST), 0)
    end
  end
end

-- Arms the icons on the events that move the field.
function Dock.icons_arm()
  local I = Dock.icons
  if I ~= nil then
    I.live, I.still = 1, 0
    for _, s in pairs(I.st) do
      s.wait = 0
    end
  end
end

-- Switches a zone on or off; runs every Step.
function Dock.zone(layer, off, why)
  if (Dock.zoneOff[layer] == true) == off then
    return
  end
  Dock.zoneOff[layer] = off
  menu_command(Dock.ZONE, layer, 0, not off)
  if Dock.zoneLogs < 24 then
    Dock.zoneLogs = Dock.zoneLogs + 1
    log_info("pointer zone of " .. tostring(layer) .. (off and " off" or " on") .. " (" .. why .. ")")
  end
end

function Dock.header_zones()
  if Dock.locked() then
    for layer in pairs(Dock.LOCKED_LAYERS) do
      if is_live(layer) then
        Dock.zone(layer, true, "the team's identity is fixed")
      end
    end
    return
  end
  Dock.zoneTick = (Dock.zoneTick or 0) + 1
  if Dock.zoneTick >= 30 then
    Dock.zoneTick = 0
    for layer, off in pairs(Dock.zoneOff) do
      if off and is_live(layer) then
        menu_command(Dock.ZONE, layer, 0, false)
      end
    end
  end
  if is_live(Dock.BAR) then
    local hdr = panel_enabled() and Dock.hdr == "header"
    Dock.zone(Dock.BAR, not hdr, hdr and "crest drawn on its zone" or "crest not drawn on its zone")
  end
  if not panel_enabled() or Dock.hdr ~= "header" then
    return
  end
  local x, y = pointer_position()
  if x == nil then
    return
  end
  local k = Dock.kitc
  local onKit = k ~= nil and math.abs(x - k[1]) <= k[3] and math.abs(-y - k[2]) <= k[4]
  if is_live(Dock.NAME) then
    local right = Dock.nameR ~= nil and x > Dock.nameR
    Dock.zone(Dock.NAME, onKit or right, string.format("pointer %.0f,%.0f, plate right edge %s", x, y,
      Dock.nameR ~= nil and string.format("%.0f", Dock.nameR) or "?"))
  end
  if k ~= nil and is_live(Dock.UNI) then
    Dock.zone(Dock.UNI, not onKit, string.format("pointer %.0f,%.0f, kit %.0f,%.0f +-%.0f,%.0f", x, y, k[1], k[2], k[3],
      k[4]))
  end
end

-- Logs the header focus; runs every Step in header mode.
Dock.HDR_ITEMS = {{"crest", Dock.BAR}, {"team name", Dock.NAME}, {"kit", Dock.UNI}, {"player plate", Dock.DECK}}
function Dock.header_focus_log()
  if Dock.hdr ~= "header" or Dock.hfocusLogs >= 60 then
    return
  end
  local cur = "other"
  for _, it in ipairs(Dock.HDR_ITEMS) do
    if is_open(it[2], 0) and is_focus_active(it[2]) then
      cur = it[1]
    end
  end
  if cur == Dock.hfocus then
    return
  end
  local prev = Dock.hfocus
  Dock.hfocus = cur
  if prev == nil and cur == "other" then
    return
  end
  Dock.hfocusLogs = Dock.hfocusLogs + 1
  local x, y = pointer_position()
  log_debug(string.format("header focus %s -> %s (pointer %s)", tostring(prev), cur,
    x ~= nil and string.format("%.0f,%.0f", x, y) or "?"))
end

-- Node of the free text.
Dock.FREE_NODE = @crc:_pos_atc_free01@
Dock.boxOff = {}
Dock.boxLogs = 0
function Dock.drawn(layer, rows)
  local base, ref = rows[1], nil
  for _, r in ipairs(rows) do
    if r[1] == Dock.FREE_NODE then
      ref = r
    end
  end
  if ref == nil or ref[2] == base[2] or ref[3] == base[3] or not is_open(layer, 0) then
    return nil
  end
  local gx, gy = global_position(layer, 0, base[1])
  local fx, fy = global_position(layer, 0, ref[1])
  if gx == nil or fx == nil then
    return nil
  end
  local kx, ky = (fx - gx) / (ref[2] - base[2]), (fy - gy) / (ref[3] - base[3])
  if math.abs(kx) < 0.05 or math.abs(ky) < 0.05 then
    return nil
  end
  local x1, y1 = gx + base[4] * kx, gy - base[5] * ky
  return {math.min(gx, x1), math.max(gx, x1), math.min(gy, y1), math.max(gy, y1)}
end

-- Tests the pointer against the two drawn boxes.
function Dock.pointer_boxes()
  local x, y = pointer_position()
  if x == nil then
    return nil
  end
  local f, c = Dock.drawn(Dock.FORM, FORMATION_BOX_LAYOUT), Dock.drawn(Dock.CONF, TEAM_CONFIG_LAYOUT)
  if f == nil or c == nil then
    return nil
  end
  local function inside(b)
    return x >= b[1] and x <= b[2] and -y >= b[3] and -y <= b[4]
  end
  return inside(f), inside(c), x, y
end

-- Guards the boxes; runs every Step.
function Dock.box_guard()
  if not panel_enabled() or menu_query(Dock.LAYER_ACTIVE, Dock.FORM) == false then
    return                        -- a child menu is up / the dock is moving: the retail owns the zones
  end
  local off = {}
  if is_config_shown() then
    local inF, inC, x, y = Dock.pointer_boxes()
    if inF ~= nil then
      off[Dock.FORM] = not inF
      off[Dock.CONF] = not inC
      Dock.boxPointer = {x, y}
    end
  end
  for _, layer in ipairs({Dock.FORM, Dock.CONF}) do
    local o, was = off[layer] == true, Dock.boxOff[layer] == true
    if o or was then              -- never touches a zone this guard did not switch off
      if was ~= o and Dock.boxLogs < 40 then
        Dock.boxLogs = Dock.boxLogs + 1
        local p = Dock.boxPointer
        log_debug("pointer box guard: zone of " .. tostring(layer) .. (o and " off" or " on")
          .. (p and string.format(" (pointer %.0f,%.0f)", p[1], p[2]) or ""))
      end
      Dock.boxOff[layer] = o
      menu_command(Dock.ZONE, layer, 0, not o)
    end
  end
end

function Dock.pointer_on_box(layer)
  local inF, inC = Dock.pointer_boxes()
  if layer == Dock.FORM then
    return inF == true
  end
  return inC == true
end

local function wrap_global(name, make)
  local prev = rawget(_ENV, name)
  if type(prev) == "function" then
    rawset(_ENV, name, make(prev))
  end
end

-- runs `after` (errors logged) after the global function `name`, keeping its results
local function run_after_global(name, after)
  wrap_global(name, function(prev)
    return function(...)
      local r = pack_args(prev(...))
      local ok, err = pcall(after, ...)
      if not ok then
        log_info("error " .. name .. " " .. tostring(err))
      end
      return table.unpack(r, 1, r.n)
    end
  end)
end

run_after_global("OnSetupLayer", function(a1, a2)
  apply_layer(a1, a2)
end)
run_after_global("OnOpenLayer", function(a1, a2)
  apply_layer(a1, a2)
  local idx = a2 or 0
  if a1 ~= nil and a1 == mod_button_layer() then
    is_unfocused(a1, idx)
  end
  if a1 == Dock.ICON then
    is_unfocused(a1, idx)
    local I = Dock.read_icons()
    local s = I.st[idx]
    if idx >= I.n or s == nil or not s.placed then
      menu_command(Dock.LAYER_VISIBLE, a1, idx, false)   -- hidden until placed; an unused one stays hidden
    end
    if idx >= I.n then
      menu_command(Dock.ZONE, a1, idx, false)
    end
  end
  if a1 == Dock.slot.layer or a1 == Dock.ICON or a1 == Dock.FRAMES[1] or a1 == Dock.FRAMES[2] or a1 == Dock.SYN_LOWER then
    Dock.slot_arm()
  end
end)
-- The team switch and the dock coming back from a child menu move the field.
run_after_global("UpdateTeamDockNo", function()
  Dock.slot_arm()
end)
run_after_global("ResumeTeamDock", function()
  Dock.slot_arm()
end)
-- the retail sets the tactic's name and plate per instance (setup, open, every refresh)
run_after_global("SetupTacticsLayer", function(a1, a2)
  if a1 == Dock.CMD then
    apply_layer(Dock.CMD, a2)
  end
end)
-- the INCLUDE shows the team config's name again on every refresh
run_after_global("UpdateTeamBuildTypeInfo", function(a1, a2, a3)
  if panel_enabled() and (a3 == nil or a3 == Dock.CONF) then
    hide_config_text()
  end
end)
-- Corrects the kit sprites because retail shows both of them on every refresh.
run_after_global("SetupUniformIcom", function(a1, a2)
  if panel_enabled() and Dock.hdr == "header" and (a1 == nil or a1 == Dock.UNI) then
    menu_command(Dock.MESH_VIS, Dock.UNI, Dock.KIT_SHADOW, false, a2 or 0)
  end
end)
run_after_global("SetupTeamDockTeamNameBar", function()
  apply_layer(Dock.BAR, 0)
end)

Dock.PAD_DIRS = {"up", "down", "left", "right"}   -- the retail direction numbers 1..4
Dock.PAD_MAP = {
  list = {right = {"crest_from_cell", "coach", "tactic_top", "card"}},
  coach = {left = {"list"}, right = {"flag", "pillar", "card"}, up = {"crest", "name"},
    down = {"tactic_top", "icon_first", "slot", "formation"}},
  flag = {left = {"coach", "list"}, right = {"card"}, up = {"name", "crest"},
    down = {"pillar", "tactic_top", "icon_first", "slot", "formation"}},
  pillar = {left = {"coach", "list"}, right = {"card"}, up = {"flag", "name", "crest"},
    down = {"tactic_top", "icon_first", "slot", "formation"}},
  tactic = {left = {"tactic_left", "list"}, right = {"tactic_right", "card"},
    up = {"tactic_above", "coach", "flag"}, down = {"tactic_below", "icon_first", "slot", "formation"}},
  icon = {left = {"icon_before", "list"}, right = {"icon_after", "card"}, up = {"tactic_bottom", "coach"},
    down = {"slot", "formation"}},
  slot = {left = {"list"}, right = {"card"}, up = {"icon_first", "tactic_bottom", "coach"}, down = {"formation"}},
  formation = {left = {"list"}, right = {"team_settings", "card"},
    up = {"slot", "icon_first", "tactic_bottom", "coach"}, down = {"kit_panel", "card"}},
  team_settings = {left = {"formation"}, right = {"card"},
    up = {"slot", "icon_last", "tactic_bottom", "coach"}, down = {"kit_panel"}},
  kit_panel = {left = {"team_settings", "formation"}, right = {"card"}, up = {"formation"}},
  crest = {left = {"list"}, right = {"name"}, down = {"coach", "tactic_top", "formation"}},
  name = {left = {"crest", "list"}, right = {"kit", "player_plate"}, down = {"card", "flag", "coach"}},
  kit = {left = {"name", "crest"}, right = {"player_plate"}, down = {"card", "flag", "coach"}},
  player_plate = {left = {"kit", "name"}, down = {"card"}},
  card = {
    left = {nearest = "y", among = {"flag", "pillar", "coach", "tactic_top", "tactic_middle", "tactic_bottom",
      "icon_first", "icon_last", "slot", "team_settings", "formation", "kit_panel"}},
    up = {nearest = "x", among = {"crest", "name", "kit", "player_plate"}},
  },
}

-- Pad targets of vrfw_team_icon_* (team_icons.toml).
Dock.PAD_FN = {
  [@crc:betterui_dock_pad_up@] = 1, [@crc:betterui_dock_pad_down@] = 2, [@crc:betterui_dock_pad_left@] = 3, [@crc:betterui_dock_pad_right@] = 4,
  [@crc:betterui_dock_button_up@] = 1, [885050662] = 2, [1381546613] = 3, [3622053520] = 4,
  [3213729062] = 1, [957527670] = 2, [@crc:vrfw_team_icon_left@] = 3, [3162678559] = 4,
}
-- OnChangeFocus arguments of the cards' and the coach card's retail direction rows
Dock.PAD_CARD_ARG = {[3483715641] = 1, [49409691] = 2, [1684642248] = 3, [1644353666] = 4}
-- the layers that are one element
Dock.PAD_ELEMENT = {[Dock.TAC] = "tactic", [Dock.FORM] = "formation", [Dock.CONF] = "team_settings", [Dock.BAR] = "crest",
  [Dock.NAME] = "name", [Dock.DECK] = "player_plate", [Dock.SYN_UPPER] = "flag", [Dock.SYN_LOWER] = "pillar",
  [Dock.ICON] = "icon", [Dock.LIST] = "list", [Dock.LEADER] = "coach", [Dock.CARDS] = "card"}

function Dock.pad_element(layer)
  if layer == Dock.UNI then
    return Dock.hdr == "header" and "kit" or "kit_panel"
  end
  if layer == mod_button_layer() then
    return "slot"
  end
  return Dock.PAD_ELEMENT[layer]
end

function Dock.pad_shown(layer, idx)
  if not is_open(layer, idx) or menu_query(Dock.IS_VISIBLE, layer, idx) == false then
    return false
  end
  return not (Dock.locked() and Dock.LOCKED_LAYERS[layer])
end

-- Returns the layer drawn for this card instance.
function Dock.pad_card_layer(layer, idx)
  if layer ~= Dock.CARDS and layer ~= Dock.LEADER then
    return layer
  end
  if Dock.pad_shown(layer, idx) or type(GetBlankCardName) ~= "function" then
    return layer
  end
  return GetBlankCardName(layer)
end

function Dock.pad_row_beside(i, dir)
  if type(CalcMoveFocusLayerIdx) ~= "function" then
    return nil
  end
  local ok, j = pcall(CalcMoveFocusLayerIdx, Dock.LIST, i, dir, 5, instance_count(Dock.LIST), Dock.POS_BASE)
  if ok and type(j) == "number" and j ~= -1 then
    return j
  end
  return nil
end

function Dock.pad_one(layer, idx)
  if Dock.pad_shown(layer, idx) then
    return layer, idx
  end
  return nil
end

-- Handles a tactic row of the column.
function Dock.pad_tactic(idx)
  if tactics_enabled() or idx < 0 or idx > 2 then
    return nil
  end
  return Dock.pad_one(Dock.TAC, idx)
end

function Dock.pad_tactic_box(idx)
  if not tactics_enabled() or idx < 0 or idx > 2 then
    return nil
  end
  return Dock.pad_one(Dock.TAC, idx)
end

function Dock.pad_icon(idx)
  if not Dock.icons_shown() or idx < 0 or idx >= Dock.read_icons().n then
    return nil
  end
  return Dock.ICON, idx
end

-- Maps a target name to a function (from layer, from instance, direction) that returns layer and instance.
Dock.PAD_TARGET = {
  list = function(from)
    if Dock.read_icons().hide then
      return nil
    end
    if from == Dock.BAR then
      for i = instance_count(Dock.LIST) - 1, 0, -1 do
        if Dock.pad_shown(Dock.LIST, i) and Dock.pad_row_beside(i, 3) ~= nil then
          return Dock.LIST, i
        end
      end
    end
    return Dock.pad_one(Dock.LIST, Dock.listRow or focused_index(Dock.LIST))
  end,
  crest_from_cell = function(from, fi)
    if from == Dock.LIST and Dock.pad_row_beside(fi, 3) ~= nil then
      return Dock.pad_one(Dock.BAR, 0)
    end
    return nil
  end,
  coach = function()
    local drawn = Dock.pad_card_layer(Dock.LEADER, 0)
    if drawn ~= 0 and Dock.pad_shown(drawn, 0) then
      return Dock.LEADER, 0
    end
    return nil
  end,
  flag = function() return Dock.pad_one(Dock.SYN_UPPER, 0) end,
  pillar = function() return Dock.pad_one(Dock.SYN_LOWER, 0) end,
  tactic_top = function() return Dock.pad_tactic(2) end,
  tactic_middle = function() return Dock.pad_tactic(1) end,
  tactic_bottom = function() return Dock.pad_tactic(0) end,
  tactic_above = function(_, fi) return Dock.pad_tactic(fi + 1) end,
  tactic_below = function(_, fi) return Dock.pad_tactic(fi - 1) end,
  tactic_left = function(_, fi) return Dock.pad_tactic_box(fi + 1) end,
  tactic_right = function(_, fi) return Dock.pad_tactic_box(fi - 1) end,
  slot = function()
    local layer = mod_button_layer()
    if layer ~= nil and Dock.slot.placed then
      return Dock.pad_one(layer, 0)
    end
    return nil
  end,
  icon_first = function() return Dock.pad_icon(0) end,
  icon_last = function() return Dock.pad_icon(Dock.read_icons().n - 1) end,
  icon_before = function(_, fi) return Dock.pad_icon(fi - 1) end,
  icon_after = function(_, fi) return Dock.pad_icon(fi + 1) end,
  formation = function() return Dock.pad_one(Dock.FORM, 0) end,
  team_settings = function()
    if is_config_shown() then
      return Dock.pad_one(Dock.CONF, 0)
    end
    return nil
  end,
  kit = function()
    if Dock.hdr == "header" then
      return Dock.pad_one(Dock.UNI, 0)
    end
    return nil
  end,
  kit_panel = function()
    if Dock.hdr ~= "header" then
      return Dock.pad_one(Dock.UNI, 0)
    end
    return nil
  end,
  crest = function() return Dock.pad_one(Dock.BAR, 0) end,
  name = function() return Dock.pad_one(Dock.NAME, 0) end,
  player_plate = function() return Dock.pad_one(Dock.DECK, 0) end,
  card = function(from, fi, dir)
    -- a wider cone for what has no card straight ahead (the header row over the pitch)
    local ci = card_from(dir, from, fi) or card_from(dir, from, fi, 60) or card_from(dir, from, fi, 80)
    if ci ~= nil then
      return Dock.CARDS, ci
    end
    return nil
  end,
}

-- Returns the available target of `among` closest to the card.
function Dock.pad_nearest(from, fi, spec)
  local fx, fy = global_position(Dock.pad_card_layer(from, fi), fi, Dock.POS_BASE)
  if fx == nil then
    return nil
  end
  local bestLayer, bestIdx, bestScore = nil, nil, nil
  for _, name in ipairs(spec.among) do
    local layer, idx = Dock.PAD_TARGET[name](from, fi)
    local x, y = nil, nil
    if layer ~= nil then
      x, y = global_position(Dock.pad_card_layer(layer, idx), idx, Dock.POS_BASE)
    end
    if x ~= nil then
      local score = nil
      if spec.nearest == "x" then
        score = math.abs(x - fx)
      elseif x < fx then
        score = math.abs(y - fy) + (fx - x) / 4
      end
      if score ~= nil and (bestScore == nil or score < bestScore) then
        bestLayer, bestIdx, bestScore = layer, idx, score
      end
    end
  end
  return bestLayer, bestIdx
end

-- moves the focus with the one function that fits the target's kind
function Dock.pad_move(from, fi, to, ti)
  if to == Dock.CARDS or to == Dock.LEADER then
    move_to_card(from, fi, ti, to)
  elseif to == Dock.TAC and from == Dock.TAC then
    step_tactics_focus(fi, ti)
  elseif to == Dock.ICON then
    Dock.to_icon(from, fi, ti)
  elseif to == mod_button_layer() then
    move_to_mod_button(from, fi)
  else
    move_focus(from, fi, to, ti)
    if to == Dock.LIST then
      play_anime(to, ti, Dock.ANIME_FOCUS, 0)
    end
  end
end

-- Computes one pad step from (layer, idx).
function Dock.pad(layer, idx, dir)
  local element = Dock.pad_element(layer)
  local entry = element and Dock.PAD_MAP[element]
  local targets = entry and entry[Dock.PAD_DIRS[dir]]
  if targets == nil then
    return false
  end
  local to, ti = nil, nil
  if targets.nearest ~= nil then
    to, ti = Dock.pad_nearest(layer, idx, targets)
  else
    for _, name in ipairs(targets) do
      to, ti = Dock.PAD_TARGET[name](layer, idx, dir)
      if to ~= nil then
        break
      end
    end
  end
  if to == nil then
    return false
  end
  Dock.pad_move(layer, idx, to, ti)
  engine_command(Dock.SOUND, Dock.SE_MOVE)
  return true
end

-- Returns whether a card has a card to go to in that direction.
function Dock.pad_card_ahead(idx, dir)
  if type(CalcMoveFocusLayerIdx) ~= "function" or type(CalcMoveFocusLayerByCircleCollision) ~= "function" then
    return true
  end
  local ok, near = pcall(CalcMoveFocusLayerIdx, Dock.CARDS, idx, dir, 37, instance_count(Dock.CARDS), Dock.POS_BASE, nil, nil,
    Dock.POS_BASE)
  if not ok or near == -1 then
    return not ok
  end
  local okCircle, hit = pcall(CalcMoveFocusLayerByCircleCollision, Dock.CARDS, idx, dir, nil, Dock.POS_BASE, Dock.LEADER)
  return not okCircle or hit ~= -1
end

-- Handles the retail direction rows that reach OnChangeFocus.
function Dock.pad_from_change(layer, arg)
  local dir = nil
  if layer == Dock.LEADER or layer == Dock.CARDS then
    dir = Dock.PAD_CARD_ARG[arg]
  elseif layer == Dock.LIST and arg == Dock.ARG_RIGHT then
    dir = 4
  end
  if dir == nil or not is_focus_active(layer) then
    return false
  end
  local idx = focused_index(layer)
  if layer == Dock.LIST and Dock.pad_row_beside(idx, 4) ~= nil then
    return false                  -- Partido -> Pachanga: Friendlies' own step
  end
  if layer == Dock.CARDS then
    if type(IsChangeMemberMode) == "function" and IsChangeMemberMode() == true then
      return false
    end
    if Dock.pad_card_ahead(idx, dir) then
      return false
    end
  end
  Dock.pad(layer, idx, dir)
  return true
end

-- Handles a direction row of CMD_FUNCTION.
function Dock.pad_from_row(dir)
  local slot = mod_button_layer()
  if slot ~= nil and is_focus_active(slot) then
    Dock.pad(slot, 0, dir)
    return
  end
  if is_focus_active(Dock.UNI) then
    Dock.pad(Dock.UNI, 0, dir)
    return
  end
  for layer in pairs(Dock.PAD_ELEMENT) do
    if layer ~= Dock.LIST and layer ~= Dock.CARDS and layer ~= Dock.LEADER and is_focus_active(layer) then
      Dock.pad(layer, focused_index(layer), dir)
      return
    end
  end
end

wrap_global("OnChangeFocus", function(prev)
  return function(a1, a2, ...)
    if a1 == Dock.ICON and not Dock.busy then
      local r = pack_args(prev(a1, a2, ...))
      Dock.icon_help(focused_index(Dock.ICON))
      return table.unpack(r, 1, r.n)
    end
    if Dock.busy then
      Dock.echo = true
    elseif Dock.pad_from_change(a1, a2) then
      return
    end
    local r = pack_args(prev(a1, a2, ...))
    if a1 == Dock.LIST and is_focus_active(Dock.LIST) then
      Dock.listRow = focused_index(Dock.LIST)
    end
    return table.unpack(r, 1, r.n)
  end
end)

wrap_global("OnFunction", function(prev)
  return function(a1, ...)
    local dir = Dock.PAD_FN[a1]
    if dir ~= nil then
      Dock.pad_from_row(dir)
      return
    end
    local r = pack_args(prev(a1, ...))
    -- Back from a card gives the retail focus to the list (BackToTeamDockListItem)
    if Dock.read_icons().hide and is_focus_active(Dock.LIST) then
      Dock.off_list(Dock.LIST, focused_index(Dock.LIST))
    end
    return table.unpack(r, 1, r.n)
  end
end)

local function set_header_mode(mode, why)
  Dock.hdr = mode
  log_info("header " .. mode .. " (" .. why .. ")")
  for _, L in ipairs({Dock.BAR, Dock.NAME, Dock.UNI}) do
    if is_open(L, 0) then
      apply_header(L, mode)
    end
  end
  for _, frame in ipairs(Dock.FRAMES) do
    if is_open(frame, 0) then
      local k = mode == "header" and kit_locator(frame) or place_kit_under_panel(frame)
      set_kit_locator(frame, k)
    end
  end
end

-- A plate is there once its layer is open and not hidden.
local PLATE_WAIT_STEPS = 120
local function plate_open(layer)
  local open = is_open(layer, 0)
  local vis = open and menu_query(Dock.IS_VISIBLE, layer, 0) ~= false
  return open and vis, open
end

local function decide_header_mode()
  if Dock.hdr ~= nil or not is_open(Dock.BAR, 0) or not is_open(Dock.UNI, 0) then
    return
  end
  if rawget(_ENV, "g_parentMenuId") == Dock.VR_MENU then
    set_header_mode("panel", "opened from the Victory Road")
    return
  end
  if Dock.headerOff == nil then
    local f = foreign_editor_spec()
    Dock.headerOff = type(f) == "table" and f.header == false
  end
  if Dock.headerOff then
    set_header_mode("panel", "the team editor's host hides the team name bar")
    return
  end
  local name, nameOpen = plate_open(Dock.NAME)
  local deck, deckOpen = plate_open(Dock.DECK)
  if name and deck then
    set_header_mode("header", "crest | team name | kit | player plate | Nv., after " .. Dock.wait .. " Step(s)")
    Dock.check = 30
    return
  end
  Dock.wait = Dock.wait + 1
  if Dock.wait < PLATE_WAIT_STEPS then
    return
  end
  if not name then
    set_header_mode("panel", "no team name plate after " .. Dock.wait .. " Steps (open " .. tostring(nameOpen) .. ")")
  else
    set_header_mode("panel", "no player plate after " .. Dock.wait .. " Steps (open " .. tostring(deckOpen) .. ")")
  end
end

-- Checks the placed team name and player plates (global units, the bar's measured scale) and logs once 30 Steps after.
local function check_header()
  if Dock.check <= 0 or Dock.hdr ~= "header" then
    return
  end
  Dock.check = Dock.check - 1
  if Dock.check > 0 then
    return
  end
  local bx, by = global_position(Dock.BAR, 0, Dock.POS_BASE)
  local ex = global_position(Dock.BAR, 0, HEADER_LAYOUT.crest)
  local nx = global_position(Dock.NAME, 0, Dock.NAME_BASE)
  local dx = global_position(Dock.DECK, 0, Dock.DECK_BASE)
  if bx == nil or ex == nil or nx == nil or dx == nil then
    return
  end
  local k = (ex - bx) / HEADER_CREST_CORNER[1]
  if math.abs(k) < 0.05 then
    return
  end
  local en, ed = (nx - bx) / k, (dx - bx) / k
  log_info(string.format("header measured: team name %.0f / player plate %.0f (layout %.0f / %.0f)",
    en, ed, HEADER_CHECK.name_l, HEADER_CHECK.deck_l))
end

-- Redirects a pointer's group switch that this layout re-routes.
local function redirect_focus_shift(sh)
  local f, fi, t, ti = sh[1], sh[2], sh[3], sh[4]
  if not is_focus_active(t) then
    return
  end
  -- Hides the list (VRFW.team_editor spec.hide_list).
  if t == Dock.LIST and Dock.read_icons().hide then
    Dock.off_list(t, ti, f, fi)
    return
  end
  local hdr = Dock.hdr == "header"
  if hdr and f == Dock.NAME and t == Dock.DECK and is_open(Dock.UNI, 0) then
    move_focus(t, ti, Dock.UNI, 0)                 -- team name RIGHT -> kit
  elseif hdr and f == Dock.DECK and t == Dock.NAME and is_open(Dock.UNI, 0) then
    move_focus(t, ti, Dock.UNI, 0)                 -- player plate LEFT -> kit
  elseif hdr and f == Dock.UNI and t == Dock.FORM then
    move_focus(t, ti, Dock.UNI, 0)                 -- kit UP: nothing above it in the header
  elseif hdr and f == Dock.UNI and t == Dock.CONF and is_open(Dock.NAME, 0) then
    move_focus(t, ti, Dock.NAME, 0)                -- kit LEFT -> team name
  elseif f == Dock.FORM and t == Dock.TAC and tactics_enabled() and is_open(Dock.TAC, 2) then
    move_focus(t, ti, Dock.TAC, 2)
  elseif f == Dock.FORM and t == Dock.CONF then
    if hdr then
      formation_down(t, ti)
    elseif is_open(Dock.UNI, 0) then
      move_focus(t, ti, Dock.UNI, 0)               -- panel mode: the kit under the panel
    end
  elseif f == Dock.CONF and t == Dock.FORM and is_open(Dock.TAC, 0) then
    move_focus(t, ti, Dock.TAC, 0)                 -- CONF. UP -> right tactic box
  elseif f == Dock.CONF and t == Dock.UNI then
    config_to_pitch(t, ti)                    -- CONF. RIGHT -> the pitch
  elseif f == Dock.TAC and t == Dock.FORM and fi == 0 and tactics_enabled() and is_config_shown() then
    move_focus(t, ti, Dock.CONF, 0)                -- right tactic box DOWN -> CONF.
  end
end

wrap_global("OnFocusLayerShift", function(prev)
  return function(a1, a2, a3, a4, ...)
    local r = pack_args(prev(a1, a2, a3, a4, ...))
    Dock.focusAt = a3
    if not Dock.going and panel_enabled() then
      local sh = {a1, a2, a3, a4}
      log_move("shift " .. tostring(a1) .. "[" .. tostring(a2) .. "] -> " .. tostring(a3) .. "[" .. tostring(a4) .. "]")
      if a3 == mod_button_layer() then
        Dock.shift = nil           -- onto the dock button (the pointer): kept, with its help line
        mod_button_help(select(2, mod_button_layer()))
      elseif a3 == Dock.ICON then
        Dock.shift = nil           -- onto an icon button (the pointer): kept, with its help line
        Dock.icon_help(a4)
      elseif (a1 == Dock.FORM or a1 == Dock.CONF) and (a3 == Dock.FORM or a3 == Dock.CONF) and Dock.pointer_on_box(a3) then
        Dock.shift = nil
      else
        Dock.shift = sh
      end
      Dock.lock_guard(a1, a2)
    end
    return table.unpack(r, 1, r.n)
  end
end)

-- Guards the focus landing on a fixed identity item (a key, the pointer or a redirect).
function Dock.lock_guard(from, fi)
  local at = Dock.focusAt
  if not Dock.locked() or at == nil or not Dock.LOCKED_LAYERS[at] or Dock.LOCKED_LAYERS[from] then
    return
  end
  Dock.shift = nil
  move_focus(at, 0, from, fi or 0)
end

run_after_global("Step", function()
  if panel_enabled() and not Dock.busy then
    decide_header_mode()
    check_header()
    if Dock.shift ~= nil then
      local sh = Dock.shift
      Dock.shift = nil
      redirect_focus_shift(sh)
      Dock.lock_guard(sh[1], sh[2])
    end
    if clip_enabled() then
      clip_tactic_plates()
    end
    fix_kit_position()
    Dock.box_guard()
    Dock.header_focus_log()
  end
  if not Dock.busy then
    Dock.header_zones()
    place_attack_defense()
    place_mod_button()
    Dock.icons_place()
    clear_ghost_focus()
  end
end)
