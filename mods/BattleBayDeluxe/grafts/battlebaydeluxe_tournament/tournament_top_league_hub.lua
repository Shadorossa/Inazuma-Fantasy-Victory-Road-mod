-- Top menu part
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}


-- League career hub constants.
BattleBayDeluxe.tournament.HUB = {
  PAGE = 9,                     -- scripts/lib/tourney_view.lua V.HUB
  -- Action of Enter on side menu row k
  NAV = { "dashboard", "calendar", "competition", "roster", "new", "exit" },
  P_NAV = @crc:battlebaydeluxe_lg_nav@,
  -- Parameter ids of the hub focus and function keys.
  P_FOCUS = @crc:battlebaydeluxe_lg_focus@,
  FN_UP = @crc:battlebaydeluxe_lg_up@,
  FN_DOWN = @crc:battlebaydeluxe_lg_down@,
  FN_LEFT = @crc:battlebaydeluxe_lg_left@,
  FN_RIGHT = @crc:battlebaydeluxe_lg_right@,
  -- Dashboard panels in DrawHub order
  PANELS = {
    { act = "play", right = 2, down = 3, left = 0 },              -- next match
    { act = "competition", left = 1, down = 5 },                  -- standings
    { act = "scorers", up = 1, right = 4, down = 6, left = 0 },   -- top scorers
    { act = "results", up = 1, left = 3, right = 5, down = 6 },   -- last results
    { act = "roster", up = 2, left = 4, down = 6 },               -- squad
    { act = "calendar", up = 4, left = 0 },                       -- calendar
  },
  SCORERS_PAGE = 19,            -- scripts/lib/tourney_view.lua V.SCORERS
  CALENDAR_PAGE = 100, CAL_HALVES = 2,   -- V.CALENDAR, V.CAL_HALVES
  -- Parameter ids of the calendar.
  P_CAL_MD = @crc:battlebaydeluxe_lg_cal_md@,
  FIXTURES_FIRST = 90,          -- V.FIXTURES: the grid's first page
  -- The anchor's left-click row
  FN_CLICK = @crc:battlebaydeluxe_lg_click@,
  -- Y or a click on the next match's second button simulates the match.
  FN_SIM = @crc:battlebaydeluxe_lg_sim@,
  SIM = @crc:CMND_BATTLEBAYDELUXE_TOURNAMENT_SIM@,
  GUIDE = @crc:mainmenu01_06_base_button_guide@,
  SQUAD_PAGE = 8,               -- scripts/lib/tourney_view.lua V.SQUAD
  -- The league team in the game's team dock (BattleBayDeluxe.tournament_hub_team_editor).
  SQUAD_GET = @crc:CMND_BATTLEBAYDELUXE_LEAGUE_SQUAD@,
  SQUAD_SET = @crc:CMND_BATTLEBAYDELUXE_LEAGUE_SQUAD_SET@,
  TEAM_INFO = 2151743654,       -- (team, 2) -> _, the team's name
}

