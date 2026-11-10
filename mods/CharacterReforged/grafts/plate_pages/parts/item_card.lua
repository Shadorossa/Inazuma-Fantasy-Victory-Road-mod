-- Player page block (plate_pages.lua)
    for k, v in pairs(type(CharacterReforged.PLAYER_PAGE_ITEM_SPEC) == "table" and CharacterReforged.PLAYER_PAGE_ITEM_SPEC or {}) do
      if IC[k] == nil then
        IC[k] = v
      end
    end
    for _, part in ipairs({{"effect", "effect_at"}, {"set_icons", "set_icons_at"}}) do
      local over = IC[part[2]]
      if type(over) == "table" and type(IC[part[1]]) == "table" then
        local t = {}
        for k, v in pairs(IC[part[1]]) do
          t[k] = v
        end
        for k, v in pairs(over) do
          t[k] = v
        end
        IC[part[1]] = t
      end
    end
    if IC.light_text then
      IC.effect.styles.ink = IC.effect.styles.white
      for name, sprite in pairs(IC.effect.sprites_on_dark) do
        IC.effect.sprites[name] = sprite
      end
    end
    IC.layers_set = {}
    for _, l in ipairs(IC.layers or {IC.layer}) do
      IC.layers_set[l] = true
    end
    G.item_card_layer = IC.layer
    local HostHide = G.host_hide
    G.host_hide = function(...)
      if HostHide ~= nil then
        HostHide(...)
      end
      for _, l in ipairs({G.EQ_BODY, G.EQ_ICON, G.EQ_DOTS, G.EQ_YPAGE}) do
        if l ~= nil and Exists(l) then
          for k = 0, 63 do
            if Cmd(C.IS_OPEN, l, k) == true then
              Cmd(C.VIS, l, k, false)
            end
          end
        end
      end
    end

    -- Writes once to loader.log with the call's place (VRFW.debug.traceback).
    if CharacterReforged.PLAYER_PAGE_PCALL == nil then
      local raw = pcall
      CharacterReforged.PLAYER_PAGE_PCALL = raw
      pcall = function(f, ...)
        if f == nil then
          if not CharacterReforged.PLAYER_PAGE_NIL_LOGGED then
            CharacterReforged.PLAYER_PAGE_NIL_LOGGED = true
            local dbg = rawget(_ENV, "VRFW.debug")
            local where = (type(dbg) == "table" and type(dbg.traceback) == "function") and dbg.traceback("", 2) or "?"
            raw(funcLuaCommand, C.LOG, "PlayerPage pcall of a nil function skipped", tostring(where))
          end
          return false, "attempt to call a nil value"
        end
        return raw(f, ...)
      end
    end
    function G.item_card_on()
      return On() and CharacterReforged.PLAYER_PAGE_HOST_OFF ~= true and IC.on ~= false
    end

    local function Fill(template, args)
      return (string.gsub(tostring(template), "{(%w+)}", function(k)
        local v = args[k]
        return v ~= nil and tostring(v) or ""
      end))
    end

    function G.signed_bonus(s)
      local head, minus, num, tail = string.match(s, "^(.-)%+(%-?)(%d+)(.*)$")
      if head == nil then
        return (string.gsub(s, "%+%-", "-"))
      end
      if minus == "-" then
        return head .. IC.minus_colour .. "-" .. num .. "[C]" .. tail
      end
      return head .. IC.plus_colour .. "+" .. num .. "[C]" .. tail
    end

    G.icPage, G.icPages, G.icBonus = 1, {}, ""
    function G.item_card_paged()
      return type(IC.paged) == "table" and #G.icPages > 1
    end
    -- Returns the card's rect.
    function G.item_card_rect()
      local P = IC.paged
      if IC.card_h ~= nil then
        return {IC.rect[1], IC.rect[4] - IC.card_h, IC.rect[3], IC.rect[4]}, P.max_rows
      end
      local h = P.first_row + (P.max_rows - 1) * P.row_pitch + P.bottom
      return {IC.rect[1], IC.rect[2], IC.rect[3], IC.rect[2] + h}, P.max_rows
    end

    function G.item_card_set_page(item)
      local set = IC.set_command ~= nil and VRFW.host.command(IC.set_command, item, (not IC.no_player and type(G.hdl) == "number") and G.hdl or 0)
      if type(set) ~= "table" or type(set.members) ~= "table" then
        return nil
      end
      local worn = {}
      if not IC.no_player and type(G.hdl) == "number" and type(GetCharaEquipmentIds) == "function" then
        local ok, ids = pcall(GetCharaEquipmentIds, G.hdl)
        for _, id in ipairs(ok and type(ids) == "table" and ids or {}) do
          worn[id] = true
        end
      end
      if type(G.icWornSwap) == "table" then          -- a preview: the hovered item in the slot's item's place
        if G.icWornSwap.from ~= nil then
          worn[G.icWornSwap.from] = nil
        end
        worn[G.icWornSwap.to] = true
      end
      local rows, wornSlot, nworn, nslots = {}, {}, 0, 0
      local count = tonumber(set.count) or #set.members
      for k = 1, count do
        local id = set.members[k]
        if id ~= nil then
          local slot = G.item_card_slot(id)
          if slot ~= nil then
            if rows[slot] == nil then
              rows[slot] = {}
              nslots = nslots + 1
            end
            table.insert(rows[slot], {id, worn[id] == true})
            if worn[id] and not wornSlot[slot] then
              wornSlot[slot] = true
              nworn = nworn + 1
            end
          end
        end
      end
      -- progress by pieces = the set's slots covered (one item per slot), as Better Equipment counts the bonus tiers
      G.icSet = {rows = rows, worn = wornSlot, nworn = nworn, nslots = nslots}
      -- the pieces that count for this set (a piece counts for one set only), then its other sets on the same row
      local template = IC.no_player and set.title_any or set.title
      local title = Fill(template or set.title, {set = set.name, worn = tonumber(set.worn) or nworn, count = nslots})
      if type(set.also) == "string" and set.also ~= "" then
        title = title .. "  " .. set.also
      end
      G.icSetTitle = title
      return G.item_card_centred(title)
    end
