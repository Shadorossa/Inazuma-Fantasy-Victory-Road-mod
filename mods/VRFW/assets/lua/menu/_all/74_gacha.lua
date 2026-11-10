-- VRFW gacha service, game Lua side (every menu VM; script side scripts\gacha.lua; docs/framework/gacha.md).
if VRFW.gacha == nil then
  local G = {
    C = {
      OF_PIECE = VRFW.commands.VRFW_GACHA_OF_PIECE,         -- CMND_VRFW_GACHA_OF_PIECE (pieceId) -> pool index, 0 = none
      POOL = VRFW.commands.VRFW_GACHA_POOL,
                                     -- free stock (0 = no free gacha)
      CARDS = VRFW.commands.VRFW_GACHA_CARDS,             -- CMND_VRFW_GACHA_CARDS (index) -> card, …
      CANDIDATES = VRFW.commands.VRFW_GACHA_CANDIDATES,
      TEXTS = VRFW.commands.VRFW_GACHA_TEXTS,
                                     -- count text id
      DRAWS = VRFW.commands.VRFW_GACHA_DRAWS,
      OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT,         -- CMND_OPEN_MENU_OBJECT (menu)
      MENU_EXISTS = 2231168902,      -- (menu) -> true while that menu object exists
      EXCLUDE_OWNED = VRFW.commands.VRFW_DROP_LIST_EXCLUDE_OWNED,    -- CMND_VRFW_DROP_LIST_EXCLUDE_OWNED (1 | 0)
      PIECE_INFO = 126049514,
      TEXT_GET = VRFW.commands.TEXT_GET,         -- CMND_TEXT_GET (text id) -> text
      WIN_TEXT = 2289627655,         -- the general window's text (text, 0, 0, 0, 0, 0, false)
      WIN_BUTTONS = 2351835063,      -- its buttons (1 = OK, 0)
      WIN_SOUNDS = 528596549,        -- its decide / cancel sounds
      WIN_CLOSED = 682363669,        -- -> true once an OK window closed
    },
    SOUND_DECIDE = 3848881948,       -- sy0000
    SOUND_CANCEL = 202039849,        -- sy0006
    TEXT_EMPTY = 1753758030,         -- vrfw_gacha_pool_empty (text\rows\gacha.toml)
    TEXT_NO_COST = 1005605398,       -- vrfw_gacha_no_cost (a pool without its own no_cost_text)
    TEXT_OBTAINED = 3030942955,      -- vrfw_gacha_obtained (%s = the player's name)
    TEXT_FEWER = 426217837,          -- vrfw_gacha_fewer_left (%d = the players signed)
    CHARA_OF_CARD = 347353059,       -- (card) -> its character
    CHARA_NAME = 523676951,          -- (character) -> its name
    pieces = nil,                    -- board piece save slot -> pool index (built on first use)
    MENU = "vs_route_town_command_select_menu",
    RESULT_MENU = 2721949403,
    RESULT_COUNT = 1872993680,       -- its parameter: how many cards
    RESULT_FRAME_NORMAL = 0,         -- cpr_pack_rarity_type_<i>: the normal frame and effect
    pools = {},                      -- pool index -> its answer (cached)
  }
  VRFW.gacha = G

  --- Logs through the gacha tag.
  function G.log(...)
    if PRINT ~= nil then
      pcall(PRINT, "VRFW.gacha", ...)
    end
  end

  --- Pool i as a table (cached); nil when there is none.
  function G.pool(i)
    if G.pools[i] == nil then
      local key, cost_item, cost_count, level, n, free = VRFW.host.command(G.C.POOL, i)
      if key == nil then
        return nil
      end
      G.pools[i] = {index = i, key = key, cost_item = cost_item or 0, cost_count = cost_count or 0, level = level or 1,
                    n = n or 0, free = free or 0, cards = table.pack(VRFW.host.command(G.C.CARDS, i)), draws = {}}
      local rows = table.pack(VRFW.host.command(G.C.DRAWS, i))
      for k = 1, (rows.n or 0) - 1, 2 do
        if type(rows[k]) == "number" then
          G.pools[i].draws[#G.pools[i].draws + 1] = {count = rows[k], text = rows[k + 1] or 0}
        end
      end
    end
    return G.pools[i]
  end

  --- Board piece index -> pool index (0 = none): the piece's save slot -> its route node (route_nodes' VRFW.route_nodes.load).
  function G.of_piece_index(idx)
    if idx == nil or idx < 0 or (VRFW.route_nodes == nil or VRFW.route_nodes.load == nil) then
      return 0
    end
    if G.pieces == nil then
      G.pieces = {}
      for _, node in ipairs(VRFW.route_nodes.load().nodes or {}) do
        local p = VRFW.host.command(G.C.OF_PIECE, node.piece)
        if type(p) == "number" and p > 0 then
          G.pieces[node.slot] = p
          G.log("node slot", node.slot, "pool", p)
        end
      end
    end
    local ok, sfi = VRFW.host.command(G.C.PIECE_INFO, idx, 6)
    if not ok then
      return 0
    end
    return G.pieces[sfi] or 0
  end

  --- True when board piece idx opens a gacha pool.
  function G.is_piece(idx)
    return G.of_piece_index(idx) > 0
  end

  --- The pool of a save slot (the command menu knows the piece's slot: VRFW.route_board_commands.L.n2), 0 = none.
  function G.of_slot(slot)
    if G.pieces == nil then
      G.of_piece_index(-1)
    end
    if G.pieces == nil and (VRFW.route_nodes ~= nil and VRFW.route_nodes.load ~= nil) then
      G.pieces = {}
      for _, node in ipairs(VRFW.route_nodes.load().nodes or {}) do
        local p = VRFW.host.command(G.C.OF_PIECE, node.piece)
        if type(p) == "number" and p > 0 then
          G.pieces[node.slot] = p
        end
      end
    end
    return (G.pieces or {})[slot] or 0
  end

  --- The free gacha: the pool's cost item topped up to its free stock (the bag's room permitting; at least one draw's cost).
  function G.refill(pool)
    if pool == nil or (pool.free or 0) <= 0 or pool.cost_item == 0 or VRFW.recruit == nil then
      return
    end
    local have = VRFW.recruit.items(pool.cost_item)
    if have >= pool.free then
      return
    end
    if not VRFW.recruit.give(pool.cost_item, pool.free - have) and have < pool.cost_count then
      VRFW.recruit.give(pool.cost_item, pool.cost_count - have)
    end
    G.log("free gacha: pool", pool.key, "cost item", have, "->", VRFW.recruit.items(pool.cost_item))
  end

  --- The node menu of a piece's slot; nil when there is no pool.
  function G.node_menu(slot)
    local p = G.of_slot(slot)
    local pool = p > 0 and G.pool(p) or nil
    if pool == nil then
      return nil
    end
    local _, banner, _, count_text = VRFW.host.command(G.C.TEXTS, p)
    local rows = {}
    for k, draw in ipairs(pool.draws) do
      rows[#rows + 1] = {index = k, text = draw.text, arg = draw.count * pool.cost_count, count = draw.count}
    end
    local refill = type(count_text) == "number" and count_text ~= 0 and pool.cost_item ~= 0
    return {key = pool.key, banner = type(banner) == "number" and banner or 0, rows = rows,
            setup = refill and function() G.refill(pool) end or nil,
            run = function(row, idx)
              local got, why = G.run(pool, row.count)
              G.log("piece", idx, "pool", pool.key, "got", type(got) == "table" and #got or got or 0, why or "")
              return true
            end}
  end

  VRFW.node_menu_providers = VRFW.node_menu_providers or {}
  table.insert(VRFW.node_menu_providers, {id = "VRFW.gacha", of_slot = G.node_menu})

  -- The command menu closes: the drop-rate list's owned-player rule is never left on.
  local function menu_final()
    VRFW.host.command(G.C.EXCLUDE_OWNED, 0)
  end

  if VRFW.host ~= nil then
    VRFW.host.on(G.MENU, "FinalizeMenu", {id = "VRFW.gacha_final", phase = "after", fn = menu_final})
  end

  local function text(id)
    local s = VRFW.host.command(G.C.TEXT_GET, id)
    return type(s) == "string" and s or ""
  end

  --- The game's OK window with a text (a text id or a string); waits until it is closed.
  function G.window(id)
    VRFW.host.command(G.C.WIN_TEXT, type(id) == "string" and id or text(id), 0, 0, 0, 0, 0, false)
    VRFW.host.command(G.C.WIN_BUTTONS, 1, 0)
    VRFW.host.command(G.C.WIN_SOUNDS, G.SOUND_DECIDE, G.SOUND_CANCEL)
    while VRFW.host.command(G.C.WIN_CLOSED) ~= true do
      coroutine.yield()
    end
  end

  --- The candidate cards of `pool`.
  function G.candidates(pool)
    local got = table.pack(VRFW.host.command(G.C.CANDIDATES, pool.index))
    local out = {}
    for k = 1, got.n or 0 do
      local c = got[k]
      if type(c) == "number" and c ~= 0 then
        out[#out + 1] = c
      end
    end
    return out
  end

  --- "You obtained <name>!" in the game's OK window.
  function G.obtained(card)
    local name = VRFW.host.command(G.CHARA_NAME, VRFW.host.command(G.CHARA_OF_CARD, card) or 0)
    local s = text(G.TEXT_OBTAINED)
    local ok, msg = pcall(string.format, s, type(name) == "string" and name or "")
    G.window(ok and msg or s)
  end

  --- Up to k cards of `list` at random, no two of one character: a walk of the list, at most one lookup per card.
  function G.pick_some(list, k)
    local rest, out, seen = {table.unpack(list)}, {}, {}
    for i = 1, #rest do
      local ok, j = pcall(math.random, i, #rest)
      if ok and type(j) == "number" then
        rest[i], rest[j] = rest[j], rest[i]
      end
      local chara = VRFW.host.command(G.CHARA_OF_CARD, rest[i]) or rest[i]
      if not seen[chara] then
        seen[chara] = true
        out[#out + 1] = rest[i]
        if #out >= k then
          break
        end
      end
    end
    return out
  end

  --- Shows the card screen for `cards`; answers true when it opened.
  function G.result_screen(cards)
    local rarities = {}
    for i, card in ipairs(cards) do
      rarities[i] = VRFW.recruit ~= nil and VRFW.recruit.card_rarity(card) or 0
    end
    local function each_key(fn)
      for i, card in ipairs(cards) do
        fn(CALC_CRC("cpr_chara_param_id_" .. i), card)
        fn(CALC_CRC("cpr_pack_rarity_type_" .. i), G.RESULT_FRAME_NORMAL)
        fn(CALC_CRC("cpr_pack_chara_rarity_" .. i), rarities[i])
      end
    end
    VRFW.param.replace(G.RESULT_COUNT, #cards)
    each_key(function(key, value) VRFW.param.replace(key, value) end)
    coroutine.yield()
    VRFW.host.command(G.C.OPEN_MENU, G.RESULT_MENU)
    coroutine.yield()
    local function exists()
      local there = VRFW.host.menu_command(G.C.MENU_EXISTS, G.RESULT_MENU)
      return there == true
    end
    local opened = exists()
    while exists() do
      coroutine.yield()
    end
    VRFW.param.clear(G.RESULT_COUNT)
    each_key(function(key) VRFW.param.clear(key) end)
    coroutine.yield()
    return opened
  end

  --- Who a draw obtained: the card screen, or one OK window per player if that screen did not open.
  function G.show_obtained(cards)
    if G.result_screen(cards) then
      return
    end
    for _, card in ipairs(cards) do
      G.obtained(card)
    end
  end

  --- Signs the picks of a draw; answers the signed list, or nil, why.
  function G.sign_picks(pool, picks, draws)
    local each = pool.cost_count > 0 and {item = pool.cost_item, count = pool.cost_count} or nil
    local signed, why = VRFW.recruit.recruit_list({params = picks, level = pool.level, price_each = each})
    if #signed == 0 then
      G.log("pool", pool.key, "nobody signed", why)
      return nil, "sign:" .. tostring(why)
    end
    G.log("pool", pool.key, "drew", #signed, "of", draws, why or "")
    if #signed < draws then
      local s = text(G.TEXT_FEWER)
      local ok, msg = pcall(string.format, s, #signed)
      G.window(ok and msg or s)
    end
    G.show_obtained(signed)
    return signed
  end

  --- Runs `draws` draws of a pool; answers the signed card(s), or nil, why.
  function G.run(pool, draws)
    draws = draws or 1
    G.refill(pool)
    local cands = G.candidates(pool)
    if #cands == 0 then
      G.window(G.TEXT_EMPTY)
      return nil, "empty"
    end
    local room = VRFW.recruit.bank_room()
    local picks = G.pick_some(cands, math.max(1, math.min(draws, room or draws)))
    local cost = pool.cost_count * #picks
    if cost > 0 and VRFW.recruit.items(pool.cost_item) < cost then
      local _, _, no_cost = VRFW.host.command(G.C.TEXTS, pool.index)
      G.window((type(no_cost) == "number" and no_cost ~= 0) and no_cost or G.TEXT_NO_COST)
      return nil, "cost"
    end
    local signed, why = G.sign_picks(pool, picks, draws)
    if signed ~= nil and draws == 1 then
      return signed[1]
    end
    return signed, why
  end
end
