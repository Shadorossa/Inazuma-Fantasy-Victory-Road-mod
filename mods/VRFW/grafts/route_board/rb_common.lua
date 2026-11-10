-- VRFW route_board BEGIN VRFW
VRFW.route_board = VRFW.route_board or {}
VRFW.route_board.STEM = "vs_route_town_menu"
VRFW.route_board.LOCALS = {
  n9 = {function() return n9 end, function(v) n9 = v end},       -- the board's menu object (vs_route_town_menu ...)
  n21 = {function() return n21 end, function(v) n21 = v end},    -- PreStep state (4 = an event plays, 6 = clear effect)
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

function VRFW.route_board.invite_check()
  local _, main = coroutine.running()
  if main == false or funcLuaCommand(682363669) then
    return CheckAndReserveGeneralWindowForInviteNotJoined()
  end
  return false
end
-- VRFW route_board END
