--@lib ../_src/better_qol/cutin_skip.lua#Head
local betterqol_xs_prev_kickoff = InitializeKickoffButton_Callback
function InitializeKickoffButton_Callback(...)
  BetterQoL.cutin_skip.disarm("kick-off")
  return betterqol_xs_prev_kickoff(...)
end
local betterqol_xs_prev_restart = InitializeRestartButton_Callback
function InitializeRestartButton_Callback(...)
  BetterQoL.cutin_skip.disarm("restart")
  return betterqol_xs_prev_restart(...)
end
-- Called by the engine when the button shows.
local betterqol_xs_prev_decide = DecideRestartButton
function DecideRestartButton(...)
  BetterQoL.cutin_skip.uncover(BetterQoL.cutin_skip.COVER_IN_S, "kick-off button")
  BetterQoL.cutin_skip.unblack_layer0("kick-off button")
  return betterqol_xs_prev_decide(...)
end
local betterqol_xs_prev_step = Step
function Step(...)
  if BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.COVER) == 1 and BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.GO) ~= 1 then
    BetterQoL.cutin_skip.uncover(BetterQoL.cutin_skip.COVER_IN_S, "kick-off (retry)")
  end
  if BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.GO) ~= 1 then
    BetterQoL.cutin_skip.unblack_layer0("kick-off guide")
  end
  return betterqol_xs_prev_step(...)
end
