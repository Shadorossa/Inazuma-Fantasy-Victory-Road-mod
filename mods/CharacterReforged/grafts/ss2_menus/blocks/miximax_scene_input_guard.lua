-- Miximax scene input guard
PL.mx_guard_prev = {OnEnter = OnEnter, OnDecideFocus = OnDecideFocus, OnBack = OnBack, OnFunction = OnFunction}
function OnEnter(...)
  if PL.mx_scene_busy then
    return
  end
  return PL.mx_guard_prev.OnEnter(...)
end
function OnDecideFocus(...)
  if PL.mx_scene_busy then
    return
  end
  return PL.mx_guard_prev.OnDecideFocus(...)
end
function OnBack(...)
  if PL.mx_scene_busy then
    return
  end
  return PL.mx_guard_prev.OnBack(...)
end
function OnFunction(...)
  if PL.mx_scene_busy then
    return
  end
  return PL.mx_guard_prev.OnFunction(...)
end
PL.mx_guard_prev_poll_r3 = PL.mx_poll_r3
function PL.mx_poll_r3(...)
  if PL.mx_scene_busy or vrfw_co ~= nil or PL.mx_guard_prev_poll_r3 == nil then
    return
  end
  return PL.mx_guard_prev_poll_r3(...)
end
PL.mx_guard_prev_hs_poll_r3 = PL.hs_poll_r3
function PL.hs_poll_r3(...)
  if PL.mx_scene_busy or PL.mx_guard_prev_hs_poll_r3 == nil then
    return
  end
  return PL.mx_guard_prev_hs_poll_r3(...)
end
-- ===== Miximax scene input guard END =====
