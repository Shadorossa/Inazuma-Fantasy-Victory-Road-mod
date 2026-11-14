
--- Advanced: tab state of the free match list (VRFW.free_match_tabs).
VRFW.free_match_tabs = VRFW.free_match_tabs or {}
--- Namespace: hooks mods add to the free match list tabs.
VRFW.free_match_tab_hooks = VRFW.free_match_tab_hooks or {}

local FMT = {
  TABS = VRFW.commands.VRFW_FM_TABS,         -- CMND_VRFW_FM_TABS () -> extra, total
  TAB = VRFW.commands.VRFW_FM_TAB,
  BAR = VRFW.commands.VRFW_FM_BAR,          -- CMND_VRFW_FM_BAR (total) -> bar sprite, attach rows...
  TEXT_GET = VRFW.commands.TEXT_GET,     -- CMND_TEXT_GET
  SERIES_INFO = VRFW.commands.GET_CHARA_SERIES_INFO,   -- CMND_GET_CHARA_SERIES_INFO
  SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING,     -- CMND_SET_MENU_TEXT_STRING
  LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE, -- CMND_SET_LAYER_VISIBLE
  MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE, -- CMND_SET_MESH_VISIBLE
  SET_SPRITE = 558735651,
  ATTACH_CLEAR = 4233535095,
  ATTACH_ROW = VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE,
  FOCUS_COUNT = 3252599449,
  FOCUSED = 2603265800,
  FOCUS_SET = 1778826357,
  SET_TEMP_BYTE = VRFW.commands.SET_TEMP_BYTE_FLAG, -- CMND_SET_TEMP_BYTE_FLAG
  SAVED_TAB = 3683890655,    -- The temp byte the screen keeps its tab in.
  TAB_ITEM = 4044286600,     -- cmn06_20_list_tab_item
  ATTACH = 1887158505,       -- cmn06_01_list_tab_attach
  BAR_ATLAS = 3062127414,    -- #/menu/20_cmn/cmn06/cmn06_01/cmn06_01.g4tx
  BAR_MESH = 2452509419,     -- list_tab_base01
  DMY_ON = 3229351341,       -- `icon_list_tab_dmy01_on`
  DMY_OFF = 380437824,       -- icon_list_tab_dmy01_off
  ICON_BASE = 4013273506,    -- _icon_base01
  TEXT_MESH = 3029561990,    -- _text_list_tab01
  RETAIL = 9,
  INSTANCES = 12,
  SECTION_PREV = 1023782679,
  SECTION_NEXT = 2244491134, -- CMD_FUNCTION vrfw_fm_section_page_next (R2 row)
  SECTION_SLOTS = VRFW.commands.VRFW_FM_SECTION_SLOTS, -- CMND_VRFW_FM_SECTION_SLOTS (index of slot 0, ...) -> live
  KEYS = 2626711995,         -- vrfw_fm_section_keys (2 x team00_40_change_page_guide)
  KEY_LEFT = "<CMD_FUNCL2>", KEY_RIGHT = "<CMD_FUNCR2>",   -- the engine draws the bound button of the device in use
  PLAY_ANIME = VRFW.commands.PLAY_ANIME_TYPE,
  ANIME_FOCUS = 2734777837,  -- Focus: the tab's selected look (blue plate, lit icon)
  ANIME_SET_BUTTON = 973515837, -- button
  page = nil,                -- the shown page (nil / 1 = the retail page)
  focus_pending = false,
  GAME_TEAM = 2204933160,    -- (game) -> has, the team of the game's first row
  TEAM_INFO = 2151743654,    -- (team, 2) -> has, the team's name
  row_logged = false,
  focus_slot = nil,
  opening = false,           -- true while the retail OnOpenLayer of a tab instance runs
  retail_icon = {},
  keys = VRFW.tab_bar_caps.new(),
  tabs = nil,
  logs = 0,
}

