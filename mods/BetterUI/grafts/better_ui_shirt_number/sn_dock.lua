-- ===== EVT better_ui shirt_number BEGIN =====
do
local better_ui_block = function()
BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

if BetterUI.preset == nil then
  BetterUI.preset = "limpio"
end
BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, corner_buttons = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, shirt_number = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

@UI_WRAP@

BetterUI.flags.shirt_number = true
-- Parameter keys of team_dock_formation_menu.
local SN_KEY = 1715129561            -- param store: 1 = open the celebration screen in shirt-number mode
local SN_KEY_TYPE = 1943979971  -- param store: team type of this dock
local SN_TEXT_CMD = 547784217   -- menu_text of the shirt-number settings row
local SN_ROW = 100
local SN_PARAM_TEAM_TYPE = 4081600465 -- retail OnInit reads (and consumes) the dock's team type here

BetterUI.shirt_number = BetterUI.shirt_number or {}
local S = BetterUI.shirt_number
S.teamType = S.teamType or 0
S.armed = false

function S.on()
  return UiOn("shirt_number")
end

function S.arm()
  S.armed = true
end

local function SnSetParam(key, v)
  VRFW.param.clear(key)
  VRFW.param.set(key, v)
end

local function SnReadTeamType()
  S.teamType = 0
  if VRFW.param.has(SN_PARAM_TEAM_TYPE) then
    S.teamType = VRFW.param.get(SN_PARAM_TEAM_TYPE) or 0
  end
end

local function SnArmCelebrationMenu()
  if S.armed and S.on() then
    SnSetParam(SN_KEY, 1)
    SnSetParam(SN_KEY_TYPE, S.teamType or 0)
  else
    VRFW.param.clear(SN_KEY)
  end
  S.armed = false
end

-- On a VRFW.host dock the two steps are host handlers
local SN_STEM = "team_dock_formation_menu"
if type(VRFW.host) == "table" and type(VRFW.host.on) == "function" then
  VRFW.host.on(SN_STEM, "OnInit", {id = "BetterUI.shirt_number_team_type", phase = "before", fn = SnReadTeamType})
  -- Retail case 4 runs coroutine.create(WaitExecPerfromanceChangeMenu) through the global, so the host hook wraps that global.
  VRFW.host.on(SN_STEM, "WaitExecPerfromanceChangeMenu", {id = "BetterUI.shirt_number_mode", phase = "before",
    fn = SnArmCelebrationMenu})
elseif not S.wrapped then
  S.wrapped = true
  local init = OnInit
  if type(init) == "function" then
    OnInit = function(...)
      SnReadTeamType()
      return init(...)
    end
  end
  local perf = WaitExecPerfromanceChangeMenu
  if type(perf) == "function" then
    WaitExecPerfromanceChangeMenu = function(...)
      SnArmCelebrationMenu()
      return perf(...)
    end
  end
end

-- Builds the per-player popup without its shirt-number entry.
if VRFW.list_rows ~= nil then
  local Rows = VRFW.list_rows
  Rows.hide(Rows.PLAYER_COMMANDS, {id = "BetterUI.hide_shirt_number", row = Rows.PLAYER_COMMAND.SHIRT_NUMBER,
    when = function() return S.on() end})
  Rows.add(Rows.TEAM_COMMANDS, {id = "BetterUI.shirt_numbers", row = SN_ROW, text = SN_TEXT_CMD,
    when = function() return S.on() end,
    run = function(context)
      S.armed = true
      UiLog("open shirt numbers")
      return context.retail(Rows.TEAM_COMMAND.GOAL_CELEBRATION)
    end})
end


end
better_ui_block()
end
-- ===== EVT better_ui shirt_number END =====
