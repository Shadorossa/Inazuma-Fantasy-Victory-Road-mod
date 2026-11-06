-- Stoppage Time: the «+N» under the scoreboard's clock (plain Lua 5.2, runs in every script VM, acts in the scripts of
-- the match HUD: the include's OnOpenSoccerConstantMenuLayer, called by soccer_constant_menu and soccer_battle_constant_menu).
-- The text is layer stoppage_time_telop of the scoreboard's screen (content\menus\stoppage_time_telop.toml): the game
-- opens and closes it with the scoreboard and plays the same 10-frame fade, so this file never shows or hides anything.
-- It writes the text from CMND_STOPPAGETIME_TELOP when the layer opens and when scripts\stoppage_time.lua calls
-- StoppageTime_TelopRefresh; an empty text draws nothing. No frame work, no engine call at load time.

if type(OnOpenSoccerConstantMenuLayer) == "function" then
  local LAYER_NAME = "stoppage_time_telop"
  local COMMAND = "CMND_STOPPAGETIME_TELOP"
  local C = {
    IS_OPEN = 2640875187 --[[CMND_IS_OPEN_LAYER]], POS = 1389957207 --[[CMND_SET_LAYER_LOCAL_POS]],
    SCALE = 3778714801 --[[CMND_SET_LAYER_LOCAL_SCALE]], SET_TEXT = 1083631230 --[[CMND_SET_MENU_TEXT_STRING]],
    TEXT_STYLE = 2333948100 --[[the text node's font style]], TEXT_SIZE = 3549540977 --[[CMND_GET_MENU_TEXT_RECT_SIZE]],
  }
  -- soccer00_81 (a retail text of the match HUD): its text node, the node's box at scale 1, the font style and its height
  local TEXT = { NODE = "_text_btn01", BOX_LEFT = -32, BOX_MID_Y = 0, STYLE = "fs2_26_w_lc_2d2_001_nr", STYLE_HEIGHT = 26 }
  local CHAR_WIDTH = 0.55   -- a character's width per text height when the game does not answer the text's size

  local function crc(text)
    return VRFW_Id.Crc(text)
  end

  local function menu_command(command, ...)
    local ok, answer = pcall(funcLuaMenuCommand, command, ...)
    if ok then return answer end
    return nil
  end

  local function place(layer)
    local ok, text, center_x, middle_y, height = pcall(funcLuaCommand, crc(COMMAND))
    if not ok or type(text) ~= "string" then text = "" end
    local node = crc(TEXT.NODE)
    if text == "" then
      menu_command(C.SET_TEXT, layer, node, "", 0)
      return
    end
    local scale = (tonumber(height) or TEXT.STYLE_HEIGHT) / TEXT.STYLE_HEIGHT
    menu_command(C.TEXT_STYLE, layer, 0, node, crc(TEXT.STYLE))
    menu_command(C.SCALE, layer, 1, 1, 1, 0)
    local width = menu_command(C.TEXT_SIZE, layer, 0, node, text)
    if type(width) ~= "number" or width <= 1 or width > 4000 then
      width = #text * CHAR_WIDTH * TEXT.STYLE_HEIGHT
    end
    local left = (tonumber(center_x) or 960) - width * scale / 2
    menu_command(C.SET_TEXT, layer, node, text, 0)
    menu_command(C.SCALE, layer, scale, scale, 1, 0)
    menu_command(C.POS, layer, left - TEXT.BOX_LEFT * scale, -(tonumber(middle_y) or 148) - TEXT.BOX_MID_Y * scale, 0, 0)
  end

  local game_open_layer = OnOpenSoccerConstantMenuLayer
  OnOpenSoccerConstantMenuLayer = function(layer, index, ...)
    if layer == crc(LAYER_NAME) then pcall(place, layer) end
    return game_open_layer(layer, index, ...)
  end

  -- the text changed (the half's regular end, the half's end). A closed layer is written when it opens.
  StoppageTime_TelopRefresh = function()
    local layer = crc(LAYER_NAME)
    if menu_command(C.IS_OPEN, layer, 0) == true then pcall(place, layer) end
  end
end
