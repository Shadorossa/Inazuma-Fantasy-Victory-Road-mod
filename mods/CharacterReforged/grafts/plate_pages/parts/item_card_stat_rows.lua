-- Player page block (plate_pages.lua)
    -- Formats a stat change as a signed number.
    function G.signed_stat(v)
      v = tonumber(v) or 0
      if v > 2147483647 then
        v = v - 4294967296
      end
      if v < -9999 or v > 9999 then
        return 0
      end
      return v
    end
    -- The item's own stat (the game's equip parameter).
    local function ItemStat(it, si)
      if it == nil or it == 0 then
        return 0
      end
      local ok, has, v = pcall(funcLuaCommand, @crc:CMND_GET_EQUIP_PARAM@, it, si)
      return ok and has ~= false and G.signed_stat(v) or 0
    end

    -- The 8 stat points the player page bonus hosts add (Equipment: affinity and sets, as the match adds them).
    local function StatBonus(item, slot)
      local page = CharacterReforged ~= nil and CharacterReforged.page or nil
      if type(G.hdl) ~= "number" or page == nil or page.stat_bonus == nil then
        return nil
      end
      local ok, b = pcall(page.stat_bonus, G.hdl, item, slot)
      return ok and type(b) == "table" and b or nil
    end

    -- Builds the stats panel's rows.
    function G.item_card_rows(item, base)
      local delta = nil
      if base ~= nil and base == item then
        base = nil
      end
      -- The bonus as worn now, then with the focused item worn (base nil: the focused item is the worn one, taken off).
      local now = StatBonus()
      local bonus = nil
      if now ~= nil then
        bonus = {}
        for g = 1, 8 do
          bonus[g] = G.signed_stat(now[G.STAT[g] + 1])
        end
      end
      -- The total of the item per stat is its stats plus the bonus points it brings into its slot, as the header boxes show.
      local total = nil
      if item ~= nil and item ~= 0 and G.item_card_on() and IC.rows ~= false then
        local slot = G.item_card_slot(item) or 0
        local empty = StatBonus(0, slot)
        local with = base == nil and now or StatBonus(item, slot)
        for si = 0, 7 do
          local brings = 0
          if empty ~= nil and with ~= nil then
            brings = G.signed_stat(with[si + 1]) - G.signed_stat(empty[si + 1])
          end
          local own = ItemStat(item, si) + brings
          local d = own
          if base ~= nil then
            local change = 0
            if now ~= nil and with ~= nil then
              change = G.signed_stat(with[si + 1]) - G.signed_stat(now[si + 1])
            end
            d = ItemStat(item, si) - ItemStat(base, si) + change
          end
          for g = 1, 8 do
            if G.STAT[g] == si then
              if d ~= 0 then
                delta = delta or {}
                delta[g] = d
              end
              if own ~= 0 then
                total = total or {}
                total[g] = own
              end
            end
          end
        end
      end
      G.rowTotal = total
      -- A stat shown at the game's minimum 1 can be below it (a drained stat); G.vals hold the bonus points too.
      local raw = nil
      if delta ~= nil and G.vals ~= nil and type(G.hdl) == "number" and CharacterReforged ~= nil
          and CharacterReforged.page ~= nil and CharacterReforged.page.stat_sum ~= nil then
        for g in pairs(delta) do
          local b = bonus ~= nil and bonus[g] or 0
          if (G.vals[g] or 0) - b <= 1 then
            local sum = CharacterReforged.page.stat_sum(G.hdl, G.STAT[g])
            raw = raw or {}
            raw[g] = sum ~= nil and sum + b or nil
          end
        end
      end
      G.rowDelta, G.rowOwn, G.rowRaw = delta, base == nil, raw
      G.try("item_card_luck_row")
    end

    -- Both kept at the game's minimum 1.
    function G.row_state(g, v)
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

    -- Sets each row's number and outline by its state, drawn only when the state changes.
    G.rowMarkKey = {}
    function G.item_card_row_marks(change, shown)
      local R = IC.row_mark
      G.numBase = G.numBase or {}
      for g = 1, 8 do
        local c = change ~= nil and change[g] or nil
        local value = shown ~= nil and shown[g] or (G.vals[g] or 0)
        local key = tostring(c) .. "/" .. tostring(value)
        if key ~= G.rowMarkKey[g] and Exists(G.NUM) and Cmd(C.IS_OPEN, G.NUM, g - 1) == true then
          local k = G.GROUP_ROW[g]
          local gs, ga = G.gain_sprite(k)
          Cmd(C.SPRITE, G.BAR, ga, gs, G.GG.SLOT_GAIN_QUAD, 0, k)
          -- Reads the number's own colour once, before its first tint (CMND get prim colour, as the retail SetPrimitiveGrayout reads it).
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

    -- Hides the icon layer's instances first..last that no part uses.
    local function HideUnused(L, first, last)
      for i = first, last do
        if Cmd(C.IS_OPEN, L, i) == true then
          Cmd(C.VIS, L, i, false)
        end
      end
      return Cmd(C.LOADING, L) ~= true
    end

    -- Draws the delta segments (G.bars hands their screen rects {x, y, w, h, raise} every frame).
    function G.delta_segment(segs)
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

    -- Draws the delta labels on the icon layer's instances after the page icons, as small texts.
    function G.item_card_delta_labels(label)
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

    -- This draws one grey plate per stat the focused item changes, with its stat icon and its signed total.
    function G.item_card_stat_boxes(total)
      local B = IC.stat_boxes
      local L = G.EQ_ICON
      if type(B) ~= "table" or not Exists(L) then
        return
      end
      local parts = {}
      for g = 1, 8 do
        parts[g] = tostring(total ~= nil and total[g] or "")
      end
      local key = table.concat(parts, "|")
      if key == G.boxKey then
        return
      end
      local E = IC.effect
      local list, width = {}, 0
      for g = 1, 8 do
        local v = total ~= nil and total[g] or nil
        local stat = IC.stat_by_index[G.STAT[g] + 1]
        local icon = stat ~= nil and E.stat_icons[stat] or nil
        if v ~= nil and v ~= 0 and icon ~= nil then
          local text = (v > 0 and (IC.plus_colour .. "+") or (IC.minus_colour .. "-")) .. tostring(math.abs(v)) .. "[C]"
          local digits = #tostring(math.abs(v)) + 1
          local w = B.pad + B.icon + B.gap + digits * B.char_px + B.pad
          list[#list + 1] = {icon = icon, text = text, w = w}
          width = width + w + (#list > 1 and B.spacing or 0)
        end
      end
      local rect = IC.rect
      local x = B.align == "right" and rect[3] - B.margin - width or rect[1] + B.margin
      local top = rect[2] - B.h + B.overlap
      local k, done = B.first, true
      for _, b in ipairs(list) do
        if k + 2 < B.first + B.count then
          done = IconSlot(k, x, top, "sprite", {E.atlas, CALC_CRC(E.sprites.chip_off), b.w, B.h}) and done
          done = IconSlot(k + 1, x + B.pad, top + (B.h - B.overlap - B.icon) / 2, "sprite",
            {E.atlas, CALC_CRC(string.format(E.sprites.stat, b.icon)), B.icon, B.icon}) and done
          done = IconSlot(k + 2, x + B.pad + B.icon + B.gap, top + (B.h - B.overlap) / 2, "text",
            {text = b.text, style = "white", scale = B.text_scale}) and done
          k = k + 3
        end
        x = x + b.w + B.spacing
      end
      done = HideUnused(L, k, B.first + B.count - 1) and done
      G.boxKey = done and key or nil
    end

    -- Suerte (no equipment changes it)
    function G.item_card_luck_row()
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
