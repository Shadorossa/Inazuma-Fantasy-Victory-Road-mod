-- Small text helpers: trim, split. Call: at load or in a handler.
-- Text helpers every mod shares (VRFW.strings).
local Strings = {}

--- VRFW.strings.trim(text): text without spaces at both ends ("" for nil). Call: at load or in a handler.
function Strings.trim(text)
  return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

--- VRFW.strings.split(text, sep): the non-empty parts of text between one-character separators, as a list. Call: at load or in a handler.
function Strings.split(text, separator)
  local parts = {}
  local pattern = "[^" .. separator:gsub("%W", "%%%0") .. "]+"
  for part in tostring(text or ""):gmatch(pattern) do parts[#parts + 1] = part end
  return parts
end

return Strings
