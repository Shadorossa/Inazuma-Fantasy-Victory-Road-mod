-- lua_patch.scope: used
if VRFW.stats == nil then
  local ST = {
    SAVE_GET = VRFW.commands.VRFW_SAVE_GET,
    SAVE_SET = VRFW.commands.VRFW_SAVE_SET,
    LOG = VRFW.commands.VRFW_LOG,        -- CMND_VRFW_LOG
    OWNER = "VRFW",
    floors = {},
  }
  --- Internal: Namespace of the stats helpers for a team's match statistics.
  VRFW.stats = ST

  local function key(team)
    if type(team) ~= "number" or team == 0 then
      return nil
    end
    return "stats.wins." .. tostring(math.floor(team))
  end

  local function stored(k)
    local s = VRFW.host.command(ST.SAVE_GET, ST.OWNER, k, "")
    if s ~= nil then
      return tonumber(s)
    end
    return nil
  end

  --- Internal: Adds a function that answers a floor for the win counts.
  function ST.add_floor(fn)
    if type(fn) == "function" then
      ST.floors[#ST.floors + 1] = fn
    end
  end

  local function floor_of(team)
    local n = 0
    for _, fn in ipairs(ST.floors) do
      local ok, v = pcall(fn, team)
      if ok and type(v) == "number" and v > n then
        n = v
      end
    end
    return n
  end

  --- Internal: The wins against a team in this save slot (0 = never beaten, or not tracked yet).
  function ST.wins_against(team)
    local k = key(team)
    if k == nil then
      return 0
    end
    local n = stored(k) or 0
    local f = floor_of(team)
    return f > n and f or n
  end

  --- Internal: Adds one win against `team`; answers the new count, 0 when the team has no key.
  function ST.add_win(team)
    local k = key(team)
    if k == nil then
      return 0
    end
    local n = ST.wins_against(team) + 1
    pcall(funcLuaCommand, ST.SAVE_SET, ST.OWNER, k, tostring(n), 1)
    pcall(funcLuaCommand, ST.LOG, "stats", "win vs", k, n)
    return n
  end
end
