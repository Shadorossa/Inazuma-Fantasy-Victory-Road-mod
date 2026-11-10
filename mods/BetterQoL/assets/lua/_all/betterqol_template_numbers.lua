-- Team plates and the dock change guide show the number of the template a dock holds.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.template_numbers == nil then
  local N = {
    INFO = 216271522,                -- CMND_BETTERQOL_TEMPLATE_INFO -> usable, template count, slot
    OF_DOCK = 215684477,             -- CMND_BETTERQOL_TEMPLATE_OF_DOCK (team set) -> template number
    FIRST_DOCK = 4017866835,         -- -> the team set of the first dock
    SET_NUMBER = 3609943765,         -- (layer, instance, primitive index, value)
    CHANGE_GUIDE = 255314328,        -- team14_04_team_dock_change_guide
  }
  BetterQoL.template_numbers = N

  --- The template number the dock `team_set` holds; nil when the save has no stored templates or the set is no dock.
  function N.of_team_set(team_set)
    if type(team_set) ~= "number" or VRFW.host.command(N.INFO) ~= true then
      return nil
    end
    local template = VRFW.host.command(N.OF_DOCK, team_set)
    return type(template) == "number" and template or nil
  end

  -- (layer, instance, team name, team set, ...): the plate's number is the team set's place among the docks
  local draw_plate = __SetupTeamDockItemLayerCore
  if type(draw_plate) == "function" then
    __SetupTeamDockItemLayerCore = function(layer, instance, name, team_set, ...)
      local template = N.of_team_set(team_set)
      if template ~= nil then
        team_set = funcLuaCommand(N.FIRST_DOCK) + template - 1
      end
      return draw_plate(layer, instance, name, team_set, ...)
    end

    --- Draws a team plate for template `template`: its number and the given name, level, emblem and active mark.
    function N.draw_plate(layer, instance, name, template, level, emblem, active)
      return draw_plate(layer, instance, name, funcLuaCommand(N.FIRST_DOCK) + template - 1, level, emblem, active, false)
    end
  end

  -- the L1 / R1 guide of the lineup screens writes the shown dock's place among the docks
  local draw_change_guide = UpdateTeamDockChangeGuideNo
  if type(draw_change_guide) == "function" then
    UpdateTeamDockChangeGuideNo = function(...)
      return VRFW.host.with_commands({menu = {[N.SET_NUMBER] = function(set_number, id, layer, instance, primitive, place, ...)
        if layer == N.CHANGE_GUIDE and type(place) == "number" then
          place = N.of_team_set(funcLuaCommand(N.FIRST_DOCK) + place - 1) or place
        end
        return set_number(id, layer, instance, primitive, place, ...)
      end}}, draw_change_guide, ...)
    end
  end
end
