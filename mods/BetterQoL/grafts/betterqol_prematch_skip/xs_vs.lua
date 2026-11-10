--@lib ../_src/better_qol/cutin_skip.lua#Head
local betterqol_xs_prev_go = GoToFormationScreen
function GoToFormationScreen(...)
  BetterQoL.cutin_skip.arm("vs screen")
  return betterqol_xs_prev_go(...)
end
