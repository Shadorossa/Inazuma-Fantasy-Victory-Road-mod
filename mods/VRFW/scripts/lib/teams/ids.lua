-- Team ids at run time: the team_config id of a mod's new team named `<mod>.<name>` (content\teams, [[team]]).

local M = {}

local NEW_TEAM_PREFIX = "evt_te_"
local NEW_TEAM_DIGITS = 6

local by_key = nil   -- "<mod>.<name>" -> { key = declared game key or nil }

local crc = VRFW.crc32

local trim = VRFW.strings.trim

-- every active mod's [[team]] declarations, first declaration of a name kept (as the team build does)
local function load()
  by_key = {}
  local ok, files = pcall(VRFW.files.declarations, "content/teams")
  if not ok or type(files) ~= "table" then return end
  for _, f in ipairs(files) do
    local data = type(f.data) == "table" and f.data or {}
    for _, d in ipairs(type(data.team) == "table" and data.team or {}) do
      if type(d) == "table" and type(d.name) == "string" and d.name ~= "" and type(f.mod) == "string" then
        local name = trim(d.name)
        local full = name:find(".", 1, true) and name or (f.mod .. "." .. name)
        if by_key[full] == nil then
          local game_key = type(d.key) == "string" and trim(d.key) or ""
          by_key[full] = { key = game_key ~= "" and game_key or nil }
        end
      end
    end
  end
end

--- the team id of `<mod>.<name>`; nil when no active mod declares it or its number is not pinned yet
function M.of(full)
  if type(full) ~= "string" then return nil end
  if not by_key then load() end
  local d = by_key[trim(full)]
  if not d then return nil end
  if d.key then return crc(d.key) end
  if not (VRFW.ids and VRFW.ids.resolve) then return nil end
  local ok, n = pcall(VRFW.ids.resolve, "team", trim(full) .. "#team")
  if not ok or type(n) ~= "number" then return nil end
  return crc(NEW_TEAM_PREFIX .. string.format("%0" .. NEW_TEAM_DIGITS .. "d", math.floor(n) % 1000000))
end

return M
