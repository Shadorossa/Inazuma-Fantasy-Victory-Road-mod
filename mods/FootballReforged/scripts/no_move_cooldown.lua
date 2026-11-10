
local info = VRFW.logger("no_move_cooldown")
local logged = false

VRFW.on("hook:FootballReforged.StartSlotRecast", function(ev)
  if ev.args[3] >= 0 or (tonumber(VRFW.option("no_move_cooldown")) or 0) == 0 then return nil end
  if not logged then
    logged = true
    info("a move's full recast was skipped (option on)")
  end
  return { skip = true }
end)
