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

-- Layers of soccer_inplay_menu.
local UI_HIDE_LAYERS = {
  [@crc:soccer00_15_zone_area_title@] = 1,
}
local CMND_OPEN_LAYER = @crc:CMND_OPEN_LAYER@
local CMND_OPEN_LAYER_ARRAY = @crc:CMND_OPEN_LAYER_ARRAY@
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local UI_FLAG = "zone_hud"

local function UiMenuFilter(orig, id, ...)
  if not UiOn(UI_FLAG) then
    return nil
  end
  if id == CMND_SET_LAYER_VISIBLE then
    local a = Pack(...)
    if UI_HIDE_LAYERS[a[1]] and a[3] == true then
      a[3] = false
      return Pack(orig(id, table.unpack(a, 1, a.n)))
    end
  elseif id == CMND_OPEN_LAYER or id == CMND_OPEN_LAYER_ARRAY then
    local layer = ...
    if UI_HIDE_LAYERS[layer] then
      local r = Pack(orig(id, ...))
      for i = 0, UI_HIDE_LAYERS[layer] - 1 do
        pcall(orig, CMND_SET_LAYER_VISIBLE, layer, i, false)
      end
      UiLog("hide", layer)
      return r
    end
  end
  return nil
end

UiHookMenuCommand(UiMenuFilter)

local function UiAfterLayer(a1, a2)
  if UiOn(UI_FLAG) and UI_HIDE_LAYERS[a1] and type(funcLuaMenuCommand) == "function" then
    funcLuaMenuCommand(CMND_SET_LAYER_VISIBLE, a1, a2 or 0, false)
  end
end
UiWrapCallback("OnSetupLayer", UiAfterLayer)
UiWrapCallback("OnOpenLayer", UiAfterLayer)
