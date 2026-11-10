-- lua_patch.scope: used
-- VRFW.textures: a menu texture loaded once and a callback when it is in (docs/framework/textures.md).
if VRFW.textures == nil then
  local T = {
    LOAD = 839427544,        -- CMND_LOAD_MENU_RES_TEXTURE (path)
    LOADING = 1506186496,    -- (texture crc) -> true while it still loads
    state = {},
    waiting = 0,             -- textures still loading
    SETTLED = {wait = 600, min_frames = 10}, -- options of a per-frame poll: never in before 10 frames
  }
  VRFW.textures = T

  local function loading(path)
    local busy = VRFW.host.command(T.LOADING, VRFW.crc32(path))
    return busy == true
  end

  local function finish(path, w, ok)
    T.state[path] = ok
    T.waiting = T.waiting - 1
    if not ok then
      pcall(funcLuaCommand, VRFW.commands.VRFW_LOG, "vrfw.Textures", "texture never loaded", path)
    end
    for _, fn in ipairs(w.fns) do
      pcall(fn, ok, path)
    end
  end

  local function advance(path, w)
    w.frames = w.frames + 1
    if not loading(path) and w.frames >= w.min_frames then
      finish(path, w, true)
    elseif w.left then
      w.left = w.left - 1
      if w.left <= 0 then
        finish(path, w, false)
      end
    end
  end

  --- Requests texture `path`, calling fn when loaded; answers true or false when known, nothing while loading.
  function T.request(path, fn, opts)
    local s = T.state[path]
    if s == true or s == false then
      return s
    end
    if s == nil then
      pcall(funcLuaMenuCommand, T.LOAD, path)
      local min_frames = opts and opts.min_frames or 0
      if min_frames <= 0 and not loading(path) then
        T.state[path] = true
        return true
      end
      s = { left = opts and type(opts.wait) == "number" and opts.wait or false, min_frames = min_frames, frames = 0, fns = {} }
      T.state[path] = s
      T.waiting = T.waiting + 1
    end
    if type(fn) == "function" then
      s.fns[#s.fns + 1] = fn
    end
    return false
  end

  --- One texture polled every frame, without settle(): true once it is in.
  function T.poll(path, opts)
    local s = T.state[path]
    if s == nil then
      T.request(path, nil, opts)
    elseif type(s) == "table" then
      advance(path, s)
    end
    return T.state[path] == true
  end

  --- True while a texture is still loading.
  function T.pending()
    return T.waiting > 0
  end

  --- Advances the texture loads.
  function T.settle()
    if T.waiting <= 0 then
      return
    end
    for path, w in pairs(T.state) do
      if type(w) == "table" then
        advance(path, w)
      end
    end
  end

  --- True or false once path is known; nil while it is loading.
  function T.ready(path)
    local s = T.state[path]
    if s == true or s == false then
      return s
    end
    return nil
  end

  --- Forgets every texture state.
  function T.forget()
    T.state, T.waiting = {}, 0
  end
end
