do
  local STATE, FADE = VRFW.commands.VRFW_MENU_SCENE_STATE, 609722083
  VRFW.field_hud.hide_under_menu_scene("rpg_info_window", function()
    local state = VRFW.host.command(STATE)
    if state == "loading" or state == "switching" then
      -- The retail field start fades in independently of the menu.
      VRFW.host.command(FADE, 1, 0)
    end
  end)
end
