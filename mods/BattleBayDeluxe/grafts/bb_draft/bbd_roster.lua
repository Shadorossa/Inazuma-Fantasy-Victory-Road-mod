BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.roster = {
  FN_GRID_Y = 756653130 --[[the grid's CMD_FUNC3 function (enjoy_team_select_menu_setting)]],
  FN_Y = @crc:battlebaydeluxe_roster_y@,
  FN_PAGE_PREV = @crc:battlebaydeluxe_roster_page_prev@,
  FN_PAGE_NEXT = @crc:battlebaydeluxe_roster_page_next@,
  PLACE = @crc:CMND_BATTLEBAYDELUXE_FORMATION_PLACE@,
  TXT_GUIDE = @crc:battlebaydeluxe_roster@,
  TXT_HINT = @crc:battlebaydeluxe_roster_hint@,
  I_FUNC3 = 3794706590 --[[<CMD_FUNC3>]],
  K_FUNC3 = 3421673595 --[[CMD_FUNC3]],
  GUIDE_LAYER = 618184632 --[[mainmenu01_06_base_button_guide_right: this menu's guide]],
  -- the formation screen's objects (content\menus\bb_draft.toml)
  L_BG = @crc:battlebaydeluxe_roster_bg@, L_FRAME = @crc:battlebaydeluxe_roster_frame@, L_TITLE = @crc:battlebaydeluxe_roster_title@,
  -- the squad's cards (instance = member slot) and the empty bench / manager / coach places
  L_CARD = @crc:battlebaydeluxe_roster_card@, L_BLANK = @crc:battlebaydeluxe_roster_blank@,
  T_TITLE = 1158637427 --[[_text_formation_btn01]],
  M_TITLE_OFF = {@crc:_formation_focus01@, @crc:_dmy_formation_btn01@},
  TITLE_CURSOR = 3528595086 --[[the bar's cursor label: the retail dock unhooks it when the bar opens]],
  PICKER_BG = 4036570440 --[[vs01_41_enjoy_team_select_background: the looks go just above it]],
  -- Picker layers hidden while the viewer is up (restored as they were), besides the Draft's grid, locks and panel.
  PICKER_HIDE = {2708277675 --[[vs01_45_p1_enjoy_team_select_teamInfo]], 2813867952 --[[vs01_44_..._backbelt]],
                 2785921709 --[[vs01_45_..._backbelt]], 3223710473 --[[vs01_48_..._explanation_plate]]},
  -- the menu camera of the character models
  CAM = 1752770328 --[[MenuCamera]], CAM_GET = 1877348924, CAM_SET = 284729675, CAM_AGAIN = {30, 90},
  CAM_POS = 2225733338 --[[named camera position]],
  -- the player page's model layer (personal_plate_menu), logged only
  MODEL_LAYER = 1370612874, MODEL_NODE = 1517329426, MODEL_PROBE = 60,
  -- the player page and its players-universe parameters (personal_plate_menu OnInit)
  PLATE = 1427722143 --[[personal_plate_menu]],
  PLATE_PAGE = 878737202 --[[team11_01_personal_plate]],
  P_PARAM = 3928123478, P_LEVEL = 3894267099, P_RARITY = 571278276,
  PLATE_SET = 1101551215 --[[(param, level, rarity, false): the page's player]],
  LINEUP_FLAG = @crc:BattleBayDeluxe.lineup@ --[[parameter set while this screen shows the page]],
  -- Team and member slot of the shown player (VRFW.plate_member).
  MEMBER_TEAM = @crc:VRFW.plate_team@, MEMBER_SLOT = @crc:VRFW.plate_slot@,
  -- Live character and team kit of the shown player when the tile's team is a team set or template (VRFW.plate_member).
  MEMBER_HANDLE = @crc:VRFW.plate_handle@, MEMBER_KIT = @crc:VRFW.plate_kit@,
  STATUS = 1131797651 --[[character status (handle, 0 level / 4 chara_param / 12 rarity)]],
  PLATE_PAGE_PREV = 567813453, PLATE_PAGE_NEXT = 2019940505, PLATE_PAGE_UPDATE = 3297841487,
  CHARA_INFO = @crc:CMND_GET_CHARA_INFO@ --[[CMND_GET_CHARA_INFO (param, 8) = chara_param rarity]],
  RARITY_DEFAULT = 4, RARITY_MAX = 7,
  FORM_INFO = @crc:CMND_GET_SOCCER_FORMATION_INFO@ --[[CMND_GET_SOCCER_FORMATION_INFO (5 / 6, formation, slot)]],
  CARD_CMD = 2339877830 --[[the retail card draw]],
  SUB_WINDOW = 2941513916 --[[sub_window_group]],
  CLICK = 749879980 --[[CMD_VRFW_MOUSE_LEFT]],
  STARTERS = 11, BENCH_END = 16, STAFF_SLOT = 19, CARD_COUNT = 20,
  FRAME_X = 437, FRAME_Y = 468, BG_X = 0, BG_Y = 0,
  -- Nodes of the frame (soccer11_02 layout).
  NODE_CC = @crc:_pos_formation01_cc@, NODE_LU = @crc:_pos_formation01_lu@, NODE_RU = @crc:_pos_formation01_ru@,
  NODE_LD = @crc:_pos_formation01_ld@, NODE_RD = @crc:_pos_formation01_rd@,
  NODE_BENCH = {@crc:_pos_sub_atc01@, @crc:_pos_sub_atc02@, @crc:_pos_sub_atc03@, @crc:_pos_sub_atc04@,
                @crc:_pos_sub_atc05@},
  NODE_MANAGERS = {@crc:_pos_support_atc01@, @crc:_pos_support_atc02@, @crc:_pos_support_atc03@},
  NODE_LEADER = @crc:_atc_leader01@,
  -- the frame's bind pose (soccer11_02_bui_fc), used only when the pose command gives no number
  BIND_POSE = {
    [@crc:_pos_formation01_cc@] = {0, 0}, [@crc:_pos_formation01_lu@] = {-252, 278},
    [@crc:_pos_formation01_ru@] = {252, 278}, [@crc:_pos_formation01_ld@] = {-346, -381},
    [@crc:_pos_formation01_rd@] = {346, -381},
    [@crc:_pos_sub_atc01@] = {439, 259}, [@crc:_pos_sub_atc02@] = {439, 157}, [@crc:_pos_sub_atc03@] = {439, 55},
    [@crc:_pos_sub_atc04@] = {439, -47}, [@crc:_pos_sub_atc05@] = {439, -149},
    [@crc:_pos_support_atc01@] = {373, -312}, [@crc:_pos_support_atc02@] = {317, -412},
    [@crc:_pos_support_atc03@] = {429, -412}, [@crc:_atc_leader01@] = {-285, -393},
  },
  -- Constants of the dock's formation rule (soccer_formation_menu_inc SetupFormationIconPosition).
  FORMATION_WIDTH_UNITS = 60, FORMATION_DEPTH_UNITS = 94, FORMATION_BASE_SET = 2, KEEPER_LIFT = 20,
  -- Layout for starters without a retail placement.
  PITCH_HALF_W = 255, PITCH_TOP_IN = 25, PITCH_BOTTOM_IN = 50,
  GRID_DX = 150, GRID_DY = 150, -- starters without any placement: rows of 4 over the pitch
  CARD_SCALE = 1.05, BENCH_SCALE = 1, COACH_SCALE = 1,
  -- the blank card's meshes (team00_01_p1 layout, as SetBlankMeshByCardType switches them)
  M_BLANK_LARGE = 3133268926 --[[_chr_blank01]], M_BLANK_SMALL = 2623475960 --[[_chr_blank_s01]],
  M_BLANK_OFF = {3083628236 --[[_chr_change_blank01]], 308279580 --[[_chr_change_blank_s01]],
                 2933978864 --[[_chr_change01]], 2675475129 --[[_chr_change_s01]]},
  M_BLANK_MARK = 263310765 --[[_icon_blank_mark01]], M_BLANK_MARK_SMALL = 560392661 --[[_icon_blank_mark_s01]],
  M_BLANK_CHARA = 1378790588 --[[_icon_blank_chr01]], M_BLANK_CHARA_SMALL = 1208665748 --[[_icon_blank_chr_s01]],
  TEX_BLANK = 551387117 --[[#/menu/102_team/team00/team00_01_p1/<LG>/team00_01_p1.g4tx]],
  SPR_MARK_COACH = 3272899405 --[[icon_blank_mark01]], SPR_MARK_MANAGER_SMALL = 3289616799 --[[icon_blank_mark_s02]],
  MAT_MARK = 3272899405 --[[icon_blank_mark01]], MAT_MARK_SMALL = 1562034213 --[[icon_blank_mark_s01]],
  TITLE_X = 434, TITLE_Y = 113,
  PRIO_LOOK = 600,
  PRIO_BLANK = 711, PRIO_CARDS = 712,
  PROBE_FRAMES = 20,
  -- half sizes on screen for the pointer (half of the card body at its scale)
  HALF_SMALL = {72, 53}, HALF_BENCH = {68, 50}, HALF_COACH = {78, 58},
  PLATE_WAIT = 180, -- frames the page may take to appear
  CLOSE_AGAIN = 30, CLOSE_MAX = 600,
  SE_OPEN = 3848881948 --[[sy0000]], SE_MOVE = 2500047763 --[[sy0005]], SE_BACK = 202039849, SE_NG = 2086672038,
  -- State of the roster viewer.
  state = nil, team = 0, tile = -1, formation = 0, members = {}, empties = {}, sel = 1, shown = nil, plate = nil,
  refresh = nil, back = nil, frame = 0, prev_click = false, guide_on = true, tile_ok = false, ylock = false,
  pending = nil, closing_at = 0, cam = nil, panel_closed = false, model_probe = nil, cam_again = nil, probe = nil,
  prio = nil, title = nil, opened = false, cards_open = false, ready = {},
}

function BattleBayDeluxe.roster_log(...)
  BattleBayDeluxe.logger(BattleBayDeluxe.roster, "BattleBayDeluxe.roster")(...)
end

local function refuse_sound()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, BattleBayDeluxe.roster.SE_NG)
end

local function param_clear(k)
  if VRFW.param.has(k) then
    VRFW.param.clear(k)
  end
end

local function param_set(k, v)
  param_clear(k)
  VRFW.param.set(k, v)
end

-- the player page's opening parameters cleared
local function params_clear()
  local R = BattleBayDeluxe.roster
  for _, k in ipairs({R.P_PARAM, R.P_LEVEL, R.P_RARITY}) do
    param_clear(k)
  end
end

local function plate_exists()
  return funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.roster.PLATE) == true
end

local function page_up()
  local R = BattleBayDeluxe.roster
  return funcLuaCommand(@crc:CMND_IS_OPEN_MENU_OBJECT@, R.PLATE, R.PLATE_PAGE) == true
end

local function closing(why)
  local R = BattleBayDeluxe.roster
  R.state = "closing"
  R.closing_at = R.frame
  BattleBayDeluxe.roster_log("closing", why)
end

-- the team on a grid tile, 0 for no tile (also read by bb_tournament's grid)
function BattleBayDeluxe.roster_team_of(tile)
  if type(tile) ~= "number" or tile < 0 then
    return 0
  end
  return BattleBayDeluxe.draft_tile_team(tile)
end

-- the focused tile is a team Y opens
function BattleBayDeluxe.roster_tile_ok()
  local B = BattleBayDeluxe.draft
  local tile = funcLuaMenuCommand(2603265800 --[[focus index]], B.GRID)
  local team = BattleBayDeluxe.roster_team_of(tile)
  return team ~= 0 and team ~= B.TEAM
end

-- Returns a frame node's pose in the frame's own space (x right, y up).
local function frame_pose(node)
  local R = BattleBayDeluxe.roster
  local x, y, _, ok = funcLuaMenuCommand(@crc:CMND_GET_MESH_POSE@, R.L_FRAME, 0, node)
  if ok ~= false and type(x) == "number" and type(y) == "number" then
    return x, y
  end
  local p = R.BIND_POSE[node]
  if p ~= nil then
    return p[1], p[2]
  end
  return nil, nil
end

-- a point of the frame's space on screen (x from the left, y down)
local function to_screen(x, y)
  local R = BattleBayDeluxe.roster
  if type(x) ~= "number" or type(y) ~= "number" then
    return nil, nil
  end
  return R.FRAME_X + x, R.FRAME_Y - y
end

local function retail_pitch_place(slot)
  local R = BattleBayDeluxe.roster
  if R.formation == 0 or type(CalcFormationIconPosition) ~= "function" then
    return nil
  end
  local ok, x, y = pcall(CalcFormationIconPosition, slot, R.formation, R.FORMATION_BASE_SET, R.L_FRAME, R.NODE_CC,
    R.NODE_LU, R.NODE_RU, R.NODE_LD, R.NODE_RD, R.FORMATION_WIDTH_UNITS, R.FORMATION_DEPTH_UNITS, true, 1, true)
  if not ok or type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then
    return nil
  end
  local okk, has, kind = pcall(funcLuaCommand, R.FORM_INFO, 5, R.formation, slot)
  if okk and has == true and kind == 0 then
    y = y + R.KEEPER_LIFT
  end
  return to_screen(x, y)
end

-- Places the starters that the dock's rule did not place.
local function fallback_pitch_places(list)
  local R = BattleBayDeluxe.roster
  local cx, cy = to_screen(frame_pose(R.NODE_CC))
  local _, ty = to_screen(frame_pose(R.NODE_LU))
  local _, by = to_screen(frame_pose(R.NODE_LD))
  cx, ty, by = cx or R.FRAME_X, ty or (R.FRAME_Y - 278), by or (R.FRAME_Y + 381)
  local top, bottom = ty + R.PITCH_TOP_IN, by - R.PITCH_BOTTOM_IN
  local xmax, ymin, ymax = 1, nil, nil
  for _, m in ipairs(list) do
    if R.formation ~= 0 then
      local ok, _, x, y = funcLuaCommand(R.PLACE, R.formation, m.slot)
      if ok == true and type(x) == "number" and type(y) == "number" then
        m.fx, m.fy = x, y
        xmax = math.max(xmax, math.abs(x))
        ymin = (ymin == nil or y < ymin) and y or ymin
        ymax = (ymax == nil or y > ymax) and y or ymax
      end
    end
  end
  local yspan = (ymin ~= nil and ymax > ymin) and (ymax - ymin) or 1
  local loose = 0
  for _, m in ipairs(list) do
    if m.fx ~= nil then
      m.x = cx + BattleBayDeluxe.draft.MIRROR * R.PITCH_HALF_W * m.fx / xmax
      m.y = top + (m.fy - ymin) / yspan * (bottom - top)
    else
      local col, row = loose % 4, math.floor(loose / 4)
      m.x, m.y = cx + (col - 1.5) * R.GRID_DX, top + row * R.GRID_DY
      loose = loose + 1
    end
  end
end

-- the frame node of a bench, manager or coach slot
local function staff_node(slot)
  local R = BattleBayDeluxe.roster
  if slot == R.STAFF_SLOT then
    return R.NODE_LEADER
  elseif slot >= R.BENCH_END then
    return R.NODE_MANAGERS[slot - R.BENCH_END + 1]
  end
  return R.NODE_BENCH[slot - R.STARTERS + 1]
end

-- Computes every member's card place (starters on the pitch, the others on their frame place) and the free bench places.
function BattleBayDeluxe.roster_layout()
  local R = BattleBayDeluxe.roster
  local loose, taken = {}, {}
  for _, m in ipairs(R.members) do
    taken[m.slot] = true
    m.layer, m.i = R.L_CARD, m.slot
    if m.slot < R.STARTERS then
      m.big, m.scale, m.half = false, R.CARD_SCALE, R.HALF_SMALL
      local x, y = retail_pitch_place(m.slot)
      if x ~= nil then
        m.x, m.y = x, y
      else
        loose[#loose + 1] = m
      end
    else
      m.big = m.slot == R.STAFF_SLOT
      m.scale = m.big and R.COACH_SCALE or R.BENCH_SCALE
      m.half = m.big and R.HALF_COACH or R.HALF_BENCH
      m.x, m.y = to_screen(frame_pose(staff_node(m.slot)))
    end
  end
  if #loose > 0 then
    fallback_pitch_places(loose)
  end
  R.empties = {}
  for slot = R.STARTERS, R.STAFF_SLOT do
    if not taken[slot] then
      local x, y = to_screen(frame_pose(staff_node(slot)))
      if x ~= nil then
        R.empties[#R.empties + 1] = {slot = slot, x = x, y = y}
      end
    end
  end
end

-- The tile's team set or template as the Battle Bay Deluxe tile panel reads it; nil for a team of the game data.
local function tile_view(team)
  if type(BattleBayDeluxe.active_team_draws_tile) ~= "function" or not BattleBayDeluxe.active_team_draws_tile(team) then
    return nil, false
  end
  return BattleBayDeluxe.active_team_tile(team), true
end

-- Loads the members of a tile's team set or template from their live characters (the tile's own team record is a placeholder).
local function roster_load_view(d)
  local R = BattleBayDeluxe.roster
  R.formation = VRFW.ids.unsigned(d.formation)
  R.kit = VRFW.ids.unsigned(d.uniform)
  local members, any = {}, false
  for slot, hdl in pairs(d.members or {}) do
    local param = VRFW.ids.unsigned(VRFW.host.command(R.STATUS, hdl, 4))
    if param ~= 0 and slot >= 0 and slot <= R.STAFF_SLOT then
      local level = VRFW.host.command(R.STATUS, hdl, 0)
      local rar = VRFW.host.command(R.STATUS, hdl, 12)
      local m = {param = param, slot = slot, hdl = hdl, coach = slot == R.STAFF_SLOT,
                 level = (type(level) == "number" and level > 0) and level or BattleBayDeluxe.draft.LEVEL,
                 rar = (type(rar) == "number" and rar >= 0 and rar <= R.RARITY_MAX) and rar or R.RARITY_DEFAULT}
      if slot < R.STARTERS and R.formation ~= 0 then
        local okk, hk, kind = pcall(funcLuaCommand, R.FORM_INFO, 6, R.formation, slot)
        m.kind = (okk and hk == true and type(kind) == "number") and kind or 0
      end
      members[#members + 1] = m
      any = any or slot < R.BENCH_END
    end
  end
  table.sort(members, function(a, b)
    return a.slot < b.slot
  end)
  R.members = members
  return any
end

function BattleBayDeluxe.roster_load(team)
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  local d, drawn = tile_view(team)
  if drawn then
    if d == nil then
      BattleBayDeluxe.roster_log("refused: the tile's team set or template is not readable now, team", tostring(team))
      return false
    end
    return roster_load_view(d)
  end
  R.kit = nil
  local okn, count = funcLuaCommand(2151743654 --[[team info]], team, 8)
  if okn ~= true or type(count) ~= "number" then
    count = 24
  end
  local okf, fm = funcLuaCommand(2151743654 --[[team info]], team, 3)
  R.formation = (okf == true and type(fm) == "number") and fm or 0
  local members, seen, any = {}, {}, false
  for i = 0, count - 1 do
    local ok, has, param, slot, level = pcall(GetTeamMemberInfo, team, i)
    if ok and has == true and type(param) == "number" and param ~= 0 and type(slot) == "number"
        and slot >= 0 and slot <= R.STAFF_SLOT and not seen[slot] then
      seen[slot] = true
      local okr, okc, rar = pcall(funcLuaCommand, R.CHARA_INFO, param, 8)
      if not (okr and okc == true and type(rar) == "number" and rar >= 0 and rar <= R.RARITY_MAX) then
        rar = R.RARITY_DEFAULT
      end
      local m = {param = param, slot = slot, rar = rar,
                 level = (type(level) == "number" and level > 0) and level or B.LEVEL}
      m.coach = slot == R.STAFF_SLOT
      if slot < R.STARTERS and R.formation ~= 0 then
        local okk, hk, kind = pcall(funcLuaCommand, R.FORM_INFO, 6, R.formation, slot)
        m.kind = (okk and hk == true and type(kind) == "number") and kind or 0
      end
      members[#members + 1] = m
      any = any or slot < R.BENCH_END
    end
  end
  table.sort(members, function(a, b)
    return a.slot < b.slot
  end)
  R.members = members
  return any
end

local function member_on(layer, i)
  if layer ~= BattleBayDeluxe.roster.L_CARD then
    return nil
  end
  for _, m in ipairs(BattleBayDeluxe.roster.members) do
    if m.i == i then
      return m
    end
  end
  return nil
end

local function empty_on(layer, i)
  if layer ~= BattleBayDeluxe.roster.L_BLANK then
    return nil
  end
  for _, e in ipairs(BattleBayDeluxe.roster.empties) do
    if e.slot == i then
      return e
    end
  end
  return nil
end

local function place(layer, i, x, y, scale, prio)
  funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, layer, i, prio, true)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, x, -y, 0, i)
  funcLuaMenuCommand(3362798188, layer, i, scale, scale)
end

-- Hides the card and the focus frame (only the focused card shows it).
local function member_card(layer, i, m)
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  local sz = m.big and 1 or 2
  BattleBayDeluxe.draft_face_on(layer, i, sz)
  funcLuaMenuCommand(R.CARD_CMD, layer, i, m.param, m.big == true, m.coach == true, m.kind or 0, 0, m.level, false,
                     false, 4, 0)
  if type(BetterUI) == "table" and type(BetterUI.card_hide_level) == "function" then
    pcall(BetterUI.card_hide_level, layer, i)
  end
  if type(BetterUI) == "table" and type(BetterUI.card_hide_name) == "function" then
    pcall(BetterUI.card_hide_name, funcLuaMenuCommand, layer, i)
  end
  BattleBayDeluxe.draft_tags_off(layer, i)
  for _, mesh in ipairs(B.M_FOCUS) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, mesh, false, i)
  end
  local other = 3 - sz
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[other], false, i)
  -- Lets a card draw hook the cursor labels again.
  local shown = R.shown
  if shown == nil or shown[1] ~= layer or shown[2] ~= i then
    BattleBayDeluxe.draft_cursor_labels_off(layer, i)
  end
end

-- Draws a free bench, manager or coach place as the retail empty slot (SetBlankMeshByCardType).
local function blank_card(layer, i, slot)
  local R = BattleBayDeluxe.roster
  local big = slot == R.STAFF_SLOT
  local manager = slot >= R.BENCH_END and not big
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, true)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, R.M_BLANK_LARGE, big, i)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, R.M_BLANK_SMALL, not big, i)
  for _, mesh in ipairs(R.M_BLANK_OFF) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, mesh, false, i)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, R.M_BLANK_MARK, big, i)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, R.M_BLANK_MARK_SMALL, manager, i)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, R.M_BLANK_CHARA, big, i)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, R.M_BLANK_CHARA_SMALL, false, i)
  if big then
    funcLuaMenuCommand(558735651, layer, R.TEX_BLANK, R.SPR_MARK_COACH, R.MAT_MARK, 0, i)
  elseif manager then
    funcLuaMenuCommand(558735651, layer, R.TEX_BLANK, R.SPR_MARK_MANAGER_SMALL, R.MAT_MARK_SMALL, 0, i)
  end
