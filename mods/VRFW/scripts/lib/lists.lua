-- Table helpers every mod shares (VRFW.lists).
local Lists = {}

--- A copy of `value`: tables are copied at every level, any other value is returned as it is.
function Lists.deep_copy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, item in pairs(value) do copy[key] = Lists.deep_copy(item) end
  return copy
end

--- True when the array `list` holds `value`.
function Lists.contains(list, value)
  for _, item in ipairs(list) do
    if item == value then return true end
  end
  return false
end

--- The first index of `value` in the array `list`; nil when it is not there.
function Lists.index_of(list, value)
  for index, item in ipairs(list) do
    if item == value then return index end
  end
  return nil
end

--- The keys of `set` as a sorted array.
function Lists.sorted_keys(set)
  local keys = {}
  for key in pairs(set) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

--- Sorts the array `list` in place by `key_of(item)`; items with equal keys keep their order.
function Lists.stable_sort(list, key_of)
  local decorated = {}
  for index, item in ipairs(list) do
    decorated[index] = { key = key_of(item), index = index, item = item }
  end
  table.sort(decorated, function(a, b)
    if a.key ~= b.key then return a.key < b.key end
    return a.index < b.index
  end)
  for index, entry in ipairs(decorated) do
    list[index] = entry.item
  end
end

return Lists
