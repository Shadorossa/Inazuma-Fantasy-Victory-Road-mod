if type(VRFW.team_editor) == "table" and type(VRFW.team_editor.view_only) == "function" then
  VRFW.team_editor.view_only({
    stem = "equip_aura_skill_menu",
    guides = { "SetupButtonGuide" },
    skill_board_lock = true,
  })
end
