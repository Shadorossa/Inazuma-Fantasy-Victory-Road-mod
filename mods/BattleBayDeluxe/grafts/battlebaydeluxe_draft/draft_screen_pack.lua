-- The Draft screen's pack opening: the five candidates dealt, revealed and picked with their animation.

function BattleBayDeluxe.draft_pack_look()
  local P = BattleBayDeluxe.draft_pack
  if P.loaded then
    return
  end
  P.loaded = true
  local ok, r = pcall(function()
    return table.pack(funcLuaCommand(P.CMD))
  end)
  if not ok or type(r) ~= "table" or r[1] ~= true then
    BattleBayDeluxe.draft_log("pack look: defaults (no CMND_BATTLEBAYDELUXE_DRAFT_PACK answer)")
    return
  end
  local keys = {"intro", "deal", "deal_stagger", "flip", "settle", "flash", "gap", "suspense", "outro", "dim", "scale",
                "spacing", "se_open", "se_deal", "se_reveal", "se_best"}
  for i, k in ipairs(keys) do
    local v = r[i + 1]
    if type(v) == "number" then
      P[k] = v
    end
  end
  BattleBayDeluxe.draft_log("pack look", P.intro, P.flip, P.gap, P.dim, P.scale, P.spacing)
end

function BattleBayDeluxe.draft_pack_frames(sec)
  return math.max(1, math.floor(sec * BattleBayDeluxe.draft_pack.FPS + 0.5))
end

local function clamp01(u)
  if u < 0 then
    return 0
  elseif u > 1 then
    return 1
  end
  return u
end

local function ease_out_cubic(u)
  u = 1 - clamp01(u)
  return 1 - u * u * u
end

local function ease_out_back(u)
  u = clamp01(u) - 1
  local c = 1.70158
  return 1 + (c + 1) * u * u * u + c * u * u
end

function BattleBayDeluxe.draft_pack_se(id)
  if type(id) == "number" and id ~= 0 then
    VRFW.host.command(BattleBayDeluxe.draft_pack.SE, id)
  end
end

function BattleBayDeluxe.draft_pack_quad(i, x, y, w, h, spr, a)
  local P = BattleBayDeluxe.draft_pack
  if a <= 0.001 or w <= 0.5 or h <= 0.5 then
    funcLuaMenuCommand(P.VISIBLE, P.QUAD, i, false)
    return
  end
  BattleBayDeluxe.draft_quad_draw(P.QUAD, P.spr, i, x, y, w, h, spr, math.min(1, a))
end

function BattleBayDeluxe.draft_pack_text(i, s, x, y, scale, a)
  local P = BattleBayDeluxe.draft_pack
  if s == nil or s == "" or a <= 0.001 then
    funcLuaMenuCommand(P.VISIBLE, P.TXT, i, false)
    return
  end
  local pk = BattleBayDeluxe.draft.pk
  funcLuaMenuCommand(P.VISIBLE, P.TXT, i, true)
  funcLuaMenuCommand(P.POS, P.TXT, x, -y, 0, i)
  funcLuaMenuCommand(P.SCALE, P.TXT, scale, scale, 1, i)
  if pk == nil or pk.texts[i] ~= s then
    BattleBayDeluxe.draft_text_set(P.TXT, i, s, P.STYLE)
    if pk ~= nil then
      pk.texts[i] = s
    end
  end
  funcLuaMenuCommand(P.TEXT_ALPHA, P.TXT, i, P.TXT_ON, a)
end

-- every quad and text of the pack hidden
function BattleBayDeluxe.draft_pack_hide_all()
  local P = BattleBayDeluxe.draft_pack
  for i = 0, P.N_QUAD - 1 do
    VRFW.host.menu_command(P.VISIBLE, P.QUAD, i, false)
  end
  for i = 0, P.N_TXT - 1 do
    VRFW.host.menu_command(P.VISIBLE, P.TXT, i, false)
  end
  for i = 0, P.N_CREST - 1 do
    VRFW.host.menu_command(P.VISIBLE, P.CREST, i, false)
  end
end

