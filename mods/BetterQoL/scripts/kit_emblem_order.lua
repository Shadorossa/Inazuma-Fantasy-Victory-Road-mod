-- BetterQoL › kit and emblem order (feature kit_emblem_order, always on). In the inventory («Objetos», item_menu),
-- the kits tab and the emblems tab list their items by saga (IE1, IE2, IE3, GO, Chrono Stone, Galaxy, Ares, Orion,
-- Victory Road, then the mods' series), and inside a saga by that saga's team order; items of no team come at the end
-- of their saga, items of no saga at the very end. The «Coleccionables» and «Consumibles» tabs list their items by
-- type: the groups of config.toml [item_type_order] (category / sub_category of the item's item_config row), then the
-- catalog number. Other tabs and the alphabetical sort (sort type 5) keep the game's order. Hook and the list layout:
-- content\game\kit_emblem_order.toml.
--
-- Everything comes from the tables the game loads (the mods' rows included); the series types, eras and belong teams
-- through the framework's game catalogue (VRFW/lib/game_catalogue):
-- * saga of an item: the first series flag of its ITEM_*_INFO_SERIES row (the row after it in the file), else the
--   first series of the era column (team_kit_<era> / team_emblem_id_<era>) that names it;
-- * sagas: the series types in their column order (team_number_<x> of belong_team_config);
-- * team of an item: belong_team_config, a kit = the uniform (item_config ITEM_FASHION_INFO column `uniform`) in one
--   of the team's team_kit_<era> columns, an emblem = the item in one of its team_emblem_id_<era> columns;
-- * team order inside a saga: the team's number in that saga's team_number_<x> column; a team without one follows,
--   in table order. An item of several teams takes the best-placed one.
-- The items mods add stand where the team kit and emblem pickers show them (selector_places): those lists are the game's
-- ItemListSort with sort type 8, whose key for a kit or a crest is its icon_index. A mod's item follows the game's item
-- before it by icon_index, and one above every game item ends the list. A clone of a game row keeps that row's series
-- flags, so the flags say nothing about it. The game's items keep their order among themselves.

local ITEM_KEY = "data/common/gamedata/item/item_config_*.cfg.bin"

-- the item list (the list view's +0x1E0): u32 count at +0x8, row pointers at +0x10; a row's item id at +0x8
local LIST_COUNT, LIST_ROWS, ROW_ITEM = 0x8, 0x10, 0x8
local MAX_ROWS = 0x898
local SORT_ALPHABETICAL = 5

local LAST = 0x7FFFFFFF
local NO_NUMBER = 0x1000000

local Id = require "VRFW/lib/ids"
local Catalogue = require "VRFW/lib/game_catalogue"

local function u32(v)
  if type(v) ~= "number" then
    return 0
  end
  return Id.u32(v)
end

-- the first value of `row` among `names`
local function col(row, ...)
  for _, n in ipairs({ ... }) do
    if row[n] ~= nil then
      return row[n]
    end
  end
  return nil
end

-- item id -> sort key { … }; kits, emblems and typed items apart (a tab is re-ordered when all its rows are of one)
local kits, emblems, typed = {}, {}, {}
local ready, typed_ready = false, false
-- typed item ids that fall in a group of [item_type_order]
local grouped = {}

local function build()
  local types, teams = Catalogue.series_types(), Catalogue.teams()
  if #types == 0 then
    error("belong_team_config: no team_number_<x> column")
  end
  -- the first saga an era serves (ie -> ie1, go -> go1, areori -> ares, v -> v)
  local function era_saga(era)
    return Catalogue.first_type_of_era(era) or LAST
  end

  -- uniform / emblem item -> its teams { { team index, era saga } … }
  local by_uniform, by_emblem = {}, {}
  local function add(map, id, ti, saga)
    if id ~= 0 then
      map[id] = map[id] or {}
      local l = map[id]
      l[#l + 1] = { ti, saga }
    end
  end
  for ti, t in ipairs(teams) do
    for era, id in pairs(t.kits) do
      add(by_uniform, id, ti, era_saga(era))
    end
    for era, id in pairs(t.emblems) do
      add(by_emblem, id, ti, era_saga(era))
    end
  end
  -- a team's place in saga k: its number there, else after the numbered teams in table order
  local function place(ti, k)
    local n = teams[ti].numbers[k]
    if n and n > 0 then
      return n
    end
    return NO_NUMBER + ti
  end

  -- series flags (the ITEM_*_INFO_SERIES row after the item's row, file order)
  local flags = {}
  local okk, key = pcall(VRFW.table.source, "item/item_fashion")
  local ok, ents = pcall(VRFW.table.entries, okk and key or ITEM_KEY,
    { "ITEM_FASHION_INFO", "ITEM_FASHION_INFO_SERIES", "ITEM_EMBLEM_INFO", "ITEM_EMBLEM_INFO_SERIES" }, true)
  if ok and type(ents) == "table" then
    local cur = nil
    for _, e in ipairs(ents) do
      if e.name == "ITEM_FASHION_INFO" or e.name == "ITEM_EMBLEM_INFO" then
        cur = u32(e[1])
      elseif e.name == "ITEM_FASHION_INFO_SERIES" or e.name == "ITEM_EMBLEM_INFO_SERIES" then
        if cur and flags[cur] == nil then
          for k = 1, 9 do
            local v = e[k]
            if v == true or (type(v) == "number" and v ~= 0) then
              flags[cur] = k
              break
            end
          end
        end
        cur = nil
      end
    end
  else
    VRFW.warn("item_config series rows not readable (" .. tostring(ents) .. "): sagas from the team's era columns")
  end

  -- { saga, place }: the saga from the flags, else the owners' earliest era; the best place among the owners
  local function key_of(owners, id)
    local saga = flags[id]
    if saga == nil then
      saga = LAST
      for _, o in ipairs(owners or {}) do
        if o[2] < saga then
          saga = o[2]
        end
      end
    end
    local best = LAST
    if saga ~= LAST then
      for _, o in ipairs(owners or {}) do
        local p = place(o[1], saga)
        if p < best then
          best = p
        end
      end
    end
    return { saga, best }
  end

  -- the mods' rows of `table_id` get the pickers' place in `map`, which holds every row by the rules above; the game's
  -- rows stay
  local function selector_places(table_id, rows, map)
    local okg, game_rows = pcall(VRFW.table.game_rows, table_id)
    if not okg then
      VRFW.warn("the game's own " .. table_id .. " not readable (" .. tostring(game_rows) .. "): mod items by series")
      return
    end
    local in_game = {}
    for _, r in ipairs(game_rows) do
      in_game[u32(col(r, "id"))] = true
    end
    local game_items, mod_items = {}, {}
    for at, r in ipairs(rows) do
      local id = u32(col(r, "id"))
      if id ~= 0 then
        local row = { id = id, icon = tonumber(col(r, "icon_index")) or 0, at = at }
        local list = in_game[id] and game_items or mod_items
        list[#list + 1] = row
      end
    end
    if #game_items == 0 then
      return
    end
    table.sort(game_items, function(a, b)
      if a.icon ~= b.icon then
        return a.icon < b.icon
      end
      return a.at < b.at
    end)
    for _, m in ipairs(mod_items) do
      -- the last game item whose icon_index is not above this one's
      local low, high = 0, #game_items
      while low < high do
        local mid = math.floor((low + high + 1) / 2)
        if game_items[mid].icon <= m.icon then
          low = mid
        else
          high = mid - 1
        end
      end
      if low == #game_items and m.icon > game_items[low].icon then
        map[m.id] = { LAST, LAST }
      elseif low == 0 then
        map[m.id] = { 0, 0 }
      else
        map[m.id] = map[game_items[low].id]
      end
    end
  end

  local n_kits, n_emblems = 0, 0
  local kit_rows, emblem_rows = VRFW.table.rows("item/item_fashion"), VRFW.table.rows("item/item_emblem")
  for _, r in ipairs(kit_rows) do
    local id = u32(col(r, "id"))
    if id ~= 0 then
      kits[id] = key_of(by_uniform[u32(col(r, "uniform"))], id)
      n_kits = n_kits + 1
    end
  end
  for _, r in ipairs(emblem_rows) do
    local id = u32(col(r, "id"))
    if id ~= 0 then
      emblems[id] = key_of(by_emblem[id], id)
      n_emblems = n_emblems + 1
    end
  end
  selector_places("item/item_fashion", kit_rows, kits)
  selector_places("item/item_emblem", emblem_rows, emblems)
  ready = true
  VRFW.log(string.format("kit / emblem order: %d kits, %d emblems, %d sagas, %d teams", n_kits, n_emblems, #types,
    #teams))
end

local ok, err = pcall(build)
if not ok then
  VRFW.warn("kit / emblem order off: " .. tostring(err))
end

-- item id -> { group, place of the sub_category in the group, catalog number } from config.toml [item_type_order]
local function build_types()
  local cfg = VRFW.files.config("item_type_order")
  if type(cfg) ~= "table" or type(cfg.groups) ~= "table" or #cfg.groups == 0 then
    error("config.toml [item_type_order]: no groups")
  end
  -- category -> sub_category -> { group, place }; category -> group for a group of the whole category
  local by_sub, by_category = {}, {}
  for g, rule in ipairs(cfg.groups) do
    local c = tonumber(rule.category)
    if c then
      if type(rule.sub_categories) == "table" and #rule.sub_categories > 0 then
        by_sub[c] = by_sub[c] or {}
        for p, sub in ipairs(rule.sub_categories) do
          local n = tonumber(sub)
          if n and by_sub[c][n] == nil then
            by_sub[c][n] = { g, p }
          end
        end
      elseif by_category[c] == nil then
        by_category[c] = g
      end
    else
      VRFW.warn(string.format("item type order: group %d (%s) has no category", g, tostring(rule.name)))
    end
  end
  local no_group = #cfg.groups + 1
  local tables = type(cfg.tables) == "table" and cfg.tables or { "item/item_consume", "item/item_important" }
  local n, n_grouped = 0, 0
  for _, t in ipairs(tables) do
    local okr, rows = pcall(VRFW.table.rows, t)
    if okr and type(rows) == "table" then
      for _, r in ipairs(rows) do
        local id = u32(col(r, "id"))
        if id ~= 0 then
          local c, sub = tonumber(col(r, "category")) or -1, tonumber(col(r, "sub_category")) or -1
          local catalog = tonumber(col(r, "catalog_no")) or LAST
          local hit = by_sub[c] and by_sub[c][sub]
          local key
          if hit then
            key = { hit[1], hit[2], catalog }
          elseif by_category[c] then
            key = { by_category[c], sub, catalog }
          else
            key = { no_group, c * 0x10000 + sub, catalog }
          end
          if typed[id] == nil then
            n = n + 1
            if key[1] ~= no_group then
              grouped[id] = true
              n_grouped = n_grouped + 1
            end
          end
          typed[id] = key
        end
      end
    else
      VRFW.warn("item type order: table " .. tostring(t) .. " not readable (" .. tostring(rows) .. ")")
    end
  end
  typed_ready = n > 0
  VRFW.log(string.format("item type order: %d items, %d in %d groups", n, n_grouped, #cfg.groups))
end

local okt, errt = pcall(build_types)
if not okt then
  VRFW.warn("item type order off: " .. tostring(errt))
end

-- the map whose keys order this tab: kits only, emblems only, or typed items only with one of them in a group
local function tab_map(items)
  local all_kits, all_emblems, all_typed, any_grouped = ready, ready, typed_ready, false
  for _, item in ipairs(items) do
    all_kits = all_kits and kits[item] ~= nil
    all_emblems = all_emblems and emblems[item] ~= nil
    all_typed = all_typed and typed[item] ~= nil
    any_grouped = any_grouped or grouped[item] == true
  end
  return (all_kits and kits) or (all_emblems and emblems) or (all_typed and any_grouped and typed) or nil
end

-- after the game sorted the inventory tab: a tab of kits only, emblems only or typed items only gets its rows by their
-- key ({ saga, place } or { group, place in the group, catalog number }), then the game's order
local function on_sorted(ev)
  if (not ready and not typed_ready) or ev.args[2] == SORT_ALPHABETICAL then
    return nil
  end
  local list = ev.args[1]
  if type(list) ~= "number" or list == 0 then
    return nil
  end
  local okn, n = pcall(VRFW.mem.read, "u32", list + LIST_COUNT)
  if not okn or n < 2 or n > MAX_ROWS then
    return nil
  end
  local rows = VRFW.mem.read_array("ptr", list + LIST_ROWS, n)
  if not rows then
    return nil
  end
  local items = {}
  for i = 1, n do
    local oki, item = pcall(VRFW.mem.read, "u32", rows[i] + ROW_ITEM)
    items[i] = oki and item or 0
  end
  local map = tab_map(items)
  if not map then
    return nil
  end
  local order = {}
  for i = 1, n do
    order[i] = { key = map[items[i]], at = i }
  end
  table.sort(order, function(a, b)
    for k = 1, #a.key do
      if a.key[k] ~= b.key[k] then
        return a.key[k] < b.key[k]
      end
    end
    return a.at < b.at
  end)
  local out, moved = {}, false
  for i, o in ipairs(order) do
    out[i] = rows[o.at]
    moved = moved or o.at ~= i
  end
  if moved and not VRFW.mem.write_array("ptr", list + LIST_ROWS, out) then
    VRFW.warn(string.format("inventory order: list 0x%X not writable", list))
  end
  return nil
end

VRFW.on("hook:BetterQoL.KitEmblemOrderInventory:post", on_sorted)
