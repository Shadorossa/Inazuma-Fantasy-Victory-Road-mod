VRFW.battle_bay_pages_online = {
  RETAIL = @crc:CMND_VRFW_BB_PAGE_RETAIL@,
  SLOT = @crc:CMND_VRFW_BB_PAGE_SLOT@,
  GRID = 106197494 --[[vs01_43_enjoy_team_select_emblem_icon]],
  LOCK = 892105257 --[[mainmenu90_30_lock_icon]],
}

function VRFW.battle_bay_pages_online.log(...)
  VRFW.battle_bay_pages_online.logger = VRFW.battle_bay_pages_online.logger or VRFW.logger.new("VRFW bb_pages")
  VRFW.battle_bay_pages_online.logger(...)
end

function VRFW.battle_bay_pages_online_retail(why)
  local O = VRFW.battle_bay_pages_online
  local rows = VRFW.host.command(O.RETAIL)
  -- the slots already created get their emblems again (the rest are set up by the game from the rebuilt records)
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, O.GRID) or 0
  -- Rows 0 = the framework found the team select offline (this script also runs for the offline grid).
  if type(rows) == "number" and rows > 0 and SetupEmblemIcon ~= nil then
    for i = 0, n - 1 do
      local team, unlocked, check, lock = funcLuaCommand(O.SLOT, i)
      if type(team) == "number" and team ~= 0 then
        pcall(SetupEmblemIcon, i, team, unlocked == true, check == true)
      end
      -- The rows of the "win it to unlock it" rule are open online.
      if type(lock) == "number" and lock >= 0 and unlocked == true then
        VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, O.LOCK, lock, false)
      elseif type(lock) == "number" and lock >= 0 then
        -- A locked slot's padlock gets the closed look.
        VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, O.LOCK, 868450029 --[[_lock_icon01_off]], true, lock)
        VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, O.LOCK, 3251826719 --[[_lock_icon01_on]], false, lock)
        VRFW.host.menu_command(@crc:CMND_PLAY_ANIME_TYPE@, O.LOCK, lock, 1286797620 --[[Active]], 2, 2274335502 --[[lock]])
      end
    end
  end
  VRFW.battle_bay_pages_online.log(string.format("network variant %s: retail rows %s (0 = offline: extended list), slots %d", why, tostring(rows), n))
end

do
  local init = OnInit
  function OnInit(...)
    local r = table.pack(init(...))
    local ok, err = pcall(VRFW.battle_bay_pages_online_retail, "open")
    if not ok then
      VRFW.battle_bay_pages_online.log("online error " .. tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end
end
