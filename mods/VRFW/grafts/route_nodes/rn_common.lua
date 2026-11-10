-- VRFW route_nodes BEGIN VRFW [[route_node]]
VRFW.route_nodes = VRFW.route_nodes or {}
VRFW.route_nodes.map = nil
VRFW.route_nodes.DIFFS = {1, 2, 3, 4, 10, 11}
VRFW.route_nodes.CMD = {NODE_COUNT = @crc:CMND_VRFW_TEAM_ROUTE_NODE_COUNT@, NODE_GET = @crc:CMND_VRFW_TEAM_ROUTE_NODE_GET@, ROAD_COUNT = @crc:CMND_VRFW_TEAM_ROUTE_ROAD_COUNT@, ROAD_GET = @crc:CMND_VRFW_TEAM_ROUTE_ROAD_GET@}
VRFW.route_nodes.CMD_CLEAR = @crc:CMND_GET_CHRONICLE_CLEAR_STATUS@     -- (slot, difficulty)
VRFW.route_nodes.CMD_LOCK = @crc:CMND_GET_CHRONICLE_LOCK_STATUS@      -- (slot, difficulty)
VRFW.route_nodes.CMD_SET_LOCK = @crc:CMND_SET_CHRONICLE_LOCK_STATUS@  -- (slot, locked, difficulty)
VRFW.route_nodes.CMD_PIECE_IDX = 1064555639 -- pieceId -> ok, piece index

function VRFW.route_nodes.log(...)
  if PRINT ~= nil then
    pcall(PRINT, "VRFW.route_nodes.map", ...)
  end
end

