-- BetterQoL, player plate («Ficha», personal_plate_menu): while the «Álbum de jugadores» page shows the plate on its
-- right half (assets\lua\screens\util_album_menu.lua, a card in the plate's players-universe mode) the plate leaves out
-- the pages that have nothing to show for a card: the sixth sense (vrfw.SixthSense), the team passives
-- (vrfw.TeamPassives) and TRAYECTORIA (BetterQoL.Career). The page dots and the page keys skip them
-- (VRFW_PlayerPages.ShowWhen, docs/framework/player-pages.md; a page no active mod adds is never drawn), unless a mod
-- keeps one for the shown card (BetterQoL.AlbumKeepPages: Signature Passives keeps the sixth sense page of a player
-- with a signature passive, whose card that page shows). The page is
-- recognised by its parameter BetterQoL.album_plate of the game's parameter store (set while it shows the plate).
-- Elsewhere the pages stay. Conditions only; no engine call at load time.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.AlbumPages == nil and VRFW_PlayerPages ~= nil and type(VRFW_PlayerPages.ShowWhen) == "function" then
  local A = {
    FLAG = 2398708549,                     -- crc32 of BetterQoL.album_plate (the album page's parameter)
    ALBUM = 2755094502,                    -- util_album_menu
    CROSS_CALL = 830228314,                -- (menu, global function, ...)
    PAGES = {"vrfw.SixthSense", "vrfw.TeamPassives", "BetterQoL.Career"},
  }
  BetterQoL.AlbumPages = A

  -- false while the album page shows the plate
  function A.Shown()
    return not VRFW_Param.Has(A.FLAG)
  end

  -- another mod keeps one of those pages on the album's plate while it has something to show for the plate's card:
  -- BetterQoL.AlbumKeepPages[<page name>] = function() return <bool> end (asked at run time, so the load order of the
  -- mods does not matter; an error counts as no)
  BetterQoL.AlbumKeepPages = BetterQoL.AlbumKeepPages or {}

  function A.Kept(name)
    local keep = BetterQoL.AlbumKeepPages[name]
    if type(keep) ~= "function" then
      return false
    end
    local ok, v = pcall(keep)
    return ok and v == true
  end

  for _, name in ipairs(A.PAGES) do
    VRFW_PlayerPages.ShowWhen(name, function()
      return A.Shown() or A.Kept(name)
    end)
  end

  -- the page a step lands on, told to the album page (its «No lo tienes» badge shows only on the first page)
  local step = VRFW_PlayerPages.Step
  if type(step) == "function" then
    VRFW_PlayerPages.Step = function(cur, dir, count)
      local nxt = step(cur, dir, count)
      if not A.Shown() then
        local o = VRFW_PlayerPages.Order(count)
        pcall(funcLuaCommand, A.CROSS_CALL, A.ALBUM, "BetterQoL_AlbumPlateFirstPage", o[1] == nil or o[1] == nxt)
      end
      return nxt
    end
  end
end

-- The plate's 3D model (Character Reforged's plate model, EVT_PPM) is built on its normal menu-camera layer here, as on
-- every other player page: the album page draws its background in the background pass (util_alb_backdrop) and the
-- opener hides the Caseta's normal-pass background meanwhile, so the model is drawn over the page's background and
-- under its 2D layers, the way the transfer office shows its model over shop01_00_background.

-- The album's plate shows its card at the album level (Nv200), so every move of the card is learned. On the album's
-- plate only, each move row is drawn as the game draws it for a player at level 1: a move whose learn level is above
-- 1 keeps its row and shows the retail padlock and «Nv. N» (that level) instead of the move; no row is ever left out.
-- The level is the framework's effective one (CMND_VRFW_CHARACTER_LEARN_LEVEL: chara_param as the game and the mods
-- serve it), else the game's learn table of the card. The row fill (SetupPersonalPlateCharaSkillItem) draws the
-- padlock for a move missing at its row whose learn table level is above the card's level (character status 0), so
-- for that row's fill only the move read answers no move, the learn table answers that move and its level, and the
-- card's level reads as the shown level. A row the card holds no move on (its moves above level 1) takes the learn
-- table's move at that list position, as the retail fill reads it (L.RowMove), so it is padlocked too. The card, its
-- level and the save are untouched. L.LockedLevel is the one
-- lock decision. The handler is the innermost around handler, so it sees the move another mod's handler (Character
-- Reforged's skill table) shows on that row. Runs on the plate's own row fill; no engine call at load.
if BetterQoL.AlbumLearnLocks == nil and VRFW_Host ~= nil and type(VRFW_Host.on) == "function" then
  local L = {
    GET_SKILL = 903078840,              -- (charaStHdl, list position 0..5) -> move
    LEARNABLE = 3475351727,             -- (charaStHdl) -> ok, {move per slot}, {learn level per slot}
    LEARN_LEVEL = VRFW_Cmd ~= nil and VRFW_Cmd.VRFW_CHARACTER_LEARN_LEVEL or 3184046342,   -- (charaStHdl, move) -> need, level
    CHARACTER_STATUS = 1131797651,      -- (charaStHdl, field) -> value; the row fill reads the level at field 0
    STATUS_LEVEL = 0,
    ROWS = 6,
    SHOWN_LEVEL = 1,                    -- the rows are drawn as for a player at this level
  }
  BetterQoL.AlbumLearnLocks = L

  local function U32(v)
    v = tonumber(v) or 0
    if v < 0 then
      v = v + 4294967296
    end
    return v
  end

  -- the level card `hdl` learns `move` at (0 = no learn level), from the framework, else the game's learn table
  function L.Need(call, hdl, move)
    local ok, need = pcall(call, L.LEARN_LEVEL, hdl, move)
    if ok and type(need) == "number" and need >= 0 then
      return need
    end
    local okT, found, moves, levels = pcall(call, L.LEARNABLE, hdl)
    if okT and found == true and type(moves) == "table" and type(levels) == "table" then
      for i, id in pairs(moves) do
        if U32(id) == move then
          return tonumber(levels[i]) or 0
        end
      end
    end
    return 0
  end

  -- the lock decision: the learn level row `move` of card `hdl` is padlocked with, 0 = drawn as it is. Only the
  -- album's plate locks (the album page sets its parameter while it shows the plate); every other plate keeps its rows.
  function L.LockedLevel(call, hdl, move)
    local album = BetterQoL.AlbumPages
    if album == nil or album.Shown() or move == 0 then
      return 0
    end
    local need = L.Need(call, hdl, move)
    return need > L.SHOWN_LEVEL and need or 0
  end

  -- the move of row `slot`: the card's move read, else the learn table's move at that list position (the one the
  -- retail row fill reads when the card has no move there: a players-universe card holds only its level-1 moves)
  function L.RowMove(call, hdl, slot)
    local okM, id = pcall(call, L.GET_SKILL, hdl, slot)
    local move = okM and U32(id) or 0
    if move ~= 0 then
      return move
    end
    local okT, found, moves = pcall(call, L.LEARNABLE, hdl)
    if okT and found == true and type(moves) == "table" and slot < #moves then
      return U32(moves[slot + 1])
    end
    return 0
  end

  VRFW_Host.on("personal_plate_menu", "SetupPersonalPlateCharaSkillItem", {
    id = "BetterQoL.album_learn_locks", phase = "around", priority = 2000000,
    fn = function(nxt, hdl, slot, ...)
      if type(hdl) ~= "number" or hdl == 0 or type(slot) ~= "number" or slot < 0 or slot >= L.ROWS
          or type(funcLuaCommand) ~= "function" then
        return nxt(hdl, slot, ...)
      end
      local album = BetterQoL.AlbumPages
      if album == nil or album.Shown() then
        return nxt(hdl, slot, ...)
      end
      local call = funcLuaCommand
      local move = L.RowMove(call, hdl, slot)
      local need = L.LockedLevel(call, hdl, move)
      if need == 0 then
        return nxt(hdl, slot, ...)
      end
      local moves, levels = {}, {}
      for i = 1, L.ROWS do
        moves[i], levels[i] = 0, 0
      end
      moves[slot + 1], levels[slot + 1] = move, need
      funcLuaCommand = function(...)
        local cmd, a, b = ...
        if a == hdl then
          if cmd == L.GET_SKILL and b == slot then
            return 0
          end
          if cmd == L.LEARNABLE then
            return true, moves, levels
          end
          if cmd == L.CHARACTER_STATUS and b == L.STATUS_LEVEL then
            return L.SHOWN_LEVEL
          end
        end
        return call(...)
      end
      local r = table.pack(pcall(nxt, hdl, slot, ...))
      funcLuaCommand = call
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })
end

