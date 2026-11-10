-- Full inventory lists (native side: content\game\inventory_full.toml).
-- The game's check before a grant only looks at the item's stack: an item that needs a new record in a full list
-- passed it, was paid for and was then dropped by the add. The check now also asks the list for a free record.

local Memory = VRFW.memory

local info, warn = VRFW.logger("inventory")

local HOOK = "VRFW.ItemCanAdd"
local HANDLE_BUFFER = "inventory_full_handle"

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

--- The list of `item` when the item needs a new record and the list has none free: list index, capacity.
--- nil when the item fits there or has no list.
local function full_list(inventory, item)
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
  if Memory.read("u32", out) ~= 0 then
    return nil
  end
  local capacity = VRFW.call_vslot(container, math.floor(VT_CAPACITY / 8), "-> u32")
  local count = VRFW.call_vslot(container, math.floor(VT_COUNT / 8), "-> u32")
  if count < capacity then
    return nil
  end
  return list, capacity
end

local function inventory_now()
  local root = Memory.read("ptr", VRFW.game.symbol("Game.Root"))
  if not root or root == 0 then
    return nil
  end
  local inventory = Memory.read("ptr", root + ROOT_ITEMS)
  return inventory ~= 0 and inventory or nil
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
end
