-- The Draft's session: its phase, building and applying the squad, restoring the rows and the campaign hooks.
local Shared = require "lib/draft/context"
local U = require "lib/util"
local G = require "lib/game"
local D = Shared.D
local floor = math.floor
local NONE = Shared.NONE
local COMPLETE = Shared.COMPLETE
local CAMPAIGN = Shared.CAMPAIGN
local BLOB = Shared.BLOB
local KEY_PHASE = Shared.KEY_PHASE
local info = Shared.info
local warn = Shared.warn
local err = Shared.err
local fail = Shared.fail
local CFG = Shared.CFG
local DECL = Shared.DECL
local TEAM = Shared.TEAM
local eligible = Shared.eligible
local pool_from = Shared.pool_from
local staff_from = Shared.staff_from
local static_tables = Shared.static_tables
local index_players = Shared.index_players
local validate = Shared.validate
local read_rows = Shared.read_rows
local write_row = Shared.write_row
local plan_writes = Shared.plan_writes
local draft_slots = Shared.draft_slots
local draft_from_picks = Shared.draft_from_picks
local filled = Shared.filled
local draft_roster = Shared.draft_roster
local roster_picks = Shared.roster_picks
local save_roster = Shared.save_roster
local load_roster = Shared.load_roster

Shared.RT = nil       -- { pool, draft, phase, written, src }
Shared.FAILED = false
Shared.BEGUN = 0

local function set_phase(r, p)
  r.phase = p
  pcall(VRFW.state.set, KEY_PHASE, p)
end

