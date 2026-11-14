CharacterReforged_PassiveIcon = type(CharacterReforged_PassiveIcon) == "table" and CharacterReforged_PassiveIcon or {}
local I = CharacterReforged_PassiveIcon

I.PASSIVE_ICON = 1201351532     -- CMND_CHARACTERREFORGED_PASSIVE_ICON (passive id) -> sprite crc
I.SPRITE = 558735651            -- (layer, texture, sprite, slot, 0, idx)
I.IS_EXIST_LAYER = 262659071    -- CMND_IS_EXIST_LAYER (layer)
I.TEAMBUFF_TEX = 2301895383     -- #/menu/200_icon/08_icon_teambuff/<LG>/icon_teambuff.g4tx
I.BUFF_SLOT = 1780336175
I.DETAIL = 1593383077           -- team00_26_passive_slot_detail_info
I.cache = I.cache or {}         -- [passive id] = sprite crc (0 = none), asked once per VM

-- the passive's own icon (sprite crc), nil when it has none
function I.of(passive)
  if type(passive) ~= "number" or passive == 0 then
    return nil
  end
  local sprite = I.cache[passive]
  if sprite == nil then
    local got = VRFW.host.command(I.PASSIVE_ICON, passive)
    sprite = (type(got) == "number") and got or 0
    I.cache[passive] = sprite
  end
  return sprite ~= 0 and sprite or nil
end

function I.draw(layer, idx, passive)
  local sprite = I.of(passive)
  if sprite == nil or not funcLuaMenuCommand(I.IS_EXIST_LAYER, layer) then
    return false
  end
  funcLuaMenuCommand(I.SPRITE, layer, I.TEAMBUFF_TEX, sprite, I.BUFF_SLOT, 0, idx or 0)
  return true
end

local detail = rawget(_ENV, "UpdateSixSenseDetailInfo")
if type(detail) == "function" and rawget(_ENV, "CHARACTERREFORGED_PASSIVE_ICON_DETAIL") ~= detail then
  local wrapped = function(idx, passive, ...)
    local result = table.pack(detail(idx, passive, ...))
    pcall(I.draw, I.DETAIL, idx, passive)
    return table.unpack(result, 1, result.n)
  end
  rawset(_ENV, "UpdateSixSenseDetailInfo", wrapped)
  rawset(_ENV, "CHARACTERREFORGED_PASSIVE_ICON_DETAIL", wrapped)
end
