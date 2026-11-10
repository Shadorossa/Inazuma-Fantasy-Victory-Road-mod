local function Recruit(i)
  local n = MAP.nodes[i]
  local st = State(i)
  if st == "locked" then
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(T.STATE_LOCKED))
    return
  end
  if st == "done" then
    funcLuaCommand(C.SE, SE_OK)
    Message(Kit.text(VRFW.recruit.owned(n.card) > 0 and T.OWNED or T.STATE_DONE))
    return
  end
  if MAP.kind == "network" and VIEW_ALL.on and not VIEW_ALL.real[i] then
    funcLuaCommand(C.SE, SE_NG)       -- view everything: a tile not open by the real order is never signed
    Message(Kit.text(T.STATE_LOCKED))
    return
  end
  if n.story then                     -- signed in story mode, not here
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(T.STORY_ONLY))
    return
  end
  local missing = VRFW.recruit.missing(n.reqs)
  if #missing > 0 then
    funcLuaCommand(C.SE, SE_NG)
    local lines = {}
    for _, l in ipairs(ReqLines({reqs = missing})) do
      lines[#lines + 1] = l
    end
    Message(Kit.format(T.NEED_REQS, table.concat(lines, "\n")))
    return
  end
  local have = VRFW.recruit.wallet(CmPages.price_of(n))
  if have < Price(n) then
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.format(T.NEED_PRICE, Price(n), CmPages.pay_name(n), have))
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  if not Ask(Kit.format(T.ASK, n.name, n.level, Price(n), CmPages.pay_name(n))) then
    return
  end
  local ok, why = VRFW.recruit.recruit({param = n.card, level = n.level, reqs = n.reqs,
                                       rarity = SET ~= nil and SET.join_rarity or nil, price = CmPages.price_of(n)})
  if not ok then
    Log("recruit refused", MAP.key, i, n.card, why)
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(why == "bank_full" and T.BANK_FULL or (why == "owned" and T.OWNED or T.FAILED)))
    return
  end
  signed[i] = true
  SaveRecord()
  CmPages.own = {}
  CmPages.waive_signed()
  if MAP.kind == "network" then
    NetState()
  end
  Log("recruited", MAP.key, i, n.card, "level", n.level, "price", Price(n))
  DrawAll()
  Message(Kit.format(T.JOINED, n.name))
end

local function Buy(it)
  local have = VRFW.recruit.items(SET.ic)
  if have < it.price then
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.format(T.NEED_PRICE, it.price, Kit.text(SET.ict), have))
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  if not Ask(Kit.format(T.SHOP_ASK, Kit.text(it.title), it.price, Kit.text(SET.ict))) then
    return
  end
  if not VRFW.recruit.charge(SET.ic, it.price) then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if not VRFW.recruit.give(it.item, 1) then
    VRFW.recruit.give(SET.ic, it.price)       -- the price back: no room
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(T.BAG_FULL))
    return
  end
  Log("bought", MAP.key, it.item, "price", it.price)
  DrawAll()
  Message(Kit.format(T.SHOP_BOUGHT, Kit.text(it.title)))
end

local function Decide()
  if mode == "list" then
    funcLuaCommand(C.SE, SE_DECIDE)
    OpenMap(focus.list)
  elseif mode == "zones" then
    if MAP.zones[focus.zones] ~= nil then
      funcLuaCommand(C.SE, SE_DECIDE)
      OpenZone(focus.zones)
    end
  elseif mode == "grid" then
    local i = members[focus.grid]
    if i ~= nil and MAP.nodes[i].kind == "ghost" then
      CmPages.ghost_ask(i)
    elseif i ~= nil then
      Recruit(i)
    end
  elseif mode == "network" then
    local n = MAP.nodes[focus.network]
    if n.kind == "player" then
      Recruit(focus.network)
    elseif n.kind == "gate" and not acquired[focus.network] then
      funcLuaCommand(C.SE, SE_NG)
      Message(opened[focus.network] and Kit.format(T.GATE, n.name) or Kit.text(T.STATE_LOCKED))
    else
      funcLuaCommand(C.SE, SE_OK)
    end
  elseif mode == "shop" then
    if shelf[focus.shop] ~= nil then
      Buy(shelf[focus.shop])
    end
  end
end

