-- lua_patch.scope: used
-- menu_engine: TEAM BEATEN (VRFW base feature, docs/framework/team-beaten.md).
if VRFW.team_beaten == nil then
  local M = {
    GET = VRFW.commands.VRFW_TEAM_BEATEN,   -- CMND_VRFW_TEAM_BEATEN (team) -> rival, chain tiles, chain won, pieces, story wins
    cache = {},                             -- team -> {rival, beaten, chronicle, story}
  }
  --- Advanced: Namespace of the beaten-team records: which teams the player has beaten.
  VRFW.team_beaten = M

  -- "a:b:c,d:e:f" -> {{"a", "b", "c"}, {"d", "e", "f"}}
  local function fields(s)
    local out = {}
    for item in string.gmatch(type(s) == "string" and s or "", "[^,]+") do
      local f = {}
      for v in string.gmatch(item, "[^:]+") do
        f[#f + 1] = v
      end
      out[#out + 1] = f
    end
    return out
  end

  local function read(team)
    local rival, tiles, chain_won, pieces, story = VRFW.host.command(M.GET, team)
    if rival ~= true then
      return {rival = false}
    end
    local p, s = fields(pieces), fields(story)
    local c = {rival = true, chronicle = #p > 0 or (tonumber(tiles) or 0) > 0, story = #s > 0, beaten = chain_won == true}
    for _, x in ipairs(p) do
      if c.beaten then
        break
      end
      c.beaten = VRFW.chronicle.piece_cleared(tonumber(x[1]) or 0, tonumber(x[2]) or 0)
    end
    if not c.beaten and #s > 0 then
      local checks = {}
      for _, x in ipairs(s) do
        checks[#checks + 1] = {t = x[1], a = tonumber(x[2]) or 0, b = tonumber(x[3]) or 0}
      end
      c.beaten = VRFW.recruit.unlocked({checks}) == 1
    end
    return c
  end

  --- Advanced: Forgets the cached answers (a screen asks again when it opens).
  function M.reset()
    --- Internal: cache of the parsed beaten-team lists, cleared on refresh.
    M.cache = {}
    VRFW.recruit.refresh()
  end

  --- Advanced: Team `team` against the player: nil when no Chronicle or story match is against it; else beaten, then whether
  --- a Chronicle match (pieces, route nodes, chain tiles) and a story match are against it.
  function M.state(team)
    team = VRFW.ids.unsigned(tonumber(team) or 0)
    local c = M.cache[team]
    if c == nil then
      c = read(team)
      M.cache[team] = c
    end
    if not c.rival then
      return nil
    end
    return c.beaten, c.chronicle, c.story
  end
end
