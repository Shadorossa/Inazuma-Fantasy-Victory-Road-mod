-- The Draft screen's pitch: the starters' places for a formation, the cards, the cursor and the screen's layers on and off.
-- Starters' places for any formation.
BattleBayDeluxe.draft_layout = {
  -- the dock's pitch (nodes of soccer11_02_formation_frame) and units, as SetupFormationIconPosition passes them
  DOCK_TOP = 278, DOCK_BOTTOM = -381, DOCK_TOP_HALF = 252, DOCK_BOTTOM_HALF = 346,
  DOCK_WIDTH_UNITS = 60, DOCK_DEPTH_UNITS = 94, DOCK_KEEPER_LIFT = 20,
  ATTACK_SET = 2, START_SET = 1, OFFSET_SET = 10,
  START_WIDTH_METRES = 30, START_DEPTH_METRES = 47, -- CMND_BATTLEBAYDELUXE_DRAFT_SLOT gives startPos x 1000
  SAME_SPOT_METRES = 1,
  -- Layout of this screen's pitch as drawn (screen pixels, y down).
  CX = 1150, TOP = 134, BOTTOM = 878, TOP_HALF = 307, BOTTOM_HALF = 417,
  -- Defaults used when config.toml [draft.pitch] gives no answer.
  CARD_SCALE = 1.05, CARD_WIDTH = 106.6, CARD_HEIGHT = 96, CARD_GAP = 8, EDGE_MARGIN = 6, SAME_ROW_DISTANCE = 30,
  SYMMETRY_TOLERANCE = 40,
  ROUNDS = 200,
  PITCH_CMD = @crc:CMND_BATTLEBAYDELUXE_DRAFT_PITCH@, asked = false,
  -- Box that the strip's mini pitch maps (screen pixels).
  BOX_L = 1150 - 417, BOX_R = 1150 + 417, BOX_T = 134, BOX_B = 878,
}

-- the tunables of config.toml [draft.pitch], once per menu
function BattleBayDeluxe.draft_pitch_look()
  local L, B = BattleBayDeluxe.draft_layout, BattleBayDeluxe.draft
  if L.asked then
    return
  end
  L.asked = true
  local answered, scale, width, height, gap, margin, sameRow, tolerance = VRFW.host.command(L.PITCH_CMD)
  if answered == true and type(tolerance) == "number" then
    L.CARD_SCALE, L.CARD_WIDTH, L.CARD_HEIGHT, L.CARD_GAP = scale, width, height, gap
    L.EDGE_MARGIN, L.SAME_ROW_DISTANCE, L.SYMMETRY_TOLERANCE = margin, sameRow, tolerance
    B.SLOT_SCALE = scale
    B.HALF_SLOT = {width * scale / 2, height * scale / 2}
  else
    BattleBayDeluxe.draft_log("pitch look: defaults (no CMND_BATTLEBAYDELUXE_DRAFT_PITCH answer)")
  end
end

-- Returns the dock's place of a position in metres (dock pixels around the centre circle, y up).
function BattleBayDeluxe.draft_dock_point(x, y)
  local L = BattleBayDeluxe.draft_layout
  local upper, lower = 2 * L.DOCK_TOP_HALF, 2 * L.DOCK_BOTTOM_HALF
  local total = L.DOCK_TOP - L.DOCK_BOTTOM
  local above, below = L.DOCK_TOP, -L.DOCK_BOTTOM
  local height = -y * (total / L.DOCK_DEPTH_UNITS) + total * 0.5
  local width = (upper - lower) * (height / total) + lower
  local ratio = y / L.DOCK_DEPTH_UNITS
  local up = below - y * (lower / L.DOCK_WIDTH_UNITS)
  if ratio < 0 then
    up = up + total * ratio * above / below
  elseif ratio > 0 then
    up = up + above * ratio * below / (total * 0.5)
  end
  return x * (width / L.DOCK_WIDTH_UNITS), up - below
end

