-- Advanced: Clubs: the versions of one club are every team whose crest is one club's crest in the game's belong_team table, plus the mods' [[VRFW.TeamClub]] declarations.

local M = {}

local u32 = VRFW.ids.unsigned
local Catalogue = VRFW.catalogue

local CLUB = nil      -- team id -> the club's first team id (team table order)
local MEMBERS = nil   -- the club's first team id -> every team id of the club

-- The crest family of emblem `e`: its item key without a final variant letter (em110001a -> em110001), else its id.
local function crest_family(e)
  local key = Catalogue.emblem_key(e)
  if type(key) == "string" and key ~= "" then return "c:" .. (key:match("^(.-%d)[a-z]$") or key) end
  return string.format("e:%08X", e)
end

-- A declared team reference (game key, 0x… id or <mod>.<name>) as a team id; nil when unusable.
local function team_ref(t)
  local id = nil
  if type(t) == "string" and t:find(".", 1, true) then id = VRFW.teams.ids.of(t) end
  id = id or Catalogue.id_value(t)
  return id and id ~= 0 and u32(id) or nil
end

-- Every active mod's declared clubs: a list of team id lists.
local function declared()
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, "content/team_clubs")
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local data = type(f.data) == "table" and f.data or {}
    local list = type(data.VRFW) == "table" and data.VRFW.TeamClub or nil
    for _, d in ipairs(type(list) == "table" and list or {}) do
      if type(d) == "table" and type(d.teams) == "table" then
        local ids = {}
        for _, t in ipairs(d.teams) do
          local id = team_ref(t)
          if id then ids[#ids + 1] = id end
        end
        if #ids > 0 then out[#out + 1] = ids end
      end
    end
  end
  return out
end

local function build()
  if CLUB then return end
  CLUB, MEMBERS = {}, {}
  local rows, why = Catalogue.team_rows()
  if type(rows) ~= "table" then
    VRFW.warn("clubs: the team table is not readable (" .. tostring(why) .. "): every team is its own club")
    return
  end
  local root, order = {}, {}
  local function find(x)
    while root[x] ~= x do x = root[x] end
    return x
  end
  local function join(a, b)
    if root[a] == nil then root[a] = a end
    if root[b] == nil then root[b] = b end
    a, b = find(a), find(b)
    if a ~= b then root[b] = a end
  end
  -- the belong_team table: every crest of one club (per era) is that club
  for _, b in ipairs(Catalogue.teams()) do
    for _, e in ipairs(b.emblems or {}) do
      if u32(e) ~= 0 then join("b:" .. string.format("%08X", u32(b.id)), crest_family(u32(e))) end
    end
  end
  local decl, own = declared(), {}
  for _, ids in ipairs(decl) do
    for _, id in ipairs(ids) do own[id] = true end
  end
  for _, r in ipairs(rows) do
    local id = u32(r.id or r[1] or 0)
    if id ~= 0 and root[id] == nil then
      root[id] = id
      order[#order + 1] = id
      local e = u32(r.emblem or r[7] or 0)
      if e ~= 0 and not own[id] then join(crest_family(e), id) end
    end
  end
  -- a declared club holds its teams only: they leave the club of their crest
  for _, ids in ipairs(decl) do
    for i = 2, #ids do
      if root[ids[1]] ~= nil and root[ids[i]] ~= nil then join(ids[1], ids[i]) end
    end
  end
  local first, n = {}, 0
  for _, id in ipairs(order) do
    local r = find(id)
    local c = first[r]
    if not c then
      c = id
      first[r] = id
    end
    CLUB[id] = c
    local list = MEMBERS[c]
    if not list then
      list = {}
      MEMBERS[c] = list
      n = n + 1
    end
    list[#list + 1] = id
  end
  VRFW.debug(string.format("clubs: %d teams in %d clubs (%d declared)", #order, n, #decl))
end

--- Advanced: The club of team `team`: the first team id of its club in team table order (team itself when it has no other).
function M.of_team(team)
  build()
  team = u32(team or 0)
  return CLUB[team] or team
end

--- Internal: Every team of the club of team `team` (team table order; { team } when it has no other).
function M.teams(team)
  build()
  team = u32(team or 0)
  return MEMBERS[CLUB[team] or 0] or { team }
end

--- Internal: True when teams `a` and `b` are versions of one club.
function M.same(a, b)
  return M.of_team(a) == M.of_team(b)
end

return M