-- The album's plate, «Hipertécnica» page (Character Reforged's graft plate_hiper_plate: EVT_PH_AuraOf / EVT_PH_MixOf):
-- the album's card is a players-universe card, not a saved one, so its skill board, the saved card's skill set and the
-- mix-slot store hold nothing and the page said «Sin hipertécnica». On the album's plate only (BetterQoL.AlbumPages:
-- the album page's parameter) both reads answer the card's own hyper techniques from its learn list
-- (CMND_VRFW_CHARACTER_LEARNSET: chara_param as the game and the mods serve it): the first keshin / totem / armour
-- (category 8, not a mix type) in the aura slot, the first Mix-Max / «Modo cambio» in the mix slot. Wrapped once per
-- plate VM when the menu starts; elsewhere the page's own reads run.
if BetterQoL.AlbumHyper == nil and VRFW_Host ~= nil and type(VRFW_Host.on) == "function" and VRFW_Cmd ~= nil then
  local H = {
    LEARNSET = VRFW_Cmd.VRFW_CHARACTER_LEARNSET,   -- (charaStHdl) -> answered, {9 moves}, {9 levels}
    SKILL_INFO = VRFW_Cmd.GET_SOCCER_SKILL_INFO,   -- (move, 9) -> ok, category; (move, 13) -> ok, aura type
    CATEGORY_AURA = 8,
    MIX_TYPES = {[2] = true, [6] = true},          -- aura types of the mix slot: Mix-Max, «Modo cambio»
    PLATE_CARD = 2716223290,                       -- crc32 of VRFW.plate_card: the card the album shows now
    sets = {},                                     -- "hdl:card" -> {aura, mix} / false, per opening of the plate
  }
  BetterQoL.AlbumHyper = H

  local function U32(v)
    v = tonumber(v) or 0
    if v < 0 then
      v = v + 4294967296
    end
    return v
  end

  -- the card's own aura / mix moves from its learn list -> {aura, mix}; nil = not the album's plate or no answer
  function H.Of(hdl)
    local album = BetterQoL.AlbumPages
    if album == nil or album.Shown() or type(hdl) ~= "number" or hdl == 0 or type(funcLuaCommand) ~= "function" then
      return nil
    end
    local card = VRFW_Param.Get(H.PLATE_CARD)
    local key = tostring(hdl) .. ":" .. tostring(card)
    local set = H.sets[key]
    if set ~= nil then
      return set or nil
    end
    set = false
    local ok, answered, moves = pcall(funcLuaCommand, H.LEARNSET, hdl)
    if ok and answered == true and type(moves) == "table" then
      set = {aura = 0, mix = 0}
      for k = 1, 9 do
        local m = U32(moves[k])
        local okc, known, category = pcall(funcLuaCommand, H.SKILL_INFO, m, 9)
        if m ~= 0 and okc and known and category == H.CATEGORY_AURA then
          local okt, kt, kind = pcall(funcLuaCommand, H.SKILL_INFO, m, 13)
          if okt and kt and H.MIX_TYPES[kind] then
            if set.mix == 0 then set.mix = m end
          elseif set.aura == 0 then
            set.aura = m
          end
        end
      end
    end
    H.sets[key] = set
    return set or nil
  end

  local function Wrap(name, field)
    local orig = _ENV[name]
    if type(orig) ~= "function" or H[name] == orig then
      return
    end
    H[name] = function(chara, ...)
      local set = H.Of(chara)
      if set ~= nil then
        return set[field]
      end
      return orig(chara, ...)
    end
    _ENV[name] = H[name]
  end

  VRFW_Host.on("personal_plate_menu", "OnInit", {id = "BetterQoL.album_hyper", phase = "after", create = true,
    fn = function()
      H.sets = {}
      Wrap("EVT_PH_AuraOf", "aura")
      Wrap("EVT_PH_MixOf", "mix")
    end})
end
