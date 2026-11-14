-- The Draft screen's wrappers of the retail grid functions (setup, open, decide, back, formation and tactics panels).
--@lib vrfw_block_helpers.lua#Wrap
do
  Wrap("BattleBayDeluxe.draft_screen_wraps", "Step", { around = function(step, ...)
    local r = table.pack(step(...))
    BattleBayDeluxe.draft_step()
    return table.unpack(r, 1, r.n)
  end })

  -- Sets up the Draft cards.
  Wrap("BattleBayDeluxe.draft_screen_wraps", "OnSetupLayer", { around = function(setup, a1, a2, ...)
    local r = table.pack(setup(a1, a2, ...))
    if a1 == BattleBayDeluxe.draft.SLOT or a1 == BattleBayDeluxe.draft.CARD then
      local ok, err = pcall(function()
        BattleBayDeluxe.draft_name(a1, a2)
        BattleBayDeluxe.draft_cursor_labels_off(a1, a2)
        funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, a1, a2, BattleBayDeluxe.draft.PRIO, true)
      end)
      if not ok then
        BattleBayDeluxe.draft_log("card setup error", tostring(err))
      end
    elseif a1 == BattleBayDeluxe.draft.ANCHOR then
      BattleBayDeluxe.draft_anchor_park(a2)
    elseif a1 == BattleBayDeluxe.draft_pack.QUAD or a1 == BattleBayDeluxe.draft_pack.TXT or a1 == BattleBayDeluxe.draft_pack.CREST then
      pcall(BattleBayDeluxe.draft_pack_priority, a1, a2)
    elseif a1 == BattleBayDeluxe.draft_formation.QUAD or a1 == BattleBayDeluxe.draft_formation.TXT then
      pcall(BattleBayDeluxe.draft_formation_priority, a1, a2)
    end
    return table.unpack(r, 1, r.n)
  end })

  Wrap("BattleBayDeluxe.draft_screen_wraps", "OnOpenLayer", { around = function(open, a1, a2, ...)
    local r = table.pack(open(a1, a2, ...))
    if a1 == BattleBayDeluxe.draft.SLOT or a1 == BattleBayDeluxe.draft.CARD then
      local ok, err = pcall(function()
        local B = BattleBayDeluxe.draft
        BattleBayDeluxe.draft_name(a1, a2) -- only if the setup did not (never twice)
        B.ready[a1 .. ":" .. a2] = true
        if a1 == B.SLOT then
          if B.slots[a2 + 1] ~= nil and B.mode ~= nil then
            BattleBayDeluxe.draft_draw_slot(a2)
          else
            funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, a1, a2, false)
          end
        else
          BattleBayDeluxe.draft_draw_candidate(a2)
        end
        if B.shown == nil or (B.shown[1] == a1 and B.shown[2] == a2) then
          BattleBayDeluxe.draft_cursor()
        end
      end)
      if not ok then
        BattleBayDeluxe.draft_log("card open error", tostring(err))
      end
    elseif a1 == BattleBayDeluxe.draft.ANCHOR then
      BattleBayDeluxe.draft_anchor_park(a2)
    elseif (a1 == BattleBayDeluxe.draft_pack.QUAD or a1 == BattleBayDeluxe.draft_pack.TXT or a1 == BattleBayDeluxe.draft_pack.CREST)
        and BattleBayDeluxe.draft.pk == nil then
      pcall(BattleBayDeluxe.draft_pack_priority, a1, a2) -- hidden until a pack opens
    elseif a1 == BattleBayDeluxe.draft_formation.QUAD or a1 == BattleBayDeluxe.draft_formation.TXT then
      pcall(BattleBayDeluxe.draft_formation_priority, a1, a2) -- drawn by the next Step (BattleBayDeluxe.draft_formation_render)
    end
    return table.unpack(r, 1, r.n)
  end })

  Wrap("BattleBayDeluxe.draft_screen_wraps", "OnDecideFocus", { around = function(decide, a1, a2, ...)
    if a1 == BattleBayDeluxe.draft.ANCHOR then
      -- A pointer click is handled once by BattleBayDeluxe.draft_mouse.
      local B = BattleBayDeluxe.draft
      if B.mode ~= nil and B.mouse and B.ptr ~= nil and (B.mouseDecided or (B.ptr.owns() and B.ptr.at() ~= nil)) then
        return
      end
      if BattleBayDeluxe.draft.mode ~= nil then
        local ok, err = pcall(BattleBayDeluxe.draft_decide)
        if not ok then
          BattleBayDeluxe.draft_log("decide error", tostring(err))
        end
      end
      return
    end
    if BattleBayDeluxe.draft.filterCo ~= nil then
      return
    end
    if a1 == BattleBayDeluxe.draft.GRID and not BattleBayDeluxe.draft.bypass and BattleBayDeluxe.draft.mode == nil then
      local ok, mine = pcall(BattleBayDeluxe.draft_is_slot, a2)
      if ok and mine then
        local okr, err = pcall(BattleBayDeluxe.draft_start, a2)
        if not okr then
          BattleBayDeluxe.draft_log("start error", tostring(err))
          pcall(BattleBayDeluxe.draft_exit, true)
        end
        return
      end
    end
    return decide(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.draft_screen_wraps", "OnFunction", { around = function(fn, a1, a2, ...)
    local B = BattleBayDeluxe.draft
    if B.mode ~= nil and (a1 == B.FN_UP or a1 == B.FN_DOWN or a1 == B.FN_LEFT or a1 == B.FN_RIGHT) then
      local dx = (a1 == B.FN_RIGHT and 1) or (a1 == B.FN_LEFT and -1) or 0
      local dy = (a1 == B.FN_UP and 1) or (a1 == B.FN_DOWN and -1) or 0
      local ok, err = pcall(BattleBayDeluxe.draft_move, dx, dy)
      if not ok then
        BattleBayDeluxe.draft_log("move error", tostring(err))
      end
      return 1
    end
    if B.mode ~= nil and a1 == B.FN_Y then
      -- The formation cannot be changed once chosen.
      return 1
    end
    return fn(a1, a2, ...)
  end })

  Wrap("BattleBayDeluxe.draft_screen_wraps", "OnBack", { around = function(back, a1, a2, ...)
    if a1 == BattleBayDeluxe.draft.ANCHOR then
      if BattleBayDeluxe.draft.mode ~= nil then
        local ok, err = pcall(BattleBayDeluxe.draft_back)
        if not ok then
          BattleBayDeluxe.draft_log("back error", tostring(err))
        end
      end
      return 1
    end
    if a1 == BattleBayDeluxe.draft.GRID and BattleBayDeluxe.draft.mode == nil then
      -- Abandons the draft when leaving the grid.
      VRFW.host.command(BattleBayDeluxe.draft.ABANDON)
    end
    return back(a1, a2, ...)
  end })

  -- Handles going back from the difficulty window after a draft.
  -- The free-match script has no OnCloseEndLayer: Wrap leaves a missing global alone.
  Wrap("BattleBayDeluxe.draft_screen_wraps", "OnCloseEndLayer", { around = function(closeEnd, a1, a2, ...)
    local r = table.pack(closeEnd(a1, a2, ...))
    if a1 == BattleBayDeluxe.draft.DIFFWIN and BattleBayDeluxe.draft.used and BattleBayDeluxe.draft.mode == nil and BattleBayDeluxe.draft.refresh == nil then
      BattleBayDeluxe.draft.refresh = BattleBayDeluxe.draft.REFRESH_FRAMES
    end
    return table.unpack(r, 1, r.n)
  end })

  Wrap("BattleBayDeluxe.draft_screen_wraps", "SetupEmblemIcon", { around = function(setupIcon, a1, a2, a3, a4, ...)
    if type(a1) == "number" then
      BattleBayDeluxe.draft.slotArgs[a1] = {a2 or 0, a3, a4}
    end
    return setupIcon(a1, a2, a3, a4, ...)
  end })

  -- Draws the panel.
  Wrap("BattleBayDeluxe.draft_screen_wraps", "UpdateFormation", { around = function(formation, a1, a2, ...)
    local B = BattleBayDeluxe.draft
    local free = BattleBayDeluxe.draft_free()
    if B.mode ~= nil and (a2 ~= false or free) then
      local ok, err = pcall(BattleBayDeluxe.draft_panel_hold)
      if not ok then
        BattleBayDeluxe.draft_log("panel hold error", tostring(err))
      end
      return
    end
    if free and not B.ours then
      -- the native refresh draws the side being chosen with the tile under the cursor
      B.drawn[a2 ~= false] = a1
      if a1 == B.TEAM then
        B.side = a2 ~= false
      end
    end
    local r = table.pack(formation(a1, a2, ...))
    if a1 == B.TEAM and (a2 ~= false or free) then
      pcall(function()
        local ok, phase = BattleBayDeluxe.draft_info()
        if not (ok and phase >= 2) then
          BattleBayDeluxe.draft_layer_visible((a2 ~= false) and B.LEFT or B.RIGHT, 11, false)
        end
      end)
    end
    return table.unpack(r, 1, r.n)
  end })

  -- the panel's tactics stay hidden while the Draft screen is open
  Wrap("BattleBayDeluxe.draft_screen_wraps", "UpdateTacticsLayer", { around = function(tactics, a1, a2, ...)
    if BattleBayDeluxe.draft.mode ~= nil and (a2 ~= false or BattleBayDeluxe.draft_free()) then
      return
    end
    return tactics(a1, a2, ...)
  end })
end
