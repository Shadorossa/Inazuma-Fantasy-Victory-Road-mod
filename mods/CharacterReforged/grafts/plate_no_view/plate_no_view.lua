-- ===== EVT plate no view BEGIN =====
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.PLATE_NO_VIEW == nil then
  CharacterReforged.PLATE_NO_VIEW = true
end
if CharacterReforged.PLATE_NO_VIEW_WRAPPED == nil then
  CharacterReforged.PLATE_NO_VIEW_WRAPPED = {}
end
if type(GetSelectSettingTypeOrderList) == "function" and not CharacterReforged.PLATE_NO_VIEW_WRAPPED[GetSelectSettingTypeOrderList] then
  local wrappedList = GetSelectSettingTypeOrderList
  CharacterReforged.plate_no_view_orig_list = wrappedList
  function GetSelectSettingTypeOrderList(...)
    local src = wrappedList(...)
    if CharacterReforged.PLATE_NO_VIEW ~= true or type(src) ~= "table" then
      return src
    end
    local out = {}
    for i = 1, #src do
      if src[i] ~= 4 then
        out[#out + 1] = src[i]
      end
    end
    return out
  end
  CharacterReforged.PLATE_NO_VIEW_WRAPPED[GetSelectSettingTypeOrderList] = true
end
-- ===== EVT plate no view END =====
