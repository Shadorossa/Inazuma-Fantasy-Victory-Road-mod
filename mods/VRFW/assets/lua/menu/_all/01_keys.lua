-- Written by research/scripts/framework_pack.py from research/grafts/_lib/evt_menu_kit.lua section Keys.
-- VRFW_Keys: the engine's menu input commands by name (CMND_CHECK_INPUT_CMD ids), the two menu controls that report
-- them, and a press tracker. Every menu VM has it (framework_pack.py writes this section into VRFW _all); a graft that
-- needs it while its chunk loads includes `--@lib evt_menu_kit.lua#Keys` above that use.
--   VRFW_Keys.UP / DOWN / LEFT / RIGHT / ENTER / BACK / ...   the command ids
--   VRFW_Keys.Held(cmd[, ctrl])   true while cmd is held (on ctrl, else on either menu control)
--   local press = VRFW_Keys.NewPress()   press.Pressed(cmd[, ctrl]) true on the frame cmd goes down;
--                                        press.Reset() takes the keys held now as already pressed (a screen's open)
VRFW_Keys = VRFW_Keys or (function()
  local K = {
    UP = 1197218715, DOWN = 3259546669, LEFT = 2765147006, RIGHT = 2075023265,   -- CMD_UP / DOWN / LEFT / RIGHT
    ENTER = 1981080283,          -- CMD_ENTER: Enter, A
    ENTER_CLICK = 1651523701,    -- CMD_ENTER_CLICK: the mouse's left button, Enter, A
    BACK = 3011112225,           -- CMD_BACK
    CANCEL = 3602695835,         -- CMD_CANCEL: Esc, B
    FUNC3 = 3421673595, FUNC4 = 1435897304,                    -- CMD_FUNC3 / CMD_FUNC4
    L1 = 3966226594, R1 = 942075773, L2 = 1970176280, R2 = 2704260807,   -- CMD_FUNCL1 / R1 / L2 / R2
    MOUSE_LEFT = 218912913,      -- CMD_EVT_MOUSE_LEFT: the mouse's left button alone
    MOUSE_RIGHT_CLICK = 3473063670,                            -- CMD_MOUSE_RIGHT_CLICK
    WHEEL_UP = 1942756954, WHEEL_DOWN = 1623431741,            -- CMD_EVT_WHEEL_UP / _DOWN
    MENU_CTRL = 1332654303,      -- the menu control
    MENU_CTRL_ANALOG = 2748927068,   -- MENU_CTRL_WITH_ANALOG_MOVE_FOCUS: the stick's menu moves
    CHECK_INPUT = 4265778440,    -- CMND_CHECK_INPUT_CMD (control, command) -> true while held
  }
  K.CONTROLS = {K.MENU_CTRL, K.MENU_CTRL_ANALOG}
  function K.Held(cmd, ctrl)
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
  function K.NewPress()
    local held = {}
    local T = {}
    function T.Pressed(cmd, ctrl)
      local key = tostring(ctrl or "any") .. ":" .. tostring(cmd)
      local now = K.Held(cmd, ctrl)
      local was = held[key]
      held[key] = now
      return now and not was
    end
    function T.Reset()
      -- every key counts as held until it is read up once: a press carried over from before is no press
      held = setmetatable({}, {__index = function() return true end})
    end
    return T
  end
  return K
end)()
