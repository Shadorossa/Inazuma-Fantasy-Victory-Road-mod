
local U = require "lib/util"
local TeamConfig = VRFW.teams.config
local Draft = require "draft"

local L = {}

local info, warn = VRFW.logger("league squad")

L.LAST_SLOT = 18
L.COACH_SLOT = 19
L.STARTERS = 11

local ORIGINAL = {}

-- the formation of a team's record in memory (0 = unreadable)
function L.formation(team)
  local rec = TeamConfig.find(team)
  local r = rec and U.struct("LeagueTeamRecord", rec)
  return U.u32(U.get(r, "formation") or 0)
end

function L.record(team)
  local rec = TeamConfig.find(team)
  local r = rec and U.struct("LeagueTeamRecord", rec)
  local out = { kit = U.u32(U.get(r, "kit") or 0), emblem = U.u32(U.get(r, "emblem") or 0), coach = 0 }
  for _, m in ipairs(Draft.member_rows(team) or {}) do
    if m.slot == L.COACH_SLOT and (m.param or 0) ~= 0 then
      out.coach = U.u32(m.param)
    end
  end
  return out
end

local function set_formation(team, formation)
  local rec, why = TeamConfig.find(team)
  local r = rec and U.struct("LeagueTeamRecord", rec)
  if not r then
    return false, why or "struct off"
  end
  if U.u32(U.get(r, "formation") or 0) == formation then
    return true
  end
  return (pcall(function()
    r.formation = formation
  end))
end

local function player_rows(team)
  local rows, why = Draft.member_rows(team)
  if not rows then
    return nil, why
  end
  local out = {}
  for _, r in ipairs(rows) do
    if r.slot <= L.LAST_SLOT and r.param ~= 0 then
      out[#out + 1] = r
    end
  end
  table.sort(out, function(a, b)
    return a.slot < b.slot
  end)
  return out
end

local function remember(team, rows)
  if ORIGINAL[team] then
    return
  end
  local order = {}
  for _, r in ipairs(rows) do
    order[r.slot] = r.param
  end
  ORIGINAL[team] = { order = order, formation = L.formation(team) }
end

-- "slot:param,…" <-> { [slot] = param }
function L.encode(order)
  local parts = {}
  for slot = 0, L.LAST_SLOT do
    if order[slot] then
      parts[#parts + 1] = slot .. ":" .. U.u32(order[slot])
    end
  end
  return table.concat(parts, ",")
end

function L.decode(text)
  local out = {}
  for slot, param in string.gmatch(tostring(text or ""), "(%d+):(%d+)") do
    out[tonumber(slot)] = U.u32(tonumber(param))
  end
  return out
end

function L.members(team)
  local rows, why = player_rows(team)
  if not rows then
    return nil, why
  end
  remember(team, rows)
  local out = {}
  for _, r in ipairs(rows) do
    out[#out + 1] = { r.slot, r.param }
  end
  return out
end

function L.from_dock(team, placed)
  local rows, why = player_rows(team)
  if not rows then
    return nil, why
  end
  remember(team, rows)
  local in_team, at = {}, {}
  for _, r in ipairs(rows) do
    in_team[r.param] = r.slot
  end
  for _, m in ipairs(type(placed) == "table" and placed or {}) do
    local position, param = U.int(m[1], -1), U.u32(m[2] or 0)
    if in_team[param] == nil then
      return nil, "card " .. U.hex(param) .. " is not a player of the team"
    end
    if at[param] then
      return nil, "card " .. U.hex(param) .. " placed twice"
    end
    at[param] = position
  end
  local order, starters, bench, rest = {}, 0, {}, {}
  for _, r in ipairs(rows) do
    if r.slot < L.STARTERS then
      starters = starters + 1
    end
  end
  for param, position in pairs(at) do
    if position >= 0 and position < L.STARTERS then
      order[position] = param
    end
  end
  for slot = 0, L.STARTERS - 1 do
    local had = false
    for _, r in ipairs(rows) do
      if r.slot == slot then
        had = true
      end
    end
    if had and not order[slot] then
      return nil, "starter place " .. slot .. " has no player of the team"
    end
    if not had and order[slot] then
      return nil, "starter place " .. slot .. " is not a slot of the team"
    end
  end
  local starters_set = {}
  for slot = 0, L.STARTERS - 1 do
    if order[slot] then
      starters_set[order[slot]] = true
    end
  end
  for _, r in ipairs(rows) do
    if not starters_set[r.param] then
      local position = at[r.param]
      if position and position >= L.STARTERS then
        bench[#bench + 1] = { key = position, param = r.param }
      else
        rest[#rest + 1] = { key = 100 + r.slot, param = r.param }
      end
    end
  end
  for _, x in ipairs(rest) do
    bench[#bench + 1] = x
  end
  table.sort(bench, function(a, b)
    return a.key < b.key
  end)
  local k = 1
  for _, r in ipairs(rows) do
    if r.slot >= L.STARTERS then
      local x = bench[k]
      if not x then
        return nil, "fewer bench players than bench slots"
      end
      order[r.slot] = x.param
      k = k + 1
    end
  end
  if starters ~= L.STARTERS then
    warn(string.format("team %s has %d starter slots", U.hex(team), starters))
  end
  return order
end

function L.apply(team, order, formation)
  local rows, why = player_rows(team)
  if not rows then
    return nil, why
  end
  remember(team, rows)
  local have, used = {}, {}
  for _, r in ipairs(rows) do
    if have[r.param] then
      return nil, "two rows hold card " .. U.hex(r.param)
    end
    have[r.param] = { uid = r.uid, loadout = r.loadout }
  end
  for _, r in ipairs(rows) do
    local param = order[r.slot]
    if not param or not have[param] then
      return nil, "slot " .. r.slot .. ": no player of the team"
    end
    if used[param] then
      return nil, "card " .. U.hex(param) .. " on two slots"
    end
    used[param] = true
  end
  local changed = 0
  for _, r in ipairs(rows) do
    local param = order[r.slot]
    if r.param ~= param then
      local m = U.struct("MemberRow", r.addr)
      local src = have[param]
      local ok = m ~= nil and pcall(function()
        m.param = param
        m.uid = src.uid
        if type(src.loadout) == "number" then
          m.loadout = src.loadout
        end
      end)
      if not ok then
        return nil, "slot " .. r.slot .. ": row not written"
      end
      changed = changed + 1
    end
  end
  if U.u32(formation or 0) ~= 0 then
    local okf, e = set_formation(team, U.u32(formation))
    if not okf then
      warn(string.format("team %s: formation %s not written (%s)", U.hex(team), U.hex(formation), tostring(e)))
    end
  end
  return changed
end

function L.ensure(lineup)
  local team = type(lineup) == "table" and U.u32(lineup.team or 0) or 0
  for t, orig in pairs(ORIGINAL) do
    if t ~= team then
      local n, why = L.apply(t, orig.order, orig.formation)
      if n == nil then
        warn(string.format("team %s: first order not put back (%s)", U.hex(t), tostring(why)))
      elseif n > 0 then
        info(string.format("team %s: first order back (%d rows)", U.hex(t), n))
      end
      ORIGINAL[t] = nil
    end
  end
  if team == 0 then
    return true
  end
  local n, why = L.apply(team, L.decode(lineup.order), U.u32(lineup.formation or 0))
  if n == nil then
    warn(string.format("team %s: the league lineup not written (%s)", U.hex(team), tostring(why)))
    return false
  end
  if n > 0 then
    info(string.format("team %s: league lineup written (%d rows, formation %s)", U.hex(team), n,
      U.hex(lineup.formation or 0)))
  end
  return true
end

return L
