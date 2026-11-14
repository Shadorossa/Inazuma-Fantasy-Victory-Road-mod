-- Internal:
-- lua_patch.scope: used
VRFW.friendly_match = VRFW.friendly_match or {}
do
  local P = VRFW.friendly_match
  --- Internal: command hashes of the friendly match plugin (START, STEP, REPORT, ABORT, BACK...).
  P.CMD = {
    START = VRFW.commands.VRFW_FRIENDLY_START, STEP = 2152525079, REPORT = 2550860972, ABORT = 1839503551, BACK = VRFW.commands.VRFW_FRIENDLY_BACK,
    STATE = 881000032, ACK = 3682169452, AUX = 1130333797, PASSED = 1073637999, PASSED_SET = 662976001,
    MAP = 1781538918, RULES = 512472487, ROLL = VRFW.commands.VRFW_ITEM_REWARD_ROLL,
  }
  --- Internal: hash of the retail encounter fade menu.
  P.FADE_ENCOUNT = 2721617045 --[[fade_menu_encount]]
  -- Internal: op codes of crate::pachanga::Step::encode
  P.OP = {VS_SWAP = 1, KIT = 2, VS_RESTORE = 3, RETURN = 4, DEACTIVATE = 10, FADE_BLACK = 11, FADE_ENCOUNTER = 12,
    BYTE = 13, WAIT = 14, ACTIVATE = 15, PRE_MATCH = 20, DIFFICULTY = 21, RESERVE = 22, KEY = 30, CLOSE = 31,
    WAIT_GONE = 32, WAIT_SETTLED = 33, TOP_WAIT = 34, WATCHDOG = 35}

  local logger
  --- Internal: Logs through the pachanga logger.
  function P.log(...)
    logger = logger or VRFW.logger.new("EVT pachanga")
    logger(...)
  end
  local function wait(f, frames)
    for _ = 1, frames do
      if f() then
        return true
      end
      coroutine.yield()
    end
    return false
  end

  --- Internal: The active friendly dock (2..12) or nil: the VS team swapped out by a friendly, else the VS team, when its five can play.
  function P.pachanga_set()
    local ok, _, pending = pcall(funcLuaCommand, VRFW.commands.VRFW_FRIENDLY_VS, 2)
    if not ok or type(pending) ~= "number" then
      return nil
    end
    local set = pending >= 0 and pending or funcLuaCommand(VRFW.commands.GET_VS_USE_TEAM_SET)
    if type(set) ~= "number" or set < 2 or set > 12 then
      return nil
    end
    local code = funcLuaCommand(1538643580, set, 1, false) -- retail member check of the 5v5 team
    if type(code) == "number" and code > 0 and code < 11 then
      return nil
    end
    return set
  end

  --- Internal: a five WITHOUT a kit of its own wears its dock's 11v11 kit (street battles dress kit-less fives in gym clothes).
  function P.kit(set)
    local a = table.pack(pcall(funcLuaCommand, VRFW.commands.VRFW_TEAM_UNIFORM, set, 0))
    local b = table.pack(pcall(funcLuaCommand, VRFW.commands.VRFW_TEAM_UNIFORM, set, 1))
    if a[1] ~= true or a[2] ~= true or type(a[3]) ~= "number" or a[3] == 0 or b[1] ~= true or b[2] ~= true then
      return
    end
    if b[3] == a[3] or b[3] ~= 0 then
      return
    end
    pcall(funcLuaCommand, VRFW.commands.VRFW_TEAM_UNIFORM, set, 1, a[3], 0)
  end

  --- Internal: Restores the VS team a friendly swapped out.
  function P.restore_versus()
    local ok, had, vs = pcall(funcLuaCommand, VRFW.commands.VRFW_FRIENDLY_VS, 0)
    if ok and had == true and type(vs) == "number" and vs >= 0 then
      funcLuaCommand(VRFW.commands.SET_VS_USE_TEAM_SET, vs)
      P.log("VS team restored", vs)
    end
  end

  local function exec(op, a, b, c)
    local O = P.OP
    if op == O.VS_SWAP then
      pcall(funcLuaCommand, VRFW.commands.VRFW_FRIENDLY_VS, 1, funcLuaCommand(VRFW.commands.GET_VS_USE_TEAM_SET --[[GET_VS_USE_TEAM_SET]]))
      funcLuaCommand(VRFW.commands.SET_VS_USE_TEAM_SET, a)
    elseif op == O.KIT then
      pcall(P.kit, a)
    elseif op == O.VS_RESTORE then
      P.restore_versus()
    elseif op == O.RETURN then
      local okt, live, armed = VRFW.host.command(VRFW.commands.VRFW_BATTLE_RETURN, a)
      P.log("way-back route", a, tostring(okt), tostring(live), tostring(armed))
    elseif op == O.DEACTIVATE then
      funcLuaMenuCommand(1558704558, a, false)
    elseif op == O.ACTIVATE then
      funcLuaMenuCommand(1558704558, a, true)
    elseif op == O.FADE_BLACK then
      if b == 1 then
        funcLuaCommand(609722083, 1, a)
        coroutine.yield()
        wait(function() return funcLuaCommand(2259183189) end, c)
      else
        funcLuaCommand(609722083, 0, a)
      end
    elseif op == O.FADE_ENCOUNTER then
      if b == 1 then
        pcall(funcLuaCommand, 3366565849, true, P.FADE_ENCOUNT)
        if a > 0 then
          wait(function()
            local ok, busy = pcall(funcLuaCommand, 316436678 --[[menu fade running]])
            return not ok or busy ~= true
          end, a)
        end
      else
        pcall(funcLuaCommand, 3366565849, false, P.FADE_ENCOUNT)
        local okf, black = pcall(funcLuaCommand, 2259183189)
        if okf and black then
          pcall(funcLuaCommand, 609722083, 0, 0.3)
        end
      end
    elseif op == O.BYTE then
      VRFW.host.command(VRFW.commands.SET_GLOBAL_BYTE_FLAG, a, b)
    elseif op == O.WAIT then
      for _ = 1, a do
        coroutine.yield()
      end
    elseif op == O.PRE_MATCH then
      VRFW.host.command(VRFW.commands.SET_PRE_MATCH_SOCCER_GAME_ID, a)
    elseif op == O.DIFFICULTY then
      VRFW.host.command(1104380539 --[[difficulty helper]], a)
    elseif op == O.RESERVE then
      if b == 0 and P.home_open then
        local home, team = P.home_stadium()
        if home ~= 0 then
          P.log("home match: team", team, "home stadium", home)
          b = home
        end
      end
      P.home_open = false
      local ok, r = pcall(funcLuaCommand, VRFW.commands.RESERVE_SOCCER, a, b, c)
      P.log("reserve", a, b, c, tostring(ok), tostring(r))
      return ok and r ~= false and r ~= nil
    elseif op == O.KEY then
      if funcLuaCommand(2947612279, a) then
        funcLuaCommand(3363400568, a)
      end
      if b ~= 0 then
        funcLuaCommand(3860611758, a, 0, b, 1)
      end
    elseif op == O.CLOSE then
      funcLuaCommand(VRFW.commands.CLOSE_MENU_OBJECT, a)
    elseif op == O.WAIT_GONE then
      local n = 0
      while n < b and funcLuaMenuCommand(VRFW.commands.IS_EXIST_MENU_OBJECT, a) do
        n = n + 1
        coroutine.yield()
      end
      return n < b
    elseif op == O.WAIT_SETTLED then
      wait(function() return funcLuaMenuCommand(3050482496) ~= false end, a)
      wait(function() return not funcLuaCommand(2736534827 --[[fade busy]]) end, a)
    elseif op == O.TOP_WAIT then
      funcLuaCommand(769636339, a)
    elseif op == O.WATCHDOG then
      for _ = 1, a do
        coroutine.yield()
      end
      return not funcLuaCommand(2947612279, b)
    end
    return true
  end
  --- Internal: runs the friendly match steps of the plugin for a context.
  P.exec = exec

  --- Internal: The home stadium of dock `set`; answers map (0 = none), set.
  function P.home_stadium(set)
    local M = VRFW.home_stadium
    if type(M) ~= "table" or type(M.of) ~= "function" then
      return 0, set
    end
    if type(set) ~= "number" then
      local ok, vs = pcall(funcLuaCommand, VRFW.commands.GET_VS_USE_TEAM_SET)
      set = (ok and type(vs) == "number") and vs or -1
    end
    local ok, map = pcall(M.of, set)
    if ok and type(map) == "number" then
      return map, set
    end
    return 0, set
  end

  --- Internal: Undoes the last n recorded launch steps.
  function P.rollback(n)
    for i = 1, (n or 0) do
      local op, a, b, c = VRFW.host.command(P.CMD.STEP, -i)
      if type(op) == "number" and op > 0 then
        exec(op, a, b, c)
      end
    end
  end

  -- Internal: THE function.
  --- Starts friendly match `id` with context ctx; answers true, or false, why.
  function P.start(id, ctx)
    ctx = ctx or {}
    local set = ctx.set
    if set == nil then
      set = P.pachanga_set() or -1
    end
    local m = ctx.map or {}
    local rival = ctx.rival
    if rival == nil and (ctx.game or 0) ~= 0 then
      local d = ctx.difficulty or 0
      local okT, team = VRFW.host.command(2204933160 --[[game row's rival team]], ctx.game, d ~= 0 and d or 1)
      if okT == true and type(team) == "number" then
        rival = team
      end
    end
    local ok, code, n = VRFW.host.command(P.CMD.START, id, ctx.tag or 0, ctx.sub or 0, ctx.game or 0, ctx.difficulty or 0,
      ctx.objective or 0, set, ctx.stadium or 0, m[1] or 0, m[2] or 0, m[3] or 0, m[4] or 0, m[5] or 0, rival or 0)
    if ok ~= true then
      P.log("start refused", id, tostring(code))
      return false, code
    end
    local skip = false
    --- Internal: true while the match runs without a stadium of its own in the context.
    P.home_open = ctx.stadium == nil
    for i = 1, (n or 0) do
      local op, a, b, c = VRFW.host.command(P.CMD.STEP, i)
      if type(op) ~= "number" or op == 0 then
        break
      end
      if not (skip and op ~= P.OP.WATCHDOG) then
        local good = exec(op, a, b, c)
        if op == P.OP.RESERVE or (op == P.OP.WATCHDOG and not good) then
          local nb = VRFW.host.command(P.CMD.REPORT, i, good and 1 or 0)
          if not good then
            if type(ctx.on_failed) == "function" then
              pcall(ctx.on_failed, op == P.OP.RESERVE and "reserve" or "watchdog") -- the caller's own state first
            end
            P.rollback(nb)
            return false, op == P.OP.RESERVE and "reserve" or "watchdog"
          end
          if op == P.OP.RESERVE and type(ctx.on_reserved) == "function" then
            pcall(ctx.on_reserved) -- the caller's own state (the hand-off may end this coroutine)
          end
        elseif op == P.OP.WAIT_GONE and not good then
          skip = true
        end
      end
    end
    P.home_open = false
    return true
  end

  --- Internal: Aborts the pending launch and rolls back its steps.
  function P.abort(why)
    P.rollback(VRFW.host.command(P.CMD.ABORT, why or "aborted"))
  end

  --- Internal: Returns from a match to `where`; answers an info table (closed, outcome, passed, id, tag, sub).
  function P.back(where)
    local r = table.pack(VRFW.host.command(P.CMD.BACK, where))
    local info = {closed = r[1] == true, outcome = r[2] or 0, passed = r[3] == true, origin = r[4] or 0,
      team_swapped = r[5] == true, id = r[6], tag = r[7] or 0, sub = r[8] or 0,
      aux = {r[9] or 0, r[10] or 0, r[11] or 0, r[12] or 0}, rewards = r[13] or ""}
    if info.closed then
      if info.team_swapped then
        P.restore_versus()
      end
      if info.rewards ~= "" then
        P.give(info.rewards)
      end
      P.log("back", where, tostring(info.id), info.outcome, tostring(info.passed))
    end
    return info
  end

  --- Internal: The launch state as a table (phase, id, tag, sub, ret, aux).
  function P.state()
    local r = table.pack(VRFW.host.command(P.CMD.STATE))
    return {phase = r[1] or 0, id = r[2], tag = r[3] or 0, sub = r[4] or 0, outcome = r[5] or 0, passed = r[6] == true,
      ret = r[7] or 0, aux = {r[8] or 0, r[9] or 0, r[10] or 0, r[11] or 0}, field_net = r[12] == true}
  end
  --- Internal: Reads or writes aux value i; answers true when the command succeeded.
  function P.aux(i, v)
    return VRFW.host.command(P.CMD.AUX, i, v) == true
  end
  --- Internal: True when the (id, tag, sub) launch was passed.
  function P.passed(id, tag, sub)
    return VRFW.host.command(P.CMD.PASSED, id, tag or 0, sub or 0) == true
  end
  --- Internal: Marks the (id, tag, sub) launch passed or not; answers true when stored.
  function P.set_passed(id, tag, sub, on)
    return VRFW.host.command(P.CMD.PASSED_SET, id, tag or 0, sub or 0, on and 1 or 0) == true
  end

  --- Internal: Gives the reward roll of `key`.
  function P.give(key)
    local ok, n, list = pcall(funcLuaCommand, P.CMD.ROLL, key, math.random(1, 2147483646), false)
    if not ok or type(list) ~= "string" then
      return
    end
    for item, count in string.gmatch(list, "(%d+):(%d+)") do
      pcall(funcLuaCommand, VRFW.commands.ADD_ITEM_ONLY, tonumber(item), tonumber(count))
    end
  end
end
