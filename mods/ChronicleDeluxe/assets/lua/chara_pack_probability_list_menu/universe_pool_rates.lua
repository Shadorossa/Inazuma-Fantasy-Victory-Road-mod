local RATE_VALUE = 36541260               -- (layer, instance, prim, percent)
local RATE_PRIM_INDEX = 1927054058        -- (layer, instance, prim name hash) -> prim index
local RATE_PRIM = 611782757

local held = {}                           -- card -> held, while this list is open
local rates_total = nil                   -- the sum of the bucket rates shown, once the pool rule applies

local function pool()
  return ChronicleDeluxe.UniversePool
end

-- Only the rate lists leave out held cards: the cells (merged lists) must match the rows the game's list view builds itself.
local retail_list = GetStarSignCharaListData
function GetStarSignCharaListData(sign, bucket, is_last_star, merged)
  local rows = retail_list(sign, bucket, is_last_star, merged)
  if merged or not pool().active() then
    return rows
  end
  local left = {}
  for _, row in ipairs(rows) do
    if not pool().held(row[1], held) then
      left[#left + 1] = row
    end
  end
  return left
end

-- A bucket with nothing left has no rate, so the rates of the others add up to 100.
local retail_rate = GetStarSignRarityRate
function GetStarSignRarityRate(sign, bucket, is_last_star)
  local rate = retail_rate(sign, bucket, is_last_star)
  if not pool().active() then
    return rate
  end
  if rate > 0 and #GetStarSignCharaListData(sign, bucket, is_last_star, false) == 0 then
    rate = 0
  end
  rates_total = (rates_total or 0) + rate
  return rate
end

local retail_calc = CalcStarSignCharaRarityRate
function CalcStarSignCharaRarityRate(...)
  rates_total = nil
  return retail_calc(...)
end

local retail_set_rate = SetRarityRateValue
function SetRarityRateValue(layer, instance)
  if rates_total == 0 then
    funcLuaMenuCommand(RATE_VALUE, layer, instance, funcLuaMenuCommand(RATE_PRIM_INDEX, layer, instance, RATE_PRIM), 0)
    return
  end
  return retail_set_rate(layer, instance)
end

local CELL_LAYER = 1562057803             -- universe01_11_charalist_chara_icon
local SET_NODE_COLOUR = 3676296427        -- (layer, cell, node, r, g, b)
local GRAY_OUT = 643056375                -- the cell's gray_out node, dimmed by the game on a search list
local DIM, FULL = 0.5, 1
local SEARCH_LIST = 3789924989            -- the property that opens this list as a search list
local STATUS_PLATE = 1019220619           -- soccer11_04_universe_charalist_stasus
local SET_TEXT = 1083631230               -- (layer, prim, text, instance)
local SET_MESH_VISIBLE = 3405944500       -- (layer, mesh, visible, instance)
local TEXT_TITLE = 1768688116             -- _text_title01: the player's title, empty for a card from this list
local TITLE_BASE = 95052701               -- _title_name_base01
local TEXT_GET = 4074371074
local TEXT_OWNED = 2818156569             -- ChronicleDeluxe.universe_card_owned

local marks_owned = nil                   -- the one-card rule holds and this is not a search list, read once
local cell_dimmed = {}                    -- cell -> dimmed now

local function marking()
  if marks_owned == nil then
    local search = GetPropValue(SEARCH_LIST)
    marks_owned = pool().active() and (search == nil or search == 0 or search == false)
  end
  return marks_owned
end

-- A cell of a card the save holds takes the game's dimmed look.
local retail_cell = OnListViewUniverseChara_UpdateCharaIcon
function OnListViewUniverseChara_UpdateCharaIcon(cell, index)
  retail_cell(cell, index)
  if not marking() then
    return
  end
  local info = GetCharaInfo(index)
  local dim = info ~= nil and pool().held(info[1], held)
  if cell_dimmed[cell] ~= dim then
    cell_dimmed[cell] = dim
    local level = dim and DIM or FULL
    funcLuaMenuCommand(SET_NODE_COLOUR, CELL_LAYER, cell, GRAY_OUT, level, level, level)
  end
end

-- The plate of a card the save holds says so in its title line.
local retail_focus = OnListViewUniverseChara_MoveFocus
function OnListViewUniverseChara_MoveFocus(from, to, index, ...)
  retail_focus(from, to, index, ...)
  if not marking() then
    return
  end
  local info = GetCharaInfo(index)
  if info ~= nil and pool().held(info[1], held) then
    funcLuaMenuCommand(SET_TEXT, STATUS_PLATE, TEXT_TITLE, funcLuaCommand(TEXT_GET, TEXT_OWNED), 0)
    funcLuaMenuCommand(SET_MESH_VISIBLE, STATUS_PLATE, TITLE_BASE, true, 0)
  end
end
