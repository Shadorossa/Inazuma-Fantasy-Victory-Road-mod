local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Call, Crc, Cut, Fit = Screen.C, Screen.CE, Screen.call, Screen.crc, Screen.cut, Screen.fit
local DrawScrollbar, G, Hit, Int, K, M = Screen.draw_scrollbar, Screen.G, Screen.hit, Screen.int, Screen.K, Screen.M
local ModById, OpenDetails, Quad, RV, SE_MOVE, SE_NG = Screen.mod_by_id, Screen.open_details, Screen.quad, Screen.RV, Screen.SE_MOVE, Screen.SE_NG
local SP, Str, T, Txt, Units, cnt = Screen.SP, Screen.str, Screen.T, Screen.txt, Screen.units, Screen.cnt
local Literal = Screen.literal
local mouse, ui = Screen.mouse, Screen.ui

local PR = {
  VERSION = Crc("CMND_VRFW_REPORT_VERSION"),
  MAX = 600,
  GAME = "@game",                -- the group of the game's own scripts and of the game version
  RANK = {error = 1, warn = 2, info = 3},
  SEVERITIES = {"error", "warn", "info"},   -- The order the rows are read in.
  FILTERS = {{key = "pr_problems", sev = {error = true, warn = true}}, {key = "pr_errors", sev = {error = true}},
             {key = "pr_warnings", sev = {warn = true}}, {key = "pr_info", sev = {info = true}}},
  -- the list: full width in the navy box, one row pitch for group headers and problems
  X = 22, W = 1856, ROW_H = 58, STEP = 62, SB_X = 1886,
  CHIP_X = 25, CHIP_W = 190, CHIP_STEP = 198,   -- the filters, left of the profile button (G.PROF_X)
  data = nil, ver = nil, ids = nil,
}
CE.PROBLEM_ROWS = math.floor((G.BOX_BOTTOM - G.BOX_PAD - G.LIST_Y) / PR.STEP)

-- the place of a group: the game first, the framework second, then the mods in load order, unknown ids last
local function GroupRank(id)
  if id == PR.GAME then
    return -2
  end
  local m = ModById(id)
  if m == nil then
    return 100000
  end
  if m == Screen.base_mod() then
    return -1
  end
  return m.pos > 0 and m.pos or (50000 + (m.idx or 0))
end

local function GroupName(id)
  if id == PR.GAME then
    return T("pr_group_game"), ""
  end
  local m = ModById(id)
  if m == nil then
    return id, ""
  end
  return m.name ~= "" and m.name or m.id, m.version
end

