if VRFW.host ~= nil then
  local LIST = 536841765                   -- shop01_21_market_list_item
  local ENTRY_TABLES = {"t", "t2", "t3", "t4", "t5", "t8"}
  local ROW_CURSOR_LOCATORS = {3313461902, 993201699}   -- cursor (shop with tokens), the other cursor locator of a row
  local state = {checked = false, bars = nil, extra = {}}

  local function unsigned(id)
    return VRFW.ids.unsigned_or(id, nil)
  end

  local log = VRFW.logger.new("VRFW market bars")

  -- shop id -> key of the shops whose every row a mod hides
  local function emptied_shops()
    local out = {}
    local count = VRFW.host.command(VRFW.commands.VRFW_REG_COUNT, "shop")
    if type(count) ~= "number" then return out end
    for i = 0, count - 1 do
      local key, id, _, new, _, _, hidden, total = VRFW.host.command(VRFW.commands.VRFW_REG_GET, "shop", i)
      if type(id) == "number" and not new and type(total) == "number" and type(hidden) == "number"
        and total > 0 and hidden >= total then
        out[unsigned(id)] = key
      end
    end
    return out
  end

  local function contact_set_shops()
    local out = {}
    local r = table.pack(VRFW.host.command(VRFW.commands.VRFW_SHOP_SCREENS))
    if type(r[1]) ~= "number" then return out end
    for i = 1, r[1] do
      local shop = r[2 * i]
      if type(shop) == "number" then out[unsigned(shop)] = true end
    end
    return out
  end

  local function leave_emptied_shops(L)
    local emptied, kept = emptied_shops(), contact_set_shops()
    for k = #L.t, 1, -1 do
      local shop = L.t[k]
      if emptied[shop] ~= nil and not kept[shop] then
        log("shop has no row left, its bar leaves the list:", tostring(emptied[shop]))
        for _, name in ipairs(ENTRY_TABLES) do
          table.remove(L[name], k)
        end
      end
    end
  end

  local function hide_extra()
    for index in pairs(state.extra) do
      VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, LIST, index, false)
    end
  end

  VRFW.host.on("market_menu", "OnInit", {id = "VRFW.market_bars", phase = "before", fn = function()
    if state.checked then return end
    state.checked = true
    leave_emptied_shops(VRFW.host.hosts.market_menu.L)
  end})

  -- after what is under the host made its own entries (a mod's bars)
  VRFW.host.on("market_menu", "OnInit", {id = "VRFW.market_bars", phase = "after", fn = function()
    state.bars = #VRFW.host.hosts.market_menu.L.t
  end})

  VRFW.host.on("market_menu", "OnSetupLayer", {id = "VRFW.market_bars", fn = function(nxt, layer, index, ...)
    if layer == LIST and state.bars ~= nil and index >= state.bars then
      state.extra[index] = true
      -- retail setup switches these off per row; CMND_SET_CURSOR_LOCATOR only clears the first GET_CREATE_LAYER_NUM rows
      for _, locator in ipairs(ROW_CURSOR_LOCATORS) do
        VRFW.host.menu_command(VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE, LIST, index, locator, false)
      end
      hide_extra()
      return
    end
    return nxt(layer, index, ...)
  end})

  VRFW.host.on("market_menu", "OnChangeFocus", {id = "VRFW.market_bars", phase = "after", fn = function(_, layer)
    if layer == LIST then hide_extra() end
  end})

  VRFW.host.on("market_menu", "OnDecideFocus", {id = "VRFW.market_bars", fn = function(nxt, layer, index, ...)
    if layer == LIST and state.bars ~= nil and index >= state.bars then return end
    return nxt(layer, index, ...)
  end})

  VRFW.host.hook_command(VRFW.commands.GET_CREATE_LAYER_NUM, function(nxt, ...)
    local _, layer = ...
    local count = nxt(...)
    if layer == LIST and select("#", ...) == 2 and state.bars ~= nil and type(count) == "number" then
      return math.min(count, state.bars)
    end
    return count
  end, "VRFW.market_bars", {menu = true})
end
