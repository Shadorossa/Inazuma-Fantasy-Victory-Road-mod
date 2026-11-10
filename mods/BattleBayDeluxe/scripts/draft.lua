
local U = require "lib/util"
local G = require "lib/game"
local TeamConfig = VRFW.teams.config

local D = {}

local floor = math.floor

local CANDIDATES = 5
local POS_ANY, POS_GK, POS_DF = 0, 1, 4
local STARTERS = 11
local STAFF = { coach = 5, manager = 6 }
local NONE, PICKING, COMPLETE, CAMPAIGN = 0, 1, 2, 3
local PHASE_NAME = { [0] = "None", "Picking", "Complete", "Campaign" }

local ROSTER_VERSION = 1
local BLOB = "bb_draft.json"               -- the roster of a running draft campaign, per save slot
local FILTER_BLOB = "bb_draft_filters.json" -- the last choices of the Draft's filter panel, per save slot
local FILTER_ROWS = { "scouts", "gender" }
local GENDER_ALL, GENDER_MALE, GENDER_FEMALE = 0, 1, 2 -- The filter's «all» value and the chara_gender values of a person.
-- The values each filter row offers, the default first (scouts: 1 = in the pool, 0 = out).
local FILTER_CHOICES = { scouts = { 1, 0 }, gender = { GENDER_ALL, GENDER_MALE, GENDER_FEMALE } }
local FILTERS = { scouts = 1, gender = GENDER_ALL }
local FILTER_SLOT = nil
local OBJ_SIZE = 0x8A0                     -- the grid object image of the BB pages service (record pass)

local KEY_TEAM = "BattleBayDeluxe.draft.team"
local KEY_PHASE = "BattleBayDeluxe.draft.phase"

local TEXT_ROOT = "data/common/text"

local info, warn, err = VRFW.logger("draft")

local function fail(msg)
  error(msg, 0)
end

local function num_set(list)
  local s = {}
  if type(list) == "table" then
    for _, v in ipairs(list) do
      if type(v) == "number" then
        s[floor(v)] = true
      end
    end
  end
  return s
end

local function num_set_u32(list)
  local s = {}
  if type(list) == "table" then
    for _, v in ipairs(list) do
      if type(v) == "number" then
        s[U.u32(v)] = true
      end
    end
  end
  return s
end

local CFG = {
  team = tostring(U.config("draft.team", "draft")),
  special = num_set(U.config("draft.special_rarities", { 5, 6, 7, 8, 10 })),
  lang = VRFW.strings.trim(tostring(U.config("draft.name_language", "es"))),
  exclude = num_set_u32(U.config("draft.exclude", {})),
  seed = tonumber(U.config("campaign.seed", 0)) or 0,
}

local function toml_u32(v)
  return VRFW.ids.parse(v, { hash_names = true })
end

