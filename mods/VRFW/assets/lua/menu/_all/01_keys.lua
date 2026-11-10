-- Written by research/scripts/framework_pack.py from research/grafts/_lib/vrfw_menu_kit.lua section Keys.
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
