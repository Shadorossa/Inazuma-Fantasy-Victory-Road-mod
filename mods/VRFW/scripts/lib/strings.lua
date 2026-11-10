-- Text helpers every mod shares (VRFW.strings).
local Strings = {}

--- `text` without spaces at either end ("" for nil).
function Strings.trim(text)
  return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

--- The non-empty parts of `text` between single-character `separator`s, as an array.
function Strings.split(text, separator)
  local parts = {}
  local pattern = "[^" .. separator:gsub("%W", "%%%0") .. "]+"
  for part in tostring(text or ""):gmatch(pattern) do parts[#parts + 1] = part end
  return parts
end

return Strings
