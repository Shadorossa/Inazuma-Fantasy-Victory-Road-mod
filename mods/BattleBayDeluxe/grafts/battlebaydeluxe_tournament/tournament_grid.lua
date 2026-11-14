-- Campaign team grid while a tournament is armed
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.tournament.ARM = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_ARM@
BattleBayDeluxe.tournament.START = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_START@
BattleBayDeluxe.tournament.GRID = @crc:vs01_43_enjoy_team_select_emblem_icon@
BattleBayDeluxe.tournament.START_BTN = @crc:cmn03_05_cmn_button_b_graphic_text@
BattleBayDeluxe.tournament.GRID_MENU = @crc:enjoy_team_select_menu@
BattleBayDeluxe.tournament_grid = { co = nil, frames = 0, fmt = 0, size = 16, filter = 0, double = 0, national = 0 }
-- The group-stage menu never belongs over this grid
BattleBayDeluxe.tournament.GROUPS_MENU = @crc:battlebaydeluxe_tn_groups_menu@
-- Option rows per mode, top to bottom, and the start button's text key.
BattleBayDeluxe.tournament_grid_rows = {
  tournament = { rows = { "groups", "size", "filter" }, start = "opt_start" },
  league = { rows = { "size", "filter", "national", "double" }, start = "opt_start_league" },
}

-- Option row count of the current mode.
function BattleBayDeluxe.tournament_grid_row_count()
  return #BattleBayDeluxe.tournament_grid_rows[BattleBayDeluxe.tournament_grid_mode()].rows
end

BattleBayDeluxe.tournament.SUB_LR_TEXT = @crc:CMND_UPDATE_SUB_WINDOW_DATA@
BattleBayDeluxe.tournament.P_OPEN = @crc:battlebaydeluxe_tn_panel_open@     -- parameter: the options panel is open (its row count)
BattleBayDeluxe.tournament.P_ENTER = @crc:battlebaydeluxe_tn_panel_enter@   -- parameter: Accept on a row (row + 1), written by the sub window
-- Team counts offered per format, from INFO .sizes (no byes).
BattleBayDeluxe.tournament_grid.sizes = { knockout = {}, groups = {}, league = {} }
BattleBayDeluxe.tournament_grid.FORMATS = { [0] = "knockout", [1] = "groups", [2] = "league" }

-- Returns the options mode.
function BattleBayDeluxe.tournament_grid_mode()
  return BattleBayDeluxe.tournament_grid.fmt == 2 and "league" or "tournament"
end

-- What option the 0-based row shows in the current mode.
function BattleBayDeluxe.tournament_grid_row(row)
  return BattleBayDeluxe.tournament_grid_rows[BattleBayDeluxe.tournament_grid_mode()].rows[row + 1]
end

function BattleBayDeluxe.tournament_grid_sizes()
  local key = BattleBayDeluxe.tournament_grid.FORMATS[BattleBayDeluxe.tournament_grid.fmt] or "knockout"
  -- A league without national teams offers the counts the rest of the pool fills.
  if key == "league" and BattleBayDeluxe.tournament_grid.national == 1 and type(BattleBayDeluxe.tournament_grid.sizes.league_no_national) == "table" then
    key = "league_no_national"
  end
  local l = BattleBayDeluxe.tournament_grid.sizes[key]
  if type(l) ~= "table" then
    return {}
  end
  return l
end

-- Snaps the size to the format's list
function BattleBayDeluxe.tournament_grid_snap_size()
  local l = BattleBayDeluxe.tournament_grid_sizes()
  if #l == 0 then
    return
  end
  local best = nil
  for _, v in ipairs(l) do
    if v == BattleBayDeluxe.tournament_grid.size then
      return
    end
    if v <= BattleBayDeluxe.tournament_grid.size then
      best = v
    end
  end
  BattleBayDeluxe.tournament_grid.size = best or l[1]
end

function BattleBayDeluxe.tournament_grid_option_id(row)
  local what = BattleBayDeluxe.tournament_grid_row(row)
  if what == "groups" then
    return BattleBayDeluxe.tournament_id("opt_groups_" .. tostring(BattleBayDeluxe.tournament_grid.fmt))
  elseif what == "filter" then
    return BattleBayDeluxe.tournament_id("opt_teams_" .. tostring(BattleBayDeluxe.tournament_grid.filter))
  elseif what == "double" then
    return BattleBayDeluxe.tournament_id("opt_double_" .. tostring(BattleBayDeluxe.tournament_grid.double))
  elseif what == "national" then
    return BattleBayDeluxe.tournament_id("opt_national_" .. tostring(BattleBayDeluxe.tournament_grid.national))
  end
  return BattleBayDeluxe.tournament_id("opt_size_" .. tostring(BattleBayDeluxe.tournament_grid.size))
