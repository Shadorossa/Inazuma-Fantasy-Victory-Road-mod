local PRIZE_RATES = 2720253709
local PROP_LIST_LAST_STAR = 478309527
local VALUES_PER_ROW = 4

local RATE_WINDOW = 795374569             -- universe01_30_rarity_rate_window
local RATE_ROW = 3591108357
local RARITY_ROWS = 6                     -- the retail instances of RATE_ROW (setting count)
local RARITY_PLATE = 286154265            -- _rarity_plate_dmy01: hidden on a prize row
local RATE_PERCENT_PRIM = 3179168223      -- the rate row's number
local PRIZE_ROW = 2524577816
local PRIZE_ROW_SCALE = 0.7
local TEXT_PRIM = 456522680               -- _text_item01
local ICONS = { { 303536660, 1875672568 }, { 2334051246, 4140117058 } }  -- _icon_item_dmy01 / 02 and their texture nodes
local ITEM_ATLAS = 411649454              -- #/menu/103_item/item01/item01_02/<LG>/item01_02.g4tx
local ITEM_BASE, ITEM_BASE_RARE = 1868240048, 4132586762  -- item_base01 / 02 (an item of rarity 2 or more, as retail)

local C = {
  IS_OPEN = 2640875187, OPEN = 629267548, CLOSE = 1273612389, LAYER_COUNT = 1175615627, GET_PRIORITY = 1018283794,
  SET_PRIORITY = 1491630496, SCALE = 3778714801, MESH_VISIBLE = 3405944500, PRIM_INDEX = 1927054058,
  RATE_VALUE = 36541260, NUMBER = 3609943765, TEXT = 1083631230, TEXT_GET = 4074371074, ITEM_PARAM = 1883585771,
  ITEM_ICON = 3508889864, SPRITE = 558735651,
}

local log = type(VRFW.logger) == "table" and VRFW.logger.new("ChronicleDeluxe.UniversePrizeRates") or function() end
local last_star = 0

local retail_init = OnInit
function OnInit(...)
  retail_init(...)
  last_star = GetPropValue(PROP_LIST_LAST_STAR) == 1 and 1 or 0
end

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

local retail_open = OpenRarityRateWindow
function OpenRarityRateWindow(...)
  local was_open = funcLuaMenuCommand(C.IS_OPEN, RATE_WINDOW)
  retail_open(...)
  if not was_open then
    open_prize_rows()
  end
end

local retail_close = CloseRarityRateWindow
function CloseRarityRateWindow(...)
  local was_open = funcLuaMenuCommand(C.IS_OPEN, RATE_WINDOW)
  retail_close(...)
  if was_open then
    for index = 0, funcLuaMenuCommand(C.LAYER_COUNT, PRIZE_ROW) - 1 do
      funcLuaMenuCommand(C.CLOSE, PRIZE_ROW, index)
    end
  end
end
