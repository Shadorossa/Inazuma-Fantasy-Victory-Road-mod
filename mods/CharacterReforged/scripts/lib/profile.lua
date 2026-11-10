local M = {}

function M.field(name)
  local ok, v = pcall(VRFW.game.field, name)
  if ok and type(v) == "number" then return v end
  return nil
end

return M
