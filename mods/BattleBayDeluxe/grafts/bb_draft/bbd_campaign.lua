-- Draft screen of the Battle Bay grids (enjoy_team_select_menu_campaign / _offline)
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.draft = {
  INFO = @crc:CMND_BATTLEBAYDELUXE_DRAFT_INFO@,
  BEGIN = @crc:CMND_BATTLEBAYDELUXE_DRAFT_BEGIN@,
  SLOTS = @crc:CMND_BATTLEBAYDELUXE_DRAFT_SLOTS@,
  SLOT_INFO = @crc:CMND_BATTLEBAYDELUXE_DRAFT_SLOT@,
  CANDS = @crc:CMND_BATTLEBAYDELUXE_DRAFT_CANDIDATES@,
  PICK = @crc:CMND_BATTLEBAYDELUXE_DRAFT_PICK@,
  ABANDON = @crc:CMND_BATTLEBAYDELUXE_DRAFT_ABANDON@,
  DECIDE = @crc:CMND_BATTLEBAYDELUXE_DRAFT_DECIDE@,
  FORMATIONS = @crc:CMND_BATTLEBAYDELUXE_DRAFT_FORMATIONS@,
  SET_FORMATION = @crc:CMND_BATTLEBAYDELUXE_DRAFT_SET_FORMATION@,
  PLACE = @crc:CMND_BATTLEBAYDELUXE_FORMATION_PLACE@,
  FN_Y = @crc:battlebaydeluxe_roster_y@, -- Y on the anchor (CMD_FUNC3): swallowed during the draft
  PAGE_SLOT = @crc:CMND_VRFW_BB_PAGE_SLOT@,
  PAGE_REFRESH = @crc:CMND_VRFW_BB_PAGE_REFRESH@,
  TEAM = @crc:battlebaydeluxe_draft@,
  MENU = 786045682 --[[enjoy_team_select_menu]],
  GRID = 106197494 --[[vs01_43_enjoy_team_select_emblem_icon]],
  ATTACH = 2994917936 --[[vs01_42_enjoy_team_select_emblem_attach_base]],
  LOCK = 892105257 --[[mainmenu90_30_lock_icon]],
  DIFFWIN = 2996147312 --[[win05_11_select_difficulty_win_base]],
  LEFT = 3003299608 --[[team00_01_chara_card_left]],
  RIGHT = 3825623416 --[[team00_01_chara_card_right]],
  -- Layers hidden in the free match.
  FREE_HIDE = {3825623416 --[[team00_01_chara_card_right]], 187604095 --[[vs01_46_enjoy_team_select_formation_frame_right]],
               2708277675 --[[vs01_45_p1_enjoy_team_select_teamInfo]], 909193856 --[[soccer08_12_tactics_cmd_right]],
               4074949471 --[[team00_10_tactics_base_right]], 4211334321 --[[soccer00_40_username_left]],
               1262779231 --[[soccer00_40_username_right]], 66400840 --[[vs01_29_ready_ok_balloon_left]],
               2413676297 --[[vs01_29_ready_ok_balloon_right]], 2313398190 --[[vs01_49_soccer_game_option_list_button]],
               429081730 --[[vs01_21_room_setting_button]]},
  FRAME = 1324325467 --[[vs01_46_enjoy_team_select_formation_frame_left]],
  M_FIELD = 832482535 --[[_formation_field_s01: the frame's pitch]],
  FRAME_NODES = {2654143900 --[[_pos_formation01_cc]], 2278526192 --[[_pos_formation01_ld]],
                 960402397 --[[_pos_formation01_ru]]},
  TEAMINFO = 2945114490 --[[vs01_44_p1_enjoy_team_select_teamInfo]],
  M_TACTICS_LABEL = 1145084495 --[[_gtxt_tactics01: TACTICS]],
  TACTICS_BASE = 996660679 --[[team00_10_tactics_base_left]],
  TACTICS_CMD = 2312417854 --[[soccer08_12_tactics_cmd_left]],
  SLOT = @crc:battlebaydeluxe_draft_slot@,
  CARD = @crc:battlebaydeluxe_draft_card@,
  NODE_BASE = @crc:_pos_base01@ --[[The retail focus rule measures from this card node.]],
  -- direction types of the retail formation focus rule (soccer_formation_menu_inc GetFocusDirType)
  DIR_UP = 1, DIR_DOWN = 2, DIR_LEFT = 3, DIR_RIGHT = 4,
  ANCHOR = @crc:battlebaydeluxe_draft_anchor@,
  FN_UP = @crc:battlebaydeluxe_up@,
  FN_DOWN = @crc:battlebaydeluxe_down@,
  FN_LEFT = @crc:battlebaydeluxe_left@,
  FN_RIGHT = @crc:battlebaydeluxe_right@,
  GUIDE = 618184632 --[[mainmenu01_06_base_button_guide_right]],
  GUIDE_TEXT = 378156699 --[[_text_guide01]],
  CURSOR = 2296367164 --[[cmn05_01_cursor]],
  GRID_CURSOR = 3313461902 --[[cursor]],
  CARD_CURSOR = 945715707, CARD_CURSOR2 = 1967169874, -- the card objbin's cursor labels
  EMBLEM_TEX = 618311715 --[[enjoy_list_icon_dmy01]],
  EMBLEM_NODE = 3933090681 --[[_pos_enjoy_list01]],
  -- Card meshes (NameSetting_CharaCardForSoccer names, large and small pairs).
  M_TAG = {@crc:_icon_card01@, @crc:_icon_card02@, @crc:_icon_lock01@, @crc:_icon_lock02@},
  M_FOCUS = {@crc:_icon_chr_focus_l01@, @crc:_icon_chr_focus_s01@},
  M_FACE = {@crc:_icon_chr_dmy_l01@, @crc:_icon_chr_dmy_s01@, @crc:_icon_chr_type_dmy_l01@, @crc:_icon_chr_type_dmy_s01@,
            @crc:_icon_base_l01@, @crc:_icon_base_s01@, @crc:_icon_chr_position_dmy_l01@, @crc:_icon_chr_position_dmy_s01@,
            @crc:_icon_chr_gradation_l01@, @crc:_icon_chr_gradation_s01@},
  M_EMPTY = {@crc:_num_chr_dmy_l01@, @crc:_num_chr_dmy_l02@, @crc:_num_chr_dmy_s01@, @crc:_num_chr_dmy_s02@,
             @crc:_gtxt_lv_l01@, @crc:_gtxt_lv_s01@, @crc:_icon_captain01@, @crc:_icon_captain02@,
             @crc:_icon_chr_grayout01@, @crc:_icon_chr_grayout01_s@, @crc:_seasonal_frame_l01@, @crc:_seasonal_frame_s01@,
             @crc:_avatar_frame_l01@, @crc:_avatar_frame_s01@, @crc:_basara_avatar_l01@, @crc:_basara_avatar_s01@},
  M_STAFF = {@crc:_leader_base01@, @crc:_leader_base02@, @crc:_gtxt_leader01@, @crc:_gtxt_leader02@,
             @crc:_icon_ai_role_dmy01@, @crc:_icon_ai_role_dmy02@, @crc:_icon_synergy_l01@, @crc:_icon_synergy_l02@,
             @crc:_icon_synergy_s01@, @crc:_icon_synergy_s02@, @crc:_icon_teamdock01@},
  N_STAFF = {@crc:_pos_leader01@, @crc:_pos_leader02@, @crc:_pos_ai_role01@, @crc:_pos_ai_role02@},
  M_BASE = {@crc:_icon_chr_base_l01@, @crc:_icon_chr_base_s01@},
  M_DEF = {@crc:_icon_chr_def01_l@, @crc:_icon_chr_def01_s@},
  -- Size index of the slot cards.
  SZ = 2,
  -- Size index of the candidate cards.
  SZ_CARD = 1,
  -- (node scale = size in px, node translation = its top-left corner)
  Q_W = 60, Q_H = 88, Q_SCALE = 0.78, Q_BOLD_X = 1.2, -- smaller, strokes thicker (width stretched)
  Q_SCALE_L = 0.94,
  NODE_POS = 2575768773 --[[(layer, idx, node, axis 0/1/2, value): local node translation]],
  NODE_SCALE = 2885415772 --[[(layer, idx, node, sx, sy): local node scale]],
  -- Sprite swap command 558735651 takes (layer, texture file, sprite, material texture, 0, idx).
  TEX_CARD = 4225297828 --[[#/menu/102_team/team00/team00_01/<LG>/team00_01.g4tx]],
  TEX_NUM = 1677382518 --[[#/menu/200_icon/100_num/num_menu01.g4tx (MENU_RES of this menu)]],
  SPR_GREY = 1967881488 --[[icon_chr_grayout01_s: the small card's grey (136 x 100)]],
  SPR_GREY_L = 2195302709 --[[icon_chr_base01_type_gray01: the large card's grey (212 x 132), the pack's backs]],
  SPR_Q = 3747115962 --[[num_menu01_01_q]],
  SLOT_BASE = {840912853 --[[icon_chr_base01_l01]], 627420056 --[[icon_chr_base01_s01]]},
  SLOT_DEF = {4281540162 --[[icon_chr_def01_l]], 1916474295 --[[icon_chr_def01_s]]},
  T_NAME = @crc:_text_chr01@,
  TXT_POS = {[0] = @crc:battlebaydeluxe_pos_0@, @crc:battlebaydeluxe_pos_1@, @crc:battlebaydeluxe_pos_2@, @crc:battlebaydeluxe_pos_3@, @crc:battlebaydeluxe_pos_4@,
             @crc:battlebaydeluxe_pos_5@, @crc:battlebaydeluxe_pos_6@},
  -- Staff places (CMND_BATTLEBAYDELUXE_DRAFT_SLOT kinds).
  POS_COACH = 5, POS_MANAGER = 6,
  COACH_X = 600, COACH_Y = -745, COACH_SCALE = 1.1, HALF_COACH = {85, 64},
  MANAGER_PLACES = {}, -- the triangle under the bench column (BattleBayDeluxe.draft_manager_places)
  TXT_SLOT = @crc:battlebaydeluxe_slot@,
  TXT_PLAYER = @crc:battlebaydeluxe_player@,
  TXT_START = @crc:battlebaydeluxe_start@,
  TXT_START_MATCH = @crc:battlebaydeluxe_start_match@, -- the free match's question
  TXT_QUIT_ASK = @crc:battlebaydeluxe_quit_ask@,
  TXT_PICK_ONE = @crc:battlebaydeluxe_pick_one@,
  SE_NG = 2086672038 --[[sy0003]],
  TXT_KEYS = @crc:battlebaydeluxe_keys@,
  TXT_ERROR = @crc:battlebaydeluxe_error@,
  -- Layout in menu pixels (x from the left, y 0 at the top edge, negative downwards).
  PITCH_CX = 1150, MIRROR = 1, PITCH_TOP = -195, SLOT_SCALE = 1.05,
  FRAME_FIELD_CX = 119, FRAME_DY = -102, FRAME_SX = 2.05, FRAME_SY = 1.94,
  -- Bench layout.
  BENCH_X = 1680, BENCH_Y = -195, BENCH_DY = -112,
  BENCH_GREY = true,
  -- Layout of the candidates when there is no pack.
  CAND_X = 250, CAND_Y = -210, CAND_DY = -150, CARD_SCALE = 1.05, CARD_SCALE_ON = 1.05,
  PRIO = 700,
  ANCHOR_X = -4000, ANCHOR_Y = 4000,
  REFRESH_FRAMES = 8,
  REAPPLY_FRAMES = 30,
  PROBE_FRAMES = 12,
  LEVEL = 40,
  -- Mouse support (config.toml [draft] mouse).
  MOUSE = @crc:CMND_BATTLEBAYDELUXE_DRAFT_MOUSE@,
  HALF_SLOT = {56, 50}, HALF_CAND = {81, 61},
  -- BattleBayDeluxe.draft_stray_scan logs visible instances of these layers within STRAY_X px of the left edge
  STRAY_X = 120,
  STRAY_LAYERS = {
    {"battlebaydeluxe_draft_anchor", @crc:battlebaydeluxe_draft_anchor@}, {"battlebaydeluxe_draft_slot", @crc:battlebaydeluxe_draft_slot@},
    {"battlebaydeluxe_draft_card", @crc:battlebaydeluxe_draft_card@}, {"battlebaydeluxe_pk_quad", @crc:battlebaydeluxe_pk_quad@},
    {"battlebaydeluxe_pk_txt", @crc:battlebaydeluxe_pk_txt@}, {"battlebaydeluxe_pk_crest", @crc:battlebaydeluxe_pk_crest@},
    {"cmn05_01_cursor", 2296367164},
    {"battlebaydeluxe_mode_bg", @crc:battlebaydeluxe_mode_bg@}, {"battlebaydeluxe_mode_pill", @crc:battlebaydeluxe_mode_pill@},
    {"battlebaydeluxe_mode_txt", @crc:battlebaydeluxe_mode_txt@}, {"vrfw_bb_page_guide", @crc:vrfw_bb_page_guide@},
    {"battlebaydeluxe_roster_bg", @crc:battlebaydeluxe_roster_bg@}, {"battlebaydeluxe_roster_frame", @crc:battlebaydeluxe_roster_frame@},
    {"battlebaydeluxe_roster_title", @crc:battlebaydeluxe_roster_title@}, {"battlebaydeluxe_roster_blank", @crc:battlebaydeluxe_roster_blank@},
    {"battlebaydeluxe_roster_card", @crc:battlebaydeluxe_roster_card@},
  },
  -- state
  mode = nil, tile = -1, sel = 0, csel = 0, k = -1, shown = nil, formation = 0,
  slots = {}, cands = {}, pos = {}, where = {}, ready = {}, slotArgs = {}, opened = false, used = false, bypass = false,
  refresh = nil, reapply = nil, probe = nil, quitCo = nil,
  named = {},
  pk = nil,
  -- State of the free match.
  side = true, drawn = {}, ours = false, stash = {}, autoDecide = false,
  ptr = nil, mouse = true, polled = false, mouseDecided = false,
}

-- The managers' triangle under the last bench slot, centred on the bench column, with the bench column's gap between cards.
function BattleBayDeluxe.draft_manager_places()
  local B, L = BattleBayDeluxe.draft, BattleBayDeluxe.draft_layout
  BattleBayDeluxe.draft_pitch_look()
  local rowGap = -B.BENCH_DY
  local lastBench = B.BENCH_Y + 4 * B.BENCH_DY
  local top = lastBench - 2 * rowGap
  local gap = rowGap - L.CARD_HEIGHT * L.CARD_SCALE
  local half = (L.CARD_WIDTH * L.CARD_SCALE + gap) / 2
  B.MANAGER_PLACES = {{B.BENCH_X, top}, {B.BENCH_X - half, top - rowGap}, {B.BENCH_X + half, top - rowGap}}
end


function BattleBayDeluxe.draft_free()
  return BattleBayDeluxe.draft_host == "free_match"
end

-- State of the candidates' pack opening.
BattleBayDeluxe.draft_pack = {
  CMD = @crc:CMND_BATTLEBAYDELUXE_DRAFT_PACK@,
  QUAD = @crc:battlebaydeluxe_pk_quad@,
  TXT = @crc:battlebaydeluxe_pk_txt@,
  CREST = @crc:battlebaydeluxe_pk_crest@,
  ART = 1048010258 --[[#/menu/220_img/bbd_pk/bbd_pk.g4tx]],
  MESH_QUAD = 312193881 --[[_icon_new01]],
  NODE_QUAD = 1909474081 --[[icon_new01]],
  TXT_ON = @crc:_text_list01_on@, TXT_OFF = @crc:_text_list01_off@,
  STYLE = 1911293514 --[[fs_28_w_cc_2d0_001: centred white, no outline]],
  TXT_SKIP = @crc:battlebaydeluxe_pack_skip@,
  -- commands
  VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@, POS = @crc:CMND_SET_LAYER_LOCAL_POS@, SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@, SPRITE = 558735651, PRIM_COLOR = @crc:CMND_SET_PRIM_COLOR@,
  PRIM_ALPHA = @crc:CMND_SET_PRIM_ALPHA@, TEXT = @crc:CMND_SET_MENU_TEXT_STRING@, TEXT_VISIBLE = @crc:CMND_SET_MENU_TEXT_VISIBLE@, TEXT_STYLE = 2333948100,
  TEXT_ALPHA = @crc:CMND_SET_MENU_TEXT_ALPHA@, MODEL_ALPHA = @crc:CMND_SET_LAYER_MODEL_ALPHA@, PRIO = @crc:CMND_SET_DRAW_PRIORITY@, CHARA_INFO = @crc:CMND_GET_CHARA_INFO@, SE = @crc:CMND_SND_PLAY_SE@,
  Q = 36, -- the quad's size in px at scale 1
  -- Layout of the row under a card.
  N_CREST = 5, CREST_PX = 68, CREST_CX = 78, CREST_WAIT = 30, LOADING = 1277042906,
  CREST_HIDE = {@crc:_list_base_xs01_off@, @crc:_list_base_xs01_on@, @crc:_list_base_xs01_ok@, @crc:_list_base_xs01_ol@,
                @crc:_icon_check01@},
  MESH_VISIBLE = 2158717427,
  ROW_CREST = 44, ROW_GAP = 12, ROW_MARGIN = 14, NAME_SCALE = 0.82, NAME_MIN = 0.5, GLYPH = 13.5, ROW_Y = 30,
  crests = {}, -- the team each crest instance shows (VRFW.team.emblem)
  I_DIM = 0, I_BAND = 1, I_EDGE = 2, I_GLOW = 4, I_FLASH = 9, I_SCREEN = 14, N_QUAD = 16, N_TXT = 7,
  CARD_PRIO = 720,
  -- Timings and sizes of the pack animation.
  intro = 0.25, deal = 0.22, deal_stagger = 0.07, flip = 0.22, settle = 0.12, flash = 0.30, gap = 0.45,
  suspense = 0.40, outro = 0.28, dim = 0.72, scale = 1.6, spacing = 330,
  se_open = 3848881948 --[[sy0000]], se_deal = 2629173176 --[[sy0009]], se_reveal = 4235359837 --[[sy0010]],
  se_best = 766561556 --[[sy0080]],
  FPS = 60, CX = 960, CY = 540,
  -- the large card at scale 1 (body _touch_chr01 154 x 116, centred on the layer origin)
  CARD_W = 154, CARD_H = 116, CARD_OX = 0, CARD_OY = 0,
  LAND = 106.6 / 154.4,
  -- Places the cursor arrow (cmn05_01_cursor, tip at the layer's origin, arrow to its left) at the focused card.
  CUR_DX = 6, CUR_DY = 0,
  PAUSE = 0.12,
  OVER = 0.12, OVER_BEST = 0.25, -- the turned card's bounce
  SEL_GROW = 1.08, SEL_LIFT = 16, -- the chosen card on the band
  COL_DIM = @crc:bbd_pk_dim@, COL_BAND = @crc:bbd_pk_band@, BAND_ALPHA = 0.88, COL_EDGE = @crc:bbd_pk_edge@,
  COL_GLOW = @crc:bbd_pk_glow@, GLOW_ALPHA = 0, COL_GOLD = @crc:bbd_pk_gold@, GOLD_ALPHA = 0.65,
  COL_FLASH = @crc:bbd_pk_flash@, COL_SCREEN = @crc:bbd_pk_screen@, SCREEN_ALPHA = 0.55,
  spr = {},
  loaded = false,
}

-- Registers extra card layers for the formation-card look of soccer_common's position_cards (VRFW.formation_card_extra).
VRFW.formation_card_extra = VRFW.formation_card_extra or {}
VRFW.formation_card_extra[BattleBayDeluxe.draft.SLOT] = true
VRFW.formation_card_extra[BattleBayDeluxe.draft.CARD] = true

function BattleBayDeluxe.draft_logger()
  return BattleBayDeluxe.logger(BattleBayDeluxe.draft, "BattleBayDeluxe.draft")
end

function BattleBayDeluxe.draft_log(...)
  BattleBayDeluxe.draft_logger()(...)
end

function BattleBayDeluxe.draft_text(id, fallback)
  local s = funcLuaCommand(@crc:CMND_TEXT_GET@, id)
  if type(s) ~= "string" or s == "" then
    return fallback or ""
  end
  return s
end

-- Reads the state of the draft script.
function BattleBayDeluxe.draft_info()
  local ok, team, phase, filled, total = funcLuaCommand(BattleBayDeluxe.draft.INFO)
  if ok ~= true or type(phase) ~= "number" then
    -- Returns zeros when the mod's script gives no answer (it is off).
    return false, 0, 0, 0
  end
  return true, phase, filled or 0, total or 0
end

function BattleBayDeluxe.draft_team_name()
  local ok, name = funcLuaCommand(2151743654, BattleBayDeluxe.draft.TEAM, 2)
  if ok and type(name) == "string" and name ~= "" then
    return name
  end
  return "Draft"
end

-- Returns the team on a grid tile.
function BattleBayDeluxe.draft_tile_team(tile)
  local B = BattleBayDeluxe.draft
  local rec = B.slotArgs[tile]
  local team = rec and rec[1] or nil
  if team == nil then
    local t = funcLuaCommand(B.PAGE_SLOT, tile)
    team = type(t) == "number" and t or 0
  end
  return team
end

function BattleBayDeluxe.draft_is_slot(slot)
  return BattleBayDeluxe.draft_tile_team(slot) == BattleBayDeluxe.draft.TEAM
end

function BattleBayDeluxe.draft_layer_visible(layer, count, on)
  for i = 0, count - 1 do
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, on)
  end
end

-- both cursor labels of a card instance unhooked
function BattleBayDeluxe.draft_cursor_labels_off(layer, i)
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, layer, i, B.CARD_CURSOR, false)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, layer, i, B.CARD_CURSOR2, false)
end

-- Closes the team panel when it is open, since it holds the picker's 3D character.
function BattleBayDeluxe.draft_team_panel_close()
  local B = BattleBayDeluxe.draft
  if funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, B.TEAMINFO, 0) == true then
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, B.TEAMINFO)
    return true
  end
  return false
end

-- the anchor instance kept off screen and never drawn
function BattleBayDeluxe.draft_anchor_park(i)
  local B = BattleBayDeluxe.draft
  VRFW.host.menu_command(@crc:CMND_SET_LAYER_LOCAL_POS@, B.ANCHOR, B.ANCHOR_X, B.ANCHOR_Y, 0, i)
  VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, B.ANCHOR, i or 0, false)
end

-- Returns the card layer and instance that the D-pad direction (dx, dy) (dy > 0 = up) reaches from instance i of
-- layer by the retail formation screen's rule (soccer_formation_menu_inc CalcMoveFocusLayerByCircleCollision over the
-- shown instances 0..count-1); nil when no card lies that way, so the focus stays as on the retail screen.
function BattleBayDeluxe.draft_focus_move(layer, i, count, dx, dy)
  local B = BattleBayDeluxe.draft
  if type(CalcMoveFocusLayerByCircleCollision) ~= "function" then
    BattleBayDeluxe.draft_log("move: the retail formation focus rule is not in this script, the focus stays")
    return nil
  end
  local dir = (dy > 0 and B.DIR_UP) or (dy < 0 and B.DIR_DOWN) or (dx < 0 and B.DIR_LEFT) or (dx > 0 and B.DIR_RIGHT) or nil
  if dir == nil then
    return nil
  end
  local to, to_layer = CalcMoveFocusLayerByCircleCollision(layer, i, dir, count, B.NODE_BASE)
  if type(to) ~= "number" or to < 0 then
    return nil
  end
  return to_layer, to
end

-- a Draft card instance's name table, written once for the life of the menu (a second write corrupts the heap)
function BattleBayDeluxe.draft_name(layer, i)
  local B = BattleBayDeluxe.draft
  local key = layer .. ":" .. i
  if B.named[key] then
    return
  end
  B.named[key] = true
  NameSetting_CharaCardForSoccer(layer, i)
end

function BattleBayDeluxe.draft_guide(s)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, BattleBayDeluxe.draft.GUIDE, BattleBayDeluxe.draft.GUIDE_TEXT, s, 0)
  funcLuaMenuCommand(2735666188, BattleBayDeluxe.draft.GUIDE, BattleBayDeluxe.draft.GUIDE_TEXT, true, 0)
end

function BattleBayDeluxe.draft_filled()
  local n = 0
  for k = 0, #BattleBayDeluxe.draft.slots - 1 do
    if BattleBayDeluxe.draft.slots[k + 1].param ~= 0 then
      n = n + 1
    end
  end
  return n
end

-- the guide line of the current mode
function BattleBayDeluxe.draft_show_guide()
  local B = BattleBayDeluxe.draft
  local head = string.format("%s %d/%d  ·  ", BattleBayDeluxe.draft_team_name(), BattleBayDeluxe.draft_filled(), #B.slots)
  if B.mode == "pitch" then
    -- Clears the controls guide because the board has none.
    VRFW.footer_prompts.set(nil, B.MENU, {}, {guide = B.GUIDE, declared = false})
    BattleBayDeluxe.draft_guide(string.format("Draft %d/%d", BattleBayDeluxe.draft_filled(), #B.slots))
  elseif B.mode == "cands" then
    local rec = B.slots[B.k + 1]
    BattleBayDeluxe.draft_guide(head .. BattleBayDeluxe.draft_text(B.TXT_POS[rec and rec.pos or 0]) .. ": " .. BattleBayDeluxe.draft_text(B.TXT_PLAYER))
  elseif B.mode == "start" then
    BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(BattleBayDeluxe.draft_free() and B.TXT_START_MATCH or B.TXT_START) .. "   " .. BattleBayDeluxe.draft_text(B.TXT_KEYS))
  elseif B.mode == "quit" then
    BattleBayDeluxe.draft_guide(head .. BattleBayDeluxe.draft_text(B.TXT_SLOT))
  end
end

-- Loads the slots from the script, one command per slot, because a single call's return values are capped.
function BattleBayDeluxe.draft_load_slots()
  local B = BattleBayDeluxe.draft
  local r = table.pack(funcLuaCommand(B.SLOTS))
  if r[1] ~= true then
    return false
  end
  B.slots, B.pos, B.where = {}, {}, {}
  BattleBayDeluxe.draft_manager_places()
  local bench, managers = 0, 0
  for k = 0, (r[2] or 0) - 1 do
    local q = table.pack(funcLuaCommand(B.SLOT_INFO, k))
    if q[1] ~= true or type(q[2]) ~= "number" then
      return false
    end
    local rec = {slot = q[2], pos = q[3], x = q[4], y = q[5], param = q[6], ph = q[7]}
    rec.field = rec.pos ~= 0 and rec.slot >= 0 and rec.slot <= 10
    rec.staff = rec.pos == B.POS_COACH or rec.pos == B.POS_MANAGER
    B.slots[k + 1] = rec
    B.where[k] = {B.SLOT, k}
    if rec.field then
      B.pos[k] = {B.PITCH_CX, B.PITCH_TOP}
    elseif rec.pos == B.POS_COACH then
      B.pos[k] = {B.COACH_X, B.COACH_Y}
    elseif rec.pos == B.POS_MANAGER then
      managers = managers + 1
      B.pos[k] = B.MANAGER_PLACES[math.min(managers, #B.MANAGER_PLACES)]
    else
      B.pos[k] = {B.BENCH_X, B.BENCH_Y + bench * B.BENCH_DY}
      bench = bench + 1
    end
  end
  local okf, fm = funcLuaCommand(2151743654, B.TEAM, 3)
  B.formation = (okf and type(fm) == "number") and fm or 0
  BattleBayDeluxe.draft_place_field()
  return #B.slots > 0
end

-- Starters' places for any formation.
BattleBayDeluxe.draft_layout = {
  -- the dock's pitch (nodes of soccer11_02_formation_frame) and units, as SetupFormationIconPosition passes them
  DOCK_TOP = 278, DOCK_BOTTOM = -381, DOCK_TOP_HALF = 252, DOCK_BOTTOM_HALF = 346,
  DOCK_WIDTH_UNITS = 60, DOCK_DEPTH_UNITS = 94, DOCK_KEEPER_LIFT = 20,
  ATTACK_SET = 2, START_SET = 1, OFFSET_SET = 10,
  START_WIDTH_METRES = 30, START_DEPTH_METRES = 47, -- CMND_BATTLEBAYDELUXE_DRAFT_SLOT gives startPos x 1000
  SAME_SPOT_METRES = 1,
  -- Layout of this screen's pitch as drawn (screen pixels, y down).
  CX = 1150, TOP = 134, BOTTOM = 878, TOP_HALF = 307, BOTTOM_HALF = 417,
  -- Defaults used when config.toml [draft.pitch] gives no answer.
  CARD_SCALE = 1.05, CARD_WIDTH = 106.6, CARD_HEIGHT = 96, CARD_GAP = 8, EDGE_MARGIN = 6, SAME_ROW_DISTANCE = 30,
  SYMMETRY_TOLERANCE = 40,
  ROUNDS = 200,
  PITCH_CMD = @crc:CMND_BATTLEBAYDELUXE_DRAFT_PITCH@, asked = false,
  -- Box that the strip's mini pitch maps (screen pixels).
  BOX_L = 1150 - 417, BOX_R = 1150 + 417, BOX_T = 134, BOX_B = 878,
}

-- the tunables of config.toml [draft.pitch], once per menu
function BattleBayDeluxe.draft_pitch_look()
  local L, B = BattleBayDeluxe.draft_layout, BattleBayDeluxe.draft
  if L.asked then
    return
  end
  L.asked = true
  local answered, scale, width, height, gap, margin, sameRow, tolerance = VRFW.host.command(L.PITCH_CMD)
  if answered == true and type(tolerance) == "number" then
    L.CARD_SCALE, L.CARD_WIDTH, L.CARD_HEIGHT, L.CARD_GAP = scale, width, height, gap
    L.EDGE_MARGIN, L.SAME_ROW_DISTANCE, L.SYMMETRY_TOLERANCE = margin, sameRow, tolerance
    B.SLOT_SCALE = scale
    B.HALF_SLOT = {width * scale / 2, height * scale / 2}
  else
    BattleBayDeluxe.draft_log("pitch look: defaults (no CMND_BATTLEBAYDELUXE_DRAFT_PITCH answer)")
  end
end

-- Returns the dock's place of a position in metres (dock pixels around the centre circle, y up).
function BattleBayDeluxe.draft_dock_point(x, y)
  local L = BattleBayDeluxe.draft_layout
  local upper, lower = 2 * L.DOCK_TOP_HALF, 2 * L.DOCK_BOTTOM_HALF
  local total = L.DOCK_TOP - L.DOCK_BOTTOM
  local above, below = L.DOCK_TOP, -L.DOCK_BOTTOM
  local height = -y * (total / L.DOCK_DEPTH_UNITS) + total * 0.5
  local width = (upper - lower) * (height / total) + lower
  local ratio = y / L.DOCK_DEPTH_UNITS
  local up = below - y * (lower / L.DOCK_WIDTH_UNITS)
  if ratio < 0 then
    up = up + total * ratio * above / below
  elseif ratio > 0 then
    up = up + above * ratio * below / (total * 0.5)
  end
  return x * (width / L.DOCK_WIDTH_UNITS), up - below
end

-- the half width of the drawn pitch at screen height y
function BattleBayDeluxe.draft_pitch_half(y)
  local L = BattleBayDeluxe.draft_layout
  return L.TOP_HALF + (y - L.TOP) * (L.BOTTOM_HALF - L.TOP_HALF) / (L.BOTTOM - L.TOP)
end

-- a row's cards at least a card plus the gap apart (mirrored rows from the centre outwards), inside the pitch
function BattleBayDeluxe.draft_space_row(row, w, h)
  local L = BattleBayDeluxe.draft_layout
  local xs, n, step = row.xs, #row.xs, w + L.CARD_GAP
  if row.mirrored then
    local middle = math.floor(n / 2)
    local previous, first = -step / 2, middle + 1
    if row.clear_centre then
      previous = 0
    end
    if n % 2 == 1 then
      xs[middle + 1] = 0
      previous, first = 0, middle + 2
    end
    for i = first, n do
      previous = math.max(xs[i], previous + step)
      xs[i], xs[n + 1 - i] = previous, -previous
    end
  else
    for i = 2, n do
      xs[i] = math.max(xs[i], xs[i - 1] + step)
    end
  end
  local limit = BattleBayDeluxe.draft_pitch_half(row.y - h / 2) - w / 2 - L.EDGE_MARGIN
  if xs[n] > limit then
    xs[n] = limit
    for i = n - 1, 1, -1 do
      xs[i] = math.min(xs[i], xs[i + 1] - step)
    end
  end
  if xs[1] < -limit then
    xs[1] = -limit
    for i = 2, n do
      xs[i] = math.max(xs[i], xs[i - 1] + step)
    end
  end
end

-- Returns the height that two rows need between them.
function BattleBayDeluxe.draft_rows_need(a, b, w, h)
  local L = BattleBayDeluxe.draft_layout
  for _, xa in ipairs(a.xs) do
    for _, xb in ipairs(b.xs) do
      if math.abs(xa - xb) < w + L.CARD_GAP then
        return h + L.CARD_GAP
      end
    end
  end
  return 0
end

-- Pushes apart rows whose cards would touch, each by half the distance, inside the pitch's height.
function BattleBayDeluxe.draft_stack_rows(rows, w, h, yMin, yMax)
  local L = BattleBayDeluxe.draft_layout
  for _ = 1, L.ROUNDS do
    local moved = false
    for _, row in ipairs(rows) do
      BattleBayDeluxe.draft_space_row(row, w, h)
    end
    for i = 1, #rows - 1 do
      for j = i + 1, #rows do
        local a, b = rows[i], rows[j]
        local short = BattleBayDeluxe.draft_rows_need(a, b, w, h) - (b.y - a.y)
        if short > 0.01 then
          a.y, b.y = a.y - short / 2, b.y + short / 2
          moved = true
        end
      end
    end
    for _, row in ipairs(rows) do
      row.y = math.max(yMin, math.min(yMax, row.y))
    end
    if not moved then
      break
    end
  end
  for i = #rows - 1, 1, -1 do
    for j = i + 1, #rows do
      rows[i].y = math.min(rows[i].y, rows[j].y - BattleBayDeluxe.draft_rows_need(rows[i], rows[j], w, h))
    end
  end
end

function BattleBayDeluxe.draft_pitch_layout(places)
  local L = BattleBayDeluxe.draft_layout
  BattleBayDeluxe.draft_pitch_look()
  local w, h = L.CARD_WIDTH * L.CARD_SCALE, L.CARD_HEIGHT * L.CARD_SCALE
  local sx = (L.TOP_HALF + L.BOTTOM_HALF) / (L.DOCK_TOP_HALF + L.DOCK_BOTTOM_HALF)
  local sy = (L.BOTTOM - L.TOP) / (L.DOCK_TOP - L.DOCK_BOTTOM)
  local centreY = L.TOP + L.DOCK_TOP * sy
  local field, keepers = {}, {}
  for _, p in ipairs(places) do
    local x, y = BattleBayDeluxe.draft_dock_point(p[3], p[4])
    y = y + p[6] + (p[2] and L.DOCK_KEEPER_LIFT or 0)
    local card = {key = p[1], x = (x + p[5]) * sx, y = centreY - y * sy}
    if p[2] then
      keepers[#keepers + 1] = card
    else
      field[#field + 1] = card
    end
  end
  table.sort(field, function(a, b)
    if a.y ~= b.y then
      return a.y < b.y
    end
    return a.x < b.x
  end)
  local rows = {}
  for _, card in ipairs(field) do
    local row = rows[#rows]
    if row ~= nil and card.y - row.first <= L.SAME_ROW_DISTANCE then
      row.cards[#row.cards + 1] = card
    else
      rows[#rows + 1] = {first = card.y, cards = {card}}
    end
  end
  for _, card in ipairs(keepers) do
    rows[#rows + 1] = {first = card.y, cards = {card}}
  end
  local yMin = L.TOP + L.EDGE_MARGIN + h / 2
  local yMax = L.BOTTOM - L.EDGE_MARGIN - h / 2
  for _, row in ipairs(rows) do
    table.sort(row.cards, function(a, b)
      return a.x < b.x
    end)
    local n, sum, worst, xs = #row.cards, 0, 0, {}
    for i, card in ipairs(row.cards) do
      sum = sum + card.y
      xs[i] = card.x
    end
    for i = 1, n do
      worst = math.max(worst, math.abs(xs[i] + xs[n + 1 - i]))
    end
    row.mirrored = worst <= L.SYMMETRY_TOLERANCE * 2
    row.xs = {}
    for i = 1, n do
      row.xs[i] = row.mirrored and (xs[i] - xs[n + 1 - i]) / 2 or xs[i]
    end
    row.y = math.max(yMin, math.min(yMax, sum / n))
  end
  BattleBayDeluxe.draft_stack_rows(rows, w, h, yMin, yMax)
  if rows[1].y < yMin then
    -- Marks the rows when too many rows are stacked on the centre line for the pitch's height.
    for _, row in ipairs(rows) do
      row.clear_centre = #row.xs % 2 == 0
    end
    BattleBayDeluxe.draft_stack_rows(rows, w, h, yMin, yMax)
  end
  local out = {}
  for _, row in ipairs(rows) do
    BattleBayDeluxe.draft_space_row(row, w, h)
    for i, card in ipairs(row.cards) do
      out[card.key] = {L.CX + BattleBayDeluxe.draft.MIRROR * row.xs[i], row.y}
    end
  end
  return out
end

-- Returns a formation slot's place from the game's formation data (metres and menu pixels).
function BattleBayDeluxe.draft_slot_data(formation, slot, set)
  local L = BattleBayDeluxe.draft_layout
  local info = @crc:CMND_GET_SOCCER_FORMATION_INFO@
  local ok, x, _, y = funcLuaCommand(info, 4, formation, slot, set)
  if ok ~= true or type(x) ~= "number" or type(y) ~= "number" then
    return nil
  end
  local oko, ox, oy = funcLuaCommand(info, 4, formation, slot, L.OFFSET_SET)
  if oko ~= true or type(ox) ~= "number" or type(oy) ~= "number" then
    ox, oy = 0, 0
  end
  return x, y, ox, oy
end

function BattleBayDeluxe.draft_rule_places(id, list)
  local L = BattleBayDeluxe.draft_layout
  local function read(set)
    local places = {}
    for _, m in ipairs(list) do
      local x, y, ox, oy = nil, nil, 0, 0
      if id ~= 0 then
        x, y, ox, oy = BattleBayDeluxe.draft_slot_data(id, m[2], set)
      end
      if x == nil then
        x, y, ox, oy = (m[4] or 0) * L.START_WIDTH_METRES / 1000, (m[5] or 0) * L.START_DEPTH_METRES / 1000, 0, 0
      end
      places[#places + 1] = {m[1], m[3], x, y, ox, oy}
    end
    return places
  end
  local places = read(L.ATTACK_SET)
  for i = 1, #places - 1 do
    for j = i + 1, #places do
      if math.abs(places[i][3] - places[j][3]) < L.SAME_SPOT_METRES
        and math.abs(places[i][4] - places[j][4]) < L.SAME_SPOT_METRES then
        return read(L.START_SET)
      end
    end
  end
  return places
end

function BattleBayDeluxe.draft_place_field()
  local B = BattleBayDeluxe.draft
  local list = {}
  for k = 0, #B.slots - 1 do
    local rec = B.slots[k + 1]
    if rec.field then
      list[#list + 1] = {k, rec.slot, rec.pos == 1, rec.x, rec.y}
    end
  end
  for k, at in pairs(BattleBayDeluxe.draft_pitch_layout(BattleBayDeluxe.draft_rule_places(B.formation, list))) do
    B.pos[k] = {at[1], -at[2]}
  end
end

-- Returns the large or small pair index of a Draft card.
function BattleBayDeluxe.draft_size(layer, i)
  local B = BattleBayDeluxe.draft
  if layer == B.CARD then
    return B.SZ_CARD
  end
  local rec = i ~= nil and B.slots[i + 1] or nil
  if rec ~= nil and rec.pos == B.POS_COACH then
    return 1
  end
  return B.SZ
end

-- Draws a param with the retail card draw.
function BattleBayDeluxe.draft_card_draw(layer, i, param, big, kind, role)
  local B = BattleBayDeluxe.draft
  if role == B.POS_MANAGER then
    funcLuaMenuCommand(2339877830, layer, i, param, big, false, kind, 0, B.LEVEL, false, false, 4, 0, false, true, 0,
                       false, false, true)
  else
    funcLuaMenuCommand(2339877830, layer, i, param, big, role == B.POS_COACH, kind, 0, B.LEVEL, false, false, 4, 0)
  end
end

-- Runs after any draw of a card.
function BattleBayDeluxe.draft_card_meshes(layer, i)
  local B = BattleBayDeluxe.draft
  local sz = BattleBayDeluxe.draft_size(layer, i)
  for _, m in ipairs(B.M_FOCUS) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
  for j = 1, 2 do
    if j ~= sz then
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[j], false, i)
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_DEF[j], false, i)
    end
  end
end

-- Draws what a drafted or offered card shows.
function BattleBayDeluxe.draft_filled_card(layer, i, param, role)
  local sz = BattleBayDeluxe.draft_size(layer, i)
  BattleBayDeluxe.draft_face_on(layer, i, sz)
  BattleBayDeluxe.draft_card_draw(layer, i, param, sz == 1, 0, role)
  BattleBayDeluxe.draft_tags_off(layer, i)
  BattleBayDeluxe.draft_card_meshes(layer, i)
end

function BattleBayDeluxe.draft_face_on(layer, i, sz)
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, true)
  for _, m in ipairs(B.M_DEF) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
  for k = sz, #B.M_FACE, 2 do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_FACE[k], true, i)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[sz], true, i)
end

-- the season tag / lock of a card instance hidden (after a draw)
function BattleBayDeluxe.draft_tags_off(layer, i)
  for _, m in ipairs(BattleBayDeluxe.draft.M_TAG) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
end

-- Draws an empty card centred.
function BattleBayDeluxe.draft_empty_card(layer, i, ph, grey, kind, role)
  local B = BattleBayDeluxe.draft
  local sz = BattleBayDeluxe.draft_size(layer, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, true)
  if type(ph) == "number" and ph ~= 0 then
    BattleBayDeluxe.draft_card_draw(layer, i, ph, sz == 1, type(kind) == "number" and kind or 0, role)
  else
    grey = true
  end
  for _, list in ipairs({B.M_FACE, B.M_EMPTY, B.M_TAG, B.M_STAFF}) do
    for _, m in ipairs(list) do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
    end
  end
  for _, n in ipairs(B.N_STAFF) do
    funcLuaMenuCommand(2158717427 --[[node visible]], layer, n, false, i)
  end
  if role == B.POS_COACH then
    funcLuaMenuCommand(2158717427 --[[node visible]], layer, B.N_STAFF[sz], true, i)
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_STAFF[sz], true, i)
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_STAFF[2 + sz], true, i)
  end
  local j = sz
  if grey then
    funcLuaMenuCommand(558735651, layer, B.TEX_CARD, j == 1 and B.SPR_GREY_L or B.SPR_GREY, B.SLOT_BASE[j], 0, i)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[j], true, i)
  local qs = j == 1 and B.Q_SCALE_L or B.Q_SCALE
  local qw, qh = B.Q_W * qs * B.Q_BOLD_X, B.Q_H * qs
  funcLuaMenuCommand(B.NODE_SCALE, layer, i, B.M_DEF[j], qw, qh)
  funcLuaMenuCommand(B.NODE_POS, layer, i, B.M_DEF[j], 0, -qw / 2)
  funcLuaMenuCommand(B.NODE_POS, layer, i, B.M_DEF[j], 1, qh / 2)
  funcLuaMenuCommand(558735651, layer, B.TEX_NUM, B.SPR_Q, B.SLOT_DEF[j], 0, i)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_DEF[j], true, i)
  BattleBayDeluxe.draft_card_meshes(layer, i)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, layer, B.T_NAME, "", i)
end

-- the empty look again (a late face / icon load can switch a mesh back on)
function BattleBayDeluxe.draft_rehide(layer, i)
  for _, m in ipairs(BattleBayDeluxe.draft.M_FACE) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
end

function BattleBayDeluxe.draft_draw_slot(k)
  local B = BattleBayDeluxe.draft
  local rec, w = B.slots[k + 1], B.where[k]
  if rec == nil or w == nil then
    return
  end
  local layer, i = w[1], w[2]
  if not B.ready[layer .. ":" .. i] then
    return
  end
  if B.mode == "formation" and rec.staff then
    -- Hides the layer because the formation step's strip covers the bottom edge.
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
    return
  end
  if rec.param ~= 0 then
    BattleBayDeluxe.draft_filled_card(layer, i, rec.param, rec.pos)
  else
    local kind = 0
    if rec.field and B.formation ~= 0 then
      local okk, kk = funcLuaCommand(@crc:CMND_GET_SOCCER_FORMATION_INFO@ --[[formation info]], 6, B.formation, rec.slot)
      kind = (okk == true and type(kk) == "number") and kk or 0
    end
    local grey = B.BENCH_GREY and not rec.field and rec.pos ~= B.POS_MANAGER
    BattleBayDeluxe.draft_empty_card(layer, i, rec.ph, grey, kind, rec.pos)
    B.reapply = B.REAPPLY_FRAMES
  end
  local sc = rec.pos == B.POS_COACH and B.COACH_SCALE or B.SLOT_SCALE
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, B.pos[k][1], B.pos[k][2], 0, i)
  funcLuaMenuCommand(3362798188, layer, i, sc, sc)
end

-- the pitch and the bench
function BattleBayDeluxe.draft_draw_pitch()
  for k = 0, #BattleBayDeluxe.draft.slots - 1 do
    BattleBayDeluxe.draft_draw_slot(k)
  end
end

function BattleBayDeluxe.draft_draw_candidate(i)
  local B = BattleBayDeluxe.draft
  local p = B.cands[i + 1]
  if not B.ready[B.CARD .. ":" .. i] or B.pk ~= nil then
    return
  end
  if p == nil or B.mode ~= "cands" then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
    return
  end
  BattleBayDeluxe.draft_filled_card(B.CARD, i, p.param, p.pos)
  local s = i == B.csel and B.CARD_SCALE_ON or B.CARD_SCALE
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CARD, B.CAND_X, B.CAND_Y + i * B.CAND_DY, 0, i)
  funcLuaMenuCommand(3362798188, B.CARD, i, s, s)
end

-- Returns the retail formation focus label of the selected card.
function BattleBayDeluxe.draft_cursor_label(layer, i)
  return BattleBayDeluxe.draft_size(layer, i) == 1 and BattleBayDeluxe.draft.CARD_CURSOR or BattleBayDeluxe.draft.CARD_CURSOR2
end

function BattleBayDeluxe.draft_cursor()
  local B = BattleBayDeluxe.draft
  if B.shown ~= nil then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, B.shown[1], B.shown[2],
                       BattleBayDeluxe.draft_cursor_label(B.shown[1], B.shown[2]), false)
    for _, m in ipairs(B.M_FOCUS) do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.shown[1], m, false, B.shown[2])
    end
    B.shown = nil
  end
  if B.mode == "formation" then
    -- Hides the cursor during the formation step.
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, false)
    return
  end
  local layer, i, n
  if B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      -- no cursor while the pack's cards are dealt and turned (BattleBayDeluxe.draft_pack_done puts it back)
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, false)
      return
    end
    layer, i, n = B.CARD, B.csel, 5
  elseif B.mode == "pitch" or B.mode == "start" or B.mode == "quit" then
    local w = B.where[B.sel]
    if w == nil then
      return
    end
    layer, i, n = w[1], w[2], #B.slots
  else
    return
  end
  local sz = BattleBayDeluxe.draft_size(layer, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, true)
  if layer == B.CARD and B.pk ~= nil then
    -- Draws the cursor on the pack's band.
    B.pk.cur = nil
    BattleBayDeluxe.draft_pack_cursor()
  else
    if B.curMoved then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CURSOR, 0, 0, 0, 0)
      B.curMoved = false
    end
    local label = BattleBayDeluxe.draft_cursor_label(layer, i)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, layer, i, label, true)
    funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, layer, label, i, n)
  end
  for j = 1, 2 do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_FOCUS[j], j == sz, i)
  end
  B.shown = {layer, i}
