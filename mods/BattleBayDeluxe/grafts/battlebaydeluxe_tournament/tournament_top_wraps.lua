-- Top menu part
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}


do
  Wrap("BattleBayDeluxe.tournament_top_wraps", "OnInit", { around = function(init, ...)
    BattleBayDeluxe.tournament_state.setup_frames = 0
    local ok, done = pcall(BattleBayDeluxe.tournament_sync)
    if not ok then
      BattleBayDeluxe.tournament_log("sync error", tostring(done))
    elseif not done then
      BattleBayDeluxe.tournament_state.sync, BattleBayDeluxe.tournament_state.sync_frames = true, 0   -- scripts busy: retried from Step
    end
    -- Top bar step battlebaydeluxe_tournament
    if BattleBayDeluxe.tournament_host.step ~= nil and type(VRFW.top_bar.step) == "function" then
      local oks, go = pcall(VRFW.top_bar.step, BattleBayDeluxe.tournament_host.step)
      if oks and go then
        BattleBayDeluxe.tournament_state.step, BattleBayDeluxe.tournament_state.frames, BattleBayDeluxe.tournament_state.want = true, 0, false
        BattleBayDeluxe.tournament_log("top bar step: the campaign row in tournament mode")
      end
    end
    return init(...)
  end })

  Wrap("BattleBayDeluxe.tournament_top_wraps", "OnDecideFocus", { around = function(decide, a1, a2, ...)
    if BattleBayDeluxe.tournament_state.open then
      -- A decide on another layer (the menu focus came back over the anchor) is the overlay's Enter too.
      if a1 ~= BattleBayDeluxe.tournament.ANCHOR then
        if BattleBayDeluxe.tournament_state.stray_decide ~= a1 then
          BattleBayDeluxe.tournament_state.stray_decide = a1
          BattleBayDeluxe.tournament_log("overlay keys: decide on layer " .. tostring(a1) .. ": taken as the overlay's Enter, the anchor focused")
        end
        BattleBayDeluxe.tournament_focus_anchor()
      end
      BattleBayDeluxe.tournament_on_enter()
      return 1
    end
    if (a1 == BattleBayDeluxe.tournament.LIST_MID or a1 == BattleBayDeluxe.tournament.LIST_SMALL) and BattleBayDeluxe.tournament_host.name == "bb_stadium_top_menu" then
      local okl, info = pcall(GetLitItemInfo, a1, a2)
      if okl and info ~= nil and info.menuObjectName == BattleBayDeluxe.tournament.ROW_CAMPAIGN then
        local mode = BattleBayDeluxe.tournament_state.row_mode
        BattleBayDeluxe.tournament_state.row_mode = nil
        local t = mode == "tournament"
        if mode == nil then
          local ti = BattleBayDeluxe.tournament_info()
          t = ti.active == true or ti.ended == true
        end
        if t then
          funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
          local ok, err = pcall(BattleBayDeluxe.tournament_entry_tournament)
          if not ok then
            BattleBayDeluxe.tournament_log("entry error", tostring(err))
          end
          return 1
        end
        VRFW.param.clear(BattleBayDeluxe.tournament_mode_go_tournament_param)
      end
    end
    return decide(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.tournament_top_wraps", "OnBack", { around = function(back, a1, ...)
    -- Back on the league hub dashboard = exit (its coroutine closes the overlay).
    if BattleBayDeluxe.tournament_state.open and (BattleBayDeluxe.tournament_hub_key("back") or BattleBayDeluxe.tournament_hub_calendar_key("back")) then
      return 1
    end
    if BattleBayDeluxe.tournament_state.open and BattleBayDeluxe.tournament_state.section then
      BattleBayDeluxe.tournament_state.section = false
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@)
      return 1
    end
    if BattleBayDeluxe.tournament_state.open then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@)
      -- Leaving an ended run's last screens forgets it.
      BattleBayDeluxe.tournament_info_no_ended()
      BattleBayDeluxe.tournament_close()
      return 1
    end
    return back(a1, ...)
  end })

  -- The badge's retail setup, then the running run's next match over it.
  Wrap("BattleBayDeluxe.tournament_top_wraps", "OnSetupLayer", { around = function(setup_layer, a1, a2, ...)
    local r = table.pack(setup_layer(a1, a2, ...))
    if a1 == BattleBayDeluxe.tournament.BADGE then
      local ok, err = pcall(BattleBayDeluxe.tournament_next_badge, BattleBayDeluxe.tournament_info(), a2)
      if not ok then
        BattleBayDeluxe.tournament_log("badge error", tostring(err))
      end
    end
    return table.unpack(r, 1, r.n)
  end })

  Wrap("BattleBayDeluxe.tournament_top_wraps", "OnFunction", { around = function(fn, a1, a2, ...)
    if BattleBayDeluxe.tournament_state.open then
      -- League hub side menu keys (Up / Down / L1 / R1) and the left click.
      if BattleBayDeluxe.tournament_hub_key("function", a1) or BattleBayDeluxe.tournament_hub_calendar_key("function", a1) then
        return 1
      end
      -- The arrows have their own ids (dashboard focus)
      if a1 == BattleBayDeluxe.tournament.HUB.FN_LEFT then
        a1 = BattleBayDeluxe.tournament.FN_PREV
      elseif a1 == BattleBayDeluxe.tournament.HUB.FN_RIGHT then
        a1 = BattleBayDeluxe.tournament.FN_NEXT
      end
      if a1 == BattleBayDeluxe.tournament.FN_PREV then
        BattleBayDeluxe.tournament_turn(-1)
      elseif a1 == BattleBayDeluxe.tournament.FN_NEXT then
        BattleBayDeluxe.tournament_turn(1)
      end
      return 1
    end
    return fn(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.tournament_top_wraps", "Step", { around = function(step, ...)
    local r = { step(...) }
    local S = BattleBayDeluxe.tournament_state
    if S.setup_frames ~= nil then
      S.setup_frames = S.setup_frames + 1
      if S.setup_frames >= BattleBayDeluxe.tournament_setup_frames then
        S.setup_frames = nil
        local okc, errc = pcall(BattleBayDeluxe.tournament_setup_check)
        if not okc then
          BattleBayDeluxe.tournament_logger().once("setup_check_error", "setup check error", tostring(errc))
        end
      end
    end
    if S.open and S.champ then
      pcall(BattleBayDeluxe.tournament_champion_step)
    end
    if S.open and S.focus_watch ~= nil then
      local okf, errf = pcall(BattleBayDeluxe.tournament_focus_watch)
      if not okf then
        S.focus_watch = nil
        BattleBayDeluxe.tournament_logger().once("overlay_keys_error", "overlay keys error", tostring(errf))
      end
    end
    -- The group-stage child menu, opened after an earlier one closed.
    local okg, errg = pcall(BattleBayDeluxe.tournament_groups_step)
    if not okg then
      BattleBayDeluxe.tournament_logger().once("groups_menu_error", "groups menu error", tostring(errg))
    end
    -- The bracket screen (tree page), opened after an earlier one closed.
    local okt, errt = pcall(VRFW.bracket.step)
    if not okt then
      BattleBayDeluxe.tournament_logger().once("tree_menu_error", "bracket menu error", tostring(errt))
    end
    -- A bracket layer set up after the bracket opened (S.redraw)
    if S.redraw then
      S.redraw = false
      if S.open and not S.champ then
        local ok, err = pcall(BattleBayDeluxe.tournament_draw, S.page)
        BattleBayDeluxe.tournament_log("late layer setup: page drawn again", S.page, ok and "" or tostring(err))
      end
    end
    if S.sync then
      S.sync_frames = S.sync_frames + 1
      local ok, done = pcall(BattleBayDeluxe.tournament_sync)
      if (ok and done) or S.sync_frames > 600 then
        S.sync = false
      end
    end
    local okp, errp = pcall(BattleBayDeluxe.tournament_hub_pointer_step)
    if not okp then
      S.hub_ptr, S.hub_zones = nil, nil   -- off until the hub is drawn again
      BattleBayDeluxe.tournament_logger().once("hub_pointer_error", "hub pointer error", tostring(errp))
    end
    if S.co ~= nil then
      local ok, err = coroutine.resume(S.co)
      if not ok then
        BattleBayDeluxe.tournament_log("error", tostring(err))
      end
      if not ok or coroutine.status(S.co) == "dead" then
        S.co = nil
      end
    elseif S.step and not S.open then
      S.frames = S.frames + 1
      if S.frames > 600 then
        S.step = false
      elseif S.frames > 20 and funcLuaMenuCommand(@crc:CMND_IS_CTRL_FOCUS_ACTIVE@, BattleBayDeluxe.tournament.LIST_MID) == true
        and funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) ~= true then
        S.step = false
        local ok, err = pcall(BattleBayDeluxe.tournament_decide_row)
        if not ok then
          BattleBayDeluxe.tournament_log("top bar step error", tostring(err))
        end
      end
    elseif S.want and not S.open then
      S.frames = S.frames + 1
      -- On a host with `cover` the screen stays black until the bracket is up, then fades in once.
      local cover = BattleBayDeluxe.tournament_host.cover == true
      if cover then
        funcLuaCommand(609722083 --[[fade black]], 1, 0)
      end
      if S.frames > 600 then
        S.want = false
        if cover then
          funcLuaCommand(609722083, 0, 0.3)
        end
      elseif S.frames > (cover and 2 or 20) and BattleBayDeluxe.tournament_host.ready()
        and (cover or funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) ~= true) then
        S.want = false
        local ok, err = pcall(BattleBayDeluxe.tournament_open, -1)
        if not ok then
          BattleBayDeluxe.tournament_log("overlay error", tostring(err))
        end
        if cover then
          funcLuaCommand(609722083, 0, 0.3)
          BattleBayDeluxe.tournament_log("results shown under the cover after", S.frames, "Steps")
        end
      end
    end
    return table.unpack(r)
  end })
end
