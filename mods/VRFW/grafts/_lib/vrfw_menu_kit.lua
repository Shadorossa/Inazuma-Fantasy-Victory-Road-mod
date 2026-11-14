--@section Call --- Advanced: Runs funcLuaCommand(cmd, ...) under pcall; answers its results, or nil when it failed.
local function Call(cmd, ...)
  local r = table.pack(pcall(funcLuaCommand, cmd, ...))
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2, r.n)
end
--@section Int --- Advanced: Rounds v to the nearest integer; answers 0 when v is not a number.
local function Int(v)
  if type(v) ~= "number" then
    return 0
  end
  return math.floor(v + 0.5)
end
--@section Pct --- Advanced: n as a percentage of total, as text with at most one decimal; "0" when total is not positive.
local function Pct(n, total)
  if total <= 0 then
    return "0"
  end
  return (string.format("%.1f", n * 100 / total):gsub("%.", ","))
end
--@section Ask --- Advanced: Asks a yes / no question with this menu's input off; answers true for yes.
local function Ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  local yes = VRFW.question.ask(text)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  return yes
end
--@section Message --- Advanced: Shows an OK window with this menu's input off; `button` is its button text.
local function Message(text, button)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  VRFW.question.notice(text, {button = button})
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
end
--@section ItemGet --- Advanced: Shows the game's item-obtained window for item `id` with this menu's input off.
local function ItemGet(id)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  VRFW.question.item_get(id)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
end
--@section Close --- Advanced: Stores `result` in the result parameter and closes this menu.
local function Close(result)
  VRFW.param.replace(KEY_RESULT, result)
  funcLuaMenuCommand(C.MENU_ACTIVE, MENU, false)
  funcLuaCommand(C.CLOSE_MENU, MENU)
end
--@section StartCo --- Advanced: Starts fn(arg) as this screen's coroutine, unless one is already running.
local function StartCo(fn, arg)
  if vrfw_co ~= nil then
    return
  end
  vrfw_co = coroutine.create(fn)
  local ok, err = coroutine.resume(vrfw_co, arg)
  if not ok then
    PRINT("@MENU_FILE@: " .. tostring(err))
    Log("error", tostring(err))
    vrfw_co = nil
    funcLuaMenuCommand(C.MENU_ACTIVE, MENU, true)
  elseif coroutine.status(vrfw_co) == "dead" then
    vrfw_co = nil
  end
end
--@section Pack --- Advanced: Packs the arguments; answers {n = count, ...}.
local function Pack(...)
  return {n = select("#", ...), ...}
end
--@section ParamPerMille --- Advanced: Stores `rate` (0..1) in parameter `key` as a per-mille integer.
local function SetParamPerMille(key, rate)
  VRFW.param.replace(key, math.floor(math.max(0, math.min(1, rate)) * 1000 + 0.5), "plain")
end
--@section Cmd --- Advanced: Runs funcLuaMenuCommand(...) under pcall; answers its results, or nil when it failed.
local function Cmd(...)
  if type(funcLuaMenuCommand) ~= "function" then
    return nil
  end
  local r = Pack(pcall(funcLuaMenuCommand, ...))
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2, r.n)
end
--@section call --- Advanced: Runs funcLuaCommand(cmd, ...) under pcall; answers its results, or nil when it failed.
local function call(cmd, ...)
  local r = table.pack(pcall(funcLuaCommand, cmd, ...))
  if not r[1] then
    return nil
  end
  return table.unpack(r, 2, r.n)
end
--@section U32 --- Advanced: Normalises id to an unsigned 32-bit number; 0 when it is not a number.
local function to_u32(id)
  id = tonumber(id) or 0
  if id < 0 then
    id = id + 4294967296
  end
  return id
