-- Name tags in game texts for the menu screens (content\game\text_tags.toml): CMND_VRFW_TEXT_EXPAND_TAGS(text, lang
-- code) -> the text with its tags replaced (lib/name_tags.lua clean), as the game shows it.

TextTags = TextTags or {}

local GameText = require "VRFW/lib/game_text"
local NameTags = require "VRFW/lib/name_tags"

function TextTags.Expand(text, code)
  if type(text) ~= "string" then return "" end
  return NameTags.clean(text, GameText.language(code))
end
