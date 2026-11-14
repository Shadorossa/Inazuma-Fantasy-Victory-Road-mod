-- Hero style selector: the rarity whose card values are the styles (config.toml [hero_style]).
CharacterReforged = CharacterReforged or {}
CharacterReforged.HeroStyle = CharacterReforged.HeroStyle or {}
local HS = CharacterReforged.HeroStyle

local info, warn = VRFW.logger("hero_style")

local cfg = VRFW.config("hero_style", {})
local key = type(cfg.rarity) == "string" and cfg.rarity or ""
if key == "" then
  warn("config.toml [hero_style] rarity is not set: the skill table's idol button is off")
else
  info("hero style selector on the rarity", key)
end

-- The key of the rarity whose card values are the styles ("" = off).
function HS.Rarity()
  return key
end
