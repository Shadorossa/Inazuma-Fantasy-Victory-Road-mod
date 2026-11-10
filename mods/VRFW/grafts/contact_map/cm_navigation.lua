local function SetMode(m)
  mode = m
  UpdateTitle()
  UpdateButtonGuide()
  DrawAll()
end

-- Handles a network that is opened (one map, no pages).
local function NetOpen()
  local minx, maxx, miny, maxy = nil, nil, nil, nil
  for _, n in ipairs(MAP.nodes) do
    minx, maxx = math.min(minx or n.x, n.x), math.max(maxx or n.x, n.x)
    miny, maxy = math.min(miny or n.y, n.y), math.max(maxy or n.y, n.y)
  end
  MAP.cx, MAP.miny, MAP.maxy = ((minx or 0) + (maxx or 0)) / 2, miny or 0, maxy or 0
  MAP.minx, MAP.maxx = minx or 0, maxx or 0
  local sx, sy = (maxx or 0) - (minx or 0), (maxy or 0) - (miny or 0)
  local vw, vh = VIEW.X1 - VIEW.X0 - NET.PLATE0, VIEW.Y1 - VIEW.Y0 - NET.PLATE0
  local fit = math.min(NET.S0, sx > 0 and vw / sx or NET.S0, sy > 0 and vh / sy or NET.S0)
  local density = #MAP.nodes / math.max(1, (sx + NET.PLATE0) * (sy + NET.PLATE0))
  local cap = math.sqrt(density * vw * vh / NET.CAP)   -- the scale at which ~CAP tiles fill the view
  NET.FIT = math.min(NET.S0, math.max(fit, cap))
  NET.T = math.max(NET.FIT, math.min(NET.S0, sx > 0 and vw / sx or NET.S0))
  SetScale(NET.T)
  NetState()
  focus.network = 1
  for i, n in ipairs(MAP.nodes) do
    if n.kind == "player" and opened[i] and not acquired[i] then
      focus.network = i
      break
    end
  end
  NET.cx, NET.cy = MAP.nodes[focus.network].x, MAP.nodes[focus.network].y
  ClampCamera()
  FollowCamera()
  N.full = false
end

