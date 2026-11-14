-- lua_patch.scope: used
if VRFW.match_rank == nil then
  local R = {
    OWNER = "VRFW",
    SAVE_GET = VRFW.commands.VRFW_SAVE_GET,
    COUNT = VRFW.commands.VRFW_TEAM_MATCH_RANK_COUNT,           -- CMND_VRFW_TEAM_MATCH_RANK_COUNT
    GET = VRFW.commands.VRFW_TEAM_MATCH_RANK_GET,            -- CMND_VRFW_TEAM_MATCH_RANK_GET
    LEGACY = {[1] = "B", [2] = "A", [3] = "S"},
    list_cache = nil,
    by = nil,
  }
  --- Internal: Namespace: the match rank helpers of the menu VM.
  VRFW.match_rank = R

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("vrfw.MatchRank")
    logger(...)
  end

  --- Internal: The declared ranks, best first (read once per VM).
  function R.list()
    if R.list_cache ~= nil then
      return R.list_cache
    end
    R.list_cache, R.by = {}, {}
    local ok, n = pcall(funcLuaCommand, R.COUNT)
    n = ok and tonumber(n) or 0
    for i = 0, n - 1 do
      local okG, id, order, won, gf, mc, gd, badge, atlas, piece, text = pcall(funcLuaCommand, R.GET, i)
      if okG and type(id) == "string" and id ~= "" then
        local r = {id = id, order = tonumber(order) or 0, won = won ~= 0, gf = tonumber(gf) or -1, mc = tonumber(mc) or -1,
                   gd = tonumber(gd) or -999, badge = badge or "", atlas = atlas or "", piece = piece or "", text = text or ""}
        R.list_cache[#R.list_cache + 1] = r
        R.by[id] = r
      end
    end
    if #R.list_cache == 0 then
      log("no ranks declared (defaults\\match_rank.toml): wins are unranked")
    end
    return R.list_cache
  end

  --- Internal: The rank with Id `id`; nil when unknown.
  function R.by_id(id)
    R.list()
    return id ~= nil and R.by[id] or nil
  end

  --- Internal: The Order of a rank Id (0 = none / unknown).
  function R.order(id)
    local r = R.by_id(id)
    return r ~= nil and r.order or 0
  end

  --- Internal: The rank Id of an old numeric rank value; other values unchanged.
  function R.from_legacy(v)
    local n = tonumber(v)
    if n ~= nil then
      return R.LEGACY[n]
    end
    return v
  end

  --- Internal: The display label of a rank Id; "" for nil.
  function R.label(id)
    if id == nil then
      return ""
    end
    return string.match(id, "([^%.]+)$") or id
  end

  local function holds(r, f, a)
    local win = f > a
    if r.won and not win then
      return false
    end
    if r.gf >= 0 and f < r.gf then
      return false
    end
    if r.mc >= 0 and a > r.mc then
      return false
    end
    if r.gd > -999 and f - a < r.gd then
      return false
    end
    return true
  end

  --- Internal: The rank Id for a match score (goals for, against); nil when unknown.
  function R.of(f, a)
    f, a = tonumber(f) or -1, tonumber(a) or -1
    local list = R.list()
    if f < 0 or a < 0 then
      for i = #list, 1, -1 do
        local r = list[i]
        if r.gf < 0 and r.mc < 0 and r.gd <= -999 then
          return r.id
        end
      end
      return list[#list] and list[#list].id or nil
    end
    for _, r in ipairs(list) do
      if holds(r, f, a) then
        return r.id
      end
    end
    return nil
  end

  --- Internal: The last match's rank Id and score (id, for, against).
  function R.last()
    local okF, f = pcall(funcLuaCommand, R.SAVE_GET, R.OWNER, "mr_last_for", -1)
    local okA, a = pcall(funcLuaCommand, R.SAVE_GET, R.OWNER, "mr_last_against", -1)
    f = okF and tonumber(f) or -1
    a = okA and tonumber(a) or -1
    return R.of(f, a), f, a
  end

  --- Internal: The rank Id whose order matches the rounded average; nil when none does.
  function R.for_order(avg)
    local o = math.floor((tonumber(avg) or 0) + 0.5)
    for _, r in ipairs(R.list()) do
      if r.order <= o then
        return r.id
      end
    end
    return nil
  end
end
