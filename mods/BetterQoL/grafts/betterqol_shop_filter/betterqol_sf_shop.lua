-- wrappers.
BetterQoL = BetterQoL or {}
BetterQoL.shop_filter = BetterQoL.shop_filter or {}
BetterQoL.shop_filter_banner = BetterQoL.shop_filter_banner or {}
BetterQoL.shop_filter.SHOP = 3170360552 --[[shop_menu]]
BetterQoL.shop_filter.MENU = 4116121052 --[[item_filter_menu]]
BetterQoL.shop_filter.WIN = 758265787 --[[win07_01_item_filter_list]]
BetterQoL.shop_filter.LIST = 2569990914 --[[shop01_01_list_base]]
BetterQoL.shop_filter.TABS = 4044286600 --[[cmn06_20_list_tab_item]]
BetterQoL.shop_filter.ATTACH = 1887158505 --[[cmn06_01_list_tab_attach]]
BetterQoL.shop_filter.KEY_MENU = 2640949932
BetterQoL.shop_filter.KEY_INV = 2870353710
BetterQoL.shop_filter.BUTTON = 3170216173 --[[CMD_FUNC2]] -- keyboard Tab, the bank's filter key (free on the shop list layer)
BetterQoL.shop_filter.BTN_TEXT = 2352215829
BetterQoL.shop_filter.CMD_SET = 4016203380 --[[CMND_BETTERQOL_SHOP_FILTER_SET]]
BetterQoL.shop_filter.CMD_RESET = 2004653210 --[[CMND_BETTERQOL_SHOP_FILTER_RESET]]
-- shop slot type (tab, 0x118BCA0) -> inventory type of the item filter window
BetterQoL.shop_filter.INV = {[4] = 0, [5] = 1, [6] = 2, [7] = 3, [2] = 4, [3] = 5, [16] = 6, [17] = 11}
BetterQoL.shop_filter.DEFAULT = {[0] = {2}, [1] = {2}, [2] = {2}, [3] = {2}, [4] = {1}, [5] = {1}, [6] = {3, 4, 5}, [11] = {4, 6}}
BetterQoL.shop_filter.PARAMS = {}
BetterQoL.shop_filter.RECV = nil
BetterQoL.shop_filter.CO = nil
BetterQoL.shop_filter.LIVE = false
BetterQoL.shop_filter.WAIT = 900
BetterQoL.shop_filter_banner.LAYER = 4037719016 --[[shop01_11_view_staff]]
BetterQoL.shop_filter_banner.TICK = 0
if BetterQoL.shop_filter.WRAPPED == nil then
  BetterQoL.shop_filter.WRAPPED = {}
end

function BetterQoL.shop_filter.log(...)
  BetterQoL.shop_filter.logger = BetterQoL.shop_filter.logger or VRFW.logger.new("BetterQoL shop_filter")
  BetterQoL.shop_filter.logger(...)
end

function BetterQoL.shop_filter.exists(m)
  return funcLuaMenuCommand(2231168902 --[[CMND_IS_EXIST_MENU_OBJECT?]], m) == true
end

function BetterQoL.shop_filter.slot()
  local ok, s = pcall(GetCurrentSlotType)
  if ok and s ~= nil then
    return s
  end
  return -1
end

