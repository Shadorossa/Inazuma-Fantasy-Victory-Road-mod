-- lua_patch.scope: used
-- VRFW.match_challenge.of(game, diff)         -> challenge index (0-based) of a match game, nil = none.
if VRFW.match_challenge == nil then
  local MC = {
    CLEAR_FLAG = VRFW.commands.GET_SOCCER_GAME_CLEAR_FLAG,   -- CMND_GET_SOCCER_GAME_CLEAR_FLAG (game, difficulty) -> won
    CMD = {
      OF = VRFW.commands.VRFW_TEAM_CHALLENGE_OF,         -- CMND_VRFW_TEAM_CHALLENGE_OF (game) -> i / -1
      GET = VRFW.commands.VRFW_TEAM_CHALLENGE_GET,
                              -- difficulties ("4", "1,4"; "" = every row), required starters, short (0 = the title)
      REQ = VRFW.commands.VRFW_TEAM_CHALLENGE_REQ,
      CHECK = VRFW.commands.VRFW_TEAM_CHALLENGE_CHECK,
                              -- -> ok, failed, offenders
      REQUIRED = VRFW.commands.VRFW_TEAM_CHALLENGE_REQUIRED,
                              -- clear, own text id, label suffix text id
      AURAS = VRFW.commands.VRFW_TEAM_CHALLENGE_AURAS,
                              -- sides, label suffix text id
      MOVES = VRFW.commands.VRFW_TEAM_CHALLENGE_MOVES,
                              -- (i) -> ruled, banned categories ("shoot,keeper"), sides, label suffix text id
    },
    AURAS_ARM = VRFW.commands.VRFW_MATCH_AURAS_ARM,
    AURAS_DISARM = VRFW.commands.VRFW_MATCH_AURAS_DISARM, -- CMND_VRFW_MATCH_AURAS_DISARM (): the next match has none
    MOVES_ARM = VRFW.commands.VRFW_MATCH_MOVES_ARM, -- CMND_VRFW_MATCH_MOVES_ARM (banned categories, sides): the next match's move rule
    VS_SET = VRFW.commands.GET_VS_USE_TEAM_SET,      -- CMND_GET_VS_USE_TEAM_SET
    MEMBER = 1720957768,      -- (set, team, i, 0 hdl / 1 position)
    STATUS = 1131797651,      -- (hdl, 0 level / 4 chara_param / 12 rarity)
    IS_AVATAR = VRFW.commands.GET_IS_AVATAR_CHARA,
    HAS_ATTRIBUTE = 29506568,
    ATTRIBUTE_AVATAR = 4096,
    TEAM_SET_INFO = VRFW.commands.GET_TEAM_SET_INFO, -- CMND_GET_TEAM_SET_INFO (set, team, 4) -> ok, formation id
    FORMATION_INFO = VRFW.commands.GET_SOCCER_FORMATION_INFO,
    -- scPosType bit (16 GK, 32 DF, 64 MF, 128 FW) -> position code
    PLACE_BITS = {{16, 1}, {32, 4}, {64, 3}, {128, 2}},
    NAME = VRFW.commands.GET_CHARA_NAME_TEXT,        -- CMND_GET_CHARA_NAME_TEXT (hdl)
    SERIES = VRFW.commands.GET_CHARA_SERIES_INFO,
    TEXT_GET = VRFW.commands.TEXT_GET,    -- CMND_TEXT_GET
    MSG_OPEN = 2289627655,
    SE = VRFW.commands.SND_PLAY_SE, SE_NG = 2086672038 --[[sy0003]],
    -- the framework's menu_text rows (crc32 of the row id)
    T = {
      HEAD = 2317620035, REFUSED = 1303940226, EVERY = 3039376359, NONE = 1380443408, AT_LEAST = 2356225541,
      AT_MOST = 4270555599, BETWEEN = 1647389433, ANY_OF = 3050005278, ALL_OF = 2831980499, OFFENDERS = 2311040840,
      MORE = 2793740195, STARTERS = 1000104873, ANYONE = 296937077,
      GENDER = {[1] = 1426515113, [2] = 3423581459},
      ELEMENT = {[0] = 2593977113, [1] = 3986408335, [2] = 1955762741, [3] = 60138147, [4] = 2649831168},
      POSITION = {[1] = 1807914029, [2] = 4073440663, [3] = 2244801793, [4] = 464019618},
      F_ELEMENT = 3685919861, F_POSITION = 970726332, F_SERIES = 2001861548, F_TEAM = 3863514637, F_CHARA = 2064652193,
      F_LEVEL_MIN = 2369649544, F_LEVEL_MAX = 2972763345, F_LEVEL = 1769018739, F_RARITY_MIN = 266945921,
      F_RARITY_MAX = 870611672, F_RARITY = 4202775751, F_AVATAR = 1530300590, F_NOT = 2721797827, OR = 2007264933, AND = 3539978642,
      REQUIRED = 3122860320, REQUIRED_PLACES = 4094007390, WITH_REQUIRED = 206140731,
    },
    -- the dock's positions (team 0: 0-10 starters, 11-18 bench, 19 coach, 20-28 reserves; team 1: 0-4, 5-15)
    LAST = {[0] = {starters = 10, squad = 18}, [1] = {starters = 4, squad = 15}},
    MAX_NAMES = 4,
    SUPPLY_ROW = 1,           -- the difficulty row (retail: the fixed line-up row) a restricted chain match plays with a supplied squad
    info_cache = {},
  }
  VRFW.match_challenge = MC

  local function u32(v) return VRFW.ids.unsigned(v) end

  local logger
  --- Logs the arguments with the challenge tag.
  function MC.log(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    logger = logger or VRFW.logger.new("VRFW match_challenge")
    logger(table.concat(parts, " "))
  end

  local function text(id)
    if type(id) ~= "number" or id == 0 then
      return ""
    end
    local s = VRFW.host.command(MC.TEXT_GET, id)
    if type(s) == "string" then
      return s
    end
    return ""
  end

  local function fmt(id, ...)
    local ok, s = pcall(string.format, text(id), ...)
    if ok then
      return s
    end
    return text(id)
  end

  --- The challenge index of a match row; nil when it has none.
  function MC.of(game, diff)
    if type(game) ~= "number" or game == 0 then
      return nil
    end
    local i = VRFW.host.command(MC.CMD.OF, u32(game))
    if type(i) ~= "number" or i < 0 then
      return nil
    end
    local c = MC.details(i)
    if c ~= nil and next(c.diffs) ~= nil and not (type(diff) == "number" and c.diffs[diff]) then
      return nil
    end
    return i
  end

  --- Whether the match row was won: the game's clear bit of the row; beaten = the launcher's own record (a chain tile won with its supplied squad).
  function MC.won(game, diff, beaten)
    if beaten == true then
      return true
    end
    return type(game) == "number" and type(diff) == "number" and VRFW.host.command(MC.CLEAR_FLAG, game, diff) == true
  end

  --- The challenge in force on a match row, nil = none: one declared UntilFirstClear is off once the row was won.
  function MC.applies(game, diff, beaten)
    local i = MC.of(game, diff)
    local c = i ~= nil and MC.details(i) or nil
    if c ~= nil and c.until_first_clear and MC.won(game, diff, beaten) then
      return nil
    end
    return i
  end

  --- The challenge info table of index i (cached); nil when there is none.
  function MC.details(i)
    if MC.info_cache[i] ~= nil then
      return MC.info_cache[i] or nil
    end
    local name, mod, title, desc, scope, nreq, diffs, nrequired, short, until_first_clear = VRFW.host.command(MC.CMD.GET, i)
    if type(name) ~= "string" or name == "" then
      MC.info_cache[i] = false
      return nil
    end
    local set = {}
    for x in string.gmatch(type(diffs) == "string" and diffs or "", "%d+") do
      set[tonumber(x)] = true
    end
    local required = {}
    for k = 1, (type(nrequired) == "number" and nrequired or 0) do
      local count, places, until_first_clear, own, label = VRFW.host.command(MC.CMD.REQUIRED, i, k)
      local codes = {}
      for x in string.gmatch(type(places) == "string" and places or "", "%d+") do
        codes[#codes + 1] = tonumber(x)
      end
      required[k] = {count = count or 0, places = codes, until_first_clear = until_first_clear == true, text = own or 0,
                     label = type(label) == "number" and label or 0}
    end
    local auras = nil
    local ruled, allowed, sides, alabel = VRFW.host.command(MC.CMD.AURAS, i)
    if ruled == true then
      auras = {allowed = type(allowed) == "string" and allowed or "", sides = type(sides) == "string" and sides or "both",
               label = type(alabel) == "number" and alabel or 0}
    end
    local moves = nil
    local mruled, banned, msides, mlabel = VRFW.host.command(MC.CMD.MOVES, i)
    if mruled == true then
      moves = {banned = type(banned) == "string" and banned or "", sides = type(msides) == "string" and msides or "both",
               label = type(mlabel) == "number" and mlabel or 0}
    end
    local c = {i = i, name = name, mod = mod, title = title or 0, description = desc or 0,
               short = type(short) == "number" and short or 0, scope = scope or "squad", nreq = nreq or 0,
               diffs = set, required = required, auras = auras, moves = moves, until_first_clear = until_first_clear == true}
    MC.info_cache[i] = c
    return c
  end

  --- The title text of the challenge on a match row; nil when there is none.
  function MC.title_of(game, diff, beaten)
    local i = MC.applies(game, diff, beaten)
    local c = i and MC.details(i)
    if c == nil then
      return nil
    end
    local t = text(c.title)
    if t == "" then
      t = c.name
    end
    return t
  end

  --- The texts of the required starters of challenge i.
  function MC.required_texts(i, cleared)
    local c = MC.details(i)
    local out = {}
    for _, r in ipairs(c and c.required or {}) do
      if not (r.until_first_clear and cleared) and r.label == 0 and type(r.text) == "number" and r.text ~= 0 then
        out[#out + 1] = r.text
      end
    end
    return out
  end

  -- the position code of a scPosType bit set (0 = none of the four)
  local function place_of(bits)
    if type(bits) ~= "number" then
      return 0
    end
    for _, b in ipairs(MC.PLACE_BITS) do
      if math.floor(bits / b[1]) % 2 == 1 then
        return b[2]
      end
    end
    return 0
  end

  --- The players of `scope` ("starters" or the squad) for team type tt.
  function MC.players(scope, tt)
    tt = tt or 0
    local limits = MC.LAST[tt] or MC.LAST[0]
    local last = limits[scope == "starters" and "starters" or "squad"]
    local set = VRFW.host.command(MC.VS_SET)
    local out = {}
    if type(set) ~= "number" then
      return out
    end
    local okF, formation = VRFW.host.command(MC.TEAM_SET_INFO, set, tt, 4)
    if not okF then
      formation = nil
    end
    for k = 0, 28 do
      local ok, hdl = VRFW.host.command(MC.MEMBER, set, tt, k, 0)
      if ok and type(hdl) == "number" and hdl ~= 0 then
        local okP, pos = VRFW.host.command(MC.MEMBER, set, tt, k, 1)
        if okP and type(pos) == "number" and pos >= 0 and pos <= last then
          local place = nil
          if pos <= limits.starters then
            place = 0
            if type(formation) == "number" then
              local okP2, bits = VRFW.host.command(MC.FORMATION_INFO, 6, formation, pos)
              if okP2 then
                place = place_of(bits)
              end
            end
          end
          local chara_param = VRFW.host.command(MC.STATUS, hdl, 4)
          out[#out + 1] = {hdl = hdl, card = u32(chara_param), level = tonumber(VRFW.host.command(MC.STATUS, hdl, 0)) or 0,
                           rarity = tonumber(VRFW.host.command(MC.STATUS, hdl, 12)) or -1, pos = pos, place = place,
                           avatar = VRFW.host.command(MC.IS_AVATAR, chara_param) == true}
        end
      end
    end
    return out
  end

  local function csv(s)
    local t = {}
    for x in string.gmatch(s or "", "[^,]+") do
      t[#t + 1] = tonumber(x)
    end
    return t
  end

  local function log_dock(c, tt, dock, ps, ok, failed)
    if MC.logged_dock ~= dock then
      MC.logged_dock = dock
      MC.logged = {}
    end
    if MC.logged[c.i] then
      return
    end
    MC.logged[c.i] = true
    local avatars, attributes = 0, 0
    for _, p in ipairs(ps) do
      if p.avatar then
        avatars = avatars + 1
      end
      if VRFW.host.command(MC.HAS_ATTRIBUTE, p.hdl, MC.ATTRIBUTE_AVATAR) == true then
        attributes = attributes + 1
      end
    end
    MC.log("dock team", tt or 0, c.name, "players", #ps, "avatars", avatars, "avatar_attribute", attributes,
           "ok", ok, "failed", failed ~= "" and failed or "-")
  end

  --- Checks challenge i against the squad; answers ok, failed, bad, players.
  function MC.check(i, tt, cleared)
    local c = MC.details(i)
    if c == nil then
      return true, {}, {}, {}
    end
    local ps = MC.players(c.scope, tt)
    local parts = {}
    for _, p in ipairs(ps) do
      -- not "%d": card ids >= 2^31 (32-bit `long`); the place only for starters
      parts[#parts + 1] = string.format("%.0f:%.0f:%.0f:%.0f:%d", p.card, p.level, p.rarity, p.place or -1, p.avatar and 1 or 0)
    end
    local dock = table.concat(parts, ";")
    local ok, failed, bad = VRFW.host.command(MC.CMD.CHECK, i, dock, cleared and 1 or 0)
    log_dock(c, tt, tostring(tt or 0) .. "|" .. dock, ps, ok, tostring(failed or ""))
    if ok == nil then
      return true, {}, {}, ps
    end
    return ok == true, csv(failed), csv(bad), ps
  end

  --- The row a restricted match plays with its supplied squad: its challenge covers `diff` and leaves SUPPLY_ROW out (nil = none).
  function MC.supply_row(game, diff)
    local i = MC.of(game, diff)
    local c = i and MC.details(i)
    if c == nil or next(c.diffs) == nil or not c.diffs[diff] or c.diffs[MC.SUPPLY_ROW] or diff == MC.SUPPLY_ROW then
      return nil
    end
    return MC.SUPPLY_ROW
  end

  local function dock_of(list)
    local parts = {}
    for _, p in ipairs(list) do
      parts[#parts + 1] = string.format("%.0f:%.0f:%.0f:-1:%d", u32(p.param), p.level, p.rarity, VRFW.host.command(MC.IS_AVATAR, p.param) == true and 1 or 0)
    end
    return table.concat(parts, ";")
  end

  --- Whether the whole club can field challenge i: the club minus every player the rules reject still fills the starters and passes.
  function MC.club_can_field(i, tt, cleared)
    local roster = VRFW.recruit ~= nil and VRFW.recruit.roster() or nil
    if roster == nil then
      return true   -- the club cannot be read: the challenge's normal refusal stands
    end
    local need = (MC.LAST[tt or 0] or MC.LAST[0]).starters + 1
    local cflag = cleared and 1 or 0
    local ok, _, bad = VRFW.host.command(MC.CMD.CHECK, i, dock_of(roster), cflag)
    local rejected = {}
    for _, k in ipairs(csv(bad)) do
      rejected[k] = true
    end
    local eligible = {}
    for k, p in ipairs(roster) do
      if not rejected[k] then
        eligible[#eligible + 1] = p
      end
    end
    if #eligible < need then
      MC.log("club", i, "players", #roster, "eligible", #eligible, "cannot field")
      return false
    end
    if ok ~= true then
      ok = VRFW.host.command(MC.CMD.CHECK, i, dock_of(eligible), cflag)
    end
    MC.log("club", i, "players", #roster, "eligible", #eligible, ok == true and "can field" or "cannot field")
    return ok == true
  end

  -- split "a=1;b=(x;y);c=(p)|(q)" at top-level `;`
  local function parts_of(s)
    local out, depth, cur = {}, 0, {}
    for ch in string.gmatch(s or "", ".") do
      if ch == "(" then
        depth = depth + 1
      elseif ch == ")" then
        depth = depth - 1
      end
      if ch == ";" and depth == 0 then
        out[#out + 1] = table.concat(cur)
        cur = {}
      else
        cur[#cur + 1] = ch
      end
    end
    if #cur > 0 then
      out[#out + 1] = table.concat(cur)
    end
    return out
  end

  local function inner(s)
    return (s or ""):match("^%((.*)%)$") or s or ""
  end

  local function words(map, list)
    local t = {}
    for _, v in ipairs(csv(list)) do
      t[#t + 1] = text(map[v])
    end
    return table.concat(t, text(MC.T.OR))
  end

  local function series_names(list)
    local t = {}
    for _, v in ipairs(csv(list)) do
      local okc, name = VRFW.host.menu_command(MC.SERIES, 1, v)
      if okc and type(name) == "string" and name ~= "" then
        t[#t + 1] = name
      end
    end
    return table.concat(t, text(MC.T.OR))
  end

  local function bounds(v)
    local a, z = v:match("^(%-?%d*)%-(%-?%d*)$")
    return tonumber(a), tonumber(z)
  end

  --- The filter description (CMND_VRFW_TEAM_CHALLENGE_REQ's last value) in words.
  function MC.filter(desc)
    local out = {}
    for _, part in ipairs(parts_of(desc)) do
      local k, v = part:match("^(%a+)=(.*)$")
      if k == "gender" then
        out[#out + 1] = text(MC.T.GENDER[tonumber(v)])
      elseif k == "element" then
        out[#out + 1] = fmt(MC.T.F_ELEMENT, words(MC.T.ELEMENT, v))
      elseif k == "position" then
        out[#out + 1] = fmt(MC.T.F_POSITION, words(MC.T.POSITION, v))
      elseif k == "series" then
        local names = series_names(v)
        out[#out + 1] = fmt(MC.T.F_SERIES, names ~= "" and names or tostring(#csv(v)))
      elseif k == "team" then
        out[#out + 1] = fmt(MC.T.F_TEAM, tonumber(v) or 0)
      elseif k == "chara" then
        out[#out + 1] = fmt(MC.T.F_CHARA, tonumber(v) or 0)
      elseif k == "level" or k == "rarity" then
        local a, z = bounds(v)
        local T = MC.T
        local min_id, max_id, both = T.F_LEVEL_MIN, T.F_LEVEL_MAX, T.F_LEVEL
        if k == "rarity" then
          min_id, max_id, both = T.F_RARITY_MIN, T.F_RARITY_MAX, T.F_RARITY
        end
        if a and z then
          out[#out + 1] = fmt(both, a, z)
        elseif a then
          out[#out + 1] = fmt(min_id, a)
        elseif z then
          out[#out + 1] = fmt(max_id, z)
        end
      elseif k == "avatar" then
        out[#out + 1] = v == "1" and text(MC.T.F_AVATAR) or fmt(MC.T.F_NOT, text(MC.T.F_AVATAR))
      elseif k == "not" then
        out[#out + 1] = fmt(MC.T.F_NOT, MC.filter(inner(v)))
      elseif k == "any" then
        local alts = {}
        for alt in string.gmatch(v, "%b()") do
          alts[#alts + 1] = MC.filter(inner(alt))
        end
        out[#out + 1] = table.concat(alts, text(MC.T.OR))
      end
    end
    if #out == 0 then
      return text(MC.T.ANYONE)
    end
    return table.concat(out, text(MC.T.AND))
  end

  --- Appends the requirement lines of challenge i at `path` to `lines`; answers `lines`.
  function MC.lines(i, path, depth, lines)
    lines = lines or {}
    local kind, lo, hi, own, nsub, desc = VRFW.host.command(MC.CMD.REQ, i, path)
    if type(kind) ~= "string" or kind == "" then
      return lines
    end
    local pad = string.rep("  ", depth or 0) .. "· "
    if type(own) == "number" and own ~= 0 and text(own) ~= "" then
      lines[#lines + 1] = pad .. text(own)
      return lines
    end
    local what = MC.filter(desc)
    if kind == "every" then
      lines[#lines + 1] = pad .. fmt(MC.T.EVERY, what)
    elseif kind == "none" then
      lines[#lines + 1] = pad .. fmt(MC.T.NONE, what)
    elseif kind == "count" then
      if lo >= 0 and hi >= 0 then
        lines[#lines + 1] = pad .. fmt(MC.T.BETWEEN, lo, hi, what)
      elseif hi >= 0 then
        lines[#lines + 1] = pad .. fmt(MC.T.AT_MOST, hi, what)
      else
        lines[#lines + 1] = pad .. fmt(MC.T.AT_LEAST, math.max(lo, 0), what)
      end
    elseif kind == "any" or kind == "all" then
      lines[#lines + 1] = pad .. text(kind == "any" and MC.T.ANY_OF or MC.T.ALL_OF)
      for k = 1, nsub or 0 do
        MC.lines(i, path .. "/" .. k, (depth or 0) + 1, lines)
      end
    end
    return lines
  end

  --- The line of required starter k (1-based) of challenge i.
  function MC.required_line(i, k)
    local c = MC.details(i)
    local r = c and c.required[k]
    if r == nil then
      return nil
    end
    local pad = "· "
    if type(r.text) == "number" and r.text ~= 0 and text(r.text) ~= "" then
      return pad .. text(r.text)
    end
    local who = fmt(MC.T.F_CHARA, r.count)
    if #r.places == 0 then
      return pad .. fmt(MC.T.REQUIRED, who)
    end
    return pad .. fmt(MC.T.REQUIRED_PLACES, who, words(MC.T.POSITION, table.concat(r.places, ",")))
  end

  --- The refusal text of a match row's challenge; nil when it is allowed.
  function MC.refusal(game, tt, diff, beaten)
    local i = MC.applies(game, diff, beaten)
    if i == nil then
      return nil
    end
    local ok, failed, bad, ps = MC.check(i, tt, MC.won(game, diff, beaten))
    local c = MC.details(i)
    MC.log("check", c and c.name or i, "game", game, ok and "ok" or "refused", "failed", table.concat(failed, ","), "players", #ps, "offenders", #bad)
    if ok or c == nil then
      return nil
    end
    local t = text(c.title)
    local lines = {fmt(MC.T.HEAD, t ~= "" and t or c.name)}
    local d = text(c.description)
    if d ~= "" then
      lines[#lines + 1] = d
    end
    lines[#lines + 1] = text(MC.T.REFUSED) .. (c.scope == "starters" and (" " .. text(MC.T.STARTERS)) or "")
    for _, k in ipairs(failed) do
      if k > c.nreq then
        lines[#lines + 1] = MC.required_line(i, k - c.nreq)
      else
        MC.lines(i, tostring(k), 0, lines)
      end
    end
    if #bad > 0 then
      local names = {}
      for n, k in ipairs(bad) do
        if n > MC.MAX_NAMES then
          break
        end
        local p = ps[k]
        local nm = p and VRFW.host.command(MC.NAME, p.hdl)
        names[#names + 1] = type(nm) == "string" and nm or "?"
      end
      local s = table.concat(names, text(MC.T.AND))
      if #bad > MC.MAX_NAMES then
        s = fmt(MC.T.MORE, s, #bad - MC.MAX_NAMES)
      end
      lines[#lines + 1] = fmt(MC.T.OFFENDERS, s)
    end
    return table.concat(lines, "\n")
  end

  --- The challenge status of a match row as a table; nil when there is none.
  function MC.status(game, tt, diff, beaten)
    local i = MC.applies(game, diff, beaten)
    local c = i ~= nil and MC.details(i) or nil
    if c == nil then
      return nil
    end
    local cleared = MC.won(game, diff, beaten)
    local ok, _, bad = MC.check(i, tt, cleared)
    local label = text(c.short)
    if label == "" then
      label = text(c.title)
    end
    if label == "" then
      label = c.name
    end
    for _, r in ipairs(c.required) do
      local suffix = r.label ~= 0 and not (r.until_first_clear and cleared) and text(r.label) or ""
      if suffix ~= "" then
        label = fmt(MC.T.WITH_REQUIRED, label, suffix)
      end
    end
    local aura_suffix = c.auras ~= nil and text(c.auras.label) or ""
    if aura_suffix ~= "" then
      label = fmt(MC.T.WITH_REQUIRED, label, aura_suffix)
    end
    local move_suffix = c.moves ~= nil and text(c.moves.label) or ""
    if move_suffix ~= "" then
      label = fmt(MC.T.WITH_REQUIRED, label, move_suffix)
    end
    return {i = i, ok = ok, offenders = #bad, label = label}
  end

  --- Arms the aura and move rules the challenge on a match row declares.
  function MC.arm_auras(game, diff, beaten)
    local i = MC.applies(game, diff, beaten)
    local c = i ~= nil and MC.details(i) or nil
    pcall(funcLuaCommand, MC.AURAS_DISARM)
    if c ~= nil and c.auras ~= nil then
      MC.log("auras", c.name, "game", game, "allowed", c.auras.allowed == "" and "none" or c.auras.allowed, "sides", c.auras.sides)
      pcall(funcLuaCommand, MC.AURAS_ARM, c.auras.allowed, c.auras.sides)
    end
    if c ~= nil and c.moves ~= nil then
      MC.log("moves", c.name, "game", game, "banned", c.moves.banned, "sides", c.moves.sides)
      pcall(funcLuaCommand, MC.MOVES_ARM, c.moves.banned, c.moves.sides)
    end
  end

  --- True when the match row's challenge lets the match start; a refusal shows its text.
  function MC.gate(game, tt, diff, beaten)
    local msg = MC.refusal(game, tt, diff, beaten)
    if msg == nil then
      MC.arm_auras(game, diff, beaten)
      return true
    end
    pcall(funcLuaCommand, MC.SE, MC.SE_NG)
    pcall(funcLuaCommand, MC.MSG_OPEN, msg, 0, 0, 0, 0, 0, false)
    return false
  end
end
