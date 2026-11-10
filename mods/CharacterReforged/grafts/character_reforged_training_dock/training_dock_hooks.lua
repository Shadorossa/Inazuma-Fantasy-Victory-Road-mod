-- soccer_team_dock_menu
local ROW = 6                          -- row index of "Entrenamiento" (after the 6 retail rows 0..5)
local TEXT = 1567719417
local MENU = 278813410                -- character_reforged_training_menu
local LOADER_VERSION = 3277307410      -- CMND_VRFW_LOADER_VERSION
local KEY_HDL = 4161869490             -- character_reforged_training_menu: first character (0 = first dock member)
local KEY_DOCK_OK = 638665151         -- character_reforged_tr_dock_ok
local KEY_DOCK_NO = 946320615         -- character_reforged_tr_dock_no
local KEY_DOCK_TYPE = 2835528766       -- character_reforged_tr_dock_type
local IDS = {3845375161, 150149707, 4260689898, 22372728, 2344649719, 3924033091}
-- Rows shown for "Entrenamiento".
local SHOW = {0, 1, 4}
local SIZE_BY_ROWS = {[1] = 0, [2] = 0, [3] = 1, [4] = 2, [5] = 6, [6] = 3}

local STEM = "soccer_team_dock_menu"
local host = VRFW.host

local function locals()
  local h = type(host) == "table" and type(host.hosts) == "table" and host.hosts[STEM] or nil
  return h ~= nil and h.L or nil
end

-- Maps a visible row (0-based) to the retail row.
local function retail_row(v)
  if type(v) ~= "number" or v < 0 then
    return v
  end
  if v < #SHOW then
    return SHOW[v + 1]
  end
  return ROW
end

-- retail row -> visible row (0 when the retail row is hidden)
local function visible_row(r)
  if r == ROW then
    return #SHOW
  end
  for i = 1, #SHOW do
    if SHOW[i] == r then
      return i - 1
    end
  end
  return 0
end

local function available()
  local ok, api = pcall(funcLuaCommand, LOADER_VERSION)
  return ok and type(api) == "number"            -- the loader's Lua bridge answers
end

local function set_param(key, v)
  VRFW.param.clear(key)
  VRFW.param.set(key, v)
end

-- Opens soccer_formation_menu_inc OpenSelectTeamMemberControlSubWindowCore with a 7th row.
local function open_core(a1, a2)
  local n5 = locals().n5
  local focus = a2 or 0
  local ok, count = funcLuaCommand(1033065575 --[[CMND_GET_TEAM_SET_INFO?]], n5, 0, 0)
  local on = (ok ~= false and count ~= 0) and 1 or 0
  local enable = {on, on, on, on, on, on}
  local ret2 = funcLuaCommand(589837020, 1)
  ok, count = funcLuaCommand(1033065575 --[[CMND_GET_TEAM_SET_INFO?]], n5, 0, 0, false, false, false, true)
  if ok == false or count == 0 or ret2 <= 0 then
    enable[5] = 0
  end
  local ids, shown, check = {}, {}, {}
  for i = 1, #SHOW do
    ids[i] = IDS[SHOW[i] + 1]
    shown[i] = enable[SHOW[i] + 1]
    check[i] = 0
  end
  if available() then
    ids[#ids + 1] = TEXT
    shown[#shown + 1] = on
    check[#check + 1] = 0
  end
  focus = visible_row(focus)
  if focus >= #ids then
    focus = 0
  end
  funcLuaCommand(2040257363, false)
  MENU_DEF.OpenSubWindow(a1, "", #ids, ids, SIZE_BY_ROWS[#ids] or 3, 3934778541 --[[gtxt_command01]], shown, focus, false, false, 22, 0, {}, -1, {}, {}, 0, check)
  waitFalse(function()
    return funcLuaCommand(667479479, 968210065 --[[sub_window]])
  end)
  funcLuaCommand(63483614, 960, -267)
  waitTrue(function()
    return funcLuaCommand(3444627471, 118161610 --[[win05_11_sub_list_locator_15]])
  end)
  funcLuaCommand(3647847018, focus, 118161610 --[[win05_11_sub_list_locator_15]])
end

-- Runs as l7 (resumed by Step) after the list closed.
local function training_coroutine()
  local L = locals()
  funcLuaMenuCommand(1558704558, 937147172 --[[soccer_team_dock_menu]], false)
  funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], 2296367164 --[[cmn05_01_cursor]], 0, false, 937147172 --[[soccer_team_dock_menu]])
  set_param(KEY_HDL, 0)
  set_param(KEY_DOCK_OK, 1)
  set_param(KEY_DOCK_NO, L.n5)
  set_param(KEY_DOCK_TYPE, 0)
  pcall(funcLuaCommand, 519897777 --[[CMND_VRFW_LOG]], "Character Reforged training: team dock -> character_reforged_training_menu", "dock", L.n5)
  funcLuaCommand(433545986 --[[CMND_OPEN_MENU_OBJECT]], MENU)
  local n = 0
  while not funcLuaCommand(264888438 --[[CMND_IS_EXIST_MENU?]], MENU) and n < 180 do
    coroutine.yield()
    n = n + 1
  end
  waitFalse(function()
    return funcLuaMenuCommand(2231168902 --[[CMND_IS_EXIST_MENU_OBJECT?]], MENU)
  end)
  funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], 2296367164 --[[cmn05_01_cursor]], 0, true, 937147172 --[[soccer_team_dock_menu]])
  funcLuaMenuCommand(1558704558, 937147172 --[[soccer_team_dock_menu]], true)
  UpdateFormationInfo()
  L.l7 = nil
  L.n12 = ROW
  L.l6 = coroutine.create(OpenSelectTeamMemberControlSubWindowSoccerTeamDock)
end

if type(host) == "table" and type(host.on) == "function" then
  -- the menu's own OpenSelectTeamMemberControlSubWindowSoccerTeamDock with the mod's core (the retail one is not called)
  host.on(STEM, "OpenSelectTeamMemberControlSubWindowSoccerTeamDock", {id = "CharacterReforged.training_dock.open_list",
    phase = "around", fn = function(_, a1, a2)
      funcLuaMenuCommand(1558704558, 937147172 --[[soccer_team_dock_menu]], false)
      funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], 2296367164 --[[cmn05_01_cursor]], 0, false, 937147172 --[[soccer_team_dock_menu]])
      open_core(a1, a2)
      waitTrue(function()
        return funcLuaCommand(1521844538 --[[CMND_IS_CLOSE_MENU_OBJECT]], 968210065 --[[sub_window]])
      end)
      funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], 2296367164 --[[cmn05_01_cursor]], 0, true, 937147172 --[[soccer_team_dock_menu]])
      funcLuaMenuCommand(1558704558, 937147172 --[[soccer_team_dock_menu]], true)
      locals().l6 = nil
    end})
  -- The visible row is mapped back to the retail one.
  host.on(STEM, "CallbackCloseCondTeamCommandSubWinSoccerTeamDock", {id = "CharacterReforged.training_dock.choose_row",
    phase = "around", fn = function(nxt, a1, ...)
      a1 = retail_row(a1)
      if a1 == ROW then
        local L = locals()
        L.l6 = nil
        L.n12 = ROW
        L.l7 = coroutine.create(training_coroutine)
        funcLuaCommand(320421347 --[[CMND_CLOSE_MENU_OBJECT]], 968210065 --[[sub_window]])
        return
      end
      return nxt(a1, ...)
    end})
end