function BattleBayDeluxe.tournament_hub_team_editor()
  local H = BattleBayDeluxe.tournament.HUB
  if type(VRFW.team_editor) ~= "table" then
    BattleBayDeluxe.tournament_log("hub: no VRFW.team_editor (VRFW < 2.226.0): the squad page")
    return false
  end
  local sq = BattleBayDeluxe.tournament_call(H.SQUAD_GET)
  if type(sq) ~= "table" or not sq.ok then
    BattleBayDeluxe.tournament_log("hub: league squad not read:", type(sq) == "table" and tostring(sq.why) or "no answer")
    return false
  end
  if sq.kind == "draft" then
    BattleBayDeluxe.tournament_log("hub: the Draft team keeps its drafted order: the squad page")
    return false
  end
  if sq.kind ~= "own" then
    local can, why = VRFW.team_editor.can_open()
    if not can then
      BattleBayDeluxe.tournament_log("hub: team editor refused:", why)
      return false
    end
  end
  local _, name = VRFW.host.command(H.TEAM_INFO, sq.team, 2)
  BattleBayDeluxe.tournament_close()
  -- The top menu's own layers stay closed / hidden under the dock as under the overlay
  BattleBayDeluxe.tournament_switch_layers(BattleBayDeluxe.tournament_host.close, false)
  BattleBayDeluxe.tournament_show_layers(BattleBayDeluxe.tournament_host.hide, false)
  BattleBayDeluxe.tournament_bg_logo(false)
  for _, l in ipairs(BattleBayDeluxe.tournament_host.lists or {}) do
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, l, false)
  end
  -- No hub band under the dock (the editor gives it the retail background)
  local own = sq.kind == "own"
  local res, why = VRFW.team_editor.run({
    owner = "BattleBayDeluxe", host = BattleBayDeluxe.tournament_host.menu, own = own, foreign = not own, members = sq.members,
    formation = sq.formation, level = sq.level, emblem = sq.emblem, name = type(name) == "string" and name or nil,
    coach = sq.coach, kit = sq.kit, tactics = sq.tactics, synergies = sq.synergies, stadium = sq.stadium,
    -- The list offers the lineup, synergy links and hyper technique commands.
    rows = (VRFW.team_editor.ROW ~= nil) and { VRFW.team_editor.ROW.LINEUP, VRFW.team_editor.ROW.BONDS,
      VRFW.team_editor.ROW.HYPER_COMMANDS } or nil,
  })
  -- Card ids are unsigned 32-bit, past this Lua's "%d" range
  local okw, saved = pcall(function()
    if res and not res.own then
      local parts = {}
      for _, m in ipairs(res.members or {}) do
        parts[#parts + 1] = string.format("%.0f:%.0f", m[1], m[2])
      end
      local r = BattleBayDeluxe.tournament_call(H.SQUAD_SET, res.formation or 0, table.concat(parts, ","))
      local kept = type(r) == "table" and r.ok == true
      BattleBayDeluxe.tournament_log("hub: league lineup from the dock:", #parts, "players,", res.foreign or 0, "club players, kept",
        tostring(kept), type(r) == "table" and tostring(r.why or "") or "no answer")
      return kept
    elseif not res then
      BattleBayDeluxe.tournament_log("hub: team editor:", tostring(why))
    end
    return true
  end)
  if not okw then
    BattleBayDeluxe.tournament_log("hub: league lineup not kept:", tostring(saved))
    saved = false
  end
  for _, l in ipairs(BattleBayDeluxe.tournament_host.lists or {}) do
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, l, true)
  end
  BattleBayDeluxe.tournament_open(H.PAGE)
  if not saved and BattleBayDeluxe.tournament_state.open then
    BattleBayDeluxe.tournament_window(BattleBayDeluxe.tournament_id("squad_not_saved"), 1)
  end
  return true
end

-- Sends the side menu cursor and dashboard focus to the drawing menu.
function BattleBayDeluxe.tournament_hub_nav_param()
  VRFW.param.clear(BattleBayDeluxe.tournament.HUB.P_NAV)
  VRFW.param.set(BattleBayDeluxe.tournament.HUB.P_NAV, BattleBayDeluxe.tournament_state.hub_nav or 0)
  VRFW.param.clear(BattleBayDeluxe.tournament.HUB.P_FOCUS)
  VRFW.param.set(BattleBayDeluxe.tournament.HUB.P_FOCUS, BattleBayDeluxe.tournament_state.hub_focus or 0)
end

-- Focuses dashboard panel k (0 = the side menu) and redraws
function BattleBayDeluxe.tournament_hub_focus(k, silent)
  BattleBayDeluxe.tournament_state.hub_focus = (k or 0) > 0 and k or nil
  BattleBayDeluxe.tournament_hub_nav_param()
  if not silent then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0001@)
  end
  BattleBayDeluxe.tournament_groups_show(BattleBayDeluxe.tournament.HUB.PAGE)
