BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.top_bar = type(BetterQoL.top_bar) == "table" and BetterQoL.top_bar or {}
BetterQoL.top_bar.board = {skip = false, co = nil}
BetterQoL.top_bar.board.STEP = "chronicle_board"      -- the step name entries declare in `action.path`
BetterQoL.top_bar.board.MENU = 3902542018             -- chronicle_mode_top_menu
BetterQoL.top_bar.board.BG = 117665605

function BetterQoL.top_bar.board.log(...)
  BetterQoL.top_bar.board.logger = BetterQoL.top_bar.board.logger or VRFW.logger.new("BetterQoL chronicle_board")
  BetterQoL.top_bar.board.logger(...)
end

function BetterQoL.top_bar.board.wanted()
  if type(VRFW.top_bar.step) ~= "function" or not VRFW.top_bar.step(BetterQoL.top_bar.board.STEP) then
    return false
  end
  local mode = funcLuaCommand(@crc:CMND_GET_GLOBAL_BYTE_FLAG@, 3152001072)
  if mode == 0 or mode == 2 then
    BetterQoL.top_bar.board.log("menu shown: chronicle mode byte", tostring(mode))
    return false
  end
  if not funcLuaCommand(@crc:CMND_GET_GLOBAL_BIT_FLAG@, 1169930310) then
    BetterQoL.top_bar.board.log("menu shown: the Chronicle tutorial is not confirmed yet")
    return false
  end
  if funcLuaCommand(@crc:CMND_GET_TEMP_BIT_FLAG@, 774062760)
      or funcLuaCommand(@crc:CMND_GET_TEMP_BIT_FLAG@, 3914011134) then
    BetterQoL.top_bar.board.log("menu shown: a Players Universe event is reserved")
    return false
  end
  return true
end

-- the end of the retail UpdateVsRouteTownSceneChange (the board of the route the menu holds), screen kept black
function BetterQoL.top_bar.board.board()
  funcLuaMenuCommand(1558704558, BetterQoL.top_bar.board.MENU, false)
  funcLuaCommand(609722083, 1, 0)
  coroutine.yield()
  funcLuaCommand(2565779025, 207055258, 0)
  funcLuaCommand(@crc:CMND_SET_TEMP_BYTE_FLAG@, 2502072435, 0)
  funcLuaCommand(769636339, 1.5)
  funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BetterQoL.top_bar.board.MENU)
  if not funcLuaCommand(@crc:CMND_GET_TEMP_BIT_FLAG@, 3914011134) then
    funcLuaMenuCommand(890340801)
  end
  local route = funcLuaMenuCommand(1951539112)
  BetterQoL.top_bar.board.log("board: route", tostring(route))
  funcLuaCommand(@crc:CMND_RESERVE_VSROUTE@, route, 0, 0, 1, 2976993266)
end

do
  local init = OnInit
  function OnInit(...)
    BetterQoL.top_bar.board.skip, BetterQoL.top_bar.board.co = false, nil
    local ok, want = pcall(BetterQoL.top_bar.board.wanted)
    if ok and want then
      BetterQoL.top_bar.board.skip = true
      funcLuaCommand(609722083, 1, 0) -- stays black: the menu is never seen
      BetterQoL.top_bar.board.log("top bar step chronicle_board: straight to the board")
    end
    return init(...)
  end
  local open = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    if BetterQoL.top_bar.board.skip and a1 == BetterQoL.top_bar.board.BG then
      BetterQoL.top_bar.board.skip = false
      BetterQoL.top_bar.board.co = coroutine.create(BetterQoL.top_bar.board.board)
      return
    end
    return open(a1, a2, ...)
  end
  local step = Step
  function Step(...)
    local r = table.pack(step(...))
    if BetterQoL.top_bar.board.co ~= nil then
      local ok, err = coroutine.resume(BetterQoL.top_bar.board.co)
      if not ok then
        BetterQoL.top_bar.board.log("error", tostring(err))
        funcLuaCommand(609722083, 0, 0.3)
        funcLuaMenuCommand(1558704558, BetterQoL.top_bar.board.MENU, true)
      end
      if not ok or coroutine.status(BetterQoL.top_bar.board.co) == "dead" then
        BetterQoL.top_bar.board.co = nil
      end
    end
    return table.unpack(r, 1, r.n)
  end
end
