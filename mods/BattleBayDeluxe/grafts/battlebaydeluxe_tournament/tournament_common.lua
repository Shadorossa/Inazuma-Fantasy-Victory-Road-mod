-- Shared tournament helpers appended to every screen the tournament touches.
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.tournament = BattleBayDeluxe.tournament or {
  INFO = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_INFO@,
  CI = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_CAMPAIGN_INFO@,
  CAMPAIGN = @crc:CMND_GET_BB_STADIUM_CAMPAIGN_INFO@,
  SUB_WINDOW = @crc:sub_window@,
  TRIES = 90,
}
-- The logger is created on first use.
function BattleBayDeluxe.tournament_logger()
  BattleBayDeluxe.tournament.logger = BattleBayDeluxe.tournament.logger or VRFW.logger.new("BattleBayDeluxe.tournament")
  return BattleBayDeluxe.tournament.logger
end

function BattleBayDeluxe.tournament_log(...)
  BattleBayDeluxe.tournament_logger()(...)
end

-- Calls a mod script command
function BattleBayDeluxe.tournament_call(cmd, ...)
  local _, main = coroutine.running()
  local tries = main and 1 or BattleBayDeluxe.tournament.TRIES
  for k = 1, tries do
    local r = table.pack(VRFW.host.command(cmd, ...))
    if r[1] ~= nil then
      return table.unpack(r, 1, r.n)
    end
    if k < tries then
      coroutine.yield()
    end
  end
  BattleBayDeluxe.tournament_log("busy: no answer", cmd)
  return nil
end

-- Reads the tournament state.
function BattleBayDeluxe.tournament_info()
  local t = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.INFO)
  if type(t) == "table" then
    BattleBayDeluxe.tournament_last_info = t
    return t
  end
  return BattleBayDeluxe.tournament_last_info or {}
end

function BattleBayDeluxe.tournament_campaign_info(sub, i)
  if sub ~= 1 and sub ~= 3 then
    return false
  end
  local handled, v = VRFW.host.command(BattleBayDeluxe.tournament.CI, sub, i or 0)
  if handled ~= nil then
    if handled == true then
      return true, v
    end
    return false
  end
  -- Handles the case where the scripts are busy.
  local t = BattleBayDeluxe.tournament_last_info
  if type(t) == "table" and t.active and t.loaded and t.ci1 ~= nil then
    if sub == 1 then
      return true, t.ci1
    end
    return true, (t.ci3 and t.ci3[(i or 0) + 1]) or 0
  end
  return false
end

-- True when a tournament is armed or running
function BattleBayDeluxe.tournament_on()
  local t = VRFW.host.command(BattleBayDeluxe.tournament.INFO)
  if type(t) == "table" then
    BattleBayDeluxe.tournament_last_info = t
    return t.active == true or t.armed == true
  end
  return false
end

-- Runs f(...) with funcLuaMenuCommand answering CMND_GET_BB_STADIUM_CAMPAIGN_INFO from the tournament first.
function BattleBayDeluxe.tournament_with_campaign_info(f, ...)
  if type(funcLuaMenuCommand) ~= "function" or not BattleBayDeluxe.tournament_on() then
    return f(...)
  end
  local menu_cmd = funcLuaMenuCommand
  local wrap
  wrap = function(c, ...)
    if c == BattleBayDeluxe.tournament.CAMPAIGN then
      local sub, i = ...
      local h, v = BattleBayDeluxe.tournament_campaign_info(sub, i)
      if h then
        return v
      end
    end
    return menu_cmd(c, ...)
  end
  funcLuaMenuCommand = wrap
  local r = table.pack(pcall(f, ...))
  if funcLuaMenuCommand == wrap then
    funcLuaMenuCommand = menu_cmd
  end
  if not r[1] then
    error(r[2], 0)
  end
  return table.unpack(r, 2, r.n)
end

-- Wraps the retail campaign-info readers once per VM
if BattleBayDeluxe.tournament_wrapped_campaign_info == nil and SetupWindowParams == nil then
  BattleBayDeluxe.tournament_wrapped_campaign_info = true
  for _, name in ipairs({ "SetupParam", "OnSetupLayer" }) do
    Wrap("BattleBayDeluxe.tournament_campaign_info", name, { around = function(previous, ...)
      return BattleBayDeluxe.tournament_with_campaign_info(previous, ...)
    end })
  end
end

