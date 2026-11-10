-- Duplicate resets: a copy of the locked retail save keeps at most `keep` of the items mods declare.

local D = VRFW.declarations
local SaveItems = VRFW.save.items

local info, warn = VRFW.logger("duplicate_resets")

-- item id -> the most the copy keeps (the lowest `keep` of the declarations naming it), the declarations' keys; nil, why
local function declared()
  local schema, why = D.schema("duplicate_reset")
  if not schema then return nil, why end
  local most_by_item, keys = {}, {}
  for _, d in ipairs(D.load(schema, warn)) do
    for _, item in ipairs(d.v.items) do
      local most = most_by_item[item]
      if most == nil or d.v.keep < most then most_by_item[item] = d.v.keep end
    end
    keys[#keys + 1] = d.key
  end
  return most_by_item, keys
end

VRFW.on("slot_copy", function(event)
  local from, to = event.from, event.to
  local copy = "COPY " .. tostring(from) .. "->" .. tostring(to)
  local untouched = ": copy refused, slot " .. tostring(from) .. " untouched"
  local most_by_item, keys = declared()
  if not most_by_item then
    event.bytes = nil
    warn(copy .. ": the declarations could not be read (" .. tostring(keys) .. ")" .. untouched)
    return { refuse = "VRFW duplicate resets: the declarations could not be read" }
  end
  if next(most_by_item) == nil then
    event.bytes = nil
    return nil
  end
  local tree, why = VRFW.save_tree.open_bytes(event.bytes)
  event.bytes = nil -- the save string is big: let it go
  if not tree then
    warn(copy .. ": the save could not be read (" .. tostring(why) .. ")" .. untouched)
    return { refuse = "VRFW duplicate resets: the save could not be read" }
  end
  local ok, report, reason = pcall(SaveItems.limit, tree, most_by_item)
  if not ok or not report then
    warn(copy .. ": the items could not be reset (" .. tostring(ok and reason or report) .. ")" .. untouched)
    return { refuse = "VRFW duplicate resets: the items could not be reset" }
  end
  info(copy .. ": " .. table.concat(keys, ", ") .. ": " .. SaveItems.summary(report))
  for _, line in ipairs(report.lines) do info(copy .. ": " .. line) end
  if not tree:changed() then return nil end
  return { bytes = tree:commit() }
end)
