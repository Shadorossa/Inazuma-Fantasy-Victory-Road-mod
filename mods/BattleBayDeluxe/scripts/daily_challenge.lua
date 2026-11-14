
local U = require "lib/util"
local Block = require "lib/campaign_block"
local G = require "lib/game"
local Trophy = require "lib/trophy_celebration"
local Catalogue = VRFW.catalogue
local Daily = VRFW.daily

local D = {}

local BLOB = "bb_daily_challenge.json"
local CAMP_BLOB = "bb_daily_campaign.json"
local DOC_VERSION = 1

local info, warn = VRFW.logger("daily challenge")

local function cfg(key, default)
  return U.config("daily_challenge." .. key, default)
end

local function cfg_int(key, default, lo, hi)
  local v = U.int(tonumber(cfg(key, default)), default)
  if v < lo or v > hi then
    warn(string.format("config [daily_challenge] %s = %d out of %d..%d: %d used", key, v, lo, hi, default))
    return default
  end
  return v
end

local function cfg_list(key)
  local v = cfg(key, {})
  return type(v) == "table" and v or {}
end

local function settings()
  local pool_cfg = cfg("pool", {})
  pool_cfg = type(pool_cfg) == "table" and pool_cfg or {}
  local s = {
    salt = tostring(cfg("salt", "BattleBayDeluxe.DailyChallenge")),
    version = cfg_int("version", 1, 1, 1000000),
    -- 1-3 matches (config.toml [daily_challenge] matches)
    matches = cfg_int("matches", 3, 1, 3),
    keep_days = cfg_int("keep_days", 60, 1, 3650),
    level = U.int(tonumber(pool_cfg.level), 40),
    keys = type(pool_cfg.team_keys) == "table" and pool_cfg.team_keys or {},
    difficulty = {},
  }
  local d = cfg_list("difficulty")
  for i = 1, s.matches do
    local v = U.int(d[i] or d[#d], 2)
    if v < 1 or v > 4 then
      v = 2
    end
    s.difficulty[i] = v
  end
  return s
end

-- a glob of a team key (`*` any run of characters, `?` one character) as a Lua pattern
local function glob_pattern(g)
  local p = tostring(g):gsub("[%^%$%(%)%%%.%[%]%+%-]", "%%%0"):gsub("%*", ".*"):gsub("%?", ".")
  return "^" .. p .. "$"
end

local function key_matches(key, patterns)
  if #patterns == 0 then
    return true
  end
  for _, p in ipairs(patterns) do
    if key:match(p) then
      return true
    end
  end
  return false
end

local function pool(s)
  local rows = Catalogue.pool({ level = s.level })
  if not rows then
    return nil, "team table not readable"
  end
  local enjoy, why = G.enjoy_rows()
  if not enjoy then
    return nil, why
  end
  local listed = {}
  for _, r in ipairs(enjoy) do
    listed[VRFW.ids.unsigned(r.team)] = true
  end
  local patterns = {}
  for _, k in ipairs(s.keys) do
    patterns[#patterns + 1] = glob_pattern(k)
  end
  local out = {}
  for _, r in ipairs(rows) do
    local id = VRFW.ids.unsigned(r.id or r[1] or 0)
    local key = tostring(r.key or r[2] or "")
    if id ~= 0 and key ~= "" and listed[id] and key_matches(key, patterns) then
      out[#out + 1] = { team = id, key = key, name = VRFW.ids.unsigned(r.name_text or r[4] or 0) }
    end
  end
  table.sort(out, function(a, b)
    if a.key ~= b.key then
      return a.key < b.key
    end
    return a.team < b.team
  end)
  local seen, uniq = {}, {}
  for _, c in ipairs(out) do
    local name = c.name ~= 0 and c.name or c.team
    if not seen[name] then
      seen[name] = true
      uniq[#uniq + 1] = c
    end
  end
  return uniq
end

local PLANS = {}
function D.plan(date)
  date = U.int(date, 0)
  if date < 19700101 or date > 99991231 then
    return nil, "date"
  end
  if PLANS[date] then
    return PLANS[date]
  end
  local s = settings()
  local cands, why = pool(s)
  if not cands then
    return nil, why
  end
  if #cands < s.matches + 1 then
    return nil, string.format("pool of %d team(s), %d needed", #cands, s.matches + 1)
  end
  local picks = Daily.pick({ salt = s.salt, version = s.version, pool = cands, picks = s.matches + 1 }, date)
  local p = { date = date, team = picks[1].team, rivals = {}, difficulty = s.difficulty, matches = s.matches }
  local names = { picks[1].key }
  for i = 2, #picks do
    p.rivals[#p.rivals + 1] = picks[i].team
    names[#names + 1] = picks[i].key
  end
  PLANS[date] = p
  info(string.format("%d: pool %d teams (level %d), salt %q version %d: team %s, rivals %s", date, #cands, s.level,
    s.salt, s.version, names[1], table.concat(names, ", ", 2)))
  return p
end

local STORE = VRFW.save.doc.new(BLOB, {
  aside = false,
  log = "daily challenge",
  default = function() return { v = DOC_VERSION, days = {} } end,
  decode = function(doc)
    if doc.v ~= DOC_VERSION then return nil, "unreadable: a new record" end
    doc.days = type(doc.days) == "table" and doc.days or {}
    return doc
  end,
})

local function load()
  return (STORE:get())
end

local function prune(doc, keep)
  local keys = {}
  for k in pairs(doc.days) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  for i = 1, #keys - keep do
    doc.days[keys[i]] = nil
  end
end

local function save()
  local doc = load()
  prune(doc, settings().keep_days)
  local ok, why = STORE:put(doc, nil, true)
  if not ok then
    warn(BLOB .. " not written: " .. tostring(why))
  end
end

local function day_of(doc, date)
  local key = tostring(date)
  local d = doc.days[key]
  if type(d) ~= "table" then
    d = { done = false, best = { won = 0, gf = 0, ga = 0 }, attempts = 0 }
    doc.days[key] = d
  end
  return d
end

-- the run of `date` (a new one when the kept run is of another day)
local function run_of(doc, p)
  local r = doc.run
  if type(r) ~= "table" or r.date ~= p.date or r.team ~= p.team then
    r = { date = p.date, team = p.team, k = 0, results = {}, loaded = false }
    doc.run = r
  end
  return r
end

local function totals(results)
  local gf, ga = 0, 0
  for _, m in ipairs(results) do
    gf, ga = gf + (m.gf or 0), ga + (m.ga or 0)
  end
  return gf, ga
end

local function better(won, gf, ga, best)
  if won ~= best.won then
    return won > best.won
  end
  if gf ~= best.gf then
    return gf > best.gf
  end
  return ga < best.ga
end

local function record(doc, r, res)
  local p = D.plan(r.date)
  local matches = p and p.matches or (#r.results + 1)
  local d = day_of(doc, r.date)
  local event
  if res.outcome == "win" then
    r.results[#r.results + 1] = { gf = res.gf, ga = res.ga }
    r.k = r.k + 1
    local gf, ga = totals(r.results)
    if better(r.k, gf, ga, d.best) then
      d.best = { won = r.k, gf = gf, ga = ga }
    end
    if r.k >= matches then
      d.done = true
      event = "completed"
    else
      event = "won"
    end
  else
    event = "lost"
  end
  r.last = { event = event, gf = res.gf, ga = res.ga, k = r.k }
  save()
  info(string.format("%d: %s %d-%d; run %d/%d, best %d won (%d-%d)%s", r.date, tostring(res.outcome), res.gf, res.ga,
    r.k, matches, d.best.won, d.best.gf, d.best.ga, d.done and ", day done" or ""))
  return event
end

local LIVE = false

VRFW.on("match:start", function()
  LIVE = false
  local r = load().run
  if type(r) == "table" and r.loaded then
    local b = Block.read()
    LIVE = b ~= nil and b.player == r.team and b.index == r.k
  end
  return nil
end)

VRFW.on("script:signal:vrfw.match_result", function()
  if not LIVE then
    return nil
  end
  LIVE = false
  local last = VRFW.match.results.last()
  local doc = load()
  local r = doc.run
  if type(last) ~= "table" or type(r) ~= "table" or not r.loaded then
    return nil
  end
  r.seen = true
  local event = record(doc, r, { gf = U.int(last.score_for, 0), ga = U.int(last.score_against, 0),
    outcome = last.outcome })
  if event == "completed" then
    Trophy.play("daily_challenge", last)
  end
  return nil
end)

VRFW.on("save:slot_load", function()
  STORE:forget()
  LIVE = false
  return nil
end)

function BattleBayDeluxe.DailyInfo(date)
  local p, why = D.plan(date)
  if not p then
    return { ok = false, why = tostring(why) }
  end
  local doc = load()
  local r = run_of(doc, p)
  local d = day_of(doc, p.date)
  return {
    ok = true, date = p.date, team = p.team, rivals = p.rivals, matches = p.matches, k = r.k, results = r.results,
    loaded = r.loaded == true, done = d.done == true, best = d.best, attempts = d.attempts or 0, last = r.last,
  }
end

function BattleBayDeluxe.DailyLoaded()
  local r = load().run
  return type(r) == "table" and r.loaded == true
end

function BattleBayDeluxe.DailyPrepare(date)
  local p, why = D.plan(date)
  if not p then
    return { ok = false, why = tostring(why) }
  end
  local doc = load()
  local r = run_of(doc, p)
  if r.k >= p.matches then
    r.k, r.results = 0, {}
    info(string.format("%d: the run starts again", p.date))
  end
  if not r.loaded and not Block.snapshot(CAMP_BLOB) then
    return { ok = false, why = "snapshot" }
  end
  local diff = p.difficulty[r.k + 1] or 2
  if not Block.write(0, diff, p.team, p.rivals, r.k) then
    Block.restore(CAMP_BLOB)
    return { ok = false, why = "block" }
  end
  r.loaded, r.seen, r.last = true, nil, nil
  local d = day_of(doc, p.date)
  d.attempts = (d.attempts or 0) + 1
  save()
  info(string.format("%d: match %d/%d, team %s vs %s, difficulty %d (the Campaña's block lent)", p.date, r.k + 1,
    p.matches, VRFW.ids.hex_text(p.team), VRFW.ids.hex_text(p.rivals[r.k + 1]), diff))
  return { ok = true, k = r.k }
end

function BattleBayDeluxe.DailyUnload()
  local doc = load()
  if type(doc.run) == "table" then
    doc.run.loaded = false
    save()
  end
  Block.restore(CAMP_BLOB)
  return true
end

function BattleBayDeluxe.DailySync()
  local doc = load()
  local r = doc.run
  if type(r) ~= "table" or not r.loaded then
    if Block.has_snapshot(CAMP_BLOB) then
      Block.restore(CAMP_BLOB)
    end
    return { event = "none" }
  end
  local b = Block.read()
  local seen = r.seen == true
  r.loaded, r.seen = false, nil
  Block.restore(CAMP_BLOB)
  if seen and type(r.last) == "table" then
    save()
    return { event = r.last.event, gf = r.last.gf, ga = r.last.ga, k = r.k }
  end
  local touched = b ~= nil and (b.player ~= r.team or b.index ~= r.k or (b.rivals[1] or 0) == 0)
  if not touched then
    save()
    info("the lent block was not played (a cancelled load or a restart): nothing recorded")
    return { event = "none" }
  end
  local won = b.player == r.team and b.index == r.k + 1
  warn("no vrfw.match_result seen: the outcome taken from the campaign block (" .. (won and "win" or "loss") .. ")")
  local event = record(doc, r, { gf = 0, ga = 0, outcome = won and "win" or "loss" })
  return { event = event, gf = 0, ga = 0, k = r.k }
end

return D