-- a name's estimated width in px at scale 1
function BattleBayDeluxe.draft_pack_name_width(s)
  local units = 0
  for ch in s:gmatch("[^\128-\191][\128-\191]*") do
    units = units + (#ch >= 3 and 2 or 1)
  end
  return units * BattleBayDeluxe.draft_pack.GLYPH
end

-- Returns the row under card c, whose card centre is x.
function BattleBayDeluxe.draft_pack_row(c, x)
  local P = BattleBayDeluxe.draft_pack
  local w = BattleBayDeluxe.draft_pack_name_width(c.name)
  local row = P.spacing - P.ROW_MARGIN
  local room = c.crest and (row - P.ROW_CREST - P.ROW_GAP) or row
  c.ns = math.max(P.NAME_MIN, math.min(P.NAME_SCALE, room / math.max(1, w)))
  c.nx = x
  if c.crest then
    local nw = w * c.ns
    local left = x - (P.ROW_CREST + P.ROW_GAP + nw) / 2
    c.cx = left + P.ROW_CREST / 2
    c.nx = left + P.ROW_CREST + P.ROW_GAP + nw / 2
  end
end

-- Returns card c's crest at the start of a pack.
function BattleBayDeluxe.draft_pack_crest(c, x, y)
  local P = BattleBayDeluxe.draft_pack
  local i = c.i
  local team = c.team or 0
  local has, icon = false, 0
  if team ~= 0 and VRFW.team ~= nil then
    has, icon = VRFW.host.command(VRFW.team.TEAM_INFO, team, 6, 0)
  end
  c.crest = has == true and (icon or 0) ~= 0
  BattleBayDeluxe.draft_pack_row(c, x)
  funcLuaMenuCommand(P.VISIBLE, P.CREST, i, false)
  if not c.crest then
    if VRFW.team ~= nil then
      VRFW.team.emblem_reset(P.CREST, i, P.crests)
    end
    return
  end
  for _, m in ipairs(P.CREST_HIDE) do
    funcLuaMenuCommand(P.MESH_VISIBLE, P.CREST, m, false, i)
  end
  funcLuaMenuCommand(P.TEXT_VISIBLE, P.CREST, P.TXT_ON, false, i)
  funcLuaMenuCommand(P.TEXT_VISIBLE, P.CREST, P.TXT_OFF, false, i)
  local s = P.ROW_CREST / P.CREST_PX
  funcLuaMenuCommand(P.SCALE, P.CREST, s, s, 1, i)
  funcLuaMenuCommand(P.POS, P.CREST, c.cx - P.CREST_CX * s, -y, 0, i)
  VRFW.team.emblem(P.CREST, i, team, P.crests)
  c.wait, c.ca = P.CREST_WAIT, 0
end

-- Shows card c's crest at alpha a, as its name.
function BattleBayDeluxe.draft_pack_crest_show(c, a)
  local P = BattleBayDeluxe.draft_pack
  if not c.crest or c.ca == a then
    return
  end
  if a <= 0.001 then
    funcLuaMenuCommand(P.VISIBLE, P.CREST, c.i, false)
    c.ca = 0
    return
  end
  if c.wait > 0 then
    local loading = VRFW.host.menu_command(P.LOADING, P.CREST, c.i)
    if loading == true then
      c.wait = c.wait - 1
      return
    end
    c.wait = 0
  end
  if c.ca == 0 then
    funcLuaMenuCommand(P.VISIBLE, P.CREST, c.i, true)
  end
  funcLuaMenuCommand(P.MODEL_ALPHA, P.CREST, c.i, 0, a)
  c.ca = a
end

-- Sets the draw priorities of the pack layers (OnSetupLayer and OnOpenLayer).
function BattleBayDeluxe.draft_pack_priority(layer, i)
  local P = BattleBayDeluxe.draft_pack
  local prio = 740
  if layer == P.CREST then
    if VRFW.team ~= nil then
      VRFW.team.emblem_forget(layer, i, P.crests)
    end
  elseif layer == P.QUAD then
    if i == P.I_DIM then
      prio = 705
    elseif i == P.I_BAND then
      prio = 706
    elseif i < P.I_GLOW then
      prio = 707
    elseif i < P.I_FLASH then
      prio = 712
    elseif i < P.I_SCREEN then
      prio = 726
    else
      prio = 745
    end
    funcLuaMenuCommand(P.SPRITE, layer, P.ART, P.COL_DIM, P.NODE_QUAD, 0, i)
    P.spr[i] = P.COL_DIM
  end
  funcLuaMenuCommand(P.PRIO, layer, i, prio, true)
  funcLuaMenuCommand(P.VISIBLE, layer, i, false)
end

-- Computes the band's geometry for the look's card scale.
function BattleBayDeluxe.draft_pack_band()
  local P = BattleBayDeluxe.draft_pack
  local h = P.CARD_H * P.scale + 280
  return P.CY, h, P.CY - h / 2
end

function BattleBayDeluxe.draft_pack_spot(i, n)
  local P = BattleBayDeluxe.draft_pack
  return P.CX + (i - (n - 1) / 2) * P.spacing, P.CY
end

-- a candidate card at (x, y) screen px (y down), scale sx x sy
function BattleBayDeluxe.draft_pack_card(i, x, y, sx, sy)
  local B = BattleBayDeluxe.draft
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CARD, x, -y, 0, i)
  funcLuaMenuCommand(3362798188, B.CARD, i, math.max(0.001, sx), math.max(0.001, sy))
