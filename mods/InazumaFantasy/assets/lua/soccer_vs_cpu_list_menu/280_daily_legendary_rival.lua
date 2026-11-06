-- Inazuma Fantasy (prefix InazumaFantasy), free-match list (soccer_vs_cpu_list_menu): the «Rival del día» row.
-- The list never shows which team it is: the row is the slot team's own (name «Rival del día», a «?» crest), and the
-- squad panel shows every player slot and the coach slot as the game's plain empty card.
-- With BetterMenu, its Competition pitch shows no players for the row (BetterMenu.Competition.HidePlayers).
-- The day's team comes only with the match: when the row's match is reserved, the slot team stands in for it
-- (assets\lua\_all\280_daily_legendary_rival.lua, hooked here, in the class window and in soccer_top_menu).
-- * before OnInit: the slot team back (CMND_VRFW_TEAM_STAND_IN_RESTORE), so coming back to the list shows nothing of it;
-- * while the panel draws the slot team, no player is drawn: UpdateMemberCharaIconInfoByChrParamId gets param 0 and the
--   coach card is skipped; once UpdateFormation is done (it shows the card layer of every member slot again) each of
--   those slots and the coach slot is the plain empty card (card layer hidden, blank layer shown: the retail
--   UpdateMemberCharaBlankSlot / SetBlankMeshByCardType look);
-- * after OnInit: a beaten day's reward still due (CMND_INAZUMAFANTASY_DAILY_RIVAL_REWARD) goes into the bag
--   (VRFW_Recruit.Give) and is marked paid (CMND_INAZUMAFANTASY_DAILY_RIVAL_PAID), once per day;
-- * after OnChangeFocus of a row: on the row, the guide line shows the level, the time left to the next rival and
--   whether the day's rival is beaten in this save slot with its reward; the retail line back on another row.
-- Handlers of the framework's host of this script. No engine call at load time.
if VRFW_Host ~= nil and VRFW_Daily ~= nil and InazumaFantasyDailyRival ~= nil then
  InazumaFantasyDailyRival.PlayOnReserve()
  local DLR = {
    STEM = "soccer_vs_cpu_list_menu",
    ID = "InazumaFantasy.daily_legendary_rival",
    SLOT_TEAM = VRFW_Crc32("evt_ct_ft_daily_legendary_rival"),
    GAME = VRFW_Crc32("inazuma_fantasy_daily_legendary_rival"),
    RESTORE = VRFW_Crc32("CMND_VRFW_TEAM_STAND_IN_RESTORE"),
    REWARD = VRFW_Crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL_REWARD"),
    PAID = VRFW_Crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL_PAID"),
    BLANK = 3571911991,       -- team00_01_p1_chara_card_blank (the empty card; instance = slot)
    CARD = 1973487846,        -- team00_01_chara_card_for_soccer (the player card; instance = slot)
    COACH_CARD = 1658289671,  -- team00_01_chara_card_for_leader
    COACH_BLANK = 2290394976, -- team00_01_p1_chara_card_blank_for_leader
    LAYER_VISIBLE = 711242136,
    drawn = {},         -- member slots of the slot team the panel draw went through
    reward = 0,         -- Puntos de pasión the day's win pays
    ITEM = 1074924810,        -- mainmenu90_19_vs_cpu_list_item
    FOCUS_DATA = 1666448199,  -- (0) -> ok, the focused row's game
    GUIDE = 3078308064,       -- mainmenu90_05_content_guide_line01
    GUIDE_MESH = 378156699,   -- _text_guide01
    GUIDE_RETAIL = 3822200449, -- the retail guide text
    TEXT_GUIDE = VRFW_Crc32("InazumaFantasy.daily_rival_guide"),
    TEXT_CLASS = VRFW_Crc32("InazumaFantasy.daily_rival_class"),
    TEXT_TIME = VRFW_Crc32("InazumaFantasy.daily_rival_time"),
    TEXT_DONE = VRFW_Crc32("InazumaFantasy.daily_rival_done"),
    TEXT_OPEN = VRFW_Crc32("InazumaFantasy.daily_rival_open"),
    shown = false,
    hiding = false,     -- the panel is drawing the slot team
    done = false,
  }

  local function log(text)
    pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "InazumaFantasy daily rival " .. text)
  end

  local function text(id)
    local ok, s = pcall(funcLuaCommand, VRFW_Cmd.TEXT_GET, id)
    return ok and type(s) == "string" and s or ""
  end

  local function focused_game()
    local ok, okd, game = pcall(funcLuaMenuCommand, DLR.FOCUS_DATA, 0)
    if ok and okd and type(game) == "number" then return game end
    return nil
  end

  -- the day's rival beaten / its reward, for the guide line and the bag
  local function refresh()
    local r = InazumaFantasyDailyRival.Ask()
    if r ~= nil then
      DLR.done = r.done == true
      DLR.reward = tonumber(r.reward) or 0
    end
  end

  -- after the panel drew the slot team: every member slot and the coach slot the plain empty card
  local function blank_all()
    for slot in pairs(DLR.drawn) do
      pcall(funcLuaMenuCommand, DLR.LAYER_VISIBLE, DLR.CARD, slot, false)
      if type(UpdateMemberCharaBlankSlot) == "function" then pcall(UpdateMemberCharaBlankSlot, slot, true) end
      pcall(funcLuaMenuCommand, DLR.LAYER_VISIBLE, DLR.BLANK, slot, true)
    end
    pcall(funcLuaMenuCommand, DLR.LAYER_VISIBLE, DLR.COACH_CARD, 0, false)
    pcall(funcLuaMenuCommand, DLR.LAYER_VISIBLE, DLR.COACH_BLANK, 0, true)
    if type(SetBlankMeshByCardType) == "function" then pcall(SetBlankMeshByCardType, DLR.COACH_BLANK, 0, true, false) end
  end

  -- a beaten day's reward still due goes into the bag, once
  local function pay_reward()
    local day = VRFW_Daily.Period("day")
    if day == nil or not DLR.done then return end
    local ok, item, count = pcall(funcLuaCommand, DLR.REWARD, day)
    if not ok or type(item) ~= "number" or item == 0 or type(count) ~= "number" or count <= 0 then return end
    if not (VRFW_Recruit and VRFW_Recruit.Give(item, count)) then
      log(string.format("day %d: reward 0x%08X x%d not given (bag full?), kept for the next visit", day, item, count))
      return
    end
    pcall(funcLuaCommand, DLR.PAID, day)
    log(string.format("day %d: reward 0x%08X x%d given", day, item, count))
  end

  VRFW_Host.on(DLR.STEM, "OnInit", {
    id = DLR.ID, phase = "before",
    fn = function()
      pcall(funcLuaCommand, DLR.RESTORE, DLR.SLOT_TEAM)   -- the stand-in of the match just played goes back
      DLR.drawn = {}
      refresh()
      local bm = rawget(_G, "BetterMenu")
      if type(bm) == "table" and type(bm.Competition) == "table" and type(bm.Competition.HidePlayers) == "function" then
        bm.Competition.HidePlayers(DLR.ID, DLR.GAME)
      end
    end,
  })

  VRFW_Host.on(DLR.STEM, "OnInit", {
    id = DLR.ID .. ".reward", phase = "after",
    fn = function() pay_reward() end,
  })

  VRFW_Host.on(DLR.STEM, "UpdateFormation", {
    id = DLR.ID, phase = "around",
    fn = function(nxt, team, ...)
      if team ~= DLR.SLOT_TEAM then return nxt(team, ...) end
      DLR.hiding, DLR.drawn = true, {}
      local r = table.pack(pcall(nxt, team, ...))
      DLR.hiding = false
      if not r[1] then error(r[2], 0) end
      if next(DLR.drawn) ~= nil then blank_all() end
      return table.unpack(r, 2, r.n)
    end,
  })

  VRFW_Host.on(DLR.STEM, "UpdateMemberCharaIconInfoByChrParamId", {
    id = DLR.ID, phase = "around",
    fn = function(nxt, param, slot, ...)
      if not DLR.hiding then return nxt(param, slot, ...) end
      if type(slot) == "number" then DLR.drawn[slot] = true end
      return nxt(0, slot, ...)   -- param 0: the card instance is hidden (UpdateFormation shows it again: blank_all)
    end,
  })

  VRFW_Host.on(DLR.STEM, "UpdateLeaderCharaByCharaParamId", {
    id = DLR.ID, phase = "around",
    fn = function(nxt, ...)
      if DLR.hiding then return end   -- the coach card is not drawn (blank_all)
      return nxt(...)
    end,
  })

  VRFW_Host.on(DLR.STEM, "OnChangeFocus", {
    id = DLR.ID, phase = "after",
    fn = function(r, a1, ...)
      if a1 ~= DLR.ITEM then return end
      if focused_game() == DLR.GAME then
        local _, secs = VRFW_Daily.Period("day")
        secs = math.max(0, math.floor(tonumber(secs) or 0))
        local left = string.format(text(DLR.TEXT_TIME), math.floor(secs / 3600), math.floor((secs % 3600) / 60))
        local state = string.format(text(DLR.done and DLR.TEXT_DONE or DLR.TEXT_OPEN), DLR.reward)
        funcLuaMenuCommand(VRFW_Cmd.SET_MENU_TEXT_STRING, DLR.GUIDE, DLR.GUIDE_MESH,
          string.format(text(DLR.TEXT_GUIDE), text(DLR.TEXT_CLASS), left, state), 0)
        DLR.shown = true
      elseif DLR.shown then
        funcLuaMenuCommand(VRFW_Cmd.SET_MENU_TEXT_STRING, DLR.GUIDE, DLR.GUIDE_MESH, text(DLR.GUIDE_RETAIL), 0)
        DLR.shown = false
      end
    end,
  })
end
