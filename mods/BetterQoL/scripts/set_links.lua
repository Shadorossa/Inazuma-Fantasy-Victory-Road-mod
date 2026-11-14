-- The player set links of a slot kept before team loadouts: read once, moved into VRFW.team_loadout, then set aside.
BetterQoL = BetterQoL or {}
BetterQoL.SetLinks = BetterQoL.SetLinks or {}
local Links = BetterQoL.SetLinks

local info, warn = VRFW.logger("set_links")
local u32 = VRFW.ids.unsigned

local BLOB = "betterqol_set_links.json"

-- { version, teams = { ["template<n>"] = { [handle hex] = set index } } }
local DOC = VRFW.save.doc.new(BLOB, {
  version = 1,
  default = function() return { version = 1, teams = {} } end,
  stage = true,
  log = "set_links",
})

-- the slot of the links; nil on a reserved or missing slot
local function usable_slot()
  local ok, slot = pcall(VRFW.slots.active)
  if not ok or type(slot) ~= "number" or slot == 0 then
    return nil
  end
  local okr, reserved = pcall(VRFW.slots.reserved, slot)
  if okr and reserved then
    return nil
  end
  return slot
end

-- CMND_BETTERQOL_SET_LINKS_TO_MOVE -> the links as "n:h=s,h=s;n:..." (template number, handle, set index); "" when none
function Links.ToMove()
  local slot = usable_slot()
  local text = slot and VRFW.save.doc.read_text(BLOB, slot) or nil
  if text == nil then
    return ""
  end
  local doc = DOC:get(slot)
  local parts = {}
  for key, team in pairs(type(doc) == "table" and type(doc.teams) == "table" and doc.teams or {}) do
    local n = tostring(key):match("^template(%d+)$")
    local links = {}
    for h, set in pairs(type(team) == "table" and team or {}) do
      local handle, index = tonumber(h, 16), VRFW.value.integer(set, nil)
      if n ~= nil and handle ~= nil and index ~= nil and index >= 0 then
        links[#links + 1] = string.format("%08X=%d", u32(handle), index)
      end
    end
    if #links > 0 then
      table.sort(links)
      parts[#parts + 1] = n .. ":" .. table.concat(links, ",")
    end
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

-- CMND_BETTERQOL_SET_LINKS_MOVED -> true once the links are set aside (moved into the team loadouts)
function Links.Moved()
  local slot = usable_slot()
  if slot == nil then
    return false
  end
  DOC:forget()
  local ok, where = VRFW.save.doc.set_aside(BLOB, slot)
  if ok then
    info("slot " .. slot .. ": the player set links are now team loadouts; the old file went to " .. tostring(where))
  else
    warn("slot " .. slot .. ": the old player set links file was not set aside (" .. tostring(where) .. ")")
  end
  return ok == true
end
