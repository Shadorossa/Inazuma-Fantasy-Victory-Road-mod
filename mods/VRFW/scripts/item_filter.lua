
ItemFilter = ItemFilter or {}

local info, warn = VRFW.logger("item_filter")

-- The files that declare the sections ([[VRFW.ItemFilterSection]]).
local SECTION_FOLDERS = { "content/item_filter_sections" }
-- The declaration's defaults (types\item_filter_section.toml).
local SECTION_DEFAULTS = { icon = "icon_list_tab_filter08", symbol = "filter_symbol08" }
-- The windows a section may name.
local WINDOWS = { equipment = true }
-- The window's tab strip has room for 9 tabs: the game's own one and the added ones.
local MAX_TABS = 8
-- Rows an added tab lists at most.
local MAX_ROWS = 255
-- The window's groups: a tab's group picks its row builder.
local SERIES_GROUP, STAT_GROUP = 0, 1
-- List item types of a row: a checkbox of the series group, and the «all» row of a tab.
local ROW_KIND, ALL_KIND = 1, 8
local NO_VALUE = 0xFFFFFFFF
local ROW_SIZE = 0x1C
-- The layer the game's series rows are drawn with.
local ROW_LAYER = "win07_14_chara_filter_list_item_series"
-- [added tab] = its row count: the row builder's post handler runs only for these tabs.
local TAB_TABLE = "ItemFilter.Tab"
-- The block the group stub reads: the tab count (u32), then the groups from +8.
local GROUPS = { buffer = "item_filter_groups", list = 8, size = 8 + 1 + MAX_TABS }

local u32 = VRFW.ids.unsigned

ItemFilter.rows = ItemFilter.rows or {}

-- The declared sections in load order: { name, mod, text, icon, icon_off, symbol, serve, menus = { [menu id] = true } }.
local function declared_sections()
  if ItemFilter.sections then return ItemFilter.sections end
  local list = {}
  local ok, files = pcall(VRFW.files.declarations, SECTION_FOLDERS)
  for _, f in ipairs((ok and type(files) == "table") and files or {}) do
    local v = type(f.data) == "table" and f.data.VRFW or nil
    local decls = type(v) == "table" and v.ItemFilterSection or nil
    for _, d in ipairs(type(decls) == "table" and decls or {}) do
      local where = tostring(f.mod) .. ": [[VRFW.ItemFilterSection]] " .. tostring(d.name)
      if type(d.name) ~= "string" or d.name == "" then
        warn(where .. " has no name (left out)")
      elseif not WINDOWS[d.window] then
        warn(where .. ": window \"" .. tostring(d.window) .. "\" is not a window (equipment) (left out)")
      elseif type(d.text) ~= "string" or d.text == "" then
        warn(where .. " has no text (left out)")
      elseif type(d.serve) ~= "string" or not string.find(d.serve, "^CMND_") then
        warn(where .. ": serve is not a command name (left out)")
      elseif type(d.menus) ~= "table" or #d.menus == 0 then
        warn(where .. " names no menu (left out)")
      elseif #list >= MAX_TABS then
        warn(where .. string.format(": the window has room for %d sections (left out)", MAX_TABS))
      else
        local icon = type(d.icon) == "string" and d.icon ~= "" and d.icon or SECTION_DEFAULTS.icon
        local symbol = type(d.symbol) == "string" and d.symbol ~= "" and d.symbol or SECTION_DEFAULTS.symbol
        local menus = {}
        for _, name in ipairs(d.menus) do
          if type(name) == "string" then menus[VRFW.crc32(name)] = true end
        end
        list[#list + 1] = { name = d.name, mod = tostring(f.mod), text = d.text, icon = VRFW.crc32(icon),
          icon_off = VRFW.crc32(icon .. "_off"), symbol = VRFW.crc32(symbol), serve = d.serve, menus = menus }
      end
    end
  end
  ItemFilter.sections = list
  return list
end

-- The block of the group stub, written with the game's own tabs the first time; nil when the stub is not written.
local function groups_block()
  if ItemFilter.block then return ItemFilter.block end
  local ok, block = pcall(VRFW.memory.buffer, GROUPS.buffer, GROUPS.size)
  if not ok or type(block) ~= "number" or block == 0 then
    warn("no memory block for the tab list (" .. tostring(block) .. ")")
    return nil
  end
  VRFW.memory.write("u32", block, 1)
  VRFW.memory.write("u8", block + GROUPS.list, STAT_GROUP)
  local address, v = {}, block
  for i = 1, 8 do
    address[i] = v % 256
    v = math.floor(v / 256)
  end
  local okP, written = pcall(VRFW.patch.apply, "ItemFilter.Groups", { append = address })
  if not okP or written ~= true then
    VRFW.error("item_filter: the tab list stub was not written (" .. tostring(written) .. "): the window keeps the game's tabs")
    return nil
  end
  ItemFilter.block = block
  return block
end

