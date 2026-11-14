--- Advanced: Library: team dock page state.
local TeamDock = {}

-- the state key: declared by VRFW (content\game\team_editor.toml); the mod that mounts pages writes it
local PAGE_KEY = "vrfw.team_dock.page"

local function number_at(key)
  local ok, v = pcall(VRFW.state.get, key)
  if ok and type(v) == "number" then
    return math.floor(v)
  end
  return nil
end

--- Advanced: The team dock page shown.
function TeamDock.page()
  local v = number_at(PAGE_KEY)
  if v ~= nil and v >= 0 then
    return v
  end
  return 0
end

--- Internal: Sets the team dock page to `n`.
function TeamDock.set_page(n)
  n = type(n) == "number" and math.floor(n) or -1
  if number_at(PAGE_KEY) ~= n then
    pcall(VRFW.state.set, PAGE_KEY, n)
  end
end

return TeamDock
