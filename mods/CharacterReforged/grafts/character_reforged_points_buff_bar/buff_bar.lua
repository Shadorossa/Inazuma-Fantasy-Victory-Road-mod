CharacterReforged_PointsBuffBar = CharacterReforged_PointsBuffBar or {entries = {}, ready = {}, fill = {}, rates = {}, owners = {}, shown = {}}
local B = CharacterReforged_PointsBuffBar
B.opened = B.opened or {}              -- bar instances opened in this menu (k -> true)
B.digits = B.digits or {opened = {}, ready = {}, glyph = {}, pos = {}, shown = {}, text = {}}
B.lvl = B.lvl or {opened = {}, ready = {}, shown = {}, text = {}, pos = {}, logged = {}}
B.lvl.logged = B.lvl.logged or {}
B.ON = true                            -- false: no bar (the retail stopwatch everywhere)
B.BAR_W, B.BAR_H = 60, 12              -- bar frame size (layout units; retail frame 476 x 44)
B.DX, B.DY = 0, 0                      -- extra offset from the portrait's position (layout units)
B.GAP = 2                              -- gap between an entry's two bars (layout units)
B.PITCH = 21                           -- distance between an entry's two bar + number blocks (layout units)
B.NUM_H = 9                            -- height of a number glyph cell (layout units); the cell is 44 x 36
B.NUM_W = 9 * 44 / 36
B.NUM_ADV, B.SLASH_ADV, B.ONE_ADV = 7.8, 4.5, 4.8
B.NUM_GAP = 0.5                        -- gap between the bar and its number
B.LEVEL_SCALE = 0.28                   -- the level label's text scale (the telop's text box is 334 x 70)
B.LEVEL_DY = 1
B.PROGRESS_H = 4
B.PROGRESS_GAP = 1
B.LOGS = B.LOGS or 0

