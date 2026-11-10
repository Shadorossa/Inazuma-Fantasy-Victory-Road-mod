if VRFW.host ~= nil then
  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateFormation", {
    id = "BetterUI.free_match_class_plate", phase = "after",
    fn = function(r, a1)
      if a1 ~= nil and a1 ~= 0 then
        VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, 1835074715 --[[mainmenu90_34_cpu_team_formation]],
          126765991 --[[_cpu_icon_class_dmy01]], false, 0)
      end
    end,
  })
end
