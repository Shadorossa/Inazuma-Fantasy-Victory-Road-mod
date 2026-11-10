if VRFW.host ~= nil and BetterUI ~= nil and BetterUI.vs_basic_data ~= nil then
  local V = BetterUI.vs_basic_data
  local SWITCH_FUNCTION = 3702644710      -- the X key's CMD_FUNCTION
  local TELL_RIVAL = 586982911

  VRFW.host.on("vs_route_town_vs_team_menu", "OnInit", {
    id = "BetterUI.vs_basic_data_open", phase = "before",
    fn = function()
      V.last = nil
      V.set_basic(false)
    end,
  })

  VRFW.host.on("vs_route_town_vs_team_menu", "SetFormation", {
    id = "BetterUI.vs_basic_data_draw", phase = "around",
    fn = function(nxt, ...)
      return V.draw(nxt, ...)
    end,
  })

  VRFW.host.on("vs_route_town_vs_team_menu", "OnFunction", {
    id = "BetterUI.vs_basic_data_switch", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= SWITCH_FUNCTION then
        return nxt(a1, ...)
      end
      V.set_basic(not V.is_basic())
      V.redraw()
      VRFW.host.menu_command(TELL_RIVAL)
    end,
  })
end
