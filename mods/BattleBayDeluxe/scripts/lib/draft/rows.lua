-- The Draft team's rows in memory: the pool check, the row reads and writes and the placeholder write plan.
local Shared = require "lib/draft/context"
local D = Shared.D
local CANDIDATES = Shared.CANDIDATES
local POS_ANY = Shared.POS_ANY
local POS_GK = Shared.POS_GK
local POS_DF = Shared.POS_DF
local STAFF = Shared.STAFF

local function validate(pool)
  if pool.team == 0 then
    return "no team"
  end
  if #pool.slots == 0 then
    return "no slots"
  end
  local seen = {}
  for _, s in ipairs(pool.slots) do
    if seen[s.slot] then
      return "slot " .. s.slot .. " twice"
    end
    seen[s.slot] = s
    if s.placeholder == 0 then
      return "slot " .. s.slot .. " without placeholder"
    end
    if s.pos > POS_DF and s.pos ~= STAFF.coach and s.pos ~= STAFF.manager then
      return "slot " .. s.slot .. " position " .. s.pos
    end
  end
  for _, kind in ipairs({ STAFF.coach, STAFF.manager }) do
    local need, have = 0, 0
    for _, s in ipairs(pool.slots) do
      if s.pos == kind then
        need = need + 1
      end
    end
    for _, p in ipairs(pool.staff or {}) do
      if p.pos == kind then
        have = have + 1
      end
    end
    if need > 0 and have < need - 1 + CANDIDATES then
      return "staff kind " .. kind .. ": " .. have .. " cards for " .. need .. " picks"
    end
  end
  for k = 0, 10 do
    local s = seen[k]
    if not s then
      return "starter slot " .. k .. " missing"
    elseif s.pos == POS_ANY then
      return "starter slot " .. k .. " without a position"
    end
  end
  local ids, charas = {}, {}
  for _, p in ipairs(pool.players) do
    if p.param == 0 or ids[p.param] then
      return "player " .. VRFW.ids.hex_text(p.param) .. " twice or zero"
    end
    ids[p.param] = true
    if p.chara ~= 0 then
      if charas[p.chara] then
        return "character " .. VRFW.ids.hex_text(p.chara) .. " twice (player " .. VRFW.ids.hex_text(p.param) .. ")"
      end
      charas[p.chara] = true
    end
    if p.pos < POS_GK or p.pos > POS_DF then
      return "player " .. VRFW.ids.hex_text(p.param) .. " position " .. p.pos
    end
  end
  for pos = POS_GK, POS_DF do
    local need, have = 0, 0
    for _, s in ipairs(pool.slots) do
      if s.pos == pos then
        need = need + 1
      end
    end
    for _, p in ipairs(pool.players) do
      if p.pos == pos then
        have = have + 1
      end
    end
    if need > 0 and have < need - 1 + CANDIDATES then
      return "position " .. pos .. ": " .. have .. " players for " .. need .. " picks"
    end
  end
  local field = 0
  for _, s in ipairs(pool.slots) do
    if s.pos <= POS_DF then
      field = field + 1
    end
  end
  if #pool.players < field - 1 + CANDIDATES then
    return #pool.players .. " players for " .. field .. " picks"
  end
  return nil
end

local function read_rows(team)
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then
    return nil, why
  end
  local rec = slice.record
  local out = {}
  for _, a in ipairs(slice.rows) do
    -- the whole row in one guarded read (the pool build reads ~9000 rows of 600 squads)
    local m = VRFW.memory.read_struct("MemberRow", a)
    local okm = m ~= nil
    if not okm then
      m = nil
    end
    local slot, param, uid = m and m.slot, m and m.param, m and m.uid
    if slot == nil or param == nil or uid == nil then
      return nil, "row unreadable"
    end
    out[#out + 1] = { slot = slot, param = param, uid = uid, loadout = m.loadout, addr = a }
  end
  out.rec = rec
  return out
end

function D.roster(team)
  local rows, why = read_rows(team)
  if not rows then
    return nil, why
  end
  local out = {}
  for i, r in ipairs(rows) do
    out[i] = { r.slot, r.param, r.loadout }
  end
  return out
end

local function write_row(row, id, loadout)
  local m = VRFW.memory.struct("MemberRow", row.addr)
  if not m then
    return false
  end
  local a = pcall(function()
    m.param = id
  end)
  local b = pcall(function()
    m.uid = id
  end)
  local c = true
  if type(loadout) == "number" then
    c = pcall(function()
      m.loadout = loadout
    end)
  end
  return a and b and c
end

function D.member_rows(team)
  return read_rows(team)
end

function D.write_member(row, id)
  return write_row(row, id)
end

local function placeholder_of(pool, slot)
  for _, s in ipairs(pool.slots) do
    if s.slot == slot then
      return s.placeholder
    end
  end
  return nil
end

local PH_LOADOUT = {}

local function plan_writes(rows, pool, written, want)
  if #rows ~= #pool.slots then
    return nil, #rows .. " member rows, the pool has " .. #pool.slots .. " slots"
  end
  local seen, out = {}, {}
  for i, r in ipairs(rows) do
    local ph = placeholder_of(pool, r.slot)
    if not ph then
      return nil, "row " .. (i - 1) .. ": slot " .. r.slot .. " is not a draft slot"
    end
    if seen[r.slot] then
      return nil, "row " .. (i - 1) .. ": slot " .. r.slot .. " twice"
    end
    seen[r.slot] = true
    local last = written[r.slot] or ph
    if r.param ~= r.uid or (r.param ~= ph and r.param ~= last) then
      return nil, string.format("row %d (slot %d): holds %08X/%08X, expected %08X or %08X", i - 1, r.slot, r.param,
        r.uid, ph, last)
    end
    local to = want[r.slot] or ph
    if to == 0 then
      return nil, "slot " .. r.slot .. ": id 0"
    end
    if r.param == ph and PH_LOADOUT[r.slot] == nil and type(r.loadout) == "number" then
      PH_LOADOUT[r.slot] = r.loadout
    end
    local lo
    if to == ph then
      lo = PH_LOADOUT[r.slot]
    else
      local p = pool.by and pool.by[to]
      lo = (p and type(p.loadout) == "number") and p.loadout or 0
    end
    if to ~= r.param or (lo ~= nil and lo ~= r.loadout) then
      out[#out + 1] = { row = r, id = to, loadout = lo }
    end
  end
  return out
end

local function new_draft(rng, n)
  return { rng = rng, picks = {}, n = n, offers = {}, shown = {}, formation = nil, slots = nil }
end

local function draft_slots(d, pool)
  return (d and d.slots) or pool.slots
end

-- The names the later parts of the Draft read.
Shared.validate = validate
Shared.read_rows = read_rows
Shared.write_row = write_row
Shared.plan_writes = plan_writes
Shared.new_draft = new_draft
Shared.draft_slots = draft_slots
