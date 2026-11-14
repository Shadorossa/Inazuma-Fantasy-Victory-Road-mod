
local U = require "lib/util"
local TeamConfig = VRFW.teams.config

local M = {}

local MATCH_TEAMS_KEY = "VRFW.team_lineup.match_teams"
local TEAM_FIRST, TEAM_STRIDE = VRFW.game.field("MatchInfo.Teams"), VRFW.game.field("MatchTeam")
local USER_SIDE = VRFW.game.field("MatchInfo.UserTeam")
-- The match team's uniform and alternate flag have no game profile name.
local TEAM_UNIFORM, TEAM_ALTERNATE = 0x1040, 0x1101
local STAFF_FLAGS = 0x30

local logged = {}

local log = VRFW.logger("kit diag")

local function declared_kit(team)
  if not team or team == 0 then
    return 0
  end
  local rec = TeamConfig.find(team)
  if not rec then
    return 0
  end
  return VRFW.ids.unsigned(U.get(VRFW.memory.struct("ActiveTeamRecord", rec), "uniform") or 0)
end

local function teams_by_side(match)
  local ok, block = pcall(VRFW.state.get, MATCH_TEAMS_KEY)
  if not ok or type(block) ~= "number" or block < 0x10000 then
    return {}
  end
  local user = VRFW.memory.read("u8", match + USER_SIDE) or 0
  if user > 1 then
    return {}
  end
  return { [user] = VRFW.memory.read("u32", block) or 0, [1 - user] = VRFW.memory.read("u32", block + 4) or 0 }
end

local function on_look(ev)
  if logged[0] and logged[1] then
    return nil
  end
  local args = ev and ev.args
  local flags, uniform = args and tonumber(args[2]), args and tonumber(args[4])
  if not flags or not uniform or math.floor(flags / 16) % 4 ~= 0 then
    return nil
  end
  local match = VRFW.game.global("kit_diag_match")
  if not match then
    return nil
  end
  local alt = math.floor(flags / 2) % 2
  local block = {}
  for side = 0, 1 do
    local at = match + TEAM_FIRST + side * TEAM_STRIDE
    block[side] = { uniform = VRFW.ids.unsigned(VRFW.memory.read("u32", at + TEAM_UNIFORM) or 0), alternate = VRFW.memory.read("u8", at + TEAM_ALTERNATE) or 0 }
  end
  uniform = VRFW.ids.unsigned(uniform)
  local side
  if block[0].uniform ~= block[1].uniform then
    side = (uniform == block[0].uniform and 0) or (uniform == block[1].uniform and 1) or nil
  elseif uniform == block[0].uniform then
    side = (alt == block[0].alternate and 0) or (alt == block[1].alternate and 1) or nil
  end
  if side == nil or logged[side] then
    return nil
  end
  logged[side] = true
  local teams = teams_by_side(match)
  local other = 1 - side
  local user = VRFW.memory.read("u8", match + USER_SIDE)
  log(string.format("side %d (%s) team %s declared kit %s match uniform %s dressed typeId %d (alternative bit %d, team alternate flag %d) rival kit %s (declared %s)",
    side, user == side and "user" or "cpu", VRFW.ids.hex_text(teams[side] or 0), VRFW.ids.hex_text(declared_kit(teams[side])), VRFW.ids.hex_text(block[side].uniform),
    alt, alt, block[side].alternate, VRFW.ids.hex_text(block[other].uniform), VRFW.ids.hex_text(declared_kit(teams[other]))))
  return nil
end

VRFW.on("match:start", function()
  logged = {}
  return nil
end)
VRFW.on("hook:VRFW.MatchLook", on_look)

return M
