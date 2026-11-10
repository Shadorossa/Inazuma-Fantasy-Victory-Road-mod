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
