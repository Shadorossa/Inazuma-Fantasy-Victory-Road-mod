-- lua_patch.scope: used

VRFW.synergy = VRFW.synergy or {}
local S = VRFW.synergy
if S.apply_panel ~= nil then return end     -- defined once per menu VM
S.CMD_PANEL = S.CMD_PANEL or VRFW.commands.VRFW_SYNERGY_PANEL
local CMD_TEXT_GET = VRFW.commands.TEXT_GET
local CMD_LANGUAGE = VRFW.commands.GET_LANGUAGE_CODE
local CMD_ITEM_OF_INV = 2662166687
local SET_TEXT = VRFW.commands.SET_MENU_TEXT_STRING                -- (layer, node, text, instance)
local SET_MESH_VISIBLE = VRFW.commands.SET_MESH_VISIBLE        -- (layer, mesh, visible, instance)
local PRIM_COLOR = VRFW.commands.SET_PRIM_COLOR               -- (layer, instance, mesh, r, g, b) (multiplier 0..1)
local PRIM_ALPHA = VRFW.commands.SET_PRIM_ALPHA              -- (layer, instance, mesh, alpha)
local C = {
  IS_EXIST_LAYER = VRFW.commands.IS_EXIST_LAYER,              -- (layer) -> true when the menu has it
  OPEN_LAYER = VRFW.commands.OPEN_LAYER,                  -- (layer, instance)
  LAYER_VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,               -- (layer, instance, visible)
  LOCAL_POS = VRFW.commands.SET_LAYER_LOCAL_POS,
  LOCAL_SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,                -- (layer, sx, sy, sz, instance)
  NODE_VISIBLE = 2158717427,               -- (layer, node, visible, instance)
  TEXT_VISIBLE = VRFW.commands.SET_MENU_TEXT_VISIBLE,               -- (layer, text node, visible, instance)
  GPOS = VRFW.commands.GET_MESH_GLOBAL_POSITION,
  EMBLEM = 3190452549,                     -- (layer, instance, mesh, texture slot, item_emblem id, 0)
  RESET_FACE = 4176779611,                 -- (layer, instance, texture slot)
}

