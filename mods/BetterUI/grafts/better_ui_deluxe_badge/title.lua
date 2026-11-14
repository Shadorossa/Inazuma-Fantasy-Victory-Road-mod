-- ===== EVT better_ui deluxe_badge BEGIN =====
do
local better_ui_block = function()
BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, corner_buttons = true, deluxe_badge = true, enemy_meters = true, esc_guide = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_hud = true }) do
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

BetterUI.flags.deluxe_badge = true
-- Layer and mesh ids of title_menu_2.
local UI_DX_LAYER = @crc:title02_21_dlc_buy_btn@
local UI_DX_MESHES = {
  @crc:_buy_btn_base01@,
  @crc:_buy_btn_ok01@,
  @crc:_buy_btn_ol01@,
  @crc:_icon_check_buy01@,
  @crc:_icon_buy01@,
}
local UI_DX_LOWER = @crc:title00_07_item_button_lower@   -- fallback focus: the lower button row
local UI_DX_OWNED = 2127863466
local CMND_SET_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
local CMND_SET_LAYER_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_IS_OPEN_LAYER = @crc:CMND_IS_OPEN_LAYER@
local CMND_GET_CREATE_LAYER_NUM = @crc:CMND_GET_CREATE_LAYER_NUM@
local CMND_SET_ENABLE_CTRL_FOCUS = @crc:CMND_SET_ENABLE_CTRL_FOCUS@
local CMND_SET_HIT_ZONE = @crc:CMND_SET_MENU_COLLISION_HIT_ALL@       -- (layer, idx, bool): the instance's mouse zone
local CMND_SET_ON_CHANGE_FOCUS_MOUSE = @crc:CMND_SET_ON_CHANGE_FOCUS_MOUSE@
local CMND_FOCUS_INSTANCE = 1778826357    -- (layer, idx, bool): retail OnFunction moves the focus with it
local ui_dx_logged = false

local function UiDxOwned()
  return VRFW.host.command(UI_DX_OWNED) == true
end

local function UiDxApply()
  if not UiOn("deluxe_badge") or not VRFW.host.menu_command(CMND_IS_OPEN_LAYER, UI_DX_LAYER, 0) then
    return
  end
  local owned = UiDxOwned()
  if not ui_dx_logged then
    ui_dx_logged = true
    UiLog("deluxe_badge owned", owned)
  end
  VRFW.host.menu_command(CMND_SET_ENABLE_CTRL_FOCUS, UI_DX_LAYER, false)
  local n = VRFW.host.menu_command(CMND_GET_CREATE_LAYER_NUM, UI_DX_LAYER)
  if type(n) ~= "number" or n < 1 then
    n = 1
  end
  for i = 0, n - 1 do
    VRFW.host.menu_command(CMND_SET_HIT_ZONE, UI_DX_LAYER, i, false)
    VRFW.host.menu_command(CMND_SET_ON_CHANGE_FOCUS_MOUSE, UI_DX_LAYER, i, false)
    for k = 1, #UI_DX_MESHES do
      VRFW.host.menu_command(CMND_SET_MESH_VISIBLE, UI_DX_LAYER, UI_DX_MESHES[k], false, i)
    end
    if not owned then
      VRFW.host.menu_command(CMND_SET_LAYER_VISIBLE, UI_DX_LAYER, i, false)
    end
  end
end

local function UiDxBounce()
  local layer, idx = UI_DX_LOWER, 0
  local gl, gi = rawget(_ENV, "GetSelectItemLayerName"), rawget(_ENV, "GetSelectItemIdx")
  if type(gl) == "function" and type(gi) == "function" then
    local l, i = gl(), gi()
    if type(l) == "number" and l ~= 0 and l ~= UI_DX_LAYER and type(i) == "number" then
      layer, idx = l, i
    end
  end
  VRFW.host.menu_command(CMND_SET_ENABLE_CTRL_FOCUS, UI_DX_LAYER, false)
  VRFW.host.menu_command(CMND_SET_ENABLE_CTRL_FOCUS, layer, true)
  VRFW.host.menu_command(CMND_FOCUS_INSTANCE, layer, idx, true)
end

do
  -- Applies the badge after the retail set-up of the button (texture, visibility, check or cart).
  local setup = rawget(_ENV, "SetupDlcBuyBtn_Coroutine")
  if type(setup) == "function" then
    rawset(_ENV, "SetupDlcBuyBtn_Coroutine", function(...)
      setup(...)
      local ok, err = pcall(UiDxApply)
      if not ok then
        UiLog("error", "deluxe_badge setup", err)
      end
    end)
  end
  local change = rawget(_ENV, "OnChangeFocus")
  if type(change) == "function" then
    rawset(_ENV, "OnChangeFocus", function(a1, ...)
      if a1 == UI_DX_LAYER and UiOn("deluxe_badge") then
        local ok, err = pcall(UiDxBounce)
        if not ok then
          UiLog("error", "deluxe_badge focus", err)
        end
        return
      end
      return change(a1, ...)
    end)
  end
  local enter = rawget(_ENV, "OnEnter")
  if type(enter) == "function" then
    rawset(_ENV, "OnEnter", function(a1, ...)
      if a1 == UI_DX_LAYER and UiOn("deluxe_badge") then
        return
      end
      return enter(a1, ...)
    end)
  end
end

-- Applies the badge again when the retail focus states show a mesh again.
UiWrapCallback("OnOpenLayer", function(a1)
  if a1 == UI_DX_LAYER then
    UiDxApply()
  end
end)
UiWrapCallback("OnChangeFocus", function()
  UiDxApply()
end)

end
better_ui_block()
end
-- ===== EVT better_ui deluxe_badge END =====
