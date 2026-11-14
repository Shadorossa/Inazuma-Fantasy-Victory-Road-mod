-- Level sync of the user's team, script side (docs/framework/level-sync.md).

LevelSync = LevelSync or {}

local D = VRFW.declarations
local Memory = VRFW.memory
local Difficulty = VRFW.match.difficulty

local function info(text) VRFW.log("level_sync: " .. text) end
local function warn(text) VRFW.warn("level_sync: " .. text) end

local TABLE_RAISE, TABLE_CAP = "VRFW.LevelSync.Raise", "VRFW.LevelSync.Cap"
-- The card level tables only hold the rules whose moves come from the synced level.
local TABLE_CARD_RAISE, TABLE_CARD_CAP = "VRFW.LevelSync.CardRaise", "VRFW.LevelSync.CardCap"
local STATE_KEY = "VRFW.level_sync.request"
local HOOKS = { "LevelSync.MatchRequest", "LevelSync.MatchCopyLevel", "LevelSync.StatusLevel" }
-- The game's reads of the level a screen shows for the saved cards, whose own level is not changed.
local SHOWN_HOOKS = { "LevelSync.ShownTeamLevel", "LevelSync.ShownCharaInfo", "LevelSync.ShownMainStatus",
  "LevelSync.ShownDetailStatus", "LevelSync.ShownUseChara", "LevelSync.ShownCharaCard" }

local RULES = {}
local BLOCK = nil
local LIVE = false

local hex = VRFW.ids.hex_text

local function pair_text(game, row)
  local g = game == 0 and "any game" or "game " .. hex(game)
  local r = row == 0 and "any difficulty" or "difficulty " .. row
  return g .. ", " .. r
end

local function load_rules()
  local schema, why = D.schema("level_sync")
  if not schema then
    warn(why .. ": no level sync")
    return 0
  end
  local decls, skipped = D.load(schema, warn)
  local count = 0
  for _, d in ipairs(decls) do
    local v = d.v
    local games = (v.games and #v.games > 0) and v.games or { 0 }
    local rows = (v.difficulties and #v.difficulties > 0) and v.difficulties or { 0 }
    if v.difficulty_level then
      rows = {}
      for _, row in ipairs(v.difficulties or {}) do rows[#rows + 1] = row end
      for _, row in ipairs(Difficulty.rows_at_level(v.difficulty_level)) do rows[#rows + 1] = row end
      info(string.format("%s: difficulty rows at Nv. %d: %s", d.key or d.where, v.difficulty_level,
        #rows > 0 and table.concat(rows, ", ") or "none"))
    end
    if v.difficulty_level and #rows == 0 then
      warn(d.where .. ": no difficulty row is declared at Nv. " .. v.difficulty_level .. ": left out")
    elseif games[1] == 0 and rows[1] == 0 then
      warn(d.where .. ": neither games nor difficulties: left out (a rule names the matches it syncs)")
    else
      for _, game in ipairs(games) do
        for _, row in ipairs(rows) do
          local k = game .. ":" .. row
          local had = RULES[k]
          if had then
            warn(string.format("%s: %s already synced by %s: left out for it", d.where, pair_text(game, row), had.key))
          else
            RULES[k] = { game = game, row = row, level = v.level, raise = v.raise ~= false, saved_moves = v.moves == "saved", key = d.key }
            count = count + 1
          end
        end
      end
    end
  end
  if count == 0 then
    info(string.format("off: no declaration (%d left out by `when`): every match at the players' own levels", skipped or 0))
  end
  return count
end

local function describe()
  local parts = {}
  for _, r in pairs(RULES) do
    parts[#parts + 1] = string.format("%s = Nv. %d (%s, %s, %s)", pair_text(r.game, r.row), r.level,
      r.raise and "every player" or "players above it", r.saved_moves and "saved moves" or "moves of the level", r.key)
  end
  table.sort(parts)
  return table.concat(parts, "; ")
end

-- the rule of a request (most specific first), as the native answers pick it
local function rule_of(game, row)
  return RULES[game .. ":" .. row] or RULES[game .. ":0"] or RULES["0:" .. row]
end

local function request()
  if not BLOCK then return nil end
  local row, game = Memory.read("u8", BLOCK), Memory.read("u32", BLOCK + 4)
  if row == nil or game == nil then return nil end
  return row, game
end

-- forget the last request (no match is synced until the next request)
local function clear(why)
  local row, game = request()
  if row == nil or (row == 0 and game == 0) then return end
  VRFW.memory.write("u8", BLOCK, 0)
  VRFW.memory.write("u32", BLOCK + 4, 0)
  if rule_of(game, row) then info(string.format("%s: sync off (%s)", pair_text(game, row), why)) end
end

VRFW.on("match:start", function()
  if not LIVE then return end
  local row, game = request()
  local r = row ~= nil and rule_of(game, row)
  if r then
    info(string.format("this match (%s): the user's players play with the stats of Nv. %d%s (%s); moves and board of %s",
      pair_text(game, row), r.level, r.raise and "" or " (only the players above it)", r.key,
      r.saved_moves and "their saved cards" or "that level"))
  elseif row ~= nil then
    info(string.format("this match (request game %s, difficulty %d): no rule: the user's players play at their own levels",
      hex(game), row))
  else
    warn("this match: the request block is not readable: no level sync")
  end
end)

VRFW.on("match:end", function() clear("match end") end)
VRFW.on("game:reset", function() clear("title return") end)

local function start()
  if load_rules() == 0 then return end
  for _, r in pairs(RULES) do
    local names = { r.raise and TABLE_RAISE or TABLE_CAP }
    if not r.saved_moves then names[2] = r.raise and TABLE_CARD_RAISE or TABLE_CARD_CAP end
    for _, name in ipairs(names) do
      local ok, err = pcall(VRFW.native.table_set, name, { r.game, r.row }, r.level)
      if not ok then
        warn(string.format("table %s: %s not written (%s): no level sync", name, pair_text(r.game, r.row), tostring(err)))
        return
      end
    end
  end
  local block = VRFW.memory.buffer("level_sync_request", 16)
  local okb = block ~= nil
  if not okb or type(block) ~= "number" or not pcall(VRFW.state.set, STATE_KEY, block) then
    warn("the request block is not set up: no level sync")
    return
  end
  BLOCK = block
  for _, name in ipairs(HOOKS) do
    local ok, done, e = pcall(VRFW.hook.apply, name)
    if not (ok and done == true) then
      warn(string.format("detour %s not installed (%s): no level sync (%s)", name, tostring(ok and e or done), describe()))
      return
    end
  end
  for _, name in ipairs(SHOWN_HOOKS) do
    local ok, done, e = pcall(VRFW.hook.apply, name)
    if not (ok and done == true) then
      warn(string.format("detour %s not installed (%s): that level still shows the real number", name, tostring(ok and e or done)))
    end
  end
  LIVE = true
  info("on: " .. describe())
end

pcall(start)
