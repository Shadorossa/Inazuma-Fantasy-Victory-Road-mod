-- Player page host table for screens with their own plate copy
@ITEMSPEC@
CharacterReforged.PLAYER_PAGE_HOST = {name = "equip", plate = 607716004, status = 2917320188, graph = 32151736, radar = 2334590304, pages = false, fixed = 9,
  menu = 606230082 --[[equip_menu: its close state shuts the added layers]],
  -- Places the stats panel at the layout's place (rows 740..875).
  card = {985, 535, 1920, 940}}
-- The item detail card (team05_02_equip_info_easy, traced by the status base on _atc_equip01) as one card
CharacterReforged.PLAYER_PAGE_HOST.item_card = {
  layer = 3239909435,                      -- team05_02_equip_info_easy
  root = {1222, 734},                      -- the layer's origin on screen (soccer11_05 _atc_equip01)
  base = 1517329426,
  rect = {985, 535, 1920, 705},            -- the card's left, top, right, bottom (on the stats panel's top)
  card_h = 170,                            -- one height on every page: the band and a two-row body (535..705)
  effect_at = {stat_row = 82},
  -- Anchors the base (_pos_base01) at this card point.
  anchor = {285, 15},
  body_mesh = 2511236049,
  -- The green band is 46 px (2..48).
  nodes = {
    {2511236049, 0, 0, 935, 214, body = true},
    {2885220123, -12, -2, 959, 50},
    {303536660, 6, 4, 42, 42},
    {2334051246, 6, 4, 42, 42},
    {2203859798, 555, 12, 48, 27},
    {441805548, 605, 12, 48, 27},
    {442049775, 659, 8, 0.85, 0.85},
    {3426045766, 793, 8, 0.85, 0.85},
    {2336812131, 850, 60},
    {3174025408, 300, 150},
  },
  dump = {{1517329426, "_pos_base01"}, {2511236049, "_win_item01"}, {456522680, "_text_item01"},
    {1923430404, "_dmy_item01"}, {3138144965, "_text_parameter01"}, {1139770918, "_dmy_parameter01"},
    {303536660, "_icon_item_dmy01"}},
  -- Reads the item picker's hovered item.
  picker_event = "CharacterReforged.ItemCardHover", picker_owner = "equip_menu_select", menu = 606230082 --[[equip_menu]],
  picker_page_event = "CharacterReforged.ItemCardPage",   -- L2 / R2 pressed in the picker
  select_group = 802408180 --[[equip_menu_select]],   -- this screen's layer group (back from the picker)
  text_x = 56,
  -- The card has one size for every item and page.
  paged = {first_row = 99, row_pitch = 54, bottom = 30, max_rows = 3},   -- 468 + 99 + 2 x 54 + 30 = 705
  -- The pager sits under the stats panel, centred on the panel.
  pager = {at = {1452, 912}},
  -- The grey boxes stick out of the top edge of the card and show the icon and signed total of each stat the focused item changes.
  -- The boxes use the icon layer instances from first to first+count-1, three per box, and align is "left" or "right".
  stat_boxes = {first = 60, count = 24, align = "left", margin = 14, h = 44, overlap = 6, pad = 10, icon = 30,
    gap = 6, spacing = 6, char_px = 17, text_scale = 0.62},
  -- Rows of the stats panel that the focused item raises or lowers.
  row_mark = {
    sprite = {raise = 1322374740 --[[cr_pp_row_raise]], lower = 4163712750 --[[cr_pp_row_lower]]},
    atlas = 3891933463,                    -- #/menu/102_team/team05/cr_eq_fx/cr_eq_fx.g4tx
    margin = 2,
    number_style = 2612831244,             -- the value prim of cr_pp_num_host
    colour = {raise = {0.2, 0.75, 0.3}, lower = {0.9, 0.2, 0.2}},   -- unchanged rows: the number's own colour
    -- Suerte row.
    delta = {first = 52, count = 8, band = {0.3125, 0.375}, raise = "cr_eq_fx_delta_up", lower = "cr_eq_fx_delta_down",
      -- Sizes are in screen pixels.
      min_width = 6, gap = 3},
    label = {dx = 338, dy = -22, scale = 0.42, plus = "[CG]", minus = "[CR]"},
    luck_number = 7,
    luck_arrows = {1180371782, 3746716412, 2824170090, 1539293697, 3266745275, 3048317741, 2576032421, 8549151,
      2005222281, 2221927394, 493271640, 1784777422},
    -- Label colour group of the chart layers' CMenuChangeMaterialColor (parameter_name_gtxt) and the labels.
    label_group = 3659653428, label_colour = {0.0784313725490196, 0.29411764705882354, 0.5098039215686274},
  },
}
-- Only the chart on the Plantilla page's card.
if CharacterReforged.PLAYER_PAGE_HOST_OFF == nil then
  CharacterReforged.PLAYER_PAGE_HOST_OFF = false
end
