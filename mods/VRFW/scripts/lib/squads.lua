-- The player's squads (team docks): active squad, its members. Call: in a handler (not while the script loads).
--- Library: team squads and their physical and logical layout.
local Memory = VRFW.memory

local M = {}

local LOGICAL_TO_PHYSICAL = "Party.LogicalToPhysical"
local RECOUNT_TEAM_INFO = "Party.RecountTeamInfo"
local SET_ORGANIZED_FLAG_BIT = "Party.SetOrganizedFlagBit"

local LAYOUT = nil
local LAYOUT_WHY = nil

--- Advanced: The squad layout from the game profile; nil, why when a field is missing.
function M.layout()
  if LAYOUT ~= nil or LAYOUT_WHY ~= nil then
    return LAYOUT, LAYOUT_WHY
  end
  local names = {
    sets = "Party.TeamSets", set_count = "Party.TeamSetCount", active = "Party.ActiveTeamSet", set_size = "TeamSet",
    team_size = "TeamInfo", members = "TeamInfo.Members", member_count = "Party.TeamSetMemberCount",
    member_size = "TeamSetMember", member_handle = "TeamSetMember.Handle",
  }
  local out, missing = VRFW.game.fields(names)
  if out == nil then
    LAYOUT_WHY = "the game profile has no " .. tostring(missing)
    VRFW.warn("party_squads: " .. LAYOUT_WHY)
    return nil, LAYOUT_WHY
  end
  LAYOUT = out
  return LAYOUT
end

--- VRFW.squads.physical_index(logical): the stored index of a squad shown as `logical`, or nil. Call: in a handler (not while the script loads).
function M.physical_index(logical)
  local L = M.layout()
  if L == nil or type(logical) ~= "number" then
    return nil
  end
  local ok, p = pcall(VRFW.call, LOGICAL_TO_PHYSICAL, 0, logical)
  if ok and type(p) == "number" and p >= 0 and p < L.set_count then
    return p
  end
  return nil
end

--- VRFW.squads.active([party]): the active squad number, or nil. Call: in a handler (not while the script loads).
function M.active(party)
  local L = M.layout()
  if L == nil or not Memory.is_pointer(party) then
    return nil
  end
  return Memory.read("u8", party + L.active)
end

--- VRFW.squads.squad(logical[, party]): the address of a squad by its shown number, or nil. Call: in a handler (not while the script loads).
function M.squad(logical, party)
  local L = M.layout()
  if L == nil or not Memory.is_pointer(party) then
    return nil
  end
  local data = Memory.read_pointer(party + L.sets)
  local p = data and M.physical_index(logical)
  if p == nil then
    return nil
  end
  return data + p * L.set_size
end

--- Internal: The address of team `team` of `squad`; nil when unreadable.
function M.team(squad, team)
  local L = M.layout()
  if L == nil or not Memory.is_pointer(squad) or type(team) ~= "number" then
    return nil
  end
  return squad + team * L.team_size
end

--- VRFW.squads.members(squad, team): the member addresses of one team of a squad, as a list. Call: in a handler (not while the script loads).
function M.members(squad, team)
  local out = {}
  local L = M.layout()
  local first = M.team(squad, team)
  if first == nil then
    return out
  end
  first = first + L.members
  local handles = VRFW.memory.read_array("u32", first + L.member_handle, L.member_count, L.member_size)
  local ok = handles ~= nil
  if not ok or type(handles) ~= "table" then
    return out
  end
  for k = 0, L.member_count - 1 do
    local handle = handles[k + 1] or 0
    if handle ~= 0 then
      out[#out + 1] = { slot = k, handle = handle, address = first + k * L.member_size }
    end
  end
  return out
end

--- Advanced: Makes the game recount the team at `team_address`: true; false, why.
function M.recount(team_address)
  local ok, e = pcall(VRFW.call, RECOUNT_TEAM_INFO, team_address)
  if ok then
    return true
  end
  return false, tostring(e)
end

--- Advanced: Sets the organized flag of `member` in dock `dock`: true; false, why.
function M.set_organized(member, dock, on)
  local ok, e = pcall(VRFW.call, SET_ORGANIZED_FLAG_BIT, member, dock, on)
  if ok then
    return true
  end
  return false, tostring(e)
end

return M