end

-- Moves the side menu cursor by d (wraps) and redraws
function BattleBayDeluxe.tournament_hub_move(d, silent)
  local n = #BattleBayDeluxe.tournament.HUB.NAV
  BattleBayDeluxe.tournament_state.hub_nav = ((BattleBayDeluxe.tournament_state.hub_nav or 0) + d) % n
  BattleBayDeluxe.tournament_hub_nav_param()
  if not silent then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0001@)
  end
  BattleBayDeluxe.tournament_groups_show(BattleBayDeluxe.tournament.HUB.PAGE)
end

--@lib vrfw_menu_kit.lua#Pointer

-- Pointer zones sent by the drawing menu after each hub drawing (called by name, cross-menu)
function BattleBayDeluxeTournamentHubZones(s)
  local zones = {}
  for kind, n, x0, y0, x1, y1 in tostring(s or ""):gmatch("(%a),(%d+),([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)") do
    zones[#zones + 1] = { tonumber(x0), tonumber(y0), tonumber(x1), tonumber(y1),
      nav = kind == "n" and tonumber(n) or nil, panel = kind == "p" and tonumber(n) or nil,
      md = kind == "c" and tonumber(n) or nil }
    -- Handles the zone kind "s" (format "s,0,...").
    if kind == "s" then
      zones[#zones].panel, zones[#zones].sim = 1, true
    end
  end
  BattleBayDeluxe.tournament_state.hub_zones = zones
end

-- Focuses zone z as the keys would (side menu row, dashboard panel or calendar card)
function BattleBayDeluxe.tournament_hub_point_to(z, silent)
  if z.md ~= nil then
    BattleBayDeluxe.tournament_hub_calendar_focus(z.md, silent)
  elseif z.panel ~= nil then
    if BattleBayDeluxe.tournament_state.hub_focus ~= z.panel then
      BattleBayDeluxe.tournament_hub_focus(z.panel, silent)
    end
  elseif BattleBayDeluxe.tournament_state.hub_focus ~= nil or (BattleBayDeluxe.tournament_state.hub_nav or 0) ~= z.nav then
    BattleBayDeluxe.tournament_state.hub_focus = nil
    BattleBayDeluxe.tournament_hub_move(z.nav - (BattleBayDeluxe.tournament_state.hub_nav or 0), silent)
  end
end

-- Every Step while the dashboard or calendar grid waits
function BattleBayDeluxe.tournament_hub_pointer_step()
  local S = BattleBayDeluxe.tournament_state
  local grid = S.cal_wait == true and S.cal_act == nil
  if not (S.open and ((S.hub_wait and S.hub_act == nil) or grid)) or S.hub_zones == nil then
    S.hub_ptr_idle = true
    return
  end
  local P = S.hub_ptr
  if P == nil then
    P = VRFW.pointer.new()
    S.hub_ptr = P
    S.hub_ptr_idle = true
  end
  if S.hub_ptr_idle then
    S.hub_ptr_idle = false
    P.reset()
  end
  P.begin()
  for k, z in ipairs(S.hub_zones) do
    P.rect(z[1], z[2], z[3] - z[1], z[4] - z[2], k)
  end
  local ev = P.poll()
  if grid and ev.wheel ~= nil then
    BattleBayDeluxe.tournament_hub_calendar_turn(ev.wheel)
    return
  end
  local k = ev.click or ev.hover
  local z = k and S.hub_zones[k]
  if z == nil or (grid and z.md == nil) or (not grid and z.md ~= nil) then
    return
  end
  BattleBayDeluxe.tournament_hub_point_to(z, ev.click ~= nil)
  if ev.click ~= nil then
    if grid then
      S.cal_act = "open"
    else
      S.hub_act = (z.sim and "sim") or (z.panel ~= nil and BattleBayDeluxe.tournament.HUB.PANELS[z.panel].act) or BattleBayDeluxe.tournament.HUB.NAV[z.nav + 1]
    end
  end
end

-- The hub's key events (OnDecideFocus / OnBack / OnFunction while it waits)
function BattleBayDeluxe.tournament_hub_key(kind, fn)
  if not BattleBayDeluxe.tournament_state.hub_wait then
    return false
  end
  local H = BattleBayDeluxe.tournament.HUB
  local P = BattleBayDeluxe.tournament_state.hub_ptr
  -- The left-click row and a pointer-click Accept belong to BattleBayDeluxe.tournament_hub_pointer_step.
  if fn == H.FN_CLICK or (kind == "enter" and P ~= nil and P.owns()) then
    return true
  end
  -- A key moves the focus
  if P ~= nil and kind == "function" then
    P.key_step()
  end
  if fn == H.FN_SIM then
    BattleBayDeluxe.tournament_state.hub_act = "sim"
    return true
  end
  -- Returns the panel that has the focus inside the dashboard.
  local p = BattleBayDeluxe.tournament_state.hub_focus and H.PANELS[BattleBayDeluxe.tournament_state.hub_focus]
  if p then
    if kind == "enter" then
      BattleBayDeluxe.tournament_state.hub_act = p.act
    elseif kind == "back" then
      BattleBayDeluxe.tournament_hub_focus(0)
    else
      local dir = (fn == H.FN_UP and "up") or (fn == H.FN_DOWN and "down") or (fn == H.FN_LEFT and "left")
        or (fn == H.FN_RIGHT and "right") or nil
      local to = dir and p[dir]
      if to ~= nil then
        BattleBayDeluxe.tournament_hub_focus(to)
      end
    end
    return true
  end
  if kind == "enter" then
    BattleBayDeluxe.tournament_state.hub_act = H.NAV[(BattleBayDeluxe.tournament_state.hub_nav or 0) + 1]
  elseif kind == "back" then
    BattleBayDeluxe.tournament_state.hub_act = "exit"
  elseif fn == H.FN_RIGHT and (BattleBayDeluxe.tournament_state.hub_nav or 0) == 0 then
    BattleBayDeluxe.tournament_hub_focus(1)
  elseif fn == H.FN_UP or fn == BattleBayDeluxe.tournament.FN_PREV then
    BattleBayDeluxe.tournament_hub_move(-1)
  elseif fn == H.FN_DOWN or fn == BattleBayDeluxe.tournament.FN_NEXT then
    BattleBayDeluxe.tournament_hub_move(1)
  end
  return true
end

-- Footer while the dashboard waits
function BattleBayDeluxe.tournament_hub_guide(on)
  if BattleBayDeluxe.tournament_host.name ~= "bb_stadium_top_menu" then
    return
  end
  if not on then
    pcall(BattleBayDeluxe.tournament_host.guide, true)
    return
  end
  local G = BattleBayDeluxe.tournament.HUB.GUIDE
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, G, 0, true)
  VRFW.footer_prompts.set(BattleBayDeluxe.tournament_host.name, BattleBayDeluxe.tournament_host.menu, {
    {text = 1847312674 --[[Accept]], icon = 2750714971 --[[<CMD_ENTER>]], command = @crc:CMD_ENTER@, offset = 0},
    {text = BattleBayDeluxe.tournament_id("hub_sim"), icon = BattleBayDeluxe.tournament_id("key_sim"), command = @crc:CMD_FUNC3@, offset = 0},
    {text = BattleBayDeluxe.tournament_id("hub_exit"), icon = BattleBayDeluxe.tournament_id("key_back"), command = @crc:CMD_BACK@, offset = 0},
  }, {guide = G, declared = false})
