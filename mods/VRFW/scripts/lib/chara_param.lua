-- Advanced: The game's chara_param rows in memory (Game.Root + CharaParams.Table; offsets from the game profile's structs.toml).

local M = {}

local rd, wr = VRFW.memory.read, VRFW.memory.write

local layout = nil     -- the profile offsets, read once
local index = nil      -- { base = row array pointer, rows = { [card id] = row address } }
local originals = {}   -- [card id] = the element the row had before this library first wrote it

local function u32(v)
  return math.floor(tonumber(v) or 0) % 0x100000000
end

-- Returns the profile offsets of the table, nil when one of them does not resolve on this build.
local function offsets()
  if layout ~= nil then return layout or nil end
  local f = VRFW.game.field
  local t = { table = f("CharaParams.Table"), rows = f("CharaParams.Rows"), count = f("CharaParams.Count"),
    size = f("CharaParamRow.Size"), element = f("CharaParamRow.Element") }
  for _, key in ipairs({ "table", "rows", "count", "size", "element" }) do
    if type(t[key]) ~= "number" then
      layout = false
      return nil
    end
  end
  layout = t
  return t
end

-- Returns the row address of every card, rebuilt when the game moved its row array; nil while the table is not loaded.
local function rows()
  local L = offsets()
  if not L then return nil end
  local root = VRFW.game.global("Game.Root")
  local tbl = root and rd("ptr", root + L.table)
  local base = tbl and rd("ptr", tbl + L.rows)
  local n = tbl and rd("i32", tbl + L.rows + L.count)
  if not base or not n or n <= 0 then return nil end
  if index and index.base == base and index.n == n then return index.rows end
  local map = {}
  for i = 0, n - 1 do
    local at = base + i * L.size
    local id = rd("u32", at)
    if id then map[id] = at end
  end
  index = { base = base, n = n, rows = map }
  return map
end

--- Advanced: The element of card `card` in the game's memory; nil when the card or the table is not there.
function M.element(card)
  local map = rows()
  local at = map and map[u32(card)]
  return at and rd("u8", at + layout.element) or nil
end

--- Advanced: Writes `element` (0..255) as the element of card `card` in the game's memory: true when written.
function M.set_element(card, element)
  local id, v = u32(card), math.floor(tonumber(element) or -1)
  if v < 0 or v > 255 then return false end
  local map = rows()
  local at = map and map[id]
  if not at then return false end
  if originals[id] == nil then originals[id] = rd("u8", at + layout.element) end
  return wr("u8", at + layout.element, v) and true or false
end

--- Advanced: Gives every card this library wrote its element back; answers how many were restored and { [card id] = element }.
function M.restore_elements()
  local n, back = 0, {}
  for id, v in pairs(originals) do
    if M.set_element(id, v) then
      n = n + 1
      back[id] = v
    end
  end
  originals = {}
  return n, back
end

return M
