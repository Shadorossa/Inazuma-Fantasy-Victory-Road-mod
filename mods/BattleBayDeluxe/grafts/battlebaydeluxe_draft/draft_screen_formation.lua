-- The Draft screen's formation board (choose the formation of the drafted team) and its mouse input.
BattleBayDeluxe.draft_formation = {
  QUAD = @crc:battlebaydeluxe_fm_quad@, TXT = @crc:battlebaydeluxe_fm_txt@, N_QUAD = 84, N_TXT = 20,
  FORM_INFO = @crc:CMND_GET_SOCCER_FORMATION_INFO@, TEXT_OF = 297699480,
  SPR_BAND = @crc:bbd_pk_band@, SPR_EDGE = @crc:bbd_pk_edge@, SPR_CARD = @crc:bbd_pk_card@, SPR_SEL = @crc:bbd_pk_sel@,
  STYLE_ON_CHOSEN = 2029954615 --[[fs_28_k_cc_2d0_001: centred dark, no outline, on the chosen card's gold]],
  SPR_FRAME = @crc:bbd_pk_frame@, SPR_PITCH = @crc:bbd_pk_pitch@, SPR_DOT = @crc:bbd_pk_flash@,
  -- Quad instance indexes.
  I_BAND = 0, I_EDGE = 1, I_FRAME = 2, I_CARD = 3, I_PITCH = 9, I_DOT = 15,
  -- Text instance indexes.
  T_CARD = 0, T_ARROW = 12, T_PANEL = 14,
  PRIO_STRIP = 750, PRIO_TEXT = 760, PRIO_BOARD = 701,
  -- Layout of the strip (screen pixels, y down).
  STRIP_TOP = 918, STRIP_Y = 1000, VISIBLE = 5, CARD_X0 = 346, CARD_DX = 307, CARD_W = 288, CARD_H = 116,
  FRAME_PAD = 5, MINI_DX = -96, MINI_W = 74, MINI_H = 92, DOT = 9, DOT_PAD = 4, TEXT_DX = 45, TEXT_W = 186,
  LINE1_DY = -25, LINE2_DY = 22, NUM_SCALE = 1.0, NAME_SCALE = 0.78, ARROW_X = 22, ARROW_SCALE = 1.2,
  -- Layout of the board's labels.
  PANEL_X = 215, PANEL_W = 400, PANEL_Y = {590, 637, 690}, PANEL_SCALE = {0.8, 1.1, 0.8},
  -- state
  list = nil, total = 0, sel = 0, from = nil, saved = 0, info = {}, spr = {}, texts = {}, ready = {}, dirty = false,
  opened = false, guideHidden = false,
}

-- Draws a quad at screen pixels (y down) with width w, height h and alpha.
function BattleBayDeluxe.draft_quad_draw(layer, cache, i, x, y, w, h, spr, alpha)
  local P = BattleBayDeluxe.draft_pack
  if cache[i] ~= spr then
    funcLuaMenuCommand(P.SPRITE, layer, P.ART, spr, P.NODE_QUAD, 0, i)
    cache[i] = spr
  end
  funcLuaMenuCommand(P.VISIBLE, layer, i, true)
  funcLuaMenuCommand(P.SCALE, layer, w / P.Q, h / P.Q, 1, i)
  funcLuaMenuCommand(P.POS, layer, x, -y, 0, i)
  funcLuaMenuCommand(P.MODEL_ALPHA, layer, i, 0, alpha)
end

function BattleBayDeluxe.draft_text_set(layer, i, s, style)
  local P = BattleBayDeluxe.draft_pack
  funcLuaMenuCommand(P.TEXT_STYLE, layer, i, P.TXT_ON, style)
  funcLuaMenuCommand(P.TEXT, layer, P.TXT_ON, s, i)
  funcLuaMenuCommand(P.TEXT, layer, P.TXT_OFF, "", i)
  funcLuaMenuCommand(P.TEXT_VISIBLE, layer, P.TXT_ON, true, i)
  funcLuaMenuCommand(P.TEXT_VISIBLE, layer, P.TXT_OFF, false, i)
end

function BattleBayDeluxe.draft_formation_quad(i, x, y, w, h, spr)
  local F, P = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft_pack
  if spr == nil or w <= 0.5 or h <= 0.5 then
    funcLuaMenuCommand(P.VISIBLE, F.QUAD, i, false)
    return
  end
  BattleBayDeluxe.draft_quad_draw(F.QUAD, F.spr, i, x, y, w, h, spr, 1)
end

function BattleBayDeluxe.draft_formation_text(i, s, x, y, scale, style)
  local F, P = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft_pack
  if s == nil or s == "" then
    funcLuaMenuCommand(P.VISIBLE, F.TXT, i, false)
    return
  end
  funcLuaMenuCommand(P.VISIBLE, F.TXT, i, true)
  funcLuaMenuCommand(P.POS, F.TXT, x, -y, 0, i)
  funcLuaMenuCommand(P.SCALE, F.TXT, scale, scale, 1, i)
  style = style or P.STYLE
  local shown = tostring(style) .. ":" .. s
  if F.texts[i] ~= shown then
    BattleBayDeluxe.draft_text_set(F.TXT, i, s, style)
    F.texts[i] = shown
  end
  funcLuaMenuCommand(P.TEXT_ALPHA, F.TXT, i, P.TXT_ON, 1)
end

-- Sets the draw priorities of the layers (OnSetupLayer and OnOpenLayer).
function BattleBayDeluxe.draft_formation_priority(layer, i)
  local F, P = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft_pack
  local prio = F.PRIO_TEXT
  if layer == F.QUAD then
    prio = F.PRIO_STRIP + ((i == F.I_BAND and 0) or (i < F.I_CARD and 1) or (i < F.I_PITCH and 2) or (i < F.I_DOT and 3)
      or 4)
    F.spr[i] = nil
  elseif i >= F.T_PANEL then
    prio = F.PRIO_BOARD
  end
  if layer == F.TXT then
    F.texts[i] = nil
  end
  funcLuaMenuCommand(P.PRIO, layer, i, prio, true)
  funcLuaMenuCommand(P.VISIBLE, layer, i, false)
  F.ready[layer .. ":" .. i] = true
  F.dirty = true
end

function BattleBayDeluxe.draft_formation_load()
  local F, B = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft
  local list, total, current = {}, nil, 0
  local start = 0
  repeat
    local r = table.pack(funcLuaCommand(B.FORMATIONS, start))
    if r[1] ~= true or type(r[2]) ~= "number" then
      return false
    end
    total, current = r[2], type(r[3]) == "number" and r[3] or 0
    for j = 4, r.n do
      list[#list + 1] = r[j]
    end
    start = start + math.max(1, r.n - 3)
  until #list >= total or r.n <= 3
  F.list, F.total, F.sel = list, #list, 0
  for j, id in ipairs(list) do
    if id == current then
      F.sel = j - 1
    end
  end
  return #list > 0
end

-- Reads a formation's card look once per formation.
function BattleBayDeluxe.draft_formation_info(id)
  local F, B = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft
  local inf = F.info[id]
  if inf ~= nil then
    return inf
  end
  local n, list, dots = {0, 0, 0, 0}, {}, {}
  for slot = 0, 10 do
    local ok, pos, x, y = funcLuaCommand(B.PLACE, id, slot)
    if ok == true and type(pos) == "number" then
      if pos >= 1 and pos <= 4 then
        n[pos] = n[pos] + 1
      end
      list[#list + 1] = {slot, slot, pos == 1, x or 0, y or 0}
    end
  end
  -- Draws the dots.
  local L = BattleBayDeluxe.draft_layout
  for _, at in pairs(BattleBayDeluxe.draft_pitch_layout(BattleBayDeluxe.draft_rule_places(id, list))) do
    dots[#dots + 1] = {(at[1] - L.BOX_L) / (L.BOX_R - L.BOX_L), (at[2] - L.BOX_T) / (L.BOX_B - L.BOX_T)}
  end
  local name = BattleBayDeluxe.draft_formation_name(id):gsub("^%s*%d+%-%d+%-%d+%-?%d*%s*", "")
  inf = {nums = string.format("%d-%d-%d", n[4], n[3], n[2]), name = name, dots = dots}
  F.info[id] = inf
  return inf
end

-- a formation's game name (formation info 7 -> its text id -> the text), "" when unknown
function BattleBayDeluxe.draft_formation_name(id)
  local F = BattleBayDeluxe.draft_formation
  local has, tid = VRFW.host.command(F.FORM_INFO, 7, id)
  if not (has == true and type(tid) == "number") then
    return ""
  end
  local s = VRFW.host.command(F.TEXT_OF, tid)
  return (type(s) == "string") and s or ""
end

-- Returns the first card shown.
function BattleBayDeluxe.draft_formation_first()
  local F = BattleBayDeluxe.draft_formation
  return math.max(0, math.min(F.total - F.VISIBLE, F.sel - 1))
end

-- Returns the place of visible card j (0-based).
function BattleBayDeluxe.draft_formation_spot(j)
  local F = BattleBayDeluxe.draft_formation
  return F.CARD_X0 + j * F.CARD_DX, F.STRIP_Y
end

function BattleBayDeluxe.draft_formation_fit(s, scale, w)
  local chars = #(s:gsub("[\128-\191]", ""))
  return math.min(scale, (w or BattleBayDeluxe.draft_formation.TEXT_W) / math.max(1, chars * 13))
end

-- the strip (formation step only)
function BattleBayDeluxe.draft_formation_strip(show)
  local F = BattleBayDeluxe.draft_formation
  if not show or F.list == nil then
    for i = 0, F.I_DOT + 6 * 11 - 1 do
      BattleBayDeluxe.draft_formation_quad(i, 0, 0, 0, 0, nil)
    end
    for i = F.T_CARD, F.T_ARROW + 1 do
      BattleBayDeluxe.draft_formation_text(i, "", 0, 0, 1)
    end
    return
  end
  local h = 1080 - F.STRIP_TOP
  BattleBayDeluxe.draft_formation_quad(F.I_BAND, 960, F.STRIP_TOP + h / 2, 1920, h, F.SPR_BAND)
  BattleBayDeluxe.draft_formation_quad(F.I_EDGE, 960, F.STRIP_TOP, 1920, 4, F.SPR_EDGE)
  local first = BattleBayDeluxe.draft_formation_first()
  local framed = false
  for j = 0, F.VISIBLE - 1 do
    local idx = first + j
    local id = F.list[idx + 1]
    local base = F.I_DOT + j * 11
    if id == nil then
      BattleBayDeluxe.draft_formation_quad(F.I_CARD + j, 0, 0, 0, 0, nil)
      BattleBayDeluxe.draft_formation_quad(F.I_PITCH + j, 0, 0, 0, 0, nil)
      for d = 0, 10 do
        BattleBayDeluxe.draft_formation_quad(base + d, 0, 0, 0, 0, nil)
      end
      BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j, "", 0, 0, 1)
      BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j + 1, "", 0, 0, 1)
    else
      local inf = BattleBayDeluxe.draft_formation_info(id)
      local x, y = BattleBayDeluxe.draft_formation_spot(j)
      local on = idx == F.sel
      if on then
        BattleBayDeluxe.draft_formation_quad(F.I_FRAME, x, y, F.CARD_W + 2 * F.FRAME_PAD, F.CARD_H + 2 * F.FRAME_PAD, F.SPR_FRAME)
        framed = true
      end
      BattleBayDeluxe.draft_formation_quad(F.I_CARD + j, x, y, F.CARD_W, F.CARD_H, on and F.SPR_SEL or F.SPR_CARD)
      local px = x + F.MINI_DX
      BattleBayDeluxe.draft_formation_quad(F.I_PITCH + j, px, y, F.MINI_W, F.MINI_H, F.SPR_PITCH)
      local pad = F.DOT / 2 + F.DOT_PAD
      local left, top = px - F.MINI_W / 2 + pad, y - F.MINI_H / 2 + pad
      local w, hh = F.MINI_W - 2 * pad, F.MINI_H - 2 * pad
      for d = 0, 10 do
        local dot = inf.dots[d + 1]
        if dot ~= nil then
          BattleBayDeluxe.draft_formation_quad(base + d, left + w * math.max(0, math.min(1, dot[1])),
                            top + hh * math.max(0, math.min(1, dot[2])), F.DOT, F.DOT, F.SPR_DOT)
        else
          BattleBayDeluxe.draft_formation_quad(base + d, 0, 0, 0, 0, nil)
        end
      end
      local tx = x + F.TEXT_DX
      local style = on and F.STYLE_ON_CHOSEN or nil
      if inf.name ~= "" then
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j, inf.nums, tx, y + F.LINE1_DY, F.NUM_SCALE, style)
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j + 1, inf.name, tx, y + F.LINE2_DY, BattleBayDeluxe.draft_formation_fit(inf.name, F.NAME_SCALE), style)
      else
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j, inf.nums, tx, y, F.NUM_SCALE, style)
        BattleBayDeluxe.draft_formation_text(F.T_CARD + 2 * j + 1, "", 0, 0, 1)
      end
    end
  end
  if not framed then
    BattleBayDeluxe.draft_formation_quad(F.I_FRAME, 0, 0, 0, 0, nil)
  end
  BattleBayDeluxe.draft_formation_text(F.T_ARROW, first > 0 and "<" or "", F.ARROW_X, F.STRIP_Y, F.ARROW_SCALE)
  BattleBayDeluxe.draft_formation_text(F.T_ARROW + 1, first + F.VISIBLE < F.total and ">" or "", 1920 - F.ARROW_X, F.STRIP_Y, F.ARROW_SCALE)
