-- The Draft's pool: the team's parameters, names, formations, places, the eligible players and staff, and the static tables.
local Shared = require "lib/draft/context"
local TeamConfig = Shared.TeamConfig
local D = Shared.D
local floor = math.floor
local POS_ANY = Shared.POS_ANY
local POS_GK = Shared.POS_GK
local POS_DF = Shared.POS_DF
local STARTERS = Shared.STARTERS
local STAFF = Shared.STAFF
local fail = Shared.fail
local CFG = Shared.CFG
local DECL = Shared.DECL
local TEAM = Shared.TEAM

function D.team()
  if TEAM == 0 or not VRFW.is_on("CMND_BATTLEBAYDELUXE_DRAFT_INFO") then
    return 0
  end
  return TEAM
end

local function parse_params()
  local out, n = {}, 0
  for _, c in ipairs(VRFW.character.cards({ character = true })) do
    out[VRFW.ids.unsigned(c.id)] = {
      base = VRFW.ids.unsigned(c.base),
      element = VRFW.ids.unsigned(c.element) % 256,
      pos = VRFW.ids.unsigned(c.position) % 256,
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
    if type(r.formId) == "number" and VRFW.ids.unsigned(r.formId) == id then
      row = r
      break
    end
  end
  if not row then
    fail("formation " .. VRFW.ids.hex_text(id) .. " not in formation_config")
  end
  local s = row.placementInfo
  if type(s) ~= "table" or type(s.start) ~= "number" or type(s.count) ~= "number" then
    fail("formation " .. VRFW.ids.hex_text(id) .. ": no placement slice")
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
      x, y = VRFW.value.round(p.startPos[1] * 1000), VRFW.value.round(p.startPos[2] * 1000)
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

-- one key per person (VRFW.persons: every version of one character), the card itself when it has no character
local function character_key(param, inf)
  if inf.base ~= 0 then
    return VRFW.persons.of_character(inf.base)
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
  STATIC = VRFW.derived("draft_pool_tables_4", nil, function()
    local places = formation_places(DECL.formation)
    local slots = slot_specs(DECL, places)
    local params = parse_params()
    local keys = {}
    for p, inf in pairs(params) do
      keys[p] = character_key(p, inf)
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

-- The names the later parts of the Draft read.
Shared.position_class = position_class
Shared.formation_lists = formation_lists
Shared.formation_places = formation_places
Shared.slot_specs = slot_specs
Shared.eligible = eligible
Shared.pool_from = pool_from
Shared.staff_from = staff_from
Shared.static_tables = static_tables
Shared.index_players = index_players