end

-- Next dashboard action ("play" | "calendar" | "competition" | "roster" | "new" | "exit")
function BattleBayDeluxe.tournament_hub_wait()
  BattleBayDeluxe.tournament_state.hub_act = nil
  BattleBayDeluxe.tournament_state.hub_wait = true
  while BattleBayDeluxe.tournament_state.hub_act == nil and BattleBayDeluxe.tournament_state.open do
    coroutine.yield()
  end
  BattleBayDeluxe.tournament_state.hub_wait = nil
  local a = BattleBayDeluxe.tournament_state.hub_act or "exit"
  BattleBayDeluxe.tournament_state.hub_act = nil
  return a
end

-- A section's pages until Enter / Back (they clear BattleBayDeluxe.tournament_state.section).
function BattleBayDeluxe.tournament_hub_section(page)
  BattleBayDeluxe.tournament_draw(page)
  BattleBayDeluxe.tournament_state.section = true
  while BattleBayDeluxe.tournament_state.section and BattleBayDeluxe.tournament_state.open do
    coroutine.yield()
  end
  BattleBayDeluxe.tournament_state.section = nil
end

-- Calendar page of the last matchday played
function BattleBayDeluxe.tournament_hub_results_page(v)
  local played = tonumber(v.played) or 0
  if played < 1 then
    return nil
  end
  return BattleBayDeluxe.tournament.HUB.CALENDAR_PAGE + (played - 1) * BattleBayDeluxe.tournament.HUB.CAL_HALVES
