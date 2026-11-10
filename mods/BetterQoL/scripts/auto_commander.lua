local Memory = VRFW.memory
local OPTION = "auto_commander"
local HOOK_GATE = "BetterQoL.CoachModeGate"
local T_GATE = "BetterQoL.AutoCommander"
local T_WHY = "BetterQoL.AutoCommanderWhy"
local FORCED_FLAG = 0x200000
local MI_GAME = 0x4               -- match info: the match row's id (soccer_game_config key hash)
local MI_DIFF = 0x15              -- match info: the difficulty
local MODE_COMMANDER = 1
local HOOK_COACH_AI = "BetterQoL.CoachAISet"
local COACH_AI_TEAM = 0x0          -- coach AI object (TeamAI + 0x12440) +0: its team
local MI_USER_TEAM = 0x2C29        -- match info: the user's team
local mirrored = false             -- the rival's profiles are on the user's team this match
local SET_FLAGS = 2
local CLEAR_FLAGS = 0xC00

local cfg = VRFW.config("auto_commander", {})

local SPEED_OPTION = "auto_commander_speed"
local SPEED_BUFFER = "BetterQoL.CommanderSpeed"
local PATCH_SPEED_GATE = "BetterQoL.CommanderSpeedGate"
local PATCH_SPEED_FACTOR = "BetterQoL.CommanderSpeedFactor"
local GAME_RULE = 0                -- the buffer's 0: the game's own Commander speed rule
local SPEED_MIN = tonumber(cfg.speed_min) or 1.0
local SPEED_MAX = tonumber(cfg.speed_max) or 4.0
local speed_cell = nil             -- the factor's address once both patches are written
local speed_failed = false         -- a patch failed this session: the game's code stays
local speed_shown = nil

local function speed_patches()
  if speed_cell ~= nil then
    return true
  end
  if speed_failed then
    return false
  end
  speed_failed = true
  local cell = VRFW.memory.buffer(SPEED_BUFFER, 4)
  local ok_buffer = cell ~= nil
  if not ok_buffer or cell == nil then
    VRFW.warn("auto commander: no speed buffer: the game's Commander speed")
    return false
  end
  VRFW.memory.write("f32", cell, GAME_RULE)
  local address = math.tointeger and math.tointeger(cell) or cell
  local ok_gate, gate_written = pcall(VRFW.patch.apply, PATCH_SPEED_GATE, { imm = { { at = 2, width = "u64", value = address } } })
  if not (ok_gate and gate_written) then
    VRFW.warn("auto commander: speed gate not written (" .. tostring(gate_written) .. "): the game's Commander speed")
    return false
  end
  local ok_factor, factor_written = pcall(VRFW.patch.apply, PATCH_SPEED_FACTOR)
  if not (ok_factor and factor_written) then
    -- the gate alone keeps the game's x2 (its multiply still reads the game's constant)
    VRFW.warn("auto commander: speed factor not written (" .. tostring(factor_written) .. "): the game's Commander speed")
    return false
  end
  speed_failed = false
  speed_cell = cell
  return true
end

-- the row's factor, clamped (x1 = normal speed)
local function chosen_speed()
  local v = tonumber(VRFW.option(SPEED_OPTION)) or 1.0
  if v < SPEED_MIN then
    v = SPEED_MIN
  elseif v > SPEED_MAX then
    v = SPEED_MAX
  end
  return v
end

local function set_speed(factor)
  if factor == nil and speed_cell == nil then
    return
  end
  if not speed_patches() then
    return
  end
  VRFW.memory.write("f32", speed_cell, factor or GAME_RULE)
  if speed_shown ~= factor then
    speed_shown = factor
    VRFW.log("auto commander: Commander speed " .. (factor and ("x" .. tostring(factor)) or "the game's rule"))
  end
end

local function list(v, default)
  return type(v) == "table" and v or default
end

-- match rows (game keys or numbers) whose matches always start in Commander mode, gate open
local ALWAYS = {}
for _, g in ipairs(list(cfg.always_games, { "fbtl_bb_stadium_00" })) do
  local id = type(g) == "number" and g or (type(g) == "string" and VRFW.crc32(g)) or nil
  if id then
    ALWAYS[bit32.band(id, 0xFFFFFFFF)] = true
  else
    VRFW.warn("config.toml [auto_commander] always_games: " .. tostring(g) .. " is no game key: ignored")
  end
end

-- game modes (current-mode keys) where the beaten-only rule never applies
local NEVER_MODES = list(cfg.never_modes, { "story" })

