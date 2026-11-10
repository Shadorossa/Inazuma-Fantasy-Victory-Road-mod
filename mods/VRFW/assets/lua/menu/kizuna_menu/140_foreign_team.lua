if type(VRFW.team_editor) == "table" and type(VRFW.team_editor.view_only) == "function" then
  VRFW.team_editor.view_only({
    stem = "kizuna_menu",
    functions = { [206718306] = true, [330777687] = true },
    guides = { "SetButtonGuide" },
  })
end
