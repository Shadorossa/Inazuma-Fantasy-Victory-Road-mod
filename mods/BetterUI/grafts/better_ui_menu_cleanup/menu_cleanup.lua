-- ===== EVT better_ui menu_cleanup BEGIN =====
do
local better_ui_block = function()
BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

if BetterUI.preset == nil then
  BetterUI.preset = "limpio"
end
BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, corner_buttons = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

@UI_WRAP@

-- Mode top menus (soccer_top_menu, chronicle_mode_top_menu, bb_stadium_top_menu)

-- declared data ----------------------------------------------------------------------------------------------------
local UI_MC_CORNERS = {
  [4096284290] = "controls guide",
  [3687874606] = "tutorial",
}
-- retail OnFunction ids of the corner buttons (soccer_top_menu / chronicle_mode_top_menu / bb_stadium_top_menu)
local UI_MC_CORNER_FN = {
  [1055436260] = true, -- list -> corner buttons
  [3860297742] = true, -- corner buttons -> list
  [1169567619] = true, -- corner buttons -> list (bb_stadium_top_menu)
  [3517640427] = true, -- corner up / down
  [1643904886] = true, -- V: the controls guide window
  [2666587639] = true, -- Alt: the tutorial
}
local UI_MC_TUTORIAL_RETURN = 207055258   -- temp value: the tutorial asks to come back on the tutorial button
local UI_MC_CURSOR = 3313461902

-- engine commands ----------------------------------------------------------------------------------------------------
local CMND_SET_LAYER_VISIBLE = 711242136
local CMND_SET_ENABLE_CTRL_FOCUS = 3518307824
local CMND_SET_HIT_ZONE = 855005857          -- (layer, idx, bool): the instance's mouse zone
local CMND_ATTACH_TRACE = 1774843228         -- (layer, idx, locator, bool): the cursor follows the instance
local CMND_SET_TEMP_VALUE = 2565779025

-- corner buttons ------------------------------------------------------------------------------------------------------
local function UiMcIsCorner(a1)
  return UI_MC_CORNERS[a1] ~= nil and UiOn("corner_buttons")
end

local ui_mc_corner_logged = {}
local function UiMcHideCorner(a1, a2)
  local i = a2 or 0
  VRFW.host.menu_command(CMND_SET_LAYER_VISIBLE, a1, i, false)
  VRFW.host.menu_command(CMND_SET_ENABLE_CTRL_FOCUS, a1, false)
  VRFW.host.menu_command(CMND_SET_HIT_ZONE, a1, i, false)
  VRFW.host.menu_command(CMND_ATTACH_TRACE, a1, i, UI_MC_CURSOR, false)
  if not ui_mc_corner_logged[a1] then
    ui_mc_corner_logged[a1] = true
    UiLog("menu_cleanup corner hidden", UI_MC_CORNERS[a1])
  end
end

-- callbacks -----------------------------------------------------------------------------------------------------------
do
  local init = rawget(_ENV, "OnInit")
  if type(init) == "function" then
    rawset(_ENV, "OnInit", function(...)
      if UiOn("corner_buttons") and type(funcLuaCommand) == "function" then
        VRFW.host.command(CMND_SET_TEMP_VALUE, UI_MC_TUTORIAL_RETURN, 0)
      end
      return init(...)
    end)
  end
  local setup = rawget(_ENV, "OnSetupLayer")
  if type(setup) == "function" then
    rawset(_ENV, "OnSetupLayer", function(a1, a2, ...)
      local r = Pack(setup(a1, a2, ...))
      if UiMcIsCorner(a1) then
        UiMcHideCorner(a1, a2)
      end
      return table.unpack(r, 1, r.n)
    end)
  end
  local open = rawget(_ENV, "OnOpenLayer")
  if type(open) == "function" then
    rawset(_ENV, "OnOpenLayer", function(a1, a2, ...)
      local r = Pack(open(a1, a2, ...))
      if UiMcIsCorner(a1) then
        UiMcHideCorner(a1, a2)
      end
      return table.unpack(r, 1, r.n)
    end)
  end
  local decide = rawget(_ENV, "OnDecideFocus")
  if type(decide) == "function" then
    rawset(_ENV, "OnDecideFocus", function(a1, ...)
      if UiMcIsCorner(a1) then
        return
      end
      return decide(a1, ...)
    end)
  end
  local enter = rawget(_ENV, "OnEnter")
  if type(enter) == "function" then
    rawset(_ENV, "OnEnter", function(a1, ...)
      if UiMcIsCorner(a1) then
        return
      end
      return enter(a1, ...)
    end)
  end
  local switch = rawget(_ENV, "SwitchLayerVisible")
  if type(switch) == "function" then
    rawset(_ENV, "SwitchLayerVisible", function(a1, a2, ...)
      local r = Pack(switch(a1, a2, ...))
      if a2 == true and type(a1) == "table" and UiOn("corner_buttons") then
        for _, layer in ipairs(a1) do
          if UI_MC_CORNERS[layer] ~= nil then
            VRFW.host.menu_command(CMND_SET_LAYER_VISIBLE, layer, 0, false)
          end
        end
      end
      return table.unpack(r, 1, r.n)
    end)
  end
  local fn = rawget(_ENV, "OnFunction")
  if type(fn) == "function" then
    rawset(_ENV, "OnFunction", function(a1, ...)
      if UI_MC_CORNER_FN[a1] and UiOn("corner_buttons") then
        UiLog("menu_cleanup corner function ignored", a1)
        return
      end
      return fn(a1, ...)
    end)
  end
end

end
better_ui_block()
end
-- ===== EVT better_ui menu_cleanup END =====
