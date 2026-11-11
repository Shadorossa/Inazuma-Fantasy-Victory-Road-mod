-- VRFW route_board BEGIN VRFW
VRFW.route_board = VRFW.route_board or {}
VRFW.route_board.STEM = "vs_route_town_menu"
VRFW.route_board.LOCALS = {
  n9 = {function() return n9 end, function(v) n9 = v end},       -- the board's menu object (vs_route_town_menu ...)
  n21 = {function() return n21 end, function(v) n21 = v end},    -- PreStep state (4 = an event plays, 6 = clear effect)
  n11 = {function() return n11 end, function(v) n11 = v end},    -- the focused piece's index (-1 none)
  flag5 = {function() return flag5 end, function(v) flag5 = v end},     -- closing for a reserved map jump
  flag16 = {function() return flag16 end, function(v) flag16 = v end}   -- FinalizeMenu sets temp bit 1255964678
}
VRFW.route_board.L = setmetatable({}, {
  __index = function(_, k)
    local a = VRFW.route_board.LOCALS[k]
    if a == nil then
      error("VRFW.route_board.L: the board serves no local " .. tostring(k), 2)
    end
    return a[1]()
  end,
  __newindex = function(_, k, v)
    local a = VRFW.route_board.LOCALS[k]
    if a == nil then
      error("VRFW.route_board.L: the board serves no local " .. tostring(k), 2)
    end
    a[2](v)
  end
})

function VRFW.route_board.is_command(item)
  return false
end

function VRFW.route_board.command(item, piece)
  return false
end

function VRFW.route_board.piece_open(piece)
  if VRFW.node_menu ~= nil and VRFW.node_menu.open_piece ~= nil then
    return VRFW.node_menu.open_piece(piece) == true
  end
  return false
end

function VRFW.route_board.menu_closed(piece)
  if VRFW.node_menu ~= nil and VRFW.node_menu.after_menu ~= nil then
    VRFW.node_menu.after_menu(piece)
  end
end

function VRFW.route_board.back_on_board()
end

function VRFW.route_board.clear(c)
end

function VRFW.route_board.cleared(c)
end

function VRFW.route_board.unlock_next(c)
  return false
end

function VRFW.route_board.open_effect(open)
  return open
end

function VRFW.route_board.dot_shown(kind, difficulty)
  return true
end

function VRFW.route_board.rank(slot)
  if (VRFW.route_chains ~= nil and VRFW.route_chains.rank_of ~= nil) then
    return VRFW.route_chains.rank_of(slot)
  end
  return nil
end

-- Returns the rank of the match just won.
function VRFW.route_board.match_rank()
  if VRFW.match_rank ~= nil then
    return VRFW.match_rank.last()
  end
  return "B", -1, -1
end

-- The rank badge of a chain piece (end of UpdatePieceClearIcon(layer, instance, piece))
VRFW.route_board.BADGE_POS = {x = 40, y = -6} -- badge centre, piece coordinates (crest: 128 px centred at (0, 38))
VRFW.route_board.BADGE_TEX = 2855820778 --[[crc32("#/menu/30_vsroute/vsroute01/vsroute01_06b/vsroute01_06b.g4tx")]]
VRFW.route_board.BADGE_TEXREF = 516486421 --[[clear_icon08: the picture of both Legendaria dots]]
-- Badge dots per eventType of the piece.
VRFW.route_board.BADGE_DOT = {
  [0] = {pos = 2027773323 --[[_pos_clear08_01]], hide = {760159382 --[[_clear_icon08_01_add01]], 3024506156 --[[_clear_icon08_01_add02]], 3008808285 --[[_clear_ring08_01]]}},
  [5] = {pos = 3788770353 --[[_pos_clear08_02]], hide = {480708107 --[[_clear_icon08_02_add01]], 2242795441 --[[_clear_icon08_02_add02]], 710907111 --[[_clear_ring08_02]]}}
}

