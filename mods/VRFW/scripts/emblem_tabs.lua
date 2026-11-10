-- Emblem picker tabs of the mods: the declared tabs, the emblems each one lists and the picker list's filter by them.
EmblemTabs = EmblemTabs or {}

local D = VRFW.declarations
local Memory = VRFW.memory
local Catalogue = VRFW.catalogue
local u32 = VRFW.ids.unsigned

local info, warn = VRFW.logger("emblem_tabs")

-- The item list (ItemListSort's first argument): its row count, its row pointers, and the item id of a row.
local LIST_COUNT, LIST_ROWS, ROW_ITEM = 0x8, 0x10, 0x8
-- The picker view holds the list at + 0x1E0 and the rows' records (0x28 bytes each) from + 0x46BC (rebuild 0x1076400).
local VIEW_LIST, VIEW_RECORDS, RECORD_SIZE, MAX_ROWS = 0x1E0, 0x46BC, 0x28, 0x898
local RECORD_WORDS = math.floor(RECORD_SIZE / 4)

local ITEM_TABLES_FILE = "content/base_tables/gamedata/item/item_config.toml"
local EMBLEM_TABLE = "item/item_emblem"
local TEAMS_FOLDER = "content/teams"
-- The name text the team build gives an emblem made from an image: crc32 of the team's key and this suffix.
local TEAM_EMBLEM_SUFFIX = "_emblem"

local TABS = nil       -- the declared tabs in bar order: { key, mod, icon, icon_off, set = { [emblem] = true }, count }
local BY_KEY = {}
local ACTIVE = nil     -- The picker's list is kept to this tab.

-- Mod -> { [emblem] = true } of the emblem rows the mods' own item tables add.
local function table_emblems()
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, ITEM_TABLES_FILE)
  if not ok or type(files) ~= "table" then return out end
  for _, f in ipairs(files) do
    for _, keyed in ipairs(type(f.data) == "table" and type(f.data.keyed) == "table" and f.data.keyed or {}) do
      if keyed.table == EMBLEM_TABLE and type(keyed.add) == "table" then
        for _, row in ipairs(keyed.add) do
          local id = D.id_of(row.key)
          if id and id ~= 0 then
            out[f.mod] = out[f.mod] or {}
            out[f.mod][u32(id)] = true
          end
        end
      end
    end
  end
  return out
end

-- Mod -> { [emblem] = true } of the emblems the mods' teams make from an image (found by their name text).
local function team_emblems()
  local out = {}
  local ok, files = pcall(VRFW.files.declarations, TEAMS_FOLDER)
  if not ok or type(files) ~= "table" then return out end
  local marks = {}
  for _, f in ipairs(files) do
    for _, team in ipairs(type(f.data) == "table" and type(f.data.team) == "table" and f.data.team or {}) do
      if type(team.emblem) == "table" and team.emblem.png ~= nil then
        for _, name in ipairs({ team.key, team.name }) do
          if type(name) == "string" then marks[u32(D.id_of(name .. TEAM_EMBLEM_SUFFIX))] = f.mod end
        end
      end
    end
  end
  if next(marks) == nil then return out end
  local okr, rows = pcall(VRFW.table.rows, EMBLEM_TABLE)
  if not okr or type(rows) ~= "table" then
    warn("emblem table not readable (" .. tostring(rows) .. "): no team emblem joins a tab")
    return out
  end
  for _, row in ipairs(rows) do
    local mod = marks[u32(row.name_text)]
    local id = u32(row.id or row[1])
    if mod and id ~= 0 then
      out[mod] = out[mod] or {}
      out[mod][id] = true
    end
  end
  return out
end

local function count(set)
  local n = 0
  for _ in pairs(set) do n = n + 1 end
  return n
end

