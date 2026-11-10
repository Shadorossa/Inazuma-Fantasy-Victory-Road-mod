BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}

if BetterQoL.club_stats_visit == nil then
  BetterQoL.club_stats_visit = {
    PAGE = 2762561604,                    -- betterqol_club_stats_menu
    HEADER_TYPE = 13,
    GUIDE_PAGE = { {text = 2723098887 --[[BetterQoL.ClubStats.Sort]], icon = 2387151820 --[[<CMD_FUNC2>]],
                    command = 3170216173 --[[CMD_FUNC2]]} },
    co = nil,
  }
end

local CS = BetterQoL.club_stats_visit
local Caseta = BetterQoL.page.caseta
local Log = BetterQoL.page.logger("BetterQoL club_stats")

local function Visit()
  local row = Caseta.leave(CS.PAGE, CS.HEADER_TYPE, 1451400137 --[[BetterQoL.ClubStats.Row]], CS.GUIDE_PAGE)
  Log("page open asked (row " .. tostring(row) .. ")")
  Caseta.wait_closed(CS.PAGE)
  Caseta.go_back(row)
  Log("back from the page")
end

if BetterQoL.club_stats_visit.hooked == nil then
  BetterQoL.club_stats_visit.hooked = true
  CS.open = Caseta.visits(CS, Visit, Log, function() CS.co = nil end)
end
BetterQoL.club_stats = { open = CS.open }
