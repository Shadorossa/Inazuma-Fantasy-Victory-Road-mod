-- Chronicle Deluxe: the class menu of a free match pachanga. The free match list opens this menu for a pachanga with the
-- parameter ChronicleDeluxe.FreeMatchPachangaClass set; deciding a class then writes that class into the parameter and
-- closes the menu, and the list starts the pachanga at it (soccer_vs_cpu_list_menu\300_free_match_pachanga.lua).
do
  local CLASS = "ChronicleDeluxe.FreeMatchPachangaClass"
  local CARD = VRFW.ids.crc32("vsroute01_21_sub_list")           -- the class cards
  local MENU = VRFW.ids.crc32("soccer_vs_cpu_class_select_menu")
  VRFW.host.wrap_once("OnDecideFocus", "ChronicleDeluxe.free_match_pachanga_class", function(decide, a1, a2, ...)
    if a1 ~= CARD or type(a2) ~= "number" or not VRFW.param.has(CLASS) then return decide(a1, a2, ...) end
    local classes = VRFW.free_match_classes
    VRFW.param.replace(CLASS, 6 + classes.cls(classes.game, a2))   -- The card's class, as the retail decide reads it.
    funcLuaMenuCommand(1558704558, MENU, false)
    funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, MENU)
  end)
end
