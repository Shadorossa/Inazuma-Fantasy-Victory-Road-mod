-- Battle Bay Deluxe: the champions' celebration when the player wins a competition (the Torneo, the Liga, the Campaña,
-- the Reto diario). The celebration itself is the framework's (signal vrfw.trophy, docs/framework/trophy.md): each
-- caller only decides whether the finished match wins its competition (its own rule) and calls Trophy.play, which
-- names the competition on the photo's plate and sends the signal.

local U = require "lib/util"

local Trophy = {}

-- the competitions and the text key of the name the photo scene's tournament plate shows
local COMPETITION_NAMES = {
  tournament = "evt_bbd_tn_mode_tournament",
  league = "evt_bbd_tn_mode_league",
  campaign = "evt_bbd_tn_mode_campaign",
  daily_challenge = "evt_bbd_dc_daily",
}

require "VRFW/lib/basics"
local warn = select(2, VRFW.logger("trophy celebration"))

-- another mod's competition sent without a name shows the Torneo's name on the photo's plate
pcall(VRFW.state.set, "vrfw.trophy.default_name", COMPETITION_NAMES.tournament)

-- the framework's result of the finished match (VRFW lib/match_result), nil when none was sent
function Trophy.last_result()
  local last = require("VRFW/lib/match_result").last()
  if type(last) == "table" then
    return last
  end
  return nil
end

-- the rival team of the match being played (the match setup's team record of the side that is not the user's), 0 when
-- not readable
function Trophy.rival_team()
  local mi, party = U.global("trophy_match"), U.global("trophy_party")
  local user = mi and U.rd("u8", mi + 0x2C29)
  if not party or not user or user > 1 then
    return 0
  end
  return U.u32(U.rd("u32", party + 0x1E0 + (1 - user) * 0x4A8) or 0)
end

-- the finished match wins `competition` (one of COMPETITION_NAMES): the framework plays the celebration after its full
-- time when the player won the match (it reads the game's own result itself). true when the signal was sent.
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
