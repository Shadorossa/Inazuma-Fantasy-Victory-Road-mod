local Memory = VRFW.memory
local ROW_ITEM = 0x4
local VIEW_SHOP = 0x2040
local VIEW_NEW_LIST, NEW_LIST_MAX = 0x2054, 10
local MAX_TAB_ROWS = 0x140
local NO_TAB = 0xFFFFFFFF

local Id = VRFW.ids
local u32 = Id.unsigned

local function arg_u32(v)
  if type(v) ~= "number" then
    return 0
  end
  return u32(v)
end

-- inventory type of the item filter window -> engine test (nil = no filter for that type)
local function pred_of_inv(inv)
  if inv <= 3 then
    return { series = true, mask = 0x2000 * 2 ^ inv }
  elseif inv == 4 then
    return { series = true, mask = 0x20000 }
  elseif inv == 5 then
    return { series = true, mask = 0x40000 }
  elseif inv <= 9 then
    return { series = false, mask = 0x80000000 * 2 ^ (inv - 6), kind = inv - 5 }
  elseif inv <= 16 then
    return { series = false, mask = 0x800000000, kind = 8 }
  end
  return nil
end

local function series_stat_block(params)
  local b = {}
  for i = 0, 0x1F do
    b[i] = 0
  end
  b[0x1C], b[0x1D] = 1, 1
  for _, p in ipairs(params) do
    local t, v = p[1], p[2]
    if t == 1 and b[0] < 10 then
      b[4 + b[0]] = v % 256
      b[0] = b[0] + 1
    elseif t == 2 and b[0x10] < 8 then
      b[0x14 + b[0x10]] = v % 256
      b[0x10] = b[0x10] + 1
    elseif t == 8 and v == 1 then
      b[0x1C] = 0
    elseif t == 8 and v == 2 then
      b[0x1D] = 0
    end
  end
  return b, 0x20
end

local function skill_block(params)
  local b = {}
  for i = 0, 0x37 do
    b[i] = 0
  end
  for i = 0x34, 0x37 do
    b[i] = 1
  end
  local lists = { [3] = { 0x00, 0x04, 6 }, [4] = { 0x0C, 0x10, 6 }, [5] = { 0x18, 0x1C, 7 }, [6] = { 0x24, 0x28, 9 } }
  for _, p in ipairs(params) do
    local t, v = p[1], p[2]
    local l = lists[t]
    if l and b[l[1]] < l[3] then
      b[l[2] + b[l[1]]] = v % 256
      b[l[1]] = b[l[1]] + 1
    elseif t == 8 and v >= 3 and v <= 6 then
      b[0x34 + v - 3] = 0
    end
  end
  return b, 0x38
end