end

-- Sets the board's labels.
function BattleBayDeluxe.draft_formation_board(show)
  local F, B = BattleBayDeluxe.draft_formation, BattleBayDeluxe.draft
  local line = ""
  if show and B.formation ~= 0 then
    local inf = BattleBayDeluxe.draft_formation_info(B.formation)
    line = inf.name ~= "" and (inf.nums .. " " .. inf.name) or inf.nums
  end
  local texts = {"", line, ""}
  for j = 1, 3 do
    local s = show and texts[j] or ""
    BattleBayDeluxe.draft_formation_text(F.T_PANEL + j - 1, s, F.PANEL_X, F.PANEL_Y[j], BattleBayDeluxe.draft_formation_fit(s, F.PANEL_SCALE[j], F.PANEL_W))
  end
end

function BattleBayDeluxe.draft_formation_render()
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  F.dirty = false
  if not F.opened then
    return
  end
  local strip = B.mode == "formation" or (B.mode == "quit" and B.quitTo == "formation")
  BattleBayDeluxe.draft_formation_strip(strip)
  BattleBayDeluxe.draft_formation_board(B.mode ~= nil and not strip)
end

-- Hides the guide bar while the strip is up (entries emptied, text cleared, every instance hidden).
function BattleBayDeluxe.draft_formation_guide(show)
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  if show == not F.guideHidden then
    return
  end
  F.guideHidden = not show
  if not show then
    VRFW.footer_prompts.set(nil, B.MENU, {}, {guide = B.GUIDE, declared = false})
    pcall(BattleBayDeluxe.draft_guide, "")
  elseif UpdateButtonGuide ~= nil then
    pcall(UpdateButtonGuide, B.MENU, B.GUIDE, false)
  end
  local n = funcLuaMenuCommand(@crc:CMND_GET_CREATE_LAYER_NUM@, B.GUIDE)
  BattleBayDeluxe.draft_layer_visible(B.GUIDE, math.max(1, type(n) == "number" and n or 1), show)
