-- VRFW_Game: retail engine commands the game's own scripts never (or rarely) call, as named helpers. Each helper is
-- one retail command (docs/framework/retail-commands.md: hash, handler address, arguments, confidence). Every call
-- is in pcall: a missing dispatcher or a failed command answers nil. Definitions only: no engine call at load.
--   VRFW_Game.Call(name, ...)            -> the results of funcLuaCommand(crc32("CMND_" .. name), ...)
--   VRFW_Game.CallCamera(name, ...)      the same through funcLuaCameraCommand
--   VRFW_Game.CallEffect(name, ...)      the same through funcLuaEffectCommand
--   VRFW_Game.GameMode()                 -> the game mode number of the running scene
--   VRFW_Game.IsPlayingSoccer()          -> true while a match is being played
--   VRFW_Game.TimeZone()                 -> time of day 0..4 (the game clock's zone, as the field menus read it)
--   VRFW_Game.Weather(field)             -> the current weather id (field 0 or nil); field 1 / 2 = that weather's
--                                           first / second table value
--   VRFW_Game.StepScale()                -> the game speed (1 = normal)
--   VRFW_Game.SlowMotion(scale, back_s, delay_s)  the game runs at `scale` now and blends back to normal speed
--                                           over `back_s` seconds after `delay_s` seconds
--   VRFW_Game.CameraShake(power, preset) shakes the active camera (preset 0..14)
--   VRFW_Game.FadeOut(seconds)           screen to black
--   VRFW_Game.FadeIn(seconds)            screen back from black
--   VRFW_Game.IsFading()                 -> true while a screen fade runs
--   VRFW_Game.ObjectPos(handle)          -> x, y, z of a scene object (a character's object handle); nil if gone
--   VRFW_Game.SetObjectScale(handle, x, y, z) -> true when the object exists
--   VRFW_Game.BattleBit(n)               -> a per-match bit flag (the game clears them for every match)
--   VRFW_Game.SetBattleBit(n, on)
--   VRFW_Game.BattleByte(n)              -> a per-match byte flag
--   VRFW_Game.SetBattleByte(n, value)
--   VRFW_Game.EndTutorial()              closes the running tutorial
--   VRFW_Game.Announce(kind, a, b)       pushes one entry to the game's announce log (arguments unverified)
if VRFW_Game == nil then
  local function run(dispatcher, name, ...)
    local f = _ENV[dispatcher]
    if type(f) ~= "function" then
      return nil
    end
    local r = table.pack(pcall(f, VRFW_Cmd[name], ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
  end

  local G = {}

  function G.Call(name, ...)
    return run("funcLuaCommand", name, ...)
  end

  function G.CallCamera(name, ...)
    return run("funcLuaCameraCommand", name, ...)
  end

  function G.CallEffect(name, ...)
    return run("funcLuaEffectCommand", name, ...)
  end

  function G.GameMode()
    return G.Call("GET_GAME_MODE")
  end

  function G.IsPlayingSoccer()
    return G.Call("IS_PLAYING_SOCCER") == true
  end

  function G.TimeZone()
    return G.Call("GET_GAME_TIME_ZONE")
  end

  function G.Weather(field)
    return G.Call("GET_WEATHER", field or 0)
  end

  function G.StepScale()
    return G.Call("GET_STEP_SCALE")
  end

  function G.SlowMotion(scale, back_s, delay_s)
    return G.CallCamera("PLAY_SLOW", scale or 1, back_s or 0, delay_s or 0)
  end

  function G.CameraShake(power, preset)
    return G.CallCamera("PLAY_CAMERA_SHAKE", power or 1, preset or 0)
  end

  function G.FadeOut(seconds)
    return G.Call("START_SCREEN_FADE", 0, seconds or 0.5)
  end

  function G.FadeIn(seconds)
    return G.Call("START_SCREEN_FADE", 2, seconds or 0.5)
  end

  function G.IsFading()
    return G.Call("BRIGHT_IS_FADE") == true
  end

  function G.ObjectPos(handle)
    local ok, x, y, z = G.CallEffect("GET_TARGET_CHARA_POS", handle)
    if ok ~= true then
      return nil
    end
    return x, y, z
  end

  function G.SetObjectScale(handle, x, y, z)
    return G.Call("SET_SCALE", handle, x, y or x, z or x) == true
  end

  function G.BattleBit(n)
    return G.Call("GET_TEMP_BTL_BIT_FLAG", n) == true
  end

  function G.SetBattleBit(n, on)
    return G.Call("SET_TEMP_BTL_BIT_FLAG", n, on ~= false)
  end

  function G.BattleByte(n)
    return G.Call("GET_TEMP_BTL_BYTE_FLAG", n)
  end

  function G.SetBattleByte(n, value)
    return G.Call("SET_TEMP_BTL_BYTE_FLAG", n, value or 0)
  end

  function G.EndTutorial()
    return G.Call("END_TUTORIAL")
  end

  function G.Announce(kind, a, b)
    return G.Call("REGIST_ANNOUNCE_LOG", kind or 0, a or 0, b or 0)
  end

  VRFW_Game = G
end
