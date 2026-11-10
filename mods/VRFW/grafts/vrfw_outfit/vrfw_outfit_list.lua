-- ===== VRFW outfit_list BEGIN ===== (research/grafts/vrfw_outfit) Item list of "Equipamiento" (equip_menu_list)
do
  VRFW.outfit = VRFW.outfit or {}
  VRFW.outfit.IS = @crc:CMND_VRFW_OUTFIT_IS@

  if VRFW.outfit.prev_caution == nil then
    VRFW.outfit.prev_caution = OpenFirstChangeCostumeCautionMessage
  end

  function OpenFirstChangeCostumeCautionMessage(a1)
    if type(a1) == "number" and a1 ~= 0 then
      local is = VRFW.host.command(VRFW.outfit.IS, a1)
      if is == true then
        return
      end
    end
    return VRFW.outfit.prev_caution(a1)
  end
end
-- ===== VRFW outfit_list END =====
