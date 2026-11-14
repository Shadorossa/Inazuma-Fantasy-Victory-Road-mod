
local C = require "lib/tp_core"
local Cat = require "lib/original_names_catalogue"
local Catalogue = VRFW.catalogue
local RealPlayers = VRFW.real_players
local T = require "lib/original_names_tables"
local GameText = VRFW.names
local Fold = VRFW.text_fold

BetterQoL = BetterQoL or {}
BetterQoL.Album = BetterQoL.Album or {}

local PLAYER_KIND = 10
local DEFAULT_TEAM_PAGE_MIN_PLAYERS = 11
local SEARCH_KIND = 4
local NO_RANK = math.huge
local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

local int, u32 = C.int, VRFW.ids.unsigned
local chars, fold = Fold.chars, Fold.fold_upper

local info, warn = VRFW.logger("album")

local roster = nil
local bases = {}         -- [lang] = language_base(lang)
local names = {}         -- [lang] = language(...)
local view = nil         -- the opening's language state
local view_owned = nil   -- the club's cards read at the opening
local view_level, view_rarity, view_counts = 1, 0, {}
local search_group = nil
local view_groups = nil   -- the opening's groups under the filter in force (nil: no filter)

-- t[key] when it is a table, else an empty one
local function list_of(t, key)
  local v = type(t) == "table" and t[key] or nil
  return type(v) == "table" and v or {}
end

local function declarations(paths)
  local ok, decls = pcall(VRFW.files.declarations, paths)
  return ok and type(decls) == "table" and decls or {}
end

local function album_config()
  return VRFW.config("album", {})
end

local function first_team(teams)
  for _, t in ipairs(teams) do
    if t ~= 0 then
      return t
    end
  end
  return nil
end

local function count(list, have)
  local n = 0
  for _, e in ipairs(list) do
    if have[e] then
      n = n + 1
    end
  end
  return n
end

local function card_values()
  return C.rule(VRFW.config("team_planner"), declarations({ "content/team_planner", "team_planner" })).card_values
end

local function series_row(series_id)
  for _, r in ipairs(Cat.series_rows()) do
    if r.id == series_id then
      return r
    end
  end
  return nil
end

