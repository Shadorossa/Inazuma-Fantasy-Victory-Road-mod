BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}

if BetterQoL.album_pages == nil and VRFW.player_pages ~= nil and type(VRFW.player_pages.show_when) == "function" then
  local A = {
    FLAG = 2398708549,
    ALBUM = 3856542290,                    -- betterqol_album_menu
    CROSS_CALL = 830228314,                -- (menu, global function, ...)
    PAGES = {"vrfw.SixthSense", "vrfw.TeamPassives", "BetterQoL.Career"},
  }
  BetterQoL.album_pages = A

  -- false while the album page shows the plate
  function A.shown()
    return not VRFW.param.has(A.FLAG)
  end

  BetterQoL.album_keep_pages = BetterQoL.album_keep_pages or {}

  function A.kept(name)
    local keep = BetterQoL.album_keep_pages[name]
    if type(keep) ~= "function" then
      return false
    end
    local ok, v = pcall(keep)
    return ok and v == true
  end

  for _, name in ipairs(A.PAGES) do
    VRFW.player_pages.show_when(name, function()
      return A.shown() or A.kept(name)
    end)
  end

  -- whether a step lands on the first page, told to the album page
  VRFW.player_pages.on_step(function(nxt, o)
    if not A.shown() then
      VRFW.host.command(A.CROSS_CALL, A.ALBUM, "BetterQoL_AlbumPlateFirstPage", o[1] == nil or o[1] == nxt)
    end
  end)
end

if BetterQoL.album_learn_locks == nil and VRFW.host ~= nil and type(VRFW.host.on) == "function" then
  local L = {
    GET_SKILL = 903078840,              -- (charaStHdl, list position 0..5) -> move
    LEARNABLE = 3475351727,             -- (charaStHdl) -> ok, {move per slot}, {learn level per slot}
    LEARN_LEVEL = VRFW.commands ~= nil and VRFW.commands.VRFW_CHARACTER_LEARN_LEVEL or 8867751,   -- (charaStHdl, move) -> need, level
    CHARACTER_STATUS = 1131797651,
    STATUS_LEVEL = 0,
    ROWS = 6,
    SHOWN_LEVEL = 1,                    -- the rows are drawn as for a player at this level
  }
  BetterQoL.album_learn_locks = L

  -- the level card `hdl` learns `move` at (0 = no learn level), from the framework, else the game's learn table
  function L.need(call, hdl, move)
    local ok, need = pcall(call, L.LEARN_LEVEL, hdl, move)
    if ok and type(need) == "number" and need >= 0 then
      return need
    end
    local okT, found, moves, levels = pcall(call, L.LEARNABLE, hdl)
    if okT and found == true and type(moves) == "table" and type(levels) == "table" then
      for i, id in pairs(moves) do
        if VRFW.ids.unsigned(id) == move then
          return tonumber(levels[i]) or 0
        end
      end
    end
    return 0
  end

  function L.locked_level(call, hdl, move)
    local album = BetterQoL.album_pages
    if album == nil or album.shown() or move == 0 then
      return 0
    end
    local need = L.need(call, hdl, move)
    return need > L.SHOWN_LEVEL and need or 0
  end

  function L.row_move(call, hdl, slot)
    local okM, id = pcall(call, L.GET_SKILL, hdl, slot)
    local move = okM and VRFW.ids.unsigned(id) or 0
    if move ~= 0 then
      return move
    end
    local okT, found, moves = pcall(call, L.LEARNABLE, hdl)
    if okT and found == true and type(moves) == "table" and slot < #moves then
      return VRFW.ids.unsigned(moves[slot + 1])
    end
    return 0
  end

  VRFW.host.on("personal_plate_menu", "SetupPersonalPlateCharaSkillItem", {
    id = "BetterQoL.album_learn_locks", phase = "around", priority = 2000000,
    fn = function(nxt, hdl, slot, ...)
      if type(hdl) ~= "number" or hdl == 0 or type(slot) ~= "number" or slot < 0 or slot >= L.ROWS
          or type(funcLuaCommand) ~= "function" then
        return nxt(hdl, slot, ...)
      end
      local album = BetterQoL.album_pages
      if album == nil or album.shown() then
        return nxt(hdl, slot, ...)
      end
      local call = funcLuaCommand
      local move = L.row_move(call, hdl, slot)
      local need = L.locked_level(call, hdl, move)
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

if BetterQoL.album_hyper == nil and VRFW.host ~= nil and type(VRFW.host.on) == "function" and VRFW.commands ~= nil then
  local H = {
    LEARNSET = VRFW.commands.VRFW_CHARACTER_LEARNSET,   -- (charaStHdl) -> answered, {9 moves}, {9 levels}
    SKILL_INFO = VRFW.commands.GET_SOCCER_SKILL_INFO,   -- (move, 9) -> ok, category; (move, 13) -> ok, aura type
    CATEGORY_AURA = 8,
    HALF = VRFW.commands.VRFW_EXTRA_SLOT_HALF,      -- (move) -> 0 aura slot, 1 mix slot, -1 neither (the extra slot's [source])
    AURA_HALF = 0,
    MIX_HALF = 1,
    PLATE_CARD = 2716223290,
    sets = {},                                     -- "hdl:card" -> {aura, mix} / false, per opening of the plate
  }
  BetterQoL.album_hyper = H

  function H.of(hdl)
    local album = BetterQoL.album_pages
    if album == nil or album.shown() or type(hdl) ~= "number" or hdl == 0 or type(funcLuaCommand) ~= "function" then
      return nil
    end
    local card = VRFW.param.get(H.PLATE_CARD)
    local key = tostring(hdl) .. ":" .. tostring(card)
    local set = H.sets[key]
    if set ~= nil then
      return set or nil
    end
    set = false
    local answered, moves = VRFW.host.command(H.LEARNSET, hdl)
    if answered == true and type(moves) == "table" then
      set = {aura = 0, mix = 0}
      for k = 1, 9 do
        local m = VRFW.ids.unsigned(moves[k])
        local known, category = VRFW.host.command(H.SKILL_INFO, m, 9)
        if m ~= 0 and known and category == H.CATEGORY_AURA then
          local half = VRFW.host.command(H.HALF, m)
          if half == H.MIX_HALF then
            if set.mix == 0 then set.mix = m end
          elseif half == H.AURA_HALF and set.aura == 0 then
            set.aura = m
          end
        end
      end
    end
    H.sets[key] = set
    return set or nil
  end

  local function Wrap(name, field)
    local owner = rawget(_ENV, "CharacterReforged")
    local orig = type(owner) == "table" and owner[name] or nil
    if type(orig) ~= "function" or H[name] == orig then
      return
    end
    H[name] = function(chara, ...)
      local set = H.of(chara)
      if set ~= nil then
        return set[field]
      end
      return orig(chara, ...)
    end
    owner[name] = H[name]
  end

  VRFW.host.on("personal_plate_menu", "OnInit", {id = "BetterQoL.album_hyper", phase = "after", create = true,
    fn = function()
      H.sets = {}
      Wrap("hyper_page_aura_of", "aura")
      Wrap("hyper_page_mix_of", "mix")
    end})
end
