-- ===== EVT FootballReforged barrier hud BEGIN =====
GoalkeeperBarrier = GoalkeeperBarrier or {}
GoalkeeperBarrier.hud = GoalkeeperBarrier.hud or {}
GoalkeeperBarrier.hud.ENABLED = true                   -- false: no barrier segments
GoalkeeperBarrier.hud.CMD = @crc:CMND_GOALKEEPERBARRIER_GET@
-- Places each keeper bar in its locator's space (layout units, y up).
GoalkeeperBarrier.hud.BAR_LEFT = -182
GoalkeeperBarrier.hud.BAR_TOP = 12
GoalkeeperBarrier.hud.BAR_WIDTH = 364
GoalkeeperBarrier.hud.BAR_HEIGHT = 24
GoalkeeperBarrier.hud.LOCATOR_SPAN = 670           -- x distance from _pos_hp01 (-335) to _pos_hp02 (335), layout units
GoalkeeperBarrier.hud.SHARE = {25, 25}             -- per side: the barrier share of the bar in % (from the command)
GoalkeeperBarrier.hud.DEBUG = false
GoalkeeperBarrier.hud.BAR_RATE = @crc:CMND_GET_SOCCER_TEAM_INFO@        -- the retail keeper bar fill: (3 own / 4 rival) -> ok, rate 0..1
GoalkeeperBarrier.hud.RIVAL_DX = 0                 -- extra offset of the rival's segment (layout units)
GoalkeeperBarrier.hud.RIVAL_DY = 0
GoalkeeperBarrier.hud.PROBE_STEP = 100
GoalkeeperBarrier.hud.PROBE_WAIT = 2               -- frames between a probe change and its reading
GoalkeeperBarrier.hud.SETTLE = 1                   -- frames between a placement and its check
GoalkeeperBarrier.hud.SNAP = 2                     -- screen units: a segment this close to its target is shown
GoalkeeperBarrier.hud.FILL_FRAMES = 10             -- frames after a show in which the meshes are set up every frame
GoalkeeperBarrier.hud.FILL_EVERY = 30
GoalkeeperBarrier.hud.PROBE_TRIES = 6
GoalkeeperBarrier.hud.UNIT_TOLERANCE = 0.02        -- relative difference of the x and y units accepted as uniform
GoalkeeperBarrier.hud.LOGS = 0
GoalkeeperBarrier.hud.SHOWN = {false, false}
GoalkeeperBarrier.hud.LAST = {nil, nil}
GoalkeeperBarrier.hud.MAPPING = {nil, nil}         -- per instance: measured mapping, false = not measurable
GoalkeeperBarrier.hud.SPRITE = {nil, nil}
-- generated BEGIN
GoalkeeperBarrier.hud.STEPS = 29
GoalkeeperBarrier.hud.QUAD_X = {11, 263}
GoalkeeperBarrier.hud.QUAD_ROW = 8
GoalkeeperBarrier.hud.QUAD_W = 89
GoalkeeperBarrier.hud.QUAD_H = 7
GoalkeeperBarrier.hud.SPRITES = {
  [0] = {@crc:goalkeeper_barrier_own_01@, @crc:goalkeeper_barrier_own_02@, @crc:goalkeeper_barrier_own_03@, @crc:goalkeeper_barrier_own_04@, @crc:goalkeeper_barrier_own_05@, @crc:goalkeeper_barrier_own_06@, @crc:goalkeeper_barrier_own_07@, @crc:goalkeeper_barrier_own_08@, @crc:goalkeeper_barrier_own_09@, @crc:goalkeeper_barrier_own_10@, @crc:goalkeeper_barrier_own_11@, @crc:goalkeeper_barrier_own_12@, @crc:goalkeeper_barrier_own_13@, @crc:goalkeeper_barrier_own_14@, @crc:goalkeeper_barrier_own_15@, @crc:goalkeeper_barrier_own_16@, @crc:goalkeeper_barrier_own_17@, @crc:goalkeeper_barrier_own_18@, @crc:goalkeeper_barrier_own_19@, @crc:goalkeeper_barrier_own_20@, @crc:goalkeeper_barrier_own_21@, @crc:goalkeeper_barrier_own_22@, @crc:goalkeeper_barrier_own_23@, @crc:goalkeeper_barrier_own_24@, @crc:goalkeeper_barrier_own_25@, @crc:goalkeeper_barrier_own_26@, @crc:goalkeeper_barrier_own_27@, @crc:goalkeeper_barrier_own_28@, @crc:goalkeeper_barrier_own_29@},
  [1] = {@crc:goalkeeper_barrier_rival_01@, @crc:goalkeeper_barrier_rival_02@, @crc:goalkeeper_barrier_rival_03@, @crc:goalkeeper_barrier_rival_04@, @crc:goalkeeper_barrier_rival_05@, @crc:goalkeeper_barrier_rival_06@, @crc:goalkeeper_barrier_rival_07@, @crc:goalkeeper_barrier_rival_08@, @crc:goalkeeper_barrier_rival_09@, @crc:goalkeeper_barrier_rival_10@, @crc:goalkeeper_barrier_rival_11@, @crc:goalkeeper_barrier_rival_12@, @crc:goalkeeper_barrier_rival_13@, @crc:goalkeeper_barrier_rival_14@, @crc:goalkeeper_barrier_rival_15@, @crc:goalkeeper_barrier_rival_16@, @crc:goalkeeper_barrier_rival_17@, @crc:goalkeeper_barrier_rival_18@, @crc:goalkeeper_barrier_rival_19@, @crc:goalkeeper_barrier_rival_20@, @crc:goalkeeper_barrier_rival_21@, @crc:goalkeeper_barrier_rival_22@, @crc:goalkeeper_barrier_rival_23@, @crc:goalkeeper_barrier_rival_24@, @crc:goalkeeper_barrier_rival_25@, @crc:goalkeeper_barrier_rival_26@, @crc:goalkeeper_barrier_rival_27@, @crc:goalkeeper_barrier_rival_28@, @crc:goalkeeper_barrier_rival_29@},
}
-- generated END

