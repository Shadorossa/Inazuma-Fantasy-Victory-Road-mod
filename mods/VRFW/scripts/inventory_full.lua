-- Full inventory lists (native side: content\game\inventory_full.toml).
-- The game's check before a grant only looks at the item's stack: an item that needs a new record in a full list
-- passed it, was paid for and was then dropped by the add. The check now also asks the list for a free record.
-- Every shop purchase logs one line per item it adds, with the list and the stack before and after the add.

local Memory = VRFW.memory

local info, warn = VRFW.logger("inventory")

local HOOK = "VRFW.ItemCanAdd"
local HANDLE_BUFFER = "inventory_full_handle"
local MAX_PURCHASE_LINES = 200   -- purchase lines of one game session

local function profile_value(name)
  local ok, value = pcall(VRFW.game.field, name)
  return ok and type(value) == "number" and value or nil
end

local CONTAINERS = profile_value("Inventory.Containers")
local LIST_COUNT = profile_value("Inventory.ListCount")
local VT_CAPACITY = profile_value("Inventory.VtCapacity")
local VT_COUNT = profile_value("Inventory.VtCount")
local ROOT_ITEMS = profile_value("Game.RootItems")

local function hook_on(name)
  local ok, on = pcall(VRFW.is_on, name)
  return ok and on == true
end

--- The place of `item` in the inventory: { list, capacity, count, handle }; nil when the item has no list.
--- `handle` is 0 when no record holds the item yet.
local function place_of(inventory, item)
  local list = VRFW.call("Inventory.ListOfCategory", VRFW.call("Item.Category", item))
  if list >= LIST_COUNT then
    return nil
  end
  local container = Memory.read("ptr", inventory + CONTAINERS + 8 * list)
  if not container or container == 0 then
    return nil
  end
  local out = Memory.buffer(HANDLE_BUFFER, 8)
  Memory.write("u32", out, 0)
  VRFW.call("Inventory.FindStack", container, out, item, 0, 0)
  return {
    list = list,
    capacity = VRFW.call_vslot(container, math.floor(VT_CAPACITY / 8), "-> u32"),
    count = VRFW.call_vslot(container, math.floor(VT_COUNT / 8), "-> u32"),
    handle = Memory.read("u32", out) or 0,
  }
end

--- The list of `item` when the item needs a new record and the list has none free: list index, capacity.
--- nil when the item fits there or has no list.
local function full_list(inventory, item)
  local place = place_of(inventory, item)
  if not place or place.handle ~= 0 or place.count < place.capacity then
    return nil
  end
  return place.list, place.capacity
end

local function inventory_now()
  local root = Memory.read("ptr", VRFW.game.symbol("Game.Root"))
  if not root or root == 0 then
    return nil
  end
  local inventory = Memory.read("ptr", root + ROOT_ITEMS)
  return inventory ~= 0 and inventory or nil
end

--- The place of `item` now, with the stock and the equipped count of its record; nil when it cannot be read.
local function stock_of(item)
  local inventory = inventory_now()
  if not inventory then
    return nil
  end
  local ok, place = pcall(place_of, inventory, item)
  if not ok or not place then
    return nil
  end
  place.stock, place.equipped = 0, 0
  if place.handle ~= 0 then
    local read, _, stock, equipped = pcall(VRFW.item.of_inv, place.handle)
    if read then
      place.stock, place.equipped = stock or 0, equipped or 0
    end
  end
  return place
end

if not (CONTAINERS and LIST_COUNT and VT_CAPACITY and VT_COUNT and ROOT_ITEMS) then
  warn("the inventory layout is not in the game profile: a full list is not checked before a grant")
elseif not hook_on(HOOK) then
  warn("hook " .. HOOK .. " is off (Item.CanAdd not resolved): a full list is not checked before a grant")
else
  local failed = false

  VRFW.on("hook:" .. HOOK .. ":post", function(ev)
    if ev.ret ~= true and ev.ret ~= 1 then
      return nil
    end
    local ok, list, capacity = pcall(full_list, ev.args[1], ev.args[2])
    if not ok then
      if not failed then
        failed = true
        warn("the list of an item could not be read: " .. tostring(list))
      end
      return nil
    end
    if not list then
      return nil
    end
    info(string.format("item 0x%08X refused before the grant: inventory list %d is full (%d records)",
      ev.args[2], list, capacity))
    return { ret = false }
  end)

  -- A grant that did not ask first: the add found no free record and gave nothing.
  VRFW.on("item:added:post", function(ev)
    local out, item = ev.args[1], ev.args[2]
    if not out or out == 0 or Memory.read("u32", out) ~= 0 then
      return nil
    end
    local inventory = inventory_now()
    if not inventory then
      return nil
    end
    local ok, list, capacity = pcall(full_list, inventory, item)
    if ok and list then
      warn(string.format("item 0x%08X was not given: inventory list %d is full (%d records)", item, list, capacity))
    end
    return nil
  end)

  -- The purchase that runs: the items it added, in order, each with its place before and after the add.
  local purchase = nil
  local purchase_lines = 0

  local function purchase_log(level, text)
    if purchase_lines >= MAX_PURCHASE_LINES then
      return
    end
    purchase_lines = purchase_lines + 1
    level(text .. (purchase_lines == MAX_PURCHASE_LINES and "; line cap reached: no more purchase lines this session" or ""))
  end

  VRFW.on("shop:purchase", function(ev)
    purchase = { quantity = ev.args and ev.args[2] or 0, items = {}, order = {} }
    return nil
  end)

  VRFW.on("item:added", function(ev)
    if not purchase then
      return nil
    end
    local item = ev.args[2]
    if item and not purchase.items[item] then
      purchase.items[item] = { asked = 0, before = stock_of(item), handle = 0 }
      purchase.order[#purchase.order + 1] = item
    end
    return nil
  end)

  VRFW.on("item:added:post", function(ev)
    local entry = purchase and purchase.items[ev.args[2]]
    if not entry then
      return nil
    end
    local out = ev.args[1]
    entry.asked = entry.asked + (ev.args[3] or 0)
    entry.handle = out and out ~= 0 and Memory.read("u32", out) or 0
    return nil
  end)

  VRFW.on("shop:purchase:post", function()
    local done = purchase
    purchase = nil
    if not done then
      return nil
    end
    if #done.order == 0 then
      purchase_log(info, string.format("shop purchase: quantity %d: no item add (a card row, or nothing was given)", done.quantity))
      return nil
    end
    for _, item in ipairs(done.order) do
      local entry = done.items[item]
      local before, after = entry.before, stock_of(item)
      if not before or not after then
        purchase_log(warn, string.format("shop purchase: item 0x%08X x%d: handle 0x%08X, its inventory list could not be read",
          item, entry.asked, entry.handle))
      else
        local given = after.stock - before.stock
        purchase_log(given == entry.asked and info or warn, string.format(
          "shop purchase: item 0x%08X x%d -> inventory list %d: records %d -> %d of %d, stock %d -> %d (equipped %d -> %d), handle 0x%08X%s",
          item, entry.asked, after.list, before.count, after.count, after.capacity, before.stock, after.stock,
          before.equipped, after.equipped, entry.handle,
          given == entry.asked and "" or string.format(": %d of %d given", given, entry.asked)))
      end
    end
    return nil
  end)

  VRFW.on("game:reset", function()
    purchase = nil
    return nil
  end)
end
