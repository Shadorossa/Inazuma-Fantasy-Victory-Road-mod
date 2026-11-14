-- Internal: VRFW extra-time telops (rule engine): the period-end telop of a ruleset's match.
VRFW.extra_time_telop = VRFW.extra_time_telop or {}
do
  local C = {
    BREAK = VRFW.commands.VRFW_RULE_ENGINE_BREAK,
    STATE = VRFW.commands.VRFW_RULE_ENGINE_STATE,
    SET_SPRITE = 558735651,
    LOG = VRFW.commands.VRFW_LOG,         -- CMND_VRFW_LOG
  }
  local L_TEXT = 852785315          -- soccer05_02_timetelop_text
  local ATLAS = 3297212849          -- #/menu/00_soccer/soccer05/soccer05_02/<LG>/soccer05_02.g4tx
  local DUMMY = 3127472322          -- gtxt_timetelop01 (the mesh every telop picture is drawn in)
  local PERIOD_END = 7              -- telop type: the end of a period
  local PIC = {
    reg_end = 3103382739,           -- gtxt_timetelop_vrfw_reg_end
    et1_end = 1700369862,           -- gtxt_timetelop_vrfw_et1_end
    full_end = 4261068378,          -- gtxt_timetelop_vrfw_full_end
  }
  local NAME = {[3103382739] = "reg_end", [1700369862] = "et1_end", [4261068378] = "full_end"}
  local want = nil

  local function pick()
    local phase, nth = VRFW.host.command(C.BREAK)
    if type(phase) ~= "string" or phase == "" then return nil end
    nth = tonumber(nth) or 1
    if phase == "extra_time" then
      return nth >= 2 and PIC.et1_end or PIC.reg_end
    end
    local r = table.pack(VRFW.host.command(C.STATE))
    return (r[8] == true) and PIC.full_end or PIC.reg_end
  end

  local prev_setup = SetupTimeTelopInfo
  if type(prev_setup) == "function" and VRFW.extra_time_telop.setup ~= SetupTimeTelopInfo then
    --- Internal: wrapped setup function; remembers the telop wanted for the extra time.
    VRFW.extra_time_telop.setup = function(a1, a2, a3, a4, ...)
      local r = table.pack(prev_setup(a1, a2, a3, a4, ...))
      want = nil
      if a4 == PERIOD_END then
        local ok, p = pcall(pick)
        want = ok and p or nil
        if want ~= nil then
          VRFW.host.command(C.LOG, "VRFW extra_time telop", NAME[want] or tostring(want))
        end
      end
      return table.unpack(r, 1, r.n)
    end
    SetupTimeTelopInfo = VRFW.extra_time_telop.setup
  end

  local prev_tex = UpdateUseTextureTelop
  if type(prev_tex) == "function" and VRFW.extra_time_telop.texture ~= UpdateUseTextureTelop then
    --- Internal: wrapped texture function; swaps the extra time telop texture.
    VRFW.extra_time_telop.texture = function(...)
      local r = table.pack(prev_tex(...))
      if want ~= nil then
        VRFW.host.menu_command(C.SET_SPRITE, L_TEXT, ATLAS, want, DUMMY, 0)
      end
      return table.unpack(r, 1, r.n)
    end
    UpdateUseTextureTelop = VRFW.extra_time_telop.texture
  end
end
