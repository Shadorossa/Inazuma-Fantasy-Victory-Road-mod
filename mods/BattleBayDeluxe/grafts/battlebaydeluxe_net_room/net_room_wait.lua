-- network_menu's private-room screen as the UI shell of the mod's room
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.net_room_screen = BattleBayDeluxe.net_room_screen or {
  MENU = @crc:network_menu@ --[[crc32 network_menu]],
  TOP = @crc:bb_stadium_top_menu@,
  GRID = @crc:enjoy_team_select_menu@ --[[enjoy_team_select_menu (the menu object; also the online variant's layer group)]],
  GRID_OFFLINE = @crc:enjoy_team_select_menu_offline@ --[[enjoy_team_select_menu_offline: the offline variant's layer group]],
  STATUS = @crc:CMND_VRFW_NET_STATUS@,
  PICKS = @crc:CMND_VRFW_NET_PICKS@,
  REVISION = @crc:CMND_VRFW_NET_REVISION@,
  READY = @crc:CMND_VRFW_NET_READY@,
  START = @crc:CMND_VRFW_NET_START@,
  LEAVE = @crc:CMND_VRFW_NET_LEAVE@,
  INVITE = @crc:CMND_VRFW_NET_INVITE@,
  PICK_ARM = @crc:CMND_BATTLEBAYDELUXE_NET_PICK_ARM@,
  PICKED = @crc:CMND_BATTLEBAYDELUXE_NET_PICKED@,
  TEAM = @crc:CMND_BATTLEBAYDELUXE_NET_TEAM@,
  PICK = @crc:CMND_VRFW_NET_PICK@,
  TEAM_INFO = 2151743654 --[[a team's info (team, 2 = name, 4 = kit, 6 0 = crest), as the Battle Bay grid reads it]],
  MEMBER_ROW = @crc:vs01_13_room_setting_member_list_item@,
  RANK_ICON = @crc:_icon_rank_dmy01@ --[[_icon_rank_dmy01: the online rank badge of a member row]],
  LOG = @crc:CMND_VRFW_LOG@,
  FN_INVITE = 2028025522,
  FN_KICK = 564775998,
  PLATFORM = @crc:CMND_CANCEL_TU_USERNAME@ --[[the local platform type]],
  APP_PLATFORM = @crc:CMND_GET_APP_PLATFORM@,
  OPEN_MENU = @crc:CMND_OPEN_MENU_OBJECT@,
  CLOSE_MENU = @crc:CMND_CLOSE_MENU_OBJECT@,
  IDLE_SECONDS = 1800,
  stage = 0,
  picking = false,  -- the grid is open for this player's room pick
  starting = false, -- the screen's soccer reserve ran: network_menu closes for the match
  leave_pending = false,
  seen = false,
  room = nil,       -- this frame's room snapshot (BattleBayDeluxe.net_room_screen_room)
  frame = 0,
}

-- logs through the game's own funcLuaCommand, never through the shadow
function BattleBayDeluxe.net_room_screen_log(...)
  pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.LOG, "BattleBayDeluxe.net_room", ...)
end

-- Keeps the game's own functions while the shadow is on top.
BattleBayDeluxe.net_room_screen_originals = BattleBayDeluxe.net_room_screen_originals or {}
BattleBayDeluxe.net_room_screen_shadows = BattleBayDeluxe.net_room_screen_shadows or {}
function BattleBayDeluxe.net_room_screen_game_function(k)
  local f = BattleBayDeluxe.net_room_screen_originals[k]
  if f ~= nil then
    return f
  end
  local g = (k == "net" and funcLuaMenuNetworkCommand) or (k == "mp" and funcLuaMenuMultiplayCommand) or funcLuaCommand
  if BattleBayDeluxe.net_room_screen_shadows[g] then
    return function()
      return nil
    end
  end
  return g
end

-- Returns the mod room's snapshot, or nil outside the mod's rooms.
function BattleBayDeluxe.net_room_screen_room()
  local cur = BattleBayDeluxe.net_room_screen.room
  if BattleBayDeluxe.net_room_screen.reading or (cur ~= nil and cur.frame == BattleBayDeluxe.net_room_screen.frame) then
    return cur ~= nil and cur.open and cur or nil
  end
  BattleBayDeluxe.net_room_screen.reading = true
  local flc = BattleBayDeluxe.net_room_screen_game_function("flc")
  local okv, rev = pcall(flc, BattleBayDeluxe.net_room_screen.REVISION)
  rev = okv and rev or -1
  if cur ~= nil and rev ~= -1 and cur.rev == rev then
    cur.frame = BattleBayDeluxe.net_room_screen.frame
    BattleBayDeluxe.net_room_screen.reading = false
    return cur.open and cur or nil
  end
  local ok, phase, role, _, peer, my_ready, peer_ready, _, _, _, my_name = pcall(flc, BattleBayDeluxe.net_room_screen.STATUS)
  local r = { frame = BattleBayDeluxe.net_room_screen.frame, rev = rev, open = false }
  if ok and (phase == "waiting" or phase == "joined" or phase == "started") then
    r.open = true
    r.phase = phase
    r.host = role == "host"
    r.joined = phase ~= "waiting"
    r.count = r.joined and 2 or 1
    r.names = { [0] = r.host and (my_name or "") or (peer or ""), [1] = r.host and (peer or "") or (my_name or "") }
    if not r.joined then
      r.names[1] = ""
    end
    r.me = r.host and 0 or 1
    r.ready = { [r.me] = my_ready == true, [1 - r.me] = peer_ready == true }
    local okp, mine, theirs = pcall(flc, BattleBayDeluxe.net_room_screen.PICKS)
    mine = okp and tonumber(mine) or 0
    theirs = okp and tonumber(theirs) or 0
    r.picks = { [r.me] = mine, [1 - r.me] = theirs }
  end
  BattleBayDeluxe.net_room_screen.room = r
  BattleBayDeluxe.net_room_screen.reading = false
  return r.open and r or nil
end

function BattleBayDeluxe.net_room_screen_ours()
  return BattleBayDeluxe.net_room_screen_room() ~= nil
end

function BattleBayDeluxe.net_room_screen_stage(r, i)
  if i == r.me then
    return BattleBayDeluxe.net_room_screen.stage
  end
  if not r.joined then
    return 0
  end
  if r.phase == "started" then
    return 2
  end
  return r.ready[i] and 1 or 0
end


-- Answers funcLuaMenuNetworkCommand(3275623542, case, ...).
function BattleBayDeluxe.net_room_screen_member(r, case, a, b)
  local idx = (a == -1 or a == nil) and b or a
  idx = tonumber(idx) or -1
  if case == 13 then
    return r.count
  elseif case == 1 then
    return (idx >= 0 and idx < r.count) and r.names[idx] or ""
  elseif case == 15 then
    return idx >= 0 and idx < r.count
  elseif case == 20 then
    return idx + 1
  elseif case == 21 then
    return idx
  elseif case == 22 then
    return (idx >= 0 and idx < r.count) and BattleBayDeluxe.net_room_screen_stage(r, idx) or 0
  elseif case == 23 then
    return BattleBayDeluxe.net_room_screen_game_function("flc")(BattleBayDeluxe.net_room_screen.PLATFORM)
  elseif case == 28 then
    return BattleBayDeluxe.net_room_screen_game_function("flc")(BattleBayDeluxe.net_room_screen.APP_PLATFORM)
  end
  return 0
end

-- Answers funcLuaCommand(1549302719, k, member number).
function BattleBayDeluxe.net_room_screen_setting(r, k, m)
  local idx = (tonumber(m) or 0) - 1
  if idx < 0 or idx >= r.count then
    return k == 1 and false or 255
  end
  if k == 1 then
    return false
  end
  if k == 0 and (r.picks[idx] or 0) == 0 then
    return 255
  end
  return idx
end

function BattleBayDeluxe.net_room_screen_frame_team(r, frame)
  local team = r.picks[tonumber(frame) or -1] or 0
  if team == 0 then
    return "", 0, 0, 0, false, 0
  end
  local flc = BattleBayDeluxe.net_room_screen_game_function("flc")
  local ok, leader, _, level = pcall(flc, BattleBayDeluxe.net_room_screen.TEAM, team)
  local okn, hasn, name = pcall(flc, BattleBayDeluxe.net_room_screen.TEAM_INFO, team, 2)
  local okk, hask, kit = pcall(flc, BattleBayDeluxe.net_room_screen.TEAM_INFO, team, 4)
  local oke, hase, crest = pcall(flc, BattleBayDeluxe.net_room_screen.TEAM_INFO, team, 6, 0)
  name = (okn and hasn and type(name) == "string") and name or ""
  kit = (okk and hask and tonumber(kit)) or 0
  crest = (oke and hase and tonumber(crest)) or 0
  return name, ok and tonumber(level) or 0, crest, ok and tonumber(leader) or 0, false, kit
end

-- Answers funcLuaCommand(829879707, 0, side, spectator, frame, ...).
function BattleBayDeluxe.net_room_screen_set_place(r, _, side)
  if tonumber(side) ~= 255 or (r.picks[r.me] or 0) == 0 then
    return
  end
  pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.PICK, 0)
  BattleBayDeluxe.net_room_screen.picked = false
  BattleBayDeluxe.net_room_screen.room = nil
  BattleBayDeluxe.net_room_screen_log("room pick dropped (Back on the team frame)")
end

function BattleBayDeluxe.net_room_screen_set_stage(r, s)
  s = tonumber(s) or 0
  if s == BattleBayDeluxe.net_room_screen.stage then
    return
  end
  local was = BattleBayDeluxe.net_room_screen.stage
  BattleBayDeluxe.net_room_screen.stage = s
  if (was > 0) ~= (s > 0) and r.phase == "joined" then
    pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.READY, s > 0 and 1 or 0)
  end
  BattleBayDeluxe.net_room_screen_log("ready stage", was, "->", s)
end

-- Answers the host's session start (339001344).
function BattleBayDeluxe.net_room_screen_host_start(r)
  if r.phase == "started" then
    return true
  end
  local ok, done, err = pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.START)
  BattleBayDeluxe.net_room_screen_log("room start", tostring(ok and done), tostring(err))
  return ok and done == true
end

-- Answers the screen's soccer reserve (funcLuaMenuMultiplayCommand 3361958747).
function BattleBayDeluxe.net_room_screen_reserve(r)
  if r.phase ~= "started" or (r.picks[0] or 0) == 0 or (r.picks[1] or 0) == 0 then
    BattleBayDeluxe.net_room_screen_log("soccer reserve refused", tostring(r.phase), tostring(r.picks[0]), tostring(r.picks[1]))
    return false
  end
  BattleBayDeluxe.net_room_screen.starting = true
  BattleBayDeluxe.net_room_screen_log("soccer reserve: the room's local match")
  return true
end

-- Opens the room pick.
function BattleBayDeluxe.net_room_screen_open_grid(open, menu, ...)
  BattleBayDeluxe.net_room_screen.picking = true
  pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.PICK_ARM, 1)
  BattleBayDeluxe.net_room_screen_log("room pick: the Battle Bay grid opens")
  return open(BattleBayDeluxe.net_room_screen.OPEN_MENU, menu, BattleBayDeluxe.net_room_screen.GRID_OFFLINE, ...)
end

-- the hashes of funcLuaCommand answered by the shadow (each gets the room and the call's arguments)
BattleBayDeluxe.net_room_screen_lua_commands = {
  [2903155582] = function(r) return r.host end,
  [33022758] = function(r) return r.me end,                             -- the local member index
  [2655173747] = function(r, i)                                         -- ready stage of a member / of all
    i = tonumber(i) or -1
    if i < 0 then
      if BattleBayDeluxe.net_room_screen.stage < 2 or not r.joined then
        return BattleBayDeluxe.net_room_screen.stage < 1 and 0 or 1
      end
      return (r.phase == "started" or r.ready[1 - r.me]) and 2 or 1
    end
    return BattleBayDeluxe.net_room_screen_stage(r, i)
  end,
  [2730093000] = function(r, s) BattleBayDeluxe.net_room_screen_set_stage(r, s) end,                -- set the local ready stage
  [1549302719] = function(r, k, m) return BattleBayDeluxe.net_room_screen_setting(r, k, m) end,    -- a member's setting
  [2714657400] = function() return true end,                            -- the Battle Bay room
  [524379756] = function() return false end,                            -- the 2 vs 2 room
  [@crc:CMND_IS_NETWORK_ROOM_MATCH@] = function() return false end,                           -- the ranked room (cheat checks)
  [99921238] = function(r, op)                                          -- room match checks
    if op == 0 then return false end
    return true, true
  end,
  [339001344] = function(r) return BattleBayDeluxe.net_room_screen_host_start(r) end,               -- host: session start
  [642319729] = function(r) return r.phase == "started" end,            -- guest: the session started
  [283992225] = function() return true, 1 end,                          -- the team select may open
  [714644454] = function() return BattleBayDeluxe.net_room_screen.picked and 0 or -1 end,          -- the team select's result
  [1904579678] = function(r, k, c)                                      -- a member's profile
    k = tonumber(k) or 0
    if k == 1 then
      return r.names[tonumber(c) or -1] or ""
    elseif k == 2 then
      return BattleBayDeluxe.net_room_screen_game_function("flc")(BattleBayDeluxe.net_room_screen.PLATFORM)
    elseif k == 3 or k == 5 then
      return ""
    end
    return 0
  end,
  [3634046379] = function() return nil end,                             -- a member's platform id
  [@crc:CMND_IS_ERROR_NETWORK@] = function() return false, false end,                    -- CMND_IS_ERROR_NETWORK
  [829879707] = function(r, k, side) BattleBayDeluxe.net_room_screen_set_place(r, k, side) end,    -- this player's place (frame / none)
  [1004008458] = function() end,
  [1885905018] = function() end,
  [2094946649] = function() end,
  [2103770758] = function() end,
  [2316954474] = function() end,
  [473587382] = function() end,
  [4052189765] = function() end,                                        -- room rules sent
  [@crc:CMND_SEND_REPORT_PLAYER@] = function() end,                                        -- report a player
  [@crc:CMND_SEND_KICK_MEMBER@] = function() end,                                        -- kick a member
  [@crc:CMND_RESET_ONLINE@] = function() end,                                        -- CMND_RESET_ONLINE
  [2888362962] = function() end,
  [4217935939] = function() return true end,
  [@crc:CMND_IS_CLOSE_NETWORK@] = function() return true end,                            -- CMND_IS_CLOSE_NETWORK
}

-- the hashes of funcLuaMenuNetworkCommand answered by the shadow
BattleBayDeluxe.net_room_screen_network_commands = {
  [@crc:CMND_GET_INVITE_INFO@] = function(r, case, a, b) return BattleBayDeluxe.net_room_screen_member(r, tonumber(case) or -1, a, b) end,
  [1000640748] = function(r) return r.count - 1 end,
  [10872836] = function(r, frame) return BattleBayDeluxe.net_room_screen_frame_team(r, frame) end,
  [@crc:CMND_MAKE_COMMENT_FACIAL@] = function() return 0, "", 0, 0, 0 end,
  [2375860295] = function() return 2 end,
  [3028448045] = function() return BattleBayDeluxe.net_room_screen.IDLE_SECONDS end,
  [4068635440] = function() end,
  [1362422903] = function() end,
  [@crc:CMND_SET_NETWORK_INFO@] = function() end,
  [@crc:CMND_ON_ERROR_PROC@] = function() end,
  [@crc:CMND_SET_SEARCH_COND@] = function() end,
  [@crc:CMND_SET_RECRUIT_CONFIG@] = function() end,
  [@crc:CMND_SET_RECRUIT_COND@] = function() end,
  [3195473670] = function() end,
  [4287663672] = function() end,
}

-- the shadow functions (put on top by NetRoomScreenWithShadow)
function BattleBayDeluxe.net_room_screen_lua_command(cmd, ...)
  local orig = BattleBayDeluxe.net_room_screen_game_function("flc")
  local r = BattleBayDeluxe.net_room_screen_room()
  if r ~= nil then
    local f = BattleBayDeluxe.net_room_screen_lua_commands[cmd]
    if f ~= nil then
      return f(r, ...)
    end
    if cmd == BattleBayDeluxe.net_room_screen.OPEN_MENU then
      local menu, group = ...
      if menu == BattleBayDeluxe.net_room_screen.GRID and group == BattleBayDeluxe.net_room_screen.GRID then
        return BattleBayDeluxe.net_room_screen_open_grid(orig, menu, select(3, ...))
      end
    elseif cmd == BattleBayDeluxe.net_room_screen.CLOSE_MENU and BattleBayDeluxe.net_room_screen.starting and (...) == BattleBayDeluxe.net_room_screen.TOP then
      -- The retail WaitFade closes the Battle Bay top menu.
      return true
    end
  end
  return orig(cmd, ...)
end

function BattleBayDeluxe.net_room_screen_network_command(cmd, ...)
  local r = BattleBayDeluxe.net_room_screen_room()
  if r ~= nil then
    local f = BattleBayDeluxe.net_room_screen_network_commands[cmd]
    if f ~= nil then
      return f(r, ...)
    end
  end
  return BattleBayDeluxe.net_room_screen_game_function("net")(cmd, ...)
end

function BattleBayDeluxe.net_room_screen_multiplayer_command(cmd, ...)
  local r = BattleBayDeluxe.net_room_screen_room()
  if r ~= nil and cmd == 3361958747 --[[StepReserveStartSoccer]] then
    return BattleBayDeluxe.net_room_screen_reserve(r)
  end
  return BattleBayDeluxe.net_room_screen_game_function("mp")(cmd, ...)
end

BattleBayDeluxe.net_room_screen_shadows[BattleBayDeluxe.net_room_screen_lua_command] = true
BattleBayDeluxe.net_room_screen_shadows[BattleBayDeluxe.net_room_screen_network_command] = true
BattleBayDeluxe.net_room_screen_shadows[BattleBayDeluxe.net_room_screen_multiplayer_command] = true

-- Runs one engine callback of the screen with the shadow on top.
function BattleBayDeluxe.net_room_screen_with_shadow(f, ...)
  local saved = { funcLuaCommand, funcLuaMenuNetworkCommand, funcLuaMenuMultiplayCommand }
  if BattleBayDeluxe.net_room_screen_shadows[saved[1]] then
    return f(...)
  end
  BattleBayDeluxe.net_room_screen_originals.flc, BattleBayDeluxe.net_room_screen_originals.net, BattleBayDeluxe.net_room_screen_originals.mp = saved[1], saved[2], saved[3]
  if not BattleBayDeluxe.net_room_screen_ours() then
    return f(...)
  end
  funcLuaCommand, funcLuaMenuNetworkCommand, funcLuaMenuMultiplayCommand = BattleBayDeluxe.net_room_screen_lua_command, BattleBayDeluxe.net_room_screen_network_command, BattleBayDeluxe.net_room_screen_multiplayer_command
  local r = table.pack(pcall(f, ...))
  funcLuaCommand, funcLuaMenuNetworkCommand, funcLuaMenuMultiplayCommand = saved[1], saved[2], saved[3]
  if not r[1] then
    error(r[2], 0)
  end
  return table.unpack(r, 2, r.n)
end


-- the mod's room out, network_menu closed
function BattleBayDeluxe.net_room_screen_close(why)
  BattleBayDeluxe.net_room_screen_log("leave", tostring(why))
  BattleBayDeluxe.net_room_screen.leave_pending = false
  BattleBayDeluxe.net_room_screen.seen = false
  BattleBayDeluxe.net_room_screen.stage = 0
  pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.LEAVE)
  BattleBayDeluxe.net_room_screen.room = nil
  BattleBayDeluxe.net_room_screen_game_function("flc")(BattleBayDeluxe.net_room_screen.CLOSE_MENU, BattleBayDeluxe.net_room_screen.MENU, true)
end

-- Steps the room pick's grid.
function BattleBayDeluxe.net_room_screen_step_pick()
  if not BattleBayDeluxe.net_room_screen.picking then
    return
  end
  local flc = BattleBayDeluxe.net_room_screen_game_function("flc")
  local okp, team = pcall(flc, BattleBayDeluxe.net_room_screen.PICKED)
  team = okp and tonumber(team) or 0
  local open = funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, BattleBayDeluxe.net_room_screen.GRID)
  if team ~= 0 then
    BattleBayDeluxe.net_room_screen.picking = false
    BattleBayDeluxe.net_room_screen.picked = true
    BattleBayDeluxe.net_room_screen_log("room pick in", VRFW.ids.hex_text(team))
    if open then
      flc(BattleBayDeluxe.net_room_screen.CLOSE_MENU, BattleBayDeluxe.net_room_screen.GRID, true)
    end
  elseif not open then
    BattleBayDeluxe.net_room_screen.picking = false
    pcall(flc, BattleBayDeluxe.net_room_screen.PICK_ARM, 0)
    BattleBayDeluxe.net_room_screen_log("room pick: the grid closed without a pick")
  end
end

-- Wraps the update of the member rows.
do
  Wrap("BattleBayDeluxe.net_room_wait", "UpdatePlayerInfo", { around = function(update, row, ...)
    local r = table.pack(update(row, ...))
    if BattleBayDeluxe.net_room_screen_ours() then
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, BattleBayDeluxe.net_room_screen.MEMBER_ROW, BattleBayDeluxe.net_room_screen.RANK_ICON, false, row)
    end
    return table.unpack(r, 1, r.n)
  end })
