-- Little-endian words and hex text in byte strings (VRFW.bytes). A word is 32 bits; offsets start at 0.
local Bytes = {}

local band, rshift = bit32.band, bit32.rshift
local byte, char, concat = string.byte, string.char, table.concat

--- The 4-byte little-endian text of `value`.
function Bytes.word_text(value)
  value = band(value or 0, 0xFFFFFFFF)
  return char(band(value, 0xFF), band(rshift(value, 8), 0xFF), band(rshift(value, 16), 0xFF), rshift(value, 24))
end

--- The word at `offset` of `text`; nil past the end.
function Bytes.read_word(text, offset)
  local a, b, c, d = byte(text, offset + 1, offset + 4)
  if not d then return nil end
  return a + b * 0x100 + c * 0x10000 + d * 0x1000000
end

--- Byte `index` (0 = lowest) of `word`.
function Bytes.byte_of_word(word, index)
  return band(rshift(word, index * 8), 0xFF)
end

--- `count` words of `text` from `offset`, as an array.
function Bytes.read_words(text, offset, count)
  local words = {}
  for index = 0, count - 1 do
    local a, b, c, d = byte(text, offset + index * 4 + 1, offset + index * 4 + 4)
    words[index + 1] = a + b * 0x100 + c * 0x10000 + d * 0x1000000
  end
  return words
end

--- The text of `words[first..last]` (default: all of them).
function Bytes.text_of_words(words, first, last)
  local parts, count = {}, 0
  for index = first or 1, last or #words do
    count = count + 1
    parts[count] = Bytes.word_text(words[index])
  end
  return concat(parts)
end

--- `text` cut or zero-filled to exactly `size` bytes.
function Bytes.padded(text, size)
  if #text >= size then return text:sub(1, size) end
  return text .. string.rep("\0", size - #text)
end

--- `text` up to its first zero byte.
function Bytes.before_zero(text)
  local zero = text:find("\0", 1, true)
  if zero then return text:sub(1, zero - 1) end
  return text
end

--- The bytes of the hex digits `hex_text` (a bad digit pair gives 0).
function Bytes.from_hex_text(hex_text)
  return (hex_text:gsub("..", function(pair) return char(tonumber(pair, 16) or 0) end))
end

--- The 8 hex digits of `word`.
function Bytes.word_hex_text(word)
  return string.format("%08X", band(word or 0, 0xFFFFFFFF))
end

return Bytes
