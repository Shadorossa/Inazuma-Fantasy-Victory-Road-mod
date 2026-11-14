-- Live match frame helpers: score, minute, ball in play, timers, change watchers. Call: in a handler (not while the script loads).
--- Library: live match state, score, minute and timers.

local Live = {}

local DEFAULTS = { live = { 9, 14, 15, 16 }, duel = { 14, 15 }, in_play = 9, goal = 13, restart = 10 }
local STATES_FILE = "content/defaults/match_states.toml"

local states = nil

local function set_of(list)
  local s = {}
  for _, v in ipairs(type(list) == "table" and list or {}) do
    local n = tonumber(v)
    if n then s[math.floor(n)] = true end
  end
  return s
end

local function load_states()
  local raw = {}
  local ok, files = pcall(VRFW.files.declarations, STATES_FILE)
  if ok and type(files) == "table" then
    for _, f in ipairs(files) do
      if type(f.data) == "table" then raw = f.data end
    end
  end
  local function one(k) return math.floor(tonumber(raw[k]) or DEFAULTS[k]) end
  return {
    live = set_of(type(raw.live) == "table" and raw.live or DEFAULTS.live),
    duel = set_of(type(raw.duel) == "table" and raw.duel or DEFAULTS.duel),
    in_play = one("in_play"),
    goal = one("goal"),
    restart = one("restart"),
  }
end

--- VRFW.match.live.states(): the match state sets (live, in play, duel) to test a frame with. Call: in a handler (not while the script loads).
function Live.states()
  if not states then states = load_states() end
  return states
end

--- Advanced: A state set from the array `list` (`default` when `list` is not a table).
function Live.state_set(list, default)
  if type(list) == "table" then return set_of(list) end
  return default or Live.states().live
end

local function state_of(m)
  return type(m) == "table" and tonumber(m.soccer_state) or nil
end

--- Internal: True when frame `m` is in a state of `set` (default: the live states).
function Live.is_live(m, set)
  local st = state_of(m)
  return st ~= nil and (set or Live.states().live)[st] == true
end

--- VRFW.match.live.in_play(m): whether the ball is in play in frame m. Call: in a handler (not while the script loads).
function Live.in_play(m)
  local st = state_of(m)
  return st ~= nil and st == Live.states().in_play
end

--- Internal: True when frame `m` is in a duel.
function Live.is_duel(m)
  local st = state_of(m)
  return st ~= nil and Live.states().duel[st] == true
end

--- Advanced: The seconds of frame `m` while it is live; 0 otherwise.
function Live.live_time_step(m, set)
  local dt = type(m) == "table" and tonumber(m.dt) or 0
  if dt > 0 and dt < 1 and Live.is_live(m, set) then return dt end
  return 0
end

--- VRFW.match.live.minute(m): the match minute of frame m, or nil. Call: in a handler (not while the script loads).
function Live.minute(m)
  local c = type(m) == "table" and tonumber(m.clock) or nil
  return c and math.floor(c / 60) or nil
end

--- VRFW.match.live.score(m): the goals of match frame m: own, rival (nil, nil when unknown). Call: in a handler (not while the script loads).
function Live.score(m)
  if type(m) ~= "table" or type(m.score) ~= "table" then return nil, nil end
  local us = m.user_team
  if us ~= 0 and us ~= 1 then return nil, nil end
  return tonumber(m.score[us + 1]), tonumber(m.score[2 - us])
end

local Timer = {}
Timer.__index = Timer

--- Adds `dt` seconds; answers how many periods ended.
function Timer:step(dt)
  if not (dt and dt > 0) or self.seconds <= 0 then return 0 end
  self.acc = self.acc + dt
  local n = 0
  while self.acc >= self.seconds do
    self.acc = self.acc - self.seconds
    n = n + 1
  end
  return n
end

--- Forgets the time gathered so far.
function Timer:reset()
  self.acc = 0
end

--- VRFW.match.live.timer(seconds): a countdown of match time. Call: in a handler (not while the script loads).
function Live.timer(seconds)
  return setmetatable({ seconds = tonumber(seconds) or 0, acc = 0 }, Timer)
end

local Watch = {}
Watch.__index = Watch

local FIELDS = { "half", "minute", "score_user", "score_rival", "state" }

--- the flags table is reused by the next step
function Watch:step(m)
  local now, last, changed = self.now, self.last, self.changed
  now.half = type(m) == "table" and m.half or nil
  now.minute = Live.minute(m)
  now.score_user, now.score_rival = Live.score(m)
  now.state = state_of(m)
  changed.any, changed.half, changed.minute, changed.score, changed.state = false, false, false, false, false
  for _, k in ipairs(FIELDS) do
    if last[k] ~= now[k] or not self.seen then
      last[k] = now[k]
      changed.any = true
      if k == "score_user" or k == "score_rival" then changed.score = true else changed[k] = true end
    end
  end
  self.seen = true
  return changed
end

--- Forgets the values seen so far.
function Watch:reset()
  self.last, self.seen = {}, false
end

--- VRFW.match.live.watch(): a watcher that tells what changed between two frames (goals, state). Call: in a handler (not while the script loads).
function Live.watch()
  return setmetatable({ last = {}, now = {}, changed = {}, seen = false }, Watch)
end

local listeners = nil   -- { kind = { fn, ... } }
local timers = nil      -- { { timer, fn, live }, ... }
local watcher = nil

local function on_tick(ev)
  local m = ev.match or {}
  if listeners then
    local changed = watcher:step(m)
    if changed.any then
      for kind, fns in pairs(listeners) do
        if changed[kind] then
          for _, fn in ipairs(fns) do fn(m, ev) end
        end
      end
    end
  end
  if timers then
    local dt = tonumber(m.dt) or 0
    for _, t in ipairs(timers) do
      local step = t.live and Live.live_time_step(m) or ((dt > 0 and dt < 1) and dt or 0)
      for _ = 1, t.timer:step(step) do t.fn(m, ev) end
    end
  end
  return nil
end

local function ensure_tick()
  if listeners or timers then return end
  VRFW.on("frame:tick", on_tick)
  VRFW.on("match:start", function()
    if watcher then watcher:reset() end
    for _, t in ipairs(timers or {}) do t.timer:reset() end
    return nil
  end)
end

local KINDS = { minute = true, score = true, half = true, state = true }

--- Internal: Calls `fn` when `kind` (minute, score, half, state) changes; false, why on another kind.
function Live.on(kind, fn)
  if not KINDS[kind] then return false, "kind must be minute, score, half or state" end
  ensure_tick()
  listeners = listeners or {}
  watcher = watcher or Live.watch()
  listeners[kind] = listeners[kind] or {}
  table.insert(listeners[kind], fn)
end

--- Internal: Calls `fn` every `seconds` seconds of live match time.
function Live.every(seconds, fn, opts)
  ensure_tick()
  timers = timers or {}
  table.insert(timers, { timer = Live.timer(seconds), fn = fn, live = not (opts and opts.live == false) })
end

return Live
