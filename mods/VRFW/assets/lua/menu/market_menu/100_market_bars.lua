-- VRFW › the Mercado's bars follow the shops: a shop with every row hidden by a mod (`hide`, `hide_spirits`;
-- docs/framework/types/shop.md) leaves the list. A shop that opens a contact set ([[VRFW.ShopRedirect]] contact_set)
-- keeps its bar: its menu entry still opens something.
-- The per-entry tables are the retail chunk's locals (t shop, t2 header icon, t3 background, t4 base, t5 name, t8 icon).
-- A list layer with more instances than shops hides the extra ones: its count answers the shops, setup and decide
-- do nothing there.
-- Handlers of the framework's host; engine calls only inside the game's callbacks.
if VRFW_Host ~= nil then
  local LIST = 536841765                   -- shop01_21_market_list_item
  local ENTRY_TABLES = {"t", "t2", "t3", "t4", "t5", "t8"}
  local state = {checked = false, bars = nil, extra = {}}

  local function unsigned(id)
    return VRFW_Id.u32_or(id, nil)
  end

  local function log(...)
    pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "VRFW market bars", ...)
  end

  -- shop id -> key of the shops whose every row a mod hides
  local function emptied_shops()
    local out = {}
    local ok, count = pcall(funcLuaCommand, VRFW_Cmd.VRFW_REG_COUNT, "shop")
    if not ok or type(count) ~= "number" then return out end
    for i = 0, count - 1 do
      local got, key, id, _, new, _, _, hidden, total = pcall(funcLuaCommand, VRFW_Cmd.VRFW_REG_GET, "shop", i)
      if got and type(id) == "number" and not new and type(total) == "number" and type(hidden) == "number"
        and total > 0 and hidden >= total then
        out[unsigned(id)] = key
      end
    end
    return out
  end

  -- the shops whose menu entries open a contact set (CMND_VRFW_SHOP_SCREENS: n, from 1, set 1, ...)
  local function contact_set_shops()
    local out = {}
    local r = table.pack(pcall(funcLuaCommand, VRFW_Cmd.VRFW_SHOP_SCREENS))
    if not r[1] or type(r[2]) ~= "number" then return out end
    for i = 1, r[2] do
      local shop = r[1 + 2 * i]
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
      pcall(funcLuaMenuCommand, VRFW_Cmd.SET_LAYER_VISIBLE, LIST, index, false)
    end
  end

  VRFW_Host.on("market_menu", "OnInit", {id = "VRFW.market_bars", phase = "before", fn = function()
    if state.checked then return end
    state.checked = true
    leave_emptied_shops(VRFW_Host.hosts.market_menu.L)
  end})

  -- after what is under the host made its own entries (a mod's bars)
  VRFW_Host.on("market_menu", "OnInit", {id = "VRFW.market_bars", phase = "after", fn = function()
    state.bars = #VRFW_Host.hosts.market_menu.L.t
  end})

  VRFW_Host.on("market_menu", "OnSetupLayer", {id = "VRFW.market_bars", fn = function(nxt, layer, index, ...)
    if layer == LIST and state.bars ~= nil and index >= state.bars then
      state.extra[index] = true
      hide_extra()
      return
    end
    return nxt(layer, index, ...)
  end})

  VRFW_Host.on("market_menu", "OnChangeFocus", {id = "VRFW.market_bars", phase = "after", fn = function(_, layer)
    if layer == LIST then hide_extra() end
  end})

  VRFW_Host.on("market_menu", "OnDecideFocus", {id = "VRFW.market_bars", fn = function(nxt, layer, index, ...)
    if layer == LIST and state.bars ~= nil and index >= state.bars then return end
    return nxt(layer, index, ...)
  end})

  VRFW_Host.HookCommand(VRFW_Cmd.GET_CREATE_LAYER_NUM, function(nxt, ...)
    local _, layer = ...
    local count = nxt(...)
    if layer == LIST and select("#", ...) == 2 and state.bars ~= nil and type(count) == "number" then
      return math.min(count, state.bars)
    end
    return count
  end, "VRFW.market_bars", {menu = true})
end
