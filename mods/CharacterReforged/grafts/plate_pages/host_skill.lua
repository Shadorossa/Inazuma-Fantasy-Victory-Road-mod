-- Player page host table for the skill table
CharacterReforged.PLAYER_PAGE_HOST = {name = "skill", plate = 607716004, status = 2917320188, graph = 32151736, radar = 2334590304, pages = false, fixed = 9,
  menu = 2221030314 --[[vrfw_skill_slot_menu: its close state shuts the added layers]],
  -- Default card rect (screen x0, y0, x1, y1).
  plate_off = {3562698908, 3892654168},
  chart = false, card = {985, 625, 1920, 955},
  -- The screen has no PostStep.
  frame_hook = "Step",
  keep_radar = function()
    return type(CharacterReforged.player_page_skill_table_radar_wanted) == "function" and CharacterReforged.player_page_skill_table_radar_wanted() == true
  end}
if CharacterReforged.PLAYER_PAGE_HOST_OFF == nil then
  CharacterReforged.PLAYER_PAGE_HOST_OFF = false
end