end

-- Draws one card instance.
function BattleBayDeluxe.roster_draw_card(layer, i)
  local R = BattleBayDeluxe.roster
  if not R.ready[layer .. ":" .. i] then
    return
  end
  local live = R.state ~= nil and R.state ~= "closing"
  local m = live and member_on(layer, i) or nil
  local e = (live and m == nil) and empty_on(layer, i) or nil
  if m ~= nil and m.x ~= nil then
    member_card(layer, i, m)
    place(layer, i, m.x, m.y, m.scale, R.PRIO_CARDS)
  elseif e ~= nil then
    blank_card(layer, i, e.slot)
    place(layer, i, e.x, e.y, e.slot == R.STAFF_SLOT and R.COACH_SCALE or R.BENCH_SCALE, R.PRIO_BLANK)
  else
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
  end
end

local function each_instance(fn)
  local R = BattleBayDeluxe.roster
  for _, layer in ipairs({R.L_CARD, R.L_BLANK}) do
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, layer)
    if type(n) ~= "number" or n <= 0 then
      n = R.CARD_COUNT
    end
    for i = 0, n - 1 do
      fn(layer, i)
    end
  end
end

function BattleBayDeluxe.roster_draw_all()
  each_instance(BattleBayDeluxe.roster_draw_card)
