local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local BASE, Badge, C, CE, Call, Cut = Screen.BASE, Screen.badge, Screen.C, Screen.CE, Screen.call, Screen.cut
local Fit, G, Hit, INFO, Initials, K = Screen.fit, Screen.G, Screen.hit, Screen.INFO, Screen.initials, Screen.K
local KeyOf, M, ModById, NameOf, Quad = Screen.key_of, Screen.M, Screen.mod_by_id, Screen.name_of, Screen.quad
local SP, SelectMod, StartCo, Str, T = Screen.SP, Screen.select_mod, Screen.start_co, Screen.str, Screen.T
local Text, TextIdKey, TileOf, Toggle, Txt = Screen.text, Screen.text_id_key, Screen.tile_of, Screen.toggle, Screen.txt
local cnt, mouse, ui = Screen.cnt, Screen.mouse, Screen.ui

-- (INFO: its layers and sizes are in 100_mods_screen.lua)

-- the state in two words and its colour
function INFO.state(m)
  if m.pending then
    return T(m.enabled and "st_pend_on" or "st_pend_off"), "[CY]"
  end
  if m.enabled and m.state == 1 then
    return T("st_skip"), "[CR]"
  end
  return T(m.enabled and "st_on" or "st_off"), m.enabled and "[CB]" or "[CWG]"
end

function INFO.provides(m)
  if m.provides_text == nil then
    m.provides_text = Str(Call(M.PROVIDES, m.id))
  end
  return m.provides_text
end

