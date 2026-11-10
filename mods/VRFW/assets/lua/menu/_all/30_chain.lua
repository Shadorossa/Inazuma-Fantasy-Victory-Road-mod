-- lua_patch.scope: used
if VRFW.chain == nil then
  local CH = {
    -- the team type's commands
    CMD = {
      COUNT = VRFW.commands.VRFW_TEAM_CHAIN_COUNT,     -- CMND_VRFW_TEAM_CHAIN_COUNT
      GET = VRFW.commands.VRFW_TEAM_CHAIN_GET,
      BOARD = VRFW.commands.VRFW_TEAM_CHAIN_BOARD,
      PAGE = VRFW.commands.VRFW_TEAM_CHAIN_PAGE,      -- CMND_VRFW_TEAM_CHAIN_PAGE (i, p, lang) -> title
      TILE = VRFW.commands.VRFW_TEAM_CHAIN_TILE,
      OF_PIECE = VRFW.commands.VRFW_TEAM_CHAIN_OF_PIECE,
    },
    SAVE_GET = VRFW.commands.VRFW_SAVE_GET,
    SAVE_SET = VRFW.commands.VRFW_SAVE_SET,
    SET_GLOBAL_FLAG = VRFW.commands.SET_GLOBAL_BIT_FLAG,
    OWNER = "VRFW",
    PENDING = "chain.pending",
    MENU = 2748171433,       -- crc32("vrfw_chain_board_menu"): the chain board screen
    P_CHAIN = 75385505,
    P_PICK = 46591264,
    P_HUB = 659670413,       -- crc32("vrfw_chain_hub"): parameter, the hub node's save slot
    P_PICK_CHAIN = 3161495482,
    P_SUPPLIED = 2344781693,      -- crc32("vrfw_chain_supplied"): the picked tile plays its supplied line-up (match_challenge.supply_row)
    NODE = {COUNT = VRFW.commands.VRFW_TEAM_ROUTE_NODE_COUNT, GET = VRFW.commands.VRFW_TEAM_ROUTE_NODE_GET},   -- CMND_VRFW_TEAM_ROUTE_NODE_*
    DEBUG_SWITCH = VRFW.commands.VRFW_DEBUG_SWITCH,
    boards = {},             -- chain index -> board table (per VM)
    debug_all_cache = nil,         -- [debug] all_chains, read once per VM (CH.debug_all)
    bad_state = {},
  }
  VRFW.chain = CH

  local logger
  --- Logs through the chain logger.
  function CH.log(...)
    logger = logger or VRFW.logger.new("chain")
    logger(...)
  end

  local function csv(s)
    local t = {}
    for x in string.gmatch(s or "", "[^,]+") do
      t[#t + 1] = tonumber(x)
    end
    return t
  end

  local function requires(enc, names)
    local out, nm = {}, {}
    for x in string.gmatch((names or "") .. "|", "([^|]*)|") do
      nm[#nm + 1] = x
    end
    for part in string.gmatch(enc or "", "[^;]+") do
      local k, v = string.match(part, "^([%a_]+):(.+)$")
      if k ~= nil then
        out[#out + 1] = {kind = k, value = tonumber(v) or v, name = nm[#out + 1] or ""}
      end
    end
    return out
  end

  --- The rank rewards decoded from `enc` with the names in `names`.
  function CH.parse_rank_rewards(enc, names)
    local out, nm = {}, {}
    for x in string.gmatch((names or "") .. "|", "([^|]*)|") do
      nm[#nm + 1] = x
    end
    for part in string.gmatch(enc or "", "[^,]+") do
      local r, id, n, k, tx = string.match(part, "^([%w_]+):(%d+):(%d+):(%a+):?(%d*)$")
      if r ~= nil then
        out[#out + 1] = {rank = r, id = tonumber(id), count = math.max(1, tonumber(n) or 1), kind = k, name = nm[#out + 1] or "",
                         text = tonumber(tx) or 0}
      end
    end
    return out
  end

  --- Board i as a table, read once; nil when there is none.
  function CH.board(i)
    if type(i) ~= "number" or i < 0 then
      return nil
    end
    if CH.boards[i] ~= nil then
      return CH.boards[i] or nil
    end
    local cols, rows, pages, ntiles, start, matches, title, layout, direction_tolerance = VRFW.host.command(CH.CMD.BOARD, i)
    if type(cols) ~= "number" or cols <= 0 or type(ntiles) ~= "number" then
      CH.boards[i] = false
      return nil
    end
    local key = VRFW.host.command(CH.CMD.GET, i)
    local b = {i = i, key = tostring(key or i), title = title or "", cols = cols, rows = rows, pages = {}, start = start + 1, tiles = {}, matches = matches or 0,
               layout = layout == "hex" and "hex" or "square", direction_tolerance_degrees = tonumber(direction_tolerance) or 90}
    for p = 0, pages - 1 do
      b.pages[p + 1] = VRFW.host.command(CH.CMD.PAGE, i, p) or ""
    end
    for t = 0, ntiles - 1 do
      local id, kind, page, col, row, links, game, team, level, diff, ttl, rival, emblem, reward, req, reqn, sreward, rrw, rrn, areward, win_flag = VRFW.host.command(CH.CMD.TILE, i, t)
      local links1 = {}
      for _, x in ipairs(csv(links)) do
        links1[#links1 + 1] = x + 1
      end
      b.tiles[t + 1] = {id = id or "", kind = kind or "", page = page or 0, col = col or 0, row = row or 0, links = links1,
                        game = game or 0, team = team or 0, level = level or 0, difficulty = diff or 0, title = ttl or "",
                        rival = rival or "", emblem = emblem or "", reward = reward or "",
                        sreward = type(sreward) == "string" and sreward or "",
                        areward = type(areward) == "string" and areward or "",
                        win_flag = tonumber(win_flag) or 0,
                        requires = requires(type(req) == "string" and req or "", type(reqn) == "string" and reqn or ""),
                        rank_rewards = CH.parse_rank_rewards(type(rrw) == "string" and rrw or "", type(rrn) == "string" and rrn or "")}
    end
    CH.boards[i] = b
    CH.log("board", i, b.key, cols, rows, #b.pages, #b.tiles, "start", b.start)
    return b
  end

  --- The board and slot of a board piece; nil when the piece has none.
  function CH.of_piece(piece)
    local i, slot = VRFW.host.command(CH.CMD.OF_PIECE, piece)
    if type(i) ~= "number" or i < 0 then
      return nil
    end
    return CH.board(i), slot
  end

  --- The tile-state text of board b from the save.
  function CH.state(b)
    local s = VRFW.host.command(CH.SAVE_GET, CH.OWNER, "chain." .. b.key, "")
    if type(s) ~= "string" then
      if s ~= nil and not CH.bad_state[b.key] then
        CH.bad_state[b.key] = true
        CH.log("progress unreadable", b.key, "stored as", type(s), tostring(s), "-> not started")
      end
      s = ""
    end
    if string.len(s) < #b.tiles then
      s = s .. string.rep("0", #b.tiles - string.len(s))
    end
    return s
  end

  --- The state letter of tile t ("s" for the start tile).
  function CH.tile_state(b, t)
    if t == b.start then
      return "s"
    end
    return string.sub(CH.state(b), t, t)
  end

  local function put(b, t, c)
    local s = CH.state(b)
    s = string.sub(s, 1, t - 1) .. c .. string.sub(s, t + 1)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, "chain." .. b.key, s, 1)
  end

  --- True when tile t is no longer closed.
  function CH.done(b, t)
    return CH.tile_state(b, t) ~= "0"
  end

  --- The tiles of the branch that leads to tile t.
  function CH.branch(b, t)
    local seen, todo, out = {[t] = true, [b.start] = true}, {t}, {}
    while #todo > 0 do
      local i = table.remove(todo)
      for _, j in ipairs(b.tiles[i].links) do
        if not seen[j] then
          seen[j] = true
          todo[#todo + 1] = j
          if b.tiles[j].kind == "match" then
            out[#out + 1] = j
          end
        end
      end
    end
    return out
  end

  local function tier_need(tier)
    local s = VRFW.match_rank ~= nil and VRFW.match_rank.order("S") or 3
    if s == 0 and VRFW.match_rank ~= nil and VRFW.match_rank.list()[1] ~= nil then
      s = VRFW.match_rank.list()[1].order
    end
    if tier ~= "A" then
      return s
    end
    local a = VRFW.match_rank ~= nil and VRFW.match_rank.order("A") or 2
    return a > 0 and a or s
  end

  -- every match of tile t's branch won with at least that rank Order
  local function branch_at_least(b, t, need)
    local ms = CH.branch(b, t)
    for _, j in ipairs(ms) do
      if CH.rank(b, j) < need then
        return false
      end
    end
    return #ms > 0
  end

  --- An S chest (IE3's "S" chest) is ready once every match of its branch is won with S.
  function CH.s_ready(b, t)
    return branch_at_least(b, t, tier_need("S"))
  end

  --- a double chest's A tier is ready once every match of its branch is won with A or better.
  function CH.a_ready(b, t)
    return branch_at_least(b, t, tier_need("A"))
  end

  --- What the player has towards one requirement of a blocked tile, and whether it is met.
  function CH.req_have(r)
    if r.kind == "win" then
      return CH.team_wins(r.value)
    elseif r.kind == "chain" then
      local b = CH.by_key(r.value)
      return (b ~= nil and CH.complete(b)) and 1 or 0
    elseif r.kind == "team_level" then
      return VRFW.recruit ~= nil and VRFW.recruit.team_level() or 0
    elseif r.kind == "player" then
      return VRFW.recruit ~= nil and VRFW.recruit.owned_any(csv(tostring(r.value))) or 0
    end
    return 0   -- a kind this build does not know is never met
  end

  --- True when requirement r is met.
  function CH.req_met(r)
    local need = r.kind == "team_level" and (tonumber(r.value) or 1) or 1
    return CH.req_have(r) >= need
  end

  --- Every requirement of blocked tile t met.
  function CH.unblocked(b, t)
    local reqs = b.tiles[t].requires or {}
    for _, r in ipairs(reqs) do
      if not CH.req_met(r) then
        return false
      end
    end
    return #reqs > 0
  end

  -- a blocked tile reached by the path (a tile linked to it is done)
  local function reached(b, t)
    for _, j in ipairs(b.tiles[t].links) do
      if CH.tile_state(b, j) ~= "0" then
        return true
      end
    end
    return false
  end

  --- Opens every tile whose requirements are now met; answers the tiles opened.
  function CH.sync(b)
    local opened = {}
    local again = true
    while again do
      again = false
      for t, tile in ipairs(b.tiles) do
        if tile.kind == "blocked" and CH.tile_state(b, t) == "0" and reached(b, t) and CH.unblocked(b, t) then
          put(b, t, "o")
          opened[#opened + 1] = t
          again = true
          CH.log("unblocked", b.key, tile.id)
        end
      end
    end
    return opened
  end

  --- True when double chest t has no reward left.
  function CH.d_chest_empty(b, t)
    local tile = b.tiles[t]
    return tile ~= nil and tile.kind == "dchest" and tile.reward == "" and (tile.sreward or "") == "" and (tile.areward or "") == ""
  end

  --- True when the all_chains debug switch is on (read once).
  function CH.debug_all()
    if CH.debug_all_cache == nil then
      local v = VRFW.host.command(CH.DEBUG_SWITCH, "all_chains")
      CH.debug_all_cache = (v == true or v == 1)
      if CH.debug_all_cache then
        CH.log("debug all_chains: every match tile open")
      end
    end
    return CH.debug_all_cache
  end

  --- Opens tile t; answers true when it is open, false when it cannot be.
  function CH.open(b, t)
    if CH.done(b, t) then
      return true
    end
    if b.tiles[t].kind == "match" and CH.debug_all() then
      return true
    end
    if b.tiles[t].kind == "slot" or b.tiles[t].kind == "blocked" or (b.tiles[t].kind == "schest" and not CH.s_ready(b, t))
        or CH.d_chest_empty(b, t) then
      return false
    end
    for _, j in ipairs(b.tiles[t].links) do
      if CH.done(b, j) then
        return true
      end
    end
    return false
  end

  local function rank_map(b)
    local s = VRFW.host.command(CH.SAVE_GET, CH.OWNER, "chain." .. b.key .. ".ranks", "")
    local m = {}
    if type(s) == "string" then
      for t, id in string.gmatch(s, "(%d+)=([^;]+)") do
        m[tonumber(t)] = id
      end
    end
    return m
  end

  local function put_rank(b, t, id)
    local m = rank_map(b)
    m[t] = id
    local parts = {}
    for k, v in pairs(m) do
      parts[#parts + 1] = k .. "=" .. v
    end
    table.sort(parts)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, "chain." .. b.key .. ".ranks", table.concat(parts, ";"), 1)
  end

  --- The rank Id of a won match tile (nil = not won).
  function CH.rank_id(b, t)
    local c = CH.tile_state(b, t)
    if c == "r" then
      return rank_map(b)[t]
    end
    local n = tonumber(c)
    if n ~= nil and n > 0 then
      return VRFW.match_rank ~= nil and VRFW.match_rank.from_legacy(n) or ({"B", "A", "S"})[n]
    end
    return nil
  end

  --- The rank order of tile t; 0 when it was not won.
  function CH.rank(b, t)
    local id = CH.rank_id(b, t)
    if id == nil then
      return 0
    end
    local o = VRFW.match_rank ~= nil and VRFW.match_rank.order(id) or 0
    return o > 0 and o or 1
  end

  local floor_on = false
  local function stats()
    if VRFW.stats == nil then
      return nil
    end
    if not floor_on then
      floor_on = true
      VRFW.stats.add_floor(function(team)
        local n = 0
        for _, b in pairs(CH.boards) do
          if b then
            for t, tile in ipairs(b.tiles) do
              if tile.kind == "match" and tile.team == team and CH.done(b, t) then
                n = n + 1
              end
            end
          end
        end
        return n
      end)
    end
    return VRFW.stats
  end

  --- Records the win of match tile t at `rank`; answers the previous rank Id.
  function CH.win(b, t, rank)
    local id = rank
    if type(rank) ~= "string" then
      id = ({"B", "A", "S"})[math.max(1, math.min(3, math.floor(tonumber(rank) or 1)))]
    end
    if stats() ~= nil and b.tiles[t] ~= nil and b.tiles[t].kind == "match" then
      VRFW.stats.add_win(b.tiles[t].team)
    end
    local old = CH.rank_id(b, t)
    local links = (b.tiles[t] or {}).links or {}
    local was_open = {}
    for _, j in ipairs(links) do
      was_open[j] = CH.open(b, j)
    end
    local better = old == nil or (VRFW.match_rank ~= nil and VRFW.match_rank.order(id) > VRFW.match_rank.order(old))
    if better then
      local legacy = ({B = "1", A = "2", S = "3"})[id]
      if legacy ~= nil then
        put(b, t, legacy)
      else
        put_rank(b, t, id)
        put(b, t, "r")
      end
      old = id
    end
    CH.log("win", b.key, b.tiles[t].id, "rank", id, "best", old)
    if b.tiles[t].win_flag ~= 0 then
      funcLuaCommand(CH.SET_GLOBAL_FLAG, b.tiles[t].win_flag, true)
    end
    if better then
      local opened = {}
      for _, j in ipairs(links) do
        if not was_open[j] and CH.open(b, j) then
          opened[#opened + 1] = b.tiles[j].id
        end
      end
      local stored = CH.tile_state(b, t)
      CH.log("unlock", b.key, b.tiles[t].id, "stored", stored, stored == "0" and "NOT SAVED" or "saved",
             "opens", #opened > 0 and table.concat(opened, ",") or "-", CH.debug_all() and "(debug all_chains)" or "")
    end
    if #((b.tiles[t] or {}).rank_rewards or {}) > 0 then
      CH.pay_rank(b, t)
    end
    return old
  end

  local function dchest_left(tile, st)
    local base = tile.reward ~= "" and st == "0"
    local a = (tile.areward or "") ~= "" and st ~= "a" and st ~= "o"
    local s = (tile.sreward or "") ~= "" and st ~= "o"
    return base, a, s
  end

  --- Opens chest t; answers its state letter afterwards.
  function CH.open_chest(b, t)
    local tile = b.tiles[t]
    if tile.kind == "dchest" then
      local st = CH.tile_state(b, t)
      if CH.d_chest_empty(b, t) or st == "o" then
        return st
      end
      local base, a, s = dchest_left(tile, st)
      if CH.s_ready(b, t) then
        put(b, t, "o")
      elseif a and CH.a_ready(b, t) then
        put(b, t, s and "a" or "o")
      elseif base then
        put(b, t, (a or s) and "h" or "o")
      end
      CH.log("chest", b.key, tile.id, CH.tile_state(b, t))
      return CH.tile_state(b, t)
    end
    if not CH.done(b, t) then
      put(b, t, "o")
      CH.log("chest", b.key, tile.id)
    end
    return CH.tile_state(b, t)
  end

  --- True when double chest t can be opened now; answers the reward tiers that are ready.
  function CH.d_chest_ready(b, t)
    if not CH.open(b, t) or CH.d_chest_empty(b, t) then
      return false
    end
    local st, tile = CH.tile_state(b, t), b.tiles[t]
    if st == "o" then
      return false
    end
    local base, a, s = dchest_left(tile, st)
    if CH.s_ready(b, t) then
      return base or a or s
    end
    if CH.a_ready(b, t) then
      return base or a
    end
    return base
  end

  --- Which tier double chest t waits for: "a" or "s".
  function CH.d_chest_waits(b, t)
    local tile = b.tiles[t]
    local _, a = dchest_left(tile, CH.tile_state(b, t))
    return a and "a" or "s"
  end

  CH.ITEM_FITS = 765340069     -- (item, n) -> the bag has room
  CH.ITEM_NUM = VRFW.commands.GET_ITEM_NUM     -- (item, false) -> how many the player has
  CH.ITEM_ADD = VRFW.commands.ADD_ITEM_ONLY     -- (item, n): no window (the screen shows the retail one)
  CH.AUTO_SAVE = VRFW.commands.SYSTEM_AUTO_SAVE

  --- The rewards of tile t, of `tier` for a double chest.
  function CH.rewards(b, t, tier)
    local out = {}
    local tile = b.tiles[t]
    local enc = ""
    if tile ~= nil then
      if tier == true or tier == "s" then
        enc = tile.sreward or ""
      elseif tier == "a" then
        enc = tile.areward or ""
      else
        enc = tile.reward
      end
    end
    for part in string.gmatch(enc, "[^,]+") do
      local card = string.match(part, "^player:(%d+)$")
      local id, n = string.match(part, "^(%d+):(%d+)$")
      if card ~= nil then
        out[#out + 1] = {kind = "player", id = tonumber(card), count = 1}
      elseif id ~= nil then
        out[#out + 1] = {kind = "item", id = tonumber(id), count = math.max(1, tonumber(n) or 1)}
      else
        CH.log("reward not understood", b.key, tile.id, part)
      end
    end
    return out
  end

  local function paid_set(b)
    local s = VRFW.host.command(CH.SAVE_GET, CH.OWNER, "chain." .. b.key .. ".paid", "")
    local m = {}
    if type(s) == "string" then
      for id in string.gmatch(s, "[^;]+") do
        m[id] = true
      end
    end
    return m
  end

  --- Chest t's rewards already given in this save.
  function CH.paid(b, t)
    return paid_set(b)[b.tiles[t].id] == true
  end

  local function mark(tile, tier)
    return tier and (tile.id .. "+" .. tier) or tile.id
  end

  local function due(b, t, m)
    local tile, st = b.tiles[t], CH.tile_state(b, t)
    local out = {}
    if tile.kind == "chest" or tile.kind == "schest" then
      if tile.reward ~= "" and st == "o" and not m[tile.id] then
        out[#out + 1] = false
      end
    elseif tile.kind == "dchest" then
      if tile.reward ~= "" and (st == "h" or st == "a" or st == "o") and not m[mark(tile, false)] then
        out[#out + 1] = false
      end
      if (tile.areward or "") ~= "" and (st == "a" or st == "o") and not m[mark(tile, "a")] then
        out[#out + 1] = "a"
      end
      if (tile.sreward or "") ~= "" and st == "o" and not m[mark(tile, "s")] then
        out[#out + 1] = "s"
      end
    end
    return out
  end

  --- The opened chests of board b whose rewards were never given.
  function CH.unpaid(b)
    local out, m = {}, nil
    for t, tile in ipairs(b.tiles) do
      if (tile.kind == "chest" or tile.kind == "schest" or tile.kind == "dchest") and CH.tile_state(b, t) ~= "0" then
        m = m or paid_set(b)
        if #due(b, t, m) > 0 then
          out[#out + 1] = t
        end
      end
    end
    return out
  end

  local function hex(v) return VRFW.ids.hex_text(v) end

  -- Whether reward r can be given: "fits", "owned" (a one-copy item the player has: no later try can fit it) or "full".
  local function room_for(r)
    local ok, fits = pcall(funcLuaCommand, CH.ITEM_FITS, r.id, r.count)
    if not ok or fits ~= false then
      return "fits"
    end
    if r.kind ~= "item" then
      return "owned"  -- a crest or kit stacks to one
    end
    -- holding exactly one with no room for one more means the item's stack limit is one
    local one_copy = VRFW.host.command(CH.ITEM_FITS, r.id, 1) == false and VRFW.host.command(CH.ITEM_NUM, r.id, false) == 1 == 1
    return one_copy and "owned" or "full"
  end

  --- Give opened chest t's rewards once; answers the rewards given (nil, why when it waits) and how many were already owned.
  function CH.pay(b, t)
    local tile = b.tiles[t]
    if tile == nil or (tile.kind ~= "chest" and tile.kind ~= "schest" and tile.kind ~= "dchest") or CH.tile_state(b, t) == "0" then
      return nil, "closed"
    end
    local m = paid_set(b)
    local parts_due = due(b, t, m)
    if #parts_due == 0 then
      return {}
    end
    local rw, marks = {}, {}
    for _, tier in ipairs(parts_due) do
      for _, r in ipairs(CH.rewards(b, t, tier)) do
        rw[#rw + 1] = r
      end
      marks[#marks + 1] = mark(tile, tier)
    end
    if #rw == 0 then
      return {}
    end
    local owned, skipped = {}, 0
    for _, r in ipairs(rw) do
      if r.kind == "item" then
        local room = room_for(r)
        if room == "full" then
          CH.log("chest reward waits: bag full", b.key, tile.id, hex(r.id), "x", r.count)
          return nil, "full"
        end
        owned[r] = room == "owned"
      end
    end
    -- a player who cannot join yet keeps the whole chest pending: unmarked, CH.unpaid delivers it later
    local joining = 0
    for _, r in ipairs(rw) do
      if r.kind == "player" then
        local ok, why = nil, "no recruit service"
        if VRFW.recruit ~= nil then
          ok, why = VRFW.recruit.can_sign(r.id)
        end
        if ok then
          joining = joining + 1
        elseif why ~= "owned" then
          CH.log("chest reward waits: player", b.key, tile.id, hex(r.id), tostring(why))
          return nil, why
        end
      end
    end
    if joining > 0 and (VRFW.recruit.bank_room() or joining) < joining then
      CH.log("chest reward waits: bank room", b.key, tile.id, "players", joining)
      return nil, "bank_full"
    end
    local given, parts = {}, {}
    for _, r in ipairs(rw) do  -- players first: a signing that fails leaves nothing paid
      if r.kind == "player" then
        local hdl, why = VRFW.recruit.sign(r.id, 1)
        if hdl ~= nil then
          given[#given + 1] = r
          parts[#parts + 1] = "player " .. hex(r.id)
        elseif why == "owned" then
          parts[#parts + 1] = "player " .. hex(r.id) .. " already owned"
          skipped = skipped + 1
        else
          CH.log("chest reward waits: signing failed", b.key, tile.id, hex(r.id), tostring(why))
          return nil, why
        end
      end
    end
    for _, r in ipairs(rw) do
      if r.kind == "item" and owned[r] then
        parts[#parts + 1] = "item " .. hex(r.id) .. " already owned"
        skipped = skipped + 1
      elseif r.kind == "item" then
        pcall(funcLuaCommand, CH.ITEM_ADD, r.id, r.count)
        given[#given + 1] = r
        parts[#parts + 1] = "item " .. hex(r.id) .. " x" .. r.count
      end
    end
    for _, k in ipairs(marks) do
      m[k] = true
    end
    local ids = {}
    for id in pairs(m) do
      ids[#ids + 1] = id
    end
    table.sort(ids)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, "chain." .. b.key .. ".paid", table.concat(ids, ";"), 0)
    pcall(funcLuaCommand, CH.AUTO_SAVE)
    CH.log("chest paid", b.key, table.concat(marks, "/"), table.concat(parts, ", "))
    return given, nil, skipped
  end

  -- the Order of a rank Id (0 = not declared)
  local function order_of(id)
    return VRFW.match_rank ~= nil and VRFW.match_rank.order(id) or (({B = 1, A = 2, S = 3})[id] or 0)
  end

  --- The rank rewards of match tile t.
  function CH.rank_rewards(b, t)
    local tile = b.tiles[t]
    local out = {}
    if tile == nil or tile.kind ~= "match" then
      return out
    end
    local m = paid_set(b)
    local best = CH.rank(b, t)
    for _, r in ipairs(tile.rank_rewards or {}) do
      local o = order_of(r.rank)
      out[#out + 1] = {rank = r.rank, id = r.id, count = r.count, kind = r.kind, name = r.name, text = r.text or 0,
                       paid = m[tile.id .. "@" .. r.rank] == true, earned = o > 0 and best >= o}
    end
    return out
  end

  -- the rank rewards of tile t earned and not paid yet
  local function rank_due(b, t)
    local out = {}
    for _, r in ipairs(CH.rank_rewards(b, t)) do
      if r.earned and not r.paid then
        out[#out + 1] = r
      end
    end
    return out
  end

  --- The match tiles of board b with earned rank rewards never given (a full bag at the win).
  function CH.rank_unpaid(b)
    local out = {}
    for t, tile in ipairs(b.tiles) do
      if tile.kind == "match" and #(tile.rank_rewards or {}) > 0 and #rank_due(b, t) > 0 then
        out[#out + 1] = t
      end
    end
    return out
  end

  --- Give tile t's earned rank rewards once; answers the rewards given, or nil, "full".
  function CH.pay_rank(b, t, save)
    local tile = b.tiles[t]
    local due = rank_due(b, t)
    if #due == 0 then
      return {}
    end
    for _, r in ipairs(due) do
      local room = room_for(r)
      if room == "full" then
        CH.log("rank reward waits: bag full", b.key, tile.id, r.rank, hex(r.id), "x", r.count)
        return nil, "full"
      end
      r.already_owned = room == "owned"
    end
    local m = paid_set(b)
    local parts, news, given = {}, CH.news_text(b), {}
    for _, r in ipairs(due) do
      m[tile.id .. "@" .. r.rank] = true
      if r.already_owned then
        parts[#parts + 1] = r.rank .. " item " .. hex(r.id) .. " already owned"
      else
        pcall(funcLuaCommand, CH.ITEM_ADD, r.id, r.count)
        parts[#parts + 1] = r.rank .. " item " .. hex(r.id) .. " x" .. r.count
        news = news .. (news ~= "" and "," or "") .. string.format("%d:%d", r.id, r.count)
        given[#given + 1] = r
      end
    end
    local ids = {}
    for id in pairs(m) do
      ids[#ids + 1] = id
    end
    table.sort(ids)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, "chain." .. b.key .. ".paid", table.concat(ids, ";"), 0)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, "chain." .. b.key .. ".news", news, 0)
    if save then
      pcall(funcLuaCommand, CH.AUTO_SAVE)
    end
    CH.log("rank reward paid", b.key, tile.id, table.concat(parts, ", "))
    return given
  end

  --- The stored news text of board b; "" when there is none.
  function CH.news_text(b)
    local s = VRFW.host.command(CH.SAVE_GET, CH.OWNER, "chain." .. b.key .. ".news", "")
    return type(s) == "string" and s or ""
  end

  --- The news of board b as a list of {id, count}.
  function CH.news(b)
    local out = {}
    for id, n in string.gmatch(CH.news_text(b), "(%d+):(%d+)") do
      out[#out + 1] = {id = tonumber(id), count = tonumber(n)}
    end
    return out
  end

  --- Clears the news of board b.
  function CH.clear_news(b)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, "chain." .. b.key .. ".news", "", 0)
  end

  --- Every match tile won.
  function CH.complete(b)
    for t, tile in ipairs(b.tiles) do
      if tile.kind == "match" and CH.rank(b, t) == 0 then
        return false
      end
    end
    return b.matches > 0
  end

  --- The average rank Id of a complete board; nil while it is not complete.
  function CH.average(b)
    if not CH.complete(b) then
      return nil
    end
    local sum, n = 0, 0
    for t, tile in ipairs(b.tiles) do
      if tile.kind == "match" then
        sum, n = sum + CH.rank(b, t), n + 1
      end
    end
    if n == 0 or VRFW.match_rank == nil then
      return nil
    end
    return VRFW.match_rank.for_order(sum / n)
  end

  --- The number of won match tiles of a board.
  function CH.won(b)
    local n = 0
    for t, tile in ipairs(b.tiles) do
      if tile.kind == "match" and CH.rank(b, t) > 0 then
        n = n + 1
      end
    end
    return n
  end

  --- The boards of the chain hub whose node has save slot `slot`, in the hub's order (nil = not a hub).
  function CH.hub(slot)
    if type(slot) ~= "number" then
      return nil
    end
    CH.hubs = CH.hubs or {}
    if CH.hubs[slot] ~= nil then
      return CH.hubs[slot] or nil
    end
    CH.hubs[slot] = false
    local n = VRFW.host.command(CH.NODE.COUNT)
    for i = 0, (type(n) == "number" and n or 0) - 1 do
      local _, s, _, _, _, _, _, _, _, _, hub = VRFW.host.command(CH.NODE.GET, i)
      if s == slot and type(hub) == "string" and hub ~= "" then
        local list = {}
        for _, ci in ipairs(csv(hub)) do
          local b = CH.board(ci)
          if b ~= nil then
            list[#list + 1] = b
          end
        end
        if #list > 0 then
          CH.hubs[slot] = list
          CH.log("hub", slot, #list)
        end
        break
      end
    end
    return CH.hubs[slot] or nil
  end

  --- Every chain of a hub complete.
  function CH.hub_complete(boards)
    for _, b in ipairs(boards) do
      if not CH.complete(b) then
        return false
      end
    end
    return #boards > 0
  end

  --- The average rank Id of a complete hub; nil while it is not complete.
  function CH.hub_average(boards)
    if not CH.hub_complete(boards) or VRFW.match_rank == nil then
      return nil
    end
    local sum = 0
    for _, b in ipairs(boards) do
      local id = CH.average(b)
      local o = id ~= nil and VRFW.match_rank.order(id) or 0
      sum = sum + (o > 0 and o or 1)
    end
    return VRFW.match_rank.for_order(sum / #boards)
  end

  --- Stores the board tile and slot of the match about to start.
  function CH.set_pending(b, t, slot)
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, CH.PENDING, b.key .. "|" .. tostring(t) .. "|" .. tostring(slot or -1), 0)
  end

  --- Chain key, tile, opener's slot of the match started from a board (nil = none).
  function CH.pending()
    local s = VRFW.host.command(CH.SAVE_GET, CH.OWNER, CH.PENDING, "")
    if type(s) ~= "string" or s == "" then
      return nil
    end
    local k, t, slot = string.match(s, "^(.*)|(%d+)|(%-?%d+)$")
    if k == nil then
      return nil
    end
    return k, tonumber(t), tonumber(slot)
  end

  --- Clears the stored pending match.
  function CH.clear_pending()
    pcall(funcLuaCommand, CH.SAVE_SET, CH.OWNER, CH.PENDING, "", 0)
  end

  --- The board table of chain key `key` (nil = none).
  function CH.by_key(key)
    local n = VRFW.host.command(CH.CMD.COUNT)
    if type(n) ~= "number" then
      return nil
    end
    for i = 0, n - 1 do
      local k = VRFW.host.command(CH.CMD.GET, i)
      if k == key then
        return CH.board(i)
      end
    end
    return nil
  end

  --- The wins against `team`.
  function CH.team_wins(team)
    if stats() ~= nil then
      return VRFW.stats.wins_against(team)
    end
    local n = 0
    for _, b in pairs(CH.boards) do
      if b then
        for t, tile in ipairs(b.tiles) do
          if tile.kind == "match" and tile.team == team and CH.done(b, t) then
            n = n + 1
          end
        end
      end
    end
    return n
  end

  --- The wins against tile t's team; 0 when t is no match.
  function CH.wins_against(b, t)
    local tile = b.tiles[t]
    if tile == nil or tile.kind ~= "match" then
      return 0
    end
    if stats() ~= nil then
      return VRFW.stats.wins_against(tile.team)
    end
    return CH.done(b, t) and 1 or 0
  end
end
