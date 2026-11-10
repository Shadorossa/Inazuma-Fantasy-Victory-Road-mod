BetterQoL = BetterQoL or {}
BetterQoL.shop_filter_basara_banner = BetterQoL.shop_filter_basara_banner or {}
BetterQoL.shop_filter_basara_banner.LAYER = 4037719016 --[[shop01_11_view_staff]]
BetterQoL.shop_filter_basara_banner.TICK = 0
if BetterQoL.shop_filter_basara_banner.WRAPPED == nil then
  BetterQoL.shop_filter_basara_banner.WRAPPED = {}
end

function BetterQoL.shop_filter_basara_banner.hide(inst)
  local i = inst or 0
  funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], BetterQoL.shop_filter_basara_banner.LAYER, 672386185 --[[_shop_cut_chr_dmy01]], false, i)
  funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], BetterQoL.shop_filter_basara_banner.LAYER, 2022610798 --[[_shop_cut_parts01]], false, i)
  funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], BetterQoL.shop_filter_basara_banner.LAYER, i, false)
end

function BetterQoL.shop_filter_basara_banner.wrap(name, make)
  local cur = _ENV[name]
  if BetterQoL.shop_filter_basara_banner.WRAPPED[cur] then
    return
  end
  local w = make(cur)
  BetterQoL.shop_filter_basara_banner.WRAPPED[w] = true
  _ENV[name] = w
end

local function layer_hook(orig)
  return function(a1, a2, ...)
    local r = table.pack()
    if orig ~= nil then
      r = table.pack(orig(a1, a2, ...))
    end
    if a1 == BetterQoL.shop_filter_basara_banner.LAYER then
      pcall(BetterQoL.shop_filter_basara_banner.hide, a2)
    end
    return table.unpack(r, 1, r.n)
  end
end

BetterQoL.shop_filter_basara_banner.wrap("OnSetupLayer", layer_hook)
BetterQoL.shop_filter_basara_banner.wrap("OnOpenLayer", layer_hook)

BetterQoL.shop_filter_basara_banner.wrap("Step", function(orig)
  return function(...)
    local r = table.pack()
    if orig ~= nil then
      r = table.pack(orig(...))
    end
    BetterQoL.shop_filter_basara_banner.TICK = BetterQoL.shop_filter_basara_banner.TICK + 1
    if BetterQoL.shop_filter_basara_banner.TICK >= 20 then
      BetterQoL.shop_filter_basara_banner.TICK = 0
      pcall(function()
        if funcLuaMenuCommand(262659071 --[[CMND_IS_EXIST_LAYER?]], BetterQoL.shop_filter_basara_banner.LAYER) == true
          and funcLuaMenuCommand(1262717583 --[[CMND_IS_LAYER_VISIBLE]], BetterQoL.shop_filter_basara_banner.LAYER, 0) == true then
          BetterQoL.shop_filter_basara_banner.hide(0)
        end
      end)
    end
    return table.unpack(r, 1, r.n)
  end
end)
