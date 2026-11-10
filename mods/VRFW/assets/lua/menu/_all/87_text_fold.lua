-- lua_patch.scope: used
-- VRFW.text_fold: accent and case folding of a UTF-8 text, for search keys and name grouping.
if VRFW.text_fold == nil then
  local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

  -- plain letter -> its accented forms (upper and lower case)
  local GROUPS = {
    A = "ÀÁÂÃÄÅàáâãäå", C = "Çç", E = "ÈÉÊËèéêë", I = "ÌÍÎÏìíîï", N = "Ññ", O = "ÒÓÔÕÖØòóôõöø",
    U = "ÙÚÛÜùúûü", Y = "Ýýÿ",
  }

  local T = {}

  --- The UTF-8 characters of s, as a list.
  function T.chars(s)
    local out = {}
    for ch in tostring(s or ""):gmatch(UTF8_CHAR) do
      out[#out + 1] = ch
    end
    return out
  end

  local PLAIN = {}
  for plain, list in pairs(GROUPS) do
    for _, ch in ipairs(T.chars(list)) do
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

  --- s folded to lower case (UTF-8).
  function T.fold(s)
    return (string.gsub(tostring(s or ""), UTF8_CHAR, lower_char))
  end

  --- s folded to upper case (UTF-8).
  function T.fold_upper(s)
    return (string.gsub(tostring(s or ""), UTF8_CHAR, upper_char))
  end

  VRFW.text_fold = T
end

if VRFW.text_fold.units == nil then
  local T = VRFW.text_fold
  local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"
  local WIDE_LEAD = 0xE3

  local function char_units(ch)
    return (string.byte(ch, 1) or 0) >= WIDE_LEAD and 2 or 1
  end

  --- The display width of s in units.
  function T.units(s)
    local plain = string.gsub(tostring(s or ""), "%[C%u*%]", "")
    plain = string.gsub(plain, "<[%u%d_]+>", "MM")
    local u = 0
    for ch in string.gmatch(plain, UTF8_CHAR) do
      u = u + char_units(ch)
    end
    return u
  end

  --- The display width of s in pixels, `unit_px` per unit.
  function T.width(s, unit_px)
    return T.units(s) * (unit_px or 1)
  end

  --- s cut to `units`, with its ellipsis.
  function T.cut(s, units)
    s = tostring(s or "")
    if units == nil or units <= 1 or T.units(s) <= units then
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

  --- s cut to fit `px` at `size` and glyph width `glyph`.
  function T.fit(s, px, size, glyph)
    local unit = (size or 1) * (glyph or 0.5)
    if unit <= 0 then
      return tostring(s or "")
    end
    return T.cut(s, math.floor((px or 0) / unit))
  end

  --- The drawn width of text s; nil when it cannot be measured.
  function T.measure(layer, idx, node, s)
    local ok, w = pcall(funcLuaMenuCommand, VRFW.commands.GET_MENU_TEXT_RECT_SIZE, layer, idx, node, s)
    w = ok and tonumber(w) or nil
    if w ~= nil and w > 0 and w < 4000 then
      return w
    end
    return nil
  end
end

if VRFW.text_fold.literal == nil then
  -- the layout has no escape: `<x>`, `[Cx]` and the two characters backslash-n are consumed as markup (nie.exe 0x587EF0, 0x589C80, 0x589AE0)
  local MARKUP_LOOKALIKE = {["<"] = "‹", [">"] = "›", ["["] = "［", ["]"] = "］"}
  local NEWLINE_SEQUENCE, BACKSLASH_N = "\\n", "＼n"

  --- Untrusted text (problem messages, paths, mod names) with its markup characters swapped for look-alikes, so it draws as written.
  function VRFW.text_fold.literal(s)
    local text = string.gsub(tostring(s or ""), "[<>%[%]]", MARKUP_LOOKALIKE)
    return (string.gsub(text, NEWLINE_SEQUENCE, BACKSLASH_N))
  end
end

if VRFW.text_fold.fill_template == nil then
  --- Text with {1}, {2}, ... filled from the arguments.
  function VRFW.text_fold.fill_template(text, ...)
    local args = table.pack(...)
    return (string.gsub(tostring(text or ""), "{(%d)}", function(k)
      local v = args[tonumber(k)]
      if v == nil then
        return ""
      end
      return tostring(v)
    end))
  end
end