end

-- 0-based row showing `what` in the current mode, nil when none.
function BattleBayDeluxe.tournament_grid_row_of(what)
  for i, w in ipairs(BattleBayDeluxe.tournament_grid_rows[BattleBayDeluxe.tournament_grid_mode()].rows) do
    if w == what then
      return i - 1
    end
  end
  return nil
end

-- Snaps the size after a format or pool change and refreshes the size row when it changed.
function BattleBayDeluxe.tournament_grid_resnap_size_row()
  local G = BattleBayDeluxe.tournament_grid
  local before = G.size
  BattleBayDeluxe.tournament_grid_snap_size()
  local srow = BattleBayDeluxe.tournament_grid_row_of("size")
  if G.size ~= before and srow ~= nil then
    funcLuaMenuCommand(BattleBayDeluxe.tournament.SUB_LR_TEXT, srow, BattleBayDeluxe.tournament_grid_option_id(srow), "", true)
  end
end

function BattleBayDeluxeTournamentGridOptionMove(row, dir)
  local G = BattleBayDeluxe.tournament_grid
  local what = BattleBayDeluxe.tournament_grid_row(row)
  if what == "groups" then
    G.fmt = 1 - G.fmt
    -- The other format may not offer the count shown (a group stage needs 8 or more).
    BattleBayDeluxe.tournament_grid_resnap_size_row()
  elseif what == "size" then
    local l = BattleBayDeluxe.tournament_grid_sizes()
    local n, k = #l, 1
    if n == 0 then
      return
    end
    for i, v in ipairs(l) do
      if v == G.size then
        k = i
      end
    end
    k = k + ((dir == 1) and 1 or -1)
    if k > n then
      k = 1
    elseif k < 1 then
      k = n
    end
    G.size = l[k]
  elseif what == "filter" then
    G.filter = (G.filter + ((dir == 1) and 1 or 2)) % 3
  elseif what == "double" then
    G.double = 1 - G.double
  elseif what == "national" then
    G.national = 1 - G.national
    -- The pool without national teams may not fill the count shown.
    BattleBayDeluxe.tournament_grid_resnap_size_row()
  else
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0004@)
  funcLuaMenuCommand(BattleBayDeluxe.tournament.SUB_LR_TEXT, row, BattleBayDeluxe.tournament_grid_option_id(row), "", true)
end

-- Sub window list-item refresh callback (called by name)
function BattleBayDeluxeTournamentGridOptionItem(a1, a2)
  VRFW.host.command(830228314 --[[cross-menu call]], BattleBayDeluxe.tournament.SUB_WINDOW, "BattleBayDeluxeTournamentSubWindowPanelDress", BattleBayDeluxe.tournament_grid_row_count())
end

-- Sub window end callback (called by name)
function BattleBayDeluxeTournamentGridOptionDone(r)
  BattleBayDeluxe.tournament_grid.opt_result = r
  if r ~= -1 then
    funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW)
  end
end

-- Shows or hides the grid menu's own cursor arrow (the popup is another menu).
function BattleBayDeluxe.tournament_grid_cursor(on)
  VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, @crc:cmn05_01_cursor@, 0, on)
end

-- Options panel in a coroutine
function BattleBayDeluxe.tournament_grid_options()
  local G = BattleBayDeluxe.tournament_grid
  G.keep = false
  G.new_picks = true
  while true do
    local r = BattleBayDeluxe.tournament_grid_options_once()
    if r ~= "pick" then
      G.keep = false
      return r
    end
    G.keep = true
    local order = BattleBayDeluxe.tournament_grid_pick(G.size)
    if order ~= nil then
      G.keep = false
      return BattleBayDeluxe.tournament_grid_arm(G.size, order == "chosen" and 1 or 0)
    end
  end
end

