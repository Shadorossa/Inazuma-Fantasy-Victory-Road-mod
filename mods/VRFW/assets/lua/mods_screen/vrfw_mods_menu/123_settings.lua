local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local Ask, C, CE, Call, Crc, Cut, Draw, FN = Screen.ask, Screen.C, Screen.CE, Screen.call, Screen.crc, Screen.cut, Screen.draw, Screen.FN
local Fit, G, Hit, Initials, Int = Screen.fit, Screen.G, Screen.hit, Screen.initials, Screen.int
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
    local k, kind, storage, label, fallback, get, set, _gated, _fixed, parent, help, help_fb, category, default, restart, started_with =
      Call(RV.OPT.ROW, i)
    if type(k) == "string" then
      all[#all + 1] = {key = k, kind = Str(kind), storage = Str(storage), label = Int(label), fallback = Str(fallback),
                       get = Int(get), set = Int(set), help = Int(help), help_fb = Str(help_fb), category = Int(category),
                       default = type(default) == "number" and default or nil, restart = restart == true,
                       parent = type(parent) == "string" and parent or nil,
                       started_with = type(started_with) == "number" and started_with or nil}
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

-- The text of value `v`, its 0-based position among the row's values and how many values the row has (nil, nil without a value list).
function RV.fmt(r, v)
  if r.module ~= nil then
    local k = v == 1 and "module_on" or "module_off"
    return T(r.module.pending and (k .. "_next") or k), v, 2
  end
  local id, fb, position, count = Call(RV.OPT.TEXT, r.key, v)
  if type(id) ~= "number" then
    return tostring(v)
  end
  local s = RV.text_of(id, Str(fb))
  if type(position) ~= "number" or type(count) ~= "number" then
    position, count = nil, nil
  end
  return s ~= "" and s or tostring(v), position, count
end

-- Stores value `n` where row `r` keeps it; true when it was taken.
function RV.store(r, n)
  if r.storage == "command" then
    return Call(r.set, n) == true
  end
  return Call(RV.OPT.SET, r.key, n) == true
end

-- What value `v` says about row `r`: it differs from the default, and it waits for a restart.
function RV.row_state(r, v)
  local changed = r.module == nil and r.default ~= nil and v ~= nil and v ~= r.default
  local pending = r.restart == true and r.started_with ~= nil and v ~= nil and v ~= r.started_with
  return changed, pending
end

-- Y on a setting: the focused row goes back to its default value.
function RV.restore_default(m)
  local r = RV.set_rows(m)[ui.popup.srow or 1]
  local v, live = nil, false
  if r ~= nil and r.module == nil then
    v, live = RV.value(r)
  end
  local ok = live and (RV.row_state(r, v)) and RV.store(r, r.default)
  funcLuaCommand(C.SE, ok and SE_MOVE or SE_NG)
  if ok then
    Log("setting", r.key, "default")
  end
  Draw()
end

