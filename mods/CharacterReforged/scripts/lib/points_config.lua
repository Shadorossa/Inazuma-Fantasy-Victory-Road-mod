-- The [points] settings of config.toml with their defaults.

local M = {}

local num = VRFW.value.number

local function pos_or(v, d)
  v = tonumber(v)
  if v ~= nil and v == v and v >= 0 and v < math.huge then return v end
  return d
end

local bool = VRFW.value.boolean

function M.points(t, parts)
  t = t or {}
  parts = parts or {}
  local c = {
    peg_on = bool(t.keshin_points, true) and parts.peg ~= false,
    sp_on = bool(t.totem_points, true) and parts.sp ~= false,
    move_tension_free = bool(t.move_tension_free, true),
    cost_model = string.lower(tostring(t.cost_model or "cs")),
    armour_boost = num(t.armour_boost, 1.05),
    armour_drain_per_s_if = num(t.armour_drain_per_s, 1.0),
    cs_armour_drain_k = pos_or(t.armour_drain_factor, 0.025),
    cs_armour_gk_zone_mult = pos_or(t.armour_goalkeeper_zone_multiplier, 0.5),
    default_atk = num(t.default_atk, 80),
    cs_armour_first_refill = num(t.armour_first_refill, 0.30),
    cs_armour_moves_free_on = bool(t.armour_moves_free, true),
    cs_keshin_moves_cost = string.lower(tostring(t.keshin_moves_cost or "own")),
    cs_armour_keshin_move = bool(t.armour_keshin_move, false),
  }
  c.cs_on = c.cost_model:match("^%s*cs%s*$") ~= nil
  local scale = pos_or(t.cost_scale == nil and 0.75 or t.cost_scale, 1.0)
  function c.peg() return c.peg_on end
  function c.sp() return c.sp_on end
  function c.any() return c.peg_on or c.sp_on end
  function c.cs() return c.cs_on end
  function c.cs_scale() return scale end
  function c.armour_moves_free() return c.cs() and c.cs_armour_moves_free_on end
  function c.armour_blocks_keshin_move() return c.cs() and not c.cs_armour_keshin_move end
  function c.keshin_moves_all_peg() return c.cs() and c.peg() and c.cs_keshin_moves_cost:match("^%s*peg%s*$") ~= nil end
  function c.armour_drain_per_s(kp, atk, keeper_home)
    if not c.cs() then return math.max(c.armour_drain_per_s_if, 0) end
    local base = (math.max(kp, 0) + math.max(atk, 0)) * c.cs_armour_drain_k * c.cs_scale()
    if keeper_home then return base * c.cs_armour_gk_zone_mult end
    return base
  end
  return c
end

function M.option_on(id)
  local ok, v = pcall(VRFW.option, id)
  if not ok or v == nil then return true end
  return v ~= 0 and v ~= false
end

return M
