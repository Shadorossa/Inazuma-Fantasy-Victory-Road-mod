--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
do
  Wrap("BattleBayDeluxe.daily_challenge_end", "OnDecideFocus", { around = function(decide, a1, a2, ...)
    if a1 == @crc:cmn03_06_sel_button@ and a2 == 0 then
      if BattleBayDeluxe.tournament_call(@crc:CMND_BATTLEBAYDELUXE_DAILY_LOADED@) == true then
        BattleBayDeluxe.tournament_log("daily: end window: continue -> back to the Battle Bay")
        return decide(a1, 1, ...)
      end
    end
    return decide(a1, a2, ...)
  end })
end
