--- Advanced: Library: series, eras, teams and crest ranks from the game tables.

local Id = VRFW.ids

local M = {}

local u32 = Id.unsigned
local STEP = 100000
--- Internal: Size of one rank band (100000) in the sort ranks.
M.STEP = STEP
--- Internal: Sort rank answered when an item has no rank; sorts after every ranked item.
M.NO_RANK = 10 * STEP + STEP - 1

local SERIES_TABLE, BELONG_TABLE, EMBLEM_TABLE, TEAM_TABLE = "character/chara_series", "character/belong_team",
  "item/item_emblem", "team/team"

local function crc(s)
  local f = VRFW.crc32 or (VRFW.ui and VRFW.crc32)
  return f and f(s) or 0
end

-- the first present value of `row` among `names` (schema name, then the file's own field name)
local function col(row, ...)
  for i = 1, select("#", ...) do
    local v = row[select(i, ...)]
    if v ~= nil then return v end
  end
  return nil
end

local trim = VRFW.strings.trim

--- Advanced: A number, "0x..." text or name (its crc32) as an id; nil when unusable.
function M.id_value(v)
  return Id.parse(v, { hash_names = true })
end

local function rows_of(tbl)
  local ok, rows = pcall(VRFW.table.rows, tbl)
  return ok and type(rows) == "table" and rows or {}
end

local SERIES = nil
--- Advanced: The series table, read once.
function M.series()
  if SERIES then return SERIES end
  SERIES = {}
  for _, r in ipairs(rows_of(SERIES_TABLE)) do
    local id = u32(col(r, "chara_series_id", "charaSeriesId"))
    if id ~= 0 then
      SERIES[#SERIES + 1] = { id = id, ty = u32(col(r, "chara_series_type", "charaSeriesType")),
        name_text = u32(col(r, "chara_series_name_text_id", "charaSeriesNameTextId")) }
    end
  end
  return SERIES
end

-- the belong table's layout and rows, read once
local B = nil
local function belong()
  if B then return B end
  B = { types = {}, eras = {}, rows = {}, by_id = {}, type_era = {}, era_type = {} }
  local nums, emblem_cols, kit_cols = {}, {}, {}
  local ok_cols, cols = pcall(VRFW.table.columns, BELONG_TABLE)
  for i, n in ipairs(ok_cols and type(cols) == "table" and cols or {}) do
    local x = n:match("^teamNumber_(.+)$") or n:match("^team_number_(.+)$")
    if x then
      nums[#nums + 1] = i
      B.types[#B.types + 1] = { name = x:lower() }
    end
    local e = n:match("^team_emblem_id_(.+)$") or n:match("^teamEmblemId_(.+)$")
    if e then
      emblem_cols[#emblem_cols + 1] = i
      B.eras[#B.eras + 1] = { name = e:lower() }
    end
    local k = n:match("^team_kit_(.+)$") or n:match("^teamKit_(.+)$")
    if k then kit_cols[#kit_cols + 1] = { era = k:lower(), col = i } end
  end
  for k, t in ipairs(B.types) do
    for ei, e in ipairs(B.eras) do
      if t.name:sub(1, #e.name) == e.name or (#t.name >= 3 and e.name:find(t.name:sub(1, 3), 1, true)) then
        B.type_era[k] = ei
        t.era = ei
        if B.era_type[ei] == nil then B.era_type[ei] = k end
        break
      end
    end
  end
  for ei, e in ipairs(B.eras) do e.first_type = B.era_type[ei] end
  local era_index = {}
  for ei, e in ipairs(B.eras) do era_index[e.name] = ei end
  for _, r in ipairs(rows_of(BELONG_TABLE)) do
    local id = u32(col(r, "belong_team_id", "belongTeamId"))
    if id ~= 0 then
      local numbers, emblems, kits = {}, {}, {}
      for k, i in ipairs(nums) do
        local v = r[i]
        numbers[k] = type(v) == "number" and v > 0 and v or 0
      end
      for ei, i in ipairs(emblem_cols) do emblems[ei] = u32(r[i]) end
      for _, c in ipairs(kit_cols) do
        local ei = era_index[c.era]
        if ei then kits[ei] = u32(r[c.col]) end
      end
      local row = { id = id, name_text = u32(col(r, "team_name_text_id", "teamNameTextId")), numbers = numbers,
        emblems = emblems, kits = kits }
      B.rows[#B.rows + 1] = row
      if B.by_id[id] == nil then B.by_id[id] = row end
    end
  end
  return B
end

--- Advanced: The series types of the belong table.
function M.series_types() return belong().types end
--- Internal: The eras of the belong table.
function M.eras() return belong().eras end
--- Advanced: The era of series type `k`.
function M.era_of_type(k) return belong().type_era[k] end
--- Advanced: The first series type of era `era`.
function M.first_type_of_era(era) return belong().era_type[era] end
--- Advanced: Every row of the belong table.
function M.teams() return belong().rows end
--- Advanced: The belong row of team `id`; nil when it has none.
function M.team(id) return belong().by_id[u32(id)] end

--- Internal: The sort rank of team `team` in series type `k`.
function M.team_rank(team, k)
  local row = belong().by_id[u32(team)]
  local n = row and k and row.numbers[k]
  if not k then return M.NO_RANK end
  if n and n > 0 then return k * STEP + math.min(n, STEP - 1) end
  return k * STEP
end

-- a crest ranks by the earliest series of its own era the team exists in, else by the team's earliest series
local CREST_RANK = nil
--- Internal: The sort rank of crest `emblem`; `M.NO_RANK` when it has none.
function M.crest_rank(emblem)
  if not CREST_RANK then
    CREST_RANK = {}
    local b = belong()
    for _, row in ipairs(b.rows) do
      for ei, e in ipairs(row.emblems) do
        if e ~= 0 and CREST_RANK[e] == nil then
          local best, any
          for k = 1, #b.types do
            local n = row.numbers[k]
            if n > 0 then
              local rank = k * STEP + math.min(n, STEP - 1)
              if not any then any = rank end
              if b.type_era[k] == ei and not best then best = rank end
            end
          end
          CREST_RANK[e] = best or any or M.NO_RANK
        end
      end
    end
  end
  return CREST_RANK[u32(emblem)] or M.NO_RANK
end

local CHARA_RANK = {}
--- Advanced: The sort rank of character `base`.
function M.character_rank(base)
  base = u32(base)
  local r = CHARA_RANK[base]
  if r then return r end
  r = M.NO_RANK
  local ok, c = pcall(VRFW.character.character, base)
  if ok and type(c) == "table" then
    local k = math.floor(tonumber(c.series) or 0)
    if k > 0 then
      local n = STEP - 1
      for _, t in ipairs(c.teams or {}) do
        local row = belong().by_id[u32(t)]
        local v = row and row.numbers[k]
        if v and v > 0 and v < n then n = v end
      end
      r = k * STEP + n
    end
  end
  CHARA_RANK[base] = r
  return r
end

local EMBLEMS = nil
local function emblem_table()
  if EMBLEMS then return EMBLEMS end
  EMBLEMS = { keys = {}, by_key = {} }
  local ok, rows = pcall(VRFW.table.rows, EMBLEM_TABLE)
  if not ok or type(rows) ~= "table" then return EMBLEMS end
  local ids, n = {}, 0
  for _, r in ipairs(rows) do
    local id = u32(col(r, "id"))
    if id ~= 0 then
      ids[id] = true
      n = n + 1
      if type(r.key) == "string" and r.key ~= "" then
        EMBLEMS.keys[id] = r.key
        EMBLEMS.by_key[r.key] = id
      end
    end
  end
  if n > 0 then EMBLEMS.ids = ids end
  return EMBLEMS
end

--- Advanced: Every emblem id, as an array.
function M.emblem_ids() return emblem_table().ids end
--- Advanced: The key name of emblem `emblem`; nil when unknown.
function M.emblem_key(emblem) return emblem_table().keys[u32(emblem)] end

local function usable(id)
  local ids = emblem_table().ids
  return (id or 0) ~= 0 and (ids == nil or ids[id] == true)
end
--- Internal: True when `id` is a nonzero emblem id known to the emblem table.
M.usable_emblem = usable

--- Internal: The crest of team `team` in every era, as a table.
function M.era_crests(team)
  local row = belong().by_id[u32(team)]
  return row and row.emblems or {}
end

local DECLARED = nil
local function declared()
  if DECLARED then return DECLARED end
  DECLARED = {}
  local ok, files = pcall(VRFW.files.declarations, "content/team_crests")
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local data = type(f.data) == "table" and f.data or {}
    local own = type(data.VRFW) == "table" and data.VRFW.TeamCrest or nil
    for _, list in ipairs({ own, data.crest }) do
      for _, c in ipairs(type(list) == "table" and list or {}) do
        local t = type(c) == "table" and M.id_value(c.team) or nil
        local e = type(c) == "table" and M.id_value(c.emblem) or nil
        if t and e and t ~= 0 and usable(e) and DECLARED[t] == nil then DECLARED[t] = e end
      end
    end
  end
  return DECLARED
end

local NAMED = nil
local function named()
  if NAMED then return NAMED end
  NAMED = { crest = {}, team_ja = {} }
  local texts = VRFW.names.texts("team_text", "ja") or {}
  local function ja(text)
    local s = text ~= 0 and texts[text] or nil
    if type(s) ~= "string" then return nil end
    s = VRFW.names.without_furigana(s)
    return s ~= "" and s or nil
  end
  for _, r in ipairs(rows_of(TEAM_TABLE)) do
    local e = u32(col(r, "emblem") or r[7])
    if usable(e) then
      local nm = ja(u32(col(r, "name_text") or r[4]))
      if nm and NAMED.crest[nm] == nil then NAMED.crest[nm] = e end
    end
  end
  for _, row in ipairs(belong().rows) do
    if NAMED.team_ja[row.id] == nil then NAMED.team_ja[row.id] = ja(row.name_text) or false end
  end
  return NAMED
end

--- Internal: The crest a mod declares for team `team`; nil when none does.
function M.declared_crest(team) return declared()[u32(team)] end

--- Advanced: The crest of team `team` in era `era` (0 = none).
function M.crest(team, era)
  team = u32(team)
  local d = declared()[team]
  if d then return d end
  local e = M.era_crests(team)
  if era and usable(e[era]) then return e[era] end
  local n = named()
  local nm = n.team_ja[team]
  if nm and n.crest[nm] then return n.crest[nm] end
  if era then
    for i = #e, 1, -1 do
      if usable(e[i]) then return e[i] end
    end
  else
    for i = 1, #e do
      if usable(e[i]) then return e[i] end
    end
  end
  return 0
end

local ITEM_SERIES = nil
--- Advanced: Item id -> { [series type] = true } of every kit and emblem, from item_config's series rows.
function M.item_series()
  if ITEM_SERIES then return ITEM_SERIES end
  ITEM_SERIES = {}
  local okk, key = pcall(VRFW.table.source, "item/item_fashion")
  local ok, ents = pcall(VRFW.table.entries, okk and key or VRFW.table_files.file_name("data/common/gamedata/item/item_config"),
    { "ITEM_FASHION_INFO", "ITEM_FASHION_INFO_SERIES", "ITEM_EMBLEM_INFO", "ITEM_EMBLEM_INFO_SERIES" }, true)
  if not ok or type(ents) ~= "table" then
    VRFW.warn("item_config series rows not readable (" .. tostring(ents) .. ")")
    return ITEM_SERIES
  end
  local cur = nil
  for _, e in ipairs(ents) do
    if e.name == "ITEM_FASHION_INFO" or e.name == "ITEM_EMBLEM_INFO" then
      cur = u32(e[1])
    elseif e.name == "ITEM_FASHION_INFO_SERIES" or e.name == "ITEM_EMBLEM_INFO_SERIES" then
      if cur and ITEM_SERIES[cur] == nil then
        local types = {}
        for k = 1, 9 do
          local v = e[k]
          if v == true or (type(v) == "number" and v ~= 0) then types[k] = true end
        end
        if next(types) ~= nil then ITEM_SERIES[cur] = types end
      end
      cur = nil
    end
  end
  return ITEM_SERIES
end

-- the technique files of every active mod, and the cell names of the technique table's series column
local TECHNIQUE_FOLDERS = { "techniques", "content/techniques", "features/*/content/techniques" }
local SERIES_CELLS = { "seriesIdCrc", "series_id_crc", "seriesidcrc" }

-- the [saga] of every active mod's mod.toml, in load order: { mod, text, name, game_series = { [move key] = true } }
local function mod_sagas()
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, "mod.toml")
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local data = type(f.data) == "table" and f.data or {}
    local saga = type(data.saga) == "table" and data.saga or {}
    local keep = {}
    for _, k in ipairs(type(saga.game_series_moves) == "table" and saga.game_series_moves or {}) do
      if type(k) == "string" then keep[k] = true end
    end
    local id = tostring(f.mod)
    out[#out + 1] = { mod = id, text = type(saga.text) == "string" and saga.text or "",
      name = type(data.name) == "string" and data.name ~= "" and data.name or id, game_series = keep }
  end
  return out
end

-- move id -> the game series a mod's move stays in: a move its mod lists in [saga] game_series_moves, with the series
-- its own [[technique]] declaration writes in cells
local function kept_game_series(known, keep_of)
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, TECHNIQUE_FOLDERS)
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local keep = keep_of[tostring(f.mod)] or {}
    local list = type(f.data) == "table" and f.data.technique or nil
    for _, d in ipairs(type(list) == "table" and list or {}) do
      local key = type(d) == "table" and (d.key or d.name) or nil
      if type(key) == "string" and keep[key] then
        local cells = type(d.cells) == "table" and d.cells or {}
        local v = col(cells, table.unpack(SERIES_CELLS))
        local series = v ~= nil and M.id_value(v) or nil
        local id = Id.technique(tostring(f.mod) .. "." .. key) or Id.technique(key)
        if id and series and known[series] then
          out[u32(id)] = series
        else
          VRFW.warn(string.format("%s: game_series_moves names %s, whose cells set no series of the game's table: it is in the mod's saga",
            tostring(f.mod), key))
        end
      end
    end
  end
  return out
end

local SAGAS = nil
--- Advanced: The sagas of every technique, read once: { list = { { key, series, mod, text, name } }, of = { [move id] =
--- saga key } }. The list holds the game's series rows in table order (key = the series id, named by the game's series
--- name), then one saga per active mod in load order (key = the mod id; text = the text key of its mod.toml
--- [saga] text, name = its display name). A game move is in the saga of its own skill table cell series_id_crc; a mod's
--- move is in its mod's saga, unless the mod lists it in [saga] game_series_moves (then the series its cells set). A
--- game move without a series is absent from `of`.
function M.sagas()
  if SAGAS then return SAGAS end
  SAGAS = { list = {}, of = {} }
  local known = {}
  for _, s in ipairs(M.series()) do
    known[s.id] = true
    SAGAS.list[#SAGAS.list + 1] = { key = s.id, series = s.id, name_text = s.name_text }
  end
  local keep_of = {}
  for _, m in ipairs(mod_sagas()) do
    keep_of[m.mod] = m.game_series
    SAGAS.list[#SAGAS.list + 1] = { key = m.mod, mod = m.mod, text = m.text, name = m.name }
  end
  local okw, owners = pcall(VRFW.ids.owners, "technique")
  owners = okw and type(owners) == "table" and owners or {}
  local kept = kept_game_series(known, keep_of)
  for _, r in ipairs(rows_of("skill/skill")) do
    local id = u32(col(r, "skill_id", "skillID"))
    if id ~= 0 then
      local owner = owners[id]
      if owner then
        SAGAS.of[id] = kept[id] or owner
      else
        local series = u32(col(r, "series_id_crc", "seriesIdCrc"))
        if known[series] then SAGAS.of[id] = series end
      end
    end
  end
  return SAGAS
end

local COLOURS = nil
local function colours()
  if COLOURS then return COLOURS end
  COLOURS = {}
  local ok, files = pcall(VRFW.files.declarations, "content/emblem_colours")
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local data = type(f.data) == "table" and f.data or {}
    local list = type(data.VRFW) == "table" and data.VRFW.EmblemColour or nil
    for _, c in ipairs(type(list) == "table" and list or {}) do
      if type(c) == "table" and type(c.emblem) == "string" and c.emblem ~= "" then
        local key = trim(c.emblem)
        local id = key:match("^0[xX]%x+$") and M.id_value(key) or crc(key)
        COLOURS[id] = { hue = tonumber(c.hue), strength = tonumber(c.strength) or 0, share = tonumber(c.share) or 0,
          value = tonumber(c.value) or 0 }
      end
    end
  end
  return COLOURS
end

--- Internal: The colour of emblem `emblem`; nil when unknown.
function M.emblem_colour(emblem)
  local id = type(emblem) == "string" and M.id_value(emblem) or u32(emblem)
  return id and colours()[id] or nil
end

--- Internal: The word of `rule` matching the colour of emblem `emblem`; nil when unknown.
function M.colour_name(emblem, rule)
  local c = M.emblem_colour(emblem)
  if not c or type(rule) ~= "table" then return nil end
  local weak = c.hue == nil or c.strength < (tonumber(rule.min_strength) or 0) or c.share < (tonumber(rule.min_share) or 0)
  if not weak then
    local best, dist = nil, 361
    for _, h in ipairs(type(rule.hues) == "table" and rule.hues or {}) do
      local name, hue = h.name or h[1], tonumber(h.hue or h[2])
      if name and hue then
        local d = math.abs(c.hue - hue) % 360
        d = math.min(d, 360 - d)
        if d < dist then best, dist = name, d end
      end
    end
    if best then return best end
  end
  if rule.dark and c.value < (tonumber(rule.dark_below) or 0) then return rule.dark end
  return rule.light or rule.neutral
end

-- content\team_tags\*.toml: [[VRFW.TeamTag]] tag = "<name>", teams = [game keys, 0x… ids or "<mod>.<name>"]
local TAGS = nil
local function tags()
  if TAGS then return TAGS end
  TAGS = {}
  local ok, files = pcall(VRFW.files.declarations, "content/team_tags")
  for _, f in ipairs(ok and type(files) == "table" and files or {}) do
    local data = type(f.data) == "table" and f.data or {}
    local list = type(data.VRFW) == "table" and data.VRFW.TeamTag or nil
    for _, d in ipairs(type(list) == "table" and list or {}) do
      if type(d) == "table" and type(d.tag) == "string" and type(d.teams) == "table" then
        local set = TAGS[d.tag] or {}
        TAGS[d.tag] = set
        for _, t in ipairs(d.teams) do
          local id = nil
          if type(t) == "string" and t:find(".", 1, true) then id = VRFW.teams.ids.of(t) end
          id = id or M.id_value(t)
          if id and id ~= 0 then set[id] = true end
        end
      end
    end
  end
  return TAGS
end

--- Advanced: The teams with tag `tag`, as an array.
function M.tagged(tag) return tags()[tag] or {} end

--- Internal: True when team `team` has tag `tag`.
function M.has_tag(team, tag)
  local id = team
  if type(team) == "string" then
    id = (team:find(".", 1, true) and VRFW.teams.ids.of(team)) or M.id_value(team)
  end
  return (tags()[tag] or {})[u32(id)] == true
end

local TEAM_MEMBER_TABLE = "team/team_member"

local function scalar(v)
  if type(v) == "table" then return v[1] end
  return v
end

local function column_of(id, name, default)
  local ok, cols = pcall(VRFW.table.columns, id)
  if ok and type(cols) == "table" then
    for i, c in ipairs(cols) do
      if c == name then return i end
    end
  end
  return default
end

local TEAM_ROWS = nil
--- Advanced: The rows of the team table; nil, why when unreadable.
function M.team_rows()
  if TEAM_ROWS then return TEAM_ROWS end
  local ok, rows = pcall(VRFW.table.rows, TEAM_TABLE)
  if not ok or type(rows) ~= "table" then return nil, tostring(rows) end
  if #rows > 0 then TEAM_ROWS = rows end
  return rows
end

-- the member ranges of the team rows (first row of each id) and the member rows, read once
local MAX_TEAM_MEMBER_ROWS = 64
local ROSTER = nil
local ROSTER_WARNED = false
local function roster()
  if ROSTER then return ROSTER end
  local ok, r, why = pcall(function()
    local key = VRFW.table.source(TEAM_TABLE)
    local p_id = column_of(TEAM_TABLE, "id", 1)
    local p_card, p_slot = column_of(TEAM_MEMBER_TABLE, "chara_param", 1), column_of(TEAM_MEMBER_TABLE, "slot", 9)
    local info = VRFW.table.raw(key, "SOCCER_TEAM_INFO", { p_id })
    local refs = VRFW.table.raw(key, "SOCCER_TEAM_INFO_REF_MEMBER", { 1, 2 })
    local members = VRFW.table.raw(key, "SOCCER_TEAM_MEMBER", { p_card, p_slot })
    if type(info) ~= "table" or type(refs) ~= "table" or type(members) ~= "table" or #refs ~= #info then
      return nil, "team rows / member refs do not match"
    end
    local range = {}
    for i, t in ipairs(info) do
      local team = u32(scalar(t[p_id]))
      local first, count = tonumber(scalar(refs[i][1])), tonumber(scalar(refs[i][2]))
      if team ~= 0 and range[team] == nil and first and count then range[team] = { first, count } end
    end
    return { range = range, members = members, p_card = p_card, p_slot = p_slot, lists = {} }
  end)
  if not ok or not r then
    if not ROSTER_WARNED then
      ROSTER_WARNED = true
      VRFW.warn("game catalogue: team members not readable (" .. tostring(why or r) .. ")")
    end
    return nil
  end
  ROSTER = r
  return r
end

--- Advanced: The members of team `team` in the game data: array of { card, slot } ({} when unreadable).
function M.members(team)
  local r = roster()
  if not r then return {} end
  team = u32(team)
  local list = r.lists[team]
  if list then return list end
  list = {}
  local range = r.range[team]
  if range then
    for k = range[1] + 1, range[1] + range[2] do
      local m = r.members[k]
      if m then
        list[#list + 1] = { card = u32(scalar(m[r.p_card])), slot = tonumber(scalar(m[r.p_slot])) or 0 }
      end
    end
  end
  r.lists[team] = list
  return list
end

local MEMBER_ROW_LAYOUT = nil
local function member_row_layout()
  if MEMBER_ROW_LAYOUT then return MEMBER_ROW_LAYOUT end
  local field = VRFW.game.field
  local layout = { first = field("TeamRecord.First"), count = field("TeamRecord.Count"), members = field("TeamConfig.Members"),
    total = field("TeamConfig.MemberCount"), row_size = field("MemberRow") }
  for name, value in pairs(layout) do
    if type(value) ~= "number" then return nil, "the game profile has no member row field " .. name end
  end
  MEMBER_ROW_LAYOUT = layout
  return layout
end

--- Advanced: The live member rows of team `team`: { record, container, base, first, count, row_size, rows = row addresses }; nil, why.
function M.member_rows(team)
  local layout, missing = member_row_layout()
  if not layout then return nil, missing end
  local record, container = VRFW.teams.config.find(team)
  if not record then return nil, container end
  local Memory = VRFW.memory
  local first, count = Memory.read("u32", record + layout.first), Memory.read("u32", record + layout.count)
  local base, total = Memory.read_pointer(container + layout.members), Memory.read("i32", container + layout.total)
  if not first or not count or not base or not total then return nil, "member slice unreadable" end
  first = first % 65536
  if count == 0 or count > MAX_TEAM_MEMBER_ROWS or first + count > total then
    return nil, string.format("member slice %d+%d of %d rows", first, count, total)
  end
  local rows = {}
  for index = 0, count - 1 do rows[index + 1] = base + (first + index) * layout.row_size end
  return { record = record, container = container, base = base, first = first, count = count, row_size = layout.row_size, rows = rows }
end

local FREE_MATCH = {}   -- class -> team ids
--- Advanced: The team ids of free match class `class`; nil, why when unreadable.
function M.free_match_teams(class)
  local cached = FREE_MATCH[class]
  if cached then return cached end
  local ok, out, why = pcall(function()
    local key = VRFW.table.source("soccer/soccer_game_info")
    local info = VRFW.table.raw(key, "SOCCER_GAME_INFO", { 1 })
    local refs = VRFW.table.raw(key, "SOCCER_GAME_INFO_REF_DIFFICULTY", { 1, 2 })
    local classes = VRFW.table.raw(key, "SOCCER_GAME_DIFFICULTY", { 1, 2 })
    if type(info) ~= "table" or type(refs) ~= "table" or type(classes) ~= "table" or #refs ~= #info then
      return nil, "game rows / class refs do not match"
    end
    local rival = {}
    for i, g in ipairs(info) do
      local first, count = tonumber(scalar(refs[i][1])), tonumber(scalar(refs[i][2]))
      for k = (first or 0) + 1, (first or 0) + (count or 0) do
        local row = classes[k]
        if row and tonumber(scalar(row[1])) == class then
          rival[u32(scalar(g[1]))] = u32(scalar(row[2]))
          break
        end
      end
    end
    local teams, seen = {}, {}
    for _, row in ipairs(VRFW.table.rows("soccer/soccer_opponent_info")) do
      local team = rival[u32(scalar(col(row, "battleId", 2)) or 0)]
      if team and team ~= 0 and not seen[team] then
        seen[team] = true
        teams[#teams + 1] = team
      end
    end
    return teams
  end)
  if not ok or not out then return nil, tostring(why or out) end
  if #out > 0 then FREE_MATCH[class] = out end
  return out
end

local COLUMN_ROWS = {}   -- column list -> the team rows with only those columns
-- the team rows with only the named columns (by name), read once per column list; nil, why when unreadable
local function team_column_rows(columns)
  local list_key = table.concat(columns, ",")
  if COLUMN_ROWS[list_key] then return COLUMN_ROWS[list_key] end
  local ok, rows = pcall(VRFW.table.rows, TEAM_TABLE, columns)
  if not ok or type(rows) ~= "table" then return nil, tostring(rows) end
  if #rows > 0 then COLUMN_ROWS[list_key] = rows end
  return rows
end

local POOLS = {}   -- rule key -> rows
--- Advanced: The team rows matching `rule`; `rule.columns` (column names) reads only those columns, plus the ones the rule tests.
function M.pool(rule)
  rule = rule or {}
  local exclude, excluded_ids = {}, {}
  for _, v in ipairs(type(rule.exclude) == "table" and rule.exclude or {}) do
    local id = M.id_value(v)
    if id and not exclude[id] then
      exclude[id] = true
      excluded_ids[#excluded_ids + 1] = id
    end
  end
  table.sort(excluded_ids)
  local rule_key = table.concat({ tostring(rule.level), tostring(rule.key_prefix), tostring(rule.min_members),
    tostring(rule.unique == true), tostring(rule.order), table.concat(excluded_ids, ","),
    type(rule.columns) == "table" and table.concat(rule.columns, ",") or "" }, "|")
  local cached = POOLS[rule_key]
  if cached then return cached end
  local prefix, level, unique = rule.key_prefix, rule.level, rule.unique
  local rows, why
  if type(rule.columns) == "table" then
    local columns, listed = { "id" }, { id = true }
    for _, c in ipairs(rule.columns) do
      if not listed[c] then listed[c] = true; columns[#columns + 1] = c end
    end
    if prefix and not listed.key then columns[#columns + 1] = "key" end
    if level ~= nil and not listed.level then columns[#columns + 1] = "level" end
    rows, why = team_column_rows(columns)
  else
    rows, why = M.team_rows()
  end
  if not rows then return nil, "team table not readable (" .. tostring(why) .. ")" end
  local r = nil
  if rule.min_members then
    r = roster()
    if not r then return nil, "team members not readable" end
  end
  local prefix_len = prefix and #prefix or 0
  local out, seen, index = {}, {}, {}
  -- one pass over the team table: the cheap key test first, the cells read in place (row.name or its position)
  for i, row in ipairs(rows) do
    local pass = true
    if prefix then
      local key = row.key or row[2]
      pass = type(key) == "string" and key:sub(1, prefix_len) == prefix
    end
    local id = pass and u32(row.id or row[1] or 0) or 0
    pass = pass and id ~= 0 and not exclude[id] and not (unique and seen[id])
    if pass and level ~= nil then pass = (row.level or row[9]) == level end
    if pass and r then
      local range = r.range[id]
      pass = range ~= nil and range[2] >= rule.min_members
    end
    if pass then
      seen[id] = true
      out[#out + 1] = row
      index[row] = i
    end
  end
  if rule.order == "id" then
    table.sort(out, function(a, b)
      local ia, ib = u32(col(a, "id", 1) or 0), u32(col(b, "id", 1) or 0)
      if ia ~= ib then return ia < ib end
      return index[a] < index[b]
    end)
  end
  POOLS[rule_key] = out
  return out
end

return M
