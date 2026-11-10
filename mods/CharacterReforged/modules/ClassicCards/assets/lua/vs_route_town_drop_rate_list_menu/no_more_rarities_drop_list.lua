local DROP_BAND_FORWARD_SPRITE = "no_more_rarities_drop_band_forward"

ClassicCards = type(ClassicCards) == "table" and ClassicCards or {}
if type(rawget(_ENV, "UpdateListItem_DropChara")) == "function" and ClassicCards.drop_list == nil then
  local D = {}
  ClassicCards.drop_list = D
  local ROW_TEXTURE = 2268931645         -- #/menu/10_win/win05/win05_38/<LG>/win05_38.g4tx
  local BAND_SLOT = 94010567             -- list_drop_chr_rarity01: the band mesh's texture slot
  local SWAP_SPRITE = 558735651          -- (layer, texture, sprite, slot, 0, instance)
  local SPIRIT_CARD = VRFW.commands.GET_SPIRIT_CHARA_PARAM_ID         -- (chara, rarity) -> the spirit's card
  local DROP_BAND_OF_LOOK = {
    goalkeeper = 1978697800,             -- list_drop_chr_rarity04 (gold)
    defender = 2626891133,               -- list_drop_chr_rarity02 (blue)
    midfielder = 94010567,               -- list_drop_chr_rarity01 (green)
    forward = DROP_BAND_FORWARD_SPRITE,
  }

  local function BandOf(look)
    local band = type(look) == "table" and DROP_BAND_OF_LOOK[look.key] or nil
    if type(band) == "string" then
      band = VRFW.ids.crc32(band)
      DROP_BAND_OF_LOOK[look.key] = band
    end
    return band
  end

  function D.paint(layer, instance, chara, rarity)
    if type(chara) ~= "number" or chara == 0 or not ClassicCards.rarity_removed(rarity) then
      return false
    end
    local card = VRFW.host.command(SPIRIT_CARD, chara, rarity)
    if type(card) ~= "number" or card == 0 then
      return false
    end
    local okLook, look = pcall(ClassicCards.position_colour, {charaParamId = card, rarity = rarity})
    local band = okLook and BandOf(look) or nil
    if band == nil then
      return false
    end
    return (pcall(ClassicCards.raw_menu_command(), SWAP_SPRITE, layer, ROW_TEXTURE, band, BAND_SLOT, 0, instance))
  end

  local retail_row = UpdateListItem_DropChara
  function UpdateListItem_DropChara(layer, instance, dirty, focused, chara, a6, a7, rarity, ...)
    -- the retail row repaints its band when dirty, or on the focused row after a tab change (VRFW.drop_list.forced)
    local redrawn = dirty or (focused and type(VRFW.drop_list) == "table" and VRFW.drop_list.forced == true)
    local results = table.pack(retail_row(layer, instance, dirty, focused, chara, a6, a7, rarity, ...))
    if redrawn then
      pcall(D.paint, layer, instance, chara, rarity)
    end
    return table.unpack(results, 1, results.n)
  end
end
