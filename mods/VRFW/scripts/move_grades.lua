-- Starting move grades: a saved player's move is never below the grade his card declares (`VRFW.MoveGrades`, docs/internal/types/character.md).

local Memory = VRFW.memory
local u32, hex = VRFW.ids.unsigned, VRFW.ids.hex_text

local info = VRFW.logger("move_grades")

-- the saved record: handle, card, then 6 list entries of 8 bytes at +0x50 (move id, then the rank byte)
local REC_LIST, LIST_ENTRY, LIST_SLOTS, ENTRY_RANK = 0x50, 8, 6, 4
local REC_WORDS = math.floor((REC_LIST + LIST_SLOTS * LIST_ENTRY) / 4)
local SAVED_KINDS = { [0] = true, [7] = true }
local LOG_MAX = 24

local grades_by_card = {}
local sweep_pending = false
local logged = 0

-- move id -> the card's declared grade (the framework's answer, cached per card until the mods' data changes)
local function grades_of(card)
  local c = grades_by_card[card]
  if c then return c end
  c = {}
  local ok, list = pcall(VRFW.traits.move_grades, card)
  if ok and type(list) == "table" then
    for _, e in ipairs(list) do
      local m, g = u32(e[1]), tonumber(e[2]) or 0
      if m ~= 0 and g > 0 and c[m] == nil then c[m] = g end
    end
  end
  grades_by_card[card] = c
  return c
end

local function is_saved(hdl)
  return hdl ~= 0 and SAVED_KINDS[math.floor(hdl / 4096) % 16] == true
end

-- Raises every list move of the saved record at `rec` to its declared grade; returns the (move, old, new) texts.
local function raise_record(rec)
  local w = rec and rec >= 0x10000 and Memory.read_array("u32", rec, REC_WORDS)
  if type(w) ~= "table" or not is_saved(u32(w[1])) then return nil end
  local declared = grades_of(u32(w[2]))
  if next(declared) == nil then return nil end
  local changes = {}
  for i = 0, LIST_SLOTS - 1 do
    local k = math.floor(REC_LIST / 4) + i * 2 + 1
    local id, rank = u32(w[k]), (w[k + 1] or 0) % 256
    local g = declared[id]
    -- aura and spirit moves have no grade
    if g and g > rank and VRFW.auras.type(id) == nil and not VRFW.auras.is_spirit_move(id)
        and Memory.write("u8", rec + REC_LIST + i * LIST_ENTRY + ENTRY_RANK, g) then
      changes[#changes + 1] = string.format("(%s, %d, %d)", hex(id), rank, g)
    end
  end
  if #changes > 0 and logged < LOG_MAX then
    logged = logged + 1
    info(string.format("chara %s (card %s): moves at their starting grades [%s]", hex(u32(w[1])), hex(u32(w[2])), table.concat(changes, ", ")))
  end
  return #changes
end

-- Every saved player of the loaded slot, once per load: the ones whose list the game does not rebuild.
local function sweep()
  sweep_pending = false
  local ok, columns = pcall(VRFW.character.saved_columns, { "handle", "param" })
  if not ok or type(columns) ~= "table" then return end
  local players, moves = 0, 0
  for n, handle in ipairs(columns.handle) do
    local h = u32(handle)
    if is_saved(h) and next(grades_of(u32(columns.param[n]))) ~= nil then
      local okR, r = pcall(VRFW.character.record, h)
      local raised = okR and type(r) == "table" and raise_record(r.addr) or 0
      if raised > 0 then players, moves = players + 1, moves + raised end
    end
  end
  info(string.format("slot sweep: %d move(s) raised to their starting grade on %d saved player(s) (%d scanned)", moves, players, #columns.handle))
end

VRFW.on("chara:moves:post", function(ev)
  local obj = ev.args and ev.args[1] or 0
  if obj >= 0x10000 then raise_record(Memory.read("ptr", obj + 8)) end
  if sweep_pending then sweep() end
end)
VRFW.on("menu:open:post", function()
  if sweep_pending then sweep() end
end)
VRFW.on("save:slot_load", function() sweep_pending = true end)
VRFW.on("game:reset", function()
  grades_by_card = {}
  sweep_pending = false
end)
