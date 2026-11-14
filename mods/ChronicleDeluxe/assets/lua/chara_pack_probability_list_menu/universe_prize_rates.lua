local PRIZE_RATES = VRFW.commands.CHRONICLEDELUXE_UNIVERSE_PRIZE_RATES
local PROP_LIST_LAST_STAR = 478309527
local VALUES_PER_ROW = 4

local RATE_WINDOW = VRFW.ids.crc32("universe01_30_rarity_rate_window")
local RATE_ROW = VRFW.ids.crc32("universe01_31_rarity_rate_item")
local RARITY_ROWS = 6                     -- the retail instances of RATE_ROW (setting count)
local RARITY_PLATE = VRFW.ids.crc32("_rarity_plate_dmy01")            -- hidden on a prize row
local RATE_PERCENT_PRIM = 3179168223      -- the rate row's number
local PRIZE_ROW = VRFW.ids.crc32("chronicle_deluxe_universe_prize_row")
local PRIZE_ROW_SCALE = 0.7
local TEXT_PRIM = VRFW.ids.crc32("_text_item01")
local ICONS = { { VRFW.ids.crc32("_icon_item_dmy01"), VRFW.ids.crc32("icon_item_dmy01") }, { VRFW.ids.crc32("_icon_item_dmy02"), VRFW.ids.crc32("icon_item_dmy02") } }  -- the two item icons and their texture nodes
local ITEM_ATLAS = 411649454              -- #/menu/103_item/item01/item01_02/<LG>/item01_02.g4tx
local ITEM_BASE, ITEM_BASE_RARE = VRFW.ids.crc32("item_base01"), VRFW.ids.crc32("item_base02")  -- the rare base is for an item of rarity 2 or more, as retail

local C = {
  IS_OPEN = VRFW.commands.IS_OPEN_LAYER, OPEN = VRFW.commands.OPEN_LAYER, CLOSE = VRFW.commands.CLOSE_LAYER, LAYER_COUNT = VRFW.commands.GET_CREATE_LAYER_NUM, GET_PRIORITY = VRFW.commands.GET_DRAW_PRIORITY,
  SET_PRIORITY = VRFW.commands.SET_DRAW_PRIORITY, SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE, MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE, PRIM_INDEX = VRFW.commands.SEARCH_PRIM_INDEX,
  RATE_VALUE = 36541260, NUMBER = 3609943765, TEXT = VRFW.commands.SET_MENU_TEXT_STRING, TEXT_GET = VRFW.commands.TEXT_GET, ITEM_PARAM = VRFW.commands.GET_ITEM_PARAM,
  ITEM_ICON = 3508889864, SPRITE = 558735651,
}

local log = type(VRFW.logger) == "table" and VRFW.logger.new("ChronicleDeluxe.UniversePrizeRates") or function() end
local last_star = 0

VRFW.host.wrap_once("OnInit", "ChronicleDeluxe.universe_prize_rates", function(retail_init, ...)
  retail_init(...)
  last_star = GetPropValue(PROP_LIST_LAST_STAR) == 1 and 1 or 0
end)

local function fill_row(index, text_id, percent, count, item)
  local rate = RARITY_ROWS + index
  funcLuaMenuCommand(C.MESH_VISIBLE, RATE_ROW, RARITY_PLATE, false, rate)
  local prim = funcLuaMenuCommand(C.PRIM_INDEX, RATE_ROW, rate, RATE_PERCENT_PRIM)
  funcLuaMenuCommand(C.RATE_VALUE, RATE_ROW, rate, prim, percent)
  local label = funcLuaCommand(C.TEXT_GET, text_id)
  if type(label) ~= "string" or label == "" then
    label = funcLuaCommand(C.ITEM_PARAM, item, 0)
  end
  funcLuaMenuCommand(C.TEXT, PRIZE_ROW, TEXT_PRIM, label, index)
  for _, icon in ipairs(ICONS) do
    funcLuaMenuCommand(C.ITEM_ICON, PRIZE_ROW, index, icon[1], icon[2], item)
  end
  local base = funcLuaCommand(C.ITEM_PARAM, item, 6) >= 2 and ITEM_BASE_RARE or ITEM_BASE
  funcLuaMenuCommand(C.SPRITE, PRIZE_ROW, ITEM_ATLAS, base, ITEM_BASE, 0, index)
  funcLuaMenuCommand(C.NUMBER, PRIZE_ROW, index, 0, count)
end

local function open_prize_rows()
  local rows = funcLuaCommand(PRIZE_RATES, last_star)
  rows = type(rows) == "table" and rows or {}
  local capacity = funcLuaMenuCommand(C.LAYER_COUNT, PRIZE_ROW)
  local priority = funcLuaMenuCommand(C.GET_PRIORITY, RATE_WINDOW, 0)
  local shown = 0
  for index = 0, capacity - 1 do
    local at = index * VALUES_PER_ROW
    if at + VALUES_PER_ROW <= #rows then
      funcLuaMenuCommand(C.SET_PRIORITY, RATE_ROW, RARITY_ROWS + index, priority + 1)
      funcLuaMenuCommand(C.SET_PRIORITY, PRIZE_ROW, index, priority + 2)
      funcLuaMenuCommand(C.OPEN, PRIZE_ROW, index)
      funcLuaMenuCommand(C.SCALE, PRIZE_ROW, PRIZE_ROW_SCALE, PRIZE_ROW_SCALE, 1, index)
      fill_row(index, rows[at + 1], rows[at + 2], rows[at + 3], rows[at + 4])
      shown = shown + 1
    else
      funcLuaMenuCommand(C.CLOSE, RATE_ROW, RARITY_ROWS + index)
    end
  end
  log("prize rows", shown, "pools", math.floor(#rows / VALUES_PER_ROW), "last star", last_star)
end

VRFW.host.wrap_once("OpenRarityRateWindow", "ChronicleDeluxe.universe_prize_rates", function(retail_open, ...)
  local was_open = funcLuaMenuCommand(C.IS_OPEN, RATE_WINDOW)
  retail_open(...)
  if not was_open then
    open_prize_rows()
  end
end)

VRFW.host.wrap_once("CloseRarityRateWindow", "ChronicleDeluxe.universe_prize_rates", function(retail_close, ...)
  local was_open = funcLuaMenuCommand(C.IS_OPEN, RATE_WINDOW)
  retail_close(...)
  if was_open then
    for index = 0, funcLuaMenuCommand(C.LAYER_COUNT, PRIZE_ROW) - 1 do
      funcLuaMenuCommand(C.CLOSE, PRIZE_ROW, index)
    end
  end
end)
