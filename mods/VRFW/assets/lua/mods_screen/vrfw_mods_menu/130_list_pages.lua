local Screen = VRFW.mods_screen
if Screen == nil then
  return
end
local C, CE, Call, Cut, Draw, DrawPanel = Screen.C, Screen.CE, Screen.call, Screen.cut, Screen.draw, Screen.draw_panel
local DrawScrollbar, Fit, G, Hit, Int = Screen.draw_scrollbar, Screen.fit, Screen.G, Screen.hit, Screen.int
local Keyboard, M, ModById, Quad, RT_SEARCH = Screen.keyboard, Screen.M, Screen.mod_by_id, Screen.quad, Screen.RT_SEARCH
local RV, SE_NG, SP, Str, T, Txt = Screen.RV, Screen.SE_NG, Screen.SP, Screen.str, Screen.T, Screen.txt
local mouse, ui = Screen.mouse, Screen.ui
local Literal = Screen.literal

local function WaitPage(p)
  p.pick, p.back, p.act = nil, false, nil
  ui.page = p
  Draw()
  while p.pick == nil and not p.back and p.act == nil do
    coroutine.yield()
  end
  return p.pick, p.back, p.act
end

local function ListPage(title, help, items, opt)
  opt = opt or {}
  local p = {kind = "list", title = title, help = help, items = items, sel = opt.sel or 1, top = 1, search = opt.search,
             query = opt.query or "", total = opt.total, preview = opt.preview, zone = "list", info = opt.info}
  opt.p = p
  while true do
    local pick, back, act = WaitPage(p)
    if back then
      return nil
    end
    if act == "search" and p.search ~= nil then
      local q = Keyboard(p.query, "kb_search", RT_SEARCH, 24)
      if q ~= nil then
        p.query = q
        p.items, p.total = p.search(q)
        p.sel, p.top = 1, 1
      end
    elseif pick ~= nil then
      local it = p.items[pick]
      if it ~= nil and not it.off then
        return pick, it
      end
      funcLuaCommand(C.SE, SE_NG)
    end
  end
end

