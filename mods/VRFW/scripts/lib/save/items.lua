-- Advanced: Item stacks in a save: a pass that lowers the owned amount of chosen items in a save tree.

local T = VRFW.save_tree
local Id = VRFW.ids

local SaveItems = {}

local BLOCK_INVENTORY = 4

-- the item lists of the inventory block: every array of stacks { handle, item_id, stockNum }
local function stack_lists(tree, inventory)
  local out = {}
  for _, name in ipairs(tree:children(inventory) or {}) do
    local stacks, capacity = T.array(tree, inventory, name)
    if stacks and capacity > 0 then
      local first = T.at(stacks, 0)
      if T.number(tree, first, "handle") and T.number(tree, first, "item_id") and T.number(tree, first, "stockNum") then
        out[#out + 1] = { name = name, path = stacks, capacity = capacity }
      end
    end
  end
  return out
end

--- Internal: Lowers the stock of every item of `most_by_item` (item id -> the most kept) in `tree`: report; false, why.
function SaveItems.limit(tree, most_by_item)
  if not T.has_block(tree, BLOCK_INVENTORY) then return false, "block " .. BLOCK_INVENTORY .. " not found" end
  local inventory = T.unwrap(tree, "block" .. BLOCK_INVENTORY, "m_Permanent")
  local lists = stack_lists(tree, inventory)
  if #lists == 0 then return false, "no item list found in block " .. BLOCK_INVENTORY end
  local P = T.patches(tree)
  local report = { stacks = 0, lowered = 0, bytes_patched = 0, lines = {} }
  for _, list in ipairs(lists) do
    for i = 0, list.capacity - 1 do
      local stack = T.at(list.path, i)
      local item = T.number(tree, stack, "item_id")
      local most = item and most_by_item[item] or nil
      if most and (T.number(tree, stack, "handle") or 0) ~= 0 then
        local stock = tree:int(stack .. ".stockNum", true)
        report.stacks = report.stacks + 1
        if stock > most then
          P:set(stack .. ".stockNum", T.number(tree, stack, "stockNum"), most)
          report.lowered = report.lowered + 1
          report.lines[#report.lines + 1] = string.format("%s[%d]: item %s: %d -> %d", list.name, i, Id.hex_text(item), stock, most)
        end
      end
    end
  end
  report.bytes_patched = P:apply()
  return report
end

--- Internal: One line of text for `report`.
function SaveItems.summary(report)
  return string.format("%d item stacks found, %d lowered; %d bytes patched", report.stacks, report.lowered, report.bytes_patched)
end

return SaveItems
