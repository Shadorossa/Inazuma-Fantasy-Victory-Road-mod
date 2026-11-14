-- VRFW extra-time half label (rule engine): the scoreboard's half picture of the match HUD.
do
  local C = {
    BREAK = VRFW.commands.VRFW_RULE_ENGINE_BREAK,
    SET_SPRITE = 558735651,
    LOG = VRFW.commands.VRFW_LOG,         -- CMND_VRFW_LOG
  }
  local ATLAS = 4109108046          -- #/menu/00_soccer/soccer00/soccer00_01/<LG>/soccer00_01.g4tx
  local DUMMY = 2834393702          -- gtxt_half01 (the label's mesh)
  local PIC = {2822503542, 825404876}   -- gtxt_half_vrfw_et1 / _et2 (extra-time half 1 / 2)
  local last = nil

  local prev = SwapLayerGamePhaseHalfIconTex
  if type(prev) == "function" and VRFW.extra_time_half_label ~= SwapLayerGamePhaseHalfIconTex then
    --- Internal: Retail wrap: labels the extra-time half; answers the previous results.
    VRFW.extra_time_half_label = function(half, ...)
      local r = table.pack(prev(half, ...))
      local ok, phase, nth = pcall(funcLuaCommand, C.BREAK)
      local pic = nil
      if ok and phase == "extra_time" then
        pic = PIC[tonumber(nth) or 0]
      end
      local shown = "retail"
      if pic ~= nil and type(LAYER_NAME_CRC_SCOREBOARD) == "number" then
        local set = pcall(funcLuaMenuCommand, C.SET_SPRITE, LAYER_NAME_CRC_SCOREBOARD, ATLAS, pic, DUMMY, 0)
        shown = set and ("extra_time " .. tostring(nth)) or "extra_time (sprite NOT set)"
      end
      local key = tostring(half) .. " " .. shown
      if key ~= last then
        last = key
        pcall(funcLuaCommand, C.LOG, "VRFW extra_time half label", tostring(half), tostring(ok and phase or "?"), shown)
      end
      return table.unpack(r, 1, r.n)
    end
    SwapLayerGamePhaseHalfIconTex = VRFW.extra_time_half_label
  end
end
