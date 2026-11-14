
local U = require "lib/util"
local G = require "lib/game"
local Block = require "lib/campaign_block"
local Draft = require "draft"
local Active = require "active_team"
local TeamConfig = VRFW.teams.config

local N = {}

local BLOB = "bb_net_campaign.json"

local info, warn = VRFW.logger("net")

local CFG = {
  game = VRFW.ids.unsigned(tonumber(U.config("net.game", 0x8F85B173)) or 0x8F85B173),
  difficulty = math.max(0, math.min(3, U.int(tonumber(U.config("net.difficulty", 1)), 1))),
}

local PICK = { armed = false, team = 0 }

-- The two room teams: side 0 plays the host's payload, side 1 the guest's, on both PCs (content\teams\224_net_room.toml).
local SIDES = {
  { name = tostring(U.config("net.side_0_team", "net_side_0")), who = "host", block = "bbd_net_side_0_name" },
  { name = tostring(U.config("net.side_1_team", "net_side_1")), who = "guest", block = "bbd_net_side_1_name" },
}

-- team -> slot -> { param, loadout } of its declared rows, as first read this session
local PLACEHOLDER = {}
-- team -> { emblem, uniform } of its declared record, as first read this session
local DECLARED_LOOK = {}

-- The team id of a room team's declaration in this mod's content\teams; 0, why when it is missing.
local function side_team(side)
  if side.team ~= nil then
    return side.team, side.why
  end
  local ok, files = pcall(VRFW.files.declarations, "content/teams")
  side.team, side.why = 0, 'no [[team]] name = "' .. side.name .. '" in content\\teams'
  for _, e in ipairs(ok and type(files) == "table" and files or {}) do
    for _, t in ipairs(e.mod == VRFW.mod and type(e.data) == "table" and type(e.data.team) == "table" and e.data.team or {}) do
      if type(t) == "table" and t.name == side.name and type(t.key) == "string" then
        side.team, side.why = VRFW.crc32(t.key), nil
      end
    end
  end
  return side.team, side.why
end

