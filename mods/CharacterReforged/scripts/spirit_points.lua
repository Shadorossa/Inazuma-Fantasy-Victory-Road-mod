
CharacterReforged = CharacterReforged or {}
local C = require "lib/points_config"
local A = require "lib/spirit_auras"
local ROUTE = require "lib/spirit_route"

local info, warn = VRFW.logger("CharacterReforged points")

local option_on = C.option_on
local PARTS = { peg = option_on("keshin_points"), sp = option_on("totem_points"), pe = option_on("stamina") }

local RAW = VRFW.files.config("points") or {}
local P = C.points(RAW, PARTS)
local PEG, SP = "CharacterReforged.keshin_points", "CharacterReforged.totem_points"

-- game layout
local Actors = VRFW.players
local Live = VRFW.match.live
local PEND_FLAG_NO_COST, PEND_FLAG_HYPER_GAUGE = 0x08, 0x10
local TENSION_PAY_KIND_SKILL = 8
local EMPTY_EPS = 1e-3
local MIN_LEFT_S = 0.5
local AURA_SLOT_CATEGORY = 8

local LIVE = Live.state_set(RAW.live_states)

local band = bit32.band

local Memory = VRFW.memory
local read_memory, write_memory = Memory.read, Memory.write

local Id = VRFW.ids
local hex = Id.hex_text
local function key_of(id) return A.key(id) end

local function flag(name) return VRFW.flag(name) or 0 end

local seen = { in_match = false, ended = false, half = 0, clock = 0, end_half = 0 }
local match_no = 0
local frame = { state = 0, half = 0, clock = 0, user = 0xFF, dt = 0, live = false, in_play = false }
local players = {}      -- hdl -> player record (this match)

local function new_player(hdl)
  return {
    hdl = hdl, team = 0xFF,
    tr = { keshin = false, armour = false, soul = false, cut_keshin = false, cut_soul = false, cut_armour = false,
      keshin_skill = 0, meta_skill = 0, armour_starts = {} },
    ctx = nil, last_pool = nil, slot_pool = nil, poolless_aura = false,
  }
end

local recs = {}
local pair_recs = {}

local function rec_of(name, key)
  local t = recs[name]
  if not t then
    t = {}
    recs[name] = t
  end
  local k = type(key) == "table" and table.concat(key, ":") or key
  local r = t[k]
  if not r then
    r = { key = key, fields = {}, dirty = false, name = name, rec_key = k }
    t[k] = r
  end
  return r
end

local dirty_recs = {}

