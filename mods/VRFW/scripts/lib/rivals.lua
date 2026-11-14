--- Advanced: Library: rival players, their stats, positions and elements.

local Id = VRFW.ids
local ME = VRFW.match.equipment
local _, warn = VRFW.logger("rival_players")

local M = {}
local TWO32 = 4294967296

--- Advanced: Constants: rival stat names mapped to their stat index.
M.STAT = { kick = 0, control = 1, technique = 2, pressure = 3, physical = 4, intelligence = 5, agility = 6, luck = 8 }
--- Internal: Stat index mapped back to its stat name.
M.STAT_NAME = {}
for k, v in pairs(M.STAT) do M.STAT_NAME[v] = k end
--- Internal: Position code (1-4) mapped to GK, FW, MF or DF.
M.POSITION_KEY = { [1] = "GK", [2] = "FW", [3] = "MF", [4] = "DF" }
--- Internal: Constant 5.
M.SLOTS = 5
--- Internal: Element names mapped to their element index.
M.ELEMENT = { neutral = 0, wind = 1, forest = 2, fire = 3, mountain = 4, void = 5 }

local RULES = nil

local function crc(text)
  local f = VRFW.crc32 or (VRFW.ui and VRFW.crc32)
  return f and (f(text) % TWO32) or 0
end

local function key_id(v)
  if type(v) == "number" then return Id.unsigned(v) end
  if type(v) == "string" then
    if v:match("^0[xX]%x+$") then return Id.unsigned(tonumber(v:sub(3), 16)) end
    return crc(v)
  end
  return 0
end