end

-- the pitch laid out for formation id at once (the empty places' colour too), the script untouched until Enter
function BattleBayDeluxe.draft_formation_preview(id)
  local B = BattleBayDeluxe.draft
  B.formation = id
  for k = 0, #B.slots - 1 do
    local rec = B.slots[k + 1]
    if rec.field then
      local ok, pos, x, y = funcLuaCommand(B.PLACE, id, rec.slot)
      if ok == true and type(x) == "number" and type(y) == "number" then
        rec.pos, rec.x, rec.y = pos, x, y
      end
    end
  end
  BattleBayDeluxe.draft_place_field()
  BattleBayDeluxe.draft_draw_pitch()
end

-- Opens the formation step.
function BattleBayDeluxe.draft_formation_open(from)
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  if not BattleBayDeluxe.draft_formation_load() then
    BattleBayDeluxe.draft_log("no formation list: the team's own formation")
    return false
  end
  F.from, F.saved = from, B.formation
  B.mode = "formation"
  BattleBayDeluxe.draft_formation_guide(false)
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_formation_preview(F.list[F.sel + 1])
  BattleBayDeluxe.draft_formation_render()
  BattleBayDeluxe.draft_log("formation step", from, F.total, "formations")
  return true
end

-- Closes the formation step.
function BattleBayDeluxe.draft_formation_close()
  local B = BattleBayDeluxe.draft
  B.mode = "pitch"
  BattleBayDeluxe.draft_formation.from = nil
  BattleBayDeluxe.draft_formation_guide(true)
  BattleBayDeluxe.draft_draw_pitch()
  BattleBayDeluxe.draft_cursor()
  BattleBayDeluxe.draft_show_guide()
  BattleBayDeluxe.draft_formation_render()
end

-- Left / Right on the strip
function BattleBayDeluxe.draft_formation_move(d)
  local F = BattleBayDeluxe.draft_formation
  local to = math.max(0, math.min(F.total - 1, F.sel + d))
  if to == F.sel then
    return
  end
  BattleBayDeluxe.draft_formation_select(to)
end

function BattleBayDeluxe.draft_formation_select(to)
  local F = BattleBayDeluxe.draft_formation
  if to == F.sel or F.list == nil or F.list[to + 1] == nil then
    return
  end
  F.sel = to
  BattleBayDeluxe.draft_formation_preview(F.list[to + 1])
  BattleBayDeluxe.draft_formation_render()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0005@)
