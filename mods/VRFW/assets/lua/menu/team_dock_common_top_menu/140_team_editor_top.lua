-- menu_engine: the team screen top menu (team_dock_common_top_menu) under a VRFW_TeamEditor dock showing a foreign team:
-- its dock line and tournament icon stay hidden, they name the player's own team. Definitions only; no engine call at load.
if VRFW_Host ~= nil then
  VRFW_Host.on("team_dock_common_top_menu", "SetVisibleHeaderTeamDoc", {
    id = "menu_engine.team_editor_top_dock_line", phase = "around",
    fn = function(nxt, shown, ...)
      if shown and type(VRFW_TeamEditor) == "table" and VRFW_TeamEditor.Foreign() ~= nil then
        return nxt(false, ...)
      end
      return nxt(shown, ...)
    end,
  })
end
