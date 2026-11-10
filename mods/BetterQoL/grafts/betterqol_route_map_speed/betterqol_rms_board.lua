if VRFW.footer_prompts ~= nil then
  VRFW.footer_prompts.add({
    name = "BetterQoL.RouteMapSpeed",
    menu = "vs_route_town_menu",
    text = 2217037856,      -- menu_text of the game: the Players' Universe speed-up prompt
    icon = 3487556099,      -- <CMD_FUNCR2> (pad R2, keyboard E)
    command = 2704260807,   -- CMD_FUNCR2
    order = 100,
    when = 3642518977,
  })
end
