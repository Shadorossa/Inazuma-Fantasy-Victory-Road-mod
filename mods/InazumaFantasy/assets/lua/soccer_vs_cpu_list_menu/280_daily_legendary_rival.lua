if VRFW.host ~= nil and VRFW.daily ~= nil and InazumaFantasy ~= nil and InazumaFantasy.DailyRivalMenu ~= nil then
  InazumaFantasy.DailyRivalMenu.play_on_reserve()
  local DLR = {
    STEM = "soccer_vs_cpu_list_menu",
    ID = "InazumaFantasy.daily_legendary_rival",
    SLOT_TEAM = VRFW.crc32("evt_ct_ft_daily_legendary_rival"),
    GAME = VRFW.crc32("inazuma_fantasy_daily_legendary_rival"),
    RESTORE = VRFW.crc32("CMND_VRFW_TEAM_STAND_IN_RESTORE"),
    REWARD = VRFW.crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL_REWARD"),
    PAID = VRFW.crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL_PAID"),
    BLANK = 3571911991,
    CARD = 1973487846,
    COACH_CARD = 1658289671,  -- team00_01_chara_card_for_leader
    COACH_BLANK = 2290394976, -- team00_01_p1_chara_card_blank_for_leader
    LAYER_VISIBLE = 711242136,
    drawn = {},         -- member slots of the slot team the panel draw went through
    reward = 0,
    level = 0,
    ITEM = 1074924810,        -- mainmenu90_19_vs_cpu_list_item
    FOCUS_DATA = 1666448199,  -- (0) -> ok, the focused row's game
    GUIDE = 3078308064,       -- mainmenu90_05_content_guide_line01
    GUIDE_MESH = 378156699,   -- _text_guide01
    GUIDE_RETAIL = 3822200449, -- the retail guide text
    TEXT_GUIDE = VRFW.crc32("InazumaFantasy.daily_rival_guide"),
    TEXT_DONE = VRFW.crc32("InazumaFantasy.daily_rival_done"),
    TEXT_OPEN = VRFW.crc32("InazumaFantasy.daily_rival_open"),
    shown = false,
    hiding = false,     -- the panel is drawing the slot team
    done = false,
  }

  local log = VRFW.logger.new("InazumaFantasy daily rival")

  local function text(id)
    local s = VRFW.host.command(VRFW.commands.TEXT_GET, id)
    return type(s) == "string" and s or ""
  end

  local function focused_game()
    local okd, game = VRFW.host.menu_command(DLR.FOCUS_DATA, 0)
    if okd and type(game) == "number" then return game end
    return nil
  end

  -- the day's rival beaten / its reward, for the guide line and the bag
  local function refresh()
    local r = InazumaFantasy.DailyRivalMenu.ask()
    if r ~= nil then
      DLR.done = r.done == true
      DLR.reward = tonumber(r.reward) or 0
      DLR.level = tonumber(r.level) or 0
    end
  end

  local function blank_all()
    for slot in pairs(DLR.drawn) do
      VRFW.host.menu_command(DLR.LAYER_VISIBLE, DLR.CARD, slot, false)
      if type(UpdateMemberCharaBlankSlot) == "function" then pcall(UpdateMemberCharaBlankSlot, slot, true) end
      VRFW.host.menu_command(DLR.LAYER_VISIBLE, DLR.BLANK, slot, true)
    end
    VRFW.host.menu_command(DLR.LAYER_VISIBLE, DLR.COACH_CARD, 0, false)
    VRFW.host.menu_command(DLR.LAYER_VISIBLE, DLR.COACH_BLANK, 0, true)
    if type(SetBlankMeshByCardType) == "function" then pcall(SetBlankMeshByCardType, DLR.COACH_BLANK, 0, true, false) end
  end

  -- a beaten day's reward still due goes into the bag, once
  local function pay_reward()
    local day = VRFW.daily.period("day")
    if day == nil or not DLR.done then return end
    local item, count = VRFW.host.command(DLR.REWARD, day)
    if type(item) ~= "number" or item == 0 or type(count) ~= "number" or count <= 0 then return end
    if not (VRFW.recruit and VRFW.recruit.give(item, count)) then
      log(string.format("day %d: reward 0x%08X x%d not given (bag full?), kept for the next visit", day, item, count))
      return
    end
    VRFW.host.command(DLR.PAID, day)
    log(string.format("day %d: reward 0x%08X x%d given", day, item, count))
  end

  VRFW.host.on(DLR.STEM, "OnInit", {
    id = DLR.ID, phase = "before",
    fn = function()
      VRFW.host.command(DLR.RESTORE, DLR.SLOT_TEAM)   -- the stand-in of the match just played goes back
      DLR.drawn = {}
      refresh()
      local bm = rawget(_G, "BetterMenu")
      if type(bm) == "table" and type(bm.competition) == "table" and type(bm.competition.hide_players) == "function" then
        bm.competition.hide_players(DLR.ID, DLR.GAME)
      end
    end,
  })

  VRFW.host.on(DLR.STEM, "OnInit", {
    id = DLR.ID .. ".reward", phase = "after",
    fn = function() pay_reward() end,
  })

  VRFW.host.on(DLR.STEM, "UpdateFormation", {
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

  VRFW.host.on(DLR.STEM, "UpdateMemberCharaIconInfoByChrParamId", {
    id = DLR.ID, phase = "around",
    fn = function(nxt, param, slot, ...)
      if not DLR.hiding then return nxt(param, slot, ...) end
      if type(slot) == "number" then DLR.drawn[slot] = true end
      return nxt(0, slot, ...)
    end,
  })

  VRFW.host.on(DLR.STEM, "UpdateLeaderCharaByCharaParamId", {
    id = DLR.ID, phase = "around",
    fn = function(nxt, ...)
      if DLR.hiding then return end   -- the coach card is not drawn (blank_all)
      return nxt(...)
    end,
  })

  VRFW.host.on(DLR.STEM, "OnChangeFocus", {
    id = DLR.ID, phase = "after",
    fn = function(r, a1, ...)
      if a1 ~= DLR.ITEM then return end
      if focused_game() == DLR.GAME then
        local _, secs = VRFW.daily.period("day")
        secs = math.max(0, math.floor(tonumber(secs) or 0))
        local state = string.format(text(DLR.done and DLR.TEXT_DONE or DLR.TEXT_OPEN), DLR.reward)
        funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, DLR.GUIDE, DLR.GUIDE_MESH,
          string.format(text(DLR.TEXT_GUIDE), math.floor(secs / 3600), math.floor((secs % 3600) / 60), state), 0)
        DLR.shown = true
      elseif DLR.shown then
        funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, DLR.GUIDE, DLR.GUIDE_MESH, text(DLR.GUIDE_RETAIL), 0)
        DLR.shown = false
      end
    end,
  })
end
