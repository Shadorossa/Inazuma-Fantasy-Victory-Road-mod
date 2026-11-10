BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
BetterQoL.top_bar = type(BetterQoL.top_bar) == "table" and BetterQoL.top_bar or {}
BetterQoL.top_bar.GO_KEY = 2009229711 --[[crc32 betterqol_topbar_go]]
BetterQoL.top_bar.READY_KEY = 1915179208 --[[crc32 betterqol_title_ready]]
BetterQoL.top_bar.LIST_IDX = 2
BetterQoL.top_bar.WAIT = 900            -- frames: the row never got ready -> give up (title shown)
BetterQoL.top_bar.READY_MAX = 2400      -- frames: title_main never reported reading requests -> press anyway
BetterQoL.top_bar.ALIVE = 3600          -- frames after OnEnter: the title is still here -> give up
BetterQoL.top_bar.title = {pending = nil, frames = 0, fired = 0, force = nil, row_ok = false, unready = false}

function BetterQoL.top_bar.log(...)
  BetterQoL.top_bar.logger = BetterQoL.top_bar.logger or VRFW.logger.new("BetterQoL top_bar title")
  BetterQoL.top_bar.logger(...)
end

function BetterQoL.top_bar.take(k)
  if not VRFW.param.has(k) then
    return nil
  end
  local v = VRFW.param.get(k)
  VRFW.param.clear(k)
  return v
end

function BetterQoL.top_bar.give_up(why)
  local T = BetterQoL.top_bar.title
  BetterQoL.top_bar.log("give up", tostring(T.pending), why)
  local fired = T.fired > 0
  T.pending, T.fired, T.force = nil, 0, nil
  funcLuaCommand(609722083, 0, 0.3)
  if fired then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, 24113234 --[[cmn05_01_coursor]], 0, true)
    funcLuaMenuCommand(1558704558, 3874253475 --[[title_menu_2]], true)
  end
end

function BetterQoL.top_bar.step()
  local T = BetterQoL.top_bar.title
  if T.pending == nil then
    return
  end
  T.frames = T.frames + 1
  if T.fired > 0 then
    T.fired = T.fired + 1
    if T.fired > BetterQoL.top_bar.ALIVE then
      BetterQoL.top_bar.give_up("the title did not leave after OnEnter")
    end
    return
  end
  funcLuaCommand(609722083, 1, 0) -- stay black: no title frame between the two menus
  local pos = GetLayerIndexFromItemListIdx(BetterQoL.top_bar.LIST_IDX)
  if not T.row_ok then
    if T.frames > BetterQoL.top_bar.WAIT then
      BetterQoL.top_bar.give_up("the mode row never got ready")
      return
    end
    if T.frames < 30 or IsEnableMenuItemButton(pos, true) ~= true then
      return
    end
    T.row_ok = true
  end
  if not VRFW.param.has(BetterQoL.top_bar.READY_KEY) then
    if T.frames < BetterQoL.top_bar.READY_MAX then
      return
    end
    if not T.unready then
      T.unready = true
      BetterQoL.top_bar.log("title_main never reported reading requests: press anyway", T.frames)
    end
  end
  T.fired = 1
  BetterQoL.top_bar.log("press", tostring(T.pending), pos, T.frames)
  T.force = T.pending
  local ok, r = pcall(OnEnter, 2250456639 --[[title00_07_item_button_upper]], pos)
  T.force = nil
  if not ok then
    T.fired = 0
    BetterQoL.top_bar.give_up("OnEnter error " .. tostring(r))
  elseif r == 1 then
    T.fired = 0
    BetterQoL.top_bar.give_up("OnEnter refused")
  end
end

do
  local init = OnInit
  function OnInit(...)
    local T = BetterQoL.top_bar.title
    local go = BetterQoL.top_bar.take(BetterQoL.top_bar.GO_KEY)
    if type(go) == "number" then
      go = VRFW.ids.unsigned(go) -- a title id above 2^31 may come back signed from the param store
    end
    if VRFW.param.has(BetterQoL.top_bar.READY_KEY) then
      VRFW.param.clear(BetterQoL.top_bar.READY_KEY) -- this title's title_main sets it again
    end
    if type(go) == "number" and go ~= 0 then
      T.pending, T.frames, T.fired, T.force, T.row_ok, T.unready = go, 0, 0, nil, false, false
      BetterQoL.top_bar.log("hand-off", tostring(go))
      funcLuaCommand(609722083, 1, 0)
    end
    return init(...)
  end
  local getid = GetTitleMenuItemId
  function GetTitleMenuItemId(a1, a2)
    if BetterQoL.top_bar.title.force ~= nil then
      return BetterQoL.top_bar.title.force
    end
    return getid(a1, a2)
  end
  local enabled = IsEnableMenuItemButton
  function IsEnableMenuItemButton(a1, a2)
    if BetterQoL.top_bar.title.force ~= nil then
      return true
    end
    return enabled(a1, a2)
  end
  local step = Step
  function Step(...)
    local r = table.pack(step(...))
    local ok, err = pcall(BetterQoL.top_bar.step)
    if not ok then
      BetterQoL.top_bar.log("error", tostring(err))
      BetterQoL.top_bar.title.pending, BetterQoL.top_bar.title.force = nil, nil
      funcLuaCommand(609722083, 0, 0.3)
    end
    return table.unpack(r, 1, r.n)
  end
end
