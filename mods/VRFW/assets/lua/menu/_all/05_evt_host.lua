-- menu_engine: VRFW_Host, the hook points of the framework's host patches. Defined in every
-- script VM (lua\_all runs after each retail chunk, before every stem folder of every mod root). It only defines tables
-- and functions: no engine call happens here (funcLuaCommand does not exist while a chunk loads).
--
-- A HOST is the one patch that owns a retail script for the framework: it replaces the named global functions of the
-- script (its hook points) with dispatchers, once, and exposes the chunk's locals (H.L) and named lists. Every mod then
-- registers HANDLERS from its own patch file (its own chunk, so no merged file and no locals limit). The hook points
-- are not listed anywhere: a global function of the script becomes one when a mod registers a handler for it.
--
--   VRFW_Host.on("title_menu_2", "OnEnter", { id = "my_mod.button", phase = "around",
--                                             fn = function(nxt, a1, a2) ... return nxt(a1, a2) end })
--   VRFW_Host.on(stem, "Step",   { id = "my_mod.tick", phase = "after", fn = function(r, ...) end })
--   VRFW_Host.on(stem, "OnInit", { id = "my_mod.reset", phase = "before", priority = -10, fn = function(...) end })
--   VRFW_Host.on(stem, "FinalizeMenu", { ..., create = true })   -- hooked even if the script does not define it
--   VRFW_Host.on(stem, "@edit",  { id = "my_mod.rows", fn = function(L, host) table.insert(L.t4, 9) end })
--   VRFW_Host.add(stem, "option_rows", { id = "my_mod.row", value = row })      -- a named list of the host
--
-- Phases: before fn(...) (return VRFW_Host.HALT, ... to return those values at once); around fn(nxt, ...) (call nxt to
-- go on; the first around in the order is the outermost); after fn(r, ...) (r = table.pack of the results; edit r to
-- change them). Order: priority (lower first, default 0), then after / before = { "<mod>.<name>" | "<mod>" } (soft:
-- a missing one is ignored), then registration order. requires = { "<mod>.<name>" } is hard: without it the handler
-- does not run (logged once). Before / after / @edit handlers run in pcall (an error is logged once, the others go
-- on); around handlers are called directly.
--
-- Registering before this file ran (from an `_all` of a lua_early root): VRFW_HOST_Q = VRFW_HOST_Q or {};
-- table.insert(VRFW_HOST_Q, { "on", stem, point, spec }) -- drained here.
local VERSION = 1
local host = VRFW_Host
if type(host) ~= "table" then
  host = type(EVT_Host) == "table" and EVT_Host or {}   -- a 1.x early patch that made the table under the old name
  VRFW_Host = host
end
-- 1.x name: the same table under the old name, so mods written for 1.x keep working
EVT_Host = host

-- the retail closures of this VM's chunk(s), before any stem patch replaced them (the locals map reads their upvalues)
host.retail = host.retail or {}
for k, v in next, _ENV do
  if type(v) == "function" and type(k) == "string" and host.retail[k] == nil then
    host.retail[k] = v
  end
end

if (host.version or 0) >= VERSION then
  return          -- a second chunk in the same VM: keep the registry (only the snapshot above was refreshed)
end
host.version = VERSION

local DEBUG_LIBRARY = EVT_DEBUG
local LOG = VRFW_Cmd.EVT_LOG          -- crc32("CMND_EVT_LOG")
local pack, unpack = table.pack, table.unpack

host.HALT = host.HALT or setmetatable({}, { __tostring = function() return "VRFW_Host.HALT" end })
host.reg = host.reg or {}             -- reg[stem][point] = { entry, ... } (every phase; entries keep their registration seq)
host.hosts = host.hosts or {}         -- hosts[stem] = { stem, points = { [fn name] = point }, lists = {}, map = {}, L, done, listed, egen }
host.ids = host.ids or {}             -- handler id -> true, mod -> true (requires / after / before targets)
host.seq = host.seq or 0
host.gen = host.gen or 0              -- bumped by every registration: the dispatchers rebuild their order lazily
host.notes = host.notes or {}         -- log lines waiting for the engine (written at the first dispatch)
host.noted = host.noted or {}

local PHASES = { before = true, after = true, around = true, edit = true, item = true }
local CALLS = { before = true, after = true, around = true }   -- phases that hook a global function
local hook_point                -- (host, function name, create): defined with the hosts below

local function list_of(v)
  if v == nil then
    return {}
  elseif type(v) == "string" then
    return { v }
  elseif type(v) == "table" then
    return v
  end
  error("VRFW_Host: a list of handler ids or a string expected", 3)
end

