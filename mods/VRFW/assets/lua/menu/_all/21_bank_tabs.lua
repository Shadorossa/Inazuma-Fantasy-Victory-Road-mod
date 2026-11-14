-- lua_patch.scope: used
if VRFW.bank_tabs == nil then
  local BT = {
    CMD_TABS = VRFW.commands.VRFW_CARD_FILTER_TABS,     -- CMND_VRFW_CARD_FILTER_TABS() -> n
    CMD_TAB = VRFW.commands.VRFW_CARD_FILTER_TAB,
    CMD_BAR = VRFW.commands.VRFW_CARD_FILTER_TAB_BAR,      -- CMND_VRFW_CARD_FILTER_TAB_BAR(total) -> attach row ids
    SERIES_INFO = VRFW.commands.GET_CHARA_SERIES_INFO,  -- CMND_GET_CHARA_SERIES_INFO(1, id) -> ok, name
    SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,    -- CMND_SET_MENU_TEXT_STRING
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,      -- CMND_SET_LAYER_VISIBLE
    MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE,
    SET_SPRITE = 558735651,
    ATTACH_CLEAR = 4233535095,
    ATTACH_ROW = VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE,
    FOCUSED = 2603265800,
    TAB_ITEM = 4044286600,    -- cmn06_20_list_tab_item
    BAR = 3310065218,         -- cmn06_04_list_tab_attach_11_only
    TEXT_MESH = 3029561990,   -- _text_list_tab01
    DMY_ON = 3229351341,      -- `icon_list_tab_dmy01_on`
    DMY_OFF = 380437824,      -- icon_list_tab_dmy01_off
    ICON_BASE = 4013273506,   -- _icon_base01
    MARK = 1447428096,
    tabs = nil,
    tables = {},              -- stem -> the tab table the screen's code reads
    all_tables = {},          -- stem -> every tab table found (the live one last)
    pagers = {},              -- stem -> VRFW.tab_pager of a paged bar
    caps = {},
    CAPS_LAYER = 1323657004,
    SE_MOVE = 2500047763,     -- sy0005
    TAB_INSTANCES = 13,       -- tab instances of the screens (menus\bank_tabs.toml)
    wrapped = false,
    logs = 0,
  }

  local logger
  --- Internal: Logs through the bank-tabs logger, at most 20 lines.
  function BT.log(...)
    if BT.logs >= 20 then
      return
    end
    --- Internal: count of log lines written by the bank tabs.
    BT.logs = BT.logs + 1
    logger = logger or VRFW.logger.new("VRFW bank_tabs")
    logger(...)
  end

  --- Internal: The declared bank tabs (read once per VM).
  function BT.list()
    if BT.tabs ~= nil then
      return BT.tabs
    end
    --- Internal: list of the bank tabs read from the framework command.
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

  --- Internal: Append the declared tabs to tab table `t` (once each) and make it the table of `stem`.
  function BT.apply(t, stem)
    if type(t) ~= "table" then
      return
    end
    BT.tables[stem] = t
    for i, d in ipairs(BT.list()) do
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
    BT.log(stem, "tabs", #t)
  end

  --- Internal: True when v looks like a retail tab table.
  function BT.is_tab_table(v)
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

  --- Internal: The retail tab tables reachable from locals table L.
  function BT.find(L)
    local found, seen, live = {}, {}, nil
    local function add(v)
      if not seen[v] and BT.is_tab_table(v) then
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
    local dbg = VRFW.debug
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

  --- Internal: The current bank tab of `stem`; nil when there is none.
  function BT.current(stem)
    local t = BT.tables[stem]
    if t == nil then
      return nil
    end
    local i = VRFW.host.menu_command(BT.FOCUSED, BT.TAB_ITEM)
    local e = type(i) == "number" and t[i + 1] or nil
    if e ~= nil and e.vrfwTab ~= nil then
      return e
    end
    return nil
  end

  --- Internal: The filter params with listItemType 2 (team) = `team` in every series.
  function BT.team_filter(params, team)
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

  --- Internal: Wraps the retail list-view icon and number setters once per VM.
  function BT.wrap()
    if BT.wrapped or LISTVIEW == nil then
      return
    end
    --- Internal: true once LISTVIEW.SetupTabIcon is wrapped for the bank tabs.
    BT.wrapped = true
    local icon = LISTVIEW.SetupTabIcon
    LISTVIEW.SetupTabIcon = function(a1, a2, a3, a4, ...)
      local d = type(a3) == "number" and a3 > BT.MARK and BT.list()[a3 - BT.MARK] or nil
      if d == nil then
        return icon(a1, a2, a3, a4, ...)
      end
      a1 = a1 or BT.TAB_ITEM
      if not d.drawn then
        d.drawn = true
        BT.log("icon", d.key, "instance", a2)
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
          BT.log("bar", n, "declared layout")
          return
        end
        BT.log("bar", n, "no declared layout: retail")
      end
      return num(n, layer, ...)
    end
  end

  --- Internal: The tab pager of `stem`; nil when it has no tabs.
  function BT.pager(stem)
    local t = BT.tables[stem]
    if t == nil or VRFW.tab_pager == nil then
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
    local pager = VRFW.tab_pager.new({
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
    if pager:pages() <= 1 then
      return nil
    end
    pager:reset()
    BT.log(stem, "pages", pager:pages(), "per page", per, "pinned", pager.spec.pinned)
    return pager
  end

  --- Internal: The L2 / R2 prompts in the end caps of a paged bar (the engine draws the keys of the device in use).
  function BT.capacity_spec(stem)
    local pager = BT.pagers[stem]
    return {
      layer = BT.CAPS_LAYER,
      slots = {layer = BT.TAB_ITEM, first = 0, last = pager.spec.per_page - 1},
      edge_inset = 24,
    }
  end

  --- Internal: Installs the bank tabs on menu `stem` through VRFW.host.
  function BT.attach(stem)
    if VRFW.host == nil then
      return
    end
    VRFW.host.on(stem, "@edit", {
      id = "menu_engine.bank_tabs",
      fn = function(L)
        BT.wrap()
        if BT.tables[stem] == nil then
          local found = BT.find(L)
          for _, t in ipairs(found) do
            BT.apply(t, stem)       -- the live table last: it becomes BT.tables[stem]
          end
          BT.all_tables[stem] = found
          BT.log(stem, "tab tables", #found)
          BT.pagers[stem] = BT.pager(stem)
        end
      end,
    })
    VRFW.host.on(stem, "OnInit", {
      id = "menu_engine.bank_tabs", phase = "before",
      fn = function()
        local pager = BT.pagers[stem]
        if pager ~= nil and pager.page ~= 1 then
          pager:reset()             -- the screen opens on page 1
        end
        BT.caps[stem] = VRFW.tab_bar_caps ~= nil and VRFW.tab_bar_caps.new() or nil
      end,
    })
    VRFW.host.on(stem, "OnChangeFocus", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, ...)
        local pager = BT.pagers[stem]
        if a1 == BT.TAB_ITEM and pager ~= nil and pager.turning then
          local slot = VRFW.host.menu_command(BT.FOCUSED, BT.TAB_ITEM)
          if slot ~= nil then
            pager:focus(slot)
          end
        end
        return nxt(a1, ...)
      end,
    })
    -- L2 / R2 (the [[screen]]'s OnFunction call) switch the bar's page, only while the screen browses
    VRFW.host.on(stem, "OnFunction", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, a2, ...)
        local pager = BT.pagers[stem]
        local CF = VRFW.card_filter
        local S = CF ~= nil and CF.S[stem] or nil
        if pager == nil or S == nil or S.on or a1 ~= S.fn or (a2 ~= S.prev and a2 ~= S.next)
            or CF.plate_open(stem) or not CF.idle(stem) then
          return nxt(a1, a2, ...)
        end
        local pages = pager:pages()
        local p = a2 == S.next and pager.page % pages + 1 or (pager.page - 2) % pages + 1
        pcall(funcLuaCommand, VRFW.commands.SND_PLAY_SE, BT.SE_MOVE)
        pager:show(p, 0, true)
      end,
    })
    VRFW.host.on(stem, "ChangeSeriesTabByCharaStHdl", {
      id = "menu_engine.bank_tabs", phase = "before",
      fn = function(hdl)
        local pager = BT.pagers[stem]
        if pager == nil or pager.page == 1 or hdl == 0 or GetCharaSeriesType == nil or GetCurrentSeriesType == nil then
          return
        end
        if GetCharaSeriesType(hdl) ~= GetCurrentSeriesType() then
          pager:show(1, pager.spec.pinned, false)
        end
      end,
    })
    VRFW.host.on(stem, "OnOpenLayer", {
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
          VRFW.tab_bar_caps.open(caps, BT.capacity_spec(stem))    -- only a bar with a second page shows the prompts
        end
        return table.unpack(r, 1, r.n)
      end,
    })
    VRFW.host.on(stem, "Step", {
      id = "menu_engine.bank_tabs", phase = "after",
      fn = function()
        local caps = BT.caps[stem]
        if caps ~= nil and caps.pending and BT.pagers[stem] ~= nil then
          VRFW.tab_bar_caps.step(caps, BT.capacity_spec(stem))
        end
      end,
    })
    VRFW.host.on(stem, "SetCharaBankListFilter", {
      id = "menu_engine.bank_tabs", phase = "around",
      fn = function(nxt, a1, a2, ...)
        if a1 == 0 and (IsSeriesSelectEnabled == nil or IsSeriesSelectEnabled()) then
          local e = BT.current(stem)
          if e ~= nil then
            a2 = BT.team_filter(a2, e.evtTeam)
          end
        end
        return nxt(a1, a2, ...)
      end,
    })
    VRFW.host.on(stem, "OnListTabChanged", {
      id = "menu_engine.bank_tabs", phase = "after",
      fn = function()
        local pager = BT.pagers[stem]
        if pager ~= nil and not pager.turning then
          local slot = VRFW.host.menu_command(BT.FOCUSED, BT.TAB_ITEM)
          if type(slot) == "number" then
            pager.slot = slot       -- the focused slot, for the next wrap
          end
        end
        if IsSeriesSelectEnabled ~= nil and not IsSeriesSelectEnabled() then
          return
        end
        local e = BT.current(stem)
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

  --- Internal: Namespace of the bank tabs: extra tab icons and labels added to the bank list views.
  VRFW.bank_tabs = BT
end
