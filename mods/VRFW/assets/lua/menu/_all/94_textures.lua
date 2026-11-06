-- VRFW_Textures: a menu texture loaded once and a callback when it is in (docs/framework/textures.md). The game loads
-- menu textures in the background (CMND_LOAD_MENU_RES_TEXTURE) and offers no «loaded» event to menu Lua: its only
-- answer is the texture's own «still loading» flag. This file is the one place that asks that flag, and only while a
-- texture is waited for; screens ask for the texture and get called back. Definitions only; no engine call at load.
--   VRFW_Textures.Request(path[, fn[, opts]]) -> true when the texture is in (fn is not called), false while it loads
--       (fn(true, path) is called once it is in, fn(false, path) when it is given up). The load is asked once per VM.
--       opts.wait = the Settle calls a texture may take before it is given up (nil = no limit; logged once).
--   VRFW_Textures.Pending() -> true while a texture asked in this VM is still loading
--   VRFW_Textures.Settle()  from the screen's Step, only while Pending(): the textures that came in get their callbacks
--   VRFW_Textures.Ready(path) -> true (in), false (given up) or nil (not asked or still loading)
--   VRFW_Textures.Forget()  every texture of this VM asked again next time (the screen's OnInit)
if VRFW_Textures == nil then
  local T = {
    LOAD = 839427544,        -- CMND_LOAD_MENU_RES_TEXTURE (path)
    LOADING = 1506186496,    -- (texture crc) -> true while it still loads
    state = {},              -- path -> true (in) | false (given up) | { left = checks or false, fns = {} } (loading)
    waiting = 0,             -- textures still loading
  }
  VRFW_Textures = T

  local function loading(path)
    local ok, busy = pcall(funcLuaCommand, T.LOADING, VRFW_Crc32(path))
    return ok and busy == true
  end

  local function finish(path, w, ok)
    T.state[path] = ok
    T.waiting = T.waiting - 1
    if not ok then
      pcall(funcLuaCommand, VRFW_Cmd.EVT_LOG, "vrfw.Textures", "texture never loaded", path)
    end
    for _, fn in ipairs(w.fns) do
      pcall(fn, ok, path)
    end
  end

  function T.Request(path, fn, opts)
    local s = T.state[path]
    if s == true or s == false then
      return s
    end
    if s == nil then
      pcall(funcLuaMenuCommand, T.LOAD, path)
      if not loading(path) then
        T.state[path] = true
        return true
      end
      s = { left = opts and type(opts.wait) == "number" and opts.wait or false, fns = {} }
      T.state[path] = s
      T.waiting = T.waiting + 1
    end
    if type(fn) == "function" then
      s.fns[#s.fns + 1] = fn
    end
    return false
  end

  function T.Pending()
    return T.waiting > 0
  end

  function T.Settle()
    if T.waiting <= 0 then
      return
    end
    for path, w in pairs(T.state) do
      if type(w) == "table" then
        if not loading(path) then
          finish(path, w, true)
        elseif w.left then
          w.left = w.left - 1
          if w.left <= 0 then
            finish(path, w, false)
          end
        end
      end
    end
  end

  function T.Ready(path)
    local s = T.state[path]
    if s == true or s == false then
      return s
    end
    return nil
  end

  function T.Forget()
    T.state, T.waiting = {}, 0
  end
end
