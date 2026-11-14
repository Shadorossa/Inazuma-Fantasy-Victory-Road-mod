-- the tournament panel.
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.tournament.ARM = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_ARM@
BattleBayDeluxe.tournament.DISARM = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_DISARM@
BattleBayDeluxe.tournament.SYNC = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_SYNC@
BattleBayDeluxe.tournament.VIEW = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_VIEW@
BattleBayDeluxe.tournament.ABANDON = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_ABANDON@
BattleBayDeluxe.tournament.CLOSE = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_CLOSE@
BattleBayDeluxe.tournament.STEP = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_STEP@
BattleBayDeluxe.tournament.PREPARE = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_PREPARE@
BattleBayDeluxe.tournament.UNLOAD = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_UNLOAD@
-- Opens the team grid as the campaign variant
BattleBayDeluxe.tournament.GRID_WAIT_STEPS = 180
function BattleBayDeluxe.tournament_top_menu_settled()
  local menu = BattleBayDeluxe.tournament_host.menu
  local _, main = coroutine.running()
  funcLuaMenuCommand(@crc:CMND_MAKE_ACHIEVE_MESSAGE@ --[[CMND_SET_MENU_ACTIVE?]], menu, false)
  BattleBayDeluxe.tournament_log("grid: " .. tostring(BattleBayDeluxe.tournament_host.name) .. " made inactive, waiting for it to settle")
  for step = 0, BattleBayDeluxe.tournament.GRID_WAIT_STEPS do
    local busy = VRFW.host.command(667479479 --[[menu still changing?]], menu)
    if busy ~= true then
      BattleBayDeluxe.tournament_log("grid: " .. tostring(BattleBayDeluxe.tournament_host.name) .. " settled after " .. step .. " Step(s)")
      return true
    end
    if main then
      break
    end
    coroutine.yield()
  end
  funcLuaMenuCommand(@crc:CMND_MAKE_ACHIEVE_MESSAGE@ --[[CMND_SET_MENU_ACTIVE?]], menu, true)
  pcall(BattleBayDeluxe.tournament_host.refocus)
  BattleBayDeluxe.tournament_log("grid: " .. tostring(BattleBayDeluxe.tournament_host.name) .. " did not settle in " .. BattleBayDeluxe.tournament.GRID_WAIT_STEPS ..
    " Steps: the grid is not opened, the menu is active again")
  return false
end

function BattleBayDeluxe.tournament_open_grid_as_campaign()
  if not BattleBayDeluxe.tournament_top_menu_settled() then
    return false
  end
  local cmd = funcLuaCommand
  local swapped = false
  local swap
  swap = function(c, a1, a2, ...)
    if not swapped and c == @crc:CMND_OPEN_MENU_OBJECT@ and a1 == @crc:enjoy_team_select_menu@ and a2 == @crc:enjoy_team_select_menu_offline@ then
      swapped = true
      if funcLuaCommand == swap then
        funcLuaCommand = cmd
      end
      cmd(VRFW.commands.PARAM_DELETE, 357455239)
      BattleBayDeluxe.tournament_log("grid: the campaign variant for the tournament")
      return cmd(c, a1, @crc:enjoy_team_select_menu_campaign@, ...)
    end
    return cmd(c, a1, a2, ...)
  end
  funcLuaCommand = swap
  local ok, err = pcall(WaitExecOtherMenu, @crc:enjoy_team_select_menu@, BattleBayDeluxe.tournament.LIST_MID)
  if funcLuaCommand == swap then
    funcLuaCommand = cmd
  end
  if not swapped then
    BattleBayDeluxe.tournament_log("grid: no swap (the 1P path did not open the grid variant)")
  end
  if not ok then
    error(err, 0)
  end
  BattleBayDeluxe.tournament_log("grid: the retail opener returned")
  return true
