-- The team dock's shown page for mod scripts (docs/framework/team-dock.md «The shown page»): a mod that mounts other
-- pages of docks on the team dock writes the page, any script reads it. Stored in game_state, so every script VM sees it.
--   local TeamDock = require "VRFW/lib/team_dock"
--   TeamDock.page()        -> the page of docks shown (0-based), 0 when no page is mounted (mod off, story, not ready)
--   TeamDock.set_page(n)   the mod that mounts pages: n = the page now (0-based), -1 = its pages are off
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

function TeamDock.page()
  local v = number_at(PAGE_KEY)
  if v ~= nil and v >= 0 then
    return v
  end
  return 0
end

function TeamDock.set_page(n)
  n = type(n) == "number" and math.floor(n) or -1
  if number_at(PAGE_KEY) ~= n then
    pcall(VRFW.state.set, PAGE_KEY, n)
  end
end

return TeamDock
