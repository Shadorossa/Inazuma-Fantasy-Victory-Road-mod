-- VRFW › team synergies declared by mods: the rows of a synergy detail panel (rows
-- team16_03_synergy_chara_condition_list), shared by every menu that shows one: the synergy list
-- (equip_synergy_menu_list/300_synergy.lua), the shop (shop_menu_buy/310_synergy_shop.lua) and the team dock's Formación
-- (team_dock_formation_menu/320_synergy_dock.lua). This file defines the
-- functions only (VRFW_Synergy.ApplyPanel / Built / HideExtras); each menu's file calls them from its own events. The engine
-- draws the rows of a player itself (the framework's hook on its row builder: the nexus, the members that fill the
-- slots); a row without a player's face (an open slot, a team group, a staff slot) is written as 0 there, so the game
-- draws nothing and asks no face for it, and VRFW_Synergy.ApplyPanel draws it with a row clone. For a declared synergy
-- only (the same rules in every menu; texts in the normal colour, the check boxes as the game draws them unless
-- rules.checks = false):
--   * a named player's row (a filler, the nexus): his face, his name, the check box as the game draws them; the nexus
--     row's line orange, the other allowed persons of a several-person nexus as minifaces at the row's end; a missing
--     nexus (team known): his face grey and translucent;
--   * an open slot of a pool: the small check box and the empty grey square (no face, no text); every row of the pool
--     shows all its candidates (its named players' minifaces, then its teams' crests, layers vrfw_syn_face /
--     vrfw_syn_crest) on one line at its right end; a pool with nothing to show: the slot's hint;
--   * an open team group (`slot_members`): the team's crest inside the grey square, the team's name and its players'
--     minifaces at the row's end;
--   * a filled slot (a team group's too): the game's row as drawn (the filler's face, name, check box and series
--     icons), nothing else;
--   * a staff slot (a pool with a role): the role's icon in the face square, the required series' icons
--     right-aligned (CMND_VRFW_ROLE_ICON / CMND_VRFW_SERIES_ICON drawn with the sprite command), the role's short name;
--   * a synergy with 4 to 6 rows: a 2-column grid of 2 or 3 lines; the framework writes its odd rows (1st, 3rd, 5th) to the
--     game's row builder (the left column, the game's own rows) and the even rows are row clones (layer vrfw_syn_row) beside them;
--     each cell shows its own slot's candidates right after its square, inside the cell.
-- No per-frame code: the extra pieces (row clones, crests, minifaces, icons) are set, placed and shown when the panel
-- is filled (the menu's selection change) and, for an instance built later, in its own OnOpenLayer (its look sent, its
-- picture asked, placed, shown). The game's rows are never hidden as whole instances (the engine then redraws the panel
-- every frame). A row clone (vrfw_syn_row: its own grey plate, no face asked, its face mesh hidden, its text in the
-- normal colour) is the first extra layer, so crests, minifaces and icons draw over it.
-- Row places: the panel's own attach joints, where the game hangs its rows (team16_02 / team16_05 layouts:
-- _atc_list02_01 / 02 for 1 or 2 rows, _atc_list03_01 .. 03 for 3 rows), read with CMND_GET_MESH_GLOBAL_POSITION on
-- the detail layer (it takes any joint of the layer's skeleton). The layout is the panel's declared row count, not the
-- count the game drew: a 3-row panel with rows written as 0 gets the game's 2-row attach locators from the row builder,
-- so its 3-row locators are put back (CMND_SET_LAYER_ATTACH_LOCATOR_TRACE, the builder's own locator ids from the
-- framework) and the game's rows hang on the 3-row places again.
-- Only the rows the game drew this time are put back to the game's look (tints, alpha, check box) and dressed: a row
-- the game hid is never touched (showing one of its meshes or texts again showed the last panel's names, lines and faces
-- under the new rows). Extras the new panel does not use are hidden (always sent, not only when the kept state says
-- shown).
-- One fill for every menu that shows the panel: S.ApplyPanel(item, rules); rules.checks = false: no check box on any
-- row (the shop: no team is checked); rules.detail: the detail layer (default the synergy screen's team16_02);
-- rules.hide_undrawn = true: every row instance the framework wrote as 0 is hidden (the shop's builder keeps it on
-- screen with its last content).
-- An extra instance's look (which tile / row meshes it hides) is set again once it is built (OnOpenLayer).
-- The crest tile's node is shown FIRST, then its plates hidden: CMND_SET_NODE_VISIBLE sets the flag on every mesh under
-- the node (the retail SetupEmblemIcon hides _pos_enjoy_list01, the parent of the emblem quad, then shows the quad and
-- the outline one by one). Showing _pos_enjoy_list01 after the hides re-showed every plate under it: the red / pink
-- team-colour hexagons and the cyan cursor outline around each crest (twice).
-- No engine call at load time; every call guarded.

VRFW_Synergy = VRFW_Synergy or {}
local S = VRFW_Synergy
if S.ApplyPanel ~= nil then return end     -- defined once per menu VM
S.CMD_PANEL = S.CMD_PANEL or VRFW_Cmd.VRFW_SYNERGY_PANEL
local CMD_TEXT_GET = VRFW_Cmd.TEXT_GET
local CMD_LANGUAGE = VRFW_Cmd.GET_LANGUAGE_CODE
local CMD_ITEM_OF_INV = 2662166687         -- (inventory handle, 0) -> the item id (the retail script's own call)
local SET_TEXT = VRFW_Cmd.SET_MENU_TEXT_STRING                -- (layer, node, text, instance)
local SET_MESH_VISIBLE = VRFW_Cmd.SET_MESH_VISIBLE        -- (layer, mesh, visible, instance)
local PRIM_COLOR = VRFW_Cmd.SET_PRIM_COLOR               -- (layer, instance, mesh, r, g, b) (multiplier 0..1)
local PRIM_ALPHA = VRFW_Cmd.SET_PRIM_ALPHA              -- (layer, instance, mesh, alpha)
local C = {
  IS_EXIST_LAYER = VRFW_Cmd.IS_EXIST_LAYER,              -- (layer) -> true when the menu has it
  OPEN_LAYER = VRFW_Cmd.OPEN_LAYER,                  -- (layer, instance)
  LAYER_VISIBLE = VRFW_Cmd.SET_LAYER_VISIBLE,               -- (layer, instance, visible)
  LOCAL_POS = VRFW_Cmd.SET_LAYER_LOCAL_POS,                  -- (layer, x, y, z, instance): screen px from the top left, y up
  LOCAL_SCALE = VRFW_Cmd.SET_LAYER_LOCAL_SCALE,                -- (layer, sx, sy, sz, instance)
  NODE_VISIBLE = 2158717427,               -- (layer, node, visible, instance)
  TEXT_VISIBLE = VRFW_Cmd.SET_MENU_TEXT_VISIBLE,               -- (layer, text node, visible, instance)
  GPOS = VRFW_Cmd.GET_MESH_GLOBAL_POSITION,                        -- CMND_GET_MESH_GLOBAL_POSITION (layer, instance, mesh) -> x, y, z
  EMBLEM = 3190452549,                     -- (layer, instance, mesh, texture slot, item_emblem id, 0)
  RESET_FACE = 4176779611,                 -- (layer, instance, texture slot)
}

local ROW = 4041512772                     -- team16_03_synergy_chara_condition_list
local N_ROWS = 3                           -- the panel's largest layout
local DETAIL = 1473585342                  -- team16_02_synergy_item_detail (the synergy screen's detail; rules.detail else)
-- the detail layouts' attach joints the game's rows hang on (the same names in team16_02 and team16_05), per layout
local ROW_JOINTS = {
  [2] = { 4288612777, 1721128979 },               -- _atc_list02_01 / _atc_list02_02 (1 or 2 rows drawn)
  [3] = { 1193504460, 3727310710, 2838302688 },   -- _atc_list03_01 .. _atc_list03_03 (3 rows drawn)
}
local LOCATOR_TRACE = VRFW_Cmd.SET_LAYER_ATTACH_LOCATOR_TRACE   -- (layer, instance, locator, on)
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
local CMD_SERIES_ICON = VRFW_Cmd.VRFW_SERIES_ICON          -- (series) -> ok, sheet, sprite
local CMD_ROLE_ICON = VRFW_Cmd.VRFW_ROLE_ICON           -- (role) -> ok, sheet, sprite
local SPRITE = 558735651                   -- sprite command (layer, sheet, sprite, texture node, 0, instance) -> true once applied
local ORANGE = { 1.0, 0.55, 0.12 }         -- the nexus row's tint (the name: [CMODE03] = 247 107 0)
local GHOST = { 0.62, 0.62, 0.62 }         -- a missing nexus's face / an empty slot's plate: grey ...
local GHOST_ALPHA = 0.45                   -- ... and translucent
local WHITE = { 1, 1, 1 }
local KIND_NEXUS, KIND_NEXUS_MISSING, KIND_FILLED, KIND_EMPTY = 1, 2, 3, 4

-- the extra layers (content\menus\synergy_panel.toml) and the row geometry they are placed by (team16_03, row-local
-- units, y up: check box centred on the origin, the face plate 64 at x 31..95, the series icons x 592..764)
local L_CREST, N_CREST = 527765702, 36     -- vrfw_syn_crest (vrfw_emblem_tile): every row's full candidate crests
local L_FACE, N_FACE = 734603085, 72       -- vrfw_syn_face (team16_03 itself): every row's full candidate minifaces
local L_ICON, N_ICON = 1263105521, 24      -- vrfw_syn_icon (team16_03 itself): one series / role icon per instance
local L_ROW, N_CLONES = 3982581158, 6       -- vrfw_syn_row (team16_03 itself): a whole row over an open slot / a grid cell
local GRID_MIN, GRID_MAX = 4, 6            -- rows drawn as a 2-column grid (2 lines for 4, 3 lines for 5-6)
local GRID_COLS = 0.5                      -- a grid column's share of the row width (cells at the rows' own scale and places)
local ROW_WIDTH = 800                      -- a row's width in its own units (check box to the series icons' end)
local LOG_CMD = VRFW_Cmd.EVT_LOG                 -- CMND log (loader.log lines «lua log: …»)
local ROW_RIGHT = 764                      -- the right edge of the series icons: the extras end there
local ANCHOR_A, ANCHOR_AX, ANCHOR_AY = 4051829508, -16, 16   -- _icon_check_box01 at (-16, 16)
local ANCHOR_B, ANCHOR_BX, ANCHOR_BY = 3231997250, 706, 14   -- _icon_series_dmy01 at (706, 14)
local CREST_PX, CREST_STEP = 52, 56        -- crest size / pitch, row units: the series icons' size, 4 apart
local SQUARE_CREST_PX = 52                 -- a team group's crest inside the grey face square (the plate 64: x 31..95)
local EMBLEM_PX = 84                       -- the tile's emblem quad
local TILE_MESH, TILE_SLOT = 1926542734, 618311715   -- _enjoy_list_icon_dmy01 / enjoy_list_icon_dmy01
-- every plate / frame / cursor / check part of the retail tile (the emblem grid hides the same: 58_emblem_grid.lua): only
-- the emblem quad stays, so a crest is the plain picture. Before, only three were hidden: the team-colour hexagon
-- frames (p1 / p2 plates) and their add / ok quads showed as frames with white rectangles around the crest.
local TILE_HIDE = { 2668225226, 1751802610, 3159751709, 155260060, 688408036, 2291119251, 1323396684, 294053161,
                    2968134629, 100709232, 1763834249 }
-- the plates' nodes (under _pos_enjoy_list01: _p1 / _p2 hold the two team-colour hexagon sets) and the player tags
local TILE_HIDE_NODES = { 3808539401, 2047402675, 1061671357, 2790162439 }   -- _pos_enjoy_list01_p1 / _p2, _pos_1p01 / 02
local TILE_NODE = 3933090681               -- _pos_enjoy_list01 (parent of the plates, the outline and the emblem quad)
local FACE_SCALE, FACE_STEP = 0.6, 44      -- a candidate's plate (64) and face at 0.6, pitch in row units
local FACE_X0, FACE_X1 = 31, 95            -- the plate's x extent in the row object
local IS_VISIBLE = VRFW_Cmd.IS_LAYER_VISIBLE             -- (layer, instance) -> true when shown
-- an icon instance shows only its first series quad (_icon_series_dmy01: top left 706, 14, 58 x 38 in the row object;
-- the series quads' pitch 57) with the asked sprite on its texture node icon_series_dmy01
local ICON_MESH, ICON_SLOT = 3231997250, 201452450
local ICON_W, ICON_PITCH = 58, 57
local ICON_CX, ICON_CY = 706 + 58 / 2, 14 - 38 / 2   -- the quad's centre in the row object
local SERIES_ROW_Y = ICON_CY               -- the row's own series icons' centre line
local ROLE_SCALE = 1.25                    -- the role icon in the face square (plate 64 x 64 at x 31..95, centre y 0)
local MAX_STRIP = 6                        -- series icons of one row (room between the name and the row's end)

local function text(id)
  local ok, s = pcall(funcLuaCommand, CMD_TEXT_GET, id)
  if ok and type(s) == "string" then return s end
  return ""
end

S.noted = S.noted or {}
local function note(msg)
  if not S.noted[msg] then
    S.noted[msg] = true
    pcall(funcLuaCommand, LOG_CMD, "VRFW synergy rows: " .. msg)
  end
end

local function M(cmd, ...)
  local ok, a, b, c = pcall(funcLuaMenuCommand, cmd, ...)
  if ok then return a, b, c end
  return nil
end

local function tint(layer, inst, mesh, c)
  pcall(funcLuaMenuCommand, PRIM_COLOR, layer, inst, mesh, c[1], c[2], c[3])
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

-- ------------------------------------------------------------------------------------------------ the extra layers

-- per layer: opened instances, what each shows (want: the instance's content and look; used = in the panel drawn last),
-- built (OnOpenLayer seen), shown (the instance's visibility as last set)
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
  local ok, r = pcall(funcLuaMenuCommand, C.IS_EXIST_LAYER, layer)
  return ok and r == true
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

-- a game row's part off (a plate, never the face: see the header). The game's rows are never hidden as whole instances:
-- the engine draws the panel again when one of its row instances is hidden, every frame
local function hide_part(inst, mesh)
  M(SET_MESH_VISIBLE, ROW, mesh, false, inst)
end

-- instance k's look: on a crest only the emblem quad (every plate / frame / cursor / check of the tile hidden), on a
-- miniface only its plate (tinted) and face, on a row clone the look its row asks for (w.id face, w.plate, w.line,
-- w.box, w.check, w.text). Sent when the content is set, when the instance is built (lost before) and when it is shown
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
    -- a row clone: a face only when one was asked for (no request, no picture that loads and shows later)
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
    -- the sprite command answers false (and draws nothing) while the sheet or the instance's model is not ready: asked
    -- again at the next panel fill or OnOpenLayer
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
    VRFW_FaceIcon.Request(layer, k, w.id, FACE, FACE_SLOT)
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

-- instance k of `layer` shows icon `id` at row `row` (row-local centre lx, size px), or nothing (id nil); a miniface's
-- plate is tinted `plate` (default orange: a nexus's; false = no plate). The same icon again keeps its loaded picture
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

-- icon instance k shows sprite (sheet, sprite) centred on row `row`'s (lx, ly) at `scale` x the row's own series icon
-- (sheet nil: nothing)
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

-- row clone k (layer vrfw_syn_row: the row object itself), a cell of a 2-column grid (4-6 rows): placed by frame `row`
-- (the grid cell's 100 + k + 1), its face drawn for chara `id` (0: no face, nothing requested). Its look:
-- the fields of `look` (plate, line, box, check, face_tint, face_alpha, plate_alpha), its text set by set_row_text
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
  local ok, has, sheet, sprite = pcall(funcLuaCommand, cmd, v)
  if ok and has == true and type(sheet) == "number" and type(sprite) == "number" then return sheet, sprite end
  return nil
end

-- the series icons `list` (series numbers, at most MAX_STRIP: the last ones) in a row, the last one's right edge at row
-- x `right`; returns the next free icon instance
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

-- the panel's row places now (S.layout = { detail, rows = 2 / 3, grid, scale }): frames[i] = { x, y, scale } of row i
-- (0-based) from the layout's attach joints; a grid: frames[100 + cell] (the right column half a row width to
-- the right of the left one). A joint the layer does not answer: the game's row's own place when it drew that row
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
    pcall(funcLuaCommand, LOG_CMD, "VRFW synergy rows: layer", L.detail, "layout", L.rows, "row places", table.concat(parts, " "), "scale", s)
  end
  return f
end

-- every extra instance of the panel at its row's place (layout_frames: read again each time, the panel may have moved
-- since it was filled)
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

-- every extra instance off; what each one shows is kept (the same picture shows again at once when a later panel asks
-- for it)
local function hide_extras()
  for _, layer in ipairs(EXTRA_LAYERS) do
    local e = ex(layer)
    for k in pairs(e.opened) do set_shown(layer, k, false) end
    for _, w in pairs(e.want) do w.used = false end
  end
  S.extras = nil
  S.layout = nil
end

-- ------------------------------------------------------------------------------------------------ the rows

-- a game row back to the game's look (it may have been a nexus / empty row of another synergy's panel)
local function reset_row(inst)
  pcall(funcLuaMenuCommand, SET_MESH_VISIBLE, ROW, FACE_BASE, true, inst)
  pcall(funcLuaMenuCommand, SET_MESH_VISIBLE, ROW, CHECK_BOX, true, inst)
  pcall(funcLuaMenuCommand, SET_MESH_VISIBLE, ROW, LINE, true, inst)
  M(C.TEXT_VISIBLE, ROW, TEXT_NAME, true, inst)
  if S.sprite_rows and S.sprite_rows[inst] then
    M(C.RESET_FACE, ROW, inst, FACE_SLOT)      -- an older version's nexus icon off the face mesh
    S.sprite_rows[inst] = nil
  end
  -- the series icons are left to the game: its row draw (just before this patch runs) shows a character's series and
  -- hides the unused slots (a row is reused by characters of 1-3 series). Forcing all three on here showed the unused
  -- slot as a white quad left of the saga icons on member rows
  tint(ROW, inst, FACE, WHITE)
  tint(ROW, inst, FACE_BASE, WHITE)
  tint(ROW, inst, LINE, WHITE)
  pcall(funcLuaMenuCommand, PRIM_ALPHA, ROW, inst, FACE, 1)
  pcall(funcLuaMenuCommand, PRIM_ALPHA, ROW, inst, FACE_BASE, 1)
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

-- the 3-row attach locators of the detail layer back on (the row builder put its 2-row ones on: it drew fewer than 3
-- rows of a 3-row panel); locators = { off = "ids", on = "ids" } from the framework (the builder's own ids)
local function locators_3_rows(detail, locators)
  if type(locators) ~= "table" then
    note("no row locators from the framework: the game's rows keep its 2-row places")
    return
  end
  for _, id in ipairs(split_ids(locators.off)) do M(LOCATOR_TRACE, detail, 0, id, false) end
  for _, id in ipairs(split_ids(locators.on)) do M(LOCATOR_TRACE, detail, 0, id, true) end
end

-- the rows of the panel of `item` the game just drew: the rows it drew put back to its look, then, for a declared
-- synergy, dressed (nothing more for any other synergy). An open slot: the grey square over its face square. A synergy
-- of 4-6 rows: a 2-column grid, the game's 2-3 rows on the left, row clones beside them. The extra pieces are placed and shown at once (reveal),
-- an instance built later in its OnOpenLayer. rules: { checks = false (no check box on any row) }
function S.ApplyPanel(item, rules)
  rules = type(rules) == "table" and rules or {}
  local p = nil
  if type(item) == "number" and item ~= 0 then
    local okc, code = pcall(funcLuaCommand, CMD_LANGUAGE)
    local ok, v = pcall(funcLuaCommand, S.CMD_PANEL, item, okc and code or -1)
    if ok and type(v) == "table" and type(v.rows) == "table" then p = v end
  end
  -- the rows the game drew: for a declared synergy the framework's own list (p.drawn, "1" per drawn row instance);
  -- else the row instances shown. A row the game hid is never touched (a mesh shown again on it brings back its last
  -- name and face: in the shop, the active team's players of the game's own team draw)
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
  -- rules.hide_undrawn (the shop): a row instance the framework wrote as 0 this time is hidden, as the retail shop hides
  -- its rows itself (OnSetupLayer, SetHideSynergyDetail); its builder leaves such a row on screen with the last name,
  -- face, check and series icons drawn into it (the active team's members of the game's own draw)
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
  -- the panel's layout from its declared rows (the game picks its 3-row places only when it draws 3 rows): a 3-row
  -- panel the game drew fewer rows of gets its 3-row locators back. The row scale: a drawn row's, else the last one
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
  -- the candidates of an open slot: its pool's named players' minifaces, then its teams' crests (every row of the pool
  -- shows them all)
  -- the one candidate order: minifaces then crests, each by series (IE1 ... Victory Road, then the story order inside a
  -- series: the rank the rows hook computes from the game's tables); equal or unknown ranks keep their given order
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
  -- minifaces / crests in one line, right-aligned at the row's end and centred on the row's line (row `fr`), all of
  -- them: scaled down together when they do not fit between `left` and the row's end
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
  local LEFT_BARE = FACE_X1 + 30           -- a row with no text: the strip starts right of the face square
  local LEFT_TEXT = 440                    -- a row with a name: the strip starts right of it
  -- a strip: a 1-column panel right-aligns it at the row's end; a grid cell (one slot, 400 wide) shows its OWN
  -- slot's candidates right after its square (or its name), starting there and kept inside the cell
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
      -- a row without a player's face: the framework wrote it as 0, the game drew nothing there (its row instance is
      -- hidden and never touched)
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
          pcall(funcLuaMenuCommand, PRIM_ALPHA, ROW, inst, FACE_BASE, a or 1)
        end
      end
      local series_hidden = false
      local function series_off()
        series_hidden = true
        if not cw then
          for _, m in ipairs(SERIES) do pcall(funcLuaMenuCommand, SET_MESH_VISIBLE, ROW, m, false, inst) end
        end
      end
      if branch == "members" then
        -- an open team group (slot_members): the team's crest inside the grey square, the team's name, its players'
        -- minifaces at the row's end
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
        -- an open slot of a pool: the empty grey square, no text, all the pool's candidates on the right (a pool with
        -- none to show: the slot's hint)
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
        -- a staff slot: the role's icon in the face square (else the grey square), the required series' icons
        -- right-aligned, the role's short name
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
        -- the game's own row (the nexus's face, his name, the retail check box), only the line orange; the other
        -- allowed persons of a several-person nexus as minifaces at the row's end; missing (team known): his face grey
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
            pcall(funcLuaMenuCommand, PRIM_ALPHA, ROW, inst, FACE, GHOST_ALPHA)
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
        pcall(funcLuaMenuCommand, SET_TEXT, ROW, TEXT_NAME, s or "", inst)
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

-- an extra layer's instance is built (its OnOpenLayer): its look sent, its picture asked, placed and shown when this
-- panel uses it
function S.Built(layer, inst)
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

-- every extra piece (crests, minifaces, icons, row clones) off, the rows left as drawn: a page of the panel without the
-- condition rows (the shop's effects page) or a detail that is not a synergy. The next ApplyPanel shows them again
function S.HideExtras()
  hide_extras()
end

-- the rows' layer and check parts, for the menus' own files
S.ROW, S.CHECK, S.CHECK_BOX = ROW, CHECK, CHECK_BOX
