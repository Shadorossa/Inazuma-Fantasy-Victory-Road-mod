-- Battle Bay Deluxe «Reto diario», Battle Bay top menu (bb_stadium_top_menu; docs/game/modes/bb-daily-challenge.md).
--   * The «Campaña» row opens one window: «Continuar» (with the Campaña team's crest), «Nueva partida», «Reto diario».
--     A saved Campaña: the retail window itself (WaitExecOtherMenu), with the daily row added and its second row's text
--     changed; its «Continuar», its question and its Back stay retail. No saved Campaña: no «Continuar» row, the
--     Torneo / Liga panel's window (BBT_Choose), «Nueva partida» = the retail row's way (straight to the team grid). A
--     running or ended Torneo / Liga: BBT_Choose with its own first two rows (the entry flow; «Nuevo torneo» / «Nueva
--     liga» with its Yes / No). The row decided by the mode selector or the top bar (row_mode) gets no daily row.
--   * «Reto diario» starts the run's next match at once: it lends the campaign block to the run
--     (CMND_BBD_DAILY_PREPARE) and sends the game's campaign «continue» request, as the Torneo's next match does. When
--     the run cannot be prepared, a one-row notice (evt_bbd_dc_unavailable).
--   * Every opening of this menu first syncs the run (CMND_BBD_DAILY_SYNC, before the Torneo's sync and the retail
--     OnInit): the Campaña's block back and the last run match's result recorded.
-- The date: the framework's daily service (VRFW_Daily.Period("day"), the UTC day) as YYYYMMDD. Keys, pad and mouse:
-- the retail sub window's own. Globals only (BattleBayDeluxe.DailyChallenge*); nothing runs at chunk load.
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.DailyChallenge = BattleBayDeluxe.DailyChallenge or {}
BattleBayDeluxe.DailyChallenge.PREPARE = @crc:CMND_BBD_DAILY_PREPARE@
BattleBayDeluxe.DailyChallenge.UNLOAD = @crc:CMND_BBD_DAILY_UNLOAD@
BattleBayDeluxe.DailyChallenge.SYNC = @crc:CMND_BBD_DAILY_SYNC@
BattleBayDeluxe.DailyChallenge.ROW_CONTINUE = 2856747853   -- the retail window's first row text
BattleBayDeluxe.DailyChallenge.ROW_NEW = 1851993283        -- the retail window's second row text
BattleBayDeluxe.DailyChallenge.WINDOW_X = 1068             -- the retail window's centre x (sub window kind 20)
BattleBayDeluxe.DailyChallengeState = { sync = false, menu_open = false, no_daily = false }

function BBDC_Id(key)
  return BBT_Crc("evt_bbd_dc_" .. key)
end

-- the UTC day of the framework's daily service: YYYYMMDD; nil without the service
function BBDC_Today()
  if type(VRFW_Daily) ~= "table" or type(VRFW_Daily.Period) ~= "function" then
    return nil
  end
  local _, _, label = VRFW_Daily.Period("day")
  local y, m, d = tostring(label or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if y == nil then
    return nil
  end
  return tonumber(y) * 10000 + tonumber(m) * 100 + tonumber(d)
end

-- the «Campaña» row of the list at (layer, index)
function BBDC_IsCampaignRow(l, i)
  if (l ~= BattleBayDeluxe.Tournament.LIST_MID and l ~= BattleBayDeluxe.Tournament.LIST_SMALL) or BattleBayDeluxe.TournamentHost.name ~= "bb_stadium_top_menu" then
    return false
  end
  local ok, info = pcall(GetLitItemInfo, l, i)
  return ok and info ~= nil and info.menuObjectName == BattleBayDeluxe.Tournament.ROW_CAMPAIGN
end

-- the sub window fully gone (a window opened right after another one reads the old one's close)
function BBDC_WindowGone()
  local g = 0
  while funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.Tournament.SUB_WINDOW) == true and g < 300 do
    g = g + 1
    coroutine.yield()
  end
  for _ = 1, 6 do
    coroutine.yield()
  end
end

-- the «Campaña» row's window without the retail one (no saved Campaña, or a Torneo / Liga): "campaign" (the row's own
-- decide), "daily", "started" (a new Torneo / Liga went on) or nil (cancelled). Runs in the decide's coroutine.
function BBDC_CampaignMenu()
  while true do
    local t = BBT_InfoNoEnded()
    local run = t.active == true
    local league = t.fmt == 2
    local daily = BBDC_Id("daily")
    local ids = { BBDC_Id("new"), daily }
    if run then
      ids = { BBT_Id(BBT_RunKey("continue", league)), BBT_Id(BBT_RunKey("new", league)), daily }
    end
    local c = BBT_Choose(ids, 0, false, BattleBayDeluxe.DailyChallenge.WINDOW_X)
    local id = ids[c + 1]
    if c < 0 or id == nil then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 202039849 --[[sy0006]])
      BBDC_WindowGone()
      return nil
    end
    if id == daily then
      return "daily"
    end
    if not run or c == 0 then
      return "campaign"
    end
    if BBT_EntryTournament(BBT_EntryNew, t) then
      return "started"
    end
  end
