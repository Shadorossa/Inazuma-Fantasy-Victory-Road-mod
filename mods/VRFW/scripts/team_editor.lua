-- Team editor: the kit of a team set's team (docs/framework/team-editor.md; content\game\team_editor.toml).

TeamEditor = TeamEditor or {}

local info = VRFW.logger("team_editor")

local MAX_SET = 16
local TEAMS = 2
local UNIFORM_TEAMS = 3   -- teams per set the uniform command reaches (11v11, 5v5, ...)
local KITLESS_KEY = "vrfw.team_uniform.kitless"

local Id = VRFW.ids
local ExpTable = VRFW.experience
local function u32(v) return Id.unsigned_or(v, nil) end

-- the TeamInfo record of (set, team), nil when the party is not there yet
local function team_info(set, team)
  local party = VRFW.game.TeamEditorParty()
  if not party then
    return nil
  end
  local ok, p = pcall(VRFW.call, "Team.SetStruct", party, set, team)
  if not ok or not p or p < 0x10000 then
    return nil
  end
  local rec = VRFW.memory.struct("TeamEditorTeamInfo", p)
  local ok2 = rec ~= nil
  return ok2 and rec or nil
end

function TeamEditor.SetKit(set, team, uniform)
  set, team, uniform = u32(set), u32(team), u32(uniform)
  if not set or not team or not uniform or uniform == 0 or set > MAX_SET or team >= TEAMS then
    return false, 0
  end
  local rec = team_info(set, team)
  if not rec then
    return false, 0
  end
  local okr, before = pcall(function() return rec.Uniform end)
  local ok = pcall(function()
    rec.Uniform = uniform
    rec.UniformItem = 0
  end)
  local okn, now = pcall(function() return rec.Uniform end)
  now = okn and now or 0
  info(string.format("set %d team %d: kit 0x%08X -> 0x%08X (ok %s)", set, team, okr and before or 0, now, tostring(ok)))
  return ok and now == uniform, now
end

-- a character record's EXP inside its current level (VRFW.character.record(handle).addr + 8)
local RECORD_EXP = 8

function TeamEditor.MemberExp(handle, share)
  handle, share = u32(handle), tonumber(share)
  if not handle or handle == 0 or share == nil then return false, 0 end
  local ok, rec = pcall(VRFW.character.record, handle)
  if not ok or type(rec) ~= "table" or not rec.addr or not tonumber(rec.level) then return false, 0 end
  local need = ExpTable.need(rec.level, rec.rarity)
  if not need then return false, 0 end
  local exp = math.max(0, math.min(math.floor(need) - 1, math.floor(need * math.max(0, math.min(1, share)))))
  if not VRFW.memory.write("u32", rec.addr + RECORD_EXP, exp) then return false, 0 end
  return true, exp
end

local function kitless_uniform()
  local ok, v = pcall(VRFW.state.get, KITLESS_KEY)
  v = ok and u32(v) or nil
  return v or 0
end

local function read_uniform(rec)
  local ok, v = pcall(function() return rec.Uniform end)
  return ok and v or 0
end

local uniform_logs = 0

function TeamEditor.Uniform(set, team, uniform, src_team)
  set, team = u32(set), u32(team)
  if not set or not team or set > MAX_SET or team >= UNIFORM_TEAMS then
    return false, 0
  end
  local rec = team_info(set, team)
  if not rec then
    return false, 0
  end
  local cur = read_uniform(rec)
  local new = u32(uniform)
  if not new then
    return true, cur
  end
  local allowed = cur ~= 0 and new ~= 0
  local src = u32(src_team)
  if not allowed and src and src < UNIFORM_TEAMS and src ~= team then
    local other = team_info(set, src)
    local src_cur = other and read_uniform(other) or 0
    allowed = src_cur ~= 0 and new == src_cur
  end
  if not allowed then
    local kitless = kitless_uniform()
    allowed = kitless ~= 0 and cur == 0 and new == kitless
  end
  if not allowed then
    VRFW.warn(string.format("team uniform refused: set %d team %d, 0x%08X -> 0x%08X", set, team, cur, new))
    return false, cur
  end
  local ok = true
  if new ~= cur then
    ok = pcall(function() rec.Uniform = new end)
  end
  if uniform_logs < 50 then
    uniform_logs = uniform_logs + 1
    local oki, item = pcall(function() return rec.UniformItem end)
    info(string.format("team uniform: set %d team %d (kit item 0x%08X): 0x%08X -> 0x%08X ok=%s", set, team,
      oki and item or 0, cur, new, tostring(ok)))
  end
  return ok, read_uniform(rec)
end
