-- OnInit reads the campaign block.
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.draft_top_menu = {
  SYNC = @crc:CMND_BATTLEBAYDELUXE_CAMPAIGN_SYNC@,
}

-- The logger (VRFW.logger) is created on the first call.
function BattleBayDeluxe.draft_top_log(...)
  BattleBayDeluxe.draft_top_menu.logger = BattleBayDeluxe.draft_top_menu.logger or VRFW.logger.new("BattleBayDeluxe.draft_top")
  BattleBayDeluxe.draft_top_menu.logger(...)
end

function BattleBayDeluxe.draft_top_sync()
  BattleBayDeluxe.draft_top_log("sync", funcLuaCommand(BattleBayDeluxe.draft_top_menu.SYNC))
end

do
  Wrap("BattleBayDeluxe.draft_top", "OnInit", { around = function(init, ...)
    local ok, err = pcall(BattleBayDeluxe.draft_top_sync)
    if not ok then
      BattleBayDeluxe.draft_top_log("sync error", tostring(err))
    end
    return init(...)
  end })
end
