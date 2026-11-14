-- Small list helpers: contains, index_of, sorted_keys, stable_sort, deep_copy. Call: at load or in a handler.
-- Table helpers every mod shares (VRFW.lists).
local Lists = {}

--- VRFW.lists.deep_copy(value): a copy of value with every nested table copied too. Call: at load or in a handler.
function Lists.deep_copy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, item in pairs(value) do copy[key] = Lists.deep_copy(item) end
  return copy
end

--- VRFW.lists.contains(list, value): whether the list holds value. Returns a boolean. Call: at load or in a handler.
function Lists.contains(list, value)
  for _, item in ipairs(list) do
    if item == value then return true end
  end
  return false
end

--- VRFW.lists.index_of(list, value): the first position of value in the list, or nil. Call: at load or in a handler.
function Lists.index_of(list, value)
  for index, item in ipairs(list) do
    if item == value then return index end
  end
  return nil
end

--- VRFW.lists.sorted_keys(set): the keys of a table, sorted, as a list. Call: at load or in a handler.
function Lists.sorted_keys(set)
  local keys = {}
  for key in pairs(set) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

--- VRFW.lists.stable_sort(list, key_of): sorts the list in place by key_of(item); equal keys keep their order. Call: at load or in a handler.
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
