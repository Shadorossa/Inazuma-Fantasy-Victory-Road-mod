
local MAX_SET = 16
local TEAMS = 3 -- teams per set (11v11, 5v5, ...)
local KITLESS_KEY = "vrfw.team_uniform.kitless"
local SEP = "\1"

local writes = 0

local Id = VRFW.ids
local u32 = Id.unsigned

local function arg_u32(v)
  if type(v) ~= "number" then
    return nil
  end
  return u32(v)
end

-- TeamInfo record of (set, team), nil when the party is not there yet
local function team_info(set, team)
  local party = VRFW.game.party()
  if not party then
    return nil
  end
  local ok, p = pcall(VRFW.call, "Team.SetStruct", party, set, team)
  if not ok or not p or p < 0x10000 then
    return nil
  end
  local rec = VRFW.memory.struct("TeamInfo", p)
  local ok2 = rec ~= nil
  return ok2 and rec or nil
end

local function read_uniform(rec)
  local ok, u = pcall(function() return rec.uniform end)
  return ok and u or 0
end

function BetterQoL.TeamUniform(set, team, uniform, src_team)
  set, team = arg_u32(set), arg_u32(team)
  if not set or not team then
    return false, 0
  end
  local rec = (set <= MAX_SET and team < TEAMS) and team_info(set, team) or nil
  if not rec then
    return false, 0
  end
  local cur = read_uniform(rec)
  local new = arg_u32(uniform)
  if not new then
    return true, cur
  end
  local copy = false
  local src = arg_u32(src_team)
  if src and src < TEAMS and src ~= team then
    local r = team_info(set, src)
    local src_cur = r and read_uniform(r) or 0
    copy = src_cur ~= 0 and new == src_cur
  end
  local kitless_id = u32(VRFW.state.get(KITLESS_KEY) or 0)
  local kitless = kitless_id ~= 0 and cur == 0 and new == kitless_id
  if not copy and not kitless and not (cur ~= 0 and new ~= 0) then
    VRFW.warn(string.format("refused set %d team %d: uniform 0x%08X -> 0x%08X", set, team, cur, new))
    return false, cur
  end
  local ok = true
  if new ~= cur then
    ok = pcall(function() rec.uniform = new end)
  end
  if writes < 50 then
    writes = writes + 1
    local ok_inv, inv = pcall(function() return rec.uniform_item end)
    VRFW.log(string.format("set %d team %d (kit item 0x%08X): uniform 0x%08X -> 0x%08X ok=%s", set, team, ok_inv and inv or 0, cur, new, tostring(ok)))
  end
  return ok, read_uniform(rec)
end