end
BattleBayDeluxe.tournament.RULE_SELECT = @crc:CMND_VRFW_RULE_ENGINE_SELECT@
BattleBayDeluxe.tournament.RULE_STATE = @crc:CMND_VRFW_RULE_ENGINE_STATE@
BattleBayDeluxe.tournament.ROW_CAMPAIGN = 4154438766
BattleBayDeluxe.tournament.LIST_MID = @crc:mainmenu90_11_list_item_middle@
BattleBayDeluxe.tournament.LIST_SMALL = @crc:mainmenu90_12_list_item_small@
BattleBayDeluxe.tournament.TOP = @crc:bb_stadium_top_menu@
BattleBayDeluxe.tournament.ANCHOR = @crc:battlebaydeluxe_tn_anchor@
BattleBayDeluxe.tournament.FN_PREV = @crc:battlebaydeluxe_tn_prev@
BattleBayDeluxe.tournament.FN_NEXT = @crc:battlebaydeluxe_tn_next@
-- Overlay layers (content\menus\bb_tournament.toml).
BattleBayDeluxe.tournament.L = {
  bg = @crc:vroad04_01_p1_bg@,
  stadium = @crc:vroad01_00_background@,   -- the opaque stadium background behind the band
  line = @crc:battlebaydeluxe_tn_line@,    -- connector pieces (a tinted white quad)
  row_l = @crc:battlebaydeluxe_tn_row_l@,  -- a team plate, crest left of the name (left side; results; champion)
  row_r = @crc:battlebaydeluxe_tn_row_r@,  -- the mirrored plate (right side)
  txt = @crc:battlebaydeluxe_tn_txt@,      -- free texts: match scores, group titles, results values
  icon = @crc:battlebaydeluxe_tn_icon@,    -- the champion's crown
}
BattleBayDeluxe.tournament.L.box = @crc:battlebaydeluxe_tn_box@   -- a score box at a plate's inner end
-- Instances per layer (the menu file's counts).
BattleBayDeluxe.tournament.N = { line = 330, row_l = 33, row_r = 32, txt = 4, icon = 1, box = 36 }
BattleBayDeluxe.tournament.PRIO = { line = 549, box = 552 }
-- A pool a host menu lacks (N[k] = 0) drawn on another pool at PRIO[k], e.g.
BattleBayDeluxe.tournament.SHARE = {}
BattleBayDeluxe.tournament.ROW_CHAMP = 32                 -- row_l instance of the champion's plate
BattleBayDeluxe.tournament.ART = 2658588602               -- crc32("#/menu/220_img/bbd_tn/bbd_tn.g4tx"): the mod's drawings
-- Score digits atlas (a g4tx holds at most 255 sprites)
BattleBayDeluxe.tournament.ART_NUM = 1494349866
BattleBayDeluxe.tournament.SPR_CROWN = @crc:bbd_tn_crown@
BattleBayDeluxe.tournament.SPR_DIM = @crc:bbd_tn_dim@        -- the stadium dimmed under a page (one box-pool quad)
-- Team strips in the order of config.toml [bracket_strips] names (a plate's .strip = 1-based index), drawn
BattleBayDeluxe.tournament.SPR_STRIP = {
  @crc:bbd_tn_strip_red@, @crc:bbd_tn_strip_orange@, @crc:bbd_tn_strip_yellow@, @crc:bbd_tn_strip_green@,
  @crc:bbd_tn_strip_cyan@, @crc:bbd_tn_strip_blue@, @crc:bbd_tn_strip_purple@, @crc:bbd_tn_strip_pink@,
  @crc:bbd_tn_strip_black@, @crc:bbd_tn_strip_silver@,
}
BattleBayDeluxe.tournament.PLATE_SPRITE = @crc:list_base_xs01_off@
BattleBayDeluxe.tournament.PLATE_ATLAS = 143680280
BattleBayDeluxe.tournament.WHITE = { 1, 1, 1 }
BattleBayDeluxe.tournament.MESH_QUAD = @crc:_icon_new01@
BattleBayDeluxe.tournament.NODE_QUAD = @crc:icon_new01@
-- Score digit sizes.
BattleBayDeluxe.tournament.NUM = { W = 22, H = 29, GAP = 32, PAIR_H = 90, HEIGHT = 0.55, H_MIN = 13, H_MAX = 26, SPACE = 4, ADV = 0.78,
  PEN_S = 0.75, FINAL_S = 1.3, BOX_FILL = 0.72, PRIO = 548 }
-- Plate looks.
BattleBayDeluxe.tournament.PLATE = { off = @crc:_list_base_xs01_off@, on = @crc:_list_base_xs01_on@, ok = @crc:_list_base_xs01_ok@,
  ol = @crc:_list_base_xs01_ol@ }
BattleBayDeluxe.tournament.MESH_EMBLEM = @crc:_icon_emblem_dmy01@
BattleBayDeluxe.tournament.TXT_ON = @crc:_text_list01_on@     -- white (on the blue / cyan plates)
BattleBayDeluxe.tournament.TXT_OFF = @crc:_text_list01_off@   -- blue (on the light plate)
BattleBayDeluxe.tournament.STYLE_TXT = 187454762              -- fs_28_w_cc_2d2_001: centred white, outlined (scores, titles)
BattleBayDeluxe.tournament.C = {
  VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@, POS = @crc:CMND_SET_LAYER_LOCAL_POS@, SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@, SPRITE = 558735651, PRIM_COLOR = @crc:CMND_SET_PRIM_COLOR@,
  MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@, TEXT = @crc:CMND_SET_MENU_TEXT_STRING@, TEXT_VISIBLE = @crc:CMND_SET_MENU_TEXT_VISIBLE@, TEXT_STYLE = 2333948100,
}
-- Geometry in screen px (y down), shared with research/mods/BattleBayDeluxe/_tools/bbd_bracket_art.py.
BattleBayDeluxe.tournament.G = {
  W = 1920, TOP = 136, BOTTOM = 1004, CX = 960, PLATE_W = 520, PLATE_H = 72, SCALE_MAX = 1.0, Q = 36,
  CROWN_W = 72, CROWN_H = 54, DIM = 0.5,
  -- Background panel stretched over BG_TOP ..
  BG_Y = 178, BG_H = 724, BG_TOP = 100, BG_BOTTOM = 1036,
  -- Draw priorities (higher draws in front)
  PRIO_STADIUM = 190, PRIO_DIM = 192, PRIO_BACK = 546,
}
-- Top menu layers hidden under the overlay.
BattleBayDeluxe.tournament.TOP_LAYERS = {
  @crc:mainmenu90_35_cross_play_guide@,
  @crc:mainmenu90_06_content_guide_line03@, @crc:mainmenu90_25_list_item_locator@,
  @crc:mainmenu90_11_list_item_middle@, @crc:mainmenu90_12_list_item_small@,
  @crc:mainmenu90_24_tutorial_button@, @crc:mainmenu90_24_02_play_guide_button@,
  @crc:vs01_21_room_setting_button@, @crc:vs11_01_next_stage_guide@,
}
-- Screen the tournament runs on.
BattleBayDeluxe.tournament_host = {
  name = "bb_stadium_top_menu", menu = @crc:bb_stadium_top_menu@, hide = {}, close = BattleBayDeluxe.tournament.TOP_LAYERS,
  lists = { @crc:mainmenu90_11_list_item_middle@, @crc:mainmenu90_12_list_item_small@ },
  step = "battlebaydeluxe_tournament",
  -- Page title in the menu header (Battle Bay header type 30).
  title = function(t)
    pcall(SwapSoccerTopCommonHeaderByHeaderType, 30, t)
  end,
  header = function()
    pcall(SwapSoccerTopCommonHeaderByHeaderType, 30, funcLuaCommand(@crc:CMND_TEXT_GET@, 3066112094))
  end,
  refocus = function()
    BattleBayDeluxe.tournament_focus_campaign_row()
  end,
  ready = function()
    return funcLuaMenuCommand(@crc:CMND_IS_CTRL_FOCUS_ACTIVE@, BattleBayDeluxe.tournament.LIST_MID) == true
  end,
  open_grid = function()
    return BattleBayDeluxe.tournament_open_grid_as_campaign()
  end,
  -- While the overlay is up the footer shows only the retail Accept prompt
  guide = function(open)
    local GUIDE = @crc:mainmenu01_06_base_button_guide@
    if open then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, GUIDE, 0, true)
      VRFW.footer_prompts.set(BattleBayDeluxe.tournament_host.name, BattleBayDeluxe.tournament_host.menu,
        { {text = 1847312674 --[[Accept]], icon = 2750714971 --[[<CMD_ENTER>]], command = @crc:CMD_ENTER@} },
        {guide = GUIDE, declared = false})
    elseif type(UpdateButtonGuide) == "function" then
      UpdateButtonGuide(true)
    end
  end,
  before_match = function() end,
}

-- Opens / closes every instance of the layers (soccer_top_menu has no SwitchLayerOpenOrClose of its own).
function BattleBayDeluxe.tournament_switch_layers(t, open)
  for _, l in ipairs(t or {}) do
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, l) or 0
    for i = 0, n - 1 do
      if open then
        funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, l, i)
      else
        funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, l, i)
      end
    end
  end
