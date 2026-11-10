CharacterReforged = type(CharacterReforged) == "table" and CharacterReforged or {}
if CharacterReforged.page == nil then
  local Page = {}
  CharacterReforged.page = Page
  Page.HOST_STAT = "CharacterReforged.page_stat"
  Page.HOST_LUCK_BONUS = "CharacterReforged.page_luck_bonus"
  Page.HOST_STAT_MAX = "CharacterReforged.page_stat_max"
  Page.HOST_STAT_BONUS = "CharacterReforged.page_stat_bonus"
  Page.HOST_STAT_GAIN = "CharacterReforged.page_stat_gain"
  Page.HOST_MODE_CHANGE_PARTNER = "CharacterReforged.mode_change_partner"
  Page.CMD_CHARA_STAT = 1938088826
  Page.LUCK = 8                            -- stat idx of Suerte
  Page.CMD_MIX_GET = 358194355
  Page.providerCache = {}                  -- host -> the command ids of its entries, last declared first

  local function EngineReady()
    return type(rawget(_ENV, "funcLuaCommand")) == "function"
  end

  -- the command ids declared on a host, last declared first (read once per VM, at the first run-time use)
  function Page.providers(host)
    local cached = Page.providerCache[host]
    if cached ~= nil then
      return cached
    end
    local list = {}
    if not EngineReady() then
      return list
    end
    local menu = rawget(VRFW, "menu")
    if type(menu) == "table" and type(menu.entries) == "function" then
      local ok, entries = pcall(menu.entries, host)
      if ok and type(entries) == "table" then
        for i = #entries, 1, -1 do
          local entry = entries[i]
          local id = entry.value_id
          if type(id) ~= "number" and type(entry.value) == "string" and type(rawget(_ENV, "CALC_CRC")) == "function" then
            id = CALC_CRC(entry.value)
          end
          if entry.kind == "command" and type(id) == "number" and id ~= 0 then
            list[#list + 1] = id
          end
        end
      end
    end
    Page.providerCache[host] = list
    return list
  end

  function Page.stat(hdl, idx)
    if not EngineReady() then
      return nil
    end
    for _, id in ipairs(Page.providers(Page.HOST_STAT)) do
      local value = VRFW.host.command(id, hdl, idx)
      if type(value) == "number" and value >= 0 then
        return value
      end
    end
    local value = VRFW.host.command(Page.CMD_CHARA_STAT, hdl, idx)
    if type(value) == "number" and value >= 0 then
      if idx == Page.LUCK then
        value = value + Page.luck_bonus(hdl)
      end
      return value
    end
    return nil
  end

  -- the sum of the page_luck_bonus answers for a chara status handle (0 = none)
  function Page.luck_bonus(hdl)
    local sum = 0
    if not EngineReady() then
      return sum
    end
    for _, id in ipairs(Page.providers(Page.HOST_LUCK_BONUS)) do
      local bonus = VRFW.host.command(id, hdl)
      if type(bonus) == "number" then
        sum = sum + bonus
      end
    end
    return sum
  end

  -- The 8 stat points (engine stat order) the page_stat_bonus answers add, with `item` worn in `slot` when given.
  function Page.stat_bonus(hdl, item, slot)
    local sum = {0, 0, 0, 0, 0, 0, 0, 0}
    if not EngineReady() then
      return sum
    end
    for _, id in ipairs(Page.providers(Page.HOST_STAT_BONUS)) do
      local r = {VRFW.host.command(id, hdl, item or 0, slot or 0)}
      for k = 1, 8 do
        if type(r[k]) == "number" then
          sum[k] = sum[k] + r[k]
        end
      end
    end
    return sum
  end

  function Page.stat_top(hdl, idx)
    if not EngineReady() then
      return nil
    end
    for _, id in ipairs(Page.providers(Page.HOST_STAT_MAX)) do
      local answered, _, base, _, _, _, _, max = VRFW.host.command(id, hdl, idx)
      if answered == true and type(base) == "number" and type(max) == "number" and base + max > 0 then
        return base + max
      end
    end
    return nil
  end

  function Page.stat_sum(hdl, idx)
    if not EngineReady() then
      return nil
    end
    for _, id in ipairs(Page.providers(Page.HOST_STAT_MAX)) do
      local answered, _, base, bonus, delta = VRFW.host.command(id, hdl, idx)
      if answered == true and type(base) == "number" and type(bonus) == "number" and type(delta) == "number" then
        return base + bonus + delta
      end
    end
    return nil
  end

  function Page.gains_raw(hdl)
    if not EngineReady() then
      return {false}
    end
    for _, id in ipairs(Page.providers(Page.HOST_STAT_GAIN)) do
      local result = {true, VRFW.host.command(id, hdl)}
      if result[2] and type(result[4]) == "number" then
        return result
      end
    end
    return {false}
  end

  -- true while the option "Skill table" shows the new set (6 moves + aura slot + mix slot)

  Page.CMD_PROJECT = 2177163225
  Page.projectionCache = {}
  Page.PROJECTION_CACHE_S = 0.25
  local function Clock()
    if type(os) == "table" and type(os.clock) == "function" then
      local ok, t = pcall(os.clock)
      if ok and type(t) == "number" then
        return t
      end
    end
    return nil
  end
  Page.CMD_MATCH_MEMBER = 992494052
  Page.CMD_MEMBER_MOVES = 319507648
  Page.CMD_SKILL_INFO = 2580586398
  Page.MIX_AURA_TYPES = {[2] = true, [6] = true}   -- Mix-Max, Switch Mode
  function Page.match_member_set(card)
    local found, team, slot = VRFW.host.command(Page.CMD_MATCH_MEMBER, card)
    if not (found == true and type(team) == "number" and type(slot) == "number") then
      return nil
    end
    local r = {VRFW.host.command(Page.CMD_MEMBER_MOVES, team, slot)}
    if r[1] ~= true then
      return nil
    end
    local value = {aura = 0, mix = 0, aura_from = -1, mix_from = -1, techniques = {}, rows = {}}
    for i = 1, 6 do
      local m = VRFW.ids.unsigned(r[1 + i])
      local known, category = VRFW.host.command(Page.CMD_SKILL_INFO, m, 9)
      if m ~= 0 and known and category == 8 then
        local kt, kind = VRFW.host.command(Page.CMD_SKILL_INFO, m, 13)
        if kt and Page.MIX_AURA_TYPES[kind] then
          if value.mix == 0 then value.mix, value.mix_from = m, i - 1 end
        elseif value.aura == 0 then
          value.aura, value.aura_from = m, i - 1
        end
      elseif m ~= 0 then
        value.techniques[#value.techniques + 1] = m
        value.rows[#value.rows + 1] = i - 1
      end
    end
    return value
  end

  function Page.projection(card)
    if not EngineReady() or type(card) ~= "number" or card == 0 then
      return nil
    end
    if type(VRFW.plate_member) == "table" and type(VRFW.plate_member.skill_set) == "function" then
      local okm, member = pcall(VRFW.plate_member.skill_set, card)
      if okm and type(member) == "table" then
        return member
      end
    end
    local now = Clock()
    local hit = Page.projectionCache[card]
    if hit ~= nil and now ~= nil and now - hit.at < Page.PROJECTION_CACHE_S then
      return hit.value
    end
    local value = Page.match_member_set(card)
    local aura, mix, auraFrom, mixFrom
    if value == nil then
      aura, mix, auraFrom, mixFrom = VRFW.host.command(Page.CMD_PROJECT, card)
    end
    if type(aura) == "number" then
      value = {aura = VRFW.ids.unsigned(aura), mix = VRFW.ids.unsigned(mix), aura_from = tonumber(auraFrom) or -1, mix_from = tonumber(mixFrom) or -1}
    end
    if now ~= nil then
      Page.projectionCache[card] = {at = now, value = value}
    end
    return value
  end

  function Page.mode_change_partner(card)
    if not EngineReady() or type(card) ~= "number" or card == 0 then
      return nil
    end
    for _, id in ipairs(Page.providers(Page.HOST_MODE_CHANGE_PARTNER)) do
      local exists, partnerParam, partnerChara = VRFW.host.command(id, card)
      if exists == true and type(partnerParam) == "number" and partnerParam ~= 0 then
        return partnerParam, partnerChara
      end
    end
    return nil
  end

  function Page.mix_of(card)
    if not EngineReady() or card == nil or card == 0 then
      return 0
    end
    local move = VRFW.host.command(Page.CMD_MIX_GET, card)
    return (type(move) == "number") and move or 0
  end
end
