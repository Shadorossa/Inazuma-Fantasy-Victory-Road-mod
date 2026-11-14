-- Top menu part
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}


-- Tournament entry, in the decide coroutine
function BattleBayDeluxe.tournament_entry_tournament(flow, ...)
  BattleBayDeluxe.tournament_state.entry = true
  local ok, r = pcall(flow or BattleBayDeluxe.tournament_entry_flow, ...)
  BattleBayDeluxe.tournament_state.entry = false
  if not ok then
    error(r, 0)
  end
  return r
end

-- Tournament panel over the bracket
function BattleBayDeluxe.tournament_entry_flow()
  while true do
    local info = BattleBayDeluxe.tournament_info_no_ended()
    if not (info.active or info.ended) then
      return BattleBayDeluxe.tournament_new_run()
    end
    -- A running league opens its career hub.
    if info.active and info.fmt == 2 then
      return BattleBayDeluxe.tournament_league_hub()
    end
    BattleBayDeluxe.tournament_open(BattleBayDeluxe.tournament_entry_page())
    -- A league's panel uses the <key>_league texts.
    local lg = info.fmt == 2
    local cont, view, new = BattleBayDeluxe.tournament_id(BattleBayDeluxe.tournament_run_key("continue", lg)), BattleBayDeluxe.tournament_id(BattleBayDeluxe.tournament_run_key("view", lg)),
      BattleBayDeluxe.tournament_id(BattleBayDeluxe.tournament_run_key("new", lg))
    local ids = { cont, view, new }
    -- The host menu's input is never switched (it disturbs the engine's input).
    local c = BattleBayDeluxe.tournament_choose(ids, 0)
    local id = ids[c + 1]
    if c < 0 or id == nil then
      if BattleBayDeluxe.tournament_state.open then
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@)
        BattleBayDeluxe.tournament_close()
      end
      return
    end
    if id == cont then
      BattleBayDeluxe.tournament_on_enter()
      return
    end
    if id == view then
      return
    end
    if BattleBayDeluxe.tournament_entry_new(info) then
      return
    end
  end
end

-- New tournament / league over the run in info
function BattleBayDeluxe.tournament_entry_new(info)
  if info.active then
    local a = BattleBayDeluxe.tournament_choose({ BattleBayDeluxe.tournament_id("new_yes"), BattleBayDeluxe.tournament_id("new_no") }, 1)
    BattleBayDeluxe.tournament_log("new tournament: answer", a == 0 and "yes" or "no", a)
    if a ~= 0 then
      return false
    end
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.ABANDON)
    BattleBayDeluxe.tournament_log("new tournament: the running one abandoned")
  else
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.CLOSE)
    BattleBayDeluxe.tournament_log("new tournament: the ended one put aside")
  end
  VRFW.host.command(BattleBayDeluxe.tournament.RULE_SELECT, "")
  if BattleBayDeluxe.tournament_state.open then
    BattleBayDeluxe.tournament_close()
  end
  BattleBayDeluxe.tournament_new_run(info.fmt == 2 and 2 or -1)
  return true
end

-- One saved run per slot
function BattleBayDeluxe.tournament_info_no_ended()
  local info = BattleBayDeluxe.tournament_info()
  if info.ended and not info.active then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.CLOSE)
    info = BattleBayDeluxe.tournament_info()
  end
  return info
end

-- One saved run per slot
function BattleBayDeluxe.tournament_confirm_over_campaign()
  if funcLuaMenuCommand(BattleBayDeluxe.tournament.CAMPAIGN, 0) ~= true then
    return true
  end
  local a = BattleBayDeluxe.tournament_choose({ BattleBayDeluxe.tournament_id("replace_campaign_yes"), BattleBayDeluxe.tournament_id("new_no") }, 1)
  BattleBayDeluxe.tournament_log("new run over a saved campaign: answer", a == 0 and "yes" or "no", a)
  return a == 0
end

-- Starts a new run.
function BattleBayDeluxe.tournament_new_run(fmt)
  if not BattleBayDeluxe.tournament_confirm_over_campaign() then
    return
  end
  local armed, why = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.ARM, fmt or -1, 0, 0)
  if armed ~= true then
    BattleBayDeluxe.tournament_log("not armed", tostring(armed), tostring(why))
    return
  end
  -- The grid opens the host's way (BattleBayDeluxe.tournament_host.open_grid).
  BattleBayDeluxe.tournament_log("new tournament: armed, team grid opens on", BattleBayDeluxe.tournament_host.name)
  BattleBayDeluxe.tournament_state.newrun = true
  local okg, errg = pcall(BattleBayDeluxe.tournament_host.open_grid)
  BattleBayDeluxe.tournament_state.newrun = false
  if not okg then
    error(errg, 0)
  end
  -- Grid not opened (the menu never settled)
  if errg == false then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.DISARM)
    BattleBayDeluxe.tournament_log("new tournament: the team grid did not open, the run is disarmed")
    return
  end
  BattleBayDeluxe.tournament_log("new tournament: team grid closed")
  -- Handles going back from the grid.
  local i3 = BattleBayDeluxe.tournament_info()
  if i3.active and i3.fmt == 2 then
    return BattleBayDeluxe.tournament_league_hub()
  elseif i3.active then
    BattleBayDeluxe.tournament_open(BattleBayDeluxe.tournament_entry_page())
  elseif i3.armed then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.DISARM)
  end