function VRFW.route_board.badge(a1, a2, a3)
  if a3 == nil or a3 == -1 then
    return
  end
  local okE, evType = GetTownMapResourceEvent(a3, 1, true)
  local dot = okE and VRFW.route_board.BADGE_DOT[evType] or nil
  if dot == nil then
    return
  end
  local ok, sfi = funcLuaCommand(126049514, a3, 6)
  if not ok then
    return
  end
  -- Returns the rank's PieceBadge (defaults\match_rank.toml).
  local rank = VRFW.route_board.rank(sfi)
  local def = VRFW.match_rank ~= nil and VRFW.match_rank.by_id(rank) or nil
  local sprite = nil
  if def ~= nil and def.piece ~= "" then
    sprite = CRC32(def.piece)
  end
  if sprite == nil then
    return
  end
  funcLuaMenuCommand(558735651, a1, VRFW.route_board.BADGE_TEX, sprite, VRFW.route_board.BADGE_TEXREF, 0, a2)
  funcLuaMenuCommand(1856671416 --[[node translation]], a1, a2, dot.pos, VRFW.route_board.BADGE_POS.x, VRFW.route_board.BADGE_POS.y, 0)
  funcLuaMenuCommand(2158717427, a1, dot.pos, true, a2)
  for i = 1, #dot.hide do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, a1, dot.hide[i], false, a2)
  end
  funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, a1, a2)
end

-- ---- route-open state -----------------------
-- The save writes of the retail route-open effect (UpdateClearEffect: OnAroundPieceUnlock, OnGateOpen), without the effect:
-- the effect writes them one by one while it plays, so a clear whose effect never ran to its end is opened from its clear bit.
VRFW.route_board.CMD_PIECE_INFO = 126049514     -- (piece index, field) -> ok, ...: 6 statusFlagIndex, 7 unlock links
VRFW.route_board.CMD_PIECE_IDX = 1064555639     -- pieceId -> ok, piece index
VRFW.route_board.CMD_PIECE_INSTANCE = 1350631190 -- piece index -> the piece's layer instance, -1 when not placed
VRFW.route_board.CMD_GET_CLEAR = 4034518619     -- CMND_GET_CHRONICLE_CLEAR_STATUS (slot, difficulty)
VRFW.route_board.CMD_GET_LOCK = 3394595467      -- CMND_GET_CHRONICLE_LOCK_STATUS (slot, difficulty)
VRFW.route_board.CMD_GET_GLOBAL_BIT = 941426960
VRFW.route_board.CMD_SET_GLOBAL_BIT = 3258400760
VRFW.route_board.PIECE_LAYER = 4002479583 --[[vsroute00_05_town_map_piece]]
VRFW.route_board.BALLOON_LAYER = 1632548965 --[[vsroute00_07_town_map_piece_atc_chara]]
VRFW.route_board.CLEAR_ICON_LAYER = 2638032167 --[[vsroute01_06c_town_map_piece_clear_icon]]
VRFW.route_board.ROUTE_OPEN = 2     -- the difficulty whose clear opens the route
VRFW.route_board.MAX_PIECES = 4096
VRFW.route_board.OPENERS = nil      -- piece -> the pieces whose unlock links reach it

function VRFW.route_board.log(...)
  VRFW.route_board.logger = VRFW.route_board.logger or VRFW.logger.new("VRFW route_board")
  VRFW.route_board.logger(...)
end

