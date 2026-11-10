-- The item card's shared spec (graft plate_pages)
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.PLAYER_PAGE_ITEM_SPEC = {
  page_command = @crc:CMND_CHARACTERREFORGED_ITEM_PAGE@,             -- (item) -> text, "" = none (answered by a module)
  set_command = @crc:CMND_CHARACTERREFORGED_ITEM_SET@,               -- (item) -> {name, count, members, tiers, ...} (answered by a module)
  -- Icons of the set page (layer character_reforged_eq_set_icon, `instances` copies of the item card object).
  badges = {
    atlas = 2058213660,                    -- #/menu/200_icon/15_icon_common2/<LG>/icon_common2.g4tx
    sprites = {FW = 30648122, MF = 2564486784, DF = 4024288790, GK = 1907970997},
    size = {48, 27}, gap = 6, space_px = 9, char_px = 17,
    dy = -5,                               -- the text line's centre is 5 px above the row centre
  },
  set_icons = {
    instances = 60, size = 34, gap = 6, group_gap = 20, margin = 40, row_cy = 140,   -- under the title row (96)
    page_instances = 44,
    slot_atlas = 1676671618,               -- #/menu/00_soccer/soccer11/soccer11_08/<LG>/soccer11_08.g4tx
    slot_swap = 3592622327,                -- win_item_base01 (the icon instance's _win_item_base01 slot)
    -- Slot icons where one of the set is worn.
    worn_atlas = 3891933463,               -- #/menu/102_team/team05/cr_eq_fx/cr_eq_fx.g4tx
    slot_worn_sprites = {2450106010, 345887796, 3753969553, 3267639081},
    slot_size = {40, 44},
    slot_sprites = {2346103015, 316662109, 1708708299, 4223419496},   -- icon_equip01..04 (boots, bracelet, pendant, special)
    slot_of_category = {[30] = 1, [40] = 2, [50] = 3, [60] = 4},
  },
  set_colours = {worn = "[CG]", missing = "[CWG]"},   -- worn pieces / reached tiers; pieces not owned / tiers not reached
  effect = {
    atlas = 3891933463,                    -- #/menu/102_team/team05/cr_eq_fx/cr_eq_fx.g4tx
    row1 = 82, row2 = 134, left = 24, split = 478, right = 911,
    section = 28, sep = {4, 28}, sep_gap = 8, gap = 6, icon = 22, check = 14, badge = {42, 24}, slot = {22, 24},
    chip_h = 30, chip_pad = 10, tier_min = 60, tier_gap = 12, bar_h = 4, bar_gap = 5, bar_pad = 12, text_scale = 0.6,
    plus = "+",
    -- Layout of a card without a player (inventory, shop).
    stat_row = 40, stat_gap = 34, stat_scale = 0.7, title_y = 30, title_scale = 0.62,
    passive_w = 300, affinity_w = 270,     -- the chips' widths at least (B3v13)
    -- Layout of the tier chips.
    tier_h = 36, tier_scale = 0.5, tier_scale_min = 0.36, reward_dy = -5, bar_dy = 9,
    stat_texts = {3905596903, 1084668705, 1047492482, 2352972234, 2604963209, 614355554, 2718198818, 1241387599},
    -- Draw order inside the icon layer (CMND_SET_DRAW_PRIORITY per instance).
    prio_under = 552, prio_over = 556,
    styles = {
      white = {node = 456522680, at = {-221, 15}, box_h = 50, char_px = 18, dy = 2},
      ink = {node = 3138144965, at = {-229, -59}, box_h = 50, char_px = 17},
    },
    -- the section icons on a card with a dark body (host light_text)
    sprites_on_dark = {bond = "cr_eq_fx_bond_light", emblem = "cr_eq_fx_emblem_light", equip = "cr_eq_fx_equip_light"},
    sprites = {
      bond = "cr_eq_fx_bond", emblem = "cr_eq_fx_emblem", equip = "cr_eq_fx_equip", sep = "cr_eq_fx_sep",
      check = "cr_eq_fx_check", chip_on = "cr_eq_fx_chip_green", chip_blue = "cr_eq_fx_chip_blue",
      chip_off = "cr_eq_fx_chip_off", bar_on = "cr_eq_fx_bar_on", bar_off = "cr_eq_fx_bar_off",
      bar_white = "cr_eq_fx_bar_white", element = "cr_eq_fx_el%02d", element_off = "cr_eq_fx_el%02d_off",
      stat = "cr_eq_fx_stat%s", position = "icon_param2_position%02d", position_off = "cr_eq_fx_pos%02d_off",
    },
    -- The game's icon orders.
    elements = {wind = 1, forest = 2, fire = 3, mountain = 4},
    element_texts = {wind = 450194284, forest = 1565306319, fire = 1660958301, mountain = 191660811, void = 3339176265},
    positions = {FW = 1, MF = 2, DF = 3, GK = 4},
    -- The game's GK badge is dark letters on a near-white plate (bare text on the white card).
    position_own = {GK = "cr_eq_fx_pos04_on"},
    stat_icons = {kick = "01", control = "02", technique = "03", pressure = "04", physical = "05",
      intelligence = "06", agility = "07"},
  },

  bonus_gap = "   ",                       -- between two bonuses of the row
  plus_colour = "[CG]",                    -- font colour tags of a raise / a lowering ([C] ends them)
  minus_colour = "[CR]",
  -- the stat keys of the equipment stat indices 0..6 (CMND_GET_EQUIP_PARAM order), for the stat icons
  stat_by_index = {"kick", "control", "technique", "pressure", "physical", "intelligence", "agility"},
}