-- the half width of the drawn pitch at screen height y
function BattleBayDeluxe.draft_pitch_half(y)
  local L = BattleBayDeluxe.draft_layout
  return L.TOP_HALF + (y - L.TOP) * (L.BOTTOM_HALF - L.TOP_HALF) / (L.BOTTOM - L.TOP)
end

-- a row's cards at least a card plus the gap apart (mirrored rows from the centre outwards), inside the pitch
function BattleBayDeluxe.draft_space_row(row, w, h)
  local L = BattleBayDeluxe.draft_layout
  local xs, n, step = row.xs, #row.xs, w + L.CARD_GAP
  if row.mirrored then
    local middle = math.floor(n / 2)
    local previous, first = -step / 2, middle + 1
    if row.clear_centre then
      previous = 0
    end
    if n % 2 == 1 then
      xs[middle + 1] = 0
      previous, first = 0, middle + 2
    end
    for i = first, n do
      previous = math.max(xs[i], previous + step)
      xs[i], xs[n + 1 - i] = previous, -previous
    end
  else
    for i = 2, n do
      xs[i] = math.max(xs[i], xs[i - 1] + step)
    end
  end
  local limit = BattleBayDeluxe.draft_pitch_half(row.y - h / 2) - w / 2 - L.EDGE_MARGIN
  if xs[n] > limit then
    xs[n] = limit
    for i = n - 1, 1, -1 do
      xs[i] = math.min(xs[i], xs[i + 1] - step)
    end
  end
  if xs[1] < -limit then
    xs[1] = -limit
    for i = 2, n do
      xs[i] = math.max(xs[i], xs[i - 1] + step)
    end
  end
end

-- Returns the height that two rows need between them.
function BattleBayDeluxe.draft_rows_need(a, b, w, h)
  local L = BattleBayDeluxe.draft_layout
  for _, xa in ipairs(a.xs) do
    for _, xb in ipairs(b.xs) do
      if math.abs(xa - xb) < w + L.CARD_GAP then
        return h + L.CARD_GAP
      end
    end
  end
  return 0
end

-- Pushes apart rows whose cards would touch, each by half the distance, inside the pitch's height.
function BattleBayDeluxe.draft_stack_rows(rows, w, h, yMin, yMax)
  local L = BattleBayDeluxe.draft_layout
  for _ = 1, L.ROUNDS do
    local moved = false
    for _, row in ipairs(rows) do
      BattleBayDeluxe.draft_space_row(row, w, h)
    end
    for i = 1, #rows - 1 do
      for j = i + 1, #rows do
        local a, b = rows[i], rows[j]
        local short = BattleBayDeluxe.draft_rows_need(a, b, w, h) - (b.y - a.y)
        if short > 0.01 then
          a.y, b.y = a.y - short / 2, b.y + short / 2
          moved = true
        end
      end
    end
    for _, row in ipairs(rows) do
      row.y = math.max(yMin, math.min(yMax, row.y))
    end
    if not moved then
      break
    end
  end
  for i = #rows - 1, 1, -1 do
    for j = i + 1, #rows do
      rows[i].y = math.min(rows[i].y, rows[j].y - BattleBayDeluxe.draft_rows_need(rows[i], rows[j], w, h))
    end
  end
end

