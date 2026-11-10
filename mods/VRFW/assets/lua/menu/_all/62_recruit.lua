-- lua_patch.scope: used
-- menu_engine: the RECRUIT service.
if VRFW.recruit == nil then
  local R = {
    C = {
      ADD_PARTY = VRFW.commands.ADD_PARTY,        -- CMND_ADD_PARTY 0x705FC228
      AFTER_ADD = 3007956834,
      AUTO_SAVE = VRFW.commands.SYSTEM_AUTO_SAVE,        -- CMND_SYSTEM_AUTO_SAVE
      OWNED = 1052152255,            -- (card, 0) -> ok, n / n: copies of the card in the club
      CHARA_INFO = VRFW.commands.GET_CHARA_INFO,
      BANK_FREE = VRFW.commands.CAN_SPIRIT_NUM,        -- CMND_CAN_SPIRIT_NUM -> free bank slots
      ITEM_NUM = VRFW.commands.GET_ITEM_NUM,         -- CMND_GET_ITEM_NUM (id, false) -> count
      DEL_ITEM = VRFW.commands.DELETE_ITEM,
      ITEM_FITS = 765340069,         -- (id, n) -> the bag has room
      ADD_ITEM = VRFW.commands.ADD_ITEM_ONLY,         -- CMND_ADD_ITEM_ONLY (id, n): no window
      CLUB = VRFW.commands.VRFW_RECRUIT_CLUB,
      SAVE_GET = VRFW.commands.VRFW_SAVE_GET,
      IN_STORY = 424926145,
      STORY_DOCK = 2787124386,       -- the story's team dock in use
      VS_DOCK = VRFW.commands.GET_VS_USE_TEAM_SET,
      TEAM_SET_INFO = VRFW.commands.GET_TEAM_SET_INFO,    -- CMND_GET_TEAM_SET_INFO (dock, 0, 1) -> ok, team level
      GAME_CLEAR = VRFW.commands.GET_SOCCER_GAME_CLEAR_FLAG,        -- CMND_GET_SOCCER_GAME_CLEAR_FLAG (game, difficulty) -> won
      CHRONICLE_CLEAR = VRFW.commands.GET_CHRONICLE_CLEAR_STATUS,
      GLOBAL_BIT = VRFW.commands.GET_GLOBAL_BIT_FLAG,        -- CMND_GET_GLOBAL_BIT_FLAG (flag) -> on.
      PASSED = 1073637999,           -- CMND_VRFW_FRIENDLY_PASSED (friendly id, tag, sub) -> passed
      HOLDERS = VRFW.commands.VRFW_RECRUIT_HOLDERS,
      ROSTER = VRFW.commands.VRFW_RECRUIT_ROSTER,   -- CMND_VRFW_RECRUIT_ROSTER () -> every club player {param, level, rarity}
      SPIRIT_NUM = VRFW.commands.GET_SPIRIT_NUM,       -- CMND_GET_SPIRIT_NUM (card, rarity) -> ok, n
      ADD_SPIRIT = VRFW.commands.ADD_ITEM_SPIRIT,       -- CMND_ADD_ITEM_SPIRIT (card, n, rarity, used): n < 0 takes
      RETIRE = 3955826921,           -- the bank's retire (funcLuaMenuCommand, handle) -> ok
      STATUS = 1131797651,
      HAS_ATTRIBUTE = 29506568,
      SET_ATTRIBUTE = 1525180681,    -- 0x5AE86909 (handle, mask, on): sets / clears attribute bits
    },
    ATTRIBUTE_SEASON = 0x100000,
    SPIRIT_RARITIES = {0, 1, 2, 3, 4},   -- a spirit price is paid with any rarity, lowest first
    holders_cache = {},                    -- card list -> club players, until Refresh()
    cleared_cache = {},                    -- "game:difficulty" -> won, until Refresh()
    OWNER = "VRFW",
    club_cache = nil,                      -- the club counts (CMND_VRFW_RECRUIT_CLUB), until Refresh()
    TEAM_SET_BANK = 16,
    RARITY = 4,                      -- the default join rarity of a normal card
    INFO_SPECIAL_RARITY = 8,         -- CMND_GET_CHARA_INFO field: the card's special rarity
    SOURCE = 2,                      -- CMND_ADD_PARTY arg 17: 2 = scouted (the office uses 4)
  }
  VRFW.recruit = R

  local function num(v)
    if type(v) ~= "number" then
      return 0
    end
    return math.floor(v + 0.5)
  end

  local logger
  --- Logs through the recruit logger.
  function R.log(...)
    logger = logger or VRFW.logger.new("recruit")
    logger(...)
  end

  --- How many copies of player `param` the club holds.
  function R.owned(param)
    local a, b = VRFW.host.command(R.C.OWNED, param, 0)
    if type(a) == "number" then
      return num(a)                  -- some builds answer the count first
    end
    return num(b)
  end

  --- How many of the cards in `ids` the club holds.
  function R.owned_any(ids)
    local n = 0
    for _, id in ipairs(ids or {}) do
      n = n + R.owned(id)
    end
    return n
  end

  --- How many of item `id` the player has.
  function R.items(id)
    return num(VRFW.host.command(R.C.ITEM_NUM, id, false))
  end

  --- Forget the club counts (after a signing, or when a screen opens).
  function R.refresh()
    R.club_cache = nil
    R.cleared_cache = {}
    R.holders_cache = {}
  end

  --- The club players of some cards (cached per list until Refresh).
  function R.holders(ids)
    local key = table.concat(ids or {}, ",")
    if R.holders_cache[key] == nil then
      local list = VRFW.host.command(R.C.HOLDERS, table.unpack(ids or {}))
      R.holders_cache[key] = type(list) == "table" and list or {}
    end
    return R.holders_cache[key]
  end

  local function check(c)
    local key = tostring(c.t) .. ":" .. tostring(c.a) .. ":" .. tostring(c.b)
    local v = R.cleared_cache[key]
    if v == nil then
      if c.t == "game" then
        v = VRFW.host.command(R.C.GAME_CLEAR, c.a, c.b) == true
      elseif c.t == "chronicle" then
        v = (c.a or 0) > 0 and VRFW.host.command(R.C.CHRONICLE_CLEAR, c.a, c.b) == true
      elseif c.t == "flag" then
        v = VRFW.host.command(R.C.GLOBAL_BIT, c.a) == true
      else
        v = false
      end
      R.cleared_cache[key] = v
    end
    return v
  end

  --- 1 when every group has a check that holds.
  function R.unlocked(groups)
    for _, g in ipairs(groups or {}) do
      local any = false
      for _, c in ipairs(g) do
        if check(c) then
          any = true
          break
        end
      end
      if not any then
        return 0
      end
    end
    return 1
  end

  local function spirit_num(card, r)
    local a, b = VRFW.host.command(R.C.SPIRIT_NUM, card, r)
    local v = type(b) == "number" and b or (type(a) == "number" and a or 0)
    return math.max(0, num(v))
  end

  --- How many spirits of `card` the player has, over every rarity.
  function R.spirits(card)
    local n = 0
    for _, r in ipairs(R.SPIRIT_RARITIES) do
      n = n + spirit_num(card, r)
    end
    return n
  end

  --- Takes n spirits of `card`; answers true, or false when there are too few.
  function R.charge_spirits(card, n)
    n = num(n)
    if n <= 0 then
      return true
    end
    if R.spirits(card) < n then
      return false
    end
    local left = n
    for _, r in ipairs(R.SPIRIT_RARITIES) do
      if left <= 0 then
        break
      end
      local take = math.min(spirit_num(card, r), left)
      if take > 0 then
        VRFW.host.command(R.C.ADD_SPIRIT, card, -take, r, false)
        left = left - take
      end
    end
    return left <= 0
  end

  --- Gives n spirits of `card`; answers true.
  function R.give_spirits(card, n)
    n = num(n)
    if n > 0 then
      VRFW.host.command(R.C.ADD_SPIRIT, card, n, 4, false)
    end
    return true
  end

  --- a price: {item = id, count = n} or {spirit = card, count = n}; answers true, or false when it cannot be paid.
  function R.pay(price)
    if price == nil or (price.count or 0) <= 0 then
      return true
    end
    if price.spirit ~= nil and price.spirit ~= 0 then
      return R.charge_spirits(price.spirit, price.count)
    end
    return R.charge(price.item, price.count)
  end

  --- Gives back the price paid.
  function R.refund(price)
    if price == nil or (price.count or 0) <= 0 then
      return
    end
    if price.spirit ~= nil and price.spirit ~= 0 then
      R.give_spirits(price.spirit, price.count)
    else
      R.give(price.item, price.count)
    end
  end

  --- What the player has to pay with: the spirits of `spirit`, else the item.
  function R.wallet(price)
    if price ~= nil and price.spirit ~= nil and price.spirit ~= 0 then
      return R.spirits(price.spirit)
    end
    return R.items(price and price.item or 0)
  end

  --- 1 when every game in `games` was cleared, else 0.
  function R.cleared(games)
    if type(games) ~= "table" then
      return 0
    end
    for i = 1, #games - 1, 2 do
      local key = tostring(games[i]) .. ":" .. tostring(games[i + 1])
      local won = R.cleared_cache[key]
      if won == nil then
        won = VRFW.host.command(R.C.GAME_CLEAR, games[i], games[i + 1]) == true
        R.cleared_cache[key] = won
      end
      if won then
        return 1
      end
    end
    return 0
  end

  --- The club counts (total, element, position), cached until R.refresh.
  function R.club()
    if R.club_cache == nil then
      local c = VRFW.host.command(R.C.CLUB)
      R.club_cache = type(c) == "table" and c or {total = 0, element = {}, position = {}}
    end
    return R.club_cache
  end

  --- The level of the team in use (1 when it cannot be read).
  function R.team_level()
    local dock
    if VRFW.host.command(R.C.IN_STORY) == true then
      dock = VRFW.host.command(R.C.STORY_DOCK)
    else
      dock = VRFW.host.command(R.C.VS_DOCK)
    end
    local ok, lv = VRFW.host.command(R.C.TEAM_SET_INFO, num(dock), 0, 1)
    if ok == true and type(lv) == "number" then
      return num(lv)
    end
    return 1
  end

  --- Career value `key` from the save, as a number.
  function R.career(key)
    return num(tonumber(VRFW.host.command(R.C.SAVE_GET, R.OWNER, key, "0")))
  end

  --- The player's current amount towards requirement `req`.
  function R.have(req)
    local k = req.kind
    if k == "player" then
      if (req.level or 0) > 1 then
        local n = 0
        for _, h in ipairs(R.holders(req.ids)) do
          if (h.level or 0) >= req.level then
            n = n + 1
          end
        end
        return n
      end
      return R.owned_any(req.ids)
    elseif k == "item" then
      return R.items(req.id)
    elseif k == "team_level" then
      return R.team_level()
    elseif k == "element" then
      return num((R.club().element or {})[req.element])
    elseif k == "position" then
      return num((R.club().position or {})[req.position])
    elseif k == "wins" then
      return R.career("stats.matches_won")
    elseif k == "goals" then
      return R.career("stats.goals")
    elseif k == "cleared" then
      return R.cleared(req.games)
    elseif k == "unlock" then
      return R.unlocked(req.groups)
    elseif k == "trial" then
      local key = "trial:" .. tostring(req.friendly) .. ":" .. tostring(req.tag) .. ":" .. tostring(req.sub)
      if R.cleared_cache[key] == nil then
        R.cleared_cache[key] = VRFW.host.command(R.C.PASSED, req.friendly, req.tag or 0, req.sub or 0) == true
      end
      return R.cleared_cache[key] and 1 or 0
    end
    return 0
  end

  --- The requirements not met, as a list.
  function R.missing(reqs)
    local out = {}
    for _, q in ipairs(reqs or {}) do
      if R.have(q) < (q.count or 1) then
        out[#out + 1] = q
      end
    end
    return out
  end

  --- Removes n of item `item`; answers true, or false when there are too few.
  function R.charge(item, n)
    n = num(n)
    if n <= 0 then
      return true
    end
    if R.items(item) < n then
      return false
    end
    return VRFW.host.command(R.C.DEL_ITEM, item, n) ~= false
  end

  --- Adds n of item `item`; answers true, or false when it does not fit.
  function R.give(item, n)
    n = num(n)
    if n <= 0 then
      return true
    end
    if VRFW.host.command(R.C.ITEM_FITS, item, n) == false then
      return false
    end
    VRFW.host.command(R.C.ADD_ITEM, item, n)
    return true
  end

  --- Every player of the club: {param, level, rarity}, nil = the club is not readable.
  function R.roster()
    local list = VRFW.host.command(R.C.ROSTER)
    return type(list) == "table" and list or nil
  end

  --- True when `param` can be signed, or false, why ("owned", "bank_full").
  function R.can_sign(param)
    if R.owned(param) > 0 then
      return false, "owned"
    end
    local free = VRFW.host.command(R.C.BANK_FREE)
    if type(free) == "number" and free < 1 then
      return false, "bank_full"
    end
    return true
  end

  --- The rarity a new card of `param` joins with.
  function R.card_rarity(param)
    local first, second = VRFW.host.command(R.C.CHARA_INFO, param, R.INFO_SPECIAL_RARITY)
    local special = type(second) == "number" and second or first
    if type(special) == "number" and special > 0 then
      return num(special)
    end
    return R.RARITY
  end

  --- Signs player `param`; answers the handle, or nil, why.
  function R.sign(param, level, rarity, source)
    local ok, why = R.can_sign(param)
    if not ok then
      return nil, why
    end
    level = math.max(1, num(level))
    rarity = rarity or R.card_rarity(param)
    local hdl = VRFW.host.command(R.C.ADD_PARTY, param, level, false, false, 0, 0, false, false, false, R.TEAM_SET_BANK, 255, 255,
      rarity, true, true, false, source or R.SOURCE, false, false, 0)
    VRFW.host.command(R.C.AFTER_ADD)
    if R.owned(param) <= 0 then
      R.log("sign failed", param, level, rarity)
      return nil, "refused"
    end
    R.log("signed", param, "level", level, "rarity", rarity, hdl)
    R.refresh()
    R.clear_season(param, hdl)
    return hdl or 0
  end

  --- Clears the season state of a signed player.
  function R.clear_season(param, hdl)
    local handles = {}
    if type(hdl) == "number" and hdl ~= 0 then
      handles[1] = hdl
    else
      for _, h in ipairs(R.holders({param})) do
        handles[#handles + 1] = h.handle
      end
    end
    for _, h in ipairs(handles) do
      if VRFW.host.command(R.C.HAS_ATTRIBUTE, h, R.ATTRIBUTE_SEASON) == true then
        VRFW.host.command(R.C.SET_ATTRIBUTE, h, R.ATTRIBUTE_SEASON, false)
        R.log("season bit cleared", param, h, "still set", VRFW.host.command(R.C.HAS_ATTRIBUTE, h, R.ATTRIBUTE_SEASON) == true)
      end
    end
  end

  --- Pays and signs opt.param; answers true, or false, why.
  function R.recruit(opt)
    local ok, why = R.can_sign(opt.param)
    if not ok then
      return false, why
    end
    if #R.missing(opt.reqs) > 0 then
      return false, "requirements"
    end
    local price = opt.price
    if not R.pay(price) then
      return false, "price"
    end
    local hdl, err = R.sign(opt.param, opt.level, opt.rarity, opt.source)
    if hdl == nil then
      R.refund(price)
      return false, err
    end
    VRFW.host.command(R.C.AUTO_SAVE)
    return true
  end

  --- The free places in the bank; nil when they cannot be read.
  function R.bank_room()
    local free = VRFW.host.command(R.C.BANK_FREE)
    return type(free) == "number" and free or nil
  end

  --- Signs a list of players, one payment for all; opt.count_of / opt.rarity_of (by card) over price_each.count / opt.rarity; answers the signed list, and why when one failed.
  function R.recruit_list(opt)
    local params, signed, why = {}, {}, nil
    for _, card in ipairs(opt.params or {}) do
      local ok, err = R.can_sign(card)
      if ok then
        params[#params + 1] = card
      else
        why = err
      end
    end
    if #params == 0 then
      return signed, why
    end
    local function price_of(first)
      local each = opt.price_each
      if each == nil then
        return nil
      end
      local count = 0
      for i = first, #params do
        count = count + (opt.count_of ~= nil and opt.count_of[params[i]] or each.count or 0)
      end
      return {item = each.item, spirit = each.spirit, count = count}
    end
    if not R.pay(price_of(1)) then
      return signed, "price"
    end
    for _, card in ipairs(params) do
      local rarity = opt.rarity_of ~= nil and opt.rarity_of[card] or opt.rarity
      local hdl, err = R.sign(card, opt.level, rarity, opt.source)
      if hdl == nil then
        why = err
        break
      end
      signed[#signed + 1] = card
    end
    R.refund(price_of(#signed + 1))
    if #signed > 0 then
      VRFW.host.command(R.C.AUTO_SAVE)
    end
    return signed, why
  end

  --- Removes players `cards` from the club and gives back the price; answers true, or false, why.
  function R.release(cards, refund_price)
    R.holders_cache = {}
    local h = nil
    local busy = false
    for _, x in ipairs(R.holders(cards)) do
      if x.busy then
        busy = true
      elseif h == nil then
        h = x
      end
    end
    if h == nil then
      return false, busy and "busy" or "none"
    end
    local rarity = num(VRFW.host.command(R.C.STATUS, h.handle, 12))
    local before = spirit_num(h.param, rarity)
    local owned = R.owned(h.param)
    local ok, done = pcall(funcLuaMenuCommand, R.C.RETIRE, h.handle)
    R.log("release", h.param, h.handle, tostring(ok), tostring(done))
    R.refresh()
    if R.owned(h.param) >= owned then
      return false, "refused"                              -- the bank refused (e.g. he is in a team dock)
    end
    local now = spirit_num(h.param, rarity)
    if now == before + 1 then
      VRFW.host.command(R.C.ADD_SPIRIT, h.param, -1, rarity, true)     -- the retire's card back: one card per character
    end
    R.refund(refund_price)
    VRFW.host.command(R.C.AUTO_SAVE)
    return true
  end
end

if vrfw_recruit_trial == nil then
  local GAME_RIVAL = 2204933160      -- (game, difficulty) -> has, the match row's rival team
  local GAME_STADIUM = VRFW.commands.VRFW_RECRUIT_GAME_STADIUM     -- (game) -> map crc (0 = none)

  --- Starts a recruit trial match from the menu VM; answers true when it started.
  function vrfw_recruit_trial(friendly, game, difficulty, tag, sub, objective, friendly_team)
    if type(VRFW.match_start) ~= "table" or type(VRFW.match_start.start) ~= "function" or type(friendly) ~= "string" then
      return false
    end
    difficulty = difficulty or 1
    local okr, has, rival = pcall(funcLuaCommand, GAME_RIVAL, game, difficulty)   -- (has, team), as the retail menus read it
    rival = (okr and has == true and type(rival) == "number" and rival ~= 0) and rival or nil
    local oks, stadium = pcall(funcLuaCommand, GAME_STADIUM, game)
    stadium = (oks and type(stadium) == "number" and stadium ~= 0) and stadium or nil
    local ok, started, why = pcall(VRFW.match_start.start, {friendly = friendly, game = game, difficulty = difficulty,
      tag = tag, sub = sub, objective = objective, rival = rival, stadium = stadium,
      set = function() return VRFW.match_start.pachanga_team(friendly_team) end,
      overrides = rival and {{"teams.rival.team", rival}} or nil, settle = 20, black = false})
    if VRFW.recruit ~= nil then
      VRFW.recruit.log("trial start", friendly, game, difficulty, tag, sub, objective, "rival", tostring(rival),
        "stadium", tostring(stadium), tostring(ok), tostring(started), tostring(why))
    end
    return ok and started == true
  end
end
