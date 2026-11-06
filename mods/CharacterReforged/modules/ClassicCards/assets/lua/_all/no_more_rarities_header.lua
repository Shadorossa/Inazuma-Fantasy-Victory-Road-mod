-- No More Rarities: the player page's header band in the player's POSITION colour (content\menus\player_header.toml, a
-- band colour of Character Reforged's host CharacterReforged.header_band; CharacterReforged.Header.BandColour calls
-- ClassicCards.HeaderBandColour(layer, inst, hdl) on every fill of the band). Without this mod the band keeps the
-- retail rarity look (Character Reforged).
-- * A card of a removed rarity (ClassicCards.RarityRemoved: 0-4 always, Ídolo / Diamante by the option) gets the plate of his OWN position through the
--   mod's one position helper ClassicCards.PositionColour,
-- swapped on the band's texture slot status_chr_base01_s01 -> true.
-- * A special card (Héroe / Ídolo / Diamante: they keep their rarity), staff or an unknown position -> false: Character
--   Reforged draws the rarity look.
-- ClassicCards.HeaderShowsRarity(hdl): the header's rarity title (Character Reforged's host
-- CharacterReforged.header_rarity, the banner left of «Nv.»): only Ídolo and Diamante (the game's rarities `hero`
-- and `fabled`) and the rarities other mods declare (the VR-Framework's rarity set, provider other
-- than `game`) keep it; every other card (the «Leyenda del fútbol» every normal card is now) shows none -> false. A
-- normal card (rarity 0-4, ClassicCards.IsNormalCard) is answered at once, without the framework (no title even
-- before the framework answers); any other: its chara_param card type through CMND_VRFW_RARITY_OF_CARD, the row
-- through CMND_VRFW_REG_GET("rarity", i). Without the framework's answer: true
-- (the retail title).
-- Both rules only while the rarity removal applies (ClassicCards.RarityRemovalApplies,
-- no_more_rarities_card_look.lua: not in a reserved slot, a mode's own save such as INAROGUE's): there the band keeps the retail rarity look and the
-- title shows.
-- Defines functions only; engine calls only when the band / the header is filled; every call goes through pcall.
if type(rawget(_ENV, "UpdateCharaStatusPlateInfoByCharaStHdl")) == "function" then
  ClassicCards = type(ClassicCards) == "table" and ClassicCards or {}
  if ClassicCards.HeaderBandColour == nil then
    local STATUS_TEXTURE = 348706892     -- #/menu/00_soccer/soccer11/soccer11_04/<LG>/soccer11_04.g4tx
    local BAND_SLOT = 1621728801         -- status_chr_base01_s01 (the band mesh _status_chr_base_s01's slot)
    local SWAP_SPRITE = 558735651        -- (layer, texture, sprite, slot, 0, inst)
    local CHARA = 1131797651             -- CMND_GET_CHARA (hdl, 4) = chara_param id
    local CHARA_INFO = 4060384944        -- CMND_GET_CHARA_INFO (param, 8) = card type (chara_param col 41)
    local RARITY_OF_CARD = 2739024233    -- CMND_VRFW_RARITY_OF_CARD (card type, frame 0 = any) -> rarity index
    local REGISTRY_GET = 1306193655      -- CMND_VRFW_REG_GET ("rarity", index) -> key, value, frame, provider, ...
    local GAME_PROVIDER = "game"         -- the provider of the game's own rarities in the framework's set
    local TITLED_GAME_RARITIES = {hero = true, fabled = true}   -- Ídolo, Diamante: the game rarities with a title

    -- the card type of a status (chara_param col 41), nil when unknown
    local function CardType(hdl)
      local okp, param = pcall(funcLuaCommand, CHARA, hdl, 4)
      if not okp or type(param) ~= "number" or param == 0 then
        return nil
      end
      local okc, ok, cardType = pcall(funcLuaCommand, CHARA_INFO, param, 8)
      if not okc or ok == false then
        return nil
      end
      if type(ok) == "number" and cardType == nil then
        cardType = ok
      end
      return type(cardType) == "number" and cardType or nil
    end

    local function RemovalApplies()
      return type(ClassicCards.RarityRemovalApplies) ~= "function" or ClassicCards.RarityRemovalApplies()
    end

    function ClassicCards.HeaderShowsRarity(hdl)
      if type(hdl) ~= "number" or hdl == 0 or not RemovalApplies() then
        return true
      end
      if type(ClassicCards.IsNormalCard) == "function" then
        local okNormal, normal = pcall(ClassicCards.IsNormalCard, hdl)
        if okNormal and normal == true then
          return false                   -- a removed rarity: never a title
        end
      end
      local cardType = CardType(hdl)
      if cardType == nil then
        return true
      end
      local okIndex, index = pcall(funcLuaCommand, RARITY_OF_CARD, cardType, 0)
      if not okIndex or type(index) ~= "number" then
        return true                      -- no answer from the framework: the retail title
      end
      if index < 0 then
        return false                     -- a rarity this mod (or another) removed
      end
      local okRow, key, _, _, provider = pcall(funcLuaCommand, REGISTRY_GET, "rarity", index)
      if not okRow or type(key) ~= "string" or key == "" then
        return true
      end
      return TITLED_GAME_RARITIES[key] == true or (type(provider) == "string" and provider ~= GAME_PROVIDER)
    end

    function ClassicCards.HeaderBandColour(layer, inst, hdl)
      local crc = rawget(_ENV, "CRC32")
      if type(hdl) ~= "number" or hdl == 0 or type(VRFW_UI) ~= "table" or type(crc) ~= "function" then
        return false
      end
      local look = type(ClassicCards.PositionColour) == "function" and ClassicCards.PositionColour(hdl) or nil
      if look == nil then
        return false
      end
      local sprite = look.status_plate
      -- the unfiltered command: the band is not a rarity plate (the card look filter maps by the plate being filled)
      local command = funcLuaMenuCommand
      if type(ClassicCards.RawMenuCommand) == "function" then
        command = ClassicCards.RawMenuCommand()
      end
      local ok = pcall(command, SWAP_SPRITE, layer, STATUS_TEXTURE, crc(sprite), BAND_SLOT, 0, inst or 0)
      return ok
    end
  end
end
