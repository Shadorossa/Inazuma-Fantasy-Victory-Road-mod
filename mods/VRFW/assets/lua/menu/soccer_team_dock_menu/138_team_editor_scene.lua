-- menu_engine: the team dock (soccer_team_dock_menu) as the root of a VRFW_TeamEditor scene (lua\_all\81_team_editor.lua
-- E.Scene, docs/framework/team-editor.md): at its OnInit the owner's team fills the dock inside a save session; its
-- Back (FuncOnBack, also the team page's L1 / R1) reads the dock, ends the session and resets straight into the owner's
-- menu instead of the retail save and reset to the title. A dock that is no scene's root runs as retail. Definitions
-- only; no engine call at load.
if VRFW_Host ~= nil then
  local STEM = "soccer_team_dock_menu"

  local function editor()
    local E = VRFW_TeamEditor
    return type(E) == "table" and type(E.SceneOpen) == "function" and E or nil
  end

  -- before every other OnInit handler (the foreign team mode reads its parameters there)
  VRFW_Host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_scene", phase = "before", priority = -2000,
    fn = function()
      local E = editor()
      if E then E.SceneOpen() end
    end,
  })

  VRFW_Host.on(STEM, "FuncOnBack", {
    id = "menu_engine.team_editor_scene", phase = "around", priority = -2000,
    fn = function(nxt, ...)
      local E = editor()
      if E and E.SceneLeave() then
        return 1
      end
      return nxt(...)
    end,
  })

  VRFW_Host.on(STEM, "Step", {
    id = "menu_engine.team_editor_scene", phase = "after",
    fn = function()
      local E = editor()
      if E then E.SceneStep() end
    end,
  })
end
