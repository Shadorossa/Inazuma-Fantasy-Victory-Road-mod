local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local Ask, C, CE, Call, Crc, Cut, Draw, FN = Screen.ask, Screen.C, Screen.CE, Screen.call, Screen.crc, Screen.cut, Screen.draw, Screen.FN
local Fit, G, Hit, Initials, Int = Screen.fit, Screen.G, Screen.hit, Screen.initials, Screen.int
local Log, ModById, PopupButtons, PopupWindow = Screen.log, Screen.mod_by_id, Screen.popup_buttons, Screen.popup_window
local Quad, RV, SE_MOVE, SE_NG, SP, Str = Screen.quad, Screen.RV, Screen.SE_MOVE, Screen.SE_NG, Screen.SP, Screen.str
local T, TextIdKey, Txt, Units, Wrap, ui = Screen.T, Screen.text_id_key, Screen.txt, Screen.units, Screen.wrap, Screen.ui
local BASE = Screen.BASE

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

-- The settings list the keys and the pointer act on: the docked page's, else the Settings tab's.
function RV.set_state()
  return ui.popup or ui.all_settings
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
  local r = RV.set_rows(m)[RV.set_state().srow or 1]
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
  local r = row or RV.set_rows(m)[RV.set_state().srow or 1]
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

RV.HEAD_H, RV.ROW_H = 28, 38
-- where a page draws its settings rows: quad / left text / centred text layers, section bar height
RV.PAGE_ROW = {q = "P1", l = "PL", c = "PC", bar_h = RV.HEAD_H}
-- the Settings tab's first column: the screen's own layers (its backdrop is on Q0, under them)
RV.TAB_ROW = {q = "Q1", l = "TL", c = "TC", bar_h = RV.HEAD_H}
-- The retail atlases a setting row is drawn from (the Options menu's row pieces, the list window's check box, the alert icons).
RV.ART = {
  option = "#/menu/108_option/option01/option01_02/option01_02.g4tx",
  window = "#/menu/10_win/win05/win05_02/win05_02.g4tx",
  alert = "#/menu/20_cmn/cmn01/cmn01_10/cmn01_10.g4tx",
  changed = "#/menu/20_cmn/cmn01/cmn01_12/cmn01_12.g4tx",
}
-- A setting row's measures (screen px; the sprites are atlas.rs size::SET_*): child indent, check box side, mark side,
-- the fewest values that draw a slider, the opacity of a row that cannot change, the text scales.
RV.ROW = {CHILD_INDENT = 22, CHECK_SIDE = 26, MARK_SIDE = 24, GAUGE_MIN_VALUES = 8, LOCKED_OPACITY = 0.55,
          LABEL_SCALE = 0.66, VALUE_SCALE = 0.62, NOTE_SCALE = 0.5,
          GAP = 4,                                   -- between two rows (plate height = RV.ROW_H - GAP)
          CAP_W = 12, VALUE_W = 252, TREE_SIDE = 16,  -- plate start, value box, tree mark (atlas sizes)
          LABEL_X = 30, TREE_W = 26, LABEL_MIN_W = 260, MARKS_W = 56,   -- label start, tree room, label column floor, mark column
          TRACK_X = 34, TRACK_Y = 8,                 -- the slider track inside the value box: inset from each end, from the bottom
          HELP_GAP = 24, HELP_MIN_W = 320, HELP_LINES = 8,   -- the help pane right of the rows
          HELP_BAR_H = 40, HELP_LINE_H = 28, VALUE_LINE_H = 30,   -- the help's title bar, one help line, one value line
          COL_GAP = 48,                              -- between two columns of rows
          STRIP_GAP = 16, STRIP_VALUES_W = 520, STRIP_PAD = 10,   -- the help strip under the columns: gap above, value block, padding
          STRIP_HELP_LINES = 3}                      -- the most help lines the strip shows (its height follows, the rows above get the rest)

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
  local p = RV.set_state()
  p.srow, p.szone = n, "rows"
  RV.change(m, 1)
end

