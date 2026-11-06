-- Signature Passives › a passive's own buff icon (content\passive_icons\*.toml): the passive windows draw it in their buff
-- icon slot instead of the buff icon of the game passive behind it (every signature passive card is a copy of
-- ps10020, so the game would draw the same boot for all of them).
--   * every passive detail window filled by the game's UpdateSixSenseDetailInfo (team00_26_passive_slot_detail_info:
--     the skill board's window, Character Reforged's skill table): wrapped once per VM, the icon is drawn right after
--     the game's fill;
--   * the player page's custom passive page asks PersonalPassives_Icon.Draw itself (include soccer_common).
-- A passive without a declared icon keeps the game's. Definitions and the wrap only at load (no engine call).
PersonalPassives_Icon = type(PersonalPassives_Icon) == "table" and PersonalPassives_Icon or {}
local I = PersonalPassives_Icon

I.PASSIVE_ICON = 4227343560     -- CMND_PERSONALPASSIVES_PASSIVE_ICON (game passive id) -> sprite crc (0 = none)
I.SPRITE = 558735651            -- (layer, texture, sprite, slot, 0, idx)
I.IS_EXIST_LAYER = 262659071    -- CMND_IS_EXIST_LAYER (layer)
I.TEAMBUFF_TEX = 2301895383     -- #/menu/200_icon/08_icon_teambuff/<LG>/icon_teambuff.g4tx
I.BUFF_SLOT = 1780336175        -- the buff icon slot of the passive windows (UpdateSixSenseDetailInfo,
                                -- SwapSixSenseSkillEffectIcon)
I.DETAIL = 1593383077           -- team00_26_passive_slot_detail_info
I.cache = I.cache or {}         -- [passive id] = sprite crc (0 = none), asked once per VM

-- the passive's own icon (sprite crc), nil when it has none
function I.Of(passive)
  if type(passive) ~= "number" or passive == 0 then
    return nil
  end
  local sprite = I.cache[passive]
  if sprite == nil then
    local ok, got = pcall(funcLuaCommand, I.PASSIVE_ICON, passive)
    sprite = (ok and type(got) == "number") and got or 0
    I.cache[passive] = sprite
  end
  return sprite ~= 0 and sprite or nil
end

-- draws the passive's own icon in the buff icon slot of layer instance idx; false when it has none
function I.Draw(layer, idx, passive)
  local sprite = I.Of(passive)
  if sprite == nil or not funcLuaMenuCommand(I.IS_EXIST_LAYER, layer) then
    return false
  end
  funcLuaMenuCommand(I.SPRITE, layer, I.TEAMBUFF_TEX, sprite, I.BUFF_SLOT, 0, idx or 0)
  return true
end

local detail = rawget(_ENV, "UpdateSixSenseDetailInfo")
if type(detail) == "function" and rawget(_ENV, "PERSONALPASSIVES_ICON_DETAIL") ~= detail then
  local wrapped = function(idx, passive, ...)
    local result = table.pack(detail(idx, passive, ...))
    pcall(I.Draw, I.DETAIL, idx, passive)
    return table.unpack(result, 1, result.n)
  end
  rawset(_ENV, "UpdateSixSenseDetailInfo", wrapped)
  rawset(_ENV, "PERSONALPASSIVES_ICON_DETAIL", wrapped)
end
