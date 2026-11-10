if VRFW.host ~= nil then
  local STEM = "soccer_team_dock_menu"

  local function editor()
    local E = VRFW.team_editor
    return type(E) == "table" and type(E.scene_open) == "function" and E or nil
  end

  VRFW.host.on(STEM, "OnInit", {
    id = "menu_engine.team_editor_scene", phase = "before", priority = -2000,
    fn = function()
      local E = editor()
      if E then E.scene_open() end
    end,
  })

  VRFW.host.on(STEM, "FuncOnBack", {
    id = "menu_engine.team_editor_scene", phase = "around", priority = -2000,
    fn = function(nxt, ...)
      local E = editor()
      if E and E.scene_leave() then
        return 1
      end
      return nxt(...)
    end,
  })

  VRFW.host.on(STEM, "Step", {
    id = "menu_engine.team_editor_scene", phase = "after",
    fn = function()
      local E = editor()
      if E then E.scene_step() end
    end,
  })
end
