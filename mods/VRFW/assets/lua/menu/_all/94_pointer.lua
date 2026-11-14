-- Written by research/scripts/framework_pack.py from research/grafts/_lib/vrfw_menu_kit.lua section Pointer.
--- Advanced: Namespace: mouse pointer tracker for menus; holds new().
VRFW.pointer = VRFW.pointer or {}
--- Advanced: Creates a mouse pointer tracker; answers a table with zone setters (rect, box, inst), position, at, poll and reset.
VRFW.pointer.new = VRFW.pointer.new or function()
  local P = {zones = {}, on = false, x = nil, y = nil, hot = nil, prev = {}, edge_t = 0, REPEAT = 10}
  local MOVED, POS, GPOS, CHECK, CTRL = 3272825600, 558229292, 4002164178, 4265778440, 1332654303
  local LEFT, CLICK = 749879980 --[[CMD_VRFW_MOUSE_LEFT]], 1651523701 --[[CMD_ENTER_CLICK]]
  local W_UP, W_DOWN = 2649361876 --[[CMD_VRFW_WHEEL_UP]], 1098743808 --[[CMD_VRFW_WHEEL_DOWN]]
  local NAV = {1197218715, 3259546669, 2765147006, 2075023265} -- CMD_UP / DOWN / LEFT / RIGHT
  local CTRLS = {CTRL, 2748927068 --[[analog-move control: the stick's menu moves]]}
  local function M(cmd, ...)
    local ok, a, b = pcall(funcLuaMenuCommand, cmd, ...)
    if ok then return a, b end
    return nil
  end
  local function In(cmd, ctrl)
    local ok, r = pcall(funcLuaCommand, CHECK, ctrl or CTRL, cmd)
    return ok and r == true
  end
  local function Edge(cmd, ctrl)
    local key = ctrl and (tostring(ctrl) .. ":" .. tostring(cmd)) or cmd
    local now = In(cmd, ctrl)
    local was = P.prev[key]
    P.prev[key] = now
    return now and not was
  end
  --- Starts a new list of pointer zones for this frame.
  function P.begin()
    P.zones = {}
  end
  --- Adds a zone by top-left corner and size; `id` is what P.at answers, `edge` as in P.poll.
  function P.rect(x, y, w, h, id, edge)
    P.zones[#P.zones + 1] = {x, y, x + w, y + h, id = id, edge = edge}
  end
  --- Adds a zone by centre and half sizes; `id` and `edge` as in P.rect.
  function P.box(cx, cy, hw, hh, id, edge)
    P.zones[#P.zones + 1] = {cx - hw, cy - hh, cx + hw, cy + hh, id = id, edge = edge}
  end
  --- Adds a zone that follows instance idx of a layer, with half sizes hw and hh.
  function P.inst(layer, idx, hw, hh, id, edge)
    P.zones[#P.zones + 1] = {layer = layer, idx = idx, hw = hw, hh = hh, id = id, edge = edge}
  end
  --- The pointer position: x, y, or nil when it is not available.
  function P.position()
    local x, y = M(POS)
    if type(x) == "number" and type(y) == "number" then return x, y end
    return nil
  end
  --- The topmost zone under (x, y), or under the last pointer position; nil when there is none.
  function P.at(x, y)
    if x == nil then x, y = P.x, P.y end
    if x == nil then return nil end
    for i = #P.zones, 1, -1 do
      local z = P.zones[i]
      if z.layer ~= nil then
        local gx, gy = M(GPOS, z.layer, z.idx)
        if type(gx) == "number" and type(gy) == "number" and math.abs(x - gx) <= z.hw and math.abs(-y - gy) <= z.hh then
          return z
        end
      elseif x >= z[1] and x < z[3] and y >= z[2] and y < z[4] then
        return z
      end
    end
    return nil
  end
  -- (Enter / A with the pointer resting on empty space is a key Accept on the current selection)
  --- True when this press belongs to the pointer: a left click, or a click over a zone while the pointer is on.
  function P.owns()
    return In(LEFT) or (P.on and In(CLICK) and P.at() ~= nil)
  end
  --- Clears the hovered zone.
  function P.forget()
    P.hot = nil
  end
  --- Hands the cursor to the keys for this frame: pointer off, hover cleared, position remembered.
  function P.key_step()
    P.on, P.hot = false, nil
    local x, y = P.position()
    if x ~= nil then P.x, P.y = x, y end
  end
  --- Clears the zones, the hover and the edge state, and remembers the pointer position.
  function P.reset()
    P.zones, P.on, P.hot, P.prev, P.edge_t = {}, false, nil, {}, 0
    P.x, P.y = P.position()
    for _, c in ipairs({LEFT, CLICK, W_UP, W_DOWN}) do Edge(c) end
    for _, ctrl in ipairs(CTRLS) do
      for _, c in ipairs(NAV) do Edge(c, ctrl) end
    end
  end
  --- One frame of pointer input; answers this frame's event table.
  function P.poll()
    local ev = {}
    local x, y = P.position()
    if x ~= nil then
      local moved = M(MOVED) == true
      if not moved and P.x ~= nil and (math.abs(x - P.x) > 1 or math.abs(y - P.y) > 1) then
        moved = true
      end
      P.x, P.y = x, y
      if moved then
        P.on, ev.moved = true, true
      end
    end
    for _, ctrl in ipairs(CTRLS) do
      for _, c in ipairs(NAV) do
        if Edge(c, ctrl) then
          ev.keys = true
        end
      end
    end
    if ev.keys and not ev.moved then
      P.on = false
    end
    local left, click = Edge(LEFT), Edge(CLICK)
    if left then
      P.on, ev.left = true, true
    end
    local z = P.on and P.at() or nil
    local id = z and z.id or nil
    ev.changed = id ~= P.hot
    P.hot, ev.hot = id, id
    if z ~= nil and (ev.moved or left) then
      ev.hover = id
    end
    if left then
      if z ~= nil then
        ev.click = id
      else
        ev.miss = true                 -- a mouse click on empty space: nothing
      end
    elseif click and P.on then
      if z ~= nil then
        ev.click = id
      else
        P.on, P.hot = false, nil
      end
    end
    if In(W_DOWN) then
      ev.wheel = 1
    elseif In(W_UP) then
      ev.wheel = -1
    end
    if z ~= nil and z.edge ~= nil then
      P.edge_t = P.edge_t - 1
      if P.edge_t <= 0 then
        ev.edge, P.edge_t = z.edge, P.REPEAT
      end
    else
      P.edge_t = 0
    end
    return ev
  end
  return P
end
