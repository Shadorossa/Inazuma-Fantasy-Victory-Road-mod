    -- row 1 the item's passive chip, position / element badges and raised stats
    local function EffWidth(text, style)
      local E = IC.effect
      local st = E.styles[style] or E.styles.white
      local ok, w = pcall(funcLuaMenuCommand, @crc:CMND_GET_MENU_TEXT_RECT_SIZE@, IC.layer, 0, st.node, text)
      w = ok and tonumber(w) or nil
      if w == nil or w <= 0 then
        w = #text * st.char_px
      end
      return w
    end

    local function Spr(name)
      return {IC.effect.atlas, CALC_CRC(name)}
    end

    -- Returns the content of a chip.
    local function EffPieces(part, on)
      local E = IC.effect
      local p = {}
      if part.stat ~= nil then
        local n = E.stat_icons[part.stat]
        if n ~= nil then
          p[#p + 1] = {sprite = string.format(E.sprites.stat, n)}
        end
        local name = G.item_card_stat_name(part.stat_index) or part.stat_name or part.stat
        p[#p + 1] = {text = tostring(name)}
        p[#p + 1] = {text = tostring(part.value)}
        return p
      end
      if part.label ~= nil and (part.element ~= nil or part.family ~= nil) then
        p[#p + 1] = {text = tostring(part.label)}
        local el = part.element ~= nil and E.elements[part.element] or nil
        local ext = type(part.element_icon) == "table" and part.element_icon or nil
        if el ~= nil then
          p[#p + 1] = {sprite = string.format(on and E.sprites.element or E.sprites.element_off, el)}
        elseif ext ~= nil then
          p[#p + 1] = {atlas = ext.atlas, sprite_id = ext.sprite}
        elseif part.family ~= nil then
          p[#p + 1] = {text = tostring(part.family)}
        elseif part.element ~= nil then
          p[#p + 1] = {text = tostring(G.item_card_element_name(part.element) or part.element_name or part.element)}
        end
        p[#p + 1] = {text = tostring(part.value)}
        return p
      end
      p[#p + 1] = {text = tostring(part.text or "")}
      return p
    end

    G.statNames = G.statNames or {}
    function G.item_card_stat_name(si)
      si = tonumber(si)
      local id = si ~= nil and IC.effect.stat_texts[si + 1] or nil
      if id == nil then
        return nil
      end
      if G.statNames[si] == nil then
        local ok, t = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@ --[[the text of a text id]], id)
        local name = ok and type(t) == "string" and string.match(t, "^(.-)%s*%+") or nil
        G.statNames[si] = (name ~= nil and name ~= "") and name or false
      end
      return G.statNames[si] or nil
    end

    G.elementNames = G.elementNames or {}
    function G.item_card_element_name(element)
      local id = element ~= nil and IC.effect.element_texts[element] or nil
      if id == nil then
        return nil
      end
      if G.elementNames[element] == nil then
        local ok, t = pcall(funcLuaCommand, @crc:CMND_TEXT_GET@ --[[the text of a text id]], id)
        G.elementNames[element] = (ok and type(t) == "string" and t ~= "") and t or false
      end
      return G.elementNames[element] or nil
    end

    local function PiecesWidth(pieces, style, sc)
      local E = IC.effect
      sc = sc or E.text_scale
      local w = 0
      for i, pc in ipairs(pieces) do
        if i > 1 then
          w = w + E.gap
        end
        if pc.sprite ~= nil or pc.sprite_id ~= nil then
          w = w + E.icon
        else
          w = w + EffWidth(pc.text, style) * sc
        end
      end
      return w
    end

    -- the pieces drawn from x at centre y (text colour tag `tag`)
    local function DrawPieces(out, pieces, x, y, tag, style, sc)
      local E = IC.effect
      sc = sc or E.text_scale
      for i, pc in ipairs(pieces) do
        if i > 1 then
          x = x + E.gap
        end
        if pc.sprite ~= nil or pc.sprite_id ~= nil then
          local sp = pc.sprite_id ~= nil and {pc.atlas, pc.sprite_id} or Spr(pc.sprite)
          out[#out + 1] = {kind = "sprite", x = x, y = y - E.icon / 2, value = {sp[1], sp[2], E.icon, E.icon}}
          x = x + E.icon
        else
          local t = pc.tag or tag
          out[#out + 1] = {kind = "text", x = x, y = y, value = {text = t .. pc.text .. (t ~= "" and "[C]" or ""),
            style = style, scale = sc}}
          x = x + EffWidth(pc.text, style) * sc
        end
      end
      return x
    end

    local function Section(out, x, y, sprite)
      local E = IC.effect
      local sp = Spr(sprite)
      out[#out + 1] = {kind = "sprite", x = x, y = y - E.section / 2, value = {sp[1], sp[2], E.section, E.section}}
      x = x + E.section + E.sep_gap
      local sv = Spr(E.sprites.sep)
      out[#out + 1] = {kind = "sprite", x = x, y = y - E.sep[2] / 2, value = {sv[1], sv[2], E.sep[1], E.sep[2]}}
      return x + E.sep[1] + E.sep_gap
    end

    local function Chip(out, x, y, w, sprite, h)
      local E = IC.effect
      local sp = Spr(sprite)
      h = h or E.chip_h
      out[#out + 1] = {kind = "sprite", x = x, y = y - h / 2, value = {sp[1], sp[2], w, h, under = true}}
    end

    function G.item_card_effect_items(rect)
      local E, F = IC.effect, G.icEffect
      local out = {}
      local x0, y0 = rect[1], rect[2]
      local r1, r2 = y0 + E.row1, y0 + E.row2
      local check = Spr(E.sprites.check)
      -- Draws row 1, left.
      local x = Section(out, x0 + E.left, r1, E.sprites.bond)
      if type(F.passive) == "table" then
        local pieces = EffPieces(F.passive, true)
        local pw = PiecesWidth(pieces, "white")
        local w = math.max(pw + 2 * E.chip_pad, E.passive_w)
        Chip(out, x, r1, w, E.sprites.chip_on)
        DrawPieces(out, pieces, x + (w - pw) / 2, r1, "", "white")
      end
      -- Draws row 1, right.
      local A = F.affinity
      if type(A) == "table" then
        x = Section(out, x0 + E.split, r1, E.sprites.emblem)
        local pos = A.position ~= nil and E.positions[A.position] or nil
        if pos ~= nil then
          local own = type(E.position_own) == "table" and E.position_own[A.position] or nil
          local sp = (A.pos_ok or IC.no_player)
            and (own ~= nil and Spr(own) or {IC.badges.atlas, CALC_CRC(string.format(E.sprites.position, pos))})
            or Spr(string.format(E.sprites.position_off, pos))
          out[#out + 1] = {kind = "sprite", x = x, y = r1 - E.badge[2] / 2, value = {sp[1], sp[2], E.badge[1], E.badge[2]}}
          if A.pos_ok then
            out[#out + 1] = {kind = "sprite", x = x + E.badge[1] - E.check / 2, y = r1 - E.badge[2] / 2 - E.check / 2,
              value = {check[1], check[2], E.check, E.check}}
          end
          x = x + E.badge[1] + E.gap
        end
        local el = A.element ~= nil and E.elements[A.element] or nil
        local ext = type(A.element_icon) == "table" and A.element_icon or nil
        if el == nil and ext == nil and A.element ~= nil then
          if pos ~= nil then
            x = DrawPieces(out, {{text = E.plus}}, x, r1, "", "ink") + E.gap
          end
          x = DrawPieces(out, {{text = G.item_card_element_name(A.element) or A.element}}, x, r1, "", "ink") + E.gap
        end
        if el ~= nil or ext ~= nil then
          if pos ~= nil then
            x = DrawPieces(out, {{text = E.plus}}, x, r1, "", "ink") + E.gap
          end
          local sp = el ~= nil and Spr(string.format((A.el_ok or IC.no_player) and E.sprites.element or E.sprites.element_off, el))
            or {ext.atlas, ext.sprite}
          out[#out + 1] = {kind = "sprite", x = x, y = r1 - E.icon / 2, value = {sp[1], sp[2], E.icon, E.icon}}
          if A.el_ok then
            out[#out + 1] = {kind = "sprite", x = x + E.icon - E.check / 2, y = r1 - E.icon / 2 - E.check / 2,
              value = {check[1], check[2], E.check, E.check}}
          end
          x = x + E.icon + E.gap
        end
        local pieces = {}
        for _, st in ipairs(type(A.stats) == "table" and A.stats or {}) do
          local n = E.stat_icons[st]
          if n ~= nil then
            pieces[#pieces + 1] = {sprite = string.format(E.sprites.stat, n)}
          end
        end
        pieces[#pieces + 1] = {text = tostring(A.text or "")}
        local rate = A.rate or ((A.pos_ok and A.el_ok) and "both" or (A.pos_ok and "one" or "none"))
        if IC.no_player then
          rate = "one"                         -- the requirement and both rates: the neutral (blue) chip
        end
        local chip = rate == "both" and E.sprites.chip_on or (rate == "one" and E.sprites.chip_blue or E.sprites.chip_off)
        local style = rate == "none" and "ink" or "white"   -- the off plate is light: the card's dark text
        local pw = PiecesWidth(pieces, style)
        local w = math.max(pw + 2 * E.chip_pad, E.affinity_w)
        local cx = math.max(x + E.gap, x0 + E.right - w)
        Chip(out, cx, r1, w, chip)
        DrawPieces(out, pieces, cx + (w - pw) / 2, r1, "", style)
      end
      -- Draws row 2.
      local S = G.icSet
      if type(F.tiers) == "table" and #F.tiers > 0 and type(S) == "table" then
        x = Section(out, x0 + E.left, r2, E.sprites.equip)
        local SI = IC.set_icons
        for slot = 1, #SI.slot_sprites do
          if S.rows[slot] ~= nil then
            local worn = S.worn[slot] == true
            local sp = worn and {SI.worn_atlas, SI.slot_worn_sprites[slot]} or {SI.slot_atlas, SI.slot_sprites[slot]}
            out[#out + 1] = {kind = "sprite", x = x, y = r2 - E.slot[2] / 2, value = {sp[1], sp[2], E.slot[1], E.slot[2]}}
            x = x + E.slot[1] + E.gap
          end
        end
        if not IC.no_player then
          x = DrawPieces(out, {{text = string.format("%d/%d", S.nworn or 0, S.nslots or 0)}}, x, r2, "", "ink")
        end
        x = x + E.tier_gap
        -- the tier chips to the right edge, the room split by their natural widths
        local nat, total = {}, 0
        for i, t in ipairs(F.tiers) do
          local on = not IC.no_player and (S.nworn or 0) >= (tonumber(t.pieces) or 99)
          local pieces = EffPieces(t.reward or {}, on)
          local style = (on or IC.no_player) and "white" or "ink"   -- the off plate is light: the card's dark text
          local w = math.max(PiecesWidth(pieces, style, E.tier_scale), E.tier_min) + 2 * E.chip_pad
          nat[i] = {pieces = pieces, w = w, on = on, style = style, need = tonumber(t.pieces) or 2}
          total = total + w
        end
        local room = (x0 + E.right) - x - (#nat - 1) * E.tier_gap
        for _, t in ipairs(nat) do
          local w = total > 0 and math.max(t.w, room * t.w / total) or t.w
          Chip(out, x, r2, w, t.on and E.sprites.chip_on or (IC.no_player and E.sprites.chip_blue or E.sprites.chip_off),
            E.tier_h)
          -- the reward centred, its text shrunk to fit the chip (down to tier_scale_min)
          local sc = E.tier_scale
          local pw = PiecesWidth(t.pieces, t.style, sc)
          if pw > w - 2 * E.chip_pad then
            sc = math.max(E.tier_scale_min, sc * (w - 2 * E.chip_pad) / pw)
            pw = PiecesWidth(t.pieces, t.style, sc)
          end
          DrawPieces(out, t.pieces, x + (w - pw) / 2, r2 + E.reward_dy, "", t.style, sc)
          local bx0, bx1 = x + E.bar_pad, x + w - E.bar_pad
          local bw = (bx1 - bx0 - E.bar_gap * (t.need - 1)) / t.need
          for i = 1, t.need do
            local name = i <= (S.nworn or 0) and (t.on and E.sprites.bar_white or E.sprites.bar_on) or E.sprites.bar_off
            local sp = Spr(name)
            out[#out + 1] = {kind = "sprite", x = bx0 + (i - 1) * (bw + E.bar_gap), y = r2 + E.bar_dy,
              value = {sp[1], sp[2], bw, E.bar_h}}
          end
          x = x + w + E.tier_gap
        end
      end
      return out
    end

    function G.item_card_centred(text)
      local B = IC.badges
      local w = TextWidth(text)
      local sw = TextWidth(string.rep(".", 10))
      local dot = TextWidth(string.rep(".", 10) .. string.rep(" ", 10))
      sw = (sw ~= nil and dot ~= nil and dot > sw) and (dot - sw) / 10 or B.space_px
      if w == nil then
        return text
      end
      local pad = ((IC.rect[3] - IC.rect[1]) / 2 - IC.text_x) - w / 2
      return string.rep(" ", math.max(0, math.floor(pad / sw + 0.5))) .. text
    end

    -- Returns the parts of the stat page (a card without a player).
    function G.item_card_stat_parts(item)
      local E, parts = IC.effect, {}
      for si = 0, 7 do
        local ok, has, v = pcall(funcLuaCommand, @crc:CMND_GET_EQUIP_PARAM@, item, si)
        v = ok and has ~= false and tonumber(v) or 0
        local name = v ~= 0 and G.item_card_stat_name(si) or nil
        if name ~= nil then
          local key = IC.stat_by_index ~= nil and IC.stat_by_index[si + 1] or nil
          local icon = key ~= nil and E.stat_icons[key] or nil
          parts[#parts + 1] = {icon = icon ~= nil and string.format(E.sprites.stat, icon) or nil, name = name, value = v}
        end
      end
      return parts
    end

    -- Returns the shown page's texts drawn on the icon layer.
    function G.item_card_text_items(rect)
      local E, out = IC.effect, {}
      local width = rect[3] - rect[1] - 2 * (IC.set_icons.margin or 0)
      if G.icStatPage ~= nil and G.icPage == G.icStatPage then
        local sc, groups = E.stat_scale, {}
        for _, p in ipairs(G.icStats or {}) do
          local pieces = {}
          if p.icon ~= nil then
            pieces[#pieces + 1] = {sprite = p.icon}
          end
          pieces[#pieces + 1] = {text = p.name}
          pieces[#pieces + 1] = {text = (p.value > 0 and "+" or "-") .. tostring(math.abs(p.value)),
            tag = p.value > 0 and IC.plus_colour or IC.minus_colour}
          groups[#groups + 1] = pieces
        end
        local function Total(scale)
          local t = 0
          for _, g in ipairs(groups) do
            t = t + PiecesWidth(g, "ink", scale)
          end
          return t + math.max(0, #groups - 1) * E.stat_gap
        end
        local total = Total(sc)
        if total > width and total > 0 then
          sc = sc * width / total
          total = Total(sc)
        end
        local x = rect[1] + ((rect[3] - rect[1]) - total) / 2
        for _, g in ipairs(groups) do
          DrawPieces(out, g, x, rect[2] + E.stat_row, "", "ink", sc)
          x = x + PiecesWidth(g, "ink", sc) + E.stat_gap
        end
      elseif G.icSetPage ~= nil and G.icPage == G.icSetPage and type(G.icSetTitle) == "string" then
        local sc = E.title_scale
        local w = EffWidth(G.icSetTitle, "ink") * sc
        if w > width and w > 0 then
          sc = sc * width / w
          w = width
        end
        DrawPieces(out, {{text = G.icSetTitle}}, rect[1] + ((rect[3] - rect[1]) - w) / 2, rect[2] + E.title_y, "",
          "ink", sc)
      end
      return out
    end

    function G.item_card_effect_page(effect)
      if type(effect) == "string" then
        return effect
      end
      if type(effect) ~= "table" then
        return nil
      end
      local lines = {}
      for _, l in ipairs(type(effect.lines) == "table" and effect.lines or {}) do
        lines[#lines + 1] = tostring(l)
      end
      local a = effect.affinity
      if type(a) == "table" then
        local B = IC.badges
        local label = tostring(a.label or "")
        local row = label
        local sprite = a.position ~= nil and B.sprites[a.position] or nil
        if sprite ~= nil then
          local lw = label ~= "" and TextWidth(label) or 0
          local dots = TextWidth(string.rep(".", 10))
          local both = TextWidth(string.rep(".", 10) .. string.rep(" ", 10))
          local sw = (dots ~= nil and both ~= nil and both > dots) and (both - dots) / 10 or B.space_px
          local spaces = math.ceil((B.size[1] + 2 * B.gap) / sw)
          row = label .. string.rep(" ", spaces)
          local start = lw or #label * B.char_px
          G.icAffinity = {row = #lines + 1, sprite = sprite, x = start + (spaces * sw - B.size[1]) / 2}
        end
        if a.element ~= nil then
          row = row .. tostring(a.element) .. " "
        end
        lines[#lines + 1] = row .. tostring(a.text or "")
      end
      return table.concat(lines, "\n")
    end

    function G.item_card_pages(item)
      G.icPages, G.icSetPage, G.icStatPage, G.icPageNames, G.icSetTitle = {}, nil, nil, {}, nil
      if item == nil or item == 0 or not G.item_card_on() then
        return
      end
      G.icAffinity, G.icEffectPage, G.icEffect, G.icSet = nil, nil, nil, nil
      local hdl = (not IC.no_player and type(G.hdl) == "number") and G.hdl or 0
      local ok, set = pcall(G.item_card_set_page, item)
      local effect = IC.page_command ~= nil and VRFW.host.command(IC.page_command, item, hdl)
      local names = type(effect) == "table" and type(effect.page_names) == "table" and effect.page_names or {}
      if IC.stat_page then
        G.icStats = G.item_card_stat_parts(item)
        if #G.icStats > 0 then
          G.icPages[#G.icPages + 1] = ""
          G.icStatPage = #G.icPages
          G.icPageNames[#G.icPages] = names.stats
        end
      end
      if type(effect) == "table" and (type(effect.passive) == "table" or type(effect.affinity) == "table"
          or (type(effect.tiers) == "table" and #effect.tiers > 0)) then
        G.icEffect = effect
        G.icPages[#G.icPages + 1] = ""                    -- drawn by G.item_card_effect_items, no text
        G.icEffectPage = #G.icPages
        G.icPageNames[#G.icPages] = names.effect
      else
        local body = G.item_card_effect_page(effect)
        if body ~= nil and body ~= "" then
          G.icPages[#G.icPages + 1] = body
          G.icEffectPage = #G.icPages
        end
      end
      if ok and type(set) == "string" and set ~= "" then
        G.icPages[#G.icPages + 1] = IC.text_on_icons and "" or set
        G.icSetPage = #G.icPages
        G.icPageNames[#G.icPages] = names.set
      end
      if #G.icPages == 0 and not IC.stat_page then
        G.icStats = G.item_card_stat_parts(item)
        if #G.icStats > 0 then
          G.icPages[1] = ""
          G.icStatPage = 1
          G.icPageNames[1] = names.stats
        end
      end
      if G.icPage > #G.icPages then
        G.icPage = 1
      end
    end

    function G.item_card()
      local L, i = IC.layer, 0
      if not Exists(L) or Cmd(C.IS_OPEN, L, i) ~= true then
        G.itemCardPending = true
        return
      end
      G.itemCardPending = false
      if IC.relayout == false then
        return
      end
      local rect = G.item_card_rect()
      local h = rect[4] - rect[2]
      -- The base sits at the card's `anchor`.
      local ax, ay = IC.anchor[1], IC.anchor[2]
      local x0, y0 = rect[1], rect[2]
      Cmd(C.NODE_POS, L, i, IC.base, 0, x0 + ax - IC.root[1])
      Cmd(C.NODE_POS, L, i, IC.base, 1, IC.root[2] - (y0 + ay))
      for _, n in ipairs(IC.nodes) do
        local x, y, w, hh = n[2], n[3], n[4], n[5]
        if n.body then
          hh = h
        end
        Cmd(C.NODE_POS, L, i, n[1], 0, x - ax)
        Cmd(C.NODE_POS, L, i, n[1], 1, ay - y)
        if w ~= nil then
          Cmd(C.NODE_SCALE, L, i, n[1], w, hh)
        end
      end
      -- Hides the retail body mesh (its drop shadow).
      Cmd(C.MESH, L, IC.body_mesh, false, i)
      if IC.body_bottom == nil then
        G.try("item_card_body", nil, false)
      else
        local body = {rect[1], rect[2], rect[3], math.max(rect[4], IC.body_bottom)}
        if not G.item_card_body(body, true) then
          G.itemCardPending = true
        end
      end
      if not G.icDumped then
        G.icDumped = true
        G.try("item_card_dump")
      end
    end

    -- Dumps once.
    function G.item_card_dump()
      for _, n in ipairs(IC.dump or {}) do
        local ok, x, y = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_GLOBAL_POSITION@, IC.layer, 0, n[1])
        pcall(funcLuaCommand, C.LOG, "PlayerPage item card node", n[2], tostring(ok and x), tostring(ok and y))
      end
    end
