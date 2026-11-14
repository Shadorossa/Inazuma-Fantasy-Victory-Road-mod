CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}

if CharacterReforged.one_card_per_player == nil then
  local ONE_CARD_PER_PLAYER = 1160876995  -- CMND_CHARACTERREFORGED_ONE_CARD_PER_PLAYER -> 1 or 0

  -- True while the loaded save keeps one card per player (content\duplicate_rules, one_card_per).
  function CharacterReforged.one_card_per_player()
    return VRFW.host.command(ONE_CARD_PER_PLAYER) == 1
  end
end

if CharacterReforged.copy_rarity == nil then
  local COPY_RARITY = 3460068810  -- CMND_CHARACTERREFORGED_COPY_RARITY (rarity, the card's chara_param col 41) -> rarity

  -- The rarity a copy saved at `rarity` of a card of special rarity `card_rarity` holds in the loaded save (content\duplicate_rules): with the card it names one player.
  function CharacterReforged.copy_rarity(rarity, card_rarity)
    local held = VRFW.host.command(COPY_RARITY, rarity, card_rarity)
    return type(held) == "number" and held or rarity
  end

  -- True when the club holds card `card` at the rarity a copy saved at `rarity` holds: the same card at another rarity is another player.
  function CharacterReforged.holds_copy(card, rarity)
    local R = VRFW.recruit
    return R.copies(card, CharacterReforged.copy_rarity(rarity, R.special_rarity(card))) > 0
  end
end
