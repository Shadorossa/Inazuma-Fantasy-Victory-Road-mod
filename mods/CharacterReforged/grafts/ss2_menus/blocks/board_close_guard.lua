-- ===== Board close guard ===== Once Back starts the close (PL.board_closing), the detail panels are not redrawn
PL.board_closing = false

PL.cg_prev_init = OnInit
function OnInit(...)
  PL.board_closing = false
  return PL.cg_prev_init(...)
end

PL.cg_prev_change_focus = OnChangeFocus
function OnChangeFocus(...)
  if PL.board_closing then
    return
  end
  return PL.cg_prev_change_focus(...)
end

PL.cg_prev_item_info = UpdateEquipItemInfo
function UpdateEquipItemInfo(...)
  if PL.board_closing then
    return
  end
  return PL.cg_prev_item_info(...)
end

PL.cg_prev_open = PL.open
function PL.open(...)
  if PL.board_closing then
    return
  end
  return PL.cg_prev_open(...)
end

PL.cg_prev_hs_poll_r3 = PL.hs_poll_r3
function PL.hs_poll_r3(...)
  if PL.board_closing or PL.cg_prev_hs_poll_r3 == nil then
    return
  end
  return PL.cg_prev_hs_poll_r3(...)
end

PL.cg_prev_focus_resync = PL.focus_resync
function PL.focus_resync(...)
  if PL.board_closing or PL.cg_prev_focus_resync == nil then
    return
  end
  return PL.cg_prev_focus_resync(...)
end
-- ===== Board close guard END =====
