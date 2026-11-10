-- vrfw_bracket_menu: the knockout bracket screen (its [[screen]] in content\menus\bracket.toml).
INCLUDE("LUA_PROG_BASE")

local function Crc(text)
  return VRFW.ids.crc32(text)
end

local MENU_NAME = "vrfw_bracket_menu"

-- engine commands by name (crc32 at first use); the unnamed ones are the retail Lua's numbers
local CMD = {
  VISIBLE = "CMND_SET_LAYER_VISIBLE", POS = "CMND_SET_LAYER_LOCAL_POS", SCALE = "CMND_SET_LAYER_LOCAL_SCALE",
  PRIM_COLOR = "CMND_SET_PRIM_COLOR", MESH_VISIBLE = "CMND_SET_MESH_VISIBLE", TEXT = "CMND_SET_MENU_TEXT_STRING",
  TEXT_VISIBLE = "CMND_SET_MENU_TEXT_VISIBLE", MODEL_ALPHA = "CMND_SET_LAYER_MODEL_ALPHA",
  TEXT_ALPHA = "CMND_SET_MENU_TEXT_ALPHA", PRIORITY = "CMND_SET_DRAW_PRIORITY", LAYER_NUM = "CMND_GET_CREATE_LAYER_NUM",
  GROUP_INDEX = "CMND_GET_GROUP_INDEX", PRIM_INDEX = "CMND_SEARCH_PRIM_INDEX", TEXT_GET = "CMND_TEXT_GET",
  MAP_NAME = "CMND_GET_MAP_NAME", LOAD_TEX = "CMND_LOAD_MENU_RES_TEXTURE",
}
local N_CMD = {
  SPRITE = 558735651,
  TEXT_VALUE = 910683996,      -- (text, tag, n, …): the text with <tag> filled
  FRAME_TIME = 1549797111,     -- the frame's time step (s)
  TEX_LOADING = 1506186496,    -- texture still loading?
  GLOBAL_POS = 4002164178,
  RATE_BIND = 541357333, RATE_SET = 1595998683,           -- a MenuRateSetting bound to an animation group / set
  NUM_SHOW = 1233047821, NUM_SET = 3609943765,           -- a number setting shown / its value
}
local function K(name)
  return Crc(CMD[name])
end
local function M(name, ...)
  return funcLuaMenuCommand(K(name), ...)
end

local POOL_NAME = {
  line = "vrfw_bracket_line",
  row_l = "vrfw_bracket_row_l",
  row_r = "vrfw_bracket_row_r",     -- the mirrored plate (right side)
  box = "vrfw_bracket_box",
  crest = "vrfw_bracket_crest",
  icon = "vrfw_bracket_icon",       -- the champion's crown (a tree without the retail trophy)
  stadium_panel = "vrfw_bracket_stadium",
}
local N = {}
local ROW_CHAMP = -1

-- the retail art's layers (retail layer names: the base attaches them by name) and their retail draw priorities
local RETAIL_NAME = {
  base = "vroad04_01_tournament_base", trophy = "vroad04_02_trophy", star = "vroad04_04_light_on_line",
  sched = "vroad04_09_schedule_for_spectator",
  score = { "vroad04_07_tounament_score_round01", "vroad04_07_tounament_score_round02",
    "vroad04_07_tounament_score_round03", "vroad04_07b_tounament_score_final" },
}
local RETAIL_PRIO = { base = 197, line = 201, star = 201, score = 202, trophy = 203, sched = 201, stadium_panel = 201 }

local RETAIL = {
  ROUNDS = 4, STARS = 16, SCORES = { 8, 4, 2, 1 },
  RATE_MOVE = 4013832056,          -- the strips' MenuRateSetting "move"
  ANIM_LINE = "line",              -- its animation group
  NUM_A = 2710162575, NUM_B = 947952949,
  FLAG = { left = { "_icon_flag_l01", "_icon_flag_l02" }, right = { "_icon_flag_r01", "_icon_flag_r02" } },
  FLAG_FINAL = { "_icon_flag_l01", "_icon_flag_r01" },
  FLAG_ALL = { "_icon_flag_l01", "_icon_flag_l02", "_icon_flag_r01", "_icon_flag_r02" },
  TXT_ROUND = "_text_time01_01", TXT_PLAYED = "_text_time01_02", TXT_NEXT = "_text_now01", TXT_SPARE = "_text_time02",
  NAME_X_L = 363, NAME_X_R = 1557, NAME_Y0 = 288, NAME_STEP = 72, STRIP_IN = 137,
  PLATE_S = 0.6, PLATE_GAP = 6,
  MESH_TREE = "_tournament01",     -- the base's unlit 16-team bracket mesh
  TROPHY_NODE_Y = 381,             -- the base's _atc_trophy01, screen px
  CHAMP_Y = 206,                   -- the champion's plate, above the trophy
}

local ART = 3201721854
local ART_NUM = 4021109445
local PLATE_ATLAS = 143680280
local NODE_QUAD, MESH_QUAD = "icon_new01", "_icon_new01"
local WHITE = { 1, 1, 1 }

-- the geometry, screen px (y down) of the 1920 x 1080 menu camera
local G = {
  W = 1920, TOP = 136, BOTTOM = 1004, MARGIN = 34, CX = 960, PLATE_W = 520, PLATE_H = 72, FILL = 0.84,
  SCALE_MAX = 1.0, GAP = 16, Q = 36, LINE = 6, LINE_LIT = 10, CHAMP_Y = 176, CHAMP_S = 0.85, CROWN_W = 72,
  CROWN_H = 54, DIM = 0.5,
  TROPHY_Y = 300, STAR = 1.8, STAR_MIN = 32, STAR_MAX = 64,
  TURN_R = 8, TURN_LEN = 120, TROPHY_CUP_BOTTOM = 38, PRIO_BACK = 546,
  CORNER_OVERLAP = 4, CHUNK = 48,
}
local NUM = { W = 22, H = 29, GAP = 32, PAIR_H = 90, HEIGHT = 0.55, H_MIN = 13, H_MAX = 26, SPACE = 4, ADV = 0.78,
  PEN_S = 0.75, FINAL_S = 1.3, PRIO = 548 }
-- the advance and the crests at the joints
local ADV = {
  DUR = 0.65, STAGGER = 0.06, STAGGER_ALL = 0.4,
  CREST_W = 68, CREST_X = 56, CREST_X_R = 464, OUT_ALPHA = 0.45,
  BIG_OF = 0.5, BIG_GAP = 8, BIG_MIN = 24, BIG_MAX = 72, CREST_PRIO = 550,
}
local LINE_PRIO, BOX_PRIO = 549, 552
-- the final stadium's panel
local STADIUM = { Y = 958, PANEL_W = 394, THUMB_W = 128, THUMB_H = 72, PAD = 8, LOAD_MIN = 10, LOAD_MAX = 600,
  PICTURE_DIR = "#/menu/220_img/stadium/img_room_" }