-- [mod] = { character ids } of its content/characters [[character]] entries (base.id, else crc32 of base.name)
local function declared_characters()
  local out = {}
  for _, d in ipairs(declarations({ "content/characters" })) do
    local list = out[d.mod] or {}
    out[d.mod] = list
    for _, ch in ipairs(list_of(d.data, "character")) do
      local base = type(ch.base) == "table" and ch.base or {}
      local id = u32(base.id)
      if (id == nil or id == 0) and type(base.name) == "string" then id = u32(VRFW.crc32(base.name)) end
      if id and id ~= 0 then list[#list + 1] = id end
    end
  end
  return out
end

-- the [[series]] categories: members from `cards` rules, `team` and `own_characters`; a base stays in the first claim
local function declared_categories(decls, base_rows, base_of, normal_base)
  local categories, category_of_base = {}, {}
  local mod_characters = nil
  for _, d in ipairs(decls) do
    for _, sd in ipairs(list_of(d.data, "series")) do
      local series_id, team = u32(sd.series), u32(sd.team)
      local row = series_row(series_id)
      local has_rules = type(sd.cards) == "table"
      local own = sd.own_characters == true
      if row == nil or (team == 0 and not has_rules and not own) then
        warn("content/album of mod " .. tostring(d.mod) .. ": series " .. string.format("0x%08X", series_id or 0)
          .. " not in chara_series_config or none of cards, team, own_characters (skipped)")
      else
        local category = { row = row, mod = d.mod, exclusive = sd.exclusive ~= false,
                           kit_from_own_teams = sd.kit_from_own_teams ~= false, bases = {},
                           page = math.max(1, int(sd.page) or 1) }
        local function claim(base)
          if base and base ~= 0 and normal_base[base] and category_of_base[base] == nil then
            category_of_base[base] = category
            category.bases[base] = true
          end
        end
        if has_rules then
          local ok, selected = pcall(VRFW.character.select, sd.cards)
          if ok and type(selected) == "table" then
            for _, card_id in ipairs(selected) do
              claim(base_of[u32(card_id)])
            end
          else
            warn("content/album of mod " .. tostring(d.mod) .. ": cards not selected (" .. tostring(selected) .. ")")
          end
        end
        if own then
          local excepted = {}
          for _, card_id in ipairs(list_of(sd, "except_cards")) do
            excepted[base_of[u32(card_id)] or 0] = true
          end
          mod_characters = mod_characters or declared_characters()
          for _, base in ipairs(mod_characters[d.mod] or {}) do
            if not excepted[base] then
              claim(base)
            end
          end
        end
        if team ~= 0 then
          for _, r in ipairs(base_rows) do
            if u32(r.team_1) == team or u32(r.team_2) == team or u32(r.team_3) == team then
              claim(u32(r.id))
            end
          end
        end
        categories[#categories + 1] = category
      end
    end
  end
  return categories, category_of_base
end

-- [card] = crc32(key) of the first content/teams [[team]] of `mod` whose roster lists the card
local function own_team_of_cards(mod)
  local out = {}
  for _, d in ipairs(declarations({ "content/teams" })) do
    if d.mod == mod then
      for _, team in ipairs(list_of(d.data, "team")) do
        local team_id = type(team.key) == "string" and u32(VRFW.crc32(team.key)) or 0
        if team_id ~= 0 then
          for _, member in ipairs(list_of(team, "member")) do
            local card_id = u32(member.card)
            if card_id ~= 0 and out[card_id] == nil then
              out[card_id] = team_id
            end
          end
        end
      end
    end
  end
  return out
end

local function hidden_rarities(decls)
  local hidden, signature = {}, {}
  for _, d in ipairs(decls) do
    for _, rule in ipairs(list_of(d.data, "hide_rarities")) do
      local key = type(rule.option) == "string" and rule.option or ""
      local ok, value
      if type(rule.config) == "string" then
        key = rule.config
        ok, value = pcall(VRFW.files.config, key, tostring(d.mod))
      else
        ok, value = pcall(VRFW.option, key)
      end
      value = ok and value or nil
      signature[#signature + 1] = key .. "=" .. tostring(value)
      for _, case in ipairs(list_of(rule, "when")) do
        local applies = false
        for _, v in ipairs(list_of(case, "values")) do
          if value ~= nil and (v == value or (tonumber(v) ~= nil and tonumber(v) == tonumber(value))) then applies = true end
        end
        if applies then
          for _, rarity in ipairs(list_of(case, "rarities")) do
            hidden[int(rarity) or -1] = true
          end
        end
      end
    end
  end
  return hidden, table.concat(signature, ",")
end

local album_decls = nil
local function album_declarations()
  album_decls = album_decls or declarations({ "content/album" })
  return album_decls
end

-- a chara_base row the album may list: a player with a serial number (0 = the avatars) and a name
local function is_album_player(r)
  return int(r.kind) == PLAYER_KIND and (int(r.serial_no) or 0) > 0 and u32(r.name_text) ~= 0
end

-- chara_body.body_group -> the filter's build value (the game's own grouping, nie.exe 0x1123250)
local BODY_BUILD = { [0] = 1, 1, 2, 6, 4, 5, 3, 5, 5, 3, 2, 6, 3, 3, 4, 5, 5, 5 }
local GENDER_OTHER = 3

-- sets e.filter = { position, element, gender, build } on every row from the served tables (mods' characters included)
local function set_filter_fields(lists)
  -- only the columns read below: whole rows of these four tables do not fit the script's memory together
  local function by_id(table_id, columns)
    local out = {}
    local ok, rows = pcall(VRFW.table.rows, table_id, columns)
    if ok and type(rows) == "table" then
      for _, r in ipairs(rows) do out[u32(r.id)] = r end
    else
      warn("table not read for the filter: " .. table_id .. ": " .. tostring(rows))
    end
    return out
  end
  local params, chara_bases = by_id("character/chara_param", { "id", "main_position", "element" }),
    by_id("character/chara_base", { "id", "model", "gender" })
  local models, bodies = by_id("character/chara_model", { "id", "body" }), by_id("character/chara_body", { "id", "body_group" })
  for _, list in ipairs(lists) do
    for _, e in ipairs(list) do
      local param, base = params[u32(e.param or 0)], chara_bases[u32(e.base or 0)]
      local model = base and models[u32(base.model)] or nil
      local body = model and bodies[u32(model.body)] or nil
      local gender = base and int(base.gender) or 0
      e.filter = { position = param and int(param.main_position) or 0, element = param and int(param.element) or 0,
                   gender = (gender == 1 or gender == 2) and gender or GENDER_OTHER,
                   build = body and BODY_BUILD[int(body.body_group) or -1] or 0 }
    end
  end
end

local function build()
  local params, base_of, excluded = {}, {}, {}
  local edecls = album_declarations()
  local hidden, hidden_signature = hidden_rarities(edecls)
  for _, d in ipairs(edecls) do
    for _, id in ipairs(list_of(d.data, "exclude_cards")) do
      excluded[u32(id)] = true
    end
  end
  local shown_rarity = int(album_config().display_rarity) or 0
  local special_cards = {}        -- { param, base, rarity } of the cards above the shown rarity
  local is_special = {}
  for _, c in ipairs(VRFW.character.cards()) do
    local p, b = u32(c.id), u32(c.base)
    local rar = int(c.rarity) or 0
    if p ~= 0 and b ~= 0 and not excluded[p] then
      base_of[p] = b
      if not hidden[rar] then
        params[#params + 1] = { p, b, rar }
        if rar > shown_rarity then
          special_cards[#special_cards + 1] = { p, b, rar }
          is_special[p] = true
        end
      end
    end
  end
  local own_row = {}
  for _, d in ipairs(edecls) do
    for _, id in ipairs(list_of(d.data, "own_row_cards")) do
      local b = base_of[u32(id)]
      if b then own_row[b] = true end
    end
  end
  local card = C.card_params(params, card_values())
  local cat = Cat.build(Cat.series_rows(), Cat.belong_rows(), Cat.charas(), {})
  local series_of = {}
  for si, s in ipairs(cat.series) do
    series_of[s.id] = si
  end
  local rows = VRFW.table.rows("character/chara_base")
  local normal_base = {}
  for _, pc in ipairs(params) do
    if pc[3] <= shown_rarity then normal_base[pc[2]] = true end
  end
  local categories, category_of_base = declared_categories(edecls, rows, base_of, normal_base)
  local listed, not_real = {}, 0
  for _, r in ipairs(rows) do
    local b = u32(r.id)
    if card[b] and is_album_player(r) and (series_of[u32(r.series)] or category_of_base[b]) then
      if RealPlayers.of_character(b) == false then
        not_real = not_real + 1
      else
        listed[b] = true
      end
    end
  end
  -- one row per face (internal name + name text); a category's character folds only into his own category
  local entries, by_base, by_face, fold_into = {}, {}, {}, {}
  local order_of = {}
  local folded = 0
  for _, r in ipairs(rows) do
    local b = u32(r.id)
    if listed[b] then
      local voice, model = u32(r.voice_bank), u32(r.model)
      local category = category_of_base[b]
      local into = nil
      local face = tostring(r.name) .. "\0" .. u32(r.name_text)
      if own_row[b] then
        into = nil
      elseif category then
        category.by_model = category.by_model or {}
        if voice ~= 0 and voice ~= b and listed[voice] and category_of_base[voice] == category then
          into = voice
        elseif model ~= 0 then
          into = category.by_model[model]
        end
      else
        into = by_face[face]
      end
      if into then
        fold_into[b] = into
        folded = folded + 1
      else
        local e = { base = b, param = card[b], name_text = u32(r.name_text), si = series_of[u32(r.series)],
                    teams = { u32(r.team_1), u32(r.team_2), u32(r.team_3) }, bases = { b }, category = category,
                    game_name_text = category and category.row.name_text or nil }
        entries[#entries + 1] = e
        by_base[b] = e
        order_of[e] = { sort = int(r.sort_order) or 0, serial = int(r.serial_no) or 0, index = #entries }
        if not own_row[b] then
          if category then
            if model ~= 0 then category.by_model[model] = b end
          else
            by_face[face] = b
          end
        end
      end
    end
  end
  for _, category in ipairs(categories) do
    if category.kit_from_own_teams then
      category.team_of_card = own_team_of_cards(category.mod)
      for _, e in ipairs(entries) do
        if e.category == category then
          e.dress_team = category.team_of_card[e.param]
        end
      end
    end
  end
  for b, into in pairs(fold_into) do
    local e = by_base[into]
    local hops = 0
    while e == nil and fold_into[into] and hops < 8 do
      into = fold_into[into]
      e = by_base[into]
      hops = hops + 1
    end
    if e then
      e.bases[#e.bases + 1] = b
      by_base[b] = e
    end
  end
  -- a character with only special cards has no row: his cards go to "Specials" under his own face and name
  local has_card = {}
  for _, b in pairs(base_of) do
    has_card[b] = true
  end
  local special_only, special_players = {}, {}
  for _, r in ipairs(rows) do
    local b = u32(r.id)
    local si = series_of[u32(r.series)]
    if has_card[b] and not card[b] and not special_only[b] and si and is_album_player(r)
        and RealPlayers.of_character(b) ~= false then
      local e = { base = b, name_text = u32(r.name_text), si = si, voice = u32(r.voice_bank),
                  teams = { u32(r.team_1), u32(r.team_2), u32(r.team_3) } }
      e.team = first_team(e.teams)
      special_only[b] = e
      special_players[#special_players + 1] = e
    end
  end
  local of_param = {}
  for p, b in pairs(base_of) do
    local e = by_base[b]
    if e == nil and special_only[b] then
      local player = by_base[special_only[b].voice]
      if player and player.category == nil then
        e = player
      end
    end
    -- a special card ticks its own "Specials" row only
    if e and (not is_special[p] or e.param == p) then
      of_param[p] = e
    end
  end
  -- "Game": each series' players by the series' team order, then sort_order (0 last), serial_no, table order
  local series = {}
  for si, s in ipairs(cat.series) do
    local team_rank = {}
    for i, t in ipairs(s.teams) do
      team_rank[t] = i
    end
    local list, rank = {}, {}
    for _, e in ipairs(entries) do
      if e.si == si and (e.category == nil or not e.category.exclusive) then
        local first, numbered = 0, 0
        for _, t in ipairs(e.teams) do
          if t ~= 0 then
            if first == 0 then first = t end
            local row = numbered == 0 and Catalogue.team(t) or nil
            if row and (row.numbers[s.ty] or 0) > 0 then numbered = t end
          end
        end
        e.team = numbered ~= 0 and numbered or (first ~= 0 and first or nil)
        rank[e] = e.team and team_rank[e.team] or NO_RANK
        list[#list + 1] = e
      end
    end
    table.sort(list, function(a, b)
      if rank[a] ~= rank[b] then return rank[a] < rank[b] end
      local oa, ob = order_of[a], order_of[b]
      local sa, sb = oa.sort > 0 and oa.sort or NO_RANK, ob.sort > 0 and ob.sort or NO_RANK
      if sa ~= sb then return sa < sb end
      if oa.serial ~= ob.serial then return oa.serial < ob.serial end
      return oa.index < ob.index
    end)
    if #list > 0 then
      series[#series + 1] = { si = si, ty = s.ty or 0, name_text = s.name_text, list = list }
    end
  end
  for _, e in ipairs(entries) do
    e.team = e.team or first_team(e.teams)
  end
  -- "Team": one group per team of each series, in the series' team order
  local teams = {}
  for _, s in ipairs(series) do
    local of_team = {}
    for _, e in ipairs(s.list) do
      local t = e.team or 0
      local g = of_team[t]
      if g == nil then
        g = { team = t, ty = s.ty, si = s.si, list = {} }
        of_team[t] = g
        teams[#teams + 1] = g
      end
      g.list[#g.list + 1] = e
    end
  end
  -- the crest that merges a team's pages and the emblem its page shows, kept with the roster
  for _, g in ipairs(teams) do
    local era = Catalogue.era_of_type(g.ty)
    local row = g.team ~= 0 and Catalogue.team(g.team) or nil
    g.crest = (row and era and u32(row.emblems[era] or 0)) or 0
    g.emblem = g.team ~= 0 and Cat.team_emblem(cat, g.team, g.ty) or 0
  end
  for _, category in ipairs(categories) do
    local list = {}
    for _, e in ipairs(entries) do
      if e.category == category then
        list[#list + 1] = e
      end
    end
    info(string.format("declared category 0x%08X (mod %s): %d players", category.row.id, tostring(category.mod), #list))
    if #list > 0 then
      series[#series + 1] = { ty = category.row.ty or 0, name_text = category.row.name_text, list = list,
                               page = category.page }
    end
  end
  local specials, special_of_param, base_of_special = {}, {}, {}
  for _, c in ipairs(special_cards) do
    base_of_special[c[1]] = c[2]
    local e = by_base[c[2]] or special_only[c[2]]
    if e then
      local sp = { base = e.base, param = c[1], rarity = c[3], name_text = e.name_text, si = e.si, team = e.team,
                   teams = e.teams, of = e, special = true, game_name_text = e.game_name_text,
                   dress_team = e.category and e.category.team_of_card and e.category.team_of_card[c[1]] or nil }
      specials[#specials + 1] = sp
      special_of_param[c[1]] = sp
    end
  end
  -- "Specials" in season order (the card's own character's series), then chara_base name, then card id
  local season_of, chara_id_of = {}, {}
  for _, r in ipairs(rows) do
    local b = u32(r.id)
    if season_of[b] == nil then
      season_of[b] = series_of[u32(r.series)] or NO_RANK
      chara_id_of[b] = tostring(r.name or "")
    end
  end
  table.sort(specials, function(a, b)
    local ba, bb = base_of_special[a.param], base_of_special[b.param]
    local sa, sb = season_of[ba] or NO_RANK, season_of[bb] or NO_RANK
    if sa ~= sb then
      return sa < sb
    end
    local ia, ib = chara_id_of[ba] or "", chara_id_of[bb] or ""
    if ia ~= ib then
      return ia < ib
    end
    return a.param < b.param
  end)
  rows = nil
  set_filter_fields({ entries, specials })
  roster = { entries = entries, by_base = by_base, of_param = of_param, series = series, teams = teams, cat = cat,
             specials = specials, special_of_param = special_of_param, special_players = special_players,
             hidden_signature = hidden_signature }
  info(string.format("roster: %d players (%d bases folded into them, %d characters left out as no real player), %d games",
    #entries, folded, not_real, #series))
end

local function ensure_roster()
  local _, signature = hidden_rarities(album_declarations())
  if roster ~= nil and signature ~= roster.hidden_signature then
    info("hidden rarities changed (" .. tostring(roster.hidden_signature) .. " -> " .. signature .. "): roster rebuilt")
    roster, names, bases = nil, {}, {}
  end
  if roster == nil then
    local ok, err = pcall(function()
      roster = VRFW.derived("album_roster", signature, function()
        build()
        return roster
      end)
    end)
    if not ok then
      roster = nil
      warn("no roster (" .. tostring(err) .. ")")
    end
  end
  return roster
end

-- [entry] = { param, level, handle } of the club's highest-level copy of each row
local function owned()
  local out = {}
  local ok, columns = pcall(VRFW.character.saved_columns, { "param", "level", "handle" })
  if ok and type(columns) == "table" then
    for n, param in ipairs(columns.param) do
      local p = u32(param)
      local lv = int(columns.level[n]) or 0
      for _, e in ipairs({ roster.of_param[p] or false, roster.special_of_param[p] or false }) do
        if e and (out[e] == nil or lv > out[e].level) then
          out[e] = { param = p, level = lv, handle = int(columns.handle[n]) }
        end
      end
    end
  else
    warn("saved characters not read (" .. tostring(columns) .. ")")
  end
  return out
end

-- every row shows the base card at the level cap in force ([VRFW.Level] raised cap, else [album] game_level_cap)
local function shown_card()
  local cfg = album_config()
  local level = int(cfg.game_level_cap) or 1
  local okr, raised = pcall(VRFW.state.get, "level.raised")
  local okm, max = pcall(VRFW.state.get, "level.max")
  if okr and okm and raised == 1 and type(max) == "number" and max > level then
    level = math.floor(max)
  end
  return math.max(1, level), int(cfg.display_rarity) or 0
end

-- only the rows `ids` of a text table (chara_text has ~21k rows)
local function text_rows(lang, tbl, ids)
  local ok, rows = pcall(VRFW.files.text_rows, T.text_key(lang, tbl), ids)
  if ok and type(rows) == "table" then
    return rows
  end
  if lang ~= "en" then
    return text_rows("en", tbl, ids)
  end
  return {}
end

local function roster_text_ids()
  if roster.text_ids then
    return roster.text_ids
  end
  local chara, names_seen, other, other_seen = {}, {}, {}, {}
  local function add(list, seen, id)
    if id and id ~= 0 and not seen[id] then
      seen[id] = true
      list[#list + 1] = id
    end
  end
  for _, e in ipairs(roster.entries) do
    add(chara, names_seen, e.name_text)
    add(other, other_seen, e.game_name_text)
  end
  for _, e in ipairs(roster.special_players) do
    add(chara, names_seen, e.name_text)
  end
  for _, text_id in pairs(roster.cat.team_names or {}) do
    add(other, other_seen, u32(text_id))
  end
  for _, s in ipairs(roster.cat.series) do
    add(other, other_seen, s.name_text)
  end
  for _, s in ipairs(roster.series) do
    add(other, other_seen, s.name_text)
  end
  roster.text_ids = { chara = chara, other = other }
  return roster.text_ids
end

local function raw_text_of(rows, id)
  local r = rows and rows[id]
  local s = r and r[0]
  if type(s) == "string" and s ~= "" and s:sub(1, 1) ~= "<" then
    return s
  end
  return nil
end

local function text_of(rows, id)
  local s = raw_text_of(rows, id)
  return s and T.strip_furigana(s)
end

-- the character names the game shows; ids that table lacks (mod names) from the language's own chara table
local function shown_chara_rows(lang, ids)
  local key = T.shown_chara_key(lang)
  local ok, rows = false, nil
  if key ~= T.text_key(lang, T.CHARA) then
    ok, rows = pcall(VRFW.files.text_rows, key, ids)
  end
  if not ok or type(rows) ~= "table" then
    return text_rows(lang, T.CHARA, ids)
  end
  local missing = {}
  for _, id in ipairs(ids) do
    if text_of(rows, id) == nil then missing[#missing + 1] = id end
  end
  if #missing > 0 then
    for id, r in pairs(text_rows(lang, T.CHARA, missing)) do
      rows[id] = r
    end
  end
  return rows
end

-- The roster's texts in one language by roster position (no roster tables inside, so the derived store can keep them).
local function language_texts(lang)
  local ids = roster_text_ids()
  local crows = shown_chara_rows(lang, ids.chara)
  local D = { base = {}, name_text = {}, name = {}, key = {}, reading = {}, reading_order = {}, special_name = {}, sorted = {},
              team_rows = text_rows(lang, T.TEAM, ids.other), series_rows = text_rows(lang, T.SERIES_TEXT, ids.other) }
  local team_text_ids = {}
  for _, text_id in pairs(roster.cat.team_names or {}) do
    if u32(text_id) ~= 0 then team_text_ids[#team_text_ids + 1] = u32(text_id) end
  end
  local okt, shown = pcall(GameText.shown_team_names, team_text_ids, lang)
  D.team_names = okt and type(shown) == "table" and shown or {}
  for i, e in ipairs(roster.entries) do
    D.base[i], D.name_text[i] = e.base, e.name_text
    local n = text_of(crows, e.name_text) or ""
    local key = fold(n)
    D.name[i], D.key[i] = n, key
    local raw = raw_text_of(crows, e.name_text)
    -- A name without furigana is its own reading, so its folded key is reused.
    D.reading[i] = raw and (raw == n and key or fold(T.furigana_reading(raw))) or key
  end
  for i, e in ipairs(roster.special_players) do
    D.special_name[i] = text_of(crows, e.name_text) or ""
  end
  -- name, season, base as one plain string key: sorts without a Lua comparator
  local sort_keys, of_sort_key = {}, {}
  for i, e in ipairs(roster.entries) do
    if D.name[i] ~= "" then
      local tie_break = string.format("%03d%010d", e.si or 999, e.base)
      local k = D.key[i] .. "\0" .. tie_break
      D.reading_order[i] = D.reading[i] .. "\0" .. tie_break
      sort_keys[#sort_keys + 1] = k
      of_sort_key[k] = i
    end
  end
  table.sort(sort_keys)
  for i, k in ipairs(sort_keys) do
    D.sorted[i] = of_sort_key[k]
  end
  return D
end

-- The roster's texts in one language kept between starts for these shown text tables and this roster.
local function language_texts_kept(lang, tables)
  local ok, D = pcall(VRFW.derived, "album_names_" .. lang, { lang, tables, roster.hidden_signature,
    #roster.entries, #roster.special_players }, function() return language_texts(lang) end)
  if ok and type(D) == "table" then return D end
  warn("names of " .. lang .. " not read from the start cache (" .. tostring(D) .. ")")
  return nil
end

-- True when kept texts `D` were built from this roster, position by position.
local function language_texts_fit(D)
  if type(D) ~= "table" or type(D.base) ~= "table" or #D.base ~= #roster.entries then return false end
  if type(D.special_name) ~= "table" or #D.special_name ~= #roster.special_players then return false end
  for i, e in ipairs(roster.entries) do
    if D.base[i] ~= e.base or D.name_text[i] ~= e.name_text then return false end
  end
  return true
end

-- the roster's names in one language as the game shows them; rebuilt when the shown text tables change
local function language_base(lang)
  local tables = T.shown_chara_key(lang) .. "|" .. (GameText.shown_key(lang, T.TEAM) or "")
  local B = bases[lang]
  if B and B.tables == tables then
    return B
  end
  local D = language_texts_kept(lang, tables)
  if not language_texts_fit(D) then D = language_texts(lang) end
  B = { tables = tables, name = {}, key = {}, reading = {}, reading_order = {}, team_rows = D.team_rows,
        series_rows = D.series_rows, team_names = D.team_names, sorted = {} }
  for i, e in ipairs(roster.entries) do
    B.name[e], B.key[e], B.reading[e] = D.name[i], D.key[i], D.reading[i]
    B.reading_order[e] = D.reading_order[i]
  end
  for i, e in ipairs(roster.special_players) do
    B.name[e] = D.special_name[i]
  end
  for i, n in ipairs(D.sorted) do
    B.sorted[i] = roster.entries[n]
  end
  bases[lang] = B
  return B
end

-- a team's shown name; nil when it has none or only tags
local function team_name(B, team)
  local s = team and team ~= 0 and B.team_names[u32(roster.cat.team_names[team] or 0)]
  if type(s) == "string" and s ~= "" and not s:find("<", 1, true) then
    return s
  end
  return nil
end

local function append(into, list)
  for _, e in ipairs(list) do into[#into + 1] = e end
end

local function team_pages(raw, min_players, others_label)
  local merged, by_label, by_crest = {}, {}, {}
  for _, g in ipairs(raw) do
    local into = (g.label and by_label[g.label]) or (g.crest ~= 0 and by_crest[g.crest]) or nil
    if not into then
      into = { label = g.label, list = {}, si = g.si, emblem = g.emblem }
      merged[#merged + 1] = into
      if g.label then by_label[g.label] = into end
    end
    append(into.list, g.list)
    if g.crest ~= 0 and by_crest[g.crest] == nil then by_crest[g.crest] = into end
  end
  local pages, others = {}, nil
  for _, g in ipairs(merged) do
    if g.label == nil or #g.list < min_players then
      others = others or { label = others_label, list = {}, si = g.si, emblem = 0 }
      append(others.list, g.list)
    else
      pages[#pages + 1] = g
    end
  end
  pages[#pages + 1] = others
  return pages
end

local function named(L, list)
  local out = {}
  for _, e in ipairs(list) do
    if L.name[e] ~= "" then
      out[#out + 1] = e
    end
  end
  return out
end

-- the language's state: names and the name / game / team groups (spec: first letters of each name group, comma-split)
local function language(code, spec, other_label, special_label, other_teams_label)
  local lang = GameText.language(code)
  spec = tostring(spec or "")
  local L = names[lang]
  local B = language_base(lang)
  other_label = tostring(other_label or "#")
  special_label = tostring(special_label or "")
  other_teams_label = tostring(other_teams_label or "")
  if other_teams_label == "" then other_teams_label = other_label end
  if L and L.base == B and L.spec == spec and L.other == other_label and L.special == special_label
      and L.other_teams == other_teams_label then
    return L
  end
  local trows, srows = B.team_rows, B.series_rows
  L = { base = B, lang = lang, spec = spec, other = other_label, special = special_label, other_teams = other_teams_label,
        name = B.name, key = B.key, series_rows = srows,
        team_name = function(t) return team_name(B, t) end }
  local groups, of_char = {}, {}
  for g in spec:gmatch("[^,]+") do
    local cs = chars(g)
    groups[#groups + 1] = { label = (#cs > 1) and (fold(cs[1]) .. "-" .. fold(cs[#cs])) or fold(cs[1] or "?"),
                            list = {} }
    for _, ch in ipairs(cs) do
      of_char[fold(ch)] = of_char[fold(ch)] or #groups
    end
  end
  local other = { label = other_label ~= "" and other_label or "#", list = {} }
  for _, e in ipairs(B.sorted) do
    local first = B.reading[e]:match("^" .. UTF8_CHAR)
    local g = first and of_char[first]
    local l = g and groups[g].list or other.list
    l[#l + 1] = e
    if g and not of_char[L.key[e]:match("^" .. UTF8_CHAR) or ""] then
      groups[g].by_reading = true
    end
  end
  for _, g in ipairs(groups) do
    if g.by_reading then
      table.sort(g.list, function(a, b) return B.reading_order[a] < B.reading_order[b] end)
    end
  end
  local name_groups = {}
  for _, g in ipairs(groups) do
    if #g.list > 0 then
      name_groups[#name_groups + 1] = g
    end
  end
  if #other.list > 0 then
    name_groups[#name_groups + 1] = other
  end
  local game_groups = {}
  for _, s in ipairs(roster.series) do
    local label = text_of(srows, s.name_text) or text_of(trows, s.name_text) or string.format("0x%08X", s.name_text)
    local list = named(L, s.list)
    if #list > 0 then
      game_groups[#game_groups + 1] = { label = label, ty = s.ty, list = list, page = s.page or 1 }
    end
  end
  for _, sp in ipairs(roster.specials) do
    L.name[sp] = L.name[sp.of] or ""
  end
  local special_list = named(L, roster.specials)
  if #special_list > 0 then
    local icon = album_config().special_icon
    game_groups[#game_groups + 1] = { label = special_label, ty = 0, icon = type(icon) == "string" and icon or "",
                                      list = special_list, page = 1 }
  end
  -- bar pages: stable order inside a page, pages renumbered 1, 2, … so none is empty
  for i, g in ipairs(game_groups) do g.order = i end
  table.sort(game_groups, function(a, b)
    if a.page ~= b.page then return a.page < b.page end
    return a.order < b.order
  end)
  local renumbered, last = 0, nil
  for _, g in ipairs(game_groups) do
    if g.page ~= last then renumbered, last = renumbered + 1, g.page end
    g.page = renumbered
  end
  local min_players = int(album_config().team_page_min_players) or DEFAULT_TEAM_PAGE_MIN_PLAYERS
  local team_groups, raw, raw_si = {}, {}, nil
  local function flush()
    for _, g in ipairs(team_pages(raw, min_players, other_teams_label)) do
      g.name = g.label
      team_groups[#team_groups + 1] = g
    end
    raw = {}
  end
  for _, t in ipairs(roster.teams) do
    local list = named(L, t.list)
    if #list > 0 then
      if t.si ~= raw_si then
        flush()
        raw_si = t.si
      end
      raw[#raw + 1] = { label = team_name(B, t.team), list = list, si = t.si, crest = t.crest, emblem = t.emblem }
    end
  end
  flush()
  -- a name several groups share: "team · game"
  local uses = {}
  for _, g in ipairs(team_groups) do
    uses[g.label] = (uses[g.label] or 0) + 1
  end
  for _, g in ipairs(team_groups) do
    if uses[g.label] > 1 then
      local game = text_of(srows, roster.cat.series[g.si].name_text)
      if game then g.label = g.label .. " · " .. game end
    end
  end
  L.groups = { name_groups, game_groups, team_groups }
  names[lang] = L
  return L
end

-- the groups as the page reads them
local function groups_out(group_lists, have)
  local out = {}
  for kind, gl in ipairs(group_lists) do
    local o = {}
    for i, g in ipairs(gl) do
      o[i] = { g.label, #g.list, count(g.list, have), g.ty or 0, g.emblem or 0, g.name or g.label, g.icon or "", g.page or 1 }
    end
    out[kind] = o
  end
  return out
end

function BetterQoL.Album.Open(code, spec, other_label, special_label, other_teams_label)
  if ensure_roster() == nil then
    return false
  end
  local L = language(code, spec, other_label, special_label, other_teams_label)
  local have = owned()
  view = L
  view_owned = have
  view_level, view_rarity = shown_card()
  view_counts = {}
  view_groups = nil
  local out = { total = 0, owned = 0, groups = groups_out(L.groups, have) }
  for _, e in ipairs(roster.entries) do
    if L.name[e] ~= "" then
      out.total = out.total + 1
      if have[e] then
        out.owned = out.owned + 1
      end
    end
  end
  info(string.format("opened (%s): %d players, %d in the club, %d name groups, %d games", L.lang, out.total, out.owned,
    #L.groups[1], #L.groups[2]))
  return out
end

-- CMND_BETTERQOL_ALBUM_SEARCH(text) -> matches among the name groups (page kind 4); 0 keeps the last results
function BetterQoL.Album.Search(text)
  local L = view
  if L == nil or roster == nil then
    return 0
  end
  local query = fold(tostring(text or "")):gsub("%s+", " "):match("^ ?(.-) ?$")
  if query == "" then
    return 0
  end
  local found = {}
  for _, g in ipairs((view_groups or L.groups)[1]) do
    for _, e in ipairs(g.list) do
      if L.key[e]:find(query, 1, true) ~= nil then
        found[#found + 1] = e
      end
    end
  end
  if #found > 0 then
    search_group = { list = found }
  end
  return #found
end

-- an entry's teams with their shown names: { { team, name }, ... } (the page's team-beaten rule reads them)
local function row_teams(L, e)
  local out = {}
  for _, t in ipairs(e.teams or {}) do
    if t ~= 0 then
      out[#out + 1] = { t, L.team_name(t) or "" }
    end
  end
  return out
end

-- CMND_BETTERQOL_ALBUM_PAGE(kind, group, page, rows a page); kind 1 = name, 2 = game, 3 = team, 4 = search
function BetterQoL.Album.Page(kind, group, page, per)
  local L = view
  if L == nil or roster == nil then
    return false
  end
  local gl = (view_groups or L.groups)[int(kind) or 0]
  local g = gl and gl[int(group) or 0]
  if int(kind) == SEARCH_KIND then
    g = search_group
  end
  if g == nil then
    return false
  end
  per = math.max(1, int(per) or 20)
  local pages = math.max(1, math.ceil(#g.list / per))
  page = math.max(1, math.min(pages, int(page) or 1))
  local have = view_owned or {}
  -- counted once per opening: a group can hold thousands of players
  view_counts[g] = view_counts[g] or count(g.list, have)
  local out = { page = page, pages = pages, total = #g.list, owned = view_counts[g], rows = {} }
  for k = 1, per do
    local e = g.list[(page - 1) * per + k]
    if e == nil then
      break
    end
    local source_series = e.si and roster.cat.series[e.si]
    local game_name_text = e.game_name_text or (source_series and source_series.name_text)
    out.rows[k] = { e.base, e.param, L.name[e], (e.team and L.team_name(e.team)) or "",
                    (game_name_text and text_of(L.series_rows, game_name_text)) or "", have[e] ~= nil,
                    view_level, e.special and e.rarity or view_rarity, e.dress_team or 0, row_teams(L, e) }
  end
  return out
end

-- the filter window's data ------------------------------------------------------------------------------------------


-- the language state's sagas: the "Game" groups, each with its row's teams in row order; [entry] = saga index
local function filter_sagas(L)
  if L.filter_sagas ~= nil then return L.filter_sagas, L.filter_saga_of end
  local sagas, saga_of = {}, {}
  for i, g in ipairs(L.groups[2]) do
    local teams, seen = {}, {}
    for _, e in ipairs(g.list) do
      saga_of[e] = i
      for _, t in ipairs(e.teams or {}) do
        if t ~= 0 and not seen[t] then
          seen[t] = true
          local name = L.team_name(t)
          if name then teams[#teams + 1] = { t, name } end
        end
      end
    end
    sagas[i] = { g.label, teams }
  end
  L.filter_sagas, L.filter_saga_of = sagas, saga_of
  return sagas, saga_of
end

local FILTER_FIELDS = { position = true, element = true, gender = true, build = true }

-- the window's selection: position=1,2;teams=1:11,12/3:  (a category left out is complete; "" is no filter)
local function parse_filter(spec)
  local filter = { fields = {} }
  local any = false
  for key, value in tostring(spec or ""):gmatch("(%a+)=([^;]*)") do
    any = true
    if key == "teams" then
      filter.teams = {}
      for saga, list in value:gmatch("(%d+):([^/]*)") do
        local set = {}
        for n in list:gmatch("%d+") do set[u32(tonumber(n))] = true end
        filter.teams[tonumber(saga)] = set
      end
    elseif FILTER_FIELDS[key] then
      local set = {}
      for n in value:gmatch("%d+") do set[tonumber(n)] = true end
      filter.fields[key] = set
    end
  end
  return any and filter or nil
end

local function passes_filter(e, filter, saga_of)
  local a = e.filter
  for field, set in pairs(filter.fields) do
    if not set[a[field]] then return false end
  end
  local set = filter.teams and filter.teams[saga_of[e] or 0] or nil
  if set == nil then return true end
  for _, t in ipairs(e.teams or {}) do
    if set[t] then return true end
  end
  return false
end

-- the same groups with only the rows that pass; a group left empty is gone, the bar pages renumbered
local function filtered_groups(L, filter)
  local _, saga_of = filter_sagas(L)
  local out = {}
  for kind, gl in ipairs(L.groups) do
    local kept, renumbered, last = {}, 0, nil
    for _, g in ipairs(gl) do
      local list = {}
      for _, e in ipairs(g.list) do
        if passes_filter(e, filter, saga_of) then list[#list + 1] = e end
      end
      if #list > 0 then
        local page = g.page
        if page ~= nil then
          if page ~= last then renumbered, last = renumbered + 1, page end
          page = renumbered
        end
        kept[#kept + 1] = { label = g.label, ty = g.ty, emblem = g.emblem, name = g.name, icon = g.icon, page = page, list = list }
      end
    end
    out[kind] = kept
  end
  return out
end

-- CMND_BETTERQOL_ALBUM_FILTER_INFO() -> { total, sagas = { { label, { { team, name }, ... } }, ... } }
function BetterQoL.Album.FilterInfo()
  local L = view
  if L == nil or roster == nil then return false end
  local sagas = filter_sagas(L)
  local total = 0
  for _, e in ipairs(roster.entries) do
    if L.name[e] ~= "" then total = total + 1 end
  end
  return { total = total, sagas = sagas }
end

-- CMND_BETTERQOL_ALBUM_FILTER_COUNT(selection) -> the album's players that pass
function BetterQoL.Album.FilterCount(spec)
  local L = view
  if L == nil or roster == nil then return 0 end
  local filter = parse_filter(spec)
  local _, saga_of = filter_sagas(L)
  local shown = 0
  for _, e in ipairs(roster.entries) do
    if L.name[e] ~= "" and (filter == nil or passes_filter(e, filter, saga_of)) then shown = shown + 1 end
  end
  return shown
end

-- CMND_BETTERQOL_ALBUM_FILTER_SET(selection) -> { groups } of the album's lists under it ("" lifts the filter)
function BetterQoL.Album.FilterSet(spec)
  local L = view
  if L == nil or roster == nil then return false end
  local filter = parse_filter(spec)
  view_groups = filter and filtered_groups(L, filter) or nil
  view_counts = {}
  search_group = nil
  return { groups = groups_out(view_groups or L.groups, view_owned or {}) }
end

ensure_roster()

-- builds the names of the game language `lang` once (the start cache keeps them); `when` names the moment in a warning
local function build_language_names(lang, when)
  if type(lang) ~= "string" or lang == "" or roster == nil then return end
  local ok, e = pcall(language_base, lang)
  if not ok then
    warn("names of " .. lang .. " not built at " .. when .. " (" .. tostring(e) .. ")")
  end
end

-- the script load (off the game thread) builds the names of the language the game already shows
local ok_lang, load_lang = pcall(VRFW.files.game_language)
if ok_lang then build_language_names(load_lang, "the script load") end

-- a save load builds the game language's names when the script load saw another one, so the first opening only groups them
VRFW.on("save:slot_load", function()
  local ok, lang = pcall(VRFW.files.game_language)
  if ok then build_language_names(lang, "the save load") end
end)
