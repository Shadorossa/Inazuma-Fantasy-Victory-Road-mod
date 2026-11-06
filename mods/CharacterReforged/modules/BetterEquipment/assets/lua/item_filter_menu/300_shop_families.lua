-- Better Equipment › the «Family» tab of the shop's filter window (item_filter_menu opened by BetterQoL's shop filter).
-- In an equipment tab of a shop the window gets a second tab with one row per set ([[VRFW.EquipmentSet]]) that has an
-- item in that shop tab. The rows are the game's series group (list item type 1, text rows, «All» = type 8 value 1);
-- the row value is the set's number, the label comes from the set's text key. The script writes the rows the native
-- builder lists (content\game\better_equipment.toml, scripts\better_equipment.lua); BetterQoL's shop filter applies them
-- (CMND_BETTERQOL_SHOP_FILTER_ROWS). Windows not opened from a shop keep the single retail tab. No engine call at load time.
if VRFW_Host ~= nil and VRFW_Param ~= nil and type(GetInventoryTypeArray) == "function" then
  local KEY_RECEIVER = 2640949932   -- param store: the menu the window sends its params to
  local SHOP_MENU = 3170360552      -- shop_menu
  local ROW_TYPE = 1                -- list item type of the rows
  local ALL_TYPE = 8                -- list item type «all rows of a tab» (value = the rows' type)
  local STAT_TYPE = 2               -- list item type of the retail stat tab
  local TAB_INDEX = 1               -- the added tab's index in the window's tab list
  local TAB_ICON_TYPE = 1001        -- tabIconType of the added tab (above the game's 0..5 and the move family tab)
  local TAB_TEXT_KEY = "BetterEquipment.filter_tab_families"
  local TAB_ICON = "icon_list_tab_filter05"
  local TAB_SYMBOL = "filter_symbol05"
  local TAB_ICONS = 1333035005      -- the tab icon atlas (icon_list_tab_filter.g4tx)
  local TAB_DUMMY_ON = 3229351341   -- icon_list_tab_dmy01_on
  local TAB_DUMMY_OFF = 380437824   -- icon_list_tab_dmy01_off
  local SET_SPRITE = 558735651      -- the game's sprite swap (layer, texture file, sprite, dummy sprite, 0, item)
  local ROW_NAME = 1704438437       -- _text_name01 (the row's label)
  local LAST_EQUIPMENT_INVENTORY = 3

  local S = { on = false, labels = {} }

  -- the window opens: from a shop, the rows of the shop tab built last; else the single retail tab
  local function open()
    S.on, S.labels = false, {}
    local from_shop = VRFW_Param.Has(KEY_RECEIVER) and VRFW_Param.Get(KEY_RECEIVER) == SHOP_MENU
    local items = {}
    if from_shop then
      local listed = table.pack(pcall(funcLuaCommand, VRFW_Cmd.BETTERQOL_SHOP_NAME_ITEMS))
      if listed[1] and type(listed[2]) == "number" then
        for i = 1, listed[2] do items[i] = listed[2 + i] end
      end
    end
    local r = table.pack(pcall(funcLuaCommand, VRFW_Cmd.BETTEREQUIPMENT_SHOP_FAMILIES, table.unpack(items)))
    local n = r[1] and type(r[2]) == "number" and r[2] or 0
    if n <= 0 then
      if from_shop then pcall(funcLuaCommand, VRFW_Cmd.BETTERQOL_SHOP_FILTER_ROWS) end
      return
    end
    for i = 1, n do
      S.labels[r[1 + 2 * i]] = r[2 + 2 * i]
    end
    pcall(funcLuaCommand, VRFW_Cmd.BETTERQOL_SHOP_FILTER_ROWS, table.unpack(r, 3 + 2 * n, r.n))
    S.on = true
  end

  VRFW_Host.on("item_filter_menu", "OnInit", { id = "BetterEquipment.shop_families_open", phase = "before", fn = open })

  VRFW_Host.on("item_filter_menu", "FinalizeMenu", { id = "BetterEquipment.shop_families_close", phase = "before", fn = function()
    if S.on then
      S.on = false
      pcall(funcLuaCommand, VRFW_Cmd.BETTEREQUIPMENT_SHOP_FAMILIES)
    end
  end })

  -- the added tab's entry of the tab list: its name, icon type and background symbol
  VRFW_Host.on("item_filter_menu", "SetupFilterGroupInfoArray", { id = "BetterEquipment.shop_families_tab", phase = "after", fn = function()
    local host = VRFW_Host.hosts and VRFW_Host.hosts.item_filter_menu
    local tabs = host and host.L and host.L.t10
    local entry = S.on and type(tabs) == "table" and tabs[TAB_INDEX + 1] or nil
    if type(entry) ~= "table" then return end
    entry.tabIconType = TAB_ICON_TYPE
    entry.bgIconTextureName = VRFW_Crc32(TAB_SYMBOL)
    local ok, id = pcall(funcLuaCommand, VRFW_Cmd.VRFW_TEXT_ID, TAB_TEXT_KEY)
    if ok and type(id) == "number" and id ~= 0 then entry.tabTextName = id end
  end })

  VRFW_Host.on("item_filter_menu", "SetTabIcon", { id = "BetterEquipment.shop_families_icon", phase = "after", fn = function(r, layer, item, icon_type)
    if icon_type ~= TAB_ICON_TYPE then return end
    funcLuaMenuCommand(SET_SPRITE, layer, TAB_ICONS, VRFW_Crc32(TAB_ICON), TAB_DUMMY_ON, 0, item)
    funcLuaMenuCommand(SET_SPRITE, layer, TAB_ICONS, VRFW_Crc32(TAB_ICON .. "_off"), TAB_DUMMY_OFF, 0, item)
  end })

  -- a row: the set's name in place of the game's series name
  VRFW_Host.on("item_filter_menu", "UpdateItem", { id = "BetterEquipment.shop_families_row", phase = "around", fn = function(nxt, layer, item, list_type, value, option, ...)
    if not S.on or list_type ~= ROW_TYPE then return nxt(layer, item, list_type, value, option, ...) end
    funcLuaMenuCommand(VRFW_Cmd.SET_MENU_TEXT_STRING, layer, ROW_NAME, S.labels[value] or "", item)
    UpdateCheckBox(layer, item, list_type, value, option)
  end })

  -- a filter the shop kept without this tab's rows: «All» of the tab
  VRFW_Host.on("item_filter_menu", "OnAfterReceiveFilterParam", { id = "BetterEquipment.shop_families_default", phase = "before", fn = function()
    if S.on and GetFilterParamNum(ROW_TYPE, 0) == 0 and GetFilterParamArrayIdx(ALL_TYPE, ROW_TYPE, 0) == 0 then
      AddFilterParam(ALL_TYPE, ROW_TYPE, 0)
    end
  end })

  -- «Reset»: the added tab's «All» next to the stat tab's
  local game_types = GetInventoryTypeArray
  function GetInventoryTypeArray(inventory, ...)
    if S.on and type(inventory) == "number" and inventory <= LAST_EQUIPMENT_INVENTORY then
      return { STAT_TYPE, ROW_TYPE }
    end
    return game_types(inventory, ...)
  end
end
