
CharaFilterTab = CharaFilterTab or {}

local info, warn = VRFW.logger("chara_filter_tab")

-- the files that declare the tab ([[VRFW.CharaFilterTab]])
local TAB_FOLDERS = { "content/chara_filter_tabs" }
-- the rows kind of the archetype tag tab, and the declaration's defaults (types\chara_filter_tab.toml)
local TAG_ROWS = "passive_tags"
local TAB_DEFAULTS = { icon = "icon_list_tab_filter08", symbol = "filter_symbol08" }
-- rows the filter's stored mask holds (bits of the u32 the store stub writes)
local MAX_ROWS = 32
-- the callback the test stub calls
local TAB_PASS = "CharaFilterTab.Pass"

local u32 = VRFW.ids.unsigned
local rd = VRFW.memory.read
local Passives = VRFW.passives

local function apply(name, arg)
  local ok, r = pcall(VRFW.patch.apply, name, arg)
  if not ok then
    warn(name .. ": " .. tostring(r))
    return false
  end
  return r == true
end

-- the window's native tab types: (bank list, album list) as the code reads them; nil, why when not readable
local function native_tab_types()
  local ok1, types = pcall(VRFW.game.symbol, "Card.CharaFilterTabTypes")
  local ok2, count = pcall(VRFW.game.symbol, "Card.CharaFilterTabCount")
  if not (ok1 and ok2 and types and count) then return nil, nil, "the tab list sites are not on this build" end
  -- the album table's lea is the site; the bank table's lea is 10 bytes before it
  local function table_at(lea)
    local rel = rd("u32", lea + 3)
    if not rel then return nil end
    if rel >= 0x80000000 then rel = rel - 0x100000000 end
    return lea + 7 + rel
  end
  -- the count function: mov eax, <bank count> 5 bytes before the site's mov edx, <album count>
  local n_bank, n_album = rd("u8", count - 5), rd("u8", count)
  local bank_at, album_at = table_at(types - 10), table_at(types)
  if not (n_bank and n_album and bank_at and album_at) then return nil, nil, "the tab lists are not readable" end
  local bank, album = {}, {}
  for i = 1, n_bank do bank[i] = rd("u8", bank_at + i - 1) end
  for i = 1, n_album do album[i] = rd("u8", album_at + i - 1) end
  return bank, album
end