local capped_logger = VRFW.logger.new("VRFW fm_tabs")
local function FMT_Log(...)
  if FMT.logs >= 20 then
    return
  end
  FMT.logs = FMT.logs + 1
  capped_logger.debug(...)
end

-- the extra tabs the DLL serves (cached), then the mods' count hooks (e.g. a mode that shows fewer)
local function FMT_All()
  if FMT.tabs ~= nil then
    return FMT.tabs
  end
  FMT.tabs = {}
  local n = VRFW.host.command(FMT.TABS)
  if type(n) ~= "number" then
    return FMT.tabs
  end
  for i = 1, n do
    local r = table.pack(VRFW.host.command(FMT.TAB, i))
    if type(r[1]) == "number" then
      FMT.tabs[#FMT.tabs + 1] = {index = r[1], id = r[2], text = r[3], series = r[4], atlas = r[5], icon = r[6],
        off = r[7], itype = r[8], page = type(r[9]) == "number" and r[9] or 1, slot = type(r[10]) == "number" and r[10] or r[1]}
    else
      break
    end
  end
  FMT_Log("tabs", #FMT.tabs)
  return FMT.tabs
end

local function FMT_Count()
  local n = #FMT_All()
  for _, h in pairs(VRFW.free_match_tab_hooks) do
    if type(h) == "table" and type(h.count) == "function" then
      local ok, m = pcall(h.count, n, FMT.tabs)
      if ok and type(m) == "number" and m >= 0 and m < n then
        n = m
      end
    end
  end
  return n
end

-- a kept tab by its tab index
local function FMT_Tab(index)
  local all = FMT_All()
  for k = 1, FMT_Count() do
    if all[k] ~= nil and all[k].index == index then
      return all[k]
    end
  end
  return nil
end

-- tabs on page 1 of the bar: the retail ones + the kept extra tabs of page 1
local function FMT_Page1Total()
  local n = FMT.RETAIL
  local all = FMT_All()
  for k = 1, FMT_Count() do
    if all[k] ~= nil and (all[k].page or 1) <= 1 then
      n = n + 1
    end
  end
  return n
end

-- Internal: the tab index of extra tab `id` (nil: not declared / no framework DLL); for mods (call it inside a callback)
function VRFW.free_match_tabs.index(id)
  for _, t in ipairs(FMT_All()) do
    if t.id == id then
      return t.index
    end
  end
  return nil
end

-- attach set and bar for `total` tabs (the retail script asked for 9)
local function FMT_Bar(orig, total, layer)
  if total <= FMT.RETAIL then
    return orig(total, layer)
  end
  if total == FMT.RETAIL + 1 then
    orig(total, layer)                            -- the retail 10-tab set, as the spirit list's
    LISTVIEW.SetBgTextureListTab(4, layer)         -- the retail 10-tab bar
    return
  end
  local r = table.pack(VRFW.host.command(FMT.BAR, total))
  if type(r[1]) ~= "number" or r.n < 1 + total then
    FMT_Log("no bar layout for", total)
    orig(FMT.RETAIL + 1, layer)
    LISTVIEW.SetBgTextureListTab(4, layer)
    return
  end
  funcLuaMenuCommand(FMT.ATTACH_CLEAR, layer, 0, false)
  for i = 1, total do
    funcLuaMenuCommand(FMT.ATTACH_ROW, layer, 0, r[1 + i], true)
  end
  LISTVIEW.SetBgTextureListTab(4, layer)
  if r[1] ~= 0 then
    funcLuaMenuCommand(FMT.SET_SPRITE, layer, FMT.BAR_ATLAS, r[1], FMT.BAR_MESH, 0, 0)
  end
end

-- instance `inst` of `layer` shows tab t's icon (its sprite pair, or a retail icon type through `setup`)
local function FMT_SetIcon(layer, inst, t, setup)
  if t == nil then
    return
  end
  if t.icon == 0 and type(t.itype) == "number" and t.itype >= 0 then
    return setup(layer, inst, t.itype, true)
  end
  if t.icon ~= 0 then
    funcLuaMenuCommand(FMT.SET_SPRITE, layer, t.atlas, t.icon, FMT.DMY_ON, 0, inst)
    funcLuaMenuCommand(FMT.SET_SPRITE, layer, t.atlas, t.off, FMT.DMY_OFF, 0, inst)
    funcLuaMenuCommand(FMT.MESH_VISIBLE, layer, FMT.ICON_BASE, true, inst)
  end
end

local function FMT_Icon(orig, a1, a2, ...)
  if type(a2) ~= "number" or a2 < FMT.RETAIL then
    if type(a2) == "number" and a1 == FMT.TAB_ITEM then
      FMT.retail_icon[a2] = table.pack(a1, a2, ...)
    end
    return orig(a1, a2, ...)
  end
  local t = FMT_Tab(a2)
  if t == nil or a2 >= FMT_Page1Total() then
    funcLuaMenuCommand(FMT.LAYER_VISIBLE, a1, a2, false)
    return
  end
  return FMT_SetIcon(a1, a2, t, orig)
end

local function FMT_Name(t)
  local name = nil
  if t.series ~= 0 then
    local okc, s = VRFW.host.menu_command(FMT.SERIES_INFO, 1, t.series)
    if okc then
      name = s
    end
  end
  if (type(name) ~= "string" or name == "") and t.text ~= 0 then
    local s = VRFW.host.command(FMT.TEXT_GET, t.text)
    if s ~= nil then
      name = s
    end
  end
  if type(name) ~= "string" then
    name = ""
  end
  for _, h in pairs(VRFW.free_match_tab_hooks) do
    if type(h) == "table" and type(h.text) == "function" then
      local ok, s = pcall(h.text, t.id, name)
      if ok and type(s) == "string" then
        name = s
      end
    end
  end
  return name
end

local function FMT_With(key, wrap, fn, ...)
  local orig = LISTVIEW[key]
  LISTVIEW[key] = function(...)
    return wrap(orig, ...)
  end
  local r = table.pack(pcall(fn, ...))
  LISTVIEW[key] = orig
  if not r[1] then
    error(r[2], 0)
  end
  return table.unpack(r, 2, r.n)
end

-- docs/framework/team-sections.md: the sections (the retail tabs + the mods' tabs) in pages of the bar.

-- the kept tabs (first FMT_Count of them) on page p, in slot order
local function FMT_PageTabs(p)
  local out = {}
  local all = FMT_All()
  for k = 1, FMT_Count() do
    local t = all[k]
    if t ~= nil and (t.page or 1) == p then
      out[#out + 1] = t
    end
  end
  table.sort(out, function(a, b) return (a.slot or a.index) < (b.slot or b.index) end)
  return out
end

-- pages of the bar (1 = everything on the retail page)
local function FMT_Pages()
  local n = 1
  local all = FMT_All()
  for k = 1, FMT_Count() do
    local t = all[k]
    if t ~= nil and (t.page or 1) > n then
      n = t.page
    end
  end
  return n
end

-- the tab index bar slot `slot` stands for on the shown page
local function FMT_SlotIndex(slot)
  if (FMT.page or 1) <= 1 or type(slot) ~= "number" then
    return slot
  end
  local t = FMT_PageTabs(FMT.page)[slot + 1]
  return t ~= nil and t.index or slot
end

-- instance `slot` shows its tab's icon on the shown page (retail tabs: the retail call recorded at set-up)
local function FMT_ApplySlot(slot)
  local p = FMT.page or 1
  if p <= 1 then
    if slot < FMT.RETAIL then
      local call = FMT.retail_icon[slot]
      if call ~= nil then
        LISTVIEW.SetupTabIcon(table.unpack(call, 1, call.n))
      end
    else
      FMT_SetIcon(FMT.TAB_ITEM, slot, FMT_Tab(slot), LISTVIEW.SetupTabIcon)
    end
    return
  end
  local t = FMT_PageTabs(p)[slot + 1]
  if t ~= nil then
    FMT_SetIcon(FMT.TAB_ITEM, slot, t, LISTVIEW.SetupTabIcon)
  end
end

-- show page p: instances, icons, focus count, and the slots the native list answer maps
local function FMT_ShowPage(p)
  FMT.page = p
  local list = p > 1 and FMT_PageTabs(p) or nil
  local n = list ~= nil and #list or FMT_Page1Total()
  for slot = 0, FMT.INSTANCES - 1 do
    local shown = slot < n
    funcLuaMenuCommand(FMT.LAYER_VISIBLE, FMT.TAB_ITEM, slot, shown)
    if shown then
      FMT_ApplySlot(slot)
    end
  end
  funcLuaMenuCommand(FMT.FOCUS_COUNT, FMT.TAB_ITEM, n)
  local index = {}
  for k, t in ipairs(list or {}) do
    index[k] = t.index
  end
  VRFW.host.command(FMT.SECTION_SLOTS, table.unpack(index))
  FMT_Log("page", p, "of", FMT_Pages(), "slots", n)
end

-- the bar's focused slot: the one the screen set, the engine's answer only when none is known
local function FMT_FocusedSlot()
  if FMT.focus_slot ~= nil then
    return FMT.focus_slot
  end
  local s = VRFW.host.menu_command(FMT.FOCUSED, FMT.TAB_ITEM)
  return s or nil
end

-- the slots the shown page uses
local function FMT_ShownSlots()
  if (FMT.page or 1) > 1 then
    return #FMT_PageTabs(FMT.page)
  end
  return FMT_Page1Total()
end

-- instance `slot` drawn selected (Focus animation in) or unselected (Focus animation out)
local function FMT_SlotLook(slot, selected)
  VRFW.host.menu_command(FMT.PLAY_ANIME, FMT.TAB_ITEM, slot, FMT.ANIME_FOCUS, selected and 0 or 2,
    FMT.ANIME_SET_BUTTON)
end

-- the tab states: the focused slot selected, every other shown slot unselected.
local function FMT_ApplyTabStates(slot, force)
  slot = slot or FMT_FocusedSlot()
  if type(slot) ~= "number" or slot < 0 then
    return
  end
  local key = tostring(FMT.page or 1) .. ":" .. tostring(slot)
  if not force and FMT.states_key == key then
    return
  end
  local shown = FMT_ShownSlots()
  for s = 0, shown - 1 do
    FMT_SlotLook(s, s == slot)
  end
  if FMT.states_key ~= key then
    VRFW.host.command(3626744379 --[[CMND_VRFW_LOG_DEBUG]], "VRFW fm_tabs tab states page " .. tostring(FMT.page or 1) .. " selected "
      .. tostring(slot) .. " of " .. tostring(shown))
  end
  FMT.states_key = key
end

local function FMT_Focus(slot)
  FMT.focus_pending = true
  FMT.focus_slot = slot
  funcLuaMenuCommand(FMT.FOCUS_SET, FMT.TAB_ITEM, slot)
  if FMT.focus_pending and type(OnChangeFocus) == "function" then
    OnChangeFocus(FMT.TAB_ITEM, slot)
  end
  FMT_ApplyTabStates(slot)
end

local function FMT_CapSpec()
  local spec = {
    layer = FMT.KEYS,
    slots = {layer = FMT.TAB_ITEM, first = 0, last = FMT_Page1Total() - 1},
    left_text = FMT.KEY_LEFT, right_text = FMT.KEY_RIGHT,
    edge_inset = 4,   -- L2 hugs the left end of the bar, R2 the right end
    cap_offset = 459, cap_width = 118,
    screen_left = 0,
    symmetric = true, -- R2 mirrors L2 about the bar's centre
  }
  for _, h in pairs(VRFW.free_match_tab_hooks) do
    if type(h) == "table" and type(h.cap) == "function" then
      local ok, c = pcall(h.cap)
      if ok and type(c) == "table" and type(c.offset) == "number" then
        spec.cap_offset, spec.cap_width = c.offset, c.width
        break
      end
    end
  end
  return spec
end

local function FMT_OpenKeys()
  VRFW.tab_bar_caps.open(FMT.keys, FMT_CapSpec())
end

local function FMT_PlaceKeys()
  VRFW.tab_bar_caps.step(FMT.keys, FMT_CapSpec())
end

if VRFW.host ~= nil then
  VRFW.host.on("soccer_vs_cpu_list_menu", "OnInit", {
    id = "menu_engine.free_match_tabs", phase = "before",
    fn = function()
      FMT.page, FMT.focus_pending, FMT.focus_slot, FMT.opening, FMT.row_logged = nil, false, nil, false, false
      FMT.states_key, FMT.states_pending = nil, false
      FMT.keys = VRFW.tab_bar_caps.new()
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnOpenLayer", {
    id = "menu_engine.free_match_tabs", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= FMT.TAB_ITEM then
        return nxt(a1, ...)
      end
      local total = FMT_Page1Total()
      local pages = FMT_Pages()
      local cmd = funcLuaMenuCommand
      funcLuaMenuCommand = function(id, b1, b2, ...)
        if id == FMT.FOCUS_SET and b1 == FMT.TAB_ITEM and type(b2) == "number" then
          if b2 >= total then
            local t = pages > 1 and FMT_Tab(b2) or nil
            if t ~= nil and (t.page or 1) > 1 then
              if FMT.page ~= t.page then
                FMT_ShowPage(t.page)       -- its calls pass through this wrapper unchanged (no FOCUS_SET)
              end
              b2 = t.slot
            else
              FMT_Log("saved tab", b2, "-> 0")
              VRFW.host.command(FMT.SET_TEMP_BYTE, FMT.SAVED_TAB, 0)
              b2 = 0
            end
          end
          FMT.focus_slot = b2
        end
        return cmd(id, b1, b2, ...)
      end
      FMT.opening = true
      local r = table.pack(pcall(nxt, a1, ...))
      FMT.opening = false
      funcLuaMenuCommand = cmd
      if pages > 1 then
        FMT_OpenKeys()
        if r[1] then
          FMT.states_pending = true
        end
      end
      if not r[1] then
        error(r[2], 0)
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnSetupLayer", {
    id = "menu_engine.free_match_tabs", phase = "around",
    fn = function(nxt, a1, a2, ...)
      if a1 ~= FMT.TAB_ITEM or LISTVIEW == nil or LISTVIEW.UpdateAttachTabNum == nil then
        return nxt(a1, a2, ...)
      end
      local total = FMT_Page1Total()
      local cmd = funcLuaMenuCommand
      if a2 == 0 and total > FMT.RETAIL then
        funcLuaMenuCommand = function(id, b1, b2, ...)
          if id == FMT.FOCUS_COUNT and b1 == FMT.TAB_ITEM and b2 == FMT.RETAIL then
            b2 = total
          end
          return cmd(id, b1, b2, ...)
        end
        FMT_Log("tab bar", total, "pages", FMT_Pages())
      end
      local r = table.pack(pcall(FMT_With, "UpdateAttachTabNum",
        function(orig, k, layer, ...)
          if k == FMT.RETAIL and layer == FMT.ATTACH then
            return FMT_Bar(orig, total, layer)
          end
          return orig(k, layer, ...)
        end,
        FMT_With, "SetupTabIcon", FMT_Icon, nxt, a1, a2, ...))
      funcLuaMenuCommand = cmd
      if not r[1] then
        error(r[2], 0)
      end
      -- an instance set up while a later page is shown keeps that page's look
      if (FMT.page or 1) > 1 and type(a2) == "number" then
        local list = FMT_PageTabs(FMT.page)
        funcLuaMenuCommand(FMT.LAYER_VISIBLE, a1, a2, a2 < #list)
        if a2 < #list then
          FMT_ApplySlot(a2)
          FMT_SlotLook(a2, a2 == FMT_FocusedSlot())
        end
      end
      return table.unpack(r, 2, r.n)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnChangeFocus", {
    id = "menu_engine.free_match_tabs", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= FMT.TAB_ITEM or LISTVIEW == nil or LISTVIEW.SetupTabText == nil then
        return nxt(a1, ...)
      end
      local from_page_turn = FMT.focus_pending
      FMT.focus_pending = false
      local slot = VRFW.host.menu_command(FMT.FOCUSED, a1)
      if from_page_turn and FMT.focus_slot ~= nil then
        slot = FMT.focus_slot
      elseif type(slot) == "number" and not FMT.opening then
        FMT.focus_slot = slot      -- a focus move on the bar (Z / C, pointer)
      end
      local index = slot and FMT_SlotIndex(slot) or nil
      local t = type(index) == "number" and index >= FMT.RETAIL and FMT_Tab(index) or nil
      local r
      if t == nil then
        r = table.pack(nxt(a1, ...))
      else
        r = table.pack(FMT_With("SetupTabText", function(orig, _, layer)
          funcLuaMenuCommand(FMT.SET_TEXT, layer, FMT.TEXT_MESH, FMT_Name(t))
        end, nxt, a1, ...))
      end
      -- on a later page the saved byte holds the tab index (the retail code saved the slot)
      if (FMT.page or 1) > 1 and type(index) == "number" then
        VRFW.host.command(FMT.SET_TEMP_BYTE, FMT.SAVED_TAB, index)
      end
      -- a tab change: exactly one tab selected (the opening sets its states in Step)
      if not FMT.opening and type(slot) == "number" and FMT_Pages() > 1 then
        FMT_ApplyTabStates(slot)
      end
      return table.unpack(r, 1, r.n)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OnFunction", {
    id = "menu_engine.free_match_tabs", phase = "around",
    fn = function(nxt, a1, ...)
      if a1 ~= FMT.SECTION_PREV and a1 ~= FMT.SECTION_NEXT then
        return nxt(a1, ...)
      end
      local pages = FMT_Pages()
      if pages <= 1 then
        return
      end
      local step = a1 == FMT.SECTION_NEXT and 1 or -1
      FMT_ShowPage(((FMT.page or 1) - 1 + step) % pages + 1)
      FMT_Focus(0)
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "OpenClassSelect", {
    id = "menu_engine.free_match_tabs", phase = "after",
    fn = function()
      if FMT_Pages() > 1 then
        FMT_ApplyTabStates(nil, true)
      end
    end,
  })

  -- the first list row of each opening: the name answer the retail UpdateItem draws (one log line per opening)
  VRFW.host.on("soccer_vs_cpu_list_menu", "UpdateItem", {
    id = "menu_engine.free_match_tabs.row_name", phase = "after",
    fn = function(r, a1, a2, a3)
      if FMT.row_logged or type(a3) ~= "number" or a3 == 0 then
        return
      end
      FMT.row_logged = true
      local hast, team = VRFW.host.command(FMT.GAME_TEAM, a3)
      local has, name = nil, nil
      if hast then
        has, name = VRFW.host.command(FMT.TEAM_INFO, team, 2)
      end
      FMT_Log("row " .. tostring(a2), "game " .. tostring(a3), "team " .. tostring(team), "name", has, type(name) == "string" and #name or "-")
    end,
  })

  VRFW.host.on("soccer_vs_cpu_list_menu", "Step", {
    id = "menu_engine.free_match_tabs", phase = "after",
    fn = function()
      if FMT.keys.pending then
        FMT_PlaceKeys()
      end
      if FMT.states_pending then
        FMT.states_pending = false
        FMT_ApplyTabStates(nil, true)
      end
    end,
  })
end
