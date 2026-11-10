do
  local SkillTable = type(CharacterReforged) == "table" and CharacterReforged.skill_table or nil
  local Host = rawget(VRFW, "host")
  if SkillTable ~= nil and type(Host) == "table" and type(Host.host) == "function" and not SkillTable.hosted then
    local ok, host = pcall(Host.host, "vrfw_skill_slot_menu", {})
    if ok and type(host) == "table" then
      host.L = SkillTable.L
      SkillTable.hosted = true
      SkillTable.host = host
    end
  end
end
