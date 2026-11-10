do
  BetterQoL = BetterQoL or {}
  BetterQoL.career_match_hud = BetterQoL.career_match_hud or {}
  local M = BetterQoL.career_match_hud
  M.CMD = 1076897207
  VRFW.host.wrap_once("OnInit", "BetterQoL.career_match", function(orig, ...)
    local r = orig(...)
    local ok, v = pcall(funcLuaCommand, M.CMD, 1)
    M.ON = ok and type(v) == "number"
    return r
  end)
  VRFW.host.wrap_once("Step", "BetterQoL.career_match", function(orig, ...)
    local r = orig(...)
    if M.ON then
      local ok, v = pcall(funcLuaCommand, M.CMD, 0)
      if not ok or type(v) ~= "number" then
        M.ON = false
      end
    end
    return r
  end)
end