end
--@section Pointer --- Advanced: Mouse pointer hit-zone tracker for menus.
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
--@section Keys --- Advanced: Menu key constants and press tracking.
--- Advanced: Constants: command hashes of the menu keys, plus held(cmd, ctrl) and new_press().
VRFW.keys = VRFW.keys or (function()
  local K = {
    UP = 1197218715, DOWN = 3259546669, LEFT = 2765147006, RIGHT = 2075023265,   -- CMD_UP / DOWN / LEFT / RIGHT
    ENTER = 1981080283,          -- CMD_ENTER: Enter, A
    ENTER_CLICK = 1651523701,    -- CMD_ENTER_CLICK: the mouse's left button, Enter, A
    BACK = 3011112225,           -- CMD_BACK
    CANCEL = 3602695835,         -- CMD_CANCEL: Esc, B
    FUNC3 = 3421673595, FUNC4 = 1435897304,                    -- CMD_FUNC3 / CMD_FUNC4
    L1 = 3966226594, R1 = 942075773, L2 = 1970176280, R2 = 2704260807,   -- CMD_FUNCL1 / R1 / L2 / R2
    MOUSE_LEFT = 749879980,      -- CMD_VRFW_MOUSE_LEFT: the mouse's left button alone
    MOUSE_RIGHT_CLICK = 3473063670,                            -- CMD_MOUSE_RIGHT_CLICK
    WHEEL_UP = 2649361876, WHEEL_DOWN = 1098743808,            -- CMD_VRFW_WHEEL_UP / _DOWN
    MENU_CTRL = 1332654303,      -- the menu control
    MENU_CTRL_ANALOG = 2748927068,   -- MENU_CTRL_WITH_ANALOG_MOVE_FOCUS: the stick's menu moves
    CHECK_INPUT = 4265778440,    -- CMND_CHECK_INPUT_CMD (control, command) -> true while held
  }
  K.CONTROLS = {K.MENU_CTRL, K.MENU_CTRL_ANALOG}
  --- True when input cmd is held; with ctrl, on that controller only.
  function K.held(cmd, ctrl)
    if ctrl ~= nil then
      local ok, r = pcall(funcLuaCommand, K.CHECK_INPUT, ctrl, cmd)
      return ok and r == true
    end
    for _, c in ipairs(K.CONTROLS) do
      local ok, r = pcall(funcLuaCommand, K.CHECK_INPUT, c, cmd)
      if ok and r == true then
        return true
      end
    end
    return false
  end
  --- A press tracker; answers a table with pressed(cmd, ctrl) and reset().
  function K.new_press()
    local held = {}
    local T = {}
    --- True on the frame cmd goes down, once per press.
    function T.pressed(cmd, ctrl)
      local key = tostring(ctrl or "any") .. ":" .. tostring(cmd)
      local now = K.held(cmd, ctrl)
      local was = held[key]
      held[key] = now
      return now and not was
    end
    --- Treats every key as already held, so a key still down after a reset is no press.
    function T.reset()
      held = setmetatable({}, {__index = function() return true end})
    end
    return T
  end
  return K
end)()
--@section CharaModel --- Advanced: 3D character model preview on a menu layer.
--- Advanced: Namespace: 3D character model preview helper for menus; holds new().
VRFW.chara_model = VRFW.chara_model or {}
--- Advanced: Creates a character model preview (layer, opts); answers a table with show(pid), show_chara(chara, motion), hide, release, ok and step.
VRFW.chara_model.new = VRFW.chara_model.new or function(layer, opts)
  opts = opts or {}
  local M = {pid = nil, chara = nil, pend = nil, build = nil, hide_build = false, logs = 0, failed = false,
    SHADOW = opts.shadow or 858725131 --[[mainmenu01_08_chara_3d_shadow]], POSE = opts.pose or 2328706751,
    SETTLE = opts.settle or 2, MIN = opts.min or 6, MAX = opts.max or 120, SLOT = opts.slot or 0}
  M.KEY = opts.key or M.SLOT
  local FREE_FRAMES = opts.free_frames or 2
  local function MC(cmd, ...)
    local ok, a, b = pcall(funcLuaMenuCommand, cmd, ...)
    if ok then return a, b end
    return nil
  end
  local function Log(...)
    if opts.log ~= nil and M.logs < 12 then
      M.logs = M.logs + 1
      pcall(opts.log, "model", ...)
    end
  end
  local function Visible(on)
    local h = MC(3895705890, layer, 0, M.SLOT)
    if type(h) == "number" and h ~= 0 then
      pcall(funcLuaCommand, 1890282463, h, on)
    end
  end
  local function Ready()
    return MC(1583438030, layer, 0, M.SLOT) == true
  end
  local function Loading(chara)
    local ok, l = pcall(funcLuaCommand, 2475005551, chara)
    return ok and l == true
  end
  local function BuildDone()
    return M.build == nil or M.build.done
  end
  -- Returns the character's body type, as retail shop_menu_buy passes it to SetupCharaModel.
  local function BodyType(chara)
    local ok, has, v = pcall(funcLuaCommand, 4060384944 --[[CMND_GET_CHARA_INFO]], chara, 3, 0)
    if ok and has == true and type(v) == "number" then
      return v
    end
    return 0
  end
  local function Setup(chara, pid, motion, n, uniform, flags)
    MC(59611540, layer, 0, chara, M.SLOT)
    MC(186863317 --[[CMND_SET_SCN_CHARA_REGIST_TYPE]], layer, 0, 4, M.SLOT)
    MC(3290636356, layer, 0, uniform, motion, flags, M.SLOT)
    MC(4219344099 --[[CMND_SET_CHARA_MODEL_SHADOW?]], layer, 0, M.SHADOW, M.SLOT, M.SLOT)
    MC(2232914067 --[[CMND_CHARA_MODEL_CHANGE]], layer, 0, 0, 9, M.SLOT, M.KEY)
    if opts.bodies ~= nil and opts.bodies[n] then   -- only a body type the pose lists (see CRASH GUARD above)
      MC(2450020144, layer, 0, M.POSE, n, M.SLOT)
    end
  end
  local function BuildStep()
    local B = M.build
    if B == nil or B.done then
      return
    end
    B.n = B.n + 1
    if not Ready() then
      B.seen, B.ok = true, 0
    elseif B.seen or B.n >= M.MIN then
      B.ok = B.ok + 1
    end
    if B.ok >= M.SETTLE or B.n >= M.MAX then
      B.done = true
      if not B.seen and B.ok < M.SETTLE then
        M.failed = true
      end
      Log("ready", B.n, tostring(B.seen), tostring(B.ok >= M.SETTLE))
    end
  end
  local function PendStep()
    local P = M.pend
    if P == nil then
      if M.hide_build then
        Visible(false)
        M.hide_build = not BuildDone()
      end
      return
    end
    M.hide_build = false
    P.n = P.n + 1
    if not P.built then
      if P.n < M.MAX and (not BuildDone() or Loading(P.chara)) then
        Visible(false)
        return
      end
      local ok, err = pcall(Setup, P.chara, P.pid, P.motion, P.body, P.uniform, P.flags)
      Visible(false)
      P.built, P.n = true, 0
      M.build = {n = 0, seen = false, ok = 0, done = false}
      M.pid, M.chara, M.clip = P.pid, P.chara, P.clip
      Log("build", P.pid, P.chara, P.motion, string.format("uniform 0x%08X flags %d", P.uniform, P.flags), tostring(ok),
        tostring(err))
      return
    end
    if not BuildDone() then
      Visible(false)
      return
    end
    Visible(true)
    if M.clip ~= nil then
      MC(180466856, layer, 0, M.clip, 0, 0, 0, 0, M.SLOT)   -- Plays the model's stand clip, as retail shop_menu_buy does.
    end
    M.pend = nil
    Log("shown", P.pid, P.n)
  end
  --- True while the model view has not failed.
  function M.ok()
    return not M.failed
  end
  --- Hides the model and cancels a pending show.
  function M.hide()
    M.pend = nil
    M.hide_build = not BuildDone()
    if M.pid ~= nil then
      Visible(false)
    end
  end
  -- a build or a model load of this slot still under way (retail SetupCharaModel never changes a model mid-load)
  local function Busy()
    return not BuildDone() or (M.chara ~= nil and Loading(M.chara))
  end
  -- Hides the model and frees the slot.
  local function Free()
    Visible(false)
    MC(59611540, layer, 0, 0, M.SLOT)
    -- Clears the slot's own model key.
    MC(2232914067 --[[CMND_CHARA_MODEL_CHANGE]], layer, 0, 0, 9, M.SLOT, M.KEY)
    Log("released", M.pid)
    M.pid, M.chara, M.build, M.release_wanted = nil, nil, nil, false
    M.free_frames = FREE_FRAMES
  end
  --- Releases the slot's model, like retail shop ResetCharaModel.
  function M.release()
    M.pend, M.hide_build = nil, false
    if M.pid == nil then
      M.release_wanted = false
      return
    end
    if Busy() then
      Visible(false)
      if not M.release_wanted then
        M.release_wanted = true
        Log("release waits for the load", M.pid)
      end
      return
    end
    Free()
  end
  --- Returns true once nothing is held.
  function M.released()
    return M.pid == nil and not M.release_wanted and (M.free_frames or 0) <= 0
  end
  --- Shows player param pid in the model view, building it when needed.
  function M.show(pid)
    M.release_wanted = false
    local P = M.pend
    if P ~= nil and P.pid == pid then
      return
    end
    if P == nil and M.pid == pid then
      if BuildDone() then
        Visible(true)
      else
        M.pend = {pid = pid, chara = M.chara, n = 0, built = true}
      end
      return
    end
    local ok, chara = pcall(funcLuaCommand, 347353059 --[[chara of chara_param]], pid)
    if not ok or type(chara) ~= "number" or chara == 0 then
      Log("none", pid)
      M.hide()
      return
    end
    local motion = 1
    local ok2, has, v = pcall(funcLuaCommand, 4060384944 --[[CMND_GET_CHARA_INFO]], pid, 21)
    if ok2 and has == true and type(v) == "number" and v ~= 0 then
      motion = v
    end
    local body = BodyType(chara)
    if opts.bodies == nil or not opts.bodies[body] then
      Log("skip body", pid, chara, body, tostring(opts.bodies ~= nil))
      M.hide()
      return
    end
    -- Reads the uniform and look options of the kit.
    local uniform, flags = opts.uniform or 0, opts.look or 0
    if opts.kit ~= nil then
      local okk, u, f = pcall(opts.kit, pid)
      if okk and type(u) == "number" and u ~= 0 then
        uniform = u
      end
      if okk and type(f) == "number" then
        for _, bit in ipairs({2, 16, 32}) do
          if math.floor(f / bit) % 2 == 1 and math.floor(flags / bit) % 2 == 0 then
            flags = flags + bit
          end
        end
      end
    end
    Visible(false)
    M.pend = {pid = pid, chara = chara, motion = motion, body = body, uniform = uniform, flags = flags, n = 0,
      built = false}
    PendStep()
  end
  --- Shows character id chara itself, for a model of its own (a spirit, a prop): no kit, no pose; motion = its stand clip or nil.
  function M.show_chara(chara, motion)
    M.release_wanted = false
    if type(chara) ~= "number" or chara == 0 then
      M.hide()
      return
    end
    local P = M.pend
    if P ~= nil and P.pid == chara then
      return
    end
    if P == nil and M.pid == chara then
      if BuildDone() then
        Visible(true)
      else
        M.pend = {pid = chara, chara = M.chara, n = 0, built = true}
      end
      return
    end
    Visible(false)
    M.pend = {pid = chara, chara = chara, motion = 1, body = -1, uniform = 0, flags = 0, clip = motion, n = 0,
      built = false}
    PendStep()
  end
  --- One frame of the model view: advances the build and a pending release.
  function M.step()
    BuildStep()
    if M.release_wanted then
      Visible(false)
      if not Busy() then
        Free()
      end
      return
    end
    if (M.free_frames or 0) > 0 then
      M.free_frames = M.free_frames - 1
    end
    PendStep()
  end
  return M
end
