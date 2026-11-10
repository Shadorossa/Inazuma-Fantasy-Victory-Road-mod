-- Team lineup: who of a team's players play its next match (docs/framework/team-lineup.md).

TeamLineup = TeamLineup or {}

local Rows = VRFW.table_files
local TeamConfig = VRFW.teams.config
local Id = VRFW.ids
local u32, hex = Id.unsigned, Id.hex_text
local info, _, _, debug = VRFW.logger("team_lineup")

local MEMBER_CARD = 0x20         -- the row's chara_param (u32)
local MEMBER_SLOT = 0x47         -- the row's roster slot (u8)
local MEMBER_LOADOUT = 0x28

local rd = VRFW.memory.read

local wr = VRFW.memory.write

-- CMND_VRFW_TEAM_LINEUP(team, card…): the cards take roster slots 0..
function TeamLineup.Set(team, ...)
  team = u32(team)
  local want = {}
  for _, c in ipairs({ ... }) do
    want[#want + 1] = u32(c)
  end
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return false, why end
  local rows = {}
  for k, a in ipairs(slice.rows) do
    local card, slot = rd("u32", a + MEMBER_CARD), rd("u8", a + MEMBER_SLOT)
    if card == nil or slot == nil then return false, "member row " .. k .. " unreadable" end
    if not TeamConfig.is_staff(slot) then rows[#rows + 1] = { addr = a, card = card, slot = slot } end
  end
  table.sort(rows, function(a, b) return a.slot < b.slot end)
  local order, used = {}, {}
  for _, c in ipairs(want) do
    for _, r in ipairs(rows) do
      if r.card == c and not used[r] then
        used[r] = true
        order[#order + 1] = r
        break
      end
    end
  end
  for _, r in ipairs(rows) do
    if not used[r] then order[#order + 1] = r end
  end
  local slots = {}
  for _, r in ipairs(rows) do slots[#slots + 1] = r.slot end
  local wrote = 0
  for k, r in ipairs(order) do
    if r.slot ~= slots[k] then
      if not wr("u8", r.addr + MEMBER_SLOT, slots[k]) then return false, "write failed" end
      wrote = wrote + 1
    end
  end
  debug(string.format("team 0x%08X: %d card(s) first, %d row(s) moved", team, #want, wrote))
  return true, wrote
end

function TeamLineup.Kit(team)
  local rec = TeamConfig.find(u32(team))
  if not rec then return 0 end
  local rv = VRFW.memory.read_struct("RandomTeamRecord", rec)
  local ok = rv ~= nil
  return ok and type(rv) == "table" and tonumber(rv.Uniform) or 0
end

local DATA_OFFSET = {}   -- member row address -> its offset as the data had it
function TeamLineup.Level(team, game, difficulty, level)
  team = u32(team)
  game = u32(game)
  difficulty = math.floor(tonumber(difficulty) or 0)
  local want = math.floor(tonumber(level) or 0)
  if want < 1 then return false, "no level" end
  local base = Rows.level(game, difficulty)
  if not base then return false, string.format("game 0x%08X has no difficulty %d row", game, difficulty) end
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return false, why end
  local n = 0
  for _, a in ipairs(slice.rows) do
    if DATA_OFFSET[a] == nil then
      DATA_OFFSET[a] = rd("i16", a + 0x44) or 0
    end
    local ms = VRFW.memory.struct("RandomTeamMember", a)
    local v = math.max(-998, math.min(998, DATA_OFFSET[a] + want - base))
    if pcall(function() ms.LevelOffset = v end) then n = n + 1 end
  end
  debug(string.format("team 0x%08X: level %d (game 0x%08X difficulty %d row level %d): %d row(s)", team, want, game,
    difficulty, base, n))
  return true, n
end

local LOADOUT_ROWS = 0xA8
local LOADOUT_COUNT = 0xB0       -- container: their count (i32)
local LOADOUT_STRIDE = 0x34
local ARRAY_MAX = 4096           -- VRFW.memory.read_array's largest read
local EMPTY_MOVE = 0xFB997A80
local MEMBER_RANKS = 0x4B        -- the row's 6 move grades (i8, -1 = none)
local MOVE_SLOTS = 6
local NO_GRADE = 0xFF
local INDEX = { base = nil, count = nil, rows = nil }   -- loadout id -> row index of the container's table

local function loadout_row(cont, id)
  local base, count = rd("ptr", cont + LOADOUT_ROWS), rd("i32", cont + LOADOUT_COUNT)
  if not base or base < 0x10000 or not count or count <= 0 then return nil, "loadout table unreadable" end
  if INDEX.base ~= base or INDEX.count ~= count then
    local rows = {}
    for start = 0, count - 1, ARRAY_MAX do
      local n = math.min(ARRAY_MAX, count - start)
      local ids = VRFW.memory.read_array("u32", base + start * LOADOUT_STRIDE, n, LOADOUT_STRIDE)
      local ok = ids ~= nil
      if not ok or type(ids) ~= "table" then return nil, "loadout ids unreadable" end
      for k = 1, n do rows[ids[k]] = start + k - 1 end
    end
    INDEX.base, INDEX.count, INDEX.rows = base, count, rows
  end
  local i = INDEX.rows[id]
  if not i then return nil, string.format("loadout 0x%08X not in the team table", id) end
  local v = VRFW.memory.read_array("u32", base + i * LOADOUT_STRIDE, 13)
  local ok = v ~= nil
  if not ok or type(v) ~= "table" or v[1] ~= id then return nil, "loadout row unreadable" end
  return v, base + i * LOADOUT_STRIDE
end

function TeamLineup.MemberMoves(team, slot)
  team = u32(team)
  slot = math.floor(tonumber(slot) or -1)
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return false, why end
  for _, a in ipairs(slice.rows) do
    if rd("u8", a + MEMBER_SLOT) == slot then
      local lid = rd("u32", a + MEMBER_LOADOUT) or 0
      if lid == 0 then return false, "the card's own learn list" end
      local v, why = loadout_row(slice.container, lid)
      if not v then return false, why end
      local m = {}
      for i = 2, 7 do m[#m + 1] = v[i] == EMPTY_MOVE and 0 or v[i] end
      return true, m[1], m[2], m[3], m[4], m[5], m[6], v[8], v[9], v[10], v[11], v[12], v[13]
    end
  end
  return false, "no member in slot " .. slot
end

-- member row address -> { card, loadout, ranks } as first written over; loadout id -> its row's words as first written over
local MEMBER_MOVES, LOADOUT_DATA = {}, {}

-- the member row in roster slot `slot` of the slice; nil when the team has none
local function member_at_slot(slice, slot)
  for _, a in ipairs(slice.rows) do
    if rd("u8", a + MEMBER_SLOT) == slot then return a end
  end
  return nil
end

-- the loadout row the member was given takes its data back
local function loadout_back(m)
  if m.given and LOADOUT_DATA[m.given] then
    VRFW.memory.write_array("u32", m.given_at, LOADOUT_DATA[m.given])
    LOADOUT_DATA[m.given] = nil
  end
  m.given, m.given_at = nil, nil
end

-- CMND_VRFW_TEAM_MEMBER_SET_MOVES(team, roster slot, loadout id, move1..6, level1..6): the member plays that set
-- from the loadout row `id` the mod declared for him; loadout 0 puts his own set back. Answer true | false, why.
function TeamLineup.MemberSetMoves(team, slot, id, ...)
  team, id = u32(team), u32(id)
  slot = math.floor(tonumber(slot) or -1)
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return false, why end
  local a = member_at_slot(slice, slot)
  if not a then return false, "no member in slot " .. slot end
  local card = rd("u32", a + MEMBER_CARD)
  local own = MEMBER_MOVES[a]
  if own and own.card ~= card then own = nil end
  if id == 0 then
    if own then
      wr("u32", a + MEMBER_LOADOUT, own.loadout)
      VRFW.memory.write_array("u8", a + MEMBER_RANKS, own.ranks)
      loadout_back(own)
      MEMBER_MOVES[a] = nil
    end
    return true
  end
  for _, b in ipairs(slice.rows) do
    if b ~= a and rd("u32", b + MEMBER_LOADOUT) == id then
      return false, string.format("loadout %s is the set of slot %d too", hex(id), rd("u8", b + MEMBER_SLOT))
    end
  end
  local row, at = loadout_row(slice.container, id)
  if not row then return false, at end
  if not own then
    local ranks = VRFW.memory.read_array("u8", a + MEMBER_RANKS, MOVE_SLOTS)
    if type(ranks) ~= "table" then return false, "member grades unreadable" end
    own = { card = card, loadout = rd("u32", a + MEMBER_LOADOUT) or 0, ranks = ranks }
    MEMBER_MOVES[a] = own
  end
  local want, none = { ... }, {}
  local words = {}
  for i = 1, MOVE_SLOTS do
    local move = u32(want[i] or 0)
    words[i] = move == 0 and EMPTY_MOVE or move
    words[MOVE_SLOTS + i] = math.floor(tonumber(want[MOVE_SLOTS + i]) or 0)
    none[i] = NO_GRADE
  end
  if not LOADOUT_DATA[id] then
    local data = {}
    for i = 2, #row do data[#data + 1] = row[i] end
    LOADOUT_DATA[id] = data
  end
  if own.given ~= id then loadout_back(own) end
  own.given, own.given_at = id, at + 4
  if not VRFW.memory.write_array("u32", at + 4, words) then return false, "loadout row not written" end
  if not VRFW.memory.write_array("u8", a + MEMBER_RANKS, none) then return false, "member grades not written" end
  if not wr("u32", a + MEMBER_LOADOUT, id) then return false, "member row not written" end
  debug(string.format("team %s slot %d: moves from loadout %s", hex(team), slot, hex(id)))
  return true
end

-- CMND_VRFW_MATCH_MEMBER(chara handle) -> true, team, slot of the member row a match player plays from; false, why.
local MATCH_TEAMS_KEY = "VRFW.team_lineup.match_teams"
local MATCH = { block = nil, on = false }
do
  local block = VRFW.memory.buffer("tl_match_teams", 8)
  local ok = block ~= nil
  if ok and type(block) == "number" and pcall(VRFW.state.set, MATCH_TEAMS_KEY, block) then
    MATCH.block = block
    wr("u64", block, 0)
  else
    VRFW.warn("team_lineup: the match teams block is not set up: a match player's page shows his card's set")
  end
end
VRFW.on("match_start", function() MATCH.on = true return nil end)
VRFW.on("match_end", function() MATCH.on = false return nil end)
VRFW.on("game_reset", function() MATCH.on = false return nil end)

-- the roster slot of card `card` in team `team` (staff slots left out); nil when he is not a member
local function member_slot(team, card)
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return nil end
  for _, a in ipairs(slice.rows) do
    local slot = rd("u8", a + MEMBER_SLOT)
    if slot and not TeamConfig.is_staff(slot) and rd("u32", a + MEMBER_CARD) == card then return slot end
  end
  return nil
end

function TeamLineup.MatchMember(hdl)
  hdl = u32(hdl)
  if not MATCH.on or not MATCH.block then return false, "no match" end
  if hdl == 0 then return false, "no character" end
  local okw, own = pcall(VRFW.character.user_owned, hdl)
  if okw and own ~= nil then return false, "the user's own player" end
  local okr, r = pcall(VRFW.character.record, hdl)
  local card = okr and type(r) == "table" and tonumber(r.param) or nil
  if not card or card == 0 then return false, "not a character" end
  card = u32(card)
  for _, at in ipairs({ 0, 4 }) do
    local team = rd("u32", MATCH.block + at)
    if team and team ~= 0 then
      local slot = member_slot(team, card)
      if slot then return true, team, slot end
    end
  end
  return false, string.format("card 0x%08X is in neither team of the match", card)
end

-- member row address -> { team, card, uid, skill } as the data had it (kept from the first write until restored)
local ROSTER_DATA = {}

-- the team's player rows (staff slots left out) by roster slot: { [slot] = row address }; nil, why
local function player_rows(team)
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return nil, why end
  local rows = {}
  for k, a in ipairs(slice.rows) do
    local slot = rd("u8", a + MEMBER_SLOT)
    if slot == nil then return nil, "member row " .. k .. " unreadable" end
    if not TeamConfig.is_staff(slot) then rows[slot] = a end
  end
  return rows
end

-- one member row plays `card` (its card, uid and loadout 0: the card's own learn list)
local function write_member(a, card, uid, skill)
  local ms = VRFW.memory.struct("RandomTeamMember", a)
  local ok = pcall(function()
    ms.Param = card
    ms.Uid = uid
    ms.Skill = skill
  end)
  return ok and rd("u32", a + MEMBER_CARD) == card
end

function TeamLineup.Roster(team, ...)
  team = u32(team)
  local args = { ... }
  local rows, why = player_rows(team)
  if not rows then return false, why end
  local wrote, skipped = 0, 0
  for i = 1, #args - 1, 2 do
    local slot = math.floor(tonumber(args[i]) or -1)
    local card = u32(args[i + 1])
    local a = rows[slot]
    if a == nil or card == 0 then
      skipped = skipped + 1
    else
      if ROSTER_DATA[a] == nil then
        local m = VRFW.memory.read_struct("RandomTeamMember", a)
        local okm = m ~= nil
        if not okm or type(m) ~= "table" or m.Param == nil or m.Uid == nil or m.Skill == nil then
          return false, "member row of slot " .. slot .. " unreadable"
        end
        ROSTER_DATA[a] = { team = team, card = m.Param, uid = m.Uid, skill = m.Skill }
      end
      if rd("u32", a + MEMBER_CARD) ~= card then
        if not write_member(a, card, card, 0) then return false, "write failed (slot " .. slot .. ")" end
        wrote = wrote + 1
      end
    end
  end
  debug(string.format("team 0x%08X: roster of %d slot(s), %d row(s) written, %d skipped", team, math.floor(#args / 2),
    wrote, skipped))
  return true, wrote
end

function TeamLineup.RosterRestore(team)
  team = u32(team)
  local n = 0
  for a, d in pairs(ROSTER_DATA) do
    if team == 0 or d.team == team then
      if d.card and d.uid and d.skill and write_member(a, d.card, d.uid, d.skill) then n = n + 1 end
      ROSTER_DATA[a] = nil
    end
  end
  info(string.format("roster restore %s: %d row(s)", team == 0 and "every team" or string.format("team 0x%08X", team), n))
  return true, n
end

local RECORD_STRIDE = 0x50              -- team_config record array stride
local REC_FIRST, REC_COUNT = 0x28, 0x2C -- the record's member slice
local LOOK_FIELDS = { "Level", "NameText", "Formation", "Uniform", "Emblem" }
local STAND_IN = {}

-- the team's record, container and member slice: { rec, cont, base, first, count, rows = { { addr, slot, card, words } } }
local function read_slice(team)
  local slice, why = VRFW.catalogue.member_rows(team)
  if not slice then return nil, why end
  local cv = VRFW.memory.read_struct("RandomTeamConfig", slice.container)
  local okc = cv ~= nil
  if not okc or type(cv) ~= "table" then return nil, "member slice unreadable" end
  local row_words = math.floor(slice.row_size / 4)
  local rows = {}
  for k, a in ipairs(slice.rows) do
    local words = VRFW.memory.read_array("u32", a, row_words)
    local okw = words ~= nil
    local slot = rd("u8", a + MEMBER_SLOT)
    if not okw or type(words) ~= "table" or #words ~= row_words or slot == nil then
      return nil, "member row " .. k .. " unreadable"
    end
    rows[#rows + 1] = { addr = a, slot = slot, words = words, card = words[math.floor(MEMBER_CARD / 4) + 1] }
  end
  return { rec = slice.record, cont = cv, base = slice.base, first = slice.first, count = slice.count, row_size = slice.row_size, rows = rows }
end

-- true when no other team_config record uses rows of this slice (a stand-in write must touch one team only)
local function own_rows(team, sl)
  local recs, nrec = sl.cont.Records, sl.cont.RecordCount
  if not recs or recs < 0x10000 or not nrec or nrec <= 0 then return false, "record table unreadable" end
  local done = 0
  while done < nrec do
    local take = math.min(4096, nrec - done)
    local at = recs + done * RECORD_STRIDE
    local ids = VRFW.memory.read_array("u32", at, take, RECORD_STRIDE)
    local ok1 = ids ~= nil
    local fs = VRFW.memory.read_array("u32", at + REC_FIRST, take, RECORD_STRIDE)
    local ok2 = fs ~= nil
    local cs = VRFW.memory.read_array("u32", at + REC_COUNT, take, RECORD_STRIDE)
    local ok3 = cs ~= nil
    if not (ok1 and ok2 and ok3) or type(ids) ~= "table" or type(fs) ~= "table" or type(cs) ~= "table" then
      return false, "record table unreadable"
    end
    for k = 1, take do
      if recs + (done + k - 1) * RECORD_STRIDE ~= sl.rec and ids[k] ~= team then
        local f2, c2 = fs[k] % 65536, cs[k]
        if c2 > 0 and f2 < sl.first + sl.count and sl.first < f2 + c2 then
          return false, "member rows shared with team " .. hex(ids[k])
        end
      end
    end
    done = done + take
  end
  return true
end

local function stand_in_data(team)
  local s = STAND_IN[team]
  local sl, why = read_slice(team)
  if not sl then return nil, why end
  if s and s.rec == sl.rec and s.first == sl.first then return s end
  local ok, why2 = own_rows(team, sl)
  if not ok then return nil, why2 end
  local r = VRFW.memory.struct("RandomTeamRecord", sl.rec)
  local look = {}
  for _, f in ipairs(LOOK_FIELDS) do look[f] = r[f] end
  local players, staff = {}, {}
  for _, x in ipairs(sl.rows) do
    if TeamConfig.is_staff(x.slot) then staff[#staff + 1] = x else players[#players + 1] = x end
  end
  table.sort(players, function(a, b) return a.slot < b.slot end)
  s = { rec = sl.rec, base = sl.base, first = sl.first, count = sl.count, row_size = sl.row_size, rows = sl.rows, players = players,
    staff = staff, look = look }
  STAND_IN[team] = s
  return s
end

local function put_row(a, words)
  return (VRFW.memory.write_array("u32", a, words))
end

function TeamLineup.StandIn(team, source, ...)
  team = u32(team)
  source = u32(source)
  local s, why = stand_in_data(team)
  if not s then return false, "slot team " .. hex(team) .. ": " .. tostring(why) end
  local src, why2 = read_slice(source)
  if not src then return false, "source team " .. hex(source) .. ": " .. tostring(why2) end
  local cards = {}
  for _, c in ipairs({ ... }) do
    c = u32(c)
    if c ~= 0 and #cards < #s.players then cards[#cards + 1] = c end
  end
  if #cards == 0 then return false, "no card" end
  local listed, by_card, by_slot = {}, {}, {}
  for _, c in ipairs(cards) do listed[c] = true end
  for _, x in ipairs(src.rows) do
    if not TeamConfig.is_staff(x.slot) then
      if by_card[x.card] == nil then by_card[x.card] = x end
      by_slot[x.slot] = x
    end
  end
  local copied, other = 0, 0
  for k, c in ipairs(cards) do
    local slot = k - 1
    local own = by_card[c]
    local vacated = by_slot[slot]
    if vacated and listed[vacated.card] then vacated = nil end
    local tpl = own or vacated or s.players[k]
    local words = {}
    for i = 1, #tpl.words do words[i] = tpl.words[i] end
    local a = s.base + (s.first + slot) * s.row_size
    if not put_row(a, words) or not wr("u8", a + MEMBER_SLOT, slot) then
      return false, "write failed (slot " .. slot .. ")"
    end
    if own then
      copied = copied + 1
    else
      local ms = VRFW.memory.struct("RandomTeamMember", a)
      local ok = pcall(function()
        ms.Param = c
        ms.Uid = c
        ms.Skill = 0
        ms.LevelOffset = 0
      end)
      if not ok or rd("u32", a + MEMBER_CARD) ~= c then return false, "write failed (slot " .. slot .. ")" end
      other = other + 1
    end
  end
  for i, x in ipairs(s.staff) do
    if not put_row(s.base + (s.first + #cards + i - 1) * s.row_size, x.words) then
      return false, "staff row write failed"
    end
  end
  if not wr("u32", s.rec + REC_COUNT, #cards + #s.staff) then return false, "slice count write failed" end
  s.placed = #cards
  local r = VRFW.memory.struct("RandomTeamRecord", s.rec)
  local sr = VRFW.memory.struct("RandomTeamRecord", src.rec)
  local okl = pcall(function()
    for _, f in ipairs(LOOK_FIELDS) do r[f] = sr[f] end
  end)
  if not okl then VRFW.warn("team_lineup: team " .. hex(team) .. ": record look not written") end
  debug(string.format("team %s stands in for %s: %d player(s) (%d copied rows, %d other cards), %d staff row(s)",
    hex(team), hex(source), #cards, copied, other, #s.staff))
  return true, #cards
end

function TeamLineup.StandInFormation(team, formation)
  team = u32(team)
  formation = u32(formation)
  local s = STAND_IN[team]
  if not s then return false, "slot team " .. hex(team) .. " stands in for no team" end
  if formation == 0 then return false, "no formation" end
  local r = VRFW.memory.struct("RandomTeamRecord", s.rec)
  if not pcall(function() r.Formation = formation end) then return false, "formation write failed" end
  debug(string.format("team %s plays formation %s", hex(team), hex(formation)))
  return true
end

function TeamLineup.StandInLook(team, kit, emblem, coach)
  team = u32(team)
  local s = STAND_IN[team]
  if not s or not s.placed then return false, "slot team " .. hex(team) .. " stands in for no team" end
  kit = u32(kit)
  emblem = u32(emblem)
  coach = u32(coach)
  local r = VRFW.memory.struct("RandomTeamRecord", s.rec)
  if kit ~= 0 and not pcall(function() r.Uniform = kit end) then return false, "kit write failed" end
  if emblem ~= 0 and not pcall(function() r.Emblem = emblem end) then return false, "emblem write failed" end
  local coached = false
  if coach ~= 0 then
    for i, x in ipairs(s.staff) do
      if x.slot == TeamConfig.COACH_SLOT and not coached then
        local a = s.base + (s.first + s.placed + i - 1) * s.row_size
        local ms = VRFW.memory.struct("RandomTeamMember", a)
        local ok = pcall(function()
          ms.Param = coach
          ms.Uid = coach
          ms.Skill = 0
        end)
        if not ok or rd("u32", a + MEMBER_CARD) ~= coach then return false, "coach write failed" end
        coached = true
      end
    end
    if not coached then return false, "slot team " .. hex(team) .. " has no coach row" end
  end
  debug(string.format("team %s look: kit %s, emblem %s, coach %s", hex(team), hex(kit), hex(emblem), hex(coach)))
  return true
end

-- the team looks written by CMND_VRFW_TEAM_LOOK_SET: team id -> { NameText, Uniform, Emblem } as the data has them
local OWN_LOOK = {}
local OWN_LOOK_FIELDS = { "NameText", "Uniform", "Emblem" }

function TeamLineup.Look(team)
  team = u32(team)
  local sl, why = read_slice(team)
  if not sl then return false, "team " .. hex(team) .. ": " .. tostring(why) end
  local rv = VRFW.memory.read_struct("RandomTeamRecord", sl.rec)
  local ok = rv ~= nil
  if not ok or type(rv) ~= "table" then return false, "team " .. hex(team) .. ": record unreadable" end
  local coach = 0
  for _, x in ipairs(sl.rows) do
    if x.slot == TeamConfig.COACH_SLOT and coach == 0 then coach = x.card or 0 end
  end
  local own = OWN_LOOK[team] or rv
  return true, math.floor(tonumber(rv.Level) or 0), u32(rv.Formation),
    u32(rv.Uniform), u32(rv.Emblem), coach,
    u32(own.Uniform), u32(own.Emblem),
    u32(own.NameText)
end

function TeamLineup.LookSet(team, name, kit, emblem)
  team = u32(team)
  local want = { NameText = u32(name),
    Uniform = u32(kit), Emblem = u32(emblem) }
  local function put(id, values)
    local rec, why = TeamConfig.find(id)
    if not rec then return false, why end
    local r = VRFW.memory.struct("RandomTeamRecord", rec)
    local ok = pcall(function()
      for _, f in ipairs(OWN_LOOK_FIELDS) do r[f] = values[f] end
    end)
    return ok, ok and nil or "record write failed"
  end
  if team == 0 then
    local n = 0
    for id, own in pairs(OWN_LOOK) do
      if put(id, own) then n = n + 1 end
      OWN_LOOK[id] = nil
    end
    if n > 0 then info(string.format("team looks restored: %d team(s)", n)) end
    return true, n
  end
  local own = OWN_LOOK[team]
  if own == nil then
    local rec, why = TeamConfig.find(team)
    if not rec then return false, "team " .. hex(team) .. ": " .. tostring(why) end
    local rv = VRFW.memory.read_struct("RandomTeamRecord", rec)
    local ok = rv ~= nil
    if not ok or type(rv) ~= "table" then return false, "team " .. hex(team) .. ": record unreadable" end
    own = {}
    for _, f in ipairs(OWN_LOOK_FIELDS) do own[f] = u32(rv[f]) end
  end
  local values, changed = {}, false
  for _, f in ipairs(OWN_LOOK_FIELDS) do
    values[f] = want[f] ~= 0 and want[f] or own[f]
    if want[f] ~= 0 then changed = true end
  end
  local ok, why = put(team, values)
  if not ok then return false, "team " .. hex(team) .. ": " .. tostring(why) end
  OWN_LOOK[team] = changed and own or nil
  debug(string.format("team %s look: name %s, kit %s, emblem %s", hex(team), hex(values.NameText), hex(values.Uniform),
    hex(values.Emblem)))
  return true, 1
end

-- CMND_VRFW_TEAM_MEMBER_LEVELS(team, base, level…): the member rows in roster slots 0..
local MEMBER_LEVEL = {}   -- member row address -> { card, offset } as first written over

function TeamLineup.MemberLevels(team, base, ...)
  team = u32(team)
  base = math.floor(tonumber(base) or 0)
  local sl, why = read_slice(team)
  if not sl then return false, "team " .. hex(team) .. ": " .. tostring(why) end
  local rv = VRFW.memory.read_struct("RandomTeamRecord", sl.rec)
  local ok = rv ~= nil
  local record = ok and type(rv) == "table" and math.floor(tonumber(rv.Level) or 0) or 0
  if base <= 0 then base = record end
  if base <= 0 then return false, "team " .. hex(team) .. ": no level to count from" end
  local by_slot = {}
  for _, x in ipairs(sl.rows) do
    if not TeamConfig.is_staff(x.slot) and by_slot[x.slot] == nil then by_slot[x.slot] = x end
  end
  local levels = { ... }
  local function own(x)
    local m = MEMBER_LEVEL[x.addr]
    if m == nil or m.card ~= x.card then
      m = { card = x.card, offset = rd("i16", x.addr + 0x44) or 0 }
      MEMBER_LEVEL[x.addr] = m
    end
    return m
  end
  local n, lo, hi = 0, nil, nil
  local function put(x, v)
    local ms = VRFW.memory.struct("RandomTeamMember", x.addr)
    if pcall(function() ms.LevelOffset = math.max(-998, math.min(998, v)) end) then n = n + 1 end
  end
  if #levels == 0 then
    for _, x in pairs(by_slot) do
      local m = MEMBER_LEVEL[x.addr]
      if m and m.card == x.card then put(x, m.offset) end
    end
    debug(string.format("team %s: member levels back: %d row(s)", hex(team), n))
    return true, n
  end
  for k, v in ipairs(levels) do
    local x = by_slot[k - 1]
    v = math.floor(tonumber(v) or 0)
    if x then
      local m = own(x)
      if v > 0 then
        put(x, v - base)
        lo, hi = lo and math.min(lo, v) or v, hi and math.max(hi, v) or v
      else
        put(x, m.offset)
      end
    end
  end
  debug(string.format("team %s: member levels %s..%s from base %d (record level %d): %d row(s)", hex(team),
    tostring(lo or "-"), tostring(hi or "-"), base, record, n))
  return true, n
end

-- CMND_VRFW_TEAM_STAND_IN_RESTORE(slot team, 0 = every one): the slot team's rows, slice and record back
function TeamLineup.StandInRestore(team)
  team = u32(team)
  local n = 0
  for id, s in pairs(STAND_IN) do
    if team == 0 or id == team then
      for _, x in ipairs(s.rows) do
        put_row(x.addr, x.words)
        if MEMBER_MOVES[x.addr] then
          loadout_back(MEMBER_MOVES[x.addr])
          MEMBER_MOVES[x.addr] = nil
        end
      end
      wr("u32", s.rec + REC_COUNT, s.count)
      local r = VRFW.memory.struct("RandomTeamRecord", s.rec)
      pcall(function()
        for _, f in ipairs(LOOK_FIELDS) do r[f] = s.look[f] end
      end)
      STAND_IN[id] = nil
      n = n + 1
    end
  end
  info(string.format("stand-in restore %s: %d team(s)", team == 0 and "every team" or hex(team), n))
  return true, n
end
