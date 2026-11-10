CmPages.PITCH = {X0 = 120, X1 = 960, Y0 = 190, Y1 = 960, BENCH_X = 1110, BENCH_Y0 = 200, BENCH_DY = 84, PLATE = 96,
                 MAX = 30, GHOST = {0.55, 0.57, 0.62}, GHOST_ALPHA = 0.45}
-- The team dock's lineup layers (content/menus/contact_map.toml).
CmPages.FORM = {BASE = 3518110933 --[[mainmenu04_10_formation_base]], FRAME = 3321884270 --[[soccer11_02_formation_frame]],
                CARD = 1973487846 --[[team00_01_chara_card_for_soccer]], LEADER = 1658289671 --[[`..._for_leader`]],
                BLANK = 3571911991 --[[team00_01_p1_chara_card_blank]], BLANK_L = 2290394976 --[[`..._blank_for_leader`]],
                filled = nil, shown = false}
CmPages.FORM_LAYER = {[3518110933] = true, [3321884270] = true, [1973487846] = true, [1658289671] = true,
                      [3571911991] = true, [2290394976] = true}
CmPages.CARD = {HW = 104, HH = 80,      -- half the size of a lineup card on the screen (the hit box)
                BORDER_MESH = 3345942320, SEASONAL_MESH = 960763094 --[[_seasonal_frame_l01]],
                SMALL_MESH = 3491095421 --[[_icon_chr_focus_s01]],
                SMALL_HW = 68, SMALL_HH = 50,     -- half the size of a small card on the screen (the hit box)
                -- Constants of the state border.
                BORDER_PAD = 6, BORDER_PRIORITY = 800,
                NEW_TAG = 40}
CmPages.FOCUS = {ANIM = 2734777837 --[[Focus]], TYPE = 973515837, PLAY = @crc:CMND_PLAY_ANIME_TYPE@,
                 CURSOR_BIG = 945715707, CURSOR_SMALL = 1967169874, CURSOR_LOCATOR = @crc:CMND_SET_CURSOR_LOCATOR@,
                 cur = nil,
                 -- Dummies of the leader card's number primitives (_num_chr_dmy_l01, l02, s01, s02).
                 NUMBERS = {1451641049, 3482261859, 1107078292, 3639999790}}
-- Locators of the frame that bound the lineup (the cards hang on the frame).
CmPages.FORM_SPAN = {TOP = 3984567298 --[[_pos_formation01_lu]], BOTTOM = 2278526192 --[[_pos_formation01_ld]],
                     BENCH = 2517135446 --[[_pos_support_atc02]]}

-- Returns a locator of a lineup layer (layer-local, y up).
function CmPages.form_pose(layer, joint)
  local ok, x, y, _, found = pcall(funcLuaMenuCommand, @crc:CMND_GET_MESH_POSE@, layer, 0, joint)
  if ok and found ~= false and type(x) == "number" and type(y) == "number" then
    return x, y
  end
  return nil
end