end

-- the squad's layers opened (once per viewer) / closed
local function cards_open(show)
  local R = BattleBayDeluxe.roster
  if show and not R.cards_open then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, R.L_CARD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, R.L_BLANK)
    R.cards_open = true
  elseif not show and R.cards_open then
    pcall(funcLuaMenuCommand, @crc:CMND_CLOSE_LAYER_ARRAY@, R.L_CARD)
    pcall(funcLuaMenuCommand, @crc:CMND_CLOSE_LAYER_ARRAY@, R.L_BLANK)
    R.cards_open = false
    R.ready = {}
  end
end

-- the cursor label of a card size (the large card's / the small card's)
local function cursor_label(big)
  return big and BattleBayDeluxe.draft.CARD_CURSOR or BattleBayDeluxe.draft.CARD_CURSOR2
end

-- Draws the retail cursor on the focused card, as BattleBayDeluxe.draft_cursor does.
function BattleBayDeluxe.roster_cursor(show)
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  if R.shown ~= nil then
    local l, i = R.shown[1], R.shown[2]
    BattleBayDeluxe.draft_cursor_labels_off(l, i)
    for _, m in ipairs(B.M_FOCUS) do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, l, m, false, i)
    end
    R.shown = nil
  end
  if not show then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, false)
    return
  end
  local m = R.members[R.sel]
  if m == nil or not R.ready[m.layer .. ":" .. m.i] then
    return
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, true)
  if B.curMoved then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CURSOR, 0, 0, 0, 0)
    B.curMoved = false
  end
  local label = cursor_label(m.big)
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, m.layer)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@ --[[attach locator trace]], m.layer, m.i, label, true)
  funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@ --[[cursor locator]], m.layer, label, m.i, type(n) == "number" and n or 1)
  local sz = m.big and 1 or 2
  for j = 1, 2 do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, m.layer, B.M_FOCUS[j], j == sz, m.i)
  end
  R.shown = {m.layer, m.i, m.big}
