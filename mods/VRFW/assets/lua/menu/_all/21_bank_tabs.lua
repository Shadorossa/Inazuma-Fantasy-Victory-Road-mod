-- menu_engine: extra series tabs of the character bank's tab bar (VRFW base feature). Definitions only (this file runs in every script VM, lua\_all): the bank screens'
-- handler files (lua\<stem>\110_bank_tabs.lua) call VRFW_BankTabs.Attach(stem). Nothing here names a series or a mod:
-- the tabs come from the mods' [[bank_tab]] (type card_filter: CMND_VRFW_CARD_FILTER_TABS / _TAB(i) / _TAB_BAR(total)).
--
-- * A tab = one more entry of the screen's retail tab table (`t` of chara_bank_menu / chara_bank_menu_for_search):
--   {tabType = 0, seriesId = <series>, seriesType = 0, tabIconType = <marker>, evtTeam = <team>, vrfwTab = <key>},
--   added once per VM at the host's first callback (@edit on the retail local `t`). The game's list filter knows
--   series types 1-9 only, so the tab sends series type 0 («TODO») plus a belong-team filter (listItemType 2, the
--   team, in all 9 series): the characters of that team, whatever their series (the way a mod's series tabs work;
--   the field name `evtTeam` is theirs, so that mod's merged bank code treats these entries as its own).
-- * Around SetCharaBankListFilter: the team filter while such a tab is the current one; after OnListTabChanged: the
--   tab's name (the series' own name text) instead of the retail «TODO» text; around OnOpenLayer: a tab instance past
--   the table is hidden (the screens get 13 instances: menus\bank_tabs.toml).
-- * LISTVIEW.SetupTabIcon: a marker icon type draws the tab's two sprites; LISTVIEW.UpdateAttachTabNum(n) on the bar
--   enables the attach rows of the layout declared for n tabs ([[bank_tab_bar]]; 12 = the framework's own).
-- A mod whose merged bank code keeps its own copy of the tab table (a signings patch) gets the tabs
-- too: @edit finds every tab-shaped table among the upvalues of the script's functions (BT.Find, EVT_DEBUG) and the
-- live one drives the bar (only the retail `t` got them, the merged code drew 11 tabs and its 12th tab
-- instance, never configured by OnOpenLayer (t[12] = nil there), stayed unattached: a white square at the top-left).
-- Never skip OnSetupLayer of a tab instance: the screen counts them there and opens the bar only once all
-- are set up (OpenListTab). Such a mod may still call VRFW_BankTabs.Apply(its_t, stem) itself before OnInit. Without the framework DLL every command fails: the retail tabs.
-- * Pages (card-filter.md §13): a screen whose [[screen]] declares `tabs_per_page` (CMND_VRFW_CARD_FILTER_TABS(stem))
--   shows its tabs in pages of the bar (VRFW_TabPager, lua\_all\24_tab_pager.lua): page 1 = the retail tabs, later
--   pages = the `pinned_tabs` first tabs + the declared tabs. L2 / R2 (the screen's [[screen]] function / args, the
--   keys of the card filter header, off on the bank) switch the page; L1 / R1 stay inside the page. Each tab table
--   holds the shown page's tabs; the screen opens on page 1.
-- No engine call at load time.
if VRFW_BankTabs == nil then
  local BT = {
    CMD_TABS = VRFW_Cmd.VRFW_CARD_FILTER_TABS,     -- CMND_VRFW_CARD_FILTER_TABS() -> n
    CMD_TAB = VRFW_Cmd.VRFW_CARD_FILTER_TAB,     -- CMND_VRFW_CARD_FILTER_TAB(i) -> key, series, team, atlas, icon, icon_off
    CMD_BAR = VRFW_Cmd.VRFW_CARD_FILTER_TAB_BAR,      -- CMND_VRFW_CARD_FILTER_TAB_BAR(total) -> attach row ids
    LOG = VRFW_Cmd.EVT_LOG,         -- CMND_EVT_LOG
    SERIES_INFO = VRFW_Cmd.GET_CHARA_SERIES_INFO,  -- CMND_GET_CHARA_SERIES_INFO(1, id) -> ok, name
    SET_TEXT = VRFW_Cmd.SET_MENU_TEXT_STRING,    -- CMND_SET_MENU_TEXT_STRING
    VISIBLE = VRFW_Cmd.SET_LAYER_VISIBLE,      -- CMND_SET_LAYER_VISIBLE
    MESH_VISIBLE = VRFW_Cmd.SET_MESH_VISIBLE,
    SET_SPRITE = 558735651,
    ATTACH_CLEAR = 4233535095,
    ATTACH_ROW = VRFW_Cmd.SET_LAYER_ATTACH_LOCATOR_TRACE,
    FOCUSED = 2603265800,
    TAB_ITEM = 4044286600,    -- cmn06_20_list_tab_item
    BAR = 3310065218,         -- cmn06_04_list_tab_attach_11_only
    TEXT_MESH = 3029561990,   -- _text_list_tab01
    DMY_ON = 3229351341,      -- icon_list_tab_dmy01_on
    DMY_OFF = 380437824,      -- icon_list_tab_dmy01_off
    ICON_BASE = 4013273506,   -- _icon_base01
    MARK = 1447428096,        -- tabIconType marker base (0x56460000 + i): never a retail icon type
    tabs = nil,               -- {{key, series, team, atlas, icon, off}, ...} (read once per VM)
    tables = {},              -- stem -> the tab table the screen's code reads
    all_tables = {},          -- stem -> every tab table found (the live one last)
    pagers = {},              -- stem -> VRFW_TabPager of a paged bar
    caps = {},                -- stem -> VRFW_TabBarCaps state (the L2 / R2 prompts at the ends of a paged bar)
    CAPS_LAYER = 1323657004,  -- vrfw_bank_page_keys (2 x team00_40_change_page_guide: menus/bank_tabs.toml)
    SE_MOVE = 2500047763,     -- sy0005
    TAB_INSTANCES = 13,       -- tab instances of the screens (menus\bank_tabs.toml)
    wrapped = false,
    logs = 0,
  }

  function BT.Log(...)
    if BT.logs >= 20 then
      return
    end
    BT.logs = BT.logs + 1
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring((select(i, ...)))
    end
    pcall(funcLuaCommand, BT.LOG, "VRFW bank_tabs " .. table.concat(parts, " "))
  end

  function BT.List()
    if BT.tabs ~= nil then
      return BT.tabs
    end
    BT.tabs = {}
    local ok, n = pcall(funcLuaCommand, BT.CMD_TABS)
    if not ok or type(n) ~= "number" then
      return BT.tabs
    end
    for i = 1, n do
      local r = table.pack(pcall(funcLuaCommand, BT.CMD_TAB, i))
      if r[1] and type(r[2]) == "string" then
        BT.tabs[#BT.tabs + 1] = {key = r[2], series = r[3], team = r[4], atlas = r[5], icon = r[6], off = r[7]}
      else
        break
      end
    end
    return BT.tabs
  end

  -- append the declared tabs to tab table `t` (once each) and make it the table of `stem`
  function BT.Apply(t, stem)
    if type(t) ~= "table" then
      return
    end
    BT.tables[stem] = t
    for i, d in ipairs(BT.List()) do
      local have = false
      for _, e in ipairs(t) do
        if e.vrfwTab == d.key then
          have = true
        end
      end
      if not have then
        t[#t + 1] = {tabType = 0, seriesId = d.series, seriesType = 0, tabIconType = BT.MARK + i, evtTeam = d.team,
          vrfwTab = d.key}
      end
    end
    BT.Log(stem, "tabs", #t)
  end

  -- a screen's tab table: an array of entries {tabType, seriesType, tabIconType, ...} (the retail `t` shape)
  function BT.IsTabTable(v)
    if type(v) ~= "table" or #v < 2 then
      return false
    end
    for i = 1, #v do
      local e = v[i]
      if type(e) ~= "table" or e.tabType == nil or e.seriesType == nil or e.tabIconType == nil then
        return false
      end
    end
    return true
  end

  -- the tab tables of this screen's code: the retail one (host locals map, L.t) and every copy a later patch of the
  -- screen declared (a merged bank script promotes the retail locals and keeps its OWN `local t`, read by its
  -- OnSetupLayer / ChangeTabMode / GetCurrentSeriesType). Found by shape among the upvalues of the script's global
  -- functions (EVT_DEBUG; without it: the retail table only). The live one (the table of the current
  -- GetCurrentSeriesType, else any patched copy, else the retail one) comes last.
  function BT.Find(L)
    local found, seen, live = {}, {}, nil
    local function add(v)
      if not seen[v] and BT.IsTabTable(v) then
        seen[v] = true
        found[#found + 1] = v
      end
      return seen[v] == true
    end
    local ok, rt = pcall(function() return L.t end)
    if not ok then
      rt = nil
    elseif rt ~= nil then
      add(rt)
    end
    local dbg = EVT_DEBUG
    if dbg ~= nil and type(dbg.getupvalue) == "function" then
      local function scan(f, pick)
        for i = 1, 255 do
          local okn, n, v = pcall(dbg.getupvalue, f, i)
          if not okn or n == nil then
            return
          end
          if type(v) == "table" and add(v) and pick and v ~= rt then
            live = v
          end
        end
      end
      for k, f in next, _ENV do
        if type(f) == "function" and type(k) == "string" then
          scan(f, false)
        end
      end
      local cur = rawget(_ENV, "GetCurrentSeriesType")
      if type(cur) == "function" then
        scan(cur, true)
      end
    end
    if live == nil then
      for i = #found, 1, -1 do
        if found[i] ~= rt then
          live = found[i]
          break
        end
      end
    end
    local out = {}
    for _, v in ipairs(found) do
      if v ~= live then
        out[#out + 1] = v
      end
    end
    out[#out + 1] = live
    return out
  end

  -- the tab entry focused on the bar (nil: not a declared tab)
  function BT.Current(stem)
    local t = BT.tables[stem]
    if t == nil then
      return nil
    end
    local ok, i = pcall(funcLuaMenuCommand, BT.FOCUSED, BT.TAB_ITEM)
    local e = ok and type(i) == "number" and t[i + 1] or nil
    if e ~= nil and e.vrfwTab ~= nil then
      return e
    end
    return nil
  end

  -- the filter params with listItemType 2 (team) = `team` in every series
  function BT.TeamFilter(params, team)
    local out = {}
    if params ~= nil then
      for i = 1, #params do
        local p = params[i]
        if p.listItemType ~= 2 and not (p.listItemType == 9 and p.value == 2) then
          out[#out + 1] = p
        end
      end
    end
    for s = 1, 9 do
      out[#out + 1] = {listItemType = 2, value = team, option = s}
    end
    return out
  end

  -- LISTVIEW wrappers (once per VM): marker icons, declared bar layouts
  function BT.Wrap()
    if BT.wrapped or LISTVIEW == nil then
      return
    end
    BT.wrapped = true
    local icon = LISTVIEW.SetupTabIcon
    LISTVIEW.SetupTabIcon = function(a1, a2, a3, a4, ...)
      local d = type(a3) == "number" and a3 > BT.MARK and BT.List()[a3 - BT.MARK] or nil
      if d == nil then
        return icon(a1, a2, a3, a4, ...)
      end
      a1 = a1 or BT.TAB_ITEM
      if not d.drawn then
        d.drawn = true
        BT.Log("icon", d.key, "instance", a2)
      end
      funcLuaMenuCommand(BT.SET_SPRITE, a1, d.atlas, d.icon, BT.DMY_ON, 0, a2)
      funcLuaMenuCommand(BT.SET_SPRITE, a1, d.atlas, d.off, BT.DMY_OFF, 0, a2)
      funcLuaMenuCommand(BT.MESH_VISIBLE, a1, BT.ICON_BASE, a4 ~= false, a2)
    end
    local num = LISTVIEW.UpdateAttachTabNum
    LISTVIEW.UpdateAttachTabNum = function(n, layer, ...)
      if type(n) == "number" and n > 11 and (layer == nil or layer == BT.BAR) then
        local r = table.pack(pcall(funcLuaCommand, BT.CMD_BAR, n))
        if r[1] and r.n >= 1 + n and type(r[2]) == "number" then
          layer = layer or BT.BAR
          funcLuaMenuCommand(BT.ATTACH_CLEAR, layer, 0, false)
          for i = 1, n do
            funcLuaMenuCommand(BT.ATTACH_ROW, layer, 0, r[1 + i], true)
          end
          BT.Log("bar", n, "declared layout")
          return
        end
        BT.Log("bar", n, "no declared layout: retail")
      end
      return num(n, layer, ...)
    end
  end

  -- the bar's pages (nil: one bar): from the screen's [[screen]] tabs_per_page / pinned_tabs
  function BT.Pager(stem)
    local t = BT.tables[stem]
    if t == nil or VRFW_TabPager == nil then
      return nil
    end
    local ok, _, per, pinned = pcall(funcLuaCommand, BT.CMD_TABS, stem)
    if not ok or type(per) ~= "number" or per <= 0 or per > BT.TAB_INSTANCES or #t <= per then
      return nil
    end
    local entries = {}
    for i = 1, #t do
      entries[i] = t[i]
    end
    local pager = VRFW_TabPager.New({
      name = stem, layer = BT.TAB_ITEM, per_page = per, pinned = type(pinned) == "number" and pinned or 0,
      entries = entries,
      show = function(list)
        for _, tt in ipairs(BT.all_tables[stem] or {t}) do
          for i = #tt, 1, -1 do
            tt[i] = nil
          end
          for i, e in ipairs(list) do
            tt[i] = e
          end
        end
      end,
      icon = function(slot, e)
        LISTVIEW.SetupTabIcon(BT.TAB_ITEM, slot, e.tabIconType, true)
      end,
      bar = function(n)
        LISTVIEW.UpdateAttachTabNum(n, BT.BAR)
      end,
      changed = function()
        if type(OnListTabChanged) == "function" then
          OnListTabChanged()
        end
      end,
    })
    if pager:Pages() <= 1 then
      return nil
    end
    pager:Reset()
    BT.Log(stem, "pages", pager:Pages(), "per page", per, "pinned", pager.spec.pinned)
    return pager
  end

  -- the L2 / R2 prompts in the end caps of a paged bar (the engine draws the keys of the device in use)
  function BT.CapSpec(stem)
    local pager = BT.pagers[stem]
    return {
      Layer = BT.CAPS_LAYER,
      Slots = {Layer = BT.TAB_ITEM, First = 0, Last = pager.spec.per_page - 1},
      EdgeInset = 24,
    }
  end

  function BT.Attach(stem)
    if VRFW_Host == nil then
      return
    end
    VRFW_Host.on(stem, "@edit", {
      id = "menu_engine.bank_tabs",
      fn = function(L)
        BT.Wrap()
        if BT.tables[stem] == nil then
          local found = BT.Find(L)
          for _, t in ipairs(found) do
            BT.Apply(t, stem)       -- the live table last: it becomes BT.tables[stem]
          end
          BT.all_tables[stem] = found
          BT.Log(stem, "tab tables", #found)
          BT.pagers[stem] = BT.Pager(stem)
        end
      end,
    })
    VRFW_Host.on(stem, "OnInit", {
      id = "menu_engine.bank_tabs", phase = "before",
      fn = function()
        local pager = BT.pagers[stem]
        if pager ~= nil and pager.page ~= 1 then
          pager:Reset()             -- the screen opens on page 1
        end
        BT.caps[stem] = VRFW_TabBarCaps ~= nil and VRFW_TabBarCaps.New() or nil
      end,
    })
    -- the focus move of a page switch: the screen's own handler rebuilds the list (the pager skips its own rebuild)
    VRFW_Host.on(stem, "OnChangeFocus", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, ...)
        local pager = BT.pagers[stem]
        if a1 == BT.TAB_ITEM and pager ~= nil and pager.turning then
          local ok, slot = pcall(funcLuaMenuCommand, BT.FOCUSED, BT.TAB_ITEM)
          if ok then
            pager:Focus(slot)
          end
        end
        return nxt(a1, ...)
      end,
    })
    -- L2 / R2 (the [[screen]]'s OnFunction call) switch the bar's page, only while the screen browses
    VRFW_Host.on(stem, "OnFunction", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, a2, ...)
        local pager = BT.pagers[stem]
        local CF = VRFW_CardFilter
        local S = CF ~= nil and CF.S[stem] or nil
        if pager == nil or S == nil or S.on or a1 ~= S.fn or (a2 ~= S.prev and a2 ~= S.next)
            or CF.PlateOpen(stem) or not CF.Idle(stem) then
          return nxt(a1, a2, ...)
        end
        local pages = pager:Pages()
        local p = a2 == S.next and pager.page % pages + 1 or (pager.page - 2) % pages + 1
        pcall(funcLuaCommand, VRFW_Cmd.SND_PLAY_SE, BT.SE_MOVE)
        pager:Show(p, 0, true)
      end,
    })
    -- a jump to a character's retail series tab (member swap) while a later page is shown: page 1 first
    VRFW_Host.on(stem, "ChangeSeriesTabByCharaStHdl", {
      id = "menu_engine.bank_tabs", phase = "before",
      fn = function(hdl)
        local pager = BT.pagers[stem]
        if pager == nil or pager.page == 1 or hdl == 0 or GetCharaSeriesType == nil or GetCurrentSeriesType == nil then
          return
        end
        if GetCharaSeriesType(hdl) ~= GetCurrentSeriesType() then
          pager:Show(1, pager.spec.pinned, false)
        end
      end,
    })
    VRFW_Host.on(stem, "OnOpenLayer", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, a2, ...)
        local t = BT.tables[stem]
        if a1 == BT.TAB_ITEM and t ~= nil and type(a2) == "number" and a2 >= #t then
          funcLuaMenuCommand(BT.VISIBLE, a1, a2, false)     -- an instance past the tab table
          return
        end
        local r = table.pack(nxt(a1, a2, ...))
        local caps = BT.caps[stem]
        if a1 == BT.TAB_ITEM and a2 == 0 and caps ~= nil and BT.pagers[stem] ~= nil then
          VRFW_TabBarCaps.Open(caps, BT.CapSpec(stem))    -- only a bar with a second page shows the prompts
        end
        return table.unpack(r, 1, r.n)
      end,
    })
    VRFW_Host.on(stem, "Step", {
      id = "menu_engine.bank_tabs", phase = "after",
      fn = function()
        local caps = BT.caps[stem]
        if caps ~= nil and caps.pending and BT.pagers[stem] ~= nil then
          VRFW_TabBarCaps.Step(caps, BT.CapSpec(stem))
        end
      end,
    })
    VRFW_Host.on(stem, "SetCharaBankListFilter", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, a2, ...)
        if a1 == 0 and (IsSeriesSelectEnabled == nil or IsSeriesSelectEnabled()) then
          local e = BT.Current(stem)
          if e ~= nil then
            a2 = BT.TeamFilter(a2, e.evtTeam)
          end
        end
        return nxt(a1, a2, ...)
      end,
    })
    VRFW_Host.on(stem, "OnListTabChanged", {
      id = "menu_engine.bank_tabs", phase = "after",
      fn = function()
        local pager = BT.pagers[stem]
        if pager ~= nil and not pager.turning then
          local ok, slot = pcall(funcLuaMenuCommand, BT.FOCUSED, BT.TAB_ITEM)
          if ok and type(slot) == "number" then
            pager.slot = slot       -- the focused slot, for the next wrap
          end
        end
        if IsSeriesSelectEnabled ~= nil and not IsSeriesSelectEnabled() then
          return
        end
        local e = BT.Current(stem)
        if e == nil then
          return
        end
        local ok, okc, name = pcall(funcLuaMenuCommand, BT.SERIES_INFO, 1, e.seriesId)
        if ok and okc and type(name) == "string" then
          funcLuaMenuCommand(BT.SET_TEXT, BT.BAR, BT.TEXT_MESH, name)
        end
      end,
    })
  end

  VRFW_BankTabs = BT
end
