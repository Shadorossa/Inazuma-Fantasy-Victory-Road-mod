-- ===== VRFW item_xform_select BEGIN ===== (research/grafts/vrfw_item_xform) Equipment screen
do
  VRFW.item_transform = VRFW.item_transform or {}
  VRFW.item_transform.STATE = @crc:CMND_VRFW_ITEM_XFORM_STATE@
  VRFW.item_transform.L_MODEL = 2917320188               -- soccer11_05_equip_status_base (3D preview)
  VRFW.item_transform.G_SELECT = 802408180               -- layer group equip_menu_select (back from the item list)
  VRFW.item_transform.mdl_h, VRFW.item_transform.mdl_t = 0, -1        -- player / target of the last model build
  VRFW.item_transform.card_h, VRFW.item_transform.card_t = 0, -1      -- player / target of the last card setup

  -- transformation target chara id of a card (0 = none), nil = no answer (no loader / module off)
  function VRFW.item_transform.target(h)
    if type(h) ~= "number" or h == 0 then
      return nil
    end
    local item, target = VRFW.host.command(VRFW.item_transform.STATE, h)
    if type(target) ~= "number" then
      return nil
    end
    return target
  end

  function VRFW.item_transform.s_log(...)
    VRFW.item_transform.logger = VRFW.item_transform.logger or VRFW.logger.new("item_xform")
    VRFW.item_transform.logger(...)
  end

  function VRFW.item_transform.refresh(why)
    local h = n
    local tg = VRFW.item_transform.target(h)
    if tg == nil then
      return
    end
    local model = VRFW.item_transform.mdl_h ~= h or VRFW.item_transform.mdl_t ~= tg
    local card = VRFW.item_transform.card_h ~= h or VRFW.item_transform.card_t ~= tg
    if not model and not card then
      return
    end
    VRFW.item_transform.s_log("refresh", why, string.format("%08X", h), string.format("%08X", tg), model and 1 or 0, card and 1 or 0)
    if model then
      SetupCharaModel(VRFW.item_transform.L_MODEL, 0)
    end
    if card then
      UpdateCharaCard()
    end
  end

  if VRFW.item_transform.prev_setup_chara_model == nil then
    VRFW.item_transform.prev_setup_chara_model = SetupCharaModel
    VRFW.item_transform.prev_update_chara_card = UpdateCharaCard
    VRFW.item_transform.prev_on_change_layer_group = OnChangeLayerGroup
    VRFW.item_transform.prev_update_equip_condition = UpdateEquipCondition
  end

  function SetupCharaModel(a1, a2)
    local r = VRFW.item_transform.prev_setup_chara_model(a1, a2)
    if a1 == VRFW.item_transform.L_MODEL then
      VRFW.item_transform.mdl_h, VRFW.item_transform.mdl_t = n, VRFW.item_transform.target(n) or -1
    end
    return r
  end

  function UpdateCharaCard()
    local r = VRFW.item_transform.prev_update_chara_card()
    VRFW.item_transform.card_h, VRFW.item_transform.card_t = n, VRFW.item_transform.target(n) or -1
    return r
  end

  -- back from the item list (equip / remove / swap there)
  function OnChangeLayerGroup(a1)
    local r = VRFW.item_transform.prev_on_change_layer_group(a1)
    if a1 == VRFW.item_transform.G_SELECT then
      VRFW.item_transform.refresh("list")
    end
    return r
  end

  -- quick remove on a row, optimal equip
  function UpdateEquipCondition(a1, a2)
    local r = VRFW.item_transform.prev_update_equip_condition(a1, a2)
    VRFW.item_transform.refresh("cond")
    return r
  end
end
-- ===== VRFW item_xform_select END =====