local function set_field(r, field, value)
  if r.fields[field] ~= value then
    r.fields[field] = value
    if not r.dirty then
      r.dirty = true
      dirty_recs[#dirty_recs + 1] = r
    end
  end
end

local function rset(name, key, field, value) set_field(rec_of(name, key), field, value) end

local function pset(hdl, field, value) rset("CharacterReforged.PointsPlayer", hdl, field, value) end
local function pairset(hdl, id, field, value)
  local name = "CharacterReforged.PointsPair"
  local by_name = pair_recs[name]
  if by_name == nil then
    by_name = {}
    pair_recs[name] = by_name
  end
  local by_hdl = by_name[hdl]
  if by_hdl == nil then
    by_hdl = {}
    by_name[hdl] = by_hdl
  end
  local r = by_hdl[id]
  if r == nil or recs[name] == nil or recs[name][r.k] ~= r then
    r = rec_of(name, { hdl, id })
    r.k = hdl .. ":" .. id
    by_hdl[id] = r
  end
  set_field(r, field, value)
end
local function teamset(team, field, value) rset("CharacterReforged.PointsTeam", team, field, value) end

local function flush_records()
  local n = #dirty_recs
  if n == 0 then return end
  for i = 1, n do
    local r = dirty_recs[i]
    dirty_recs[i] = nil
    local t = recs[r.name]
    if r.dirty and t and t[r.rec_key] == r then
      r.dirty = false
      local v = next(r.fields) ~= nil and r.fields or nil
      pcall(VRFW.native.table_set, r.name, r.key, v)
    end
  end
end

local cost_teams_user = nil

local spent_marked = {}

local function mark_spent(hdl, id)
  local k = hdl .. ":" .. id
  if spent_marked[k] then return end
  spent_marked[k] = true
  local ok, done = pcall(VRFW.extra_slot.spent, hdl, id, true)
  info(string.format("actor %s: aura %s spent for the match: its summon plate is gone%s", hex(hdl), key_of(id), (ok and done) and "" or " (the plates service did not take it)"))
end

local function report_gauge_empty(hdl)
  local ae = VRFW.aura_end
  if ae and ae.report then pcall(ae.report, hdl, "gauge_empty", 1000) end
end

local function clear_match_tables()
  spent_marked = {}
  pair_recs = {}
  dirty_recs = {}
  for _, n in ipairs({ "CharacterReforged.PointsPlayer", "CharacterReforged.PointsPair", "CharacterReforged.PointsTeam" }) do
    recs[n] = {}
    pcall(VRFW.native.table_clear, n)
  end
  cost_teams_user = nil
  rset("CharacterReforged.PointsTeam", 255, "armour_blocks_keshin_move", P.armour_blocks_keshin_move() and 1 or 0)
  flush_records()
end

local function applies(team) return team == 0 or team == 1 end

local function cost_teams()
  local u = frame.user
  if cost_teams_user == u then return end
  cost_teams_user = u
  for team = 0, 1 do
    teamset(team, "cost", applies(team) and 1 or nil)
  end
end

local function ends_match(s) return s == 2 or s == 3 or s == 6 or s == 7 or s == 8 or s == 22 or s == 24 end
local function restarts_play(s) return s == 9 or s == 10 end

local function log_pools()
  for team = 0, 1 do
    local line = {}
    for hdl, p in pairs(players) do
      if p.team == team then
        for k in pairs(p.tr.armour_starts) do
          local ok, v = pcall(VRFW.resource.get, PEG, hdl, k)
          if ok and v then line[#line + 1] = string.format("%s %s %.0f/%.0f armoured", hex(hdl), key_of(k), v.cur, v.max) end
        end
      end
    end
    if #line > 0 then info(string.format("armoured pools of the last match, T%d: %s", team, table.concat(line, "; "))) end
  end
end

local function start_match()
  match_no = match_no + 1
  if next(players) then log_pools() end
  players = {}
  clear_match_tables()
  info(string.format("match #%d start: h%d, user team %d (pools: the framework's %s / %s)", match_no, frame.half, frame.user, PEG, SP))
end

local function frame_update()
  local f = frame
  local b = "same"
  if f.half ~= 0 then
    if not seen.in_match or f.half < seen.half or (f.half == seen.half and f.clock + 60 < seen.clock) then
      b = "new"
    elseif seen.ended and restarts_play(f.state) then
      b = (f.half > seen.end_half) and "resume" or "new"
    end
  end
  if b == "new" then
    seen = { in_match = true, ended = false, half = f.half, clock = f.clock, end_half = 0 }
    start_match()
  elseif b == "resume" then
    seen.ended = false
  end
  if not seen.in_match then return end
  if ends_match(f.state) and not seen.ended then
    seen.ended = true
    seen.end_half = f.half
    for _, p in pairs(players) do
      p.ctx = nil
      p.tr.keshin, p.tr.armour, p.tr.soul = false, false, false
    end
  end
  seen.half = f.half
  seen.clock = f.clock
end

local function covers(cur, cost) return cur > EMPTY_EPS and cur + EMPTY_EPS >= math.max(cost, 0) end

local function is_soul_pool(k) return A.type(k) == 3 end
local function pool_res(k) return is_soul_pool(k) and SP or PEG end

local function pool_aura_of(aura)
  local ty = A.type(aura)
  if ty == 0 and P.peg() then return aura end
  if ty == 1 and P.peg() then return A.spirit(aura) end
  if ty == 3 and P.sp() then return aura end
  return nil
end

local function start_max(k)
  if not is_soul_pool(k) then return nil end
  local v = VRFW.flag("CharacterReforged.sp_start." .. k) or 0
  if v > 0 then return v end
  return nil
end

local function pool_info(k)
  local ok, pi = pcall(VRFW.resource.pool, pool_res(k), k)
  if not (ok and pi) then pi = { max = 200, move_cost = 60, row = false } end
  local o = start_max(k)
  if o then return { max = o, move_cost = pi.move_cost, row = pi.row } end
  return pi
end

-- a pool not touched yet this match reads as full at its start max
local function pool_get(hdl, k)
  local ok, v = pcall(VRFW.resource.get, pool_res(k), hdl, k)
  if not ok then return nil end
  local o = v and not v.touched and start_max(k)
  if o then return { cur = o, max = o, ratio = 1, touched = false } end
  return v
end

local FREE_FLAG = { [PEG] = "CharacterReforged.free_peg", [SP] = "CharacterReforged.free_sp" }
local function pool_free(res, hdl)
  if flag(FREE_FLAG[res]) == 0 then return false end
  local ok, a = pcall(VRFW.actor, hdl)
  return ok and a ~= nil and a.side == "user"
end

local function pool_add(hdl, k, amount)
  local res = pool_res(k)
  if amount < 0 and pool_free(res, hdl) then return true end
  local ok, r = pcall(VRFW.resource.add, res, hdl, amount, false, k)
  return ok and r
end

local function touch_pool(hdl, k)
  pool_add(hdl, k, 0)
  local o = start_max(k)
  if not o then return end
  local ok, v = pcall(VRFW.resource.get, pool_res(k), hdl, k)
  if ok and v and v.max and v.max > 0 and math.abs(v.max - o) > 0.01 then
    pcall(VRFW.resource.scale, pool_res(k), hdl, k, o / v.max)
  end
end

local function move_cost_of(k) return pool_info(k).move_cost or 0 end

local function atk_of(k)
  local ok, v = pcall(VRFW.resource.pool_value, PEG, k, "atk")
  if ok and type(v) == "number" and v > 0 then return v end
  return P.default_atk
end

local function pool_pay(hdl, k, cost, committed)
  local v = pool_get(hdl, k)
  if not v then return nil end
  if pool_free(pool_res(k), hdl) then return v.cur end
  cost = math.max(cost, 0)
  if not covers(v.cur, cost) then
    if not committed then return nil end
    cost = math.min(cost, v.cur)
  end
  pool_add(hdl, k, -cost)
  local left = v.cur - cost
  if left <= EMPTY_EPS then
    if left > 0 then pool_add(hdl, k, -left) end
    left = 0
  end
  return left
end

local function aura_rule(fn, ...)
  if not (VRFW.aura_rule and VRFW.aura_rule[fn]) then return nil end
  local ok, a, b, c = pcall(VRFW.aura_rule[fn], ...)
  if ok then return a, b, c end
  return nil
end

local FLAG_NAMES = {}
local function flags_of(hdl)
  local n = FLAG_NAMES[hdl]
  if n == nil then
    n = { cost = "CharacterReforged.cost_pct." .. hdl, exempt = "CharacterReforged.exempt." .. hdl, free = "CharacterReforged.armour_free." .. hdl }
    FLAG_NAMES[hdl] = n
  end
  return n
end
local function cost_factor(hdl)
  local v = flag(flags_of(hdl).cost)
  if v > 0 then return v / 100 end
  return 1.0
end
local function exempt(hdl) return flag(flags_of(hdl).exempt) ~= 0 end
local function armour_free(hdl) return flag(flags_of(hdl).free) ~= 0 end

local function pool_move_check(p, skill)
  if not A.is_spirit_move(skill) or A.type(skill) ~= nil then return nil end
  local ctx = p.ctx
  if ctx and ctx.armour and not ctx.soul and P.armour_moves_free() then return nil end
  if not ctx then
    local mv, spirit, members = aura_rule("partner_move", p.hdl)
    if not mv or mv ~= skill or type(members) ~= "table" then return nil end
    local k = pool_aura_of(spirit)
    if not k then return nil end
    local share = move_cost_of(k) / math.max(#members, 1)
    local ok, mine = true, nil
    for _, h in ipairs(members) do
      local v = pool_get(h, k)
      local cur = v and v.cur or pool_info(k).max
      if h == p.hdl then mine = cur end
      if not covers(cur, share) then ok = false end
    end
    return ok, mine or pool_info(k).max, share
  end
  if not ROUTE.is_own_move(A, ctx, skill) then return nil end
  local partners = aura_rule("shared_partners", p.hdl, ctx.key) or {}
  local cost = ctx.move_cost / (1 + #partners)
  local v = pool_get(p.hdl, ctx.key)
  local left = v and v.cur or 0
  local ok = covers(left, cost)
  for _, h in ipairs(partners) do
    local pv = pool_get(h, ctx.key)
    if not covers(pv and pv.cur or pool_info(ctx.key).max, cost) then ok = false end
  end
  return ok, left, cost
end

local function hold_left(full, ratio)
  if not (full == full and full > 0) then full = 60 end
  if ratio ~= ratio then ratio = 1 end
  ratio = math.min(math.max(ratio, 0), 1)
  return math.max(full * ratio, MIN_LEFT_S)
end

local function slot_pool_of(unit)
  if not unit then return nil end
  for i = 0, 5 do
    local s, c = unit["s" .. i], unit["c" .. i]
    if c == AURA_SLOT_CATEGORY and s and s ~= 0 then
      local k = pool_aura_of(s)
      if k then return k end
    end
  end
  return nil
end

-- One player's spirits this frame.
local function aura_step(p, actor, a, unit, live, dt)
  local hdl, team = p.hdl, p.team
  local attr = unit and unit.attr or 0
  local ss, ms = a.summon_state, a.meta_state
  local meta_run = ms == 4 or ms == 5
  local keshin = band(attr, 1) ~= 0 and ss == 2 and P.peg()
  local armour = band(attr, 2) ~= 0 and meta_run and P.peg()
  local soul = band(attr, 8) ~= 0 and ss == 2 and band(attr, 1) == 0 and P.sp()
  local in_play = frame.in_play
  local tr = p.tr
  local ctx = nil
  local free_armour = armour and armour_free(hdl)

  if applies(team) and (keshin or armour or soul) and not exempt(hdl) then
    local cut = cost_factor(hdl)
    local aura_id = armour and a.meta_skill or a.summon_skill
    local k = pool_aura_of(aura_id)
    if k then
      local pi = pool_info(k)
      local kp = pi.max
      local mcost = (pi.move_cost or 0) * cut
      local atk = atk_of(k)
      local drain_per_s = P.armour_drain_per_s(kp, atk, false)
      local members = aura_rule("members_of", hdl, k)
      local group = (type(members) == "table" and #members > 1) and members or nil
      local v = pool_get(hdl, k)
      if v and not v.touched then
        touch_pool(hdl, k)
        info(string.format("actor %s T%d: %s of %s = %.0f (%s), its move costs %.0f", hex(hdl), team,
          soul and "SP bar" or "PEG pool", key_of(k), kp, pi.row and "table" or "default", mcost))
        v = pool_get(hdl, k)
      elseif v and not tr.keshin and not tr.armour and not tr.soul then
        info(string.format("actor %s T%d: %s out again: %s %.0f/%.0f (the pool of this match)", hex(hdl), team, key_of(aura_id),
          soul and "SP" or "PEG", v.cur, v.max))
      end
      if armour and not tr.armour then
        local starts = tr.armour_starts[k] or 0
        tr.armour_starts[k] = starts + 1
        local b = v
        if P.cs() then
          -- the first armour of this pool in the match restores armour_first_refill of max PEG
          if starts == 0 and P.cs_armour_first_refill > 0 and b then pool_add(hdl, k, P.cs_armour_first_refill * b.max) end
          local aft = pool_get(hdl, k)
          if b and aft then
            info(string.format("actor %s T%d: armour %s on %s: %s PEG %.0f/%.0f -> %.0f/%.0f, then %.2f PEG/s (KP %.0f + ATK %.0f)",
              hex(hdl), team, key_of(aura_id), key_of(k), starts == 0 and string.format("first armour of the match: +%.0f %% of max", P.cs_armour_first_refill * 100) or "not the first armour: no refill",
              b.cur, b.max, aft.cur, aft.max, drain_per_s, kp, atk))
          end
        else
          pcall(VRFW.resource.scale, PEG, hdl, k, P.armour_boost)
          local aft = pool_get(hdl, k)
          if b and aft then
            info(string.format("actor %s T%d: armour %s on %s: PEG x%s %.0f/%.0f -> %.0f/%.0f, then %s PEG/s", hex(hdl), team, key_of(aura_id), key_of(k),
              P.armour_boost, b.cur, b.max, aft.cur, aft.max, drain_per_s))
          end
        end
      end
      if armour and in_play and live and dt > 0 and dt < 1 and not free_armour then
        if not group then
          local cur = pool_get(hdl, k)
          if cur and cur.cur > EMPTY_EPS then
            local d = math.min(drain_per_s * cut * dt, cur.cur)
            pool_add(hdl, k, -d)
            if cur.cur - d <= EMPTY_EPS and cur.cur - d > 0 then pool_add(hdl, k, -(cur.cur - d)) end
          end
        else
          -- split over every participant who still has PEG of it
          local holders = {}
          for _, h in ipairs(group) do
            local gv = pool_get(h, k)
            if gv and not gv.touched then
              pool_add(h, k, 0)
              gv = pool_get(h, k)
            end
            if gv and gv.cur > EMPTY_EPS then holders[#holders + 1] = { h, gv.cur } end
          end
          if #holders > 0 then
            local per = drain_per_s * cut / #holders
            for _, hv in ipairs(holders) do
              pool_add(hv[1], k, -math.min(per * dt, hv[2]))
            end
          end
        end
      end
      ctx = { key = k, aura = aura_id, armour = armour, soul = soul, move_cost = mcost }
      p.last_pool = k
      local cur, max = 0, 0
      if group then
        for _, h in ipairs(group) do
          local gv = pool_get(h, k)
          cur = cur + (gv and gv.cur or kp)
          max = max + (gv and gv.max or kp)
        end
      else
        local pv = pool_get(hdl, k)
        cur, max = pv and pv.cur or kp, pv and pv.max or kp
      end
      local empty = cur <= EMPTY_EPS
      if not (empty and in_play) then
        local ratio = empty and 0 or ((max > 0) and math.min(math.max(cur / max, 0), 1) or 0)
        if keshin or soul then write_memory("f32", actor + 0x370, hold_left(a.summon_full, ratio)) end
        if armour then write_memory("f32", actor + 0x39C, hold_left(a.meta_full, free_armour and 1 or ratio)) end
      else
        if soul or keshin or (armour and not free_armour) then report_gauge_empty(hdl) end
        if soul then
          write_memory("f32", actor + 0x370, 0)
          if not tr.cut_soul then
            tr.cut_soul = true
            info(string.format("actor %s T%d: SP empty: totem %s leaves (time 0; no SP for it until the next match)", hex(hdl), team, key_of(a.summon_skill)))
          end
        end
        if keshin then
          write_memory("f32", actor + 0x370, 0)
          if not tr.cut_keshin then
            tr.cut_keshin = true
            info(string.format("actor %s T%d: PEG empty: keshin %s dismissed (time 0; no PEG for it until the next match)", hex(hdl), team, key_of(a.summon_skill)))
          end
        end
        if armour and free_armour then
          write_memory("f32", actor + 0x39C, hold_left(a.meta_full, 1))
        elseif armour then
          write_memory("f32", actor + 0x39C, 0)
          if not tr.cut_armour then
            tr.cut_armour = true
            info(string.format("actor %s T%d: PEG empty: armour %s ends (time 0; its keshin is done for the match)", hex(hdl), team, key_of(aura_id)))
          end
        end
      end
      -- an empty pool refuses its starts for the match
      local own = pool_get(hdl, k)
      if own and own.touched and own.cur <= EMPTY_EPS then
        pairset(hdl, k, "empty", 1)
        mark_spent(hdl, k)
        for _, arm in ipairs(A.armours_of(k)) do pairset(hdl, arm, "empty", 1) end
      end
    elseif aura_id ~= 0 and tr.keshin_skill ~= aura_id and tr.meta_skill ~= aura_id then
      warn(string.format("actor %s T%d: aura %s has no keshin for a PEG pool: its own timer runs", hex(hdl), team, key_of(aura_id)))
    end
  end
  p.ctx = ctx

  -- ends
  if tr.keshin and not keshin then
    info(string.format("actor %s T%d: keshin %s over (summon state %d)%s", hex(hdl), team, key_of(tr.keshin_skill), ss, tr.cut_keshin and ": PEG empty" or ""))
  end
  if tr.armour and not armour then
    info(string.format("actor %s T%d: armour %s over (meta state %d)%s", hex(hdl), team, key_of(tr.meta_skill), ms, tr.cut_armour and ": PEG empty" or ""))
  end
  if tr.soul and not soul then
    info(string.format("actor %s T%d: totem over (summon state %d)%s", hex(hdl), team, ss, tr.cut_soul and ": SP empty" or ""))
  end
  if not keshin then tr.cut_keshin = false end
  if not armour then tr.cut_armour = false end
  if not soul then tr.cut_soul = false end
  tr.keshin, tr.armour, tr.soul = keshin, armour, soul
  if keshin then tr.keshin_skill = a.summon_skill end
  if armour then tr.meta_skill = a.meta_skill end
  p.slot_pool = slot_pool_of(unit) or p.slot_pool
end

local NO_MOVES = {}   -- (read only)
local POOL_FIELDS = { "spirit", "armour", "soul", "cost", "left" }

-- the tables the AuraCostCheck answers read, for one player
local function publish(p)
  local hdl = p.hdl
  local ctx = p.ctx
  local cs_armour_on = ctx and ctx.armour and not ctx.soul
  local own
  if not ctx then
    own = NO_MOVES
  elseif p.own_mvs ~= nil and p.own_aura == ctx.aura and p.own_pool == ctx.key then
    own = p.own_mvs
  else
    own = ROUTE.own_moves(A, ctx)
  end
  p.own_aura, p.own_pool = ctx and ctx.aura, ctx and ctx.key
  local blocked_on = cs_armour_on and P.armour_blocks_keshin_move()
  local cover = nil
  if ctx and not (cs_armour_on and P.armour_moves_free()) then
    local ok = nil
    for m in pairs(own) do
      if ok == nil then ok = select(1, pool_move_check(p, m)) end
    end
    if ok == nil then
      local v = pool_get(hdl, ctx.key)
      ok = v ~= nil and covers(v.cur, ctx.move_cost)
    end
    if P.move_tension_free then cover = ok and 1 or 0 elseif not ok then cover = 0 end
  end
  for m in pairs(p.own_mvs or {}) do
    if not own[m] then
      pairset(hdl, m, "peg_cover", nil)
      pairset(hdl, m, "own_blocked", nil)
      pairset(hdl, m, "cost", nil)
    end
  end
  -- the points one use of the running form's technique takes from its pool (the match HUD's entry cost)
  local shown_cost = ctx and not (cs_armour_on and P.armour_moves_free()) and math.floor(ctx.move_cost + 0.5) or nil
  for m in pairs(own) do
    pairset(hdl, m, "peg_cover", cover)
    pairset(hdl, m, "own_blocked", blocked_on and 1 or nil)
    pairset(hdl, m, "cost", shown_cost)
  end
  p.own_mvs = own
  local mv = aura_rule("partner_move", hdl)
  if not ctx and mv and mv ~= 0 then
    local okp = pool_move_check(p, mv)
    if okp ~= nil then
      pairset(hdl, mv, "partner_cover", okp and 1 or 0)
      p.partner_mv = mv
    end
  elseif p.partner_mv then
    pairset(hdl, p.partner_mv, "partner_cover", nil)
    p.partner_mv = nil
  end
  if P.armour_blocks_keshin_move() then
    local gm = (ctx and A.aura_move(ctx.key)) or mv
    if gm and gm ~= 0 then
      local blocked = aura_rule("move_blocked_by_armour", hdl, gm)
      pairset(hdl, gm, "blocked", blocked and 1 or nil)
      p.blocked_mv = gm
    elseif p.blocked_mv then
      pairset(hdl, p.blocked_mv, "blocked", nil)
      p.blocked_mv = nil
    end
  end
  local kop = nil
  if ctx and not ctx.armour and not ctx.soul and P.keshin_moves_all_peg() then
    local v = pool_get(hdl, ctx.key)
    kop = v and v.cur or 0
  end
  pset(hdl, "keshin_out_peg", kop)
  -- the running pool (other mods' plates)
  if ctx then
    local v = pool_get(hdl, ctx.key)
    pset(hdl, "spirit", ctx.key)
    pset(hdl, "armour", ctx.armour and 1 or 0)
    pset(hdl, "soul", ctx.soul and 1 or 0)
    pset(hdl, "cost", ctx.move_cost)
    pset(hdl, "left", v and math.floor(v.cur * 100 + 0.5) / 100 or 0)
    p.pool_fields = true
  elseif p.pool_fields then
    for _, f in ipairs(POOL_FIELDS) do pset(hdl, f, nil) end
    p.pool_fields = false
  end
end

local UNIT_REREAD_MS = 2000

local function step_player(p, actor, a)
  local now = frame.now
  local running = a.summon_state == 2 or a.meta_state == 4 or a.meta_state == 5
  local tracked = p.tr.keshin or p.tr.armour or p.tr.soul
  local unit = nil
  if running or tracked or now - (p.unit_ms or -UNIT_REREAD_MS) >= UNIT_REREAD_MS then
    local u = VRFW.players.unit_of(actor)
    if u then
      unit = VRFW.memory.read_struct("ApUnit", u)
      p.unit_ms = now
    end
  end
  if unit then
    local attr = unit.attr or 0
    p.poolless_aura = running and attr ~= 0 and band(attr, 1 + 2 + 8) == 0
  elseif not running then
    p.poolless_aura = false
  end
  local live = frame.live and a.in_play ~= 0
  aura_step(p, actor, a, unit, live, frame.dt)
end

local function frame_actors()
  if Actors.frame then return Actors.frame() end
  local base = Actors.base()
  if not base then return nil, nil end
  return Actors.list(), base
end

local NO_MATCH = {}     -- (read only)
local actor_recs = {}
local IDLE_ACTOR = { hdl = 0, team = 0xFF, summon_state = 0, meta_state = 0, in_play = 0, summon_skill = 0, meta_skill = 0,
  summon_full = 0, meta_full = 0 }
local IDLE_STEP_MS = 100
local IDLE_STEP_MAX_FRAMES = 12
local tick_no = 0

VRFW.on("tick", function(ev)
  if not P.any() then return nil end
  local m = ev.match or NO_MATCH
  frame.state = m.soccer_state or 0
  frame.half = m.half or 0
  frame.clock = m.clock or 0
  frame.user = m.user_team or 0xFF
  frame.dt = m.dt or 0
  frame.live = Live.live_time_step(m, LIVE) > 0
  frame.in_play = Live.in_play(m)
  if frame.half == 0 then return nil end
  frame_update()
  if not seen.in_match or seen.ended then return nil end
  cost_teams()
  local list, base = frame_actors()
  if not base then return nil end
  frame.now = VRFW.now_ms()
  local summon = Actors.field and Actors.field("ApActor", "summon_state", base)
  local meta = summon and Actors.field("ApActor", "meta_state", base)
  local now = frame.now
  tick_no = tick_no + 1
  for _, entry in ipairs(list) do
    local actor = entry.address
    local a = nil
    local skip = false
    if meta then
      local ss, ms = summon[entry.index + 1], meta[entry.index + 1]
      local q = players[entry.handle]
      local tr = q and q.tr
      if ss ~= 2 and ms ~= 4 and ms ~= 5 and not (tr and (tr.keshin or tr.armour or tr.soul)) then
        a = IDLE_ACTOR
        a.hdl, a.team, a.summon_state, a.meta_state = entry.handle, entry.team, ss, ms
        -- (and runs at IDLE_STEP_MS while no spirit of his runs)
        skip = q ~= nil and q.ctx == nil and q.team == entry.team and q.idle_due ~= nil and now < q.idle_due
          and now >= q.idle_from and tick_no - q.idle_tick < IDLE_STEP_MAX_FRAMES
      end
    end
    if skip then
      a = nil
    elseif a == nil then
      a = VRFW.memory.read_struct("ApActor", actor, actor_recs[entry.index])
      if a then actor_recs[entry.index] = a end
    end
    if a and a.hdl ~= 0 and band(a.hdl, 0xFF) == entry.index and a.team <= 1 then
      local p = players[a.hdl]
      if not p then
        p = new_player(a.hdl)
        players[a.hdl] = p
      end
      p.team = a.team
      step_player(p, actor, a)
      publish(p)
      if a == IDLE_ACTOR and p.ctx == nil then
        -- the next idle step (the first one spread over the players so they do not all step on the same frame)
        local spread = p.idle_due == nil and (entry.index % 5) * (IDLE_STEP_MS / 5) or 0
        p.idle_due, p.idle_from, p.idle_tick = now + IDLE_STEP_MS + spread, now, tick_no
      else
        p.idle_due = nil
      end
    end
  end
  flush_records()
  return nil
end)

VRFW.on("hook:Ap_PendingPay", function(ev)
  if not P.any() then return nil end
  local actor = ev.args[1]
  if type(actor) ~= "number" or actor < 0x10000 then return nil end
  if (read_memory("u8", actor + 0x1A8) or 0) == 0 then return nil end
  local a = VRFW.memory.read_struct("ApActor", actor)
  if not a then return nil end
  local flags = a.pend_flags
  if band(flags, PEND_FLAG_HYPER_GAUGE) == 0 or band(flags, PEND_FLAG_NO_COST) ~= 0 then return nil end
  if not applies(a.team) then return nil end
  local skill = nil
  for _, id in ipairs({ a.pend_skill, a.pend_skill2 }) do
    if not skill and A.type(id) ~= nil then skill = id end
  end
  if not skill or not pool_aura_of(skill) then return nil end
  if write_memory("u32", actor + 0x1A0, bit32.bor(flags, PEND_FLAG_NO_COST)) then
    info(string.format("actor %s: %s (0x%08X, auraType %d) starts on its pool, without the hyper gauge", hex(a.hdl), key_of(skill), skill, A.type(skill)))
  end
  return nil
end)

VRFW.on("hook:Ap_TensionPay", function(ev)
  if not P.any() then return nil end
  local req = ev.args[1]
  if type(req) ~= "number" or req < 0x10000 then return nil end
  if (read_memory("u8", req + 4) or 0) ~= TENSION_PAY_KIND_SKILL then return nil end
  local hdl = read_memory("u32", req + 8) or 0
  local cost = read_memory("i32", req) or 0
  local p = players[hdl]
  if hdl == 0 or not p or not applies(p.team) or exempt(hdl) then return nil end
  local entry = Actors.of(hdl)
  local actor = entry and entry.address
  local a = actor and VRFW.memory.read_struct("ApActor", actor)
  if not a or a.hdl ~= hdl then return nil end
  local ids = { a.pend_kind == 3 and a.pend_skill2 or a.pend_skill, a.pend_skill, a.pend_skill2 }
  local ctx = p.ctx
  if ctx then
    local route, skill = ROUTE.route(A, P, ctx, ids, cost)
    if route == "keshin_out_peg" then
      local left = pool_pay(hdl, ctx.key, cost, true) or 0
      write_memory("i32", req, 0)
      info(string.format("actor %s T%d: keshin out: move 0x%08X costs its tension %d in PEG (CS), no tension: %.0f PEG left%s", hex(hdl), p.team,
        skill or 0, cost, left, left <= EMPTY_EPS and ": PEG empty, the keshin is dismissed" or ""))
    elseif route == "spirit" then
      local partners = aura_rule("shared_partners", hdl, ctx.key) or {}
      local share = ctx.move_cost / (1 + #partners)
      for _, h in ipairs(partners) do
        local l = pool_pay(h, ctx.key, share, true) or 0
        info(string.format("group keshin %s of %s: partner %s pays his share %.1f PEG: %.0f left", key_of(ctx.key), hex(hdl), hex(h), share, l))
      end
      local left = pool_pay(hdl, ctx.key, share, true)
      if left then
        local v = pool_get(hdl, ctx.key)
        info(string.format("actor %s T%d: %s move 0x%08X costs %.0f %s: %.0f/%.0f left%s", hex(hdl), p.team,
          ctx.soul and "totem" or (ctx.armour and "armour" or "keshin"), skill, share, ctx.soul and "SP" or "PEG", left, v and v.max or 0,
          left <= EMPTY_EPS and (ctx.soul and ": SP empty, the totem leaves" or ": PEG empty, the keshin is dismissed") or ""))
      end
      if P.move_tension_free and cost ~= 0 then write_memory("i32", req, 0) end
    end
    return nil
  end
  local skill = nil
  for _, id in ipairs(ids) do
    if not skill and A.is_spirit_move(id) and A.type(id) == nil then skill = id end
  end
  local mv, spirit, members = aura_rule("partner_move", hdl)
  if skill and mv and mv == skill and type(members) == "table" then
    local k = pool_aura_of(spirit)
    if k then
      local share = move_cost_of(k) / math.max(#members, 1)
      local left = {}
      for _, h in ipairs(members) do
        left[#left + 1] = string.format("%s %.0f", hex(h), pool_pay(h, k, share, true) or 0)
      end
      info(string.format("fusion keshin %s: participant %s used its move 0x%08X: %.1f PEG from each of %d (left: %s)", key_of(k), hex(hdl), skill,
        share, #members, table.concat(left, ", ")))
      if P.move_tension_free and cost ~= 0 then write_memory("i32", req, 0) end
    end
  end
  return nil
end)

function CharacterReforged.PointsPeg(hdl)
  hdl = tonumber(hdl) or 0
  local p = players[hdl]
  if not P.any() or hdl == 0 or not p or not seen.in_match or seen.ended then return false, 0, 0, 0, 0, P.any() and 1 or 0, 0, 0 end
  local function answer(k, active, armour, source)
    local v = pool_get(hdl, k)
    if not v then return nil end
    return true, v.cur, v.max, active and 1 or 0, armour and 1 or 0, 1, source, is_soul_pool(k) and 1 or 0
  end
  if p.ctx then
    local r = { answer(p.ctx.key, true, p.ctx.armour, 1) }
    if r[1] then return table.unpack(r) end
  end
  if p.poolless_aura then return false, 0, 0, 0, 0, 1, 0, 0 end
  if p.last_pool then
    local r = { answer(p.last_pool, false, false, 2) }
    if r[1] then return table.unpack(r) end
  end
  if p.slot_pool and applies(p.team) and not exempt(hdl) then
    local r = { answer(p.slot_pool, false, false, 3) }
    if r[1] then return table.unpack(r) end
  end
  return false, 0, 0, 0, 0, 1, 0, 0
end

function CharacterReforged.PointsPegInfo(aura)
  aura = tonumber(aura) or 0
  A.load()
  local k = pool_aura_of(aura)
  if not k then return false, 0, 0, 0, 0 end
  local pi = pool_info(k)
  return true, is_soul_pool(k) and 2 or 1, math.floor((pi.max or 0) + 0.5), math.floor((pi.move_cost or 0) + 0.5),
    (A.type(aura) == 1 and P.armour_moves_free()) and 1 or 0
end

function CharacterReforged.PointsActiveParts()
  return true, P.peg() and 1 or 0, P.sp() and 1 or 0, PARTS.pe and 1 or 0
end

local function start()
  if not P.any() then
    info("options «keshin_points» and «totem_points» off: keshin, armours and totems run on their time (retail)")
    return
  end
  A.load()
  local n_pool, n_moves = A.publish(function(id) return pool_aura_of(id) ~= nil end)
  clear_match_tables()
  info(string.format("active: PEG %s, SP %s; %d auras run on a pool, %d spirit moves; cost model %s (scale %s); pool moves %s; both teams; hooks: cost check %s, pending pay %s, tension pay %s",
    P.peg() and "on" or "off", P.sp() and "on" or "off", n_pool, n_moves, P.cs() and "CS" or "IF", P.cs_scale(),
    P.keshin_moves_all_peg() and "the spirit's own moves + (keshin out) every move's tension" or "only the running spirit's own moves",
    tostring(VRFW.is_on("Ap_AuraCostCheck")), tostring(VRFW.is_on("Ap_PendingPay")), tostring(VRFW.is_on("Ap_TensionPay"))))
end

start()
