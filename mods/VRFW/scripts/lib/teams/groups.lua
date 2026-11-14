-- Advanced: The players' groups ([[VRFW.SynergyPool]] of every mod's content/synergies): one reader and one evaluator for the synergies and the passive traits.
local M = {}

local GENDER = { male = 1, female = 2 }
local ROLES = { manager = true, coach = true }

local Id = VRFW.ids
local u32 = Id.unsigned
local Rows = VRFW.table_files
local Persons = VRFW.persons
local info, warn = VRFW.logger("team_groups")

local function list_of(v) return VRFW.value.list(v, {}) end

-- a character: "c11801020" (internal key) / a mod character name / "0x…" → its chara_base id
local function chara_of(v)
  return Id.character(v, { hash_names = true })
end

-- a card's character, asked once per card id
local BASE_OF = {}
local function base_of(param)
  local b = BASE_OF[param]
  if b ~= nil then return b or nil end
  local ok, v = pcall(VRFW.character.base_of, param)
  b = (ok and type(v) == "number") and u32(v) or false
  BASE_OF[param] = b
  return b or nil
end

local POOLS = nil        -- "<mod>.<name>" -> pool
local ANY_VERSION = nil  -- the mods whose [[VRFW.SynergyRules]] any_version = true (nil: none)

local POOL_KEYS = { name = true, teams = true, series = true, role = true, gender = true, charas = true, exclude = true, hint = true, show_candidates = true, captains_of = true, captains_of_teams = true, captain_overrides = true, crest_eras = true, crests = true, rosters = true, same_person = true, extends = true }
-- the keys of a pool that extends another one
local EXTEND_KEYS = { extends = true, charas = true, same_person = true }

