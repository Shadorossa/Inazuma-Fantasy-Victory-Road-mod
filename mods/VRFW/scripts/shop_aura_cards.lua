-- Shop aura cards.

ShopAuraCards = ShopAuraCards or {}

local D = VRFW.declarations

local info, warn = VRFW.logger("shop_aura_cards")

local ON = false
local CARDS = {}   -- { sub, aura_type, layer, key } in load order

local function start()
  ON = VRFW.files.config("shop.aura_cards") ~= false
  local schema, why = D.schema("shop_aura_card")
  if not schema then
    warn(why .. ": the shops keep the game's aura cards")
    return
  end
  local by_sub, by_type = {}, {}
  for _, d in ipairs(D.load(schema, warn)) do
    local v = d.v
    local layer = D.id_of(v.layer) or 0
    if by_sub[v.item_sub] then
      warn(string.format("%s: item sub-kind %d already declared by %s: left out", d.key, v.item_sub, by_sub[v.item_sub]))
    elseif by_type[v.aura_type] and by_type[v.aura_type].layer ~= layer then
      warn(string.format("%s: aura type %d already has the card %s (%s): left out", d.key, v.aura_type, by_type[v.aura_type].name,
        by_type[v.aura_type].key))
    else
      by_sub[v.item_sub] = d.key
      by_type[v.aura_type] = by_type[v.aura_type] or { layer = layer, name = v.layer, key = d.key }
      CARDS[#CARDS + 1] = { sub = v.item_sub, aura_type = v.aura_type, layer = layer, key = d.key }
    end
  end
  if #CARDS == 0 then
    info("no mod declares shop aura cards")
    return
  end
  local parts = {}
  for _, c in ipairs(CARDS) do parts[#parts + 1] = string.format("sub-kind %d -> aura type %d (%s)", c.sub, c.aura_type, c.key) end
  if ON then
    info("on: " .. table.concat(parts, ", "))
  else
    info("off (config [shop] aura_cards = false): those rows keep the game's look: " .. table.concat(parts, ", "))
  end
end

function ShopAuraCards.List()
  local out = {}
  for _, c in ipairs(CARDS) do
    out[#out + 1] = c.sub
    out[#out + 1] = c.aura_type
    out[#out + 1] = c.layer
  end
  return ON, #CARDS, table.unpack(out)
end

start()
