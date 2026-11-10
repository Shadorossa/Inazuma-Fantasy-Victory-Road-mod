
local SaveKits = VRFW.save.kits

local PurgeKits = {}

-- the [[hide]] targets of every active mod's items files (load order)
local function hidden_targets()
  local out = {}
  local ok, declarations = pcall(VRFW.files.declarations, "content/items")
  for _, file in ipairs(ok and type(declarations) == "table" and declarations or {}) do
    local data = type(file) == "table" and file.data or nil
    for _, entry in ipairs(type(data) == "table" and type(data.hide) == "table" and data.hide or {}) do
      if type(entry) == "table" and type(entry.target) == "string" then out[#out + 1] = entry.target end
    end
  end
  return out
end

function PurgeKits.facts()
  local items, why = SaveKits.items()
  if not items then return nil, why end
  local facts = { by_item = {}, count = 0 }
  for _, target in ipairs(hidden_targets()) do
    local key = target
    local id = VRFW.ids.parse(target)
    if not items.by_key[key] and id and items.by_id[id] then key = items.by_id[id].key end
    local entry = SaveKits.entry(items, key)
    if entry and not facts.by_item[entry.id] then
      facts.by_item[entry.id] = entry
      facts.count = facts.count + 1
    end
  end
  return facts
end

function PurgeKits.run(tree, facts)
  return SaveKits.remove(tree, facts.by_item)
end

PurgeKits.summary = SaveKits.summary

return PurgeKits
