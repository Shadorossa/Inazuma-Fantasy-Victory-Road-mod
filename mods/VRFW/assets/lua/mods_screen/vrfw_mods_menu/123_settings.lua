local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Call, Crc, Cut, Draw, FN = Screen.C, Screen.CE, Screen.call, Screen.crc, Screen.cut, Screen.draw, Screen.FN
local Fit, G, Hit, IconOf, Initials, Int = Screen.fit, Screen.G, Screen.hit, Screen.icon_of, Screen.initials, Screen.int
local Log, ModById, PopupButtons, PopupWindow = Screen.log, Screen.mod_by_id, Screen.popup_buttons, Screen.popup_window
local Quad, RV, SE_MOVE, SE_NG, SP, Str = Screen.quad, Screen.RV, Screen.SE_MOVE, Screen.SE_NG, Screen.SP, Screen.str
local T, TextIdKey, Txt, Units, Wrap, ui = Screen.T, Screen.text_id_key, Screen.txt, Screen.units, Screen.wrap, Screen.ui

RV.OPT = {ROWS = Crc("CMND_VRFW_OPTION_ROWS"), ROW = Crc("CMND_VRFW_OPTION_ROW"), GET = Crc("CMND_VRFW_OPTION_GET"),
          SET = Crc("CMND_VRFW_OPTION_SET"), STEP = Crc("CMND_VRFW_OPTION_STEP"), TEXT = Crc("CMND_VRFW_OPTION_TEXT")}

-- every row of the settings registry, read once per RV.cache (emptied by OpenDetails)
function RV.option_rows()
  local all = RV.cache.option_rows
  if all ~= nil then
    return all
  end
  all = {}
  for i = 1, Int(Call(RV.OPT.ROWS)) do
    local k, kind, storage, label, fallback, get, set, _gated, _fixed, _parent, help, help_fb, category = Call(RV.OPT.ROW, i)
    if type(k) == "string" then
      all[#all + 1] = {key = k, kind = Str(kind), storage = Str(storage), label = Int(label), fallback = Str(fallback),
                       get = Int(get), set = Int(set), help = Int(help), help_fb = Str(help_fb), category = Int(category)}
    end
  end
  RV.cache.option_rows = all
  return all
end