end

function BattleBayDeluxe.draft_pack_face(c, state)
  local B = BattleBayDeluxe.draft
  local i = c.i
  if c.state == state or not B.ready[B.CARD .. ":" .. i] then
    return
  end
  c.state = state
  if state == "none" then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
  elseif state == "back" then
    BattleBayDeluxe.draft_empty_card(B.CARD, i, nil, true)
  else
    BattleBayDeluxe.draft_filled_card(B.CARD, i, c.param, c.pos)
  end
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_MODEL_ALPHA@, B.CARD, i, 0, 1)
end

-- Starts a new pack for the current candidates (B.cands).
function BattleBayDeluxe.draft_pack_start()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  BattleBayDeluxe.draft_pack_look()
  if B.pk ~= nil then
    BattleBayDeluxe.draft_pack_end()
  end
  local n = #B.cands
  local pk = {cards = {}, order = {}, f = 0, phase = "anim", texts = {}, best = nil, n = n}
  for i = 0, n - 1 do
    local p = B.cands[i + 1]
    local ok, r = VRFW.host.command(P.CHARA_INFO, p.param, 8)
    local rar = (ok and type(r) == "number") and r or 0
    local ok2, name = VRFW.host.command(P.CHARA_INFO, p.param, 0)
    name = (ok2 and type(name) == "string") and name or ""
    pk.cards[i + 1] = {i = i, param = p.param, pos = p.pos, team = p.team, rarity = rar, name = name, state = nil}
    pk.order[#pk.order + 1] = i + 1
    local cx, cy = BattleBayDeluxe.draft_pack_spot(i, n)
    BattleBayDeluxe.draft_pack_crest(pk.cards[i + 1], cx + P.CARD_OX * P.scale,
                       cy + (P.CARD_OY + P.CARD_H / 2) * P.scale + P.ROW_Y)
  end
  table.sort(pk.order, function(a, b)
    local ra, rb = pk.cards[a].rarity, pk.cards[b].rarity
    if ra ~= rb then
      return ra < rb
    end
    return a < b
  end)
  if n >= 2 then
    local last, prev = pk.cards[pk.order[n]], pk.cards[pk.order[n - 1]]
    if last.rarity > prev.rarity then
      pk.best = pk.order[n]
    end
  end
  -- the frame plan
  local F = BattleBayDeluxe.draft_pack_frames
  local intro, deal, stag = F(P.intro), F(P.deal), F(P.deal_stagger)
  local flip, settle, gap = F(P.flip), F(P.settle), F(P.gap)
  pk.intro = intro
  for i = 0, n - 1 do
    pk.cards[i + 1].deal = intro + i * stag
  end
  local t = intro + (n - 1) * stag + deal + F(P.PAUSE)
  for r, k in ipairs(pk.order) do
    if k == pk.best then
      t = t + F(P.suspense)
    end
    pk.cards[k].turn = t
    if r < n then
      t = t + gap
    end
  end
  pk.dealLen, pk.flip, pk.settle, pk.flash = deal, flip, settle, F(P.flash)
  pk.done = t + flip + settle
  -- Sets the band's title.
  local rec = B.slots[B.k + 1]
  pk.title = rec ~= nil and BattleBayDeluxe.draft_text(B.TXT_POS[rec.pos or 0]) or ""
  pk.cur = nil
  B.pk = pk
  for i = 0, P.N_QUAD - 1 do
    pcall(BattleBayDeluxe.draft_pack_priority, P.QUAD, i)
  end
  for i = 0, n - 1 do
    funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, B.CARD, i, P.CARD_PRIO, true)
    BattleBayDeluxe.draft_pack_face(pk.cards[i + 1], "none")
  end
  for i = n, 4 do
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
  end
  BattleBayDeluxe.draft_pack_se(P.se_open)
  BattleBayDeluxe.draft_log("pack", B.k, "cards", n, "best", tostring(pk.best and pk.cards[pk.best].param), "frames", pk.done)
  BattleBayDeluxe.draft_pack_render(false)
