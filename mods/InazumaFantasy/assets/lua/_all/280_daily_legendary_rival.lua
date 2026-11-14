InazumaFantasy = InazumaFantasy or {}
InazumaFantasy.DailyRivalMenu = {}

local logger
InazumaFantasy.DailyRivalMenu.log = function(text)
  logger = logger or VRFW.logger.new("InazumaFantasy daily rival")
  logger(text)
end

InazumaFantasy.DailyRivalMenu.ask = function()
  local DR = InazumaFantasy.DailyRivalMenu
  local day = VRFW.daily ~= nil and VRFW.daily.period("day") or nil
  if day == nil then return nil end
  local r = VRFW.host.command(VRFW.crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL"), day)
  if type(r) ~= "table" then
    DR.log("day " .. tostring(day) .. ": no answer (" .. tostring(r) .. ")")
    return nil
  end
  return r
end

InazumaFantasy.DailyRivalMenu.stadium = function(team, row_map)
  local DR = InazumaFantasy.DailyRivalMenu
  local declared = VRFW.host.command(VRFW.crc32("CMND_VRFW_TEAM_HOME_STADIUM"), team)
  if type(declared) ~= "number" then declared = 0 end
  local map = VRFW.host.command(VRFW.crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL_STADIUM"), team, declared, row_map or 0)
  if map == nil then
    DR.log("stadium: no answer (" .. tostring(map) .. "), the row's stays")
    return nil
  end
  if type(map) == "number" and map ~= 0 then return map end
  return nil
end

InazumaFantasy.DailyRivalMenu.play = function(row_map)
  local DR = InazumaFantasy.DailyRivalMenu
  local r = DR.ask()
  if r == nil or r.ok ~= true or type(r.cards) ~= "table" or #r.cards == 0 or type(r.slot_team) ~= "number" then
    DR.log("no rival, the row keeps its own team (" .. tostring(r and r.why) .. ")")
    return
  end
  local slot_team = r.slot_team
  local done, why = VRFW.host.command(VRFW.crc32("CMND_VRFW_TEAM_STAND_IN"), slot_team, r.team, table.unpack(r.cards))
  if not (done == true) then
    DR.log("stand-in failed: " .. tostring(why or done))
    return
  end
  if type(r.coach) == "number" and r.coach ~= 0 then
    local donec, whyc = VRFW.host.command(VRFW.crc32("CMND_VRFW_TEAM_STAND_IN_LOOK"), slot_team, 0, 0, r.coach)
    if not (donec == true) then DR.log("coach not set: " .. tostring(whyc or donec)) end
  end
  local levels = {}
  for i = 1, #r.cards do levels[i] = r.level end
  local donel, whyl = VRFW.host.command(VRFW.crc32("CMND_VRFW_TEAM_MEMBER_LEVELS"), slot_team, r.level, table.unpack(levels))
  if not (donel == true) then DR.log("member levels not set: " .. tostring(whyl or donel)) end
  DR.log(string.format("day %d: team 0x%08X, %d player(s) at Lv %d, pool %d, beaten %s", r.day, r.team, #r.cards,
    r.level, r.pool or 0, tostring(r.done)))
  return DR.stadium(r.team, row_map)
end

InazumaFantasy.DailyRivalMenu.play_on_reserve = function()
  local game = VRFW.crc32("inazuma_fantasy_daily_legendary_rival")
  VRFW.host.hook_command(VRFW.commands.RESERVE_SOCCER, function(nxt, id, reserved, map, ...)
    if type(reserved) == "number" and reserved % 4294967296 == game then
      map = InazumaFantasy.DailyRivalMenu.play(map) or map
    end
    return nxt(id, reserved, map, ...)
  end, "InazumaFantasy.daily_rival_reserve")
end
