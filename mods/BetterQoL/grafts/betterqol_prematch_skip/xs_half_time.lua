--@lib ../_src/better_qol/cutin_skip.lua#Head
local betterqol_xs_prev_init = OnInit
function OnInit(...)
  BetterQoL.cutin_skip.disarm("half time")
  return betterqol_xs_prev_init(...)
end
