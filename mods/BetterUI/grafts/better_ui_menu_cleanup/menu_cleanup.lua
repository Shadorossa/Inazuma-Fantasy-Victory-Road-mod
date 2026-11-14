-- ===== EVT better_ui menu_cleanup BEGIN =====
do
local better_ui_block = function()
BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, corner_buttons = true, enemy_meters = true, esc_guide = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_hud = true }) do
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

-- Mode top menus (soccer_top_menu, chronicle_mode_top_menu, bb_stadium_top_menu)

-- declared data ----------------------------------------------------------------------------------------------------
local UI_MC_CORNERS = {
  [@crc:mainmenu90_24_02_play_guide_button@] = "controls guide",
  [@crc:mainmenu90_24_tutorial_button@] = "tutorial",
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
local UI_MC_CURSOR = @crc:cursor@

-- engine commands ----------------------------------------------------------------------------------------------------
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_SET_ENABLE_CTRL_FOCUS = @crc:CMND_SET_ENABLE_CTRL_FOCUS@
local CMND_SET_HIT_ZONE = @crc:CMND_SET_MENU_COLLISION_HIT_ALL@          -- (layer, idx, bool): the instance's mouse zone
local CMND_ATTACH_TRACE = @crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@         -- (layer, idx, locator, bool): the cursor follows the instance
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
