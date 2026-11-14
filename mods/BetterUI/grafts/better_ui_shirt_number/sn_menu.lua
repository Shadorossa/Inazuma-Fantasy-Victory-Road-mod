BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, corner_buttons = true, enemy_meters = true, esc_guide = true, header_short = true, nickname_pill = true, shirt_number = true, team_param_guide = true, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

local function UiOn(flag)
  return BetterUI.flags[flag] == true
end

local function Pack(...)
  return { n = select("#", ...), ... }
end

-- Logs at most 30 UI messages.
local log_count = 0
local function UiLog(...)
  if log_count >= 30 then
    return
  end
  log_count = log_count + 1
  local parts = {}
  for i = 1, select("#", ...) do
    parts[#parts + 1] = tostring((select(i, ...)))
  end
  if type(funcLuaCommand) == "function" then
    VRFW.host.command(@crc:CMND_VRFW_LOG_DEBUG@, "BetterUI @TAG@ " .. table.concat(parts, " "))
  end
end

-- Runs filter(call, id, ...) on every funcLuaMenuCommand of this VM as an innermost VRFW.host command hook, so the
-- other hooks run outside it; call(id, ...) passes the same command on and runs another one on the function under
-- every hook; a nil answer passes the command on.
local function UiHookMenuCommand(filter)
  local function register(host)
    local real = host.real_menu_command
    host.hook_command("*", function(nxt, id, ...)
      local function call(command, ...)
        if command == id then
          return nxt(command, ...)
        end
        return real(command, ...)
      end
      local r = filter(call, id, ...)
      if r ~= nil then
        return table.unpack(r, 1, r.n)
      end
      return nxt(id, ...)
    end, "BetterUI.@TAG@", { menu = true, priority = host.INNERMOST })
  end
  if type(VRFW) == "table" and type(VRFW.host) == "table" and type(VRFW.host.hook_command) == "function" then
    register(VRFW.host)
  else
    -- The menu chunk runs before the Lua patch files: BetterUI's lua/_all/better_ui.lua registers the queue after VRFW's.
    BetterUI.command_hooks = BetterUI.command_hooks or {}
    BetterUI.command_hooks[#BetterUI.command_hooks + 1] = register
  end
end

-- Wraps a menu callback (OnSetupLayer, OnOpenLayer, ...) that the chunk already defined: `after` runs after it.
local function UiWrapCallback(name, after)
  local orig = rawget(_ENV, name)
  if type(orig) ~= "function" then
    return false
  end
  rawset(_ENV, name, function(...)
    local r = Pack(orig(...))
    local ok, err = pcall(after, ...)
    if not ok then
      UiLog("error", name, err)
    end
    return table.unpack(r, 1, r.n)
  end)
  return true
end

BetterUI.flags.shirt_number = true
-- Parameter keys of soccer_performance_change_menu in shirt-number mode (param better_ui_shirt_number = 1, consumed at OnInit).
local SN_KEY = @crc:better_ui_shirt_number@
local SN_KEY_TYPE = @crc:better_ui_shirt_number_type@
local SN_TEXT_ROW = @crc:better_ui_shirt_number_row@
local SN_LIST = @crc:win05_35_performance_chara_list@ -- win05_35_performance_chara_list
local SN_ITEM = @crc:win05_36_performance_chara_list_item@ -- win05_36_performance_chara_list_item
local SN_WIN = @crc:uniform_no_window@  -- uniform_no_window
local SN_MENU = @crc:soccer_performance_change_menu@  -- soccer_performance_change_menu
local SN_TITLE = @crc:_gtxt_performance01@
local SN_TEAM_PARAM = 3357163798
local SN_CURSOR = @crc:cmn05_01_cursor@ -- cmn05_01_cursor
local SN_COACH_POS = 19
local CMND_TEXT_GET = @crc:CMND_TEXT_GET@
local CMND_SET_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_SET_MENU_INPUT = @crc:CMND_SET_INPUT_ENABLE_MENU_OBJECT@
local CMND_CLOSE_MENU_OBJECT = @crc:CMND_CLOSE_MENU_OBJECT@
local CMND_IS_CLOSE_MENU_OBJECT = @crc:CMND_IS_CLOSE_MENU_OBJECT@
local CMND_IS_OPENING = 667479479
local CMND_PLAY_SE = @crc:CMND_SND_PLAY_SE@
local SE_DECIDE = @crc:sy0000@ -- sy0000
local SE_BEEP = @crc:sy0003@   -- sy0003
local CMND_TEAM_CHARA_INDEX = @crc:CMND_GET_TEAM_CHARA_INDEX@
local CMND_TEAM_NUMBER = @crc:CMND_SORT_GIMMICK_MP@
local CMND_TEAM_MEMBER_INFO = @crc:CMND_REJECT_ALIGN_HUMAN@ -- (team, type, idx, what): 0 handle, 1 position slot, 2 number
local CMND_TEAM_NUMBER_OWNER = 1967539593
local CMND_TEAM_SET_NUMBER = @crc:CMND_OPEN_SEARCH_EQ_CG@
local CMND_NUMBER_CHANGEABLE = 2573177663
local CMND_NUM_WIN_DUP_POPUP = 2821144936
local CMND_NUM_WIN_RESET = 1129326309
local CMND_NUM_WIN_REFRESH = 1453710531

BetterUI.shirt_number_menu = {on = false, type = 0, team = nil, rows = {}, cur = nil, edit = nil, prev = 0,
  forced = false}
local M = BetterUI.shirt_number_menu

local function SnReadMode()
  local mode = 0
  if VRFW.param.has(SN_KEY) then
    mode = VRFW.param.get(SN_KEY) or 0
    VRFW.param.clear(SN_KEY)
  end
  M.type = 0
  if VRFW.param.has(SN_KEY_TYPE) then
    M.type = VRFW.param.get(SN_KEY_TYPE) or 0
    VRFW.param.clear(SN_KEY_TYPE)
  end
  M.on = mode == 1 and UiOn("shirt_number")
  M.rows = {}
  M.cur, M.edit, M.prev, M.forced = nil, nil, 0, false
  if VRFW.param.has(SN_TEAM_PARAM) then
    M.team = VRFW.param.get(SN_TEAM_PARAM)
  end
  if M.on then
    UiLog("shirt number mode team", M.team, "type", M.type)
  end
end

local function SnTeam()
  return M.team or 0
end

-- current number and team index of a chara handle
local function SnNum(hdl)
  if hdl == nil or hdl == 0 then
    return nil, nil
  end
  local ok, idx = funcLuaCommand(CMND_TEAM_CHARA_INDEX, SnTeam(), M.type, hdl)
  if not ok then
    return nil, nil
  end
  local ok2, num = funcLuaCommand(CMND_TEAM_NUMBER, SnTeam(), M.type, idx)
  if not ok2 or type(num) ~= "number" then
    ok2, num = funcLuaCommand(CMND_TEAM_MEMBER_INFO, SnTeam(), M.type, idx, 2)
    if not ok2 then
      num = nil
    end
  end
  return num, idx
end

-- Mirrors retail IsUniformNoOverlapFreeChara.
local function SnFree(hdl)
  if hdl == nil or hdl == 0 then
    return true
  end
  local ok, idx = funcLuaCommand(CMND_TEAM_CHARA_INDEX, SnTeam(), M.type, hdl)
  if not ok then
    return false
  end
  local ok2, pos = funcLuaCommand(CMND_TEAM_MEMBER_INFO, SnTeam(), M.type, idx, 1)
  return ok2 == true and pos == SN_COACH_POS
end

-- the other member already wearing `num` (retail CheckSameUniformNoToTeamMember)
local function SnDup(num)
  local ret = funcLuaCommand(CMND_TEAM_NUMBER_OWNER, SnTeam(), M.type, num)
  local _, myIdx = SnNum(M.edit)
  if type(ret) == "number" and ret ~= -1 and ret ~= myIdx then
    local ok, h = funcLuaCommand(CMND_TEAM_MEMBER_INFO, SnTeam(), M.type, ret, 0)
    if ok and h ~= nil then
      return h, ret
    end
  end
  return 0, -1
end

local function SnRowText(num)
  local s = funcLuaCommand(CMND_TEXT_GET, SN_TEXT_ROW)
  local n = string.format("%d", num)
  if type(s) ~= "string" or s == "" then
    return n
  end
  local out, k = string.gsub(s, "{n}", n)
  if k == 0 then
    out = s .. " " .. n
  end
  return out
end

local function SnSetRowText(row, hdl)
  local s = "-"
  local num = SnNum(hdl)
  if num ~= nil then
    s = SnRowText(num)
  end
  _SetPerformanceText(SN_ITEM, row, s, false)
end

local function SnRefreshRows()
  for row, hdl in pairs(M.rows) do
    SnSetRowText(row, hdl)
  end
end

local function SnHideTitle()
  funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, SN_LIST, SN_TITLE, false)
end

local function SnOpenNumber()
  local hdl = M.cur
  if hdl == nil or hdl == 0 then
    return
  end
  if not funcLuaCommand(CMND_NUMBER_CHANGEABLE, hdl) then
    funcLuaCommand(CMND_PLAY_SE, SE_BEEP)
    UiLog("number change refused", hdl)
    return
  end
  local num = SnNum(hdl) or 0
  M.edit, M.prev, M.forced = hdl, 0, false
  funcLuaMenuCommand(CMND_SET_MENU_INPUT, SN_MENU, false)
  funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, SN_CURSOR, 0, false)
  funcLuaCommand(CMND_PLAY_SE, SE_DECIDE)
  MENU_DEF.OpenNumDigitWindow("BetterUI_ShirtNumberDone", "BetterUI_ShirtNumberChange", SN_WIN, true, 1, 0, 0, 2, 1)
  local ones = num % 10
  MENU_DEF.AddNumWindow(SN_WIN, 0, 9, ones)
  MENU_DEF.AddNumWindow(SN_WIN, 0, 9, (num - ones) / 10)
  waitFalse(function()
    return funcLuaCommand(CMND_IS_OPENING, SN_WIN)
  end)
  waitTrue(function()
    return funcLuaCommand(CMND_IS_CLOSE_MENU_OBJECT, SN_WIN)
  end)
  funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, SN_CURSOR, 0, true)
  funcLuaMenuCommand(CMND_SET_MENU_INPUT, SN_MENU, true)
  M.edit, M.forced = nil, false
  SnRefreshRows()
