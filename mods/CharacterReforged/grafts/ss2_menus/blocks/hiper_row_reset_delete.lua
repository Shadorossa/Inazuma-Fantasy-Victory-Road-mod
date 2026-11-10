-- ===== Hiper row
PL.HALF_CMD_DEFAULT = @crc:CMND_CHARACTERREFORGED_DEFAULT_SET@

function PL.half_default_mix()
  if n == nil or n == 0 then
    return 0
  end
  local ok, _, mix = pcall(funcLuaCommand, PL.HALF_CMD_DEFAULT, n)
  return (ok and type(mix) == "number") and to_u32(mix) or 0
end

PL.half_prev_restore = CharacterReforged.skill_table_restore_coroutine
function CharacterReforged.skill_table_restore_coroutine(row)
  if row ~= 0 or PL.mx_removing then
    return PL.half_prev_restore(row)
  end
  if PL.hs_half == 1 then
    if PL.hs_mix() == 0 then
      funcLuaCommand(C.SE, SE_NG)                  -- the mix half is already empty
      return
    end
    return PL.half_prev_restore(0)                   -- the mix slot's removal (fusion / change questions)
  end
  if Skill(0) == 0 then
    local okp, proj = pcall(PL.skill_set_projection)
    if not (okp and proj ~= nil and #PL.fb_sources("aura") > 0) then
      funcLuaCommand(C.SE, SE_NG)                  -- the aura half shows nothing: the mix slot is never touched here
      return
    end
  end
  return PL.half_prev_restore(0)
end

PL.half_prev_reset = PL.fallback_reset_coroutine
function CharacterReforged.skill_table_reset_coroutine(row)
  if row ~= 0 or PL.hs_half ~= 1 then
    return PL.half_prev_reset(row)
  end
  if CharacterReforged.skill_table_is_prime() or PL.readonly then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local cur, want = PL.hs_mix(), PL.half_default_mix()
  if cur == want then
    funcLuaCommand(C.SE, SE_NG)                    -- already the basic set's mix
    return
  end
  if cur ~= 0 then
    CharacterReforged.skill_table_restore_coroutine(0)                        -- the current mix off first (its own questions)
    if PL.hs_mix() ~= 0 then
      return                                       -- the player kept it
    end
  end
  if want ~= 0 then
    if PL.hs_mix_put(want) then
      funcLuaCommand(C.SE, SE_DECIDE)
    else
      funcLuaCommand(C.SE, SE_NG)
    end
  end
  pcall(Call, C.LOG, "skill_slots", "reset mix", string.format("%08X", to_u32(cur)),
    string.format("%08X", to_u32(want)), string.format("%08X", PL.hs_mix()))
  RefreshRows()
  UpdateEquipItemInfo()
  CharacterReforged.skill_table_focus_row(0)
end
-- ===== Hiper row
