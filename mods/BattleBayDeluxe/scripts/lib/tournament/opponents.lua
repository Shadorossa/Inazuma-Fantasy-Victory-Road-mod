-- The Tournament's opponents: team levels and strength, the story teams and the filtered opponent list.
local Shared = require "lib/tournament/context"
local U = require "lib/util"
local Catalogue = Shared.Catalogue
local Tn = Shared.Tn
local info = Shared.info
local warn = Shared.warn
local CFG = Shared.CFG

local function mk(h, l)
  return U.rng(h, l)
end

local LEVELS = nil

local function team_rows()
  local rows, why = Catalogue.team_rows()
  if rows then
    return true, rows
  end
  return false, why
end

-- team -> level (team_config col 8 "level" as the game loads it, the mods' teams included)
local function levels()
  if LEVELS then
    return LEVELS
  end
  LEVELS = {}
  local ok, rows = team_rows()
  if ok and type(rows) == "table" then
    for _, r in ipairs(rows) do
      local id, lv = r.id or r[1], r.level or r[9]
      if type(id) == "number" and type(lv) == "number" then
        LEVELS[VRFW.ids.unsigned(id)] = lv
      end
    end
  else
    warn("team table not readable: team levels left out of the strength")
  end
  return LEVELS
end

-- a team's strength: its level
local function strength(team)
  return levels()[team] or 0
end

-- "Filter minor teams".
local STORY = nil

local function glob_match(pat, s)
  local lp = "^" .. tostring(pat):gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0"):gsub("%*", ".*") .. "$"
  return tostring(s):match(lp) ~= nil
end

local function story_set()
  if STORY then
    return STORY
  end
  STORY = { teams = {}, names = {}, games = 0, n = 0 }
  local ok, err = pcall(function()
    local games = {}
    local function team(t, set)
      t = VRFW.ids.unsigned(t or 0)
      if t ~= 0 then
        STORY.teams[t] = true
      end
    end
    for _, r in ipairs(VRFW.table.rows("vsroute/vs_route_piece_event")) do
      local g = VRFW.ids.unsigned(r.paramCrc1 or r[1] or 0)
      if g ~= 0 then
        games[g] = true
      end
      team(r.paramCrc2 or r[2])
    end
    local globs = CFG.story_games
    if #globs > 0 then
      for _, r in ipairs(VRFW.table.rows("soccer/soccer_game_info")) do
        local name = r.name or r[2]
        for _, gl in ipairs(globs) do
          if type(name) == "string" and glob_match(gl, name) then
            games[VRFW.ids.unsigned(r.id or r[1])] = true
          end
        end
      end
    end
    local key = VRFW.table.source("soccer/soccer_game_info")
    local cur, slice, diffs = nil, {}, {}
    for _, e in ipairs(VRFW.table.entries(key, { "SOCCER_GAME_INFO", "SOCCER_GAME_INFO_REF_DIFFICULTY",
      "SOCCER_GAME_DIFFICULTY" }, true)) do
      if e.name == "SOCCER_GAME_INFO" then
        cur = VRFW.ids.unsigned(e[1] or 0)
      elseif e.name == "SOCCER_GAME_INFO_REF_DIFFICULTY" then
        if cur then
          slice[cur] = { e[1] or 0, e[2] or 0 }
        end
      elseif e.name == "SOCCER_GAME_DIFFICULTY" then
        diffs[#diffs + 1] = { e[2], e[6] }
      end
    end
    for g in pairs(games) do
      local sl = slice[g]
      if sl then
        STORY.games = STORY.games + 1
        for k = sl[1] + 1, sl[1] + sl[2] do
          local d = diffs[k]
          if d then
            team(d[1])
            team(d[2])
          end
        end
      end
    end
    -- the name texts of those teams
    local okT, trows = team_rows()
    if not okT then
      error(trows, 0)
    end
    for _, r in ipairs(trows) do
      local id = VRFW.ids.unsigned(r.id or r[1] or 0)
      if STORY.teams[id] then
        local nt = VRFW.ids.unsigned(r.name_text or r[4] or 0)
        if nt ~= 0 then
          STORY.names[nt] = true
        end
      end
    end
    for _ in pairs(STORY.teams) do
      STORY.n = STORY.n + 1
    end
  end)
  if not ok then
    warn("minor teams filter: the story / Chronicle teams not readable (" .. tostring(err) .. "): no team counts as one")
  else
    info(string.format("minor teams filter: %d story / Chronicle teams from %d games", STORY.n, STORY.games))
  end
  return STORY
end

local NAME_TEXT = nil
local function name_text(t)
  if not NAME_TEXT then
    NAME_TEXT = {}
    local ok, rows = team_rows()
    if ok and type(rows) == "table" then
      for _, r in ipairs(rows) do
        NAME_TEXT[VRFW.ids.unsigned(r.id or r[1] or 0)] = VRFW.ids.unsigned(r.name_text or r[4] or 0)
      end
    end
  end
  return NAME_TEXT[t] or 0
end
Tn.name_text = name_text

local function is_story(t)
  local S = story_set()
  if S.teams[t] then
    return true
  end
  local nt = name_text(t)
  return nt ~= 0 and S.names[nt] == true
end
Tn.is_story = is_story

local function filtered_opponents(v, n)
  local story, rest = {}, {}
  for _, t in ipairs(v) do
    if is_story(t) then
      story[#story + 1] = t
    else
      rest[#rest + 1] = { t = t, s = strength(t), k = #rest }
    end
  end
  local out = {}
  for i = 1, math.min(n, #story) do
    out[#out + 1] = story[i]
  end
  if #out < n then
    table.sort(rest, function(a, b)
      if a.s ~= b.s then
        return a.s > b.s
      end
      return a.k < b.k
    end)
    for i = 1, n - #out do
      if rest[i] then
        out[#out + 1] = rest[i].t
      end
    end
  end
  info(string.format("minor teams filter: %d of %d story / Chronicle candidates, %d strongest of the rest", math.min(n,
    #story), #story, math.max(0, n - #story)))
  return out
end

-- The names the later parts of the Tournament read.
Shared.mk = mk
Shared.team_rows = team_rows
Shared.levels = levels
Shared.strength = strength
Shared.story_set = story_set
Shared.name_text = name_text
Shared.filtered_opponents = filtered_opponents
