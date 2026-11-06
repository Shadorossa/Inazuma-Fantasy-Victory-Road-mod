-- no season tab (VRFW, always on, docs/framework/no-season.md §4): the player filter window («FILTRAR») lists no
-- Victory Road season tab. The game's tab list is the last entry of its tab table (tab icon type 7); it leaves the
-- copy the window reads (GetFilterGroupInfoArray), so the tab strip, L1 / R1 and a remembered tab never reach it and
-- every other tab keeps its index. The season category (list item type 12) stays «all» ({9, 12, 0}, no
-- {12, value, 0}) in the window's params when they arrive and before they are sent; the bank's own season test is
-- off natively (season_end.toml SeasonFilterOff). Wraps the menu's own global functions (no host); nothing runs at
-- load time.
do
  local SEASON_TAB_ICON = 7   -- tabIconType of the game's season tab (icon_list_tab_filter13)
  local SEASON_TYPE = 12      -- list item type of the season category
  local ALL_TYPE = 9          -- list item type of the «all of a category» params

  local trimmed = setmetatable({}, { __mode = "k" })   -- game tab table -> the same table without the season tab

  local function without_season(tabs)
    if type(tabs) ~= "table" then
      return tabs
    end
    local last = tabs[#tabs]
    if type(last) ~= "table" or last.tabIconType ~= SEASON_TAB_ICON then
      return tabs
    end
    local copy = trimmed[tabs]
    if copy == nil then
      copy = {}
      for i = 1, #tabs - 1 do
        copy[i] = tabs[i]
      end
      trimmed[tabs] = copy
      pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "no_season", "chara_filter_menu", "season tab left out (" .. #copy .. " tabs)")
    end
    return copy
  end

  -- the season category back to «all» in a param array ({listItemType, value, option} rows); in place
  local function season_all(params)
    if type(params) ~= "table" then
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
