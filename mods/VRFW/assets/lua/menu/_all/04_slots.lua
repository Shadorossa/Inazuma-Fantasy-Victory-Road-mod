VRFW.slots = VRFW.slots or {}
do
  local S = VRFW.slots
  local C = {
    VERSION = VRFW.commands.VRFW_LOADER_VERSION,      -- () -> api, modules (bit value 2 = the slot service)
    ACTIVE = VRFW.commands.VRFW_SLOT_ACTIVE,         -- () -> active slot
    LAYOUT = VRFW.commands.VRFW_SLOT_LAYOUT,         -- () -> playerCount, lockedSlot, active, slot1, slot2, ...
    RESERVED = VRFW.commands.VRFW_SLOT_RESERVED,
    RELOAD = VRFW.commands.VRFW_SLOT_RELOAD,
    ABORT = VRFW.commands.VRFW_SLOT_ABORT,           -- () -> bool: back to the previous slot, fence off
    PLAY_TARGET = VRFW.commands.VRFW_SLOT_PLAY_TARGET,
    SLOT_INFO = 1195222835,                     -- (n) -> exists, ...
    COMMIT = 4173545121,                        -- () -> bool: fence off, slot remembered
    BUSY = 1127104486,                          -- () -> bool: a game save / load job is pending
    LOG = VRFW.commands.VRFW_LOG,
    LOAD_HEADER = 4179471494, IS_SAVE_WORKING = 1979970074, LOAD_GAME_DATA = 2585060058, LOAD_FAILED = 3772572101,
    APPLY = 3660094710, HEADER_CLEAR = 3960538079, RESET_ALL = 1481565076,
    SKIP_PRESS_START = 937976662,               -- (true): the next title opens title_menu_2 at once
    SKIP_PENDING = 2335895154,
    GAME_RESET = VRFW.commands.GAME_RESET,
    GET_GFLAG = VRFW.commands.GET_GLOBAL_BIT_FLAG, SET_GFLAG = VRFW.commands.SET_GLOBAL_BIT_FLAG,
    FLAG_AVATAR_DONE = 2113473044,              -- off: the next title runs the retail first run (avatar, team)
    FADE = 609722083, FADE_DONE = 2259183189, FADE_BUSY = 2736534827, IS_FADE = VRFW.commands.BRIGHT_IS_FADE,
    PRE_RESET = 3015544382,
    OPEN_MENU = VRFW.commands.OPEN_MENU_OBJECT, EXIST_MENU = VRFW.commands.IS_EXIST_MENU_OBJECT,
    CLOSE_MENU = VRFW.commands.CLOSE_MENU_OBJECT,
    TEXT_GET = VRFW.commands.TEXT_GET,
  }
  local SCREEN = 2103230976        -- vrfw_save_slot_menu
  local SCREEN_RESULT = 2449975398 -- its result: 0 cancel, else the slot
  local MAX_SLOT = 99              -- save engine MAX_SLOT
  local LOCKED_SLOT = 1            -- the layout's locked slot without the layout command
  local WAIT_FRAMES = 3600         -- a save / load job given up after ~60 s
  local FADE_FRAMES = 240
  local MOVE_TRIES, MOVE_RETRY_FRAMES = 5, 120
  local TXT = {
    BUSY = { 1981719410 --[[vrfw_slot_switch_busy]], "The game is saving or loading. Try again in a few seconds." },
    REFUSED = { 1429037734 --[[vrfw_slot_switch_refused]], "Could not switch to Slot %d." },
    LOAD_FAILED = { 355550271 --[[vrfw_slot_switch_load_failed]],
      "The data of Slot %d could not be loaded. The current slot is kept." },
  }

  local function Log(...)
    VRFW.host.command(C.LOG, "save_slots", ...)
  end

  --- Slot-screen text `key` for slot k; "" when unknown.
  function S.text(key, k)
    local t = TXT[key]
    if t == nil then
      return ""
    end
    local s = VRFW.host.command(C.TEXT_GET, t[1])
    if type(s) ~= "string" or s == "" then
      s = t[2]
    end
    if s:find("%%d") then
      s = string.format(s, math.floor(tonumber(k) or 0))
    end
    return s
  end

  --- True when the framework's save slots are active.
  function S.available()
    local api, mods = VRFW.host.command(C.VERSION)
    return type(api) == "number" and api >= 1 and type(mods) == "number" and math.floor(mods / 2) % 2 == 1
  end

  --- Whether slot k is a player slot, then the locked slot number.
  function S.layout(k)
    local t = table.pack(VRFW.host.command(C.LAYOUT))
    if type(t[1]) ~= "number" or t[1] < 1 then
      return k >= 1 and k <= 3, LOCKED_SLOT
    end
    local player = false
    for i = 4, 3 + math.floor(t[1]) do
      if t[i] == k then
        player = true
      end
    end
    return player, type(t[2]) == "number" and math.floor(t[2]) or LOCKED_SLOT
  end

  --- The mod reserving slot k: owner, enterable, root menu; nil, false, nil when it is not reserved.
  function S.reserved(k)
    local r, owner, enterable, root = VRFW.host.command(C.RESERVED, k)
    if r ~= true or type(owner) ~= "string" or owner == "" then
      return nil, false, nil
    end
    return owner, enterable == true, (type(root) == "string" and root ~= "") and root or nil
  end

  local function WaitJob()
    local k = 0
    coroutine.yield()
    while funcLuaCommand(C.IS_SAVE_WORKING) do
      k = k + 1
      if k > WAIT_FRAMES then
        return false
      end
      coroutine.yield()
    end
    return true
  end

  local function FadeOut()
    funcLuaCommand(C.FADE, 1, 0.5)
    coroutine.yield()
    local k = 0
    while not funcLuaCommand(C.FADE_DONE) and k < FADE_FRAMES do
      k = k + 1
      coroutine.yield()
    end
    while funcLuaCommand(C.FADE_BUSY) and k < 2 * FADE_FRAMES do
      k = k + 1
      coroutine.yield()
    end
    if k >= FADE_FRAMES then
      Log("fade out: gave up waiting after", k, "frames")
    end
  end

  local function FadeIn()
    funcLuaCommand(C.FADE, 0, 0.3)
    coroutine.yield()
    local k = 0
    while funcLuaCommand(C.IS_FADE) and k < FADE_FRAMES do
      k = k + 1
      coroutine.yield()
    end
  end

  local function Forever()
    while true do
      coroutine.yield()
    end
  end

  --- Loads slot k and restarts into its save; answers false, why when it cannot.
  function S.load(k, spec)
    spec = spec or {}
    local log = type(spec.log) == "function" and spec.log or Log
    if VRFW.host.command(C.BUSY) == true then
      return false, S.text("BUSY", k)
    end
    local exists = spec.exists
    if exists == nil then
      exists = VRFW.host.command(C.SLOT_INFO, k) == true
    end
    if VRFW.host.command(C.RELOAD, k) ~= true then
      log("reload refused", k)
      return false, S.text("REFUSED", k)
    end
    local owner, _, root = S.reserved(k)
    local reserved = owner ~= nil
    if reserved and type(spec.on_reserved) == "function" then
      local okh, err = pcall(spec.on_reserved, owner, k)
      if not okh then
        log("reserved enter hook of", owner, "failed:", tostring(err))
      end
    end
    if exists and VRFW.host.command(C.SLOT_INFO, k) ~= true then
      log("slot", k, "has no readable game any more: started as a new game")
      exists = false
    end
    log("switch", k, exists == true, root and ("root menu " .. root) or "title")
    FadeOut()
    if exists then
      funcLuaCommand(C.LOAD_HEADER)
      local ok = WaitJob()
      local started = ok and funcLuaCommand(C.LOAD_GAME_DATA, 1)
      ok = started and WaitJob() and not funcLuaCommand(C.LOAD_FAILED)
      if not ok then
        log("load failed", k)
        VRFW.host.command(C.ABORT)
        funcLuaCommand(C.LOAD_HEADER)
        WaitJob()
        FadeIn()
        return false, S.text("LOAD_FAILED", k)
      end
      funcLuaCommand(C.APPLY)
      if root ~= nil and type(VRFW.reset) == "table" then
        log("commit (root menu)", VRFW.host.command(C.COMMIT) == true)
        local how = VRFW.reset.straight({ menu = root, bgm_stop = true, need_carry = true,
          log = function(text) log("slot", k, "root menu:", text) end })
        log("slot", k, "root menu", root, ":", how)
        if how ~= "refused" then
          Forever()
        end
      end
    else
      funcLuaCommand(C.HEADER_CLEAR)
      funcLuaCommand(C.RESET_ALL)
      log("commit (new game)", VRFW.host.command(C.COMMIT) == true)
      if not reserved then
        funcLuaCommand(C.SET_GFLAG, C.FLAG_AVATAR_DONE, false)
        log("first run", k, "avatar flag", funcLuaCommand(C.GET_GFLAG, C.FLAG_AVATAR_DONE) == true)
      end
    end
    funcLuaCommand(C.SKIP_PRESS_START, (exists == true or reserved) and spec.to_title ~= true)
    log("game reset", k)
    if spec.close_menu ~= nil then
      funcLuaMenuCommand(C.PRE_RESET)
      funcLuaCommand(C.CLOSE_MENU, spec.close_menu, true)
    end
    funcLuaCommand(C.GAME_RESET)
    Forever()
  end

  --- True when the active slot is the locked slot, or no slot is active.
  function S.on_locked()
    local active = VRFW.host.command(C.ACTIVE)
    if type(active) ~= "number" then
      return false
    end
    local _, locked = S.layout(active)
    return active < 1 or active == locked
  end

  --- Fades out and returns to the title screen.
  function S.to_title(close_menu, log)
    log = type(log) == "function" and log or Log
    FadeOut()
    funcLuaCommand(C.SKIP_PRESS_START, false)
    log("locked slot: game reset into the EMPEZAR title")
    if close_menu ~= nil then
      funcLuaMenuCommand(C.PRE_RESET)
      funcLuaCommand(C.CLOSE_MENU, close_menu, true)
    end
    funcLuaCommand(C.GAME_RESET)
    Forever()
  end

  local function MoveOffLocked(log)
    local free, used = VRFW.host.command(C.PLAY_TARGET)
    local targets = {}
    if type(used) == "number" and used >= 1 then
      targets[#targets + 1] = { used, { exists = true, to_title = true, log = log } }
    end
    if type(free) == "number" and free >= 1 then
      targets[#targets + 1] = { free, { exists = false, log = log } }
    end
    for _, target in ipairs(targets) do
      for try = 1, MOVE_TRIES do
        local _, why = S.load(target[1], target[2])
        log("locked slot: move to slot", target[1], "failed, try", try, "of", MOVE_TRIES, ":", tostring(why))
        for _ = 1, MOVE_RETRY_FRAMES do
          coroutine.yield()
        end
      end
    end
    log("ERROR locked slot: no writable slot could be entered; the title stays on the locked slot and nothing it writes is kept")
  end

  --- With the locked slot active at the title: leaves it when there is no avatar, otherwise cancels a pending press-start skip.
  function S.title_guard(log)
    log = type(log) == "function" and log or Log
    if not S.available() or not S.on_locked() then
      return
    end
    if VRFW.host.command(C.GET_GFLAG, C.FLAG_AVATAR_DONE) ~= true then
      log("locked slot active and no avatar: a new game never starts here")
      MoveOffLocked(log)
    elseif VRFW.host.command(C.SKIP_PENDING) == true then
      log("locked slot active: the mode row was asked for, the EMPEZAR title opens instead")
      funcLuaCommand(C.SKIP_PRESS_START, false)
    end
  end

  --- Opens the slot screen; answers "same", "cancel", the result of S.load, or false, why.
  function S.screen(spec)
    spec = spec or {}
    local log = type(spec.log) == "function" and spec.log or Log
    VRFW.param.clear(SCREEN_RESULT)
    funcLuaCommand(C.OPEN_MENU, SCREEN)
    coroutine.yield()
    coroutine.yield()
    if not funcLuaMenuCommand(C.EXIST_MENU, SCREEN) then
      log("slot screen: did not open")
      return false, S.text("REFUSED", 0)
    end
    if type(spec.shown) == "function" then
      pcall(spec.shown)
    end
    while funcLuaMenuCommand(C.EXIST_MENU, SCREEN) do
      coroutine.yield()
    end
    local r = VRFW.param.has(SCREEN_RESULT) and VRFW.param.get(SCREEN_RESULT) or 0
    VRFW.param.clear(SCREEN_RESULT)
    r = math.floor(tonumber(r) or 0)
    local active = VRFW.host.command(C.ACTIVE)
    local player, locked = S.layout(r)
    log("slot screen result", r, "active", tostring(active))
    if r == locked then
      r = 0          -- the locked slot is never continued
    end
    if r == active then
      return "same"
    end
    if r >= 1 and not player then
      local owner, enterable = S.reserved(r)
      if owner == nil or not enterable then
        log("slot screen result", r, "refused: not a reserved slot whose owner's mode is on")
        r = 0
      end
    end
    if r < 1 or r > MAX_SLOT then
      return "cancel"
    end
    return S.load(r, { log = log })
  end

  --- Restarts straight into the root menu of the active slot's owner; nil when no slot is active.
  function S.forward(log)
    log = type(log) == "function" and log or Log
    local active = VRFW.host.command(C.ACTIVE)
    if type(active) ~= "number" then
      return nil
    end
    local owner, enterable, root = S.reserved(active)
    if owner == nil or root == nil or not enterable or type(VRFW.reset) ~= "table" then
      return nil
    end
    log("title of slot", active, "(" .. owner .. "): straight into its root menu", root)
    return VRFW.reset.straight({ menu = root, bgm_stop = true, need_carry = true,
      log = function(text) log("slot", active, "root menu:", text) end })
  end
end
