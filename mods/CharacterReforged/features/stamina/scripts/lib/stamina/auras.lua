
local Auras = VRFW.auras
local u32 = VRFW.ids.unsigned

local M = setmetatable({}, { __index = Auras })

local MIXIMAX = 2

M.MIXIMAX_CARRIERS = {}

local carriers = {}
local carriers_read = false

function M.set_carriers(list)
  M.MIXIMAX_CARRIERS = type(list) == "table" and list or {}
end

function M.load()
  if not carriers_read then
    carriers_read = true
    for _, k in ipairs(M.MIXIMAX_CARRIERS) do
      if type(k) == "number" then carriers[u32(k)] = true else carriers[u32(VRFW.crc32(tostring(k)))] = true end
    end
  end
  return Auras.load()
end

function M.is_miximax(id)
  return id ~= nil and id ~= 0 and (Auras.type(id) == MIXIMAX or carriers[id] == true)
end

function M.publish(cfg)
  local auras, seen = {}, {}
  local function rec(id, r)
    local x = { aura = 1, type = r and r.type or 2 }
    if M.is_miximax(id) then x.miximax = 1 end
    local ty = x.miximax and 2 or x.type
    if cfg.free_activation(ty) then x.free = 1 end
    if cfg.start_check_waived(ty) then x.waived = 1 end
    auras[#auras + 1] = { id, x }
  end
  for _, id in ipairs(Auras.ids()) do
    if not seen[id] then
      seen[id] = true
      rec(id, Auras.row(id))
    end
  end
  for c in pairs(carriers) do
    if not Auras.row(c) then rec(c, nil) end
  end
  pcall(VRFW.native.table_replace, "CharacterReforged.PointsStaminaAura", nil, auras)
  return #auras
end

return M
