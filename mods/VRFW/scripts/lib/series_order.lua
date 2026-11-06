-- Series order of teams (by crest) and characters: an alias of lib/game_catalogue, where the one series-order rule lives.
--   local Order = require "VRFW/lib/series_order"
--   Order.crest(emblem)         -> Catalogue.crest_rank(emblem)
--   Order.team_crest(team, era) -> rank of a belong team in the first series type its crest era serves
--   Order.character(base)       -> Catalogue.character_rank(base)
--   Order.team_emblem(team, series) -> the crest of the series type's era, else the team's first era with one (0 = none)

local Catalogue = require "VRFW/lib/game_catalogue"

local M = {}
M.NONE = Catalogue.NO_RANK

function M.crest(emblem) return Catalogue.crest_rank(emblem) end

-- era: 1-based index of the belong table's team_emblem_id_<era> columns
function M.team_crest(team, era)
  local k = Catalogue.first_type_of_era(era) or #Catalogue.series_types()
  return Catalogue.team_rank(team, k)
end

function M.team_emblem(team, series)
  local emblems = Catalogue.era_crests(team)
  local era = Catalogue.era_of_type(math.floor(tonumber(series) or 0))
  if era and (emblems[era] or 0) ~= 0 then return emblems[era] end
  for ei = 1, #emblems do
    if emblems[ei] ~= 0 then return emblems[ei] end
  end
  return 0
end

function M.character(base) return Catalogue.character_rank(base) end

return M
