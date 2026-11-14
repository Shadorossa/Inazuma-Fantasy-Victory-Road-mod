-- Internal:
-- lua_patch.scope: used
-- Team loadouts: each team keeps what its players carry; the team made active gets its own values back (docs/framework/team-loadout.md).
if VRFW.team_loadout == nil then
  local TL = { fields = {}, source = nil }
  --- Advanced: State of the team loadout fields and their source.
  VRFW.team_loadout = TL

  local C = {
    STATE = VRFW.commands.VRFW_TEAM_LOADOUT_STATE,
    MEMBERS = VRFW.commands.VRFW_TEAM_LOADOUT_MEMBERS,
    ACTIVATE = VRFW.commands.VRFW_TEAM_LOADOUT_ACTIVATE,
    GET = VRFW.commands.VRFW_TEAM_LOADOUT_GET,
    PUT = VRFW.commands.VRFW_TEAM_LOADOUT_PUT,
    DROP = VRFW.commands.VRFW_TEAM_LOADOUT_DROP,
    VS_TEAM = VRFW.commands.GET_VS_USE_TEAM_SET,
  }
  local OWN_SIDE = 0 -- the side a team switch writes: the player's own team

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("VRFW.team_loadout")
    logger(...)
  end
  --- Advanced: Log function of the team loadout.
  TL.log = log

  local function call(id, ...)
    return VRFW.host.command(id, ...)
  end

  local function hex(handle)
    return string.format("%08X", VRFW.ids.unsigned_or(handle, 0))
  end

  local function handle_of(word)
    return tonumber(word, 16)
  end

  local function split(text)
    local out = {}
    for w in tostring(text or ""):gmatch("[^,]+") do
      out[#out + 1] = w
    end
    return out
  end

  --- Internal: Registers a mod's per-player field `key` = "<Mod>.<name>": spec.collect(member, team) gives the value (one line
  --- of text or a number, nil = none), spec.apply(side, member, value, team) writes it, spec.default(member, team)
  --- (optional) writes what a player gets in a team that has no value of him yet. Same shape as VRFW.net_team.field.
  function TL.field(key, spec)
    if type(key) ~= "string" or not key:find(".", 1, true) or type(spec) ~= "table" then
      return false, "a field needs a key <Mod>.<name> and a spec table"
    end
    if type(spec.collect) ~= "function" or type(spec.apply) ~= "function" then
      return false, "a field needs collect and apply functions"
    end
    if spec.default ~= nil and type(spec.default) ~= "function" then
      return false, "a field's default must be a function"
    end
    TL.fields[key] = { collect = spec.collect, apply = spec.apply, default = spec.default }
    return true
  end

  --- Advanced: Sets the source of the teams: spec.key(team set) -> the team's stable key (nil = no team), spec.teams() -> every
  --- team of the save as { { key, handles = { charaStHdl } } }, spec.migrate() (optional) puts the source's own older
  --- per-team records in (TL.keep) before a switch. Without a source a team is its team set.
  function TL.set_source(spec)
    if type(spec) ~= "table" or type(spec.key) ~= "function" then
      return false, "a source needs a key function"
    end
    if spec.teams ~= nil and type(spec.teams) ~= "function" then
      return false, "a source's teams must be a function"
    end
    if spec.migrate ~= nil and type(spec.migrate) ~= "function" then
      return false, "a source's migrate must be a function"
    end
    --- Internal: loadout source spec given to the module.
    TL.source = spec
    return true
  end

  local function field_keys()
    local keys = {}
    for k in pairs(TL.fields) do
      keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
  end

  --- Advanced: The stable key of the team in team set `set`; nil when that set holds no team.
  function TL.team_key(set)
    if type(set) ~= "number" or set < 0 then
      return nil
    end
    if TL.source ~= nil then
      local ok, key = pcall(TL.source.key, set)
      if not ok then
        log("team source failed for team set", set, tostring(key))
        return nil
      end
      return type(key) == "string" and key ~= "" and key or nil
    end
    return "team_set" .. tostring(set)
  end

  --- Advanced: The member handles of team `team` (the playing team when nil) of team set `set`; nil when unreadable.
  function TL.members(set, team)
    local text = call(C.MEMBERS, set, team)
    if type(text) ~= "string" then
      return nil
    end
    local out = {}
    for _, w in ipairs(split(text)) do
      out[#out + 1] = handle_of(w)
    end
    return out
  end

  --- Advanced: The team set of the active team; nil when the game does not answer.
  function TL.active_set()
    local set = call(C.VS_TEAM)
    return (type(set) == "number" and set >= 0) and set or nil
  end

  --- Internal: Every registered field's value of player `handle` as one record text ("<key>=<value>" lines); nil when none.
  function TL.collect(handle, team)
    local member, lines = { handle = handle }, {}
    for _, key in ipairs(field_keys()) do
      local ok, v = pcall(TL.fields[key].collect, member, team)
      if not ok then
        log("field", key, "collect failed for", hex(handle), tostring(v))
      elseif v ~= nil then
        local text = tostring(v)
        if text:find("\n", 1, true) then
          log("field", key, "value of", hex(handle), "has a line break: left out")
        else
          lines[#lines + 1] = key .. "=" .. text
        end
      end
    end
    return #lines > 0 and table.concat(lines, "\n") or nil
  end

  local function parse(record)
    local values = {}
    for line in tostring(record or ""):gmatch("[^\n]+") do
      local key, value = line:match("^([^=]+)=(.*)$")
      if key ~= nil then
        values[key] = value
      end
    end
    return values
  end

  --- Internal: Writes record `record` on player `handle` for `side` (0 = the player's team); a field the record lacks takes
  --- its default when `fill` is true.
  function TL.apply(side, handle, record, team, fill)
    local member, values = { handle = handle }, parse(record)
    for _, key in ipairs(field_keys()) do
      local f, v = TL.fields[key], values[key]
      local ok, e = true, nil
      if v ~= nil then
        ok, e = pcall(f.apply, side, member, v, team)
      elseif fill and f.default ~= nil then
        ok, e = pcall(f.default, member, team)
      end
      if not ok then
        log("field", key, "write failed for", hex(handle), tostring(e))
      end
    end
  end

  local function store(keys, handle, team)
    local record = TL.collect(handle, team)
    if record == nil then
      return 0
    end
    local n = call(C.PUT, table.concat(keys, ","), handle, record)
    return type(n) == "number" and n or 0
  end

  local function state()
    local usable, seeded, key, set, members = call(C.STATE)
    if usable ~= true then
      return nil
    end
    local list = {}
    for _, w in ipairs(split(members)) do
      list[#list + 1] = handle_of(w)
    end
    return { seeded = seeded == true, key = key ~= "" and key or nil, set = set, members = list }
  end

  local function contains(list, handle)
    for _, h in ipairs(list or {}) do
      if h == handle then
        return true
      end
    end
    return false
  end

  -- Every team of the save with its members: the source's list, else the active team only.
  local function all_teams(key, set)
    if TL.source ~= nil and TL.source.teams ~= nil then
      local ok, list = pcall(TL.source.teams)
      if ok and type(list) == "table" then
        return list
      end
      log("team source: the team list failed:", tostring(list))
    end
    return { { key = key, handles = TL.members(set) or {} } }
  end

  local function hex_list(list)
    local out = {}
    for _, h in ipairs(list) do
      out[#out + 1] = hex(h)
    end
    return table.concat(out, ",")
  end

  -- The first run on a save: every player's current values become his record in every team he is in.
  local function seed(key, set, members)
    local teams_of, order = {}, {}
    for _, t in ipairs(all_teams(key, set)) do
      for _, h in ipairs(t.handles or {}) do
        if teams_of[h] == nil then
          teams_of[h] = {}
          order[#order + 1] = h
        end
        table.insert(teams_of[h], t.key)
      end
    end
    local records = 0
    for _, h in ipairs(order) do
      records = records + store(teams_of[h], h, { key = teams_of[h][1] })
    end
    call(C.ACTIVATE, key, set, hex_list(members), true)
    log("first run: the current values of", #order, "player(s) kept as", records, "team record(s); active team", key)
  end

  -- A player who enters the active team: his record of that team, else the defaults of a first time in it.
  local function enter(handle, team)
    local record = call(C.GET, team.key, handle)
    if type(record) == "string" and record ~= "" then
      TL.apply(OWN_SIDE, handle, record, team, true)
      return "record"
    end
    TL.apply(OWN_SIDE, handle, nil, team, true)
    return "default"
  end

  --- Advanced: Makes the active team's players carry that team's values: the players of the team left keep theirs in it first.
  --- `why` names the trigger in the log. Off online and on a slot a mode reserved.
  function TL.sync(why)
    if type(VRFW.team_dock) == "table" and VRFW.team_dock.online() then
      return false
    end
    local set = TL.active_set()
    local key = TL.team_key(set)
    local st = key ~= nil and state() or nil
    if st == nil then
      return false
    end
    local now = TL.members(set)
    if now == nil then
      return false
    end
    if not st.seeded then
      seed(key, set, now)
    end
    if TL.source ~= nil and TL.source.migrate ~= nil then
      local ok, e = pcall(TL.source.migrate)
      if not ok then
        log("team source: the migration failed:", tostring(e))
      end
    end
    if not st.seeded then
      return true
    end
    local team = { key = key, set = set }
    local kept, entered, defaults = 0, 0, 0
    if st.key ~= key then
      if st.key ~= nil then
        local left = (TL.team_key(st.set) == st.key and TL.members(st.set)) or st.members
        for _, h in ipairs(left) do
          kept = kept + (store({ st.key }, h, { key = st.key, set = st.set }) > 0 and 1 or 0)
        end
      end
      for _, h in ipairs(now) do
        entered = entered + 1
        if enter(h, team) == "default" then
          defaults = defaults + 1
        end
      end
    else
      for _, h in ipairs(now) do
        if not contains(st.members, h) then
          entered = entered + 1
          if enter(h, team) == "default" then
            defaults = defaults + 1
          end
        end
      end
    end
    local list = hex_list(now)
    if st.key ~= key or st.set ~= set or list ~= hex_list(st.members) then
      call(C.ACTIVATE, key, set, list, false)
    end
    if kept > 0 or entered > 0 then
      log(tostring(why) .. ":", "team", tostring(st.key), "->", key, "kept", kept, "written", entered, "defaults", defaults)
    end
    return true
  end

  --- Advanced: A player edited while shown in team set `set`: a player outside the active team keeps the edit in that team.
  function TL.edited(handle, set)
    if type(handle) ~= "number" or handle == 0 then
      return false
    end
    if type(VRFW.team_dock) == "table" and VRFW.team_dock.online() then
      return false
    end
    local st, key = state(), TL.team_key(set)
    if st == nil or key == nil or not st.seeded or key == st.key or contains(st.members, handle) then
      return false
    end
    return store({ key }, handle, { key = key, set = set }) > 0
  end

  --- Advanced: True when player `handle` plays in the active team (a seeded save, not online).
  function TL.is_active_member(handle)
    if type(VRFW.team_dock) == "table" and VRFW.team_dock.online() then
      return false
    end
    local st = state()
    local members = st ~= nil and st.seeded and TL.members(TL.active_set()) or nil
    return members ~= nil and contains(members, handle)
  end

  --- Advanced: True when player `handle` has a record of his own in the team of team set `set` (the active team when nil).
  function TL.has_record(handle, set)
    local key = TL.team_key(set or TL.active_set())
    if key == nil or state() == nil then
      return false
    end
    local record = call(C.GET, key, handle)
    return type(record) == "string" and record ~= ""
  end

  --- Advanced: Copies the current values of player `handle` to every other team he is in; answers how many teams got them.
  function TL.copy_to_all(handle)
    local set = TL.active_set()
    local key = TL.team_key(set)
    if key == nil or state() == nil then
      return 0
    end
    local keys = {}
    for _, t in ipairs(all_teams(key, set)) do
      if t.key ~= key and contains(t.handles, handle) then
        keys[#keys + 1] = t.key
      end
    end
    if #keys == 0 then
      return 0
    end
    local n = store(keys, handle, { key = key, set = set })
    log("copy of", hex(handle), "from", key, "to", n, "team(s)")
    return n
  end

  --- Advanced: Puts player `handle` back on the defaults of a first time in the active team and drops his record there.
  function TL.reset(handle)
    local set = TL.active_set()
    local key = TL.team_key(set)
    if key == nil or state() == nil then
      return false
    end
    local team = { key = key, set = set }
    TL.apply(OWN_SIDE, handle, nil, team, true)
    call(C.DROP, key, handle)
    log("defaults written for", hex(handle), "in", key)
    return true
  end

  --- Advanced: Puts record text `record` ("<field key>=<value>" lines) under team `key` for player `handle`; with `replace`
  --- false a record he already has there stays.
  function TL.keep(key, handle, record, replace)
    if type(key) ~= "string" or type(record) ~= "string" or record == "" or state() == nil then
      return false
    end
    if not replace then
      local now = call(C.GET, key, handle)
      if type(now) == "string" and now ~= "" then
        return false
      end
    end
    local n = call(C.PUT, key, handle, record)
    return type(n) == "number" and n > 0
  end

  --- Advanced: The records of the players of team set `set`, { [charaStHdl] = record }: the current values for the active team,
  --- the kept records for any other team.
  function TL.records_of(set)
    local out = {}
    local key, members = TL.team_key(set), TL.members(set)
    if key == nil or members == nil or state() == nil then
      return out
    end
    local live = TL.active_set() == set
    for _, h in ipairs(members) do
      local record = live and TL.collect(h, { key = key, set = set }) or call(C.GET, key, h)
      if type(record) == "string" and record ~= "" then
        out[h] = record
      end
    end
    return out
  end

  --- Advanced: `records` ({ [charaStHdl] = record }) as one text for a command: "<hex>\31<record>" joined by "\30".
  function TL.pack(records)
    local parts = {}
    for h, record in pairs(records) do
      parts[#parts + 1] = hex(h) .. "\31" .. record
    end
    table.sort(parts)
    return table.concat(parts, "\30")
  end

  --- Advanced: The records of a TL.pack text.
  function TL.unpack(text)
    local out = {}
    for entry in tostring(text or ""):gmatch("[^\30]+") do
      local h, record = entry:match("^(%x+)\31(.*)$")
      if h ~= nil and record ~= "" then
        out[handle_of(h)] = record
      end
    end
    return out
  end

  --- Internal: Drops every record of team `key` (a team that was replaced by a new one).
  function TL.forget(key)
    if type(key) ~= "string" then
      return 0
    end
    local n = call(C.DROP, key, 0)
    return type(n) == "number" and n or 0
  end

  -- Runs the registrations of the lua_early mods' `_all` files, which load before this file.
  local queue = rawget(VRFW, "team_loadout_queue")
  rawset(VRFW, "team_loadout_queue", nil)
  if type(queue) == "table" then
    for _, register in ipairs(queue) do
      local ok, err = pcall(register, TL)
      if not ok then
        log("queued registration failed:", tostring(err))
      end
    end
  end

  -- A bank page that is mounted, or given back, may hold another active team.
  local function wire(TD)
    TD.on("page_changed", "VRFW.team_loadout", function()
      TL.sync("team page")
    end)
    TD.on("saved_page_changed", "VRFW.team_loadout", function()
      TL.sync("lent team page")
    end)
  end
  if type(VRFW.team_dock) == "table" then
    wire(VRFW.team_dock)
  else
    VRFW.team_dock_queue = VRFW.team_dock_queue or {}
    table.insert(VRFW.team_dock_queue, wire)
  end
end