local BEATEN = nil
local function beaten_set()
  if BEATEN then
    return BEATEN
  end
  local ctxs, names = {}, {}
  for _, c in ipairs(list(cfg.beaten_only_contexts, { "free_match" })) do
    ctxs[c] = true
  end
  for _, n in ipairs(list(cfg.beaten_only_difficulties, { "Heroica", "HeroicaPlus" })) do
    names[n] = true
  end
  local merged = {}
  local ok, files = pcall(VRFW.files.declarations, { "defaults/match_difficulty.toml", "content/defaults/match_difficulty.toml" })
  for _, f in ipairs(ok and files or {}) do
    local md = type(f.data) == "table" and f.data.MatchDifficulty or nil
    if type(md) == "table" then
      for name, row in pairs(md) do
        if type(row) == "table" then
          local m = merged[name] or {}
          for k, v in pairs(row) do
            m[k] = v
          end
          merged[name] = m
        end
      end
    end
  end
  local set, shown = {}, {}
  for name, row in pairs(merged) do
    local d = tonumber(row.Difficulty)
    local hit = names[name] == true
    for _, c in ipairs(type(row.Contexts) == "table" and row.Contexts or {}) do
      hit = hit or ctxs[c] == true
    end
    if d and hit then
      set[d] = true
      shown[#shown + 1] = name .. "=" .. d
    end
  end
  table.sort(shown)
  if #shown == 0 then
    VRFW.warn("auto commander: no match difficulty found for the beaten-only rule (defaults\\match_difficulty.toml)")
  else
    VRFW.log("auto commander: beaten-only difficulties " .. table.concat(shown, ", "))
  end
  BEATEN = set
  return set
end

local function option_on()
  return (tonumber(VRFW.option(OPTION)) or 0) ~= 0
end

-- a field of the running match's info (nil = unknown)
local function match_field(width, offset)
  local mi = VRFW.game.betterqol_match_info()
  if mi == nil then
    return nil
  end
  return Memory.read(width, mi + offset)
end

local function match_info()
  local flags, game, diff = match_field("u32", 0), match_field("u32", MI_GAME), match_field("u8", MI_DIFF)
  if flags == nil or game == nil or diff == nil then
    return nil
  end
  return { flags = flags, game = game, diff = diff }
end

local function gate(open)
  if open then
    VRFW.native.table_set(T_WHY, 0, 1)
    VRFW.native.table_set(T_GATE, 0, 0)
  else
    VRFW.native.table_clear(T_WHY)
    VRFW.native.table_clear(T_GATE)
  end
end

local function game_allows()
  if not VRFW.is_on(HOOK_GATE) then
    return false
  end
  local ok, blocked = pcall(VRFW.hook.original, HOOK_GATE, 0)
  return ok and (blocked == false or blocked == 0)
end

local function in_mode(keys)
  for _, k in ipairs(keys) do
    if VRFW.mode_is(k) then
      return true
    end
  end
  return false
end

-- "always" / "beaten" / nil (the game's rules), and why
local function classify(m)
  if ALWAYS[m.game] then
    return "always", "Battle Bay row"
  end
  if not beaten_set()[m.diff] then
    return nil, "difficulty " .. tostring(m.diff) .. " not under the rule"
  end
  if in_mode(NEVER_MODES) then
    return nil, "mode " .. tostring(VRFW.mode())
  end
  if game_allows() then
    return "beaten", "difficulty " .. m.diff .. ", rival beaten"
  end
  return nil, "difficulty " .. m.diff .. ", rival not beaten: Manual"
end

local function on_init(ev)
  gate(false)
  mirrored = false
  set_speed(nil)
  if not option_on() then
    return nil
  end
  local m = match_info()
  if m == nil then
    VRFW.log("auto commander: " .. ev.hook .. ": no match info: the game's rules")
    return nil
  end
  local kind, why = classify(m)
  if kind == nil then
    VRFW.log(string.format("auto commander: %s: game 0x%08X: %s: the game's rules", ev.hook, m.game, why))
    return nil
  end
  set_speed(chosen_speed())
  local forced = bit32.band(m.flags, FORCED_FLAG) ~= 0
  if kind == "always" and not forced then
    gate(true)
  end
  local mode, req = ev.args[1], ev.args[2]
  if mode ~= 0 or req == nil or req == 0 then
    VRFW.log(string.format("auto commander: %s asks mode %s: left as it is", ev.hook, tostring(mode)))
    return nil
  end
  local ok = VRFW.memory.write("u32", req, SET_FLAGS) and VRFW.memory.write("u32", req + 4, CLEAR_FLAGS)
  if not ok then
    VRFW.warn("auto commander: the request's flags could not be written: Commander mode without them")
  end
  VRFW.log(string.format("auto commander: %s: game 0x%08X (%s): match starts in Commander mode (gate open: %s)",
    ev.hook, m.game, why, tostring(kind == "always" and not forced)))
  return { args = { [1] = MODE_COMMANDER } }
end

VRFW.on("hook:BetterQoL.CoachModeInit", on_init)
VRFW.on("hook:BetterQoL.CoachModeInit2", on_init)

local function on_coach_ai(ev)
  local obj, on = ev.args[1], ev.args[2]
  local team = Memory.read("u8", obj + COACH_AI_TEAM)
  if team == nil or team ~= match_field("u8", MI_USER_TEAM) then
    return nil
  end
  if on ~= 0 then
    if not option_on() then
      return nil
    end
    local names, why = VRFW.ai.mirror_profiles("user", "rival")
    mirrored = names ~= nil
    if names then
      VRFW.log("auto commander: Commander mode: your team plays the rival's AI [" .. names .. "]")
    else
      VRFW.log("auto commander: Commander mode: the game's Commander AI (" .. tostring(why) .. ")")
    end
  elseif mirrored then
    mirrored = false
    VRFW.ai.reset_profiles("user")
    VRFW.log("auto commander: Commander mode off: your team's AI back to the game's")
  end
  return nil
end

VRFW.on("hook:" .. HOOK_COACH_AI, on_coach_ai)