function INFO.requires(m)
  local raw = Text(m, 2)
  if raw == "" then
    return ""
  end
  local base, parts = ModById(BASE), {}
  if base ~= nil then
    for item in string.gmatch(INFO.provides(base), "[^,%s]+") do
      local n = string.match(item, "^([%w_]+)")
      if n ~= nil then
        parts[n] = true
      end
    end
  end
  local function need(op, ver)
    if ver == "" then
      return ""
    end
    if op == "" or op == ">=" then
      return " (" .. ver .. "+)"
    end
    return " (" .. op .. " " .. ver .. ")"
  end
  local fw, fwv, out, seen = false, "", {}, {}
  for req in string.gmatch(raw, "[^,\n]+") do
    local name, op, ver = string.match(req, "^%s*([%w_%.%-]+)%s*([<>=!~]*)%s*([^%s]*)%s*$")
    if name ~= nil then
      local key = KeyOf(name)
      if key == BASE or parts[name] then
        fw = true
        if key == BASE and ver ~= "" then
          fwv = need(op, ver)
        end
      elseif not seen[key] then
        seen[key] = true
        out[#out + 1] = NameOf(name) .. need(op, ver)
      end
    end
  end
  if fw then
    table.insert(out, 1, ((base ~= nil and base.name ~= "") and base.name or "VRFW") .. fwv)
  end
  return table.concat(out, ", ")
end

-- The colour of a mod's page header: the tile of its first tag.
INFO.TAG_TILE = {framework = 0, interface = 1, interfaz = 1, gameplay = 2, jugabilidad = 2, story = 3, historia = 3,
                 audio = 4, graphics = 5, ["gráficos"] = 5, tools = 6, herramientas = 6}
-- the mod's colour: the tile of its first tag, else one picked by its id
function INFO.tile(m)
  local tag = string.match(Text(m, 8), "^([^\n]+)") or ""
  return INFO.TAG_TILE[string.lower(tag)] or TileOf(m.id)
end

INFO.PERMS = {}
function INFO.perms(m)
  local p = INFO.PERMS[m.id]
  if p == nil then
    p = Str(Call(M.PERMS, m.id))
    INFO.PERMS[m.id] = p
  end
  return p
end

function INFO.description(m)
  local id = TextIdKey(m.id .. ".mod_description")
  local s = id ~= nil and Str(Call(C.TEXT_GET, id)) or ""
  if s == "" then
    s = Text(m, 0)
  end
  s = string.gsub(s, "\r", "")
  local first, rest = string.match(s, "^(.-)\n%s*\n(.*)$")
  if first ~= nil and string.find(rest, "%S") ~= nil then
    return first, true, s
  end
  return s, false, s
end

function CE.round_box(layer, flat, disc, x, y, w, h, r)
  Quad(layer, SP(flat), x + r, y, w - 2 * r, h)
  Quad(layer, SP(flat), x, y + r, r, h - 2 * r)
  Quad(layer, SP(flat), x + w - r, y + r, r, h - 2 * r)
  for _, c in ipairs({{x, y}, {x + w - 2 * r, y}, {x, y + h - 2 * r}, {x + w - 2 * r, y + h - 2 * r}}) do
    Quad(layer, SP(disc), c[1], c[2], 2 * r, 2 * r)
  end
end

-- the navy box of the list (it ends above the button guide), w wide (the whole width when nil)
function CE.list_box(w)
  if w ~= nil then
    -- the Mods tab's list pane: one plate at the backdrop's opacity (rounded corners would overlap their sides)
    Quad("Q0", SP("navy"), G.BOX_X, G.BOX_Y, w, G.BOX_BOTTOM - G.BOX_Y, G.BACKDROP_ALPHA)
    return
  end
  CE.round_box("Q0", "navy", "disc_navy", G.BOX_X, G.BOX_Y, G.BOX_W, G.BOX_BOTTOM - G.BOX_Y, G.BOX_R)
end

-- a mod's icon: its mod.toml `icon`, else its initials in the neutral frame; s = side (36 a row, 96 the panel)
function CE.icon(m, x, y, s)
  local big = s >= 60
  local a = (m.enabled or big) and 1 or 0.75
  if CE.draw_icon("Q1", m, x, y, s, a) then
    return
  end
  Quad("Q1", SP(big and "iconbox_l" or "iconbox"), x, y, s, s, a)
  Txt("TC", "[CWG]" .. Initials(m) .. "[C]", x + s / 2, y + s / 2 - (big and 3 or 1), big and 1.45 or 0.5)
end

-- One row of the Mods list: focused = it has the keys; current = the selected row while the page has them.
function CE.list_row(k, m, focused, row_id, tag_id, open, family, current)
  local x, y, w, h = G.LIST_X, G.LIST_Y + k * G.ROW_STEP, G.LIST_ROW_W, G.ROW_H
  local cy = y + h / 2
  local off = not m.enabled
  Quad("Q2", SP((off and "lplate_off" or "lplate") .. ((focused or current) and "_sel" or "")), x, y, w, h)
  if focused then
    Quad("Q1", SP("arrow_g"), x - 20, cy - 14, 18, 28)
  end
  if m.enabled and m.pos > 0 then
    Quad("Q1", SP("numbox"), x + 18, cy - 17, 34, 34)
    Txt("TC", "[CN]" .. m.pos .. "[C]", x + 35, cy, m.pos >= 100 and 0.5 or (m.pos >= 10 and 0.66 or 0.76))
  else
    Quad("Q1", SP("numbox_off"), x + 18, cy - 17, 34, 34)
  end
  CE.icon(m, x + 70, cy - 17, 34)
  local nm = m.name ~= "" and m.name or m.id
  if family and m.family ~= nil then
    nm = m.family.name .. " › " .. (m.mname or nm)
  end
  local tx = x + w - 150
  -- warnings and the pending restart: small marks left of the tag (the page shows version, size and author)
  local ix = tx - 34
  if m.level >= 2 or (m.enabled and m.state == 1) then
    Quad("Q1", SP("warn_r"), ix, cy - 14, 28, 28)
    ix = ix - 32
  elseif m.level == 1 or m.nwarn > 0 then
    Quad("Q1", SP("warn_a"), ix, cy - 14, 28, 28)
    ix = ix - 32
  end
  if m.pending then
    Quad("Q1", SP("pend"), ix, cy - 14, 28, 28)
    ix = ix - 32
  end
  Txt("TL", (off and "[CWG]" or "[CB]") .. Cut(nm, Fit(ix + 24 - (x + 122), 0.9)) .. "[C]", x + 122, cy, 0.9)
  -- the state tag: green "Enabled" / grey "Disabled"; the other states (restart, not loaded, update) in words
  local bs, bt = Badge(m)
  if bs == "pill_green" or bs == "pill_grey" then
    bt = T(m.enabled and "card_on" or "card_off")
  end
  Quad("Q1", SP(bs), tx, cy - 13, 122, 26, off and 0.9 or 1)
  Txt("TC", Cut(bt, Fit(114, 0.6)), tx + 61, cy, 0.6)
  if mouse.on and mouse.hot == tag_id then
    CE.focus("Q1", tx, cy - 13, 122, 26, 2)
  end
  Hit(x, y, w, h, row_id, open)
  Hit(tx - 4, cy - 17, 130, 34, tag_id, function() SelectMod(m.id) StartCo(Toggle) end)
end

-- the info panel's frame: the header bar (diagonal stripes, the blue bar to the screen's edge) and the white body
function CE.panel_frame()
  local x, y, hh = G.PANEL_X, G.PANEL_Y, G.PANEL_HEAD
  Quad("Q0", SP("hstripes"), x, y, 64, hh)
  Quad("Q0", SP("hbar_l"), x + 44, y, 40, hh)
  Quad("Q0", SP("hbar"), x + 84, y, 1920 - (x + 84), hh)
  CE.round_box("Q0", "white", "disc_white", x, G.PANEL_BODY_Y, G.PANEL_W, G.PANEL_BODY_H, G.PANEL_R)