local function Read()
  local ver, ids = Int(Call(PR.VERSION)), Screen.text_ids()
  if PR.data ~= nil and PR.ver == ver and PR.ids == ids then
    return PR.data
  end
  local groups, list = {}, {}
  local d = {groups = list, total = 0, n = {error = 0, warn = 0, info = 0}, more = false}
  local left = PR.MAX
  for _, want in ipairs(PR.SEVERITIES) do
    local n = Int(Call(M.REPORT_COUNT, "", "", want))
    d.n[want] = n
    d.total = d.total + n
    d.more = d.more or n > left
    for i = 0, math.min(n, left) - 1 do
      local sev, ty, code, loc, msg, mod, _, _, win, _, cat, hint = Call(M.REPORT_ROW, i, "", "", want)
      local e = {sev = Str(sev), ty = Str(ty), code = Str(code), loc = Str(loc), msg = Str(msg), win = Str(win),
                 cat = Str(cat), hint = Str(hint)}
      if PR.RANK[e.sev] ~= nil then
        local gid = (e.ty == "game_script" or e.ty == "game") and PR.GAME or Str(mod)
        local g = groups[gid]
        if g == nil then
          g = {id = gid, items = {}, n = {error = 0, warn = 0, info = 0}}
          groups[gid] = g
          list[#list + 1] = g
        end
        -- the place inside the mod's folder (the core writes mods/<id>/<file>:<line>; "-" = none)
        e.where = e.loc == "-" and "" or (string.gsub(e.loc, "^mods/[^/]+/", ""))
        e.title = RV.head(e, RV.wanted(e))
        if e.win ~= "" then
          e.msg = e.msg .. "  (" .. T("rp_winner", {w = e.win}) .. ")"
        end
        g.items[#g.items + 1] = e
        g.n[e.sev] = g.n[e.sev] + 1
      end
    end
    left = left - math.min(n, left)
  end
  for _, g in ipairs(list) do
    g.rank = GroupRank(g.id)
    g.name, g.version = GroupName(g.id)
    table.sort(g.items, function(a, b)
      if a.sev ~= b.sev then
        return PR.RANK[a.sev] < PR.RANK[b.sev]
      end
      if a.code ~= b.code then
        return a.code < b.code
      end
      if a.ty ~= b.ty then
        return a.ty < b.ty
      end
      return a.where < b.where
    end)
  end
  table.sort(list, function(a, b)
    if a.rank ~= b.rank then
      return a.rank < b.rank
    end
    return a.id < b.id
  end)
  PR.data, PR.ver, PR.ids, PR.rows = d, ver, ids, nil
  return d
end

-- the visible list under the filter: a header per group that has rows, then its problems
local function Rows()
  local d = Read()
  if PR.rows ~= nil and PR.rows_filter == ui.pfilter then
    return PR.rows
  end
  local want = PR.FILTERS[ui.pfilter].sev
  local rows = {}
  for _, g in ipairs(d.groups) do
    local head = nil
    for _, e in ipairs(g.items) do
      if want[e.sev] then
        if head == nil then
          head = {head = true, g = g}
          rows[#rows + 1] = head
        end
        rows[#rows + 1] = {e = e, g = g}
      end
    end
  end
  PR.rows, PR.rows_filter = rows, ui.pfilter
  return rows
end

function CE.headed_selected(rows, s)
  if rows[s] == nil or rows[s].head then
    s = 0
    for k, r in ipairs(rows) do
      if not r.head then
        s = k
        break
      end
    end
  end
  return s
end

-- the real row `d` real rows away from row s (headers skipped); a longer step stops at the last row it reaches
function CE.headed_step(rows, s, d)
  local step = d > 0 and 1 or -1
  local left = math.abs(d)
  local t = s
  while left > 0 do
    local k = t + step
    while rows[k] ~= nil and rows[k].head do
      k = k + step
    end
    if rows[k] == nil then
      break
    end
    t, left = k, left - 1
  end
  return t
end

-- the first row shown with `vis` rows on screen: selection s in view, its header too when it fits
function CE.headed_top(top, s, vis, n)
  if s > 0 then
    if s - 1 < top then
      top = math.max(0, s - 2)
    elseif s > top + vis then
      top = s - vis
    end
  end
  return math.max(0, math.min(top, n - vis))
end

-- the selected row: a problem row (never a header); 0 = none
local function Selected(rows)
  ui.psel = CE.headed_selected(rows, ui.psel)
  return ui.psel
end

function CE.problem_tab_label()
  local d = Read()
  return T("tab_problems_all", {n = d.n.error + d.n.warn})
end

-- the mod of the selected problem (nil = none, or the game's group without a page)
function CE.problem_mod()
  local rows = Rows()
  local r = rows[Selected(rows)]
  if r == nil then
    return nil
  end
  return ModById(r.g.id == PR.GAME and Screen.BASE or r.g.id)
end

-- the view of the mod's page that lists the selected problem
function CE.problem_view()
  local rows = Rows()
  local r = rows[Selected(rows)]
  return (r ~= nil and r.e ~= nil and r.e.cat == "conflict") and "conflicts" or "problems"
end

function CE.problem_open()
  if CE.problem_mod() == nil then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  OpenDetails()
end

function CE.problem_move(d)
  local rows = Rows()
  local s = Selected(rows)
  local t = CE.headed_step(rows, s, d)
  if t == s or s == 0 then
    funcLuaCommand(C.SE, SE_NG)
    return
  end
  funcLuaCommand(C.SE, SE_MOVE)
  ui.psel = t
  Screen.draw()
end

function CE.problem_filter(d)
  ui.pfilter = ((ui.pfilter - 1 + d) % #PR.FILTERS) + 1
  ui.psel, ui.ptop = 0, 0
  funcLuaCommand(C.SE, SE_MOVE)
  Screen.draw()
end

-- the mouse over a problem row selects it (true = draw again)
function CE.problem_hover(id)
  local n = tonumber(string.match(id, "^prob(%d+)$") or "")
  local rows = Rows()
  if n == nil or rows[n] == nil or rows[n].head or n == ui.psel then
    return false
  end
  ui.psel = n
  return true
end

-- the row under the tabs: the severity filters with their counts (L3 or a click)
function CE.draw_problem_filters()
  local d = Read()
  local y, h = G.TOOLS_Y, G.TOOLS_H
  for k, f in ipairs(PR.FILTERS) do
    local x = PR.CHIP_X + (k - 1) * PR.CHIP_STEP
    local sel = ui.pfilter == k
    local foc = sel or mouse.hot == "pchip" .. k
    Quad("Q0", SP(foc and "tool2_sel" or "tool2"), x, y, PR.CHIP_W, h)
    local n = 0
    for sev in pairs(f.sev) do
      n = n + d.n[sev]
    end
    -- the selected filter shows its key (L3 cycles them)
    local label = (sel and (K.L3 .. " ") or "") .. T(f.key, {n = n})
    Txt("TC", Cut(label, Fit(PR.CHIP_W - 24, 0.66)), x + PR.CHIP_W / 2, y + h / 2, 0.66)
    Hit(x, y, PR.CHIP_W, h, "pchip" .. k, function()
      if ui.pfilter ~= k then
        CE.problem_filter(k - ui.pfilter)
      end
    end)
  end
end

-- the severity icon at x (left), centred on cy
local function SevIcon(sev, x, cy, s)
  if sev == "info" then
    Quad("Q1", SP("pill_blue"), x, cy - s / 2, s, s)
    Txt("TC", "i", x + s / 2, cy, s / 44)
  else
    Quad("Q1", SP(sev == "error" and "warn_r" or "warn_a"), x, cy - s / 2, s, s)
  end
end

local function DrawHead(r, y, hot)
  local g = r.g
  local cy = y + PR.ROW_H / 2
  Quad("Q2", SP("row_head"), PR.X, y, PR.W, PR.ROW_H, hot and 0.85 or 1)
  local name = Cut(Literal(g.name), Fit(PR.W - 600, 0.82))
  Txt("TL", name, PR.X + 28, cy, 0.82)
  if g.version ~= "" then
    Txt("TL", "[CWG]v" .. Cut(Literal(g.version), 12) .. "[C]", PR.X + 28 + Units(name) * G.PX * 0.82 + 18, cy + 2, 0.6)
  end
  -- the group's counts at the right, errors first: icon, number
  local x = PR.X + PR.W - 24
  for _, sev in ipairs({"info", "warn", "error"}) do
    local n = g.n[sev]
    if n > 0 then
      local s = tostring(n)
      local w = Units(s) * G.PX * 0.76
      x = x - w
      Txt("TL", s, x, cy, 0.76)
      x = x - 36
      SevIcon(sev, x, cy, 28)
      x = x - 22
    end
  end
end

local function DrawItem(r, y, sel)
  local e = r.e
  local cy = y + PR.ROW_H / 2
  Quad("Q2", SP(sel and "lplate_sel" or "lplate"), PR.X, y, PR.W, PR.ROW_H)
  if sel then
    Quad("Q1", SP("arrow_g"), PR.X - 20, cy - 14, 18, 28)
  end
  SevIcon(e.sev, PR.X + 24, cy, 32)
  local where = Literal(e.where)
  local where_w = where ~= "" and math.min(560, Units(where) * G.PX * 0.6 + 20) or 0
  local tw = PR.W - 110 - where_w
  Txt("TL", (e.sev == "error" and "[CR]" or "[CB]") .. Cut(Literal(e.title), Fit(tw, 0.68)) .. "[C]", PR.X + 76, y + 18, 0.68)
  Txt("TL", "[CWG]" .. Cut("[" .. Literal(e.ty) .. "] " .. Literal(e.msg), Fit(tw, 0.54)) .. "[C]", PR.X + 76, y + 42, 0.54)
  if where ~= "" then
    Txt("TR", "[CN]" .. Cut(where, Fit(540, 0.6)) .. "[C]", PR.X + PR.W - 24, cy, 0.6)
  end
end

-- the empty state: one white plate (no problem at all, or none of the filter's kind)
local function DrawEmpty(d)
  local x, y, w = PR.X, G.LIST_Y, PR.W
  Quad("Q2", SP("white"), x, y, w, 200)
  if d.total == 0 then
    Quad("Q1", SP("pill_green"), x + 30, y + 30, 56, 56)
    Txt("TL", "[CN]" .. Cut(T("pr_empty_title"), Fit(w - 160, 1.0)) .. "[C]", x + 110, y + 58, 1.0)
    Txt("TL", "[CWG]" .. Cut(T("pr_empty_desc", {n = cnt.mods or 0}), Fit(w - 160, 0.7)) .. "[C]", x + 110, y + 110, 0.7)
  else
    Txt("TL", "[CN]" .. Cut(T("pr_empty_filter"), Fit(w - 80, 0.9)) .. "[C]", x + 30, y + 58, 0.9)
  end
end

function CE.draw_problems()
  local d = Read()
  local rows = Rows()
  CE.round_box("Q0", "navy", "disc_navy", G.BOX_X, G.BOX_Y, PR.SB_X + 18 - G.BOX_X, G.BOX_BOTTOM - G.BOX_Y, G.BOX_R)
  if #rows == 0 then
    DrawEmpty(d)
    return
  end
  local vis = CE.PROBLEM_ROWS
  local s = Selected(rows)
  ui.ptop = CE.headed_top(ui.ptop, s, vis, #rows)
  for i = 1, math.min(vis, #rows - ui.ptop) do
    local n = ui.ptop + i
    local r = rows[n]
    local y = G.LIST_Y + (i - 1) * PR.STEP
    local hid = "prob" .. n
    if r.head then
      DrawHead(r, y, mouse.on and mouse.hot == hid)
      Hit(PR.X, y, PR.W, PR.ROW_H, hid, function()
        -- a header: the group's first problem, then its mod's page
        ui.psel = n + 1
        CE.problem_open()
      end)
    else
      DrawItem(r, y, n == s and ui.popup == nil)
      Hit(PR.X, y, PR.W, PR.ROW_H, hid, function()
        ui.psel = n
        CE.problem_open()
      end)
    end
  end
  DrawScrollbar(#rows, ui.ptop, vis, PR.SB_X, G.LIST_Y, vis * PR.STEP - (PR.STEP - PR.ROW_H), function(f)
    -- the bar moves the page and the selection with it (the first problem shown)
    ui.ptop = f
    local k = f + 1
    if rows[k] ~= nil and rows[k].head then
      k = k + 1
    end
    ui.psel = k
  end)
  if d.more then
    Txt("TR", "[CWG]" .. Cut(T("pr_more", {n = PR.MAX}), Fit(700, 0.56)) .. "[C]", PR.X + PR.W, G.BOX_BOTTOM - 4, 0.56)
  end
end
