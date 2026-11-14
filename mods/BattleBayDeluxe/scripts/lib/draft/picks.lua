-- The Draft's picks: the formation, the candidates of a place, a pick, and the stored roster of a running draft.
local Shared = require "lib/draft/context"
local U = require "lib/util"
local CANDIDATES = Shared.CANDIDATES
local POS_ANY = Shared.POS_ANY
local POS_GK = Shared.POS_GK
local POS_DF = Shared.POS_DF
local STAFF = Shared.STAFF
local ROSTER_VERSION = Shared.ROSTER_VERSION
local BLOB = Shared.BLOB
local info = Shared.info
local warn = Shared.warn
local DECL = Shared.DECL
local formation_places = Shared.formation_places
local slot_specs = Shared.slot_specs
local new_draft = Shared.new_draft
local draft_slots = Shared.draft_slots

-- staff kinds take their candidates from the staff list, every other place from the players
local function is_staff_kind(pos)
  return pos == STAFF.coach or pos == STAFF.manager
end

local function draft_formation(d, pool, id)
  if id == 0 or id == pool.formation then
    d.formation, d.slots = nil, nil
    return true
  end
  local ok, places = pcall(formation_places, id)
  if not ok then
    return nil, tostring(places)
  end
  local ok2, slots = pcall(slot_specs, DECL, places)
  if not ok2 then
    return nil, tostring(slots)
  end
  local old = draft_slots(d, pool)
  for k, s in ipairs(slots) do
    if old[k] and old[k].pos ~= s.pos then
      d.offers[k] = nil
    end
  end
  d.formation, d.slots = id, slots
  return true
end