function BattleBayDeluxe.draft_pitch_layout(places)
  local L = BattleBayDeluxe.draft_layout
  BattleBayDeluxe.draft_pitch_look()
  local w, h = L.CARD_WIDTH * L.CARD_SCALE, L.CARD_HEIGHT * L.CARD_SCALE
  local sx = (L.TOP_HALF + L.BOTTOM_HALF) / (L.DOCK_TOP_HALF + L.DOCK_BOTTOM_HALF)
  local sy = (L.BOTTOM - L.TOP) / (L.DOCK_TOP - L.DOCK_BOTTOM)
  local centreY = L.TOP + L.DOCK_TOP * sy
  local field, keepers = {}, {}
  for _, p in ipairs(places) do
    local x, y = BattleBayDeluxe.draft_dock_point(p[3], p[4])
    y = y + p[6] + (p[2] and L.DOCK_KEEPER_LIFT or 0)
    local card = {key = p[1], x = (x + p[5]) * sx, y = centreY - y * sy}
    if p[2] then
      keepers[#keepers + 1] = card
    else
      field[#field + 1] = card
    end
  end
  table.sort(field, function(a, b)
    if a.y ~= b.y then
      return a.y < b.y
    end
    return a.x < b.x
  end)
  local rows = {}
  for _, card in ipairs(field) do
    local row = rows[#rows]
    if row ~= nil and card.y - row.first <= L.SAME_ROW_DISTANCE then
      row.cards[#row.cards + 1] = card
    else
      rows[#rows + 1] = {first = card.y, cards = {card}}
    end
  end
  for _, card in ipairs(keepers) do
    rows[#rows + 1] = {first = card.y, cards = {card}}
  end
  local yMin = L.TOP + L.EDGE_MARGIN + h / 2
  local yMax = L.BOTTOM - L.EDGE_MARGIN - h / 2
  for _, row in ipairs(rows) do
    table.sort(row.cards, function(a, b)
      return a.x < b.x
    end)
    local n, sum, worst, xs = #row.cards, 0, 0, {}
    for i, card in ipairs(row.cards) do
      sum = sum + card.y
      xs[i] = card.x
    end
    for i = 1, n do
      worst = math.max(worst, math.abs(xs[i] + xs[n + 1 - i]))
    end
    row.mirrored = worst <= L.SYMMETRY_TOLERANCE * 2
    row.xs = {}
    for i = 1, n do
      row.xs[i] = row.mirrored and (xs[i] - xs[n + 1 - i]) / 2 or xs[i]
    end
    row.y = math.max(yMin, math.min(yMax, sum / n))
  end
  BattleBayDeluxe.draft_stack_rows(rows, w, h, yMin, yMax)
  if rows[1].y < yMin then
    -- Marks the rows when too many rows are stacked on the centre line for the pitch's height.
    for _, row in ipairs(rows) do
      row.clear_centre = #row.xs % 2 == 0
    end
    BattleBayDeluxe.draft_stack_rows(rows, w, h, yMin, yMax)
  end
  local out = {}
  for _, row in ipairs(rows) do
    BattleBayDeluxe.draft_space_row(row, w, h)
    for i, card in ipairs(row.cards) do
      out[card.key] = {L.CX + BattleBayDeluxe.draft.MIRROR * row.xs[i], row.y}
    end
  end
  return out
end

-- Returns a formation slot's place from the game's formation data (metres and menu pixels).
function BattleBayDeluxe.draft_slot_data(formation, slot, set)
  local L = BattleBayDeluxe.draft_layout
  local info = @crc:CMND_GET_SOCCER_FORMATION_INFO@
  local ok, x, _, y = funcLuaCommand(info, 4, formation, slot, set)
  if ok ~= true or type(x) ~= "number" or type(y) ~= "number" then
    return nil
  end
  local oko, ox, oy = funcLuaCommand(info, 4, formation, slot, L.OFFSET_SET)
  if oko ~= true or type(ox) ~= "number" or type(oy) ~= "number" then
    ox, oy = 0, 0
  end
  return x, y, ox, oy
end

function BattleBayDeluxe.draft_rule_places(id, list)
  local L = BattleBayDeluxe.draft_layout
  local function read(set)
    local places = {}
    for _, m in ipairs(list) do
      local x, y, ox, oy = nil, nil, 0, 0
      if id ~= 0 then
        x, y, ox, oy = BattleBayDeluxe.draft_slot_data(id, m[2], set)
      end
      if x == nil then
        x, y, ox, oy = (m[4] or 0) * L.START_WIDTH_METRES / 1000, (m[5] or 0) * L.START_DEPTH_METRES / 1000, 0, 0
      end
      places[#places + 1] = {m[1], m[3], x, y, ox, oy}
    end
    return places
  end
  local places = read(L.ATTACK_SET)
  for i = 1, #places - 1 do
    for j = i + 1, #places do
      if math.abs(places[i][3] - places[j][3]) < L.SAME_SPOT_METRES
        and math.abs(places[i][4] - places[j][4]) < L.SAME_SPOT_METRES then
        return read(L.START_SET)
      end
    end
  end
  return places
end

function BattleBayDeluxe.draft_place_field()
  local B = BattleBayDeluxe.draft
  local list = {}
  for k = 0, #B.slots - 1 do
    local rec = B.slots[k + 1]
    if rec.field then
      list[#list + 1] = {k, rec.slot, rec.pos == 1, rec.x, rec.y}
    end
  end
  for k, at in pairs(BattleBayDeluxe.draft_pitch_layout(BattleBayDeluxe.draft_rule_places(B.formation, list))) do
    B.pos[k] = {at[1], -at[2]}
  end
end

-- Returns the large or small pair index of a Draft card.
function BattleBayDeluxe.draft_size(layer, i)
  local B = BattleBayDeluxe.draft
  if layer == B.CARD then
    return B.SZ_CARD
  end
  local rec = i ~= nil and B.slots[i + 1] or nil
  if rec ~= nil and rec.pos == B.POS_COACH then
    return 1
  end
  return B.SZ
end

-- Draws a param with the retail card draw.
function BattleBayDeluxe.draft_card_draw(layer, i, param, big, kind, role)
  local B = BattleBayDeluxe.draft
  if role == B.POS_MANAGER then
    funcLuaMenuCommand(2339877830, layer, i, param, big, false, kind, 0, B.LEVEL, false, false, 4, 0, false, true, 0,
                       false, false, true)
  else
    funcLuaMenuCommand(2339877830, layer, i, param, big, role == B.POS_COACH, kind, 0, B.LEVEL, false, false, 4, 0)
  end
end

-- Runs after any draw of a card.
function BattleBayDeluxe.draft_card_meshes(layer, i)
  local B = BattleBayDeluxe.draft
  local sz = BattleBayDeluxe.draft_size(layer, i)
  for _, m in ipairs(B.M_FOCUS) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
  for j = 1, 2 do
    if j ~= sz then
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[j], false, i)
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_DEF[j], false, i)
    end
  end
end

-- Draws what a drafted or offered card shows.
function BattleBayDeluxe.draft_filled_card(layer, i, param, role)
  local sz = BattleBayDeluxe.draft_size(layer, i)
  BattleBayDeluxe.draft_face_on(layer, i, sz)
  BattleBayDeluxe.draft_card_draw(layer, i, param, sz == 1, 0, role)
  BattleBayDeluxe.draft_tags_off(layer, i)
  BattleBayDeluxe.draft_card_meshes(layer, i)
end

function BattleBayDeluxe.draft_face_on(layer, i, sz)
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, true)
  for _, m in ipairs(B.M_DEF) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
  for k = sz, #B.M_FACE, 2 do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_FACE[k], true, i)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[sz], true, i)
end

-- the season tag / lock of a card instance hidden (after a draw)
function BattleBayDeluxe.draft_tags_off(layer, i)
  for _, m in ipairs(BattleBayDeluxe.draft.M_TAG) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
end

-- Draws an empty card centred.
function BattleBayDeluxe.draft_empty_card(layer, i, ph, grey, kind, role)
  local B = BattleBayDeluxe.draft
  local sz = BattleBayDeluxe.draft_size(layer, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, true)
  if type(ph) == "number" and ph ~= 0 then
    BattleBayDeluxe.draft_card_draw(layer, i, ph, sz == 1, type(kind) == "number" and kind or 0, role)
  else
    grey = true
  end
  for _, list in ipairs({B.M_FACE, B.M_EMPTY, B.M_TAG, B.M_STAFF}) do
    for _, m in ipairs(list) do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
    end
  end
  for _, n in ipairs(B.N_STAFF) do
    funcLuaMenuCommand(2158717427 --[[node visible]], layer, n, false, i)
  end
  if role == B.POS_COACH then
    funcLuaMenuCommand(2158717427 --[[node visible]], layer, B.N_STAFF[sz], true, i)
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_STAFF[sz], true, i)
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_STAFF[2 + sz], true, i)
  end
  local j = sz
  if grey then
    funcLuaMenuCommand(558735651, layer, B.TEX_CARD, j == 1 and B.SPR_GREY_L or B.SPR_GREY, B.SLOT_BASE[j], 0, i)
  end
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_BASE[j], true, i)
  local qs = j == 1 and B.Q_SCALE_L or B.Q_SCALE
  local qw, qh = B.Q_W * qs * B.Q_BOLD_X, B.Q_H * qs
  funcLuaMenuCommand(B.NODE_SCALE, layer, i, B.M_DEF[j], qw, qh)
  funcLuaMenuCommand(B.NODE_POS, layer, i, B.M_DEF[j], 0, -qw / 2)
  funcLuaMenuCommand(B.NODE_POS, layer, i, B.M_DEF[j], 1, qh / 2)
  funcLuaMenuCommand(558735651, layer, B.TEX_NUM, B.SPR_Q, B.SLOT_DEF[j], 0, i)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_DEF[j], true, i)
  BattleBayDeluxe.draft_card_meshes(layer, i)
  funcLuaMenuCommand(@crc:CMND_SET_MENU_TEXT_STRING@, layer, B.T_NAME, "", i)
end

-- the empty look again (a late face / icon load can switch a mesh back on)
function BattleBayDeluxe.draft_rehide(layer, i)
  for _, m in ipairs(BattleBayDeluxe.draft.M_FACE) do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, m, false, i)
  end
