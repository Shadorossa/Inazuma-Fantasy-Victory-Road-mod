-- VRFW table columns: a few named columns of a game table as the game loads it (the mods overlay's served file, else
-- the game's). VRFW.table.rows builds every column of every row by name and by position: a wide table of thousands of
-- rows (chara_base, chara_model) takes about 20 MB of a script's memory for as long as its rows are kept. This reads
-- only the asked columns (VRFW.table.source + VRFW.table.raw).
-- M.read(id, list, names) -> rows, at: rows holding only those columns, at[name] = the column's position (read a value
-- as row[at.name]); nil, why when the table or a column cannot be read. Keep the values needed, not the rows.
local M = {}

function M.read(id, list, names)
  if type(VRFW.table) ~= "table" or type(VRFW.table.raw) ~= "function" then return nil, "no table service" end
  local okc, cols = pcall(VRFW.table.columns, id)
  if not okc or type(cols) ~= "table" then return nil, tostring(cols) end
  local position = {}
  for i, name in ipairs(cols) do position[name] = i end
  local at, wanted = {}, {}
  for _, name in ipairs(names) do
    local i = position[name]
    if i == nil then return nil, id .. ": no column " .. tostring(name) end
    at[name] = i
    wanted[#wanted + 1] = i
  end
  local oks, key = pcall(VRFW.table.source, id)
  if not oks or type(key) ~= "string" then return nil, tostring(key) end
  local okr, rows = pcall(VRFW.table.raw, key, list, wanted)
  if not okr or type(rows) ~= "table" then return nil, tostring(rows) end
  return rows, at
end

return M
