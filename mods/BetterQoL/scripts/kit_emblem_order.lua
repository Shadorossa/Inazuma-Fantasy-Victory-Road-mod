local Memory = VRFW.memory

local LIST_COUNT, LIST_ROWS, ROW_ITEM = 0x8, 0x10, 0x8
local MAX_ROWS = 0x898
local SORT_ALPHABETICAL = 5

local LAST = 0x7FFFFFFF
local NO_NUMBER = 0x1000000

local Id = VRFW.ids
local Catalogue = VRFW.catalogue

local u32 = Id.unsigned

local kits, emblems, typed = {}, {}, {}
local ready, typed_ready = false, false
-- typed item ids that fall in a group of [item_type_order]
local grouped = {}

local function build()
  local types, teams = Catalogue.series_types(), Catalogue.teams()
  if #types == 0 then
    error("belong_team_config: no team_number_<x> column")
  end
  -- first saga an era serves (ie -> ie1, go -> go1, areori -> ares)
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
  local function place(ti, k)
    local n = teams[ti].numbers[k]
    if n and n > 0 then
      return n
    end
    return NO_NUMBER + ti
  end

  -- first saga of each item
  local flags = {}
  for id, types in pairs(Catalogue.item_series()) do
    for k = 1, 9 do
      if types[k] then
        flags[id] = k
        break
      end
    end
  end

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

  local function selector_places(table_id, rows, map)
    local okg, game_rows = pcall(VRFW.table.game_rows, table_id)
    if not okg then
      VRFW.warn("the game's own " .. table_id .. " not readable (" .. tostring(game_rows) .. "): mod items by series")
      return
    end
    local in_game = {}
    for _, r in ipairs(game_rows) do
      in_game[u32(r.id)] = true
    end
    local game_items, mod_items = {}, {}
    for at, r in ipairs(rows) do
      local id = u32(r.id)
      if id ~= 0 then
        local row = { id = id, icon = tonumber(r.icon_index) or 0, at = at }
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
      -- last game item whose icon_index is not above this one's
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

  local function keys_of(table_id, map, owners)
    local rows, n = VRFW.table.rows(table_id), 0
    for _, r in ipairs(rows) do
      local id = u32(r.id)
      if id ~= 0 then
        map[id] = key_of(owners(r, id), id)
        n = n + 1
      end
    end
    selector_places(table_id, rows, map)
    return n
  end
  local n_kits = keys_of("item/item_fashion", kits, function(r) return by_uniform[u32(r.uniform)] end)
  local n_emblems = keys_of("item/item_emblem", emblems, function(_, id) return by_emblem[id] end)
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
  local cfg = VRFW.config("item_type_order")
  if type(cfg) ~= "table" or type(cfg.groups) ~= "table" or #cfg.groups == 0 then
    error("config.toml [item_type_order]: no groups")
  end
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
        local id = u32(r.id)
        if id ~= 0 then
          local c, sub = tonumber(r.category) or -1, tonumber(r.sub_category) or -1
          local catalog = tonumber(r.catalog_no) or LAST
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

local function on_sorted(ev)
  if (not ready and not typed_ready) or ev.args[2] == SORT_ALPHABETICAL then
    return nil
  end
  local list = ev.args[1]
  if type(list) ~= "number" or list == 0 then
    return nil
  end
  local n = Memory.read("u32", list + LIST_COUNT)
  if n == nil or n < 2 or n > MAX_ROWS then
    return nil
  end
  local rows = VRFW.memory.read_array("ptr", list + LIST_ROWS, n)
  if not rows then
    return nil
  end
  local items = {}
  for i = 1, n do
    local item = Memory.read("u32", rows[i] + ROW_ITEM)
    items[i] = item or 0
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
  if moved and not VRFW.memory.write_array("ptr", list + LIST_ROWS, out) then
    VRFW.warn(string.format("inventory order: list 0x%X not writable", list))
  end
  return nil
end

VRFW.on("hook:BetterQoL.KitEmblemOrderInventory:post", on_sorted)
