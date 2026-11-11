local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local BASE, Badge, C, CE, Call = Screen.BASE, Screen.badge, Screen.C, Screen.CE, Screen.call
local ClosePopup, Cut, Draw, Fit, G, Hit = Screen.close_popup, Screen.cut, Screen.draw, Screen.fit, Screen.G, Screen.hit
local INFO, Initials, K, KeyOf = Screen.INFO, Screen.initials, Screen.K, Screen.key_of
local M, ModById, Quad, RV, SE_MOVE = Screen.M, Screen.mod_by_id, Screen.quad, Screen.RV, Screen.SE_MOVE
local SE_NG, SE_OK, SP, Size, StartCo = Screen.SE_NG, Screen.SE_OK, Screen.SP, Screen.size, Screen.start_co
local Str, T, Text, Thumb, Toggle, Txt = Screen.str, Screen.T, Screen.text, Screen.thumb, Screen.toggle, Screen.txt
local Units, Warnings, Wrap, cnt, mouse = Screen.units, Screen.warnings, Screen.wrap, Screen.cnt, Screen.mouse
local ui = Screen.ui

-- the body of a mod's page: under the header band and the view tabs, above the shortcut bar
function RV.body_y()
  return G.WIN_Y + G.BAND_H + G.VTABS_H
end

function RV.foot_y()
  return G.WIN_Y + G.WIN_H - G.FOOT_H
end