local MAX_PARAMS = 128
local function game_skill_block(params)
  if #params > MAX_PARAMS then
    return nil
  end
  local bp, pp = VRFW.memory.buffer("fill_block", 0x38), VRFW.memory.buffer("fill_params", 12 * MAX_PARAMS)
  for i = 0, 0x37 do
    VRFW.memory.write("u8", bp + i, (i >= 0x34) and 1 or 0)
  end
  for i, p in ipairs(params) do
    local at = pp + 12 * (i - 1)
    VRFW.memory.write("u32", at, arg_u32(p[1]) % 256)
    VRFW.memory.write("u32", at + 4, arg_u32(p[2]))
    VRFW.memory.write("u32", at + 8, arg_u32(p[3]))
  end
  local ok, err = pcall(VRFW.call, "ItemFilterBlockFill", bp, pp, #params)
  if not ok then
    VRFW.warn("game filter fill failed (" .. tostring(err) .. "): the shop's own block is used")
    return nil
  end
  local bytes = VRFW.memory.read_array("u8", bp, 0x38)
  if type(bytes) ~= "table" then
    return nil
  end
  local b = {}
  for i = 0, 0x37 do
    b[i] = bytes[i + 1]
  end
  return b, 0x38
end

local function filter_of(inv, params)
  local pred = pred_of_inv(inv)
  if not pred then
    return nil
  end
  local block, n
  if pred.series then
    block, n = series_stat_block(params)
  else
    block, n = game_skill_block(params)
    if not block then
      block, n = skill_block(params)
    end
  end
  pred.block, pred.n = block, n
  return pred
end

-- t1, v1, o1, … -> { { t1, v1, o1 }, … }
local function triples(...)
  local flat = {}
  for _, x in ipairs({ ... }) do
    flat[#flat + 1] = arg_u32(x)
  end
  local out = {}
  for i = 1, #flat - 2, 3 do
    out[#out + 1] = { flat[i], flat[i + 1], flat[i + 2] }
  end
  return out
end

-- engine test of `item` (a failed call lets it pass)
local function passes(f, item)
  local bp, idp = VRFW.memory.buffer("block", 0x38), VRFW.memory.buffer("item", 4)
  for i = 0, f.n - 1 do
    VRFW.memory.write("u8", bp + i, f.block[i])
  end
  VRFW.memory.write("u32", idp, item)
  local ok, r
  if f.series then
    ok, r = pcall(VRFW.call, "ItemTestSeriesStat", 0, f.mask, idp, bp)
  else
    ok, r = pcall(VRFW.call, "ItemTestSkill", 0, f.mask, f.kind, idp, bp)
  end
  if not ok then
    VRFW.warn(string.format("engine item test failed (%s, item 0x%08X): row kept", tostring(r), item))
    return true
  end
  return bit32.band(r or 0, 0xFF) ~= 0
end

local filters = {} -- slot type -> filter
local hits = 0
local rec -- rows and items of the tab built last

local function rec_reset(view, slot)
  rec = { view = view, slot = slot, rows = {}, items = {}, seen = {}, step = 0 }
end
rec_reset(0, -1)

-- set of the item ids of the tab built last
local function tab_items()
  local set = {}
  for _, item in ipairs(rec.items) do
    set[item] = true
  end
  return set
end

-- every item a shop tab listed since the game started (the universe of the Mods filter section)
local seen_items, seen_list = {}, {}
-- the shop slot each seen item was listed in, and the filter window's inventory type of each slot
local slot_of_item, inv_of_slot = {}, {}

local name_search = nil

local function rec_add(view, slot, row, item)
  local last = rec.rows[#rec.rows]
  local step = (last ~= nil and row ~= last) and ((row > last) and 1 or -1) or 0
  if rec.view ~= view or rec.slot ~= slot or rec.rows[1] == row or (rec.step ~= 0 and step ~= 0 and step ~= rec.step) then
    rec_reset(view, slot)
    step = 0
  end
  if rec.step == 0 and step ~= 0 then
    rec.step = step
  end
  if #rec.rows < 4 * MAX_TAB_ROWS and not rec.seen[row] then
    rec.seen[row] = true
    rec.rows[#rec.rows + 1] = row
    rec.items[#rec.items + 1] = item
  end
end

local function name_search_drops(item)
  return name_search ~= nil and item ~= 0 and name_search.scope[item] and not name_search.keep[item]
end

-- ev.args = (rcx, category, sub, slot type being built), r13 = list view, rsi = row, ev.ret = the game's tab
VRFW.on("hook:ShopTabOf:post", function(ev)
  local t, slot = ev.ret, ev.args[4]
  if t ~= slot then
    return nil
  end
  local view, row = ev.regs.r13, ev.regs.rsi
  local item = Memory.read("u32", row + ROW_ITEM)
  item = item or 0
  rec_add(view, slot, row, item)
  if item ~= 0 and not seen_items[item] then
    seen_items[item] = true
    seen_list[#seen_list + 1] = item
    slot_of_item[item] = slot
  end
  if name_search_drops(item) then
    return { ret = NO_TAB }
  end
  local f = filters[slot]
  if f and item ~= 0 and not passes(f, item) then
    if hits == 0 then
      local shop = Memory.read("u32", view + VIEW_SHOP)
      VRFW.log(string.format("shop 0x%08X slot %d: item 0x%08X filtered out (first hit)", shop or 0, slot, item))
    end
    hits = hits + 1
    return { ret = NO_TAB }
  end
  return nil
end)

local function live()
  return VRFW.is_on("ShopTabOf")
end

-- slot, inv, t1, v1, o1, … -> ok
function BetterQoL.ShopFilterSet(slot, inv, ...)
  slot, inv = arg_u32(slot), arg_u32(inv)
  inv_of_slot[slot] = inv
  local params = triples(...)
  local ok = true
  if #params == 0 then
    filters[slot] = nil
  else
    local f = filter_of(inv, params)
    if f then
      filters[slot] = f
    else
      ok = false
    end
  end
  hits = 0
  VRFW.log(string.format("CMND_BETTERQOL_SHOP_FILTER_SET(slot %d, inv %d, %d params) -> %s", slot, inv, #params, tostring(ok)))
  return ok and live()
end

-- inv, t1, v1, o1, … -> shown, total over the rows of the tab built last
function BetterQoL.ShopFilterCount(inv, ...)
  inv = arg_u32(inv)
  inv_of_slot[rec.slot] = inv
  local params = triples(...)
  local f = filter_of(inv, params)
  local total, shown = #rec.items, #rec.items
  if f then
    shown = 0
    for _, it in ipairs(rec.items) do
      if it == 0 or passes(f, it) then
        shown = shown + 1
      end
    end
  end
  return shown, total
end

-- -> live, cleared
function BetterQoL.ShopFilterReset()
  local n = 0
  for _ in pairs(filters) do
    n = n + 1
  end
  filters = {}
  if name_search ~= nil then
    name_search = nil
    n = n + 1
  end
  if n > 0 then
    VRFW.log("CMND_BETTERQOL_SHOP_FILTER_RESET: " .. n .. " tab filters dropped")
  end
  return live(), n
end

function BetterQoL.ShopNameItems()
  return #rec.items, table.unpack(rec.items)
end

function BetterQoL.ShopNameSet(...)
  local keep = {}
  local n = 0
  for _, x in ipairs({ ... }) do
    keep[arg_u32(x)] = true
    n = n + 1
  end
  if n == 0 then
    name_search = nil
  else
    name_search = { keep = keep, scope = tab_items() }
  end
  VRFW.log(string.format("CMND_BETTERQOL_SHOP_NAME_SET: %d item(s) kept of %d", n, #rec.items))
  return live()
end

-- "new" list of the list view built last (a 0 ends it)
local function view_new_list()
  local out = {}
  if rec.view < 0x10000 then
    return out
  end
  for i = 0, NEW_LIST_MAX - 1 do
    local id = Memory.read("u32", rec.view + VIEW_NEW_LIST + 4 * i)
    if id == nil or id == 0 then
      break
    end
    out[#out + 1] = id
  end
  return out
end

-- -> n, id1, …, idN
function BetterQoL.ShopNewList()
  local v = view_new_list()
  return #v, table.unpack(v)
end

-- id -> true (getter answered), isNew
function BetterQoL.ShopNewState(id)
  id = arg_u32(id)
  if id == 0 then
    return true, false
  end
  for _, x in ipairs(view_new_list()) do
    if x == id then
      return true, true
    end
  end
  return true, false
end

-- The shop's Mods filter section (content\item_filter_sections\mods.toml): one row for the game's items and one per mod
-- that holds an item id, named as in its mod.toml; a row holds the items of its mod.
do
  local ITEM_KIND = "item"
  local owners = nil
  local function owner_of(item)
    if not owners then
      local ok, t = pcall(VRFW.ids.owners, ITEM_KIND)
      owners = ok and type(t) == "table" and t or {}
    end
    return owners[u32(item)]
  end

  -- "mods": the base game row, then one row per mod holding an item id, in load order
  local function row_list(name)
    if name ~= "mods" then return {} end
    owner_of(0)
    local held = {}
    for _, mod in pairs(owners) do held[mod] = true end
    local okb, base = pcall(VRFW.text, "BetterQoL.filter_row_base_game")
    local rows = { { name = "base_game", label = okb and type(base) == "string" and base or "", test = "mod:" } }
    local ok, manifests = pcall(VRFW.files.declarations, "mod.toml")
    for _, f in ipairs(ok and type(manifests) == "table" and manifests or {}) do
      local id = tostring(f.mod)
      if held[id] then
        held[id] = nil
        local label = type(f.data) == "table" and type(f.data.name) == "string" and f.data.name ~= "" and f.data.name or id
        rows[#rows + 1] = { name = id, label = label, test = "mod:" .. id }
      end
    end
    return rows
  end

  -- "mod:<id>" holds the items of mod <id>; "mod:" the game's own
  local function row_test(test)
    local mod = string.match(test, "^mod:(.*)$")
    if mod == nil then return nil end
    return function(item)
      return (owner_of(item) or "") == mod
    end
  end

  if type(VRFW.item_filter) == "table" then
    BetterQoL.ItemFilter = VRFW.item_filter.server({ command = "CMND_BETTERQOL_ITEM_FILTER",
      items = function() return seen_list end, test = row_test, list = row_list,
      inventory_of = function(item) return inv_of_slot[slot_of_item[item] or -1] end })
  else
    VRFW.warn("VRFW.item_filter is missing: the shop's Mods filter tab answers nothing")
  end
end
