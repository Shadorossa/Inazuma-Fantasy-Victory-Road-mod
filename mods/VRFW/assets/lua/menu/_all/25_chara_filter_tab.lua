-- chara_filter_tab (VRFW base feature): the player filter window's season slot as the tab a mod declares
-- ([[VRFW.CharaFilterTab]], scripts/chara_filter_tab.lua). Definitions only: the screens attach it.
if VRFW.chara_filter_tab == nil then
  local CFT = {
    CMD_TAB = VRFW.commands.VRFW_CHARA_FILTER_TAB,
    TEXT_ID = VRFW.commands.VRFW_TEXT_ID,        -- CMND_VRFW_TEXT_ID(text key) -> text id
    TEXT_GET = VRFW.commands.TEXT_GET,           -- CMND_TEXT_GET(text id) -> string
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    SET_SPRITE = 558735651,
    SAVE_FILTER = 1495564355,    -- the bank's own filter save (count, flat params)
    TAB_ICONS = 1333035005,
    TAB_DUMMY_ON = 3229351341,   -- The on-state texture of the dummy tab, `icon_list_tab_dmy01_on`.
    TAB_DUMMY_OFF = 380437824,   -- icon_list_tab_dmy01_off
    ROW_NAME = 1704438437,       -- _text_name01 (the row's label)
    ICON_TYPE = 1000,            -- tabIconType of the tab (above the game's 0..8)
    ROWS_TYPE = 12,              -- list item type of the season slot
    ALL_TYPE = 9,                -- list item type of the "all of a category" params
    cache = nil,                 -- the served tab, false = none (asked once per menu VM)
  }
  VRFW.chara_filter_tab = CFT

  -- a text key in the game's language: string, text id (nil, nil when the key has no text)
  local function text_of(key)
    if type(key) ~= "string" or key == "" then return nil, nil end
    local id = VRFW.host.command(CFT.TEXT_ID, key)
    if type(id) ~= "number" or id == 0 then return nil, nil end
    local s = VRFW.host.command(CFT.TEXT_GET, id)
    if type(s) ~= "string" or s == "" then return nil, nil end
    return s, id
  end

  --- The tab the framework serves: { text id, icon, icon_off, symbol, album, rows = { label } }; nil when none.
  function CFT.served()
    if CFT.cache == nil then
      CFT.cache = false
      local r = table.pack(VRFW.host.command(CFT.CMD_TAB))
      if type(r[1]) == "number" and r[1] > 0 then
        local _, id = text_of(r[2])
        if id == nil then
          VRFW.logger.new("chara_filter_tab")("the tab's text key " .. tostring(r[2]) .. " has no text: no tab")
        else
          local tab = { text = id, icon = r[3], icon_off = r[4], symbol = r[5], album = r[6] == 1, rows = {} }
          for i = 1, r[1] do
            tab.rows[i] = text_of(r[5 + 2 * i]) or tostring(r[6 + 2 * i])
          end
          CFT.cache = tab
        end
      end
    end
    return CFT.cache or nil
  end

  --- The tab table entry of the served tab, or nil; `added` = for a tab list without the season slot (the album's).
  function CFT.entry(added)
    local tab = CFT.served()
    if tab == nil or (added and not tab.album) then return nil end
    return { tabIconType = CFT.ICON_TYPE, tabTextName = tab.text, bgIconTextureName = tab.symbol }
  end

  --- Draws the tab icon on tab slot `slot` of menu `menu`; false when `icon_type` is not the tab's.
  function CFT.draw_icon(menu, slot, icon_type)
    local tab = CFT.served()
    if icon_type ~= CFT.ICON_TYPE or tab == nil then return false end
    VRFW.host.menu_command(CFT.SET_SPRITE, menu, CFT.TAB_ICONS, tab.icon, CFT.TAB_DUMMY_ON, 0, slot)
    VRFW.host.menu_command(CFT.SET_SPRITE, menu, CFT.TAB_ICONS, tab.icon_off, CFT.TAB_DUMMY_OFF, 0, slot)
    return true
  end

  --- Writes the label of row `value` on item `item` of menu `menu`; false when the row is not the tab's.
  function CFT.draw_row(menu, item, item_type, value)
    local tab = CFT.served()
    if item_type ~= CFT.ROWS_TYPE or tab == nil or type(value) ~= "number" then return false end
    local s = tab.rows[value + 1]
    if s == nil then return false end
    VRFW.host.menu_command(CFT.SET_TEXT, menu, CFT.ROW_NAME, s, item)
    return true
  end

  --- `params` without the tab's rows and with its «all»: the save's filter set has no place for them.
  function CFT.saved(params)
    local copy, all = {}, false
    for _, p in ipairs(params) do
      if type(p) ~= "table" or p.listItemType ~= CFT.ROWS_TYPE then
        if type(p) == "table" and p.listItemType == CFT.ALL_TYPE and p.value == CFT.ROWS_TYPE then all = true end
        copy[#copy + 1] = p
      end
    end
    if not all then copy[#copy + 1] = { listItemType = CFT.ALL_TYPE, value = CFT.ROWS_TYPE, option = 0 } end
    return copy
  end

  --- Bank screen `stem` saves its filter without the tab's rows (they last while the screen is open).
  function CFT.attach_bank(stem)
    VRFW.host.wrap("SaveFilterData", function(game_save)
      return function(...)
        if CFT.served() == nil then return game_save(...) end
        local send = CHARA_FILTER_MENU.CreateSendFilterParamArray(CFT.saved(CHARA_FILTER_MENU.GetFilterParamArray()))
        VRFW.host.menu_command(CFT.SAVE_FILTER, #send, send)
      end
    end, { stem = stem, id = "VRFW.chara_filter_tab_save" })
  end

  --- The filter window draws the tab's icon and row labels.
  function CFT.attach_window()
    VRFW.host.wrap("SetTabIcon", function(game_icon)
      return function(menu, slot, icon_type, ...)
        if CFT.draw_icon(menu, slot, icon_type) then return end
        return game_icon(menu, slot, icon_type, ...)
      end
    end, { stem = "chara_filter_menu", id = "VRFW.chara_filter_tab_icon" })
    VRFW.host.wrap("UpdateItem", function(game_item)
      return function(menu, item, item_type, value, option, ...)
        if CFT.draw_row(menu, item, item_type, value) then
          return UpdateCheckBox(menu, item, item_type, value, option)
        end
        return game_item(menu, item, item_type, value, option, ...)
      end
    end, { stem = "chara_filter_menu", id = "VRFW.chara_filter_tab_rows" })
  end
end
