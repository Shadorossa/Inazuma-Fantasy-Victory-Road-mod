-- it
BetterQoL = BetterQoL or {}
BetterQoL.camera_side = BetterQoL.camera_side or {}
BetterQoL.camera_side.OPTION = "BetterQoL.camera"
BetterQoL.camera_side.OWNER = "BetterQoL"
BetterQoL.camera_side.PRESET = "BetterQoL.side"
BetterQoL.camera_side.PRIORITY = 0
betterqolCsDone = true
betterqolCsTries = 0
betterqolCsTick = 0
function BetterQoL.camera_side.log(...)
  BetterQoL.camera_side.logger = BetterQoL.camera_side.logger or VRFW.logger.new("BetterQoL camera:")
  BetterQoL.camera_side.logger(...)
end
function BetterQoL.camera_side.done()
  betterqolCsDone = true
  local body = VRFW.host.command(@crc:CMND_GET_SOCCER_CAMERA_TYPE_INFO@, 0)
  local off = VRFW.host.command(@crc:CMND_GET_SOCCER_CAMERA_TYPE_INFO@, 1)
  BetterQoL.camera_side.log("side camera applied", "body V", tostring(body), "offence V", tostring(off),
    "tries", betterqolCsTries)
end
function BetterQoL.camera_side.init()
  betterqolCsDone = true
  -- Skips online and observer matches.
  if funcLuaCommand(3959907440) == true or funcLuaCommand(1191545622) == true then
    return
  end
  local v = VRFW.host.command(@crc:CMND_VRFW_OPTION_GET@, BetterQoL.camera_side.OPTION)
  if v ~= 1 then
    local code, mgr = VRFW.host.command(@crc:CMND_VRFW_CAMERA_RELEASE@, BetterQoL.camera_side.OWNER)
    if code == 0 then
      BetterQoL.camera_side.log("match start, Original: side camera released", "manager", tostring(mgr))
    end
    return
  end
  local code, mgr = VRFW.host.command(@crc:CMND_VRFW_CAMERA_REQUEST@, BetterQoL.camera_side.OWNER, BetterQoL.camera_side.PRESET,
    BetterQoL.camera_side.PRIORITY)
  BetterQoL.camera_side.log("match start, Lateral: request", BetterQoL.camera_side.PRESET, "code", tostring(code), "manager",
    tostring(mgr))
  if code ~= 0 then
    return
  end
  betterqolCsTries = 0
  betterqolCsTick = 0
  if mgr == true then
    BetterQoL.camera_side.done()
    return
  end
  betterqolCsDone = false
end
function BetterQoL.camera_side.try()
  local mgr = VRFW.host.command(@crc:CMND_VRFW_CAMERA_APPLY@)
  betterqolCsTries = betterqolCsTries + 1
  if mgr == true then
    BetterQoL.camera_side.done()
  elseif betterqolCsTries >= 60 then
    betterqolCsDone = true
    BetterQoL.camera_side.log("no soccer camera manager after", betterqolCsTries, "tries (the rows stay written)")
  end
end
function BetterQoL.camera_side.tick()
  if betterqolCsDone then
    return
  end
  betterqolCsTick = betterqolCsTick + 1
  if betterqolCsTick >= 30 then
    betterqolCsTick = 0
    BetterQoL.camera_side.try()
  end
end
local BETTERQOL_CamSide_OnInit_prev = OnInit
function OnInit(...)
  local r = table.pack(BETTERQOL_CamSide_OnInit_prev(...))
  BetterQoL.camera_side.init()
  return table.unpack(r, 1, r.n)
end
local BETTERQOL_CamSide_Step_prev = Step
function Step(...)
  local r = table.pack(BETTERQOL_CamSide_Step_prev(...))
  BetterQoL.camera_side.tick()
  return table.unpack(r, 1, r.n)
end
