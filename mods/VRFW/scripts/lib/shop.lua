-- Advanced: The shop rows a player can see (VRFW.shop): the framework hides a row by a condition that compares its never-written flag VRFW_ROW_HIDDEN.
local Shop = {}

local SHOP_TABLE = "data/common/gamedata/shop/shop_config"
local SHOP_ROWS = "SHOP_INFO_ITEM"
local SHOP_ITEM, SHOP_CONDITION = 3, 23    -- 1-based columns of a shop row: its item, its condition
local HIDE_FLAG = "VRFW_ROW_HIDDEN"
local HASH_LITERAL = 0x34                  -- the token of a hash literal in condition bytecode (big-endian u32 after it)
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--- Internal: The bytes of base64 text as an array (1-based); the decode stops at the first character that is not base64.
function Shop.base64_bytes(text)
  local bytes, buffer, bits = {}, 0, 0
  for i = 1, #text do
    local value = BASE64:find(text:sub(i, i), 1, true)
    if value == nil then
      break
    end
    buffer = (buffer % 65536) * 64 + (value - 1)
    bits = bits + 6
    if bits >= 8 then
      bits = bits - 8
      bytes[#bytes + 1] = math.floor(buffer / 2 ^ bits) % 256
    end
  end
  return bytes
end

--- Internal: True when condition bytes (an array, 1-based) hold the hash literal `hash`.
function Shop.mentions(bytes, hash)
  for i = 1, #bytes - 4 do
    if bytes[i] == HASH_LITERAL and bytes[i + 1] * 16777216 + bytes[i + 2] * 65536 + bytes[i + 3] * 256 + bytes[i + 4] == hash then
      return true
    end
  end
  return false
end

--- Internal: True when a shop row's base64 condition text hides the row (it compares VRFW_ROW_HIDDEN).
function Shop.hidden(condition)
  return type(condition) == "string" and condition ~= "" and Shop.mentions(Shop.base64_bytes(condition), VRFW.crc32(HIDE_FLAG))
end

--- Advanced: The items some shop row sells and does not hide: item id -> true.
function Shop.sold_items()
  local sold, hidden_by_text = {}, {}
  for _, row in ipairs(VRFW.table.raw(VRFW.table_files.file_name(SHOP_TABLE), SHOP_ROWS, { SHOP_ITEM, SHOP_CONDITION })) do
    local text = row[SHOP_CONDITION]
    local hidden = false
    if type(text) == "string" then
      if hidden_by_text[text] == nil then
        hidden_by_text[text] = Shop.hidden(text)
      end
      hidden = hidden_by_text[text]
    end
    if not hidden and type(row[SHOP_ITEM]) == "number" then
      sold[VRFW.ids.unsigned(row[SHOP_ITEM])] = true
    end
  end
  return sold
end

return Shop