local BARRIER_LAYER = 1188342059 --[[football_reforged_barrier]]
local BARRIER_KEEPER_BARS = 546630184 --[[soccer00_01_kp_scoreboard_kp]]
local BARRIER_MESH_FRAME = 1837325853 --[[_hp_base01]]
local BARRIER_MESH_FILL = 2043683848 --[[_hp_bar02]]
local BARRIER_MESH_LABEL = 1257514352 --[[_gtxt_stamina01]]
local BARRIER_MESH_TRAIL = 2609329121 --[[_hp_empty01]]
local BARRIER_ATLAS = 1653991639 --[[#/menu/02_btl/goalkeeper_barrier_hud/goalkeeper_barrier_hud.g4tx: the mod's own atlas]]
local BARRIER_TEXTURE_SLOT = 538967808 --[[hp_base01: the frame's texture slot]]
-- Measured placement.
local barrier_hud = {
  DRAW_NODE = 1837325853 --[[_hp_base01: the frame quad that draws the segment]],
  LOCATORS = {2302841237 --[[_pos_hp01]], 273399855 --[[_pos_hp02]]},
  GLOBAL_POS = @crc:CMND_GET_MESH_GLOBAL_POSITION@,
  SET_POS = @crc:CMND_SET_LAYER_LOCAL_POS@,
  SET_SCALE = @crc:CMND_SET_LAYER_LOCAL_SCALE@,
  probe = {nil, nil},
  place = {nil, nil},
  fill = {0, 0},
  fill_logged = {false, false},
  tries = {0, 0},         -- per instance: probes made
  state = {nil, nil},     -- per side: what it draws, logged on a change
}
-- The source gauge's frame quad _hp_base01.
local BARRIER_SOURCE_X, BARRIER_SOURCE_Y, BARRIER_SOURCE_W, BARRIER_SOURCE_H = 94, -816, 476, 44
local barrier_ready = {false, false, init = false}

local function FootballBarrier_Log(...)
  if GoalkeeperBarrier.hud.LOGS >= 40 or type(funcLuaCommand) ~= "function" then
    return
  end
  GoalkeeperBarrier.hud.LOGS = GoalkeeperBarrier.hud.LOGS + 1
  GoalkeeperBarrier.hud.logger = GoalkeeperBarrier.hud.logger or VRFW.logger.new("FR_BARRIER")
  GoalkeeperBarrier.hud.logger.debug(...)
end

-- Returns the barrier of side 1 (own) or 2 (rival).
function FootballBarrier_Value(side)
  if type(funcLuaCommand) ~= "function" then
    return nil
  end
  -- Reads the keeper bar as the scoreboard draws it (the retail UpdateScoreboardKeeperHp's own read).
  local bar_ok, has_bar, bar_rate = pcall(funcLuaCommand, GoalkeeperBarrier.hud.BAR_RATE, side == 1 and 3 or 4)
  if not bar_ok or not has_bar or type(bar_rate) ~= "number" then
    bar_rate = nil
  end
  local ok, has, percent, _, _, _, share, debug = pcall(funcLuaCommand, GoalkeeperBarrier.hud.CMD, side == 1 and -1 or -2, bar_rate)
  if not ok or has ~= true or type(percent) ~= "number" then
    return nil
  end
  if type(share) == "number" and share > 0 and share <= 100 then
    GoalkeeperBarrier.hud.SHARE[side] = share
  end
  GoalkeeperBarrier.hud.DEBUG = debug == 1
  if GoalkeeperBarrier.hud.DEBUG then
    return GoalkeeperBarrier.hud.SHARE[side]
  end
  return math.max(0, math.min(100, percent))
end

-- Returns the left edge of a segment (FOOTBALL_BARRIER_QUAD_*).
function FootballBarrier_SegmentLeft(i, width)
  return GoalkeeperBarrier.hud.BAR_LEFT + GoalkeeperBarrier.hud.QUAD_X[i + 1]
end

-- the top of the quad in its locator's space (layout units, y up)
function FootballBarrier_QuadTop()
  return GoalkeeperBarrier.hud.BAR_TOP - GoalkeeperBarrier.hud.QUAD_ROW
end

function FootballBarrier_LayerPos(i, width)
  local sx, sy = width / BARRIER_SOURCE_W, GoalkeeperBarrier.hud.QUAD_H / BARRIER_SOURCE_H
  local left = FootballBarrier_SegmentLeft(i, width)
  local dx, dy = 0, 0
  if i == 1 then
    dx, dy = GoalkeeperBarrier.hud.RIVAL_DX, GoalkeeperBarrier.hud.RIVAL_DY
  end
  return left - BARRIER_SOURCE_X * sx + dx, FootballBarrier_QuadTop() - BARRIER_SOURCE_Y * sy + dy, sx, sy
end

function FootballBarrier_Global(layer, index, node)
  local x, y = VRFW.host.menu_command(barrier_hud.GLOBAL_POS, layer, index, node)
  if type(x) ~= "number" or type(y) ~= "number" then
    return nil
  end
  return x, y
end

-- Measures the mapping at position 0 and scale 1, position step and scale 1, and position 0 and scale 2.
function FootballBarrier_Probe(i)
  if GoalkeeperBarrier.hud.MAPPING[i + 1] ~= nil then
    return true
  end
  local p = barrier_hud.probe[i + 1]
  if p == nil then
    barrier_hud.probe[i + 1] = {stage = 1, wait = GoalkeeperBarrier.hud.PROBE_WAIT}
    VRFW.host.menu_command(barrier_hud.SET_SCALE, BARRIER_LAYER, 1, 1, 1, i)
    VRFW.host.menu_command(barrier_hud.SET_POS, BARRIER_LAYER, 0, 0, 0, i)
    return false
  end
  if p.wait > 0 then
    p.wait = p.wait - 1
    return false
  end
  local x, y = FootballBarrier_Global(BARRIER_LAYER, i, barrier_hud.DRAW_NODE)
  if x == nil then
    GoalkeeperBarrier.hud.MAPPING[i + 1] = false
    FootballBarrier_Log("instance", i, "no global position for the frame node: static placement")
    return true
  end
  local step = GoalkeeperBarrier.hud.PROBE_STEP
  if p.stage == 1 then
    p.x1, p.y1, p.stage, p.wait = x, y, 2, GoalkeeperBarrier.hud.PROBE_WAIT
    VRFW.host.menu_command(barrier_hud.SET_POS, BARRIER_LAYER, step, step, 0, i)
    return false
  end
  if p.stage == 2 then
    p.x2, p.y2, p.stage, p.wait = x, y, 3, GoalkeeperBarrier.hud.PROBE_WAIT
    VRFW.host.menu_command(barrier_hud.SET_POS, BARRIER_LAYER, 0, 0, 0, i)
    VRFW.host.menu_command(barrier_hud.SET_SCALE, BARRIER_LAYER, 2, 2, 1, i)
    return false
  end
  local unit_x, unit_y = (p.x2 - p.x1) / step, (p.y2 - p.y1) / step
  if math.abs(unit_x) < 0.05 or math.abs(unit_y) < 0.05 then
    GoalkeeperBarrier.hud.MAPPING[i + 1] = false
    FootballBarrier_Log("instance", i, "position does not move the frame node", string.format("%.3f %.3f", unit_x, unit_y),
      "static placement")
    return true
  end
  -- The scoreboard's open animation still moving the node shows as x and y units that differ.
  barrier_hud.tries[i + 1] = barrier_hud.tries[i + 1] + 1
  if math.abs(unit_x - unit_y) > GoalkeeperBarrier.hud.UNIT_TOLERANCE * math.max(math.abs(unit_x), math.abs(unit_y))
      and barrier_hud.tries[i + 1] < GoalkeeperBarrier.hud.PROBE_TRIES then
    FootballBarrier_Log("instance", i, "probe", barrier_hud.tries[i + 1], "units differ",
      string.format("%.3f %.3f", unit_x, unit_y), "measuring again")
    barrier_hud.probe[i + 1] = nil
    return false
  end
  local node_x, node_y = x - p.x1, y - p.y1
  FootballBarrier_Log("instance", i, "frame node point", string.format("%.1f %.1f", node_x / unit_x, node_y / unit_y))
  GoalkeeperBarrier.hud.MAPPING[i + 1] = {unit_x = unit_x, unit_y = unit_y, node_x = node_x, node_y = node_y,
    origin_x = p.x1 - node_x, origin_y = p.y1 - node_y}
  GoalkeeperBarrier.hud.LAST[i + 1] = nil
  FootballBarrier_Log("instance", i, "mapping unit", string.format("%.3f %.3f", unit_x, unit_y), "origin",
    string.format("%.1f %.1f", p.x1 - node_x, p.y1 - node_y))
  return true
end

-- Computes the measured position from the locators.
function FootballBarrier_MeasuredPos(i, width, map)
  local own_x, own_y = FootballBarrier_Global(BARRIER_KEEPER_BARS, 0, barrier_hud.LOCATORS[1])
  local rival_x, rival_y = FootballBarrier_Global(BARRIER_KEEPER_BARS, 0, barrier_hud.LOCATORS[2])
  if own_x == nil or rival_x == nil then
    return nil
  end
  local board_x = (rival_x - own_x) / GoalkeeperBarrier.hud.LOCATOR_SPAN
  if math.abs(board_x) < 0.05 then
    return nil
  end
  local board_y = board_x * map.unit_y / map.unit_x
  local target_x, target_y
  local left = FootballBarrier_SegmentLeft(i, width)
  if i == 0 then
    target_x = own_x + left * board_x
    target_y = own_y + FootballBarrier_QuadTop() * board_y
  else
    target_x = rival_x + (left + GoalkeeperBarrier.hud.RIVAL_DX) * board_x
    target_y = rival_y + (FootballBarrier_QuadTop() + GoalkeeperBarrier.hud.RIVAL_DY) * board_y
  end
  local sx = width * board_x / (map.unit_x * BARRIER_SOURCE_W)
  local sy = GoalkeeperBarrier.hud.QUAD_H * board_y / (map.unit_y * BARRIER_SOURCE_H)
  local px = (target_x - map.origin_x) / map.unit_x - sx * BARRIER_SOURCE_X
  local py = (target_y - map.origin_y) / map.unit_y - sy * BARRIER_SOURCE_Y
  return px, py, sx, sy
end

function FootballBarrier_Place(i, width)
  local map = GoalkeeperBarrier.hud.MAPPING[i + 1]
  local place = barrier_hud.place[i + 1]
  if map and place and place.wait > 0 then
    place.wait = place.wait - 1
    return place.settled
  end
  -- a moved origin (the scoreboard sliding, a late attach) is corrected from the frame node's reading
  if map and place then
    local x, y = FootballBarrier_Global(BARRIER_LAYER, i, barrier_hud.DRAW_NODE)
    if x ~= nil then
      local origin_x = x - map.unit_x * place.px - place.sx * map.node_x
      local origin_y = y - map.unit_y * place.py - place.sy * map.node_y
      local error_x, error_y = origin_x - map.origin_x, origin_y - map.origin_y
      if math.abs(error_x) <= GoalkeeperBarrier.hud.SNAP and math.abs(error_y) <= GoalkeeperBarrier.hud.SNAP then
        place.settled = true
      end
      if math.abs(error_x) > 0.5 or math.abs(error_y) > 0.5 then
        map.origin_x, map.origin_y = origin_x, origin_y
      end
    end
  end
  local px, py, sx, sy
  if map then
    px, py, sx, sy = FootballBarrier_MeasuredPos(i, width, map)
  end
  local measured = px ~= nil
  if not measured then
    px, py, sx, sy = FootballBarrier_LayerPos(i, width)
  end
  if place == nil or math.abs(place.px - px) > 0.05 or math.abs(place.py - py) > 0.05 or math.abs(place.sx - sx) > 0.0005
      or math.abs(place.sy - sy) > 0.0005 then
    VRFW.host.menu_command(barrier_hud.SET_SCALE, BARRIER_LAYER, sx, sy, 1, i)
    VRFW.host.menu_command(barrier_hud.SET_POS, BARRIER_LAYER, px, py, 0, i)
    local settled = (place ~= nil and place.settled) or not measured
    place = {px = px, py = py, sx = sx, sy = sy, wait = GoalkeeperBarrier.hud.SETTLE, settled = settled}
    barrier_hud.place[i + 1] = place
    if GoalkeeperBarrier.hud.LAST[i + 1] == nil or math.abs(GoalkeeperBarrier.hud.LAST[i + 1] - width) > 0.5 then
      GoalkeeperBarrier.hud.LAST[i + 1] = width
      FootballBarrier_Log("instance", i, measured and "measured" or "static", "width", string.format("%.1f", width),
        "pos scale", string.format("%.1f %.1f / %.3f %.3f", px, py, sx, sy))
    end
  elseif not measured then
    place.settled = true
  end
  return place.settled
end

function FootballBarrier_Fill(i)
  VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_FILL, false, i)
  VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_LABEL, false, i)
  VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_TRAIL, false, i)
  VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_FRAME, true, i)
  if GoalkeeperBarrier.hud.SHOWN[i + 1] and not barrier_hud.fill_logged[i + 1] then
    barrier_hud.fill_logged[i + 1] = true
    FootballBarrier_Log("instance", i, "frame quad drawn after the show")
  end
end

-- Logs a change of the sprite.
local function FootballBarrier_Sprite(i, width)
  if GoalkeeperBarrier.hud.DEBUG then
    return true
  end
  local steps = GoalkeeperBarrier.hud.STEPS
  local full = GoalkeeperBarrier.hud.BAR_WIDTH * GoalkeeperBarrier.hud.SHARE[i + 1] / 100
  -- Picks the step at or below the barrier.
  local step = math.min(steps, math.floor(width / full * steps + 1e-6))
  if step < 1 then
    return false
  end
  local sprite = GoalkeeperBarrier.hud.SPRITES[i][step]
  if GoalkeeperBarrier.hud.SPRITE[i + 1] ~= sprite then
    GoalkeeperBarrier.hud.SPRITE[i + 1] = sprite
    VRFW.host.menu_command(558735651 --[[swap texture]], BARRIER_LAYER, BARRIER_ATLAS, sprite, BARRIER_TEXTURE_SLOT, 0, i)
  end
  return true
end

local function FootballBarrier_HideOne(i)
  if GoalkeeperBarrier.hud.SHOWN[i + 1] then
    GoalkeeperBarrier.hud.SHOWN[i + 1] = false
    VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, BARRIER_LAYER, i, false)
  end
