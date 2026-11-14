-- network_menu
--@lib vrfw_block_helpers.lua#Wrap
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.net_room_top = BattleBayDeluxe.net_room_top or {
  MENU = @crc:network_menu@ --[[crc32 network_menu]],
  WAIT = @crc:network_room_match_wait@ --[[crc32 network_room_match_wait: the private-room layer group]],
  STATUS = @crc:CMND_VRFW_NET_STATUS@,
  REVISION = @crc:CMND_VRFW_NET_REVISION@,
  LEAVE = @crc:CMND_VRFW_NET_LEAVE@,
  opened = false,
  frames = 0,
}

-- The logger is created on the first call.
function BattleBayDeluxe.net_room_top_log(...)
  BattleBayDeluxe.net_room_top.logger = BattleBayDeluxe.net_room_top.logger or VRFW.logger.new("BattleBayDeluxe.net_top")
  BattleBayDeluxe.net_room_top.logger(...)
end

-- Returns the mod room's phase and whether this player hosts it.
function BattleBayDeluxe.net_room_top_state()
  local rev = VRFW.host.command(BattleBayDeluxe.net_room_top.REVISION)
  if rev ~= nil and BattleBayDeluxe.net_room_top.state ~= nil and BattleBayDeluxe.net_room_top.state.rev == rev then
    return BattleBayDeluxe.net_room_top.state.phase, BattleBayDeluxe.net_room_top.state.host
  end
  local phase, role = VRFW.host.command(BattleBayDeluxe.net_room_top.STATUS)
  if type(phase) ~= "string" then
    phase, role = "none", ""
  end
  BattleBayDeluxe.net_room_top.state = { rev = rev or nil, phase = phase, host = role == "host" }
  return phase, role == "host"
end

function BattleBayDeluxe.net_room_top_is_room_phase(phase)
  return phase == "waiting" or phase == "joined" or phase == "started"
end

function BattleBayDeluxe.net_room_top_ours()
  return BattleBayDeluxe.net_room_top_is_room_phase((BattleBayDeluxe.net_room_top_state()))
end

-- leave the mod's room and close this menu (back to the Battle Bay top menu)
function BattleBayDeluxe.net_room_top_leave(why)
  BattleBayDeluxe.net_room_top_log("leave", tostring(why))
  VRFW.host.command(BattleBayDeluxe.net_room_top.LEAVE)
  BattleBayDeluxe.net_room_top.opened = false
  BattleBayDeluxe.net_room_top.frames = 0
  funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.net_room_top.MENU, true)
end

-- Does what the retail create or join does after its EOS lobby step, without that step.
function BattleBayDeluxe.net_room_top_to_room(is_host)
  BattleBayDeluxe.net_room_top_log("our room: the private-room screen opens", tostring(is_host))
  pcall(ResetLayerGroup)
  if VRFW.param.has(2056018466) then
    VRFW.param.clear(2056018466)
  end
  VRFW.param.set(2056018466, 0)
  funcLuaCommand(2014550292, 0, false)
  funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, @crc:cmn05_01_cursor@)
  funcLuaMenuCommand(@crc:CMND_ON_CHANGE_LAYER_GROUP@, BattleBayDeluxe.net_room_top.WAIT)
  funcLuaMenuCommand(3010622924, false)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, @crc:vs01_04_room_condition_background@, 0,
    @crc:offset01@, 2, @crc:Default@)
  funcLuaMenuCommand(@crc:CMND_PLAY_ANIME_TYPE@, @crc:vs01_04_room_condition_background@, 0,
    @crc:offset02@, 0, @crc:Default@)
end

do
  Wrap("BattleBayDeluxe.net_room_top", "Step", { around = function(step, ...)
    local phase, is_host = BattleBayDeluxe.net_room_top_state()
    if BattleBayDeluxe.net_room_top_is_room_phase(phase) then
      if not BattleBayDeluxe.net_room_top.opened then
        -- two frames for the menu's own open, then the room screen
        BattleBayDeluxe.net_room_top.frames = BattleBayDeluxe.net_room_top.frames + 1
        if BattleBayDeluxe.net_room_top.frames >= 2 then
          BattleBayDeluxe.net_room_top.opened = true
          local ok, err = pcall(BattleBayDeluxe.net_room_top_to_room, is_host)
          if not ok then
            BattleBayDeluxe.net_room_top_log("room screen error", tostring(err))
            BattleBayDeluxe.net_room_top_leave("room screen error")
            return
          end
        end
      end
      -- The retail room list's Step is skipped.
      return
    elseif BattleBayDeluxe.net_room_top.opened and phase ~= "started" then
      BattleBayDeluxe.net_room_top_leave("room " .. tostring(phase))
      return
    end
    return step(...)
  end })
end

do
  Wrap("BattleBayDeluxe.net_room_top", "OpenNetworkRoomMatchTop", { around = function(top, ...)
    if BattleBayDeluxe.net_room_top_ours() or BattleBayDeluxe.net_room_top.opened then
      return -- never the retail room list in the mod's room
    end
    return top(...)
  end })
end

do
  Wrap("BattleBayDeluxe.net_room_top", "OnBack", { around = function(back, ...)
    if BattleBayDeluxe.net_room_top_ours() or BattleBayDeluxe.net_room_top.opened then
      BattleBayDeluxe.net_room_top_leave("back")
      return 1
    end
    return back(...)
  end })
end
