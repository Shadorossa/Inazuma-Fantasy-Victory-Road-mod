-- lua_patch.scope: used
-- menu_engine: CHRONICLE COMPLETION (VRFW base feature).
if VRFW.chronicle == nil then
  local M = {
    PIECES = VRFW.commands.VRFW_CHRONICLE_PIECES,
    CLEAR_GET = VRFW.commands.GET_CHRONICLE_CLEAR_STATUS,    -- CMND_GET_CHRONICLE_CLEAR_STATUS (slot, difficulty)
    NODE = {COUNT = VRFW.commands.VRFW_TEAM_ROUTE_NODE_COUNT, GET = VRFW.commands.VRFW_TEAM_ROUTE_NODE_GET},   -- CMND_VRFW_TEAM_ROUTE_NODE_*
    CHAIN_COUNT = VRFW.commands.VRFW_TEAM_CHAIN_COUNT,   -- CMND_VRFW_TEAM_CHAIN_COUNT
    OF_PIECE = VRFW.commands.VRFW_TEAM_CHAIN_OF_PIECE,
    list = nil,                -- {{piece, slot, difficulty or nil (= the caller's)}} (per VM)
    cache = {},                -- d -> {done, cleared, total, missing}
    slot_of = nil,             -- pieceId -> the slot its clear bits use (per VM)
  }
  VRFW.chronicle = M

  local function u32(v) return VRFW.ids.unsigned(v) end

  local logger
  --- Logs through the chronicle logger.
  function M.log(...)
    logger = logger or VRFW.logger.new("chronicle")
    logger(...)
  end

  -- the pieces that count: the script's list with the route nodes' own slot / difficulty, the chain nodes left out
  local function pieces()
    if M.list ~= nil then
      return M.list
    end
    local ok, got = pcall(funcLuaCommand, M.PIECES)
    if not ok or type(got) ~= "table" or #got == 0 then
      M.log("no board piece listed (the script command did not answer)")
      return nil                                   -- asked again next time
    end
    local nodes = {}
    local n = VRFW.host.command(M.NODE.COUNT)
    for i = 0, (type(n) == "number" and n or 0) - 1 do
      local piece, slot, _, diffs, _, _, _, _, _, _, hub = VRFW.host.command(M.NODE.GET, i)
      if type(piece) == "number" and piece ~= 0 then
        local chain = (type(hub) == "string" and hub ~= "") or ((VRFW.host.command(M.OF_PIECE, piece) or -1) >= 0)
        local d = tonumber(string.match(type(diffs) == "string" and diffs or "", "^%s*(%d+)"))
        nodes[u32(piece)] = {slot = slot, d = d, chain = chain}
      end
    end
    local list = {}
    for _, p in ipairs(got) do
      local id, sfi = u32(p[1]), tonumber(p[2]) or 0
      local nd = nodes[id]
      if nd == nil then
        list[#list + 1] = {id, sfi, nil}
      elseif not nd.chain then
        list[#list + 1] = {id, tonumber(nd.slot) or sfi, nd.d}
      end
    end
    M.list = list
    M.log("pieces", #list, "of", #got, "(route nodes", n or 0, ")")
    return list
  end

  local function cleared(slot, d)
    if slot >= 300 then
      return VRFW.route_slots ~= nil and VRFW.route_slots.get("clear", slot, d) == true
    end
    local v = VRFW.host.command(M.CLEAR_GET, slot, d)
    return v == true
  end

  --- Forgets the cached completion.
  function M.reset()
    M.cache = {}
  end

  --- Chronicle completion of difficulty d: done, have, total, missing.
  function M.complete(d)
    d = tonumber(d) or 2
    local c = M.cache[d]
    if c ~= nil then
      return c[1], c[2], c[3], c[4]
    end
    local list = pieces()
    if list == nil then
      return false, 0, 0, "no piece list"
    end
    local have, total, missing = 0, 0, nil
    for _, p in ipairs(list) do
      total = total + 1
      if cleared(p[2], p[3] or d) then
        have = have + 1
      elseif missing == nil then
        missing = string.format("piece 0x%08X slot %d difficulty %d", p[1], p[2], p[3] or d)
      end
    end
    local nc = VRFW.host.command(M.CHAIN_COUNT)
    for i = 0, (type(nc) == "number" and nc or 0) - 1 do
      local b = VRFW.chain ~= nil and VRFW.chain.board(i) or nil
      if b ~= nil then
        total = total + 1
        if VRFW.chain.complete(b) then
          have = have + 1
        elseif missing == nil then
          missing = "chain " .. b.key
        end
      end
    end
    local done = total > 0 and have == total
    M.cache[d] = {done, have, total, missing}
    M.log("complete", tostring(done), have, "/", total, "difficulty", d, "first missing", missing or "-")
    return done, have, total, missing
  end

  --- Whether piece `piece` (a board piece or a route node) was cleared at difficulty d; false when the board does not list it.
  function M.piece_cleared(piece, d)
    if M.slot_of == nil then
      local list = pieces()
      if list == nil then
        return false
      end
      local slots = {}
      for _, p in ipairs(list) do
        slots[p[1]] = p[2]
      end
      M.slot_of = slots
    end
    local slot = M.slot_of[u32(piece)]
    return slot ~= nil and cleared(slot, tonumber(d) or 2)
  end
end
