
local U = require "lib/util"
local G = require "lib/game"
local TeamConfig = VRFW.teams.config
local Draft = require "draft"

local A = {}

local TABLE = "BattleBayDeluxe.ActiveTeam"

local info, warn = VRFW.logger("active team")

local TEAM_NAME = VRFW.strings.trim(tostring(U.config("active_team.team", "active_team")))

local TEAM_FILES = nil

local function find_key(name)
  if TEAM_FILES == nil then
    local ok, read = pcall(VRFW.files.declarations, "content/teams")
    TEAM_FILES = ok and type(read) == "table" and read or false
  end
  if not TEAM_FILES then
    return nil, "content\\teams not readable"
  end
  for _, e in ipairs(TEAM_FILES) do
    local teams = e.mod == VRFW.mod and type(e.data) == "table" and e.data.team
    if type(teams) == "table" then
      for _, t in ipairs(teams) do
        if type(t) == "table" and t.name == name then
          if type(t.key) ~= "string" then
            return nil, tostring(e.file) .. ": the team has no key"
          end
          return t.key
        end
      end
    end
  end
  return nil, 'no [[team]] name = "' .. name .. '" in content\\teams'
end

local KEY, KEY_ERR = find_key(TEAM_NAME)
local TEAM = KEY and VRFW.crc32(KEY) or 0

if TEAM == 0 then
  warn("off (" .. tostring(KEY_ERR) .. "): the Active team tile plays its placeholder players")
elseif not VRFW.is_on("StartMatchRequest") then
  warn(string.format("team %s = %s (%s), but the hook StartMatchRequest is off: the tile would play its placeholder " ..
    "players, so it is refused", TEAM_NAME, KEY, U.hex(TEAM)))
else
  local ok, e = pcall(VRFW.native.table_set, TABLE, TEAM, 1)
  if ok then
    info(string.format("team %s = %s (%s): its matches play the player's active team", TEAM_NAME, KEY, U.hex(TEAM)))
  else
    warn("the hook's table not written (" .. tostring(e) .. "): the tile is refused")
    TEAM = 0
  end
end

-- team id -> team set of each Personal Teams tile (config.toml [active_team] dock_tiles)
local DOCK_OF = {}
local DOCK_READY = {}
local DOCK_LIST = {}

