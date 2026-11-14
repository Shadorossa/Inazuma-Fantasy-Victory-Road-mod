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
  MENU = @crc:enjoy_team_select_menu@,
  GRID = @crc:vs01_43_enjoy_team_select_emblem_icon@,
  ATTACH = @crc:vs01_42_enjoy_team_select_emblem_attach_base@,
  LOCK = @crc:mainmenu90_30_lock_icon@,
  DIFFWIN = @crc:win05_11_select_difficulty_win_base@,
  LEFT = @crc:team00_01_chara_card_left@,
  RIGHT = @crc:team00_01_chara_card_right@,
  -- Layers hidden in the free match.
  FREE_HIDE = {@crc:team00_01_chara_card_right@, @crc:vs01_46_enjoy_team_select_formation_frame_right@,
               @crc:vs01_45_p1_enjoy_team_select_teamInfo@, @crc:soccer08_12_tactics_cmd_right@,
               @crc:team00_10_tactics_base_right@, @crc:soccer00_40_username_left@,
               @crc:soccer00_40_username_right@, @crc:vs01_29_ready_ok_balloon_left@,
               @crc:vs01_29_ready_ok_balloon_right@, @crc:vs01_49_soccer_game_option_list_button@,
               @crc:vs01_21_room_setting_button@},
  FRAME = @crc:vs01_46_enjoy_team_select_formation_frame_left@,
  M_FIELD = @crc:_formation_field_s01@ --[[_formation_field_s01: the frame's pitch]],
  FRAME_NODES = {@crc:_pos_formation01_cc@, @crc:_pos_formation01_ld@,
                 @crc:_pos_formation01_ru@},
  TEAMINFO = @crc:vs01_44_p1_enjoy_team_select_teamInfo@,
  M_TACTICS_LABEL = @crc:_gtxt_tactics01@ --[[_gtxt_tactics01: TACTICS]],
  TACTICS_BASE = @crc:team00_10_tactics_base_left@,
  TACTICS_CMD = @crc:soccer08_12_tactics_cmd_left@,
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
  GUIDE = @crc:mainmenu01_06_base_button_guide_right@,
  GUIDE_TEXT = @crc:_text_guide01@,
  CURSOR = @crc:cmn05_01_cursor@,
  GRID_CURSOR = @crc:cursor@,
  CARD_CURSOR = 945715707, CARD_CURSOR2 = 1967169874, -- the card objbin's cursor labels
  EMBLEM_TEX = @crc:enjoy_list_icon_dmy01@,
  EMBLEM_NODE = @crc:_pos_enjoy_list01@,
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
  SPR_GREY = @crc:icon_chr_grayout01_s@ --[[icon_chr_grayout01_s: the small card's grey (136 x 100)]],
  SPR_GREY_L = @crc:icon_chr_base01_type_gray01@ --[[icon_chr_base01_type_gray01: the large card's grey (212 x 132), the pack's backs]],
  SPR_Q = @crc:num_menu01_01_q@,
  SLOT_BASE = {@crc:icon_chr_base01_l01@, @crc:icon_chr_base01_s01@},
  SLOT_DEF = {@crc:icon_chr_def01_l@, @crc:icon_chr_def01_s@},
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
  SE_NG = @crc:sy0003@,
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
    {"cmn05_01_cursor", @crc:cmn05_01_cursor@},
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
  MESH_QUAD = @crc:_icon_new01@,
  NODE_QUAD = @crc:icon_new01@,
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
  se_open = @crc:sy0000@, se_deal = @crc:sy0009@, se_reveal = @crc:sy0010@,
  se_best = @crc:sy0080@,
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