-- The team dock hangs the pitch lines and the formation frame on a locator of its own layer, which this function places.
function CmPages.place_form_layers()
  local F, P, S, H = CmPages.FORM, CmPages.PITCH, CmPages.FORM_SPAN, CmPages.CARD.HH
  local _, top = CmPages.form_pose(F.FRAME, S.TOP)
  local _, bottom = CmPages.form_pose(F.FRAME, S.BOTTOM)
  local _, bench = CmPages.form_pose(F.FRAME, S.BENCH)
  if top == nil or bottom == nil then
    Log("lineup place: no formation spots on the frame")
    return false
  end
  local low = (bench ~= nil and bench < bottom) and bench or bottom
  local mid = ((top + H) + (low - H)) / 2                  -- the lineup's centre, layer-local (y up)
  local tx, ty = (P.X0 + P.X1) / 2, -((P.Y0 + P.Y1) / 2)    -- the pitch area's centre, global (y up)
  for _, l in ipairs({F.BASE, F.FRAME}) do
    local ok, gx, gy = pcall(funcLuaMenuCommand, 4002164178 --[[the instance's global position]], l, 0)
    gx = (ok and type(gx) == "number") and gx or 0
    gy = (ok and type(gy) == "number") and gy or 0
    pcall(funcLuaMenuCommand, C.POS, l, tx - gx, ty - mid - gy, 0, 0)
  end
  Log("lineup placed at", tostring(tx), tostring(ty - mid), "span", tostring(top), tostring(low))
  return true
end

-- a lineup layer's setup, as the free-match list does it for the same layers (soccer_formation_menu_inc)
function CmPages.setup_form_layer(a1, a2)
  local F = CmPages.FORM
  if a1 == F.FRAME and type(SetFormationLayer) == "function" then
    pcall(SetFormationLayer, a1)
    local HR = type(VRFW.ui_plates) == "table" and VRFW.ui_plates.header_row or nil
    if HR ~= nil then
      pcall(HR.level_off, a1, a2)
      pcall(funcLuaMenuCommand, C.NODE_VISIBLE, a1, HR.LEVEL_GROUP, false, a2 or 0)
    end
  elseif a1 == F.CARD or a1 == F.LEADER then
    pcall(funcLuaMenuCommand, 4233535095, a1, a2, false)
    pcall(funcLuaMenuCommand, 2628464193, a1, a2, 550)
    -- Hides the seasonal shimmer frame.
    pcall(funcLuaMenuCommand, C.MESH_VISIBLE, a1, CmPages.CARD.SEASONAL_MESH, false, a2)
    pcall(funcLuaMenuCommand, C.MESH_VISIBLE, a1, CmPages.CARD.BORDER_MESH, false, a2)
    pcall(funcLuaMenuCommand, C.MESH_VISIBLE, a1, CmPages.CARD.SMALL_MESH, false, a2)
    if a1 == F.LEADER then
      for _, m in ipairs(CmPages.FOCUS.NUMBERS) do
        pcall(funcLuaMenuCommand, C.MESH_VISIBLE, a1, m, false, a2)
      end
    end
  end
  if type(OnSetupLayerFormationCommon) == "function" then
    pcall(OnSetupLayerFormationCommon, a1, a2)
  end
end

function CmPages.form_count(layer)
  local ok, n = pcall(funcLuaMenuCommand, C.LAYER_NUM or @crc:CMND_GET_CREATE_LAYER_NUM@, layer)
  return (ok and type(n) == "number") and n or 0
end

-- Opens the lineup layers with the screen's own (a layer is drawn only once opened), hidden until a team is shown.
function CmPages.open_form_layers()
  local F = CmPages.FORM
  local n = 0
  for _, l in ipairs({F.BASE, F.FRAME, F.BLANK, F.BLANK_L, F.CARD, F.LEADER}) do
    for i = 0, CmPages.form_count(l) - 1 do
      pcall(funcLuaMenuCommand, C.OPEN_LAYER, l, i)
      pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, l, i, false)
      n = n + 1
    end
  end
  F.shown, F.filled, F.opened = false, nil, n > 0
  Log("lineup layers opened", n)
  if n > 0 then
    CmPages.place_form_layers()
  end
end

function CmPages.hide_lineup()
  local F = CmPages.FORM
  CmPages.unfocus()
  if not F.shown then
    return
  end
  F.shown = false
  for _, l in ipairs({F.BASE, F.FRAME, F.CARD, F.LEADER, F.BLANK, F.BLANK_L}) do
    for i = 0, CmPages.form_count(l) - 1 do
      pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, l, i, false)
    end
  end
end

-- Shows the page's team on the game's lineup.
function CmPages.lineup(z)
  local F = CmPages.FORM
  if type(UpdateMemberCharaIconInfoByChrParamId) ~= "function" or type(UpdateMainMemberIcomFormationPos) ~= "function" then
    return false
  end
  local ncard = CmPages.form_count(F.CARD)
  local zz = MAP and MAP.zones[z]
  local team = zz and Int(zz.team) or 0
  if ncard == 0 or team == 0 then
    return false
  end
  if not F.opened then
    CmPages.open_form_layers()
  end
  if F.filled ~= team then
    F.filled = team
    local lv, sold = {}, {}
    for _, n in ipairs(MAP.nodes) do
      if n.zone == z and Int(n.level or 0) > 0 then
        lv[Int(n.card)] = Int(n.level)
      end
      if n.zone == z and n.kind == "player" then
        sold[Int(n.card)] = true
      end
    end
    for i = 0, ncard - 1 do
      pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, F.BLANK, i, false)
      pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, F.CARD, i, false)
    end
    local _, form = funcLuaCommand(2151743654, team, 3)
    pcall(UpdateMainMemberIcomFormationPos, form or 0, true)
    local _, uni = funcLuaCommand(2151743654, team, 4)
    local kit = funcLuaMenuCommand(1187793486, uni or 0)
    local okc, cnt = funcLuaCommand(2151743654, team, 8)
    if type(SetDisableForceCharaInvalidUseTarget) == "function" then
      pcall(SetDisableForceCharaInvalidUseTarget)
    end
    F.coach = false
    for m = 0, ((okc and type(cnt) == "number") and cnt or 0) - 1 do
      local okp, param = funcLuaCommand(34355761, team, m, 0)
      local oks, slot = funcLuaCommand(34355761, team, m, 7)
      if okp and oks and slot == 19 and CmPages.form_count(F.LEADER) > 0
          and type(UpdateLeaderCharaByCharaParamId) == "function" then
        -- Sets the coach.
        pcall(UpdateLeaderCharaByCharaParamId, param, F.LEADER, 0, lv[Int(param)] or 1)
        for _, mesh in ipairs(CmPages.FOCUS.NUMBERS) do
          pcall(funcLuaMenuCommand, C.MESH_VISIBLE, F.LEADER, mesh, false, 0)
        end
        pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_MODEL_ALPHA@, F.LEADER, 0, 0,
          sold[Int(param)] and 1 or CmPages.PITCH.GHOST_ALPHA)
        F.coach = true
      elseif okp and oks and type(slot) == "number" and slot < 19 and slot < ncard then
        local _, num = funcLuaCommand(34355761, team, m, 9)
        pcall(UpdateMemberCharaIconInfoByChrParamId, param, slot, form, kit, lv[Int(param)] or 1, num, uni, 4)
        pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, F.CARD, slot, true)
        -- a member sold on another page (or not at all) stays on the lineup, translucent
        pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_MODEL_ALPHA@, F.CARD, slot, 0,
          sold[Int(param)] and 1 or CmPages.PITCH.GHOST_ALPHA)
      end
    end
    if type(SetEnableForceCharaInvalidUseTarget) == "function" then
      pcall(SetEnableForceCharaInvalidUseTarget)
    end
    local x0, y0 = CmPages.card_at(0)
    Log("lineup", team, "formation " .. tostring(form) .. " members " .. tostring(cnt) .. " cards " .. tostring(ncard)
      .. " card 0 at " .. tostring(x0) .. ", " .. tostring(y0))
  end
  if not F.shown then
    F.shown = true
    -- An 11-a-side lineup draws on the formation frame alone (its own pitch).
    pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, F.BASE, 0, false)
    pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, F.FRAME, 0, true)
  end
  -- the leader card only for a team with a coach (no empty leader box)
  for _, l in ipairs({F.LEADER, F.BLANK_L}) do
    for i = 0, CmPages.form_count(l) - 1 do
      pcall(funcLuaMenuCommand, C.LAYER_VISIBLE, l, i, l == F.LEADER and i == 0 and F.coach == true)
    end
  end
  return true
