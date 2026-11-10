-- VRFW.ids: the one way to read a game id (a crc, a chara_param, a handle) as a number.
if VRFW.ids == nil then
  local TWO_32 = 4294967296
  local TWO_31 = 2147483648

  local function number_of(v)
    local t = type(v)
    if t == "boolean" then
      return v and 1 or 0
    end
    if t ~= "number" and t ~= "string" then
      return nil
    end
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then
      return nil
    end
    return v
  end

  local I = {}

  --- v as an unsigned 32-bit number; `none` when it is no number.
  function I.unsigned_or(v, none)
    local n = number_of(v)
    if n == nil then
      return none
    end
    return math.floor(n) % TWO_32
  end

  --- v as an unsigned 32-bit number; 0 when it is no number.
  function I.unsigned(v)
    return I.unsigned_or(v, 0)
  end

  --- v as a signed 32-bit number.
  function I.signed(v)
    local n = I.unsigned(v)
    if n >= TWO_31 then
      return n - TWO_32
    end
    return n
  end

  --- True for nil or the -1 / 0xFFFFFFFF "no id" value.
  function I.is_none(v)
    if v == nil then
      return true
    end
    local n = number_of(v)
    return n == -1 or n == TWO_32 - 1
  end

  --- v as 0xXXXXXXXX text.
  function I.hex_text(v)
    local n = I.unsigned(v)
    return string.format("0x%04X%04X", math.floor(n / 65536), n % 65536)
  end

  local crc_of_text = {}

  --- The CRC-32 of text (cached).
  function I.crc32(text)
    local crc = crc_of_text[text]
    if crc == nil then
      crc = VRFW.crc32(text)
      crc_of_text[text] = crc
    end
    return crc
  end

  VRFW.ids = I
end
