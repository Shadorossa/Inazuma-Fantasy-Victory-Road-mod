BetterQoL = BetterQoL or {}
BetterQoL.neutral_element_shop = BetterQoL.neutral_element_shop or {prev = nil}
if BetterQoL.neutral_element_shop.prev == nil then
  BetterQoL.neutral_element_shop.prev = GetElementIconTexture
end
if BetterQoL.neutral_element_shop.prev ~= nil then
  function GetElementIconTexture(a1, ...)
    if a1 == 0 or a1 == 5 then
      return {{icon_cmd_type00}}
    end
    return BetterQoL.neutral_element_shop.prev(a1, ...)
  end
end
