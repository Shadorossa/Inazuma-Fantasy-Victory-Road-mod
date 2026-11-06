-- BetterQoL › technique name search, shop side (shop_menu_buy). Ported from the mod Technique Search by YellowAlberto.
-- In the special moves tab of any shop (slot type 16, each of its split tabs too) and the auras tab (17) the key
-- CMD_BETTERQOL_TECHNIQUE_SEARCH (F / pad R3, content\inputs\technique_search.toml) opens the game's text entry; the
-- text is matched against the name of every move of the tab (part of the name; case, accents, «ü» / «ñ» ignored) and
-- the tab is rebuilt with only the matches. The rows come from the shop's own tab builder (scripts\shop_filter.lua),
-- so the goods mods add to a shop are searched like the game's. An empty search shows every move again; a search
-- with no match buzzes and leaves the tab as it was. The search lasts while the shop is open; the bottom button guide
-- of those tabs shows «<key> Search» (VRFW_FooterPrompts). Handlers of the framework's shop_menu_buy host; no engine
-- call at load time.
BetterQoL = type(BetterQoL) == "table" and BetterQoL or {}
if BetterQoL.TechniqueSearch == nil and VRFW_Host ~= nil then
  local STEM = "shop_menu_buy"
  local ID = "BetterQoL.TechniqueSearch."
  local SEARCHABLE_TABS = { [16] = true, [17] = true } -- special moves, auras
  local NAME_FIELD = 4                                  -- CMND_GET_SOCCER_SKILL_INFO(move, 4) -> name text id
  local MOVE_NAME_TEXT = 720417636                      -- a move's name text id -> its text
  local BUSY_MENUS = { "sub_window", "general_window", "item_filter_menu", "personal_plate_menu" }

  local S = { query = "", co = nil, held = true, names = {}, ids = nil }
  BetterQoL.TechniqueSearch = S

  local function hash(name)
    local v = S.ids and S.ids[name]
    if v == nil then
      S.ids = S.ids or {}
      v = VRFW_Crc32(name)
      S.ids[name] = v
    end
    return v
  end

  local function Log(...)
    pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "BetterQoL technique_search", ...)
  end

  local function SetShopInput(on)
    funcLuaMenuCommand(VRFW_Cmd.SET_INPUT_ENABLE_MENU_OBJECT, hash("shop_menu"), on)
  end

  local function CurrentTab()
    local ok, s = pcall(GetCurrentSlotType)
    if ok and type(s) == "number" then
      return s
    end
    return -1
  end

  -- the shop filter's tab rebuild (graft util_shop_filter), else the same three calls
  local function RebuildTab()
    if type(UTIL_SF_Refresh) == "function" then
      UTIL_SF_Refresh()
      return
    end
    funcLuaMenuCommand(1262569306, hash("cmn06_20_list_tab_item"), hash("shop01_01_list_base"))
    funcLuaMenuCommand(306610847, hash("shop01_01_list_base"), 0)
    funcLuaMenuCommand(1778826357, hash("shop01_02_list_item"), 0, true)
  end

  local function Fold(s)
    return BetterQoL.TextSearch.Fold(s)
  end

  -- the folded name of a move item, asked once per item in this VM ("" = no name)
  local function FoldedName(id)
    local cached = S.names[id]
    if cached ~= nil then
      return cached
    end
    local name = ""
    local okc, ok, name_id = pcall(funcLuaCommand, VRFW_Cmd.GET_SOCCER_SKILL_INFO, id, NAME_FIELD)
    if okc and ok and name_id then
      local okt, s = pcall(funcLuaCommand, MOVE_NAME_TEXT, name_id)
      if okt and type(s) == "string" then
        name = Fold(s)
      end
    end
    S.names[id] = name
    return name
  end

  -- what a confirmed text does in the shop (the text entry itself: BetterQoL.TextSearch, assets\lua\_all\text_search.lua)
  local function Apply(query, text)
    if query == "" then
      S.query = ""
      pcall(funcLuaCommand, VRFW_Cmd.BETTERQOL_SHOP_NAME_SET)
      RebuildTab()
      return
    end
    local r = table.pack(pcall(funcLuaCommand, VRFW_Cmd.BETTERQOL_SHOP_NAME_ITEMS))
    local total = (r[1] and type(r[2]) == "number") and r[2] or 0
    local keep = {}
    for i = 3, 2 + total do
      local id = r[i]
      if type(id) == "number" and FoldedName(id):find(query, 1, true) ~= nil then
        keep[#keep + 1] = id
      end
    end
    Log("search", query, "moves", total, "found", #keep)
    if #keep == 0 then
      BetterQoL.TextSearch.Refuse()
    else
      local ok, live = pcall(funcLuaCommand, VRFW_Cmd.BETTERQOL_SHOP_NAME_SET, table.unpack(keep))
      if ok and live == true then
        S.query = text
        RebuildTab()
      else
        Log("search not applied: the shop tab hook is off")
        BetterQoL.TextSearch.Refuse()
      end
    end
  end

  local function Search()
    if not BetterQoL.TextSearch.Run(hash("shop_menu"), hash("betterqol_technique_search_title"), S.query, Apply) then
      Log("text entry did not open")
    end
  end

  local function KeyPressed()
    local key = hash("CMD_BETTERQOL_TECHNIQUE_SEARCH")
    for _, ctrl in ipairs({ "MENU_CTRL", "MENU_CTRL_WITH_ANALOG_MOVE_FOCUS" }) do
      if funcLuaCommand(VRFW_Cmd.CHECK_INPUT_CMD, hash(ctrl), key) == true then
        return true
      end
    end
    return false
  end

  local function CanOpen()
    -- the shop filter's window (UTIL_SF_CO) and Better UI's shop shortcuts (CLEAN_HUD_SS_CO) are read softly
    if not SEARCHABLE_TABS[CurrentTab()] or UTIL_SF_CO ~= nil or CLEAN_HUD_SS_CO ~= nil then
      return false
    end
    if funcLuaCommand(VRFW_Cmd.BRIGHT_IS_FADE) == true then
      return false
    end
    for _, m in ipairs(BUSY_MENUS) do
      if funcLuaMenuCommand(VRFW_Cmd.IS_EXIST_MENU_OBJECT, hash(m)) == true then
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
    VRFW_Host.on(STEM, point, { id = ID .. point, phase = "around", create = create == true, fn = fn })
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

  -- «<key> Search» at the end of the list's button guide in the searchable tabs (UpdateButtonGuide(true) = the list's
  -- guide; the prompt's When reads it while the guide is set)
  on("UpdateButtonGuide", function(nxt, list_mode, ...)
    S.list_guide = list_mode and true or false
    local r = table.pack(nxt(list_mode, ...))
    S.list_guide = false
    return table.unpack(r, 1, r.n)
  end)

  if VRFW_FooterPrompts ~= nil then
    VRFW_FooterPrompts.Add({
      Name = "BetterQoL.TechniqueSearch",
      Menu = STEM,
      Text = VRFW_Crc32("betterqol_technique_search"),
      Icon = VRFW_Crc32("betterqol_technique_search_key"),
      Command = VRFW_Crc32("CMD_BETTERQOL_TECHNIQUE_SEARCH"),
      Order = 100,
      When = function()
        return S.list_guide == true and SEARCHABLE_TABS[CurrentTab()] == true
      end,
    })
    -- the shop sets the main menu's guide or its own (VRFW >= 3.10: a list of guide layers)
    VRFW_FooterPrompts.Attach(STEM, "UpdateButtonGuide",
      { VRFW_Crc32("mainmenu01_06_base_button_guide"), VRFW_Crc32("shopmenu01_06_base_button_guide") })
  end
end
