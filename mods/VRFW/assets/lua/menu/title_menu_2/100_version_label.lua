-- version_label (VRFW base feature): the title screen's version label reads «ver.7.2.1  Framework 3.0».
-- (handler of the title_menu_2 host).
--
-- Retail label (layer title02_04_version / _ps, opened by OnOpenLayer): «ver.A.B.C  X.YY ZZZ», six bitmap-number
-- primitives and no text node. A.B.C = the game version (funcLuaCommand 3113844068, kept as the game prints it),
-- X.YY = 1619246457 (1 digit . up to 2 digits, bitmap numbers are not zero-padded), ZZZ = 1691080945 (3 digits). The framework's menus\title_version.toml moves
-- the pieces (ZZZ off screen) and adds the word «Framework» (layer evt_vrfw_title_word, pure data); this handler
-- answers the X.YY getter with the framework version (CMND_VRFW_VERSION, the DLL's string = mod.toml `version`)
-- while the retail OnOpenLayer runs:
--   MAJOR.MINOR (two parts)        ->  X.YY = major . minor as written, no padding (max 99)   (3.0 -> «3.0», 3.1 -> «3.1», 3.10 -> «3.10»)
--   three parts, minor and patch < 10  ->  X.YY = major . minor*10+patch   (2.1.3 -> «2.13»)
--   three parts otherwise          ->  X.YY = major . minor (max 99)   (2.10.4 -> «2.10»)
-- The retail code still picks the layer, its primitives and their order: nothing here names a layer or primitive.
-- Without the framework DLL (command fails / no version) the getters answer as retail. No engine call at load time.

local VL = {
  VERSION = VRFW_Cmd.VRFW_VERSION,   -- CMND_VRFW_VERSION () -> "3.0"
  GET_XY = 1619246457,    -- retail getter of the X.YY pair (OnOpenLayer of the version layer)
  GET_Z = 1691080945,     -- retail getter of ZZZ (off screen; answered with the patch number)
  parts = nil,            -- {x, yy, z} once read; false = no framework version (retail)
}

local function VL_Parts()
  if VL.parts == nil then
    VL.parts = false
    local ok, v = pcall(funcLuaCommand, VL.VERSION)
    if ok and type(v) == "string" then
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

if VRFW_Host ~= nil and type(OnOpenLayer) == "function" then
  VRFW_Host.on("title_menu_2", "OnOpenLayer", {
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
