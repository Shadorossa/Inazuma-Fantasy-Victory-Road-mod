-- VRFW_ScreenKit: the drawing pools of a screen that draws itself with layer instances (quads, texts, faces), as a
-- mod's own screens (assets\lua\screens) and the framework's free-layer screens do. Definitions only: no engine call at
-- load. One kit per screen:
--   local K = VRFW_ScreenKit.New{caps = {[layer] = instance count, ...}, log = function(...) end}
--   K.Reset()                     OnInit: everything sent, opened, shown and loaded is forgotten
--   K.Begin()                     a new drawing: every pool starts empty
--   K.Slot(layer)                 the next free instance of the layer (opened on its first use), nil when full
--   K.Show(layer, idx)            shown (hidden again by K.Finish when the next drawing does not use it)
--   K.Set(layer, idx, prop, cmd, ...)   funcLuaMenuCommand(cmd, ...) sent only when its arguments changed
--   K.Forget(layer, idx[, prop])  what was sent for the instance (or only its `prop`) is forgotten: the next K.Set
--                                 sends again (OnSetupLayer of a pool instance); no arguments = everything sent
--   K.Finish(on_hide)             the instances the last drawing showed and this one did not are hidden;
--                                 on_hide(layer, idx) for each (a face or crest slot forgets its picture)
--   K.Hide(layer, idx)            the instance hidden now and no longer counted as shown
--   K.HideAll(layer)              every shown instance of the layer hidden (nil = of every layer)
--   K.TexReady(path)              the texture's load asked once (VRFW_Textures); true once it is in. A texture still
--                                 loading after `tex_wait` Settle calls (600) is logged once and answers false from
--                                 then on. New's opts.on_texture(path, ok) is called when a waited texture is in (the
--                                 screen draws again); the screen's Step calls K.Settle() while K.Pending()
--   K.Pending() / K.Settle()      VRFW_Textures.Pending / Settle
--   K.BasePrio(layer)             the layer's own draw priority (read once from its instance 0), false if none
--   K.Quad(layer, tex, sprite, x, y, w, h[, o])   a sprite of the atlas `tex` on the next instance, top-left x, y and
--                                 size w, h (screen px, y down); o = {alpha, raise (priorities above the layer's own),
--                                 flip (mirrored)}. Returns the instance, or nil (pool full, or the texture still
--                                 loading: K.waiting is then true, so the screen draws again)
-- The quad layer is an object with one sprite slot (retail cmn01_10, slot icon_new01, side 36 px): `quad_slot` /
-- `quad_side` in New's options for another one. New's opts.tex_ready(path) -> true once the texture is in: the
-- screen's own texture check used by K.Quad instead of K.TexReady.
-- A screen script runs before the _all files of its VM: it calls VRFW_ScreenKit.New in OnInit, not at load.
if VRFW_ScreenKit == nil then
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

  local function Menu(cmd, ...)
    local ok, a, b = pcall(funcLuaMenuCommand, cmd, ...)
    if ok then
      return a, b
    end
    return nil
  end

  local function Crc(text)
    if VRFW_Id ~= nil then
      return VRFW_Id.Crc(text)
    end
    return VRFW_Crc32(text)
  end

  local function Key(layer, idx)
    return layer .. ":" .. idx
  end

  local function New(opts)
    opts = opts or {}
    local K = {caps = opts.caps or {}, waiting = false}
    local quad_slot, quad_side = opts.quad_slot or QUAD_SLOT, opts.quad_side or QUAD_SIDE
    local tex_wait = opts.tex_wait or TEX_WAIT
    local sent, opened, shown, used, loaded, prio, full = {}, {}, {}, {}, {}, {}, {}

    local function Log(...)
      if opts.log ~= nil then
        pcall(opts.log, ...)
      end
    end

    function K.Reset()
      sent, opened, shown, used, loaded, prio, full = {}, {}, {}, {}, {}, {}, {}
      K.waiting = false
    end

    function K.Begin()
      used = {}
      K.waiting = false
    end

    function K.Set(layer, idx, prop, cmd, ...)
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

    function K.Forget(layer, idx, prop)
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

    function K.Slot(layer)
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

    function K.Show(layer, idx)
      K.Set(layer, idx, "vis", C.VISIBLE, layer, idx, true)
      shown[Key(layer, idx)] = {layer, idx}
    end

    local function Hide(k, at)
      K.Set(at[1], at[2], "vis", C.VISIBLE, at[1], at[2], false)
      shown[k] = nil
    end

    function K.Hide(layer, idx)
      Hide(Key(layer, idx), {layer, idx})
    end

    function K.Finish(on_hide)
      for k, at in pairs(shown) do
        if at[2] >= (used[at[1]] or 0) then
          Hide(k, at)
          if on_hide ~= nil then
            pcall(on_hide, at[1], at[2])
          end
        end
      end
    end

    function K.HideAll(layer)
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

    function K.TexReady(path)
      local w = loaded[path]
      if w == true or w == false then
        return w
      end
      local ready = VRFW_Textures.Request(path, w == nil and texture_in or nil, {wait = tex_wait})
      if ready == true then
        loaded[path] = true
        return true
      end
      if ready == false and VRFW_Textures.Ready(path) == false then
        loaded[path] = false
        return false
      end
      loaded[path] = "loading"
      return false
    end

    function K.Pending()
      return VRFW_Textures.Pending()
    end

    function K.Settle()
      VRFW_Textures.Settle()
    end

    function K.BasePrio(layer)
      if prio[layer] == nil then
        local p = Menu(C.GET_PRIO, layer, 0)
        prio[layer] = type(p) == "number" and p or false
      end
      return prio[layer]
    end

    function K.Quad(layer, tex, sprite, x, y, w, h, o)
      o = o or {}
      local ready
      if opts.tex_ready ~= nil then
        ready = opts.tex_ready(tex)
      else
        ready = K.TexReady(tex)
      end
      if not ready then
        if loaded[tex] ~= false then
          K.waiting = true
        end
        return nil
      end
      local i = K.Slot(layer)
      if i == nil then
        return nil
      end
      K.Show(layer, i)
      local sprite_id = type(sprite) == "number" and sprite or Crc(sprite)
      K.Set(layer, i, "sc", C.SCALE, layer, (o.flip and -w or w) / quad_side, h / quad_side, 1, i)
      K.Set(layer, i, "sp", C.SPRITE, layer, Crc(tex), sprite_id, quad_slot, 0, i)
      K.Set(layer, i, "pos", C.POS, layer, x + w / 2, -(y + h / 2), 0, i)
      K.Set(layer, i, "a", C.ALPHA, layer, i, 0, o.alpha or 1)
      local base = K.BasePrio(layer)
      if base then
        K.Set(layer, i, "prio", C.SET_PRIO, layer, i, base + (o.raise or 0), true)
      end
      return i
    end

    return K
  end

  VRFW_ScreenKit = {New = New, C = C}
end