function VRFW.route_nodes.csv(s)
  local t = {}
  for x in string.gmatch(s or "", "[^,]+") do
    t[#t + 1] = tonumber(x)
  end
  return t
end

function VRFW.route_nodes.load()
  if VRFW.route_nodes.map ~= nil then
    return VRFW.route_nodes.map
  end
  VRFW.route_nodes.map = {nodes = {}, bySlot = {}, byIdx = {}, roads = {}}
  if VRFW.route_slots ~= nil then
    VRFW.route_slots.install() -- extended slots: normally in already, from the script's OnInit
  end
  local n = VRFW.host.command(VRFW.route_nodes.CMD.NODE_COUNT)
  if type(n) ~= "number" then
    return VRFW.route_nodes.map
  end
  for i = 0, n - 1 do
    local piece, slot, parents, diffs, game, field, linked, beside, path, gates, hub, lockedGuide, scalePct = VRFW.host.command(VRFW.route_nodes.CMD.NODE_GET, i)
    if type(slot) == "number" and slot > 0 then
      local node = {i = i, piece = piece, slot = slot, parents = {}, diffs = VRFW.route_nodes.csv(diffs), game = game, field = field, linked = linked == true, idx = -1, beside = beside, bidx = -1, path = {}, gates = VRFW.route_nodes.csv(type(gates) == "string" and gates or ""),
                    hub = VRFW.route_nodes.csv(type(hub) == "string" and hub or ""), lockedGuide = type(lockedGuide) == "number" and lockedGuide or 0,
                    pieceScale = (type(scalePct) == "number" and scalePct > 0) and scalePct / 100 or 1}
      for part in string.gmatch(type(path) == "string" and path or "", "[^;]+") do
        local x, y = string.match(part, "^([^,]+),(.+)$")
        if tonumber(x) ~= nil and tonumber(y) ~= nil then
          node.path[#node.path + 1] = {tonumber(x), tonumber(y)}
        end
      end
      if type(beside) == "number" and beside ~= 0 then
        local okB, bidx = funcLuaCommand(VRFW.route_nodes.CMD_PIECE_IDX, beside)
        if okB and type(bidx) == "number" then
          node.bidx = bidx
        end
      end
      for part in string.gmatch(parents or "", "[^;]+") do
        local s, d = string.match(part, "^(%d+):(.*)$")
        if s ~= nil then
          node.parents[#node.parents + 1] = {slot = tonumber(s), diffs = VRFW.route_nodes.csv(d)}
        end
      end
      if #node.diffs == 0 then
        node.diffs = {1, 4}
      end
      local okI, idx = funcLuaCommand(VRFW.route_nodes.CMD_PIECE_IDX, piece)
      if okI and type(idx) == "number" then
        node.idx = idx
        VRFW.route_nodes.map.byIdx[idx] = node
      end
      VRFW.route_nodes.map.nodes[#VRFW.route_nodes.map.nodes + 1] = node
      VRFW.route_nodes.map.bySlot[slot] = node
    end
  end
  local nr = VRFW.host.command(VRFW.route_nodes.CMD.ROAD_COUNT)
  if type(nr) == "number" then
    for i = 0, nr - 1 do
      local node, sprite, x, y, w, h = VRFW.host.command(VRFW.route_nodes.CMD.ROAD_GET, i)
      if type(node) == "number" and node >= 0 and type(sprite) == "string" and sprite ~= "" and type(w) == "number" and w > 0 then
        VRFW.route_nodes.map.roads[#VRFW.route_nodes.map.roads + 1] = {node = node, sprite = sprite, x = x, y = y, w = w, h = h}
      end
    end
  end
  local linked, gated = 0, 0
  for i = 1, #VRFW.route_nodes.map.nodes do
    local nd = VRFW.route_nodes.map.nodes[i]
    if nd.linked then linked = linked + 1 end
    if #nd.gates > 0 then gated = gated + 1 end
  end
  VRFW.route_nodes.log("load", "nodes", #VRFW.route_nodes.map.nodes, "roads", #VRFW.route_nodes.map.roads, "linked", linked, "with gates", gated)
  VRFW.route_nodes.wrap_chara()
  return VRFW.route_nodes.map
end

-- `idx`, is drawn at its node's scale (base and crest)
VRFW.route_nodes.PIECE_LAYER = 4002479583 --[[vsroute00_05_town_map_piece]]
VRFW.route_nodes.PIECE_SCALES = {}
function VRFW.route_nodes.piece_scale(layer, inst, idx)
  if layer ~= VRFW.route_nodes.PIECE_LAYER or type(inst) ~= "number" then
    return
  end
  local s = 1
  if type(idx) == "number" and idx ~= -1 then
    local node = VRFW.route_nodes.load().byIdx[idx]
    if node ~= nil and node.pieceScale ~= nil then
      s = node.pieceScale
    end
  end
  if (VRFW.route_nodes.PIECE_SCALES[inst] or 1) == s then
    return
  end
  VRFW.route_nodes.PIECE_SCALES[inst] = s
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_LOCAL_SCALE@, layer, s, s, 1, inst)
  VRFW.route_nodes.log("piece scale", "inst", inst, "piece", idx, "scale", s)
end

function VRFW.route_nodes.clear(slot, d)
  return funcLuaCommand(VRFW.route_nodes.CMD_CLEAR, slot, d) == true
end

function VRFW.route_nodes.locked(slot, d)
  return funcLuaCommand(VRFW.route_nodes.CMD_LOCK, slot, d) == true
end

function VRFW.route_nodes.ready(node)
  for i = 1, #node.parents do
    local p, won = node.parents[i], false
    for k = 1, #p.diffs do
      if VRFW.route_nodes.clear(p.slot, p.diffs[k]) then
        won = true
        break
      end
    end
    if not won then
      return false
    end
  end
  return true
end

function VRFW.route_nodes.is_open(node)
  for i = 1, #VRFW.route_nodes.DIFFS do
    if not VRFW.route_nodes.locked(node.slot, VRFW.route_nodes.DIFFS[i]) then
      return true
    end
  end
  return false
end

-- Debug (the framework's config [debug] all_chains, docs/framework/debug-flags.md)
function VRFW.route_nodes.debug_chain(node)
  if node.debugChain == nil then
    node.debugChain = VRFW.chain ~= nil and VRFW.chain.debug_all ~= nil and VRFW.chain.debug_all() == true
      and VRFW.chain.of_piece(node.piece) ~= nil
  end
  return node.debugChain
end

-- Returns whether the node is drawn (piece and road).
function VRFW.route_nodes.shown(node)
  return VRFW.route_nodes.debug_chain(node) or (VRFW.route_nodes.is_open(node) and VRFW.route_nodes.ready(node))
end

function VRFW.route_nodes.hidden(idx)
  if idx == nil or idx < 0 then
    return false
  end
  local node = VRFW.route_nodes.load().byIdx[idx]
  if node ~= nil and VRFW.route_nodes.group_hidden(node) then
    return true
  end
  return node ~= nil and node.lockedGuide == 0 and not VRFW.route_nodes.shown(node)
end

-- Hideable board groups ([[VRFW.BoardGroup]], content\board_groups\*.toml, scripts\board_group.lua)
VRFW.route_nodes.GROUPS = nil
VRFW.route_nodes.CMD_GROUP_PIECES = @crc:CMND_VRFW_BOARD_GROUPS@
VRFW.route_nodes.CMD_HIDE = @crc:CMND_VRFW_BOARD_HIDE@
VRFW.route_nodes.CMD_HIDDEN = @crc:CMND_VRFW_BOARD_HIDDEN@

function VRFW.route_nodes.groups()
  if VRFW.route_nodes.GROUPS ~= nil then
    return VRFW.route_nodes.GROUPS
  end
  VRFW.route_nodes.GROUPS = {pieces = {}, always = {}, n = 0, hidden = 0, on = false}
  local okd, ruled = pcall(funcLuaCommand, VRFW.route_nodes.CMD_HIDDEN)
  if okd and type(ruled) == "table" then
    for _, p in ipairs(ruled) do
      if type(p) == "number" and not VRFW.route_nodes.GROUPS.always[p % 4294967296] then
        VRFW.route_nodes.GROUPS.always[p % 4294967296] = true
        VRFW.route_nodes.GROUPS.hidden = VRFW.route_nodes.GROUPS.hidden + 1
      end
    end
  end
  local ok, list = pcall(funcLuaCommand, VRFW.route_nodes.CMD_GROUP_PIECES)
  if ok and type(list) == "table" then
    for _, p in ipairs(list) do
      -- A node its group's conditions hide is not the switch's.
      if type(p) == "number" and not VRFW.route_nodes.GROUPS.always[p % 4294967296] then
        VRFW.route_nodes.GROUPS.pieces[p % 4294967296] = true
        VRFW.route_nodes.GROUPS.n = VRFW.route_nodes.GROUPS.n + 1
      end
    end
  end
  local okh, on = pcall(funcLuaCommand, VRFW.route_nodes.CMD_HIDE)
  VRFW.route_nodes.GROUPS.on = okh and on == true
  VRFW.route_nodes.log("groups: hideable pieces", VRFW.route_nodes.GROUPS.n, "hidden", tostring(VRFW.route_nodes.GROUPS.on),
    "always hidden", VRFW.route_nodes.GROUPS.hidden)
  return VRFW.route_nodes.GROUPS
end

function VRFW.route_nodes.group_hidden(node)
  local G = VRFW.route_nodes.groups()
  if node.piece == nil then
    return false
  end
  local piece = node.piece % 4294967296
  return G.always[piece] == true or (G.on and G.pieces[piece] == true)
end

function VRFW.route_nodes.hideable_count()
  return VRFW.route_nodes.groups().n
end

function VRFW.route_nodes.hide_on()
  return VRFW.route_nodes.groups().on
end

-- Sets the hide switch.
function VRFW.route_nodes.set_hide(on)
  local G = VRFW.route_nodes.groups()
  on = on == true
  if G.on == on then
    return
  end
  G.on = on
  pcall(funcLuaCommand, VRFW.route_nodes.CMD_HIDE, "set", on and 1 or 0)
  for _, node in ipairs(VRFW.route_nodes.load().nodes) do
    if node.idx >= 0 and G.pieces[node.piece % 4294967296] then
      local ok, inst = pcall(funcLuaMenuVSRouteTownCommand, VRFW.route_nodes.CMD_PIECE_INSTANCE, node.idx)
      if ok and type(inst) == "number" and inst >= 0 then
        UpdatePlacementPiece(inst, VRFW.route_nodes.hidden(node.idx) and -1 or node.idx)
      end
    end
  end
  VRFW.route_nodes.log("groups: hidden", tostring(on))
end

-- The board balloon's text id of piece `idx` (UpdatePieceAtcBalloon)
function VRFW.route_nodes.guide_text(idx, id)
  local node = idx ~= nil and idx >= 0 and VRFW.route_nodes.load().byIdx[idx] or nil
  if node ~= nil and node.lockedGuide ~= 0 and not VRFW.route_nodes.shown(node) then
    return node.lockedGuide
  end
  return id
end

-- Accept on a locked piece (retail OnEnter, the lock message `s`)
function VRFW.route_nodes.locked_text(slot, s)
  local node = VRFW.route_nodes.by_slot(slot)
  if node ~= nil and node.lockedGuide ~= 0 and not VRFW.route_nodes.shown(node) then
    local ok, t = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@, node.lockedGuide)
    if ok and type(t) == "string" and t ~= "" then
      return t
    end
  end
  return s
end

function VRFW.route_nodes.by_slot(slot)
  if slot == nil then
    return nil
  end
  return VRFW.route_nodes.load().bySlot[slot]
end

-- The board's Accept on a piece (retail OnEnter) refuses a piece whose difficulty 1 (Chronicle) is locked
function VRFW.route_nodes.enterable(slot)
  local node = VRFW.route_nodes.by_slot(slot)
  return node ~= nil and VRFW.route_nodes.shown(node)
end

function VRFW.route_nodes.won(node)
  if VRFW.route_nodes.clear(node.slot, 2) then
    return true
  end
  for k = 1, #node.diffs do
    if VRFW.route_nodes.clear(node.slot, node.diffs[k]) then
      return true
    end
  end
  return false
end

-- The pieces a node gates (`gates`)
function VRFW.route_nodes.sync_gates(node, effect)
  if #node.gates == 0 then
    return false
  end
  local won = VRFW.route_nodes.won(node)
  local opened = false
  for g = 1, #node.gates do
    local gs = node.gates[g]
    local played, open = false, false
    for k = 1, #VRFW.route_nodes.DIFFS do
      local d = VRFW.route_nodes.DIFFS[k]
      if VRFW.route_nodes.clear(gs, d) then
        played = true
      end
      if not VRFW.route_nodes.locked(gs, d) then
        open = true
      end
    end
    if not played then
      if not won and open then
        for k = 1, #VRFW.route_nodes.DIFFS do
          funcLuaCommand(VRFW.route_nodes.CMD_SET_LOCK, gs, true, VRFW.route_nodes.DIFFS[k])
        end
        VRFW.route_nodes.log("gate", "slot", gs, "locked until node", node.slot, "is won")
      elseif won and not open then
        funcLuaCommand(VRFW.route_nodes.CMD_SET_LOCK, gs, false, 1)
        opened = true
        VRFW.route_nodes.log("gate", "slot", gs, "opened by node", node.slot, "effect", tostring(effect))
      end
    end
  end
  return opened
end

-- The retail one-time lock set-up of a save (OnInit, CMND 0x5D347D73) locks every piece and unlocks
VRFW.route_nodes.START_EVENT = 6            -- eventType of the start piece
VRFW.route_nodes.FIRST_DIFFICULTY = 1       -- the difficulty the retail set-up unlocks
VRFW.route_nodes.CMD_PIECE_INFO = 126049514
VRFW.route_nodes.CMD_PIECE_INSTANCE = 1350631190
VRFW.route_nodes.CMD_TRIGGER_RUNNING = 3500708916
VRFW.route_nodes.CLEAR_ICON_LAYER = 2638032167 --[[vsroute01_06c_town_map_piece_clear_icon]]
VRFW.route_nodes.START_CHECK_FRAMES = 30    -- frames between two checks while the board runs
VRFW.route_nodes.START = nil
VRFW.route_nodes.START_REDRAW = {}          -- piece index -> true: opened here, its board piece not redrawn yet
VRFW.route_nodes.START_FRAME = VRFW.route_nodes.START_CHECK_FRAMES - 1 -- the first board frame checks at once

-- The start neighbours that follow the rule
function VRFW.route_nodes.start_neighbours()
  if VRFW.route_nodes.START ~= nil then
    return VRFW.route_nodes.START
  end
  local rn = VRFW.route_nodes.load()
  local list, seen = {}, {}
  for i = 0, 4095 do
    if not funcLuaCommand(VRFW.route_nodes.CMD_PIECE_INFO, i, 6) then
      break
    end
    local okS, kindS = GetTownMapResourceEvent(i, 1, false, false)
    if okS and kindS == VRFW.route_nodes.START_EVENT then
      local move = table.pack(funcLuaCommand(VRFW.route_nodes.CMD_PIECE_INFO, i, 3))
      for k = 3, move[1] == true and move.n or 0 do
        local id = move[k]
        if type(id) == "number" and id ~= 0 then
          local okI, j = funcLuaCommand(VRFW.route_nodes.CMD_PIECE_IDX, id)
          if okI and type(j) == "number" and j >= 0 and not seen[j] and rn.byIdx[j] == nil then
            seen[j] = true
            local okE, kind = GetTownMapResourceEvent(j, 1, false, false)
            local okF, slot = funcLuaCommand(VRFW.route_nodes.CMD_PIECE_INFO, j, 6)
            if okE and okF and type(slot) == "number" and kind ~= VRFW.route_nodes.START_EVENT and kind ~= 4 then
              list[#list + 1] = {idx = j, slot = slot, start = i}
            end
          end
        end
      end
    end
  end
  VRFW.route_nodes.START = list
  return list
end

-- Unlock difficulty 1 of every start neighbour with nothing cleared and every difficulty locked.
function VRFW.route_nodes.open_start_neighbours()
  local opened = 0
  local list = VRFW.route_nodes.start_neighbours()
  for n = 1, #list do
    local p = list[n]
    local any_clear, all_locked = false, true
    for d = 1, #VRFW.route_nodes.DIFFS do
      if VRFW.route_nodes.clear(p.slot, VRFW.route_nodes.DIFFS[d]) then
        any_clear = true
      end
      if not VRFW.route_nodes.locked(p.slot, VRFW.route_nodes.DIFFS[d]) then
        all_locked = false
      end
    end
    if not any_clear and all_locked then
      funcLuaCommand(VRFW.route_nodes.CMD_SET_LOCK, p.slot, false, VRFW.route_nodes.FIRST_DIFFICULTY)
      VRFW.route_nodes.START_REDRAW[p.idx] = true
      opened = opened + 1
      VRFW.route_nodes.log("start neighbour opened", "idx", p.idx, "slot", p.slot, "start", p.start)
    end
  end
  return opened
end

-- Redraw the board pieces opened here once they are placed (crest and clear dots of the piece's instance).
function VRFW.route_nodes.start_redraw()
  for idx in pairs(VRFW.route_nodes.START_REDRAW) do
    local ok, inst = pcall(funcLuaMenuVSRouteTownCommand, VRFW.route_nodes.CMD_PIECE_INSTANCE, idx)
    if ok and type(inst) == "number" and inst >= 0 then
      UpdateTownMapPiece(VRFW.route_nodes.PIECE_LAYER, inst, idx)
      if UpdatePieceClearIcon ~= nil then
        UpdatePieceClearIcon(VRFW.route_nodes.CLEAR_ICON_LAYER, inst, idx)
      end
      VRFW.route_nodes.START_REDRAW[idx] = nil
      VRFW.route_nodes.log("start neighbour redrawn", "idx", idx, "instance", inst)
    end
  end
end

-- Every VRFW.route_nodes.START_CHECK_FRAMES frames of the board (end of PreStep, graft route_board), while no
function VRFW.route_nodes.start_neighbours_step()
  VRFW.route_nodes.START_FRAME = VRFW.route_nodes.START_FRAME + 1
  if VRFW.route_nodes.START_FRAME < VRFW.route_nodes.START_CHECK_FRAMES then
    return
  end
  VRFW.route_nodes.START_FRAME = 0
  if funcLuaCommand(VRFW.route_nodes.CMD_TRIGGER_RUNNING) then
    return
  end
  VRFW.route_nodes.open_start_neighbours()
  VRFW.route_nodes.start_redraw()
end

-- Save state of every node
function VRFW.route_nodes.sync(effect)
  local rn = VRFW.route_nodes.load()
  local opened = false
  for i = 1, #rn.nodes do
    local node = rn.nodes[i]
    local any_clear, all_open = false, true
    for k = 1, #VRFW.route_nodes.DIFFS do
      local d = VRFW.route_nodes.DIFFS[k]
      if VRFW.route_nodes.clear(node.slot, d) then
        any_clear = true
      end
      if VRFW.route_nodes.locked(node.slot, d) then
        all_open = false
      end
    end
    local ready = VRFW.route_nodes.ready(node)
    if not any_clear and (all_open or (not ready and VRFW.route_nodes.is_open(node))) then
      for k = 1, #VRFW.route_nodes.DIFFS do
        funcLuaCommand(VRFW.route_nodes.CMD_SET_LOCK, node.slot, true, VRFW.route_nodes.DIFFS[k])
      end
    end
    if ready then
      local was_open = VRFW.route_nodes.is_open(node)
      if not was_open and effect and node.idx >= 0 and WaitPieceOpenEffect ~= nil then
        WaitPieceOpenEffect({node.idx}, {true})
      end
      local shown = false
      for k = 1, #node.diffs do
        if not VRFW.route_nodes.locked(node.slot, node.diffs[k]) then
          shown = true
        end
      end
      if not shown then
        funcLuaCommand(VRFW.route_nodes.CMD_SET_LOCK, node.slot, false, node.diffs[1])
      end
      if not was_open then
        opened = true
        VRFW.route_nodes.log("open", "slot", node.slot, "idx", node.idx, "effect", tostring(effect))
      end
    end
    if VRFW.route_nodes.sync_gates(node, effect) then
      opened = true
    end
  end
  return opened
end

-- The nodes' roads, drawn at RUN TIME above the map tiles (the per-combination tile copies are gone)
VRFW.route_nodes.ROAD_LAYER = 922325769 --[[vrfw_route_road]]
VRFW.route_nodes.ROAD_SHEET = 1895945654 --[[#/menu/200_icon/01_icon_emblem/vsroute/icon_vsroute_emblem/vsroute_emblem.g4tx]]
VRFW.route_nodes.ROAD_NODE = 1909474081 --[[icon_new01: the quad's sprite node]]
VRFW.route_nodes.ROAD_QUAD = 36
VRFW.route_nodes.ROAD_SHOWN = {}

function VRFW.route_nodes.main_board()
  return n9 == nil or n9 == 0 or n9 == 364708540 --[[vs_route_town_menu]]
end

function VRFW.route_nodes.road_pool()
  local ok, n = pcall(funcLuaMenuCommand, @crc:CMND_GET_CREATE_LAYER_NUM@, VRFW.route_nodes.ROAD_LAYER)
  if ok and type(n) == "number" and n > 0 then
    return n
  end
  return nil
end

function VRFW.route_nodes.road_set(i, road, shown)
  if road == nil or not shown then
    pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, VRFW.route_nodes.ROAD_LAYER, i, false)
    VRFW.route_nodes.ROAD_SHOWN[i] = false
    return
  end
  local q = VRFW.route_nodes.ROAD_QUAD
  pcall(funcLuaMenuCommand, 558735651, VRFW.route_nodes.ROAD_LAYER, VRFW.route_nodes.ROAD_SHEET, CALC_CRC(road.sprite), VRFW.route_nodes.ROAD_NODE, 0, i)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_LOCAL_POS@, VRFW.route_nodes.ROAD_LAYER, road.x, road.y, 0, i)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_LOCAL_SCALE@, VRFW.route_nodes.ROAD_LAYER, road.w / q, road.h / q, 1, i)
  pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_VISIBLE@, VRFW.route_nodes.ROAD_LAYER, i, true)
  if VRFW.route_nodes.ROAD_SHOWN[i] ~= true then
    VRFW.route_nodes.log("road", i, "node", road.node, road.sprite, "at", road.x, road.y, "size", road.w, road.h)
  end
  VRFW.route_nodes.ROAD_SHOWN[i] = true
end

-- Whether road `road` is drawn
function VRFW.route_nodes.road_shown(road, extra)
  local node = VRFW.route_nodes.load().nodes[road.node + 1]
  return node ~= nil and (node == extra or VRFW.route_nodes.shown(node) or node.lockedGuide ~= 0)
end

function VRFW.route_nodes.road_setup(i)
  if not VRFW.route_nodes.main_board() then
    return
  end
  local road = VRFW.route_nodes.load().roads[i + 1]
  VRFW.route_nodes.road_set(i, road, road ~= nil and VRFW.route_nodes.road_shown(road))
end

function VRFW.route_nodes.roads(extra)
  if not VRFW.route_nodes.main_board() then
    return
  end
  local rn = VRFW.route_nodes.load()
  local pool = VRFW.route_nodes.road_pool()
  if pool == nil then
    if #rn.roads > 0 then
      VRFW.route_nodes.log("roads: the layer vrfw_route_road is not on this board (menus route_roads.toml not built?)", #rn.roads, "roads not drawn")
    end
    return
  end
  if #rn.roads > pool then
    VRFW.route_nodes.log("WARN roads:", #rn.roads, "roads, the layer has", pool, "instances: the last", #rn.roads - pool, "are not drawn")
  end
  for i = 0, pool - 1 do
    local road = rn.roads[i + 1]
    VRFW.route_nodes.road_set(i, road, road ~= nil and VRFW.route_nodes.road_shown(road, extra))
  end
end

-- A node opens while the board is shown (its unlock effect)
function VRFW.route_nodes.reveal(node)
  if not VRFW.route_nodes.main_board() then
    return
  end
  local rn = VRFW.route_nodes.load()
  local pool = VRFW.route_nodes.road_pool() or 0
  for k = 1, math.min(#rn.roads, pool) do
    local road = rn.roads[k]
    if rn.nodes[road.node + 1] == node then
      VRFW.route_nodes.log("reveal", "node", road.node, road.sprite)
      VRFW.route_nodes.road_set(k - 1, road, true)
    end
  end
end

function VRFW.route_nodes.reveal_pieces(idxs)
  if idxs == nil then
    return
  end
  local rn = VRFW.route_nodes.load()
  for i = 1, #idxs do
    local node = rn.byIdx[idxs[i]]
    if node ~= nil and not VRFW.route_nodes.is_open(node) then
      VRFW.route_nodes.reveal(node)
    end
  end
end

-- The caravan's rails (the bus drove straight from Big Waves to C1 across the houses).
VRFW.route_nodes.RAILS = true
VRFW.route_nodes.FIT = nil
VRFW.route_nodes.EPS = 3

function VRFW.route_nodes.layer_pos(idx)
  local ok, x, y = pcall(funcLuaMenuVSRouteTownCommand, 1731060169, idx)
  if ok and type(x) == "number" and type(y) == "number" then
    return x, y
  end
  return nil
end

-- Fits the board per axis.
function VRFW.route_nodes.fit()
  if VRFW.route_nodes.FIT ~= nil then
    return VRFW.route_nodes.FIT or nil
  end
  local pts = {}
  for _, node in ipairs(VRFW.route_nodes.load().nodes) do
    local p = node.path
    if #p >= 2 then
      local ends = {{node.bidx, p[1]}, {node.idx, p[#p]}}
      for _, e in ipairs(ends) do
        if e[1] >= 0 then
          local lx, ly = VRFW.route_nodes.layer_pos(e[1])
          if lx ~= nil then
            pts[#pts + 1] = {e[2][1], e[2][2], lx, ly}
          end
        end
      end
    end
  end
  local function axis(gi, li)
    local n, sg, sl, sgg, sgl = #pts, 0, 0, 0, 0
    for _, q in ipairs(pts) do
      sg, sl, sgg, sgl = sg + q[gi], sl + q[li], sgg + q[gi] * q[gi], sgl + q[gi] * q[li]
    end
    local den = n * sgg - sg * sg
    if n < 2 or math.abs(den) < 1e-6 then
      return nil
    end
    local k = (n * sgl - sg * sl) / den
    return {(sl - k * sg) / n, k}
  end
  local fx, fy = axis(1, 3), axis(2, 4)
  if fx == nil or fy == nil then
    VRFW.route_nodes.FIT = false
    VRFW.route_nodes.log("rails: no grid -> layer fit (points", #pts, ")")
    return nil
  end
  VRFW.route_nodes.FIT = {fx, fy}
  VRFW.route_nodes.log("rails: fit x", fx[1], fx[2], "y", fy[1], fy[2], "points", #pts)
  return VRFW.route_nodes.FIT
end

function VRFW.route_nodes.near(a, b)
  return math.abs(a[1] - b[1]) <= VRFW.route_nodes.EPS and math.abs(a[2] - b[2]) <= VRFW.route_nodes.EPS
end

-- c on the segment a-b (strictly between, within VRFW.route_nodes.EPS of the line)
function VRFW.route_nodes.on(c, a, b)
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local l2 = dx * dx + dy * dy
  if l2 < 1 then
    return false
  end
  local t = ((c[1] - a[1]) * dx + (c[2] - a[2]) * dy) / l2
  if t <= 0.01 or t >= 0.99 then
    return false
  end
  local px, py = a[1] + t * dx - c[1], a[2] + t * dy - c[2]
  return px * px + py * py <= VRFW.route_nodes.EPS * VRFW.route_nodes.EPS * 4
end

function VRFW.route_nodes.path(t)
  if not VRFW.route_nodes.RAILS or type(t) ~= "table" or #t < 4 then
    return t
  end
  local ok, out = pcall(function()
    local fit = VRFW.route_nodes.fit()
    if fit == nil then
      return t
    end
    local P = {}
    for k = 1, #t - 1, 2 do
      P[#P + 1] = {t[k], t[k + 1]}
    end
    local changed = false
    for _, node in ipairs(VRFW.route_nodes.load().nodes) do
      local p = node.path
      if #p >= 3 and node.idx >= 0 and node.bidx >= 0 then
        local bx, by = VRFW.route_nodes.layer_pos(node.bidx)
        local nx, ny = VRFW.route_nodes.layer_pos(node.idx)
        if bx ~= nil and nx ~= nil then
          local B, N = {bx, by}, {nx, ny}
          local inner = {}
          for k = 2, #p - 1 do
            inner[#inner + 1] = {fit[1][1] + fit[1][2] * p[k][1], fit[2][1] + fit[2][2] * p[k][2]}
          end
          local Q = {}
          for k = 1, #P do
            Q[#Q + 1] = P[k]
            local nxt = P[k + 1]
            if nxt ~= nil and VRFW.route_nodes.near(P[k], B) and VRFW.route_nodes.near(nxt, N) then
              for j = 1, #inner do
                Q[#Q + 1] = inner[j]
              end
              changed = true
            elseif nxt ~= nil and VRFW.route_nodes.near(P[k], N) and VRFW.route_nodes.near(nxt, B) then
              for j = #inner, 1, -1 do
                Q[#Q + 1] = inner[j]
              end
              changed = true
            end
          end
          P = Q
        end
      end
    end
    if not changed then
      return t
    end
    -- Handles a piece that was passed and come back from.
    local k = 1
    while k + 2 <= #P do
      if VRFW.route_nodes.on(P[k + 2], P[k], P[k + 1]) or VRFW.route_nodes.on(P[k], P[k + 1], P[k + 2]) then
        table.remove(P, k + 1)
      else
        k = k + 1
      end
    end
    local r = {}
    for _, q in ipairs(P) do
      r[#r + 1] = q[1]
      r[#r + 1] = q[2]
    end
    VRFW.route_nodes.log("rails: path", #t / 2, "->", #P, "points")
    return r
  end)
  if ok and type(out) == "table" then
    return out
  end
  VRFW.route_nodes.log("rails: error", tostring(out))
  return t
end

VRFW.route_nodes.off_road_map = nil

function VRFW.route_nodes.off_road_nodes()
  if VRFW.route_nodes.off_road_map ~= nil then
    return VRFW.route_nodes.off_road_map
  end
  local L = VRFW.route_nodes.load()
  local drawn = {}
  for _, r in ipairs(L.roads) do
    drawn[r.node] = true
  end
  VRFW.route_nodes.off_road_map = {byIdx = {}, n = 0}
  for _, node in ipairs(L.nodes) do
    if node.idx >= 0 and node.bidx >= 0 and #node.path >= 2 and not drawn[node.i] then
      VRFW.route_nodes.off_road_map.byIdx[node.idx] = node
      VRFW.route_nodes.off_road_map.n = VRFW.route_nodes.off_road_map.n + 1
    end
  end
  VRFW.route_nodes.log("rails: road-less nodes", VRFW.route_nodes.off_road_map.n)
  return VRFW.route_nodes.off_road_map
end

-- Returns the piece the caravan stands on for board piece idx.
function VRFW.route_nodes.chara_piece(idx)
  if not VRFW.route_nodes.RAILS or type(idx) ~= "number" or idx < 0 then
    return idx
  end
  local node = VRFW.route_nodes.off_road_nodes().byIdx[idx]
  return node ~= nil and node.bidx or idx
end

function VRFW.route_nodes.off_road(t)
  if not VRFW.route_nodes.RAILS or type(t) ~= "table" or #t < 4 then
    return t
  end
  local ok, out = pcall(function()
    local P = {}
    for k = 1, #t - 1, 2 do
      P[#P + 1] = {t[k], t[k + 1]}
    end
    local changed, last = false, nil
    for idx, node in pairs(VRFW.route_nodes.off_road_nodes().byIdx) do
      local nx, ny = VRFW.route_nodes.layer_pos(idx)
      local bx, by = VRFW.route_nodes.layer_pos(node.bidx)
      if nx ~= nil and bx ~= nil then
        local N, B = {nx, ny}, {bx, by}
        if VRFW.route_nodes.near(P[#P], N) or VRFW.route_nodes.near(P[1], N) then
          last = {N = N, B = B}
        end
        if VRFW.route_nodes.near(P[#P], N) then        -- going to the node: the caravan stops at its beside piece
          table.remove(P)
          if #P == 0 or not VRFW.route_nodes.near(P[#P], B) then
            P[#P + 1] = B
          end
          changed = true
        end
        if #P > 0 and VRFW.route_nodes.near(P[1], N) then   -- leaving the node: from its beside piece
          table.remove(P, 1)
          if #P == 0 or not VRFW.route_nodes.near(P[1], B) then
            table.insert(P, 1, B)
          end
          changed = true
        end
      end
    end
    if not changed then
      return t
    end
    -- Skips a leg of no length.
    local Q = {P[1]}
    for k = 2, #P do
      if not VRFW.route_nodes.near(P[k], Q[#Q]) then
        Q[#Q + 1] = P[k]
      end
    end
    P = Q
    if #P < 2 then
      -- The caravan is already at the road point.
      local a, n = P[1], last and last.N or P[1]
      local dx, dy = n[1] - a[1], n[2] - a[2]
      local l = math.sqrt(dx * dx + dy * dy)
      if l < 1e-6 then
        dx, dy, l = 1, 0, 1
      end
      P[2] = {a[1] + dx / l * 0.5, a[2] + dy / l * 0.5}
    end
    local r = {}
    for _, q in ipairs(P) do
      r[#r + 1] = q[1]
      r[#r + 1] = q[2]
    end
    VRFW.route_nodes.log("rails: road-less end", #t / 2, "->", #P, "points")
    return r
  end)
  if ok and type(out) == "table" then
    return out
  end
  VRFW.route_nodes.log("rails: road-less error", tostring(out))
  return t
end

-- Places the caravan on the board (retail UpdateCharaPos(piece index), every idle frame).
VRFW.route_nodes.CHARA_WRAPPED = false
function VRFW.route_nodes.wrap_chara()
  if VRFW.route_nodes.CHARA_WRAPPED or type(UpdateCharaPos) ~= "function" then
    return
  end
  VRFW.route_nodes.CHARA_WRAPPED = true
  local prev = UpdateCharaPos
  UpdateCharaPos = function(a1, ...)
    return prev(VRFW.route_nodes.chara_piece(a1), ...)
  end
end

-- The board cursor follows the same rails (the green cursor still slid straight from Big Waves to C1).
VRFW.route_nodes.SCROLL = nil

function VRFW.route_nodes.scroll_start(target)
  VRFW.route_nodes.SCROLL = nil
  if not VRFW.route_nodes.RAILS or n11 == nil or n11 < 0 or target == nil or target < 0 or n11 == target then
    return
  end
  local ok, err = pcall(function()
    local sx, sy = VRFW.route_nodes.layer_pos(n11)
    local tx, ty = VRFW.route_nodes.layer_pos(target)
    if sx == nil or tx == nil then
      return
    end
    local rail = VRFW.route_nodes.path({sx, sy, tx, ty})
    if type(rail) ~= "table" or #rail <= 4 then
      return
    end
    local z = n23 or 1
    local S = {-n5, -n6}
    local pts, len = {}, {0}
    for k = 1, #rail - 1, 2 do
      pts[#pts + 1] = {S[1] + z * (rail[k] - sx), S[2] + z * (rail[k + 1] - sy)}
    end
    for k = 2, #pts do
      local dx, dy = pts[k][1] - pts[k - 1][1], pts[k][2] - pts[k - 1][2]
      len[k] = len[k - 1] + math.sqrt(dx * dx + dy * dy)
    end
    local T = {S[1] + z * (tx - sx), S[2] + z * (ty - sy)}
    if len[#pts] < 1 then
      return
    end
    VRFW.route_nodes.SCROLL = {S = S, T = T, pts = pts, len = len}
    VRFW.route_nodes.log("rails: scroll", n11, "->", target, "points", #pts)
  end)
  if not ok then
    VRFW.route_nodes.log("rails: scroll error", tostring(err))
  end
end

function VRFW.route_nodes.scroll_end()
  VRFW.route_nodes.SCROLL = nil
end

function VRFW.route_nodes.scroll_rail(x, y)
  local r = VRFW.route_nodes.SCROLL
  if r == nil or type(x) ~= "number" or type(y) ~= "number" then
    return x, y
  end
  local dx, dy = r.T[1] - r.S[1], r.T[2] - r.S[2]
  local l2 = dx * dx + dy * dy
  if l2 < 1 then
    return x, y
  end
  local t = ((x - r.S[1]) * dx + (y - r.S[2]) * dy) / l2
  local ox, oy = r.S[1] + t * dx - x, r.S[2] + t * dy - y
  if ox * ox + oy * oy > l2 * 0.01 + 16 then
    VRFW.route_nodes.log("rails: scroll off the line, left alone")
    VRFW.route_nodes.SCROLL = nil
    return x, y
  end
  if t <= 0 then
    return r.pts[1][1], r.pts[1][2]
  end
  if t >= 1 then
    return r.pts[#r.pts][1], r.pts[#r.pts][2]
  end
  local want = t * r.len[#r.pts]
  for k = 2, #r.pts do
    if want <= r.len[k] then
      local seg = r.len[k] - r.len[k - 1]
      local f = seg > 0 and (want - r.len[k - 1]) / seg or 1
      return r.pts[k - 1][1] + f * (r.pts[k][1] - r.pts[k - 1][1]), r.pts[k - 1][2] + f * (r.pts[k][2] - r.pts[k - 1][2])
    end
  end
  return r.pts[#r.pts][1], r.pts[#r.pts][2]
end

function VRFW.route_nodes.rows(rows, slot)
  local node = VRFW.route_nodes.by_slot(slot)
  if node == nil or rows == nil then
    return rows
  end
  local keep = {}
  for i = 1, #rows do
    for k = 1, #node.diffs do
      if rows[i].difficultyType == node.diffs[k] then
        keep[#keep + 1] = rows[i]
      end
    end
  end
  if #keep > 0 then
    return keep
  end
  return rows
end
-- VRFW route_nodes END
