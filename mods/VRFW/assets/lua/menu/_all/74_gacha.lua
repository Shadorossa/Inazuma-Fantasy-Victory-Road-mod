-- VRFW gacha service, game Lua side (every menu VM; script side scripts\gacha.lua; docs/framework/gacha.md).
-- A pool is a mod's [[VRFW.GachaPool]] (content\gacha\*.toml): its cards, its cost, its level, the Chronicle board node
-- that opens it. Only mechanism here; what is drawn is the declaring mods' data.
--   VRFW_Gacha.IsPiece(idx)      -> true when board piece index `idx` is a gacha node (the board's balloon hides its face)
--   VRFW_Gacha.AfterMenu(idx)    the board, right after the piece's command menu closed: when a command row (the pool's
--                                   `draws`) was picked, the draw runs (route_board's VRFW_RB_MenuClosed default)
-- The node's command menu (vs_route_town_command_select_menu, VRFW_Host handlers of this file): its rows are the pool's
-- command rows (route_board's VRFW_RBC_Rows default asks VRFW_Gacha.RowsFor). A row keeps the retail «MI EQUIPO»
-- row layout (the left label, the number on the right): the label is the row's text, the number how many of the cost
-- item the player has (the team level's place; its «team level» label hidden), every other text slot emptied
-- (VRFW_Gacha.SetupRow). The flavour window under the panel is hidden and the «MI EQUIPO» banner shows the pool's
-- `banner` picture alone (no team picture, no level label, no level number).
-- The free gacha (config [debug] free_gacha, debug flag `free_gacha`): the cost item is topped up to the pool's free
-- stock when the menu reads the count and before each draw (VRFW_Gacha.Refill). Picking the row closes the menu with the pool's request in the parameter store (no
-- retail result: the board goes back as after «back», then runs the draw). The X key keeps the retail drop-rate list of
-- the node's game: its spirit candidates are the pool (data of the declaring mod), the owned players left out
-- (vrfw_drop_list: CMND_VRFW_DROP_LIST_EXCLUDE_OWNED), the same list the draw picks from (CMND_VRFW_GACHA_CANDIDATES).
--   VRFW_Gacha.Run(pool, draws)  -> the drawn card (draws > 1: the list of cards), or nil + why ("empty", "cost",
--                                   "sign:<why>"): the draw, the cost taken, the signing (VRFW_Recruit), then the retail
--                                   card screen chara_pack_result_menu with the card(s), whatever their number.
--                                   Runs inside a coroutine
-- Log: "LUAPRINT … VRFW_GACHA …" (the picked row, the drawn card or why nothing was drawn).
if VRFW_Gacha == nil then
  local G = {
    C = {
      OF_PIECE = VRFW_Cmd.VRFW_GACHA_OF_PIECE,         -- CMND_VRFW_GACHA_OF_PIECE (pieceId) -> pool index, 0 = none
      POOL = VRFW_Cmd.VRFW_GACHA_POOL,             -- CMND_VRFW_GACHA_POOL (index) -> key, cost item, cost count, level, card count,
                                     -- free stock (0 = no free gacha)
      CARDS = VRFW_Cmd.VRFW_GACHA_CARDS,             -- CMND_VRFW_GACHA_CARDS (index) -> card, …
      CANDIDATES = VRFW_Cmd.VRFW_GACHA_CANDIDATES,       -- CMND_VRFW_GACHA_CANDIDATES (index) -> the cards a draw picks from now
      TEXTS = VRFW_Cmd.VRFW_GACHA_TEXTS,             -- CMND_VRFW_GACHA_TEXTS (index) -> command text id, banner image id, no-cost text id,
                                     -- count text id
      DRAWS = VRFW_Cmd.VRFW_GACHA_DRAWS,             -- CMND_VRFW_GACHA_DRAWS (index) -> players, text id, per command row
      OPEN_MENU = VRFW_Cmd.OPEN_MENU_OBJECT,         -- CMND_OPEN_MENU_OBJECT (menu)
      MENU_EXISTS = 2231168902,      -- (menu) -> true while that menu object exists
      EXCLUDE_OWNED = VRFW_Cmd.VRFW_DROP_LIST_EXCLUDE_OWNED,    -- CMND_VRFW_DROP_LIST_EXCLUDE_OWNED (1 | 0)
      CLOSE_MENU = VRFW_Cmd.CLOSE_MENU_OBJECT,        -- CMND_CLOSE_MENU_OBJECT
      SET_TEXT = VRFW_Cmd.SET_MENU_TEXT_STRING,         -- (layer, text node, string, instance)
      LOC_VISIBLE = 2158717427,      -- (layer, locator, on, instance)
      MESH_VISIBLE = VRFW_Cmd.SET_MESH_VISIBLE,     -- (layer, mesh, on, instance)
      LAYER_VISIBLE = VRFW_Cmd.SET_LAYER_VISIBLE,     -- (layer, instance, on)
      SET_TEX = 558735651,           -- (layer, atlas path, sprite, texture slot, 0, instance)
      PRIM_VISIBLE = 1233047821,     -- CMND_SET_PRIM_VISIBLE (layer, instance, number setting, on)
      PRIM_INDEX = 1927054058,       -- CMND_SEARCH_PRIM_INDEX (layer, 0, number setting) -> its index
      PRIM_VALUE = 3609943765,       -- (layer, instance, prim index, value): a number setting's value
      PIECE_INFO = 126049514,        -- (piece index, 6) -> ok, the piece's save slot (statusFlagIndex)
      TEXT_GET = VRFW_Cmd.TEXT_GET,         -- CMND_TEXT_GET (text id) -> text
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
    MENU_ID = 1193383590,            -- its menu object
    REQUEST = 1006738234,            -- crc32("vrfw_gacha_request"): the pool index whose command row was picked
    REQUEST_DRAWS = 2533590496,      -- crc32("vrfw_gacha_request_draws"): how many players that row draws
    RESULT_MENU = 2721949403,        -- chara_pack_result_menu: the retail card screen (fed by the parameter store)
    RESULT_COUNT = 1872993680,       -- its parameter: how many cards
    RESULT_FRAME_NORMAL = 0,         -- cpr_pack_rarity_type_<i>: the normal frame and effect
    ROW_ITEM = 0x56524741,           -- the command row's listItemType ("VRGA"): never a retail command
    SUB_LIST = 284009563,            -- vsroute01_16_sub_list (the command rows)
    BANNER = 1483086491,             -- vsroute01_17_myteam_banner
    INFO_WINDOW = 1303149463,        -- team02_04_info_window (the flavour text under the panel)
    BANNER_ATLAS = 1503831295,       -- crc32("#/menu/30_vsroute/vsroute01/vsroute01_17/<LG>/vsroute01_17.g4tx")
    BANNER_SLOT = 3668937361,        -- myteam_dmy01: the one-picture banner's texture slot
    BANNER_SHOW = {1711801685},      -- _myteam_dmy01_b (vsroute01_17.g4pkm)
    BANNER_HIDE = {447975417, 689040068, 13372060, 1546785142},   -- _gtxt_teamlevel01_b, _num_lv01_b, _num_lv_dmy01_b, _gtxt_myteam01
    BANNER_NUMBERS = {2269507340, 508346038},   -- the banner's team level numbers (_pos_team01_a / _b): a number setting
                                     -- ignores its locator's visibility, so it is hidden by itself
    ROW_TEXTS = {808187266, 3180095505},   -- _text_list_base01_on / _off: the centred label (emptied)
    ROW_LABELS = {580803180, 4197192385},  -- _text_list_base02_on / _off: the left label (the command)
    ROW_NUMBERS = {861327194, 1146224588}, -- the row's team level numbers (on / off): the cost item count
    ROW_LEVEL_LABELS = {165487784, 1712215830},   -- _gtxt_teamlevel01_on / _off: the «team level» label (hidden)
    ROW_ICONS = {1928480906, 3004512670},  -- _icon_list01_on / _off: the row's left icon (hidden)
    ROW_LEVEL = 3597743423,          -- _pos_team_lv01: the label and the numbers
    pools = {},                      -- pool index -> its answer (cached)
  }
  VRFW_Gacha = G

  local function call(cmd, ...)
    local r = table.pack(pcall(funcLuaCommand, cmd, ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
  end

  function G.Log(...)
    if PRINT ~= nil then
      pcall(PRINT, "VRFW_GACHA", ...)
    end
  end

  function G.Pool(i)
    if G.pools[i] == nil then
      local key, cost_item, cost_count, level, n, free = call(G.C.POOL, i)
      if key == nil then
        return nil
      end
      G.pools[i] = {index = i, key = key, cost_item = cost_item or 0, cost_count = cost_count or 0, level = level or 1,
                    n = n or 0, free = free or 0, cards = table.pack(call(G.C.CARDS, i)), draws = {}}
      local rows = table.pack(call(G.C.DRAWS, i))
      for k = 1, (rows.n or 0) - 1, 2 do
        if type(rows[k]) == "number" then
          G.pools[i].draws[#G.pools[i].draws + 1] = {count = rows[k], text = rows[k + 1] or 0}
        end
      end
    end
    return G.pools[i]
  end

  -- board piece index -> pool index (0 = none): the piece's save slot -> its route node (route_nodes' VRFW_RN_Load)
  function G.OfPieceIndex(idx)
    if idx == nil or idx < 0 or VRFW_RN_Load == nil then
      return 0
    end
    if G.pieces == nil then
      G.pieces = {}
      for _, node in ipairs(VRFW_RN_Load().nodes or {}) do
        local p = call(G.C.OF_PIECE, node.piece)
        if type(p) == "number" and p > 0 then
          G.pieces[node.slot] = p
          G.Log("node slot", node.slot, "pool", p)
        end
      end
    end
    local ok, sfi = call(G.C.PIECE_INFO, idx, 6)
    if not ok then
      return 0
    end
    return G.pieces[sfi] or 0
  end

  function G.IsPiece(idx)
    return G.OfPieceIndex(idx) > 0
  end

  -- the pool of a save slot (the command menu knows the piece's slot: VRFW_RBC.L.n2), 0 = none
  function G.OfSlot(slot)
    if G.pieces == nil then
      G.OfPieceIndex(-1)
    end
    if G.pieces == nil and VRFW_RN_Load ~= nil then
      G.pieces = {}
      for _, node in ipairs(VRFW_RN_Load().nodes or {}) do
        local p = call(G.C.OF_PIECE, node.piece)
        if type(p) == "number" and p > 0 then
          G.pieces[node.slot] = p
        end
      end
    end
    return (G.pieces or {})[slot] or 0
  end

  -- the command menu's rows of a gacha node (route_board's VRFW_RBC_Rows default): one row per entry of the pool's draws;
  -- nil = not a gacha node. Difficulty 1 (the node's game row) keeps the retail X key: the drop-rate list of that game.
  function G.RowsFor(slot, rows)
    local p = G.OfSlot(slot)
    if p <= 0 then
      return nil
    end
    local pool = G.Pool(p)
    local base = (type(rows) == "table" and rows[1]) or {}
    local out = {}
    for _, draw in ipairs(pool ~= nil and pool.draws or {}) do
      out[#out + 1] = {listItemType = G.ROW_ITEM, pattern = 0, text = draw.text, classTexture = 0, difficultyType = 1,
                       textureOn = 2928350469 --[[icon_list01_on]], textureOff = 3469663858 --[[icon_list01_off]],
                       textureDiffBase = 0, heroDropControlEnabled = false, base = base.listItemType}
    end
    return #out > 0 and out or nil
  end

  local function text_of(id)
    local s = call(G.C.TEXT_GET, id)
    return type(s) == "string" and s or ""
  end

  local function menu_pool()
    if VRFW_RBC == nil or VRFW_RBC.L == nil then
      return 0
    end
    local ok, slot = pcall(function() return VRFW_RBC.L.n2 end)
    if not ok then
      return 0
    end
    return G.OfSlot(slot)
  end

  -- the free gacha: the pool's cost item topped up to its free stock (the bag's room permitting; at least one draw's cost)
  function G.Refill(pool)
    if pool == nil or (pool.free or 0) <= 0 or pool.cost_item == 0 or VRFW_Recruit == nil then
      return
    end
    local have = VRFW_Recruit.Items(pool.cost_item)
    if have >= pool.free then
      return
    end
    if not VRFW_Recruit.Give(pool.cost_item, pool.free - have) and have < pool.cost_count then
      VRFW_Recruit.Give(pool.cost_item, pool.cost_count - have)
    end
    G.Log("free gacha: pool", pool.key, "cost item", have, "->", VRFW_Recruit.Items(pool.cost_item))
  end

  -- the row's number: how many of the pool's cost item the player has (nil = none shown: no cost or no count text)
  local function cost_count_shown(p)
    local _, _, _, count_text = call(G.C.TEXTS, p)
    local pool = G.Pool(p)
    if type(count_text) ~= "number" or count_text == 0 or pool == nil or pool.cost_item == 0 or VRFW_Recruit == nil then
      return nil
    end
    G.Refill(pool)
    return VRFW_Recruit.Items(pool.cost_item) or 0
  end

  -- a command row's text; %d in it = what the row costs
  local function row_label(pool, draw)
    local s = text_of(draw.text)
    local ok, label = pcall(string.format, s, draw.count * pool.cost_count)
    return ok and label or s
  end

  -- a gacha's command row in the retail row layout: the centred label = the row's text («x1 - 5» + the star icon), the left
  -- label emptied, the left icon, the «team level» label and its number hidden: every slot set or hidden
  function G.SetupRow(layer, inst, p)
    local pool = G.Pool(p)
    local draw = pool ~= nil and pool.draws[inst + 1] or nil
    if draw == nil then
      return
    end
    local label = row_label(pool, draw)
    for _, node in ipairs(G.ROW_LABELS) do
      pcall(funcLuaMenuCommand, G.C.SET_TEXT, layer, node, "", inst)
    end
    for _, node in ipairs(G.ROW_TEXTS) do
      pcall(funcLuaMenuCommand, G.C.SET_TEXT, layer, node, label, inst)
    end
    for _, mesh in ipairs(G.ROW_LEVEL_LABELS) do
      pcall(funcLuaMenuCommand, G.C.MESH_VISIBLE, layer, mesh, false, inst)
    end
    for _, mesh in ipairs(G.ROW_ICONS) do
      pcall(funcLuaMenuCommand, G.C.MESH_VISIBLE, layer, mesh, false, inst)
    end
    cost_count_shown(p)   -- the free stock refill only: no number is drawn on the row
    pcall(funcLuaMenuCommand, G.C.LOC_VISIBLE, layer, G.ROW_LEVEL, false, inst)
    for _, number in ipairs(G.ROW_NUMBERS) do
      pcall(funcLuaMenuCommand, G.C.PRIM_VISIBLE, layer, inst, number, false)
    end
  end

  -- the command menu: the row (G.SetupRow), the flavour window hidden
  local function menu_setup(r, layer, inst)
    local p = menu_pool()
    if p <= 0 then
      return
    end
    if layer == G.SUB_LIST then
      G.SetupRow(layer, inst, p)
    elseif layer == G.INFO_WINDOW then
      pcall(funcLuaMenuCommand, G.C.LAYER_VISIBLE, layer, inst, false)
    end
  end

  -- the banner: the one-picture style (_pos_team01_b) with the pool's picture alone: no level label or number, no «MI EQUIPO»
  local function menu_open(r, layer, inst)
    local p = menu_pool()
    if p <= 0 then
      return
    end
    if layer == G.INFO_WINDOW then
      pcall(funcLuaMenuCommand, G.C.LAYER_VISIBLE, layer, inst, false)
      return
    end
    if layer ~= G.BANNER then
      return
    end
    local _, banner = call(G.C.TEXTS, p)
    if type(banner) ~= "number" or banner == 0 then
      return
    end
    pcall(funcLuaMenuCommand, G.C.LOC_VISIBLE, layer, 4160160648 --[[_pos_team01_a]], false, inst)
    pcall(funcLuaMenuCommand, G.C.LOC_VISIBLE, layer, 1862160946 --[[_pos_team01_b]], true, inst)
    pcall(funcLuaMenuCommand, G.C.SET_TEX, layer, G.BANNER_ATLAS, banner, G.BANNER_SLOT, 0, inst)
    for _, m in ipairs(G.BANNER_SHOW) do
      pcall(funcLuaMenuCommand, G.C.MESH_VISIBLE, layer, m, true, inst)
    end
    for _, m in ipairs(G.BANNER_HIDE) do
      pcall(funcLuaMenuCommand, G.C.MESH_VISIBLE, layer, m, false, inst)
    end
    for _, number in ipairs(G.BANNER_NUMBERS) do
      pcall(funcLuaMenuCommand, G.C.PRIM_VISIBLE, layer, inst, number, false)
    end
  end

  -- picking the command row: the request in the parameter store, the menu closed with no retail result
  local function menu_decide(nxt, layer, inst, ...)
    if layer == G.SUB_LIST and menu_pool() > 0 then
      local p = menu_pool()
      local pool = G.Pool(p)
      local draw = pool ~= nil and pool.draws[inst + 1] or nil
      VRFW_Param.Replace(G.REQUEST, p)
      VRFW_Param.Replace(G.REQUEST_DRAWS, draw ~= nil and draw.count or 1)
      call(G.C.CLOSE_MENU, G.MENU_ID)
      G.Log("command row picked: pool", p, "row", inst)
      return
    end
    return nxt(layer, inst, ...)
  end

  -- the command menu closes: the drop-rate list's owned-player rule is never left on
  local function menu_final()
    call(G.C.EXCLUDE_OWNED, 0)
  end

  if VRFW_Host ~= nil then
    VRFW_Host.on(G.MENU, "OnSetupLayer", {id = "VRFW.gacha_rows", phase = "after", fn = menu_setup})
    VRFW_Host.on(G.MENU, "OnOpenLayer", {id = "VRFW.gacha_banner", phase = "after", fn = menu_open})
    VRFW_Host.on(G.MENU, "OnDecideFocus", {id = "VRFW.gacha_command", phase = "around", fn = menu_decide})
    VRFW_Host.on(G.MENU, "FinalizeMenu", {id = "VRFW.gacha_final", phase = "after", fn = menu_final})
  end

  -- the board, the command menu just closed (route_board's VRFW_RB_MenuClosed default): a picked command row runs the
  -- draw (the cost, the draw, the signing, the «obtained» window); the board then goes back as after «back» (no retail
  -- result was written)
  function G.AfterMenu(idx)
    if not VRFW_Param.Has(G.REQUEST) then
      return false
    end
    local p = VRFW_Param.Take(G.REQUEST) or 0
    local draws = VRFW_Param.Take(G.REQUEST_DRAWS) or 1
    local pool = G.Pool(p)
    if pool == nil then
      G.Log("piece", idx, "pool", p, "not served")
      return false
    end
    local got, why = G.Run(pool, draws)
    G.Log("piece", idx, "pool", pool.key, "got", type(got) == "table" and #got or got or 0, why or "")
    return true
  end

  local function text(id)
    local s = call(G.C.TEXT_GET, id)
    return type(s) == "string" and s or ""
  end

  -- the game's OK window with a text (a text id or a string); waits until it is closed
  function G.Window(id)
    call(G.C.WIN_TEXT, type(id) == "string" and id or text(id), 0, 0, 0, 0, 0, false)
    call(G.C.WIN_BUTTONS, 1, 0)
    call(G.C.WIN_SOUNDS, G.SOUND_DECIDE, G.SOUND_CANCEL)
    while call(G.C.WIN_CLOSED) ~= true do
      coroutine.yield()
    end
  end

  -- the cards a draw picks from now: the pool's cards whose character has no player in the club (the script side's
  -- CMND_VRFW_GACHA_CANDIDATES: the drop-rate list's owned-player rule, so the window lists exactly these)
  function G.Candidates(pool)
    local got = table.pack(call(G.C.CANDIDATES, pool.index))
    local out = {}
    for k = 1, got.n or 0 do
      local c = got[k]
      if type(c) == "number" and c ~= 0 then
        out[#out + 1] = c
      end
    end
    return out
  end

  -- «You obtained <name>!» in the game's OK window
  function G.Obtained(card)
    local name = call(G.CHARA_NAME, call(G.CHARA_OF_CARD, card) or 0)
    local s = text(G.TEXT_OBTAINED)
    local ok, msg = pcall(string.format, s, type(name) == "string" and name or "")
    G.Window(ok and msg or s)
  end

  -- up to k cards of `list` at random, no two of one character: a walk of the list, at most one lookup per card
  function G.PickSome(list, k)
    local rest, out, seen = {table.unpack(list)}, {}, {}
    for i = 1, #rest do
      local ok, j = pcall(math.random, i, #rest)
      if ok and type(j) == "number" then
        rest[i], rest[j] = rest[j], rest[i]
      end
      local chara = call(G.CHARA_OF_CARD, rest[i]) or rest[i]
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

  -- the retail card screen with `cards` (the parameter store, as the retail Players Universe feeds it); waits until the
  -- screen closes itself. False = the screen did not open.
  function G.ResultScreen(cards)
    local rarities = {}
    for i, card in ipairs(cards) do
      rarities[i] = VRFW_Recruit ~= nil and VRFW_Recruit.CardRarity(card) or 0
    end
    local function each_key(fn)
      for i, card in ipairs(cards) do
        fn(CALC_CRC("cpr_chara_param_id_" .. i), card)
        fn(CALC_CRC("cpr_pack_rarity_type_" .. i), G.RESULT_FRAME_NORMAL)
        fn(CALC_CRC("cpr_pack_chara_rarity_" .. i), rarities[i])
      end
    end
    VRFW_Param.Replace(G.RESULT_COUNT, #cards)
    each_key(function(key, value) VRFW_Param.Replace(key, value) end)
    coroutine.yield()
    call(G.C.OPEN_MENU, G.RESULT_MENU)
    coroutine.yield()
    local function exists()
      local ok, there = pcall(funcLuaMenuCommand, G.C.MENU_EXISTS, G.RESULT_MENU)
      return ok and there == true
    end
    local opened = exists()
    while exists() do
      coroutine.yield()
    end
    VRFW_Param.Clear(G.RESULT_COUNT)
    each_key(function(key) VRFW_Param.Clear(key) end)
    coroutine.yield()
    return opened
  end

  -- who a draw obtained: the card screen, or one OK window per player if that screen did not open
  function G.ShowObtained(cards)
    if G.ResultScreen(cards) then
      return
    end
    for _, card in ipairs(cards) do
      G.Obtained(card)
    end
  end

  -- the signing of a draw: `picks` is already determined; one charge for what is signed, signed and saved before
  -- anything is shown, so leaving during the result screen loses nothing
  function G.SignPicks(pool, picks, draws)
    local each = pool.cost_count > 0 and {item = pool.cost_item, count = pool.cost_count} or nil
    local signed, why = VRFW_Recruit.RecruitList({params = picks, level = pool.level, price_each = each})
    if #signed == 0 then
      G.Log("pool", pool.key, "nobody signed", why)
      return nil, "sign:" .. tostring(why)
    end
    G.Log("pool", pool.key, "drew", #signed, "of", draws, why or "")
    if #signed < draws then
      local s = text(G.TEXT_FEWER)
      local ok, msg = pcall(string.format, s, #signed)
      G.Window(ok and msg or s)
    end
    G.ShowObtained(signed)
    return signed
  end

  -- the whole draw: the card(s) drawn among the candidates, the cost checked and taken, signed, who was obtained
  function G.Run(pool, draws)
    draws = draws or 1
    G.Refill(pool)
    local cands = G.Candidates(pool)
    if #cands == 0 then
      G.Window(G.TEXT_EMPTY)
      return nil, "empty"
    end
    local room = VRFW_Recruit.BankRoom()
    local picks = G.PickSome(cands, math.max(1, math.min(draws, room or draws)))
    local cost = pool.cost_count * #picks
    if cost > 0 and VRFW_Recruit.Items(pool.cost_item) < cost then
      local _, _, no_cost = call(G.C.TEXTS, pool.index)
      G.Window((type(no_cost) == "number" and no_cost ~= 0) and no_cost or G.TEXT_NO_COST)
      return nil, "cost"
    end
    local signed, why = G.SignPicks(pool, picks, draws)
    if signed ~= nil and draws == 1 then
      return signed[1]
    end
    return signed, why
  end
end
