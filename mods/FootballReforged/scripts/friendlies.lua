
FootballReforged = FootballReforged or {}
FootballReforged.Friendlies = FootballReforged.Friendlies or {}
local Friendlies = FootballReforged.Friendlies

local band, lshift = bit32.band, bit32.lshift
local ENABLED = true

local BLOB, VERSION = "pachanga.json", 1
local TeamDock = VRFW.teams.dock

local FIRST_DOCK, LAST_DOCK, DOCKS, MAX_BANKS = 2, 12, 11, 32
local Squads = VRFW.squads
local SQUAD_LAYOUT = Squads.layout()
local TEAM_SIZE, MEMBERS = SQUAD_LAYOUT.team_size, SQUAD_LAYOUT.member_count
local MEMBER_LIST, MEMBER_STRIDE = SQUAD_LAYOUT.members, SQUAD_LAYOUT.member_size
local TEAM_FIELDS_FROM, TEAM_FIELDS_TO, COUNTERS, TEAMS = 0x250, 0x2C8, 0x2C8, 3
local PLAY_MODE, PLAY_MODE_STORY = VRFW.game.field("Game.PlayMode"), 2
local REC_TEAM_FLAG = 0x1EC
local CAPTAIN_PARAM, CAPTAIN_HDL = 0x2A0, 0x2A4
local C = { OK = 0, BAD_ARGS = 1, NOT_READY = 2, STORY = 3, PAIRED = 4, EXCEPTION = 7 }
local MEMBER_POSITION, STARTERS, PLAYER_POSITIONS, MATCH_STARTERS = 0xE, 5, 16, 11
local GOALKEEPER = 1   -- the keeper class of VRFW.formation.classes

local info, warn = VRFW.logger("friendlies")

local Memory = VRFW.memory
local read_memory, write_memory, game_global = Memory.read, Memory.write, VRFW.game.global

local function int(v, def)
  if type(v) == "boolean" then return v and 1 or 0 end
  if type(v) ~= "number" then return def end
  if v >= 0 then return math.floor(v) end
  return math.ceil(v)
end

local function dock_no(set) return set - FIRST_DOCK + 1 end

local function ready()
  return ENABLED and VRFW.is_on("Party.LogicalToPhysical") and VRFW.is_on("friendly_party")
end

local function slot()
  if VRFW.slots.ready() then return VRFW.slots.active() end
  return 1
end

local function play_mode()
  local pd = game_global("friendly_play_data")
  return pd and read_memory("u8", pd + PLAY_MODE)
end

local function is_story() return play_mode() == PLAY_MODE_STORY end

local function is_mode_save() return VRFW.slots.ready() and VRFW.slots.reserved(VRFW.slots.active()) == true end

local function is_dock(set) return set >= FIRST_DOCK and set <= LAST_DOCK end
local function is_independent(set) return set > FIRST_DOCK and set <= LAST_DOCK end

-- the live address of logical team set `l`
local function set_addr(l)
  local party = game_global("friendly_party")
  if not party then return nil end
  return Squads.squad(l, party)
end

local function member_off(t, k) return t * TEAM_SIZE + MEMBER_LIST + k * MEMBER_STRIDE end
local function member_handle(addr, t, k) return read_memory("u32", addr + member_off(t, k)) or 0 end

