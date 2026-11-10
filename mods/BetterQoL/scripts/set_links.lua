-- Player sets linked to teams, per save slot: a team template keeps one saved set per player.
BetterQoL = BetterQoL or {}
BetterQoL.SetLinks = BetterQoL.SetLinks or {}
local Links = BetterQoL.SetLinks

local info, warn = VRFW.logger("set_links")
local u32 = VRFW.ids.unsigned

local function int(v)
  return VRFW.value.integer(v, nil)
end

-- { version, teams = { [team] = { [handle hex] = set index } } }, staged with the game's save of the slot
local DOC = VRFW.save.doc.new("betterqol_set_links.json", {
  version = 1,
  default = function() return { version = 1, teams = {} } end,
  stage = true,
  log = "set_links",
})

local function hex(handle)
  return string.format("%08X", u32(handle))
end

-- the document of the active slot; nil on a reserved or missing slot
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
  doc.teams = type(doc.teams) == "table" and doc.teams or {}
  return doc, slot
end

-- the team template that dock `dock` holds (BetterQoL scripts/team_templates.lua); nil when the set is no dock
local function team_key(dock)
  dock = int(dock)
  if dock == nil or dock < 0 then
    return nil
  end
  local ok, n = pcall(BetterQoL.TemplateOfDock, dock)
  if not ok or type(n) ~= "number" then
    return nil
  end
  return string.format("template%d", n)
end

-- CMND_BETTERQOL_SET_LINK_STATE (charaStHdl, set, dock) -> set `set` is the player's linked set in the team of `dock`
function Links.State(handle, set, dock)
  local doc, key, n = slot_doc(), team_key(dock), int(set)
  if doc == nil or key == nil or n == nil then
    return false
  end
  local team = doc.teams[key]
  return team ~= nil and team[hex(handle)] == n
end

-- CMND_BETTERQOL_SET_LINK_TOGGLE (charaStHdl, set, dock) -> linked now; nil when refused. One set per player and team.
function Links.Toggle(handle, set, dock)
  local doc, slot = slot_doc()
  local key, n = team_key(dock), int(set)
  if doc == nil or key == nil or n == nil or n < 0 then
    return nil
  end
  local team = doc.teams[key] or {}
  local h = hex(handle)
  if team[h] == n then
    team[h] = nil
  else
    team[h] = n
  end
  doc.teams[key] = next(team) ~= nil and team or nil
  local ok, why = DOC:put(doc, slot)
  if not ok then
    warn("slot " .. tostring(slot) .. ": link not kept (" .. tostring(why) .. ")")
    return nil
  end
  info(string.format("slot %d %s: player %s set %d %s", slot, key, h, n + 1, team[h] == n and "linked" or "unlinked"))
  return team[h] == n
end

local last_key, prematch_seen = nil, false

-- CMND_BETTERQOL_SET_LINK_PLAN (dock, why) -> count, handles, sets: the linked members of the team of `dock`
function Links.Plan(dock, why)
  local doc, key = slot_doc(), team_key(dock)
  if doc == nil or key == nil then
    return 0
  end
  last_key = key
  if why == "pre-match" then
    prematch_seen = true
  end
  local team = doc.teams[key]
  if team == nil or next(team) == nil then
    return 0
  end
  local okp, party = pcall(VRFW.game.global, "team_template_party")
  local squad = okp and party and VRFW.squads.squad(int(dock), party) or nil
  local handles, sets = {}, {}
  for _, member in ipairs(VRFW.squads.members(squad, 0)) do
    local n = team[hex(member.handle)]
    if n ~= nil then
      handles[#handles + 1] = u32(member.handle)
      sets[#sets + 1] = n
    end
  end
  info(string.format("%s (%s): %d linked member(s)", key, tostring(why), #handles))
  return #handles, handles, sets
end

-- a match that did not open the pre-match formation screen plays the sets written at the last team change
VRFW.on("match:start_request", function()
  local doc = slot_doc()
  local team = doc ~= nil and last_key ~= nil and doc.teams[last_key] or nil
  if team ~= nil and next(team) ~= nil and not prematch_seen then
    warn(last_key .. ": this match did not pass the pre-match formation screen; its linked sets were written at the last team change only")
  end
  prematch_seen = false
end)