end

-- Holds the panel while the Draft screen is open.
function BattleBayDeluxe.draft_panel_hold()
  local B = BattleBayDeluxe.draft
  BattleBayDeluxe.draft_layer_visible(B.LEFT, 11, false)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.FRAME, B.PITCH_CX - B.FRAME_FIELD_CX, B.FRAME_DY, 0, 0)
  funcLuaMenuCommand(3362798188, B.FRAME, 0, B.FRAME_SX, B.FRAME_SY)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.FRAME, 0, true)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.FRAME, B.M_FIELD, true, 0)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.TACTICS_BASE, 0, false)
  BattleBayDeluxe.draft_layer_visible(B.TACTICS_CMD, 3, false)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.TEAMINFO, B.M_TACTICS_LABEL, false, 0)
end

-- every visible instance of a layer hidden and remembered (BattleBayDeluxe.draft_unstash restores them)
function BattleBayDeluxe.draft_stash(layer)
  local B = BattleBayDeluxe.draft
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, layer)
  if type(n) ~= "number" or n <= 0 then
    n = 1
  end
  for i = 0, n - 1 do
    if funcLuaMenuCommand(@crc:CMND_IS_LAYER_VISIBLE@, layer, i) == true then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
      B.stash[#B.stash + 1] = {layer, i}
    end
  end
end

function BattleBayDeluxe.draft_unstash()
  local B = BattleBayDeluxe.draft
  local list = B.stash
  B.stash = {}
  for _, e in ipairs(list) do
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, e[1], e[2], true)
  end
