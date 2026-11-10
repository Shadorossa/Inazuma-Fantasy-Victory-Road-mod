CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}

if CharacterReforged.one_card_per_player == nil then
  local ONE_CARD_PER_PLAYER = 1160876995  -- CMND_CHARACTERREFORGED_ONE_CARD_PER_PLAYER -> 1 or 0

  -- True while the loaded save keeps one card per player (content\duplicate_rules, one_card_per).
  function CharacterReforged.one_card_per_player()
    return VRFW.host.command(ONE_CARD_PER_PLAYER) == 1
  end
end
