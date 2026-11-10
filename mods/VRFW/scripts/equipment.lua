-- Equipment of a player, for the game's Lua (docs/internal/types/item.md §15).

-- PlayerEquipment: the framework's command handlers (content/game/equipment.toml)
PlayerEquipment = {}

function PlayerEquipment.Items(hdl)
  local ok, a, b, c, d = pcall(VRFW.item.equipped, tonumber(hdl) or 0)
  if not ok or a == nil then return end
  return a, b, c, d
end

function PlayerEquipment.SetPieces(hdl, name)
  if type(name) ~= "string" then return -1 end
  local ok, n = pcall(VRFW.item.set_pieces, tonumber(hdl) or 0, name)
  if not ok or n == nil then return -1 end
  return n
end
