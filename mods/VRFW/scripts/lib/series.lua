-- Series order of teams (by crest) and characters: an alias of lib/game_catalogue, where the one series-order rule lives.

local Catalogue = VRFW.catalogue

local M = {}
M.NONE = Catalogue.NO_RANK

--- The sort rank of crest `emblem`.
function M.crest(emblem) return Catalogue.crest_rank(emblem) end

--- era: 1-based index of the belong table's team_emblem_id_<era> columns
function M.team_crest(team, era)
  local k = Catalogue.first_type_of_era(era) or #Catalogue.series_types()
  return Catalogue.team_rank(team, k)
end

--- The crest of team `team` in series `series`.
function M.team_emblem(team, series)
  local emblems = Catalogue.era_crests(team)
  local era = Catalogue.era_of_type(math.floor(tonumber(series) or 0))
  if era and (emblems[era] or 0) ~= 0 then return emblems[era] end
  for ei = 1, #emblems do
    if emblems[ei] ~= 0 then return emblems[ei] end
  end
  return 0
end

--- The sort rank of character `base`.
function M.character(base) return Catalogue.character_rank(base) end

return M
