-- lua_patch.scope: used
-- Writes a saved player set to a character handle: the one write path of the skill table and of any other menu.
CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
-- Per-row actions of the player set list: [name] = { key_text, row_text, press }; any mod may add one.
CharacterReforged.player_set_row_actions = CharacterReforged.player_set_row_actions or {}
if CharacterReforged.player_sets == nil then
  local S = {}
  CharacterReforged.player_sets = S

  local HYPER_SLOT, NORMAL_NUM, ROW_NUM, AURA_SLOTS, PRIME_RARITY, LIST_BOARD_SLOTS = 8, 6, 7, 4, 10, 8
  local SE_NG = 2086672038
  local C = {
    GET_SKILL = 903078840,
    SET_SKILL = 2394267160 --[[CMND_SET_SKILL]],
    REMOVE_SKILL = 3149494359 --[[CMND_REMOVE_SKILL]],
    LEARNABLE = 3475351727,
    CHARA_GET = 1131797651,
    SKILL_INFO = 2580586398 --[[CMND_GET_SOCCER_SKILL_INFO]],
    NAME_TEXT = 720417636,
    BOARD_INV = 632801955,
    INV_ITEM = 2662166687,
    SKILL_POS = 26437624,
    TEAM_INFO = 1033065575 --[[CMND_GET_TEAM_SET_INFO]],
    TEAM_AURA_SET = 1506470613 --[[CMND_SET_TEAM_SET_INFO]],
    BOARD_PLACE = 3270716539 --[[CMND_CHARACTERREFORGED_BOARD_PLACE]],
    BOARD_CLEAR = 1398771376 --[[CMND_CHARACTERREFORGED_BOARD_CLEAR]],
    LOG = 519897777 --[[CMND_VRFW_LOG]],
    ADD_ITEM = 1897915498 --[[CMND_ADD_ITEM_ONLY]],
    DEL_ITEM = 425598937 --[[CMND_DELETE_ITEM]],
    ITEM_NUM = 2011560392 --[[CMND_GET_ITEM_NUM]],
    EQUIPPED_NUM = 556568075,
    INV_OF_SLOT = 128658370,              -- (charaStHdl, equip slot) -> the inventory handle worn there
    REMOVE_EQUIP = 402087824 --[[CMND_REMOVE_EQUIP]],
    EQUIP_ITEM = 179748541 --[[CMND_EQUIP_ITEM]],
    LEARNSET = 1491603481 --[[CMND_VRFW_CHARACTER_LEARNSET]],
    CAN_PLACE = 6717499 --[[CMND_CHARACTERREFORGED_CAN_PLACE]],
    PLACE_RULES = 884939394 --[[CMND_CHARACTERREFORGED_PLACE_RULES]],
    SLOT_OF = 1826049290 --[[CMND_CHARACTERREFORGED_SLOT_OF]],
    MIX_GET = 358194355 --[[CMND_CHARACTERREFORGED_MIX_GET]],
    MIX_SET = 242652959 --[[CMND_CHARACTERREFORGED_MIX_SET]],
    PROJECT_SKILL_SET = 2177163225 --[[CMND_CHARACTERREFORGED_PROJECT_SKILL_SET]],
    SIX_SENSE = 8065085 --[[CMND_CHARACTERREFORGED_SIX_SENSE]],
    GET_ROLE = 1327558109 --[[CMND_CHARACTERREFORGED_GET_ROLE]],
    SET_ROLE = 3083981324 --[[CMND_CHARACTERREFORGED_SET_ROLE]],
    DEFAULT_SET = 2076075108 --[[CMND_CHARACTERREFORGED_DEFAULT_SET]],
    SET_GET = 390397015 --[[CMND_CHARACTERREFORGED_PLAYER_SET_GET]],
    SET_FULL = 2129739473 --[[CMND_CHARACTERREFORGED_PLAYER_SET_FULL]],
    PC_INFO = 3569354349 --[[CMND_BETTERQOL_PC_INFO]],
    PC_SLOT = 3007780701 --[[CMND_BETTERQOL_PC_SLOT]],
    PC_SET = 1973449007 --[[CMND_BETTERQOL_PC_SET]],
  }
  S.ROLE_ITEM = {[1] = 2607368153, [2] = 3966662479}   -- coach / manager badge items

  local function u32(id)
    return VRFW.ids.unsigned(id)
  end

  local function call(cmd, ...)
    local ok, a, b, c, d = pcall(funcLuaCommand, cmd, ...)
    if not ok then
      return nil
    end
    return a, b, c, d
  end

  local function log(...)
    call(C.LOG, "skill_slots", ...)
  end

  --- Whether the skill is a Hiper (category 8).
  function S.is_special(skill)
    if skill == nil or skill == 0 then
      return false
    end
    local ok, cat = funcLuaCommand(C.SKILL_INFO, skill, 9)
    return ok and cat == 8
  end

  local special_of = {}
  --- The same, remembered per skill id.
  function S.is_special_cached(id)
    local known = special_of[id]
    if known == nil then
      known = S.is_special(id) == true
      special_of[id] = known
    end
    return known
  end

  --- The display name of a skill; its hex id when it has none.
  function S.name(skill)
    if skill == nil or skill == 0 then
      return "---"
    end
    local ok, name_id = funcLuaCommand(C.SKILL_INFO, skill, 4)
    if ok and name_id then
      local text = funcLuaCommand(C.NAME_TEXT, name_id)
      if text ~= nil and text ~= "" then
        return text
      end
    end
    return string.format("%08X", skill)
  end

  --- The skill and inventory handle on board slot `bslot`.
  function S.board_skill(h, bslot)
    if h == nil or h == 0 or bslot == nil then
      return 0, 0
    end
    local inv = funcLuaCommand(C.BOARD_INV, h, bslot, 1)
    if inv == nil or inv == 0 then
      inv = funcLuaCommand(C.BOARD_INV, h, bslot, 0)
    end
    if inv == nil or inv == 0 then
      return 0, 0
    end
    return u32(funcLuaCommand(C.INV_ITEM, inv, 0)), inv
  end

  --- The move on list position `pos`.
  function S.list_skill(h, pos)
    local id = funcLuaCommand(C.GET_SKILL, h, pos)
    return (id ~= nil) and u32(id) or 0
  end

  --- The move on board cell `p` (placed item, else native), 0 for none.
  function S.board_move_at(h, p)
    local inv = funcLuaCommand(C.BOARD_INV, h, p, 1)
    if inv == nil or inv == 0 then
      inv = funcLuaCommand(C.BOARD_INV, h, p, 0)
    end
    if inv == nil or inv == 0 then
      return 0
    end
    return u32(funcLuaCommand(C.INV_ITEM, inv, 0))
  end

  local cached = {learnset = {hdl = -1}, idol = {hdl = -1}}

  --- Drops the per-player reads (the screen calls it when the shown player changes).
  function S.forget()
    cached.learnset, cached.idol = {hdl = -1}, {hdl = -1}
  end

  --- The learnset of `h`: chara_param slots 1-9 (9 is the Hiper).
  function S.read_learnset(h)
    if cached.learnset.hdl == h then
      return cached.learnset
    end
    local ls = {hdl = h, skill = {}, lv = {}, loader = false}
    cached.learnset = ls
    if h == nil or h == 0 then
      return ls
    end
    local ok, ids, lvs = call(C.LEARNSET, h)
    if ok == true and type(ids) == "table" and type(lvs) == "table" then
      ls.loader = true
      for k = 1, 9 do
        ls.skill[k] = u32(ids[k] or 0)
        ls.lv[k] = tonumber(lvs[k]) or 0
      end
      return ls
    end
    local okr, rids, rlvs = funcLuaCommand(C.LEARNABLE, h)
    if okr and type(rids) == "table" then
      for k = 1, NORMAL_NUM do
        ls.skill[k] = u32(rids[k] or 0)
        ls.lv[k] = (type(rlvs) == "table" and tonumber(rlvs[k])) or 0
      end
    end
    return ls
  end

  --- The move an empty list position `p` takes.
  function S.fill_move_at(h, p)
    local id = S.board_move_at(h, p)
    if id ~= 0 or p == nil or p < 0 or p >= NORMAL_NUM then
      return id
    end
    local ls = S.read_learnset(h)
    local m, need = ls.skill[p + 1] or 0, ls.lv[p + 1] or 0
    if m == 0 then
      return 0
    end
    if need > 1 and (funcLuaCommand(C.CHARA_GET, h, 0) or 0) < need then
      return 0
    end
    return m
  end

  --- The technique board cell `p` adds to the rows, 0 for none.
  function S.board_technique_at(h, p)
    local id = S.fill_move_at(h, p)
    if id == 0 or S.is_special_cached(id) then
      return 0
    end
    local at = funcLuaCommand(C.SKILL_POS, h, id)
    if at ~= nil and at >= 0 and at < NORMAL_NUM then
      return 0
    end
    for q = 0, p - 1 do
      local listed = funcLuaCommand(C.GET_SKILL, h, q)
      if (listed == nil or listed == 0) and S.fill_move_at(h, q) == id then
        return 0
      end
    end
    return id
  end

  --- Whether `h` is a Prime card.
  function S.is_prime(h)
    return h ~= nil and h ~= 0 and funcLuaCommand(C.CHARA_GET, h, 12) == PRIME_RARITY
  end

  --- Whether `h` is a custom Idol card.
  function S.is_idol(h)
    if cached.idol.hdl == h then
      return cached.idol.on
    end
    local on = false
    if h ~= nil and h ~= 0 and type(IDOL_FRAME) == "table" then
      local param = funcLuaCommand(C.CHARA_GET, h, 4)
      if type(param) == "number" then
        on = IDOL_FRAME[u32(param)] ~= nil or IDOL_FRAME[param] ~= nil
      end
    end
    cached.idol = {hdl = h, on = on}
    return on
  end

  --- The learnset slot of a row.
  function S.row_slot(row)
    if row == 0 then
      return 9
    end
    return row
  end

  --- Whether an Idol card's row is fixed.
  function S.idol_fixed(h, row)
    if row == nil or row < 0 or row >= ROW_NUM or not S.is_idol(h) then
      return false
    end
    local ls = S.read_learnset(h)
    local m = ls.skill[S.row_slot(row)] or 0
    if row == 0 then
      return S.is_special(m)
    end
    return m ~= 0
  end

  --- The level at which a row unlocks.
  function S.unlock_level(h, row)
    if row == 0 then
      if S.is_idol(h) then
        local ls = S.read_learnset(h)
        local m = ls.skill[9] or 0
        if m ~= 0 and S.is_special(m) and (ls.lv[9] or 0) > 1 then
          return ls.lv[9]
        end
      end
      return 0
    end
    local need = CharacterReforged.move_rows.need(funcLuaCommand, h, row - 1)
    return need
  end

  --- Whether a row is below its unlock level, and that level.
  function S.is_locked(h, row)
    return CharacterReforged.move_rows.below(funcLuaCommand, h, S.unlock_level(h, row))
  end

  --- Whether the move is in the match list.
  function S.active(h, skill)
    if skill == 0 then
      return false
    end
    local pos = funcLuaCommand(C.SKILL_POS, h, skill)
    return pos ~= nil and pos >= 0 and pos < 6
  end

  -- this player's team aura slot and the free slot of the team in ctx
  local function aura_find(h, ctx)
    local mine, free, mine_skill = -1, -1, 0
    for i = 0, AURA_SLOTS - 1 do
      local ok, ch, sk = funcLuaCommand(C.TEAM_INFO, ctx.dock, ctx.kind, 15, i)
      if ok then
        if u32(ch) == u32(h) and mine < 0 then
          mine, mine_skill = i, u32(sk)
        elseif (ch == nil or ch == 0) and free < 0 then
          free = i
        end
      end
    end
    return mine, free, mine_skill
  end

  --- The player's team aura in the team of `ctx`, 0 for none.
  function S.team_aura_get(h, ctx)
    if ctx.dock == nil then
      return 0
    end
    local _, _, sk = aura_find(h, ctx)
    return sk
  end

  --- Puts `skill` (0 = remove) into the player's team aura slot: ok, description.
  function S.team_aura_put(h, skill, ctx)
    if ctx.dock == nil then
      return false, "no team"
    end
    local mine, free = aura_find(h, ctx)
    local slot = mine >= 0 and mine or free
    if slot < 0 then
      return skill == 0, "team aura full (4 of 4)"
    end
    local ok
    if skill == 0 then
      ok = funcLuaCommand(C.TEAM_AURA_SET, ctx.dock, ctx.kind, 6, slot, 0, 0)
    else
      ok = funcLuaCommand(C.TEAM_AURA_SET, ctx.dock, ctx.kind, 6, slot, h, skill)
    end
    local _, _, now = aura_find(h, ctx)
    local good = (skill == 0 and now == 0) or (skill ~= 0 and now == skill)
    return good, string.format("team aura slot %d %s (team %s/%s, game %s)", slot + 1, good and "OK" or "NO",
      tostring(ctx.dock), tostring(ctx.kind), tostring(ok))
  end

  --- The move a row holds.
  function S.skill(h, row, ctx)
    if row == 0 then
      local skill = S.board_skill(h, HYPER_SLOT)
      if S.is_special(skill) then
        return skill
      end
      local aura = S.team_aura_get(h, ctx)
      return S.is_special(aura) and aura or 0
    end
    local skill = S.list_skill(h, row - 1)
    if skill ~= 0 then
      if S.is_special(skill) then
        return 0                                   -- an aura kept hidden on this position (the projection)
      end
      return skill
    end
    return S.board_technique_at(h, row - 1)
  end

  --- Places an inventory handle on a board slot: done and verified, state.
  function S.board_put(h, bslot, skill, inv)
    if bslot == nil or inv == nil or inv == 0 then
      return false, "no slot / item"
    end
    local st = call(C.BOARD_PLACE, h, inv, bslot)
    return st == 1 and S.board_skill(h, bslot) == skill, st
  end

  --- Clears a board slot; keep_open leaves the slot open.
  function S.board_clear(h, bslot, keep_open)
    if bslot == nil then
      return nil
    end
    return (call(C.BOARD_CLEAR, h, bslot, keep_open and 1 or 0))
  end

  --- Puts `skill` on list position `slot`; the move leaves every other position that held it.
  function S.list_put(h, slot, skill)
    if skill == 0 or slot == nil then
      return
    end
    local pos = funcLuaCommand(C.SKILL_POS, h, skill)
    if pos ~= slot then
      funcLuaCommand(C.SET_SKILL, h, skill, slot)
    end
    -- CMND_SET_SKILL swaps with the move on `slot`; over an empty `slot` it leaves `skill` on its old position too.
    if S.list_skill(h, slot) ~= u32(skill) then
      return
    end
    for other = 0, NORMAL_NUM - 1 do
      if other ~= slot and S.list_skill(h, other) == u32(skill) then
        funcLuaCommand(C.REMOVE_SKILL, h, other)
      end
    end
  end

  --- A real inventory handle for `skill`, and whether a copy was added to obtain it.
  function S.handle_for(h, skill, pool)
    if pool ~= nil and pool[skill] ~= nil and pool[skill] ~= 0 then
      return pool[skill], false
    end
    for b = 0, HYPER_SLOT do
      local id, inv = S.board_skill(h, b)
      if id == skill and inv ~= nil and inv ~= 0 then
        return inv, false
      end
    end
    local owned = funcLuaCommand(C.ITEM_NUM, skill)
    owned = type(owned) == "number" and owned or 0
    local inv = funcLuaCommand(C.ADD_ITEM, skill, 1, false)
    if inv ~= nil and inv ~= 0 then
      local used = funcLuaCommand(C.EQUIPPED_NUM, inv)
      used = type(used) == "number" and used or 0
      if used > owned then
        funcLuaCommand(C.ADD_ITEM, skill, used - owned, false)
      end
      return inv, owned > used
    end
    return 0, false
  end

  --- The handle for the Hiper slot.
  function S.hyper_handle(h, skill)
    for b = 0, HYPER_SLOT do
      local id, inv = S.board_skill(h, b)
      if id == skill and inv ~= nil and inv ~= 0 then
        if b >= 6 then
          return inv, false
        end
        local inv2 = funcLuaCommand(C.ADD_ITEM, skill, 1, false)
        if inv2 ~= nil and inv2 ~= 0 then
          return inv2, false
        end
        return inv, false
      end
    end
    return S.handle_for(h, skill)
  end

  --- Makes the board mirror the match list.
  function S.sync_board(h, ctx)
    if h == nil or h == 0 or S.is_prime(h) or ctx.readonly then
      return true
    end
    local want, cur, curh, todo = {}, {}, {}, {}
    for k = 0, NORMAL_NUM - 1 do
      cur[k], curh[k] = S.board_skill(h, k)
      if not S.is_locked(h, k + 1) then
        local l = S.list_skill(h, k)
        if l ~= 0 then
          want[k] = l
        end
      end
    end
    for k = 0, NORMAL_NUM - 1 do
      local need = want[k] ~= nil and want[k] ~= cur[k]
      if not need and want[k] == nil and cur[k] ~= 0 and not S.is_locked(h, k + 1) then
        for j, s in pairs(want) do                 -- this slot holds a move another row wants
          if j ~= k and s == cur[k] then
            need = true
          end
        end
      end
      if need then
        todo[#todo + 1] = k
      end
    end
    local all_ok = true
    if #todo > 0 then
      local pool = {}
      for _, k in ipairs(todo) do
        if cur[k] ~= 0 and curh[k] ~= 0 then
          pool[cur[k]] = curh[k]
        end
        S.board_clear(h, k, true)
      end
      for pass = 1, 2 do
        for _, k in ipairs(todo) do
          local s = want[k]
          if s ~= nil and S.board_skill(h, k) ~= s then
            local inv, added = S.handle_for(h, s, pool)
            local ok, st = S.board_put(h, k, s, inv)
            if added then
              funcLuaCommand(C.DEL_ITEM, s, 1)
            end
            if pass == 2 then
              log("sync slot", k, S.name(s), ok and "OK" or "NO", "status", st)
            end
          end
        end
      end
      for _, k in ipairs(todo) do
        local now = S.board_skill(h, k)
        if want[k] ~= nil and now ~= want[k] then
          all_ok = false
          if now == 0 and cur[k] ~= 0 then
            local inv, added = S.handle_for(h, cur[k], pool)
            S.board_put(h, k, cur[k], inv)
            if added then
              funcLuaCommand(C.DEL_ITEM, cur[k], 1)
            end
          end
        end
      end
    end
    for k = 0, NORMAL_NUM - 1 do
      if not S.is_locked(h, k + 1) and S.list_skill(h, k) == 0 then
        local b = S.board_skill(h, k)
        if b ~= 0 and not S.active(h, b) and not S.is_special(b) then
          S.list_put(h, k, b)
        end
      end
    end
    return all_ok
  end

  --- The slot kind of a Hiper move (0 aura, 1 mix, 2 an armour, 3 a picker create entry) and the keshin of an armour.
  function S.hs_kind(id)
    if id == nil or id == 0 then
      return nil, 0
    end
    local ok, kind, k = pcall(funcLuaCommand, C.SLOT_OF, id)
    if not ok or type(kind) ~= "number" then
      return nil, 0
    end
    return kind, u32(k or 0)
  end

  --- The player's mix slot, 0 for none.
  function S.hs_mix(h)
    if h == nil or h == 0 then
      return 0
    end
    local ok, id = pcall(funcLuaCommand, C.MIX_GET, h)
    return (ok and type(id) == "number") and u32(id) or 0
  end

  --- Writes the player's mix slot.
  function S.hs_mix_put(h, id, ctx)
    if ctx.readonly or h == nil or h == 0 then
      return false
    end
    local ok, done, code = pcall(funcLuaCommand, C.MIX_SET, h, id or 0)
    pcall(call, C.LOG, "skill_slots", "hiper mix slot", string.format("%08X", u32(h)),
      string.format("%08X", u32(id or 0)), tostring(ok), tostring(done), tostring(code))
    return ok and done == true
  end

  local place_rules = nil
  -- the placement rule commands mods declared
  local function read_place_rules()
    if place_rules ~= nil then
      return place_rules
    end
    local r = {pcall(funcLuaCommand, C.PLACE_RULES)}
    local out = {}
    if r[1] == true and type(r[2]) == "number" then
      for i = 1, r[2] do
        local id, kind = r[1 + 2 * i], r[2 + 2 * i]
        if type(id) == "number" and id ~= 0 then
          out[#out + 1] = {id = id, board = kind == 1}
        end
      end
    end
    place_rules = out
    log("Character Reforged place rules", #out)
    return out
  end

  --- The placement slot of a row (the Hiper row: 7 aura half, 8 mix half).
  function S.place_slot_of(row, ctx)
    if row == nil then
      return 0
    end
    if row == 0 then
      return ctx.hs_half == 1 and 8 or 7
    end
    return row
  end

  --- Whether `skill` may go on `slot`: allowed, why.
  function S.can_place(h, slot, skill)
    if skill == nil or skill == 0 or h == nil or h == 0 then
      return true, ""
    end
    local ok, res, why = pcall(funcLuaCommand, C.CAN_PLACE, h, slot, skill)
    if ok and res == false then
      return false, why or ""
    end
    for _, r in ipairs(read_place_rules()) do
      local at = slot
      if r.board then
        at = (slot == 7) and HYPER_SLOT or ((slot >= 1 and slot <= 6) and slot - 1 or nil)
      end
      if at ~= nil then
        local okr, res2 = pcall(funcLuaCommand, r.id, h, at, skill)
        if okr and res2 == false then
          return false, string.format("rule %08X", u32(r.id))
        end
      end
    end
    return true, ""
  end

  --- Moves a hidden aura out of list position `row` before a move takes it; the aura moved, if any.
  function S.free_list_pos(h, row, skill, ctx)
    local pos = row - 1
    local cur = S.list_skill(h, pos)
    if cur == 0 or not S.is_special(cur) or cur == skill then
      return
    end
    local p = funcLuaCommand(C.SKILL_POS, h, skill)
    if p ~= nil and p >= 0 and p < NORMAL_NUM then
      return
    end
    local okk, kind = pcall(funcLuaCommand, C.SLOT_OF, cur)
    kind = okk and kind or -1
    local what = "overflow: replaced (item back to stock)"
    if (kind == 0 or kind == 2) and S.skill(h, 0, ctx) == 0 then
      local inv, added = S.hyper_handle(h, cur)
      local ok = false
      if inv ~= nil and inv ~= 0 then
        ok = S.board_put(h, HYPER_SLOT, cur, inv)
      end
      if added then
        funcLuaCommand(C.DEL_ITEM, cur, 1)
      end
      if ok then
        S.team_aura_put(h, cur, ctx)
      end
      what = ok and "moved to the aura slot" or "aura slot write FAILED: replaced"
    elseif kind == 1 then
      local okg, have = pcall(funcLuaCommand, C.MIX_GET, h)
      if okg and (tonumber(have) or 0) == 0 then
        local oks, done = pcall(funcLuaCommand, C.MIX_SET, h, cur)
        what = (oks and done == true) and "moved to the mix slot" or "mix slot write FAILED: replaced"
      end
    end
    log("projection", "row", row, "list position", pos + 1, "hidden", S.name(cur), what, "for", S.name(skill))
    return cur
  end

  --- Gives a displaced aura a copy back when the player no longer has it anywhere.
  function S.keep_aura(h, aura, why)
    if aura == nil or aura == 0 then
      return
    end
    for b = 0, HYPER_SLOT do
      if S.board_skill(h, b) == aura then
        return
      end
    end
    if S.active(h, aura) or S.hs_mix(h) == u32(aura) then
      return
    end
    local num = funcLuaCommand(C.ITEM_NUM, aura)
    if type(num) == "number" and num > 0 then
      log("projection", "hidden aura", S.name(aura), "kept in stock", num, why)
      return
    end
    local inv = funcLuaCommand(C.ADD_ITEM, aura, 1, false)
    log("projection", "hidden aura", S.name(aura), "had no copy left: one copy back into stock", tostring(inv), why)
  end

  --- The aura and mix the skill set projects on the player; nil when it does not apply.
  function S.skill_set_projection(h)
    if h == nil or h == 0 or S.is_prime(h) then
      return nil
    end
    local ok, aura, mix, aura_from, mix_from = pcall(funcLuaCommand, C.PROJECT_SKILL_SET, h)
    if not ok or type(aura) ~= "number" then
      return nil
    end
    return {aura = u32(aura), mix = u32(mix or 0), aura_from = tonumber(aura_from) or -1, mix_from = tonumber(mix_from) or -1}
  end

  local function fb_wanted(half, id)
    if id == nil or id == 0 then
      return false
    end
    local kind = S.hs_kind(id)
    if half == "mix" then
      return kind == 1
    end
    return kind == 0 or kind == 2
  end

  --- The board slots holding a fallback of `half`.
  function S.fb_sources(h, half)
    local out, seen = {}, {}
    for p = 0, NORMAL_NUM - 1 do
      local id = S.list_skill(h, p)
      if fb_wanted(half, id) then
        out[#out + 1] = {slot = p, id = id}
        seen[p] = true
      end
    end
    if half == "mix" then
      for b = 0, LIST_BOARD_SLOTS - 1 do
        local id = S.board_skill(h, b)
        if not seen[b] and fb_wanted(half, id) then
          out[#out + 1] = {slot = b, id = id}
        end
      end
    end
    return out
  end

  --- Clears a board slot with the raw clear mode.
  function S.fb_board_clear(h, slot, mode)
    return (call(C.BOARD_CLEAR, h, slot, mode))
  end

  --- Gives a list position a technique when its aura leaves.
  function S.fb_refill(h, pos)
    local function usable(m)
      if m == nil or m == 0 or S.is_special_cached(m) then
        return false
      end
      local at = funcLuaCommand(C.SKILL_POS, h, m)
      return not (at ~= nil and at >= 0 and at < NORMAL_NUM)
    end
    local m = S.board_technique_at(h, pos)
    if not usable(m) then
      local ls = S.read_learnset(h)
      m = ls.skill[pos + 1] or 0
      local lv = funcLuaCommand(C.CHARA_GET, h, 0) or 0
      if (ls.lv[pos + 1] or 0) > lv then
        m = 0
      end
    end
    if usable(m) then
      funcLuaCommand(C.SET_SKILL, h, m, pos)
      if S.list_skill(h, pos) == u32(m) then
        return m
      end
    end
    funcLuaCommand(C.REMOVE_SKILL, h, pos)
    return 0
  end

  --- Takes the fallbacks of `half` off the board: how many went.
  function S.fb_clear(h, half, why, ctx)
    if ctx.readonly or h == nil or h == 0 or S.is_prime(h) then
      return 0
    end
    local okp, proj = pcall(S.skill_set_projection, h)
    if not okp or proj == nil then
      return 0
    end
    local cleared = 0
    for _, s in ipairs(S.fb_sources(h, half)) do
      local st = S.fb_board_clear(h, s.slot, 1)
      if S.board_skill(h, s.slot) == s.id then
        st = S.fb_board_clear(h, s.slot, 3)        -- a native move: taken off too
      end
      local left = S.board_skill(h, s.slot)
      local listed = S.list_skill(h, s.slot) == s.id
      if listed then
        S.fb_refill(h, s.slot)
        listed = S.list_skill(h, s.slot) == s.id
      end
      local gone = left ~= s.id and not listed
      if gone then
        cleared = cleared + 1
      end
      log("fantasy fallback", why, half, string.format("%08X", u32(h)),
        "board slot", s.slot, S.name(s.id), "clear status", tostring(st),
        gone and "removed" or "still there")
    end
    return cleared
  end

  --- The nine board slots of `h`.
  function S.board_snapshot(h)
    local t = {}
    for b = 0, HYPER_SLOT do
      t[b] = S.board_skill(h, b)
    end
    return t
  end

  --- The board slots that changed between two snapshots, as a log line.
  function S.board_diff(before, after)
    local out = {}
    for b = 0, HYPER_SLOT do
      if before[b] ~= after[b] then
        out[#out + 1] = string.format("%d %s->%s", b + 1, S.name(before[b]), S.name(after[b]))
      end
    end
    if #out == 0 then
      return "no change on the board"
    end
    return "board: " .. table.concat(out, ", ")
  end

  --- Puts `skill` on `row`: the board and list write itself.
  function S.equip_base(h, row, skill, ctx)
    local before = S.board_snapshot(h)
    local msg, ok_all
    if row == 0 then
      local ok_board, st = false, "no handle"
      local inv, added = S.hyper_handle(h, skill)
      local item = (inv ~= 0) and u32(funcLuaCommand(C.INV_ITEM, inv, 0)) or 0
      if inv ~= 0 and item == skill then
        ok_board, st = S.board_put(h, HYPER_SLOT, skill, inv)
      end
      if added then
        funcLuaCommand(C.DEL_ITEM, skill, 1)       -- undo the extra copy made to obtain the handle
      end
      msg = string.format("%s: board %s (slot %d, handle %X, state %s)", S.name(skill), ok_board and "OK" or "NO",
        HYPER_SLOT + 1, u32(inv), tostring(st))
      ok_all = ok_board
      local ok_aura, txt = S.team_aura_put(h, skill, ctx)
      msg = msg .. ", " .. txt
      ok_all = ok_all or ok_aura
    else
      local pos = row - 1
      S.list_put(h, pos, skill)
      local ok_list = S.list_skill(h, pos) == skill
      local ok_board = S.sync_board(h, ctx)
      msg = string.format("%s: list position %d %s, board %s", S.name(skill), pos + 1, ok_list and "OK" or "NO",
        ok_board and "OK" or "unchanged (the list rules)")
      ok_all = ok_list
      if not ok_board then
        -- Diagnostic: the whole list and board of the player, which shows the cells the list's moves sit on.
        local listed, cells = {}, {}
        for position = 0, NORMAL_NUM - 1 do
          listed[#listed + 1] = string.format("%08X", S.list_skill(h, position))
        end
        for cell = 0, HYPER_SLOT do
          cells[#cells + 1] = string.format("%08X", (S.board_skill(h, cell)))
        end
        log("equip row", row, S.name(skill), "board not mirrored", "list", table.concat(listed, " "), "board", table.concat(cells, " "))
      end
    end
    msg = msg .. ".\n" .. S.board_diff(before, S.board_snapshot(h))
    if not ok_all then
      log("equip failed", row, (string.gsub(msg, "\n", " / ")))
      if ctx.se ~= nil then
        ctx.se(SE_NG)                              -- error sound only, details in loader.log
      end
    else
      log("report", row, (string.gsub(msg, "\n", " / ")))
    end
  end

  --- Equip step: writing a move row over a hidden aura moves the aura away first.
  function S.with_projection(h, row, skill, ctx, inner)
    local displaced = nil
    if row ~= nil and row > 0 and skill ~= nil and skill ~= 0 and h ~= nil and h ~= 0 and not S.is_prime(h) then
      local ok, aura = pcall(S.free_list_pos, h, row, skill, ctx)
      if not ok then
        log("projection", "free list position failed", tostring(aura))
      else
        displaced = aura
      end
    end
    local r = inner()
    if displaced ~= nil then
      local ok, err = pcall(S.keep_aura, h, displaced, string.format("row %d %s", row, S.name(skill)))
      if not ok then
        log("projection", "hidden aura check failed", tostring(err))
      end
    end
    return r
  end

  --- Equip step: the placement rules; a refusal answers false.
  function S.with_rules(h, row, skill, ctx, inner)
    local slot = S.place_slot_of(row, ctx)
    -- A picker create entry opens its creation flow and is never stored in any row.
    if skill ~= nil and skill ~= 0 and S.hs_kind(skill) == 3 then
      log("equip refused by Character Reforged: a create entry", row, string.format("%08X", u32(skill)))
      if ctx.se ~= nil then
        ctx.se(SE_NG)
      end
      return false
    end
    if row == 0 and skill ~= nil and skill ~= 0 then
      local kind = S.hs_kind(skill)
      if kind == 1 then
        slot = 8
      elseif kind == 0 or kind == 2 then
        slot = 7
      end
    end
    local allowed, why = S.can_place(h, slot, skill)
    if not allowed then
      log("equip refused by Character Reforged", row, slot, string.format("%08X", u32(skill or 0)), tostring(why))
      if ctx.se ~= nil then
        ctx.se(SE_NG)
      end
      return false
    end
    return inner()
  end

  --- Equip step: keeps the copies an equip must not consume.
  function S.with_copies(h, skill, inner)
    if type(VRFW.copies) ~= "table" then
      return inner()
    end
    local ok_snapshot, before = pcall(function()
      local ids = {u32(skill)}
      for b = 0, HYPER_SLOT do
        ids[#ids + 1] = (S.board_skill(h, b))
      end
      return VRFW.copies.snapshot(ids)
    end)
    if not ok_snapshot or next(before) == nil then
      return inner()
    end
    inner()
    local ok_restore, err = pcall(VRFW.copies.restore, before, function(id)
      for b = 0, HYPER_SLOT do
        local s, inv = S.board_skill(h, b)
        if s == id and inv ~= nil and inv ~= 0 then
          return inv
        end
      end
      return nil
    end)
    if not ok_restore then
      pcall(funcLuaCommand, C.LOG, "unlimited_copies", "restore error", tostring(err))
    end
  end

  --- Equip step: a Hiper placed on a half takes that half's list and board fallbacks off.
  function S.with_fallbacks(h, row, skill, ctx, inner)
    local r = inner()
    if row == 0 and skill ~= nil and skill ~= 0 and r ~= false then
      local okk, kind = pcall(S.hs_kind, skill)
      local half = (okk and kind == 1) and "mix" or ((okk and (kind == 0 or kind == 2)) and "aura" or nil)
      local placed = half == "mix" and S.hs_mix(h) == u32(skill) or (half == "aura" and S.skill(h, 0, ctx) == u32(skill))
      if placed then
        local ok, cleared = pcall(S.fb_clear, h, half, "equip", ctx)
        if ok and cleared > 0 and ctx.after_change ~= nil then
          pcall(ctx.after_change)
        end
      end
    end
    return r
  end

  --- Puts `skill` on `row` with every equip step.
  function S.equip(h, row, skill, ctx)
    return S.with_fallbacks(h, row, skill, ctx, function()
      return S.with_copies(h, skill, function()
        return S.with_rules(h, row, skill, ctx, function()
          return S.with_projection(h, row, skill, ctx, function()
            return S.equip_base(h, row, skill, ctx)
          end)
        end)
      end)
    end)
  end

  -- the item worn on equip slot `t`: the equip include's reader where the menu has it, else the slot's handle
  local function equip_item(h, t)
    if type(GetEquipItemid) == "function" then
      return GetEquipItemid(h, t)
    end
    local inv = funcLuaCommand(C.INV_OF_SLOT, h, t)
    if inv == nil or inv == 0 then
      return 0
    end
    return funcLuaCommand(C.INV_ITEM, inv, 0)
  end

  --- The five equipment items of `h`.
  function S.equip_ids(h)
    local e = {}
    for t = 0, 4 do
      local ok, id = pcall(equip_item, h, t)
      e[t + 1] = (ok and type(id) == "number") and u32(id) or 0
    end
    return e
  end

  --- The inventory handle of an owned item with a free copy; 0, reason when there is none.
  function S.free_handle(item)
    local num = funcLuaCommand(C.ITEM_NUM, item)
    if type(num) ~= "number" or num <= 0 then
      return 0, "not owned"
    end
    local inv = funcLuaCommand(C.ADD_ITEM, item, 1, false)
    funcLuaCommand(C.DEL_ITEM, item, 1)
    if inv == nil or inv == 0 then
      return 0, "no item"
    end
    -- The delete takes from the first stack of the item (v7.2.1 0xD9A900), so it can empty and free the stack the add opened.
    local held = funcLuaCommand(C.INV_ITEM, inv, 0)
    if type(held) ~= "number" or u32(held) ~= u32(item) then
      log("free handle", string.format("%08X", u32(item)), string.format("handle %08X holds no copy after the probe", u32(inv)))
      return 0, "no item"
    end
    local used = funcLuaCommand(C.EQUIPPED_NUM, inv)
    if type(used) == "number" and used >= num then
      return 0, "every copy in use"
    end
    return inv, nil
  end

  -- the skip reason of a free_handle refusal
  local FREE_REASON = {["not owned"] = "notown", ["no item"] = "fail", ["every copy in use"] = "inuse"}

  --- The custom passive inventory handle and item of `h`.
  function S.six_get(h)
    local r = {pcall(funcLuaCommand, C.SIX_SENSE, h, 0, 0, -1)}
    if not r[1] or r[2] ~= 1 then
      return 0, 0
    end
    return u32(r[3] or 0), u32(r[4] or 0)
  end

  local six_present = nil
  --- Whether a mod answers the custom passive slot.
  function S.has_six_sense()
    if six_present == nil then
      local ok, answer, second = pcall(funcLuaCommand, C.SIX_SENSE, 0, 0, 0, -1)
      six_present = ok and (type(answer) == "number" or second ~= nil)
    end
    return six_present
  end

  --- The role of `h`, its native role and lock; -1 when no mod answers.
  function S.role(h)
    local ok, r, _, _, native, lock = pcall(funcLuaCommand, C.GET_ROLE, h)
    if not ok or type(r) ~= "number" then
      return -1, 0, 0
    end
    return r, type(native) == "number" and native or 0, type(lock) == "number" and lock or 0
  end

  local function ids_of(t, count)
    local out = {}
    for k = 1, count do
      out[k] = u32(type(t) == "table" and t[k] or 0)
    end
    return out
  end

  local has_full = nil
  --- Whether the loader answers the full set read (passives, role, kit, mix).
  function S.has_full(h)
    if has_full == nil then
      local r = {pcall(funcLuaCommand, C.SET_FULL, h, 0)}
      has_full = r[1] == true and type(r[3]) == "string"
      log("loader FULL/SET2", tostring(has_full))
    end
    return has_full
  end

  --- Saved set `index` of `h` as the table the apply reads; nil when the slot is empty.
  function S.read(h, index)
    if S.has_full(h) then
      local r = {pcall(funcLuaCommand, C.SET_FULL, h, index)}
      if r[1] and r[2] == false and r[3] == "" then
        return nil
      end
      if r[1] and r[2] == true and type(r[4]) == "table" then
        local p = {name = r[3] or "", moves = ids_of(r[4], 6), hiper = u32(r[5] or 0), equip = ids_of(r[6], 5),
          sixsense = u32(r[7] or 0)}
        if type(r[8]) == "table" then
          p.passives = ids_of(r[8], 5)
          p.pcfg = ids_of(r[9], 5)
        end
        if type(r[10]) == "number" and r[10] >= 0 then
          p.role = r[10]
        end
        p.kit = type(r[11]) == "number" and u32(r[11]) or 0   -- the team kit at save time
        p.mix = type(r[12]) == "number" and u32(r[12]) or 0   -- the mix slot (0 = empty)
        return p
      end
    end
    local r = {pcall(funcLuaCommand, C.SET_GET, h, index)}
    if not r[1] or r[2] ~= true then
      return nil
    end
    local p = {name = r[3] or "", moves = {}, hiper = u32(r[10] or 0), equip = {}, sixsense = u32(r[16] or 0)}
    for k = 1, 6 do
      p.moves[k] = u32(r[3 + k] or 0)
    end
    for k = 1, 5 do
      p.equip[k] = u32(r[10 + k] or 0)
    end
    return p
  end

  -- the role and configured passives a set stores
  local function apply_extra(h, p, skip)
    if p.role ~= nil and p.role >= 0 then
      local cur = S.role(h)
      if cur >= 0 and cur ~= p.role then
        if p.role ~= 0 and S.ROLE_ITEM[p.role] ~= nil then
          funcLuaCommand(C.ADD_ITEM, S.ROLE_ITEM[p.role], 1, false)   -- a free copy (as the role picker)
        end
        local st, now = call(C.SET_ROLE, h, p.role)
        log("load role", cur, "->", p.role, "status", st, "now", now)
        if st ~= 1 then
          skip("fail", "role", p.role)
        end
      end
    end
    if p.pcfg == nil then
      return
    end
    local ok_info, got, mode = pcall(funcLuaCommand, C.PC_INFO, h)
    if not ok_info or got ~= true or mode == 0 then
      for s = 1, 5 do
        if (p.pcfg[s] or 0) ~= 0 then
          skip("locked", "pv_slot", s)
        end
      end
      return
    end
    local function slot(s)
      local ok_slot, id, conf, locked = pcall(funcLuaCommand, C.PC_SLOT, h, s)
      if not ok_slot then
        return 0, false, true
      end
      return u32(id or 0), conf == true, locked == true
    end
    for s = 0, 4 do                                -- first free the slots the set does not keep
      local id, conf, locked = slot(s)
      if conf and not locked and id ~= (p.pcfg[s + 1] or 0) then
        pcall(funcLuaCommand, C.PC_SET, h, s, 0)
      end
    end
    for s = 0, 4 do
      local want = p.pcfg[s + 1] or 0
      if want ~= 0 then
        local id, conf, locked = slot(s)
        if not (conf and id == want) then
          if locked then
            skip(mode == 2 and "idol" or "locked", "pv_slot", s + 1)
          else
            local ok_set, done, code = pcall(funcLuaCommand, C.PC_SET, h, s, want)
            log("load passive", s, want, "ok", tostring(ok_set and done), "code", tostring(code))
            if not (ok_set and done == true) then
              skip("fail", "pv_slot", s + 1)
            end
          end
        end
      end
    end
  end

  --- With ctx.exact: empties the rows, the Hiper, the mix and the sixth sense that set `p` holds empty.
  function S.clear_unset(h, p, ctx, skip)
    for r = 1, NORMAL_NUM do
      if (p.moves[r] or 0) == 0 and S.skill(h, r, ctx) ~= 0 and not S.is_locked(h, r) and not S.idol_fixed(h, r) then
        local pos = r - 1
        if S.list_skill(h, pos) ~= 0 then
          funcLuaCommand(C.REMOVE_SKILL, h, pos)
        end
        S.sync_board(h, ctx)
        if S.skill(h, r, ctx) ~= 0 then
          skip("fail", "move", 0)
        end
      end
    end
    if (p.hiper or 0) == 0 and S.skill(h, 0, ctx) ~= 0 and not S.idol_fixed(h, 0) then
      call(C.BOARD_CLEAR, h, HYPER_SLOT, 3)        -- keep-open mode 3: the placed and the native item off
      S.team_aura_put(h, 0, ctx)
    end
    if (p.mix or 0) == 0 and S.hs_mix(h) ~= 0 and not S.hs_mix_put(h, 0, ctx) then
      skip("fail", "move", 0)
    end
    local _, ss = S.six_get(h)
    if (p.sixsense or 0) == 0 and ss ~= 0 and S.has_six_sense() and call(C.SIX_SENSE, h, 1, 0, -1) ~= 1 then
      skip("fail", "passive")
    end
  end

  --- The player's current build as a set (rows below their unlock level count as empty); ctx: dock, kind.
  function S.current(h, ctx)
    ctx = ctx or {}
    S.forget()
    local p = {name = "", moves = {}, equip = {0, 0, 0, 0, 0}}
    for r = 1, NORMAL_NUM do
      p.moves[r] = S.is_locked(h, r) and 0 or S.skill(h, r, ctx)
    end
    p.hiper = S.skill(h, 0, ctx)
    p.mix = S.hs_mix(h)
    local _, ss = S.six_get(h)
    p.sixsense = ss
    local ok, got = pcall(funcLuaCommand, C.PC_INFO, h)
    if ok and got == true then
      p.pcfg = {}
      for s = 0, 4 do
        local ok_slot, id, conf = pcall(funcLuaCommand, C.PC_SLOT, h, s)
        p.pcfg[s + 1] = (ok_slot and conf == true and type(id) == "number") and u32(id) or 0
      end
    end
    local role = S.role(h)
    if role >= 0 then
      p.role = role
    end
    return p
  end

  --- The card's own build of `h`: the learnset moves its level reached, the card's aura and mix, no sixth sense,
  --- no configured passives and the native role.
  function S.default_set(h)
    S.forget()
    local p = {name = "", moves = {}, equip = {0, 0, 0, 0, 0}, sixsense = 0, pcfg = {0, 0, 0, 0, 0}}
    local ls = S.read_learnset(h)
    local level = funcLuaCommand(C.CHARA_GET, h, 0) or 0
    local function reached(slot)
      local m = ls.skill[slot] or 0
      return (m ~= 0 and (ls.lv[slot] or 0) <= level) and m or 0
    end
    for r = 1, NORMAL_NUM do
      local m = reached(r)
      p.moves[r] = S.is_special(m) and 0 or m
    end
    local ok, aura, mix = pcall(funcLuaCommand, C.DEFAULT_SET, h)
    aura = (ok and type(aura) == "number") and u32(aura) or 0
    if aura == 0 or not S.is_special(aura) then
      local m = reached(9)
      aura = S.is_special(m) and m or 0
    end
    p.hiper = aura
    p.mix = (ok and type(mix) == "number") and u32(mix) or 0
    local role, native = S.role(h)
    if role >= 0 then
      p.role = native
    end
    return p
  end

  --- Writes set `p` on `h`; only what the set holds (with ctx.exact, also what it holds empty). ctx: dock, kind, readonly,
  --- hs_half, se, after_change, skip, exact.
  --- ctx.skip(reason, kind, value) gets each piece left out; reasons: prime, row, idol, notown, inuse, fail, locked.
  function S.apply(h, p, ctx)
    ctx = ctx or {}
    local count = 0
    local function skip(reason, kind, value)
      count = count + 1
      if ctx.skip ~= nil then
        ctx.skip(reason, kind, value)
      end
    end
    S.forget()
    local function has(skill)
      if S.active(h, skill) then
        return true
      end
      for b = 0, HYPER_SLOT do
        if S.board_skill(h, b) == skill then
          return true
        end
      end
      local num = funcLuaCommand(C.ITEM_NUM, skill)
      return type(num) == "number" and num > 0
    end
    if S.is_prime(h) then
      skip("prime")
    else
      for r = 1, 6 do
        local s = p.moves[r]
        if s ~= 0 and S.skill(h, r, ctx) ~= s then
          if S.is_locked(h, r) then
            skip("row", "move", s)
          elseif S.idol_fixed(h, r) then
            skip("idol", "move", s)
          elseif not has(s) then
            skip("notown", "move", s)
          elseif not pcall(S.equip, h, r, s, ctx) then
            skip("fail", "move", s)
          end
        end
      end
      if p.hiper ~= 0 and S.skill(h, 0, ctx) ~= p.hiper then
        if S.idol_fixed(h, 0) then
          skip("idol", "move", p.hiper)
        elseif has(p.hiper) and S.is_special(p.hiper) then
          pcall(S.equip, h, 0, p.hiper, ctx)
        else
          skip("notown", "move", p.hiper)
        end
      end
      local mix = p.mix or 0                       -- A stored empty slot leaves the current slot unchanged.
      local ok_mix, now = pcall(S.hs_mix, h)
      if mix ~= 0 and ok_mix and now ~= mix then
        if S.idol_fixed(h, 0) then
          skip("idol", "move", mix)
        elseif not has(mix) then
          skip("notown", "move", mix)
        elseif not S.hs_mix_put(h, mix, ctx) then
          skip("fail", "move", mix)
        end
      end
      if ctx.exact then
        S.clear_unset(h, p, ctx, skip)
      end
    end
    local cur = S.equip_ids(h)                     -- equipment, as the retail equip list commits
    for t = 0, 4 do
      local want = p.equip[t + 1]
      if want ~= 0 and want ~= cur[t + 1] then
        local inv, why = S.free_handle(want)
        if inv ~= 0 then
          if cur[t + 1] ~= 0 then
            funcLuaCommand(C.REMOVE_EQUIP, h, t)
          end
          funcLuaCommand(C.EQUIP_ITEM, h, inv, t)
          if S.equip_ids(h)[t + 1] ~= want then
            skip("fail", "item", want)
          end
        else
          skip(FREE_REASON[why], "item", want)
        end
      end
    end
    local _, ss = S.six_get(h)                     -- custom passive (six-sense slot)
    if p.sixsense ~= 0 and p.sixsense ~= ss then
      local inv, why = S.free_handle(p.sixsense)
      if not S.has_six_sense() then
        skip("locked", "passive")
      elseif inv == 0 then
        skip(FREE_REASON[why], "passive")
      else
        local st = call(C.SIX_SENSE, h, 1, inv, -1)
        if st ~= 1 then
          skip("fail", "passive")
        end
      end
    end
    local ok_extra, err_extra = pcall(apply_extra, h, p, skip)
    if not ok_extra then
      log("player set load extra", tostring(err_extra))
    end
    log("player set load", p.name, "skipped", count)
    return count
  end
end
