-- Advanced: Room team payloads: the versioned text each player sends after his pick, from which both PCs build the same two match teams (docs/framework/online.md).

local M = {}

-- Internal: The payload's format version: a payload of another version is refused, never guessed.
M.VERSION = 1

local HEADER = "VRFWTEAM"

local info, warn = VRFW.logger("net team")

-- Registered per-player fields: key -> { collect = function(member, team) -> value | nil, apply = function(side, member, value, team) }.
local FIELDS = {}

-- A text as one token: never empty, no space, no line break.
local function pack_text(text)
  return "s" .. tostring(text or ""):gsub("[^%w%-_~]", function(c)
    return string.format("%%%02X", c:byte())
  end)
end

local function unpack_text(token)
  if type(token) ~= "string" or token:sub(1, 1) ~= "s" then
    return nil
  end
  return (token:sub(2):gsub("%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end))
end

local function number_text(v)
  return string.format("%.0f", VRFW.ids.unsigned(v) or 0)
end

-- Internal: Registers a mod's per-player field: `key` = "<Mod>.<name>"; `spec.collect(member, team)` gives the value to send
-- (a string or number, nil = none); `spec.apply(side, member, value, team)` uses it on both PCs before the match is built.
function M.field(key, spec)
  if type(key) ~= "string" or not key:find(".", 1, true) or type(spec) ~= "table" then
    return false, "a field needs a key <Mod>.<name> and a spec table"
  end
  if type(spec.collect) ~= "function" or type(spec.apply) ~= "function" then
    return false, "a field needs collect and apply functions"
  end
  FIELDS[key] = { collect = spec.collect, apply = spec.apply }
  return true
end

-- The registered field keys in one order, so both PCs apply them alike.
local function field_keys()
  local keys = {}
  for k in pairs(FIELDS) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

-- Internal: Adds every registered field's value to each member of `team` (members[i].fields[key]).
function M.collect(team)
  for _, key in ipairs(field_keys()) do
    for _, m in ipairs(team.members or {}) do
      local ok, v = pcall(FIELDS[key].collect, m, team)
      if not ok then
        warn("field " .. key .. ": collect failed for slot " .. tostring(m.slot) .. ": " .. tostring(v))
      elseif v ~= nil then
        m.fields = m.fields or {}
        m.fields[key] = tostring(v)
      end
    end
  end
  return team
end

-- Advanced: Calls every registered field's apply for the members of `team` that carry it; side 0 = the host's team, 1 = the guest's.
function M.apply(side, team)
  for _, key in ipairs(field_keys()) do
    for _, m in ipairs(team.members or {}) do
      local v = m.fields and m.fields[key]
      if v ~= nil then
        local ok, e = pcall(FIELDS[key].apply, side, m, v, team)
        if not ok then
          warn("field " .. key .. ": apply failed for side " .. tostring(side) .. " slot " .. tostring(m.slot) .. ": " .. tostring(e))
        end
      end
    end
  end
end

-- Internal: `team` = { team, formation, emblem, uniform, captain, name, members = { { slot, param, loadout, fields = { key = text } } } }.
function M.encode(team)
  local lines = { HEADER .. " " .. M.VERSION }
  lines[#lines + 1] = table.concat({ "team", number_text(team.team), number_text(team.formation), number_text(team.emblem),
    number_text(team.uniform), number_text(team.captain), pack_text(team.name) }, " ")
  local members = {}
  for _, m in ipairs(team.members or {}) do
    members[#members + 1] = m
  end
  table.sort(members, function(a, b)
    return a.slot < b.slot
  end)
  for _, m in ipairs(members) do
    local fields = {}
    for key, v in pairs(m.fields or {}) do
      fields[#fields + 1] = pack_text(key) .. "=" .. pack_text(v)
    end
    table.sort(fields)
    lines[#lines + 1] = table.concat({ "m", tostring(m.slot), number_text(m.param), number_text(m.loadout),
      #fields > 0 and table.concat(fields, ",") or "-" }, " ")
  end
  return table.concat(lines, "\n")
end

-- Internal: The team of a payload text; nil, why when it is not a payload of this version.
function M.decode(text)
  if type(text) ~= "string" then
    return nil, "no payload"
  end
  local team = { members = {} }
  local first = true
  for line in text:gmatch("[^\n]+") do
    local words = {}
    for w in line:gmatch("%S+") do
      words[#words + 1] = w
    end
    if first then
      if words[1] ~= HEADER or tonumber(words[2]) ~= M.VERSION then
        return nil, "payload version " .. tostring(words[2]) .. " (this game reads " .. M.VERSION .. ")"
      end
      first = false
    elseif words[1] == "team" and #words == 7 then
      team.team, team.formation, team.emblem = tonumber(words[2]), tonumber(words[3]), tonumber(words[4])
      team.uniform, team.captain, team.name = tonumber(words[5]), tonumber(words[6]), unpack_text(words[7])
    elseif words[1] == "m" and #words == 5 then
      local m = { slot = tonumber(words[2]), param = tonumber(words[3]), loadout = tonumber(words[4]) }
      if words[5] ~= "-" then
        m.fields = {}
        for pair in words[5]:gmatch("[^,]+") do
          local k, v = pair:match("^([^=]+)=(.+)$")
          local key, value = unpack_text(k), unpack_text(v)
          if key == nil or value == nil then
            return nil, "a member field is not readable"
          end
          m.fields[key] = value
        end
      end
      if m.slot == nil or m.param == nil or m.loadout == nil then
        return nil, "a member line is not readable"
      end
      team.members[#team.members + 1] = m
    else
      return nil, "line not readable: " .. line:sub(1, 40)
    end
  end
  if first or team.formation == nil then
    return nil, "the payload has no team line"
  end
  return team
end

-- Advanced: Collects the registered fields, encodes `team` and sends it to the other player: true, or false, why.
function M.send(team)
  M.collect(team)
  local text = M.encode(team)
  local r = VRFW.net.team_send(text)
  if type(r) ~= "table" or not r.ok then
    return false, type(r) == "table" and r.error or "the net service did not answer"
  end
  info(string.format("sent: %d member(s), formation %s, %d bytes", #(team.members or {}), VRFW.ids.hex_text(team.formation or 0), #text))
  return true
end

-- Advanced: The decoded payload of `who` ("own", "peer", "host" or "guest"): team, crc; nil, why when there is none yet.
function M.of(who)
  local r = VRFW.net.team(who)
  if type(r) ~= "table" or not r.ok then
    return nil, type(r) == "table" and r.error or "the net service did not answer"
  end
  local team, why = M.decode(r.value)
  if not team then
    return nil, why
  end
  return team, r.crc
end

return M
