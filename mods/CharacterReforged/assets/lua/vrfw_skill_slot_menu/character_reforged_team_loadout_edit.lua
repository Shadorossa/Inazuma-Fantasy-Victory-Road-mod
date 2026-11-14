-- The moves screen: an edit of a player outside the active team stays in the team he was shown in (VRFW.team_loadout).
if VRFW.host ~= nil and VRFW.team_loadout ~= nil then
  VRFW.host.on("vrfw_skill_slot_menu", "OnBack", {id = "CharacterReforged.team_loadout", phase = "before", fn = function()
    local get = type(CharacterReforged) == "table" and type(CharacterReforged.skill_table) == "table"
      and CharacterReforged.skill_table.get or nil
    if get == nil then
      return
    end
    local handle, set = get.n(), get.n3()
    if type(handle) == "number" and type(set) == "number" then
      VRFW.team_loadout.edited(handle, set)
    end
  end})
end