end

function BattleBayDeluxe.draft_screen_on()
  local B = BattleBayDeluxe.draft
  -- Closes the team panel because it holds the picker's 3D character.
  if not B.panelClosed then
    B.panelClosed = BattleBayDeluxe.draft_team_panel_close()
  end
  if BattleBayDeluxe.draft_free() then
    if #B.stash == 0 then
      BattleBayDeluxe.draft_stash(B.GRID)
      BattleBayDeluxe.draft_stash(B.ATTACH)
      BattleBayDeluxe.draft_stash(B.LOCK)
      for _, layer in ipairs(B.FREE_HIDE) do
        BattleBayDeluxe.draft_stash(layer)
      end
    end
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, false)
    if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.hide ~= nil) then
      pcall(VRFW.battle_bay_pages.hide)
    end
    BattleBayDeluxe.draft_panel_hold()
    return
  end
  BattleBayDeluxe.draft_layer_visible(B.GRID, funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.GRID) or 0, false)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.ATTACH, 0, false)
  BattleBayDeluxe.draft_layer_visible(B.LOCK, funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.LOCK) or 0, false)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, false)
  -- Hides the framework's page, category and season line over the grid (graft vrfw_bb_pages).
  if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.hide ~= nil) then
    pcall(VRFW.battle_bay_pages.hide)
  end
  BattleBayDeluxe.draft_panel_hold()