-- the team plate (vrfw_bracket_row_l = team06_02): its looks, crest, name nodes
local PLATE = { off = "_list_base_xs01_off", on = "_list_base_xs01_on", ok = "_list_base_xs01_ok", ol = "_list_base_xs01_ol" }
local PLATE_SPRITE = "list_base_xs01_off"
local MESH_EMBLEM = "_icon_emblem_dmy01"   -- the plate's crest quad (its crest: VRFW.team.emblem)
local TXT_ON, TXT_OFF = "_text_list01_on", "_text_list01_off"
-- the bracket's sprites (content\images\menu\220_img\vrfw_bracket.toml)
local SPR = {
  plain = "vrfw_bracket_line_plain", lit = "vrfw_bracket_line_lit", me = "vrfw_bracket_line_me", out = "vrfw_bracket_line_out",
  out_me = "vrfw_bracket_line_out_me", star = "vrfw_bracket_star", crown = "vrfw_bracket_crown", frame = "vrfw_bracket_frame_l",
  line = "vrfw_bracket_line",
}
local SPR_HALO = { lit = { h = "vrfw_bracket_lit_h", v = "vrfw_bracket_lit_v" }, me = { h = "vrfw_bracket_me_h", v = "vrfw_bracket_me_v" } }
local SPR_STRIP = { "vrfw_bracket_strip_red", "vrfw_bracket_strip_orange", "vrfw_bracket_strip_yellow", "vrfw_bracket_strip_green",
  "vrfw_bracket_strip_cyan", "vrfw_bracket_strip_blue", "vrfw_bracket_strip_purple", "vrfw_bracket_strip_pink", "vrfw_bracket_strip_black",
  "vrfw_bracket_strip_silver" }
local FRAME_GROW = { w = 408 / 392, h = 88 / 72 }

local S = {
  page = -1, host = nil, view_cmd = nil, top = 0, lift = 0, need = 0, got = 0, seen = {}, frame = 0, drawn = false,
  want = false, animate = false, used = {}, taken = {}, emb = {}, strip = {}, prio = {}, crest_prio = {}, lifted = {},
  view = nil, anim = nil, crests = {}, retail = nil, trophy = false, pics = {},
  pic_load = nil, logged = {}, stuck = false,
}
local L, KEY_OF, RL = {}, {}, nil
local C

local logger
local function Log(...)
  logger = logger or VRFW.logger.new("VRFW.bracket")
  logger(...)
end

