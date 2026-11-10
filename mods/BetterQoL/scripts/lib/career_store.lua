-- Career stats store (per-slot blob career.json) and per-match rules (assists, man of the match, modes, exclusions).

local S = {}

S.BLOB = "career.json"
-- unknown dates read S.UNKNOWN_DAY
S.FILE_VERSION = 2
S.UNKNOWN_DAY = -1
S.MATCH_TYPE_TRAINING = 3
S.MODES = { "story", "chronicle", "free", "vroad", "kizuna", "battle_bay" }
S.MODE_FREE = 3
S.MODE_BATTLE_BAY = 6
-- the per-actor match numbers summed per player
S.PER_FIELDS = { "shots", "steals", "saves", "skill_uses", "hiper_uses", "conceded" }

local OUTCOME_FIELD = { win = "wins", draw = "draws", loss = "losses" }
local OUTCOME_CODE = { win = 1, draw = 2, loss = 3 }

function S.mode_index(play_mode)
  if play_mode == 2 or play_mode == 6 then return 1 end
  if play_mode == 4 then return 2 end
  if play_mode == 5 then return 4 end
  if play_mode == 3 then return 5 end
  return S.MODE_FREE
end

-- why a match is not counted (nil = counted)
function S.exclusion(match_type, half_len, user_team, reserved_slot)
  if reserved_slot then return "reserved slot of a mod's own mode (that mode keeps its own counters)" end
  if user_team > 1 then return "no user team (spectator / CPU vs CPU)" end
  if match_type == S.MATCH_TYPE_TRAINING then return "training drill (engine match type 3)" end
  if half_len == 0 then return "no match clock (drill)" end
  return nil
end

function S.source_kind(src)
  if src == 4 then return 1 end
  if src == 2 or src == 6 then return 2 end
  if src == 5 then return 3 end
  if src == 10 then return 4 end
  return 0
end

function S.role(main_position, matches, gk_matches)
  if matches > 0 and gk_matches * 2 >= matches then return 1 end
  if main_position and main_position >= 1 and main_position <= 4 then return main_position end
  return 2
end

-- the engine's on-pitch test of a team member (0xEB2900)
function S.member_on_pitch(position, on_pitch_count, flags)
  return bit32.band(flags, 0x800) == 0 and bit32.band(flags, 0x8) == 0 and position < on_pitch_count
end

function S.rec_new() return { slots = {}, per = {} } end

function S.new_per()
  return { shots = 0, steals = 0, saves = 0, skill_uses = 0, hiper_uses = 0, conceded = 0, keeper = false }
end

local function per_of(r, chara)
  local e = r.per[chara]
  if not e then
    e = S.new_per()
    r.per[chara] = e
  end
  return e
end
S.per_of = per_of

function S.rec_sample(r, actor, chara, vals)
  local prev = r.slots[actor]
  local prev_chara, last = chara, { 0, 0, 0, 0 }
  if prev then prev_chara, last = prev[1], prev[2] end
  local d = {}
  local any = false
  for k = 1, 4 do
    if vals[k] >= last[k] then d[k] = vals[k] - last[k] else d[k] = vals[k] end
    if d[k] > 0 then any = true end
  end
  if prev_chara ~= 0 and any then
    local e = per_of(r, prev_chara)
    e.shots = e.shots + d[1]
    e.steals = e.steals + d[2]
    e.saves = e.saves + d[3]
    e.skill_uses = e.skill_uses + d[4]
  end
  r.slots[actor] = { chara, vals }
end

function S.contributions(goals)
  local m = {}
  for _, g in ipairs(goals) do
    if g.scorer then
      m[g.scorer] = m[g.scorer] or { 0, 0 }
      m[g.scorer][1] = m[g.scorer][1] + 1
    end
    if g.assist and g.assist ~= g.scorer then
      m[g.assist] = m[g.assist] or { 0, 0 }
      m[g.assist][2] = m[g.assist][2] + 1
    end
  end
  return m
end

