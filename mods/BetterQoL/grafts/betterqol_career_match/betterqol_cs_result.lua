do
  BetterQoL = BetterQoL or {}
  BetterQoL.career_match_result = BetterQoL.career_match_result or {}
  local M = BetterQoL.career_match_result
  M.WRAPPED = M.WRAPPED or {}
  local cur = InitResultParam
  if type(cur) == "function" and not M.WRAPPED[cur] then
    local w = function(a1, ...)
      local r = cur(a1, ...)
      pcall(funcLuaCommand, 1076897207 --[[CMND_BETTERQOL_CAREER_MATCH]], a1 and 3 or 2)
      return r
    end
    M.WRAPPED[w] = true
    InitResultParam = w
  end
end