local function bb_squads(draft)
  local rows, why = G.enjoy_rows()
  if not rows then
    fail(why)
  end
  local seen, out, conds, unread = {}, {}, {}, 0
  for _, row in ipairs(rows) do
    local t = row.team
    if t ~= 0 then
      local c = conds[t]
      if not c then
        c = {}
        conds[t] = c
      end
      c[#c + 1] = row.cond
    end
    if t ~= 0 and t ~= draft and not seen[t] then
      seen[t] = true
      local r = D.roster(t)
      if r then
        out[#out + 1] = { team = t, members = r }
      else
        unread = unread + 1
      end
    end
  end
  return out, conds, unread
end

-- the pool and a fresh session (phase NONE).
local function build(quiet)
  if not DECL or (quiet == "script load" and TEAM or D.team()) == 0 then
    return nil
  end
  local t0 = VRFW.now_ms()
  local ok, res = pcall(function()
    local sx = static_tables()
    local slots, params = sx.slots, sx.params
    local t1 = VRFW.now_ms()
    local squads, conds, unread = bb_squads(TEAM)
    local t2 = VRFW.now_ms()
    local rule = { special = CFG.special, exclude = CFG.exclude }
    local st = { squads = #squads, members = 0, staff = 0, unknown = 0, special = 0, no_position = 0, excluded = 0 }
    local lists = {}
    for i, sq in ipairs(squads) do
      lists[i] = eligible(sq.members, params, rule, st)
      lists[i].team = sq.team
      sq.elig = lists[i]
    end
    local players, merged = pool_from(lists, params, sx.keys)
    info(string.format("pool derived: %d players from %d Battle Bay squads (%d members; left out: staff %d, not in "
      .. "chara_param %d, special cards %d, no position %d, excluded %d; variants of one character merged %d), %d slots, "
      .. "formation %s", #players, st.squads, st.members, st.staff, st.unknown, st.special, st.no_position, st.excluded,
      merged, #slots, VRFW.ids.hex_text(DECL.formation)))
    info(string.format("pool build%s: tables %d ms, squads %d ms (%d team(s) without readable member rows), pool %d ms",
      quiet and (" (" .. quiet .. ")") or "", t1 - t0, t2 - t1, unread, VRFW.now_ms() - t2))
    local staff = staff_from(params, sx.keys, rule)
    info(string.format("staff pool: %d coach / manager cards", #staff))
    local pool = { team = TEAM, formation = DECL.formation, level = DECL.level, slots = slots, players = players,
      staff = staff }
    index_players(pool)
    local bad = validate(pool)
    if bad then
      fail(bad)
    end
    local written = {}
    for _, sl in ipairs(slots) do
      written[sl.slot] = sl.placeholder
    end
    return { pool = pool, draft = nil, phase = NONE, written = written,
      src = { squads = squads, conds = conds, params = params, keys = sx.keys, all = players, open = nil } }
  end)
  if ok then
    return res
  end
  if quiet then
    info("pool not prepared at the " .. quiet .. " (" .. tostring(res) .. "): derived by the first Draft command")
    return nil
  end
  err("the pool cannot be derived (" .. tostring(res) .. "): the Draft tile does nothing this session")
  Shared.FAILED = true
  return nil
end

local function with()
  if Shared.RT == nil and not Shared.FAILED then
    Shared.RT = build()
  end
  return Shared.RT
end

if DECL then
  local t0 = VRFW.now_ms()
  local ok, e = pcall(static_tables)
  if ok then
    info(string.format("pool tables read at load in %d ms (%d slots)", VRFW.now_ms() - t0, #e.slots))
  else
    info("pool tables not read at load (" .. tostring(e) .. "): read by the first build")
  end
  if ok and Shared.RT == nil and not Shared.FAILED then
    Shared.RT = build("script load")
  end
end

VRFW.on("save:slot_load", function(ev)
  if Shared.RT == nil and not Shared.FAILED and D.team() ~= 0 then
    local r = build("save load")
    if r and Shared.RT == nil then
      Shared.RT = r
    end
  end
  -- the running draft run's roster of the loaded slot back on the rows (D.slot_roster, below)
  local ok, e = pcall(D.slot_roster, type(ev) == "table" and ev.slot or nil)
  if not ok then
    err("slot_load: roster not restored: " .. tostring(e))
  end
end)

local function apply(r, want)
  local now, why = read_rows(r.pool.team)
  if not now then
    return nil, why
  end
  local plan, perr = plan_writes(now, r.pool, r.written, want)
  if not plan then
    return nil, perr
  end
  for _, w in ipairs(plan) do
    if not write_row(w.row, w.id, w.loadout) then
      return nil, "write of row at " .. VRFW.ids.hex_text(w.row.addr) .. " failed"
    end
  end
  -- the team plays the draft's formation (the team's own when it has none / without a draft)
  local fm = (r.draft and r.draft.formation) or r.pool.formation
  local rec = now.rec and VRFW.memory.struct("TeamRecord", now.rec)
  if rec and fm and fm ~= 0 and U.get(rec, "formation") ~= fm then
    if not pcall(function()
      rec.formation = fm
    end) then
      return nil, "formation write failed"
    end
  end
  for _, s in ipairs(r.pool.slots) do
    r.written[s.slot] = want[s.slot] or s.placeholder
  end
  return #plan
end

-- placeholders back, no draft
local function restore(r)
  r.draft = nil
  set_phase(r, NONE)
  return apply(r, {})
end

local function session_slots(r)
  local out = {}
  for k, s in ipairs(draft_slots(r.draft, r.pool)) do
    out[k] = { spec = s, pick = r.draft and r.draft.picks[k] or nil }
  end
  return out
end

local function campaign_started(r)
  if r.phase == COMPLETE then
    set_phase(r, CAMPAIGN)
    return true
  end
  return false
end

local function leader_of(rows)
  local pick = rows[1]
  for _, r in ipairs(rows) do
    if r.slot == 0 then
      pick = r
      break
    end
  end
  if pick and pick.param ~= 0 then
    return pick.param
  end
  return nil
end

local function sync_leader(why)
  local team = D.team()
  if team == 0 then
    return nil
  end
  local rows, rerr = read_rows(team)
  if not rows then
    warn("leader not checked (" .. why .. "): roster rows of " .. VRFW.ids.hex_text(team) .. ": " .. tostring(rerr))
    return nil
  end
  local lead = leader_of(rows)
  if not lead then
    return nil
  end
  local row = G.enjoy_row(team)
  local er = row and VRFW.memory.struct("EnjoyRow", row)
  if not er then
    warn("leader not checked (" .. why .. "): no enjoy row of " .. VRFW.ids.hex_text(team) .. " in memory")
    return nil
  end
  local old = U.get(er, "leader") or 0
  if old == lead then
    return lead
  end
  if pcall(function()
    er.leader = lead
  end) then
    info(string.format("Draft row leader %s -> %s (slot 0 member, %s)", VRFW.ids.hex_text(old), VRFW.ids.hex_text(lead), why))
    return lead
  end
  err(string.format("Draft row leader NOT written (%s): %s stays, not a member", why, VRFW.ids.hex_text(old)))
  return nil
end

-- The drafted squad only lives on the team's rows in memory.

D.tournament_team = nil

local function tournament_owns(team)
  if type(D.tournament_team) ~= "function" then
    return false
  end
  local ok, t = pcall(D.tournament_team)
  return ok and type(t) == "number" and t ~= 0 and VRFW.ids.unsigned(t) == team
end

local function rows_sane(r)
  local rows, why = read_rows(r.pool.team)
  if not rows then
    return false, why
  end
  local ph, ids = {}, {}
  for _, s in ipairs(r.pool.slots) do
    ph[s.placeholder] = true
  end
  for _, row in ipairs(rows) do
    local known = ph[row.param] or r.pool.by[row.param] or (r.src and r.src.params and r.src.params[row.param])
    if row.param == 0 or row.param ~= row.uid or not known then
      return false, string.format("slot %d holds %08X/%08X", row.slot, row.param, row.uid)
    end
    ids[row.param] = true
  end
  local er = G.enjoy_row(r.pool.team)
  local lead = er and U.get(VRFW.memory.struct("EnjoyRow", er), "leader") or nil
  if lead ~= nil and not ids[lead] then
    return false, "enjoy row leader " .. VRFW.ids.hex_text(lead) .. " is no member"
  end
  return true
end

local function restore_run(r, why, slot)
  local n, e
  local lost = false
  if r.phase == CAMPAIGN and r.draft then
    n, e = apply(r, draft_roster(r.draft, r.pool))
  else
    local doc, picks
    doc, e = load_roster(slot)
    if doc then
      picks, e = roster_picks(doc, r.pool)
    end
    lost = picks == nil
    if picks then
      local d = draft_from_picks(picks, r.pool, type(doc.formation) == "number" and VRFW.ids.unsigned(doc.formation) or nil)
      n, e = apply(r, draft_roster(d, r.pool))
      if n then
        r.draft = d
        set_phase(r, CAMPAIGN)
      end
    end
  end
  sync_leader(why)
  local sane, serr = true, nil
  if n then
    sane, serr = rows_sane(r)
  end
  if n and sane then
    info(string.format("%s: the run's drafted squad on the rows (%d rows written)", why, n))
    return n
  end
  e = n and ("check failed: " .. tostring(serr)) or e
  local back = restore(r)
  sync_leader(why .. ", fallback")
  if lost then
    info(string.format("%s: no stored drafted squad (%s): %s", why, tostring(e),
      back and "placeholders on the rows" or "placeholders not written either"))
  else
    err(string.format("%s: the run's drafted squad NOT restored (%s; phase %s, draft in run %s, rows written %s): %s",
      why, tostring(e), tostring(r.phase), tostring(r.draft ~= nil), tostring(n),
      back and "placeholders on the rows" or "placeholders not written either"))
  end
  return nil, e, lost
end

local SLOT_DONE = nil

function D.slot_roster(slot)
  if D.team() == 0 or Shared.FAILED then
    return
  end
  local has = false
  local n = slot or VRFW.slots.active()
  SLOT_DONE = n
  has = type(VRFW.save.doc.read_text(BLOB, n)) == "string"
  if not has and Shared.RT == nil then
    return
  end
  local r = with()
  if not r then
    return
  end
  if has then
    -- the roster of THIS slot (its blob), never what the last slot / session left in memory
    r.draft = nil
    set_phase(r, NONE)
    restore_run(r, "save load (slot " .. n .. ")", n)
  elseif r.phase ~= NONE then
    local back = restore(r)
    sync_leader("save load")
    info("save load (slot " .. n .. "): no draft run stored, placeholders back (" .. tostring(back) .. " rows)")
  end
end

local function ensure_slot()
  local ok, n = pcall(VRFW.slots.active)
  if not ok or type(n) ~= "number" or n == 0 then
    return
  end
  n = floor(n)
  if SLOT_DONE ~= n then
    local ok2, e = pcall(D.slot_roster, n)
    if not ok2 then
      err("first use of slot " .. n .. ": roster not restored: " .. tostring(e))
      SLOT_DONE = n
    end
  end
end

function D.before_run_match(why)
  local team = D.team()
  if team == 0 then
    return true
  end
  ensure_slot()
  local r = with()
  if not r then
    return true
  end
  if r.phase == CAMPAIGN and r.draft then
    local ok = rows_sane(r)
    if ok then
      sync_leader(why)
      return true
    end
  end
  restore_run(r, why)
  return true
end

-- a complete draft is on the rows (the campaign may start with it)
function D.ready_to_play()
  local r = with()
  return r ~= nil and (r.phase == COMPLETE or r.phase == CAMPAIGN)
end

function D.before_campaign()
  local team = D.team()
  if team == 0 then
    return
  end
  local lead = sync_leader("campaign start")
  local rows, why = read_rows(team)
  if not rows then
    err("campaign start: roster rows of " .. VRFW.ids.hex_text(team) .. " unreadable: " .. tostring(why))
    return
  end
  local list, member = {}, false
  for _, r in ipairs(rows) do
    list[#list + 1] = string.format("%d:%08X", r.slot, r.param)
    if lead and r.param == lead then
      member = true
    end
  end
  local row = G.enjoy_row(team)
  local leader = row and U.get(VRFW.memory.struct("EnjoyRow", row), "leader") or 0
  info(string.format("campaign start with %s: %d rows [%s], enjoy leader %s (member: %s)", VRFW.ids.hex_text(team), #rows,
    table.concat(list, " "), VRFW.ids.hex_text(leader), tostring(member)))
end

-- the campaign really started with the Draft team (the Decide post-phase saw the session block filled)
function D.campaign_started()
  local r = with()
  if r and campaign_started(r) then
    save_roster(r)
    info("campaign started with the drafted team")
  end
end

function BattleBayDeluxe.DraftInfo()
  ensure_slot()
  local r = with()
  if not r then
    return false
  end
  local n = r.draft and filled(r.draft) or 0
  return true, r.pool.team, r.phase, n, #r.pool.slots
end

-- The names the later parts of the Draft read.
Shared.set_phase = set_phase
Shared.with = with
Shared.apply = apply
Shared.restore = restore
Shared.session_slots = session_slots
Shared.campaign_started = campaign_started
Shared.sync_leader = sync_leader
Shared.tournament_owns = tournament_owns
Shared.restore_run = restore_run
Shared.ensure_slot = ensure_slot
