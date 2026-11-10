-- Campaign end window
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
do
  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    if a1 == 2895249556 --[[cmn03_06_sel_button]] and a2 == 0 then
      local t = BattleBayDeluxe.tournament_info()
      if t.active and t.loaded then   -- a tournament match, not a campaign match while a tournament exists
        BattleBayDeluxe.tournament_log("end window: continue -> back to the Battle Bay (tournament)")
        return decide(a1, 1, ...)
      end
    end
    return decide(a1, a2, ...)
  end
end

-- A won match that ends the run (INFO ends_run)
BattleBayDeluxe.tournament_end_window = {
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

function BattleBayDeluxe.tournament_end_window_only_next()
  local t = BattleBayDeluxe.tournament_info()
  return t.active == true and t.loaded == true and t.ends_run == true
end

-- Layers hidden in that case
function BattleBayDeluxe.tournament_end_window_hides_layer(layer, instance)
  local W = BattleBayDeluxe.tournament_end_window
  return layer == W.TELOP or (layer == W.BUTTON and instance == 1)
end

do
  local setup_layer = OnSetupLayer
  function OnSetupLayer(a1, a2, ...)
    local r = table.pack(setup_layer(a1, a2, ...))
    local W = BattleBayDeluxe.tournament_end_window
    if (a1 == W.BUTTON or a1 == W.TELOP) and BattleBayDeluxe.tournament_end_window_only_next() then
      if BattleBayDeluxe.tournament_end_window_hides_layer(a1, a2) then
        funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
      elseif a2 == 0 then
        funcLuaMenuCommand(W.LIST_COUNT, a1, 1)
        funcLuaMenuCommand(W.FOCUS_ENABLE, a1, W.FOCUS_NEXT, false)
        local text = funcLuaCommand(@crc:CMND_TEXT_GET@, W.NEXT_TEXT)
        funcLuaMenuCommand(W.SET_TEXT, a1, W.TEXT_OFF, text, a2)
        funcLuaMenuCommand(W.SET_TEXT, a1, W.TEXT_ON, text, a2)
        BattleBayDeluxe.tournament_log("end window: no match left in the run, only Next")
      end
    end
    return table.unpack(r, 1, r.n)
  end

  local open_layer = OnOpenLayer
  function OnOpenLayer(a1, a2, ...)
    local r = table.pack(open_layer(a1, a2, ...))
    if BattleBayDeluxe.tournament_end_window_hides_layer(a1, a2) and BattleBayDeluxe.tournament_end_window_only_next() then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
    end
    return table.unpack(r, 1, r.n)
  end
end
