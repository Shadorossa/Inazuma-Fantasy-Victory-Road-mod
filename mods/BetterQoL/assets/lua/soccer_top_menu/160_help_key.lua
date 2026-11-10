-- BetterQoL › the V key of the main menu (retail CMD_FUNC3, OnFunction 1643904886) opens the Help screen instead of the
-- controls guide window. The retail WaitExecHelpWindow keeps switching the menu off and on: only its open and its wait change.
if VRFW.host ~= nil and type(WaitExecHelpWindow) == "function" then
  local THIS_MENU = 811496143              -- soccer_top_menu
  local HELP_MENU = 948899592              -- help_menu
  local OPEN_CONTROLS_GUIDE = 2398648456   -- retail: opens the controls guide window
  local CONTROLS_GUIDE_OPEN = 2968794903   -- retail: true while that window is open
  local CTRL_FOCUS_ACTIVE = 102308320      -- (layer) -> the layer holds the input focus
  local FOCUS_INSTANCE = 2603265800        -- (layer) -> the focused instance
  local SET_FOCUS_INSTANCE = 3466097042    -- (layer, instance)
  local SET_ENABLE_CTRL_FOCUS = 3518307824 -- (layer, on)
  local SET_CURSOR_LOCATOR = 381797568     -- (layer, locator, instance, instance count)
  local CURSOR_LOCATOR = 3313461902        -- cursor
  local INSTANCE_COUNT = VRFW.commands.GET_CREATE_LAYER_NUM
  local SUSPEND_LAYER_GROUP = 369172623    -- (menu) -> the menu's layers leave the screen
  local RESUME_LAYER_GROUP = 66378409      -- (menu)
  local OPEN_MENU_OBJECT = VRFW.commands.OPEN_MENU_OBJECT
  local IS_EXIST_MENU_OBJECT = VRFW.commands.IS_EXIST_MENU_OBJECT
  local CLEAR_PARAM, SET_PARAM = 3363400568, 3860611758
  local HELP_MODE, HELP_CLOSER = 3288069995, 633992871
  local FULL_TAB_MODE = 4                  -- help_menu: every tab (retail value of play_guide_top_menu)
  local BUTTON_GUIDE_CHILD_MENU, BUTTON_GUIDE_TOP_MENU = 16, 10
  local HEADER_MAIN_MENU_TEXT = 1846856871
  -- the layers V is read on; the one with focus gets it back when the Help screen closes
  local FOCUS_LAYERS = {
    3887253505, -- mainmenu90_10_list_item_large
    530619243,  -- mainmenu90_12_list_item_small
    3687874606, -- mainmenu90_24_tutorial_button
    4096284290, -- mainmenu90_24_02_play_guide_button
  }

  -- The layer that holds the focus and its instance; nil when none does.
  local function focused_layer()
    for _, layer in ipairs(FOCUS_LAYERS) do
      if funcLuaMenuCommand(CTRL_FOCUS_ACTIVE, layer) then
        return layer, funcLuaMenuCommand(FOCUS_INSTANCE, layer)
      end
    end
    return nil, nil
  end

  -- Opens the Help screen like play_guide_top_menu; the menu's layers leave the screen meanwhile.
  local function open_help()
    funcLuaMenuCommand(SUSPEND_LAYER_GROUP, THIS_MENU)
    UpdateButtonGuideFromTopMenu(BUTTON_GUIDE_CHILD_MENU)
    funcLuaCommand(OPEN_MENU_OBJECT, HELP_MENU)
    funcLuaCommand(CLEAR_PARAM, HELP_MODE)
    funcLuaCommand(SET_PARAM, HELP_MODE, 0, FULL_TAB_MODE, 1)
    funcLuaCommand(CLEAR_PARAM, HELP_CLOSER)
    funcLuaCommand(SET_PARAM, HELP_CLOSER, 0, HELP_MENU, 1)
  end

  -- The menu's layers come back and the focus returns to where V was pressed.
  local function restore_menu(layer, instance)
    funcLuaMenuCommand(RESUME_LAYER_GROUP, THIS_MENU)
    if layer ~= nil then
      funcLuaMenuCommand(SET_ENABLE_CTRL_FOCUS, layer, true)
      funcLuaMenuCommand(SET_FOCUS_INSTANCE, layer, instance)
      funcLuaMenuCommand(SET_CURSOR_LOCATOR, layer, CURSOR_LOCATOR, instance, funcLuaMenuCommand(INSTANCE_COUNT, layer))
    end
    UpdateButtonGuideFromTopMenu(BUTTON_GUIDE_TOP_MENU)
    SwapSoccerTopCommonHeaderByHeaderType(0, HEADER_MAIN_MENU_TEXT)
  end

  VRFW.host.wrap_once("WaitExecHelpWindow", "BetterQoL.help_key", function(next, ...)
    local layer, instance = focused_layer()
    local results = table.pack(VRFW.host.with_commands({
      menu = {
        [OPEN_CONTROLS_GUIDE] = function() open_help() return true end,
        [CONTROLS_GUIDE_OPEN] = function() return funcLuaMenuCommand(IS_EXIST_MENU_OBJECT, HELP_MENU) end,
      },
    }, next, ...))
    restore_menu(layer, instance)
    return table.unpack(results, 1, results.n)
  end)
end
