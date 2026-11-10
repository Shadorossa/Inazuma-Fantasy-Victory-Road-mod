--@lib vrfw_prematch.lua#Head
BetterUI = BetterUI or {}
BetterUI.prematch = BetterUI.prematch or {}
BetterUI.prematch.AUTO = false                -- true: each screen advances by itself after its animations
BetterUI.prematch.AUTO_HOLD = 1.0                   -- s shown after the animations end
BetterUI.prematch.AUTO_MAX = 4.0                    -- s max wait for the animations
BetterUI.prematch.BUTTONS = true
BetterUI.prematch.LINEUP_CAM = false                -- true: fly-through camera behind the two screens
local evtPmT = 0
local evtPmAnimT = 0
function BetterUI.prematch.auto_on()
  return (VRFW.prematch ~= nil and VRFW.prematch.lineups) and BetterUI.prematch.AUTO and not VRFW.prematch.online()
end
function BetterUI.prematch.auto_reset()
  evtPmT = 0
  evtPmAnimT = 0
end
function BetterUI.prematch.anim_done(layer)
  local num = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, layer) or 1
  for i = 0, num - 1 do
    if funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, layer, i) and
        not funcLuaMenuCommand(@crc:CMND_IS_END_ANIME_TYPE@, layer, i, 71445658 --[[Open]], 0) then
      return false
    end
  end
  return true
end
function BetterUI.prematch.auto_tick(layer, what)
  if not BetterUI.prematch.auto_on() then
    return false
  end
  local dt = funcLuaCommand(1549797111) or 0
  if evtPmAnimT < BetterUI.prematch.AUTO_MAX and not BetterUI.prematch.anim_done(layer) then
    evtPmAnimT = evtPmAnimT + dt
    return false
  end
  evtPmT = evtPmT + dt
  if evtPmT >= BetterUI.prematch.AUTO_HOLD then
    VRFW.prematch.log("EVT prematch: lineup auto-advance", what, "anim wait", evtPmAnimT)
    BetterUI.prematch.auto_reset()
    return true
  end
  return false
end
BetterUI.prematch.BUTTON_ROWS = {
  MENU = 1853845420,                     -- soccer_battle_setting_flow_vs_menu (menu object of both groups)
  LEFT = 2930915263,                     -- better_ui_pm_left_button: Siguiente's layout mirrored
  NEXT = 562570935,
  NICK = 209828247,
  FORM_MENU = 2049316981,                -- soccer_formation_menu
  TEXT_NODE = 378327766,
  TEXT_EDIT = "BetterUI.prematch_edit",
  TEXT_EDIT_CRC = 858851828,
  TEXT_DATA = "BetterUI.prematch_data",
  TEXT_DATA_CRC = 536290445,
  ICON_FUNC3 = 3794706590,
  CMD_FUNC3 = 3421673595,
  FN = 4187903235,
  MENU_CTRL = 1332654303, CHECK_INPUT = @crc:CMND_CHECK_INPUT_CMD@,  -- key poll, works without the cfg rows
  SUB_KEY = 4273778482,
  OPEN_WAIT = 8.0,
}
local evtPmbGuide = false                -- left button opened on the current screen
local evtPmbReq = false                  -- button pressed, not handled yet
local evtPmbWas = true                   -- CMD_FUNC3 held (edge detection; true = wait for a release first)
local evtPmbShown = {}
function BetterUI.prematch.btn_on()
  return (VRFW.prematch ~= nil and VRFW.prematch.lineups) and BetterUI.prematch.BUTTONS and not VRFW.prematch.online()
end
function BetterUI.prematch.text(key, crc)
  local ok, id = pcall(funcLuaCommand, @crc:CMND_VRFW_TEXT_ID@, key)
  if not (ok and type(id) == "number" and id ~= 0) then
    id = crc
  end
  return funcLuaCommand(@crc:CMND_TEXT_GET@, id)
end
function BetterUI.prematch.btn_press(src)
  if BetterUI.prematch.btn_on() and evtPmbGuide and not evtPmbReq then
    evtPmbReq = true
    VRFW.prematch.log("EVT prematch: lineup button", src)
  end
end
function BetterUI.prematch.left_setup(a1, a2)
  if a1 ~= BetterUI.prematch.BUTTON_ROWS.LEFT then
    return false
  end
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, a1, a2, 1493879504 --[[offset]], 0, 1819879843)
  return true
end
function BetterUI.prematch.guide_open(isSelf)         -- opens the left button
  evtPmbGuide = true
  local label = isSelf and BetterUI.prematch.text(BetterUI.prematch.BUTTON_ROWS.TEXT_EDIT, BetterUI.prematch.BUTTON_ROWS.TEXT_EDIT_CRC)
    or BetterUI.prematch.text(BetterUI.prematch.BUTTON_ROWS.TEXT_DATA, BetterUI.prematch.BUTTON_ROWS.TEXT_DATA_CRC)
  local glyph = funcLuaCommand(@crc:CMND_TEXT_GET@, BetterUI.prematch.BUTTON_ROWS.ICON_FUNC3)
  if type(label) ~= "string" or label == "" then
    label = isSelf and "Editar" or "Datos"
  end
  if type(glyph) ~= "string" then
    glyph = "<CMD_FUNC3>"
  end
  funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, BetterUI.prematch.BUTTON_ROWS.LEFT)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, BetterUI.prematch.BUTTON_ROWS.LEFT, BetterUI.prematch.BUTTON_ROWS.TEXT_NODE, glyph .. " " .. label)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, BetterUI.prematch.BUTTON_ROWS.NEXT, true)   -- Siguiente keeps the pad focus
  VRFW.prematch.log("EVT prematch: lineup buttons", isSelf and "self: Editar + Siguiente" or "enemy: Datos + Siguiente")