-- Arms the tournament with the confirmed options
function BattleBayDeluxe.tournament_grid_arm(size, ordered)
  local G = BattleBayDeluxe.tournament_grid
  local ok, why = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.ARM, G.fmt, size, 1, G.filter, G.double, G.national, ordered or 0)
  if ok == true then
    BattleBayDeluxe.tournament_log("options: start", G.fmt, size, G.filter, G.double, G.national, ordered or 0)
    BattleBayDeluxe.tournament_info()
    return true
  end
  BattleBayDeluxe.tournament_log("options not armed", tostring(ok), tostring(why))
  return false
end

-- Sets the bottom button's label of the open options panel.
function BattleBayDeluxe.options_panel_set_start(text)
  VRFW.host.command(830228314 --[[cross-menu call]], BattleBayDeluxe.tournament.SUB_WINDOW, "UpdateTextSubListItemLR", 0, text, text,
    funcLuaCommand(@crc:CMND_TEXT_GET@, 932232033), funcLuaCommand(@crc:CMND_TEXT_GET@, 2223530141))
end

-- Runs the retail left / right sub window with spec.rows rows and a start button, in a coroutine; returns its result.
-- spec: state (.opt_result), rows, ids, move_cb / item_cb / done_cb (global names), refresh(row), start_text(), accept(row), waiting(frames).
function BattleBayDeluxe.options_panel_run(spec)
  local state = spec.state
  state.opt_result = nil
  VRFW.param.clear(BattleBayDeluxe.tournament.P_ENTER)
  VRFW.param.clear(BattleBayDeluxe.tournament.P_OPEN)
  VRFW.param.set(BattleBayDeluxe.tournament.P_OPEN, spec.rows, "plain")
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
  MENU_DEF.SetSubWindowCallback_MoveSubIndex(spec.move_cb)
  MENU_DEF.SetSubwindowCallback_UpdateListItem(spec.item_cb)
  BattleBayDeluxe.tournament_grid_cursor(false)
  local enabled = {}
  for row = 1, spec.rows do
    enabled[row] = 1
  end
  MENU_DEF.OpenSubWindow(spec.done_cb, "", spec.rows, spec.ids, 5, 0, enabled, 0, false, false, 3)
  local f = 0
  while funcLuaCommand(@crc:CMND_IS_OPEN_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW, @crc:cmn05_01_cursor@)
    ~= true and f < 120 do
    f = f + 1
    coroutine.yield()
  end
  for row = 0, spec.rows - 1 do
    spec.refresh(row)
  end
  BattleBayDeluxe.options_panel_set_start(spec.start_text())
  -- Dress the panel (BattleBayDeluxeTournamentSubWindowPanelDress in the sub window).
  VRFW.host.command(830228314 --[[cross-menu call]], BattleBayDeluxe.tournament.SUB_WINDOW, "BattleBayDeluxeTournamentSubWindowPanelDress", spec.rows)
  local waited = 0
  while state.opt_result == nil and funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) do
    BattleBayDeluxe.tournament_grid_cursor(false)
    -- Waits for the player.
    waited = waited + 1
    if spec.waiting ~= nil and waited % 300 == 0 then
      spec.waiting(waited)
    end
    if VRFW.param.has(BattleBayDeluxe.tournament.P_ENTER) then
      local v = VRFW.param.get(BattleBayDeluxe.tournament.P_ENTER)
      VRFW.param.clear(BattleBayDeluxe.tournament.P_ENTER)
      if type(v) == "number" and v >= 1 then
        spec.accept(v - 1)
      end
    end
    coroutine.yield()
  end
  BattleBayDeluxe.tournament_grid_cursor(true)
  VRFW.param.clear(BattleBayDeluxe.tournament.P_OPEN)
  VRFW.param.clear(BattleBayDeluxe.tournament.P_ENTER)
  MENU_DEF.SetSubWindowCallback_MoveSubIndex("OnMoveSubIndex")
  MENU_DEF.SetSubwindowCallback_UpdateListItem("OnSubWindowUpdateListItem")
  local r = state.opt_result
  state.opt_result = nil
  return r
end

