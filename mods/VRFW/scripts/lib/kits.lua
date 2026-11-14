-- Advanced: Derives the uniform of a card's own team from game data (mod overlays included); names no character, team or kit.

local M = {}

local Id = VRFW.ids
local u32 = Id.unsigned

local function col(row, ...)
  for i = 1, select("#", ...) do
    local v = row[select(i, ...)]
    if v ~= nil then return v end
  end
  return nil
end

-- Served file of a table id (mod overlay first, else the game's).
local function key_of(id, stem)
  local ok, k = pcall(VRFW.table.source, id)
  if ok and type(k) == "string" and k ~= "" then return k end
  return VRFW.table_files.file_name(stem)
end

-- 1-based position of column `name` in table `id`; nil = absent.
local function pos_of(id, ...)
  local ok, cols = pcall(VRFW.table.columns, id)
  if not ok or type(cols) ~= "table" then return nil end
  for i, c in ipairs(cols) do
    for k = 1, select("#", ...) do
      if c == select(k, ...) then return i end
    end
  end
  return nil
end

local D = nil          -- tables, read once
local CACHE = {}       -- card -> { uniform, flags, source }

local function read_all()
  if D ~= nil then return D end
  local t0 = VRFW.now_ms()
  D = { uniform = {}, item_uniform = {}, kits = {}, type_era = {}, eras = 0, chara = {}, card = {},
        roster = nil, n_uniform = 0 }
  -- uniforms (uniform_config)
  pcall(function()
    local rows = VRFW.table.raw(key_of("character/uniform", "data/common/gamedata/character/uniform_config"),
      "m_UniformInfoList", { 1 })
    for _, r in ipairs(rows or {}) do
      local id = u32(r[1])
      if id ~= 0 then
        D.uniform[id] = true
        D.n_uniform = D.n_uniform + 1
      end
    end
  end)
  -- kit items: item id -> model uniform
  pcall(function()
    local p = pos_of("item/item_fashion", "uniform")
    if p == nil then return end
    local rows = VRFW.table.raw(key_of("item/item_fashion", "data/common/gamedata/item/item_config"),
      "ITEM_FASHION_INFO", { 1, p })
    for _, r in ipairs(rows or {}) do
      local id, u = u32(r[1]), u32(r[p])
      if id ~= 0 and u ~= 0 and D.item_uniform[id] == nil then D.item_uniform[id] = u end
    end
  end)
  -- belong_team_config: series type -> era (k-th teamNumber_<x> column), team -> kits
  pcall(function()
    local nums, eras = {}, {}
    for i, n in ipairs(VRFW.table.columns("character/belong_team")) do
      local x = n:match("^team_number_(.+)$") or n:match("^teamNumber_(.+)$")
      if x then nums[#nums + 1] = x:lower() end
      local e = n:match("^team_kit_(.+)$") or n:match("^teamKit_(.+)$")
      if e then eras[#eras + 1] = { name = e:lower(), col = i } end
    end
    for k, x in ipairs(nums) do
      for ei, e in ipairs(eras) do
        if x:sub(1, #e.name) == e.name or (#x >= 3 and e.name:find(x:sub(1, 3), 1, true)) then
          D.type_era[k] = ei
          break
        end
      end
    end
    D.eras = #eras
    for _, r in ipairs(VRFW.table.rows("character/belong_team")) do
      local id = u32(col(r, "belong_team_id", "belongTeamId"))
      if id ~= 0 then
        local kits = {}
        for ei, e in ipairs(eras) do kits[ei] = u32(r[e.col]) end
        D.kits[id] = kits
      end
    end
  end)
  D.chara = setmetatable({}, { __index = function(t, base)
    local ok, c = pcall(VRFW.character.character, base)
    if not ok or type(c) ~= "table" then return nil end
    local v = { u32(c.series), u32(c.teams[1]), u32(c.teams[2]), u32(c.teams[3]) }
    rawset(t, base, v)
    return v
  end })
  D.card = setmetatable({}, { __index = function(t, card)
    local ok, c = pcall(VRFW.character.card, card)
    if not ok or type(c) ~= "table" then return nil end
    local v = { u32(c.base), u32(c.position), c.coach == true, c.manager == true }
    rawset(t, card, v)
    return v
  end })
  VRFW.log(string.format("chara_kit: tables read in %d ms (%d uniforms, %d belong teams, %d eras; characters and cards: the framework's index)",
    math.floor(VRFW.now_ms() - t0), D.n_uniform, (function() local n = 0 for _ in pairs(D.kits) do n = n + 1 end return n end)(),
    D.eras))
  return D
end

-- A kit value -> a uniform_config id (itself or the model of a kit item); nil = none.
local function resolve(v)
  v = u32(v)
  if v == 0 then return nil end
  if D.uniform[v] then return v end
  local u = D.item_uniform[v]
  if u ~= nil and D.uniform[u] then return u end
  return nil
end

local team_kit

-- the stand-in kits of belong_team_config and the team whose kit replaces them (config.toml [character]); read once
local function stand_ins()
  if D.stand_in ~= nil then return D.stand_in end
  D.stand_in = { kits = {}, team = 0 }
  for _, k in ipairs(VRFW.config("character.stand_in_kits", {})) do D.stand_in.kits[u32(k)] = true end
  local team = VRFW.config("character.stand_in_kit_team", "")
  if team ~= "" then D.stand_in.team = VRFW.crc32(team) end
  return D.stand_in
end

local function belong_kit(base)
  local c = D.chara[base]
  if c == nil then return nil end
  local era = D.type_era[c[1]]
  for t = 2, 4 do
    local kits = c[t] ~= 0 and D.kits[c[t]] or nil
    if kits ~= nil then
      local v = era and u32(kits[era]) or 0
      local s = stand_ins()
      if s.kits[v] and s.team ~= 0 then
        local u = team_kit(s.team)
        if u then return u end
      end
      return resolve(v) or false
    end
  end
  return nil
end

-- card -> uniform of the first team_config team listing it (built on first use)
local function roster_kit(card)
  if D.roster == nil then
    D.roster = {}
    D.team_uniform = {}
    local t0 = VRFW.now_ms()
    local ok, err = pcall(function()
      local key = key_of("team/team", "data/common/gamedata/team/team_config")
      local pu = pos_of("team/team", "uniform") or 6
      local teams = VRFW.table.raw(key, "SOCCER_TEAM_INFO", { 1, pu })
      local refs = VRFW.table.raw(key, "SOCCER_TEAM_INFO_REF_MEMBER", { 1, 2 })
      local members = VRFW.table.raw(key, "SOCCER_TEAM_MEMBER", { 1 })
      if type(teams) ~= "table" or type(refs) ~= "table" or type(members) ~= "table" or #refs ~= #teams then
        return "team_config rows / member refs do not match"
      end
      for i, t in ipairs(teams) do
        local u = resolve(t[pu])
        local team_id = u32(t[1])
        if u and team_id ~= 0 and D.team_uniform[team_id] == nil then D.team_uniform[team_id] = u end
        local a, n = tonumber(refs[i][1]), tonumber(refs[i][2])
        if u and a and n then
          for k = a + 1, a + n do
            local c = members[k] and u32(members[k][1]) or 0
            if c ~= 0 and D.roster[c] == nil then D.roster[c] = u end
          end
        end
      end
    end)
    VRFW.log(string.format("chara_kit: team rosters read in %d ms%s", math.floor(VRFW.now_ms() - t0),
      (ok and not err) and "" or (" (" .. tostring(err) .. ")")))
  end
  return D.roster[card]
end

-- team_config id -> its uniform (read with the rosters)
function team_kit(team)
  roster_kit(0)
  return D.team_uniform[team]
end

--- Internal: Reads the kit tables and the team rosters now, before their first use.
function M.prepare()
  read_all()
  roster_kit(0)
end

--- Advanced: The kit of card `card` (in team `team` when given); nil when it has none.
function M.of(card, team)
  card, team = u32(card), u32(team)
  local cache_key = team ~= 0 and (card .. ":" .. team) or card
  local c = CACHE[cache_key]
  if c ~= nil then return c[1], c[2], c[3] end
  read_all()
  local u, src, flags = nil, "none", 0
  if team ~= 0 then
    u = team_kit(team)
    if u then src = "team" end
  end
  local p = D.card[card]
  local own = false
  if p ~= nil then
    if u == nil then
      local b = belong_kit(p[1])
      if b then
        u, src = b, "belong"
      elseif b == false then
        own, src = true, "own"
      end
    end
    if p[2] == 1 then flags = 2 end
  end
  if u == nil and not own and card ~= 0 then
    u = roster_kit(card)
    if u then src = "roster" end
  end
  if u == nil then flags = 0 end
  -- staff cards: the coach's / manager's own clothes (the costume the game looks up with that bit)
  if p ~= nil and p[3] then
    flags = 16
  elseif p ~= nil and p[4] then
    flags = 32
  end
  CACHE[cache_key] = { u or 0, flags, src }
  return u or 0, flags, src
end

return M
