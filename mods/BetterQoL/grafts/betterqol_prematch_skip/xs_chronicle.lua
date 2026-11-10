--@lib ../_src/better_qol/cutin_skip.lua#Head
local betterqol_xs_prev_close = CloseChronicleModeSoccerVsMenu
function CloseChronicleModeSoccerVsMenu(...)
  BetterQoL.cutin_skip.arm("chronicle vs screen")
  return betterqol_xs_prev_close(...)
end
