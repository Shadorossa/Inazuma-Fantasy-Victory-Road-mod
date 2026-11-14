-- refuses an accept that would leave none.
BetterQoL = BetterQoL or {}
BetterQoL.shop_filter = BetterQoL.shop_filter or {}
BetterQoL.shop_filter.FROM_SHOP = false
BetterQoL.shop_filter.SHOWN = -1
BetterQoL.shop_filter.REDRAW = {}

local FILTER_LIST = 758265787 --[[win07_01_item_filter_list]]

function BetterQoL.shop_filter.redraw()
  funcLuaMenuCommand(4114514990, FILTER_LIST, false)
  UpdateItemCount()
end

local function SetCounter(prim, value)
  local idx = funcLuaMenuCommand(@crc:CMND_SEARCH_PRIM_INDEX@, FILTER_LIST, 0, prim)
  funcLuaMenuCommand(3609943765, FILTER_LIST, 0, idx, value)
end

do
  local init = OnInit
  function OnInit(...)
    BetterQoL.shop_filter.FROM_SHOP = false
    BetterQoL.shop_filter.SHOWN = -1
    if VRFW.param.has(2640949932) and VRFW.param.get(2640949932) == 3170360552 --[[shop_menu]] then
      BetterQoL.shop_filter.FROM_SHOP = true
    end
    return init(...)
  end
  local count = UpdateItemCount
  function UpdateItemCount(...)
    if not BetterQoL.shop_filter.FROM_SHOP then
      return count(...)
    end
    local params = GetFilterParamArray()
    if VRFW ~= nil and VRFW.item_filter_sections ~= nil then
      params = VRFW.item_filter_sections.saved(params)
    end
    local flat = CreateSendFilterParamArray(params)
    local ok, shown, total = pcall(funcLuaCommand, @crc:CMND_BETTERQOL_SHOP_FILTER_COUNT@, GetInventoryType(), table.unpack(flat))
    if not ok or type(shown) ~= "number" or type(total) ~= "number" then
      BetterQoL.shop_filter.SHOWN = -1
      return count(...)
    end
    BetterQoL.shop_filter.SHOWN = shown
    SetCounter(2872982514, shown)
    SetCounter(119370028, total)
  end
  local after = OnAfterReceiveFilterParam
  function OnAfterReceiveFilterParam(...)
    local r = table.pack(after(...))
    if BetterQoL.shop_filter.FROM_SHOP then
      BetterQoL.shop_filter.redraw()
      BetterQoL.shop_filter.REDRAW = {2, 6, 15}
    end
    return table.unpack(r, 1, r.n)
  end
  -- item_filter_menu has no Step of its own
  local step = Step
  function Step(...)
    local r = step ~= nil and table.pack(step(...)) or {n = 0}
    if #BetterQoL.shop_filter.REDRAW > 0 then
      for i = 1, #BetterQoL.shop_filter.REDRAW do
        BetterQoL.shop_filter.REDRAW[i] = BetterQoL.shop_filter.REDRAW[i] - 1
      end
      if BetterQoL.shop_filter.REDRAW[1] <= 0 then
        table.remove(BetterQoL.shop_filter.REDRAW, 1)
        BetterQoL.shop_filter.redraw()
      end
    end
    return table.unpack(r, 1, r.n)
  end
  local fn = OnFunction
  function OnFunction(a1, a2, ...)
    if a1 == 564758500 and BetterQoL.shop_filter.FROM_SHOP and BetterQoL.shop_filter.SHOWN == 0 then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
      return
    end
    local r = table.pack(fn(a1, a2, ...))
    if BetterQoL.shop_filter.FROM_SHOP and (a1 == 1319857620 or a1 == 1708665184) then
      BetterQoL.shop_filter.REDRAW = {1}
    end
    return table.unpack(r, 1, r.n)
  end
end
