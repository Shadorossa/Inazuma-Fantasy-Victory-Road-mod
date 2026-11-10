-- EVT shop_shortcuts, shop side
BetterUI = type(BetterUI) == "table" and BetterUI or {}
BetterUI.shop_cycle_key = 3441281602 --[[crc32 better_ui_shop_cycle_dir: 1 = next shop, 2 = previous (read by the host menu)]]
BetterUI.shop_host_key = 1245025685 --[[crc32 better_ui_shop_cycle_host: 1 = Mercado (market_menu)]]
BetterUI.shop_hosts = {839500579 --[[market_menu]]}
BetterUI.shop_previous_function = 3762100098
BetterUI.shop_next_function = 1492160491
BetterUI.shop_text_key = "BetterUI.shop_switch"
BetterUI.shop_text_crc = 1948721644 --[[crc32 BetterUI.shop_switch: the framework text id when free]]
BetterUI.shop_menu = 3170360552 --[[shop_menu (this script: shop_menu_buy)]]
BetterUI.shop_basara_menu = 713974531 --[[shop_menu_basara_top: its shops are not the Mercado's]]
BetterUI.shop_wait = 600
BetterUI.shop_leaving = nil
BetterUI.shop_buy = {wrapped = false, guide = false, txt = nil}

function BetterUI.shop_log(...)
  BetterUI.shop_logger = BetterUI.shop_logger or VRFW.logger.new("EVT shop_shortcuts")
  BetterUI.shop_logger(...)
end

function BetterUI.shop_exists(m)
  return funcLuaMenuCommand(@crc:CMND_IS_EXIST_MENU_OBJECT@, m) == true
end

function BetterUI.shop_param(k)
  if not VRFW.param.has(k) then
    return nil
  end
  return VRFW.param.get(k)
end

-- a host waits for this shop (its menu exists) and the shop is not one of shop_menu_basara_top
function BetterUI.shop_can()
  if BetterUI.shop_leaving ~= nil then
    return false
  end
  local h = BetterUI.shop_param(BetterUI.shop_host_key)
  local host = type(h) == "number" and BetterUI.shop_hosts[h] or nil
  return host ~= nil and BetterUI.shop_exists(host) and not BetterUI.shop_exists(BetterUI.shop_basara_menu)
end

function BetterUI.shop_set_key(v)
  if VRFW.param.has(BetterUI.shop_cycle_key) then
    VRFW.param.clear(BetterUI.shop_cycle_key)
  end
  if v ~= nil then
    VRFW.param.set(BetterUI.shop_cycle_key, v)
  end
end

function BetterUI.shop_leave(dir)
  BetterUI.shop_set_key(dir)
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, 2500047763 --[[sy0005]])
  funcLuaMenuCommand(1558704558, BetterUI.shop_menu, false)
  BetterUI.shop_log("leave", dir)
  funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BetterUI.shop_menu)
  for _ = 1, BetterUI.shop_wait do
    coroutine.yield()
  end
  if VRFW.param.has(BetterUI.shop_cycle_key) then
    BetterUI.shop_set_key(nil)
    BetterUI.shop_log("watchdog: the shop is still open; key cleared, shop active again")
    funcLuaMenuCommand(1558704558, BetterUI.shop_menu, true)
  end
end

function BetterUI.shop_resume()
  local ok, err = coroutine.resume(BetterUI.shop_leaving)
  if not ok then
    BetterUI.shop_log("error", tostring(err))
    BetterUI.shop_set_key(nil)
    funcLuaMenuCommand(1558704558, BetterUI.shop_menu, true)
  end
  if not ok or coroutine.status(BetterUI.shop_leaving) == "dead" then
    BetterUI.shop_leaving = nil
  end
end

function BetterUI.shop_text_id()
  if BetterUI.shop_buy.txt == nil then
    local ok, id = pcall(funcLuaCommand, @crc:CMND_VRFW_TEXT_ID@, BetterUI.shop_text_key)
    BetterUI.shop_buy.txt = (ok and type(id) == "number" and id ~= 0) and id or BetterUI.shop_text_crc
  end
  return BetterUI.shop_buy.txt
end

-- Installs the funcLuaMenuCommand wrapper.
function BetterUI.shop_buy_install()
  local real = funcLuaMenuCommand
  if BetterUI.shop_buy.wrapped or type(real) ~= "function" then
    return
  end
  BetterUI.shop_buy.wrapped = true
  funcLuaMenuCommand = function(c, ...)
    if BetterUI.shop_buy.guide and (c == 2209673388 or c == 452337289) then
      local args = table.pack(c, ...)
      if (args[3] == 1138543975 --[[mainmenu01_06_base_button_guide]] or args[3] == 2062970623 --[[shopmenu01_06_base_button_guide]])
          and type(args[4]) == "table" then
        if c == 2209673388 then
          local add = {{0, 619948187 --[[<CMD_FUNCL2>]]}, {BetterUI.shop_text_id(), 3487556099 --[[<CMD_FUNCR2>]]}}
          for _, e in ipairs(add) do
            args[4][#args[4] + 1] = e[1]
            if type(args[5]) == "table" then args[5][#args[5] + 1] = e[2] end
            if type(args[6]) == "table" then args[6][#args[6] + 1] = 18 end
            if type(args[7]) == "table" then args[7][#args[7] + 1] = 0 end
            if type(args[8]) == "table" then args[8][#args[8] + 1] = 0 end
          end
        else
          args[4][#args[4] + 1] = 1970176280 --[[CMD_FUNCL2]]
          args[4][#args[4] + 1] = 2704260807 --[[CMD_FUNCR2]]
          BetterUI.shop_buy.guide = false
        end
        return real(table.unpack(args, 1, args.n))
      end
    end
    return real(c, ...)
  end
end

do
  local fn = OnFunction
  function OnFunction(a1, a2, ...)
    if a1 == BetterUI.shop_previous_function or a1 == BetterUI.shop_next_function then
      local okc, can = pcall(BetterUI.shop_can)
      if okc and can then
        BetterUI.shop_leaving = coroutine.create(BetterUI.shop_leave)
        local ok, err = coroutine.resume(BetterUI.shop_leaving, a1 == BetterUI.shop_next_function and 1 or 2)
        if not ok then
          BetterUI.shop_log("error", tostring(err))
          BetterUI.shop_leaving = nil
        elseif coroutine.status(BetterUI.shop_leaving) == "dead" then
          BetterUI.shop_leaving = nil
        end
        return
      end
    end
    return fn(a1, a2, ...)
  end
  local init = OnInit
  if type(init) == "function" then
    function OnInit(...)
      pcall(BetterUI.shop_buy_install)
      return init(...)
    end
  end
  local step = Step
  function Step(...)
    pcall(BetterUI.shop_buy_install)
    local r = table.pack(step(...))
    if BetterUI.shop_leaving ~= nil then
      BetterUI.shop_resume()
    end
    return table.unpack(r, 1, r.n)
  end
  -- Handles list mode (a1) of a shop that can switch.
  local guide = UpdateButtonGuide
  if type(guide) == "function" then
    function UpdateButtonGuide(a1, ...)
      pcall(BetterUI.shop_buy_install)
      local ok, can = pcall(BetterUI.shop_can)
      BetterUI.shop_buy.guide = a1 and ok and can or false
      local r = table.pack(guide(a1, ...))
      BetterUI.shop_buy.guide = false
      return table.unpack(r, 1, r.n)
    end
  end
end
