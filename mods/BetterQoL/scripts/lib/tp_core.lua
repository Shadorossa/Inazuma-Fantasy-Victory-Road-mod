
local M = {}

M.BLOB = "team_planner.json"
M.FILE_VERSION = 2 -- 2: a dock squad is keyed by its team template (1: by page and team set)
M.LEADER_SLOT = 19
M.MAX_SLOT = 19

local Id = VRFW.ids

local u32 = Id.unsigned

-- an integer or nil
function M.int(v)
  if type(v) ~= "number" then
    return nil
  end
  if v >= 0 then
    return math.floor(v)
  end
  return math.ceil(v)
end

-- a list of integers 0..15 (nil when `v` is not such a list)
local function value_list(v)
  if type(v) ~= "table" then
    return nil
  end
  local out = {}
  for _, x in ipairs(v) do
    if type(x) ~= "number" or x ~= math.floor(x) or x < 0 or x > 15 then
      return nil
    end
    out[#out + 1] = x
  end
  return out
end

function M.rule_from_config(cfg, notes)
  local r = { display_rarity = 4, owned_any = false, owned = { [4] = true }, card_values = { 0, 1, 2, 3, 4 },
              source = "config" }
  if type(cfg) ~= "table" then
    return r
  end
  M.apply(r, cfg, "config.toml [team_planner]", notes)
  return r
end

function M.apply(r, d, who, notes)
  notes = notes or {}
  local any = false
  local dr = d.display_rarity
  if dr ~= nil then
    if type(dr) == "number" and dr == math.floor(dr) and dr >= 0 and dr <= 15 then
      r.display_rarity = dr
      any = true
    else
      notes[#notes + 1] = who .. ": display_rarity must be an integer 0..15 (ignored)"
    end
  end
  local o = d.owned_rarities
  if o ~= nil then
    if o == "any" then
      r.owned_any, r.owned = true, {}
      any = true
    else
      local l = value_list(o)
      if l and #l > 0 then
        r.owned_any, r.owned = false, {}
        for _, x in ipairs(l) do
          r.owned[x] = true
        end
        any = true
      else
        notes[#notes + 1] = who .. ": owned_rarities must be \"any\" or a list of integers 0..15 (ignored)"
      end
    end
  end
  local cv = d.card_values
  if cv ~= nil then
    local l = value_list(cv)
    if l and #l > 0 then
      r.card_values = l
      any = true
    else
      notes[#notes + 1] = who .. ": card_values must be a list of integers 0..15 (ignored)"
    end
  end
  return any
end

-- a comparable text of the parts of a rule a declaration sets (to tell two declarations apart)
function M.rule_sig(r)
  local owned = {}
  if r.owned_any then
    owned[1] = "any"
  else
    for k in pairs(r.owned) do
      owned[#owned + 1] = tostring(k)
    end
    table.sort(owned)
  end
  local cv = {}
  for _, x in ipairs(r.card_values) do
    cv[#cv + 1] = tostring(x)
  end
  return string.format("display %d, owned %s, cards %s", r.display_rarity, table.concat(owned, "/"), table.concat(cv, "/"))
end

local KEY_SIG = {
  display_rarity = function(r) return tostring(r.display_rarity) end,
  owned_rarities = function(r) return M.rule_sig(r):match("owned ([^,]*)") end,
  card_values = function(r) return M.rule_sig(r):match("cards (.*)$") end,
}
function M.rule(cfg, decls, notes)
  notes = notes or {}
  local r = M.rule_from_config(cfg, notes)
  local set_by = {}
  for _, e in ipairs(decls or {}) do
    local d = type(e.data) == "table" and e.data or {}
    local probe = { display_rarity = r.display_rarity, owned_any = r.owned_any, owned = r.owned, card_values = r.card_values }
    if M.apply(probe, d, "content/team_planner of mod " .. tostring(e.mod), notes) then
      for key, sig_of in pairs(KEY_SIG) do
        if d[key] ~= nil then
          local value = sig_of(probe)
          local prev = set_by[key]
          if prev ~= nil and prev.value ~= value then
            notes[#notes + 1] = "content/team_planner: mod " .. tostring(e.mod) .. " sets " .. key .. " = " .. value
              .. ", replacing mod " .. tostring(prev.mod) .. "'s " .. prev.value
          end
          set_by[key] = { mod = e.mod, value = value }
        end
      end
      r.display_rarity, r.owned_any, r.owned, r.card_values = probe.display_rarity, probe.owned_any, probe.owned, probe.card_values
      r.source = "mod " .. tostring(e.mod)
    end
  end
  return r
end

-- does an owned copy of rarity `rarity` count
function M.qualifies(r, rarity)
  if r.owned_any then
    return true
  end
  return r.owned[rarity or -1] == true
end

function M.card_params(rows, card_values)
  local ok = {}
  for _, v in ipairs(card_values) do
    ok[v] = true
  end
  local out, n = {}, 0
  for _, r in ipairs(rows) do
    local p, b, s = r[1], r[2], r[3] or 0
    if p ~= 0 and b ~= 0 and ok[s] and out[b] == nil then
      out[b] = p
      n = n + 1
    end
  end
  return out, n
end

-- `template` > 0: a squad of that team template (set 0); 0: the squad of team set `set`, which is no dock
function M.squad_key(template, set, ty)
  return string.format("%d:%d:%d", template, set, ty)
end

function M.parse_squad_key(k)
  local p, s, t = tostring(k):match("^(%-?%d+):(%d+):(%d+)$")
  if not p then
    return nil
  end
  return tonumber(p), tonumber(s), tonumber(t)
end

function M.valid_slot(slot)
  return type(slot) == "number" and slot == math.floor(slot) and slot >= 0 and slot <= M.MAX_SLOT
end

function M.new_file(slot)
  return { slot = slot, version = M.FILE_VERSION, plans = {}, dirty = false }
end

function M.set(f, key, slot, param)
  local sq = f.plans[key]
  local cur = sq and sq[slot] or nil
  if param == 0 then
    if cur == nil then
      return false
    end
    sq[slot] = nil
    if next(sq) == nil then
      f.plans[key] = nil
    end
    f.dirty = true
    return true
  end
  if cur == param then
    return false
  end
  if not sq then
    sq = {}
    f.plans[key] = sq
  end
  sq[slot] = param
  f.dirty = true
  return true
end

function M.move(f, from_key, from_slot, to_key, to_slot)
  if from_slot == M.LEADER_SLOT or to_slot == M.LEADER_SLOT then
    return nil
  end
  local from_sq = f.plans[from_key]
  local param = from_sq and from_sq[from_slot] or nil
  if param == nil then
    return nil
  end
  if from_key == to_key and from_slot == to_slot then
    return true
  end
  local to_sq = f.plans[to_key]
  local other = to_sq and to_sq[to_slot] or nil
  if from_key ~= to_key then
    for slot, p in pairs(to_sq or {}) do
      if p == param and slot ~= to_slot then
        return nil
      end
    end
    for slot, p in pairs(from_sq) do
      if other ~= nil and p == other and slot ~= from_slot then
        return nil
      end
    end
  end
  M.set(f, from_key, from_slot, other or 0)
  M.set(f, to_key, to_slot, param)
  return true
end

-- "slot:param,…" of a squad (slots ascending), "" for none
function M.list_text(f, key)
  local sq = f.plans[key]
  if not sq then
    return ""
  end
  local slots = {}
  for s in pairs(sq) do
    slots[#slots + 1] = s
  end
  table.sort(slots)
  local parts = {}
  for _, s in ipairs(slots) do
    parts[#parts + 1] = string.format("%d:%d", s, sq[s])
  end
  return table.concat(parts, ",")
end

-- "set:type,..." of the planned squads now in a team set; set_of(template, set) -> that team set or nil
function M.pending_text(f, set_of)
  local out = {}
  for k in pairs(f.plans) do
    local p, s, t = M.parse_squad_key(k)
    local set = p and set_of(p, s)
    if set then
      out[#out + 1] = { set, t }
    end
  end
  table.sort(out, function(a, b)
    if a[1] ~= b[1] then
      return a[1] < b[1]
    end
    return a[2] < b[2]
  end)
  local parts = {}
  for _, x in ipairs(out) do
    parts[#parts + 1] = string.format("%d:%d", x[1], x[2])
  end
  return table.concat(parts, ",")
end

function M.count(f)
  local n = 0
  for _, sq in pairs(f.plans) do
    for _ in pairs(sq) do
      n = n + 1
    end
  end
  return n
end

-- the JSON document of a file (slots as text keys)
function M.encode_doc(f)
  local plans = {}
  for k, sq in pairs(f.plans) do
    local o = {}
    for s, p in pairs(sq) do
      o[tostring(s)] = p
    end
    plans[k] = o
  end
  return { version = f.version, plans = plans }
end

function M.decode_doc(doc, slot)
  local f = M.new_file(slot)
  if doc == nil then
    return f
  end
  if type(doc) ~= "table" then
    return nil, "not an object"
  end
  f.version = doc.version or 1
  local v = doc.version
  if v ~= nil and v ~= M.FILE_VERSION and v ~= 1 then
    return nil, "version " .. tostring(v) .. " (this BetterQoL reads " .. M.FILE_VERSION .. ")"
  end
  if type(doc.plans) ~= "table" then
    return f
  end
  for k, sq in pairs(doc.plans) do
    if M.parse_squad_key(k) and type(sq) == "table" then
      for s, p in pairs(sq) do
        local slot = tonumber(s)
        if M.valid_slot(slot) and type(p) == "number" and p > 0 then
          f.plans[k] = f.plans[k] or {}
          f.plans[k][slot] = u32(p)
        end
      end
    end
  end
  return f
end

function M.candidates(r, owned)
  local out = {}
  for _, c in ipairs(owned or {}) do
    if M.qualifies(r, c.rarity) then
      out[#out + 1] = c
    end
  end
  table.sort(out, function(a, b)
    if (a.level or 0) ~= (b.level or 0) then
      return (a.level or 0) > (b.level or 0)
    end
    if (a.rarity or 0) ~= (b.rarity or 0) then
      return (a.rarity or 0) > (b.rarity or 0)
    end
    return a.h < b.h
  end)
  return out
end

return M