end

function BattleBayDeluxe.draft_draw_slot(k)
  local B = BattleBayDeluxe.draft
  local rec, w = B.slots[k + 1], B.where[k]
  if rec == nil or w == nil then
    return
  end
  local layer, i = w[1], w[2]
  if not B.ready[layer .. ":" .. i] then
    return
  end
  if B.mode == "formation" and rec.staff then
    -- Hides the layer because the formation step's strip covers the bottom edge.
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
    return
  end
  if rec.param ~= 0 then
    BattleBayDeluxe.draft_filled_card(layer, i, rec.param, rec.pos)
  else
    local kind = 0
    if rec.field and B.formation ~= 0 then
      local okk, kk = funcLuaCommand(@crc:CMND_GET_SOCCER_FORMATION_INFO@ --[[formation info]], 6, B.formation, rec.slot)
      kind = (okk == true and type(kk) == "number") and kk or 0
    end
    local grey = B.BENCH_GREY and not rec.field and rec.pos ~= B.POS_MANAGER
    BattleBayDeluxe.draft_empty_card(layer, i, rec.ph, grey, kind, rec.pos)
    B.reapply = B.REAPPLY_FRAMES
  end
  local sc = rec.pos == B.POS_COACH and B.COACH_SCALE or B.SLOT_SCALE
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, layer, B.pos[k][1], B.pos[k][2], 0, i)
  funcLuaMenuCommand(3362798188, layer, i, sc, sc)
