-- Switched with the rebindable CMD_BBD_MODE_SWITCH key (polled on MENU_CTRL) or a click on a pill.
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.tournament_mode_selector = {
  BG = @crc:battlebaydeluxe_mode_bg@,
  PILL = @crc:battlebaydeluxe_mode_pill@,
  TXT = @crc:battlebaydeluxe_mode_txt@,
  ATLAS = "#/menu/220_img/bbd_md/bbd_md.g4tx",
  SPR_BG = @crc:bbd_md_bg@, SPR_ON = @crc:bbd_md_on@, SPR_OFF = @crc:bbd_md_off@,
  KEY = @crc:CMD_BBD_MODE_SWITCH@,       -- the mod's rebindable action (MENU_CTRL)
  READY_BTN = 2055576472 --[[cmn03_04_cmn_button_b_graphic_text: the ready balloon's button, retail Y there]],
  CLICK = 749879980 --[[CMD_VRFW_MOUSE_LEFT]],
  -- Modes left to right (label text keys battlebaydeluxe_tn_<mode>)
  MODES = { "campaign", "tournament", "league" },
  LABELS = { campaign = "mode_campaign", tournament = "mode_tournament", league = "mode_league" },
  ARM_FMT = { tournament = -1, league = 2 },
  -- Geometry in screen px (y down)
  CX = 960, Y = 34, BG_EXTRA = 6, BG_H = 56, PILL_W = 172, PILL_H = 44, PILL_GAP = 6, KEY_W = 40, GAP = 8, PAD = 10,
  TEXT_CX = 102,                         -- the change-page plate is right-anchored
  TEXT_S = 0.85, KEY_S = 0.85, DIM = 0.55, LOCK = 0.6, PRIO_TXT = 697,
  Q = 36, NODE_QUAD = 1909474081 --[[icon_new01]], MESH_QUAD = 312193881,
  N = {},
  shown = {}, opened = {}, prev_key = false, prev_click = false, atlas = nil, labels = {},
}
BattleBayDeluxe.tournament_mode_selector.N[BattleBayDeluxe.tournament_mode_selector.BG], BattleBayDeluxe.tournament_mode_selector.N[BattleBayDeluxe.tournament_mode_selector.PILL], BattleBayDeluxe.tournament_mode_selector.N[BattleBayDeluxe.tournament_mode_selector.TXT] = 1, #BattleBayDeluxe.tournament_mode_selector.MODES, #BattleBayDeluxe.tournament_mode_selector.MODES + 1
BattleBayDeluxe.tournament_mode_selector.TEXT = 378156699 --[[_text_guide01]]
-- Commands this file sends in either menu.
BattleBayDeluxe.tournament.DISARM = BattleBayDeluxe.tournament.DISARM or @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_DISARM@
BattleBayDeluxe.tournament.RULE_SELECT = BattleBayDeluxe.tournament.RULE_SELECT or @crc:CMND_VRFW_RULE_ENGINE_SELECT@
BattleBayDeluxe.tournament_mode_selector.BTN = @crc:_text_btn01@
BattleBayDeluxe.tournament_mode_selector.PLATE_BASE = @crc:_win_guide_base01@

-- The logger is created on first use.
function BattleBayDeluxe.tournament_mode_log(...)
  BattleBayDeluxe.tournament_mode_selector.logger = BattleBayDeluxe.tournament_mode_selector.logger or VRFW.logger.new("BattleBayDeluxe.tournament_mode")
  BattleBayDeluxe.tournament_mode_selector.logger(...)
end

local function same(layer, i, state)
  local M = BattleBayDeluxe.tournament_mode_selector
  local k = tostring(layer) .. ":" .. tostring(i)
  if M.shown[k] == state then
    return true
  end
  M.shown[k] = state
  return false
end

-- Opens every selector layer instance once (they are not opened with their group).
local function open_all()
  local M = BattleBayDeluxe.tournament_mode_selector
  for layer, n in pairs(M.N) do
    for i = 0, n - 1 do
      local k = tostring(layer) .. ":" .. i
      if not M.opened[k] then
        M.opened[k] = true
        funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, layer, i)
      end
    end
  end
end

local function quad(layer, i, spr, x, y, w, h, show, g)
  local M = BattleBayDeluxe.tournament_mode_selector
  local state = show and string.format("%s %.1f %.1f %.1f %.1f %.2f", tostring(spr), x, y, w, h, g) or "off"
  if same(layer, i, state) then
    return
  end
  if not show then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
    return
  end
  if M.atlas == nil then
    M.atlas = BattleBayDeluxe.tournament_crc(M.ATLAS)
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, true)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, layer, w / M.Q, h / M.Q, 1, i)
  funcLuaMenuCommand(558735651 --[[sprite]], layer, M.atlas, spr, M.NODE_QUAD, 0, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, x, -y, 0, i)
  funcLuaMenuCommand(@crc:CMND_SET_PRIM_COLOR@, layer, i, M.MESH_QUAD, g, g, g)
