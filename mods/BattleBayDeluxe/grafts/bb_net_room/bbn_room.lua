-- BattleBayDeluxe bb_net_room, Battle Bay top menu: the «Multijugador» row opens the «Sala privada» (BBN_Entry of
-- bbn_common.lua, appended before this block) while gameplay mods are enabled; otherwise the retail row.
-- The first Step of the menu gives the Campaña's block back when a room match borrowed it (CMND_BBD_NET_RESTORE: a
-- no-op when none is kept) and hides the framework's compatibility window layers.
-- A Steam invite its host welcomed (CMND_VRFW_NET_INVITE_TARGET names this menu): the menu decides its own
-- «Multijugador» row once its list has the focus, so the room opens by the row's own flow (BBN_EntryRun joins the invite).
-- ------------------------------------------------------------------------------------------------ invite
BBN_AUTO = { rev = nil, wanted = false, frames = 0, co = nil }
BBN_AUTO_MENU = "bb_stadium_top_menu"
BBN_AUTO_READY_FRAMES = 20
BBN_AUTO_MAX_FRAMES = 600

-- the row's list layer and index
function BBN_AutoRow()
  for _, layer in ipairs({ BattleBayDeluxe.NetRoom.LIST_MID, BattleBayDeluxe.NetRoom.LIST_SMALL }) do
    for i = 0, (GetNumUsedButtons(layer) or 0) - 1 do
      local info = GetLitItemInfo(layer, i)
      if info ~= nil and info.menuObjectName == BattleBayDeluxe.NetRoom.ROW then
        return layer, i
      end
    end
  end
  return nil
end

function BBN_AutoStep()
  local A = BBN_AUTO
  if A.co ~= nil then
    local ok, err = coroutine.resume(A.co)
    if not ok then
      BBN_Log("invite: row error", tostring(err))
    end
    if not ok or coroutine.status(A.co) == "dead" then
      A.co = nil
    end
    return
  end
  A.frames = A.frames + 1
  local okr, rev = pcall(funcLuaCommand, BattleBayDeluxe.NetRoom.REVISION)
  if okr and rev ~= A.rev then
    A.rev = rev
    local okt, code, menu = pcall(funcLuaCommand, BattleBayDeluxe.NetRoom.INVITE_TARGET)
    local wanted = okt and type(code) == "string" and code ~= "" and menu == BBN_AUTO_MENU
    if wanted and not A.wanted then
      BBN_Log("invite: welcomed, this menu opens the room", code)
      A.frames = 0
    end
    A.wanted = wanted
  end
  if not A.wanted or A.frames < BBN_AUTO_READY_FRAMES then
    return
  end
  if A.frames > BBN_AUTO_MAX_FRAMES then
    BBN_Log("invite: the list never got ready, the row stays for the player")
    A.wanted = false
    return
  end
  local Q = type(BetterQoL) == "table" and type(BetterQoL.TopBar) == "table" and BetterQoL.TopBar.BbRows or nil
  if Q ~= nil and (Q.row ~= nil or Q.co ~= nil) then
    return
  end
  if BBN_Open(BBN_Status()) then
    BBN_Log("invite: a room is open here, it stays pending")
    A.wanted = false
    return
  end
  local layer, idx = BBN_AutoRow()
  if layer == nil or funcLuaMenuCommand(@crc:CMND_IS_CTRL_FOCUS_ACTIVE@, layer) ~= true then
    return
  end
  if funcLuaCommand(2259183189) == true or funcLuaCommand(@crc:CMND_BRIGHT_IS_FADE@) == true
    or funcLuaCommand(316436678) == true then
    return
  end
  A.wanted = false
  local okn, n, key = pcall(funcLuaCommand, BattleBayDeluxe.NetRoom.NOTICE)
  if okn and key == "vrfw_net_invite_ready" then
    pcall(funcLuaCommand, BattleBayDeluxe.NetRoom.NOTICE_TAKE, n)
  end
  BBN_Log("invite: deciding the row", layer, idx)
  funcLuaMenuCommand(1778826357, layer, idx, true)
  funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, layer, 3313461902 --[[cursor]], idx, GetNumUsedButtons(layer) or 0)
  pcall(SelectListItem, layer)
  BBN_AUTO_JOIN = true
  A.co = coroutine.create(function()
    OnDecideFocus(layer, idx)
  end)
  BBN_AutoStep()
end

-- ------------------------------------------------------------------------------------------------ wraps
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}

do
  local decide = OnDecideFocus
  function OnDecideFocus(a1, a2, ...)
    if a1 == BattleBayDeluxe.NetRoom.LIST_MID or a1 == BattleBayDeluxe.NetRoom.LIST_SMALL then
      local okl, info = pcall(GetLitItemInfo, a1, a2)
      if okl and info ~= nil and info.menuObjectName == BattleBayDeluxe.NetRoom.ROW then
        BBN_LAYER = a1 -- the row's list layer (the retail WaitExecOtherMenu's second argument)
        local ok, handled = pcall(BBN_Entry)
        if not ok then
          BBN_Log("entry error", tostring(handled))
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
    if not BBN_RESTORED then
      BBN_RESTORED = true
      pcall(funcLuaCommand, BattleBayDeluxe.NetRoom.RESTORE)
      -- the framework's compatibility window (content\menus\online_compat.toml layers) hidden until it opens
      if type(VRFW_OnlineCompat) == "table" then
        pcall(VRFW_OnlineCompat.Hide)
      end
    end
    local r = table.pack(step(...))
    local ok, err = pcall(BBN_AutoStep)
    if not ok then
      BBN_Log("invite: error", tostring(err))
      BBN_AUTO.wanted, BBN_AUTO.co = false, nil
    end
    return table.unpack(r, 1, r.n)
  end
end
