-- VRFW hud:frame: one framework wrap of UpdateScoreboardKeeperHp (every frame of the match HUD, from
-- StepSoccerConstantMenu); VRFW_OnHudFrame(fn) adds fn, run after the game's function in subscription order, each
-- through pcall. The first block of a chunk run wraps the function (a run of the chunk again redefines it: wrapped
-- again with a new list); nothing else at chunk load.
if UpdateScoreboardKeeperHp == nil or UpdateScoreboardKeeperHp ~= VRFW_HudFrameWrapper then
  local previous = UpdateScoreboardKeeperHp
  local list = {}
  VRFW_HudFrameSubscribers = list
  VRFW_HudFrameWrapper = function(...)
    local r = {n = 0}
    if type(previous) == "function" then
      r = table.pack(previous(...))
    end
    for i = 1, #list do
      pcall(list[i])
    end
    return table.unpack(r, 1, r.n)
  end
  UpdateScoreboardKeeperHp = VRFW_HudFrameWrapper
  VRFW_OnHudFrame = function(f)
    if type(f) == "function" then
      VRFW_HudFrameSubscribers[#VRFW_HudFrameSubscribers + 1] = f
    end
  end
end