end

-- One text (or key glyph) centred on (cx, y).
local function text(i, s, cx, y, scale, show, alpha)
  local M = BattleBayDeluxe.tournament_mode_selector
  if same(M.TXT, i, show and string.format("%s %.1f %.1f %.2f %.2f", s, cx, y, scale, alpha) or "off") then
    return
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, M.TXT, i, show)
  if not show then
    return
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, M.TXT, cx + M.TEXT_CX * scale, -y, 0, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, M.TXT, scale, scale, 1, i)
  funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, M.TXT, i, M.PRIO_TXT, true)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, M.TXT, M.BTN, "", i)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, M.TXT, M.TEXT, s, i)
  funcLuaMenuCommand(@crc:CMND_UPDATE_TEXT_PLATE@, M.TXT, i, M.TEXT)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, M.TXT, M.PLATE_BASE, false, i)
  VRFW.host.menu_command(@crc:CMND_SET_MENU_TEXT_ALPHA@, M.TXT, i, M.TEXT, alpha)
end

-- Key glyph centre x, pill centres (MODES order) and strip width.
function BattleBayDeluxe.tournament_mode_geom()
  local M = BattleBayDeluxe.tournament_mode_selector
  local n = #M.MODES
  local inner = M.PAD + M.KEY_W + M.GAP + n * M.PILL_W + (n - 1) * M.PILL_GAP + M.PAD
  local x0 = M.CX - inner / 2
  local key = x0 + M.PAD + M.KEY_W / 2
  local p1 = x0 + M.PAD + M.KEY_W + M.GAP + M.PILL_W / 2
  local pills = {}
  for i = 1, n do
    pills[i] = p1 + (i - 1) * (M.PILL_W + M.PILL_GAP)
  end
  return key, pills, inner + M.BG_EXTRA
end

-- Draws the selector.
function BattleBayDeluxe.tournament_mode_draw(mode, show, locked)
  local M = BattleBayDeluxe.tournament_mode_selector
  if show then
    open_all()
  end
  local key, pills, bg_w = BattleBayDeluxe.tournament_mode_geom()
  local g = locked and M.LOCK or 1
  quad(M.BG, 0, M.SPR_BG, M.CX, M.Y, bg_w, M.BG_H, show, 1)
  text(0, "<CMD_BBD_MODE_SWITCH>", key, M.Y, M.KEY_S, show, locked and M.DIM or 1)
  for i, m in ipairs(M.MODES) do
    local on = m == mode
    quad(M.PILL, i - 1, on and M.SPR_ON or M.SPR_OFF, pills[i], M.Y, M.PILL_W, M.PILL_H, show, g)
    if show and (M.labels[m] == nil or M.labels[m] == "") then
      M.labels[m] = BattleBayDeluxe.tournament_text(M.LABELS[m])
    end
    text(i, M.labels[m] or "", pills[i], M.Y, M.TEXT_S, show, on and 1 or M.DIM)
  end
end

-- Next mode in MODES, wrapping around.
function BattleBayDeluxe.tournament_mode_next(mode)
  local M = BattleBayDeluxe.tournament_mode_selector
  for i, m in ipairs(M.MODES) do
    if m == mode then
      return M.MODES[i % #M.MODES + 1]
    end
  end
  return M.MODES[1]
end

-- A selector layer set up by the engine
function BattleBayDeluxe.tournament_mode_setup(a1)
  local M = BattleBayDeluxe.tournament_mode_selector
  if M.N[a1] == nil then
    return false
  end
  for k in pairs(M.shown) do
    if k:sub(1, #tostring(a1) + 1) == tostring(a1) .. ":" then
      M.shown[k] = nil
    end
  end
  return true
end

-- Mode of the pill under the pointer, or nil.
local function pointed()
  local M = BattleBayDeluxe.tournament_mode_selector
  local mx, my = funcLuaMenuCommand(558229292 --[[pointer]])
  if type(mx) ~= "number" or type(my) ~= "number" then
    return nil
  end
  local py = -my
  for i, mode in ipairs(M.MODES) do
    local gx, gy = funcLuaMenuCommand(4002164178 --[[GPOS]], M.PILL, i - 1)
    if type(gx) == "number" and type(gy) == "number" and math.abs(mx - gx) <= M.PILL_W / 2
      and math.abs(py - gy) <= M.PILL_H / 2 then
      return mode
    end
  end
  return nil
end

-- Polls whether a switch was requested this frame.
function BattleBayDeluxe.tournament_mode_poll(shown)
  local M = BattleBayDeluxe.tournament_mode_selector
  local key = funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 1332654303 --[[MENU_CTRL]], M.KEY) == true
  local click = funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 1332654303 --[[MENU_CTRL]], M.CLICK) == true
  local kd, cd = key and not M.prev_key, click and not M.prev_click
  M.prev_key, M.prev_click = key, click
  if not shown then
    return nil
  end
  if kd then
    return "toggle"
  end
  if cd then
    return pointed()
  end
  return nil