-- (list menu id) -> n, then per section: name, title text key, icon, icon_off, symbol (sprite hashes), serve command name
-- (0 = no section, or the item test is not hooked)
function ItemFilter.CmdSections(menu)
  if type(menu) ~= "number" or not ItemFilter.test_hook then return 0 end
  local id, out, n = u32(menu), {}, 0
  for _, s in ipairs(declared_sections()) do
    if s.menus[id] then
      n = n + 1
      out[#out + 1] = s.name
      out[#out + 1] = s.text
      out[#out + 1] = s.icon
      out[#out + 1] = s.icon_off
      out[#out + 1] = s.symbol
      out[#out + 1] = s.serve
    end
  end
  return n, table.unpack(out)
end

-- (n) -> true: the equipment filter window shows n more tabs after the game's; 0 = the game's tabs
function ItemFilter.CmdTabs(count)
  count = math.floor(tonumber(count) or -1)
  if count < 0 or count > MAX_TABS then
    warn("tabs: " .. tostring(count) .. " is not 0.." .. MAX_TABS)
    return false
  end
  ItemFilter.rows = {}
  pcall(VRFW.native.table_clear, TAB_TABLE)
  -- Nothing was ever asked for: the game's code is untouched.
  if count == 0 and not ItemFilter.block then return true end
  local block = groups_block()
  if not block then return false end
  for i = 1, count do VRFW.memory.write("u8", block + GROUPS.list + i, SERIES_GROUP) end
  VRFW.memory.write("u32", block, 1 + count)
  return true
end

-- (tab, at, value at, ...) -> true: added tab `tab` lists one checkbox row per value. A command takes 32 arguments at
-- most, so a long tab comes in several calls: `at` = the row the values start at, 1 = the tab's rows anew.
function ItemFilter.CmdTabRows(tab, at, ...)
  tab, at = math.floor(tonumber(tab) or 0), math.floor(tonumber(at) or 0)
  if tab < 1 or tab > MAX_TABS then
    warn("tab rows: tab " .. tostring(tab) .. " is not 1.." .. MAX_TABS)
    return false
  end
  local values = at == 1 and {} or ItemFilter.rows[tab]
  if values == nil or at ~= #values + 1 then
    warn(string.format("tab rows: tab %d has no row %d to go on from", tab, at - 1))
    return false
  end
  for _, x in ipairs({ ... }) do
    if type(x) == "number" and #values < MAX_ROWS then values[#values + 1] = u32(x) end
  end
  if not ItemFilter.rows_hook then
    local ok, on, why = pcall(VRFW.hook.apply, "ItemFilter.Rows")
    if not ok or on ~= true then
      VRFW.error("item_filter: the row builder hook is not installed (" .. tostring(ok and why or on) .. "): no rows")
      return false
    end
    ItemFilter.rows_hook = true
  end
  ItemFilter.rows[tab] = values
  local okT, e = pcall(VRFW.native.table_set, TAB_TABLE, tab, #values)
  if not okT then
    warn(TAB_TABLE .. ": " .. tostring(e))
    return false
  end
  return true
end

-- The rows of the tab shown, written over the series rows the game built: the «all» row, then one row per value.
local function write_rows(window)
  local w = VRFW.memory.struct("ItemFilter.Window", window)
  local tab = w.tab
  local values = ItemFilter.rows[tab]
  if not values then return end
  local rows, capacity = w.rows, w.row_capacity
  if type(rows) ~= "number" or rows == 0 or w.row_count < 1 or capacity < 1 then
    error("the game built no row for tab " .. tostring(tab))
  end
  local all = VRFW.memory.struct("ItemFilter.Row", rows)
  if all.kind ~= ALL_KIND then error("the first row of tab " .. tostring(tab) .. " is not the «all» row") end
  all.option = tab
  all.option_right = tab
  local n = math.min(#values, capacity - 1)
  local layer = VRFW.crc32(ROW_LAYER)
  for i = 1, n do
    local row = VRFW.memory.struct("ItemFilter.Row", rows + i * ROW_SIZE)
    row.kind = ROW_KIND
    row.value = values[i]
    row.option = tab
    row.value_right = NO_VALUE
    row.option_right = tab
    row.layer = layer
    row.layer_right = layer
  end
  w.row_count = n + 1
  if not ItemFilter.rows_logged then
    ItemFilter.rows_logged = true
    info(string.format("rows written: tab %d, %d row(s) (first time this session)", tab, n))
  end
end

-- ev.args = (window): after the game built the series rows of the tab shown
VRFW.on("hook:ItemFilter.Rows:post", function(ev)
  local ok, e = pcall(write_rows, ev.args[1])
  if not ok and not ItemFilter.rows_failed then
    ItemFilter.rows_failed = true
    warn("the rows of an added tab were not written (" .. tostring(e) .. "): that tab lists the game's series rows")
  end
  return nil
end)

local function start()
  local sections = declared_sections()
  if #sections == 0 then
    info("no mod declares an item filter section: the item test is not hooked")
    return
  end
  local ok, on, why = pcall(VRFW.hook.apply, "ItemFilter.Test")
  if not ok or on ~= true then
    VRFW.error("item_filter: the item test hook is not installed (" .. tostring(ok and why or on) .. "): the sections filter nothing")
    return
  end
  ItemFilter.test_hook = true
  local names = {}
  for i, s in ipairs(sections) do names[i] = s.mod .. "." .. s.name end
  info(string.format("%d section(s): %s; item test hooked", #sections, table.concat(names, " ")))
end

start()