end

-- Returns the bar's text.
local function formation_name()
  local R = BattleBayDeluxe.roster
  if R.formation == 0 then
    return ""
  end
  return BattleBayDeluxe.draft_formation_name(R.formation)
end

-- one of the formation screen's objects set up (its priority, place, the bar's text)
function BattleBayDeluxe.roster_look_layer(layer)
  local R = BattleBayDeluxe.roster
  local base = R.prio or R.PRIO_LOOK
  if layer == R.L_BG then
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, layer, 0, base, true)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, R.BG_X, -R.BG_Y, 0, 0)
  elseif layer == R.L_FRAME then
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, layer, 0, base + 1, true)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, R.FRAME_X, -R.FRAME_Y, 0, 0)
  elseif layer == R.L_TITLE then
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, layer, 0, base + 2, true)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, R.TITLE_X, -R.TITLE_Y, 0, 0)
    for _, mesh in ipairs(R.M_TITLE_OFF) do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, mesh, false, 0)
    end
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, layer, R.T_TITLE, R.title or "", 0)
    -- the bar never holds the cursor or the focus (the green arrow follows the cards, as on the retail dock)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@ --[[attach locator trace]], layer, 0, R.TITLE_CURSOR, false)
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, layer, false)
  else
    return
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, 0, R.state ~= nil and R.state ~= "closing")
end

