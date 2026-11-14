local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Call, Cut, Fit, G, Hit, K = Screen.C, Screen.CE, Screen.call, Screen.cut, Screen.fit, Screen.G, Screen.hit, Screen.K
local DrawScrollbar, Quad, SE_MOVE, SE_NG, SE_OK, SP = Screen.draw_scrollbar, Screen.quad, Screen.SE_MOVE, Screen.SE_NG, Screen.SE_OK, Screen.SP
local Str, T, Txt, Units, Literal = Screen.str, Screen.T, Screen.txt, Screen.units, Screen.literal
local mouse, ui = Screen.mouse, Screen.ui

-- The «Base game» tab: the game's own content as every mod left it, with the player's own values on top.
local BG = {
  STATS_COUNT = VRFW.commands.VRFW_TECHNIQUE_STATS_COUNT,   -- () -> rows
  STATS_ROW = VRFW.commands.VRFW_TECHNIQUE_STATS_ROW,       -- (i) -> id, key, then shown, mods, base, own per value
  STATS_SET = VRFW.commands.VRFW_TECHNIQUE_STATS_SET,       -- (i, value index, value | nil) -> ok, reason
  SKILL_INFO = 2580586398,   -- (move, field) -> ok, value; field 4 = the name's text id
  NAME_TEXT = 720417636,     -- (name id, variant) -> text id
  TEXT_CONVERT = 820766113,  -- (text id, 0, tag, partner) -> the shown string
  TEXT_TAG = 2508554842,
  SECTIONS = {{key = "bg_techniques"}},
  -- The value columns: text key, left edge, step of L1 / R1, decimals shown.
  COLUMNS = {{key = "bg_col_power_min", x = 860, step = 1, dec = 0},
             {key = "bg_col_power_max", x = 1120, step = 1, dec = 0},
             {key = "bg_col_tension", x = 1380, step = 1, dec = 0},
             {key = "bg_col_cooldown", x = 1640, step = 0.5, dec = 1}},
  VALUES = 4,
  X = 22, W = 1856, NAME_X = 50, CELL_W = 236, SB_X = 1886,
  CHIP_X = 25, CHIP_W = 260, CHIP_STEP = 268,
  HEAD_H = 40, ROW_H = 54, STEP = 58, HINT_H = 40,
  VALUE_SCALE = 0.7, BASE_SCALE = 0.52, NAME_SCALE = 0.7, HEAD_SCALE = 0.62,
  rows = nil, shown = nil, lang = nil,
}
BG.LIST_Y = G.LIST_Y + BG.HEAD_H
BG.ROWS = math.floor((G.BOX_BOTTOM - G.BOX_PAD - BG.HINT_H - BG.LIST_Y) / BG.STEP)

-- The tab's state, kept in the screen's ui table (a reset of the screen clears it).
local function St()
  if ui.base_game == nil then
    ui.base_game = {section = 1, sel = 1, top = 0, col = 1, query = ""}
  end
  return ui.base_game
end

