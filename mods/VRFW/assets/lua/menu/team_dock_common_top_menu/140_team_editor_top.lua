if VRFW.host ~= nil then
  VRFW.host.on("team_dock_common_top_menu", "SetVisibleHeaderTeamDoc", {
    id = "menu_engine.team_editor_top_dock_line", phase = "around",
    fn = function(nxt, shown, ...)
      if shown and type(VRFW.team_editor) == "table" and VRFW.team_editor.foreign() ~= nil then
        return nxt(false, ...)
      end
      return nxt(shown, ...)
    end,
  })
end
