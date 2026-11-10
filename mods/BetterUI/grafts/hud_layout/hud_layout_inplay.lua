
BetterUI = BetterUI or {}
BetterUI.hud_layout = BetterUI.hud_layout or {}
BetterUI.hud_layout.CMDR_X = 960               -- centre x of the guides, layout units from the left (screen centre)
BetterUI.hud_layout.CMDR_HALF_W = 137
BetterUI.hud_layout.CMDR_TOP = 165
BetterUI.hud_layout.CMDR_GAP = 57              -- distance between stacked guides (retail)
BetterUI.hud_layout.CMDR_SQUARE = true         -- square blue plate instead of the pill
BetterUI.hud_layout.CMDR_ERROR_BELOW = 1       -- error bubble this many gaps under the lowest guide
BetterUI.hud_layout.SCREEN_H = 1080

local HLC_ATTACH = 1132565342 --[[soccer00_66_change_ai_mode_button_attach]]
local HLC_GUIDE = 2446662467 --[[soccer00_67_change_ai_mode_button]]
local HLC_ERROR = 3087830238 --[[soccer00_58_common_error_message]]
local HLC_LOC_X = 102
local HLC_LOC_Y = {141, 198, 255} --[[instances 0, 1, 2]]
local HLC_ERR_X, HLC_ERR_Y = 261, 258
local HLC_CMND_POS = @crc:CMND_SET_LAYER_LOCAL_POS@
local HLC_CMND_SWAP = 558735651
local HLC_ATLAS_0808 = 1822283221 --[[#/menu/00_soccer/soccer08/soccer08_08/<LG>/soccer08_08.g4tx]]
local HLC_PLATE = 2905228853 --[[cmd_base01]]
local HLC_SLOT = 3394469048 --[[ai_guide_base01: nine-slice pill of soccer00_67]]
local hlc_swapped = false


-- Computes the attach layer offset.
local function HLC_AttachOffset()
  local ax = BetterUI.hud_layout.CMDR_X - BetterUI.hud_layout.CMDR_HALF_W - HLC_LOC_X
  local ay = (BetterUI.hud_layout.SCREEN_H - BetterUI.hud_layout.CMDR_TOP) - HLC_LOC_Y[2]
  return ax, ay
end

local function HLC_Swap()
  hlc_swapped = true
  if not BetterUI.hud_layout.CMDR_SQUARE then
    return
  end
  for i = 0, 2 do
    VRFW.host.menu_command(HLC_CMND_SWAP, HLC_GUIDE, HLC_ATLAS_0808, HLC_PLATE, HLC_SLOT, 0, i)
  end
end

local function HLC_Place()
  local ax, ay = HLC_AttachOffset()
  local top = HLC_LOC_Y[2] + ay
  VRFW.host.menu_command(HLC_CMND_POS, HLC_ATTACH, ax, ay, 0, 0)
  -- Instance 0 is already one gap under instance 1.
  VRFW.host.menu_command(HLC_CMND_POS, HLC_GUIDE, 0, 0, 0, 0)
  VRFW.host.menu_command(HLC_CMND_POS, HLC_GUIDE, 0, 0, 0, 1)
  VRFW.host.menu_command(HLC_CMND_POS, HLC_GUIDE, 0, (top - 2 * BetterUI.hud_layout.CMDR_GAP) - (HLC_LOC_Y[3] + ay), 0, 2)
  local ey = top - (2 + BetterUI.hud_layout.CMDR_ERROR_BELOW) * BetterUI.hud_layout.CMDR_GAP
  VRFW.host.menu_command(HLC_CMND_POS, HLC_ERROR, BetterUI.hud_layout.CMDR_X - (HLC_ERR_X + ax), ey - (HLC_ERR_Y + ay), 0, 0)
end

--@lib vrfw_block_helpers.lua#WrapAfter

local function HLC_OnLayer(a1)
  if a1 == HLC_GUIDE then
    HLC_Swap()
  end
  if a1 == HLC_ATTACH or a1 == HLC_GUIDE or a1 == HLC_ERROR then
    HLC_Place()
  end
end

WrapAfter("BetterUI.hud_layout.inplay", "OnSetupLayer", HLC_OnLayer)
WrapAfter("BetterUI.hud_layout.inplay", "OnOpenLayer", HLC_OnLayer)
local function HLC_Frame()
  if not hlc_swapped then
    HLC_Swap()
  end
  HLC_Place()
end
-- soccer_inplay_menu has PostStep (include), soccer_setplay_prev_menu has Step.
WrapAfter("BetterUI.hud_layout.inplay", "PostStep", HLC_Frame)
WrapAfter("BetterUI.hud_layout.inplay", "Step", HLC_Frame)
