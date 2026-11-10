-- CutinSkip: event_menu's Step asks CMND_CUTINSKIP_SKIP on a fresh press of CMD_CUTINSKIP_SKIP; never in a network
-- match, for an observer, while paused or just after the pause closes (its confirm press).
local cutin = {
  INPUT = @crc:CMND_CHECK_INPUT_CMD@,
  KEY = @crc:CMD_CUTINSKIP_SKIP@,
  CTRLS = {2917185202 --[[EVENT_CTRL_VISUAL]], 3237690481 --[[EVENT_CTRL_TALK]], 517748912 --[[EVENT_CTRL_RPG_FUNC]]},
  SKIP = @crc:CMND_CUTINSKIP_SKIP@,
  REPORT = @crc:CMND_CUTINSKIP_MENU_REPORT@,  -- (device, controller, not asked reason) -> nothing
  DEVICE_PAD = @crc:CMND_VRFW_INPUT_PAD@,     -- () -> held buttons of the game pad
  DEVICE_KEY = @crc:CMND_VRFW_INPUT_KEY@,     -- (virtual key) -> held
  PAD_CONFIRM = 0x4000,                   -- the pad's A in the held buttons
  KEY_ENTER = 0x0D,                       -- the Enter virtual key
  PAUSED = 3618071757,                    -- CMND_IS_GAME_PAUSE
  NETWORK = 3959907440,                   -- network match (the pre-match skip's test)
  OBSERVER = 1191545622,                  -- observer (the pre-match skip's test)
  DT = 2839043456,                        -- frame seconds
  LOG = 519897777,                       -- CMND_VRFW_LOG
  AFTER_PAUSE_S = 0.25,                   -- seconds after the pause closes before a press counts
  HEARTBEAT_STEPS = 60,                   -- Steps between two reports with no press
  NOT_ASKED = {paused = 1, after_pause = 2, network = 3, observer = 4},
  quiet = 0,
  ask_again = false,
  device_held = 0,
  steps = 0,
  prev_step = Step,
}

-- the index in CTRLS of the controller answering the press, or 0
function cutin.pressed()
  for index, ctrl in ipairs(cutin.CTRLS) do
    local ok, on = pcall(funcLuaCommand, cutin.INPUT, ctrl, cutin.KEY)
    if ok and on == true then
      return index
    end
  end
  return 0
end

-- a fresh press read from the devices: 1 pad A, 2 Enter, 0 none
function cutin.device_pressed()
  local ok_pad, held = pcall(funcLuaCommand, cutin.DEVICE_PAD)
  local ok_key, enter = pcall(funcLuaCommand, cutin.DEVICE_KEY, cutin.KEY_ENTER)
  local now = 0
  if ok_pad and type(held) == "number" and held > 0 and math.floor(held / cutin.PAD_CONFIRM) % 2 == 1 then
    now = 1
  elseif ok_key and enter == true then
    now = 2
  end
  local fresh = (now ~= 0 and cutin.device_held == 0) and now or 0
  cutin.device_held = now
  return fresh
end

function cutin.step()
  local not_asked = 0
  if funcLuaCommand(cutin.PAUSED) == true then
    cutin.quiet = cutin.AFTER_PAUSE_S
    not_asked = cutin.NOT_ASKED.paused
  elseif cutin.quiet > 0 then
    cutin.quiet = cutin.quiet - (funcLuaCommand(cutin.DT) or 0)
    not_asked = cutin.NOT_ASKED.after_pause
  end
  local controller = cutin.pressed()
  local device = cutin.device_pressed()
  local press = controller ~= 0 or device ~= 0
  local ask = not_asked == 0 and (cutin.ask_again or controller ~= 0)
  if ask and funcLuaCommand(cutin.NETWORK) == true then
    ask, not_asked = false, cutin.NOT_ASKED.network
  elseif ask and funcLuaCommand(cutin.OBSERVER) == true then
    ask, not_asked = false, cutin.NOT_ASKED.observer
  end
  cutin.steps = cutin.steps + 1
  if press or cutin.steps >= cutin.HEARTBEAT_STEPS then
    cutin.steps = 0
    pcall(funcLuaCommand, cutin.REPORT, device, controller, not_asked)
  end
  if not ask then
    if not_asked == cutin.NOT_ASKED.network or not_asked == cutin.NOT_ASKED.observer then
      cutin.ask_again = false
    end
    return
  end
  local ok, answer = pcall(funcLuaCommand, cutin.SKIP)
  cutin.ask_again = ok and answer == 2
end

function Step()
  local r = cutin.prev_step()
  local ok, err = pcall(cutin.step)
  if not ok then
    pcall(funcLuaCommand, cutin.LOG, "cut-in skip:", "step error", tostring(err))
  end
  return r
end