-- "author · updated · size · place in the load order" (a module: "Module of <parent>" first)
function RV.meta(m)
  local out = {}
  if m.family ~= nil then
    out[#out + 1] = T("module_of", {o = m.family.name})
  end
  out[#out + 1] = m.author ~= "" and m.author or T("no_author_short")
  local d, sz = Text(m, 9), Size(m.size)
  if d ~= "" then
    out[#out + 1] = d
  end
  if sz ~= "" then
    out[#out + 1] = sz
  end
  if m.enabled and m.pos > 0 and m.family == nil then
    out[#out + 1] = T("meta_position", {n = m.pos, t = cnt.active})
  end
  return table.concat(out, "  ·  ")
end

-- The docked page of mod `m` in the right pane: the header band and the white body.
local function PopupWindow(m)
  local x, y, w, h = G.WIN_X, G.WIN_Y, G.WIN_W, G.BAND_H
  Quad("P0", SP("tile" .. INFO.tile(m)), x, y, w, h)
  Quad("P0", SP("white"), x, y + h + G.VTABS_H, w, G.WIN_H - h - G.VTABS_H, G.BACKDROP_ALPHA)
  -- the compact header: the mod's picture (16:9) or its icon (mod.toml `icon`, else its initials), no big cover tile
  local ch = G.COVER_H
  local cx, cy = x + 24, y + (h - ch) / 2
  local t = Thumb(m)
  local cw = ch
  if t ~= nil then
    cw = G.COVER_W
    Quad("P1", t[3], cx, cy, cw, ch, 1, t[1])
  elseif not CE.draw_icon("P1", m, cx, cy, cw, 1) then
    Quad("P1", SP("iconbox_l"), cx, cy, cw, ch)
    Txt("PC", "[CWG]" .. Initials(m) .. "[C]", cx + cw / 2, cy + ch / 2 - 2, 1.2)
  end
  local tx = cx + cw + 24
  local tw = x + w - 300 - tx
  local name = m.name ~= "" and m.name or m.id
  Txt("PL", Cut(name, Fit(tw - 150, 1.2)) .. (m.version ~= "" and ("   v" .. Cut(m.version, 12)) or ""), tx, y + 32, 1.2)
  Txt("PL", Cut(RV.meta(m), Fit(tw, 0.7)), tx, y + 72, 0.7)
  -- the state pill and, while the page has the keys, "Back to the list" (B, Esc or a click); a page opened over another goes back to it
  local bs, bt = Badge(m)
  local pw = 230
  Quad("P1", SP(bs), x + w - 28 - pw, y + 50, pw, 38)
  Txt("PC", Cut(bt, Fit(pw - 20, 0.64)), x + w - 28 - pw / 2, y + 69, 0.64)
  if CE.page_focused() then
    Txt("PR", K.B .. " " .. T(ui.popup.back ~= nil and "hint_back" or "hint_to_list"), x + w - 28, y + 24, 0.72)
    Hit(x + w - 240, y, 240, 44, "pclose", function() ClosePopup() end)
  end
end

local function PopupButton(label, filled, sel, act, id, glyph)
  local bw, bh = 300, 48
  local bx, by = G.WIN_X + G.WIN_W - 28 - bw, RV.foot_y() + (G.FOOT_H - bh) / 2
  Quad("P1", SP((filled and "btn_on" or "btn_off") .. (sel and "_sel" or "")), bx, by, bw, bh)
  local s = (glyph ~= nil and (glyph .. " ") or "") .. Cut(label, Fit(bw - (glyph ~= nil and 56 or 24), 0.78))
  Txt("PC", (filled and "" or "[CN]") .. s .. (filled and "" or "[C]"), bx + bw / 2, by + bh / 2, 0.78)
  Hit(bx, by, bw, bh, id, act)
end

-- the page's action buttons: the switch of a mod; none for the framework (it always loads)
local function PopupButtons(m)
  if m.id == BASE then
    return {}
  end
  return {{id = "pb1", label = T(m.enabled and "btn_disable" or "btn_enable"), filled = not m.enabled,
           act = function() StartCo(Toggle) end}}
end

function RV.views(m)
  local v = {"info"}
  if RV.has_modules(m) then
    v[#v + 1] = "modules"
  end
  v[#v + 1] = "problems"
  v[#v + 1] = "conflicts"
  v[#v + 1] = "settings"
  if #RV.notes(m).notes > 0 then
    v[#v + 1] = "news"
  end
  return v
end

function RV.view()
  return ui.popup ~= nil and ui.popup.view or "info"
end

-- the place of the open view among the page's tabs (0 = no page)
function RV.view_index()
  local p = ui.popup
  local m = p and ModById(p.id)
  if m == nil then
    return 0
  end
  for k, v in ipairs(RV.views(m)) do
    if v == p.view then
      return k
    end
  end
  return 0
end

-- open view `v` of the page (its scroll and focus from the start)
function RV.go(v)
  local p = ui.popup
  if p == nil then
    return
  end
  funcLuaCommand(C.SE, SE_MOVE)
  p.view, p.top, p.full, p.srow, p.szone, p.stop = v, 0, nil, 1, "rows", 0
  Draw()
end

-- the changelog summary of mod `m` in the game's language: {title, notes} (read once per page opening)
function RV.notes(m)
  local ck = "notes:" .. m.id
  local r = RV.cache[ck]
  if r == nil then
    if Screen.lang() == nil then
      Screen.set_lang(Call(C.LANG) or 1)
    end
    local title, notes = Call(M.NOTES, m.id, Screen.lang())
    r = {title = Str(title), notes = CE.lines(Str(notes))}
    RV.cache[ck] = r
  end
  return r
end

-- the shortcuts of the open view, one per entry: "<glyphs> <what it does>"
function RV.keys(m)
  local p, v, out = ui.popup, RV.view(), {}
  local function add(glyphs, key)
    out[#out + 1] = (glyphs ~= "" and (glyphs .. " ") or "") .. T(key)
  end
  if not CE.page_focused() then
    add(K.START, "sc_open_page")
    return out
  end
  if p.full then
    add("", "sc_scroll")
    add(K.B, "hint_back")
    return out
  end
  if v == "info" then
    add(K.A, "sc_select")
    add(K.X, "sc_description")
  elseif v == "modules" then
    add(K.A, "sc_module_toggle")
    add(K.Y, "sc_module_page")
    add(K.R3, "sc_module_settings")
  elseif v == "settings" then
    add(K.A, "sc_change")
    add(K.Y, "sc_default")
    add(K.X, "sc_reset_mod")
  elseif v == "conflicts" then
    add(K.R3, "sc_who")
  end
  add(K.L2 .. K.R2, "sc_tabs")
  if m.enabled and m.family == nil and m.id ~= BASE then
    add(K.L1 .. K.R1, "sc_order")
  end
  add(K.B, p.back ~= nil and "hint_back" or "hint_to_list")
  return out
end

function RV.action_focused(m)
  local p, v = ui.popup, RV.view()
  if p.full or v == "modules" then
    return false
  end
  if v == "info" then
    return RV.info_target(m).kind == "action"
  end
  if v == "settings" then
    return p.szone == "buttons" or #RV.set_rows(m) == 0
  end
  return true
end

function RV.footer(m)
  local y = RV.foot_y()
  Quad("P1", SP("line"), G.WIN_X + 24, y, G.WIN_W - 48, 2)
  local s = ui.toast or table.concat(RV.keys(m), "    ")
  Txt("PL", "[CB]" .. Cut(s, Fit(G.WIN_W - 380, 0.64)) .. "[C]", G.WIN_X + 32, y + G.FOOT_H / 2, 0.64)
  local pb = PopupButtons(m)[1]
  if pb == nil then
    return
  end
  local hot = (mouse.on and mouse.hot == pb.id) or (not mouse.on and CE.page_focused() and RV.action_focused(m))
  PopupButton(pb.label, pb.filled, hot, pb.act, pb.id, RV.view() == "modules" and not ui.popup.full and K.X or nil)
end

-- One line of chips from x (wrapping into at most `maxrows` rows of width w): {text, sprite, icon, id, act, foc}.
function RV.chips(items, x, y, w, maxrows)
  local cx, rows = x, 1
  for _, it in ipairs(items) do
    local tw = math.min(w, math.floor(Units(it.text) * G.PX * 0.68) + (it.icon and 64 or 34))
    if cx > x and cx + tw > x + w then
      rows = rows + 1
      if rows > maxrows then
        break
      end
      cx, y = x, y + 50
    end
    Quad("P0", SP(it.sprite), cx, y, tw, 40)
    local t0 = cx + 17
    if it.icon then
      Quad("P1", SP(it.icon), cx + 10, y + 6, 28, 28)
      t0 = cx + 46
    end
    Txt("PL", Cut(it.text, Fit(tw - (t0 - cx) - 10, 0.68)), t0, y + 20, 0.68)
    if it.foc then
      CE.focus("P1", cx, y, tw, 40, 3)
    end
    if it.act ~= nil then
      Hit(cx, y, tw, 40, it.id, it.act)
    end
    cx = cx + tw + 10
  end
  return y + 50
end

-- "keeper_scenes" -> "Keeper scenes": the words of an id
function RV.words(id)
  local s = string.gsub(id, "[_%.%-]+", " ")
  return (string.gsub(s, "^%l", string.upper))
end

function RV.offers(m)
  local out = {}
  for item in string.gmatch(INFO.provides(m), "[^,]+") do
    local name = string.match(item, "^%s*([%w_%.%-]+)")
    if name ~= nil and KeyOf(name) ~= m.id then
      local s = CE.key_text(m.id .. ".provides_" .. name)
      if s == "" then
        local o = ModById(name)
        s = (o ~= nil and o.name ~= "") and o.name or RV.words(name)
      end
      out[#out + 1] = s
    end
  end
  return out
end

function RV.info_targets(m)
  local out = {}
  for i, d in ipairs(INFO.needs(m)) do
    if d.mod ~= nil and i <= 5 then
      out[#out + 1] = {kind = "chip", id = d.mod.id}
    end
  end
  out[#out + 1] = {kind = "desc"}
  if #PopupButtons(m) > 0 then
    out[#out + 1] = {kind = "action"}
  end
  return out
end

function RV.info_target(m)
  local t = RV.info_targets(m)
  local p = ui.popup
  p.ifoc = math.max(1, math.min(p.ifoc or #t, #t))
  return t[p.ifoc]
end

function RV.info_move(m, d)
  local t = RV.info_targets(m)
  local p = ui.popup
  local k = math.max(1, math.min(#t, (p.ifoc or #t) + d))
  funcLuaCommand(C.SE, k ~= p.ifoc and SE_MOVE or SE_NG)
  p.ifoc = k
  Draw()
end

function RV.draw_info(m)
  if ui.popup.full then
    RV.draw_full(m)
    return
  end
  local top, foot = RV.body_y() + 34, RV.foot_y()
  local lx, lw = G.WIN_X + 40, G.INFO_TEXT_W
  local rx = lx + lw + 60
  local rw = G.WIN_X + G.WIN_W - 40 - rx
  local target = RV.info_target(m)
  local pad = not mouse.on and CE.page_focused()
  Quad("P0", SP("line"), rx - 32, top - 14, 2, foot - top - 10)
  Txt("PL", "[CN]" .. T("what_it_does") .. "[C]", lx, top, 0.86)
  local y, ylim = top + 46, foot - 130
  local notes = RV.notes(m).notes
  if #notes > 0 then
    for i = 1, math.min(5, #notes) do
      local ls = Wrap(notes[i], Fit(lw - 30, 0.74), 2)
      if y + (#ls - 1) * 30 > ylim then
        break
      end
      for j, l in ipairs(ls) do
        Txt("PL", (j == 1 and "[CN]›[C]  " or "") .. "[CB]" .. l .. "[C]", lx + (j == 1 and 0 or 25), y + (j - 1) * 30, 0.74)
      end
      y = y + #ls * 30 + 10
    end
  else
    local desc = INFO.description(m)
    for _, l in ipairs(Wrap(desc ~= "" and desc or T("no_desc"), Fit(lw, 0.74), 8)) do
      Txt("PL", (desc ~= "" and "[CB]" or "[CWG]") .. l .. "[C]", lx, y, 0.74)
      y = y + 30
    end
  end
  local warn = (m.enabled and m.state == 1) and {true, T("state_skip", {r = Text(m, 1)})} or Warnings(m)[1]
  if warn ~= nil then
    local wy = foot - 110
    Quad("P1", SP(warn[1] and "warn_r" or "warn_a"), lx, wy - 14, 28, 28)
    Txt("PL", (warn[1] and "[CR]" or "[CY]") .. Cut(warn[2], Fit(lw - 40, 0.66)) .. "[C]", lx + 38, wy, 0.66)
  end
  local bw, bh, by = 430, 46, foot - 74
  local foc = (mouse.on and mouse.hot == "pfull") or (pad and target.kind == "desc")
  Quad("P1", SP(foc and "btn_off_sel" or "btn_off"), lx, by, bw, bh)
  Txt("PC", "[CN]" .. K.X .. " " .. Cut(T("full_desc"), Fit(bw - 70, 0.72)) .. "[C]", lx + bw / 2, by + bh / 2, 0.72)
  Hit(lx, by, bw, bh, "pfull", function() RV.open_full() end)
  -- the "Requires" section title
  Txt("PL", "[CN]" .. T("f_needs") .. "[C]", rx, top, 0.86)
  y = top + 26
  local needs = INFO.needs(m)
  if #needs == 0 then
    Txt("PL", "[CWG]" .. T("needs_none") .. "[C]", rx, y + 20, 0.72)
    y = y + 50
  else
    local items = {}
    for i, d in ipairs(needs) do
      if i > 5 then
        break
      end
      local it = {text = d.ok and d[1] or (d[1] .. "  ·  " .. d.reason), sprite = d.ok and "pill_green" or "pill_red",
                  icon = d.ok and "ok" or "no"}
      if d.mod ~= nil then
        local id = d.mod.id
        it.id = "need" .. i
        it.act = function() RV.open_child(id) end
        it.foc = (mouse.on and mouse.hot == it.id) or (pad and target.kind == "chip" and target.id == id)
      end
      items[#items + 1] = it
    end
    y = RV.chips(items, rx, y, rw, 2)
  end
  -- the "Offers to other mods" section title
  y = y + 18
  Txt("PL", "[CN]" .. T("offers") .. "[C]", rx, y, 0.86)
  local offers = RV.offers(m)
  local ls = Wrap(#offers > 0 and table.concat(offers, "  ·  ") or T("offers_none"), Fit(rw, 0.72), 3)
  for i, l in ipairs(ls) do
    Txt("PL", (#offers > 0 and "[CB]" or "[CWG]") .. l .. "[C]", rx, y + 40 + (i - 1) * 30, 0.72)
  end
  y = y + 40 + #ls * 30 + 10
  -- the "Tags" section title
  Txt("PL", "[CN]" .. T("f_tags") .. "[C]", rx, y, 0.86)
  local tags = {}
  for i, t in ipairs(CE.mod_tags(m)) do
    if i > 4 then
      break
    end
    tags[#tags + 1] = {text = t, sprite = "pill_blue"}
  end
  if #tags == 0 then
    Txt("PL", "[CWG]" .. INFO.DASH .. "[C]", rx, y + 40, 0.72)
  else
    RV.chips(tags, rx, y + 22, rw, 2)
  end
end

function RV.open_full()
  local p = ui.popup
  if p == nil or p.view ~= "info" then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  p.full, p.ftop = true, 1
  Draw()
end

function RV.folder(m)
  local f = Str(Call(M.FOLDER, m.id))
  return "mods/" .. (f ~= "" and f or m.id)
end

-- the lines of the whole description and the technical details (read once per page opening)
function RV.full_lines(m)
  local ck = "full:" .. m.id
  if RV.cache[ck] ~= nil then
    return RV.cache[ck]
  end
  local w = Fit(G.WIN_W - 100, 0.74)
  local out = {}
  local _, _, all = INFO.description(m)
  for _, l in ipairs(Wrap(all ~= "" and all or T("no_desc"), w, 1000)) do
    out[#out + 1] = l ~= "" and ((all ~= "" and "[CB]" or "[CWG]") .. l .. "[C]") or ""
  end
  out[#out + 1] = ""
  out[#out + 1] = "[CN]" .. T("details_tech") .. "[C]"
  local function field(label, value)
    if value ~= "" then
      for _, l in ipairs(Wrap(label .. ": " .. value, w, 6)) do
        out[#out + 1] = "[CWG]" .. l .. "[C]"
      end
    end
  end
  field(T("f_folder"), RV.folder(m))
  field(T("f_requires"), INFO.requires(m))
  field(T("f_conflicts"), (string.gsub(Text(m, 3), "\n", ", ")))
  field(T("f_provides"), INFO.provides(m))
  field(T("f_permissions"), INFO.perms(m))
  local ws = {}
  if m.enabled and m.state == 1 then
    ws[#ws + 1] = {true, T("state_skip", {r = Text(m, 1)})}
  end
  for _, x in ipairs(Warnings(m)) do
    ws[#ws + 1] = x
  end
  for l in string.gmatch(Str(Call(M.AU_NOTES, m.id)), "[^\n]+") do
    local wf, tx = string.match(l, "^(%d)|(.*)$")
    if tx ~= nil then
      ws[#ws + 1] = {wf == "1", T("au_note", {t = tx})}
    end
  end
  for _, x in ipairs(ws) do
    for _, l in ipairs(Wrap(x[2], w, 3)) do
      out[#out + 1] = (x[1] and "[CR]" or "[CY]") .. l .. "[C]"
    end
  end
  RV.cache[ck] = out
  return out
end

function RV.pager(xr, y, first, last, total, prev, next)
  if total <= last - first + 1 then
    return
  end
  local back, fwd = first > 1, last < total
  local s = (back and "[CN]↑[C]" or "[CWG]↑[C]") .. " " .. K.LEFT .. "  [CB]" ..
            T("report_rows", {n = first, c = last, t = total}) .. "[C]  " .. K.RIGHT .. " " .. (fwd and "[CN]↓[C]" or "[CWG]↓[C]")
  Txt("PR", s, xr, y, 0.66)
  local w = math.floor(Units(s) * G.PX * 0.66 * 0.82)
  Hit(xr - w, y - 20, w / 2, 40, "pgback", function()
    if back then prev() else funcLuaCommand(C.SE, SE_NG) end
  end)
  Hit(xr - w / 2, y - 20, w / 2, 40, "pgnext", function()
    if fwd then next() else funcLuaCommand(C.SE, SE_NG) end
  end)
end

function RV.draw_full(m)
  local p = ui.popup
  local lines = RV.full_lines(m)
  local x, top = G.WIN_X + 40, RV.body_y() + 34
  local y0, vis = top + 50, RV.FULL_ROWS
  p.ftop = math.max(1, math.min(p.ftop or 1, math.max(1, #lines - vis + 1)))
  Txt("PL", "[CN]" .. T("full_desc_title") .. "[C]", x, top, 0.86)
  RV.pager(G.WIN_X + G.WIN_W - 40, top, p.ftop, math.min(#lines, p.ftop + vis - 1), #lines, function()
    p.ftop = math.max(1, p.ftop - vis)
    funcLuaCommand(C.SE, SE_MOVE)
    Draw()
  end, function()
    p.ftop = p.ftop + vis
    funcLuaCommand(C.SE, SE_MOVE)
    Draw()
  end)
  for i = 0, vis - 1 do
    local l = lines[p.ftop + i]
    if l == nil then
      break
    end
    Txt("PL", l, x, y0 + i * 30, 0.74)
  end
end

-- for 100_mods_screen.lua and the files after this one
Screen.popup_window = PopupWindow
Screen.popup_buttons = PopupButtons
