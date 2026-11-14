--- Advanced: Library of match difficulty rows by level, read from match_difficulty.toml.
local M = {}

local FILE = "content/defaults/match_difficulty.toml"

local ROWS = nil
local AT_LEVEL = nil
local LEVEL_OF = nil

--- Internal: Every difficulty row.
function M.rows()
  if ROWS ~= nil then
    return ROWS
  end
  ROWS = {}
  local ok, files = pcall(VRFW.files.declarations, FILE)
  if not ok or type(files) ~= "table" then
    return ROWS
  end
  for _, f in ipairs(files) do
    local md = type(f.data) == "table" and f.data.MatchDifficulty or nil
    if type(md) == "table" then
      for id, t in pairs(md) do
        if type(t) == "table" then
          ROWS[id] = ROWS[id] or {}
          for k, x in pairs(t) do ROWS[id][k] = x end
        end
      end
    end
  end
  return ROWS
end

local function indexes()
  if AT_LEVEL ~= nil then
    return
  end
  AT_LEVEL, LEVEL_OF = {}, {}
  for _, m in pairs(M.rows()) do
    local row, level = tonumber(m.Difficulty), tonumber(m.Level)
    if row and level then
      row, level = math.floor(row), math.floor(level)
      LEVEL_OF[row] = level
      if m.Enabled ~= false then
        AT_LEVEL[level] = AT_LEVEL[level] or {}
        table.insert(AT_LEVEL[level], row)
      end
    end
  end
  for _, list in pairs(AT_LEVEL) do table.sort(list) end
end

--- Internal: The difficulty rows of level `level`, as an array.
function M.rows_at_level(level)
  indexes()
  return AT_LEVEL[level] or {}
end

--- Internal: The level of difficulty row `row`.
function M.level_of(row)
  indexes()
  return LEVEL_OF[row]
end

return M
