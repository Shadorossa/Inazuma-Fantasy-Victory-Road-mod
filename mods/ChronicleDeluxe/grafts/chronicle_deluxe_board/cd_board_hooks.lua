@ORB_BAR@
ChronicleDeluxe = ChronicleDeluxe or {}
ChronicleDeluxe.board = ChronicleDeluxe.board or {}
local B = ChronicleDeluxe.board
B.CMD = {
  GET_CLEAR = 4034518619,     -- CMND_GET_CHRONICLE_CLEAR_STATUS (slot, difficulty)
  SET_CLEAR = 1891570685,     -- CMND_SET_CHRONICLE_CLEAR_STATUS (slot, on, difficulty)
  SET_LOCK = 1778321182,      -- CMND_SET_CHRONICLE_LOCK_STATUS (slot, locked, difficulty)
  PIECE_SLOT = 126049514,     -- (piece index, 6) -> ok, the piece's statusFlagIndex
  TRIGGER_RUNNING = 3500708916,
  MENU_ACTIVE = 1558704558,   -- the board menu object's active flag (the retail state-4 handover)
  SET_TEMP_BIT = 3964465990,  -- CMND_SET_TEMP_BIT_FLAG (bit, value)
  SET_PLAYED_DIFFICULTY = 1104380539, -- (difficulty): the byte GET 3146838638 reads back in PreStep
}
B.CHRONICLE, B.ROUTE_OPEN, B.HEROIC = 1, 2, 4
B.WIN = 4108050209            -- crc32("0"): the trigger result of a win
B.NORMAL = 0                  -- eventType of a normal match piece
B.GATE = 5                    -- eventType of a gate piece
B.trigger_piece = -1          -- the piece whose trigger 506 already ran in this return to the board
B.fast_clear = false

function B.log(...)
  B.logger = B.logger or VRFW.logger.new("ChronicleDeluxe board")
  B.logger(...)
end

-- Inazuma Fantasy's redesign owns the clear flow in this VM
function B.if_owns_flow()
  return EVT_ChrClear ~= nil
end

function B.open_won_heroics()
  local n = 0
  for i = 0, 1023 do
    local ok, slot = funcLuaCommand(B.CMD.PIECE_SLOT, i, 6)
    if not ok then
      break
    end
    local okE, kind = GetTownMapResourceEvent(i, 1, false, false)
    if okE and kind == B.NORMAL and funcLuaCommand(B.CMD.GET_CLEAR, slot, B.CHRONICLE) then
      funcLuaCommand(B.CMD.SET_LOCK, slot, false, B.HEROIC)
      n = n + 1
    end
  end
  return n
end

function B.clear(c)
  if not c.ok then
    return
  end
  local fast = c.diff == B.CHRONICLE and c.kind == B.NORMAL and not funcLuaCommand(B.CMD.GET_CLEAR, c.slot, B.ROUTE_OPEN)
  c.force = fast
  if fast and B.trigger_piece ~= c.piece then
    B.trigger_piece = c.piece
    B.log("route unlock by Chronicle win: piece", c.piece, "slot", c.slot)
    RunVsRouteTrigger(506, B.WIN)
    if funcLuaCommand(B.CMD.TRIGGER_RUNNING) then
      c.wait = true
      VRFW.route_board.L.n21 = 4
      funcLuaMenuCommand(B.CMD.MENU_ACTIVE, VRFW.route_board.L.n9, false)
    end
  end
end

-- Autocomplete: what the end of a won match leaves for the board, then the board's own return state.
B.AUTOCOMPLETE_REQUEST = 1168198373 -- crc32("chronicle_deluxe_autocomplete_request"): written by the command menu
B.AUTOCOMPLETE_CONFIRM = 4058342974 -- crc32("chronicle_deluxe_autocomplete_confirm")
B.TEMP_RETURNED_FROM_MATCH = 1388584433
B.TEMP_MATCH_WON = 2046383450
B.STATE_BACK_FROM_MATCH = 8       -- PreStep state: the retail handling of a match result

