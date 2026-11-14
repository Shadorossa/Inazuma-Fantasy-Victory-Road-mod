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

-- ability_learning_board_menu
-- Header dock layers.
local HD_LAYERS = { @HD_LAYERS@ }
local HD_CHECK = { @HD_CHECK@ }
local CMND_SET_LAYER_LOCAL_POS = @crc:CMND_SET_LAYER_LOCAL_POS@
local CMND_SET_LAYER_LOCAL_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@
local CMND_IS_OPEN_MENU_OBJECT = @crc:CMND_IS_OPEN_MENU_OBJECT@
local HEADER_LAYER = @crc:mainmenu90_01_header@        -- mainmenu90_01_header
local hd_done = {}
local hd_check_raw = "-"

local function HdActive()
  if not UiOn("header_short") then
    return false
  end
  if type(funcLuaCommand) ~= "function" then
    return false
  end
  for _, m in ipairs(HD_CHECK) do
    local ok, r = pcall(funcLuaCommand, CMND_IS_OPEN_MENU_OBJECT, m, HEADER_LAYER)
    hd_check_raw = tostring(ok) .. ":" .. tostring(r)
    if ok and r ~= nil and r ~= false and r ~= 0 then
      return true
    end
  end
  return false
end

local function HdPlace(a1, a2)
  if type(a1) ~= "number" or HD_LAYERS[a1] == nil or type(funcLuaMenuCommand) ~= "function" then
    return
  end
  local idx = type(a2) == "number" and a2 or 0
  local t = HD_LAYERS[a1]
  local active = HdActive()
  if active then                  -- inactive: no call at all, the layer keeps its retail state
    funcLuaMenuCommand(CMND_SET_LAYER_LOCAL_SCALE, a1, t[3], t[3], 1, idx)
    funcLuaMenuCommand(CMND_SET_LAYER_LOCAL_POS, a1, t[1], t[2], 0, idx)
  end
  if hd_done[a1] == nil then
    hd_done[a1] = true
    UiLog("header_dock", a1, idx, active and "in bar" or "retail (no compact header)", hd_check_raw)
  end
end

-- OnSetupLayer places the layer when it is created
for _, cb in ipairs({ "OnSetupLayer", "OnOpenLayer" }) do
  if not UiWrapCallback(cb, HdPlace) then
    UiLog("error", "no " .. cb .. " to wrap")
  end
end
