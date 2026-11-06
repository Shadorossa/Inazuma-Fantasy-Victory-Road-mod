-- BattleBayDeluxe bb_tournament, campaign end window (bb_stadium_campaign_end_window; docs/game/modes/bb-tournament.md
-- §5.3). After a won match the game asks «continue / back to the Battle Bay»; during a tournament both answers go back
-- to the Battle Bay top menu (choice 1): there the tournament records the result, simulates the round and shows the
-- results and the bracket before the next match (Enter there = the next match). Its «next stage» telop reads the
-- match number through the tournament (bbt_common.lua). Globals only; nothing runs at chunk load.
do
  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    if a1 == 2895249556 --[[cmn03_06_sel_button]] and a2 == 0 then
      local t = BBT_Info()
      if t.active and t.loaded then   -- a tournament match (not a Campaña match while a Torneo exists)
        BBT_Log("end window: continue -> back to the Battle Bay (tournament)")
        return decide(a1, 1, ...)
      end
    end
    return decide(a1, a2, ...)
  end
end

-- A won tournament match that leaves the player no match (the final, the league's last matchday, a last group match
-- that does not qualify; CMND_BBD_TOURN_INFO ends_run): the window has one button, the game's «Next», and no «Match No.
-- N» telop. Its decide takes the same way back to the top menu as above, where the sync ends the run.
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.TournamentEndWindow = {
  BUTTON = 2895249556 --[[cmn03_06_sel_button]],
  TELOP = 1676279530 --[[vs11_03_next_stage_telop]],
  NEXT_TEXT = 1834965033 --[[menu_text row 0x6D5F5829: Next]],
  TEXT_OFF = 2729666850 --[[_text_cmd_off01]],
  TEXT_ON = 1317518280 --[[_text_cmd_on01]],
  FOCUS_NEXT = 2734193315 --[[CMD_FCS_NEXT]],
  FOCUS_ENABLE = 2559269762,
  LIST_COUNT = 3252599449,
  SET_TEXT = 1083631230 --[[CMND_SET_MENU_TEXT_STRING]],
}

function BBT_EndWindowOnlyNext()
  local t = BBT_Info()
  return t.active == true and t.loaded == true and t.ends_run == true
end

-- what is hidden: the second button and the telop
function BBT_EndWindowHidesLayer(layer, instance)
  local W = BattleBayDeluxe.TournamentEndWindow
  return layer == W.TELOP or (layer == W.BUTTON and instance == 1)
end

do
  local setup_layer = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local r = table.pack(setup_layer(a1, a2, ...))
    local W = BattleBayDeluxe.TournamentEndWindow
    if (a1 == W.BUTTON or a1 == W.TELOP) and BBT_EndWindowOnlyNext() then
      if BBT_EndWindowHidesLayer(a1, a2) then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
      elseif a2 == 0 then
        funcLuaMenuCommand(W.LIST_COUNT, a1, 1)
        funcLuaMenuCommand(W.FOCUS_ENABLE, a1, W.FOCUS_NEXT, false)
        local text = funcLuaCommand(@crc:CMND_TEXT_GET@, W.NEXT_TEXT)
        funcLuaMenuCommand(W.SET_TEXT, a1, W.TEXT_OFF, text, a2)
        funcLuaMenuCommand(W.SET_TEXT, a1, W.TEXT_ON, text, a2)
        BBT_Log("end window: no match left in the run, only Next")
      end
    end
    return table.unpack(r, 1, r.n)
  end

  local open_layer = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    local r = table.pack(open_layer(a1, a2, ...))
    if BBT_EndWindowHidesLayer(a1, a2) and BBT_EndWindowOnlyNext() then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
    end
    return table.unpack(r, 1, r.n)
  end
end
