-- VRFW route_board BEGIN
-- VR-Framework: the Chronicle route board's hook points (the board
-- grafts move to the framework). The framework owns the one patch of vs_route_town_menu (route_nodes, route_chains,
-- this graft: one merged file, so the board's main-chunk locals exist once) and makes the script a VRFW_Host host
-- (the host call at the end of this graft's file). A mod changes the board's rules with VRFW_Host handlers on the
-- hook points below (its own hook file, [[hooks]] stem = "vs_route_town_menu"), never with a second text patch of the
-- script. Without handlers every point keeps the retail behaviour (plus the framework's nodes, chains and badges).
-- Hook points (global functions; `c` = the clear context of a won match, state 10 of PreStep):
--   VRFW_RB_IsCommand(item) -> bool              a command-menu result (parameter 2612514222) that is a mod's item
--   VRFW_RB_Command(item, piece) -> bool         run it (OpenCommandSelect); false = refused (error sound, back to the
--                                                command menu)
--   VRFW_RB_PieceOpen(piece) -> bool             a piece was picked (OpenCommandSelect, before its menu opens): true
--                                                = the piece ran its own flow instead of the command menu (the board
--                                                goes back as after «back»); default: a mod's node menu
--                                                (VRFW_NodeMenu.OpenPiece, a [[VRFW.NodeMenu]] node), else false
--   VRFW_RB_MenuClosed(piece)                    the piece's command menu just closed, before its result is read: a
--                                                mod's row that wrote no retail result runs here (the board then goes
--                                                back as after «back»); default: the framework's gacha node
--                                                (VRFW_Gacha.AfterMenu: its «insert a coin» row runs the draw)
--   VRFW_RB_BackOnBoard()                        back on the board after a match (state 8), before the retail result
--   VRFW_RB_Clear(c)                             the clear handling starts: c = {diff, piece, slot, kind, ok, wait,
--                                                force}; set c.wait (the retail clear is skipped: a mod's event runs
--                                                first, the board waits, state 4) or c.force (cleared again even when
--                                                that difficulty was cleared before)
--   VRFW_RB_Cleared(c)                           the clear bit was set (before the clear effect)
--   VRFW_RB_UnlockNext(c) -> bool                true = the mod unlocked what this clear opens (the retail "next
--                                                difficulty» unlock is skipped)
--   VRFW_RB_OpenEffect(open) -> bool             the route-open effect after the clear (retail: the difficulty-2 clear)
--   VRFW_RB_DotShown(kind, difficulty) -> bool   a cleared difficulty's dot on the piece (kind 0 normal, 5 gate)
--   VRFW_RB_Rank(slot) -> rank Id | nil           the rank badge of a piece's save slot (a VRFW_MatchRank Id);
--                                                default: a chain node's chain rank (route_chains), nil on a plain piece
--   VRFW_RB_MatchRank() -> rank Id, for, against the rank of the chain tile just won; default:
--                                                the declared ranks VRFW_MatchRank (defaults\match_rank.toml)
-- The board's locals a handler may read / write: VRFW_RB.L.<name> (decompile names of the retail chunk, served by
-- this patch: the locals it promoted). A mod that needs another one asks for it here (one line in VRFW_RB_LOCALS).
-- Retail globals of the script (OnInit, PreStep, ...) are hook points too (VRFW_Host.on(stem, "OnInit", ...)).
VRFW_RB = VRFW_RB or {}
VRFW_RB.STEM = "vs_route_town_menu"
VRFW_RB_LOCALS = {
  n9 = {function() return n9 end, function(v) n9 = v end},       -- the board's menu object (vs_route_town_menu ...)
  n21 = {function() return n21 end, function(v) n21 = v end},    -- PreStep state (4 = an event plays, 6 = clear effect)
  flag5 = {function() return flag5 end, function(v) flag5 = v end},     -- closing for a reserved map jump
  flag16 = {function() return flag16 end, function(v) flag16 = v end}   -- FinalizeMenu sets temp bit 1255964678
}
VRFW_RB.L = setmetatable({}, {
  __index = function(_, k)
    local a = VRFW_RB_LOCALS[k]
    if a == nil then
      error("VRFW_RB.L: the board serves no local " .. tostring(k), 2)
    end
    return a[1]()
  end,
  __newindex = function(_, k, v)
    local a = VRFW_RB_LOCALS[k]
    if a == nil then
      error("VRFW_RB.L: the board serves no local " .. tostring(k), 2)
    end
    a[2](v)
  end
})

function VRFW_RB_IsCommand(item)
  return false
end

function VRFW_RB_Command(item, piece)
  return false
end

function VRFW_RB_PieceOpen(piece)
  if VRFW_NodeMenu ~= nil and VRFW_NodeMenu.OpenPiece ~= nil then
    return VRFW_NodeMenu.OpenPiece(piece) == true
  end
  return false
end

function VRFW_RB_MenuClosed(piece)
  if VRFW_Gacha ~= nil and VRFW_Gacha.AfterMenu ~= nil then
    VRFW_Gacha.AfterMenu(piece)
  end
end

function VRFW_RB_BackOnBoard()
end

function VRFW_RB_Clear(c)
end

function VRFW_RB_Cleared(c)
end

function VRFW_RB_UnlockNext(c)
  return false
end

function VRFW_RB_OpenEffect(open)
  return open
end

function VRFW_RB_DotShown(kind, difficulty)
  return true
end

function VRFW_RB_Rank(slot)
  if VRFW_RCH_RankOf ~= nil then
    return VRFW_RCH_RankOf(slot)
  end
  return nil
end

-- the rank of the match just won: the framework's rule (VRFW_MatchRank, menu part); B when it is missing
function VRFW_RB_MatchRank()
  if VRFW_MatchRank ~= nil then
    return VRFW_MatchRank.Last()
  end
  return "B", -1, -1
end

-- The rank badge of a chain piece (end of UpdatePieceClearIcon(layer, instance, piece)): the clear-icon layer of the piece
-- (vsroute01_06c, attached at the piece's origin) has a 6th difficulty dot (_pos_clear08_01, Legendaria;
-- _pos_clear08_02 on gate pieces). With a rank it becomes the badge: moved over the crest's lower-right corner, its
-- picture = the rank's PieceBadge (defaults\match_rank.toml: a sprite a mod adds to the dots' atlas vsroute01_06b,
-- e.g. a mod's chronicle_deluxe_rank_{s,a,b}; the framework declares no rank and ships no badge).
-- Without a rank, or a rank without a PieceBadge, nothing changes.
VRFW_RB_BADGE_POS = {x = 40, y = -6} -- badge centre, piece coordinates (crest: 128 px centred at (0, 38))
VRFW_RB_BADGE_TEX = 2855820778 --[[crc32("#/menu/30_vsroute/vsroute01/vsroute01_06b/vsroute01_06b.g4tx")]]
VRFW_RB_BADGE_TEXREF = 516486421 --[[clear_icon08: the picture of both Legendaria dots]]
-- per eventType of the piece: the dot used as badge and the effect / ring meshes kept hidden on it
VRFW_RB_BADGE_DOT = {
  [0] = {pos = 2027773323 --[[_pos_clear08_01]], hide = {760159382 --[[_clear_icon08_01_add01]], 3024506156 --[[_clear_icon08_01_add02]], 3008808285 --[[_clear_ring08_01]]}},
  [5] = {pos = 3788770353 --[[_pos_clear08_02]], hide = {480708107 --[[_clear_icon08_02_add01]], 2242795441 --[[_clear_icon08_02_add02]], 710907111 --[[_clear_ring08_02]]}}
}

function VRFW_RB_Badge(a1, a2, a3)
  if a3 == nil or a3 == -1 then
    return
  end
  local okE, evType = GetTownMapResourceEvent(a3, 1, true)
  local dot = okE and VRFW_RB_BADGE_DOT[evType] or nil
  if dot == nil then
    return
  end
  local ok, sfi = funcLuaCommand(126049514, a3, 6)
  if not ok then
    return
  end
  -- the rank's PieceBadge (defaults\match_rank.toml): a sprite of the dots' atlas vsroute01_06b
  local rank = VRFW_RB_Rank(sfi)
  local def = VRFW_MatchRank ~= nil and VRFW_MatchRank.ById(rank) or nil
  local sprite = nil
  if def ~= nil and def.piece ~= "" then
    sprite = CRC32(def.piece)
  end
  if sprite == nil then
    return -- no rank (or a rank without a piece badge): the retail loop already set the dot
  end
  funcLuaMenuCommand(558735651, a1, VRFW_RB_BADGE_TEX, sprite, VRFW_RB_BADGE_TEXREF, 0, a2)
  funcLuaMenuCommand(1856671416 --[[node translation]], a1, a2, dot.pos, VRFW_RB_BADGE_POS.x, VRFW_RB_BADGE_POS.y, 0)
  funcLuaMenuCommand(2158717427, a1, dot.pos, true, a2)
  for i = 1, #dot.hide do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, a1, dot.hide[i], false, a2)
  end
  funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, a1, a2)
end

-- The retail invite check at the end of PreStep (CheckAndReserveGeneralWindowForInviteNotJoined, include
-- network_invite_menu_inc) waits with coroutine.yield while a general window is busy (CMND 682363669 false). PreStep is
-- not a coroutine here, so every frame a message window was up logged "LUAERR … attempt to yield from outside a
-- coroutine» (e.g. hundreds of lines in 30 s while the board's lock message showed). Called when it can wait (inside a
-- coroutine) or will not wait (no window busy); otherwise it runs again next frame, as the retail wait would.
function VRFW_RB_InviteCheck()
  local _, main = coroutine.running()
  if main == false or funcLuaCommand(682363669) then
    return CheckAndReserveGeneralWindowForInviteNotJoined()
  end
  return false
end
-- VRFW route_board END
