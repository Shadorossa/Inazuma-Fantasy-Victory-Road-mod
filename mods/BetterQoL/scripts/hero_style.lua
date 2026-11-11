-- Hero style selector: the rarity whose card values are the styles (config.toml [hero_style]).
BetterQoL = BetterQoL or {}
BetterQoL.HeroStyle = BetterQoL.HeroStyle or {}
local HS = BetterQoL.HeroStyle

local info, warn = VRFW.logger("hero_style")

local cfg = VRFW.config("hero_style", {})
local key = type(cfg.rarity) == "string" and cfg.rarity or ""
if key == "" then
  warn("config.toml [hero_style] rarity is not set: the hero style selector is off")
else
  info("hero style selector on the rarity", key)
end

-- The key of the rarity whose card values are the styles ("" = off).
function HS.Rarity()
  return key
end
