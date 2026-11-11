
CharacterReforged = CharacterReforged or {}

local Id = VRFW.ids
local u32, hex = Id.unsigned, Id.hex_text
local Memory = VRFW.memory
local read_memory = Memory.read
local info = VRFW.logger("move write")
local band, rshift = bit32.band, bit32.rshift

local REC_LIST, LIST_SLOTS, LIST_WORDS_PER_SLOT = 0x50, 6, 2
local INVENTORY_KIND_SHIFT, INVENTORY_KIND_MASK, MOVE_KIND = 13, 0x1F, 11

local MAX_LINES = 300            -- all lines of one game session
local MAX_HOLDER_WALKS = 60      -- holder queries in one game session
local MAX_HOLDERS_SHOWN = 6      -- players named on one line
local RECENT_ITEM_MS = 600000    -- an added item counts as recent for 10 minutes
local MAX_BOUGHT_WATCHED = 20    -- bought moves followed in one game session

local lines, walks = 0, 0
local census_due = true
local recent = {}
local purchases_running = 0
local bought = {}
local bought_count = 0
local stack_removing = nil

local function log(...)
  if lines >= MAX_LINES then return end
  lines = lines + 1
  if lines == MAX_LINES then info("line cap reached: nothing more is logged this session") end
  info(string.format(...))
end

local function item_of(inventory_handle)
  local ok, item = pcall(VRFW.item.of_inv, inventory_handle)
  return ok and u32(item or 0) or 0
end

local function census()
  local ok, cell_count, handles = pcall(VRFW.character.board_handles)
  if not ok or type(handles) ~= "table" or cell_count == 0 then return false end
  local stale_handles = 0
  for handle, entry in pairs(handles) do
    if item_of(handle) == 0 then
      stale_handles = stale_handles + 1
      log("census: handle %s holds no item: %d cell(s), first %s slot %d %s", hex(u32(handle)), entry.count,
        hex(u32(entry.holder)), entry.slot, entry.kind)
    end
  end
  log("census: %d board cell(s), %d handle(s) that hold no item", cell_count, stale_handles)
  return true
end

