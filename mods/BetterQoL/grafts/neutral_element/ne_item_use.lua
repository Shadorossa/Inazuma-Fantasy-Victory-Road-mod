local BETTERQOL_NE_prev_GetElementIcon = GetElementIcon
function GetElementIcon(a1, ...)
  if a1 == 0 or a1 == 5 then
    return @crc:icon_cmd_type00@
  end
  return BETTERQOL_NE_prev_GetElementIcon(a1, ...)
end