function BattleBayDeluxe.tournament_grid_options_once()
  local info = BattleBayDeluxe.tournament_info()
  local G = BattleBayDeluxe.tournament_grid
  if G.keep then
    info = { sizes = G.sizes }
  end
  if not G.keep then
    G.fmt = info.fmt or (info.defaults or {}).fmt or 0
    G.size = info.size or (info.defaults or {}).size or 16
    G.filter = info.filter or (info.defaults or {}).filter or 0
    G.double = info.double or (info.defaults or {}).double or 0
    G.national = info.no_national or (info.defaults or {}).no_national or 0
    if type(info.sizes) == "table" then
      G.sizes = info.sizes
    end
  end
  G.want_pick = false
  BattleBayDeluxe.tournament_grid_snap_size()
  -- The panel's row count
  local nrows = BattleBayDeluxe.tournament_grid_row_count()
  local ids = {}
  for row = 0, nrows - 1 do
    ids[row + 1] = BattleBayDeluxe.tournament_grid_option_id(row)
  end
  local r = BattleBayDeluxe.options_panel_run({
    state = G,
    rows = nrows,
    ids = ids,
    move_cb = "BattleBayDeluxeTournamentGridOptionMove",
    item_cb = "BattleBayDeluxeTournamentGridOptionItem",
    done_cb = "BattleBayDeluxeTournamentGridOptionDone",
    refresh = function(row)
      funcLuaMenuCommand(BattleBayDeluxe.tournament.SUB_LR_TEXT, row, BattleBayDeluxe.tournament_grid_option_id(row), "", true)
    end,
    start_text = function()
      return BattleBayDeluxe.tournament_text(BattleBayDeluxe.tournament_grid_rows[BattleBayDeluxe.tournament_grid_mode()].start)
    end,
    accept = function(row)
      if BattleBayDeluxe.tournament_grid_row(row) == "filter" and G.filter == 2 then
        -- Accept on the filter row with "picked by hand" opens the team picker, like the confirmation.
        G.want_pick = true
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
        funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW)
      else
        BattleBayDeluxeTournamentGridOptionMove(row, 1)
      end
    end,
    waiting = function(waited)
      BattleBayDeluxe.tournament_log("options: window still open after", waited, "frames; group tables menu open",
        funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.GROUPS_MENU) == true)
      pcall(BattleBayDeluxe.tournament_grid_close_groups, "options window waiting")
    end,
  })
  if G.want_pick then
    G.want_pick = false
    return "pick"
  end
  if r == nil or r == -1 then
    BattleBayDeluxe.tournament_log("options: back to the grid")
    return false
  end
  -- The player picked by hand.
  if G.filter == 2 then
    return "pick"
  end
  return BattleBayDeluxe.tournament_grid_arm(G.size, 0)
end


-- Hand-picked teams on the campaign grid
BattleBayDeluxe.tournament.PICK = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_PICK@
BattleBayDeluxe.tournament_picker = {
  MARK = @crc:battlebaydeluxe_pick_mark@, SPR = @crc:bbd_md_check@, ATLAS = "#/menu/220_img/bbd_md/bbd_md.g4tx",
  NUMBER = @crc:battlebaydeluxe_pick_number@,
  N = 40,                    -- instances of the mark and number layers
  DX = 30, DY = -30, SIZE = 40, Q = 36, NODE_QUAD = @crc:icon_new01@, MESH_QUAD = @crc:_icon_new01@,
  NUMBER_DX = -34, NUMBER_SCALE = 0.8, NUMBER_PRIORITY = 698,   -- the pick number: left of the check mark
  KEY = @crc:CMD_BBD_MODE_SWITCH@,
}

-- Pick order from the scripts' list (the player's team = 1).
function BattleBayDeluxe.tournament_grid_pick_order(pk, teams)
  pk.order = {}
  local player = BattleBayDeluxe.tournament_grid.player or 0
  if player ~= 0 then
    pk.order[player] = 1
  end
  for i, t in ipairs(type(teams) == "table" and teams or {}) do
    pk.order[t] = i + 1
  end
end

function BattleBayDeluxe.tournament_grid_pick_number(i, on, number, x, y)
  local P, M = BattleBayDeluxe.tournament_picker, BattleBayDeluxe.tournament_mode_selector
  P.number_opened = P.number_opened or {}
  if on and not P.number_opened[i] then
    P.number_opened[i] = true
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, P.NUMBER, i)
  end
  if not P.number_opened[i] then
    return
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, P.NUMBER, i, on)
  if not on then
    return
  end
  local s = P.NUMBER_SCALE
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, P.NUMBER, x + P.NUMBER_DX + M.TEXT_CX * s, -y, 0, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, P.NUMBER, s, s, 1, i)
  funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, P.NUMBER, i, P.NUMBER_PRIORITY, true)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, P.NUMBER, M.BTN, "", i)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, P.NUMBER, M.TEXT, tostring(number), i)
  funcLuaMenuCommand(@crc:CMND_UPDATE_TEXT_PLATE@, P.NUMBER, i, M.TEXT)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, P.NUMBER, M.PLATE_BASE, false, i)
