-- lua_patch.scope: used
if VRFW.screen_kit == nil then
  local C = {
    OPEN_LAYER = 629267548,      -- CMND_OPEN_LAYER (layer, instance)
    VISIBLE = 711242136,         -- CMND_SET_LAYER_VISIBLE (layer, instance, on)
    POS = 1389957207,            -- CMND_SET_LAYER_LOCAL_POS (layer, x, y, z, instance)
    SCALE = 3778714801,          -- CMND_SET_LAYER_LOCAL_SCALE (layer, sx, sy, sz, instance)
    SPRITE = 558735651,          -- (layer, texture crc, sprite crc, sprite slot, 0, instance)
    ALPHA = 4231609516,          -- (layer, instance, 0, alpha)
    GET_PRIO = 1018283794,       -- CMND_GET_DRAW_PRIORITY (layer, instance)
    SET_PRIO = 1491630496,       -- CMND_SET_DRAW_PRIORITY (layer, instance, priority, children)
  }
  local QUAD_SLOT, QUAD_SIDE, TEX_WAIT = 1909474081 --[[icon_new01]], 36, 600

  local QUAD_MESH = 312193881    -- the cmn01_10 quad's mesh (K.colour)
  local CURSOR_LOCATOR = 3313461902
  local FOCUS_SET, LIST_NUM = 3466097042, 3252599449   -- (layer, row) the list focus / (layer, n) the list size
  local OFF_SCREEN = 4000
  local WHITE = {1, 1, 1}
  local KEY_DELAY, REPEAT_FIRST, REPEAT_EVERY = 2, 18, 6

  local function Menu(cmd, ...)
    return VRFW.host.menu_command(cmd, ...)
  end

  local function Crc(text)
    if VRFW.ids ~= nil then
      return VRFW.ids.crc32(text)
    end
    return VRFW.crc32(text)
  end

  local function Key(layer, idx)
    return layer .. ":" .. idx
  end

  local function New(opts)
    opts = opts or {}
    local K = {caps = opts.caps or {}, waiting = false}
    local quad_slot, quad_side = opts.quad_slot or QUAD_SLOT, opts.quad_side or QUAD_SIDE
    local tex_wait = opts.tex_wait or TEX_WAIT
    local quad_mesh = opts.quad_mesh or QUAD_MESH
    local sent, opened, shown, used, loaded, prio, full = {}, {}, {}, {}, {}, {}, {}
    local tinted = {}
    local keys = {held = {}, press = {}, reported = {}, next_rep = {}, frame = 0}
    local pointer = nil

    local function Log(...)
      if opts.log ~= nil then
        pcall(opts.log, ...)
      end
    end

    --- Forgets everything drawn and the key state.
    function K.reset()
      sent, opened, shown, used, loaded, prio, full = {}, {}, {}, {}, {}, {}, {}
      tinted = {}
      keys = {held = {}, press = {}, reported = {}, next_rep = {}, frame = 0}
      K.waiting = false
    end

    --- Starts a new draw: no slot used yet.
    function K.begin()
      used = {}
      K.waiting = false
    end

    --- Sends property `prop` of (layer, idx) only when its arguments changed.
    function K.set(layer, idx, prop, cmd, ...)
      local k = Key(layer, idx) .. ":" .. prop
      local a = table.pack(...)
      local sig = {}
      for i = 1, a.n do
        sig[#sig + 1] = tostring(a[i])
      end
      sig = table.concat(sig, ",")
      if sent[k] == sig then
        return
      end
      sent[k] = sig
      Menu(cmd, ...)
    end

    --- Forgets the sent values of (layer, idx, prop), or all of them with no layer.
    function K.forget(layer, idx, prop)
      if layer == nil then
        sent = {}
        return
      end
      if prop ~= nil then
        sent[Key(layer, idx) .. ":" .. prop] = nil
        return
      end
      local prefix = Key(layer, idx) .. ":"
      for k in pairs(sent) do
        if string.sub(k, 1, #prefix) == prefix then
          sent[k] = nil
        end
      end
    end

    --- The next free instance of `layer`; nil when it is full.
    function K.slot(layer)
      local n = used[layer] or 0
      if n >= (K.caps[layer] or 0) then
        if not full[layer] then
          full[layer] = true
          Log("pool full: layer", layer, "has", K.caps[layer] or 0, "instances")
        end
        return nil
      end
      used[layer] = n + 1
      if not opened[Key(layer, n)] then
        Menu(C.OPEN_LAYER, layer, n)
        opened[Key(layer, n)] = true
      end
      return n
    end

    --- Shows (layer, idx).
    function K.show(layer, idx)
      K.set(layer, idx, "vis", C.VISIBLE, layer, idx, true)
      shown[Key(layer, idx)] = {layer, idx}
    end

    local function Hide(k, at)
      K.set(at[1], at[2], "vis", C.VISIBLE, at[1], at[2], false)
      shown[k] = nil
    end

    --- Hides (layer, idx).
    function K.hide(layer, idx)
      Hide(Key(layer, idx), {layer, idx})
    end

    --- Hides (layer, idx) and moves it off the screen.
    function K.hide_off_screen(layer, idx)
      K.hide(layer, idx)
      K.set(layer, idx, "pos", C.POS, layer, -OFF_SCREEN, OFF_SCREEN, 0, idx)
    end

    --- Hides the instances this draw did not use; `on_hide` gets each one.
    function K.finish(on_hide)
      for k, at in pairs(shown) do
        if at[2] >= (used[at[1]] or 0) then
          Hide(k, at)
          if on_hide ~= nil then
            pcall(on_hide, at[1], at[2])
          end
        end
      end
    end

    --- Hides every shown instance, of `layer` when given.
    function K.hide_all(layer)
      for k, at in pairs(shown) do
        if layer == nil or at[1] == layer then
          Hide(k, at)
        end
      end
    end

    local function texture_in(ok, path)
      loaded[path] = ok
      if not ok then
        Log("texture never loaded", path)
      end
      if opts.on_texture ~= nil then
        pcall(opts.on_texture, path, ok)
      end
    end

    --- True or false once texture `path` is known; nil while it loads.
    function K.tex_ready(path)
      local w = loaded[path]
      if w == true or w == false then
        return w
      end
      local ready = VRFW.textures.request(path, w == nil and texture_in or nil, {wait = tex_wait})
      if ready == true then
        loaded[path] = true
        return true
      end
      if ready == false and VRFW.textures.ready(path) == false then
        loaded[path] = false
        return false
      end
      loaded[path] = "loading"
      return false
    end

    --- True while a texture is still loading.
    function K.pending()
      return VRFW.textures.pending()
    end

    --- Advances the texture loads.
    function K.settle()
      VRFW.textures.settle()
    end

    --- The base draw priority of `layer`, or false.
    function K.base_prio(layer)
      if prio[layer] == nil then
        local p = Menu(C.GET_PRIO, layer, 0)
        prio[layer] = type(p) == "number" and p or false
      end
      return prio[layer]
    end

    --- Draws a quad of `tex` and `sprite`; answers its instance, or nil.
    function K.quad(layer, tex, sprite, x, y, w, h, o)
      o = o or {}
      local ready
      if opts.tex_ready ~= nil then
        ready = opts.tex_ready(tex)
      else
        ready = K.tex_ready(tex)
      end
      if not ready then
        if loaded[tex] ~= false then
          K.waiting = true
        end
        return nil
      end
      local i = K.slot(layer)
      if i == nil then
        return nil
      end
      K.show(layer, i)
      local sprite_id = type(sprite) == "number" and sprite or Crc(sprite)
      K.set(layer, i, "sc", C.SCALE, layer, (o.flip and -w or w) / quad_side, h / quad_side, 1, i)
      K.set(layer, i, "sp", C.SPRITE, layer, Crc(tex), sprite_id, quad_slot, 0, i)
      K.set(layer, i, "pos", C.POS, layer, x + w / 2, -(y + h / 2), 0, i)
      K.set(layer, i, "a", C.ALPHA, layer, i, 0, o.alpha or 1)
      local base = K.base_prio(layer)
      if base then
        K.set(layer, i, "prio", C.SET_PRIO, layer, i, base + (o.raise or 0), true)
      end
      return i
    end

    --- Scales (layer, idx).
    function K.scale(layer, idx, sx, sy)
      K.set(layer, idx, "sc", C.SCALE, layer, sx, sy, 1, idx)
    end

    --- Places (layer, idx) in screen pixels, y down.
    function K.place(layer, idx, x, y)
      K.set(layer, idx, "pos", C.POS, layer, x, -y, 0, idx)
    end

    --- Colours (layer, idx) with `rgb`.
    function K.colour(layer, idx, rgb)
      K.set(layer, idx, "col", VRFW.commands.SET_PRIM_COLOR, layer, idx, quad_mesh, rgb[1], rgb[2], rgb[3])
    end

    --- Shows a quad of texture `tex_crc`; answers false when the sprite was refused.
    function K.textured_quad(layer, idx, tex_crc, sprite_crc, x, y, w, h)
      K.set(layer, idx, "vis", C.VISIBLE, layer, idx, true)
      K.scale(layer, idx, w / quad_side, h / quad_side)
      local ok = Menu(C.SPRITE, layer, tex_crc, sprite_crc, quad_slot, 0, idx)
      K.forget(layer, idx, "sp")
      K.place(layer, idx, x, y)
      local k = Key(layer, idx)
      if tinted[k] then
        tinted[k] = nil
        K.colour(layer, idx, WHITE)
      end
      return ok
    end

    --- The hash of `path` once it is loaded; nil for no path, false when missing or not loaded yet.
    function K.texture(path)
      if path == nil or path == "" then
        return nil
      end
      if path == VRFW.screen_art.PLAIN then
        return Crc(path)              -- a resource of every screen that uses it: never loaded here
      end
      if K.tex_ready(path) then
        return Crc(path)
      end
      if loaded[path] == false then
        return nil
      end
      K.waiting = true
      return false
    end

    --- Draws the art of `role`; answers true, or false when it has none.
    function K.art_quad(layer, idx, role, x, y, w, h)
      local a = opts.art ~= nil and opts.art[role] or nil
      if a ~= nil and a.res then
        if K.textured_quad(layer, idx, Crc(a.atlas), a.crc, x, y, w, h) ~= false then
          return true
        end
        a = nil
      end
      if a ~= nil then
        local tex_crc = K.texture(a.atlas)
        if tex_crc == false then
          K.hide_off_screen(layer, idx)
          return false
        end
        if tex_crc ~= nil and K.textured_quad(layer, idx, tex_crc, a.crc, x, y, w, h) ~= false then
          return true
        end
      end
      local f = opts.fallback ~= nil and opts.fallback[role] or opts.fallback_any or {"square", WHITE}
      local tex_crc, sprite_crc = VRFW.screen_art.plain(f[1])
      K.textured_quad(layer, idx, tex_crc, sprite_crc, x, y, w, h)
      tinted[Key(layer, idx)] = f[2]
      K.colour(layer, idx, f[2])
      return true
    end

    --- Text `id`; "" when it cannot be read.
    function K.text(id)
      local s = VRFW.host.command(VRFW.commands.TEXT_GET, id)
      if type(s) == "string" then
        return s
      end
      return ""
    end

    --- Text `id` with string.format arguments.
    function K.format(id, ...)
      local text = K.text(id)
      local ok, s = pcall(string.format, text, ...)
      if ok then
        return s
      end
      return text
    end

    --- True while `key` is held.
    function K.key_pressed(key)
      return VRFW.keys.held(key)
    end

    --- Marks `name` reported this frame.
    function K.key_reported(name)
      keys.reported[name] = keys.frame
    end

    --- One frame of key navigation: calls `nav` and `act`.
    function K.poll_keys(nav, act, o)
      o = o or {}
      local delay = o.delay or KEY_DELAY
      local enabled = o.enabled ~= false
      local repeats = o.repeat_keys
      keys.frame = keys.frame + 1
      local now = keys.frame
      for name, key in pairs(nav) do
        local on = K.key_pressed(key)
        if on and not keys.held[name] then
          keys.press[name] = now
        elseif not on then
          keys.press[name] = nil
        end
        keys.held[name] = on
        local p = keys.press[name]
        if p ~= nil and enabled then
          if now - p == delay and (keys.reported[name] or -100) < p - delay then
            keys.next_rep[name] = now + (o.repeat_first or REPEAT_FIRST)
            act(name)
          elseif repeats ~= nil and repeats[name] and keys.next_rep[name] ~= nil and now >= keys.next_rep[name]
              and now - p > delay then
            keys.next_rep[name] = now + (o.repeat_every or REPEAT_EVERY)
            act(name)
          end
        end
      end
    end

    --- The screen's pointer (created once).
    function K.pointer()
      if pointer == nil then
        pointer = VRFW.pointer.new()
      end
      return pointer
    end

    --- Polls the pointer over `zones`; answers its events.
    function K.poll_pointer(zones)
      local P = K.pointer()
      P.begin()
      for id, z in pairs(zones or {}) do
        P.box(z.x, z.y, z.hw, z.hh, id)
      end
      return P.poll()
    end

    --- Hides the list cursor layer and anchors the list.
    function K.open_list_anchor(layer, cursor_layer, locator)
      if cursor_layer ~= nil then
        Menu(C.VISIBLE, cursor_layer, 0, false)
      end
      Menu(VRFW.commands.SET_ENABLE_CTRL_FOCUS, layer, true)
      Menu(LIST_NUM, layer, 1)
      Menu(FOCUS_SET, layer, 0)
      Menu(VRFW.commands.SET_LAYER_ATTACH_LOCATOR_TRACE, layer, 0, locator or CURSOR_LOCATOR, false)
      Menu(C.POS, layer, -OFF_SCREEN, OFF_SCREEN, 0, 0)
    end

    return K
  end

  --- Advanced: Screen kit: the new constructor and the command constants C.
  VRFW.screen_kit = {new = New, C = C}
end
