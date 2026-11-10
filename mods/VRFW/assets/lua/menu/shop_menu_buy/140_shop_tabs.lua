-- VRFW › shop tab split, menu side.
if VRFW.host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "VRFW.shop_tabs_"

  local CMD = {
    TAB_KEYS = VRFW.commands.VRFW_SHOP_TAB_KEYS,      -- CMND_VRFW_SHOP_TAB_KEYS() -> n, key 1 … key n
    TAB_BIND = VRFW.commands.VRFW_SHOP_TAB_BIND,       -- CMND_VRFW_SHOP_TAB_BIND(key, shop id) -> bound
    TABS = VRFW.commands.VRFW_SHOP_TABS,
    ICON = VRFW.commands.VRFW_IMAGE_ICON,
    REG_FIND = VRFW.commands.VRFW_REG_FIND,
    TEXT_GET = VRFW.commands.TEXT_GET,      -- CMND_TEXT_GET(text id) -> text
    FOCUS_INSTANCE = 2603265800,
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,
    MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,
    SET_SPRITE = 558735651,
  }
  local DMY_ON = 3229351341     -- icon_list_tab_dmy01_on (the tab plate's lit icon)
  local DMY_OFF = 380437824     -- icon_list_tab_dmy01_off (its unfocused icon)
  local ICON_BASE = 4013273506  -- _icon_base01
  local TAB_ITEM = 4044286600   -- cmn06_20_list_tab_item (one plate per tab)
  local TAB_BAR = 1887158505    -- cmn06_01_list_tab_attach (the title bar)
  local TAB_TEXT = 3029561990   -- _text_list_tab01
  local MARK = 0x56540000

  local ST = { bound = false, shop = 0, split = 0, first = 0, tabs = {} }
  VRFW.shop_tabs = ST

  local Log = VRFW.logger.new("vrfw.ShopTabs")

  local function on(point, phase, fn)
    VRFW.host.on(STEM, point, { id = ID .. point, phase = phase, fn = fn })
  end

  local function unsigned(v) return VRFW.ids.unsigned(v) end

  local function set_icon(inst, icon)
    if type(icon) ~= "string" then
      pcall(LISTVIEW.SetupTabIcon, TAB_ITEM, inst, icon, true)
      return
    end
    local has, atlas, sprite = VRFW.host.command(CMD.ICON, icon)
    if has ~= true or type(atlas) ~= "number" or type(sprite) ~= "number" then
      Log("icon " .. icon .. ": not declared (no [[VRFW.Icon]] of that name)")
      return
    end
    VRFW.host.menu_command(CMD.SET_SPRITE, TAB_ITEM, atlas, sprite, DMY_ON, 0, inst)
    VRFW.host.menu_command(CMD.SET_SPRITE, TAB_ITEM, atlas, sprite, DMY_OFF, 0, inst)
    VRFW.host.menu_command(CMD.MESH_VISIBLE, TAB_ITEM, ICON_BASE, true, inst)
  end

  -- the ids of the shops declared by key (once per menu)
  local function bind()
    if ST.bound then return end
    ST.bound = true
    local r = table.pack(VRFW.host.command(CMD.TAB_KEYS))
    if type(r[1]) ~= "number" then return end
    for i = 1, r[1] do
      local key = r[1 + i]
      local id = VRFW.host.command(CMD.REG_FIND, "shop", key)
      if type(id) == "number" and id ~= -1 and id ~= 0 then
        VRFW.host.command(CMD.TAB_BIND, key, unsigned(id))
      end
    end
  end

  -- the split tabs of the open shop (split 0 = none)
  local function load_tabs()
    ST.split, ST.tabs = 0, {}
    local okid, shop = pcall(GetShopId)
    ST.shop = okid and unsigned(shop) or 0
    if ST.shop == 0 then return end
    local r = table.pack(VRFW.host.command(CMD.TABS, ST.shop))
    if type(r[1]) ~= "number" or r[1] == 0 or type(r[2]) ~= "number" then return end
    ST.split = r[1]
    for k = 1, r[2] do
      ST.tabs[k] = { icon = r[1 + 2 * k], text = r[2 + 2 * k] }
    end
  end

  on("OnInit", "before", function()
    ST.bound = false
    bind()
  end)

  on("SetupSlotInfo", "around", function(nxt, n, list)
    bind()
    load_tabs()
    ST.first = 0
    if ST.split == 0 or type(list) ~= "table" or #ST.tabs < 2 then
      return nxt(n, list)
    end
    local out = {}
    for i = 1, (n or #list) do
      local v = list[i]
      if type(v) == "number" and v > MARK and v <= MARK + #ST.tabs then
        out[#out + 1] = ST.split
      elseif v == ST.split and ST.first == 0 then
        ST.first = #out + 1
        out[#out + 1] = v
        local split_already = false
        for j = i + 1, (n or #list) do
          local w = list[j]
          if type(w) == "number" and w > MARK and w <= MARK + #ST.tabs then split_already = true end
        end
        if not split_already then
          for _ = 2, #ST.tabs do out[#out + 1] = ST.split end
        end
      else
        out[#out + 1] = v
      end
    end
    if ST.first == 0 then
      return nxt(n, list)
    end
    local r = table.pack(nxt(#out, out))
    for k, t in ipairs(ST.tabs) do
      set_icon(ST.first + k - 2, t.icon)
    end
    Log(string.format("shop 0x%08X: game tab %d listed as %d tabs (from tab %d)", ST.shop, ST.split, #ST.tabs, ST.first))
    UpdateTabNameByShopSlotType(ST.split)
    return table.unpack(r, 1, r.n)
  end)

  on("UpdateTabNameByShopSlotType", "around", function(nxt, slot, ...)
    local r = table.pack(nxt(slot, ...))
    if ST.first == 0 or slot ~= ST.split then return table.unpack(r, 1, r.n) end
    local index = VRFW.host.menu_command(CMD.FOCUS_INSTANCE, TAB_ITEM)
    if type(index) ~= "number" then index = 0 end
    local tab = ST.tabs[index + 2 - ST.first]
    if tab and tab.text ~= 0 then
      local text = VRFW.host.command(CMD.TEXT_GET, tab.text)
      if type(text) == "string" and text ~= "" then
        VRFW.host.menu_command(CMD.SET_TEXT, TAB_BAR, TAB_TEXT, text, 0)
      end
    end
    return table.unpack(r, 1, r.n)
  end)
end