end

-- the pitch and the bench
function BattleBayDeluxe.draft_draw_pitch()
  for k = 0, #BattleBayDeluxe.draft.slots - 1 do
    BattleBayDeluxe.draft_draw_slot(k)
  end
end

function BattleBayDeluxe.draft_draw_candidate(i)
  local B = BattleBayDeluxe.draft
  local p = B.cands[i + 1]
  if not B.ready[B.CARD .. ":" .. i] or B.pk ~= nil then
    return
  end
  if p == nil or B.mode ~= "cands" then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
    return
  end
  BattleBayDeluxe.draft_filled_card(B.CARD, i, p.param, p.pos)
  local s = i == B.csel and B.CARD_SCALE_ON or B.CARD_SCALE
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CARD, B.CAND_X, B.CAND_Y + i * B.CAND_DY, 0, i)
  funcLuaMenuCommand(3362798188, B.CARD, i, s, s)
end

-- Returns the retail formation focus label of the selected card.
function BattleBayDeluxe.draft_cursor_label(layer, i)
  return BattleBayDeluxe.draft_size(layer, i) == 1 and BattleBayDeluxe.draft.CARD_CURSOR or BattleBayDeluxe.draft.CARD_CURSOR2
end

function BattleBayDeluxe.draft_cursor()
  local B = BattleBayDeluxe.draft
  if B.shown ~= nil then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, B.shown[1], B.shown[2],
                       BattleBayDeluxe.draft_cursor_label(B.shown[1], B.shown[2]), false)
    for _, m in ipairs(B.M_FOCUS) do
      funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.shown[1], m, false, B.shown[2])
    end
    B.shown = nil
  end
  if B.mode == "formation" then
    -- Hides the cursor during the formation step.
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, false)
    return
  end
  local layer, i, n
  if B.mode == "cands" then
    if BattleBayDeluxe.draft_pack_busy() then
      -- no cursor while the pack's cards are dealt and turned (BattleBayDeluxe.draft_pack_done puts it back)
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, false)
      return
    end
    layer, i, n = B.CARD, B.csel, 5
  elseif B.mode == "pitch" or B.mode == "start" or B.mode == "quit" then
    local w = B.where[B.sel]
    if w == nil then
      return
    end
    layer, i, n = w[1], w[2], #B.slots
  else
    return
  end
  local sz = BattleBayDeluxe.draft_size(layer, i)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CURSOR, 0, true)
  if layer == B.CARD and B.pk ~= nil then
    -- Draws the cursor on the pack's band.
    B.pk.cur = nil
    BattleBayDeluxe.draft_pack_cursor()
  else
    if B.curMoved then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CURSOR, 0, 0, 0, 0)
      B.curMoved = false
    end
    local label = BattleBayDeluxe.draft_cursor_label(layer, i)
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_ATTACH_LOCATOR_TRACE@, layer, i, label, true)
    funcLuaMenuCommand(@crc:CMND_SET_CURSOR_LOCATOR@, layer, label, i, n)
  end
  for j = 1, 2 do
    funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, layer, B.M_FOCUS[j], j == sz, i)
  end
  B.shown = {layer, i}