if TEAM ~= 0 then
  for name, dock in pairs(U.config("active_team.dock_tiles", {})) do
    local key, why = find_key(name)
    local team = key and VRFW.crc32(key) or 0
    if team ~= 0 and pcall(VRFW.native.table_set, TABLE, team, 1)
      and pcall(VRFW.native.table_set, "BattleBayDeluxe.ActiveSet", team, dock) then
      DOCK_OF[team] = dock
      DOCK_LIST[#DOCK_LIST + 1] = string.format("%.0f:%d", team, dock)
    else
      warn("Personal Teams tile " .. tostring(name) .. " is off: " .. tostring(why or "the hook's tables not written"))
    end
  end
  table.sort(DOCK_LIST)
end

function A.team()
  return TEAM
end

-- True for the Active team tile and every Personal Teams tile.
function A.is_tile(team)
  return team ~= 0 and (team == TEAM or DOCK_OF[team] ~= nil)
end

-- The last seen state of a Personal Teams tile's dock: true = 11 starters, false = not, nil = not such a tile or not read yet.
function A.dock_ready(team)
  return DOCK_READY[team]
end

-- CMND_BATTLEBAYDELUXE_PERSONAL_DOCKS -> "team:dock,..."
function BattleBayDeluxe.PersonalDocks()
  return table.concat(DOCK_LIST, ",")
end

-- CMND_BATTLEBAYDELUXE_PERSONAL_DOCK_READY (team, 1 = 11 starters)
function BattleBayDeluxe.PersonalDockReady(team, ready)
  team = U.u32(tonumber(team) or 0) or 0
  if DOCK_OF[team] == nil then
    return false
  end
  DOCK_READY[team] = U.int(ready, 0) ~= 0
  return true
end

-- each tile's own placeholder of its member places (team -> slot -> chara_param), as first seen this session
local PLACEHOLDER = {}
local DRAFT_UNCHANGED = "Draft crest and kit unchanged, Draft name unchanged"

-- "position:param,…" -> { [position] = param }
local function parse_lineup(text)
  local out = {}
  for pos, param in string.gmatch(tostring(text or ""), "(%d+):(%d+)") do
    local p, id = tonumber(pos), U.u32(tonumber(param))
    if p and id and id ~= 0 then
      out[p] = id
    end
  end
  return out
end

local function leader_of(final, captain)
  local first
  for slot, id in pairs(final) do
    if captain ~= 0 and id == captain then
      return id, "captain"
    end
    if first == nil or slot < first then
      first = slot
    end
  end
  if final[0] then
    return final[0], "place 0"
  end
  return first and final[first], "first place"
end

local ACTIVE_SET = nil

local function write_look(team, label, emblem, uniform)
  if emblem == 0 and uniform == 0 then
    return "no emblem / kit to write"
  end
  local rec, why = TeamConfig.find(team or TEAM)
  local r = rec and U.struct("ActiveTeamRecord", rec)
  if not r then
    warn("mirror: the " .. label .. "'s team record not read: " .. tostring(why or "struct off"))
    return label .. " team record not read"
  end
  local done = {}
  for _, f in ipairs({ { "emblem", emblem }, { "uniform", uniform } }) do
    local field, value = f[1], f[2]
    if value ~= 0 and U.get(r, field) ~= value then
      if pcall(function()
        r[field] = value
      end) then
        done[#done + 1] = field .. " " .. U.hex(value)
      else
        warn("mirror: the " .. label .. "'s " .. field .. " NOT written")
      end
    end
  end
  if #done == 0 then
    return label .. " crest and kit unchanged"
  end
  return label .. " " .. table.concat(done, ", ")
end

local NAME_TABLE = "BattleBayDeluxe.TeamName"
local NAME_BLOCK, NAME_BYTES = "bbd_active_team_name", 128
local name_written = nil

local function utf8_cut(text, max)
  if #text <= max then
    return text
  end
  local n = max
  while n > 0 do
    local b = text:byte(n + 1)
    if b == nil or b < 0x80 or b >= 0xC0 then
      break
    end
    n = n - 1
  end
  return text:sub(1, n)
end

-- the active team's name as the match name of `team` -> note
local function write_name(team, name)
  if type(name) ~= "string" or name == "" then
    return "no team name to write"
  end
  if not VRFW.is_on("TeamLookBuild") then
    return "name: the hook TeamLookBuild is off"
  end
  name = utf8_cut(name, NAME_BYTES - 1)
  if name_written == name then
    return "name unchanged"
  end
  local block = VRFW.memory.buffer(NAME_BLOCK, NAME_BYTES)
  local okb = block ~= nil
  if not okb or type(block) ~= "number" or block == 0 then
    warn("mirror: no native block for the team name")
    return "name NOT written"
  end
  local bytes = { name:byte(1, -1) }
  bytes[#bytes + 1] = 0
  local written = VRFW.memory.write_array("u8", block, bytes)
  local okw = written ~= nil
  if not okw or written == false then
    warn("mirror: the team name NOT written")
    return "name NOT written"
  end
  if not pcall(VRFW.native.table_set, NAME_TABLE, team, block) then
    warn("mirror: the team name table NOT written")
    return "name NOT written"
  end
  name_written = name
  return "name «" .. name .. "»"
end

-- the active team's kit and name onto the Draft team -> note
local function write_draft_identity(uniform, name)
  local draft = Draft.team()
  if draft == 0 then
    return "no Draft team"
  end
  return write_look(draft, "Draft", 0, uniform) .. ", Draft " .. write_name(draft, name)
end

-- `tile` (optional): the Personal Teams tile to mirror onto; none = the Active team tile.
function BattleBayDeluxe.ActiveTeamMirror(captain, lineup, set, emblem, uniform, name, tile)
  local dock_tile = U.u32(tonumber(tile) or 0) or 0
  local team = dock_tile ~= 0 and dock_tile or TEAM
  if team == 0 then
    return false, "no Active team tile"
  end
  if dock_tile ~= 0 and DOCK_OF[dock_tile] == nil then
    return false, "not a Personal Teams tile"
  end
  set = tonumber(set)
  if dock_tile == 0 and set and set >= 0 and set < 16 then
    ACTIVE_SET = math.floor(set)
    pcall(VRFW.native.table_set, "BattleBayDeluxe.ActiveSet", TEAM, ACTIVE_SET)
  end
  emblem, uniform = U.u32(tonumber(emblem) or 0) or 0, U.u32(tonumber(uniform) or 0) or 0
  local look = write_look(team, "tile", emblem, uniform)
  local draft_look = dock_tile ~= 0 and DRAFT_UNCHANGED or write_draft_identity(uniform, name)
  captain = U.u32(tonumber(captain) or 0) or 0
  local want = parse_lineup(lineup)
  if next(want) == nil then
    return false, "empty line-up"
  end
  local rows, why = Draft.member_rows(team)
  if not rows then
    warn("mirror: the tile's member rows not read: " .. tostring(why))
    return false, "member rows: " .. tostring(why)
  end
  local used = {}
  for _, id in pairs(want) do
    used[id] = true
  end
  PLACEHOLDER[team] = PLACEHOLDER[team] or {}
  local holders = PLACEHOLDER[team]
  for _, r in ipairs(rows) do
    if holders[r.slot] == nil then
      holders[r.slot] = r.param
    end
  end
  local spare = {}
  for _, id in pairs(holders) do
    if id ~= 0 and not used[id] then
      spare[#spare + 1] = id
    end
  end
  table.sort(spare)
  local final, written, empty = {}, 0, 0
  for _, r in ipairs(rows) do
    local to = want[r.slot]
    if to == nil then
      empty = empty + 1
      to = holders[r.slot]
      if used[to] then
        to = table.remove(spare, 1) or to
      end
    end
    used[to] = true
    final[r.slot] = to
    if to ~= 0 and (r.param ~= to or r.uid ~= to) then
      if not Draft.write_member(r, to) then
        warn(string.format("mirror: member row of place %d NOT written", r.slot))
        return false, "a member row not written"
      end
      written = written + 1
    end
  end
  local lead, lead_why = leader_of(final, captain)
  local leader_note = "leader unchanged"
  local row = lead and G.enjoy_row(team)
  local er = row and U.struct("EnjoyRow", row)
  if er then
    local old = U.get(er, "leader") or 0
    if old ~= lead then
      if pcall(function()
        er.leader = lead
      end) then
        leader_note = string.format("leader %s -> %s (%s)", U.hex(old), U.hex(lead), lead_why)
      else
        leader_note = "leader NOT written"
        warn("mirror: the tile's row leader NOT written (" .. U.hex(old) .. " stays)")
      end
    end
  elseif lead then
    leader_note = "no Battle Bay row of the tile in memory (leader not written)"
  end
  local note = string.format("%d of %d member rows written, %d place(s) the active team leaves empty, %s, %s, %s, team set %s",
    written, #rows, empty, leader_note, look, draft_look, tostring(ACTIVE_SET))
  if written > 0 or leader_note ~= "leader unchanged" or look ~= "tile crest and kit unchanged"
    or draft_look ~= DRAFT_UNCHANGED then
    info("mirror: the active team onto the tile: " .. note)
  end
  return true, note
end

local REQUEST_EXPLICIT, REQUEST_PLAYER, REQUEST_RIVAL = G.REQUEST_EXPLICIT, G.REQUEST_PLAYER, G.REQUEST_RIVAL
local REQUEST_TEAM_SET = 0xC0
local REQUEST_GAME, REQUEST_DIFFICULTY = 0x6C, 0x7D
local PARTY_VS_SET, PARTY_VS_SET_STORY, SESSION_PLAY_MODE = 0x9F10, 0x9F13, 0x2CAC6F

local SYNC_TABLE = "BattleBayDeluxe.LevelSync"
local LEVEL_SYNC = U.int(U.config("active_team.level_sync", 40), 40)
local sync_on = false

-- the active VS team set read from the party block (the mirror's when unreadable), nil when none
local function active_set()
  local party = U.global("active_team_party")
  local session = U.global("session")
  if party then
    local mode = session and U.rd("u8", session + SESSION_PLAY_MODE)
    local set = U.rd("u8", party + (mode == 2 and PARTY_VS_SET_STORY or PARTY_VS_SET))
    if set and set < 16 then
      return set
    end
  end
  return ACTIVE_SET
end

-- the level sync of the next match's stats (0 / nil = none)
local function set_sync(level)
  local on = level ~= nil and level > 0
  if on == sync_on then
    return
  end
  local ok = pcall(VRFW.native.table_set, SYNC_TABLE, 0, on and level or nil)
  if ok then
    sync_on = on
    info(on and string.format("level sync %d for the active team's match stats", level) or "level sync off")
  else
    warn("level sync table not written")
  end
end

local REQUEST_MARK_KEY = "BattleBayDeluxe.active_team.request_mark"
local REQUEST_TILE_KEY = "BattleBayDeluxe.active_team.request_tile"
local request_mark, request_tile = nil, nil

local function is_tile_request(req, player)
  if A.is_tile(player) then
    return true
  end
  return request_mark ~= nil and U.rd("ptr", request_mark) == req
end

if TEAM ~= 0 then
  local block = VRFW.memory.buffer("bbd_active_request_mark", 8)
  local okb = block ~= nil
  if okb and type(block) == "number" and pcall(VRFW.state.set, REQUEST_MARK_KEY, block) then
    request_mark = block
  else
    warn("the request mark is not set up: the active team's team set and level sync only apply to a request the " ..
      "native answer did not turn")
  end
  local tile_block = VRFW.memory.buffer("bbd_active_request_tile", 8)
  if type(tile_block) == "number" and pcall(VRFW.state.set, REQUEST_TILE_KEY, tile_block) then
    request_tile = tile_block
  else
    warn("the request's tile is not recorded: a Personal Teams tile turned by the native answer plays the active team set")
  end

  VRFW.on("game_reset", function()
    set_sync(nil)
  end)

  VRFW.on("hook:StartMatchRequest", function(ev)
    local req = ev.args and ev.args[2]
    if type(req) ~= "number" or req < 0x10000 then
      set_sync(nil)
      return nil
    end
    local explicit = U.rd("u8", req + REQUEST_EXPLICIT)
    local player = U.rd("u32", req + REQUEST_PLAYER)
    local rival = U.rd("u32", req + REQUEST_RIVAL)
    if not is_tile_request(req, player) then
      info(string.format("match request: not the Active team tile (player's team %s, explicit flag %s, game %s, marked %s): " ..
        "no level sync from the tile", U.hex(player or 0), tostring(explicit), U.hex(U.rd("u32", req + REQUEST_GAME) or 0),
        tostring(request_mark ~= nil and U.rd("ptr", request_mark) == req)))
      set_sync(nil)
      return nil
    end
    info(string.format("match request: the Active team tile (player's team %s, game %s, difficulty %s): stats synced to Nv. %d",
      U.hex(player or 0), U.hex(U.rd("u32", req + REQUEST_GAME) or 0), tostring(U.rd("u8", req + REQUEST_DIFFICULTY)), LEVEL_SYNC))
    local tile = player ~= 0 and player or (request_tile and U.rd("u32", request_tile)) or 0
    local set = DOCK_OF[tile] or active_set()
    local had = U.rd("u8", req + REQUEST_TEAM_SET)
    if set == nil then
      warn("match request: the active team set is unknown: the request keeps team set " .. tostring(had))
    elseif had ~= set then
      if U.wr("u8", req + REQUEST_TEAM_SET, set) then
        info(string.format("match request: team set %s -> %d (the active VS team set)", tostring(had), set))
      else
        warn("match request: the team set NOT written (" .. tostring(had) .. " stays)")
      end
    end
    set_sync(LEVEL_SYNC)
    if A.is_tile(player) then
      if U.wr("u32", req + REQUEST_PLAYER, 0) then
        info(string.format("match request: the tile %s as the player's team with explicit flag %s: turned into the " ..
          "active team set here (the native answer did not)", U.hex(player), tostring(explicit)))
      else
        warn("match request: the tile as the player's team NOT turned into the active team set (write failed)")
      end
    elseif player == 0 then
      info(string.format("match request: the tile turned natively into the active team set (player's team 0), rival %s",
        U.hex(rival or 0)))
    end
    return nil
  end)
end

-- The tile plays the active team (the hook is on and its table holds the tile).
function A.playable()
  return TEAM ~= 0 and VRFW.is_on("StartMatchRequest")
end

function A.refusal(campaign, player_one_decided, network)
  if not A.playable() then
    return "the hook StartMatchRequest is off (the tile would play its placeholder players)"
  end
  if network then
    return "network session (the other player builds this side from the tile's own team)"
  end
  if not campaign and player_one_decided then
    return "the rival side (only the player's side plays the active team)"
  end
  return nil
end

return A
