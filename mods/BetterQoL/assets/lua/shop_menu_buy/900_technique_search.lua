BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.technique_search == nil and VRFW.host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "BetterQoL.TechniqueSearch."
  local SEARCHABLE_TABS = { [16] = true, [17] = true } -- special moves, auras
  local BUSY_MENUS = { "sub_window", "general_window", "item_filter_menu", "personal_plate_menu" }

  local S = { query = "", co = nil, held = true, ids = nil }
  BetterQoL.technique_search = S

  local function hash(name)
    local v = S.ids and S.ids[name]
    if v == nil then
      S.ids = S.ids or {}
      v = VRFW.crc32(name)
      S.ids[name] = v
    end
    return v
  end

  local function Log(...)
    VRFW.host.command(VRFW.commands.VRFW_LOG, "BetterQoL technique_search", ...)
  end

  local function SetShopInput(on)
    funcLuaMenuCommand(VRFW.commands.SET_INPUT_ENABLE_MENU_OBJECT, hash("shop_menu"), on)
  end

  local function CurrentTab()
    local ok, s = pcall(GetCurrentSlotType)
    if ok and type(s) == "number" then
      return s
    end
    return -1
  end

  -- the shop filter's tab rebuild (graft betterqol_shop_filter), else the same three calls
  local function RebuildTab()
    if type(BetterQoL.shop_filter) == "table" and type(BetterQoL.shop_filter.refresh) == "function" then
      BetterQoL.shop_filter.refresh()
      return
    end
    funcLuaMenuCommand(1262569306, hash("cmn06_20_list_tab_item"), hash("shop01_01_list_base"))
    funcLuaMenuCommand(306610847, hash("shop01_01_list_base"), 0)
    funcLuaMenuCommand(1778826357, hash("shop01_02_list_item"), 0, true)
  end


  -- what a confirmed text does in the shop
  local function Apply(query, text)
    if query == "" then
      S.query = ""
      VRFW.host.command(VRFW.commands.BETTERQOL_SHOP_NAME_SET)
      RebuildTab()
      return
    end
    local r = table.pack(VRFW.host.command(VRFW.commands.BETTERQOL_SHOP_NAME_ITEMS))
    local total = type(r[1]) == "number" and r[1] or 0
    local keep = {}
    for i = 2, 1 + total do
      local id = r[i]
      if type(id) == "number" and BetterQoL.text_search.move_name(id):find(query, 1, true) ~= nil then
        keep[#keep + 1] = id
      end
    end
    Log("search", query, "moves", total, "found", #keep)
    if #keep == 0 then
      BetterQoL.text_search.refuse()
    else
      local live = VRFW.host.command(VRFW.commands.BETTERQOL_SHOP_NAME_SET, table.unpack(keep))
      if live == true then
        S.query = text
        RebuildTab()
      else
        Log("search not applied: the shop tab hook is off")
        BetterQoL.text_search.refuse()
      end
    end
  end

  local function Search()
    if not BetterQoL.text_search.run(hash("shop_menu"), hash("betterqol_technique_search_title"), S.query, Apply) then
      Log("text entry did not open")
    end
  end

  local function KeyPressed()
    local key = hash("CMD_BETTERQOL_TECHNIQUE_SEARCH")
    for _, ctrl in ipairs({ "MENU_CTRL", "MENU_CTRL_WITH_ANALOG_MOVE_FOCUS" }) do
      if funcLuaCommand(VRFW.commands.CHECK_INPUT_CMD, hash(ctrl), key) == true then
        return true
      end
    end
    return false
  end

  local function CanOpen()
    if not SEARCHABLE_TABS[CurrentTab()] or (type(BetterQoL.shop_filter) == "table" and BetterQoL.shop_filter.CO ~= nil) then
      return false
    end
    if funcLuaCommand(VRFW.commands.BRIGHT_IS_FADE) == true then
      return false
    end
    for _, m in ipairs(BUSY_MENUS) do
      if funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, hash(m)) == true then
        return false
      end
    end
    return true
  end

  local function Resume()
    local ok, err = coroutine.resume(S.co)
    if not ok then
      Log("error", tostring(err))
      SetShopInput(true)
    end
    if not ok or coroutine.status(S.co) == "dead" then
      S.co = nil
    end
  end

  local function Tick()
    if S.co ~= nil then
      Resume()
      return
    end
    local down = KeyPressed()
    local press = down and not S.held
    S.held = down
    if press and CanOpen() then
      S.co = coroutine.create(Search)
      Resume()
    end
  end

  local function on(point, fn, create)
    VRFW.host.on(STEM, point, { id = ID .. point, phase = "around", create = create == true, fn = fn })
  end

  on("OnShopInit", function(nxt, ...)
    local r = table.pack(nxt(...))
    S.query, S.co, S.held = "", nil, true
    return table.unpack(r, 1, r.n)
  end)

  on("FinalizeMenu", function(nxt, ...)
    S.query, S.co = "", nil
    if nxt ~= nil then
      return nxt(...)
    end
  end, true)

  on("Step", function(nxt, ...)
    local r = table.pack(nxt(...))
    local ok, err = pcall(Tick)
    if not ok then
      Log("tick error", tostring(err))
    end
    return table.unpack(r, 1, r.n)
  end)

  -- "<key> Search" at the end of the list's button guide (UpdateButtonGuide(true)) in the searchable tabs
  on("UpdateButtonGuide", function(nxt, list_mode, ...)
    S.list_guide = list_mode and true or false
    local r = table.pack(nxt(list_mode, ...))
    S.list_guide = false
    return table.unpack(r, 1, r.n)
  end)

  if VRFW.footer_prompts ~= nil then
    VRFW.footer_prompts.add({
      name = "BetterQoL.TechniqueSearch",
      menu = STEM,
      text = VRFW.crc32("betterqol_technique_search"),
      icon = VRFW.crc32("betterqol_technique_search_key"),
      command = VRFW.crc32("CMD_BETTERQOL_TECHNIQUE_SEARCH"),
      order = 100,
      when = function()
        return S.list_guide == true and SEARCHABLE_TABS[CurrentTab()] == true
      end,
    })
    VRFW.footer_prompts.attach(STEM, "UpdateButtonGuide",
      { VRFW.crc32("mainmenu01_06_base_button_guide"), VRFW.crc32("shopmenu01_06_base_button_guide") })
  end
end