end
function BetterUI.prematch.guide_close()
  if evtPmbGuide then
    evtPmbGuide = false
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, BetterUI.prematch.BUTTON_ROWS.LEFT)
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, BetterUI.prematch.BUTTON_ROWS.LEFT, false)
  end
  evtPmbReq = false
end
function BetterUI.prematch.btn_tick(isSelf)
  if not BetterUI.prematch.btn_on() then
    return false
  end
  if not evtPmbGuide then
    BetterUI.prematch.guide_open(isSelf)
  end
  local held = funcLuaCommand(BetterUI.prematch.BUTTON_ROWS.CHECK_INPUT, BetterUI.prematch.BUTTON_ROWS.MENU_CTRL, BetterUI.prematch.BUTTON_ROWS.CMD_FUNC3) == true
  if held and not evtPmbWas then
    BetterUI.prematch.btn_press("key")
  end
  evtPmbWas = held
  if evtPmbReq then
    evtPmbReq = false
    return true
  end
  return false
end
function BetterUI.prematch.reshow(isSelf)
  local again = evtPmbShown[isSelf] == true
  evtPmbShown[isSelf] = true
  return again
end
function BetterUI.prematch.sub_open(isSelf)
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3848881948 --[[sy0000]])
  BetterUI.prematch.guide_close()
  SyncCloseFormationLayers(isSelf)
  funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, BetterUI.prematch.BUTTON_ROWS.NICK, 0)
  funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, BetterUI.prematch.BUTTON_ROWS.NEXT)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, BetterUI.prematch.BUTTON_ROWS.NEXT, false)
  coroutine.yield()
  WaitSyncCloseFormationLayers(isSelf)
  local mode = isSelf and 1 or 2
  VRFW.param.set(BetterUI.prematch.BUTTON_ROWS.SUB_KEY, mode, "plain")
  funcLuaMenuCommand(@crc:CMND_OPEN_FORMATION_MENU@)
  VRFW.prematch.log("EVT prematch: editor opened from the lineup", isSelf and "edit own team" or "rival data (read-only)")
  local t = 0
  while not funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BetterUI.prematch.BUTTON_ROWS.FORM_MENU) do
    t = t + (funcLuaCommand(1549797111) or 0)
    if t > BetterUI.prematch.BUTTON_ROWS.OPEN_WAIT then
      VRFW.prematch.log("EVT prematch: editor did not open -> screen shown again")
      break
    end
    coroutine.yield()
  end
  while funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BetterUI.prematch.BUTTON_ROWS.FORM_MENU) do
    coroutine.yield()
  end
  VRFW.param.clear(BetterUI.prematch.BUTTON_ROWS.SUB_KEY)
  evtPmbWas = true
  VRFW.prematch.log("EVT prematch: editor closed -> lineup shown again", isSelf and "self" or "enemy")
end
BetterUI.prematch.CAM_SHOT_S = 7.0
BetterUI.prematch.CAM_SHOTS = {2638571594, 72104432, 1934297446, 3979320517}   -- evt_cam_fly_01..04
local evtPmCamOn = false
local evtPmCamShot = 0
local evtPmCamT = 0
function BetterUI.prematch.cam_start()
  if evtPmCamOn or not BetterUI.prematch.LINEUP_CAM or not (VRFW.prematch ~= nil and VRFW.prematch.lineups) or VRFW.prematch.online() then
    return
  end
  evtPmCamOn = true
  evtPmCamShot = 0
  evtPmCamT = BetterUI.prematch.CAM_SHOT_S
  VRFW.prematch.log("EVT prematch: lineup camera start")
end
function BetterUI.prematch.cam_tick()
  if not evtPmCamOn then
    return
  end
  evtPmCamT = evtPmCamT + (funcLuaCommand(1549797111) or 0)
  if evtPmCamT >= BetterUI.prematch.CAM_SHOT_S then
    evtPmCamT = 0
    evtPmCamShot = evtPmCamShot % #BetterUI.prematch.CAM_SHOTS + 1
    funcLuaCommand(@crc:CMND_CHANGE_SOCCER_CAMERA_TYPE@, 21, 0, 0, 0, BetterUI.prematch.CAM_SHOTS[evtPmCamShot])
  end
end
function BetterUI.prematch.cam_stop()
  if not evtPmCamOn then
    return
  end
  evtPmCamOn = false
  funcLuaCommand(@crc:CMND_CHANGE_SOCCER_CAMERA_TYPE@, 0, 0, 0, 0)
  funcLuaCommand(@crc:CMND_CAMERA_RESET@, true)
  VRFW.prematch.log("EVT prematch: lineup camera stop")
end
