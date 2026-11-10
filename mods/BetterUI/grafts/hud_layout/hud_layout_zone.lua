-- sits lower so it clears the LB tactics ring at the bottom left.

BetterUI = BetterUI or {}
BetterUI.hud_layout = BetterUI.hud_layout or {}
BetterUI.hud_layout.ZONE_EXEC_DY = -100        -- layout units (+ = up): bar at y 23..83
BetterUI.hud_layout.ZONE_EXEC_DX = 0

local HLZ_LAYER = 2456741170 --[[soccer08_18_zone_exec_chara]]
local HLZ_CMND_POS = @crc:CMND_SET_LAYER_LOCAL_POS@

--@lib vrfw_menu_kit.lua#Pack,ParamPerMille

local function HLZ_Apply()
  if type(funcLuaMenuCommand) == "function" then
    pcall(funcLuaMenuCommand, HLZ_CMND_POS, HLZ_LAYER, BetterUI.hud_layout.ZONE_EXEC_DX, BetterUI.hud_layout.ZONE_EXEC_DY, 0, 0)
  end
end

local function HLZ_Wrap(name, onlyLayer)
  VRFW.host.wrap_once(name, "BetterUI.hud_layout.zone", function(previous, a1, ...)
    local r = Pack(previous(a1, ...))
    if not onlyLayer or a1 == HLZ_LAYER then
      pcall(HLZ_Apply)
    end
    return table.unpack(r, 1, r.n)
  end)
end

HLZ_Wrap("OnSetupLayer", true)
HLZ_Wrap("OnOpenLayer", true)
HLZ_Wrap("SetupZoneExecChara", false)

-- (1 = full, 0 = over) goes to the parameter store as per-mille (key better_ui_hl_timeline_zone)
BetterUI.hud_layout.TIMELINE_ON = true

local HLZ_TL_KEY = 1199734162 --[[better_ui_hl_timeline_zone]]
local hlz_logged = false             -- one log line per zone menu
local hlz_prevLimit = rawget(_ENV, "UpdateZoneLimitTimer")
if type(hlz_prevLimit) == "function" then
  rawset(_ENV, "UpdateZoneLimitTimer", function(...)
    local r = Pack(hlz_prevLimit(...))
    local rate = ...
    if BetterUI.hud_layout.TIMELINE_ON and type(rate) == "number" and rate == rate and type(funcLuaCommand) == "function" then
      if not hlz_logged then
        hlz_logged = true
        pcall(funcLuaCommand, @crc:CMND_VRFW_LOG_DEBUG@, "EVT hud_layout timeline", "zone rate", rate)
      end
      SetParamPerMille(HLZ_TL_KEY, rate)
    end
    return table.unpack(r, 1, r.n)
  end)
end
