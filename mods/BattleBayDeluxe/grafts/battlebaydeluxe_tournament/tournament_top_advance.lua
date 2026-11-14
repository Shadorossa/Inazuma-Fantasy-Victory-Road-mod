-- Top menu part
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}

function BattleBayDeluxe.tournament_tree_show(page, animate)
  VRFW.bracket.show(page, { host = BattleBayDeluxe.tournament_host.menu, view = BattleBayDeluxe.tournament.VIEW,
    animate = animate == true })
end

function BattleBayDeluxe.tournament_tree_hide(why)
  VRFW.bracket.hide(why)
end

-- Round results, every match on one page as scoreboard rows
BattleBayDeluxe.tournament.RES = { GAP = 20, BOX_W = 64, BOX_W_PEN = 128, BOX_H = 0.74, PITCH_MAX = 84, FILL = 0.84, DIGIT_PRIO = 553 }
function BattleBayDeluxe.tournament_draw_results(v)
  local G, Rr = BattleBayDeluxe.tournament.G, BattleBayDeluxe.tournament.RES
  local rows = v.rows or {}
  local n = #rows
  if n == 0 then
    return
  end
  local pitch = math.min(Rr.PITCH_MAX, (G.BOTTOM - G.TOP) / n)
  local s = math.min(G.SCALE_MAX, pitch * Rr.FILL / G.PLATE_H)
  local top = (G.TOP + G.BOTTOM) / 2 - pitch * n / 2
  local pw = G.PLATE_W * s
  local bh = G.PLATE_H * s * Rr.BOX_H
  local scores = {}
  for t, r in ipairs(rows) do
    local y = top + pitch * (t - 0.5)
    local xa = G.CX - Rr.GAP / 2 - pw
    local xb = G.CX + Rr.GAP / 2
    if r.a and (r.a.team or 0) ~= 0 then
      BattleBayDeluxe.tournament_plate(r.a, xa, y, s, false, false)
    end
    if r.b and (r.b.team or 0) ~= 0 then
      BattleBayDeluxe.tournament_plate(r.b, xb, y, s, true, false)
    end
    -- Shows the league calendar and results.
    if v.fmt == "league" then
      if r.a and r.a.me then
        BattleBayDeluxe.tournament_focus(xa, y, s, false)
      elseif r.b and r.b.me then
        BattleBayDeluxe.tournament_focus(xb, y, s, true)
      end
    end
    scores[#scores + 1] = r.done and (BattleBayDeluxe.tournament_score({ ga = r.ga, gb = r.gb, pa = r.pa, pb = r.pb }) .. (r.et and "*" or ""))
      or "-"
    if r.done then
      for side = 1, 2 do
        local g = side == 1 and r.ga or r.gb
        local pk = side == 1 and r.pa or r.pb
        local txt = tostring(g or 0)
        local bw = Rr.BOX_W * s
        if (r.pa or 0) + (r.pb or 0) > 0 then
          txt = string.format("%d (%d)", g or 0, pk or 0)
          bw = Rr.BOX_W_PEN * s
        elseif r.et then
          txt = txt .. "*"
        end
        local look = "even"
        if r.w ~= 0 then
          look = r.w == side and "win" or "lose"
        end
        local bx = side == 1 and (G.CX - Rr.GAP / 2 - bw / 2 - 4) or (G.CX + Rr.GAP / 2 + bw / 2 + 4)
        -- Digit sprites (draw white, winner yellow-orange, loser light blue)
        local N = BattleBayDeluxe.tournament.NUM
        local style = look == "win" and "gold" or (look == "lose" and "blue" or "white")
        local h = bh * N.BOX_FILL
        local parts = VRFW.bracket.number_parts("bbd_tn_d_", {}, g or 0, style, h)
        if (r.pa or 0) + (r.pb or 0) > 0 then
          VRFW.bracket.number_parts("bbd_tn_d_", parts, pk or 0, style, h * N.PEN_S, true)
        elseif r.et then
          parts[#parts + 1] = { "bbd_tn_d_et", h * N.PEN_S }
        end
        BattleBayDeluxe.tournament_glyphs(parts, bx, y, Rr.DIGIT_PRIO)
      end
    end
  end
  -- Log the scores this page shows, once per draw.
  BattleBayDeluxe.tournament_log("results page: " .. #rows .. " match(es): " .. table.concat(scores, "  "))
end

-- Group and league tables are drawn on one page by the display-only child menu battlebaydeluxe_tn_groups_menu
BattleBayDeluxe.tournament.GM = {
  MENU = @crc:battlebaydeluxe_tn_groups_menu@,
  child = nil,
}

function BattleBayDeluxe.tournament_groups_child()
  local GM = BattleBayDeluxe.tournament.GM
  GM.child = GM.child or VRFW.child_menu.host(GM.MENU, { prefix = "battlebaydeluxe_tn_groups_", label = "groups menu",
    log = function(...) BattleBayDeluxe.tournament_log("groups menu:", ...) end })
  return GM.child
end

-- Shows the group page.
function BattleBayDeluxe.tournament_groups_show(page)
  BattleBayDeluxe.tournament_groups_child().show(page, BattleBayDeluxe.tournament_host.menu)
end

-- Closes the child menu (another page shown, or the overlay closed).
function BattleBayDeluxe.tournament_groups_hide()
  BattleBayDeluxe.tournament_groups_child().hide("the overlay left the group page")
end

-- Every Step of this host
function BattleBayDeluxe.tournament_groups_step()
  BattleBayDeluxe.tournament_groups_child().step()
end

function BattleBayDeluxe.tournament_title(v)
  local t = v.title or {}
  local key = t.key or ""
  if key == "md" or key == "groups" or key == "groups_md" then
    return BattleBayDeluxe.tournament_text_value(key, t.n or 0)
  end
  if v.kind == "league" or v.kind == "hub" or v.kind == "scorers" or v.kind == "squad" or v.kind == "fixtures"
    or v.calendar then
    -- League page titles carry the matchday
    local s = t.m and VRFW.bracket.text_value2(BattleBayDeluxe.tournament_text(key), t.n or 0, t.m) or ((t.n or 0) > 0 and BattleBayDeluxe.tournament_text_value(key, t.n) or BattleBayDeluxe.tournament_text(key))
    if (v.page_count or 1) > 1 then
      s = string.format("%s  (%d/%d)", s, v.page_n or 1, v.page_count)
    end
    return s
  end
  if key == "" then
    return BattleBayDeluxe.tournament_text("mode_tournament")
  end
  return BattleBayDeluxe.tournament_text(key)
end

-- Text key for the run's format
function BattleBayDeluxe.tournament_run_key(key, league)
  return league and (key .. "_league") or key
end

function BattleBayDeluxe.tournament_outcome(v)
  if v.outcome == "champion" then
    return BattleBayDeluxe.tournament_text(BattleBayDeluxe.tournament_run_key("champion", v.fmt == "league"))
  end
  if v.outcome == "out" and v.place and v.place.stage == "league" then
    return BattleBayDeluxe.tournament_text_value("out_league", v.place.pos or 0)
  end
  if v.outcome == "out" and v.place then
    if v.place.stage == "groups" then
      return BattleBayDeluxe.tournament_text("out_groups")
    end
    return BattleBayDeluxe.tournament_text("out_ko_" .. tostring(v.place.from_end or 1))
  end
  return ""
end

-- Champion screen, first page of an ended run
BattleBayDeluxe.tournament.CH = { EMB_S = 3.4, EMB_Y = 520, NAME_Y = 760, NAME_S = 1.3, BANNER_Y = 230, BANNER_S = 2.2, CROWN_Y = 330,
  CROWN_S = 2.2, DUR = 0.6, SLIDE = 700, TXT_BANNER = 0, TXT_NAME = 1 }
function BattleBayDeluxe.tournament_champion_layout(p)
  local G, C, L, H = BattleBayDeluxe.tournament.G, BattleBayDeluxe.tournament.C, BattleBayDeluxe.tournament.L, BattleBayDeluxe.tournament.CH
  local e = 1 - (1 - math.min(1, p)) ^ 3
  -- The plate's crest slot sits 22 ..
  local s = math.max(0.05, H.EMB_S * e)
  local i = BattleBayDeluxe.tournament.ROW_CHAMP
  funcLuaMenuCommand(C.SCALE, L.row_l, s, s, 1, i)
  funcLuaMenuCommand(C.POS, L.row_l, G.CX - 56 * s, -H.EMB_Y, 0, i)
  -- The banner slides in from the left
  local bx = G.CX - H.SLIDE * (1 - e)
  funcLuaMenuCommand(C.POS, L.txt, bx, -H.BANNER_Y, 0, H.TXT_BANNER)
  funcLuaMenuCommand(C.SCALE, L.txt, H.NAME_S * e, H.NAME_S * e, 1, H.TXT_NAME)
  local cs = H.CROWN_S * e
  funcLuaMenuCommand(C.SCALE, L.icon, G.CROWN_W * cs / G.Q, G.CROWN_H * cs / G.Q, 1, 0)
end

function BattleBayDeluxe.tournament_champion_text(i, str, x, y, scale)
  local C, L = BattleBayDeluxe.tournament.C, BattleBayDeluxe.tournament.L
  VRFW.bracket.take(BattleBayDeluxe.tournament_state, L.txt, i)
  funcLuaMenuCommand(C.VISIBLE, L.txt, i, true)
  funcLuaMenuCommand(C.POS, L.txt, x, -y, 0, i)
  funcLuaMenuCommand(C.SCALE, L.txt, scale, scale, 1, i)
  funcLuaMenuCommand(C.TEXT_STYLE, L.txt, i, BattleBayDeluxe.tournament.TXT_ON, BattleBayDeluxe.tournament.STYLE_TXT)
  funcLuaMenuCommand(C.TEXT, L.txt, BattleBayDeluxe.tournament.TXT_ON, str, i)
  funcLuaMenuCommand(C.TEXT, L.txt, BattleBayDeluxe.tournament.TXT_OFF, "", i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, L.txt, BattleBayDeluxe.tournament.TXT_ON, true, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, L.txt, BattleBayDeluxe.tournament.TXT_OFF, false, i)
end

function BattleBayDeluxe.tournament_champion_open(v)
  local C, L, H, G = BattleBayDeluxe.tournament.C, BattleBayDeluxe.tournament.L, BattleBayDeluxe.tournament.CH, BattleBayDeluxe.tournament.G
  BattleBayDeluxe.tournament_state.view, BattleBayDeluxe.tournament_state.page = v, v.page
  BattleBayDeluxe.tournament_state.champ = { t = 0, team = v.champion }
  BattleBayDeluxe.tournament_state.champ_done = true
  pcall(BattleBayDeluxe.tournament_tree_hide, "the champion screen")
  BattleBayDeluxe.tournament_begin()
  -- Shows the crest.
  local i = VRFW.bracket.take(BattleBayDeluxe.tournament_state, L.row_l, BattleBayDeluxe.tournament.ROW_CHAMP)
  funcLuaMenuCommand(C.VISIBLE, L.row_l, i, true)
  for _, m in pairs(BattleBayDeluxe.tournament.PLATE) do
    funcLuaMenuCommand(C.MESH_VISIBLE, L.row_l, m, false, i)
  end
  funcLuaMenuCommand(C.TEXT_VISIBLE, L.row_l, BattleBayDeluxe.tournament.TXT_ON, false, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, L.row_l, BattleBayDeluxe.tournament.TXT_OFF, false, i)
  funcLuaMenuCommand(C.PRIM_COLOR, L.row_l, i, BattleBayDeluxe.tournament.MESH_EMBLEM, 1, 1, 1)
  BattleBayDeluxe.tournament_alpha(L.row_l, i, 1)
  VRFW.team.emblem(L.row_l, i, v.champion, BattleBayDeluxe.tournament_state.emb)
  BattleBayDeluxe.tournament_champion_text(H.TXT_BANNER, BattleBayDeluxe.tournament_text("champion_banner"), G.CX, H.BANNER_Y, H.BANNER_S)
  BattleBayDeluxe.tournament_champion_text(H.TXT_NAME, VRFW.team.name(v.champion), G.CX, H.NAME_Y, H.NAME_S)
  BattleBayDeluxe.tournament_quad(L.icon, BattleBayDeluxe.tournament.SPR_CROWN, G.CX, H.CROWN_Y, G.CROWN_W * H.CROWN_S, G.CROWN_H * H.CROWN_S, { 1, 1, 1 })
  BattleBayDeluxe.tournament_end()
  BattleBayDeluxe.tournament_champion_layout(0)
  pcall(BattleBayDeluxe.tournament_host.title, BattleBayDeluxe.tournament_text(BattleBayDeluxe.tournament_run_key("champion", v.fmt == "league")))
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
  BattleBayDeluxe.tournament_log(string.format("champion screen: team %s (%s)", VRFW.ids.hex_text(v.champion),
    v.outcome == "champion" and "the player" or "a CPU team"))
  return true
end

-- Entrance animation from Step, timed by frame time (Step runs faster than 60 / s in menus).
function BattleBayDeluxe.tournament_champion_step()
  local ch = BattleBayDeluxe.tournament_state.champ
  if not ch or ch.t >= BattleBayDeluxe.tournament.CH.DUR then
    return
  end
  local dt = VRFW.host.command(1549797111)
  if type(dt) ~= "number" or dt <= 0 or dt > 0.5 then
    dt = 1 / 60
  end
  ch.t = ch.t + dt
  BattleBayDeluxe.tournament_champion_layout(ch.t / BattleBayDeluxe.tournament.CH.DUR)
end

-- View kinds drawn by the group-stage child menu.
BattleBayDeluxe.tournament_group_page_kinds = { groups = true, league = true, hub = true, scorers = true, squad = true, fixtures = true }
function BattleBayDeluxe.tournament_group_page_kind(kind)
  return BattleBayDeluxe.tournament_group_page_kinds[kind] == true
end

function BattleBayDeluxe.tournament_draw(page, animate)
  local v = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.VIEW, page or -1)
  if type(v) ~= "table" or v.kind == "none" then
    BattleBayDeluxe.tournament_log("view unavailable", tostring(v))
    return false
  end
  -- A finished tournament opens on its champion first (once per overlay opening).
  BattleBayDeluxe.tournament_state.champ = nil
  if (v.champion or 0) ~= 0 and (v.outcome or "") ~= "" and not BattleBayDeluxe.tournament_state.champ_done and (page == nil or page < 0) then
    return BattleBayDeluxe.tournament_champion_open(v)
  end
  BattleBayDeluxe.tournament_state.view, BattleBayDeluxe.tournament_state.page = v, v.page
  BattleBayDeluxe.tournament_state.hub_zones = nil
  BattleBayDeluxe.tournament_begin()
  -- The stadium dimmed under the page (the box pool's first quad, behind everything it draws).
  if BattleBayDeluxe.tournament_state.stadium_bg and v.kind ~= "groups" then
    BattleBayDeluxe.tournament_quad(BattleBayDeluxe.tournament.L.box, BattleBayDeluxe.tournament.SPR_DIM, BattleBayDeluxe.tournament.G.CX, 540, BattleBayDeluxe.tournament.G.W, 1080, BattleBayDeluxe.tournament.WHITE, BattleBayDeluxe.tournament.G.PRIO_DIM)
  end
  local ok, err = pcall(function()
    if v.kind == "results" then
      BattleBayDeluxe.tournament_draw_results(v)
    end
  end)
  if not ok then
    BattleBayDeluxe.tournament_log("draw error", tostring(err))
  end
  BattleBayDeluxe.tournament_end()
  -- Group and league standings pages draw in the child menu, the tree page in the bracket screen.
  if BattleBayDeluxe.tournament_group_page_kind(v.kind) then
    BattleBayDeluxe.tournament_groups_show(v.page)
  else
    BattleBayDeluxe.tournament_groups_hide()
  end
  if v.kind == "tree" then
    BattleBayDeluxe.tournament_tree_show(v.page, animate)
  else
    BattleBayDeluxe.tournament_tree_hide("the overlay left the tree page")
  end
  -- Log what this draw placed, and the view's fields when it placed nothing.
  local u = BattleBayDeluxe.tournament_state.used or {}
  local L = BattleBayDeluxe.tournament.L
  local placed = (u[L.row_l] or 0) + (u[L.row_r] or 0) + (u[L.line] or 0) + (u[L.txt] or 0)
  local keys = {}
  if placed == 0 then
    for k, x in pairs(v) do
      keys[#keys + 1] = tostring(k) .. ":" .. type(x) .. (type(x) == "table" and ("#" .. #x) or "")
    end
  end
  if BattleBayDeluxe.tournament_group_page_kind(v.kind) or v.kind == "tree" then
    keys = {}
  end
  BattleBayDeluxe.tournament_log(string.format("bracket drawn n=%d on %s (kind %s, rounds %s; plates %d+%d, lines %d, texts %d)%s%s",
    placed, BattleBayDeluxe.tournament_host.name, tostring(v.kind), tostring(v.rounds), u[L.row_l] or 0, u[L.row_r] or 0, u[L.line] or 0,
    u[L.txt] or 0, v.kind == "groups" and (" groups " .. #(v.groups or {}) .. " in battlebaydeluxe_tn_groups_menu")
      or (v.kind == "league" and (" standings " .. #(v.standings or {}) .. " rows in battlebaydeluxe_tn_groups_menu")
      or (v.kind == "tree" and " in vrfw_bracket_menu" or "")),
    #keys > 0 and (" view: " .. table.concat(keys, " ")) or ""))
  -- Sets the header title.
  local title = BattleBayDeluxe.tournament_title(v)
  local tail = BattleBayDeluxe.tournament_outcome(v)
  if tail ~= "" then
    title = title .. "  ·  " .. tail
  end
  pcall(BattleBayDeluxe.tournament_host.title, title)
  return true
end

-- Hides the background's character-art logo under the bracket (the stadium picture stays)
BattleBayDeluxe.tournament.BG_BB = @crc:vs01_00_p2_background_bb_stadium@
BattleBayDeluxe.tournament.BG_BB_LOGO = @crc:_bg_logo_bb01@
function BattleBayDeluxe.tournament_bg_logo(show)
  if BattleBayDeluxe.tournament_host.menu == BattleBayDeluxe.tournament.TOP then
    VRFW.host.menu_command(BattleBayDeluxe.tournament.C.MESH_VISIBLE, BattleBayDeluxe.tournament.BG_BB, BattleBayDeluxe.tournament.BG_BB_LOGO, show, 0)
  end
end

function BattleBayDeluxe.tournament_open(page)
  if BattleBayDeluxe.tournament_state.open then
    return BattleBayDeluxe.tournament_draw(page)
  end
  BattleBayDeluxe.tournament_state.open = true
  BattleBayDeluxe.tournament_state.emb = {}
  BattleBayDeluxe.tournament_state.prio = {}
  local H = BattleBayDeluxe.tournament_host
  BattleBayDeluxe.tournament_switch_layers(H.close, false)
  BattleBayDeluxe.tournament_show_layers(H.hide, false)
  BattleBayDeluxe.tournament_bg_logo(false)
  for _, l in ipairs(H.lists or {}) do
    funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, l, false)
  end
  -- The bracket keeps the menu's own background (not closed, no band, no stadium).
  local G = BattleBayDeluxe.tournament.G
  local sy = (G.BG_BOTTOM - G.BG_TOP) / G.BG_H
  funcLuaMenuCommand(BattleBayDeluxe.tournament.C.SCALE, BattleBayDeluxe.tournament.L.bg, 1, sy, 1, 0)
  funcLuaMenuCommand(BattleBayDeluxe.tournament.C.POS, BattleBayDeluxe.tournament.L.bg, 0, -(G.BG_TOP - G.BG_Y * sy), 0, 0)
  -- Stadium at the back (G.PRIO_STADIUM)
  BattleBayDeluxe.tournament_state.strip = {}
  BattleBayDeluxe.tournament_state.stadium_bg = false
  local nst = 0
  if type(nst) == "number" and nst >= 1 then
    bbt_open_layer(BattleBayDeluxe.tournament.L.stadium, 0)
    funcLuaMenuCommand(BattleBayDeluxe.tournament.C.SCALE, BattleBayDeluxe.tournament.L.stadium, 1, 1, 1, 0)
    funcLuaMenuCommand(BattleBayDeluxe.tournament.C.POS, BattleBayDeluxe.tournament.L.stadium, 0, 0, 0, 0)
    VRFW.host.menu_command(@crc:CMND_SET_DRAW_PRIORITY@, BattleBayDeluxe.tournament.L.stadium, 0, G.PRIO_STADIUM, true)
    BattleBayDeluxe.tournament_state.stadium_bg = true
  end
  -- Every instance opened once and hidden until a page draws it.
  BattleBayDeluxe.tournament_each_instance(function(l, i)
    bbt_open_layer(l, i)
    BattleBayDeluxe.tournament_hide(l, i)
  end)
  bbt_open_layer(BattleBayDeluxe.tournament.ANCHOR, 0)
  -- The input anchor is a button object
  funcLuaMenuCommand(BattleBayDeluxe.tournament.C.POS, BattleBayDeluxe.tournament.ANCHOR, -4000, 4000, 0, 0)
  funcLuaMenuCommand(BattleBayDeluxe.tournament.C.VISIBLE, BattleBayDeluxe.tournament.ANCHOR, 0, false)
  BattleBayDeluxe.tournament_focus_anchor()
  BattleBayDeluxe.tournament_state.focus_watch = 0
  pcall(BattleBayDeluxe.tournament_host.guide, true)
  if not BattleBayDeluxe.tournament_draw(page) then
    BattleBayDeluxe.tournament_close()
    return false
  end
  pcall(BattleBayDeluxe.tournament_diag, "open")
  return true
end

-- Logs diagnostics.
function BattleBayDeluxe.tournament_diag(when)
  local parts = {}
  for k, l in pairs(BattleBayDeluxe.tournament.L) do
    local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, l)
    local open = funcLuaMenuCommand(@crc:CMND_IS_OPEN_LAYER@, l, 0, BattleBayDeluxe.tournament_host.menu)
    local vis = VRFW.host.menu_command(@crc:CMND_IS_LAYER_VISIBLE@ --[[is visible]], l, 0)
    local gx, gy = VRFW.host.menu_command(@crc:CMND_GET_LAYER_GLOBAL_POS@ --[[global pos]], l, 0)
    parts[#parts + 1] = string.format("%s n=%s open0=%s vis0=%s pos0=%s,%s used=%s", k, tostring(n), tostring(open),
      tostring(vis), tostring(gx), tostring(gy), tostring(BattleBayDeluxe.tournament_state.used and BattleBayDeluxe.tournament_state.used[l]))
  end
  local v = BattleBayDeluxe.tournament_state.view or {}
  BattleBayDeluxe.tournament_log(string.format("bracket %s on %s: kind %s page %s | %s", when, BattleBayDeluxe.tournament_host.name, tostring(v.kind),
    tostring(v.page), table.concat(parts, "; ")))
end

function BattleBayDeluxe.tournament_close()
  -- Log the view's open / close state.
  BattleBayDeluxe.tournament_log("overlay closing on " .. tostring(BattleBayDeluxe.tournament_host.name) .. ": page " .. tostring(BattleBayDeluxe.tournament_state.page) .. ", group page menu " ..
    (BattleBayDeluxe.tournament_groups_child().open() and "open" or "not open"))
  BattleBayDeluxe.tournament_state.champ, BattleBayDeluxe.tournament_state.champ_done = nil, false
  BattleBayDeluxe.tournament_groups_hide()   -- the group-stage child menu
  BattleBayDeluxe.tournament_tree_hide("the overlay closed")
  BattleBayDeluxe.tournament_each_instance(function(l, i)
    bbt_close_layer(l, i)
  end)
  bbt_close_layer(BattleBayDeluxe.tournament.L.bg, 0)
  if BattleBayDeluxe.tournament_state.stadium_bg then
    bbt_close_layer(BattleBayDeluxe.tournament.L.stadium, 0)
    BattleBayDeluxe.tournament_state.stadium_bg = false
  end
  bbt_close_layer(BattleBayDeluxe.tournament.ANCHOR, 0)
  BattleBayDeluxe.tournament_state.emb = {}
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, BattleBayDeluxe.tournament.ANCHOR, false)
  BattleBayDeluxe.tournament_state.open = false
  local H = BattleBayDeluxe.tournament_host
  BattleBayDeluxe.tournament_switch_layers(H.close, true)
  BattleBayDeluxe.tournament_show_layers(H.hide, true)
  BattleBayDeluxe.tournament_bg_logo(true)
  H.header()
  -- Refreshes the badge.
  if H.name == "bb_stadium_top_menu" then
    pcall(OnSetupLayer, BattleBayDeluxe.tournament.BADGE, 0)
  end
  H.refocus()
  BattleBayDeluxe.tournament_state.focus_watch = nil
  pcall(H.guide, false)
end

-- The input anchor takes the keys.
BattleBayDeluxe.tournament.FOCUS_SETTLE = 120
function BattleBayDeluxe.tournament_focus_anchor()
  funcLuaMenuCommand(@crc:CMND_SET_ENABLE_CTRL_FOCUS@, BattleBayDeluxe.tournament.ANCHOR, true)
  funcLuaMenuCommand(1778826357, BattleBayDeluxe.tournament.ANCHOR, 0, true)
end

-- From Step after an opening
function BattleBayDeluxe.tournament_focus_watch()
  local S = BattleBayDeluxe.tournament_state
  S.focus_watch = S.focus_watch + 1
  local has = funcLuaMenuCommand(@crc:CMND_IS_CTRL_FOCUS_ACTIVE@, BattleBayDeluxe.tournament.ANCHOR) == true
  if has then
    if S.focus_watch > 1 then
      BattleBayDeluxe.tournament_log("overlay keys: the anchor holds the focus after " .. S.focus_watch .. " Step(s)")
    end
    S.focus_watch = nil
    return
  end
  if S.focus_watch >= BattleBayDeluxe.tournament.FOCUS_SETTLE then
    BattleBayDeluxe.tournament_log("overlay keys: the anchor never reported its focus in " .. BattleBayDeluxe.tournament.FOCUS_SETTLE ..
      " Steps (a decide on any layer is still the overlay's Enter)")
    S.focus_watch = nil
    return
  end
  BattleBayDeluxe.tournament_focus_anchor()
end

-- Round results show once, right after the match
BattleBayDeluxe.tournament_results_page = 20

-- Bracket page of a view
function BattleBayDeluxe.tournament_bracket_page_of(v)
  if v.home_page ~= nil then
    return v.home_page
  end
  local first
  for _, p in ipairs(v.pages or {}) do
    if p < BattleBayDeluxe.tournament_results_page then
      if p == 0 then
        return 0
      end
      first = first or p
    end
  end
  return first
end

function BattleBayDeluxe.tournament_entry_page()
  local v = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.VIEW, -1)
  if type(v) ~= "table" or v.kind ~= "results" then
    return -1
  end
  if (v.champion or 0) ~= 0 and (v.outcome or "") ~= "" then
    return -1
  end
  return BattleBayDeluxe.tournament_bracket_page_of(v) or -1
end

function BattleBayDeluxe.tournament_turn(d)
  local v = BattleBayDeluxe.tournament_state.view
  if not v or not v.pages then
    return
  end
  -- From a bracket page the results page is skipped when turning pages.
  local pages = {}
  for _, p in ipairs(v.pages) do
    if p < BattleBayDeluxe.tournament_results_page or (BattleBayDeluxe.tournament_state.page or 0) >= BattleBayDeluxe.tournament_results_page then
      pages[#pages + 1] = p
    end
  end
  if #pages < 2 then
    return
  end
  local k = 1
  for i, p in ipairs(pages) do
    if p == BattleBayDeluxe.tournament_state.page then
      k = i
    end
  end
  k = (k - 1 + d) % #pages + 1
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
  BattleBayDeluxe.tournament_draw(pages[k])
end

-- Starts the next match.
function BattleBayDeluxe.tournament_play_next()
  -- Write the tournament's match into the campaign block (CMND_BATTLEBAYDELUXE_TOURNAMENT_PREPARE).
  local prep = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.PREPARE)
  if type(prep) ~= "table" or not prep.ok then
    BattleBayDeluxe.tournament_log("next match: not prepared", type(prep) == "table" and "refused" or "busy")
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0003@)
    return
  end
  VRFW.host.command(BattleBayDeluxe.tournament.RULE_SELECT, prep.rules or "")
  BattleBayDeluxe.tournament_close()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
  local ret = funcLuaMenuCommand(2227512519)
  BattleBayDeluxe.tournament_log("next match requested", tostring(ret), prep.rules or "")
  if not ret then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.UNLOAD)
  end
  if ret then
    -- The host's mark for the way back.
    pcall(BattleBayDeluxe.tournament_host.before_match)
    funcLuaMenuCommand(@crc:CMND_MAKE_ACHIEVE_MESSAGE@, BattleBayDeluxe.tournament_host.menu, false)
    if type(BrightFadeAllMenu) == "function" then
      BrightFadeAllMenu(@crc:fade_menu_encount_campaign@, true)
    end
    funcLuaCommand(769636339, 0.5)
    if BattleBayDeluxe.tournament_host.menu ~= @crc:soccer_top_menu@ then
      funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, BattleBayDeluxe.tournament_host.menu, true)
    end
    funcLuaCommand(@crc:CMND_CLOSE_MENU_OBJECT@, @crc:soccer_top_menu@)
  end
end

function BattleBayDeluxe.tournament_on_enter()
  -- Enter during the bracket advance ends it at once.
  if VRFW.bracket.busy() then
    VRFW.bracket.skip()
    BattleBayDeluxe.tournament_log("bracket advance: skipped")
    return
  end
  -- The league hub dashboard waits for its side menu action.
  if BattleBayDeluxe.tournament_hub_key("enter") or BattleBayDeluxe.tournament_hub_calendar_key("enter") then
    return
  end
  -- A league hub section page
  if BattleBayDeluxe.tournament_state.section then
    BattleBayDeluxe.tournament_state.section = false
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@)
    return
  end
  if BattleBayDeluxe.tournament_state.champ then
    -- Shows the champion screen.
    BattleBayDeluxe.tournament_state.champ = nil
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
    local v = BattleBayDeluxe.tournament_state.view or {}
    BattleBayDeluxe.tournament_draw(v.home_page or (v.pages and v.pages[#v.pages]) or 0, true)
    return
  end
  local v = BattleBayDeluxe.tournament_state.view or {}
  -- A running league's results after a match
  if v.fmt == "league" and (v.outcome or "") == "" and not BattleBayDeluxe.tournament_state.hub and BattleBayDeluxe.tournament_state.co == nil then
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
    BattleBayDeluxe.tournament_state.co = coroutine.create(BattleBayDeluxe.tournament_league_hub)
    return
  end
  -- Results page after a match
  if v.kind == "results" then
    local p = BattleBayDeluxe.tournament_bracket_page_of(v)
    if p ~= nil then
      funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
      BattleBayDeluxe.tournament_draw(p, true)
      BattleBayDeluxe.tournament_log("results -> bracket page", p)
      return
    end
  end
  if v.watching then
    -- Handles an eliminated player.
    local r = BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.STEP)
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
    if type(r) == "table" and r.event == "step" then
      BattleBayDeluxe.tournament_draw(-1)
      return
    end
  end
  if v.outcome ~= nil and v.outcome ~= "" then
    BattleBayDeluxe.tournament_call(BattleBayDeluxe.tournament.CLOSE)
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0000@)
    BattleBayDeluxe.tournament_close()
    return
  end
  if (v.next or 0) ~= 0 then
    BattleBayDeluxe.tournament_state.co = coroutine.create(BattleBayDeluxe.tournament_play_next)
    return
  end
  BattleBayDeluxe.tournament_close()
end