-- passive keys / ids -> ids (0 dropped; repeats dropped too unless keep_repeats)
local function passive_ids(list, where, keep_repeats)
  local out, seen = {}, {}
  for _, v in ipairs(type(list) == "table" and list or {}) do
    local id = key_id(v)
    if id ~= 0 and (keep_repeats or not seen[id]) then
      out[#out + 1], seen[id] = id, true
    elseif id == 0 then
      warn(where .. ": passive " .. tostring(v) .. " unknown (skipped)")
    end
  end
  return out
end

-- a stat-name list -> stat numbers (unknown / repeated skipped)
local function stat_list(list, where)
  local out, seen = {}, {}
  for _, name in ipairs(type(list) == "table" and list or {}) do
    local i = M.STAT[tostring(name):lower()]
    if i and not seen[i] then
      out[#out + 1], seen[i] = i, true
    else
      warn(where .. ": stat " .. tostring(name) .. " unknown or repeated (skipped)")
    end
  end
  return out, seen
end

-- { kick = n, ... } -> { [stat 0..7] = n } (luck has no match-copy value: skipped)
local function stat_map(t, where)
  if type(t) ~= "table" then return nil end
  local out, any = {}, false
  for name, v in pairs(t) do
    local i = M.STAT[tostring(name):lower()]
    if i and i <= 7 and tonumber(v) then
      out[i], any = math.floor(tonumber(v)), true
    else
      warn(where .. ": stat " .. tostring(name) .. " unknown or not a number (skipped)")
    end
  end
  return any and out or nil
end

local function by_position(row, convert, where)
  local out = {}
  for code, key in pairs(M.POSITION_KEY) do
    if row[key] ~= nil then out[code] = convert(row[key], where .. " " .. key) end
  end
  return out
end

local function games_of(v)
  if v == nil then return nil end
  local list = type(v) == "table" and v or { v }
  local out, any = {}, false
  for _, g in ipairs(list) do
    local id = key_id(g)
    if id ~= 0 then out[id], any = true, true end
  end
  return any and out or nil
end

local function read_rules()
  RULES = {}
  local ok, files = pcall(VRFW.files.declarations, "content/rival_players")
  if not ok or type(files) ~= "table" then return RULES end
  for _, f in ipairs(files) do
    local d, source = f.data or {}, tostring(f.mod)
    local stats_by, sets_by, pos_by, arch_by = {}, {}, {}, {}
    for _, row in ipairs(d.archetype or {}) do
      if type(row.name) == "string" then
        local where = source .. " archetype " .. row.name
        local a = { name = row.name, stats = {}, passives = {}, element = {} }
        for code, key in pairs(M.POSITION_KEY) do
          local p = row[key]
          if type(p) == "table" then
            local l, s = stat_list(p.stats, where .. " " .. key)
            a.stats[code] = { list = l, set = s }
            a.passives[code] = passive_ids(p.passives, where .. " " .. key)
          end
        end
        for name, v in pairs(type(row.element_bonus) == "table" and row.element_bonus or {}) do
          local e = M.ELEMENT[tostring(name):lower()]
          if e and tonumber(v) then a.element[e] = tonumber(v) else warn(where .. ": element " .. tostring(name) .. " unknown (skipped)") end
        end
        arch_by[row.name] = a
      end
    end
    for _, row in ipairs(d.training_stats or {}) do
      if type(row.name) == "string" then
        stats_by[row.name] = by_position(row, function(list, w)
          local l, s = stat_list(list, w)
          return { list = l, set = s }
        end, source .. " training_stats " .. row.name)
      end
    end
    for _, row in ipairs(d.passive_set or {}) do
      if type(row.name) == "string" then
        sets_by[row.name] = { name = row.name, ids = passive_ids(row.passives, source .. " passive_set " .. row.name) }
      end
    end
    for _, row in ipairs(d.position_passives or {}) do
      if type(row.name) == "string" then
        pos_by[row.name] = by_position(row, function(list, where) return passive_ids(list, where, true) end,
          source .. " position_passives " .. row.name)
      end
    end
    local by_name = {}
    for _, r in ipairs(d.rule or {}) do
      local where = source .. " rule " .. tostring(r.name)
      local diff, diffs = ME.difficulty(r.difficulty), nil
      for _, v in ipairs(type(r.difficulties) == "table" and r.difficulties or {}) do
        local n = ME.difficulty(v)
        if n then
          diffs = diffs or {}
          diffs[n] = true
        else
          warn(where .. ": unknown difficulty " .. tostring(v) .. " (skipped)")
        end
      end
      if not diff and not diffs then
        warn(where .. ": unknown difficulty " .. tostring(r.difficulty) .. " (rule off)")
      else
        local rule = { name = tostring(r.name), source = source, difficulty = diff, difficulties = diffs,
          play_mode = tonumber(r.play_mode), side = r.side or "rival", games = games_of(r.games), players = {}, sets = {},
          set_count = math.max(0, math.floor(tonumber(r.set_passives) or 0)),
          team_focus = tonumber(r.team_focus) or 0, keep_special = r.keep_special == true }
        for _, n in ipairs(type(r.archetypes) == "table" and r.archetypes or {}) do
          if arch_by[n] then
            rule.archetypes = rule.archetypes or {}
            arch_by[n].index = #rule.archetypes + 1
            rule.archetypes[arch_by[n].index] = arch_by[n]
          else
            warn(where .. ": archetype " .. tostring(n) .. " not in the file (skipped)")
          end
        end
        local by_class = r.training_level == "class"
        if (tonumber(r.training_level) or by_class) and (r.training_stats or rule.archetypes) then
          local st = r.training_stats and stats_by[r.training_stats] or nil
          if st or rule.archetypes then
            rule.training = { level = (not by_class) and math.floor(tonumber(r.training_level)) or nil, by_class = by_class, stats = st or {} }
          else
            warn(where .. ": training_stats " .. tostring(r.training_stats) .. " not in the file (no training)")
          end
        end
        for _, n in ipairs(r.passive_sets or {}) do
          if sets_by[n] and #sets_by[n].ids > 0 then
            rule.sets[#rule.sets + 1] = sets_by[n]
          else
            warn(where .. ": passive_set " .. tostring(n) .. " not in the file or empty (skipped)")
          end
        end
        if r.position_passives then
          rule.positions = pos_by[r.position_passives]
          if not rule.positions then
            warn(where .. ": position_passives " .. tostring(r.position_passives) .. " not in the file (skipped)")
          end
        end
        RULES[#RULES + 1] = rule
        by_name[rule.name] = rule
      end
    end
    for _, p in ipairs(d.player or {}) do
      local rule, card = by_name[tostring(p.rule)], key_id(p.card)
      local where = source .. " player " .. string.format("0x%08X", card)
      if not rule or card == 0 then
        warn(where .. ": rule " .. tostring(p.rule) .. " not in the file or no card (skipped)")
      else
        rule.players[card] = { passives = p.passives and passive_ids(p.passives, where) or nil,
          stats = stat_map(p.stats, where), points = stat_map(p.points, where) }
      end
    end
  end
  return RULES
end

-- the rules, built once per VM and kept between starts (mod files only)
local function load()
  if RULES then return RULES end
  local ok, t = pcall(VRFW.derived, "rival_rules", nil, read_rules)
  if ok and type(t) == "table" then
    RULES = t
  else
    RULES = {}
    warn("content/rival_players not read (" .. tostring(t) .. ")")
  end
  return RULES
end

--- Advanced: Builds (or reads from the start cache) the rules; a script calls it at load so a match call stays short.
M.prepare = load

--- Advanced: the rule of a match: game rules first, then difficulty rules; the mod loaded last wins
function M.rule(game, diff, mode, side)
  local rules = load()
  local best, best_rank = nil, -1
  for _, r in ipairs(rules) do
    if VRFW.mod_is_on_now(r.source) and (r.difficulty == diff or (r.difficulties and r.difficulties[diff])) and (r.play_mode == nil or r.play_mode == mode) and r.side == (side or "rival") then
      local rank = -1
      if r.games then
        if r.games[Id.unsigned(game or 0)] then rank = 1 end
      else
        rank = 0
      end
      if rank >= 0 and rank >= best_rank then best, best_rank = r, rank end
    end
  end
  return best
end

-- how well a player's own values suit the archetype's stats for his position: the share of his values in them, 0..1
local function stat_fit(a, row)
  local st = a.stats[row.pos]
  if not st or not row.base then return 0 end
  local listed, all = 0, 0
  for i = 0, 8 do all = all + (row.base[i] or 0) end
  for _, i in ipairs(st.list) do listed = listed + (row.base[i] or 0) end
  return all > 0 and listed / all or 0
end

--- Advanced: The cards `rule` picks from `rows`, as an array.
function M.choose(rule, rows)
  local picks = {}
  if not rule.archetypes or #rows == 0 then return picks end
  local base_score, votes = {}, {}
  for _, row in ipairs(rows) do
    local ok, ci = pcall(VRFW.character.card, row.card)
    local element = ok and type(ci) == "table" and tonumber(ci.element) or 0
    local scores, best = {}, nil
    for k, a in ipairs(rule.archetypes) do
      scores[k] = a.passives[row.pos] and (stat_fit(a, row) + (a.element[element] or 0)) or -1
      if not best or scores[k] > scores[best] then best = k end
    end
    base_score[row.card] = scores
    votes[best] = (votes[best] or 0) + 1
  end
  for _, row in ipairs(rows) do
    local scores, best, top = base_score[row.card], nil, nil
    for k in ipairs(rule.archetypes) do
      local s = scores[k] + rule.team_focus * (votes[k] or 0) / #rows
      if scores[k] >= 0 and (not top or s > top) then best, top = k, s end
    end
    picks[row.card] = best and rule.archetypes[best] or nil
  end
  return picks
end

--- Internal: The position of card `card` (0 when unknown).
function M.position(card)
  local ok, ci = pcall(VRFW.character.card, card)
  local p = ok and type(ci) == "table" and tonumber(ci.position) or 0
  if p == 1 or p == 2 or p == 4 then return p end
  return 3
end

return M
