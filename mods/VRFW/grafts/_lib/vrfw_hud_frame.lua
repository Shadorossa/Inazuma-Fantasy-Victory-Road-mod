-- Advanced: VRFW hud:frame
VRFW.hud_frame = VRFW.hud_frame or {}
if UpdateScoreboardKeeperHp == nil or UpdateScoreboardKeeperHp ~= VRFW.hud_frame.wrapper then
  local previous = UpdateScoreboardKeeperHp
  local list = {}
  --- Internal: List of the functions run on every HUD frame after the previous hook.
  VRFW.hud_frame.subscribers = list
  --- Internal: Runs the previous frame hook, then every subscriber; answers the previous hook's results.
  VRFW.hud_frame.wrapper = function(...)
    local r = {n = 0}
    if type(previous) == "function" then
      r = table.pack(previous(...))
    end
    for i = 1, #list do
      pcall(list[i])
    end
    return table.unpack(r, 1, r.n)
  end
  UpdateScoreboardKeeperHp = VRFW.hud_frame.wrapper
  --- Advanced: Adds f to the functions called every HUD frame.
  VRFW.hud_frame.on = function(f)
    if type(f) == "function" then
      VRFW.hud_frame.subscribers[#VRFW.hud_frame.subscribers + 1] = f
    end
  end
end
