
ChronicleDeluxe = type(ChronicleDeluxe) == "table" and ChronicleDeluxe or {}
ChronicleDeluxe.FreeMatchShuffle = ChronicleDeluxe.FreeMatchShuffle or {}
local FmShuffle = ChronicleDeluxe.FreeMatchShuffle

local POS_GK, POS_FW, POS_MF, POS_DF = 1, 2, 3, 4
local Id = VRFW.ids
local Catalogue = VRFW.catalogue
local TeamConfig = VRFW.teams.config
local u32, hex = Id.unsigned, Id.hex_text

local function row_words() return math.floor(VRFW.game.field("MemberRow") / 4) end
local SLOT_AT = 0x47
local RATES = 8           -- stat rates at +0x00 (8 floats)
local STARTER_SLOTS = 11
local PREFIX = "chronicle_deluxe_fms_"
local SOURCES = { [POS_GK] = "_as_gk", [POS_FW] = "_as_fw", [POS_MF] = "_as_mf", [POS_DF] = "_as_df" }
local POS_NAME = { [POS_GK] = "GK", [POS_FW] = "FW", [POS_MF] = "MF", [POS_DF] = "DF" }
local STARTS = 8          -- random starting deals; the best one after the swaps is kept

local TEAMS = nil         -- shuffled teams: { { id, key, formation } }
local DIRTY = true
local DEALS = 0
local TRIES, MAX_TRIES = 0, 3
local WARNED = {}

local info, warn = VRFW.logger("ChronicleDeluxe free_match_shuffle")

local Memory = VRFW.memory
local read_memory, write_memory = Memory.read, Memory.write