end

-- Restores the page line (vrfw_bb_pages) when the Draft screen turns off.
function BattleBayDeluxe.draft_screen_off()
  local B = BattleBayDeluxe.draft
  if B.panelClosed then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, B.TEAMINFO)
    B.panelClosed = false
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.FRAME, 0, 0, 0, 0)
  funcLuaMenuCommand(3362798188, B.FRAME, 0, 1, 1)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.TACTICS_BASE, 0, true)
  BattleBayDeluxe.draft_layer_visible(B.TACTICS_CMD, 3, true)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.TEAMINFO, B.M_TACTICS_LABEL, true, 0)
  if BattleBayDeluxe.draft_free() then
    BattleBayDeluxe.draft_unstash()
  end
  if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.setup_line ~= nil) then
    pcall(VRFW.battle_bay_pages.setup_line, 0)
  end
end

function BattleBayDeluxe.draft_probe()
  local B = BattleBayDeluxe.draft
  local parts = {}
  for _, node in ipairs(B.FRAME_NODES) do
    local x, y, z, ok = funcLuaMenuCommand(@crc:CMND_GET_MESH_POSE@, B.FRAME, 0, node)
    parts[#parts + 1] = string.format("%s(%s,%s,%s)", tostring(ok), tostring(x), tostring(y), tostring(z))
  end
  local fx, fy = funcLuaMenuCommand(@crc:CMND_GET_LAYER_LOCAL_POS@, B.FRAME, 0)
  local sx, sy = funcLuaMenuCommand(@crc:CMND_GET_LAYER_LOCAL_POS@, B.SLOT, 0)
  BattleBayDeluxe.draft_log("layout probe: frame nodes cc/ld/ru", table.concat(parts, " "), "frame at", tostring(fx), tostring(fy),
              "slot 0 at", tostring(sx), tostring(sy))
  pcall(BattleBayDeluxe.draft_stray_scan)
end

-- every visible instance of B.STRAY_LAYERS within STRAY_X px of the left edge, in one log line per screen
function BattleBayDeluxe.draft_stray_scan()
  local B = BattleBayDeluxe.draft
  local hits = {}
  for _, e in ipairs(B.STRAY_LAYERS) do
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, e[2])
    for i = 0, (type(n) == "number" and n or 0) - 1 do
      local vis = VRFW.host.menu_command(@crc:CMND_IS_LAYER_VISIBLE@ --[[is visible]], e[2], i)
      local gx, gy = VRFW.host.menu_command(4002164178 --[[global position]], e[2], i)
      if vis == true and type(gx) == "number" and gx >= -B.STRAY_X and gx <= B.STRAY_X then
        hits[#hits + 1] = string.format("%s[%d] at %d,%d", e[1], i, math.floor(gx), math.floor(-(gy or 0)))
      end
    end
  end
  BattleBayDeluxe.draft_log("left-edge scan: " .. (#hits > 0 and table.concat(hits, "; ") or "no visible layer of the list there"))
end

-- open the Draft layers (once per screen) and give the control focus to the anchor
function BattleBayDeluxe.draft_open()
  local B = BattleBayDeluxe.draft
  if not B.opened then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, B.SLOT)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, B.CARD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.QUAD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.TXT)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.CREST)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, B.ANCHOR)
    B.opened = true
  end
  BattleBayDeluxe.draft_formation_layers(true)
  -- Moves the anchor (a button object) off screen and makes it invisible.
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.ANCHOR, B.ANCHOR_X, B.ANCHOR_Y, 0, 0)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.ANCHOR, 0, false)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.ANCHOR, true)
  funcLuaMenuCommand(1778826357, B.ANCHOR, 0, true)
end

-- close the Draft layers (their card textures are released), the panel back, the focus off the anchor
function BattleBayDeluxe.draft_close_layers()
  local B = BattleBayDeluxe.draft
  if B.shown ~= nil then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, B.shown[1], B.shown[2],
                       BattleBayDeluxe.draft_cursor_label(B.shown[1], B.shown[2]), false)
    B.shown = nil
  end
  pcall(BattleBayDeluxe.draft_pack_end)
  B.cands = {}
  B.mode = nil
  B.reapply = nil
  B.probe = nil
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.ANCHOR, false)
  if B.opened then
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, B.SLOT)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, B.CARD)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.QUAD)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.TXT)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, BattleBayDeluxe.draft_pack.CREST)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, B.ANCHOR)
    B.opened = false
  end
  pcall(BattleBayDeluxe.draft_formation_layers, false)
  B.quitTo = nil
  B.ready = {}
  local ok, err = pcall(BattleBayDeluxe.draft_screen_off)
  if not ok then
    BattleBayDeluxe.draft_log("screen off error", tostring(err))
  end
end

function BattleBayDeluxe.draft_grid_back()
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, true)
  if BattleBayDeluxe.draft_free() then
    -- The grid came back with the stash (see BattleBayDeluxe.draft_screen_off).
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, true)
    local cur = funcLuaMenuCommand(2603265800, B.GRID)
    if type(cur) == "number" then
      funcLuaMenuCommand(4233535095, B.GRID, cur, true)
    end
    if SetButtonGuideText ~= nil then
      pcall(SetButtonGuideText, -1)
    end
    B.refresh = B.REFRESH_FRAMES
    return
  end
  local ok, err = pcall(OnCloseEndLayer, B.DIFFWIN, 0)
  if not ok then
    BattleBayDeluxe.draft_log("grid back error", tostring(err))
  end
  B.refresh = B.REFRESH_FRAMES
end

-- Refreshes the tile and the panel.
function BattleBayDeluxe.draft_refresh(tile, panel, keep)
  local B = BattleBayDeluxe.draft
  tile = tile or B.tile
  local page = funcLuaCommand(B.PAGE_REFRESH)
  local redrawn = false
  if type(page) == "number" and VRFW.battle_bay_pages ~= nil and (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.query ~= nil) and (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.redraw ~= nil) then
    VRFW.battle_bay_pages.query()
    redrawn = pcall(VRFW.battle_bay_pages.redraw)
  end
  if not redrawn then
    -- Skips the page handling when there is no pages service.
    local args = {}
    for i, rec in pairs(B.slotArgs) do
      args[#args + 1] = {i, rec}
    end
    for _, a in ipairs(args) do
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.GRID, a[1], a[2][1] ~= 0)
      if not keep then
        funcLuaMenuCommand(4176779611 --[[reset icon]], B.GRID, a[1], B.EMBLEM_TEX)
      end
      pcall(SetupEmblemIcon, a[1], a[2][1], a[2][2], a[2][3])
      funcLuaMenuCommand(2158717427 --[[node visible]], B.GRID, B.EMBLEM_NODE, a[2][1] ~= 0, a[1])
    end
  end
  -- Sets focus and cursor on the tile.
  if tile >= 0 then
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.GRID) or 0
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, true)
    funcLuaMenuCommand(1778826357, B.GRID, tile, true)
    funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, B.GRID, B.GRID_CURSOR, tile, n)
  end
  if panel ~= nil then
    panel()
  else
    BattleBayDeluxe.draft_panel_back()
  end
  BattleBayDeluxe.draft_log("grid refreshed", page, redrawn, tile)
end

function BattleBayDeluxe.draft_panel()
  local B = BattleBayDeluxe.draft
  B.ours = true
  pcall(UpdateTeamNameText, B.TEAM, true)
  local ok, err = pcall(UpdateFormation, B.TEAM, true)
  B.ours = false
  if not ok then
    BattleBayDeluxe.draft_log("panel error", tostring(err))
  end
end

-- Goes back from the panel (BattleBayDeluxe.draft_panel).
function BattleBayDeluxe.draft_panel_back()
  local B = BattleBayDeluxe.draft
  if not BattleBayDeluxe.draft_free() or B.side ~= false then
    BattleBayDeluxe.draft_panel()
    return
  end
  B.ours = true
  local p1 = B.drawn[true]
  if p1 ~= nil and p1 ~= 0 then
    pcall(UpdateTeamNameText, p1, true)
    pcall(UpdateFormation, p1, true)
  end
  pcall(UpdateTeamNameText, B.TEAM, false)
  local ok, err = pcall(UpdateFormation, B.TEAM, false)
  B.ours = false
  if not ok then
    BattleBayDeluxe.draft_log("panel error (right)", tostring(err))
  end
end

function BattleBayDeluxe.draft_start(tile)
  local B = BattleBayDeluxe.draft
  local ok, phase = BattleBayDeluxe.draft_info()
  if not ok then
    BattleBayDeluxe.draft_log("no loader draft: the Draft tile does nothing")
    return
  end
  B.tile = tile
  B.used = true
  if phase >= 2 and BattleBayDeluxe.draft_free() then
    -- Decides the tile automatically in a free match with a complete draft.
    B.autoDecide = true
    B.refresh = 1
    return
  end
  if phase == 2 then
    -- Handles a tile that was already drafted (back from the difficulty window).
    B.bypass = true
    pcall(OnDecideFocus, B.GRID, tile)
    B.bypass = false
    return
  end
  if phase ~= 1 and not BattleBayDeluxe.draft_free() then
    -- The Campaign's Draft opens the filter panel first; its start button calls draft_begin.
    B.filterTile = tile
    B.filterCo = coroutine.create(BattleBayDeluxe.draft_filters_then_begin)
    BattleBayDeluxe.draft_filters_step()
    return
  end
  BattleBayDeluxe.draft_begin(tile, phase ~= 1, false)
end

-- Begins (fresh) or resumes the Draft on `tile`; `filtered` applies the panel's filters.
function BattleBayDeluxe.draft_begin(tile, fresh, filtered)
  local B = BattleBayDeluxe.draft
  if fresh then
    local okb, total = funcLuaCommand(B.BEGIN, filtered and 1 or 0)
    if okb ~= true then
      BattleBayDeluxe.draft_log("begin refused by the loader")
      BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(B.TXT_ERROR))
      return
    end
    BattleBayDeluxe.draft_log("begin", tile, total)
  end
  if not BattleBayDeluxe.draft_load_slots() then
    BattleBayDeluxe.draft_log("no slots from the loader")
    funcLuaCommand(B.ABANDON)
    return
  end
  B.refresh = nil
  B.mode = "pitch"
  B.sel = 0
  B.cands = {}
  BattleBayDeluxe.draft_screen_on()
  BattleBayDeluxe.draft_open()
  BattleBayDeluxe.draft_panel()
  BattleBayDeluxe.draft_draw_pitch()
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
  B.probe = B.PROBE_FRAMES
  BattleBayDeluxe.draft_mouse_open()
  BattleBayDeluxe.draft_log("screen", #B.slots, "slots, formation", B.formation)
  B.quitTo = nil
  if not (fresh and BattleBayDeluxe.draft_formation_open("start")) then
    BattleBayDeluxe.draft_formation_render()
  end
end

-- nearest slot in the direction (dx, dy) (screen, y up) from the selected one
function BattleBayDeluxe.draft_move(dx, dy)
  local B = BattleBayDeluxe.draft
  if B.ptr ~= nil then
    B.ptr.key_step() -- the keys own the selection until the pointer really moves again
  end
  if B.mode == "formation" then
    if dx ~= 0 then
      BattleBayDeluxe.draft_formation_move(dx)
    end
    return
  end
  if B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      return -- the pack is still being turned (Enter shows all)
    end
    -- Treats the candidates as a row on the pack's band.
    local d = (dy ~= 0) and -dy or dx
    if d ~= 0 then
      BattleBayDeluxe.draft_select_candidate(math.max(0, math.min(#B.cands - 1, B.csel + d)))
    end
    return
  end
  if B.mode ~= "pitch" then
    return
  end
  local from = B.where[B.sel]
  if from == nil then
    return
  end
  local layer, to = BattleBayDeluxe.draft_focus_move(from[1], from[2], #B.slots, dx, dy)
  for k = 0, #B.slots - 1 do
    local w = B.where[k]
    if layer ~= nil and w ~= nil and w[1] == layer and w[2] == to then
      BattleBayDeluxe.draft_select_slot(k)
      return
    end
  end
end

function BattleBayDeluxe.draft_next_empty(from)
  local B = BattleBayDeluxe.draft
  for d = 0, #B.slots - 1 do
    local k = (from + d) % #B.slots
    if B.slots[k + 1].param == 0 then
      return k
    end
  end
  return from
end

-- Handles Enter.
function BattleBayDeluxe.draft_decide()
  local B = BattleBayDeluxe.draft
  if B.mode == "formation" then
    BattleBayDeluxe.draft_formation_confirm()
    return
  end
  if B.mode == "pitch" then
    if BattleBayDeluxe.draft_filled() >= #B.slots then
      B.mode = "start"
    elseif B.slots[B.sel + 1].param == 0 then
      local r = table.pack(funcLuaCommand(B.CANDS, B.sel))
      if r[1] ~= true then
        BattleBayDeluxe.draft_log("no candidates for slot", B.sel)
        return
      end
      B.k = r[2]
      B.cands = {}
      for i = 0, (r[5] or 0) - 1 do
        B.cands[i + 1] = {param = r[6 + 3 * i], pos = r[7 + 3 * i], team = r[8 + 3 * i]}
      end
      B.mode = "cands"
      B.csel = 0
      BattleBayDeluxe.draft_pack_start()
    else
      return
    end
  elseif B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      BattleBayDeluxe.draft_pack_done(true) -- Enter during the animation: all 5 at once
      BattleBayDeluxe.draft_show_guide()
      return
    end
    local ok, done, slot, param = funcLuaCommand(B.PICK, B.k, B.csel)
    if ok ~= true then
      BattleBayDeluxe.draft_log("pick refused", B.k, B.csel)
      BattleBayDeluxe.draft_exit(true)
      BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(B.TXT_ERROR))
      return
    end
    B.slots[B.k + 1].param = param
    BattleBayDeluxe.draft_draw_slot(B.k)
    BattleBayDeluxe.draft_pack_outro(B.k, B.csel) -- the card flies to its place, the screen comes back
    B.mode = done and "start" or "pitch"
    for i = 0, 4 do
      BattleBayDeluxe.draft_draw_candidate(i)
    end
    B.sel = B.k
  elseif B.mode == "start" then
    BattleBayDeluxe.draft_finish()
    return
  elseif B.mode == "quit" then
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 4235359837 --[[decide]])
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
end

-- Handles Back.
function BattleBayDeluxe.draft_back()
  local B = BattleBayDeluxe.draft
  if B.mode == "formation" then
    BattleBayDeluxe.draft_formation_back()
    return
  end
  if B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      BattleBayDeluxe.draft_pack_done(true) -- Back during the animation: all 5 at once too
      return
    end
    -- the 5 of a slot cannot be left without a pick (no reroll by backing out)
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, B.SE_NG)
    local rec = B.slots[B.k + 1]
    BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(B.TXT_POS[rec and rec.pos or 0]) .. ": " .. BattleBayDeluxe.draft_text(B.TXT_PICK_ONE, "Elige uno de los 5"))
    BattleBayDeluxe.draft_log("pick open: back refused", B.k)
    return
  elseif B.mode == "quit" then
    return
  elseif B.mode == "pitch" then
    BattleBayDeluxe.draft_quit_open(nil)
    return
  elseif B.mode == "start" then
    B.mode = "pitch"
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 202039849 --[[back]])
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
end

