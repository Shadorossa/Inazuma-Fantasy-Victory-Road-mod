
VRFW.archetype = VRFW.archetype or {}
local A = VRFW.archetype
A.CMD_TEAM = 3704961242   -- CMND_VRFW_ARCHETYPE_TEAM
A.CMD_MATCH = 2854479468  -- CMND_VRFW_ARCHETYPE_MATCH
A.CMD_INFO = 3552358290   -- CMND_VRFW_ARCHETYPE_INFO
A.FIRST = 7

-- { name, desc, icon, large, gauge } of a declared archetype's number, nil for the game's builds / no answer
function A.info(n)
  if type(n) ~= "number" or n < A.FIRST then return nil end
  local has, name, desc, icon, large, gauge = VRFW.host.command(A.CMD_INFO, n)
  if has == true then return { name = name, desc = desc, icon = icon, large = large, gauge = gauge } end
  return nil
end

-- the declared archetype a team set (dock, party) got at its last pick, nil when it is one of the game's builds
function A.team(dock, party)
  local b = VRFW.host.command(A.CMD_TEAM, dock or 0, party or 0)
  if type(b) == "number" and b >= A.FIRST then return b end
  return nil
end

-- the declared archetype of a match side (0 / 1) and its rank, nil when none
function A.match(side)
  if side ~= 0 and side ~= 1 then return nil end
  local b, rank = VRFW.host.command(A.CMD_MATCH, side)
  if type(b) == "number" and b >= A.FIRST then return b, rank or 0 end
  return nil
end

if MENU_DEF ~= nil then
  A.menu_def = A.menu_def or {}
  local W = A.menu_def
  local function wrap(name, field)
    local cur = MENU_DEF[name]
    if type(cur) ~= "function" or cur == W[name] then return end
    local orig = cur
    W[name] = function(a1, ...)
      local x = A.info(a1)
      if x and x[field] ~= nil and x[field] ~= 0 then return x[field] end
      return orig(a1, ...)
    end
    MENU_DEF[name] = W[name]
  end
  wrap("GetBuildTypeLargeTextureIdFromTeamBuildType", "large")
  wrap("GetBuildTypeNameTextIdFromTeamBuildType", "name")
  wrap("GetBuildTypeExplanationTextIdFromTeamBuildType", "desc")
end
