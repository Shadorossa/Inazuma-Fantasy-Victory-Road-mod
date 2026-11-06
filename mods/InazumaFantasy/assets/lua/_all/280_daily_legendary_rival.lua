-- Inazuma Fantasy (prefix InazumaFantasy), the «Rival del día» row: the slot team plays the day's team from the moment its
-- match is reserved, through the VS screen, the match, its result and every retry of it. The free-match list and the class
-- window keep the mystery. The list restores the slot team when it opens again (soccer_vs_cpu_list_menu/280_...).
-- The menus that reserve a match call PlayOnReserve: the class window, the list (one-class rows), soccer_top_menu
-- (BetterMenu's Competition hands the reservation over to it). The match is played at the rival's own stadium: the hook
-- replaces the stadium of this row's reservation only (scripts/daily_legendary_rival.lua, rival_stadium); a rival without
-- one keeps the row's. Definitions only: no engine call at load time.
InazumaFantasyDailyRival = {}

InazumaFantasyDailyRival.Log = function(text)
  pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "InazumaFantasy daily rival " .. text)
end

-- the day's answer: { ok, why, day, team, cards, coach, level, done, reward, ... } or nil
InazumaFantasyDailyRival.Ask = function()
  local DR = InazumaFantasyDailyRival
  local day = VRFW_Daily ~= nil and VRFW_Daily.Period("day") or nil
  if day == nil then return nil end
  local ok, r = pcall(funcLuaCommand, VRFW_Crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL"), day)
  if not ok or type(r) ~= "table" then
    DR.Log("day " .. tostring(day) .. ": no answer (" .. tostring(r) .. ")")
    return nil
  end
  return r
end

-- the rival's own stadium for the reservation, nil = the row's stays (`row_map`: the reservation's stadium)
InazumaFantasyDailyRival.Stadium = function(team, row_map)
  local DR = InazumaFantasyDailyRival
  local okh, declared = pcall(funcLuaCommand, VRFW_Crc32("CMND_VRFW_TEAM_HOME_STADIUM"), team)
  if not okh or type(declared) ~= "number" then declared = 0 end
  local ok, map = pcall(funcLuaCommand, VRFW_Crc32("CMND_INAZUMAFANTASY_DAILY_RIVAL_STADIUM"), team, declared, row_map or 0)
  if not ok then
    DR.Log("stadium: no answer (" .. tostring(map) .. "), the row's stays")
    return nil
  end
  if type(map) == "number" and map ~= 0 then return map end
  return nil
end

-- the slot team plays the day's rival; without one it keeps its own team, with a log line.
-- Returns the stadium of the match, nil = the row's stays
InazumaFantasyDailyRival.Play = function(row_map)
  local DR = InazumaFantasyDailyRival
  local r = DR.Ask()
  if r == nil or r.ok ~= true or type(r.cards) ~= "table" or #r.cards == 0 then
    DR.Log("no rival, the row keeps its own team (" .. tostring(r and r.why) .. ")")
    return
  end
  local slot_team = VRFW_Crc32("evt_ct_ft_daily_legendary_rival")
  local oks, done, why = pcall(funcLuaCommand, VRFW_Crc32("CMND_VRFW_TEAM_STAND_IN"), slot_team, r.team, table.unpack(r.cards))
  if not (oks and done == true) then
    DR.Log("stand-in failed: " .. tostring(oks and why or done))
    return
  end
  if type(r.coach) == "number" and r.coach ~= 0 then
    local okc, donec, whyc = pcall(funcLuaCommand, VRFW_Crc32("CMND_VRFW_TEAM_STAND_IN_LOOK"), slot_team, 0, 0, r.coach)
    if not (okc and donec == true) then DR.Log("coach not set: " .. tostring(okc and whyc or donec)) end
  end
  local levels = {}
  for i = 1, #r.cards do levels[i] = r.level end
  local okl, donel, whyl = pcall(funcLuaCommand, VRFW_Crc32("CMND_VRFW_TEAM_MEMBER_LEVELS"), slot_team, r.level, table.unpack(levels))
  if not (okl and donel == true) then DR.Log("member levels not set: " .. tostring(okl and whyl or donel)) end
  DR.Log(string.format("day %d: team 0x%08X, %d player(s) at Lv %d, pool %d, beaten %s", r.day, r.team, #r.cards,
    r.level, r.pool or 0, tostring(r.done)))
  return DR.Stadium(r.team, row_map)
end

-- before the row's match is reserved, in this menu's VM
InazumaFantasyDailyRival.PlayOnReserve = function()
  local game = VRFW_Crc32("inazuma_fantasy_daily_legendary_rival")
  VRFW_Host.HookCommand(VRFW_Cmd.RESERVE_SOCCER, function(nxt, id, reserved, map, ...)
    if type(reserved) == "number" and reserved % 4294967296 == game then
      map = InazumaFantasyDailyRival.Play(map) or map
    end
    return nxt(id, reserved, map, ...)
  end, "InazumaFantasy.daily_rival_reserve")
end