end

function BetterUI.shirt_number_change(a1)
  local other = SnDup(a1)
  funcLuaMenuCommand(CMND_NUM_WIN_DUP_POPUP, SN_WIN, other, other ~= 0 and not SnFree(other))
end

-- (unless he may share it) the window stays open on him and cannot be cancelled until his number is unique
function BetterUI.shirt_number_done(a1)
  if a1 < 0 then
    if not M.forced then
      funcLuaCommand(CMND_CLOSE_MENU_OBJECT, SN_WIN)
    end
    return
  end
  local other, otherIdx = SnDup(a1)
  local old, myIdx = SnNum(M.edit)
  if myIdx == nil then
    funcLuaCommand(CMND_CLOSE_MENU_OBJECT, SN_WIN)
    return
  end
  funcLuaCommand(CMND_TEAM_SET_NUMBER, SnTeam(), M.type, a1, myIdx)
  UiLog("set", M.edit, old, "->", a1)
  if other ~= 0 then
    funcLuaCommand(CMND_TEAM_SET_NUMBER, SnTeam(), M.type, old or 0, otherIdx)
    UiLog("swap", other, a1, "->", old)
    if SnFree(other) then
      M.forced = false
      funcLuaCommand(CMND_CLOSE_MENU_OBJECT, SN_WIN)
    else
      M.prev, M.edit, M.forced = M.edit, other, true
      funcLuaMenuCommand(CMND_NUM_WIN_RESET, SN_WIN)
      funcLuaMenuCommand(CMND_NUM_WIN_DUP_POPUP, SN_WIN, M.prev, not SnFree(M.prev))
      funcLuaMenuCommand(CMND_NUM_WIN_REFRESH, SN_WIN)
    end
  else
    M.forced = false
    funcLuaCommand(CMND_CLOSE_MENU_OBJECT, SN_WIN)
  end
  SnRefreshRows()
