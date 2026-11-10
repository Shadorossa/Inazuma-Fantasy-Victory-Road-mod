-- ===== unlimited copies BEGIN ===== VRFW.copies
PL.copies_prev_equip = CharacterReforged.skill_table_equip
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  return CharacterReforged.player_sets.with_copies(n, skill, function()
    return PL.copies_prev_equip(row, skill, inv_hint, cur)
  end)
end

PL.copies_prev_on_init = OnInit
function OnInit(...)
  if type(VRFW.copies) == "table" then
    pcall(VRFW.copies.reset)
  end
  return PL.copies_prev_on_init(...)
end
-- ===== unlimited copies END =====