end

-- Renders the pack at its frame pk.f.
function BattleBayDeluxe.draft_pack_render(quiet)
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local pk = B.pk
  if pk == nil then
    return
  end
  local f, n, S = pk.f, pk.n, P.scale
  local cy, bh, btop = BattleBayDeluxe.draft_pack_band()
  -- the darkness and the band
  local u = ease_out_cubic(f / pk.intro)
  BattleBayDeluxe.draft_pack_quad(P.I_DIM, P.CX, P.CY, 2700, 1300, P.COL_DIM, P.dim * u)
  BattleBayDeluxe.draft_pack_quad(P.I_BAND, P.CX, cy, 2700, bh * u, P.COL_BAND, P.BAND_ALPHA * math.min(1, u * 1.5))
  local ew = 2200 * u
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE, P.CX, cy - bh * u / 2, ew, 4, P.COL_EDGE, u)
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE + 1, P.CX, cy + bh * u / 2, ew, 4, P.COL_EDGE, u)
  BattleBayDeluxe.draft_pack_text(0, pk.title, P.CX, btop + 46, 1.1, u)
  local screen = 0
  for k = 1, n do
    local c = pk.cards[k]
    local x, y = BattleBayDeluxe.draft_pack_spot(c.i, n)
    local best = k == pk.best
    local want, sx, sy, cx, cyy = "none", S, S, x, y
    local glow, flash = 0, 0
    if f >= c.deal then
      want = "back"
      local d = (f - c.deal) / pk.dealLen
      if d < 1 then
        local e = ease_out_cubic(d)
        cx = P.CX + (x - P.CX) * e
        cyy = 1180 + (y - 1180) * e
        local s = S * (0.55 + 0.45 * ease_out_back(d))
        sx, sy = s, s
      elseif f < c.turn and best and f >= c.turn - BattleBayDeluxe.draft_pack_frames(P.suspense) then
        -- the best card throbs while it waits
        local w = 1 + 0.05 * math.sin((f - c.turn) * 0.9)
        sx, sy = S * w, S * w
        glow = 0.5 * clamp01(1 - (c.turn - f) / BattleBayDeluxe.draft_pack_frames(P.suspense))
      end
      if c.deal == f and not quiet then
        BattleBayDeluxe.draft_pack_se(P.se_deal)
      end
    end
    if f >= c.turn then
      local v = (f - c.turn) / pk.flip
      local over = best and P.OVER_BEST or P.OVER
      if v < 1 then
        local o = v < 0.5 and (1 + 0.12 * v) or (1 + over * (2 * v - 1))
        sx = S * math.abs(math.cos(math.pi * v)) * o
        sy = S * o
        if v >= 0.5 then
          want = "face"
        end
      else
        want = "face"
        local w = (f - c.turn - pk.flip) / pk.settle
        local o = 1 + over * (1 - ease_out_cubic(w))
        sx, sy = S * o, S * o
      end
      if want == "face" then
        local tf = f - (c.turn + math.floor(pk.flip / 2))
        flash = 0.9 * (1 - clamp01(tf / pk.flash)) ^ 2
        glow = clamp01(tf / 12)
        if best then
          screen = math.max(screen, P.SCREEN_ALPHA * (1 - clamp01(tf / (pk.flash * 1.5))) ^ 2)
        end
        if c.state ~= "face" and not quiet then
          BattleBayDeluxe.draft_pack_se(best and P.se_best or P.se_reveal)
        end
      end
    end
    if pk.phase == "pick" then
      want, flash, glow = "face", 0, 1
      local on = c.i == B.csel
      local g = on and P.SEL_GROW or 1
      sx, sy, cx, cyy = S * g, S * g, x, y - (on and P.SEL_LIFT or 0)
      if on then
        glow = 1.6
      end
    end
    BattleBayDeluxe.draft_pack_face(c, want)
    c.x, c.y, c.s = cx, cyy, sy
    if want ~= "none" then
      BattleBayDeluxe.draft_pack_card(c.i, cx, cyy, sx, sy)
      if want == "back" then
        BattleBayDeluxe.draft_rehide(B.CARD, c.i) -- a late face load must not show through the back
      end
    end
    local cw, ch = P.CARD_W * S, P.CARD_H * S
    -- Draws no tile behind a plain card (GLOW_ALPHA 0).
    local gcol, ga = P.COL_GLOW, P.GLOW_ALPHA
    if best then
      gcol, ga = P.COL_GOLD, P.GOLD_ALPHA * (0.85 + 0.15 * math.sin(f * 0.15))
    end
    local gx, gy = cx + P.CARD_OX * sy, cyy + P.CARD_OY * sy
    BattleBayDeluxe.draft_pack_quad(P.I_GLOW + c.i, gx, gy, cw * 1.16, ch * 1.16, gcol, math.min(1, ga * glow))
    BattleBayDeluxe.draft_pack_quad(P.I_FLASH + c.i, gx, gy, cw * (1.25 - 0.25 * flash), ch * (1.25 - 0.25 * flash), P.COL_FLASH,
                      flash)
    local na = want == "face" and clamp01((f - c.turn - pk.flip) / 9) or 0
    if pk.phase == "pick" then
      na = 1
    end
    BattleBayDeluxe.draft_pack_text(1 + c.i, c.name, c.nx, y + P.CARD_OY * S + ch / 2 + P.ROW_Y, c.ns, na)
    BattleBayDeluxe.draft_pack_crest_show(c, na)
  end
  for i = n, 4 do
    BattleBayDeluxe.draft_pack_quad(P.I_GLOW + i, 0, 0, 0, 0, P.COL_GLOW, 0)
    BattleBayDeluxe.draft_pack_quad(P.I_FLASH + i, 0, 0, 0, 0, P.COL_FLASH, 0)
    BattleBayDeluxe.draft_pack_text(1 + i, "", 0, 0, 1, 0)
  end
  BattleBayDeluxe.draft_pack_quad(P.I_SCREEN, P.CX, P.CY, 2700, 1300, P.COL_SCREEN, screen)
  -- the skip line only while the cards are dealt and turned
  local hint = pk.phase ~= "pick" and BattleBayDeluxe.draft_text(P.TXT_SKIP) or ""
  BattleBayDeluxe.draft_pack_text(6, hint, P.CX, btop + bh + 44, 0.8, u * 0.85)
  if pk.phase == "pick" then
    BattleBayDeluxe.draft_pack_cursor()
  end