function CmNetZoom(f)                -- the target only: CmNetEase shows it
  NET.T = math.max(NET.FIT, math.min(NET.MAX, (NET.T or NET.S) * f))
end
function CmNetEase()
  local t = NET.T or NET.S
  if math.abs(t - NET.S) <= t * 0.0015 then
    if t ~= NET.S then
      SetScale(t)
      ClampCamera()
      KeepFocusInView()
      DrawAll()
    end
    return
  end
  local a = 1 - math.exp(-NET.DT / NET.EASE)
  SetScale(NET.S + (t - NET.S) * a)
  ClampCamera()
  KeepFocusInView()
  DrawAll()
end
function CmNetPan(dx, dy)            -- screen px
  local bx, by = NET.cx, NET.cy
  NET.cx, NET.cy = NET.cx + dx / NET.S, NET.cy + dy / NET.S
  ClampCamera()
  if math.abs(NET.cx - bx) * NET.S > 0.5 or math.abs(NET.cy - by) * NET.S > 0.5 then
    KeepFocusInView()
    DrawAll()
  end
end
function CmNetViewStep(free)
  if mode ~= "network" or MAP == nil or not free then
    NET.drag = nil
    return
  end
  -- Returns whether LT or RT is held.
  local function Held(name, cmds)
    for _, c in ipairs(cmds) do
      if Kit.key_pressed(c) then
        NET[name] = KEYS.frame + NET.HOLD
        break
      end
    end
    return (NET[name] or -1) >= KEYS.frame
  end
  if Held("lt", {3833829418 --[[CMD_FUNCL2_ON]], 1520574355 --[[CMD_FUNCL2_REPEAT]], 1970176280 --[[CMD_FUNCL2]]}) then
    CmNetZoom(NET.ZOOM_RATE ^ -NET.DT)
  elseif Held("rt", {995340745 --[[CMD_FUNCR2_ON]], 1050707568 --[[CMD_FUNCR2_REPEAT]], 2704260807 --[[CMD_FUNCR2]]}) then
    CmNetZoom(NET.ZOOM_RATE ^ NET.DT)
  end
  CmNetEase()
  -- Reads the right stick (CMND_GET_ANALOG_VALUE 2 and 3, y above 0 means up).
  local okx, x = pcall(funcLuaCommand, KEYS.ANALOG, 2)
  local oky, y = pcall(funcLuaCommand, KEYS.ANALOG, 3)
  x = (okx and type(x) == "number") and x or 0
  y = (oky and type(y) == "number") and y or 0
  local function speed(v)
    local a = math.abs(v)
    if a <= NET.DEAD then
      return 0
    end
    local f = (a - NET.DEAD) / (1 - NET.DEAD)
    return (v > 0 and 1 or -1) * NET.PAN * f * f
  end
  local px_, py_ = speed(x), -speed(y)
  if px_ ~= 0 or py_ ~= 0 then
    CmNetPan(px_, py_)
  end
  -- Handles the mouse drag (left button held on empty space).
  local held = Kit.key_pressed(749879980 --[[CMD_VRFW_MOUSE_LEFT]])
  local px, py = Ptr.pos()
  if held and px ~= nil then
    if NET.drag == nil then
      NET.drag = {x = px, y = py}
    else
      local dx, dy = px - NET.drag.x, py - NET.drag.y
      if dx ~= 0 or dy ~= 0 then
        NET.drag.x, NET.drag.y = px, py
        CmNetPan(-dx, -dy)
      end
    end
  else
    NET.drag = nil
  end
end

local function PollPointer()
  local ev = Kit.poll_pointer(pos)
  if vrfw_co ~= nil or not ready or open_guard > 0 then
    return
  end
  if type(ev.hover) == "number" and ev.hover ~= focus[mode] and NET.drag == nil then
    focus[mode] = ev.hover
    funcLuaCommand(C.SE, SE_OK)
    DrawAll()
  end
  if type(ev.click) == "number" then
    KEYS.cb.ENTER = KEYS.frame
    focus[mode] = ev.click
    StartCo(Decide)
  end
  if mode == "network" and type(ev.wheel) == "number" then
    CmNetZoom(ev.wheel < 0 and NET.WHEEL or 1 / NET.WHEEL)   -- wheel up = zoom in (the target: eased)
  end
end
