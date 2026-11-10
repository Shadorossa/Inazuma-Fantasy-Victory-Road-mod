
local function get(key)
  local ok, v = pcall(VRFW.state.get, key)
  if ok and type(v) == "number" then return v end
end

local function push()
  local a, b = get("BetterQoL.role_medal.matches_required"), get("BetterQoL.role_medal.matches_required_created_role")
  if a and b then pcall(function() CharacterReforged.SetRoleMedalThresholds(a, b) end) end
end

VRFW.on("slot_load", push)
