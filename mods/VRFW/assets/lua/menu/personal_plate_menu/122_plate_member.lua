VRFW.plate_member = type(VRFW.plate_member) == "table" and VRFW.plate_member or {}
if VRFW.plate_member.gear == nil then
  local M = VRFW.plate_member
  M.P_TEAM = 1930590710                 -- crc32 of VRFW.plate_team
  M.P_SLOT = 469565326                  -- crc32 of VRFW.plate_slot
  M.P_CARD = 2716223290                 -- crc32 of VRFW.plate_card
  M.P_CARD_TEAM = 1860450077            -- crc32 of VRFW.plate_card_team
  M.P_HANDLE = 139464907                -- crc32 of VRFW.plate_handle
  M.P_KIT = 387402342                   -- crc32 of VRFW.plate_kit
  M.C = {
    GEAR = VRFW.commands.VRFW_TEAM_MEMBER_GEAR,
    INV_OF_SLOT = 128658370,            -- (charaStHdl, equip slot) -> the inventory handle worn there
    ITEM_OF_INV = 2662166687,           -- (inventory handle, 0) -> its item id
    CARD_KIT = VRFW.commands.VRFW_CONTACT_KIT,
  }
  M.ITEM_SLOTS = 4

  local function Param(k)
    local v = VRFW.param.get(k)
    return type(v) == "number" and v or nil
  end

  function M.member()
    local team, slot = Param(M.P_TEAM), Param(M.P_SLOT)
    if team == nil or slot == nil or team == 0 then
      return nil
    end
    return team, slot
  end

  -- The live character a line-up viewer shows (VRFW.plate_handle) and the kit of his team (VRFW.plate_kit, 0 = none).
  function M.handle()
    local hdl = VRFW.ids.unsigned(Param(M.P_HANDLE))
    if hdl == 0 then
      return nil
    end
    return hdl, VRFW.ids.unsigned(Param(M.P_KIT))
  end

  -- The items a live character wears in his 4 equipment slots (0 = none).
  local function HandleItems(hdl)
    local real = (type(VRFW.host) == "table" and type(VRFW.host.real_command) == "function") and VRFW.host.real_command
      or funcLuaCommand
    local items = {}
    for k = 0, M.ITEM_SLOTS - 1 do
      local ok, inv = pcall(real, M.C.INV_OF_SLOT, hdl, k)
      local item = 0
      if ok and type(inv) == "number" and inv ~= 0 then
        local oki, id = pcall(real, M.C.ITEM_OF_INV, inv, 0)
        item = (oki and type(id) == "number") and id or 0
      end
      items[k] = item
    end
    return items
  end

  function M.gear()
    local hdl, kit = M.handle()
    if hdl ~= nil then
      return kit, HandleItems(hdl)
    end
    local team, slot = M.member()
    if team == nil then
      return nil
    end
    local found, kit, a, b, c, d = VRFW.host.command(M.C.GEAR, team, slot)
    if not (found == true) then
      return nil
    end
    return kit, {[0] = a or 0, b or 0, c or 0, d or 0}
  end

  function M.card_kit()
    local card = Param(M.P_CARD)
    if card == nil or card == 0 then
      return nil
    end
    local r = VRFW.host.command(M.C.CARD_KIT, card, Param(M.P_CARD_TEAM) or 0)
    if type(r) == "table" and r.source == "own" then
      return 0, "own"
    end
    if type(r) == "table" and type(r.uniform) == "number" and r.uniform ~= 0 then
      return r.uniform, r.source
    end
    return nil
  end

  function M.kit()
    local kit = M.gear()
    if type(kit) == "number" and kit ~= 0 then
      return kit, "member"
    end
    return M.card_kit()
  end

  local function Wrap(name, make)
    local cur = _ENV[name]
    if type(cur) ~= "function" or M.wrapped == cur then
      return
    end
    M.wrapped = make(cur)
    _ENV[name] = M.wrapped
  end
  Wrap("SetupPersonalPlateEquipItem", function(orig)
    return function(i, hdl, ...)
      local kit, items = M.gear()
      if items == nil then
        return orig(i, hdl, ...)
      end
      local tokens = {}
      local function slot_item(nxt, cmd, a, b, ...)
        if a == hdl and type(b) == "number" then
          local it = b >= 0 and b < M.ITEM_SLOTS and items[b] or 0
          if it == 0 then
            return 0
          end
          local token = -1000 - b
          tokens[token] = it
          return token
        end
        return nxt(cmd, a, b, ...)
      end
      local function token_item(nxt, cmd, a, b, ...)
        if tokens[a] ~= nil then
          return tokens[a]
        end
        return nxt(cmd, a, b, ...)
      end
      return (VRFW.host.with_commands({ [M.C.INV_OF_SLOT] = slot_item, [M.C.ITEM_OF_INV] = token_item }, orig, i, hdl,
        ...))
    end
  end)
