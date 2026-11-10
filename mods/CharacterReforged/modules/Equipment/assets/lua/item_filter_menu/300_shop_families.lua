if VRFW.host ~= nil and VRFW.param ~= nil and type(GetInventoryTypeArray) == "function" then
  local KEY_RECEIVER = 2640949932   -- Param store: the menu the window sends its params to.
  local SHOP_MENU = 3170360552      -- shop_menu
  local ROW_TYPE = 1                -- list item type of the rows
  local ALL_TYPE = 8                -- list item type "all rows of a tab" (value = the rows' type)
  local STAT_TYPE = 2               -- list item type of the retail stat tab
  local TAB_INDEX = 1               -- the added tab's index in the window's tab list
  local TAB_ICON_TYPE = 1001
  local TAB_TEXT_KEY = "Equipment.filter_tab_families"
  local TAB_ICON = "icon_list_tab_filter05"
  local TAB_SYMBOL = "filter_symbol05"
  local TAB_ICONS = 1333035005      -- the tab icon atlas (icon_list_tab_filter.g4tx)
  local TAB_DUMMY_ON = 3229351341   -- `icon_list_tab_dmy01_on`
  local TAB_DUMMY_OFF = 380437824   -- icon_list_tab_dmy01_off
  local SET_SPRITE = 558735651
  local ROW_NAME = 1704438437       -- _text_name01 (the row's label)
  local LAST_EQUIPMENT_INVENTORY = 3

  local S = { on = false, labels = {} }

  local function open()
    S.on, S.labels = false, {}
    local from_shop = VRFW.param.has(KEY_RECEIVER) and VRFW.param.get(KEY_RECEIVER) == SHOP_MENU
    local items = {}
    if from_shop then
      local listed = table.pack(VRFW.host.command(VRFW.commands.BETTERQOL_SHOP_NAME_ITEMS))
      if type(listed[1]) == "number" then
        for i = 1, listed[1] do items[i] = listed[1 + i] end
      end
    end
    local r = table.pack(VRFW.host.command(VRFW.commands.EQUIPMENT_SHOP_FAMILIES, table.unpack(items)))
    local n = type(r[1]) == "number" and r[1] or 0
    if n <= 0 then
      if from_shop then VRFW.host.command(VRFW.commands.BETTERQOL_SHOP_FILTER_ROWS) end
      return
    end
    for i = 1, n do
      S.labels[r[2 * i]] = r[1 + 2 * i]
    end
    VRFW.host.command(VRFW.commands.BETTERQOL_SHOP_FILTER_ROWS, table.unpack(r, 2 + 2 * n, r.n))
    S.on = true
  end

  VRFW.host.on("item_filter_menu", "OnInit", { id = "Equipment.shop_families_open", phase = "before", fn = open })

  VRFW.host.on("item_filter_menu", "FinalizeMenu", { id = "Equipment.shop_families_close", phase = "before", fn = function()
    if S.on then
      S.on = false
      VRFW.host.command(VRFW.commands.EQUIPMENT_SHOP_FAMILIES)
    end
  end })

  VRFW.host.on("item_filter_menu", "SetupFilterGroupInfoArray", { id = "Equipment.shop_families_tab", phase = "after", fn = function()
    local host = VRFW.host.hosts and VRFW.host.hosts.item_filter_menu
    local tabs = host and host.L and host.L.t10
    local entry = S.on and type(tabs) == "table" and tabs[TAB_INDEX + 1] or nil
    if type(entry) ~= "table" then return end
    entry.tabIconType = TAB_ICON_TYPE
    entry.bgIconTextureName = VRFW.crc32(TAB_SYMBOL)
    local id = VRFW.host.command(VRFW.commands.VRFW_TEXT_ID, TAB_TEXT_KEY)
    if type(id) == "number" and id ~= 0 then entry.tabTextName = id end
  end })

  VRFW.host.on("item_filter_menu", "SetTabIcon", { id = "Equipment.shop_families_icon", phase = "after", fn = function(r, layer, item, icon_type)
    if icon_type ~= TAB_ICON_TYPE then return end
    funcLuaMenuCommand(SET_SPRITE, layer, TAB_ICONS, VRFW.crc32(TAB_ICON), TAB_DUMMY_ON, 0, item)
    funcLuaMenuCommand(SET_SPRITE, layer, TAB_ICONS, VRFW.crc32(TAB_ICON .. "_off"), TAB_DUMMY_OFF, 0, item)
  end })

  VRFW.host.on("item_filter_menu", "UpdateItem", { id = "Equipment.shop_families_row", phase = "around", fn = function(nxt, layer, item, list_type, value, option, ...)
    if not S.on or list_type ~= ROW_TYPE then return nxt(layer, item, list_type, value, option, ...) end
    funcLuaMenuCommand(VRFW.commands.SET_MENU_TEXT_STRING, layer, ROW_NAME, S.labels[value] or "", item)
    UpdateCheckBox(layer, item, list_type, value, option)
  end })

  VRFW.host.on("item_filter_menu", "OnAfterReceiveFilterParam", { id = "Equipment.shop_families_default", phase = "before", fn = function()
    if S.on and GetFilterParamNum(ROW_TYPE, 0) == 0 and GetFilterParamArrayIdx(ALL_TYPE, ROW_TYPE, 0) == 0 then
      AddFilterParam(ALL_TYPE, ROW_TYPE, 0)
    end
  end })

  local game_types = GetInventoryTypeArray
  function GetInventoryTypeArray(inventory, ...)
    if S.on and type(inventory) == "number" and inventory <= LAST_EQUIPMENT_INVENTORY then
      return { STAT_TYPE, ROW_TYPE }
    end
    return game_types(inventory, ...)
  end
end
