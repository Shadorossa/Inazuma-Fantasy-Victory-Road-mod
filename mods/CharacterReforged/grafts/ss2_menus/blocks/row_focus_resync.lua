-- Row focus resync
PL.FS_WINDOW = 120
PL.fs_wait = 0
PL.FS_CTRL = @crc:CMND_IS_CTRL_FOCUS_ACTIVE@                  -- (layer)

function PL.ctrl_focus(L)
  if L == nil then
    return false
  end
  local ok, on = pcall(funcLuaMenuCommand, PL.FS_CTRL, L)
  return ok and on == true
end

-- the row list has the control focus and none of the bottom buttons does
function PL.row_has_focus()
  if not PL.ctrl_focus(L_ROW) then
    return false
  end
  for _, b in ipairs({L_BTN, L_BTN_SS, PL.L_BTN_ROLE, L_BTN_ICON}) do
    if PL.ctrl_focus(b) then
      return false
    end
  end
  return true
end

function PL.focus_resync(why)
  n14 = L_ROW
  local ok, err = pcall(UpdateEquipItemInfo)
  pcall(Call, C.LOG, "skill_slots", "focus resync", why, "row", funcLuaMenuCommand(C.FOCUS_IDX, L_ROW),
    ok and "" or tostring(err))
end

PL.fs_prev_change_focus = OnChangeFocus
function OnChangeFocus(a1, a2)
  if (a1 == L_BTN or a1 == L_BTN_SS or a1 == PL.L_BTN_ROLE) and not PL.ctrl_focus(a1) and PL.row_has_focus() then
    if n14 ~= L_ROW then
      PL.focus_resync("button focus event dropped")
    end
    return
  end
  return PL.fs_prev_change_focus(a1, a2)
end

PL.fs_prev_init = OnInit
function OnInit(...)
  PL.fs_wait = PL.FS_WINDOW
  return PL.fs_prev_init(...)
end

PL.fs_prev_step = Step
function Step(...)
  local r = PL.fs_prev_step ~= nil and PL.fs_prev_step(...) or nil
  if PL.fs_wait > 0 then
    PL.fs_wait = PL.fs_wait - 1
    if not PL.mx_scene_busy and vrfw_co == nil and n14 ~= L_ROW and PL.row_has_focus() then
      PL.focus_resync("step")
    end
  end
  return r
end
-- ===== Row focus resync END =====
