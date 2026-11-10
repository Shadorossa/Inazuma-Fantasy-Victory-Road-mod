-- Top menu part
BattleBayDeluxe = type(BattleBayDeluxe) == "table" and BattleBayDeluxe or {}


-- On a host whose layers open with the menu group, CMND_OPEN_LAYER does nothing
local function bbt_open_layer(l, i)
  if BattleBayDeluxe.tournament_host.vis_only then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, l, i, true)
    return
  end
  funcLuaMenuCommand(@crc:CMND_OPEN_LAYER@, l, i)
end
local function bbt_close_layer(l, i)
  if BattleBayDeluxe.tournament_host.vis_only then
    funcLuaMenuCommand(@crc:CMND_SET_LAYER_VISIBLE@, l, i, false)
    return
  end
  funcLuaMenuCommand(@crc:CMND_CLOSE_LAYER@, l, i)
end

-- Every instance of the overlay layers (names in BattleBayDeluxe.tournament.L / N).
function BattleBayDeluxe.tournament_each_instance(f)
  for k, n in pairs(BattleBayDeluxe.tournament.N) do
    for i = 0, n - 1 do
      f(BattleBayDeluxe.tournament.L[k], i)
    end
  end
end

function BattleBayDeluxe.tournament_hide(layer, i)
  local C = BattleBayDeluxe.tournament.C
  funcLuaMenuCommand(C.VISIBLE, layer, i, false)
  funcLuaMenuCommand(C.POS, layer, -4000, 4000, 0, i)
end

-- Pieces drawn by one BattleBayDeluxe.tournament_draw
function BattleBayDeluxe.tournament_begin()
  BattleBayDeluxe.tournament_state.used = {}
  for _, l in pairs(BattleBayDeluxe.tournament.L) do
    BattleBayDeluxe.tournament_state.used[l] = 0
  end
  BattleBayDeluxe.tournament_state.taken = {}
end

function BattleBayDeluxe.tournament_end()
  BattleBayDeluxe.tournament_each_instance(function(l, i)
    if not BattleBayDeluxe.tournament_state.taken[tostring(l) .. ":" .. i] then
      BattleBayDeluxe.tournament_hide(l, i)
    end
  end)
end

-- A tinted quad of the mod's drawings centred on (x, y), w x h px
function BattleBayDeluxe.tournament_quad(layer, spr, x, y, w, h, col, prio, atlas)
  local C, G = BattleBayDeluxe.tournament.C, BattleBayDeluxe.tournament.G
  local nk = "icon"
  for k, l in pairs(BattleBayDeluxe.tournament.L) do
    if l == layer and BattleBayDeluxe.tournament.N[k] then
      nk = k
    end
  end
  -- A pool drawn on another one (BattleBayDeluxe.tournament.SHARE) when the menu has none of its own.
  local to = BattleBayDeluxe.tournament.N[nk] <= 0 and BattleBayDeluxe.tournament.SHARE[nk] or nil
  if to ~= nil and BattleBayDeluxe.tournament.L[to] ~= nil and BattleBayDeluxe.tournament.N[to] then
    layer, nk, prio = BattleBayDeluxe.tournament.L[to], to, prio or BattleBayDeluxe.tournament.PRIO[nk]
  end
  local i = VRFW.bracket.take(BattleBayDeluxe.tournament_state, layer)
  if i >= BattleBayDeluxe.tournament.N[nk] then
    return
  end
  -- Connector and box pools carry quads at several depths
  if layer == BattleBayDeluxe.tournament.L.line or layer == BattleBayDeluxe.tournament.L.box then
    local want = prio or BattleBayDeluxe.tournament.PRIO[nk] or BattleBayDeluxe.tournament.PRIO.line
    local key = tostring(layer) .. ":" .. i
    BattleBayDeluxe.tournament_state.prio = BattleBayDeluxe.tournament_state.prio or {}
    if BattleBayDeluxe.tournament_state.prio[key] ~= want then
      BattleBayDeluxe.tournament_state.prio[key] = want
      funcLuaMenuCommand(@crc:CMND_SET_DRAW_PRIORITY@, layer, i, want, true)
    end
  end
  funcLuaMenuCommand(C.VISIBLE, layer, i, true)
  funcLuaMenuCommand(C.SCALE, layer, w / G.Q, h / G.Q, 1, i)
  funcLuaMenuCommand(C.SPRITE, layer, atlas or BattleBayDeluxe.tournament.ART, spr, BattleBayDeluxe.tournament.NODE_QUAD, 0, i)
  funcLuaMenuCommand(C.POS, layer, x, -y, 0, i)
  funcLuaMenuCommand(C.PRIM_COLOR, layer, i, BattleBayDeluxe.tournament.MESH_QUAD, col[1], col[2], col[3])
  return i
