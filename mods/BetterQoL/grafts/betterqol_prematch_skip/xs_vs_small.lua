--@lib ../_src/better_qol/cutin_skip.lua#Head
local betterqol_xs_prev_close = CloseSoccerBattleVsMenu
function CloseSoccerBattleVsMenu(...)
  BetterQoL.cutin_skip.arm("small match vs screen")
  return betterqol_xs_prev_close(...)
end
