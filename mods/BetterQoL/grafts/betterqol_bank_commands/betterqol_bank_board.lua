-- Ability board opened from the bank for a player in no dock slot
do
  BetterQoL = BetterQoL or {}
  BetterQoL.bank_board = BetterQoL.bank_board or {}
  local U = BetterQoL.bank_board
  U.NO_SLOT = 255
  U.logged = false
  local cur = rawget(_ENV, "UpdateAbilityLearningBoardCharaCard")
  if type(cur) == "function" and not U.wrapped then
    U.wrapped = true
    -- (charaStHdl, showTeamDockNo, teamDockType, formationId, selectCharaIdx, isScout)
    rawset(_ENV, "UpdateAbilityLearningBoardCharaCard", function(a1, a2, a3, a4, a5, ...)
      if type(a5) ~= "number" then
        if not U.logged then
          U.logged = true
          pcall(funcLuaCommand, 519897777 --[[CMND_VRFW_LOG]], "BetterQoL bank_commands", "board card: player not in dock",
            a2, "kind", a3, "chara", a1, "slot", tostring(a5), "->", U.NO_SLOT)
        end
        a5 = U.NO_SLOT
      end
      return cur(a1, a2, a3, a4, a5, ...)
    end)
  end
end