end

-- Shows the calendar section.

-- Redraws the grid.
function BattleBayDeluxe.tournament_hub_calendar_show(silent)
  local S = BattleBayDeluxe.tournament_state
  local v = S.view or {}
  local page = BattleBayDeluxe.tournament.HUB.FIXTURES_FIRST + math.floor((S.cal_md - 1) / math.max(1, S.cal_per))
  VRFW.param.clear(BattleBayDeluxe.tournament.HUB.P_CAL_MD)
  VRFW.param.set(BattleBayDeluxe.tournament.HUB.P_CAL_MD, S.cal_md)
  if not silent then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0001@)
  end
  if v.kind == "fixtures" and v.page == page then
    BattleBayDeluxe.tournament_groups_show(page)
  else
    BattleBayDeluxe.tournament_draw(page)
  end
end

-- Focuses matchday md (clamped to the league's matchdays).
function BattleBayDeluxe.tournament_hub_calendar_focus(md, silent)
  local S = BattleBayDeluxe.tournament_state
  md = math.max(1, math.min(S.cal_mds, md))
  if md ~= S.cal_md then
    S.cal_md = md
    BattleBayDeluxe.tournament_hub_calendar_show(silent)
  end
end

-- The grid's key events while it waits
function BattleBayDeluxe.tournament_hub_calendar_key(kind, fn)
  local S = BattleBayDeluxe.tournament_state
  if not S.cal_wait then
    return false
  end
  local H = BattleBayDeluxe.tournament.HUB
  local P = S.hub_ptr
  if fn == H.FN_CLICK or (kind == "enter" and P ~= nil and P.owns()) then
    return true
  end
  if P ~= nil and kind == "function" then
    P.key_step()
  end
  if kind == "enter" then
    S.cal_act = "open"
  elseif kind == "back" then
    S.cal_act = "back"
  elseif fn == H.FN_LEFT then
    BattleBayDeluxe.tournament_hub_calendar_focus(S.cal_md - 1)
  elseif fn == H.FN_RIGHT then
    BattleBayDeluxe.tournament_hub_calendar_focus(S.cal_md + 1)
  elseif fn == H.FN_UP or fn == H.FN_DOWN then
    -- Moves the calendar one row up or down.
    local to = S.cal_md + (fn == H.FN_UP and -S.cal_cols or S.cal_cols)
    if to >= 1 and to <= S.cal_mds then
      BattleBayDeluxe.tournament_hub_calendar_focus(to)
    end
  elseif fn == BattleBayDeluxe.tournament.FN_PREV or fn == BattleBayDeluxe.tournament.FN_NEXT then
    BattleBayDeluxe.tournament_hub_calendar_turn(fn == BattleBayDeluxe.tournament.FN_NEXT and 1 or -1)
  end
  return true
end

-- Turns the grid page by d (wraps), keeping the focus position (the last card when shorter).
function BattleBayDeluxe.tournament_hub_calendar_turn(d)
  local S = BattleBayDeluxe.tournament_state
  local pages = math.max(1, math.ceil(S.cal_mds / S.cal_per))
  if pages < 2 then
    return
  end
  local p = math.floor((S.cal_md - 1) / S.cal_per)
  local slot = (S.cal_md - 1) % S.cal_per
  local np = (p + d) % pages
  S.cal_md = math.min(S.cal_mds, np * S.cal_per + slot + 1)
  BattleBayDeluxe.tournament_hub_calendar_show()
end

-- The grid until Back (in the hub coroutine)
function BattleBayDeluxe.tournament_hub_calendar(v)
  local S = BattleBayDeluxe.tournament_state
  local H = BattleBayDeluxe.tournament.HUB
  local first = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.VIEW, v.fixtures_page or H.FIXTURES_FIRST)
  if type(first) ~= "table" or first.kind ~= "fixtures" then
    -- No grid in the view
    BattleBayDeluxe.tournament_hub_section(v.calendar_page or H.CALENDAR_PAGE)
    return
  end
  S.cal_mds = math.max(1, tonumber(first.mds) or 1)
  S.cal_cols = math.max(1, tonumber(first.cols) or 1)
  S.cal_per = math.max(1, tonumber(first.per) or S.cal_mds)
  S.cal_md = math.max(1, math.min(S.cal_mds, tonumber(v.fixtures_md) or 1))
  BattleBayDeluxe.tournament_hub_calendar_show(true)
  while BattleBayDeluxe.tournament_state.open do
    S.cal_act = nil
    S.cal_wait = true
    while S.cal_act == nil and BattleBayDeluxe.tournament_state.open do
      coroutine.yield()
    end
    S.cal_wait = nil
    local a = S.cal_act
    S.cal_act = nil
    if a ~= "open" then
      break
    end
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
    BattleBayDeluxe.tournament_hub_section(H.CALENDAR_PAGE + (S.cal_md - 1) * H.CAL_HALVES)
    if not BattleBayDeluxe.tournament_state.open then
      break
    end
    -- Back on the grid, on the matchday the inner pages were turned to.
    local pg = tonumber(BattleBayDeluxe.tournament_state.page) or 0
    if pg >= H.CALENDAR_PAGE then
      S.cal_md = math.max(1, math.min(S.cal_mds, math.floor((pg - H.CALENDAR_PAGE) / H.CAL_HALVES) + 1))
    end
    BattleBayDeluxe.tournament_state.view = nil
    BattleBayDeluxe.tournament_hub_calendar_show(true)
  end
  if BattleBayDeluxe.tournament_state.open then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@)
  end
  S.cal_wait, S.cal_act = nil, nil
