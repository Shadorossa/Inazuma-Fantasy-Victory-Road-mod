-- Aura Points › the aura commands of the framework's reader (VRFW/lib/auras), with this mod's rule: an armour's own
-- move is a spirit move too. Adds publish() for the native answers.
--   local A = require "lib/auras"
--   A.load(); A.type(id); A.key(id); A.spirit(id); A.is_spirit_move(id); A.aura_move(id); A.armours_of(keshin)

local Auras = require "VRFW/lib/auras"

local M = setmetatable({}, { __index = Auras })

local WITH_ARMOURS = true

function M.is_spirit_move(id)
  return Auras.is_spirit_move(id, WITH_ARMOURS)
end

-- Fill SpiritStaminaPoints.Aura (aura id -> { type, pool = 1 when it runs on a pool }) for the native answers
-- (content\game\aura_points.toml) and the other mods that read it. `is_pool(id)`: the aura runs on a pool now.
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
  pcall(VRFW.native.table_replace, "SpiritStaminaPoints.Aura", nil, auras)
  return n_pool, n_moves
end

return M
