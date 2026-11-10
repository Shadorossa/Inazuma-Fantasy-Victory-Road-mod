-- lua_patch.scope: used
if VRFW.match_difficulty == nil then
  local D = {
    COUNT = VRFW.commands.VRFW_TEAM_DIFFICULTY_COUNT,          -- CMND_VRFW_TEAM_DIFFICULTY_COUNT
    GET = VRFW.commands.VRFW_TEAM_DIFFICULTY_GET,            -- CMND_VRFW_TEAM_DIFFICULTY_GET
    CLASS = VRFW.commands.VRFW_FM_CLASS,                     -- CMND_VRFW_FM_CLASS
    sets = {},
    lists = {},
    orbs = {},
  }
  VRFW.match_difficulty = D

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("vrfw.MatchDifficulty")
    logger(...)
  end

  local function load(ctx)
    if D.sets[ctx] ~= nil then
      return
    end
    local ok, n = pcall(funcLuaCommand, D.COUNT, ctx)
    n = ok and tonumber(n) or -1
    if n < 0 then
      D.sets[ctx], D.lists[ctx] = false, {}
      return
    end
    local set, list = {}, {}
    for i = 0, n - 1 do
      local okG, d, id, level, atlas, sprite = pcall(funcLuaCommand, D.GET, ctx, i)
      d = okG and tonumber(d) or nil
      if d ~= nil then
        set[d] = true
        list[#list + 1] = {difficulty = d, id = id or "", level = tonumber(level) or -1, atlas = atlas or "", sprite = sprite or ""}
      end
    end
    D.sets[ctx], D.lists[ctx] = set, list
    log(ctx, n)
  end

  --- The difficulty set of context ctx; nil when none is declared.
  function D.set(ctx)
    load(ctx)
    return D.sets[ctx] or nil
  end

  --- Does difficulty d exist in context ctx (true when nothing is declared).
  function D.exists(ctx, d)
    local s = D.set(ctx)
    return s == nil or s[d] == true
  end

  --- The declared difficulties of context ctx, in order.
  function D.list(ctx)
    load(ctx)
    return D.lists[ctx]
  end

  --- The clear orb sprite crc32 of free-match class d on game `game` (its own Orb, else the class's), nil = none declared; read once.
  function D.class_orb(game, d)
    if type(game) ~= "number" or type(d) ~= "number" then
      return nil
    end
    local per_game = D.orbs[game]
    if per_game == nil then
      per_game = {}
      D.orbs[game] = per_game
    end
    local orb = per_game[d]
    if orb == nil then
      local r = {VRFW.host.command(D.CLASS, d, game)}
      orb = r[1] == true and type(r[7]) == "number" and r[7] ~= 0 and r[7] or false
      per_game[d] = orb
    end
    return orb or nil
  end
end