end

-- Draws a team plate.
function BattleBayDeluxe.tournament_plate(p, x, y, s, right, champ, fixed)
  local C, L = BattleBayDeluxe.tournament.C, BattleBayDeluxe.tournament.L
  local l = right and L.row_r or L.row_l
  local i = VRFW.bracket.take(BattleBayDeluxe.tournament_state, l, fixed)
  if i >= BattleBayDeluxe.tournament.N[right and "row_r" or "row_l"] then
    return
  end
  local look = champ and "ok" or (p.me and "on" or "off")
  -- A team plate is the team's strip with the name in white.
  local strip = not champ and BattleBayDeluxe.tournament.SPR_STRIP[tonumber(p.strip) or 0] or nil
  if strip then
    look = "off"
  end
  BattleBayDeluxe.tournament_plate_strip(l, i, look == "off" and strip or nil)
  local white = look ~= "off" or strip ~= nil
  funcLuaMenuCommand(C.VISIBLE, l, i, true)
  funcLuaMenuCommand(C.SCALE, l, s, s, 1, i)
  funcLuaMenuCommand(C.POS, l, x, -y, 0, i)
  for k, m in pairs(BattleBayDeluxe.tournament.PLATE) do
    funcLuaMenuCommand(C.MESH_VISIBLE, l, m, k == look, i)
  end
  local name = VRFW.team.name(p.team)
  funcLuaMenuCommand(C.TEXT, l, BattleBayDeluxe.tournament.TXT_ON, white and name or "", i)
  funcLuaMenuCommand(C.TEXT, l, BattleBayDeluxe.tournament.TXT_OFF, white and "" or name, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, BattleBayDeluxe.tournament.TXT_ON, white, i)
  funcLuaMenuCommand(C.TEXT_VISIBLE, l, BattleBayDeluxe.tournament.TXT_OFF, not white, i)
  local c = (p.out and not champ) and BattleBayDeluxe.tournament.G.DIM or 1
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, BattleBayDeluxe.tournament.PLATE[look], c, c, c)
  funcLuaMenuCommand(C.PRIM_COLOR, l, i, BattleBayDeluxe.tournament.MESH_EMBLEM, c, c, c)
  -- A team that is out is drawn faded (the retail locked-dock alpha).
  BattleBayDeluxe.tournament_alpha(l, i, (p.out and not champ) and BattleBayDeluxe.tournament.ADV.OUT_ALPHA or 1)
  VRFW.team.emblem(l, i, p.team, BattleBayDeluxe.tournament_state.emb)
end

-- Swaps the plate sprite for a team strip (spr nil = back to the list plate)
function BattleBayDeluxe.tournament_plate_strip(l, i, spr)
  BattleBayDeluxe.tournament_state.strip = BattleBayDeluxe.tournament_state.strip or {}
  local k = tostring(l) .. ":" .. i
  local want = spr or false
  if BattleBayDeluxe.tournament_state.strip[k] == want then
    return
  end
  BattleBayDeluxe.tournament_state.strip[k] = want
  if spr then
    VRFW.host.menu_command(BattleBayDeluxe.tournament.C.SPRITE, l, BattleBayDeluxe.tournament.ART, spr, BattleBayDeluxe.tournament.PLATE_SPRITE, 0, i)
  else
    VRFW.host.menu_command(BattleBayDeluxe.tournament.C.SPRITE, l, BattleBayDeluxe.tournament.PLATE_ATLAS, BattleBayDeluxe.tournament.PLATE_SPRITE, BattleBayDeluxe.tournament.PLATE_SPRITE, 0, i)
  end
