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

-- Layout of soccer_team_buff_icon_list_menu.
local UI_BUFF_S = 0.85
local UI_BUFF_DX = -5.4
local UI_BUFF_DY = -7.65
local UI_BUFF_LAYERS = {
  [@crc:soccer00_51_team_buff_icon@] = true,
  [@crc:soccer00_51_team_buff_icon_super_tactics@] = true,
  [@crc:soccer00_51_team_buff_icon_technical_combo@] = true,
  [@crc:soccer00_53_aura_buff_chara_icon@] = true,
}
local CMND_SET_LAYER_LOCAL_POS = @crc:CMND_SET_LAYER_LOCAL_POS@
local CMND_SET_LAYER_LOCAL_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@
local ui_buff_logged = false

local function UiMenuFilter(orig, id, ...)
  if id ~= CMND_SET_LAYER_LOCAL_POS or not UiOn("buff_icons") then
    return nil
  end
  local a = Pack(...)
  if not UI_BUFF_LAYERS[a[1]] or type(a[2]) ~= "number" then
    return nil
  end
  a[2] = a[2] * UI_BUFF_S + UI_BUFF_DX
  a[3] = (a[3] or 0) + UI_BUFF_DY
  local r = Pack(orig(id, table.unpack(a, 1, a.n)))
  pcall(orig, CMND_SET_LAYER_LOCAL_SCALE, a[1], UI_BUFF_S, UI_BUFF_S, 1, a[5] or 0)
  if not ui_buff_logged then
    ui_buff_logged = true
    UiLog("buff_scale", UI_BUFF_S, a[1], a[2], a[5])
  end
  return r
end

UiHookMenuCommand(UiMenuFilter)
