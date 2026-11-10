local TEAM_AI_KEY = @crc:better_ui_team_ai@             -- param store: 1 = AI-role mode
local TEAM_AI_KEY_TYPE = @crc:better_ui_team_ai_type@   -- param store: the dock's team type
local ROLE_TEXTS = {3547488057, 2081656054, 185908320, 2451434970, 3843743052} -- the retail chooser's rows: none, 0..3
local PLAYER_LIST = 3043452150      -- win05_35_performance_chara_list
local PLAYER_ROW = 1076657304       -- win05_36_performance_chara_list_item
local THIS_MENU = 927762597         -- soccer_performance_change_menu
local TITLE_MESH = @crc:_gtxt_performance01@
local TEAM_PARAM = 3357163798
local CURSOR_LAYER = 2296367164     -- cmn05_01_cursor
local BLACK_BACKGROUND = 3801549073 -- cmn02_01_blackbg
local SUB_WINDOW = 968210065        -- sub_window
local CMND_TEXT_GET = @crc:CMND_TEXT_GET@
local CMND_SET_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_SET_MENU_INPUT = 1558704558
local CMND_SET_DRAW_PRIORITY = @crc:CMND_SET_DRAW_PRIORITY@
local CMND_CLOSE_MENU_OBJECT = @crc:CMND_CLOSE_MENU_OBJECT@
local CMND_IS_OPEN_MENU_OBJECT = @crc:CMND_IS_OPEN_MENU_OBJECT@
local CMND_IS_EXIST_MENU_OBJECT = @crc:CMND_IS_EXIST_MENU_OBJECT@
local CMND_SUB_WINDOW_POSITION = 63483614
local CMND_TEAM_CHARA_INDEX = 2113285063
local CMND_TEAM_MEMBER_INFO = 1720957768 -- (team, type, index, what): 0 handle
local CMND_GET_AI_ROLE = 766740776       -- (team, type, index) -> role (-1 none, 0..3)
local CMND_SET_AI_ROLE = 748531447       -- (team, type, index, role)
local CMND_MATCH_ROLE_LIST = @crc:CMND_VRFW_MATCH_ROLE_LIST@
local CMND_MATCH_ROLE_GET = @crc:CMND_VRFW_MATCH_ROLE_GET@    -- (set, type, handle) -> name ("" none), text id
local CMND_MATCH_ROLE_SET = @crc:CMND_VRFW_MATCH_ROLE_SET@    -- (set, type, handle, name) -> ok
local TEAM_SLOTS = 29               -- team member indices 0..28
local LIST_TITLE = 3684289860       -- gtxt_ai_role01, a title sprite of the one-column window (win05_13)
local LIST_TYPE = 0                 -- the one-column sub window (win05_13, up to 9 rows)
local LIST_SIZE = {[1] = 0, [2] = 5, [3] = 1, [4] = 2, [5] = 6, [6] = 3, [7] = 7, [8] = 8} -- size code by row count
local LIST_POSITION_X, LIST_POSITION_Y = 960, -350
local LIST_FULL_HEIGHT, LIST_ROW_PITCH, LIST_FULL_ROWS = 804, 70, 9   -- the window's height at 9 rows, 70 px less per row
local LIST_BOTTOM = 1000            -- the window ends above the button guides: a longer list opens higher

BetterUI_TeamAI = {on = false, teamType = 0, team = nil, rows = {}, focused = nil, picked = nil, listed = nil}
local A = BetterUI_TeamAI

local function Log(...)
  if PRINT ~= nil then
    pcall(PRINT, "BetterUI team_ai", ...)
  end
end

-- read and clear a param store key (0 when absent)
local function TakeParam(key)
  if VRFW.param.has(key) then
    local value = VRFW.param.get(key) or 0
    VRFW.param.clear(key)
    return value
  end
  return 0
end

local function ReadMode()
  local mode = TakeParam(TEAM_AI_KEY)
  A.teamType = TakeParam(TEAM_AI_KEY_TYPE)
  A.on = mode == 1
  A.rows = {}
  A.focused = nil
  if VRFW.param.has(TEAM_PARAM) then
    A.team = VRFW.param.get(TEAM_PARAM)
  end
  if A.on then
    Log("AI-role mode team", A.team, "type", A.teamType)
  end
end

local function Team()
  return A.team or 0
end