end

-- Handles Enter in the formation step.
function BattleBayDeluxe.draft_formation_confirm()
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  local id = F.list and F.list[F.sel + 1]
  if id == nil or funcLuaCommand(B.SET_FORMATION, id) ~= true then
    BattleBayDeluxe.draft_log("formation refused", tostring(id))
    funcLuaCommand(@crc:CMND_SND_PLAY_SE@, B.SE_NG)
    return
  end
  BattleBayDeluxe.draft_load_slots()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0010@ --[[decide]])
  B.sel = BattleBayDeluxe.draft_next_empty(0)
  BattleBayDeluxe.draft_formation_close()
  BattleBayDeluxe.draft_log("formation", id)
end

-- Handles Back in the formation step.
function BattleBayDeluxe.draft_formation_back()
  local B, F = BattleBayDeluxe.draft, BattleBayDeluxe.draft_formation
  if F.from == "start" then
    BattleBayDeluxe.draft_quit_open("formation")
    return
  end
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0006@ --[[back]])
  BattleBayDeluxe.draft_load_slots()
  BattleBayDeluxe.draft_formation_close()
end

-- open / close the step's layers with the Draft's
function BattleBayDeluxe.draft_formation_layers(open)
  local F = BattleBayDeluxe.draft_formation
  if open and not F.opened then
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, F.QUAD)
    funcLuaMenuCommand(@crc:CMND_OPEN_LAYER_ARRAY@, F.TXT)
    F.opened = true
  elseif not open and F.opened then
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, F.QUAD)
    funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER_ARRAY@, F.TXT)
    F.opened = false
    F.spr, F.texts, F.ready = {}, {}, {}
    BattleBayDeluxe.draft_formation_guide(true)
  end
