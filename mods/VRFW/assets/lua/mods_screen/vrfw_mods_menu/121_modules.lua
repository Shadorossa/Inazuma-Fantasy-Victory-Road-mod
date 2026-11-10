local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Cut, Draw, Fit, G, Hit = Screen.C, Screen.CE, Screen.cut, Screen.draw, Screen.fit, Screen.G, Screen.hit
local INFO, IconOf, Initials, K, Quad = Screen.INFO, Screen.icon_of, Screen.initials, Screen.K, Screen.quad
local RV, SE_MOVE, SE_NG, SP, Size, T = Screen.RV, Screen.SE_MOVE, Screen.SE_NG, Screen.SP, Screen.size, Screen.T
local Text, Txt, Units, Wrap, ui = Screen.text, Screen.txt, Screen.units, Screen.wrap, Screen.ui

function RV.category(m)
  local tag = string.match(Text(m, 8), "^([^\n]+)") or ""
  if tag == "" then
    return nil
  end
  local id = string.gsub(string.lower(tag), "[%s%-]+", "_")
  local key = "category_" .. id
  local label = T(key)
  return {id = id, label = label ~= key and label or tag}
end

function RV.module_rows(m)
  local ck = "mrows:" .. m.id
  local r = RV.cache[ck]
  if r == nil then
    local groups, order = {}, {}
    for _, o in ipairs(RV.settings(m.id)) do
      local row = nil
      if o.module ~= nil then
        row = {mod = o.module, cat = RV.category(o.module)}
      elseif o.imodule then
        row = {opt = o}
      end
      if row ~= nil then
        local gid = row.cat and row.cat.id or ""
        if groups[gid] == nil then
          groups[gid] = {}
          order[#order + 1] = gid
        end
        groups[gid][#groups[gid] + 1] = row
      end
    end
    r = {}
    for _, gid in ipairs(order) do
      for _, row in ipairs(groups[gid]) do
        r[#r + 1] = row
      end
    end
    RV.cache[ck] = r
  end
  return r
end

function RV.module_lines(m)
  local ck = "mlines:" .. m.id
  local lines = RV.cache[ck]
  if lines == nil then
    lines = {}
    local last = nil
    for n, r in ipairs(RV.module_rows(m)) do
      local gid = r.cat and r.cat.id or ""
      if gid ~= last and r.cat ~= nil then
        lines[#lines + 1] = {head = r.cat.label, gid = gid, h = RV.MOD_HEAD_H}
      end
      last = gid
      lines[#lines + 1] = {n = n, h = RV.MOD_STEP}
    end
    RV.cache[ck] = lines
  end
  return lines
end

-- the line of module row n
function RV.module_line(lines, n)
  for li, l in ipairs(lines) do
    if l.n == n then
      return li
    end
  end
  return 1
end

function RV.module_on(r)
  if r.mod ~= nil then
    return r.mod.enabled
  end
  local v = RV.value(r.opt)
  return v ~= nil and v ~= 0
end

function RV.modules_on(m)
  local n = 0
  for _, r in ipairs(RV.module_rows(m)) do
    if RV.module_on(r) then
      n = n + 1
    end
  end
  return n
end

function RV.module_need(mm)
  for _, d in ipairs(INFO.needs(mm)) do
    if not d.ok and (mm.family == nil or d.key ~= mm.family.id) then
      return d.name
    end
  end
  return nil
end

function RV.module_name(r)
  local mm = r.mod
  if mm == nil then
    return RV.text_of(r.opt.label, r.opt.fallback ~= "" and r.opt.fallback or r.opt.key)
  end
  local title = RV.notes(mm).title
  if title ~= "" then
    return title
  end
  return mm.mname or (mm.name ~= "" and mm.name or mm.id)
end

function RV.draw_module_row(m, n, r, x, y, w, h, foc)
  local mm = r.mod
  local name = RV.module_name(r)
  local on = RV.module_on(r)
  local need = mm ~= nil and RV.module_need(mm) or nil
  local grey = need ~= nil and not on
  local cy = y + h / 2
  if foc then
    CE.focus("P1", x, y, w, h, 3)
  end
  -- a click on the row opens a module mod's page (Y); an internal module has none: it switches
  Hit(x, y, w, h, "mrow" .. n, function()
    ui.popup.mrow = n
    if mm ~= nil then
      RV.open_child(mm.id)
    else
      RV.module_toggle(m, n)
    end
  end)
  local ic = mm ~= nil and IconOf(mm) or nil
  if ic ~= nil then
    Quad("P1", ic[2], x + 10, cy - 15, 30, 30, grey and 0.6 or 1, ic[1])
  else
    Quad("P1", SP("iconbox"), x + 10, cy - 15, 30, 30, grey and 0.6 or 1)
    Txt("PC", "[CWG]" .. Initials({name = name, id = name}) .. "[C]", x + 25, cy - 1, 0.46)
  end
  local pw = 112
  local px = x + w - 10 - pw
  local vx = px - G.MOD_VER_W
  Txt("PL", (grey and "[CWG]" or "[CB]") .. Cut(name, Fit(vx - x - 70, 0.76)) .. "[C]", x + 54, cy, 0.76)
  if need ~= nil then
    Txt("PL", "[CR]" .. Cut(T("module_needs", {o = need}), Fit(G.MOD_VER_W - 10, 0.56)) .. "[C]", vx, cy, 0.56)
  elseif mm ~= nil and mm.version ~= "" then
    Txt("PL", "[CWG]v" .. Cut(mm.version, 12) .. "[C]", vx, cy, 0.6)
  end
  local pend = mm ~= nil and mm.pending
  Quad("P1", SP(pend and "pill_amber" or (on and "pill_green" or "pill_grey")), px, cy - 14, pw, 28, grey and 0.7 or 1)
  Txt("PC", T(on and "module_yes" or "module_no"), px + pw / 2, cy, 0.58)
  Hit(px - 4, cy - 18, pw + 8, 36, "mtog" .. n, function()
    ui.popup.mrow = n
    RV.module_toggle(m, n)
  end)
end

function RV.draw_module_pane(m, r)
  local x, w, y = G.MOD_PANE_X, G.MOD_PANE_W, RV.body_y() + 14
  local hh = G.MOD_PANE_HEAD
  local bottom = RV.foot_y() - 16
  local mm = r.mod
  Quad("P1", SP("hstripes"), x, y, 64, hh)
  Quad("P1", SP("hbar_l"), x + 44, y, 40, hh)
  Quad("P1", SP("hbar"), x + 84, y, w - 84, hh)
  for _, e in ipairs({{x, y + hh, 2, bottom - y - hh}, {x + w - 2, y + hh, 2, bottom - y - hh}, {x, bottom - 2, w, 2}}) do
    Quad("P1", SP("line"), e[1], e[2], e[3], e[4])
  end
  local name = RV.module_name(r)
  local ver = (mm ~= nil and mm.version ~= "") and ("   v" .. Cut(mm.version, 12)) or ""
  Txt("PL", Cut(name, Fit(w - 260, 0.8)) .. ver, x + 96, y + hh / 2, 0.8)
  -- the icon and two lines: the state, then the family · size
  local iy = y + hh + 18
  local ic = mm ~= nil and IconOf(mm) or nil
  if ic ~= nil then
    Quad("P1", ic[2], x + 24, iy, 96, 96, 1, ic[1])
  else
    Quad("P1", SP("iconbox_l"), x + 24, iy, 96, 96)
    Txt("PC", "[CWG]" .. Initials({name = name, id = name}) .. "[C]", x + 72, iy + 45, 1.3)
  end
  local st, sc
  if mm ~= nil then
    st, sc = INFO.state(mm)
    if sc == "[CB]" then
      sc = "[CG]"
    end
  else
    st, sc = T(RV.module_on(r) and "module_on" or "module_off"), RV.module_on(r) and "[CG]" or "[CWG]"
  end
  local tx, tw = x + 140, w - 164
  Txt("PL", sc .. Cut(st, Fit(tw, 0.74)) .. "[C]", tx, iy + 28, 0.74)
  local sub = mm ~= nil and T("module_of", {o = m.name ~= "" and m.name or m.id}) or T("module_internal")
  if mm ~= nil and Size(mm.size) ~= "" then
    sub = sub .. "  ·  " .. Size(mm.size)
  end
  Txt("PL", "[CWG]" .. Cut(sub, Fit(tw, 0.62)) .. "[C]", tx, iy + 68, 0.62)
  local cx, cw = x + 24, w - 48
  local ty = iy + 128
  Txt("PL", "[CN]" .. T("what_it_does") .. "[C]", cx, ty, 0.74)
  local notes = mm ~= nil and RV.notes(mm).notes or {}
  local lines = {}
  for k = 1, math.min(#notes, G.MOD_NOTES) do
    lines[#lines + 1] = "[CN]›[C]  [CB]" .. Cut(notes[k], Fit(cw - 30, 0.64)) .. "[C]"
  end
  if #lines == 0 then
    local desc = mm ~= nil and INFO.description(mm) or ""
    for _, l in ipairs(Wrap(desc ~= "" and desc or T("no_desc"), Fit(cw, 0.64), G.MOD_NOTES)) do
      lines[#lines + 1] = (desc ~= "" and "[CB]" or "[CWG]") .. l .. "[C]"
    end
  end
  for k, l in ipairs(lines) do
    Txt("PL", l, cx, ty + 6 + k * 30, 0.64)
  end
  if mm == nil then
    return
  end
  -- its settings: how many, and R3 / a click opens them on the module's page
  local sy = ty + 6 + G.MOD_NOTES * 30 + 28
  local ns = #RV.own_settings(mm.id)
  Quad("P1", SP("paper2"), cx, sy, cw, 44)
  if ns > 0 then
    Txt("PL", "[CN]" .. T("tab_settings") .. "[C]  [CB]" .. Cut(T("module_settings_count", {n = ns}), Fit(cw - 300, 0.64)) .. "[C]",
        cx + 16, sy + 22, 0.64)
    Txt("PR", "[CB]" .. K.R3 .. " " .. Cut(T("module_settings_open"), Fit(150, 0.62)) .. "[C]", cx + cw - 14, sy + 22, 0.62)
    Hit(cx, sy, cw, 44, "mset", function() RV.module_settings(m) end)
  else
    Txt("PL", "[CN]" .. T("tab_settings") .. "[C]  [CWG]" .. Cut(T("module_settings_none"), Fit(cw - 120, 0.64)) .. "[C]",
        cx + 16, sy + 22, 0.64)
  end
  -- "Requires": one row of chips
  local ny = sy + 78
  Txt("PL", "[CN]" .. T("f_needs") .. "[C]", cx, ny, 0.74)
  local needs, chx = INFO.needs(mm), cx
  if #needs == 0 then
    Txt("PL", "[CWG]" .. T("needs_none") .. "[C]", cx + 160, ny, 0.64)
  end
  for k = 1, math.min(#needs, G.MOD_CHIPS) do
    local d = needs[k]
    local s = Cut(d[1], 24)
    local chw = math.min(cx + cw - chx, math.floor(Units(s) * G.PX * 0.62) + 34)
    if chw < 80 then
      break
    end
    Quad("P1", SP(d.ok and "pill_green" or "pill_red"), chx, ny + 22, chw, 34)
    Txt("PL", Cut(s, Fit(chw - 24, 0.62)), chx + 14, ny + 39, 0.62)
    if d.mod ~= nil then
      Hit(chx, ny + 22, chw, 34, "mneed" .. k, function() RV.open_child(d.mod.id) end)
    end
    chx = chx + chw + 10
  end
  -- "Required by": one line with the names
  local users = INFO.needed_by(mm)
  local us = #users > 0 and ("[CB]" .. table.concat(users, "  ·  ") .. "[C]") or ("[CWG]" .. T("needed_by_none") .. "[C]")
  Txt("PL", "[CN]" .. T("f_needed_by") .. "[C]   " .. Cut(us, Fit(cw - 190, 0.64)), cx, ny + 92, 0.64)
end

function RV.draw_modules(m)
  local p = ui.popup
  local rows = RV.module_rows(m)
  local x, w = G.WIN_X + 32, G.MOD_LIST_W
  local top = RV.body_y() + 28
  local msize = 0
  for _, mm in ipairs(m.modules or {}) do
    msize = msize + (mm.size or 0)
  end
  local head = T("modules_head", {n = #rows, k = RV.modules_on(m)}) .. "  ·  " ..
               (msize > 0 and T("modules_size", {s = Size(m.size), z = Size(msize)}) or Size(m.size))
  Txt("PL", "[CB]" .. Cut(head, Fit(w - 220, 0.7)) .. "[C]", x, top, 0.7)
  local y0 = top + 26
  local avail = RV.foot_y() - 12 - y0
  local h = RV.MOD_STEP - 6
  p.mrow = math.max(1, math.min(p.mrow or 1, #rows))
  -- scroll by lines: the focused row on the page, with its category title when it is right above
  local lines = RV.module_lines(m)
  local sl = RV.module_line(lines, p.mrow)
  local tl = math.max(1, math.min(p.mline or 1, sl))
  if tl > 1 and lines[tl - 1].head ~= nil then
    tl = tl - 1
  end
  local function fits(a, b)
    local hsum, nrows = 0, 0
    for k = a, b do
      hsum = hsum + lines[k].h
      nrows = nrows + (lines[k].n ~= nil and 1 or 0)
    end
    return hsum <= avail and nrows <= RV.MOD_ROWS
  end
  while tl < sl and not fits(tl, sl) do
    tl = tl + 1
  end
  p.mline = tl
  -- the categories' counts: "K/N" after each title
  local on_in, all_in = {}, {}
  for _, r in ipairs(rows) do
    local gid = r.cat and r.cat.id or ""
    all_in[gid] = (all_in[gid] or 0) + 1
    on_in[gid] = (on_in[gid] or 0) + (RV.module_on(r) and 1 or 0)
  end
  local y, first, last, drawn = y0, nil, nil, 0
  for k = tl, #lines do
    local l = lines[k]
    local need = l.h + ((l.head ~= nil and lines[k + 1] ~= nil) and lines[k + 1].h or 0)   -- a title only with its first row
    if y + need > y0 + avail or (l.n ~= nil and drawn >= RV.MOD_ROWS) then
      break
    end
    if l.head ~= nil then
      Txt("PL", "[CN]" .. Cut(l.head, Fit(w - 120, 0.78)) .. "[C]  [CWG]" .. (on_in[l.gid] or 0) .. "/" .. (all_in[l.gid] or 0) .. "[C]",
          x, y + l.h / 2, 0.78)
    else
      first, last, drawn = first or l.n, l.n, drawn + 1
      RV.draw_module_row(m, l.n, rows[l.n], x, y + 3, w, h, l.n == p.mrow)   -- the pointer's hover moves p.mrow too (Hover)
    end
    y = y + l.h
  end
  -- the pages of the list above the rows: ↑ / ↓ and the keys that turn them (left / right)
  local function turn(n)
    p.mrow = n
    p.mline = RV.module_line(lines, n)
    funcLuaCommand(C.SE, SE_MOVE)
    Draw()
  end
  first, last = first or 1, last or #rows
  RV.pager(x + w, top, first, last, #rows, function()
    turn(math.max(1, first - (last - first + 1)))
  end, function()
    turn(math.min(#rows, last + 1))
  end)
  if rows[p.mrow] ~= nil then
    RV.draw_module_pane(m, rows[p.mrow])
  end
end

function RV.module_settings(m)
  local r = RV.module_rows(m)[ui.popup.mrow or 1]
  if r == nil or r.mod == nil or #RV.own_settings(r.mod.id) == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  RV.open_child(r.mod.id, "settings")
end
