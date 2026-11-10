-- ===== EVT better_ui deluxe_badge BEGIN =====
do
local better_ui_block = function()
BetterUI = type(BetterUI) == "table" and BetterUI or {}
local BETTER_UI_SIGNATURE = "BETTER_UI_GRAFT"

if BetterUI.preset == nil then
  BetterUI.preset = "limpio"
end
BetterUI.flags = BetterUI.flags or {}
for k, v in pairs({ bank_sort_guide = true, buff_icons = true, buff_panel = false, corner_buttons = true, deluxe_badge = true, duel_telop = true, enemy_meters = true, esc_guide = true, exec_offset = true, header_short = true, nickname_pill = true, team_param_guide = true, zone_exec = false, zone_hud = true }) do
  if BetterUI.flags[k] == nil then
    BetterUI.flags[k] = v
  end
end

@UI_WRAP@

BetterUI.flags.deluxe_badge = true
-- Layer and mesh ids of title_menu_2.
local UI_DX_LAYER = 3427392471
local UI_DX_MESHES = {
  2781781827,
  1714296966,
  1667304963,
  3487882952,
  2381063373,
}
local UI_DX_LOWER = 3873872512   -- fallback focus: the lower button row
local UI_DX_OWNED = 2127863466
local CMND_SET_MESH_VISIBLE = 3405944500
local CMND_SET_LAYER_VISIBLE = 711242136
local CMND_IS_OPEN_LAYER = 2640875187
local CMND_GET_CREATE_LAYER_NUM = 1175615627
local CMND_SET_ENABLE_CTRL_FOCUS = 3518307824
local CMND_SET_HIT_ZONE = 855005857       -- (layer, idx, bool): the instance's mouse zone
local CMND_SET_ON_CHANGE_FOCUS_MOUSE = 2206938151
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