end

-- The player's frame around his plate (left edge x, centre y, scale s) on the box pool
BattleBayDeluxe.tournament.SPR_FRAME = { l = @crc:bbd_tn_frame_l@, r = @crc:bbd_tn_frame_r@ }
BattleBayDeluxe.tournament.FRAME_GROW = { w = 408 / 392, h = 88 / 72 }
function BattleBayDeluxe.tournament_focus(x, y, s, right)
  local G = BattleBayDeluxe.tournament.G
  -- The player's plate gets a gold frame.
  local w, h = G.PLATE_W * s, G.PLATE_H * s
  -- The mirrored plate keeps the left slant
  BattleBayDeluxe.tournament_quad(BattleBayDeluxe.tournament.L.box, BattleBayDeluxe.tournament.SPR_FRAME.l, x + w / 2, y, w * BattleBayDeluxe.tournament.FRAME_GROW.w,
    h * BattleBayDeluxe.tournament.FRAME_GROW.h, BattleBayDeluxe.tournament.WHITE, G.PRIO_BACK)
end

-- An instance's model and name alpha, as the retail team dock does
function BattleBayDeluxe.tournament_alpha(l, i, a)
  VRFW.host.menu_command(@crc:CMND_SET_LAYER_MODEL_ALPHA@, l, i, 0, a)
  VRFW.host.menu_command(@crc:CMND_SET_MENU_TEXT_ALPHA@, l, i, BattleBayDeluxe.tournament.TXT_ON, a)
  VRFW.host.menu_command(@crc:CMND_SET_MENU_TEXT_ALPHA@, l, i, BattleBayDeluxe.tournament.TXT_OFF, a)
end

-- Cached crc32 of a digit sprite name.
function BattleBayDeluxe.tournament_sprite_crc(name)
  BattleBayDeluxe.tournament_state.spr_crc = BattleBayDeluxe.tournament_state.spr_crc or {}
  local c = BattleBayDeluxe.tournament_state.spr_crc[name]
  if c == nil then
    c = BattleBayDeluxe.tournament_crc(name)
    BattleBayDeluxe.tournament_state.spr_crc[name] = c
  end
  return c
end

-- A row of digit sprites centred on (x, y)
function BattleBayDeluxe.tournament_glyphs(parts, x, y, prio)
  local N = BattleBayDeluxe.tournament.NUM
  local total, ws = 0, {}
  for k, p in ipairs(parts) do
    ws[k] = N.W * p[2] / N.H
    total = total + ws[k] * (k < #parts and N.ADV or 1)
  end
  local cx = x - total / 2
  for k, p in ipairs(parts) do
    BattleBayDeluxe.tournament_quad(BattleBayDeluxe.tournament.L.line, BattleBayDeluxe.tournament_sprite_crc(p[1]), cx + ws[k] / 2, y, ws[k], p[2], BattleBayDeluxe.tournament.WHITE, prio or N.PRIO, BattleBayDeluxe.tournament.ART_NUM)
    cx = cx + ws[k] * N.ADV
  end
  return total
end

-- A match score, the upper entrant first
function BattleBayDeluxe.tournament_score(sc)
  if not sc then
    return ""
  end
  local s = string.format("%d-%d", sc.ga or 0, sc.gb or 0)
  if (sc.pa or 0) + (sc.pb or 0) > 0 then
    s = s .. string.format(" (%d-%d)", sc.pa or 0, sc.pb or 0)
  end
  return s
end

-- The knockout tree is drawn by the framework's bracket screen (BattleBayDeluxe.tournament_tree_show).
BattleBayDeluxe.tournament.ADV = { OUT_ALPHA = 0.45 }