-- the album's tab list gains the season slot's type after its last tab; true when written
local function extend_album()
  local bank, album, why = native_tab_types()
  if not bank then
    info(why .. ": the album's filter keeps its tabs")
    return false
  end
  -- the season slot is the bank list's last tab (the one the framework leaves out)
  local season = bank[#bank]
  for _, t in ipairs(album) do
    if t == season then
      info("the album's tab list already has the season slot: nothing written")
      return true
    end
  end
  local list = {}
  for i, t in ipairs(album) do list[i] = t end
  list[#list + 1] = season
  if not apply("CharaFilterTab.AlbumTypes", { append = list }) then
    VRFW.error("chara_filter_tab: the album's tab list stub was not written (see the patch line above): the album's filter keeps its tabs")
    return false
  end
  if not apply("CharaFilterTab.AlbumCount", string.format("%02X", #list)) then
    VRFW.error("chara_filter_tab: the album's tab count was not written (see the patch line above): the album's filter keeps its tabs")
    return false
  end
  return true
end

-- the declared tab (the last declaration wins), or nil
local function declared_tab()
  local ok, files = pcall(VRFW.files.declarations, TAB_FOLDERS)
  if not ok or type(files) ~= "table" then return nil end
  local tab = nil
  for _, f in ipairs(files) do
    local v = type(f.data) == "table" and f.data.VRFW or nil
    local decls = type(v) == "table" and v.CharaFilterTab or nil
    for _, d in ipairs(type(decls) == "table" and decls or {}) do
      if type(d.text) ~= "string" or d.text == "" then
        warn(tostring(f.mod) .. ": [[VRFW.CharaFilterTab]] " .. tostring(d.name) .. " has no text (left out)")
      elseif d.rows ~= TAG_ROWS then
        warn(tostring(f.mod) .. ": [[VRFW.CharaFilterTab]] " .. tostring(d.name) .. ": rows \"" .. tostring(d.rows)
          .. "\" is not a rows kind (" .. TAG_ROWS .. ") (left out)")
      else
        local icon = type(d.icon) == "string" and d.icon ~= "" and d.icon or TAB_DEFAULTS.icon
        local symbol = type(d.symbol) == "string" and d.symbol ~= "" and d.symbol or TAB_DEFAULTS.symbol
        if tab then info("the tab of " .. tab.mod .. " is replaced by the one of " .. tostring(f.mod)) end
        tab = { text = d.text, rows = d.rows, icon = VRFW.crc32(icon), icon_off = VRFW.crc32(icon .. "_off"),
          symbol = VRFW.crc32(symbol), mod = tostring(f.mod) }
      end
    end
  end
  return tab
end

-- one row per declared archetype tag, by tag name: { name, text key }
local function tag_rows()
  local list = {}
  for name, t in pairs(Passives.data(warn).tags) do
    local key = t.text or ""
    if key ~= "" and not string.find(key, ".", 1, true) then key = tostring(t.mod) .. "." .. key end
    list[#list + 1] = { name = name, text = key }
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

-- 8 little-endian bytes of a non-negative integer below 2^53, appended to `out`
local function push_u64(out, v)
  for _ = 1, 8 do
    out[#out + 1] = v % 256
    v = math.floor(v / 256)
  end
end

local function start()
  -- the sites are already written when the script reloads
  if CharaFilterTab.rows then return end
  local tab = declared_tab()
  if not tab then
    info("no mod declares a player filter tab: the season tab stays left out")
    return
  end
  local rows = tag_rows()
  if #rows == 0 then
    info(tab.mod .. " declares a player filter tab but no mod declares an archetype tag: no tab")
    return
  end
  if #rows > MAX_ROWS then
    warn(string.format("%d archetype tags: the tab lists the first %d", #rows, MAX_ROWS))
    for i = #rows, MAX_ROWS + 1, -1 do rows[i] = nil end
  end
  local ok, at = pcall(VRFW.hook.address, TAB_PASS)
  if not (ok and type(at) == "number" and at > 0) then
    warn(TAB_PASS .. " is not installed (" .. tostring(at) .. "): no tab")
    return
  end
  if not apply("CharaFilterTab.Store") then
    VRFW.error("chara_filter_tab: the row store stub was not written (see the patch line above): no tab")
    return
  end
  local addr = {}
  push_u64(addr, at)
  if not apply("CharaFilterTab.Test", { append = addr }) then
    VRFW.error("chara_filter_tab: the test stub was not written after the row store stub (see the patch line above): no tab")
    return
  end
  local count = string.format("%02X", #rows)
  if not (apply("CharaFilterTab.RowsTab", count) and apply("CharaFilterTab.RowsRebuild", count)) then
    VRFW.error("chara_filter_tab: the row count was not written (see the patch lines above): no tab")
    return
  end
  tab.album = extend_album()
  CharaFilterTab.rows = rows
  CharaFilterTab.tab = tab
  local names = {}
  for i, r in ipairs(rows) do names[i] = r.name end
  info(string.format("tab of %s in the season slot: %d rows (%s)%s", tab.mod, #rows, table.concat(names, " "),
    tab.album and "; the album's filter lists it too" or ""))
end

-- [chara_param id] = mask of the rows `rows` (the tab's) his character's tags tick
local function build_masks(rows)
  local bit_of = {}
  for i, r in ipairs(rows) do bit_of[r.name] = 2 ^ (i - 1) end
  local of = {}
  for _, e in ipairs(Passives.data(warn).character_tags) do
    local m = 0
    for _, t in ipairs(e.tags) do
      if bit_of[t] then m = bit32.bor(m, bit_of[t]) end
    end
    for _, card in ipairs(Passives.cards_of({ character = e.character })) do
      of[u32(card)] = m
    end
  end
  return of
end

-- the masks, built once and kept between starts (mod tags and game cards only)
local function card_masks()
  if CharaFilterTab.mask_of then return CharaFilterTab.mask_of end
  local rows = CharaFilterTab.rows
  if not rows then return nil end
  CharaFilterTab.mask_of = VRFW.derived("chara_filter_masks", nil, function() return build_masks(rows) end)
  return CharaFilterTab.mask_of
end

-- (card, ticked row mask) -> 1 when his character has a tag of a ticked row
VRFW.on("hook:" .. TAB_PASS, function(ev)
  local ok, of = pcall(card_masks)
  if not ok or not of then
    if not CharaFilterTab.index_failed then
      CharaFilterTab.index_failed = true
      warn("the card index could not be built (" .. tostring(of) .. "): the tab filters nobody out")
    end
    return { ret = 1 }
  end
  local mine = of[u32(ev.args[1])] or 0
  return { ret = bit32.band(mine, u32(ev.args[2])) ~= 0 and 1 or 0 }
end)

-- () -> n, tab text key, icon, icon_off, symbol, album (1 = the album's filter lists it), then per row: text key, name
-- (0 = no tab)
function CharaFilterTab.CmdTab()
  local rows, tab = CharaFilterTab.rows, CharaFilterTab.tab
  if not rows or not tab then return 0 end
  local out = {}
  for _, r in ipairs(rows) do
    out[#out + 1] = r.text
    out[#out + 1] = r.name
  end
  return #rows, tab.text, tab.icon, tab.icon_off, tab.symbol, tab.album and 1 or 0, table.unpack(out)
end

start()
-- built at load, so neither a slot load nor the first filtered list builds it
if CharaFilterTab.rows then
  local ok, e = pcall(card_masks)
  if not ok then warn("the card index could not be built at load (" .. tostring(e) .. ")") end
end
