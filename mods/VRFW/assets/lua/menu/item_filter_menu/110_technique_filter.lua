-- technique filter values (VRFW, the Lua side of scripts\technique_filter.lua): the move filter window's tension
-- tab (list item type 3) lists one row per value the framework serves from the technique table
-- (CMND_VRFW_TECHNIQUE_FILTER_VALUES); a tab a mod adds ([[VRFW.TechniqueFilterTab]], rows = "families") lists one row
-- per technique family (CMND_VRFW_TECHNIQUE_FILTER_FAMILIES). Both tabs are the game's tension group: the row values
-- table (local t4) holds the tension rows then the family rows, rebuilt in place when the window opens, and the game
-- builds only the rows of the tab shown. A family row's label is the family's name (its text key, else its id's last
-- part). The added tab's entry of the tab list (local t10) gets the declared name, tab icon and background symbol.
-- Framework off (the game's own rows): nothing is touched. Handlers on this script's host (000_host.lua): OnInit and
-- SetupFilterGroupInfoArray (the tab list's copy of the tab table) both refresh. No engine call at load time.
if VRFW_Host ~= nil then
  local TF = {
    CMD_VALUES = VRFW_Cmd.VRFW_TECHNIQUE_FILTER_VALUES,     -- CMND_VRFW_TECHNIQUE_FILTER_VALUES(list item type) -> n, value 1, ... (0 = off)
    CMD_FAMILIES = VRFW_Cmd.VRFW_TECHNIQUE_FILTER_FAMILIES,   -- CMND_VRFW_TECHNIQUE_FILTER_FAMILIES() -> first row, n, tab index, tab text, icon, icon off, symbol, text 1, name 1, ... (0 = none)
    TEXT_ID = VRFW_Cmd.VRFW_TEXT_ID,        -- CMND_VRFW_TEXT_ID(text key) -> text id
    TEXT_GET = VRFW_Cmd.TEXT_GET,       -- CMND_TEXT_GET(text id) -> string
    SET_TEXT = VRFW_Cmd.SET_MENU_TEXT_STRING,       -- CMND_SET_MENU_TEXT_STRING(layer, text name, string, item)
    SET_SPRITE = 558735651,      -- the game's sprite swap (layer, texture file, sprite, dummy sprite, 0, item)
    TAB_ICONS = 1333035005,      -- #/menu/200_icon/16_icon_list_tab_filter/<LG>/icon_list_tab_filter.g4tx
    TAB_DUMMY_ON = 3229351341,   -- icon_list_tab_dmy01_on
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
      local ok, id = pcall(funcLuaCommand, TF.TEXT_ID, key)
      if ok and type(id) == "number" and id ~= 0 then
        local okg, s = pcall(funcLuaCommand, TF.TEXT_GET, id)
        if okg and type(s) == "string" and s ~= "" then
          return s, id
        end
      end
    end
    return tostring(fallback or ""), nil
  end

  -- the served rows into t4; the same result on every call
  local function refresh()
    local host = VRFW_Host.hosts and VRFW_Host.hosts.item_filter_menu
    local rows = host and host.L and host.L.t4
    local r = table.pack(pcall(funcLuaCommand, TF.CMD_VALUES, TF.TENSION))
    if type(rows) ~= "table" or not r[1] or type(r[2]) ~= "number" or r[2] <= 0 then
      return
    end
    for i = #rows, 1, -1 do
      rows[i] = nil
    end
    for i = 1, r[2] do
      rows[i] = { value = r[2 + i] }
    end
    TF.first, TF.labels, TF.tab = nil, {}, nil
    local f = table.pack(pcall(funcLuaCommand, TF.CMD_FAMILIES))
    if not f[1] or type(f[2]) ~= "number" or type(f[3]) ~= "number" or f[3] <= 0 or type(f[4]) ~= "number" then
      return
    end
    TF.first = f[2]
    local _, text_id = text_of(f[5], "")
    TF.tab = { index = f[4], text = text_id, icon = f[6], icon_off = f[7], symbol = f[8] }
    for i = 1, f[3] do
      TF.labels[i] = text_of(f[7 + 2 * i], f[8 + 2 * i])
      rows[f[2] + i] = { value = 0 }
    end
  end

  -- the added tab's entry of the tab list: its name, icon and background symbol
  local function tab_entry()
    local host = VRFW_Host.hosts and VRFW_Host.hosts.item_filter_menu
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

  VRFW_Host.on("item_filter_menu", "OnInit", { id = "VRFW.technique_filter_values", phase = "before", fn = refresh })
  -- the tab list is copied from the tab table here (the window's layer setup)
  VRFW_Host.on("item_filter_menu", "SetupFilterGroupInfoArray", { id = "VRFW.technique_filter_tab", phase = "before",
    fn = refresh })
  VRFW_Host.on("item_filter_menu", "SetupFilterGroupInfoArray", { id = "VRFW.technique_filter_tab_entry",
    phase = "after", fn = tab_entry })

  -- the added tab's icon (the game's own icon types draw as before)
  VRFW_Host.on("item_filter_menu", "SetTabIcon", { id = "VRFW.technique_filter_tab_icon", phase = "after", fn = function(r, a1, a2, a3)
    local tab = TF.tab
    if a3 ~= TF.TAB_ICON_TYPE or tab == nil or type(tab.icon) ~= "number" or type(tab.icon_off) ~= "number" then
      return
    end
    funcLuaMenuCommand(TF.SET_SPRITE, a1, TF.TAB_ICONS, tab.icon, TF.TAB_DUMMY_ON, 0, a2)
    funcLuaMenuCommand(TF.SET_SPRITE, a1, TF.TAB_ICONS, tab.icon_off, TF.TAB_DUMMY_OFF, 0, a2)
  end })

  -- a family row: the family's name in place of the number the game drew
  VRFW_Host.on("item_filter_menu", "UpdateItem", { id = "VRFW.technique_filter_families", phase = "after", fn = function(r, a1, a2, a3, a4)
    if a3 ~= TF.TENSION or TF.first == nil or type(a4) ~= "number" or a4 < TF.first then
      return
    end
    local s = TF.labels[a4 - TF.first + 1]
    if s ~= nil then
      funcLuaMenuCommand(TF.SET_TEXT, a1, TF.ROW_NAME, s, a2)
    end
  end })
end