-- The pad on the settings rows of mod `m` (a page's "Settings" view or the Settings tab).
function RV.settings_key(id, m)
  local rows = m and RV.set_rows(m) or {}
  if #rows == 0 then
    return false
  end
  local p = RV.set_state()
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
  elseif p.grid ~= nil and p.grid.cols > 1 then
    p.srow = sel
    moved(RV.column_move(p, id == FN.LEFT and -1 or 1))
  else
    p.srow = sel
    RV.change(m, id == FN.LEFT and -1 or 1)
  end
  return true
end

-- Left / right on rows drawn in columns (p.grid from RV.draw_settings): the focus goes to the row at the nearest height
-- of the column d (±1) away, past the page's edge to the next / previous page. false = no column there.
function RV.column_move(p, d)
  local pages = p.grid.pages
  for pk, page in ipairs(pages) do
    for c, col in ipairs(page) do
      for _, e in ipairs(col) do
        if e.n == p.srow then
          local to = page[c + d]
          if to == nil and pages[pk + d] ~= nil then
            local np = pages[pk + d]
            to = np[d > 0 and 1 or #np]
          end
          if to == nil then
            return false
          end
          local best = to[1]
          for _, t in ipairs(to) do
            if math.abs(t.y - e.y) < math.abs(best.y - e.y) then
              best = t
            end
          end
          p.srow = best.n
          return true
        end
      end
    end
  end
  return false
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

-- a module's section header: its name and a thin line to the rows' end (one quad)
function RV.draw_group_bar(style, mm, x, y, w)
  local h = style.bar_h
  local name = Cut(RV.group_name(mm), Fit(w - 60, 0.6))
  Txt(style.l, "[CN]" .. name .. "[C]", x + 4, y + h / 2, 0.6)
  local lx = x + 18 + math.floor(Units(name) * G.PX * 0.6)
  if lx < x + w then
    Quad(style.q, SP("line"), lx, math.floor(y + h / 2), x + w - lx, 2)
  end
end

-- a category's sub-header inside its mod: its name only, no plate
function RV.draw_category_bar(style, category, x, y, w)
  local name = RV.text_of(category, "")
  Txt(style.l, Cut(name, Fit(w - 24, 0.58)), x + 12, y + style.bar_h / 2, 0.58)
end

-- The value box of a row (from x0, R.VALUE_W wide): the box, the picker arrows on the focused row, then a check box, a slider or the value's text.
function RV.draw_value(style, r, v, live, focused, x0, y, h)
  local R = RV.ROW
  local x1 = x0 + R.VALUE_W
  local cy, mid = y + h / 2, x0 + R.VALUE_W / 2
  local alpha = live and 1 or R.LOCKED_OPACITY
  local ink = focused and "" or (live and "[CB]" or "[CWG]")
  local close = ink ~= "" and "[C]" or ""
  local text, position, count = nil, nil, nil
  if v ~= nil and not (r.module == nil and (r.kind == "lua" or r.storage == "lua")) then
    text, position, count = RV.fmt(r, v)
  end
  local slider = count ~= nil and count >= R.GAUGE_MIN_VALUES
  Quad(style.q, SP("set_val" .. (slider and "_g" or "") .. (focused and "_sel" or "")), x0, y, R.VALUE_W, h, alpha)
  if r.module == nil and (r.kind == "lua" or r.storage == "lua") then
    Txt(style.c, ink .. Cut(T("set_lua"), Fit(R.VALUE_W - 30, R.NOTE_SCALE)) .. close, mid, cy, R.NOTE_SCALE)
    return
  end
  if v == nil then
    Txt(style.c, ink .. T("set_unknown") .. close, mid, cy, R.VALUE_SCALE)
    return
  end
  if focused and live then
    Quad(style.q, SP("set_arr_l"), x0 + 12, math.floor(cy - 10), 12, 20)
    Quad(style.q, SP("set_arr_r"), x1 - 24, math.floor(cy - 10), 12, 20)
  end
  text = Cut(text, Fit(R.VALUE_W - 70, R.VALUE_SCALE))
  if count == 2 and (r.module ~= nil or r.kind == "toggle") then
    local tw = Units(text) * G.PX * R.VALUE_SCALE
    RV.draw_check(style.q, mid - tw / 2 - R.CHECK_SIDE, cy, v == 1, alpha)
    Txt(style.c, ink .. text .. close, mid + 14, cy, R.VALUE_SCALE)
  elseif slider then
    -- the slider's fill on the box's own track (R.TRACK_X from each end, R.TRACK_Y above the bottom)
    Txt(style.c, ink .. text .. close, mid, cy - 4, R.VALUE_SCALE)
    local gw = R.VALUE_W - 2 * R.TRACK_X
    local fill = math.floor(gw * position / (count - 1))
    if fill > 0 then
      Quad(style.q, SP(focused and "cyan" or "blue"), x0 + R.TRACK_X, y + h - R.TRACK_Y, fill, 3, alpha)
    end
  else
    Txt(style.c, ink .. text .. close, mid, cy, R.VALUE_SCALE)
  end
end

-- The widest label among rows `rows` (screen px at the label scale).
function RV.label_width(rows)
  local w = 0
  for _, r in ipairs(rows) do
    local label, chip = RV.set_label(r)
    if chip ~= nil then
      label = chip .. " · " .. label
    end
    w = math.max(w, math.floor(Units(label) * G.PX * RV.ROW.LABEL_SCALE))
  end
  return w
end

-- The plate width of a page's rows: label column (the widest label, clamped), the mark column, the value box.
function RV.plate_width(rows, w)
  local R = RV.ROW
  local fixed = R.LABEL_X + R.TREE_W + R.MARKS_W + R.VALUE_W
  return math.min(w - R.HELP_MIN_W, fixed + math.max(R.LABEL_MIN_W, RV.label_width(rows)))
end

-- The value box's left edge of row r on a plate drawn at x, w wide.
function RV.value_x(x, w)
  return x + w - RV.ROW.VALUE_W
end

-- One setting row: plate (start + stretched body, 1:1 sprites), tree mark of a child row, label, mark column (changed, restart), value box.
function RV.draw_row(style, r, x, y, w, h, focused)
  local R = RV.ROW
  local v, live = RV.value(r)
  local alpha = live and 1 or R.LOCKED_OPACITY
  local child = r.parent ~= nil
  local px = child and x + R.CHILD_INDENT or x
  local vx = RV.value_x(x, w)
  local cy = y + h / 2
  local sel = focused and "_sel" or ""
  Quad(style.q, SP("set_l" .. sel), px, y, R.CAP_W, h, alpha)
  Quad(style.q, SP("set_m" .. sel), px + R.CAP_W, y, vx - px, h, alpha)   -- the body runs on under the value box
  local tx = x + R.LABEL_X
  if child then
    Quad(style.q, SP("set_tree" .. sel), px + 12, math.floor(cy - R.TREE_SIDE / 2), R.TREE_SIDE, R.TREE_SIDE, alpha)
    tx = tx + R.TREE_W
  end
  local ink = focused and "" or (live and "[CB]" or "[CWG]")
  local close = ink ~= "" and "[C]" or ""
  local changed = RV.row_state(r, v)
  -- the mark column right before the value box: changed (left slot), restart (right slot)
  local mx = vx - R.MARKS_W
  if changed then
    RV.art_quad(style.q, "changed", "icon_new03", mx, math.floor(cy - R.MARK_SIDE / 2), R.MARK_SIDE, R.MARK_SIDE)
  end
  if r.restart then
    RV.art_quad(style.q, "alert", "icon_error01", mx + R.MARK_SIDE + 4, math.floor(cy - R.MARK_SIDE / 2), R.MARK_SIDE, R.MARK_SIDE)
  end
  local label, chip = RV.set_label(r)
  if chip ~= nil then
    label = chip .. " · " .. label
  end
  label = Cut(label, Fit(mx - 8 - tx, R.LABEL_SCALE))
  Txt(style.l, ink .. label .. close, tx, cy, R.LABEL_SCALE)
  RV.draw_value(style, r, v, live, focused, vx, y, h)
end

-- The value lines of a setting's help pane from y: now, default and, on a restart row, when a change applies.
function RV.draw_set_values(style, r, x, y, w)
  local v = RV.value(r)
  local lines = {}
  if v ~= nil then
    lines[#lines + 1] = {"set_now", (RV.fmt(r, v))}
    if r.module == nil and r.default ~= nil then
      lines[#lines + 1] = {"set_default", (RV.fmt(r, r.default))}
    end
  end
  if r.restart then
    local _, pending = RV.row_state(r, v)
    lines[#lines + 1] = {"set_applies", T("set_on_restart"), pending}
  end
  for k, l in ipairs(lines) do
    local value = Cut(l[2], Fit(w - math.floor(Units(T(l[1])) * G.PX * 0.6) - 30, 0.6))
    Txt(style.l, "[CWG]" .. T(l[1]) .. ":[C]  " .. (l[3] and "[CY]" or "[CB]") .. value .. "[C]", x, y + (k - 1) * 30, 0.6)
  end
end

-- the value lines a setting's help shows (RV.draw_set_values): now, default, when a change applies
function RV.value_lines(r)
  local v = RV.value(r)
  local n = v ~= nil and 1 or 0
  if v ~= nil and r.module == nil and r.default ~= nil then
    n = n + 1
  end
  return n + (r.restart and 1 or 0)
end

-- the help text of row r as wrapped lines `units` wide (at most RV.ROW.HELP_LINES), and whether it has its own help
function RV.help_lines(r, units, maxl)
  local help = RV.set_help(r)
  return Wrap(help ~= "" and help or T("set_no_help"), units, maxl or RV.ROW.HELP_LINES), help ~= ""
end

-- the focused setting's help pane right of the rows (x, y = its top left, w x h): a bar with its label, its help, its values
function RV.draw_set_help(r, x, y, w, h)
  local R = RV.ROW
  local hh = R.HELP_BAR_H
  Quad("P1", SP("hbar"), x, y, w, hh)
  Txt("PL", Cut((RV.set_label(r)), Fit(w - 32, 0.66)), x + 16, y + hh / 2, 0.66)
  local lines, own = RV.help_lines(r, Fit(w - 32, 0.6), math.max(1, math.min(R.HELP_LINES, math.floor((h - hh - 140) / R.HELP_LINE_H))))
  for k, l in ipairs(lines) do
    Txt("PL", (own and "[CB]" or "[CWG]") .. l .. "[C]", x + 16, y + hh + 24 + (k - 1) * R.HELP_LINE_H, 0.6)
  end
  RV.draw_set_values(RV.PAGE_ROW, r, x + 16, y + hh + 24 + #lines * R.HELP_LINE_H + 20, w - 32)
end

-- The help strip under the columns (x, y, w wide): a bar with the focused setting's label, its help at the left, its
-- values at the right.
function RV.draw_set_strip(r, x, y, w)
  local R = RV.ROW
  local hh = R.HELP_BAR_H
  Quad("P1", SP("hbar"), x, y, w, hh)
  Txt("PL", Cut((RV.set_label(r)), Fit(w - 32, 0.66)), x + 16, y + hh / 2, 0.66)
  local lines, own = RV.help_lines(r, Fit(w - 48 - R.STRIP_VALUES_W, 0.6), R.STRIP_HELP_LINES)
  local ty = y + hh + R.STRIP_PAD + R.HELP_LINE_H / 2
  for k, l in ipairs(lines) do
    Txt("PL", (own and "[CB]" or "[CWG]") .. l .. "[C]", x + 16, ty + (k - 1) * R.HELP_LINE_H, 0.6)
  end
  RV.draw_set_values(RV.PAGE_ROW, r, x + w - R.STRIP_VALUES_W, ty, R.STRIP_VALUES_W - 16)
end

-- The strip's height for rows `rows` on a frame w wide: room for the longest help and the most value lines among them,
-- so no setting's help is cut and the columns above keep one height on every page.
function RV.strip_height(rows, w)
  local R = RV.ROW
  local ck = "set_strip:" .. tostring(rows) .. ":" .. w
  local h = RV.cache[ck]
  if h == nil then
    local units, hl, vl = Fit(w - 48 - R.STRIP_VALUES_W, 0.6), 1, 1
    for _, r in ipairs(rows) do
      hl = math.max(hl, #(RV.help_lines(r, units, R.STRIP_HELP_LINES)))
      vl = math.max(vl, RV.value_lines(r))
    end
    h = R.HELP_BAR_H + 2 * R.STRIP_PAD + math.max(hl * R.HELP_LINE_H, vl * R.VALUE_LINE_H)
    RV.cache[ck] = h
  end
  return h
end

-- The instances one line of the settings draws per layer kind (q quads, l left texts, c centred texts): a section bar,
-- or a row with its plate, tree mark, marks and value box pieces (the focused row's picker arrows are kept apart).
function RV.line_cost(l, rows)
  if l.kind == "head" then
    return l.group ~= nil and 1 or 0, 1, 0
  end
  local r = rows[l.items[1]]
  local v = RV.value(r)
  local q = 3 + (r.parent ~= nil and 1 or 0) + (RV.row_state(r, v) and 1 or 0) + (r.restart and 1 or 0)
  local count = nil
  if v ~= nil and not (r.module == nil and (r.kind == "lua" or r.storage == "lua")) then
    count = select(3, RV.fmt(r, v))
  end
  if count == 2 and (r.module ~= nil or r.kind == "toggle") then
    q = q + 2
  elseif count ~= nil and count >= RV.ROW.GAUGE_MIN_VALUES then
    q = q + 1
  end
  return q, 1, 1
end

-- The pages of `lines` in columns `avail` high, one column a layer set of `free` ({q, l, c} instances left for it).
-- A column takes lines while they fit its height and its layers; a section bar goes only with its first row, so no
-- column ends on a bar, and a column starting inside a mod's rows repeats its bar.
-- pages[k][c] = the rows of column c: {n = row number, y = its offset from the top}; .lines = every line it draws.
function RV.pack_pages(lines, rows, avail, free)
  local pages, li = {}, 1
  while lines[li] ~= nil do
    local page = {}
    for c = 1, #free do
      local left = {q = free[c].q, l = free[c].l, c = free[c].c}
      local col, y = {lines = {}}, 0
      -- a column that starts inside a mod's rows repeats that mod's bar on top
      if lines[li] ~= nil and lines[li].kind == "row" then
        local j = li - 1
        while j > 0 and not (lines[j].kind == "head" and lines[j].group ~= nil) do
          j = j - 1
        end
        if j > 0 then
          col.lines[1] = {line = j, y = 0}
          y, left.q, left.l = lines[j].h, left.q - 1, left.l - 1
        end
      end
      while lines[li] ~= nil do
        local k, h, q, l, cc = li, 0, 0, 0, 0
        while true do
          local dq, dl, dc = RV.line_cost(lines[k], rows)
          h, q, l, cc = h + lines[k].h, q + dq, l + dl, cc + dc
          if lines[k].kind ~= "head" or lines[k + 1] == nil then
            break
          end
          k = k + 1
        end
        if y + h > avail or q > left.q or l > left.l or cc > left.c then
          break
        end
        for j = li, k do
          if lines[j].kind == "row" then
            col[#col + 1] = {n = lines[j].items[1], y = y, line = j}
          end
          col.lines[#col.lines + 1] = {line = j, y = y}
          y = y + lines[j].h
        end
        left.q, left.l, left.c = left.q - q, left.l - l, left.c - cc
        li = k + 1
      end
      if #col == 0 then
        break
      end
      page[#page + 1] = col
    end
    if #page == 0 then
      break   -- not even one row fits: the rest stays off the screen (Quad / Txt log the full layer)
    end
    pages[#pages + 1] = page
  end
  return pages
end

-- Where a mod page draws its settings: its body, the rows lit while the page has the keys.
function RV.page_set_frame()
  return {x = G.WIN_X + 32, y = RV.body_y() + 14, w = G.WIN_W - 64, bottom = RV.foot_y() - 40, focused = CE.page_focused(),
          styles = {RV.PAGE_ROW}}
end

-- The settings rows of mod `m` in frame `f` = {x, y, w, bottom (above the note), focused, styles (one layer set a column),
-- empty (text key), keys (note prefix)}. The columns as many as the width holds (at most one a style); one column has
-- the help pane at its right, more columns the help strip under them across the width. Each page fills the height.
function RV.draw_settings(m, f)
  local rows = m ~= nil and RV.set_rows(m) or {}
  local px, py, w = f.x, f.y, f.w
  local p = RV.set_state()
  p.grid = nil
  if #rows == 0 then
    local why = f.empty or ((m.enabled and m.state == 0 and not m.pending) and "set_none" or "set_inactive")
    for i, l in ipairs(Wrap(T(why), Fit(w - 16, 0.8), 3)) do
      Txt("PL", "[CN]" .. l .. "[C]", px, py + 26 + (i - 1) * 34, 0.8)
    end
    return
  end
  local R = RV.ROW
  local sel = math.max(1, math.min(p.srow or 1, #rows))
  p.srow = sel
  local lines = RV.layout(m)
  local bottom = f.bottom
  local col_min = R.LABEL_X + R.TREE_W + R.MARKS_W + R.VALUE_W + R.LABEL_MIN_W
  local cols = math.max(1, math.min(#f.styles, math.floor((w + R.COL_GAP) / (col_min + R.COL_GAP))))
  local pw, rows_bottom, reserve
  if cols > 1 then
    pw = math.floor((w - (cols - 1) * R.COL_GAP) / cols)
    local sh = RV.strip_height(rows, w)
    rows_bottom = bottom - R.STRIP_GAP - sh
    reserve = {P1 = 1, PL = 2 + math.floor((sh - R.HELP_BAR_H) / R.HELP_LINE_H) + 3}   -- the strip and the note line
  else
    pw = RV.plate_width(rows, w)
    rows_bottom = bottom
    reserve = {P1 = 1, PL = 2 + R.HELP_LINES + 3}   -- the help pane and the note line
  end
  -- the instances each column's layers still have, the focused row's two picker arrows and what the help draws kept back
  local free = {}
  for c = 1, cols do
    local s = f.styles[c]
    free[c] = {q = Screen.free(s.q) - 2 - (reserve[s.q] or 0), l = Screen.free(s.l) - (reserve[s.l] or 0),
               c = Screen.free(s.c) - (reserve[s.c] or 0)}
  end
  local pages = RV.pack_pages(lines, rows, rows_bottom - py, free)
  p.grid = {cols = cols, pages = pages}
  -- the page with the focused row
  local page = pages[1] or {}
  for _, pg in ipairs(pages) do
    for _, col in ipairs(pg) do
      for _, e in ipairs(col) do
        if e.n == sel then
          page = pg
        end
      end
    end
  end
  local first, last = nil, nil
  local h = RV.ROW_H - RV.ROW.GAP
  for c, col in ipairs(page) do
    local style = f.styles[c]
    local cx = px + (c - 1) * (pw + R.COL_GAP)
    for _, e in ipairs(col.lines) do
      local l = lines[e.line]
      local y = py + e.y
      if l.kind == "head" and l.group ~= nil then
        RV.draw_group_bar(style, l.group, cx, y, pw)
      elseif l.kind == "head" then
        RV.draw_category_bar(style, l.category, cx, y, pw)
      else
        local n = l.items[1]
        first, last = first or n, n
        local foc = f.focused and p.szone ~= "buttons" and n == sel
        RV.draw_row(style, rows[n], cx, y, pw, h, foc)
        Hit(cx, y, pw, h, "set" .. n, function() RV.activate(m, n) end)   -- hover moves p.srow too (Hover)
        if foc then
          -- A click on a picker arrow of the focused row steps its value back or on.
          local vx = RV.value_x(cx, pw)
          Hit(vx, y, 40, h, "arrow_l", function() RV.change(m, -1, rows[n]) end)
          Hit(vx + RV.ROW.VALUE_W - 40, y, 40, h, "arrow_r", function() RV.change(m, 1, rows[n]) end)
        end
      end
    end
  end
  -- where the page is, and the short note on where these values live
  local note = (f.keys or "") .. T("set_note")
  if first ~= nil and (first > 1 or last < #rows) then
    note = T("report_rows", {n = first, c = last, t = #rows}) .. "   ·   " .. note
  end
  Txt("PL", "[CWG]" .. Cut(note, Fit(w, 0.58)) .. "[C]", px, bottom + 20, 0.58)
  if cols > 1 then
    RV.draw_set_strip(rows[sel], px, rows_bottom + R.STRIP_GAP, w)
  else
    local hx = px + pw + R.HELP_GAP
    RV.draw_set_help(rows[sel], hx, py, px + w - hx, bottom - py)
  end
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

-- the active mods other than the framework in load order, and a signature of them
local function OtherActiveMods()
  local active, parts = {}, {}
  for _, m in ipairs(Screen.mods()) do
    if m.enabled and m.family == nil and m.id ~= BASE then
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
  for _, m in ipairs(active) do
    parts[#parts + 1] = m.id
    for _, mm in ipairs(m.modules or {}) do
      parts[#parts + 1] = mm.enabled and mm.id or ""
    end
  end
  return active, table.concat(parts, "|")
end

-- the framework's page and the Settings tab list every active mod's rows under that mod's bar, the framework first (modules under theirs)
local OwnRows = RV.set_rows
function RV.set_rows(m)
  if m.id ~= BASE then
    return OwnRows(m)
  end
  local active, sig = OtherActiveMods()
  local ck = "setrows_all:" .. sig
  local r = RV.cache[ck]
  if r == nil then
    r = {}
    table.insert(active, 1, m)
    for _, om in ipairs(active) do
      for _, o in ipairs(OwnRows(om)) do
        local row = {}
        for k, v in pairs(o) do
          row[k] = v
        end
        row.group = o.group or om
        r[#r + 1] = row
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
    RV.draw_settings(m, RV.page_set_frame())
  elseif v == "news" then
    RV.draw_news(m)
  else
    RV.draw(m, v == "problems" and 2 or 3)
  end
  RV.footer(m)
end

-- The Settings tab: the framework page's rows (every active mod's settings) on the screen's width under the tool row.
function CE.draw_all_settings()
  local x0, y0, x1, y1 = G.LIST_X, G.BOX_Y, G.WIN_X + G.WIN_W, G.BOX_BOTTOM
  Quad("Q0", SP("white"), x0, y0, x1 - x0, y1 - y0, G.BACKDROP_ALPHA)
  local K = Screen.K
  RV.draw_settings(Screen.base_mod(), {x = x0 + 32, y = y0 + 14, w = x1 - x0 - 64, bottom = y1 - 40, focused = ui.page == nil,
                                       styles = {RV.TAB_ROW, RV.PAGE_ROW}, empty = "set_none_all",
                                       keys = K.L1 .. K.R1 .. " " .. K.A .. " " .. T("sc_change") .. "   ·   "})
end

-- The Settings tab's label: its name and how many settings it lists.
function CE.all_settings_label()
  local m = Screen.base_mod()
  return T("tab_settings_all", {n = m ~= nil and #RV.set_rows(m) or 0})
end

-- A on the Settings tab: the focused row moves one step.
function CE.all_settings_decide()
  local m = Screen.base_mod()
  if m == nil or #RV.set_rows(m) == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  RV.activate(m, ui.all_settings.srow or 1)
end

-- L1 / R1 on the Settings tab: the focused row's value one step back / on.
function CE.all_settings_step(d)
  local m = Screen.base_mod()
  if m == nil or #RV.set_rows(m) == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  RV.change(m, d)
end

-- An arrow on the Settings tab: up / down move between rows, left / right between the columns (past the last, to the
-- next page).
function CE.all_settings_key(id)
  if not RV.settings_key(id, Screen.base_mod()) then
    funcLuaCommand(C.SE, SE_NG)
  end
end

-- Internal: for 100_mods_screen.lua and the files after this one
Screen.draw_details = DrawDetails
