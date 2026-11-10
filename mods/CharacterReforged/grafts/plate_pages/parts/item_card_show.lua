-- Player page block (plate_pages.lua)
    function G.item_card_text()
      if #G.icPages == 0 or not Exists(IC.layer) or Cmd(C.IS_OPEN, IC.layer, 0) ~= true then
        return
      end
      if IC.text_on_icons then
        Cmd(C.TEXT_VIS, IC.layer, 3138144965 --[[_text_parameter01]], false, 0)
        G.try("item_card_page_icons")
        return
      end
      local body = G.icPages[G.icPage] or G.icBonus
      Cmd(C.SET_TEXT, IC.layer, 3138144965 --[[_text_parameter01]], body, 0)
      -- the text node only on a page that writes in it (the game's bonus lines never show under the Efecto page)
      Cmd(C.TEXT_VIS, IC.layer, 3138144965 --[[_text_parameter01]], body ~= "", 0)
      G.try("item_card_page_icons")
    end

    G.IC_CTRLS = {1332654303 --[[MENU_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]]}
    local function Pressed(k)
      for _, ctrl in ipairs(G.IC_CTRLS) do
        local ok, hit = pcall(funcLuaCommand, @crc:CMND_CHECK_INPUT_CMD@, ctrl, k)
        if ok and hit == true then
          return true
        end
      end
      return false
    end

    -- Reads the frame's input while a paged card shows.
    function G.item_card_input()
      -- the item picker's script reads the keys while the picker is up (IC.picker_page_event)
      if G.icPreviewing or not G.item_card_pageable() then
        return
      end
      local dir
      if IC.pager ~= nil and IC.pager.style == "ycycle" then
        dir = Pressed(3421673595 --[[CMD_FUNC3]]) and 1 or 0
      else
        dir = (Pressed(1970176280 --[[CMD_FUNCL2]]) and -1) or (Pressed(2704260807 --[[CMD_FUNCR2]]) and 1) or 0
      end
      if dir ~= 0 then
        G.item_card_turn_page(dir)
      end
    end

    function G.item_card_pageable()
      return G.item_card_paged() and G.item_card_on() and Exists(IC.layer)
        and Cmd(C.IS_OPEN, IC.layer, 0) == true and Cmd(C.IS_VIS, IC.layer, 0) == true
    end

    -- one page back (-1) or forward (1), wrapping
    function G.item_card_turn_page(dir)
      G.icPage = (G.icPage - 1 + dir) % #G.icPages + 1
      pcall(funcLuaCommand, @crc:CMND_SND_PLAY_SE@, 1228648509)      -- the retail page switch sound (sy0027)
      G.item_card()
      G.item_card_text()
    end

    function G.item_card_pending()
      if G.itemCardPending and G.item_card_on() then
        G.item_card()
        G.item_card_page_icons()
        if not G.itemCardPending and not IC.no_player and G.itemCardLast ~= nil
            and type(SetupEquipInfoWindow) == "function" then
          pcall(SetupEquipInfoWindow, G.itemCardLast)
        end
      end
    end

    if not IC.no_player then
      PlayerPageWrap("GetEquipParamTextOneLine", function(orig)
        return function(item, idx, ...)
          local ok, s = orig(item, idx, ...)
          if ok == true and type(s) == "string" then
            local okS, signed = pcall(G.signed_bonus, s)
            if okS and type(signed) == "string" then
              s = signed
            end
          end
          return ok, s
        end
      end)
      PlayerPageWrap("GetEquipParamText", function(orig)
        return function(item, ...)
          if not G.item_card_on() or type(GetEquipParamTextOneLine) ~= "function" then
            return orig(item, ...)
          end
          local parts = {}
          for k = 0, 7 do
            local ok, s = GetEquipParamTextOneLine(item, k)
            if ok == true and type(s) == "string" and s ~= "" then
              parts[#parts + 1] = s
            end
          end
          G.icBonus = table.concat(parts, IC.bonus_gap)
          return G.icBonus
        end
      end)
      PlayerPageWrap("SetVisibleEquipInfoWindow", function(orig)
        return function(on, ...)
          G.try("item_card_subscribe")
          local r = Pack(orig(on, ...))
          if on ~= true then
            G.item_card_hide()                    -- nothing focused: the rows' own look, no card
          end
          return table.unpack(r, 1, r.n)
        end
      end)
    end

    -- Returns the equip slot 1..4 of an item by its category (nil = not equipment).
    function G.item_card_slot(item)
      local ok, category = pcall(funcLuaCommand, @crc:CMND_GET_ITEM_PARAM@ --[[the item's category]], item, 2)
      return ok and IC.set_icons.slot_of_category[tonumber(category) or 0] or nil
    end

    -- Shows the card of `item` after the game filled the card layer (name, icon, chips).
    function G.item_card_show(item, base)
      if item ~= G.icShown then
        G.icPage = 1                          -- another item: its first page
      end
      G.icShown = item
      G.icWornSwap = base ~= nil and {from = base ~= 0 and base or nil, to = item} or nil
      if IC.prio_above_card and Exists(IC.layer) then
        local okP, p = pcall(funcLuaMenuCommand, @crc:CMND_GET_DRAW_PRIORITY@, IC.layer, 0)
        G.icPrioBase = okP and tonumber(p) or G.icPrioBase
      end
      if G.item_card_on() then
        G.try("item_card_pages", item)          -- after the fill: G.icBonus is the item's bonus row
        G.try("item_card")
        G.try("item_card_text")
      end
      if IC.rows ~= false then
        G.try("item_card_rows", item, base)
      end
    end

    -- Hides the card (nothing focused or hovered).
    function G.item_card_hide()
      G.icPages, G.icShown, G.icWornSwap = {}, nil, nil
      if IC.text_on_icons and Exists(IC.layer) and Cmd(C.IS_OPEN, IC.layer, 0) == true then
        Cmd(C.TEXT_VIS, IC.layer, 3138144965 --[[_text_parameter01]], true, 0)   -- another item: the game's own line
      end
      if IC.rows ~= false then
        G.try("item_card_rows", nil)
      end
      G.try("item_card_body", nil, false)
      G.try("item_card_page_icons")
    end

    if not IC.no_player then
      function G.item_card_subscribe()
        if G.icSubscribed or type(VRFW.menu_event) ~= "table" then
          return
        end
        G.icSubscribed = VRFW.menu_event.on(IC.picker_event, IC.menu, IC.picker_owner, function(item)
          item = tonumber(item)
          if item == nil then
            return
          end
          if item < 0 then
            G.icPreviewing = false
            CharacterReforged.player_page_item_card_preview_end()
          else
            G.icPreviewing = true
            CharacterReforged.player_page_item_card_preview(item)
          end
          G.try("bars")
        end)
        VRFW.menu_event.on(IC.picker_page_event, IC.menu, IC.picker_owner, function(dir)
          dir = tonumber(dir)
          if dir ~= nil and G.item_card_pageable() then
            G.item_card_turn_page(dir)
          end
        end)
      end
      PlayerPageWrap("OnInit", function(orig)
        return function(...)
          local r = Pack(orig(...))
          G.try("item_card_subscribe")
          return table.unpack(r, 1, r.n)
        end
      end)

      -- Returns what the hovered item would replace.
      function G.item_card_replaced(item)
        local slot = G.item_card_slot(item)
        if slot == nil then
          return 0
        end
        if type(G.hdl) ~= "number" or type(GetCharaEquipmentIds) ~= "function" then
          return G.itemCardLast or 0
        end
        local okIds, ids = pcall(GetCharaEquipmentIds, G.hdl)
        return okIds and type(ids) == "table" and ids[slot] or 0
      end

      -- Runs after coming back from the picker (an equip or remove there changed the player and the slot).
      PlayerPageWrap("OnChangeLayerGroup", function(orig)
        return function(group, ...)
          local r = Pack(orig(group, ...))
          if group == IC.select_group and type(UpdateEquipItemInfo) == "function" then
            G.icPreviewing = false
            pcall(UpdateEquipItemInfo)
          end
          return table.unpack(r, 1, r.n)
        end
      end)

      function CharacterReforged.player_page_item_card_preview(item)
        if item == nil or item == 0 then
          G.item_card_hide()
          return true
        end
        if type(G.hdl) == "number" then
          local ok, v = pcall(G.values, G.hdl)
          if ok and type(v) == "table" then
            G.vals = v
          end
        end
        G.try("item_card")
        -- Handles the picker's own script having filled the card.
        if type(GetEquipParamText) == "function" then
          pcall(GetEquipParamText, item)
        end
        local replaced = G.item_card_replaced(item)
        G.item_card_show(item, replaced)
        local parts = {}
        for g = 1, 8 do
          local d = G.rowDelta ~= nil and G.rowDelta[g] or nil
          if d ~= nil then
            parts[#parts + 1] = string.format("%s%+d", tostring(G.STAT[g]), d)
          end
        end
        pcall(funcLuaCommand, C.LOG, "picker hover", tostring(item), "vs", tostring(replaced), "delta",
          table.concat(parts, " "), "frames", tostring(G.frameSteps or 0))
        return true
      end
      function CharacterReforged.player_page_item_card_preview_end()
        if G.itemCardLast ~= nil and G.itemCardLast ~= 0 then
          G.try("item_card")
          G.item_card_show(G.itemCardLast, nil)
        else
          G.item_card_hide()
        end
        return true
      end

      PlayerPageWrap("SetupEquipInfoWindow", function(orig)
        return function(item, ...)
          G.try("item_card_subscribe")
          G.itemCardLast = item
          if G.item_card_on() then
            G.try("item_card")                   -- Nodes first: the fill draws the texts / icons where the nodes are.
          end
          local r = Pack(orig(item, ...))
          G.item_card_show(item, nil)
          return table.unpack(r, 1, r.n)
        end
      end)
    else
      -- Watches a screen without a player (inventory, shop).
      function G.item_card_watch()
        if G.icWatched or type(funcLuaMenuCommand) ~= "function" then
          return
        end
        G.icWatched = true
        local raw = funcLuaMenuCommand
        -- Every call goes on with exactly the arguments it got (raw(...)).
        funcLuaMenuCommand = function(...)
          local cmd, layer = ...
          if cmd == C.VIS and IC.layers_set[layer] then
            local r = Pack(raw(...))
            if layer == IC.layer and G.icShown ~= nil then
              G.try("item_card_page_icons")
            end
            return table.unpack(r, 1, r.n)
          end
          return raw(...)
        end
      end
      PlayerPageWrap("SetupItemPositionIcon", function(orig)
        return function(layer, k, item, ...)
          local r = Pack(orig(layer, k, item, ...))
          if IC.layers_set[layer] and type(item) == "number" and item ~= 0 then
            G.try("item_card_watch")
            IC.layer = layer
            G.item_card_layer = layer
            G.item_card_show(item, nil)
          end
          return table.unpack(r, 1, r.n)
        end
      end)
      PlayerPageWrap("ClearItemPositionIcon", function(orig)
        return function(layer, ...)
          local r = Pack(orig(layer, ...))
          if IC.layers_set[layer] and layer == IC.layer and G.icShown ~= nil then
            G.item_card_hide()
          end
          return table.unpack(r, 1, r.n)
        end
      end)
    end
