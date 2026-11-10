-- Game-over telop
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.tournament_game_over = { MENU = 2754376147 --[[game_over_menu]], TELOP = 3428917655, CLOSE_AFTER = 6, GIVE_UP = 240,
  state = nil, steps = 0 }

-- The logger is created on first use.
function BattleBayDeluxe.tournament_over_log(...)
  BattleBayDeluxe.tournament_game_over.logger = BattleBayDeluxe.tournament_game_over.logger or VRFW.logger.new("BattleBayDeluxe.tournament")
  BattleBayDeluxe.tournament_game_over.logger(...)
end

do
  local open_layer = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    if a1 == BattleBayDeluxe.tournament_game_over.TELOP and BattleBayDeluxe.tournament_game_over.state == nil then
      local still_in = VRFW.host.command(@crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_STILL_IN@)
      if still_in == true then
        BattleBayDeluxe.tournament_over_log(
          "game over skipped (a league match, or a group-stage defeat that keeps the player in the run): the menu closes")
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2 or 0, false)
        BattleBayDeluxe.tournament_game_over.state, BattleBayDeluxe.tournament_game_over.steps = "skip", 0
        return
      end
      BattleBayDeluxe.tournament_game_over.state = "retail"
    end
    return open_layer(a1, a2, ...)
  end

  local step = Step
  function Step(...)
    local O = BattleBayDeluxe.tournament_game_over
    if O.state == "skip" or O.state == "closing" then
      O.steps = O.steps + 1
      if O.state == "skip" and O.steps >= O.CLOSE_AFTER then
        O.state = "closing"
        RunManageCoroutine(2)
        BattleBayDeluxe.tournament_over_log(
          "game over skipped: the retail close started after " .. O.steps .. " Steps")
      elseif O.state == "closing" and O.steps >= O.GIVE_UP then
        -- The menu did not close
        O.state = "retail"
        BattleBayDeluxe.tournament_over_log(
          "game over skip: the menu did not close in " .. O.GIVE_UP .. " Steps; the retail telop is shown")
        VRFW.host.command(609722083 --[[fade black]], 0, 0.3)
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, O.TELOP, 0, true)
        RunManageCoroutine(1)
      end
    end
    return step(...)
  end
end
