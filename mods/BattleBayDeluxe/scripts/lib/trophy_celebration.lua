
local U = require "lib/util"

local Trophy = {}

-- the competitions and the text key of the name the photo scene's tournament plate shows
local COMPETITION_NAMES = {
  tournament = "battlebaydeluxe_tn_mode_tournament",
  league = "battlebaydeluxe_tn_mode_league",
  campaign = "battlebaydeluxe_tn_mode_campaign",
  daily_challenge = "battlebaydeluxe_dc_daily",
}

local warn = select(2, VRFW.logger("trophy celebration"))

-- another mod's competition sent without a name shows the Torneo's name on the photo's plate
pcall(VRFW.state.set, "vrfw.trophy.default_name", COMPETITION_NAMES.tournament)

function Trophy.last_result()
  local last = VRFW.match.results.last()
  if type(last) == "table" then
    return last
  end
  return nil
end

function Trophy.rival_team()
  local mi, party = U.global("trophy_match"), U.global("trophy_party")
  local user = mi and U.rd("u8", mi + 0x2C29)
  if not party or not user or user > 1 then
    return 0
  end
  return U.u32(U.rd("u32", party + 0x1E0 + (1 - user) * 0x4A8) or 0)
end

function Trophy.play(competition)
  local name = COMPETITION_NAMES[competition]
  if not name then
    warn("unknown competition " .. tostring(competition) .. ": no celebration")
    return false
  end
  pcall(VRFW.state.set, "vrfw.trophy.name", name)
  local ok, e = pcall(VRFW.signal, "vrfw.trophy")
  if not ok then
    warn(competition .. " won, but the signal vrfw.trophy was not sent: " .. tostring(e))
  end
  return ok
end

return Trophy