end

function BattleBayDeluxe.tournament_show_layers(t, on)
  for _, l in ipairs(t or {}) do
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, l) or 0
    for i = 0, n - 1 do
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, l, i, on)
    end
  end
end

BattleBayDeluxe.tournament_state = { open = false, view = nil, page = -1, want = false, frames = 0, co = nil, busy = false, step = false,
  sync = false, sync_frames = 0, emb = {}, used = {}, taken = {}, entry = false }


function BattleBayDeluxe.tournament_sync()
  local st = { VRFW.host.command(BattleBayDeluxe.tournament.RULE_STATE) }
  local args = {}
  for i = 1, 8 do
    args[#args + 1] = st[i]
  end
  local r = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.SYNC, table.unpack(args, 1, 8))
  if type(r) ~= "table" then
    return false
  end
  BattleBayDeluxe.tournament_log("sync", r.event, r.show)
  if r.show then
    BattleBayDeluxe.tournament_state.want = true
    BattleBayDeluxe.tournament_state.frames = 0
  end
  -- An armed tournament that never started (grid left without a start) is disarmed here.
  local info = BattleBayDeluxe.tournament_info()
  if info.armed then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.DISARM)
    VRFW.host.command(BattleBayDeluxe.tournament.RULE_SELECT, "")
  end
  return true
end
