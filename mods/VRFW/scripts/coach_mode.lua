
VRFW.on("button_press:CMD_CHANGE_COACH_MODE", function(ev)
  if VRFW.state("match.coach_mode") == 0 then
    return { block = true }
  end
  return nil
end)
