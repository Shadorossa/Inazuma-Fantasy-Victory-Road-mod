
if type(OnOpenSoccerConstantMenuLayer) == "function" then
  local LAYER_NAME = "stoppage_time_telop"
  local COMMAND = "CMND_STOPPAGETIME_TELOP"
  local C = {
    IS_OPEN = 2640875187 --[[CMND_IS_OPEN_LAYER]], POS = 1389957207 --[[CMND_SET_LAYER_LOCAL_POS]],
    SCALE = 3778714801 --[[CMND_SET_LAYER_LOCAL_SCALE]], SET_TEXT = 1083631230 --[[CMND_SET_MENU_TEXT_STRING]],
    TEXT_STYLE = 2333948100 --[[the text node's font style]], TEXT_SIZE = 3549540977 --[[CMND_GET_MENU_TEXT_RECT_SIZE]],
  }
  local TEXT = { NODE = "_text_btn01", BOX_LEFT = -32, BOX_MID_Y = 0, STYLE = "fs2_26_w_lc_2d2_001_nr", STYLE_HEIGHT = 26 }
  local CHAR_WIDTH = 0.55

  local function crc(text)
    return VRFW.ids.crc32(text)
  end

  local function place(layer)
    local text, center_x, middle_y, height = VRFW.host.command(crc(COMMAND))
    if type(text) ~= "string" then text = "" end
    local node = crc(TEXT.NODE)
    if text == "" then
      VRFW.host.menu_command(C.SET_TEXT, layer, node, "", 0)
      return
    end
    local scale = (tonumber(height) or TEXT.STYLE_HEIGHT) / TEXT.STYLE_HEIGHT
    VRFW.host.menu_command(C.TEXT_STYLE, layer, 0, node, crc(TEXT.STYLE))
    VRFW.host.menu_command(C.SCALE, layer, 1, 1, 1, 0)
    local width = VRFW.host.menu_command(C.TEXT_SIZE, layer, 0, node, text)
    if type(width) ~= "number" or width <= 1 or width > 4000 then
      width = #text * CHAR_WIDTH * TEXT.STYLE_HEIGHT
    end
    local left = (tonumber(center_x) or 960) - width * scale / 2
    VRFW.host.menu_command(C.SET_TEXT, layer, node, text, 0)
    VRFW.host.menu_command(C.SCALE, layer, scale, scale, 1, 0)
    VRFW.host.menu_command(C.POS, layer, left - TEXT.BOX_LEFT * scale, -(tonumber(middle_y) or 148) - TEXT.BOX_MID_Y * scale, 0, 0)
  end

  local game_open_layer = OnOpenSoccerConstantMenuLayer
  OnOpenSoccerConstantMenuLayer = function(layer, index, ...)
    if layer == crc(LAYER_NAME) then pcall(place, layer) end
    return game_open_layer(layer, index, ...)
  end

  -- the text changed (the half's regular end, the half's end).
  StoppageTime_TelopRefresh = function()
    local layer = crc(LAYER_NAME)
    if VRFW.host.menu_command(C.IS_OPEN, layer, 0) == true then pcall(place, layer) end
  end
end
