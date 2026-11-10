
local M = {}

local BITS = nil
--- The attribute bits mods protect, as an array.
function M.bits()
  if BITS then return BITS end
  BITS = {}
  local ok, files = pcall(VRFW.files.declarations, "content/protected_attributes")
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local data = type(f.data) == "table" and f.data or {}
    local list = type(data.VRFW) == "table" and data.VRFW.ProtectedAttribute or nil
    for _, d in ipairs(type(list) == "table" and list or {}) do
      local bit = type(d) == "table" and tonumber(d.bit) or nil
      if bit and bit >= 1 and bit <= 0xFFFFFFFF and bit == math.floor(bit) then
        BITS[#BITS + 1] = { key = tostring(f.mod) .. "." .. tostring(d.name), bit = bit }
      end
    end
  end
  return BITS
end

local function has_bit(v, bit) return math.floor(v / bit) % 2 == 1 end

--- True when `attribute` holds a protected bit.
function M.has_any(attribute)
  attribute = tonumber(attribute) or 0
  for _, b in ipairs(M.bits()) do
    if has_bit(attribute, b.bit) then return true end
  end
  return false
end

return M