local function TeamIndex(handle)
  if handle == nil or handle == 0 then
    return nil
  end
  local ok, index = funcLuaCommand(CMND_TEAM_CHARA_INDEX, Team(), A.teamType, handle)
  if not ok then
    return nil
  end
  return index
end

local function RoleOf(index)
  if index == nil then
    return nil
  end
  local ok, role = funcLuaCommand(CMND_GET_AI_ROLE, Team(), A.teamType, index)
  if ok and type(role) == "number" and role >= -1 and role < 4 then
    return role
  end
  return -1
end

-- Returns the player's match role in this team set.
local function MatchRoleOf(handle)
  if handle == nil or handle == 0 then
    return nil
  end
  local ok, name, text = pcall(funcLuaCommand, CMND_MATCH_ROLE_GET, Team(), A.teamType, handle)
  if ok and type(name) == "string" and name ~= "" then
    return name, text
  end
  return nil
end

local function MatchRolesFor(handle)
  local ok, list = pcall(funcLuaCommand, CMND_MATCH_ROLE_LIST, handle)
  if ok and type(list) == "table" then
    return list
  end
  return {}
end

local function SetMatchRole(handle, name)
  local ok, done = pcall(funcLuaCommand, CMND_MATCH_ROLE_SET, Team(), A.teamType, handle, name or "")
  Log("match role", handle, name or "none", ok and done)
end

local function SetRowText(row, handle)
  local text = "-"
  local name, text_id = MatchRoleOf(handle)
  if name ~= nil then
    text = (type(text_id) == "number" and text_id ~= 0 and funcLuaCommand(CMND_TEXT_GET, text_id)) or name
  else
    local role = RoleOf(TeamIndex(handle))
    if role ~= nil then
      text = funcLuaCommand(CMND_TEXT_GET, ROLE_TEXTS[role + 2]) or ""
    end
  end
  _SetPerformanceText(PLAYER_ROW, row, text, false)
end

local function RefreshRows()
  for row, handle in pairs(A.rows) do
    SetRowText(row, handle)
  end
end

local function HideTitle()
  funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, PLAYER_LIST, TITLE_MESH, false)
end

-- Sets the role of team index `index`.
local function SetRole(index, role)
  if role >= 0 then
    for slot = 0, TEAM_SLOTS - 1 do
      local ok, handle = funcLuaCommand(CMND_TEAM_MEMBER_INFO, Team(), A.teamType, slot, 0)
      if ok and handle ~= nil and handle ~= 0 then
        local ok_index, other = funcLuaCommand(CMND_TEAM_CHARA_INDEX, Team(), A.teamType, handle)
        if ok_index and other ~= index then
          local ok_role, held = funcLuaCommand(CMND_GET_AI_ROLE, Team(), A.teamType, other)
          if ok_role and held == role then
            funcLuaCommand(CMND_SET_AI_ROLE, Team(), A.teamType, other, -1)
            Log("role cleared", handle, role)
          end
        end
      end
    end
  end
  funcLuaCommand(CMND_SET_AI_ROLE, Team(), A.teamType, index, role)
  Log("role set", index, role)
end

-- Runs a modal sub window over this menu.
local function RunSubWindow(open, x, y)
  funcLuaMenuCommand(CMND_SET_MENU_INPUT, THIS_MENU, false)
  funcLuaMenuCommand(CMND_SET_DRAW_PRIORITY, BLACK_BACKGROUND, 0, 750, true)
  funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, CURSOR_LAYER, 0, false)
  open()
  waitTrue(function()
    return funcLuaCommand(CMND_IS_OPEN_MENU_OBJECT, SUB_WINDOW, CURSOR_LAYER)
  end)
  funcLuaCommand(CMND_SUB_WINDOW_POSITION, x, y)
  waitFalse(function()
    return funcLuaMenuCommand(CMND_IS_EXIST_MENU_OBJECT, SUB_WINDOW)
  end)
  funcLuaMenuCommand(CMND_SET_DRAW_PRIORITY, BLACK_BACKGROUND, 0, 740, true)
  funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, CURSOR_LAYER, 0, true)
  funcLuaMenuCommand(CMND_SET_MENU_INPUT, THIS_MENU, true)
end