end

-- Draws the cursor arrow on the pack's focused card (pick phase).
function BattleBayDeluxe.draft_pack_cursor()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local pk = B.pk
  if pk == nil or pk.phase ~= "pick" then
    return
  end
  local c = pk.cards[B.csel + 1]
  if c == nil or c.x == nil then
    return
  end
  local s = c.s or P.scale
  local x = c.x + (P.CARD_OX - P.CARD_W / 2) * s - P.CUR_DX
  local y = c.y + (P.CARD_OY + P.CUR_DY) * s
  local key = math.floor(x + 0.5) .. ":" .. math.floor(y + 0.5)
  if pk.cur == key then
    return
  end
  pk.cur = key
  B.curMoved = true
  funcLuaMenuCommand(@crc:CMND_SET_LAYER_LOCAL_POS@, B.CURSOR, x, -y, 0, 0)
end

-- Runs when the animation is over (its end or a skip).
function BattleBayDeluxe.draft_pack_done(skipped)
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  if pk == nil or pk.phase ~= "anim" then
    return
  end
  pk.f = math.max(pk.f, pk.done)
  pk.phase = "pick"
  BattleBayDeluxe.draft_pack_render(true)
  BattleBayDeluxe.draft_cursor()
  if skipped then
    BattleBayDeluxe.draft_pack_se(BattleBayDeluxe.draft_pack.se_reveal)
    BattleBayDeluxe.draft_log("pack skipped")
  end
end

function BattleBayDeluxe.draft_pack_outro(k, i)
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  if pk == nil then
    return
  end
  pk.phase = "outro"
  pk.of = 0
  pk.olen = BattleBayDeluxe.draft_pack_frames(BattleBayDeluxe.draft_pack.outro)
  pk.pick = i
  pk.to = B.pos[k]
end