-- Wraps sub_window_group only.
if BattleBayDeluxe.tournament_wrapped_sub_window == nil and SetupWindowParams ~= nil then
  BattleBayDeluxe.tournament_wrapped_sub_window = true
  -- Called by the grid by name
  function BattleBayDeluxeTournamentSubWindowPanelDress(rows)
    for r = 0, (rows or 2) - 1 do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, @crc:win05_08_sub_list_item_lr@,
        @crc:_icon_rank_dmy01@, false, r)
    end
    local loc = BattleBayDeluxe.tournament_sub_window_locators[rows or 2] or @crc:win05_17_sub_list_locator_lr@
    funcLuaMenuCommand(558735651, loc,
      CRC32("#/menu/107_vs/vs01/vs01_21/<LG>/vs01_21.g4tx"), CRC32("gtxt_settings01"), CRC32("gtxt_list_lr01"), 0, 0)
    return true
  end
  -- Writes a string into a row of the left / right window (called by name from the options panel).
  function BattleBayDeluxeSubWindowRowText(row, text)
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, @crc:win05_08_sub_list_item_lr@, @crc:_text_list01_on@, text, row)
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, @crc:win05_08_sub_list_item_lr@, @crc:_text_list01_off@, text, row)
    return true
  end
  -- The retail left / right window shows 2 rows
  BattleBayDeluxe.tournament_sub_window_locators = { [3] = @crc:battlebaydeluxe_tn_opts_locator@,
    [4] = @crc:battlebaydeluxe_tn_opts4_locator@ }
  -- Upward shift (px) per row count
  BattleBayDeluxe.tournament_sub_window_locator_shift_up = { [4] = 121 }
  -- Row count of the open tournament panel (parameter battlebaydeluxe_tn_panel_open), 2 otherwise.
  function BattleBayDeluxe.tournament_sub_window_left_right_rows()
    if not VRFW.param.has(@crc:battlebaydeluxe_tn_panel_open@) then
      return 2
    end
    local n = VRFW.param.get(@crc:battlebaydeluxe_tn_panel_open@)
    if type(n) == "number" and n > 2 then
      return n
    end
    return 2
  end
  function BattleBayDeluxe.tournament_sub_window_extra_rows(rows)
    local ROW, LOC = @crc:win05_08_sub_list_item_lr@, @crc:win05_17_sub_list_locator_lr@
    -- The copy takes the retail locator position set in SetupWindowParams.
    local x, y = VRFW.host.menu_command(@crc:CMND_GET_LAYER_LOCAL_POS@, LOC, 0)
    local loc = BattleBayDeluxe.tournament_sub_window_locators[rows]
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, LOC, 0)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, loc, 0)
    if type(x) == "number" and type(y) == "number" then
      -- A taller copy moves up by its extra height so its button stays on screen.
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, loc, x, y + (BattleBayDeluxe.tournament_sub_window_locator_shift_up[rows] or 0), 0)
    end
    for i = 2, rows - 1 do
      funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, ROW, i)
    end
    funcLuaMenuCommand(@crc:CMND_RUN_PHOTO_START_INFO@ --[[list item count]], ROW, rows)
    funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, ROW, @crc:select_cur@, 0, rows)
    return true
  end
  -- TournamentChoose panel (battlebaydeluxe_tn_panel_center = row count)
  BattleBayDeluxe.TournamentSubWindowRowH, BattleBayDeluxe.tournament_sub_window_pad = 90, 27
  function BattleBayDeluxe.tournament_sub_window_panel()
    if not VRFW.param.has(@crc:battlebaydeluxe_tn_panel_center@) then
      return false
    end
    local n = VRFW.param.get(@crc:battlebaydeluxe_tn_panel_center@)
    n = (type(n) == "number" and n > 0) and n or 2
    local h = BattleBayDeluxe.tournament_sub_window_pad + BattleBayDeluxe.TournamentSubWindowRowH * n
    -- Optional centre x from battlebaydeluxe_tn_panel_x (the league hub menu stands on the left).
    local cx = 960
    if VRFW.param.has(@crc:battlebaydeluxe_tn_panel_x@) then
      local x = VRFW.param.get(@crc:battlebaydeluxe_tn_panel_x@)
      if type(x) == "number" then
        cx = x
      end
    end
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, @crc:win05_03_sub_list_locator@, cx,
      -(540 - h / 2), 0)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, @crc:win05_04_p1_sub_list_item_add_icon@, 0, false)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, @crc:win05_04_p1_sub_list_item_add_icon@, 0)
    return true
  end
  Wrap("BattleBayDeluxe.tournament_common", "SetupWindowParams", { around = function(setup_params, ...)
    local r = table.pack(setup_params(...))
    local ok, err = pcall(BattleBayDeluxe.tournament_sub_window_panel)
    if not ok then
      BattleBayDeluxe.tournament_log("panel:", tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end })
  Wrap("BattleBayDeluxe.tournament_common", "OnSetupLayer", { around = function(setup_layer, a1, a2, ...)
    if a1 == @crc:win05_04_p1_sub_list_item_add_icon@ then
      if VRFW.param.has(@crc:battlebaydeluxe_tn_panel_center@) then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2 or 0, false)
        return
      end
    end
    return setup_layer(a1, a2, ...)
  end })
  Wrap("BattleBayDeluxe.tournament_common", "OpenWindow", { around = function(open_window, ...)
    local r = table.pack(open_window(...))
    local rows = BattleBayDeluxe.tournament_sub_window_left_right_rows()
    if rows > 2 then
      local ok, err = pcall(BattleBayDeluxe.tournament_sub_window_extra_rows, rows)
      if not ok then
        BattleBayDeluxe.tournament_log("third row:", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end })
  -- Accept on a panel row hands row + 1 to the grid (battlebaydeluxe_tn_panel_enter) and keeps the window open.
  Wrap("BattleBayDeluxe.tournament_common", "OnEnter", { around = function(enter, a1, a2, ...)
    if a1 == @crc:win05_08_sub_list_item_lr@ then
      if VRFW.param.has(@crc:battlebaydeluxe_tn_panel_open@) then
        VRFW.param.clear(@crc:battlebaydeluxe_tn_panel_enter@)
        VRFW.param.set(@crc:battlebaydeluxe_tn_panel_enter@, (a2 or 0) + 1, "plain")
        return 1
      end
    end
    return enter(a1, a2, ...)
  end })
end

-- crc32 of a text id built at run time (opt_size_16, ko_3, group_2...).
function BattleBayDeluxe.tournament_crc(s)
  return VRFW.ids.crc32(s)
end

function BattleBayDeluxe.tournament_id(key)
  return VRFW.ids.crc32("battlebaydeluxe_tn_" .. key)
end

function BattleBayDeluxe.tournament_text(key)
  local t = VRFW.host.command(@crc:CMND_TEXT_GET@, BattleBayDeluxe.tournament_id(key))
  return t or ""
end

-- Text with <VALUE> filled by the retail text value command.
function BattleBayDeluxe.tournament_text_value(key, n)
  local t = BattleBayDeluxe.tournament_text(key)
  local r = VRFW.host.command(910683996, t, "VALUE", n or 0, 0, 0, true)
  return r or t
end

-- Sub window open size argument per row count.
BattleBayDeluxe.tournament_choose_size = { [1] = 5, [2] = 5, [3] = 1, [4] = 2, [5] = 6, [6] = 3 }
-- Retail sub window list of text ids, in a coroutine
function BattleBayDeluxe.tournament_choose(ids, cursor, keep, x, texts)
  local enabled = {}
  for i = 1, #ids do
    enabled[i] = 1
  end
  -- Wait for the previous window to close and the new one to open, else the closing one reads as a cancel.
  local g = 0
  while funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) == true and g < 300 do
    g = g + 1
    coroutine.yield()
  end
  for _ = 1, 6 do
    coroutine.yield()
  end
  VRFW.param.clear(@crc:battlebaydeluxe_tn_panel_center@)
  VRFW.param.set(@crc:battlebaydeluxe_tn_panel_center@, #ids)
  VRFW.param.clear(@crc:battlebaydeluxe_tn_panel_x@)
  if x ~= nil then
    VRFW.param.set(@crc:battlebaydeluxe_tn_panel_x@, x)
  end
  MENU_DEF.OpenSubWindowDefault(#ids, ids, BattleBayDeluxe.tournament_choose_size[#ids] or 5, cursor or 0, enabled, 0, false, false, 20)
  local f = 0
  while not funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, @crc:win05_03_sub_list_locator@, 0,
    BattleBayDeluxe.tournament.SUB_WINDOW) and f < 120 do
    f = f + 1
    coroutine.yield()
  end
  BattleBayDeluxe.tournament_log("panel open", #ids, "rows, the previous one gone after", g, "frames, came up after", f)
  for i = 1, #ids do
    if texts ~= nil and type(texts[i]) == "string" and texts[i] ~= "" then
      VRFW.host.command(2315959435 --[[sub window row text]], i - 1, texts[i])
    end
  end
  local r = -1
  funcLuaCommand(@crc:CMND_RESET_SUB_WINDOW_RESULT@)
  while funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) and r < 0 do
    r = funcLuaCommand(@crc:CMND_GET_SUB_WINDOW_RESULT@)
    coroutine.yield()
  end
  BattleBayDeluxe.tournament_log("panel choice", r)
  if not keep or r < 0 then
    BattleBayDeluxe.tournament_choose_close()
  end
  return r
end

function BattleBayDeluxe.tournament_choose_close()
  if funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW) then
    funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.tournament.SUB_WINDOW)
  end
  VRFW.param.clear(@crc:battlebaydeluxe_tn_panel_center@)
  VRFW.param.clear(@crc:battlebaydeluxe_tn_panel_x@)
  funcLuaCommand(@crc:CMND_RESET_SUB_WINDOW_RESULT@)
end

-- Retail one-button window with a text id, opened with the tournament's window sound
function BattleBayDeluxe.tournament_window(text_id)
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
  VRFW.question.notice(text_id)
end
