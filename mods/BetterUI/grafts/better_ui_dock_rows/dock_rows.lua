-- The team dock list without the team settings (kind 12) and formation (kind 0) rows, applied by the dock's row service
-- each time the dock opens, together with every other mod's rows.
if VRFW.team_dock ~= nil and VRFW.team_dock.half_rows ~= nil then
  VRFW.team_dock.half_rows.add({ id = "BetterUI.dock_rows", remove = { 12, 0 } })
end