local function DrawList(p)
  local LW = G.ROW_W
  local rows = G.LIST_ROWS
  local y0 = G.LIST_Y              -- its search is in the top row (CE.draw_page_row)
  p.sel = math.max(1, math.min(p.sel, math.max(1, #p.items)))
  if p.sel < p.top then
    p.top = p.sel
  elseif p.sel >= p.top + rows then
    p.top = p.sel - rows + 1
  end
  p.top = math.max(1, math.min(p.top, math.max(1, #p.items - rows + 1)))
  CE.list_box()
  if #p.items == 0 then
    Quad("Q2", SP("row_off"), G.LIST_X, y0, LW, G.ROW_H)
    Txt("TL", "[CWG]" .. T("list_empty") .. "[C]", G.LIST_X + 28, y0 + G.ROW_H / 2, 0.85)
  end
  for k = 0, rows - 1 do
    local n = p.top + k
    local it = p.items[n]
    if it ~= nil then
      local y = y0 + k * G.ROW_STEP
      local sel = n == p.sel and p.zone == "list"
      if it.head then
        Quad("Q2", SP("row_head"), G.LIST_X, y, LW, G.ROW_H)
        Txt("TL", Cut(it.label, math.min(64, Fit(LW - 56, 0.8))), G.LIST_X + 28, y + G.ROW_H / 2, 0.8)
      else
        Quad("Q2", SP(sel and "row_sel" or (it.off and "row_off" or "row")), G.LIST_X, y, LW, G.ROW_H)
        if sel then
          CE.focus("Q1", G.LIST_X, y, LW, G.ROW_H, 3)   -- the cursor of every list
        end
        local lx = G.LIST_X + 28
        Txt("TL", (it.off and "[CWG]" or "[CB]") .. Cut(it.label, math.min(it.sub and 44 or 64, Fit(LW - (lx - G.LIST_X) - (it.sub and 230 or 30), 0.84))) .. "[C]", lx, y + G.ROW_H / 2, 0.84)
        if it.sub ~= nil and it.sub ~= "" then
          Txt("TR", "[CWG]" .. Cut(it.sub, 30) .. "[C]", G.LIST_X + LW - 24, y + G.ROW_H / 2, 0.72)
        end
        Hit(G.LIST_X, y, LW, G.ROW_H, "prow" .. n, function() p.sel = n p.zone = "list" p.pick = n end)
      end
    end
  end
  DrawScrollbar(#p.items, p.top - 1, rows, G.SB_X, y0, rows * G.ROW_STEP - (G.ROW_STEP - G.ROW_H), function(f)
    p.top = f + 1
    p.sel = math.max(p.top, math.min(p.sel, p.top + rows - 1))
  end)
  -- the panel: help + preview of the selected entry
  local lines = {{t = p.help or "", c = "[CWG]", max = 4}, {gap = 10}}
  local it = p.items[p.sel]
  if it ~= nil and p.preview ~= nil then
    for _, l in ipairs(p.preview(it)) do
      lines[#lines + 1] = l
    end
  end
  if p.info ~= nil then
    for _, l in ipairs(p.info) do
      lines[#lines + 1] = l
    end
  end
  DrawPanel(p.title, lines)
end

local function DrawPage()
  DrawList(ui.page)
end

function RV.who_items(id)
  local items, places = {}, 0
  if id == nil or id == "" then
    return items, 0, ""
  end
  local n, win = Call(M.REPORT_WHO, id)
  n, win = Int(n), Str(win)
  local last, rep = nil, false
  for i = 0, n - 1 do
    local mid, order, ty, place, text, kind, wins = Call(M.REPORT_WHO_ROW, i)
    mid, kind = Str(mid), Str(kind)
    if kind == "report" and not rep then
      rep, last = true, nil
      items[#items + 1] = {head = true, label = T("who_report")}
    end
    if mid ~= last and kind ~= "report" then
      last = mid
      local m = ModById(mid)
      local name = Literal((m ~= nil and m.name ~= nil and m.name ~= "") and m.name or mid)
      local pos = Int(order) > 0 and T("who_order", {n = Int(order)}) or T("who_not_loaded")
      items[#items + 1] = {head = true, label = (mid == win and "[CY]" or "") .. name .. "  ·  " .. pos ..
                           (mid == win and ("  ·  " .. T("rp_winner", {w = name})) or "") .. (mid == win and "[C]" or "")}
    end
    places = places + (kind == "report" and 0 or 1)
    local shown_text, shown_place = Literal(Str(text)), Literal(Str(place))
    items[#items + 1] = {label = "[" .. Literal(Str(ty)) .. "] " .. shown_text, sub = shown_place, off = kind == "refers",
                         full = shown_text, place = shown_place, mod = mid, kind = kind, win = wins == true}
  end
  return items, places, win
end

-- The explorer's list page; B returns to the mod page on the view it came from.
function RV.who_flow(id)
  local saved = ui.popup
  ui.popup = nil
  local opt = {query = id or ""}
  local function fill(q)
    local items, places, win = RV.who_items(q)
    local info = {{gap = 10}, {t = q == "" and T("who_empty") or (win ~= "" and T("who_winner", {w = Literal(win)}) or
                  (places > 0 and T("who_no_winner") or T("who_nobody", {i = Literal(q)}))), c = "[CN]", max = 3}}
    opt.info = info
    if opt.p ~= nil then
      opt.p.info = info
    end
    return items, places
  end
  local items
  items, opt.total = fill(opt.query)
  opt.search = fill
  opt.preview = function(it)
    if it.head then
      return {}
    end
    return {{t = it.place or "", c = "[CWG]", max = 2}, {t = it.full or "", c = "[CB]", max = 5},
            {t = T("who_kind_" .. (it.kind or "defines")), c = "[CWG]", max = 2}}
  end
  while true do
    local k = ListPage(T("who_title"), T("who_help"), items, opt)
    if k == nil then
      break
    end
    -- a row picked: nothing to do on it; the list stays (its search, its cursor)
    items, opt.query, opt.total, opt.sel = opt.p.items, opt.p.query, opt.p.total, opt.p.sel
  end
  ui.page = nil
  ui.popup = saved
  Draw()
end

-- a mod's vertical offset (px) of the screen's top block, applied at the next layout
function Screen.set_top_offset(dy)
  Screen.top_offset = tonumber(dy) or 0
end

function CE.apply_layout()
  if G.BASE_Y == nil then
    G.BASE_Y = {}
    for _, k in ipairs(G.SHIFT_Y) do
      G.BASE_Y[k] = G[k]
    end
  end
  local dy = math.max(-160, math.min(160, Screen.top_offset or 0))
  for _, k in ipairs(G.SHIFT_Y) do
    G[k] = G.BASE_Y[k] + dy
  end
  -- the rows that fit between the list's top and the box's bottom (fixed: the button guide does not move)
  G.LIST_ROWS = math.max(4, math.floor((G.BOX_BOTTOM - G.BOX_PAD - G.LIST_Y + (G.ROW_STEP - G.ROW_H)) / G.ROW_STEP))
  G.TOP_DY = dy
  return dy
end

-- the search of a list page for CE.row_search, or nil (none)
function CE.page_search(p)
  if p.search == nil then
    return nil
  end
  local id = "psearch"
  return {on = true, query = p.query, hint = "search_hint_list", count = T("list_count", {n = #p.items, t = p.total or #p.items}),
          foc = p.zone == "search" or mouse.hot == id, id = id, act = function() p.act = "search" end}
end

-- the page's own part of the top row: its search box (the count inside), in the place of the "Installed" search
function CE.draw_page_row(p)
  local s = CE.page_search(p)
  if s ~= nil then
    CE.row_search(s)
  end
end

-- for 100_mods_screen.lua and the files after this one
Screen.draw_page = DrawPage