end

do
  Wrap("BattleBayDeluxe.net_room_wait", "OnInit", { around = function(init, ...)
    BattleBayDeluxe.net_room_screen.stage, BattleBayDeluxe.net_room_screen.picking, BattleBayDeluxe.net_room_screen.picked, BattleBayDeluxe.net_room_screen.starting = 0, false, false, false
    BattleBayDeluxe.net_room_screen.frame = BattleBayDeluxe.net_room_screen.frame + 1
    if BattleBayDeluxe.net_room_screen_ours() then
      BattleBayDeluxe.net_room_screen_log("the room screen runs on our room (shell)")
    end
    return init(...)
  end })
end

do
  BattleBayDeluxe.net_room_screen_retail_back_error = RequestBackError
  Wrap("BattleBayDeluxe.net_room_wait", "RequestBackError", { around = function(rbe, ...)
    local r = table.pack(rbe(...))
    if BattleBayDeluxe.net_room_screen.seen or BattleBayDeluxe.net_room_screen_ours() then
      BattleBayDeluxe.net_room_screen_log("room error: the room is left once the message is answered")
      BattleBayDeluxe.net_room_screen.leave_pending = true
    end
    return table.unpack(r, 1, r.n)
  end })
end

do
  Wrap("BattleBayDeluxe.net_room_wait", "RequestBack", { around = function(back, ...)
    if not BattleBayDeluxe.net_room_screen_ours() then
      return back(...)
    end
    BattleBayDeluxe.net_room_screen_log("back: our room is left")
    funcLuaMenuCommand(@crc:CMND_MAKE_ACHIEVE_MESSAGE@, BattleBayDeluxe.net_room_screen.MENU, false)
    -- Runs the retail screen cleanup (BGM, timer, stamps, sub windows, team select, cursor).
    if type(BattleBayDeluxe.net_room_screen_retail_back_error) == "function" then
      local ok, err = pcall(BattleBayDeluxe.net_room_screen_retail_back_error)
      if not ok then
        BattleBayDeluxe.net_room_screen_log("cleanup error", tostring(err))
      end
    end
    BattleBayDeluxe.net_room_screen_close("back")
  end })