end


BattleBayDeluxe.tournament_mode_selector.P_GO_T = @crc:battlebaydeluxe_mode_go_tournament@   -- parameter: the top menu opens the tournament after the grid
BattleBayDeluxe.tournament_mode_selector.TOP = 85255651 --[[bb_stadium_top_menu]]
BattleBayDeluxe.tournament_mode_selector.DIFFICULTY = 2996147312 --[[win05_11_select_difficulty_win_base]]

-- Selector state on the grid (shown, mode, locked)
function BattleBayDeluxe.tournament_mode_grid_state()
  local M = BattleBayDeluxe.tournament_mode_selector
  local info = BattleBayDeluxe.tournament_last_info or {}
  local show = funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, M.TOP) == true
    and info.active ~= true and info.ended ~= true
    and not (type(BattleBayDeluxe.roster) == "table" and BattleBayDeluxe.roster.state ~= nil) -- hidden under the bb_draft roster viewer
  local mode = info.armed and (info.fmt == 2 and "league" or "tournament") or "campaign"
  local locked = (BattleBayDeluxe.tournament_grid and BattleBayDeluxe.tournament_grid.co ~= nil)
    or funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) == true
    or funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, M.DIFFICULTY) == true
    or (type(VRFW.battle_bay_pages) == "table" and VRFW.battle_bay_pages.hidden == true)
    or funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, M.READY_BTN) == true
    or info.configured == true or info.pending == true
  return show, mode, locked
end

function BattleBayDeluxe.tournament_mode_grid_switch(to, mode)
  local M = BattleBayDeluxe.tournament_mode_selector
  local info = BattleBayDeluxe.tournament_info()
  if M.ARM_FMT[to] ~= nil then
    if info.active or info.ended then
      -- A run exists.
      VRFW.param.clear(M.P_GO_T)
      VRFW.param.set(M.P_GO_T, 1, "plain")
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3848881948 --[[sy0000]])
      BattleBayDeluxe.tournament_mode_log("grid -> tournament: a run exists, the grid closes for the top menu's tournament")
      funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, 786045682 --[[enjoy_team_select_menu]])
      return
    end
    local ok, why = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.ARM, M.ARM_FMT[to], 0, 0)
    if ok ~= true then
      BattleBayDeluxe.tournament_mode_log("grid ->", to, "refused", tostring(ok), tostring(why))
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
      return
    end
    BattleBayDeluxe.tournament_mode_log("grid ->", to, "armed")
  else
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.DISARM)
    VRFW.host.command(BattleBayDeluxe.tournament.RULE_SELECT, "")
    BattleBayDeluxe.tournament_mode_log("grid -> campaign: disarmed")
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3791946501 --[[sy0004]])
  BattleBayDeluxe.tournament_info()
end

-- During the custom team pick (BattleBayDeluxe.tournament_grid_pick) the selector area shows the pick count
BattleBayDeluxe.tournament_mode_selector.PICK = { COUNT_X = -60, KEY_X = 170, LABEL_X = 262 }
function BattleBayDeluxe.tournament_mode_pick_draw()
  local M, P, pk = BattleBayDeluxe.tournament_mode_selector, BattleBayDeluxe.tournament_mode_selector.PICK, BattleBayDeluxe.tournament_grid.pick
  open_all()
  quad(M.BG, 0, M.SPR_BG, M.CX, M.Y, 10, M.BG_H, false, 1)
  for i = 1, #M.MODES do
    quad(M.PILL, i - 1, M.SPR_OFF, 0, M.Y, M.PILL_W, M.PILL_H, false, 1)
  end
  local line = pk.asking and "pick_order_ask" or pk.notice
  if line then
    text(1, BattleBayDeluxe.tournament_text(line), M.CX, M.Y, M.TEXT_S, true, 1)
    for i = 0, #M.MODES do
      if i ~= 1 then
        text(i, "", 0, M.Y, M.TEXT_S, false, 1)
      end
    end
    return
  end
  local t = BattleBayDeluxe.tournament_text("pick_count")
  local r = VRFW.host.command(910683996, t, "VALUE", pk.n or 1, 0, 0, true)
  t = r or t
  local r2 = VRFW.host.command(910683996, t, "VALUE2", pk.max or 0, 0, 0, true)
  t = r2 or t
  text(1, t, M.CX + P.COUNT_X, M.Y, M.TEXT_S, true, 1)
  text(0, "<CMD_BBD_MODE_SWITCH>", M.CX + P.KEY_X, M.Y, M.KEY_S, true, 1)
  if M.labels.pick == nil or M.labels.pick == "" then
    M.labels.pick = BattleBayDeluxe.tournament_text("pick_accept")
  end
  text(2, M.labels.pick, M.CX + P.LABEL_X, M.Y, M.TEXT_S, true, 1)
  for i = 3, #M.MODES do
    text(i, "", 0, M.Y, M.TEXT_S, false, 1)
  end