end

-- The campaign row of the list
function BattleBayDeluxe.tournament_campaign_row()
  for _, l in ipairs({ BattleBayDeluxe.tournament.LIST_MID, BattleBayDeluxe.tournament.LIST_SMALL }) do
    local n = GetNumUsedButtons(l) or 0
    for i = 0, n - 1 do
      local info = GetLitItemInfo(l, i)
      if info ~= nil and info.menuObjectName == BattleBayDeluxe.tournament.ROW_CAMPAIGN then
        return l, i, n
      end
    end
  end
  return nil
end

-- Focuses the campaign row the retail way
function BattleBayDeluxe.tournament_focus_campaign_row()
  local l, i, n = BattleBayDeluxe.tournament_campaign_row()
  if l == nil then
    l, i, n = BattleBayDeluxe.tournament.LIST_MID, 0, GetNumUsedButtons(BattleBayDeluxe.tournament.LIST_MID) or 1
  end
  for _, other in ipairs({ BattleBayDeluxe.tournament.LIST_MID, BattleBayDeluxe.tournament.LIST_SMALL }) do
    if other ~= l then
      funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, other, false)
    end
  end
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, l, true)
  funcLuaMenuCommand(1778826357 --[[set focus index]], l, i, true)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@ --[[button anime]], l, i, @crc:Active@, 0 --[[lit]], @crc:button@)
  funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, l, @crc:cursor@, i, n)
  pcall(SelectListItem, l)
  pcall(UpdateContentGuide, i)
  return l, i
end

-- Next-stage badge under the campaign row
BattleBayDeluxe.tournament.BADGE = @crc:vs11_01_next_stage_guide@
BattleBayDeluxe.tournament.BADGE_TEXT = @crc:_text_btn_next01@
BattleBayDeluxe.tournament.BADGE_KEYS = { league = "badge_league", groups = "badge_groups", ko = "badge_ko" }
function BattleBayDeluxe.tournament_next_badge(info, inst)
  if BattleBayDeluxe.tournament_host.name ~= "bb_stadium_top_menu" or type(info) ~= "table" or not info.active then
    return false
  end
  local key = BattleBayDeluxe.tournament.BADGE_KEYS[info.next_stage or ""]
  if key == nil then
    return false
  end
  inst = inst or 0
  local rival = info.rival or 0
  local name = rival ~= 0 and VRFW.team.name(rival) or ""
  if name == "" then
    name = BattleBayDeluxe.tournament_text("sched_rival_tbd")
  end
  local round = info.next_stage == "ko" and BattleBayDeluxe.tournament_text("round_" .. tostring(info.next_round or 1)) or ""
  local s = BattleBayDeluxe.tournament_text_value(key, info.next_round or 0)
  s = s:gsub("<ROUND>", function() return round end):gsub("<NAME>", function() return name end)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, BattleBayDeluxe.tournament.BADGE, BattleBayDeluxe.tournament.BADGE_TEXT, s, inst, 0, true)
  funcLuaMenuCommand(@crc:CMND_UPDATE_TEXT_PLATE@ --[[fit the text]], BattleBayDeluxe.tournament.BADGE, inst, BattleBayDeluxe.tournament.BADGE_TEXT)
  if rival ~= 0 then
    local _, tex = VRFW.host.command(2151743654 --[[team info]], rival, 6 --[[crest]], 0)
    if tex ~= nil then
      funcLuaMenuCommand(3190452549, BattleBayDeluxe.tournament.BADGE, inst, @crc:_emblem_s_dmy01@, @crc:emblem_s_dmy01@, tex, 0, true, true)
    end
  end
  return true
end

-- Decides the campaign row in a coroutine
function BattleBayDeluxe.tournament_decide_campaign_row(mode)
  local l, i, n = BattleBayDeluxe.tournament_campaign_row()
  if l == nil then
    BattleBayDeluxe.tournament_log("no campaign row in the list:", mode)
    return false
  end
  BattleBayDeluxe.tournament_state.row_mode = mode
  BattleBayDeluxe.tournament_focus_campaign_row()
  BattleBayDeluxe.tournament_state.co = coroutine.create(function()
    OnDecideFocus(l, i)
  end)
  BattleBayDeluxe.tournament_log("campaign row decided in mode", mode)
  return true
end

-- Top bar step battlebaydeluxe_tournament
function BattleBayDeluxe.tournament_decide_row()
  BattleBayDeluxe.tournament_decide_campaign_row("tournament")
end