end

function FootballBarrier_Step()
  if not GoalkeeperBarrier.hud.ENABLED or VRFW.host.menu_command(@crc:CMND_IS_OPEN_LAYER@, BARRIER_KEEPER_BARS, 0) ~= true then
    FootballBarrier_HideOne(0)
    FootballBarrier_HideOne(1)
    return
  end
  local widths = {}
  for side = 1, 2 do
    local percent = FootballBarrier_Value(side)
    -- one line per change of what a side draws (no answer / barrier 0 / a segment)
    local state = percent == nil and "no answer" or (percent * GoalkeeperBarrier.hud.BAR_WIDTH / 100 < 0.5 and "barrier 0: hidden" or "segment")
    if barrier_hud.state[side] ~= state then
      barrier_hud.state[side] = state
      FootballBarrier_Log("instance", side - 1, state, percent and string.format("%.1f %%", percent) or "")
    end
    if percent ~= nil then
      local width = GoalkeeperBarrier.hud.BAR_WIDTH * percent / 100
      if width >= 0.5 then
        widths[side] = width
      end
    end
  end
  if widths[1] == nil and widths[2] == nil then
    FootballBarrier_HideOne(0)
    FootballBarrier_HideOne(1)
    return
  end
  if VRFW.host.menu_command(@crc:CMND_IS_OPEN_LAYER@, BARRIER_LAYER) ~= true then
    barrier_ready = {false, false, init = false}
    barrier_hud.probe, barrier_hud.place, barrier_hud.tries = {nil, nil}, {nil, nil}, {0, 0}
    GoalkeeperBarrier.hud.MAPPING = {nil, nil}
    GoalkeeperBarrier.hud.SHOWN = {false, false}
    GoalkeeperBarrier.hud.SPRITE = {nil, nil}
    VRFW.host.menu_command(@crc:CMND_OPEN_LAYER_ARRAY@, BARRIER_LAYER)
    return
  end
  if VRFW.host.menu_command(@crc:CMND_IS_LOADING_LAYER@, BARRIER_LAYER) == true then
    return
  end
  -- Opens the layer with both instances visible as the retail gauge.
  if not barrier_ready.init then
    barrier_ready.init = true
    for i = 0, 1 do
      VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, BARRIER_LAYER, i, false)
      VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_FILL, false, i)
      VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_LABEL, false, i)
      VRFW.host.menu_command(@crc:CMND_SET_MESH_VISIBLE@, BARRIER_LAYER, BARRIER_MESH_TRAIL, false, i)
    end
    GoalkeeperBarrier.hud.SHOWN = {false, false}
    FootballBarrier_Log("layer open: instances hidden")
  end
  for i = 0, 1 do
    local width = widths[i + 1]
    if width == nil then
      FootballBarrier_HideOne(i)
    else
      if not barrier_ready[i + 1] then
        barrier_ready[i + 1] = true
        GoalkeeperBarrier.hud.LAST[i + 1] = nil
        GoalkeeperBarrier.hud.SHOWN[i + 1] = false
        VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, BARRIER_LAYER, i, false)    -- hidden until placed
        FootballBarrier_Fill(i)
        GoalkeeperBarrier.hud.SPRITE[i + 1] = nil
        if GoalkeeperBarrier.hud.DEBUG then
          FootballBarrier_Log("instance", i, "debug: the plain retail gauge over the barrier share")
        end
      end
      if not FootballBarrier_Sprite(i, width) then
        FootballBarrier_HideOne(i)
      elseif FootballBarrier_Probe(i) and FootballBarrier_Place(i, GoalkeeperBarrier.hud.QUAD_W) then
        if not GoalkeeperBarrier.hud.SHOWN[i + 1] then
          GoalkeeperBarrier.hud.SHOWN[i + 1] = true
          barrier_hud.fill[i + 1] = 0
          VRFW.host.menu_command(@crc:CMND_SET_LAYER_VISIBLE@, BARRIER_LAYER, i, true)
          local x, y = FootballBarrier_Global(BARRIER_LAYER, i, barrier_hud.DRAW_NODE)
          FootballBarrier_Log("shown", i, "frame node at", string.format("%.1f %.1f", x or 0, y or 0))
        end
        -- Showing an instance replays the gauge's open animation, which may show its other meshes again.
        local frames = barrier_hud.fill[i + 1]
        barrier_hud.fill[i + 1] = frames + 1
        if frames < GoalkeeperBarrier.hud.FILL_FRAMES or frames % GoalkeeperBarrier.hud.FILL_EVERY == 0 then
          FootballBarrier_Fill(i)
        end
      end
    end
  end
end

-- Runs every frame of the match HUD.
@HUD_FRAME@
VRFW.hud_frame.on(function() FootballBarrier_Step() end)
-- ===== EVT FootballReforged barrier hud END =====