end


--@lib vrfw_menu_kit.lua#Pointer

-- Runs when the screen is opened.
function BattleBayDeluxe.draft_mouse_open()
  local B = BattleBayDeluxe.draft
  local okc, on = VRFW.host.command(B.MOUSE)
  B.mouse = not (okc == true and on == false)
  if B.ptr == nil then
    B.ptr = VRFW.pointer.new()
  end
  B.ptr.reset()
  B.polled = false
  BattleBayDeluxe.draft_log("mouse " .. (B.mouse and "on" or "off (config.toml [draft] mouse)"))
end

function BattleBayDeluxe.draft_select_slot(k)
  local B = BattleBayDeluxe.draft
  if k == B.sel then
    return
  end
  B.sel = k
  BattleBayDeluxe.draft_cursor()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0005@)
end

function BattleBayDeluxe.draft_select_candidate(i)
  local B = BattleBayDeluxe.draft
  if i == B.csel then
    return
  end
  local old = B.csel
  B.csel = i
  BattleBayDeluxe.draft_draw_candidate(old)
  BattleBayDeluxe.draft_draw_candidate(i)
  BattleBayDeluxe.draft_cursor()
  funcLuaCommand(@crc:CMND_SND_PLAY_SE@, @crc:sy0005@)
end

-- Runs once the screen is turned.
function BattleBayDeluxe.draft_mouse_zones()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local Ptr = B.ptr
  Ptr.begin()
  if B.mode == "pitch" or B.mode == "start" then
    for k = 0, #B.slots - 1 do
      local w = B.where[k]
      if w ~= nil and B.ready[w[1] .. ":" .. w[2]] then
        local half = B.slots[k + 1].pos == B.POS_COACH and B.HALF_COACH or B.HALF_SLOT
        Ptr.inst(w[1], w[2], half[1], half[2], k)
      end
    end
  elseif B.mode == "formation" then
    local F = BattleBayDeluxe.draft_formation
    local first = BattleBayDeluxe.draft_formation_first()
    for j = 0, F.VISIBLE - 1 do
      if F.list ~= nil and F.list[first + j + 1] ~= nil then
        local x, y = BattleBayDeluxe.draft_formation_spot(j)
        Ptr.box(x, y, F.CARD_W / 2, F.CARD_H / 2, first + j)
      end
    end
  elseif B.mode == "cands" and not BattleBayDeluxe.draft_pack_busy() then
    local pk = B.pk
    for i = 0, #B.cands - 1 do
      if pk ~= nil and pk.phase == "pick" then
        local x, y = BattleBayDeluxe.draft_pack_spot(i, pk.n)
        local hw, hh = P.CARD_W * P.scale / 2, P.CARD_H * P.scale / 2
        Ptr.box(x + P.CARD_OX * P.scale, y + P.CARD_OY * P.scale - P.SEL_LIFT / 2, hw, hh + P.SEL_LIFT / 2, i)
      elseif pk == nil and B.ready[B.CARD .. ":" .. i] then
        Ptr.inst(B.CARD, i, B.HALF_CAND[1], B.HALF_CAND[2], i)
      end
    end
  end
