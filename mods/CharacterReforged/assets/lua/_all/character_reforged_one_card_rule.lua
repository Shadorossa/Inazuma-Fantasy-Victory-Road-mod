CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}

if CharacterReforged.one_card_per_player == nil then
  local ONE_CARD_PER_PLAYER = 1160876995  -- CMND_CHARACTERREFORGED_ONE_CARD_PER_PLAYER -> 1 or 0

  -- True while the loaded save keeps one card per player (content\duplicate_rules, one_card_per).
  function CharacterReforged.one_card_per_player()
    return VRFW.host.command(ONE_CARD_PER_PLAYER) == 1
  end
end

if CharacterReforged.raised_copy_rarity == nil then
  local RAISED_COPY_RARITY = 3649620525  -- CMND_CHARACTERREFORGED_RAISED_COPY_RARITY (rarity, the card's own rarity) -> 1 or 0

  -- True while a copy saved at `rarity` of a card whose own rarity is `card_rarity` is kept beside the card's other copies (content\duplicate_rules, raised_copy_rarities).
  function CharacterReforged.raised_copy_rarity(rarity, card_rarity)
    return VRFW.host.command(RAISED_COPY_RARITY, rarity, card_rarity) == 1
  end
end