function BattleBayDeluxe.draft_quit_ask()
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(1558704558, B.MENU, false)
  local text = BattleBayDeluxe.draft_text(B.TXT_QUIT_ASK, "¿Quieres abandonar el draft?")
  local yes = VRFW.question.ask(text, {on_open = function() funcLuaCommand(2529383714, 1) end}) -- the cursor starts on No
  funcLuaMenuCommand(1558704558, B.MENU, true)
  return yes
end

function BattleBayDeluxe.draft_quit_open(to)
  local B = BattleBayDeluxe.draft
  B.mode = "quit"
  B.quitTo = to
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 202039849 --[[back]])
  B.quitCo = coroutine.create(BattleBayDeluxe.draft_quit_ask)
  BattleBayDeluxe.draft_quit_step()
end

function BattleBayDeluxe.draft_quit_step()
  local B = BattleBayDeluxe.draft
  if B.quitCo == nil then
    return
  end
  local ok, yes = coroutine.resume(B.quitCo)
  if ok and coroutine.status(B.quitCo) ~= "dead" then
    return
  end
  B.quitCo = nil
  if not ok then
    BattleBayDeluxe.draft_log("quit window error", tostring(yes))
    pcall(funcLuaMenuCommand, 1558704558, B.MENU, true)
    yes = false
  end
  if B.mode ~= "quit" then
    return
  end
  if yes == true then
    BattleBayDeluxe.draft_log("abandoned with", BattleBayDeluxe.draft_filled(), "picks")
    BattleBayDeluxe.draft_exit(true)
    return
  end
  B.mode = B.quitTo or "pitch"
  B.quitTo = nil
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
end

-- Leaves the Draft screen.
function BattleBayDeluxe.draft_exit(abandon)
  local B = BattleBayDeluxe.draft
  if abandon then
    funcLuaCommand(B.ABANDON)
  end
  BattleBayDeluxe.draft_close_layers()
  BattleBayDeluxe.draft_grid_back()
  BattleBayDeluxe.draft_panel_back()
end

-- Finishes the draft once 16 players are drafted and confirmed.
function BattleBayDeluxe.draft_finish()
  local B = BattleBayDeluxe.draft
  BattleBayDeluxe.draft_close_layers()
  if BattleBayDeluxe.draft_free() then
    -- Free match: decides the tile directly.
    BattleBayDeluxe.draft_log("complete: the tile's decide (free match)")
    BattleBayDeluxe.draft_grid_back()
    BattleBayDeluxe.draft_panel_back()
    B.autoDecide = true
    return
  end
  BattleBayDeluxe.draft_panel()
  BattleBayDeluxe.draft_log("complete: difficulty window")
  B.bypass = true
  local ok, err = pcall(OnDecideFocus, B.GRID, B.tile)
  B.bypass = false
  if not ok then
    BattleBayDeluxe.draft_log("difficulty window error", tostring(err))
  end
end

function BattleBayDeluxe.draft_step()
  local B = BattleBayDeluxe.draft
  if B.pk ~= nil then
    local ok, err = pcall(BattleBayDeluxe.draft_pack_step)
    if not ok then
      BattleBayDeluxe.draft_logger().once("pack_error", "pack error", tostring(err))
      pcall(BattleBayDeluxe.draft_pack_end)
      if B.mode == "cands" then
        for i = 0, 4 do
          pcall(BattleBayDeluxe.draft_draw_candidate, i) -- the plain cards back (no pack)
        end
        pcall(BattleBayDeluxe.draft_cursor)
      end
    end
  end
  if B.quitCo ~= nil then
    BattleBayDeluxe.draft_quit_step()
  end
  if B.filterCo ~= nil then
    BattleBayDeluxe.draft_filters_step()
  end
  if BattleBayDeluxe.draft_formation.dirty and B.mode ~= nil then
    local okf, errf = pcall(BattleBayDeluxe.draft_formation_render)
    if not okf then
      BattleBayDeluxe.draft_logger().once("formation_error", "formation step error", tostring(errf))
    end
  end
  local okm, errm = pcall(BattleBayDeluxe.draft_mouse)
  if not okm then
    B.polled = false
    BattleBayDeluxe.draft_logger().once("mouse_error", "mouse error", tostring(errm))
  end
  if B.refresh ~= nil then
    B.refresh = B.refresh - 1
    if B.refresh <= 0 then
      B.refresh = nil
      local ok, err = pcall(BattleBayDeluxe.draft_refresh)
      if not ok then
        BattleBayDeluxe.draft_logger().once("refresh_error", "refresh error", tostring(err))
      end
      if B.autoDecide then
        -- Free match: clears the automatic decision.
        B.autoDecide = false
        local done = VRFW.host.command(B.DECIDE, B.tile)
        BattleBayDeluxe.draft_log("free match decide", tostring(done), B.tile)
      end
    end
  end
  if B.reapply ~= nil and B.mode ~= nil then
    B.reapply = B.reapply - 1
    for k = 0, #B.slots - 1 do
      local w = B.where[k]
      if w ~= nil and B.slots[k + 1].param == 0 and B.ready[w[1] .. ":" .. w[2]] then
        BattleBayDeluxe.draft_rehide(w[1], w[2])
      end
    end
    if B.reapply <= 0 then
      B.reapply = nil
    end
  end
  if B.probe ~= nil and B.mode ~= nil then
    B.probe = B.probe - 1
    if B.probe <= 0 then
      B.probe = nil
      local ok, err = pcall(BattleBayDeluxe.draft_probe)
      if not ok then
        BattleBayDeluxe.draft_logger().once("probe_error", "probe error", tostring(err))
      end
    end
  end
end

BattleBayDeluxe.draft_formation = {
  QUAD = @crc:battlebaydeluxe_fm_quad@, TXT = @crc:battlebaydeluxe_fm_txt@, N_QUAD = 84, N_TXT = 20,
  FORM_INFO = @crc:CMND_GET_SOCCER_FORMATION_INFO@, TEXT_OF = 297699480,
  SPR_BAND = @crc:bbd_pk_band@, SPR_EDGE = @crc:bbd_pk_edge@, SPR_CARD = @crc:bbd_pk_card@, SPR_SEL = @crc:bbd_pk_sel@,
  STYLE_ON_CHOSEN = 2029954615 --[[fs_28_k_cc_2d0_001: centred dark, no outline, on the chosen card's gold]],
  SPR_FRAME = @crc:bbd_pk_frame@, SPR_PITCH = @crc:bbd_pk_pitch@, SPR_DOT = @crc:bbd_pk_flash@,
  -- Quad instance indexes.
  I_BAND = 0, I_EDGE = 1, I_FRAME = 2, I_CARD = 3, I_PITCH = 9, I_DOT = 15,
  -- Text instance indexes.
  T_CARD = 0, T_ARROW = 12, T_PANEL = 14,
  PRIO_STRIP = 750, PRIO_TEXT = 760, PRIO_BOARD = 701,
  -- Layout of the strip (screen pixels, y down).
  STRIP_TOP = 918, STRIP_Y = 1000, VISIBLE = 5, CARD_X0 = 346, CARD_DX = 307, CARD_W = 288, CARD_H = 116,
  FRAME_PAD = 5, MINI_DX = -96, MINI_W = 74, MINI_H = 92, DOT = 9, DOT_PAD = 4, TEXT_DX = 45, TEXT_W = 186,
  LINE1_DY = -25, LINE2_DY = 22, NUM_SCALE = 1.0, NAME_SCALE = 0.78, ARROW_X = 22, ARROW_SCALE = 1.2,
  -- Layout of the board's labels.
  PANEL_X = 215, PANEL_W = 400, PANEL_Y = {590, 637, 690}, PANEL_SCALE = {0.8, 1.1, 0.8},
  -- state
  list = nil, total = 0, sel = 0, from = nil, saved = 0, info = {}, spr = {}, texts = {}, ready = {}, dirty = false,
  opened = false, guideHidden = false,
}

-- Draws a quad at screen pixels (y down) with width w, height h and alpha.
function BattleBayDeluxe.draft_quad_draw(layer, cache, i, x, y, w, h, spr, alpha)
  local P = BattleBayDeluxe.draft_pack
  if cache[i] ~= spr then
    funcLuaMenuCommand(P.SPRITE, layer, P.ART, spr, P.NODE_QUAD, 0, i)
    cache[i] = spr
  end
  funcLuaMenuCommand(P.VISIBLE, layer, i, true)
  funcLuaMenuCommand(P.SCALE, layer, w / P.Q, h / P.Q, 1, i)
  funcLuaMenuCommand(P.POS, layer, x, -y, 0, i)
  funcLuaMenuCommand(P.MODEL_ALPHA, layer, i, 0, alpha)
end

function BattleBayDeluxe.draft_text_set(layer, i, s, style)
  local P = BattleBayDeluxe.draft_pack
  funcLuaMenuCommand(P.TEXT_STYLE, layer, i, P.TXT_ON, style)
  funcLuaMenuCommand(P.TEXT, layer, P.TXT_ON, s, i)
  funcLuaMenuCommand(P.TEXT, layer, P.TXT_OFF, "", i)
  funcLuaMenuCommand(P.TEXT_VISIBLE, layer, P.TXT_ON, true, i)
  funcLuaMenuCommand(P.TEXT_VISIBLE, layer, P.TXT_OFF, false, i)
end

function BattleBayDeluxe.draft_formation_quad(i, x, y, w, h, spr)
  local F, P = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft_pack
  if spr == nil or w <= 0.5 or h <= 0.5 then
    funcLuaMenuCommand(P.VISIBLE, F.QUAD, i, false)
    return
  end
  BattleBayDeluxe.draft_quad_draw(F.QUAD, F.spr, i, x, y, w, h, spr, 1)
end

function BattleBayDeluxe.draft_formation_text(i, s, x, y, scale, style)
  local F, P = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft_pack
  if s == nil or s == "" then
    funcLuaMenuCommand(P.VISIBLE, F.TXT, i, false)
    return
  end
  funcLuaMenuCommand(P.VISIBLE, F.TXT, i, true)
  funcLuaMenuCommand(P.POS, F.TXT, x, -y, 0, i)
  funcLuaMenuCommand(P.SCALE, F.TXT, scale, scale, 1, i)
  style = style or P.STYLE
  local shown = tostring(style) .. ":" .. s
  if F.texts[i] ~= shown then
    BattleBayDeluxe.draft_text_set(F.TXT, i, s, style)
    F.texts[i] = shown
  end
  funcLuaMenuCommand(P.TEXT_ALPHA, F.TXT, i, P.TXT_ON, 1)
end

-- Sets the draw priorities of the layers (OnSetupLayer and OnOpenLayer).
function BattleBayDeluxe.draft_formation_priority(layer, i)
  local F, P = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft_pack
  local prio = F.PRIO_TEXT
  if layer == F.QUAD then
    prio = F.PRIO_STRIP + ((i == F.I_BAND and 0) or (i < F.I_CARD and 1) or (i < F.I_PITCH and 2) or (i < F.I_DOT and 3)
      or 4)
    F.spr[i] = nil
  elseif i >= F.T_PANEL then
    prio = F.PRIO_BOARD
  end
  if layer == F.TXT then
    F.texts[i] = nil
  end
  funcLuaMenuCommand(P.PRIO, layer, i, prio, true)
  funcLuaMenuCommand(P.VISIBLE, layer, i, false)
  F.ready[layer .. ":" .. i] = true
  F.dirty = true
end

function BattleBayDeluxe.draft_formation_load()
  local F, B = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft
  local list, total, current = {}, nil, 0
  local start = 0
  repeat
    local r = table.pack(funcLuaCommand(B.FORMATIONS, start))
    if r[1] ~= true or type(r[2]) ~= "number" then
      return false
    end
    total, current = r[2], type(r[3]) == "number" and r[3] or 0
    for j = 4, r.n do
      list[#list + 1] = r[j]
    end
    start = start + math.max(1, r.n - 3)
  until #list >= total or r.n <= 3
  F.list, F.total, F.sel = list, #list, 0
  for j, id in ipairs(list) do
    if id == current then
      F.sel = j - 1
    end
  end
  return #list > 0
end

-- Reads a formation's card look once per formation.
function BattleBayDeluxe.draft_formation_info(id)
  local F, B = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft
  local inf = F.info[id]
  if inf ~= nil then
    return inf
  end
  local n, list, dots = {0, 0, 0, 0}, {}, {}
  for slot = 0, 10 do
    local ok, pos, x, y = funcLuaCommand(B.PLACE, id, slot)
    if ok == true and type(pos) == "number" then
      if pos >= 1 and pos <= 4 then
        n[pos] = n[pos] + 1
      end
      list[#list + 1] = {slot, slot, pos == 1, x or 0, y or 0}
    end
  end
  -- Draws the dots.
  local L = BattleBayDeluxe.draft_layout
  for _, at in pairs(BattleBayDeluxe.draft_pitch_layout(BattleBayDeluxe.draft_rule_places(id, list))) do
    dots[#dots + 1] = {(at[1] - L.BOX_L) / (L.BOX_R - L.BOX_L), (at[2] - L.BOX_T) / (L.BOX_B - L.BOX_T)}
  end
  local name = BattleBayDeluxe.draft_formation_name(id):gsub("^%s*%d+%-%d+%-%d+%-?%d*%s*", "")
  inf = {nums = string.format("%d-%d-%d", n[4], n[3], n[2]), name = name, dots = dots}
  F.info[id] = inf
  return inf
end

-- a formation's game name (formation info 7 -> its text id -> the text), "" when unknown
function BattleBayDeluxe.draft_formation_name(id)
  local F = BattleBayDeluxe.draft_formation
  local has, tid = VRFW.host.command(F.FORM_INFO, 7, id)
  if not (has == true and type(tid) == "number") then
    return ""
  end
  local s = VRFW.host.command(F.TEXT_OF, tid)
  return (type(s) == "string") and s or ""
end

-- Returns the first card shown.
function BattleBayDeluxe.draft_formation_first()
  local F = BattleBayDeluxe.draft_formation
  return math.max(0, math.min(F.total - F.VISIBLE, F.sel - 1))
end

-- Returns the place of visible card j (0-based).
function BattleBayDeluxe.draft_formation_spot(j)
  local F = BattleBayDeluxe.draft_formation
  return F.CARD_X0 + j * F.CARD_DX, F.STRIP_Y
end

function BattleBayDeluxe.draft_formation_fit(s, scale, w)
  local chars = #(s:gsub("[\128-\191]", ""))
  return math.min(scale, (w or BattleBayDeluxe.draft_formation.TEXT_W) / math.max(1, chars * 13))
end

-- the strip (formation step only)
function BattleBayDeluxe.draft_formation_strip(show)
  local F = BattleBayDeluxe.draft_formation
  if not show or F.list == nil then
    for i = 0, F.I_DOT + 6 * 11 - 1 do
      BattleBayDeluxe.draft_formation_quad(i, 0, 0, 0, 0, nil)
    end
    for i = F.T_CARD, F.T_ARROW + 1 do
      BattleBayDeluxe.draft_formation_text(i, "", 0, 0, 1)
    end
    return
  end
  local h = 1080 - F.STRIP_TOP
  BattleBayDeluxe.draft_formation_quad(F.I_BAND, 960, F.STRIP_TOP + h / 2, 1920, h, F.SPR_BAND)
  BattleBayDeluxe.draft_formation_quad(F.I_EDGE, 960, F.STRIP_TOP, 1920, 4, F.SPR_EDGE)
  local first = BattleBayDeluxe.draft_formation_first()
  local framed = false
  for j = 0, F.VISIBLE - 1 do
    local idx = first + j
    local id = F.list[idx + 1]
    local base = F.I_DOT + j * 11
    if id == nil then
      BattleBayDeluxe.draft_formation_quad(F.I_CARD + j, 0, 0, 0, 0, nil)
      BattleBayDeluxe.draft_formation_quad(F.I_PITCH + j, 0, 0, 0, 0, nil)
      for d = 0, 10 do
        BattleBayDeluxe.draft_formation_quad(base + d, 0, 0, 0, 0, nil)
      end
      BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j, "", 0, 0, 1)
      BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j + 1, "", 0, 0, 1)
    else
      local inf = BattleBayDeluxe.draft_formation_info(id)
      local x, y = BattleBayDeluxe.draft_formation_spot(j)
      local on = idx == F.sel
      if on then
        BattleBayDeluxe.draft_formation_quad(F.I_FRAME, x, y, F.CARD_W + 2 * F.FRAME_PAD, F.CARD_H + 2 * F.FRAME_PAD, F.SPR_FRAME)
        framed = true
      end
      BattleBayDeluxe.draft_formation_quad(F.I_CARD + j, x, y, F.CARD_W, F.CARD_H, on and F.SPR_SEL or F.SPR_CARD)
      local px = x + F.MINI_DX
      BattleBayDeluxe.draft_formation_quad(F.I_PITCH + j, px, y, F.MINI_W, F.MINI_H, F.SPR_PITCH)
      local pad = F.DOT / 2 + F.DOT_PAD
      local left, top = px - F.MINI_W / 2 + pad, y - F.MINI_H / 2 + pad
      local w, hh = F.MINI_W - 2 * pad, F.MINI_H - 2 * pad
      for d = 0, 10 do
        local dot = inf.dots[d + 1]
        if dot ~= nil then
          BattleBayDeluxe.draft_formation_quad(base + d, left + w * math.max(0, math.min(1, dot[1])),
                            top + hh * math.max(0, math.min(1, dot[2])), F.DOT, F.DOT, F.SPR_DOT)
        else
          BattleBayDeluxe.draft_formation_quad(base + d, 0, 0, 0, 0, nil)
        end
      end
      local tx = x + F.TEXT_DX
      local style = on and F.STYLE_ON_CHOSEN or nil
      if inf.name ~= "" then
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j, inf.nums, tx, y + F.LINE1_DY, F.NUM_SCALE, style)
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j + 1, inf.name, tx, y + F.LINE2_DY, BattleBayDeluxe.draft_formation_fit(inf.name, F.NAME_SCALE), style)
      else
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j, inf.nums, tx, y, F.NUM_SCALE, style)
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j + 1, "", 0, 0, 1)
      end
    end
  end
  if not framed then
    BattleBayDeluxe.draft_formation_quad(F.I_FRAME, 0, 0, 0, 0, nil)
  end
  BattleBayDeluxe.draft_formation_text(F.T_ARROW, first > 0 and "<" or "", F.ARROW_X, F.STRIP_Y, F.ARROW_SCALE)
  BattleBayDeluxe.draft_formation_text(F.T_ARROW + 1, first + F.VISIBLE < F.total and ">" or "", 1920 - F.ARROW_X, F.STRIP_Y, F.ARROW_SCALE)
