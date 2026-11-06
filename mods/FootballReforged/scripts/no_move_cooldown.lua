-- The option «no special move cooldown»: while it is on, a move's own full recast never starts, on both teams.
-- The slot's remaining time stays 0, so the engine's usable check, the AI's chooser and the HUD see a ready move.
-- An aura's end passes its own time and is left alone. Tension costs are not touched.
-- Details: docs/game/mechanics/move-effects.md. Declarations: content\game\no_move_cooldown.toml.

require "VRFW/lib/basics"   -- sets VRFW.logger in this script's VM
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
