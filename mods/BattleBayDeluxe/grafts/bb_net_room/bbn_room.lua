-- Battle Bay top menu: the "Multiplayer" row opens the mod's room (NetRoomEntry) while gameplay mods are enabled; a Steam
-- invite whose host welcomed this game decides that row by itself once its list has the focus.
-- ------------------------------------------------------------------------------------------------ invite
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}
BattleBayDeluxe.net_room_invite = { rev = nil, wanted = false, frames = 0, co = nil }
BattleBayDeluxe.net_room_invite_menu = "bb_stadium_top_menu"
BattleBayDeluxe.net_room_invite_ready_frames = 20
BattleBayDeluxe.net_room_invite_max_frames = 600

function BattleBayDeluxe.net_room_invite_step()
  local A = BattleBayDeluxe.net_room_invite
  if A.co ~= nil then
    local ok, err = coroutine.resume(A.co)
    if not ok then
      BattleBayDeluxe.net_room_log("invite: row error", tostring(err))
    end
    if not ok or coroutine.status(A.co) == "dead" then
      A.co = nil
    end
    return
  end
  A.frames = A.frames + 1
  local rev = VRFW.host.command(BattleBayDeluxe.net_room.REVISION)
  if rev ~= nil and rev ~= A.rev then
    A.rev = rev
    local code, menu = VRFW.host.command(BattleBayDeluxe.net_room.INVITE_TARGET)
    local wanted = type(code) == "string" and code ~= "" and menu == BattleBayDeluxe.net_room_invite_menu
    if wanted and not A.wanted then
      BattleBayDeluxe.net_room_log("invite: welcomed, this menu opens the room", code)
      A.frames = 0
    end
    A.wanted = wanted
  end
  if not A.wanted or A.frames < BattleBayDeluxe.net_room_invite_ready_frames then
    return
  end
  if A.frames > BattleBayDeluxe.net_room_invite_max_frames then
    BattleBayDeluxe.net_room_log("invite: the list never got ready, the row stays for the player")
    A.wanted = false
    return
  end
  -- BetterQoL's top bar is deciding a Battle Bay row: wait for it
  local Q = type(BetterQoL) == "table" and type(BetterQoL.top_bar) == "table" and BetterQoL.top_bar.bb_rows or nil
  if Q ~= nil and (Q.row ~= nil or Q.co ~= nil) then
    return
  end
  if BattleBayDeluxe.net_room_open(BattleBayDeluxe.net_room_status()) then
    BattleBayDeluxe.net_room_log("invite: a room is open here, it stays pending")
    A.wanted = false
    return
  end
  local layer, idx = BattleBayDeluxe.net_room_find_row()
  if layer == nil or funcLuaMenuCommand(@crc:CMND_IS_CTRL_FOCUS_ACTIVE@, layer) ~= true then
    return
  end
  if funcLuaCommand(2259183189) == true or funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) == true
    or funcLuaCommand(316436678) == true then
    return
  end
  A.wanted = false
  local n, key = VRFW.host.command(BattleBayDeluxe.net_room.NOTICE)
  if key == "vrfw_net_invite_ready" then
    VRFW.host.command(BattleBayDeluxe.net_room.NOTICE_TAKE, n)
  end
  BattleBayDeluxe.net_room_log("invite: deciding the row", layer, idx)
  funcLuaMenuCommand(1778826357, layer, idx, true)
  funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, layer, 3313461902 --[[cursor]], idx, GetNumUsedButtons(layer) or 0)
  pcall(SelectListItem, layer)
  BattleBayDeluxe.net_room_invite_accepted = true
  A.co = coroutine.create(function()
    OnDecideFocus(layer, idx)
  end)
  BattleBayDeluxe.net_room_invite_step()
end

-- ------------------------------------------------------------------------------------------------ wraps

do
  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    if a1 == BattleBayDeluxe.net_room.LIST_MID or a1 == BattleBayDeluxe.net_room.LIST_SMALL then
      local okl, info = pcall(GetLitItemInfo, a1, a2)
      if okl and info ~= nil and info.menuObjectName == BattleBayDeluxe.net_room.ROW then
        BattleBayDeluxe.net_room_layer = a1 -- the row's list layer (the retail WaitExecOtherMenu's second argument)
        local ok, handled = pcall(BattleBayDeluxe.net_room_entry)
        if not ok then
          BattleBayDeluxe.net_room_log("entry error", tostring(handled))
          return 1
        end
        if handled then
          return 1
        end
      end
    end
    return decide(a1, a2, ...)
  end
end

do
  local step = Step
  function Step(...)
    -- first Step: the Campaña's block back from a room match, the framework's compatibility window hidden
    if not BattleBayDeluxe.net_room_restored then
      BattleBayDeluxe.net_room_restored = true
      VRFW.host.command(BattleBayDeluxe.net_room.RESTORE)
      if type(VRFW.online_compat) == "table" then
        pcall(VRFW.online_compat.hide)
      end
    end
    local r = table.pack(step(...))
    local ok, err = pcall(BattleBayDeluxe.net_room_invite_step)
    if not ok then
      BattleBayDeluxe.net_room_log("invite: error", tostring(err))
      BattleBayDeluxe.net_room_invite.wanted, BattleBayDeluxe.net_room_invite.co = false, nil
    end
    return table.unpack(r, 1, r.n)
  end
end
