-- Player Training › the rival players a mod declares trained to the full for a match (VRFW match training,
-- content\match_training\*.toml of any active mod, e.g. Chronicle Deluxe's legendary free match; VRFW/lib/match_training).
-- When the match is requested (match:start_request, before its players are built) each rival card of a trained
-- position is trained as a player could train it: the same rules as config.toml [training] (its floor and max value),
-- position pairs of lib/training_rules.lua, the card's untrained values and Libertad at the rule's level
-- (lib/card_stats.lua). Every Libertad point goes into the position's stats of config.toml [rival_training] (in their
-- order, or split evenly), then each of those stats is raised by the trade rule until its counterpart is at its floor.
-- The deltas of stats 0..7 go to the native table ClassicTraining.RivalAdd (key: chara_param id, stat), added to the
-- rival's roster rows by [[VRFW.MatchStat]] ClassicTraining.RivalTraining; the Suerte delta is answered to
-- lib\stat_effects.lua (M.luck_delta). Match copies only: nothing is written to a save or to the user's cards.
-- The rival cards of the match are the ones its match equipment rule lists (VRFW/lib/match_equipment).
-- A VRFW rival players rule with a training (content\rival_players, VRFW/lib/rival_players) holding for the match
-- replaces this rule: its own levels and stat lists by position, the match's real roster (signal
-- vrfw.rival_players.training, see train_rival_players). There a player trains for the position he plays in the match's
-- formation (the bench: his card's): that position's pairs and list. All his Libertad goes into the list's first stat,
-- each listed stat is raised until its counterpart is at its floor, and a stat at its floor is answered as an absolute value.
-- A library, not a script: every script runs in its own VM, so lib\stat_effects.lua (required by
-- scripts\player_training.lua) requires it: its handlers and the Suerte deltas live in that VM. The training rules come from config.toml [training] (R.read_config) and the
-- training runs while the state ClassicTraining.active is 1 (scripts\player_training.lua).

local CS = require "lib/card_stats"
local R = require "lib/training_rules"
local ME = require "VRFW/lib/match_equipment"
local MT = require "VRFW/lib/match_training"
local RP = require "VRFW/lib/rival_players"

require "VRFW/lib/basics"
local info, warn = VRFW.logger("rival_training")
local u32 = CS.u32

local M = {}

local T_RIVAL = "ClassicTraining.RivalAdd"
local STATE_KEY = "ClassicTraining.active"
local STAT = { kick = 0, control = 1, technique = 2, pressure = 3, physical = 4, intelligence = 5, agility = 6, luck = 8 }
local STAT_NAME = {}
for k, v in pairs(STAT) do STAT_NAME[v] = k end
local POSITION_KEY = { [1] = "GK", [2] = "FW", [3] = "MF", [4] = "DF" }

local SETTINGS = nil   -- { [position code] = { stats = { i, ... }, spread } }
local USELESS = {}     -- [position code] = { [stat] = true }
local FILLED = false
local LUCK = {}        -- [card] = Suerte delta, this match
local RP_LUCK = {}     -- [card] = Suerte delta of the VRFW rival players' training (while its flags are set)
local RP_FLAG = "vrfw.rival_players"
local LOGGED = nil     -- the log text of the last trained match (cleared at match end)

local RULES, LOCKED = nil, nil

local function cfg(path, default)
  local ok, v = pcall(VRFW.files.config, path)
  if not ok or v == nil then return default end
  if default ~= nil and type(v) ~= type(default) then return default end
  return v
end

-- the training rules (config.toml [training], read once) and whether the training runs
local function training_rules()
  if not RULES then
    RULES, LOCKED = R.read_config(cfg)
    local bp = cfg("training.budget_percent", 0)   -- checked and reported by scripts\player_training.lua
    if type(bp) ~= "number" or bp ~= bp or bp < 0 or bp > 1000 then bp = 0 end
    CS.configure_budget({ percent = bp })
  end
  local ok, v = pcall(VRFW.state.get, STATE_KEY)
  return RULES, LOCKED, ok and (v == 1 or v == true)
end

local function settings()
  if SETTINGS then return SETTINGS end
  SETTINGS = {}
  local okS, spread = pcall(VRFW.files.config, "rival_training.spread")
  spread = (okS and spread == "even") and "even" or "priority"
  for code, key in pairs(POSITION_KEY) do
    local ok, list = pcall(VRFW.files.config, "rival_training." .. key)
    if ok and type(list) == "table" then
      local stats, seen = {}, {}
      for _, name in ipairs(list) do
        local i = STAT[tostring(name):lower()]
        if i and not seen[i] then
          stats[#stats + 1], seen[i] = i, true
        else
          warn(string.format("[rival_training] %s: stat %s unknown or repeated (skipped)", key, tostring(name)))
        end
      end
      if #stats > 0 then SETTINGS[code] = { stats = stats, spread = spread, set = seen } end
    end
  end
  return SETTINGS
end

-- { [stat] = true } of the stats config.toml [rival_training.useless] names for position code `pos` (read once)
local function useless_stats(pos)
  local set = USELESS[pos]
  if set then return set end
  set = {}
  for _, name in ipairs(cfg("rival_training.useless." .. POSITION_KEY[pos], {})) do
    local i = STAT[tostring(name):lower()]
    if i then
      set[i] = true
    else
      warn(string.format("[rival_training.useless] %s: stat %s unknown (skipped)", POSITION_KEY[pos], tostring(name)))
    end
  end
  USELESS[pos] = set
  return set
end

-- the card's untrained values at `level` [0..8]
local function base_of(p, level)
  local base = {}
  for i = 0, R.N - 1 do
    base[i] = (i == R.SPEED) and 0 or CS.stat(p, i, level)
  end
  base[R.LUCK] = CS.luck(p, level)
  return base
end

-- the deltas d[0..8] of a card trained to the full for `pos` at `level` (+ base values, each stat's lowest delta), nil
-- (+ reason) when it cannot be trained;
-- `s` = the position's stats { stats = { i, ... }, spread, set } (default: config.toml [rival_training]);
-- `known` = the card's values at that level when the caller holds them
local function train(card, pos, level, rules, locked, s, known)
  local p = CS.players()[card]
  if not p then return nil, "no card values" end
  if p.native then return nil, "no per-character values" end
  if CS.locked(p, locked) then return nil, "locked rarity" end
  s = s or settings()[pos]
  if not s then return nil, "no stats for its position" end
  local base, bonus = known or base_of(p, level), {}
  for i = 0, R.N - 1 do
    bonus[i] = 0
  end
  local total = CS.libertad(p, level, base)
  local c = R.ctx({ rule = "trade", floor_percent = rules.floor_percent, max_value = rules.max_value }, pos, base, bonus, total)
  local d = R.zeros()
  -- a stat off the list that still helps the position keeps up to [rival_training] useful_floor (below it: his own
  -- value, untouched); one the position's useless list names goes to the training's floor
  local keep = math.floor(cfg("rival_training.useful_floor", 0))
  if keep > 0 then
    local useless = useless_stats(pos)
    for i = 0, R.N - 1 do
      if i ~= R.SPEED and not s.set[i] and not useless[i] then
        c.lo[i] = math.max(c.lo[i], math.min(keep - base[i], 0))
      end
    end
  end
  -- the Libertad: evenly over the stats (the remainder to the first ones), or each stat to its max in order
  if s.spread == "even" then
    local n = #s.stats
    local share, rest = math.floor(total / n), total % n
    for k, i in ipairs(s.stats) do
      local want = share + ((k <= rest) and 1 or 0)
      R.set(c, d, i, d[i] + math.min(want, c.hi[i] - d[i]))
    end
  end
  for _, i in ipairs(s.stats) do
    local free = R.available(c, d)
    if free > 0 then R.set(c, d, i, d[i] + math.min(free, c.hi[i] - d[i])) end
  end
  -- the trade: each stat raised while its counterpart (not one of the stats) can go down towards its floor
  for _, i in ipairs(s.stats) do
    local drains = false
    for _, partner in ipairs(R.partners(pos, i)) do
      if not s.set[partner] then drains = true end
    end
    if drains and R.available(c, d) <= 0 then R.set(c, d, i, c.hi[i]) end
  end
  return d, nil, base, c.lo
end

local function clear()
  if FILLED then pcall(VRFW.native.table_clear, T_RIVAL) end
  FILLED = false
  LUCK = {}
end

local function describe(card, pos, level, base, d, card_pos)
  local parts = {}
  for i = 0, R.N - 1 do
    if d[i] ~= 0 then
      parts[#parts + 1] = string.format("%s %d->%d (%+d)", STAT_NAME[i], base[i], base[i] + d[i], d[i])
    end
  end
  local plays = POSITION_KEY[pos] .. ((card_pos and card_pos ~= pos) and (" (card " .. POSITION_KEY[card_pos] .. ")") or "")
  return string.format("0x%08X %s Lv %d: %s", card, plays, level, table.concat(parts, ", "))
end

local function refresh(request)
  local rules, locked, on = training_rules()
  local off = select(2, pcall(VRFW.game.field, "Match.StartRequestInfo"))
  local at = (type(off) == "number" and request and request >= 0x10000) and (request + off) or nil
  local rule = at and MT.of_info(at, "rival") or nil
  -- a VRFW rival players rule with a training was applied to this match (VRFW set its flags: its players and game):
  -- it trains the rival (signal vrfw.rival_players.training). A rule that found no players leaves this one on.
  if rule then
    local game, diff, mode = ME.match_of(at)
    local rp = game and RP.rule(game, diff, mode, "rival") or nil
    local applied = (tonumber(VRFW.flag(RP_FLAG .. ".count")) or 0) > 0
      and u32(tonumber(VRFW.flag(RP_FLAG .. ".game")) or 0) == u32(game or 0)
    if rp and rp.training and applied then
      clear()
      if LOGGED ~= rp.name then
        LOGGED = rp.name
        info(string.format("rival training (rule of %s): left to the rival players rule %s/%s", rule.source, rp.source, rp.name))
      end
      return
    end
  end
  local cards = rule and ME.of_info(at) or nil
  if not rule or not cards or not on or not CS.ready() then
    clear()
    if rule then
      local why = (not cards) and "the match equipment rule lists no rival cards" or (not on) and
        "the training is off" or "Character Reforged's card values are not published"
      if why ~= LOGGED then
        LOGGED = why
        warn(string.format("rival training (rule of %s): nothing trained, %s", rule.source, why))
      end
    end
    return
  end
  local entries, lines, luck = {}, {}, {}
  for card in pairs(cards) do
    card = u32(card)
    local p = CS.players()[card]
    local pos = p and R.position(p.pos)
    if pos and rule.positions[pos] then
      local d, why, base = train(card, pos, rule.level, rules, locked or {})
      if d then
        for i = 0, 7 do
          if d[i] ~= 0 then entries[#entries + 1] = { { card, i }, d[i] } end
        end
        if d[R.LUCK] ~= 0 then luck[card] = d[R.LUCK] end
        lines[#lines + 1] = describe(card, pos, rule.level, base, d)
      else
        lines[#lines + 1] = string.format("0x%08X %s not trained (%s)", card, POSITION_KEY[pos], why)
      end
    end
  end
  local ok, e = pcall(VRFW.native.table_replace, T_RIVAL, nil, entries)
  if not ok then warn(T_RIVAL .. ": " .. tostring(e)) end
  FILLED, LUCK = #entries > 0, luck
  table.sort(lines)
  local text = table.concat(lines, "\n")
  if text ~= LOGGED then
    LOGGED = text
    info(string.format("rival training (rule of %s): %d rival player(s) trained for this match", rule.source, #lines))
    for _, l in ipairs(lines) do info("rival training: " .. l) end
  end
end

-- the VRFW rival players' training (VRFW/lib/rival_players and VRFW scripts\rival_players.lua): the cards and the match
-- come as flags with the signal vrfw.rival_players.training; the deltas of stats 0..7 go back as flags
-- vrfw.rival_players.trained.<card>.<stat> with the signal vrfw.rival_players.trained (VRFW adds them to the match
-- copies); the Suerte delta stays here (M.luck_delta)
local function train_rival_players()
  RP_LUCK = {}
  clear()   -- the older match_training rule of this match, if it ran first, gives way to the applied rule
  local rules, locked, on = training_rules()
  local n = math.floor(tonumber(VRFW.flag(RP_FLAG .. ".count")) or 0)
  local game, diff = tonumber(VRFW.flag(RP_FLAG .. ".game")), tonumber(VRFW.flag(RP_FLAG .. ".difficulty"))
  local mode = tonumber(VRFW.flag(RP_FLAG .. ".play_mode"))
  if mode == -1 then mode = nil end
  local rp = (n > 0 and game and diff) and RP.rule(game, diff, mode, "rival") or nil
  if not rp or not rp.training then return end
  local level = tonumber(VRFW.flag(RP_FLAG .. ".level")) or rp.training.level
  if not on or not CS.ready() then
    warn(string.format("rival training (rule %s/%s): nothing trained, %s", rp.source, rp.name,
      (not on) and "the training is off" or "Character Reforged's card values are not published"))
    return
  end
  if not level then
    warn(string.format("rival training (rule %s/%s): nothing trained, the match names no level", rp.source, rp.name))
    return
  end
  -- one pass over the team: each card's values, then the archetype each one trains for (VRFW/lib/rival_players)
  local rows, known = {}, {}
  for k = 1, n do
    local card = u32(VRFW.flag(RP_FLAG .. ".card." .. k) or 0)
    local p = CS.players()[card]
    if p then
      local vals = (not p.native) and base_of(p, level) or nil
      known[card] = vals
      local place = math.floor(tonumber(VRFW.flag(RP_FLAG .. ".place." .. k)) or 0)
      local own = R.position(p.pos)
      rows[#rows + 1] = { card = card, pos = POSITION_KEY[place] and place or own, own = own, base = vals }
    end
  end
  local picks = RP.choose(rp, rows)
  local lines = {}
  for _, row in ipairs(rows) do
    local card, pos = row.card, row.pos
    local pick = picks[card]
    if pick then pcall(VRFW.set_flag, string.format("%s.archetype.%d", RP_FLAG, card), pick.index) end
    local st = (pick and pick.stats[pos]) or rp.training.stats[pos]
    if st and #st.list > 0 then
      local d, why, base, lowest = train(card, pos, level, rules, locked or {}, { stats = st.list, spread = "priority", set = st.set }, known[card])
      if d then
        for i = 0, 7 do
          if d[i] < 0 and d[i] <= lowest[i] then
            pcall(VRFW.set_flag, string.format("%s.floor.%d.%d", RP_FLAG, card, i), base[i] + d[i])
          elseif d[i] ~= 0 then
            pcall(VRFW.set_flag, string.format("%s.trained.%d.%d", RP_FLAG, card, i), d[i])
          end
        end
        if d[R.LUCK] ~= 0 then RP_LUCK[card] = d[R.LUCK] end
        lines[#lines + 1] = (pick and (pick.name .. " ") or "") .. describe(card, pos, level, base, d, row.own)
      else
        lines[#lines + 1] = string.format("0x%08X %s not trained (%s)", card, POSITION_KEY[pos], why)
      end
    end
  end
  info(string.format("rival training (rule %s/%s): %d rival player(s) trained for this match", rp.source, rp.name, #lines))
  table.sort(lines)
  for _, l in ipairs(lines) do info("rival training: " .. l) end
  pcall(VRFW.signal, "vrfw.rival_players.trained")
end

-- the Suerte delta of a rival match player of card `card` (0 for any other player)
function M.luck_delta(hdl, card)
  local delta = LUCK[u32(card or 0)]
  if not delta and (tonumber(VRFW.flag(RP_FLAG .. ".count")) or 0) > 0 then delta = RP_LUCK[u32(card or 0)] end
  if not delta then return 0 end
  local ok, a = pcall(VRFW.actor, hdl)
  if ok and a and a.side == "rival" then return delta end
  return 0
end

-- the Suerte delta the views show for a rival player without a saved owner, on the pitch or on the bench
function M.view_luck(hdl, card)
  local key = u32(card or 0)
  local delta = LUCK[key]
  if not delta and (tonumber(VRFW.flag(RP_FLAG .. ".count")) or 0) > 0 then delta = RP_LUCK[key] end
  if not delta then return nil end
  local ok, owner = pcall(VRFW.character.owner, hdl)
  if ok and owner == nil then return delta end
  return nil
end

VRFW.on("match:start_request", function(ev)
  local ok, e = pcall(refresh, ev.args and ev.args[2])
  if not ok then warn("rival training: " .. tostring(e)) end
end)

VRFW.on("signal:vrfw.rival_players.training", function()
  local ok, e = pcall(train_rival_players)
  if not ok then warn("rival training: " .. tostring(e)) end
end)

VRFW.on("match_end", function()
  LOGGED = nil
  RP_LUCK = {}
end)

VRFW.on("game_reset", function()
  clear()
  LOGGED = nil
end)

return M
