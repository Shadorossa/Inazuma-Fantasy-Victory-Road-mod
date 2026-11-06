-- Guarded game memory access for a mod script: every function answers nil / false on a bad address or a failed
-- read, and never raises. An address is good when it is a number >= 0x10000 (the lowest 64 KiB are never mapped).
--   local Memory = require "VRFW/lib/memory"   -- any mod's scripts (the framework's own: require "lib/memory")
--   Memory.read_memory(type, address)          -> VRFW.mem.read(type, address), nil on a bad address or a failed read
--   Memory.read_number(type, address)          -> as read_memory, nil when the value read is not a number
--   Memory.read_pointer(address)               -> the pointer stored at address, nil unless it is a good address
--   Memory.write_memory(type, address, value)  -> true when VRFW.mem.write succeeded; false on a bad address or a failure
--   Memory.struct_view(name, address)          -> VRFW.mem.struct(name, address), nil on a bad address or a failure
--   Memory.struct_field(view, name)            -> view[name] of a struct view, nil when there is no view or the read fails
--   Memory.game_global(name)                   -> the pointer VRFW.game[name]() answers, nil unless it is a good address
--   Memory.is_address(v)                       -> true when v is a good address
-- Requiring it also sets VRFW.memory to the same table in that script's VM.
local LOWEST_ADDRESS = 0x10000

local M = {}

function M.is_address(v)
  return type(v) == "number" and v >= LOWEST_ADDRESS
end

function M.read_memory(type_name, address)
  if not M.is_address(address) then
    return nil
  end
  local ok, value = pcall(VRFW.mem.read, type_name, address)
  if ok then
    return value
  end
  return nil
end

function M.read_number(type_name, address)
  local value = M.read_memory(type_name, address)
  if type(value) == "number" then
    return value
  end
  return nil
end

function M.read_pointer(address)
  local value = M.read_memory("ptr", address)
  if M.is_address(value) then
    return value
  end
  return nil
end

function M.write_memory(type_name, address, value)
  if not M.is_address(address) then
    return false
  end
  return (pcall(VRFW.mem.write, type_name, address, value))
end

function M.struct_view(name, address)
  if not M.is_address(address) then
    return nil
  end
  local ok, view = pcall(VRFW.mem.struct, name, address)
  if ok then
    return view
  end
  return nil
end

function M.struct_field(view, name)
  if not view then
    return nil
  end
  local ok, value = pcall(function()
    return view[name]
  end)
  if ok then
    return value
  end
  return nil
end

function M.game_global(name)
  local ok, address = pcall(function()
    return VRFW.game[name]()
  end)
  if ok and M.is_address(address) then
    return address
  end
  return nil
end

if type(VRFW) == "table" and rawget(VRFW, "memory") == nil then
  pcall(rawset, VRFW, "memory", M)
end

return M