function CmPages.hide_locked_zones()
  if VIEW_ALL.on then
    return #MAP.zones
  end
  local keep, new = {}, {}
  for z, zz in ipairs(MAP.zones) do
    if type(zz.reqs) ~= "table" or #VRFW.recruit.missing(zz.reqs) == 0 then
      keep[#keep + 1] = zz
      new[z] = #keep
    end
  end
  if #keep == #MAP.zones then
    return #keep
  end
  for _, n in ipairs(MAP.nodes) do
    local z = new[n.zone]
    if n.zone > 0 and z == nil then
      n.kind, n.zone = "hidden", 0
    elseif z ~= nil then
      n.zone = z
    end
  end
  Log("zones open", MAP.key, #keep, "of", #MAP.zones)
  MAP.zones = keep
  return #keep
end

local function OpenMap(i)
  local m = SET.maps[i]
  local data = Call(C.CM_MAP, m.key, lang)
  if type(data) ~= "table" or type(data.nodes) ~= "table" then
    Log("map not served", m.key)
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  MAP = data
  MAP.key = m.key
  MAP.zones = MAP.zones or {}
  MAP.items = MAP.items or {}
  for _, n in ipairs(MAP.nodes) do
    n.links = n.links or {}
    n.reqs = n.reqs or {}
    n.name = n.name or ""
    n.face = n.face or ""
    if SET.bypass then                -- a test mod's bypass switch: no requirement, no price
      n.reqs, n.price = {}, 0
    end
  end
  if SET.bypass then
    for _, zz in ipairs(MAP.zones) do
      zz.reqs = {}
    end
  end
  CmPages.own = {}
  CmPages.load_seen()
  if #MAP.zones > 0 and not CmPages.direct and not CmPages.going and CmPages.hide_locked_zones() == 0 then
    MAP = nil
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(T.TEAMS_NONE))
    return
  end
  CmPages.all = CmPages.going == true
  LoadRecord()
  CmPages.waive_signed()
  if MAP.kind == "network" then
    NetOpen()
    SetMode("network")
  elseif MAP.kind == "list" and #MAP.zones == 1 then
    zone = 1
    members = MAP.pitch and CmPages.members(1) or ZoneMembers(1)
    focus.grid = 1
    SetMode("grid")
  else
    focus.zones = 1
    SetMode("zones")
  end
  Log("open map", m.key, MAP.kind, "nodes", #MAP.nodes, "signed", MapSigned(m))
end

local function OpenZone(z)
  zone = z
  members = MAP.pitch and CmPages.members(z) or ZoneMembers(z)
  focus.grid = 1
  for g, i in ipairs(members) do
    if MAP.nodes[i].kind == "player" and not IsSigned(i) then
      focus.grid = g
      break
    end
  end
  if MAP.pitch and MAP.nodes[members[focus.grid] or 0] ~= nil and MAP.nodes[members[focus.grid]].kind ~= "player" then
    for g, i in ipairs(members) do
      if MAP.nodes[i].kind == "player" then
        focus.grid = g
        break
      end
    end
  end
  SetMode("grid")
end

-- Opens one team page directly.
function CmPages.open_direct()
  local f = Call(@crc:CMND_VRFW_CONTACT_FIND@, SET.key, CmPages.direct)
  if type(f) ~= "table" or f.map == nil then
    Log("direct", "no team page for game", CmPages.direct)
    return false
  end
  for i, m in ipairs(SET.maps) do
    if m.key == f.map then
      OpenMap(i)
      if MAP ~= nil and mode ~= "grid" and MAP.zones[f.zone] ~= nil then
        OpenZone(f.zone)
      end
      Log("direct", "game", CmPages.direct, "map", f.map, "zone", f.zone)
      return MAP ~= nil
    end
  end
  return false
end

-- Opens a team page by its map and team (zone.team).
function CmPages.open_page(map_key, team, all)
  for mi, m in ipairs(SET.maps) do
    if m.key == map_key then
      CmPages.going = all
      OpenMap(mi)
      CmPages.going = false
      if MAP == nil or MAP.key ~= map_key then
        return false
      end
      for z, zz in ipairs(MAP.zones) do
        if zz.team == team then
          if mode ~= "grid" or zone ~= z then
            OpenZone(z)
          end
          return true
        end
      end
      return false
    end
  end
  return false
end

function CmPages.ghost_ask(i)
  local n = MAP.nodes[i]
  local text = Kit.format(T.SOLD_AT, (n.sold_at or "") ~= "" and n.sold_at or Kit.text(T.UNKNOWN))
  local from_team = MAP.zones[zone] and MAP.zones[zone].team or nil
  if n.sold_map == nil or (n.sold_team or 0) == 0 or from_team == nil then
    funcLuaCommand(C.SE, SE_NG)
    Message(text)
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  VRFW.param.set(4261573565 --[[vrfw_window_yes_text]], T.GO)
  VRFW.param.set(1121728934 --[[vrfw_window_no_text]], T.CLOSE)
  local go = Ask(text)
  VRFW.param.clear(4261573565)
  VRFW.param.clear(1121728934)
  if not go then
    return
  end
  local from = {map = MAP.key, team = from_team, grid = focus.grid, all = CmPages.all}
  if not CmPages.open_page(n.sold_map, n.sold_team, true) then
    Log("go", "no page", n.sold_map, n.sold_team, "for card", n.card)
    CmPages.open_page(from.map, from.team, from.all)
    focus.grid = from.grid
    DrawAll()
    funcLuaCommand(C.SE, SE_NG)
    Message(text)
    return
  end
  CmPages.trail[#CmPages.trail + 1] = from
  for g, k in ipairs(members) do
    local m = MAP.nodes[k]
    local same = m.kind == "player" and m.card == n.card
    for _, c in ipairs(m.kind == "player" and m.cards or {}) do
      same = same or c == n.card
    end
    if same then
      focus.grid = g
      break
    end
  end
  DrawAll()
  Log("go", "card", n.card, "to", n.sold_map, n.sold_team, "from", from.map, from.team, "depth", #CmPages.trail)
end

function CmPages.go_back()
  local from = table.remove(CmPages.trail)
  if from == nil or not CmPages.open_page(from.map, from.team, from.all) then
    return false
  end
  focus.grid = from.grid
  DrawAll()
  Log("go back", from.map, from.team, "depth", #CmPages.trail)
  return true
end

local function OpenShop()
  prev_mode = mode
  shelf = ShelfFor()
  focus.shop = 1
  SetMode("shop")
end

-- Keys polled from the pad and keyboard for what the screen's input rows do not carry.
local KEYS = {L1 = 3966226594, R1 = 942075773, BACK = 3011112225,
              held = {}, frame = 0, back_cb = -100, back_poll = nil, logs = 0,
              NAV = {UP = 1197218715, DOWN = 3259546669, LEFT = 2765147006, RIGHT = 2075023265,
                     ENTER = 1981080283, FUNC3 = 3421673595, FUNC4 = 1435897304},
              DIR = {UP = {0, -1}, DOWN = {0, 1}, LEFT = {-1, 0}, RIGHT = {1, 0}},
              ANALOG = @crc:CMND_GET_ANALOG_VALUE@,    -- CMND_GET_ANALOG_VALUE (index: 0 / 1 = left stick x / y)
              FREE_CURSOR = @crc:CMND_SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE@, free_off = false,
              cb = {}, press = {}, owned = {}, next_rep = {}, stick = nil, co_was = false,
              REPEAT_FIRST = 18, REPEAT = 6}
-- Yields to the menu this screen opened over (its header, button guides, token panel).
local function HubYield(on)
  if on == HUB.on then
    return
  end
  if on and HUB.menu == nil then
    -- the opener's parameter (OnInit), else the engine's parent of this menu
    local ok, parent = pcall(function() return MENU_DEF.GetParentMenuID(MENU) end)
    if ok and type(parent) == "number" and parent ~= 0 then
      HUB.menu = parent
    end
  end
  HUB.on = on
  if HUB.menu == nil then
    Log("hub yield", tostring(on), "no parent menu")
    return
  end
  local ok, err = pcall(funcLuaCommand, C.MENU_CALL, HUB.menu, "vrfw_hub_yield", on, MENU)
  Log("hub yield", tostring(on), "menu", HUB.menu, tostring(ok), tostring(err))
end

-- Handles every way out of the screen.
local function Leave(result)
  if Model ~= nil then
    Model.hide()
  end
  KEYS.free(true)
  HubYield(false)
  HEADROW.free()
  if Model ~= nil and Model.cam then        -- the shared menu model camera back (Model.place's fallback)
    pcall(funcLuaCommand, 284729675, 1752770328, 0, 0, 0)
    Model.cam = nil
  end
  Close(result)
end

CmPages.leave = Leave
CmPages.recruited = function()
  if MAP ~= nil and mode == "grid" then
    DrawAll()
  end
end

local function Back()
  if mode == "grid" and #CmPages.trail > 0 and CmPages.go_back() then
    return
  end
  if CmPages.direct and mode ~= "shop" then
    Leave(0)                          -- opened on one team page by its hub: back to the hub
    return
  end
  if mode == "shop" then
    SetMode(prev_mode or "zones")
  elseif mode == "grid" and not (MAP.kind == "list" and #MAP.zones == 1) then
    SetMode("zones")
  elseif mode ~= "list" then
    for _, m in ipairs(SET.maps) do
      if m.key == MAP.key then
        m.signed = MapSigned(m)
      end
    end
    MAP = nil
    SetMode("list")
  else
    Log("back")
    Leave(0)
  end
end

-- the nearest item in a direction among the items on screen (zones / network)
local function MoveNear(dx, dy)
  local P = pos
  if mode == "network" then          -- every tile, also out of view (the camera follows the cursor)
    P = {}
    for i, n in ipairs(MAP.nodes) do
      P[i] = {x = NetX(n), y = NetY(n)}
    end
  end
  local p = P[focus[mode]]
  if p == nil then
    return
  end
  local best, bd = nil, nil
  for i, q in pairs(P) do
    if i ~= focus[mode] then
      local ex, ey = q.x - p.x, q.y - p.y
      local along = ex * dx + ey * dy
      if along > 1 then
        local across = math.abs(ex * dy) + math.abs(ey * dx)
        local d = along + across * 2
        if bd == nil or d < bd then
          best, bd = i, d
        end
      end
    end
  end
  if best ~= nil then
    focus[mode] = best
    funcLuaCommand(C.SE, SE_OK)
    if mode == "network" then
      FollowCamera()
    end
    DrawAll()
  end
end

local function MoveGrid(dx, dy)
  local n = #members
  if n == 0 then
    return
  end
  if MAP.pitch then
    local g = CmPages.pitch_move(dx, dy)
    if g ~= nil then
      focus.grid = g
      funcLuaCommand(C.SE, SE_OK)
      DrawAll()
    end
    return
  end
  local g = focus.grid
  if dx ~= 0 then
    g = g + dx
  else
    g = g + dy * GRID.COLS
  end
  if g < 1 or g > n then
    return
  end
  focus.grid = g
  funcLuaCommand(C.SE, SE_OK)
  DrawAll()
end

local function MoveList(dy, count)
  local k = focus[mode] + dy
  if k < 1 or k > count then
    return
  end
  focus[mode] = k
  funcLuaCommand(C.SE, SE_OK)
  DrawAll()
end

-- Handles LB and RB.
local function PageTurn(d)
  local per, count, key
  if mode == "grid" and MAP.pitch then
    return false
  elseif mode == "grid" then
    per, count, key = GRID.COLS * GRID.ROWS, #members, "grid"
  elseif mode == "list" then
    per, count, key = LIST.ROWS, #SET.maps, "list"
  elseif mode == "zones" then
    per, count, key = LIST.ROWS, #MAP.zones, "zones"
  elseif mode == "shop" then
    per, count, key = LIST.ROWS, #shelf, "shop"
  else
    return false
  end
  if count == 0 then
    return false
  end
  local cur = focus[key]
  local k
  if key == "grid" then
    local pages = math.ceil(count / per)
    local page = math.floor((cur - 1) / per) + d
    if page < 0 or page >= pages then
      return false
    end
    k = math.min(count, page * per + (cur - 1) % per + 1)
  else
    k = math.max(1, math.min(count, cur + d * per))
    if k == cur then
      return false
    end
  end
  focus[key] = k
  Ptr.key_step()
  funcLuaCommand(C.SE, SE_OK)
  DrawAll()
  return true
end

local function KeyEdge(name)
  local on = Kit.key_pressed(KEYS[name])
  local edge = on and not KEYS.held[name]
  KEYS.held[name] = on
  return edge
end
function KEYS.note_seen(name)
  KEYS.seen = (KEYS.seen or 0) + 1
  if KEYS.seen <= 8 then
    Log("input", name, mode)
  end
end
-- Switches the engine's free cursor (virtual mouse, the game's pointer).
function KEYS.free(on, force)
  if not force and KEYS.free_off == not on then
    return
  end
  KEYS.free_off = not on
  local ok = pcall(funcLuaMenuCommand, KEYS.FREE_CURSOR, on, false, true)
  if not force then
    Log("free cursor", tostring(on), tostring(ok))
  end
end
function KEYS.stick_dir()
  local okx, x = pcall(funcLuaCommand, KEYS.ANALOG, 0)
  local oky, y = pcall(funcLuaCommand, KEYS.ANALOG, 1)
  x = (okx and type(x) == "number") and x or 0
  y = (oky and type(y) == "number") and y or 0
  local d = nil
  if math.max(math.abs(x), math.abs(y)) > 0.5 then
    if math.abs(x) >= math.abs(y) then
      d = x > 0 and "RIGHT" or "LEFT"
    else
      d = y > 0 and "UP" or "DOWN"
    end
  elseif KEYS.stick ~= nil then
    local v = KEYS.DIR[KEYS.stick]
    if x * v[1] - y * v[2] > 0.3 then
      d = KEYS.stick
    end
  end
  KEYS.stick = d
  return d
end
-- one step in a direction, as the arrows' input rows do (OnFunction)
function KEYS.move(dx, dy)
  Ptr.key_step()
  if mode == "list" then
    MoveList(dy ~= 0 and dy or dx, #SET.maps)
  elseif mode == "zones" then
    MoveList(dy ~= 0 and dy or dx, #MAP.zones)
  elseif mode == "shop" then
    MoveList(dy ~= 0 and dy or dx, #shelf)
  elseif mode == "grid" then
    MoveGrid(dx, dy)
  else
    MoveNear(dx, dy)
  end
end
