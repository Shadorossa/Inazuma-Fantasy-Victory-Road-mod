if type(rawget(_ENV, "UpdateCharaStatusPlateInfoByCharaStHdl")) == "function" then
  ClassicCards = type(ClassicCards) == "table" and ClassicCards or {}
  if ClassicCards.header_band_colour == nil then
    local STATUS_TEXTURE = 348706892     -- #/menu/00_soccer/soccer11/soccer11_04/<LG>/soccer11_04.g4tx
    local BAND_SLOT = 1621728801
    local SWAP_SPRITE = 558735651        -- (layer, texture, sprite, slot, 0, inst)
    local CHARA = 1131797651             -- CMND_GET_CHARA (hdl, 4) = chara_param id
    local RARITY_OF_CARD = 2739024233
    local REGISTRY_GET = 1306193655
    local GAME_PROVIDER = "game"
    local TITLED_GAME_RARITIES = {hero = true, fabled = true}   -- Ídolo, Diamante: the game rarities with a title

    -- the card type of a status (chara_param col 41), nil when unknown
    local function CardType(hdl)
      local param = VRFW.host.command(CHARA, hdl, 4)
      if type(param) ~= "number" or param == 0 then
        return nil
      end
      return ClassicCards.param_rarity(param)
    end

    -- false = no rarity title: a removed rarity, or a game rarity other than Ídolo / Diamante; true outside the removal
    function ClassicCards.header_shows_rarity(hdl)
      if type(hdl) ~= "number" or hdl == 0 or not ClassicCards.rarity_removal_applies() then
        return true
      end
      local okNormal, normal = pcall(ClassicCards.is_normal_card, hdl)
      if okNormal and normal == true then
        return false
      end
      local cardType = CardType(hdl)
      if cardType == nil then
        return true
      end
      local index = VRFW.host.command(RARITY_OF_CARD, cardType, 0)
      if type(index) ~= "number" then
        return true
      end
      if index < 0 then
        return false                     -- a rarity some mod removed
      end
      local key, _, _, provider = VRFW.host.command(REGISTRY_GET, "rarity", index)
      if type(key) ~= "string" or key == "" then
        return true
      end
      return TITLED_GAME_RARITIES[key] == true or (type(provider) == "string" and provider ~= GAME_PROVIDER)
    end

    function ClassicCards.header_band_colour(layer, inst, hdl)
      local crc = rawget(_ENV, "CRC32")
      if type(hdl) ~= "number" or hdl == 0 or type(VRFW.ui_plates) ~= "table" or type(crc) ~= "function" then
        return false
      end
      local look = ClassicCards.position_colour(hdl)
      if look == nil then
        return false
      end
      -- the band is not a rarity plate: past the card look filter
      local ok = pcall(ClassicCards.raw_menu_command(), SWAP_SPRITE, layer, STATUS_TEXTURE, crc(look.status_plate),
        BAND_SLOT, 0, inst or 0)
      return ok
    end
  end
end
