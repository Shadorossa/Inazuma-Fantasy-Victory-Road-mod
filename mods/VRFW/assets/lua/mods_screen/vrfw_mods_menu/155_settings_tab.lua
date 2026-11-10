local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Cut, DrawScrollbar, Fit, G = Screen.C, Screen.CE, Screen.cut, Screen.draw_scrollbar, Screen.fit, Screen.G
local Hit, K, ModById, Quad, RV, SE_MOVE = Screen.hit, Screen.K, Screen.mod_by_id, Screen.quad, Screen.RV, Screen.SE_MOVE
local SE_NG, SP, T, Txt, Wrap, ui = Screen.SE_NG, Screen.SP, Screen.T, Screen.txt, Screen.wrap, Screen.ui

local ST = {
  sig = nil,        -- Which mods the cached rows belong to.
  MODULE_INDENT = 24,
  STYLE = {q = "Q1", l = "TL", c = "TC", bar_h = G.ROW_H, chips = 16},
}

-- the active mods in load order, the framework first; and a signature of them and of their active modules
local function ActiveMods()
  local active = {}
  for _, m in ipairs(Screen.mods()) do
    if m.enabled and m.family == nil then
      active[#active + 1] = m
    end
  end
  table.sort(active, function(a, b)
    local pa, pb = a.pos > 0 and a.pos or math.huge, b.pos > 0 and b.pos or math.huge
    if pa ~= pb then
      return pa < pb
    end
    return a.order < b.order
  end)
  if Screen.base_mod() ~= nil then
    table.insert(active, 1, Screen.base_mod())
  end
  local parts = {}
  for _, m in ipairs(active) do
    parts[#parts + 1] = m.id
    for _, mm in ipairs(m.modules or {}) do
      if mm.enabled then
        parts[#parts + 1] = mm.id
      end
    end
  end
  return active, table.concat(parts, "|")
end

-- the list: {head = true, m = mod, group = module or nil} and {m = mod, r = setting, n = its row in the mod's page}
local function Rows()
  local active, sig = ActiveMods()
  if sig ~= ST.sig then
    RV.cache = {}
    ST.sig = sig
  end
  local list = RV.cache.settings_tab
  if list ~= nil then
    return list
  end
  list = {count = 0}
  for _, m in ipairs(active) do
    local group = nil
    for n, r in ipairs(RV.set_rows(m)) do
      if n == 1 then
        list[#list + 1] = {head = true, m = m}
      end
      if r.group ~= nil and r.group ~= group then
        group = r.group
        list[#list + 1] = {head = true, m = m, group = group}
      end
      list[#list + 1] = {m = m, r = r, n = n}
      list.count = list.count + 1
    end
  end
  RV.cache.settings_tab = list
  return list
end

local function Selected(rows)
  ui.ssel = CE.headed_selected(rows, ui.ssel)
  return ui.ssel
end

function CE.settings_tab_label()
  return T("tab_settings_all", {n = Rows().count})
end

-- the mod of the focused setting (nil = none)
function CE.settings_mod()
  local rows = Rows()
  local row = rows[Selected(rows)]
  return row ~= nil and ModById(row.m.id) or nil
end

-- the focused setting's row on its mod's page
function CE.settings_page_row()
  local rows = Rows()
  local row = rows[Selected(rows)]
  return row ~= nil and row.n or 1
end

-- the focused setting one step in direction dir (±1), by the function of the mod's page
function CE.settings_change(dir)
  local rows = Rows()
  local row = rows[Selected(rows)]
  if row == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  RV.change(row.m, dir, row.r)
end

function CE.settings_move(d)
  local rows = Rows()
  local s = Selected(rows)
  local t = CE.headed_step(rows, s, d)
  if t == s or s == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_MOVE)
  ui.ssel = t
  Screen.draw()
end

-- the mouse over a setting row selects it (true = draw again)
function CE.settings_hover(id)
  local n = tonumber(string.match(id, "^stg(%d+)$") or "")
  local rows = Rows()
  if n == nil or rows[n] == nil or rows[n].head or n == ui.ssel then
    return false
  end
  ui.ssel = n
  return true
end

local function DrawEmpty()
  Quad("Q2", SP("white"), G.LIST_X, G.LIST_Y, G.ROW_W - 12, 200)
  Txt("TL", "[CN]" .. Cut(T("st_empty"), Fit(G.ROW_W - 80, 1.0)) .. "[C]", G.LIST_X + 30, G.LIST_Y + 58, 1.0)
  CE.info_panel(nil)
end

-- the focused setting's sheet in the info panel's place
local function DrawSheet(row)
  CE.panel_frame()
  local x, w = G.PANEL_X, G.PANEL_W
  Txt("TL", Cut((RV.set_label(row.r)), Fit(w - 160, 1.0)), x + 96, G.PANEL_Y + G.PANEL_HEAD / 2, 1.0)
  RV.draw_set_sheet(ST.STYLE, row.r, RV.group_name(row.m), x + 30, G.PANEL_BODY_Y + 34, w - 60)
  local bottom = G.PANEL_BODY_Y + G.PANEL_BODY_H
  for k, l in ipairs(Wrap(T("set_note"), Fit(w - 60, 0.58), 2)) do
    Txt("TL", "[CWG]" .. l .. "[C]", x + 30, bottom - 96 + (k - 1) * 26, 0.58)
  end
  local hint_y = bottom - 30
  Txt("TR", "[CWG]" .. K.START .. " " .. Cut(T("panel_details"), Fit(300, 0.62)) .. "[C]", x + w - 30, hint_y, 0.62)
  Hit(x + w - 380, hint_y - 18, 360, 36, "pdetails", Screen.open_details)
end

function CE.draw_settings_tab()
  local rows = Rows()
  CE.list_box()
  if #rows == 0 then
    DrawEmpty()
    return
  end
  local vis = G.LIST_ROWS
  local s = Selected(rows)
  ui.stop = CE.headed_top(ui.stop, s, vis, #rows)
  local x, w, chips = G.LIST_X, G.ROW_W, {n = 0}
  for i = 1, math.min(vis, #rows - ui.stop) do
    local n = ui.stop + i
    local row = rows[n]
    local y = G.LIST_Y + (i - 1) * G.ROW_STEP
    local hid = "stg" .. n
    if row.head then
      local indent = row.group ~= nil and ST.MODULE_INDENT or 0
      RV.draw_group_bar(ST.STYLE, row.group or row.m, x + indent, y, w - indent)
      Hit(x, y, w, G.ROW_H, hid, function()
        -- a bar: the mod's page, on the first setting under it
        ui.ssel = CE.headed_step(rows, n, 1)
        Screen.open_details()
      end)
    else
      local sel = n == s and ui.popup == nil
      Quad("Q2", SP(sel and "lplate_sel" or "lplate"), x, y, w, G.ROW_H)
      if sel then
        Quad("Q1", SP("arrow_g"), x - 20, y + G.ROW_H / 2 - 14, 18, 28)
      end
      RV.draw_row(ST.STYLE, row.r, x, y, w, G.ROW_H, sel, chips)
      Hit(x, y, w, G.ROW_H, hid, function()
        ui.ssel = n
        CE.settings_change(1)
      end)
    end
  end
  DrawScrollbar(#rows, ui.stop, vis, G.SB_X, G.LIST_Y, vis * G.ROW_STEP - (G.ROW_STEP - G.ROW_H), function(f)
    -- the bar moves the page and the selection with it (the first setting shown)
    ui.stop = f
    ui.ssel = rows[f + 1] ~= nil and rows[f + 1].head and CE.headed_step(rows, f + 1, 1) or f + 1
  end)
  DrawSheet(rows[s])
end
