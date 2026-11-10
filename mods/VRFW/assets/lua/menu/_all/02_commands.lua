if VRFW.crc32 == nil then
  local band, bxor, rshift = bit32.band, bit32.bxor, bit32.rshift
  local byte = string.byte

  --- CRC-32 of text as an unsigned 32-bit number.
  function VRFW.crc32(text)
    local crc = 0xFFFFFFFF
    for i = 1, #text do
      crc = bxor(crc, byte(text, i))
      for _ = 1, 8 do
        if band(crc, 1) ~= 0 then
          crc = bxor(rshift(crc, 1), 0xEDB88320)
        else
          crc = rshift(crc, 1)
        end
      end
    end
    return bxor(crc, 0xFFFFFFFF)
  end
end

if VRFW.commands == nil then
  local Crc32 = VRFW.crc32

  VRFW.commands = setmetatable({}, {
    __index = function(ids, name)
      if type(name) ~= "string" then
        return nil
      end
      local id = Crc32("CMND_" .. name)
      rawset(ids, name, id)
      return id
    end,
  })
end

if rawget(VRFW.commands, "PARAM_HAS") == nil then
  rawset(VRFW.commands, "PARAM_HAS", 2947612279)
  rawset(VRFW.commands, "PARAM_GET", 3522198769)
  rawset(VRFW.commands, "PARAM_SET", 3860611758)
  rawset(VRFW.commands, "PARAM_DELETE", 3363400568)
end
