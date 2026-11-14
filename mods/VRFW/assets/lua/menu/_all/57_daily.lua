-- lua_patch.scope: used
-- menu_engine: daily renewal (VRFW base service `VRFW.Daily`).
if VRFW.daily == nil then
  local D = {
    CMD = {
      PERIOD = VRFW.commands.VRFW_DAILY_PERIOD,    -- CMND_VRFW_DAILY_PERIOD (kind [, id]) -> id, secs, label
      SEED = VRFW.commands.VRFW_DAILY_SEED,
      INT = VRFW.commands.VRFW_DAILY_INT,
      PICK = VRFW.commands.VRFW_DAILY_PICK,
      SAMPLE = VRFW.commands.VRFW_DAILY_SAMPLE,    -- CMND_VRFW_DAILY_SAMPLE (..., keys, k) -> "i,j,...", cursor
      SHUFFLE = VRFW.commands.VRFW_DAILY_SHUFFLE,   -- CMND_VRFW_DAILY_SHUFFLE (..., keys) -> "i,j,...", cursor
      WEIGHTED = VRFW.commands.VRFW_DAILY_WEIGHTED,
      SEEN = VRFW.commands.VRFW_DAILY_SEEN,       -- CMND_VRFW_DAILY_SEEN (key, kind) -> isNew, previous, current
      MARK_DONE = VRFW.commands.VRFW_DAILY_MARK_DONE,
      IS_DONE = VRFW.commands.VRFW_DAILY_IS_DONE,    -- CMND_VRFW_DAILY_IS_DONE (key, kind) -> done
      STREAK = VRFW.commands.VRFW_DAILY_STREAK,    -- CMND_VRFW_DAILY_STREAK (key, kind) -> streak, best, total
      STATUS = VRFW.commands.VRFW_DAILY_STATUS,
    },
    KINDS = { day = true, week = true, month = true },
    handlers = {},            -- handlers[kind] = { { id, fn }, ... }
    last = {},                -- last[kind] = id seen by the last Poll of this VM
    watched = {},
    frames = 0,
  }
  --- Internal: Namespace of the daily rival helpers.
  VRFW.daily = D

  local logger
  --- Internal: Logs text once through the daily logger.
  function D.log(text)
    logger = logger or VRFW.logger.new("VRFW daily")
    logger.once(text, text)
  end

  local function kind_of(k)
    if k == nil then
      return "day"
    end
    k = string.lower(tostring(k))
    if D.KINDS[k] then
      return k
    end
    return nil
  end

  --- Advanced: The current period of `kind`: index, seconds left, label; nil for an unknown kind.
  function D.period(kind, id)
    local k = kind_of(kind)
    if k == nil then
      return nil
    end
    local i, secs, label = VRFW.host.command(D.CMD.PERIOD, k, id)
    if type(i) ~= "number" or i < 0 and label == "" then
      return nil
    end
    return i, secs, label
  end

  local G = {}
  G.__index = G

  --- Internal: A seeded generator for key and spec.Period; nil on a bad key or period.
  function D.rng(key, spec)
    spec = spec or {}
    local k = kind_of(spec.Period)
    if type(key) ~= "string" or k == nil then
      D.log("Rng: a key text and Period day / week / month expected")
      return nil
    end
    local id = spec.Id
    if id == nil then
      id = D.period(k)
    end
    if id == nil then
      return nil
    end
    return setmetatable({ key = key, period = k, version = spec.Version or 1, id = id, cursor = 0 }, G)
  end

  --- Internal: The period seed as hex, then its id; nil for an unknown period.
  function D.seed(key, spec)
    spec = spec or {}
    local k = kind_of(spec.Period)
    if k == nil then
      return nil
    end
    local hex, id = VRFW.host.command(D.CMD.SEED, key, k, spec.Version or 1, spec.Id)
    if hex == nil or hex == "" then
      return nil
    end
    return hex, id
  end

  -- the result of a draw command: value, new cursor (-1 = error, third value = why)
  local function advance(g, what, v, cursor, err)
    if type(cursor) ~= "number" or cursor < 0 then
      D.log(what .. " " .. g.key .. ": " .. tostring(err or "no answer (framework DLL missing?)"))
      return nil
    end
    g.cursor = cursor
    return v
  end

  --- A random integer in lo..hi.
  function G:int(lo, hi)
    local v, c, e = VRFW.host.command(D.CMD.INT, self.key, self.period, self.version, self.id, self.cursor, lo, hi)
    return advance(self, "Int", v, c, e)
  end

  local function key_text(item, key)
    local v = item
    if type(key) == "function" then
      v = key(item)
    elseif key ~= nil then
      v = type(item) == "table" and item[key] or nil
    end
    if type(v) == "number" then
      if v ~= math.floor(v) then
        return nil
      end
      return string.format("%.0f", v)
    elseif type(v) == "string" and not string.find(v, "\n", 1, true) then
      return v
    end
    return nil
  end

  local function keys_of(items, key, what)
    if type(items) ~= "table" then
      D.log(what .. ": an item list expected")
      return nil
    end
    local t = {}
    for i = 1, #items do
      local s = key_text(items[i], key)
      if s == nil then
        D.log(what .. ": item " .. i .. " has no integer / text key")
        return nil
      end
      t[i] = s
    end
    return table.concat(t, "\n")
  end

  local function indices(list)
    local t = {}
    for s in string.gmatch(list or "", "%d+") do
      t[#t + 1] = tonumber(s)
    end
    return t
  end

  --- A random element of items; answers element and index, nil on a bad list.
  function G:pick(items, key)
    local keys = keys_of(items, key, "Pick")
    if keys == nil then
      return nil
    end
    local i, c, e = VRFW.host.command(D.CMD.PICK, self.key, self.period, self.version, self.id, self.cursor, keys)
    i = advance(self, "Pick", i, c, e)
    if i == nil or i < 1 then
      return nil
    end
    return items[i], i
  end

  local function many(self, cmd, what, items, keys, ...)
    local list, c, e = VRFW.host.command(cmd, self.key, self.period, self.version, self.id, self.cursor, keys, ...)
    list = advance(self, what, list, c, e)
    if list == nil then
      return nil
    end
    local idx = indices(list)
    local out = {}
    for n = 1, #idx do
      out[n] = items[idx[n]]
    end
    return out, idx
  end

  --- n random elements of items; nil on a bad list.
  function G:sample(items, n, key)
    local keys = keys_of(items, key, "Sample")
    if keys == nil then
      return nil
    end
    return many(self, D.CMD.SAMPLE, "Sample", items, keys, n)
  end

  --- Items shuffled; nil on a bad list.
  function G:shuffle(items, key)
    local keys = keys_of(items, key, "Shuffle")
    if keys == nil then
      return nil
    end
    return many(self, D.CMD.SHUFFLE, "Shuffle", items, keys)
  end

  --- A weighted random element of items; answers element and index, nil on a bad list.
  function G:weighted(items, weight, key)
    local keys = keys_of(items, key, "Weighted")
    if keys == nil then
      return nil
    end
    local w = {}
    for i = 1, #items do
      local x = items[i]
      local v
      if type(weight) == "function" then
        v = weight(x)
      elseif type(x) == "table" then
        v = x[weight]
      end
      if type(v) ~= "number" or v < 0 or v ~= math.floor(v) then
        D.log("Weighted: item " .. i .. " has no integer weight >= 0")
        return nil
      end
      w[i] = string.format("%.0f", v)
    end
    local i, c, e = VRFW.host.command(D.CMD.WEIGHTED, self.key, self.period, self.version, self.id, self.cursor, keys, table.concat(w, "\n"))
    i = advance(self, "Weighted", i, c, e)
    if i == nil or i < 1 then
      return nil
    end
    return items[i], i
  end

  --- Internal: Whether `key` is new this period: is_new, previous period, current period.
  function D.seen(key, kind)
    local isNew, prev, cur = VRFW.host.command(D.CMD.SEEN, key, kind_of(kind) or "")
    return isNew == true, prev or -1, cur or -1
  end

  --- Internal: Marks `key` done this period; answers ok, streak, newly_done.
  function D.mark_done(key, kind)
    local ok, streak, newly = VRFW.host.command(D.CMD.MARK_DONE, key, kind_of(kind) or "")
    return ok == true, streak or 0, newly == true
  end

  --- Internal: True when `key` is done this period.
  function D.is_done(key, kind)
    return VRFW.host.command(D.CMD.IS_DONE, key, kind_of(kind) or "") == true
  end

  --- Internal: Streak of `key`: current, best, total.
  function D.streak(key, kind)
    local s, b, t = VRFW.host.command(D.CMD.STREAK, key, kind_of(kind) or "")
    return s or 0, b or 0, t or 0
  end

  --- Internal: Status of `key` as a table (done, streak, best, total, last, current, seconds).
  function D.status(key, kind)
    local done, s, b, t, last, cur, secs = VRFW.host.command(D.CMD.STATUS, key, kind_of(kind) or "")
    return {
      done = done == true, streak = s or 0, best = b or 0, total = t or 0, lastDone = last or -1, current = cur or -1,
      secondsUntilNext = secs or 0,
    }
  end

  --- Internal: Calls fn when the period of `kind` changes; answers true, or false, why.
  function D.on(kind, fn, id)
    local k = kind_of(kind)
    if k == nil or type(fn) ~= "function" then
      return false, "a known period and a function expected"
    end
    local list = D.handlers[k] or {}
    D.handlers[k] = list
    if id ~= nil then
      for i = 1, #list do
        if list[i].id == id then
          list[i].fn = fn
          return true
        end
      end
    end
    list[#list + 1] = { id = id, fn = fn }
    return true
  end

  --- Internal: Calls the handlers of every period that changed.
  function D.poll()
    for _, k in ipairs({ "day", "week", "month" }) do
      local list = D.handlers[k]
      if list ~= nil and #list > 0 then
        local id = D.period(k)
        local old = D.last[k]
        if id ~= nil then
          D.last[k] = id
          if old ~= nil and old ~= id then
            for i = 1, #list do
              local ok, err = pcall(list[i].fn, id, old, k)
              if not ok then
                D.log("On " .. k .. " handler " .. tostring(list[i].id or i) .. " failed: " .. tostring(err))
              end
            end
          end
        end
      end
    end
  end

  --- Internal: Installs the period watch on menu `stem` once; answers true, or false, why.
  function D.watch(stem)
    if D.watched[stem] or type(VRFW.host) ~= "table" or type(VRFW.host.on) ~= "function" then
      return false, "already watched, or no VRFW.host"
    end
    D.watched[stem] = true
    VRFW.host.on(stem, "Step", {
      id = "vrfw.daily_poll", phase = "after",
      fn = function()
        D.frames = D.frames + 1
        if D.frames >= 30 then
          D.frames = 0
          D.poll()
        end
      end,
    })
    return true
  end
end
