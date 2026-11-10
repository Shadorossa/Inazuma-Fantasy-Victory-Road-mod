-- ===== VRFW vrfw_announce_item_name BEGIN ===== Convert mode for the <ITEM_NAME> placeholder of an item
function VRFW.item_name_convert_mode(itemId, defaultMode)
  local cat = funcLuaCommand(@crc:CMND_GET_ITEM_PARAM@, itemId, 2)
  local sub = funcLuaCommand(@crc:CMND_GET_ITEM_PARAM@, itemId, 3)
  if cat == 160 and sub ~= 177 then
    return 155
  end
  return defaultMode
end
-- ===== VRFW vrfw_announce_item_name END =====
