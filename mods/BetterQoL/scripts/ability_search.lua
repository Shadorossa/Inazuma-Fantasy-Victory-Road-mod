-- Technique name search of the ability list (assets/lua/ability_list_menu/900_technique_search.lua): after each
-- build of the list, only the rows the menu matched stay; rows it has not judged yet wait in `pending`.
local Memory = VRFW.memory

-- CMenuListViewAbility: rows at +0x19F10 (16 bytes each, item id at +4), count at +0x26710 (docs/game/ui/miximax-partner-bank.md §6)
local LIST = { ENTRIES = 0x19F10, ENTRY_SIZE = 0x10, ENTRY_ITEM = 0x4, COUNT = 0x26710, CAPACITY = 0xC80 }
local WORDS = 4      -- u32 words of a row
local ITEM_WORD = 2  -- the word of the item id (+4)

local search = { on = false, view = 0, decided = {}, pending = {}, serial = 0 }

local function live()
  return VRFW.is_on("BetterQoL.AbilityListBuild")
end

-- the rows of the list as WORDS columns of u32 (row r of column w = word w of row r); nil when not readable
local function read_columns(view, n)
  local columns = {}
  for w = 1, WORDS do
    columns[w] = Memory.read_array("u32", view + LIST.ENTRIES + 4 * (w - 1), n, LIST.ENTRY_SIZE)
    if type(columns[w]) ~= "table" then
      return nil
    end
  end
  return columns
end

-- keeps rows `kept` (row numbers, in order) at the head of the list, zero-fills the rest
local function write_rows(view, columns, n, kept)
  for w = 1, WORDS do
    local column = {}
    for k, r in ipairs(kept) do
      column[k] = columns[w][r]
    end
    for k = #kept + 1, n do
      column[k] = 0
    end
    if Memory.write_array("u32", view + LIST.ENTRIES + 4 * (w - 1), column, LIST.ENTRY_SIZE) == false then
      return false
    end
  end
  return Memory.write("u32", view + LIST.COUNT, #kept) ~= false
end

VRFW.on("hook:BetterQoL.AbilityListBuild:post", function(ev)
  if not search.on then
    return nil
  end
  local view = ev.args[1]
  if not Memory.is_pointer(view) or (search.view ~= 0 and search.view ~= view) then
    return nil
  end
  search.view = view
  search.serial = search.serial + 1
  search.pending = {}
  local n = Memory.read("u32", view + LIST.COUNT)
  if type(n) ~= "number" or n == 0 or n > LIST.CAPACITY then
    return nil
  end
  local columns = read_columns(view, n)
  if columns == nil then
    VRFW.warn(string.format("ability search: list 0x%X not readable: its %d rows stay", view, n))
    return nil
  end
  local kept = {}
  for r = 1, n do
    local item = columns[ITEM_WORD][r]
    local decided = search.decided[item]
    if decided == nil then
      search.pending[#search.pending + 1] = item
    elseif decided then
      kept[#kept + 1] = r
    end
  end
  if #kept < n and not write_rows(view, columns, n, kept) then
    VRFW.warn(string.format("ability search: list 0x%X not writable: its %d rows stay", view, n))
  end
  return nil
end)

-- -> live: a new search (nothing judged yet; the next build holds every row back until the menu judges it)
function BetterQoL.AbilitySearchStart()
  search = { on = true, view = 0, decided = {}, pending = {}, serial = search.serial + 1 }
  return live()
end

-- -> live: no search; the next build keeps the game's rows
function BetterQoL.AbilitySearchStop()
  search = { on = false, view = 0, decided = {}, pending = {}, serial = search.serial + 1 }
  return live()
end

-- -> serial (one more per build), n, item1, ...: the rows of the last build the menu has not judged
function BetterQoL.AbilitySearchPending()
  return search.serial, #search.pending, table.unpack(search.pending)
end

-- matched, item1, ... -> true: the first `matched` items match the search, the others do not
function BetterQoL.AbilitySearchDecide(matched, ...)
  local items = { ... }
  matched = type(matched) == "number" and matched or 0
  for i, item in ipairs(items) do
    if type(item) == "number" then
      search.decided[item] = i <= matched
    end
  end
  return true
end
