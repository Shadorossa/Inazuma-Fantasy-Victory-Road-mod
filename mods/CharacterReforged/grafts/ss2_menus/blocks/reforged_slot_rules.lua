-- ===== Character Reforged slot rules =====
PL.PICK_SLOT_KEY = 193456069
PL.PICK_CHARA_KEY = 2968815042
PL.PICK_BOARD_KEY = 1613324356
function PL.place_slot_of(row)
  return CharacterReforged.player_sets.place_slot_of(row, PL.set_ctx())
end

function PL.can_place(slot, skill)
  return CharacterReforged.player_sets.can_place(n, slot, skill)
end
PL.prev_pick_coroutine = CharacterReforgedSkillTablePickCoroutine
function CharacterReforgedSkillTablePickCoroutine(row)
  P_Set(PL.PICK_SLOT_KEY, PL.place_slot_of(row))
  P_Set(PL.PICK_CHARA_KEY, n or 0)
  local slot = PL.place_slot_of(row)
  P_Set(PL.PICK_BOARD_KEY, slot == 7 and HYPER_BUTTON_SLOT or ((slot >= 1 and slot <= 6) and ListPos(slot) or -1))
  local ok, err = pcall(PL.prev_pick_coroutine, row)
  VRFW.param.clear(PL.PICK_SLOT_KEY)
  VRFW.param.clear(PL.PICK_CHARA_KEY)
  VRFW.param.clear(PL.PICK_BOARD_KEY)
  if not ok then
    error(err, 0)
  end
end
PL.prev_equip = CharacterReforged.skill_table_equip
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  return CharacterReforged.player_sets.with_rules(n, row, skill, PL.set_ctx(), function()
    return PL.prev_equip(row, skill, inv_hint, cur)
  end)
end
-- ===== Character Reforged slot rules END =====
