
Pressing = Pressing or {}
local P = Pressing
local info = VRFW.logger("pressing")
local function press_debug(line) VRFW.debug("pressing: " .. line) end

local clamp = VRFW.value.clamp   -- a config number with a default, kept inside its range

local function text_setting(t, k, default)
  local v = t and t[k]
  if type(v) == "string" and v ~= "" then return v end
  return default
end

local function list_setting(t, k, default)
  local v = t and t[k]
  if type(v) ~= "table" then return default end
  local out = {}
  for _, x in ipairs(v) do
    if type(x) == "string" and x ~= "" then out[#out + 1] = x end
  end
  if #out == 0 then return default end
  return out
end

local RAW = VRFW.config("pressing", {})
local SETTINGS = {
  min_players = math.floor(clamp(RAW.min_players, 2, 1, 10)),
  max_players = math.floor(clamp(RAW.max_players, 4, 1, 10)),
  band_m = clamp(RAW.band_m, 14, 0, 200),
  range_m = clamp(RAW.range_m, 32, 1, 200),
  sprint = RAW.sprint ~= false,
  sprint_speed = clamp(RAW.sprint_speed, 0.9, 0.1, 3),
  sprint_drain = clamp(RAW.sprint_drain, 0.9, 0, 5),
  order_ms = math.floor(clamp(RAW.order_ms, 300, 50, 5000)),
  chase = RAW.chase ~= false,
  sprint_resource = text_setting(RAW, "sprint_resource", "VRFW.sprint"),
  winded_state = text_setting(RAW, "winded_state", "winded"),
  min_sprint = clamp(RAW.min_sprint, 0, 0, 1),
  focus_field_gate = text_setting(RAW, "focus_field_gate", "off_ball"),
  hold_commands = list_setting(RAW, "hold_commands", { "CMD_GO_AHEAD_HOLD", "CMD_GO_AHEAD", "CMD_CATCH_BOMB" }),
  cpu = RAW.cpu ~= false,
  decide_ms = math.floor(clamp(RAW.decide_ms, 500, 50, 10000)),
  press_ms = math.floor(clamp(RAW.press_ms, 2500, 100, 30000)),
  rest_ms = math.floor(clamp(RAW.rest_ms, 1500, 0, 60000)),
  hud_sprite = text_setting(RAW, "hud_sprite", ""),
  arrows = text_setting(RAW, "arrows", "user"),
  cpu_rules = {},
}
-- the AI's own press, per defender ([pressing.ai])
local RAW_AI = type(RAW.ai) == "table" and RAW.ai or {}
SETTINGS.ai = {
  enabled = RAW_AI.enabled ~= false,
  radius_m = clamp(RAW_AI.radius_m, 10, 0, 100),
  ranks = math.floor(clamp(RAW_AI.ranks, 2, 1, 10)),
  chance = clamp(RAW_AI.chance, 0.3, 0, 1),
  cooldown_ms = math.floor(clamp(RAW_AI.cooldown_ms, 6000, 0, 120000)),
  press_ms = math.floor(clamp(RAW_AI.press_ms, 2000, 100, 5000)),
  decide_ms = math.floor(clamp(RAW_AI.decide_ms, 600, 100, 10000)),
}
if SETTINGS.max_players < SETTINGS.min_players then SETTINGS.max_players = SETTINGS.min_players end
if SETTINGS.arrows ~= "both" and SETTINGS.arrows ~= "off" then SETTINGS.arrows = "user" end
if SETTINGS.focus_field_gate ~= "off_ball" and SETTINGS.focus_field_gate ~= "always" then SETTINGS.focus_field_gate = "off" end
if type(RAW.cpu_rule) == "table" then
  for _, r in ipairs(RAW.cpu_rule) do
    if type(r) == "table" then
      SETTINGS.cpu_rules[#SETTINGS.cpu_rules + 1] = {
        carrier_to_own_goal_max_m = tonumber(r.carrier_to_own_goal_max_m),
        carrier_in_own_half = r.carrier_in_own_half == true,
        nearest_within_m = tonumber(r.nearest_within_m),
        ready_within_m = tonumber(r.ready_within_m),
        ready_count = math.floor(clamp(r.ready_count, 1, 1, 10)),
        chance = clamp(r.chance, 1, 0, 1),
      }
    end
  end
end
P.settings = SETTINGS

-- the soccer states (the press runs only in plain open play)
local Live = VRFW.match.live

local State = {
  team = {
    [0] = { pressers = {}, count = 0, cpu_until = 0, cpu_rest = 0, cpu_next = 0, ai = {}, ai_next = 0 },
    [1] = { pressers = {}, count = 0, cpu_until = 0, cpu_rest = 0, cpu_next = 0, ai = {}, ai_next = 0 },
  },
  gate_set = false,
  carrier = nil,
  ready_at = {},
  owner = nil,
  last_owner = nil,
  hud = false,
}

local hex = VRFW.ids.hex_text

local function order(ms)
  return { sprint = SETTINGS.sprint, sprint_speed = SETTINGS.sprint_speed, sprint_drain = SETTINGS.sprint_drain, ms = ms }
end

local function chance_roll() return VRFW.random.float() end

local function dist(ax, az, bx, bz)
  local dx, dz = ax - bx, az - bz
  return math.sqrt(dx * dx + dz * dz)
end

local function winded(hdl)
  local key = SETTINGS.sprint_resource
  if not key or not VRFW.resource then return false end
  local ok, v = pcall(VRFW.resource.get, key, hdl)
  if not ok or type(v) ~= "table" then return false end
  local okw, w = pcall(VRFW.resource.state, key, hdl, SETTINGS.winded_state)
  if okw and w == true then return true end
  return SETTINGS.min_sprint > 0 and (tonumber(v.ratio) or 1) < SETTINGS.min_sprint
end

local function candidates(team, cx, cz)
  local ok, players = pcall(VRFW.ai.players, team)
  if not ok or type(players) ~= "table" then return {} end
  local list = {}
  for _, p in ipairs(players) do
    if not p.keeper and not p.controlled and not p.ball then
      local d = dist(p.x, p.z, cx, cz)
      if d <= SETTINGS.range_m and not winded(p.handle) then list[#list + 1] = { hdl = p.handle, d = d } end
    end
  end
  table.sort(list, function(a, b) return a.d < b.d end)
  return list
end

local function pick(list)
  local out = {}
  for _, c in ipairs(list) do
    if #out >= SETTINGS.max_players then break end
    if c.d <= SETTINGS.band_m or #out < SETTINGS.min_players then out[#out + 1] = c end
  end
  return out
end

local function arrows_for(team, user)
  return SETTINGS.arrows == "both" or (SETTINGS.arrows == "user" and team == user)
end

local function arrows_off(hdl, mark)
  if mark ~= true then pcall(VRFW.ai.hide_arrow, hdl) end
end

local function set_hud(on)
  if SETTINGS.hud_sprite == "" or on == State.hud or not VRFW.hud then return end
  local ok = pcall(VRFW.hud.go_ahead_guide, on and SETTINGS.hud_sprite or nil)
  if ok then
    State.hud = on
    press_debug(on and "the L2 guide shows the press" or "the L2 guide is the game's")
  end
end

local function stop(team, why)
  local t = State.team[team]
  t.empty, t.refused = nil, nil
  if t.count == 0 then return end
  for hdl, mark in pairs(t.pressers) do
    pcall(VRFW.ai.release, hdl)
    arrows_off(hdl, mark)
  end
  t.pressers, t.count = {}, 0
  press_debug(string.format("T%d stops pressing (%s)", team, why))
end

local function press(team, carrier, cx, cz, who, user)
  local t = State.team[team]
  local chosen = pick(candidates(team, cx, cz))
  local now_set, n, names = {}, 0, {}
  local target = SETTINGS.chase and { chase = carrier } or { x = cx, z = cz }
  local arrows = arrows_for(team, user)
  local refused = nil
  for _, c in ipairs(chosen) do
    local ok, done, why = pcall(VRFW.ai.move, c.hdl, target, order(SETTINGS.order_ms))
    if not (ok and done) then
      refused = refused or string.format("%s: %s", hex(c.hdl), tostring(ok and why or done))
    end
    if ok and done then
      -- his arrows when he starts pressing, and a new target for them when the carrier changes
      local mark = t.pressers[c.hdl]
      if arrows and mark ~= nil and mark ~= true and mark ~= carrier then
        pcall(VRFW.ai.arrow, c.hdl, { chase = carrier })
        mark = carrier
      elseif arrows and mark == nil then
        local oka, shown, why_not = pcall(VRFW.ai.arrow, c.hdl, { chase = carrier })
        mark = (oka and shown) and carrier or true
        if mark == true then
          press_debug(string.format("T%d: no arrows on %s (%s)", team, hex(c.hdl), tostring(oka and why_not or shown)))
        end
      elseif mark == nil then
        mark = true
      end
      now_set[c.hdl] = mark
      n = n + 1
      names[#names + 1] = string.format("%s (%.1f m)", hex(c.hdl), c.d)
    end
  end
  local changed = n ~= t.count
  for hdl, mark in pairs(t.pressers) do
    if not now_set[hdl] then
      pcall(VRFW.ai.release, hdl)
      arrows_off(hdl, mark)
      changed = true
    end
  end
  for hdl in pairs(now_set) do
    if not t.pressers[hdl] then changed = true end
  end
  t.pressers, t.count = now_set, n
  -- a refused move order and an empty press are logged when they start (no per-frame line)
  if refused ~= t.refused then
    t.refused = refused
    if refused then info(string.format("T%d: a press order was refused (%s)", team, refused)) end
  end
  local empty = n == 0
  if empty ~= t.empty then
    t.empty = empty
    changed = changed or empty
  end
  if changed then
    if n > 0 then
      press_debug(string.format("T%d presses the carrier %s (%s): %s", team, hex(carrier), who, table.concat(names, ", ")))
    else
      press_debug(string.format("T%d: nobody can press the carrier %s (%s: none in range / all winded)", team, hex(carrier), who))
    end
  end
end

local function ai_stop(team, why)
  local t = State.team[team]
  local n = 0
  for hdl in pairs(t.ai) do
    pcall(VRFW.ai.release, hdl)
    n = n + 1
  end
  if n > 0 then
    t.ai = {}
    press_debug(string.format("T%d: %d AI press(es) end (%s)", team, n, why))
  end
end

local function ai_decide(team, carrier, cx, cz, now, force)
  local A = SETTINGS.ai
  local t = State.team[team]
  if not force and now < t.ai_next then return end
  t.ai_next = now + A.decide_ms
  local list = candidates(team, cx, cz)
  local eligible = {}
  for _, c in ipairs(list) do eligible[c.hdl] = true end
  for hdl, o in pairs(t.ai) do
    local why = nil
    if now >= o.ends then
      why = "time over"
    elseif not eligible[hdl] then
      why = "winded, out of range or no longer the AI's"
    end
    if why then
      pcall(VRFW.ai.release, hdl)
      t.ai[hdl] = nil
      press_debug(string.format("T%d: AI press of %s ends (%s)", team, hex(hdl), why))
    elseif o.carrier ~= carrier then
      local ok, done = pcall(VRFW.ai.move, hdl, SETTINGS.chase and { chase = carrier } or { x = cx, z = cz },
        order(math.max(math.floor(o.ends - now), 50)))
      if ok and done then o.carrier = carrier else t.ai[hdl] = nil end
    end
  end
  for rank = 1, math.min(A.ranks, #list) do
    local c = list[rank]
    if c.d > A.radius_m then break end
    if not t.ai[c.hdl] and now >= (State.ready_at[c.hdl] or 0) and chance_roll() < A.chance then
      local ok, done, why = pcall(VRFW.ai.move, c.hdl, SETTINGS.chase and { chase = carrier } or { x = cx, z = cz },
        order(A.press_ms))
      if ok and done then
        t.ai[c.hdl] = { ends = now + A.press_ms, carrier = carrier }
        State.ready_at[c.hdl] = now + A.press_ms + A.cooldown_ms
        press_debug(string.format("T%d: AI press: %s (rank %d, %.1f m) on the carrier %s, %d ms", team, hex(c.hdl), rank, c.d,
          hex(carrier), A.press_ms))
      elseif not t.ai_refused then
        t.ai_refused = true
        info(string.format("T%d: an AI press order was refused (%s: %s)", team, hex(c.hdl), tostring(ok and why or done)))
      end
    end
  end
end

local function user_holds()
  if not VRFW.ai.input or not VRFW.ai.input.on then return false end
  for _, c in ipairs(SETTINGS.hold_commands) do
    local ok, on = pcall(VRFW.ai.input.on, c)
    if ok and on == true then return true end
  end
  return false
end

local function rule_holds(r, team, cx, cz, list)
  if r.carrier_to_own_goal_max_m or r.carrier_in_own_half then
    local ok, gx, gz = pcall(VRFW.ai.own_goal, team)
    if not ok or not gx then return false end
    local own = dist(cx, cz, gx, gz)
    if r.carrier_to_own_goal_max_m and own > r.carrier_to_own_goal_max_m then return false end
    if r.carrier_in_own_half then
      local ok2, ox, oz = pcall(VRFW.ai.own_goal, 1 - team)
      if not ok2 or not ox or own >= dist(cx, cz, ox, oz) then return false end
    end
  end
  if r.nearest_within_m and not (list[1] and list[1].d <= r.nearest_within_m) then return false end
  if r.ready_within_m then
    local n = 0
    for _, c in ipairs(list) do
      if c.d <= r.ready_within_m then n = n + 1 end
    end
    if n < r.ready_count then return false end
  end
  return chance_roll() < r.chance
end

local function cpu_wants(team, cx, cz, now)
  local t = State.team[team]
  if now < t.cpu_until then return true end
  if t.cpu_until ~= 0 then
    t.cpu_until = 0
    stop(team, "the CPU's press time is over")
  end
  if now < t.cpu_rest or now < t.cpu_next then return false end
  t.cpu_next = now + SETTINGS.decide_ms
  local list = candidates(team, cx, cz)
  if #list == 0 then return false end
  for i, r in ipairs(SETTINGS.cpu_rules) do
    if rule_holds(r, team, cx, cz, list) then
      t.cpu_until = now + SETTINGS.press_ms
      t.cpu_rest = t.cpu_until + SETTINGS.rest_ms
      press_debug(string.format("T%d (CPU) starts a press: rule %d, %d ms", team, i, SETTINGS.press_ms))
      return true
    end
  end
  return false
end

local function note_button(on, context)
  if on == State.user_held then return end
  State.user_held = on
  press_debug(string.format("your press button %s (%s)", on and "on" or "off", context))
end

local function stop_all(why)
  stop(0, why)
  stop(1, why)
  ai_stop(0, why)
  ai_stop(1, why)
end

local function set_gate()
  if State.gate_set or SETTINGS.focus_field_gate == "off" then return end
  State.gate_set = true
  for team = 0, 1 do
    local ok, done, why = pcall(VRFW.ai.focus_field_gate, team, SETTINGS.focus_field_gate)
    if not (ok and done) and not State.gate_warned then
      State.gate_warned = true
      info("focus field gate not set: " .. tostring(ok and why or done))
    end
  end
end

VRFW.on("match:start", function() State.gate_set, State.ready_at, State.carrier = false, {}, nil return nil end)
VRFW.on("match:end", function() State.gate_set, State.ready_at, State.carrier = false, {}, nil return nil end)

VRFW.on("frame:tick", function(ev)
  local m = ev.match or VRFW.match()
  local now = VRFW.now_ms()
  set_gate()
  if not m or not Live.in_play(m) then
    stop_all("play stopped")
    State.owner, State.last_owner, State.carrier = nil, nil, nil
    set_hud(false)
    return nil
  end
  local user = m.user_team
  local ok, carrier, cteam, cx, cz = pcall(VRFW.ai.ball)
  if not ok or not carrier or (cteam ~= 0 and cteam ~= 1) then
    if user == 0 or user == 1 then note_button(user_holds(), "loose ball") end
    stop_all("loose ball")
    State.owner, State.carrier = nil, nil
    return nil
  end
  if State.owner ~= cteam then
    State.owner, State.last_owner = cteam, cteam
    set_hud((user == 0 or user == 1) and cteam ~= user)
    for team = 0, 1 do
      local t = State.team[team]
      t.cpu_until, t.cpu_next = 0, 0
    end
  end
  stop(cteam, "his team has the ball")
  ai_stop(cteam, "his team has the ball")
  local team = 1 - cteam
  local new_carrier = State.carrier ~= carrier
  State.carrier = carrier
  local want, who
  local human = VRFW.ai.human(team)
  if user == team then
    want, who = user_holds(), "your press button"
    note_button(want, "the rival's carrier " .. hex(carrier))
  elseif human then
    want, who = false, "a human"
  else
    want, who = SETTINGS.cpu and cpu_wants(team, cx, cz, now), "CPU"
  end
  if want then
    ai_stop(team, "a team press")
    press(team, carrier, cx, cz, who, user)
  else
    stop(team, user == team and "press button released" or (human and "a human drives the team" or "the CPU does not press"))
    if SETTINGS.ai.enabled then ai_decide(team, carrier, cx, cz, now, new_carrier) end
  end
  return nil
end)

info(string.format("active: %d-%d pressers within %.0f m (range %.0f m), sprint %s, focus field %s, your button %s, CPU %s (%d rules)",
  SETTINGS.min_players, SETTINGS.max_players, SETTINGS.band_m, SETTINGS.range_m,
  string.format("%s (speed x%.2f, drain x%.2f)", tostring(SETTINGS.sprint), SETTINGS.sprint_speed, SETTINGS.sprint_drain),
  SETTINGS.focus_field_gate, table.concat(SETTINGS.hold_commands, " / "), tostring(SETTINGS.cpu), #SETTINGS.cpu_rules))
info(string.format("AI press: %s, the nearest %d within %.0f m, chance %.2f every %d ms, %d ms then %d ms cooldown",
  SETTINGS.ai.enabled and "on" or "off", SETTINGS.ai.ranks, SETTINGS.ai.radius_m, SETTINGS.ai.chance,
  SETTINGS.ai.decide_ms, SETTINGS.ai.press_ms, SETTINGS.ai.cooldown_ms))
info(string.format("HUD: L2 press guide %s, arrows %s", SETTINGS.hud_sprite ~= "" and SETTINGS.hud_sprite or "off",
  SETTINGS.arrows))