function BattleBayDeluxe.roster_look(show)
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  local looks = {R.L_BG, R.L_FRAME, R.L_TITLE}
  if not show then
    if R.opened then
      for _, layer in ipairs(looks) do
        pcall(funcLuaMenuCommand, @crc:CMND_CLOSE_LAYER@, layer)
      end
      R.opened = false
    end
    return
  end
  if #B.stash == 0 then
    for _, layer in ipairs({B.GRID, B.ATTACH, B.LOCK, B.LEFT, B.TACTICS_BASE, B.TACTICS_CMD, B.FRAME}) do
      BattleBayDeluxe.draft_stash(layer)
    end
    for _, layer in ipairs(R.PICKER_HIDE) do
      BattleBayDeluxe.draft_stash(layer)
    end
  end
  if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.hide ~= nil) then
    pcall(VRFW.battle_bay_pages.hide) -- the page / category / season strip
  end
  -- Closes the team panel (vs01_44_p1) because it holds the picker's own 3D character.
  if not R.panel_closed then
    R.panel_closed = BattleBayDeluxe.draft_team_panel_close()
  end
  if R.prio == nil then
    local p = funcLuaMenuCommand(@crc:CMND_GET_DRAW_PRIORITY@ --[[draw priority]], R.PICKER_BG, 0)
    R.prio = (type(p) == "number" and p + 1 < R.PRIO_BLANK - 3) and (p + 1) or R.PRIO_LOOK
  end
  R.title = formation_name()
  if not R.opened then
    for _, layer in ipairs(looks) do
      funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, layer)
    end
    R.opened = true
  end
  for _, layer in ipairs(looks) do
    BattleBayDeluxe.roster_look_layer(layer)
  end
end

-- the frame's node poses and the first card's place in the log, once per opening (the layout check)
function BattleBayDeluxe.roster_probe()
  local R = BattleBayDeluxe.roster
  local parts = {}
  for _, node in ipairs({R.NODE_CC, R.NODE_LU, R.NODE_RU, R.NODE_LD, R.NODE_RD, R.NODE_BENCH[1], R.NODE_BENCH[5],
                         R.NODE_MANAGERS[1], R.NODE_LEADER}) do
    local x, y, z, ok = funcLuaMenuCommand(@crc:CMND_GET_MESH_POSE@, R.L_FRAME, 0, node)
    parts[#parts + 1] = string.format("%s(%s,%s)", tostring(ok), tostring(x), tostring(y))
  end
  local tx, ty = funcLuaMenuCommand(4002164178 --[[global position]], R.L_TITLE, 0)
  local cx, cy = funcLuaMenuCommand(4002164178 --[[global position]], R.L_CARD, 0)
  BattleBayDeluxe.roster_log("layout probe: frame cc/lu/ru/ld/rd/sub1/sub5/support1/leader " .. table.concat(parts, " ")
    .. " title at " .. tostring(tx) .. "," .. tostring(ty) .. " card 0 at " .. tostring(cx) .. "," .. tostring(cy)
    .. " formation " .. VRFW.ids.hex_text(R.formation) .. " free places " .. #R.empties)
end

function BattleBayDeluxe.roster_model_probe()
  local R = BattleBayDeluxe.roster
  local okc, has, ox, oy, oz = pcall(funcLuaCommand, R.CAM_GET, R.CAM)
  local okp, hp, px, py, pz = pcall(funcLuaCommand, R.CAM_POS, R.CAM)
  local okm, mx, my, mz = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_GLOBAL_POSITION@ --[[mesh global position]], R.MODEL_LAYER, 0,
    R.MODEL_NODE, R.PLATE)
  BattleBayDeluxe.roster_log("model probe: camera offset " .. tostring(has) .. " " .. tostring(ox) .. "," .. tostring(oy) .. ","
    .. tostring(oz) .. " camera position " .. tostring(hp) .. " " .. tostring(px) .. "," .. tostring(py) .. ","
    .. tostring(pz) .. " model layer " .. tostring(okm) .. " " .. tostring(mx) .. "," .. tostring(my) .. ","
    .. tostring(mz) .. " team panel closed " .. tostring(R.panel_closed))
end

-- Sets the guide while the viewer is up.
function BattleBayDeluxe.roster_guide()
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  VRFW.footer_prompts.set(nil, B.MENU, {}, {guide = R.GUIDE_LAYER, declared = false})
  BattleBayDeluxe.draft_guide(BattleBayDeluxe.draft_text(R.TXT_HINT))
end

function BattleBayDeluxe.roster_busy()
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  return B.mode ~= nil or B.pk ~= nil or B.quitCo ~= nil or B.refresh ~= nil or R.refresh ~= nil
    or (type(BattleBayDeluxe.tournament_grid) == "table" and BattleBayDeluxe.tournament_grid.co ~= nil)
    or (type(VRFW.battle_bay_pages) == "table" and VRFW.battle_bay_pages.pend ~= nil)
    or funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, B.DIFFWIN) == true
    or funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, R.SUB_WINDOW) == true
    or plate_exists()