-- The shown name of move `id` (the game's own lookup; empty when the game has none).
local function MoveName(id)
  local ok, name_id = funcLuaCommand(BG.SKILL_INFO, id, 4)
  if ok ~= true or type(name_id) ~= "number" then
    return ""
  end
  local text_id = funcLuaCommand(BG.NAME_TEXT, name_id, 0)
  return Str(funcLuaCommand(BG.TEXT_CONVERT, text_id, 0, BG.TEXT_TAG, ""))
end

-- One row of the technique list read from the framework (index i, 1-based).
local function ReadRow(i)
  local r = table.pack(Call(BG.STATS_ROW, i - 1))
  if type(r[1]) ~= "number" or r[1] == 0 then
    return nil
  end
  local row = {i = i, id = r[1], key = Str(r[2]), shown = {}, mods = {}, base = {}, own = {}}
  for k = 1, BG.VALUES do
    local at = 2 + (k - 1) * 4
    row.shown[k], row.mods[k] = tonumber(r[at + 1]) or 0, tonumber(r[at + 2]) or 0
    row.base[k] = (tonumber(r[at + 3]) or -1) >= 0 and r[at + 3] or nil
    row.own[k] = r[at + 4] == true
  end
  return row
end

-- Every technique with its name, read once per language.
local function Rows()
  if BG.rows ~= nil and BG.lang == Screen.lang() then
    return BG.rows
  end
  BG.rows, BG.shown, BG.lang = {}, nil, Screen.lang()
  local n = tonumber(Call(BG.STATS_COUNT)) or 0
  for i = 1, n do
    local row = ReadRow(i)
    if row ~= nil then
      local name = MoveName(row.id)
      row.name = name ~= "" and name or row.key
      row.find = string.lower(row.name)
      BG.rows[#BG.rows + 1] = row
    end
  end
  table.sort(BG.rows, function(a, b) return a.find < b.find or (a.find == b.find and a.i < b.i) end)
  return BG.rows
end

-- The rows the search leaves.
local function Shown()
  if BG.shown ~= nil then
    return BG.shown
  end
  local q = string.lower(St().query)
  BG.shown = {}
  for _, r in ipairs(Rows()) do
    if q == "" or string.find(r.find, q, 1, true) ~= nil then
      BG.shown[#BG.shown + 1] = r
    end
  end
  return BG.shown
end

-- Number `v` with the column's decimals.
local function Fmt(v, col)
  if BG.COLUMNS[col].dec > 0 and v ~= math.floor(v) then
    return string.format("%." .. BG.COLUMNS[col].dec .. "f", v)
  end
  return string.format("%d", math.floor(v + 0.5))
end

-- Keeps the selection in the list and on the shown page.
local function Clamp()
  local s, n = St(), #Shown()
  s.sel = math.max(1, math.min(s.sel, math.max(1, n)))
  if s.sel <= s.top then
    s.top = s.sel - 1
  elseif s.sel > s.top + BG.ROWS then
    s.top = s.sel - BG.ROWS
  end
  s.top = math.max(0, math.min(s.top, math.max(0, n - BG.ROWS)))
end

-- Stores value `col` of the selected move (nil = back to the mods' value) and reads the row again.
local function Store(row, col, value)
  local ok, why = Call(BG.STATS_SET, row.i - 1, col - 1, value)
  if ok ~= true then
    Screen.log("base_game", "set failed", row.key, tostring(col), Str(why))
    funcLuaCommand(C.SE, SE_NG)
    return false
  end
  local fresh = ReadRow(row.i)
  if fresh ~= nil then
    row.shown, row.mods, row.base, row.own = fresh.shown, fresh.mods, fresh.base, fresh.own
  end
  Screen.log("base_game", "set", row.key, tostring(col), tostring(value))
  return true
end

local function Selected()
  Clamp()
  return Shown()[St().sel]
end

-- The tab's sub-sections (L3 cycles them) and the list's search, under the tabs.
function CE.draw_base_game_bar()
  local s = St()
  local y, h = G.TOOLS_Y, G.TOOLS_H
  for k, sec in ipairs(BG.SECTIONS) do
    local x = BG.CHIP_X + (k - 1) * BG.CHIP_STEP
    local sel = s.section == k
    Quad("Q0", SP((sel or mouse.hot == "bgsec" .. k) and "tool2_sel" or "tool2"), x, y, BG.CHIP_W, h)
    local label = (sel and #BG.SECTIONS > 1 and (K.L3 .. " ") or "") .. T(sec.key)
    Txt("TC", Cut(label, Fit(BG.CHIP_W - 24, 0.66)), x + BG.CHIP_W / 2, y + h / 2, 0.66)
    Hit(x, y, BG.CHIP_W, h, "bgsec" .. k, function()
      if s.section ~= k then
        CE.base_game_section(k - s.section)
      end
    end)
  end
  local n = #Shown()
  CE.row_search({on = true, x = BG.CHIP_X + #BG.SECTIONS * BG.CHIP_STEP + 10, query = s.query, hint = "bg_search_hint", id = "bgsearch",
                 foc = mouse.hot == "bgsearch", count = T("bg_count", {n = n, t = #Rows()}),
                 act = function() Screen.start_co(CE.base_game_search) end})
  local pages = math.max(1, math.ceil(n / BG.ROWS))
  local page = math.floor(s.top / BG.ROWS) + 1
  Txt("TR", "[CWG]" .. T("bg_page", {p = math.min(page, pages), n = pages}) .. "[C]", BG.X + BG.W, y + h / 2, 0.66)
end

-- One value cell: the effective value, then the game's own value in grey when it differs.
local function DrawCell(row, col, y, focused)
  local c = BG.COLUMNS[col]
  local cy = y + BG.ROW_H / 2
  if focused then
    Quad("Q1", SP("set_val_sel"), c.x - 16, y + 4, BG.CELL_W, BG.ROW_H - 8)
    Quad("Q1", SP("set_arr_l"), c.x - 8, math.floor(cy - 10), 12, 20)
    Quad("Q1", SP("set_arr_r"), c.x + BG.CELL_W - 32, math.floor(cy - 10), 12, 20)
  end
  local v = Fmt(row.shown[col], col)
  local ink = row.own[col] and "[CY]" or "[CB]"
  local x = c.x + 12
  Txt("TL", ink .. v .. "[C]", x, cy, BG.VALUE_SCALE)
  local base = row.base[col]
  if base ~= nil and Fmt(base, col) ~= v then
    Txt("TL", "[CWG][" .. Fmt(base, col) .. "][C]", x + Units(v) * G.PX * BG.VALUE_SCALE + 10, cy + 2, BG.BASE_SCALE)
  end
end

local function DrawRow(row, n, y, sel)
  local s = St()
  local cy = y + BG.ROW_H / 2
  Quad("Q2", SP(sel and "lplate_sel" or "lplate"), BG.X, y, BG.W, BG.ROW_H)
  if sel then
    Quad("Q1", SP("arrow_g"), BG.X - 20, cy - 14, 18, 28)
  end
  Txt("TL", "[CB]" .. Cut(Literal(row.name), Fit(BG.COLUMNS[1].x - BG.NAME_X - 40, BG.NAME_SCALE)) .. "[C]", BG.NAME_X, cy, BG.NAME_SCALE)
  for col = 1, BG.VALUES do
    DrawCell(row, col, y, sel and s.col == col and ui.popup == nil)
    local c = BG.COLUMNS[col]
    Hit(c.x - 16, y, BG.CELL_W, BG.ROW_H, "bgcell" .. n .. "_" .. col, function()
      if s.sel == n and s.col == col then
        CE.base_game_decide()
      else
        s.sel, s.col = n, col
        funcLuaCommand(C.SE, SE_MOVE)
        Screen.draw()
      end
    end)
  end
end

-- The list: column titles, one page of moves, the scrollbar and the key hints.
function CE.draw_base_game()
  local s = St()
  CE.round_box("Q0", "navy", "disc_navy", G.BOX_X, G.BOX_Y, BG.SB_X + 18 - G.BOX_X, G.BOX_BOTTOM - G.BOX_Y, G.BOX_R)
  local hy = G.LIST_Y + BG.HEAD_H / 2 - 4
  Txt("TL", Cut(T("bg_col_name"), Fit(BG.COLUMNS[1].x - BG.NAME_X - 40, BG.HEAD_SCALE)), BG.NAME_X, hy, BG.HEAD_SCALE)
  for _, c in ipairs(BG.COLUMNS) do
    Txt("TL", Cut(T(c.key), Fit(BG.CELL_W - 20, BG.HEAD_SCALE)), c.x + 12, hy, BG.HEAD_SCALE)
  end
  local shown = Shown()
  Clamp()
  if #shown == 0 then
    Quad("Q2", SP("white"), BG.X, BG.LIST_Y, BG.W, 120)
    local key = #Rows() == 0 and "bg_empty" or "bg_empty_search"
    Txt("TL", "[CN]" .. Cut(T(key), Fit(BG.W - 80, 0.8)) .. "[C]", BG.X + 30, BG.LIST_Y + 60, 0.8)
  end
  for i = 1, math.min(BG.ROWS, #shown - s.top) do
    local n = s.top + i
    DrawRow(shown[n], n, BG.LIST_Y + (i - 1) * BG.STEP, n == s.sel)
  end
  DrawScrollbar(#shown, s.top, BG.ROWS, BG.SB_X, BG.LIST_Y, BG.ROWS * BG.STEP - (BG.STEP - BG.ROW_H), function(f)
    s.top, s.sel = f, f + 1
  end)
  local keys = K.L1 .. K.R1 .. " " .. T("bg_key_change") .. "   " .. K.A .. " " .. T("bg_key_type") .. "   " .. K.Y .. " " .. T("bg_key_reset")
  Txt("TL", "[CWG]" .. Cut(keys .. "   ·   " .. T("bg_restart"), Fit(BG.W - 40, 0.56)) .. "[C]", BG.X + 8, G.BOX_BOTTOM - BG.HINT_H / 2 - 6, 0.56)
end

-- The arrows: up / down move between moves, left / right between the value columns.
function CE.base_game_move(dx, dy)
  local s = St()
  local n = #Shown()
  local sel, col = s.sel + dy, s.col + dx
  if n == 0 or sel < 1 or sel > n or col < 1 or col > BG.VALUES then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  s.sel, s.col = sel, col
  Clamp()
  funcLuaCommand(C.SE, SE_MOVE)
  Screen.draw()
end

-- L1 / R1: the focused value one step down / up.
function CE.base_game_step(d)
  local row, s = Selected(), St()
  if row == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  local v = math.max(0, row.shown[s.col] + d * BG.COLUMNS[s.col].step)
  if v == row.shown[s.col] then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if Store(row, s.col, v) then
    funcLuaCommand(C.SE, SE_MOVE)
  end
  Screen.draw()
end

-- Y: the focused value back to the mods' value («Restablecer»).
function CE.base_game_reset()
  local row, s = Selected(), St()
  if row == nil or not row.own[s.col] then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  if Store(row, s.col, nil) then
    funcLuaCommand(C.SE, SE_OK)
  end
  Screen.draw()
end

-- A: type the focused value on the game's keyboard.
function CE.base_game_decide()
  local row, s = Selected(), St()
  if row == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  local col = s.col
  Screen.start_co(function()
    local typed = Screen.keyboard(Fmt(row.shown[col], col), "bg_kb_value", Screen.RT_SEARCH, 6)
    local v = tonumber(typed or "")
    if v ~= nil and v >= 0 and v ~= row.shown[col] then
      Store(row, col, v)
    elseif typed ~= nil and v == nil then
      funcLuaCommand(C.SE, SE_NG)
    end
    Screen.draw()
  end)
end

-- L3 / a click: the next sub-section.
function CE.base_game_section(d)
  local s = St()
  local k = ((s.section - 1 + d) % #BG.SECTIONS) + 1
  if k == s.section then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  s.section, s.sel, s.top = k, 1, 0
  funcLuaCommand(C.SE, SE_MOVE)
  Screen.draw()
end

-- R3 / the search box: part of a name (empty = every move).
function CE.base_game_search()
  local s = St()
  local q = Screen.keyboard(s.query, "bg_search_title", Screen.RT_SEARCH, 24)
  if q ~= nil then
    s.query, s.sel, s.top = q, 1, 0
    BG.shown = nil
    Screen.log("base_game", "search", q, "shown", #Shown())
  end
  Screen.draw()
end

-- B with a search: clears it (true = it was cleared).
function CE.base_game_clear_search()
  local s = St()
  if s.query == "" then
    return false
  end
  s.query, s.sel, s.top = "", 1, 0
  BG.shown = nil
  return true
end

-- The mouse over a value cell selects it (true = draw again).
function CE.base_game_hover(id)
  local n, col = string.match(id, "^bgcell(%d+)_(%d+)$")
  n, col = tonumber(n or ""), tonumber(col or "")
  local s = St()
  if n == nil or Shown()[n] == nil or (n == s.sel and col == s.col) then
    return false
  end
  s.sel, s.col = n, col
  return true
end