end

-- Sets the board's labels.
function BattleBayDeluxe.draft_formation_board(show)
  local F, B = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft
  local line = ""
  if show and B.formation ~= 0 then
    local inf = BattleBayDeluxe.draft_formation_info(B.formation)
    line = inf.name ~= "" and (inf.nums .. " " .. inf.name) or inf.nums
  end
  local texts = {"", line, ""}
  for j = 1, 3 do
    local s = show and texts[j] or ""
    BattleBayDeluxe.draft_formation_text(F.T_PANEL + j - 1, s, F.PANEL_X, F.PANEL_Y[j], BattleBayDeluxe.draft_formation_fit(s, F.PANEL_SCALE[j], F.PANEL_W))
  end
end

function BattleBayDeluxe.draft_formation_render()
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  F.dirty = false
  if not F.opened then
    return
  end
  local strip = B.mode == "formation" or (B.mode == "quit" and B.quitTo == "formation")
  BattleBayDeluxe.draft_formation_strip(strip)
  BattleBayDeluxe.draft_formation_board(B.mode ~= nil and not strip)
end

-- Hides the guide bar while the strip is up (entries emptied, text cleared, every instance hidden).
function BattleBayDeluxe.draft_formation_guide(show)
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  if show == not F.guideHidden then
    return
  end
  F.guideHidden = not show
  if not show then
    VRFW.footer_prompts.set(nil, B.MENU, {}, {guide = B.GUIDE, declared = false})
    pcall(BattleBayDeluxe.draft_guide, "")
  elseif UpdateButtonGuide ~= nil then
    pcall(UpdateButtonGuide, B.MENU, B.GUIDE, false)
  end
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.GUIDE)
  BattleBayDeluxe.draft_layer_visible(B.GUIDE, math.max(1, type(n) == "number" and n or 1), show)
end

-- the pitch laid out for formation id at once (the empty places' colour too), the script untouched until Enter
function BattleBayDeluxe.draft_formation_preview(id)
  local B = BattleBayDeluxe.draft
  B.formation = id
  for k = 0, #B.slots - 1 do
    local rec = B.slots[k + 1]
    if rec.field then
      local ok, pos, x, y = funcLuaCommand(B.PLACE, id, rec.slot)
      if ok == true and type(x) == "number" and type(y) == "number" then
        rec.pos, rec.x, rec.y = pos, x, y
      end
    end
  end
  BattleBayDeluxe.draft_place_field()
  BattleBayDeluxe.draft_draw_pitch()
end

-- Opens the formation step.
function BattleBayDeluxe.draft_formation_open(from)
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  if not BattleBayDeluxe.draft_formation_load() then
    BattleBayDeluxe.draft_log("no formation list: the team's own formation")
    return false
  end
  F.from, F.saved = from, B.formation
  B.mode = "formation"
  BattleBayDeluxe.draft_formation_guide(false)
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_formation_preview(F.list[F.sel + 1])
  BattleBayDeluxe.draft_formation_render()
  BattleBayDeluxe.draft_log("formation step", from, F.total, "formations")
  return true
end

-- Closes the formation step.
function BattleBayDeluxe.draft_formation_close()
  local B = BattleBayDeluxe.draft
  B.mode = "pitch"
  BattleBayDeluxe.draft_formation.from = nil
  BattleBayDeluxe.draft_formation_guide(true)
  BattleBayDeluxe.draft_draw_pitch()
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
  BattleBayDeluxe.draft_formation_render()
end

-- Left / Right on the strip
function BattleBayDeluxe.draft_formation_move(d)
  local F = BattleBayDeluxe.draft_formation
  local to = math.max(0, math.min(F.total - 1, F.sel + d))
  if to == F.sel then
    return
  end
  BattleBayDeluxe.draft_formation_select(to)
end

function BattleBayDeluxe.draft_formation_select(to)
  local F = BattleBayDeluxe.draft_formation
  if to == F.sel or F.list == nil or F.list[to + 1] == nil then
    return
  end
  F.sel = to
  BattleBayDeluxe.draft_formation_preview(F.list[to + 1])
  BattleBayDeluxe.draft_formation_render()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2500047763 --[[sy0005]])
end

-- Handles Enter in the formation step.
function BattleBayDeluxe.draft_formation_confirm()
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  local id = F.list and F.list[F.sel + 1]
  if id == nil or funcLuaCommand(B.SET_FORMATION, id) ~= true then
    BattleBayDeluxe.draft_log("formation refused", tostring(id))
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, B.SE_NG)
    return
  end
  BattleBayDeluxe.draft_load_slots()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 4235359837 --[[decide]])
  B.sel = BattleBayDeluxe.draft_next_empty(0)
  BattleBayDeluxe.draft_formation_close()
  BattleBayDeluxe.draft_log("formation", id)
end

-- Handles Back in the formation step.
function BattleBayDeluxe.draft_formation_back()
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  if F.from == "start" then
    BattleBayDeluxe.draft_quit_open("formation")
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 202039849 --[[back]])
  BattleBayDeluxe.draft_load_slots()
  BattleBayDeluxe.draft_formation_close()
end

-- open / close the step's layers with the Draft's
function BattleBayDeluxe.draft_formation_layers(open)
  local F = BattleBayDeluxe.draft_formation
  if open and not F.opened then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, F.QUAD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, F.TXT)
    F.opened = true
  elseif not open and F.opened then
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, F.QUAD)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, F.TXT)
    F.opened = false
    F.spr, F.texts, F.ready = {}, {}, {}
    BattleBayDeluxe.draft_formation_guide(true)
  end
end


--@lib vrfw_menu_kit.lua#Pointer

-- Runs when the screen is opened.
function BattleBayDeluxe.draft_mouse_open()
  local B = BattleBayDeluxe.draft
  local okc, on = VRFW.host.command(B.MOUSE)
  B.mouse = not (okc == true and on == false)
  if B.ptr == nil then
    B.ptr = VRFW.pointer.new()
  end
  B.ptr.reset()
  B.polled = false
  BattleBayDeluxe.draft_log("mouse " .. (B.mouse and "on" or "off (config.toml [draft] mouse)"))
end

function BattleBayDeluxe.draft_select_slot(k)
  local B = BattleBayDeluxe.draft
  if k == B.sel then
    return
  end
  B.sel = k
  BattleBayDeluxe.draft_cursor()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2500047763 --[[sy0005]])
end

function BattleBayDeluxe.draft_select_candidate(i)
  local B = BattleBayDeluxe.draft
  if i == B.csel then
    return
  end
  local old = B.csel
  B.csel = i
  BattleBayDeluxe.draft_draw_candidate(old)
  BattleBayDeluxe.draft_draw_candidate(i)
  BattleBayDeluxe.draft_cursor()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2500047763 --[[sy0005]])
end

-- Runs once the screen is turned.
function BattleBayDeluxe.draft_mouse_zones()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local Ptr = B.ptr
  Ptr.begin()
  if B.mode == "pitch" or B.mode == "start" then
    for k = 0, #B.slots - 1 do
      local w = B.where[k]
      if w ~= nil and B.ready[w[1] .. ":" .. w[2]] then
        local half = B.slots[k + 1].pos == B.POS_COACH and B.HALF_COACH or B.HALF_SLOT
        Ptr.inst(w[1], w[2], half[1], half[2], k)
      end
    end
  elseif B.mode == "formation" then
    local F = BattleBayDeluxe.draft_formation
    local first = BattleBayDeluxe.draft_formation_first()
    for j = 0, F.VISIBLE - 1 do
      if F.list ~= nil and F.list[first + j + 1] ~= nil then
        local x, y = BattleBayDeluxe.draft_formation_spot(j)
        Ptr.box(x, y, F.CARD_W / 2, F.CARD_H / 2, first + j)
      end
    end
  elseif B.mode == "cands" and not BattleBayDeluxe.draft_pack_busy() then
    local pk = B.pk
    for i = 0, #B.cands - 1 do
      if pk ~= nil and pk.phase == "pick" then
        local x, y = BattleBayDeluxe.draft_pack_spot(i, pk.n)
        local hw, hh = P.CARD_W * P.scale / 2, P.CARD_H * P.scale / 2
        Ptr.box(x + P.CARD_OX * P.scale, y + P.CARD_OY * P.scale - P.SEL_LIFT / 2, hw, hh + P.SEL_LIFT / 2, i)
      elseif pk == nil and B.ready[B.CARD .. ":" .. i] then
        Ptr.inst(B.CARD, i, B.HALF_CAND[1], B.HALF_CAND[2], i)
      end
    end
  end
end

-- Runs once per frame (Step) while the Draft screen takes input.
function BattleBayDeluxe.draft_mouse()
  local B = BattleBayDeluxe.draft
  local live = B.mouse and B.ptr ~= nil and B.quitCo == nil
    and (B.mode == "pitch" or B.mode == "start" or B.mode == "cands" or B.mode == "formation")
    and not (B.pk ~= nil and B.pk.phase == "outro")
  if not live then
    B.polled = false
    return
  end
  B.mouseDecided = false
  local Ptr = B.ptr
  if not B.polled then
    B.polled = true
    Ptr.reset()
    return
  end
  BattleBayDeluxe.draft_mouse_zones()
  local ev = Ptr.poll()
  if B.mode == "cands" and BattleBayDeluxe.draft_pack_busy() then
    if ev.click ~= nil or ev.miss then
      B.mouseDecided = true
      BattleBayDeluxe.draft_decide() -- a click during the deal: all 5 at once, as Enter
    end
    return
  end
  if ev.hover ~= nil then
    if B.mode == "formation" then
      BattleBayDeluxe.draft_formation_select(ev.hover)
    elseif B.mode == "cands" then
      BattleBayDeluxe.draft_select_candidate(ev.hover)
    else
      BattleBayDeluxe.draft_select_slot(ev.hover)
    end
  end
  if ev.click ~= nil then
    if B.mode == "formation" then
      BattleBayDeluxe.draft_formation_select(ev.click)
    elseif B.mode == "cands" then
      BattleBayDeluxe.draft_select_candidate(ev.click)
    else
      BattleBayDeluxe.draft_select_slot(ev.click)
    end
    B.mouseDecided = true
    BattleBayDeluxe.draft_decide()
    -- Forgets the pointer zones because the screen may change under the pointer (the pack, the pitch again).
    Ptr.forget()
  end
end


function BattleBayDeluxe.draft_pack_look()
  local P = BattleBayDeluxe.draft_pack
  if P.loaded then
    return
  end
  P.loaded = true
  local ok, r = pcall(function()
    return table.pack(funcLuaCommand(P.CMD))
  end)
  if not ok or type(r) ~= "table" or r[1] ~= true then
    BattleBayDeluxe.draft_log("pack look: defaults (no CMND_BATTLEBAYDELUXE_DRAFT_PACK answer)")
    return
  end
  local keys = {"intro", "deal", "deal_stagger", "flip", "settle", "flash", "gap", "suspense", "outro", "dim", "scale",
                "spacing", "se_open", "se_deal", "se_reveal", "se_best"}
  for i, k in ipairs(keys) do
    local v = r[i + 1]
    if type(v) == "number" then
      P[k] = v
    end
  end
  BattleBayDeluxe.draft_log("pack look", P.intro, P.flip, P.gap, P.dim, P.scale, P.spacing)
end

function BattleBayDeluxe.draft_pack_frames(sec)
  return math.max(1, math.floor(sec * BattleBayDeluxe.draft_pack.FPS + 0.5))
end

local function clamp01(u)
  if u < 0 then
    return 0
  elseif u > 1 then
    return 1
  end
  return u