local CMD_PEG = @crc:CMND_CHARACTERREFORGED_POINTS_PEG@
local CMD_PE = @crc:CMND_CHARACTERREFORGED_POINTS_STAMINA@ --[[the mod's PE of a match player]]
local CMD_CHANGE = @crc:CMND_CHARACTERREFORGED_CHANGE_SWAP_GAUGE@ --[[Custom Change Mode's swap: active, recovered 0..1]]
local CMD_LOG = @crc:CMND_VRFW_LOG@ --[[the loader's log line]]
local LAYER = @crc:character_reforged_points_buff_bar@
local PORTRAIT = 1535165083 --[[soccer00_53_aura_buff_chara_icon]]
local GAUGE = 698939060 --[[soccer00_54_aura_recast_gauge]]
local ATLAS = 1191797350 --[[#/menu/02_btl/btl06/btl06_13/<LG>/btl06_13.g4tx: the retail gauge's own sprites (hp_bar02)]]
local FILL_SLOT = 1460691304 --[[hp_bar02]]
local FILL_PEG = 2220753497 --[[cr_peg_fill01]]
local FILL_SP = 2390822131 --[[cr_sp_fill01]]
local FILL_CHANGE = @crc:character_reforged_points_change_fill01@
local RATE_BAR = 3060237847 --[[hp_bar]]
local RATE_RED = 2546116024 --[[hp_bar_red]]
local MESH_LABEL = 1257514352 --[[_gtxt_stamina01]]
local MESH_EMPTY = 2609329121 --[[_hp_empty01]]
local FRAME_CX, FRAME_CY, FRAME_W, FRAME_H = 332, -838, 476, 44
local K = {} --[[this block's own constants (one local: the menu's main chunk is near the local limit)]]
K.CMD_LEVEL = @crc:CMND_AURAOVERHAUL_SOULS_TOTEM_LEVEL@ --[[the mod Souls Rework's totem level of a match player: ok, level, text]]
K.DIGIT_LAYER = @crc:character_reforged_points_buff_digit@
K.LEVEL_LAYER = @crc:character_reforged_points_buff_level@
K.SLOTS = 7 --[[glyph slots per bar: 3 digits, slash, 3 digits]]
K.FRAME_SPRITE = 538967808 --[[hp_base01: the gauge frame's sprite the glyphs replace]]
K.MESH_FILL = 2043683848 --[[_hp_bar02]]
K.OWN_ATLAS = 3908013348 --[[#/menu/02_btl/character_reforged_points_hud/<LG>/character_reforged_points_hud.g4tx: the mod's own atlas]]
K.ATLAS_GLYPHS = {[0] = @crc:character_reforged_points_buff_num0@, @crc:character_reforged_points_buff_num1@, @crc:character_reforged_points_buff_num2@,
  @crc:character_reforged_points_buff_num3@, @crc:character_reforged_points_buff_num4@, @crc:character_reforged_points_buff_num5@, @crc:character_reforged_points_buff_num6@,
  @crc:character_reforged_points_buff_num7@, @crc:character_reforged_points_buff_num8@, @crc:character_reforged_points_buff_num9@}
K.GLYPH_SLASH = @crc:character_reforged_points_buff_num_slash@
K.LEVEL_QUAD = @crc:_camera_telop01@ --[[the telop's quad (hidden: the label is the text only)]]
K.LEVEL_TEXT = @crc:_text_telop01@
K.LEVEL_TEXT_W = 334 --[[the text node's box at scale 1]]
K.LEVEL_TEXT_H = 70
K.CMND_GLOBAL_POS = @crc:CMND_GET_MESH_GLOBAL_POSITION@
K.CMND_LAYER_GLOBAL_POS = 4002164178 --[[a layer instance's global position (layer, instance)]]
K.PROBE_TRIES = 6 --[[level label probe: measurements before it gives up on steady units]]
K.CMND_SET_TEXT = @crc:CMND_SET_MENU_TEXT_STRING@
local CMND_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@
local CMND_OPEN = @crc:CMND_OPEN_LAYER@
local CMND_IS_OPEN = @crc:CMND_IS_OPEN_LAYER@
local CMND_IS_LOADING = @crc:CMND_IS_LOADING_LAYER@
local CMND_LOCAL_POS = @crc:CMND_GET_LAYER_LOCAL_POS@
local CMND_SET_POS = @crc:CMND_SET_LAYER_LOCAL_POS@
local CMND_SET_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@
local CMND_RATE_INIT = 541357333
local CMND_RATE = 1595998683
local CMND_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
local CMND_SWAP_TEX = 558735651 --[[swap a mesh texture: (layer, atlas, new sprite, old sprite, 0, instance)]]
local CMND_MEMBER = 66484325 --[[(team, member, true) -> ok, soccer handle]]
local ATTR_KESHIN, ATTR_ARMOUR, ATTR_MIXIMAX, ATTR_TOTEM = 1, 2, 4, 8
local CHANGE = -1 --[[an entry's mode change bar (no aura bit: the swap gauge decides)]]

-- Returns the mode change's recharge (0 to 1) while its swap runs.
local function ChangeRate(hdl)
  local ok, active, rate = pcall(funcLuaCommand, CMD_CHANGE, hdl or 0)
  if ok and active == true and type(rate) == "number" then
    return math.max(0, math.min(1, rate))
  end
  return nil
end

local function Rows()
  local row = rawget(_ENV, "CharacterReforged_PointsBuffRow")
  if type(row) == "table" and type(row.rows) == "function" then
    local ok, n = pcall(row.rows)
    if ok and type(n) == "number" and n > 0 then
      return n
    end
  end
  return nil
end

local function Log(...)
  K.logger = K.logger or VRFW.logger.new("CharacterReforged points buff bar")
  K.logger.debug(...)
end

local function PoolsOn()
  local row = rawget(_ENV, "CharacterReforged_PointsBuffRow")
  if type(row) == "table" and type(row.pools_on) == "function" then
    local ok, on = pcall(row.pools_on)
    return ok and on == true
  end
  return true
end

-- Collects the aura entries that the row just built.
function B.collect()
  local out = {}
  local ok0, okt, team = pcall(GetSoccerTeamInfo, 0)
  if not ok0 or not okt or team == nil then
    return out
  end
  local cap = Rows()
  local users = {}
  local row = rawget(_ENV, "CharacterReforged_PointsBuffRow")
  local drawn = type(row) == "table" and type(row.drawn) == "table" and row.drawn or nil
  for i = 1, drawn ~= nil and #drawn or 0 do
    local d = drawn[i]
    if type(d) == "table" and type(d.auraCharaHdl) == "number" and d.auraCharaHdl ~= 0 and d.auraAttr ~= 0
      and (cap == nil or i <= cap) then
      users[#users + 1] = {hdl = d.auraCharaHdl, attr = d.auraAttr, face = i - 1}
    end
  end
  for i = 0, drawn ~= nil and -1 or 28 do
    local ok, ok2, hdl = pcall(funcLuaCommand, CMND_MEMBER, team, i, true)
    if ok and ok2 and hdl ~= nil and hdl ~= 0 then
      local oka, has, attr = pcall(GetSoccerCharaInfo, hdl, 26)
      if oka and has and type(attr) == "number" and attr ~= 0 then
        users[#users + 1] = {hdl = hdl, attr = attr}
        if cap ~= nil and #users >= cap then
          break
        end
      end
    end
  end
  local rows = cap or (drawn ~= nil and #drawn) or #users
  -- the portrait of each player, logged when it changes
  local map = {}
  for _, u in ipairs(users) do
    map[#map + 1] = string.format("%s:0x%X", tostring(u.face), u.hdl)
  end
  map = table.concat(map, " ")
  if map ~= B.map then
    B.map = map
    Log("portraits", drawn ~= nil and "drawn state" or "member order", map)
  end
  for k0, u in ipairs(users) do
    local k = u.face or (k0 - 1)
    -- the miximax's PE or the mode change's recharge first, then the keshin / armour / totem pool
    local track = 0
    if ChangeRate(u.hdl) ~= nil then
      out[#out + 1] = {k = k, face = k, track = track, hdl = u.hdl, attr = CHANGE}
      track = track + 1
    elseif bit32.band(u.attr, ATTR_MIXIMAX) ~= 0 then
      out[#out + 1] = {k = k, face = k, track = track, hdl = u.hdl, attr = ATTR_MIXIMAX}
      track = track + 1
    end
    local spirit = bit32.band(u.attr, ATTR_KESHIN + ATTR_ARMOUR + ATTR_TOTEM)
    if spirit ~= 0 then
      -- Shows a totem as the entry's first bar.
      local progress = (spirit == ATTR_TOTEM and track == 0) and (k + rows) or nil
      out[#out + 1] = {k = k + track * rows, face = k, track = track, hdl = u.hdl, attr = spirit, progress = progress}
    end
  end
  return out
end

-- Also the pool in whole numbers (cur, max)
function B.rate(hdl, attr)
  if attr == CHANGE then
    local rate = ChangeRate(hdl)
    return rate, rate ~= nil and "change" or nil
  end
  if attr == ATTR_MIXIMAX then
    local ok, has, cur, max, _, on = pcall(funcLuaCommand, CMD_PE, hdl or 0)
    if not ok or has ~= true or on ~= 1 or type(cur) ~= "number" or type(max) ~= "number" or max <= 0 then
      return nil
    end
    return math.max(0, math.min(1, cur / max)), "pe", math.max(0, math.floor(cur + 0.5)), math.floor(max + 0.5)
  end
  if bit32.band(attr or 0, ATTR_KESHIN + ATTR_ARMOUR + ATTR_TOTEM) == 0 then
    return nil
  end
  local ok, has, cur, max, active, _, _, source, soul = pcall(funcLuaCommand, CMD_PEG, hdl or 0)
  if not ok or has ~= true or type(cur) ~= "number" or type(max) ~= "number" or max <= 0 or active ~= 1 or source ~= 1 then
    return nil
  end
  return math.max(0, math.min(1, cur / max)), soul == 1 and "sp" or "peg", math.max(0, math.floor(cur + 0.5)), math.floor(max + 0.5)
end

-- Hides the number under bar k.
function B.hide_number(k)
  local D = B.digits
  D.text[k] = nil
  for slot = 0, K.SLOTS - 1 do
    local inst = k * K.SLOTS + slot
    if D.shown[inst] then
      D.shown[inst] = false
      if VRFW.host.menu_command(CMND_IS_OPEN, K.DIGIT_LAYER, inst) == true then
        VRFW.host.menu_command(CMND_VISIBLE, K.DIGIT_LAYER, inst, false)
      end
    end
  end
end

function B.hide(k)
  B.shown[k] = false
  B.rates[k] = nil
  if VRFW.host.menu_command(CMND_IS_OPEN, LAYER, k) == true then
    VRFW.host.menu_command(CMND_VISIBLE, LAYER, k, false)
  end
  B.hide_number(k)
end

local function Glyphs(cur, max)
  local out = {}
  for d in string.format("%d", math.min(999, cur)):gmatch("%d") do
    out[#out + 1] = tonumber(d)
  end
  out[#out + 1] = "/"
  for d in string.format("%d", math.min(999, max)):gmatch("%d") do
    out[#out + 1] = tonumber(d)
  end
  return out
end

-- Draws the number of bar instance k.
function B.draw_number(k, cur, max, cx, cy, scale)
  local D = B.digits
  local glyphs = Glyphs(cur, max)
  local waiting = false
  for slot = 0, #glyphs - 1 do
    local inst = k * K.SLOTS + slot
    if VRFW.host.menu_command(CMND_IS_OPEN, K.DIGIT_LAYER, inst) ~= true then
      VRFW.host.menu_command(CMND_OPEN, K.DIGIT_LAYER, inst)
      D.opened[inst] = true
      D.ready[inst], D.glyph[inst], D.pos[inst], D.shown[inst] = nil, nil, nil, false
      VRFW.host.menu_command(CMND_VISIBLE, K.DIGIT_LAYER, inst, false)
      waiting = true
    elseif VRFW.host.menu_command(CMND_IS_LOADING, K.DIGIT_LAYER, inst) == true then
      waiting = true
    end
  end
  if waiting then
    return false
  end
  local width = 0
  for _, g in ipairs(glyphs) do
    width = width + (g == "/" and B.SLASH_ADV or (g == 1 and B.ONE_ADV or B.NUM_ADV))
  end
  local w, h = B.NUM_W * scale, B.NUM_H * scale
  local sx, sy = w / FRAME_W, h / FRAME_H
  local x = cx - width * scale / 2
  for i, g in ipairs(glyphs) do
    local inst = k * K.SLOTS + i - 1
    local adv = (g == "/" and B.SLASH_ADV or (g == 1 and B.ONE_ADV or B.NUM_ADV)) * scale
    if not D.ready[inst] then
      D.ready[inst] = true
      D.glyph[inst] = nil
      -- the gauge's frame only
      VRFW.host.menu_command(CMND_MESH_VISIBLE, K.DIGIT_LAYER, MESH_LABEL, false, inst)
      VRFW.host.menu_command(CMND_MESH_VISIBLE, K.DIGIT_LAYER, MESH_EMPTY, false, inst)
      VRFW.host.menu_command(CMND_MESH_VISIBLE, K.DIGIT_LAYER, K.MESH_FILL, false, inst)
    end
    if D.glyph[inst] ~= g then
      D.glyph[inst] = g
      VRFW.host.menu_command(CMND_SWAP_TEX, K.DIGIT_LAYER, K.OWN_ATLAS, g == "/" and K.GLYPH_SLASH or K.ATLAS_GLYPHS[g], K.FRAME_SPRITE, 0, inst)
    end
    -- the cell is centred on its advance
    local px = x + adv / 2 - FRAME_CX * sx
    local py = cy - FRAME_CY * sy
    local old = D.pos[inst]
    if old == nil or math.abs(old[1] - px) > 0.01 or math.abs(old[2] - py) > 0.01 or math.abs(old[3] - sx) > 1e-6 then
      D.pos[inst] = {px, py, sx}
      VRFW.host.menu_command(CMND_SET_SCALE, K.DIGIT_LAYER, sx, sy, 1, inst)
      VRFW.host.menu_command(CMND_SET_POS, K.DIGIT_LAYER, px, py, 0, inst)
    end
    if not D.shown[inst] then
      D.shown[inst] = true
      VRFW.host.menu_command(CMND_VISIBLE, K.DIGIT_LAYER, inst, true)
    end
    x = x + adv
  end
  for slot = #glyphs, K.SLOTS - 1 do
    local inst = k * K.SLOTS + slot
    if D.shown[inst] then
      D.shown[inst] = false
      VRFW.host.menu_command(CMND_VISIBLE, K.DIGIT_LAYER, inst, false)
    end
  end
  return true
end

function B.draw(e)
  if VRFW.host.menu_command(CMND_IS_VISIBLE, PORTRAIT, e.face) ~= true then
    B.hide(e.k)
    return false
  end
  local rate, soul, cur, max = B.rate(e.hdl, e.attr)
  if rate == nil then
    B.hide(e.k)
    return false
  end
  if VRFW.host.menu_command(CMND_IS_OPEN, LAYER, e.k) ~= true then
    VRFW.host.menu_command(CMND_OPEN, LAYER, e.k)
    B.opened[e.k] = true
    B.ready[e.k] = nil
    B.shown[e.k] = false
    B.rates[e.k] = nil
    return false
  end
  if VRFW.host.menu_command(CMND_IS_LOADING, LAYER, e.k) == true then
    return false
  end
  if B.owners[e.k] ~= e.hdl then
    B.owners[e.k] = e.hdl
    B.ready[e.k] = nil
  end
  if not B.ready[e.k] then
    B.ready[e.k] = true
    B.fill[e.k] = nil
    B.rates[e.k] = nil
    VRFW.host.menu_command(CMND_RATE_INIT, LAYER, RATE_BAR, 0, e.k)
    VRFW.host.menu_command(CMND_RATE_INIT, LAYER, RATE_RED, 0, e.k)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LAYER, MESH_LABEL, false, e.k)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LAYER, MESH_EMPTY, false, e.k)
  end
  if B.fill[e.k] ~= soul then
    B.fill[e.k] = soul
    VRFW.host.menu_command(CMND_SWAP_TEX, LAYER, soul == "pe" and ATLAS or K.OWN_ATLAS, soul == "pe" and FILL_SLOT or (soul == "change" and FILL_CHANGE or (soul == "sp" and FILL_SP or FILL_PEG)), FILL_SLOT, 0, e.k)
  end
  -- the entry's stopwatch off, the bar on its place
  VRFW.host.menu_command(CMND_VISIBLE, GAUGE, e.face, false)
  -- The bar hangs on the portrait's locator (attach rows copied by buff_bar.toml).
  local gx, gy = VRFW.host.menu_command(CMND_LOCAL_POS, PORTRAIT, e.face)
  if type(gx) ~= "number" or type(gy) ~= "number" then
    gx, gy = 0, 0
  end
  -- Better UI draws the row's icons at 0.85
  local better_ui = rawget(_ENV, "BetterUI")
  local flags = type(better_ui) == "table" and better_ui.flags or nil
  local scale = (type(better_ui) == "table" and better_ui.preset ~= "off" and type(flags) == "table" and flags.buff_icons == true) and 0.85 or 1
  local sx, sy = B.BAR_W * scale / FRAME_W, B.BAR_H * scale / FRAME_H
  local block = (e.track or 0) * B.PITCH                      -- the entry's second bar + number block lies lower
  local bar_half = 28 * B.BAR_H / FRAME_H / 2                  -- half the bar's visible height
  local bar_y = gy - (36 + 2 + bar_half + block) * scale
  gy = bar_y
  local px = gx + B.DX - FRAME_CX * sx
  local py = gy + B.DY - FRAME_CY * sy
  VRFW.host.menu_command(CMND_SET_SCALE, LAYER, sx, sy, 1, e.k)
  VRFW.host.menu_command(CMND_SET_POS, LAYER, px, py, 0, e.k)
  if not B.shown[e.k] then
    VRFW.host.menu_command(CMND_VISIBLE, LAYER, e.k, true)
    B.shown[e.k] = true
    B.rates[e.k] = nil
  end
  -- the rate animation only when the value changed (restarting it every frame leaves a new bar empty)
  if B.rates[e.k] == nil or math.abs(B.rates[e.k] - rate) > 0.0005 then
    B.rates[e.k] = rate
    VRFW.host.menu_command(CMND_RATE, LAYER, RATE_BAR, 0, rate, e.k, true)
    VRFW.host.menu_command(CMND_RATE, LAYER, RATE_RED, 0, rate, e.k, true)
  end
  if cur ~= nil and max ~= nil then
    local ny = bar_y - (bar_half + B.NUM_GAP + B.NUM_H / 2) * scale
    B.draw_number(e.k, cur, max, gx + B.DX, ny, scale)
    e.under = {x = gx + B.DX, y = ny - (B.NUM_H / 2 + B.PROGRESS_GAP) * scale, scale = scale}
  else
    B.hide_number(e.k)
    e.under = nil
  end
  if B.LOGS < 6 then
    B.LOGS = B.LOGS + 1
    Log("entry", e.k, "hdl", string.format("0x%X", e.hdl), "attr", e.attr, soul, string.format("%.2f", rate), "portrait", tostring(gx), tostring(gy), "bar", px, py)
  end
  return true
end


-- Measures once on instance 0 the text node's offset from the layer position (position units at scale 1).
function B.level_node()
  local L = B.lvl
  if L.node ~= nil then
    return L.node ~= false and L.node or nil
  end
  if VRFW.host.menu_command(CMND_IS_OPEN, K.LEVEL_LAYER, 0) ~= true then
    VRFW.host.menu_command(CMND_OPEN, K.LEVEL_LAYER, 0)
    L.opened[0] = true
    L.probe = nil
    return nil
  end
  if VRFW.host.menu_command(CMND_IS_LOADING, K.LEVEL_LAYER, 0) == true then
    return nil
  end
  local p = L.probe
  if p == nil then
    L.probe = {stage = 0, wait = 2, tries = (L.tries or 0) + 1}
    L.tries = L.probe.tries
    VRFW.host.menu_command(CMND_VISIBLE, K.LEVEL_LAYER, 0, false)
    VRFW.host.menu_command(CMND_SET_SCALE, K.LEVEL_LAYER, 1, 1, 1, 0)
    VRFW.host.menu_command(CMND_SET_POS, K.LEVEL_LAYER, 0, 0, 0, 0)
    return nil
  end
  if p.wait > 0 then
    p.wait = p.wait - 1
    return nil
  end
  local x, y = VRFW.host.menu_command(K.CMND_GLOBAL_POS, K.LEVEL_LAYER, 0, K.LEVEL_TEXT)
  if type(x) ~= "number" or type(y) ~= "number" then
    L.node = false
    Log("level label: no global position for its text node: off")
    return nil
  end
  local step = 100
  -- Handles stage 0.
  if p.stage == 0 then
    if p.rx ~= nil and math.abs(p.rx - x) < 0.5 and math.abs(p.ry - y) < 0.5 then
      p.stage = 1
    else
      p.rx, p.ry, p.wait = x, y, 2
      return nil
    end
  end
  if p.stage == 1 then
    p.x1, p.y1, p.stage, p.wait = x, y, 2, 2
    VRFW.host.menu_command(CMND_SET_POS, K.LEVEL_LAYER, step, step, 0, 0)
    return nil
  end
  if p.stage == 2 then
    p.x2, p.y2, p.stage, p.wait = x, y, 3, 2
    VRFW.host.menu_command(CMND_SET_POS, K.LEVEL_LAYER, 0, 0, 0, 0)
    VRFW.host.menu_command(CMND_SET_SCALE, K.LEVEL_LAYER, 2, 2, 1, 0)
    return nil
  end
  local ux, uy = (p.x2 - p.x1) / step, (p.y2 - p.y1) / step
  VRFW.host.menu_command(CMND_SET_SCALE, K.LEVEL_LAYER, 1, 1, 1, 0)
  local skew = math.abs(math.abs(ux) - math.abs(uy)) / math.max(math.abs(ux), math.abs(uy), 0.01)
  if skew > 0.02 and L.tries < K.PROBE_TRIES then
    Log("level label: probe", L.tries, string.format("units differ (%.3f %.3f): measuring again", ux, uy))
    L.probe = nil
    return nil
  end
  if math.abs(ux) < 0.01 or math.abs(uy) < 0.01 then
    L.node = false
    Log("level label: its position does not move its text node: off")
    return nil
  end
  L.node = {x = (x - p.x1) / ux, y = (y - p.y1) / uy}
  Log("level label: text node offset", string.format("%.1f %.1f", L.node.x, L.node.y), "units",
    string.format("%.3f %.3f", ux, uy), "probe", L.tries)
  return L.node
end

function B.hide_level(k)
  local L = B.lvl
  L.shown[k] = false
  L.text[k] = nil
  if VRFW.host.menu_command(CMND_IS_OPEN, K.LEVEL_LAYER, k) == true then
    VRFW.host.menu_command(CMND_VISIBLE, K.LEVEL_LAYER, k, false)
  end
end

-- Hides the totem's next-level bar of entry e.
function B.hide_progress(e)
  if e.progress ~= nil and B.shown[e.progress] then
    B.hide(e.progress)
  end
end

-- Draws the totem's next-level bar of entry e.
function B.draw_progress(e, rate)
  local k, u = e.progress, e.under
  if k == nil or u == nil then
    B.hide_progress(e)
    return
  end
  if VRFW.host.menu_command(CMND_IS_OPEN, LAYER, k) ~= true then
    VRFW.host.menu_command(CMND_OPEN, LAYER, k)
    B.opened[k] = true
    B.ready[k], B.shown[k], B.rates[k] = nil, false, nil
    return
  end
  if VRFW.host.menu_command(CMND_IS_LOADING, LAYER, k) == true then
    return
  end
  if B.owners[k] ~= e.hdl then
    B.owners[k] = e.hdl
    B.ready[k] = nil
  end
  if not B.ready[k] then
    B.ready[k] = true
    B.rates[k] = nil
    VRFW.host.menu_command(CMND_RATE_INIT, LAYER, RATE_BAR, 0, k)
    VRFW.host.menu_command(CMND_RATE_INIT, LAYER, RATE_RED, 0, k)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LAYER, MESH_LABEL, false, k)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LAYER, MESH_EMPTY, false, k)
  end
  if B.fill[k] ~= "progress" then
    B.fill[k] = "progress"
    VRFW.host.menu_command(CMND_SWAP_TEX, LAYER, ATLAS, FILL_SLOT, FILL_SLOT, 0, k)
  end
  B.hide_number(k)
  local sx, sy = B.BAR_W * u.scale / FRAME_W, B.PROGRESS_H * u.scale / FRAME_H
  local half = 28 * B.PROGRESS_H / FRAME_H / 2 * u.scale
  VRFW.host.menu_command(CMND_SET_SCALE, LAYER, sx, sy, 1, k)
  VRFW.host.menu_command(CMND_SET_POS, LAYER, u.x - FRAME_CX * sx, u.y - half - FRAME_CY * sy, 0, k)
  if not B.shown[k] then
    VRFW.host.menu_command(CMND_VISIBLE, LAYER, k, true)
    B.shown[k] = true
    B.rates[k] = nil
  end
  if B.rates[k] == nil or math.abs(B.rates[k] - rate) > 0.0005 then
    B.rates[k] = rate
    VRFW.host.menu_command(CMND_RATE, LAYER, RATE_BAR, 0, rate, k, true)
    VRFW.host.menu_command(CMND_RATE, LAYER, RATE_RED, 0, rate, k, true)
  end
end

function B.draw_level(e)
  local L = B.lvl
  if VRFW.host.menu_command(CMND_IS_VISIBLE, PORTRAIT, e.face) ~= true then
    B.hide_level(e.face)
    return false
  end
  local has, level, text, progress, top = VRFW.host.command(K.CMD_LEVEL, e.hdl or 0)
  if has ~= true or type(level) ~= "number" or type(text) ~= "string" or text == "" then
    B.hide_level(e.face)
    B.hide_progress(e)
    return false
  end
  if top == 1 or type(progress) ~= "number" then
    B.hide_progress(e)
  else
    B.draw_progress(e, progress)
  end
  local node = B.level_node()
  if node == nil then
    return false
  end
  local k = e.face
  if VRFW.host.menu_command(CMND_IS_OPEN, K.LEVEL_LAYER, k) ~= true then
    VRFW.host.menu_command(CMND_OPEN, K.LEVEL_LAYER, k)
    L.opened[k] = true
    L.ready[k], L.shown[k], L.text[k], L.pos[k] = nil, false, nil, nil
    VRFW.host.menu_command(CMND_VISIBLE, K.LEVEL_LAYER, k, false)
    return false
  end
  if VRFW.host.menu_command(CMND_IS_LOADING, K.LEVEL_LAYER, k) == true then
    return false
  end
  if not L.ready[k] then
    L.ready[k] = true
    VRFW.host.menu_command(CMND_VISIBLE, K.LEVEL_LAYER, k, false)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, K.LEVEL_LAYER, K.LEVEL_QUAD, false, k)
  end
  if L.text[k] ~= text then
    L.text[k] = text
    VRFW.host.menu_command(K.CMND_SET_TEXT, K.LEVEL_LAYER, K.LEVEL_TEXT, text, k)
  end
  local gx, gy = VRFW.host.menu_command(CMND_LOCAL_POS, PORTRAIT, k)
  if type(gx) ~= "number" or type(gy) ~= "number" then
    gx, gy = 0, 0
  end
  local better_ui = rawget(_ENV, "BetterUI")
  local flags = type(better_ui) == "table" and better_ui.flags or nil
  local scale = (type(better_ui) == "table" and better_ui.preset ~= "off" and type(flags) == "table" and flags.buff_icons == true) and 0.85 or 1
  local ts = B.LEVEL_SCALE * scale
  local w, h = K.LEVEL_TEXT_W * ts, K.LEVEL_TEXT_H * ts
  local cx, cy = gx, gy + (36 - B.LEVEL_DY) * scale
  local px, py = cx - w / 2 - ts * node.x, cy + h / 2 - ts * node.y
  local old = L.pos[k]
  if old == nil or math.abs(old[1] - px) > 0.01 or math.abs(old[2] - py) > 0.01 or math.abs(old[3] - ts) > 1e-6 then
    L.pos[k] = {px, py, ts}
    L.logged[k] = nil
    VRFW.host.menu_command(CMND_SET_SCALE, K.LEVEL_LAYER, ts, ts, 1, k)
    VRFW.host.menu_command(CMND_SET_POS, K.LEVEL_LAYER, px, py, 0, k)
  end
  if not L.shown[k] then
    L.shown[k] = true
    VRFW.host.menu_command(CMND_VISIBLE, K.LEVEL_LAYER, k, true)
  elseif not L.logged[k] then
    L.logged[k] = true
    local portrait_x = VRFW.host.menu_command(K.CMND_LAYER_GLOBAL_POS, PORTRAIT, k)
    local text_x = VRFW.host.menu_command(K.CMND_GLOBAL_POS, K.LEVEL_LAYER, k, K.LEVEL_TEXT)
    Log("level label", text, "hdl", string.format("0x%X", e.hdl or 0), "instance", k, "portrait local x", tostring(gx),
      "portrait global x", tostring(portrait_x), "label local x", string.format("%.1f", px), "text node global x",
      tostring(text_x))
  end
  return true
end

-- Runs every frame for the level text.
function B.level_frame()
  local L = B.lvl
  local used = {}
  for _, e in ipairs(B.entries) do
    if e.attr == ATTR_TOTEM and B.draw_level(e) then
      used[e.face] = true
    end
  end
  for k, on in pairs(L.shown) do
    if on and not used[k] then
      B.hide_level(k)
    end
  end
  -- an opened instance no totem entry drew this frame stays hidden even when the layer showed itself again
  for k in pairs(L.opened) do
    if not used[k] and k ~= 0 and VRFW.host.menu_command(CMND_IS_VISIBLE, K.LEVEL_LAYER, k) == true then
      B.hide_level(k)
    elseif not used[k] and k == 0 and L.node ~= nil and VRFW.host.menu_command(CMND_IS_VISIBLE, K.LEVEL_LAYER, 0) == true then
      B.hide_level(0)
    end
  end
end

-- Runs every frame.
function B.frame()
  if not B.ON or not PoolsOn() then
    return
  end
  local used = {}
  for _, e in ipairs(B.entries) do
    if B.draw(e) then
      used[e.k] = true
      if e.progress ~= nil then
        used[e.progress] = true
      end
    end
  end
  for k, on in pairs(B.shown) do
    if on and not used[k] then
      B.hide(k)
    end
  end
  -- an opened instance no entry drew this frame stays hidden even when the layer showed itself again
  for k in pairs(B.opened) do
    if not used[k] and VRFW.host.menu_command(CMND_IS_VISIBLE, LAYER, k) == true then
      B.hide(k)
    end
  end
  -- the glyph slots of the bars no entry drew
  for inst in pairs(B.digits.opened) do
    local k = math.floor(inst / K.SLOTS)
    if not used[k] and VRFW.host.menu_command(CMND_IS_VISIBLE, K.DIGIT_LAYER, inst) == true then
      B.hide_number(k)
      VRFW.host.menu_command(CMND_VISIBLE, K.DIGIT_LAYER, inst, false)
    end
  end
  B.level_frame()
end

if B.origUpdate == nil and type(UpdateAuraBuffCharaIcon) == "function" then
  B.origUpdate = UpdateAuraBuffCharaIcon
  function UpdateAuraBuffCharaIcon(...)
    local r = table.pack(B.origUpdate(...))
    if B.ON then
      local ok, ents = pcall(B.collect)
      B.entries = ok and ents or {}
      pcall(B.frame)
    end
    return table.unpack(r, 1, r.n)
  end
end
if B.origStep == nil and type(Step) == "function" then
  B.origStep = Step
  function Step(...)
    local r = table.pack(B.origStep(...))
    local row = rawget(_ENV, "CharacterReforged_PointsBuffRow")
    if type(row) == "table" and type(row.step) == "function" then
      pcall(row.step)
    end
    pcall(B.frame)
    return table.unpack(r, 1, r.n)
  end
end