end

if VRFW.plate_member.skill_set == nil then
  local M = VRFW.plate_member
  M.MC = {
    MOVES = VRFW.commands.VRFW_TEAM_MEMBER_MOVES,
    LEARNSET = VRFW.commands.VRFW_CHARACTER_LEARNSET,
    GET_SKILL = 903078840,              -- (charaStHdl, list position 0-5) -> move
    LEARNABLE = 3475351727,             -- (charaStHdl) -> ok, {move per slot}, {learn level per slot}
    LEARN_LEVEL = VRFW.commands.VRFW_CHARACTER_LEARN_LEVEL,
    BOARD_INV = 632801955,              -- (charaStHdl, board slot, kind) -> inventory handle
    SKILL_SET = VRFW.commands.VRFW_SKILL_SET,
    SKILL_INFO = VRFW.commands.GET_SOCCER_SKILL_INFO,
    LOG = VRFW.commands.VRFW_LOG,                   -- CMND_VRFW_LOG
  }
  M.MIX_TYPES = {[2] = true, [6] = true} -- aura types of the mix slot: Mix-Max, mode change
  M.ROWS = 6
  M.set_cache = nil
  M.temporary = {}

  local function U32(v) return VRFW.ids.unsigned(v) end

  local function Build(call, set, moves, position)
    for i, m in ipairs(moves) do
      local okc, known, category = pcall(call, M.MC.SKILL_INFO, m, 9)
      if m ~= 0 and okc and known and category == 8 then
        local okt, kt, kind = pcall(call, M.MC.SKILL_INFO, m, 13)
        if okt and kt and M.MIX_TYPES[kind] then
          if set.mix == 0 then set.mix, set.mix_from = m, i - 1 end
        elseif set.aura == 0 then
          set.aura, set.aura_from = m, i - 1
        end
      elseif m ~= 0 and #set.techniques < M.ROWS then
        set.techniques[#set.techniques + 1] = m
        set.rows[#set.rows + 1] = position(i, #set.techniques)
      end
    end
    return set
  end

  local function NewSet(key)
    return {key = key, found = false, moves = {}, rows = {}, techniques = {}, aura = 0, mix = 0, aura_from = -1,
      mix_from = -1}
  end

  local function TemporaryCard(hdl)
    if type(hdl) ~= "number" or hdl == 0 or M.temporary[hdl] == false then
      return nil
    end
    local editor = VRFW.team_editor
    local ok, card = false, nil
    if type(editor) == "table" and type(editor.temporary_card) == "function" then
      ok, card = pcall(editor.temporary_card, hdl)
    end
    if ok and type(card) == "number" and card ~= 0 then
      return card
    end
    M.temporary[hdl] = false
    return nil
  end

  local function TemporarySet(hdl)
    local card = TemporaryCard(hdl)
    if card == nil then
      return nil
    end
    local key = "temporary:" .. tostring(hdl) .. ":" .. tostring(card)
    if M.set_cache ~= nil and M.set_cache.key == key then
      return M.set_cache.found and M.set_cache or nil
    end
    local real = (type(VRFW.host) == "table" and type(VRFW.host.real_command) == "function") and VRFW.host.real_command
      or funcLuaCommand
    local set = NewSet(key)
    M.set_cache = set
    local ok, answered, moves, levels = pcall(real, M.MC.LEARNSET, hdl)
    if ok and answered == true and type(moves) == "table" then
      local list = {}
      for k = 1, 9 do
        list[#list + 1] = U32(moves[k])
      end
      set.found = true
      Build(real, set, list, function(_, row) return row - 1 end)
      local okl, _, level = pcall(real, M.MC.LEARN_LEVEL, hdl, set.techniques[1] or 0)
      level = (okl and tonumber(level)) or 0
      for i = 1, M.ROWS do
        local m = set.techniques[i] or 0
        local need = 0
        for k = 1, 9 do
          if list[k] == m and type(levels) == "table" then need = tonumber(levels[k]) or 0 end
        end
        set.moves[i] = (m ~= 0 and (need <= 1 or level >= need)) and m or 0
      end
    end
    pcall(real, M.MC.LOG, "VRFW plate member", string.format("temporary player %s (card 0x%08X): %s", tostring(hdl),
      card % 4294967296, set.found and string.format("his card's learn list: %d technique(s), aura 0x%08X, mix 0x%08X",
        #set.techniques, set.aura, set.mix) or "no learn list answered (the game's own reads)"))
    return set.found and set or nil
  end

  -- The moves a live character has set in his 6 move slots.
  local function HandleSet(hdl)
    local key = "handle:" .. tostring(hdl)
    if M.set_cache ~= nil and M.set_cache.key == key then
      return M.set_cache.found and M.set_cache or nil
    end
    local real = (type(VRFW.host) == "table" and type(VRFW.host.real_command) == "function") and VRFW.host.real_command
      or funcLuaCommand
    local set = NewSet(key)
    local list = {}
    for i = 1, M.ROWS do
      local ok, m = pcall(real, M.MC.GET_SKILL, hdl, i - 1)
      list[i] = ok and U32(m) or 0
      set.moves[i] = list[i]
      set.found = set.found or list[i] ~= 0
    end
    Build(real, set, list, function(i) return i - 1 end)
    M.set_cache = set
    pcall(real, M.MC.LOG, "VRFW plate member", string.format("live character %s: %s", tostring(hdl),
      set.found and string.format("his own set: %d technique(s), aura 0x%08X, mix 0x%08X", #set.techniques, set.aura,
        set.mix) or "no move set: the card's own set kept"))
    return set.found and set or nil
  end

  local function MemberSet(call)
    local team, slot = M.member()
    if team == nil then
      return nil
    end
    local key = tostring(team) .. ":" .. tostring(slot)
    if M.set_cache ~= nil and M.set_cache.key == key then
      return M.set_cache.found and M.set_cache or nil
    end
    local r = {pcall(call, M.MC.MOVES, team, slot)}
    local set = NewSet(key)
    set.found = r[1] == true and r[2] == true
    if set.found then
      local list = {}
      for i = 1, 6 do
        list[i] = U32(r[2 + i])
        set.moves[i] = list[i]
      end
      Build(call, set, list, function(i) return i - 1 end)
    end
    M.set_cache = set
    pcall(call, M.MC.LOG, "VRFW plate member", string.format("team 0x%08X slot %s: %s", team % 4294967296, tostring(slot),
      set.found and string.format("team set applied: %d technique(s), aura 0x%08X, mix 0x%08X", #set.techniques, set.aura,
        set.mix) or ("card's own set kept (" .. tostring(r[3]) .. ")")))
    return set.found and set or nil
  end

  function M.set(call, hdl)
    local live = M.handle()
    if live ~= nil then
      return HandleSet(live), false
    end
    local team = M.member()
    if team ~= nil then
      return MemberSet(call), false
    end
    return TemporarySet(hdl), true
  end

  function M.skill_set(hdl)
    if type(funcLuaCommand) ~= "function" then
      return nil
    end
    local set = M.set(funcLuaCommand, hdl)
    if set == nil then
      return nil
    end
    return {aura = set.aura, mix = set.mix, aura_from = set.aura_from, mix_from = set.mix_from}
  end

  local answer = {
    [M.MC.GET_SKILL] = function(set, a, b)
      return set.moves[(tonumber(b) or -1) + 1] or 0
    end,
    [M.MC.LEARNABLE] = function(set, a, b, nxt, temporary)
      if temporary then
        return nxt(M.MC.LEARNABLE, a, b)
      end
      return false
    end,
    [M.MC.LEARN_LEVEL] = function(set, a, b, nxt, temporary)
      if temporary then
        return nxt(M.MC.LEARN_LEVEL, a, b)
      end
      local ok, need, level = pcall(nxt, M.MC.LEARN_LEVEL, a, b)
      return 0, (ok and level) or 1
    end,
    [M.MC.BOARD_INV] = function()
      return 0
    end,
    [M.MC.SKILL_SET] = function(set)
      local rows, techniques = {}, {}
      for i = 1, 6 do
        rows[i] = set.rows[i] or -1
        techniques[i] = set.techniques[i] or 0
      end
      return true, set.aura, set.mix, set.aura_from, set.mix_from, rows[1], rows[2], rows[3], rows[4], rows[5], rows[6],
        techniques[1], techniques[2], techniques[3], techniques[4], techniques[5], techniques[6]
    end,
  }
  local function answer_member(nxt, cmd, a, b, ...)
    local ok, set, temporary = pcall(M.set, funcLuaCommand, a)
    if ok and set ~= nil then
      return answer[cmd](set, a, b, nxt, temporary)
    end
    return nxt(cmd, a, b, ...)
  end
  function M.install()
    if M.installed or type(funcLuaCommand) ~= "function" then
      return
    end
    local ids = {}
    for cmd in pairs(answer) do
      ids[#ids + 1] = cmd
    end
    M.installed = VRFW.host.hook_command(ids, answer_member, "VRFW.plate_member")
  end
  if VRFW.host ~= nil then
    VRFW.host.on("personal_plate_menu", "OnInit", {id = "vrfw.plate_member.install", phase = "before", create = true,
      fn = function()
        M.set_cache = nil
        M.temporary = {}
        M.install()
      end})
  end
end