-- Returns the locked pieces a piece's unlock links reach, without the route nodes whose own prerequisites are not won.
function VRFW.route_board.locked_links(piece)
  local idxs = SearchLockedPieceIdxsAround(piece, true)
  local kept = {}
  for i = 1, #idxs do
    local idx = idxs[i]
    if idx ~= 0 then
      local ok, slot = funcLuaCommand(VRFW.route_board.CMD_PIECE_INFO, idx, 6)
      local node = ok and VRFW.route_nodes ~= nil and VRFW.route_nodes.by_slot(slot) or nil
      if node == nil or VRFW.route_nodes.ready(node) then
        kept[#kept + 1] = idx
      end
    end
  end
  return kept
end

-- Sets the gate keys a piece's route-open clear gives and opens the gate once every key is set (retail OnGateOpen).
function VRFW.route_board.open_gate(piece)
  local has, gate_id = GetObtainGateKeyInfo(piece)
  if not has then
    return 0
  end
  local ok, gate = funcLuaCommand(VRFW.route_board.CMD_PIECE_IDX, gate_id)
  local okS, gate_slot = false, nil
  if ok then
    okS, gate_slot = funcLuaCommand(VRFW.route_board.CMD_PIECE_INFO, gate, 6)
  end
  if not okS then
    return 0
  end
  local written, every_key = 0, true
  for key = 0, 1 do
    local bit, met = GetGateOpenInfo(gate, key)
    if type(bit) == "number" and bit ~= 0 then
      local set = funcLuaCommand(VRFW.route_board.CMD_GET_GLOBAL_BIT, bit) == true
      if not set and met == true then
        funcLuaCommand(VRFW.route_board.CMD_SET_GLOBAL_BIT, bit, true)
        set = true
        written = written + 1
      end
      every_key = every_key and set
    end
  end
  if every_key then
    if funcLuaCommand(VRFW.route_board.CMD_GET_LOCK, gate_slot, 1) or funcLuaCommand(VRFW.route_board.CMD_GET_LOCK, gate_slot, 2) then
      UnlockPiece(gate)
      written = written + 1
    end
    local idxs = VRFW.route_board.locked_links(gate)
    for i = 1, #idxs do
      UnlockPiece(idxs[i])
    end
    written = written + #idxs
  end
  return written
end

-- Unlocks what a piece's route-open clear opens, in one call: its links, its gate key; returns the writes and the opened links.
function VRFW.route_board.open_route(piece)
  local idxs = VRFW.route_board.locked_links(piece)
  for i = 1, #idxs do
    UnlockPiece(idxs[i])
  end
  return #idxs + VRFW.route_board.open_gate(piece), idxs
end

-- Opens what every won route-open clear opens and an interrupted effect left closed (derived from the clear bits, at OnInit).
function VRFW.route_board.repair_routes()
  local repaired = 0
  for piece = 0, VRFW.route_board.MAX_PIECES - 1 do
    local ok, slot = funcLuaCommand(VRFW.route_board.CMD_PIECE_INFO, piece, 6)
    if not ok then
      break
    end
    if funcLuaCommand(VRFW.route_board.CMD_GET_CLEAR, slot, VRFW.route_board.ROUTE_OPEN) == true then
      local written = VRFW.route_board.open_route(piece)
      if written > 0 then
        repaired = repaired + written
        VRFW.route_board.log("repair: piece", piece, "slot", slot, "has its route-open clear:", written, "link(s) / gate key(s) its effect never opened are open now")
      end
    end
  end
  return repaired
end

-- Returns the pieces whose unlock links reach a piece (the board's link table, read once per board).
function VRFW.route_board.openers(piece)
  if VRFW.route_board.OPENERS == nil then
    local map = {}
    for from = 0, VRFW.route_board.MAX_PIECES - 1 do
      if not funcLuaCommand(VRFW.route_board.CMD_PIECE_INFO, from, 6) then
        break
      end
      local ok, count, ids = funcLuaCommand(VRFW.route_board.CMD_PIECE_INFO, from, 7)
      for i = 1, ok and type(count) == "number" and count or 0 do
        local okI, to = false, nil
        if ids[i] ~= 0 then
          okI, to = funcLuaCommand(VRFW.route_board.CMD_PIECE_IDX, ids[i])
        end
        if okI then
          map[to] = map[to] or {}
          map[to][#map[to] + 1] = from
        end
      end
    end
    VRFW.route_board.OPENERS = map
  end
  return VRFW.route_board.OPENERS[piece] or {}
end

-- Redraws a placed piece after its lock state changed without the open effect (crest, balloon, clear dots).
function VRFW.route_board.redraw(piece)
  local instance = funcLuaMenuVSRouteTownCommand(VRFW.route_board.CMD_PIECE_INSTANCE, piece)
  if type(instance) ~= "number" or instance < 0 then
    return false
  end
  UpdateTownMapPiece(VRFW.route_board.PIECE_LAYER, instance, piece)
  UpdatePieceAtcBalloon(VRFW.route_board.BALLOON_LAYER, instance, piece)
  UpdatePieceClearIcon(VRFW.route_board.CLEAR_ICON_LAYER, instance, piece)
  return true
end

if VRFW.host ~= nil then
  VRFW.host.on(VRFW.route_board.STEM, "OnInit", {id = "VRFW.route_board.repair_routes", phase = "after", fn = function()
    VRFW.route_board.repair_routes()
  end})
end

function VRFW.route_board.invite_check()
  local _, main = coroutine.running()
  if main == false or funcLuaCommand(682363669) then
    return CheckAndReserveGeneralWindowForInviteNotJoined()
  end
  return false
end
-- VRFW route_board END