end

local function ease_out_cubic(u)
  u = 1 - clamp01(u)
  return 1 - u * u * u
end

local function ease_out_back(u)
  u = clamp01(u) - 1
  local c = 1.70158
  return 1 + (c + 1) * u * u * u + c * u * u
end

function BattleBayDeluxe.draft_pack_se(id)
  if type(id) == "number" and id ~= 0 then
    VRFW.host.command(BattleBayDeluxe.draft_pack.SE, id)
  end
end

function BattleBayDeluxe.draft_pack_quad(i, x, y, w, h, spr, a)
  local P = BattleBayDeluxe.draft_pack
  if a <= 0.001 or w <= 0.5 or h <= 0.5 then
    funcLuaMenuCommand(P.VISIBLE, P.QUAD, i, false)
    return
  end
  BattleBayDeluxe.draft_quad_draw(P.QUAD, P.spr, i, x, y, w, h, spr, math.min(1, a))
end

function BattleBayDeluxe.draft_pack_text(i, s, x, y, scale, a)
  local P = BattleBayDeluxe.draft_pack
  if s == nil or s == "" or a <= 0.001 then
    funcLuaMenuCommand(P.VISIBLE, P.TXT, i, false)
    return
  end
  local pk = BattleBayDeluxe.draft.pk
  funcLuaMenuCommand(P.VISIBLE, P.TXT, i, true)
  funcLuaMenuCommand(P.POS, P.TXT, x, -y, 0, i)
  funcLuaMenuCommand(P.SCALE, P.TXT, scale, scale, 1, i)
  if pk == nil or pk.texts[i] ~= s then
    BattleBayDeluxe.draft_text_set(P.TXT, i, s, P.STYLE)
    if pk ~= nil then
      pk.texts[i] = s
    end
  end
  funcLuaMenuCommand(P.TEXT_ALPHA, P.TXT, i, P.TXT_ON, a)
end

-- every quad and text of the pack hidden
function BattleBayDeluxe.draft_pack_hide_all()
  local P = BattleBayDeluxe.draft_pack
  for i = 0, P.N_QUAD - 1 do
    VRFW.host.menu_command(P.VISIBLE, P.QUAD, i, false)
  end
  for i = 0, P.N_TXT - 1 do
    VRFW.host.menu_command(P.VISIBLE, P.TXT, i, false)
  end
  for i = 0, P.N_CREST - 1 do
    VRFW.host.menu_command(P.VISIBLE, P.CREST, i, false)
  end
end

-- a name's estimated width in px at scale 1
function BattleBayDeluxe.draft_pack_name_width(s)
  local units = 0
  for ch in s:gmatch("[^\128-\191][\128-\191]*") do
    units = units + (#ch >= 3 and 2 or 1)
  end
  return units * BattleBayDeluxe.draft_pack.GLYPH
end

-- Returns the row under card c, whose card centre is x.
function BattleBayDeluxe.draft_pack_row(c, x)
  local P = BattleBayDeluxe.draft_pack
  local w = BattleBayDeluxe.draft_pack_name_width(c.name)
  local row = P.spacing - P.ROW_MARGIN
  local room = c.crest and (row - P.ROW_CREST - P.ROW_GAP) or row
  c.ns = math.max(P.NAME_MIN, math.min(P.NAME_SCALE, room / math.max(1, w)))
  c.nx = x
  if c.crest then
    local nw = w * c.ns
    local left = x - (P.ROW_CREST + P.ROW_GAP + nw) / 2
    c.cx = left + P.ROW_CREST / 2
    c.nx = left + P.ROW_CREST + P.ROW_GAP + nw / 2
  end
end

-- Returns card c's crest at the start of a pack.
function BattleBayDeluxe.draft_pack_crest(c, x, y)
  local P = BattleBayDeluxe.draft_pack
  local i = c.i
  local team = c.team or 0
  local has, icon = false, 0
  if team ~= 0 and VRFW.team ~= nil then
    has, icon = VRFW.host.command(VRFW.team.TEAM_INFO, team, 6, 0)
  end
  c.crest = has == true and (icon or 0) ~= 0
  BattleBayDeluxe.draft_pack_row(c, x)
  funcLuaMenuCommand(P.VISIBLE, P.CREST, i, false)
  if not c.crest then
    if VRFW.team ~= nil then
      VRFW.team.emblem_reset(P.CREST, i, P.crests)
    end
    return
  end
  for _, m in ipairs(P.CREST_HIDE) do
    funcLuaMenuCommand(P.MESH_VISIBLE, P.CREST, m, false, i)
  end
  funcLuaMenuCommand(P.TEXT_VISIBLE, P.CREST, P.TXT_ON, false, i)
  funcLuaMenuCommand(P.TEXT_VISIBLE, P.CREST, P.TXT_OFF, false, i)
  local s = P.ROW_CREST / P.CREST_PX
  funcLuaMenuCommand(P.SCALE, P.CREST, s, s, 1, i)
  funcLuaMenuCommand(P.POS, P.CREST, c.cx - P.CREST_CX * s, -y, 0, i)
  VRFW.team.emblem(P.CREST, i, team, P.crests)
  c.wait, c.ca = P.CREST_WAIT, 0
end

-- Shows card c's crest at alpha a, as its name.
function BattleBayDeluxe.draft_pack_crest_show(c, a)
  local P = BattleBayDeluxe.draft_pack
  if not c.crest or c.ca == a then
    return
  end
  if a <= 0.001 then
    funcLuaMenuCommand(P.VISIBLE, P.CREST, c.i, false)
    c.ca = 0
    return
  end
  if c.wait > 0 then
    local loading = VRFW.host.menu_command(P.LOADING, P.CREST, c.i)
    if loading == true then
      c.wait = c.wait - 1
      return
    end
    c.wait = 0
  end
  if c.ca == 0 then
    funcLuaMenuCommand(P.VISIBLE, P.CREST, c.i, true)
  end
  funcLuaMenuCommand(P.MODEL_ALPHA, P.CREST, c.i, 0, a)
  c.ca = a
end

-- Sets the draw priorities of the pack layers (OnSetupLayer and OnOpenLayer).
function BattleBayDeluxe.draft_pack_priority(layer, i)
  local P = BattleBayDeluxe.draft_pack
  local prio = 740
  if layer == P.CREST then
    if VRFW.team ~= nil then
      VRFW.team.emblem_forget(layer, i, P.crests)
    end
  elseif layer == P.QUAD then
    if i == P.I_DIM then
      prio = 705
    elseif i == P.I_BAND then
      prio = 706
    elseif i < P.I_GLOW then
      prio = 707
    elseif i < P.I_FLASH then
      prio = 712
    elseif i < P.I_SCREEN then
      prio = 726
    else
      prio = 745
    end
    funcLuaMenuCommand(P.SPRITE, layer, P.ART, P.COL_DIM, P.NODE_QUAD, 0, i)
    P.spr[i] = P.COL_DIM
  end
  funcLuaMenuCommand(P.PRIO, layer, i, prio, true)
  funcLuaMenuCommand(P.VISIBLE, layer, i, false)
end

-- Computes the band's geometry for the look's card scale.
function BattleBayDeluxe.draft_pack_band()
  local P = BattleBayDeluxe.draft_pack
  local h = P.CARD_H * P.scale + 280
  return P.CY, h, P.CY - h / 2
end

function BattleBayDeluxe.draft_pack_spot(i, n)
  local P = BattleBayDeluxe.draft_pack
  return P.CX + (i - (n - 1) / 2) * P.spacing, P.CY
end

-- a candidate card at (x, y) screen px (y down), scale sx x sy
function BattleBayDeluxe.draft_pack_card(i, x, y, sx, sy)
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CARD, x, -y, 0, i)
  funcLuaMenuCommand(3362798188, B.CARD, i, math.max(0.001, sx), math.max(0.001, sy))
end

function BattleBayDeluxe.draft_pack_face(c, state)
  local B = BattleBayDeluxe.draft
  local i = c.i
  if c.state == state or not B.ready[B.CARD .. ":" .. i] then
    return
  end
  c.state = state
  if state == "none" then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
  elseif state == "back" then
    BattleBayDeluxe.draft_empty_card(B.CARD, i, nil, true)
  else
    BattleBayDeluxe.draft_filled_card(B.CARD, i, c.param, c.pos)
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_MODEL_ALPHA@, B.CARD, i, 0, 1)
end

-- Starts a new pack for the current candidates (B.cands).
function BattleBayDeluxe.draft_pack_start()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  BattleBayDeluxe.draft_pack_look()
  if B.pk ~= nil then
    BattleBayDeluxe.draft_pack_end()
  end
  local n = #B.cands
  local pk = {cards = {}, order = {}, f = 0, phase = "anim", texts = {}, best = nil, n = n}
  for i = 0, n - 1 do
    local p = B.cands[i + 1]
    local ok, r = VRFW.host.command(P.CHARA_INFO, p.param, 8)
    local rar = (ok and type(r) == "number") and r or 0
    local ok2, name = VRFW.host.command(P.CHARA_INFO, p.param, 0)
    name = (ok2 and type(name) == "string") and name or ""
    pk.cards[i + 1] = {i = i, param = p.param, pos = p.pos, team = p.team, rarity = rar, name = name, state = nil}
    pk.order[#pk.order + 1] = i + 1
    local cx, cy = BattleBayDeluxe.draft_pack_spot(i, n)
    BattleBayDeluxe.draft_pack_crest(pk.cards[i + 1], cx + P.CARD_OX * P.scale,
                       cy + (P.CARD_OY + P.CARD_H / 2) * P.scale + P.ROW_Y)
  end
  table.sort(pk.order, function(a, b)
    local ra, rb = pk.cards[a].rarity, pk.cards[b].rarity
    if ra ~= rb then
      return ra < rb
    end
    return a < b
  end)
  if n >= 2 then
    local last, prev = pk.cards[pk.order[n]], pk.cards[pk.order[n - 1]]
    if last.rarity > prev.rarity then
      pk.best = pk.order[n]
    end
  end
  -- the frame plan
  local F = BattleBayDeluxe.draft_pack_frames
  local intro, deal, stag = F(P.intro), F(P.deal), F(P.deal_stagger)
  local flip, settle, gap = F(P.flip), F(P.settle), F(P.gap)
  pk.intro = intro
  for i = 0, n - 1 do
    pk.cards[i + 1].deal = intro + i * stag
  end
  local t = intro + (n - 1) * stag + deal + F(P.PAUSE)
  for r, k in ipairs(pk.order) do
    if k == pk.best then
      t = t + F(P.suspense)
    end
    pk.cards[k].turn = t
    if r < n then
      t = t + gap
    end
  end
  pk.dealLen, pk.flip, pk.settle, pk.flash = deal, flip, settle, F(P.flash)
  pk.done = t + flip + settle
  -- Sets the band's title.
  local rec = B.slots[B.k + 1]
  pk.title = rec ~= nil and BattleBayDeluxe.draft_text(B.TXT_POS[rec.pos or 0]) or ""
  pk.cur = nil
  B.pk = pk
  for i = 0, P.N_QUAD - 1 do
    pcall(BattleBayDeluxe.draft_pack_priority, P.QUAD, i)
  end
  for i = 0, n - 1 do
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, B.CARD, i, P.CARD_PRIO, true)
    BattleBayDeluxe.draft_pack_face(pk.cards[i + 1], "none")
  end
  for i = n, 4 do
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
  end
  BattleBayDeluxe.draft_pack_se(P.se_open)
  BattleBayDeluxe.draft_log("pack", B.k, "cards", n, "best", tostring(pk.best and pk.cards[pk.best].param), "frames", pk.done)
  BattleBayDeluxe.draft_pack_render(false)
end

-- Renders the pack at its frame pk.f.
function BattleBayDeluxe.draft_pack_render(quiet)
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local pk = B.pk
  if pk == nil then
    return
  end
  local f, n, S = pk.f, pk.n, P.scale
  local cy, bh, btop = BattleBayDeluxe.draft_pack_band()
  -- the darkness and the band
  local u = ease_out_cubic(f / pk.intro)
  BattleBayDeluxe.draft_pack_quad(P.I_DIM, P.CX, P.CY, 2700, 1300, P.COL_DIM, P.dim * u)
  BattleBayDeluxe.draft_pack_quad(P.I_BAND, P.CX, cy, 2700, bh * u, P.COL_BAND, P.BAND_ALPHA * math.min(1, u * 1.5))
  local ew = 2200 * u
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE, P.CX, cy - bh * u / 2, ew, 4, P.COL_EDGE, u)
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE + 1, P.CX, cy + bh * u / 2, ew, 4, P.COL_EDGE, u)
  BattleBayDeluxe.draft_pack_text(0, pk.title, P.CX, btop + 46, 1.1, u)
  local screen = 0
  for k = 1, n do
    local c = pk.cards[k]
    local x, y = BattleBayDeluxe.draft_pack_spot(c.i, n)
    local best = k == pk.best
    local want, sx, sy, cx, cyy = "none", S, S, x, y
    local glow, flash = 0, 0
    if f >= c.deal then
      want = "back"
      local d = (f - c.deal) / pk.dealLen
      if d < 1 then
        local e = ease_out_cubic(d)
        cx = P.CX + (x - P.CX) * e
        cyy = 1180 + (y - 1180) * e
        local s = S * (0.55 + 0.45 * ease_out_back(d))
        sx, sy = s, s
      elseif f < c.turn and best and f >= c.turn - BattleBayDeluxe.draft_pack_frames(P.suspense) then
        -- the best card throbs while it waits
        local w = 1 + 0.05 * math.sin((f - c.turn) * 0.9)
        sx, sy = S * w, S * w
        glow = 0.5 * clamp01(1 - (c.turn - f) / BattleBayDeluxe.draft_pack_frames(P.suspense))
      end
      if c.deal == f and not quiet then
        BattleBayDeluxe.draft_pack_se(P.se_deal)
      end
    end
    if f >= c.turn then
      local v = (f - c.turn) / pk.flip
      local over = best and P.OVER_BEST or P.OVER
      if v < 1 then
        local o = v < 0.5 and (1 + 0.12 * v) or (1 + over * (2 * v - 1))
        sx = S * math.abs(math.cos(math.pi * v)) * o
        sy = S * o
        if v >= 0.5 then
          want = "face"
        end
      else
        want = "face"
        local w = (f - c.turn - pk.flip) / pk.settle
        local o = 1 + over * (1 - ease_out_cubic(w))
        sx, sy = S * o, S * o
      end
      if want == "face" then
        local tf = f - (c.turn + math.floor(pk.flip / 2))
        flash = 0.9 * (1 - clamp01(tf / pk.flash)) ^ 2
        glow = clamp01(tf / 12)
        if best then
          screen = math.max(screen, P.SCREEN_ALPHA * (1 - clamp01(tf / (pk.flash * 1.5))) ^ 2)
        end
        if c.state ~= "face" and not quiet then
          BattleBayDeluxe.draft_pack_se(best and P.se_best or P.se_reveal)
        end
      end
    end
    if pk.phase == "pick" then
      want, flash, glow = "face", 0, 1
      local on = c.i == B.csel
      local g = on and P.SEL_GROW or 1
      sx, sy, cx, cyy = S * g, S * g, x, y - (on and P.SEL_LIFT or 0)
      if on then
        glow = 1.6
      end
    end
    BattleBayDeluxe.draft_pack_face(c, want)
    c.x, c.y, c.s = cx, cyy, sy
    if want ~= "none" then
      BattleBayDeluxe.draft_pack_card(c.i, cx, cyy, sx, sy)
      if want == "back" then
        BattleBayDeluxe.draft_rehide(B.CARD, c.i) -- a late face load must not show through the back
      end
    end
    local cw, ch = P.CARD_W * S, P.CARD_H * S
    -- Draws no tile behind a plain card (GLOW_ALPHA 0).
    local gcol, ga = P.COL_GLOW, P.GLOW_ALPHA
    if best then
      gcol, ga = P.COL_GOLD, P.GOLD_ALPHA * (0.85 + 0.15 * math.sin(f * 0.15))
    end
    local gx, gy = cx + P.CARD_OX * sy, cyy + P.CARD_OY * sy
    BattleBayDeluxe.draft_pack_quad(P.I_GLOW + c.i, gx, gy, cw * 1.16, ch * 1.16, gcol, math.min(1, ga * glow))
    BattleBayDeluxe.draft_pack_quad(P.I_FLASH + c.i, gx, gy, cw * (1.25 - 0.25 * flash), ch * (1.25 - 0.25 * flash), P.COL_FLASH,
                      flash)
    local na = want == "face" and clamp01((f - c.turn - pk.flip) / 9) or 0
    if pk.phase == "pick" then
      na = 1
    end
    BattleBayDeluxe.draft_pack_text(1 + c.i, c.name, c.nx, y + P.CARD_OY * S + ch / 2 + P.ROW_Y, c.ns, na)
    BattleBayDeluxe.draft_pack_crest_show(c, na)
  end
  for i = n, 4 do
    BattleBayDeluxe.draft_pack_quad(P.I_GLOW + i, 0, 0, 0, 0, P.COL_GLOW, 0)
    BattleBayDeluxe.draft_pack_quad(P.I_FLASH + i, 0, 0, 0, 0, P.COL_FLASH, 0)
    BattleBayDeluxe.draft_pack_text(1 + i, "", 0, 0, 1, 0)
  end
  BattleBayDeluxe.draft_pack_quad(P.I_SCREEN, P.CX, P.CY, 2700, 1300, P.COL_SCREEN, screen)
  -- the skip line only while the cards are dealt and turned
  local hint = pk.phase ~= "pick" and BattleBayDeluxe.draft_text(P.TXT_SKIP, "Aceptar: mostrar todos") or ""
  BattleBayDeluxe.draft_pack_text(6, hint, P.CX, btop + bh + 44, 0.8, u * 0.85)
  if pk.phase == "pick" then
    BattleBayDeluxe.draft_pack_cursor()
  end
