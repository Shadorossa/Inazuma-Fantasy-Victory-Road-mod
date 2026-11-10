-- Item filter sections (docs/framework/item-filter-sections.md): the tabs a mod declares in the filter window of an
-- item list, and the list screen's side of them. Library VRFW.item_filter_sections.
if VRFW.item_filter_sections == nil and VRFW.host ~= nil then
  local IFS = {
    CMD_SECTIONS = VRFW.commands.VRFW_ITEM_FILTER_SECTIONS,
    CMD_TABS = VRFW.commands.VRFW_ITEM_FILTER_TABS,
    CMD_TAB_ROWS = VRFW.commands.VRFW_ITEM_FILTER_TAB_ROWS,
    TEXT_ID = VRFW.commands.VRFW_TEXT_ID,    -- CMND_VRFW_TEXT_ID(text key) -> text id
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    SAVE_FILTER = 3666261249,     -- CMND_SAVE_ITEM_FILTER(save id, n, params)
    SET_SPRITE = 558735651,
    TAB_ICONS = 1333035005,       -- the tab icon atlas (icon_list_tab_filter.g4tx)
    TAB_DUMMY_ON = 3229351341,    -- `icon_list_tab_dmy01_on`
    TAB_DUMMY_OFF = 380437824,    -- icon_list_tab_dmy01_off
    TAB_ICON_BASE = 1100,         -- tabIconType of added tab i = this + i (above the game's 0..5)
    ROW_NAME = 1704438437,        -- _text_name01 (the row's label)
    ROW_TYPE = 1,                 -- list item type of the rows (the series group's)
    ALL_TYPE = 8,                 -- list item type "all rows of a tab" (value = the rows' type)
    LAST_EQUIPMENT_INVENTORY = 3, -- inventory types 0..3 = the equipment lists
    VALUES_PER_CALL = 24,         -- row values one command call carries (a command takes 32 arguments at most)
    WINDOW = "item_filter_menu",
    character = 0,                -- This is the player the list screen is for.
    by_menu = {},                 -- [list menu id] = its sections
    list_menu = nil,              -- the list menu whose filter the mods hold
    window = nil,                 -- the open window: { menu, tabs = { { section, values, labels } } }
  }
  VRFW.item_filter_sections = IFS

  --- The sections of list menu `menu`: { { name, text, icon, icon_off, symbol, serve } }, asked once per screen.
  function IFS.sections(menu)
    local known = IFS.by_menu[menu]
    if known ~= nil then return known end
    local r = table.pack(VRFW.host.command(IFS.CMD_SECTIONS, menu))
    local list = {}
    for i = 1, type(r[1]) == "number" and r[1] or 0 do
      local at = 2 + (i - 1) * 6
      if type(r[at]) == "string" and type(r[at + 5]) == "string" then
        list[#list + 1] = { name = r[at], text = r[at + 1], icon = r[at + 2], icon_off = r[at + 3],
          symbol = r[at + 4], serve = VRFW.crc32(r[at + 5]) }
      end
    end
    IFS.by_menu[menu] = list
    return list
  end

  --- One request to each serve command of the sections of `menu`.
  function IFS.tell(menu, ...)
    local told = {}
    for _, section in ipairs(IFS.sections(menu)) do
      if not told[section.serve] then
        told[section.serve] = true
        VRFW.host.command(section.serve, ...)
      end
    end
  end

  --- Calls command(at, values...) once per VALUES_PER_CALL values, `at` = the place of the call's first value;
  --- false when a call does not answer true.
  function IFS.in_calls(values, command)
    for at = 1, math.max(#values, 1), IFS.VALUES_PER_CALL do
      local last = math.min(at + IFS.VALUES_PER_CALL - 1, #values)
      if command(at, table.unpack(values, at, last)) ~= true then return false end
    end
    return true
  end

  --- Tells the mods which rows of `params` are ticked in the sections of `menu`; scope "list" or "window".
  --- A section with every row or no row ticked does not filter: nothing is sent for it.
  function IFS.send(scope, menu, params)
    for i, section in ipairs(IFS.sections(menu)) do
      local values, all = {}, false
      for _, p in ipairs(params) do
        if type(p) == "table" and p.option == i then
          if p.listItemType == IFS.ROW_TYPE then
            values[#values + 1] = p.value
          elseif p.listItemType == IFS.ALL_TYPE and p.value == IFS.ROW_TYPE then
            all = true
          end
        end
      end
      if not all and #values > 0 then
        IFS.in_calls(values, function(_, ...)
          VRFW.host.command(section.serve, "tick", scope, section.name, ...)
          return true
        end)
      end
    end
    IFS.tell(menu, "apply", scope)
  end

  --- `params` without the sections' rows (the save's filter set has no place for them), and true when any was left out.
  function IFS.saved(params)
    local copy, dropped = {}, false
    for _, p in ipairs(params) do
      local own = type(p) == "table" and p.option ~= 0
        and (p.listItemType == IFS.ROW_TYPE or (p.listItemType == IFS.ALL_TYPE and p.value == IFS.ROW_TYPE))
      if own then dropped = true else copy[#copy + 1] = p end
    end
    return copy, dropped
  end

  --- True when a row of a section is ticked in `params`.
  function IFS.filters(params)
    for _, p in ipairs(params) do
      if type(p) == "table" and p.listItemType == IFS.ROW_TYPE and p.option ~= 0 then return true end
    end
    return false
  end

  --- List screen `stem` tells the mods its player and its filter; its saved filter keeps the game's rows only.
  function IFS.attach_list(stem)
    VRFW.host.wrap("SetStartMenu", function(game_start)
      return function(character, ...)
        IFS.character = type(character) == "number" and character or 0
        return game_start(character, ...)
      end
    end, { stem = stem, id = "VRFW.item_filter_sections_player" })
    VRFW.host.wrap("OpenFilter", function(game_open)
      return function(menu, ...)
        if type(menu) == "number" then IFS.tell(menu, "context", IFS.character) end
        return game_open(menu, ...)
      end
    end, { stem = stem, id = "VRFW.item_filter_sections_open" })
    VRFW.host.wrap("SetEquipListFilter", function(game_filter)
      return function(params, apply, menu, ...)
        if type(params) == "table" and type(menu) == "number" then
          IFS.list_menu = menu
          IFS.send("list", menu, params)
        end
        return game_filter(params, apply, menu, ...)
      end
    end, { stem = stem, id = "VRFW.item_filter_sections_apply" })
    VRFW.host.wrap("SaveFilterData", function(game_save)
      return function(save_id, ...)
        local copy, dropped = IFS.saved(GetFilterParamArray())
        if not dropped then return game_save(save_id, ...) end
        local send = CreateSendFilterParamArray(copy)
        VRFW.host.menu_command(IFS.SAVE_FILTER, save_id, #send, send)
      end
    end, { stem = stem, id = "VRFW.item_filter_sections_save" })
    VRFW.host.wrap("IsFilterEnabled", function(game_enabled)
      return function(...)
        return game_enabled(...) or IFS.filters(GetFilterParamArray())
      end
    end, { stem = stem, id = "VRFW.item_filter_sections_enabled" })
    VRFW.host.wrap("FinalizeMenu", function(game_finalize)
      return function(...)
        if IFS.list_menu ~= nil then
          IFS.send("list", IFS.list_menu, {})
          IFS.list_menu = nil
        end
        return game_finalize(...)
      end
    end, { stem = stem, id = "VRFW.item_filter_sections_close" })
  end

  -- The window script's own locals (the host patch of item_filter_menu), or nil.
  local function window_locals()
    local host = VRFW.host.hosts and VRFW.host.hosts[IFS.WINDOW]
    return host and host.L or nil
  end

  -- Every added tab without a ticked row gets its «all» param, as the game's tabs have by default.
  local function window_defaults()
    local w = IFS.window
    if w == nil then return end
    for i in ipairs(w.tabs) do
      if GetFilterParamNum(IFS.ROW_TYPE, i) == 0 and GetFilterParamArrayIdx(IFS.ALL_TYPE, IFS.ROW_TYPE, i) == 0 then
        AddFilterParam(IFS.ALL_TYPE, IFS.ROW_TYPE, i)
      end
    end
  end

  -- The window opens for a list menu with sections: one more tab per section, with the rows its mod answers.
  local function window_setup()
    IFS.window = nil
    local L = window_locals()
    local menu = L and L.n
    if type(menu) ~= "number" or menu == 0 then return end
    local inventory = GetInventoryType()
    if type(inventory) ~= "number" or inventory > IFS.LAST_EQUIPMENT_INVENTORY then return end
    local sections = IFS.sections(menu)
    if #sections == 0 then return end
    local tabs = {}
    for i, section in ipairs(sections) do
      local r = table.pack(VRFW.host.command(section.serve, "rows", section.name, inventory))
      local tab = { section = section, values = {}, labels = {} }
      for k = 1, type(r[1]) == "number" and r[1] or 0 do
        local value, label = r[2 * k], r[2 * k + 1]
        if type(value) == "number" then
          tab.values[#tab.values + 1] = value
          tab.labels[value] = tostring(label or "")
        end
      end
      tabs[i] = tab
    end
    if VRFW.host.command(IFS.CMD_TABS, #tabs) ~= true then return end
    for i, tab in ipairs(tabs) do
      local sent = IFS.in_calls(tab.values, function(at, ...)
        return VRFW.host.command(IFS.CMD_TAB_ROWS, i, at, ...)
      end)
      if not sent then
        VRFW.host.command(IFS.CMD_TABS, 0)
        return
      end
    end
    IFS.window = { menu = menu, tabs = tabs }
    window_defaults()
  end

  -- The tab list's entries of the added tabs: their icon type, name and background symbol.
  local function window_tab_entries()
    local w, L = IFS.window, window_locals()
    local entries = L and L.t10
    if w == nil or type(entries) ~= "table" then return end
    for i, tab in ipairs(w.tabs) do
      local entry = entries[i + 1]
      if type(entry) == "table" then
        entry.tabIconType = IFS.TAB_ICON_BASE + i
        if type(tab.section.symbol) == "number" then entry.bgIconTextureName = tab.section.symbol end
        local id = VRFW.host.command(IFS.TEXT_ID, tab.section.text)
        if type(id) == "number" and id ~= 0 then entry.tabTextName = id end
      end
    end
  end

  -- The added tab shown when `list_type` is its rows' type: its index, or nil.
  local function window_shown_tab(list_type)
    local w, L = IFS.window, window_locals()
    local shown = L and L.n2
    if w == nil or list_type ~= IFS.ROW_TYPE or w.tabs[shown] == nil then return nil end
    return shown
  end

  --- The filter window shows the sections of the list menu that opened it and tells the mods what is ticked.
  function IFS.attach_window()
    local stem = IFS.WINDOW
    VRFW.host.on(stem, "SetupFilterGroupInfoArray", { id = "VRFW.item_filter_sections_setup", phase = "before",
      fn = window_setup })
    VRFW.host.on(stem, "SetupFilterGroupInfoArray", { id = "VRFW.item_filter_sections_tabs", phase = "after",
      fn = window_tab_entries })
    VRFW.host.on(stem, "SetTabIcon", { id = "VRFW.item_filter_sections_icon", phase = "after",
      fn = function(_, layer, item, icon_type)
        local w = IFS.window
        local tab = w ~= nil and type(icon_type) == "number" and w.tabs[icon_type - IFS.TAB_ICON_BASE] or nil
        if tab == nil or type(tab.section.icon) ~= "number" or type(tab.section.icon_off) ~= "number" then return end
        VRFW.host.menu_command(IFS.SET_SPRITE, layer, IFS.TAB_ICONS, tab.section.icon, IFS.TAB_DUMMY_ON, 0, item)
        VRFW.host.menu_command(IFS.SET_SPRITE, layer, IFS.TAB_ICONS, tab.section.icon_off, IFS.TAB_DUMMY_OFF, 0, item)
      end })
    VRFW.host.on(stem, "UpdateItem", { id = "VRFW.item_filter_sections_row", phase = "around",
      fn = function(game_item, layer, item, list_type, value, option, ...)
        local w = IFS.window
        local tab = w ~= nil and list_type == IFS.ROW_TYPE and w.tabs[option] or nil
        if tab == nil then return game_item(layer, item, list_type, value, option, ...) end
        VRFW.host.menu_command(IFS.SET_TEXT, layer, IFS.ROW_NAME, tab.labels[value] or "", item)
        UpdateCheckBox(layer, item, list_type, value, option)
      end })
    VRFW.host.on(stem, "OnAfterReceiveFilterParam", { id = "VRFW.item_filter_sections_default", phase = "before",
      fn = window_defaults })
    VRFW.host.on(stem, "SetItemFilter", { id = "VRFW.item_filter_sections_preview", phase = "before",
      fn = function()
        local w = IFS.window
        if w ~= nil then IFS.send("window", w.menu, GetFilterParamArray()) end
      end })
    -- «Y Todos» and «Restablecer» work on the rows of the tab shown, as in the game's tabs.
    VRFW.host.on(stem, "IsAllSelectedInCategory", { id = "VRFW.item_filter_sections_all", phase = "around",
      fn = function(game_all, list_type, ...)
        local shown = window_shown_tab(list_type)
        if shown == nil then return game_all(list_type, ...) end
        return GetFilterParamArrayIdx(IFS.ALL_TYPE, IFS.ROW_TYPE, shown) ~= 0
      end })
    VRFW.host.on(stem, "ResetAllFilterParams", { id = "VRFW.item_filter_sections_none", phase = "around",
      fn = function(game_reset, list_type, ...)
        local shown = window_shown_tab(list_type)
        if shown == nil then return game_reset(list_type, ...) end
        RemoveFilterParamInCategory(IFS.ROW_TYPE, shown)
        RemoveFilterParam(IFS.ALL_TYPE, IFS.ROW_TYPE, shown)
      end })
    VRFW.host.on(stem, "SetDefaultFilterParams", { id = "VRFW.item_filter_sections_reset", phase = "around",
      fn = function(game_default, list_type, ...)
        if list_type == nil then
          game_default(list_type, ...)
          return window_defaults()
        end
        local shown = window_shown_tab(list_type)
        if shown == nil then return game_default(list_type, ...) end
        RemoveFilterParamInCategory(IFS.ROW_TYPE, shown)
        AddFilterParam(IFS.ALL_TYPE, IFS.ROW_TYPE, shown)
      end })
    VRFW.host.on(stem, "FinalizeMenu", { id = "VRFW.item_filter_sections_close", phase = "before", fn = function()
      local w = IFS.window
      if w == nil then return end
      IFS.window = nil
      IFS.tell(w.menu, "apply", "close")
      VRFW.host.command(IFS.CMD_TABS, 0)
    end })
  end
end
