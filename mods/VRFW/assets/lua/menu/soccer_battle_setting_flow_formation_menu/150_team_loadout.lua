-- The pre-match formation screen: the team that plays carries its own values before the match loads (VRFW.team_loadout).
if VRFW.host ~= nil and VRFW.team_loadout ~= nil then
  VRFW.host.on("soccer_battle_setting_flow_formation_menu", "OnInit", {id = "VRFW.team_loadout", phase = "before",
    fn = function()
      VRFW.team_loadout.sync("pre-match")
    end})
end