end

do
  Wrap("BattleBayDeluxe.net_room_wait", "Step", { around = function(step, ...)
    BattleBayDeluxe.net_room_screen.frame = BattleBayDeluxe.net_room_screen.frame + 1
    local r = BattleBayDeluxe.net_room_screen_room()
    if r ~= nil then
      BattleBayDeluxe.net_room_screen.seen = true
      BattleBayDeluxe.net_room_screen_step_pick()
    elseif BattleBayDeluxe.net_room_screen.seen and not BattleBayDeluxe.net_room_screen.starting and not BattleBayDeluxe.net_room_screen.leave_pending then
      -- The mod's room closed under the screen.
      BattleBayDeluxe.net_room_screen_log("our room closed: the room screen closes")
      BattleBayDeluxe.net_room_screen.leave_pending = true
      pcall(BattleBayDeluxe.net_room_screen_retail_back_error)
    end
    if BattleBayDeluxe.net_room_screen.leave_pending and BattleBayDeluxe.net_room_screen_game_function("flc")(898725220 --[[MSG_BUSY]]) ~= true
        and BattleBayDeluxe.net_room_screen_game_function("flc")(682363669 --[[MSG_DONE]]) == true then
      BattleBayDeluxe.net_room_screen_close("room ended")
      return
    end
    return step(...)
  end })
