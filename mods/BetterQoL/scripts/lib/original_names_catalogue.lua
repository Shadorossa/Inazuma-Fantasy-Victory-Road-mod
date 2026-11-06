-- BetterQoL › original names: the picker model (series pages, their team rows, the characters) and the selection.
-- The game's series, belong teams, eras and crests come from the framework's game catalogue (VRFW/lib/game_catalogue,
-- docs/framework/game-catalogue.md); the characters from chara_base and the mods' card_filters\ declarations; no game
-- memory. Ids are unsigned 32-bit numbers.
--
-- A selection is per player: { [chara_base id] = true } (since BetterQoL 1.6.0; before, whole series and teams).

local M = {}

local CHARA_TABLE = "character/chara_base"

local Id = require "VRFW/lib/ids"
local Catalogue = require "VRFW/lib/game_catalogue"

-- a page of a series type without a crest era of its own: Catalogue.crest then takes the team's latest era with one
local NO_ERA = 0

local function u32(v)
  if type(v) ~= "number" then
    return 0
  end
  return Id.u32(v)
end
M.u32 = u32

local trim = require("VRFW/lib/basics").value.trim
M.trim = trim

-- the game's series (chara_series rows: { id, ty, name_text }) and belong teams ({ id, name_text, numbers, emblems,
-- kits }), read once per VM by the framework's game catalogue
M.series_rows = Catalogue.series
M.belong_rows = Catalogue.teams

local function truthy(v)
  return v == true or (type(v) == "number" and v ~= 0)
end

