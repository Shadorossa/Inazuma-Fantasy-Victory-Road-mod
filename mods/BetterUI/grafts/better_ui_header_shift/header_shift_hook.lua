BetterUI = type(BetterUI) == "table" and BetterUI or {}
VRFW.header_shift.apply("BetterUI.header_shift", function()
  return BetterUI.preset ~= "off" and (type(BetterUI.flags) ~= "table" or BetterUI.flags.header_short ~= false)
end)
