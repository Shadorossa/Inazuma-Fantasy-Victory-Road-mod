-- The Draft screen's commands: the filters, begin, places, candidates, picks, formations and abandon.
local Shared = require "lib/draft/context"
local U = require "lib/util"
local POS_GK = Shared.POS_GK
local STARTERS = Shared.STARTERS
local PICKING = Shared.PICKING
local COMPLETE = Shared.COMPLETE
local PHASE_NAME = Shared.PHASE_NAME
local FILTER_ROWS = Shared.FILTER_ROWS
local FILTERS = Shared.FILTERS
local info = Shared.info
local warn = Shared.warn
local err = Shared.err
local CFG = Shared.CFG
local position_class = Shared.position_class
local formation_lists = Shared.formation_lists
local formation_places = Shared.formation_places
local index_players = Shared.index_players
local new_draft = Shared.new_draft
local draft_slots = Shared.draft_slots
local draft_formation = Shared.draft_formation
local filled = Shared.filled
local done = Shared.done
local candidates = Shared.candidates
local draft_pick = Shared.draft_pick
local draft_roster = Shared.draft_roster
local set_phase = Shared.set_phase
local with = Shared.with
local apply = Shared.apply
local restore = Shared.restore
local session_slots = Shared.session_slots
local sync_leader = Shared.sync_leader
local open_pool = Shared.open_pool
local filters_load = Shared.filters_load
local filters_save = Shared.filters_save
local filter_step = Shared.filter_step
local filtered_players = Shared.filtered_players
local slots_feasible = Shared.slots_feasible
local formation_slots = Shared.formation_slots
local pool_fillable = Shared.pool_fillable

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
    local n = Shared.BEGUN
    Shared.BEGUN = Shared.BEGUN + 1
    local h, l
    if CFG.seed ~= 0 then
      h, l = U.split64(CFG.seed)
      l = bit32.bxor(l, 0xD4AF7000, n % U.TWO32)
    else
      h, l = U.entropy(VRFW.game.global("enjoy") or 0, n)
    end
    local ok, why = restore(r)
    if ok then
      r.draft = new_draft(U.rng(h, l), #r.pool.slots)
      if start_formation then
        draft_formation(r.draft, r.pool, start_formation)
      end
      set_phase(r, PICKING)
      total = #r.pool.slots
      info(string.format("begin (seed %s:%s, %d picks, %d players)", VRFW.ids.hex_text(h), VRFW.ids.hex_text(l), total, #r.pool.players))
    else
      err("cannot begin, roster rows of " .. VRFW.ids.hex_text(r.pool.team) .. ": " .. tostring(why))
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
  local id = VRFW.ids.unsigned(formation)
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
      info(string.format("pick %d/%d: slot %d = %s", got.filled, #r.pool.slots, got.slot, VRFW.ids.hex_text(got.id)))
      if got.done then
        info(string.format("complete (%d players on the rows of %s)", #r.pool.slots, VRFW.ids.hex_text(r.pool.team)))
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
      local spot = VRFW.value.round(at[1] * SPOT_PRECISION) .. ":" .. VRFW.value.round(at[2] * SPOT_PRECISION)
      if seen[spot] then
        return true
      end
      seen[spot] = true
    end
  end
  return false
end

Shared.formation_list = function()
  if FORMATION_LIST then
    return FORMATION_LIST
  end
  -- The list is kept between starts, so a warm start never reads the formation tables for it.
  FORMATION_LIST = VRFW.derived("draft_formation_list_1", nil, function()
    local forms, places = formation_lists()
    local out, names = {}, {}
    for _, row in ipairs(forms) do
      local s = row.placementInfo
      local id = type(row.formId) == "number" and VRFW.ids.unsigned(row.formId) or 0
      local noun = type(row.nounId) == "number" and VRFW.ids.unsigned(row.nounId) or 0
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
    return out
  end)
  info(string.format("%d formations to choose from", #FORMATION_LIST))
  return FORMATION_LIST
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
  local ok, list = pcall(Shared.formation_list)
  if not r or not ok then
    if not ok then
      warn("formation list: " .. tostring(list))
    end
    return false
  end
  local current = (r.draft and r.draft.formation) or r.pool.formation
  if not (r.draft and r.draft.fm_offer) and r.pool.players ~= (r.src.base or r.src.all) then
    -- a filtered pool offers the formations it can fill (once: the draft keeps its offer)
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
  local id = VRFW.ids.unsigned(formation)
  local r = with()
  if not r or (r.phase ~= PICKING and r.phase ~= COMPLETE) or not r.draft or id == 0 then
    return false
  end
  if r.pool.players ~= (r.src.base or r.src.all) then
    -- a filtered pool must still fill the open places in the new formation
    local slots = (id == r.pool.formation) and r.pool.slots or formation_slots(id)
    if not slots or not slots_feasible(slots, r.pool.players, r.draft.picks) then
      info("formation " .. VRFW.ids.hex_text(id) .. " not set: the filtered pool cannot fill it")
      return false
    end
  end
  local ok, why = draft_formation(r.draft, r.pool, id)
  if ok then
    ok, why = apply(r, draft_roster(r.draft, r.pool))
  end
  if not ok then
    warn("formation " .. VRFW.ids.hex_text(id) .. " not set: " .. tostring(why))
    return false
  end
  info("formation " .. VRFW.ids.hex_text(id))
  return true
end

function BattleBayDeluxe.DraftAbandon()
  local r = Shared.RT
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
