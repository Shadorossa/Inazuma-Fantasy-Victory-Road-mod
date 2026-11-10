-- The pre-match formation screen writes the active team's linked player sets before the match loads.
if VRFW.host ~= nil then
  VRFW.host.on("soccer_battle_setting_flow_formation_menu", "OnInit", {id = "BetterQoL.set_links", phase = "before",
    fn = function()
      BetterQoL.set_links.apply_active("pre-match")
    end})
end
