local SpiritPurge = require "lib/spirit_purge"

local function log(message) VRFW.log("ClassicRecruitment spirit purge: " .. message) end
local function warn(message) VRFW.warn("ClassicRecruitment spirit purge: " .. message) end

local function is_reserved(slot)
  local ok, reserved = pcall(VRFW.slots.reserved, slot)
  return ok and reserved and true or false
end

VRFW.on("save:slot_duplicate", function(event)
  local from, to = event.from, event.to
  local copy = "COPY " .. tostring(from) .. "->" .. tostring(to)
  if VRFW.option("classic_recruitment") == 0 then
    event.bytes = nil
    log(copy .. ": classic recruitment is off: spirits left as they are")
    return nil
  end
  if is_reserved(from) or is_reserved(to) then
    event.bytes = nil
    log(copy .. ": a reserved slot (a mode's own save): spirits left as they are")
    return nil
  end
  local tree, why = VRFW.save_tree.open_bytes(event.bytes)
  event.bytes = nil -- the save string is big: let it go
  if not tree then
    warn(copy .. ": the save could not be read (" .. tostring(why) .. "): copy refused, slot " .. tostring(from) .. " untouched")
    return { refuse = "Classic Recruitment: the save could not be read" }
  end
  local ok, report = pcall(SpiritPurge.run, tree)
  if not ok then
    warn(copy .. ": the spirits could not be removed (" .. tostring(report) .. "): copy refused, slot " .. tostring(from) .. " untouched")
    return { refuse = "Classic Recruitment: the spirits could not be removed" }
  end
  local source = event.from_locked and " (the locked retail save)" or ""
  log(copy .. source .. ": " .. SpiritPurge.summary(report))
  if not tree:changed() then return nil end
  return { bytes = tree:commit() }
end)
