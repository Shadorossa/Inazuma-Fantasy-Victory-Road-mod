
local M = {}

function M.own_moves(A, ctx)
  local set = {}
  if not ctx then return set end
  local function add(id)
    if not id or id == 0 then return end
    local m = A.aura_move(id)
    if m and m ~= 0 and A.is_spirit_move(m) and A.type(m) == nil then set[m] = true end
  end
  add(ctx.aura)
  add(ctx.key)
  if ctx.key and ctx.key ~= 0 and A.armours_of then
    for _, ar in ipairs(A.armours_of(ctx.key)) do add(ar) end
  end
  return set
end

-- Is `move` one of the running spirit's own moves?
function M.is_own_move(A, ctx, move)
  if not ctx or not move or move == 0 then return false end
  return M.own_moves(A, ctx)[move] == true
end

function M.route(A, P, ctx, ids, cost)
  if not ctx then return "tension", nil end
  local own = M.own_moves(A, ctx)
  for _, id in ipairs(ids or {}) do
    if id and id ~= 0 and own[id] then
      if ctx.armour and not ctx.soul and P.armour_moves_free() then return "armour_free", id end
      return "spirit", id
    end
  end
  if not ctx.armour and not ctx.soul and P.keshin_moves_all_peg() and (cost or 0) > 0 then
    for _, id in ipairs(ids or {}) do
      if id and id ~= 0 then return "keshin_out_peg", id end
    end
    return "keshin_out_peg", 0
  end
  return "tension", nil
end

return M
