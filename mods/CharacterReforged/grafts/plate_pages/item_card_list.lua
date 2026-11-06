-- ===== EVT plate_pages item card list BEGIN =====
-- Character Reforged (graft plate_pages): the item picker (equip_menu_list, a layer group of the equipment menu with its
-- own script) hands the hovered item to the equipment screen's script (equip_menu_select, plate_pages G.ItemCardShow,
-- which draws the card and the stats panel's rows): after the game fills the card for the hovered item
-- (SetupEquipInfoWindow) it sends the item as the menu event CharacterReforged.ItemCardHover (VRFW_MenuEvent; 0 =
-- nothing hovered: the card hidden; -1 = the picker left: the slot's own item again), which the equipment screen's
-- script handles at once; again after an equip / remove with the cursor still on the item, which changes what it would
-- replace. (A cross-menu call reaches a menu, not one of its scripts.)
-- Wrappers only; nothing runs at load time. loader.log «picker hover <item>» once per hovered item.
-- While the picker is up its PreStep also reads L2 / R2 (the card's pages) and sends the turn as the menu event
-- CharacterReforged.ItemCardPage.
EVT_ICL = EVT_ICL or {EVENT = "CharacterReforged.ItemCardHover", LOG = @crc:CMND_EVT_LOG@,
  PAGE_EVENT = "CharacterReforged.ItemCardPage", CHECK_INPUT = @crc:CMND_CHECK_INPUT_CMD@,
  MENU_EXISTS = @crc:CMND_IS_EXIST_MENU@, POPUPS = {@crc:item_filter_menu@, @crc:sub_window@},
  CTRLS = {1332654303 --[[MENU_CTRL]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]]},
  KEY_BACK = 1970176280 --[[CMD_FUNCL2]], KEY_FORWARD = 2704260807 --[[CMD_FUNCR2]]}

function EVT_ICL.Tell(item)
  EVT_ICL.hover = item
  if type(VRFW_MenuEvent) == "table" then
    VRFW_MenuEvent.Emit(EVT_ICL.EVENT, item)
  end
  if item ~= EVT_ICL.last then
    EVT_ICL.last = item
    pcall(funcLuaCommand, EVT_ICL.LOG, "picker hover", tostring(item))
  end
end

function EVT_ICL.Pressed(key)
  for _, ctrl in ipairs(EVT_ICL.CTRLS) do
    local ok, hit = pcall(funcLuaCommand, EVT_ICL.CHECK_INPUT, ctrl, key)
    if ok and hit == true then
      return true
    end
  end
  return false
end

-- the frame's L2 / R2 while an item is hovered, unless one of the picker's windows is over it
function EVT_ICL.PageInput()
  if EVT_ICL.hover == nil or EVT_ICL.hover <= 0 then
    return
  end
  local dir = (EVT_ICL.Pressed(EVT_ICL.KEY_BACK) and -1) or (EVT_ICL.Pressed(EVT_ICL.KEY_FORWARD) and 1) or 0
  if dir == 0 then
    return
  end
  for _, menu in ipairs(EVT_ICL.POPUPS) do
    local ok, open = pcall(funcLuaCommand, EVT_ICL.MENU_EXISTS, menu)
    if ok and open == true then
      return
    end
  end
  if type(VRFW_MenuEvent) == "table" then
    VRFW_MenuEvent.Emit(EVT_ICL.PAGE_EVENT, dir)
  end
end

if not EVT_ICL.wrapped then
  EVT_ICL.wrapped = true
  if type(PreStep) == "function" then
    local EVT_ICL_PreStep = PreStep
    function PreStep(...)
      local r = table.pack(EVT_ICL_PreStep(...))
      EVT_ICL.PageInput()
      return table.unpack(r, 1, r.n)
    end
  end
  if type(SetupEquipInfoWindow) == "function" then
    local EVT_ICL_Setup = SetupEquipInfoWindow
    function SetupEquipInfoWindow(item, ...)
      local r = table.pack(EVT_ICL_Setup(item, ...))
      EVT_ICL.Tell(type(item) == "number" and item or 0)
      return table.unpack(r, 1, r.n)
    end
  end
  if type(EquipItem) == "function" then
    local EVT_ICL_Equip = EquipItem
    function EquipItem(...)
      local r = table.pack(EVT_ICL_Equip(...))
      if type(r[1]) == "boolean" and EVT_ICL.hover ~= nil and EVT_ICL.hover > 0 then
        EVT_ICL.Tell(EVT_ICL.hover)
      end
      return table.unpack(r, 1, r.n)
    end
  end
  if type(SetVisibleEquipInfoWindow) == "function" then
    local EVT_ICL_Visible = SetVisibleEquipInfoWindow
    function SetVisibleEquipInfoWindow(on, ...)
      local r = table.pack(EVT_ICL_Visible(on, ...))
      if on ~= true then
        EVT_ICL.Tell(0)
      end
      return table.unpack(r, 1, r.n)
    end
  end
  if type(OnBack) == "function" then
    local EVT_ICL_Back = OnBack
    function OnBack(...)
      local r = table.pack(EVT_ICL_Back(...))
      EVT_ICL.Tell(-1)
      EVT_ICL.last = nil
      return table.unpack(r, 1, r.n)
    end
  end
end
-- ===== EVT plate_pages item card list END =====