end

-- Marks and pick numbers on the grid tiles (written only when a tile's state changes).
function BattleBayDeluxe.tournament_grid_pick_marks(show)
  local P, pk = BattleBayDeluxe.tournament_picker, BattleBayDeluxe.tournament_grid.pick
  P.state = P.state or {}
  P.opened = P.opened or {}
  if P.atlas == nil then
    P.atlas = BattleBayDeluxe.tournament_crc(P.ATLAS)
  end
  local tiles = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, BattleBayDeluxe.tournament.GRID) or 0
  for i = 0, P.N - 1 do
    local on, x, y, number = false, 0, 0, 0
    if show and pk and i < tiles and funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, BattleBayDeluxe.tournament.GRID, i) == true then
      local team = BattleBayDeluxe.roster_team_of(i)
      number = team ~= 0 and pk.order[team] or nil
      if number then
        local gx, gy = funcLuaMenuCommand(@crc:CMND_GET_LAYER_GLOBAL_POS@ --[[GPOS]], BattleBayDeluxe.tournament.GRID, i)
        if type(gx) == "number" and type(gy) == "number" then
          on, x, y = true, gx + P.DX, -gy + P.DY
        end
      end
    end
    local st = on and string.format("%.0f %.0f %d", x, y, number) or "off"
    if P.state[i] ~= st then
      P.state[i] = st
      if on and not P.opened[i] then
        P.opened[i] = true
        funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, P.MARK, i)
      end
      if P.opened[i] then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, P.MARK, i, on)
      end
      if on then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_SCALE@, P.MARK, P.SIZE / P.Q, P.SIZE / P.Q, 1, i)
        funcLuaMenuCommand(558735651 --[[sprite]], P.MARK, P.atlas, P.SPR, P.NODE_QUAD, 0, i)
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, P.MARK, x, -y, 0, i)
        funcLuaMenuCommand(@crc:CMND_SET_PRIM_COLOR@, P.MARK, i, P.MESH_QUAD, 1, 1, 1)
      end
      pcall(BattleBayDeluxe.tournament_grid_pick_number, i, on, number, x, y)
    end
  end
end

-- A tile decided while picking
function BattleBayDeluxe.tournament_grid_pick_tile(tile)
  local pk = BattleBayDeluxe.tournament_grid.pick
  local team = BattleBayDeluxe.roster_team_of(tile)
  if team == 0 or (type(BattleBayDeluxe.draft) == "table" and team == BattleBayDeluxe.draft.TEAM) then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
    return
  end
  local r = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.PICK, 1, BattleBayDeluxe.tournament_grid.fmt, team, BattleBayDeluxe.tournament_grid.player or 0)
  if type(r) ~= "table" then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
    return
  end
  if r.ok then
    BattleBayDeluxe.tournament_grid_pick_order(pk, r.teams)
    pk.n = r.n or pk.n
    pk.notice = nil
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0004@)
    if r.on and pk.n >= pk.max then
      pk.done = "full"
    end
  else
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
    pk.notice = r.why == "club" and "pick_club" or nil
  end
  BattleBayDeluxe.tournament_log("picker: tile", tile, "team", VRFW.ids.hex_text(team), r.ok and (r.on and "in" or "out")
    or ("refused " .. tostring(r.why)), "count", pk.n)
end

