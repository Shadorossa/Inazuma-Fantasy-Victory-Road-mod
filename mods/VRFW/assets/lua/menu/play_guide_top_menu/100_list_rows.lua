-- Row ids = the retail row kinds of play_guide_top_menu (the chunk's list local t; kind 0 is the help row).
if VRFW.list_rows ~= nil and VRFW.list_rows.declare_local_list ~= nil then
  VRFW.list_rows.declare_local_list(VRFW.list_rows.PLAY_GUIDE, {
    stem = "play_guide_top_menu",
    list = "t",
    -- The rules are applied when the list is set up (mainmenu90_12_list_item_small, instance 0).
    setup = {point = "OnSetupLayer", layer = 530619243 --[[mainmenu90_12_list_item_small]], instance = 0},
    -- Retail OnInit marks a locked row by its retail position, so the list is back in the retail order before it.
    reset = "OnInit",
  })
end
