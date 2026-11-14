-- ===== Character Reforged projection ===== Writing a move row over a hidden aura moves the aura to its own
function PL.free_list_pos(row, skill)
  return CharacterReforged.player_sets.free_list_pos(n, row, skill, PL.set_ctx())
end

-- Returns whether the player still has `aura` (board, list, mix store or stock).
function PL.keep_aura(aura, why)
  return CharacterReforged.player_sets.keep_aura(n, aura, why)
end
function PL.skill_set_projection()
  return CharacterReforged.player_sets.skill_set_projection(n)
end
-- Returns the aura and mix the two Hiper halves show and the learn level each half still needs (0 = open; CharacterReforged.move_rows.with_locked).
function PL.shown_skill_set_slots()
  local own, mix = PL.row_move(0), PL.hs_mix()
  local okp, proj = pcall(PL.skill_set_projection)
  if not okp or proj == nil then
    return own, mix, 0, 0
  end
  local aura = own
  local kind = own ~= 0 and PL.hs_kind(own) or nil
  if own == 0 or kind == 1 then
    aura = proj.aura                           -- a list aura (or none); a mix move on the row shows in the mix half
  end
  if mix == 0 then
    mix = proj.mix
  end
  local shown = CharacterReforged.move_rows.with_locked(funcLuaCommand, n, {aura = aura, mix = mix})
  return shown.aura, shown.mix, shown.aura_need, shown.mix_need
end

PL.proj_prev_equip = CharacterReforged.skill_table_equip
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  return CharacterReforged.player_sets.with_projection(n, row, skill, PL.set_ctx(), function()
    return PL.proj_prev_equip(row, skill, inv_hint, cur)
  end)
end
-- ===== Character Reforged projection END =====
