-- BetterQoL, team bank pages: the pager «L2 • • • R2» under the title of the bank window (the dock list of the sub window,
-- layer win05_15_sub_list_locator_doc), drawn by the framework's page row (VRFW_Pager) on the layer util_tb_pager
-- (content\menus\10_win\sub_window.toml). The window is another menu with its own Lua state, so the team dock tells this
-- script the page with the menu event BetterQoL.TeamBankPage (research/grafts/team_banks): (mounted page, pages, rows, true)
-- when it opens the list, (mounted page, pages, rows) after a page turn, (0, 0) before it closes it. A page turn keeps the
-- list open: the rows are drawn again from the mounted page with the window's own functions, so nothing fades. The other
-- users of this window never send it: the layer stays closed for them.
-- Wrappers by assignment (the script has no VRFW_Host host); no engine call at load time.
if BetterQoL_TeamBankPager == nil and type(PostStep) == "function" and type(OnOpenLayer) == "function" then
  local P = {
    EVENT = "BetterQoL.TeamBankPage",
    OWNER = "BetterQoL.team_bank_pager",
    SUB_WINDOW = 968210065,          -- crc32("sub_window")
    WINDOW = 193803588,              -- crc32("win05_15_sub_list_locator_doc")
    LAYER = 2599463680,              -- crc32("util_tb_pager")
    TRACE_PREFIX = "util_tb_pager",  -- the attach rows of content\menus\objects.toml: this + the instance
    DOTS = 32,                       -- the dots of the layer's 34 copies (content\menus\10_win\sub_window.toml)
    PRIORITY = 870,                  -- over the window (859) and its rows (862), under the cursor (999)
    ROOM = 496,                      -- the row's width in px: ends clear of the scroll bar (258 px right of the centre)
    OFFSET_Y = -100,                 -- the row's centre: px under the panel's top edge, between the title and row 01
    MAX_TRIES = 120,                 -- frames to wait for the copies to open
    FIRST_SET = 4017866835,          -- the first team dock's logical set
    CAN_ACTIVE = 1104634465,         -- funcLuaCommand(CAN_ACTIVE, logical set, 0): the retail grey-out rule
    LIST_REFRESH = 4114514990,       -- funcLuaMenuCommand(LIST_REFRESH, list layer): the list redraws its rows on screen
    -- SetBtnEnable value of a dock that cannot be active: the window's OnEnter refuses only 0, its grey look is any value
    -- other than 1. Choosing a row shows that dock, as retail L1 / R1 reaches every dock.
    ROW_CAN_ACTIVE = 1, ROW_GREY_CHOOSABLE = 2,
    want = nil, tries = 0, row = nil,
  }
  BetterQoL_TeamBankPager = P

  local function Log(...)
    pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "BetterQoL team bank pager", ...)
  end

  local function Hide()
    P.want = nil
    if P.row ~= nil and P.row:Opened() then
      P.row:Hide()
    end
  end

  -- places the row once its copies are open. Until the last copy is open a frame costs 2 commands; nothing runs after.
  local function TryShow()
    local want = P.want
    if want == nil then
      return
    end
    P.tries = P.tries + 1
    if P.tries > P.MAX_TRIES then
      P.want = nil
      Log("not shown: the layer did not open")
      return
    end
    if P.row:Opened() then
      local last = P.DOTS + 1
      if funcLuaMenuCommand(VRFW_Cmd.IS_OPEN_LAYER, P.LAYER, last) ~= true
        or funcLuaMenuCommand(VRFW_Cmd.IS_LOADING_LAYER, P.LAYER) == true then
        return
      end
    end
    if P.row:Show(want.pages, want.page, 0, P.OFFSET_Y) then
      P.want = nil
    end
  end

  -- the grey state of every dock of the mounted page, then one retail list refresh: the list calls UpdateListItem for the
  -- rows on screen, which draws each dock plate and its grey look (UpdateBtnGrayMaterial on this window type)
  local function RedrawRows(rows)
    local first = funcLuaCommand(P.FIRST_SET)
    for i = 0, rows - 1 do
      SetBtnEnable(i, funcLuaCommand(P.CAN_ACTIVE, first + i, 0) and P.ROW_CAN_ACTIVE or P.ROW_GREY_CHOOSABLE)
    end
    funcLuaMenuCommand(P.LIST_REFRESH, P.WINDOW)
  end

  local function OnPage(page, pages, rows, opening)
    if rows ~= nil then
      RedrawRows(rows)
    end
    if type(pages) ~= "number" or pages < 2 or type(VRFW_Pager) ~= "table" then
      Hide()
      return
    end
    if not opening and P.row ~= nil then
      P.want = {pages = pages, page = page + 1}
      P.tries = 0
      TryShow()
      return
    end
    P.row = VRFW_Pager.New({layer = P.LAYER, name = "team banks", dots = P.DOTS, room = P.ROOM, prio = P.PRIORITY,
      setup = function(k)
        funcLuaMenuCommand(VRFW_Cmd.SET_LAYER_ATTACH_LOCATOR_TRACE, P.WINDOW, 0, VRFW_Crc32(P.TRACE_PREFIX .. k), true)
      end})
    P.want = {pages = pages, page = page + 1}
    P.tries = 0
    TryShow()
  end

  local open_layer = OnOpenLayer
  OnOpenLayer = function(layer, idx, ...)
    if layer == P.WINDOW and (idx or 0) == 0 and type(VRFW_MenuEvent) == "table" then
      VRFW_MenuEvent.On(P.EVENT, P.SUB_WINDOW, P.OWNER, OnPage)
    elseif layer == P.LAYER then
      pcall(funcLuaMenuCommand, VRFW_Cmd.SET_LAYER_VISIBLE, layer, idx, false)   -- the whole status base, until placed
    end
    return open_layer(layer, idx, ...)
  end

  local post_step = PostStep
  PostStep = function(...)
    local r = table.pack(post_step(...))
    if P.want ~= nil then
      local ok, e = pcall(TryShow)
      if not ok then
        P.want = nil
        Log("error", tostring(e))
      end
    end
    return table.unpack(r, 1, r.n)
  end
end
