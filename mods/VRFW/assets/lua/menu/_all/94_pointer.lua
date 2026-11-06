-- Written by research/scripts/framework_pack.py from research/grafts/_lib/evt_menu_kit.lua section Pointer.
-- EVT_PointerNew(): a pointer helper for menus that draw their own selectable items (docs/game/ui/mouse-support.md §5).
-- Mouse and VR's free cursor (the stick-driven «virtual mouse», CMND_SET_ENABLE_FREE_CURSOR_FOR_VIRTUAL_MOUSE) are
-- the same pointer: the engine's pointer position (558229292, screen px, y down) is read every frame and any change
-- (or the engine's «mouse moved», 3272825600) puts the menu in pointer mode; a menu arrow (CMD_UP/DOWN/LEFT/RIGHT)
-- ends it. The menu declares its zones each time it draws, from the same positions it draws with:
--   P.Begin()                              forget the zones of the last drawing
--   P.Rect(x, y, w, h, id[, edge])         top-left + size, screen px (y down)
--   P.Box(cx, cy, hw, hh, id[, edge])      centre + half sizes, screen px (y down)
--   P.Inst(layer, idx, hw, hh, id[, edge]) around a layer instance's global position (read at hit-test time)
--   (edge = -1 / 1: a scroll band; hovering it scrolls every P.REPEAT frames: ev.edge)
-- The last zone declared wins (popups / buttons drawn over cards). Per frame (Step): local ev = P.Poll() with
--   ev.moved   the pointer moved (pointer mode on)          ev.hot / ev.changed  zone id under the pointer / it changed
--   ev.click   id clicked (mouse left button, or Accept / the free cursor's A in pointer mode) on a zone
--   ev.miss    a mouse click on no zone (do nothing; Enter / A there = the menu's key Accept, pointer mode off)
--   ev.wheel   -1 up / 1 down (CMD_EVT_WHEEL_*)
--   ev.edge    -1 / 1 from a scroll band                     ev.keys   a menu arrow was pressed (pointer mode off)
--   ev.hover   the zone under the pointer, only on a frame the pointer MOVED (or was clicked): hover by movement only,
--              so a redraw / scroll / camera move under a resting pointer never re-selects (retail behaviour)
-- P.KeyStep(): the menu moved its selection itself (its own key callbacks, a polled stick / D-pad the arrows above do
-- not see): pointer mode off and the resting position taken as the baseline, so the pad owns the selection until the
-- pointer really moves again or clicks (a resting mouse would otherwise pin the selection under it).
-- Hover = move the selection to ev.hot with the keyboard highlight; ev.click = select it and decide. The menu's own
-- Accept callbacks (OnEnter / OnDecideFocus / a polled CMD_ENTER) return early while P.Owns(): in pointer mode the
-- click belongs to the pointer, so an item not under it is never activated. Zones are only declared for pickable,
-- shown items (never hidden ones). P.Forget() after a redraw under a still pointer re-focuses the zone beneath it.
-- VRFW_Pointer.New() is the same constructor under the framework's name (every menu VM has both).
VRFW_Pointer = VRFW_Pointer or {New = function() return EVT_PointerNew() end}
EVT_PointerNew = EVT_PointerNew or function()
  local P = {zones = {}, on = false, x = nil, y = nil, hot = nil, prev = {}, edge_t = 0, REPEAT = 10}
  local MOVED, POS, GPOS, CHECK, CTRL = 3272825600, 558229292, 4002164178, 4265778440, 1332654303
  local LEFT, CLICK = 218912913 --[[CMD_EVT_MOUSE_LEFT]], 1651523701 --[[CMD_ENTER_CLICK]]
  local W_UP, W_DOWN = 1942756954 --[[CMD_EVT_WHEEL_UP]], 1623431741 --[[CMD_EVT_WHEEL_DOWN]]
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
  function P.Begin()
    P.zones = {}
  end
  function P.Rect(x, y, w, h, id, edge)
    P.zones[#P.zones + 1] = {x, y, x + w, y + h, id = id, edge = edge}
  end
  function P.Box(cx, cy, hw, hh, id, edge)
    P.zones[#P.zones + 1] = {cx - hw, cy - hh, cx + hw, cy + hh, id = id, edge = edge}
  end
  function P.Inst(layer, idx, hw, hh, id, edge)
    P.zones[#P.zones + 1] = {layer = layer, idx = idx, hw = hw, hh = hh, id = id, edge = edge}
  end
  function P.Pos()
    local x, y = M(POS)
    if type(x) == "number" and type(y) == "number" then return x, y end
    return nil
  end
  function P.At(x, y)
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
  -- the Accept being pressed now is a pointer click: the mouse button, or Accept / A in pointer mode ON an item
  -- (Enter / A with the pointer resting on empty space is a key Accept on the current selection)
  function P.Owns()
    return In(LEFT) or (P.on and In(CLICK) and P.At() ~= nil)
  end
  -- forget the hovered zone: the next Poll reports the zone under a still pointer as changed (after a redraw)
  function P.Forget()
    P.hot = nil
  end
  function P.KeyStep()
    P.on, P.hot = false, nil
    local x, y = P.Pos()
    if x ~= nil then P.x, P.y = x, y end
  end
  function P.Reset()
    P.zones, P.on, P.hot, P.prev, P.edge_t = {}, false, nil, {}, 0
    P.x, P.y = P.Pos()
    -- a press / wheel / arrow held from the screen before is no click, no scroll, no key
    for _, c in ipairs({LEFT, CLICK, W_UP, W_DOWN}) do Edge(c) end
    for _, ctrl in ipairs(CTRLS) do
      for _, c in ipairs(NAV) do Edge(c, ctrl) end
    end
  end
  function P.Poll()
    local ev = {}
    local x, y = P.Pos()
    if x ~= nil then
      local moved = M(MOVED) == true
      if not moved and P.x ~= nil and (math.abs(x - P.x) > 1 or math.abs(y - P.y) > 1) then
        moved = true    -- the free cursor (stick) moves the pointer without the mouse's «moved» flag
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
      P.on = true
    end
    local z = P.on and P.At() or nil
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
        P.on, P.hot = false, nil       -- Enter / A on empty space: the menu's key Accept takes it (selection kept)
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
