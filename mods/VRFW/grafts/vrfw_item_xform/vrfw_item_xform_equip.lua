-- ===== VRFW item_xform BEGIN ===== (research/grafts/vrfw_item_xform) Equipment list (equip_menu_list)
do
  VRFW.item_transform = VRFW.item_transform or {}
  VRFW.item_transform.CAN = @crc:CMND_VRFW_ITEM_XFORM_CAN@
  VRFW.item_transform.ITEM_OF_INV = 1730783731       -- (invHdl, 0) -> item id (retail CheckEnableEquip)
  VRFW.item_transform.ITEM_NAME = @crc:CMND_GET_ITEM_PARAM@         -- (itemId, 0) -> item name (retail UpdateItemEquipLine)
  VRFW.item_transform.TEXT_GET = @crc:CMND_TEXT_GET@          -- (textId) -> text
  VRFW.item_transform.SE = @crc:CMND_SND_PLAY_SE@
  VRFW.item_transform.SE_NG = 2086672038             -- sy0003
  VRFW.item_transform.DECIDE = 4067673008            -- OnFunction "equip"
  VRFW.item_transform.hdl = 0
  VRFW.item_transform.inv = 0

  function VRFW.item_transform.log(...)
    VRFW.item_transform.logger = VRFW.item_transform.logger or VRFW.logger.new("item_xform")
    VRFW.item_transform.logger(...)
  end

  -- The declaring mod's text for the refusal, {item} = the item's name.
  function VRFW.item_transform.text(textId, item)
    if type(textId) ~= "number" or textId == 0 then
      return nil
    end
    local s = VRFW.host.command(VRFW.item_transform.TEXT_GET, textId)
    if type(s) ~= "string" or s == "" then
      return nil
    end
    local name = VRFW.host.command(VRFW.item_transform.ITEM_NAME, item, 0)
    if type(name) ~= "string" then
      name = ""
    end
    return (string.gsub(s, "{item}", (string.gsub(name, "%%", "%%%%"))))
  end

  function VRFW.item_transform.refused()
    local h, inv = VRFW.item_transform.hdl, VRFW.item_transform.inv
    if type(h) ~= "number" or h == 0 or type(inv) ~= "number" or inv == 0 then
      return false
    end
    local item = VRFW.host.command(VRFW.item_transform.ITEM_OF_INV, inv, 0)
    if type(item) ~= "number" or item == 0 then
      return false
    end
    local ok, why, textId = VRFW.host.command(VRFW.item_transform.CAN, h, item)
    if ok ~= false or type(why) ~= "number" or why <= 0 then
      return false
    end
    VRFW.host.command(VRFW.item_transform.SE, VRFW.item_transform.SE_NG)
    VRFW.item_transform.log("refused", string.format("%08X", h), string.format("%08X", item), why)
    local s = VRFW.item_transform.text(textId, item)
    if s ~= nil then
      OpenGeneralWindow(s, true)
    end
    return true
  end

  if VRFW.item_transform.prev_set_start_menu == nil then
    VRFW.item_transform.prev_set_start_menu = SetStartMenu
    VRFW.item_transform.prev_update_item_equip_menu = UpdateItemEquipMenu
    VRFW.item_transform.prev_on_function = OnFunction
  end

  -- the player whose equipment is shown (retail n = a1)
  function SetStartMenu(a1, a2)
    VRFW.item_transform.hdl = a1 or 0
    VRFW.item_transform.inv = 0
    return VRFW.item_transform.prev_set_start_menu(a1, a2)
  end

  -- the focused inventory entry (retail n3 = a1)
  function UpdateItemEquipMenu(a1)
    VRFW.item_transform.inv = a1 or 0
    return VRFW.item_transform.prev_update_item_equip_menu(a1)
  end

  function OnFunction(a1, a2)
    if a1 == VRFW.item_transform.DECIDE and VRFW.item_transform.refused() then
      return
    end
    return VRFW.item_transform.prev_on_function(a1, a2)
  end
end
-- ===== VRFW item_xform END =====