local function draft_from_picks(picks, pool, formation)
  local d = new_draft(U.rng(0, 0), #picks)
  for k, id in ipairs(picks) do
    d.picks[k] = id
  end
  if pool and formation and formation ~= 0 and not draft_formation(d, pool, formation) then
    warn("stored formation " .. VRFW.ids.hex_text(formation) .. " not readable: the team's own formation")
  end
  return d
end

local function filled(d)
  local n = 0
  for k = 1, d.n do
    if d.picks[k] then
      n = n + 1
    end
  end
  return n
end

local function done(d)
  return filled(d) == d.n
end

-- per position: the players still free minus the open places of that position
local function spare_players(d, pool)
  local slots = draft_slots(d, pool)
  local picked, left = {}, {}
  for kk = 1, d.n do
    if d.picks[kk] then
      picked[d.picks[kk]] = true
    end
  end
  for _, p in ipairs(pool.players) do
    if not picked[p.param] then
      left[p.pos] = (left[p.pos] or 0) + 1
    end
  end
  for kk, s in ipairs(slots) do
    if not d.picks[kk] and s.pos >= POS_GK and s.pos <= POS_DF then
      left[s.pos] = (left[s.pos] or 0) - 1
    end
  end
  return left
end

local function candidates(d, pool, k)
  local spec = draft_slots(d, pool)[k]
  if not spec or d.picks[k] then
    return {}
  end
  local picked = {}
  for kk = 1, d.n do
    if d.picks[kk] then
      picked[d.picks[kk]] = true
    end
  end
  local source = is_staff_kind(spec.pos) and (pool.staff or {}) or pool.players
  local of = {}
  for _, p in ipairs(source) do
    of[p.param] = p
  end
  -- a bench place cannot take the last player of a position that still has open places
  local spare = spec.pos == POS_ANY and spare_players(d, pool) or nil
  local function fits(p)
    return (spec.pos == POS_ANY or p.pos == spec.pos) and not picked[p.param]
      and (spare == nil or (spare[p.pos] or 0) > 0)
  end
  local offer, in_offer = {}, {}
  for _, id in ipairs(d.offers[k] or {}) do
    if not picked[id] and (spare == nil or (of[id] and fits(of[id]))) then
      offer[#offer + 1] = id
      in_offer[id] = true
    end
  end
  if #offer < CANDIDATES then
    local fresh = {}
    for _, p in ipairs(source) do
      if fits(p) and not d.shown[p.param] and not in_offer[p.param] then
        fresh[#fresh + 1] = p.param
      end
    end
    d.rng:shuffle(fresh)
    local need = CANDIDATES - #offer
    for i = #fresh, need + 1, -1 do
      fresh[i] = nil
    end
    if #fresh < need then
      local seen = {}
      for _, p in ipairs(source) do
        if fits(p) and d.shown[p.param] and not in_offer[p.param] then
          seen[#seen + 1] = p.param
        end
      end
      d.rng:shuffle(seen)
      local more = need - #fresh
      for i = 1, math.min(more, #seen) do
        fresh[#fresh + 1] = seen[i]
      end
    end
    for _, id in ipairs(fresh) do
      d.shown[id] = true
      offer[#offer + 1] = id
    end
  end
  local copy = {}
  for i, id in ipairs(offer) do
    copy[i] = id
  end
  d.offers[k] = copy
  local out = {}
  for _, id in ipairs(offer) do
    local p = of[id]
    if p then
      out[#out + 1] = p
    end
  end
  return out
end

local function draft_pick(d, pool, k, i)
  local spec = draft_slots(d, pool)[k]
  if not spec then
    return nil, "no slot " .. (k - 1)
  end
  if d.picks[k] then
    return nil, "slot " .. spec.slot .. " is already picked"
  end
  local offer = candidates(d, pool, k)
  local p = offer[i + 1]
  if not p then
    return nil, "candidate " .. i .. " of " .. #offer
  end
  d.picks[k] = p.param
  d.offers[k] = nil
  return spec, p.param
end

-- slot -> id of every place picked
local function draft_roster(d, pool)
  local out = {}
  for k, s in ipairs(pool.slots) do
    if d.picks[k] then
      out[s.slot] = d.picks[k]
    end
  end
  return out
end

local function roster_doc(pool, d)
  local roster = {}
  for k, s in ipairs(pool.slots) do
    if d.picks[k] then
      roster[#roster + 1] = { s.slot, d.picks[k] }
    end
  end
  return { version = ROSTER_VERSION, team = pool.team, roster = roster, formation = d.formation }
end

-- the picks in pool order when the stored roster fits the pool (same team, every place once, ids in the pool)
local function roster_picks(doc, pool)
  if type(doc) ~= "table" or doc.version ~= ROSTER_VERSION or VRFW.ids.unsigned(doc.team) ~= pool.team then
    return nil, string.format("version %s / team %s (pool team %s)", tostring(type(doc) == "table" and doc.version),
      VRFW.ids.hex_text(type(doc) == "table" and doc.team or 0), VRFW.ids.hex_text(pool.team))
  end
  local by, n, entries = {}, 0, 0
  for _, e in ipairs(type(doc.roster) == "table" and doc.roster or {}) do
    entries = entries + 1
    if type(e) == "table" and type(e[1]) == "number" and type(e[2]) == "number" then
      if by[e[1]] == nil then
        n = n + 1
      end
      by[e[1]] = VRFW.ids.unsigned(e[2])
    end
  end
  local staff = 0
  for _, s in ipairs(pool.slots) do
    if is_staff_kind(s.pos) and by[s.slot] == nil then
      by[s.slot] = s.placeholder
      staff = staff + 1
    end
  end
  if n ~= entries or n + staff ~= #pool.slots then
    return nil, entries .. " roster entries for " .. #pool.slots .. " slots"
  end
  local picks = {}
  for _, s in ipairs(pool.slots) do
    local id = by[s.slot]
    if id == nil then
      return nil, "slot " .. s.slot .. " missing"
    elseif not pool.by[id] and not (is_staff_kind(s.pos) and id == s.placeholder) then
      return nil, string.format("slot %d: %08X not in the pool", s.slot, id)
    end
    picks[#picks + 1] = id
  end
  return picks
end

local function blob_desc(n)
  return BLOB .. " (slot " .. n .. ")"
end

local function save_roster(r)
  if not r.draft then
    return
  end
  local n = VRFW.slots.active()
  local done_, why = VRFW.save.doc.write_text(BLOB, VRFW.json.encode(roster_doc(r.pool, r.draft), true), n)
  if done_ then
    info("roster kept in " .. tostring(why) .. " (campaign running)")
  else
    warn(blob_desc(n) .. " not written (" .. tostring(why) .. "): after a restart the campaign plays the placeholders")
  end
end

local function load_roster(slot)
  local n = slot or VRFW.slots.active()
  local b, why = VRFW.save.doc.read_text(BLOB, n)
  if type(b) ~= "string" then
    return nil, blob_desc(n) .. ": " .. tostring(why or "none")
  end
  local doc, jerr = VRFW.json.decode(b)
  if doc == nil then
    return nil, blob_desc(n) .. ": " .. tostring(jerr)
  end
  return doc
end

local function drop_roster(why)
  local n = VRFW.slots.active()
  if type(VRFW.save.doc.read_text(BLOB, n)) == "string" then
    local ok2, where = VRFW.save.doc.set_aside(BLOB, n)
    if ok2 then
      info(blob_desc(n) .. " removed (" .. why .. "): " .. tostring(where))
    else
      warn(blob_desc(n) .. " not removed (" .. tostring(where) .. ")")
    end
  end
end

-- The names the later parts of the Draft read.
Shared.draft_formation = draft_formation
Shared.draft_from_picks = draft_from_picks
Shared.filled = filled
Shared.done = done
Shared.candidates = candidates
Shared.draft_pick = draft_pick
Shared.draft_roster = draft_roster
Shared.roster_picks = roster_picks
Shared.save_roster = save_roster
Shared.load_roster = load_roster
Shared.drop_roster = drop_roster