-- one log line (once per text per VM); kept until the engine is there
function host.note(stem, text)
  local key = tostring(stem) .. "|" .. text
  if host.noted[key] then
    return
  end
  host.noted[key] = true
  host.notes[#host.notes + 1] = { tostring(stem), text }
  host.flush()
end

function host.flush()
  if #host.notes == 0 or type(funcLuaCommand) ~= "function" then
    return
  end
  local pending_notes = host.notes
  host.notes = {}
  for _, note in ipairs(pending_notes) do
    pcall(funcLuaCommand, LOG, "evt_host", note[1], note[2])
  end
end

-- ---- registration ---------------------------------------------------------------------------------------------------
local function caller_mod()
  local patch_file = EVT_PATCH and EVT_PATCH.file
  return type(patch_file) == "string" and patch_file:match("^mods/([^/]+)/") or nil
end

-- Register (or replace, same stem + point + id) a handler. Returns the entry.
function host.on(stem, point, spec)
  if type(stem) ~= "string" or type(point) ~= "string" or type(spec) ~= "table" then
    error("VRFW_Host.on(stem, point, spec): strings and a table expected", 2)
  end
  local id = spec.id
  if type(id) ~= "string" or not id:find(".", 1, true) then
    error("VRFW_Host.on: " .. stem .. ":" .. point .. ": spec.id must be \"<mod>.<name>\"", 2)
  end
  local phase = spec.phase or (point == "@edit" and "edit") or "around"
  if not PHASES[phase] then
    error("VRFW_Host.on: " .. id .. ": phase must be before, after or around", 2)
  end
  if phase ~= "item" and type(spec.fn) ~= "function" then
    error("VRFW_Host.on: " .. id .. ": spec.fn must be a function", 2)
  end
  local points_of_stem = host.reg[stem]
  if points_of_stem == nil then
    points_of_stem = {}
    host.reg[stem] = points_of_stem
  end
  local list = points_of_stem[point]
  if list == nil then
    list = {}
    points_of_stem[point] = list
  end
  local entry
  for _, existing in ipairs(list) do
    if existing.id == id and existing.phase == phase then
      entry = existing
      break
    end
  end
  if entry == nil then
    host.seq = host.seq + 1
    entry = { seq = host.seq }
    list[#list + 1] = entry
  end
  entry.id, entry.phase, entry.fn, entry.value = id, phase, spec.fn, spec.value
  entry.stem, entry.point, entry.mod = stem, point, id:match("^(.-)%.[^.]*$")
  entry.priority = tonumber(spec.priority) or 0
  entry.after, entry.before, entry.requires = list_of(spec.after), list_of(spec.before), list_of(spec.requires)
  entry.from = caller_mod()
  entry.create = spec.create == true
  host.ids[id], host.ids[entry.mod] = true, true
  host.gen = host.gen + 1
  -- registered after the host ran (a mod root after the framework's): hooked now, at this file's place in the chain
  local menu_host = host.hosts[stem]
  if menu_host ~= nil and CALLS[phase] then
    hook_point(menu_host, point, entry.create)
  end
  return entry
end

-- Remove a handler (every phase of that id on that point).
function host.off(stem, point, id)
  local list = host.reg[stem] and host.reg[stem][point]
  if list == nil then
    return
  end
  for i = #list, 1, -1 do
    if list[i].id == id then
      table.remove(list, i)
    end
  end
  host.gen = host.gen + 1
end

-- An item of a host's named list (see H.items).
function host.add(stem, list, item)
  if type(item) ~= "table" then
    error("VRFW_Host.add(stem, list, item): a table expected", 2)
  end
  local spec = {}
  for k, v in pairs(item) do
    spec[k] = v
  end
  spec.phase = "item"
  return host.on(stem, list, spec)
end

-- A handler id (or a whole mod) is registered somewhere in this VM.
function host.has(ref)
  return host.ids[ref] == true
end

-- ---- order ----------------------------------------------------------------------------------------------------------
local function matches(ref, entry)
  return ref == entry.id or ref == entry.mod
end

-- The entries of one phase in their run order: requires checked, priority, after / before, registration order.
function host.order(stem, point, phase)
  local live = {}
  for _, entry in ipairs((host.reg[stem] and host.reg[stem][point]) or {}) do
    if entry.phase == phase then
      local ok = true
      for _, required_id in ipairs(entry.requires) do
        if not host.has(required_id) then
          ok = false
          host.note(stem, entry.id .. " (" .. point .. ") does not run: requires " .. required_id .. ", which is not registered")
        end
      end
      if ok then
        live[#live + 1] = entry
      end
    end
  end
  table.sort(live, function(left, right)
    if left.priority ~= right.priority then
      return left.priority < right.priority
    end
    return left.seq < right.seq
  end)
  local count = #live
  if count < 2 then
    return live
  end
  local runs_before, in_degree = {}, {}
  for i = 1, count do
    runs_before[i], in_degree[i] = {}, 0
  end
  local function edge(earlier, later)   -- a runs before b
    if not runs_before[earlier][later] then
      runs_before[earlier][later] = true
      in_degree[later] = in_degree[later] + 1
    end
  end
  for i = 1, count do
    local entry = live[i]
    for j = 1, count do
      if i ~= j then
        for _, ref in ipairs(entry.after) do
          if matches(ref, live[j]) then
            edge(j, i)
          end
        end
        for _, ref in ipairs(entry.before) do
          if matches(ref, live[j]) then
            edge(i, j)
          end
        end
      end
    end
  end
  local out, done = {}, {}
  for _ = 1, count do
    local pick
    for i = 1, count do
      if not done[i] and in_degree[i] == 0 then
        pick = i
        break
      end
    end
    if pick == nil then
      for i = 1, count do       -- a cycle: the rest in priority order
        if not done[i] then
          pick = i
          host.note(stem, point .. ": after / before cycle around " .. live[i].id .. ": rest in priority order")
          break
        end
      end
      in_degree[pick] = 0
    end
    done[pick] = true
    out[#out + 1] = live[pick]
    for j in pairs(runs_before[pick]) do
      in_degree[j] = in_degree[j] - 1
    end
  end
  return out
end

-- The values of a host's named list in order (item.value, or the item spec when it has none).
function host.items(stem, list)
  local out = {}
  for _, entry in ipairs(host.order(stem, list, "item")) do
    out[#out + 1] = entry.value ~= nil and entry.value or entry
  end
  return out
end

-- ---- dispatch -------------------------------------------------------------------------------------------------------
local function failed(stem, entry, err)
  host.note(stem, entry.id .. " (" .. entry.point .. ", " .. entry.phase .. ") failed: " .. tostring(err))
end

-- what is under the dispatcher of a point the host hooked AGAIN (install: «replaced after the host hooked it»): the
-- new function may be a wrapper over the dispatcher that calls it through something the host could not see (a table
-- field: `S.origInit = OnInit; OnInit = function(...) ... return S.origInit(...) end`). The call into it is counted
-- per coroutine; the dispatcher entered again from inside it goes on with what was under the FIRST hook (p.base),
-- never through the handlers and the new function again (that loop was the team dock's Lua stack overflow).
-- Errors keep going up (rethrown).
local function call_under_rehooked(point_record, callee, ...)
  local running_coroutine = coroutine.running()
  local inside = point_record.inside
  inside[running_coroutine] = (inside[running_coroutine] or 0) + 1
  local results = pack(pcall(callee, ...))
  local depth = inside[running_coroutine] - 1
  inside[running_coroutine] = depth > 0 and depth or nil
  if not results[1] then
    error(results[2], 0)
  end
  return unpack(results, 2, results.n)
end

local function build(menu_host, point_record)
  local cache = { gen = host.gen, before = host.order(menu_host.stem, point_record.name, "before"), after = host.order(menu_host.stem, point_record.name, "after") }
  local next_handler = function(...)
    local previous = point_record.prev
    if previous ~= nil then
      if point_record.inside ~= nil then
        return call_under_rehooked(point_record, previous, ...)
      end
      return previous(...)
    end
  end
  local around = host.order(menu_host.stem, point_record.name, "around")
  for i = #around, 1, -1 do
    local around_function, inner = around[i].fn, next_handler
    next_handler = function(...)
      return around_function(inner, ...)
    end
  end
  cache.entry = next_handler
  point_record.cache = cache
  return cache
end

-- at the first dispatch of any point of a host (and again only if handlers were registered since): the @edit handlers
-- not run yet, in order; then, once per VM, each named list's apply with its items
local function edit(menu_host)
  menu_host.egen = host.gen
  host.flush()
  for _, entry in ipairs(host.order(menu_host.stem, "@edit", "edit")) do
    if not menu_host.done[entry] then
      menu_host.done[entry] = true
      local ok, err = pcall(entry.fn, menu_host.L, menu_host)
      if not ok then
        failed(menu_host.stem, entry, err)
      end
    end
  end
  if not menu_host.listed then
    menu_host.listed = true
    for name, list_spec in pairs(menu_host.lists) do
      if type(list_spec.apply) == "function" then
        local items = {}
        for _, entry in ipairs(host.order(menu_host.stem, name, "item")) do
          items[#items + 1] = { id = entry.id, mod = entry.mod, value = entry.value }
        end
        local ok, err = pcall(list_spec.apply, items, menu_host.L, menu_host)
        if not ok then
          host.note(menu_host.stem, "list " .. name .. ": apply failed: " .. tostring(err))
        end
      end
    end
  end
  -- handlers on points this host does not hook never run: say so once
  for point, list in pairs(host.reg[menu_host.stem] or {}) do
    local first = list[1]
    if first ~= nil and point ~= "@edit" then
      local point_record = menu_host.points[point]
      if point_record == nil and menu_host.lists[point] == nil and CALLS[first.phase] then
        host.note(menu_host.stem, point .. " was never hooked: " .. first.id .. " never runs")
      elseif point_record ~= nil and point_record.dispatch == nil then
        host.note(menu_host.stem, point .. " is not defined in this script: " .. first.id .. " never runs")
      end
    end
  end
end

local function make_dispatch(menu_host, point_record)
  return function(...)
    if point_record.inside ~= nil and point_record.inside[coroutine.running()] ~= nil then
      if not point_record.looped then
        point_record.looped = true
        host.note(menu_host.stem, point_record.name .. ": the function the host hooked again calls the host's dispatcher (a wrapper over it): "
          .. "that call goes on with what was under the first hook, once (no loop)")
      end
      local base = point_record.base
      if base ~= nil and base ~= point_record.prev then
        return base(...)
      end
      return
    end
    if menu_host.egen ~= host.gen then
      edit(menu_host)
    end
    local cache = point_record.cache
    if cache == nil or cache.gen ~= host.gen then
      cache = build(menu_host, point_record)
    end
    local before, after = cache.before, cache.after
    if before[1] == nil and after[1] == nil then
      return cache.entry(...)
    end
    for i = 1, #before do
      local entry = before[i]
      local results = pack(pcall(entry.fn, ...))
      if not results[1] then
        failed(menu_host.stem, entry, results[2])
      elseif results[2] == host.HALT then
        return unpack(results, 3, results.n)
      end
    end
    if after[1] == nil then
      return cache.entry(...)
    end
    local results = pack(cache.entry(...))
    for i = 1, #after do
      local entry = after[i]
      local ok, err = pcall(entry.fn, results, ...)
      if not ok then
        failed(menu_host.stem, entry, err)
      end
    end
    return unpack(results, 1, results.n)
  end
end

-- `target` is reached from f through upvalues (f is a wrapper some later patch put over the dispatcher), or through a
-- field of a table upvalue (a wrapper that keeps what it wraps in its own table: `S.origInit = OnInit`; the globals
-- table itself is not searched)
local function wraps(searched, target, depth, seen)
  local debug_library = DEBUG_LIBRARY or EVT_DEBUG
  if debug_library == nil or depth > 4 or seen[searched] then
    return false
  end
  if type(searched) == "table" then
    if rawequal(searched, _ENV) or rawequal(searched, _G) then
      return false
    end
    seen[searched] = true
    for _, upvalue_value in next, searched do
      if rawequal(upvalue_value, target) then
        return true
      end
    end
    return false
  end
  if type(searched) ~= "function" then
    return false
  end
  seen[searched] = true
  local i = 1
  while true do
    local upvalue_name, upvalue_value = debug_library.getupvalue(searched, i)
    if upvalue_name == nil then
      return false
    end
    if rawequal(upvalue_value, target) or ((type(upvalue_value) == "function" or type(upvalue_value) == "table") and wraps(upvalue_value, target, depth + 1, seen)) then
      return true
    end
    i = i + 1
  end
end

-- The per-frame entry points: a screen script defines Step, PostStep or both. A handler registered on one the script
-- does not define goes on the other (the screen's per-frame function either way), so a mod hooks "Step" or "PostStep"
-- without knowing which one the retail script has. When the script defines both, or the handler asks for the point to be
-- created (create = true), each point keeps its own function.
local FRAME_ENTRY = { Step = "PostStep", PostStep = "Step" }

-- The global a point hooks: its own name, or the other per-frame entry when only that one is defined here.
local function global_of(menu_host, point_record)
  if point_record.global ~= nil then
    return point_record.global
  end
  local other = FRAME_ENTRY[point_record.name]
  if other ~= nil and not point_record.create and type(_ENV[point_record.name]) ~= "function" and type(_ENV[other]) == "function" then
    point_record.global = other
    host.note(menu_host.stem, point_record.name .. " is not defined in this script: its handlers run from " .. other .. " (the per-frame entry)")
    return other
  end
  return point_record.name
end

local function install(menu_host, point_record)
  local name = global_of(menu_host, point_record)
  local cur = _ENV[name]
  if point_record.dispatch ~= nil and (cur == point_record.dispatch or (DEBUG_LIBRARY or EVT_DEBUG) == nil or wraps(cur, point_record.dispatch, 0, {})) then
    return                      -- already hooked, or a later patch wraps the dispatcher (keep the chain; without
  end                           -- EVT_DEBUG a wrapper cannot be told from a replacement: never hooked twice)
  if type(cur) ~= "function" then
    if not point_record.create then
      return                    -- not in this script: nothing to hook
    end
    cur = nil
  end
  if point_record.dispatch ~= nil then
    host.note(menu_host.stem, point_record.name .. " was replaced after the host hooked it: hooked again over the new function")
    -- the new function may still call the dispatcher (a wrapper the search above could not see): the dispatcher
    -- entered again from inside it goes on with what was under the first hook (call_under_rehooked)
    if point_record.inside == nil then
      point_record.base = point_record.prev
      point_record.inside = {}
    end
  end
  point_record.prev = cur
  point_record.dispatch = point_record.dispatch or make_dispatch(menu_host, point_record)
  _ENV[name] = point_record.dispatch
end

-- ---- locals of the retail chunk (H.L) -------------------------------------------------------------------------------
-- the closure holding the locals: the retail function, or the one under a wrapper an INCLUDE put on it at chunk time
-- (title_menu_inc wraps OnInit): the first function with exactly `nup` upvalues, searched through upvalues
local function holder(searched, wanted_upvalues, debug_library, depth, seen)
  if type(searched) ~= "function" or depth > 3 or seen[searched] then
    return nil
  end
  seen[searched] = true
  local upvalue_count = 0
  while debug_library.getupvalue(searched, upvalue_count + 1) ~= nil do
    upvalue_count = upvalue_count + 1
  end
  if upvalue_count == wanted_upvalues then
    return searched
  end
  for i = 1, upvalue_count do
    local _, upvalue_value = debug_library.getupvalue(searched, i)
    local found = holder(upvalue_value, wanted_upvalues, debug_library, depth + 1, seen)
    if found ~= nil then
      return found
    end
  end
  return nil
end

-- A merge-path patch that PROMOTED the retail locals (declared them again and redefined every function using them:
-- e.g. a passive dispatch or a dock patch on team_dock_formation_menu) runs on its OWN copy;
-- the retail closures' upvalues then never change. Such a patch is compiled from text, so its closures keep their
-- upvalue names (stripped retail bytecode has none): the closure live now for the map's function that captures every
-- local the map gives that function (`names`) holds the live copy. Searched from the global (and from what is under
-- the host's dispatcher) through wrapper upvalues; -> closure, upvalue index of `k`.
local function promoted(searched, local_name, names, debug_library, depth, seen)
  if type(searched) ~= "function" or depth > 4 or seen[searched] then
    return nil
  end
  seen[searched] = true
  local have, match_index, i = {}, nil, 1
  while true do
    local upvalue_name, upvalue_value = debug_library.getupvalue(searched, i)
    if upvalue_name == nil then
      break
    end
    have[upvalue_name] = true
    if upvalue_name == local_name then
      match_index = i
    end
    i = i + 1
  end
  if match_index ~= nil then
    local all = true
    for _, wanted_name in ipairs(names) do
      if not have[wanted_name] then
        all = false
        break
      end
    end
    if all then
      return searched, match_index
    end
  end
  for j = 1, i - 1 do
    local _, upvalue_value = debug_library.getupvalue(searched, j)
    local found, found_index = promoted(upvalue_value, local_name, names, debug_library, depth + 1, seen)
    if found ~= nil then
      return found, found_index
    end
  end
  return nil
end

local function make_locals(menu_host)
  local found = {}       -- k -> { f, index, the two closures it was searched from } (searched again when they change)
  local names_of = nil   -- retail function name -> the map's locals it captures
  local function names(function_name)
    if names_of == nil then
      names_of = {}
      for name, local_spec in pairs(menu_host.map) do
        local locals_of_function = names_of[local_spec[1]] or {}
        locals_of_function[#locals_of_function + 1] = name
        names_of[local_spec[1]] = locals_of_function
      end
    end
    return names_of[function_name] or {}
  end
  local function locate(local_name)
    local map_entry = menu_host.map[local_name]
    local debug_library = DEBUG_LIBRARY or EVT_DEBUG
    if map_entry == nil or debug_library == nil then
      return nil
    end
    local point_record = menu_host.points[map_entry[1]]
    local top, under = rawget(_ENV, map_entry[1]), point_record ~= nil and point_record.dispatch ~= nil and point_record.prev or nil
    local cached = found[local_name]
    if cached == nil or cached.top ~= top or cached.under ~= under then
      local seen = {}
      local closure, upvalue_index = promoted(under, local_name, names(map_entry[1]), debug_library, 0, seen)
      if closure == nil then
        closure, upvalue_index = promoted(top, local_name, names(map_entry[1]), debug_library, 0, seen)
      end
      local how = "promoted"
      if closure == nil then
        closure, upvalue_index, how = holder(host.retail[map_entry[1]], map_entry[3], debug_library, 0, {}), map_entry[2], "retail"
      end
      if closure == nil then
        host.note(menu_host.stem, "local " .. tostring(local_name) .. ": " .. tostring(map_entry[1]) .. " with " .. tostring(map_entry[3]) .. " upvalues not found")
        return nil
      end
      if cached ~= nil and cached.how ~= how then
        host.note(menu_host.stem, "local " .. tostring(local_name) .. ": now the " .. how .. " copy (" .. tostring(map_entry[1]) .. " was redefined)")
      end
      cached = { closure = closure, upvalue_index = upvalue_index, top = top, under = under, how = how }
      found[local_name] = cached
      if how == "promoted" then
        host.note(menu_host.stem, "local " .. tostring(local_name) .. ": served from a patch's promoted copy (" .. tostring(map_entry[1]) .. "), not the retail one")
      end
    end
    return cached.closure, cached.upvalue_index, map_entry[4], debug_library
  end
  return setmetatable({}, {
    __index = function(_, local_name)
      local closure, upvalue_index, expected_type, debug_library = locate(local_name)
      if closure == nil then
        return nil
      end
      local _, value = debug_library.getupvalue(closure, upvalue_index)
      if expected_type ~= nil and value ~= nil and type(value) ~= expected_type then
        host.note(menu_host.stem, "local " .. tostring(local_name) .. " is a " .. type(value) .. ", not a " .. expected_type .. ": not served")
        return nil
      end
      return value
    end,
    __newindex = function(_, local_name, value)
      local closure, upvalue_index, _, debug_library = locate(local_name)
      if closure == nil then
        error("VRFW_Host: " .. menu_host.stem .. ": no local " .. tostring(local_name) .. " (not in the host's map, or no EVT_DEBUG)", 2)
      end
      debug_library.setupvalue(closure, upvalue_index, value)
    end,
  })
end

-- ---- hosts ----------------------------------------------------------------------------------------------------------
local function host_of(stem)
  local menu_host = host.hosts[stem]
  if menu_host == nil then
    menu_host = { stem = stem, points = {}, lists = {}, map = {}, done = {}, listed = false, egen = -1, active = false }
    menu_host.L = make_locals(menu_host)
    host.hosts[stem] = menu_host
  end
  return menu_host
end

-- the script stem of the patch file running now: its folder (EVT_PATCH.file "mods/<id>/<folder>/<file>"), without the
-- version suffix (title_menu_2_7.01.12.00 -> title_menu_2)
local function stem_here()
  local patch_file = EVT_PATCH and EVT_PATCH.file
  local dir = type(patch_file) == "string" and patch_file:match("([^/]+)/[^/]+$") or nil
  if dir == nil then
    return nil
  end
  return (dir:gsub("_%d+%.%d+[%.%d]*$", ""))
end

-- (host, function name, create): replace the global by the point's dispatcher, once the host is active
hook_point = function(menu_host, name, create)
  if not menu_host.active then
    return
  end
  local point_record = menu_host.points[name]
  if point_record == nil then
    point_record = { name = name }
    menu_host.points[name] = point_record
  end
  point_record.create = point_record.create or create or false
  install(menu_host, point_record)
end

-- After the last patch file of the script (the loader calls it): every hook point of an active host whose global a
-- later root replaced (a merge-path patch that redefines the retail functions) is hooked again over the new function,
-- so the handlers of the mods that ran before that root still run. A point the script defined only later is hooked now.
function host.settle()
  host.settled = true
  for _, menu_host in pairs(host.hosts) do
    if menu_host.active then
      for _, point_record in pairs(menu_host.points) do
        install(menu_host, point_record)
      end
    end
  end
  -- H.wrap of a script without a host: the wrappers go on the globals now, in registration order
  local waiting = host.unhosted
  host.unhosted = {}
  table.sort(waiting, function(left, right) return left.seq < right.seq end)
  for _, waiting_wrap in ipairs(waiting) do
    local waiting_host = host.hosts[waiting_wrap.stem]
    if not (waiting_host ~= nil and waiting_host.active) then
      host.wrap_global(waiting_wrap)
    end
  end
end

-- ---- classic wrappers -----------------------------------------------------------------------------------------------
-- VRFW_Host.wrap(name, make [, spec]) -> true when `name` is a global function of this script. `make(orig)` returns
-- the wrapper of `orig`, as with `_ENV[name] = make(_ENV[name])`; the rules decide where it goes:
--   * the script's host has not run yet (a lua_early root): an around handler, inner to every other handler (the
--     wrapper of a patch that ran before the host is part of the original), so a later patch that redefines the
--     function does not drop it (H.settle hooks the point again);
--   * the host already ran (a later root, or a call from a callback): a wrapper of the global, over the dispatcher;
--   * a script without a host: a wrapper of the global after the last patch file (H.settle).
-- One wrapper per call site: the same call running again (the script loaded twice, a second install pass) replaces
-- its handler, or wraps the global again only when that was redefined since. spec = { level = stack level of the call
-- site above the caller (default 1: the caller; 2 for a mod's own wrap helper), stem = script stem (default: the
-- patch file's folder), id = handler id (default: derived from the call site) }.
host.unhosted = host.unhosted or {}
host.wrapped = host.wrapped or {}     -- handler id -> the global wrapper it made (wrapper of the global only)
local wrap_seq = 0

local function wrap_site(level)
  local debug_library = DEBUG_LIBRARY or EVT_DEBUG
  local info = debug_library ~= nil and type(debug_library.getinfo) == "function" and debug_library.getinfo(level + 1, "Sl") or nil
  if info == nil or type(info.source) ~= "string" then
    return nil, nil
  end
  local source = info.source:gsub("^[=@]", ""):gsub("^patch:", "")
  return source, source .. ":" .. tostring(info.currentline)
end

-- the global a classic wrapper goes on: its name, or the other per-frame entry when only that one is defined
local function wrap_target(name)
  local other = FRAME_ENTRY[name]
  if type(_ENV[name]) ~= "function" and other ~= nil and type(_ENV[other]) == "function" then
    return other
  end
  return name
end

function host.wrap_global(wrap_spec)
  local target = wrap_target(wrap_spec.name)
  local cur = _ENV[target]
  if type(cur) ~= "function" then
    host.note(wrap_spec.stem, wrap_spec.name .. " is not defined in this script: " .. wrap_spec.id .. " never runs")
    return false
  end
  if host.wrapped[wrap_spec.id] == cur then
    return true
  end
  local wrapper = wrap_spec.make(cur)
  host.wrapped[wrap_spec.id] = wrapper
  _ENV[target] = wrapper
  return true
end

function host.wrap(name, make, spec)
  if type(name) ~= "string" or type(make) ~= "function" then
    error("VRFW_Host.wrap(name, make [, spec]): a string and a function expected", 2)
  end
  spec = spec or {}
  if type(_ENV[wrap_target(name)]) ~= "function" then
    return false
  end
  local source, site = wrap_site((tonumber(spec.level) or 1) + 1)
  local stem = spec.stem
  if stem == nil then
    local dir = type(source) == "string" and source:match("([^/]+)/[^/]+$") or nil
    stem = dir ~= nil and (dir:gsub("_%d+%.%d+[%.%d]*$", "")) or stem_here()
  end
  local mod = type(source) == "string" and source:match("^mods/([^/]+)/") or caller_mod() or "patch"
  local id = spec.id
  if id == nil then
    if site == nil then
      wrap_seq = wrap_seq + 1
      site = "call" .. wrap_seq
    end
    id = mod .. ".wrap_" .. site:gsub("[^%w]", "_") .. "_" .. name
  end
  local wrap_spec = { name = name, make = make, stem = stem, id = id }
  local list = stem ~= nil and host.reg[stem] and host.reg[stem][name] or nil
  local seq = nil
  for _, entry in ipairs(list or {}) do
    if entry.id == id and entry.phase == "around" then
      seq = entry.seq
    end
  end
  local menu_host = stem ~= nil and host.hosts[stem] or nil
  if seq ~= nil and menu_host ~= nil and menu_host.active then
    return true                 -- this call site's handler is in place: the dispatcher runs it over any redefinition
  end
  if stem == nil or (DEBUG_LIBRARY or EVT_DEBUG) == nil or (menu_host ~= nil and menu_host.active) or (host.settled and menu_host == nil) then
    return host.wrap_global(wrap_spec)
  end
  seq = seq or (host.seq + 1)
  local under, wrapper = nil, nil
  host.on(stem, name, { id = id, phase = "around", priority = 1000000 - seq, fn = function(next_handler, ...)
    if next_handler ~= under then
      under, wrapper = next_handler, make(next_handler)
    end
    return wrapper(...)
  end })
  if menu_host == nil then
    wrap_spec.seq = seq
    host.unhosted[#host.unhosted + 1] = wrap_spec
  end
  return true
end

-- A named list of a host (H.add items), declared by the mod that consumes it:
-- def = { apply = function(items, L, host) end }, items = { {id, mod, value}, ... } in order; apply runs once per VM
-- at the host's first callback.
function host.list(stem, name, def)
  host_of(stem).lists[name] = def or {}
end

-- Make a script a host: the patch file that calls it (the host patch; `stem` defaults to its folder) is the place in
-- the patch chain where the dispatchers go. Its hook points are not a fixed list: every global function some mod
-- registered a before / around / after handler for (VRFW_Host.on), and every one registered later (hooked at that
-- registration). spec = {
--   locals = { name = { "GlobalFn", upvalue index, upvalue count, "table" | ... } },   -- menu_assemble.py locals <file>
--   functions = { ... },   -- optional: points hooked even with no handler yet (rarely needed)
-- }. Idempotent; several files may extend one host.
function host.host(stem, spec)
  if type(stem) == "table" and spec == nil then
    stem, spec = nil, stem
  end
  stem = stem or stem_here()
  if type(stem) ~= "string" then
    error("VRFW_Host.host: no stem (call it from a patch file of the script's folder, or pass the stem)", 2)
  end
  spec = spec or {}
  local menu_host = host_of(stem)
  for k, v in pairs(spec.locals or {}) do
    menu_host.map[k] = v
  end
  for k, v in pairs(spec.lists or {}) do
    menu_host.lists[k] = v
  end
  menu_host.active = true
  local want = {}
  for point, list in pairs(host.reg[stem] or {}) do
    for _, entry in ipairs(list) do
      if CALLS[entry.phase] then
        want[point] = want[point] or entry.create
      end
    end
  end
  for _, name in ipairs(spec.functions or {}) do
    if want[name] == nil then
      want[name] = false
    end
  end
  for name, create in pairs(want) do
    hook_point(menu_host, name, create)
  end
  return menu_host
end

-- The retail closure of a global (as the chunk defined it, before any patch).
function host.retail_fn(name)
  return host.retail[name]
end

-- A function that calls what is UNDER the host's dispatcher of stem:name (retail, or what the patches that ran before
-- the host made of it), skipping every handler of that point; resolved at call time, so it may be taken at load.
function host.original(stem, name)
  return function(...)
    local menu_host = host.hosts[stem]
    local point_record = menu_host and menu_host.points[name]
    local under
    if point_record ~= nil and point_record.dispatch ~= nil then
      under = point_record.prev
    else
      under = _ENV[name]
    end
    if under ~= nil then
      return under(...)
    end
  end
end

-- Human-readable order of a host (tests, debug logs): one line per point with handlers.
function host.report(stem)
  local lines = {}
  local menu_host = host.hosts[stem]
  local points = {}
  for point in pairs(host.reg[stem] or {}) do
    points[#points + 1] = point
  end
  table.sort(points)
  for _, point in ipairs(points) do
    local parts = {}
    for _, phase in ipairs({ "before", "around", "after", "edit", "item" }) do
      local ids = {}
      for _, entry in ipairs(host.order(stem, point, phase)) do
        ids[#ids + 1] = entry.id
      end
      if #ids > 0 then
        parts[#parts + 1] = phase .. " " .. table.concat(ids, ", ")
      end
    end
    local hooked = menu_host and (menu_host.points[point] ~= nil and (menu_host.points[point].dispatch ~= nil and "hooked" or "not defined")
      or (menu_host.lists[point] ~= nil and "list") or (point == "@edit" and "edit")) or "no host"
    lines[#lines + 1] = stem .. ":" .. point .. " [" .. hooked .. "] " .. table.concat(parts, "; ")
  end
  return table.concat(lines, "\n")
end

-- registrations queued by patches that ran before this file (VRFW_HOST_Q, or the 1.x EVT_HOST_Q)
for _, qname in ipairs({ "VRFW_HOST_Q", "EVT_HOST_Q" }) do
  local queue = rawget(_ENV, qname)
  if type(queue) == "table" then
    for _, queued in ipairs(queue) do
      if queued[1] == "on" then
        host.on(queued[2], queued[3], queued[4])
      elseif queued[1] == "add" then
        host.add(queued[2], queued[3], queued[4])
      end
    end
    rawset(_ENV, qname, nil)
  end
end