end

-- Returns the screen place of the lineup card of slot (the layer instance's position, y down).
function CmPages.card_at(slot)
  local layer, idx = CmPages.card_of(slot)
  local ok, gx, gy = pcall(funcLuaMenuCommand, 4002164178 --[[the instance's position]], layer, idx)
  if ok and type(gx) == "number" and type(gy) == "number" and (math.abs(gx) > 1 or math.abs(gy) > 1) then
    return gx, -gy
  end
  return nil
end
CmPages.seen = {}
CmPages.seen_key = nil

-- Returns the card of team slot `slot`.
function CmPages.card_of(slot)
  if slot == 19 then
    return CmPages.FORM.LEADER, 0
  end
  return CmPages.FORM.CARD, slot
end

function CmPages.is_big_card(layer, idx)
  if type(IsCharaCardBigtype) == "function" then
    local ok, big = pcall(IsCharaCardBigtype, idx, layer)
    if ok and type(big) == "boolean" then
      return big
    end
  end
  return layer == CmPages.FORM.LEADER or idx <= 10
end

-- Returns a lineup card's own frames.
function CmPages.card_frames(layer, idx)
  local B = CmPages.CARD
  local big = CmPages.is_big_card(layer, idx)
  pcall(funcLuaMenuCommand, C.MESH_VISIBLE, layer, B.SEASONAL_MESH, false, idx)
  pcall(funcLuaMenuCommand, C.MESH_VISIBLE, layer, big and B.SMALL_MESH or B.BORDER_MESH, false, idx)
  pcall(funcLuaMenuCommand, C.MESH_VISIBLE, layer, big and B.BORDER_MESH or B.SMALL_MESH, true, idx)
end

function CmPages.state_border(k, role, x, y, hw, hh)
  local B = CmPages.CARD
  Kit.art_quad(L_TAG, k, role, x, y, 2 * (hw + B.BORDER_PAD), 2 * (hh + B.BORDER_PAD))
  pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@ --[[draw priority]], L_TAG, k, B.BORDER_PRIORITY, true)
end

function CmPages.focus_card(layer, idx)
  local Fo = CmPages.FOCUS
  local cur = Fo.cur
  if cur ~= nil and (cur[1] ~= layer or cur[2] ~= idx) then
    pcall(funcLuaMenuCommand, Fo.PLAY, cur[1], cur[2], Fo.ANIM, 2, Fo.TYPE)
    pcall(funcLuaMenuCommand, C.ATTACH_TRACE, cur[1], cur[2], cur[4], false)
    pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@ --[[draw priority]], cur[1], cur[2], cur[3], true)
    Fo.cur = nil
  end
  if layer == nil then
    if cur ~= nil then
      funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, false)
    end
    return
  end
  if Fo.cur == nil then
    local okp, prio = pcall(funcLuaMenuCommand, @crc:CMND_GET_DRAW_PRIORITY@ --[[the instance's draw priority]], layer, idx)
    local label = CmPages.is_big_card(layer, idx) and Fo.CURSOR_BIG or Fo.CURSOR_SMALL
    Fo.cur = {layer, idx, (okp and type(prio) == "number") and prio or 652, label}
    pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@ --[[draw priority]], layer, idx, Fo.cur[3] + 30, true)
    pcall(funcLuaMenuCommand, Fo.PLAY, layer, idx, Fo.ANIM, 0, Fo.TYPE)
    funcLuaMenuCommand(C.POS, L_CURSOR, 0, 0, 0, 0)       -- no offset of its own: the locator places it
    pcall(funcLuaMenuCommand, C.ATTACH_TRACE, layer, idx, label, true)
    pcall(funcLuaMenuCommand, Fo.CURSOR_LOCATOR, layer, label, idx, math.max(1, CmPages.form_count(layer)))
  end
  funcLuaMenuCommand(C.LAYER_VISIBLE, L_CURSOR, 0, true)
end

function CmPages.unfocus()
  CmPages.focus_card(nil)
end

function CmPages.price_of(n)
  if n ~= nil and (n.spirit or 0) ~= 0 then
    return {spirit = n.spirit, count = n.price or 0}
  end
  return {item = SET and SET.rc or 0, count = n and n.price or 0}
end

-- one price spirit's name (the set's ElementCurrencyUnit), else the currency's name
function CmPages.pay_unit(n)
  if n ~= nil and (n.pay_unit or 0) ~= 0 then
    local t = Kit.text(n.pay_unit)
    if t ~= "" then
      return t
    end
  end
  return CmPages.pay_name(n)
end

-- Returns the width in pixels of `s` on a text instance at scale 1.
function CmPages.text_width(layer, idx, s)
  return VRFW.text_fold.measure(layer, idx, TEXT_ON, s) or VRFW.text_fold.width(s, INFO.CHAR_W)
end

function CmPages.pay_name(n)
  if n ~= nil and (n.pay_title or 0) ~= 0 then
    local t = Kit.text(n.pay_title)       -- the set's name of that element's spirit (ElementCurrencyTitle)
    if t ~= "" then
      return t
    end
  end
  if n ~= nil and (n.spirit or 0) ~= 0 and (n.pay_name or "") ~= "" then
    return n.pay_name
  end
  return CmPages.currency_name()
end

function CmPages.trial_text(r)
  local obj = r.objective or 0
  local kind = math.floor(obj / 100000)
  local secs = math.floor((obj % 100000) / 100)
  local count = obj % 100
  local id = T.TRIAL[kind] or T.TRIAL[1]
  if kind == 1 then
    return Kit.format(id, r.part or 1, r.of or 1, secs)
  elseif kind == 2 then
    return Kit.format(id, r.part or 1, r.of or 1, count, secs)
  end
  return Kit.format(id, r.part or 1, r.of or 1, count)
end

-- Marks players, items, levels and trials as never asked again.
function CmPages.waive_signed()
  if MAP == nil or not MAP.pitch then
    return
  end
  for i, n in ipairs(MAP.nodes) do
    if signed[i] == true and n.all_reqs == nil then
      n.all_reqs = n.reqs
      local keep = {}
      for _, r in ipairs(n.reqs or {}) do
        if r.kind == "cleared" or r.kind == "unlock" then
          keep[#keep + 1] = r
        end
      end
      n.reqs = keep
    end
  end
end

function CmPages.load_seen()
  CmPages.seen = {}
  CmPages.seen_key = nil
  if MAP == nil or not MAP.pitch then
    return
  end
  CmPages.seen_key = "contact.seen." .. MAP.key
  local v = Call(C.SAVE_GET, OWNER, CmPages.seen_key, "")
  for x in string.gmatch(type(v) == "string" and v or "", "%d+") do
    CmPages.seen[tonumber(x)] = true
  end
end

function CmPages.mark_seen(n)
  if CmPages.seen_key == nil or n == nil or CmPages.seen[Int(n.card)] then
    return
  end
  CmPages.seen[Int(n.card)] = true
  local t = {}
  for c in pairs(CmPages.seen) do
    t[#t + 1] = c
  end
  table.sort(t)
  Call(C.SAVE_SET, OWNER, CmPages.seen_key, table.concat(t, ","), 1)
end

-- Returns a team page's members.
function CmPages.members(z)
  local out = {}
  for _, kind in ipairs({"player", "ghost"}) do
    for i, n in ipairs(MAP.nodes) do
      if n.kind == kind and n.zone == z then
        out[#out + 1] = i
      end
    end
  end
  return out
end

function CmPages.spot(g)
  local P = CmPages.PITCH
  local n = MAP.nodes[members[g]]
  if (n.px or -1) >= 0 and (n.py or -1) >= 0 then
    return P.X0 + n.px * (P.X1 - P.X0), P.Y0 + n.py * (P.Y1 - P.Y0)
  end
  local k = 0
  for h = 1, g - 1 do
    local m = MAP.nodes[members[h]]
    if not ((m.px or -1) >= 0 and (m.py or -1) >= 0) then
      k = k + 1
    end
  end
  return P.BENCH_X, P.BENCH_Y0 + k * P.BENCH_DY
end

function CmPages.draw_pitch()
  local P = CmPages.PITCH
  local cards = CmPages.lineup(zone)
  CmPages.at = {}
  for g, i in ipairs(members) do
    local k = g - 1
    if k >= P.MAX then
      break
    end
    local n = MAP.nodes[i]
    local x, y = CmPages.spot(g)
    local size = (n.px or -1) >= 0 and P.PLATE or P.PLATE * 0.8
    local cx, cy = nil, nil
    if cards and n.main and Int(n.slot or 99) <= 19 then
      cx, cy = CmPages.card_at(Int(n.slot))
    end
    if cx ~= nil then
      -- The selection is the card's own (CmPages.focus_card).
      CmPages.at[g] = {cx, cy}
      local B = CmPages.CARD
      local hw, hh = B.HW, B.HH
      local layer, idx = CmPages.card_of(Int(n.slot))
      if not CmPages.is_big_card(layer, idx) then
        hw, hh = B.SMALL_HW, B.SMALL_HH
      end
      pcall(funcLuaMenuCommand, @crc:CMND_SET_LAYER_MODEL_ALPHA@, layer, idx, 0,
        n.kind == "ghost" and P.GHOST_ALPHA or 1)
      Kit.hide_off_screen(L_TILE, k)
      Kit.hide_off_screen(L_FACE, k)
      Kit.hide_off_screen(L_TILE, 100 + k)
      pos[g] = {x = cx, y = cy, hw = hw, hh = hh, layer = layer, idx = idx}
      Kit.hide_off_screen(L_TAG, k)
      CmPages.card_frames(layer, idx)
      if n.kind == "ghost" then
        Kit.hide_off_screen(L_TAG, B.NEW_TAG + k)
      else
        -- The selected card shows the retail cyan selection instead.
        local st = State(i)
        if g ~= focus.grid then
          CmPages.state_border(k, st == "done" and "card_border_signed"
            or (st == "ready" and "card_border_ready" or "card_border_unmet"), cx, cy, hw, hh)
        end
        local bs = 44
        if st == "ready" and not CmPages.seen[Int(n.card)] and B.NEW_TAG + k < N.TAG then
          Kit.art_quad(L_TAG, B.NEW_TAG + k, "badge_new", cx - hw + bs * 0.4, cy - hh + bs * 0.4, bs, bs)
          pcall(funcLuaMenuCommand, @crc:CMND_SET_DRAW_PRIORITY@ --[[draw priority]], L_TAG, B.NEW_TAG + k, 801, true)
        else
          Kit.hide_off_screen(L_TAG, B.NEW_TAG + k)
        end
        if g == focus.grid and st == "ready" then
          CmPages.mark_seen(n)
        end
      end
    elseif n.kind == "ghost" then
      Plate(k, "locked", x, y, size)
      DrawFace(L_FACE, k, n, x, y, size * NET.FACE_IN)
      pcall(Kit.tint, L_FACE, k, P.GHOST)
      Kit.hide_off_screen(L_TAG, k)
      pos[g] = {x = x, y = y, hw = size / 2, hh = size / 2}
    else
      local st = State(i)
      local bs = size * GRID.CHECK
      local bx, by = x + size / 2 - bs * 0.45, y + size / 2 - bs * 0.45
      Plate(k, st, x, y, size)
      DrawFace(L_FACE, k, n, x, y, size * NET.FACE_IN)
      local e = Int(n.element or 0)
      local tc = ELEM_ICON[e] ~= nil and Kit.texture(COMMON_TEX) or nil
      if tc then
        local es = size * 0.34
        Kit.textured_quad(L_TILE, 100 + k, tc, CRC32(ELEM_ICON[e]), x + size / 2 - es * 0.45, y - size / 2 + es * 0.45, es, es)
      else
        Kit.hide_off_screen(L_TILE, 100 + k)
      end
      if st == "done" then
        Kit.art_quad(L_TAG, k, "icon_check", bx, by, bs, bs)
      elseif st == "ready" and not CmPages.seen[Int(n.card)] then
        Kit.art_quad(L_TAG, k, "badge_new", x - size / 2 + bs * 0.45, y - size / 2 + bs * 0.45, bs, bs)
      elseif ReqsUnmet(n) then
        Kit.art_quad(L_TAG, k, "badge_unmet", bx, by, size * GRID.REQNG, size * GRID.REQNG)
      else
        Kit.hide_off_screen(L_TAG, k)
      end
      pos[g] = {x = x, y = y, hw = size / 2, hh = size / 2}
      if g == focus.grid and st == "ready" then
        CmPages.mark_seen(n)
      end
    end
  end
  local p = pos[focus.grid]
  if p ~= nil and p.layer ~= nil then
    CmPages.focus_card(p.layer, p.idx)
  else
    CmPages.unfocus()
  end
  if CmPages.guide ~= nil then
    CmPages.guide()
  end
end

-- Handles the D-pad on the pitch.
function CmPages.where(g)
  local a = CmPages.at and CmPages.at[g]
  if a ~= nil then
    return a[1], a[2]
  end
  return CmPages.spot(g)
end

function CmPages.pitch_move(dx, dy)
  local cx, cy = CmPages.where(focus.grid)
  local best, bd = nil, nil
  for g, i in ipairs(members) do
    if g ~= focus.grid and g <= CmPages.PITCH.MAX then
      local x, y = CmPages.where(g)
      local ax, ay = x - cx, y - cy
      local along = ax * dx + ay * dy
      if along > 4 then
        local side = math.abs(ax * dy) + math.abs(ay * dx)
        local d = along + side * 2.5
        if bd == nil or d < bd then
          best, bd = g, d
        end
      end
    end
  end
  return best
end

function CmPages.focused()
  if MAP == nil or not MAP.pitch or mode ~= "grid" then
    return nil
  end
  local i = members[focus.grid]
  local n = i and MAP.nodes[i] or nil
  if n == nil or n.kind ~= "player" then
    return nil
  end
  return n, i
end

-- the focused player's first trial not passed yet (a requirement, or an optional trial when the set asks none)
function CmPages.open_trial(n)
  for _, list in ipairs({n and n.reqs or {}, n and n.trials or {}}) do
    for _, r in ipairs(list) do
      if r.kind == "trial" and VRFW.recruit.have(r) < 1 then
        return r
      end
    end
  end
  return nil
end

-- Returns the button guide's extra entries.
function CmPages.guide_extra()
  local out = {}
  local n, i = CmPages.focused()
  if n == nil then
    return out
  end
  if CmPages.open_trial(n) ~= nil then
    out[#out + 1] = {T.TRIAL_BTN, 2735202045 --[[<CMD_FUNC3>]], 3421673595 --[[CMD_FUNC3]]}
  end
  if IsSigned(i) then
    out[#out + 1] = {T.RELEASE_BTN, 950905002 --[[<CMD_FUNC4>]], 1435897304 --[[CMD_FUNC4]]}
  end
  return out
end

-- Handles Y.
function CmPages.trial()
  local n = CmPages.focused()
  local r = CmPages.open_trial(n)
  if r == nil then
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  if not Ask(Kit.format(T.TRIAL_ASK, CmPages.trial_text(r))) then
    return
  end
  local ok, started = pcall(funcLuaCommand, C.MENU_CALL, HUB.menu or 0, "vrfw_recruit_trial", r.friendly, r.game,
    r.difficulty or 1, r.tag or 0, r.sub or 0, r.objective or 0, r.friendly_team or "")
  Log("trial", tostring(r.friendly), r.game, r.tag, r.sub, tostring(ok), tostring(started))
  if not ok or started == false then
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(T.TRIAL_FAIL))
    return
  end
  CmPages.leave(0)
end

function CmPages.release()
  local n, i = CmPages.focused()
  if n == nil or not IsSigned(i) then
    return
  end
  funcLuaCommand(C.SE, SE_DECIDE)
  if not Ask(Kit.format(T.RELEASE_Q, n.name)) then
    return
  end
  local refund = nil
  if (n.spirit or 0) ~= 0 and (SET.refund or 0) > 0 then
    refund = {spirit = n.spirit, count = SET.refund}
  end
  local ok, why = VRFW.recruit.release(n.cards or {n.card}, refund)
  Log("release", MAP.key, i, n.card, tostring(ok), tostring(why))
  CmPages.own = {}
  if not ok then
    funcLuaCommand(C.SE, SE_NG)
    Message(Kit.text(why == "busy" and T.RELEASE_BUSY or T.RELEASE_FAIL))
    return
  end
  funcLuaCommand(C.SE, SE_OK)
  CmPages.recruited()
  Message(Kit.format(T.RELEASE_DONE, n.name))
end
