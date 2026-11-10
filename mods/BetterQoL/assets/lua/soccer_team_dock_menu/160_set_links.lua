-- The team dock writes the linked player sets of the team made active (BetterQoL.set_links).
if VRFW.host ~= nil then
  local STEM = "soccer_team_dock_menu"
  local seen = nil

  VRFW.host.on(STEM, "OnInit", {id = "BetterQoL.set_links", phase = "after", fn = function()
    seen = BetterQoL.set_links.active_dock()
  end})

  -- the retail dock redraws its active background after the active team changes
  VRFW.host.on(STEM, "SetActiveDockBackground", {id = "BetterQoL.set_links", phase = "after", fn = function()
    local now = BetterQoL.set_links.active_dock()
    if now ~= nil and now ~= seen then
      seen = now
      BetterQoL.set_links.apply_active("active team")
    end
  end})
end
