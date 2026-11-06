-- VRFW_Text: accent and case folding of a UTF-8 text, for search keys and name grouping. The script side has the same
-- table (scripts\lib\text_fold.lua). Definitions only: no engine call at load.
--   VRFW_Text.Fold(s)      -> s with every accented Latin letter as its plain letter, everything lower case
--                             («Ángel Ñandú» -> "angel nandu"); other characters as they are (ASCII lower-cased)
--   VRFW_Text.FoldUpper(s) -> the same, upper case («Ángel» -> "ANGEL")
--   VRFW_Text.Chars(s)     -> the UTF-8 characters of s, one string each
-- Text width (a menu's own screens: centring, right alignment, cutting a name to its box):
--   VRFW_Text.Units(s)              -> the width of s in glyph units: a letter 1, a CJK letter 2, a button tag
--                                      (<CMD_FUNCL1>) 2; colour tags ([CN] ... [C]) count nothing
--   VRFW_Text.Width(s, unit_px)     -> Units(s) * unit_px (an estimate in px)
--   VRFW_Text.Cut(s, units)         -> s cut to `units` with «…» (trailing spaces and punctuation dropped first)
--   VRFW_Text.Fit(s, px, size[, glyph]) -> s cut to fit `px` pixels at font size `size` (a unit = size * glyph px,
--                                      glyph 0.5 by default)
--   VRFW_Text.Measure(layer, idx, node, s) -> the game's own width in px of s on that text node at scale 1
--                                      (CMND_GET_MENU_TEXT_RECT_SIZE), nil when the game gives none
if VRFW_Text == nil then
  local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

  -- plain letter -> its accented forms (upper and lower case)
  local GROUPS = {
    A = "ÀÁÂÃÄÅàáâãäå", C = "Çç", E = "ÈÉÊËèéêë", I = "ÌÍÎÏìíîï", N = "Ññ", O = "ÒÓÔÕÖØòóôõöø",
    U = "ÙÚÛÜùúûü", Y = "Ýýÿ",
  }

  local T = {}

  function T.Chars(s)
    local out = {}
    for ch in tostring(s or ""):gmatch(UTF8_CHAR) do
      out[#out + 1] = ch
    end
    return out
  end

  local PLAIN = {}
  for plain, list in pairs(GROUPS) do
    for _, ch in ipairs(T.Chars(list)) do
      PLAIN[ch] = plain
    end
  end

  local function lower_char(ch)
    local p = PLAIN[ch]
    if p ~= nil then
      return string.lower(p)
    end
    return string.lower(ch)
  end

  local function upper_char(ch)
    return PLAIN[ch] or string.upper(ch)
  end

  function T.Fold(s)
    return (string.gsub(tostring(s or ""), UTF8_CHAR, lower_char))
  end

  function T.FoldUpper(s)
    return (string.gsub(tostring(s or ""), UTF8_CHAR, upper_char))
  end

  VRFW_Text = T
end

if VRFW_Text.Units == nil then
  local T = VRFW_Text
  local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"
  local WIDE_LEAD = 0xE3   -- lead byte of the CJK blocks: those letters are two units wide

  local function char_units(ch)
    return (string.byte(ch, 1) or 0) >= WIDE_LEAD and 2 or 1
  end

  function T.Units(s)
    local plain = string.gsub(tostring(s or ""), "%[C%u*%]", "")
    plain = string.gsub(plain, "<[%u%d_]+>", "MM")
    local u = 0
    for ch in string.gmatch(plain, UTF8_CHAR) do
      u = u + char_units(ch)
    end
    return u
  end

  function T.Width(s, unit_px)
    return T.Units(s) * (unit_px or 1)
  end

  function T.Cut(s, units)
    s = tostring(s or "")
    if units == nil or units <= 1 or T.Units(s) <= units then
      return s
    end
    local out, u = {}, 0
    for ch in string.gmatch(s, UTF8_CHAR) do
      local w = char_units(ch)
      if u + w > units - 1 then
        break
      end
      out[#out + 1] = ch
      u = u + w
    end
    return (string.gsub(table.concat(out), "[%s%p]+$", "")) .. "…"
  end

  function T.Fit(s, px, size, glyph)
    local unit = (size or 1) * (glyph or 0.5)
    if unit <= 0 then
      return tostring(s or "")
    end
    return T.Cut(s, math.floor((px or 0) / unit))
  end

  function T.Measure(layer, idx, node, s)
    local ok, w = pcall(funcLuaMenuCommand, VRFW_Cmd.GET_MENU_TEXT_RECT_SIZE, layer, idx, node, s)
    w = ok and tonumber(w) or nil
    if w ~= nil and w > 0 and w < 4000 then
      return w
    end
    return nil
  end
end
