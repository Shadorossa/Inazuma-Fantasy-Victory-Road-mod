ClassicRecruitment = ClassicRecruitment or {}
local P = {}

local FOLDER = "content/friendly_zones"
local info, warn = VRFW.logger("friendly_zones")

local crc = VRFW.crc32
local TeamIds = VRFW.teams.ids

local ZONES = nil      -- { { name, node, title, stadium, game, music, friendlies = { … } } … }
local LEVEL = { scale = "data", min = 1, max = 200 }   -- zones.toml [ClassicRecruitment.FriendlyLevel]
local BASE = nil
local BY_NODE = {}     -- node name -> zone index
local BY_KEY = {}      -- friendly key -> friendly
local LIVE = nil       -- the armed friendly's match: { key, armed, result }
local PLAYED = nil     -- { key, won } until read

local function id_of(text) return VRFW.ids.parse(text) end

local function load_zones()
  if ZONES ~= nil then return ZONES end
  ZONES = {}
  local ok, files = pcall(VRFW.files.declarations, FOLDER)
  if not ok then
    warn("the friendly zones could not be read (" .. tostring(files) .. "): none")
    return ZONES
  end
  local by_zone, pending, music = {}, {}, {}
  for _, file in ipairs(type(files) == "table" and files or {}) do
    local root = type(file.data) == "table" and file.data.ClassicRecruitment or nil
    if type(root) == "table" then
      if type(root.FriendlyLevel) == "table" then
        local l = root.FriendlyLevel
        LEVEL = { scale = tostring(l.scale or "data"), min = math.floor(tonumber(l.min) or 1),
                  max = math.floor(tonumber(l.max) or 200) }
      end
      for _, z in ipairs(root.FriendlyZone or {}) do
        if type(z.name) == "string" and type(z.node) == "string" and by_zone[z.name] == nil then
          local zone = { name = z.name, node = z.node, title = crc(tostring(z.title or "")),
                         stadium = crc(tostring(z.stadium or "")), game = z.game, music = 0, friendlies = {} }
          ZONES[#ZONES + 1] = zone
          by_zone[z.name] = zone
          BY_NODE[z.node] = #ZONES
        end
      end
      for _, m in ipairs(root.FriendlyMusic or {}) do
        if type(m.game) == "string" and type(m.set) == "string" and music[m.game] == nil then
          music[m.game] = crc(m.set)
        end
      end
      for _, p in ipairs(root.Friendly or {}) do
        pending[#pending + 1] = { file = file, p = p }
      end
    end
  end
  for _, item in ipairs(pending) do
    local file, p = item.file, item.p
    local zone = by_zone[p.zone]
    if zone == nil or type(p.name) ~= "string" or type(p.team) ~= "string" then
      warn(string.format("mods/%s/%s: friendly %s: unknown zone %s or no team: left out", tostring(file.mod),
        tostring(file.file), tostring(p.name), tostring(p.zone)))
    else
      local cards = {}
      for _, c in ipairs(type(p.cards) == "table" and p.cards or {}) do
        local id = id_of(c)
        if id then cards[#cards + 1] = id end
      end
      local key = file.mod .. "." .. p.name
      local entry = { key = key, team = TeamIds.of(file.mod .. "." .. p.team) or crc(p.team), team_name = tostring(p.team_name or p.name),
                      level = math.floor(tonumber(p.level) or 1), format = tostring(p.format or "5v5"),
                      level_offset = math.floor(tonumber(p.level_offset) or 0), cards = cards }
      zone.friendlies[#zone.friendlies + 1] = entry
      BY_KEY[key] = entry
    end
  end
  local n = 0
  for _, z in ipairs(ZONES) do
    n = n + #z.friendlies
    z.music = music[z.game] or 0
  end
  info(string.format("%d zone(s), %d friendly(s)", #ZONES, n))
  return ZONES
end

local function level_of(p)
  local lv = p.level
  if LEVEL.scale == "team" and BASE ~= nil then
    lv = BASE + p.level_offset
  end
  return math.max(LEVEL.min, math.min(LEVEL.max, lv))
end

local function won(key)
  return VRFW.save.get("won." .. key, false) == true
end

function P.Zone(node)
  load_zones()
  local i = BY_NODE[tostring(node)]
  local z = i and ZONES[i]
  if not z then return nil end
  return i, z.title, z.stadium, #z.friendlies, z.music
end

function P.Get(zi, i)
  local z = load_zones()[math.floor(tonumber(zi) or 0)]
  local p = z and z.friendlies[math.floor(tonumber(i) or 0)]
  if not p then return nil end
  return p.key, p.team, p.team_name, level_of(p), p.format, won(p.key), #p.cards, table.unpack(p.cards)
end

local TEXT = {
  COUNT = crc("classic_recruitment_friendlies_count"), ROW = crc("classic_recruitment_friendlies_row"),
  INFO = crc("classic_recruitment_friendlies_info_5v5"), TAG = crc("classic_recruitment_friendlies_tag_5v5"),
}
function P.Menu(zi, i)
  local z = load_zones()[math.floor(tonumber(zi) or 0)]
  if not z then return nil end
  i = math.floor(tonumber(i) or 0)
  if i == 0 then
    return { title = z.title, count = #z.friendlies, info = { id = TEXT.COUNT, args = { #z.friendlies } } }
  end
  local p = z.friendlies[i]
  if not p then return nil end
  local models = {}
  for n, card in ipairs(p.cards) do
    models[n] = { card = card, plays = true, no_check = true, text = "" }
  end
  local lv = level_of(p)
  return { label = p.team_name, title = p.team_name, tag = TEXT.TAG, level = lv, done = won(p.key), team = p.team,
           sub = { id = TEXT.ROW, args = { lv } }, info = { id = TEXT.INFO, args = { lv } },
           lineup = #p.cards, models = models }
end

function P.Arm(key)
  load_zones()
  local p = BY_KEY[tostring(key)]
  if p == nil then return false end
  LIVE = { key = p.key, armed = true }
  PLAYED = nil
  info("armed " .. p.key)
  return true
end

VRFW.on("match:start", function(ev)
  if LIVE and LIVE.armed then
    LIVE.armed = false
  elseif LIVE then
    LIVE = nil
  end
  return nil
end)

VRFW.on("script:signal:vrfw.match_result", function()
  local last = VRFW.match.results.last()
  if type(last) ~= "table" then return nil end
  if LIVE and not LIVE.armed then
    LIVE.result = last
  elseif PLAYED then
    PLAYED.won = last.outcome == "win"
    info(string.format("%s judged: %s", PLAYED.key, tostring(last.outcome)))
  end
  return nil
end)

VRFW.on("match:end", function(ev)
  if not LIVE or LIVE.armed then return nil end
  PLAYED = { key = LIVE.key, won = LIVE.result ~= nil and LIVE.result.outcome == "win" }
  LIVE = nil
  return nil
end)

function P.Result()
  local r = PLAYED
  PLAYED = nil
  if not r then return nil end
  return r.key, r.won
end

function P.Won(key) return won(tostring(key)) end

function P.Base(level)
  load_zones()
  local lv = math.floor(tonumber(level) or 0)
  BASE = lv >= 1 and lv or nil
  return true
end

function P.Level(key)
  load_zones()
  local p = BY_KEY[tostring(key)]
  if not p then return nil end
  return level_of(p)
end

function P.SetWon(key)
  VRFW.save.set("won." .. tostring(key), true)
  return true
end

-- the commands (content\game\friendly_zones.toml)
ClassicRecruitment.FriendlyZone = P.Zone
ClassicRecruitment.FriendlyGet = P.Get
ClassicRecruitment.FriendlyArm = P.Arm
ClassicRecruitment.FriendlyResult = P.Result
ClassicRecruitment.FriendlyWon = P.Won
ClassicRecruitment.FriendlySetWon = P.SetWon
ClassicRecruitment.FriendlyMenu = P.Menu
ClassicRecruitment.FriendlyBase = P.Base
ClassicRecruitment.FriendlyLevel = P.Level

pcall(load_zones)
