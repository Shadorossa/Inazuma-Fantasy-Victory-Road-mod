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

-- Layer and mesh ids of soccer_area_title_menu.
local UI_LAYER = @crc:soccer00_14_area_title@
local UI_MESH = @crc:_mode_title01@
local UI_ZONE_TYPE = 3
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_SET_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
local ui_area_type = 0

local function UiHideNow()
  return UiOn("zone_hud") and ui_area_type == UI_ZONE_TYPE
end

local function UiApply()
  if type(funcLuaMenuCommand) ~= "function" then
    return
  end
  if UiHideNow() then
    funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, UI_LAYER, UI_MESH, false, 0)
    funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, UI_LAYER, 0, false)
  else
    funcLuaMenuCommand(CMND_SET_MESH_VISIBLE, UI_LAYER, UI_MESH, true, 0)
  end
end

-- anything that tries to show the layer / the title mesh again while a zone title is up stays hidden
local function UiMenuFilter(orig, id, ...)
  if not UiHideNow() then
    return nil
  end
  local a = Pack(...)
  if id == CMND_SET_LAYER_VISIBLE and a[1] == UI_LAYER and a[3] == true then
    a[3] = false
    return Pack(orig(id, table.unpack(a, 1, a.n)))
  elseif id == CMND_SET_MESH_VISIBLE and a[1] == UI_LAYER and a[2] == UI_MESH and a[3] == true then
    a[3] = false
    return Pack(orig(id, table.unpack(a, 1, a.n)))
  end
  return nil
end
UiHookMenuCommand(UiMenuFilter)

local ui_orig_setup = rawget(_ENV, "SetupAreaTitle")
if type(ui_orig_setup) == "function" then
  rawset(_ENV, "SetupAreaTitle", function(a1, ...)
    ui_area_type = a1 or 0
    local r = Pack(ui_orig_setup(a1, ...))
    local ok, err = pcall(UiApply)
    UiLog("area_title", a1, ok and "ok" or err)
    return table.unpack(r, 1, r.n)
  end)
end

UiWrapCallback("OnSetupLayer", function(a1, a2)
  if a1 == UI_LAYER then
    UiApply()
  end
end)

-- Defines OnOpenLayer when the retail script has none.
if rawget(_ENV, "OnOpenLayer") == nil then
  rawset(_ENV, "OnOpenLayer", function(a1, a2)
    if a1 == UI_LAYER then
      pcall(UiApply)
    end
  end)
end
