-- lua_patch.scope: used
-- VRFW.game_menu: retail engine commands the game's own scripts never (or rarely) call, as named helpers.
if VRFW.game_menu == nil then
  local function run(dispatcher, name, ...)
    local f = _ENV[dispatcher]
    if type(f) ~= "function" then
      return nil
    end
    local r = table.pack(pcall(f, VRFW.commands[name], ...))
    if not r[1] then
      return nil
    end
    return table.unpack(r, 2, r.n)
  end

  local G = {}

  --- Internal: Runs a named command through funcLuaCommand; answers its results.
  function G.call(name, ...)
    return run("funcLuaCommand", name, ...)
  end

  --- Internal: Runs a named camera command; answers its results.
  function G.call_camera(name, ...)
    return run("funcLuaCameraCommand", name, ...)
  end

  --- Internal: Runs a named effect command; answers its results.
  function G.call_effect(name, ...)
    return run("funcLuaEffectCommand", name, ...)
  end

  --- Internal: The game mode.
  function G.game_mode()
    return G.call("GET_GAME_MODE")
  end

  --- Internal: True while soccer is being played.
  function G.is_playing_soccer()
    return G.call("IS_PLAYING_SOCCER") == true
  end

  --- Internal: The game time zone.
  function G.time_zone()
    return G.call("GET_GAME_TIME_ZONE")
  end

  --- Internal: The weather value of `field`.
  function G.weather(field)
    return G.call("GET_WEATHER", field or 0)
  end

  --- Internal: The game step scale.
  function G.step_scale()
    return G.call("GET_STEP_SCALE")
  end

  --- Internal: Plays slow motion at `scale`, back after `back_s`, starting after `delay_s`.
  function G.slow_motion(scale, back_s, delay_s)
    return G.call_camera("PLAY_SLOW", scale or 1, back_s or 0, delay_s or 0)
  end

  --- Internal: Shakes the camera.
  function G.camera_shake(power, preset)
    return G.call_camera("PLAY_CAMERA_SHAKE", power or 1, preset or 0)
  end

  --- Internal: Fades the screen out in `seconds`.
  function G.fade_out(seconds)
    return G.call("START_SCREEN_FADE", 0, seconds or 0.5)
  end

  --- Internal: Fades the screen in in `seconds`.
  function G.fade_in(seconds)
    return G.call("START_SCREEN_FADE", 2, seconds or 0.5)
  end

  --- Internal: True while the screen fades.
  function G.is_fading()
    return G.call("BRIGHT_IS_FADE") == true
  end

  --- Internal: The position of object `handle`: x, y, z; nil when it cannot be read.
  function G.object_position(handle)
    local ok, x, y, z = G.call_effect("GET_TARGET_CHARA_POS", handle)
    if ok ~= true then
      return nil
    end
    return x, y, z
  end

  --- Internal: Scales object `handle`; answers true when done.
  function G.set_object_scale(handle, x, y, z)
    return G.call("SET_SCALE", handle, x, y or x, z or x) == true
  end

  --- Internal: True when temporary battle bit n is on.
  function G.battle_bit(n)
    return G.call("GET_TEMP_BTL_BIT_FLAG", n) == true
  end

  --- Internal: Sets temporary battle bit n.
  function G.set_battle_bit(n, on)
    return G.call("SET_TEMP_BTL_BIT_FLAG", n, on ~= false)
  end

  --- Internal: Temporary battle byte n.
  function G.battle_byte(n)
    return G.call("GET_TEMP_BTL_BYTE_FLAG", n)
  end

  --- Internal: Sets temporary battle byte n.
  function G.set_battle_byte(n, value)
    return G.call("SET_TEMP_BTL_BYTE_FLAG", n, value or 0)
  end

  --- Internal: Ends the tutorial.
  function G.end_tutorial()
    return G.call("END_TUTORIAL")
  end

  --- Internal: Adds an announce-log entry.
  function G.announce(kind, a, b)
    return G.call("REGIST_ANNOUNCE_LOG", kind or 0, a or 0, b or 0)
  end

  --- Internal: Namespace of the in-game menu helpers.
  VRFW.game_menu = G
end