end

-- Draws the cursor arrow on the pack's focused card (pick phase).
function BattleBayDeluxe.draft_pack_cursor()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local pk = B.pk
  if pk == nil or pk.phase ~= "pick" then
    return
  end
  local c = pk.cards[B.csel + 1]
  if c == nil or c.x == nil then
    return
  end
  local s = c.s or P.scale
  local x = c.x + (P.CARD_OX - P.CARD_W / 2) * s - P.CUR_DX
  local y = c.y + (P.CARD_OY + P.CUR_DY) * s
  local key = math.floor(x + 0.5) .. ":" .. math.floor(y + 0.5)
  if pk.cur == key then
    return
  end
  pk.cur = key
  B.curMoved = true
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CURSOR, x, -y, 0, 0)
end

-- Runs when the animation is over (its end or a skip).
function BattleBayDeluxe.draft_pack_done(skipped)
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  if pk == nil or pk.phase ~= "anim" then
    return
  end
  pk.f = math.max(pk.f, pk.done)
  pk.phase = "pick"
  BattleBayDeluxe.draft_pack_render(true)
  BattleBayDeluxe.draft_cursor()
  if skipped then
    BattleBayDeluxe.draft_pack_se(BattleBayDeluxe.draft_pack.se_reveal)
    BattleBayDeluxe.draft_log("pack skipped")
  end
end

function BattleBayDeluxe.draft_pack_outro(k, i)
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  if pk == nil then
    return
  end
  pk.phase = "outro"
  pk.of = 0
  pk.olen = BattleBayDeluxe.draft_pack_frames(BattleBayDeluxe.draft_pack.outro)
  pk.pick = i
  pk.to = B.pos[k]
end

function BattleBayDeluxe.draft_pack_outro_render()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local pk = B.pk
  local u = clamp01(pk.of / pk.olen)
  local e = ease_out_cubic(u)
  local a = 1 - e
  local cy, bh, btop = BattleBayDeluxe.draft_pack_band()
  BattleBayDeluxe.draft_pack_quad(P.I_DIM, P.CX, P.CY, 2700, 1300, P.COL_DIM, P.dim * a)
  BattleBayDeluxe.draft_pack_quad(P.I_BAND, P.CX, cy, 2700, bh * a, P.COL_BAND, P.BAND_ALPHA * a)
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE, P.CX, cy - bh * a / 2, 2200 * a, 4, P.COL_EDGE, a)
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE + 1, P.CX, cy + bh * a / 2, 2200 * a, 4, P.COL_EDGE, a)
  BattleBayDeluxe.draft_pack_text(0, pk.title, P.CX, btop + 46, 1.1, a)
  BattleBayDeluxe.draft_pack_text(6, "", 0, 0, 1, 0)
  BattleBayDeluxe.draft_pack_quad(P.I_SCREEN, 0, 0, 0, 0, P.COL_SCREEN, 0)
  for k = 1, pk.n do
    local c = pk.cards[k]
    local x, y = BattleBayDeluxe.draft_pack_spot(c.i, pk.n)
    BattleBayDeluxe.draft_pack_quad(P.I_FLASH + c.i, 0, 0, 0, 0, P.COL_FLASH, 0)
    BattleBayDeluxe.draft_pack_text(1 + c.i, c.name, c.nx, y + (P.CARD_OY + P.CARD_H / 2) * P.scale + P.ROW_Y, c.ns, a)
    BattleBayDeluxe.draft_pack_crest_show(c, a)
    if c.i == pk.pick and pk.to ~= nil then
      local tx, ty = pk.to[1], -pk.to[2]
      local cx, cyy = x + (tx - x) * e, (y - P.SEL_LIFT) + (ty - (y - P.SEL_LIFT)) * e
      local land = B.SLOT_SCALE * P.LAND -- the large card lands at the small slot card's size
      local s = P.scale * P.SEL_GROW + (land - P.scale * P.SEL_GROW) * e
      BattleBayDeluxe.draft_pack_card(c.i, cx, cyy, s, s)
      BattleBayDeluxe.draft_pack_quad(P.I_GLOW + c.i, cx + P.CARD_OX * s, cyy + P.CARD_OY * s, P.CARD_W * s * 1.16,
                        P.CARD_H * s * 1.16, P.COL_EDGE, 0.5 * a)
    else
      local s = P.scale * (1 - 0.3 * e)
      BattleBayDeluxe.draft_pack_card(c.i, x, y, s, s)
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_MODEL_ALPHA@, B.CARD, c.i, 0, a)
      BattleBayDeluxe.draft_pack_quad(P.I_GLOW + c.i, 0, 0, 0, 0, P.COL_GLOW, 0)
    end
  end
end

-- Ends the pack.
function BattleBayDeluxe.draft_pack_end()
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  B.pk = nil
  BattleBayDeluxe.draft_pack_hide_all()
  if pk ~= nil then
    for k = 1, pk.n do
      local i = pk.cards[k].i
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_MODEL_ALPHA@, B.CARD, i, 0, 1)
      if B.mode ~= "cands" then
        VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
      end
    end
  end
end

-- one frame of the pack (Step)
function BattleBayDeluxe.draft_pack_step()
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  if pk == nil then
    return
  end
  if pk.phase == "anim" then
    pk.f = pk.f + 1
    if pk.f >= pk.done then
      BattleBayDeluxe.draft_pack_done(false)
    else
      BattleBayDeluxe.draft_pack_render(false)
    end
  elseif pk.phase == "pick" then
    pk.f = pk.f + 1
    BattleBayDeluxe.draft_pack_render(true) -- the best card's glow keeps breathing
  elseif pk.phase == "outro" then
    pk.of = pk.of + 1
    if pk.of >= pk.olen then
      BattleBayDeluxe.draft_pack_end()
    else
      BattleBayDeluxe.draft_pack_outro_render()
    end
  end
end

-- the animation runs (input = skip)
function BattleBayDeluxe.draft_pack_busy()
  local pk = BattleBayDeluxe.draft.pk
  return pk ~= nil and pk.phase == "anim"
end

do
  local step = Step
  function Step(...)
    local r = table.pack(step(...))
    BattleBayDeluxe.draft_step()
    return table.unpack(r, 1, r.n)
  end

  -- Sets up the Draft cards.
  local setup = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local r = table.pack(setup(a1, a2, ...))
    if a1 == BattleBayDeluxe.draft.SLOT or a1 == BattleBayDeluxe.draft.CARD then
      local ok, err = pcall(function()
        BattleBayDeluxe.draft_name(a1, a2)
        BattleBayDeluxe.draft_cursor_labels_off(a1, a2)
        funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, a1, a2, BattleBayDeluxe.draft.PRIO, true)
      end)
      if not ok then
        BattleBayDeluxe.draft_log("card setup error", tostring(err))
      end
    elseif a1 == BattleBayDeluxe.draft.ANCHOR then
      BattleBayDeluxe.draft_anchor_park(a2)
    elseif a1 == BattleBayDeluxe.draft_pack.QUAD or a1 == BattleBayDeluxe.draft_pack.TXT or a1 == BattleBayDeluxe.draft_pack.CREST then
      pcall(BattleBayDeluxe.draft_pack_priority, a1, a2)
    elseif a1 == BattleBayDeluxe.draft_formation.QUAD or a1 == BattleBayDeluxe.draft_formation.TXT then
      pcall(BattleBayDeluxe.draft_formation_priority, a1, a2)
    end
    return table.unpack(r, 1, r.n)
  end

  local open = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    local r = table.pack(open(a1, a2, ...))
    if a1 == BattleBayDeluxe.draft.SLOT or a1 == BattleBayDeluxe.draft.CARD then
      local ok, err = pcall(function()
        local B = BattleBayDeluxe.draft
        BattleBayDeluxe.draft_name(a1, a2) -- only if the setup did not (never twice)
        B.ready[a1 .. ":" .. a2] = true
        if a1 == B.SLOT then
          if B.slots[a2 + 1] ~= nil and B.mode ~= nil then
            BattleBayDeluxe.draft_draw_slot(a2)
          else
            funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
          end
        else
          BattleBayDeluxe.draft_draw_candidate(a2)
        end
        if B.shown == nil or (B.shown[1] == a1 and B.shown[2] == a2) then
          BattleBayDeluxe.draft_cursor()
        end
      end)
      if not ok then
        BattleBayDeluxe.draft_log("card open error", tostring(err))
      end
    elseif a1 == BattleBayDeluxe.draft.ANCHOR then
      BattleBayDeluxe.draft_anchor_park(a2)
    elseif (a1 == BattleBayDeluxe.draft_pack.QUAD or a1 == BattleBayDeluxe.draft_pack.TXT or a1 == BattleBayDeluxe.draft_pack.CREST)
        and BattleBayDeluxe.draft.pk == nil then
      pcall(BattleBayDeluxe.draft_pack_priority, a1, a2) -- hidden until a pack opens
    elseif a1 == BattleBayDeluxe.draft_formation.QUAD or a1 == BattleBayDeluxe.draft_formation.TXT then
      pcall(BattleBayDeluxe.draft_formation_priority, a1, a2) -- drawn by the next Step (BattleBayDeluxe.draft_formation_render)
    end
    return table.unpack(r, 1, r.n)
  end

  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    if a1 == BattleBayDeluxe.draft.ANCHOR then
      -- A pointer click is handled once by BattleBayDeluxe.draft_mouse.
      local B = BattleBayDeluxe.draft
      if B.mode ~= nil and B.mouse and B.ptr ~= nil and (B.mouseDecided or (B.ptr.owns() and B.ptr.at() ~= nil)) then
        return
      end
      if BattleBayDeluxe.draft.mode ~= nil then
        local ok, err = pcall(BattleBayDeluxe.draft_decide)
        if not ok then
          BattleBayDeluxe.draft_log("decide error", tostring(err))
        end
      end
      return
    end
    if BattleBayDeluxe.draft.filterCo ~= nil then
      return
    end
    if a1 == BattleBayDeluxe.draft.GRID and not BattleBayDeluxe.draft.bypass and BattleBayDeluxe.draft.mode == nil then
      local ok, mine = pcall(BattleBayDeluxe.draft_is_slot, a2)
      if ok and mine then
        local okr, err = pcall(BattleBayDeluxe.draft_start, a2)
        if not okr then
          BattleBayDeluxe.draft_log("start error", tostring(err))
          pcall(BattleBayDeluxe.draft_exit, true)
        end
        return
      end
    end
    return decide(a1, a2, ...)
  end

  local fn = OnFunction
  function OnFunction(a1, a2, ...)
    local B = BattleBayDeluxe.draft
    if B.mode ~= nil and (a1 == B.FN_UP or a1 == B.FN_DOWN or a1 == B.FN_LEFT or a1 == B.FN_RIGHT) then
      local dx = (a1 == B.FN_RIGHT and 1) or (a1 == B.FN_LEFT and -1) or 0
      local dy = (a1 == B.FN_UP and 1) or (a1 == B.FN_DOWN and -1) or 0
      local ok, err = pcall(BattleBayDeluxe.draft_move, dx, dy)
      if not ok then
        BattleBayDeluxe.draft_log("move error", tostring(err))
      end
      return 1
    end
    if B.mode ~= nil and a1 == B.FN_Y then
      -- The formation cannot be changed once chosen.
      return 1
    end
    return fn(a1, a2, ...)
  end

  local back = OnBack
  function OnBack(a1, a2, ...)
    if a1 == BattleBayDeluxe.draft.ANCHOR then
      if BattleBayDeluxe.draft.mode ~= nil then
        local ok, err = pcall(BattleBayDeluxe.draft_back)
        if not ok then
          BattleBayDeluxe.draft_log("back error", tostring(err))
        end
      end
      return 1
    end
    if a1 == BattleBayDeluxe.draft.GRID and BattleBayDeluxe.draft.mode == nil then
      -- Abandons the draft when leaving the grid.
      VRFW.host.command(BattleBayDeluxe.draft.ABANDON)
    end
    return back(a1, a2, ...)
  end

  -- Handles going back from the difficulty window after a draft.
  local closeEnd = OnCloseEndLayer
  if closeEnd ~= nil then -- the free-match script has none
    function OnCloseEndLayer(a1, a2, ...)
      local r = table.pack(closeEnd(a1, a2, ...))
      if a1 == BattleBayDeluxe.draft.DIFFWIN and BattleBayDeluxe.draft.used and BattleBayDeluxe.draft.mode == nil and BattleBayDeluxe.draft.refresh == nil then
        BattleBayDeluxe.draft.refresh = BattleBayDeluxe.draft.REFRESH_FRAMES
      end
      return table.unpack(r, 1, r.n)
    end
  end

  local setupIcon = SetupEmblemIcon
  function SetupEmblemIcon(a1, a2, a3, a4, ...)
    if type(a1) == "number" then
      BattleBayDeluxe.draft.slotArgs[a1] = {a2 or 0, a3, a4}
    end
    return setupIcon(a1, a2, a3, a4, ...)
  end

  -- Draws the panel.
  local formation = UpdateFormation
  function UpdateFormation(a1, a2, ...)
    local B = BattleBayDeluxe.draft
    local free = BattleBayDeluxe.draft_free()
    if B.mode ~= nil and (a2 ~= false or free) then
      local ok, err = pcall(BattleBayDeluxe.draft_panel_hold)
      if not ok then
        BattleBayDeluxe.draft_log("panel hold error", tostring(err))
      end
      return
    end
    if free and not B.ours then
      -- the native refresh draws the side being chosen with the tile under the cursor
      B.drawn[a2 ~= false] = a1
      if a1 == B.TEAM then
        B.side = a2 ~= false
      end
    end
    local r = table.pack(formation(a1, a2, ...))
    if a1 == B.TEAM and (a2 ~= false or free) then
      pcall(function()
        local ok, phase = BattleBayDeluxe.draft_info()
        if not (ok and phase >= 2) then
          BattleBayDeluxe.draft_layer_visible((a2 ~= false) and B.LEFT or B.RIGHT, 11, false)
        end
      end)
    end
    return table.unpack(r, 1, r.n)
  end

  -- the panel's tactics stay hidden while the Draft screen is open
  local tactics = UpdateTacticsLayer
  if tactics ~= nil then
    function UpdateTacticsLayer(a1, a2, ...)
      if BattleBayDeluxe.draft.mode ~= nil and (a2 ~= false or BattleBayDeluxe.draft_free()) then
        return
      end
      return tactics(a1, a2, ...)
    end
  end
end