end

-- Holds the panel while the Draft screen is open.
function BattleBayDeluxe.draft_panel_hold()
  local B = BattleBayDeluxe.draft
  BattleBayDeluxe.draft_layer_visible(B.LEFT, 11, false)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.FRAME, B.PITCH_CX - B.FRAME_FIELD_CX, B.FRAME_DY, 0, 0)
  funcLuaMenuCommand(3362798188, B.FRAME, 0, B.FRAME_SX, B.FRAME_SY)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.FRAME, 0, true)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.FRAME, B.M_FIELD, true, 0)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.TACTICS_BASE, 0, false)
  BattleBayDeluxe.draft_layer_visible(B.TACTICS_CMD, 3, false)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.TEAMINFO, B.M_TACTICS_LABEL, false, 0)
end

-- every visible instance of a layer hidden and remembered (BattleBayDeluxe.draft_unstash restores them)
function BattleBayDeluxe.draft_stash(layer)
  local B = BattleBayDeluxe.draft
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, layer)
  if type(n) ~= "number" or n <= 0 then
    n = 1
  end
  for i = 0, n - 1 do
    if funcLuaMenuCommand(@crc:CMND_IS_LAYER_VISIBLE@, layer, i) == true then
      funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, layer, i, false)
      B.stash[#B.stash + 1] = {layer, i}
    end
  end
end

function BattleBayDeluxe.draft_unstash()
  local B = BattleBayDeluxe.draft
  local list = B.stash
  B.stash = {}
  for _, e in ipairs(list) do
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, e[1], e[2], true)
  end
end

