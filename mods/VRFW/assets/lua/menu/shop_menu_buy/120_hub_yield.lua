-- VRFW › a shop over a hub other than the Mercado.
if VRFW.host ~= nil then
  local SHOP = 3170360552            -- shop_menu (this script: shop_menu_buy)
  local MARKET = 839500579           -- market_menu
  local BG = 717014739               -- shop01_00_background: its close = the shop is going
  local HY = {hub = nil, on = false}
  --- Internal: state of the shop hub yield.
  VRFW.shop_hub_yield = HY

  local Log = VRFW.logger.new("vrfw.ShopHubYield")

  local function Yield(on)
    if on == HY.on then
      return
    end
    if on then
      local ok, parent = pcall(function() return MENU_DEF.GetParentMenuID(SHOP) end)
      if not ok or type(parent) ~= "number" or parent == 0 or parent == MARKET then
        Log("hub", tostring(parent), "not yielded (none or the Mercado)")
        return
      end
      local market = VRFW.host.command(VRFW.commands.IS_OPEN_MENU_OBJECT, MARKET, 717014739)
      if market then
        Log("hub", parent, "not yielded (over the Mercado)")
        return
      end
      HY.hub = parent
    end
    --- Internal: true while the shop yields the hub.
    HY.on = on
    if HY.hub == nil then
      return
    end
    local ok, n = pcall(funcLuaCommand, 830228314 --[[run a function in another menu's VM]], HY.hub, "vrfw_hub_yield", on, SHOP)
    Log(on and "yield" or "give back", "hub", HY.hub, tostring(ok), tostring(n))
    if not on then
      HY.hub = nil
    end
  end

  VRFW.host.on("shop_menu_buy", "OnInit", {id = "VRFW.shop_hub_yield_init", phase = "after", fn = function(r, ...)
    HY.hub, HY.on = nil, false
    pcall(Yield, true)
  end})
  VRFW.host.on("shop_menu_buy", "OnCloseLayer", {id = "VRFW.shop_hub_yield_close", phase = "before",
    create = true, fn = function(a1, ...)
      if a1 == BG then
        pcall(Yield, false)
      end
    end})
  VRFW.host.on("shop_menu_buy", "FinalizeMenu", {id = "VRFW.shop_hub_yield_end", phase = "before",
    create = true, fn = function(...)
      pcall(Yield, false)
    end})
end
