-- Advanced: The last owners of the ball in a match, used to name the player who assisted a goal.
local M = {}

local LENGTH = 8

--- Advanced: A new, empty chain.
function M.new()
  return {}
end

--- Advanced: Adds `owner` of `team` as the ball's new owner; answers false when `owner` already held it.
function M.push(chain, owner, team)
  local n = #chain
  if n > 0 and chain[n][1] == owner then
    return false
  end
  if n == LENGTH then
    table.remove(chain, 1)
  end
  chain[#chain + 1] = { owner, team }
  return true
end

--- Advanced: The teammate of `team` who gave `scorer` the ball; nil when the goal had no assist.
function M.assist(chain, scorer, team)
  local n = #chain
  local seen = false
  for i = 1, n do
    if chain[i][1] == scorer then
      seen = true
    end
  end
  if seen and chain[n][1] ~= scorer then
    return nil
  end
  local k = n
  while k > 0 and chain[k][1] == scorer do
    k = k - 1
  end
  if k > 0 and chain[k][2] == team and chain[k][1] ~= scorer then
    return chain[k][1]
  end
  return nil
end

return M
