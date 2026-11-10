CharacterReforged_PointsHud = CharacterReforged_PointsHud or {}
local H = CharacterReforged_PointsHud
H.ON = true                            -- false: no bar
H.BAR_W, H.BAR_H = 92, 12              -- bar frame size, layout units (retail frame 476 x 44)
H.FACE_RADIUS = 56
H.BAR_GAP = 4                          -- between the bubble and the bar (no PE bar above)
H.PE_GAP = 1.5                         -- between the PE bar's visible frame and this bar's
H.DX, H.DY = 0, 0                      -- extra offset of the bar (layout units, y up)
H.LABEL = true
H.LABEL_GAP = 2                        -- between the tag and the bar's frame
H.LABEL_ASPECT = 68 / 28
H.SHINE = true                         -- glass gloss over the bar while the spirit is out
H.SHINE_FRAMES, H.SHINE_PAUSE = 40, 25 -- frames of one sweep (left to right), frames between two sweeps
H.SHINE_ALPHA = 1
H.SHINE_MIN = 0.03                     -- no gloss below this fill
H.EMPTY_HOLD = 90                      -- frames the empty bar stays after the pool reached 0, then hidden

local CMD_PEG = @crc:CMND_CHARACTERREFORGED_POINTS_PEG@
local BALLOON = 3573161010 --[[soccer02_22_chara_face_balloon]]
local LAYER = @crc:character_reforged_points_peg_bar@
local SHINE = @crc:character_reforged_points_peg_shine@
local LABEL = @crc:character_reforged_points_peg_label@
local RATE_BAR = 3060237847 --[[hp_bar]]
local RATE_RED = 2546116024 --[[hp_bar_red]]
local MESH_LABEL = 1257514352 --[[_gtxt_stamina01]]
local MESH_EMPTY = 2609329121 --[[_hp_empty01]]
local MESH_BAR = 2043683848 --[[_hp_bar02]]
local MESH_FRAME = 1837325853 --[[_hp_base01]]
local CMND_POS = @crc:CMND_SET_LAYER_LOCAL_POS@
local CMND_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@
local CMND_VISIBLE = @crc:CMND_SET_LAYER_VISIBLE@
local CMND_IS_VISIBLE = @crc:CMND_IS_LAYER_VISIBLE@
local CMND_OPEN = @crc:CMND_OPEN_LAYER@
local CMND_IS_OPEN = @crc:CMND_IS_OPEN_LAYER@
local CMND_IS_LOADING = @crc:CMND_IS_LOADING_LAYER@
local CMND_SUSPEND = @crc:CMND_SUSPEND_LAYER@
local CMND_RESUME = @crc:CMND_RESUME_LAYER@
local CMND_IS_SUSPENDED = 15180
local CMND_RATE_INIT = 541357333
local CMND_RATE = 1595998683
local CMND_MESH_VISIBLE = @crc:CMND_SET_MESH_VISIBLE@
local CMND_PRIM_ALPHA = @crc:CMND_SET_PRIM_ALPHA@
local CMND_SWAP_TEX = 558735651 --[[swap a mesh texture: (layer, atlas, new sprite, old sprite, 0, instance)]]
local CMND_LAYOUT_TO_POS = 1192474820 --[[layout offset -> layer position offset (retail UpdateScreenOutCtrlCharaIcon)]]
local ATLAS = 3908013348 --[[#/menu/02_btl/character_reforged_points_hud/<LG>/character_reforged_points_hud.g4tx: the mod's own atlas]]
local TEX_FILL = 1460691304 --[[hp_bar02: the fill's texture slot]]
local TEX_FRAME = 538967808 --[[hp_base01: the frame's texture slot]]
local PEG_FILL = 2220753497 --[[cr_peg_fill01]]
local PEG_TAG = 1575081510 --[[cr_peg_tag01]]
local SP_FILL = 2390822131 --[[cr_sp_fill01]]
local SP_TAG = 2185321384 --[[cr_sp_tag01]]
-- Geometry of the retail gauge frame _hp_base01.
local FRAME_CX, FRAME_CY, FRAME_W, FRAME_H = 332, -838, 476, 44
local FRAME_VIS_H, FRAME_VIS_CY = 28, -832
local GLOSS = {
  @crc:character_reforged_points_gloss_00@, @crc:character_reforged_points_gloss_01@, @crc:character_reforged_points_gloss_02@, @crc:character_reforged_points_gloss_03@,
  @crc:character_reforged_points_gloss_04@, @crc:character_reforged_points_gloss_05@, @crc:character_reforged_points_gloss_06@, @crc:character_reforged_points_gloss_07@,
  @crc:character_reforged_points_gloss_08@, @crc:character_reforged_points_gloss_09@, @crc:character_reforged_points_gloss_10@, @crc:character_reforged_points_gloss_11@,
  @crc:character_reforged_points_gloss_12@, @crc:character_reforged_points_gloss_13@, @crc:character_reforged_points_gloss_14@, @crc:character_reforged_points_gloss_15@,
  @crc:character_reforged_points_gloss_16@, @crc:character_reforged_points_gloss_17@, @crc:character_reforged_points_gloss_18@, @crc:character_reforged_points_gloss_19@,
  @crc:character_reforged_points_gloss_20@, @crc:character_reforged_points_gloss_21@, @crc:character_reforged_points_gloss_22@, @crc:character_reforged_points_gloss_23@,
  @crc:character_reforged_points_gloss_24@, @crc:character_reforged_points_gloss_25@, @crc:character_reforged_points_gloss_26@, @crc:character_reforged_points_gloss_27@,
  @crc:character_reforged_points_gloss_28@, @crc:character_reforged_points_gloss_29@, @crc:character_reforged_points_gloss_30@, @crc:character_reforged_points_gloss_31@,
  @crc:character_reforged_points_gloss_32@, @crc:character_reforged_points_gloss_33@, @crc:character_reforged_points_gloss_34@, @crc:character_reforged_points_gloss_35@,
  @crc:character_reforged_points_gloss_36@, @crc:character_reforged_points_gloss_37@, @crc:character_reforged_points_gloss_38@, @crc:character_reforged_points_gloss_39@,
  @crc:character_reforged_points_gloss_40@, @crc:character_reforged_points_gloss_41@, @crc:character_reforged_points_gloss_42@, @crc:character_reforged_points_gloss_43@,
  @crc:character_reforged_points_gloss_44@, @crc:character_reforged_points_gloss_45@, @crc:character_reforged_points_gloss_46@, @crc:character_reforged_points_gloss_47@,
}
local GLOSS_C0, GLOSS_C1 = -0.10, 1.10

-- State of this frame.
H.frame = H.frame or { hdl = 0, shown = false, x = nil, y = nil }
H.empty = H.empty or {}                -- handle -> frames drawn with an empty pool
local st = { bar = false, shine = false, label = false, rate = nil, shine_rate = nil, shine_frame = nil, shine_t = 0,
  ready = false, shine_ready = false, label_ready = false, fill_soul = nil, tag_soul = nil }

local function pack(...) return { n = select("#", ...), ... } end

-- Returns the pool ratio (0 to 1), spirit out (bool), pool empty (bool) and a totem's SP (bool).
local function query(hdl)
  if type(funcLuaCommand) ~= "function" then return nil end
  local ok, has, cur, max, active, _, _, _, soul = pcall(funcLuaCommand, CMD_PEG, hdl or 0)
  if not ok or has ~= true or type(cur) ~= "number" or type(max) ~= "number" or max <= 0 then return nil end
  local r = cur / max
  if r ~= r or r < 0 then r = 0 elseif r > 1 then r = 1 end
  return r, active == 1, cur <= 0, soul == 1
end

-- Returns the bar value of this frame.
local function value(hdl)
  local rate, active, empty, soul = query(hdl)
  if rate == nil then return nil, false, false end
  if not empty then
    H.empty[hdl] = nil
    return rate, active, soul
  end
  local n = math.min((H.empty[hdl] or 0) + 1, H.EMPTY_HOLD + 1)
  H.empty[hdl] = n
  if n > H.EMPTY_HOLD then return nil, false, false end
  return 0, active, soul
end

local function to_pos(dx, dy)
  local _, x, y = VRFW.host.menu_command(CMND_LAYOUT_TO_POS, dx, dy)
  if type(x) == "number" and type(y) == "number" then return x, y end
  return dx, dy
end

local function hide_layer(l)
  VRFW.host.menu_command(CMND_VISIBLE, l, 0, false)
  if VRFW.host.menu_command(CMND_IS_SUSPENDED, l) ~= true then VRFW.host.menu_command(CMND_SUSPEND, l) end
end

local function show_layer(l)
  if VRFW.host.menu_command(CMND_IS_SUSPENDED, l) == true then VRFW.host.menu_command(CMND_RESUME, l) end
  VRFW.host.menu_command(CMND_VISIBLE, l, 0, true)
end

-- Returns whether a layer was opened once and loaded.
local function layer_ready(l)
  if VRFW.host.menu_command(CMND_IS_OPEN, l) ~= true then
    VRFW.host.menu_command(CMND_OPEN, l)
    return false, true
  end
  return VRFW.host.menu_command(CMND_IS_LOADING, l) ~= true, false
end

local function hide_shine()
  if st.shine then
    st.shine = false
    hide_layer(SHINE)
  end
  st.shine_t = 0
end

local function hide_all()
  hide_shine()
  if st.label then
    st.label = false
    hide_layer(LABEL)
  end
  if st.bar then
    st.bar = false
    hide_layer(LAYER)
  end
end

-- Returns the gloss sprite (1-based index of GLOSS) at frame t of the cycle on a fill of rate, or nil in the pause.
local function shine_frame(t, rate)
  local n = math.max(1, H.SHINE_FRAMES)
  if t < 0 or t >= n or type(rate) ~= "number" or rate < H.SHINE_MIN then return nil end
  local c = GLOSS_C0 + (math.min(rate, 1) + (GLOSS_C1 - 1) - GLOSS_C0) * t / (n - 1 > 0 and n - 1 or 1)
  local k = math.floor((c - GLOSS_C0) / (GLOSS_C1 - GLOSS_C0) * (#GLOSS - 1) + 0.5)
  return math.max(0, math.min(#GLOSS - 1, k)) + 1
end

-- Returns the bar layer position and scale.
local function bar_pos()
  local sx, sy = H.BAR_W / FRAME_W, H.BAR_H / FRAME_H
  local pe_hud = type(CharacterReforged) == "table" and type(CharacterReforged.points_hud) == "table" and CharacterReforged.points_hud or {}
  local pe = pe_hud.FRAME
  local pe_pos = pe_hud.bar_pos
  if type(pe) == "table" and pe.shown and pe.x ~= nil and pe.rate ~= nil and pe_hud.BAR_SHOWN == true
    and type(pe_pos) == "function" then
    local ok, px, py, psx, psy = pcall(pe_pos, pe.x, pe.y, pe_hud.FACE_SCALE or 1)
    if ok and type(px) == "number" and type(py) == "number" then
      sx, sy = psx or sx, psy or sy
      local ox, oy = to_pos(H.DX, -(FRAME_VIS_H * sy + H.PE_GAP) + H.DY)
      return px + ox, py + oy, sx, sy
    end
  end
  local f = H.frame
  local bx, by = f.x, f.y
  local s = 1
  if type(pe) == "table" and pe.shown and pe.x ~= nil then
    -- The PE HUD moved or scaled the bubble.
    bx, by, s = pe.x, pe.y, pe_hud.FACE_SCALE or 1
  end
  if bx == nil or by == nil then return nil end
  local ox, oy = to_pos(H.DX, -(H.FACE_RADIUS * s + H.BAR_GAP + H.BAR_H / 2) + H.DY)
  local cx, cy = to_pos(FRAME_CX * sx, FRAME_CY * sy)
  return bx + ox - cx, by + oy - cy, sx, sy
end

local function draw_label(px, py, sx, sy, soul)
  if not H.LABEL then
    if st.label then
      st.label = false
      hide_layer(LABEL)
    end
    return
  end
  local ready, opened = layer_ready(LABEL)
  if opened then st.label_ready = false end
  if not ready then return end
  if not st.label_ready then
    st.label_ready = true
    st.tag_soul = nil
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LABEL, MESH_LABEL, false, 0)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LABEL, MESH_EMPTY, false, 0)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LABEL, MESH_BAR, false, 0)
  end
  if st.tag_soul ~= soul then
    st.tag_soul = soul
    VRFW.host.menu_command(CMND_SWAP_TEX, LABEL, ATLAS, soul and SP_TAG or PEG_TAG, TEX_FRAME, 0, 0)
  end
  local h = FRAME_VIS_H * sy
  local w = H.LABEL_ASPECT * h
  local tsx, tsy = w / FRAME_W, h / FRAME_H
  local ox, oy = to_pos(94 * sx - H.LABEL_GAP - w / 2 - FRAME_CX * tsx, FRAME_VIS_CY * sy - FRAME_CY * tsy)
  VRFW.host.menu_command(CMND_SCALE, LABEL, tsx, tsy, 1, 0)
  VRFW.host.menu_command(CMND_POS, LABEL, px + ox, py + oy, 0, 0)
  if not st.label then
    st.label = true
    show_layer(LABEL)
  end
end

local function draw_shine(px, py, sx, sy, rate, active)
  if not (H.SHINE and active) then
    hide_shine()
    return
  end
  local ready, opened = layer_ready(SHINE)
  if opened then st.shine_ready = false end
  if not ready then return end
  if not st.shine_ready then
    st.shine_ready = true
    st.shine_frame, st.shine_rate = nil, nil
    VRFW.host.menu_command(CMND_RATE_INIT, SHINE, RATE_BAR, 0)
    VRFW.host.menu_command(CMND_RATE_INIT, SHINE, RATE_RED, 0)
    VRFW.host.menu_command(CMND_RATE, SHINE, RATE_RED, 0, 0, 0, true)   -- no red trail under the gloss
    VRFW.host.menu_command(CMND_MESH_VISIBLE, SHINE, MESH_FRAME, false, 0)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, SHINE, MESH_LABEL, false, 0)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, SHINE, MESH_EMPTY, false, 0)
    VRFW.host.menu_command(CMND_PRIM_ALPHA, SHINE, 0, MESH_BAR, H.SHINE_ALPHA)
  end
  local cycle = math.max(1, H.SHINE_FRAMES) + math.max(0, H.SHINE_PAUSE)
  local k = shine_frame(st.shine_t % cycle, rate)
  st.shine_t = st.shine_t + 1
  if k == nil then
    if st.shine then
      st.shine = false
      hide_layer(SHINE)
    end
    return
  end
  if st.shine_frame ~= k then
    st.shine_frame = k
    VRFW.host.menu_command(CMND_SWAP_TEX, SHINE, ATLAS, GLOSS[k], TEX_FILL, 0, 0)
  end
  if st.shine_rate == nil or math.abs(st.shine_rate - rate) > 0.0005 then
    st.shine_rate = rate
    VRFW.host.menu_command(CMND_RATE, SHINE, RATE_BAR, 0, rate, 0, true)
  end
  VRFW.host.menu_command(CMND_SCALE, SHINE, sx, sy, 1, 0)
  VRFW.host.menu_command(CMND_POS, SHINE, px, py, 0, 0)
  if not st.shine then
    st.shine = true
    show_layer(SHINE)
  end
end

-- Opens the bar layer once.
local function open_bar(soul)
  local ready, opened = layer_ready(LAYER)
  if opened then st.ready = false end
  if not ready then return false end
  if not st.ready then
    st.ready = true
    st.fill_soul = nil
    st.rate = nil
    VRFW.host.menu_command(CMND_RATE_INIT, LAYER, RATE_BAR, 0)
    VRFW.host.menu_command(CMND_RATE_INIT, LAYER, RATE_RED, 0)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LAYER, MESH_LABEL, false, 0)
    VRFW.host.menu_command(CMND_MESH_VISIBLE, LAYER, MESH_EMPTY, false, 0)
  end
  -- purple PEG fill for a keshin / armour, blue SP fill for a totem (swapped again when the kind changes)
  if st.fill_soul ~= soul then
    st.fill_soul = soul
    VRFW.host.menu_command(CMND_SWAP_TEX, LAYER, ATLAS, soul and SP_FILL or PEG_FILL, TEX_FILL, 0, 0)
  end
  return true
end

-- Draws once per frame (PostStep).
function H.draw()
  local f = H.frame
  local vis = f.shown and VRFW.host.menu_command(CMND_IS_OPEN, BALLOON) == true and VRFW.host.menu_command(CMND_IS_VISIBLE, BALLOON, 0) == true
  if not H.ON or not vis or type(f.hdl) ~= "number" or f.hdl == 0 then
    hide_all()
    return
  end
  local rate, active, soul = value(f.hdl)
  if rate == nil then
    hide_all()
    return
  end
  local px, py, sx, sy = bar_pos()
  if px == nil then
    hide_all()
    return
  end
  if not open_bar(soul) then return end
  VRFW.host.menu_command(CMND_SCALE, LAYER, sx, sy, 1, 0)
  VRFW.host.menu_command(CMND_POS, LAYER, px, py, 0, 0)
  if st.rate == nil or math.abs(st.rate - rate) > 0.0005 then
    st.rate = rate
    VRFW.host.menu_command(CMND_RATE, LAYER, RATE_BAR, 0, rate, 0, true)
    VRFW.host.menu_command(CMND_RATE, LAYER, RATE_RED, 0, rate, 0, true)
  end
  if not st.bar then
    st.bar = true
    show_layer(LAYER)
  end
  draw_label(px, py, sx, sy, soul)
  draw_shine(px, py, sx, sy, rate, active)
end

local AP_prevCtrlIcon = UpdateScreenOutCtrlCharaIcon
function UpdateScreenOutCtrlCharaIcon(a1, a2, a3, a4)
  if type(AP_prevCtrlIcon) ~= "function" then
    return                               -- a twin without the include: nothing to wrap
  end
  if not H.ON or type(funcLuaMenuCommand) ~= "function" then
    return AP_prevCtrlIcon(a1, a2, a3, a4)
  end
  local f = H.frame
  f.hdl, f.shown, f.x, f.y = type(a1) == "number" and a1 or 0, false, nil, nil
  local real = funcLuaMenuCommand
  funcLuaMenuCommand = function(...)
    local c, layer, x, y = ...
    if layer == BALLOON then
      if c == CMND_POS and type(x) == "number" and type(y) == "number" then
        f.x, f.y = x, y
      elseif c == CMND_VISIBLE then
        local _, _, _, v = ...
        f.shown = v == true
      end
    end
    return real(...)
  end
  local r = pack(pcall(AP_prevCtrlIcon, a1, a2, a3, a4))
  funcLuaMenuCommand = real
  if not r[1] then
    error(r[2], 0)
  end
  return table.unpack(r, 2, r.n)
end

-- Runs every frame, after the bubble's update and the PE bar.
local AP_prevPostStep = rawget(_ENV, "PostStep")
function PostStep(...)
  local r = { n = 0 }
  if type(AP_prevPostStep) == "function" then
    r = pack(AP_prevPostStep(...))
  end
  pcall(H.draw)
  return table.unpack(r, 1, r.n)
end