end

-- the focused member on the open page (or once it is open)
function BattleBayDeluxe.roster_show()
  local R = BattleBayDeluxe.roster
  local m = R.members[R.sel]
  if m == nil then
    return
  end
  if R.state ~= "view" or not page_up() then
    R.pending = m
    return
  end
  R.pending = nil
  if R.plate ~= nil and R.plate.param == m.param then
    return
  end
  BattleBayDeluxe.roster_plate_member(m)
  funcLuaMenuCommand(R.PLATE_SET, m.param, m.level, m.rar, false)
  if R.plate ~= nil then
    R.plate.param = m.param
  end
end

-- Names the shown player to the page: his live character and team kit, or his member slot of the tile's team.
function BattleBayDeluxe.roster_plate_member(m)
  local R = BattleBayDeluxe.roster
  if m.hdl ~= nil then
    param_clear(R.MEMBER_TEAM)
    param_clear(R.MEMBER_SLOT)
    param_set(R.MEMBER_HANDLE, VRFW.ids.signed(m.hdl)) -- the store keeps signed 32-bit numbers
    param_set(R.MEMBER_KIT, VRFW.ids.signed(R.kit or 0))
    return
  end
  param_clear(R.MEMBER_HANDLE)
  param_clear(R.MEMBER_KIT)
  param_set(R.MEMBER_TEAM, VRFW.ids.signed(R.team))
  param_set(R.MEMBER_SLOT, m.slot)
end

-- the menu camera's offset kept (open) / put back (close)
local function camera_keep()
  local R = BattleBayDeluxe.roster
  local ok, has, x, y, z = pcall(funcLuaCommand, R.CAM_GET, R.CAM)
  R.cam = (ok and has == true and type(x) == "number") and {x, y or 0, z or 0} or nil
end

local function camera_back()
  local R = BattleBayDeluxe.roster
  if R.cam ~= nil then
    pcall(funcLuaCommand, R.CAM_SET, R.CAM, R.cam[1], R.cam[2], R.cam[3])
  end
end

-- Returns the first member to focus.
local function first_member()
  local R = BattleBayDeluxe.roster
  for k, m in ipairs(R.members) do
    if m.slot < R.STARTERS then
      return k
    end
  end
  return 1
end

-- Y on the grid
function BattleBayDeluxe.roster_open()
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  if R.state ~= nil then
    return
  end
  if BattleBayDeluxe.roster_busy() then
    refuse_sound()
    return
  end
  local tile = funcLuaMenuCommand(2603265800 --[[focus index]], B.GRID)
  local team = BattleBayDeluxe.roster_team_of(tile)
  if team == 0 or team == B.TEAM then
    refuse_sound()
    BattleBayDeluxe.roster_log("refused: tile", tostring(tile), "team", tostring(team))
    return
  end
  if not BattleBayDeluxe.roster_load(team) then
    refuse_sound()
    BattleBayDeluxe.roster_log("refused: no members, team", tostring(team))
    return
  end
  local sel = first_member()
  local m = R.members[sel]
  R.state, R.team, R.tile, R.sel, R.shown, R.pending = "opening", team, tile, sel, nil, nil
  R.ylock = true
  R.plate = {at = R.frame, seen = false, param = m.param, asked = nil}
  R.cam_again, R.probe = nil, R.PROBE_FRAMES
  camera_keep()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, R.SE_OPEN)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, false)
  BattleBayDeluxe.roster_look(true)
  BattleBayDeluxe.roster_layout()
  BattleBayDeluxe.draft_open()
  cards_open(true)
  BattleBayDeluxe.roster_draw_all()
  BattleBayDeluxe.roster_cursor(true)
  BattleBayDeluxe.roster_guide()
  -- the player page of the first player (the right half)
  param_set(R.P_PARAM, m.param)
  param_set(R.P_LEVEL, m.level)
  param_set(R.P_RARITY, m.rar)
  param_set(R.LINEUP_FLAG, 1)
  BattleBayDeluxe.roster_plate_member(m)
  funcLuaCommand(@crc:CMND_OPEN_MENU_OBJECT@, R.PLATE)
  BattleBayDeluxe.roster_log("open: tile", tile, "team", team, "members", #R.members, "free places", #R.empties)
end

-- Closes the viewer on Back or Y.
function BattleBayDeluxe.roster_close()
  local R = BattleBayDeluxe.roster
  if R.state == nil or R.state == "closing" then
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, R.SE_BACK)
  closing("asked")
  BattleBayDeluxe.roster_cursor(false)
end

-- the grid back as after the Draft screen (the page is gone)
function BattleBayDeluxe.roster_finish(why)
  local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
  params_clear()
  param_clear(R.LINEUP_FLAG)
  param_clear(R.MEMBER_TEAM)
  param_clear(R.MEMBER_SLOT)
  param_clear(R.MEMBER_HANDLE)
  param_clear(R.MEMBER_KIT)
  R.state, R.plate, R.pending, R.probe = nil, nil, nil, nil
  BattleBayDeluxe.roster_cursor(false)
  cards_open(false)
  BattleBayDeluxe.roster_look(false)
  BattleBayDeluxe.draft_close_layers() -- the Draft's layers closed, the page line back
  BattleBayDeluxe.draft_unstash()
  if R.panel_closed then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, B.TEAMINFO) -- the picker's team panel and its character
    R.panel_closed = false
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, true)
  if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.keep_crests ~= nil) then
    pcall(VRFW.battle_bay_pages.keep_crests, true)
  end
  local keep = B.refresh
  local ok, err = pcall(OnCloseEndLayer, B.DIFFWIN, 0)
  B.refresh = keep
  if not ok then
    BattleBayDeluxe.roster_log("grid back error", tostring(err))
  end
  camera_back()
  R.cam_again = {at = R.frame, k = 1}
  R.back = {tile = R.tile, team = R.team}
  R.refresh = B.REFRESH_FRAMES
  BattleBayDeluxe.roster_log("closed", why)
end

-- Asks the page to close again until it is gone.
function BattleBayDeluxe.roster_closing_step()
  local R = BattleBayDeluxe.roster
  local P = R.plate or {at = R.closing_at, seen = false}
  R.plate = P
  if plate_exists() then
    P.seen = true
    if P.asked == nil or R.frame - P.asked >= R.CLOSE_AGAIN then
      funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, R.PLATE)
      P.asked = R.frame
    end
  elseif P.seen or R.frame - P.at > R.PLATE_WAIT then
    BattleBayDeluxe.roster_finish(P.seen and "page gone" or "no page")
    return
  end
  if R.frame - R.closing_at > R.CLOSE_MAX then
    BattleBayDeluxe.roster_finish("page still there after " .. R.CLOSE_MAX .. " frames")
  end
