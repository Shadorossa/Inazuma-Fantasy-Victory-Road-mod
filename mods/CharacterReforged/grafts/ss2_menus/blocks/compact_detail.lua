-- ===== compact detail layout ===== PL.apply_detail_layout for PL.LAYOUT_FRAMES frames after each state
PL.layout_prev_step = Step
function Step(...)
  local r = PL.layout_prev_step ~= nil and PL.layout_prev_step(...) or nil
  pcall(PL.mx_poll_r3)
  if PL.layout_mode ~= nil and (PL.layout_frames or 0) > 0 then
    PL.layout_frames = PL.layout_frames - 1
    pcall(PL.apply_detail_layout)
  end
  return r
end
-- ===== compact detail layout END =====