local function load()
  if TABS then return TABS end
  TABS = {}
  local schema, why = D.schema("emblem_tab")
  if not schema then
    warn(why .. ": the emblem picker has no mod tabs")
    return TABS
  end
  local decls = D.load(schema, warn)
  if #decls == 0 then
    info("no mod declares an emblem tab")
    return TABS
  end
  local from_tables, from_teams = table_emblems(), team_emblems()
  local known = Catalogue.emblem_ids() or {}
  for _, d in ipairs(decls) do
    local v, set, source = d.v, {}, nil
    if d.given.emblems then
      for _, name in ipairs(v.emblems) do
        local id = D.id_of(name)
        if id then set[u32(id)] = true end
      end
      source = "its emblems list"
    else
      local tables, teams = from_tables[d.mod] or {}, from_teams[d.mod] or {}
      for id in pairs(tables) do set[id] = true end
      for id in pairs(teams) do set[id] = true end
      source = string.format("%d item table row(s), %d team image emblem(s)", count(tables), count(teams))
    end
    local unknown = 0
    for id in pairs(set) do
      if not known[id] then unknown = unknown + 1 end
    end
    for id in pairs(known) do
      if set[id] then set[id] = "known" end
    end
    local listed = {}
    for id, state in pairs(set) do
      if state == "known" then listed[id] = true end
    end
    local n = count(listed)
    if n == 0 then
      warn(string.format("%s: no emblem to list (%s, %d not in the emblem table): left out", d.where, source, unknown))
    elseif BY_KEY[d.key] then
      warn(string.format("%s: tab %s is declared twice: left out", d.where, d.key))
    else
      local tab = { key = d.key, mod = d.mod, order = v.order or 0, icon = u32(D.id_of(v.icon)),
        icon_off = u32(D.id_of(v.icon_off or v.icon)), set = listed, count = n }
      TABS[#TABS + 1] = tab
      BY_KEY[d.key] = tab
      info(string.format("tab %s: %d emblem(s) (%s, %d not in the emblem table)", d.key, n, source, unknown))
    end
  end
  table.sort(TABS, function(a, b)
    if a.order ~= b.order then return a.order < b.order end
    return a.key < b.key
  end)
  return TABS
end

--- CMND_VRFW_EMBLEM_TABS() -> array of { key, mod, icon, icon_off, emblems } in bar order.
function EmblemTabs.List()
  local out = {}
  for i, tab in ipairs(load()) do
    out[i] = { key = tab.key, mod = tab.mod, icon = tab.icon, icon_off = tab.icon_off, emblems = tab.count }
  end
  return out
end

--- CMND_VRFW_EMBLEM_TAB_SELECT(key) -> the emblem count of the tab; "" selects no tab (0).
function EmblemTabs.Select(key)
  load()
  ACTIVE = type(key) == "string" and BY_KEY[key] or nil
  if type(key) == "string" and key ~= "" and ACTIVE == nil then
    warn("select: no tab " .. key)
  end
  return ACTIVE and ACTIVE.count or 0
end

-- The rebuilt list keeps the rows of the active tab's emblems: their records move to the front of the view's record
-- array in the built order, the other records are cleared as the rebuild clears them, and the count shrinks.
local function on_built(ev)
  local tab = ACTIVE
  if tab == nil then return nil end
  local list = ev.args[1]
  if type(list) ~= "number" or list == 0 then return nil end
  local n = Memory.read("u32", list + LIST_COUNT)
  if n == nil or n == 0 or n > MAX_ROWS then return nil end
  local rows = Memory.read_array("ptr", list + LIST_ROWS, n)
  if not rows then return nil end
  local records = list - VIEW_LIST + VIEW_RECORDS
  local emblems = Catalogue.emblem_ids() or {}
  local kept, emblem_rows = {}, 0
  for i = 1, n do
    local at = rows[i] - records
    if at < 0 or at % RECORD_SIZE ~= 0 or at >= MAX_ROWS * RECORD_SIZE then
      warn(string.format("filter: tab %s: row %d of list 0x%X is not a record of its view: list left as built", tab.key, i, list))
      return nil
    end
    local words = Memory.read_array("u32", rows[i], RECORD_WORDS)
    if not words then
      warn(string.format("filter: tab %s: row %d of list 0x%X not readable: list left as built", tab.key, i, list))
      return nil
    end
    local item = u32(words[math.floor(ROW_ITEM / 4) + 1])
    if emblems[item] then emblem_rows = emblem_rows + 1 end
    if tab.set[item] then kept[#kept + 1] = words end
  end
  if emblem_rows == 0 then
    info(string.format("filter: tab %s: a list of %d row(s) without emblems is not the emblem picker's: left as built", tab.key, n))
    return nil
  end
  local blank = {}
  for w = 1, RECORD_WORDS do blank[w] = 0 end
  local pointers = {}
  for i = 1, n do
    local record = records + (i - 1) * RECORD_SIZE
    pointers[i] = record
    if not Memory.write_array("u32", record, kept[i] or blank) then
      warn(string.format("filter: tab %s: list 0x%X not writable at record %d", tab.key, list, i))
      return nil
    end
  end
  if not (Memory.write_array("ptr", list + LIST_ROWS, pointers) and Memory.write("u32", list + LIST_COUNT, #kept)) then
    warn(string.format("filter: tab %s: list 0x%X not writable", tab.key, list))
    return nil
  end
  info(string.format("filter: tab %s (mod %s): %d of %d emblem(s) kept", tab.key, tab.mod, #kept, n))
  return nil
end

VRFW.on("hook:VRFW.EquipPickerListBuilt:post", on_built)

-- The tabs and their emblem sets are read once, when the script loads, so the picker's commands answer from them.
local loaded, why = pcall(load)
if not loaded then
  TABS = nil
  warn("tabs not read at load (" .. tostring(why) .. "): read again at the first use")
end
