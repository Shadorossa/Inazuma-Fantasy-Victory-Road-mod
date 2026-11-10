
local Auras = VRFW.auras

local M = setmetatable({}, { __index = Auras })

local WITH_ARMOURS = true

function M.is_spirit_move(id)
  return Auras.is_spirit_move(id, WITH_ARMOURS)
end

function M.publish(is_pool)
  local auras, n_pool, seen = {}, 0, {}
  for _, id in ipairs(Auras.ids()) do
    if not seen[id] and is_pool(id) then
      seen[id] = true
      auras[#auras + 1] = { id, { type = Auras.type(id), pool = 1 } }
      n_pool = n_pool + 1
    end
  end
  local n_moves = 0
  for _ in pairs(Auras.spirit_moves(WITH_ARMOURS)) do n_moves = n_moves + 1 end
  pcall(VRFW.native.table_replace, "CharacterReforged.PointsAura", nil, auras)
  return n_pool, n_moves
end

return M
