-- Player page block (plate_pages.lua): the stats panel's rows the focused item raises / lowers
    -- ---- the stats panel's rows the focused item raises / lowers: outline + number colour (CMND_GET_EQUIP_PARAM) ----
    -- an item's stat si for the shown player: its change and its affinity bonus (Better Equipment's page answer)
    G.icAffinityOf = {}
    -- a stat change as a signed number: a negative i32 read as u32 back below 0; anything outside the stats' range
    -- (-9999..9999) is no change
    function G.SignedStat(v)
      v = tonumber(v) or 0
      if v > 2147483647 then
        v = v - 4294967296
      end
      if v < -9999 or v > 9999 then
        return 0
      end
      return v
    end
    local function ItemStat(it, si, effect)
      if it == nil or it == 0 then
        return 0
      end
      local ok, has, v = pcall(funcLuaCommand, @crc:CMND_GET_EQUIP_PARAM@, it, si)
      v = ok and has ~= false and G.SignedStat(v) or 0
      local eff = effect
      if eff == nil then
        local key = tostring(it) .. "/" .. tostring(G.hdl)
        eff = G.icAffinityOf[key]
        if eff == nil then
          eff = Command(IC.page_command, it, type(G.hdl) == "number" and G.hdl or 0) or false
          G.icAffinityOf[key] = eff
        end
      end
      local A = type(eff) == "table" and eff.affinity or nil
      local extra = (type(A) == "table" and type(A.bonus) == "table") and G.SignedStat(A.bonus[si + 1]) or 0
      return v + extra
    end

    -- the stats panel's rows: the change of wearing `item` instead of `base` (nil = the item's own change: the
    -- equipment screen, and the picker on the worn item), affinity included. Only the state is kept here; the frame step
    -- (G.Bars) draws the number, its colour, the outline, the bar's segment and the label from G.RowState
    function G.ItemCardRows(item, base)
      local delta = nil
      if base ~= nil and base == item then
        base = nil
      end
      if item ~= nil and item ~= 0 and G.ItemCardOn() and IC.rows ~= false then
        for si = 0, 7 do
          local d = ItemStat(item, si, G.icEffect) - ItemStat(base, si)
          if d ~= 0 then
            for g = 1, 8 do
              if G.STAT[g] == si then
                delta = delta or {}
                delta[g] = d
              end
            end
          end
        end
      end
      -- a stat shown at the game's minimum 1 can be below it (a drained stat): its real sum, from the training mod's
      -- answer, is what the change adds to
      local raw = nil
      if delta ~= nil and G.vals ~= nil and type(G.hdl) == "number" and CharacterReforged ~= nil
          and CharacterReforged.Page ~= nil and CharacterReforged.Page.StatSum ~= nil then
        for g in pairs(delta) do
          if (G.vals[g] or 0) <= 1 then
            raw = raw or {}
            raw[g] = CharacterReforged.Page.StatSum(G.hdl, G.STAT[g])
          end
        end
      end
      G.rowDelta, G.rowOwn, G.rowRaw = delta, base == nil, raw
      G.Try("ItemCardLuckRow")
    end

    -- row g's state from the player's stat now (v): the value without the focused item's change, the value with it and
    -- the change between them (new = old + change on every row). The item worn (the equipment screen, the picker on the
    -- worn item): old = the value without it, new = v. The picker on another item: old = v, new = the value with it in
    -- place of the worn one. Both kept at the game's minimum 1 (Classic Training's StatusStatMinimum). nil = no change.
    function G.RowState(g, v)
      local d = G.rowDelta ~= nil and G.rowDelta[g] or nil
      if d == nil or d == 0 or type(v) ~= "number" then
        return nil
      end
      local sum = G.rowRaw ~= nil and G.rowRaw[g] or v
      local old, new = v, math.max(1, sum + d)
      if G.rowOwn then
        old, new = math.max(1, sum - d), v
      end
      if new == old then
        return nil
      end
      return old, new, new - old
    end

    -- each row's number and outline by its state, drawn only when the state changes: the value it would be (G.RowState's
    -- new, else the stat), green / red / the number's own colour, the outline's sprite. `change` and `shown` by group.
    G.rowMarkKey = {}
    function G.ItemCardRowMarks(change, shown)
      local R = IC.row_mark
      G.numBase = G.numBase or {}
      for g = 1, 8 do
        local c = change ~= nil and change[g] or nil
        local value = shown ~= nil and shown[g] or (G.vals[g] or 0)
        local key = tostring(c) .. "/" .. tostring(value)
        if key ~= G.rowMarkKey[g] and Exists(G.NUM) and Cmd(C.IS_OPEN, G.NUM, g - 1) == true then
          local k = G.GROUP_ROW[g]
          local gs, ga = G.GainSprite(k)
          Cmd(C.SPRITE, G.BAR, ga, gs, G.GG.SLOT_GAIN_QUAD, 0, k)
          -- the number's own colour (CMND get prim colour, as the retail SetPrimitiveGrayout reads it), read once
          -- before its first tint
          if G.numBase[g] == nil then
            local ok, r, gg, b = pcall(funcLuaMenuCommand, 3648327470 --[[get prim colour]], G.NUM, g - 1, R.number_style)
            if ok and type(r) == "number" and type(gg) == "number" and type(b) == "number" then
              G.numBase[g] = {r, gg, b}
            end
          end
          local tint = G.numBase[g]
          if c ~= nil then
            tint = R.colour[c > 0 and "raise" or "lower"]
          end
          if tint ~= nil then
            pcall(funcLuaMenuCommand, @crc:CMND_SET_PRIM_COLOR@, G.NUM, g - 1, R.number_style, tint[1], tint[2], tint[3])
          end
          local prim = Cmd(@crc:CMND_SEARCH_PRIM_INDEX@, G.NUM, g - 1, R.number_style)
          Cmd(3609943765, G.NUM, g - 1, prim, value)
          Cmd(1233047821, G.NUM, g - 1, R.number_style, true)
          G.rowMarkKey[g] = key
        end
      end
    end

    -- the icon layer's instances first..last that no part uses: hidden; false while the layer still loads one (an
    -- instance that finishes opening after this call would show the whole card object: the caller tries again)
    local function HideUnused(L, first, last)
      for i = first, last do
        if Cmd(C.IS_OPEN, L, i) == true then
          Cmd(C.VIS, L, i, false)
        end
      end
      return Cmd(C.LOADING, L) ~= true
    end

    -- the delta segments (G.Bars hands their screen rects {x, y, w, h, raise} every frame): drawn on the icon layer's
    -- instances after the labels only when they change; the fill's visible band of the bar (IC.row_mark.delta.band)
    function G.DeltaSegment(segs)
      local R, S = IC.row_mark, IC.set_icons
      local parts = {}
      for _, sg in ipairs(segs or {}) do
        parts[#parts + 1] = string.format("%.0f %.0f %.0f %s", sg[1], sg[2], sg[3], tostring(sg[5]))
      end
      local key = table.concat(parts, "|")
      if key == G.segKey then
        return
      end
      local L = G.EQ_ICON
      if not Exists(L) then
        return
      end
      local B = R.delta.band
      local k, done = R.delta.first, true
      for _, sg in ipairs(segs or {}) do
        if sg[3] >= 1 and k < S.instances then
          local sp = {IC.effect.atlas, CALC_CRC(sg[5] and R.delta.raise or R.delta.lower), sg[3], sg[4] * B[2]}
          done = IconSlot(k, sg[1], sg[2] + sg[4] * B[1], "sprite", sp) and done
          k = k + 1
        end
      end
      done = HideUnused(L, k, R.delta.first + R.delta.count - 1) and done
      G.segKey = done and key or nil
    end

    -- the delta labels over the changed numbers («+41» green, «-10» red; G.RowState's change, group order): the icon
    -- layer's instances after the page icons, as small texts. Called by the frame step (G.Bars) with the segments'
    -- previews; drawn only when they change, and again while an instance is not ready
    function G.ItemCardDeltaLabels(label)
      local L, S, R = G.EQ_ICON, IC.set_icons, IC.row_mark
      local parts = {}
      for g = 1, 8 do
        parts[g] = tostring(label ~= nil and label[g] or "")
      end
      local key = table.concat(parts, "|")
      if key == G.labelKey or not Exists(L) then
        return
      end
      local k = S.page_instances or S.instances
      local last = (IC.row_mark.delta.first or S.instances) - 1
      local done = true
      for g = 1, 8 do
        local v = label ~= nil and label[g] or nil
        if v ~= nil and v ~= 0 and k <= last then
          local row = G.GROUP_ROW[g]
          local col, r = math.floor(row / 4), row % 4
          -- the bars' origin (the chart base at G.CHART_AT), as the delta segments
          local x = G.CHART_AT[1] + G.ROW_X0[col] + R.label.dx
          local y = G.CHART_AT[2] - G.ROW_Y[r] + R.label.dy
          local text = (v > 0 and (R.label.plus .. "+") or (R.label.minus .. "-")) .. tostring(math.abs(v)) .. "[C]"
          done = IconSlot(k, x, y, "text", {text = text, style = "white", scale = R.label.scale}) and done
          k = k + 1
        end
      end
      done = HideUnused(L, k, last) and done
      G.labelKey = done and key or nil
    end

    -- Suerte (no equipment changes it): its number copy's comparison arrows off (the retail graph only sets them for
    -- the 7 stats, so they showed as crossed arrows) and its label given the labels' colour the way the retail graph
    -- does (its layer's label colour group; nothing set it on this screen, so it kept the white of its sprite)
    function G.ItemCardLuckRow()
      local R = IC.row_mark
      if Exists(G.NUM) and Cmd(C.IS_OPEN, G.NUM, R.luck_number) == true then
        for _, m in ipairs(R.luck_arrows) do
          Cmd(C.MESH, G.NUM, m, false, R.luck_number)
        end
      end
      if Exists(G.EXTRA) and Cmd(C.IS_OPEN, G.EXTRA, 0) == true then
        local c = R.label_colour
        pcall(funcLuaMenuCommand, 801406373 --[[material colour of a group]], G.EXTRA, 0, R.label_group, c[1], c[2], c[3])
      end
    end
