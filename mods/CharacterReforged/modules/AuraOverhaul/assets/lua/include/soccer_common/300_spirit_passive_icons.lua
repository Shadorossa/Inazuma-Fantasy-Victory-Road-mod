
AuraOverhaul = AuraOverhaul or {}
AuraOverhaul.spirit_icons = AuraOverhaul.spirit_icons or {}
local S = AuraOverhaul.spirit_icons

if type(GeTeamBuffIconTextureName) == "function" and GeTeamBuffIconTextureName ~= S.icon_name then
  local orig = GeTeamBuffIconTextureName
  S.icon_name = function(icon_type, ...)
    local sprite = orig(icon_type, ...)
    if (sprite == nil or sprite == 0) and type(icon_type) == "number" and (icon_type < 0 or icon_type > 65535) then
      if icon_type < 0 then return icon_type + 4294967296 end
      return icon_type
    end
    return sprite
  end
  GeTeamBuffIconTextureName = S.icon_name
end