local TEAMS_UNREADABLE_WARNED = false
local function teams()
  if TEAMS then return TEAMS end
  local rows, why = Catalogue.pool({ key_prefix = PREFIX })
  if not rows then
    if not TEAMS_UNREADABLE_WARNED then
      TEAMS_UNREADABLE_WARNED = true
      warn("team_config not readable (" .. tostring(why) .. "): no team is shuffled")
    end
    return {}
  end
  TEAMS = {}
  for _, r in ipairs(rows) do
    local key = r.key or r[2]
    local id = r.id or r[1]
    if type(key) == "string" and type(id) == "number" and not key:find("_as_%a%a$") then
      TEAMS[#TEAMS + 1] = { id = u32(id), key = key, formation = u32(r.formation or r[5]) }
    end
  end
  if #TEAMS > 0 then
    local names = {}
    for _, t in ipairs(TEAMS) do names[#names + 1] = t.key end
    info(#TEAMS .. " shuffled team(s): " .. table.concat(names, ", "))
  end
  return TEAMS
end

local function rows_of(id)
  local slice, why = VRFW.catalogue.member_rows(id)
  if not slice then return nil, why end
  local by_slot, starters = {}, 0
  for k, a in ipairs(slice.rows) do
    local m = VRFW.memory.read_struct("MemberRow", a)
    local okm = m ~= nil
    if not okm or type(m) ~= "table" or m.Slot == nil then return nil, "member row " .. k .. " unreadable" end
    if by_slot[m.Slot] then return nil, "roster slot " .. m.Slot .. " twice" end
    by_slot[m.Slot] = a
    if m.Slot < STARTER_SLOTS then starters = starters + 1 end
  end
  for s = 0, starters - 1 do
    if not by_slot[s] then return nil, "starter slots are not 0.." .. (starters - 1) end
  end
  return by_slot, starters
end

local function rate_at(a, k)
  local v = read_memory("f32", a + 4 * k)
  if v and v == v and v > 1e-6 and v < 1e6 then return v end
  local u = read_memory("u32", a + 4 * k)
  if u and u >= 1 and u <= 1000 then return u end
  return nil
end

local function read_row(a)
  local w = VRFW.memory.read_array("u32", a, row_words(), 4)
  local ok = w ~= nil
  if ok and type(w) == "table" and #w == row_words() then return w end
  return nil
end

local function score(deal, own, cls, n)
  local s = 0
  for i = 0, n - 1 do
    local j = deal[i]
    if j ~= i then s = s + 1000 end
    if cls[j] ~= own[i] then s = s + 10 end
  end
  return s
end

local function draw(rng, own, cls, n)
  local best, best_s
  for _ = 1, STARTS do
    local p = {}
    for k = 1, n do p[k] = k - 1 end
    rng:shuffle(p)
    local deal = {}
    for i = 0, n - 1 do deal[i] = p[i + 1] end
    local s = score(deal, own, cls, n)
    local better = true
    while better do
      better = false
      for a = 0, n - 2 do
        for b = a + 1, n - 1 do
          deal[a], deal[b] = deal[b], deal[a]
          local t = score(deal, own, cls, n)
          if t > s then
            s, better = t, true
          else
            deal[a], deal[b] = deal[b], deal[a]
          end
        end
      end
    end
    if not best_s or s > best_s then
      best, best_s = {}, s
      for i = 0, n - 1 do best[i] = deal[i] end
    end
  end
  return best
end

local function deal_team(t)
  local rows, starters = rows_of(t.id)
  if not rows then return nil, starters end
  local form = VRFW.formation.classes(t.formation)
  if not form then return nil, "formation " .. hex(t.formation) .. " not in formation_config" end
  local srcs = {}
  for cls, suffix in pairs(SOURCES) do
    local src, why = rows_of(VRFW.crc32(t.key .. suffix))
    if not src then return nil, "source team " .. t.key .. suffix .. ": " .. tostring(why) end
    srcs[cls] = src
  end
  local own, cls, src_rows = {}, {}, {}
  for s = 0, starters - 1 do
    cls[s] = form[s] or POS_MF
    local card = u32(read_memory("u32", srcs[POS_GK][s] + 0x20))
    local c = card ~= 0 and VRFW.character.card(card) or nil
    own[s] = (c and c.position and c.position >= 1 and c.position <= 4) and c.position or cls[s]
  end
  local rng = VRFW.random("ChronicleDeluxe.free_match_shuffle", { t.id, DEALS, VRFW.random.int(0, 2147483646) })
  local deal = draw(rng, own, cls, starters)
  for i = 0, starters - 1 do
    local w = read_row(srcs[cls[deal[i]]][i])
    if not w then return nil, "source row of slot " .. i .. " unreadable" end
    src_rows[i] = w
  end
  local rates = {}
  for i = 0, starters - 1 do
    local j = deal[i]
    local src, mine, place = srcs[cls[j]][i], srcs[own[i]][i], srcs[own[j]][j]
    local r = {}
    for k = 0, RATES - 1 do
      local sv, mv, pv = rate_at(src, k), rate_at(mine, k), rate_at(place, k)
      if sv and mv and pv and mv > 0 then r[k] = { from = sv, to = pv * sv / mv } end
    end
    rates[i] = r
  end
  local parts, moved = {}, 0
  for i = 0, starters - 1 do
    local j = deal[i]
    local a = rows[j]
    for k = 1, row_words() do
      if not write_memory("u32", a + 4 * (k - 1), src_rows[i][k]) then return nil, "write of place " .. j .. " failed (the team may be half written)" end
    end
    for k, x in pairs(rates[i]) do
      if math.abs(x.to - x.from) > 1e-6 and not write_memory("f32", a + 4 * k, x.to) then
        return nil, "rate write of place " .. j .. " failed (the team may be half written)"
      end
    end
    if not write_memory("u8", a + SLOT_AT, j) then return nil, "slot write of place " .. j .. " failed" end
    if cls[j] ~= own[i] then moved = moved + 1 end
    parts[j + 1] = string.format("%d<-%d:%s %s->%s", j, i, hex(src_rows[i][9]), POS_NAME[own[i]] or "?", POS_NAME[cls[j]] or "?")
  end
  return true, string.format("%d starter(s) moved, %d of them to another position: [%s]", starters, moved, table.concat(parts, " "))
end

function FmShuffle.Deal()
  if not DIRTY then return 0 end
  local n, failed = 0, false
  for _, t in ipairs(teams()) do
    local ok, res, text = pcall(deal_team, t)
    if ok and res then
      n = n + 1
      DEALS = DEALS + 1
      WARNED[t.key] = nil
      info(t.key .. " dealt: " .. text)
    else
      failed = true
      local why = tostring(ok and text or res)
      if WARNED[t.key] ~= why then
        WARNED[t.key] = why
        warn(t.key .. ": not dealt: " .. why)
      end
    end
  end
  -- a failed deal is tried again at the next call, at most TRIES times until the next match
  TRIES = failed and TRIES + 1 or 0
  DIRTY = failed and TRIES < MAX_TRIES
  return n
end

VRFW.on("slot_load", function()
  for _, t in ipairs(teams()) do
    VRFW.formation.classes(t.formation)
  end
  return nil
end)

VRFW.on("match_end", function()
  DIRTY, TRIES = true, 0
  return nil
end)

VRFW.on("game_reset", function()
  DIRTY, TRIES = true, 0
  return nil
end)
