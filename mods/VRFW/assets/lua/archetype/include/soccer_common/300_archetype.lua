
VRFW.archetype = VRFW.archetype or {}
local A = VRFW.archetype
A.CMD_INFO = A.CMD_INFO or 3552358290   -- CMND_VRFW_ARCHETYPE_INFO

local function info_icon(n)
  if type(n) ~= "number" or n < 7 then return nil end
  local has, _, _, icon = VRFW.host.command(A.CMD_INFO, n)
  if has == true and type(icon) == "number" and icon ~= 0 then return icon end
  return nil
end

if type(GeTeamBuffBuildTypeIconTextureName) == "function" and GeTeamBuffBuildTypeIconTextureName ~= A.small_icon then
  local orig = GeTeamBuffBuildTypeIconTextureName
  A.small_icon = function(a1, ...)
    local icon = info_icon(a1)
    if icon then return icon end
    return orig(a1, ...)
  end
  GeTeamBuffBuildTypeIconTextureName = A.small_icon
end
