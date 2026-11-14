
CharacterReforged = CharacterReforged or {}
CharacterReforged.BoardSlots = CharacterReforged.BoardSlots or {}
local BoardSlots = CharacterReforged.BoardSlots

local STATUS_OK, STATUS_REFUSED, STATUS_MISMATCH = 1, 0, 2
local STATUS_BAD_ARGUMENTS, STATUS_NOT_READY, STATUS_CLOSED, STATUS_EXCEPTION, STATUS_NO_RECORD = -1, -2, -3, -4, -5
local STATUS_WOULD_CLOSE = -6
local LAST_SLOT = 8

local handle_buffer, pieces_buffer = nil, nil

local Id = VRFW.ids
local u32 = Id.unsigned
local hex = Id.hex_text
local info, warn = VRFW.logger("board slots")

local read = VRFW.memory.read

local function buffers()
  handle_buffer = handle_buffer or VRFW.memory.buffer("character_reforged_board_slots_handle", 8)
  pieces_buffer = pieces_buffer or VRFW.memory.buffer("character_reforged_board_slots_pieces", 16)
end

local function slot_argument(v)
  local s = tonumber(v)
  if s == nil then return nil end
  s = math.floor(s)
  if s >= 0 and s <= LAST_SLOT then return s end
  return nil
end

-- the game profile's value of a name (lib/profile.lua)
local profile_field = require("lib/profile").field

local BOARD = nil
local board_warned = false
local function board_layout()
  if BOARD then return BOARD end
  local pieces, placed, native = profile_field("CharaData.BoardPieces"), profile_field("CharaData.PlacedSkills"),
    profile_field("CharaData.NativeSkills")
  if not pieces or not placed or not native then
    if not board_warned then
      board_warned = true
      warn("the game profile has no CharaData.BoardPieces / PlacedSkills / NativeSkills: the board slot commands are off")
    end
    return nil
  end
  BOARD = { pieces = pieces, placed = placed, native = native }
  return BOARD
end

-- the character data (record + 8) of a handle, or nil + status
local function character_data(hdl)
  if hdl == 0 then return nil, STATUS_BAD_ARGUMENTS end
  if not board_layout() then return nil, STATUS_NOT_READY end
  local ok, r = pcall(VRFW.character.record, hdl)
  if not ok then return nil, STATUS_EXCEPTION end
  if type(r) ~= "table" or not r.addr or r.addr < 0x10000 then return nil, STATUS_NO_RECORD end
  return r.addr
end

local function read_slot(data, slot)
  local piece = read("u8", data + BOARD.pieces + slot)
  local placed = read("u32", data + BOARD.placed + slot * 4)
  local native = read("u32", data + BOARD.native + slot * 4)
  if piece == nil or placed == nil or native == nil then return nil end
  return { piece = piece, placed = u32(placed), native = u32(native) }
end

local function is_closed(s) return s.piece >= 0x80 end
local function effective(s) if s.placed ~= 0 then return s.placed end return s.native end

local function definition(hdl)
  buffers()
  VRFW.memory.write("u32", handle_buffer, hdl)
  VRFW.memory.write("u64", pieces_buffer, 0)
  VRFW.memory.write("u64", pieces_buffer + 8, 0)
  local ok = pcall(VRFW.call, "CharacterReforged.BoardSkillPieces", pieces_buffer, handle_buffer)
  if not ok then return nil end
  local list, count = read("ptr", pieces_buffer), read("u64", pieces_buffer + 8)
  if not list or not count or list < 0x10000 or count > 16 then return nil end
  local def = { n = count }
  for k = 0, count - 1 do
    local p = read("u8", list + k * 2)
    if p == nil then return nil end
    def[k] = p
  end
  return def
end

-- the board definition's piece of a board slot (opens a closed slot), nil when unreadable / none
local function definition_piece(hdl, slot)
  local def = definition(hdl)
  if not def or slot >= def.n then return nil end
  local p = def[slot]
  if p ~= nil and p < 0x80 then return p end
  return nil
end

local AURA_SLOT = LAST_SLOT
local LAST_EFFECT = 59
local LAST_MOVE_SLOT = 5               -- board slots 0-5 are the skill table's move rows

