-- Accent and case folding of a UTF-8 text, for search keys and name grouping.
local M = {}

local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

-- plain letter -> its accented forms (upper and lower case)
local GROUPS = {
  A = "ÀÁÂÃÄÅàáâãäå", C = "Çç", E = "ÈÉÊËèéêë", I = "ÌÍÎÏìíîï", N = "Ññ", O = "ÒÓÔÕÖØòóôõöø",
  U = "ÙÚÛÜùúûü", Y = "Ýýÿ",
}

--- The UTF-8 characters of `s`, as an array.
function M.chars(s)
  local out = {}
  for ch in tostring(s or ""):gmatch(UTF8_CHAR) do
    out[#out + 1] = ch
  end
  return out
end

local PLAIN = {}
for plain, list in pairs(GROUPS) do
  for _, ch in ipairs(M.chars(list)) do
    PLAIN[ch] = plain
  end
end

local function lower_char(ch)
  local p = PLAIN[ch]
  if p ~= nil then
    return p:lower()
  end
  return ch:lower()
end

local function upper_char(ch)
  return PLAIN[ch] or ch:upper()
end

--- Text `s` in lower case (Latin letters with accents too).
function M.fold(s)
  return (tostring(s or ""):gsub(UTF8_CHAR, lower_char))
end

--- Text `s` in upper case (Latin letters with accents too).
function M.fold_upper(s)
  return (tostring(s or ""):gsub(UTF8_CHAR, upper_char))
end

--- Text with `{1}`..`{9}` replaced by the arguments.
function M.fill_template(text, ...)
  local args = { ... }
  return (tostring(text or ""):gsub("{(%d)}", function(k)
    local v = args[tonumber(k)]
    if v == nil then
      return ""
    end
    return tostring(v)
  end))
end

return M