end

-- the one-row notice when the day's run cannot be prepared
function BBDC_Unavailable(why)
  BBT_Log("daily: not available:", tostring(why))
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
  BBT_Choose({ BBDC_Id("unavailable") }, 0)
end

-- «Reto diario»: the run's next match on the lent campaign block, the game's campaign «continue» request (the request
-- and the way out of this menu are the Torneo's next match's, BBT_PlayNext); true when the match was requested
function BBDC_Play()
  local date = BBDC_Today()
  if date == nil then
    BBDC_Unavailable("no daily service")
    return false
  end
  local prep = BBT_Call(BattleBayDeluxe.DailyChallenge.PREPARE, date)
  if type(prep) ~= "table" or not prep.ok then
    BBDC_Unavailable(type(prep) == "table" and prep.why or "busy")
    return false
  end
  -- the run's matches play the match row's own rules (no rulebook a Torneo selected before)
  pcall(funcLuaCommand, BattleBayDeluxe.Tournament.RULE_SELECT, "")
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3848881948 --[[sy0000]])
  local ret = funcLuaMenuCommand(2227512519)
  BBT_Log("daily: match", (prep.k or 0) + 1, "requested", tostring(ret))
  if not ret then
    BBT_Call(BattleBayDeluxe.DailyChallenge.UNLOAD)
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2086672038 --[[sy0003]])
    return false
  end
  pcall(BattleBayDeluxe.TournamentHost.before_match)
  funcLuaMenuCommand(1558704558 --[[CMND_SET_MENU_ACTIVE?]], BattleBayDeluxe.TournamentHost.menu, false)
  if type(BrightFadeAllMenu) == "function" then
    BrightFadeAllMenu(3578114327 --[[fade_menu_encount_campaign]], true)
  end
  funcLuaCommand(769636339, 0.5)
  if BattleBayDeluxe.TournamentHost.menu ~= 811496143 then
    funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.TournamentHost.menu, true)
  end
  funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, 811496143 --[[soccer_top_menu]])
  return true
end

-- the retail Campaña window of WaitExecOtherMenu with «Nueva partida»'s text and, with_daily, the «Reto diario» row:
-- its open and its result are read through swaps that last until each was seen. true when the daily row was picked:
-- the retail code then only gave the menu back and left the window open.
function BBDC_RetailWindow(wait, a1, a2, with_daily)
  local dc = BattleBayDeluxe.DailyChallenge
  local picked = false
  local cmd, open = funcLuaCommand, MENU_DEF.OpenSubWindowDefault
  local swap, swap_open
  swap_open = function(n, ids, size, cursor, enabled, ...)
    if type(ids) ~= "table" or ids[1] ~= dc.ROW_CONTINUE or ids[2] ~= dc.ROW_NEW then
      return open(n, ids, size, cursor, enabled, ...)
    end
    MENU_DEF.OpenSubWindowDefault = open
    if with_daily then
      return open(3, { ids[1], BBDC_Id("new"), BBDC_Id("daily") }, BBT_CHOOSE_SIZE[3], cursor, { 1, 1, 1 }, ...)
    end
    return open(n, { ids[1], BBDC_Id("new") }, size, cursor, enabled, ...)
  end
  swap = function(c, ...)
    if c ~= @crc:CMND_GET_SUB_WINDOW_RESULT@ then
      return cmd(c, ...)
    end
    local r = cmd(c, ...)
    if r >= 0 then
      picked = with_daily and r == 2
      funcLuaCommand = cmd
    end
    return r
  end
  MENU_DEF.OpenSubWindowDefault = swap_open
  funcLuaCommand = swap
  local ok, err = pcall(wait, a1, a2)
  if MENU_DEF.OpenSubWindowDefault == swap_open then
    MENU_DEF.OpenSubWindowDefault = open
  end
  if funcLuaCommand == swap then
    funcLuaCommand = cmd
  end
  if not ok then
    error(err, 0)
  end
  return picked
