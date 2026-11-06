-- Signature Passives › the player page's custom passive page (team00_28_six_sense_detail_info, filled by the game's
-- UpdateSixSenseLayerInfo from the item in the custom passive slot): a player with an own passive shows it there, as
-- the skill boards' window shows it: its name in the title bar, its effect lines in the panel, its effect icon
-- (PersonalPassives_Display, assets\lua\_all) and its own buff icon (PersonalPassives_Icon). A player without
-- one keeps the game's page.
-- Wraps UpdateSixSenseLayerInfo right after the game's fill; no engine call at load time; wrapped again when the
-- include runs again.
PersonalPassives_Page = type(PersonalPassives_Page) == "table" and PersonalPassives_Page or {}
local P = PersonalPassives_Page

P.IS_EXIST_LAYER = 262659071    -- CMND_IS_EXIST_LAYER (layer)
P.LOCATOR_VISIBLE = 2158717427  -- (layer, locator, visible, idx)
P.SET_TEXT = 1083631230         -- CMND_SET_MENU_TEXT_STRING (layer, node, text, idx)
P.TEXT_VISIBLE = 1505208242     -- (layer, text node, visible, idx)
P.ANIME = 3781155141            -- (layer, idx, animation, frame)
P.CONTENT = 1517329426          -- _pos_base01: the filled page
P.EMPTY = 2020757070            -- the empty page
P.TITLE = 4098766424            -- the title bar's text
P.EFFECT = 691026122            -- _text_flavor01
P.PAGE_ANIME = 2274335502       -- the page's state animation (frame 2 = open slot)

-- the page (layer, instance 0) of the player hdl, when he has an own passive
function P.Fill(layer, hdl)
  if type(hdl) ~= "number" or hdl == 0 or type(PersonalPassives_Display) ~= "table" then
    return
  end
  local display = PersonalPassives_Display.Of(hdl)
  if display == nil or not funcLuaMenuCommand(P.IS_EXIST_LAYER, layer) then
    return
  end
  funcLuaMenuCommand(P.LOCATOR_VISIBLE, layer, P.CONTENT, true, 0)
  funcLuaMenuCommand(P.LOCATOR_VISIBLE, layer, P.EMPTY, false, 0)
  funcLuaMenuCommand(P.SET_TEXT, layer, P.TITLE, display.name, 0)
  funcLuaMenuCommand(P.SET_TEXT, layer, P.EFFECT, display.effect, 0)
  funcLuaMenuCommand(P.TEXT_VISIBLE, layer, P.EFFECT, true, 0)
  if type(SwapSixSenseSkillEffectIcon) == "function" then
    SwapSixSenseSkillEffectIcon(layer, 0, display.effect_id)
  end
  if type(PersonalPassives_Icon) == "table" then   -- the passive's own buff icon (assets\lua\_all)
    PersonalPassives_Icon.Draw(layer, 0, display.passive)
  end
  funcLuaMenuCommand(P.ANIME, layer, 0, P.PAGE_ANIME, 2)
end

if type(rawget(_ENV, "UpdateSixSenseLayerInfo")) == "function" and UpdateSixSenseLayerInfo ~= P.wrapper then
  local previous = UpdateSixSenseLayerInfo
  P.wrapper = function(layer, hdl, item, ...)
    local result = table.pack(previous(layer, hdl, item, ...))
    -- an explicit item (a3) is that item's page, not the player's slot
    if item == nil or item == 0 then
      pcall(P.Fill, layer, hdl)
    end
    return table.unpack(result, 1, result.n)
  end
  UpdateSixSenseLayerInfo = P.wrapper
end
