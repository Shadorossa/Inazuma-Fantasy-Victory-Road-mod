--- Advanced: Library: team_config roster slots; tells staff from players.

local M = {}

--- roster slots of team_config (retail): 16-18 managers, 19 coach; 0-15 and 20+ are players
M.FIRST_MANAGER_SLOT, M.LAST_MANAGER_SLOT, M.COACH_SLOT = 16, 18, 19

--- Advanced: true when roster slot `slot` holds staff (a manager or the coach)
function M.is_staff(slot)
  return slot == M.COACH_SLOT or (slot >= M.FIRST_MANAGER_SLOT and slot <= M.LAST_MANAGER_SLOT)
end

--- Advanced: the team_config record and container of team `team` (its id): rec, cont; nil, why
function M.find(team)
  if not VRFW.is_on("Team.FindConfig") then return nil, "FindTeamConfig not resolved" end
  local recb = VRFW.memory.buffer("vrfw_team_config_record", 8)
  local okb = recb ~= nil
  local contb = VRFW.memory.buffer("vrfw_team_config_container", 8)
  local okc = contb ~= nil
  local hashb = VRFW.memory.buffer("vrfw_team_config_hash", 4)
  local okh = hashb ~= nil
  if not (okb and okc and okh) then return nil, "no native buffer" end
  local id = VRFW.ids.unsigned(team)
  VRFW.memory.write("u64", recb, 0)
  VRFW.memory.write("u64", contb, 0)
  VRFW.memory.write("u32", hashb, id)
  local ok, e = pcall(VRFW.call, "Team.FindConfig", recb, contb, hashb)
  if not ok then return nil, "FindTeamConfig faulted (" .. tostring(e) .. ")" end
  local rec, cont = VRFW.memory.read_pointer(recb), VRFW.memory.read_pointer(contb)
  if not rec or not cont then return nil, string.format("team 0x%08X not in team_config", id) end
  return rec, cont
end

return M
