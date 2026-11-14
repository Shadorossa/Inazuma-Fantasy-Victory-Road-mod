
TechniqueFilter = TechniqueFilter or {}
TechniqueFilter.kept = TechniqueFilter.kept or {}

local info, warn = VRFW.logger("technique_filter")

-- the game's numeric tab: its list item type and the technique table column it filters (record byte +0x31)
local TENSION = { list_item_type = 3, table = "skill/skill", column = "consume_tp" }
-- the window's filter group whose row builder builds the tension rows (the move lists' groups: 2 3 4)
local TENSION_GROUP = 2
-- the match site's six `cmp byte [rdi+0x31], imm8` immediates (offsets in the site's game bytes)
local GAME_VALUE_AT = { 21, 27, 33, 39, 45, 51 }
-- rows the stored mask holds (bits of the filter block's 8 bytes)
local MAX_ROWS = 64
-- tension byte -> row table of the match stub: no row
local NO_ROW = 0xFF
-- the technique files that declare families ([[VRFW.TechniqueFamily]])
local FAMILY_FOLDERS = { "techniques", "content/techniques", "features/*/content/techniques" }
-- the files that declare added filter tabs ([[VRFW.TechniqueFilterTab]])
local TAB_FOLDERS = { "content/technique_filter_tabs" }
-- the tab defaults (types	echnique_filter_tab.toml)
local TAB_DEFAULTS = { icon = "icon_list_tab_filter09", symbol = "filter_symbol09" }
-- the id kind of a technique in the framework's id registry
local TECHNIQUE_KIND = "technique"
-- the callback the match stub calls for the rows of the added tabs
local TAB_ROWS_PASS = "TechniqueFilter.TabRowsPass"
-- the row loop stub's buffer: tension end, first added tab, added tabs, then first row and row end per tab (u32 each)
local ROW_BUFFER = { name = "technique_filter_rows", head = 12, per_tab = 8 }

local rd = VRFW.memory.read
local u32 = VRFW.ids.unsigned

local function apply(name, arg)
  local ok, r = pcall(VRFW.patch.apply, name, arg)
  if not ok then
    warn(name .. ": " .. tostring(r))
    return false
  end
  return r == true
end

local function game_rows()
  local ok1, match = pcall(VRFW.game.symbol, "Technique.FilterTensionMatch")
  local ok2, rows = pcall(VRFW.game.symbol, "Technique.FilterTensionRows")
  if not (ok1 and ok2 and match and rows) then return nil, "the filter sites are not on this build" end
  local values = {}
  for i, at in ipairs(GAME_VALUE_AT) do
    if rd("u8", match + at - 3) ~= 0x80 then return nil, "the match test is not the game's (another mod changed it)" end
    values[i] = rd("u8", match + at)
  end
  if rd("u8", rows) ~= #values then return nil, "the row count is not the game's" end
  return values
end

local function game_groups()
  local ok, site = pcall(VRFW.game.symbol, "Technique.FilterGroupsMoves")
  if not ok or not site then return nil end
  local n, rel = rd("u32", site + 2), rd("u32", site + 9)
  if not n or not rel or n == 0 or n > 8 then return nil end
  if rel >= 0x80000000 then rel = rel - 0x100000000 end
  local list = {}
  for i = 1, n do
    local g = rd("u8", site + 13 + rel + i - 1)
    if not g then return nil end
    list[i] = g
  end
  return list
end

-- the served technique table's rows, or nil and why
local function technique_rows()
  local ok, rows = pcall(VRFW.table.rows, TENSION.table)
  if not ok or type(rows) ~= "table" then return nil, TENSION.table .. " not readable: " .. tostring(rows) end
  return rows
end

-- distinct tension values of the served table's rows, ascending
local function table_values(rows)
  local seen, list = {}, {}
  for _, r in ipairs(rows) do
    local v = tonumber(r[TENSION.column])
    if v then
      v = math.max(0, math.min(255, math.floor(v)))
      if not seen[v] then
        seen[v] = true
        list[#list + 1] = v
      end
    end
  end
  table.sort(list)
  return list
end

local function declared_families()
  local ok, files = pcall(VRFW.files.declarations, FAMILY_FOLDERS, "VRFW.TechniqueFamily")
  if not ok or type(files) ~= "table" then
    warn("the technique files could not be read (" .. tostring(files) .. "): no family rows")
    return {}
  end
  local list, at = {}, {}
  for _, f in ipairs(files) do
    local v = type(f.data) == "table" and f.data.VRFW or nil
    local decls = type(v) == "table" and v.TechniqueFamily or nil
    for _, d in ipairs(type(decls) == "table" and decls or {}) do
      if type(d.name) == "string" and d.name ~= "" then
        local key = string.find(d.name, ".", 1, true) and d.name or (tostring(f.mod) .. "." .. d.name)
        local fam = { key = key, text = type(d.text) == "string" and d.text or "",
          name = string.match(key, "([^%.]+)$") or key }
        if at[key] then
          list[at[key]] = fam
        else
          list[#list + 1] = fam
          at[key] = #list
        end
      end
    end
  end
  return list
end

-- The row kinds an added tab can list: rows(tab, technique rows) -> { { text, name } }, and the tab's member(skill) ->
-- the set of its 0-based rows that hold the skill.
local ROW_KINDS = {}

-- One row per technique family of any active mod; a skill is in the rows of its families.
ROW_KINDS.families = function()
  local families = declared_families()
  local of = nil
  local function member(skill)
    if not of then
      of = {}
      for i, fam in ipairs(families) do
        local ok, moves = pcall(VRFW.technique_family, fam.key)
        for _, id in ipairs(ok and type(moves) == "table" and moves or {}) do
          local m = u32(id)
          of[m] = of[m] or {}
          of[m][i - 1] = true
        end
      end
    end
    return of[u32(skill)]
  end
  return families, member
end

-- One row for the game's techniques (the tab's base_text) and one per mod that holds a technique of the served table,
-- in the mods' load order, labelled with the mod's name from its mod.toml; a skill is in the row of the mod that holds its id.
ROW_KINDS.mods = function(tab, rows)
  local okw, owners = pcall(VRFW.ids.owners, TECHNIQUE_KIND)
  if not okw or type(owners) ~= "table" then
    warn("the technique id registry could not be read (" .. tostring(owners) .. "): no mod rows")
    return {}, function() return nil end
  end
  local held, base = {}, false
  for _, r in ipairs(rows) do
    local owner = owners[u32(r.skill_id)]
    if owner then held[owner] = true else base = true end
  end
  local list, row_of = {}, {}
  if base then list[1] = { text = tab.base_text or "", name = "" } end
  local okm, manifests = pcall(VRFW.files.declarations, "mod.toml")
  for _, f in ipairs(okm and type(manifests) == "table" and manifests or {}) do
    local id = tostring(f.mod)
    if held[id] and not row_of[id] then
      local name = type(f.data) == "table" and type(f.data.name) == "string" and f.data.name ~= "" and f.data.name or id
      list[#list + 1] = { text = "", name = name }
      row_of[id] = { [#list - 1] = true }
    end
  end
  local base_row = base and { [0] = true } or nil
  return list, function(skill)
    local owner = owners[u32(skill)]
    if owner then return row_of[owner] end
    return base_row
  end
end

-- One row per saga that holds a technique of the served table (VRFW.catalogue.sagas): the game's series in table order,
-- named by the game's series name (the row's text is the series id), then the mods' sagas in load order (the mod's
-- [saga] text key, else its display name); then the tab's none_text row for the game moves no series holds.
ROW_KINDS.series = function(tab, rows)
  local sagas = VRFW.catalogue.sagas()
  local held, none = {}, false
  for _, r in ipairs(rows) do
    local k = sagas.of[u32(r.skill_id)]
    if k ~= nil then held[k] = true else none = true end
  end
  local list, row_of = {}, {}
  for _, saga in ipairs(sagas.list) do
    if held[saga.key] and not row_of[saga.key] then
      if saga.series then
        list[#list + 1] = { text = saga.series, name = "" }
      else
        list[#list + 1] = { text = saga.text or "", name = saga.name or "" }
      end
      row_of[saga.key] = { [#list - 1] = true }
    end
  end
  local none_row = nil
  if none and type(tab.none_text) == "string" and tab.none_text ~= "" then
    list[#list + 1] = { text = tab.none_text, name = "" }
    none_row = { [#list - 1] = true }
  end
  return list, function(skill)
    local k = sagas.of[u32(skill)]
    if k ~= nil then return row_of[k] end
    return none_row
  end
end

-- the added tabs in declaration order, one per row kind (a later declaration of the same rows wins)
local function declared_tabs()
  local ok, files = pcall(VRFW.files.declarations, TAB_FOLDERS)
  if not ok or type(files) ~= "table" then return {} end
  local list, at = {}, {}
  for _, f in ipairs(files) do
    local v = type(f.data) == "table" and f.data.VRFW or nil
    local decls = type(v) == "table" and v.TechniqueFilterTab or nil
    for _, d in ipairs(type(decls) == "table" and decls or {}) do
      if not ROW_KINDS[d.rows] then
        warn(tostring(f.mod) .. ": filter tab rows \"" .. tostring(d.rows) .. "\" is not a row kind: tab left out")
      elseif type(d.text) == "string" and d.text ~= "" then
        local icon = type(d.icon) == "string" and d.icon ~= "" and d.icon or TAB_DEFAULTS.icon
        local symbol = type(d.symbol) == "string" and d.symbol ~= "" and d.symbol or TAB_DEFAULTS.symbol
        local tab = { rows = d.rows, text = d.text, base_text = type(d.base_text) == "string" and d.base_text or nil,
          none_text = type(d.none_text) == "string" and d.none_text or nil,
          icon = VRFW.crc32(icon), icon_off = VRFW.crc32(icon .. "_off"), symbol = VRFW.crc32(symbol), mod = tostring(f.mod) }
        if at[d.rows] then
          list[at[d.rows]] = tab
        else
          list[#list + 1] = tab
          at[d.rows] = #list
        end
      end
    end
  end
  return list
end

-- 4 little-endian bytes of a non-negative integer below 2^32, appended to `out`
local function push_u32(out, v)
  for _ = 1, 4 do
    out[#out + 1] = v % 256
    v = math.floor(v / 256)
  end
end

-- 8 little-endian bytes of a non-negative integer below 2^53, appended to `out`
local function push_u64(out, v)
  for _ = 1, 8 do
    out[#out + 1] = v % 256
    v = math.floor(v / 256)
  end
end

-- 8 little-endian bytes of the mask of rows first .. first + n - 1, appended to `out`
local function push_row_mask(out, first, n)
  local bytes = { 0, 0, 0, 0, 0, 0, 0, 0 }
  for row = first, first + n - 1 do
    local i = math.floor(row / 8) + 1
    bytes[i] = bytes[i] + 2 ^ (row % 8)
  end
  for _, b in ipairs(bytes) do out[#out + 1] = b end
end

-- The added tabs with their rows, built from the declarations: { rows kind, text, icon, ..., labels, member, n }.
local function build_tabs(rows, tension_rows)
  local declared = declared_tabs()
  if #declared == 0 then return {} end
  local groups = game_groups()
  local has = false
  for _, g in ipairs(groups or {}) do
    if g == TENSION_GROUP then has = true end
  end
  if not has then
    warn("the move lists' filter groups are not the game's (or not found): no added filter tabs")
    return {}
  end
  local tabs, next_row = {}, tension_rows
  for _, tab in ipairs(declared) do
    local labels, member = ROW_KINDS[tab.rows](tab, rows)
    if next_row + #labels > MAX_ROWS then
      warn(string.format("filter tab %s (%s): %d rows past the window's %d: the first %d are listed", tab.rows, tab.mod,
        next_row + #labels - MAX_ROWS, MAX_ROWS, MAX_ROWS - next_row))
      for i = #labels, MAX_ROWS - next_row + 1, -1 do labels[i] = nil end
    end
    if #labels > 0 then
      tab.labels, tab.member, tab.first, tab.index = labels, member, next_row, #groups + #tabs
      tabs[#tabs + 1] = tab
      next_row = next_row + #labels
    else
      info("filter tab " .. tab.rows .. " (" .. tab.mod .. ") has no rows: left out")
    end
  end
  TechniqueFilter.groups = groups
  return tabs
end

local function start()
  -- served values are kept across a script reload: the sites are already written
  if TechniqueFilter.values then return end
  local game, why = game_rows()
  if not game then
    info(why .. ": the filter keeps the game's rows")
    return
  end
  local rows, err = technique_rows()
  if not rows then
    warn(err .. ": the filter keeps the game's rows")
    return
  end
  local list = table_values(rows)
  if #list == 0 then
    info("no tension values in " .. TENSION.table .. ": the filter keeps the game's rows")
    return
  end
  if #list > MAX_ROWS then
    warn(string.format("%d tension values: the window lists the first %d", #list, MAX_ROWS))
    for i = #list, MAX_ROWS + 1, -1 do list[i] = nil end
  end
  local tabs = build_tabs(rows, #list)
  local same = #list == #game
  for i, v in ipairs(list) do
    if v ~= game[i] then same = false end
  end
  if same and #tabs == 0 then
    info("the table's values are the game's rows and no filter tab is added: nothing written")
    return
  end
  local callback = nil
  if #tabs > 0 then
    local ok, at = pcall(VRFW.hook.address, TAB_ROWS_PASS)
    callback = ok and type(at) == "number" and at > 0 and at or nil
    if not callback then
      warn(TAB_ROWS_PASS .. " is not installed (" .. tostring(at) .. "): no added filter tabs")
      tabs = {}
    end
  end
  local added = 0
  for _, tab in ipairs(tabs) do added = added + #tab.labels end
  -- the match stub's data: tension byte -> row index, the mask of the added tabs' rows, the callback's address
  local bytes = {}
  for v = 0, 255 do bytes[v + 1] = NO_ROW end
  for i, v in ipairs(list) do bytes[v + 1] = i - 1 end
  push_row_mask(bytes, #list, added)
  push_u64(bytes, callback or 0)
  if not apply("TechniqueFilter.Store") then
    VRFW.error("technique_filter: the row store stub was not written (see the patch line above): the filter keeps the game's rows")
    return
  end
  if not apply("TechniqueFilter.Match", { append = bytes }) then
    VRFW.error("technique_filter: the match stub was not written after the row store stub (see the patch line above): the tension tab does not filter")
    return
  end
  -- the row loop stub reads the row ranges from a buffer whose address is appended to it
  local buffer = VRFW.memory.buffer(ROW_BUFFER.name, ROW_BUFFER.head + ROW_BUFFER.per_tab * math.max(#tabs, 1))
  VRFW.memory.write("u32", buffer, #list)
  VRFW.memory.write("u32", buffer + 4, #tabs > 0 and tabs[1].index or 0)
  VRFW.memory.write("u32", buffer + 8, #tabs)
  for k, tab in ipairs(tabs) do
    local at = buffer + ROW_BUFFER.head + ROW_BUFFER.per_tab * (k - 1)
    VRFW.memory.write("u32", at, tab.first)
    VRFW.memory.write("u32", at + 4, tab.first + #tab.labels)
  end
  local loop = {}
  push_u64(loop, buffer)
  if not apply("TechniqueFilter.RowLoop", { append = loop }) then
    VRFW.error("technique_filter: the row loop stub was not written (see the patch line above): the window keeps the game's rows")
    return
  end
  if #tabs > 0 then
    local groups = {}
    for _, g in ipairs(TechniqueFilter.groups) do groups[#groups + 1] = g end
    for _ = 1, #tabs do groups[#groups + 1] = TENSION_GROUP end
    local code = string.format("C7 02 %02X 00 00 00 48 8D 05 01 00 00 00 C3", #groups)
    if not apply("TechniqueFilter.Groups", { code = code, append = groups }) then
      VRFW.error("technique_filter: the tab list stub was not written (see the patch line above): no added filter tabs")
      VRFW.memory.write("u32", buffer + 8, 0)
      tabs = {}
    end
  end
  TechniqueFilter.values = list
  TechniqueFilter.tabs = tabs
  local s, g, t = {}, {}, {}
  for i, v in ipairs(list) do s[i] = tostring(v) end
  for i, v in ipairs(game) do g[i] = tostring(v) end
  for i, tab in ipairs(tabs) do t[i] = string.format("%s %d rows in tab %d (%s)", tab.rows, #tab.labels, tab.index, tab.mod) end
  info(string.format("%d tension rows: %s (game: %s); added tabs: %s", #list, table.concat(s, " "), table.concat(g, " "),
    #t > 0 and table.concat(t, ", ") or "none"))
end

-- the membership indexes are built when a slot loads, so the first filtered list does not build them
VRFW.on("save:slot_load", function()
  for _, tab in ipairs(TechniqueFilter.tabs or {}) do pcall(tab.member, 0) end
end)

-- (skill id, filter block) -> 1 when the skill passes every added tab: a tab with none or all of its rows ticked
-- passes, else the skill must be in one of its ticked rows.
VRFW.on("hook:" .. TAB_ROWS_PASS, function(ev)
  local skill, block = ev.args[1], ev.args[2]
  local tabs = TechniqueFilter.tabs
  if not tabs then return { ret = 1 } end
  local lo, hi = rd("u32", block + 4), rd("u32", block + 8)
  if not lo or not hi then return { ret = 1 } end
  local function ticked(row)
    return bit32.btest(row < 32 and lo or hi, 2 ^ (row % 32))
  end
  for _, tab in ipairs(tabs) do
    local n = 0
    for row = tab.first, tab.first + #tab.labels - 1 do
      if ticked(row) then n = n + 1 end
    end
    if n > 0 and n < #tab.labels then
      local pass = false
      for i in pairs(tab.member(skill) or {}) do
        if ticked(tab.first + i) then pass = true end
      end
      if not pass then return { ret = 0 } end
    end
  end
  return { ret = 1 }
end)

-- (list item type) -> n, value 1, ...
function TechniqueFilter.CmdValues(list_item_type)
  local values = TechniqueFilter.values
  if tonumber(list_item_type) ~= TENSION.list_item_type or not values then return 0 end
  return #values, table.unpack(values)
end

-- -> tension rows, added tabs, then per tab: index, text key, icon, icon off, symbol (sprite hashes), rows, then the
-- text and name of each row. A row's text is a text key, or a number: a series id, named by the game's series name.
function TechniqueFilter.CmdTabs()
  local tabs, values = TechniqueFilter.tabs, TechniqueFilter.values
  if not tabs or #tabs == 0 or not values then return 0 end
  local out = {}
  for _, tab in ipairs(tabs) do
    for _, v in ipairs({ tab.index, tab.text, tab.icon, tab.icon_off, tab.symbol, #tab.labels }) do out[#out + 1] = v end
    for _, row in ipairs(tab.labels) do
      out[#out + 1] = row.text
      out[#out + 1] = row.name
    end
  end
  return #values, #tabs, table.unpack(out)
end

-- (save id, n, value 1, ...) -> true: the tension values ticked in that saved filter (n < 0 = forget)
function TechniqueFilter.CmdKeep(save_id, n, ...)
  local id, count = tonumber(save_id), tonumber(n)
  if not id or not count then return false end
  if count < 0 then
    TechniqueFilter.kept[id] = nil
    return true
  end
  local values, args = {}, { ... }
  for i = 1, math.min(count, MAX_ROWS) do
    local v = tonumber(args[i])
    if v then values[#values + 1] = v end
  end
  TechniqueFilter.kept[id] = values
  return true
end

-- (save id) -> n, value 1, ...
function TechniqueFilter.CmdKept(save_id)
  local values = TechniqueFilter.kept[tonumber(save_id) or -1]
  if not values then return -1 end
  return #values, table.unpack(values)
end

start()