local ROW = 4041512772                     -- team16_03_synergy_chara_condition_list
local N_ROWS = 3                           -- the panel's largest layout
local DETAIL = 1473585342
-- the detail layouts' attach joints the game's rows hang on (the same names in team16_02 and team16_05), per layout
local ROW_JOINTS = {
  [2] = { 4288612777, 1721128979 },               -- _atc_list02_01 / _atc_list02_02 (1 or 2 rows drawn)
  [3] = { 1193504460, 3727310710, 2838302688 },   -- _atc_list03_01 .. _atc_list03_03 (3 rows drawn)
}
local LOCATOR_TRACE = VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE   -- (layer, instance, locator, on)
local TEXT_NAME = 1704438437               -- _text_name01 (row name; the detail's title)
local FACE = 478320441                     -- _icon_chr_dmy01 (the face icon's mesh)
local FACE_SLOT = 3237726902               -- icon_chr_dmy01 (its texture slot)
local FACE_BASE = 1042467758               -- _chr_base01 (the plate behind the face)
local LINE = 2519428701                    -- _chr_line01 (the row's line)
local CHECK_BOX = 4051829508               -- _icon_check_box01
local CHECK = 2309656400                   -- _icon_check01
local SERIES = { 3231997250, 1504513272, 782908526 }   -- _icon_series_dmy01..03
local TXT_MISSING = 787277494              -- VRFW.SynergyNexusMissing
local TXT_ROLE = { manager = 172090118, coach = 3665956829 }   -- VRFW.SynergyRoleManager / VRFW.SynergyRoleCoach
local CMD_SERIES_ICON = VRFW.commands.VRFW_SERIES_ICON          -- (series) -> ok, sheet, sprite
local CMD_ROLE_ICON = VRFW.commands.VRFW_ROLE_ICON           -- (role) -> ok, sheet, sprite
local SPRITE = 558735651
local ORANGE = { 1.0, 0.55, 0.12 }         -- the nexus row's tint (the name: [CMODE03] = 247 107 0)
local GHOST = { 0.62, 0.62, 0.62 }         -- a missing nexus's face / an empty slot's plate: grey ...
local GHOST_ALPHA = 0.45                   -- Translucent.
local WHITE = { 1, 1, 1 }
local KIND_NEXUS, KIND_NEXUS_MISSING, KIND_FILLED, KIND_EMPTY = 1, 2, 3, 4

local L_CREST, N_CREST = 527765702, 36
local L_FACE, N_FACE = 734603085, 72
local L_ICON, N_ICON = 1263105521, 24
local L_ROW, N_CLONES = 3982581158, 6
local GRID_MIN, GRID_MAX = 4, 6
local GRID_COLS = 0.5
local ROW_WIDTH = 800
local log = VRFW.logger.new("VRFW synergy rows")
local ROW_RIGHT = 764                      -- the right edge of the series icons: the extras end there
local ANCHOR_A, ANCHOR_AX, ANCHOR_AY = 4051829508, -16, 16   -- _icon_check_box01 at (-16, 16)
local ANCHOR_B, ANCHOR_BX, ANCHOR_BY = 3231997250, 706, 14   -- _icon_series_dmy01 at (706, 14)
local CREST_PX, CREST_STEP = 52, 56
local SQUARE_CREST_PX = 52
local EMBLEM_PX = 84                       -- the tile's emblem quad
local TILE_MESH, TILE_SLOT = 1926542734, 618311715   -- _enjoy_list_icon_dmy01 / enjoy_list_icon_dmy01
local TILE_HIDE = { 2668225226, 1751802610, 3159751709, 155260060, 688408036, 2291119251, 1323396684, 294053161,
                    2968134629, 100709232, 1763834249 }
-- the plates' nodes (under _pos_enjoy_list01: _p1 / _p2 hold the two team-colour hexagon sets) and the player tags
local TILE_HIDE_NODES = { 3808539401, 2047402675, 1061671357, 2790162439 }   -- _pos_enjoy_list01_p1 / _p2, _pos_1p01 / 02
local TILE_NODE = 3933090681
local FACE_SCALE, FACE_STEP = 0.6, 44      -- a candidate's plate (64) and face at 0.6, pitch in row units
local FACE_X0, FACE_X1 = 31, 95            -- the plate's x extent in the row object
local IS_VISIBLE = VRFW.commands.IS_LAYER_VISIBLE             -- (layer, instance) -> true when shown
local ICON_MESH, ICON_SLOT = 3231997250, 201452450
local ICON_W, ICON_PITCH = 58, 57
local ICON_CX, ICON_CY = 706 + 58 / 2, 14 - 38 / 2   -- the quad's centre in the row object
local SERIES_ROW_Y = ICON_CY               -- the row's own series icons' centre line
local ROLE_SCALE = 1.25
local MAX_STRIP = 6

local function text(id)
  local s = VRFW.host.command(CMD_TEXT_GET, id)
  if type(s) == "string" then return s end
  return ""
end

local function note(msg)
  log.once(msg, msg)
end

local M = VRFW.host.menu_command

local function tint(layer, inst, mesh, c)
  VRFW.host.menu_command(PRIM_COLOR, layer, inst, mesh, c[1], c[2], c[3])
end

local function split_ids(s)
  local out = {}
  if type(s) ~= "string" then return out end
  for v in s:gmatch("[^,]+") do
    local n = tonumber(v)
    if n and n ~= 0 then out[#out + 1] = n end
  end
  return out
end

S.ex = S.ex or {}
local function ex(layer)
  local e = S.ex[layer]
  if not e then
    e = { opened = {}, want = {}, built = {}, shown = {} }
    S.ex[layer] = e
  end
  return e
end

local function has_layer(layer)
  local r = VRFW.host.menu_command(C.IS_EXIST_LAYER, layer)
  return r == true
end

-- an extra instance on or off (a call only when it changes)
local function set_shown(layer, k, on)
  local e = ex(layer)
  if e.shown[k] ~= on then
    M(C.LAYER_VISIBLE, layer, k, on)
    e.shown[k] = on
  end
end

-- the row's frame on screen: origin and scale (two of its meshes' global positions)
local function row_frame(inst)
  local ax, ay = M(C.GPOS, ROW, inst, ANCHOR_A)
  local bx, by = M(C.GPOS, ROW, inst, ANCHOR_B)
  if type(ax) ~= "number" or type(ay) ~= "number" or type(bx) ~= "number" or type(by) ~= "number" then return nil end
  local s = (bx - ax) / (ANCHOR_BX - ANCHOR_AX)
  if s <= 0.05 or s > 20 then s = 1 end
  return ax - ANCHOR_AX * s, ay - ANCHOR_AY * s, s
end

-- a game row's part off (a plate, never the face: see the header).
local function hide_part(inst, mesh)
  M(SET_MESH_VISIBLE, ROW, mesh, false, inst)
end

local function dress(layer, k)
  local w = ex(layer).want[k]
  if not w then return end
  if layer == L_ICON then
    for _, m in ipairs({ CHECK_BOX, CHECK, LINE, FACE_BASE, FACE, SERIES[2], SERIES[3] }) do M(SET_MESH_VISIBLE, layer, m, false, k) end
    M(C.TEXT_VISIBLE, layer, TEXT_NAME, false, k)
    tint(layer, k, ICON_MESH, WHITE)
    M(PRIM_ALPHA, layer, k, ICON_MESH, 1)
    M(SET_MESH_VISIBLE, layer, ICON_MESH, w.done == true, k)
  elseif layer == L_ROW then
    M(SET_MESH_VISIBLE, layer, LINE, true, k)
    M(SET_MESH_VISIBLE, layer, CHECK_BOX, w.box ~= false, k)
    M(SET_MESH_VISIBLE, layer, CHECK, w.check == true, k)
    for _, m in ipairs(SERIES) do M(SET_MESH_VISIBLE, layer, m, false, k) end
    -- no face: the face mesh hidden and clear (the row object's template face never shows)
    M(SET_MESH_VISIBLE, layer, FACE, w.id ~= 0, k)
    M(SET_MESH_VISIBLE, layer, FACE_BASE, w.plate ~= false, k)
    tint(layer, k, FACE, w.face_tint or WHITE)
    M(PRIM_ALPHA, layer, k, FACE, w.id ~= 0 and (w.face_alpha or 1) or 0)
    tint(layer, k, FACE_BASE, type(w.plate) == "table" and w.plate or WHITE)
    M(PRIM_ALPHA, layer, k, FACE_BASE, w.plate_alpha or 1)
    tint(layer, k, LINE, w.line or WHITE)
    M(C.TEXT_VISIBLE, layer, TEXT_NAME, true, k)
    M(SET_TEXT, layer, TEXT_NAME, w.text or "", k)
  elseif layer == L_CREST then
    -- order matters: a node's visibility is set on every mesh under it, so the parent first, the hides after
    M(C.NODE_VISIBLE, layer, TILE_NODE, true, k)
    for _, n in ipairs(TILE_HIDE_NODES) do M(C.NODE_VISIBLE, layer, n, false, k) end
    for _, m in ipairs(TILE_HIDE) do M(SET_MESH_VISIBLE, layer, m, false, k) end
    M(SET_MESH_VISIBLE, layer, TILE_MESH, w.asked == true, k)
  else
    tint(layer, k, FACE, w.grey and GHOST or WHITE)
    M(PRIM_ALPHA, layer, k, FACE, w.grey and GHOST_ALPHA or 1)
    for _, m in ipairs({ CHECK_BOX, CHECK, LINE, SERIES[1], SERIES[2], SERIES[3] }) do M(SET_MESH_VISIBLE, layer, m, false, k) end
    M(C.TEXT_VISIBLE, layer, TEXT_NAME, false, k)
    M(SET_MESH_VISIBLE, layer, FACE, true, k)
    M(SET_MESH_VISIBLE, layer, FACE_BASE, w.plate ~= false, k)
    if w.plate ~= false then tint(layer, k, FACE_BASE, w.plate or ORANGE) end
  end
end

-- the picture of instance k asked for once the instance is built (then it may show: its picture appears when loaded)
local function ask(layer, k)
  local e = ex(layer)
  local w = e.want[k]
  if not w or not e.built[k] or w.asked then return end
  if layer == L_ICON then
    w.done = M(SPRITE, layer, w.sheet, w.sprite, ICON_SLOT, 0, k) == true
    w.asked = w.done
    w.ready = true
    return
  end
  w.asked = true
  w.ready = true
  if layer == L_CREST then
    M(C.EMBLEM, layer, k, TILE_MESH, TILE_SLOT, w.id, 0)
  elseif w.id ~= 0 then
    VRFW.face_icon.request(layer, k, w.id, FACE, FACE_SLOT)
  end
end

-- every used extra instance that is built: its picture asked (once), its look sent and shown
local function reveal()
  for _, layer in ipairs({ L_ROW, L_CREST, L_FACE, L_ICON }) do
    local e = ex(layer)
    for k, w in pairs(e.want) do
      if w.used and e.built[k] then
        if not w.asked then ask(layer, k) end
        if e.shown[k] ~= true then
          dress(layer, k)
          set_shown(layer, k, true)
        end
      end
    end
  end
end

-- an extra instance opened once (hidden until its content is ready)
local function open_instance(layer, k)
  local e = ex(layer)
  if not e.opened[k] then
    M(C.OPEN_LAYER, layer, k)
    e.opened[k] = true
    e.shown[k] = nil
    set_shown(layer, k, false)
  end
end

local function show(layer, k, id, row, lx, px, plate, grey)
  local e = ex(layer)
  if not id then
    if e.opened[k] then
      e.shown[k] = nil                     -- sent even when the kept state says hidden
      set_shown(layer, k, false)
    end
    e.want[k] = nil
    return
  end
  open_instance(layer, k)
  local w = e.want[k]
  if not w or w.id ~= id then
    set_shown(layer, k, false)
    w = { id = id }
    e.want[k] = w
  end
  w.used = true
  w.row, w.lx, w.px, w.plate, w.grey = row, lx, px, plate, grey
  w.scale = nil
  if not w.asked then ask(layer, k) end
  if w.ready then dress(layer, k) end
  S.extras = true
end

local function show_icon(k, sheet, sprite, row, lx, ly, scale)
  local e = ex(L_ICON)
  if not sheet then
    if e.opened[k] then
      e.shown[k] = nil                     -- sent even when the kept state says hidden
      set_shown(L_ICON, k, false)
    end
    e.want[k] = nil
    return
  end
  open_instance(L_ICON, k)
  local w = e.want[k]
  if not w or w.sheet ~= sheet or w.sprite ~= sprite then
    set_shown(L_ICON, k, false)
    w = { sheet = sheet, sprite = sprite }
    e.want[k] = w
  end
  w.used = true
  w.row, w.lx, w.ly, w.k = row, lx, ly, scale
  if not w.asked then ask(L_ICON, k) end
  if w.ready then dress(L_ICON, k) end
  S.extras = true
end

local function open_clone(k, id, row, look)
  local e = ex(L_ROW)
  open_instance(L_ROW, k)
  id = id or 0
  local w = e.want[k]
  if not w or w.id ~= id then
    set_shown(L_ROW, k, false)
    w = { id = id }
    e.want[k] = w
  end
  w.used = true
  w.row = row
  w.plate, w.line, w.box, w.check = nil, nil, nil, nil
  w.face_tint, w.face_alpha, w.plate_alpha = nil, nil, nil
  for key, v in pairs(look or {}) do w[key] = v end
  if w.ready then dress(L_ROW, k) else ask(L_ROW, k) end
  S.extras = true
  return w
end

-- a series' / role's icon: sheet, sprite (nil when the framework has none)
local function icon_of(cmd, v)
  local has, sheet, sprite = VRFW.host.command(cmd, v)
  if has == true and type(sheet) == "number" and type(sprite) == "number" then return sheet, sprite end
  return nil
end

local function series_strip(ii, inst, list, right)
  local n = math.min(#list, MAX_STRIP)
  for j = 1, n do
    local sheet, sprite = icon_of(CMD_SERIES_ICON, list[#list - n + j])
    if sheet and ii < N_ICON then
      show_icon(ii, sheet, sprite, inst, right - ICON_W / 2 - (n - j) * ICON_PITCH, SERIES_ROW_Y, 1)
      ii = ii + 1
    end
  end
  return ii
end

local EXTRA_LAYERS = { L_ROW, L_CREST, L_FACE, L_ICON }

S.logged_places = S.logged_places or {}
local function layout_frames()
  local L = S.layout
  if not L then return {} end
  local f = {}
  local s = L.scale or 1
  for i, joint in ipairs(ROW_JOINTS[L.rows] or {}) do
    local x, y = M(C.GPOS, L.detail, 0, joint)
    if type(x) == "number" and type(y) == "number" and (x ~= 0 or y ~= 0) then
      f[i - 1] = { x, y, s }
    else
      local ox, oy, rs = row_frame(i - 1)
      if ox and L.drawn and L.drawn[i - 1] then f[i - 1] = { ox, oy, rs } end
    end
  end
  if L.grid then
    for i = 1, GRID_MAX do
      local b = f[math.floor((i - 1) / 2)]
      if b then f[100 + i] = { b[1] + ((i - 1) % 2) * ROW_WIDTH * GRID_COLS * b[3], b[2], b[3] } end
    end
  end
  -- once per detail layer and layout: the row places found (loader.log)
  local key = string.format("%d:%d", L.detail, L.rows)
  if not S.logged_places[key] and f[0] then
    S.logged_places[key] = true
    local parts = {}
    for i = 0, L.rows - 1 do
      parts[#parts + 1] = f[i] and string.format("%.1f,%.1f", f[i][1], f[i][2]) or "-"
    end
    log("layer", L.detail, "layout", L.rows, "row places", table.concat(parts, " "), "scale", s)
  end
  return f
end

local function place_all()
  local frames = layout_frames()
  for _, layer in ipairs(EXTRA_LAYERS) do
    local e = ex(layer)
    for k, w in pairs(e.want) do
      if w.used then
        local f = frames[w.row]
        if f then
          local ox, oy, s = f[1], f[2], f[3]
          if layer == L_ROW then
            -- a row clone: the row object itself at its row's (or grid cell's) origin and scale
            M(C.LOCAL_SCALE, layer, s, s, 1, k)
            M(C.LOCAL_POS, layer, ox, oy, 0, k)
          elseif layer == L_ICON then
            -- the instance's origin so that its series quad is centred on (lx, ly)
            local sc = w.k * s
            M(C.LOCAL_SCALE, layer, sc, sc, 1, k)
            M(C.LOCAL_POS, layer, ox + w.lx * s - ICON_CX * sc, oy + w.ly * s - ICON_CY * sc, 0, k)
          elseif layer == L_CREST then
            local sc = w.px / EMBLEM_PX * s
            M(C.LOCAL_SCALE, layer, sc, sc, 1, k)
            M(C.LOCAL_POS, layer, ox + w.lx * s, oy, 0, k)      -- the tile's origin = its centre
          else
            local sc = (w.scale or FACE_SCALE) * s
            -- the row object's origin so that its plate is centred on lx, y 0
            M(C.LOCAL_SCALE, layer, sc, sc, 1, k)
            M(C.LOCAL_POS, layer, ox + w.lx * s - (FACE_X0 + FACE_X1) / 2 * sc, oy, 0, k)
          end
        else
          set_shown(layer, k, false)
        end
      end
    end
  end
end

local function hide_extras()
  for _, layer in ipairs(EXTRA_LAYERS) do
    local e = ex(layer)
    for k in pairs(e.opened) do set_shown(layer, k, false) end
    for _, w in pairs(e.want) do w.used = false end
  end
  S.extras = nil
  S.layout = nil
end

-- a game row back to the game's look (it may have been a nexus / empty row of another synergy's panel)
local function reset_row(inst)
  VRFW.host.menu_command(SET_MESH_VISIBLE, ROW, FACE_BASE, true, inst)
  VRFW.host.menu_command(SET_MESH_VISIBLE, ROW, CHECK_BOX, true, inst)
  VRFW.host.menu_command(SET_MESH_VISIBLE, ROW, LINE, true, inst)
  M(C.TEXT_VISIBLE, ROW, TEXT_NAME, true, inst)
  if S.sprite_rows and S.sprite_rows[inst] then
    M(C.RESET_FACE, ROW, inst, FACE_SLOT)      -- an older version's nexus icon off the face mesh
    S.sprite_rows[inst] = nil
  end
  tint(ROW, inst, FACE, WHITE)
  tint(ROW, inst, FACE_BASE, WHITE)
  tint(ROW, inst, LINE, WHITE)
  VRFW.host.menu_command(PRIM_ALPHA, ROW, inst, FACE, 1)
  VRFW.host.menu_command(PRIM_ALPHA, ROW, inst, FACE_BASE, 1)
end

-- the rows the game drew for this panel (row instances it shows; it hides the others itself), back to the game's look
local function reset_all(drawn)
  for _, inst in ipairs(drawn) do reset_row(inst) end
  for _, layer in ipairs(EXTRA_LAYERS) do
    for _, w in pairs(ex(layer).want) do w.used = false end
  end
end

-- no check box on the drawn rows (rules.checks == false)
local function no_checks(drawn)
  for _, inst in ipairs(drawn) do
    M(SET_MESH_VISIBLE, ROW, CHECK_BOX, false, inst)
    M(SET_MESH_VISIBLE, ROW, CHECK, false, inst)
  end
end

local function locators_3_rows(detail, locators)
  if type(locators) ~= "table" then
    note("no row locators from the framework: the game's rows keep its 2-row places")
    return
  end
  for _, id in ipairs(split_ids(locators.off)) do M(LOCATOR_TRACE, detail, 0, id, false) end
  for _, id in ipairs(split_ids(locators.on)) do M(LOCATOR_TRACE, detail, 0, id, true) end
end

function S.apply_panel(item, rules)
  rules = type(rules) == "table" and rules or {}
  local p = nil
  if type(item) == "number" and item ~= 0 then
    local code = VRFW.host.command(CMD_LANGUAGE)
    local v = VRFW.host.command(S.CMD_PANEL, item, code or -1)
    if type(v) == "table" and type(v.rows) == "table" then p = v end
  end
  local drawn, is_drawn = {}, {}
  local known = p ~= nil and type(p.drawn) == "string" and #p.drawn >= N_ROWS
  for i = 0, N_ROWS - 1 do
    local on
    if known then on = p.drawn:sub(i + 1, i + 1) == "1" else on = M(IS_VISIBLE, ROW, i) == true end
    if on then
      drawn[#drawn + 1] = i
      is_drawn[i] = true
    end
  end
  reset_all(drawn)
  if rules.checks == false then no_checks(drawn) end
  if rules.hide_undrawn and known then
    for i = 0, N_ROWS - 1 do
      if not is_drawn[i] then M(C.LAYER_VISIBLE, ROW, i, false) end
    end
    note("rows the framework did not draw are hidden (rules.hide_undrawn)")
  end
  if not p then
    hide_extras()                          -- no item, or a game synergy: its rows are the game's
    return
  end
  local has_team = p.team == 1 or p.team == true
  local crest_ok, face_ok, icon_ok = has_layer(L_CREST), has_layer(L_FACE), has_layer(L_ICON)
  local clone_ok = has_layer(L_ROW)
  local ci, fi, ii = 0, 0, 0
  local grid = #p.rows >= GRID_MIN and clone_ok
  local n_rows = grid and math.ceil(math.min(#p.rows, GRID_MAX) / 2) or math.min(#p.rows, N_ROWS)
  local layout = n_rows == 3 and 3 or 2
  local detail = tonumber(rules.detail) or DETAIL
  if layout == 3 and #drawn < 3 then locators_3_rows(detail, p.locators) end
  for _, inst in ipairs(drawn) do
    local _, _, sc = row_frame(inst)
    if sc then S.row_scale = sc break end
  end
  S.layout = { detail = detail, rows = layout, grid = grid, scale = S.row_scale or 1, drawn = is_drawn }
  local ROWR = grid and (ROW_WIDTH * GRID_COLS - 24) or ROW_RIGHT      -- the right edge of a row / grid cell, row units
  local ri = 0                             -- the next row clone
  local function order_items(items)
    for i, it in ipairs(items) do it.seq = i end
    table.sort(items, function(a, b)
      local ac, bc = a.crest ~= nil, b.crest ~= nil
      if ac ~= bc then return bc end
      local ar, br = a.rank or math.huge, b.rank or math.huge
      if ar ~= br then return ar < br end
      return a.seq < b.seq
    end)
    return items
  end
  local function candidates(row)
    local items, have = {}, {}
    for v in (type(row.have) == "string" and row.have or ""):gmatch("[^,]+") do have[#have + 1] = (v == "1") end
    local face_rank, crest_rank = split_ids(row.face_rank), split_ids(row.crest_rank)
    if face_ok then
      for j, id in ipairs(split_ids(row.faces)) do items[#items + 1] = { face = id, grey = has_team and have[j] ~= true, rank = face_rank[j] } end
    end
    if crest_ok then
      for j, id in ipairs(split_ids(row.crests)) do items[#items + 1] = { crest = id, rank = crest_rank[j] } end
    end
    return order_items(items)
  end
  local function right_strip(fr, items, left, right)
    right = right or ROWR
    local need = 0
    for _, it in ipairs(items) do need = need + (it.crest and CREST_STEP or FACE_STEP) end
    if need == 0 then return end
    local f = math.min(1, (right - left) / need)
    local x = right
    for j = #items, 1, -1 do
      local it = items[j]
      local w = (it.crest and CREST_STEP or FACE_STEP) * f
      local size = (it.crest and CREST_PX or (FACE_X1 - FACE_X0) * FACE_SCALE) * f
      it.cx = x - size / 2
      x = x - w
    end
    for _, it in ipairs(items) do
      if it.crest then
        if ci < N_CREST then
          show(L_CREST, ci, it.crest, fr, it.cx, CREST_PX * f)
          ci = ci + 1
        end
      elseif fi < N_FACE then
        show(L_FACE, fi, it.face, fr, it.cx, 0, WHITE, it.grey)
        ex(L_FACE).want[fi].scale = FACE_SCALE * f
        fi = fi + 1
      end
    end
  end
  local LEFT_BARE = FACE_X1 + 30
  local LEFT_TEXT = 440                    -- a row with a name: the strip starts right of it
  local function strip(fr, items, left)
    if not grid then
      right_strip(fr, items, left)
      return
    end
    local need = 0
    for _, it in ipairs(items) do need = need + (it.crest and CREST_STEP or FACE_STEP) end
    right_strip(fr, items, left, left + math.min(need, ROWR - left))
  end
  for r, row in ipairs(p.rows) do
    if (not grid and r > N_ROWS) or r > GRID_MAX then break end
    -- the game's row of slot r (a grid: the left column's slots 1, 3, 5 are the game's rows 0, 1, 2), else a clone
    local game_row = not grid and (r - 1) or (r % 2 == 1 and math.floor((r - 1) / 2)) or nil
    local inst = game_row or (r - 1)
    do
      local name = type(row.name) == "string" and row.name or ""
      local s = name
      local big = crest_ok and tonumber(row.crest) or 0
      local role = type(row.role) == "string" and row.role or ""
      local faces = type(row.faces) == "string" and row.faces or ""
      -- which look the row takes (the branches below)
      local branch
      if big ~= 0 and row.kind == KIND_EMPTY then
        branch = "members"
      elseif row.kind == KIND_EMPTY and role == "" then
        branch = "pool"
      elseif row.kind == KIND_EMPTY then
        branch = "staff"
      elseif row.kind == KIND_NEXUS or row.kind == KIND_NEXUS_MISSING then
        branch = "nexus"
      else
        branch = "filled"
      end
      local faceless = branch == "members" or branch == "pool" or branch == "staff"
      -- a player's row the game did not draw (it hid that instance) is not touched
      if game_row and not faceless and not is_drawn[game_row] then goto next_row end
      -- the row drawn on: the game's row, or a row clone (cw) at the row's place (a grid's right column: its cell)
      local fr, cw, ck = inst, nil, nil
      if not game_row or faceless then
        if ri >= N_CLONES then goto next_row end
        if not game_row then fr = 100 + r end
        ck = ri
        cw = open_clone(ck, faceless and 0 or (tonumber(row.base) or 0), fr)
        ri = ri + 1
      end
      -- the face square's plate, on the clone (kept in its look) or on the game's row
      local function plate(c, a)
        if cw then
          cw.plate, cw.plate_alpha = c, a
        elseif c == false then
          hide_part(inst, FACE_BASE)
        else
          tint(ROW, inst, FACE_BASE, c)
          VRFW.host.menu_command(PRIM_ALPHA, ROW, inst, FACE_BASE, a or 1)
        end
      end
      local series_hidden = false
      local function series_off()
        series_hidden = true
        if not cw then
          for _, m in ipairs(SERIES) do VRFW.host.menu_command(SET_MESH_VISIBLE, ROW, m, false, inst) end
        end
      end
      if branch == "members" then
        if ci < N_CREST then
          show(L_CREST, ci, big, fr, (FACE_X0 + FACE_X1) / 2, SQUARE_CREST_PX)
          ci = ci + 1
        end
        series_off()
        s = type(row.team_name) == "string" and row.team_name or ""
        local items = {}
        for _, id in ipairs(face_ok and split_ids(faces) or {}) do items[#items + 1] = { face = id } end
        strip(fr, items, LEFT_TEXT)
      elseif branch == "pool" then
        series_off()
        local items = candidates(row)
        if #items > 0 then
          s = ""
          strip(fr, items, LEFT_BARE)
        else
          local tn = type(row.team_name) == "string" and row.team_name or ""
          s = (string.gsub(text(row.hint), "{team}", function() return tn end))
        end
      elseif branch == "staff" then
        series_off()
        local rsheet, rsprite = nil, nil
        if role ~= "" and icon_ok then rsheet, rsprite = icon_of(CMD_ROLE_ICON, role) end
        if rsheet then
          if ii < N_ICON then
            show_icon(ii, rsheet, rsprite, fr, (FACE_X0 + FACE_X1) / 2, 0, ROLE_SCALE)
            ii = ii + 1
          end
          ii = series_strip(ii, fr, split_ids(row.series), ROWR)
        end
        local label = TXT_ROLE[role] and text(TXT_ROLE[role]) or ""
        if label == "" then
          local tn = type(row.team_name) == "string" and row.team_name or ""
          label = (string.gsub(text(row.hint), "{team}", function() return tn end))
        end
        s = label
      elseif branch == "nexus" then
        if cw then
          cw.line = ORANGE
        else
          tint(ROW, inst, LINE, ORANGE)
        end
        plate(ORANGE)
        local shown = tonumber(row.base) or 0
        local items = {}
        if face_ok then
          for _, id in ipairs(split_ids(faces)) do
            if id ~= shown then items[#items + 1] = { face = id } end
          end
        end
        if #items > 0 then
          series_off()
          strip(fr, items, LEFT_TEXT)
        end
        if row.kind == KIND_NEXUS_MISSING and has_team then
          if cw then
            cw.face_tint, cw.face_alpha = GHOST, GHOST_ALPHA
          else
            tint(ROW, inst, FACE, GHOST)
            VRFW.host.menu_command(PRIM_ALPHA, ROW, inst, FACE, GHOST_ALPHA)
          end
          if #items == 0 and not face_ok and not (row.single == 1 or row.single == true) then
            s = s .. "  (" .. text(TXT_MISSING) .. ")"
          end
        end
      end
      if cw then
        -- a clone: its text, check box and check in its look (sent when it is built and when it shows)
        cw.text = s or ""
        if rules.checks == false then
          cw.box, cw.check = false, false
        elseif branch ~= "members" then
          cw.check = row.kind == KIND_FILLED or (row.kind == KIND_NEXUS and has_team)
        end
        -- a clone of a player's row: that player's series icons at the row's end, as the game's row draws them
        if not series_hidden and icon_ok and type(row.series) == "string" and row.series ~= "" then
          ii = series_strip(ii, fr, split_ids(row.series), ROWR)
        end
        if cw.ready then dress(L_ROW, ck) end
      else
        if grid and not series_hidden then
          -- the left column of a grid: the game's series icons sit at the full row's end, under the right cell
          series_off()
          if icon_ok and type(row.series) == "string" and row.series ~= "" then
            ii = series_strip(ii, fr, split_ids(row.series), ROWR)
          end
        end
        VRFW.host.menu_command(SET_TEXT, ROW, TEXT_NAME, s or "", inst)
      end
    end
    ::next_row::
  end
  -- the instances this panel does not use
  for k = ci, N_CREST - 1 do show(L_CREST, k, nil) end
  for k = fi, N_FACE - 1 do show(L_FACE, k, nil) end
  for k = ii, N_ICON - 1 do show_icon(k, nil) end
  for k = ri, N_CLONES - 1 do
    if ex(L_ROW).opened[k] then show(L_ROW, k, nil) end
  end
  if S.extras then
    place_all()
    reveal()
  end
end

function S.built(layer, inst)
  if (layer == L_CREST or layer == L_FACE or layer == L_ICON or layer == L_ROW) and type(inst) == "number" then
    local e = ex(layer)
    e.built[inst] = true
    note("extra instances built by OnOpenLayer")
    local w = e.want[inst]
    if w and w.used then
      ask(layer, inst)
      place_all()
      dress(layer, inst)
      set_shown(layer, inst, true)
    end
  end
end

function S.hide_extras()
  hide_extras()
end

-- the rows' layer and check parts, for the menus' own files
S.ROW, S.CHECK, S.CHECK_BOX = ROW, CHECK, CHECK_BOX
