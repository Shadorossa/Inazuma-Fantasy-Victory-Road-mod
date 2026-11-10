-- ===== Board-only move guide ===== A row greyed by the projection (on the board, not in the match list)
PL.TX_BOARD_ONLY = 186386713
PL.board_guide = false
PL.bg_prev_item_info = UpdateEquipItemInfo
function UpdateEquipItemInfo(...)
  local r = PL.bg_prev_item_info(...)
  local ok, err = pcall(PL.board_only_guide)
  if not ok then
    pcall(Call, C.LOG, "skill_slots", "board-only guide failed", tostring(err))
  end
  return r
end

function PL.board_only_guide()
  local board_only = false
  if n14 ~= L_BTN and n ~= nil and n ~= 0 and not CharacterReforged.skill_table_is_prime() then
    local row = funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)
    if type(row) == "number" and row >= 1 and row < ROW_NUM and not CharacterReforged.skill_table_is_locked(row) then
      local skill = PL.row_move(row)
      board_only = skill ~= 0 and not Active(skill)
    end
  end
  if board_only then
    local t = PL.txt(PL.TX_BOARD_ONLY)
    if t ~= "" then
      PL.guide(t)
      PL.board_guide = true
    end
  elseif PL.board_guide then
    PL.board_guide = false
    if not PL.idol_fixed(funcLuaMenuCommand(C.FOCUS_IDX, L_ROW)) then
      PL.guide(PL.txt(GUIDE_TEXT))
    end
  end
end
-- ===== Board-only move guide END =====
