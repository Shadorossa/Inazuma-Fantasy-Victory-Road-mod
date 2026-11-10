-- Data of the equip pickers: which series have emblems, which have kits.
local Catalogue = VRFW.catalogue

--- Series of the game with at least one item of the set `items` (item id -> anything), in the series table's order.
local function series_with(items)
  local has_item = {}
  for item, types in pairs(Catalogue.item_series()) do
    if items[item] then
      for series_type in pairs(types) do
        has_item[series_type] = true
      end
    end
  end
  local tabs = {}
  for _, series in ipairs(Catalogue.series()) do
    if has_item[series.ty] then
      tabs[#tabs + 1] = { id = series.id, ty = series.ty }
    end
  end
  return tabs
end

--- Series of the game that have at least one emblem, in the series table's order.
function BetterUI.EmblemTabs()
  return series_with(Catalogue.emblem_ids() or {})
end

--- Series of the game that have at least one kit, in the series table's order.
function BetterUI.KitTabs()
  local kits = VRFW.save.kits.items()
  return series_with(kits and kits.by_id or {})
end