-- the settings of mod `id`, read once per RV.cache
function RV.settings(id)
  local ck = "settings:" .. id
  local r = RV.cache[ck]
  if r ~= nil then
    return r
  end
  local opts = {}
  local pre = id .. "."
  for _, o in ipairs(RV.option_rows()) do
    if string.sub(o.key, 1, #pre) == pre then
      opts[#opts + 1] = o
    end
  end
  r = {}
  local m = ModById(id)
  if m ~= nil then
    for _, mm in ipairs(m.modules or {}) do
      r[#r + 1] = {module = mm, key = mm.id}
    end
    for _, key in ipairs(m.internal or {}) do
      for k, o in ipairs(opts) do
        if o.key == key then
          o.imodule = true
          r[#r + 1] = table.remove(opts, k)
          break
        end
      end
    end
  end
  for _, o in ipairs(opts) do
    r[#r + 1] = o
  end
  RV.cache[ck] = r
  return r
end

-- the mod has a "Modules" list (module mods of its family or internal modules)
function RV.has_modules(m)
  return #(m.modules or {}) > 0 or #(m.internal or {}) > 0
end

-- a menu_text row in the game's language, else the fallback
function RV.text_of(id, fallback)
  if id ~= nil and id ~= 0 then
    local s = Call(C.TEXT_GET, id)
    if type(s) == "string" and s ~= "" then
      return s
    end
  end
  return fallback
end

-- (value, changeable): nil for a row with its own Lua behaviour or a value nobody answers
function RV.value(r)
  if r.module ~= nil then
    return r.module.enabled and 1 or 0, true      -- A module mod: on = switched on.
  end
  if r.kind == "lua" or r.storage == "lua" then
    return nil, false
  end
  if r.storage == "command" then
    local v, extra = Call(r.get)
    if type(v) == "number" then
      return v, true
    end
    if type(v) == "boolean" and (v or extra ~= nil) then
      return v and 1 or 0, true
    end
    return nil, false
  end
  local v, dv = Call(RV.OPT.GET, r.key, true)
  if type(v) == "number" then
    return v, true
  end
  if v == false and type(dv) == "number" then
    return dv, false          -- enabled_if not met / parent off: shown greyed, no changes
  end
  return nil, false
end

function RV.fmt(r, v)
  if r.module ~= nil then
    local k = v == 1 and "module_on" or "module_off"
    return T(r.module.pending and (k .. "_next") or k)
  end
  local id, fb = Call(RV.OPT.TEXT, r.key, v)
  if type(id) ~= "number" then
    return tostring(v)
  end
  local s = RV.text_of(id, Str(fb))
  return s ~= "" and s or tostring(v)
end

-- the selected row's (or `row`'s) value one step in direction `dir` (±1), stored where the row keeps it
function RV.change(m, dir, row)
  local r = row or RV.set_rows(m)[ui.popup.srow or 1]
  if r ~= nil and r.module ~= nil then
    return RV.toggle_module(r.module)
  end
  local v, live = nil, false
  if r ~= nil then
    v, live = RV.value(r)
  end
  local ok, n = false, nil
  if v ~= nil and live then
    n = Call(RV.OPT.STEP, r.key, v, dir)
    if type(n) == "number" and n ~= v then
      if r.storage == "command" then
        ok = Call(r.set, n) == true
      else
        ok = Call(RV.OPT.SET, r.key, n) == true
      end
    end
  end
  funcLuaCommand(C.SE, ok and SE_MOVE or SE_NG)
  if ok then
    Log("setting", r.key, tostring(n))
  end
  Draw()
end

RV.HEAD_H, RV.ROW_H, RV.SET_ROWS, RV.SET_CHIPS = 34, 38, 12, 4
-- where a page draws its settings rows: quad / left text / centred text layers, section bar height, most chips
RV.PAGE_ROW = {q = "P1", l = "PL", c = "PC", bar_h = RV.HEAD_H - 6, chips = RV.SET_CHIPS}

function RV.layout(m)
  local lines, group, category = {}, nil, 0
  for n, r in ipairs(RV.set_rows(m)) do
    if r.group ~= nil and r.group ~= group then
      group, category = r.group, 0
      lines[#lines + 1] = {kind = "head", h = RV.HEAD_H, group = group}
    end
    if r.category ~= 0 and r.category ~= category then
      category = r.category
      lines[#lines + 1] = {kind = "head", h = RV.HEAD_H, category = category}
    end
    lines[#lines + 1] = {kind = "row", h = RV.ROW_H, items = {n}}
  end
  return lines
end

-- the line of row number n in `lines`
function RV.where(lines, n)
  for li, l in ipairs(lines) do
    if l.items ~= nil and l.items[1] == n then
      return li
    end
  end
  return nil
end

-- the next line with a row from line `li` in direction d (±1), or nil
function RV.next_line(lines, li, d)
  local k = li + d
  while lines[k] ~= nil and lines[k].kind == "head" do
    k = k + d
  end
  return lines[k] ~= nil and k or nil
end

-- A / a click on row n: the setting moves one step
function RV.activate(m, n)
  local r = RV.set_rows(m)[n]
  if r == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  ui.popup.srow, ui.popup.szone = n, "rows"
  RV.change(m, 1)
end

-- The pad in the "Settings" view.
function RV.settings_key(id)
  local m = ModById(ui.popup.id)
  local rows = m and RV.set_rows(m) or {}
  if #rows == 0 then
    return false
  end
  local p = ui.popup
  local lines = RV.layout(m)
  local function moved(ok)
    funcLuaCommand(C.SE, ok and SE_MOVE or SE_NG)
    Draw()
  end
  if p.szone == "buttons" then
    if id == FN.UP then
      local li = RV.next_line(lines, #lines + 1, -1)
      p.szone, p.srow = "rows", li and lines[li].items[1] or 1
      moved(true)
    elseif id == FN.LEFT or id == FN.RIGHT then
      local n = #PopupButtons(m)
      local b = math.max(1, math.min(n, (p.btn or 1) + (id == FN.LEFT and -1 or 1)))
      local ok = b ~= p.btn
      p.btn = b
      moved(ok)
    else
      moved(false)
    end
    return true
  end
  local sel = math.max(1, math.min(p.srow or 1, #rows))
  local li = RV.where(lines, sel) or RV.next_line(lines, 0, 1)
  if id == FN.UP or id == FN.DOWN then
    local k = RV.next_line(lines, li, id == FN.UP and -1 or 1)
    if k == nil then
      if id == FN.DOWN and #PopupButtons(m) > 0 then
        p.szone = "buttons"
        p.btn = math.max(1, math.min(#PopupButtons(m), p.btn or 1))
        moved(true)
      else
        moved(false)
      end
      return true
    end
    p.srow = lines[k].items[1]
    moved(true)
  else
    p.srow = sel
    RV.change(m, id == FN.LEFT and -1 or 1)
  end
  return true
end

-- a setting's label split into its "[Prefix]" (the chip) and the rest; the module group's name
function RV.set_label(r)
  local label = RV.text_of(r.label, r.fallback ~= "" and r.fallback or r.key)
  local chip, rest = string.match(label, "^%[([^%]]+)%]%s*(.+)$")
  return rest or label, chip
end

function RV.group_name(mm)
  local title = RV.notes(mm).title
  return title ~= "" and title or (mm.mname or (mm.name ~= "" and mm.name or mm.id))
end

function RV.set_help(r)
  local s = RV.text_of(r.help, r.help_fb)
  if s ~= "" then
    return s
  end
  local id = TextIdKey(r.key .. "_help")
  return id ~= nil and Str(Call(C.TEXT_GET, id)) or ""
end

-- a module's slim section bar: its badge (icon or two letters) and its name
function RV.draw_group_bar(style, mm, x, y, w)
  local h = style.bar_h
  Quad(style.q, SP("row_head"), x, y, w, h)
  local name = RV.group_name(mm)
  local ic = IconOf(mm)
  if ic ~= nil then
    Quad(style.q, ic[2], x + 8, y + 3, h - 6, h - 6, 1, ic[1])
  else
    Txt(style.c, Initials({name = name, id = name}), x + 8 + (h - 6) / 2, y + h / 2, 0.5)
  end
  Txt(style.l, Cut(name, Fit(w - 80, 0.66)), x + h + 14, y + h / 2, 0.66)
end

-- a category's sub-header inside its mod: its name only, no plate
function RV.draw_category_bar(style, category, x, y, w)
  local name = RV.text_of(category, "")
  Txt(style.l, Cut(name, Fit(w - 24, 0.58)), x + 12, y + style.bar_h / 2, 0.58)
end

function RV.draw_row(style, r, x, y, w, h, focused, chips)
  local cy = y + h / 2
  if focused then
    CE.focus(style.q, x, y, w, h, 3)
  end
  local label, chip = RV.set_label(r)
  local tx = x + 12
  if chip ~= nil and chips.n < style.chips then
    chips.n = chips.n + 1
    local cw = math.min(140, math.floor(Units(chip) * G.PX * 0.52) + 22)
    Quad(style.q, SP("pill_blue"), tx, cy - 12, cw, 24)
    Txt(style.c, Cut(chip, Fit(cw - 10, 0.52)), tx + cw / 2, cy, 0.52)
    tx = tx + cw + 10
  elseif chip ~= nil then
    label = chip .. " · " .. label
  end
  local bx, bw = x + w - G.SET_VAL_W - 8, G.SET_VAL_W
  Txt(style.l, "[CB]" .. Cut(label, Fit(bx - tx - 16, 0.66)) .. "[C]", tx, cy, 0.66)
  local v, live = RV.value(r)
  if r.kind == "lua" or r.storage == "lua" then
    Txt(style.c, "[CWG]" .. Cut(T("set_lua"), Fit(bw, 0.5)) .. "[C]", bx + bw / 2, cy, 0.5)
  elseif v == nil then
    Txt(style.c, "[CWG]" .. T("set_unknown") .. "[C]", bx + bw / 2, cy, 0.6)
  else
    Quad(style.q, SP((focused and live) and "val_sel" or "val"), bx, cy - 15, bw, 30)
    Txt(style.c, (live and "[CB]" or "[CWG]") .. Cut(RV.fmt(r, v), Fit(bw - 60, 0.62)) .. "[C]", bx + bw / 2, cy, 0.62)
  end
end

function RV.draw_set_sheet(style, r, owner, x, ty, w)
  local _, chip = RV.set_label(r)
  local from = {}
  if owner ~= nil then
    from[#from + 1] = owner
  end
  if r.group ~= nil then
    from[#from + 1] = RV.group_name(r.group)
  end
  if chip ~= nil then
    from[#from + 1] = chip
  end
  if #from > 0 then
    Txt(style.l, "[CN]" .. Cut(table.concat(from, "  ·  "), Fit(w, 0.64)) .. "[C]", x, ty, 0.64)
    ty = ty + 34
  end
  local help = RV.set_help(r)
  for k, l in ipairs(Wrap(help ~= "" and help or T("set_no_help"), Fit(w, 0.64), G.SET_HELP_LINES)) do
    Txt(style.l, (help ~= "" and "[CB]" or "[CWG]") .. l .. "[C]", x, ty + (k - 1) * 30, 0.64)
  end
end

-- the focused setting's sheet at the right of a page: a blue bar with its label, then the sheet
function RV.draw_set_pane(r)
  local x, w, y = G.MOD_PANE_X, G.MOD_PANE_W, RV.body_y() + 14
  local hh = G.MOD_PANE_HEAD
  Quad("P1", SP("hbar"), x, y, w, hh)
  Txt("PL", Cut((RV.set_label(r)), Fit(w - 40, 0.74)), x + 20, y + hh / 2, 0.74)
  RV.draw_set_sheet(RV.PAGE_ROW, r, nil, x + 20, y + hh + 26, w - 40)
end

function RV.draw_settings(m)
  local rows = RV.set_rows(m)
  local px, py = G.WIN_X + 32, RV.body_y() + 14
  local w = G.MOD_LIST_W
  if #rows == 0 then
    local why = (m.enabled and m.state == 0 and not m.pending) and "set_none" or "set_inactive"
    for i, l in ipairs(Wrap(T(why), Fit(G.WIN_W - 80, 0.8), 3)) do
      Txt("PL", "[CN]" .. l .. "[C]", px, py + 26 + (i - 1) * 34, 0.8)
    end
    return
  end
  local p = ui.popup
  local sel = math.max(1, math.min(p.srow or 1, #rows))
  p.srow = sel
  local lines = RV.layout(m)
  local bottom = RV.foot_y() - 40     -- above the page line and the shortcut bar
  local avail = bottom - py
  -- scroll: the selected line on the page (with its section bar when it is right above)
  local sl = RV.where(lines, sel) or 1
  local top = math.max(1, math.min(p.stop or 1, #lines))
  if sl < top then
    top = sl
  end
  while top > 1 and lines[top - 1].kind == "head" and top - 1 <= sl do
    top = top - 1
  end
  local function fits(a, b)
    local hsum, nrows = 0, 0
    for k = a, b do
      hsum = hsum + lines[k].h
      nrows = nrows + (lines[k].kind == "row" and 1 or 0)
    end
    return hsum <= avail and nrows <= RV.SET_ROWS
  end
  while top < sl and not fits(top, sl) do
    top = top + 1
  end
  p.stop = top
  local y, first, last, drawn, chips = py, nil, nil, 0, {n = 0}
  for k = top, #lines do
    local l = lines[k]
    local need = l.h
    local below = k + 1
    while l.kind == "head" and lines[below] ~= nil do   -- a bar only with its first row, past any bar right under it
      need = need + lines[below].h
      if lines[below].kind ~= "head" then
        break
      end
      below = below + 1
    end
    if y + need > bottom or (l.kind == "row" and drawn >= RV.SET_ROWS) then
      break
    end
    if l.kind == "head" and l.group ~= nil then
      RV.draw_group_bar(RV.PAGE_ROW, l.group, px, y + 4, w)
    elseif l.kind == "head" then
      RV.draw_category_bar(RV.PAGE_ROW, l.category, px, y + 4, w)
    else
      local n = l.items[1]
      first, last, drawn = first or n, n, drawn + 1
      RV.draw_row(RV.PAGE_ROW, rows[n], px, y, w, RV.ROW_H - 4, p.szone ~= "buttons" and n == sel, chips)
      Hit(px, y, w, RV.ROW_H - 4, "set" .. n, function() RV.activate(m, n) end)   -- hover moves p.srow too (Hover)
    end
    y = y + l.h
  end
  -- where the page is, and the short note on where these values live
  local note = T("set_note")
  if first ~= nil and (first > 1 or last < #rows) then
    note = T("report_rows", {n = first, c = last, t = #rows}) .. "   ·   " .. note
  end
  Txt("PL", "[CWG]" .. Cut(note, Fit(w, 0.58)) .. "[C]", px, bottom + 20, 0.58)
  RV.draw_set_pane(rows[sel])
end

-- a mod's own rows: rows with no category first, then each category together in the order its first row is declared
function RV.own_settings(id)
  local r, cats, by_cat = {}, {}, {}
  for _, o in ipairs(RV.settings(id)) do
    if o.module == nil and not o.imodule then
      if o.category == 0 then
        r[#r + 1] = o
      else
        if by_cat[o.category] == nil then
          by_cat[o.category] = {}
          cats[#cats + 1] = o.category
        end
        table.insert(by_cat[o.category], o)
      end
    end
  end
  for _, c in ipairs(cats) do
    for _, o in ipairs(by_cat[c]) do
      r[#r + 1] = o
    end
  end
  return r
end

function RV.set_rows(m)
  local ck = "setrows:" .. m.id
  local r = RV.cache[ck]
  if r == nil then
    r = RV.own_settings(m.id)
    for _, mm in ipairs(m.modules or {}) do
      if mm.enabled then
        for _, o in ipairs(RV.own_settings(mm.id)) do
          local row = {group = mm}
          for k, v in pairs(o) do
            row[k] = v
          end
          r[#r + 1] = row
        end
      end
    end
    RV.cache[ck] = r
  end
  return r
end

local function DrawDetails()
  local m = ModById(ui.popup.id)
  while m == nil and ui.popup ~= nil do
    -- the mod is gone from the list (a rescan): the page under it, else none
    ui.popup = ui.popup.back
    m = ui.popup and ModById(ui.popup.id)
  end
  if m == nil then
    return
  end
  local known = false
  for _, v in ipairs(RV.views(m)) do
    known = known or v == ui.popup.view
  end
  if not known then
    ui.popup.view = "info"
  end
  PopupWindow(m)
  RV.tabs(m)
  local v = ui.popup.view
  if v == "info" then
    RV.draw_info(m)
  elseif v == "modules" then
    RV.draw_modules(m)
  elseif v == "settings" then
    RV.draw_settings(m)
  elseif v == "news" then
    RV.draw_news(m)
  else
    RV.draw(m, v == "problems" and 2 or 3)
  end
  RV.footer(m)
end

-- for 100_mods_screen.lua and the files after this one
Screen.draw_details = DrawDetails