-- Runs in OpenCommandSelect, after the command menu closed: confirms, then starts the retail win flow.
function B.autocomplete()
  if VRFW.param.take(B.AUTOCOMPLETE_REQUEST) == nil or not VRFW.question.ask(B.AUTOCOMPLETE_CONFIRM) then
    return
  end
  B.log("autocomplete: Chronicle battle of the current piece counted as won")
  funcLuaCommand(B.CMD.SET_PLAYED_DIFFICULTY, B.CHRONICLE)
  funcLuaCommand(B.CMD.SET_TEMP_BIT, B.TEMP_RETURNED_FROM_MATCH, true)
  funcLuaCommand(B.CMD.SET_TEMP_BIT, B.TEMP_MATCH_WON, true)
  VRFW.route_board.L.n21 = B.STATE_BACK_FROM_MATCH
end

-- Returns the dots a piece shows.
function B.shown(kind)
  return VRFW.match_difficulty ~= nil and VRFW.match_difficulty.set(kind == B.GATE and "gate" or "route") or nil
end

if VRFW.host ~= nil then
  local stem = "vs_route_town_menu"
  local id = "ChronicleDeluxe.board"
  VRFW.host.on(stem, "VRFW.route_board.menu_closed", {id = id .. "_autocomplete", phase = "after", fn = function()
    B.autocomplete()
  end})
  VRFW.host.on(stem, "VRFW.route_board.back_on_board", {id = id, phase = "after", fn = function()
    if not B.if_owns_flow() then
      B.open_won_heroics()
    end
  end})
  VRFW.host.on(stem, "VRFW.route_board.clear", {id = id, phase = "after", fn = function(r, c)
    if not B.if_owns_flow() then
      B.clear(c)
    end
  end})
  VRFW.host.on(stem, "VRFW.route_board.cleared", {id = id, phase = "after", fn = function(r, c)
    if c.force and not B.if_owns_flow() then
      funcLuaCommand(B.CMD.SET_CLEAR, c.slot, true, B.ROUTE_OPEN)
      B.fast_clear = true
      B.trigger_piece = -1
    end
  end})
  VRFW.host.on(stem, "VRFW.route_board.unlock_next", {id = id, phase = "around", fn = function(nxt, c)
    if c.kind ~= B.NORMAL or B.if_owns_flow() then
      return nxt(c)
    end
    if c.diff == B.CHRONICLE then
      funcLuaCommand(B.CMD.SET_LOCK, c.slot, false, B.ROUTE_OPEN)
      funcLuaCommand(B.CMD.SET_LOCK, c.slot, false, B.HEROIC)
    end
    return true
  end})
  VRFW.host.on(stem, "VRFW.route_board.open_effect", {id = id, phase = "around", fn = function(nxt, open)
    local fast = B.fast_clear == true
    B.fast_clear = false
    return nxt(open) == true or fast
  end})
  VRFW.host.on(stem, "VRFW.route_board.dot_shown", {id = id, phase = "around", fn = function(nxt, kind, difficulty)
    local shown = B.shown(kind)
    if shown ~= nil and not shown[difficulty] then
      return false
    end
    return nxt(kind, difficulty)
  end})
  -- the orb bar of a piece, after the retail dots of UpdatePieceClearIcon(layer, instance, piece)
  VRFW.host.on(stem, "VRFW.route_board.badge", {id = id .. "_orb_bar", phase = "before", fn = function(layer, instance, piece)
    if B.if_owns_flow() or piece == nil or piece == -1 then
      return
    end
    local ok, kind = GetTownMapResourceEvent(piece, 1, true)
    if ok then
      ChronicleDeluxe.orb_bar.fit(layer, instance, kind, GetGameDifficultyArray(kind), GetClearIconLocatorNameArray(kind))
    end
  end})
end