end

-- the retail number window (MENU_DEF.OpenNumDigitWindow) calls its callbacks by global name
BetterUI_ShirtNumberChange = BetterUI.shirt_number_change
BetterUI_ShirtNumberDone = BetterUI.shirt_number_done

local snInit = OnInit
OnInit = function(...)
  SnReadMode()
  return snInit(...)
end

local snInfo = InitPerformanceChangeMenuInfo
InitPerformanceChangeMenuInfo = function(a1, ...)
  M.team = a1
  return snInfo(a1, ...)
end

local snSetup = OnSetupLayer
OnSetupLayer = function(a1, a2, ...)
  local r = Pack(snSetup(a1, a2, ...))
  if M.on and a1 == SN_LIST then
    SnHideTitle()
  end
  return table.unpack(r, 1, r.n)
end

local snUpdate = UpdateListItem
UpdateListItem = function(a1, a2, a3, a4, ...)
  local r = Pack(snUpdate(a1, a2, a3, a4, ...))
  if M.on and a1 == SN_ITEM and a3 ~= nil then
    M.rows[a2] = a3
    if a4 then
      M.cur = a3
    end
    SnSetRowText(a2, a3)
    SnHideTitle()
  end
  return table.unpack(r, 1, r.n)
end

local snDecide = OnDecideFocus
OnDecideFocus = function(a1, a2, ...)
  if M.on and a1 == SN_LIST then
    return SnOpenNumber()
  end
  return snDecide(a1, a2, ...)
end
