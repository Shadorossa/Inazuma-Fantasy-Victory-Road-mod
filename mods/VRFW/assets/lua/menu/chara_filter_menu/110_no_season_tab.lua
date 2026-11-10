do
  local SEASON_TAB_ICON = 7
  local SEASON_TYPE = 12      -- list item type of the season category
  local ALL_TYPE = 9          -- list item type of the "all of a category" params

  local trimmed = setmetatable({}, { __mode = "k" })   -- game tab table -> the table the window gets

  -- the tab a mod declares in the season slot (VRFW.chara_filter_tab), or nil; `added` = for a list without that slot
  local function mod_tab(added)
    return VRFW.chara_filter_tab ~= nil and VRFW.chara_filter_tab.entry(added) or nil
  end

  local function without_season(tabs)
    if type(tabs) ~= "table" then
      return tabs
    end
    local last = tabs[#tabs]
    if type(last) ~= "table" then
      return tabs
    end
    local season = last.tabIconType == SEASON_TAB_ICON
    -- a list without the season slot (the album's) gets the tab after its last one when the framework extended it
    local entry = mod_tab(not season)
    if not season and entry == nil then
      return tabs
    end
    local copy = trimmed[tabs]
    if copy == nil then
      copy = {}
      for i = 1, #tabs do
        copy[i] = tabs[i]
      end
      if season then
        copy[#tabs] = nil
      end
      if entry ~= nil then
        copy[#copy + 1] = entry
        VRFW.host.command(VRFW.commands.VRFW_LOG, "no_season", "chara_filter_menu", "declared tab in the season slot (" .. #copy .. " tabs)")
      else
        VRFW.host.command(VRFW.commands.VRFW_LOG, "no_season", "chara_filter_menu", "season tab left out (" .. #copy .. " tabs)")
      end
      trimmed[tabs] = copy
    end
    return copy
  end

  local function season_all(params)
    if type(params) ~= "table" or mod_tab() ~= nil then
      return
    end
    local has_all = false
    for i = #params, 1, -1 do
      local p = params[i]
      if type(p) == "table" then
        if p.listItemType == SEASON_TYPE then
          table.remove(params, i)
        elseif p.listItemType == ALL_TYPE and p.value == SEASON_TYPE and p.option == 0 then
          has_all = true
        end
      end
    end
    if not has_all then
      table.insert(params, { listItemType = ALL_TYPE, value = SEASON_TYPE, option = 0 })
    end
  end

  local get_tabs = _G.GetFilterGroupInfoArray
  if type(get_tabs) == "function" then
    _G.GetFilterGroupInfoArray = function(...)
      return without_season(get_tabs(...))
    end
  end

  local after_receive = _G.OnAfterReceiveFilterParam
  if type(after_receive) == "function" then
    _G.OnAfterReceiveFilterParam = function(...)
      if type(CHARA_FILTER_MENU) == "table" and type(CHARA_FILTER_MENU.GetFilterParamArray) == "function" then
        season_all(CHARA_FILTER_MENU.GetFilterParamArray())
      end
      return after_receive(...)
    end
  end

  if type(CHARA_FILTER_MENU) == "table" and type(CHARA_FILTER_MENU.SendFilterParam) == "function" then
    local send = CHARA_FILTER_MENU.SendFilterParam
    CHARA_FILTER_MENU.SendFilterParam = function(menu, params, ...)
      season_all(params)
      return send(menu, params, ...)
    end
  end
end
