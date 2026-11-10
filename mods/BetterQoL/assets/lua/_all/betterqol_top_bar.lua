BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.top_bar = type(BetterQoL.top_bar) == "table" and BetterQoL.top_bar or {}
local TB = BetterQoL.top_bar

function BetterQoL.top_bar_on()
  return true
end

TB.BOARD_MENUS = {"vs_route_town_menu", "vs_route_town_menu_future", "vs_route_town_menu_future_clear",
  "vs_route_town_menu_victory"}

function BetterQoL.top_bar_on_board()
  if type(CRC32) ~= "function" then
    return false
  end
  for _, m in ipairs(TB.BOARD_MENUS) do
    local r = VRFW.host.menu_command(VRFW.commands.IS_EXIST_MENU_OBJECT, CRC32(m))
    if r == true then
      return true
    end
  end
  return false
end

TB.HINT = {
  LAYER = 4218549498 --[[vrfw_topbar_hint]], NODE = 378327766 --[[_text_cmd_back01]],
  MESHES = {298211823 --[[_cmd_back_base01]], 2853207670 --[[_cmd_back_base01_add]]},
  TEXT = 2850170714 --[[crc32 betterqol_topbar_open]], FALLBACK = "<CMD_VRFW_TOPBAR_OPEN>",
  BOX_LEFT = -384, BOX_MID_Y = 144, HALF = 17, SCALE = 1.0,
}

function VRFW.top_bar_hint(menu, x, y, on)
  local H = TB.HINT
  local n = funcLuaMenuCommand(VRFW.commands.GET_CREATE_LAYER_NUM, H.LAYER)
  if type(n) ~= "number" or n <= 0 then
    return
  end
  if not on then
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, H.LAYER, 0, false)
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_POS, H.LAYER, -4000, 4000, 0, 0)
    return
  end
  local s = funcLuaCommand(VRFW.commands.TEXT_GET, H.TEXT)
  if type(s) ~= "string" or s == "" then
    s = H.FALLBACK
  end
  for _, m in ipairs(H.MESHES) do
    funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, H.LAYER, m, false, 0)
  end
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, H.LAYER, H.NODE, s, 0)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_SCALE, H.LAYER, H.SCALE, H.SCALE, 1, 0)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_POS, H.LAYER,
    x - H.HALF - H.BOX_LEFT * H.SCALE, -y - H.BOX_MID_Y * H.SCALE, 0, 0)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, H.LAYER, 0, true)
end

TB.DROP = {
  LAYER = 3950785521 --[[vrfw_topbar_drop_label]], NODE = 378327766 --[[_text_cmd_back01]],
  MESHES = {298211823 --[[_cmd_back_base01]], 2853207670 --[[_cmd_back_base01_add]]},
  BOX_LEFT = -384, BOX_MID_Y = 144, SCALE = 1.0,
  TEXT_SIZE = 3549540977 --[[CMND_GET_MENU_TEXT_RECT_SIZE (layer, idx, node, string) -> w, h]],
}

function BetterQoL_TopBarDropLabelWidth(menu, text)
  local D = TB.DROP
  local n = funcLuaMenuCommand(VRFW.commands.GET_CREATE_LAYER_NUM, D.LAYER)
  if type(n) ~= "number" or n < 1 or type(text) ~= "string" then return nil end
  local w = VRFW.host.menu_command(D.TEXT_SIZE, D.LAYER, 0, D.NODE, text)
  if type(w) == "number" and w > 0 then return w * D.SCALE end
  return nil
end

function VRFW.top_bar_drop_label(menu, i, text, x, y, on, sel, maxw)
  local D = TB.DROP
  local n = funcLuaMenuCommand(VRFW.commands.GET_CREATE_LAYER_NUM, D.LAYER)
  if type(n) ~= "number" or i < 1 or i > n then
    return
  end
  local idx = i - 1
  if not on or type(text) ~= "string" then
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, D.LAYER, idx, false)
    funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_POS, D.LAYER, -4000, 4000, 0, idx)
    return
  end
  for _, m in ipairs(D.MESHES) do
    funcLuaMenuCommand(VRFW.commands.SET_MESH_VISIBLE, D.LAYER, m, false, idx)
  end
  funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, D.LAYER, D.NODE, text, idx)
  local s = D.SCALE
  if type(maxw) == "number" and maxw > 0 then
    local w = BetterQoL_TopBarDropLabelWidth(menu, text)
    if w ~= nil and w > maxw then s = D.SCALE * maxw / w end
  end
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_SCALE, D.LAYER, s, s, 1, idx)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_LOCAL_POS, D.LAYER,
    x - D.BOX_LEFT * s, -y - D.BOX_MID_Y * s, 0, idx)
  funcLuaMenuCommand(VRFW.commands.SET_LAYER_VISIBLE, D.LAYER, idx, true)
end

TB.RANK_HIDE_WITH = {2279382105 --[[mainmenu90_31_doc_item]]}

function VRFW.top_bar_rank_hide(menu)
  for _, layer in ipairs(TB.RANK_HIDE_WITH) do
    local r = VRFW.host.command(VRFW.commands.IS_OPEN_MENU_OBJECT, menu, layer)
    if r ~= nil and r ~= false and r ~= 0 then
      local v = VRFW.host.menu_command(VRFW.commands.IS_LAYER_VISIBLE, layer, 0)
      if v == true then
        return true
      end
    end
  end
  return false
end