local function cell_text(v)
  if type(v) == "table" then
    local parts = {}
    for i = 1, #v do
      parts[i] = cell_text(v[i])
    end
    for k, x in pairs(v) do
      if type(k) == "string" then
        parts[#parts + 1] = k .. "=" .. cell_text(x)
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return tostring(v)
end

local function shapes()
  local uniforms = VRFW.table.rows("character/uniform")
  local models = VRFW.table.rows("character/uniform_model_info")
  local cols = VRFW.table.columns("character/uniform_model_info")
  local type_col
  for i, c in ipairs(cols) do
    if c == "type_id" then
      type_col = i
    end
  end
  if not type_col then
    error("uniform_model_info has no type_id column")
  end
  local out = {}
  for _, row in ipairs(uniforms) do
    local id, slice = row.name_id, row.model_info
    if id and type(slice) == "table" and slice.count == 2 and slice.start >= 0 and slice.start + 2 <= #models then
      local by = {}
      for k = slice.start + 1, slice.start + 2 do
        local m = models[k]
        local ty = m[type_col]
        if ty == 0 or ty == 1 then
          local rest = {}
          for i = 1, #cols do
            if i ~= type_col then
              rest[#rest + 1] = cell_text(m[i])
            end
          end
          by[ty] = { full = table.concat(rest, SEP), main = (rest[1] or "") .. SEP .. (rest[2] or "") }
        end
      end
      if by[0] and by[1] then
        out[u32(id)] = by
      end
    end
  end
  return out
end

-- uniform id of a kit item -> item key (first item of a uniform wins)
local function kits()
  local out, n = {}, 0
  for _, row in ipairs(VRFW.table.rows("item/item_fashion")) do
    local u = u32(row.uniform)
    if u ~= 0 and out[u] == nil then
      out[u] = row.key or ""
      n = n + 1
    end
  end
  return out, n
end

local function build()
  local kit, nkits = kits()
  local shape = shapes()
  local by_full, by_main = {}, {}
  local function push(map, key, id)
    map[key] = map[key] or {}
    table.insert(map[key], id)
  end
  for id, s in pairs(shape) do
    push(by_full, s[0].full .. SEP .. SEP .. s[1].full, id)
    push(by_main, s[0].main .. SEP .. SEP .. s[1].main, id)
  end
  local order = {}
  for u, k in pairs(kit) do
    order[#order + 1] = { k, u }
  end
  table.sort(order, function(a, b)
    if a[1] ~= b[1] then
      return a[1] < b[1]
    end
    return a[2] < b[2]
  end)
  local map, back, with_twin = {}, {}, 0
  for _, e in ipairs(order) do
    local u = e[2]
    local s = shape[u]
    if s then
      local cands = by_full[s[1].full .. SEP .. SEP .. s[0].full] or {}
      if #cands == 0 then
        cands = by_main[s[1].main .. SEP .. SEP .. s[0].main] or {}
      end
      local others, in_kits = {}, {}
      for _, c in ipairs(cands) do
        if c ~= u then
          others[#others + 1] = c
          if kit[c] ~= nil then
            in_kits[#in_kits + 1] = c
          end
        end
      end
      local pref = #in_kits > 0 and in_kits or others
      local best
      for _, c in ipairs(pref) do
        if best == nil or c < best then
          best = c
        end
      end
      if best then
        map[u] = best
        with_twin = with_twin + 1
        back[#back + 1] = { u, others }
      end
    end
  end
  for _, b in ipairs(back) do
    for _, t in ipairs(b[2]) do
      if map[t] == nil then
        map[t] = b[1]
      end
    end
  end
  local ik, iov = VRFW.table.source("item/item_fashion")
  local uk, uov = VRFW.table.source("character/uniform")
  local from = function(o) return o and "mods overlay" or "game" end
  VRFW.log(string.format("kit tables: %s (%s), %s (%s); %d kit pair(s) of %d kit(s)", ik, from(iov), uk, from(uov), with_twin, nkits))
  return map
end

local pair_map
local tried = false

local function pair_map_now()
  if pair_map == nil and not tried then
    tried = true
    local ok, m = pcall(build)
    if ok then
      pair_map = m
    else
      VRFW.warn("kit pairs not built (" .. tostring(m) .. "): no kit has an away version")
      pair_map = {}
    end
  end
  return pair_map or {}
end

function BetterQoL.AwayKitPair(uniform)
  local u = arg_u32(uniform)
  if not u then
    return 0
  end
  return pair_map_now()[u] or 0
end

-- built while the framework starts (the game tables are served by then)
pair_map_now()

local SaveKits = VRFW.save.kits

local away_items_cache

-- { by_item = { [item id] = entry }, count }
local function away_items()
  if away_items_cache then return away_items_cache end
  local cfg = VRFW.config("away_kit", {})
  local keep = {}
  for _, key in ipairs(type(cfg.keep) == "table" and cfg.keep or {}) do
    if type(key) == "string" then keep[key] = true end
  end
  local items, why = SaveKits.items()
  if not items then return nil, why end
  local twins = pair_map_now()
  local found = { by_item = {}, count = 0 }
  for key, kit in pairs(items.by_key) do
    local home = SaveKits.home_of(items, key)
    if home and not keep[key] and kit.uniform ~= 0 and home.uniform ~= 0 and kit.uniform ~= home.uniform
      and (twins[home.uniform] == kit.uniform or twins[kit.uniform] == home.uniform) then
      found.by_item[kit.id] = SaveKits.entry(items, key)
      found.count = found.count + 1
    end
  end
  away_items_cache = found
  return found
end

BetterQoL.SaveAdjust = BetterQoL.SaveAdjust or {}

function BetterQoL.SaveAdjust.can_remove_away_kits()
  local ok, found = pcall(away_items)
  return ok and found ~= nil and found.count > 0
end

function BetterQoL.SaveAdjust.remove_away_kits(tree, event)
  local found, why = away_items()
  if not found then return { error = why } end
  if found.count == 0 then return { error = "no away-kit item in the kit list" } end
  local report, not_removed = SaveKits.remove(tree, found.by_item)
  if not report then return { error = not_removed } end
  local line = string.format("save adjust: remove_away_kits (slot %s): %d away-kit item(s) removed of %d known (%s)",
    tostring(event and event.slot), report.stacks, found.count, SaveKits.summary(report))
  VRFW.log(line)
  return { count = report.stacks, log = line }
end
