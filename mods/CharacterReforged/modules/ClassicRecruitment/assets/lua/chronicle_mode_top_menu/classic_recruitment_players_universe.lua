local MIDDLE_LIST = 4042532538            -- mainmenu90_11_chronicle_top_list_item_middle
local SMALL_LIST = 530619243              -- mainmenu90_12_list_item_small
local BOX_LAYER = 3085812933
local UNIVERSE_MENU = 2357301264          -- players_universe_menu
local GET_LOCAL_POS = VRFW.commands.GET_LAYER_LOCAL_POS          -- (layer, instance) -> x, y, z
local SET_LOCAL_POS = VRFW.commands.SET_LAYER_LOCAL_POS          -- (layer, x, y, z, instance)
local ROW_PITCH = 108                     -- layout px between the two big rows

local function removed()
  return type(ClassicRecruitment) == "table" and type(ClassicRecruitment.gacha_removed) == "function"
    and ClassicRecruitment.holds(ClassicRecruitment.gacha_removed)
end

local function is_universe_row(layer, index)
  local ok, info = pcall(GetLitItemInfo, layer, index)
  return ok and type(info) == "table" and info.menuObjectName == UNIVERSE_MENU
end

local retail_count = rawget(_ENV, "GetNumUsedButtons")
if type(retail_count) == "function" then
  function GetNumUsedButtons(layer, ...)
    local count = retail_count(layer, ...)
    if layer == MIDDLE_LIST and type(count) == "number" and count > 1 and removed() and is_universe_row(layer, count - 1) then
      return count - 1
    end
    return count
  end
end

local retail_decide = rawget(_ENV, "OnDecideFocus")
if type(retail_decide) == "function" then
  function OnDecideFocus(layer, index, ...)
    if (layer == MIDDLE_LIST or layer == SMALL_LIST) and removed() and is_universe_row(layer, index) then
      return
    end
    return retail_decide(layer, index, ...)
  end
end

local retail_enter = rawget(_ENV, "OnEnter")
if type(retail_enter) == "function" then
  function OnEnter(layer, index, ...)
    if layer == MIDDLE_LIST and removed() and is_universe_row(layer, index) then
      return
    end
    return retail_enter(layer, index, ...)
  end
end

local retail_reserved = rawget(_ENV, "IsReservedPlayersUniverseEvent")
if type(retail_reserved) == "function" then
  function IsReservedPlayersUniverseEvent(...)
    if removed() then
      return false
    end
    return retail_reserved(...)
  end
end

local first_seen = {}                     -- layer .. ":" .. instance -> {x, y, z}

local function moves_with_gap(layer)
  if layer == BOX_LAYER then
    return true
  end
  return layer == SMALL_LIST and (type(rawget(_ENV, "BetterUI")) == "table" and BetterUI.chronicle_boxes or nil) ~= true
end

local function close_gap(layer, instance)
  if type(instance) ~= "number" or not moves_with_gap(layer) or not removed() then
    return
  end
  local key = layer .. ":" .. instance
  local base = first_seen[key]
  if base == nil then
    local x, y, z = VRFW.host.menu_command(GET_LOCAL_POS, layer, instance)
    if type(x) ~= "number" or type(y) ~= "number" then
      return
    end
    base = {x, y, type(z) == "number" and z or 0}
    first_seen[key] = base
  end
  VRFW.host.menu_command(SET_LOCAL_POS, layer, base[1], base[2] + ROW_PITCH, base[3], instance)
end

for _, name in ipairs({"OnSetupLayer", "OnOpenLayer"}) do
  local retail = rawget(_ENV, name)
  if type(retail) == "function" then
    _ENV[name] = function(layer, instance, ...)
      local results = table.pack(retail(layer, instance, ...))
      close_gap(layer, instance)
      return table.unpack(results, 1, results.n)
    end
  end
end