function BetterQoL.shop_filter.flat(params)
  local t = {}
  for i = 1, #params do
    local p = params[i]
    t[#t + 1] = p.listItemType
    t[#t + 1] = p.value
    t[#t + 1] = p.option
  end
  return t
end

function BetterQoL.shop_filter.param(key, v)
  if VRFW.param.has(key) then
    VRFW.param.clear(key)
  end
  VRFW.param.set(key, v)
end

function BetterQoL.shop_filter.icon(slot)
  local on = BetterQoL.shop_filter.LIVE and BetterQoL.shop_filter.INV[slot] ~= nil
  funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], BetterQoL.shop_filter.ATTACH, 1037529311 --[[_icon_sort01]], on, 0)
  funcLuaMenuCommand(1505208242 --[[CMND_SET_MENU_TEXT_VISIBLE?]], BetterQoL.shop_filter.ATTACH, 950238781 --[[_text_btn01]], on, 0)
  if on then
    local s = funcLuaCommand(4074371074 --[[CMND_TEXT_GET]], BetterQoL.shop_filter.BTN_TEXT)
    funcLuaMenuCommand(1083631230 --[[CMND_SET_MENU_TEXT_STRING?]], BetterQoL.shop_filter.ATTACH, 950238781 --[[_text_btn01]], s, 0)
  end
end

function BetterQoL.shop_filter.refresh()
  funcLuaMenuCommand(1262569306, BetterQoL.shop_filter.TABS, BetterQoL.shop_filter.LIST)
  funcLuaMenuCommand(306610847, BetterQoL.shop_filter.LIST, 0)
  funcLuaMenuCommand(1778826357, 3747827324 --[[shop01_02_list_item]], 0, true)
end

function BetterQoL.shop_filter.can_open()
  if not BetterQoL.shop_filter.LIVE or BetterQoL.shop_filter.CO ~= nil or (type(BetterUI) == "table" and BetterUI.shop_leaving ~= nil) then
    return nil
  end
  local slot = BetterQoL.shop_filter.slot()
  local inv = BetterQoL.shop_filter.INV[slot]
  if inv == nil then
    return nil
  end
  -- both menu control schemes (a list screen runs MENU_CTRL_WITH_ANALOG_MOVE_FOCUS)
  if funcLuaCommand(4265778440 --[[CMND_CHECK_INPUT_CMD]], 1332654303 --[[MENU_CTRL]], BetterQoL.shop_filter.BUTTON) ~= true
    and funcLuaCommand(4265778440 --[[CMND_CHECK_INPUT_CMD]], 2748927068 --[[MENU_CTRL_WITH_ANALOG_MOVE_FOCUS]], BetterQoL.shop_filter.BUTTON) ~= true then
    return nil
  end
  local why = nil
  if funcLuaCommand(1215256347 --[[CMND_BRIGHT_IS_FADE]]) == true then
    why = "fade"
  elseif BetterQoL.shop_filter.exists(968210065 --[[sub_window]]) then
    why = "sub_window"
  elseif BetterQoL.shop_filter.exists(449578137 --[[general_window]]) then
    why = "general_window"
  elseif BetterQoL.shop_filter.exists(BetterQoL.shop_filter.MENU) then
    why = "filter open"
  elseif BetterQoL.shop_filter.exists(1427722143 --[[personal_plate_menu]]) then
    why = "personal plate"
  end
  if why ~= nil then
    BetterQoL.shop_filter.log("key ignored", slot, why)
    return nil
  end
  return slot, inv
end

-- Opens the retail OpenFilter (item_filter_menu_inc) for the shop.
function BetterQoL.shop_filter.open(slot, inv)
  funcLuaCommand(1917805374, 3848881948 --[[sy0000]])
  funcLuaMenuCommand(1558704558, BetterQoL.shop_filter.SHOP, false)
  BetterQoL.shop_filter.RECV = nil
  BetterQoL.shop_filter.param(BetterQoL.shop_filter.KEY_MENU, BetterQoL.shop_filter.SHOP)
  BetterQoL.shop_filter.param(BetterQoL.shop_filter.KEY_INV, inv)
  BetterQoL.shop_filter.log("open", slot, inv)
  -- the mods' filter sections learn this tab's inventory type and that the shop's list has no player
  pcall(funcLuaCommand, @crc:CMND_BETTERQOL_SHOP_FILTER_COUNT@, inv)
  if VRFW ~= nil and VRFW.item_filter_sections ~= nil then
    VRFW.item_filter_sections.tell(BetterQoL.shop_filter.SHOP, "context", 0)
  end
  funcLuaCommand(433545986 --[[CMND_OPEN_MENU_OBJECT]], BetterQoL.shop_filter.MENU)
  local n = 0
  while n < BetterQoL.shop_filter.WAIT and funcLuaCommand(3693934564 --[[CMND_IS_OPEN_MENU_OBJECT]], BetterQoL.shop_filter.MENU, BetterQoL.shop_filter.WIN) ~= true do
    n = n + 1
    coroutine.yield()
  end
  local p = BetterQoL.shop_filter.PARAMS[slot]
  if p == nil or #p == 0 then
    p = {}
    for _, c in ipairs(BetterQoL.shop_filter.DEFAULT[inv] or {}) do
      p[#p + 1] = {listItemType = 8, value = c, option = 0}
    end
  end
  if #p > 0 then
    local flat = BetterQoL.shop_filter.flat(p)
    funcLuaMenuCommand(986162705 --[[CMND_SEND_ITEM_FILTER_PARAM]], BetterQoL.shop_filter.MENU, #flat, flat)
  end
  while BetterQoL.shop_filter.exists(BetterQoL.shop_filter.MENU) do
    coroutine.yield()
  end
  if BetterQoL.shop_filter.RECV ~= nil then
    BetterQoL.shop_filter.apply(slot, inv, BetterQoL.shop_filter.RECV)
    BetterQoL.shop_filter.RECV = nil
  end
  funcLuaMenuCommand(1558704558, BetterQoL.shop_filter.SHOP, true)
end

function BetterQoL.shop_filter.apply(slot, inv, params)
  -- the game's test takes the game's rows; the mods' filter sections get theirs for this tab's inventory type
  local sections = VRFW ~= nil and VRFW.item_filter_sections or nil
  local flat = BetterQoL.shop_filter.flat(sections ~= nil and sections.saved(params) or params)
  if sections ~= nil then
    sections.send("list", BetterQoL.shop_filter.SHOP, params, inv)
  end
  local ok, live = pcall(funcLuaCommand, BetterQoL.shop_filter.CMD_SET, slot, inv, table.unpack(flat))
  BetterQoL.shop_filter.log("apply", slot, inv, #params, ok and live)
  if not ok or live ~= true then
    return
  end
  BetterQoL.shop_filter.PARAMS[slot] = params
  BetterQoL.shop_filter.refresh()
end

-- the window's params come back to the menu named in the param store (shop_menu) through these engine callbacks
function OnBeforeReceiveFilterParam()
  BetterQoL.shop_filter.RECV = {}
end

function OnReceiveFilterParam(a1, a2, a3)
  if BetterQoL.shop_filter.RECV == nil then
    BetterQoL.shop_filter.RECV = {}
  end
  table.insert(BetterQoL.shop_filter.RECV, {listItemType = a1, value = a2, option = a3})
end

function OnAfterReceiveFilterParam()
end

function BetterQoL.shop_filter.resume(...)
  local ok, err = coroutine.resume(BetterQoL.shop_filter.CO, ...)
  if not ok then
    BetterQoL.shop_filter.log("error", tostring(err))
    funcLuaMenuCommand(1558704558, BetterQoL.shop_filter.SHOP, true)
  end
  if not ok or coroutine.status(BetterQoL.shop_filter.CO) == "dead" then
    BetterQoL.shop_filter.CO = nil
  end
end

function BetterQoL.shop_filter.reset()
  if VRFW ~= nil and VRFW.item_filter_sections ~= nil then
    VRFW.item_filter_sections.send("list", BetterQoL.shop_filter.SHOP, {})
  end
  local ok, live, n = pcall(funcLuaCommand, BetterQoL.shop_filter.CMD_RESET)
  BetterQoL.shop_filter.LIVE = ok and live == true
  return ok and n or 0
end

function BetterQoL.shop_filter.tick()
  if BetterQoL.shop_filter.CO ~= nil then
    BetterQoL.shop_filter.resume()
    return
  end
  local slot, inv = BetterQoL.shop_filter.can_open()
  if slot ~= nil then
    BetterQoL.shop_filter.CO = coroutine.create(BetterQoL.shop_filter.open)
    BetterQoL.shop_filter.resume(slot, inv)
  end
end

function BetterQoL.shop_filter_banner.hide(inst)
  local i = inst or 0
  funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], BetterQoL.shop_filter_banner.LAYER, 672386185 --[[_shop_cut_chr_dmy01]], false, i)
  funcLuaMenuCommand(3405944500 --[[CMND_SET_MESH_VISIBLE]], BetterQoL.shop_filter_banner.LAYER, 2022610798 --[[_shop_cut_parts01]], false, i)
  funcLuaMenuCommand(711242136 --[[CMND_SET_LAYER_VISIBLE]], BetterQoL.shop_filter_banner.LAYER, i, false)
end

function BetterQoL.shop_filter_banner.tick()
  BetterQoL.shop_filter_banner.TICK = BetterQoL.shop_filter_banner.TICK + 1
  if BetterQoL.shop_filter_banner.TICK >= 20 then
    BetterQoL.shop_filter_banner.TICK = 0
    if funcLuaMenuCommand(262659071 --[[CMND_IS_EXIST_LAYER?]], BetterQoL.shop_filter_banner.LAYER) == true
      and funcLuaMenuCommand(1262717583 --[[CMND_IS_LAYER_VISIBLE]], BetterQoL.shop_filter_banner.LAYER, 0) == true then
      BetterQoL.shop_filter_banner.hide(0)
    end
  end
end

-- Wraps callback `name` with make(orig).
function BetterQoL.shop_filter.wrap(name, make, create)
  local H = VRFW.host
  H.on("shop_menu_buy", name, {id = "BetterQoL.shop_filter." .. name, phase = "around", create = create == true, fn = function(nxt, ...)
    return make(nxt)(...)
  end})
end

BetterQoL.shop_filter.wrap("OnShopInit", function(orig)
  return function(...)
    local r = table.pack(orig(...))
    BetterQoL.shop_filter.PARAMS = {}
    -- a filter left by a shop that never closed (title reset) would already have trimmed the first build
    if BetterQoL.shop_filter.reset() > 0 then
      BetterQoL.shop_filter.refresh()
    end
    BetterQoL.shop_filter.icon(BetterQoL.shop_filter.slot())
    return table.unpack(r, 1, r.n)
  end
end)

BetterQoL.shop_filter.wrap("FinalizeMenu", function(orig)
  return function(...)
    pcall(funcLuaCommand, BetterQoL.shop_filter.CMD_RESET)
    if orig ~= nil then
      return orig(...)
    end
  end
end, true)

BetterQoL.shop_filter.wrap("UpdateTabNameByShopSlotType", function(orig)
  return function(a1, ...)
    local r = table.pack(orig(a1, ...))
    BetterQoL.shop_filter.icon(a1)
    return table.unpack(r, 1, r.n)
  end
end)

BetterQoL.shop_filter.wrap("Step", function(orig)
  return function(...)
    local r = table.pack(orig(...))
    BetterQoL.shop_filter.tick()
    BetterQoL.shop_filter_banner.tick()
    return table.unpack(r, 1, r.n)
  end
end)

local function BannerLayerHook(orig)
  return function(a1, a2, ...)
    local r = table.pack(orig(a1, a2, ...))
    if a1 == BetterQoL.shop_filter_banner.LAYER then
      BetterQoL.shop_filter_banner.hide(a2)
    end
    return table.unpack(r, 1, r.n)
  end
end

BetterQoL.shop_filter.wrap("OnSetupLayer", BannerLayerHook)
BetterQoL.shop_filter.wrap("OnOpenLayer", BannerLayerHook)
