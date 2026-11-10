-- version_label (VRFW base feature): the title screen's version label reads "ver.7.2.1  Framework 3.0".

local VL = {
  VERSION = VRFW.commands.VRFW_VERSION,   -- CMND_VRFW_VERSION () -> "3.0"
  GET_XY = 1619246457,
  GET_Z = 1691080945,
  parts = nil,            -- {x, yy, z} once read; false = no framework version (retail)
}

local function VL_Parts()
  if VL.parts == nil then
    VL.parts = false
    local v = VRFW.host.command(VL.VERSION)
    if type(v) == "string" then
      local a, b, c = string.match(v, "^%s*(%d+)%.(%d+)%.?(%d*)")
      if a ~= nil then
        local two_parts = c == ""
        a, b, c = tonumber(a), tonumber(b), tonumber(c) or 0
        local yy = math.min(b, 99)
        if not two_parts and b < 10 and c < 10 then
          yy = b * 10 + c
        end
        VL.parts = { x = math.min(a, 9), yy = yy, z = math.min(c, 999) }
      end
    end
  end
  return VL.parts
end

if VRFW.host ~= nil and type(OnOpenLayer) == "function" then
  VRFW.host.on("title_menu_2", "OnOpenLayer", {
    id = "menu_engine.version_label", phase = "around",
    fn = function(nxt, ...)
      local p = VL_Parts()
      if not p then
        return nxt(...)
      end
      local cmd = funcLuaCommand
      funcLuaCommand = function(c, ...)
        if c == VL.GET_XY then
          return p.x, p.yy
        elseif c == VL.GET_Z then
          return p.z
        end
        return cmd(c, ...)
      end
      local r = table.pack(pcall(nxt, ...))
      funcLuaCommand = cmd
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })
end
