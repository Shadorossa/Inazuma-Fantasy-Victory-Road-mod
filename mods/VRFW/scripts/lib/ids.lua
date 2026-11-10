-- The one way to read a game id (a crc, a chara_param, a handle) as a number in a mod script.
local TWO_32 = 4294967296
local TWO_31 = 2147483648
local MAX_U32 = TWO_32 - 1

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

local M = {}

--- `v` as an unsigned 32-bit id; `none` when it is not a number.
function M.unsigned_or(v, none)
  local n = number_of(v)
  if n == nil then
    return none
  end
  return math.floor(n) % TWO_32
end

--- `v` as an unsigned 32-bit id (0 when it is not a number).
function M.unsigned(v)
  return M.unsigned_or(v, 0)
end

--- `v` as a signed 32-bit number.
function M.signed(v)
  local n = M.unsigned(v)
  if n >= TWO_31 then
    return n - TWO_32
  end
  return n
end

--- True when `v` means no id (nil, -1 or the unsigned -1).
function M.is_none(v)
  if v == nil then
    return true
  end
  local n = number_of(v)
  return n == -1 or n == TWO_32 - 1
end

--- The hex text of id `v`.
function M.hex_text(v)
  local n = M.unsigned(v)
  return string.format("0x%04X%04X", math.floor(n / 65536), n % 65536)
end

-- a whole number in -2^31..2^32-1 -> its u32; nil otherwise (fractions, NaN, infinities, more than 32 bits)
local function whole_id(n)
  if n ~= math.floor(n) or n < -TWO_31 or n > MAX_U32 then
    return nil
  end
  return n % TWO_32
end

-- digits of one class with single "_" between them -> the digits alone; nil when written otherwise
local function digits_of(s, class)
  if s == "" or s:find("^_") or s:find("_$") or s:find("__", 1, true) or s:find("[^" .. class .. "_]") then
    return nil
  end
  return (s:gsub("_", ""))
end

--- A number, "0x..." or decimal text as an id; other text is its crc32 when `options.hash_names` is set.
function M.parse(v, options)
  local t = type(v)
  if t == "number" then
    return whole_id(v)
  end
  if t ~= "string" then
    return nil
  end
  local s = v:match("^%s*(.-)%s*$")
  if s == "" then
    return nil
  end
  local hex = s:match("^0[xX](.*)$")
  if hex ~= nil then
    local digits = digits_of(hex, "%x")
    if digits ~= nil then
      return whole_id(tonumber(digits, 16))
    end
  else
    local sign, decimal = s:match("^(%-?)(.*)$")
    local digits = digits_of(decimal, "%d")
    if digits ~= nil then
      local n = tonumber(digits)
      if sign == "-" then
        n = -n
      end
      return whole_id(n)
    end
  end
  if options ~= nil and options.hash_names then
    return M.unsigned(VRFW.crc32(s))
  end
  return nil
end

-- the id a framework resolver gives a key (0 or no answer = unknown), else Id.parse(ref, options)
local function resolved(resolver_name, ref, options)
  local resolver = type(VRFW) == "table" and VRFW[resolver_name] or nil
  if type(ref) == "string" and ref ~= "" and resolver ~= nil then
    local ok, id = pcall(resolver, ref)
    local n = ok and (type(id) == "number" or type(id) == "string") and M.unsigned_or(id, nil) or nil
    if n ~= nil and n ~= 0 then
      return n
    end
  end
  return M.parse(ref, options)
end

--- The chara_base id of `ref`.
function M.character(ref, options)
  return resolved("character", ref, options)
end

--- The move id of `ref`.
function M.technique(ref, options)
  return resolved("technique", ref, options)
end

return M
