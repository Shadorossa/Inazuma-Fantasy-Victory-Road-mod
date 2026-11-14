-- the focus stopwatch (soccer08_23_focus_count_down, bar_time01) gets in UpdateFocusCountDownTimer /
BetterUI = BetterUI or {}
BetterUI.hud_layout = BetterUI.hud_layout or {}
BetterUI.hud_layout.TIMELINE_ON = true

local HLF_KEY = 3795993759 --[[better_ui_hl_timeline_focus]]
local HLF_LAYER = 3070268158 --[[soccer08_23_focus_count_down]]
local HLF_MESH = 1261530200 --[[bar_time01]]
local HLF_CMND_RATE = 1595998683

--@lib vrfw_menu_kit.lua#Pack,ParamPerMille

local function HLF_Spy(prev, ...)
  local real = rawget(_ENV, "funcLuaMenuCommand")
  if not BetterUI.hud_layout.TIMELINE_ON or type(real) ~= "function" then
    return prev(...)
  end
  local seen
  rawset(_ENV, "funcLuaMenuCommand", function(...)
    local c, layer, mesh, _, v = ...
    if c == HLF_CMND_RATE and layer == HLF_LAYER and mesh == HLF_MESH and type(v) == "number" then
      seen = v
    end
    return real(...)
  end)
  local r = Pack(pcall(prev, ...))
  rawset(_ENV, "funcLuaMenuCommand", real)
  if not r[1] then
    error(r[2], 0)
  end
  if seen ~= nil and seen == seen and type(funcLuaCommand) == "function" then
    SetParamPerMille(HLF_KEY, seen)
  end
  return table.unpack(r, 2, r.n)
end

local function HLF_Wrap(name)
  VRFW.host.wrap_once(name, "BetterUI.hud_layout.focus", HLF_Spy)
end

HLF_Wrap("UpdateFocusCountDownTimer")
HLF_Wrap("UpdateSkillDecideCountDownTimer")

-- Versus name plates (rival on top, «CONTRA» between, the player below; retail layer soccer08_01, the root the plate
-- instances hang from): the whole block sits lower, nearer the bottom edge, with its internal spacing kept.
-- The offset is applied to the root layer when it opens or sets up; engine calls only from those callbacks.
BetterUI.hud_layout.FOCUS_VS_DY = -90          -- layout units (+ = up): the plates' bottom edge moves from y ~192 to ~102
BetterUI.hud_layout.FOCUS_VS_DX = 0

local HLF_VS_LAYER = 1752673562 --[[soccer08_01_focus_battle_self_status_attach_locator]]
local HLF_VS_CMND_POS = 1389957207 --[[CMND_SET_LAYER_LOCAL_POS]]

local function HLF_VsApply()
  if type(funcLuaMenuCommand) == "function" then
    pcall(funcLuaMenuCommand, HLF_VS_CMND_POS, HLF_VS_LAYER, BetterUI.hud_layout.FOCUS_VS_DX, BetterUI.hud_layout.FOCUS_VS_DY, 0, 0)
  end
end

local function HLF_VsWrap(name)
  VRFW.host.wrap_once(name, "BetterUI.hud_layout.focus_vs", function(previous, a1, ...)
    local r = Pack(previous(a1, ...))
    if a1 == HLF_VS_LAYER then
      pcall(HLF_VsApply)
    end
    return table.unpack(r, 1, r.n)
  end)
end

HLF_VsWrap("OnSetupLayer")
HLF_VsWrap("OnOpenLayer")
