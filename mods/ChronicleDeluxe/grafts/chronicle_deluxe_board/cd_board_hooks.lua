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
  local route_won = funcLuaCommand(B.CMD.GET_CLEAR, c.slot, B.ROUTE_OPEN) == true
  local fast = c.diff == B.CHRONICLE and c.kind == B.NORMAL and not route_won
  c.force = fast
  -- Diagnostics: the state each board return decides the route opening from (docs/audit/chronicle-route-graph.md).
  B.log("clear: piece", c.piece, "slot", c.slot, "difficulty", c.diff, "kind", c.kind,
    "chronicle won", tostring(funcLuaCommand(B.CMD.GET_CLEAR, c.slot, B.CHRONICLE) == true),
    "route unlock won", tostring(route_won), "trigger piece", B.trigger_piece)
  if fast and B.trigger_piece ~= c.piece then
    B.trigger_piece = c.piece
    B.log("route unlock by Chronicle win: piece", c.piece, "slot", c.slot)
    RunVsRouteTrigger(506, B.WIN)
    if funcLuaCommand(B.CMD.TRIGGER_RUNNING) then
      B.log("trigger 506 running: the board waits, piece", c.piece)
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
B.STATE_IDLE = 0                  -- PreStep state: the board takes input

-- Runs in OpenCommandSelect, after the command menu closed: confirms, then runs the retail win flow to its end.
function B.autocomplete()
  if VRFW.param.take(B.AUTOCOMPLETE_REQUEST) == nil then
    return
  end
  if VRFW.route_board.L.n21 ~= B.STATE_IDLE then
    B.log("autocomplete refused: the board is in state", VRFW.route_board.L.n21, "(a win flow is still running)")
    return
  end
  if not VRFW.question.ask(B.AUTOCOMPLETE_CONFIRM) then
    return
  end
  B.log("autocomplete: Chronicle battle of the current piece counted as won")
  funcLuaCommand(B.CMD.SET_PLAYED_DIFFICULTY, B.CHRONICLE)
  funcLuaCommand(B.CMD.SET_TEMP_BIT, B.TEMP_RETURNED_FROM_MATCH, true)
  funcLuaCommand(B.CMD.SET_TEMP_BIT, B.TEMP_MATCH_WON, true)
  VRFW.route_board.L.n21 = B.STATE_BACK_FROM_MATCH
  -- OpenCommandSelect disabled the map control before the command menu: it stays so until the win flow ends, then the retail "back" branch enables it
  waitTrue(function()
    return VRFW.route_board.L.n21 == B.STATE_IDLE
  end)
  B.log("autocomplete: win flow ended, map control back")
end

-- Sets what a normal piece's Chronicle win writes on the piece: its route-open clear and its two battle rows.
function B.mark_route_open(slot)
  funcLuaCommand(B.CMD.SET_CLEAR, slot, true, B.ROUTE_OPEN)
  funcLuaCommand(B.CMD.SET_LOCK, slot, false, B.ROUTE_OPEN)
  funcLuaCommand(B.CMD.SET_LOCK, slot, false, B.HEROIC)
end

-- Whether a piece's battle that opens the route is won: its route-open clear, or the Chronicle of a normal piece.
function B.won(piece)
  local ok, slot = funcLuaCommand(B.CMD.PIECE_SLOT, piece, 6)
  local okE, kind = GetTownMapResourceEvent(piece, 1, false, false)
  if not ok or not okE or not IsSoccerBattle(kind) then
    return false
  end
  if funcLuaCommand(B.CMD.GET_CLEAR, slot, B.ROUTE_OPEN) then
    return true, slot, kind
  end
  return kind == B.NORMAL and funcLuaCommand(B.CMD.GET_CLEAR, slot, B.CHRONICLE) == true, slot, kind
end

B.UNLOCK_CONFIRM = 1117551755     -- crc32("chronicle_deluxe_unlock_piece_confirm")
B.BACKGROUND = 1021315501         -- vsroute00_00_background: the board layer whose Accept picks a piece
B.UNLOCK_STEPS = 4                -- route steps without a battle walked back from the locked piece

-- Returns the pieces to open, won piece first, so that a locked piece opens: its link from a won piece, through steps without a battle.
function B.unlock_path(piece, depth, seen)
  seen[piece] = true
  local openers = VRFW.route_board.openers(piece)
  for i = 1, #openers do
    local from = openers[i]
    if not seen[from] then
      if B.won(from) then
        return {from}
      end
      local okE, kind = GetTownMapResourceEvent(from, 1, false, false)
      if okE and not IsSoccerBattle(kind) and not IsPieceOpened(from) and depth < B.UNLOCK_STEPS then
        local path = B.unlock_path(from, depth + 1, seen)
        if path ~= nil then
          path[#path + 1] = from
          return path
        end
      end
    end
  end
  return nil
end

-- Accept on a locked battle piece next to a won one: asks, then opens it with the normal unlock's writes.
-- Returns nil when it is not offered (the retail Accept follows), false when declined, true when the piece is open now.
function B.offer_unlock(piece)
  local _, main = coroutine.running()
  if main ~= false or piece == nil or piece < 0 or VRFW.route_board.L.n21 ~= B.STATE_IDLE or IsPieceOpened(piece) then
    return nil
  end
  local ok, slot = funcLuaCommand(B.CMD.PIECE_SLOT, piece, 6)
  local okE, kind = GetTownMapResourceEvent(piece, 1, true)
  if not ok or not okE or not IsSoccerBattle(kind) or (VRFW.route_nodes ~= nil and VRFW.route_nodes.by_slot(slot) ~= nil) then
    return nil
  end
  local path = B.unlock_path(piece, 0, {})
  if path == nil then
    return nil
  end
  if not VRFW.question.ask(B.UNLOCK_CONFIRM) then
    return false
  end
  for i = 1, #path do
    local won, from_slot, from_kind = B.won(path[i])
    if won and from_kind == B.NORMAL then
      B.mark_route_open(from_slot)
    end
    local written, opened = VRFW.route_board.open_route(path[i])
    B.log("unlock by confirm: piece", piece, "slot", slot, "step", i, "from piece", path[i], "wrote", written)
    for k = 1, #opened do
      VRFW.route_board.redraw(opened[k])
    end
  end
  return IsPieceOpened(piece)
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
      B.mark_route_open(c.slot)
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
  -- Accept on a locked piece: the confirm instead of the retail "locked" message when a won piece links to it
  VRFW.host.on(stem, "OnEnter", {id = id .. "_unlock_offer", phase = "around", fn = function(nxt, layer, instance)
    if layer == B.BACKGROUND and not B.if_owns_flow() and B.offer_unlock(VRFW.route_board.L.n11) == false then
      return 1
    end
    return nxt(layer, instance)
  end})
  VRFW.host.on(stem, "VRFW.route_board.open_effect", {id = id, phase = "around", fn = function(nxt, open)
    local fast = B.fast_clear == true
    B.fast_clear = false
    B.log("open effect: retail", tostring(open), "fast clear", tostring(fast))
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