local function OpenRoleList(handle, index, roles)
  local rows = {}
  for i = 1, #ROLE_TEXTS do
    rows[#rows + 1] = {id = ROLE_TEXTS[i], retail = i - 2}
  end
  local current, focus = MatchRoleOf(handle), 0
  for _, r in ipairs(roles) do
    rows[#rows + 1] = {id = r.text ~= 0 and r.text or ROLE_TEXTS[1], name = r.name}
    if current ~= nil and r.name == current then
      focus = #rows - 1
    end
  end
  if current == nil then
    focus = (RoleOf(index) or -1) + 1
  end
  local ids, enabled, new = {}, {}, {}
  for i, r in ipairs(rows) do
    ids[i], enabled[i], new[i] = r.id, 1, 0
  end
  A.picked = nil
  A.listed = rows
  local height = LIST_FULL_HEIGHT - LIST_ROW_PITCH * (LIST_FULL_ROWS - math.min(#rows, LIST_FULL_ROWS))
  RunSubWindow(function()
    MENU_DEF.OpenSubWindow("BetterUI_TeamAI_OnListPicked", "", #rows, ids, LIST_SIZE[#rows] or 0, LIST_TITLE, enabled, focus, false, false, LIST_TYPE, 0, new)
  end, LIST_POSITION_X, -math.min(-LIST_POSITION_Y, LIST_BOTTOM - height))
  local pick = type(A.picked) == "number" and rows[A.picked + 1] or nil
  A.listed = nil
  if pick ~= nil then
    if pick.name ~= nil then
      if RoleOf(index) ~= -1 then
        funcLuaCommand(CMND_SET_AI_ROLE, Team(), A.teamType, index, -1)
      end
      SetMatchRole(handle, pick.name)
    else
      if current ~= nil then
        SetMatchRole(handle, "")
      end
      SetRole(index, pick.retail)
    end
  end
  RefreshRows()
end

function BetterUI_TeamAI_OnListPicked(pick)
  if type(pick) == "number" and pick >= 0 and A.listed ~= nil and pick < #A.listed then
    A.picked = pick
    funcLuaCommand(CMND_CLOSE_MENU_OBJECT, SUB_WINDOW)
  end
end

-- the retail AI-role chooser for the focused player, or the match roles' list when his position has any
local function OpenRoleChooser()
  local handle = A.focused
  if handle == nil or handle == 0 then
    return
  end
  local index = TeamIndex(handle)
  if index == nil then
    return
  end
  local roles = MatchRolesFor(handle)
  if #roles > 0 then
    return OpenRoleList(handle, index, roles)
  end
  local role = RoleOf(index) or -1
  A.picked = nil
  RunSubWindow(function()
    MENU_DEF.OpenSubWindowRoleAISettings("BetterUI_TeamAI_OnRolePicked", "", role + 1)
  end, LIST_POSITION_X, LIST_POSITION_Y)
  local picked = A.picked
  if type(picked) == "number" and picked >= 0 and picked <= 4 then
    SetRole(index, picked - 1)
  end
  RefreshRows()
end

function BetterUI_TeamAI_OnRolePicked(pick)
  A.picked = pick
  funcLuaCommand(CMND_CLOSE_MENU_OBJECT, SUB_WINDOW)
end

local retailOnInit = OnInit
OnInit = function(...)
  ReadMode()
  return retailOnInit(...)
end

local retailInitInfo = InitPerformanceChangeMenuInfo
InitPerformanceChangeMenuInfo = function(team, ...)
  A.team = team
  return retailInitInfo(team, ...)
end

local retailSetupLayer = OnSetupLayer
OnSetupLayer = function(layer, index, ...)
  local results = table.pack(retailSetupLayer(layer, index, ...))
  if A.on and layer == PLAYER_LIST then
    HideTitle()
  end
  return table.unpack(results, 1, results.n)
end

local retailUpdateListItem = UpdateListItem
UpdateListItem = function(layer, row, handle, focused, ...)
  local results = table.pack(retailUpdateListItem(layer, row, handle, focused, ...))
  if A.on and layer == PLAYER_ROW and handle ~= nil then
    A.rows[row] = handle
    if focused then
      A.focused = handle
    end
    SetRowText(row, handle)
    HideTitle()
  end
  return table.unpack(results, 1, results.n)
end

local retailDecideFocus = OnDecideFocus
OnDecideFocus = function(layer, index, ...)
  if A.on and layer == PLAYER_LIST then
    return OpenRoleChooser()
  end
  return retailDecideFocus(layer, index, ...)
end
