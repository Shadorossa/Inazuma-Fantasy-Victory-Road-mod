--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
do
  Wrap("BattleBayDeluxe.active_team_top", "OnInit", { around = function(init, ...)
    -- before the Campaña sync of this menu, which ends a saved run whose template has no 11 starters
    local okd, errd = pcall(function()
      BattleBayDeluxe.personal_run_hold("hub opened")
      BattleBayDeluxe.active_team.page = 0
      BattleBayDeluxe.personal_docks_sync("hub opened")
    end)
    if not okd then
      BattleBayDeluxe.active_team_log("personal docks error", tostring(errd))
    end
    local r = table.pack(init(...))
    local ok, err = pcall(BattleBayDeluxe.active_team_sync, "hub opened")
    if not ok then
      BattleBayDeluxe.active_team_log("hub sync error", tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end })
end
