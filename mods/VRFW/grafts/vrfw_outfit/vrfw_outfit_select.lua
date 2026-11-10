-- ===== VRFW outfit_select BEGIN ===== (research/grafts/vrfw_outfit) "Equipamiento" (equip_menu_select) gets
do
  VRFW.outfit = VRFW.outfit or {}
  VRFW.outfit.COUNT = @crc:CMND_VRFW_OUTFIT_COUNT@
  VRFW.outfit.OF = @crc:CMND_VRFW_OUTFIT_OF@
  VRFW.outfit.TEXT_SLOT = @crc:vrfw_outfit_slot@     -- menu_text "Elegir atuendo"
  VRFW.outfit.TEXT_SLOT_LOOK = @crc:vrfw_outfit_card_look_on@
  VRFW.outfit.TEXT_GET = @crc:CMND_TEXT_GET@                  -- (textId) -> text
  VRFW.outfit.SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@                  -- (layer, text name, string, instance)
  VRFW.outfit.TEXT_ALPHA = @crc:CMND_SET_MENU_TEXT_ALPHA@                -- (layer, instance, text name, alpha)
  VRFW.outfit.L_ROW = 4251697490                     -- soccer11_08_equip_list_item
  VRFW.outfit.TYPE = 4                               -- equip slot / row type of the costume
  VRFW.outfit.P_LIST_TABS = 363718978                -- list param: costume tab (retail flag6)
  VRFW.outfit.CARD_LOOK = @crc:CMND_VRFW_CARD_LOOK@
  VRFW.outfit.TEXT_LOOK_ON = @crc:vrfw_card_look_on@   -- menu_text "{label}: Activada"
  VRFW.outfit.TEXT_LOOK_OFF = @crc:vrfw_card_look_off@ -- menu_text "{label}: Desactivada"
  VRFW.outfit.TEXT_LOOK_NAME = @crc:vrfw_card_look_name@ -- menu_text: the label of a rule without one
  VRFW.outfit.ATTR_SET = 1525180681                  -- (hdl, attribute bit, set)
  VRFW.outfit.SOUND = @crc:CMND_SND_PLAY_SE@                     -- (sound)
  VRFW.outfit.SOUND_ON = 4235359837                  -- sy0010
  VRFW.outfit.SOUND_OFF = 2339718859                 -- sy0011
  VRFW.outfit.SOUND_REFUSED = 2086672038             -- sy0003
  VRFW.outfit.FN_EYE = 1141890006                    -- the eye-toggle key (CMD_FUNC4)
  VRFW.outfit.FOCUSED = 2603265800                   -- (layer) -> focused instance
  VRFW.outfit.CHANGE_GROUP = @crc:CMND_ON_CHANGE_LAYER_GROUP@              -- (group)
  VRFW.outfit.G_LIST = 530161788                     -- layer group equip_menu_list
  VRFW.outfit.L_STATUS = 2917320188                  -- soccer11_05_equip_status_base (the 3D preview)
  VRFW.outfit.SET_COUNT = 3252599449                 -- (layer, instance count)
  VRFW.outfit.SET_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@                -- (layer, instance, visible)
  VRFW.outfit.SET_BONE = 2158717427                  -- (layer, bone, visible, instance)
  VRFW.outfit.SET_FONT = 2333948100                  -- (layer, instance, text name, font style)
  VRFW.outfit.SET_SKIN = 558735651                   -- (layer, texture file, sprite, slot, 0, instance)
  VRFW.outfit.SET_MESH = @crc:CMND_SET_MESH_VISIBLE@                  -- (layer, mesh, visible, instance)
  VRFW.outfit.P_FLAG5 = 2029825652                   -- list param: flag5
  VRFW.outfit.P_CHARA = 1038144478                   -- the player the opener passes (read by the chara card)
  VRFW.outfit.ROW_INSTANCES = 5                      -- instances of the row layer
  VRFW.outfit.GLYPH_X = 289161319                    -- button guide glyph of CMD_FUNC4 (X)
  VRFW.outfit.CMD_X = 1435897304                     -- CMD_FUNC4: what a click on the guide entry sends
  VRFW.outfit.on = false                             -- this screen shows the "Atuendo" row
  VRFW.outfit.look_row = false                        -- row type 4 shows the player's card look switch
  VRFW.outfit.want = nil
  VRFW.outfit.shown = 0

  function VRFW.outfit.log(...)
    VRFW.outfit.logger = VRFW.outfit.logger or VRFW.logger.new("outfit")
    VRFW.outfit.logger(...)
  end

  -- declared outfits (0 = none, or a framework without outfits)
  function VRFW.outfit.count()
    local c = VRFW.host.command(VRFW.outfit.COUNT)
    if type(c) == "number" then
      return c
    end
    return 0
  end

  -- The declared outfit a player wears.
  function VRFW.outfit.of(h)
    if type(h) ~= "number" or h == 0 then
      return 0, 0
    end
    local item, u = VRFW.host.command(VRFW.outfit.OF, h)
    if type(item) ~= "number" or type(u) ~= "number" then
      return 0, 0
    end
    return item, u
  end

  -- The card look of a player.
  function VRFW.outfit.look(h)
    if type(h) ~= "number" or h == 0 then
      return 0, -1, 0, 0
    end
    local u, st, bit, label, set_means_on = VRFW.host.command(VRFW.outfit.CARD_LOOK, h)
    if type(u) ~= "number" or type(st) ~= "number" then
      return 0, -1, 0, 0
    end
    return u, st, type(bit) == "number" and bit or 0, type(label) == "number" and label or 0, set_means_on == true
  end

  -- the player has a card look he can switch (outside the story)
  function VRFW.outfit.switchable(h)
    if flag6 then
      return false
    end
    local u, st, bit = VRFW.outfit.look(h)
    return u ~= 0 and bit ~= 0 and (st == 0 or st == 1)
  end

  function VRFW.outfit.player()
    if type(VRFW.outfit.want) == "number" then
      return VRFW.outfit.want
    end
    if VRFW.param.has(VRFW.outfit.P_CHARA) then
      return VRFW.param.get(VRFW.outfit.P_CHARA) or 0
    end
    return type(n) == "number" and n or 0
  end

  function VRFW.outfit.text(id)
    local s = VRFW.host.command(VRFW.outfit.TEXT_GET, id)
    if type(s) == "string" then
      return s
    end
    return ""
  end

  function VRFW.outfit.look_text(h)
    local _, st, _, label = VRFW.outfit.look(h)
    local name = label ~= 0 and VRFW.outfit.text(label) or ""
    if name == "" then
      name = VRFW.outfit.text(VRFW.outfit.TEXT_LOOK_NAME)
    end
    local text = VRFW.outfit.text(st == 1 and VRFW.outfit.TEXT_LOOK_ON or VRFW.outfit.TEXT_LOOK_OFF)
    local a, b = string.find(text, "{label}", 1, true)
    if a then
      text = string.sub(text, 1, a - 1) .. name .. string.sub(text, b + 1)
    end
    return text
  end

  -- the row instance that shows type 4 (-1 = none)
  function VRFW.outfit.row_index()
    for i = 0, GetEquipTypeNum() - 1 do
      if GetEquipType(i) == VRFW.outfit.TYPE then
        return i
      end
    end
    return -1
  end

  -- Switch the shown player's card look.
  function VRFW.outfit.look_toggle()
    local u, st, bit, _, set_means_on = VRFW.outfit.look(n)
    if u == 0 or bit == 0 or (st ~= 0 and st ~= 1) then
      funcLuaCommand(VRFW.outfit.SOUND, VRFW.outfit.SOUND_REFUSED)
      VRFW.outfit.log("look refused", n, st)
      return false
    end
    local off = st == 1
    funcLuaCommand(VRFW.outfit.ATTR_SET, n, bit, off ~= set_means_on)
    funcLuaCommand(VRFW.outfit.SOUND, off and VRFW.outfit.SOUND_OFF or VRFW.outfit.SOUND_ON)
    local _, now = VRFW.outfit.look(n)
    VRFW.outfit.log("look", n, u, off and "OFF" or "ON", now)
    local row = VRFW.outfit.row_index()
    if row >= 0 then
      UpdateEquipListItem(row)
    end
    SetupCharaModel(VRFW.outfit.L_STATUS, 0)
    return true
  end

  -- The uniform of the 3D preview (called from the patched SetupCharaModel).
  function VRFW.outfit.preview_uniform(h, uniform, flags, story)
    VRFW.outfit.shown = 0
    if story then
      return uniform
    end
    if VRFW.outfit.on then
      local item, u = VRFW.outfit.of(h)
      VRFW.outfit.shown = item
      if item ~= 0 and u ~= 0 and flags ~= 16 and flags ~= 32 then
        return u
      end
    end
    if flags == 16 or flags == 32 then
      return uniform
    end
    local lu, st = VRFW.outfit.look(h)
    if st == 1 and lu ~= 0 then
      return lu
    end
    return uniform
  end

  function VRFW.outfit.list_params()
    VRFW.param.clear(VRFW.outfit.P_FLAG5)
    VRFW.param.set(VRFW.outfit.P_FLAG5, flag5, "plain")
    VRFW.param.clear(VRFW.outfit.P_LIST_TABS)
    VRFW.param.set(VRFW.outfit.P_LIST_TABS, flag6 or VRFW.outfit.on, "plain")
  end

  function VRFW.outfit.row_bones(i)
    local info = GetEquipListItemInfo(GetEquipType(i))
    for k = 1, #t2 do
      funcLuaMenuCommand(VRFW.outfit.SET_BONE, VRFW.outfit.L_ROW, t2[k], t2[k] == info.enableBoneName, i)
    end
  end

  function VRFW.outfit.row_look(i)
    local info = GetEquipListItemInfo(VRFW.outfit.TYPE)
    VRFW.outfit.row_bones(i)
    funcLuaMenuCommand(VRFW.outfit.SET_FONT, VRFW.outfit.L_ROW, i, info.itemTextName, info.fontStyle)
    funcLuaMenuCommand(VRFW.outfit.SET_SKIN, VRFW.outfit.L_ROW, 1676671618, 3264784393, 1536293299, 0, i)
    funcLuaMenuCommand(VRFW.outfit.SET_SKIN, VRFW.outfit.L_ROW, 1676671618, 1558763435, 3319891473, 0, i)
  end

  if VRFW.outfit.prev_create_equip_type_table == nil then
    VRFW.outfit.prev_create_equip_type_table = CreateEquipTypeTable
    VRFW.outfit.prev_on_enter = OnEnter
    VRFW.outfit.prev_update_equip_list_item = UpdateEquipListItem
    VRFW.outfit.prev_check_model = CheckEquipmentModelUpdateNeeded
    VRFW.outfit.prev_change_chara = ChangeChara
    VRFW.outfit.prev_on_decide_focus = OnDecideFocus
    VRFW.outfit.prev_on_function = OnFunction
  end

  function CreateEquipTypeTable()
    VRFW.outfit.prev_create_equip_type_table()
    VRFW.outfit.on = false
    VRFW.outfit.look_row = false
    if flag6 then
      return
    end
    local cnt = VRFW.outfit.count()
    if cnt > 0 then
      VRFW.outfit.on = true
    elseif VRFW.outfit.switchable(VRFW.outfit.player()) then
      VRFW.outfit.look_row = true
    else
      return
    end
    for i = 1, #t do
      if t[i] == VRFW.outfit.TYPE then
        return
      end
    end
    t[#t + 1] = VRFW.outfit.TYPE
    VRFW.outfit.log("row", cnt)
  end

  -- The row layer's list parameters (retail sets the same two there).
  function OnEnter(a1, a2)
    if a1 == VRFW.outfit.L_ROW then
      VRFW.outfit.list_params()
      return
    end
    return VRFW.outfit.prev_on_enter(a1, a2)
  end

  function OnDecideFocus(a1, a2)
    if a1 ~= VRFW.outfit.L_ROW then
      return VRFW.outfit.prev_on_decide_focus(a1, a2)
    end
    if VRFW.outfit.look_row and not flag6 and GetEquipType(a2) == VRFW.outfit.TYPE then
      VRFW.outfit.look_toggle()
      return
    end
    local r = VRFW.outfit.prev_on_decide_focus(a1, a2)
    VRFW.outfit.list_params()
    funcLuaMenuCommand(VRFW.outfit.CHANGE_GROUP, VRFW.outfit.G_LIST)
    return r
  end

  -- the eye key on row type 4 switches the card look outside the story (retail uses the key only with flag6)
  function OnFunction(a1, a2)
    if a1 == VRFW.outfit.FN_EYE and not flag6 then
      local row = funcLuaMenuCommand(VRFW.outfit.FOCUSED, VRFW.outfit.L_ROW)
      if type(row) == "number" and GetEquipType(row) == VRFW.outfit.TYPE and VRFW.outfit.switchable(n) then
        VRFW.outfit.look_toggle()
      end
      return
    end
    return VRFW.outfit.prev_on_function(a1, a2)
  end

  -- L / R to another player
  function ChangeChara(a1)
    if not flag6 and not VRFW.outfit.on then
      local was = VRFW.outfit.look_row
      VRFW.outfit.want = t4[a1 + 1] or 0
      CreateEquipTypeTable()
      VRFW.outfit.want = nil
      if was ~= VRFW.outfit.look_row then
        local num = GetEquipTypeNum()
        funcLuaMenuCommand(VRFW.outfit.SET_COUNT, VRFW.outfit.L_ROW, num)
        for i = 0, num - 1 do
          if GetEquipType(i) == VRFW.outfit.TYPE then
            VRFW.outfit.row_look(i)
          else
            VRFW.outfit.row_bones(i)
          end
          funcLuaMenuCommand(VRFW.outfit.SET_VISIBLE, VRFW.outfit.L_ROW, i, true)
        end
        for i = num, VRFW.outfit.ROW_INSTANCES - 1 do
          funcLuaMenuCommand(VRFW.outfit.SET_VISIBLE, VRFW.outfit.L_ROW, i, false)
        end
      end
    end
    return VRFW.outfit.prev_change_chara(a1)
  end

  -- An empty "Atuendo" row says what it is (the retail type-4 row has no category label).
  function UpdateEquipListItem(a1)
    local r = VRFW.outfit.prev_update_equip_list_item(a1)
    if flag6 or GetEquipType(a1) ~= VRFW.outfit.TYPE then
      return r
    end
    local info = GetEquipListItemInfo(VRFW.outfit.TYPE)
    if VRFW.outfit.look_row then
      funcLuaMenuCommand(VRFW.outfit.SET_TEXT, VRFW.outfit.L_ROW, info.itemTextName, VRFW.outfit.look_text(n), a1)
      if info.itemIconMeshName ~= nil then
        funcLuaMenuCommand(VRFW.outfit.SET_MESH, VRFW.outfit.L_ROW, info.itemIconMeshName, false, a1)
      end
      VRFW.host.menu_command(VRFW.outfit.TEXT_ALPHA, VRFW.outfit.L_ROW, a1, info.itemTextName, 1)
      return r
    end
    if not VRFW.outfit.on then
      return r
    end
    local empty = GetEquipItemIdByLayerIdx(a1) == 0
    if empty then
      local _, st, bit = VRFW.outfit.look(n)
      local id = (bit ~= 0 and st == 1) and VRFW.outfit.TEXT_SLOT_LOOK or VRFW.outfit.TEXT_SLOT
      local s = VRFW.host.command(VRFW.outfit.TEXT_GET, id)
      if type(s) == "string" and s ~= "" then
        funcLuaMenuCommand(VRFW.outfit.SET_TEXT, VRFW.outfit.L_ROW, info.itemTextName, s, a1)
      end
    end
    VRFW.host.menu_command(VRFW.outfit.TEXT_ALPHA, VRFW.outfit.L_ROW, a1, info.itemTextName, 1)
    return r
  end

  -- Back from the item list / quick remove.
  function CheckEquipmentModelUpdateNeeded(a1, a2)
    local r = VRFW.outfit.prev_check_model(a1, a2)
    if r or flag6 or not VRFW.outfit.on then
      return r
    end
    local item = VRFW.outfit.of(n)
    return item ~= VRFW.outfit.shown
  end
  function VRFW.outfit.guide_shown(entry)
    if flag6 or type(n) ~= "number" or n == 0 then
      return false
    end
    local row = funcLuaMenuCommand(VRFW.outfit.FOCUSED, VRFW.outfit.L_ROW)
    if type(row) ~= "number" or row < 0 or GetEquipType(row) ~= VRFW.outfit.TYPE then
      return false
    end
    local u, st, bit, label = VRFW.outfit.look(n)
    if u == 0 or bit == 0 or (st ~= 0 and st ~= 1) then
      return false
    end
    entry.text = label ~= 0 and label or VRFW.outfit.TEXT_LOOK_NAME
    return true
  end

  if VRFW.footer_prompts ~= nil and VRFW.outfit.guide_entry == nil then
    local entry = {
      name = "VRFW.CardLookSwitch",
      menu = "equip_menu_select",
      text = VRFW.outfit.TEXT_LOOK_NAME,
      icon = VRFW.outfit.GLYPH_X,
      command = VRFW.outfit.CMD_X,
      order = 50,
    }
    entry.when = function()
      return VRFW.outfit.guide_shown(entry)
    end
    VRFW.outfit.guide_entry = entry
    VRFW.footer_prompts.add(entry)
    VRFW.footer_prompts.attach("equip_menu_select", "UpdateEquipButtonGuide")
  end
end
-- ===== VRFW outfit_select END =====
