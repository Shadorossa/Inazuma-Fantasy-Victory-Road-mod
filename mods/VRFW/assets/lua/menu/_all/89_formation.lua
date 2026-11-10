-- lua_patch.scope: used
if VRFW.formation == nil then
  local F = { PLAYERS = VRFW.commands.VRFW_FORMATION_PLAYERS }  -- CMND_VRFW_FORMATION_PLAYERS (formation id) -> players
  local known = {}
  VRFW.formation = F

  --- The players of formation `id`; nil when unknown, 0 when id is no number.
  function F.players(id)
    if type(id) ~= "number" then
      return 0
    end
    id = VRFW.ids.unsigned(id)
    local players = known[id]
    if players == nil then
      players = VRFW.host.command(F.PLAYERS, id)
      if type(players) ~= "number" then
        return nil
      end
      known[id] = players
    end
    return players
  end

  --- True for a 5-a-side formation; nil when unknown.
  function F.is_five_a_side(id)
    local players = F.players(id)
    if players == nil then
      return nil
    end
    return players == 5
  end
end