end

-- Hub loop, in a coroutine (BattleBayDeluxe.tournament_state.co or the entry's decide coroutine).
function BattleBayDeluxe.tournament_league_hub()
  BattleBayDeluxe.tournament_state.hub = true
  local H = BattleBayDeluxe.tournament.HUB
  BattleBayDeluxe.tournament_state.hub_nav = BattleBayDeluxe.tournament_state.hub_nav or 0
  BattleBayDeluxe.tournament_state.hub_focus = nil
  while true do
    local info = BattleBayDeluxe.tournament_info()
    if not info.active or info.fmt ~= 2 then
      break
    end
    BattleBayDeluxe.tournament_hub_nav_param()
    if BattleBayDeluxe.tournament_state.open then
      BattleBayDeluxe.tournament_draw(H.PAGE)
    else
      BattleBayDeluxe.tournament_open(H.PAGE)
    end
    if not BattleBayDeluxe.tournament_state.open then
      break
    end
    BattleBayDeluxe.tournament_hub_guide(true)
    local what = BattleBayDeluxe.tournament_hub_wait()
    BattleBayDeluxe.tournament_hub_guide(false)
    BattleBayDeluxe.tournament_log("hub:", what, "side menu row", BattleBayDeluxe.tournament_state.hub_nav)
    local v = BattleBayDeluxe.tournament_state.view or {}
    if what == "dashboard" then
      -- Handles the Home action.
      BattleBayDeluxe.tournament_hub_focus(1)
    elseif what == "scorers" then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      BattleBayDeluxe.tournament_hub_section(H.SCORERS_PAGE)
      if not BattleBayDeluxe.tournament_state.open then
        break
      end
    elseif what == "results" then
      -- The last matchday played, or the next one when none.
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      BattleBayDeluxe.tournament_hub_section(BattleBayDeluxe.tournament_hub_results_page(v) or v.calendar_page or H.CALENDAR_PAGE)
      if not BattleBayDeluxe.tournament_state.open then
        break
      end
    elseif what == "play" then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      BattleBayDeluxe.tournament_state.hub = nil
      BattleBayDeluxe.tournament_play_next()
      if not BattleBayDeluxe.tournament_state.open then
        return
      end
      BattleBayDeluxe.tournament_state.hub = true
    elseif what == "sim" then
      local r = BattleBayDeluxe.tournament_call(H.SIM)
      if type(r) == "table" and r.ok then
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
        BattleBayDeluxe.tournament_log("hub: match simulated:", r.gf, r.ga, r.event)
        -- Open the pages a played match opens on (results or champion screen)
        local S = BattleBayDeluxe.tournament_state
        S.hub, S.hub_focus = nil, nil
        BattleBayDeluxe.tournament_groups_hide()
        if not BattleBayDeluxe.tournament_draw(-1) then
          BattleBayDeluxe.tournament_close()
        end
        return
      end
      BattleBayDeluxe.tournament_log("hub: match not simulated:", type(r) == "table" and tostring(r.why) or "no answer")
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
    elseif what == "calendar" then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      BattleBayDeluxe.tournament_hub_calendar(v)
      if not BattleBayDeluxe.tournament_state.open then
        break
      end
    elseif what == "competition" then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      BattleBayDeluxe.tournament_hub_section(v.home_page or 10)
      if not BattleBayDeluxe.tournament_state.open then
        break
      end
    elseif what == "roster" then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      if not BattleBayDeluxe.tournament_hub_team_editor() then
        BattleBayDeluxe.tournament_hub_section(H.SQUAD_PAGE)
      end
      if not BattleBayDeluxe.tournament_state.open then
        break
      end
    elseif what == "new" then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      local a = BattleBayDeluxe.tournament_choose({ BattleBayDeluxe.tournament_id("new_yes"), BattleBayDeluxe.tournament_id("new_no") }, 1)
      if a == 0 then
        BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.ABANDON)
        VRFW.host.command(BattleBayDeluxe.tournament.RULE_SELECT, "")
        if BattleBayDeluxe.tournament_state.open then
          BattleBayDeluxe.tournament_close()
        end
        BattleBayDeluxe.tournament_state.hub = nil
        BattleBayDeluxe.tournament_log("hub: the running league abandoned, a new one")
        return BattleBayDeluxe.tournament_new_run(2)
      end
    else
      if BattleBayDeluxe.tournament_state.open then
        funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@)
        BattleBayDeluxe.tournament_close()
      end
      break
    end
  end
  BattleBayDeluxe.tournament_state.hub, BattleBayDeluxe.tournament_state.hub_wait, BattleBayDeluxe.tournament_state.hub_act, BattleBayDeluxe.tournament_state.hub_focus = nil, nil, nil, nil
end
