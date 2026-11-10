
TextTags = TextTags or {}

local GameText = VRFW.names
local NameTags = VRFW.name_tags

function TextTags.Expand(text, code)
  if type(text) ~= "string" then return "" end
  return NameTags.clean(text, GameText.language(code))
end
