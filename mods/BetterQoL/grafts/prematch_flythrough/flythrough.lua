-- ===== EVT prematch_flythrough BEGIN =====
BetterQoL = BetterQoL or {}
BetterQoL.flythrough = BetterQoL.flythrough or {}
BetterQoL.flythrough.SHOT_S = 7.0
BetterQoL.flythrough.SHOTS = {
  2638571594 --[[evt_cam_fly_01: high side stand, tracking along the touchline]],
  72104432 --[[evt_cam_fly_02: low behind the goal, sliding sideways]],
  1934297446 --[[evt_cam_fly_03: aerial over the far goal, descending]],
  3979320517 --[[evt_cam_fly_04: corner, closing in on the centre circle]],
}
if BetterQoL.flythrough.WRAPPED == nil then
  BetterQoL.flythrough.WRAPPED = {}
end
betterqolCamFly = false                        -- fly-through running (this lua_State only)
betterqolCamShot = 0
betterqolCamT = 0
betterqolCamSet = false
function BetterQoL.flythrough.log(...)
  pcall(funcLuaCommand, @crc:CMND_VRFW_LOG@, ...)
end
function BetterQoL.flythrough.online()                 -- network match / observer: never change anything
  return funcLuaCommand(3959907440) == true or funcLuaCommand(1191545622) == true
end
function BetterQoL.flythrough.wrap(name, make)         -- wrap a global once (never a wrapper of ours twice)
  local cur = _ENV[name]
  if type(cur) ~= "function" or BetterQoL.flythrough.WRAPPED[cur] then
    return false
  end
  local w = make(cur)
  BetterQoL.flythrough.WRAPPED[w] = true
  _ENV[name] = w
  return true
end
function BetterQoL.flythrough.start()
  if #BetterQoL.flythrough.SHOTS == 0 or BetterQoL.flythrough.online() then
    return
  end
  betterqolCamFly = true
  betterqolCamShot = 0
  betterqolCamT = BetterQoL.flythrough.SHOT_S               -- the first PostStep cuts to shot 1 at once
  BetterQoL.flythrough.log("BetterQoL camera: pre-match fly-through start", "shots", #BetterQoL.flythrough.SHOTS, "seconds", BetterQoL.flythrough.SHOT_S)
end
function BetterQoL.flythrough.next()
  betterqolCamShot = betterqolCamShot % #BetterQoL.flythrough.SHOTS + 1
  betterqolCamT = 0
  local id = BetterQoL.flythrough.SHOTS[betterqolCamShot]
  local ok = funcLuaCommand(@crc:CMND_CHANGE_SOCCER_CAMERA_TYPE@, 21, 0, 0, 0, id)
  betterqolCamSet = true
  BetterQoL.flythrough.log("BetterQoL camera: shot", betterqolCamShot, id, ok)
end
function BetterQoL.flythrough.tick()
  if not betterqolCamFly then
    return
  end
  betterqolCamT = betterqolCamT + funcLuaCommand(1549797111)   -- frame delta, seconds (retail menu timers)
  if betterqolCamT >= BetterQoL.flythrough.SHOT_S then
    BetterQoL.flythrough.next()
  end
end
function BetterQoL.flythrough.stop(why)
  if not betterqolCamFly then
    return
  end
  betterqolCamFly = false
  if betterqolCamSet then
    betterqolCamSet = false
    funcLuaCommand(@crc:CMND_CHANGE_SOCCER_CAMERA_TYPE@, 0, 0, 0, 0)   -- retail chase camera
    funcLuaCommand(@crc:CMND_CAMERA_RESET@, true)
  end
  BetterQoL.flythrough.log("BetterQoL camera: fly-through stop", why)
end
BetterQoL.flythrough.wrap("SetupOpenFromBeforeSoccerStart", function(orig)
  return function(...)
    local r = orig(...)
    BetterQoL.flythrough.start()
    return r
  end
end)
BetterQoL.flythrough.wrap("CloseFormationMenu", function(orig)
  return function(...)
    local live = betterqolCamFly and IsEnableProcStateEvent()   -- the retail close returns early otherwise; keep flying then
    local r = table.pack(orig(...))
    -- The close may have turned into the opponent view.
    if live and not ((BetterUI ~= nil and BetterUI.prematch ~= nil and type(BetterUI.prematch.enemy_on) == "function") and BetterUI.prematch.enemy_on()) then
      BetterQoL.flythrough.stop("close")
    end
    return table.unpack(r, 1, r.n)
  end
end)
local BETTERQOL_Cam_PostStep_prev = PostStep
function PostStep()
  BETTERQOL_Cam_PostStep_prev()
  BetterQoL.flythrough.tick()
end
-- ===== EVT prematch_flythrough END =====
