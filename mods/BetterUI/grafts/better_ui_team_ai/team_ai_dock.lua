BetterUI = type(BetterUI) == "table" and BetterUI or {}
do
  local STEM = "team_dock_formation_menu"
  local TEAM_AI_KEY = 216585116          -- crc32("better_ui_team_ai"): 1 = celebration list in AI-role mode
  local TEAM_AI_KEY_TYPE = 4205327680     -- crc32("better_ui_team_ai_type"): the dock's team type
  local TEAM_AI_TEXT = 2239751552
  local TEAM_AI_ROW = 101                 -- row id in the team commands window
  local SHIRT_NUMBERS_ROW = 100
  local PARAM_TEAM_TYPE = 4081600465      -- the dock's team type, consumed by retail OnInit

  BetterUI_TeamAIDock = BetterUI_TeamAIDock or {}
  local D = BetterUI_TeamAIDock
  D.teamType = D.teamType or 0
  D.armed = false

  local function set_param(key, value)
    VRFW.param.clear(key)
    VRFW.param.set(key, value)
  end

  if VRFW.list_rows ~= nil then
    local Rows = VRFW.list_rows
    Rows.add(Rows.TEAM_COMMANDS, {id = "BetterUI.team_ai", row = TEAM_AI_ROW, text = TEAM_AI_TEXT,
      after = SHIRT_NUMBERS_ROW,
      run = function(context)
        D.armed = true
        if PRINT ~= nil then
          pcall(PRINT, "BetterUI team_ai", "open AI settings, team type", D.teamType)
        end
        return context.retail(Rows.TEAM_COMMAND.GOAL_CELEBRATION)
      end})
  end

  if VRFW.host ~= nil then
    VRFW.host.on(STEM, "OnInit", {id = "BetterUI.team_ai_team_type", phase = "before", fn = function()
      D.teamType = 0
      if VRFW.param.has(PARAM_TEAM_TYPE) then
        D.teamType = VRFW.param.get(PARAM_TEAM_TYPE) or 0
      end
    end})
    -- the retail celebration command starts WaitExecPerfromanceChangeMenu through the global
    VRFW.host.on(STEM, "WaitExecPerfromanceChangeMenu", {id = "BetterUI.team_ai_mode", phase = "around",
      fn = function(next_handler, ...)
        if D.armed then
          set_param(TEAM_AI_KEY, 1)
          set_param(TEAM_AI_KEY_TYPE, D.teamType or 0)
        else
          VRFW.param.clear(TEAM_AI_KEY)
        end
        D.armed = false
        return next_handler(...)
      end})
  end
end
