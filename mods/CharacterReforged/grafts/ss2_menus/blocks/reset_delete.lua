-- Y empties the focused row

function PL.kit_move(row)
  local ls = PL.read_learnset()
  local slot = PL.row_slot(row)
  local m = ls.skill[slot] or 0
  if m == 0 or IsSpecial(m) ~= (row == 0) then
    return 0
  end
  local lv = funcLuaCommand(C.CHARA_GET, n, 0) or 0
  if (ls.lv[slot] or 0) > lv then
    return 0
  end
  return m
end

function PL.row_guide()
  local t = {1847312674 --[[Aceptar]], PL.TX.BTN_RESET}
  local i = {PL.I_ENTER, PL.I_FUNC3}
  local c = {PL.K_ENTER, PL.K_FUNC3}
  local o = {0, 18}
  pcall(PL.mx_guide_add, t, i, c, o)
  local list = {}
  for k = 1, #t do
    list[k] = {text = t[k], icon = i[k], command = c[k], offset = o[k]}
  end
  VRFW.footer_prompts.set("vrfw_skill_slot_menu", n12, list, 1138543975 --[[mainmenu01_06_base_button_guide]])
end

-- Returns the basic-kit move of `row`.
function PL.reset_kit(row)
  local m = 0
  if row == 0 and n ~= nil and n ~= 0 then
    local ok, aura = pcall(funcLuaCommand, @crc:CMND_CHARACTERREFORGED_DEFAULT_SET@, n)
    m = (ok and type(aura) == "number") and to_u32(aura) or 0
  end
  local special = IsSpecial(m)
  if row == 0 then
    if not special or m == PL.MX_FUSION or m == PL.MX_CREATE or CharacterReforged.hyper_card.is_mode_change(m) then
      m = 0
    end
  elseif special then
    m = 0
  end
  if m == 0 then
    m = PL.kit_move(row)
  end
  return m
end

function PL.base_reset_coroutine(row)
  if CharacterReforged.skill_table_is_prime() then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local before = Snapshot()
  local old = Skill(row)
  local bslot = BoardSlot(row)
  local want = PL.reset_kit(row)
  if row == 0 and old ~= 0 and old ~= want then
    -- A miximax fusion or mode change on the Hiper row goes through Y with its own questions.
    local mx = old == PL.MX_FUSION
    local mc = CharacterReforged.hyper_card.is_mode_change(to_u32(old))
    if mx or mc then
      CharacterReforged.skill_table_restore_coroutine(0)
      if Skill(0) ~= 0 then
        return
      end
    end
  end
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, false)
  local r
  if row == 0 then
    if want == 0 then
      r = Call(C.BOARD_CLEAR, n, bslot, 3 --[[keepOpen 3: everything off]])
      TeamAuraPut(0)
    else
      r = BoardClear(bslot, true)              -- placed item off: the native Hiper (if still there) is back
      if BoardSkill(bslot) ~= 0 and BoardSkill(bslot) ~= want then
        r = Call(C.BOARD_CLEAR, n, bslot, 3 --[[keepOpen 3: the retail native item off too]])
      end
      if BoardSkill(bslot) == want then
        TeamAuraPut(want)
      else
        CharacterReforged.skill_table_equip(0, want)                         -- board slot 8 + the team aura slot
      end
    end
  else
    r = BoardClear(bslot, true)                -- placed item off: the native move (if any) is back
    if IsSpecial(BoardSkill(bslot)) then   -- an aura native item never returns to a row
      r = Call(C.BOARD_CLEAR, n, bslot, PL.AURA_CLEAR_NATIVE)
    end
    if want == 0 and BoardSkill(bslot) ~= 0 then
      r = Call(C.BOARD_CLEAR, n, bslot, 3 --[[keepOpen 3: the retail native move off: no default = empty]])
    end
    local pos = ListPos(row)
    if want ~= 0 then
      CharacterReforged.skill_table_equip(row, want)                         -- match list (swaps if the move sat on another row) + board
    elseif ListSkill(pos) ~= 0 then
      funcLuaCommand(C.REMOVE_SKILL, n, pos)       -- empty kit slot: the row ends empty
    end
  end
  local now = Skill(row)
  funcLuaCommand(C.SE, now ~= old and SE_DECIDE or SE_NG)   -- already the kit move: error sound only
  Report(string.format("Reset row %d: %s -> %s (kit %s, state %s).\n%s", row, Name(old), Name(now),
    Name(want), tostring(r), Diff(before, Snapshot())), row)
  CharacterReforged.skill_table_after_change()
  CharacterReforged.skill_table_focus_row(row)
  funcLuaMenuCommand(C.MENU_ACTIVE, EVT_MENU, true)
end