end

-- the framework's parts (the names its mod.toml `provides`): a requirement on one is a requirement on the framework
function INFO.base_parts()
  local parts = {}
  local base_mod = Screen.base_mod()
  if base_mod ~= nil then
    for item in string.gmatch(INFO.provides(base_mod), "[^,%s]+") do
      local n = string.match(item, "^([%w_%.%-]+)")
      if n ~= nil then
        parts[n] = true
      end
    end
  end
  return parts
end

-- the installed mod that answers requirement `name`: the mod of that id, else one whose `provides` names it
function INFO.provider(name)
  local d = ModById(name)
  if d ~= nil then
    return d
  end
  for _, o in ipairs(Screen.mods()) do
    for item in string.gmatch(INFO.provides(o), "[^,%s]+") do
      local n = string.match(item, "^([%w_%.%-]+)")
      if n ~= nil and string.lower(n) == string.lower(name) then
        return o
      end
    end
  end
  return nil
end

function INFO.needs(m)
  if m.needs ~= nil then
    return m.needs
  end
  local old = {}
  for line in string.gmatch(Text(m, 7), "[^\n]+") do
    local kind, other = string.match(line, "^(%a+)|([^|]*)|")
    if kind == "version" and other ~= nil then
      old[other] = true
    end
  end
  local out, seen, parts = {}, {}, INFO.base_parts()
  for req in string.gmatch(Text(m, 2), "[^,\n]+") do
    local name, op, ver = string.match(req, "^%s*([%w_%.%-]+)%s*([<>=!~]*)%s*([^%s]*)%s*$")
    if name ~= nil then
      local own = KeyOf(name)
      local key = (own == BASE or parts[name]) and BASE or own
      if not seen[key] then
        seen[key] = true
        local d = key == BASE and Screen.base_mod() or INFO.provider(name)
        local short = (d ~= nil and d.name ~= "") and d.name or (key == BASE and "VRFW" or name)
        local label = short
        if key == own and ver ~= "" then
          label = label .. ((op == "" or op == ">=") and (" (" .. ver .. "+)") or (" (" .. op .. " " .. ver .. ")"))
        end
        local row
        if d == nil then
          row = {label, T("dep_missing"), "[CR]"}
        else
          row = {label, T(d.enabled and "st_on" or "st_off"), d.enabled and "[CG]" or "[CWG]"}
        end
        local too_old = old[name] or old[key] or old[own] or (d ~= nil and old[d.id])
        row.key, row.mod, row.name = key, d, short
        row.ok = d ~= nil and d.enabled and not too_old
        row.reason = (d == nil and T("dep_missing")) or (too_old and T("dep_old")) or ((not d.enabled) and T("st_off")) or ""
        if key == BASE then
          table.insert(out, 1, row)
        else
          out[#out + 1] = row
        end
      end
    end
  end
  m.needs = out
  return out
end

-- "Required by": the names of the installed mods whose `requires` names this mod (its id or a name it provides)
function INFO.needed_by(m)
  if m.needed_by ~= nil then
    return m.needed_by
  end
  local mine = {[m.id] = true}
  for item in string.gmatch(INFO.provides(m), "[^,%s]+") do
    local n = string.match(item, "^([%w_%.%-]+)")
    if n ~= nil then
      mine[n] = true
    end
  end
  local out = {}
  for _, o in ipairs(Screen.mods()) do
    if o ~= m then
      for req in string.gmatch(Text(o, 2), "[^,\n]+") do
        local name = string.match(req, "^%s*([%w_%.%-]+)")
        if name ~= nil and (mine[name] or mine[KeyOf(name)]) then
          out[#out + 1] = o.name ~= "" and o.name or o.id
          break
        end
      end
    end
  end
  m.needed_by = out
  return out
end
