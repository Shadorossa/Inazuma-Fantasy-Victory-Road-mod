-- a piece's crest on the board (vs_route_town_menu) and on each row of the team list
ChronicleDeluxe = ChronicleDeluxe or {}
ChronicleDeluxe.orb_bar = ChronicleDeluxe.orb_bar or {}
local O = ChronicleDeluxe.orb_bar
O.CMD = {
  NODE_TRANSLATION = 1856671416,  -- (layer, instance, node, x, y, z)
  NODE_SCALE = 2885415772,        -- (layer, instance, node, width, height): a quad's size in px
  LOCATOR_VISIBLE = 2158717427,   -- (layer, locator, visible, instance)
  SET_SPRITE = 558735651,         -- (layer, atlas, sprite, texture slot, 0, instance)
}
O.ATLAS = "#/menu/30_vsroute/vsroute01/vsroute01_06c/vsroute01_06c.g4tx"
O.SPRITE_PREFIX = "chronicle_deluxe_orb_bar_"
O.SPACING = 18                    -- px between two sockets (retail layout)
-- Layout per eventType of the piece (0 normal, 5 gate).
O.LAYOUT = {
  [0] = {context = "route", base = 1003654013 --[[_clear_base01]], sprite = "clear_base01_02", width = 124, height = 32,
         base_y = -17, dot_y = -33, slots = 6},
  [5] = {context = "gate", base = 2732317383 --[[_clear_base02]], sprite = "clear_base02_2", width = 68, height = 32,
         base_y = -40, dot_y = -56, slots = 3},
}

function O.fit(layer, instance, kind, difficulties, locators)
  local lay = O.LAYOUT[kind]
  if lay == nil or difficulties == nil or locators == nil or VRFW.match_difficulty == nil then
    return
  end
  local shown = VRFW.match_difficulty.set(lay.context)
  if shown == nil then
    return -- nothing declared: the retail bar
  end
  local kept = {}
  for i = 1, #difficulties do
    if locators[i] ~= nil then
      if shown[difficulties[i]] then
        kept[#kept + 1] = locators[i]
      else
        funcLuaMenuCommand(O.CMD.LOCATOR_VISIBLE, layer, locators[i], false, instance)
      end
    end
  end
  local count = #kept
  if count == 0 or count > lay.slots then
    return
  end
  local first = -(count - 1) * O.SPACING / 2
  for k = 1, count do
    funcLuaMenuCommand(O.CMD.NODE_TRANSLATION, layer, instance, kept[k], first + (k - 1) * O.SPACING, lay.dot_y, 0)
  end
  local sprite = count == lay.slots and lay.sprite or (O.SPRITE_PREFIX .. lay.context .. "_" .. count)
  local width = lay.width - O.SPACING * (lay.slots - count)
  funcLuaMenuCommand(O.CMD.SET_SPRITE, layer, CRC32(O.ATLAS), CRC32(sprite), CRC32(lay.sprite), 0, instance)
  funcLuaMenuCommand(O.CMD.NODE_SCALE, layer, instance, lay.base, width, lay.height)
  funcLuaMenuCommand(O.CMD.NODE_TRANSLATION, layer, instance, lay.base, -width / 2, lay.base_y, 0)
end