function BattleBayDeluxe.draft_screen_on()
  local B = BattleBayDeluxe.draft
  -- Closes the team panel because it holds the picker's 3D character.
  if not B.panelClosed then
    B.panelClosed = BattleBayDeluxe.draft_team_panel_close()
  end
  if BattleBayDeluxe.draft_free() then
    if #B.stash == 0 then
      BattleBayDeluxe.draft_stash(B.GRID)
      BattleBayDeluxe.draft_stash(B.ATTACH)
      BattleBayDeluxe.draft_stash(B.LOCK)
      for _, layer in ipairs(B.FREE_HIDE) do
        BattleBayDeluxe.draft_stash(layer)
      end
    end
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, false)
    if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.hide ~= nil) then
      pcall(VRFW.battle_bay_pages.hide)
    end
    BattleBayDeluxe.draft_panel_hold()
    return
  end
  BattleBayDeluxe.draft_layer_visible(B.GRID, funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.GRID) or 0, false)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.ATTACH, 0, false)
  BattleBayDeluxe.draft_layer_visible(B.LOCK, funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.LOCK) or 0, false)
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, B.GRID, false)
  -- Hides the framework's page, category and season line over the grid (graft vrfw_bb_pages).
  if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.hide ~= nil) then
    pcall(VRFW.battle_bay_pages.hide)
  end
  BattleBayDeluxe.draft_panel_hold()
end

-- Restores the page line (vrfw_bb_pages) when the Draft screen turns off.
function BattleBayDeluxe.draft_screen_off()
  local B = BattleBayDeluxe.draft
  if B.panelClosed then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, B.TEAMINFO)
    B.panelClosed = false
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.FRAME, 0, 0, 0, 0)
  funcLuaMenuCommand(3362798188, B.FRAME, 0, 1, 1)
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.TACTICS_BASE, 0, true)
  BattleBayDeluxe.draft_layer_visible(B.TACTICS_CMD, 3, true)
  funcLuaMenuCommand(@crc:CMND_SET_MESH_VISIBLE@, B.TEAMINFO, B.M_TACTICS_LABEL, true, 0)
  if BattleBayDeluxe.draft_free() then
    BattleBayDeluxe.draft_unstash()
  end
  if (VRFW.battle_bay_pages ~= nil and VRFW.battle_bay_pages.setup_line ~= nil) then
    pcall(VRFW.battle_bay_pages.setup_line, 0)
  end
end

function BattleBayDeluxe.draft_probe()
  local B = BattleBayDeluxe.draft
  local parts = {}
  for _, node in ipairs(B.FRAME_NODES) do
    local x, y, z, ok = funcLuaMenuCommand(@crc:CMND_GET_MESH_POSE@, B.FRAME, 0, node)
    parts[#parts + 1] = string.format("%s(%s,%s,%s)", tostring(ok), tostring(x), tostring(y), tostring(z))
  end
  local fx, fy = funcLuaMenuCommand(@crc:CMND_GET_LAYER_LOCAL_POS@, B.FRAME, 0)
  local sx, sy = funcLuaMenuCommand(@crc:CMND_GET_LAYER_LOCAL_POS@, B.SLOT, 0)
  BattleBayDeluxe.draft_log("layout probe: frame nodes cc/ld/ru", table.concat(parts, " "), "frame at", tostring(fx), tostring(fy),
              "slot 0 at", tostring(sx), tostring(sy))
  pcall(BattleBayDeluxe.draft_stray_scan)
end

-- every visible instance of B.STRAY_LAYERS within STRAY_X px of the left edge, in one log line per screen
function BattleBayDeluxe.draft_stray_scan()
  local B = BattleBayDeluxe.draft
  local hits = {}
  for _, e in ipairs(B.STRAY_LAYERS) do
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, e[2])
    for i = 0, (type(n) == "number" and n or 0) - 1 do
      local vis = VRFW.host.menu_command(@crc:CMND_IS_LAYER_VISIBLE@ --[[is visible]], e[2], i)
      local gx, gy = VRFW.host.menu_command(@crc:CMND_GET_LAYER_GLOBAL_POS@ --[[global position]], e[2], i)
      if vis == true and type(gx) == "number" and gx >= -B.STRAY_X and gx <= B.STRAY_X then
        hits[#hits + 1] = string.format("%s[%d] at %d,%d", e[1], i, math.floor(gx), math.floor(-(gy or 0)))
      end
    end
  end
  BattleBayDeluxe.draft_log("left-edge scan: " .. (#hits > 0 and table.concat(hits, "; ") or "no visible layer of the list there"))
end