end

-- Runs once per frame (Step) while the Draft screen takes input.
function BattleBayDeluxe.draft_mouse()
  local B = BattleBayDeluxe.draft
  local live = B.mouse and B.ptr ~= nil and B.quitCo == nil
    and (B.mode == "pitch" or B.mode == "start" or B.mode == "cands" or B.mode == "formation")
    and not (B.pk ~= nil and B.pk.phase == "outro")
  if not live then
    B.polled = false
    return
  end
  B.mouseDecided = false
  local Ptr = B.ptr
  if not B.polled then
    B.polled = true
    Ptr.reset()
    return
  end
  BattleBayDeluxe.draft_mouse_zones()
  local ev = Ptr.poll()
  if B.mode == "cands" and BattleBayDeluxe.draft_pack_busy() then
    if ev.click ~= nil or ev.miss then
      B.mouseDecided = true
      BattleBayDeluxe.draft_decide() -- a click during the deal: all 5 at once, as Enter
    end
    return
  end
  if ev.hover ~= nil then
    if B.mode == "formation" then
      BattleBayDeluxe.draft_formation_select(ev.hover)
    elseif B.mode == "cands" then
      BattleBayDeluxe.draft_select_candidate(ev.hover)
    else
      BattleBayDeluxe.draft_select_slot(ev.hover)
    end
  end
  if ev.click ~= nil then
    if B.mode == "formation" then
      BattleBayDeluxe.draft_formation_select(ev.click)
    elseif B.mode == "cands" then
      BattleBayDeluxe.draft_select_candidate(ev.click)
    else
      BattleBayDeluxe.draft_select_slot(ev.click)
    end
    B.mouseDecided = true
    BattleBayDeluxe.draft_decide()
    -- Forgets the pointer zones because the screen may change under the pointer (the pack, the pitch again).
    Ptr.forget()
  end
end