end

-- Runs when the page has appeared (opening to view).
function BattleBayDeluxe.roster_opening_step()
  local R = BattleBayDeluxe.roster
  local P = R.plate
  if plate_exists() then
    P.seen = true
    if page_up() then
      R.state = "view"
      params_clear()
      R.model_probe = R.MODEL_PROBE
      BattleBayDeluxe.roster_log("page up")
      if R.pending ~= nil then
        BattleBayDeluxe.roster_show()
      end
    end
  elseif P.seen or R.frame - P.at > R.PLATE_WAIT then
    closing("the page did not open")
  end
end

-- Runs when the page is gone by itself while viewing.
function BattleBayDeluxe.roster_view_step()
  local R = BattleBayDeluxe.roster
  if not plate_exists() then
    closing("the page is gone")
    return
  end
  if R.pending ~= nil then
    BattleBayDeluxe.roster_show()
  end
end

-- Moves the focus in the direction (dx, dy) (dy > 0 = up) by the retail formation screen's rule (draft_focus_move).
function BattleBayDeluxe.roster_move(dx, dy)
  local R = BattleBayDeluxe.roster
  local from = R.members[R.sel]
  if from == nil or from.layer == nil then
    return
  end
  local layer, i = BattleBayDeluxe.draft_focus_move(from.layer, from.i, R.CARD_COUNT, dx, dy)
  local best = nil
  for k, m in ipairs(R.members) do
    if layer ~= nil and m.layer == layer and m.i == i then
      best = k
    end
  end
  if best ~= nil then
    R.sel = best
    BattleBayDeluxe.roster_cursor(true)
    BattleBayDeluxe.roster_show()
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, R.SE_MOVE)
  end
end

function BattleBayDeluxe.roster_plate_page(d)
  local R = BattleBayDeluxe.roster
  if not page_up() then
    return
  end
  funcLuaMenuCommand(d < 0 and R.PLATE_PAGE_PREV or R.PLATE_PAGE_NEXT)
  funcLuaMenuCommand(R.PLATE_PAGE_UPDATE)
end


function BattleBayDeluxe.roster_pointed()
  local R = BattleBayDeluxe.roster
  local mx, my = funcLuaMenuCommand(558229292 --[[pointer]])
  if type(mx) ~= "number" or type(my) ~= "number" then
    return nil
  end
  local py = -my
  for k, m in ipairs(R.members) do
    local gx, gy = funcLuaMenuCommand(4002164178 --[[global position]], m.layer, m.i)
    if type(gx) == "number" and type(gy) == "number" and math.abs(mx - gx) <= m.half[1]
        and math.abs(py - gy) <= m.half[2] then
      return k
    end
  end
  return nil
end

function BattleBayDeluxe.roster_mouse()
  local R = BattleBayDeluxe.roster
  local click = funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 1332654303 --[[MENU_CTRL]], R.CLICK) == true
  local edge = click and not R.prev_click
  R.prev_click = click
  if not edge or R.state ~= "view" then
    return
  end
  local k = BattleBayDeluxe.roster_pointed()
  if k ~= nil and k ~= R.sel then
    R.sel = k
    BattleBayDeluxe.roster_cursor(true)
    BattleBayDeluxe.roster_show()
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, R.SE_MOVE)
  end
end

-- the panel of the tile again (team name, formation, tactics)
function BattleBayDeluxe.roster_panel()
  local q = BattleBayDeluxe.roster.back
  if q == nil then
    return
  end
  pcall(UpdateTeamNameText, q.team, true)
  pcall(UpdateFormation, q.team, true)
  pcall(UpdateTacticsLayer, q.team, true)
end

function BattleBayDeluxe.roster_step()
  local R = BattleBayDeluxe.roster
  R.frame = R.frame + 1
  if R.ylock and funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 1332654303 --[[MENU_CTRL]], R.K_FUNC3) ~= true then
    R.ylock = false
  end
  if R.cam_again ~= nil then
    local q = R.cam_again
    local due = R.CAM_AGAIN[q.k]
    if due == nil then
      R.cam_again = nil
    elseif R.frame - q.at >= due then
      camera_back()
      q.k = q.k + 1
    end
  end
  if R.refresh ~= nil then
    R.refresh = R.refresh - 1
    if R.refresh <= 0 then
      R.refresh = nil
      local q = R.back
      local ok, err = pcall(BattleBayDeluxe.draft_refresh, q and q.tile or -1, BattleBayDeluxe.roster_panel, true)
      if not ok then
        BattleBayDeluxe.roster_log("refresh error", tostring(err))
      end
      if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.keep_crests ~= nil) then
        pcall(VRFW.battle_bay_pages.keep_crests, false)
      end
      R.back = nil
    end
  end
  if R.probe ~= nil then
    R.probe = R.probe - 1
    if R.probe <= 0 then
      R.probe = nil
      pcall(BattleBayDeluxe.roster_probe)
    end
  end
  if R.model_probe ~= nil and R.state == "view" then
    R.model_probe = R.model_probe - 1
    if R.model_probe <= 0 then
      R.model_probe = nil
      pcall(BattleBayDeluxe.roster_model_probe)
    end
  end
  if R.state == "opening" then
    BattleBayDeluxe.roster_opening_step()
  elseif R.state == "view" then
    BattleBayDeluxe.roster_view_step()
  end
  if R.state == "closing" then
    BattleBayDeluxe.roster_closing_step()
  end
  if R.state ~= nil then
    BattleBayDeluxe.roster_mouse()
  else
    R.prev_click = false
  end
end


if VRFW.footer_prompts ~= nil then
  VRFW.footer_prompts.add({
    name = "BattleBayDeluxe.Roster",
    menu = "enjoy_team_select_menu_campaign",
    text = BattleBayDeluxe.roster.TXT_GUIDE,
    icon = BattleBayDeluxe.roster.I_FUNC3,
    command = BattleBayDeluxe.roster.K_FUNC3,
    order = 100,
    when = function()
      return BattleBayDeluxe.roster.guide_on == true and BattleBayDeluxe.roster.tile_ok == true
    end,
  })
  -- this menu's guide is the right-hand one (mainmenu01_06_base_button_guide_right), not the framework's default
  VRFW.footer_prompts.attach("enjoy_team_select_menu_campaign", "UpdateButtonGuide", BattleBayDeluxe.roster.GUIDE_LAYER)
end

