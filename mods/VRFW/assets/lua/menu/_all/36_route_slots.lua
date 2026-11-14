-- lua_patch.scope: used
if VRFW.route_slots == nil then
  local M = {
    BASE = 300,
    PIECE = 126049514,        -- piece info (pieceIndex, field): field 6 = statusFlagIndex
    CLEAR_GET = VRFW.commands.GET_CHRONICLE_CLEAR_STATUS,   -- CMND_GET_CHRONICLE_CLEAR_STATUS (slot, difficulty)
    CLEAR_SET = VRFW.commands.SET_CHRONICLE_CLEAR_STATUS,   -- CMND_SET_CHRONICLE_CLEAR_STATUS (slot, on, difficulty)
    LOCK_GET = VRFW.commands.GET_CHRONICLE_LOCK_STATUS,    -- CMND_GET_CHRONICLE_LOCK_STATUS (slot, difficulty)
    LOCK_SET = VRFW.commands.SET_CHRONICLE_LOCK_STATUS,    -- CMND_SET_CHRONICLE_LOCK_STATUS (slot, locked, difficulty)
    PIECE_IDX = 1064555639,   -- pieceId -> ok, piece index
    NODE_COUNT = VRFW.commands.VRFW_TEAM_ROUTE_NODE_COUNT,   -- CMND_VRFW_TEAM_ROUTE_NODE_COUNT
    NODE_GET = VRFW.commands.VRFW_TEAM_ROUTE_NODE_GET,     -- CMND_VRFW_TEAM_ROUTE_NODE_GET (i) -> pieceId, slot, ...
    SAVE_GET = VRFW.commands.VRFW_SAVE_GET,
    SAVE_SET = VRFW.commands.VRFW_SAVE_SET,
    OWNER = "VRFW",
    BIT = {[1] = 1, [2] = 2, [3] = 4, [4] = 8, [10] = 16, [11] = 32},
    by_idx = nil,              -- piece index -> extended slot (per VM, built on first use)
    installed = false,
  }
  --- Advanced: Namespace of the route slot handling: route node clear and lock state per slot.
  VRFW.route_slots = M

  local function log(...)
    if PRINT ~= nil then
      pcall(PRINT, "VRFW.route_slots", ...)
    end
  end

  -- the team type's command (with the real funcLuaCommand)
  local function call(real, cmd, ...)
    local r = table.pack(pcall(real, cmd, ...))
    if r[1] and r[2] ~= nil then
      return table.unpack(r, 2, r.n)
    end
    return nil
  end

  -- piece index -> extended slot of every route node with a slot >= BASE
  local function load(real)
    if M.by_idx ~= nil then
      return M.by_idx
    end
    --- Internal: map from route node index to its slot data, rebuilt on demand.
    M.by_idx = {}
    local n = call(real, M.NODE_COUNT)
    if type(n) ~= "number" then
      return M.by_idx
    end
    for i = 0, n - 1 do
      local piece, slot = call(real, M.NODE_GET, i)
      if type(piece) == "number" and type(slot) == "number" and slot >= M.BASE then
        local ok, okI, idx = pcall(real, M.PIECE_IDX, piece)
        if ok and okI and type(idx) == "number" then
          M.by_idx[idx] = slot
        end
      end
    end
    local count = 0
    for _ in pairs(M.by_idx) do count = count + 1 end
    log("extended slots", count, "of", n, "nodes")
    return M.by_idx
  end

  local function read(real, slot)
    local ok, s = pcall(real, M.SAVE_GET, M.OWNER, "route_slot." .. tostring(slot), "")
    local c, l = 0, 0
    if ok and type(s) == "string" then
      local a, b = string.match(s, "^(%d+),(%d+)$")
      c, l = tonumber(a) or 0, tonumber(b) or 0
    end
    return c, l
  end

  local function has(mask, bit)
    return math.floor(mask / bit) % 2 == 1
  end

  local function with(mask, bit, on)
    if has(mask, bit) == (on == true) then
      return mask
    end
    return on and mask + bit or mask - bit
  end

  local function get(real, kind, slot, d)
    local bit = M.BIT[d]
    if bit == nil then
      return false
    end
    local c, l = read(real, slot)
    return has(kind == "clear" and c or l, bit)
  end

  local function set(real, kind, slot, on, d)
    local bit = M.BIT[d]
    if bit == nil then
      return
    end
    local c, l = read(real, slot)
    if kind == "clear" then
      c = with(c, bit, on)
    else
      l = with(l, bit, on)
    end
    pcall(real, M.SAVE_SET, M.OWNER, "route_slot." .. tostring(slot), c .. "," .. l, 1)
  end

  --- Advanced: Reads a route-slot flag of kind `kind`; `d` is the default.
  function M.get(kind, slot, d)
    return get(funcLuaCommand, kind, slot, d)
  end

  --- Internal: Writes a route-slot flag of kind `kind`.
  function M.set(kind, slot, on, d)
    set(funcLuaCommand, kind, slot, on, d)
  end

  --- Advanced: Installs the route-slot commands once; answers true, or false, why.
  function M.install()
    if M.installed then
      return false, "already installed"
    end
    if type(funcLuaCommand) ~= "function" then
      return false, "no command function yet"
    end
    -- the argument count is passed on unchanged (a C command may check it)
    local function handler(nxt, ...)
      local cmd, a, b, c = ...
      if cmd == M.PIECE and b == 6 and type(a) == "number" then
        local slot = load(funcLuaCommand)[a]
        if slot ~= nil then
          return true, slot
        end
      elseif type(a) == "number" and a >= M.BASE then
        if cmd == M.CLEAR_GET then
          return get(funcLuaCommand, "clear", a, b)
        elseif cmd == M.LOCK_GET then
          return get(funcLuaCommand, "lock", a, b)
        elseif cmd == M.CLEAR_SET then
          set(funcLuaCommand, "clear", a, b, c)
          return
        elseif cmd == M.LOCK_SET then
          set(funcLuaCommand, "lock", a, b, c)
          return
        end
      end
      return nxt(...)
    end
    --- Internal: true once the route slot command hook is installed.
    M.installed = VRFW.host.hook_command({ M.PIECE, M.CLEAR_GET, M.LOCK_GET, M.CLEAR_SET, M.LOCK_SET }, handler,
      "VRFW.route_slots")
    return M.installed
  end

  --- Internal: Wraps OnInit so the commands are installed once the script is up.
  function M.watch()
    local prev = OnInit
    OnInit = function(...)
      M.install()
      if prev ~= nil then
        return prev(...)
      end
    end
    return true
  end
end
