if VRFW.host ~= nil then
  local TF = {
    CMD_VALUES = VRFW.commands.VRFW_TECHNIQUE_FILTER_VALUES,
    CMD_FAMILIES = VRFW.commands.VRFW_TECHNIQUE_FILTER_FAMILIES,
    TEXT_ID = VRFW.commands.VRFW_TEXT_ID,        -- CMND_VRFW_TEXT_ID(text key) -> text id
    TEXT_GET = VRFW.commands.TEXT_GET,       -- CMND_TEXT_GET(text id) -> string
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    SET_SPRITE = 558735651,
    TAB_ICONS = 1333035005,
    TAB_DUMMY_ON = 3229351341,   -- `icon_list_tab_dmy01_on`
    TAB_DUMMY_OFF = 380437824,   -- icon_list_tab_dmy01_off
    TAB_ICON_TYPE = 1000,        -- tabIconType of the added tab (above the game's 0..5)
    ROW_NAME = 1704438437,       -- _text_name01 (the row's label)
    TENSION = 3,                 -- list item type of the tension tab
    first = nil,                 -- row index of the first family row (nil = no family rows)
    labels = {},                 -- family row labels, by family index (1-based)
    tab = nil,                   -- the added tab: { index, text, icon, icon_off, symbol }
  }

  -- a text key in the game's language, else `fallback`
  local function text_of(key, fallback)
    if type(key) == "string" and key ~= "" then
      local id = VRFW.host.command(TF.TEXT_ID, key)
      if type(id) == "number" and id ~= 0 then
        local s = VRFW.host.command(TF.TEXT_GET, id)
        if type(s) == "string" and s ~= "" then
          return s, id
        end
      end
    end
    return tostring(fallback or ""), nil
  end

  local function refresh()
    local host = VRFW.host.hosts and VRFW.host.hosts.item_filter_menu
    local rows = host and host.L and host.L.t4
    local r = table.pack(VRFW.host.command(TF.CMD_VALUES, TF.TENSION))
    if type(rows) ~= "table" or type(r[1]) ~= "number" or r[1] <= 0 then
      return
    end
    for i = #rows, 1, -1 do
      rows[i] = nil
    end
    for i = 1, r[1] do
      rows[i] = { value = r[1 + i] }
    end
    TF.first, TF.labels, TF.tab = nil, {}, nil
    local f = table.pack(VRFW.host.command(TF.CMD_FAMILIES))
    if type(f[1]) ~= "number" or type(f[2]) ~= "number" or f[2] <= 0 or type(f[3]) ~= "number" then
      return
    end
    TF.first = f[1]
    local _, text_id = text_of(f[4], "")
    TF.tab = { index = f[3], text = text_id, icon = f[5], icon_off = f[6], symbol = f[7] }
    for i = 1, f[2] do
      TF.labels[i] = text_of(f[6 + 2 * i], f[7 + 2 * i])
      rows[f[1] + i] = { value = 0 }
    end
  end

  local function tab_entry()
    local host = VRFW.host.hosts and VRFW.host.hosts.item_filter_menu
    local tabs = host and host.L and host.L.t10
    local tab = TF.tab
    if tab == nil or type(tabs) ~= "table" or type(tabs[tab.index + 1]) ~= "table" then
      return
    end
    local entry = tabs[tab.index + 1]
    entry.tabIconType = TF.TAB_ICON_TYPE
    if tab.text ~= nil then
      entry.tabTextName = tab.text
    end
    if type(tab.symbol) == "number" then
      entry.bgIconTextureName = tab.symbol
    end
  end

  VRFW.host.on("item_filter_menu", "OnInit", { id = "VRFW.technique_filter_values", phase = "before", fn = refresh })
  -- the tab list is copied from the tab table here (the window's layer setup)
  VRFW.host.on("item_filter_menu", "SetupFilterGroupInfoArray", { id = "VRFW.technique_filter_tab", phase = "before",
    fn = refresh })
  VRFW.host.on("item_filter_menu", "SetupFilterGroupInfoArray", { id = "VRFW.technique_filter_tab_entry",
    phase = "after", fn = tab_entry })

  VRFW.host.on("item_filter_menu", "SetTabIcon", { id = "VRFW.technique_filter_tab_icon", phase = "after", fn = function(r, a1, a2, a3)
    local tab = TF.tab
    if a3 ~= TF.TAB_ICON_TYPE or tab == nil or type(tab.icon) ~= "number" or type(tab.icon_off) ~= "number" then
      return
    end
    funcLuaMenuCommand(TF.SET_SPRITE, a1, TF.TAB_ICONS, tab.icon, TF.TAB_DUMMY_ON, 0, a2)
    funcLuaMenuCommand(TF.SET_SPRITE, a1, TF.TAB_ICONS, tab.icon_off, TF.TAB_DUMMY_OFF, 0, a2)
  end })

  VRFW.host.on("item_filter_menu", "UpdateItem", { id = "VRFW.technique_filter_families", phase = "after", fn = function(r, a1, a2, a3, a4)
    if a3 ~= TF.TENSION or TF.first == nil or type(a4) ~= "number" or a4 < TF.first then
      return
    end
    local s = TF.labels[a4 - TF.first + 1]
    if s ~= nil then
      funcLuaMenuCommand(TF.SET_TEXT, a1, TF.ROW_NAME, s, a2)
    end
  end })
end
