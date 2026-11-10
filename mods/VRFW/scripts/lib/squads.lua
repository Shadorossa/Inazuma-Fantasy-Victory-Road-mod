local Memory = VRFW.memory

local M = {}

local LOGICAL_TO_PHYSICAL = "Party.LogicalToPhysical"
local RECOUNT_TEAM_INFO = "Party.RecountTeamInfo"
local SET_ORGANIZED_FLAG_BIT = "Party.SetOrganizedFlagBit"

local LAYOUT = nil
local LAYOUT_WHY = nil

local function profile_value(name)
  local ok, v = pcall(VRFW.game.field, name)
  if ok and type(v) == "number" then
    return v
  end
  return nil
end

--- The squad layout from the game profile; nil, why when a field is missing.
function M.layout()
  if LAYOUT ~= nil or LAYOUT_WHY ~= nil then
    return LAYOUT, LAYOUT_WHY
  end
  local names = {
    sets = "Party.TeamSets", set_count = "Party.TeamSetCount", active = "Party.ActiveTeamSet", set_size = "TeamSet",
    team_size = "TeamInfo", members = "TeamInfo.Members", member_count = "Party.TeamSetMemberCount",
    member_size = "TeamSetMember", member_handle = "TeamSetMember.Handle",
  }
  local out = {}
  for key, name in pairs(names) do
    local v = profile_value(name)
    if v == nil then
      LAYOUT_WHY = "the game profile has no " .. name
      VRFW.warn("party_squads: " .. LAYOUT_WHY)
      return nil, LAYOUT_WHY
    end
    out[key] = v
  end
  LAYOUT = out
  return LAYOUT
end

--- The stored index of logical squad `logical`; nil when out of range.
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

--- The active squad of `party`; nil when unreadable.
function M.active(party)
  local L = M.layout()
  if L == nil or not Memory.is_pointer(party) then
    return nil
  end
  return Memory.read("u8", party + L.active)
end

--- The address of logical squad `logical`; nil when unreadable.
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

--- The address of team `team` of `squad`; nil when unreadable.
function M.team(squad, team)
  local L = M.layout()
  if L == nil or not Memory.is_pointer(squad) or type(team) ~= "number" then
    return nil
  end
  return squad + team * L.team_size
end

--- The member addresses of team `team` of `squad`, as an array.
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

--- Makes the game recount the team at `team_address`: true; false, why.
function M.recount(team_address)
  local ok, e = pcall(VRFW.call, RECOUNT_TEAM_INFO, team_address)
  if ok then
    return true
  end
  return false, tostring(e)
end

--- Sets the organized flag of `member` in dock `dock`: true; false, why.
function M.set_organized(member, dock, on)
  local ok, e = pcall(VRFW.call, SET_ORGANIZED_FLAG_BIT, member, dock, on)
  if ok then
    return true
  end
  return false, tostring(e)
end

return M
