local BETTERQOL_NE_prev_FilterUpdateItem = UpdateItem
local BETTERQOL_NE_FILTER_NEUTRAL_TEXT = 3339176265
function UpdateItem(a1, a2, a3, a4, a5)
  local r = table.pack(BETTERQOL_NE_prev_FilterUpdateItem(a1, a2, a3, a4, a5))
  if a3 == 4 and a4 == 5 then
    local label = funcLuaCommand(@crc:CMND_TEXT_GET@, BETTERQOL_NE_FILTER_NEUTRAL_TEXT)
    if type(label) ~= "string" then
      label = ""
    end
    funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, a1, 1704438437 --[[_text_name01]], " [$gaiji_cmd_type00]   [CMODE02]" .. label .. "[C]", a2)
  end
  return table.unpack(r, 1, r.n)
end