-- same_person = [[chara, chara, ...], ...]: groups of characters that are one person; answers the groups of ids, or nil, why
local function same_person_of(v, where)
  local out = {}
  if v == nil then return out end
  if type(v) ~= "table" then return nil, where .. ": same_person = [ [ \"<chara>\", \"<chara>\" ], ... ]" end
  for _, g in ipairs(v) do
    local group = {}
    for _, c in ipairs(type(g) == "table" and g or {}) do
      local b = chara_of(c)
      if not b then return nil, where .. ": same_person: unknown character " .. tostring(c) end
      group[#group + 1] = b
    end
    if #group < 2 then return nil, where .. ": same_person: each group lists two or more characters" end
    out[#out + 1] = group
  end
  return out
end

local function read_pool(mod, file, p, i)
  local where = string.format("mods/%s/%s: [[VRFW.SynergyPool]] #%d", tostring(mod), tostring(file), i)
  for k in pairs(p) do
    if not POOL_KEYS[k] then return nil, where .. ": unknown key `" .. tostring(k) .. "`" end
  end
  local same, bad = same_person_of(p.same_person, where)
  if not same then return nil, bad end
  -- extends = "<Mod>.<pool name>": the charas and same_person groups join that pool instead of a new pool
  if p.extends ~= nil then
    if type(p.extends) ~= "string" or not p.extends:match("^[%w_]+%.[a-z0-9_]+$") then return nil, where .. ": extends = \"<Mod>.<pool name>\"" end
    for k in pairs(p) do
      if not EXTEND_KEYS[k] then return nil, where .. ": extends: key `" .. tostring(k) .. "` (only charas, same_person)" end
    end
    local x = { extends = p.extends, where = where, charas = {}, same_person = same }
    for _, c in ipairs(list_of(p.charas)) do
      local id = chara_of(c)
      if id then x.charas[id] = true end
    end
    return x
  end
  if type(p.name) ~= "string" or not p.name:match("^[a-z0-9_]+$") then return nil, where .. ": name = \"a-z 0-9 _\" is required" end
  local x = { key = tostring(mod) .. "." .. p.name, teams = {}, team_list = {}, series = {}, charas = {}, exclude = {},
    hint = p.hint and Id.parse(p.hint, { hash_names = true }) or nil, show_candidates = p.show_candidates == true, same_person = same }
  for _, t in ipairs(list_of(p.teams)) do
    local id = Id.parse(t, { hash_names = true })
    if not id then return nil, where .. " " .. p.name .. ": teams = [ belong team ids ]" end
    if not x.teams[id] then x.team_list[#x.team_list + 1] = id end
    x.teams[id] = true
    x.any_team = true
  end
  for _, s in ipairs(list_of(p.series)) do
    local ok, n = pcall(VRFW.character.series_of, s)
    if ok and n == nil then
      local okn, names = pcall(VRFW.character.series_names)
      return nil, string.format("%s %s: series %q (%s, or an alias of content\\defaults\\series_names.toml)", where, p.name,
        tostring(s), okn and type(names) == "table" and table.concat(names, " ") or "?")
    end
    x.series[#x.series + 1] = ok and n or s
    x.any_series = true
  end
  if p.role ~= nil then
    if not ROLES[p.role] then return nil, string.format("%s %s: role %q (manager, coach)", where, p.name, tostring(p.role)) end
    x.role = p.role
  end
  if p.gender ~= nil then
    x.gender = GENDER[tostring(p.gender)]
    if not x.gender then return nil, string.format("%s %s: gender %q (male, female)", where, p.name, tostring(p.gender)) end
  end
  for _, c in ipairs(list_of(p.charas)) do
    local id = chara_of(c)
    if id then x.charas[id] = true; x.any_chara = true end
  end
  for _, c in ipairs(list_of(p.exclude)) do
    local id = chara_of(c)
    if id then x.exclude[id] = true end
  end
  x.crest_eras = p.crest_eras == true
  local ERA_OF = { ie1 = 1, ie2 = 1, ie3 = 1, go1 = 2, go2 = 2, go3 = 2, go = 2, cs = 2, galaxy = 2, ares = 3, orion = 3, victory_road = 4, vr = 4 }
  for _, sname in ipairs(list_of(p.series)) do
    local e = ERA_OF[tostring(sname)]
    if e == nil or (x.era ~= nil and x.era ~= e) then x.era = nil; x.era_mixed = true
    elseif not x.era_mixed then x.era = e end
  end
  x.crest_list = {}
  local CREST_ERA = { ie = 1, go = 2, ares = 3, vr = 4 }
  for _, c in ipairs(list_of(p.crests)) do
    if type(c) == "table" and type(c.game_team) == "string" then
      x.crest_list[#x.crest_list + 1] = { game_team = c.game_team }
    else
      local t = type(c) == "table" and Id.parse(c.team, { hash_names = true }) or nil
      local e = type(c) == "table" and CREST_ERA[tostring(c.era)] or nil
      if not t or not e then return nil, where .. " " .. p.name .. ": crests = [ { team = <belong team id>, era = \"ie\" | \"go\" | \"ares\" | \"vr\" } or { game_team = \"<game team key>\" } ]" end
      x.crest_list[#x.crest_list + 1] = { team = t, era = e, emblem = c.emblem ~= nil and Id.parse(c.emblem, { hash_names = true }) or nil }
    end
  end
  -- captains_of_teams = [game team keys] (team_config): the captains of those teams join the pool
  x.captain_keys = {}
  for _, k in ipairs(list_of(p.captains_of_teams)) do
    if type(k) ~= "string" then return nil, where .. " " .. p.name .. ": captains_of_teams = [ \"<game team key>\" ]" end
    x.captain_keys[k] = true
    x.has_captain_keys = true
  end
  x.roster_keys = {}
  for _, k in ipairs(list_of(p.rosters)) do
    if type(k) ~= "string" then return nil, where .. " " .. p.name .. ": rosters = [ \"<game team key>\" ]" end
    x.roster_keys[#x.roster_keys + 1] = k
  end
  x.captain_override = {}
  for _, o in ipairs(list_of(p.captain_overrides)) do
    local c = type(o) == "table" and chara_of(o.captain) or nil
    if type(o) ~= "table" or type(o.team) ~= "string" or not c then
      return nil, where .. " " .. p.name .. ": captain_overrides = [ { team = \"<game team key>\", captain = \"<chara>\" } ]"
    end
    x.captain_override[o.team] = c
  end
  -- captains_of = [belong team ids]: the captains of the game's teams (team_config) named like those belong teams
  x.captain_teams = {}
  for _, t in ipairs(list_of(p.captains_of)) do
    local id = Id.parse(t, { hash_names = true })
    if not id then return nil, where .. " " .. p.name .. ": captains_of = [ belong team ids ]" end
    x.captain_teams[#x.captain_teams + 1] = id
  end
  if not (x.any_team or x.any_series or x.role or x.gender or x.any_chara or #x.captain_teams > 0 or x.has_captain_keys
      or #x.roster_keys > 0) then
    return nil, where .. " " .. p.name .. ": no criterion (teams, series, role, gender, charas, captains_of, captains_of_teams, rosters): it would take everyone"
  end
  return x
end


local TEAM_CAPTAINS = nil
local TEAM_ROSTERS = {}
local function team_captains()
  if TEAM_CAPTAINS then return TEAM_CAPTAINS end
  TEAM_CAPTAINS = {}
  TEAM_ROSTERS = {}
  local ok, e = pcall(function()
    local ents = VRFW.table.entries(Rows.file_name("data/common/gamedata/team/team_config"),
      { "SOCCER_TEAM_INFO", "SOCCER_TEAM_INFO_REF_MEMBER", "SOCCER_TEAM_MEMBER" })
    local members = {}
    for _, m in ipairs(ents) do
      if m.name == "SOCCER_TEAM_MEMBER" then members[#members + 1] = m end
    end
    for i, t in ipairs(ents) do
      local ref = ents[i + 1]
      if t.name == "SOCCER_TEAM_INFO" and ref and ref.name == "SOCCER_TEAM_INFO_REF_MEMBER" then
        local text = u32(tonumber(t[4]) or 0)
        local roster = {}
        TEAM_ROSTERS[tostring(t[2])] = roster
        for k = 0, (tonumber(ref[2]) or 0) - 1 do
          local m = members[(tonumber(ref[1]) or 0) + k + 1]
          local b = m and base_of(u32(tonumber(m[1]) or 0)) or nil
          if b then roster[#roster + 1] = b end
          if b and tonumber(m[12]) == 1 then
            TEAM_CAPTAINS[#TEAM_CAPTAINS + 1] = { key = tostring(t[2]), text = text, base = b, emblem = u32(tonumber(t[7]) or 0) }
          end
        end
      end
    end
  end)
  if not ok then warn("team captains not readable: " .. tostring(e)) end
  return TEAM_CAPTAINS
end

-- the captains of the teams named like the belong teams `ids`
local function captains_of(ids, keys, override)
  local out, texts = {}, {}
  local ok, e = pcall(function()
    for _, r in ipairs(VRFW.table.rows("character/belong_team") or {}) do
      local id = u32(r.belong_team_id or r[1] or 0)
      local text = u32(r.team_name_text_id or r[3] or 0)
      for _, want in ipairs(ids) do
        if id == want and text ~= 0 then texts[#texts + 1] = text end
      end
    end
  end)
  if not ok then warn("belong teams not readable: " .. tostring(e)) end
  local seen = {}
  for _, t in ipairs(team_captains()) do
    local hit = keys[t.key] == true
    for _, text in ipairs(texts) do
      if t.text == text then hit = true end
    end
    local b = override[t.key] or t.base
    if hit and not seen[b] then seen[b] = true; out[#out + 1] = b end
  end
  return out
end

-- the members of the game teams `keys` (team_config), every card of their rosters
local function roster_members(keys)
  local out = {}
  if #keys == 0 then return out end
  team_captains()
  for _, k in ipairs(keys) do
    local r = TEAM_ROSTERS[k]
    if r then
      for _, b in ipairs(r) do out[#out + 1] = b end
    else
      warn(string.format("rosters: game team %s not found in team_config", k))
    end
  end
  return out
end

-- any_version: the characters of `set` and every version of them, as a list
local function with_versions(set)
  local out, seen = {}, {}
  for b in pairs(set) do
    for _, v in ipairs(ANY_VERSION and Persons.versions(b) or { b }) do
      if not seen[v] then
        seen[v] = true
        out[#out + 1] = v
      end
    end
  end
  return out
end

local function pool_members(p)
  if p.members then return p.members end
  p.members, p.set = {}, {}
  local include = {}
  local captains = (#p.captain_teams > 0 or p.has_captain_keys) and captains_of(p.captain_teams, p.captain_keys, p.captain_override) or {}
  local roster = roster_members(p.roster_keys)
  if p.any_chara or #captains > 0 or #roster > 0 then
    local ids = with_versions(p.charas)
    for _, b in ipairs(captains) do ids[#ids + 1] = b end
    for _, b in ipairs(roster) do ids[#ids + 1] = b end
    include[#include + 1] = { characters = ids }
  end
  if p.any_team or p.any_series or p.role or p.gender then
    include[#include + 1] = { team = p.any_team and p.team_list or nil, series = p.any_series and p.series or nil,
      role = p.role, gender = p.gender and { p.gender } or nil }
  end
  local exclude = with_versions(p.exclude)
  if #include > 0 then
    local ok, ids = pcall(VRFW.character.select, { include = include, exclude = #exclude > 0 and { { characters = exclude } } or nil },
      { characters = true })
    if ok and type(ids) == "table" then
      for _, b in ipairs(ids) do
        b = u32(b)
        p.members[#p.members + 1] = b
        p.set[b] = true
      end
    else
      warn(string.format("pool %s: not evaluated (%s): no members", p.key, tostring(ids)))
    end
  end
  info(string.format("pool %s: %d characters", p.key, #p.members))
  return p.members
end


-- an extending pool `x`: its charas and same_person groups join pool x.extends; answers that pool, or nil, why
local function extend(x)
  local p = POOLS[x.extends]
  if not p then
    info(x.where .. ": extends " .. x.extends .. ": no such pool (its mod is not loaded): skipped")
    return nil, x.extends .. ": no such pool"
  end
  local n = 0
  for id in pairs(x.charas) do
    if not p.charas[id] then p.charas[id], n = true, n + 1 end
    p.any_chara = true
  end
  for _, g in ipairs(x.same_person) do p.same_person[#p.same_person + 1] = g end
  p.members, p.set = nil, nil
  info(string.format("%s: extends %s: +%d characters, +%d same_person groups", x.where, x.extends, n, #x.same_person))
  return p
end

-- the pools and the any_version rule of every mod's content/synergies, read once
local function read()
  if POOLS then return POOLS end
  POOLS = {}
  local extensions = {}
  local ok, files = pcall(VRFW.files.declarations, "content/synergies")
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local d = f.data or {}
    if d.schema == nil or d.schema == "VRFW.synergy/1" then
      local v = type(d.VRFW) == "table" and d.VRFW or {}
      for i, p in ipairs(type(v.SynergyPool) == "table" and v.SynergyPool or {}) do
        local x, why = read_pool(f.mod, f.file, p, i)
        if not x then warn(why .. ": left out")
        elseif x.extends then extensions[#extensions + 1] = x
        elseif POOLS[x.key] then warn(x.key .. ": declared twice: the second left out")
        else POOLS[x.key] = x end
      end
      for i, r in ipairs(type(v.SynergyRules) == "table" and v.SynergyRules or {}) do
        local where = string.format("mods/%s/%s: [[VRFW.SynergyRules]] #%d", tostring(f.mod), tostring(f.file), i)
        local bad = nil
        for k in pairs(r) do
          if k ~= "any_version" then bad = k end
        end
        if bad ~= nil then
          warn(where .. ": unknown key `" .. tostring(bad) .. "`: left out")
        elseif r.any_version ~= nil and type(r.any_version) ~= "boolean" then
          warn(where .. ": any_version = true / false: left out")
        elseif r.any_version then
          ANY_VERSION = ANY_VERSION or {}
          ANY_VERSION[#ANY_VERSION + 1] = tostring(f.mod)
        end
      end
    end
  end
  for _, x in ipairs(extensions) do extend(x) end
  if ANY_VERSION then
    info(string.format("any_version (%s): a character a group or a synergy names is met by any version of him", table.concat(ANY_VERSION, ", ")))
  end
  return POOLS
end

--- Internal: Every declared pool: "<mod>.<name>" -> its record (read once).
function M.pools()
  return read()
end

--- Internal: The record of pool `key`, or nil.
function M.pool(key)
  return read()[key]
end

--- Internal: True when pool `key` exists.
function M.has_pool(key)
  return read()[key] ~= nil
end

--- Internal: Adds a pool declared outside content/synergies (mod, file, the declaration table, its index); answers the record, or nil, why.
function M.add(mod, file, decl, i)
  local x, why = read_pool(mod, file, decl, i)
  if not x then return nil, why end
  local pools = read()
  if x.extends then return extend(x) end
  pools[x.key] = pools[x.key] or x
  return pools[x.key]
end

--- Internal: The mods that turn the any_version rule on, or nil when none does.
function M.any_version()
  read()
  return ANY_VERSION
end

--- Internal: The characters of `set` ([id] = true) and, with the any_version rule, every version of them, as a list.
function M.with_versions(set)
  read()
  return with_versions(set)
end

--- Internal: The member list of a pool record (evaluated once; the record's `set` holds the same characters).
function M.member_list(p)
  if not p then return {} end
  return pool_members(p)
end

--- Internal: The member set of pool `key` ([chara_base] = true; empty when the pool is unknown).
function M.members(key)
  local p = read()[key]
  if not p then return {} end
  pool_members(p)
  return p.set
end

--- Internal: Takes member lists computed earlier (pool key -> list) for the pools not evaluated yet.
function M.seed_members(lists)
  local pools = read()
  for k, list in pairs(lists or {}) do
    local p = pools[k]
    if p and not p.members then
      p.members, p.set = list, {}
      for _, b in ipairs(list) do p.set[b] = true end
    end
  end
end

--- Internal: The game teams' captains ({ key, text, base, emblem }, team_config order), read once.
function M.team_captains()
  return team_captains()
end

--- Internal: The captains and rosters as read, for a cache, and back: M.team_tables() -> captains, rosters; M.seed_teams(captains, rosters).
function M.team_tables()
  return TEAM_CAPTAINS, TEAM_CAPTAINS and TEAM_ROSTERS or nil
end

--- Internal: Fills the captain and roster tables from a cache when they are not loaded yet.
function M.seed_teams(captains, rosters)
  if TEAM_CAPTAINS == nil and captains then TEAM_CAPTAINS, TEAM_ROSTERS = captains, rosters or {} end
end

local GROUPS_OF = {}

--- Internal: The pools naming belong teams that hold character `base` ([key] = true).
function M.groups_of(base)
  base = u32(base)
  local g = GROUPS_OF[base]
  if g then return g end
  g = {}
  for key, p in pairs(read()) do
    if p.any_team and M.members(key)[base] then g[key] = true end
  end
  GROUPS_OF[base] = g
  return g
end

return M
