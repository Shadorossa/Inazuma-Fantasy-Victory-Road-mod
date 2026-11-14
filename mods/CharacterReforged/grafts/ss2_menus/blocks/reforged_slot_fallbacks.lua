-- ===== Reforged slot fallbacks ===== An equip, reset or removal on a half also takes that half's list / board


-- Returns the board slots holding a fallback of `half`.
function PL.fb_sources(half)
  return CharacterReforged.player_sets.fb_sources(n, half)
end

function PL.fb_board_clear(slot, mode)
  return CharacterReforged.player_sets.fb_board_clear(n, slot, mode)
end

-- Returns the technique a list position takes when its aura leaves.
function PL.fb_refill(pos)
  return CharacterReforged.player_sets.fb_refill(n, pos)
end

-- Takes the fallbacks of `half` off the board, which clears the slots.
function PL.fb_clear(half, why)
  return CharacterReforged.player_sets.fb_clear(n, half, why, PL.set_ctx())
end

PL.fb_prev_equip = CharacterReforged.skill_table_equip
function CharacterReforged.skill_table_equip(row, skill, inv_hint, cur)
  return CharacterReforged.player_sets.with_fallbacks(n, row, skill, PL.set_ctx(), function()
    return PL.fb_prev_equip(row, skill, inv_hint, cur)
  end)
end

PL.fb_prev_restore = CharacterReforged.skill_table_restore_coroutine
function CharacterReforged.skill_table_restore_coroutine(row)
  if row ~= 0 then
    return PL.fb_prev_restore(row)
  end
  local mix = PL.hs_mix()
  local aura_half = PL.hs_half == 0 or mix == 0
  local okp, proj = pcall(PL.skill_set_projection)
  -- The aura half shows a list fallback and its own slot is empty.
  if aura_half and okp and proj ~= nil and Skill(0) == 0 and #PL.fb_sources("aura") > 0 then
    local ok, cleared = pcall(PL.fb_clear, "aura", "remove")
    funcLuaCommand(C.SE, (ok and cleared > 0) and SE_REMOVE or SE_NG)
    pcall(CharacterReforged.skill_table_after_change)
    CharacterReforged.skill_table_focus_row(0)
    return
  end
  local r = PL.fb_prev_restore(row)
  local ok, cleared = pcall(PL.fb_clear, aura_half and "aura" or "mix", "reset / remove")
  if ok and cleared > 0 then
    pcall(CharacterReforged.skill_table_after_change)
  end
  return r
end

-- Restablecer (tap) on the aura half with its own slot empty
PL.fb_prev_reset = PL.base_reset_coroutine
function PL.fallback_reset_coroutine(row)
  if row ~= 0 or Skill(0) ~= 0 or (PL.hs_half == 1 and PL.hs_mix() ~= 0) then
    return PL.fb_prev_reset(row)
  end
  local okp, proj = pcall(PL.skill_set_projection)
  if okp and proj ~= nil and #PL.fb_sources("aura") > 0 then
    return CharacterReforged.skill_table_restore_coroutine(0)
  end
  local okk, kit = pcall(PL.reset_kit, 0)
  if okk and (kit or 0) == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  return PL.fb_prev_reset(row)
end
-- ===== Reforged slot fallbacks END =====