-- is `piece` on board slot 8 the free aura piece (not a piece of the card's board definition)?
local function is_free_aura(hdl, slot, piece)
  if slot ~= AURA_SLOT or piece >= 0x80 then return false end
  local def = definition(hdl)
  if not def or def.n > AURA_SLOT then return false end
  for k = 0, def.n - 1 do
    if def[k] == piece then return false end
  end
  return true
end

-- an effect index neither the definition nor the other save bytes use, nil when the board has an aura piece or no room
local function free_aura_piece(data, hdl)
  local def = definition(hdl)
  if not def or def.n > AURA_SLOT then return nil end
  local used = {}
  for k = 0, def.n - 1 do used[def[k]] = true end
  for k = 0, LAST_SLOT do
    local b = read("u8", data + BOARD.pieces + k)
    if b ~= nil then used[b] = true end
  end
  for p = LAST_EFFECT, 0, -1 do
    if not used[p] then return p end
  end
  return nil
end

local function equip_slot(hdl, inv, slot, native)
  local ok, e = pcall(VRFW.call, "CharacterReforged.BoardEquipSlot", hdl, inv, slot, native and 1 or 0)
  if not ok then
    warn(string.format("EquipSlot(%s, %s, slot %d, native %s) raised: %s", hex(hdl), hex(inv), slot, tostring(native), tostring(e)))
    return STATUS_EXCEPTION
  end
  return nil
end

local function place_by_handle(hdl, piece, inv, native)
  buffers()
  VRFW.memory.write("u32", handle_buffer, hdl)
  local ok, e = pcall(VRFW.call, "CharacterReforged.BoardPlaceByHandle", handle_buffer, piece, inv, native and 1 or 0, 1, 1)
  if not ok then
    warn(string.format("PlaceByHandle(%s, piece %d, %s, native %s) raised: %s", hex(hdl), piece, hex(inv), tostring(native), tostring(e)))
    return STATUS_EXCEPTION
  end
  return nil
end

local function put(data, hdl, inv, slot)
  local before = read_slot(data, slot)
  if not before then return STATUS_NOT_READY, 0 end
  local piece = before.piece
  local free = not is_closed(before) and is_free_aura(hdl, slot, piece)
  if is_closed(before) then
    piece = definition_piece(hdl, slot)
    if not piece and slot == AURA_SLOT then
      piece = free_aura_piece(data, hdl)
      free = piece ~= nil
    end
    if not piece then return STATUS_CLOSED, effective(before) end
  end
  local okc, can = pcall(VRFW.call, "CharacterReforged.BoardCanEquip", hdl, inv, 1, 1, slot)
  if not okc then return STATUS_EXCEPTION, effective(before) end
  if (tonumber(can) or 0) % 256 == 0 then return STATUS_REFUSED, effective(before) end
  local st
  if free then
    if is_closed(before) then
      VRFW.memory.write("u8", data + BOARD.pieces + slot, piece)
      info(string.format("aura slot of %s opened with the free piece %d (his board has no aura piece)", hex(hdl), piece))
    end
    st = equip_slot(hdl, inv, slot, false)
  else
    st = place_by_handle(hdl, piece, inv, false)
  end
  if st then return st, effective(before) end
  local after = read_slot(data, slot)
  if not after then return STATUS_NOT_READY, 0 end
  local ok = not is_closed(after) and effective(after) == inv
  -- the game's list rebuild only reads a piece marked in openedEffectPieceList (right after the 9 piece bytes)
  if ok and not free and slot <= LAST_MOVE_SLOT and piece <= LAST_EFFECT then
    local flag = data + BOARD.pieces + LAST_SLOT + 1 + piece
    local was = read("u8", flag)
    if was == 0 then VRFW.memory.write("u8", flag, 1) end
    if was ~= 1 then info(string.format("slot %d of %s: piece %d opened flag %s -> %s", slot, hex(hdl), piece, tostring(was), tostring(read("u8", flag)))) end
  end
  if not ok then
    warn(string.format("slot %d after the write: piece %d placed %s native %s (wanted %s)", slot, after.piece, hex(after.placed), hex(after.native), hex(inv)))
  end
  return ok and STATUS_OK or STATUS_MISMATCH, effective(after)
end

local function clear(data, hdl, slot, keep_open, drop_native)
  local before = read_slot(data, slot)
  if not before then return STATUS_NOT_READY, 0 end
  if is_closed(before) then return STATUS_CLOSED, effective(before) end
  local piece = before.piece
  if is_free_aura(hdl, slot, piece) then
    if drop_native and before.native ~= 0 then
      local st = equip_slot(hdl, 0, slot, true)
      if st then return st, effective(before) end
    end
    if before.placed ~= 0 then
      local st = equip_slot(hdl, 0, slot, false)
      if st then return st, effective(before) end
    end
    local after = read_slot(data, slot)
    if not after then return STATUS_NOT_READY, 0 end
    local ok = after.placed == 0 and (not drop_native or after.native == 0)
    return ok and STATUS_OK or STATUS_MISMATCH, effective(after)
  end
  if drop_native and before.native ~= 0 then
    local st = place_by_handle(hdl, piece, 0, true)
    if st then return st, effective(before) end
    local now = read_slot(data, slot)
    if not now then return STATUS_NOT_READY, 0 end
    if is_closed(now) then VRFW.memory.write("u8", data + BOARD.pieces + slot, piece) end
    before = read_slot(data, slot) or now
    keep_open = true
  end
  if before.placed == 0 then return STATUS_OK, effective(before) end
  if before.native == 0 and not keep_open then return STATUS_WOULD_CLOSE, effective(before) end
  local st = place_by_handle(hdl, piece, 0, false)
  if st then return st, effective(before) end
  local after = read_slot(data, slot)
  if not after then return STATUS_NOT_READY, 0 end
  if is_closed(after) and keep_open and after.placed == 0 and after.native == 0 then
    VRFW.memory.write("u8", data + BOARD.pieces + slot, piece)
    after = read_slot(data, slot) or after
  end
  local ok = after.placed == 0 and not is_closed(after)
  return ok and STATUS_OK or STATUS_MISMATCH, effective(after)
end

function BoardSlots.Piece(hdl, slot)
  hdl, slot = u32(hdl), slot_argument(slot)
  if slot == nil then return STATUS_BAD_ARGUMENTS, 0, 0, 0 end
  local data, st = character_data(hdl)
  if not data then return st, 0, 0, 0 end
  local s = read_slot(data, slot)
  if not s then return STATUS_NOT_READY, 0, 0, 0 end
  return s.piece, effective(s), s.placed, s.native
end

local TECHNIQUE_LIST_ENTRY_BYTES = 8
local add_buffer = nil

local function added_copy_of(item)
  add_buffer = add_buffer or VRFW.memory.buffer("character_reforged_board_item_add", 64)
  VRFW.memory.write("u32", add_buffer, 0)
  if not pcall(VRFW.call, "CharacterReforged.ItemAdd", add_buffer, item, 1, 0) then return 0 end
  return u32(read("u32", add_buffer) or 0)
end

local function repair_cell(data, hdl, slot, cell, list_at)
  local move = 0
  if cell.native == 0 and list_at and slot <= LAST_MOVE_SLOT then
    move = u32(read("u32", data + list_at + slot * TECHNIQUE_LIST_ENTRY_BYTES) or 0)
  end
  local cleared = clear(data, hdl, slot, true, false)
  if cleared ~= STATUS_OK then return false, 0 end
  if move ~= 0 then
    local inv = added_copy_of(move)
    if inv ~= 0 and put(data, hdl, inv, slot) == STATUS_OK then return true, move end
  end
  return true, 0
end

-- Freed stacks repaired per call: the walk over the cells is the framework's, so one call stays within the script budget.
local FREED_STACKS_PER_CALL = 64
local repair_tried = {}

-- Inventory handles on the boards whose stack is free and not tried yet, at most FREED_STACKS_PER_CALL; nil before the roster loads.
local function freed_stacks()
  local ok, cell_count, handles = pcall(VRFW.character.board_freed_handles)
  if not ok or type(handles) ~= "table" or cell_count == 0 then return nil end
  local freed, more = {}, false
  for _, inv in ipairs(handles) do
    if not repair_tried[inv] then
      if #freed == FREED_STACKS_PER_CALL then
        more = true
        break
      end
      freed[#freed + 1] = inv
    end
  end
  return freed, more, cell_count
end

-- Repairs one freed stack on every placed cell that names it.
local function repair_stack(inv, list_at, counts)
  local ok, cells = pcall(VRFW.character.board_holders, inv)
  if not ok or type(cells) ~= "table" then return end
  for _, c in ipairs(cells) do
    local hdl, slot = u32(c.holder), c.slot - 1
    local data = c.kind == "placed" and character_data(hdl)
    local cell = data and read_slot(data, slot)
    if cell and cell.placed == inv then
      local done, move = repair_cell(data, hdl, slot, cell, list_at)
      if not done then
        counts.failed = counts.failed + 1
      elseif move ~= 0 then
        counts.restored = counts.restored + 1
      else
        counts.emptied = counts.emptied + 1
      end
      info(string.format("freed stack: %s slot %d handle %s -> %s", hex(hdl), slot, hex(inv),
        done and hex(move) or "left as it is"))
    end
  end
end

local function repair_freed_cells()
  if not board_layout() then return true end
  local freed, more, cell_count = freed_stacks()
  if not freed then return false end
  local list_at = profile_field("CharaData.TechniqueList")
  local counts = { restored = 0, emptied = 0, failed = 0 }
  for _, inv in ipairs(freed) do
    repair_tried[inv] = true
    repair_stack(inv, list_at, counts)
  end
  info(string.format("freed stacks on %d board cell(s): %d move(s) back with their own copy, %d cell(s) emptied, %d left%s",
    cell_count, counts.restored, counts.emptied, counts.failed, more and "; more on the next menu" or ""))
  return not more
end

local repair_due = false
VRFW.on("save:slot_load", function()
  repair_due, repair_tried = true, {}
  return nil
end)
VRFW.on("menu:open:post", function()
  if repair_due and repair_freed_cells() then repair_due = false end
  return nil
end)
VRFW.on("game:reset", function()
  repair_due, repair_tried = false, {}
  return nil
end)

function BoardSlots.Place(hdl, inv, slot)
  hdl, inv, slot = u32(hdl), u32(inv), slot_argument(slot)
  local st, now = STATUS_BAD_ARGUMENTS, 0
  if slot ~= nil and inv ~= 0 then
    local data, why = character_data(hdl)
    if data then
      st, now = put(data, hdl, inv, slot)
    else
      st = why
    end
  end
  info(string.format("PLACE(%s, inv %s, slot %s) -> status %d, slot item %s", hex(hdl), hex(inv), tostring(slot), st, hex(now)))
  return st, now
end

function BoardSlots.Clear(hdl, slot, mode)
  hdl, slot, mode = u32(hdl), slot_argument(slot), math.floor(tonumber(mode) or 0)
  local st, now = STATUS_BAD_ARGUMENTS, 0
  if slot ~= nil then
    local data, why = character_data(hdl)
    if data then
      st, now = clear(data, hdl, slot, mode ~= 0, mode == 3)
    else
      st = why
    end
  end
  info(string.format("CLEAR(%s, slot %s, keepOpen %d) -> status %d, slot item %s", hex(hdl), tostring(slot), mode, st, hex(now)))
  return st, now
end

-- Board equip slot 9 (CharaData.PlacedSkills + 9 * 4), read and written for the skill table's custom passive button.
local SIX_SENSE_SLOT = 9

function BoardSlots.SixSense(hdl, op, inv, piece)
  hdl, op, inv = u32(hdl), math.floor(tonumber(op) or 0), u32(inv)
  local data, why = character_data(hdl)
  if not data then return why, 0, 0 end
  local at = data + BOARD.placed + SIX_SENSE_SLOT * 4
  local st = STATUS_OK
  if op == 1 then
    local before = u32(read("u32", at) or 0)
    local failed = equip_slot(hdl, inv, SIX_SENSE_SLOT, false)
    local after = u32(read("u32", at) or 0)
    st = failed or (after == inv and STATUS_OK or STATUS_REFUSED)
    info(string.format("SIX_SENSE(%s) %s -> %s (wanted %s) -> status %d", hex(hdl), hex(before), hex(after), hex(inv), st))
  elseif op ~= 0 then
    return STATUS_BAD_ARGUMENTS, 0, 0
  end
  local current = u32(read("u32", at) or 0)
  local item = 0
  if current ~= 0 then
    local ok, id = pcall(VRFW.item.of_inv, current)
    item = ok and u32(id) or 0
  end
  return st, current, item
end
