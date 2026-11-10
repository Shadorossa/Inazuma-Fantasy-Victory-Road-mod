local BETTERQOL_NE_prev_GetElementIconTextureName = GetElementIconTextureName
function GetElementIconTextureName(a1, ...)
  local r = BETTERQOL_NE_prev_GetElementIconTextureName(a1, ...)
  if r == 0 and a1 ~= nil and a1 ~= 0 then
    local ok, el = funcLuaCommand(@crc:CMND_GET_CHARA_INFO@, a1, 13)
    if ok and (el == 0 or el == 5) then
      return @crc:icon_cmd_type00@
    end
  end
  return r
end