-- X on the settings: after a yes, every changed setting of the mod and of its modules goes back to its default value.
function RV.restore_mod(m)
  local changed = {}
  for _, r in ipairs(RV.set_rows(m)) do
    if r.module == nil and (RV.row_state(r, (RV.value(r)))) then
      changed[#changed + 1] = r
    end
  end
  if #changed == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if Ask(T("set_reset_ask", {n = #changed, name = m.name ~= "" and m.name or m.id})) then
    for _, r in ipairs(changed) do
      RV.store(r, r.default)
    end
    Log("settings", m.id, "defaults", #changed)
  end
  Draw()
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
      ok = RV.store(r, n)
    end
  end
  funcLuaCommand(C.SE, ok and SE_MOVE or SE_NG)
  if ok then
    Log("setting", r.key, tostring(n))
  end
  Draw()
end

RV.HEAD_H, RV.ROW_H, RV.SET_ROWS = 34, 46, 11
-- where a page draws its settings rows: quad / left text / centred text layers, section bar height
RV.PAGE_ROW = {q = "P1", l = "PL", c = "PC", bar_h = RV.HEAD_H - 6}
-- The retail atlases a setting row is drawn from (the Options menu's row pieces, the list window's check box, the alert icons).
RV.ART = {
  option = "#/menu/108_option/option01/option01_02/option01_02.g4tx",
  window = "#/menu/10_win/win05/win05_02/win05_02.g4tx",
  alert = "#/menu/20_cmn/cmn01/cmn01_10/cmn01_10.g4tx",
  changed = "#/menu/20_cmn/cmn01/cmn01_12/cmn01_12.g4tx",
}
-- A setting row's measures: child indent, where the value zone starts (share of the plate), check box side, mark side,
-- the fewest values that draw a gauge, the opacity of a row that cannot change.
RV.ROW = {CHILD_INDENT = 30, VALUE_FROM = 0.61, CHECK_SIDE = 26, MARK_SIDE = 24, GAUGE_MIN_VALUES = 8, LOCKED_OPACITY = 0.55,
          LABEL_SCALE = 0.7, VALUE_SCALE = 0.66, NOTE_SCALE = 0.5}

-- Sprite `sprite` of retail atlas `atlas` (a key of RV.ART) as a quad.
function RV.art_quad(layer, atlas, sprite, x, y, w, h, alpha)
  return Quad(layer, Crc(sprite), x, y, w, h, alpha, CE.texture(RV.ART[atlas]))
end

-- The retail check box at x, vertical middle cy: its base and, when on, its tick.
function RV.draw_check(layer, x, cy, on, alpha)
  local s = RV.ROW.CHECK_SIDE
  RV.art_quad(layer, "window", "icon_check_base03", x, cy - s / 2, s, s, alpha)
  if on then
    RV.art_quad(layer, "window", "icon_check01", x - 2, cy - s / 2 - 4, s + 6, s + 6, alpha)
  end
end

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
  if not CE.draw_icon(style.q, mm, x + 8, y + 3, h - 6, 1) then
    Txt(style.c, Initials({name = name, id = name}), x + 8 + (h - 6) / 2, y + h / 2, 0.5)
  end
  Txt(style.l, Cut(name, Fit(w - 80, 0.66)), x + h + 14, y + h / 2, 0.66)
end

-- a category's sub-header inside its mod: its name only, no plate
function RV.draw_category_bar(style, category, x, y, w)
  local name = RV.text_of(category, "")
  Txt(style.l, Cut(name, Fit(w - 24, 0.58)), x + 12, y + style.bar_h / 2, 0.58)
end

-- The value zone of a row (from x0 to x1): the picker arrows on the focused row, then a check box, a gauge or the value's text.
function RV.draw_value(style, r, v, live, focused, x0, x1, y, h)
  local R = RV.ROW
  local cy, mid = y + h / 2, (x0 + x1) / 2
  local ink = focused and "" or (live and "[CB]" or "[CWG]")
  local close = ink ~= "" and "[C]" or ""
  if r.module == nil and (r.kind == "lua" or r.storage == "lua") then
    Txt(style.c, ink .. Cut(T("set_lua"), Fit(x1 - x0, R.NOTE_SCALE)) .. close, mid, cy, R.NOTE_SCALE)
    return
  end
  if v == nil then
    Txt(style.c, ink .. T("set_unknown") .. close, mid, cy, R.VALUE_SCALE)
    return
  end
  if focused and live then
    RV.art_quad(style.q, "option", "btn_arrow_l01", x0 + 6, cy - 17, 28, 34)
    RV.art_quad(style.q, "option", "btn_arrow_r01", x1 - 34, cy - 17, 28, 34)
  end
  local text, position, count = RV.fmt(r, v)
  text = Cut(text, Fit(x1 - x0 - 130, R.VALUE_SCALE))
  if count == 2 and (r.module ~= nil or r.kind == "toggle") then
    local tw = Units(text) * G.PX * R.VALUE_SCALE
    RV.draw_check(style.q, mid - tw / 2 - R.CHECK_SIDE, cy, v == 1, live and 1 or R.LOCKED_OPACITY)
    Txt(style.c, ink .. text .. close, mid + 14, cy, R.VALUE_SCALE)
  elseif count ~= nil and count >= R.GAUGE_MIN_VALUES then
    Txt(style.c, ink .. text .. close, mid, cy - 6, R.VALUE_SCALE)
    local gx, gw = x0 + 52, x1 - x0 - 104
    RV.art_quad(style.q, "option", "gauge_base01", gx, y + h - 11, gw, 6)
    local fill = math.floor(gw * position / (count - 1))
    if fill > 0 then
      RV.art_quad(style.q, "option", "gauge_bar01", gx, y + h - 11, fill, 6)
    end
  else
    Txt(style.c, ink .. text .. close, mid, cy, R.VALUE_SCALE)
  end
end

-- The value zone (x0, x1) of row r drawn at x, w wide (a child row is indented).
function RV.value_zone(r, x, w)
  if r.parent ~= nil then
    x, w = x + RV.ROW.CHILD_INDENT, w - RV.ROW.CHILD_INDENT
  end
  return x + math.floor(w * RV.ROW.VALUE_FROM), x + w - 20
end

-- One setting row in the Options menu's look: plate (the child plate under a parent row), changed mark, label, restart mark, default, value.
function RV.draw_row(style, r, x, y, w, h, focused)
  local R = RV.ROW
  local x0, x1 = RV.value_zone(r, x, w)
  local v, live = RV.value(r)
  local child = r.parent ~= nil
  if child then
    x, w = x + R.CHILD_INDENT, w - R.CHILD_INDENT
  end
  local cy = y + h / 2
  RV.art_quad(style.q, "option", (child and "option_list_base03_" or "option_list_base02_") .. (focused and "on" or "off"), x, y, w, h,
              live and 1 or R.LOCKED_OPACITY)
  local ink = focused and "" or (live and "[CB]" or "[CWG]")
  local close = ink ~= "" and "[C]" or ""
  local changed, pending = RV.row_state(r, v)
  local tx = x + (child and math.floor(w * 0.085) or 36)
  if changed then
    RV.art_quad(style.q, "changed", "icon_new03", tx - R.MARK_SIDE - 4, cy - R.MARK_SIDE / 2, R.MARK_SIDE, R.MARK_SIDE)
  end
  local right = x0 - 12
  if changed then
    -- The default value ends where the value zone starts.
    local s = Cut(T("set_default_is", {v = (RV.fmt(r, r.default))}), Fit(170, R.NOTE_SCALE))
    right = right - math.floor(Units(s) * G.PX * R.NOTE_SCALE)
    Txt(style.l, (focused and "" or "[CWG]") .. s .. (focused and "" or "[C]"), right, cy, R.NOTE_SCALE)
    right = right - 12
  end
  local note = pending and T("set_on_restart") or nil
  local room = right - tx - (r.restart and (R.MARK_SIDE + 10) or 0) - (note ~= nil and math.floor(Units(note) * G.PX * R.NOTE_SCALE) + 8 or 0)
  local label, chip = RV.set_label(r)
  if chip ~= nil then
    label = chip .. " · " .. label
  end
  label = Cut(label, Fit(room, R.LABEL_SCALE))
  Txt(style.l, ink .. label .. close, tx, cy, R.LABEL_SCALE)
  if r.restart then
    local mx = tx + math.floor(Units(label) * G.PX * R.LABEL_SCALE) + 10
    RV.art_quad(style.q, "alert", "icon_error01", mx, cy - R.MARK_SIDE / 2, R.MARK_SIDE, R.MARK_SIDE)
    if note ~= nil then
      Txt(style.l, (focused and "" or "[CY]") .. note .. (focused and "" or "[C]"), mx + R.MARK_SIDE + 6, cy, R.NOTE_SCALE)
    end
  end
  RV.draw_value(style, r, v, live, focused, x0, x1, y, h)
end

-- The value lines of a setting's sheet from y: now, default and, on a restart row, when a change applies.
function RV.draw_set_values(style, r, x, y)
  local v = RV.value(r)
  local lines = {}
  if v ~= nil then
    lines[#lines + 1] = {"set_now", (RV.fmt(r, v))}
    if r.module == nil and r.default ~= nil then
      lines[#lines + 1] = {"set_default", (RV.fmt(r, r.default))}
    end
  end
  if r.restart then
    lines[#lines + 1] = {"set_applies", T("set_on_restart")}
  end
  for k, l in ipairs(lines) do
    Txt(style.l, "[CWG]" .. T(l[1]) .. ":[C]  [CB]" .. Cut(l[2], 40) .. "[C]", x, y + (k - 1) * 30, 0.64)
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
  RV.draw_set_values(style, r, x, ty + G.SET_HELP_LINES * 30 + 14)
end

-- the focused setting's strip under a page's rows (y = its top): a bar with its label, its help at the left, its values at the right
function RV.draw_set_strip(r, x, y, w)
  local hh = 40
  Quad("P1", SP("hbar"), x, y, w, hh)
  Txt("PL", Cut((RV.set_label(r)), Fit(w - 40, 0.72)), x + 20, y + hh / 2, 0.72)
  local hw = math.floor(w * 0.64)
  local help = RV.set_help(r)
  for k, l in ipairs(Wrap(help ~= "" and help or T("set_no_help"), Fit(hw - 20, 0.62), G.SET_STRIP_LINES)) do
    Txt("PL", (help ~= "" and "[CB]" or "[CWG]") .. l .. "[C]", x + 20, y + hh + 24 + (k - 1) * 30, 0.62)
  end
  RV.draw_set_values(RV.PAGE_ROW, r, x + hw + 20, y + hh + 24)
end

function RV.draw_settings(m)
  local rows = RV.set_rows(m)
  local px, py = G.WIN_X + 32, RV.body_y() + 14
  local w = G.WIN_W - 64
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
  local strip_y = RV.foot_y() - G.SET_STRIP_H
  local bottom = strip_y - 40         -- above the page line and the focused setting's strip
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
  local y, first, last, drawn = py, nil, nil, 0
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
      local foc = CE.page_focused() and p.szone ~= "buttons" and n == sel
      RV.draw_row(RV.PAGE_ROW, rows[n], px, y, w, RV.ROW_H - 4, foc)
      Hit(px, y, w, RV.ROW_H - 4, "set" .. n, function() RV.activate(m, n) end)   -- hover moves p.srow too (Hover)
      if foc then
        -- A click on a picker arrow of the focused row steps its value back or on.
        local x0, x1 = RV.value_zone(rows[n], px, w)
        Hit(x0, y, 40, RV.ROW_H - 4, "arrow_l", function() RV.change(m, -1, rows[n]) end)
        Hit(x1 - 40, y, 40, RV.ROW_H - 4, "arrow_r", function() RV.change(m, 1, rows[n]) end)
      end
    end
    y = y + l.h
  end
  -- where the page is, and the short note on where these values live
  local note = T("set_note")
  if first ~= nil and (first > 1 or last < #rows) then
    note = T("report_rows", {n = first, c = last, t = #rows}) .. "   ·   " .. note
  end
  Txt("PL", "[CWG]" .. Cut(note, Fit(w, 0.58)) .. "[C]", px, bottom + 20, 0.58)
  RV.draw_set_strip(rows[sel], px, strip_y, w)
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
