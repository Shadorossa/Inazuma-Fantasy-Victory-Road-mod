
local EDITOR_FLAG = 0x2000000      -- match info flags: the retail pre-kick-off editor opens
local skips = 0

local ENABLED = true
do
  local ok, v = pcall(VRFW.files.config, "skip_prematch_editor")
  ENABLED = not (ok and v == false)
end

-- mi = the match info (rax at the site).
function BetterUI.SkipEditor(mi)
  local info = VRFW.memory.struct("MatchInfo", mi)
  local ok = info ~= nil
  if not ok then
    return false
  end
  local okf, flags = pcall(function() return info.flags end)
  if not okf or bit32.band(flags, EDITOR_FLAG) == 0 then
    return false
  end
  local oko, observer = pcall(function() return info.observer end)
  local okn, net = pcall(VRFW.call, "Net.IsSession")
  local okt, ty = pcall(function() return info.match_type end)
  ty = okt and ty or 255
  if oko and observer == 0 and okn and net == false then
    skips = skips + 1
    VRFW.log(string.format("prematch: pre-kick-off team editor skipped (offline, match type %d) -> walk-in [%d]", ty, skips))
    return true
  end
  VRFW.log(string.format("prematch: pre-kick-off team editor kept (network %s, observer %s, match type %d)",
    okn and tostring(net) or "?", oko and tostring(observer) or "?", ty))
  return false
end

VRFW.on("hook:PrematchEditor", function(ev)
  if not ENABLED then
    return nil
  end
  if BetterUI.SkipEditor(ev.regs.rax) then
    return { skip = true }
  end
  return nil
end)
