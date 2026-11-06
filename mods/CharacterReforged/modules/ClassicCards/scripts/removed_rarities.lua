-- Classic Cards: tells the game's Lua which rarities lose their rarity look (config.toml [removed_rarities] tiers).
-- | Command | Args | Returns |
-- |---|---|---|
-- | CMND_CLASSICCARDS_REMOVED_RARITIES | none | the configured tiers, default "basic" |

ClassicCards = ClassicCards or {}

function ClassicCards.RemovedRaritiesChoice()
  return VRFW.files.config("removed_rarities.tiers") or "basic"
end
