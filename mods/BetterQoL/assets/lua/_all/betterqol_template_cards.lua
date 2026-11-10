-- A team template read as the game reads a team, without a dock swap: the fields the team lists show.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.template_cards == nil then
  local C = {
    CARD = 3514409766,               -- CMND_BETTERQOL_TEMPLATE_CARD (template) -> its fields and members
    TEAM_SET_INFO = 1033065575,      -- CMND_GET_TEAM_SET_INFO (set, team, field, ...) -> ok, value
    CHARA_INFO = 1131797651,         -- (handle, field)
    CHARA_LEVEL = 0,                 -- CHARA_INFO field: the level, capped while the level cap flag is set
    FIELD = {LEVEL = 1, FORMATION = 4, EMBLEM = 5, NAME = 6, UNIFORM = 7, IS_CAPTAIN = 8},   -- TEAM_SET_INFO fields
    TEAM = 0,                        -- the 11-a-side team of a team set
    STARTERS = 11,                   -- positions 0..10
    SUPPORT_FIRST = 16, COACH = 19,  -- positions 16..19 do not count for the team level (nie.exe 0xDACE50)
  }
  BetterQoL.template_cards = C

  --- The card of `template`: its dock when it is in one, else its stored fields and members; nil when it is empty.
  function C.read(template)
    local _, _, set, emblem, uniform, name, formation, _, _, _, members, captain = VRFW.host.command(C.CARD, template)
    if type(members) ~= "string" then
      return nil
    end
    local card = {template = template, set = type(set) == "number" and set >= 0 and set or nil, emblem = emblem,
      uniform = uniform, name = name, formation = formation, captain = captain, members = {}, starters = 0, levels = {}}
    for position, handle in members:gmatch("(%d+):(-?%d+)") do
      position = tonumber(position)
      card.members[#card.members + 1] = {handle = tonumber(handle), position = position}
      if position < C.STARTERS then
        card.starters = card.starters + 1
      end
    end
    return card
  end

  --- The game's team level of a stored card under level cap `level_cap`: the mean member level rounded up, 1 without members.
  function C.stored_level(card, level_cap)
    local level = card.levels[level_cap]
    if level == nil then
      local sum, counted = 0, 0
      for _, member in ipairs(card.members) do
        if member.position < C.SUPPORT_FIRST or member.position > C.COACH then
          local member_level = VRFW.host.real_command(C.CHARA_INFO, member.handle, C.CHARA_LEVEL)
          if type(member_level) == "number" then
            sum, counted = sum + member_level, counted + 1
          end
        end
      end
      level = counted == 0 and 1 or math.ceil(sum / counted)
      card.levels[level_cap] = level
    end
    return level
  end

  --- CMND_GET_TEAM_SET_INFO of a stored card: true, the value; false for a field the team lists do not show.
  function C.stored_info(card, field, extra, level_cap)
    if field == C.FIELD.LEVEL then
      return true, C.stored_level(card, level_cap or 0)
    elseif field == C.FIELD.FORMATION then
      return true, card.formation
    elseif field == C.FIELD.EMBLEM then
      return true, card.emblem
    elseif field == C.FIELD.NAME then
      return true, card.name
    elseif field == C.FIELD.UNIFORM then
      return true, card.uniform
    elseif field == C.FIELD.IS_CAPTAIN then
      return true, extra == card.captain
    end
    return false
  end

  --- A team field of a card for its list row, from its dock or its stored fields; `missing` when it is not read.
  function C.field(card, missing, field, extra, level_cap)
    local ok, value
    if card.set == nil then
      ok, value = C.stored_info(card, field, extra, level_cap)
    elseif extra == nil then
      ok, value = VRFW.host.command(C.TEAM_SET_INFO, card.set, C.TEAM, field)
    else
      ok, value = VRFW.host.command(C.TEAM_SET_INFO, card.set, C.TEAM, field, extra)
    end
    if ok and value ~= nil then
      return value
    end
    return missing
  end
end
