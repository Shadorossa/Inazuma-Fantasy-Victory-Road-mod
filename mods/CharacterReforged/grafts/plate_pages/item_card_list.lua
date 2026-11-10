-- ===== EVT plate_pages item card list BEGIN =====
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
CharacterReforged.item_card_list = CharacterReforged.item_card_list or {EVENT = "CharacterReforged.ItemCardHover", LOG = @crc:CMND_VRFW_LOG@,
  PAGE_EVENT = "CharacterReforged.ItemCardPage", CHECK_INPUT = @crc:CMND_CHECK_INPUT_CMD@,
  MENU_EXISTS = @crc:CMND_IS_EXIST_MENU@, POPUPS = {@crc:item_filter_menu@, @crc:sub_window@},
  CTRLS = {1332654303 --[[MENU_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]]},
  KEY_BACK = 1970176280 --[[CMD_FUNCL2]], KEY_FORWARD = 2704260807 --[[CMD_FUNCR2]]}

function CharacterReforged.item_card_list.tell(item)
  CharacterReforged.item_card_list.hover = item
  if type(VRFW.menu_event) == "table" then
    VRFW.menu_event.emit(CharacterReforged.item_card_list.EVENT, item)
  end
  if item ~= CharacterReforged.item_card_list.last then
    CharacterReforged.item_card_list.last = item
    pcall(funcLuaCommand, CharacterReforged.item_card_list.LOG, "picker hover", tostring(item))
  end
end

function CharacterReforged.item_card_list.pressed(key)
  for _, ctrl in ipairs(CharacterReforged.item_card_list.CTRLS) do
    local ok, hit = pcall(funcLuaCommand, CharacterReforged.item_card_list.CHECK_INPUT, ctrl, key)
    if ok and hit == true then
      return true
    end
  end
  return false
end

-- the frame's L2 / R2 while an item is hovered, unless one of the picker's windows is over it
function CharacterReforged.item_card_list.page_input()
  if CharacterReforged.item_card_list.hover == nil or CharacterReforged.item_card_list.hover <= 0 then
    return
  end
  local dir = (CharacterReforged.item_card_list.pressed(CharacterReforged.item_card_list.KEY_BACK) and -1) or (CharacterReforged.item_card_list.pressed(CharacterReforged.item_card_list.KEY_FORWARD) and 1) or 0
  if dir == 0 then
    return
  end
  for _, menu in ipairs(CharacterReforged.item_card_list.POPUPS) do
    local ok, open = pcall(funcLuaCommand, CharacterReforged.item_card_list.MENU_EXISTS, menu)
    if ok and open == true then
      return
    end
  end
  if type(VRFW.menu_event) == "table" then
    VRFW.menu_event.emit(CharacterReforged.item_card_list.PAGE_EVENT, dir)
  end
end

if not CharacterReforged.item_card_list.wrapped then
  CharacterReforged.item_card_list.wrapped = true
  if type(PreStep) == "function" then
    local ItemCardListPreStep = PreStep
    function PreStep(...)
      local r = table.pack(ItemCardListPreStep(...))
      CharacterReforged.item_card_list.page_input()
      return table.unpack(r, 1, r.n)
    end
  end
  if type(SetupEquipInfoWindow) == "function" then
    local ItemCardListSetup = SetupEquipInfoWindow
    function SetupEquipInfoWindow(item, ...)
      local r = table.pack(ItemCardListSetup(item, ...))
      CharacterReforged.item_card_list.tell(type(item) == "number" and item or 0)
      return table.unpack(r, 1, r.n)
    end
  end
  if type(EquipItem) == "function" then
    local ItemCardListEquip = EquipItem
    function EquipItem(...)
      local r = table.pack(ItemCardListEquip(...))
      if type(r[1]) == "boolean" and CharacterReforged.item_card_list.hover ~= nil and CharacterReforged.item_card_list.hover > 0 then
        CharacterReforged.item_card_list.tell(CharacterReforged.item_card_list.hover)
      end
      return table.unpack(r, 1, r.n)
    end
  end
  if type(SetVisibleEquipInfoWindow) == "function" then
    local ItemCardListVisible = SetVisibleEquipInfoWindow
    function SetVisibleEquipInfoWindow(on, ...)
      local r = table.pack(ItemCardListVisible(on, ...))
      if on ~= true then
        CharacterReforged.item_card_list.tell(0)
      end
      return table.unpack(r, 1, r.n)
    end
  end
  if type(OnBack) == "function" then
    local ItemCardListBack = OnBack
    function OnBack(...)
      local r = table.pack(ItemCardListBack(...))
      CharacterReforged.item_card_list.tell(-1)
      CharacterReforged.item_card_list.last = nil
      return table.unpack(r, 1, r.n)
    end
  end
end
-- ===== EVT plate_pages item card list END =====
