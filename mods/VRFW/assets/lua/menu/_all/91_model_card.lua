-- lua_patch.scope: used
-- VRFW model cards, game Lua side (every menu VM; script side scripts\model_card.lua; docs/framework/model-card.md).
if VRFW.model_card == nil then
  local MC = {}
  VRFW.model_card = MC

  local CMD = {
    SET_CHARA = 59611540,          -- (layer, idx, chara, slot)
    KIT = 3290636356,              -- (layer, idx, uniform, motion set number, flags, slot)
    BELONG_KIT = 1701330357,       -- (layer, idx, true): a team's kit, as the team dock's view
    MOTION = 180466856,            -- (layer, idx, clip, 0, 0, 0, 0, slot)
    GET_MODEL = 3895705890,        -- (layer, idx, slot) -> model handle (0 = none)
    COMPLETE = 1583438030,         -- (layer, idx, slot) -> the build is complete
    MODEL_VIS = 1890282463,        -- funcLuaCommand (model handle, on)
    LOADING = 2475005551,
    TO_MODEL = 347353059,          -- funcLuaCommand (chara_param) -> chara
    TURN_CONTROL = 1195674914,     -- (layer, idx, on): the right stick turns the model
    ROT = 2463117189,              -- (layer, idx, rx, ry, rz)
  }
  local SETTLE, MAX_FRAMES, FREE_FRAMES = 2, 180, 2
  local SCROLL_MESHES = { "_scr_line01", "_scr_obj01" }
  local KEY = nil

  MC.layers = {}
  local function HideShopParts(layer, idx)
    for _, mesh in ipairs(SCROLL_MESHES) do VRFW.host.menu_command(VRFW.commands.SET_MESH_VISIBLE, layer, VRFW.crc32(mesh), false, idx or 0) end
  end
  -- the screen's OnSetupLayer wrapped once (again only when the screen defined a new one); called from MC.New (OnInit)
  local function WatchSetup()
    if OnSetupLayer == MC.setup or type(OnSetupLayer) ~= "function" then return end
    local inner = OnSetupLayer
    --- Runs the card's setup, then hides the shop parts on its layers.
    MC.setup = function(a1, a2, ...)
      local r = table.pack(inner(a1, a2, ...))
      if MC.layers[a1] then HideShopParts(a1, a2) end
      return table.unpack(r, 1, r.n)
    end
    OnSetupLayer = MC.setup
  end

  local function same(a, b)
    if a == nil or b == nil then return a == b end
    return a.card == b.card and a.team == b.team and a.clips == b.clips and a.static == b.static
  end

  -- two boxes of the same place and size (a screen may pass a new box table every frame)
  local function same_box(a, b)
    if a == nil or b == nil then return a == b end
    return a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h
  end

  local function FitBox(b, fit, ppm1, centre)
    local m = fit.margin_px or 6
    local top, below, wide = fit.top_m or 2.1, fit.below_m or 0.03, fit.width_m or 1.1
    local bw, bh = math.max(20, (b.w or 450) - 2 * m), math.max(40, (b.h or 742) - 2 * m)
    local d = ppm1 * math.max((top + below) / bh, wide / bw)
    local ppm = ppm1 / d
    local feet = (b.y or 0) + (b.h or 742) - m - below * ppm
    local sx = (b.x or 0) + (b.w or 450) * (centre or 0.5)
    return d, sx, feet
  end

  --- A new model card for `spec`.
  function MC.new(spec)
    local K = { spec = spec, want = nil, held = nil, free_frames = 0, covered = false, logs = 0, opened = false }
    local layer = spec.layer
    MC.layers[layer] = true
    WatchSetup()

    local function Log(...)
      if spec.log ~= nil and K.logs < 40 then
        K.logs = K.logs + 1
        pcall(spec.log, "model card", ...)
      end
    end

    local function Handle()
      local h = VRFW.host.menu_command(CMD.GET_MODEL, layer, 0, 0)
      return type(h) == "number" and h ~= 0 and h or nil
    end

    local function Visible(on)
      local h = Handle()
      if h then VRFW.host.command(CMD.MODEL_VIS, h, on) end
    end

    -- the screen's background swapped for the background-pass copy while a model is shown
    local function Cover(on)
      if K.covered == on then return end
      K.covered = on
      for _, l in ipairs(spec.hide or {}) do VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, l, 0, not on) end
      if spec.backdrop then VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, spec.backdrop, 0, on) end
      if spec.on_cover then spec.on_cover(on) end
      Log("backdrop", tostring(on))
    end

    -- the place of the model for its box (the camera of content\defaults\model_card.toml)
    local function Place(H)
      local w, cam = H.want, H.camera or {}
      local b = w.box or {}
      H.placed_box = w.box
      local eye_y, eye_z, look_y = cam.eye_y or 2.25, cam.eye_z or 12.5, cam.look_y or 1.6
      local ppm1, tall = cam.px_per_m_at_1m or 3060, cam.player_height or 1.7
      local d, sx, feet
      if w.fit then
        d, sx, feet = FitBox(b, H.fit or {}, ppm1, w.centre)
      else
        local h_px = math.max(40, (b.h or 742) * (w.height or 0.8))
        d = ppm1 * tall / h_px
        sx = (b.x or 0) + (b.w or 450) * (w.centre or 0.5)
        feet = (b.y or 0) + (b.h or 742) * (w.feet or 0.9)
      end
      local z = eye_z - d
      local ppm = ppm1 / d
      local look = look_y + (eye_y - look_y) * z / eye_z
      local x, y = (sx - 960) / ppm, look - (feet - 540) / ppm
      VRFW.host.menu_command(VRFW.commands.SET_CHARA_MODEL_POS, layer, 0, x, y, z, 0)
      VRFW.host.menu_command(CMD.TURN_CONTROL, layer, 0, false)
      VRFW.host.menu_command(CMD.ROT, layer, 0, 0, cam.turn or -15, 0)
      Log("placed", w.card, string.format("%.2f %.2f %.2f", x, y, z), w.fit and string.format("fit box %.0f %.0f %.0f %.0f", b.x or 0, b.y or 0, b.w or 0, b.h or 0) or "")
    end

    local function Build(H)
      local w = H.want
      local kit = VRFW.host.command(VRFW.commands.VRFW_CONTACT_KIT, w.card, w.team or 0)
      local uniform = type(kit) == "table" and tonumber(kit.uniform) or 0
      local flags = type(kit) == "table" and tonumber(kit.flags) or 0
      local motion = 1
      local has, v = VRFW.host.command(VRFW.commands.GET_CHARA_INFO, w.card, 21)
      if has == true and type(v) == "number" and v ~= 0 then motion = v end
      VRFW.host.menu_command(CMD.SET_CHARA, layer, 0, H.chara, 0)
      VRFW.host.menu_command(VRFW.commands.SET_SCN_CHARA_REGIST_TYPE, layer, 0, 4, 0)
      VRFW.host.menu_command(CMD.KIT, layer, 0, uniform, motion, flags, 0)
      if (w.team or 0) ~= 0 and uniform ~= 0 then VRFW.host.menu_command(CMD.BELONG_KIT, layer, 0, true) end
      VRFW.host.menu_command(CMD.MOTION, layer, 0, H.stand, 0, 0, 0, 0, 0)
      VRFW.host.menu_command(VRFW.commands.CHARA_MODEL_CHANGE, layer, 0, 0, 9, 0, KEY)
      Visible(false)
      Log("build", w.card, H.chara, string.format("uniform 0x%08X flags %d team %s clip %s", uniform % 4294967296,
        flags, tostring(w.team), tostring(H.clip and H.clip.name)))
    end

    -- a new card: the chara, the clip its motion set holds; built once nothing else loads
    local function Start(w)
      local chara = VRFW.host.command(CMD.TO_MODEL, w.card)
      if type(chara) ~= "number" or chara == 0 then
        Log("no chara", w.card)
        return nil
      end
      local base = VRFW.host.command(VRFW.commands.VRFW_CHARA_BASE, w.card)
      local set = type(base) == "number" and VRFW.host.command(VRFW.commands.VRFW_CHARA_MOTION_SET, base) or nil
      -- static: no clip list, the stand only (the clip answer still brings the camera and the fit envelope)
      local clips = w.static and "" or (w.clips or "")
      local clip = VRFW.host.command(VRFW.commands.VRFW_MODEL_CARD_CLIP, type(set) == "string" and set or "", clips)
      if type(clip) ~= "table" then clip = nil end
      return { want = w, chara = chara, set = set, clip = clip, camera = clip and clip.camera or nil,
        fit = clip and clip.fit or nil,
        stand = 2263925137 --[[立ち1L]], phase = "wait", n = 0, ok = 0 }
    end

    local function Free()
      Visible(false)
      VRFW.host.menu_command(CMD.SET_CHARA, layer, 0, 0, 0)
      VRFW.host.menu_command(VRFW.commands.CHARA_MODEL_CHANGE, layer, 0, 0, 9, 0, KEY)
      Log("released", K.held and K.held.want.card)
      K.held = nil
      K.free_frames = FREE_FRAMES
    end

    local function Busy(H)
      return H.phase == "load" or VRFW.host.command(CMD.LOADING, H.chara) == true
    end

    --- Sets the model the card wants (nil = none).
    function K.set_want(w)
      if w ~= nil and (w.card or 0) == 0 then w = nil end
      if same(w, K.want) then
        if w ~= nil and K.held ~= nil then K.held.want.box = w.box end
        return
      end
      if K.hold then w = nil end
      if same(w, K.want) then return end
      K.want = w
      if K.held ~= nil then K.held.leaving = true end
      if w == nil then Visible(false) Cover(false) end
    end

    --- Hides the model card.
    function K.hide() K.set_want(nil) end

    --- Another screen with its own 3D model view opened over this one (on) / closed (off).
    function K.set_hold(on)
      on = on == true
      if K.hold == on then return end
      K.hold = on
      Log("hold", tostring(on))
      if on then
        K.set_want(nil)
      elseif K.closed then
        K.closed, K.opened = false, false
      end
    end

    --- True when nothing is held, wanted or being freed.
    function K.released()
      return K.held == nil and K.want == nil and K.free_frames <= 0
    end

    --- One frame of the model card.
    function K.step()
      if KEY == nil then KEY = VRFW.crc32("vrfw_model_card") end
      if not K.opened then
        K.opened = true
        if spec.backdrop then VRFW.host.menu_command(VRFW.commands.SET_LAYER_VISIBLE, spec.backdrop, 0, false) end
        VRFW.host.menu_command(VRFW.commands.OPEN_LAYER, layer, 0)
        -- the shop list base's scroll bar is not part of a card
        HideShopParts(layer, 0)
      end
      if K.free_frames > 0 then
        K.free_frames = K.free_frames - 1
        return
      end
      if K.hold then
        if K.held == nil and not K.closed then
          K.closed = true
          VRFW.host.menu_command(VRFW.commands.CLOSE_LAYER, layer)
          Log("layer closed while another screen's model view is up")
        end
        if K.held == nil then return end
      end
      local H = K.held
      if H ~= nil and H.leaving then
        Visible(false)
        if H.phase == "load" and H.n < MAX_FRAMES then
          H.n = H.n + 1
          if VRFW.host.menu_command(CMD.COMPLETE, layer, 0, 0) ~= true then return end
        end
        Free()
        return
      end
      if H == nil then
        if K.want == nil then return end
        H = Start(K.want)
        if H == nil then
          K.want = nil
          Cover(false)
          return
        end
        K.held = H
      end
      H.n = H.n + 1
      if H.phase == "wait" then
        if VRFW.host.command(CMD.LOADING, H.chara) == true and H.n < MAX_FRAMES then return end
        Build(H)
        H.phase, H.n, H.ok = "load", 0, 0
      elseif H.phase == "load" then
        if VRFW.host.menu_command(CMD.COMPLETE, layer, 0, 0) == true then H.ok = H.ok + 1 else H.ok = 0 end
        if H.ok < SETTLE and H.n < MAX_FRAMES then return end
        Place(H)
        local c = H.clip
        if c ~= nil and c.attach then
          local h = Handle()
          local done, why = false, "no model handle"
          if h then done, why = VRFW.host.command(VRFW.commands.VRFW_MODEL_CARD_PACK, h, c.pack) end
          Log("pack", c.pack, tostring(done), tostring(why))
          if done ~= true then
            -- the pack did not load: the stand stays (never a clip the model cannot play)
            H.clip = nil
          end
          H.phase, H.n = "pack", 0
        else
          H.phase, H.n = "play", 0
        end
      elseif H.phase == "pack" then
        local frames = H.camera and H.camera.pack_frames or 6
        if H.n < frames then return end
        H.phase, H.n = "play", 0
      elseif H.phase == "play" then
        if H.clip ~= nil and H.clip.clip ~= H.stand then VRFW.host.menu_command(CMD.MOTION, layer, 0, H.clip.clip, 0, 0, 0, 0, 0) end
        Log("shown", H.want.card, H.clip and H.clip.name or "stand")
        Cover(true)
        Visible(true)
        H.phase = "up"
      elseif H.phase == "up" then
        if not same_box(H.placed_box, H.want.box) then Place(H) end
      end
    end

    return K
  end
end