end

-- the window fully gone, then the run's next match
function BBDC_PlayFromWindow()
  BBDC_WindowGone()
  local ok, err = pcall(BBDC_Play)
  if not ok then
    BBT_Log("daily: error", tostring(err))
  end
end

-- a sync answer (the result itself is recorded by CMND_BBD_DAILY_SYNC; the game's result screen showed the score)
function BBDC_Synced(r)
  BattleBayDeluxe.DailyChallengeState.sync = false
  if type(r) == "table" and r.event ~= nil and r.event ~= "none" then
    BBT_Log("daily: back from a run match:", tostring(r.event))
  end
end

-- the sync again while the scripts were busy at OnInit
function BBDC_Step()
  if BattleBayDeluxe.TournamentHost.name ~= "bb_stadium_top_menu" or not BattleBayDeluxe.DailyChallengeState.sync then
    return
  end
  local r = BBT_Call(BattleBayDeluxe.DailyChallenge.SYNC)
  if r ~= nil then
    BBDC_Synced(r)
  end
end

-- ------------------------------------------------------------------------------------------------ wraps

do
  local init = OnInit
  function OnInit(...)
    BattleBayDeluxe.DailyChallengeState.sync = false
    BattleBayDeluxe.DailyChallengeState.no_daily = false
    local r = BBT_Call(BattleBayDeluxe.DailyChallenge.SYNC)
    if r ~= nil then
      BBDC_Synced(r)
    else
      BattleBayDeluxe.DailyChallengeState.sync = true   -- the scripts were busy: again from Step
    end
    return init(...)
  end

  local wait = WaitExecOtherMenu
  function WaitExecOtherMenu(a1, a2)
    local no_daily = BattleBayDeluxe.DailyChallengeState.no_daily
    BattleBayDeluxe.DailyChallengeState.no_daily = false
    -- a saved Campaña only: without one the retail code opens no window
    if a1 ~= BattleBayDeluxe.Tournament.ROW_CAMPAIGN or BattleBayDeluxe.TournamentHost.name ~= "bb_stadium_top_menu"
      or funcLuaMenuCommand(BattleBayDeluxe.Tournament.CAMPAIGN, 0) ~= true then
      return wait(a1, a2)
    end
    if BBDC_RetailWindow(wait, a1, a2, not no_daily) then
      BBT_ChooseClose()
      BBDC_PlayFromWindow()
    end
  end

  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    local state = BattleBayDeluxe.TournamentState
    BattleBayDeluxe.DailyChallengeState.no_daily = state.row_mode ~= nil
    if state.open or state.row_mode ~= nil or not BBDC_IsCampaignRow(a1, a2) then
      return decide(a1, a2, ...)
    end
    local t = BBT_InfoNoEnded()
    if t.active ~= true and funcLuaMenuCommand(BattleBayDeluxe.Tournament.CAMPAIGN, 0) == true then
      return decide(a1, a2, ...)
    end
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 3848881948 --[[sy0000]])
    BattleBayDeluxe.DailyChallengeState.menu_open = true
    local ok, pick = pcall(BBDC_CampaignMenu)
    BattleBayDeluxe.DailyChallengeState.menu_open = false
    if not ok then
      BBT_Log("daily: menu error", tostring(pick))
    elseif pick == "campaign" then
      BBDC_WindowGone()
      return decide(a1, a2, ...)
    elseif pick == "daily" then
      BBDC_PlayFromWindow()
    end
    return 1
  end

  -- the Back that closed the window, or a press before it is gone, never reaches this menu; the window's «new league»
  -- runs the League hub inside this decide, menu_open still set: the overlay's Back goes on to the overlay's own wrap
  local back = OnBack
  function OnBack(...)
    if BattleBayDeluxe.DailyChallengeState.menu_open and not BattleBayDeluxe.TournamentState.open then
      return 1
    end
    return back(...)
  end

  local step = Step
  function Step(...)
    local r = table.pack(step(...))
    local ok, err = pcall(BBDC_Step)
    if not ok and BattleBayDeluxe.DailyChallengeState.step_error ~= err then
      BattleBayDeluxe.DailyChallengeState.step_error = err
      BBT_Log("daily: step error", tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end
end