-- member handles of team t (non-zero, slot order)
local function team_handles(addr, t)
  local v = {}
  for k = 0, MEMBERS - 1 do
    local h = member_handle(addr, t, k)
    if h ~= 0 then v[#v + 1] = h end
  end
  return v
end

-- the live record's organizedTeamFlag of a handle (nil = no live record)
local function team_flag(h)
  local ok, r = pcall(VRFW.character.record, h)
  if not ok or type(r) ~= "table" or not r.addr then return nil end
  return read_memory("u16", r.addr + REC_TEAM_FLAG)
end

local function recount(addr, t)
  local c = addr + t * TEAM_SIZE + COUNTERS
  local n = { [0] = 0, 0, 0, 0, 0 }
  for k = 0, MEMBERS - 1 do
    local m = addr + member_off(t, k)
    if (read_memory("u32", m) or 0) ~= 0 then
      n[0] = n[0] + 1
      local pos = read_memory("u8", m + 0xE) or 0
      local s
      if pos == 0x13 then s = 2 elseif pos >= 0x10 and pos <= 0x12 then s = 3 elseif pos >= 0x14 and pos <= 0x1C then s = 4 else s = 1 end
      n[s] = n[s] + 1
    end
  end
  for i = 0, 4 do write_memory("u8", c + i, band(n[i], 0xFF)) end
  write_memory("u8", c + 7, t)
end

local function recount_team_info(team_addr)
  local ok, e = Squads.recount(team_addr)
  if not ok then warn("RecountTeamInfo: " .. tostring(e)) end
end

local function set_bit(member_addr, l, on)
  local ok, e = Squads.set_organized(member_addr, l, on)
  if not ok then warn("SetOrganizedFlagBit dock " .. l .. ": " .. tostring(e)) end
  return ok
end

local function clear_member(addr, t, k)
  local m = addr + member_off(t, k)
  local h = read_memory("u32", m) or 0
  write_memory("u32", m, 0)
  write_memory("u32", m + 4, 0)
  if h ~= 0 then
    local base = addr + t * TEAM_SIZE
    for o = TEAM_FIELDS_FROM, TEAM_FIELDS_TO - 4, 4 do
      if read_memory("u32", base + o) == h then write_memory("u32", base + o, 0) end
    end
  end
  return h
end

local function fresh(s) return { slot = s, mirrored = {} } end

local function bank_ok(k)
  local b = tonumber(k)
  return b and b == math.floor(b) and b >= 1 and b <= MAX_BANKS
end

local function decode(j, s)
  if tonumber(j.slot) ~= s then return nil, "written for slot " .. tostring(j.slot) .. ", not slot " .. s end
  local f = fresh(s)
  if type(j.active) == "table" and next(j.active) ~= nil then
    info("slot " .. s .. ": stored active pachanga choice ignored (the active 5-a-side team is the active match team's pair)")
  end
  if type(j.split) == "table" and next(j.split) ~= nil then
    info("slot " .. s .. ": old split marks ignored (the 5-a-side teams follow their match team's players)")
  end
  if type(j.mirrored) == "table" then
    for k, list in pairs(j.mirrored) do
      if bank_ok(k) and type(list) == "table" then
        local seen, out = {}, {}
        for _, x in pairs(list) do
          x = tonumber(x)
          if x and is_dock(x) and not seen[x] then seen[x] = true out[#out + 1] = x end
        end
        table.sort(out)
        if #out > 0 then f.mirrored[tostring(tonumber(k))] = out end
      end
    end
  end
  return f
end

-- an unusable file is left as it is (the next change writes a new one)
local STORE = VRFW.save.doc.new(BLOB, {
  version = VERSION,
  decode = decode,
  encode = function(f) return { version = VERSION, slot = f.slot, mirrored = f.mirrored } end,
  default = fresh,
  pretty = true,
  aside = false,
  log = "pachanga",
})

local function pt_write(f)
  local ok, where = STORE:put(f, f.slot, true)
  if not ok then VRFW.error("pachanga: cannot write the pachanga pointer: " .. tostring(where)) end
  return ok
end

local function with_pt(s) return (STORE:get(s)) end

-- the team bank page shown on the dock (0-based, VRFW TeamDock.page()), else 0 (no pages / not ready / slot 1 / story)
local function bank()
  local v = TeamDock.page()
  if v < MAX_BANKS then return v end
  return 0
end

local function bank_key(b) return tostring(b + 1) end

-- the dock of the VS team a friendly swapped out (match engine), else of the VS team
local function active_dock()
  local v = VRFW.state("match.friendly.vs_restore")
  if type(v) ~= "number" or v < 0 then
    local party = game_global("friendly_party")
    v = party and Squads.active(party)
  end
  if v and is_dock(v) then return v end
  return nil
end

-- The position classes of formation `id` (1 keeper, 2 forward, 3 midfield, 4 defence) from the framework's formation library.
local function formation_roles(id)
  return VRFW.formation.classes(id)
end

local function player_info(h)
  local ok, r = pcall(VRFW.character.record, h)
  if not ok or type(r) ~= "table" then return 0, 0, 0 end
  local card = math.floor(tonumber(r.param) or 0) % 4294967296
  local okc, c = pcall(VRFW.character.card, card)
  local pos = okc and type(c) == "table" and tonumber(c.position) or 0
  return math.floor(pos) % 256, tonumber(r.level) or 0, card
end

local function entries(addr, t)
  local v = {}
  for k = 0, MEMBERS - 1 do
    local at = addr + member_off(t, k)
    v[k] = { k = k, h = read_memory("u32", at) or 0, pos = read_memory("u8", at + MEMBER_POSITION) or 255, at = at }
  end
  return v
end

local function is_mirrored(f, b, l)
  for _, x in ipairs(f.mirrored[bank_key(b)] or {}) do
    if x == l then return true end
  end
  return false
end

local function mark_mirrored(f, b, l)
  if b >= MAX_BANKS or not is_dock(l) or is_mirrored(f, b, l) then return false end
  local v = f.mirrored[bank_key(b)] or {}
  v[#v + 1] = l
  table.sort(v)
  f.mirrored[bank_key(b)] = v
  return true
end

local function cards_text(list)
  local out = {}
  for _, h in ipairs(list) do
    local _, _, card = player_info(h)
    out[#out + 1] = string.format("0x%08X", card)
  end
  return table.concat(out, " ")
end

-- CMND_FOOTBALLREFORGED_FRIENDLIES_INFO -> ok, active dock (-1 none), 5v5 members of it, bank (1-based), slot
function Friendlies.Info()
  if not ready() then return false end
  local s, b = slot(), bank()
  local active = active_dock()
  local members = 0
  local addr = active and set_addr(active)
  if addr then members = #team_handles(addr, 1) end
  return true, active or -1, members, b + 1, s
end

function Friendlies.Set(set)
  set = int(set, -1)
  if not ready() then return false, C.NOT_READY end
  if is_story() then return false, C.STORY end
  if not is_dock(set) then
    warn("PACHANGA_SET " .. set .. " refused, code " .. C.BAD_ARGS)
    return false, C.BAD_ARGS
  end
  local active = active_dock()
  if active ~= set then
    warn(string.format("PACHANGA_SET dock %02d refused, code %d: the active pachanga team follows the active match team (%s)",
      dock_no(set), C.PAIRED, active and string.format("dock %02d", dock_no(active)) or "none"))
    return false, C.PAIRED
  end
  return true, C.OK
end

function Friendlies.Captain()
  if not ready() then return false, 0, 0 end
  local set = active_dock()
  if not set then return false, 0, 0 end
  local addr = set_addr(set)
  if not addr then return false, 0, 0 end
  local team = addr + TEAM_SIZE
  return true, read_memory("u32", team + CAPTAIN_PARAM) or 0, read_memory("u32", team + CAPTAIN_HDL) or 0
end

local note = ""
function Friendlies.Note(op, text)
  if op == "set" then note = tostring(text or "") end
  return note
end

function Friendlies.Flags()
  if not ready() then return -1 end
  local miss = {}
  for l = FIRST_DOCK, LAST_DOCK do
    local addr = set_addr(l)
    if not addr then return -1 end
    for t = 0, 1 do
      for k = 0, MEMBERS - 1 do
        local h = member_handle(addr, t, k)
        if h ~= 0 then
          local f = team_flag(h)
          if f and band(f, lshift(1, l)) == 0 then miss[#miss + 1] = { addr + member_off(t, k), l } end
        end
      end
    end
  end
  local fixed = 0
  for _, m in ipairs(miss) do
    if set_bit(m[1], m[2], true) then fixed = fixed + 1 end
  end
  if fixed > 0 then info(fixed .. " dock bit(s) put back on 11v11 / 5v5 members") end
  return fixed
end

-- CMND_FOOTBALLREFORGED_FRIENDLIES_MIRROR(dock, 5v5 formation) -> changes, removed, added.
function Friendlies.Mirror(set, formation)
  set = int(set, -1)
  formation = int(formation, 0) % 4294967296
  if not ready() or not is_dock(set) or is_story() or is_mode_save() then return -1, 0, 0 end
  local addr = set_addr(set)
  if not addr then return -1, 0, 0 end
  local s, b = slot(), bank()
  local f = with_pt(s)
  local first = not is_mirrored(f, b, set)
  local a, e = entries(addr, 0), entries(addr, 1)
  local pool, in_a, order = {}, {}, {}
  for k = 0, MEMBERS - 1 do
    local x = a[k]
    if x.h ~= 0 then
      in_a[x.h] = true
      if x.pos < PLAYER_POSITIONS and not pool[x.h] then
        pool[x.h] = x
        order[#order + 1] = x
      end
    end
  end
  table.sort(order, function(p, q) return p.pos < q.pos end)
  local refill = false
  if first then
    for k = 0, MEMBERS - 1 do
      local x = e[k]
      if x.h ~= 0 and x.pos < STARTERS and not pool[x.h] then refill = true end
    end
  end
  -- players outside the pool leave (the dock bit first, while the entry still names him)
  local removed, added, moved = {}, {}, 0
  for k = 0, MEMBERS - 1 do
    local x = e[k]
    if x.h ~= 0 and x.pos < PLAYER_POSITIONS and not pool[x.h] then
      if not in_a[x.h] then set_bit(x.at, set, false) end
      removed[#removed + 1] = x.h
      clear_member(addr, 1, k)
      x.h = 0
    end
  end
  local in_b, taken = {}, {}
  for k = 0, MEMBERS - 1 do
    local x = e[k]
    if x.h ~= 0 then
      in_b[x.h] = true
      if x.pos < PLAYER_POSITIONS and taken[x.pos] == nil then taken[x.pos] = x end
    end
  end
  local need = {}
  if refill then
    for p = 0, STARTERS - 1 do
      if taken[p] then
        need[#need + 1] = { h = taken[p].h, entry = taken[p], src = pool[taken[p].h] }
        taken[p] = nil
      end
    end
  end
  for _, x in ipairs(order) do
    if not in_b[x.h] then need[#need + 1] = { h = x.h, src = x } end
  end
  local free = {}
  for k = 0, MEMBERS - 1 do
    if e[k].h == 0 then free[#free + 1] = e[k] end
  end
  local function place(c, p)
    if c.entry then
      write_memory("u8", c.entry.at + MEMBER_POSITION, p)
      c.entry.pos = p
      taken[p] = c.entry
      moved = moved + 1
      return true
    end
    local x = table.remove(free, 1)
    if not x then return false end
    for o = 0, MEMBER_STRIDE - 4, 4 do write_memory("u32", x.at + o, read_memory("u32", c.src.at + o) or 0) end
    write_memory("u8", x.at + MEMBER_POSITION, p)
    x.h, x.pos = c.h, p
    taken[p] = x
    added[#added + 1] = c.h
    return true
  end
  -- the formation's roles, read only when a starter position is empty
  local roles = nil
  local facts = {}
  local function fact(h)
    if not facts[h] then
      local pos, lv = player_info(h)
      facts[h] = { pos = pos, lv = lv }
    end
    return facts[h]
  end
  for p = 0, STARTERS - 1 do
    if taken[p] == nil then
      if roles == nil then roles = (formation ~= 0 and formation_roles(formation)) or false end
      local cands = {}
      for _, c in ipairs(need) do
        if not c.done then cands[#cands + 1] = c end
      end
      for q = STARTERS, PLAYER_POSITIONS - 1 do
        local x = taken[q]
        if x and pool[x.h] then cands[#cands + 1] = { h = x.h, entry = x, src = pool[x.h], bench = q } end
      end
      local want = (roles and roles[p]) or (p == 0 and GOALKEEPER or nil)
      local best, key = nil, nil
      for _, c in ipairs(cands) do
        local i = fact(c.h)
        local k = {
          (want and i.pos == want) and 1 or 0,
          (c.src and c.src.pos < MATCH_STARTERS) and 1 or 0,
          i.lv,
          -(c.src and c.src.pos or PLAYER_POSITIONS),
        }
        local better = best == nil
        if not better then
          for j = 1, #k do
            if k[j] ~= key[j] then
              better = k[j] > key[j]
              break
            end
          end
        end
        if better then best, key = c, k end
      end
      if best then
        if best.bench then taken[best.bench] = nil end
        if place(best, p) then best.done = true end
      end
    end
  end
  -- the rest of the pool on the bench, in 11v11 order
  for _, c in ipairs(need) do
    if not c.done then
      local p = nil
      for q = STARTERS, PLAYER_POSITIONS - 1 do
        if taken[q] == nil then
          p = q
          break
        end
      end
      if p == nil or not place(c, p) then
        warn(string.format("dock %02d: no free 5v5 place for card 0x%08X", dock_no(set), select(3, player_info(c.h))))
      end
      c.done = true
    end
  end
  local changes = #removed + #added + moved
  if changes > 0 then
    recount(addr, 1)
    recount_team_info(addr + TEAM_SIZE)
  end
  if first and mark_mirrored(f, b, set) then pt_write(f) end
  if changes > 0 then
    info(string.format("slot %d bank %d dock %02d: 5v5 team %s: removed %d [%s], added %d [%s], starters placed %d",
      s, b + 1, dock_no(set), first and (refill and "migrated (old five refilled)" or "migrated (five kept)")
        or "follows the 11v11 team", #removed, cards_text(removed), #added, cards_text(added), moved))
  end
  return changes, #removed, #added
end

-- the dock whose 11v11 / 5v5 member lists are swapped while the team bonuses screen is open
local swapped = nil

local function swap_apply(l)
  local addr = set_addr(l)
  if not addr then return false end
  local a, b = addr + MEMBER_LIST, addr + TEAM_SIZE + MEMBER_LIST
  local xs, ys = {}, {}
  for o = 0, MEMBERS * MEMBER_STRIDE - 4, 4 do
    xs[o], ys[o] = read_memory("u32", a + o), read_memory("u32", b + o)
    if not xs[o] or not ys[o] then
      VRFW.error(string.format("pachanga: pachanga team swap: dock %02d not written", dock_no(l)))
      return false
    end
  end
  for o = 0, MEMBERS * MEMBER_STRIDE - 4, 4 do
    write_memory("u32", a + o, ys[o])
    write_memory("u32", b + o, xs[o])
  end
  recount(addr, 0)
  recount(addr, 1)
  recount_team_info(addr)
  recount_team_info(addr + TEAM_SIZE)
  return true
end

-- a swap still pending (screen closed abnormally, a return to the title) is undone
local function swap_restore(why)
  local l = swapped
  swapped = nil
  if not l then return end
  local ok = swap_apply(l)
  info(string.format("pachanga team swap: dock %02d swapped back (%s) ok=%s", dock_no(l), why, tostring(ok)))
end

-- CMND_FOOTBALLREFORGED_FRIENDLIES_TEAMSWAP(dock, on) -> ok, swapped dock.
function Friendlies.TeamSwap(set, on)
  set, on = int(set, -1), int(on, 0) ~= 0
  if not ready() then return false, -1 end
  swap_restore(on and "new swap" or "screen closed")
  if not on then return true, -1 end
  if not is_dock(set) or is_story() then return false, -1 end
  local ok = swap_apply(set)
  if ok then swapped = set end
  info(string.format("pachanga team swap: dock %02d (logical %d) 5v5 players in team 0 ok=%s", dock_no(set), set, tostring(ok)))
  return ok, ok and set or -1
end

function Friendlies.OnGameReset()
  if ready() then swap_restore("game reset") end
  return false
end

local TEAM_WORDS = TEAM_SIZE / 4
local split_pending = nil

local function split_plan(to_set, from_set, team)
  local v = {}
  if team ~= 0 and team ~= 1 then return v end
  for _, s in ipairs({ to_set, from_set }) do
    local seen = false
    for _, x in ipairs(v) do
      if x[1] == s then seen = true end
    end
    if is_independent(s) and not seen then v[#v + 1] = { s, 1 - team } end
  end
  return v
end

local function read_team(addr)
  local w = {}
  for i = 0, TEAM_WORDS - 1 do
    local x = read_memory("u32", addr + i * 4)
    if x == nil then return nil end
    w[i + 1] = x
  end
  return w
end

function Friendlies.SplitPre(to_set, pos, from_set, hdl, team)
  split_pending = nil
  if not ready() or is_story() or is_mode_save() then return false end
  local plan = split_plan(int(to_set, -1), int(from_set, -1), int(team, 0))
  if #plan == 0 then return false end
  local saved = {}
  for _, p in ipairs(plan) do
    local addr = set_addr(p[1])
    local w = addr and read_team(addr + p[2] * TEAM_SIZE)
    if w then saved[#saved + 1] = { set = p[1], team = p[2], words = w } end
  end
  split_pending = saved
  return false
end

function Friendlies.SplitPost(args, results)
  local saved = split_pending
  split_pending = nil
  if not saved or #saved == 0 or not ready() then return nil end
  for _, s in ipairs(saved) do
    local addr = set_addr(s.set)
    local taddr = addr and addr + s.team * TEAM_SIZE
    local now = taddr and read_team(taddr)
    local same = now ~= nil
    if now then
      for i = 1, TEAM_WORDS do
        if now[i] ~= s.words[i] then same = false end
      end
    end
    if now and not same then
      local ok = true
      for i = 1, TEAM_WORDS do
        if now[i] ~= s.words[i] and not write_memory("u32", taddr + (i - 1) * 4, s.words[i]) then ok = false end
      end
      if not ok then
        warn(string.format("pachanga split: dock %02d team %d not restored", dock_no(s.set), s.team))
      else
        recount_team_info(taddr)
        local bits = 0
        for k = 0, MEMBERS - 1 do
          local h = s.words[(MEMBER_LIST + k * MEMBER_STRIDE) / 4 + 1] or 0
          local f = h ~= 0 and team_flag(h) or nil
          if f ~= nil and band(f, lshift(1, s.set)) == 0 and set_bit(addr + member_off(s.team, k), s.set, true) then
            bits = bits + 1
          end
        end
        info(string.format("pachanga split: dock %02d (logical %d) team %d kept as it was (%d dock bit(s) put back)",
          dock_no(s.set), s.set, s.team, bits))
      end
    end
  end
  return nil
end

if ENABLED then
  info("active (5v5 templates of the team dock; the active pachanga team is the active match team's pair)")
end

-- The formation classes are read at script load, on the boot thread, so the first friendly does not build them.
if ENABLED then pcall(VRFW.formation.prepare) end