end

do
  Wrap("BattleBayDeluxe.net_room_wait", "OnFunction", { around = function(fn, a1, a2, ...)
    if (a1 == BattleBayDeluxe.net_room_screen.FN_INVITE or a1 == BattleBayDeluxe.net_room_screen.FN_KICK) and BattleBayDeluxe.net_room_screen_ours() then
      if a1 == BattleBayDeluxe.net_room_screen.FN_INVITE then
        local ok, shown = pcall(BattleBayDeluxe.net_room_screen_game_function("flc"), BattleBayDeluxe.net_room_screen.INVITE)
        BattleBayDeluxe.net_room_screen_log("invite (Steam overlay)", tostring(ok and shown))
      else
        BattleBayDeluxe.net_room_screen_log("kick: not in our rooms")
      end
      return
    end
    return fn(a1, a2, ...)
  end })
end

BattleBayDeluxe.net_room_screen_callbacks = { "OnInit", "Step", "PostStep", "OnSetupLayer", "OnOpenLayer", "OnOpenEndLayer", "OnCloseLayer",
  "OnFocusLayerShift", "OnChangeFocus", "OnEnter", "OnDecideFocus", "OnFunction", "OnBack" }
for _, name in ipairs(BattleBayDeluxe.net_room_screen_callbacks) do
  Wrap("BattleBayDeluxe.net_room_shadow", name, { around = function(previous, ...)
    return BattleBayDeluxe.net_room_screen_with_shadow(previous, ...)
  end })
end