-- Picker for `need` teams (the player's included), in the options coroutine
function BattleBayDeluxe.tournament_grid_pick(need)
  local G = BattleBayDeluxe.tournament_grid
  local r = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.PICK, G.new_picks and 5 or 0, G.fmt, need, G.player or 0)
  if type(r) ~= "table" then
    BattleBayDeluxe.tournament_log("picker: the scripts did not answer")
    return nil
  end
  G.new_picks = false
  local pk = { order = {}, n = r.n or 1, max = r.max or need, done = nil, prev = true }
  BattleBayDeluxe.tournament_grid_pick_order(pk, r.teams)
  G.pick = pk
  BattleBayDeluxe.tournament_grid_cursor(true)
  BattleBayDeluxe.tournament_log("picker open: format", G.fmt, "count", pk.n, "of", pk.max)
  local answer = nil
  while answer == nil do
    while pk.done == nil do
      local key = funcLuaCommand(@crc:CMND_CHECK_INPUT_CMD@, @crc:MENU_CTRL@, BattleBayDeluxe.tournament_picker.KEY) == true
      if key and not pk.prev then
        if pk.n >= pk.max then
          pk.done = "full"
        else
          funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
        end
      end
      pk.prev = key
      pcall(BattleBayDeluxe.tournament_grid_pick_marks, true)
      coroutine.yield()
    end
    if pk.done ~= "full" then
      break
    end
    pcall(BattleBayDeluxe.tournament_grid_pick_marks, true)
    BattleBayDeluxe.tournament_log("picker: count reached", pk.n, "of", pk.max)
    pk.asking = true
    BattleBayDeluxe.tournament_grid_cursor(false)
    local c = BattleBayDeluxe.tournament_choose({ BattleBayDeluxe.tournament_id("pick_order_chosen"), BattleBayDeluxe.tournament_id("pick_order_random") }, 0)
    pk.asking = false
    BattleBayDeluxe.tournament_grid_cursor(true)
    if c == 0 then
      answer = "chosen"
    elseif c == 1 then
      answer = "random"
    else
      pk.done, pk.prev = nil, true
    end
    BattleBayDeluxe.tournament_log("picker: order", answer or "back to the picks")
  end
  local c = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.PICK, answer and 2 or 3, G.fmt, 0, G.player or 0)
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, answer and @crc:sy0000@ or @crc:sy0006@)
  G.pick = nil
  pcall(BattleBayDeluxe.tournament_grid_pick_marks, false)
  BattleBayDeluxe.tournament_log("picker closed:", answer or "cancel", "count", type(c) == "table" and c.n or "?")
  return answer
end

-- Sends the difficulty to the tournament, then closes the grid.
function BattleBayDeluxe.tournament_grid_start(a1, a2, prev)
  local idx = 0
  local okd, d = pcall(GetSelectDifficultyIdx)
  if okd and type(d) == "number" then
    idx = d
  end
  local r = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.START, idx + 1)
  BattleBayDeluxe.tournament_log("start: difficulty", idx + 1, type(r) == "table" and tostring(r.ok) or "busy")
  if type(r) == "table" and r.ok == false and not r.waiting then
    BattleBayDeluxe.tournament_grid_fail("start refused: " .. tostring(r.why))
    return
  end
  local info
  for _ = 1, 120 do
    info = BattleBayDeluxe.tournament_info()
    if info.active or info.campaign then
      break
    end
    coroutine.yield()
  end
  if info.active then
    BattleBayDeluxe.tournament_log("start: the tournament runs, the grid closes (the bracket on the top menu)")
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
    funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.tournament.GRID_MENU)
    return
  end
  if info.campaign and prev ~= nil then
    BattleBayDeluxe.tournament_log("the game started its own campaign (the Decide hook did not run): a plain campaign")
    prev(a1, a2)
    return
  end
  BattleBayDeluxe.tournament_grid_fail("no tournament after the start (log of scripts/tournament.lua)")
end

function BattleBayDeluxe.tournament_grid_close_groups(why)
  if not VRFW.child_menu.close(BattleBayDeluxe.tournament.GROUPS_MENU, "over the team grid") then
    BattleBayDeluxe.tournament_grid.groups_left = nil
    return false
  end
  if not BattleBayDeluxe.tournament_grid.groups_left then
    BattleBayDeluxe.tournament_grid.groups_left = true
    BattleBayDeluxe.tournament_log("grid: the group tables were still open over the team grid (" .. tostring(why) .. "): closed")
  end
  return true
end

-- Handles a failed start.
function BattleBayDeluxe.tournament_grid_fail(why)
  BattleBayDeluxe.tournament_log("start failed:", tostring(why))
  -- Two rows (message and Accept)
  pcall(BattleBayDeluxe.tournament_choose, { BattleBayDeluxe.tournament_id("start_failed"), BattleBayDeluxe.tournament_id("pick_accept") }, 1)