local function draft_decl(data, name)
  local teams = type(data) == "table" and data.team
  if type(teams) ~= "table" then
    return nil
  end
  for _, t in ipairs(teams) do
    if type(t) == "table" and t.name == name then
      if type(t.key) ~= "string" then
        return nil, "the team has no key"
      end
      local formation = toml_u32(t.formation)
      if not formation then
        return nil, "the team has no formation"
      end
      if type(t.member) ~= "table" then
        return nil, "the team has no member list"
      end
      local members = {}
      for _, m in ipairs(t.member) do
        if type(m) ~= "table" or type(m.slot) ~= "number" then
          return nil, "a member without slot"
        end
        local card = toml_u32(m.card)
        if not card then
          return nil, "a member without card"
        end
        members[#members + 1] = { slot = floor(m.slot) % 256, card = card }
      end
      local level = type(t.level) == "number" and math.max(0, floor(t.level)) or 0
      return { key = t.key, formation = formation, level = level, members = members }
    end
  end
  return nil
end

-- the Draft team's declaration in the mod's own team files (content\teams)
local function find_decl(name)
  local ok, list = pcall(VRFW.files.declarations, "content/teams")
  for _, e in ipairs(ok and type(list) == "table" and list or {}) do
    if e.mod == VRFW.mod then
      local d, why = draft_decl(e.data, name)
      if why then
        return nil, tostring(e.file) .. ": " .. why
      end
      if d then
        return d
      end
    end
  end
  return nil, 'no [[team]] name = "' .. name .. '" in content\\teams'
end

local DECL, DECL_ERR = find_decl(CFG.team)
local TEAM = DECL and VRFW.crc32(DECL.key) or 0

if DECL then
  info(string.format("team %s = %s (%s), %d members, formation %s, level %d", CFG.team, DECL.key, U.hex(TEAM),
    #DECL.members, U.hex(DECL.formation), DECL.level))
else
  warn("off (" .. tostring(DECL_ERR) .. "): the Draft tile of the Campaña does nothing")
end
pcall(VRFW.state.set, KEY_TEAM, TEAM)
pcall(VRFW.state.set, KEY_PHASE, NONE)

function D.team()
  if TEAM == 0 or not VRFW.is_on("CMND_BATTLEBAYDELUXE_DRAFT_INFO") then
    return 0
  end
  return TEAM
end

local function parse_params()
  local out, n = {}, 0
  for _, c in ipairs(VRFW.character.cards({ character = true })) do
    out[U.u32(c.id)] = {
      base = U.u32(c.base),
      element = U.u32(c.element) % 256,
      pos = U.u32(c.position) % 256,
      card = floor(c.rarity),
      coach = c.coach == true,
      manager = c.manager == true,
      gender = floor(c.gender or 0),
    }
    n = n + 1
  end
  if n == 0 then
    fail("chara_param: no CHARA_PARAM_INFO row")
  end
  return out
end

-- { [chara_base id] = name } from chara_base (col 3 = its name text) and one language's chara_text (NOUN_INFO form 0)
local function parse_names(lang)
  local txt = {}
  for _, r in ipairs(VRFW.table.raw(VRFW.table_files.file_name(TEXT_ROOT .. "/" .. lang .. "/chara_text"), "NOUN_INFO", { 1, 2, 6 })) do
    if type(r[1]) == "number" and r[2] == 0 and type(r[6]) == "string" then
      txt[U.u32(r[1])] = VRFW.strings.trim(r[6])
    end
  end
  local out = {}
  for _, c in ipairs(VRFW.character.characters()) do
    local n = txt[U.u32(c.name_text)]
    if n and n ~= "" then
      out[U.u32(c.id)] = n
    end
  end
  return out
end

local function position_class(id)
  if id == 1 then
    return 1
  elseif id == 2 or id == 3 then
    return 4
  elseif id >= 4 and id <= 7 then
    return 3
  end
  return 2
end

local FORMATION_LISTS = nil   -- { forms, places }
local function formation_lists()
  if FORMATION_LISTS == nil then
    local key = VRFW.table_files.file_name(VRFW.table_files.FORMATION_CONFIG)
    local forms = VRFW.table.raw(key, "m_SoccerFormationInfoList")
    local places = VRFW.table.raw(key, "m_SoccerFormPlacementInfoList")
    FORMATION_LISTS = { forms, places }
  end
  return FORMATION_LISTS[1], FORMATION_LISTS[2]
end

local function formation_places(id)
  local forms, places = formation_lists()
  local row
  for _, r in ipairs(forms) do
    if type(r.formId) == "number" and U.u32(r.formId) == id then
      row = r
      break
    end
  end
  if not row then
    fail("formation " .. U.hex(id) .. " not in formation_config")
  end
  local s = row.placementInfo
  if type(s) ~= "table" or type(s.start) ~= "number" or type(s.count) ~= "number" then
    fail("formation " .. U.hex(id) .. ": no placement slice")
  end
  local out = {}
  for k = s.start + 1, s.start + s.count do
    local p = places[k]
    if not p then
      break
    end
    if type(p.positionNo) ~= "number" then
      fail("placement without positionNo")
    end
    local class = position_class(type(p.positionId) == "number" and p.positionId or 0)
    local x, y = 0, 0
    if type(p.startPos) == "table" and type(p.startPos[1]) == "number" and type(p.startPos[2]) == "number" then
      x, y = U.round(p.startPos[1] * 1000), U.round(p.startPos[2] * 1000)
    end
    out[floor(p.positionNo) % 256] = { pos = class, x = x, y = y }
  end
  return out
end

local function slot_specs(decl, places)
  local members = {}
  for i, m in ipairs(decl.members) do
    members[i] = m
  end
  VRFW.lists.stable_sort(members, function(m)
    return m.slot
  end)
  local out = {}
  for _, m in ipairs(members) do
    if m.slot < STARTERS then
      local p = places[m.slot]
      if not p then
        fail("slot " .. m.slot .. ": no placement in the formation")
      end
      out[#out + 1] = { slot = m.slot, pos = p.pos, placeholder = m.card, x = p.x, y = p.y }
    else
      local pos = POS_ANY
      if m.slot == TeamConfig.COACH_SLOT then
        pos = STAFF.coach
      elseif TeamConfig.is_staff(m.slot) then
        pos = STAFF.manager
      end
      out[#out + 1] = { slot = m.slot, pos = pos, placeholder = m.card, x = 0, y = 0 }
    end
  end
  return out
end

local function character_key(param, inf, names)
  local n = names[inf.base]
  if n and n ~= "" then
    return VRFW.crc32("name:" .. n)
  elseif inf.base ~= 0 then
    return inf.base
  end
  return param
end

local function eligible(squad, params, rule, st)
  local out = {}
  for k, m in ipairs(squad) do
    st.members = st.members + 1
    local slot, p = m[1], m[2]
    local inf = params[p]
    if TeamConfig.is_staff(slot) then
      st.staff = st.staff + 1
    elseif not inf then
      st.unknown = st.unknown + 1
    elseif rule.exclude[p] then
      st.excluded = st.excluded + 1
    elseif inf.card ~= nil and rule.special[inf.card] then
      st.special = st.special + 1
    elseif inf.pos < POS_GK or inf.pos > POS_DF then
      st.no_position = st.no_position + 1
    else
      out[#out + 1] = { p, k, m[3] }
    end
  end
  return out
end

local function pool_from(lists, params, keys)
  local count, first, order = {}, {}, {}
  for t, list in ipairs(lists) do
    for _, e in ipairs(list) do
      local p = e[1]
      count[p] = (count[p] or 0) + 1
      if not first[p] then
        first[p] = { t, e[2], e[3] }
        order[#order + 1] = p
      end
    end
  end
  local best, nbest = {}, 0
  for _, p in ipairs(order) do
    local n, f = count[p], first[p]
    local ch = keys[p] or p
    local b = best[ch]
    local better = not b or n > b.n or (n == b.n and (f[1] < b.t or (f[1] == b.t and f[2] < b.k)))
    if better then
      if not b then
        nbest = nbest + 1
      end
      best[ch] = { n = n, t = f[1], k = f[2], p = p, lo = f[3] }
    end
  end
  local out = {}
  for ch, b in pairs(best) do
    local inf = params[b.p]
    out[#out + 1] = { param = b.p, pos = inf.pos, chara = ch, element = inf.element, loadout = b.lo,
      team = lists[b.t].team }
  end
  table.sort(out, function(a, b)
    if a.pos ~= b.pos then
      return a.pos < b.pos
    end
    return a.param < b.param
  end)
  return out, #order - nbest
end

local function staff_from(params, keys, rule)
  local out, seen = {}, {}
  for p, inf in pairs(params) do
    local pos = (inf.coach and STAFF.coach) or (inf.manager and STAFF.manager) or nil
    if pos and not rule.exclude[p] and not (inf.card ~= nil and rule.special[inf.card]) then
      local ch = pos .. ":" .. tostring(keys[p] or p)
      local b = seen[ch]
      if not b or p < b.param then
        if b then
          b.param = p
        else
          b = { param = p, pos = pos, chara = keys[p] or p, element = inf.element }
          seen[ch] = b
          out[#out + 1] = b
        end
      end
    end
  end
  table.sort(out, function(a, b)
    if a.pos ~= b.pos then
      return a.pos < b.pos
    end
    return a.param < b.param
  end)
  return out
end

local STATIC = nil
local function static_tables()
  if STATIC then
    return STATIC
  end
  STATIC = VRFW.derived("draft_pool_tables_3", nil, function()
    local places = formation_places(DECL.formation)
    local slots = slot_specs(DECL, places)
    local params = parse_params()
    local nok, names = pcall(parse_names, CFG.lang)
    if not nok then
      warn("character names not read (" .. tostring(names) .. "): variants of one character count by chara_base")
      names = {}
    end
    local keys = {}
    for p, inf in pairs(params) do
      keys[p] = character_key(p, inf, names)
    end
    return { slots = slots, params = params, keys = keys }
  end)
  return STATIC
end

local function index_players(pool)
  local by = {}
  for _, p in ipairs(pool.players) do
    by[p.param] = p
  end
  for _, p in ipairs(pool.staff or {}) do
    by[p.param] = by[p.param] or p
  end
  pool.by = by
end

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
      return "player " .. U.hex(p.param) .. " twice or zero"
    end
    ids[p.param] = true
    if p.chara ~= 0 then
      if charas[p.chara] then
        return "character " .. U.hex(p.chara) .. " twice (player " .. U.hex(p.param) .. ")"
      end
      charas[p.chara] = true
    end
    if p.pos < POS_GK or p.pos > POS_DF then
      return "player " .. U.hex(p.param) .. " position " .. p.pos
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
  local m = U.struct("MemberRow", row.addr)
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
    warn("stored formation " .. U.hex(formation) .. " not readable: the team's own formation")
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
  if type(doc) ~= "table" or doc.version ~= ROSTER_VERSION or U.u32(doc.team) ~= pool.team then
    return nil, string.format("version %s / team %s (pool team %s)", tostring(type(doc) == "table" and doc.version),
      U.hex(type(doc) == "table" and doc.team or 0), U.hex(pool.team))
  end
  local by, n, entries = {}, 0, 0
  for _, e in ipairs(type(doc.roster) == "table" and doc.roster or {}) do
    entries = entries + 1
    if type(e) == "table" and type(e[1]) == "number" and type(e[2]) == "number" then
      if by[e[1]] == nil then
        n = n + 1
      end
      by[e[1]] = U.u32(e[2])
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

local RT = nil       -- { pool, draft, phase, written, src }
local FAILED = false
local BEGUN = 0

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
      merged, #slots, U.hex(DECL.formation)))
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
  FAILED = true
  return nil
end

local function with()
  if RT == nil and not FAILED then
    RT = build()
  end
  return RT
end

if DECL then
  local t0 = VRFW.now_ms()
  local ok, e = pcall(static_tables)
  if ok then
    info(string.format("pool tables read at load in %d ms (%d slots)", VRFW.now_ms() - t0, #e.slots))
  else
    info("pool tables not read at load (" .. tostring(e) .. "): read by the first build")
  end
  if ok and RT == nil and not FAILED then
    RT = build("script load")
  end
end

VRFW.on("slot_load", function(ev)
  if RT == nil and not FAILED and D.team() ~= 0 then
    local r = build("save load")
    if r and RT == nil then
      RT = r
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
      return nil, "write of row at " .. U.hex(w.row.addr) .. " failed"
    end
  end
  -- the team plays the draft's formation (the team's own when it has none / without a draft)
  local fm = (r.draft and r.draft.formation) or r.pool.formation
  local rec = now.rec and U.struct("TeamRecord", now.rec)
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
    warn("leader not checked (" .. why .. "): roster rows of " .. U.hex(team) .. ": " .. tostring(rerr))
    return nil
  end
  local lead = leader_of(rows)
  if not lead then
    return nil
  end
  local row = G.enjoy_row(team)
  local er = row and U.struct("EnjoyRow", row)
  if not er then
    warn("leader not checked (" .. why .. "): no enjoy row of " .. U.hex(team) .. " in memory")
    return nil
  end
  local old = U.get(er, "leader") or 0
  if old == lead then
    return lead
  end
  if pcall(function()
    er.leader = lead
  end) then
    info(string.format("Draft row leader %s -> %s (slot 0 member, %s)", U.hex(old), U.hex(lead), why))
    return lead
  end
  err(string.format("Draft row leader NOT written (%s): %s stays, not a member", why, U.hex(old)))
  return nil
end

-- The drafted squad only lives on the team's rows in memory.

D.tournament_team = nil

local function tournament_owns(team)
  if type(D.tournament_team) ~= "function" then
    return false
  end
  local ok, t = pcall(D.tournament_team)
  return ok and type(t) == "number" and t ~= 0 and U.u32(t) == team
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
  local lead = er and U.get(U.struct("EnjoyRow", er), "leader") or nil
  if lead ~= nil and not ids[lead] then
    return false, "enjoy row leader " .. U.hex(lead) .. " is no member"
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
      local d = draft_from_picks(picks, r.pool, type(doc.formation) == "number" and U.u32(doc.formation) or nil)
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
  if D.team() == 0 or FAILED then
    return
  end
  local has = false
  local n = slot or VRFW.slots.active()
  SLOT_DONE = n
  has = type(VRFW.save.doc.read_text(BLOB, n)) == "string"
  if not has and RT == nil then
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
    err("campaign start: roster rows of " .. U.hex(team) .. " unreadable: " .. tostring(why))
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
  local leader = row and U.get(U.struct("EnjoyRow", row), "leader") or 0
  info(string.format("campaign start with %s: %d rows [%s], enjoy leader %s (member: %s)", U.hex(team), #rows,
    table.concat(list, " "), U.hex(leader), tostring(member)))
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

local function locked_of(src, pending)
  if not VRFW.is_on("EvalCondition") then
    return nil
  end
  local out = {}
  for _, t in ipairs(pending) do
    for _, c in ipairs(src.conds and src.conds[t] or {}) do
      if c ~= 0 and G.eval(c) ~= true then
        out[t] = true
        break
      end
    end
  end
  return out
end

local function open_pool(r)
  local src = r.src
  if not src then
    return
  end
  local pending = {}
  for _, sq in ipairs(src.squads) do
    if (G.unlock_rule(sq.team) or -1) == 0 then
      pending[#pending + 1] = sq.team
    end
  end
  local players = src.all
  if #pending > 0 then
    local locked = locked_of(src, pending)
    if locked then
      local shut, nshut, sig = {}, 0, {}
      for _, t in ipairs(pending) do
        if locked[t] then
          shut[t] = true
          nshut = nshut + 1
          sig[#sig + 1] = t
        end
      end
      local key = table.concat(sig, ",")
      local o = src.open
      if not o or o.key ~= key then
        -- the pool of these squads (none left out = the derived pool), kept until the locked set changes
        local lists = {}
        for _, sq in ipairs(src.squads) do
          if not shut[sq.team] then
            lists[#lists + 1] = sq.elig
          end
        end
        local pl = nshut == 0 and src.all or pool_from(lists, src.params, src.keys)
        o = { key = key, players = pl, squads = #lists, shut = nshut,
          bad = validate({ team = r.pool.team, slots = r.pool.slots, players = pl, staff = r.pool.staff }) }
        src.open = o
      end
      if not o.bad then
        info(string.format("pool of this draft: %d players from %d squads (%d squad(s) of teams still locked left out)",
          #o.players, o.squads, o.shut))
        players = o.players
      else
        warn(string.format("without the %d locked squad(s) the pool cannot fill the draft (%s): every squad is used",
          o.shut, o.bad))
      end
    else
      warn("the unlock conditions cannot be evaluated: every squad is used")
    end
  end
  src.base = players
  if r.pool.players ~= players then
    r.pool.players = players
    index_players(r.pool)
  end
end

local function filters_load()
  local n = VRFW.save.doc.slot()
  if FILTER_SLOT == n then
    return
  end
  FILTER_SLOT = n
  for _, k in ipairs(FILTER_ROWS) do
    FILTERS[k] = FILTER_CHOICES[k][1]
  end
  local b = VRFW.save.doc.read_text(FILTER_BLOB, n)
  if type(b) == "string" then
    local doc = VRFW.json.decode(b)
    if type(doc) == "table" then
      for _, k in ipairs(FILTER_ROWS) do
        if type(doc[k]) == "number" then
          FILTERS[k] = doc[k]
        end
      end
    end
  end
end

local function filters_save()
  local ok, why = VRFW.save.doc.write_text(FILTER_BLOB, VRFW.json.encode(FILTERS, true), VRFW.save.doc.slot())
  if not ok then
    warn(FILTER_BLOB .. " not written: " .. tostring(why))
  end
end

-- the characters (chara_base ids) that speak with a generic scout voice: the scouts
local SCOUT_BASES = nil
local function scout_bases()
  if SCOUT_BASES then
    return SCOUT_BASES
  end
  local voices, v = VRFW.table_files.read("character/general_battle_voice", "m_generalBattleVoice", { "voice_id" })
  local bases, b = VRFW.table_files.read("character/chara_base", "CHARA_BASE_INFO", { "id", "voice_bank" })
  if not (voices and bases) then
    fail("scout voices unreadable: " .. tostring(v or b))
  end
  local generic = {}
  for _, r in ipairs(voices) do
    generic[U.u32(r[v.voice_id])] = true
  end
  SCOUT_BASES = {}
  for _, r in ipairs(bases) do
    if generic[U.u32(r[b.voice_bank])] then
      SCOUT_BASES[U.u32(r[b.id])] = true
    end
  end
  return SCOUT_BASES
end

-- one row's next value (dir 1 / -1), wrapping; a stored value the row no longer offers shows as its first
local function filter_step(key, dir)
  local list, at = FILTER_CHOICES[key], 0
  for i, v in ipairs(list) do
    if v == FILTERS[key] then
      at = i
    end
  end
  if at == 0 then
    FILTERS[key], at = list[1], 1
  end
  if dir ~= 0 then
    FILTERS[key] = list[(at - 1 + (dir > 0 and 1 or -1)) % #list + 1]
  end
end

local function filtered_players(src)
  local scouts = FILTERS.scouts ~= 0 and {} or scout_bases()
  local out = {}
  for _, p in ipairs(src.base or src.all) do
    local inf = src.params[p.param]
    local person = inf and (inf.gender == GENDER_MALE or inf.gender == GENDER_FEMALE)
    if person and (FILTERS.gender == GENDER_ALL or inf.gender == FILTERS.gender) and not scouts[inf.base] then
      out[#out + 1] = p
    end
  end
  return out
end

-- can `players` fill the places of `slots` still open (`picks` by place index)?
local function slots_feasible(slots, players, picks)
  local picked, have, need = {}, {}, {}
  local free, open = 0, 0
  for _, id in pairs(picks) do
    picked[id] = true
  end
  for _, p in ipairs(players) do
    if not picked[p.param] then
      have[p.pos] = (have[p.pos] or 0) + 1
      free = free + 1
    end
  end
  for k, s in ipairs(slots) do
    if not picks[k] and s.pos <= POS_DF then
      open = open + 1
      if s.pos >= POS_GK then
        need[s.pos] = (need[s.pos] or 0) + 1
      end
    end
  end
  for pos, n in pairs(need) do
    if (have[pos] or 0) < n then
      return false
    end
  end
  return free >= open
end

local formation_list -- defined with the formation offer, below

local FORMATION_SLOTS = {}
local function formation_slots(id)
  if FORMATION_SLOTS[id] == nil then
    local ok, places = pcall(formation_places, id)
    local ok2, slots = false, nil
    if ok then
      ok2, slots = pcall(slot_specs, DECL, places)
    end
    FORMATION_SLOTS[id] = ok2 and slots or false
  end
  return FORMATION_SLOTS[id] or nil
end

-- the pool the player's filters leave fills a draft: true (and the formation to start in, when the team's own cannot be filled)
local function pool_fillable(r, players)
  if slots_feasible(r.pool.slots, players, {}) then
    return true
  end
  local ok, list = pcall(formation_list)
  if ok then
    for _, id in ipairs(list) do
      local slots = formation_slots(id)
      if slots and slots_feasible(slots, players, {}) then
        return true, id
      end
    end
  end
  return false
end

-- row (-1 = read), dir -> ok, the row values, the filtered pool fills a draft, its size
function BattleBayDeluxe.DraftFilters(row, dir)
  local r = with()
  if not r then
    return false
  end
  filters_load()
  open_pool(r)
  row, dir = U.int(row, -1), U.int(dir, 0)
  for i, key in ipairs(FILTER_ROWS) do
    filter_step(key, (i - 1 == row) and dir or 0)
  end
  local players = filtered_players(r.src)
  local fine = pool_fillable(r, players)
  return true, FILTERS.scouts, FILTERS.gender, fine, #players
end

function BattleBayDeluxe.DraftBegin(filtered)
  local r = with()
  local total = nil
  if r then
    open_pool(r)
    local start_formation = nil
    if U.int(filtered, 0) == 1 then
      filters_load()
      local players = filtered_players(r.src)
      local fine, alt = pool_fillable(r, players)
      if not fine then
        warn(string.format("the filters leave %d players: not enough for a draft", #players))
        return false, 0
      end
      start_formation = alt
      if r.pool.players ~= players then
        r.pool.players = players
        index_players(r.pool)
      end
      filters_save()
    end
    local n = BEGUN
    BEGUN = BEGUN + 1
    local h, l
    if CFG.seed ~= 0 then
      h, l = U.split64(CFG.seed)
      l = bit32.bxor(l, 0xD4AF7000, n % U.TWO32)
    else
      h, l = U.entropy(U.global("enjoy") or 0, n)
    end
    local ok, why = restore(r)
    if ok then
      r.draft = new_draft(U.rng(h, l), #r.pool.slots)
      if start_formation then
        draft_formation(r.draft, r.pool, start_formation)
      end
      set_phase(r, PICKING)
      total = #r.pool.slots
      info(string.format("begin (seed %s:%s, %d picks, %d players)", U.hex(h), U.hex(l), total, #r.pool.players))
    else
      err("cannot begin, roster rows of " .. U.hex(r.pool.team) .. ": " .. tostring(why))
    end
  end
  if total then
    sync_leader("begin")
  end
  return total ~= nil, total or 0
end

function BattleBayDeluxe.DraftSlots()
  local r = with()
  if not r then
    return false
  end
  return true, #r.pool.slots
end

function BattleBayDeluxe.DraftSlot(k)
  k = U.int(k, -1)
  local r = with()
  local e = r and k >= 0 and session_slots(r)[k + 1]
  if not e then
    return false
  end
  local s = e.spec
  return true, s.slot, s.pos, s.x, s.y, e.pick or 0, s.placeholder
end

local PLACES = {}

function BattleBayDeluxe.FormationPlace(formation, slot)
  local id = U.u32(formation)
  slot = U.int(slot, -1)
  if id == 0 or slot < 0 then
    return false
  end
  local places = PLACES[id]
  if places == nil then
    local ok, got = pcall(formation_places, id)
    places = ok and got or false
    PLACES[id] = places
    if not ok then
      warn("formation place: " .. tostring(got))
    end
  end
  local p = places and places[slot]
  if not p then
    return false
  end
  return true, p.pos, p.x, p.y
end

function BattleBayDeluxe.DraftCandidates(k)
  k = U.int(k, -1)
  local r = with()
  if not r or r.phase ~= PICKING or k < 0 or not r.draft then
    return false
  end
  local spec = draft_slots(r.draft, r.pool)[k + 1]
  if not spec then
    return false
  end
  local list = candidates(r.draft, r.pool, k + 1)
  if #list == 0 then
    return false
  end
  local out = { true, k, spec.slot, spec.pos, #list }
  for _, p in ipairs(list) do
    out[#out + 1] = p.param
    out[#out + 1] = p.pos
    out[#out + 1] = p.team or 0   -- staff cards come from no squad: 0, no crest
  end
  return table.unpack(out)
end

function BattleBayDeluxe.DraftPick(k, i)
  k, i = U.int(k, -1), U.int(i, -1)
  local r = with()
  local got
  if r then
    local why
    if r.phase ~= PICKING or k < 0 or i < 0 or not r.draft then
      why = string.format("pick %d/%d refused (phase %s)", k, i, PHASE_NAME[r.phase] or tostring(r.phase))
    else
      local spec, id = draft_pick(r.draft, r.pool, k + 1, i)
      if not spec then
        why = id
      else
        local want = draft_roster(r.draft, r.pool)
        local fin, n = done(r.draft), filled(r.draft)
        local ok, aerr = apply(r, want)
        if not ok then
          restore(r)
          why = aerr
        else
          if fin then
            set_phase(r, COMPLETE)
          end
          got = { done = fin, slot = spec.slot, id = id, filled = n }
        end
      end
    end
    if got then
      info(string.format("pick %d/%d: slot %d = %s", got.filled, #r.pool.slots, got.slot, U.hex(got.id)))
      if got.done then
        info(string.format("complete (%d players on the rows of %s)", #r.pool.slots, U.hex(r.pool.team)))
      end
    else
      warn(tostring(why))
    end
  end
  if got then
    sync_leader("pick")
    return true, got.done, got.slot, got.id, got.filled
  end
  return false
end

local FORMATION_LIST = nil
local SPOT_PRECISION = 100
local function two_on_one_spot(places, s)
  local seen = {}
  for k = s.start + 1, s.start + s.count do
    local at = places[k] and places[k].offensePos
    if type(at) == "table" and type(at[1]) == "number" and type(at[2]) == "number" then
      local spot = U.round(at[1] * SPOT_PRECISION) .. ":" .. U.round(at[2] * SPOT_PRECISION)
      if seen[spot] then
        return true
      end
      seen[spot] = true
    end
  end
  return false
end

formation_list = function()
  if FORMATION_LIST then
    return FORMATION_LIST
  end
  local forms, places = formation_lists()
  local out, names = {}, {}
  for _, row in ipairs(forms) do
    local s = row.placementInfo
    local id = type(row.formId) == "number" and U.u32(row.formId) or 0
    local noun = type(row.nounId) == "number" and U.u32(row.nounId) or 0
    if id ~= 0 and type(s) == "table" and s.count == STARTERS and type(s.start) == "number"
        and (noun == 0 or not names[noun]) then
      local keepers, ok = 0, true
      for k = s.start + 1, s.start + s.count do
        local p = places[k]
        if not p or type(p.positionId) ~= "number" then
          ok = false
          break
        end
        if position_class(p.positionId) == POS_GK then
          keepers = keepers + 1
        end
      end
      if ok and keepers == 1 and not two_on_one_spot(places, s) then
        if noun ~= 0 then
          names[noun] = true
        end
        out[#out + 1] = id
      end
    end
  end
  FORMATION_LIST = out
  info(string.format("%d formations to choose from", #out))
  return out
end

local FORMATION_OFFER = 5
local function formation_offer(d, list)
  if not d then
    return list
  end
  if not d.fm_offer then
    local pool = {}
    for i, id in ipairs(list) do
      pool[i] = id
    end
    d.rng:shuffle(pool)
    d.fm_offer = {}
    for i = 1, math.min(FORMATION_OFFER, #pool) do
      d.fm_offer[i] = pool[i]
    end
  end
  return d.fm_offer
end

function BattleBayDeluxe.DraftFormations(start)
  start = math.max(0, U.int(start, 0))
  local r = with()
  local ok, list = pcall(formation_list)
  if not r or not ok then
    if not ok then
      warn("formation list: " .. tostring(list))
    end
    return false
  end
  local current = (r.draft and r.draft.formation) or r.pool.formation
  if r.pool.players ~= (r.src.base or r.src.all) then
    -- a filtered pool offers the formations it can fill
    local can = {}
    for _, id in ipairs(list) do
      local slots = formation_slots(id)
      if slots and slots_feasible(slots, r.pool.players, {}) then
        can[#can + 1] = id
      end
    end
    list = can
  end
  list = formation_offer(r.draft, list)
  local out = { true, #list, current }
  for i = start + 1, math.min(#list, start + 12) do
    out[#out + 1] = list[i]
  end
  return table.unpack(out)
end

function BattleBayDeluxe.DraftSetFormation(formation)
  local id = U.u32(formation)
  local r = with()
  if not r or (r.phase ~= PICKING and r.phase ~= COMPLETE) or not r.draft or id == 0 then
    return false
  end
  if r.pool.players ~= (r.src.base or r.src.all) then
    -- a filtered pool must still fill the open places in the new formation
    local slots = (id == r.pool.formation) and r.pool.slots or formation_slots(id)
    if not slots or not slots_feasible(slots, r.pool.players, r.draft.picks) then
      info("formation " .. U.hex(id) .. " not set: the filtered pool cannot fill it")
      return false
    end
  end
  local ok, why = draft_formation(r.draft, r.pool, id)
  if ok then
    ok, why = apply(r, draft_roster(r.draft, r.pool))
  end
  if not ok then
    warn("formation " .. U.hex(id) .. " not set: " .. tostring(why))
    return false
  end
  info("formation " .. U.hex(id))
  return true
end

function BattleBayDeluxe.DraftAbandon()
  local r = RT
  if r and (r.phase == PICKING or r.phase == COMPLETE) then
    local ok, why = restore(r)
    if ok then
      info("abandoned: placeholders back")
    else
      err("abandoned, placeholders NOT written back (" .. tostring(why) .. ")")
    end
  end
  sync_leader("abandon")
  return true
end

local PACK = nil
local PACK_KEYS = {
  { "intro", 0.25 }, { "deal", 0.22 }, { "deal_stagger", 0.07 }, { "flip", 0.22 }, { "settle", 0.12 },
  { "flash", 0.30 }, { "gap", 0.45 }, { "suspense", 0.40 }, { "outro", 0.28 }, { "dim", 0.72 }, { "scale", 1.6 },
  { "spacing", 330 },
}
local PACK_SE = { { "se_open", "sy0000" }, { "se_deal", "sy0009" }, { "se_reveal", "sy0010" }, { "se_best", "sy0080" } }

local function pack_look()
  if PACK then
    return PACK
  end
  local t = U.config("draft.pack", nil)
  if type(t) ~= "table" then
    t = {}
  end
  local function get(k, d)
    local v = t[k]
    if v == nil then
      v = U.config("draft.pack." .. k, d)
    end
    return v
  end
  local out = {}
  for _, kv in ipairs(PACK_KEYS) do
    local v = tonumber(get(kv[1], kv[2]))
    if v == nil or v < 0 then
      warn("[draft.pack] " .. kv[1] .. ": not a number >= 0, " .. tostring(kv[2]) .. " used")
      v = kv[2]
    end
    out[#out + 1] = v
  end
  for _, kv in ipairs(PACK_SE) do
    local v = get(kv[1], kv[2])
    if type(v) ~= "string" or VRFW.strings.trim(v) == "" then
      v = kv[2]
    end
    out[#out + 1] = VRFW.crc32(VRFW.strings.trim(v))
  end
  PACK = out
  info("pack opening look: " .. #out .. " values from [draft.pack]")
  return PACK
end

function BattleBayDeluxe.DraftPack()
  local ok, p = pcall(pack_look)
  if not ok then
    err("[draft.pack] unreadable: " .. tostring(p))
    return false
  end
  return true, table.unpack(p)
end

-- how the starters' cards fit the Draft's pitch (config.toml [draft.pitch]), asked once per menu by the graft
function BattleBayDeluxe.DraftPitch()
  local t = U.config("draft.pitch", nil)
  if type(t) ~= "table" then
    return false
  end
  local out = {}
  for i, key in ipairs({ "card_scale", "card_width", "card_height", "card_gap", "edge_margin", "same_row_distance",
                         "symmetry_tolerance" }) do
    if type(t[key]) ~= "number" then
      err("[draft.pitch] " .. key .. " is not a number")
      return false
    end
    out[i] = t[key]
  end
  return true, table.unpack(out)
end

function BattleBayDeluxe.DraftMouse()
  local v = U.config("draft.mouse", true)
  return true, v ~= false
end

function D.sync(active, player)
  ensure_slot()
  local team0 = D.team()
  local owned = (active and player ~= 0 and player == team0) or (team0 ~= 0 and tournament_owns(team0))
  if RT == nil and not FAILED and not owned then
    if D.team() == 0 then
      return -1, false
    end
    drop_roster(string.format("top menu sync: no campaign with the Draft team (campaign %s, player team %s)", tostring(active), U.hex(player)))
    sync_leader("sync")
    return NONE, false
  end
  local r = with()
  local phase = -1
  local lost = false
  if r then
    local was = r.phase
    local team = r.pool.team
    local ours = team ~= 0 and ((active and player == team) or tournament_owns(team))
    if ours and (was == COMPLETE or was == CAMPAIGN) then
      local want = r.draft and draft_roster(r.draft, r.pool) or {}
      campaign_started(r)
      local ok, why = apply(r, want)
      if ok then
        if was == COMPLETE then
          save_roster(r)
        end
      else
        err("campaign running but the roster was not written again: " .. tostring(why))
      end
    elseif ours then
      local _, _, gone = restore_run(r, "top menu sync")
      lost = gone == true
    else
      local ok, why = true, nil
      local n = 0
      if was ~= NONE then
        n, why = restore(r)
        ok = n ~= nil
      end
      if ok then
        if was ~= NONE then
          info("discarded (campaign over or another team): placeholders back (" .. n .. " rows)")
        end
      else
        err("discarded, placeholders NOT written back (" .. tostring(why) .. ")")
      end
      drop_roster(string.format("top menu sync: campaign over or another team (campaign %s, player team %s, phase %d)", tostring(active), U.hex(player), was))
    end
    phase = r.phase
  end
  sync_leader("sync")
  return phase, lost
end

-- The team panel shows the hovered slot's leader as its 3D model.

local AVATAR_LOGGED = nil

local function record_object(hdl)
  if not VRFW.is_on("FindCharaRecord") or hdl == 0 or hdl % 65536 >= 0xD000 then
    return nil
  end
  local kind = floor(hdl / 4096) % 16
  local conts = U.global("chara_containers")
  local cont = conts and U.rdp(conts + 8 + kind * 8)
  if not cont then
    return nil
  end
  local hb = VRFW.memory.buffer("bbd_avatar_hdl", 4)
  local okb = hb ~= nil
  if not okb or not U.wr("u32", hb, hdl) then
    return nil
  end
  local ok, rec = U.call("FindCharaRecord", cont, hb)
  if ok and type(rec) == "number" and rec >= 0x10000 then
    return rec
  end
  return nil
end

local function avatar_param()
  local kz = U.struct("Kizuna", U.global("kizuna"))
  local hdl, idx = U.get(kz, "avatar"), U.get(kz, "avatar_index")
  if not hdl or idx ~= 0 or hdl == 0 or hdl % 65536 >= 0xD000 then
    return nil
  end
  local obj = record_object(hdl)
  local rec8 = obj and U.rdp(obj + 8)
  if not rec8 or U.rd("u32", rec8) ~= hdl then
    return nil
  end
  local p = U.rd("u32", rec8 + 4)
  if p and p ~= 0 then
    return p
  end
  return nil
end

VRFW.on("hook:VRFW.BattleBayRecord", function(ev)
  local img, len = ev.args[1], ev.args[2]
  if type(img) ~= "number" or img < 0x10000 or type(len) ~= "number" or len < OBJ_SIZE then
    return nil
  end
  local team = D.team()
  if team == 0 then
    return nil
  end
  local avatar = avatar_param()
  local key = avatar or 0
  if AVATAR_LOGGED ~= key then
    AVATAR_LOGGED = key
    if avatar then
      info("the Draft tile's panel model = the player's avatar " .. U.hex(avatar))
    else
      warn("no usable Kizuna avatar in this save: the Draft tile keeps its placeholder model")
    end
  end
  if not avatar then
    return nil
  end
  if not G.slot_base() then
    return nil
  end
  for i = 0, G.SLOTS - 1 do
    local rec = G.slot_addr(img, i)
    if U.rd("u32", rec + 0x4) == team and U.rd("u32", rec + 0x8) ~= avatar then
      U.wr("u32", rec + 0x8, avatar)
    end
  end
  return nil
end)

return D
