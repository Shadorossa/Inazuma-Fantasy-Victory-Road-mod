--@lib ../_src/better_qol/cutin_skip.lua#Head
-- The match HUD opens when the pre-match flow hands the scene to the kick-off, after the flow's own fade in of the pitch.
local betterqol_xs_prev_hud_init = OnInit
function OnInit(...)
  BetterQoL.cutin_skip.unblack_layer0("match HUD")
  BetterQoL.cutin_skip.disarm("match HUD")
  return betterqol_xs_prev_hud_init(...)
end
