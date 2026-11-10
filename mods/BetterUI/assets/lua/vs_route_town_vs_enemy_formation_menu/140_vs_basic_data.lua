if VRFW.host ~= nil and BetterUI ~= nil and BetterUI.vs_basic_data ~= nil then
  local V = BetterUI.vs_basic_data

  VRFW.host.on("vs_route_town_vs_enemy_formation_menu", "OnInit", {
    id = "BetterUI.vs_basic_data_open", phase = "before",
    fn = function()
      V.last = nil
    end,
  })

  VRFW.host.on("vs_route_town_vs_enemy_formation_menu", "SetFormation", {
    id = "BetterUI.vs_basic_data_draw", phase = "around",
    fn = function(nxt, ...)
      return V.draw(nxt, ...)
    end,
  })

  VRFW.host.on("vs_route_town_vs_enemy_formation_menu", "UpdateNicknameButtonText", {
    id = "BetterUI.vs_basic_data_pill", phase = "around",
    fn = function()
      V.update_pill()
    end,
  })

  VRFW.host.on("vs_route_town_vs_enemy_formation_menu", "SwitchNickname", {
    id = "BetterUI.vs_basic_data_switch", phase = "around",
    fn = function()
      V.update_pill()
      V.redraw()
    end,
  })
end
