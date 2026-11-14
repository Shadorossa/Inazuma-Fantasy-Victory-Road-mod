-- Team loadouts: the store of what each player carries in each team (docs/framework/team-loadout.md).
-- The menu side (assets\lua\menu\_all\18_team_loadout.lua) reads the players and writes them; this script keeps the records per save slot.

TeamLoadout = TeamLoadout or {}

local u32 = VRFW.ids.unsigned
local info, warn = VRFW.logger("team_loadout")

local FILE_VERSION = 1
local PARTY = "vrfw_team_loadout_party"
local FIRST_TEAM = 0 -- the team of a squad that plays (the others are the bench pages of that squad)

-- { version, seeded, active = { key, set, members = { hex } }, teams = { [team key] = { [handle hex] = record text } } }
local DOC = VRFW.save.doc.new("vrfw_team_loadouts.json", {
  version = FILE_VERSION,
  stage = true,
  log = "team_loadout",
  default = function() return { version = FILE_VERSION, seeded = false, teams = {} } end,
  decode = function(d)
    d.teams = type(d.teams) == "table" and d.teams or {}
    d.seeded = d.seeded == true
    if type(d.active) ~= "table" or type(d.active.key) ~= "string" then
      d.active = nil
    end
    d.version = FILE_VERSION
    return d
  end,
})

local function hex(handle)
  return string.format("%08X", u32(handle))
end

local function integer(v)
  return VRFW.value.integer(v, nil)
end

-- The document of the active slot and the slot; nil on no slot or a slot a mode reserved.
local function slot_doc()
  local ok, slot = pcall(VRFW.slots.active)
  if not ok or type(slot) ~= "number" or slot == 0 then
    return nil
  end
  local okr, reserved = pcall(VRFW.slots.reserved, slot)
  if okr and reserved then
    return nil
  end
  local doc = DOC:get(slot)
  if type(doc) ~= "table" then
    return nil
  end
  return doc, slot
end

local function save(doc, slot, what)
  local ok, why = DOC:put(doc, slot)
  if not ok then
    warn(string.format("slot %d: %s not kept (%s)", slot, what, tostring(why)))
  end
  return ok
end

-- The words of a comma list, empty entries left out.
local function words(text)
  local out = {}
  for w in tostring(text or ""):gmatch("[^,]+") do
    out[#out + 1] = w
  end
  return out
end

-- The member handles of team `team` (the playing team when nil) of team set `set` as hex words; nil when the party cannot be read.
local function members_of(set, team)
  set, team = integer(set), integer(team) or FIRST_TEAM
  if set == nil or set < 0 or team < 0 then
    return nil
  end
  local okp, party = pcall(VRFW.game.global, PARTY)
  if not okp or party == nil then
    return nil
  end
  local squad = VRFW.squads.squad(set, party)
  if squad == nil then
    return nil
  end
  local out = {}
  for _, m in ipairs(VRFW.squads.members(squad, team)) do
    out[#out + 1] = hex(m.handle)
  end
  return out
end

-- CMND_VRFW_TEAM_LOADOUT_STATE () -> usable, seeded, active team key ("" = none), its team set (-1 = none), its members "h,h,..."
function TeamLoadout.State()
  local doc = slot_doc()
  if doc == nil then
    return false, false, "", -1, ""
  end
  local a = doc.active
  if a == nil then
    return true, doc.seeded, "", -1, ""
  end
  return true, doc.seeded, a.key, integer(a.set) or -1, table.concat(a.members or {}, ",")
end

-- CMND_VRFW_TEAM_LOADOUT_MEMBERS (team set[, team]) -> the member handles of that team (the playing team when nil) as "h,h,..."; nil when unreadable
function TeamLoadout.Members(set, team)
  local list = members_of(set, team)
  if list == nil then
    return nil
  end
  return table.concat(list, ",")
end

-- CMND_VRFW_TEAM_LOADOUT_ACTIVATE (team key, team set, members "h,h,...", seeded) -> true when kept
function TeamLoadout.Activate(key, set, members, seeded)
  local doc, slot = slot_doc()
  if doc == nil or type(key) ~= "string" or key == "" then
    return false
  end
  local before = doc.active and doc.active.key or ""
  doc.active = { key = key, set = integer(set) or -1, members = words(members) }
  if seeded == true then
    doc.seeded = true
  end
  if before ~= key then
    info(string.format("slot %d: active team %s (was %s), %d member(s)", slot, key, before == "" and "none" or before, #doc.active.members))
  end
  return save(doc, slot, "active team " .. key)
end

-- CMND_VRFW_TEAM_LOADOUT_GET (team key, charaStHdl) -> the player's record in that team; nil when he has none
function TeamLoadout.Get(key, handle)
  local doc = slot_doc()
  local team = doc ~= nil and type(key) == "string" and doc.teams[key] or nil
  if team == nil or handle == nil then
    return nil
  end
  return team[hex(handle)]
end

-- CMND_VRFW_TEAM_LOADOUT_PUT (team keys "k,k,...", charaStHdl, record) -> how many teams keep the record now
function TeamLoadout.Put(keys, handle, record)
  local doc, slot = slot_doc()
  if doc == nil or handle == nil or type(record) ~= "string" or record == "" then
    return 0
  end
  local h, count = hex(handle), 0
  for _, key in ipairs(words(keys)) do
    local team = doc.teams[key] or {}
    doc.teams[key] = team
    team[h] = record
    count = count + 1
  end
  if count == 0 or not save(doc, slot, "record of " .. h) then
    return 0
  end
  return count
end

-- CMND_VRFW_TEAM_LOADOUT_DROP (team key[, charaStHdl]) -> how many records were dropped; no handle drops the whole team
function TeamLoadout.Drop(key, handle)
  local doc, slot = slot_doc()
  local team = doc ~= nil and type(key) == "string" and doc.teams[key] or nil
  if team == nil then
    return 0
  end
  local count = 0
  if handle == nil or handle == 0 then
    for _ in pairs(team) do
      count = count + 1
    end
    doc.teams[key] = nil
  elseif team[hex(handle)] ~= nil then
    team[hex(handle)] = nil
    count = 1
    if next(team) == nil then
      doc.teams[key] = nil
    end
  end
  if count > 0 and save(doc, slot, "drop in " .. key) then
    info(string.format("slot %d: %s: %d record(s) dropped", slot, key, count))
    return count
  end
  return 0
end

-- A match of any mode: one that plays another team set than the active one did not pass a screen that writes the sets.
VRFW.on("match:start_request", function()
  local doc = slot_doc()
  local a = doc ~= nil and doc.active or nil
  if a == nil then
    return
  end
  local okp, party = pcall(VRFW.game.global, PARTY)
  local now = okp and party ~= nil and VRFW.squads.active(party) or nil
  local written = integer(a.set) ~= nil and VRFW.squads.physical_index(a.set) or nil
  if now ~= nil and written ~= nil and now ~= written then
    warn(string.format("match start: the party's active stored team set is %d, the sets written last are those of %s (team set %d, stored %d); no screen of this mode wrote them",
      now, a.key, a.set, written))
  end
end)