do
  local guide = UpdateButtonGuide
  function UpdateButtonGuide(a1, a2, a3, ...)
    local R = BattleBayDeluxe.roster
    R.guide_on = a3 ~= true and R.state == nil and BattleBayDeluxe.draft.mode == nil
    local ok, can = pcall(BattleBayDeluxe.roster_tile_ok)
    R.tile_ok = ok and can == true
    return guide(a1, a2, a3, ...)
  end

  -- Handles the focus moving between a team that Y opens and another tile.
  local change = OnChangeFocus
  if change ~= nil then
    function OnChangeFocus(a1, a2, ...)
      local r = table.pack(change(a1, a2, ...))
      local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
      if a1 == B.GRID and R.state == nil and B.mode == nil then
        pcall(function()
          local can = BattleBayDeluxe.roster_tile_ok()
          if can ~= R.tile_ok and funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, B.DIFFWIN) ~= true then
            UpdateButtonGuide(B.MENU, R.GUIDE_LAYER, false)
          end
        end)
      end
      return table.unpack(r, 1, r.n)
    end
  end

  local step = Step
  function Step(...)
    local r = table.pack(step(...))
    local R = BattleBayDeluxe.roster
    local ok, err = pcall(BattleBayDeluxe.roster_step)
    if not ok then
      BattleBayDeluxe.roster_log("step error", tostring(err))
      if R.state == "closing" then
        pcall(BattleBayDeluxe.roster_finish, "step error")
      elseif R.state ~= nil then
        R.state, R.closing_at = "closing", R.frame
      end
    end
    return table.unpack(r, 1, r.n)
  end

  -- Sets up the squad's cards.
  local setup = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local r = table.pack(setup(a1, a2, ...))
    local R = BattleBayDeluxe.roster
    if (a1 == R.L_CARD or a1 == R.L_BLANK) and type(a2) == "number" then
      local ok, err = pcall(function()
        if a1 == R.L_CARD then
          BattleBayDeluxe.draft_name(a1, a2)
          BattleBayDeluxe.draft_cursor_labels_off(a1, a2)
        end
        funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, a1, a2,
                           a1 == R.L_CARD and R.PRIO_CARDS or R.PRIO_BLANK, true)
      end)
      if not ok then
        BattleBayDeluxe.roster_log("card setup error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end

  local open = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    local r = table.pack(open(a1, a2, ...))
    local R = BattleBayDeluxe.roster
    if R.state ~= nil and R.state ~= "closing" and type(a2) == "number" then
      local ok, err = pcall(function()
        if a1 == R.L_CARD or a1 == R.L_BLANK then
          if a1 == R.L_CARD then
            BattleBayDeluxe.draft_name(a1, a2) -- only if the setup did not (never twice)
          end
          R.ready[a1 .. ":" .. a2] = true
          BattleBayDeluxe.roster_draw_card(a1, a2)
          local m = R.members[R.sel]
          if m ~= nil and m.layer == a1 and m.i == a2 then
            BattleBayDeluxe.roster_cursor(true)
          end
        elseif a1 == R.L_FRAME then
          -- Reads the frame's places from the open frame.
          BattleBayDeluxe.roster_look_layer(a1)
          BattleBayDeluxe.roster_layout()
          BattleBayDeluxe.roster_draw_all()
          BattleBayDeluxe.roster_cursor(true)
        elseif a1 == R.L_BG then
          BattleBayDeluxe.roster_look_layer(a1)
        elseif a1 == R.L_TITLE then
          BattleBayDeluxe.roster_look_layer(a1)
          BattleBayDeluxe.roster_cursor(true) -- the cursor back on the focused card once the bar is up
        end
      end)
      if not ok then
        BattleBayDeluxe.roster_log("layer open error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end

  -- Enter does nothing on the squad (the page follows the cursor)
  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    if BattleBayDeluxe.roster.state ~= nil and (a1 == BattleBayDeluxe.draft.ANCHOR or a1 == BattleBayDeluxe.roster.L_TITLE) then
      return
    end
    return decide(a1, a2, ...)
  end

  local fn = OnFunction
  function OnFunction(a1, a2, ...)
    local B, R = BattleBayDeluxe.draft, BattleBayDeluxe.roster
    if R.state ~= nil then
      local ok, err = true, nil
      if R.state ~= "view" then
        -- Handles the page opening or closing.
      elseif a1 == B.FN_UP or a1 == B.FN_DOWN or a1 == B.FN_LEFT or a1 == B.FN_RIGHT then
        local dx = (a1 == B.FN_RIGHT and 1) or (a1 == B.FN_LEFT and -1) or 0
        local dy = (a1 == B.FN_UP and 1) or (a1 == B.FN_DOWN and -1) or 0
        ok, err = pcall(BattleBayDeluxe.roster_move, dx, dy)
      elseif a1 == R.FN_Y then
        if not R.ylock then
          ok, err = pcall(BattleBayDeluxe.roster_close)
        end
      elseif a1 == R.FN_PAGE_PREV or a1 == R.FN_PAGE_NEXT then
        ok, err = pcall(BattleBayDeluxe.roster_plate_page, a1 == R.FN_PAGE_PREV and -1 or 1)
      elseif a1 ~= R.FN_GRID_Y then
        return fn(a1, a2, ...)
      end
      if not ok then
        BattleBayDeluxe.roster_log("function error", tostring(err))
      end
      return 1
    end
    if a1 == R.FN_GRID_Y then
      local ok, err = pcall(BattleBayDeluxe.roster_open)
      if not ok then
        BattleBayDeluxe.roster_log("open error", tostring(err))
        if R.state ~= nil then
          R.state, R.closing_at = "closing", R.frame -- the page (if asked) closed, then the grid back
        end
      end
      return 1
    end
    return fn(a1, a2, ...)
  end

  local back = OnBack
  function OnBack(a1, a2, ...)
    local R = BattleBayDeluxe.roster
    if R.state ~= nil and a1 == BattleBayDeluxe.draft.ANCHOR then
      if R.state == "view" then
        local ok, err = pcall(BattleBayDeluxe.roster_close)
        if not ok then
          BattleBayDeluxe.roster_log("back error", tostring(err))
        end
      end
      return 1
    end
    return back(a1, a2, ...)
  end

  -- the grid panel is held while the viewer is up (a native refresh would put its pitch and cards back)
  local formation = UpdateFormation
  function UpdateFormation(a1, a2, ...)
    if BattleBayDeluxe.roster.state ~= nil and a2 ~= false then
      return
    end
    return formation(a1, a2, ...)
  end

  local tactics = UpdateTacticsLayer
  if tactics ~= nil then
    function UpdateTacticsLayer(a1, a2, ...)
      if BattleBayDeluxe.roster.state ~= nil and a2 ~= false then
        return
      end
      return tactics(a1, a2, ...)
    end
  end
end