end

function BattleBayDeluxe.tournament_mode_grid_step()
  if type(BattleBayDeluxe.tournament_grid) == "table" and BattleBayDeluxe.tournament_grid.pick then
    BattleBayDeluxe.tournament_mode_pick_draw()
    return
  end
  local show, mode, locked = BattleBayDeluxe.tournament_mode_grid_state()
  BattleBayDeluxe.tournament_mode_draw(mode, show, locked)
  local req = BattleBayDeluxe.tournament_mode_poll(show)
  if req == nil then
    return
  end
  local to = req == "toggle" and BattleBayDeluxe.tournament_mode_next(mode) or req
  if to == mode then
    return
  end
  if locked then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
    return
  end
  BattleBayDeluxe.tournament_mode_grid_switch(to, mode)
end


-- Top menu header while the selector's grid is up
BattleBayDeluxe.tournament_mode_selector.HDR = {
  HEADER = 575058101 --[[mainmenu90_01_header]], TITLE = 1220590795 --[[_text_sub_title02]],
  LOGO = 766762856 --[[vs01_47_bb_stadium_header_logo]], GRID = 786045682 --[[enjoy_team_select_menu]],
  SCALE = 0.9, LEFT = 112, MID_Y = 33.6, on = false, origin = nil,
}

function BattleBayDeluxe.tournament_mode_header_step()
  local H = BattleBayDeluxe.tournament_mode_selector.HDR
  local info = BattleBayDeluxe.tournament_last_info or {}
  local want = funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, H.GRID) == true
    and info.active ~= true and info.ended ~= true
  if want then
    if not H.on then
      -- Logo origin on screen (y up), read once per showing to keep the left edge in place.
      local gx, gy = funcLuaMenuCommand(4002164178 --[[global position]], H.LOGO, 0)
      H.origin = (type(gx) == "number" and type(gy) == "number") and {gx, -gy} or {0, 0}
      local k = 1 - H.SCALE
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, H.LOGO, H.SCALE, H.SCALE, 1, 0)
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, H.LOGO, k * (H.LEFT - H.origin[1]),
        -k * (H.MID_Y - H.origin[2]), 0, 0)
      H.on = true
      BattleBayDeluxe.tournament_mode_log("header: logo x" .. H.SCALE .. ", title hidden (team-select grid)")
    end
    -- Blank the title every frame (the game may write it again).
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, H.HEADER, H.TITLE, "", 0)
  elseif H.on then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, H.LOGO, 1, 1, 1, 0)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, H.LOGO, 0, 0, 0, 0)
    H.on = false
    BattleBayDeluxe.tournament_mode_log("header: logo back to its size")
  end
end


do
  local setup = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    if BattleBayDeluxe.tournament_mode_setup(a1) then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2 or 0, false)
      return
    end
    return setup(a1, a2, ...)
  end
  -- A retail function fired by the same press as the selector key is dropped while the selector is shown.
  local fn = OnFunction
  if type(fn) == "function" then
    function OnFunction(a1, a2, ...)
      local M = BattleBayDeluxe.tournament_mode_selector
      local any = false
      for _, v in pairs(M.shown) do
        if v then
          any = true
          break
        end
      end
      if any and funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, 1332654303 --[[MENU_CTRL]], M.KEY) == true then
        BattleBayDeluxe.tournament_mode_log("retail function", tostring(a1), "left out: the press is the selector's key")
        return 1
      end
      return fn(a1, a2, ...)
    end
  end
  local step = Step
  function Step(...)
    local r = table.pack(step(...))
    local ok, err
    if BattleBayDeluxe.tournament_grid ~= nil then
      ok, err = pcall(BattleBayDeluxe.tournament_mode_grid_step)
    elseif BattleBayDeluxe.tournament_state ~= nil and type(BattleBayDeluxe.tournament_mode_top_step) == "function" then
      ok, err = pcall(BattleBayDeluxe.tournament_mode_top_step)
      if ok and type(BattleBayDeluxe.tournament_host) == "table" and BattleBayDeluxe.tournament_host.name == "bb_stadium_top_menu" then
        ok, err = pcall(BattleBayDeluxe.tournament_mode_header_step)
      end
    else
      ok = true
    end
    if not ok then
      BattleBayDeluxe.tournament_mode_log("error", tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end
end
