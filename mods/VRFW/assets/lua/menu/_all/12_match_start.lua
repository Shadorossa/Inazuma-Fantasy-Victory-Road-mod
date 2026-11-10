VRFW.match_start = VRFW.match_start or {}
do
  local M = VRFW.match_start
  local C = {
    CALLER = VRFW.commands.VRFW_FRIENDLY_CALLER,       -- CMND_VRFW_FRIENDLY_CALLER
    OVERRIDE = VRFW.commands.VRFW_RULE_ENGINE_OVERRIDE,     -- CMND_VRFW_RULE_ENGINE_OVERRIDE
    EXIT = VRFW.commands.VRFW_MATCH_EXIT,          -- CMND_VRFW_MATCH_EXIT
    PAUSE = VRFW.commands.VRFW_GAME_PAUSE,        -- CMND_VRFW_GAME_PAUSE([0 / 1]) -> ok, paused
    PLAY_MODE = 3718253404,    -- set play mode
    FADE = 609722083,          -- (on, seconds) screen fade to black
    CLOSE = VRFW.commands.CLOSE_MENU_OBJECT,         -- CMND_CLOSE_MENU_OBJECT
    SE = VRFW.commands.SND_PLAY_SE, SE_NO = 2086672038,
    MSG_BUSY = 898725220,      -- a message window is up
    IS_SCENE_ROOT = 2119959601,
    EXISTS = VRFW.commands.IS_EXIST_MENU_OBJECT,       -- CMND_IS_EXIST_MENU_OBJECT (funcLuaMenuCommand)
    SETTLED = 3050482496,      -- (funcLuaMenuCommand) no menu is opening / closing
    FADE_BUSY = 2736534827,    -- a fade is running
    SCENE_END_WAIT = 769636339,
    VS_SET = VRFW.commands.GET_VS_USE_TEAM_SET,       -- CMND_GET_VS_USE_TEAM_SET -> the active match team's set
    FIVE_CHECK = 1538643580,
    GET_PLAY_MODE = VRFW.commands.GET_PLAY_GAME_MODE,  -- CMND_GET_PLAY_GAME_MODE -> play mode (6 = the title)
  }
  local TITLE_PLAY_MODE = 6         -- the title: no menu scene, a match reserved here never starts
  local PARAM_SCENE_ROOT = 2082985882
  local PARAM_HAND_OVER = 3190064600
  local PARAM_WAY_BACK_MENU = 3244649355
  local PARAM_WAY_BACK_FRIENDLY = 1563930864
  local PARAM_RESUME_MENU = 2126831610
  local PARAM_RESUME_VALUE = 689586221
  local HAND_OVER_TIMEOUT = 600       -- frames the caller waits for the root to take the hand-over
  local ROOT_WAIT = 120               -- frames the root waits for each step of its close
  local SCENE_END_SECONDS = 1.5
  local script = type(VRFW.patch) == "table" and VRFW.patch.script or "?"
  M.stem = type(script) == "string" and (script:gsub("_%d+%.%d+%.%d+[%.%d]*$", "")) or "?"
  M.co, M.frames, M.wrapped, M.black = nil, 0, false, false
  M.watch, M.root_co, M.is_root, M.self_menu = nil, nil, false, nil

  local logger
  local function log(...)
    logger = logger or VRFW.logger.new("VRFW match_start")
    logger(tostring(M.stem), ...)
  end
  M.log = log

  local function unsigned(v) return VRFW.ids.unsigned_or(v, v) end

  local function param_get(key)
    return unsigned(VRFW.param.get(key))
  end

  local function param_set(key, value)
    if VRFW.param.has(key) then VRFW.param.clear(key) end
    if value ~= nil then VRFW.param.set(key, value) end
  end

  local function menu_exists(menu)
    local yes = VRFW.host.menu_command(C.EXISTS, menu)
    return yes == true
  end

  local function hand_over(menu, spec, mode)
    local root = param_get(PARAM_SCENE_ROOT)
    if type(menu) ~= "number" or root == nil or root == unsigned(menu) or not menu_exists(root) then
      return false
    end
    param_set(PARAM_HAND_OVER, unsigned(menu))
    M.watch = {frames = 0, menu = menu, root = root, spec = spec, mode = mode}
    log("hand-over: the scene root", root, "closes this menu and itself")
    return true
  end

  local function hand_over_failed(w)
    M.watch = nil
    log("hand-over: the scene root did not close after", w.frames, "frame(s): the launch is given up")
    param_set(PARAM_HAND_OVER, nil)
    local P = VRFW.friendly_match
    if type(P) == "table" and type(P.abort) == "function" then pcall(P.abort, "hand-over timeout") end
    pcall(funcLuaCommand, C.CALLER, "")
    pcall(funcLuaCommand, C.OVERRIDE, "")
    if type(w.spec.play_mode) == "number" and type(w.mode) == "number" and w.mode >= 0 then
      pcall(funcLuaCommand, C.PLAY_MODE, w.mode)
    end
    M.black = false
    pcall(funcLuaCommand, C.FADE, 0, 0.3)
    pcall(funcLuaCommand, C.SE, C.SE_NO)
    if type(w.spec.on_failed) == "function" then pcall(w.spec.on_failed, "hand-over") end
  end

  local function wait_frames(frames, busy)
    local n = 0
    while n < frames and busy() do
      n = n + 1
      coroutine.yield()
    end
    return n
  end

  local function root_close(caller)
    log("hand-over: closing", caller, "then this scene root")
    pcall(funcLuaCommand, C.CLOSE, caller)
    coroutine.yield()
    local gone = wait_frames(ROOT_WAIT, function() return menu_exists(caller) end)
    local settled = wait_frames(ROOT_WAIT, function()
      local ok, done = pcall(funcLuaMenuCommand, C.SETTLED)
      return ok and done == false
    end)
    local faded = wait_frames(ROOT_WAIT, function()
      local ok, busy = pcall(funcLuaCommand, C.FADE_BUSY)
      return ok and busy == true
    end)
    log("hand-over: the root closes", "gone", gone, "settled", settled, "fade", faded)
    pcall(funcLuaCommand, C.SCENE_END_WAIT, SCENE_END_SECONDS)
    pcall(funcLuaCommand, C.CLOSE, M.self_menu)
  end

  local function launch(spec)
    local P = VRFW.friendly_match
    local n = 0
    while n < (tonumber(spec.settle) or 0) or (n < 900 and select(2, pcall(funcLuaCommand, C.MSG_BUSY)) == true) do
      n = n + 1
      coroutine.yield()
    end
    pcall(funcLuaCommand, C.OVERRIDE, "")
    for _, o in ipairs(spec.overrides or {}) do
      local ok, good, why = pcall(funcLuaCommand, C.OVERRIDE, o[1], o[2])
      if not ok or good ~= true then log("override refused", tostring(o[1]), tostring(o[2]), tostring(why)) end
    end
    local okc, _, menu, mode = pcall(funcLuaCommand, C.CALLER, M.stem)
    if not okc then menu, mode = nil, nil end
    local root = param_get(PARAM_SCENE_ROOT)
    if type(menu) == "number" and root ~= nil and root ~= unsigned(menu) then
      pcall(funcLuaCommand, C.CALLER, root)
      log("caller: the scene root", root, "(the menu the game reopens after the match)")
    end
    if type(spec.play_mode) == "number" then
      pcall(funcLuaCommand, C.PLAY_MODE, spec.play_mode)
    end
    local set, friendly = spec.set, spec.friendly
    if type(set) == "function" then
      local okf, v, f = pcall(set)
      set = okf and type(v) == "number" and v or nil
      if okf and type(f) == "string" and f ~= "" then friendly = f end
    end
    log("start", tostring(friendly), "game", tostring(spec.game), "set", tostring(set), "from play mode", tostring(mode),
      "frame", M.frames)
    local back_to = root
    if back_to == nil and type(menu) == "number" and menu ~= 0 then
      back_to = unsigned(menu)
    end
    param_set(PARAM_WAY_BACK_MENU, back_to)
    param_set(PARAM_WAY_BACK_FRIENDLY, back_to ~= nil and type(friendly) == "string" and VRFW.crc32(friendly) or nil)
    log("way back target", tostring(back_to))
    local resume = back_to ~= nil and type(spec.resume) == "number" and spec.resume or nil
    param_set(PARAM_RESUME_MENU, resume ~= nil and back_to or nil)
    param_set(PARAM_RESUME_VALUE, resume)
    if resume ~= nil then log("resume value", resume, "for", back_to) end
    local ok, why = P.start(friendly, {
      game = spec.game, difficulty = spec.difficulty, stadium = spec.stadium, set = set, rival = spec.rival,
      tag = spec.tag, sub = spec.sub, objective = spec.objective,
      on_reserved = function()
        M.black = false
        log("reserved after", M.frames, "frame(s): this menu hands over to the match")
        if type(spec.on_reserved) == "function" then pcall(spec.on_reserved) end
        if not spec.keep_menu and type(menu) == "number" and menu ~= 0 and not hand_over(menu, spec, mode) then
          pcall(funcLuaCommand, C.CLOSE, menu)
        end
      end,
    })
    if not ok then
      log("start failed", tostring(why))
      param_set(PARAM_WAY_BACK_MENU, nil)
      param_set(PARAM_WAY_BACK_FRIENDLY, nil)
      param_set(PARAM_RESUME_MENU, nil)
      param_set(PARAM_RESUME_VALUE, nil)
      pcall(funcLuaCommand, C.CALLER, "")
      pcall(funcLuaCommand, C.OVERRIDE, "")
      if type(spec.play_mode) == "number" and type(mode) == "number" and mode >= 0 then
        pcall(funcLuaCommand, C.PLAY_MODE, mode)
      end
      M.black = false
      pcall(funcLuaCommand, C.FADE, 0, 0.3)
      pcall(funcLuaCommand, C.SE, C.SE_NO)
      if type(spec.on_failed) == "function" then pcall(spec.on_failed, why) end
    end
  end

  local function root_tick()
    if M.root_co == nil then
      local caller = param_get(PARAM_HAND_OVER)
      if caller == nil then return end
      param_set(PARAM_HAND_OVER, nil)
      M.root_co = coroutine.create(function() root_close(caller) end)
    end
    local ok, err = coroutine.resume(M.root_co)
    if not ok then log("hand-over error", tostring(err)) end
    if not ok or coroutine.status(M.root_co) == "dead" then M.root_co = nil end
  end

  local function tick()
    if M.is_root then pcall(root_tick) end
    local w = M.watch
    if w ~= nil then
      w.frames = w.frames + 1
      if w.frames >= HAND_OVER_TIMEOUT then hand_over_failed(w) end
    end
    if M.co == nil then return end
    if M.black then
      pcall(funcLuaCommand, C.FADE, 1, 0)
    end
    M.frames = M.frames + 1
    local ok, err = coroutine.resume(M.co)
    if not ok then log("error", tostring(err)) end
    if not ok or coroutine.status(M.co) == "dead" then M.co = nil end
  end

  local function wrap_step()
    if M.wrapped or type(Step) ~= "function" then return end
    M.wrapped = true
    local step = Step
    Step = function(...)
      local r = table.pack(step(...))
      pcall(tick)
      return table.unpack(r, 1, r.n)
    end
  end

  local recorded = false
  local function record_root()
    if recorded then return end
    recorded = true
    local okm, mode = pcall(funcLuaCommand, C.GET_PLAY_MODE)
    if okm and mode == TITLE_PLAY_MODE and param_get(PARAM_SCENE_ROOT) ~= nil then
      param_set(PARAM_SCENE_ROOT, nil)
      log("scene root cleared (the title)")
    end
    if okm and mode == TITLE_PLAY_MODE and param_get(PARAM_RESUME_MENU) ~= nil then
      param_set(PARAM_RESUME_MENU, nil)
      param_set(PARAM_RESUME_VALUE, nil)
      log("resume value dropped (the title)")
    end
    local ok, root = pcall(funcLuaMenuCommand, C.IS_SCENE_ROOT)
    if not ok or root ~= true or type(CRC32) ~= "function" or M.stem == "?" then return end
    M.is_root, M.self_menu = true, unsigned(CRC32(M.stem))
    param_set(PARAM_SCENE_ROOT, M.self_menu)
    wrap_step()
  end

  --- The team set a friendly is launched with: the pachanga dock, -1, or the VS team and the current friendly.
  function M.pachanga_team(current_friendly)
    local P = VRFW.friendly_match
    local set = type(P) == "table" and type(P.pachanga_set) == "function" and P.pachanga_set() or nil
    if type(set) == "number" then
      return set
    end
    if type(current_friendly) ~= "string" or current_friendly == "" then
      log("no active pachanga team")
      return -1
    end
    local okv, vs = pcall(funcLuaCommand, C.VS_SET)
    if okv and type(vs) == "number" and vs >= 0 then
      local okc, code = pcall(funcLuaCommand, C.FIVE_CHECK, vs, 1, false)
      if okc and not (type(code) == "number" and code > 0 and code < 11) then
        log("no active pachanga team: the active match team plays", vs, current_friendly)
        return vs, current_friendly
      end
      log("no active pachanga team and the active match team", vs, "has no complete five", tostring(code))
    end
    return -1
  end

  --- The resume value stored for this menu, consumed; nil when there is none.
  function M.take_resume()
    local menu = param_get(PARAM_RESUME_MENU)
    if menu == nil or M.stem == "?" or menu ~= VRFW.crc32(M.stem) then return nil end
    local v = VRFW.param.get(PARAM_RESUME_VALUE)
    param_set(PARAM_RESUME_MENU, nil)
    param_set(PARAM_RESUME_VALUE, nil)
    log("resume value taken", tostring(v))
    return v
  end

  --- True when this menu is reached from the title flow and is not the scene root.
  function M.title_bound()
    local okm, mode = pcall(funcLuaCommand, C.GET_PLAY_MODE)
    if not okm or mode ~= TITLE_PLAY_MODE then return false end
    local okr, root = pcall(funcLuaMenuCommand, C.IS_SCENE_ROOT)
    return not (okr and root == true)
  end

  --- The launch from this menu (see the header); answers true, or false, why.
  function M.start(spec)
    if type(spec) ~= "table" or type(spec.friendly) ~= "string" then return false, "no friendly" end
    local P = VRFW.friendly_match
    if type(P) ~= "table" or type(P.start) ~= "function" then
      log("refused: no friendly executor (VRFW.friendly_match) in this menu")
      return false, "no executor"
    end
    if M.co ~= nil or M.watch ~= nil then return false, "busy" end
    if not M.wrapped and type(Step) ~= "function" then
      log("refused: this menu has no Step to run the launch from")
      return false, "no step"
    end
    if M.title_bound() then
      log("refused: a menu over the title (no menu scene starts a match reserved here)")
      return false, "title"
    end
    local black = spec.black ~= false
    if black then pcall(funcLuaCommand, C.FADE, 1, 0) end
    M.frames, M.black = 0, black
    M.co = coroutine.create(function() launch(spec) end)
    wrap_step()
    log("requested", spec.friendly)
    return true
  end

  --- Pauses the game and leaves the match after `ms` milliseconds; answers ok, why.
  function M.exit(ms)
    local okp, pok, paused = pcall(funcLuaCommand, C.PAUSE, 1)
    log("exit: game paused", tostring(okp and pok), tostring(paused))
    local ok, done, why = pcall(funcLuaCommand, C.EXIT, ms)
    log("exit: hold-to-leave", tostring(ok and done), tostring(why))
    return ok and done == true, why
  end

  local init = OnInit
  if type(init) == "function" then
    OnInit = function(...)
      local r = table.pack(init(...))
      pcall(record_root)
      return table.unpack(r, 1, r.n)
    end
  end
  local VH = VRFW.host
  if M.stem ~= "?" and type(VH) == "table" and type(VH.on) == "function" then
    pcall(VH.on, M.stem, "OnInit", {id = "VRFW.match_start_scene_root", phase = "around", fn = function(nxt, ...)
      local r = table.pack(nxt(...))
      pcall(record_root)
      return table.unpack(r, 1, r.n)
    end})
  end
end