-- the characters of chara_base: { n1, n2, n3 (name / short / upper name text ids), series, t1, t2, t3 (belong teams),
-- id (the chara_base key: the selection's key and the face icon's) } plus
--   person = the person key: the Japanese full name (`ja_rows` = chara_text rows of ja, `strip` = furigana reducer);
--            every variant of one person (sagas, outfits, alternate versions) has the same Japanese name. No ja text:
--            the name text id (the row is its own person).
--   base   = the main row of its person: an internal key without a `_<suffix>` (`_5000`, `_notplayer`) and the
--            alternate-version flag (flag_31) off. Alternate rows have no face icon of their own.
--   serial = serial_no (0 = not a numbered player), games = { [series type k] = true } from the k-th in_<game> column.
function M.charas(ja_rows, strip)
  local games = {}
  for i, n in ipairs(VRFW.table.columns(CHARA_TABLE)) do
    if n:match("^in_") then
      games[#games + 1] = i
    end
  end
  local out = {}
  for _, r in ipairs(VRFW.table.rows(CHARA_TABLE)) do
    local name_text = u32(r.name_text)
    local person
    local t = ja_rows and name_text ~= 0 and ja_rows[name_text]
    local s = t and t[0]
    if type(s) == "string" then
      s = trim(strip and strip(s) or s)
      if s ~= "" then
        person = s
      end
    end
    local key = r.name
    local suffixed = type(key) == "string" and key:find("_", 1, true) ~= nil
    local in_games = {}
    for k, i in ipairs(games) do
      if truthy(r[i]) then
        in_games[k] = true
      end
    end
    out[#out + 1] = {
      name_text, u32(r.short_name_text), u32(r.upper_name_text),
      u32(r.series),
      u32(r.team_1), u32(r.team_2), u32(r.team_3),
      u32(r.id),
      person = person or string.format("#%08x", name_text ~= 0 and name_text or u32(r.id)),
      base = not suffixed and not truthy(r.flag_31),
      serial = type(r.serial_no) == "number" and r.serial_no or 0,
      games = in_games,
    }
  end
  return out
end

-- ------------------------------------------------------------------------------------------- declarations

-- an id written in a declaration: a number, "0x…" / decimal text, or a name (its crc32); nil = none
M.id_value = Catalogue.id_value

-- the (series, team) pairs every active mod declares in card_filters\ (`[[bank_tab]]` / `[[series]]` entries naming
-- both, not hidden), and their count
function M.declarations()
  local out, seen = {}, {}
  for _, d in ipairs(VRFW.files.declarations("card_filters")) do
    local data = type(d.data) == "table" and d.data or {}
    for _, list in ipairs({ "bank_tab", "series" }) do
      local arr = data[list]
      if type(arr) == "table" then
        for _, e in ipairs(arr) do
          if type(e) == "table" and e.hide ~= true then
            local s, t = M.id_value(e.series), M.id_value(e.team)
            if s and t and s ~= 0 and t ~= 0 then
              local k = s .. ":" .. t
              if not seen[k] then
                seen[k] = true
                out[#out + 1] = { s, t }
              end
            end
          end
        end
      end
    end
  end
  return out
end

-- ------------------------------------------------------------------------------------------- the catalogue

-- Tabs from the series table (table order), teams from belong_team_config (k-th teamNumber_ column = series type k),
-- then the characters' own teams, then the declared ones. A series with no team and no character is left out.
-- Members of a series of type k: its own characters (chara_base series) and every character flagged in the k-th
-- in_<game> column (Mark Evans of IE1 is also in IE3). A member's teams on that page are those of his teams numbered
-- for type k (Raimon is not an IE3 team, Inazuma National is not an IE1 one); a member of the series' own with no such
-- team keeps all his teams (unnumbered pages, mods' series), a flagged guest with none is left out.
-- Returns { series = { { id, ty, name_text, teams = {…}, declared = {…}, declared_set, members = { chara index… },
--           member_teams = { [chara index] = { team… } } } }, team_names = { [team] = name text }, charas = {…},
--           person_of = { [chara index] = person index }, persons = { { chara index… } } }
function M.build(series, belong, charas, decls)
  local team_names, order, emblems, numbers = {}, {}, {}, {}
  for i, b in ipairs(belong) do
    team_names[b.id] = b.name_text
    emblems[b.id] = b.emblems
    numbers[b.id] = b.numbers
    if order[b.id] == nil then
      order[b.id] = i
    end
  end
  -- persons: every variant of one person (same Japanese name), chara table order
  local person_of, persons, by_key = {}, {}, {}
  for ci, c in ipairs(charas) do
    local p = by_key[c.person]
    if not p then
      p = #persons + 1
      persons[p] = {}
      by_key[c.person] = p
    end
    local l = persons[p]
    l[#l + 1] = ci
    person_of[ci] = p
  end
  local function is_numbered(t, ty)
    local n = numbers[t]
    return n ~= nil and (n[ty] or 0) > 0
  end
  local out = {}
  for _, s in ipairs(series) do
    local numbered = {}
    if s.ty >= 1 then
      for i, b in ipairs(belong) do
        local n = b.numbers[s.ty]
        if n and n > 0 then
          numbered[#numbered + 1] = { n, i, b.id }
        end
      end
    end
    table.sort(numbered, function(a, b)
      if a[1] ~= b[1] then
        return a[1] < b[1]
      end
      return a[2] < b[2]
    end)
    local teams, in_teams = {}, {}
    for _, x in ipairs(numbered) do
      teams[#teams + 1] = x[3]
      in_teams[x[3]] = true
    end
    local declared, declared_set = {}, {}
    for _, d in ipairs(decls) do
      if d[1] == s.id and not declared_set[d[2]] then
        declared[#declared + 1] = d[2]
        declared_set[d[2]] = true
      end
    end
    local has_decl = #declared > 0
    local extra, in_extra, members, member_teams, has_chara = {}, {}, {}, {}, false
    for ci, c in ipairs(charas) do
      local own = c[4] == s.id
      has_chara = has_chara or own
      local member = own
      if not member and has_decl then
        for k = 5, 7 do
          if c[k] ~= 0 and declared_set[c[k]] then
            member = true
            break
          end
        end
      end
      local guest = not member and s.ty >= 1 and c.games and c.games[s.ty] == true
      if member or guest then
        local mine, all = {}, {}
        for k = 5, 7 do
          local t = c[k]
          if t ~= 0 then
            all[#all + 1] = t
            if s.ty >= 1 and is_numbered(t, s.ty) then
              mine[#mine + 1] = t
            end
          end
        end
        if #mine == 0 and member then
          mine = all
        end
        if #mine > 0 then
          members[#members + 1] = ci
          member_teams[ci] = mine
          for _, t in ipairs(mine) do
            if not in_teams[t] and not in_extra[t] and not declared_set[t] then
              in_extra[t] = #extra + 1
              extra[#extra + 1] = t
            end
          end
        end
      end
    end
    -- by belong table order (stable: first seen first among unknown ones)
    table.sort(extra, function(a, b)
      local oa, ob = order[a] or math.huge, order[b] or math.huge
      if oa ~= ob then
        return oa < ob
      end
      return in_extra[a] < in_extra[b]
    end)
    for _, t in ipairs(extra) do
      teams[#teams + 1] = t
      in_teams[t] = true
    end
    for _, t in ipairs(declared) do
      if not in_teams[t] then
        teams[#teams + 1] = t
        in_teams[t] = true
      end
    end
    if #teams > 0 or has_chara then
      out[#out + 1] = {
        id = s.id, ty = s.ty, name_text = s.name_text,
        teams = teams, declared = declared, declared_set = declared_set, members = members,
        member_teams = member_teams,
      }
    end
  end
  return { series = out, team_names = team_names, charas = charas, emblems = emblems,
           person_of = person_of, persons = persons }
end

-- the variant that shows person `p` in a row of series `s`: among `cands` (chara indices of the row) a main row
-- (c.base) first, then one of the series' own, then the lowest serial_no, then table order; when every candidate is an
-- alternate row (no face icon of its own), the person's best main row anywhere
local function better(cat, s, a, b)
  local ca, cb = cat.charas[a], cat.charas[b]
  if (ca.base == true) ~= (cb.base == true) then
    return ca.base == true
  end
  local oa, ob = ca[4] == s.id, cb[4] == s.id
  if oa ~= ob then
    return oa
  end
  local sa = (ca.serial or 0) > 0 and ca.serial or math.huge
  local sb = (cb.serial or 0) > 0 and cb.serial or math.huge
  if sa ~= sb then
    return sa < sb
  end
  return a < b
end

local function face_of(cat, s, p, cands)
  local best = cands[1]
  for i = 2, #cands do
    if better(cat, s, cands[i], best) then
      best = cands[i]
    end
  end
  if cat.charas[best].base ~= true then
    for _, ci in ipairs(cat.persons[p] or {}) do
      if cat.charas[ci].base == true and better(cat, s, ci, best) then
        best = ci
      end
    end
  end
  return best
end

-- every chara_base key of the person of chara index `ci`
function M.person_ids(cat, ci)
  local out = {}
  local p = cat.person_of and cat.person_of[ci]
  for _, x in ipairs(p and cat.persons[p] or { ci }) do
    local id = cat.charas[x][8]
    if id ~= 0 then
      out[#out + 1] = id
    end
  end
  return out
end

-- ------------------------------------------------------------------------------------------- the picker's rows

-- every team row of series `s` where the person plays (cached on it as s.rows_all): { { team, players = { chara
-- index… }, persons = { person index… }, cands = { [person] = { chara index… } } }, … } in the series' team order. A row
-- lists each PERSON once (every variant of him the row has is one cell), in the order his first variant appears in
-- chara_base; `players[j]` is the variant whose face the cell shows (face_of). A person is in the row when one of his
-- variants is a member of the series with the row's team among his page teams (s.member_teams); a team without players
-- is left out. Here a player of several teams or series is in each of their rows (the team names use these rows).
local function rows_all(cat, s)
  if s.rows_all then
    return s.rows_all
  end
  local by = {}
  for _, ci in ipairs(s.members) do
    local p = cat.person_of and cat.person_of[ci] or -ci
    for _, t in ipairs(s.member_teams and s.member_teams[ci] or {}) do
      local b = by[t]
      if not b then
        b = { order = {}, cands = {} }
        by[t] = b
      end
      local l = b.cands[p]
      if not l then
        l = {}
        b.cands[p] = l
        b.order[#b.order + 1] = p
      end
      if l[#l] ~= ci then
        l[#l + 1] = ci
      end
    end
  end
  local rows = {}
  for _, t in ipairs(s.teams) do
    local b = by[t]
    if b and #b.order > 0 then
      local players, persons = {}, {}
      for _, p in ipairs(b.order) do
        persons[#persons + 1] = p
        players[#players + 1] = p > 0 and face_of(cat, s, p, b.cands[p]) or b.cands[p][1]
      end
      rows[#rows + 1] = { team = t, players = players, persons = persons, cands = b.cands }
    end
  end
  s.rows_all = rows
  return rows
end
M.rows_all = rows_all

-- the order in which series claim a person: series type (the k-th teamNumber_ / in_<game> column, IE1 … Victory Road,
-- the games' release order) first, then table order; a series without a type (a mod's) after every typed one
local function claim_order(cat)
  local idx = {}
  for i = 1, #cat.series do
    idx[i] = i
  end
  table.sort(idx, function(a, b)
    local ta, tb = cat.series[a].ty, cat.series[b].ty
    ta = (ta or 0) >= 1 and ta or math.huge
    tb = (tb or 0) >= 1 and tb or math.huge
    if ta ~= tb then
      return ta < tb
    end
    return a < b
  end)
  return idx
end

-- the HOME of every person: the one (series, team row) where his cell shows. A switch covers every variant of the
-- person in the whole game, so he is listed once: in the earliest series where he plays (claim_order), in his own team
-- there: the first team (team_1, team_2, team_3 order) of the variant that shows his face on that page that has a row
-- with him, else the first row with him in the series' team order. Sets s.rows (the rows of each page with only the
-- persons at home there; a row left without players is dropped) and cat.home = { [person] = { series index, team } }.
function M.assign(cat)
  if cat.home then
    return cat.home
  end
  local home = {}
  for _, si in ipairs(claim_order(cat)) do
    local s = cat.series[si]
    local rows = rows_all(cat, s)
    local has = {}          -- person -> { [team] = true } for the rows of this page
    local cands = {}        -- person -> every variant of him on this page
    local first = {}        -- person -> the first team (series order) with a row for him
    for _, r in ipairs(rows) do
      for _, p in ipairs(r.persons) do
        if home[p] == nil then
          local h = has[p]
          if not h then
            h = {}
            has[p] = h
            cands[p] = {}
            first[p] = r.team
          end
          h[r.team] = true
          for _, ci in ipairs(r.cands[p] or {}) do
            cands[p][#cands[p] + 1] = ci
          end
        end
      end
    end
    for p, h in pairs(has) do
      local team = first[p]
      if p > 0 then
        local face = face_of(cat, s, p, cands[p])
        for _, t in ipairs(s.member_teams[face] or {}) do
          if h[t] then
            team = t
            break
          end
        end
      end
      home[p] = { si, team }
    end
  end
  for si, s in ipairs(cat.series) do
    local out = {}
    for _, r in ipairs(rows_all(cat, s)) do
      local players, persons = {}, {}
      for j, p in ipairs(r.persons) do
        local h = home[p]
        if h and h[1] == si and h[2] == r.team then
          players[#players + 1] = r.players[j]
          persons[#persons + 1] = p
        end
      end
      if #players > 0 then
        out[#out + 1] = { team = r.team, players = players, persons = persons }
      end
    end
    s.rows = out
  end
  cat.home = home
  return home
end

-- the team rows of series `s` the picker shows: { { team, players = { chara index… }, persons = { person index… } }, … }
-- in the series' team order, each person only at his home (M.assign): one cell per person in the whole picker
function M.rows(cat, s)
  if not s.rows then
    M.assign(cat)
  end
  return s.rows
end

-- the team's crest (item_emblem id) on a page of series type `ty`: the framework's crest of the team in the era that
-- type serves (a mod's declared crest, its era crest, a same-name team record's, another era's; only crests the emblem
-- table has); 0 = none (the grid's generic emblem)
function M.team_emblem(_, team, ty)
  return Catalogue.crest(team, Catalogue.era_of_type(ty) or NO_ERA)
end

-- ------------------------------------------------------------------------------------------- selections
-- A selection is per PLAYER: { [chara_base id] = true }.

function M.count(chosen)
  local n = 0
  for _ in pairs(chosen) do
    n = n + 1
  end
  return n
end

function M.copy(chosen)
  local c = {}
  for id in pairs(chosen) do
    c[id] = true
  end
  return c
end

local function sorted_keys(set)
  local out = {}
  for k in pairs(set) do
    out[#out + 1] = k
  end
  table.sort(out)
  return out
end

-- a canonical text of the selection (equality)
function M.sel_key(chosen)
  local parts = {}
  for _, id in ipairs(sorted_keys(chosen)) do
    parts[#parts + 1] = string.format("%08x", id)
  end
  return table.concat(parts, ",")
end

-- `chosen` without the ids the catalogue has no character for, and person-complete: a chosen variant chooses every
-- variant of his person (one switch per person in the whole game)
function M.normalize(cat, chosen)
  local out = {}
  for ci, c in ipairs(cat.charas) do
    if c[8] ~= 0 and chosen[c[8]] and not out[c[8]] then
      for _, id in ipairs(M.person_ids(cat, ci)) do
        out[id] = true
      end
    end
  end
  return out
end

-- (on, total) of a list of chara indices
function M.players_on(cat, players, chosen)
  local on = 0
  for _, ci in ipairs(players) do
    if chosen[cat.charas[ci][8]] then
      on = on + 1
    end
  end
  return on, #players
end

-- the chara_text ids of the names of every chosen character (sorted) and the number of characters
function M.chara_name_ids(cat, chosen)
  local ids, n = {}, 0
  for _, c in ipairs(cat.charas) do
    if c[8] ~= 0 and chosen[c[8]] then
      n = n + 1
      for k = 1, 3 do
        if c[k] ~= 0 then
          ids[c[k]] = true
        end
      end
    end
  end
  return sorted_keys(ids), n
end

-- the team_text ids of the teams every player of which is chosen (in every series row of the team, each player of the
-- team counted, also those listed at another home), sorted; `all` = every team («Originales»)
function M.team_name_ids(cat, chosen, all)
  local full = {}
  for _, s in ipairs(cat.series) do
    for _, r in ipairs(rows_all(cat, s)) do
      local on, n = M.players_on(cat, r.players, chosen)
      if all or (n > 0 and on == n) then
        if full[r.team] == nil then
          full[r.team] = true
        end
      else
        full[r.team] = false
      end
    end
    if all then
      for _, t in ipairs(s.teams) do
        full[t] = true
      end
    end
  end
  local ids = {}
  for t, ok in pairs(full) do
    local nm = cat.team_names[t]
    if ok and nm and nm ~= 0 then
      ids[nm] = true
    end
  end
  return sorted_keys(ids)
end

-- ------------------------------------------------------------------------------------------- old selections

-- BetterQoL 1.3.0 - 1.5.x chose whole series (names.s.<series>) and teams of a series (names.t.<series>.<team>): the
-- characters such a selection covered (a member of a ticked series, or of a tab where one of its teams is ticked)
function M.legacy_chosen(cat, series, teams)
  local out = {}
  for _, s in ipairs(cat.series) do
    local whole = series[s.id] == true
    local ts = teams[s.id]
    if whole or ts ~= nil then
      for _, ci in ipairs(s.members) do
        local c = cat.charas[ci]
        local on = whole
        if not on then
          for k = 5, 7 do
            if c[k] ~= 0 and ts[c[k]] then
              on = true
              break
            end
          end
        end
        if on and c[8] ~= 0 then
          out[c[8]] = true
        end
      end
    end
  end
  return out
end

-- does series name `name` end with one of `words` (case-insensitive)?
function M.series_matches(name, words)
  local last = trim(name):match("([^%s:]*)$") or ""
  if last == "" then
    return false
  end
  last = last:lower()
  for _, w in ipairs(words) do
    if type(w) == "string" and trim(w):lower() == last then
      return true
    end
  end
  return false
end

-- the series whose name (text rows of chara_add_info_text, variant 0) ends with one of `words`
function M.series_by_words(cat, names, words)
  local out = {}
  for _, s in ipairs(cat.series) do
    local r = names[s.name_text]
    local n = r and r[0]
    if type(n) == "string" and M.series_matches(n, words) then
      out[#out + 1] = s.id
    end
  end
  return out
end

-- ------------------------------------------------------------------------------------------- the picker

-- the picker's editing state: { chosen, start (its key), page (1-based series), row (the open team row, 0 = none) }.
-- It opens on the first series with a chosen player listed, else on the first series with a team row.
function M.picker(cat, chosen)
  local c = M.normalize(cat, chosen)
  local page, any = nil, nil
  for i, s in ipairs(cat.series) do
    local rows = M.rows(cat, s)
    if #rows > 0 and any == nil then
      any = i
    end
    for _, r in ipairs(rows) do
      for _, ci in ipairs(r.players) do
        if c[cat.charas[ci][8]] then
          page = i
          break
        end
      end
      if page then
        break
      end
    end
    if page then
      break
    end
  end
  return { chosen = c, start = M.sel_key(c), page = page or any or 1, row = 0 }
end

-- the page `dir` (-1 / 1) away, wrapping, past the series whose players are all listed elsewhere (no team row)
function M.step_page(cat, p, dir)
  local n = #cat.series
  if n > 0 and dir ~= 0 then
    local page = p.page
    for _ = 1, n do
      page = ((page - 1 + dir) % n) + 1
      if #M.rows(cat, cat.series[page]) > 0 then
        p.page = page
        break
      end
    end
  end
  p.row = 0
end

-- (players on, players) of the picker's series page (each character once)
function M.page_counts(cat, p)
  local s = cat.series[p.page]
  if not s then
    return 0, 0
  end
  local on, n, seen = 0, 0, {}
  for _, r in ipairs(M.rows(cat, s)) do
    for j, ci in ipairs(r.players) do
      local who = r.persons and r.persons[j] or -ci
      if not seen[who] then
        seen[who] = true
        n = n + 1
        if p.chosen[cat.charas[ci][8]] then
          on = on + 1
        end
      end
    end
  end
  return on, n
end

-- player j (1-based) of the open team row: toggled; j = 0: every player of the row (all on, or all off when every
-- one is on). Returns the new state (of player j / of the row), players on, players.
function M.toggle(cat, p, j)
  local s = cat.series[p.page]
  local r = s and M.rows(cat, s)[p.row]
  if not r then
    return false, 0, 0
  end
  -- a switch covers every variant of the person in the whole game
  local function set(ci, on)
    for _, id in ipairs(M.person_ids(cat, ci)) do
      p.chosen[id] = on or nil
    end
  end
  local state
  if j == 0 then
    local on, n = M.players_on(cat, r.players, p.chosen)
    state = on < n
    for _, ci in ipairs(r.players) do
      set(ci, state)
    end
  else
    local ci = r.players[j]
    local id = ci and cat.charas[ci][8] or 0
    if id == 0 then
      return false, M.players_on(cat, r.players, p.chosen)
    end
    state = not p.chosen[id]
    set(ci, state)
  end
  local on, n = M.players_on(cat, r.players, p.chosen)
  return state, on, n
end

function M.changed(p)
  return M.sel_key(p.chosen) ~= p.start
end

return M