end

do
  Wrap("BattleBayDeluxe.tournament_grid", "OnDecideFocus", { around = function(decide, a1, a2, ...)
    local info = BattleBayDeluxe.tournament_last_info or {}
    -- The team picker owns the tiles.
    if BattleBayDeluxe.tournament_grid.pick then
      if BattleBayDeluxe.tournament_grid.pick.asking then
        return 1
      end
      if a1 == BattleBayDeluxe.tournament.GRID then
        pcall(BattleBayDeluxe.tournament_grid_pick_tile, a2)
      else
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
      end
      return 1
    end
    -- Log the accept path (layer, index, tournament state, menus over the grid).
    if a1 == BattleBayDeluxe.tournament.GRID or a1 == BattleBayDeluxe.tournament.START_BTN then
      pcall(function()
        local groups = BattleBayDeluxe.tournament_grid_close_groups("team accept")
        BattleBayDeluxe.tournament_log("grid accept: layer " .. tostring(a1) .. " index " .. tostring(a2) .. ", armed " .. tostring(info.armed) ..
          ", configured " .. tostring(info.configured) .. ", pending " .. tostring(info.pending) .. ", running coroutine " ..
          tostring(BattleBayDeluxe.tournament_grid.co ~= nil) .. ", group tables were open " .. tostring(groups) .. ", sub window open " ..
          tostring(funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) == true))
      end)
    end
    if BattleBayDeluxe.tournament_grid.co == nil and info.armed then
      if a1 == BattleBayDeluxe.tournament.GRID and not info.configured then
        -- The player's team (always in the hand-picked list).
        local okp, team = pcall(BattleBayDeluxe.roster_team_of, a2)
        BattleBayDeluxe.tournament_grid.player = okp and team or 0
        local args = table.pack(a1, a2, ...)
        BattleBayDeluxe.tournament_grid.co = coroutine.create(function()
          if BattleBayDeluxe.tournament_grid_options() then
            decide(table.unpack(args, 1, args.n))
          end
        end)
        return 1
      end
      if a1 == BattleBayDeluxe.tournament.START_BTN and info.configured then
        BattleBayDeluxe.tournament_grid.start_sent = true
        BattleBayDeluxe.tournament_grid.co = coroutine.create(function()
          BattleBayDeluxe.tournament_grid_start(a1, a2, decide)
        end)
        return 1
      end
    end
    return decide(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.tournament_grid", "OnBack", { around = function(back, a1, ...)
    if BattleBayDeluxe.tournament_grid.pick then
      if not BattleBayDeluxe.tournament_grid.pick.asking then
        BattleBayDeluxe.tournament_grid.pick.done = "cancel"
      end
      return 1
    end
    return back(a1, ...)
  end })

  Wrap("BattleBayDeluxe.tournament_grid", "Step", { around = function(step, ...)
    local r = table.pack(step(...))
    local G = BattleBayDeluxe.tournament_grid
    if G.co ~= nil then
      local ok, err = coroutine.resume(G.co)
      if not ok then
        BattleBayDeluxe.tournament_log("grid error", tostring(err))
      end
      if not ok or coroutine.status(G.co) == "dead" then
        G.co = nil
      end
    else
      -- Refresh the tournament state for the decides (scripts may be busy then)
      G.frames = G.frames + 1
      local info = BattleBayDeluxe.tournament_last_info or {}
      local every = (info.armed and info.configured) and 10 or 30
      if BattleBayDeluxe.tournament_last_info == nil or G.frames % every == 1 then
        local t = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.INFO)
        if type(t) == "table" then
          BattleBayDeluxe.tournament_last_info = t
          info = t
        end
      end
      if not info.pending then
        G.start_sent = false
      end
      if info.pending and not G.start_sent then
        G.start_sent = true
        BattleBayDeluxe.tournament_log("start: the run is drawn (the start pressed), the difficulty goes to the tournament")
        G.co = coroutine.create(function()
          BattleBayDeluxe.tournament_grid_start(nil, nil, nil)
        end)
      elseif type(info.failed) == "string" and info.failed ~= "" then
        local why = info.failed
        info.failed = nil
        G.co = coroutine.create(function()
          BattleBayDeluxe.tournament_grid_fail(why)
        end)
      end
    end
    return table.unpack(r, 1, r.n)
  end })
end
