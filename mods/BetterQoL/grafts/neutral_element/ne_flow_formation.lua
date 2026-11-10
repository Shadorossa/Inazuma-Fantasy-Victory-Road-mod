local BETTERQOL_NE_prev_GetCharaElementIconName = GetCharaElementIconName
function GetCharaElementIconName(a1, ...)
  local r = BETTERQOL_NE_prev_GetCharaElementIconName(a1, ...)
  if r == 0 and a1 ~= nil and a1 ~= 0 then
    local el = funcLuaCommand(1131797651, a1, 8)
    if el == 0 or el == 5 then
      return @crc:icon_cmd_type00@
    end
  end
  return r
end
