--@lib ../_src/better_qol/cutin_skip.lua#Head
local BETTERQOL_XS_MATCH_BGM = 1904593249
local BETTERQOL_XS_RIVAL_SHOWN = 1776220081    -- PARAM 0x69DEF7B1 (retail: set when the own screen closes)

local betterqol_xs_close_now = false            -- direct jump: the menu is closed by the next Step, without a fade

local betterqol_xs_prev_loaded = OnLayerLoadCompleted
function OnLayerLoadCompleted(...)
  local go = BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.GO) == 1
  local jump = go and BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.JUMP) == 1
  if go then
    VRFW.param.set(BETTERQOL_XS_RIVAL_SHOWN, true, "plain")
    pcall(funcLuaCommand, BETTERQOL_XS_MATCH_BGM)
    BetterQoL.cutin_skip.log("match BGM started (lineup screens skipped)")
    if BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.COVER) == 1 then
      pcall(funcLuaCommand, BetterQoL.cutin_skip.FADE, 1, 0)
      BetterQoL.cutin_skip.set(BetterQoL.cutin_skip.BLACK0, 1)          -- checked again at the kick-off button (xs_restart.lua)
      BetterQoL.cutin_skip.uncover(0, "lineup screens (layer 0 black)")
    end
  end
  BetterQoL.cutin_skip.disarm("lineup screens")
  if jump then
    betterqol_xs_close_now = true
    BetterQoL.cutin_skip.log("lineup screens skipped -> kick-off (direct jump: closed under black, kick-off fades in)")
    return
  end
  if go then
    BetterQoL.cutin_skip.log("lineup screens skipped -> kick-off")
    StartGoToSoccerGame()
    return
  end
  return betterqol_xs_prev_loaded(...)
end

-- Keeps the cover black while the lineup layers load.
local function BetterQoLXsLineupStep(prev)
  return function(...)
    if betterqol_xs_close_now then
      betterqol_xs_close_now = false
      local ok, err = pcall(function()
        CloseCommonTimer()
        funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, 1853845420 --[[soccer_battle_setting_flow_vs_menu]])
      end)
      BetterQoL.cutin_skip.log("lineup group closed (direct jump)", tostring(ok), tostring(err))
      return
    end
    local ok, err = pcall(function()
      if BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.GO) == 1 and BetterQoL.cutin_skip.get(BetterQoL.cutin_skip.COVER) == 1 then
        BetterQoL.cutin_skip.cover(0)
        BetterQoL.cutin_skip.hold()
      end
    end)
    if not ok then
      BetterQoL.cutin_skip.log("lineup step error", tostring(err))
    end
    return prev(...)
  end
end
if not (type(VRFW.host) == "table" and type(VRFW.host.wrap) == "function" and VRFW.host.wrap("Step", BetterQoLXsLineupStep)) then
  Step = BetterQoLXsLineupStep(Step)
end
