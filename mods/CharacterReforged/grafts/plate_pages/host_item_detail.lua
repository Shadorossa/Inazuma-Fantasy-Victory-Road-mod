-- Item card host table for screens that show an item without a player (inventory, shops, received item lists).
@ITEMSPEC@
CharacterReforged.PLAYER_PAGE_HOST = {name = "item_detail", pages = false, item_only = true, fixed = 9, frame_hook = "Step",
  menu = @MENU@,
  chart = false}
CharacterReforged.PLAYER_PAGE_HOST.item_card = {
  -- the game's item cards of these screens (the one the screen fills is the one shown)
  layers = {3627613836 --[[team00_20_item_detail_l]], 1510257498 --[[team00_21b_item_detail]],
    2939475108 --[[shop01_05_item_info]]},
  layer = @CARD_LAYER@,
  no_player = true,
  relayout = false,                        -- the card stays as the game draws it
  rows = false,
  light_text = @LIGHT_TEXT@,                 -- a card with a dark body: the pages' texts in the light style
  text_on_icons = true,                    -- the pages' texts on the icon layer; the card's own text line off
  stat_page = true,                        -- first page: the stat changes ([icon] name +N / -N)
  prio_above_card = true,                  -- the icon layer's draw priority from the card's own
  base = 1517329426,
  rect = @CARD_RECT@,
  card_h = 130,
  text_x = 56,
  paged = {first_row = 30, row_pitch = 50, bottom = 20, max_rows = 2},
  -- The page dots are centred at the body's bottom.
  pager = {at = @PAGER_AT@, style = "ycycle", pill_shift = @PILL_SHIFT@},
  effect_at = {row1 = 30, row2 = 86, left = 20, split = 440, right = 858, passive_w = 270, affinity_w = 240},
  set_icons_at = {instances = 44, page_instances = 44, row_cy = 82, margin = 30},
}
if CharacterReforged.PLAYER_PAGE_HOST_OFF == nil then
  CharacterReforged.PLAYER_PAGE_HOST_OFF = false
end