-- the layers' crc32 and what each one is (built at the opening)
local function Layers()
  if RL ~= nil then
    return
  end
  for k, name in pairs(POOL_NAME) do
    L[k] = Crc(name)
    KEY_OF[L[k]] = k
  end
  RL = { base = Crc(RETAIL_NAME.base), trophy = Crc(RETAIL_NAME.trophy), star = Crc(RETAIL_NAME.star),
    sched = Crc(RETAIL_NAME.sched), lines = {}, score = {} }
  for _, side in ipairs({ "l", "r" }) do
    for k = 1, 8 do
      RL.lines[#RL.lines + 1] = Crc(string.format("vroad04_03_%s%02d_tournament_line", side, k))
    end
  end
  for r, name in ipairs(RETAIL_NAME.score) do
    RL.score[r] = Crc(name)
  end
  RL.prio = { [RL.base] = RETAIL_PRIO.base, [RL.trophy] = RETAIL_PRIO.trophy, [RL.star] = RETAIL_PRIO.star,
    [RL.sched] = RETAIL_PRIO.sched }
  for _, l in ipairs(RL.lines) do
    RL.prio[l] = RETAIL_PRIO.line
  end
  for _, l in ipairs(RL.score) do
    RL.prio[l] = RETAIL_PRIO.score
  end
end

-- every instance of the retail layers: f(layer, instance)
local function RetailEach(f)
  f(RL.base, 0)
  f(RL.trophy, 0)
  f(RL.sched, 0)
  for k = 1, #RL.lines do
    f(RL.lines[k], 0)
  end
  for i = 0, RETAIL.STARS - 1 do
    f(RL.star, i)
  end
  for r = 1, #RL.score do
    for i = 0, RETAIL.SCORES[r] - 1 do
      f(RL.score[r], i)
    end
  end
end

local function Text(key)
  local t = VRFW.host.command(K("TEXT_GET"), Crc("vrfw_bracket_" .. key))
  return type(t) == "string" and t or ""
end

local function TextValue(key, a)
  local t = Text(key)
  local r = VRFW.host.command(N_CMD.TEXT_VALUE, t, "VALUE", a or 0, 0, 0, true)
  return r or t
end

local function TextValue2(key, a, b)
  return VRFW.bracket.text_value2(Text(key), a, b or 0)
end

local function Hide(layer, i)
  M("VISIBLE", layer, i, false)
  M("POS", layer, -4000, 4000, 0, i)
end

-- the pieces of one draw: { [layer] = next free instance }; the rest hidden at the end
local function Begin()
  S.used, S.taken, S.crests = {}, {}, {}
  for _, l in pairs(L) do
    S.used[l] = 0
  end
end

local function Take(layer, fixed)
  return VRFW.bracket.take(S, layer, fixed)
end

local function End()
  for k, l in pairs(L) do
    for i = 0, N[k] - 1 do
      if not S.taken[tostring(l) .. ":" .. i] then
        Hide(l, i)
      end
    end
  end
end

local function Quad(k, spr, x, y, w, h, col, prio, atlas)
  local layer = L[k]
  local i = Take(layer)
  if i >= N[k] then
    return nil
  end
  if k == "line" or k == "box" then
    local want = prio or (k == "box" and BOX_PRIO or LINE_PRIO)
    local key = tostring(layer) .. ":" .. i
    if S.prio[key] ~= want then
      S.prio[key] = want
      M("PRIORITY", layer, i, want, true)
    end
  end
  M("VISIBLE", layer, i, true)
  M("SCALE", layer, w / G.Q, h / G.Q, 1, i)
  funcLuaMenuCommand(N_CMD.SPRITE, layer, atlas or ART, type(spr) == "string" and Crc(spr) or spr, Crc(NODE_QUAD), 0, i)
  M("POS", layer, x, -y, 0, i)
  M("PRIM_COLOR", layer, i, Crc(MESH_QUAD), col[1], col[2], col[3])
  return i
end

local function RoundedTurn(xs, xj, y, toward, right, t, look)
  local half = t / 2
  local sprite_w = math.floor(G.TURN_LEN + half)
  local sprite_h = math.floor(half + G.TURN_R)
  local w = math.abs(xj - xs) * sprite_w / (sprite_w - half)
  local cx = right and (xs - w / 2) or (xs + w / 2)
  local cy = toward == "down" and (y - half + sprite_h / 2) or (y + half - sprite_h / 2)
  Quad("line", string.format("vrfw_bracket_turn_%s_%s_%s", look, toward, right and "right" or "left"), cx, cy, w, sprite_h,
    WHITE)
end

local function Run(spr, vertical, c0, c1, pos, t)
  local lo, hi = math.min(c0, c1), math.max(c0, c1)
  local n = math.max(1, math.ceil((hi - lo) / G.CHUNK))
  local step = (hi - lo) / n
  local overlap = n > 1 and math.ceil(step / 32) or 0
  for k = 0, n - 1 do
    local a = lo + k * step - (k > 0 and overlap or 0)
    local b = lo + (k + 1) * step
    if vertical then
      Quad("line", spr, pos, (a + b) / 2, t, b - a, WHITE)
    else
      Quad("line", spr, (a + b) / 2, pos, b - a, t, WHITE)
    end
  end
end

local function Seg(x0, y0, x1, y1, lit, st, shape)
  local t = lit and G.LINE_LIT or G.LINE
  local look = st or (lit and "lit" or "plain")
  if shape and shape.toward then
    return RoundedTurn(x0, x1, y0, shape.toward, shape.right, t, look)
  end
  local halo = SPR_HALO[look]
  if y0 == y1 then
    local dir = x1 >= x0 and 1 or -1
    local spr = halo and halo.h or SPR[look] or SPR.line
    return Run(spr, false, x0 - t / 2 * dir, x1 + t / 2 * dir, y0, t)
  end
  local dir = y1 > y0 and 1 or -1
  local a = y0 - (shape and shape.trim == "start" and G.CORNER_OVERLAP or t / 2) * dir
  local b = y1 + (shape and shape.trim == "end" and G.CORNER_OVERLAP or t / 2) * dir
  local spr = halo and halo.v or SPR[look] or SPR.line
  Run(spr, true, a, b, x0, t)
end

-- an instance's model + name alpha (reset on every plate / crest drawn: instances are reused)
local function Alpha(l, i, a)
  pcall(M, "MODEL_ALPHA", l, i, 0, a)
  pcall(M, "TEXT_ALPHA", l, i, Crc(TXT_ON), a)
  pcall(M, "TEXT_ALPHA", l, i, Crc(TXT_OFF), a)
end

-- the plate's own sprite swapped for a team strip of the bracket's atlas, or back to the list plate (spr nil)
local function PlateStrip(l, i, spr)
  local k = tostring(l) .. ":" .. i
  local want = spr or false
  if S.strip[k] == want then
    return
  end
  S.strip[k] = want
  if spr then
    VRFW.host.menu_command(N_CMD.SPRITE, l, ART, Crc(spr), Crc(PLATE_SPRITE), 0, i)
  else
    VRFW.host.menu_command(N_CMD.SPRITE, l, PLATE_ATLAS, Crc(PLATE_SPRITE), Crc(PLATE_SPRITE), 0, i)
  end
end

local function Plate(p, x, y, s, right, champ, fixed)
  local k = right and "row_r" or "row_l"
  local l = L[k]
  local i = Take(l, fixed)
  if i >= N[k] then
    return
  end
  local look = champ and "ok" or (p.me and "on" or "off")
  local strip = not champ and SPR_STRIP[tonumber(p.strip) or 0] or nil
  if strip then
    look = "off"
  end
  PlateStrip(l, i, look == "off" and strip or nil)
  local white = look ~= "off" or strip ~= nil
  M("VISIBLE", l, i, true)
  M("SCALE", l, s, s, 1, i)
  M("POS", l, x, -y, 0, i)
  for name, mesh in pairs(PLATE) do
    M("MESH_VISIBLE", l, Crc(mesh), name == look, i)
  end
  local name = VRFW.team.name(p.team)
  M("TEXT", l, Crc(TXT_ON), white and name or "", i)
  M("TEXT", l, Crc(TXT_OFF), white and "" or name, i)
  M("TEXT_VISIBLE", l, Crc(TXT_ON), white, i)
  M("TEXT_VISIBLE", l, Crc(TXT_OFF), not white, i)
  local c = (p.out and not champ) and G.DIM or 1
  M("PRIM_COLOR", l, i, Crc(PLATE[look]), c, c, c)
  M("PRIM_COLOR", l, i, Crc(MESH_EMBLEM), c, c, c)
  Alpha(l, i, (p.out and not champ) and ADV.OUT_ALPHA or 1)
  VRFW.team.emblem(l, i, p.team, S.emb)
end

-- the player's gold frame behind his plate (left edge x, centre y, scale s)
local function Focus(x, y, s)
  local w, h = G.PLATE_W * s, G.PLATE_H * s
  Quad("box", SPR.frame, x + w / 2, y, w * FRAME_GROW.w, h * FRAME_GROW.h, WHITE, G.PRIO_BACK)
end

-- a row of digit sprites centred on (x, y): parts = { { sprite name, height }, ... }; returns its width
local function Glyphs(parts, x, y, prio)
  local total, ws = 0, {}
  for k, p in ipairs(parts) do
    ws[k] = NUM.W * p[2] / NUM.H
    total = total + ws[k] * (k < #parts and NUM.ADV or 1)
  end
  local cx = x - total / 2
  for k, p in ipairs(parts) do
    Quad("line", p[1], cx + ws[k] / 2, y, ws[k], p[2], WHITE, prio or NUM.PRIO, ART_NUM)
    cx = cx + ws[k] * NUM.ADV
  end
  return total
end

-- the parts of number n (style gold / blue / white) at height h appended to parts; wrap = in brackets
local function NumParts(parts, n, style, h, wrap)
  return VRFW.bracket.number_parts("vrfw_bracket_d_", parts, n, style, h, wrap)
end

local function RowW(k, h)
  return NUM.W * h / NUM.H * (1 + NUM.ADV * (k - 1))
end

local function TreeScore(m, xj, ym, right, pitch, lead)
  local sc = m and (m.w or 0) ~= 0 and m.score or nil
  if not sc then
    return 0
  end
  local h = math.max(NUM.H_MIN, math.min(NUM.H_MAX, pitch * NUM.HEIGHT))
  local dy = (h + h * NUM.GAP / NUM.H) / 2
  local function x_of(off, w)
    local c = xj + off + w / 2
    return right and (2 * G.CX - c) or c
  end
  local space = NUM.SPACE * h / NUM.H
  local used = (lead or 0) + space
  local ga, gb = sc.ga or 0, sc.gb or 0
  local sa, sb = m.w == 1 and "gold" or "blue", m.w == 2 and "gold" or "blue"
  local w
  if ga <= 9 and gb <= 9 then
    w = NUM.W * h / NUM.H
    Quad("line", string.format("vrfw_bracket_pr_%d_%d_%d", ga, gb, m.w), x_of(used, w), ym, w, h * NUM.PAIR_H / NUM.H, WHITE,
      NUM.PRIO, ART_NUM)
  else
    local pa, pb = NumParts({}, ga, sa, h), NumParts({}, gb, sb, h)
    w = RowW(math.max(#pa, #pb), h)
    Glyphs(pa, x_of(used, w), ym - dy)
    Glyphs(pb, x_of(used, w), ym + dy)
  end
  used = used + w
  if (sc.pa or 0) + (sc.pb or 0) > 0 then
    local hp = h * NUM.PEN_S
    local pa, pb = NumParts({}, sc.pa or 0, sa, hp), NumParts({}, sc.pb or 0, sb, hp)
    local wp = RowW(math.max(#pa, #pb), hp)
    used = used + space / 2
    Glyphs(pa, x_of(used, wp), ym - dy)
    Glyphs(pb, x_of(used, wp), ym + dy)
    used = used + wp
  end
  return used + space
end

local function FinalScore(m, ymid, pitch)
  local sc = m and (m.w or 0) ~= 0 and m.score or nil
  if not sc then
    return
  end
  local h = math.max(NUM.H_MIN, math.min(NUM.H_MAX, pitch * NUM.HEIGHT)) * NUM.FINAL_S
  local y = ymid + G.LINE_LIT + h / 2
  local off = NUM.W * h / NUM.H
  local sa, sb = m.w == 1 and "gold" or "blue", m.w == 2 and "gold" or "blue"
  Glyphs(NumParts({}, sc.ga or 0, sa, h), G.CX - off, y)
  Glyphs(NumParts({}, sc.gb or 0, sb, h), G.CX + off, y)
  if (sc.pa or 0) + (sc.pb or 0) > 0 then
    local hp = h * NUM.PEN_S
    local yp = y + h / 2 + hp * 0.7
    Glyphs(NumParts({}, sc.pa or 0, sa, hp, true), G.CX - off, yp)
    Glyphs(NumParts({}, sc.pb or 0, sb, hp, true), G.CX + off, yp)
  end
end

-- the size (px) of the crest standing on a joint of round r
local function BigCrest(r, pitch, stub)
  return math.max(ADV.BIG_MIN, math.min(ADV.BIG_MAX, stub * ADV.BIG_OF, 2 ^ r * pitch - ADV.BIG_GAP))
end

-- a crest alone centred on (x, y) at scale sc; returns the instance (nil: none left)
local function Crest(c, x, y, sc)
  local l = L.crest
  local i = Take(l)
  if i >= N.crest then
    return nil
  end
  if not S.crest_prio[i] then
    S.crest_prio[i] = true
    pcall(M, "PRIORITY", l, i, ADV.CREST_PRIO, true)
  end
  M("VISIBLE", l, i, true)
  for _, mesh in pairs(PLATE) do
    M("MESH_VISIBLE", l, Crc(mesh), false, i)
  end
  M("TEXT_VISIBLE", l, Crc(TXT_ON), false, i)
  M("TEXT_VISIBLE", l, Crc(TXT_OFF), false, i)
  M("PRIM_COLOR", l, i, Crc(MESH_EMBLEM), 1, 1, 1)
  Alpha(l, i, 1)
  M("SCALE", l, sc, sc, 1, i)
  M("POS", l, x - ADV.CREST_X * sc, -y, 0, i)
  local lf = (S.view and S.view.leaves or {})[c.leaf] or {}
  VRFW.team.emblem(l, i, lf.team or 0, S.emb)
  return i
end

-- the run's end in the panel: champion / out (a view without them: nothing)
local function Outcome(v)
  local league = v.fmt == "league"
  if v.outcome == "champion" then
    return Text(league and "champion_league" or "champion")
  end
  if v.outcome == "out" and v.place and v.place.stage == "league" then
    return TextValue("out_league", v.place.pos or 0)
  end
  if v.outcome == "out" and v.place then
    if v.place.stage == "groups" then
      return Text("out_groups")
    end
    return Text("out_ko_" .. tostring(v.place.from_end or 1))
  end
  return ""
end

-- the top row (S.top) moves the whole tree down by dy; the bottom row stays
local function DrawTree(v)
  local R = tonumber(v.rounds) or 0
  if R < 1 and type(v.leaves) == "table" then
    local n = 0
    for _ in pairs(v.leaves) do
      n = n + 1
    end
    while 2 ^ (R + 1) <= n do
      R = R + 1
    end
  end
  if R < 1 or type(v.leaves) ~= "table" or type(v.matches) ~= "table" then
    return
  end
  local top = S.top > 0 and S.top or G.TOP
  local dy = top - G.TOP
  local champ_y = G.CHAMP_Y + dy
  local leaves = v.leaves
  local NL = 2 ^ R
  local half = NL / 2
  local pitch = (G.BOTTOM - top) / half
  local s = math.min(G.SCALE_MAX, pitch * G.FILL / G.PLATE_H)
  local edge = G.MARGIN + G.PLATE_W * s
  local xe = edge + G.GAP
  local function jx(r)
    return xe + (G.CX - xe) * r / R
  end
  local function mx(x, right)
    return right and (2 * G.CX - x) or x
  end
  -- the byes: first-round matches with exactly one team (bye[match] = the leaf of that team)
  local bye = {}
  for t = 1, NL / 2 do
    local a, b = (leaves[2 * t - 1] or {}).team or 0, (leaves[2 * t] or {}).team or 0
    if (a == 0) ~= (b == 0) then
      bye[t] = a ~= 0 and 2 * t - 1 or 2 * t
    end
  end
  local ys, own, at = {}, {}, {}
  for t = 1, NL do
    local right = t > half
    local k = (t - 1) % half
    local y = top + pitch * (k + 0.5)
    ys[t] = y
    own[t] = t
    local p = leaves[t]
    local x = right and (G.W - G.MARGIN - G.PLATE_W * s) or G.MARGIN
    at[t] = { x + (right and ADV.CREST_X_R or ADV.CREST_X) * s, y }
    if p and (p.team or 0) ~= 0 and not bye[math.floor((t + 1) / 2)] then
      if p.me then
        Focus(x, y, s)
      end
      Plate(p, x, y, s, right, false)
    end
  end
  local segs = {}
  local function seg(x0, y0, x1, y1, l, played, won, shape)
    local p = leaves[l] or {}
    local st = "plain"
    if played and (p.team or 0) ~= 0 then
      st = (won and not p.out) and "lit" or "out"
    end
    segs[#segs + 1] = { x0, y0, x1, y1, st, p.me == true, shape }
  end
  local crests = {}
  local ymid = (top + G.BOTTOM) / 2
  local cpw = G.PLATE_W * G.CHAMP_S
  for r = 1, R do
    local row = v.matches[r] or {}
    local cnt = NL / 2 ^ r
    local nx, nown, nat = {}, {}, {}
    for t = 1, cnt do
      local m = row[t] or { w = 0 }
      local w = m.w or 0
      local played = w ~= 0
      local ya, yb = ys[2 * t - 1], ys[2 * t]
      local la, lb = own[2 * t - 1], own[2 * t]
      local ym = (ya + yb) / 2
      nx[t] = ym
      local win = w == 1 and la or (w == 2 and lb or 0)
      nown[t] = win
      local from = w == 1 and at[2 * t - 1] or at[2 * t]
      local yw = w == 1 and ya or yb
      local xc = r == 1 and edge or jx(r - 1)
      local by = r == 1 and bye[t] or nil
      if by and r < R then
        -- a bye: the team's plate ends at the first-round joint, where the next round's line starts
        local right = t > cnt / 2
        local xj = jx(r)
        local x = right and mx(xj, true) or (xj - G.PLATE_W * s)
        local p = leaves[by]
        if p.me then
          Focus(x, ym, s)
        end
        Plate(p, x, ym, s, right, false)
        nown[t] = by
        nat[t] = { x + (right and ADV.CREST_X_R or ADV.CREST_X) * s, ym }
      elseif r < R then
        local right = t > cnt / 2
        local xj = jx(r)
        seg(mx(xc, right), ya, mx(xj, right), ya, la, played, w == 1, { toward = "down", right = right })
        seg(mx(xc, right), yb, mx(xj, right), yb, lb, played, w == 2, { toward = "up", right = right })
        seg(mx(xj, right), ya + G.TURN_R, mx(xj, right), ym, la, played, w == 1, { trim = "start" })
        seg(mx(xj, right), ym, mx(xj, right), yb - G.TURN_R, lb, played, w == 2, { trim = "end" })
        local nxt = (v.matches[r + 1] or {})[math.floor((t + 1) / 2)] or {}
        local stays = win ~= 0 and (nxt.w or 0) == 0
        local big = BigCrest(r, pitch, (G.CX - xe) / R)
        TreeScore(m, xj, ym, right, pitch, big / 2)
        if win ~= 0 and from then
          local rest = { mx(xj, right), ym }
          nat[t] = rest
          crests[#crests + 1] = { leaf = win, round = r, rest = rest, s = big / ADV.CREST_W, stays = stays,
            joint = { mx(xj, right), ym }, path = { from, { mx(xj, right), yw }, { mx(xj, right), ym }, rest } }
        end
      else
        seg(xc, ya, G.CX, ya, la, played, w == 1)
        seg(mx(xc, true), yb, G.CX, yb, lb, played, w == 2)
        -- with the retail trophy the stem stops at the cup's lower edge; without it, at the champion's plate
        local stem_top = S.trophy and (G.TROPHY_Y + dy + G.TROPHY_CUP_BOTTOM) or (champ_y + G.PLATE_H * G.CHAMP_S / 2)
        seg(G.CX, stem_top, G.CX, ymid, win, played, true)
        FinalScore(m, ymid, pitch)
        if win ~= 0 and from then
          local rest = { G.CX - cpw / 2 + ADV.CREST_X * G.CHAMP_S, champ_y }
          local fs = BigCrest(R, pitch, (G.CX - xe) / R) / ADV.CREST_W
          crests[#crests + 1] = { leaf = win, round = r, rest = rest, s = fs, s1 = G.CHAMP_S, final = true,
            stays = false, path = { from, { G.CX, yw }, { G.CX, champ_y }, rest } }
        end
      end
    end
    ys, own, at = nx, nown, nat
  end
  -- the plain pieces first, then the dark ones, the lit path over them
  for _, st in ipairs({ "plain", "out", "lit" }) do
    for _, g in ipairs(segs) do
      if g[5] == st then
        local look = st
        if g[6] and st == "lit" then
          look = "me"
        elseif g[6] and st == "out" then
          look = "out_me"
        end
        Seg(g[1], g[2], g[3], g[4], st == "lit", look, g[7])
      end
    end
  end
  S.crests = crests
  -- the star glow at the joint each waiting crest stands at (shown when its crest gets there)
  local star = math.max(G.STAR_MIN, math.min(G.STAR_MAX, pitch * G.STAR))
  for _, c in ipairs(crests) do
    if c.stays then
      c.star = Quad("box", SPR.star, c.joint[1], c.joint[2], star, star, WHITE, G.PRIO_BACK)
      c.i = Crest(c, c.rest[1], c.rest[2], c.s)
    end
  end
  -- the champion: a cyan plate above the final with the crown over it (a tree without the retail trophy)
  local champ = (v.champion or 0) ~= 0
  local cy = champ_y - G.PLATE_H * G.CHAMP_S / 2 - G.CROWN_H / 2 + 6
  local cc = champ and 1 or G.DIM
  if not S.trophy then
    Quad("icon", SPR.crown, G.CX, cy, G.CROWN_W, G.CROWN_H, { cc, cc, cc })
  end
  if champ then
    Plate({ team = v.champion }, G.CX - G.PLATE_W * G.CHAMP_S / 2, champ_y, G.CHAMP_S, false, true, ROW_CHAMP)
  end
end

local function RetailReady()
  if S.retail_ok ~= nil then
    return S.retail_ok
  end
  local ok = true
  for _, l in ipairs({ RL.base, RL.trophy, RL.sched, RL.star, RL.lines[1], RL.lines[16], RL.score[1], RL.score[4] }) do
    local n = M("LAYER_NUM", l)
    if type(n) ~= "number" or n < 1 then
      ok = false
    end
  end
  S.retail_ok = ok
  Log("retail bracket layers: " .. (ok and "present" or "missing (every bracket on the generic lines)"))
  return ok
end

-- the retail layers shown (the 16-team page) or hidden; the stars and scores are shown one by one
local function RetailShow(on)
  RetailEach(function(l, i)
    local piece = l == RL.star or l == RL.score[1] or l == RL.score[2] or l == RL.score[3] or l == RL.score[4]
    M("VISIBLE", l, i, on and not piece)
  end)
end

-- the base's glow meshes, one per slot of the retail tree (_line_l01 .. _line_r08)
local function GlowMeshes()
  if S.glow == nil then
    S.glow = {}
    for _, side in ipairs({ "l", "r" }) do
      for k = 1, 2 ^ RETAIL.ROUNDS / 2 do
        S.glow[#S.glow + 1] = Crc(string.format("_line_%s%02d", side, k))
      end
    end
  end
  return S.glow
end

local function TrophyPlace(alone, dy)
  M("MESH_VISIBLE", RL.base, Crc(RETAIL.MESH_TREE), not alone, 0)
  for _, mesh in ipairs(GlowMeshes()) do
    M("MESH_VISIBLE", RL.base, mesh, not alone, 0)
  end
  M("POS", RL.base, 0, alone and (RETAIL.TROPHY_NODE_Y - (G.TROPHY_Y + dy)) or -dy, 0, 0)
  if alone then
    M("VISIBLE", RL.base, 0, true)
    M("VISIBLE", RL.trophy, 0, true)
  end
end

-- a strip's lit length: rate 0 (unlit) ..
local function RetailRate(k, rate)
  local l = RL.lines[k]
  local g = M("GROUP_INDEX", l, 0, Crc(RETAIL.ANIM_LINE))
  funcLuaMenuCommand(N_CMD.RATE_BIND, l, RETAIL.RATE_MOVE, g or 0, 0)
  funcLuaMenuCommand(N_CMD.RATE_SET, l, RETAIL.RATE_MOVE, 0, rate, 0, true, Crc(RETAIL.ANIM_LINE))
  M("VISIBLE", RL.star, k - 1, rate > 0)
end

-- one score object: the two entrants' goals, the shoot-out's winner flagged; not played = hidden
local function RetailScore(r, t, m)
  local l, i = RL.score[r], t - 1
  local sc = m and (m.w or 0) ~= 0 and m.score or nil
  M("VISIBLE", l, i, sc ~= nil)
  if not sc then
    return
  end
  for _, prim in ipairs({ RETAIL.NUM_A, RETAIL.NUM_B }) do
    funcLuaMenuCommand(N_CMD.NUM_SHOW, l, i, prim, true)
    local pi = M("PRIM_INDEX", l, i, prim)
    funcLuaMenuCommand(N_CMD.NUM_SET, l, i, pi, prim == RETAIL.NUM_A and (sc.ga or 0) or (sc.gb or 0))
  end
  for _, f in ipairs(RETAIL.FLAG_ALL) do
    M("MESH_VISIBLE", l, Crc(f), false, i)
  end
  if (sc.pa or 0) + (sc.pb or 0) > 0 then
    local flags = r == #RL.score and RETAIL.FLAG_FINAL or (t > RETAIL.SCORES[r] / 2 and RETAIL.FLAG.right or RETAIL.FLAG.left)
    M("MESH_VISIBLE", l, Crc(flags[m.w] or flags[1]), true, i)
  end
end

-- the schedule panel: the round being played, its matches played, the player's next match (or the run's end)
local function RetailPanel(v)
  local cur, played, total = nil, 0, 0
  for r = 1, RETAIL.ROUNDS do
    local n, done = 0, 0
    for _, m in pairs(v.matches[r] or {}) do
      n = n + 1
      if (m.w or 0) ~= 0 then
        done = done + 1
      end
    end
    if cur == nil and done < n then
      cur, played, total = r, done, n
    end
  end
  local round_txt, played_txt, next_txt
  if cur == nil then
    round_txt, played_txt = Text("sched_over"), ""
  else
    round_txt = Text("round_" .. tostring(RETAIL.ROUNDS - cur + 1))
    played_txt = TextValue2("sched_played", played, total)
  end
  local tail = Outcome(v)
  if tail ~= "" then
    next_txt = tail
  elseif cur ~= nil then
    local rival = (v.next or 0) ~= 0 and VRFW.team.name(v.next) or Text("sched_rival_tbd")
    next_txt = Text("sched_next") .. "  ·  " .. rival
  else
    next_txt = ""
  end
  for node, s in pairs({ [RETAIL.TXT_ROUND] = round_txt, [RETAIL.TXT_PLAYED] = played_txt, [RETAIL.TXT_NEXT] = next_txt,
    [RETAIL.TXT_SPARE] = "" }) do
    M("TEXT", RL.sched, Crc(node), s, 0)
    M("TEXT_VISIBLE", RL.sched, Crc(node), s ~= "", 0)
  end
  return cur
end

local function DrawRetail(v)
  local leaves = v.leaves
  local dy = S.top > 0 and (S.top - G.TOP) or 0
  local s = RETAIL.PLATE_S
  local pw = G.PLATE_W * s
  local last = 0
  for r = 1, RETAIL.ROUNDS do
    for _, m in pairs(v.matches[r] or {}) do
      if (m.w or 0) ~= 0 then
        last = r
      end
    end
  end
  local rates, prev = {}, {}
  for k = 1, #RL.lines do
    local p = leaves[k] or {}
    local right = k > 8
    local y = RETAIL.NAME_Y0 + dy + RETAIL.NAME_STEP * ((k - 1) % 8)
    local x = right and (RETAIL.NAME_X_R - RETAIL.STRIP_IN + RETAIL.PLATE_GAP)
      or (RETAIL.NAME_X_L + RETAIL.STRIP_IN - RETAIL.PLATE_GAP - pw)
    if (p.team or 0) ~= 0 then
      if p.me then
        Focus(x, y, s)
      end
      Plate(p, x, y, s, right, false)
    end
    local won = tonumber(p.won) or 0
    local rate = (not p.out and (p.team or 0) ~= 0) and math.min(1, won / RETAIL.ROUNDS) or 0
    rates[k] = rate
    local before = rate
    local t = math.floor((k - 1) / 2 ^ last) + 1
    local m = (v.matches[last] or {})[t]
    if last > 0 and m and (m.w or 0) ~= 0 then
      local upper = ((k - 1) % 2 ^ last) < 2 ^ (last - 1)
      local winner = (m.w == 1) == upper
      if winner then
        before = math.max(0, rate - 1 / RETAIL.ROUNDS)
      elseif (p.team or 0) ~= 0 then
        before = math.min(1, (last - 1) / RETAIL.ROUNDS)
      end
    end
    prev[k] = before
    RetailRate(k, rate)
  end
  for r = 1, RETAIL.ROUNDS do
    local row = v.matches[r] or {}
    for t = 1, RETAIL.SCORES[r] do
      RetailScore(r, t, row[t])
    end
  end
  local cur = RetailPanel(v)
  if (v.champion or 0) ~= 0 then
    Plate({ team = v.champion }, G.CX - G.PLATE_W * G.CHAMP_S / 2, RETAIL.CHAMP_Y + dy, G.CHAMP_S, false, true, ROW_CHAMP)
  end
  S.crests = {}
  S.retail = { rates = rates, prev = prev, last = last }
  local lit = 0
  for k = 1, #rates do
    if rates[k] > 0 then
      lit = lit + 1
    end
  end
  local bx, by = VRFW.host.menu_command(N_CMD.GLOBAL_POS, RL.base, 0)
  local lx, ly = VRFW.host.menu_command(N_CMD.GLOBAL_POS, RL.lines[1], 0)
  return string.format("retail bracket: %d path(s) lit, last round played %d, panel round %s; base at %s,%s, l01 strip at %s,%s",
    lit, last, tostring(cur), tostring(bx), tostring(by), tostring(lx), tostring(ly))
end

-- the picture of a map: { path, tex, sprite, st = 0 not asked / 1 loading / 2 in / -1 none }
local function StadiumPicture(map)
  local pic = S.pics[map]
  if pic == nil then
    local path = STADIUM.PICTURE_DIR .. map .. ".g4tx"
    pic = { path = path, tex = Crc(path), sprite = Crc("img_room_" .. map .. "_01"), st = 0, t = 0 }
    S.pics[map] = pic
  end
  if pic.st == 0 then
    local ok = pcall(M, "LOAD_TEX", pic.path)
    pic.st, pic.t = ok and 1 or -1, 0
    S.pic_load = ok and map or nil
    Log("final stadium picture: " .. pic.path .. (ok and " asked" or " not loadable (name only)"))
  end
  return pic
end

-- from Step while a picture loads: once it is in, the page again
local function StadiumLoadStep()
  local pic = S.pic_load and S.pics[S.pic_load]
  if not pic or pic.st ~= 1 then
    S.pic_load = nil
    return
  end
  pic.t = pic.t + 1
  local busy = VRFW.host.command(N_CMD.TEX_LOADING, pic.tex)
  if pic.t > STADIUM.LOAD_MAX then
    pic.st, S.pic_load = -1, nil
    Log("final stadium picture: never loaded (name only)", pic.path)
    return
  end
  if busy ~= true and pic.t >= STADIUM.LOAD_MIN then
    pic.st, S.pic_load = 2, nil
    Log("final stadium picture: in after " .. pic.t .. " frames")
    S.want = true
  end
end

local function DrawStadium(v)
  local fs = v.final_stadium
  if type(fs) ~= "table" or type(fs.map) ~= "string" or fs.map == "" then
    return
  end
  local id = type(fs.id) == "number" and fs.id or Crc(fs.map)
  local name = VRFW.host.command(K("MAP_NAME"), id)
  if type(name) ~= "string" then
    name = ""
  end
  local l = L.stadium_panel
  local i = Take(l)
  M("VISIBLE", l, i, true)
  M("SCALE", l, 1, 1, 1, i)
  M("POS", l, G.CX, -STADIUM.Y, 0, i)
  for node, s in pairs({ [RETAIL.TXT_ROUND] = Text("final_stadium"), [RETAIL.TXT_NEXT] = name, [RETAIL.TXT_PLAYED] = "",
    [RETAIL.TXT_SPARE] = "" }) do
    M("TEXT", l, Crc(node), s, i)
    M("TEXT_VISIBLE", l, Crc(node), s ~= "", i)
  end
  local pic = StadiumPicture(fs.map)
  if pic.st == 2 then
    Quad("box", pic.sprite, G.CX - STADIUM.PANEL_W / 2 - STADIUM.PAD - STADIUM.THUMB_W / 2, STADIUM.Y, STADIUM.THUMB_W,
      STADIUM.THUMB_H, WHITE, nil, pic.tex)
  end
  local key = fs.map .. ":" .. pic.st
  if S.stadium_logged ~= key then
    S.stadium_logged = key
    Log(string.format("final stadium panel: %s «%s» (picture %s)", fs.map, name,
      pic.st == 2 and "shown" or (pic.st == 1 and "loading" or "none")))
  end
end

-- the point at fraction f (0..1) of a polyline's length
local function Along(path, f)
  local total, lens = 0, {}
  for k = 2, #path do
    local d = math.abs(path[k][1] - path[k - 1][1]) + math.abs(path[k][2] - path[k - 1][2])
    lens[k] = d
    total = total + d
  end
  if total <= 0 then
    return path[#path][1], path[#path][2]
  end
  local want = total * f
  for k = 2, #path do
    if want <= lens[k] or k == #path then
      local u = lens[k] > 0 and math.min(1, want / lens[k]) or 1
      local a, b = path[k - 1], path[k]
      return a[1] + (b[1] - a[1]) * u, a[2] + (b[2] - a[2]) * u
    end
    want = want - lens[k]
  end
  return path[#path][1], path[#path][2]
end

local function Ease(p)
  if p < 0.5 then
    return 4 * p * p * p
  end
  return 1 - (-2 * p + 2) ^ 3 / 2
end

local function ChampionVisible(show)
  if S.view and (S.view.champion or 0) ~= 0 then
    M("VISIBLE", L.row_l, ROW_CHAMP, show)
  end
end

-- place every walking crest / strip at the animation's time
local function AnimApply()
  local an = S.anim
  if not an then
    return
  end
  if an.retail then
    local busy = false
    for _, it in ipairs(an.items) do
      local p = math.max(0, math.min(1, (an.t - it.delay) / ADV.DUR))
      if p < 1 then
        busy = true
      end
      RetailRate(it.slot, it.from + (it.to - it.from) * Ease(p))
    end
    if an.final then
      ChampionVisible(not busy)
    end
    return
  end
  local champ_wait = false
  for _, c in ipairs(an.items) do
    local p = math.max(0, math.min(1, (an.t - c.delay) / ADV.DUR))
    local e = Ease(p)
    local x, y = Along(c.path, e)
    local sc = c.s + ((c.s1 or c.s) - c.s) * e
    M("VISIBLE", L.crest, c.i, not (c.final and p >= 1))
    M("SCALE", L.crest, sc, sc, 1, c.i)
    M("POS", L.crest, x - ADV.CREST_X * sc, -y, 0, c.i)
    if c.star then
      M("VISIBLE", L.box, c.star, p >= 1)
    end
    if c.final and p < 1 then
      champ_wait = true
    end
  end
  ChampionVisible(not champ_wait)
end

local function Param(name)
  return Crc("vrfw_bracket_" .. name)
end

local function AnimFinish(why)
  VRFW.param.clear(Param("busy"))
  local an = S.anim
  if not an then
    return
  end
  an.t = an.done_at + 1
  AnimApply()
  S.anim = nil
  Log("bracket advance:", why)
end

-- the round just played (the last one with a result) walks; nothing when the tree has no result yet
local function AnimStart(v)
  S.anim = nil
  local A = ADV
  local items, an = {}, nil
  if S.retail then
    local rt = S.retail
    if rt.last > 0 then
      for k = 1, #rt.rates do
        if rt.prev[k] ~= rt.rates[k] then
          items[#items + 1] = { slot = k, from = rt.prev[k], to = rt.rates[k] }
        end
      end
      an = { t = 0, page = v.page, retail = true, items = items, round = rt.last, final = rt.last == RETAIL.ROUNDS }
    end
  else
    local last = 0
    for _, c in ipairs(S.crests) do
      last = math.max(last, c.round)
    end
    for _, c in ipairs(S.crests) do
      if last > 0 and c.round == last then
        if c.i == nil then
          c.i = Crest(c, c.path[1][1], c.path[1][2], c.s)   -- the final's winner: a crest of its own for the walk
        end
        if c.i ~= nil then
          items[#items + 1] = c
        end
      end
    end
    an = { t = 0, page = v.page, items = items, round = last }
  end
  if an == nil or #items == 0 then
    AnimFinish("nothing to advance")
    return
  end
  local gap = math.min(A.STAGGER, A.STAGGER_ALL / #items)
  for k, it in ipairs(items) do
    it.delay = (k - 1) * gap
  end
  an.done_at = (#items - 1) * gap + A.DUR
  S.anim = an
  AnimApply()
  Log(string.format("bracket advance: round %d, %d %s", an.round, #items, an.retail and "path(s) on the retail art"
    or "crest(s) walk"))
end

local function AnimStep()
  local an = S.anim
  if not an then
    return
  end
  local dt = VRFW.host.command(N_CMD.FRAME_TIME)
  if type(dt) ~= "number" or dt <= 0 or dt > 0.5 then
    dt = 1 / 60
  end
  an.t = an.t + dt
  if an.t >= an.done_at then
    AnimFinish("done")
    return
  end
  AnimApply()
end

local function ParamInt(name)
  return tonumber(VRFW.param.get(Param(name)))
end

local function ParamU32(name)
  return VRFW.param.get_u32("vrfw_bracket_" .. name)
end

-- the host's handshake parameters (at the opening and at every redraw request)
local function ReadParams()
  S.page = C.page() or S.page or -1
  S.host = C.host() or S.host
  S.view_cmd = ParamU32("view") or S.view_cmd
  S.top = ParamInt("top") or 0
  S.lift = ParamInt("lift") or 0
end

-- the retail art over a host's background: each retail layer's own priority + lift (once per instance and value)
local function Lift()
  if S.lift == 0 and next(S.lifted) == nil then
    return
  end
  RetailEach(function(l, i)
    local key = tostring(l) .. ":" .. i
    local want = RL.prio[l] + S.lift
    if S.lifted[key] ~= want then
      S.lifted[key] = want
      pcall(M, "PRIORITY", l, i, want, true)
    end
  end)
  if S.lifted.panel ~= S.lift then
    S.lifted.panel = S.lift
    pcall(M, "PRIORITY", L.stadium_panel, 0, RETAIL_PRIO.stadium_panel + S.lift, true)
  end
end

-- the page drawn: every piece shown, the rest of each pool hidden; false = the view not answered yet
local function Draw()
  if (S.view_cmd or 0) == 0 then
    Log("bracket menu: no view command from the host; nothing drawn")
    return true
  end
  local v = VRFW.host.command(S.view_cmd, S.page or -1)
  if type(v) ~= "table" then
    return false
  end
  Lift()
  S.view = v
  Begin()
  local tree = v.kind == "tree" and type(v.leaves) == "table" and type(v.matches) == "table"
  local retail = tree and tonumber(v.rounds) == RETAIL.ROUNDS and RetailReady()
  S.retail = nil
  if RetailReady() then
    RetailShow(retail)
  end
  S.trophy = tree and not retail and RetailReady()
  if RetailReady() then
    pcall(TrophyPlace, S.trophy, S.top > 0 and (S.top - G.TOP) or 0)
  end
  local note = ""
  local okd, err = pcall(function()
    if retail then
      note = DrawRetail(v)
    elseif tree then
      DrawTree(v)
    end
    if tree then
      DrawStadium(v)
    end
  end)
  if not okd then
    Log("bracket menu: draw error", tostring(err))
  end
  End()
  local skip = ParamInt("skip") ~= nil
  if skip then
    VRFW.param.clear(Param("skip"))
  end
  if S.animate and not skip then
    local oka, erra = pcall(AnimStart, v)
    if not oka then
      S.anim = nil
      AnimFinish("advance error " .. tostring(erra))
    end
  elseif S.anim and S.anim.page == v.page then
    pcall(AnimApply)
    if skip then
      AnimFinish("skipped")
    end
  else
    S.anim = nil
    AnimFinish(skip and "skipped" or "no advance")
  end
  S.animate = false
  S.drawn = true
  local u = S.used
  local line = string.format("bracket drawn on %s (kind %s, rounds %s, top %d, lift %d; plates %d+%d, lines %d, crests %d) %s",
    VRFW.ids.hex_text(S.host or 0), tostring(v.kind), tostring(v.rounds), S.top, S.lift, u[L.row_l] or 0, u[L.row_r] or 0,
    u[L.line] or 0, u[L.crest] or 0, note)
  if S.logged.last ~= line then
    S.logged.last = line
    Log(line .. (S.got < S.need and string.format(" (instances set up %d of %d)", S.got, S.need) or ""))
  end
  return true
end

-- every instance hidden (nothing of the bracket left on screen)
local function HideAll()
  for k, l in pairs(L) do
    for i = 0, N[k] - 1 do
      pcall(Hide, l, i)
    end
  end
  if RL then
    RetailEach(function(l, i)
      pcall(M, "VISIBLE", l, i, false)
    end)
  end
end

-- closing (the host's close): every piece hidden at once, no draw any more; VRFW.child_menu closes this menu
local function OnClose()
  S.want, S.drawn, S.anim = false, false, nil
  VRFW.param.clear(Param("busy"))
  HideAll()
end

-- the host's redraw (VRFW.child_menu): the page again, an advance when asked
local function OnRedraw(page, animate)
  ReadParams()
  S.page = page or S.page
  S.animate = S.animate or animate == true
  S.want = true
end

function vrfw_bracket_skip()
  VRFW.param.clear(Param("skip"))
  AnimFinish("skipped")
end

-- the instances the engine created of each pool (the [[screen]] rows) and the instances to wait for (the retail art's too)
local function ReadCounts()
  S.need = 1 + 1 + 1 + #RL.lines + RETAIL.STARS + 8 + 4 + 2 + 1
  for k, l in pairs(L) do
    local n = M("LAYER_NUM", l)
    N[k] = type(n) == "number" and n or 0
    S.need = S.need + N[k]
  end
  ROW_CHAMP = N.row_l - 1
end

function OnInit()
  Layers()
  C = VRFW.child_menu.child(MENU_NAME, { prefix = "vrfw_bracket_", on_redraw = OnRedraw, on_close = OnClose,
    log = function(...) Log("bracket menu:", ...) end })
  C.init()
  S.page, S.host, S.view_cmd = -1, nil, nil
  ReadParams()
  S.need, S.got, S.seen, S.frame = 0, 0, {}, 0
  S.drawn, S.want, S.stuck, S.emb, S.strip, S.prio, S.crest_prio, S.lifted = false, true, false, {}, {}, {}, {}, {}
  S.anim, S.logged, S.retail_ok = nil, {}, nil
  S.animate = ParamInt("busy") ~= nil
  ReadCounts()
end

function OnSetupLayer(a1, a2)
  Layers()
  local pool = KEY_OF[a1]
  if pool == nil and RL.prio[a1] == nil then
    return
  end
  local i = a2 or 0
  if pool and i >= (N[pool] or 0) then
    ReadCounts()
  end
  if pool then
    Hide(a1, i)
  else
    M("VISIBLE", a1, i, false)
  end
  local k = tostring(a1) .. ":" .. tostring(i)
  if not S.seen[k] then
    S.seen[k] = true
    S.got = S.got + 1
  end
  S.emb[k], S.strip[k], S.prio[k], S.lifted[k] = nil, nil, nil, nil
  if a1 == L.crest then
    S.crest_prio[i] = nil
  end
  if S.drawn then
    S.want = true
  end
end

function OnOpenLayer(a1, a2)
end

function Step()
  S.frame = S.frame + 1
  if C.step() then
    return   -- closing
  end
  if S.want and (S.got >= S.need or S.frame >= 120) then
    if S.got < S.need and not S.stuck then
      S.stuck = true
      Log("bracket menu: STUCK? only", S.got, "of", S.need, "instances set up after", S.frame, "frames: drawn anyway")
    end
    if Draw() then
      S.want = false
    end
  end
  if S.pic_load ~= nil then
    local okp, errp = pcall(StadiumLoadStep)
    if not okp then
      S.pic_load = nil
      Log("final stadium picture error", tostring(errp))
    end
  end
  if S.anim then
    local oka, erra = pcall(AnimStep)
    if not oka then
      S.anim = nil
      AnimFinish("advance error " .. tostring(erra))
    end
  end
end

function FinalizeMenu()
  if C then
    C.finalize()
  end
end
