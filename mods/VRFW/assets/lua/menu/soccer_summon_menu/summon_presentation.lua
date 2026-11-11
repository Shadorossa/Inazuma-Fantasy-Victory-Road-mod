-- The summon menu's side of VRFW.summon_presentation: inert unless the opening carries a request.
if VRFW.host ~= nil then
  local SUMMON_MENU = 369188769           -- soccer_summon_menu
  local PERFORMANCE_BACKGROUND = 1345986950   -- team15_10_summon_performance_bg
  local NEXT_BUTTON = 2477003745          -- cmn03_01_cmd_next
  local ADD_TEMP_MENU_CHARA = 1423295663  -- (card, 1, rarity) -> a temporary menu character
  local MENU_ACTIVE = 1558704558          -- (menu, on)
  local FADE = 609722083                  -- (1 = to black, seconds)
  local FADE_SECONDS = 0.3
  local FADE_WAIT_STEPS = 120
  local NO_ACCEPT_REPORT_STEPS = 1800     -- one line in the log when nothing reached Accept for this long
  local SPIRIT_LIST = 114255962           -- team15_01_summon_list
  local LIST_TAB_ITEM = 4044286600        -- cmn06_20_list_tab_item
  local LIST_CURSOR = 2296367164          -- cmn05_01_cursor
  local SET_LAYER_VISIBLE = 711242136     -- (layer, instance, on)
  local SET_LIST_ACTIVE = 2243775400      -- (list, instance, on)
  local SET_CTRL_FOCUS = 3518307824       -- (layer, on)
  local STATE_PERFORMANCE = 2             -- UpdateState's state during retail SummonChara

  local log = VRFW.logger.new("VRFW.summon_presentation")
  local request, performance, listed, steps, accepts = nil, nil, false, 0, 0

  local function reset()
    request, performance, listed, steps, accepts = nil, nil, false, 0, 0
  end

  -- The spirit list made inert and hidden as retail SummonChara does before ExecSummonPerformance.
  local function close_spirit_list()
    funcLuaMenuCommand(SET_LAYER_VISIBLE, LIST_CURSOR, 0, false)
    funcLuaMenuCommand(SET_LIST_ACTIVE, SPIRIT_LIST, 0, false)
    funcLuaMenuCommand(SET_CTRL_FOCUS, SPIRIT_LIST, false)
    funcLuaMenuCommand(SET_CTRL_FOCUS, LIST_TAB_ITEM, false)
    ChangeSelectChara(0)
    ResetFocusItemInfo()
    SetVisibleSummonDefaultLayer(false)
    SetIsSelectSpiritMixChara(false)
    SetAlwaysCardSizeSmallMode(true)
    UpdateState(STATE_PERFORMANCE)
    coroutine.yield()
  end

  local function perform()
    close_spirit_list()
    if request.takes_input then
      funcLuaMenuCommand(MENU_ACTIVE, SUMMON_MENU, true)
    end
    log("performance start", request.count)
    ExecSummonPerformance(request.count)
    log("performance done", request.count, "accepts", accepts)
    funcLuaCommand(FADE, 1, FADE_SECONDS)
    local waited = 0
    while funcLuaCommand(VRFW.commands.BRIGHT_IS_FADE) and waited < FADE_WAIT_STEPS do
      waited = waited + 1
      coroutine.yield()
    end
    reset()
    funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, SUMMON_MENU)
  end

  VRFW.host.wrap("OnInit", function(retail)
    return function(...)
      local results = table.pack(retail(...))
      reset()
      request = VRFW.summon_presentation.take_request()
      if request ~= nil then
        log("request", request.count, "player(s), takes input", tostring(request.takes_input))
      end
      return table.unpack(results, 1, results.n)
    end
  end)

  VRFW.host.wrap("CreateTempSummonCharaHdl", function(retail)
    return function(index, ...)
      if request == nil then
        return retail(index, ...)
      end
      local slot = math.floor(tonumber(index) or 0)
      local card = request.cards[slot]
      if card == nil or card == 0 then
        return 0
      end
      return funcLuaMenuCommand(ADD_TEMP_MENU_CHARA, card, 1, request.rarities[slot])
    end
  end)

  -- The spirit list reports its item count once built: the performance starts after it, so the list is closed for good.
  VRFW.host.wrap("UpdateItemNum", function(retail)
    return function(...)
      local results = table.pack(retail(...))
      if request ~= nil and not listed then
        listed = true
        log("spirit list built")
      end
      return table.unpack(results, 1, results.n)
    end
  end)

  VRFW.host.wrap("OnDecideFocus", function(retail)
    return function(layer, ...)
      if request ~= nil and (layer == PERFORMANCE_BACKGROUND or layer == NEXT_BUTTON) then
        accepts = accepts + 1
        log("accept arrived", accepts)
      end
      return retail(layer, ...)
    end
  end)

  VRFW.host.wrap("Step", function(retail)
    return function(...)
      local results = table.pack(retail(...))
      if request ~= nil then
        if performance == nil and listed then
          performance = coroutine.create(perform)
        end
        if performance ~= nil and coroutine.status(performance) ~= "dead" then
          steps = steps + 1
          if steps == NO_ACCEPT_REPORT_STEPS and accepts == 0 then
            log("no accept after", steps, "steps")
          end
          local ok, why = coroutine.resume(performance)
          if not ok then
            log("performance error", tostring(why))
            reset()
            funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, SUMMON_MENU)
          end
        end
      end
      return table.unpack(results, 1, results.n)
    end
  end)

  VRFW.host.wrap("FinalizeMenu", function(retail)
    return function(...)
      reset()
      return retail(...)
    end
  end)
end
