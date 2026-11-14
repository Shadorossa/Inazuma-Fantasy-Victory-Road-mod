-- The team dock: the team made active gets its players' values back (VRFW.team_loadout).
if VRFW.host ~= nil and VRFW.team_loadout ~= nil then
  local STEM = "soccer_team_dock_menu"
  local seen = nil

  VRFW.host.on(STEM, "OnInit", {id = "VRFW.team_loadout", phase = "after", fn = function()
    seen = VRFW.team_loadout.active_set()
    VRFW.team_loadout.sync("team dock")
  end})

  -- The retail dock redraws its active background after the active team changes.
  VRFW.host.on(STEM, "SetActiveDockBackground", {id = "VRFW.team_loadout", phase = "after", fn = function()
    local now = VRFW.team_loadout.active_set()
    if now ~= nil and now ~= seen then
      seen = now
      VRFW.team_loadout.sync("active team")
    end
  end})
end