function S.man_of_the_match(contrib)
  local keys = {}
  for p in pairs(contrib) do keys[#keys + 1] = p end
  table.sort(keys)
  local best, best_pts, tie = nil, nil, false
  for _, p in ipairs(keys) do
    local pts = 2 * contrib[p][1] + contrib[p][2]
    if pts > 0 then
      if best_pts and pts == best_pts then
        tie = true
      elseif not best_pts or pts > best_pts then
        best, best_pts, tie = p, pts, false
      end
    end
  end
  if tie then return nil end
  return best
end

local CLUB_FIELDS = { "since", "matches", "wins", "draws", "losses", "goals_for", "goals_against", "clean_sheets",
  "best_win_for", "best_win_against", "best_win_day", "win_run", "best_win_run", "unbeaten_run", "best_unbeaten_run" }

function S.club_new()
  local c = {}
  for _, k in ipairs(CLUB_FIELDS) do c[k] = 0 end
  return c
end

local function club_read(x)
  local c = S.club_new()
  if type(x) == "table" then
    for _, k in ipairs(CLUB_FIELDS) do c[k] = tonumber(x[k]) or 0 end
  end
  return c
end

-- biggest win = largest margin, then most goals
function S.club_apply(c, outcome, gf, ga, today)
  if c.since == 0 then c.since = today end
  c.matches = c.matches + 1
  c.goals_for = c.goals_for + gf
  c.goals_against = c.goals_against + ga
  if ga == 0 then c.clean_sheets = c.clean_sheets + 1 end
  if outcome == "win" then
    c.wins = c.wins + 1
    c.win_run = c.win_run + 1
    local margin, best = gf - ga, c.best_win_for - c.best_win_against
    if c.best_win_day == 0 or margin > best or (margin == best and gf > c.best_win_for) then
      c.best_win_for, c.best_win_against, c.best_win_day = gf, ga, today
    end
  else
    c.win_run = 0
  end
  if outcome == "draw" then c.draws = c.draws + 1 end
  if outcome == "loss" then
    c.losses = c.losses + 1
    c.unbeaten_run = 0
  else
    c.unbeaten_run = c.unbeaten_run + 1
  end
  if c.win_run > c.best_win_run then c.best_win_run = c.win_run end
  if c.unbeaten_run > c.best_unbeaten_run then c.best_unbeaten_run = c.unbeaten_run end
end

function S.club_reconcile(f)
  local c = f.club or S.club_new()
  f.club = c
  local recorded = f.recorded or 0
  if recorded <= c.matches then return false end
  local anchor, gf, ga = nil, 0, 0
  local best_for, best_against, best_day = 0, 0, 0
  for _, s in pairs(f.players) do
    if (s.matches or 0) > 0 then
      if anchor == nil or s.matches > anchor.matches then anchor = s end
      gf = gf + (s.goals or 0)
      ga = ga + (s.conceded or 0)
      local l = s.last
      if l and l.result == 1 and l.day > 0 then
        local margin, best = l.gf - l.ga, best_for - best_against
        if best_day == 0 or margin > best or (margin == best and l.gf > best_for) then
          best_for, best_against, best_day = l.gf, l.ga, l.day
        end
      end
    end
  end
  local function up(k, v) if v > c[k] then c[k] = v end end
  c.matches = recorded
  if anchor then
    up("wins", anchor.wins)
    up("draws", anchor.draws)
    up("losses", anchor.losses)
    up("clean_sheets", anchor.clean_sheets)
    if anchor.matches == recorded and anchor.losses == 0 then
      c.unbeaten_run = recorded
      up("best_unbeaten_run", recorded)
      if anchor.draws == 0 then
        c.win_run = recorded
        up("best_win_run", recorded)
      end
    end
  end
  up("goals_for", gf)
  up("goals_against", ga)
  if c.best_win_day == 0 and best_day > 0 then
    c.best_win_for, c.best_win_against, c.best_win_day = best_for, best_against, best_day
  end
  if (f.since or 0) > 0 and (c.since == 0 or f.since < c.since) then c.since = f.since end
  return true
end

function S.key(hdl) return string.format("%08X", hdl) end

local HISTORY_FIELDS = { "number", "day", "mode", "rival", "gf", "ga", "result", "mvp" }

-- one recorded match of the club history, every field present
local function history_entry_read(x)
  local e = { scorers = {} }
  for _, k in ipairs(HISTORY_FIELDS) do e[k] = tonumber(x[k]) or 0 end
  for _, sc in ipairs(type(x.scorers) == "table" and x.scorers or {}) do
    local param, goals = type(sc) == "table" and tonumber(sc[1]), type(sc) == "table" and tonumber(sc[2])
    if param and goals then e.scorers[#e.scorers + 1] = { param, goals } end
  end
  return e
end

-- the club history of a JSON file, oldest first ({} before the history existed)
local function history_read(x)
  local out = {}
  for _, e in ipairs(type(x) == "table" and x or {}) do
    if type(e) == "table" then out[#out + 1] = history_entry_read(e) end
  end
  return out
end

-- the history row of a recorded match: rival team id, the man of the match and the scorers by character param
function S.history_entry(m, contrib, mvp, ident, number, today)
  local e = { number = number, day = today, mode = m.mode, rival = m.rival or 0, gf = m.gf, ga = m.ga,
    result = OUTCOME_CODE[m.outcome] or 0, mvp = 0, scorers = {} }
  if mvp then e.mvp = ident(mvp) or 0 end
  local keys = {}
  for p, c in pairs(contrib) do
    if c[1] > 0 then keys[#keys + 1] = p end
  end
  table.sort(keys, function(a, b)
    if contrib[a][1] ~= contrib[b][1] then return contrib[a][1] > contrib[b][1] end
    return a < b
  end)
  for _, p in ipairs(keys) do
    local param = ident(p)
    if param then e.scorers[#e.scorers + 1] = { param, contrib[p][1] } end
  end
  return e
end

-- append `e` to the club history, keeping the newest `max` matches
function S.history_push(f, e, max)
  f.history = f.history or {}
  f.history[#f.history + 1] = e
  while #f.history > max do table.remove(f.history, 1) end
end

function S.new_file(slot)
  return { version = S.FILE_VERSION, slot = slot, watermark = nil, since = 0, recorded = 0, players = {}, club = S.club_new(),
    history = {} }
end

local function fresh_stats(param, order, signed)
  return {
    param = param, order = order, signed = signed,
    matches = 0, wins = 0, draws = 0, losses = 0, goals = 0, assists = 0, mvp = 0,
    shots = 0, steals = 0, saves = 0, conceded = 0, clean_sheets = 0, gk_matches = 0,
    skill_uses = 0, hiper_uses = 0, first_goal = 0, first_mvp = 0,
    best_goals = 0, best_goals_day = 0, best_goals_exact = 1, best_saves = 0, best_saves_day = 0, best_saves_exact = 1,
    last = { day = 0, result = 0, gf = 0, ga = 0, goals = 0, assists = 0 },
    modes = {},
  }
end

local function fresh_mode()
  return { matches = 0, wins = 0, draws = 0, losses = 0, goals = 0, assists = 0, mvp = 0, saves = 0 }
end

local NUM_FIELDS = { "param", "order", "signed", "matches", "wins", "draws", "losses", "goals", "assists", "mvp",
  "shots", "steals", "saves", "conceded", "clean_sheets", "gk_matches", "skill_uses", "hiper_uses", "first_goal" }
local NUM_FIELDS_DATES = { "first_mvp", "best_goals", "best_goals_day", "best_goals_exact", "best_saves", "best_saves_day",
  "best_saves_exact" }

-- a JSON record with every field present
local function normalize(s)
  local d = fresh_stats(0, 0, 0)
  for _, k in ipairs(NUM_FIELDS) do d[k] = tonumber(s[k]) or 0 end
  if type(s.last) == "table" then
    for k in pairs(d.last) do d.last[k] = tonumber(s.last[k]) or 0 end
  end
  if type(s.modes) == "table" then
    for m, x in pairs(s.modes) do
      if type(x) == "table" then
        local e = fresh_mode()
        for k in pairs(e) do e[k] = tonumber(x[k]) or 0 end
        d.modes[m] = e
      end
    end
  end
  for _, k in ipairs(NUM_FIELDS_DATES) do d[k] = tonumber(s[k]) or d[k] end
  return d
end

function S.decode(text, slot)
  if not text then return S.new_file(slot) end
  local j, err = VRFW.json.decode(text)
  if type(j) ~= "table" then return nil, err or "not a JSON object" end
  local f = S.new_file(slot)
  f.watermark = tonumber(j.watermark)
  f.since = tonumber(j.since) or 0
  f.recorded = tonumber(j.recorded) or 0
  f.club = club_read(j.club)
  f.history = history_read(j.history)
  if type(j.players) == "table" then
    for k, s in pairs(j.players) do
      if type(s) == "table" then f.players[k] = normalize(s) end
    end
  end
  f.club_reconciled = S.club_reconcile(f)
  return f
end

function S.encode(f)
  local players = {}
  for k, s in pairs(f.players) do players[k] = s end
  local t = { version = f.version, slot = f.slot, since = f.since, recorded = f.recorded, players = players,
    club = f.club or S.club_new(), history = f.history or {} }
  if f.watermark then t.watermark = f.watermark end
  return VRFW.json.encode(t, true)
end

function S.is_old(f, order)
  return f.watermark == nil or order <= f.watermark
end

function S.set_watermark(f, max_order, today)
  if f.watermark ~= nil then return false end
  f.watermark = max_order
  f.since = today
  return true
end

function S.get(f, hdl, param, order)
  local s = f.players[S.key(hdl)]
  if s and s.param == param and s.order == order then return s end
  return nil
end

local function entry(f, hdl, param, order, today)
  local signed = today
  if S.is_old(f, order) then signed = 0 end
  local k = S.key(hdl)
  local e = f.players[k]
  if not e or e.param ~= param or e.order ~= order then
    e = fresh_stats(param, order, signed)
    f.players[k] = e
  end
  return e
end

function S.observe(f, hdl, param, order, today)
  if hdl == 0 or f.watermark == nil or S.is_old(f, order) or S.get(f, hdl, param, order) then return false end
  entry(f, hdl, param, order, today)
  return true
end

function S.apply_match(f, m, ident, today)
  local contrib = S.contributions(m.goals)
  local mvp = S.man_of_the_match(contrib)
  local credited = {}
  for p in pairs(m.players) do credited[p] = true end
  for _, g in ipairs(m.goals) do
    if g.scorer then credited[g.scorer] = true end
    if g.assist then credited[g.assist] = true end
  end
  local code = OUTCOME_CODE[m.outcome]
  local result_field = OUTCOME_FIELD[m.outcome] or "losses"
  local n = 0
  for p in pairs(credited) do
    local param, order = ident(p)
    if param then
      local e = entry(f, p, param, order, today)
      e.matches = e.matches + 1
      e[result_field] = e[result_field] + 1
      local c = contrib[p] or { 0, 0 }
      local g, a = c[1], c[2]
      e.goals = e.goals + g
      e.assists = e.assists + a
      if mvp == p then
        e.mvp = e.mvp + 1
        if e.first_mvp == 0 then e.first_mvp = today end
      end
      if g > 0 and e.first_goal == 0 then e.first_goal = today end
      if g > e.best_goals then e.best_goals, e.best_goals_day = g, today end
      local pm = m.per[p]
      if pm then
        for _, k in ipairs(S.PER_FIELDS) do e[k] = e[k] + pm[k] end
        if pm.keeper then e.gk_matches = e.gk_matches + 1 end
        if pm.saves > e.best_saves then e.best_saves, e.best_saves_day = pm.saves, today end
      end
      if m.ga == 0 then e.clean_sheets = e.clean_sheets + 1 end
      e.last = { day = today, result = code, gf = m.gf, ga = m.ga, goals = g, assists = a }
      local name = S.MODES[math.min(m.mode, #S.MODES)]
      local ms = e.modes[name]
      if not ms then
        ms = fresh_mode()
        e.modes[name] = ms
      end
      ms.matches = ms.matches + 1
      ms[result_field] = ms[result_field] + 1
      ms.goals = ms.goals + g
      ms.assists = ms.assists + a
      if mvp == p then ms.mvp = ms.mvp + 1 end
      if pm then ms.saves = ms.saves + pm.saves end
      n = n + 1
    end
  end
  f.recorded = f.recorded + 1
  f.club = f.club or S.club_new()
  S.club_apply(f.club, m.outcome, m.gf, m.ga, today)
  return n, mvp, contrib
end

-- what the plate shows
function S.view(f, hdl, param, order)
  local before = 0
  if S.is_old(f, order) then before = f.since end
  local s = S.get(f, hdl, param, order)
  if not s then return { signed = 0, before = before, matches = 0, wins = 0, draws = 0, losses = 0, goals = 0, assists = 0, mvp = 0 } end
  local b = 0
  if s.signed == 0 then b = f.since end
  return { signed = s.signed, before = b, matches = s.matches, wins = s.wins, draws = s.draws, losses = s.losses,
    goals = s.goals, assists = s.assists, mvp = s.mvp }
end

return S