function BattleBayDeluxe.draft_pack_outro_render()
  local B, P = BattleBayDeluxe.draft, BattleBayDeluxe.draft_pack
  local pk = B.pk
  local u = clamp01(pk.of / pk.olen)
  local e = ease_out_cubic(u)
  local a = 1 - e
  local cy, bh, btop = BattleBayDeluxe.draft_pack_band()
  BattleBayDeluxe.draft_pack_quad(P.I_DIM, P.CX, P.CY, 2700, 1300, P.COL_DIM, P.dim * a)
  BattleBayDeluxe.draft_pack_quad(P.I_BAND, P.CX, cy, 2700, bh * a, P.COL_BAND, P.BAND_ALPHA * a)
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE, P.CX, cy - bh * a / 2, 2200 * a, 4, P.COL_EDGE, a)
  BattleBayDeluxe.draft_pack_quad(P.I_EDGE + 1, P.CX, cy + bh * a / 2, 2200 * a, 4, P.COL_EDGE, a)
  BattleBayDeluxe.draft_pack_text(0, pk.title, P.CX, btop + 46, 1.1, a)
  BattleBayDeluxe.draft_pack_text(6, "", 0, 0, 1, 0)
  BattleBayDeluxe.draft_pack_quad(P.I_SCREEN, 0, 0, 0, 0, P.COL_SCREEN, 0)
  for k = 1, pk.n do
    local c = pk.cards[k]
    local x, y = BattleBayDeluxe.draft_pack_spot(c.i, pk.n)
    BattleBayDeluxe.draft_pack_quad(P.I_FLASH + c.i, 0, 0, 0, 0, P.COL_FLASH, 0)
    BattleBayDeluxe.draft_pack_text(1 + c.i, c.name, c.nx, y + (P.CARD_OY + P.CARD_H / 2) * P.scale + P.ROW_Y, c.ns, a)
    BattleBayDeluxe.draft_pack_crest_show(c, a)
    if c.i == pk.pick and pk.to ~= nil then
      local tx, ty = pk.to[1], -pk.to[2]
      local cx, cyy = x + (tx - x) * e, (y - P.SEL_LIFT) + (ty - (y - P.SEL_LIFT)) * e
      local land = B.SLOT_SCALE * P.LAND -- the large card lands at the small slot card's size
      local s = P.scale * P.SEL_GROW + (land - P.scale * P.SEL_GROW) * e
      BattleBayDeluxe.draft_pack_card(c.i, cx, cyy, s, s)
      BattleBayDeluxe.draft_pack_quad(P.I_GLOW + c.i, cx + P.CARD_OX * s, cyy + P.CARD_OY * s, P.CARD_W * s * 1.16,
                        P.CARD_H * s * 1.16, P.COL_EDGE, 0.5 * a)
    else
      local s = P.scale * (1 - 0.3 * e)
      BattleBayDeluxe.draft_pack_card(c.i, x, y, s, s)
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_MODEL_ALPHA@, B.CARD, c.i, 0, a)
      BattleBayDeluxe.draft_pack_quad(P.I_GLOW + c.i, 0, 0, 0, 0, P.COL_GLOW, 0)
    end
  end
end

-- Ends the pack.
function BattleBayDeluxe.draft_pack_end()
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  B.pk = nil
  BattleBayDeluxe.draft_pack_hide_all()
  if pk ~= nil then
    for k = 1, pk.n do
      local i = pk.cards[k].i
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_MODEL_ALPHA@, B.CARD, i, 0, 1)
      if B.mode ~= "cands" then
        VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, B.CARD, i, false)
      end
    end
  end
end

-- one frame of the pack (Step)
function BattleBayDeluxe.draft_pack_step()
  local B = BattleBayDeluxe.draft
  local pk = B.pk
  if pk == nil then
    return
  end
  if pk.phase == "anim" then
    pk.f = pk.f + 1
    if pk.f >= pk.done then
      BattleBayDeluxe.draft_pack_done(false)
    else
      BattleBayDeluxe.draft_pack_render(false)
    end
  elseif pk.phase == "pick" then
    pk.f = pk.f + 1
    BattleBayDeluxe.draft_pack_render(true) -- the best card's glow keeps breathing
  elseif pk.phase == "outro" then
    pk.of = pk.of + 1
    if pk.of >= pk.olen then
      BattleBayDeluxe.draft_pack_end()
    else
      BattleBayDeluxe.draft_pack_outro_render()
    end
  end
end

-- the animation runs (input = skip)
function BattleBayDeluxe.draft_pack_busy()
  local pk = BattleBayDeluxe.draft.pk
  return pk ~= nil and pk.phase == "anim"
end