local function holders_of(handle)
  local ok, cells = pcall(VRFW.character.board_holders, handle)
  if not ok or type(cells) ~= "table" then return 0, "" end
  local shown = {}
  for k = 1, math.min(#cells, MAX_HOLDERS_SHOWN) do
    local cell = cells[k]
    shown[k] = string.format("%s slot %d %s", hex(u32(cell.holder)), cell.slot, cell.kind)
  end
  return #cells, table.concat(shown, ", ")
end

local function on_item_added(ev)
  local args = ev.args or {}
  local out, item, added = args[1], u32(args[2] or 0), args[3] or 0
  local handle = out and u32(read_memory("u32", out) or 0) or 0
  if handle == 0 or band(rshift(handle, INVENTORY_KIND_SHIFT), INVENTORY_KIND_MASK) ~= MOVE_KIND then return nil end
  recent[item] = VRFW.now_ms()
  if purchases_running > 0 and not bought[item] and bought_count < MAX_BOUGHT_WATCHED then
    bought[item] = { handle = handle, state = "" }
    bought_count = bought_count + 1
  end
  if walks >= MAX_HOLDER_WALKS then return nil end
  walks = walks + 1
  local count, shown = holders_of(handle)
  log("item add: item %s x%d -> handle %s; %d board cell(s) hold that handle%s%s", hex(item), added, hex(handle), count,
    count > 0 and ": " or "", shown)
  return nil
end

local function on_equip_slot(ev)
  local args = ev.args or {}
  local inventory_handle = u32(args[2] or 0)
  -- A reset of the game empties every cell of every player: those writes say nothing unless a bought move is followed.
  if inventory_handle == 0 and bought_count == 0 then return nil end
  log("EquipSlot: player %s slot %d %s handle %s item %s", hex(u32(args[1] or 0)), (args[3] or 0) + 1,
    (args[4] or 0) ~= 0 and "native" or "placed", hex(inventory_handle), hex(inventory_handle ~= 0 and item_of(inventory_handle) or 0))
  return nil
end

function CharacterReforged.MoveWriteSetSkill(args)
  args = type(args) == "table" and args or {}
  log("SetSkill: player %s move %s list position %d", hex(u32(tonumber(args[1]) or 0)), hex(u32(tonumber(args[2]) or 0)),
    (tonumber(args[3]) or 0) + 1)
  return nil
end

local function on_list_rebuilt(ev)
  if next(recent) == nil then return nil end
  local object = ev.args and ev.args[1] or 0
  if object < 0x10000 then return nil end
  local record = read_memory("ptr", object + 8)
  local handle = record and read_memory("u32", record)
  if not handle then return nil end
  local words = VRFW.memory.read_array("u32", record + REC_LIST, LIST_SLOTS * LIST_WORDS_PER_SLOT)
  local ok = words ~= nil
  if not ok or type(words) ~= "table" then return nil end
  local now = VRFW.now_ms()
  for position = 0, LIST_SLOTS - 1 do
    local move = u32(words[position * LIST_WORDS_PER_SLOT + 1] or 0)
    if recent[move] and now - recent[move] < RECENT_ITEM_MS then
      log("list: player %s has recently added item %s at list position %d after a rebuild", hex(u32(handle)), hex(move), position + 1)
    end
  end
  return nil
end

local function is_move_handle(handle)
  return handle ~= 0 and band(rshift(handle, INVENTORY_KIND_SHIFT), INVENTORY_KIND_MASK) == MOVE_KIND
end

-- the holders of a handle, walking every player only while the walk budget lasts
local function holders_text(handle)
  if walks >= MAX_HOLDER_WALKS then return "not counted" end
  walks = walks + 1
  local count, shown = holders_of(handle)
  return string.format("%d cell(s)%s%s", count, count > 0 and ": " or "", shown)
end

local function on_stack_remove(ev)
  stack_removing = nil
  local args = ev.args or {}
  local handle = args[2] and u32(read_memory("u32", args[2]) or 0) or 0
  if not is_move_handle(handle) then return nil end
  local ok, item, stock, equipped = pcall(VRFW.item.of_inv, handle)
  if not ok then return nil end
  stack_removing = { handle = handle, item = u32(item or 0), stock = stock or 0, equipped = equipped or 0, count = args[3] or 0 }
  return nil
end

local function on_stack_removed()
  local removing = stack_removing
  if not removing then return nil end
  stack_removing = nil
  local ok, item, stock = pcall(VRFW.item.of_inv, removing.handle)
  local freed = not ok or not item or u32(item) ~= removing.item
  log("stack remove: item %s handle %s x%d: stock %d -> %s, equipped %d%s%s; held by %s", hex(removing.item), hex(removing.handle),
    removing.count, removing.stock, freed and "freed" or tostring(stock or 0), removing.equipped,
    purchases_running > 0 and ", during a purchase" or "", bought[removing.item] and ", a bought move" or "", holders_text(removing.handle))
  return nil
end

local function report_bought(where)
  for item, watch in pairs(bought) do
    local ok, now_item, stock, equipped = pcall(VRFW.item.of_inv, watch.handle)
    local state = ok and string.format("handle holds %s, stock %s, equipped %s", hex(u32(now_item or 0)), tostring(stock or 0), tostring(equipped or 0))
      or "handle not readable"
    if state ~= watch.state then
      watch.state = state
      log("bought: item %s handle %s (%s): %s; held by %s", hex(item), hex(watch.handle), where, state, holders_text(watch.handle))
    end
  end
  return nil
end

VRFW.on("shop:purchase", function(ev)
  purchases_running = purchases_running + 1
  log("shop purchase: start, quantity %d", ev.args and ev.args[2] or 0)
  return nil
end)
VRFW.on("shop:purchase:post", function()
  purchases_running = math.max(purchases_running - 1, 0)
  log("shop purchase: end")
  report_bought("after the purchase")
  return nil
end)
VRFW.on("hook:CharacterReforged.MoveWriteStackRemove", on_stack_remove)
VRFW.on("hook:CharacterReforged.MoveWriteStackRemove:post", on_stack_removed)
VRFW.on("menu:close:post", function() return report_bought("a menu closed") end)
VRFW.on("item:added:post", on_item_added)
VRFW.on("hook:CharacterReforged.MoveWriteEquipSlot:post", on_equip_slot)
VRFW.on("chara:moves:post", on_list_rebuilt)
VRFW.on("slot_load", function()
  census_due = true
  return nil
end)
VRFW.on("menu:open:post", function()
  if census_due and census() then census_due = false end
  return report_bought("a menu opened")
end)
VRFW.on("game_reset", function()
  census_due, recent = true, {}
  return nil
end)