-- The payload of team `team` as it is in memory now: its record's formation, crest and kit, its grid row's leader, the
-- name a tile mirrors, and every member row (slot, chara_param, move loadout).
local function team_payload(team)
  local rows, why = Draft.member_rows(team)
  if not rows then
    return nil, "member rows: " .. tostring(why)
  end
  local out = { team = team, members = {}, name = Active.name_of(team) or "" }
  local tr = rows.rec and VRFW.memory.struct("TeamRecord", rows.rec)
  out.formation = U.get(tr, "formation") or 0
  local rec = TeamConfig.find(team)
  local look = rec and VRFW.memory.struct("ActiveTeamRecord", rec)
  out.emblem, out.uniform = U.get(look, "emblem") or 0, U.get(look, "uniform") or 0
  local row = G.enjoy_row(team)
  out.captain = row and U.get(VRFW.memory.struct("EnjoyRow", row), "leader") or 0
  -- a tile's rows hold the active team's characters over the placeholders' move loadouts: those play their own moves
  local own_moves = Active.is_tile(team)
  for _, r in ipairs(rows) do
    out.members[#out.members + 1] = { slot = r.slot, param = r.param, loadout = own_moves and 0 or (r.loadout or 0) }
  end
  if out.formation == 0 or #out.members == 0 then
    return nil, "the team has no formation or no member rows"
  end
  return out
end

function BattleBayDeluxe.NetPickArm(on)
  PICK.armed = U.int(on, 0) ~= 0
  if PICK.armed then
    PICK.team = 0
  end
  info("room pick " .. (PICK.armed and "armed" or "off"))
  return true
end

function BattleBayDeluxe.NetPicked()
  return PICK.team
end

function N.decide(menu, btn, idx)
  if not PICK.armed or VRFW.memory.read("u32", btn) ~= G.GRID_LAYER then
    return nil
  end
  local s = VRFW.memory.struct("GridSlot", G.slot_addr(menu, idx))
  local team, unlocked = U.get(s, "team"), U.get(s, "unlocked")
  if not team or team == 0 or unlocked == 0 then
    info("room pick: slot " .. tostring(idx) .. " has no playable team")
    return { skip = true, ret = 0 }
  end
  local payload, why = team_payload(team)
  if not payload then
    warn("room pick: " .. VRFW.ids.hex_text(team) .. " not sent: its team payload is not readable (" .. tostring(why) .. ")")
    return { skip = true, ret = 0 }
  end
  local ok, r = pcall(VRFW.net.pick, team)
  if not ok or type(r) ~= "table" or not r.ok then
    warn("room pick: not sent (" .. tostring(ok and r and r.error or r) .. ")")
    return { skip = true, ret = 0 }
  end
  local sent, err = VRFW.net_team.send(payload)
  if not sent then
    warn("room pick: " .. VRFW.ids.hex_text(team) .. " picked, but its team payload is not sent (" .. tostring(err) .. "): the host cannot start")
    return { skip = true, ret = 0 }
  end
  PICK.team, PICK.armed = team, false
  info("room pick: " .. VRFW.ids.hex_text(team) .. " (slot " .. tostring(idx) .. "), its team payload sent")
  return { skip = true, ret = 0 }
end

-- Writes the payload `p` onto room team `team`: every member row by slot (a slot the payload leaves out keeps its
-- placeholder, a placeholder the payload already fields gives way to the next unused one), the formation, crest, kit
-- and name. Both PCs write the same payload onto the same declared rows, so both build the same team.
local function write_side(team, p, label, block)
  local rows, why = Draft.member_rows(team)
  if not rows then
    return false, "member rows: " .. tostring(why)
  end
  PLACEHOLDER[team] = PLACEHOLDER[team] or {}
  local holders = PLACEHOLDER[team]
  for _, r in ipairs(rows) do
    if holders[r.slot] == nil then
      holders[r.slot] = { param = r.param, loadout = r.loadout or 0 }
    end
  end
  local want, used = {}, {}
  for _, m in ipairs(p.members) do
    want[m.slot] = m
    used[m.param] = true
  end
  local spare = {}
  for slot, h in pairs(holders) do
    if not used[h.param] then
      spare[#spare + 1] = { slot = slot, param = h.param, loadout = h.loadout }
    end
  end
  table.sort(spare, function(a, b)
    return a.slot < b.slot
  end)
  local fielded, left = 0, 0
  for _, r in ipairs(rows) do
    local to = want[r.slot]
    if to then
      fielded = fielded + 1
      want[r.slot] = nil
    else
      to = holders[r.slot]
      if used[to.param] then
        to = table.remove(spare, 1) or to
      end
    end
    used[to.param] = true
    local m = VRFW.memory.struct("MemberRow", r.addr)
    local ok = m and pcall(function()
      m.param, m.uid, m.loadout = to.param, to.param, to.loadout
    end)
    if not ok then
      return false, "the member row of slot " .. tostring(r.slot) .. " not written"
    end
  end
  for slot in pairs(want) do
    left = left + 1
    warn(string.format("room team %s: the payload's slot %d has no member row here (left out)", label, slot))
  end
  local tr = rows.rec and VRFW.memory.struct("TeamRecord", rows.rec)
  if not tr or not pcall(function()
    tr.formation = p.formation
  end) then
    return false, "the formation not written"
  end
  -- a crest, kit or name the payload leaves out is the declared one, never the one an earlier room match wrote here
  local rec = TeamConfig.find(team)
  local cur = rec and VRFW.memory.struct("ActiveTeamRecord", rec)
  DECLARED_LOOK[team] = DECLARED_LOOK[team] or { emblem = U.get(cur, "emblem") or 0, uniform = U.get(cur, "uniform") or 0 }
  local d = DECLARED_LOOK[team]
  local look = Active.write_look(team, label, (p.emblem or 0) ~= 0 and p.emblem or d.emblem,
    (p.uniform or 0) ~= 0 and p.uniform or d.uniform)
  local name = (type(p.name) == "string" and p.name ~= "") and Active.write_name(team, p.name, block) or Active.clear_name(team)
  return true, string.format("%d payload member(s) fielded, %d left out, formation %s, %s, %s", fielded, left,
    VRFW.ids.hex_text(p.formation), look, name)
end

function BattleBayDeluxe.NetRestore()
  return Block.restore(BLOB)
end

-- The room's match: side 0 = the host's team payload, side 1 = the guest's, built alike on both PCs. The picked team
-- ids only name the picks in the log; a missing payload stops the match instead of playing other teams.
function BattleBayDeluxe.NetPrepare(host_team, guest_team)
  host_team, guest_team = VRFW.ids.unsigned(host_team), VRFW.ids.unsigned(guest_team)
  local teams = {}
  for i, side in ipairs(SIDES) do
    local team, why = side_team(side)
    if team == 0 then
      warn("match not prepared: room team " .. side.name .. ": " .. tostring(why))
      return false
    end
    local p, perr = VRFW.net_team.of(side.who)
    if not p then
      warn("match not prepared: the " .. side.who .. "'s team payload: " .. tostring(perr))
      return false
    end
    teams[i] = { team = team, payload = p }
  end
  if not Block.session() then
    warn("match not prepared: the session block is not readable")
    return false
  end
  for i, side in ipairs(SIDES) do
    local t = teams[i]
    local ok, note = write_side(t.team, t.payload, side.name, side.block)
    if not ok then
      warn("match not prepared: room team " .. side.name .. " (the " .. side.who .. "'s): " .. tostring(note))
      return false
    end
    info(string.format("room team %s = the %s's pick %s: %s", side.name, side.who, VRFW.ids.hex_text(t.payload.team or 0), note))
    VRFW.net_team.apply(i - 1, t.payload)
  end
  if not Block.kept(BLOB) and not Block.snapshot(BLOB) then
    return false
  end
  if not Block.write(CFG.game, CFG.difficulty, teams[1].team, { teams[2].team }, 0) then
    warn("the room's match was not written into the Campaña's block")
    BattleBayDeluxe.NetRestore()
    return false
  end
  info(string.format("room match: %s (the host's pick %s, team 0) vs %s (the guest's pick %s, team 1), game %s, difficulty %d",
    VRFW.ids.hex_text(teams[1].team), VRFW.ids.hex_text(host_team), VRFW.ids.hex_text(teams[2].team), VRFW.ids.hex_text(guest_team), VRFW.ids.hex_text(CFG.game), CFG.difficulty))
  return true
end

function BattleBayDeluxe.NetTeam(team)
  team = VRFW.ids.unsigned(team)
  if team == 0 then
    return 0, 0, 0
  end
  local rows = G.enjoy_rows and G.enjoy_rows() or nil
  for _, r in ipairs(type(rows) == "table" and rows or {}) do
    if r.team == team then
      local er = VRFW.memory.struct("EnjoyRow", r.addr)
      return U.get(er, "leader") or 0, 0, 0
    end
  end
  return 0, 0, 0
end

VRFW.on("save:slot_load", function()
  if Block.kept(BLOB) then
    pcall(BattleBayDeluxe.NetRestore)
  end
  return nil
end)

return N
